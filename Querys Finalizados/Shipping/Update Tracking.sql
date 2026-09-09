USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_UPDATE_PackedBoxes_TrackingNo]    Script Date: 03/09/2026 02:41:11 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================================================
-- SP_UPDATE_PackedBoxes_TrackingNo
-- Same pattern as [dbo].[SP_WeeklyBoxes] / [dbo].[SP_Financial_MonthlyClose]:
-- receives @process + @data and returns a single unified JSON
-- { Error, message, messageData, Result }.
--
-- PROCESSES:
--   trackingno.update -> pulls TrackingNo from the remote Production DB
--                         (linked server db1.legacycaps.com) for boxes shipped
--                         in the last 7 days and stamps it into
--                         LCA.dbo.PackedBoxes.BoxComments6              Result: [...]
--
-- DATABASES:
--   LCA                     -> StatusNames, PackedBoxes, Shipments, Orders
--   db1.legacycaps.com      -> Production.dbo.prod_ShipDetail / prod_ShipTracking (linked server, via OPENQUERY)
--
-- Intended to run on a schedule (SQL Agent job), no input parameters required.
-- =============================================================================

ALTER PROCEDURE [dbo].[SP_UPDATE_PackedBoxes_TrackingNo]
     @process    VARCHAR(MAX)
    ,@data       NVARCHAR(MAX) = NULL
    ,@NoSelect   BIT           = 0
    ,@otherData  NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
-- EXEC [AppsLCA].[dbo].[SP_UPDATE_PackedBoxes_TrackingNo] @process = 'trackingno.update', @data = NULL, @NoSelect = 1

    -------PRUEBA PARA trackingno.update-------
        -- DECLARE @process    AS VARCHAR(MAX)
        -- DECLARE @data       AS NVARCHAR(MAX)
        -- DECLARE @otherData  NVARCHAR(MAX) = NULL
        -- DECLARE @NoSelect   BIT = 0
        -- SET @process = 'trackingno.update'
        -- SET @data    = NULL
        -- EXEC [AppsLCA].[dbo].[SP_UPDATE_PackedBoxes_TrackingNo] @process = 'trackingno.update', @data = NULL
    -------PRUEBA PARA trackingno.update-------

    DECLARE @message        VARCHAR(300)
    DECLARE @messageData    NVARCHAR(MAX)
    DECLARE @error          BIT
    DECLARE @result         NVARCHAR(MAX)

    SET @messageData = '[]'
    SET @result      = '[]'
    SET @error       = 1
    SET @message     = 'Error'

    BEGIN TRY

        ----------------------------------------------------
        --------------------trackingno.update-----------------
        ----------------------------------------------------
        IF @process = 'trackingno.update'
        BEGIN
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' - Iniciando proceso trackingno.update')

            DROP TABLE IF EXISTS #TB_TrackingUpd_PackedBoxes
            DROP TABLE IF EXISTS #TB_TrackingUpd_DistinctItemDetail
            DROP TABLE IF EXISTS #TB_TrackingUpd_DistinctItemDetail_Batch
            DROP TABLE IF EXISTS #TB_REMOTE_SHIPPERTRACKING_RAW
            DROP TABLE IF EXISTS #TB_REMOTE_SHIPPERTRACKING

            --------------------------------------------------------------------
            -- Step 1: Packed boxes (StatusID 75 = Shipped) shipped in the last
            --         7 days, with the ItemDetailID resolved from the PONumber
            --------------------------------------------------------------------
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' - Paso 1: obteniendo PackedBoxes candidatos (#TB_TrackingUpd_PackedBoxes)')

            SELECT DISTINCT
                 [PackedBoxID]   = PB.[PackedBoxID]
                ,[ItemDetailID]  = CASE
                                       WHEN OD.[PONumber] LIKE 'ORD-PO%' THEN
                                           NULL
                                       WHEN OD.[PONumber] LIKE 'ORD-%' AND ISNUMERIC(REPLACE(OD.[PONumber], 'ORD-', '')) = 1 THEN
                                           CAST(REPLACE(OD.[PONumber], 'ORD-', '') AS BIGINT)
                                       WHEN OD.[PONumber] LIKE 'ORD%' AND ISNUMERIC(OD.[Comments6]) = 1 THEN
                                           CAST(OD.[Comments6] AS BIGINT)
                                       ELSE
                                           NULL
                                   END
                ,[TrackingNo]    = PB.[BoxComments6]
                ,[DataTracking]  = CAST(NULL AS VARCHAR(MAX))
            INTO #TB_TrackingUpd_PackedBoxes
            FROM       (SELECT StatusID, StatusName FROM LCA.dbo.StatusNames WITH(NOLOCK) WHERE StatusID IN (75,27,25)) AS SNPB
            INNER JOIN  LCA.dbo.PackedBoxes     AS PB       WITH(NOLOCK) ON PB.[StatusID]  = SNPB.[StatusID]   AND PB.[OrderID]  IS NOT NULL
            LEFT JOIN   LCA.dbo.Shipments       AS SH       WITH(NOLOCK) ON SH.[ShipmentID] = PB.[ShipmentID]  
            LEFT JOIN   LCA.dbo.Orders          AS OD       WITH(NOLOCK) ON OD.[OrderID] = PB.[OrderID]
            WHERE (
                        (
                            SNPB.[StatusID] = 75
                            AND SH.[ShipDate]   > DATEADD(DAY, -7, CONVERT(DATE, GETDATE()))
                        )
                        OR
                        (
                            SNPB.[StatusID] IN (27,25)
                        )
                    )
                AND (
                            PB.[BoxComments6] IS NULL
                        OR
                            PB.[BoxComments6] = ''
                    )
                AND
                  (
                        CASE
                            WHEN OD.[PONumber] LIKE 'ORD-PO%' THEN
                                NULL
                            WHEN OD.[PONumber] LIKE 'ORD-%' AND ISNUMERIC(REPLACE(OD.[PONumber], 'ORD-', '')) = 1 THEN
                                CAST(REPLACE(OD.[PONumber], 'ORD-', '') AS BIGINT)
                            WHEN OD.[PONumber] LIKE 'ORD%' AND ISNUMERIC(OD.[Comments6]) = 1 THEN
                                CAST(OD.[Comments6] AS BIGINT)
                            ELSE
                                NULL
                        END
                  ) IS NOT NULL

            --------------------------------------------------------------------
            -- Step 2: TrackingNo remoto por ItemDetailID (BATCH OPENQUERY)
            -- Igual que el batch de #TB_BACKLOG_REMOTE_SHIPCOMPLETE de
            -- SP_Planning_BacklogUnits: se parte la lista de ItemDetailID en
            -- lotes para no saturar el linked server.
            --------------------------------------------------------------------
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' - Paso 2: preparando batches de ItemDetailID para OPENQUERY remoto')

            SELECT DISTINCT [ItemDetailID]
            INTO #TB_TrackingUpd_DistinctItemDetail
            FROM #TB_TrackingUpd_PackedBoxes
            WHERE [ItemDetailID] IS NOT NULL

            CREATE TABLE #TB_REMOTE_SHIPPERTRACKING_RAW
            (
                 [ItemDetailID] BIGINT       NULL
                ,[TrackingNo]   VARCHAR(200) NULL
            )

            -- ~300 * (10 digitos + coma) ~= 3300 caracteres, con margen de sobra bajo 8000
            DECLARE @BatchSize_TR      INT = 300
            DECLARE @BatchCount_TR     INT
            DECLARE @CurrentBatch_TR   INT = 1
            DECLARE @ItemDetailList_TR VARCHAR(MAX)
            DECLARE @SQL_FILTER_TR     NVARCHAR(MAX)

            SELECT
                 [ItemDetailID]
                ,[BatchNo] = ((ROW_NUMBER() OVER (ORDER BY [ItemDetailID]) - 1) / @BatchSize_TR) + 1
            INTO #TB_TrackingUpd_DistinctItemDetail_Batch
            FROM #TB_TrackingUpd_DistinctItemDetail

            SELECT @BatchCount_TR = MAX([BatchNo]) FROM #TB_TrackingUpd_DistinctItemDetail_Batch

            WHILE @CurrentBatch_TR <= ISNULL(@BatchCount_TR, 0)
            BEGIN
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' - Consultando linked server, batch ',@CurrentBatch_TR,' de ',@BatchCount_TR)

                SELECT @ItemDetailList_TR = STRING_AGG(CAST([ItemDetailID] AS VARCHAR(20)), ',')
                FROM #TB_TrackingUpd_DistinctItemDetail_Batch
                WHERE [BatchNo] = @CurrentBatch_TR

                SET @SQL_FILTER_TR = N'
                SELECT
                     [ItemDetailID]
                    ,[TrackingNo]
                FROM OPENQUERY([db1.legacycaps.com], ''
                    SELECT
                         [ItemDetailID]  = SD.ItemDetailID
                        ,[TrackingNo]    = TR1.TrackingNo
                    FROM Production.dbo.prod_ShipDetail         AS SD  WITH(NOLOCK)
                    LEFT JOIN  Production.dbo.prod_ShipTracking AS TR1 WITH(NOLOCK) ON SD.ShipperNo = TR1.ShipperNo
                    WHERE SD.ItemDetailID IN (' + @ItemDetailList_TR + N')
                '')'

                INSERT INTO #TB_REMOTE_SHIPPERTRACKING_RAW ([ItemDetailID], [TrackingNo])
                EXEC sp_executesql @SQL_FILTER_TR

                SET @CurrentBatch_TR = @CurrentBatch_TR + 1
            END

            -- Tabla final: 1 fila por ItemDetailID, con todos sus TrackingNo concatenados
            SELECT
                 [ItemDetailID]
                ,[TrackingNo] = STRING_AGG([TrackingNo], ', ') WITHIN GROUP (ORDER BY [TrackingNo])
            INTO #TB_REMOTE_SHIPPERTRACKING
            FROM (SELECT DISTINCT [ItemDetailID], [TrackingNo] FROM #TB_REMOTE_SHIPPERTRACKING_RAW WHERE [TrackingNo] IS NOT NULL) AS D
            GROUP BY [ItemDetailID]

            CREATE UNIQUE CLUSTERED INDEX IX_TB_REMOTE_SHIPPERTRACKING_ItemDetailID ON #TB_REMOTE_SHIPPERTRACKING([ItemDetailID])

            UPDATE DP SET
                [DataTracking] = RST.[TrackingNo]
            FROM #TB_TrackingUpd_PackedBoxes AS DP
            INNER JOIN #TB_REMOTE_SHIPPERTRACKING AS RST ON RST.[ItemDetailID] = DP.[ItemDetailID]

            --------------------------------------------------------------------
            -- Step 3: Stamp TrackingNo into LCA.dbo.PackedBoxes
            --------------------------------------------------------------------
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' - Paso 3: actualizando BoxComments6 en LCA.dbo.PackedBoxes')

            UPDATE S SET
                S.[BoxComments6] = LEFT(B.[DataTracking], 100)
            FROM #TB_TrackingUpd_PackedBoxes AS B
            INNER JOIN LCA.dbo.PackedBoxes AS S ON S.[PackedBoxID] = B.[PackedBoxID]
            WHERE B.[DataTracking] IS NOT NULL
              AND B.[DataTracking] <> ''

            SET @result = COALESCE
            (
                (
                    SELECT
                         [PackedBoxID] = B.[PackedBoxID]
                        ,[TrackingNo]  = LEFT(B.[DataTracking], 100)
                    FROM #TB_TrackingUpd_PackedBoxes AS B
                    WHERE B.[DataTracking] IS NOT NULL
                      AND B.[DataTracking] <> ''
                    ORDER BY B.[PackedBoxID]
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                )
               ,'[]'
            )

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' - Proceso trackingno.update finalizado correctamente')

            SET @error   = 0
            SET @message = 'Tracking numbers updated successfully.'
            GOTO END_OF_PROCEDURE
        END
        ----------------------------------------------------
        --------------------trackingno.update-----------------
        ----------------------------------------------------

        ELSE
        BEGIN
            SET @error   = 1
            SET @message = 'Unknown process: ' + ISNULL(@process, 'NULL')
        END

    END TRY
    BEGIN CATCH
        SET @message = 'Error in Database. Please contact IT.'
        SET @error   = 1
        SET @result  = '[]'
    END CATCH

END_OF_PROCEDURE:
    SET @otherData = (
        SELECT
             [Error]       = @error
            ,[message]     = @message
            ,[messageData] = JSON_QUERY(COALESCE(@messageData, '[]'))
            ,[Result]      = JSON_QUERY(@result)
        FOR JSON PATH, INCLUDE_NULL_VALUES
    )

    IF @NoSelect = 0
        SELECT @otherData

END
