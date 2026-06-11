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

    DECLARE @Datos              VARCHAR(200)    --Variable que tiene los datos que iran en el archivo TXT
    DECLARE @DatosEnviarAPI AS NVARCHAR(MAX)
    DECLARE @jsonResponse AS NVARCHAR(MAX)

    -----------PRUEBA PARA CARGAR ITEMS 
    -- SET @process = 'items-PO'
    -- SET @data = '{
    --   "selectedOptions":[{"PO":"LCA23494", "Category":"Fabric"}]
    -- }'

    -----------PRUEBA PARA GUARDAR ITEMS
--     SET @process = 'save-items'
--     SET @data = '{
--       "selectedItems":{
--          "BalanceBoxes":[
            
--          ],
--          "Category":"Fabric",
--          "CodEmpleado":"02889",
--          "CompleteBoxes":[
--             {
--                "Bin":"HE-CDN",
--                "DyeLot":"158449",
--                "HTSCode":"6006320000",
--                "IM":"5-2121",
--                "Item":4,
--                "LBS":48.25,
--                "Ordered":4800,
--                "PartNumber":"KI70WH095-408",
--                "PO":"LCA24039",
--                "Received":0,
--                "RollNum":"7672699",
--                "YDS":109.17
--             },
--             {
--                "Bin":"HE-CDN",
--                "DyeLot":"158449",
--                "HTSCode":"6006320000",
--                "IM":"5-2121",
--                "Item":4,
--                "LBS":45.25,
--                "Ordered":4800,
--                "PartNumber":"KI70WH095-408",
--                "PO":"LCA24039",
--                "Received":0,
--                "RollNum":"7665751",
--                "YDS":101.28
--             },
--             {
--                "Bin":"HE-CDN",
--                "DyeLot":"158449",
--                "HTSCode":"6006320000",
--                "IM":"5-2121",
--                "Item":4,
--                "LBS":47.9,
--                "Ordered":4800,
--                "PartNumber":"KI70WH095-408",
--                "PO":"LCA24039",
--                "Received":0,
--                "RollNum":"7665753",
--                "YDS":109.4
--             },
--             {
--                "Bin":"HE-CDN",
--                "DyeLot":"158449",
--                "HTSCode":"6006320000",
--                "IM":"5-2121",
--                "Item":4,
--                "LBS":47.8,
--                "Ordered":4800,
--                "PartNumber":"KI70WH095-408",
--                "PO":"LCA24039",
--                "Received":0,
--                "RollNum":"7665748",
--                "YDS":109.09
--             },
--             {
--                "Bin":"HE-CDN",
--                "DyeLot":"158449",
--                "HTSCode":"6006320000",
--                "IM":"5-2121",
--                "Item":4,
--                "LBS":47.35,
--                "Ordered":4800,
--                "PartNumber":"KI70WH095-408",
--                "PO":"LCA24039",
--                "Received":0,
--                "RollNum":"7665752",
--                "YDS":107.5
--             },
--             {
--                "Bin":"HE-CDN",
--                "DyeLot":"158449",
--                "HTSCode":"6006320000",
--                "IM":"5-2121",
--                "Item":4,
--                "LBS":44.85,
--                "Ordered":4800,
--                "PartNumber":"KI70WH095-408",
--                "PO":"LCA24039",
--                "Received":0,
--                "RollNum":"7665754",
--                "YDS":100.13
--             },
--             {
--                "Bin":"HE-CDN",
--                "DyeLot":"158449",
--                "HTSCode":"6006320000",
--                "IM":"5-2121",
--                "Item":4,
--                "LBS":46.1,
--                "Ordered":4800,
--                "PartNumber":"KI70WH095-408",
--                "PO":"LCA24039",
--                "Received":0,
--                "RollNum":"7665749",
--                "YDS":103.16
--             },
--             {
--                "Bin":"HE-CDN",
--                "DyeLot":"158449",
--                "HTSCode":"6006320000",
--                "IM":"5-2121",
--                "Item":4,
--                "LBS":43.7,
--                "Ordered":4800,
--                "PartNumber":"KI70WH095-408",
--                "PO":"LCA24039",
--                "Received":0,
--                "RollNum":"7672700",
--                "YDS":101.76
--             },
--             {
--                "Bin":"HE-CDN",
--                "DyeLot":"158449",
--                "HTSCode":"6006320000",
--                "IM":"5-2121",
--                "Item":4,
--                "LBS":48.65,
--                "Ordered":4800,
--                "PartNumber":"KI70WH095-408",
--                "PO":"LCA24039",
--                "Received":0,
--                "RollNum":"7665745",
--                "YDS":111.94
--             },
--             {
--                "Bin":"HE-CDN",
--                "DyeLot":"158449",
--                "HTSCode":"6006320000",
--                "IM":"5-2121",
--                "Item":4,
--                "LBS":45.25,
--                "Ordered":4800,
--                "PartNumber":"KI70WH095-408",
--                "PO":"LCA24039",
--                "Received":0,
--                "RollNum":"7672698",
--                "YDS":106.4
--             }
--          ],
--          "Warehouse":"Warehouse"
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
    --   "selectedOptions":[{"PO":"LCA24167"}]
    -- }'

-----------PRUEBA PARA DESPACHAR CONTENEDORES
    -- SET @process = 'withdraw-mo'
    -- SET @data = '{
    --                 "selectedOptions":[{
    --                 "PO":"LCA23015"
    --                 ,"MO":"23015-DTA-TBN"
    --                 ,"ManufactureID":850048
    --                 ,"Containers":"[{\"Code\":\"PPRC1896057\",\"On Hand\":0.000000000000000e+000},{\"Code\":\"PPRC1896058\",\"On Hand\":0.000000000000000e+000}]"
    --                 ,"CanWithdraw":true
    --                 ,"ErrorWithdraw":""
    --                 ,"Container":"PPRC1896057"
    --                 ,"OnHand":null
    --                 }]
    --             }'

-----------PRUEBA PARA CREAR CAJAS
    -- SET @process = 'create-boxes'
    -- SET @data = '{"selectedOptions":[{"MO":"24167-2BAR-TSSOG","ManufactureID":959075},{"MO":"24167-5PTKR-C326","ManufactureID":959076}]}'

-----------PRUEBA PARA CARGAR BINS CAJAS DE MO
    -- SET @process = 'boxes-list'
    -- SET @data = '{"selectedOptions":[{"MO":"24165-LTA-TSAN","ManufactureID":959153}, {"MO":"24165-MPS-TBLOSO","ManufactureID":959154}]}'

-----------PRUEBA PARA CARGAR BINS FLOOR
    -- SET @process = 'bins-list'
    -- SET @data = '{"selectedOptions":[{"MO":"24163-COACH-POW","ManufactureID":959070}]}'

-----------PRUEBA PARA DESPACHAR CONTENEDORES
    -- SET @process = 'move-boxes-bin'
    -- SET @data = '{
    --                 "selectedOptions":[{
    --                     "MO":"23015-DTA-NVY"
    --                 ,"ManufactureID":850045
    --                 ,"BoxNumber":"BOX4S1896041"
    --                 ,"QtyPacked":120
    --                 ,"GoodsBinID":5532
    --                 ,"Bin":"RECEIVED"
    --                 ,"WarehouseName":"Headwear DLI"
    --                 }]
    --               }'

-----------PRUEBA PARA CARGAR MO CON SUS WORKFLOW
    -- SET @process = 'mo-workflow'
    -- SET @data = '{
    --   "selectedOptions":[{"PO":"POLCATestIT20260603-2"}]
    -- }'

-----------PRUEBA PARA DESPACHAR CONTENEDORES
    -- SET @process = 'transaction-workflow'
    -- SET @data = '{
    --                 "selectedOptions":[{
    --                 "PO":"LCA23015"
    --                 ,"ManufactureNumber":"23015-DTA-NVY"
    --                 ,"ManufactureID":850045
    --                 ,"TaskID":11338756
    --                 ,"TaskName":"\r\nCreate Bundles"
    --                 ,"PPAD":"PPAD12345"
    --                 }]
    --              }'

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

            SET @category = JSON_VALUE(@data, '$.selectedOptions[0].Category')

            DROP TABLE IF EXISTS #TempPOs;

            SELECT
                 [PO] = j.[PO]
            INTO #TempPOs
            FROM OPENJSON(@data, '$.selectedOptions')
            WITH (PO NVARCHAR(200) '$.PO') AS j;

            IF @category = 'Fabric'
            BEGIN
                SET @result = (
                                SELECT
                                     [R]              = ROW_NUMBER() OVER(ORDER BY POD.[Item])
                                    ,[PO]             = TPO.[PO]
                                    ,[Item]           = POD.[Item]
                                    ,[PartNumber]     = POD.[PartNumber]
                                    ,[Vendor]         = POD.[Vendor]
                                    ,[Ordered]        = POD.[Ordered]
                                    ,[Received]       = POD.[Received]
                                    ,[HTSCode]        = POD.[HTSCode]
                                    ,[Description]    = POD.[Description]
                                    ,[VendorPartCode] = POD.[VendorPartCode]
                                    ,[PartColor]      = POD.[PartColor]
                                    ,[CanPack]        = IIF((POD.[Ordered] - POD.[Received]) > 0,1,0)
                                FROM #TempPOs AS TPO
                                INNER JOIN [LCA].[dboReaders].[VW_PurchaseOrdersDetails] AS POD WITH(NOLOCK) ON TPO.[PO] = POD.[PONumber]
                                FOR JSON PATH, INCLUDE_NULL_VALUES
                            )
            END
            ELSE
            BEGIN
                SET @result = (
                                SELECT
                                     [R]            = ROW_NUMBER() OVER(ORDER BY POD.[Item])
                                    ,[PO]           = TPO.[PO]
                                    ,[Item]         = POD.[Item]
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
            END

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

                -- Fabric:
                DROP TABLE IF EXISTS #TempCompleteBoxesMaterials;
                SELECT
                     [R]             = ROW_NUMBER() OVER(PARTITION BY j.[PO] ORDER BY j.[PO])
                    ,[PO]            = j.[PO]
                    ,[Warehouse]     = JSON_VALUE(@data, '$.selectedItems.Warehouse')
                    ,[CodEmpleado]   = JSON_VALUE(@data, '$.selectedItems.CodEmpleado')
                    ,[Item]          = j.[Item]
                    ,[PartNumber]    = j.[PartNumber]
                    ,[Ordered]       = j.[Ordered]
                    ,[Received]      = j.[Received]
                    ,[HTSCode]       = j.[HTSCode]
                    ,[Bin]           = j.[Bin]
                    ,[DyeLot]        = j.[DyeLot]
                    ,[IM]            = j.[IM]
                    ,[LBS]           = j.[LBS]
                    ,[RollNum]       = j.[RollNum]
                    ,[YDS]           = j.[YDS]
                    ,[TypeData]      = CAST(1 AS INT)
                    ,[MaxBoxID]      = CAST(NULL AS INT)
                    ,[ContainerCode] = CAST(NULL AS VARCHAR(200))
                INTO #TempCompleteBoxesMaterials
                FROM OPENJSON(@data, '$.selectedItems.CompleteBoxes')
                WITH (
                     PO          NVARCHAR(200)   '$.PO'
                    ,Item        INT             '$.Item'
                    ,PartNumber  NVARCHAR(200)   '$.PartNumber'
                    ,Ordered     INT             '$.Ordered'
                    ,Received    INT             '$.Received'
                    ,HTSCode     NVARCHAR(200)   '$.HTSCode'
                    ,Bin         NVARCHAR(200)   '$.Bin'
                    ,DyeLot      NVARCHAR(200)   '$.DyeLot'
                    ,IM          NVARCHAR(200)   '$.IM'
                    ,LBS         DECIMAL(10,4)   '$.LBS'
                    ,RollNum     NVARCHAR(200)   '$.RollNum'
                    ,YDS         DECIMAL(10,4)   '$.YDS'
                ) AS j;

                UPDATE TCBM SET
                     [MaxBoxID]      = COALESCE(BC.[IDCaja], 0) + TCBM.[R]
                    ,[ContainerCode] = TCBM.[PO] + '/' + RIGHT('00000' + CAST(COALESCE(BC.[IDCaja], 0) + TCBM.[R] AS VARCHAR(5)), 5)
                FROM #TempCompleteBoxesMaterials AS TCBM
                LEFT JOIN
                (
                    SELECT
                         [R]      = ROW_NUMBER() OVER(ORDER BY MB.[IDCaja] DESC)
                        ,[IDCaja] = MB.[IDCaja]
                        ,[PO]     = MB.[PO]
                    FROM
                    (
                        SELECT TOP 100 PERCENT
                             [IDCaja] = MAX(COALESCE(PDC.[IDCaja], 0))
                            ,[PO]     = TCBM.[PO]
                        FROM #TempCompleteBoxesMaterials AS TCBM
                        INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV_Materials] AS PDC WITH(NOLOCK) ON TCBM.[PO] = PDC.[PO]
                        GROUP BY TCBM.[PO]

                        UNION

                        SELECT
                             [IDCaja] = MAX(COALESCE(UIM.[IDCaja], 0))
                            ,[PO]     = TCBM.[PO]
                        FROM #TempCompleteBoxesMaterials AS TCBM
                        INNER JOIN [AppsLCA].[dbo].[Table_UploadItemsPPM_Materials] AS UIM WITH(NOLOCK) ON TCBM.[PO] = UIM.[PO]
                        GROUP BY TCBM.[PO]
                    ) AS MB
                ) AS BC ON TCBM.[PO] = BC.[PO] AND BC.[R] = 1

                INSERT INTO [AppsLCA].[dbo].[Table_PODataCSV_Materials]
                (
                     [Memo #]
                    ,[Roll ID]
                    ,[Piece #]
                    ,[Lbs]
                    ,[IDCaja]
                    ,[Yds]
                    ,[Warehouse]
                    ,[PO]
                    ,[SAC]
                    ,[PartNumber]
                    ,[IM]
                    ,[ItemNumber]
                    ,[Tipo]
                    ,[IDUsuario]
                )
                SELECT
                     [DyeLot]        = TCBM.[DyeLot]
                    ,[ContainerCode] = TCBM.[ContainerCode]
                    ,[RollNum]       = TCBM.[RollNum]
                    ,[LBS]           = TCBM.[LBS]
                    ,[MaxBoxID]      = TCBM.[MaxBoxID]
                    ,[YDS]           = TCBM.[YDS]
                    ,[Warehouse]     = TCBM.[Warehouse]
                    ,[PO]            = TCBM.[PO]
                    ,[HTSCode]       = TCBM.[HTSCode]
                    ,[PartNumber]    = TCBM.[PartNumber]
                    ,[IM]            = TCBM.[IM]
                    ,[Item]          = TCBM.[Item]
                    ,[TypeData]      = TCBM.[TypeData]
                    ,[CodEmpleado]   = TCBM.[CodEmpleado]
                FROM #TempCompleteBoxesMaterials AS TCBM

                SET @Error = 0
                SET @Component = '[200]'
                SET @message = 'Items saved successfully'
                GOTO SELECTFINAL

            END

            -- Contracts:
            DROP TABLE IF EXISTS #TempCompleteBoxes;
            SELECT
                 [R]                = ROW_NUMBER() OVER(PARTITION BY j.[PO] ORDER BY j.[PO])
                ,[PO]               = j.[PO]
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
                 PO                NVARCHAR(200)   '$.PO'
                ,Item              INT             '$.Item'
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
                 [R]           = ROW_NUMBER() OVER(PARTITION BY j.[PO] ORDER BY j.[PO])
                ,[PO]          = j.[PO]
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
                 PO            NVARCHAR(200)   '$.PO'
                ,Item          INT             '$.Item'
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

            IF @category = 'Fabric'
            BEGIN

                SET @result = (
                    SELECT DISTINCT
                         [Component] = POD.[Component]
                        ,[PartColor]  = POD.[PartColor]
                        ,[Rows]       = (
                                            SELECT
                                                 PDM2.[Memo #]
                                                ,PDM2.[Roll ID]
                                                ,PDM2.[Piece #]
                                                ,PDM2.[Lbs]
                                                ,PDM2.[IDCaja]
                                                ,PDM2.[Yds]
                                                ,PDM2.[Warehouse]
                                                ,PDM2.[PO]
                                                ,PDM2.[SAC]
                                                ,PDM2.[PartNumber]
                                                ,PDM2.[IM]
                                                ,PDM2.[ItemNumber]
                                                ,PDM2.[IDUsuario]
                                            FROM #TempGenerateCSV AS TGC2
                                            INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV_Materials] AS PDM2 WITH(NOLOCK) ON TGC2.[PO] = PDM2.[PO] AND TGC2.[CodEmpleado] = PDM2.[IDUsuario]
                                            INNER JOIN [LCA].[dboReaders].[VW_PurchaseOrdersDetails] AS POD2 WITH(NOLOCK) ON PDM2.[PO] = POD2.[PONumber]
                                                                                                                           AND PDM2.[ItemNumber] = POD2.[Item]
                                                                                                                           AND POD.[Component] = POD2.[Component]
                                                                                                                           AND POD.[PartColor] = POD2.[PartColor]
                                            FOR JSON PATH
                                        )
                    FROM #TempGenerateCSV AS TGC
                    INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV_Materials] AS PDM WITH(NOLOCK) ON TGC.[PO] = PDM.[PO] AND TGC.[CodEmpleado] = PDM.[IDUsuario]
                    INNER JOIN [LCA].[dboReaders].[VW_PurchaseOrdersDetails] AS POD WITH(NOLOCK) ON PDM.[PO] = POD.[PONumber] AND PDM.[ItemNumber] = POD.[Item]
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                )

                INSERT INTO [AppsLCA].[dbo].[Table_UploadItemsPPM_Materials]
                (
                     [Memo #]
                    ,[Roll ID]
                    ,[Piece #]
                    ,[Lbs]
                    ,[IDCaja]
                    ,[Yds]
                    ,[Warehouse]
                    ,[PO]
                    ,[SAC]
                    ,[PartNumber]
                    ,[IM]
                    ,[ItemNumber]
                    ,[Tipo]
                )
                SELECT
                     PDM.[Memo #]
                    ,PDM.[Roll ID]
                    ,PDM.[Piece #]
                    ,PDM.[Lbs]
                    ,PDM.[IDCaja]
                    ,PDM.[Yds]
                    ,PDM.[Warehouse]
                    ,PDM.[PO]
                    ,PDM.[SAC]
                    ,PDM.[PartNumber]
                    ,PDM.[IM]
                    ,PDM.[ItemNumber]
                    ,PDM.[Tipo]
                FROM #TempGenerateCSV AS TGC
                INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV_Materials] AS PDM WITH(NOLOCK) ON TGC.[PO] = PDM.[PO] AND TGC.[CodEmpleado] = PDM.[IDUsuario]

                DELETE PDM
                FROM #TempGenerateCSV AS TGC
                INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV_Materials] AS PDM WITH(NOLOCK) ON TGC.[PO] = PDM.[PO] AND TGC.[CodEmpleado] = PDM.[IDUsuario]

                SET @Error = 0
                SET @Component = '[200]'
                SET @message = 'Datos generados correctamente'
                GOTO SELECTFINAL

            END

            -- Contracts:
            SET @result = (
                SELECT DISTINCT
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
                                        INNER JOIN [LCA].[dboReaders].[VW_PurchaseOrdersDetails] AS POD2 WITH(NOLOCK) ON PDC2.[PONumber] = POD2.[PONumber]
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

            IF @category = 'Fabric'
            BEGIN

                SET @result = (
                    SELECT
                         PDM.[Memo #]
                        ,PDM.[Roll ID]
                        ,PDM.[Piece #]
                        ,PDM.[Lbs]
                        ,PDM.[IDCaja]
                        ,PDM.[Yds]
                        ,PDM.[Warehouse]
                        ,PDM.[PO]
                        ,PDM.[SAC]
                        ,PDM.[PartNumber]
                        ,PDM.[IM]
                        ,PDM.[ItemNumber]
                        ,PDM.[IDUsuario]
                    FROM #TempGenerateCSVAll AS TGC
                    INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV_Materials] AS PDM WITH(NOLOCK) ON TGC.[PO] = PDM.[PO] AND TGC.[CodEmpleado] = PDM.[IDUsuario]
                    FOR JSON PATH
                )

                INSERT INTO [AppsLCA].[dbo].[Table_UploadItemsPPM_Materials]
                (
                     [Memo #]
                    ,[Roll ID]
                    ,[Piece #]
                    ,[Lbs]
                    ,[IDCaja]
                    ,[Yds]
                    ,[Warehouse]
                    ,[PO]
                    ,[SAC]
                    ,[PartNumber]
                    ,[IM]
                    ,[ItemNumber]
                    ,[Tipo]
                )
                SELECT
                     PDM.[Memo #]
                    ,PDM.[Roll ID]
                    ,PDM.[Piece #]
                    ,PDM.[Lbs]
                    ,PDM.[IDCaja]
                    ,PDM.[Yds]
                    ,PDM.[Warehouse]
                    ,PDM.[PO]
                    ,PDM.[SAC]
                    ,PDM.[PartNumber]
                    ,PDM.[IM]
                    ,PDM.[ItemNumber]
                    ,PDM.[Tipo]
                FROM #TempGenerateCSVAll AS TGC
                INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV_Materials] AS PDM WITH(NOLOCK) ON TGC.[PO] = PDM.[PO] AND TGC.[CodEmpleado] = PDM.[IDUsuario]

                DELETE PDM
                FROM #TempGenerateCSVAll AS TGC
                INNER JOIN [AppsLCA].[dbo].[Table_PODataCSV_Materials] AS PDM WITH(NOLOCK) ON TGC.[PO] = PDM.[PO] AND TGC.[CodEmpleado] = PDM.[IDUsuario]

                SET @Error = 0
                SET @Component = '[200]'
                SET @message = 'Datos generados correctamente'
                GOTO SELECTFINAL

            END

            -- Contracts:
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
                INNER JOIN [LCA].[dboReaders].[VW_PurchaseOrdersDetails] AS POD WITH(NOLOCK) ON PDC.[PONumber] = POD.[PONumber]
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
                                 [ID]               = V.[ID]
                                ,[Vendor]           = V.[Vendor]
                                ,[columnsReport]    = V.[columnsReport]
                                ,[HeaderRow]        = V.[HeaderRow]
                                ,[DataRow]          = V.[DataRow]
                                ,[StartColumn]      = V.[StartColumn]
                                ,[columnMapping]    = JSON_QUERY(
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
            INNER JOIN [LCA].[dboReaders].[VW_PurchaseOrdersDetails] AS POD WITH(NOLOCK) ON TUI.[PONumber] = POD.[PONumber] AND TUI.[InventoryID] = POD.[PartNumber]

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
            DROP TABLE IF EXISTS #TB_PODetails_Containers
            DROP TABLE IF EXISTS #TB_MOCanPack

            SELECT
                 [PO] = j.[PO]
            INTO #TempPOsContainers
            FROM OPENJSON(@data, '$.selectedOptions')
            WITH (PO NVARCHAR(200) '$.PO') AS j;
            
            SELECT
                 [PO]                   = TPO.[PO]
                ,[ManufactureNumber]    = MO.[ManufactureNumber]
                ,[ManufactureID]        = MO.[ManufactureID]
                ,[RawMaterialID_MO]     = COALESCE(RA.[RawMaterialID], RAH.[RawMaterialID])
                ,[PartNumber_MO]        = RM.[PartNumber]
                ,[StyleNumber]          = ST.[StyleNumber]
                ,[StyleColorName]       = STC.[StyleColorName]
                ,[RawMaterialID_Styles] = STV.[RawMaterialID]
                ,[PartNumber_Styles]    = RMS.[PartNumber]
                ,[Containers]           = CAST(NULL AS NVARCHAR(MAX))
                ,[Boxes]                = CAST(NULL AS NVARCHAR(MAX))
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
                ,[Flag_PackBox]         = CAST(NULL AS BIT)
            INTO #TB_MO_Containers
            FROM #TempPOsContainers                         AS TPO
            LEFT  JOIN [LCA].[dbo].[Orders]                 AS OD  WITH(NOLOCK) ON OD.[PONumber] LIKE '%' + TPO.[PO] + '%'
            INNER JOIN [LCA].[dbo].[ManufactureOrders]      AS MO  WITH(NOLOCK) ON MO.[OrderID] = OD.[OrderID]
            LEFT  JOIN [LCA].[dbo].[RawAllocations]         AS RA  WITH(NOLOCK) ON MO.[ManufactureID] = RA.[ManufactureID]  --- CAMBIAR A RAWALLOCATION DESPUES DEL DESARROLLO
            LEFT  JOIN [LCA].[dbo].[RawAllocationHistory]   AS RAH WITH(NOLOCK) ON MO.[ManufactureID] = RAH.[ManufactureID]
            INNER JOIN [LCA].[dbo].[RawMaterials]           AS RM  WITH(NOLOCK) ON RA.[RawMaterialID] = RM.[RawMaterialID]
                                                                                 OR RAH.[RawMaterialID] = RM.[RawMaterialID]
            INNER JOIN [LCA].[dbo].[OrderItems]             AS OI  WITH(NOLOCK) ON MO.[FirstOrderItemID] = OI.[OrderItemID]
            INNER JOIN [LCA].[dbo].[Styles]                 AS ST  WITH(NOLOCK) ON OI.[StyleID] = ST.[StyleID]
            INNER JOIN [LCA].[dbo].[StyleColors]            AS STC WITH(NOLOCK) ON OI.[StyleColorID] = STC.[StyleColorID]
            INNER JOIN [LCA].[dbo].[StyleVariations]        AS STV WITH(NOLOCK) ON ST.[StyleID] = STV.[StyleID]
                                                                                 AND STC.[StyleColorID] = STV.[StyleColorID]
            LEFT  JOIN [LCA].[dbo].[RawMaterials]           AS RMS WITH(NOLOCK) ON STV.[RawMaterialID] = RMS.[RawMaterialID]


            SELECT
                 [R]                     = ROW_NUMBER() OVER(ORDER BY RC.[ContainerCode])
                ,[Code]                  = RC.[ContainerCode]
                ,[RawContainerID]        = RC.[RawContainerID]
                ,[Category]              = CC.[CategoryName]
                ,[SubCategoryName]       = CS.[SubCategoryName]
                ,[OrderDate]             = PO.[OrderDate]
                ,[OriginalScheduleDate]  = PO.[OriginalScheduleDate]
                ,[CancelDate]            = PO.[CancelDate]
                ,[ScheduledShipDate]     = PO.[ScheduledShipDate]
                ,[PartNumber]            = RM.[PartNumber]
                ,[PartColor]             = C.[ColorName]
                ,[StatusName]            = SN.[StatusName]
                ,[RollNumber]            = RC.[RollNumber]
                ,[PONumber]              = PO.[PONumber]
                ,[Description]           = RM.[Description]
                ,[Fabric Width]          = RC.[FabricWidth]
                ,[On Hand]               = RC.[QuantityOnHand]
                ,[Units]                 = UN.[UnitName]
                ,[Bin]                   = RB.[Bin]
                ,[Warehouse]             = WH.[WarehouseName]
                ,[ComponentName]         = CL.[ComponentName]
                ,[IM5/IM9]               = RS.[WayBill]
                ,[SAC]                   = RC.[Label]
                ,[Technical Desc.]       = RC.[Comments3]
                ,[Average Material Cost] = RM.[AverageUnitCost]
                ,[Container Unit Cost]   = RC.[AverageUnitCost]
                ,[Unit Freight Cost]     = RC.[UnitFreightCost]
                ,[FabricWidth_Component] = CL.[FabricWidth]
                ,[ColorDescription]      = C.[ColorDescription]
                ,[ShipNumber]            = RS.[ShipNumber]
                ,[RawMaterialID]         = RM.[RawMaterialID]
            INTO #TB_PODetails_Containers
            FROM
            (
                SELECT
                     [StatusID]
                    ,[StatusName]
                FROM [LCA].[dbo].[StatusNames] AS SN WITH(NOLOCK)
                WHERE [StatusID] IN (7, 30, 105)
            ) AS SN -- StatusID IN (7, 30, 58, 105, 113)
            INNER JOIN [LCA].[dbo].[RawContainers]          AS RC WITH(NOLOCK) ON SN.[StatusID] = RC.[StatusID]
                                                                                 AND RC.[ContainerCode] NOT IN ('<Default>')
            LEFT  JOIN [LCA].[dbo].[PurchaseDetails]        AS PD WITH(NOLOCK) ON RC.[PurchaseDetailID] = PD.[PurchaseDetailID]
            INNER JOIN [LCA].[dbo].[PurchaseOrders]         AS PO WITH(NOLOCK) ON PD.[PurchaseID] = PO.[PurchaseID]
            INNER JOIN #TempPOsContainers                   AS FPO              ON PO.[PONumber] = FPO.[PO]
            LEFT  JOIN [LCA].[dbo].[RawMaterials]           AS RM WITH(NOLOCK)  ON RC.[RawMaterialID] = RM.[RawMaterialID]
            LEFT  JOIN [LCA].[dbo].[ComponentLibrary]       AS CL WITH(NOLOCK)  ON RM.[ComponentID] = CL.[ComponentID]
            LEFT  JOIN [LCA].[dbo].[ComponentCategories]    AS CC WITH(NOLOCK)  ON CL.[ComponentCategoryID] = CC.[ComponentCategoryID]
            LEFT  JOIN [LCA].[dbo].[ComponentSubcategories] AS CS WITH(NOLOCK)  ON CL.[SubCategoryID] = CS.[SubCategoryID]
            LEFT  JOIN [LCA].[dbo].[UnitNames]              AS UN WITH(NOLOCK)  ON UN.[UnitNameID] = CL.[DatabaseUnitID]
            LEFT  JOIN [LCA].[dbo].[Colors]                 AS C  WITH(NOLOCK)  ON RM.[ColorID] = C.[ColorID]
            LEFT  JOIN [LCA].[dbo].[RawBins]                AS RB WITH(NOLOCK)  ON RC.[RawBinID] = RB.[RawBinID]
            LEFT  JOIN [LCA].[dbo].[Warehouses]             AS WH WITH(NOLOCK)  ON RC.[StockWarehouseID] = WH.[WarehouseID]
            LEFT  JOIN [LCA].[dbo].[ReceiveSlips]           AS RS WITH(NOLOCK)  ON RC.[ReceiveID] = RS.[ReceiveID]
            LEFT  JOIN [LCA].[dbo].[Addresses]              AS VD WITH(NOLOCK)  ON RS.[VendorID] = VD.[AddressID]



            UPDATE TMC SET
                 [Containers]       = (
                                            SELECT
                                                 [Code]   = POD.[Code]
                                                ,[OnHand] = CAST(POD.[On Hand] AS INT)
                                            FROM #TB_PODetails_Containers AS POD
                                            WHERE (TMC.[RawMaterialID_MO] = POD.[RawMaterialID] OR TMC.[RawMaterialID_Styles] = POD.[RawMaterialID])
                                              AND POD.[PONumber] = TMC.[PO]
                                            FOR JSON PATH
                                        )
                ,[RawMaterialID_RC] = CC.[RawMaterialID]
                ,[PartNumber_RC]    = CC.[PartNumber]
            FROM #TB_MO_Containers AS TMC
            INNER JOIN
            (
                SELECT
                     [PartNumber]    = MAX(POD.[PartNumber])
                    ,[RawMaterialID] = POD.[RawMaterialID]
                    ,[PO]            = POD.[PONumber]
                FROM #TB_PODetails_Containers AS POD
                GROUP BY
                     POD.[RawMaterialID]
                    ,POD.[PONumber]
            ) AS CC ON (TMC.[RawMaterialID_MO] = CC.[RawMaterialID] OR TMC.[RawMaterialID_Styles] = CC.[RawMaterialID])
                   AND CC.[PO] = TMC.[PO]

            UPDATE TMC SET
                 [IsValid_PNRC] = IIF(RawMaterialID_RC IS NULL,0,1)
                ,[IsValid_PNMO] = IIF(RawMaterialID_MO <> RawMaterialID_RC AND RawMaterialID_RC = RawMaterialID_Styles,0,1)
                ,[IsValid_PNST] = IIF(RawMaterialID_Styles <> RawMaterialID_MO AND RawMaterialID_Styles <> RawMaterialID_RC AND RawMaterialID_MO = RawMaterialID_RC,0,1)
                ,[Error_RC]     = IIF(RawMaterialID_RC IS NULL,'No containers have been found for this MO. Please check the Part Number in the Materials tab of the MO |','')
                ,[Error_MO]     = IIF(
                                        RawMaterialID_MO <> RawMaterialID_RC 
                                    AND RawMaterialID_RC = RawMaterialID_Styles
                                    ,'The Part Number of the MO does not match the Part Number of Containers/Styles, please check PartNumber in the Materials tab of the MO |'
                                    ,'')
                ,[Error_ST]     = IIF(
                                        RawMaterialID_Styles <> RawMaterialID_MO 
                                    AND RawMaterialID_Styles <> RawMaterialID_RC 
                                    AND RawMaterialID_MO = RawMaterialID_RC
                                    ,'The style part number does not match the part number of MI/Containers; please verify the part number in Style: ' + StyleNumber + ' Color: ' + StyleColorName +' variations'
                                    ,'')
            FROM #TB_MO_Containers AS TMC

            UPDATE TMC SET
                 [Flag_Final] = IIF(IsValid_PNRC = 0 OR IsValid_PNMO = 0 OR IsValid_PNST = 0,0,1)
                ,[Error_Final] = CONCAT([Error_RC], Error_MO, Error_ST)
            FROM #TB_MO_Containers AS TMC

            SELECT
                 [MO]               = TMC.[ManufactureNumber]
                ,[ManufactureID]    = TMC.[ManufactureID]
                ,[Make]             = MO.[QuantityOrdered]
                ,[QtyWithDraw]      = ABS(SUM(CT.[Quantity]))
                ,[QtyPacked]        = CAST(NULL AS INT)
                ,[CanPack]          = CAST(NULL AS BIT)
                ,[BoxCreated]       = CAST(NULL AS BIT)
            INTO #TB_MOCanPack
            FROM #TB_MO_Containers AS TMC
            INNER JOIN [LCA].[dbo].[ManufactureOrders]  AS MO WITH(NOLOCK) ON TMC.[ManufactureID] = MO.[ManufactureID]
            INNER JOIN [LCA].[dbo].[RawTransactions]    AS RT WITH(NOLOCK) ON MO.[ManufactureID] = RT.[ManufactureID]
            INNER JOIN [LCA].[dbo].[ContainerTransfers] AS CT WITH(NOLOCK) ON RT.[RawTransactionID] = CT.[RawTransactionID]
            GROUP BY
                 TMC.[ManufactureNumber]
                ,TMC.[ManufactureID]
                ,MO.[QuantityOrdered]

            UPDATE MCP SET
                [QtyPacked] = PI.[QtyPacked]
            FROM #TB_MOCanPack AS MCP 
            INNER JOIN
            (
                SELECT
                    [MO]               = TMC.[ManufactureNumber]
                    ,[ManufactureID]    = TMC.[ManufactureID]
                    ,[Make]             = MO.[QuantityOrdered]
                    ,[QtyPacked]        = SUM(PI.[Quantity])
                FROM #TB_MO_Containers AS TMC
                INNER JOIN [LCA].[dbo].[PackedItems]        AS PI WITH(NOLOCK) ON TMC.[ManufactureID] = PI.[ManufactureID]
                INNER JOIN [LCA].[dbo].[ManufactureOrders]  AS MO WITH(NOLOCK) ON TMC.[ManufactureID] = MO.[ManufactureID]
                GROUP BY
                    TMC.[ManufactureNumber]
                    ,TMC.[ManufactureID]
                    ,MO.[QuantityOrdered]
            ) AS PI ON MCP.[ManufactureID] = PI.[ManufactureID]

            UPDATE MCP SET
                [BoxCreated] = IIF([QtyPacked] - [Make] = 0,1,0)
            FROM #TB_MOCanPack AS MCP

            UPDATE MCP SET
                -- [CanPack] = IIF([QtyWithDraw] - [Make] = 0 ,1,0)
                [CanPack] = IIF([QtyWithDraw] - [Make] = 0 AND [BoxCreated] <> 1,1,0)
            FROM #TB_MOCanPack AS MCP

            UPDATE TMC SET
                 [Flag_PackBox] = MCP.[CanPack]
                ,[Flag_Final]   = IIF(MCP.[QtyWithDraw] - MCP.[Make] = 0,0,1)
                ,[Error_Final]  = IIF(MCP.[QtyWithDraw] - MCP.[Make] = 0,'No more containers can be withdrawn','')
            FROM #TB_MO_Containers      AS TMC
            INNER JOIN #TB_MOCanPack    AS MCP ON TMC.[ManufactureID] = MCP.[ManufactureID]

            UPDATE TM SET
                 [Boxes] = (
                                SELECT
                                     [BoxNumber] = PB.[BoxNumber]
                                    ,[QtyPacked] = SUM(PI.[Quantity])
                                FROM #TB_MO_Containers AS TMC
                                INNER JOIN [LCA].[dbo].[PackedItems] AS PI WITH(NOLOCK) ON TMC.[ManufactureID] = PI.[ManufactureID]
                                INNER JOIN [LCA].[dbo].[PackedBoxes] AS PB WITH(NOLOCK) ON PI.[PackedBoxID] = PB.[PackedBoxID]
                                WHERE PI.[ManufactureID] = TM.[ManufactureID]
                                GROUP BY PB.[BoxNumber]
                                FOR JSON PATH, INCLUDE_NULL_VALUES
                            )
            FROM #TB_MO_Containers AS TM

            SET @result = (
                SELECT
                     [PO]               = [PO]
                    ,[MO]               = [ManufactureNumber]
                    ,[ManufactureID]    = [ManufactureID]
                    ,[Containers]       = [Containers]
                    ,[Boxes]            = [Boxes]
                    ,[CanWithdraw]      = [Flag_Final]
                    ,[ErrorWithdraw]    = [Error_Final]
                    ,[CanPack]          = [Flag_PackBox]
                FROM #TB_MO_Containers AS TMC
                ORDER BY [ManufactureID]
                FOR JSON PATH, INCLUDE_NULL_VALUES
            )

            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Datos generados correctamente'

            GOTO SELECTFINAL

        END

        IF @process = 'withdraw-mo'
        BEGIN

            DROP TABLE IF EXISTS #TempWithdrawMO;
            SELECT
                 [PO]            = j.[PO]
                ,[MO]            = j.[MO]
                ,[ManufactureID] = j.[ManufactureID]
                ,[Container]     = j.[Container]
                ,[OnHand]        = ISNULL(j.[OnHand], 0)
                ,[CanPack]       = 0
            INTO #TempWithdrawMO
            FROM OPENJSON(@data, '$.selectedOptions')
            WITH (
                 PO            NVARCHAR(200)   '$.PO'
                ,MO            NVARCHAR(200)   '$.MO'
                ,ManufactureID INT             '$.ManufactureID'
                ,Container     NVARCHAR(200)   '$.Container'
                ,OnHand        FLOAT           '$.OnHand'
            ) AS j;

            DECLARE @BarcodeMO      VARCHAR(200)
            DECLARE @Container      VARCHAR(200)
            DECLARE @ContainerQty   INT
            DECLARE @FechaHoy   CHAR(8)
            DECLARE @HoraHoy    CHAR(7)

            SET @BarcodeMO  = CONCAT('PPMO', CAST(CAST(JSON_VALUE(@data, '$.selectedOptions[0].ManufactureID') AS INT) + 1000000 AS VARCHAR(20)))
            SET @Container  = JSON_VALUE(@data, '$.selectedOptions[0].Container')
            SET @FechaHoy   = FORMAT(GETDATE(), 'yyyyMMdd')
            SET @HoraHoy    = FORMAT(GETDATE(), 'HHmmssf')

            SET @ContainerQty = ISNULL(CAST(CAST(JSON_VALUE(@data, '$.selectedOptions[0].OnHand') AS FLOAT) AS INT), 0)

            SET @Datos              = CONCAT('MFG,',@BarcodeMO,',',@FechaHoy,',',@HoraHoy,',003,','TAKQ,',@Container,',,',@ContainerQty)
            SET @DatosEnviarAPI= @Datos
    
            -- SELECT @DatosEnviarAPI
            --DECLARE @flagJson AS BIT
            --DECLARE @responsePPM AS NVARCHAR(MAX)
            --DECLARE @jsonResponse AS NVARCHAR(MAX)
            --DECLARE @FinalComponent AS NVARCHAR(MAX)

            --- Ejecutar el procedimiento almacenado y capturar el resultado JSON en una variable de salida
            EXEC [AppsLCA].[dbo].[SP_Barcode_TransactionAPI] 
            --EXEC [192.168.1.93].[AppsLCA].[dbo].[SP_Barcode_TransactionAPI] 
                @VarTransaction = @DatosEnviarAPI, --'BOX,PPMB1606768,20250214,1325890,1,TBUQ,PPBX11441940,PPFG1196505,1',
                @jsonResponse = @jsonResponse OUTPUT

            --- Extraer los valores del JSON de salida
            SET @message = JSON_VALUE(@jsonResponse, '$[0].MessagePPM')
            SET @Error = IIF(JSON_VALUE(@jsonResponse, '$[0].FlagCompleted') = 'true',0,1)
            SET @Component = JSON_VALUE(@jsonResponse, '$[0].FinalComponent')

            IF @Error = 0
            BEGIN

                UPDATE #TempWithdrawMO SET
                    [OnHand] = [OnHand] - @ContainerQty

                SET @result = (
                    SELECT
                         [PO]            = [PO]
                        ,[MO]            = [MO]
                        ,[ManufactureID] = [ManufactureID]
                        ,[Container]     = [Container]
                        ,[OnHand]        = [OnHand]
                        ,[CanPack]       = 1
                    FROM #TempWithdrawMO
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                )

            END

            GOTO SELECTFINAL

        END

        IF @process = 'create-boxes'
        BEGIN

            DROP TABLE IF EXISTS #TempCreateBoxes;
            DROP TABLE IF EXISTS #TB_BoxesCreated
            DROP TABLE IF EXISTS #TB_DataFinal

            SELECT
                 [MO]            = j.[MO]
                ,[ManufactureID] = j.[ManufactureID]
            INTO #TempCreateBoxes
            FROM OPENJSON(@data, '$.selectedOptions')
            WITH (
                 MO            NVARCHAR(200)   '$.MO'
                ,ManufactureID INT             '$.ManufactureID'
            ) AS j;

            SELECT
                 [MO]               = TMB.[MO]
                ,[ManufactureID]    = TMB.[ManufactureID]
                ,[Make]             = MO.[QuantityOrdered]
                ,[QtyPacked]        = SUM(ISNULL(PI.[Quantity],0))
                ,[CanPack]          = CAST(NULL AS BIT)
            INTO #TB_BoxesCreated
            FROM #TempCreateBoxes AS TMB
            INNER JOIN [LCA].[dbo].[PackedItems]        AS PI WITH(NOLOCK) ON TMB.[ManufactureID] = PI.[ManufactureID]
            INNER JOIN [LCA].[dbo].[ManufactureOrders]  AS MO WITH(NOLOCK) ON TMB.[ManufactureID] = MO.[ManufactureID]
            GROUP BY
                 TMB.[MO]
                ,TMB.[ManufactureID]
                ,MO.[QuantityOrdered]

            UPDATE TBC SET
                [CanPack] = IIF([QtyPacked] - [Make] = 0,1,0)
            FROM #TB_BoxesCreated AS TBC

            SELECT
                 [MO]               = TMB.[MO]
                ,[ManufactureID]    = TMB.[ManufactureID]
                ,[BoxNumber]        = CONCAT('BOX4S',RC.[RawContainerID]+1000000)
                ,[BoxType]          = 'Caja de 12'
                ,[BoxWeight]        = 1.04
                ,[SKUNumber]        = FG.[SKUNumber]
                ,[Style]            = ST.[StyleNumber]
                ,[Color]            = STC.[StyleColorName]
                ,[Size]             = ODT.[GarmentSize]
                ,[Make]             = MO.[QuantityOrdered]
                ,[Qty]              = ABS(SUM(CT.[Quantity]))
                ,[BoxSerialNumber]  = RC.[ContainerCode]
                ,[BoxLabel]         = CONCAT(CAST(GETDATE() AS DATE),'-',RC.[ContainerCode] )
                ,[BoxComments]      = CONCAT(RC.[ContainerCode], ' - CREATED WITH THE RECEIVE CONTAINERS APP')
                ,[PartNumber_RC]    = RMC.[PartNumber]
                ,[PartNumber_ST]    = RMS.[PartNumber]
                ,[CanPack]          = CAST(NULL AS BIT)
                ,[ErrorPack]        = CAST(NULL AS NVARCHAR(MAX))
            INTO #TB_DataFinal
            FROM #TempCreateBoxes AS TMB
            INNER JOIN [LCA].[dbo].[ManufactureOrders]  AS MO   WITH(NOLOCK) ON TMB.[ManufactureID] = MO.[ManufactureID]
            INNER JOIN [LCA].[dbo].[RawTransactions]    AS RT   WITH(NOLOCK) ON MO.[ManufactureID] = RT.[ManufactureID]
            INNER JOIN [LCA].[dbo].[ContainerTransfers] AS CT   WITH(NOLOCK) ON RT.[RawTransactionID] = CT.[RawTransactionID]
            INNER JOIN [LCA].[dbo].[RawContainers]      AS RC   WITH(NOLOCK) ON CT.[RawContainerID] = RC.[RawContainerID]
            INNER JOIN [LCA].[dbo].[RawMaterials]       AS RMC  WITH(NOLOCK) ON RC.[RawMaterialID] = RMC.[RawMaterialID]
            INNER JOIN [LCA].[dbo].[OrderItems]         AS OI   WITH(NOLOCK) ON MO.[FirstOrderItemID] = OI.[OrderItemID]
            INNER JOIN [LCA].[dbo].[OrderDetails]       AS ODT  WITH(NOLOCK) ON ODT.[OrderItemID] = OI.[OrderItemID]
            INNER JOIN [LCA].[dbo].[Styles]             AS ST   WITH(NOLOCK) ON OI.[StyleID] = ST.[StyleID]
            INNER JOIN [LCA].[dbo].[StyleColors]        AS STC  WITH(NOLOCK) ON OI.[StyleColorID] = STC.[StyleColorID]
            LEFT  JOIN [LCA].[dbo].[StyleVariations]    AS STV  WITH(NOLOCK) ON RMC.[RawMaterialID] = STV.[RawMaterialID] AND STV.[StyleID] = OI.[StyleID] AND STV.[StyleColorID] = OI.[StyleColorID]
            LEFT  JOIN [LCA].[dbo].[RawMaterials]       AS RMS  WITH(NOLOCK) ON STV.[RawMaterialID] = RMS.[RawMaterialID]
            LEFT  JOIN [LCA].[dbo].[FinishedGoods]      AS FG   WITH(NOLOCK) ON ODT.[FinishedGoodsID] = FG.[FinishedGoodsID]
            GROUP BY
                 TMB.[ManufactureID]
                ,TMB.[MO]
                ,RC.[ContainerCode]
                ,RC.[RawContainerID]
                ,FG.[SKUNumber]
                ,ST.[StyleNumber]
                ,STC.[StyleColorName]
                ,ODT.[GarmentSize]
                ,MO.[QuantityOrdered]
                ,RMC.[PartNumber]
                ,RMS.[PartNumber]
                
            
            UPDATE TDF SET
                 [CanPack]      = IIF(TBC.[CanPack] = 0 OR [SKUNumber] IS NULL,0,1)
                ,[ErrorPack]    = CASE
                                    WHEN TBC.[CanPack] = 0 THEN 'There are no more goods to pack for the MO: ' + TDF.[MO] 
                                    WHEN [SKUNumber] IS NULL AND [PartNumber_RC] <> [PartNumber_ST] THEN 'SKU Number cannot be empty, Part Number of MO Materials and Part Number of 
                                    Style: ' + TDF.[Style] + ' and Color: ' + TDF.[Color] + ' are not the same'
                                    WHEN [SKUNumber] IS NULL AND [PartNumber_RC] = [PartNumber_ST] THEN 'SKUNumber cannot be empty, please check SKU for
                                    Style: ' + TDF.[Style] + ', Color: ' + TDF.[Color] + ' and Size: ' + TDF.[Size]
                                  END
            FROM #TB_DataFinal AS TDF
            LEFT JOIN #TB_BoxesCreated AS TBC ON TDF.[ManufactureID] = TBC.[ManufactureID]

            SET @result = (
                SELECT
                     [MONumber]         = [MO]
                    ,[BoxNumber]        = [BoxNumber]
                    ,[BoxType]          = [BoxType]
                    ,[Weight]           = [BoxWeight]
                    ,[SKUNumber]        = [SKUNumber]
                    ,[Quantity]         = [Qty]
                    ,[BoxSerialNumber]  = [BoxSerialNumber]
                    ,[BoxLabel]         = [BoxLabel]
                    ,[BoxComments]      = [BoxComments]
                    ,[CanPack]          = [CanPack]
                    ,[ErrorPack]        = [ErrorPack]
                FROM #TB_DataFinal
                ORDER BY [BoxNumber]
                FOR JSON PATH, INCLUDE_NULL_VALUES
            )

            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Datos generados correctamente'

            GOTO SELECTFINAL

        END

        IF @process = 'boxes-list'
        BEGIN

            DROP TABLE IF EXISTS #TempBoxesMO;

            SELECT
                 [MO]            = j.[MO]
                ,[ManufactureID] = j.[ManufactureID]
                ,[Boxes]         = CAST(NULL AS NVARCHAR(MAX))
            INTO #TempBoxesMO
            FROM OPENJSON(@data, '$.selectedOptions')
            WITH (
                 MO            NVARCHAR(200)   '$.MO'
                ,ManufactureID INT             '$.ManufactureID'
            ) AS j;

            UPDATE TB SET
                 [Boxes] = (
                                SELECT
                                     [BoxNumber] = PB.[BoxNumber]
                                    ,[QtyPacked] = SUM(PI.[Quantity])
                                    ,[Bin]       = GB.[Bin]
                                FROM #TempBoxesMO AS TBM
                                INNER JOIN [LCA].[dbo].[PackedItems] AS PI WITH(NOLOCK) ON TBM.[ManufactureID] = PI.[ManufactureID]
                                INNER JOIN [LCA].[dbo].[PackedBoxes] AS PB WITH(NOLOCK) ON PI.[PackedBoxID] = PB.[PackedBoxID]
                                LEFT  JOIN [LCA].[dbo].[GoodsBins]   AS GB WITH(NOLOCK) ON PB.[GoodsBinID] = GB.[GoodsBinID]
                                WHERE PI.[ManufactureID] = TB.[ManufactureID]
                                GROUP BY
                                     PB.[BoxNumber]
                                    ,GB.[Bin]
                                FOR JSON PATH, INCLUDE_NULL_VALUES
                            )
            FROM #TempBoxesMO AS TB

            SET @result = (
                SELECT
                     [MO]
                    ,[ManufactureID]
                    ,[Boxes]
                FROM #TempBoxesMO
                ORDER BY [ManufactureID]
                FOR JSON PATH, INCLUDE_NULL_VALUES
            )
            
            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Datos generados correctamente'

            GOTO SELECTFINAL

        END

        IF @process = 'bins-list'
        BEGIN

            DROP TABLE IF EXISTS #WH_DATA
            DROP TABLE IF EXISTS #WH_DATA_BINS
            DROP TABLE IF EXISTS #WH_DATA_BINS_Quantity
            DROP TABLE IF EXISTS #TempWarehouseMO;

            SELECT
                 [MO]            = j.[MO]
                ,[ManufactureID] = j.[ManufactureID]
            INTO #TempWarehouseMO
            FROM OPENJSON(@data, '$.selectedOptions')
            WITH (
                 MO            NVARCHAR(200)   '$.MO'
                ,ManufactureID INT             '$.ManufactureID'
            ) AS j;
    
            SELECT DISTINCT
                 [WarehouseID]      = WH.[WarehouseID]
                ,[WarehouseName]    = REPLACE(REPLACE(WH.[WarehouseName],CHAR(10),''),CHAR(13),'')
            INTO #WH_DATA
            FROM #TempWarehouseMO                           AS TWM
            INNER JOIN [LCA].[dbo].[ManufactureOrders]  AS MO WITH(NOLOCK) ON TWM.[ManufactureID] = MO.[ManufactureID]
            INNER JOIN [LCA].[dbo].[Warehouses]         AS WH WITH(NOLOCK) ON MO.[WarehouseID] = WH.[WarehouseID]
            

            SELECT
                 [R]                = ROW_NUMBER() OVER(ORDER BY FIL.[WarehouseName], GB.[Bin])
                ,[WarehouseID]      = FIL.[WarehouseID]
                ,[WarehouseName]    = FIL.[WarehouseName]
                ,[GoodsBinID]       = GB.[GoodsBinID]
                ,[Bin]              = GB.[Bin]
                ,[Rack]             = CAST(NULL AS VARCHAR(50))
            INTO #WH_DATA_BINS
            FROM #WH_DATA AS FIL
            INNER JOIN [LCA].[dbo].[Warehouses] AS WH WITH(NOLOCK) ON FIL.[WarehouseID] = WH.[WarehouseID]
            INNER JOIN [LCA].[dbo].[GoodsBins]  AS GB WITH(NOLOCK) ON WH.[WarehouseID] = GB.[WarehouseID]
                                                                    AND GB.[StatusID] = 30
            -- WHERE WH.WarehouseID = 53
            
            
            UPDATE S SET 
                [Rack] = CASE 
                            ----DLI BLOCK N
                            WHEN S.WarehouseID=60 AND LEFT(S.Bin,2) IN (
                                                    'NA'
                                                    ,'NB'
                                                    ,'NC'
                                                    ,'ND'
                                                    ,'NE'
                                                    ,'NF'
                                                )
                            THEN LEFT(S.Bin,2)
                            WHEN S.WarehouseID=60 THEN 'Floor'
                            
                            ----Stock Warehose
                            WHEN S.WarehouseID=35 AND LEFT(S.Bin,2) IN (
                                                     'AF','AB'
                                                    ,'BF','BB'
                                                    ,'CF','CB'
                                                    ,'DF','DB'
                                                    ,'EF','EB'
                                                    ,'FF','FB'
                                                    ,'GF','GB'
                                                    ,'HF','HB'
                                                    ,'IF','IB'
                                                    ,'JF','JB'
                                                    ,'KF','KB'
                                                    ,'LF','LB'
                                                    ,'ZF','ZB'
                                                )
                            THEN LEFT(S.Bin,1)
                            WHEN S.WarehouseID=35 THEN 'Floor'
                            
                            ----Headwear DLI
                            WHEN S.WarehouseID=53 AND LEFT(S.Bin ,3) = 'REC' THEN 'Floor'
                            WHEN S.WarehouseID=53 AND LEFT(S.Bin,1) IN (
                                                     'A'
                                                    ,'B'
                                                    ,'C'
                                                    ,'D'
                                                    ,'E'
                                                    ,'F'
                                                ) THEN LEFT(S.Bin,1)
                            ELSE 'Floor' END
            FROM #WH_DATA_BINS AS S

            SET @result = (
                SELECT
                     [WarehouseName] = [WarehouseName]
                    ,[Bin]           = [Bin]
                    ,[GoodsBinID]    = [GoodsBinID]
                FROM #WH_DATA_BINS
                WHERE [Rack] = 'FLOOR'
                FOR JSON PATH, INCLUDE_NULL_VALUES
            )

            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Datos generados correctamente'

            GOTO SELECTFINAL
            

        END

        IF @process = 'move-boxes-bin'
        BEGIN

            DROP TABLE IF EXISTS #TempMoveBoxes;
            SELECT
                 [MO]            = j.[MO]
                ,[ManufactureID] = j.[ManufactureID]
                ,[BoxNumber]     = j.[BoxNumber]
                ,[Qty]           = ISNULL(j.[QtyPacked], 0)
                ,[Bin]           = j.[Bin]
                ,[GoodsBinID]    = j.[GoodsBinID]
            INTO #TempMoveBoxes
            FROM OPENJSON(@data, '$.selectedOptions')
            WITH (
                 MO            NVARCHAR(200)   '$.MO'
                ,ManufactureID INT             '$.ManufactureID'
                ,BoxNumber     NVARCHAR(200)   '$.BoxNumber'
                ,QtyPacked     FLOAT           '$.QtyPacked'
                ,Bin           NVARCHAR(200)   '$.Bin'
                ,GoodsBinID    INT             '$.GoodsBinID'
            ) AS j;

            DECLARE @BarcodeBin     VARCHAR(200)
            DECLARE @BoxNumber      VARCHAR(200)
            DECLARE @FechaHoyBin    CHAR(8)
            DECLARE @HoraHoyBin     CHAR(7)

            SET @BarcodeBin    = CONCAT('PPGB', CAST(CAST(JSON_VALUE(@data, '$.selectedOptions[0].GoodsBinID') AS INT) + 1000000 AS VARCHAR(20)))
            SET @BoxNumber     = JSON_VALUE(@data, '$.selectedOptions[0].BoxNumber')
            SET @FechaHoyBin   = FORMAT(GETDATE(), 'yyyyMMdd')
            SET @HoraHoyBin    = FORMAT(GETDATE(), 'HHmmssf')


            SET @Datos              = CONCAT('BIN,',@BarcodeBin,',',@FechaHoyBin,',',@HoraHoyBin,',1,','MVBX,',@BoxNumber)
            SET @DatosEnviarAPI= @Datos
    
            --DECLARE @flagJson AS BIT
            --DECLARE @responsePPM AS NVARCHAR(MAX)
            --DECLARE @jsonResponse AS NVARCHAR(MAX)
            --DECLARE @FinalComponent AS NVARCHAR(MAX)

            --- Ejecutar el procedimiento almacenado y capturar el resultado JSON en una variable de salida
            EXEC [AppsLCA].[dbo].[SP_Barcode_TransactionAPI] 
            --EXEC [192.168.1.93].[AppsLCA].[dbo].[SP_Barcode_TransactionAPI] 
                @VarTransaction = @DatosEnviarAPI, --'BOX,PPMB1606768,20250214,1325890,1,TBUQ,PPBX11441940,PPFG1196505,1',
                @jsonResponse = @jsonResponse OUTPUT

            --- Extraer los valores del JSON de salida
            SET @message = JSON_VALUE(@jsonResponse, '$[0].MessagePPM')
            SET @Error = IIF(JSON_VALUE(@jsonResponse, '$[0].FlagCompleted') = 'true',0,1)
            SET @Component = JSON_VALUE(@jsonResponse, '$[0].FinalComponent')

            IF @Error = 0
            BEGIN

                SET @result = (
                    SELECT
                         [MO]            = [MO]
                        ,[ManufactureID] = [ManufactureID]
                        ,[BoxNumber]     = [BoxNumber]
                        ,[QtyPacked]     = [Qty]
                        ,[Bin]           = [Bin]
                    FROM #TempMoveBoxes
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                )

            END

            GOTO SELECTFINAL

        END

        IF @process = 'mo-workflow'
        BEGIN
            
            DROP TABLE IF EXISTS #TempPOsMO

            SELECT
                 [PO] = j.[PO]
            INTO #TempPOsMO
            FROM OPENJSON(@data, '$.selectedOptions')
            WITH (PO NVARCHAR(200) '$.PO') AS j;

            SET @result = (

                SELECT
                    [PO]                   = TPO.[PO]
                    ,[ManufactureNumber]    = MO.[ManufactureNumber]
                    ,[ManufactureID]        = MO.[ManufactureID]
                    ,[TaskID]               = WT.[TaskID]
                    ,[TaskName]             = WT.[TaskName]
                    ,[PPAD]                 = CASE
                                                WHEN WT.[TaskName] = 'Create Bundles' THEN 'PPAD48074'
                                                WHEN WT.[TaskName] = 'Receiving Finish Good in Warehouse' THEN 'PPAD48075'
                                                ELSE ''
                                              END
                    -- ,[TaskBarcode]          = CONCAT('PPTK',CAST(WT.[TaskID]+10000000 AS VARCHAR(100)))
                -- INTO #TB_MO_Workflow
                FROM #TempPOsMO                             AS TPO
                LEFT  JOIN [LCA].[dbo].[Orders]             AS OD  WITH(NOLOCK) ON OD.[PONumber] LIKE '%' + TPO.[PO] + '%'
                INNER JOIN [LCA].[dbo].[ManufactureOrders]  AS MO  WITH(NOLOCK) ON MO.[OrderID] = OD.[OrderID] AND MO.[StatusID] < 90
                INNER JOIN [LCA].[dbo].[WorkFlows]          AS WF  WITH(NOLOCK) ON WF.[ManufactureID] = MO.[ManufactureID]
                INNER JOIN [LCA].[dbo].[WorkTasks]          AS WT  WITH(NOLOCK) ON WF.[WorkFlowID] = WT.[WorkFlowID]
                ORDER BY MO.[ManufactureID]
                FOR JSON PATH, INCLUDE_NULL_VALUES
            )

            SET @Error = 0
            SET @Component = '[200]'
            SET @message = 'Datos generados correctamente'

            GOTO SELECTFINAL

        END

        IF @process = 'transaction-workflow'
        BEGIN

            DROP TABLE IF EXISTS #TempMoveWF;

            SELECT
                 [MO]            = j.[MO]
                ,[ManufactureID] = j.[ManufactureID]
                ,[PO]            = j.[PO]
                ,[TaskID]        = j.[TaskID]
                ,[TaskName]      = j.[TaskName]
                ,[PPAD]          = j.[PPAD]
            INTO #TempMoveWF
            FROM OPENJSON(@data, '$.selectedOptions')
            WITH (
                 MO            VARCHAR(200)   '$.ManufactureNumber'
                ,ManufactureID INT            '$.ManufactureID'
                ,PO            VARCHAR(200)   '$.PO'
                ,TaskID        INT            '$.TaskID'
                ,TaskName      VARCHAR(200)   '$.TaskName'
                ,PPAD          VARCHAR(200)   '$.PPAD'
            ) AS j;

            DECLARE @BarcodeTask    VARCHAR(200)
            DECLARE @BarcodePPAD    VARCHAR(200)
            DECLARE @FechaHoyWF     CHAR(8)
            DECLARE @HoraHoyWF      CHAR(7)

            SET @BarcodeTask   = CONCAT('PPTK', CAST(CAST(JSON_VALUE(@data, '$.selectedOptions[0].TaskID') AS INT) + 10000000 AS VARCHAR(20)))
            SET @BarcodePPAD   = JSON_VALUE(@data, '$.selectedOptions[0].PPAD')
            SET @FechaHoyWF    = FORMAT(GETDATE(), 'yyyyMMdd')
            SET @HoraHoyWF     = FORMAT(GETDATE(), 'HHmmssf')


            SET @Datos              = CONCAT('OPR,',@FechaHoyWF,',',@HoraHoyWF,',1,',@BarcodePPAD,',CTSK,',@BarcodeTask)
            SET @DatosEnviarAPI= @Datos
    
            -- SELECT @DatosEnviarAPI 
            --DECLARE @flagJson AS BIT
            --DECLARE @responsePPM AS NVARCHAR(MAX)
            --DECLARE @jsonResponse AS NVARCHAR(MAX)
            --DECLARE @FinalComponent AS NVARCHAR(MAX)

            --- Ejecutar el procedimiento almacenado y capturar el resultado JSON en una variable de salida
            EXEC [AppsLCA].[dbo].[SP_Barcode_TransactionAPI] 
            --EXEC [192.168.1.93].[AppsLCA].[dbo].[SP_Barcode_TransactionAPI] 
                @VarTransaction = @DatosEnviarAPI, --'BOX,PPMB1606768,20250214,1325890,1,TBUQ,PPBX11441940,PPFG1196505,1',
                @jsonResponse = @jsonResponse OUTPUT

            --- Extraer los valores del JSON de salida
            SET @message = JSON_VALUE(@jsonResponse, '$[0].MessagePPM')
            SET @Error = IIF(JSON_VALUE(@jsonResponse, '$[0].FlagCompleted') = 'true',0,1)
            SET @Component = JSON_VALUE(@jsonResponse, '$[0].FinalComponent')

            IF @Error = 0
            BEGIN

                SET @result = (
                    SELECT
                         [MO]            = [MO]
                        ,[ManufactureID] = [ManufactureID]
                        ,[TaskName]      = [TaskName]
                        ,[TaskID]        = [TaskID]
                        ,[PPAD]          = [PPAD]
                    FROM #TempMoveWF
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                )

            END

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
