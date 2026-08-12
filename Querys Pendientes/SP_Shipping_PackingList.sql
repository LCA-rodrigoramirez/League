USE AppsLCA;
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_Shipping_PackingSlip]
     @process   AS NVARCHAR(MAX)
    ,@data      AS NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Component AS NVARCHAR(200)
    DECLARE @Error AS BIT
    DECLARE @message AS NVARCHAR(200)
    DECLARE @result AS NVARCHAR(MAX)
    DECLARE @messageData AS NVARCHAR(MAX)

    -- DECLARE @process AS NVARCHAR(MAX)
    -- DECLARE @data AS NVARCHAR(MAX)
    DECLARE @DateFrom AS DATE
    DECLARE @DateTo AS DATE

    --------------- PRUEBAS PROCEDIMIENTO ------------------
    -- SET @process = 'export.dates'
    -- SET @data = '{
    --     "selectedDates":[
    --         {
    --              "DateFrom":"2026-08-04"
    --             ,"DateTo":"2026-08-04"
    --         }
    --     ]
    -- }'
    BEGIN TRY

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1. Sección de Eliminación de tablas temporales
        -------------------------------------------------------------------------------------------------------------------------------------------------------
            DROP TABLE IF EXISTS #TB_PL_RAW
        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1. Sección de Eliminación de tablas temporales
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        IF @process = 'export.dates'
        BEGIN
            SELECT
                @DateFrom = CAST(JSON_VALUE(@data, '$.selectedDates[0].DateFrom') AS DATE)
                ,@DateTo  = CAST(JSON_VALUE(@data, '$.selectedDates[0].DateTo')   AS DATE)

                SELECT
                        [Waybill]
                        ,[Skid]
                        ,[ItemCode]
                        ,[Style]
                        ,[Color]
                        ,[ColorGreatPlain]
                        ,[Size]
                        ,[Qty]
                        ,[XX]
                        ,[OrderNo]
                        ,[ItemDetailID]     =   CASE
                                                    WHEN [OrderNo] LIKE 'ORD-PO%' THEN NULL
                                                    WHEN [OrderNo] LIKE 'ORD-%'   THEN TRY_CAST(REPLACE([OrderNo], 'ORD-', '') AS BIGINT)
                                                    ELSE NULL
                                                END
                        ,[L2Order]
                        ,[CustomerOrder]    =  CASE WHEN ( [OrderNo] LIKE 'ORD%') AND CHARINDEX('-',L2Order) > 0 THEN SUBSTRING(L2Order,1,CHARINDEX('-',L2Order) -1) ELSE L2Order END
                        ,[Box]
                        ,[Fact]
                        ,[Gender]
                        ,[Location]
                        ,[Note]
                        ,[TrackingNumber]
                        ,[BoxNo]
                        ,[ColorPolyPM]
                        ,[Price]
                        ,[TotalPrices]
                        ,[InvoiceDate]
                        ,[HasTracking]      = CAST(NULL AS BIT)
                        ,[Comment]          = CAST(NULL AS VARCHAR(200))
                    INTO #TB_PL_RAW
                    FROM [LCA].[dboReaders].[VW_ImpExp_ShippingPackingSlip] WITH(NOLOCK)
                    WHERE [InvoiceDate] >= @DateFrom AND [InvoiceDate] <= @DateTo

                    CREATE NONCLUSTERED INDEX IX_PL_RAW ON #TB_PL_RAW ([Waybill],[ItemDetailID])


                    

                    UPDATE TPR SET
                        [HasTracking] = CASE
                                            WHEN [Location] LIKE '%Hanover%' AND ([TrackingNumber] IS NULL OR [TrackingNumber] = '') THEN 1
                                            WHEN [Location] = 'Account' AND [TrackingNumber] IS NOT NULL THEN 1
                                            ELSE 0
                                        END
                    FROM #TB_PL_RAW AS TPR

                    UPDATE TPR SET
                        [Comment] = CASE WHEN [HasTracking] = 0 AND [Location] = 'Account' THEN 'Work Order without TrackingNumber' ELSE '' END
                    FROM #TB_PL_RAW AS TPR
                    
                    -- SELECT * FROM #TB_PL_RAW 
                            
                    SET @result = (
                        SELECT 
                            [Waybill]
                            ,[Skid]
                            ,[ItemCode]
                            ,[Style]
                            ,[Color]
                            ,[ColorGreatPlain]
                            ,[Size]
                            ,[Qty]
                            ,[XX]
                            ,[OrderNo]
                            -- ,[ItemDetailID]         
                            ,[L2Order]
                            -- ,[CustomerOrder]  
                            ,[Box]
                            ,[Fact]
                            ,[Gender]
                            ,[Location]
                            ,[Note]
                            ,[TrackingNumber]
                            ,[BoxNo]
                            ,[ColorPolyPM]
                            ,[Price]
                            ,[TotalPrices]
                            ,[InvoiceDate]
                            -- ,[HasTracking]    
                            -- ,[Comment]        
                        FROM #TB_PL_RAW
                        ORDER BY [InvoiceDate] DESC, [Waybill]
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    )

                    SET @messageData = (
                        SELECT 
                            [Waybill]
                            ,[Skid]
                            ,[ItemCode]
                            ,[Style]
                            ,[Color]
                            ,[ColorGreatPlain]
                            ,[Size]
                            ,[Qty]
                            ,[XX]
                            ,[OrderNo]
                            -- ,[ItemDetailID]         
                            ,[L2Order]
                            -- ,[CustomerOrder]  
                            ,[Box]
                            ,[Fact]
                            ,[Gender]
                            ,[Location]
                            ,[Note]
                            ,[TrackingNumber]
                            ,[BoxNo]
                            ,[ColorPolyPM]
                            ,[Price]
                            ,[TotalPrices]
                            ,[InvoiceDate]
                            ,[HasTracking]    
                            ,[Comment]        
                        FROM #TB_PL_RAW
                        WHERE [Comment] <> ''
                        ORDER BY [InvoiceDate] DESC, [Waybill]
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    )
                    SET @Component = '[200]'
                    SET @Error = 0
                    SET @message = 'Datos obtenidos correctamente'

        END
    END TRY
    BEGIN CATCH

        SET @Error = 1
		SET @Component = '[' + CAST(ERROR_NUMBER() AS NVARCHAR(20)) + ']'
		SET @message = 'Line ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + ': ' + ERROR_MESSAGE()
        SET @messageData = '[]'
        SET @result = '[]'

    END CATCH

    SELECT
         [Component] 	= @Component 
        ,[Error]		= @Error
        ,[message]		= @message 
        ,[messageData]  = JSON_QUERY(@message)
        ,[Result]		= JSON_QUERY(@result)
    FOR JSON PATH, INCLUDE_NULL_VALUES

END