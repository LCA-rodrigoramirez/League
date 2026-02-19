DROP TABLE IF EXISTS #TB_Waybills
SELECT 
	[Cust PO #]		= LTRIM(RTRIM([Cust PO #]))
	,[PONumber]		= AF.PONumber
	,[Waybill]		= AF.Waybill
	,Size			= OE.Size
	,[Item # L2]	= [Item # L2] 
	,[SKU Number]	= [SKU Number]
	,[Order Qty]	= SUM(OE.Qty)
	,[Shipped Qty]	= SUM(CAST(AF.Qty AS int))
	,[Cartoon Count]= CAST(NULL AS INT)
	,[Vendor]		= 'L2 Brands'
INTO #TB_Waybills
FROM legacycaps.VW_view_qryLCA_Order_Export_Logs AS OE WITH(NOLOCK)
LEFT JOIN 
(
SELECT PONumber, Size, Waybill,SUM(Qty) as Qty, COUNT(DISTINCT BoxNumber) AS CountBox
FROM [192.168.1.53].AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK)
GROUP BY PONumber,Size,Waybill
) AS AF ON CONCAT('ORD-',CAST(OE.ItemDetailID AS VARCHAR(100))) = AF.PONumber AND OE.Size = AF.Size


WHERE OrderNo IN (

 '225103308'
,'225103316'
,'225103318'
,'225103320'
,'225103322'
,'225112214'
,'225112218'
,'225112219'
,'225112232'
,'225112217'
)AND Insert_time = '2026-02-16 14:49:56.253'


GROUP BY
LTRIM(RTRIM([Cust PO #]))
,AF.PONumber
,OE.Size
,AF.Waybill
,[Item # L2] 
,[SKU Number]


UPDATE TW SET
	[Cartoon Count] = AF2.CountBox
FROM #TB_Waybills AS TW
LEFT JOIN 
(
SELECT
	PONumber
	,Size
	,Waybill
	,SUM(CountBox) AS CountBox
FROM
(
SELECT
	PONumber
	,Size
	,Waybill
	,CASE WHEN CountBox = 1 THEN 1 ELSE 0 END as CountBox
FROM
(
	SELECT PONumber, Size, Waybill, ROW_NUMBER() OVER(PARTITION BY PONumber, BoxNumber, Waybill ORDER BY PONumber, Size) AS CountBox
	FROM [192.168.1.53].AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK)
) AS TB
) AS TB2
GROUP BY
PONumber
	,Size
	,Waybill

) AS AF2 ON TW.PONumber = AF2.PONumber AND tw.Size = AF2.Size AND TW.Waybill = AF2.Waybill

SELECT
*
FROM #TB_Waybills


