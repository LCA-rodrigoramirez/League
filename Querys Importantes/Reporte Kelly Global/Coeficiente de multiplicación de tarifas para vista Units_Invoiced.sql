USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_Planning_BacklogUnits]    Script Date: 21/07/2026 07:31:54 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
                                                                                                                                  
CREATE PROCEDURE [dbo].[SP_UpdateTariffs_UnitsInvoiced]
     @entry VARCHAR(200)
AS

BEGIN

    SET NOCOUNT ON;


    -- DECLARE @entry VARCHAR(200)
    -- SET @entry = 'BHE0433894'
    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 1. Sección de Eliminación de tablas temporales
    -------------------------------------------------------------------------------------------------------------------------------------------------------

        DROP TABLE IF EXISTS #TB_Entry_Kelly
        DROP TABLE IF EXISTS #TB_CommercialInvoice
        DROP TABLE IF EXISTS #PIV_EntryKelly
        DROP TABLE IF EXISTS #TB_Units_Invoiced

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 1. Sección de Eliminación de tablas temporales
    -------------------------------------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 2. Información del Entry
    -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2.1. Llenando tabla general obteniendo Entry, Invoice, clasificación de tarifas y valores ingresados por KGL
        -------------------------------------------------------------------------------------------------------------------------------------------------------
            
            select 
                RIGHT(
                        ei.invoice_code,
                        LEN(ei.invoice_code) - CHARINDEX('/', ei.invoice_code)
                        ) as invoice
                ,el.htsus
                ,CAST(line_num as INT) as line_num
                ,CAST(NULL as INT) as [line]
                ,COALESCE(tc.Tarifa,'HTS') AS Tarifa
                ,el.[description]
                ,el.rate
                ,ed.entry_number
                ,CAST(ed.entry_date AS DATE) AS entry_date
                ,sum(el.entered_value) as entered_value
                ,sum(el.duty) as Duty_Entry
            into #TB_Entry_Kelly
            --SELECT *, CAST(ed.entry_date as DATE)
            from AppsLCA.dbo.entry_lines as el with(nolock)
            inner join AppsLCA.dbo.entry_invoices as ei with(nolock)
                ON el.invoice_id = ei.id
            inner join AppsLCA.dbo.entry_documents as ed with(nolock)
                ON ei.document_id = ed.id
            left join AppsLCA.dbo.TB_Transfer_KellyTariffCodes as tc with(nolock)
                ON tc.Codigo = REPLACE(el.htsus,'.','')
            WHERE el.duty IS NOT NULL AND el.htsus IS NOT NULL 
            -- AND entry_number = @entry
            group by
                RIGHT(
                    ei.invoice_code,
                    LEN(ei.invoice_code) - CHARINDEX('/', ei.invoice_code)
                    )
                ,el.htsus
                ,CAST(line_num as INT)
                ,tc.Tarifa
                ,el.[description]
                ,el.rate
                ,ed.entry_number
                ,CAST(ed.entry_date AS DATE)
                -- ,el.entered_value
            ORDER BY invoice
        
        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2.1. Llenando tabla general obteniendo Entry, Invoice, clasificación de tarifas y valores ingresados por KGL
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2.2. Update de [line] que será una correlativo de número de línea por cada Invoice, importante para comparar con CI
        -------------------------------------------------------------------------------------------------------------------------------------------------------

            UPDATE TEK SET
                [line] = LI.[line]
            FROM #TB_Entry_Kelly AS TEK
            INNER JOIN
            (
                SELECT
                    [invoice]  = [invoice]
                    ,[line_num] = [line_num]
                    ,[line]     = ROW_NUMBER() OVER(PARTITION BY [invoice] ORDER BY [invoice], [line_num])
                FROM #TB_Entry_Kelly
                WHERE Tarifa = 'HTS'
            ) AS LI ON TEK.[invoice] = LI.[invoice] AND TEK.[line_num] = LI.[line_num]

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2.2. Update de [line] que será una correlativo de número de línea por cada Invoice, importante para comparar con CI
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2.3. Creacion de Pivote por cada tarifa distinta que tenemos hasta el momento (122, 301 China, Recip, Fenta y HTS)
        -------------------------------------------------------------------------------------------------------------------------------------------------------

            SELECT
                [invoice]
                ,[line]
                ,[Tariff 122]
                ,[301 China]
                ,[Reciprocal]
                ,[Fentanylo]
                ,[HTS]
            INTO #PIV_EntryKelly
            FROM
            (
                SELECT invoice, Duty_Entry, Tarifa, htsus, line_num, [line]
                FROM #TB_Entry_Kelly 
                -- WHERE Tarifa <> 'HTS'
            ) AS origen
            PIVOT
            (
                SUM(Duty_Entry)
                FOR Tarifa IN ([Tariff 122], [301 China], [Reciprocal], [Fentanylo], [HTS])
            ) AS pivote;

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2.3. Creacion de Pivote por cada tarifa distinta que tenemos hasta el momento (122, 301 China, Recip, Fenta y HTS)
        -------------------------------------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 2. Información del Entry
    -------------------------------------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 3. Información del Commercial Invoice
    -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 3.1. Llenando tabla del Commercial para obtener la Línea y DocumentID que separamos y declaramos en el Summary y así comparar con Entry de KGL
        -------------------------------------------------------------------------------------------------------------------------------------------------------

            SELECT 
                [R] = ROW_NUMBER() OVER(ORDER BY TB.[R_Order],TB.[Line] , TB.[InvoicingDescription], TB.[Manufacturer])
                , [Line] = TB.[Line]
                , TB.[DocumentID]
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
                , TB.[TariffCategory]
                , TB.[Waybill]
            INTO #TB_CommercialInvoice
            FROM
            (
                SELECT
                    [R_Order] = CI.[Orden]  -- SOLO PARA ORDEN GLOBAL, NO ES Line
                    , [Line]                 = CI.[LineGroupKelly]
                    , [DocumentID]           = CI.[DocumentID]  
                    , [InvoicingDescription] = CI.[InvoicingGroupKelly]                
                    , [US_HTSCode]           = COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
                    , [Manufacturer]         = CONCAT(CI.[Manufacturer], '/', CI.[CountryOfOrigin])
                    , [Orden]                = CI.[Orden]
                    , [Quantity]             = SUM(CI.[Quantity])
                    , [QuantityDoz]          = IIF(SUM(CI.[Quantity] / 12) < 1,ROUND(CEILING(SUM(CI.[Quantity]) / 12),0),ROUND(SUM(CI.[Quantity]) / 12, 0))
                    , [TotalPrice]           = SUM(CI.[TotalPrice])
                    , [TotalBlankPrice]      = SUM(CI.[TotalBlankPrice])
                    , [TotalFobValue]        = SUM(CI.[TotalFobValue])
                    , [DecorationValue]      = SUM(CI.[TotalDecorationValue])
                    , [TariffCategory]       = IIF(CI.[Orden] = 1, 'CAFTA', 'NO CAFTA')
                    , [Waybill]              = CI.[Waybill]
                    --select *
                FROM (SELECT DISTINCT invoice FROM #TB_Entry_Kelly) AS TEK
                INNER JOIN [192.168.1.93].appslca.dbo.CI_Import_Export_CommercialInvoice AS CI WITH(NOLOCK) ON TEK.[invoice] = CI.[DocumentID]
                
                -- WHERE CI.Waybill = 'HW-20260608'
                GROUP BY  
                        CI.[LineGroupKelly]
                    , CI.[DocumentID]
                    , CI.[InvoicingGroupKelly]
                    , COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
                    , CONCAT(CI.[Manufacturer], '/', CI.[CountryOfOrigin])
                    , CI.[Orden]
                    , IIF(CI.[Orden] = 1, 'CAFTA', 'NO CAFTA')
                    , CI.[Waybill]

                UNION ALL

                SELECT
                    [R_Order] = CI.[Orden]
                    , [Line]                 = CI.[LineGroupKelly]
                    , [DocumentID]           = CI.[DocumentID]  
                    , [InvoicingDescription] = CI.[InvoicingGroupKelly]    
                    , [US_HTSCode]           = COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])    
                    , [Manufacturer]         = CONCAT(CI.[Manufacturer], '/', CI.[CountryOfOrigin])
                    , [Orden]                = CI.[Orden]   
                    , [Quantity]             = SUM(CI.[Quantity])
                    , [QuantityDoz]          = IIF(SUM(CI.[Quantity] / 12) < 1,ROUND(CEILING(SUM(CI.[Quantity]) / 12),0),ROUND(SUM(CI.[Quantity]) / 12, 0))
                    , [TotalPrice]           = SUM(CI.[TotalPrice])
                    , [TotalBlankPrice]      = SUM(CI.[TotalBlankPrice])
                    , [TotalFobValue]        = SUM(CI.[TotalFobValue])
                    , [DecorationValue]      = SUM(CI.[TotalDecorationValue])
                    , [TariffCategory]       = 'NO CAFTA RULE 9802'
                    , [Waybill]              = CI.[Waybill]
                FROM (SELECT DISTINCT invoice FROM #TB_Entry_Kelly) AS TEK
                INNER JOIN [192.168.1.93].appslca.dbo.CI_Import_Export_DeclarationExport AS CI WITH(NOLOCK) ON TEK.[invoice] = CI.[DocumentID]
                GROUP BY  
                        CI.[LineGroupKelly]
                    , CI.[DocumentID]
                    , CI.[InvoicingGroupKelly]
                    , COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
                    , CONCAT(CI.[Manufacturer], '/', CI.[CountryOfOrigin])
                    , CI.[Orden]
                    , IIF(CI.[Orden] = 1, 'CAFTA', 'NO CAFTA')
                    , CI.[Waybill]
            ) AS TB
        
        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 3.1. Llenando tabla del Commercial para obtener la Línea y DocumentID que separamos y declaramos en el Summary y así comparar con Entry de KGL
        -------------------------------------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 3. Información del Commercial Invoice
    -------------------------------------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 4. Información de vista compartida a L2B (Units Invoiced)
    -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 4.1. Llenando tabla de Units Invoiced de la cual nace la vista compartida, incluyendo todos sus campos y añadiendo campos necesarios para los 
        --      cálculos de los factores por unidad (Line, DocumentID, Factor de cada tarifa y Total $ de cada tarifa (Factor * Quantity)), estos se actualizan
        --      después
        -------------------------------------------------------------------------------------------------------------------------------------------------------

            SELECT
                IWT.*
                ,[Line]                 = CAST(NULL AS INT)
                ,[DocumentID]           = CAST(NULL AS VARCHAR(200))
                ,[ManufacturerGroup]    = CAST(NULL AS VARCHAR(200))
                ,[InvoicingGroup]       = CAST(NULL AS VARCHAR(200))
                ,[Calc_Rate_Tariff122]  = CAST(0 AS DECIMAL(18,4))
                ,[Calc_Rate_301China]   = CAST(0 AS DECIMAL(18,4))
                ,[Calc_Rate_Reciprocal] = CAST(0 AS DECIMAL(18,4))
                ,[Calc_Rate_Fentanylo]  = CAST(0 AS DECIMAL(18,4))
                ,[Calc_Rate_HTS]        = CAST(0 AS DECIMAL(18,4))
                ,[$_KGLTariff122]       = CAST(0 AS DECIMAL(18,2))
                ,[$_KGL301China]        = CAST(0 AS DECIMAL(18,2))
                ,[$_KGLReciprocal]      = CAST(0 AS DECIMAL(18,2))
                ,[$_KGLFentanylo]       = CAST(0 AS DECIMAL(18,2))
                ,[$_KGLHTS]             = CAST(0 AS DECIMAL(18,2))
            INTO #TB_Units_Invoiced
            FROM (SELECT DISTINCT Waybill  FROM #TB_CommercialInvoice) AS CI
            INNER JOIN [AppsLCA].[legacycaps].[TB_L2Brands_Units_Invoiced_WithTariffs] AS IWT WITH(NOLOCK) ON CI.[Waybill] = IWT.[Waybill]
        
        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 4.1. Llenando tabla de Units Invoiced de la cual nace la vista compartida, incluyendo todos sus campos y añadiendo campos necesarios para los 
        --      cálculos de los factores por unidad (Line, DocumentID, Factor de cada tarifa y Total $ de cada tarifa (Factor * Quantity)), estos se actualizan
        --      después
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 4.2. Actualizando Campos de DocumentID y Line desde tablas del Commercial Invoice y Entry, Entry Date desde tabla de Entries
        -------------------------------------------------------------------------------------------------------------------------------------------------------

            UPDATE UI SET
                [DocumentID] = CI.[DocumentID]
            FROM #TB_Units_Invoiced AS UI
            INNER JOIN (SELECT DISTINCT DocumentID, TariffCategory, Waybill FROM #TB_CommercialInvoice) AS CI ON UI.[Waybill] = CI.[Waybill] AND UI.[TariffCategory] = CI.[TariffCategory]

            UPDATE UI SET
                [ManufacturerGroup] = CI.[ManufacturerGroupKelly]
            FROM #TB_Units_Invoiced AS UI
            INNER JOIN [192.168.1.93].appslca.dbo.CI_Import_Export_CommercialInvoice AS CI WITH(NOLOCK) ON UI.[IDExport] = CI.[IDExport] AND UI.[DocumentID] = CI.[DocumentID]

            UPDATE UI SET
                [ManufacturerGroup] = CI.[ManufacturerGroupKelly]
            FROM #TB_Units_Invoiced AS UI
            INNER JOIN [192.168.1.93].appslca.dbo.CI_Import_Export_DeclarationExport AS CI WITH(NOLOCK) ON UI.[IDExport] = CI.[IDExport] AND UI.[DocumentID] = CI.[DocumentID]

            UPDATE UI SET
                [US_HTSCode] = COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode]) 
            FROM #TB_Units_Invoiced AS UI
            INNER JOIN [192.168.1.93].appslca.dbo.CI_Import_Export_CommercialInvoice AS CI WITH(NOLOCK) ON UI.[IDExport] = CI.[IDExport] AND UI.[DocumentID] = CI.[DocumentID]

            UPDATE UI SET
                [US_HTSCode] = COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode]) 
            FROM #TB_Units_Invoiced AS UI
            INNER JOIN [192.168.1.93].appslca.dbo.CI_Import_Export_DeclarationExport AS CI WITH(NOLOCK) ON UI.[IDExport] = CI.[IDExport] AND UI.[DocumentID] = CI.[DocumentID]

            UPDATE UI SET
                [InvoicingGroup] = IIF(CI.[ProductDivision] <> 'Headwear',CI.[InvoicingGroupKelly],'')
            FROM #TB_Units_Invoiced AS UI
            INNER JOIN [192.168.1.93].appslca.dbo.CI_Import_Export_CommercialInvoice AS CI WITH(NOLOCK) ON UI.[IDExport] = CI.[IDExport] AND UI.[DocumentID] = CI.[DocumentID]

            UPDATE UI SET
                [InvoicingGroup] = IIF(CI.[ProductDivision] <> 'Headwear',CI.[InvoicingGroupKelly],'')
            FROM #TB_Units_Invoiced AS UI
            INNER JOIN [192.168.1.93].appslca.dbo.CI_Import_Export_DeclarationExport AS CI WITH(NOLOCK) ON UI.[IDExport] = CI.[IDExport] AND UI.[DocumentID] = CI.[DocumentID]

            UPDATE UI SET
                [Line] = CI.[Line]
            FROM #TB_Units_Invoiced AS UI
            INNER JOIN
            (
                
                SELECT
                *
                ,[Line]					= ROW_NUMBER() OVER(PARTITION BY A.[DocumentID] ORDER BY A.[Ord])
                FROM
                (
                    SELECT
                            [Ord]						= ROW_NUMBER() OVER(PARTITION BY CI.[DocumentID] ORDER BY CI.[Orden],  CI.[ManufacturerGroupKelly]) 
                            , [DocumentID]           	= CI.[DocumentID]  
                            , [InvoicingDescription] 	= ''
                            , [US_HTSCode]           	= COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])    
                            , [ManufacturerGroupKelly]  = CI.ManufacturerGroupKelly
                            , [Orden]                	= CI.[Orden]
                    FROM [192.168.1.93].appslca.dbo.CI_Import_Export_CommercialInvoice AS CI WITH(NOLOCK)
                    WHERE  ProductDivision = 'Headwear'
                    GROUP BY  
                                    CI.[DocumentID]
                                    , COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode]) 
                                    , CI.[ManufacturerGroupKelly]
                                    , CI.[Orden]

                    UNION ALL

                    SELECT
                            [Ord]						= ROW_NUMBER() OVER(PARTITION BY CI.[DocumentID] ORDER BY CI.[Orden]) 
                            , [DocumentID]           	= CI.[DocumentID]  
                            , [InvoicingDescription] 	= CI.[InvoicingGroupKelly]            
                            , [US_HTSCode]           	= COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])    
                            , [ManufacturerGroupKelly]  = CI.ManufacturerGroupKelly
                            , [Orden]                	= CI.[Orden]
                    FROM [192.168.1.93].appslca.dbo.CI_Import_Export_CommercialInvoice AS CI WITH(NOLOCK)
                    WHERE  ProductDivision <> 'Headwear'
                    GROUP BY  
                                    CI.[DocumentID]
                                    , CI.[InvoicingGroupKelly]
                                    , COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode]) 
                                    , CI.[ManufacturerGroupKelly]
                                    , CI.[Orden]
                ) AS A
            ) AS CI ON UI.[InvoicingGroup] = CI.[InvoicingDescription]
		            AND UI.[DocumentID] = CI.[DocumentID]
		            AND UI.[US_HTSCode] = CI.[US_HTSCode]
		            AND UI.[ManufacturerGroup] = CI.[ManufacturerGroupKelly]
		            AND CASE
                            WHEN UI.[TariffCategory] = 'CAFTA' THEN 1
                            WHEN UI.[TariffCategory] = 'NO CAFTA' THEN 2
                        END = CI.[Orden] 


            UPDATE UI SET
                [Line] = CI.[Line]
            FROM #TB_Units_Invoiced AS UI
            INNER JOIN
            (
                
                SELECT
                *
                ,[Line]					= ROW_NUMBER() OVER(PARTITION BY A.[DocumentID] ORDER BY A.[Ord])
                FROM
                (
                    SELECT
                            [Ord]						= ROW_NUMBER() OVER(PARTITION BY CI.[DocumentID] ORDER BY CI.[Orden],  CI.[ManufacturerGroupKelly]) 
                            , [DocumentID]           	= CI.[DocumentID]  
                            , [InvoicingDescription] 	= ''
                            , [US_HTSCode]           	= COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])    
                            , [ManufacturerGroupKelly]  = CI.ManufacturerGroupKelly
                            , [Orden]                	= CI.[Orden]
                    FROM [192.168.1.93].appslca.dbo.CI_Import_Export_DeclarationExport AS CI WITH(NOLOCK)
                    WHERE  ProductDivision = 'Headwear'
                    GROUP BY  
                                    CI.[DocumentID]
                                    , COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode]) 
                                    , CI.[ManufacturerGroupKelly]
                                    , CI.[Orden]

                    UNION ALL

                    SELECT
                            [Ord]						= ROW_NUMBER() OVER(PARTITION BY CI.[DocumentID] ORDER BY CI.[Orden]) 
                            , [DocumentID]           	= CI.[DocumentID]  
                            , [InvoicingDescription] 	= CI.[InvoicingGroupKelly]            
                            , [US_HTSCode]           	= COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])    
                            , [ManufacturerGroupKelly]  = CI.ManufacturerGroupKelly
                            , [Orden]                	= CI.[Orden]
                    FROM [192.168.1.93].appslca.dbo.CI_Import_Export_DeclarationExport AS CI WITH(NOLOCK)
                    WHERE  ProductDivision <> 'Headwear'
                    GROUP BY  
                                    CI.[DocumentID]
                                    , CI.[InvoicingGroupKelly]
                                    , COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode]) 
                                    , CI.[ManufacturerGroupKelly]
                                    , CI.[Orden]
                ) AS A
            ) AS CI ON UI.[InvoicingGroup] = CI.[InvoicingDescription]
		            AND UI.[DocumentID] = CI.[DocumentID]
		            AND UI.[US_HTSCode] = CI.[US_HTSCode]
		            AND UI.[ManufacturerGroup] = CI.[ManufacturerGroupKelly]
		            AND CASE
                            WHEN UI.[TariffCategory] = 'NO CAFTA RULE 9802' THEN 3
                        END
                            = CI.[Orden] 



            UPDATE TUI SET
                [Entry #] = TEK.[entry_number]
                ,[EntryDate] = TEK.[entry_date]
            FROM #TB_Units_Invoiced AS TUI
            INNER JOIN #TB_Entry_Kelly AS TEK ON TUI.[DocumentID] = TEK.[invoice]

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 4.2. Actualizando Campos de DocumentID y Line desde tablas del Commercial Invoice
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 4.3. Actualizando Campos de Factores unitarios
        -------------------------------------------------------------------------------------------------------------------------------------------------------

            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 4.3.1. Actualizando Factor para Tariff 122, 301 China, Reciprocal y Fentanylo, (aplicadas de forma global al Invoice), tomando la suma de Duty
            --        declarado en el Entry por cada tarifa y por Invoice, dividiendo entre la cantidad total declarada por Invoice
            -------------------------------------------------------------------------------------------------------------------------------------------------------

                UPDATE A SET
                -- select *,
                    [Calc_Rate_Tariff122] = ISNULL(B.[Tariff 122],0.0000) / C.[Quantity]
                    ,[Calc_Rate_301China]  = IIF(A.[CountryOfOrigin] = 'China',ISNULL(B.[301 China], 0.0000) / C.[QuantityChina],0.0000)
                    ,[Calc_Rate_Reciprocal] = ISNULL(B.[Reciprocal],0.0000) / C.[Quantity]
                    ,[Calc_Rate_Fentanylo]  = IIF(A.[CountryOfOrigin] = 'China',ISNULL(B.[Fentanylo], 0.0000) / C.[QuantityChina],0.0000)
                FROM #TB_Units_Invoiced AS A
                INNER JOIN
                (
                    SELECT
                        invoice        = invoice
                        ,[Tariff 122]   = SUM([Tariff 122])
                        ,[301 China]    = SUM([301 China])
                        ,[Reciprocal]   = SUM([Reciprocal])
                        ,[Fentanylo]    = SUM([Fentanylo])
                    FROM #PIV_EntryKelly 
                    GROUP BY
                        invoice
                ) AS B ON A.[DocumentID] = B.[invoice]
                INNER JOIN
                (
                    SELECT 
                        DocumentID
                        -- ,US_HTSCode
                        ,SUM(Quantity) AS Quantity
                        ,SUM(IIF(CountryOfOrigin = 'China',Quantity,0.00)) AS QuantityChina
                        ,ROUND(SUM(CASE WHEN TariffCategory = 'NO CAFTA RULE 9802' THEN (Decoration_Invoiced_Price * Quantity) ELSE FOBTotal END),0) AS Entered_Value
                    FROM #TB_Units_Invoiced 
                    -- WHERE DocumentID = 'AIR-APP-20260513.9802'
                    GROUP BY
                        DocumentID
                ) AS C ON A.[DocumentID] = C.[DocumentID]

            
            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 4.3.1. Actualizando Factor para Tariff 122, 301 China, Reciprocal y Fentanylo, (aplicadas de forma global al Invoice), tomando la suma de Duty
            --        declarado en el Entry por cada tarifa y por Invoice, dividiendo entre la cantidad total declarada por Invoice
            -------------------------------------------------------------------------------------------------------------------------------------------------------

            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 4.3.2. Actualizando Factor para HTS (aplicada por cada línea del Invoice), tomando la suma de Duty declarado en el Entry el HTS ingesado, por Línea
            --        e Invoice de KGL, dividiendo entre la cantidad total declarada por la Línea y Document ID del CI guardado
            -------------------------------------------------------------------------------------------------------------------------------------------------------

                UPDATE A SET
                -- select *,
                    [Calc_Rate_HTS] = ISNULL(B.[HTS],0.0000) / C.[Quantity]
                FROM #TB_Units_Invoiced AS A
                INNER JOIN
                (
                    SELECT
                        invoice        = invoice
                        ,line_num       = [line]
                        ,[HTS]          = SUM([HTS])
                    FROM #PIV_EntryKelly 
                    GROUP BY
                        invoice
                        ,[line]
                ) AS B ON A.[DocumentID] = B.[invoice] AND A.[Line] = b.[line_num]
                INNER JOIN
                (
                    SELECT 
                        DocumentID
                        -- ,US_HTSCode
                        ,[Line]
                        ,SUM(Quantity) AS Quantity
                        ,ROUND(SUM(CASE WHEN TariffCategory = 'NO CAFTA RULE 9802' THEN (Decoration_Invoiced_Price * Quantity) ELSE FOBTotal END),0) AS Entered_Value
                    FROM #TB_Units_Invoiced 
                    -- WHERE DocumentID = 'AIR-APP-20260513.9802'
                    GROUP BY
                        DocumentID
                        -- ,US_HTSCode
                        ,[Line]
                ) AS C ON A.[DocumentID] = C.[DocumentID] AND A.[Line] = C.[Line]

            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 4.3.2. Actualizando Factor para HTS (aplicada por cada línea del Invoice), tomando la suma de Duty declarado en el Entry el HTS ingesado, por Línea
            --        e Invoice de KGL, dividiendo entre la cantidad total declarada por la Línea y Document ID del CI guardado
            -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 4.3. Actualizando Campos de Factores unitarios
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 4.4. Actualizando Campos de Totales Calculados por Tarifa
        -------------------------------------------------------------------------------------------------------------------------------------------------------

            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 4.4.1. Actualizando cada campo que guarda el total de la Tarifa por unidad multiplicando Quantity * Factor unitario de cada Tarifa
            -------------------------------------------------------------------------------------------------------------------------------------------------------

                UPDATE TC SET
                    [$_KGLTariff122]   = [Quantity] * COALESCE([Calc_Rate_Tariff122],0.00)
                    ,[$_KGL301China]    = [Quantity] * COALESCE([Calc_Rate_301China],0.00)
                    ,[$_KGLReciprocal]  = [Quantity] * COALESCE([Calc_Rate_Reciprocal],0.00)
                    ,[$_KGLFentanylo]   = [Quantity] * COALESCE([Calc_Rate_Fentanylo],0.00)
                    ,[$_KGLHTS]         = [Quantity] * COALESCE([Calc_Rate_HTS],0.00)
                FROM #TB_Units_Invoiced AS TC

            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 4.4.1. Actualizando cada campo que guarda el total de la Tarifa por unidad multiplicando Quantity * Factor unitario de cada Tarifa
            -------------------------------------------------------------------------------------------------------------------------------------------------------
        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 4.4. Actualizando Campos de Totales Calculados por Tarifa
        -------------------------------------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 4. Información de vista compartida a L2B (Units Invoiced)
    -------------------------------------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 5. (Sección Comentada)!!!! Consultas para hacer comparativas por Línea y por Invoice para todas las tarifas
    -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 5.1. Compartiva por Invoice
        -------------------------------------------------------------------------------------------------------------------------------------------------------

            
            -- SELECT
            --     CI.[DocumentID]
            --     ,ek.[invoice]
            --     ,CI.[$_Calc_Tariff122]
            --     ,CI.[Tariff122_Estimated]
            --     ,ISNULL(EK.[Tariff 122],0) AS [Tariff 122]
            --     ,CI.[$_Calc_301China]
            --     ,CI.[301China_Estimated]
            --     ,ISNULL(EK.[301 China],0) AS [301 China]
            --     ,CI.[$_Calc_Reciprocal]
            --     ,CI.[Reciprocal_Estimated]
            --     ,ISNULL(EK.[Reciprocal],0) AS [Reciprocal]
            --     ,CI.[$_Calc_Fentanylo]
            --     ,CI.[Fentanylo_Estimated]
            --     ,ISNULL(EK.[Fentanylo],0) AS [Fentanylo]
            --     ,CI.[$_Calc_HTS]
            --     ,CI.[HTS_Estimated]
            --     ,ISNULL(EK.[HTS],0) AS [HTS]
            --     -- ,CI.[$_Calc_Tariff122] - ISNULL(EK.[Tariff 122],0) diff_122_CalcVSReal
            --     -- ,CI.[$_Calc_301China] - ISNULL(EK.[301 China],0) diff_301_CalcVSReal
            --     ,CI.[Tariff122_Estimated] - ISNULL(EK.[Tariff 122],0) diff_122_EstimVSReal
            --     ,CI.[301China_Estimated] - ISNULL(EK.[301 China],0) diff_301_EstimVSReal
            --     ,CI.[Reciprocal_Estimated] - ISNULL(EK.[Reciprocal],0) diff_Recip_EstimVSReal
            --     ,CI.[Fentanylo_Estimated] - ISNULL(EK.[Fentanylo],0) diff_Fenta_EstimVSReal
            --     ,CI.[$_Calc_HTS] - ISNULL(EK.[HTS],0) diff_hts_EstimVSReal
            -- FROM
            -- (
            --     SELECT 
            --         [DocumentID]
            --         ,[TotalFobValue]        = SUM(IIF(TariffCategory = 'NO CAFTA RULE 9802', (Decoration_Invoiced_Price * Quantity), FOBTotal)) 
            --         ,[$_Calc_Tariff122]     = SUM([$_KGLTariff122])
            --         ,[$_Calc_301China]      = SUM([$_KGL301China])
            --         ,[$_Calc_Reciprocal]    = SUM([$_KGLReciprocal])
            --         ,[$_Calc_Fentanylo]     = SUM([$_KGLFentanylo])
            --         ,[$_Calc_HTS]           = SUM([$_KGLHTS])
            --         ,[Tariff122_Estimated]  = SUM([Tariff122_Tariff])
            --         ,[301China_Estimated]   = SUM([301China_Tariff])
            --         ,[Reciprocal_Estimated] = SUM([Recip_Tariff])
            --         ,[Fentanylo_Estimated]  = SUM([Fenta_Tariff])
            --         ,[HTS_Estimated]        = SUM([HTS_Tariff])
            --     FROM #TB_Units_Invoiced AS CI
            --     -- WHERE DocumentID = 'HW-20260608.NC'
            --     GROUP BY
            --         [DocumentID]
            -- ) AS CI
            -- FULL JOIN 
            -- (
            --     SELECT
            --         [invoice]      = [invoice]
            --         ,[Tariff 122]   = SUM([Tariff 122])
            --         ,[301 China]    = SUM([301 China])
            --         ,[Reciprocal]   = SUM([Reciprocal])
            --         ,[Fentanylo]    = SUM([Fentanylo])
            --         ,[HTS]          = SUM([HTS])
            --     FROM #PIV_EntryKelly
            --     GROUP BY
            --         [invoice]
            -- ) AS EK ON CI.[DocumentID] = EK.[invoice]
            -- WHERE ci.[DocumentID] IS NOT NULL
            -- ORDER BY [DocumentID]
            

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 5.1. Compartiva por Invoice
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 5.2. Compartiva por Line e Invoice
        -------------------------------------------------------------------------------------------------------------------------------------------------------

            
            -- SELECT
            --     CI.[DocumentID]
            --     ,ek.[invoice]
            --     ,CI.[Line]
            --     ,CI.[$_Calc_HTS]
            --     ,CI.[HTS_Estimated]
            --     ,ISNULL(EK.[HTS],0) AS [HTS]
            --     ,CI.[HTS_Estimated] - ISNULL(EK.[HTS],0) diff_hts_EstimVSReal
            -- FROM
            -- (
            --     SELECT 
            --         [DocumentID]
            --         ,[Line]
            --         ,[TotalFobValue]        = SUM(IIF(TariffCategory = 'NO CAFTA RULE 9802', (Decoration_Invoiced_Price * Quantity), FOBTotal)) 
            --         ,[$_Calc_HTS]           = SUM([$_KGLHTS])
            --         ,[HTS_Estimated]        = SUM([HTS_Tariff])
                    
            --     FROM #TB_Units_Invoiced AS CI
            --     GROUP BY
            --         [DocumentID]
            --         ,[Line]
            -- ) AS CI
            -- FULL JOIN #PIV_EntryKelly AS EK ON CI.[DocumentID] = EK.[invoice] AND CI.[Line] = ek.[line] 
            -- WHERE EK.[HTS] > 0 AND CI.[DocumentID] = 'AIR-HW-20260519.NC'
            -- ORDER BY [DocumentID],CI.[Line]

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 5.2. Compartiva por Line e Invoice
        -------------------------------------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 5. (Sección Comentada)!!!! Consultas para hacer comparativas por Línea y por Invoice para todas las tarifas
    -------------------------------------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 6. Update Final a [AppsLCA].[legacycaps].[TB_L2Brands_Units_Invoiced_WithTariffs] guardando Factor unitario de cada tarifa y el total
    -------------------------------------------------------------------------------------------------------------------------------------------------------

        UPDATE UIW SET
             [Entry #]              = TUI.[Entry #] 
            ,[EntryDate]            = TUI.[EntryDate]
            ,[US_HTSCode]           = TUI.[US_HTSCode]
            ,[Rate_Tariff122]       = TUI.[Calc_Rate_Tariff122]
            ,[Rate_301China]        = TUI.[Calc_Rate_301China]
            ,[Rate_Reciprocal]      = TUI.[Calc_Rate_Reciprocal]
            ,[Rate_Fentanylo]       = TUI.[Calc_Rate_Fentanylo]
            ,[Rate_HTS]             = TUI.[Calc_Rate_HTS]
            ,[Real_Tariff122]       = TUI.[$_KGLTariff122]
            ,[Real_301China]        = TUI.[$_KGL301China]
            ,[Real_Reciprocal]      = TUI.[$_KGLReciprocal]
            ,[Real_Fentanylo]       = TUI.[$_KGLFentanylo]
            ,[Real_HTS]             = TUI.[$_KGLHTS]
            ,[Real_TotalTariffs]    = TUI.[$_KGLTariff122]
                                    + TUI.[$_KGL301China]
                                    + TUI.[$_KGLReciprocal]
                                    + TUI.[$_KGLFentanylo]
                                    + TUI.[$_KGLHTS]
        FROM #TB_Units_Invoiced AS TUI
        INNER JOIN [AppsLCA].[legacycaps].[TB_L2Brands_Units_Invoiced_WithTariffs] AS UIW ON TUI.[IDExport] = UIW.[IDExport]
        

        -- SELECT
        --      TUI.[IDExport]
        --     ,TUI.[Entry #]
        --     ,TUI.[EntryDate]
        --     ,UIW.[IDExport]
        --     ,UIW.[Entry #] 
        --     ,UIW.[EntryDate]
        --     ,TUI.[Rate_Tariff122]
        --     ,TUI.[Rate_301China]
        --     ,TUI.[Rate_Reciprocal]
        --     ,TUI.[Rate_Fentanylo]
        --     ,TUI.[Rate_HTS]
        --     ,UIW.[Rate_Tariff122]
        --     ,UIW.[Rate_301China]
        --     ,UIW.[Rate_Reciprocal]
        --     ,UIW.[Rate_Fentanylo]
        --     ,UIW.[Rate_HTS]
        --     ,TUI.[$_KGLTariff122]
        --     ,TUI.[$_KGL301China]
        --     ,TUI.[$_KGLReciprocal]
        --     ,TUI.[$_KGLFentanylo]
        --     ,TUI.[$_KGLHTS]
        --     ,UIW.[Real_Tariff122]
        --     ,UIW.[Real_301China]
        --     ,UIW.[Real_Reciprocal]
        --     ,UIW.[Real_Fentanylo]
        --     ,UIW.[Real_HTS]
            
        -- FROM #TB_Units_Invoiced AS TUI
        -- INNER JOIN [AppsLCA].[legacycaps].[TB_L2Brands_Units_Invoiced_WithTariffs] AS UIW ON TUI.[IDExport] = UIW.[IDExport]
        -- AND TUI.[Entry #] = 'BHE0433894'

    -------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 6. Update Final a [AppsLCA].[legacycaps].[TB_L2Brands_Units_Invoiced_WithTariffs] guardando Factor unitario de cada tarifa y el total
    -------------------------------------------------------------------------------------------------------------------------------------------------------

END