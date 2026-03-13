USE [AppsLCA]
GO

/****** Object:  View [L2Brand].[VW_L2Brands_Units_Invoiced]    Script Date: 03/03/2026 07:30:28 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







ALTER   VIEW [L2Brand].[VW_L2Brands_Units_Invoiced]
AS
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------VISTA PARA L2B INVOICE LCA-------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----Que hace este script
------1) Toma embarques de TB_ShipmentCheckPrices desde una fecha de corte.
------2) Consolida base de facturacion historica por Waybill/Box/MO/Style/Color/Size.
------3) Cruza packed items + shipment + ordenes + estilos para construir el detalle final.
------4) Determina precio facturado segun fecha de cambio de regla.
--;
WITH CTE_Prices
AS
(
    ----Embarques a considerar para la vista (fecha de inicio de proceso)
    SELECT
          [id]
		 ,ISNULL(SCP.[Waybill], AF.[Waybill]) AS Waybill
		 ,ISNULL(SCP.[ShipDate], AF.ShipDate) AS ShipDate
	FROM
	( SELECT DISTINCT 
		Waybill
		,ShipDate
	  FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH (NOLOCK)
      WHERE AF.ShipDate >= '2025-01-01'
      AND StyleNumber NOT IN ('-','Fabric','Trim','Supplies','SWATCH')
	) AS AF 
    LEFT JOIN AppsLCA.dbo.TB_ShipmentCheckPrices AS SCP WITH (NOLOCK) ON SCP.Waybill = AF.Waybill
    -- WHERE ISNULL(SCP.[ShipDate], AF.ShipDate) >= '2026-02-01'

	
	
),
CTE_Bill
AS
(
    ----Base de facturacion consolidada por combinacion clave
    SELECT
         [ShipDate]        = AF.[ShipDate] 
        ,[Waybill]         = AF.[Waybill]
		,[ManufactureID]   = AF.[ManufactureID]
        ,[OrderID]         = AF.[OrderID]
		,[StyleNumber]     = AF.[StyleNumber]
		,[StyleColor]      = AF.[StyleColor]
		,[Size]            = AF.[Size]
		,[BasePrice]       = AF.[BasePrice]
		,[TotalDecoration] = AF.[Price] - AF.[BasePrice]
		,[UnitPrice]	   = AF.[Price]
        ,[StyleOption]     = AF.[StyleOptionName]
		,[Quantity]		   = SUM(AF.[Qty])
        --SELECT SUM(AF.[Qty])
    FROM CTE_Prices AS CP
	INNER JOIN AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH (NOLOCK) ON CP.Waybill = AF.Waybill and CP.ShipDate = AF.ShipDate
    
    GROUP BY
         AF.[ShipDate] 
        ,AF.[Waybill]
        ,AF.[BoxNumber]
        ,AF.[ManufactureID]
        ,AF.[OrderID]
        ,AF.[StyleNumber]
        ,AF.[StyleColor]
        ,AF.[Size]
        ,AF.[BasePrice]
		,AF.[Price]
        ,AF.[StyleOptionName]
)
,CTE_L2BrandInv
AS
(
	SELECT
		Style
		,Color
		,Size
		,InvItemID
		,ROW_NUMBER() OVER(PARTITION BY Style, Color, Size ORDER BY Style, Color, Size) AS R
	FROM AppsLCA.legacycaps.VW_LCA_L2B_InventoryID AS L2BInv WITH(NOLOCK)
),CTE_Orders AS
(
    SELECT 
         OrderID
        ,CASE
            WHEN PONumber LIKE 'ORD-PO%' THEN NULL
            WHEN PONumber LIKE 'ORD-%'   THEN TRY_CAST(REPLACE(PONumber,'ORD-','') AS BIGINT)
            WHEN PONumber LIKE 'ORD%'    THEN TRY_CAST(Comments6 AS BIGINT)
            ELSE NULL
         END AS ItemDetailID_Calc
        ,CASE
            WHEN PONumber LIKE 'ORD%' AND CHARINDEX('-', Comments6) > 0
                THEN SUBSTRING(Comments6, 1, CHARINDEX('-', Comments6) - 1)
            ELSE Comments6
         END AS CustomerPO_Calc
    FROM LCA.dbo.Orders WITH(NOLOCK)
)
,
CTE_Final
AS
(
    SELECT
        [Size]						 = AF.Size
        ,[StyleColor]				 = AF.StyleColor
        ,[Quantity]					 = SUM(AF.Quantity)
        ,[Style]					 = AF.StyleNumber
        ,[StyleID]					 = COALESCE(SCPD.StyleID, OI.StyleID)
        ,[TransactionDate]			 = SCP.ShipDate
        ,[MO]						 = MO.ManufactureNumber
        ,[MO_ID]					 = AF.ManufactureID
        ,[ItemDetailID]				 = COALESCE(SCPD.ItemDetailID, OD.ItemDetailID_Calc)
        ,[Item #]					 = L2BInv.InvItemID
        ,[InvoicedPrice]			 = CASE
									     WHEN SCP.ShipDate < '2026-02-10' THEN AF.BasePrice
									     ELSE SCPD.TotalBlank
									   END
		,[Decoration_Invoiced_Price] = CASE
									     WHEN SCP.ShipDate < '2026-02-10' THEN AF.[TotalDecoration]
									     ELSE SCPD.TotalDecoration
									   END
		,[Unit_Invoiced_Price]		 = CASE
									     WHEN SCP.ShipDate < '2026-02-10' THEN AF.UnitPrice
									     ELSE SCPD.TotalBlank + SCPD.TotalDecoration
									   END
		
        ,[CustomerPO]				 = OD.[CustomerPO_Calc]
        ,[StyleOption]				 = AF.StyleOption
        ,[Waybill]					 = AF.Waybill
         --,[StyleOptionID] = SCPD.StyleOptionID
         --,[Season]        = SCPD.Season
    FROM CTE_Prices										AS SCP    WITH(NOLOCK)
    LEFT JOIN  CTE_Bill									AS AF     WITH(NOLOCK) ON  SCP.waybill							= AF.Waybill and SCP.ShipDate = AF.ShipDate
    LEFT JOIN  AppsLCA.dbo.TB_ShipmentCheckPricesDetail AS SCPD   WITH(NOLOCK) ON  SCP.ID								= SCPD.shipmentCheckPrices_id 
																			   AND SCPD.ManufactureID					= AF.ManufactureID
    LEFT JOIN   CTE_Orders                              AS OD     WITH(NOLOCK) ON  AF.OrderID = OD.OrderID
    INNER JOIN  LCA.dbo.ManufactureOrders               AS MO     WITH(NOLOCK) ON  AF.ManufactureID                    = MO.ManufactureID
    INNER JOIN  LCA.dbo.OrderItems                      AS OI     WITH(NOLOCK) ON  MO.FirstOrderItemID                 = OI.OrderItemID
    INNER JOIN  LCA.dbo.Styles							AS ST     WITH(NOLOCK) ON  ST.StyleID							= OI.StyleID
    LEFT JOIN  LCA.dbo.Styles							AS STB    WITH(NOLOCK) ON  STB.StyleID							= ST.BlankStyleID
    LEFT JOIN  CTE_L2BrandInv							AS L2BInv WITH(NOLOCK) ON  COALESCE(STB.StyleNumber, SCPD.Style, AF.StyleNumber) = L2BInv.Style
																				AND COALESCE(SCPD.Color,AF.StyleColor)	= L2BInv.Color
																				AND AF.Size								= L2BInv.[Size]
																				AND L2BInv.R							= 1
    GROUP BY
         AF.Size
        ,AF.StyleColor
        ,AF.StyleNumber
        ,COALESCE(SCPD.StyleID, OI.StyleID)
        ,SCP.ShipDate
        ,MO.ManufactureNumber
        ,AF.ManufactureID
        ,COALESCE(SCPD.ItemDetailID, OD.ItemDetailID_Calc)
        ,L2BInv.InvItemID
        ,CASE
            WHEN SCP.ShipDate < '2026-02-10' THEN AF.BasePrice
            ELSE SCPD.TotalBlank
         END
        ,CASE
            WHEN SCP.ShipDate < '2026-02-10' THEN AF.[TotalDecoration]
            ELSE SCPD.TotalDecoration
         END
        ,CASE
            WHEN SCP.ShipDate < '2026-02-10' THEN AF.UnitPrice
            ELSE SCPD.TotalBlank + SCPD.TotalDecoration
         END
        ,OD.[CustomerPO_Calc]
        ,AF.StyleOption
        ,AF.Waybill
        )

SELECT 
     [Size]
    ,[StyleColor]
    ,[Quantity]
    ,[Style]
    ,[StyleID]
    ,[TransactionDate]
    ,[MO]
    ,[MO_ID]
    ,[ItemDetailID]
    ,[Item #]
    ,[InvoicedPrice] as Blank_Invoiced_Price
    ,[CustomerPO]
    ,[StyleOption]
    ,[Waybill]
	,[Decoration_Invoiced_Price]
	,[Unit_Invoiced_Price]
	
FROM CTE_Final
GO

