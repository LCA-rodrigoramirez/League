



-- =============================================
-- DiagnÃ³stico: ver el formato real de Fecha y Hora
-- Ejecuta esto primero para confirmar el formato
-- =============================================
-- SELECT TOP 5
-- 	 [Fecha]      = sc.[Fecha]
-- 	,[Hora]       = sc.[Hora]
-- 	,[InsertDate] = sc.[InsertDate]
-- FROM [AppsLCA].[LinkUp].[ScanModReg] AS sc WITH(NOLOCK)
-- WHERE sc.[Fecha] = CONVERT(CHAR(10), GETDATE(), 112)
-- ORDER BY sc.[InsertDate] DESC


-- =============================================
-- Variables de control
-- =============================================
DECLARE @Now            DATETIME = GETDATE()
-- DECLARE @Now         DATETIME = '2026-05-19 04:00:00'   -- simular hora especifica

DECLARE @CurrentTime    TIME     = CAST(@Now AS TIME)
DECLARE @Today          CHAR(10) = CONVERT(CHAR(10), @Now,                    112)
DECLARE @Yesterday      CHAR(10) = CONVERT(CHAR(10), DATEADD(DAY, -1, @Now),  112)
DECLARE @ScheduleDate   CHAR(10) = CASE
                                        WHEN CAST(@Now AS TIME) < '06:00:00'
                                        THEN CONVERT(CHAR(10), DATEADD(DAY, -1, @Now), 112)  -- madrugada: usar dia anterior
                                        ELSE CONVERT(CHAR(10), @Now,                   112)  -- resto del dia: usar hoy
                                   END
DECLARE @DayOfWeek       INT     = DATEPART(WEEKDAY, @Now)

-- Convierte a convencion 1=Lun, 2=Mar ... 6=Sab
-- DECLARE @TodayDOW       INT = ((DATEPART(WEEKDAY, @Now)                    + 5) % 7) + 1
-- DECLARE @YesterdayDOW   INT = ((DATEPART(WEEKDAY, DATEADD(DAY, -1, @Now))  + 5) % 7) + 1


SELECT @Today, @Yesterday,@ScheduleDate, @DayOfWeek



-- DECLARE @PPAD		VARCHAR(MAX) = 'PPAD43856'   ---EMBROIDERY 1
-- DECLARE @PPAD		VARCHAR(MAX) = 'PPAD43831'   ---EMBROIDERY 2
-- DECLARE @PPAD		VARCHAR(MAX) = 'PPAD43865'   ---EMBROIDERY 4




DROP TABLE IF EXISTS #TB_CompanyName
DROP TABLE IF EXISTS #TB_TRANSACTIONS_EMPLOYEES
DROP TABLE IF EXISTS #EmpleadosActivosPorModulo

SELECT
     [R]            = ROW_NUMBER() OVER(PARTITION BY AD.[Comments6] ORDER BY AD.[Comments6], AD.[CompanyName], AD.[Comments2], AD.[ProductionTaskName])
    -- ,[Area]         = CASE 
    --                     WHEN AD.[Comments6] = 'Embroidery Headwear' THEN 'Headwear' 
    --                     WHEN AD.[Comments6] = 'Screen Print' THEN 'ScreenPrint' 
    --                     ELSE AD.[Comments6] 
    --                   END
    ,[CompanyName]       = AD.[CompanyName]
    ,[TurnoPPM]     = AD.[Comments2]
    ,[TaskName]     = AD.[ProductionTaskName]
    ,[PPAD]         = 'PPAD'+Ltrim(Str(AD.[AddressID]+10000))
    ,[Validate]        = AD.[Comments4]
    ,[Modulo_ID]    = MD.[ID]
    ,[Turno_ID]     = GS.[ID]
    ,[Turno]        = TR.[Name]
    ,[ScheduleDate] = @ScheduleDate
    ,[Area]         = AR.[area]
    ,[Area_ID]      = AR.[ID]
    
    -- ,
    -- ,[Operator]     = AD.[CompanyNumber]
    -- ,[AddressID]    = AD.[AddressID]
    -- ,[StatusID]     = AD.[StatusID]
-- INTO #TB_Operators
INTO #TB_CompanyName
FROM [LCA].[dbo].[Addresses]                AS AD WITH(NOLOCK)
LEFT JOIN AppsLCA.dbo.TV_Modulos            AS MD WITH(NOLOCK) ON AD.CompanyName = MD.Modulo
INNER JOIN AppsLCA.DBO.TV_Cal_GroupSchedule AS GS WITH(NOLOCK) ON MD.[ID] = GS.MODULO_ID AND GS.ScheduleDate = @ScheduleDate AND  DATEPART(WEEKDAY, GS.ScheduleDate) = @DayOfWeek
INNER JOIN AppsLCA.DBO.TV_Cal_Turnos        AS TR WITH(NOLOCK) ON TR.ID = GS.Turno_ID
LEFT JOIN AppsLCA.DBO.TV_Areas              AS AR WITH(NOLOCK) ON AR.ID = MD.Area_ID   
WHERE 
    --     'PPAD'+Ltrim(Str(AD.[AddressID]+10000)) = @PPAD
    -- AND 
    AD.[IsOperator] = 1 
    AND AD.[ProductionTaskName] IN ('Check In', 'Check Out') 
    AND AD.[StatusID] =30
    AND AD.Comments2 = 'DIA'

-- select * from AppsLCA.DBO.TV_Areas
-- select * from #TB_CompanyName AS TB
-- return
-- INNER JOIN #TB_CompanyName

-- SELECT
--      [PPMTurno]          = t.[PPMTurno]
--     ,[Turno_ID]          = td.[Turno_ID]
--     ,[StartTime]         = td.[StartTime]
--     ,[EndTime]           = td.[EndTime]
--     ,[IsOvertime]        = td.[IsOvertime]
--     ,[CruzaMedianoche]   = CASE WHEN td.[StartTime] > td.[EndTime] THEN 1 ELSE 0 END
-- FROM [AppsLCA].[dbo].[TV_Cal_TurnoDays]  AS td WITH(NOLOCK)
-- LEFT JOIN [AppsLCA].[dbo].[TV_Cal_Turnos] AS t  WITH(NOLOCK) ON t.[ID] = td.[Turno_ID]

-- -- =============================================
-- -- 1. Turno(s) activos a la hora actual
-- -- =============================================
-- SELECT
--      [PPMTurno]          = t.[PPMTurno]
--     ,[Turno_ID]          = td.[Turno_ID]
--     ,[StartTime]         = td.[StartTime]
--     ,[EndTime]           = td.[EndTime]
--     ,[IsOvertime]        = td.[IsOvertime]
--     ,[CruzaMedianoche]   = CASE WHEN td.[StartTime] > td.[EndTime] THEN 1 ELSE 0 END
-- FROM [AppsLCA].[dbo].[TV_Cal_TurnoDays]  AS td WITH(NOLOCK)
-- LEFT JOIN [AppsLCA].[dbo].[TV_Cal_Turnos] AS t  WITH(NOLOCK) ON t.[ID] = td.[Turno_ID]
-- WHERE
--     -- Turno de HOY sin cruzar medianoche: 06:00-14:00, 14:00-22:00, etc.
--     (    td.[DayOfWeek]  = @TodayDOW
--      AND td.[StartTime]  < td.[EndTime]
--      AND @CurrentTime   >= td.[StartTime]
--      AND @CurrentTime    < td.[EndTime]
--     )
--     OR
--     -- Turno de HOY que cruza medianoche (porciÃ³n nocturna: despuÃ©s de StartTime)
--     (    td.[DayOfWeek]  = @TodayDOW
--      AND td.[StartTime]  > td.[EndTime]
--      AND @CurrentTime   >= td.[StartTime]
--     )
--     OR
--     -- Turno de AYER que cruzÃ³ medianoche (porciÃ³n matutina: antes de EndTime)
--     -- Ejemplo: NOC 18:00-05:00 iniciado ayer, a las 04:00 de hoy sigue activo
--     (    td.[DayOfWeek]  = @YesterdayDOW
--      AND td.[StartTime]  > td.[EndTime]
--      AND @CurrentTime    < td.[EndTime]
--     )


-- =============================================
-- 2. Empleados activos + detecciÃ³n de overtime
-- Correccion: TRY_CAST(Hora AS TIME) en lugar de CAST(Fecha+Hora AS DATETIME)
-- =============================================
    -- SELECT
    --      [codEmp]        = sc.[codEmp]
    --     ,[Modulo]        = TRIM(REPLACE(sc.[Modulo], CHAR(13), ''))
    --     ,[SoF]           = RIGHT(md.[CompanyNumber], 1)
    --     ,[Fecha]         = sc.[Fecha]
    --     ,[Hora]          = sc.[Hora]
    --     -- TRY_CAST: si el formato de Hora no es HH:MM:SS retorna NULL en vez de error
    --     ,[HoraTime]      = TRY_CAST(sc.[Hora] AS TIME)
    --     ,[CompanyName]   = md.[CompanyName]
    --     ,[ppadModulo]    = 'PPAD' + LTRIM(STR(md.[AddressID] + 10000))
    --     ,[rn]            = ROW_NUMBER() OVER (
    --                            PARTITION BY sc.[codEmp]
    --                            ORDER BY sc.[Fecha] DESC, sc.[Hora] DESC, sc.[InsertDate] DESC
    --                        )
    --     ,[Turno]         = t.[Turno]
    -- FROM [AppsLCA].[LinkUp].[ScanModReg] AS sc WITH(NOLOCK)
    -- LEFT JOIN [LCA].[dbo].[Addresses]    AS md WITH(NOLOCK)
    --        ON 'PPAD' + LTRIM(STR(md.[AddressID] + 10000)) = TRIM(REPLACE(sc.[Modulo], CHAR(13), ''))
    --       AND md.[ProductionTaskName] IN ('Check In', 'Check Out')
    --       AND ISNUMERIC(RIGHT(md.[ProductionTaskName], 1)) = 0
    -- INNER JOIN #TB_CompanyName AS T ON T.CompanyName = md.[CompanyName]
    -- WHERE sc.[Fecha]      IN (@Today, @Yesterday)
    --   AND sc.[Status_Reg] <> 'Deleted'
    --   AND sc.[Modulo]      IS NOT NULL


                     SELECT
                         [R]            = ROW_NUMBER() OVER(ORDER BY t.[area],t.[turno],md.companyname)
                        ,[codEmp]        = sc.[codEmp]
                        ,[NombreEmpl]    = sc.[NombreEmpl]
                        ,[Modulo]        = TRIM(REPLACE(sc.[Modulo], CHAR(13), ''))
                        ,[SoF]           = RIGHT(md.[CompanyNumber], 1)
                        ,[Fecha]         = sc.[Fecha]
                        ,[Hora]          = sc.[Hora]
                        -- TRY_CAST: si el formato de Hora no es HH:MM:SS retorna NULL en vez de error
                        ,[HoraTime]      = TRY_CAST(sc.[Hora] AS TIME)
                        ,[CompanyName]   = md.[CompanyName]
                        ,[ppadModulo]    = 'PPAD' + LTRIM(STR(md.[AddressID] + 10000))
                        ,[rn]            = ROW_NUMBER() OVER (
                                               PARTITION BY sc.[codEmp]
                                               ORDER BY sc.[Fecha] DESC, sc.[Hora] DESC, sc.[InsertDate] DESC
                                           )
                        ,[Turno]         = t.[Turno]
                        ,[Area]          = t.[area]    
                        ,[Turno_ID]      = t.[Turno_ID]
                        ,[Area_ID]       = t.[Area_ID]
                    INTO #TB_TRANSACTIONS_EMPLOYEES
                    FROM [AppsLCA].[LinkUp].[ScanModReg] AS sc WITH(NOLOCK)
                    LEFT JOIN [LCA].[dbo].[Addresses]    AS md WITH(NOLOCK)
                           ON 'PPAD' + LTRIM(STR(md.[AddressID] + 10000)) = TRIM(REPLACE(sc.[Modulo], CHAR(13), ''))
                          AND md.[ProductionTaskName] IN ('Check In', 'Check Out')
                          AND ISNUMERIC(RIGHT(md.[ProductionTaskName], 1)) = 0
                    INNER JOIN #TB_CompanyName AS T ON T.CompanyName = md.[CompanyName]
                    WHERE sc.[Fecha]      IN (@Today, @Yesterday)
                      AND sc.[Status_Reg] <> 'Deleted'
                      AND sc.[Modulo]      IS NOT NULL

    SELECT
         [R]                = ROW_NUMBER() OVER(ORDER BY Ltrans.[Area],Ltrans.[Turno],  Ltrans.[CompanyName])
        ,[Area]             = Ltrans.[Area]
        ,[CompanyName]      = Ltrans.[CompanyName]
        ,[Turno]            = LTrans.[Turno]
        ,[EmpleadosActivos] = COUNT(*)
    -- INTO #EmpleadosActivosPorModulo
    FROM #TB_TRANSACTIONS_EMPLOYEES AS Ltrans
    WHERE   Ltrans.[rn]  = 1
      AND   Ltrans.[SoF] = 'S'
    GROUP BY
        Ltrans.[CompanyName]
        ,LTrans.[Turno]
        ,Ltrans.[Area]
                    
                    
                    SELECT DISTINCT 
                        codEmp
                        ,NombreEmpl
                        ,Modulo
                        ,SoF
                        ,Fecha
                        ,Hora
                        ,CompanyName
                        ,Turno
                        ,Area
                    FROM #TB_TRANSACTIONS_EMPLOYEES AS A
                    WHERE CompanyName LIKE 'Inspect%' AND Fecha = '20260520'
                    -- ORDER BY A.[R]
                    
-- ;WITH UltimoScan AS (
--     SELECT
--          [codEmp]        = sc.[codEmp]
--         ,[Modulo]        = TRIM(REPLACE(sc.[Modulo], CHAR(13), ''))
--         ,[SoF]           = RIGHT(md.[CompanyNumber], 1)
--         ,[Fecha]         = sc.[Fecha]
--         ,[Hora]          = sc.[Hora]
--         -- TRY_CAST: si el formato de Hora no es HH:MM:SS retorna NULL en vez de error
--         ,[HoraTime]      = TRY_CAST(sc.[Hora] AS TIME)
--         ,[CompanyName]   = md.[CompanyName]
--         ,[ppadModulo]    = 'PPAD' + LTRIM(STR(md.[AddressID] + 10000))
--         ,[rn]            = ROW_NUMBER() OVER (
--                                PARTITION BY sc.[codEmp]
--                                ORDER BY sc.[Fecha] DESC, sc.[Hora] DESC, sc.[InsertDate] DESC
--                            )
--     FROM [AppsLCA].[LinkUp].[ScanModReg] AS sc WITH(NOLOCK)
--     LEFT JOIN [LCA].[dbo].[Addresses]    AS md WITH(NOLOCK)
--            ON 'PPAD' + LTRIM(STR(md.[AddressID] + 10000)) = TRIM(REPLACE(sc.[Modulo], CHAR(13), ''))
--           AND md.[ProductionTaskName] IN ('Check In', 'Check Out')
--           AND ISNUMERIC(RIGHT(md.[ProductionTaskName], 1)) = 0
--     INNER JOIN #TB_CompanyName AS T ON T.CompanyName = md.[CompanyName]
--     WHERE sc.[Fecha]      IN (@Today, @Yesterday)
--       AND sc.[Status_Reg] <> 'Deleted'
--       AND sc.[Modulo]      IS NOT NULL
-- )
-- -- ,
-- -- EmpleadosActivos AS (
-- --     -- Solo los que tienen SoF = 'S' (estÃ¡n DENTRO del mÃ³dulo)
-- --     SELECT * FROM UltimoScan
-- --     WHERE [rn] = 1 AND [SoF] = 'S'
-- -- ),
-- -- TurnosActivos AS (
-- --     SELECT
-- --          [Turno_ID]   = td.[Turno_ID]
-- --         ,[PPMTurno]   = t.[PPMTurno]
-- --         ,[StartTime]  = td.[StartTime]
-- --         ,[EndTime]    = td.[EndTime]
-- --     FROM [AppsLCA].[dbo].[TV_Cal_TurnoDays]  AS td WITH(NOLOCK)
-- --     LEFT JOIN [AppsLCA].[dbo].[TV_Cal_Turnos] AS t  WITH(NOLOCK) ON t.[ID] = td.[Turno_ID]
-- --     WHERE
-- --         (td.[DayOfWeek] = @TodayDOW     AND td.[StartTime] < td.[EndTime] AND @CurrentTime >= td.[StartTime] AND @CurrentTime <  td.[EndTime])
-- --         OR (td.[DayOfWeek] = @TodayDOW     AND td.[StartTime] > td.[EndTime] AND @CurrentTime >= td.[StartTime])
-- --         OR (td.[DayOfWeek] = @YesterdayDOW  AND td.[StartTime] > td.[EndTime] AND @CurrentTime <  td.[EndTime])
-- -- )
-- -- SELECT
-- --      [codEmp]           = ea.[codEmp]
-- --     ,[CompanyName]      = ea.[CompanyName]
-- --     ,[Modulo]           = ea.[Modulo]
-- --     ,[Fecha]            = ea.[Fecha]
-- --     ,[Hora]             = ea.[Hora]
-- --     ,[TurnoActivo]      = ta.[PPMTurno]
-- --     -- Si el Ãºltimo scan fue de AYER y el turno de ayer ya terminÃ³ = overtime
-- --     ,[EsOvertime]       = CASE
-- --                             WHEN ta.[PPMTurno] IS NULL THEN 1   -- sin turno activo = fuera de horario
-- --                             ELSE 0
-- --                           END
-- -- FROM EmpleadosActivos   AS ea
-- -- -- El join une al empleado con el turno activo basado en su mÃ³dulo (CompanyName)
-- -- LEFT JOIN TurnosActivos AS ta ON ea.[CompanyName] IS NOT NULL  -- ajustar join a tu modelo real
-- -- ORDER BY ea.[CompanyName], ea.[codEmp]

--   SELECT * FROM UltimoScan
--     WHERE [rn] = 1 AND [SoF] = 'S'
