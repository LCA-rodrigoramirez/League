USE AppsLCA;
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_SearchImportDeclaration_CommercialInvoice_Drawback]
     @process   AS NVARCHAR(MAX)
    ,@data      AS NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Component AS NVARCHAR(200)
    DECLARE @Error AS BIT
    DECLARE @message AS NVARCHAR(200)
    DECLARE @result AS NVARCHAR(MAX)

    -- DECLARE @process AS NVARCHAR(MAX)
    -- DECLARE @data AS NVARCHAR(MAX)

    --------------- PRUEBAS PROCEDIMIENTO ------------------
    -- SET @process = 'search.im'
    -- SET @data = '{
    --         "selectedOptions":[
    --                             {
    --                                 "Entry": "BHE04309981",
    --                                 "Waybills": ["AIR-APP-20251031","AIR-HW-20251031","AIR-HW-20251031-1"]
    --                             },
    --                             {
    --                                 "Entry": "BHE04208647",
    --                                 "Waybills": ["20240215-NONCAFTA"]
    --                             }
    --                         ]
    -- }'

    BEGIN TRY

        DROP TABLE IF EXISTS #EntryWaybill

        CREATE TABLE #EntryWaybill (
             Entry   NVARCHAR(100)
            ,Waybill NVARCHAR(100)
        )

        INSERT INTO #EntryWaybill (Entry, Waybill)
        SELECT
             e.Entry
            ,w.[value] AS Waybill
        FROM OPENJSON(@data, '$.selectedOptions')
        WITH (
             Entry    NVARCHAR(100)  '$.Entry'
            ,Waybills NVARCHAR(MAX)  '$.Waybills' AS JSON
        ) AS e
        CROSS APPLY OPENJSON(e.Waybills) AS w

        SET @result = (
            SELECT STRING_AGG(EntryBlock, CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)) WITHIN GROUP (ORDER BY Entry)
            FROM (
                SELECT
                     Entry
                    ,Entry + CHAR(13)+CHAR(10)
                        + STRING_AGG(WaybillBlock, CHAR(13)+CHAR(10)) WITHIN GROUP (ORDER BY Waybill) AS EntryBlock
                FROM (
                    SELECT
                         EW.[Entry]
                        ,EW.[Waybill]
                        ,EW.[Waybill] + CHAR(13)+CHAR(10)
                            + STRING_AGG(CI.[IM5], CHAR(13)+CHAR(10)) WITHIN GROUP (ORDER BY CI.[IM5]) AS WaybillBlock
                    FROM #EntryWaybill AS EW
                    INNER JOIN (
                        SELECT DISTINCT [Waybill], [IM5]
                        FROM [192.168.1.93].[AppsLCA].[dbo].[CI_import_export_DeclarationExport_Drawback] WITH(NOLOCK)
                    ) AS CI ON EW.[Waybill] = CI.[Waybill]
                    GROUP BY EW.[Entry], EW.[Waybill]
                ) AS WaybillBlocks
                GROUP BY Entry
            ) AS EntryBlocks
        )

        SET @Error = 0
        SET @Component = '[200]'
        SET @message = 'Datos obtenidos correctamente'

    END TRY
    BEGIN CATCH

        SET @Error = 1
        SET @result = '[]'
        SET @Component = '[404]'
        SET @message = 'Error in Database'

    END CATCH

    SELECT
         [Error]        = @Error
        ,[Component]    = @Component
        ,[Message]      = @message
        ,[ResultIM]     = @result
    FOR JSON PATH, INCLUDE_NULL_VALUES
END