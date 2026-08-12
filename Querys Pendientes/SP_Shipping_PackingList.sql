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
    -- SET @data = REPLACE(@data,'/','');
    DECLARE @DateFrom AS DATE
    DECLARE @DateTo AS DATE


    --------------- PRUEBAS PROCEDIMIENTO ------------------
    -- SET @process = 'export.dates'
    -- SET @data = '{"selectedDates":[{"DateFrom":"2026-08-12","DateTo":"2026-08-12"}]}'

    -- SET @process = 'packinglist.waybills'
    -- SET @data = '{"selectedOptions":[{"R":1,"Waybill":"AIR-APP-20260812","ShipDate":"2026-08-12"},{"R":2,"Waybill":"AIR-HW-20260812","ShipDate":"2026-08-12"},{"R":4,"Waybill":"HW-20260812","ShipDate":"2026-08-12"},{"R":3,"Waybill":"APP-20260812","ShipDate":"2026-08-12"}]}'
    BEGIN TRY

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1. Sección de Eliminación de tablas temporales
        -------------------------------------------------------------------------------------------------------------------------------------------------------
            DROP TABLE IF EXISTS #TB_PL_RAW
            DROP TABLE IF EXISTS #TB_PL_Waybills
        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1. Sección de Eliminación de tablas temporales
        -------------------------------------------------------------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2. Creación de tabla temporal compartida (mismo esquema que la vista origen, sin filas)
        -------------------------------------------------------------------------------------------------------------------------------------------------------
            SELECT TOP (0)
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
                    ,[L2Order]
                    ,[Box]              = CAST(NULL AS INT)
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

            CREATE NONCLUSTERED INDEX IX_PL_RAW ON #TB_PL_RAW ([Waybill])

        IF @process = 'export.dates'
        BEGIN
            SELECT
                @DateFrom = CAST(JSON_VALUE(@data, '$.selectedDates[0].DateFrom') AS DATE)
                ,@DateTo  = CAST(JSON_VALUE(@data, '$.selectedDates[0].DateTo')   AS DATE)

            INSERT INTO #TB_PL_RAW (
                     [Waybill],[Skid],[ItemCode],[Style],[Color],[ColorGreatPlain],[Size],[Qty],[XX],[OrderNo]
                    ,[L2Order],[Box],[Fact],[Gender],[Location],[Note]
                    ,[TrackingNumber],[BoxNo],[ColorPolyPM],[Price],[TotalPrices],[InvoiceDate]
            )
            SELECT
                'Waybill'			= sh.[WayBill]
                ,'Skid'				= COALESCE(gb.[Bin],'0')     -- ver hallazgo arriba: el CASE original no cambiaba el resultado
                ,'ItemCode'			= CASE
                                            WHEN L2B_LCA.InvItemNo IS NOT NULL THEN L2B_LCA.InvItemID
                                            WHEN fg.[garmentsize] = 'XS'  THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'A' + '-' + fg.[garmentsize]
                                            WHEN fg.[garmentsize] = 'S'   THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'B' + '-' + fg.[garmentsize]
                                            WHEN fg.[garmentsize] = 'M'   THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'C' + '-' + fg.[garmentsize]
                                            WHEN fg.[garmentsize] = 'QTY' THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'C-M'
                                            WHEN fg.[garmentsize] = 'L'   THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'D' + '-' + fg.[garmentsize]
                                            WHEN fg.[garmentsize] = 'XL'  THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'E' + '-' + fg.[garmentsize]
                                            WHEN fg.[garmentsize] = '2XL' THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'F' + '-' + fg.[garmentsize]
                                            WHEN fg.[garmentsize] = '3XL' THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'G' + '-' + fg.[garmentsize]
                                            WHEN fg.[garmentsize] = '4XL' THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'H' + '-' + fg.[garmentsize]
                                        END
                ,'Style'			= sti.[stylenumber]
                ,'Color'			= stc.[StyleColorDescription]
                ,'ColorGreatPlain'	= stc.[stylecolorname]
                ,'Size'				= CASE WHEN fg.[garmentsize] = 'QTY' THEN 'M' ELSE fg.[garmentsize] END
                ,'Qty'				= pbi.[quantity]
                ,'XX'				= ''
                ,'OrderNo'			= od.[ponumber]
                ,'L2Order'			= od.[Comments6]
                ,'Box'				= ''
                ,'Fact'				= RIGHT(inb.[invoicebatch],4)
                ,'Gender'			= hts.[ca_htsdescription]
                ,'Location'			= CASE
                                            WHEN ddv2ot.[DropDownValue] = 'Miami, FL 33182' THEN 'Account'
                                            WHEN ddv2ot.[DropDownValue] = 'Hanover' AND LEFT(od.[ponumber], 3) = 'ORD' THEN 'Printed to Hanover'
                                            ELSE ddv2ot.[DropDownValue]
                                        END
                ,'Note'				= ''
                ,'TrackingNumber'	= CASE
                                            WHEN ddv2ot.[DropDownValue] = 'Miami, FL 33182' THEN pb.[BoxComments6]
                                            WHEN ddv2ot.[DropDownValue] = 'Hanover' AND LEFT(od.[ponumber], 3) = 'ORD' THEN ''
                                            ELSE ''
                                        END
                ,'BoxNo'			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL AND bxt.[DropDownValue] IS NOT NULL
                                            ,CONCAT('PPPA'+LTRIM(STR(pb.[packedpalletid]+1000000)),'-',RIGHT(bxt.[DropDownValue],3))
                                            ,pb.[boxnumber]
                                        )
                ,'ColorPolyPM'		= stc.[stylecolorname]
                ,'Price'			= CASE
                                            WHEN SCPD.[id] IS NOT NULL	THEN (SCPD.[TotalBlank] + SCPD.[TotalDecoration])
                                            ELSE oi2.[unitprice]
                                        END
                ,'TotalPrices'		= CAST(pbi.[quantity] AS DECIMAL(10,2)) * CAST((
                                            CASE
                                                WHEN SCPD.[id] IS NOT NULL	THEN (SCPD.[TotalBlank] + SCPD.[TotalDecoration])
                                                ELSE oi2.[unitprice]
                                            END
                                        ) AS DECIMAL(10,2))
                ,'InvoiceDate'		= sc.[ShipDate]
            FROM		LCA.dbo.packedboxes						AS pb	WITH(NOLOCK)
            INNER JOIN	LCA.dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid
            INNER JOIN	LCA.dbo.ShippingContainers				AS sc	WITH(NOLOCK)	ON sc.ShippingContainerID	= sh.ShippingContainerID
            AND sc.ShipDate >= @DateFrom AND sc.ShipDate <= @DateTo
            INNER JOIN	LCA.dbo.packeditems						AS pbi	WITH(NOLOCK)	ON pbi.packedboxid			= pb.packedboxid	AND pbi.quantity > 0
            INNER JOIN	LCA.dbo.finishedgoods					AS fg	WITH(NOLOCK)	ON pbi.finishedgoodsid		= fg.finishedgoodsid
            INNER JOIN	LCA.dbo.styles							AS sti	WITH(NOLOCK)	ON fg.styleid				= sti.styleid
            LEFT JOIN	LCA.dbo.stylecolors						AS stc	WITH(NOLOCK)	ON fg.stylecolorid			= stc.stylecolorid
            LEFT JOIN	LCA.dbo.htsstylecodes					AS hts	WITH(NOLOCK)	ON sti.htsstylecodeid		= hts.htsstylecodeid
            LEFT JOIN	LCA.dbo.orders							AS od	WITH(NOLOCK)	ON pb.orderid				= od.orderid
            LEFT JOIN	LCA.dbo.invoicebatches					AS inb	WITH(NOLOCK)	ON sh.invoicebatchid		= inb.invoicebatchid
            LEFT JOIN	LCA.dbo.goodsbins						AS gb	WITH(NOLOCK)	ON pb.goodsbinid			= gb.goodsbinid
            LEFT JOIN	LCA.dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid
            LEFT JOIN	LCA.dbo.DropDownValues3					AS bxt	WITH(NOLOCK)	ON bxt.DropDownValueID		= pb.BoxTagID
            LEFT JOIN	LCA.dbo.DropDownValues2					AS ddv2ot WITH(NOLOCK)	ON ddv2ot.DropDownValueID	= od.OrderTypeID3
            LEFT JOIN	LCA.dbo.ManufactureOrders				AS MO	WITH(NOLOCK)	ON MO.ManufactureID			= pbi.ManufactureID
            LEFT JOIN	LCA.dbo.orderdetails					AS odd	WITH(NOLOCK)	ON pbi.orderdetailsid		= odd.orderdetailsid
            LEFT JOIN	LCA.dbo.orderitems						AS oi2	WITH(NOLOCK)	ON odd.orderitemid			= oi2.orderitemid
            LEFT JOIN	LCA.dbo.orderitems						AS oi	WITH(NOLOCK)	ON oi.OrderItemID			= MO.FirstOrderItemID
            LEFT JOIN	AppsLCA.dbo.TB_ShipmentCheckPricesDetail AS SCPD WITH(NOLOCK) ON oi.OrderItemID		= SCPD.OrderItemID
                                                                                        AND pbi.ManufactureID	= SCPD.ManufactureID
                                                                                        AND sh.WayBill			= SCPD.Waybill
            LEFT JOIN	AppsLCA.legacycaps.VW_LCA_L2B_InventoryID AS L2B_LCA WITH(NOLOCK) ON sti.stylenumber	= L2B_LCA.style
                                                                                        AND stc.stylecolorname	= L2B_LCA.Color
                                                                                        AND fg.garmentsize		= L2B_LCA.SIZE
            WHERE pb.statusid = 75			-- reemplaza el join a statusnames: BoxStatusName no se usa en el reporte
            AND pb.orderid IS NOT NULL
        END

        IF @process = 'packinglist.waybills'
        BEGIN
            SELECT
                [R]         = JSON.[R]
                ,[Waybill]  = JSON.[Waybill]
                ,[ShipDate] = JSON.[ShipDate]
                INTO #TB_PL_Waybills
                FROM OPENJSON(@data, '$.selectedOptions')
                WITH (
                    [R]         INT             '$.R',
                    [Waybill]   NVARCHAR(100)   '$.Waybill',
                    [ShipDate]  DATE            '$.ShipDate'
                ) AS JSON

            INSERT INTO #TB_PL_RAW (
                     [Waybill],[Skid],[ItemCode],[Style],[Color],[ColorGreatPlain],[Size],[Qty],[XX],[OrderNo]
                    ,[L2Order],[Box],[Fact],[Gender],[Location],[Note]
                    ,[TrackingNumber],[BoxNo],[ColorPolyPM],[Price],[TotalPrices],[InvoiceDate]
            )
            SELECT
                'Waybill'			= sh.[WayBill]
                ,'Skid'				= COALESCE(gb.[Bin],'0')     -- ver hallazgo arriba: el CASE original no cambiaba el resultado
                ,'ItemCode'			= CASE
                                            WHEN L2B_LCA.InvItemNo IS NOT NULL THEN L2B_LCA.InvItemID
                                            WHEN fg.[garmentsize] = 'XS'  THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'A' + '-' + fg.[garmentsize]
                                            WHEN fg.[garmentsize] = 'S'   THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'B' + '-' + fg.[garmentsize]
                                            WHEN fg.[garmentsize] = 'M'   THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'C' + '-' + fg.[garmentsize]
                                            WHEN fg.[garmentsize] = 'QTY' THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'C-M'
                                            WHEN fg.[garmentsize] = 'L'   THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'D' + '-' + fg.[garmentsize]
                                            WHEN fg.[garmentsize] = 'XL'  THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'E' + '-' + fg.[garmentsize]
                                            WHEN fg.[garmentsize] = '2XL' THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'F' + '-' + fg.[garmentsize]
                                            WHEN fg.[garmentsize] = '3XL' THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'G' + '-' + fg.[garmentsize]
                                            WHEN fg.[garmentsize] = '4XL' THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'H' + '-' + fg.[garmentsize]
                                        END
                ,'Style'			= sti.[stylenumber]
                ,'Color'			= stc.[StyleColorDescription]
                ,'ColorGreatPlain'	= stc.[stylecolorname]
                ,'Size'				= CASE WHEN fg.[garmentsize] = 'QTY' THEN 'M' ELSE fg.[garmentsize] END
                ,'Qty'				= pbi.[quantity]
                ,'XX'				= ''
                ,'OrderNo'			= od.[ponumber]
                ,'L2Order'			= od.[Comments6]
                ,'Box'				= CAST(NULL AS INT)
                ,'Fact'				= RIGHT(inb.[invoicebatch],4)
                ,'Gender'			= hts.[ca_htsdescription]
                ,'Location'			= CASE
                                            WHEN ddv2ot.[DropDownValue] = 'Miami, FL 33182' THEN 'Account'
                                            WHEN ddv2ot.[DropDownValue] = 'Hanover' AND LEFT(od.[ponumber], 3) = 'ORD' THEN 'Printed to Hanover'
                                            ELSE ddv2ot.[DropDownValue]
                                        END
                ,'Note'				= ''
                ,'TrackingNumber'	= CASE
                                            WHEN ddv2ot.[DropDownValue] = 'Miami, FL 33182' THEN pb.[BoxComments6]
                                            WHEN ddv2ot.[DropDownValue] = 'Hanover' AND LEFT(od.[ponumber], 3) = 'ORD' THEN ''
                                            ELSE ''
                                        END
                ,'BoxNo'			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL AND bxt.[DropDownValue] IS NOT NULL
                                            ,CONCAT('PPPA'+LTRIM(STR(pb.[packedpalletid]+1000000)),'-',RIGHT(bxt.[DropDownValue],3))
                                            ,pb.[boxnumber]
                                        )
                ,'ColorPolyPM'		= stc.[stylecolorname]
                ,'Price'			= CASE
                                            WHEN SCPD.[id] IS NOT NULL	THEN (SCPD.[TotalBlank] + SCPD.[TotalDecoration])
                                            ELSE oi2.[unitprice]
                                        END
                ,'TotalPrices'		= CAST(pbi.[quantity] AS DECIMAL(10,2)) * CAST((
                                            CASE
                                                WHEN SCPD.[id] IS NOT NULL	THEN (SCPD.[TotalBlank] + SCPD.[TotalDecoration])
                                                ELSE oi2.[unitprice]
                                            END
                                        ) AS DECIMAL(10,2))
                ,'InvoiceDate'		= sc.[ShipDate]
            FROM		LCA.dbo.packedboxes						AS pb	WITH(NOLOCK)
            INNER JOIN	LCA.dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid AND sh.WayBill IN (SELECT DISTINCT [Waybill] FROM #TB_PL_Waybills)
            INNER JOIN	LCA.dbo.ShippingContainers				AS sc	WITH(NOLOCK)	ON sc.ShippingContainerID	= sh.ShippingContainerID
            INNER JOIN	LCA.dbo.packeditems						AS pbi	WITH(NOLOCK)	ON pbi.packedboxid			= pb.packedboxid	AND pbi.quantity > 0
            INNER JOIN	LCA.dbo.finishedgoods					AS fg	WITH(NOLOCK)	ON pbi.finishedgoodsid		= fg.finishedgoodsid
            INNER JOIN	LCA.dbo.styles							AS sti	WITH(NOLOCK)	ON fg.styleid				= sti.styleid
            LEFT JOIN	LCA.dbo.stylecolors						AS stc	WITH(NOLOCK)	ON fg.stylecolorid			= stc.stylecolorid
            LEFT JOIN	LCA.dbo.htsstylecodes					AS hts	WITH(NOLOCK)	ON sti.htsstylecodeid		= hts.htsstylecodeid
            LEFT JOIN	LCA.dbo.orders							AS od	WITH(NOLOCK)	ON pb.orderid				= od.orderid
            LEFT JOIN	LCA.dbo.invoicebatches					AS inb	WITH(NOLOCK)	ON sh.invoicebatchid		= inb.invoicebatchid
            LEFT JOIN	LCA.dbo.goodsbins						AS gb	WITH(NOLOCK)	ON pb.goodsbinid			= gb.goodsbinid
            LEFT JOIN	LCA.dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid
            LEFT JOIN	LCA.dbo.DropDownValues3					AS bxt	WITH(NOLOCK)	ON bxt.DropDownValueID		= pb.BoxTagID
            LEFT JOIN	LCA.dbo.DropDownValues2					AS ddv2ot WITH(NOLOCK)	ON ddv2ot.DropDownValueID	= od.OrderTypeID3
            LEFT JOIN	LCA.dbo.ManufactureOrders				AS MO	WITH(NOLOCK)	ON MO.ManufactureID			= pbi.ManufactureID
            LEFT JOIN	LCA.dbo.orderdetails					AS odd	WITH(NOLOCK)	ON pbi.orderdetailsid		= odd.orderdetailsid
            LEFT JOIN	LCA.dbo.orderitems						AS oi2	WITH(NOLOCK)	ON odd.orderitemid			= oi2.orderitemid
            LEFT JOIN	LCA.dbo.orderitems						AS oi	WITH(NOLOCK)	ON oi.OrderItemID			= MO.FirstOrderItemID
            LEFT JOIN	AppsLCA.dbo.TB_ShipmentCheckPricesDetail AS SCPD WITH(NOLOCK) ON oi.OrderItemID		= SCPD.OrderItemID
                                                                                        AND pbi.ManufactureID	= SCPD.ManufactureID
                                                                                        AND sh.WayBill			= SCPD.Waybill
            LEFT JOIN	AppsLCA.legacycaps.VW_LCA_L2B_InventoryID AS L2B_LCA WITH(NOLOCK) ON sti.stylenumber	= L2B_LCA.style
                                                                                        AND stc.stylecolorname	= L2B_LCA.Color
                                                                                        AND fg.garmentsize		= L2B_LCA.SIZE
            WHERE pb.statusid = 75			-- reemplaza el join a statusnames: BoxStatusName no se usa en el reporte
            AND pb.orderid IS NOT NULL
        END

        -------------------------------------------------------------------------------------------------------------------------------------------------------
        -- 3. Lógica compartida posterior a la obtención de datos (no cambia según el @process)
        -------------------------------------------------------------------------------------------------------------------------------------------------------
        IF @process IN ('export.dates','packinglist.waybills')
        BEGIN
            ;WITH CTE_Box AS (
                SELECT
                    [Box]
                    ,[BoxCorrelativo] = DENSE_RANK() OVER (PARTITION BY [Waybill] ORDER BY [BoxNo])
                FROM #TB_PL_RAW
            )
            UPDATE CTE_Box SET [Box] = [BoxCorrelativo]

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

            UPDATE TPR SET
                [TrackingNumber] = CASE WHEN [Location] LIKE '%Hanover%' THEN '' ELSE TrackingNumber END
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
                    ,[Qty]          = SUM([Qty])
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
                    ,[TotalPrices]  = SUM([TotalPrices])
                    ,[InvoiceDate]
                    -- ,[HasTracking]
                    -- ,[Comment]
                FROM #TB_PL_RAW
                GROUP BY
                    [Waybill]
                    ,[Skid]
                    ,[ItemCode]
                    ,[Style]
                    ,[Color]
                    ,[ColorGreatPlain]
                    ,[Size]
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
                    ,[InvoiceDate]
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
                    ,[Qty]          = SUM([Qty])
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
                    ,[TotalPrices]  = SUM([TotalPrices])
                    ,[InvoiceDate]
                    ,[HasTracking]
                    ,[Comment]
                FROM #TB_PL_RAW
                WHERE [Comment] <> ''
                GROUP BY
                    [Waybill]
                    ,[Skid]
                    ,[ItemCode]
                    ,[Style]
                    ,[Color]
                    ,[ColorGreatPlain]
                    ,[Size]
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
                    ,[InvoiceDate]
                    ,[HasTracking]
                    ,[Comment]
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
        ,[messageData]  = JSON_QUERY(@messageData)
        ,[Result]		= JSON_QUERY(@result)
    FOR JSON PATH, INCLUDE_NULL_VALUES


END
