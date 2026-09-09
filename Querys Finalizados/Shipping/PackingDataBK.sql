USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_PackingData]    Script Date: 31/08/2026 04:46:11 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- ALTER PROCEDURE [dbo].[SP_PackingData] 
--       @process	VARCHAR(MAX)
-- 		,@data		NVARCHAR(MAX)
-- 		, @NoSelect BIT = 0 
-- 		, @otherData NVARCHAR(MAX) =NULL OUTPUT   -- nuevo parámetro
-- AS
BEGIN
    SET NOCOUNT ON;

	-------PRUEBA PARA waybill.list
		-- DECLARE @process	AS VARCHAR(MAX)
		-- DECLARE @data		AS NVARCHAR(MAX)
		-- SET @process	= 'waybill.list'
		-- SET @data		= NULL
	-------PRUEBA PARA waybill.list

	
		-- 			DECLARE @process	AS VARCHAR(MAX)
		--  DECLARE @data		AS NVARCHAR(MAX)
		--  DECLARE @otherData NVARCHAR(MAX) =NULL
		--  declare @NoSelect BIT  = 0
		--  SET @process	= 'generate.PackingListSumMos'
 		-- SET @data		= '{"selectedOptions":[
 		-- 										  {
 		-- 											 "R":"1",
 		-- 											 "Waybill":"AIR-APP-20260512"
 		-- 										  }
 		-- 									   ]
 		-- 					}'
		-- 	set @NoSelect = 1
			
	-------PRUEBA PARA generate.PackingListBeforeShipment
		  DECLARE @process	AS VARCHAR(MAX)
		  DECLARE @data		AS NVARCHAR(MAX)
		  DECLARE @otherData NVARCHAR(MAX) =NULL
		  declare @NoSelect BIT  = 0
		  SET @process	= 'generate.PackingListBeforeShipment'
 		  SET @data		= '{"selectedOptions":[
 		 										  {
 		 											 "R":"51",
 		 											 "Waybill":"AIR-APP-20260903-2",
 		 											 "ShipDate":"2026-09-03"
 		 										  }
 		 									   ]
 		 					}'
		 	-- set @NoSelect = 1
-- 		SET @data = '{
--                 		"sources": "Empaque",
-- 												    "inventorylist_id": "11",
--                 		"filters":[
--                 			         {
-- 								    "area": "empaque",
-- 								    "location": "AIR001"
-- 								  },
-- 								  {
-- 								    "area": "empaque",
-- 								    "location": "AIR002"
-- 								  },
-- 								  {
-- 								    "area": "empaque",
-- 								    "location": "AIR003"
-- 								  },
-- 								  {
-- 								    "area": "empaque",
-- 								    "location": "TRUCK001"
-- 								  },
-- 								  {
-- 								    "area": "empaque",
-- 								    "location": "TRUCK002"
-- 								  },
-- 								  {
-- 								    "area": "empaque",
-- 								    "location": "TRUCK003"
-- 								  }
--                 		]
             
-- 		SET @data		= '{"selectedOptions":[
-- 												  {
-- 												    "sources": "Empaque",
-- 												    "inventorylist_id": "11",
-- 												    "area": "empaque",
-- 												    "location": "AIR001"
-- 												  },
-- 												  {
-- 												    "sources": "Empaque",
-- 												    "inventorylist_id": "11",
-- 												    "area": "empaque",
-- 												    "location": "AIR002"
-- 												  },
-- 												  {
-- 												    "sources": "Empaque",
-- 												    "inventorylist_id": "11",
-- 												    "area": "empaque",
-- 												    "location": "AIR003"
-- 												  },
-- 												  {
-- 												    "sources": "Empaque",
-- 												    "inventorylist_id": "11",
-- 												    "area": "empaque",
-- 												    "location": "TRUCK001"
-- 												  },
-- 												  {
-- 												    "sources": "Empaque",
-- 												    "inventorylist_id": "11",
-- 												    "area": "empaque",
-- 												    "location": "TRUCK002"
-- 												  },
-- 												  {
-- 												    "sources": "Empaque",
-- 												    "inventorylist_id": "11",
-- 												    "area": "empaque",
-- 												    "location": "TRUCK003"
-- 												  }
-- 											   ]
-- 							}'
		
-- 		SET @data		= '{"selectedOptions":[
-- 												  {
-- 													 "inventorylist_id":"1"
-- 												  }
-- 											   ]
-- 							}'
  
--   SET @data		= '{"selectedOptions":[
-- 												  {
-- 													 "inventorylist_id":"1",
-- 													 "sources":"WH FTTS",
-- 													 "area" : "Stock Warehouse"
-- 												  }
-- 											   ]
-- 							}'
							
-- 	-- -----PRUEBA PARA generate.PackingListBeforeShipment
	
-- 	-----PRUEBA PARA generate.PakingListTarimasShipped
-- 		-- DECLARE @process	AS VARCHAR(MAX)
-- 		-- DECLARE @data		AS NVARCHAR(MAX)
-- 		-- declare @NoSelect BIT  = 0
-- 		-- DECLARE @otherData NVARCHAR(MAX) =NULL
-- 		-- SET @process	= 'generate.PakingListTarimasShipped'
-- 		-- SET @data		= '{"selectedOptions":[
-- 		-- 										  {
-- 		-- 											 "R":"1",
-- 		-- 											 "Waybill":"AIR-HW-20250908"
-- 		-- 										  }
			
-- 		-- 									   ]
-- 		-- 					}'
-- 	-----PRUEBA PARA generate.PakingListTarimasShipped
	
-- 	-----PRUEBA PARA PackingListTarimas.list
-- 		-- DECLARE @process	AS VARCHAR(MAX)
-- 		-- DECLARE @data		AS NVARCHAR(MAX)
-- 		-- SET @process	= 'PackingListTarimas.list'
-- 		-- SET @data		= '{"selectedOptions":[
-- 		-- 										  {
-- 		-- 											 "R":"1",
-- 		-- 											 "Waybill":"APP-20250619"
-- 		-- 										  }
			
-- 		-- 									   ]
-- 		-- 					}'
-- 	-----PRUEBA PARA PackingListTarimas.list
	
-- 	-----PRUEBA PARA amazon.update
-- 		-- DECLARE @process	AS VARCHAR(MAX)
-- 		-- DECLARE @data		AS NVARCHAR(MAX)
-- 		-- SET @process	= 'amazon.update'
-- 		-- SET @data		= '{"selectedOrders":[{"amazon":"zrzsrezthzxrhezjtrx","customer":"225070031"}]}}'
-- 		-- DECLARE  @NoSelect BIT = 0 
-- 		-- DECLARE @otherData NVARCHAR(MAX) =NULL
-- 	-----PRUEBA PARA amazon.update


	-----PRUEBA PARA amazon.update
		-- DECLARE @process	AS VARCHAR(MAX)
		-- DECLARE @data		AS NVARCHAR(MAX)
		-- SET @process	= 'approve-wo'
		-- SET @data		= '{"selectedOrders":[{

		-- 										"ItemDetailID":"6175453",
		-- 										"Style":"RVF400",
		-- 										"Size":"L",
		-- 										"Color":"225",
		-- 										"Waybill":"AIR-APP-20260903",
		-- 										"User":"02889",
		-- 										"Pin":"182002",
		-- 										"ReasonID":2,
		-- 										"Comment":"Units packed does not match Order Requested"
		-- 									 }]
		-- 					}'
		-- DECLARE  @NoSelect BIT = 0 
		-- DECLARE @otherData NVARCHAR(MAX) =NULL
	-----PRUEBA PARA amazon.update
	

	

    DECLARE @message        AS VARCHAR(100)
    DECLARE @messageData    AS NVARCHAR(MAX)
    DECLARE @error          AS BIT
    DECLARE @result         AS NVARCHAR(MAX)
	DECLARE @resultReasons 	AS NVARCHAR(MAX)

	SET @messageData    = '[]' 
	SET @result         = '[]' 
	SET @resultReasons  = '[]' 
	SET @error          = 1
    SET @message        = 'Error'  

    BEGIN TRY
        
		----------------------------------------------------------------------------------------------------
		------------------------------------------waybill.list----------------------------------------------
		----------------------------------------------------------------------------------------------------
			IF @process = 'waybill.list'
			BEGIN
				SET @result		= (
										SELECT
											[R]					= ROW_NUMBER() OVER(ORDER BY TB.[ShipDate] DESC , TB.[Waybill])
											,[Waybill]		= TB.[Waybill]
											,[ShipDate]		= TB.[ShipDate]
										FROM(
											SELECT 
												[WayBill]		= sh.WayBill
												,[ShipDate]	= MAX(CAST(COALESCE(sc.ShipDate,sh.ShipDate) AS DATE))
											FROM   		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID = 75) AS FSN 
											INNER JOIN	LCA.dbo.statusnames				AS snpb	WITH(NOLOCK)	ON snpb.StatusID			= FSN.StatusID			AND snpb.StatusID = 75
											INNER JOIN	LCA.dbo.packedboxes				AS pb	WITH(NOLOCK)	ON pb.statusid				= snpb.statusid			AND pb.orderid IS NOT NULL
											INNER JOIN	LCA.dbo.shipments				AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid			AND sh.ShipDate > DATEADD(month,-4,convert(date,getdate())) 
											LEFT JOIN	LCA.dbo.ShippingContainers		AS sc	WITH(NOLOCK)	ON sc.ShippingContainerID	= sh.ShippingContainerID
											GROUP BY sh.WayBill
										) AS TB
										FOR JSON PATH ,INCLUDE_NULL_VALUES
									)
				SET @error		= 0
				SET @message	= 'Datos obtenidos correctamente.' 
			END
		----------------------------------------------------------------------------------------------------
		------------------------------------------waybill.list----------------------------------------------
		----------------------------------------------------------------------------------------------------

		
		ELSE
		----------------------------------------------------------------------------------------------------
		---------------------------generate.PackingListBeforeShipment---------------------------------------
		----------------------------------------------------------------------------------------------------
			IF @process = 'generate.PackingListBeforeShipment'
			BEGIN
				PRINT 'PROCESO generate.PackingListBeforeShipment'
				PRINT FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss')
				
				
				DECLARE @listWaybills		AS NVARCHAR(MAX)
				SET @listWaybills			= (SELECT JSON_QUERY(@data, '$.selectedOptions'))

				DROP TABLE IF EXISTS #TB_PACKING_LIST_BEFORE_SHIPMENT
				SELECT 
				     [rowN]			= STJ.[R]
					,[Waybill]		= STJ.[Waybill] 
				INTO #TB_PACKING_LIST_BEFORE_SHIPMENT
				FROM OPENJSON(@listWaybills)
				WITH (	 
						[R]			INT
						,[Waybill]		VARCHAR(200)
					) AS STJ
				
				DROP TABLE IF EXISTS #TB_DataPacking
				SELECT	
						[R]							= ROW_NUMBER() OVER(ORDER BY 
																				sh.[Waybill]
																				,IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[DropDownValue],'000'),3) ) 
																							,pb.[BoxNumber] 
																						)
																			)
						,[Comment]                      = CAST(NULL AS VARCHAR(MAX))
						,[WayBill]						= sh.[WayBill]
						,[CustomerOrder]                = SUBSTRING(OD.[Comments6], 1, 9)
						,[BoxNumber]					= pb.[BoxNumber]
						,[FormattedBoxNumber]			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT('PPPA'+Ltrim(Str(pp.PackedPalletID+1000000)),'-',RIGHT(btg.DropDownValue,3)) 
																	,pb.[BoxNumber] 
																)
						-- ,[FormattedBoxNumber]			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[DropDownValue],'000'),3) ) 
						-- 											,pb.[BoxNumber] 
						-- 										)
                        ,[BoxAmazon]                    = pb.BoxComments4
						,[APS]				            = od.[Comments6]
						,[PONumber]						= od.[ponumber]
						,[ItemDetailID]                 = CASE 
		                                                    WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
		                                                        NULL
		                                                    WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
		                                                        try_cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT) 
		                                                    WHEN ( od.[PONumber] LIKE 'ORD%') and (ISNUMERIC(od.Comments6) = 1 ) THEN
		                                                        try_cast(od.[Comments6] AS BIGINT)
		                                                    ELSE
		                                                        NULL 
		                                                    END 
						,[Order]						= od.[OrderNumber]
						,[StyleNumber]					= sti.[stylenumber]
						,[StyleColor]					= stc.[stylecolorname]
						,[GarmentSize]					= fg.[garmentsize]
						,[Units]						= CAST(pbi.[quantity] AS INT)
						,[GrossWeightKGSData]           = CAST(NULL AS DECIMAL(24,10))
						,[Label]						= pb.[BoxLabel]
						-- ,[VolumeBox]					= CONCAT(	CAST(bxtp.BoxLength AS VARCHAR),'*',CAST(bxtp.[BoxWidth] AS VARCHAR),'*',CAST(bxtp.[BoxHeight] AS VARCHAR))
						,[VolumeBox]					= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL
																,CONCAT(	CAST(ppt.[PalletLength] AS VARCHAR),'*',CAST(ppt.[PalletWidth] AS VARCHAR),'*',CAST(ppt.[PalletHeight] AS VARCHAR))
																,CONCAT(	CAST(bxtp.[BoxLength] AS VARCHAR),'*',CAST(bxtp.[BoxWidth] AS VARCHAR),'*',CAST(bxtp.[BoxHeight] AS VARCHAR))
															)
																		
						-- ,[BoxType]						= bxtp.[BoxTypeName]     
						,[BoxType]						= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL
																,ppt.[PalletTypeName]
																,bxtp.[BoxTypeName]
															)
						     
						,[BoxStatus]					= snpb.[StatusName]
						,[Bin]						  	= gb.[Bin]
						,[ProductDivision]              = sti.Comments9
						,[ManufactureID]			    = pbi.ManufactureID 
						,[MO]                           = MO.ManufactureNumber
						,[MOStatusID]					= MO.StatusID
						,[MOStatus]						= SMO.StatusName
						,[SupplNo]                      = CAST(NULL AS VARCHAR(50))
						,[DetailStatus]                 = CAST(NULL AS VARCHAR(100))
                        ,[DetailStatusName]             = CAST(NULL AS VARCHAR(200))
                        ,[ShippingContainerID]          = sh.ShippingContainerID
						,[PuertoDestino]				= PD.DropDownValue
						,[SuspendOrd]					= CAST(COALESCE(OS.SWHOLD,0) AS BIT) --- Requerimiento de RA para identificar órdenes suspendidas --- RR 20260212
						,[SuspendType]					= OS.SuspendType
						,[RequestQty]					= CAST(NULL AS INT)
						,[PackedQty]					= CAST(NULL AS INT)
						,[FlagReason]					= CAST(0 AS BIT)
						,[TrackingNumber]				= PB.[BoxComments6]
	 					-- ,[GoodsBinID]				  	= gb.[GoodsBinID]
				INTO #TB_DataPacking
				FROM   		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID = 75 ) AS FSN
				INNER JOIN	LCA.dbo.statusnames						AS snpb	WITH(NOLOCK)	ON snpb.StatusID			= FSN.StatusID			AND snpb.StatusID = 75
				INNER JOIN	LCA.dbo.packedboxes						AS pb	WITH(NOLOCK)	ON pb.statusid				= snpb.statusid			AND pb.orderid IS NOT NULL
				LEFT JOIN	LCA.dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid			--AND sh.ShipDate > DATEADD(month,-2,convert(date,getdate()))
				INNER JOIN	#TB_PACKING_LIST_BEFORE_SHIPMENT		AS TB					ON TB.Waybill				= sh.WayBill
				INNER JOIN	LCA.dbo.packeditems						AS pbi	WITH(NOLOCK)	ON pbi.packedboxid			= pb.packedboxid		AND pbi.quantity > 0
				INNER JOIN	LCA.dbo.finishedgoods					AS fg	WITH(NOLOCK)	ON pbi.finishedgoodsid		= fg.finishedgoodsid
				INNER JOIN	LCA.dbo.styles							AS sti	WITH(NOLOCK)	ON fg.styleid				= sti.styleid
				LEFT JOIN	LCA.dbo.GoodsBins						AS gb	WITH(NOLOCK)	ON gb.GoodsBinID			= pb.GoodsBinID
				LEFT JOIN	LCA.dbo.ManufactureOrders				AS MO	WITH(NOLOCK)	ON MO.ManufactureID			= pbi.ManufactureID
				LEFT JOIN	LCA.dbo.htsstylecodes					AS hts	WITH(NOLOCK)	ON sti.htsstylecodeid		= hts.htsstylecodeid
				LEFT JOIN	LCA.dbo.stylecolors						AS stc	WITH(NOLOCK)	ON fg.stylecolorid			= stc.stylecolorid
				LEFT JOIN	LCA.dbo.orderdetails					AS odd	WITH(NOLOCK)	ON pbi.orderdetailsid		= odd.orderdetailsid
				LEFT JOIN	LCA.dbo.orderitems						AS oi	WITH(NOLOCK)	ON odd.orderitemid			= oi.orderitemid
				LEFT JOIN	LCA.dbo.invoicebatches					AS inb	WITH(NOLOCK)	ON sh.invoicebatchid		= inb.invoicebatchid
				LEFT JOIN	LCA.dbo.orders							AS od	WITH(NOLOCK)	ON pb.orderid				= od.orderid
				LEFT JOIN	LCA.dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid
				LEFT JOIN	LCA.dbo.Warehouses						AS wh	WITH(NOLOCK)	ON wh.WarehouseID			= pb.WarehouseID
				LEFT JOIN	LCA.dbo.Styles							AS st	WITH(NOLOCK)	ON st.StyleID				= sti.BlankStyleID
				LEFT JOIN	LCA.dbo.ShippingContainers				AS sc	WITH(NOLOCK)	ON sc.ShippingContainerID	= sh.ShippingContainerID
				LEFT JOIN	LCA.dbo.DropDownValues3					AS btg	WITH(NOLOCK)	ON btg.DropDownValueID		= pb.BoxTagID			AND btg.DropDownID = 19
				LEFT JOIN   LCA.dbo.PalletTypes						AS ppt  WITH(NOLOCK)	ON pp.PalletTypeID			= ppt.PalletTypeID
				LEFT JOIN	LCA.dbo.boxtypes						AS bxtp WITH(NOLOCK)	ON pb.boxtypeid				= bxtp.boxtypeid
				LEFT JOIN	LCA.dbo.DropDownValues2					AS PD	WITH(NOLOCK)	ON od.OrderTypeID3			= PD.DropDownValueID
				LEFT JOIN	AppsLCA.legacycaps.OrdersSuspended		AS OS	WITH(NOLOCK)	ON MO.ManufactureID			= OS.ManufactureID
				LEFT JOIN	LCA.dbo.StatusNames						AS SMO	WITH(NOLOCK)	ON MO.StatusID				= SMO.StatusID


				------------------------------CALCULO DE PESO POR CAJA / CAJA CONSOLIDADA------------------------------
                    PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  TABLA TB_UnitsBox_Weight')
                    DROP TABLE IF EXISTS #TB_UnitsBox_Weight
    				SELECT 
    				     [FormattedBoxNumber]			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT('PPPA'+Ltrim(Str(pp.PackedPalletID+1000000)),'-',RIGHT(btg.DropDownValue,3)) 
    																	,pb.[BoxNumber] 
    																)
    				    ,[Quantity]                     = SUM(ROUND(pbi.[quantity],2)) 
    				INTO #TB_UnitsBox_Weight
    				FROM   		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID IN(27,25,75)) AS FSN 
    				INNER JOIN	LCA.dbo.statusnames						AS snpb	WITH(NOLOCK)	ON snpb.StatusID			= FSN.StatusID			AND snpb.StatusID = 75
    				INNER JOIN	LCA.dbo.packedboxes						AS pb	WITH(NOLOCK)	ON pb.statusid				= snpb.statusid			AND pb.orderid IS NOT NULL
    				INNER JOIN	LCA.dbo.orders							AS od	WITH(NOLOCK)	ON pb.orderid				= od.orderid			
				    LEFT JOIN	LCA.dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid			--AND sh.ShipDate > DATEADD(month,-2,convert(date,getdate()))
					INNER JOIN	#TB_PACKING_LIST_BEFORE_SHIPMENT		AS TB					ON TB.Waybill				= sh.WayBill
    				LEFT JOIN	LCA.dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid 
    				LEFT JOIN   LCA.dbo.PalletTypes						AS ppt  WITH(NOLOCK)	ON pp.PalletTypeID			= ppt.PalletTypeID  
    				LEFT JOIN	LCA.dbo.DropDownValues3					AS btg	WITH(NOLOCK)	ON btg.DropDownValueID		= pb.BoxTagID			AND btg.DropDownID = 19
    				INNER JOIN	LCA.dbo.packeditems						AS pbi	WITH(NOLOCK)	ON pbi.packedboxid			= pb.packedboxid		AND pbi.quantity > 0  
    				GROUP BY  
    				    IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT('PPPA'+Ltrim(Str(pp.PackedPalletID+1000000)),'-',RIGHT(btg.DropDownValue,3)) 
    																	,pb.[BoxNumber] 
    																)
    				
    				
                    PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  TABLA TB_Box_Weight')
                    DROP TABLE IF EXISTS #TB_Box_Weight
    				SELECT
    				     [FormattedBoxNumber]    = TB_BOX.[FormattedBoxNumber]
    				    ,[WeighBox]              = TB_BOX.[WeighBox]
    				INTO #TB_Box_Weight
    				FROM(
    				    SELECT
    				         [FormattedBoxNumber]           = TB_G.[FormattedBoxNumber]
    				        ,[WeighBox]                     = ROUND(SUM(TB_G.[weight]) + (SUM(TB_G.[PalletWeight]) / COUNT(TB_G.[BoxNumber])),2)
    				    FROM(
            				SELECT 
            				     [FormattedBoxNumber]			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT('PPPA'+Ltrim(Str(pp.PackedPalletID+1000000)),'-',RIGHT(btg.DropDownValue,3)) 
            																	,pb.[BoxNumber] 
            																)
            				    ,[Weight]                       = COALESCE(pb.[Weight],0.0000)
            				    ,[PalletWeight]                 = IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , ppt.[PalletWeight],0.0000)
            				    ,[BoxNumber]                    = pb.[BoxNumber]
            				    ,[TypeBoxFinal]                 = IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , 1,0)
                                                                                
            				FROM   		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID IN(27,25,75)) AS FSN 
            				INNER JOIN	LCA.dbo.statusnames						AS snpb	WITH(NOLOCK)	ON snpb.StatusID			= FSN.StatusID			AND snpb.StatusID = 75
            				INNER JOIN	LCA.dbo.packedboxes						AS pb	WITH(NOLOCK)	ON pb.statusid				= snpb.statusid			AND pb.orderid IS NOT NULL
            				INNER JOIN	LCA.dbo.orders							AS od	WITH(NOLOCK)	ON pb.orderid				= od.orderid			
            				LEFT JOIN	LCA.dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid			--AND sh.ShipDate > DATEADD(month,-2,convert(date,getdate()))
							INNER JOIN	#TB_PACKING_LIST_BEFORE_SHIPMENT		AS TB					ON TB.Waybill				= sh.WayBill
            				LEFT JOIN	LCA.dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid 
            				LEFT JOIN   LCA.dbo.PalletTypes						AS ppt  WITH(NOLOCK)	ON pp.PalletTypeID			= ppt.PalletTypeID  
            				LEFT JOIN	LCA.dbo.DropDownValues3					AS btg	WITH(NOLOCK)	ON btg.DropDownValueID		= pb.BoxTagID			AND btg.DropDownID = 19                                              
        				) AS TB_G
        				GROUP BY 
        				      [FormattedBoxNumber]
        				     ,[TypeBoxFinal]
    				) AS TB_BOX
    				
                    PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  UPDATE Weight')
    				UPDATE S SET
    				    [GrossWeightKGSData]    = IIF(TB_BOX.[WeighBox] > 0 AND PBUnits.[Quantity] > 0, (TB_BOX.[WeighBox] / PBUnits.[Quantity]),0) * S.[Units]
    				FROM #TB_DataPacking            AS S
    				LEFT JOIN #TB_Box_Weight        AS TB_BOX       ON TB_BOX.[FormattedBoxNumber]  = S.[FormattedBoxNumber]
    				LEFT JOIN #TB_UnitsBox_Weight   AS PBUnits      ON PBUnits.[FormattedBoxNumber] = S.[FormattedBoxNumber]
                
				------------------------------CALCULO DE PESO POR CAJA / CAJA CONSOLIDADA------------------------------
				
				
				
				
				PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' TABLE TB_GROUP_ItemDetailID')
                DROP TABLE IF EXISTS #TB_GROUP_ItemDetailID
                SELECT  DISTINCT ItemDetailID INTO #TB_GROUP_ItemDetailID FROM #TB_DataPacking WHERE ItemDetailID IS NOT NULL AND ItemDetailID <> 0


                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' TABLE L2_OrderItemDetail_Remote')
                DROP TABLE IF EXISTS #L2_OrderItemDetail_Remote
                DECLARE @ids_ItemDetail NVARCHAR(MAX)-- 1. Convertimos la lista de IDs en un string

                SELECT @ids_ItemDetail = STRING_AGG(CONVERT(NVARCHAR(MAX), ItemDetailID), ',') FROM #TB_GROUP_ItemDetailID

                -- 2. Ejecutamos la consulta remota con un filtro explícito
                DECLARE @sqlRemoteItemDetailID NVARCHAR(MAX) = '
                    SELECT ItemDetailID, DetailStatus , Quantity , SupplNo
                    FROM [db1.legacycaps.com].[Production].[dbo].[order_ItemDetail] WITH(NOLOCK)
                    WHERE ItemDetailID IN (' + @ids_ItemDetail + ')'

                -- 3. Creamos tabla temporal con los resultados
                CREATE TABLE #L2_OrderItemDetail_Remote (
                     [ItemDetailID]     INT
                    ,[DetailStatus]     INT
                    ,[Quantity]         INT
                    ,[SupplNo]          INT     
                )

                -- PRINT @sql
                INSERT INTO #L2_OrderItemDetail_Remote
                EXEC (@sqlRemoteItemDetailID)
                
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' TABLE TB_StatusL2Brands')
                DROP TABLE IF EXISTS #TB_StatusL2Brands
                SELECT 
                     [DetailStatus]   = L2Sta.StatusNo
                     ,L2Sta.[StatusText]
                INTO #TB_StatusL2Brands
                FROM #L2_OrderItemDetail_Remote AS S
                INNER JOIN [db1.legacycaps.com].[Production].[dbo].[order_Status]  AS L2Sta WITH(NOLOCK) ON L2Sta.StatusNo = S.DetailStatus

				
				PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' UPDATE DetatilStatus SupplNo')
                UPDATE S SET
                     [DetailStatus]         = L2BExp.[DetailStatus]
                    ,[DetailStatusName]     = CONCAT('(',CAST(L2BExp.[DetailStatus] AS VARCHAR),')',L2Sta.[StatusText],'(',L2BExp.[SupplNo],')')
                    ,[SupplNo]              = L2BExp.[SupplNo]
                FROM        #TB_DataPacking AS S
                INNER JOIN  #L2_OrderItemDetail_Remote      AS L2BExp   WITH(NOLOCK) ON L2BExp.ItemDetailID = S.ItemDetailID
                LEFT JOIN   #TB_StatusL2Brands              AS L2Sta    WITH(NOLOCK) ON L2BExp.DetailStatus = L2Sta.DetailStatus
                
                
                
				PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' UPDATE Comments REVISION PACKING')
				UPDATE S SET
				    [Comment]               = CASE
				                                --------VALIDACION QUE NO PERTENECE AL SUPPLIER 162 Y ORDEN CANCELADA POR L2BRANDS
				                                WHEN [ItemDetailID] IS NOT NULL AND [SupplNo] <> 162 AND [DetailStatus] = 50        THEN 'Order with incorrect supplier and cancelled by L2Brands'
				                                --------VALIDACION QUE NO SEA UNA ORDEN CON SUPPLIER DIFERENTE DE 162
				                                WHEN [ItemDetailID] IS NOT NULL AND [SupplNo] <> 162                                THEN 'Order with incorrect supplier'
				                                --------VALIDACION QUE NO SEA UNA ORDEN CANCELADA
				                                WHEN [ItemDetailID] IS NOT NULL AND [DetailStatus] = 50                             THEN 'Order cancelled by L2Brands'
												-------VALIDACION MOS QUE NO ESTEN RELEASED -------- 
												WHEN [MOStatusID] = 40																THEN 'Order with MO in status Released'
												-------VALIDACION MOS QUE NO ESTEN FORECAST -------- 
												WHEN [MOStatusID] = 20																THEN 'Order with MO in status Forecast'
												-------VALIDACION MOS QUE NO ESTEN VOID -------- 
												WHEN [MOStatusID] = 95																THEN 'Order with MO in status Void'
				                                --------VALIDACION QUE TODAS LAS CAJAS DEBEN PERTENECER A UN BIN
				                                WHEN [Bin] IS NULL                                                                  THEN 'Box not assigned to a bin'   
				                            
				                                --------VALIDACION QUE TODAS LAS CAJAS DEBEN PERTENECER A UN BIN DE EXPORTACION
				                                WHEN NOT([Bin] LIKE 'Skid%' OR [Bin] LIKE 'RT%' OR [Bin] LIKE 'AIR%' OR [Bin] LIKE 'SM%' OR [Bin] LIKE 'TRUCK%'  OR [Bin] LIKE 'MST%')                  THEN 'Box does not belong to an export bin.'   
				                                
				                                WHEN         [ProductDivision] NOT LIKE '%Apparel%'
                                                         AND [ProductDivision] NOT LIKE '%Headwear%'
                                                         AND [ProductDivision] NOT LIKE '%quilt%'
                                                         AND [ProductDivision] NOT LIKE '%swatch%'
                                                         AND [ProductDivision] NOT LIKE '%Accesories%'                              THEN 'Order with invalid product division'
												WHEN [PuertoDestino] IS NULL														THEN  'Order without Destination Port'
												--- Requerimiento de RA para evitar exportar órdenes con customer supendido por L2B --- RR 20260212
												WHEN [SuspendOrd] = 1																THEN 'Order suspended for ' + [SuspendType]
				                                ELSE
				                                    NULL
				                                END
				FROM #TB_DataPacking AS S
				
				DROP TABLE IF EXISTS #TB_MO_DataPacking_UNIQUE
				SELECT DISTINCT
					 [ManufactureID]
					,[MO]
				INTO #TB_MO_DataPacking_UNIQUE
				FROM #TB_DataPacking
				WHERE [ManufactureID] IS NOT NULL
				
				DROP TABLE IF EXISTS #TB_EORO_Packing
				SELECT 
					 [ManufactureID]	= [ManufactureID]
					,[Size]		        = [Size]
					,[Validation]       = MAX(IIF( [QuantityNeeded] <> 0 OR [QuantityPacked] > [QuantityRequired] ,1,0))
				INTO #TB_EORO_Packing
				FROM(
					SELECT 
						 [ManufactureID]        = TB.ManufactureID
						,[MO]			        = TB.MO					
						,[Size]                 = FG.GarmentSize
						,[QuantityRequired]     = MB.QuantityRequired
						,[QuantityWithdrawn]    = MB.QuantityWithdrawn
						,[QuantityNeeded]       = MB.QuantityRequired - MB.QuantityWithdrawn
						,[QuantityPacked]       = ( SELECT SUM(COALESCE(pbi.Quantity,0)) 
													FROM        LCA.dbo.PackedItems     AS pbi WITH(NOLOCK) 
													INNER JOIN  LCA.dbo.FinishedGoods   AS fgi WITH(NOLOCK) ON fgi.FinishedGoodsID = pbi.FinishedGoodsID 
																AND pbi.ManufactureID   = TB.ManufactureID
																AND FG.GarmentSize      = fgi.GarmentSize
												)
					-- ,MB.*
					FROM #TB_MO_DataPacking_UNIQUE AS TB
					INNER JOIN  LCA.dbo.ManufactureBlanks    AS MB WITH(NOLOCK) ON MB.ManufactureID     = TB.ManufactureID      ---AND (MB.QuantityRequired - MB.QuantityWithdrawn) <> 0
					INNER JOIN  LCA.dbo.FinishedGoods        AS FG WITH(NOLOCK) ON FG.FinishedGoodsID   = MB.FinishedGoodsID
					where MB.QuantityRequired > 0 ----- PARA EVITAR ERROR DE 2 SEASONS. AGREGADO POR RR 20251209
				) AS TB
				WHERE IIF( [QuantityNeeded] <> 0 OR [QuantityPacked] > [QuantityRequired] ,1,0) = 1
				GROUP BY
					[ManufactureID]
					,[Size]
				
				
				UPDATE S SET
					[Comment] = 'Units packed in excess of the withdraw quantity'
				FROM #TB_DataPacking AS S
				INNER JOIN #TB_EORO_Packing AS B ON B.ManufactureID = S.ManufactureID AND B.Size = S.GarmentSize AND [Comment] IS NULL
				
				

				DROP TABLE IF EXISTS #TB_SummaryPacking
				SELECT
					 [WayBill]		= COALESCE(S.[WayBill],'Total')
					,[Bins]			= COUNT(DISTINCT S.[Bin])
					,[Boxes]		= COUNT(DISTINCT S.[FormattedBoxNumber])
					,[Units]		= SUM(S.[Units])
				INTO #TB_SummaryPacking
				FROM #TB_DataPacking	AS S
				GROUP BY ROLLUP(S.[WayBill])
				
				DROP TABLE IF EXISTS #TB_Count_Containers
				SELECT 
					 [Waybill] 
					,[CountContainers]   = COUNT( DISTINCT COALESCE(ShippingContainerID,0)) 
				INTO #TB_Count_Containers
				FROM #TB_DataPacking 
				GROUP BY 
					[Waybill]
				
				
				UPDATE S SET
					[Comment] = CONCAT('Multiple containers for the same waybill: ' , CAST(B.COUNTContainers AS VARCHAR) )
				FROM #TB_DataPacking AS S
				INNER JOIN #TB_Count_Containers AS B ON B.WayBill = S.WayBill AND [Comment] IS NULL AND B.CountContainers > 1

				UPDATE S SET
					[Comment] = 'Empty container number for the waybill'
				FROM #TB_DataPacking AS S
				WHERE ShippingContainerID IS NULL

----- =========================================== VALIDACION UNIDADES DE WORK ORDER EN WAYBILL (ItemDetailID) ====================================================
				PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' VALIDATE WorkOrder Units In Waybill')

				DECLARE @dataWaybillWO NVARCHAR(MAX)
				SET @dataWaybillWO = (
					SELECT
						 [WayBill]        = S.[WayBill]
						,[ItemDetailID]   = S.[ItemDetailID]
						,[Order]          = S.[Order]
						,[ManufactureID]  = S.[ManufactureID]
					FROM #TB_DataPacking AS S
					WHERE S.[ItemDetailID] IS NOT NULL AND S.[Order] IS NOT NULL
					GROUP BY
						 S.[WayBill]
						,S.[ItemDetailID]
						,S.[Order]
						,S.[ManufactureID]
					FOR JSON PATH
				)

				DROP TABLE IF EXISTS #TB_WOValidationJSON
				CREATE TABLE #TB_WOValidationJSON (
					[Result] NVARCHAR(MAX)
				)

				DECLARE @resultWaybillWO NVARCHAR(MAX)

				IF @dataWaybillWO IS NOT NULL
				BEGIN
					INSERT INTO #TB_WOValidationJSON ([Result])
					EXEC [dbo].[SP_Shipping_ValidateItemDetailID_In_Waybill] @process = 'validate-wo', @data = @dataWaybillWO

					SELECT @resultWaybillWO = [Result] FROM #TB_WOValidationJSON
				END

				DROP TABLE IF EXISTS #TB_WOValidation
				SELECT
					 [Waybill]
					,[ItemDetailID]
					,[Order]
					,[OrderID]
					,[ManufactureID]
					,[FinishedGoodsID]
					,[Size]
					,[RequestQty]
					,[PackedQty]
					,[CorrectQty]
					,[MultiContainer]
					,[Containers]
					,[Comment]
				INTO #TB_WOValidation
				FROM OPENJSON(@resultWaybillWO)
				WITH (
					 [Waybill]          VARCHAR(100)
					,[ItemDetailID]     INT
					,[Order]            VARCHAR(50)
					,[OrderID]          INT
					,[ManufactureID]    INT
					,[FinishedGoodsID]  INT
					,[Size]             VARCHAR(50)
					,[RequestQty]       INT
					,[PackedQty]        INT
					,[CorrectQty]       BIT
					,[MultiContainer]   BIT
					,[Containers]       VARCHAR(200)
					,[Comment]          VARCHAR(500)
				)

				UPDATE S SET
					 [RequestQty] = TV.[RequestQty]
					,[PackedQty]  = TV.[PackedQty]
					,[Comment]    = TV.[Comment]
					,[FlagReason] = 1
				FROM #TB_DataPacking AS S
				INNER JOIN #TB_WOValidation AS TV ON TV.[ItemDetailID] = S.[ItemDetailID] AND S.[ManufactureID] = TV.[ManufactureID] AND S.[GarmentSize] = TV.[Size]
				WHERE S.[Comment] IS NULL

				IF EXISTS (SELECT TOP 1 * FROM #TB_WOValidation)
				BEGIN

					SET @resultReasons = (
						SELECT
							 ID
							,Reason
						FROM AppsLCA.dbo.TB_PackingData_ResonsToApprove WITH(NOLOCK)
						WHERE [status] = 1
						FOR JSON PATH, INCLUDE_NULL_VALUES
					)
				END
----- =========================================== VALIDACION UNIDADES DE WORK ORDER EN WAYBILL (ItemDetailID) ====================================================


----- =========================================== PROCESO PARA VALIDAR TRACKINGNO ====================================================
				-- --- DESHABILITADO PORQUE L2 BRAND NO TRABAJA HOY NI MAÑANA. RR 20251127

				-- DROP TABLE IF EXISTS #L2_OrderItemDetail_Tracking
				-- DECLARE @sqlRemoteItemDetailIDForTracking NVARCHAR(MAX) = '
                --     SELECT DISTINCT 
				-- 		ItemDetailID, TrackingNo
                --     FROM [db1.legacycaps.com].[Production].[dbo].[prod_ShipDetail]   AS SD WITH(NOLOCK)
				-- 	INNER JOIN [db1.legacycaps.com].[Production].[dbo].[prod_ShipTracking] AS TR1 with (nolock) ON SD.ShipperNo = TR1.ShipperNo AND SD.ItemDetailID IN (' + @ids_ItemDetail + ')'

                -- -- 3. Creamos tabla temporal con los resultados
                -- CREATE TABLE #L2_OrderItemDetail_Tracking (
                --      [ItemDetailID]     INT
                --     ,[TrackingNo]     NVARCHAR(200)
                -- )

                -- -- PRINT @sql
                -- INSERT INTO #L2_OrderItemDetail_Tracking
                -- EXEC (@sqlRemoteItemDetailIDForTracking)


				-- -- SELECT * FROM #L2_OrderItemDetail_Tracking
				-- -- WHERE ItemDetailID IN ('5760979')
				
				-- -- SELECT * FROM #TB_GROUP_ItemDetailID
				-- -- WHERE ItemDetailID IN ('5760979')
				
				-- -- SELECT DISTINCT
				-- -- 			 ItemDetailID
				-- -- 			 ,TrackingNo
				-- -- 		FROM #L2_OrderItemDetail_Tracking
				-- -- WHERE ItemDetailID IN ('6048177')
						
				-- -- SELECT * FROM #TB_DataPacking
				-- -- WHERE ItemDetailID IN ('5760979')
				
				ALTER TABLE #TB_GROUP_ItemDetailID ADD ShipTo              VARCHAR(50) NULL;
				DROP TABLE IF EXISTS #TB_GROUP_ITEMDetailID_VALIDATION_TRACKING
				SELECT 
					 [ItemDetailID]     = GP.ItemDetailID
					,[ShipTo]           = ----VALIDACION POR ORDENES EXPORTADAS
											CASE
												WHEN GP.ItemDetailID IN (
																 5777500    ---20260702 CORREO Larissa Stiles
																,5777497    ---20260702 CORREO Larissa Stiles
																,5790228    ---20260702 CORREO Larissa Stiles
																,5777493    ---20260702 CORREO Larissa Stiles
																,5793888    ---20260702 CORREO Larissa Stiles
																,5793890    ---20260702 CORREO Larissa Stiles
																,5777523    ---20260702 CORREO Larissa Stiles
																,5777522    ---20260702 CORREO Larissa Stiles
																,5777499	---20260702 CORREO Larissa Stiles
																,5777513	---20260702 CORREO Larissa Stiles
																,5777526	---20260702 CORREO Larissa Stiles
																,6019264	---20260702 CORREO Larissa Stiles
																,6019267	---20260702 CORREO Larissa Stiles
																,5790246	---20260702 CORREO Ordenes de DICKS
																,5816550	---20260702 CORREO Ordenes de DICKS
																,6034515	---20260702 CORREO Ordenes de DICKS
																,5793889	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008398	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008397	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008396	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008394	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008392	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008391	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008389	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008393	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008395	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008399	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5775385	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5777531	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5777534	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5790232	--- 20260711 Ordenes de Dicks autorizado por RA 
																,6046147	--- 20260711 Ordenes de Dicks autorizado por RA 
																,6046155	--- 20260711 Ordenes de Dicks autorizado por RA 
																,6046156	--- 20260711 Ordenes de Dicks autorizado por RA 
																,6046157	--- 20260711 Ordenes de Dicks autorizado por RA 
																,6046158	--- 20260711 Ordenes de Dicks autorizado por RA 
																,6046159	--- 20260711 Ordenes de Dicks autorizado por RA 
																,6046160	--- 20260711 Ordenes de Dicks autorizado por RA 
																,6046161	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5775377	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5775387	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5775389	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5775393	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5775397	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5777492	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5777514	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5777521	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5777527	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5793894	--- 20260711 Ordenes de Dicks autorizado por RA 
																,6034514	--- 20260711 Ordenes de Dicks autorizado por RA 
																,6034516	--- 20260711 Ordenes de Dicks autorizado por RA 
																,6034520	--- 20260711 Ordenes de Dicks autorizado por RA 
																,5972087	--- 20260729 Ordenes de Dicks 
																,5972088	--- 20260729 Ordenes de Dicks 
																,5972095	--- 20260729 Ordenes de Dicks 
																,5972096	--- 20260729 Ordenes de Dicks 
																,5972086	--- 20260729 Ordenes de Dicks 
																,5972097	--- 20260729 Ordenes de Dicks 
																,5993561	--- 20260729 Ordenes de Dicks 
																,5993562	--- 20260729 Ordenes de Dicks 
																,5993564	--- 20260729 Ordenes de Dicks 
																,5993570	--- 20260729 Ordenes de Dicks 
																,6004416	--- 20260729 Ordenes de Dicks 
																,6004418	--- 20260729 Ordenes de Dicks 
																,6010679	--- 20260729 Ordenes de Dicks 
																,6010681	--- 20260729 Ordenes de Dicks 
																,6094443	--- 20260729 Ordenes de Dicks 
																,6010680	--- 20260729 Ordenes de Dicks 
																,5971940	--- 20260729 Ordenes de Dicks 
																,5993559	--- 20260729 Ordenes de Dicks 
																,5971942	--- 20260730 Ordenes de Dicks
																,5972091	--- 20260730 Ordenes de Dicks
																,6069800	--- 20260730 Ordenes de Dicks
																,6069799	--- 20260731 Ordenes de Dicks
																,6010679	--- 20260731 Ordenes de Dicks
																,6010681	--- 20260731 Ordenes de Dicks
																,5920877	--- 20260810 Ordenes de Dicks
																,5920878	--- 20260731 Ordenes de Dicks
																,5920986	--- 20260731 Ordenes de Dicks
																,5921129	--- 20260731 Ordenes de Dicks
																,5921130	--- 20260731 Ordenes de Dicks
																,5921131	--- 20260731 Ordenes de Dicks
																,6037535	--- 20260813 Waybill APP-20260813 
																,5814934	--- 20260813 Waybill APP-20260813
																,5920982	--- 20260813 Waybill APP-20260813
																,5920983	--- 20260813 Waybill APP-20260813
																,5920984	--- 20260813 Waybill APP-20260813
																,5920994	--- 20260813 Waybill APP-20260813
																,5920995	--- 20260813 Waybill APP-20260813
																,5920996	--- 20260813 Waybill APP-20260813
																,5921135	--- 20260813 Waybill APP-20260813
																,5921136	--- 20260813 Waybill APP-20260813
																,5921137	--- 20260813 Waybill APP-20260813
																,5921147	--- 20260813 Waybill APP-20260813
																,5921149	--- 20260813 Waybill APP-20260813
																,5921150	--- 20260813 Waybill APP-20260813
																,5921151	--- 20260813 Waybill APP-20260813
																,6021988	--- 20260813 Waybill APP-20260813
																,6022007	--- 20260813 Waybill APP-20260813
																,6022008	--- 20260813 Waybill APP-20260813
																,6069791	--- 20260813 Waybill APP-20260813
																,6010676	--- 20260813 Waybill AIR-APP-20260813
																,6010677	--- 20260813 Waybill AIR-APP-20260813
																,6010678	--- 20260813 Waybill AIR-APP-20260813
																,6061787	--- 20260813 Waybill AIR-APP-20260813
																,6061784	--- 20260813 Waybill AIR-APP-20260813
																,6021989	--- 20260813 Waybill AIR-APP-20260813
																,6061791	--- 20260813 Waybill AIR-APP-20260813
																,6061795	--- 20260813 Waybill AIR-APP-20260813
																,6045738	--- 20260813 Waybill AIR-APP-20260813
																,6045739	--- 20260813 Waybill AIR-APP-20260813
																,6052444
																,6052446
																,5920873
																,5920874
																,6069794
																,5920879
																,5920880
																,6021974
																,6152196
																,6021980
																,6016258
																,6059756
																,5510446
																,6131467
																,5865732
																,6021981
																,6061734
																,5920989
																,5920992
																,5921133
																,5930237
																,5801576
																,5921155
																,6059586
																,6152177
																,6152206
																,5920979
																,5920980
																,5920981
																,5920999
																,5921001
																,5921002
																,5921004
																)			
													THEN 'Hanover'
											ELSE B.ShipTo
											END
					,[ExistTracking]    = CAST(NULL AS BIT)          
				INTO #TB_GROUP_ITEMDetailID_VALIDATION_TRACKING
				FROM #TB_GROUP_ItemDetailID AS GP
				LEFT JOIN (
                    SELECT 
                         [R]            = ROW_NUMBER() OVER(PARTITION BY Logs.ItemDetailID ORDER BY Logs.ItemDetailID , Logs.Insert_time DESC)
                        ,[ItemDetailID] = Logs.[ItemDetailID]
                        ,[ShipTo]       = Logs.[Ship To]
                    FROM        #TB_DataPacking AS DP 
                    INNER JOIN [192.168.1.93].[AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export_Logs] AS Logs WITH(NOLOCK) ON Logs.ItemDetailID = DP.ItemDetailID
				) AS B ON GP.ItemDetailID = B.ItemDetailID AND B.[R] =1
				-- WHERE B.ShipTo = 'Miami'
				
				
				UPDATE S SET
					[ExistTracking] = CASE 
										WHEN S.ShipTo = 'Hanover'  THEN 1
										WHEN S.ShipTo = 'Miami' AND B.ExistTracking > 0 THEN 1
										ELSE 0
										END
										-- IIF(B.ExistTracking = 0 , 0,1)
				FROM #TB_GROUP_ITEMDetailID_VALIDATION_TRACKING AS S
				LEFT JOIN (
					SELECT
						 ItemDetailID
						,COUNT(DISTINCT TrackingNumber) AS ExistTracking
					FROM
					(
						SELECT DISTINCT
							 ItemDetailID
							 ,TrackingNumber
						FROM #TB_DataPacking
						WHERE TrackingNumber IS NOT NULL
					
					) AS TR
					GROUP BY ItemDetailID
				) AS B ON B.ItemDetailID = S.ItemDetailID

				IF EXISTS (SELECT TOP 1 * FROM #TB_GROUP_ITEMDetailID_VALIDATION_TRACKING WHERE ExistTracking = 0)
				BEGIN

					EXEC [AppsLCA].[dbo].[SP_UPDATE_PackedBoxes_TrackingNo] @process = 'trackingno.update', @data = NULL, @NoSelect = 1

					UPDATE DP SET
						TrackingNumber = PB.[BoxComments6]
					FROM #TB_DataPacking AS DP
					INNER JOIN LCA.dbo.PackedBoxes AS PB WITH(NOLOCK) ON DP.[BoxNumber] = PB.[BoxNumber] AND DP.[TrackingNumber] IS NULL

					UPDATE S SET
					[ExistTracking] = CASE 
										WHEN S.ShipTo = 'Hanover'  THEN 1
										WHEN S.ShipTo = 'Miami' AND B.ExistTracking > 0 THEN 1
										ELSE 0
										END
										-- IIF(B.ExistTracking = 0 , 0,1)
					FROM #TB_GROUP_ITEMDetailID_VALIDATION_TRACKING AS S
					LEFT JOIN (
						SELECT
							ItemDetailID
							,COUNT(DISTINCT TrackingNumber) AS ExistTracking
						FROM
						(
							SELECT DISTINCT
								ItemDetailID
								,TrackingNumber
							FROM #TB_DataPacking
							WHERE TrackingNumber IS NOT NULL
						
						) AS TR
						GROUP BY ItemDetailID
					) AS B ON B.ItemDetailID = S.ItemDetailID
					WHERE S.ExistTracking = 0
				END
				
				-- SELECT * FROM #TB_GROUP_ITEMDetailID_VALIDATION_TRACKING
				
				-- RETURN
				-----------actualizacion RR,JH: SOLICITUD DE TJ. DEBE VALIDAR QUE TODO LO QUE VA PARA MIAMI DEBE TENER TRACKING
				-- UPDATE DP SET
				-- 	[Comment] = 'Orders without Tracking No'
				-- FROM #TB_DataPacking AS DP
				-- LEFT JOIN #TB_GROUP_ITEMDetailID_VALIDATION_TRACKING AS S ON DP.ItemDetailID = S.ItemDetailID and dp.ItemDetailID = 6048177
				-- WHERE (S.ExistTracking = 0)
				-- --- SE QUITAN ESTILOS DE NOTRE DAME PARA EL TRACKING PUES SE HACE UN PROCESO DISTINTO
				-- AND DP.StyleNumber NOT IN ('NDS100','NDS110','NDS150','NDS200','NDS250')
				-- AND (DP.ItemDetailID <> 6054469 AND DP.WayBill = 'AIR-APP-20260722')
				-- AND (DP.ItemDetailID NOT IN (6059901,6059899,6054469,6063040,6045656,6059900) AND DP.WayBill = 'AIR-APP-20260722-1')

				UPDATE DP SET
					[Comment] = 'Orders without Tracking No'
				FROM #TB_DataPacking AS DP
				LEFT JOIN #TB_GROUP_ITEMDetailID_VALIDATION_TRACKING AS S ON DP.ItemDetailID = S.ItemDetailID
				WHERE (S.ExistTracking = 0)

					 --SELECT * FROM #TB_DataPacking where ItemDetailID = 6054469
					 --return				
					
				-- UPDATE DP SET
				-- 	[Comment] = 'Orders without Tracking No'
				-- FROM #TB_DataPacking AS DP
				-- LEFT JOIN
				-- (
				-- 	SELECT
				-- 		 ItemDetailID
				-- 		,COUNT(DISTINCT TrackingNo) AS ExistTracking
				-- 	FROM
				-- 	(
				-- 		SELECT DISTINCT
				-- 			 ItemDetailID
				-- 			 ,TrackingNo
				-- 		FROM #L2_OrderItemDetail_Tracking
					
				-- 	) AS TR
				-- 	GROUP BY ItemDetailID
				-- ) AS TR ON DP.ItemDetailID = TR.ItemDetailID
				-- LEFT JOIN (
                --     SELECT 
                --          [R]            = ROW_NUMBER() OVER(PARTITION BY Logs.ItemDetailID ORDER BY Logs.ItemDetailID , Logs.Insert_time DESC)
                --         ,[ItemDetailID] = Logs.[ItemDetailID]
                --         ,[ShipTo]       = Logs.[Ship To]
                --     FROM        #TB_DataPacking AS DP 
                --     INNER JOIN [192.168.1.93].[AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export_Logs] AS Logs WITH(NOLOCK) ON Logs.ItemDetailID = DP.ItemDetailID
                -- ) AS B ON DP.ItemDetailID = B.ItemDetailID AND B.[R] =1
				-- WHERE (ExistTracking is null or ExistTracking = 0) AND DP.DetailStatus = 38 AND
				-- DP.StyleNumber NOT IN ('NDS100','NDS110','NDS150','NDS200','NDS250')
				
				--- SE QUITAN ESTILOS DE NOTRE DAME PARA EL TRACKING PUES SE HACE UN PROCESO DISTINTO
----- =========================================== PROCESO PARA VALIDAR TRACKINGNO ====================================================

----- =========================================== VALIDACION SHIPTO = PUERTO DESTINO ====================================================
				--- ShipTo (destino real segun logs de exportacion) debe coincidir con el PuertoDestino de la orden (mismo criterio que SP_ShipmentCheckPrices)
				UPDATE DP SET
					[Comment] = 'ShipTo does not match Destination Port'
				FROM #TB_DataPacking AS DP
				INNER JOIN #TB_GROUP_ITEMDetailID_VALIDATION_TRACKING AS S ON DP.ItemDetailID = S.ItemDetailID
				WHERE DP.[Comment] IS NULL
				AND DP.[PuertoDestino] IS NOT NULL
				AND S.[ShipTo] IS NOT NULL
				AND LEFT(DP.[PuertoDestino], LEN(S.[ShipTo])) <> S.[ShipTo]
----- =========================================== VALIDACION SHIPTO = PUERTO DESTINO ====================================================

				DROP TABLE IF EXISTS #TB_SummaryBoxes
				SELECT
					 [R]					= ROW_NUMBER() OVER(ORDER BY 
					 												 S.[Waybill]
																	,S.[FormattedBoxNumber]
																 )
					,[WayBill]				= S.[Waybill]
					,[BoxNumer]	            = S.[FormattedBoxNumber]
					,[BoxAmazon]            = (SELECT TOP 1 [BoxAmazon] FROM #TB_DataPacking WHERE [FormattedBoxNumber] = S.[FormattedBoxNumber])
					,[FirstAPS]				= (SELECT TOP 1 [APS] FROM #TB_DataPacking WHERE [FormattedBoxNumber] = S.[FormattedBoxNumber])
					,[FirstPONumber]		= (SELECT TOP 1 [PONumber] FROM #TB_DataPacking WHERE [FormattedBoxNumber] = S.[FormattedBoxNumber])
					,[VolumeBox]			= S.[VolumeBox]
					,[FirstStyle]			= (SELECT TOP 1 [StyleNumber] FROM #TB_DataPacking WHERE [FormattedBoxNumber] = S.[FormattedBoxNumber])
					,[Weight]				= (SELECT SUM([GrossWeightKGSData]) FROM #TB_DataPacking WHERE [FormattedBoxNumber] = S.[FormattedBoxNumber]  )
					,[Units]				= SUM(S.[Units])

				INTO #TB_SummaryBoxes
				FROM #TB_DataPacking	AS S
				GROUP BY 
					 S.[WayBill]
					,S.[FormattedBoxNumber]
					,S.[VolumeBox]

				
				-- select * from #TB_DataPacking WHERE FormattedBoxNumber = '00917362'
				-- select * from #TB_SummaryBoxes WHERE FormattedBoxNumber = '00917362'	
				SET @messageData = (
						SELECT
							(
							SELECT
								[R]
								,[Comment]
								,[Waybill]
								,[CustomerOrder]
								,[BoxNumber]        = [FormattedBoxNumber]
								,[APS]
								,[PONumber]
								,[ItemDetailID]
								,[MO]
								,[Style]            = [StyleNumber]
								,[Color]			= [StyleColor]
								,[Size]             = [GarmentSize]
								,[Units]            
								,RequestQty
								,PackedQty
								,[GrossWeightKGSData]
								,[BoxStatus]
								,[ProductDivision]
								,[SupplNo]
								,[DetailStatusName]								
							FROM #TB_DataPacking WHERE [Comment] <> 'OK' OR [Comment] IS NOT NULL
							ORDER BY [R]

							FOR JSON PATH, INCLUDE_NULL_VALUES
							) AS messageData
							FOR JSON PATH, INCLUDE_NULL_VALUES
				)
				
								
				SET @result =
                        (
						 SELECT
							(
								SELECT *
								FROM #TB_SummaryPacking
								FOR JSON PATH, INCLUDE_NULL_VALUES
							) AS SummaryPacking
							,(
								SELECT *
								FROM #TB_DataPacking
								ORDER BY [R]
								FOR JSON PATH, INCLUDE_NULL_VALUES
							) AS DataPacking
							,(
								SELECT *
								FROM #TB_SummaryBoxes
								ORDER BY [R]
								FOR JSON PATH, INCLUDE_NULL_VALUES
							) AS SummaryBoxes
						FOR JSON PATH, INCLUDE_NULL_VALUES
								
                        )

				SET @error		= 0
				SET @message	= 'Datos obtenidos correctamente.' 

            END    

		----------------------------------------------------------------------------------------------------
		---------------------------generate.PackingListBeforeShipment---------------------------------------
		----------------------------------------------------------------------------------------------------
		ELSE
		----------------------------------------------------------------------------------------------------
		---------------------------generate.PackingListSumMos---------------------------------------
		----------------------------------------------------------------------------------------------------
			IF @process = 'generate.PackingListSumMos'
			BEGIN
				PRINT 'PROCESO generate.PackingListSumMos'
				PRINT FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss')
				

			
				
				DECLARE @listWaybills_ListMOS		AS NVARCHAR(MAX)
				SET @listWaybills_ListMOS			= (SELECT JSON_QUERY(@data, '$.selectedOptions'))

				DROP TABLE IF EXISTS #TB_PACKING_LIST_BEFORE_SHIPMENT_ListMOS
				SELECT 
				     [rowN]			= STJ.[R]
					,[Waybill]		= STJ.[Waybill] 
				INTO #TB_PACKING_LIST_BEFORE_SHIPMENT_ListMOS
				FROM OPENJSON(@listWaybills_ListMOS)
				WITH (	 
						[R]			INT
						,[Waybill]		VARCHAR(200)
					) AS STJ
				
				-- SELECT * FROM #TB_PACKING_LIST_BEFORE_SHIPMENT_ListMOS
				
				DROP TABLE IF EXISTS #TB_DataPacking_ListMOS
				SELECT	
						[R]							= ROW_NUMBER() OVER(ORDER BY 
																				sh.[Waybill]
																				,IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[DropDownValue],'000'),3) ) 
																							,pb.[BoxNumber] 
																						)
																			)
						,[Comment]                      = CAST(NULL AS VARCHAR(MAX))
						,[WayBill]						= sh.[WayBill]
						,[CustomerOrder]                = SUBSTRING(OD.[Comments6], 1, 9)
						,[BoxNumber]					= pb.[BoxNumber]
						,[FormattedBoxNumber]			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT('PPPA'+Ltrim(Str(pp.PackedPalletID+1000000)),'-',RIGHT(btg.DropDownValue,3)) 
																	,pb.[BoxNumber] 
																)
						-- ,[FormattedBoxNumber]			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[DropDownValue],'000'),3) ) 
						-- 											,pb.[BoxNumber] 
						-- 										)
                        ,[BoxAmazon]                    = pb.BoxComments4
						,[APS]				            = od.[Comments6]
						,[PONumber]						= od.[ponumber]
						,[ItemDetailID]                 = CASE 
		                                                    WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
		                                                        NULL
		                                                    WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
		                                                        cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT) 
		                                                    WHEN ( od.[PONumber] LIKE 'ORD%') and (ISNUMERIC(od.Comments6) = 1 ) THEN
		                                                        cast(od.[Comments6] AS BIGINT)
		                                                    ELSE
		                                                        NULL 
		                                                    END 
						,[Order]						= od.[OrderNumber]
						,[StyleNumber]					= sti.[stylenumber]
						,[StyleColor]					= stc.[stylecolorname]
						,[GarmentSize]					= fg.[garmentsize]
						,[Units]						= CAST(pbi.[quantity] AS INT)
						,[GrossWeightKGSData]           = CAST(NULL AS DECIMAL(24,10))
						,[Label]						= pb.[BoxLabel]
						-- ,[VolumeBox]					= CONCAT(	CAST(bxtp.BoxLength AS VARCHAR),'*',CAST(bxtp.[BoxWidth] AS VARCHAR),'*',CAST(bxtp.[BoxHeight] AS VARCHAR))
						,[VolumeBox]					= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL
																,CONCAT(	CAST(ppt.[PalletLength] AS VARCHAR),'*',CAST(ppt.[PalletWidth] AS VARCHAR),'*',CAST(ppt.[PalletHeight] AS VARCHAR))
																,CONCAT(	CAST(bxtp.[BoxLength] AS VARCHAR),'*',CAST(bxtp.[BoxWidth] AS VARCHAR),'*',CAST(bxtp.[BoxHeight] AS VARCHAR))
															)
																		
						-- ,[BoxType]						= bxtp.[BoxTypeName]     
						,[BoxType]						= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL
																,ppt.[PalletTypeName]
																,bxtp.[BoxTypeName]
															)
						     
						,[BoxStatus]					= snpb.[StatusName]
						,[Bin]						  	= gb.[Bin]
						,[ProductDivision]              = sti.Comments9
						,[ManufactureID]			    = pbi.ManufactureID 
						,[MO]                           = MO.ManufactureNumber
						,[MOStatusID]					= MO.StatusID
						,[MOStatus]						= SMO.StatusName
						,[SupplNo]                      = CAST(NULL AS VARCHAR(50))
						,[DetailStatus]                 = CAST(NULL AS VARCHAR(100))
                        ,[DetailStatusName]             = CAST(NULL AS VARCHAR(200))
                        ,[ShippingContainerID]          = sh.ShippingContainerID
						,[PuertoDestino]				= PD.DropDownValue
						,[SuspendOrd]					= CAST(COALESCE(OS.SWHOLD,0) AS BIT) --- Requerimiento de RA para identificar órdenes suspendidas --- RR 20260212
						,[SuspendType]					= OS.SuspendType
	 					-- ,[GoodsBinID]				  	= gb.[GoodsBinID]
				INTO #TB_DataPacking_ListMOS
				FROM   		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID = 75 ) AS FSN 
				INNER JOIN	LCA.dbo.statusnames						AS snpb	WITH(NOLOCK)	ON snpb.StatusID			= FSN.StatusID			AND snpb.StatusID = 75 
				INNER JOIN	LCA.dbo.packedboxes						AS pb	WITH(NOLOCK)	ON pb.statusid				= snpb.statusid			AND pb.orderid IS NOT NULL
				LEFT JOIN	LCA.dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid			--AND sh.ShipDate > DATEADD(month,-2,convert(date,getdate()))
				INNER JOIN	#TB_PACKING_LIST_BEFORE_SHIPMENT_ListMOS		AS TB					ON TB.Waybill				= sh.WayBill
				INNER JOIN	LCA.dbo.packeditems						AS pbi	WITH(NOLOCK)	ON pbi.packedboxid			= pb.packedboxid		AND pbi.quantity > 0  
				INNER JOIN	LCA.dbo.finishedgoods					AS fg	WITH(NOLOCK)	ON pbi.finishedgoodsid		= fg.finishedgoodsid 
				INNER JOIN	LCA.dbo.styles							AS sti	WITH(NOLOCK)	ON fg.styleid				= sti.styleid 
				LEFT JOIN	LCA.dbo.GoodsBins						AS gb	WITH(NOLOCK)	ON gb.GoodsBinID			= pb.GoodsBinID
				LEFT JOIN	LCA.dbo.ManufactureOrders				AS MO	WITH(NOLOCK)	ON MO.ManufactureID			= pbi.ManufactureID	
				LEFT JOIN	LCA.dbo.htsstylecodes					AS hts	WITH(NOLOCK)	ON sti.htsstylecodeid		= hts.htsstylecodeid 
				LEFT JOIN	LCA.dbo.stylecolors						AS stc	WITH(NOLOCK)	ON fg.stylecolorid			= stc.stylecolorid 	
				LEFT JOIN	LCA.dbo.orderdetails					AS odd	WITH(NOLOCK)	ON pbi.orderdetailsid		= odd.orderdetailsid 
				LEFT JOIN	LCA.dbo.orderitems						AS oi	WITH(NOLOCK)	ON odd.orderitemid			= oi.orderitemid 
				LEFT JOIN	LCA.dbo.invoicebatches					AS inb	WITH(NOLOCK)	ON sh.invoicebatchid		= inb.invoicebatchid 
				LEFT JOIN	LCA.dbo.orders							AS od	WITH(NOLOCK)	ON pb.orderid				= od.orderid 
				LEFT JOIN	LCA.dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid 
				LEFT JOIN	LCA.dbo.Warehouses						AS wh	WITH(NOLOCK)	ON wh.WarehouseID			= pb.WarehouseID
				LEFT JOIN	LCA.dbo.Styles							AS st	WITH(NOLOCK)	ON st.StyleID				= sti.BlankStyleID
				LEFT JOIN	LCA.dbo.ShippingContainers				AS sc	WITH(NOLOCK)	ON sc.ShippingContainerID	= sh.ShippingContainerID
				LEFT JOIN	LCA.dbo.DropDownValues3					AS btg	WITH(NOLOCK)	ON btg.DropDownValueID		= pb.BoxTagID			AND btg.DropDownID = 19
				LEFT JOIN   LCA.dbo.PalletTypes						AS ppt  WITH(NOLOCK)	ON pp.PalletTypeID			= ppt.PalletTypeID  
				LEFT JOIN	LCA.dbo.boxtypes						AS bxtp WITH(NOLOCK)	ON pb.boxtypeid				= bxtp.boxtypeid
				LEFT JOIN	LCA.dbo.DropDownValues3					AS PD	WITH(NOLOCK)	ON od.OrderTypeID3			= PD.DropDownValueID
				LEFT JOIN	AppsLCA.legacycaps.OrdersSuspended		AS OS	WITH(NOLOCK)	ON MO.ManufactureID			= OS.ManufactureID
				LEFT JOIN	LCA.dbo.StatusNames						AS SMO	WITH(NOLOCK)	ON MO.StatusID				= SMO.StatusID


				------------------------------CALCULO DE PESO POR CAJA / CAJA CONSOLIDADA------------------------------
                    PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  TABLA TB_UnitsBox_Weight')
                    DROP TABLE IF EXISTS #TB_UnitsBox_Weight_ListMOS
    				SELECT 
    				     [FormattedBoxNumber]			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT('PPPA'+Ltrim(Str(pp.PackedPalletID+1000000)),'-',RIGHT(btg.DropDownValue,3)) 
    																	,pb.[BoxNumber] 
    																)
    				    ,[Quantity]                     = SUM(ROUND(pbi.[quantity],2)) 
    				INTO #TB_UnitsBox_Weight_ListMOS
    				FROM   		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID IN(27,25,75)) AS FSN 
    				INNER JOIN	LCA.dbo.statusnames						AS snpb	WITH(NOLOCK)	ON snpb.StatusID			= FSN.StatusID			AND snpb.StatusID = 75
    				INNER JOIN	LCA.dbo.packedboxes						AS pb	WITH(NOLOCK)	ON pb.statusid				= snpb.statusid			AND pb.orderid IS NOT NULL
    				INNER JOIN	LCA.dbo.orders							AS od	WITH(NOLOCK)	ON pb.orderid				= od.orderid			
				    LEFT JOIN	LCA.dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid			--AND sh.ShipDate > DATEADD(month,-2,convert(date,getdate()))
					INNER JOIN	#TB_PACKING_LIST_BEFORE_SHIPMENT_ListMOS		AS TB					ON TB.Waybill				= sh.WayBill
    				LEFT JOIN	LCA.dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid 
    				LEFT JOIN   LCA.dbo.PalletTypes						AS ppt  WITH(NOLOCK)	ON pp.PalletTypeID			= ppt.PalletTypeID  
    				LEFT JOIN	LCA.dbo.DropDownValues3					AS btg	WITH(NOLOCK)	ON btg.DropDownValueID		= pb.BoxTagID			AND btg.DropDownID = 19
    				INNER JOIN	LCA.dbo.packeditems						AS pbi	WITH(NOLOCK)	ON pbi.packedboxid			= pb.packedboxid		AND pbi.quantity > 0  
    				GROUP BY  
    				    IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT('PPPA'+Ltrim(Str(pp.PackedPalletID+1000000)),'-',RIGHT(btg.DropDownValue,3)) 
    																	,pb.[BoxNumber] 
    																)
    				
    				
                    PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  TABLA TB_Box_Weight')
                    DROP TABLE IF EXISTS #TB_Box_Weight_ListMOS
    				SELECT
    				     [FormattedBoxNumber]    = TB_BOX.[FormattedBoxNumber]
    				    ,[WeighBox]              = TB_BOX.[WeighBox]
    				INTO #TB_Box_Weight_ListMOS
    				FROM(
    				    SELECT
    				         [FormattedBoxNumber]           = TB_G.[FormattedBoxNumber]
    				        ,[WeighBox]                     = ROUND(SUM(TB_G.[weight]) + (SUM(TB_G.[PalletWeight]) / COUNT(TB_G.[BoxNumber])),2)
    				    FROM(
            				SELECT 
            				     [FormattedBoxNumber]			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT('PPPA'+Ltrim(Str(pp.PackedPalletID+1000000)),'-',RIGHT(btg.DropDownValue,3)) 
            																	,pb.[BoxNumber] 
            																)
            				    ,[Weight]                       = COALESCE(pb.[Weight],0.0000)
            				    ,[PalletWeight]                 = IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , ppt.[PalletWeight],0.0000)
            				    ,[BoxNumber]                    = pb.[BoxNumber]
            				    ,[TypeBoxFinal]                 = IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , 1,0)
                                                                                
            				FROM   		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID IN(27,25,75)) AS FSN 
            				INNER JOIN	LCA.dbo.statusnames						AS snpb	WITH(NOLOCK)	ON snpb.StatusID			= FSN.StatusID			AND snpb.StatusID = 75
            				INNER JOIN	LCA.dbo.packedboxes						AS pb	WITH(NOLOCK)	ON pb.statusid				= snpb.statusid			AND pb.orderid IS NOT NULL
            				INNER JOIN	LCA.dbo.orders							AS od	WITH(NOLOCK)	ON pb.orderid				= od.orderid			
            				LEFT JOIN	LCA.dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid			--AND sh.ShipDate > DATEADD(month,-2,convert(date,getdate()))
							INNER JOIN	#TB_PACKING_LIST_BEFORE_SHIPMENT_ListMOS		AS TB					ON TB.Waybill				= sh.WayBill
            				LEFT JOIN	LCA.dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid 
            				LEFT JOIN   LCA.dbo.PalletTypes						AS ppt  WITH(NOLOCK)	ON pp.PalletTypeID			= ppt.PalletTypeID  
            				LEFT JOIN	LCA.dbo.DropDownValues3					AS btg	WITH(NOLOCK)	ON btg.DropDownValueID		= pb.BoxTagID			AND btg.DropDownID = 19                                              
        				) AS TB_G
        				GROUP BY 
        				      [FormattedBoxNumber]
        				     ,[TypeBoxFinal]
    				) AS TB_BOX
    				
                    PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  UPDATE Weight')
    				UPDATE S SET
    				    [GrossWeightKGSData]    = IIF(TB_BOX.[WeighBox] > 0 AND PBUnits.[Quantity] > 0, (TB_BOX.[WeighBox] / PBUnits.[Quantity]),0) * S.[Units]
    				FROM #TB_DataPacking_ListMOS            AS S
    				LEFT JOIN #TB_Box_Weight_ListMOS        AS TB_BOX       ON TB_BOX.[FormattedBoxNumber]  = S.[FormattedBoxNumber]
    				LEFT JOIN #TB_UnitsBox_Weight_ListMOS   AS PBUnits      ON PBUnits.[FormattedBoxNumber] = S.[FormattedBoxNumber]
                
				------------------------------CALCULO DE PESO POR CAJA / CAJA CONSOLIDADA------------------------------
				
				-- SELECT * FROM #TB_DataPacking_ListMOS
				
				
				
				DROP TABLE IF EXISTS #TB_MO_DataPacking_UNIQUE_ListMOS
				SELECT DISTINCT
					 [ManufactureID]
					,[MO]
				INTO #TB_MO_DataPacking_UNIQUE_ListMOS
				FROM #TB_DataPacking_ListMOS
				WHERE [ManufactureID] IS NOT NULL
				
				DROP TABLE IF EXISTS #TB_EORO_Packing_ListMOS
				SELECT 
					 [ManufactureID]	= [ManufactureID]
					,[Size]		        = [Size]
					,[Validation]       = MAX(IIF( [QuantityNeeded] <> 0 OR [QuantityPacked] > [QuantityRequired] ,1,0))
				INTO #TB_EORO_Packing_ListMOS
				FROM(
					SELECT 
						 [ManufactureID]        = TB.ManufactureID
						,[MO]			        = TB.MO					
						,[Size]                 = FG.GarmentSize
						,[QuantityRequired]     = MB.QuantityRequired
						,[QuantityWithdrawn]    = MB.QuantityWithdrawn
						,[QuantityNeeded]       = MB.QuantityRequired - MB.QuantityWithdrawn
						,[QuantityPacked]       = ( SELECT SUM(COALESCE(pbi.Quantity,0)) 
													FROM        LCA.dbo.PackedItems     AS pbi WITH(NOLOCK) 
													INNER JOIN  LCA.dbo.FinishedGoods   AS fgi WITH(NOLOCK) ON fgi.FinishedGoodsID = pbi.FinishedGoodsID 
																AND pbi.ManufactureID   = TB.ManufactureID
																AND FG.GarmentSize      = fgi.GarmentSize
												)
					-- ,MB.*
					FROM #TB_MO_DataPacking_UNIQUE_ListMOS AS TB
					INNER JOIN  LCA.dbo.ManufactureBlanks    AS MB WITH(NOLOCK) ON MB.ManufactureID     = TB.ManufactureID      ---AND (MB.QuantityRequired - MB.QuantityWithdrawn) <> 0
					INNER JOIN  LCA.dbo.FinishedGoods        AS FG WITH(NOLOCK) ON FG.FinishedGoodsID   = MB.FinishedGoodsID
					where MB.QuantityRequired > 0 ----- PARA EVITAR ERROR DE 2 SEASONS. AGREGADO POR RR 20251209
				) AS TB
				WHERE IIF( [QuantityNeeded] <> 0 OR [QuantityPacked] > [QuantityRequired] ,1,0) = 1
				GROUP BY
					[ManufactureID]
					,[Size]
				
				

				DROP TABLE IF EXISTS #TB_SummaryPacking_ListMOS
				SELECT
					 [WayBill]		= COALESCE(S.[WayBill],'Total')
					,[Bins]			= COUNT(DISTINCT S.[Bin])
					,[Boxes]		= COUNT(DISTINCT S.[FormattedBoxNumber])
					,[Units]		= SUM(S.[Units])
				INTO #TB_SummaryPacking_ListMOS
				FROM #TB_DataPacking_ListMOS	AS S
				GROUP BY ROLLUP(S.[WayBill])
				
				
----- =========================================== PROCESO PARA VALIDAR TRACKINGNO ====================================================
				
				DROP TABLE IF EXISTS #TB_SummaryBoxes_ListMOS
				SELECT
					 [R]					= ROW_NUMBER() OVER(ORDER BY 
					 												 S.[Waybill]
																	,S.[FormattedBoxNumber]
																 )
					,[WayBill]				= S.[Waybill]
					,[BoxNumer]	            = S.[FormattedBoxNumber]
					,[BoxAmazon]            = (SELECT TOP 1 [BoxAmazon] FROM #TB_DataPacking_ListMOS WHERE [FormattedBoxNumber] = S.[FormattedBoxNumber])
					,[FirstAPS]				= (SELECT TOP 1 [APS] FROM #TB_DataPacking_ListMOS WHERE [FormattedBoxNumber] = S.[FormattedBoxNumber])
					,[FirstPONumber]		= (SELECT TOP 1 [PONumber] FROM #TB_DataPacking_ListMOS WHERE [FormattedBoxNumber] = S.[FormattedBoxNumber])
					,[VolumeBox]			= S.[VolumeBox]
					,[FirstStyle]			= (SELECT TOP 1 [StyleNumber] FROM #TB_DataPacking_ListMOS WHERE [FormattedBoxNumber] = S.[FormattedBoxNumber])
					,[Weight]				= (SELECT SUM([GrossWeightKGSData]) FROM #TB_DataPacking_ListMOS WHERE [FormattedBoxNumber] = S.[FormattedBoxNumber]  )
					,[Units]				= SUM(S.[Units])

				INTO #TB_SummaryBoxes_ListMOS
				FROM #TB_DataPacking_ListMOS	AS S
				GROUP BY 
					 S.[WayBill]
					,S.[FormattedBoxNumber]
					,S.[VolumeBox]

				-- SELECT * FROM #TB_SummaryBoxes_ListMOS
				
				
				-- select * from #TB_DataPacking WHERE FormattedBoxNumber = '00917362'
				-- select * from #TB_SummaryBoxes WHERE FormattedBoxNumber = '00917362'	
				-- SET @messageData = NULL
				
								
								
				SET @result =
                        (
						 SELECT
							(
								SELECT  * 
								FROM #TB_SummaryPacking_ListMOS
								FOR JSON PATH, INCLUDE_NULL_VALUES
							) AS SummaryPacking
							-- ,(
							-- 	SELECT top 1 * 
							-- 	FROM #TB_DataPacking
							-- 	ORDER BY [R]
							-- 	FOR JSON PATH, INCLUDE_NULL_VALUES
							-- ) AS DataPacking
							,(
								SELECT 
									 [Waybill]
									,[ManufactureID]
									,[MO]
									,[Units]            = SUM([Units])
								-- select * 
								FROM #TB_DataPacking_ListMOS
								GROUP BY
									 [Waybill]
									,[ManufactureID]
									,[MO]
								ORDER BY [Waybill]
								FOR JSON PATH, INCLUDE_NULL_VALUES
							) AS DataPacking
							-- ,(
							-- 	SELECT top 5 * 
							-- 	FROM #TB_SummaryBoxes
							-- 	ORDER BY [R]
							-- 	FOR JSON PATH, INCLUDE_NULL_VALUES
							-- ) AS SummaryBoxes
						FOR JSON PATH, INCLUDE_NULL_VALUES
								
                        )

				SET @error		= 0
				SET @message	= 'Datos obtenidos correctamente.' 

            END    

		----------------------------------------------------------------------------------------------------
		---------------------------generate.PackingListSumMos---------------------------------------
		----------------------------------------------------------------------------------------------------
		
		ELSE
		----------------------------------------------------------------------------------------------------
		---------------------------generate.PakingListTarimasShipped----------------------------------------
		----------------------------------------------------------------------------------------------------
			IF @process = 'generate.PakingListTarimasShipped'
			BEGIN
				PRINT 'PROCESO generate.PakingListTarimasShipped'
				PRINT FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss')

				DECLARE @listWaybillsShippedTarima		AS NVARCHAR(MAX)
				SET @listWaybillsShippedTarima			= (SELECT JSON_QUERY(@data, '$.selectedOptions'))

				DROP TABLE IF EXISTS #TB_PACKING_LIST_TARIMA
				SELECT 
				     [rowN]			= STJ.[R]
					,[Waybill]		= STJ.[Waybill] 
				INTO #TB_PACKING_LIST_TARIMA
				FROM OPENJSON(@listWaybillsShippedTarima)
				WITH (	 
						[R]			INT
						,[Waybill]		VARCHAR(200)
					) AS STJ
				
				DROP TABLE IF EXISTS #TB_DataTarimaPacking
				SELECT	
						[R]							= ROW_NUMBER() OVER(ORDER BY 
																				sh.[Waybill]
																				,IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[DropDownValue],'000'),3) ) 
																							,pb.[BoxNumber] 
																						)
																			)
						,[WayBill]						= sh.[WayBill]
						,[BoxNumber]					= pb.[BoxNumber]
						,[BoxAmazon]                    = pb.BoxComments4
						,[FormattedBoxNumber]			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT('PPPA'+Ltrim(Str(pp.PackedPalletID+1000000)),'-',RIGHT(btg.DropDownValue,3)) 
																	,pb.[BoxNumber] 
																)
						-- ,[FormattedBoxNumber]			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[DropDownValue],'000'),3) ) 
						-- 											,pb.[BoxNumber] 
						-- 										)
						,[APS]							= od.[Comments6]
						,[PONumber]						= od.[ponumber]
						,[Order]						= od.[OrderNumber]
						,[StyleNumber]					= sti.[stylenumber]
						,[StyleColor]					= stc.[stylecolorname]
						,[GarmentSize]					= fg.[garmentsize]
						,[Units]						= pbi.[quantity]
						,[GrossWeightKGSData]			=  
															IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL
																	,pb.[weight] +   (ppt.[PalletWeight] / (SUM(
																												( SELECT SUM(pbi.[quantity]) FROM LCA.dbo.packeditems as pbi WITH(NOLOCK) WHERE pbi.[packedboxid] = [pb].[packedboxid] )
																												) 
																												OVER (PARTITION BY 
																														IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[Dropdownvalue] ,'000'),3) ) 
																																,pb.[BoxNumber] 
																															)
																														)) ) 
																											* ( SELECT SUM(pbi.[quantity]) FROM LCA.dbo.packeditems as pbi WITH(NOLOCK) WHERE pbi.[packedboxid] = [pb].[packedboxid] )
																	,(pb.[weight] / ( SELECT SUM(pbi.[quantity]) FROM LCA.dbo.packeditems as pbi WITH(NOLOCK) WHERE pbi.[packedboxid] = [pb].[packedboxid] )) * pbi.[quantity]
															) 
						,[Label]						= pb.[BoxLabel]
						,[VolumeBox]					= CONCAT(	CAST(bxtp.BoxLength AS VARCHAR),'*',CAST(bxtp.[BoxWidth] AS VARCHAR),'*',CAST(bxtp.[BoxHeight] AS VARCHAR))
						,[BoxType]						= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL
																,ppt.[PalletTypeName]
																,bxtp.[BoxTypeName]
															)
						,[BoxStatus]					= snpb.[StatusName]
						,[Bin]						  	= gb.[Bin]
	 					-- ,[GoodsBinID]				  	= gb.[GoodsBinID]
				INTO #TB_DataTarimaPacking
				FROM   		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID = 75) AS FSN 
				INNER JOIN	LCA.dbo.statusnames						AS snpb	WITH(NOLOCK)	ON snpb.StatusID			= FSN.StatusID			AND snpb.StatusID = 75
				INNER JOIN	LCA.dbo.packedboxes						AS pb	WITH(NOLOCK)	ON pb.statusid				= snpb.statusid			AND pb.orderid IS NOT NULL
				INNER JOIN	LCA.dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid			AND sh.ShipDate > DATEADD(month,-2,convert(date,getdate()))
				INNER JOIN	#TB_PACKING_LIST_TARIMA					AS TB					ON TB.Waybill				= sh.WayBill
				INNER JOIN	LCA.dbo.packeditems						AS pbi	WITH(NOLOCK)	ON pbi.packedboxid			= pb.packedboxid		AND pbi.quantity > 0  
				INNER JOIN	LCA.dbo.finishedgoods					AS fg	WITH(NOLOCK)	ON pbi.finishedgoodsid		= fg.finishedgoodsid 
				INNER JOIN	LCA.dbo.styles							AS sti	WITH(NOLOCK)	ON fg.styleid				= sti.styleid 
				LEFT JOIN	LCA.dbo.GoodsBins						AS gb	WITH(NOLOCK)	ON gb.GoodsBinID			= pb.GoodsBinID
				LEFT JOIN	LCA.dbo.ManufactureOrders				AS MO	WITH(NOLOCK)	ON MO.ManufactureID			= pbi.ManufactureID	
				LEFT JOIN	LCA.dbo.htsstylecodes					AS hts	WITH(NOLOCK)	ON sti.htsstylecodeid		= hts.htsstylecodeid 
				LEFT JOIN	LCA.dbo.stylecolors						AS stc	WITH(NOLOCK)	ON fg.stylecolorid			= stc.stylecolorid 	
				LEFT JOIN	LCA.dbo.orderdetails					AS odd	WITH(NOLOCK)	ON pbi.orderdetailsid		= odd.orderdetailsid 
				LEFT JOIN	LCA.dbo.orderitems						AS oi	WITH(NOLOCK)	ON odd.orderitemid			= oi.orderitemid 
				LEFT JOIN	LCA.dbo.invoicebatches					AS inb	WITH(NOLOCK)	ON sh.invoicebatchid		= inb.invoicebatchid 
				LEFT JOIN	LCA.dbo.orders							AS od	WITH(NOLOCK)	ON pb.orderid				= od.orderid 
				LEFT JOIN	LCA.dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid 
				LEFT JOIN	LCA.dbo.Warehouses						AS wh	WITH(NOLOCK)	ON wh.WarehouseID			= pb.WarehouseID
				LEFT JOIN	LCA.dbo.Styles							AS st	WITH(NOLOCK)	ON st.StyleID				= sti.BlankStyleID
				LEFT JOIN	LCA.dbo.ShippingContainers				AS sc	WITH(NOLOCK)	ON sc.ShippingContainerID	= sh.ShippingContainerID
				LEFT JOIN	LCA.dbo.DropDownValues3					AS btg	WITH(NOLOCK)	ON btg.DropDownValueID		= pb.BoxTagID			AND btg.DropDownID = 19
				LEFT JOIN   LCA.dbo.PalletTypes						AS ppt  WITH(NOLOCK)	ON pp.PalletTypeID			= ppt.PalletTypeID  
				LEFT JOIN	LCA.dbo.boxtypes						AS bxtp WITH(NOLOCK)	ON pb.boxtypeid				= bxtp.boxtypeid

				
				-- SELECT * FROM #TB_DataTarimaPacking
				DROP TABLE IF EXISTS #TB_DataTarimaPackingSUM
				SELECT * INTO #TB_DataTarimaPackingSUM FROM(
					SELECT 
							[Bin]
							,[FormattedBoxNumber]
							,[BoxAmazon]
							,[BoxStatus]
							,[BoxType]
							,[PONumber]
							,[StyleNumber]
							,[StyleColor]
							,[GrossWeightKGSData] = SUM([GrossWeightKGSData])
							,[GarmentSize]
							,[Units]		= SUM([Units])
					FROM #TB_DataTarimaPacking
					GROUP BY
						[Bin]
						,[FormattedBoxNumber]
						,[BoxAmazon]
						,[BoxStatus]
						,[BoxType]
						,[PONumber]
						,[StyleNumber]
						,[StyleColor]
						,[GarmentSize]
				) AS TB
				
				
				DECLARE @OrderedSizes TABLE (
                	GarmentSize VARCHAR(10),
                	OrderIndex INT
                )
                
                INSERT INTO @OrderedSizes (GarmentSize, OrderIndex)
                VALUES 
                 ('XS'          , 110 )
                ,('S'           , 111 )
                ,('M'           , 112 )
                ,('L'           , 113 )
                ,('XL'          , 114 )
                ,('2XL'         , 115 )
                ,('3XL'         , 116 )
                ,('4XL'         , 117 )
                ,('5XL'         , 118 )
                ,('6XL'         , 119 )
                ,('7XL'         , 120 )
                ,('8XL'         , 121 )
                ,('S/M'         , 122 )
                ,('L/XL'        , 123 )
                ,('2T'          , 210 )
                ,('3T'          , 211 )
                ,('4T'          , 212 )
                ,('5T'          , 213 )
                ,('7T'          , 214 )
                ,('8T'          , 215 )
                ,('9T'          , 216 )
                ,('ADJ'         , 310 )
                ,('QTY'         , 410 )
                ,('ONE'         , 510 )
                ,('ONE SIZE'    , 511 )
                
				-- SELECT * FROM #TB_DataTarimaPackingSUM
				DECLARE @cols AS NVARCHAR(MAX)
				DECLARE @totalCols AS NVARCHAR(MAX)
				DECLARE @totalCols3 AS NVARCHAR(MAX)
				DECLARE @sql  AS NVARCHAR(MAX)

				-- Paso 1: Tallas dinámicas
				SELECT @cols = STRING_AGG(QUOTENAME(d.[GarmentSize]), ',')
									WITHIN GROUP (ORDER BY s.OrderIndex)
				FROM (SELECT DISTINCT [GarmentSize] FROM #TB_DataTarimaPackingSUM) AS d
				LEFT JOIN @OrderedSizes s ON s.GarmentSize = d.GarmentSize
				
				-- Paso 2: Suma total de unidades por fila
				SELECT @totalCols = STRING_AGG('ISNULL(' + QUOTENAME(d.[GarmentSize]) + ', 0)', ' + ')
									WITHIN GROUP (ORDER BY s.OrderIndex)
				FROM (SELECT DISTINCT [GarmentSize] FROM #TB_DataTarimaPackingSUM) AS d
				LEFT JOIN @OrderedSizes s ON s.GarmentSize = d.GarmentSize
				
				SELECT @totalCols3 = STRING_AGG(QUOTENAME(d.[GarmentSize]) + ' = ISNULL(' + QUOTENAME(d.[GarmentSize]) + ', 0)', ' , ')
				                 WITHIN GROUP (ORDER BY s.OrderIndex)
				FROM (SELECT DISTINCT [GarmentSize] FROM #TB_DataTarimaPackingSUM) AS d
                LEFT JOIN @OrderedSizes s ON s.GarmentSize = d.GarmentSize
                
				DECLARE @GlobalTableName NVARCHAR(128) = '##TB_Result_' + CAST(@@SPID AS NVARCHAR(10))
				
				-- SELECT DISTINCT [GarmentSize] FROM #TB_DataTarimaPackingSUM
				-- SELECT @totalCols3 AS totalCols3
				
				-- Crear la tabla global dinámica con tu pivot (igual que antes)
				SET @sql = '
				DROP TABLE IF EXISTS ' + @GlobalTableName + ' 

				SELECT * INTO ' + @GlobalTableName + ' FROM (
					SELECT 
						[Bin] = COALESCE([Bin],''NO ASIGNADO'')
						,[FormattedBoxNumber]
						,[BoxAmazon]          = (SELECT TOP 1 [BoxAmazon] FROM #TB_DataTarimaPackingSUM WHERE [FormattedBoxNumber] = p.[FormattedBoxNumber]) 
						,[BoxStatus]
						,[BoxType]            = (SELECT TOP 1 [BoxType] FROM #TB_DataTarimaPackingSUM WHERE [FormattedBoxNumber] = p.[FormattedBoxNumber])
						,[PONumber]           = (SELECT TOP 1 [PONumber] FROM #TB_DataTarimaPackingSUM WHERE [FormattedBoxNumber] = p.[FormattedBoxNumber])
						,[StyleNumber]        = (SELECT TOP 1 [StyleNumber] FROM #TB_DataTarimaPackingSUM WHERE [FormattedBoxNumber] = p.[FormattedBoxNumber])
						,[StyleColor]         = (SELECT TOP 1 [StyleColor] FROM #TB_DataTarimaPackingSUM WHERE [FormattedBoxNumber] = p.[FormattedBoxNumber])
						,[GrossWeightKGSData] = (SELECT ROUND(SUM([GrossWeightKGSData]),2) FROM #TB_DataTarimaPackingSUM WHERE [FormattedBoxNumber] = p.[FormattedBoxNumber])
						,
						' + @cols + ',
						[TotalUnits] = ' + @totalCols + '
					FROM
					(
						SELECT 
							[Bin]
							,[FormattedBoxNumber]
							,[BoxStatus]
							,[GarmentSize]
							,[Units]
						FROM #TB_DataTarimaPackingSUM
					) AS src
					PIVOT
					(
						SUM([Units]) 
						FOR [GarmentSize] IN (' + @cols + ')
					) AS p
				) AS tb
				';

				EXEC sp_executesql @sql;

				-- Ahora capturar JSON en la variable @result desde la tabla global con SQL dinámico
				-- SET @sql = '
				-- SELECT @jsonResult = (
				-- 	SELECT * FROM ' + @GlobalTableName + ' FOR JSON PATH, INCLUDE_NULL_VALUES
				-- );
				-- ';

				SET @sql = '
					SELECT @jsonResult = (
						SELECT
							 [R]	= ROW_NUMBER() OVER(ORDER BY [Bin])
							,[Bin]
							,[TotalUnitsByBin] = (
													SELECT SUM([TotalUnits])
													FROM ' + @GlobalTableName + ' AS sumT
													WHERE sumT.[Bin] = outerT.[Bin]
												)
							,(
								SELECT
									 [R]            = ROW_NUMBER() OVER(PARTITION BY innerT.[Bin] ORDER BY innerT.[FormattedBoxNumber])
									,[Bin]			= innerT.[Bin]
									,[BoxNumber]	= innerT.[FormattedBoxNumber]
									,[BoxAmazon]    = innerT.[BoxAmazon]
									,[BoxStatus]	= innerT.[BoxStatus]
									,[BoxType]      = innerT.[BoxType]
									,[PONumber]		= innerT.[PONumber]
									,[Style]		= innerT.[StyleNumber]
									,[Color]		= innerT.[StyleColor]
									,[Weight]		= innerT.[GrossWeightKGSData]
									,' + @totalCols3 + '
									,[TotalUnits]	= innerT.[TotalUnits]
								FROM ' + @GlobalTableName + ' AS innerT
								WHERE innerT.[Bin] = outerT.[Bin]
								ORDER BY innerT.[FormattedBoxNumber]
								FOR JSON PATH, INCLUDE_NULL_VALUES
							) AS Items
						FROM ' + @GlobalTableName + ' AS outerT
						GROUP BY [Bin]
						FOR JSON PATH, INCLUDE_NULL_VALUES
					);
					';


				EXEC sp_executesql @sql, N'@jsonResult NVARCHAR(MAX) OUTPUT', @jsonResult = @result OUTPUT;

				-- Ya tienes el JSON en @result
				PRINT LEFT(@result, 4000);  -- muestra un fragmento

				-- Limpiar la tabla global
				SET @sql = 'DROP TABLE IF EXISTS ' + @GlobalTableName;
				EXEC sp_executesql @sql;






				SET @error		= 0
				SET @message	= 'Datos obtenidos correctamente.' 

            END    

		----------------------------------------------------------------------------------------------------
		---------------------------generate.PakingListTarimasShipped----------------------------------------
		----------------------------------------------------------------------------------------------------
		
		-- ELSE
		-- ----------------------------------------------------------------------------------------------------
		-- ---------------------------generate.PackingListBoxComments3-----------------------------------------
		-- ----------------------------------------------------------------------------------------------------
		-- 	IF @process = 'generate.PackingListBoxComments3'
		-- 	BEGIN
		-- 		PRINT 'PROCESO generate.PackingListBoxComments3--'
		-- 		PRINT FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss')

		-- 		DECLARE @listWaybillsBXComments		AS NVARCHAR(MAX)
		-- 		SET @listWaybillsBXComments			= (SELECT JSON_QUERY(@data, '$.selectedOptions'))

		-- 		DROP TABLE IF EXISTS #TB_PACKING_LIST_BEFORE_SHIPMENT
		-- 		SELECT 
		-- 		     [rowN]			= STJ.[R]
		-- 			,[Waybill]		= STJ.[Waybill] 
		-- 		INTO #TB_PACKING_LIST_BEFORE_SHIPMENT
		-- 		FROM OPENJSON(@listWaybillsBXComments)
		-- 		WITH (	 
		-- 				[R]			INT
		-- 				,[Waybill]		VARCHAR(200)
		-- 			) AS STJ
				
		-- 		DROP TABLE IF EXISTS #TB_DataPackingBXComments
		-- 		SELECT	
		-- 				[R]							= ROW_NUMBER() OVER(ORDER BY 
		-- 																		sh.[Waybill]
		-- 																		,IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[DropDownValue],'000'),3) ) 
		-- 																					,pb.[BoxNumber] 
		-- 																				)
		-- 																	)
		-- 				,[WayBill]						= sh.[WayBill]
		-- 				,[BoxNumber]					= pb.[BoxNumber]
		-- 				,[FormattedBoxNumber]			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[DropDownValue],'000'),3) ) 
		-- 															,pb.[BoxNumber] 
		-- 														)
		-- 				,[APS]							= od.[Comments6]
		-- 				,[PONumber]						= od.[ponumber]
		-- 				,[Order]						= od.[OrderNumber]
		-- 				,[StyleNumber]					= sti.[stylenumber]
		-- 				,[StyleColor]					= stc.[stylecolorname]
		-- 				,[GarmentSize]					= fg.[garmentsize]
		-- 				,[Units]						= pbi.[quantity]
		-- 				,[GrossWeightKGSData]			=  IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL
		-- 															,pb.[weight] +   (ppt.[PalletWeight] / (SUM(
		-- 																										( SELECT SUM(pbi.[quantity]) FROM LCA.dbo.packeditems as pbi WITH(NOLOCK) WHERE pbi.[packedboxid] = [pb].[packedboxid] )
		-- 																										) 
		-- 																										OVER (PARTITION BY 
		-- 																												IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[Dropdownvalue] ,'000'),3) ) 
		-- 																														,pb.[BoxNumber] 
		-- 																													)
		-- 																												)) ) 
		-- 																									* ( SELECT SUM(pbi.[quantity]) FROM LCA.dbo.packeditems as pbi WITH(NOLOCK) WHERE pbi.[packedboxid] = [pb].[packedboxid] )
		-- 															,pb.[weight]
		-- 													) 
		-- 				,[Label]						= pb.[BoxLabel]
		-- 				,[VolumeBox]					= CONCAT(	CAST(bxtp.BoxLength AS VARCHAR),'*',CAST(bxtp.[BoxWidth] AS VARCHAR),'*',CAST(bxtp.[BoxHeight] AS VARCHAR))
		-- 				,[BoxType]						= bxtp.[BoxTypeName]     
		-- 				,[BoxStatus]					= snpb.[StatusName]
		-- 				,[Bin]						  	= gb.[Bin]
		-- 				,[BoxComments3]					= pb.[BoxComments3]
	 	-- 				-- ,[GoodsBinID]				  	= gb.[GoodsBinID]
		-- 		INTO #TB_DataPackingBXComments
		-- 		FROM   		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID = 75) AS FSN 
		-- 		INNER JOIN	LCA.dbo.statusnames						AS snpb	WITH(NOLOCK)	ON snpb.StatusID			= FSN.StatusID			AND snpb.StatusID = 75
		-- 		INNER JOIN	LCA.dbo.packedboxes						AS pb	WITH(NOLOCK)	ON pb.statusid				= snpb.statusid			AND pb.orderid IS NOT NULL
		-- 		INNER JOIN	LCA.dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid			AND sh.ShipDate > DATEADD(month,-2,convert(date,getdate()))
		-- 		INNER JOIN	#TB_PACKING_LIST_BEFORE_SHIPMENT		AS TB					ON TB.Waybill				= sh.WayBill
		-- 		INNER JOIN	LCA.dbo.packeditems						AS pbi	WITH(NOLOCK)	ON pbi.packedboxid			= pb.packedboxid		AND pbi.quantity > 0  
		-- 		INNER JOIN	LCA.dbo.finishedgoods					AS fg	WITH(NOLOCK)	ON pbi.finishedgoodsid		= fg.finishedgoodsid 
		-- 		INNER JOIN	LCA.dbo.styles							AS sti	WITH(NOLOCK)	ON fg.styleid				= sti.styleid 
		-- 		LEFT JOIN	LCA.dbo.GoodsBins						AS gb	WITH(NOLOCK)	ON gb.GoodsBinID			= pb.GoodsBinID
		-- 		LEFT JOIN	LCA.dbo.ManufactureOrders				AS MO	WITH(NOLOCK)	ON MO.ManufactureID			= pbi.ManufactureID	
		-- 		LEFT JOIN	LCA.dbo.htsstylecodes					AS hts	WITH(NOLOCK)	ON sti.htsstylecodeid		= hts.htsstylecodeid 
		-- 		LEFT JOIN	LCA.dbo.stylecolors						AS stc	WITH(NOLOCK)	ON fg.stylecolorid			= stc.stylecolorid 	
		-- 		LEFT JOIN	LCA.dbo.orderdetails					AS odd	WITH(NOLOCK)	ON pbi.orderdetailsid		= odd.orderdetailsid 
		-- 		LEFT JOIN	LCA.dbo.orderitems						AS oi	WITH(NOLOCK)	ON odd.orderitemid			= oi.orderitemid 
		-- 		LEFT JOIN	LCA.dbo.invoicebatches					AS inb	WITH(NOLOCK)	ON sh.invoicebatchid		= inb.invoicebatchid 
		-- 		LEFT JOIN	LCA.dbo.orders							AS od	WITH(NOLOCK)	ON pb.orderid				= od.orderid 
		-- 		LEFT JOIN	LCA.dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid 
		-- 		LEFT JOIN	LCA.dbo.Warehouses						AS wh	WITH(NOLOCK)	ON wh.WarehouseID			= pb.WarehouseID
		-- 		LEFT JOIN	LCA.dbo.Styles							AS st	WITH(NOLOCK)	ON st.StyleID				= sti.BlankStyleID
		-- 		LEFT JOIN	LCA.dbo.ShippingContainers				AS sc	WITH(NOLOCK)	ON sc.ShippingContainerID	= sh.ShippingContainerID
		-- 		LEFT JOIN	LCA.dbo.DropDownValues3					AS btg	WITH(NOLOCK)	ON btg.DropDownValueID		= pb.BoxTagID
		-- 		LEFT JOIN   LCA.dbo.PalletTypes						AS ppt  WITH(NOLOCK)	ON pp.PalletTypeID			= ppt.PalletTypeID  
		-- 		LEFT JOIN	LCA.dbo.boxtypes						AS bxtp WITH(NOLOCK)	ON pb.boxtypeid				= bxtp.boxtypeid

				
		-- 		DROP TABLE IF EXISTS #TB_SummaryPacking
		-- 		SELECT
		-- 			 [WayBill]		= COALESCE(S.[WayBill],'Total')
		-- 			,[Bins]			= COUNT(DISTINCT S.[Bin])
		-- 			,[Boxes]		= COUNT(DISTINCT S.[FormattedBoxNumber])
		-- 			,[Units]		= SUM(S.[Units])
		-- 		INTO #TB_SummaryPacking
		-- 		FROM #TB_DataPacking	AS S
		-- 		GROUP BY ROLLUP(S.[WayBill])

				

		-- 		SET @result =
        --                 (
		-- 				 SELECT
		-- 					(
		-- 						SELECT * 
		-- 						FROM #TB_SummaryPacking
		-- 						FOR JSON PATH, INCLUDE_NULL_VALUES
		-- 					) AS SummaryPacking,
		-- 					(
		-- 						SELECT * 
		-- 						FROM #TB_DataPacking
		-- 						ORDER BY [R]
		-- 						FOR JSON PATH, INCLUDE_NULL_VALUES
		-- 					) AS DataPacking
		-- 				FOR JSON PATH, INCLUDE_NULL_VALUES
								
        --                 )

		-- 		SET @error		= 0
		-- 		SET @message	= 'Datos obtenidos correctamente.' 

        --     END    

		-- ----------------------------------------------------------------------------------------------------
		-- ---------------------------generate.PackingListBoxComments3-----------------------------------------
		-- ----------------------------------------------------------------------------------------------------
				ELSE
		-- ----------------------------------------------------------------------------------------------------
		-- ---------------------------PackingListTarimas.list------------------------------------------------
		-- ----------------------------------------------------------------------------------------------------
		IF @process = 'PackingListTarimas.list'
		BEGIN
				PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' PackingListTarimas.list')
				
				DECLARE @listWaybillsShippedTarima10		AS NVARCHAR(MAX)
				SET @listWaybillsShippedTarima10			= (SELECT JSON_QUERY(@data, '$.selectedOptions'))

				DROP TABLE IF EXISTS #TB_PACKING_LIST_TARIMA10
				SELECT 
				     [rowN]			= STJ.[R]
					,[Waybill]		= STJ.[Waybill] 
				INTO #TB_PACKING_LIST_TARIMA10
				FROM OPENJSON(@listWaybillsShippedTarima10)
				WITH (	 
						[R]			INT
						,[Waybill]		VARCHAR(200)
					) AS STJ
				
				DROP TABLE IF EXISTS #TB_DataTarimaPacking10
				SELECT	
						[R]							= ROW_NUMBER() OVER(ORDER BY gb.[Bin]) 
						,[Bin]						  	= gb.[Bin]
	 					-- ,[GoodsBinID]				  	= gb.[GoodsBinID]
				INTO #TB_DataTarimaPacking10
				FROM   		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID = 75) AS FSN 
				INNER JOIN	LCA.dbo.statusnames						AS snpb	WITH(NOLOCK)	ON snpb.StatusID			= FSN.StatusID			AND snpb.StatusID = 75
				INNER JOIN	LCA.dbo.packedboxes						AS pb	WITH(NOLOCK)	ON pb.statusid				= snpb.statusid			AND pb.orderid IS NOT NULL
				INNER JOIN	LCA.dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid			--AND sh.ShipDate > DATEADD(MONTH,-2,CONVERT(DATE,GETDATE()))
				INNER JOIN	#TB_PACKING_LIST_TARIMA10				AS TB					ON TB.Waybill				= sh.WayBill
				LEFT JOIN	LCA.dbo.GoodsBins						AS gb	WITH(NOLOCK)	ON gb.GoodsBinID			= pb.GoodsBinID
				GROUP BY 
					gb.[Bin]
				
		 		SET @result =
                         (
		 					SELECT * FROM #TB_DataTarimaPacking10
		 					FOR JSON PATH, INCLUDE_NULL_VALUES
                         )

		 		SET @error		= 0
		 		SET @message	= 'Datos obtenidos correctamente.'
		END
		-- ----------------------------------------------------------------------------------------------------
		-- ---------------------------PackingListTarimas.list------------------------------------------------
		-- ----------------------------------------------------------------------------------------------------
		ELSE
		-- ----------------------------------------------------------------------------------------------------
		-- ---------------------------amazon.update------------------------------------------------
		-- ----------------------------------------------------------------------------------------------------
		IF @process = 'amazon.update'
		BEGIN
				PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),' amazon.update')
				
				DECLARE @listDataAmazonUpdate		AS NVARCHAR(MAX)
				SET @listDataAmazonUpdate			= (SELECT JSON_QUERY(@data, '$.selectedOrders'))

				DROP TABLE IF EXISTS #TB_DATA_JSON_AMAZON_UPDATE
				SELECT 
				     [R]              = ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
				    ,[amazon]	      = STJ.[amazon]
					,[customer]		  = STJ.[customer] 
				INTO #TB_DATA_JSON_AMAZON_UPDATE
				FROM OPENJSON(@listDataAmazonUpdate)
				WITH (	 
						[amazon]		VARCHAR(200)
						,[customer]		VARCHAR(200)
					) AS STJ
				
				-- SELECT * FROM #TB_DATA_JSON_AMAZON_UPDATE
				
				
				DROP TABLE IF EXISTS #GROUP_CustomerOrder
				SELECT DISTINCT [Customer] 
				INTO #GROUP_CustomerOrder 
				FROM #TB_DATA_JSON_AMAZON_UPDATE
				
				DROP TABLE IF EXISTS #TB_DATA_PPM_BOX_FOR_AMAZON_UPDATE
				SELECT	
						
						 [CustomerOrder]                = SUBSTRING(od.[Comments6], 1, 9)
						,[Bin]                          = gb.Bin
						,[PackedBoxID]					= pb.[PackedBoxID]
						,[BoxNumber]					= pb.[BoxNumber]
						,[FormattedBoxNumber]			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[DropDownValue],'000'),3) ) 
																	,pb.[BoxNumber] 
																)  
						,[BoxStatus]					= snpb.[StatusName]
						,[BoxStatusID]                  = snpb.[StatusID]
						,[amazon]                = CAST(NULL AS VARCHAR(MAX)) 
	 					-- ,[GoodsBinID]				  	= gb.[GoodsBinID]
				INTO #TB_DATA_PPM_BOX_FOR_AMAZON_UPDATE
				-- FROM   		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID = 75) AS FSN 
				FROM   		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID = 27) AS FSN 
				INNER JOIN	LCA.dbo.statusnames						AS snpb	WITH(NOLOCK)	ON snpb.StatusID			= FSN.StatusID			
				INNER JOIN	LCA.dbo.packedboxes						AS pb	WITH(NOLOCK)	ON pb.statusid				= snpb.statusid			AND pb.orderid IS NOT NULL
				INNER JOIN  LCA.dbo.Orders                          AS od   WITH(NOLOCK)    ON pb.OrderID               = od.OrderID
				INNER JOIN  #GROUP_CustomerOrder                    AS DAT  WITH(NOLOCK)    ON SUBSTRING(od.[Comments6], 1, 9)  = DAT.customer
				LEFT JOIN	LCA.dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid 
				LEFT JOIN	LCA.dbo.DropDownValues3					AS btg	WITH(NOLOCK)	ON btg.DropDownValueID		= pb.BoxTagID
				LEFT JOIN   LCA.dbo.GoodsBins                       AS gb   WITH(NOLOCK)    ON gb.GoodsBinID            = pb.GoodsBinID
				
				-- LEFT JOIN	LCA.dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid			--AND sh.ShipDate > DATEADD(MONTH,-2,CONVERT(DATE,GETDATE()))
				
				WHERE pb.BoxComments4 IS  NULL OR pb.BoxComments4 = ''
				-- AND SH.Waybill = 'AIR-APP-20250905'
				
				-- select * from #TB_DATA_PPM_BOX_FOR_AMAZON_UPDATE
				
				-- SELECT	
						
				-- 		 [CustomerOrder]                = SUBSTRING(od.[Comments6], 1, 9)
				-- 		,[Bin]                          = gb.Bin
				-- 		,[PackedBoxID]					= pb.[PackedBoxID]
				-- 		,[BoxNumber]					= pb.[BoxNumber]
				-- 		,[FormattedBoxNumber]			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[DropDownValue],'000'),3) ) 
				-- 													,pb.[BoxNumber] 
				-- 												)  
				-- 		,[BoxStatus]					= snpb.[StatusName]
				-- 		,[BoxStatusID]                  = snpb.[StatusID]
				-- 		,[amazon]                = CAST(NULL AS VARCHAR(MAX)) 
	 			-- 		-- ,[GoodsBinID]				  	= gb.[GoodsBinID]
				-- -- INTO #TB_DATA_PPM_BOX_FOR_AMAZON_UPDATE
				-- -- FROM   		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID = 75) AS FSN 
				-- FROM   		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID = 27) AS FSN 
				-- INNER JOIN	LCA.dbo.statusnames						AS snpb	WITH(NOLOCK)	ON snpb.StatusID			= FSN.StatusID			
				-- INNER JOIN	LCA.dbo.packedboxes						AS pb	WITH(NOLOCK)	ON pb.statusid				= snpb.statusid			AND pb.orderid IS NOT NULL
				-- INNER JOIN  LCA.dbo.Orders                          AS od   WITH(NOLOCK)    ON pb.OrderID               = od.OrderID and SUBSTRING(od.[Comments6], 1, 9)  = '225070033'
				-- -- INNER JOIN  #GROUP_CustomerOrder                    AS DAT  WITH(NOLOCK)    ON 
				-- LEFT JOIN	LCA.dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid 
				-- LEFT JOIN	LCA.dbo.DropDownValues3					AS btg	WITH(NOLOCK)	ON btg.DropDownValueID		= pb.BoxTagID
				-- LEFT JOIN   LCA.dbo.GoodsBins                       AS gb   WITH(NOLOCK)    ON gb.GoodsBinID            = pb.GoodsBinID
				-- WHERE pb.BoxComments4 IS NULL
				
				-- DROP TABLE IF EXISTS #TB_GROUP_BOX_AMAZON
				
				DECLARE @TotalBoxInSystem   AS INT = (SELECT COUNT(DISTINCT [FormattedBoxNumber]) FROM #TB_DATA_PPM_BOX_FOR_AMAZON_UPDATE)
				DECLARE @TotalBoxAmazon     AS INT = (SELECT COUNT(DISTINCT [amazon]) FROM #TB_DATA_JSON_AMAZON_UPDATE)
				
				-- SELECT @TotalBoxInSystem, @TotalBoxAmazon
				
				IF (@TotalBoxAmazon <> @TotalBoxInSystem)
				BEGIN
					SET @error		= 1
		 		    SET @message	= CONCAT('No match Number of boxes. PPM:',CAST(@TotalBoxInSystem AS VARCHAR),' Amazon:',CAST(@TotalBoxAmazon AS VARCHAR))
		 		    -- SELECT @message
				END
				
				ELSE
				BEGIN
					DROP TABLE IF EXISTS #TB_GROUP_BOXES_AMAZON
					
					SELECT
						 [R]                     = ROW_NUMBER()OVER(ORDER BY [Bin],[FormattedBoxNumber])
						,[FormattedBoxNumber]    = [FormattedBoxNumber]
						,[amazon]                = CAST(NULL AS VARCHAR(MAX)) 
					INTO #TB_GROUP_BOXES_AMAZON
					FROM(
						SELECT DISTINCT [Bin],[FormattedBoxNumber] FROM #TB_DATA_PPM_BOX_FOR_AMAZON_UPDATE
					) AS TB
					
					UPDATE S SET
						[amazon]    = B.[amazon]
					FROM #TB_GROUP_BOXES_AMAZON AS S
					INNER JOIN #TB_DATA_JSON_AMAZON_UPDATE AS B ON B.[R] = S.[R]
					
					UPDATE S SET
						[amazon]    = B.[amazon]
					FROM #TB_DATA_PPM_BOX_FOR_AMAZON_UPDATE AS S
					INNER JOIN #TB_GROUP_BOXES_AMAZON AS B ON S.[FormattedBoxNumber] = B.[FormattedBoxNumber]
					
					UPDATE S SET
						[BoxComments4]    = B.[amazon]
					FROM LCA.dbo.PackedBoxes AS S
					INNER JOIN #TB_DATA_PPM_BOX_FOR_AMAZON_UPDATE AS B ON S.[PackedBoxID] = B.[PackedBoxID]
					
					
					-- SELECT * FROM #TB_DATA_JSON_AMAZON_UPDATE
					-- SELECT * FROM #TB_GROUP_BOXES_AMAZON
					-- SELECT * FROM #TB_DATA_PPM_BOX_FOR_AMAZON_UPDATE
					-- SELECT 
					-- 	S.[PackedBoxID]
					-- 	,[BoxComments4]    = B.[amazon]
					-- FROM LCA.dbo.PackedBoxes AS S
					-- INNER JOIN #TB_DATA_PPM_BOX_FOR_AMAZON_UPDATE AS B ON S.[PackedBoxID] = B.[PackedBoxID]
					
					
			 		SET @result =
	                         (
			 					SELECT * FROM #TB_DATA_PPM_BOX_FOR_AMAZON_UPDATE
			 					FOR JSON PATH, INCLUDE_NULL_VALUES
	                         )

		 		SET @error		= 0
		 		SET @message	= 'Datos obtenidos correctamente.'
				
				END
				
				
				
		END
		-- ----------------------------------------------------------------------------------------------------
		-- ---------------------------amazon.update------------------------------------------------
		-- ----------------------------------------------------------------------------------------------------

		-- ------------------------------------------------------------------------------------------------------------
		-- ---------------------------ordenes aprovadas con diferencias------------------------------------------------
		-- ------------------------------------------------------------------------------------------------------------

		IF @process = 'approve-wo'
		BEGIN

			DROP TABLE IF EXISTS #TB_ApproveWOResult
			CREATE TABLE #TB_ApproveWOResult ([Result] NVARCHAR(MAX))

			INSERT INTO #TB_ApproveWOResult ([Result])
			EXEC [dbo].[SP_Shipping_ValidateItemDetailID_In_Waybill] @process = @process, @data = @data

			DECLARE @resultApproveWO NVARCHAR(MAX)
			SELECT @resultApproveWO = [Result] FROM #TB_ApproveWOResult

			SET @error   = CAST(JSON_VALUE(@resultApproveWO, '$.Error') AS BIT)
			SET @message = JSON_VALUE(@resultApproveWO, '$.Message')

		END

		-- ------------------------------------------------------------------------------------------------------------
		-- ---------------------------ordenes aprovadas con diferencias------------------------------------------------
		-- ------------------------------------------------------------------------------------------------------------


   END TRY
   BEGIN CATCH
       -- Manejo de errores
       SET @message = 'Error in Database. Please contact IT.'
       SET @error = 1
       SET @result = '[]' 
   END CATCH

	SET @otherData =  (SELECT 
							 [Error]	         = @error
							,[message]	         = @message
							,[messageData]	     = JSON_QUERY(COALESCE(@messageData, '[]'))
							,[Result]	         = JSON_QUERY(@result)
							,[Reasons]			 = JSON_QUERY(@resultReasons)
					   FOR JSON PATH ,INCLUDE_NULL_VALUES --, WITHOUT_ARRAY_WRAPPER
   )
--    @messageData
   -- Devolver JSON unificado
   
	IF @NoSelect =0 
        SELECT @otherData 
		 

END




						
					
