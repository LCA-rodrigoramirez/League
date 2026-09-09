-- =========================================================================
-- 0) CARGA UNICA: trae los datos del linked server una sola vez a #temp
--    Quitar el filtro de ItemDetailID de abajo para correr sobre todas las ordenes
-- =========================================================================
IF OBJECT_ID('tempdb..#DNSB') IS NOT NULL DROP TABLE #DNSB;

SELECT
	 [InsertTime]			= CAST(Insert_Time AS DATE)
	,[ItemDetailID]			= ItemDetailID
	,[DoNotShipBeforeDate]	= DoNotShipBeforeDate
	,[Req Ship]				= [Req Ship]
	,[DaysDiff]				= DATEDIFF(DAY, [Req Ship], DoNotShipBeforeDate)		-- negativo = DNSB antes del Req Ship
	,[TypeN]				= CASE
								WHEN DoNotShipBeforeDate < [Req Ship] THEN 'DNSB Date less than Req Ship'
								WHEN DoNotShipBeforeDate = [Req Ship] THEN 'DNSB Date equals Req Ship'
								WHEN DoNotShipBeforeDate > [Req Ship] THEN 'DNSB Date greater than Req Ship'
							  END
INTO #DNSB
FROM [192.168.1.93].AppsLCA.legacycaps.VW_View_qryLCA_Order_Export_Logs WITH(NOLOCK)
WHERE [R/S Priority] = 'DSE' AND DoNotShipBeforeDate IS NOT NULL AND CAST(Insert_Time AS DATE) >= '2026-08-14'
--AND ItemDetailID = 5571541
GROUP BY
	 ItemDetailID
	,DoNotShipBeforeDate
	,[Req Ship]
	,CAST(Insert_Time AS DATE);


-- =========================================================================
-- 1) DETALLE: una fila por ItemDetailID / DoNotShipBeforeDate / Req Ship
-- =========================================================================
SELECT
	 [InsertTime]
	,[ItemDetailID]
	,[DoNotShipBeforeDate]
	,[Req Ship]
	,[DaysDiff]
	,[TypeN]
	,[N]			= ROW_NUMBER() OVER(PARTITION BY ItemDetailID ORDER BY ItemDetailID, DoNotShipBeforeDate)
FROM #DNSB
ORDER BY [ItemDetailID], [DoNotShipBeforeDate];


-- =========================================================================
-- 2) RESUMEN: total de ordenes y diferencia de dias por TypeN
--    (para responder el correo con numeros globales)
-- =========================================================================
SELECT
	 [TypeN]
	,[TotalOrders]		= COUNT(*)
	,[MinDaysDiff]		= MIN([DaysDiff])
	,[MaxDaysDiff]		= MAX([DaysDiff])
	,[AvgDaysDiff]		= CAST(AVG([DaysDiff] * 1.0) AS DECIMAL(10,2))
FROM #DNSB
GROUP BY [TypeN];


-- =========================================================================
-- 3) EJEMPLOS: casos representativos por TypeN para citar en el correo
--    (los 5 con mayor diferencia de dias en cada categoria)
-- =========================================================================
SELECT
	 [TypeN]
	,[ItemDetailID]
	,[DoNotShipBeforeDate]
	,[Req Ship]
	,[DaysDiff]
FROM
(
	SELECT
		 *
		,[RN] = ROW_NUMBER() OVER (PARTITION BY [TypeN] ORDER BY ABS([DaysDiff]) DESC)
	FROM #DNSB
) AS C
WHERE [RN] <= 5
ORDER BY [TypeN], [DaysDiff] DESC;


-- DROP TABLE #DNSB;
