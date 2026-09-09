USE AppsLCA
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_Shipping_ValidateItemDetailID_In_Waybill]
     @process VARCHAR(MAX)  = 'validate-wo'
    ,@data    NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON

    -- DECLARE @process VARCHAR(MAX) = 'validate-wo'
    -- DECLARE @data NVARCHAR(MAX) = '[
    --   {
    --     "WayBill": "AIR-APP-20260904",
    --     "ItemDetailID": 6115488,
    --     "Order": "695670",
    --     "ManufactureID": 1024515
    --   }
    -- ]'


    DROP TABLE IF EXISTS #TB_WaybillWO
    DROP TABLE IF EXISTS #TB_Validation
    DROP TABLE IF EXISTS #TB_Count_Containers_ItemDetail

    IF @process = 'validate-wo'
    BEGIN

      SELECT
          WayBill,
          ItemDetailID,
          [Order],
          [ManufactureID]
      INTO #TB_WaybillWO
      FROM OPENJSON(@data)
      WITH (
          WayBill             VARCHAR(100) '$.WayBill',
          ItemDetailID        INT          '$.ItemDetailID',
          [Order]             VARCHAR(50)  '$.Order',
          [ManufactureID]     INT          '$.ManufactureID'
      )

      -- Ya aprobadas (por bodega e IT): no se vuelven a validar
      DELETE TW
      FROM #TB_WaybillWO AS TW
      WHERE EXISTS (
          SELECT 1
          FROM [AppsLCA].[dbo].[TB_PackingData_OrdersApproved] AS APR
          WHERE APR.[ItemDetailID] = TW.[ItemDetailID]
            AND APR.[ApprovedBy_Code]    IS NOT NULL
            AND APR.[ApprovedBy_Code_IT] IS NOT NULL
      )

      SELECT
          Waybill            = TW.Waybill
          ,ItemDetailID       = TW.ItemDetailID
          ,[Order]            = TW.[Order]
          ,[OrderID]          = OD.[OrderID]
          ,[ManufactureID]    = TW.ManufactureID
          ,[FinishedGoodsID]  = ODT.[FinishedGoodsID]
          ,[Size]             = ODT.[GarmentSize]
          ,[RequestQty]       = SUM(CAST(ODT.RequestCount AS INT))
          ,[PackedQty]        = CAST(NULL AS INT)
          ,[CorrectQty]       = CAST(NULL AS BIT)
          ,[MultiContainer]   = CAST(NULL AS BIT)
          ,[Containers]       = CAST(NULL AS VARCHAR(200))
          ,[Comment]          = CAST(NULL AS VARCHAR(500))
          ,[PendingITApproval]= CAST(0 AS BIT)
      INTO #TB_Validation
      FROM #TB_WaybillWO AS TW
      INNER JOIN LCA.dbo.Orders            AS OD  WITH(NOLOCK) ON TW.[Order] = OD.OrderNumber AND OD.StatusID <= 90
      INNER JOIN LCA.dbo.OrderDetails      AS ODT WITH(NOLOCK) ON ODT.OrderID = OD.OrderID AND ODT.RequestCount > 0
      GROUP BY
          TW.Waybill
          ,TW.ItemDetailID
          ,TW.[Order]
          ,OD.[OrderID]
          ,TW.ManufactureID
          ,ODT.[FinishedGoodsID]
          ,ODT.[GarmentSize]

      -- Ya enviadas a aprobación (approve-wo) pero aún esperando a IT: se siguen validando/mostrando,
      -- pero se marcan para que el frontend no vuelva a ofrecer el botón de aprobar
      UPDATE TV SET
          [PendingITApproval] = 1
      FROM #TB_Validation AS TV
      WHERE EXISTS (
          SELECT 1
          FROM [AppsLCA].[dbo].[TB_PackingData_OrdersApproved] AS APR
          WHERE APR.[ItemDetailID]     = TV.[ItemDetailID]
            AND APR.[Waybill]          = TV.[Waybill]
            AND APR.[ApprovedBy_Code] IS NOT NULL
            AND APR.[ApprovedBy_Code_IT] IS NULL
      )

      UPDATE T SET
          PackedQty = qtyPacked
      FROM #TB_Validation AS T
      INNER JOIN
      (
        SELECT
          OrderID
          ,FinishedGoodsID
          ,qtyPacked = sum(qtyPacked)
        FROM
        (
          SELECT
              tv.OrderID
              ,PI.FinishedGoodsID
              ,[Size]
              ,SUM(Quantity) AS qtyPacked
          FROM #TB_Validation AS TV
          INNER JOIN LCA.dbo.PackedBoxes AS PB WITH(NOLOCK) ON TV.[OrderID] = PB.[OrderID] AND PB.[StatusID] = 75
          INNER JOIN LCA.dbo.Shipments   AS SH WITH(NOLOCK) ON PB.[ShipmentID] = sh.[ShipmentID] and SH.[WayBill] = TV.[Waybill]--AND PB.WarehouseID = 8
          INNER JOIN LCA.dbo.PackedItems AS PI WITH(NOLOCK) ON PB.[PackedBoxID] = PI.[PackedBoxID] AND TV.[FinishedGoodsID] = PI.[FinishedGoodsID]
          GROUP BY
              tv.OrderID
              ,PI.FinishedGoodsID
              ,[Size]

          UNION ALL

          SELECT
              tv.OrderID
              ,TV.FinishedGoodsID
              ,[Size]
              ,SUM(DM.Quantity) AS qtyPacked
          FROM #TB_Validation AS TV
          INNER JOIN LCA.dbo.ManufactureDetails AS MD WITH(NOLOCK) ON TV.ManufactureID = MD.ManufactureID
          INNER JOIN LCA.dbo.Damages            AS DM WITH(NOLOCK) ON MD.ManufactureDetailID = DM.ManufactureDetailID AND TV.FinishedGoodsID = DM.FinishedGoodsID
          GROUP BY
              tv.OrderID
              ,TV.FinishedGoodsID
              ,[Size]
        ) AS B
        GROUP BY
           OrderID
          ,FinishedGoodsID
      ) AS TV ON T.OrderID = TV.OrderID AND TV.FinishedGoodsID = T.FinishedGoodsID

      UPDATE TV SET
          CorrectQty = IIF(PackedQty >= RequestQty,1,0)
          ,Comment    = IIF(PackedQty >= RequestQty,NULL,'Units packed does not match Order Requested')
      FROM #TB_Validation AS TV

      UPDATE TV SET
        [RequestQty] = OE.[Qty]
      FROM #TB_Validation AS TV
      INNER JOIN AppsLCA.legacycaps.VW_view_qryLCA_Order_Export AS OE WITH(NOLOCK) ON TV.[ItemDetailID] = OE.[ItemDetailID] AND TV.[Size] = OE.[Size] AND TV.[CorrectQty] = 0

      UPDATE TV SET
        [RequestQty] = Logs.[Qty]
      FROM #TB_Validation AS TV
      INNER JOIN 
      (
        SELECT
             [ItemDetailID] = OE.[ItemDetailID]
            ,[Size]         = OE.[Size]
            ,[Qty]          = OE.[Qty]
            ,[R]            = ROW_NUMBER() OVER(PARTITION BY OE.[ItemDetailID] ORDER BY OE.[Insert_Time] DESC)
        FROM #TB_Validation AS TV
        INNER JOIN [192.168.1.93].AppsLCA.legacycaps.VW_view_qryLCA_Order_Export_Logs AS OE WITH(NOLOCK) ON TV.[ItemDetailID] = OE.[ItemDetailID] AND TV.[Size] = OE.[Size] AND TV.[CorrectQty] = 0
      )AS Logs ON TV.[ItemDetailID] = Logs.[ItemDetailID] AND TV.[Size] = Logs.[Size] AND Logs.[R] = 1 AND TV.[CorrectQty] = 0 

      UPDATE TV SET
          CorrectQty = IIF(PackedQty >= RequestQty,1,0)
          ,Comment    = IIF(PackedQty >= RequestQty,NULL,'Units packed does not match Order Requested')
      FROM #TB_Validation AS TV
      WHERE CorrectQty = 0

      SELECT
          [ItemDetailID]
          ,[CountContainers] = COUNT( DISTINCT COALESCE(SC.[ShippingContainerID],0))
          ,[Containers]      = STRING_AGG(Containers,',')
      INTO #TB_Count_Containers_ItemDetail
      FROM
      (
          SELECT
              [ItemDetailID]
              ,[ShippingContainerID]  = SC.[ShippingContainerID]
              ,[Containers]           = SC.[ContainerNumber]
          FROM #TB_Validation 					AS TV
          INNER JOIN LCA.dbo.PackedItems          AS PI   WITH(NOLOCK) ON TV.[ManufactureID] = PI.[ManufactureID] AND TV.[FinishedGoodsID] = PI.[FinishedGoodsID]
          INNER JOIN LCA.dbo.PackedBoxes			AS PB	WITH(NOLOCK) ON TV.[OrderID] = pb.[OrderID] AND PI.[PackedBoxID] = PB.[PackedBoxID]
          LEFT  JOIN LCA.dbo.Shipments			AS SH	WITH(NOLOCK) ON PB.[ShipmentID] = SH.[ShipmentID]
          LEFT  JOIN LCA.dbo.ShippingContainers	AS SC	WITH(NOLOCK) ON SH.[ShippingContainerID] = SC.[ShippingContainerID]
          WHERE [ItemDetailID] IS NOT NULL AND SH.[ShippingContainerID] IS NOT NULL --OR TDP.PONumber = 'ORD-5719661'
          GROUP BY
              [ItemDetailID]
              ,SC.[ShippingContainerID]
              ,SC.[ContainerNumber]
      ) AS SC
      GROUP BY
          [ItemDetailID]

      UPDATE TV SET
          MultiContainer = IIF(TC.CountContainers > 1,1,0)
          ,Containers     = IIF(TC.CountContainers > 1,TC.Containers,NULL)
          ,Comment        = IIF(TC.CountContainers > 1,
                            CASE
                              WHEN Comment IS NOT NULL THEN CONCAT(Comment,'/ Work Order in Multiple Containers')
                              ELSE 'Work Order in Multiple Containers'
                            END
                            ,Comment)
      FROM #TB_Validation AS TV
      INNER JOIN #TB_Count_Containers_ItemDetail AS TC ON TV.ItemDetailID = TC.ItemDetailID

      SELECT
          [Result] = (
              SELECT *
              FROM #TB_Validation
              WHERE Comment IS NOT NULL
              FOR JSON PATH, INCLUDE_NULL_VALUES
          )

    END

    IF @process = 'approve-wo'
    BEGIN

        DROP TABLE IF EXISTS #TB_ApproveWO

        SELECT
            ItemDetailID,
            MO,
            Style,
            Color,
            Size,
            Qty,
            Waybill,
            [User],
            Pin,
            ReasonID,
            Comment
        INTO #TB_ApproveWO
        FROM OPENJSON(@data, '$.selectedOrders')
        WITH (
            ItemDetailID    INT             '$.ItemDetailID',
            MO              VARCHAR(100)    '$.MO',
            Style           VARCHAR(100)    '$.Style',
            Color           VARCHAR(100)    '$.Color',
            Size            VARCHAR(50)     '$.Size',
            Qty            VARCHAR(50)      '$.Qty',
            Waybill         VARCHAR(100)    '$.Waybill',
            [User]          VARCHAR(50)     '$.User',
            Pin             VARCHAR(50)     '$.Pin',
            ReasonID        INT             '$.ReasonID',
            Comment         VARCHAR(500)    '$.Comment'
        )

        DECLARE @ApproveUser VARCHAR(50)
        DECLARE @ApprovePin  VARCHAR(50)

        SELECT TOP 1
             @ApproveUser = [User]
            ,@ApprovePin  = Pin
        FROM #TB_ApproveWO

        IF NOT EXISTS (
            SELECT 1
            FROM [AppsLCA].[dbo].[PID_InventoryUsers]
            WHERE [user] = @ApproveUser
              AND [pin]  = @ApprovePin
              AND approveWOShip = 1
              AND [status] = 1
        )
        BEGIN
            SELECT
                [Result] = (
                    SELECT
                        [Error]   = CAST(1 AS BIT),
                        [Message] = 'Invalid credentials or insufficient permissions.'
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                )
            RETURN
        END

        INSERT INTO [AppsLCA].[dbo].[TB_PackingData_OrdersApproved]
        (
            [ReasonsToApprove_id],
            [CommentError],
            [ItemDetailID],
            [MO],
            [Style],
            [Color],
            [Size],
            [Qty],
            [Waybill],
            [ApprovedBy_Code]
        )
        SELECT
            ReasonID,
            Comment,
            ItemDetailID,
            MO,
            Style,
            Color,
            Size,
            Qty,
            Waybill,
            [User]
        FROM #TB_ApproveWO

        SELECT
            [Result] = (
                SELECT
                    [Error]   = CAST(0 AS BIT),
                    [Message] = 'WO saved! Awaiting IT approval'
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            )

    END

    IF @process = 'approve-IT'
    BEGIN

        DROP TABLE IF EXISTS #TB_ApproveIT

        SELECT
            ItemDetailID,
            Style,
            Color,
            Size,
            Waybill,
            [User],
            Pin
        INTO #TB_ApproveIT
        FROM OPENJSON(@data, '$.selectedOrders')
        WITH (
            ItemDetailID    INT             '$.ItemDetailID',
            Style           VARCHAR(100)    '$.Style',
            Color           VARCHAR(100)    '$.Color',
            Size            VARCHAR(50)     '$.Size',
            Waybill         VARCHAR(100)    '$.Waybill',
            [User]          VARCHAR(50)     '$.User',
            Pin             VARCHAR(50)     '$.Pin'
        )

        DECLARE @ApproveITUser VARCHAR(50)
        DECLARE @ApproveITPin  VARCHAR(50)

        SELECT TOP 1
             @ApproveITUser = [User]
            ,@ApproveITPin  = Pin
        FROM #TB_ApproveIT

        IF NOT EXISTS (
            SELECT 1
            FROM [AppsLCA].[dbo].[PID_InventoryUsers]
            WHERE [user] = @ApproveITUser
              AND [pin]  = @ApproveITPin
              AND approveWOShipIT = 1
              AND [status] = 1
        )
        BEGIN
            SELECT
                [Result] = (
                    SELECT
                        [Error]   = CAST(1 AS BIT),
                        [Message] = 'Invalid credentials or insufficient permissions.'
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                )
            RETURN
        END

        UPDATE OA SET
            [ApprovedBy_Code_IT] = @ApproveITUser
        FROM [AppsLCA].[dbo].[TB_PackingData_OrdersApproved] AS OA
        INNER JOIN #TB_ApproveIT AS AIT
            ON OA.[ItemDetailID] = AIT.[ItemDetailID]
           AND OA.[Style]        = AIT.[Style]
           AND OA.[Color]        = AIT.[Color]
           AND OA.[Size]         = AIT.[Size]
           AND OA.[Waybill]      = AIT.[Waybill]

        SELECT
            [Result] = (
                SELECT
                    [Error]   = CAST(0 AS BIT),
                    [Message] = 'WO Approved by IT'
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            )

    END

    IF @process = 'wo-waiting-approve'
    BEGIN

        -- @data admite: NULL (sin filtro, trae todo), {"Waybill":"X"} (un waybill),
        -- o {"Waybills":["X","Y"]} (varios waybills)
        DECLARE @WaybillFilter     VARCHAR(100) = JSON_VALUE(@data, '$.Waybill')
        DECLARE @WaybillFilterList NVARCHAR(MAX) = JSON_QUERY(@data, '$.Waybills')

        SELECT
            [Result] = (
                SELECT
                     OA.[Waybill]
                    ,OA.[ItemDetailID]
                    ,OA.[MO]
                    ,OA.[Style]
                    ,OA.[Color]
                    ,OA.[Size]
                    ,OA.[Qty]
                    ,OA.[CommentError]
                    ,[Reason] = R.[Reason]
                FROM [AppsLCA].[dbo].[TB_PackingData_OrdersApproved] AS OA WITH(NOLOCK)
                LEFT JOIN [AppsLCA].[dbo].[TB_PackingData_ResonsToApprove] AS R WITH(NOLOCK) ON R.[ID] = OA.[ReasonsToApprove_id]
                WHERE (OA.[ApprovedBy_Code_IT] IS NULL OR OA.[ApprovedBy_Code_IT] = '')
                AND OA.[ApprovedBy_Code] IS NOT NULL
                AND (@WaybillFilter IS NULL OR OA.[Waybill] = @WaybillFilter)
                AND (@WaybillFilterList IS NULL OR OA.[Waybill] IN (SELECT [value] FROM OPENJSON(@WaybillFilterList)))
                FOR JSON PATH, INCLUDE_NULL_VALUES
            )

    END
END
GO

/*
-- Ejemplo de ejecución

EXEC [dbo].[SP_Shipping_ValidateItemDetailID_In_Waybill] @process = @process, @data = @data
*/
