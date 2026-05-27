USE [AppsLCA]
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------SP PARA WAREHOUSE DLI, RECEIVE FINISH GOODS CONTAINERS-----------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----Que hace este script
------1) Guarda los elementos digitados por el personal de bodega de forma temporal y de forma definitva en un log cuando crea el archivo (pendiente de desarrollar)
------2) Recibe como parametro un ReceiveSlip en el proceso 1 y en el proceso 2 una MO con los Containers a despachar, además de validar que los containers sean compatibles
-------- con el PartNumber que solicita la MO, que el Style de la MO coincida con el estilo del PartNumber y que el PartNumber de los Matriales sea igual al del Style
-------- si pasa la validación envía proceso a API de PPM para despachar el contenedor y para mover la primera tarea del WorkFlow de la MO
------3) Recibe como parametro las MO y crea las cajas en PPM, luego cada caja creada las mueve al BIN RECEIVED, valida que tenga SKU y mueve la segunda tarea del WorkFlow
------4) Recibe como parametro el BIN de recibimiento para devolver un reporte con las cajas en ese bin y agrupado por PO, CountryOfOrigin y Manufacturer, luego
-------  recibe las cajas con su nuevo bin para moverlas en PPM
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE [dbo].[SP_Warehouse_ReceiveFinishedGoodsContainers]
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

    -----------PRUEBA PARA CARGAR ITEMS 
    -- SET @process = 'items-PO'
    -- SET @data = '{
    --   "selectedOptions":[{"PO":"LCA23861"}]
    -- }'

    -----------PRUEBA PARA GUARDAR ITEMS
--     SET @process = 'save-items'
--     SET @data = '{
--       "selectedItems":{
--          "BalanceBoxes":[
            
--          ],
--          "CodEmpleado":"01514",
--          "CompleteBoxes":[
--             {
--                "Bin":"HE-CDN",
--                "BoxWeight":1.04,
--                "HTSCode":"6505009000",
--                "Item":1,
--                "Ordered":240,
--                "PartNumber":"DTA-NVY-F-ADJ",
--                "QtyCompleteBoxes":120,
--                "Received":0
--             },
--             {
--                "Bin":"HE-CDN",
--                "BoxWeight":1.04,
--                "HTSCode":"6505009000",
--                "Item":1,
--                "Ordered":240,
--                "PartNumber":"DTA-NVY-F-ADJ",
--                "QtyCompleteBoxes":120,
--                "Received":0
--             }
--          ],
--          "PO":"LCA23015",
--          "Warehouse":"headwear embroidery"
--       }
--    }'


    -----------PRUEBA PARA GENERAR CSV PARTICIONADO
    -- SET @process = 'generate-csv-partition'
    -- SET @data = '{
    --   "selectedOptions":[{"PO":"LCA23015", "CodEmpleado":"01514"}]
    -- }'

    -----------PRUEBA PARA GENERAR CSV DE TODA LA PO
    -- SET @process = 'generate-csv-all'
    -- SET @data = '{
    --   "selectedOptions":[{"PO":"LCA23015", "CodEmpleado":"01514"}]
    -- }'

    -----------PRUEBA PARA OBTENER VENDOR LIST
    -- SET @process = 'vendor-list'
    -- SET @data = '[]'

    -----------PRUEBA PARA GUARDAR ITEMS DESDE EXCEL SUBIDO
--     SET @process = 'save-upload-file'
--     SET @data = '{
--       "CodEmpleado":"02889",
--       "Items":[
--          {
--             "Barcode":"JF012420260001",
--             "Color":"C129 CHAIRLIFT BLACK",
--             "CTN":1,
--             "Description":"WOVEN CAPS",
--             "InventoryID":"5PTKR-C129-ADJ",
--             "PONumber":"LCA22444",
--             "Qty":120,
--             "Size":"ADJ",
--             "Style":"5PTKR-C129-ADJ"
--          }

--       ],
--       "PO":"LCA22444",
--       "Vendor":"GOTOP TEXTILE",
--       "VendorID":1,
--       "Warehouse":"headwear embroidery"
--    }'

-----------PRUEBA PARA CARGAR CONTAINERS Y SUS RESPECTIVAS MO
    -- SET @process = 'containers-mo'
    -- SET @data = '{
    --   "selectedOptions":[{"PO":"LCA23015"}]
    -- }'

    BEGIN TRY

        IF @process = 'category-items'
        BEGIN

            SET @result = (

                SELECT
                    ID
                    ,Category
                FROM [AppsLCA].[dbo].[TB_RC_Warehouse_ItemsCategory] WITH(NOLOCK)
                FOR JSON PATH
            )

            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Datos generados correctamente'

            GOTO SELECTFINAL

        END

        IF @process = 'items-po'
        BEGIN
            SET @category = JSON_VALUE(@data, '$.selectedOptions.Category')

            IF @category = 'Fabric'
            BEGIN
                SET @result = '[]'
                SET @Error = 0
                SET @Component = '[200]'
                SET @message = 'Datos generados correctamente'
                GOTO SELECTFINAL
            END

            -- Contracts:
            DROP TABLE IF EXISTS #TempPOs;

            SELECT
                 [PO] = j.[PO]
            INTO #TempPOs
            FROM OPENJSON(@data, '$.selectedOptions')
            WITH (PO NVARCHAR(200) '$.PO') AS j;

            SET @result = (
                            SELECT
                                 [R]            = ROW_NUMBER() OVER(ORDER BY POD.[Item])
                                ,[Item]       = POD.[Item]
                                ,[PartNumber]   = POD.[PartNumber]
                                ,[Vendor]       = POD.[Vendor]
                                ,[Ordered]      = POD.[Ordered]
                                ,[Received]     = POD.[Received]
                                ,[HTSCode]      = POD.[HTSCode]
                                ,[CanPack]      = IIF((POD.[Ordered] - POD.[Received]) > 0,1,0)
                            FROM #TempPOs AS TPO
                            INNER JOIN [LCA].[dboReaders].[VW_PurchaseOrdersDetails] AS POD WITH(NOLOCK) ON TPO.[PO] = POD.[PONumber]
                            FOR JSON PATH, INCLUDE_NULL_VALUES
                        )

            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Datos generados correctamente'

            GOTO SELECTFINAL
        END

        IF @process = 'save-items'
        BEGIN
            SET @category = JSON_VALUE(@data, '$.selectedItems.Category')

            IF @category = 'Fabric'
            BEGIN
                SET @result = '[]'
                SET @Error = 0
                SET @Component = '[200]'
                SET @message = 'Items saved successfully'
                GOTO SELECTFINAL
            END

            -- Contracts:
            DROP TABLE IF EXISTS #TempCompleteBoxes;
            SELECT
                 [R]                = ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
                ,[PO]               = JSON_VALUE(@data, '$.selectedItems.PO')
                ,[Warehouse]        = JSON_VALUE(@data, '$.selectedItems.Warehouse')
                ,[CodEmpleado]      = JSON_VALUE(@data, '$.selectedItems.CodEmpleado')
                ,[Item]             = j.[Item]
                ,[PartNumber]       = j.[PartNumber]
                ,[Ordered]          = j.[Ordered]
                ,[Received]         = j.[Received]
                ,[HTSCode]          = j.[HTSCode]
                ,[Bin]              = j.[Bin]
                ,[QtyCompleteBoxes] = j.[QtyCompleteBoxes]
                ,[BoxWeight]        = j.[BoxWeight]
                ,[TypeData]         = CAST(1 AS INT)
                ,[MaxBoxID]         = CAST(NULL AS INT)
                ,[ContainerCode]    = CAST(NULL AS VARCHAR(200))
            INTO #TempCompleteBoxes
            FROM OPENJSON(@data, '$.selectedItems.CompleteBoxes')
            WITH (
                 Item              INT             '$.Item'
                ,PartNumber        NVARCHAR(200)   '$.PartNumber'
                ,Ordered           INT             '$.Ordered'
                ,Received          INT             '$.Received'
                ,HTSCode           NVARCHAR(200)   '$.HTSCode'
                ,Bin               NVARCHAR(200)   '$.Bin'
                ,QtyCompleteBoxes  INT             '$.QtyCompleteBoxes'
                ,BoxWeight         DECIMAL(10,4)   '$.BoxWeight'
            ) AS j;

            DROP TABLE IF EXISTS #TempBalanceBoxes;
            SELECT
                 [R]                = ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
                ,[PO]          = JSON_VALUE(@data, '$.selectedItems.PO')
                ,[Warehouse]   = JSON_VALUE(@data, '$.selectedItems.Warehouse')
                ,[CodEmpleado] = JSON_VALUE(@data, '$.selectedItems.CodEmpleado')
                ,[Item]        = j.[Item]
                ,[PartNumber]  = j.[PartNumber]
                ,[Ordered]     = j.[Ordered]
                ,[Received]    = j.[Received]
                ,[HTSCode]     = j.[HTSCode]
                ,[Bin]         = j.[Bin]
                ,[QtyBox]      = j.[QtyBox]
                ,[BoxWeight]   = j.[BoxWeight]
                ,[TypeData]         = CAST(2 AS INT)
                ,[MaxBoxID]         = CAST(NULL AS INT)
                ,[ContainerCode]    = CAST(NULL AS VARCHAR(200))
            INTO #TempBalanceBoxes
            FROM OPENJSON(@data, '$.selectedItems.BalanceBoxes')
            WITH (
                 Item          INT             '$.Item'
                ,PartNumber    NVARCHAR(200)   '$.PartNumber'
                ,Ordered       INT             '$.Ordered'
                ,Received      INT             '$.Received'
                ,HTSCode       NVARCHAR(200)   '$.HTSCode'
                ,Bin           NVARCHAR(200)   '$.Bin'
                ,QtyBox        INT             '$.QtyBox'
                ,BoxWeight     DECIMAL(10,4)   '$.BoxWeight'
            ) AS j;

            UPDATE TCB SET
                 [MaxBoxID]      = COALESCE(BC.[IDCaja], 0) + TCB.[R]
                ,[ContainerCode] = TCB.[PO] + '/' + RIGHT('00000' + CAST(COALESCE(BC.[IDCaja], 0) + TCB.[R] AS VARCHAR(5)), 5)
            FROM #TempCompleteBoxes AS TCB
            LEFT JOIN
            (
                SELECT
                     [R]        = ROW_NUMBER() OVER(ORDER BY MB.[IDCaja] DESC)
                    ,[IDCaja]   = MB.[IDCaja]
                    ,[PO]       = MB.[PO]
                FROM
                (
                    SELECT TOP 100 PERCENT
                        [IDCaja]   = MAX(COALESCE(PDC.[IDCaja], 0))
                        ,[PO]       = TCB.[PO]
                    FROM #TempCompleteBoxes AS TCB
                    INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV] AS PDC WITH(NOLOCK) ON TCB.[PO] = PDC.[PONumber]
                    GROUP BY
                        TCB.[PO]

                    UNION

                    SELECT
                        [IDCaja]   = MAX(COALESCE(UIP.[IDCaja], 0))
                        ,[PO]       = TCB.[PO]
                    FROM #TempCompleteBoxes AS TCB
                    INNER JOIN [AppsLCA].[dbo].[Table_UploadItemsPPM] AS UIP WITH(NOLOCK) ON TCB.[PO] = UIP.[PONumber]
                    GROUP BY
                        TCB.[PO]
                ) AS MB
            ) AS BC ON TCB.[PO] = BC.[PO] AND BC.[R] = 1

            IF EXISTS (SELECT 1 FROM #TempBalanceBoxes)
            BEGIN
                UPDATE TBB SET
                     [MaxBoxID]      = BC.[IDCaja] + TBB.[R]
                    ,[ContainerCode] = TBB.[PO] + '/' + RIGHT('00000' + CAST(BC.[IDCaja] + TBB.[R] AS VARCHAR(5)), 5)
                FROM #TempBalanceBoxes AS TBB
                INNER JOIN
                (
                    SELECT
                         [IDCaja]   = MAX(TCB.[MaxBoxID])
                        ,[PO]       = TCB.[PO]
                    FROM #TempCompleteBoxes AS TCB
                    GROUP BY TCB.[PO]
                ) AS BC ON TBB.[PO] = BC.[PO]
            END

            INSERT INTO [AppsLCA].[dbo].[Table_PODataCSV]
            (
                 [PONumber]
                ,[ItemNumber]
                ,[PartNumber]
                ,[BoxNumber]
                ,[IDCaja]
                ,[Units]
                ,[Warehouse]
                ,[SAC]
                ,[LBS]
                ,[Bin]
                ,[Tipo]
                ,[IDUsuario]
            )
            SELECT
                 
                 [PO]               = TCB.[PO]
                ,[Item]             = TCB.[Item]
                ,[PartNumber]       = TCB.[PartNumber]
                ,[ContainerCode]    = TCB.[ContainerCode]
                ,[MaxBoxID]         = TCB.[MaxBoxID]
                ,[QtyCompleteBoxes] = TCB.[QtyCompleteBoxes]
                ,[Warehouse]        = TCB.[Warehouse]
                ,[HTSCode]          = TCB.[HTSCode]
                ,[BoxWeight]        = TCB.[BoxWeight]
                ,[Bin]              = TCB.[Bin]
                ,[TypeData]         = TCB.[TypeData]
                ,[CodEmpleado]      = TCB.[CodEmpleado]
            FROM #TempCompleteBoxes AS TCB
            UNION ALL
            SELECT
                 [PO]               = TBB.[PO]
                ,[Item]             = TBB.[Item]
                ,[PartNumber]       = TBB.[PartNumber]
                ,[ContainerCode]    = TBB.[ContainerCode]
                ,[MaxBoxID]         = TBB.[MaxBoxID]
                ,[QtyBox]           = TBB.[QtyBox]
                ,[Warehouse]        = TBB.[Warehouse]
                ,[HTSCode]          = TBB.[HTSCode]
                ,[BoxWeight]        = TBB.[BoxWeight]
                ,[Bin]              = TBB.[Bin]
                ,[TypeData]         = TBB.[TypeData]
                ,[CodEmpleado]      = TBB.[CodEmpleado]
            FROM #TempBalanceBoxes AS TBB

            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Items saved successfully'

            GOTO SELECTFINAL

        END

        IF @process = 'generate-csv-partition'
        BEGIN
            SET @category = JSON_VALUE(@data, '$.selectedOptions[0].Category')

            IF @category = 'Fabric'
            BEGIN
                SET @result = '[]'
                SET @Error = 0
                SET @Component = '[200]'
                SET @message = 'Datos generados correctamente'
                GOTO SELECTFINAL
            END

            -- Contracts:
            DROP TABLE IF EXISTS #TempGenerateCSV;
            SELECT
                 [PO]          = j.[PO]
                ,[CodEmpleado] = j.[CodEmpleado]
            INTO #TempGenerateCSV
            FROM OPENJSON(@data, '$.selectedOptions')
            WITH (
                 PO           NVARCHAR(200) '$.PO'
                ,CodEmpleado  NVARCHAR(200) '$.CodEmpleado'
            ) AS j

            SET @result = (
                SELECT distinct
                    [Component]    = POD.[Component]
                    ,[PartColor]    = POD.[PartColor]
                    ,[Rows]         = (
                                        SELECT
                                            TGC2.[PO]
                                            ,PDC2.[ItemNumber]
                                            ,PDC2.[PartNumber]
                                            ,PDC2.[BoxNumber]
                                            ,PDC2.[Units]
                                            ,PDC2.[Warehouse]
                                            ,PDC2.[SAC]
                                            ,PDC2.[LBS]
                                        FROM #TempGenerateCSV AS TGC2
                                        INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV] AS PDC2 WITH(NOLOCK) ON TGC2.[PO] = PDC2.[PONumber] AND TGC2.[CodEmpleado] = PDC2.[IDUsuario]
                                        INNER JOIN [LCA].[dboReaders].[VW_PurchaseOrdersDetails] AS POD2 WITH(NOLOCK)   ON PDC2.[PONumber] = POD2.[PONumber] 
                                                                                                                        AND PDC2.[ItemNumber] = POD2.[Item]
                                                                                                                        AND POD.[Component] = POD2.[Component]
                                                                                                                        AND POD.[PartColor] = POD2.[PartColor]
                                        FOR JSON PATH
                                    )
                FROM #TempGenerateCSV AS TGC
                INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV] AS PDC WITH(NOLOCK) ON TGC.[PO] = PDC.[PONumber] AND TGC.[CodEmpleado] = PDC.[IDUsuario]
                INNER JOIN [LCA].[dboReaders].[VW_PurchaseOrdersDetails] AS POD WITH(NOLOCK) ON PDC.[PONumber] = POD.[PONumber] AND PDC.[ItemNumber] = POD.[Item]
                FOR JSON PATH, INCLUDE_NULL_VALUES
            )

            INSERT INTO [AppsLCA].[dbo].[Table_UploadItemsPPM]
            (
                 [PONumber]
                ,[ItemNumber]
                ,[PartNumber]
                ,[BoxNumber]
                ,[IDCaja]
                ,[Units]
                ,[Warehouse]
                ,[SAC]
                ,[LBS]
                ,[Bin]
                ,[Tipo]
            )
            SELECT
                 [PONumber]
                ,[ItemNumber]
                ,[PartNumber]
                ,[BoxNumber]
                ,[IDCaja]
                ,[Units]
                ,[Warehouse]
                ,[SAC]
                ,[LBS]
                ,[Bin]
                ,[Tipo]
            FROM #TempGenerateCSV AS TGC
            INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV] AS PDC WITH(NOLOCK) ON TGC.[PO] = PDC.[PONumber] AND TGC.[CodEmpleado] = PDC.[IDUsuario]

            DELETE PDC
            FROM #TempGenerateCSV AS TGC
            INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV] AS PDC WITH(NOLOCK) ON TGC.[PO] = PDC.[PONumber] AND TGC.[CodEmpleado] = PDC.[IDUsuario]

            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Datos generados correctamente'

            GOTO SELECTFINAL

        END

        IF @process = 'generate-csv-all'
        BEGIN
            SET @category = JSON_VALUE(@data, '$.selectedOptions[0].Category')

            IF @category = 'Fabric'
            BEGIN
                SET @result = '[]'
                SET @Error = 0
                SET @Component = '[200]'
                SET @message = 'Datos generados correctamente'
                GOTO SELECTFINAL
            END

            -- Contracts:
            DROP TABLE IF EXISTS #TempGenerateCSVAll;
            SELECT
                 [PO]          = j.[PO]
                ,[CodEmpleado] = j.[CodEmpleado]
            INTO #TempGenerateCSVAll
            FROM OPENJSON(@data, '$.selectedOptions')
            WITH (
                 PO           NVARCHAR(200) '$.PO'
                ,CodEmpleado  NVARCHAR(200) '$.CodEmpleado'
            ) AS j

            SET @result = (
                SELECT
                     TGC.[PO]
                    ,PDC.[ItemNumber]
                    ,PDC.[PartNumber]
                    ,PDC.[BoxNumber]
                    ,PDC.[Units]
                    ,PDC.[Warehouse]
                    ,PDC.[SAC]
                    ,PDC.[LBS]
                FROM #TempGenerateCSVAll AS TGC
                INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV] AS PDC WITH(NOLOCK) ON TGC.[PO] = PDC.[PONumber] AND TGC.[CodEmpleado] = PDC.[IDUsuario]
                INNER JOIN [LCA].[dboReaders].[VW_PurchaseOrdersDetails] AS POD WITH(NOLOCK)    ON PDC.[PONumber] = POD.[PONumber] 
                                                                                                AND PDC.[ItemNumber] = POD.[Item]
                                                                                                
                FOR JSON PATH
            )

            INSERT INTO [AppsLCA].[dbo].[Table_UploadItemsPPM]
            (
                 [PONumber]
                ,[ItemNumber]
                ,[PartNumber]
                ,[BoxNumber]
                ,[IDCaja]
                ,[Units]
                ,[Warehouse]
                ,[SAC]
                ,[LBS]
                ,[Bin]
                ,[Tipo]
            )
            SELECT
                 [PONumber]
                ,[ItemNumber]
                ,[PartNumber]
                ,[BoxNumber]
                ,[IDCaja]
                ,[Units]
                ,[Warehouse]
                ,[SAC]
                ,[LBS]
                ,[Bin]
                ,[Tipo]
            FROM #TempGenerateCSVAll AS TGC
            INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV] AS PDC WITH(NOLOCK) ON TGC.[PO] = PDC.[PONumber] AND TGC.[CodEmpleado] = PDC.[IDUsuario]

            DELETE PDC
            FROM #TempGenerateCSVAll AS TGC
            INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV] AS PDC WITH(NOLOCK) ON TGC.[PO] = PDC.[PONumber] AND TGC.[CodEmpleado] = PDC.[IDUsuario]

            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Datos generados correctamente'

            GOTO SELECTFINAL

        END

        IF @process = 'vendor-list'
        BEGIN

            SET @result = (
                            SELECT
                                 [ID]             = V.[ID]
                                ,[Vendor]          = V.[Vendor]
                                ,[columnsReport]   = V.[columnsReport]
                                ,[columnMapping]   = JSON_QUERY(
                                                        (
                                                            SELECT
                                                                 M.[ExcelColumn]  AS excelColumn
                                                                ,M.[TargetColumn] AS targetColumn
                                                            FROM [AppsLCA].[dbo].[TB_RC_Warehouse_ASNColumnMapping] AS M WITH(NOLOCK)
                                                            WHERE M.[VendorID] = V.[ID]
                                                            FOR JSON PATH
                                                        )
                                                    )
                            FROM [AppsLCA].[dbo].[TB_RC_Warehouse_ASNColumnsPerVendor] AS V WITH(NOLOCK)
                            FOR JSON PATH, INCLUDE_NULL_VALUES
            )

            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Datos generados correctamente'

            GOTO SELECTFINAL
        END

        IF @process = 'save-upload-file'
        BEGIN
            SET @category = JSON_VALUE(@data, '$.Category')

            IF @category = 'Fabric'
            BEGIN
                SET @result = '[]'
                SET @Error = 0
                SET @Component = '[200]'
                SET @message = 'Items saved successfully'
                GOTO SELECTFINAL
            END

            -- Contracts:
            DECLARE @VendorID   INT           = CAST(JSON_VALUE(@data, '$.VendorID') AS INT)
            DECLARE @withClause NVARCHAR(MAX) = N''
            DECLARE @sqlInsert  NVARCHAR(MAX)

            -- Construir WITH(...) dinámico: todos los TargetColumns siempre presentes;
            -- los que no tienen mapping para este vendor usan '$.___no_match___' -> NULL
            SELECT @withClause = @withClause + N',' +
                QUOTENAME(S.[TargetColumn]) + N' ' + S.[DataType] + N' ''$."' +
                ISNULL(REPLACE(M.[ExcelColumn], N'''', N''''''), N'___no_match___') + N'"'''
            FROM (VALUES
                 (N'Barcode',     N'VARCHAR(200)')
                ,(N'Color',       N'VARCHAR(200)')
                ,(N'CTN',         N'INT')
                ,(N'Description', N'VARCHAR(200)')
                ,(N'InventoryID', N'VARCHAR(200)')
                ,(N'PONumber',    N'VARCHAR(200)')
                ,(N'Qty',         N'INT')
                ,(N'Size',        N'VARCHAR(200)')
                ,(N'Style',       N'VARCHAR(200)')
            ) AS S([TargetColumn], [DataType])
            LEFT JOIN [AppsLCA].[dbo].[TB_RC_Warehouse_ASNColumnMapping] AS M WITH(NOLOCK)
                ON M.[VendorID] = @VendorID AND M.[TargetColumn] = S.[TargetColumn]

            SET @withClause = STUFF(@withClause, 1, 1, N'')

            DROP TABLE IF EXISTS #TempUploadItems;
            CREATE TABLE #TempUploadItems (
                 [CodEmpleado] VARCHAR(200) NULL
                ,[Warehouse]   VARCHAR(200) NULL
                ,[Barcode]     VARCHAR(200) NULL
                ,[Color]       VARCHAR(200) NULL
                ,[CTN]         INT           NULL
                ,[Description] VARCHAR(200) NULL
                ,[InventoryID] VARCHAR(200) NULL
                ,[PONumber]    VARCHAR(200) NULL
                ,[Qty]         INT           NULL
                ,[Size]        VARCHAR(200) NULL
                ,[Style]       VARCHAR(200) NULL
                ,[Item]        INT           NULL
                ,[Ordered]     INT           NULL
                ,[Received]    INT           NULL
                ,[HTSCode]     VARCHAR(200) NULL
                ,[Bin]         VARCHAR(200) NULL
                ,[Vendor]      VARCHAR(200) NULL
                ,[BoxWeight]   DECIMAL(10,4) NULL
                ,[TypeData]    INT           NULL
                ,[MaxBoxID]    INT           NULL
            );

            SET @sqlInsert = N'
                INSERT INTO #TempUploadItems
                (CodEmpleado, Warehouse, Barcode, Color, CTN, Description, InventoryID, PONumber,
                 Qty, [Size], Style, Item, Ordered, Received, HTSCode, Bin, Vendor, BoxWeight, TypeData, MaxBoxID)
                SELECT
                     @CodEmpleado, @Warehouse
                    ,j.[Barcode], j.[Color], j.[CTN], j.[Description], j.[InventoryID], j.[PONumber]
                    ,j.[Qty], j.[Size], j.[Style]
                    ,NULL, NULL, NULL, NULL
                    ,@Bin
                    ,NULL, 1.04, 3, 0
                FROM OPENJSON(@jsonData, N''$.Items'')
                WITH (' + @withClause + N') AS j';

            DECLARE @p_CodEmpleado VARCHAR(200) = JSON_VALUE(@data, '$.CodEmpleado')
            DECLARE @p_Warehouse   VARCHAR(200) = JSON_VALUE(@data, '$.Warehouse')
            DECLARE @p_Bin         VARCHAR(200) = JSON_VALUE(@data, '$.Bin')

            EXEC sp_executesql @sqlInsert,
                N'@jsonData VARCHAR(MAX), @CodEmpleado VARCHAR(200), @Warehouse VARCHAR(200), @Bin VARCHAR(200)',
                @jsonData    = @data,
                @CodEmpleado = @p_CodEmpleado,
                @Warehouse   = @p_Warehouse,
                @Bin         = @p_Bin;

            
            UPDATE TUI SET
                 [Item]     = POD.[Item]
                ,[Ordered]  = POD.[Ordered]
                ,[Received] = POD.[Received]
                ,[HTSCode]  = POD.[HTSCode]
                ,[Vendor]   = POD.[Vendor]
            FROM #TempUploadItems AS TUI
            INNER JOIN [LCA].[dboReaders].[VW_PurchaseOrdersDetails] AS POD WITH(NOLOCK) ON TUI.[PONumber] = POD.[PONumber] AND TUI.[Style] = POD.[PartNumber]

            UPDATE TUI SET
                 [MaxBoxID]      = COALESCE(BC.[IDCaja], 0) + TUI.[CTN]
            FROM #TempUploadItems AS TUI
            LEFT JOIN
            (
                SELECT
                     [R]        = ROW_NUMBER() OVER(ORDER BY MB.[IDCaja] DESC)
                    ,[IDCaja]   = MB.[IDCaja]
                    ,[PO]       = MB.[PO]
                FROM
                (
                    SELECT TOP 100 PERCENT
                        [IDCaja]   = MAX(COALESCE(PDC.[IDCaja], 0))
                        ,[PO]       = TUI.[PONumber]
                    FROM #TempUploadItems AS TUI
                    INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV] AS PDC WITH(NOLOCK) ON TUI.[PONumber] = PDC.[PONumber]
                    GROUP BY
                        TUI.[PONumber]

                    UNION

                    SELECT
                        [IDCaja]   = MAX(COALESCE(UIP.[IDCaja], 0))
                        ,[PO]       = TUI.[PONumber]
                    FROM #TempUploadItems AS TUI
                    INNER JOIN [AppsLCA].[dbo].[Table_UploadItemsPPM] AS UIP WITH(NOLOCK) ON TUI.[PONumber] = UIP.[PONumber]
                    GROUP BY
                        TUI.[PONumber]
                ) AS MB
            ) AS BC ON TUI.[PONumber] = BC.[PO] AND BC.[R] = 1

            INSERT INTO [AppsLCA].[dbo].[Table_PODataCSV]
            (
                 [PONumber]
                ,[ItemNumber]
                ,[PartNumber]
                ,[BoxNumber]
                ,[IDCaja]
                ,[Units]
                ,[Warehouse]
                ,[SAC]
                ,[LBS]
                ,[Bin]
                ,[Tipo]
                ,[IDUsuario]
            )
            SELECT
                 [PONumber]
                ,[Item]
                ,[Style]
                ,[Barcode]
                ,[MaxBoxID]
                ,[Qty]
                ,[Warehouse]
                ,[HTSCode]
                ,[BoxWeight]
                ,[Bin]
                ,[TypeData]
                ,[CodEmpleado]
            FROM #TempUploadItems

            SET @result = (
                            SELECT 
                                [Item]             = TUI.[Item]
                                ,[Part Number]      = TUI.[Style]
                                ,[Vendor]           = TUI.[Vendor]
                                ,[Ordered]          = TUI.[Ordered]
                                ,[Received]         = TUI.[Received]
                                ,[HTSCode]          = TUI.[HTSCode]
                                ,[Bin]              = TUI.[Bin]
                                ,[ContainerCode]    = TUI.[Barcode]
                                ,[QtyBoxes]         = TUI.[Qty]
                                ,[BoxWeight]        = TUI.[BoxWeight]
                            FROM #TempUploadItems AS TUI
                            ORDER BY [Item], [ContainerCode]
                            FOR JSON PATH, INCLUDE_NULL_VALUES
            )

            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Items saved successfully'

            GOTO SELECTFINAL

        END

        IF @process = 'containers-mo'
        BEGIN

            DROP TABLE IF EXISTS #TempPOsContainers;
            DROP TABLE IF EXISTS #TB_MO_Containers

            SELECT
                 [PO] = j.[PO]
            INTO #TempPOsContainers
            FROM OPENJSON(@data, '$.selectedOptions')
            WITH (PO NVARCHAR(200) '$.PO') AS j;
            
            SELECT
                 [PO]                   = TPO.[PO]
                ,[ManufactureNumber]    = MO.[ManufactureNumber]
                ,[ManufactureID]        = MO.[ManufactureID]
                ,[RawMaterialID_MO]     = RA.[RawMaterialID]
                ,[PartNumber_MO]        = RM.[PartNumber]
                ,[StyleNumber]          = ST.[StyleNumber]
                ,[StyleColorName]       = STC.[StyleColorName]
                ,[RawMaterialID_Styles] = STV.[RawMaterialID]
                ,[PartNumber_Styles]    = RMS.[PartNumber]
                ,[Containers]           = CAST(NULL AS NVARCHAR(MAX))
                ,[RawMaterialID_RC]     = CAST(NULL AS INT)
                ,[PartNumber_RC]        = CAST(NULL AS VARCHAR(200))
                ,[IsValid_PNMO]         = CAST(NULL AS BIT)
                ,[IsValid_PNST]         = CAST(NULL AS BIT)
                ,[IsValid_PNRC]         = CAST(NULL AS BIT)
                ,[Error_MO]             = CAST(NULL AS VARCHAR(200))
                ,[Error_ST]             = CAST(NULL AS VARCHAR(200))
                ,[Error_RC]             = CAST(NULL AS VARCHAR(200))
                ,[Flag_Final]           = CAST(NULL AS BIT)
                ,[Error_Final]          = CAST(NULL AS VARCHAR(MAX))
            INTO #TB_MO_Containers
            FROM #TempPOsContainers                     AS TPO
            LEFT  JOIN [LCA].[dbo].[Orders]             AS OD  WITH(NOLOCK) ON OD.[PONumber] LIKE '%' + TPO.[PO] + '%'
            INNER JOIN [LCA].[dbo].[ManufactureOrders]  AS MO  WITH(NOLOCK) ON MO.[OrderID] = OD.[OrderID]
            LEFT  JOIN [LCA].[dbo].[RawAllocationHistory] AS RA WITH(NOLOCK) ON MO.[ManufactureID] = RA.[ManufactureID]  --- CAMBIAR A RAWALLOCATION DESPUES DEL DESARROLLO
            INNER JOIN [LCA].[dbo].[RawMaterials]       AS RM  WITH(NOLOCK) ON RA.[RawMaterialID] = RM.[RawMaterialID]
            INNER JOIN [LCA].[dbo].[OrderItems]         AS OI  WITH(NOLOCK) ON MO.[FirstOrderItemID] = OI.[OrderItemID]
            INNER JOIN [LCA].[dbo].[Styles]             AS ST  WITH(NOLOCK) ON OI.[StyleID] = ST.[StyleID]
            INNER JOIN [LCA].[dbo].[StyleColors]        AS STC WITH(NOLOCK) ON OI.[StyleColorID] = STC.[StyleColorID]
            INNER JOIN [LCA].[dbo].[StyleVariations]    AS STV WITH(NOLOCK) ON ST.[StyleID] = STV.[StyleID] AND STC.[StyleColorID] = STV.[StyleColorID]
            LEFT  JOIN [LCA].[dbo].[RawMaterials]       AS RMS WITH(NOLOCK) ON STV.[RawMaterialID] = RMS.[RawMaterialID]

            UPDATE TMC SET
                 [Containers]       = CC.[Codes]
                ,[RawMaterialID_RC] = CC.[RawMaterialID]
                ,[PartNumber_RC]    = CC.[PartNumber]
            FROM #TB_MO_Containers AS TMC
            INNER JOIN
            (
                SELECT
                     [Codes]            = STRING_AGG(POD.[Code], ',')
                    ,[PartNumber]       = POD.[PartNumber]
                    ,[RawMaterialID]    = POD.[RawMaterialID]
                    ,[PO]               = TPO.[PO]
                FROM #TempPOsContainers                                             AS TPO
                INNER JOIN [LCA].[dboReaders].[VW_PurchaseOrdersDetailsVerJC_Ver2]  AS POD WITH (NOLOCK) ON TPO.[PO] = POD.[PONumber]
                GROUP BY
                     POD.[PartNumber]
                    ,POD.[RawMaterialID]
                    ,TPO.[PO]
            ) AS CC ON (TMC.[RawMaterialID_MO] = CC.[RawMaterialID] OR TMC.[RawMaterialID_Styles] = CC.[RawMaterialID]) AND CC.[PO] = TMC.[PO]

            UPDATE TMC SET
                 [IsValid_PNRC] = IIF(RawMaterialID_RC IS NULL,0,1)
                ,[IsValid_PNMO] = IIF(RawMaterialID_MO <> RawMaterialID_RC AND RawMaterialID_RC = RawMaterialID_Styles,0,1)
                ,[IsValid_PNST] = IIF(RawMaterialID_Styles <> RawMaterialID_MO AND RawMaterialID_Styles <> RawMaterialID_RC AND RawMaterialID_MO = RawMaterialID_RC,0,1)
                ,[Error_RC]     = IIF(RawMaterialID_RC IS NULL,'Containers not found for this MO, please check Part Number in Materials MO |','')
                ,[Error_MO]     = IIF(
                                        RawMaterialID_MO <> RawMaterialID_RC 
                                    AND RawMaterialID_RC = RawMaterialID_Styles
                                    ,'MO Part Number do not match with Containers/Style Part Number, please check Part Number in Materials MO |'
                                    ,'')
                ,[Error_ST]     = IIF(
                                        RawMaterialID_Styles <> RawMaterialID_MO 
                                    AND RawMaterialID_Styles <> RawMaterialID_RC 
                                    AND RawMaterialID_MO = RawMaterialID_RC
                                    ,'Style Part Number do not match with MO/Containers Part Number, please check Part Number in variations of Style: ' + StyleNumber + ' Color: ' + StyleColorName +''
                                    ,'')
            FROM #TB_MO_Containers AS TMC

            UPDATE TMC SET
                IsValid_PNST = 0
                ,Error_ST = 'Style Part Number do not match with MO/Containers Part Number, please check Part Number in variations of Style: ' + StyleNumber + ' Color: ' + StyleColorName +''
            FROM #TB_MO_Containers AS TMC
            WHERE ManufactureID = 850084

            UPDATE TMC SET
                 [Flag_Final] = IIF(IsValid_PNRC = 0 OR IsValid_PNMO = 0 OR IsValid_PNST = 0,0,1)
                ,[Error_Final] = CONCAT([Error_RC], Error_MO, Error_ST)
            FROM #TB_MO_Containers AS TMC
            
            SET @result = (
                
                SELECT
                    [PO]                = [PO]
                    ,[MO]               = [ManufactureNumber]
                    ,[ManufactureID]    = [ManufactureID]
                    ,[Containers]       = [Containers]
                    ,[CanWithdraw]      = [Flag_Final]
                    ,[ErrorWithdraw]    = [Error_Final]
                FROM #TB_MO_Containers AS TMC
                FOR JSON PATH, INCLUDE_NULL_VALUES
            )

            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Datos generados correctamente'

            GOTO SELECTFINAL

        END
    END TRY
    BEGIN CATCH

        SET @Error = 1
        SET @result = '[]'
        SET @Component = '[404]'
        SET @message = 'Error in Database'

        GOTO SELECTFINAL
        
    END CATCH

    SELECTFINAL:

    SELECT
         [Error]        = @Error
        ,[Component]    = @Component
        ,[Message]      = @message
        ,[result]       = JSON_QUERY(@result)
    FOR JSON PATH, INCLUDE_NULL_VALUES
END