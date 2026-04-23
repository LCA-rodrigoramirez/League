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
		 ,SCP.[Waybill]
		 ,ISNULL(SCP.[ShipDate], AF.ShipDate) AS ShipDate
    FROM AppsLCA.dbo.TB_ShipmentCheckPrices AS SCP WITH (NOLOCK)
	INNER JOIN
	( SELECT DISTINCT 
		Waybill
		,ShipDate
	  FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH (NOLOCK)
	) AS AF ON SCP.Waybill = AF.Waybill
    WHERE ISNULL(SCP.[ShipDate], AF.ShipDate) >= '2026-02-01'

	
	
),
CTE_Bill
AS
(
    ----Base de facturacion consolidada por combinacion clave
    SELECT
         [Waybill]         = AF.[Waybill]
		,[ManufactureID]   = AF.[ManufactureID]
		,[StyleNumber]     = AF.[StyleNumber]
		,[StyleColor]      = AF.[StyleColor]
		,[Size]            = AF.[Size]
		,[BasePrice]       = AF.[BasePrice]
		,[TotalDecoration] = AF.[Screen_Print] + AF.[Embroidery] + AF.[Sublimation]
		,[UnitPrice]	   = AF.Price
		,[Quantity]		   = SUM(AF.[Qty])
    FROM CTE_Prices AS CP
	INNER JOIN AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH (NOLOCK) ON CP.Waybill = AF.Waybill
    GROUP BY
         AF.[Waybill]
        ,AF.[BoxNumber]
        ,AF.[ManufactureID]
        ,AF.[StyleNumber]
        ,AF.[StyleColor]
        ,AF.[Size]
        ,AF.[BasePrice]
		,AF.Price
		,AF.Screen_Print
		,AF.Embroidery
		,AF.Sublimation
)
,
CTE_L2BrandInv
AS
(
	SELECT
		Style
		,Color
		,Size
		,InvItemID
		,ROW_NUMBER() OVER(PARTITION BY Style, Color, Size ORDER BY Style, Color, Size) AS R
	FROM AppsLCA.legacycaps.VW_LCA_L2B_InventoryID AS L2BInv WITH(NOLOCK)
),
CTE_Final
AS
(
    SELECT
        [Size]						= AF.Size
        ,[StyleColor]				= SCPD.Color
        ,[Quantity]					= SUM(AF.Quantity)
        ,[Style]					= AF.StyleNumber
        ,[StyleID]					= SCPD.StyleID
        ,[TransactionDate]			= SCP.ShipDate
        ,[MO]						= SCPD.MO
        ,[MO_ID]					= SCPD.ManufactureID
        ,[ItemDetailID]				= SCPD.ItemDetailID
        ,[Item #]					= L2BInv.InvItemID
        ,[InvoicedPrice]			= CASE
									     WHEN SCP.ShipDate < '2026-02-10' THEN AF.BasePrice
									     ELSE SCPD.TotalBlank
									 END
		,[Decoration_Invoiced_Price] = CASE
									     WHEN SCP.ShipDate < '2026-02-10' THEN AF.[TotalDecoration]
									     ELSE SCPD.TotalDecoration
									 END
		,[Unit_Invoiced_Price]		= CASE
									     WHEN SCP.ShipDate < '2026-02-10' THEN AF.UnitPrice
									     ELSE SCPD.TotalBlank + SCPD.TotalDecoration
									 END
		
        ,[CustomerPO]				= CASE
									     WHEN (OD.[PONumber] LIKE 'ORD%') AND CHARINDEX('-', OD.Comments6) > 0
									         THEN SUBSTRING(OD.Comments6, 1, CHARINDEX('-', OD.Comments6) - 1)
									     ELSE OD.Comments6
									 END
        ,[StyleOption]				= SCPD.StyleOption
        ,[Waybill]					= SCP.Waybill
         --,[StyleOptionID] = SCPD.StyleOptionID
         --,[Season]        = SCPD.Season
    FROM CTE_Prices										AS SCP    WITH (NOLOCK)
    LEFT JOIN CTE_Bill									AS AF     WITH (NOLOCK) ON  SCP.waybill							= AF.Waybill
    INNER JOIN AppsLCA.dbo.TB_ShipmentCheckPricesDetail AS SCPD   WITH (NOLOCK) ON  SCP.ID								= SCPD.shipmentCheckPrices_id 
																				AND SCPD.ManufactureID					= AF.ManufactureID
    INNER JOIN LCA.dbo.Orders							AS OD     WITH (NOLOCK) ON  SCPD.OrderID						= OD.OrderID
    INNER JOIN LCA.dbo.Styles							AS ST     WITH (NOLOCK) ON  ST.StyleID							= SCPD.StyleID
    LEFT JOIN  LCA.dbo.Styles							AS STB    WITH (NOLOCK) ON  STB.StyleID							= ST.BlankStyleID
    LEFT JOIN  CTE_L2BrandInv							AS L2BInv WITH (NOLOCK) ON  ISNULL(STB.StyleNumber, SCPD.Style) = L2BInv.Style
																				AND SCPD.Color							= L2BInv.Color
																				AND AF.Size								= L2BInv.[Size]
																				AND L2BInv.R							= 1
    GROUP BY
         AF.Size
        ,SCPD.Color
        ,AF.StyleNumber
        ,SCPD.StyleID
        ,SCP.ShipDate
        ,SCPD.MO
        ,SCPD.ManufactureID
        ,SCPD.ItemDetailID
        ,L2BInv.InvItemID
        ,CASE
            WHEN SCP.ShipDate < '2026-02-10' THEN AF.BasePrice
            ELSE SCPD.TotalBlank
        END
        ,CASE
            WHEN (OD.[PONumber] LIKE 'ORD%') AND CHARINDEX('-', OD.Comments6) > 0
                THEN SUBSTRING(OD.Comments6, 1, CHARINDEX('-', OD.Comments6) - 1)
            ELSE OD.Comments6
        END
        ,SCPD.StyleOption
        ,SCP.Waybill
		,CASE
		     WHEN SCP.ShipDate < '2026-02-10' THEN AF.UnitPrice
		     ELSE SCPD.TotalBlank + SCPD.TotalDecoration
		 END
		,CASE
		    WHEN SCP.ShipDate < '2026-02-10' THEN AF.[TotalDecoration]
		    ELSE SCPD.TotalDecoration
		END
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
 --WHERE Waybill = 'HW-20260116'
GO


