USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_ImportExport_GenerateCommercialInvoiceReport_PerWaybill]    Script Date: 12/12/2025 10:57:22 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_ImportExport_GenerateCommercialInvoiceReport_PerWaybill]
(
    @WayBill NVARCHAR(MAX)
)
AS
BEGIN
    SET NOCOUNT ON

    -- DECLARE @WayBill AS NVARCHAR(MAX) = 'AIR-APP-20260824'

    DECLARE @resultCommercial       AS NVARCHAR(MAX)
    DECLARE @result9802             AS NVARCHAR(MAX)
    DECLARE @resultSummaryKelly     AS NVARCHAR(MAX)
    DECLARE @resultCertification    AS NVARCHAR(MAX)

    DROP TABLE IF EXISTS #TB_NormalCI
    DROP TABLE IF EXISTS #TB_TransferCI
    DROP TABLE IF EXISTS #BaseSummary
    DROP TABLE IF EXISTS #TB_Cerification

    -------------------------------------------RESULT COMMERCIAL INVOICE CAFTA/NONCAFTA -------------------------------------

    -- SET @resultCommercial =
    --     (
    --         SELECT
    --              [R]                        = ROW_NUMBER() OVER(ORDER BY CI.[Orden], CI.[InvoicingDescription],CI.[CountryOfOrigin], CI.[Manufacturer])
    --             ,[WayBill]                  = CI.[WayBill]
    --             ,[ContainerNumber]          = CI.[Container]    
    --             ,[StyleNumber]              = CI.[StyleNumber]    
    --             ,[InvoicingDescription]     = CI.[InvoicingDescription]            
    --             ,[US_HTSDescription]        = CI.[US_HTSDescription]            
    --             ,[US_HTSCode]               = CI.[US_HTSCode]    
    --             ,[UnitPrice]                = CI.[Price]
    --             ,[ShipDate]                 = CI.[ShipDate]
    --             ,[Quantity]                 = SUM(CI.[Quantity])
    --             ,[TotalPrice]               = SUM(CI.[TotalPrice])
    --             ,[TotalFobValue]            = SUM(CI.[TotalFobValue])
    --             ,[MinBatch]                 = MIN(CI.[Batch])
    --             ,[WeightKg]                 = SUM(CI.[GrossWeightKGSXUnits])
    --             ,[MaxBatch]                 = MAX(CI.[Batch])
    --             ,[Cafta]                    = CI.[Cafta]
    --             ,[Pallets]                  = SUM(CASE WHEN CI.[GroupPallet] = 1 THEN 1 ELSE 0 END)
    --             ,[Boxes]                    = SUM(CASE WHEN CI.[GroupBox] = 1 THEN 1 ELSE 0 END)
    --             ,[Manufacturer]             = CI.[Manufacturer]    
    --             ,[CountryOfOrigin]          = CI.[CountryOfOrigin]        
    --             ,[Freight]                  = CI.[Freight]
    --             ,[Orden]                    = CI.[Orden]
    --             ,[DocumentID]               = CI.[DocumentID]
    --         FROM [192.168.1.93].appslca.dbo.CI_Import_Export_CommercialInvoice AS CI WITH(NOLOCK)
    --         WHERE Waybill IN (@WayBill)
    --         GROUP BY
    --             CI.[WayBill]
    --             ,CI.[Container]    
    --             ,CI.[StyleNumber]    
    --             ,CI.[InvoicingDescription]
    --             ,CI.[US_HTSDescription]   
    --             ,CI.[US_HTSCode]    
    --             ,CI.[Price]
    --             ,CI.[ShipDate]
    --             ,CI.[Cafta]
    --             ,CI.[Manufacturer]
    --             ,CI.[CountryOfOrigin]
    --             ,CI.[Freight]
    --             ,CI.[Orden]
    --             ,CI.[DocumentID]
    --         FOR JSON PATH, INCLUDE_NULL_VALUES
    --     ) 
        CREATE TABLE #TB_NormalCI(
             [R]                    INT
            ,[WayBill]              VARCHAR(200)
            ,[ContainerNumber]      VARCHAR(200)
            ,[StyleNumber]          VARCHAR(200)
            ,[InvoicingDescription] VARCHAR(200)
            ,[US_HTSDescription]    VARCHAR(200)
            ,[US_HTSCode]           VARCHAR(200)
            ,[UnitPrice]            DECIMAL(18,2)
            ,[ShipDate]             DATE
            ,[Quantity]             DECIMAL(18,2)
            ,[TotalPrice]           DECIMAL(18,2)
            ,[TotalBlankPrice]      DECIMAL(18,2)
            ,[TotalDecorationValue] DECIMAL(18,2)
            ,[TotalFobValue]        DECIMAL(18,2)
            ,[MinBatch]             VARCHAR(200)
            ,[WeightKg]             DECIMAL(18,2)
            ,[MaxBatch]             VARCHAR(200)
            ,[Cafta]                VARCHAR(200)
            ,[Pallets]              INT
            ,[Boxes]                INT
            ,[Manufacturer]         VARCHAR(200)
            ,[CountryOfOrigin]      VARCHAR(200)
            ,[Freight]              DECIMAL(18,2)
            ,[Orden]                INT
            ,[DocumentID]           VARCHAR(200)
            ,[InvoicingGroupKelly]    VARCHAR(200)
            ,[ManufacturerGroupKelly]   VARCHAR(200)
            ,[LineGroupKelly]       INT

        )

        INSERT INTO #TB_NormalCI
        SELECT
             [R]                        = ROW_NUMBER() OVER(ORDER BY CI.[Orden], CI.[InvoicingDescription],CI.[CountryOfOrigin], CI.[Manufacturer])
            ,[WayBill]                  = CI.[WayBill]
            ,[ContainerNumber]          = CI.[Container]    
            ,[StyleNumber]              = CI.[StyleNumber]
            ,[InvoicingDescription]     = CI.[InvoicingDescription]            
            ,[US_HTSDescription]        = CI.[US_HTSDescription]            
            ,[US_HTSCode]               = COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
            ,[UnitPrice]                = CI.[Price]
            ,[ShipDate]                 = CI.[ShipDate]
            ,[Quantity]                 = SUM(CI.[Quantity])
            ,[TotalPrice]               = SUM(CI.[TotalPrice])
            ,[TotalBlankPrice]          = SUM(CI.[TotalBlankPrice])
            ,[TotalDecorationValue]     = SUM(CI.[TotalDecorationValue])
            ,[TotalFobValue]            = SUM(CI.[TotalFobValue])
            ,[MinBatch]                 = MIN(CI.[Batch])
            ,[WeightKg]                 = SUM(CI.[GrossWeightKGSXUnits])
            ,[MaxBatch]                 = MAX(CI.[Batch])
            ,[Cafta]                    = CI.[Cafta]
            ,[Pallets]                  = SUM(CASE WHEN CI.[GroupPallet] = 1 THEN 1 ELSE 0 END)
            ,[Boxes]                    = SUM(CASE WHEN CI.[GroupBox] = 1 THEN 1 ELSE 0 END)
            ,[Manufacturer]             = CI.[Manufacturer]    
            ,[CountryOfOrigin]          = CI.[CountryOfOrigin]        
            ,[Freight]                  = CI.[Freight]
            ,[Orden]                    = CI.[Orden]
            ,[DocumentID]               = CI.[DocumentID]
            ,[InvoicingGroupKelly]      = CI.[InvoicingGroupKelly]
            ,[ManufacturerGroupKelly]   = CI.[ManufacturerGroupKelly]
            ,[LineGroupKelly]           = CI.[LineGroupKelly]
        FROM [192.168.1.93].appslca.dbo.CI_Import_Export_CommercialInvoice AS CI WITH(NOLOCK)
        WHERE Waybill IN (@WayBill)
        GROUP BY
            CI.[WayBill]
            ,CI.[Container]    
            ,CI.[StyleNumber]    
            ,CI.[InvoicingDescription]
            ,CI.[US_HTSDescription]   
            ,COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
            ,CI.[Price]
            ,CI.[ShipDate]
            ,CI.[Cafta]
            ,CI.[Manufacturer]
            ,CI.[CountryOfOrigin]
            ,CI.[Freight]
            ,CI.[Orden]
            ,CI.[DocumentID]
            ,CI.[InvoicingGroupKelly]
            ,CI.[ManufacturerGroupKelly]
            ,CI.[LineGroupKelly]

        INSERT INTO #TB_NormalCI
        (
             R
            ,DocumentID
            ,Orden
            ,StyleNumber
            ,US_HTSCode
            ,InvoicingGroupKelly
            ,[CountryOfOrigin]
            ,[Manufacturer]
            ,ManufacturerGroupKelly
            ,LineGroupKelly
            ,Quantity
            ,TotalPrice
            ,[TotalBlankPrice]     
            ,[TotalDecorationValue]
            ,TotalFobValue
        )
        SELECT
            [R] = MAX([R]) + 1  -- Para quedar justo debajo del último del mismo DocumentID
            , [DocumentID]
            , [Orden]
            , [Style] = 'TOTAL'
            , [US_HTSCode]
            , [InvoicingGroupKelly]
            , [CountryOfOrigin]
            , [Manufacturer]
            , [ManufacturerGroupKelly]
            , [LineGroupKelly]
            , SUM([Quantity])
            , SUM([TotalPrice])
            , SUM([TotalBlankPrice])
            , SUM([TotalDecorationValue])
            , SUM([TotalFobValue])
        FROM #TB_NormalCI
        GROUP BY 
              [DocumentID]
            , [Orden]
            , [US_HTSCode]
            , [CountryOfOrigin]
            , [Manufacturer]
            , [InvoicingGroupKelly]
            , [ManufacturerGroupKelly]
            , [LineGroupKelly]
            
         SET @resultCommercial = (
            SELECT * 
            FROM #TB_NormalCI
            ORDER BY Orden,LineGroupKelly,R
            FOR JSON PATH, INCLUDE_NULL_VALUES
         )   

    -------------------------------------------RESULT COMMERCIAL INVOICE CAFTA/NONCAFTA -------------------------------------

    -------------------------------------------RESULT COMMERCIAL INVOICE 9802 -------------------------------------
        -- SET @result9802 =
        -- (
        --     SELECT
        --          [R]                        = ROW_NUMBER() OVER(ORDER BY DE.[Orden], DE.[InvoicingDescription],DE.[CountryOfOrigin], DE.[Manufacturer])
        --         ,[WayBill]                  = DE.[WayBill]
        --         ,[ContainerNumber]          = DE.[Container]    
        --         ,[StyleNumber]              = DE.[StyleNumber]    
        --         ,[InvoicingDescription]     = DE.[InvoicingDescription]            
        --         ,[US_HTSDescription]        = DE.[US_HTSDescription]            
        --         ,[US_HTSCode]               = DE.[US_HTSCode]    
        --         ,[UnitPrice]                = DE.[Price]
        --         ,[ShipDate]                 = DE.[ShipDate]
        --         ,[Quantity]                 = SUM(DE.[Quantity])
        --         ,[TotalPrice]               = SUM(DE.[TotalPrice])
        --         ,[TotalFobValue]            = SUM(DE.[TotalFobValue])
        --         ,[MinBatch]                 = MIN(DE.[Batch])
        --         ,[WeightKg]                 = SUM(DE.[GrossWeightKGSXUnits])
        --         ,[MaxBatch]                 = MAX(DE.[Batch])
        --         ,[Cafta]                    = DE.[Cafta]
        --         ,[Pallets]                  = SUM(CASE WHEN DE.[GroupPallet] = 1 THEN 1 ELSE 0 END)
        --         ,[Boxes]                    = SUM(CASE WHEN DE.[GroupBox] = 1 THEN 1 ELSE 0 END)
        --         ,[Manufacturer]             = DE.[Manufacturer]    
        --         ,[CountryOfOrigin]          = DE.[CountryOfOrigin]        
        --         ,[IM5]                      = DE.[IM5]
        --         ,[DeclarationDate]          = DE.[DeclarationDate]
        --         ,[ArrivalDate]              = DE.[ArrivalDate]
        --         ,[DepartureDate]            = DE.[DepartureDate]
        --         ,[PortOfLoading]            = DE.[PortOfLoading]
        --         ,[DecorationDesc]           = DE.[DecorationDesc]
        --         ,[DecorationValue]          = SUM(DE.[TotalDecorationValue])
        --         ,[Orden]                    = DE.[Orden]
        --         ,[DocumentID]               = DE.[DocumentID]
        --     FROM [192.168.1.93].AppsLCA.dbo.CI_Import_Export_DeclarationExport AS DE
        --     WHERE Waybill IN (@WayBill)
        --     GROUP BY
        --         DE.[WayBill]
        --         ,DE.[Container]    
        --         ,DE.[StyleNumber]    
        --         ,DE.[InvoicingDescription]
        --         ,DE.[US_HTSDescription]   
        --         ,DE.[US_HTSCode]    
        --         ,DE.[Price]
        --         ,DE.[ShipDate]
        --         ,DE.[Cafta]
        --         ,DE.[Manufacturer]   
        --         ,DE.[CountryOfOrigin]
        --         ,DE.[IM5]
        --         ,DE.[DeclarationDate]
        --         ,DE.[ArrivalDate]
        --         ,DE.[DepartureDate]
        --         ,DE.[PortOfLoading]
        --         ,DE.[DecorationDesc]
        --         ,DE.[Orden]
        --         ,DE.[DocumentID]
        --         FOR JSON PATH, INCLUDE_NULL_VALUES
        -- );

        CREATE TABLE #TB_TransferCI(
             [R]                        INT
            ,[WayBill]                  VARCHAR(200)
            ,[ContainerNumber]          VARCHAR(200)
            ,[StyleNumber]              VARCHAR(200)
            ,[InvoicingDescription]     VARCHAR(200)
            ,[US_HTSDescription]        VARCHAR(200)
            ,[US_HTSCode]               VARCHAR(200)
            ,[UnitPrice]                DECIMAL(18,2)
            ,[ShipDate]                 DATE
            ,[Quantity]                 DECIMAL(18,2)
            ,[TotalPrice]               DECIMAL(18,2)
            ,[TotalBlankPrice]          DECIMAL(18,2)
            ,[TotalFobValue]            DECIMAL(18,2)
            ,[MinBatch]                 VARCHAR(200)
            ,[WeightKg]                 DECIMAL(18,2)
            ,[MaxBatch]                 VARCHAR(200)
            ,[Cafta]                    VARCHAR(200)
            ,[Pallets]                  INT
            ,[Boxes]                    INT
            ,[Manufacturer]             VARCHAR(200)
            ,[CountryOfOrigin]          VARCHAR(200)
            ,[IM5]                      VARCHAR(200)
            ,[DeclarationDate]          DATE
            ,[ArrivalDate]              DATE
            ,[DepartureDate]            DATE
            ,[PortOfLoading]            VARCHAR(200)
            ,[DecorationDesc]           VARCHAR(200)
            ,[DecorationValue]          DECIMAL(18,2)
            ,[Orden]                    INT
            ,[DocumentID]               VARCHAR(200)
            ,[InvoicingGroupKelly]      VARCHAR(200)
            ,[ManufacturerGroupKelly]   VARCHAR(200)
            ,[LineGroupKelly]           INT

        )

        INSERT INTO #TB_TransferCI
        SELECT
             [R]                        = ROW_NUMBER() OVER(ORDER BY DE.[Orden], DE.[InvoicingDescription],DE.[CountryOfOrigin], DE.[Manufacturer])
            ,[WayBill]                  = DE.[WayBill]
            ,[ContainerNumber]          = DE.[Container]    
            ,[StyleNumber]              = DE.[StyleNumber]    
            ,[InvoicingDescription]     = DE.[InvoicingDescription]            
            ,[US_HTSDescription]        = DE.[US_HTSDescription]            
            ,[US_HTSCode]               = COALESCE(DE.[US_HTSCode2],DE.[US_HTSCode])
            ,[UnitPrice]                = DE.[Price]
            ,[ShipDate]                 = DE.[ShipDate]
            ,[Quantity]                 = SUM(DE.[Quantity])
            ,[TotalPrice]               = SUM(DE.[TotalPrice])
            ,[TotalBlankPrice]          = SUM(DE.[TotalBlankPrice])
            ,[TotalFobValue]            = SUM(DE.[TotalFobValue])
            ,[MinBatch]                 = MIN(DE.[Batch])
            ,[WeightKg]                 = SUM(DE.[GrossWeightKGSXUnits])
            ,[MaxBatch]                 = MAX(DE.[Batch])
            ,[Cafta]                    = DE.[Cafta]
            ,[Pallets]                  = SUM(CASE WHEN DE.[GroupPallet] = 1 THEN 1 ELSE 0 END)
            ,[Boxes]                    = SUM(CASE WHEN DE.[GroupBox] = 1 THEN 1 ELSE 0 END)
            ,[Manufacturer]             = DE.[Manufacturer]    
            ,[CountryOfOrigin]          = DE.[CountryOfOrigin]        
            ,[IM5]                      = DE.[IM5]
            ,[DeclarationDate]          = DE.[DeclarationDate]
            ,[ArrivalDate]              = DE.[ArrivalDate]
            ,[DepartureDate]            = DE.[DepartureDate]
            ,[PortOfLoading]            = DE.[PortOfLoading]
            ,[DecorationDesc]           = DE.[DecorationDesc]
            ,[DecorationValue]          = SUM(DE.[TotalDecorationValue])
            ,[Orden]                    = DE.[Orden]
            ,[DocumentID]               = DE.[DocumentID]
            ,[InvoicingGroupKelly]      = DE.[InvoicingGroupKelly]    
            ,[ManufacturerGroupKelly]   = DE.[ManufacturerGroupKelly]
            ,[LineGroupKelly]           = DE.[LineGroupKelly]        
        FROM [192.168.1.93].AppsLCA.dbo.CI_Import_Export_DeclarationExport AS DE
        WHERE Waybill IN (@WayBill)
        GROUP BY
            DE.[WayBill]
            ,DE.[Container]    
            ,DE.[StyleNumber]    
            ,DE.[InvoicingDescription]
            ,DE.[US_HTSDescription]   
            ,COALESCE(DE.[US_HTSCode2],DE.[US_HTSCode])
            ,DE.[Price]
            ,DE.[ShipDate]
            ,DE.[Cafta]
            ,DE.[Manufacturer]   
            ,DE.[CountryOfOrigin]
            ,DE.[IM5]
            ,DE.[DeclarationDate]
            ,DE.[ArrivalDate]
            ,DE.[DepartureDate]
            ,DE.[PortOfLoading]
            ,DE.[DecorationDesc]
            ,DE.[Orden]
            ,DE.[DocumentID]
            ,DE.[InvoicingGroupKelly]   
            ,DE.[ManufacturerGroupKelly]
            ,DE.[LineGroupKelly]        

        INSERT INTO #TB_TransferCI
        (
             R
            ,DocumentID
            ,Orden
            ,StyleNumber
            ,US_HTSCode
            ,InvoicingGroupKelly
            ,[CountryOfOrigin]
            ,[Manufacturer]
            ,ManufacturerGroupKelly
            ,LineGroupKelly
            ,Quantity
            ,TotalPrice
            ,TotalBlankPrice
            ,DecorationValue
            ,TotalFobValue
        )
        SELECT
            [R] = MAX([R]) + 1  -- Para quedar justo debajo del último del mismo DocumentID
            , [DocumentID]
            , [Orden]
            , [Style] = 'TOTAL'
            , [US_HTSCode]
            , [InvoicingGroupKelly]
            , [CountryOfOrigin]
            , [Manufacturer]
            , [ManufacturerGroupKelly]
            , [LineGroupKelly]
            , SUM([Quantity])
            , SUM([TotalPrice])
            , SUM([TotalBlankPrice])
            , SUM([DecorationValue])
            , SUM([TotalFobValue])
        FROM #TB_TransferCI
        GROUP BY 
              [DocumentID]
            , [Orden]
            , [US_HTSCode]
            , [InvoicingGroupKelly]
            , [CountryOfOrigin]
            , [Manufacturer]
            , [ManufacturerGroupKelly]
            , [LineGroupKelly]

        SET @result9802 = (
            SELECT * 
            FROM #TB_TransferCI
            ORDER BY LineGroupKelly, R
            FOR JSON PATH, INCLUDE_NULL_VALUES
         )   
    -------------------------------------------RESULT COMMERCIAL INVOICE 9802 -------------------------------------

    -------------------------------------------RESULT SUMMARY KELLY GLOBAL -------------------------------------

        CREATE TABLE #BaseSummary
        (
            [R] INT
            , [Line] INT
            , [DocumentID] NVARCHAR(200)
            , [StyleNumber] NVARCHAR(200)
            , [InvoicingDescription] NVARCHAR(500)
            , [US_HTSCode] NVARCHAR(100)
            , [Manufacturer] NVARCHAR(300)
            , [Orden] INT
            , [Quantity] DECIMAL(18,2)
            , [QuantityDoz] DECIMAL(18,2)
            , [TotalPrice] DECIMAL(18,4)
            , [TotalBlankPrice] DECIMAL(18,4)
            , [TotalFobValue] DECIMAL(18,4)
            , [DecorationValue] DECIMAL(18,4)
        );

        -------------------------------- INSERT DE LÍNEAS NORMALES --------------------------------

        INSERT INTO #BaseSummary
        (
            [R], [Line], [DocumentID], [StyleNumber], [InvoicingDescription], [US_HTSCode], [Manufacturer],
            [Orden], [Quantity], [QuantityDoz], [TotalPrice], [TotalBlankPrice], [TotalFobValue], [DecorationValue]
        )
        SELECT 
            [R] = ROW_NUMBER() OVER(ORDER BY TB.[R_Order],TB.[Line] , TB.[InvoicingDescription], TB.[Manufacturer])
            , [Line] = TB.[Line]
            , TB.[DocumentID]
            , TB.[StyleNumber]
            , TB.[InvoicingDescription]
            , TB.[US_HTSCode]
            , TB.[Manufacturer]
            , TB.[Orden]
            , TB.[Quantity]
            , TB.[QuantityDoz]
            , TB.[TotalPrice]
            , TB.[TotalBlankPrice]
            , TB.[TotalFobValue]
            , TB.[DecorationValue]
        FROM
        (
            SELECT
                [R_Order] = CI.[Orden]  -- SOLO PARA ORDEN GLOBAL, NO ES Line
                , [Line]                 = CI.[LineGroupKelly]
                , [DocumentID]           = CI.[DocumentID]  
                , [StyleNumber]          = CI.[StyleNumber]
                , [InvoicingDescription] = CI.[InvoicingDescription]            
                , [US_HTSCode]           = COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
                , [Manufacturer]         = CONCAT(CI.[Manufacturer], '/', CI.[CountryOfOrigin])
                , [Orden]                = CI.[Orden]
                , [Quantity]             = SUM(CI.[Quantity])
                , [QuantityDoz]          = IIF(SUM(CI.[Quantity] / 12) < 1,ROUND(CEILING(SUM(CI.[Quantity]) / 12),0),ROUND(SUM(CI.[Quantity]) / 12, 0))
                , [TotalPrice]           = SUM(CI.[TotalPrice])
                , [TotalBlankPrice]      = SUM(CI.[TotalBlankPrice])
                , [TotalFobValue]        = SUM(CI.[TotalFobValue])
                , [DecorationValue]      = SUM(CI.[TotalDecorationValue])
            FROM [192.168.1.93].appslca.dbo.CI_Import_Export_CommercialInvoice AS CI WITH(NOLOCK)
            WHERE CI.[Waybill] IN (@WayBill)
            GROUP BY  
                  CI.[LineGroupKelly]
                , CI.[DocumentID]
                , CI.[StyleNumber]
                , CI.[InvoicingDescription]
                , COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
                , CONCAT(CI.[Manufacturer], '/', CI.[CountryOfOrigin])
                , CI.[Orden]

            UNION ALL

            SELECT
                [R_Order] = CI.[Orden]
                , [Line]                 = CI.[LineGroupKelly]
                , [DocumentID]           = CI.[DocumentID]
                , [StyleNumber]          = CI.[StyleNumber]
                , [InvoicingDescription] = CI.[InvoicingDescription]            
                , [US_HTSCode]           = COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])    
                , [Manufacturer]         = CONCAT(CI.[Manufacturer], '/', CI.[CountryOfOrigin])
                , [Orden]                = CI.[Orden]   
                , [Quantity]             = SUM(CI.[Quantity])
                , [QuantityDoz]          = ROUND(SUM(CI.[Quantity]) / 12, 0)
                , [TotalPrice]           = SUM(CI.[TotalPrice])
                , [TotalBlankPrice]      = SUM(CI.[TotalBlankPrice])
                , [TotalFobValue]        = SUM(CI.[TotalFobValue])
                , [DecorationValue]      = SUM(CI.[TotalDecorationValue])
            FROM [192.168.1.93].appslca.dbo.CI_Import_Export_DeclarationExport AS CI WITH(NOLOCK)
            WHERE CI.[Waybill] IN (@WayBill)
            GROUP BY
                  CI.[LineGroupKelly]
                , CI.[DocumentID]
                , CI.[StyleNumber]
                , CI.[InvoicingDescription]
                , COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
                , CONCAT(CI.[Manufacturer], '/', CI.[CountryOfOrigin])
                , CI.[Orden]
        ) AS TB;

        


        -------------------------------- INSERT DE TOTALES POR CADA DOCUMENTID --------------------------------

        INSERT INTO #BaseSummary
        (
            [R], [Line], [DocumentID], [StyleNumber], [InvoicingDescription], [US_HTSCode], [Manufacturer],
            [Orden], [Quantity], [QuantityDoz], [TotalPrice], [TotalBlankPrice], [TotalFobValue], [DecorationValue]
        )
        SELECT
            [R] = MAX([R]) + 1  -- Para quedar justo debajo del último del mismo DocumentID
            , [Line] = NULL -- correlativo interno
            , [DocumentID]
            , [StyleNumber] = NULL
            , [InvoicingDescription] = NULL
            , [US_HTSCode] = 'TOTAL INVOICE'
            , [Manufacturer] = NULL
            , [Orden]
            , SUM([Quantity])
            , SUM([QuantityDoz])
            , SUM([TotalPrice])
            , SUM([TotalBlankPrice])
            , SUM([TotalFobValue])
            , SUM([DecorationValue])
        FROM #BaseSummary
        GROUP BY [DocumentID],[Orden];
        -------------------------------- GENERAR JSON FINAL --------------------------------

        SET @resultSummaryKelly = (
            SELECT *
            FROM #BaseSummary
            ORDER BY [R], Line   -- El total queda justo debajo
            FOR JSON PATH, INCLUDE_NULL_VALUES
        );

    -------------------------------------------RESULT SUMMARY KELLY GLOBAL -------------------------------------

        SELECT
             [DocumentID]           = [DocumentID]
            ,[StyleNumber]          = [StyleNumber]
            ,[IDVersion]            = [IDVersion]
            ,[CertifyID]            = [CertifyID]
            -- ,[FabricConstruction]   = [FabricConstruction]
            ,[WayBill]              = [WayBill]
            ,[Manufacturer]         = IIF([Manufacturer] = 'League LTDA', 'League C.A Ltda. de C.V',[Manufacturer])
            ,[CommentVersion1]      = CAST(NULL AS VARCHAR(500))
            ,[CommentVersion2]      = CAST(NULL AS VARCHAR(500))
        INTO #TB_Cerification
        FROM [192.168.1.93].AppsLCA.dbo.CI_Import_Export_CertificationStyle WITH(NOLOCK)
        WHERE Waybill = @WayBill
        GROUP BY
             [DocumentID]
            ,[StyleNumber]
            ,[IDVersion]
            ,[CertifyID]
            -- ,[FabricConstruction]
            ,[WayBill]
            ,[Manufacturer]

        UPDATE TC SET
            [CommentVersion1] = IIF((SELECT COUNT(*) FROM #TB_Cerification WHERE IDVersion = '16CFR § 1610.1(d)(1)') > 0
                                , '16CFR § 1610.1(d)(1): The adult wearing apparel covered by this commercial invoice is exempt from flammability testing pursuant to 16 CFR § 1610.1(d)(1), as the garments are manufactured from plain surface fabrics weighing 2.6 ounces per square yard (88.2 g/m²) or greater.'
                                , '')

            ,[CommentVersion2] = IIF((SELECT COUNT(*) FROM #TB_Cerification WHERE IDVersion = '16CFR § 1610.1(d)(2)') > 0
                                , '16CFR § 1610.1(d)(2): The adult wearing apparel covered by this commercial invoice is exempt from flammability testing pursuant to 16 CFR § 1610.1(d)(2), as the garments are manufactured entirely from exempt fibers (acrylic, modacrylic, nylon, olefin, polyester, wool, or a combination thereof).'
                                , '')
        FROM #TB_Cerification AS TC

        SET @resultCertification = (

            SELECT
                 [ReportHeader] = (

                                    SELECT
                                         [DocumentID]
                                        ,[CommentReport]   = 'See below the list of styles along with their corresponding certificates, waybill: ' + @WayBill + '.'
                                        ,[CommentVersion1]
                                        ,[CommentVersion2]
                                        ,[WayBill]
                                    FROM #TB_Cerification
                                    GROUP BY 
                                         [DocumentID]
                                        ,[WayBill]
                                        ,[CommentVersion1]
                                        ,[CommentVersion2]
                                    FOR JSON PATH, INCLUDE_NULL_VALUES

                                  )

                ,[ReportData]   = (
                                    SELECT
                                         [StyleNumber]
                                        ,[IDVersion]            = CASE
                                                                    WHEN [IDVersion] = '16CFR § 1610.1(d)(1)' THEN CONCAT([IDVersion],'*')
                                                                    WHEN [IDVersion] = '16CFR § 1610.1(d)(2)' THEN CONCAT([IDVersion],'*')
                                                                  ELSE [IDVersion]
                                                                  END
                                        ,[CertifyID]
                                        -- ,[FabricConstruction]
                                        ,[Manufacturer]
                                    FROM #TB_Cerification
                                    ORDER BY StyleNumber
                                    FOR JSON PATH, INCLUDE_NULL_VALUES
                                  )
            FOR JSON PATH, INCLUDE_NULL_VALUES
        )

    ------------------------------------------- RESULT STYLE CERTIFICATION -------------------------------------

        

    -- SELECT * FROM AppsLCA.dbo.CertificationStylesID WHERE StyleNumber  = '31014' AND IdVersion IS NOT NULL
    -- SELECT CI.*
    -- FROM [192.168.1.93].appslca.dbo.CI_Import_Export_CommercialInvoice AS CI WITH(NOLOCK) 
    -- INNER JOIN LCA.dbo.ManufactureOrders AS MO WITH(NOLOCK) ON COALESCE(CI.[RO_ID], CI.[ManufactureID]) = MO.[ManufactureID]
    -- INNER JOIN LCA.dbo.OrderItems        AS OI WITH(NOLOCK) ON OI.[OrderItemID]     = MO.[FirstOrderItemID]
    -- WHERE StyleNumber  = '31014' AND Waybill = 'APP-20260818'
    
    -- SELECT * FROM [192.168.1.93].[AppsLCA].dbo.CertificationStylesID WHERE StyleNumber = '31014' AND IdVersion = 'D300303D'
    ------------------------------------------- RESULT STYLE CERTIFICATION -------------------------------------



    SELECT 
        [Commercial]    = JSON_QUERY(ISNULL(@resultCommercial,'[]'))
       ,[Transfer]      = JSON_QUERY(ISNULL(@result9802,'[]'))
       ,[Summary]       = JSON_QUERY(ISNULL(@resultSummaryKelly,'[]'))
       ,[Certification] = JSON_QUERY(ISNULL(@resultCertification,'[]'))
    FOR JSON PATH

END