USE AppsLCA;
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_Accounting_StatementAndInvoiceL2B]
     @process   AS NVARCHAR(MAX)
    ,@data      AS NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Component AS NVARCHAR(200)
    DECLARE @Error AS BIT
    DECLARE @message AS NVARCHAR(200)
    DECLARE @resultStatement AS NVARCHAR(MAX)
    DECLARE @resultTotInvoice AS NVARCHAR(MAX)
    DECLARE @resultPivotInvoice AS NVARCHAR(MAX)
    DECLARE @resultInvoice AS NVARCHAR(MAX)

    -- DECLARE @process AS NVARCHAR(MAX)
    -- DECLARE @data AS NVARCHAR(MAX)
    DECLARE @DateFrom AS DATE
    DECLARE @DateTo AS DATE
    DECLARE @HasContainers AS BIT
    DECLARE @jsonPackingParts AS NVARCHAR(MAX)
    DECLARE @jsonInvoiceParts AS NVARCHAR(MAX)

    --------------- PRUEBAS PROCEDIMIENTO ------------------
    -- SET @process = 'statement.dates'
    -- SET @data = '{
    --     "selectedDates":[
    --         {
    --              "DateFrom":"2026-03-01"
    --             ,"DateTo":"2026-03-31"
    --         }
    --     ]
    -- }'

    -- SET @process = 'statement.actual'
    -- SET @data = ''

--     SET @process = 'download.reports'
--     SET @data = '{
--       "selectedOptions":[{"DM":"3-2192","Container_Tracking":"810-42710850","TypeShip":"Air","ShipDate":"2026-05-04","Total":83013.61}]
--    }'


    BEGIN TRY

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1. Sección de Eliminación de tablas temporales
        -------------------------------------------------------------------------------------------------------------------------------------------------------
            DROP TABLE IF EXISTS #TB_BillingData
            DROP TABLE IF EXISTS #TB_PackingList
            DROP TABLE IF EXISTS #TB_DATA_SHIPMENTS
            DROP TABLE IF EXISTS #TB_ALL_SHIPMENTS
            DROP TABLE IF EXISTS #TB_Date_FILTER
            DROP TABLE IF EXISTS #TB_PL_RAW
            DROP TABLE IF EXISTS #TB_PACKING_LIST
            DROP TABLE IF EXISTS #TB_INVOICE
            DROP TABLE IF EXISTS #TB_PIVOT_SOURCE
        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1. Sección de Eliminación de tablas temporales
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1.1. Creación de tablas temporales
        -------------------------------------------------------------------------------------------------------------------------------------------------------
            CREATE TABLE #TB_BillingData (
                [Container]          VARCHAR(200)
               ,[Waybill]            VARCHAR(200)
               ,[ShipDate]           DATE
               ,[DM]                 VARCHAR(200)
               ,[Container_Tracking] VARCHAR(200)
               ,[TypeShip]           VARCHAR(10)
               ,[Total]              DECIMAL(18,2)
            )

            CREATE TABLE #TB_DATA_SHIPMENTS (
                [RowNum]             INT
               ,[DM]                 VARCHAR(200)
               ,[Container_Tracking] VARCHAR(200)
               ,[TypeShip]           VARCHAR(10)
               ,[ShipDate]           DATE
               ,[Total]              DECIMAL(18,2)
               ,[SheetName]          VARCHAR(200)
            )
        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1.1. Creación de tablas temporales
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2.Sheet 1 - Statement Sheet from Billing Details
        -------------------------------------------------------------------------------------------------------------------------------------------------------

            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 2.1. Obteniendo Container, Waybill, ShipDate y Monto total facturado de Billing Details (Anexo Favturación), solo el último mes
            -------------------------------------------------------------------------------------------------------------------------------------------------------

                IF @process = 'statement.actual'
                BEGIN
                    INSERT INTO #TB_BillingData (
                         [Container]
                        ,[Waybill]
                        ,[ShipDate]
                        ,[DM]
                        ,[Container_Tracking]
                        ,[TypeShip]
                        ,[Total]
                    )
                    SELECT
                        af.[Container]
                        ,af.[Waybill]
                        -- ,af.[ShipDate]
                        ,MAX(fe.[fecEmi])
                        ,CAST(NULL AS VARCHAR(200))
                        ,CAST(NULL AS VARCHAR(200))
                        ,CAST(NULL AS VARCHAR(10))
                        ,SUM(af.[Total$])
                    FROM  [AppsLCA].[dbo].[ImportExport_AnexoFacturacion] af WITH(NOLOCK)
                    INNER JOIN [AppsLCA].[dbo].[DTE_FACTURAS_ELECTRONICAS] AS FE WITH(NOLOCK) ON AF.[Waybill] = FE.[factura] AND FE.[invalidado] = 0
                    WHERE fe.[fecEmi] >= DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0)
                      AND fe.[fecEmi] <  DATEADD(month, DATEDIFF(month, 0, GETDATE()) + 1, 0)
                      AND StyleNumber NOT IN ('-','Fabric','Trim','Supplies','SWATCH')
                    GROUP BY
                        af.[Container]
                        ,af.[Waybill]
                END

                IF @process = 'statement.dates'
                BEGIN
                    SELECT
                        @DateFrom = CAST(JSON_VALUE(@data, '$.selectedDates[0].DateFrom') AS DATE)
                        ,@DateTo  = CAST(JSON_VALUE(@data, '$.selectedDates[0].DateTo')   AS DATE)

                    INSERT INTO #TB_BillingData (
                         [Container]
                        ,[Waybill]
                        ,[ShipDate]
                        ,[DM]
                        ,[Container_Tracking]
                        ,[TypeShip]
                        ,[Total]
                    )
                    SELECT
                        af.[Container]
                        ,af.[Waybill]
                        -- ,af.[ShipDate]
                        ,MAX(fe.[fecEmi])
                        ,CAST(NULL AS VARCHAR(200))
                        ,CAST(NULL AS VARCHAR(200))
                        ,CAST(NULL AS VARCHAR(10))
                        ,SUM(af.[Total$])
                    FROM  [AppsLCA].[dbo].[ImportExport_AnexoFacturacion] af WITH(NOLOCK)
                    INNER JOIN [AppsLCA].[dbo].[DTE_FACTURAS_ELECTRONICAS] AS FE WITH(NOLOCK) ON AF.[Waybill] = FE.[factura] AND FE.[invalidado] = 0
                    WHERE FE.[fecEmi] BETWEEN @DateFrom AND @DateTo
                      AND StyleNumber NOT IN ('-','Fabric','Trim','Supplies','SWATCH')
                    GROUP BY
                        af.[Container]
                        ,af.[Waybill]
                END

            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 2.1. Obteniendo Container, Waybill, ShipDate y Monto total facturado de Billing Details (Anexo Favturación), solo el último mes
            -------------------------------------------------------------------------------------------------------------------------------------------------------

            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 2.2. UPDATE para completar información desde ShippingContainers y Shipments
            -- DM: Campo BookingNumber de tabla Shipments
            -- Container_Tracking: Campo Invoice8 de ShippingContainers donde se declara guía aérea o # de Contenedor
            -- TypeShip: Envío Aéreo o Contenedor, para determinarlo se compara el campo Invoice8 con ContainerNumber (ambos de ShippingContainers), si es igual
            -- es Contenedor, si no Aéreo
            -------------------------------------------------------------------------------------------------------------------------------------------------------
                UPDATE SC SET
                    SC.[Invoice8] = (SELECT [dbo].[cleanString](SC.[Invoice8]))
                FROM #TB_BillingData AS BD
                INNER JOIN (SELECT DISTINCT [Waybill], [ShippingContainerID] FROM [dbo].[ImportExport_ShipmentBoxAll]  AS SBA  WITH(NOLOCK)) AS SBA ON BD.[Waybill] = SBA.[WayBill]
                INNER JOIN [LCA].[dbo].[ShippingContainers]     AS SC   WITH(NOLOCK) ON SBA.[ShippingContainerID] = SC.[ShippingContainerID]

                UPDATE BD SET
                    [DM] = SH.[DM]
                FROM #TB_BillingData AS BD
                INNER JOIN
                (
                    SELECT DISTINCT
                        SH.[WayBill]
                        ,SH.[BookingNumber] AS [DM]
                    FROM [LCA].[dbo].[Shipments] AS SH WITH(NOLOCK)
                ) AS SH ON BD.[Waybill] = SH.[WayBill]


                UPDATE BD SET
                    [Container_Tracking] = SH.[Container_Tracking]
                    ,[TypeShip] = SH.[TypeContainer]
                FROM #TB_BillingData AS BD
                INNER JOIN
                (
                    SELECT DISTINCT
                        BD.[WayBill]
                        ,[Container_Tracking] = (SC.[Invoice8])
                        ,[TypeContainer]    = IIF(SC.[ContainerNumber] = SC.[Invoice8], 'Container', 'Air')
                    FROM #TB_BillingData AS BD
                    INNER JOIN (SELECT DISTINCT [Waybill], [ShippingContainerID] FROM [dbo].[ImportExport_ShipmentBoxAll]  AS SBA  WITH(NOLOCK)) AS SBA ON BD.[Waybill] = SBA.[WayBill]
                    INNER JOIN [LCA].[dbo].[ShippingContainers]     AS SC   WITH(NOLOCK) ON SBA.[ShippingContainerID] = SC.[ShippingContainerID]
                ) AS SH ON BD.[Waybill] = SH.[WayBill]

            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 2.2. UPDATE para completar información desde ShippingContainers y Shipments
            -- DM: Campo BookingNumber de tabla Shipments
            -- Container_Tracking: Campo Invoice8 de ShippingContainers donde se declara guía aérea o # de Contenedor
            -- TypeShip: Envío Aéreo o Contenedor, para determinarlo se compara el campo Invoice8 con ContainerNumber (ambos de ShippingContainers), si es igual
            -- es Contenedor, si no Aéreo
            -------------------------------------------------------------------------------------------------------------------------------------------------------

            SET @resultStatement = (
                                        SELECT
                                            [DM]
                                            ,[Container_Tracking]
                                            ,[TypeShip]
                                            ,[ShipDate]
                                            ,[Total] = SUM([Total])
                                        FROM #TB_BillingData
                                        GROUP BY 
                                            [DM]
                                            ,[Container_Tracking]
                                            ,[TypeShip]
                                            ,[ShipDate]
                                        ORDER BY
                                            [ShipDate]
                                        FOR JSON PATH, INCLUDE_NULL_VALUES
            )

            IF @process = 'statement.actual' OR @process = 'statement.dates'
            BEGIN

                SET @Error = 0
                SET @Component = '[200]'
                SET @message = 'Datos generados correctamente'
                SET @resultTotInvoice = '[]'
                SET @resultInvoice = '[]'
                GOTO SELECTFINAL
            END

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2.Sheet 1 - Statement Sheet from Billing Details
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 3.Sheet 2 - Total Invoice (packing list) por DM
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        IF @process = 'download.reports'
        BEGIN
            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 3.1. Parseando JSON a #TB_DATA_SHIPMENTS
            -------------------------------------------------------------------------------------------------------------------------------------------------------
                INSERT INTO #TB_DATA_SHIPMENTS (
                     [RowNum]
                    ,[DM]
                    ,[Container_Tracking]
                    ,[TypeShip]
                    ,[ShipDate]
                    ,[Total]
                    ,[SheetName]
                )
                SELECT
                     [RowNum]             = ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
                    ,[DM]                 = JSON_VALUE(value, '$.DM')
                    ,[Container_Tracking] = JSON_VALUE(value, '$.Container_Tracking')
                    ,[TypeShip]           = JSON_VALUE(value, '$.TypeShip')
                    ,[ShipDate]           = CAST(JSON_VALUE(value, '$.ShipDate') AS DATE)
                    ,[Total]              = CAST(JSON_VALUE(value, '$.Total')    AS DECIMAL(18,2))
                    ,[SheetName]          = CAST(NULL AS VARCHAR(200))
                FROM OPENJSON(@data, '$.selectedOptions')
            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 3.1. Parseando JSON a #TB_DATA_SHIPMENTS
            -------------------------------------------------------------------------------------------------------------------------------------------------------

            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 3.1.1. Asignando SheetName según agrupación por Contenedor o por fecha (solo aéreos)
            -------------------------------------------------------------------------------------------------------------------------------------------------------
                SET @HasContainers = CASE WHEN EXISTS (SELECT 1 FROM #TB_DATA_SHIPMENTS WHERE [TypeShip] = 'Container') THEN 1 ELSE 0 END

                IF @HasContainers = 1
                BEGIN
                    -- Contenedores: 'Tot. Invoice Mmm dd', con sufijo -1, -2... si comparten fecha
                    ;WITH ContainerRanked AS (
                        SELECT
                             [RowNum]
                            ,[ShipDate]
                            ,[Suffix] = ROW_NUMBER() OVER (PARTITION BY [ShipDate] ORDER BY [RowNum]) - 1
                        FROM #TB_DATA_SHIPMENTS
                        WHERE [TypeShip] = 'Container'
                    )
                    UPDATE DS SET
                        [SheetName] = 'Tot. Invoice ' + FORMAT(CR.[ShipDate], 'MMM dd', 'en-US')
                                    + CASE WHEN CR.[Suffix] = 0 THEN '' ELSE '-' + CAST(CR.[Suffix] AS VARCHAR(5)) END
                    FROM #TB_DATA_SHIPMENTS AS DS
                    INNER JOIN ContainerRanked AS CR ON DS.[RowNum] = CR.[RowNum]

                    -- Aéreos: buscar el Contenedor con fecha más cercana, desempate a favor del que viene DESPUÉS
                    UPDATE DS SET
                        [SheetName] = (
                            SELECT TOP 1
                                'Tot. Invoice ' + FORMAT(C.[ShipDate], 'MMM dd', 'en-US')
                            FROM #TB_DATA_SHIPMENTS AS C
                            WHERE C.[TypeShip] = 'Container'
                            ORDER BY
                                 ABS(DATEDIFF(day, DS.[ShipDate], C.[ShipDate])) ASC
                                ,CASE WHEN C.[ShipDate] >= DS.[ShipDate] THEN 0 ELSE 1 END ASC
                        )
                    FROM #TB_DATA_SHIPMENTS AS DS
                    WHERE DS.[TypeShip] = 'Air'
                END
                ELSE
                BEGIN
                    -- Solo aéreos: cada uno por su propia fecha
                    UPDATE DS SET
                        [SheetName] = 'Tot. Invoice ' + FORMAT(DS.[ShipDate], 'MMM dd', 'en-US')
                    FROM #TB_DATA_SHIPMENTS AS DS
                END
            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 3.1.1. Asignando SheetName según agrupación por Contenedor o por fecha (solo aéreos)
            -------------------------------------------------------------------------------------------------------------------------------------------------------

            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 3.2. Cruzando #TB_DATA_SHIPMENTS con Shipments + AnexoFacturacion para obtener Waybills → #TB_ALL_SHIPMENTS
            -------------------------------------------------------------------------------------------------------------------------------------------------------
                SELECT
                     [RowNum]             = DS.[RowNum]
                    ,[DM]                 = DS.[DM]
                    ,[Container_Tracking] = DS.[Container_Tracking]
                    ,[TypeShip]           = DS.[TypeShip]
                    ,[ShipDate]           = DS.[ShipDate]
                    ,[Total]              = DS.[Total]
                    ,[SheetName]          = DS.[SheetName]
                    ,[Waybill]            = AF.[Waybill]
                    ,[Container]          = AF.[Container]
                INTO #TB_ALL_SHIPMENTS
                --SELECT *
                FROM #TB_DATA_SHIPMENTS AS DS
                INNER JOIN [LCA].[dbo].[Shipments]                          AS SH WITH(NOLOCK) ON DS.[DM]        = SH.[BookingNumber]
                INNER JOIN [LCA].[dbo].[ShippingContainers]                 AS SC WITH(NOLOCK) ON SH.[ShippingContainerID] = SC.[ShippingContainerID] AND DS.[Container_Tracking] = SC.[Invoice8]
                INNER JOIN [AppsLCA].[dbo].[ImportExport_AnexoFacturacion]  AS AF WITH(NOLOCK) ON SH.[WayBill]   = AF.[Waybill]
                WHERE AF.[StyleNumber] NOT IN ('-','Fabric','Trim','Supplies','SWATCH')
                GROUP BY
                     DS.[RowNum]
                    ,DS.[DM]
                    ,DS.[Container_Tracking]
                    ,DS.[TypeShip]
                    ,DS.[ShipDate]
                    ,DS.[Total]
                    ,DS.[SheetName]
                    ,AF.[Waybill]
                    ,AF.[Container]
            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 3.2. Cruzando #TB_DATA_SHIPMENTS con Shipments + AnexoFacturacion para obtener Waybills → #TB_ALL_SHIPMENTS
            -------------------------------------------------------------------------------------------------------------------------------------------------------

            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 3.3. Obteniendo Packing List desde la vista, cruzando por Waybill con #TB_ALL_SHIPMENTS → #TB_PACKING_LIST
            -------------------------------------------------------------------------------------------------------------------------------------------------------
                -- Paso 1: Waybills a usar (tabla pequeña con índice)
                SELECT DISTINCT ShipDate
                INTO #TB_Date_FILTER
                FROM #TB_ALL_SHIPMENTS

                CREATE CLUSTERED INDEX IX_WB_FILTER ON #TB_Date_FILTER ([ShipDate])

                -- Paso 2: Extraer SOLO las filas necesarias de la vista, sin JOIN todavía
                SELECT
                     [Waybill]
                    -- ,[Barcode]
                    ,[Skid]
                    ,[ItemCode]
                    ,[Style]
                    ,[Color]
                    ,[ColorGreatPlain]
                    ,[Size]
                    ,[Qty]
                    ,[XX]
                    ,[OrderNo]
                    ,[L2Order]
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
                INTO #TB_PL_RAW
                FROM [LCA].[dboReaders].[VW_ImpExp_ShippingPackingSlip] WITH(NOLOCK)
                WHERE [InvoiceDate] IN (SELECT [ShipDate] FROM #TB_Date_FILTER)

                CREATE CLUSTERED INDEX IX_PL_RAW ON #TB_PL_RAW ([Waybill])

                -- Paso 3: JOIN entre la vista ya materializada y #TB_ALL_SHIPMENTS
                SELECT
                     [DM]                 = DS.[DM]
                    ,[Container_Tracking] = DS.[Container_Tracking]
                    ,[TypeShip]           = DS.[TypeShip]
                    ,[ShipDate]           = DS.[ShipDate]
                    ,[SheetName]          = DS.[SheetName]
                    ,[Waybill]            = PL.[Waybill]
                    -- ,[Barcode]            = PL.[Barcode]
                    ,[Skid]               = PL.[Skid]
                    ,[ItemCode]           = PL.[ItemCode]
                    ,[Style]              = PL.[Style]
                    ,[Color]              = PL.[Color]
                    ,[ColorGreatPlain]    = PL.[ColorGreatPlain]
                    ,[Size]               = PL.[Size]
                    ,[Qty]                = PL.[Qty]
                    ,[XX]                 = PL.[XX]
                    ,[OrderNo]            = PL.[OrderNo]
                    ,[L2Order]            = PL.[L2Order]
                    ,[Box]                = PL.[Box]
                    ,[Fact]               = PL.[Fact]
                    ,[Gender]             = PL.[Gender]
                    ,[Location]           = PL.[Location]
                    ,[Note]               = PL.[Note]
                    ,[TrackingNumber]     = PL.[TrackingNumber]
                    ,[BoxNo]              = PL.[BoxNo]
                    ,[ColorPolyPM]        = PL.[ColorPolyPM]
                    ,[Price]              = PL.[Price]
                    ,[TotalPrices]        = PL.[TotalPrices]
                    ,[InvoiceDate]        = PL.[InvoiceDate]
                INTO #TB_PACKING_LIST
                FROM #TB_PL_RAW                AS PL
                INNER JOIN #TB_ALL_SHIPMENTS   AS DS ON PL.[Waybill] = DS.[Waybill]

                CREATE CLUSTERED INDEX IX_PACKING_SHEET ON #TB_PACKING_LIST ([SheetName], [ShipDate], [TypeShip], [Waybill])
            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 3.3. Obteniendo Packing List desde la vista, cruzando por Waybill con #TB_ALL_SHIPMENTS → #TB_PACKING_LIST
            -------------------------------------------------------------------------------------------------------------------------------------------------------

            SET @resultStatement  = '[]'

            SET @jsonPackingParts = STUFF((
                SELECT CHAR(10) + ','
                    + '"' + REPLACE(S.[SheetName], '"', '\"') + '"'
                    + ':{'
                    + '"Summary":' + ISNULL(
                        (
                            SELECT [TypeShip], [Qty], [TotalPrices]
                            FROM (
                                SELECT
                                     [TypeShip]    = T.[TypeShip]
                                    ,[Qty]         = ISNULL(SUM(PL.[Qty]), 0)
                                    ,[TotalPrices] = ISNULL(SUM(PL.[TotalPrices]), 0)
                                    ,[SortOrder]   = CASE T.[TypeShip] WHEN 'Container' THEN 1 WHEN 'Air' THEN 2 END
                                FROM (VALUES ('Container'), ('Air')) AS T([TypeShip])
                                LEFT JOIN #TB_PACKING_LIST PL ON PL.[TypeShip] = T.[TypeShip]
                                                              AND PL.[SheetName] = S.[SheetName]
                                GROUP BY T.[TypeShip]
                                UNION ALL
                                SELECT
                                     'Total ($) DM contenedor'
                                    ,ISNULL(SUM([Qty]), 0)
                                    ,ISNULL(SUM([TotalPrices]), 0)
                                    ,3
                                FROM #TB_PACKING_LIST
                                WHERE [SheetName] = S.[SheetName]
                            ) AS U
                            ORDER BY U.[SortOrder]
                            FOR JSON PATH, INCLUDE_NULL_VALUES
                        ), '[]'
                    )
                    + ',"PackingList":' + ISNULL(
                        (
                            SELECT
                                 [ShipDate]
                                ,[SheetName]
                                ,[Waybill]
                                -- ,[Barcode]
                                ,[Skid]
                                ,[ItemCode]
                                ,[Style]
                                ,[Color]
                                ,[ColorGreatPlain]
                                ,[Size]
                                ,[Qty]
                                ,[XX]
                                ,[OrderNo]
                                ,[L2Order]
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
                                ,[ShipDateText] = CONVERT(VARCHAR(8), [ShipDate], 112)
                            FROM #TB_PACKING_LIST PL2
                            WHERE PL2.[SheetName] = S.[SheetName]
                            ORDER BY PL2.[ShipDate], PL2.[TypeShip] DESC, PL2.[Waybill]
                            FOR JSON PATH, INCLUDE_NULL_VALUES
                        ), '[]'
                    )
                    + '}'
                FROM (
                    SELECT [SheetName], [MinShipDate] = MIN([ShipDate])
                    FROM #TB_PACKING_LIST
                    GROUP BY [SheetName]
                ) AS S
                ORDER BY S.[MinShipDate]
                FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)'), 1, LEN(CHAR(10) + ','), '')

            SET @resultTotInvoice = '{' + @jsonPackingParts + '}'
            -- SELECT @resultTotInvoice
        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 3.Sheet 2 - Total Invoice (packing list) por DM
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 4.Sheet 3 - Pivot Packing List por Factura, Style y Size
        -------------------------------------------------------------------------------------------------------------------------------------------------------

            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 4.1. Fuente del Pivot: SUM(Qty) por ShipDate, Fact, Style, Size — solo Contenedores
            -------------------------------------------------------------------------------------------------------------------------------------------------------
                -- ShipDateText único por contenedor: sufijo -1, -2... si hay más de uno en la misma fecha
                DECLARE @ContainerKeys TABLE (
                    [Container_Tracking] VARCHAR(200)
                   ,[ShipDateText]       VARCHAR(20)
                )
                INSERT INTO @ContainerKeys ([Container_Tracking], [ShipDateText])
                SELECT
                     [Container_Tracking]
                    ,[ShipDateText] = CONVERT(VARCHAR(8), [ShipDate], 112)
                        + CASE WHEN ROW_NUMBER() OVER (PARTITION BY [ShipDate] ORDER BY [RowNum]) - 1 = 0
                               THEN ''
                               ELSE '-' + CAST(ROW_NUMBER() OVER (PARTITION BY [ShipDate] ORDER BY [RowNum]) - 1 AS VARCHAR(5))
                          END
                FROM #TB_DATA_SHIPMENTS
                WHERE [TypeShip] = 'Container'

                SELECT
                     [ShipDateText] = CK.[ShipDateText]
                    ,[Fact]
                    ,[Style]
                    ,[Size]
                    ,[Qty]          = SUM(PL.[Qty])
                INTO #TB_PIVOT_SOURCE
                FROM #TB_PACKING_LIST PL
                INNER JOIN @ContainerKeys CK ON PL.[Container_Tracking] = CK.[Container_Tracking]
                WHERE PL.[TypeShip] = 'Container'
                GROUP BY
                     CK.[ShipDateText]
                    ,[Fact]
                    ,[Style]
                    ,[Size]

                CREATE CLUSTERED INDEX IX_PIVOT_SOURCE ON #TB_PIVOT_SOURCE ([ShipDateText], [Fact], [Style], [Size])
            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 4.1. Fuente del Pivot: SUM(Qty) por ShipDate, Fact, Style, Size — solo Contenedores
            -------------------------------------------------------------------------------------------------------------------------------------------------------

            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 4.2. Pivot dinámico de tallas → @resultPivotInvoice
            -------------------------------------------------------------------------------------------------------------------------------------------------------
                DECLARE @SizeOrder  TABLE ([Size] VARCHAR(20), [SortOrder] INT)
                INSERT INTO @SizeOrder ([Size], [SortOrder]) VALUES
                     ('XS',1),('S',2),('M',3),('L',4),('XL',5)
                    ,('2XL',6),('3XL',7),('4XL',8),('5XL',9),('6XL',10)
                    ,('7XL',11),('8XL',12),('S/M',13),('L/XL',14)
                    ,('2T',15),('3T',16),('4T',17),('5T',18),('7T',19)
                    ,('8T',20),('9T',21),('ADJ',22),('QTY',23),('ONE',24),('ONE SIZE',25)

                DECLARE @pivotCols     NVARCHAR(MAX)
                DECLARE @pivotColsNull NVARCHAR(MAX)
                DECLARE @totalCols     NVARCHAR(MAX)
                DECLARE @sumCols       NVARCHAR(MAX)
                DECLARE @sqlPivot      NVARCHAR(MAX)
                DECLARE @pivotTable    NVARCHAR(128) = '##TB_PivotPacking_' + CAST(@@SPID AS NVARCHAR(10))

                -- Columnas de tallas presentes en el envío, en el orden predefinido
                SELECT @pivotCols = STUFF((
                    SELECT ',' + QUOTENAME(D.[Size])
                    FROM (SELECT DISTINCT [Size] FROM #TB_PIVOT_SOURCE) AS D
                    LEFT JOIN @SizeOrder SO ON SO.[Size] = D.[Size]
                    ORDER BY ISNULL(SO.[SortOrder], 999)
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

                -- Mismas columnas con ISNULL para mostrar 0 en lugar de NULL
                SELECT @pivotColsNull = STUFF((
                    SELECT ',' + QUOTENAME(D.[Size]) + ' = ISNULL(' + QUOTENAME(D.[Size]) + ', 0)'
                    FROM (SELECT DISTINCT [Size] FROM #TB_PIVOT_SOURCE) AS D
                    LEFT JOIN @SizeOrder SO ON SO.[Size] = D.[Size]
                    ORDER BY ISNULL(SO.[SortOrder], 999)
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

                -- Suma total de todas las tallas por fila
                SELECT @totalCols = STUFF((
                    SELECT '+ISNULL(' + QUOTENAME(D.[Size]) + ', 0)'
                    FROM (SELECT DISTINCT [Size] FROM #TB_PIVOT_SOURCE) AS D
                    LEFT JOIN @SizeOrder SO ON SO.[Size] = D.[Size]
                    ORDER BY ISNULL(SO.[SortOrder], 999)
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')   -- quita el '+' inicial

                -- SUM de cada talla para la fila TotalGeneral
                SELECT @sumCols = STUFF((
                    SELECT ',SUM(' + QUOTENAME(D.[Size]) + ')'
                    FROM (SELECT DISTINCT [Size] FROM #TB_PIVOT_SOURCE) AS D
                    LEFT JOIN @SizeOrder SO ON SO.[Size] = D.[Size]
                    ORDER BY ISNULL(SO.[SortOrder], 999)
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

                SET @sqlPivot = '
                DROP TABLE IF EXISTS ' + @pivotTable + '

                SELECT [ContainerKey] = [ShipDateText], [ShipDate] = [ShipDateText], [Fact], [Style],
                     ' + @pivotColsNull + '
                    ,[Total] = ' + @totalCols + '
                INTO ' + @pivotTable + '
                FROM (
                    SELECT [ShipDateText], [Fact], [Style], [Size], [Qty]
                    FROM #TB_PIVOT_SOURCE
                ) AS src
                PIVOT (SUM([Qty]) FOR [Size] IN (' + @pivotCols + ')) AS pvt

                INSERT INTO ' + @pivotTable + ' ([ContainerKey], [ShipDate], [Fact], [Style], ' + @pivotCols + ', [Total])
                SELECT [ContainerKey], ''TotalGeneral'', NULL, NULL, ' + @sumCols + ', SUM([Total])
                FROM ' + @pivotTable + '
                GROUP BY [ContainerKey]
                '
                EXEC sp_executesql @sqlPivot

                SET @sqlPivot = '
                SELECT @jsonResult = STUFF((
                    SELECT CHAR(10) + '',''
                        + ''"'' + REPLACE(S.[ContainerKey], ''"'', ''\"'') + ''"''
                        + '':'' + ISNULL(
                            (
                                SELECT [Style],' + @pivotCols + ',[Total]
                                FROM ' + @pivotTable + ' P
                                WHERE P.[ContainerKey] = S.[ContainerKey]
                                ORDER BY CASE WHEN P.[ShipDate] = ''TotalGeneral'' THEN 1 ELSE 0 END
                                        ,P.[Fact], P.[Style]
                                FOR JSON PATH, INCLUDE_NULL_VALUES
                            ), ''[]'')
                    FROM (
                        SELECT [ContainerKey]
                              ,[MinDate] = MIN(CASE WHEN [ShipDate] <> ''TotalGeneral'' THEN [ShipDate] END)
                        FROM ' + @pivotTable + '
                        GROUP BY [ContainerKey]
                    ) AS S
                    ORDER BY S.[MinDate]
                    FOR XML PATH(''''), TYPE
                ).value(''.'', ''NVARCHAR(MAX)''), 1, LEN(CHAR(10) + '',''), '''')'
                EXEC sp_executesql @sqlPivot, N'@jsonResult NVARCHAR(MAX) OUTPUT', @jsonResult = @resultPivotInvoice OUTPUT
                SET @resultPivotInvoice = '{' + ISNULL(@resultPivotInvoice, '') + '}'

                SET @sqlPivot = 'DROP TABLE IF EXISTS ' + @pivotTable
                EXEC sp_executesql @sqlPivot
                -- select @resultPivotInvoice
            -------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 4.2. Pivot dinámico de tallas → @resultPivotInvoice
            -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 4.Sheet 3 - Pivot Packing List por Factura, Style y Size
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 5.Sheet 4 - Invoice For L2Brands
        -------------------------------------------------------------------------------------------------------------------------------------------------------

            SELECT
                 [SheetName]                = tb2.[SheetName]
                ,[RowL]                     = ROW_NUMBER() OVER (PARTITION BY tb2.[SheetName] ORDER BY tb2.[ShipDate] ASC, tb2.[Container_Tracking] DESC)
                ,[DM]                       = tb2.[DM]
                ,[Container_Tracking]       = tb2.[Container_Tracking]
                ,[WayBill]                  = tb2.[WayBill]
                -- ,[ContainerNumber]          = tb2.[ContainerNumber]
                ,[ShipDate]                 = tb2.[ShipDate]
                ,[PO]                       = tb2.[PO]
                -- ,[Batch]                    = tb2.[Batch]
                ,[Style]                    = tb2.[Style]
                ,[Description]              = tb2.[Description]
                -- ,[CodigoGeneracion]         = tb2.[CodigoGeneracion]
                ,[UnitPrice]                = tb2.[UnitPrice]
                ,[EmbPrice]                 = tb2.[EmbPrice]
                ,[BasePrice]                = tb2.[BasePrice]
                ,[Pcs E]                    = tb2.[Pcs E]
                ,[Total]                    = tb2.[Total]
                -- ,[Ocean Freight]            = tb2.[Ocean Freight]
                -- ,[Advance Payment Received] = tb2.[Advance Payment Received]
                -- ,[Final Payment]            = tb2.[Final Payment]
            INTO #TB_INVOICE
            FROM (
                SELECT
                     TB1.[SheetName]
                    ,TB1.[DM]
                    ,TB1.[Container_Tracking]
                    ,TB1.[WayBill]
                    -- ,TB1.[ContainerNumber]
                    ,TB1.[ShipDate]
                    ,CASE
                         WHEN TB1.[PO]    IS NULL THEN 'TOTAL UNITS / USD $'
                         WHEN TB1.[Style] IS NULL THEN TB1.[PO] + ' - SUBTOTAL'
                         ELSE TB1.[PO]
                     END                    AS [PO]
                    -- ,TB1.[Batch]
                    ,TB1.[Style]
                    ,TB1.[Description]
                    -- ,TB1.[CodigoGeneracion]
                    ,TB1.[UnitPrice]
                    ,TB1.[EmbPrice]
                    ,TB1.[BasePrice]
                    ,TB1.[Pcs E]
                    ,TB1.[Total]
                    -- ,TB1.[Ocean Freight]
                    -- ,TB1.[Advance Payment Received]
                    -- ,TB1.[Final Payment]
                FROM (
                    SELECT
                         TB_Sel.[SheetName]
                        ,TB_Sel.[DM]
                        ,TB_Sel.[Container_Tracking]
                        ,TB_Sel.[WayBill]
                        -- ,TB_Sel.[ContainerNumber]
                        ,TB_Sel.[ShipDate]
                        ,TB_Sel.[PO]
                        -- ,TB_Sel.[Batch]
                        ,TB_Sel.[Style]
                        ,TB_Sel.[Description]
                        -- ,TB_Sel.[CodigoGeneracion]
                        ,TB_Sel.[UnitPrice]
                        ,TB_Sel.[EmbPrice]
                        ,TB_Sel.[BasePrice]
                        ,[Pcs E]         = SUM(TB_Sel.[Pcs E])
                        ,[Total]         = SUM(TB_Sel.[Total])
                        -- ,TB_Sel.[Ocean Freight]
                        -- ,TB_Sel.[Advance Payment Received]
                        -- ,[Final Payment] = SUM(TB_Sel.[Final Payment])
                    FROM (
                        SELECT
                             AS_TB.[SheetName]
                            ,AS_TB.[DM]
                            ,AS_TB.[Container_Tracking]
                            ,(SELECT TOP 1 Waybill FROM #TB_ALL_SHIPMENTS AS ALL_S WHERE ALL_S.[DM] = AS_TB.[DM]) AS [Waybill]
                            -- ,SBI.[WayBill]
                            -- ,SBI.[ContainerNumber]
                            ,SBI.[ShipDate]
                            ,SBI.[PONumber]                 AS [PO]
                            -- ,SBI.[Batch]
                            ,SBI.[StyleNumber]              AS [Style]
                            ,SBI.[US_HTSDescription]        AS [Description]
                            ,[UnitPrice]    = CASE
                                                WHEN CAST(SBI.[ShipDate] AS DATE) < '2026-02-10' THEN SBI.[UnitPrice]
                                                ELSE SCPD.[TotalBlank] + SCPD.[TotalDecoration]
                                              END
                            ,[EmbPrice]     = CASE
                                                WHEN CAST(SBI.[ShipDate] AS DATE) < '2026-02-10' AND (SBI.[UnitPrice] - SBI.[BasePrice]) = 0 THEN 0
                                                WHEN CAST(SBI.[ShipDate] AS DATE) < '2026-02-10' THEN (SBI.[UnitPrice] - SBI.[BasePrice])
                                                ELSE SCPD.[TotalDecoration]
                                              END
                            ,[BasePrice]    = CASE
                                                WHEN CAST(SBI.[ShipDate] AS DATE) < '2026-02-10' THEN SBI.[BasePrice]
                                                ELSE SCPD.[TotalBlank]
                                              END
                            ,[Pcs E]        = SBI.[Quantity]
                            ,[Total]        = CASE
                                                WHEN CAST(SBI.[ShipDate] AS DATE) < '2026-02-10' THEN SBI.[UnitPrice] * SBI.[Quantity]
                                                ELSE (SCPD.[TotalBlank] + SCPD.[TotalDecoration]) * SBI.[Quantity]
                                              END
                            -- ,''             AS [Ocean Freight]
                            -- ,''             AS [Advance Payment Received]
                            -- ,[Final Payment]= CASE
                            --                     WHEN CAST(SBI.[ShipDate] AS DATE) < '2026-02-10' THEN SBI.[UnitPrice] * SBI.[Quantity]
                            --                     ELSE (SCPD.[TotalBlank] + SCPD.[TotalDecoration]) * SBI.[Quantity]
                            --                   END
                            -- ,DFE.[codigoGeneracion] AS [CodigoGeneracion]
                        FROM [LCA].[dboReaders].[VW_ImpExp_ShipmentBoxItems]       SBI  WITH(NOLOCK)
                        INNER JOIN #TB_ALL_SHIPMENTS                               AS_TB            ON SBI.[WayBill]  = AS_TB.[Waybill]
                        INNER JOIN [AppsLCA].[dbo].[DTE_FACTURAS_ELECTRONICAS]    DFE  WITH(NOLOCK) ON SBI.[WayBill]  = DFE.[factura]
                                                                                                   AND SBI.[Batch]    = DFE.[items]
                                                                                                   AND DFE.[invalidado] = 0
                        LEFT  JOIN [AppsLCA].[dbo].[TB_ShipmentCheckPrices]       SCP  WITH(NOLOCK) ON SBI.[WayBill]  = SCP.[Waybill]
                        LEFT  JOIN [AppsLCA].[dbo].[TB_ShipmentCheckPricesDetail] SCPD WITH(NOLOCK) ON SCP.[id]       = SCPD.[shipmentCheckPrices_id]
                                                                                                   AND SBI.[ManufactureID] = SCPD.[ManufactureID]
                    ) AS TB_Sel
                    GROUP BY
                         TB_Sel.[SheetName]
                        ,TB_Sel.[DM]
                        ,TB_Sel.[Container_Tracking]
                        ,TB_Sel.[WayBill]
                        -- ,TB_Sel.[ContainerNumber]
                        ,TB_Sel.[ShipDate]
                        -- ,TB_Sel.[Ocean Freight]
                        -- ,TB_Sel.[Advance Payment Received]
                        ,ROLLUP (
                             TB_Sel.[PO]
                            -- ,TB_Sel.[Batch]
                            -- ,TB_Sel.[CodigoGeneracion]
                            ,TB_Sel.[Style]
                            ,TB_Sel.[Description]
                            ,TB_Sel.[UnitPrice]
                            ,TB_Sel.[EmbPrice]
                            ,TB_Sel.[BasePrice]
                        )
                        --342994.97
                ) AS TB1
                WHERE
                    ( [Style] IS NULL AND [Description] IS NULL AND [UnitPrice] IS NULL AND [EmbPrice] IS NULL AND [BasePrice] IS NULL)
                    OR ([Style] IS NOT NULL AND [Description] IS NOT NULL AND [UnitPrice] IS NOT NULL AND [BasePrice] IS NOT NULL)
            ) AS tb2
            WHERE [PO] NOT LIKE '%SUBTOTAL%'

            -- SELECT
            -- * 
            -- FROM #TB_INVOICE
            -- WHERE [PO] NOT LIKE '%SUBTOTAL%'

            CREATE CLUSTERED INDEX IX_INVOICE_DM ON #TB_INVOICE ([DM], [RowL])

            SET @jsonInvoiceParts = STUFF((
                SELECT CHAR(10) + ','
                    + '"' + REPLACE(S.[DM], '"', '\"') + '"'
                    + ':' + ISNULL(
                        (
                            SELECT *
                            FROM #TB_INVOICE INV
                            WHERE INV.[DM] = S.[DM]
                            ORDER BY INV.[RowL]
                            FOR JSON PATH, INCLUDE_NULL_VALUES
                        ), '[]'
                    )
                FROM (
                    SELECT [DM], [MinShipDate] = MIN([ShipDate])
                    FROM #TB_INVOICE
                    GROUP BY [DM]
                ) AS S
                ORDER BY S.[MinShipDate]
                FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)'), 1, LEN(CHAR(10) + ','), '')

            SET @resultInvoice = '{' + @jsonInvoiceParts + '}'

            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Datos generados correctamente'
        END -- IF @process = 'download.reports'
        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 5.Sheet 4 - Invoice For L2Brands
        -------------------------------------------------------------------------------------------------------------------------------------------------------
    END TRY
    BEGIN CATCH

        SET @Error = 1
        SET @resultStatement = '[]'
        SET @Component = '[404]'
        SET @message = 'Error in Database'

    END CATCH

    SELECTFINAL:

    SELECT
         [Error]         = @Error
        ,[Component]    = @Component
        ,[Message]      = @message
        ,[Statement]    = @resultStatement
        ,[TotInvoice]       = JSON_QUERY(@resultTotInvoice)
        ,[PivotPackingList] = JSON_QUERY(COALESCE(@resultPivotInvoice, '[]'))
        ,[InvoiceDM]        = JSON_QUERY(@resultInvoice)
    FOR JSON PATH, INCLUDE_NULL_VALUES
END
