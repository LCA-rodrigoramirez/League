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

-- CREATE OR ALTER PROCEDURE [dbo].[SP_Production_PrepressProcess]
-- (
--      @process NVARCHAR(200)
--     ,@data NVARCHAR(MAX)
-- )
-- AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Component AS NVARCHAR(200)
    DECLARE @Error AS BIT
    DECLARE @message AS NVARCHAR(200)
    DECLARE @result AS NVARCHAR(MAX)
    DECLARE @category AS NVARCHAR(200)
    DECLARE @process NVARCHAR(200)
    DECLARE @data NVARCHAR(MAX)

    ---------PRUEBA PARA ESCANEO DE PPAD Y MO 
    -- SET @process = 'scan-mo'
    -- SET @data = '{
    --   "scannedValues":[{
    --         "PPAD":"PPAD48081",
    --         "MO":[
    --             {"WO":"5992715"}
    --         ],
    --         "Bin":""
    --     }
    --     ]
    -- }'

    ---------PRUEBA PARA LISTA DE BINES
    -- SET @process = 'bins-list'
    -- SET @data = '[]'

    ---------PRUEBA PARA REPORTE DE TRABAJO PARA PREPRENSA POR DISEÑO Y ASSIGNMENT
    SET @process = 'orders-list'
    SET @data = '[]'

    BEGIN TRY

        -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 1. Datos escaneados por el usuario
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        IF @process = 'scan-mo'
        BEGIN

            DROP TABLE IF EXISTS #TempScanMO;
            SELECT
                [PPAD]              = outer_j.[PPAD]
                ,[WO]               = inner_j.[WO]
                ,[AddressID]        = (CAST(SUBSTRING(outer_j.[PPAD], 5, LEN(outer_j.[PPAD])) AS INT) - 10000)
                ,[ManufactureID]    = CAST(NULL AS INT)
                ,[MO]               = CAST(NULL AS VARCHAR(200))
                ,[WorkOrder]        = CAST(NULL AS VARCHAR(200))
                ,[Assignment]       = CAST(NULL AS VARCHAR(200))
                ,[BinID]            = outer_j.[Bin]
            INTO #TempScanMO
            FROM OPENJSON(@data, '$.scannedValues')
            WITH (
                PPAD  VARCHAR(200) '$.PPAD'
                ,MO    NVARCHAR(MAX) '$.MO' AS JSON
                ,Bin    VARCHAR(100) '$.Bin'
            ) AS outer_j
            CROSS APPLY OPENJSON(outer_j.[MO])
            WITH (
                WO VARCHAR(200) '$.WO'
            ) AS inner_j;

            UPDATE TSM SET
                [ManufactureID] = MO.[ManufactureID]
            FROM #TempScanMO                            AS TSM
            INNER JOIN [LCA].[dbo].[ManufactureOrders]  AS MO  WITH(NOLOCK) ON MO.[ManufactureNumber] LIKE '%' + TSM.[WO] + '%' AND MO.[StatusID] < 90

            -- Si la WO tiene más de 1 ManufactureID, insertar los registros faltantes en #TempScanMO
            INSERT INTO #TempScanMO ([PPAD], [WO], [AddressID], [ManufactureID], [BinID])
            SELECT DISTINCT
                 TSM.[PPAD]
                ,TSM.[WO]
                ,TSM.[AddressID]
                ,MO.[ManufactureID]
                ,TSM.[BinID]
            FROM #TempScanMO                           AS TSM
            INNER JOIN [LCA].[dbo].[ManufactureOrders] AS MO WITH(NOLOCK) ON MO.[ManufactureNumber] LIKE '%' + TSM.[WO] + '%'
                                                                           AND MO.[StatusID] < 90
                                                                           AND MO.[ManufactureID] <> TSM.[ManufactureID]
            WHERE NOT EXISTS (
                SELECT 1 FROM #TempScanMO AS TSM2
                WHERE TSM2.[ManufactureID] = MO.[ManufactureID]
                  AND TSM2.[WO]            = TSM.[WO]
            );

            UPDATE TSM SET
                 [MO]        = MO.[ManufactureNumber]
                ,[WorkOrder]  = OD.[PONumber]
                ,[Assignment] = MO.[Comments7]
            FROM #TempScanMO                           AS TSM
            INNER JOIN [LCA].[dbo].[ManufactureOrders] AS MO WITH(NOLOCK) ON TSM.[ManufactureID] = MO.[ManufactureID]
            INNER JOIN [LCA].[dbo].[Orders]            AS OD WITH(NOLOCK) ON MO.[OrderID]        = OD.[OrderID]

            -- Validar que el PPAD escaneado exista en TB_Prepress_SequenceTasks
            DECLARE @ErrorPPAD NVARCHAR(MAX) = NULL;

            SELECT TOP 1
                @ErrorPPAD = 'El PPAD: ' + TSM.[PPAD] + ' no es válido para este proceso'
            FROM #TempScanMO AS TSM
            WHERE NOT EXISTS (
                SELECT 1
                FROM [AppsLCA].[dbo].[TB_Prepress_SequenceTasks] AS PST WITH(NOLOCK)
                WHERE PST.[PPMOperatorID] = TSM.[AddressID] AND PST.[Status] = 1
            );

            IF @ErrorPPAD IS NOT NULL
            BEGIN
                SET @Error     = 1
                SET @Component = '[400]'
                SET @message   = @ErrorPPAD
                SET @result    = '[]'
                GOTO SELECTFINAL
            END

            -- DECLARE @ValidateBin BIT = 0
            -- DECLARE @SequenceValidateBin INT = 0

            -- SELECT TOP 1
            --     @ValidateBin = PST.[RequiresBin]
            -- FROM #TempScanMO AS TSM
            -- INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks] AS PST WITH(NOLOCK) ON TSM.[AddressID] = PST.[PPMOperatorID]
            -- ORDER BY PST.[Sequence] DESC

            -- IF @ValidateBin = 1
            -- BEGIN

            --     SELECT TOP 1
            --         @SequenceValidateBin = PST.[Sequence]
            --     FROM #TempScanMO AS TSM
            --     INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks] AS PST WITH(NOLOCK) ON TSM.[AddressID] = PST.[PPMOperatorID]
            --     ORDER BY PST.[Sequence] DESC

            --     SELECT
            --          [Prepress_Bins_ID] = POS.[ID_prepress_bins]
            --         ,[MaxScreens]       = PPB.[MaxScreens]
            --         ,[BinScreens]       = SUM(POS.[ScreensByLocations])
            --     FROM [AppsLCA].[dbo].[TB_Prepress_OrdersScanned]        AS POS WITH(NOLOCK)
            --     INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks]  AS PST WITH(NOLOCK) ON POS.[Prepress_SequenceTasks_ID] = PST.[ID]
            --     LEFT  JOIN [AppsLCA].[dbo].[TB_Prepress_Bins]           AS PPB WITH(NOLOCK) ON POS.[Prepress_Bins_ID] = PPB.[ID] 
            --     WHERE PPB.[Bin] IN (SELECT [Bin] FROM #TempScanMO)
            --     GROUP BY
            --          POS.[Prepress_Bins_ID]
            --         ,PPB.[MaxScreens]
            --     HAVING MAX(PST.[Sequence]) = @SequenceValidateBin

                
            -- END
            -- RETURN

            -- Validar que la MO + tarea no haya sido escaneada previamente
            DECLARE @ErrorDuplicate NVARCHAR(MAX) = NULL;

            SELECT TOP 1
                @ErrorDuplicate = 'La WO: ' + TSM.[WorkOrder] + ' ya fue escaneada para la tarea: ' + PST.[Task]
            FROM #TempScanMO                                        AS TSM
            INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks] AS PST WITH(NOLOCK) ON TSM.[AddressID] = PST.[PPMOperatorID] AND PST.[Status] = 1
            WHERE EXISTS (
                SELECT 1
                FROM [AppsLCA].[dbo].[TB_Prepress_OrdersScanned] AS POS WITH(NOLOCK)
                WHERE POS.[ManufactureID]             = TSM.[ManufactureID]
                AND POS.[Prepress_SequenceTasks_ID] = PST.[ID]
            );

            -- Validar que la secuencia anterior esté completada antes de permitir el scan
            DECLARE @ErrorSequence NVARCHAR(MAX) = NULL;

            SELECT TOP 1
                @ErrorSequence = 'La tarea anterior (' + PST_PREV.[Task] + ') no ha sido completada para la WO: ' + TSM.[WorkOrder]
            FROM #TempScanMO                                            AS TSM
            INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks]     AS PST      WITH(NOLOCK) ON TSM.[AddressID] = PST.[PPMOperatorID] AND PST.[Status] = 1
            INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks]     AS PST_PREV WITH(NOLOCK) ON PST_PREV.[Sequence] = PST.[Sequence] - 1
            WHERE PST.[Sequence] > 1
            AND NOT EXISTS (
                    SELECT 1
                    FROM [AppsLCA].[dbo].[TB_Prepress_OrdersScanned]      AS POS       WITH(NOLOCK)
                    INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks] AS PST_PREV2 WITH(NOLOCK) ON POS.[Prepress_SequenceTasks_ID] = PST_PREV2.[ID]
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
                 [Prepress_SequenceTasks_ID]
                ,[ManufactureID]
                ,[MO]
                ,[WorkOrder]
                ,[Assignment]
                ,[Prepress_Bins_ID]
                ,[StartDate]
                ,[created_at]
            )
            SELECT
                 [TaskID]           = PST.[ID]
                ,[ManufactureID]    = TSM.[ManufactureID]
                ,[MO]               = TSM.[MO]
                ,[WorkOrder]        = TSM.[WorkOrder]
                ,[Assignment]       = TSM.[Assignment]
                ,[ID_prepress_bins] = TSM.[BinID]
                ,[StartDate]        = GETDATE()
                ,[created_at]       = GETDATE()
            FROM #TempScanMO                                        AS TSM
            INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks]  AS PST WITH(NOLOCK) ON TSM.[AddressID] = PST.[PPMOperatorID] AND PST.[Status] = 1

            -- Si la tarea actual tiene secuencia anterior, marcar ese registro como finalizado
            UPDATE POS SET
                [FinishDate] = GETDATE()
            FROM [AppsLCA].[dbo].[TB_Prepress_OrdersScanned]       AS POS
            INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks] AS PST_PREV WITH(NOLOCK) ON POS.[Prepress_SequenceTasks_ID] = PST_PREV.[ID]
            INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks] AS PST      WITH(NOLOCK) ON PST.[Sequence]     = PST_PREV.[Sequence] + 1 AND PST.[Status] = 1
            INNER JOIN #TempScanMO                                 AS TSM                   ON TSM.[AddressID]     = PST.[PPMOperatorID]
                                                                                           AND TSM.[ManufactureID] = POS.[ManufactureID]
            WHERE PST.[Sequence] > 1

            END

            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Datos generados correctamente'

        END

        IF @process = 'bins-list'
        BEGIN

            SET @result = (
                SELECT
                     [ID]
                    ,[Bin]
                FROM [AppsLCA].[dbo].[TB_Prepress_Bins] WITH(NOLOCK)
                WHERE [Status] = 1
                FOR JSON PATH
            )
            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Datos generados correctamente'

        END

        IF @process = 'orders-list'
        BEGIN

            DROP TABLE IF EXISTS #TB_ORD_LIST

            SELECT DISTINCT
                [ItemDetailID]	= CASE
                                    WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
                                        NULL
                                    WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
                                        cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT)
                                    ELSE
                                        NULL
                                    END
                ,[Req Ship]     = CAST(OD.[RequiredDate] AS DATE)
                ,[WorkOrder]    = OD.[PONumber]
                ,[Style]        = ST.[StyleNumber]
                ,[Color]        = SC.[StyleColorName]
                ,[Make]         = OD.[RequestCount]
                ,[PWModulo]     = MO.[Comments7]
                ,[Design]       = CAST(NULL AS VARCHAR(100))
                ,[OrderType]    = CAST(NULL AS VARCHAR(100))
                ,[ImageLink]    = CAST(NULL AS VARCHAR(MAX))
            INTO #TB_ORD_LIST
            FROM (SELECT StatusID FROM [LCA].[dbo].[StatusNames] sn with (nolock) WHERE StatusID < 90 and StatusID not in (67,20)) AS SN
            INNER JOIN [LCA].[dbo].[ManufactureOrders]  AS MO WITH(NOLOCK) ON SN.[StatusID] = MO.[StatusID]
            INNER JOIN [LCA].[dbo].[Orders]             AS OD WITH(NOLOCK) ON MO.[OrderID] = OD.[OrderID]
            INNER JOIN [LCA].[dbo].[OrderItems]         AS OI WITH(NOLOCK) ON OI.[OrderItemID] = MO.[FirstOrderItemID]
            INNER JOIN [LCA].[dbo].[Styles]             AS ST WITH(NOLOCK) ON OI.[StyleID] = ST.[StyleID]
            INNER JOIN [LCA].[dbo].[StyleColors]        AS SC WITH(NOLOCK) ON OI.[StyleColorID] = SC.[StyleColorID]
            WHERE CASE
                                    WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
                                        NULL
                                    WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
                                        cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT)
                                    ELSE
                                        NULL
                                    END IS NOT NULL

            
            UPDATE OL SET
                 [Design]       = DC.[DesignNo]
                ,[OrderType]    = LG.[OrderTypeDescription]
            FROM #TB_ORD_LIST                                                             AS OL
            INNER JOIN [192.168.1.93].[AppsLCA].[legacycaps].[VW_view_LCA_DesignColors]   AS DC ON DC.[ItemDetailID] = OL.[ItemDetailID] AND DC.[LogoStyleName] LIKE '%Screen Print%'
            LEFT JOIN OPENQUERY([MARIADB],'SELECT * FROM wordpress.L2Brands_LogoStyle') AS LG ON DC.[LogoStyle] = LG.[LogoStyle]

            UPDATE OL SET
                [ImageLink]    = CONCAT(
                                                'l2lookup.l2brands.org/p_drive/Production%20Data/Photos/SKU/',
                                                RIGHT(OE.[SKUID Link], CHARINDEX('=', REVERSE(OE.[SKUID Link])) - 1),
                                                '.jpg'
                                            )
            FROM #TB_ORD_LIST                                               AS OL
            INNER JOIN [AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export] AS OE ON OL.[ItemDetailID] = OE.[ItemDetailID]
            
            DELETE FROM #TB_ORD_LIST WHERE [OrderType] NOT LIKE '%Print%' OR [OrderType] IS NULL

            SELECT * FROM #TB_ORD_LIST
            ORDER BY PWModulo DESC

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