USE [AppsLCA]
GO

/****** Object:  View [dbo].[VW_ImportExport_AnexoFacturacion]    Script Date: 09/06/2026 02:00:58 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




--select * from AppsLCA.dbo.TB_MO_PartNumber_IM_Materials where mo in ('EO3701357-441','RO022805PDT-101')

ALTER VIEW [dbo].[VW_ImportExport_AnexoFacturacion]
AS
SELECT
     AFPN.*
    ,[UnitFreightCost_Ponderado]       = IIF(
                                                FAMF2.[MAKE] > 0
                                            AND FAMF2.[Contracts_FreightPrice] IS NOT NULL
                                            ,CONVERT(NUMERIC(18,4), ROUND(FAMF2.[Contracts_FreightPrice] / FAMF2.[MAKE], 4))
                                            ,0
                                        )
    ,[Total_UnitFreightCost_Ponderado] = AFPN.[Qty] * IIF(
                                                                FAMF2.[MAKE] > 0
                                                            AND FAMF2.[Contracts_FreightPrice] IS NOT NULL
                                                            ,CONVERT(NUMERIC(18,4), ROUND(FAMF2.[Contracts_FreightPrice] / FAMF2.[MAKE], 4))
                                                            ,0
                                                        )
    ,[UnitFreightCost]                 = ISNULL(FAMF.[UnitFreightCost_Ponderado], 0)
    ,[Total_UnitFreightCost]           = AFPN.[Qty] * ISNULL(FAMF.[UnitFreightCost_Ponderado], 0)
    ,[Invoice]                         = CASE
                                            WHEN AFPN.[Manufacturer] = 'NG TEXTILES GUATEMALA S.A.' THEN
                                                LTRIM(
                                                    SUBSTRING(
                                                         MOS.[Comments12]
                                                        ,CHARINDEX('Invoice: ', MOS.[Comments12]) + LEN('Invoice: ')
                                                        ,CHARINDEX(' |', MOS.[Comments12] + ' |', CHARINDEX('Invoice: ', MOS.[Comments12])) - (CHARINDEX('Invoice: ', MOS.[Comments12]) + LEN('Invoice: '))
                                                    )
                                                )
                                            ELSE NULL
                                          END
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
    FROM
    (
        SELECT TOP 100 PERCENT
             [ShipDate]                          = AF.[ShipDate]
            ,[Waybill]
            ,[InvoiceBatch]
            ,[Batch]
            ,[PONumber]                          = AF.[PONumber]
            ,[BoxNumber]                         = AF.[BoxNumber]
            ,[StyleNumber]
            ,[StyleColor]
            ,[SeasonName]
            ,[Qty]
            ,[Supplier]
            ,[SAC]
            ,[HTSDescription]
            ,[PuertoDestino]                     = DDV.[DropDownValue]
            ,[BasePrice]
            ,[Handling]
            ,[Total_Handling]
            ,[Freight]                           = AF.[Freight]
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
            ,[PartNumber]
            ,[Size]
            ,[RO_ID]
            ,[RO]
            ,[Receiving_Cost_Ponderado]
            ,[Total_Receiving_Cost_Ponderado]
            ,[OrderType]                         = CASE
                                                    WHEN [Embroidery] = 0.00 AND [Screen_Print] = 0.00 AND [Sublimation] = 0.00 THEN 'Blanks/Transfers'
                                                    ELSE 'Customer Orders'
                                                  END
            ,[TypeContainer]                     = CASE
                                                    WHEN LEFT([Waybill], 3) = 'AIR' THEN 'AIR'
                                                    ELSE 'OCEAN'
                                                  END
        FROM [AppsLCA].[dbo].[ImportExport_AnexoFacturacion] AS AF WITH(NOLOCK)
        LEFT JOIN [LCA].[dbo].[PackedBoxes]       AS PB  WITH(NOLOCK) ON AF.[BoxNumber] = PB.[BoxNumber]
                                                                       AND PB.[StatusID] = 75
        LEFT JOIN [LCA].[dbo].[Orders]            AS OD  WITH(NOLOCK) ON PB.[OrderId] = OD.[OrderID]
        LEFT JOIN [LCA].[dbo].[DropDownValues2]   AS DDV WITH(NOLOCK) ON OD.[OrderTypeID3] = DDV.[DropDownValueID]
        -- WHERE BoxNumber = '01101240'
        -- WHERE ShipDate >= '2024-08-01' AND ShipDate <= '2024-08-31'
        -- WHERE RO = 'RO022805PDT-101' AND Waybill = 'APP-20250227' -- BoxNumber = '00824507' -- AND Size = 'L'
        -- AND RO_ID IS NOT NULL
        -- AND StyleNumber NOT IN ('Fabric','Sublimation','Supplies','Trim')
        ORDER BY
             [BoxNumber]
            ,[StyleNumber]
            ,[StyleColor]
            ,[Size]
            ,[StyleOptionID]
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
                            WHEN RIGHT([PartNumber], 3) IN ('2XL','3XL','4XL','5XL','XXL','S_M','S_M','S/M') THEN RIGHT([PartNumber], 3)
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
        WHERE TF1.[Category] = 'Contracts' -- AND TF1.[PartNumber] = '05PDT-PFD-M'
        -- WHERE TF1.[ManufactureID] = 770511 AND TF1.[Category] = 'Contracts' AND TF1.[PartNumber] = '05PDT-PFD-M'
        GROUP BY
             TF1.[ManufactureID]
            ,TF1.[PartNumber]
            ,STC.[Style]
            ,STC.[Color]
            ,STC.[Size]
    ) AS ABC132
) AS FAMF ON AFPN.[RO_ID] = FAMF.[ManufactureID]
         AND (
                    AFPN.[StyleNumber] = FAMF.[Style]
                AND AFPN.[StyleColor] = FAMF.[Color]
                AND AFPN.[Size] = FAMF.[Size]
             OR
                CASE
                    WHEN AFPN.[StyleNumber] = '21014' THEN 'EZ100-' + AFPN.[StyleColor] + '-' + AFPN.[Size]
                    WHEN AFPN.[StyleNumber] IN ('10PDT','05PDT') THEN AFPN.[StyleNumber] + '-PFD-' + AFPN.[Size]
                    ELSE AFPN.[PartNumber]
                END = FAMF.[PartNumber]
         )
-- AppsLCA.dbo.TB_MO_PartNumber_IM_Freight FAMF WITH(NOLOCK)
LEFT JOIN [LCA].[dbo].[ManufactureOrders] AS MOS WITH(NOLOCK) ON AFPN.[ManufactureID] = MOS.[ManufactureID]
LEFT JOIN [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Materials] AS FAMF2 WITH(NOLOCK) ON AFPN.[RO_ID] = FAMF2.[ManufactureID]
-- WHERE ShipDate >= '2026-01-01' and ShipDate <= '2026-05-31'


GO
