DROP TABLE IF EXISTS #TB_Anexo
DROP TABLE IF EXISTS #TB_MO_FILTER
DROP TABLE IF EXISTS #TB_Final

SELECT 
    [ShipDate]
    ,[Waybill]
    ,[InvoiceBatch]
    ,[Batch]
    ,[PONumber]
    ,[BoxNumber]
    ,[StyleNumber]
    ,[SeasonName]
    ,[Qty]
    ,[Size]
    ,[Supplier]
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
    ,[RO]
    ,[RO_ID]
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
    ,[OrderId]
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
    ,[Sure]
    ,[Consigned]
    ,[StyleColor]
    ,[PartNumber]
    ,[ManufactureID]
    ,[STdCost_Fabric]
    ,[STdCost_Thread]
    ,[STdCost_Trims]
    ,[STdCost_Handling]
    ,[STdCost_SewLabor]
    ,[STdCost_Supplies]
    ,[STdCost_CutLabor]
    ,[STdCost_Contracts]
    ,[STdCost_Subassembly]
    ,[StyleOptionID]
    ,[StyleOptionName]
    ,[UnitStdCost_Fabric]
    ,[UnitStdCost_Thread]
    ,[UnitStdCost_Trims]
    ,[UnitStdCost_Handling]
    ,[UnitStdCost_SewLabor]
    ,[UnitStdCost_Supplies]
    ,[UnitStdCost_CutLabor]
    ,[UnitStdCost_Contracts]
    ,[UnitStdCost_Subassembly]
    ,[SAC]
    ,[UDM]
    ,[ComponentValue]
    ,[AssemblyValue]
    ,[Waybill_Freight]
    ,[Receiving_Cost_Ponderado]
    ,[Total_Receiving_Cost_Ponderado]
    ,CAST(0 AS BIT) AS Invalidado
    ,CAST(NULL AS VARCHAR(20)) AS [LCA_CONTRACT]
    ,CAST('L2 Brands LLC' AS VARCHAR(100)) AS Customer
INTO #TB_Anexo
FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK)
WHERE ShipDate <= '2024-07-31'

INSERT INTO #TB_Anexo
SELECT 
    [ShipDate]
    ,[Waybill]
    ,[InvoiceBatch]
    ,[Batch]
    ,[PONumber]
    ,[BoxNumber]
    ,[StyleNumber]
    ,[SeasonName]
    ,[Qty]
    ,[Size]
    ,[Supplier]
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
    ,[RO]
    ,[RO_ID]
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
    ,[OrderId]
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
    ,[Sure]
    ,[Consigned]
    ,[StyleColor]
    ,[PartNumber]
    ,[ManufactureID]
    ,[STdCost_Fabric]
    ,[STdCost_Thread]
    ,[STdCost_Trims]
    ,[STdCost_Handling]
    ,[STdCost_SewLabor]
    ,[STdCost_Supplies]
    ,[STdCost_CutLabor]
    ,[STdCost_Contracts]
    ,[STdCost_Subassembly]
    ,[StyleOptionID]
    ,[StyleOptionName]
    ,[UnitStdCost_Fabric]
    ,[UnitStdCost_Thread]
    ,[UnitStdCost_Trims]
    ,[UnitStdCost_Handling]
    ,[UnitStdCost_SewLabor]
    ,[UnitStdCost_Supplies]
    ,[UnitStdCost_CutLabor]
    ,[UnitStdCost_Contracts]
    ,[UnitStdCost_Subassembly]
    ,[SAC]
    ,[UDM]
    ,[ComponentValue]
    ,[AssemblyValue]
    ,[Waybill_Freight]
    ,[Receiving_Cost_Ponderado]
    ,[Total_Receiving_Cost_Ponderado]
    ,CAST(0 AS BIT) AS Invalidado
    ,CAST(NULL AS VARCHAR(20)) AS [LCA_CONTRACT]
    ,CASE 
        WHEN
            (R.nombre LIKE '%L2 Brands%' OR R.nombre LIKE '%NG TEXTILES GUATEMALA%' OR R.nombre LIKE '%FIBERTEX%') THEN R.nombre 
        ELSE
            'OTHERS'
     END AS Customer
FROM AppsLCA.dbo.ImportExport_AnexoFacturacion      AS AF WITH(NOLOCK) 
INNER JOIN AppsLCA.dbo.DTE_FACTURAS_ELECTRONICAS    AS FE WITH(NOLOCK) ON AF.Waybill = FE.factura AND AF.ShipDate > '2024-07-31' AND invalidado = 0 AND AF.Batch = FE.items
INNER JOIN AppsLCA.dbo.DTE_RECEPTOR                 AS R  WITH(NOLOCK) ON FE.idReceptor = R.id

INSERT INTO #TB_Anexo
SELECT 
    [ShipDate]
    ,[Waybill]
    ,[InvoiceBatch]
    ,[Batch]
    ,[PONumber]
    ,[BoxNumber]
    ,[StyleNumber]
    ,[SeasonName]
    ,[Qty]
    ,[Size]
    ,[Supplier]
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
    ,[RO]
    ,[RO_ID]
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
    ,[OrderId]
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
    ,[Sure]
    ,[Consigned]
    ,[StyleColor]
    ,[PartNumber]
    ,[ManufactureID]
    ,[STdCost_Fabric]
    ,[STdCost_Thread]
    ,[STdCost_Trims]
    ,[STdCost_Handling]
    ,[STdCost_SewLabor]
    ,[STdCost_Supplies]
    ,[STdCost_CutLabor]
    ,[STdCost_Contracts]
    ,[STdCost_Subassembly]
    ,[StyleOptionID]
    ,[StyleOptionName]
    ,[UnitStdCost_Fabric]
    ,[UnitStdCost_Thread]
    ,[UnitStdCost_Trims]
    ,[UnitStdCost_Handling]
    ,[UnitStdCost_SewLabor]
    ,[UnitStdCost_Supplies]
    ,[UnitStdCost_CutLabor]
    ,[UnitStdCost_Contracts]
    ,[UnitStdCost_Subassembly]
    ,[SAC]
    ,[UDM]
    ,[ComponentValue]
    ,[AssemblyValue]
    ,[Waybill_Freight]
    ,[Receiving_Cost_Ponderado]
    ,[Total_Receiving_Cost_Ponderado]
    ,CAST(0 AS BIT) AS Invalidado
    ,CAST(NULL AS VARCHAR(20)) AS [LCA_CONTRACT]
    ,'L2 Brands LLC'
FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK) 
WHERE AF.Waybill = 'AIR-APP-20241022'


UPDATE AF SET
    ProductDivision = ST.Comments9
FROM #TB_Anexo AS AF
INNER JOIN (SELECT DISTINCT Comments9, StyleNumber FROM LCA.dbo.Styles AS ST WITH(NOLOCK) WHERE StatusID = 64) AS ST ON AF.StyleNumber = ST.StyleNumber AND (AF.ProductDivision IS NULL OR AF.ProductDivision = 'Fleece')

UPDATE AF SET
    ProductDivision = 'Apparel'
FROM #TB_Anexo AS AF
WHERE StyleNumber LIKE 'PROTO%' AND ProductDivision IS NULL

UPDATE AF SET
    ProductDivision = 'Fabric'
FROM #TB_Anexo AS AF
WHERE Waybill = 'DEV-FABRIC20241125' AND ProductDivision IS NULL or ProductDivision = 'NONE' or ProductDivision = ''

UPDATE AF SET
    ProductDivision = 'Supplies'
FROM #TB_Anexo AS AF
WHERE Waybill = 'DEV-SINAI20241029'

UPDATE AF SET
    ProductDivision = 'Trim'
FROM #TB_Anexo AS AF
WHERE StyleNumber = 'Sublimation'

UPDATE AF SET
    ProductDivision = CASE 
                        WHEN LEFT(Waybill, 3) = 'ARD' THEN 'Services'
                        WHEN LEFT(Waybill, 4) = 'DESP' THEN 'Leftover'
                        WHEN AF.StyleNumber IN ('Fabric','Thread','Trim','Supplies', 'SWATCH') THEN AF.StyleNumber
                        ELSE ProductDivision
                        END
FROM #TB_Anexo AS AF

UPDATE AF SET
    Price = A.UnitPrice
FROM #TB_Anexo AS AF
INNER JOIN
(
    SELECT 
        AF.BoxNumber
        ,MAX(OI.UnitPrice) AS UnitPrice
    FROM #TB_Anexo AS AF
    INNER JOIN LCA.dbo.PackedBoxes          AS PB ON AF.BoxNumber = PB.BoxNumber
    INNER JOIN LCA.dbo.PackedItems          AS PC ON PC.PackedBoxID = PB.PackedBoxID
    INNER JOIN LCA.dbo.ManufactureOrders    AS MO ON MO.ManufactureID = PC.ManufactureID
    INNER JOIN LCA.dbo.OrderItems           AS OI ON OI.OrderItemID = MO.FirstOrderItemID
    WHERE Price = 0 OR Price IS NULL AND Qty > 0 
    GROUP BY
        AF.BoxNumber
) AS A ON AF.BoxNumber = A.BoxNumber

UPDATE AF SET
    Total$ = Qty * Price
FROM #TB_Anexo AS AF
WHERE Total$ IS NULL OR Total$ = 0

DELETE FROM #TB_Anexo WHERE ShipDate IS NULL

DELETE FROM #TB_Anexo WHERE Qty = 0

-- SELECT SUM(Qty) as qty, Waybill
-- FROM #TB_Anexo 
-- GROUP BY Waybill
-- ORDER BY Waybill

INSERT INTO #TB_Anexo
(
     ShipDate
    ,Waybill
    ,Batch
    ,Qty
    ,Total$
    ,Invalidado
    ,Customer
)
SELECT 
    fecEmi
    ,factura
    ,items
    ,cantidad
    ,monto  
    ,invalidado
    ,CASE 
        WHEN
            (R.nombre LIKE '%L2 Brands%' OR R.nombre LIKE '%NG TEXTILES GUATEMALA%' OR R.nombre LIKE '%FIBERTEX%') THEN R.nombre 
        ELSE
            'OTHERS'
     END AS Customer
FROM  AppsLCA.dbo.DTE_FACTURAS_ELECTRONICAS AS DTE_FE	WITH(NOLOCK) 
INNER JOIN AppsLCA.dbo.DTE_RECEPTOR         AS R  WITH(NOLOCK) ON DTE_FE.idReceptor = R.id
WHERE DTE_FE.tipoDte = 11 AND  fecEmi > '2024-08-01' AND invalidado = 1
AND factura IN (SELECT DISTINCT Waybill FROM #TB_Anexo)

-- MO'S 2023
UPDATE AN SET
    AN.ManufactureID = SMO.MOID
    --select *
FROM #TB_Anexo AS AN
INNER JOIN [LCA].[dbo].[VW_Check_Sales_Prices_in_Invoices_SeekMO_3] SMO ON AN.BoxNumber = SMO.BoxNumber AND AN.ShipDate >= '2023-01-01' AND AN.ShipDate <= '2023-12-31' AND AN.ManufactureID IS NULL
-- where an.Waybill = 'SM20230203-SV'


UPDATE AN SET
    AN.ManufactureID = SMO.MOID
    --select *
FROM #TB_Anexo AS AN
INNER JOIN [LCA].[dbo].[VW_Check_Sales_Prices_in_Invoices_SeekMO_Bundle] SMO ON AN.BoxNumber = SMO.BoxNumber AND AN.ManufactureID IS NULL
-- where an.Waybill = 'SM20230203-SV'


SELECT DISTINCT
    [ManufactureID]    = MO.ManufactureID
        ,[MO]               = MO.ManufactureNumber
        ,[WorkFlowID]       = CAST(NULL AS INT)
        ,[WorkFlowName]     = CAST(NULL AS VARCHAR(MAX))
        ,[Embroidery]       = CAST(0 AS INT)
        ,[Screen_Print]     = CAST(0 AS INT)
        ,[Sublimado]        = CAST(0 AS INT)
INTO #TB_MO_FILTER
FROM #TB_Anexo                                      AS AN
INNER JOIN      LCA.dbo.ManufactureOrders           AS MO   WITH(NOLOCK) ON MO.[ManufactureID]  = AN.[ManufactureID]         



--- BORDADO DE PRENDAS ---

UPDATE MO SET
        [WorkFlowID]       = WF.WorkFlowID
    ,[WorkFlowName]     = WF.WorkFlowName
FROM #TB_MO_FILTER AS MO
INNER JOIN LCA.dbo.WorkFlows AS WF WITH (NOLOCK) ON MO.ManufactureID = WF.ManufactureID

UPDATE MO SET
    [Embroidery]           =   IIF(WT_01.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_02.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_03.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_04.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_05.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_06.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_07.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_08.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_09.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_10.TaskName  IS NOT NULL, 1, 0)

FROM #TB_MO_FILTER       AS MO
LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish Embroidery 1'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish Embroidery 2'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish Embroidery 3'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Finish Embroidery 4'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'Finish Embroidery 5'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'Finish Embroidery 6'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'Finish Embroidery 7'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'Finish Embroidery 8'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_09    WITH(NOLOCK) ON MO.WorkFlowID = WT_09.WorkFlowID    AND WT_09.TaskName  = 'Finish Embroidery 9'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_10    WITH(NOLOCK) ON MO.WorkFlowID = WT_10.WorkFlowID    AND WT_10.TaskName  = 'Finish Embroidery 10'

--- BORDADO DE GORRAS

UPDATE MO SET
    [Embroidery]            =   IIF(WT_01.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_02.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_03.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_04.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_05.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_06.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_07.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_08.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_09.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_10.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_11.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_12.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_13.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_14.TaskName  IS NOT NULL, 1, 0) 
FROM #TB_MO_FILTER       AS MO
LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish Embroidery  HW 1'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish Embroidery  HW 2'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish Embroidery  HW 3'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Finish Embroidery  HW 4'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'Finish Embroidery  HW 5'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'Finish Embroidery  HW 6'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'Finish Embroidery  HW 7'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'Finish Embroidery  HW 8'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_09    WITH(NOLOCK) ON MO.WorkFlowID = WT_09.WorkFlowID    AND WT_09.TaskName  = 'Finish Embroidery  HW 9'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_10    WITH(NOLOCK) ON MO.WorkFlowID = WT_10.WorkFlowID    AND WT_10.TaskName  = 'Finish Embroidery  HW 10'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_11    WITH(NOLOCK) ON MO.WorkFlowID = WT_11.WorkFlowID    AND WT_11.TaskName  = 'Finish Embroidery Post HW 1'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_12    WITH(NOLOCK) ON MO.WorkFlowID = WT_12.WorkFlowID    AND WT_12.TaskName  = 'Finish Embroidery Post HW 2'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_13    WITH(NOLOCK) ON MO.WorkFlowID = WT_13.WorkFlowID    AND WT_13.TaskName  = 'Finish Embroidery Post HW 3'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_14    WITH(NOLOCK) ON MO.WorkFlowID = WT_14.WorkFlowID    AND WT_14.TaskName  = 'Finish Embroidery Post HW 4'
WHERE Embroidery = 0


--- SERIGRAFIA

UPDATE MO SET
    [Screen_Print]            =   IIF(WT_01.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_02.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_03.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_04.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_05.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_06.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_07.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_08.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_09.TaskName  IS NOT NULL, 1, 0) +
                            IIF(WT_10.TaskName  IS NOT NULL, 1, 0)
FROM #TB_MO_FILTER       AS MO
LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish Print 1'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish Print 2'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish Print 3'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Finish Print 4'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'Finish Print 5'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'Finish Print 6'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'Finish Print 7'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'Finish Print 8'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_09    WITH(NOLOCK) ON MO.WorkFlowID = WT_09.WorkFlowID    AND WT_09.TaskName  = 'Finish Print 9'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_10    WITH(NOLOCK) ON MO.WorkFlowID = WT_10.WorkFlowID    AND WT_10.TaskName  = 'Finish Print 10'


--- SUBLIMADO

UPDATE MO SET
    [Sublimado]            =   IIF(WT_01.TaskName  IS NOT NULL, 1, 0) +
                                IIF(WT_02.TaskName  IS NOT NULL, 1, 0) +
                                IIF(WT_03.TaskName  IS NOT NULL, 1, 0)
FROM #TB_MO_FILTER       AS MO
LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish Sublimation Process'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish SUB Application 1'
LEFT JOIN LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish SUB Application 2'


--- UPDATE EMBELISHMENT

UPDATE AN SET
    AN.Embroidery = OrdPR.TotalPrintValue
    ,AN.Total_Embroidery = AN.Qty * OrdPR.TotalPrintValue
FROM #TB_Anexo AS AN
INNER JOIN [LCA].[dboReaders].[VW_Planning_OrderItemsPriceRev_2] OrdPR ON AN.ManufactureID = OrdPR.ManufactureID AND AN.PONumber = OrdPR.PONumber AND AN.StyleColor = OrdPR.Color
INNER JOIN #TB_MO_FILTER AS MO ON AN.ManufactureID = MO.ManufactureID AND MO.Embroidery > 0
AND (AN.Embroidery IS NULL OR AN.Embroidery = 0)

UPDATE AN SET
    AN.Embroidery = ORDPR_2.[Total Print Value]
    ,AN.Total_Embroidery = AN.Qty * ORDPR_2.[Total Print Value]
FROM #TB_Anexo AS AN
INNER JOIN [LCA].[dboReaders].[VW_Planning_OrderItemsPriceRev_3] ORDPR_2
				on	AN.BoxNumber = OrdPR_2.boxnumber and
					AN.StyleNumber = COALESCE(ORDPR_2.BlankStyle,ORDPR_2.StyleNumber) and
					AN.Size = ORDPR_2.GarmentSize and
					AN.Stylecolor	 = ORDPR_2.StyleColorName
INNER JOIN #TB_MO_FILTER AS MO ON AN.ManufactureID = MO.ManufactureID AND MO.Embroidery > 0
AND (AN.Embroidery IS NULL OR AN.Embroidery = 0)

UPDATE AN SET
    AN.Screen_Print = OrdPR.TotalPrintValue
    ,AN.Total_Screen_Print = AN.Qty * OrdPR.TotalPrintValue
FROM #TB_Anexo AS AN
INNER JOIN [LCA].[dboReaders].[VW_Planning_OrderItemsPriceRev_2] OrdPR ON AN.ManufactureID = OrdPR.ManufactureID AND AN.PONumber = OrdPR.PONumber AND AN.StyleColor = OrdPR.Color
INNER JOIN #TB_MO_FILTER AS MO ON AN.ManufactureID = MO.ManufactureID AND MO.Screen_Print > 0
AND (an.Screen_Print IS NULL OR an.Screen_Print = 0)

UPDATE AN SET
    AN.Screen_Print = ORDPR_2.[Total Print Value]
    ,AN.Total_Screen_Print = AN.Qty * ORDPR_2.[Total Print Value]
FROM #TB_Anexo AS AN
INNER JOIN [LCA].[dboReaders].[VW_Planning_OrderItemsPriceRev_3] ORDPR_2
				on	AN.BoxNumber = OrdPR_2.boxnumber and
					AN.StyleNumber = COALESCE(ORDPR_2.BlankStyle,ORDPR_2.StyleNumber) and
					AN.Size = ORDPR_2.GarmentSize and
					AN.Stylecolor	 = ORDPR_2.StyleColorName
INNER JOIN #TB_MO_FILTER AS MO ON AN.ManufactureID = MO.ManufactureID AND MO.Screen_Print > 0
AND (an.Screen_Print IS NULL OR an.Screen_Print = 0)

UPDATE AN SET
    AN.Sublimation = OrdPR.TotalPrintValue
    ,AN.Total_Sublimation = AN.Qty * OrdPR.TotalPrintValue
FROM #TB_Anexo AS AN
INNER JOIN [LCA].[dboReaders].[VW_Planning_OrderItemsPriceRev_2] OrdPR ON AN.ManufactureID = OrdPR.ManufactureID AND AN.PONumber = OrdPR.PONumber AND AN.StyleColor = OrdPR.Color
INNER JOIN #TB_MO_FILTER AS MO ON AN.ManufactureID = MO.ManufactureID AND MO.Sublimado > 0
AND (an.Sublimation IS NULL OR an.Sublimation = 0)

UPDATE AN SET
    AN.Sublimation = ORDPR_2.[Total Print Value]
    ,AN.Total_Sublimation = AN.Qty * ORDPR_2.[Total Print Value]
FROM #TB_Anexo AS AN
INNER JOIN [LCA].[dboReaders].[VW_Planning_OrderItemsPriceRev_3] ORDPR_2
				on	AN.BoxNumber = OrdPR_2.boxnumber and
					AN.StyleNumber = COALESCE(ORDPR_2.BlankStyle,ORDPR_2.StyleNumber) and
					AN.Size = ORDPR_2.GarmentSize and
					AN.Stylecolor	 = ORDPR_2.StyleColorName
INNER JOIN #TB_MO_FILTER AS MO ON AN.ManufactureID = MO.ManufactureID AND MO.Sublimado > 0
AND (an.Sublimation IS NULL OR an.Sublimation = 0)


--- UPDATE SAC Y HTSDESCRIPTION

UPDATE AN SET
    AN.SAC = HTS.CA_HTSCode
FROM #TB_Anexo AS AN
INNER JOIN LCA.dbo.ManufactureOrders AS MO  ON AN.ManufactureID = MO.ManufactureID AND AN.SAC IS NULL
INNER JOIN LCA.dbo.OrderItems        AS OI  ON MO.FirstOrderItemID = OI.OrderItemID
INNER JOIN LCA.dbo.Styles            AS ST  ON OI.StyleID = ST.StyleID
INNER JOIN LCA.dbo.HTSStyleCodes     AS HTS ON ST.HTSStyleCodeID = HTS.HTSStyleCodeID

UPDATE AN SET
    AN.HTSDescription = HTS.CA_HTSDescription
FROM #TB_Anexo AS AN
INNER JOIN LCA.dbo.ManufactureOrders AS MO  ON AN.ManufactureID = MO.ManufactureID AND AN.HTSDescription IS NULL
INNER JOIN LCA.dbo.OrderItems        AS OI  ON MO.FirstOrderItemID = OI.OrderItemID
INNER JOIN LCA.dbo.Styles            AS ST  ON OI.StyleID = ST.StyleID
INNER JOIN LCA.dbo.HTSStyleCodes     AS HTS ON ST.HTSStyleCodeID = HTS.HTSStyleCodeID


--- UPDATE BASE COST

UPDATE AN SET
    AN.BaseCost = Price - Embroidery - Screen_Print - Sublimation
    ,AN.Total_Base_Cost = (Price - Embroidery - Screen_Print - Sublimation) * Qty
FROM #TB_Anexo AS AN
WHERE AN.BaseCost IS NULL OR AN.BaseCost = 0.00

--- UPDATE LCA_CONTRACT
UPDATE AN SET
    AN.LCA_CONTRACT = COALESCE((select distinct top 1 case when ( Manufacturer like '%League%') then 'LCA' 
						else 'SEMI' end 
                        from AppsLCA.dbo.TB_MO_PartNumber_IM  with (nolock)
                                    where Category in ('Contracts','Fabric') 
                                        AND ManufactureID = AN.ManufactureID),IIF(CHARINDEX('FG',SeasonName) > 0,'SEMI','LCA'))
FROM #TB_Anexo AS AN
WHERE ProductDivision LIKE 'Apparel%' OR ProductDivision LIKE 'HeadWear%'

UPDATE AN SET
    AN.LCA_CONTRACT = CONCAT(LCA_CONTRACT,' ',ProductDivision)
FROM #TB_Anexo AS AN
WHERE LCA_CONTRACT IS NOT NULL

UPDATE AN SET
    AN.LCA_CONTRACT = 'OTHER'
FROM #TB_Anexo AS AN
WHERE LCA_CONTRACT IS NULL

-- SELECT * FROM #TB_MO_FILTER WHERE ManufactureID IN
-- (select distinct ManufactureID from #TB_Anexo where Waybill = 'AIR-BUND-20250311' AND StyleNumber = '51000')


-- SELECT *, ROW_NUMBER() OVER(PARTITION BY ManufactureID ORDER BY ManufactureID) from #TB_MO_FILTER 
-- return
SELECT 
     ShipDate
    ,MONTH(ShipDate) AS MonthNumber
    ,DATEPART(WEEK, Shipdate) AS WeekNumber
    ,DATENAME(WEEKDAY, ShipDate) AS [WeekDay]
    ,Waybill
    ,Invalidado
    ,Batch
    ,Container
    ,ProductDivision
    ,CASE 
		WHEN 
			CONCAT(
				CASE WHEN SUM(Total_Screen_Print) > 0 THEN 'SP, ' ELSE '' END,
				CASE WHEN SUM(Total_Embroidery) > 0 THEN 'EMB, ' ELSE '' END,
				CASE WHEN SUM(Total_Sublimation) > 0 THEN 'SUB, ' ELSE '' END
			) = ''
		THEN 'BLANK'
		ELSE 
			LEFT(
				CONCAT(
					CASE WHEN SUM(Total_Screen_Print) > 0 THEN 'SP, ' ELSE '' END,
					CASE WHEN SUM(Total_Embroidery) > 0 THEN 'EMB, ' ELSE '' END,
					CASE WHEN SUM(Total_Sublimation) > 0 THEN 'SUB, ' ELSE '' END
				),
				LEN(CONCAT(
					CASE WHEN SUM(Total_Screen_Print) > 0 THEN 'SP, ' ELSE '' END,
					CASE WHEN SUM(Total_Embroidery) > 0 THEN 'EMB, ' ELSE '' END,
					CASE WHEN SUM(Total_Sublimation) > 0 THEN 'SUB, ' ELSE '' END
				)) - 1
			)
	END AS ProcessTypes
    ,StyleNumber
    ,SAC
    ,TRIM(REPLACE(REPLACE(REPLACE(HTSDescription, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS HTSDescription
    ,MO.Embroidery
    ,NULL AS Count_Embroidery
    ,MO.Screen_Print 
    ,NULL AS Count_ScreenPrint
    ,MO.Sublimado as Sublimation
    ,NULL AS Count_Sublimation
    ,Price
    ,LCA_CONTRACT
    ,Customer
    ,COALESCE(SUM(Total_Receiving_Cost_Ponderado), 0) AS Total_Receiving_Cost
    ,SUM(Total_Base_Cost)			AS Total_Base_Cost 
    ,SUM(COALESCE(Total_Screen_Print,0.00))			AS Total_Screen_Print
    ,SUM(COALESCE(Total_Embroidery,0.00))			AS Total_Embroidery
    ,SUM(COALESCE(Total_Sublimation,0.00))			AS Total_Sublimation
    ,SUM(Qty) as Qty
    ,SUM(Total$)						AS Total
    
INTO #TB_Final
FROM #TB_Anexo              AS AN
LEFT JOIN #TB_MO_FILTER    AS MO ON AN.ManufactureID = MO.ManufactureID 
-- WHERE ShipDate >= '2024-01-01' and ShipDate <= '2025-12-31'
WHERE Waybill NOT IN ('20230207','SM20230330')
-- AND Waybill = 'AIR-APP-20241022'
 GROUP BY 
    ShipDate, 
    Waybill,
    Invalidado,
    Batch,
    Container,
    SAC,
    StyleNumber,
    HTSDescription,
    MO.Embroidery,
    MO.Screen_Print,
    MO.Sublimado,
    Price,
    LCA_CONTRACT,
    Customer,
    ProductDivision


UPDATE F SET
     Embroidery         = IIF(ProcessTypes = 'BLANK',0,Embroidery)
    ,Count_Embroidery   = IIF(ProcessTypes = 'BLANK',0,Embroidery * Qty)
    ,Screen_Print       = IIF(ProcessTypes = 'BLANK',0,Screen_Print)
    ,Count_ScreenPrint  = IIF(ProcessTypes = 'BLANK',0,Screen_Print * Qty)
    ,Sublimation        = IIF(ProcessTypes = 'BLANK',0,Sublimation)
    ,Count_Sublimation  = IIF(ProcessTypes = 'BLANK',0,Sublimation * Qty)
FROM #TB_Final AS F

UPDATE F SET
    Embroidery          = IIF(Total_Embroidery <> 0 AND Embroidery = 0,1,Embroidery)
    ,Count_Embroidery   = IIF(Total_Embroidery <> 0 AND Embroidery = 0,1,Embroidery) * Qty
    ,Screen_Print       = IIF(Total_Screen_Print <> 0 AND Screen_Print = 0,1,Screen_Print)
    ,Count_ScreenPrint  = IIF(Total_Screen_Print <> 0 AND Screen_Print = 0,1,Screen_Print) * Qty
    ,Sublimation        = IIF(Total_Sublimation <> 0 AND Sublimation = 0,1,Sublimation)
    ,Count_Sublimation  = IIF(Total_Sublimation <> 0 AND Sublimation = 0,1,Sublimation) * Qty
    
FROM #TB_Final AS F

-- select SUM(Qty), SUM(Total), SUM(Total_Embroidery), SUM(Total_Screen_Print), SUM(Total_Sublimation) from  #TB_Final
-- select --Waybill, StyleNumber,
-- SUM(Qty), SUM(Total), SUM(Embroidery), SUM(ScreenPrint), SUM(Sublimation) 
-- from [192.168.1.93].AppsLCA.dbo.PBI_Billing_Data 
-- WHERE ShipDate > '2024-01-01' AND ShipDate < '2025-01-01'
-- --  GROUP BY Waybill, StyleNumber

-- select --Waybill, StyleNumber,
-- SUM(Qty), SUM(Total), SUM(Embroidery), SUM(ScreenPrint), SUM(Sublimation) 
-- from [192.168.1.93].AppsLCA.dbo.PBI_Billing_Data_Test 
-- WHERE ShipDate > '2024-01-01' AND ShipDate < '2025-01-01'
-- GROUP BY Waybill, StyleNumber

-- EMB = 2690734.40         SP = 3065310.52     SUB = 374307.14
-- select * from [192.168.1.93].AppsLCA.dbo.PBI_Billing_Data WHERE Waybill = '20231024-1' order by QTY
-- select * from [192.168.1.93].AppsLCA.dbo.PBI_Billing_Data_Test WHERE Waybill = '20231024-1' order by QTY


INSERT INTO [192.168.1.93].AppsLCA.dbo.PBI_Billing_Data_Test
select *,GETDATE() from #TB_Final-- where Total_Sublimation <> 0 AND Sublimation = 0
return

SELECT SUM(Total$) AS total, Waybill
FROM #TB_Anexo WHERE ShipDate >= '2023-01-01' AND ShipDate <= '2023-12-31'
GROUP BY Waybill
ORDER BY Waybill

SELECT SUM(Total) AS total, Waybill 
FROM [192.168.1.93].AppsLCA.dbo.PBI_Billing_Data WHERE ShipDate >= '2023-01-01' AND ShipDate <= '2023-12-31'
GROUP BY Waybill
ORDER BY Waybill

-- SELECT SUM(Qty) AS QTY, Waybill 
-- FROM [192.168.1.93].AppsLCA.dbo.PBI_Billing_Data_Test WHERE ShipDate >= '2023-01-01' AND ShipDate <= '2023-12-31'
-- GROUP BY Waybill
-- ORDER BY Waybill

-- SELECT 
--     SUM(PI.Quantity) AS Qty
--     ,SH.WayBill
-- FROM LCA.dbo.StatusNames        AS SN WITH(NOLOCK)
-- INNER JOIN LCA.dbo.PackedBoxes  AS PB WITH(NOLOCK) ON PB.StatusID = SN.StatusID AND SN.StatusID = 75
-- INNER JOIN LCA.dbo.Shipments    AS SH WITH(NOLOCK) ON PB.ShipmentID = SH.ShipmentID AND SH.ShipDate >= '2023-01-01' AND SH.ShipDate <= '2023-12-31' AND SH.WayBill in (SELECT DISTINCT Waybill FROM #TB_Anexo)
-- INNER JOIN LCA.dbo.PackedItems  AS PI WITH(NOLOCK) ON PB.PackedBoxID = PI.PackedBoxID AND PI.Quantity > 0
-- GROUP BY SH.WayBill
-- ORDER BY WayBill