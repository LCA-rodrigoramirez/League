USE [AppsLCA]
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------SP PARA PREPRENSA, PRODUCTION PREPRESS PROCESS-------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----Que hace este script
------1) El usuario envío por Scanner un Operador (PPAD) y 1 o varias MO para indicar el inicio de un proceso o tarea en Preprensa, la tarea que escanee y la orden se guardan
------   en tabla [AppsLCA].[dbo].[Prepress_OrdersScanned] y se valida que la tarea que escaneen no hay sido previamente escaneada para esa orden y que no hay tareas pendientes,
------   devuelve un mensaje de error si es el caso.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE [dbo].[SP_Production_PrepressProcess]
(
     @process NVARCHAR(200)
    ,@data NVARCHAR(MAX)
)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Component AS NVARCHAR(200)
    DECLARE @Error AS BIT
    DECLARE @message AS NVARCHAR(200)
    DECLARE @result AS NVARCHAR(MAX)
    DECLARE @category AS NVARCHAR(200)
    -- DECLARE @process NVARCHAR(200)
    -- DECLARE @data NVARCHAR(MAX)

    -----------PRUEBA PARA ESCANEO DE PPAD Y MO 
    -- SET @process = 'scan-mo'
    -- SET @data = '{
    --   "scannedValues":[{
    --         "PPAD":"PPAD48078",
    --         "MO":[
    --             {"PPMO":"PPMO1982223"},
    --             {"PPMO":"PPMO1891129"}
    --         ]
    --     }]
    -- }'

    BEGIN TRY

        -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 1. Datos escaneados por el usuario
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        IF @process = 'scan-mo'
        BEGIN

            DROP TABLE IF EXISTS #TempScanMO;
            SELECT
                [PPAD]          = outer_j.[PPAD]
                ,[PPMO]          = inner_j.[PPMO]
                ,[AddressID]     = (CAST(SUBSTRING(outer_j.[PPAD], 5, LEN(outer_j.[PPAD])) AS INT) - 10000)
                ,[ManufactureID] = (CAST(SUBSTRING(inner_j.[PPMO], 5, LEN(inner_j.[PPMO])) AS INT) - 1000000)
            INTO #TempScanMO
            FROM OPENJSON(@data, '$.scannedValues')
            WITH (
                PPAD  NVARCHAR(200) '$.PPAD'
                ,MO    NVARCHAR(MAX) '$.MO' AS JSON
            ) AS outer_j
            CROSS APPLY OPENJSON(outer_j.[MO])
            WITH (
                PPMO NVARCHAR(200) '$.PPMO'
            ) AS inner_j;


            -- Validar que la MO + tarea no haya sido escaneada previamente
            DECLARE @ErrorDuplicate NVARCHAR(MAX) = NULL;

            SELECT TOP 1
                @ErrorDuplicate = 'La MO: ' + MO.[ManufactureNumber] + ' ya fue escaneada para la tarea: ' + PST.[Task]
            FROM #TempScanMO                                        AS TSM
            INNER JOIN [LCA].[dbo].[ManufactureOrders]             AS MO  WITH(NOLOCK) ON TSM.[ManufactureID] = MO.[ManufactureID]
            INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks] AS PST WITH(NOLOCK) ON TSM.[AddressID] = PST.[PPMOperatorID] AND PST.[Status] = 1
            WHERE EXISTS (
                SELECT 1
                FROM [AppsLCA].[dbo].[TB_Prepress_OrdersScanned] AS POS WITH(NOLOCK)
                WHERE POS.[ManufactureID]             = TSM.[ManufactureID]
                AND POS.[ID_prepress_sequencetasks] = PST.[ID]
            );

            -- Validar que la secuencia anterior esté completada antes de permitir el scan
            DECLARE @ErrorSequence NVARCHAR(MAX) = NULL;

            SELECT TOP 1
                @ErrorSequence = 'La tarea anterior (' + PST_PREV.[Task] + ') no ha sido completada para la MO: ' + MO.[ManufactureNumber]
            FROM #TempScanMO                                            AS TSM
            INNER JOIN [LCA].[dbo].[ManufactureOrders]                 AS MO       WITH(NOLOCK) ON TSM.[ManufactureID] = MO.[ManufactureID]
            INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks]     AS PST      WITH(NOLOCK) ON TSM.[AddressID] = PST.[PPMOperatorID] AND PST.[Status] = 1
            INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks]     AS PST_PREV WITH(NOLOCK) ON PST_PREV.[Sequence] = PST.[Sequence] - 1
            WHERE PST.[Sequence] > 1
            AND NOT EXISTS (
                    SELECT 1
                    FROM [AppsLCA].[dbo].[TB_Prepress_OrdersScanned]      AS POS       WITH(NOLOCK)
                    INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks] AS PST_PREV2 WITH(NOLOCK) ON POS.[ID_prepress_sequencetasks] = PST_PREV2.[ID]
                    WHERE POS.[ManufactureID] = TSM.[ManufactureID]
                    AND PST_PREV2.[Sequence] = PST.[Sequence] - 1
            );

            IF @ErrorDuplicate IS NOT NULL OR @ErrorSequence IS NOT NULL
            BEGIN
                SET @Error     = 1
                SET @Component = '[400]'
                SET @message   = CONCAT(@ErrorDuplicate, IIF(@ErrorDuplicate IS NOT NULL AND @ErrorSequence IS NOT NULL, ' | ', ''), @ErrorSequence)
                SET @result    = '[]'

                GOTO SELECTFINAL
            END
            ELSE
            BEGIN

            INSERT INTO [AppsLCA].[dbo].[TB_Prepress_OrdersScanned]
            (
                [ID_prepress_sequencetasks]
                ,[ManufactureID]
                ,[MO]
                ,[WorkOrder]
                ,[Assignment]
                ,[created_at]
            )
            SELECT
                [TaskID]           = PST.[ID]
                ,[ManufactureID]    = TSM.[ManufactureID]
                ,[MO]               = MO.[ManufactureNumber]
                ,[WorkOrder]        = OD.[PONumber]
                ,[Assignment]       = MO.[Comments7]
                ,[created_at]       = GETDATE()
            FROM #TempScanMO                                        AS TSM
            INNER JOIN [LCA].[dbo].[ManufactureOrders]              AS MO  WITH(NOLOCK) ON TSM.[ManufactureID] = MO.[ManufactureID]
            INNER JOIN [LCA].[dbo].[Orders]                         AS OD  WITH(NOLOCK) ON MO.[OrderID] = OD.[OrderID]
            INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks]  AS PST WITH(NOLOCK) ON TSM.[AddressID] = PST.[PPMOperatorID] AND PST.[Status] = 1

            END

        END
        
        -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 1. Datos escaneados por el usuario
        -------------------------------------------------------------------------------------------------------------------------------------------------------
    
    END TRY
    BEGIN CATCH

        SET @Error = 1
        SET @result = '[]'
        SET @Component = '[404]'
        SET @message = 'Error in Database'

    END CATCH

    SELECTFINAL:

    SELECT
         [Error]        = @Error
        ,[Component]    = @Component
        ,[Message]      = @message
        ,[result]       = JSON_QUERY(@result)
    FOR JSON PATH, INCLUDE_NULL_VALUES

END