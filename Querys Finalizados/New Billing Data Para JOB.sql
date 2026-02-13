DROP TABLE IF EXISTS #TB_Anexo
DROP TABLE IF EXISTS #TB_MO_FILTER
DROP TABLE IF EXISTS #TB_Final

DECLARE @CurrentDate DATE = CAST(GETDATE() AS DATE);
DECLARE @StartDate DATE = DATEADD(DAY, -7, @CurrentDate);
DECLARE @EndDate DATE = @CurrentDate;

DELETE FROM [dbo].[PBI_Billing_Data]
WHERE [ShipDate] >= @StartDate AND [ShipDate] <= @EndDate

--- DATA BILLING DETAILS

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
    ,[ProductDivision] = CASE 
                            WHEN LEFT(Waybill, 3) = 'ARD' THEN 'Services'
                            WHEN LEFT(Waybill, 4) = 'DESP' THEN 'Leftover'
                            WHEN AF.StyleNumber IN ('Fabric','Thread','Trim','Supplies', 'SWATCH') THEN AF.StyleNumber
                        ELSE ProductDivision
                        END
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
INTO #TB_Anexo
FROM [192.168.1.53].AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK) 
INNER JOIN [192.168.1.53].AppsLCA.dbo.DTE_FACTURAS_ELECTRONICAS AS FE WITH(NOLOCK) ON AF.Waybill = FE.factura AND AF.[ShipDate] >= @StartDate AND AF.[ShipDate] <= @EndDate AND invalidado = 0 AND AF.Batch = FE.items
INNER JOIN [192.168.1.53].AppsLCA.dbo.DTE_RECEPTOR              AS R  WITH(NOLOCK) ON FE.idReceptor = R.id


--- DATA FE INVALIDADOS

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

--- CONOCER CUANTOS EMBELISHMENT LLEVA

UPDATE AN SET
    AN.ManufactureID = SMO.MOID
    --select *
FROM #TB_Anexo AS AN
INNER JOIN [192.168.1.53].[LCA].[dbo].[VW_Check_Sales_Prices_in_Invoices_SeekMO_3] SMO ON AN.BoxNumber = SMO.BoxNumber 
AND AN.ManufactureID IS NULL


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
INNER JOIN      [192.168.1.53].LCA.dbo.ManufactureOrders           AS MO   WITH(NOLOCK) ON MO.[ManufactureID]  = AN.[ManufactureID]         

    
    


--- BORDADO DE PRENDAS ---

UPDATE MO SET
        [WorkFlowID]       = WF.WorkFlowID
    ,[WorkFlowName]     = WF.WorkFlowName
FROM #TB_MO_FILTER AS MO
INNER JOIN [192.168.1.53].LCA.dbo.WorkFlows AS WF WITH (NOLOCK) ON MO.ManufactureID = WF.ManufactureID

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
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish Embroidery 1'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish Embroidery 2'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish Embroidery 3'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Finish Embroidery 4'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'Finish Embroidery 5'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'Finish Embroidery 6'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'Finish Embroidery 7'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'Finish Embroidery 8'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_09    WITH(NOLOCK) ON MO.WorkFlowID = WT_09.WorkFlowID    AND WT_09.TaskName  = 'Finish Embroidery 9'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_10    WITH(NOLOCK) ON MO.WorkFlowID = WT_10.WorkFlowID    AND WT_10.TaskName  = 'Finish Embroidery 10'


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
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish Embroidery  HW 1'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish Embroidery  HW 2'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish Embroidery  HW 3'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Finish Embroidery  HW 4'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'Finish Embroidery  HW 5'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'Finish Embroidery  HW 6'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'Finish Embroidery  HW 7'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'Finish Embroidery  HW 8'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_09    WITH(NOLOCK) ON MO.WorkFlowID = WT_09.WorkFlowID    AND WT_09.TaskName  = 'Finish Embroidery  HW 9'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_10    WITH(NOLOCK) ON MO.WorkFlowID = WT_10.WorkFlowID    AND WT_10.TaskName  = 'Finish Embroidery  HW 10'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_11    WITH(NOLOCK) ON MO.WorkFlowID = WT_11.WorkFlowID    AND WT_11.TaskName  = 'Finish Embroidery Post HW 1'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_12    WITH(NOLOCK) ON MO.WorkFlowID = WT_12.WorkFlowID    AND WT_12.TaskName  = 'Finish Embroidery Post HW 2'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_13    WITH(NOLOCK) ON MO.WorkFlowID = WT_13.WorkFlowID    AND WT_13.TaskName  = 'Finish Embroidery Post HW 3'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_14    WITH(NOLOCK) ON MO.WorkFlowID = WT_14.WorkFlowID    AND WT_14.TaskName  = 'Finish Embroidery Post HW 4'
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
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish Print 1'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish Print 2'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish Print 3'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Finish Print 4'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'Finish Print 5'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'Finish Print 6'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'Finish Print 7'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'Finish Print 8'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_09    WITH(NOLOCK) ON MO.WorkFlowID = WT_09.WorkFlowID    AND WT_09.TaskName  = 'Finish Print 9'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_10    WITH(NOLOCK) ON MO.WorkFlowID = WT_10.WorkFlowID    AND WT_10.TaskName  = 'Finish Print 10'


--- SUBLIMADO

UPDATE MO SET
    [Sublimado]            =   IIF(WT_01.TaskName  IS NOT NULL, 1, 0) +
                                IIF(WT_02.TaskName  IS NOT NULL, 1, 0) +
                                IIF(WT_03.TaskName  IS NOT NULL, 1, 0)
FROM #TB_MO_FILTER       AS MO
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish Sublimation Process'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish SUB Application 1'
LEFT JOIN [192.168.1.53].LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish SUB Application 2'


--- UPDATE LCA_CONTRACT
UPDATE AN SET
    AN.LCA_CONTRACT = COALESCE((select distinct top 1 case when ( Manufacturer like '%League%') then 'LCA' 
						else 'SEMI' end 
                        from [192.168.1.53].AppsLCA.dbo.TB_MO_PartNumber_IM  with (nolock)
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


--- INSERT FINAL

SELECT 
     ShipDate
    ,MONTH(ShipDate) AS MonthNumber
    ,DATEPART(WEEK, Shipdate) AS WeekNumber
    ,DATEPART(WEEKDAY, ShipDate) AS [WeekDay]
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
    ,SUM(Total_Screen_Print)			AS Total_Screen_Print
    ,SUM(Total_Embroidery)			AS Total_Embroidery
    ,SUM(Total_Sublimation)			AS Total_Sublimation
    ,SUM(Qty) as Qty
    ,SUM(Total$)						AS Total
    
INTO #TB_Final
FROM #TB_Anexo              AS AN
LEFT JOIN #TB_MO_FILTER    AS MO ON AN.ManufactureID = MO.ManufactureID 
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

UPDATE TB SET
    Customer = CASE WHEN Customer = 'L2 Brands LLC' THEN 'L2 BRANDS LLC.' ELSE Customer END
FROM #TB_Final AS TB

INSERT INTO AppsLCA.dbo.PBI_Billing_Data
select *,GETDATE() from #TB_Final