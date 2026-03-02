USE [AppsLCA]
GO

/****** Object:  View [dbo].[VW_ImportExport_AnexoFacturacion]    Script Date: 28/02/2026 10:15:25 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



--select * from AppsLCA.dbo.TB_MO_PartNumber_IM_Materials where mo in ('EO3701357-441','RO022805PDT-101')

--ALTER VIEW [dbo].[VW_ImportExport_AnexoFacturacion]
--AS
;WITH CTE_ImportExport_AnexoFacturacion AS (
    SELECT TOP 100 PERCENT
         [ShipDate]
        ,[Waybill]
        ,[InvoiceBatch]
        ,[Batch]
        ,[PONumber]
        ,[BoxNumber]
        ,[StyleNumber]
        ,[StyleColor]
        ,[SeasonName]
        ,[qty]
        ,[Supplier]
        ,[SAC]
        ,[HTSDescription]
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
        ,[ManufactureID]
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
    FROM [AppsLCA].[dbo].[ImportExport_AnexoFacturacion] AS AF WITH (NOLOCK)
    WHERE [Waybill] = 'AIR-APP-20260216'
    --WHERE ShipDate >= '2024-08-01' AND ShipDate <= '2024-08-31'
    --where ro='RO022805PDT-101' and Waybill ='APP-20250227'--BoxNumber = '00824507'-- AND Size = 'L'
    --and RO_ID IS NOT NULL
    --and StyleNumber NOT IN ('Fabric','Sublimation','Supplies','Trim')
    ORDER BY [BoxNumber],[StyleNumber],[StyleColor],[Size],[StyleOptionID]
)
SELECT
     AFPN.*
    ,[UnitFreightCost_Ponderado] = IIF(
        FAMF2.[MAKE] > 0
        AND FAMF2.[Contracts_FreightPrice] IS NOT NULL,
        CONVERT(NUMERIC(18, 4), ROUND(FAMF2.[Contracts_FreightPrice] / FAMF2.[MAKE], 4)),
        0
    )
    ,[Total_UnitFreightCost_Ponderado] = AFPN.[Qty] * IIF(
        FAMF2.[MAKE] > 0
        AND FAMF2.[Contracts_FreightPrice] IS NOT NULL,
        CONVERT(NUMERIC(18, 4), ROUND(FAMF2.[Contracts_FreightPrice] / FAMF2.[MAKE], 4)),
        0
    )
    ,[UnitFreightCost] = ISNULL(FAMF.[UnitFreightCost_Ponderado], 0)
    ,[Total_UnitFreightCost] = AFPN.[Qty] * ISNULL(FAMF.[UnitFreightCost_Ponderado], 0)
    ,[Invoice] = CASE
        WHEN AFPN.[Manufacturer] = 'NG TEXTILES GUATEMALA S.A.' THEN LTRIM(
            SUBSTRING(
                MOS.[Comments12],
                CHARINDEX('Invoice: ', MOS.[Comments12]) + LEN('Invoice: '),
                CHARINDEX(' |', MOS.[Comments12] + ' |', CHARINDEX('Invoice: ', MOS.[Comments12]))
                    - (CHARINDEX('Invoice: ', MOS.[Comments12]) + LEN('Invoice: '))
            )
        )
        ELSE NULL
    END
	--select *
FROM (
		SELECT
			 [ShipDate]
			,[Waybill]
			,[InvoiceBatch]
			,[Batch]
			,[PONumber]
			,AF.[BoxNumber]
			,[StyleNumber]
			,AF.[StyleColor]
			,[SeasonName]
			,[qty]
			,[Supplier]
			,[SAC]
			,[HTSDescription]
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
			,AF.[ManufactureID]
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
			,[PartNumber] = CASE
				WHEN AF.[PartNumber] IS NULL OR AF.[PartNumber] = '' THEN ISNULL(VWRAW.[PartNumber], '')
				ELSE ISNULL(AF.[PartNumber], '')
			 END
			,[Size]
			,AF.[RO_ID]
			,[RO]
			,AF.[Receiving_Cost_Ponderado]
			,AF.[Total_Receiving_Cost_Ponderado]
		FROM CTE_ImportExport_AnexoFacturacion AS AF
		LEFT OUTER JOIN [LCA].[dbo].[PackedBoxes] AS PBox WITH (NOLOCK)
			ON AF.[BoxNumber] = PBox.[BoxNumber]
		LEFT OUTER JOIN [LCA].[dbo].[ManufactureOrders] AS MO WITH (NOLOCK)
			ON PBox.[ManufactureID] = MO.[ManufactureID]
		LEFT OUTER JOIN [LCA].[dbo].[OrderItems] AS OI WITH (NOLOCK)
			ON MO.[FirstOrderItemID] = OI.[OrderItemID]
		LEFT OUTER JOIN (
			SELECT
				 [StyleID]
				,[StyleColorID]
				,[ManufactureID]
				,[RO_ID]
				,[Season]
				,[StyleColor]
				,[NewSize] = CASE
					WHEN RIGHT([PartNumber], 4) IN ('L_XL', 'L/XL')
						THEN RIGHT([PartNumber], 4)
					WHEN RIGHT([PartNumber], 3) IN ('2XL', '3XL', '4XL', '5XL', 'XXL', 'S_M', 'S_M', 'S/M')
						THEN RIGHT([PartNumber], 3)
					WHEN RIGHT([PartNumber], 2) IN ('XS', 'XL', '2T', '3T', '4T', '5T', '6T', '7T', '8T')
						THEN RIGHT([PartNumber], 2)
					WHEN RIGHT([PartNumber], 1) IN ('S', 'M', 'L')
						THEN RIGHT([PartNumber], 1)
					ELSE ''
				 END
				,[PartNumber]
			FROM [LCA].[dboReaders].[VW_RawMaterials_Fabric_AllMOs_Pricing]
		) AS VWRAW
			ON OI.[StyleID] = VWRAW.[StyleID]
			AND OI.[StyleColorID] = VWRAW.[StyleColorID]
			AND AF.[StyleColor] = VWRAW.[StyleColor]
			AND AF.[ManufactureID] = VWRAW.[ManufactureID]
			AND AF.[RO_ID] = VWRAW.[RO_ID]
			AND AF.[SeasonName] = VWRAW.[Season]
			AND VWRAW.[Season] IN ('EMB FG')
			AND AF.[Size] = VWRAW.[NewSize]
			AND AF.[PartNumber] = ''
											
	) AFPN
LEFT OUTER JOIN [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Freight] AS FAMF WITH (NOLOCK)
	ON AFPN.[RO_ID] = FAMF.[ManufactureID]
	AND AFPN.[StyleNumber] = FAMF.[Style]
	AND AFPN.[StyleColor] = FAMF.[Color]
	AND AFPN.[Size] = FAMF.[Size]
--CASE WHEN AFPN.StyleNumber = '21014' THEN 'EZ100-'+AFPN.StyleColor+'-'+AFPN.Size
--	 WHEN AFPN.StyleNumber IN ('10PDT','05PDT') THEN AFPN.StyleNumber+'-PFD-'+AFPN.Size
--	else AFPN.PartNumber 
--	END = FAMF.PartNumber
LEFT JOIN [LCA].[DBO].[ManufactureOrders] AS MOS WITH (NOLOCK)
	ON AFPN.[MANUFACTUREID] = MOS.[ManufactureID]
LEFT JOIN [AppsLCA].[dbo].[tb_mo_PartNumber_IM_Materials] AS FAMF2 WITH (NOLOCK)
	ON AFPN.[RO_ID] = FAMF2.[ManufactureID]
--WHERE AFPN.ManufactureID = 829484


SELECT
	ManufactureID
	,MO
	,PurchaseOrderUnitPrice_Ponderado
	,UnitFreightCost_Ponderado
	,Style
	,Color
	,Size
FROM AppsLCA.dbo.TB_MO_PartNumber_IM_Freight
WHERE ManufactureID IN
(
--770519
--,704039
--,732478
--,748259
604197
)
GROUP BY
	ManufactureID
	,MO
	,PurchaseOrderUnitPrice_Ponderado
	,UnitFreightCost_Ponderado
	,Style
	,Color
	,Size
--WHERE MO = 'EO5222632-417'


SELECT
*
FROM AppsLCA.dbo.TB_MO_PartNumber_IM_Materials
WHERE ManufactureID IN
(
770519
,704039
,732478
,748259
)


GO


