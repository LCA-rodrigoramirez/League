USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_ModuleBreaks]    Script Date: 23/04/2026 03:52:03 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_ModuleBreaks]
(
    @process VARCHAR(MAX)
    ,@data NVARCHAR(MAX)
)
AS

SET NOCOUNT ON;

BEGIN
    BEGIN TRY

        DECLARE @FinalComponent AS NVARCHAR(MAX) = ''
        DECLARE @Error		AS BIT
        DECLARE @Msg AS NVARCHAR(MAX) = ''
        DECLARE @result AS NVARCHAR(MAX) = ''

        DECLARE @IdArea		AS NVARCHAR(MAX)
	    DECLARE @Area		AS NVARCHAR(MAX)

        ------------PRUEBA PARA INSERT DESDE EXCEL
--         DECLARE @process	AS VARCHAR(MAX)
--         DECLARE @data		AS NVARCHAR(MAX)
--         SET @process	= 'insert.breaks.excel'
--         SET @data		= '{
--       "selectedModules":[
--          {
--             "id":0,
--             "Departamento":"Costura - Modulo 4",
--             "TipoReceso":"Almuerzo",
--             "HoraInicio":"11:25:00",
--             "HoraFin":"12:00:00"
--          },
--          {
--             "id":1,
--             "Departamento":"Costura - Modulo 7",
--             "TipoReceso":"Almuerzo",
--             "HoraInicio":"11:25:00",
--             "HoraFin":"12:00:00"
--          },
--       ],
--       "selectedDates":[
--          {
--             "DateIni":"2025-11-01",
--             "DateFin":"2025-11-01"
--          }
--       ]
--    }'

        ------------PRUEBA PARA TRAER INFORMACION DE LAS AREAS
        -- DECLARE @process	AS VARCHAR(MAX)
        -- DECLARE @data		AS NVARCHAR(MAX)
        -- SET @process	= 'areas.list'
        -- SET @data       = NULL

        ------------PRUEBA PARA TRAER INFORMACION DE LOS MODULOS
        -- DECLARE @process	AS VARCHAR(MAX)
        -- DECLARE @data		AS NVARCHAR(MAX)
        -- SET @process	= 'modules.list'
        -- SET @data       = '{"selectedOptions": [{
        --                                     "idArea":"2"
        --                                     }]}'

        ------------PRUEBA PARA TRAER HORARIOS DE LOS MODULOS
        -- DECLARE @process	AS VARCHAR(MAX)
        -- DECLARE @data		AS NVARCHAR(MAX)
        -- SET @process	= 'modules.schedules'
        -- SET @data       = '{
        --                     "selectedOptions":[
        --                         {
        --                             "idModulo":23
        --                         },
        --                         {
        --                             "idModulo":24
        --                         },
        --                         {
        --                             "idModulo":25
        --                         },
        --                     ]
        --                 }'

        ------------PRUEBA PARA GUARDAR HORARIOS DE LOS MODULOS
        -- DECLARE @process	AS VARCHAR(MAX)
        -- DECLARE @data		AS NVARCHAR(MAX)
        -- SET @process	= 'insert.schedules'
        -- SET @data       = '{
        --                         "Modules":[
        --                             {
        --                                 "idModulo":"88"
        --                             },
        --                             {
        --                                 "idModulo":"89"
        --                             }
        --                         ],
        --                         "Dates":[
        --                             {
        --                                 "Date":"2026-04-24"
        --                             }
        --                         ],
        --                         "HoraIni":"12:30:00",
        --                         "HoraFin":"13:05:00",
        --                         "TypeBreak":"Break",
        --                         "Area":"Trim & Inspection HW",
        --                         "Password":"$TrimsInpection2025$"
        --                     }'

        

        ------------PRUEBA PARA ELIMINAR HORARIOS DE LOS MODULOS
        -- DECLARE @process	AS VARCHAR(MAX)
        -- DECLARE @data		AS NVARCHAR(MAX)
        -- SET @process	= 'delete.schedules'
        -- SET @data       = '{
        --                     "Modules":[
        --                         {
        --                             "idModulo":"88"
        --                         },
        --                         {
        --                             "idModulo":"89"
        --                         }
        --                     ],
        --                     "Dates":[
        --                         {
        --                             "Date":"2026-04-24"
        --                         }
        --                     ],
        --                     "HoraIni":"12:30:00",
        --                     "HoraFin":"13:05:00",
        --                     "TypeBreak":"Break",
        --                     "Area":"Trim & Inspection HW",
        --                     "Password":"$TrimsInpection2025$"
        --                 }'

        IF @process = 'insert.breaks.excel'
            BEGIN
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' insert.breaks')
                
                DECLARE @listModuleBreaks	AS NVARCHAR(MAX)
                SET @listModuleBreaks	    = (SELECT JSON_QUERY(@data, '$.selectedModules'))

                DROP TABLE IF EXISTS #TB_DATA_JSON_MODULE_INSERT_PRE
                DROP TABLE IF EXISTS #TB_DATA_JSON_MODULE_INSERT
                SELECT 
                    [R]              = ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
                    ,[Departamento]	        = STJ.[Departamento]
                    ,[HoraInicio]		  = STJ.[HoraInicio]
                    ,[HoraFin]        = STJ.[HoraFin]
                    ,[TipoReceso]     = STJ.[TipoReceso]
                    ,[AreaCompleta]   = CAST(IIF(STJ.[AreaCompleta] = 'Si',1,0) AS BIT)
                INTO #TB_DATA_JSON_MODULE_INSERT_PRE
                FROM OPENJSON(@listModuleBreaks)
                WITH (	 
                        [Departamento]		VARCHAR(30)
                        ,[HoraInicio]	TIME(7)
                        ,[HoraFin]  	TIME(7)
                        ,[TipoReceso]   VARCHAR(20)
                        ,[AreaCompleta]   VARCHAR(10)
                    ) AS STJ


                SELECT 
                    [Modulo]       =  IIF(TEM.[Module] = 'ALL', AD.CompanyName,TEM.Module)
                    ,[HoraInicio]   =  TMI.HoraInicio
                    ,[HoraFin]      =  TMI.HoraFin
                    ,[TipoReceso]   =  TMI.TipoReceso
                    ,[Area]         =  TEM.Area
                    ,[AreaCompleta] =  TEM.AreaCompleta
                INTO #TB_DATA_JSON_MODULE_INSERT
                FROM #TB_DATA_JSON_MODULE_INSERT_PRE AS TMI
                INNER JOIN [dbo].[TV_EquivalenciaModulos] AS TEM WITH(NOLOCK) ON TMI.Departamento = TEM.Departamento AND COALESCE(TMI.AreaCompleta,0) = COALESCE(TEM.AreaCompleta,0)
                LEFT  JOIN 
                (   
                    SELECT DISTINCT 
                        AD.CompanyName
                        ,AD.Comments6
                    FROM
                    LCA.dbo.Addresses AS AD WITH(NOLOCK)
                    WHERE Comments6 IS NOT NULL
                ) AS AD ON TEM.Area = AD.Comments6 AND TMI.AreaCompleta = 1


                DECLARE @listDates	    AS NVARCHAR(MAX)
                SET @listDates	    = (SELECT JSON_QUERY(@data, '$.selectedDates'))

                DROP TABLE IF EXISTS #TB_DATA_JSON_DATE_RANGES
                SELECT 
                        [R]            = ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
                    ,[DateIni]	    = STJ.[DateIni]
                    ,[DateFin]		= STJ.[DateFin]
                INTO #TB_DATA_JSON_DATE_RANGES
                FROM OPENJSON(@listDates)
                WITH (	 
                            [DateIni]	DATE
                        ,[DateFin]  DATE
                    ) AS STJ

                ------------------------------------------------------------------
                -- 📅 Generar todas las fechas entre DateIni y DateFin
                ------------------------------------------------------------------
                DROP TABLE IF EXISTS #TB_ALL_DATES;

                ;WITH DateRange AS (
                    SELECT DateIni AS Fecha, DateFin
                    FROM #TB_DATA_JSON_DATE_RANGES
                    UNION ALL
                    SELECT DATEADD(DAY, 1, Fecha), DateFin
                    FROM DateRange
                    WHERE Fecha < DateFin
                )
                SELECT Fecha
                INTO #TB_ALL_DATES
                FROM DateRange
                OPTION (MAXRECURSION 32767);

                ------------------------------------------------------------------
                -- 🔗 Cruzar cada módulo con cada fecha generada
                ------------------------------------------------------------------
                DROP TABLE IF EXISTS #TB_FINAL_BREAKS;

                SELECT 
                    ROW_NUMBER() OVER (ORDER BY M.Modulo, D.Fecha) AS R,
                    M.Modulo,
                    M.HoraInicio,
                    M.HoraFin,
                    M.TipoReceso,
                    TVM.ID,
                    D.Fecha
                INTO #TB_FINAL_BREAKS
                FROM #TB_ALL_DATES AS D
                CROSS JOIN #TB_DATA_JSON_MODULE_INSERT AS M
                INNER JOIN dbo.TV_Modulos AS TVM WITH (NOLOCK)
                    ON M.Modulo = TVM.Modulo;

                ------------------------------------------------------------------
                -- ✅ Resultado final
                ------------------------------------------------------------------
                INSERT INTO dbo.TV_Module_Breaks

                SELECT 
                    ID
                    ,Fecha
                    ,TipoReceso
                    ,HoraInicio
                    ,HoraFin
                FROM #TB_FINAL_BREAKS;

                SET @result = '[]'
                SET @FinalComponent = '[Completed]'
                SET @Msg = 'Success, Data Inserted'
                SET @Error = 0
                   
            END
        
        IF @process = 'areas.list'
            BEGIN
                SET @result		=   (
										SELECT  id, area, [description],maxItemPerScreen 
										FROM AppsLCA.dbo.TV_Areas WITH(NOLOCK)
                                        -- WHERE id = 1
										FOR JSON PATH ,INCLUDE_NULL_VALUES
									)

                SET @FinalComponent = '[Completed]'
                SET @Msg = 'Data Extracted Successfully'
                SET @Error = 0   
            END
        
        IF @process = 'modules.list'
            BEGIN
                SET @Area			= (SELECT JSON_QUERY(@data, '$.selectedOptions'))
				SET @IdArea			= (SELECT
											[idArea]		= STJ.[idArea]
										FROM OPENJSON(@Area)
										WITH (	 
										        [idArea]			INT
										    ) AS STJ)

				SET @result		= (
										SELECT
											 ID, Modulo, Area_ID
											 FROM [AppsLCA].[dbo].[TV_Modulos] WITH(NOLOCK)
											 WHERE Area_ID = @IdArea
										FOR JSON PATH ,INCLUDE_NULL_VALUES
									)
                SET @FinalComponent = '[Completed]'
                SET @Msg = 'Data Extracted Successfully'
                SET @Error = 0 
            END

        IF @process = 'modules.schedules'
            BEGIN
                DECLARE @Modulo     AS NVARCHAR(MAX)
                DECLARE @IdModulo   AS NVARCHAR(MAX)
                DECLARE @dates      AS NVARCHAR(MAX)

                DROP TABLE IF EXISTS #TB_ModulosID

                SET @Modulo			= (SELECT JSON_QUERY(@data, '$.selectedOptions'))
				SELECT
                    [idModulo]		= STJ.[idModulo]
                INTO #TB_ModulosID
                FROM OPENJSON(@Modulo)
                WITH (	 
                        [idModulo]			INT
                    ) AS STJ

				SET @result		= (
										SELECT
                                             ID
                                            ,IDModule
                                            ,Fecha
                                            ,HoraInicio
                                            ,HoraFin
                                            ,TipoPausa
                                        FROM [AppsLCA].[dbo].[TV_Module_Breaks] AS TMB WITH(NOLOCK)
                                        INNER JOIN #TB_ModulosID AS TM ON TMB.IDModule = TM.idModulo
                                        AND Fecha >= CAST(GETDATE() AS DATE)
                                        ORDER BY IDModule
										FOR JSON PATH ,INCLUDE_NULL_VALUES
									)

                SET @dates = (
                                SELECT STRING_AGG(CONCAT('"', CONVERT(varchar(10), Fecha, 23), '"'), ',')
                                FROM
                                (
                                    SELECT DISTINCT Fecha
                                    FROM [AppsLCA].[dbo].[TV_Module_Breaks] AS TMB WITH(NOLOCK)
                                    INNER JOIN #TB_ModulosID AS TM ON TMB.IDModule = TM.idModulo
                                    AND Fecha >= CAST(GETDATE() AS DATE)
                                ) AS TB
                            );

                SET @dates = CONCAT('[', @dates, ']');

                SET @FinalComponent = '[Completed]'
                SET @Msg = 'Data Extracted Successfully'
                SET @Error = 0 

                SELECT 
                     [Result]           = JSON_QUERY(@result)
                    ,[Dates]            = JSON_QUERY(@dates)
                    ,[Error]			= @Error
                    ,[FinalComponent]   = @FinalComponent
                    ,[Msg]              = @Msg
                FOR JSON PATH
            END

        IF @process = 'insert.schedules'
        BEGIN
            DECLARE @ModulesInsert AS NVARCHAR(MAX) = (SELECT JSON_QUERY(@data,'$.Modules'))
            DECLARE @DatesInsert AS NVARCHAR(MAX) = (SELECT JSON_QUERY(@data,'$.Dates'))
            DECLARE @HoraIni AS NVARCHAR(MAX) = (SELECT JSON_VALUE(@data,'$.HoraIni'))
            DECLARE @HoraFin AS NVARCHAR(MAX) = (SELECT JSON_VALUE(@data,'$.HoraFin'))
            DECLARE @TypeBreak AS NVARCHAR(MAX) = (SELECT JSON_VALUE(@data,'$.TypeBreak'))
            DECLARE @AreaInsert AS NVARCHAR(MAX) = (SELECT JSON_VALUE(@data,'$.Area'))
            DECLARE @Pass AS NVARCHAR(MAX) = (SELECT JSON_VALUE(@data,'$.Password'))

            DROP TABLE IF EXISTS #TB_Modules_Insert
            DROP TABLE IF EXISTS #TB_Dates_Insert
            DROP TABLE IF EXISTS #TB_ALL

            DECLARE @AreaCompare AS NVARCHAR(MAX) = (
                SELECT
                    TA.area
                FROM [AppsLCA].[dbo].[TV_AreaPasswords] AS TAP WITH(NOLOCK)
                LEFT JOIN [AppsLCA].[dbo].[TV_Areas] AS TA WITH(NOLOCK) ON TAP.Area_ID = TA.id
                WHERE TAP.[Password] = @Pass
            )

            SELECT 
                    IDModulo
                INTO #TB_Modules_Insert
                FROM OPENJSON(@ModulesInsert)
                WITH(
                    idModulo INT
                )
                
                SELECT 
                    DateBreak = [Date]
                INTO #TB_Dates_Insert
                FROM OPENJSON(@DatesInsert)
                WITH(
                    [Date] DATE
                )

                SELECT *, @HoraIni AS HoraIni, @HoraFin AS HoraFin, @TypeBreak AS TipoPausa
                INTO #TB_ALL
                FROM #TB_Modules_Insert
                CROSS APPLY #TB_Dates_Insert

            IF @Pass = '$Recurso$Humano$2026'
            BEGIN

                IF EXISTS (
                    SELECT TA.*
                    FROM #TB_ALL AS TA
                    INNER JOIN [AppsLCA].[dbo].[TV_Module_Breaks] AS TVB WITH(NOLOCK) ON TA.IDModulo = TVB.IDModule AND TA.DateBreak = TVB.Fecha
                )
                BEGIN
                    -- select
                    UPDATE TVB SET
                        HoraInicio = TA.HoraIni
                        ,HoraFin    = TA.HoraFin
                        ,TipoPausa  = CASE 
                                        WHEN TA.TipoPausa = 'Lunch' THEN 'Almuerzo' 
                                        WHEN TA.TipoPausa = 'Break' THEN 'Descanso' 
                                        WHEN TA.TipoPausa = 'Dinner' THEN 'Cena' 
                                    END
                    FROM #TB_ALL AS TA
                    INNER JOIN [AppsLCA].[dbo].[TV_Module_Breaks] AS TVB WITH(NOLOCK) ON TA.IDModulo = TVB.IDModule AND TA.DateBreak = TVB.Fecha

                    SET @FinalComponent = '[Completed]'
                    SET @Error = 0
                    SET @Msg = 'Success, Data Inserted'

                END

                IF EXISTS
                (
                    SELECT TA.*
                    FROM #TB_ALL AS TA
                    LEFT JOIN [AppsLCA].[dbo].[TV_Module_Breaks] AS TVB WITH(NOLOCK) ON TA.IDModulo = TVB.IDModule AND TA.DateBreak = TVB.Fecha
                    WHERE TVB.IDModule IS NULL
                )
                BEGIN
                    INSERT INTO [AppsLCA].[dbo].[TV_Module_Breaks]
                    SELECT
                        TA.IDModulo
                        ,TA.DateBreak
                        ,TipoPausa  = CASE 
                                        WHEN TA.TipoPausa = 'Lunch' THEN 'Almuerzo' 
                                        WHEN TA.TipoPausa = 'Break' THEN 'Descanso' 
                                        WHEN TA.TipoPausa = 'Dinner' THEN 'Cena' 
                                    END
                        ,TA.HoraIni
                        ,TA.HoraFin
                    FROM #TB_ALL AS TA
                    LEFT JOIN [AppsLCA].[dbo].[TV_Module_Breaks] AS TVB WITH(NOLOCK) ON TA.IDModulo = TVB.IDModule AND TA.DateBreak = TVB.Fecha
                    WHERE TVB.IDModule IS NULL

                    SET @FinalComponent = '[Completed]'
                    SET @Error = 0
                    SET @Msg = 'Success, Data Inserted'
                END
            END
            ELSE
            BEGIN
                IF @AreaInsert <> @AreaCompare
                BEGIN
                    SET @FinalComponent = '[PasswordIncorrect]'
                    SET @Msg = 'Incorrect Password for ' + @AreaInsert + ' Area'
                    SET @Error = 1
                END
                ELSE
                BEGIN
                    IF @AreaInsert = @AreaCompare
                    BEGIN

                        IF EXISTS (
                            SELECT TA.*
                            FROM #TB_ALL AS TA
                            INNER JOIN [AppsLCA].[dbo].[TV_Module_Breaks] AS TVB WITH(NOLOCK) ON TA.IDModulo = TVB.IDModule AND TA.DateBreak = TVB.Fecha
                        )
                        BEGIN
                            -- select
                            UPDATE TVB SET
                                HoraInicio = TA.HoraIni
                                ,HoraFin    = TA.HoraFin
                                ,TipoPausa  = CASE 
                                                WHEN TA.TipoPausa = 'Lunch' THEN 'Almuerzo' 
                                                WHEN TA.TipoPausa = 'Break' THEN 'Descanso' 
                                                WHEN TA.TipoPausa = 'Dinner' THEN 'Cena' 
                                            END
                            FROM #TB_ALL AS TA
                            INNER JOIN [AppsLCA].[dbo].[TV_Module_Breaks] AS TVB WITH(NOLOCK) ON TA.IDModulo = TVB.IDModule AND TA.DateBreak = TVB.Fecha

                            SET @FinalComponent = '[Completed]'
                            SET @Error = 0
                            SET @Msg = 'Success, Data Inserted'

                        END

                        IF EXISTS
                        (
                            SELECT TA.*
                            FROM #TB_ALL AS TA
                            LEFT JOIN [AppsLCA].[dbo].[TV_Module_Breaks] AS TVB WITH(NOLOCK) ON TA.IDModulo = TVB.IDModule AND TA.DateBreak = TVB.Fecha
                            WHERE TVB.IDModule IS NULL
                        )
                        BEGIN
                            INSERT INTO [AppsLCA].[dbo].[TV_Module_Breaks]
                            SELECT
                                TA.IDModulo
                                ,TA.DateBreak
                                ,TipoPausa  = CASE 
                                                WHEN TA.TipoPausa = 'Lunch' THEN 'Almuerzo' 
                                                WHEN TA.TipoPausa = 'Break' THEN 'Descanso' 
                                                WHEN TA.TipoPausa = 'Dinner' THEN 'Cena' 
                                            END
                                ,TA.HoraIni
                                ,TA.HoraFin
                            FROM #TB_ALL AS TA
                            LEFT JOIN [AppsLCA].[dbo].[TV_Module_Breaks] AS TVB WITH(NOLOCK) ON TA.IDModulo = TVB.IDModule AND TA.DateBreak = TVB.Fecha
                            WHERE TVB.IDModule IS NULL

                            SET @FinalComponent = '[Completed]'
                            SET @Msg = 'Success, Data Inserted'
                            SET @Error = 0
                        END
                    END
                    ELSE
                    BEGIN
                        SET @FinalComponent = '[PasswordIncorrect]'
                        SET @Msg = 'Incorrect Password'
                        SET @Error = 1
                    END
                END
            END

            SET @result = '[]'

        END
        IF @process = 'delete.schedules'
        BEGIN
            DECLARE @ModulesDelete AS NVARCHAR(MAX) = (SELECT JSON_QUERY(@data,'$.Modules'))
            DECLARE @DatesDelete AS NVARCHAR(MAX) = (SELECT JSON_QUERY(@data,'$.Dates'))
            DECLARE @AreaDelete AS NVARCHAR(MAX) = (SELECT JSON_VALUE(@data,'$.Area'))
            DECLARE @PassDelete AS NVARCHAR(MAX) = (SELECT JSON_VALUE(@data,'$.Password'))

            DROP TABLE IF EXISTS #TB_Modules_Delete
            DROP TABLE IF EXISTS #TB_Dates_Delete
            DROP TABLE IF EXISTS #TB_ALL_Delete

            DECLARE @AreaCompareDelete AS NVARCHAR(MAX) = (
                SELECT
                    TA.area
                FROM [AppsLCA].[dbo].[TV_AreaPasswords] AS TAP WITH(NOLOCK)
                LEFT JOIN [AppsLCA].[dbo].[TV_Areas] AS TA WITH(NOLOCK) ON TAP.Area_ID = TA.id
                WHERE TAP.[Password] = @PassDelete
            )

            SELECT
                [IDModulo] = idModulo
            INTO #TB_Modules_Delete
            FROM OPENJSON(@ModulesDelete)
            WITH(
                idModulo INT
            )

            SELECT
                DateBreak = [Date]
            INTO #TB_Dates_Delete
            FROM OPENJSON(@DatesDelete)
            WITH(
                [Date] DATE
            )

            SELECT IDModulo, DateBreak
            INTO #TB_ALL_Delete
            FROM #TB_Modules_Delete
            CROSS JOIN #TB_Dates_Delete

            IF @PassDelete = '$Recurso$Humano$2026'
            BEGIN

                IF EXISTS (
                    SELECT TA.*
                    FROM #TB_ALL_Delete AS TA
                    INNER JOIN [AppsLCA].[dbo].[TV_Module_Breaks] AS TVB WITH(NOLOCK) ON TA.IDModulo = TVB.IDModule AND TA.DateBreak = TVB.Fecha
                )
                BEGIN
                    DELETE TVB
                    FROM [AppsLCA].[dbo].[TV_Module_Breaks] AS TVB
                    INNER JOIN #TB_ALL_Delete AS TA ON TA.IDModulo = TVB.IDModule AND TA.DateBreak = TVB.Fecha

                    SET @FinalComponent = '[Completed]'
                    SET @Error = 0
                    SET @Msg = 'Success, Data Deleted'

                END

            END
            ELSE
            BEGIN
                IF @AreaDelete <> @AreaCompareDelete
                BEGIN
                    SET @FinalComponent = '[PasswordIncorrect]'
                    SET @Msg = 'Incorrect Password for ' + @AreaDelete + ' Area'
                    SET @Error = 1
                END
                ELSE
                BEGIN
                    IF @AreaDelete = @AreaCompareDelete
                    BEGIN

                        IF EXISTS (
                            SELECT TA.*
                            FROM #TB_ALL_Delete AS TA
                            INNER JOIN [AppsLCA].[dbo].[TV_Module_Breaks] AS TVB WITH(NOLOCK) ON TA.IDModulo = TVB.IDModule AND TA.DateBreak = TVB.Fecha
                        )
                        BEGIN
                            DELETE TVB
                            FROM [AppsLCA].[dbo].[TV_Module_Breaks] AS TVB
                            INNER JOIN #TB_ALL_Delete AS TA ON TA.IDModulo = TVB.IDModule AND TA.DateBreak = TVB.Fecha

                            SET @FinalComponent = '[Completed]'
                            SET @Error = 0
                            SET @Msg = 'Success, Data Deleted'

                        END

                    END
                    ELSE
                    BEGIN
                        SET @FinalComponent = '[PasswordIncorrect]'
                        SET @Msg = 'Incorrect Password'
                        SET @Error = 1
                    END
                END
            END

            SET @result = '[]'
        END

    END TRY
    BEGIN CATCH
        SET @FinalComponent = '[DataBase]'
        SET @Msg = 'Error, Please Contact IT Team'
        SET @Error = 1
    END CATCH

    SELECT 
             [Result]           = JSON_QUERY(@result)
			,[Error]			= @Error
            ,[FinalComponent]   = @FinalComponent
            ,[Msg]              = @Msg
   FOR JSON PATH, INCLUDE_NULL_VALUES
END