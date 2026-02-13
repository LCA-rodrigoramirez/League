USE [LCA]
GO

/****** Object:  View [dboReaders].[VW_Planning_DispatchRO_StockWarehouse]    Script Date: 13/06/2025 10:51:30 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [dboReaders].[VW_Planning_DispatchRO_StockWarehouse]
AS

--;
	WITH CTE_INV AS (
		SELECT 
			pb.[PackedBoxID]
			,'PPBX'+Ltrim(Str(pb.[PackedBoxID]+10000000))		AS [CSVBoxNumber] 
			,pb.GoodsBinID
			,[PackDate]				=	COALESCE(pb.PackDate,MO.ManufacturedDate)
			,[OriginalPackDate]		= pb.PackDate
			,pb.BoxNumber 
			,pbi.Quantity
			,pbi.FinishedGoodsID
			,'PPFG'+Ltrim(Str(pbi.FinishedGoodsID+1000000)) 	AS [PPFG]
			,pbi.ManufactureID
			,wh.WarehouseID
			,st.StyleID
			,REPLACE(REPLACE(REPLACE(RTRIM(st.StyleNumber),CHAR(9), ''),CHAR(10),''),CHAR(13),'') AS [Style]
			,snsst.seasonName 								    		AS [Season]
			,COALESCE(strg.RegionName,'')						    		AS [StockCategory]
			,REPLACE(REPLACE(REPLACE(RTRIM(STC.StyleColorName),CHAR(9), ''),CHAR(10),''),CHAR(13),'') AS [Color]
			,fg.GarmentSize 						    		AS [Size]
			,MO.ManufacturedDate
			,[MO]				= COALESCE(MO.ManufactureNumber,'')
			,[OPTION]			= MO.Comments17		
			,[TariffCategory]	= MO.Comments16	
			,OD.OrderID									    		AS [OrderID]
			,COALESCE(OD.PONumber,'') 					    		AS [PONumber]
			,[BIN]		= REPLACE(REPLACE(REPLACE(RTRIM(GB.Bin),CHAR(9), ''),CHAR(10),''),CHAR(13),'') 
		FROM			dbo.StatusNames			AS snpb		WITH(NOLOCK)     
			INNER JOIN	dbo.PackedBoxes			AS pb		WITH (NOLOCK)   ON pb.StatusID			= snpb.StatusID			AND (pb.StatusID IN(0, 8, 98, 100))
			INNER JOIN	dbo.PackedItems			AS pbi		WITH(NOLOCK)	ON pb.PackedBoxID		= pbi.PackedBoxID		AND pbi.Quantity <> 0 
			INNER JOIN dbo.Warehouses 			AS wh		WITH (NOLOCK)	ON pb.WarehouseID		= wh.WarehouseID		AND wh.WarehouseID IN (35,53)
			LEFT JOIN dbo.FinishedGoods 		AS fg		WITH (NOLOCK)   ON fg.FinishedGoodsID	= pbi.FinishedGoodsID
			LEFT JOIN dbo.Styles 				AS st		WITH (NOLOCK)   ON st.StyleID			= fg.StyleID
			LEFT JOIN dbo.Seasons 				AS snsst 	WITH (NOLOCK) 	ON snsst.SeasonID		= st.SeasonID
			LEFT JOIN dbo.StyleRegions 			AS strg 	WITH (NOLOCK) 	ON strg.RegionID		= ST.RegionID
			LEFT JOIN dbo.StyleColors  			AS STC		WITH (NOLOCK)	ON fg.StyleColorID		= STC.StyleColorID
			LEFT JOIN dbo.ManufactureOrders		AS MO		WITH (NOLOCK)   ON MO.ManufactureID		= pbi.ManufactureID
			LEFT JOIN dbo.OrderItems			AS OI		WITH (NOLOCK)   ON OI.OrderItemID		= MO.FirstOrderItemID
			LEFT JOIN dbo.Orders 				AS OD       WITH (NOLOCK)   ON OD.OrderID			= OI.OrderID
			LEFT JOIN dbo.GoodsBins 			AS GB		WITH (NOLOCK)	ON pb.GoodsBinID		= GB.GoodsBinID 

	)
	,CTE_VENDOR AS(
		SELECT VND.* FROM [dboReaders].[VW_Planning_DispatchRO_OriginalVendor]				AS VND WITH(NOLOCK)
		INNER JOIN (SELECT DISTINCT ManufactureID FROM CTE_INV) AS INV ON INV.ManufactureID = VND.ManufactureID
	)
	,CTE_TAG AS(
		SELECT VND.* FROM [dboReaders].[VW_Planning_DispatchRO_RawMaterialHangtagYesNo]		AS VND WITH(NOLOCK)
		INNER JOIN (SELECT DISTINCT ManufactureID FROM CTE_INV) AS INV ON INV.ManufactureID = VND.ManufactureID
	)
	,CTE_BOM AS(
		SELECT VND.* FROM [dboReaders].[VW_Planning_DispatchRO_BOMRequireHangtag]			AS VND WITH(NOLOCK)
		INNER JOIN (SELECT DISTINCT StyleID FROM CTE_INV) AS INV ON INV.StyleID = VND.StyleID
	)

	SELECT    
		 [StyleID]				= 	INV.StyleID 								
		,[Style]				= INV.[Style]									
		,[Season]				= INV.[Season]									
		,[Color]				= INV.[Color]									
		,[BoxStat]				= 'RO_Packed'									
		,[BoxNumber]			= INV.BoxNumber 							    	
		,[BIN]					= INV.[BIN]										
		,[PackDate]				= INV.[PackDate]						    		
		,[Size]					= INV.[Size] 						    		
		,[QTY]					= SUM(INV.Quantity) 								
		,[StockCategory]		= INV.[StockCategory]					    	
		,[MO_ID]				= INV.ManufactureID 				    			
		,[MO]					= INV.[MO]    									
		,[OrderID]				= INV.[OrderID]				    				
		,[PONumber]				= INV.[PONumber]				    				
		,[OrigFabricVendorName]	= COALESCE(ov.[OrigFabricVendorName],'')            
		,[RequireHangtag]		= COALESCE(RPN.DAT,1)							
		,[PNHangtag]			= COALESCE(HTG.PartNumber,'NO Hangtag Assigned'	)  
		,[TariffCategory]		= INV.[TariffCategory]							
		,[CSVBoxNumber]  		= INV.[CSVBoxNumber]								
		,[PPFG]					= INV.[PPFG] 									
		,[TypeQuery]			= 1                                                 
		,[OrderWIP]				= 0                                                 
		,[OPTION]				= INV.[OPTION]									
	FROM			CTE_INV			AS INV	WITH(NOLOCK)
		LEFT JOIN	CTE_VENDOR      AS ov   WITH(NOLOCK) ON ov.ManufactureID	= INV.ManufactureID
		LEFT JOIN	CTE_TAG			AS RPN  WITH(NOLOCK) ON RPN.ManufactureID	= INV.ManufactureID
		LEFT JOIN	CTE_BOM			AS HTG  WITH(NOLOCK) ON HTG.StyleID			= INV.StyleID
	GROUP BY 
			INV.StyleID							        
		,INV.[Style]							    	
		,INV.[Season]							    	
		,INV.[Color]									    	
		,INV.BoxNumber 							    	
		,INV.[BIN]		
		,INV.[PackDate]								    	
		,INV.[Size] 	 							    	
		,INV.[StockCategory]					    	
		,INV.ManufactureID 		
		,INV.[MO]    		  	
		,INV.[OrderID]		    	
		,INV.[PONumber]		    	
		,COALESCE(ov.[OrigFabricVendorName],'')               	
		,COALESCE(RPN.DAT,1)								    	
		,COALESCE(HTG.PartNumber,'NO Hangtag Assigned'	)   	
		,INV.[TariffCategory]						
		,INV.[CSVBoxNumber]	
		,INV.[PPFG]
		,INV.[OPTION]

	
GO


