USE AppsLCA

DROP TABLE IF EXISTS #TB_Entry2025
DROP TABLE IF EXISTS #TB_Entry2026
DROP TABLE IF EXISTS #TB_LinesPerEntry

SELECT DISTINCT
	 YearEntry			= YEAR([Entry Date])
	,MonthEntry			= CASE 
							WHEN MONTH([Entry Date]) IN (1,2,3) THEN '1 Period'
							WHEN MONTH([Entry Date]) IN (4,5,6) THEN '2 Period'
							WHEN MONTH([Entry Date]) IN (7,8,9) THEN '3 Period'
							WHEN MONTH([Entry Date]) IN (10,11,12) THEN '4 Period'
						  END
	,[Entry #]
	,[Entry Date]		= CAST([Entry Date] AS DATE)
	,[Invoice #]	
INTO #TB_Entry2025
FROM AppsLCA.dbo.TB_Transfer_TablaKelly 
WHERE YEAR([Entry Date]) = 2025
ORDER BY [Entry #],[Invoice #]

SELECT DISTINCT
	 YearEntry			= YEAR([Entry Date])
	,MonthEntry			= CASE 
							WHEN MONTH([Entry Date]) IN (1,2,3) THEN '1 Period'
							WHEN MONTH([Entry Date]) IN (4,5,6) THEN '2 Period'
							WHEN MONTH([Entry Date]) IN (7,8,9) THEN '3 Period'
							WHEN MONTH([Entry Date]) IN (10,11,12) THEN '4 Period'
						  END
	,[Entry #]
	,[Entry Date]		= CAST([Entry Date] AS DATE)
	,[Invoice #]
INTO #TB_Entry2026
FROM AppsLCA.dbo.TB_Transfer_TablaKelly_AfterPSC
WHERE YEAR([Entry Date]) = 2026
ORDER BY [Entry #],[Invoice #]

SELECT
	YearEntry
	,MonthEntry
	,[Entry #]
	,[Entry Date]
	,MAX(Num_Invoice) AS Invoice_PerEntry
INTO #TB_LinesPerEntry
FROM
(
	SELECT
		*
		,ROW_NUMBER() OVER(PARTITION BY [Entry #] ORDER BY [Entry #],[Invoice #]) AS Num_Invoice
	FROM #TB_Entry2025

	UNION

	SELECT
		*
		,ROW_NUMBER() OVER(PARTITION BY [Entry #] ORDER BY [Entry #],[Invoice #]) AS Num_Invoice
	FROM #TB_Entry2026
) AS TB
GROUP BY 
	 YearEntry
	,MonthEntry
	,[Entry #]
	,[Entry Date]

SELECT
	YearEntry
	,MonthEntry
	,MAX(Invoice_PerEntry) MaxInvoicePerEntry
	,MIN(Invoice_PerEntry) MinInvoicePerEntry
	,AVG(Invoice_PerEntry) AverageInvoicePerEntry
FROM #TB_LinesPerEntry
GROUP BY YearEntry, MonthEntry
ORDER BY YearEntry, MonthEntry

SELECT
	YearEntry
	,MAX(Invoice_PerEntry) MaxInvoicePerEntry
	,MIN(Invoice_PerEntry) MinInvoicePerEntry
	,AVG(Invoice_PerEntry) AverageInvoicePerEntry
FROM #TB_LinesPerEntry
GROUP BY YearEntry
ORDER BY YearEntry