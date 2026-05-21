
DROP TABLE IF EXISTS #TB_Operators
DROP TABLE IF EXISTS #TB_Turnos

SELECT
     [R]            = ROW_NUMBER() OVER(PARTITION BY AD.[Comments6] ORDER BY AD.[Comments6], AD.[CompanyName], AD.[Comments2], AD.[ProductionTaskName])
    ,[Area]         = CASE 
                        WHEN AD.[Comments6] = 'Embroidery Headwear' THEN 'Headwear' 
                        WHEN AD.[Comments6] = 'Screen Print' THEN 'ScreenPrint' 
                        ELSE AD.[Comments6] 
                      END
    ,[Modulo]       = AD.[CompanyName]
    ,[TurnoPPM]     = AD.[Comments2]
    ,[TaskName]     = AD.[ProductionTaskName]
    ,[PPAD]         = 'PPAD'+Ltrim(Str(AD.[AddressID]+10000))
    -- ,[Operator]     = AD.[CompanyNumber]
    -- ,[AddressID]    = AD.[AddressID]
    -- ,[StatusID]     = AD.[StatusID]
    -- ,[NIT]          = AD.[Comments4]
INTO #TB_Operators
FROM [LCA].[dbo].[Addresses] AS AD WITH(NOLOCK)
WHERE AD.[IsOperator] = 1 AND AD.[ProductionTaskName] IN ('Check In', 'Check Out') AND AD.[StatusID] = 30

SELECT
	 [R]            = ROW_NUMBER() OVER(ORDER BY TA.[Area], TCT.[Name])
	,[area]         = TA.[area]
	,[Name]         = TCT.[Name]
	,[PPMTurno]     = TCT.[PPMTurno]
	,[StartTime]    = TCT.[StartTime]
	,[EndTime]      = TCT.[EndTime]
INTO #TB_Turnos
FROM [AppsLCA].[dbo].[TV_Cal_Turnos] AS TCT WITH(NOLOCK)
CROSS APPLY
[AppsLCA].[dbo].[TV_Areas] AS TA WITH(NOLOCK) 
WHERE TCT.[Status] = 1 AND TA.[id] IN (1,2,3,4,5)



SELECT 
   [R]            = T.[R]             
  ,[area]         = T.[area]        
  ,[Name]         = T.[Name]        
  ,[PPMTurno]     = T.[PPMTurno]    
  ,[StartTime]    = T.[StartTime]   
  ,[EndTime]      = T.[EndTime]     
  ,[Details]      = (
                        SELECT
                            [Modulo]    = M.[Modulo],
                            [Operators] = JSON_QUERY((
                                SELECT
                                    [CheckIn]  = MAX(CASE WHEN S.[TaskName] = 'Check In'  THEN S.[PPAD] END),
                                    [CheckOut] = MAX(CASE WHEN S.[TaskName] = 'Check Out' THEN S.[PPAD] END)
                                FROM #TB_Operators AS S
                                WHERE S.[Area] = T.[area] AND S.[TurnoPPM] = T.[PPMTurno] AND S.[Modulo] = M.[Modulo]
                                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
                            ))
                        FROM (SELECT DISTINCT [Area], [Modulo] FROM #TB_Operators WHERE [Area] = T.[area]) AS M
                        ORDER BY M.[Modulo]
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    )
FROM #TB_Turnos AS T
WHERE EXISTS (
    SELECT 1 FROM #TB_Operators AS O
    WHERE O.[Area] = T.[area] AND O.[TurnoPPM] = T.[PPMTurno]
)
ORDER BY T.[R]