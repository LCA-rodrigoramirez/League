USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_ImportExport_BillingDetails_InventoryCost]    Script Date: 10/08/2026 11:53:47 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Convertido desde la vista [dbo].[VW_ImportExport_AnexoFacturacion]
-- @DateFrom / @DateTo filtran AF.[ShipDate] desde el origen (AppsLCA.dbo.ImportExport_AnexoFacturacion)
-- Los campos UnitFreightCost_Ponderado, Total_UnitFreightCost_Ponderado, UnitFreightCost, Total_UnitFreightCost e Invoice
-- se calculan por UPDATE (no por JOIN directo en el SELECT) para evitar duplicidad de filas cuando hay múltiples coincidencias.

--ALTER   PROCEDURE [dbo].[SP_ImportExport_BillingDetails_InventoryCost]
--     @DateFrom AS DATE
--    ,@DateTo   AS DATE
--AS
BEGIN
    SET NOCOUNT ON;

     DECLARE @DateFrom AS DATE = '2026-07-01'
     DECLARE @DateTo   AS DATE = '2026-07-31'
    DROP TABLE IF EXISTS #AnexoFacturacion
    DROP TABLE IF EXISTS #TB_EORO_ChangeCost

    SELECT
         AFPN.*
        ,[UnitFreightCost_Ponderado]       = CONVERT(NUMERIC(18,4), 0)
        ,[Total_UnitFreightCost_Ponderado] = CONVERT(NUMERIC(18,4), 0)
        ,[UnitFreightCost]                 = CONVERT(NUMERIC(18,4), 0)
        ,[Total_UnitFreightCost]           = CONVERT(NUMERIC(18,4), 0)
        ,[Invoice]                         = CAST(NULL AS NVARCHAR(500))
        ,[US_HTSCode]                      = CAST(NULL AS NVARCHAR(50))
        ,[PackedItemID]                    = CAST(NULL AS INT)
        ,[RO_Cost]                         = CAST(NULL AS VARCHAR(100))
        ,[ROID_Cost]                       = CAST(NULL AS INT)
    INTO #AnexoFacturacion
    FROM
    (
        SELECT
             [ShipDate]
            ,[Waybill]
            ,[InvoiceBatch]
            ,[Batch]
            ,[PONumber]
            ,[BoxNumber]                         = AF.[BoxNumber]
            ,[StyleNumber]
            ,[StyleColor]                        = AF.[StyleColor]
            ,[SeasonName]
            ,[Qty]
            ,[Supplier]
            ,[SAC]
            ,[HTSDescription]
            ,[PuertoDestino]
            ,[BasePrice]
            ,[Handling]
            ,[Total_Handling]
            ,[Freight]
            ,[Total_Freight]
            ,[BaseCost]
            ,[Total_Base_Cost]
            ,[Receiving_Cost]
            ,[Total_Receiving_Cost]
            ,[Purchase_order]
            ,[PrintCount]
            ,[Screen_Print]
            ,[Total_Screen_Print]
            ,[Embroidery]
            ,[Total_Embroidery]
            ,[Sublimation]
            ,[Total_Sublimation]
            ,[Price]
            ,[Total$]
            ,[ManufactureID]                     = AF.[ManufactureID]
            ,[MO]
            ,[Embr_Code1]
            ,[Embr_Code2]
            ,[Embr_Code3]
            ,[Embr_Code4]
            ,[PrintLocations]
            ,[CountryOfOrigin]
            ,[ProductDivision]
            ,[Manufacturer]
            ,[SemiFinishProductCost]
            ,[SemiFinishProductCost_Fabric]
            ,[SemiFinishProductCost_Thread]
            ,[SemiFinishProductCost_Trim]
            ,[SemiFinishProductCost_Supplies]
            ,[SemiFinishProductCost_Contracts]
            ,[SemiFinishProductCost_SubAssembly]
            ,[FinishProductCost]
            ,[FinishProductCost_Fabric]
            ,[FinishProductCost_Thread]
            ,[FinishProductCost_Trim]
            ,[FinishProductCost_Supplies]
            ,[FinishProductCost_Contracts]
            ,[FinishProductCost_SubAssembly]
            ,[Incoterm]
            ,[Gross_Weight_kgs]
            ,[Net_Weight_kgs]
            ,[Container]
            ,[Consigned]
            ,[PartNumber]                        = CASE
                                                    WHEN AF.[PartNumber] IS NULL OR AF.[PartNumber] = '' THEN ISNULL(VWRAW.[PartNumber], '')
                                                    ELSE ISNULL(AF.[PartNumber], '')
                                                  END
        
            ,[Size]
            ,[RO_ID]                             = AF.[RO_ID]
            ,[RO]
            ,[Receiving_Cost_Ponderado]          = AF.[Receiving_Cost_Ponderado]
            ,[Total_Receiving_Cost_Ponderado]    = AF.[Total_Receiving_Cost_Ponderado]
            ,[OrderType]
            ,[TypeContainer]
            ,[Price_ScreenPrint]
            ,[Price_Sublimation]
            ,[Price_SubApplication]
            ,[CodePrice_EmbroideryApp]
            ,[Price_EmbroideryApp]
            ,[CodePrice_EmbroideryHW]
            ,[Cost_PackingMaterial]
            ,[Price_EmbroideryHW]
            ,[Price_HDP]
            ,[Price_SpecialPK]
            ,[Price_Relabel]
            ,[Price_PigmentDye]
            ,[Price_InlandFreight]
            ,[Price_AirFreight]
            ,[Price_OceanFreight]
            ,[OutboundFreight]
            ,[NumeroControl]
            ,[CodigoGeneracion]
            ,[Sello]
            ,[MensajeRecepcion]
            ,[ID]

        FROM
        (
            SELECT TOP 100 PERCENT
                 [ShipDate]                          = AF.[ShipDate]
                ,[Waybill]                           = TRIM(REPLACE(REPLACE(REPLACE(AF.[Waybill], CHAR(10), ''), CHAR(9), ''), CHAR(13), ''))
                ,[InvoiceBatch]
                ,[Batch]                             = AF.[Batch]
                ,[PONumber]                          = AF.[PONumber]
                ,[BoxNumber]                         = AF.[BoxNumber]
                ,[StyleNumber]
                ,[StyleColor]
                ,[SeasonName]
                ,[Qty]
                ,[Supplier]
                ,[SAC]
                ,[HTSDescription]                    = TRIM(REPLACE(REPLACE(REPLACE(AF.[HTSDescription], CHAR(10), ''), CHAR(9), ''), CHAR(13), ''))
                ,[PuertoDestino]                     = AF.[PuertoDestino]
                ,[BasePrice]                         = AF.[BasePrice]
                ,[Handling]
                ,[Total_Handling]
                ,[Freight]                           = AF.[Freight]
                ,[Total_Freight]
                ,[BaseCost]
                ,[Total_Base_Cost]
                ,[Receiving_Cost]
                ,[Total_Receiving_Cost]
                ,[Purchase_order]
                ,[PrintCount]                        = AF.[PrintCount]
                ,[Screen_Print]
                ,[Total_Screen_Print]
                ,[Embroidery]
                ,[Total_Embroidery]
                ,[Sublimation]                       = AF.[Sublimation]
                ,[Total_Sublimation]
                ,[Price]
                ,[Total$]
                ,[ManufactureID]                     = AF.[ManufactureID]
                ,[MO]                                = AF.[MO]
                ,[Embr_Code1]
                ,[Embr_Code2]
                ,[Embr_Code3]
                ,[Embr_Code4]
                ,[PrintLocations]                    = TRIM(REPLACE(REPLACE(REPLACE(AF.[PrintLocations], CHAR(10), ''), CHAR(9), ''), CHAR(13), ''))
                ,[CountryOfOrigin]
                ,[ProductDivision]
                ,[Manufacturer]
                ,[SemiFinishProductCost]
                ,[SemiFinishProductCost_Fabric]
                ,[SemiFinishProductCost_Thread]
                ,[SemiFinishProductCost_Trim]
                ,[SemiFinishProductCost_Supplies]
                ,[SemiFinishProductCost_Contracts]
                ,[SemiFinishProductCost_SubAssembly]
                ,[FinishProductCost]
                ,[FinishProductCost_Fabric]
                ,[FinishProductCost_Thread]
                ,[FinishProductCost_Trim]
                ,[FinishProductCost_Supplies]
                ,[FinishProductCost_Contracts]
                ,[FinishProductCost_SubAssembly]
                ,[Incoterm]
                ,[Gross_Weight_kgs]
                ,[Net_Weight_kgs]
                ,[Container]
                ,[Consigned]
                ,[PartNumber]
                ,[Size]
                ,[RO_ID]
                ,[RO]
                ,[Receiving_Cost_Ponderado]
                ,[Total_Receiving_Cost_Ponderado]
                ,[OrderType]                         = CASE
                                                        WHEN [Embroidery] = 0.00 AND [Screen_Print] = 0.00 AND AF.[Sublimation] = 0.00 THEN 'Blanks/Transfers'
                                                        ELSE 'Customer Orders'
                                                      END
                ,[TypeContainer]                     = CASE
                                                        WHEN LEFT(AF.[Waybill], 3) = 'AIR' THEN 'AIR'
                                                        ELSE 'OCEAN'
                                                      END
                ,[Price_ScreenPrint]                = SPD.[Price_ScreenPrint]
                ,[Price_Sublimation]                = SPD.[Price_Sublimation]
                ,[Price_SubApplication]             = SPD.[Price_SubApplication]
                ,[CodePrice_EmbroideryApp]          = SPD.[CodePrice_EmbroideryApp]
                ,[Price_EmbroideryApp]              = SPD.[Price_EmbroideryApp]
                ,[CodePrice_EmbroideryHW]           = SPD.[CodePrice_EmbroideryHW]
                ,[Cost_PackingMaterial]             = SPD.[Price_EmbroideryHW] - SPD.[CodePrice_EmbroideryHW]
                ,[Price_EmbroideryHW]               = SPD.[Price_EmbroideryHW]
                ,[Price_HDP]                        = SPD.[Price_HDP]
                ,[Price_SpecialPK]                  = SPD.[Price_SpecialPK]
                ,[Price_Relabel]                    = SPD.[Price_Relabel]
                ,[Price_PigmentDye]                 = SPD.[Price_PigmentDye]
                ,[Price_InlandFreight]              = SPD.[Price_InlandFreight]
                ,[Price_AirFreight]                 = SPD.[Price_AirFreight]
                ,[Price_OceanFreight]               = SPD.[Price_OceanFreight]
                ,[OutboundFreight]                  = SPD.[OutboundFreight]
                ,[NumeroControl]                     = FE.[numeroControl]
                ,[CodigoGeneracion]                  = FE.[codigoGeneracion]
                ,[Sello]                             = FE.[sello]
                ,[MensajeRecepcion]                  = FE.[mensajeRecepcion]
                ,[ID]                                = AF.[ID]
            FROM [AppsLCA].[dbo].[ImportExport_AnexoFacturacion]        AS AF WITH(NOLOCK)
            LEFT JOIN [LCA].[dbo].[PackedBoxes]                         AS PB  WITH(NOLOCK) ON AF.[BoxNumber] = PB.[BoxNumber]
                                                                                             AND PB.[StatusID] = 75
            LEFT JOIN [LCA].[dbo].[Orders]                              AS OD  WITH(NOLOCK) ON PB.[OrderId] = OD.[OrderID]
            LEFT JOIN [LCA].[dbo].[DropDownValues2]                     AS DDV WITH(NOLOCK) ON OD.[OrderTypeID3] = DDV.[DropDownValueID]
            LEFT JOIN [AppsLCA].[dbo].[TB_ShipmentCheckPricesDetail]    AS SPD WITH(NOLOCK) ON SPD.[id] = AF.[IDCheckPrices]
            LEFT JOIN
            (
                SELECT DISTINCT
                     [waybill]         = [factura]
                    ,[batch]           = [items]
                    ,[numeroControl]
                    ,[codigoGeneracion]
                    ,[sello]
                    ,[mensajeRecepcion]
                    ,[cuenta]          = ROW_NUMBER() OVER(PARTITION BY [factura], [items] ORDER BY [factura], [items])
                FROM [AppsLCA].[dbo].[DTE_FACTURAS_ELECTRONICAS]
                WHERE [mensajeRecepcion] LIKE 'RECIBIDO%'
                  AND CAST([fecEmi] AS DATE) >= '2024-08-01'
            ) AS FE ON TRIM(REPLACE(REPLACE(REPLACE(AF.[Waybill], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) = FE.[waybill]
                   AND AF.[Batch] = FE.[batch]
                   AND FE.[cuenta] = 1
            WHERE (AF.[ShipDate] < '2024-08-01' OR [fe].[mensajeRecepcion] IS NOT NULL)
                        AND
                    AF.[ShipDate] >= @DateFrom AND AF.[ShipDate] <= @DateTo
            ORDER BY
                 [BoxNumber]
                ,[StyleNumber]
                ,[StyleColor]
                ,[Size]
                ,AF.[StyleOptionID]
        ) AS AF
        LEFT JOIN [LCA].[dbo].[PackedBoxes]      AS PBox WITH(NOLOCK) ON AF.[BoxNumber] = PBox.[BoxNumber]
        LEFT JOIN [LCA].[dbo].[ManufactureOrders] AS MO  WITH(NOLOCK) ON PBox.[ManufactureID] = MO.[ManufactureID]
        LEFT JOIN [LCA].[dbo].[OrderItems]       AS OI   WITH(NOLOCK) ON MO.[FirstOrderItemID] = OI.[OrderItemID]
        LEFT JOIN
        (
            SELECT
                 [StyleID]
                ,[StyleColorID]
                ,[ManufactureID]
                ,[RO_ID]
                ,[Season]
                ,[StyleColor]
                ,[NewSize] = CASE
                                WHEN RIGHT([PartNumber], 4) IN ('L_XL','L/XL') THEN RIGHT([PartNumber], 4)
                                WHEN RIGHT([PartNumber], 3) IN ('2XL','3XL','4XL','5XL','XXL','S_M','S_M','S/M','ONE') THEN RIGHT([PartNumber], 3)
                                WHEN RIGHT([PartNumber], 2) IN ('XS','XL','2T','3T','4T','5T','6T','7T','8T') THEN RIGHT([PartNumber], 2)
                                WHEN RIGHT([PartNumber], 1) IN ('S','M','L') THEN RIGHT([PartNumber], 1)
                                ELSE ''
                             END
                ,[PartNumber]
            FROM [LCA].[dboReaders].[VW_RawMaterials_Fabric_AllMOs_Pricing]
        ) AS VWRAW ON OI.[StyleID] = VWRAW.[StyleID]
                  AND OI.[StyleColorID] = VWRAW.[StyleColorID]
                  AND AF.[StyleColor] = VWRAW.[StyleColor]
                  AND AF.[ManufactureID] = VWRAW.[ManufactureID]
                  AND AF.[RO_ID] = VWRAW.[RO_ID]
                  AND AF.[SeasonName] = VWRAW.[Season]
                  AND VWRAW.[Season] IN ('EMB FG')
                  AND AF.[Size] = VWRAW.[NewSize]
                  AND AF.[PartNumber] = ''
    ) AS AFPN

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- UPDATE de UnitFreightCost_Ponderado / Total_UnitFreightCost_Ponderado (antes JOIN directo contra TB_MO_PartNumber_IM_Materials)
    -------------------------------------------------------------------------------------------------------------------------------------------------------
    UPDATE T SET
         T.[UnitFreightCost_Ponderado]       = IIF(
                                                    FAMF2.[MAKE] > 0
                                                AND FAMF2.[Contracts_FreightPrice] IS NOT NULL
                                                ,CONVERT(NUMERIC(18,4), ROUND(FAMF2.[Contracts_FreightPrice] / FAMF2.[MAKE], 4))
                                                ,0
                                            )
        ,T.[Total_UnitFreightCost_Ponderado] = T.[Qty] * IIF(
                                                                    FAMF2.[MAKE] > 0
                                                                AND FAMF2.[Contracts_FreightPrice] IS NOT NULL
                                                                ,CONVERT(NUMERIC(18,4), ROUND(FAMF2.[Contracts_FreightPrice] / FAMF2.[MAKE], 4))
                                                                ,0
                                                            )
    FROM #AnexoFacturacion AS T
    LEFT JOIN [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Materials] AS FAMF2 WITH(NOLOCK) ON T.[RO_ID] = FAMF2.[ManufactureID]

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- UPDATE de UnitFreightCost / Total_UnitFreightCost (antes JOIN directo contra TB_MO_PartNumber_IM)
    -------------------------------------------------------------------------------------------------------------------------------------------------------
    UPDATE T SET
         T.[UnitFreightCost]       = ISNULL(FAMF.[UnitFreightCost_Ponderado], 0)
        ,T.[Total_UnitFreightCost] = T.[Qty] * ISNULL(FAMF.[UnitFreightCost_Ponderado], 0)
    FROM #AnexoFacturacion AS T
    LEFT JOIN
    (
        SELECT
             [ManufactureID]
            ,[PartNumber]
            ,[UnitFreightCost_Ponderado] = ([UF1] / IIF([TC] = 0,1,[TC]))
            ,[Style]
            ,[Color]
            ,[Size]
        FROM
        (
            SELECT
                 [ManufactureID] = TF1.[ManufactureID]
                ,[PartNumber]   = TF1.[PartNumber]
                ,[UF1]          = SUM(TF1.[Consumption] * TF1.[UnitFreightCost])
                ,[TC]           = SUM(TF1.[Consumption])
                ,[Style]        = STC.[Style]
                ,[Color]        = STC.[Color]
                ,[Size]         = STC.[Size]
            FROM [AppsLCA].[dbo].[TB_MO_PartNumber_IM] AS TF1 WITH(NOLOCK)
            LEFT JOIN
            (
                SELECT DISTINCT
                     [ManufactureID]
                    ,[PartNumber]
                    ,[Style]
                    ,[Color]
                    ,[Size]
                FROM [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Freight] WITH(NOLOCK)
            ) AS STC ON TF1.[ManufactureID] = STC.[ManufactureID]
                    AND TF1.[PartNumber] = STC.[PartNumber]
            WHERE TF1.[Category] = 'Contracts'
            GROUP BY
                 TF1.[ManufactureID]
                ,TF1.[PartNumber]
                ,STC.[Style]
                ,STC.[Color]
                ,STC.[Size]
        ) AS ABC132
    ) AS FAMF ON T.[RO_ID] = FAMF.[ManufactureID]
             AND (
                        T.[StyleNumber] = FAMF.[Style]
                    AND T.[StyleColor] = FAMF.[Color]
                    AND T.[Size] = FAMF.[Size]
                 OR
                    CASE
                        WHEN T.[StyleNumber] = '21014' THEN 'EZ100-' + T.[StyleColor] + '-' + T.[Size]
                        WHEN T.[StyleNumber] IN ('10PDT','05PDT') THEN T.[StyleNumber] + '-PFD-' + T.[Size]
                        ELSE T.[PartNumber]
                    END = FAMF.[PartNumber]
             )

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- UPDATE de Invoice (antes JOIN directo contra ManufactureOrders)
    -------------------------------------------------------------------------------------------------------------------------------------------------------
    UPDATE T SET
        T.[Invoice] = LTRIM(
                            SUBSTRING(
                                 MOS.[Comments12]
                                ,CHARINDEX('Invoice: ', MOS.[Comments12]) + LEN('Invoice: ')
                                ,CHARINDEX(' |', MOS.[Comments12] + ' |', CHARINDEX('Invoice: ', MOS.[Comments12])) - (CHARINDEX('Invoice: ', MOS.[Comments12]) + LEN('Invoice: '))
                            )
                        )
    FROM #AnexoFacturacion AS T
    INNER JOIN [LCA].[dbo].[ManufactureOrders] AS MOS WITH(NOLOCK) ON T.[ManufactureID] = MOS.[ManufactureID]
    WHERE T.[Manufacturer] = 'NG TEXTILES GUATEMALA S.A.'

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- UPDATE de US_HTSCode (antes JOIN directo contra ImportExport_ShipmentBoxAll)
    -------------------------------------------------------------------------------------------------------------------------------------------------------
    UPDATE T SET
        T.[US_HTSCode] = SBA.[US_HTSCode]
    FROM #AnexoFacturacion AS T
    LEFT JOIN
    (
        SELECT
             [WayBill]
            ,[BoxNumber]
            ,[StyleNumber]
            ,[StyleColor]
            ,[GarmentSize]
            ,[US_HTSCode]
            ,[US_HTSDescription]
            ,[InvoicingDescription]
        FROM [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] WITH(NOLOCK)
        GROUP BY
             [WayBill]
            ,[BoxNumber]
            ,[StyleNumber]
            ,[StyleColor]
            ,[GarmentSize]
            ,[US_HTSCode]
            ,[US_HTSDescription]
            ,[InvoicingDescription]
    ) AS SBA ON SBA.[WayBill] = T.[Waybill]
            AND SBA.[BoxNumber] = T.[BoxNumber]
            AND SBA.[StyleNumber] = T.[StyleNumber]
            AND SBA.[StyleColor] = T.[StyleColor]
            AND SBA.[GarmentSize] = T.[Size]

    SELECT
         [ShipDate]
        ,[Waybill]
        ,[InvoiceBatch]
        ,[Batch]
        ,[PONumber]
        ,[BoxNumber]
        ,[StyleNumber]
        ,[StyleColor]
        ,[SeasonName]
        ,[Qty]
        ,[Supplier]
        ,[HTSCode]  = [SAC]
        ,[HTSDescription]
        ,[US_HTSCode]
        ,[PuertoDestino]
        ,[BasePrice]
        ,[Handling]
        ,[Total_Handling]
        ,[Freight]
        ,[Total_Freight]
        ,[BaseCost]
        ,[Total_Base_Cost]
        ,[Receiving_Cost]
        ,[Total_Receiving_Cost]
        ,[Purchase_order]
        ,[PrintCount]
        ,[Screen_Print]
        ,[Total_Screen_Print]
        ,[Embroidery]
        ,[Total_Embroidery]
        ,[Sublimation] 
        ,[Total_Sublimation]
        ,[Price]
        ,[Total$]
        ,[MO]
        ,[Embr_Code1]
        ,[Embr_Code2]
        ,[Embr_Code3]
        ,[Embr_Code4]
        ,[PrintLocations]
        ,[CountryOfOrigin]
        ,[ProductDivision]
        ,[Manufacturer]
        ,[SemiFinishProductCost]
        ,[SemiFinishProductCost_Fabric]
        ,[SemiFinishProductCost_Thread]
        ,[SemiFinishProductCost_Trim]
        ,[SemiFinishProductCost_Supplies]
        ,[SemiFinishProductCost_Contracts]
        ,[SemiFinishProductCost_SubAssembly]
        ,[FinishProductCost]
        ,[FinishProductCost_Fabric]
        ,[FinishProductCost_Thread]
        ,[FinishProductCost_Trim]
        ,[FinishProductCost_Supplies]
        ,[FinishProductCost_Contracts]
        ,[FinishProductCost_SubAssembly]
        ,[Incoterm]
        ,[Gross_Weight_kgs]
        ,[Net_Weight_kgs]
        ,[Container]
        ,[Consigned]
        ,[PartNumber]
        ,[CodigoGeneracion]
        ,[Sello]
        ,[NumeroControl]
        ,[Size]
        ,[RO]
        ,[OrderType]
        ,[TypeContainer]
        ,[Price_ScreenPrint]      
        ,[Price_Sublimation]      
        ,[Price_SubApplication]   
        ,[CodePrice_EmbroideryApp]
        ,[Price_EmbroideryApp]    
        ,[CodePrice_EmbroideryHW] 
        ,[Cost_PackingMaterial]   
        ,[Price_EmbroideryHW]     
        ,[Price_HDP]              
        ,[Price_SpecialPK]        
        ,[Price_Relabel]          
        ,[Price_PigmentDye]       
        ,[Price_InlandFreight]    
        ,[Price_AirFreight]       
        ,[Price_OceanFreight]     
        ,[OutboundFreight]
        ,[UnitFreightCost_Ponderado]      
        ,[Total_UnitFreightCost_Ponderado]
        ,[UnitFreightCost]                
        ,[Total_UnitFreightCost]          
        ,[Invoice]                                
    FROM #AnexoFacturacion ORDER BY ShipDate DESC

    SELECT 
     AF.*
    ,SE.SeasonName AS SeasonMO
    ,SE2.SeasonName AS SeasonRO
    FROM #AnexoFacturacion AS AF
    LEFT JOIN LCA.dbo.ManufactureOrders AS MO WITH(NOLOCK) ON AF.ManufactureID = MO.ManufactureID AND AF.SeasonName = 'EMB FG'
    LEFT JOIN LCA.dbo.OrderItems        AS OI WITH(NOLOCK) ON MO.FirstOrderItemID = OI.OrderItemID
    LEFT JOIN LCA.dbo.Styles            AS ST WITH(NOLOCK) ON OI.StyleID = ST.StyleID
    LEFT JOIN LCA.dbo.Styles            AS BS WITH(NOLOCK) ON ST.BlankStyleID = BS.StyleID
    LEFT JOIN LCA.dbo.Seasons           AS SE WITH(NOLOCK) ON BS.SeasonID = SE.SeasonID
    LEFT JOIN LCA.dbo.ManufactureOrders AS MO2 WITH(NOLOCK) ON AF.RO_ID = MO2.ManufactureID
    LEFT JOIN LCA.dbo.OrderItems        AS OI2 WITH(NOLOCK) ON MO2.FirstOrderItemID = OI2.OrderItemID
    LEFT JOIN LCA.dbo.Styles            AS ST2 WITH(NOLOCK) ON OI2.StyleID = ST2.StyleID
    LEFT JOIN LCA.dbo.Seasons           AS SE2 WITH(NOLOCK) ON ST2.SeasonID = SE2.SeasonID
    WHERE SE.SeasonName <> SE2.SeasonName

		
    SELECT 
         [ManufactureID]            = S.RO_ID
        ,[ManufactureCostID]	    = B.MO_A_ID
        ,[MOCost]				    = B.MO_A	
    INTO #TB_EORO_ChangeCost
    FROM #AnexoFacturacion AS S
    LEFT JOIN (
                SELECT * 
                FROM (
                        SELECT MO_A_ID,MO_B_ID,MO_A,MO_B,R = ROW_NUMBER() OVER (PARTITION BY MO_B_ID order by MO_B_ID ,packedItemID desc)
                        FROM AppsLCA.dbo.Financial_TB_MO_PARtNumber_IM_OriginalStyleInBox	with(nolock) ---cambio financial famosisima
                    --  FROM AppsLCA.dbo.TB_MO_PARtNumber_IM_OriginalStyleInBox	with(nolock)
                    ) AS B
                    WHERE B.R = 1
                )	AS B  ON B.[MO_B_ID] = S.[RO_ID]
                        
    ---Actualizacion de MOs que debe traer su costo. Por problema de cambio de manufactureID en Julio 2024
    UPDATE S SET
         [ROID_Cost]	= ISNULL(B.ManufactureCostID, S.RO_ID)
        ,[RO_Cost]	    = ISNULL(B.MOCost	, S.RO)
    FROM		#AnexoFacturacion				AS S
    LEFT JOIN #TB_EORO_ChangeCost	AS B  ON B.[ManufactureID] = S.[RO_ID]
    AND S.[ROID_Cost] IS NULL AND S.[SeasonName] = 'EMB FG'

UPDATE AF SET
    Receiving_Cost = A.CostoPonderado
    ,Total_Receiving_Cost = A.CostoPonderado * Qty
FROM #AnexoFacturacion AS AF
INNER JOIN
(
    select 
        sum(PurchaseOrderUnitPrice * iif(Consumption is null or Consumption=0,1,Consumption )) / 
        iif(sum(iif(Consumption is null or Consumption=0,1,Consumption ))=0,1,
        sum(iif(Consumption is null or Consumption=0,1,Consumption )))
            as CostoPonderado, ManufactureID
        from appslca.dbo.TB_MO_PartNumber_IM with (nolock)
        --where mo='TO0315O82176-HWTROH' and category='Contracts'
        where  category in ('Contracts','Fabric')
        group by ManufactureID
) AS A ON AF.ROID_Cost = A.ManufactureID
AND AF.ManufactureID IN
(
    978873
,978875
,978885
,978889
,978891
,978897
,978899
,978902
,978904
,980251
,940639
,940645
,947243
,947244
,947245
,947246
,947267
,947507
,947594
,947599
,947601
,947603
,947626
,948912
,948918
,949077
,949082
,949461
,949464
,954124
,954128
,954132
,954139
,1018361
,956406
,956411
,959418
,962904

) --AND AF.ManufactureID = 978897

return

SELECT 
    AF.Waybill
    ,af.ShipDate
    ,AF.MO
    ,AF.ManufactureID 
    ,AF.RO
    ,AF.RO_ID
    ,[Size]
    ,AF.BoxNumber
    ,AF.ID
    ,AF.RO_Cost
    ,AF.ROID_Cost
    ,AF.Receiving_Cost + af.UnitFreightCost_Ponderado
    ,Qty
    ,(AF.Receiving_Cost + af.UnitFreightCost_Ponderado) * Qty AS TotalReceiving
FROM #AnexoFacturacion AS AF WITH(NOLOCK)
WHERE MONTH(ShipDate) = 7 AND ManufactureID = 978897

SELECT 
    AF.Waybill
    ,af.ShipDate
    ,AF.MO
    ,AF.ManufactureID 
    ,AF.RO
    ,AF.RO_ID
    ,[Size]
    ,AF.BoxNumber
    ,AF.ID
    -- ,AF.RO_Cost
    -- ,AF.ROID_Cost
    ,AF.Receiving_Cost 
    ,Qty
    -- ,(AF.Receiving_Cost + af.UnitFreightCost_Ponderado) * Qty AS TotalReceiving
FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK)
WHERE MONTH(ShipDate) = 7 AND ManufactureID = 978897

SELECT
    SUM((AF.Receiving_Cost + af.UnitFreightCost_Ponderado) * Qty) AS TotalReceiving
FROM #AnexoFacturacion AS AF WITH(NOLOCK)
WHERE MONTH(ShipDate) = 7


 select 
        sum(PurchaseOrderUnitPrice * iif(Consumption is null or Consumption=0,1,Consumption )) / 
        iif(sum(iif(Consumption is null or Consumption=0,1,Consumption ))=0,1,
        sum(iif(Consumption is null or Consumption=0,1,Consumption )))
            as CostoPonderado, ManufactureID
        from appslca.dbo.TB_MO_PartNumber_IM with (nolock)
        --where mo='TO0315O82176-HWTROH' and category='Contracts'
        where  category in ('Contracts','Fabric') AND ManufactureID = 978897
        group by ManufactureID

select *         from appslca.dbo.TB_MO_PartNumber_IM with (nolock)
        --where mo='TO0315O82176-HWTROH' and category='Contracts'
        where  category in ('Contracts','Fabric') AND ManufactureID = 978897

        select *         from appslca.dbo.TB_MO_PartNumber_IM_Materials with (nolock)
        --where mo='TO0315O82176-HWTROH' and category='Contracts'
        where ManufactureID = 978897

-- select
-- *
-- into AppsLCA.dbo.ImportExport_AnexoFacturacion_NewReceivingCost
-- from #AnexoFacturacion
END
