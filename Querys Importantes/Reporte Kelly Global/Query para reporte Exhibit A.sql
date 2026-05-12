DROP TABLE IF EXISTS #TB_EntryPort
DROP TABLE IF EXISTS #TB_EntryData

SELECT
	[Entry #]
	,PortEntry
INTO #TB_EntryPort
FROM AppsLCA.dbo.TB_Transfer_TablaKelly WITH(NOLOCK)
WHERE [Entry #] IN
(
 'BHE04255242'
,'BHE04256315'
,'BHE04256372'
,'BHE04256935'
,'BHE04257149'
,'BHE04257511'
,'BHE04257560'
,'BHE04258543'
,'BHE04258568'
,'BHE04258709'
,'BHE04258691'
,'BHE04260739'
,'BHE04260978'
,'BHE04261034'
,'BHE04261075'
,'BHE04261679'
,'BHE04261968'
,'BHE04262784'
,'BHE04262958'
,'BHE04262990'
,'BHE04263527'
,'BHE04263675'
,'BHE04263840'
,'BHE04263865'
,'BHE04264152'
,'BHE04264244'
,'BHE04264681'
,'BHE04265159'
,'BHE04265357'
,'BHE04265407'
,'BHE04265456'
,'BHE04265555'
,'BHE04265795'
,'BHE04266645'
,'BHE04266751'
,'BHE04266769'
,'BHE04266785'
,'BHE04267361'
,'BHE04267643'
,'BHE04268526'
,'BHE04268658'
,'BHE04271934'
,'BHE04279671'
,'BHE04298994'
,'BHE04304081'
)
GROUP BY
	[Entry #]
	,PortEntry

SELECT DISTINCT
	 SNCK.[Entry#]
	,CAST(SNCK.[EntryDate] AS date) AS [EntryDate]
	,TEP.PortEntry
	,RT.RowType
	,RT.RowTypeOrder
	,CAST(NULL AS DECIMAL(18,2)) AS OriginalEnteredValue
	,CAST(NULL AS DECIMAL(18,2)) AS OriginalDutyPaid
	,CAST(NULL AS DECIMAL(18,2)) AS AlterationValue9802
	,CAST(NULL AS DECIMAL(18,2)) AS NewDutiableValue
	,CAST(NULL AS DECIMAL(18,2)) AS NewDutyPaid
	,CAST(NULL AS BIT)			 AS New9802
	,CAST(NULL AS BIT)			 AS Modified9802
INTO #TB_EntryData
FROM #TB_EntryPort AS TEP
INNER JOIN AppsLCA.dbo.TB_Transfer_SummaryNewCIKelly AS SNCK WITH(NOLOCK) ON TEP.[Entry #] = SNCK.[Entry#]
CROSS APPLY
(
	VALUES
		 (1, 'Primary HTSUS')
		,(2, 'Chapter 99 / IEEPA')
		,(3, '9802.00.5060')
) AS RT(RowTypeOrder, RowType)

UPDATE TED SET
	TED.OriginalEnteredValue = 	CASE 
									WHEN TED.RowTypeOrder IN (1,2) THEN SNCK.OriginalEnteredValue
									WHEN TED.RowTypeOrder = 3 THEN SNCK.OriginalEnteredValue9802 
								END
	,TED.OriginalDutyPaid    = 	CASE 
									WHEN TED.RowTypeOrder = 1 THEN SNCK.OriginalDutyHTS
									WHEN TED.RowTypeOrder = 2 THEN SNCK.OriginalDutyIEEPA
									WHEN TED.RowTypeOrder = 3 THEN SNCK.OriginalDutyHTS9802 + SNCK.OriginalDutyIEEPA9802 
								END
	,TED.AlterationValue9802 = 	CASE 
									WHEN TED.RowTypeOrder = 3 THEN SNCK.NewDutiableValue9802
									ELSE 0
								END
	,TED.NewDutiableValue 	 = 	CASE 
									WHEN TED.RowTypeOrder IN (1,2) THEN SNCK.NewDutiableValue
									WHEN TED.RowTypeOrder = 3 THEN SNCK.NewDutiableValue9802 
								END
	,TED.NewDutyPaid 	 	 = 	CASE 
									WHEN TED.RowTypeOrder = 1 THEN SNCK.NewDutyPaidHTS
									WHEN TED.RowTypeOrder = 2 THEN 0
									WHEN TED.RowTypeOrder = 3 THEN SNCK.NewDutyPaidHTS9802 + SNCK.NewDutyPaidIEEPA9802
								END
FROM #TB_EntryData AS TED
INNER JOIN 
(
	SELECT
		 [Entry#]
		,SUM(CASE WHEN SNCK.OriginalTariffCategory <> 'NO CAFTA RULE 9802' THEN Kelly_TotalFOB ELSE 0 END) AS OriginalEnteredValue
		,SUM(CASE WHEN SNCK.OriginalTariffCategory = 'NO CAFTA RULE 9802' THEN Kelly_TotalFOB ELSE 0 END) AS OriginalEnteredValue9802
		,SUM(CASE WHEN SNCK.OriginalTariffCategory <> 'NO CAFTA RULE 9802' THEN Kelly_301China$ + Kelly_HTS$ ELSE 0 END)	AS OriginalDutyHTS
		,SUM(CASE WHEN SNCK.OriginalTariffCategory = 'NO CAFTA RULE 9802' THEN Kelly_301China$ + Kelly_HTS$ ELSE 0 END)	AS OriginalDutyHTS9802
		,SUM(CASE WHEN SNCK.OriginalTariffCategory <> 'NO CAFTA RULE 9802' THEN Kelly_Fenta$ + Kelly_Recip$ ELSE 0 END)	AS OriginalDutyIEEPA
		,SUM(CASE WHEN SNCK.OriginalTariffCategory = 'NO CAFTA RULE 9802' THEN Kelly_Fenta$ + Kelly_Recip$ ELSE 0 END)	AS OriginalDutyIEEPA9802
		,SUM(CASE WHEN SNCK.NewTariffCategory <> 'NO CAFTA RULE 9802' THEN New_TotalFOB ELSE 0 END)					AS NewDutiableValue
		,SUM(CASE WHEN SNCK.NewTariffCategory = 'NO CAFTA RULE 9802' THEN New_TotalFOB ELSE 0 END)					AS NewDutiableValue9802
		,SUM(CASE WHEN SNCK.NewTariffCategory <> 'NO CAFTA RULE 9802' THEN New_301China$ + New_HTS$ ELSE 0 END)		AS NewDutyPaidHTS
		,SUM(CASE WHEN SNCK.NewTariffCategory = 'NO CAFTA RULE 9802' THEN New_301China$ + New_HTS$ ELSE 0 END)		AS NewDutyPaidHTS9802
		-- ,SUM(CASE WHEN SNCK.NewTariffCategory <> 'NO CAFTA RULE 9802' THEN New_Fenta$ + New_Recip$ ELSE 0 END)		AS NewDutyPaidIEEPA
		-- ,SUM(CASE WHEN SNCK.NewTariffCategory = 'NO CAFTA RULE 9802' THEN New_Fenta$ + New_Recip$ ELSE 0 END)		AS NewDutyPaidIEEPA9802
		,SUM(CASE WHEN SNCK.NewTariffCategory <> 'NO CAFTA RULE 9802' THEN 0 ELSE 0 END)		AS NewDutyPaidIEEPA
		,SUM(CASE WHEN SNCK.NewTariffCategory = 'NO CAFTA RULE 9802' THEN 0 ELSE 0 END)		AS NewDutyPaidIEEPA9802
	FROM AppsLCA.dbo.TB_Transfer_SummaryNewCIKelly AS SNCK WITH(NOLOCK) 
	GROUP BY Entry#
	
) AS SNCK ON TED.[Entry#] = SNCK.[Entry#]

SELECT
	*
FROM #TB_EntryData 
ORDER BY EntryDate, Entry#, RowTypeOrder

SELECT
	Entry#
	,EntryDate
	,PortEntry
	,SUM(OriginalDutyPaid) AS TotalDutyPaid
	,SUM(NewDutyPaid) AS TotalDutyOwed
FROM #TB_EntryData 
GROUP BY
	Entry#
	,EntryDate
	,PortEntry
ORDER BY EntryDate, Entry#