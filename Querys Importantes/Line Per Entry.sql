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
	,Line_Left			
INTO #TB_Entry2025
FROM AppsLCA.dbo.TB_Transfer_TablaKelly 
WHERE YEAR([Entry Date]) = 2025
ORDER BY [Entry #],Line_Left

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
	,Line_Left			
INTO #TB_Entry2026
FROM AppsLCA.dbo.TB_Transfer_TablaKelly_AfterPSC
WHERE YEAR([Entry Date]) = 2026
ORDER BY [Entry #],Line_Left

SELECT
	YearEntry
	,MonthEntry
	,[Entry #]
	,[Entry Date]
	,MAX(Num_Lines) AS Line_PerEntry
INTO #TB_LinesPerEntry
FROM
(
	SELECT
		*
		,ROW_NUMBER() OVER(PARTITION BY [Entry #] ORDER BY [Entry #],Line_Left) AS Num_Lines
	FROM #TB_Entry2025

	UNION

	SELECT
		*
		,ROW_NUMBER() OVER(PARTITION BY [Entry #] ORDER BY [Entry #],Line_Left) AS Num_Lines
	FROM #TB_Entry2026
) AS TB
GROUP BY 
	 YearEntry
	,MonthEntry
	,[Entry #]
	,[Entry Date]

SELECT
	YearEntry
	,MAX(Line_PerEntry) MaxLinePerEntry
	,MIN(Line_PerEntry) MinLinePerEntry
	,AVG(Line_PerEntry) AverageLinePerEntry
FROM #TB_LinesPerEntry
GROUP BY YearEntry

SELECT
	YearEntry
	,MonthEntry
	,MAX(Line_PerEntry) MaxLinePerEntry
	,MIN(Line_PerEntry) MinLinePerEntry
	,AVG(Line_PerEntry) AverageLinePerEntry
FROM #TB_LinesPerEntry
GROUP BY YearEntry, MonthEntry
--SELECT
--SUM(Line_PerEntry)
--,YearEntry
--FROM #TB_LinesPerEntry
--Group By YearEntry

--SELECT DISTINCT [Entry #]
--FROM #TB_LinesPerEntry
--WHERE YearEntry = '2026'


--SELECT
--*
--FROM #TB_LinesPerEntry
--WHERE YearEntry = '2026'
--ORDER BY Line_PerEntry DESC

--SELECT
--*
--FROM AppsLCA.dbo.TB_Transfer_TablaKelly 
--WHERE [Entry #] = 'BHE04266777' 