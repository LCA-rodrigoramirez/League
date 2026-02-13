SELECT 
	Entry#
	,EntryDate 
	,WayBill
	,TypeData
	,Orden
	,SUM(Quantity) as Qty
	,SUM(CI_Total) as CI_Total
	,SUM(TotalPrice) as TotalPrice
FROM AppsLCA.dbo.TB_Transfer_CuadreCI_KellyGlobal AS KG WITH(NOLOCK)
WHERE Entry# = 'BHE04232464'
GROUP BY
	Entry#
	,EntryDate
	,WayBill
	,TypeData
	,Orden

SELECT 
	Entry#
	,EntryDate 
	,SUM(Quantity) as Qty
	,SUM(CI_Total) as CI_Total
	,SUM(TotalPrice) as TotalPrice
FROM AppsLCA.dbo.TB_Transfer_CuadreCI_KellyGlobal AS KG WITH(NOLOCK) 
GROUP BY
	Entry#
	,EntryDate 
ORDER BY
	Entry#
	,EntryDate 
	SELECT DISTINCT ShipDate,WayBill FROM AppsLCA.dbo.TB_Transfer_CuadreCI_KellyGlobal AS KG WITH(NOLOCK) WHERE CAST(EntryDate AS DATE) in ('2025-03-17')

select * from AppsLCA.dbo.TB_Transfer_CuadreCI_KellyGlobal WHERE Entry# = 'BHE04245235'


SELECT DISTINCT
[Entry #]
,CAST([Entry Date] AS DATE) AS [Entry Date]
FROM [AppsLCA].[dbo].[TB_Transfer_TablaKelly] AS KG WITH(NOLOCK) 
WHERE [Entry #] NOT IN ('BHE04203689','BHE04217994')
ORDER BY CAST([Entry Date] AS DATE), [Entry #]

SELECT DISTINCT
[Entry #]
,EntryDate
FROM AppsLCA.dbo.TB_Transfer_WaybillEntry AS KG WITH(NOLOCK) 
-- WHERE EntryDate >= '2024-08-06'
ORDER BY EntryDate , [Entry #]

select * 
FROM AppsLCA.dbo.TB_Transfer_WaybillEntry AS KG WITH(NOLOCK) 
WHERE Waybill = 'APP-20240627'
--[Entry #] = 'BHE04230377'

SELECT * FROM AppsLCA.dbo.TB_Transfer_Waybill_Void WHERE waybill = '20240112'

SELECT 
*
FROM [AppsLCA].[dbo].[TB_Transfer_TablaKelly] AS KG WITH(NOLOCK) 
WHERE [Entry #] NOT IN ('BHE04217994')
ORDER BY [Entry #], [Entry Date]