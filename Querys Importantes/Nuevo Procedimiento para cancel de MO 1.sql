USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_Orders_Cancelled_L2Brands]    Script Date: 08/08/2025 06:46:15 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- ALTER PROCEDURE [dbo].[SP_Orders_Cancelled_L2Brands]
-- (
-- 	@process as NVARCHAR(MAX)
-- )
-- AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @result     AS NVARCHAR(MAX)
	DECLARE @message    AS VARCHAR(100)
	DECLARE @error      AS BIT
	DECLARE @process    AS NVARCHAR(MAX) = 'supplier.flex'

	--- Procedimiento para borrar las órdenes de la semana pasada que ya no aparecen en la actual (no está listo)

	BEGIN TRY

	IF @process = 'cancel.report'
	BEGIN

		DROP TABLE IF EXISTS #TB_MO
		-- DROP TABLE IF EXISTS #TB_LogOE
		-- DROP TABLE IF EXISTS #TB_LogOE_LW
		-- DROP TABLE IF EXISTS #TB_ItemMissing
		-- DROP TABLE IF EXISTS #TB_MOMissing

		-- SELECT DISTINCT 
		-- 	OELog.ItemDetailID
		-- INTO #TB_LogOE
		-- FROM [192.168.1.93].AppsLCA.legacycaps.VW_view_qryLCA_Order_Export_Logs AS OELog WITH(NOLOCK)
		-- WHERE OELog.Insert_Time >= DATEADD(week, DATEDIFF(week, 0, GETDATE()) - 1, 0) AND OELog.Insert_Time < DATEADD(week, DATEDIFF(week, 0, GETDATE()), 0)

		-- SELECT DISTINCT 
		-- 	OELog.ItemDetailID
		-- INTO #TB_LogOE_LW
		-- FROM [192.168.1.93].AppsLCA.legacycaps.VW_view_qryLCA_Order_Export_Logs AS OELog WITH(NOLOCK)
		-- WHERE OELog.Insert_Time >= DATEADD(week, DATEDIFF(week, 0, GETDATE()) , 0) AND OELog.Insert_Time < DATEADD(week, DATEDIFF(week, 0, GETDATE()) +1, 0)

		

		-- SELECT 
		-- 	 [ORD] = CONCAT('ORD-',CAST(ItemDetailID AS varchar(100)))
		-- 	,ItemDetailID
		-- into #TB_ItemMissing
		-- FROM #TB_LogOE_LW 
		-- WHERE ItemDetailID NOT IN (SELECT DISTINCT ItemDetailID FROM #TB_LogOE) 

		-- DELETE 
		-- FROM #TB_ItemMissing 
		-- WHERE ORD IN (SELECT DISTINCT 
		-- 				TIM.ORD 
		-- 			  FROM #TB_ItemMissing AS TIM
		-- 			  INNER JOIN AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK) 
		-- 			  ON TIM.ORD = AF.PONumber )


		-- SELECT distinct 
		-- 	 TIM.ItemDetailID
		-- 	,TIM.ORD
		-- 	,OD.OrderID
		-- 	,MO.ManufactureID
		-- 	,MO.ManufactureNumber
		-- 	,MO.StatusID
		-- 	,MO.Comments2
		-- 	,SN.StatusName
		-- 	,CONCAT('ESTA ORDEN FUE CANCELADA POR L2Brands EN LA FEHCA: ', CAST(GETDATE() AS DATE)) AS Comment
		-- INTO #TB_MOMissing
		-- FROM #TB_ItemMissing AS TIM
		-- INNER JOIN	LCA.dbo.Orders				AS OD 	WITH(NOLOCK) ON TIM.ORD = OD.PONumber AND OD.StatusID < 90
		-- LEFT JOIN	LCA.dbo.OrderItems			AS OI 	WITH(NOLOCK) ON OD.OrderID = OI.OrderID
		-- INNER JOIN  LCA.dbo.ManufactureOrders	AS MO 	WITH(NOLOCK) ON OI.OrderItemID = MO.FirstOrderItemID AND MO.StatusID < 90
		-- LEFT JOIN	LCA.dbo.StatusNames			AS SN 	WITH(NOLOCK) ON MO.StatusID = SN.StatusID
		-- ORDER BY TIM.ItemDetailID

		-- SELECT * FROM #TB_MOMissing ---SUJETO A REVISION


		--- Proceso para cancelar las órdenes que en Status/Date de L2Brands tienen Cancel

		SELECT 
			TB.*
			,CAST(NULL AS NVARCHAR(MAX)) AS Comment
		INTO #TB_MO
		FROM
		(	
			SELECT DISTINCT 
				OE.ItemDetailID
				,OD.PONumber
				,OD.OrderID
				,MO.ManufactureID
				,MO.ManufactureNumber
				,MO.StatusID
				,MO.Comments2
				,SN.StatusName
				,OE.[Status/Date]
				,LTRIM(RTRIM(SUBSTRING([Status/Date], CHARINDEX(' ', [Status/Date]), LEN([Status/Date])))) AS Fecha
				,DV.DropDownValue AS ProductionStatus
				,SUM(MB.QuantityWithdrawn) AS Withdraw
				,NULL AS MatWithdraw
			FROM AppsLCA.legacycaps.VW_view_qryLCA_Order_Export AS OE WITH(NOLOCK)
			INNER JOIN	LCA.dbo.Orders				AS OD WITH(NOLOCK) ON CONCAT('ORD-',CAST(OE.ItemDetailID AS VARCHAR(100))) = OD.PONumber AND OE.[Status/Date] like '%Canceled%'
			INNER JOIN  LCA.dbo.ManufactureOrders	AS MO WITH(NOLOCK) ON OD.OrderID = MO.OrderID AND MO.StatusID < 90 --AND MO.StatusID <> 67
			INNER JOIN	LCA.dbo.StatusNames			AS SN WITH(NOLOCK) ON MO.StatusID = SN.StatusID
			LEFT JOIN	LCA.dbo.DropDownValues3		AS DV WITH(NOLOCK) ON MO.ProductionStatusID = DV.DropDownValueID
			INNER JOIN	LCA.dbo.ManufactureBlanks	AS MB WITH(NOLOCK) ON MO.ManufactureID = MB.ManufactureID

			GROUP BY
				OE.ItemDetailID
				,OD.PONumber
				,OD.OrderID
				,MO.ManufactureID
				,MO.ManufactureNumber
				,MO.StatusID
				,MO.Comments2
				,SN.StatusName
				,OE.[Status/Date]
				,LTRIM(RTRIM(SUBSTRING([Status/Date], CHARINDEX(' ', [Status/Date]), LEN([Status/Date]))))
				,DV.DropDownValue
				--,RA.QuantityWithdrawn
		
		) AS TB

		UPDATE TMO SET		
			TMO.MatWithdraw = ISNULL(TMO_Temp.MatWithdraw,0)
		FROM #TB_MO AS TMO
		INNER JOIN 
		(
		 SELECT 
			 TMO_Temp.ManufactureID
			,SUM(RA.QuantityWithdrawn) AS MatWithdraw
		 FROM #TB_MO AS TMO_Temp
		 INNER JOIN LCA.dbo.RawAllocations AS RA WITH(NOLOCK) ON TMO_Temp.ManufactureID = RA.ManufactureID
		 GROUP BY TMO_Temp.ManufactureID
		) AS TMO_Temp ON TMO.ManufactureID = TMO_Temp.ManufactureID

		update TMO
		SET Comment = CASE 
						WHEN TMO.StatusID NOT IN(67,40,20) OR TMO.Withdraw > 0 OR TMO.MatWithdraw > 0 
							THEN CONCAT('ORDEN CANCELADA POR L2Brands EN LA FECHA: ', CONCAT(YEAR(GETDATE()), '/', TMO.Fecha),'. PERO EN PROCESO EN LCA')
						WHEN TMO.StatusID IN(67,40,20) AND TMO.Withdraw = 0 AND TMO.MatWithdraw = 0
							THEN CONCAT('ORDEN CANCELADA POR L2Brands Y LCA EN LA FECHA: ', CONCAT(YEAR(GETDATE()), '/', TMO.Fecha))
					  END
		FROM #TB_MO AS TMO
		INNER JOIN LCA.dbo.ManufactureOrders AS MO WITH(NOLOCK) ON TMO.ManufactureID = MO.ManufactureID

	
		SET @result =
		(
			SELECT 
				TMO.ManufactureID
				,TMO.ManufactureNumber
				,TMO.PONumber
				,TMO.ProductionStatus
				,TMO.StatusName
				--,MO.StatusID
				--,[NewStatusID] 	= 67
				,CASE WHEN TMO.StatusID = 40 OR TMO.StatusID = 20 THEN 'Hold' ELSE TMO.StatusName END AS NewStatus
				,TMO.[Status/Date]
				,TMO.Comment
			FROM #TB_MO as TMO
			INNER JOIN LCA.dbo.ManufactureOrders AS MO WITH(NOLOCK) ON TMO.ManufactureID = MO.ManufactureID
			FOR JSON PATH ,INCLUDE_NULL_VALUES
		
		)
		UPDATE MO SET
			 MO.StatusID = 67
			,MO.Comments2 = CASE WHEN MO.Comments2 IS NOT NULL THEN MO.comments2 + CHAR(13) + CHAR(10) + TMO.Comment ELSE TMO.Comment END
		FROM #TB_MO AS TMO
		INNER JOIN LCA.dbo.ManufactureOrders AS MO with(nolock) ON TMO.ManufactureID = MO.ManufactureID AND TMO.StatusID in (40,20)
					AND TMO.Withdraw = 0 AND TMO.MatWithdraw = 0

		---Actualizar Comments6 de Orders [Staus/Date] Rodrigo Ramirez 2025-08-04
		UPDATE OD SET
			OD.Comments5 = TMO.[Status/Date]
		FROM #TB_MO AS TMO
		INNER JOIN LCA.dbo.Orders AS OD with(nolock) ON TMO.OrderID = OD.OrderID AND TMO.StatusID in (40,20)
					AND TMO.Withdraw = 0 AND TMO.MatWithdraw = 0

		SET @error		= 0
		SET @message	= 'Datos obtenidos correctamente.' 

	

	END --- FIN IF PROCESS 

	--wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww--wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
	IF @process = 'modify.report'
	BEGIN
			--script agregado el 04/08/2025 por JC
			--script para la obtencion de las ordenes modificadas en relacion a PPM - L2Brands

			DROP TABLE IF EXISTS #TB_PREMO
			DROP TABLE IF EXISTS #TB_Logs

			SELECT 
		
					STRING_AGG(MO.ManufactureNumber,',') AS ManufactureNumber
					,MO.Comments7
					,MO.StatusID
					,OD.PONumber
					,isnull(ST2.StyleNumber,ST.StyleNumber) as StyleNumberPPM
					,STC.StyleColorName as StyleColorPPM
					,FG.GarmentSize as GarmentSizePPM
					,SUM(ODT.RequestCount) AS RequestedPPM
					,od.RequiredDate
				INTO #TB_PREMO
	
				FROM LCA.dbo.StatusNames AS SN WITH(NOLOCK)
				INNER JOIN LCA.dbo.ManufactureOrders	AS MO  WITH(NOLOCK) ON SN.StatusID = MO.StatusID AND SN.StatusID < 90--AND SN.StatusID <> 20
				INNER JOIN LCA.dbo.Orders				AS OD  WITH(NOLOCK) ON MO.OrderID = OD.OrderID AND OD.Comments6 IS NOT NULL
				INNER JOIN LCA.dbo.OrderDetails			AS ODT WITH(NOLOCK) ON OD.OrderID = ODT.OrderID AND MO.FirstOrderItemID = ODT.OrderItemID
				INNER JOIN LCA.DBO.FinishedGoods		AS FG  WITH(NOLOCK) ON ODT.FinishedGoodsID = FG.FinishedGoodsID
				INNER JOIN LCA.dbo.Styles				AS ST  WITH(NOLOCK) ON FG.StyleID = ST.StyleID
				INNER JOIN LCA.dbo.StyleColors			AS STC WITH(NOLOCK) ON FG.StyleColorID = STC.StyleColorID
				LEFT JOIN  LCA.dbo.Styles				AS ST2 with(nolock) ON ST.BlankStyleID = ST2.StyleID
	
	   
				GROUP BY
						MO.Comments7
						,MO.StatusID
						,OD.PONumber
						,FG.GarmentSize
						,isnull(ST2.StyleNumber,ST.StyleNumber)
						,STC.StyleColorName
						,od.RequiredDate

	

			CREATE INDEX idx_ponumber_style_color_size
			ON #TB_PREMO (PONumber, StyleNumberPPM, StyleColorPPM, GarmentSizePPM);

			SELECT *
			INTO #TB_Logs
			FROM AppsLCA.legacycaps.VW_view_qryLCA_Order_Export WITH(NOLOCK)
			WHERE CONCAT('ORD-',CAST(ItemDetailID AS varchar(100))) IN (SELECT DISTINCT PONumber FROM #TB_PREMO)

			CREATE INDEX idx_itemDetail_style_color_size
			ON #TB_Logs (ItemDetailID, Style, Color, Size);

			SET @result =
							(
								SELECT 
										TB.Comments7 as Assigment
										,tb.ManufactureNumber

										,isnull(TB.StyleNumberPPM,0) as StylePPM
										,isnull(TB.StyleColorPPM,0) as ColorPPM
										,isnull(TB.GarmentSizePPM,0) as SizePPM
										,isnull(TB.RequestedPPM,0) as QtyPPM
		
										,isnull(OE.Style,0) as StyleORD
										,isnull(OE.Color,0) as ColorORD
										,isnull(OE.Size,0) as SizeORD
										,isnull(OE.Qty,0) as QtyORD

										,case when isnull(OE.Style,0) <> isnull(TB.StyleNumberPPM,0) then 'Style'
											else 
												case when isnull(OE.Color,0) <> isnull(TB.StyleColorPPM,0) then 'Color'
												else
													case when isnull(OE.Size,0) <> isnull(TB.GarmentSizePPM,0) then 'Size'
													else
														case when isnull(OE.Qty,0) <> isnull(TB.RequestedPPM,0) then 'Qty'
														else  ''
														end
													end
												end
											end as Diferencia
		
										,TB.RequestedPPM - OE.Qty AS Diff
										,tb.PONumber
										,tb.RequiredDate
										,OE.[ORD #] as APS
										,OE.ItemDetailID
	
									FROM #TB_PREMO AS TB
									FULL JOIN #TB_Logs AS OE WITH(NOLOCK) ON CONCAT('ORD-',CAST(OE.ItemDetailID AS varchar(100))) = TB.PONumber 
										AND TB.GarmentSizePPM = OE.Size

									where tb.RequiredDate >= '2025-01-01'
									ORDER BY Style
								FOR JSON PATH ,INCLUDE_NULL_VALUES
							)

			SET @error		= 0
			SET @message	= 'Datos obtenidos correctamente.' 

	END --- FIN IF MODIFY

	IF @process = 'supplier.report'
	BEGIN

		DROP TABLE IF EXISTS #TB_Supp

		--- Proceso para cancelar las órdenes que en Status/Date de L2Brands tienen Cancel

		SELECT 
			TB.*
			,CAST(NULL AS NVARCHAR(MAX)) AS Supplier
		INTO #TB_Supp
		FROM
		(	
			SELECT DISTINCT 
				
				 [CustomerOrder] =  CASE WHEN ( od.[PONumber] LIKE 'ORD%') AND CHARINDEX('-',OD.Comments6) > 0 THEN SUBSTRING(od.Comments6,1,CHARINDEX('-',OD.Comments6) -1) ELSE NULL END
				,[ItemDetailID]         = CASE
											WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
												NULL
											WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
												cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT)
											ELSE
												NULL
										  END
				,OD.PONumber
				,SN2.StatusName			 AS ORDStatus
				,MO.ManufactureNumber
				,SUM(MO.QuantityOrdered) AS Make
				,ST.StyleNumber AS Style
				,STC.StyleColorName AS Color
				,SN.StatusName AS MOStatus
				,NULL AS BoxStatus
				,OD.Comments5 AS [Status/Date]
				,DV.DropDownValue AS ProductionStatus
				,OD.Comments4 AS Customer
				-- ,SUM(PKI.Quantity) AS Qty
				-- ,PB.BoxNumber
				-- ,PB.WarehouseID

			FROM LCA.dbo.StatusNames				AS SN  WITH(NOLOCK) 
			INNER JOIN  LCA.dbo.ManufactureOrders	AS MO  WITH(NOLOCK) ON MO.StatusID = SN.StatusID AND SN.StatusID < 90 --AND MO.StatusID <> 67
			INNER JOIN  LCA.dbo.Orders				AS OD  WITH(NOLOCK) ON OD.OrderID = MO.OrderID AND OD.Comments6 IS NOT NULL
			INNER JOIN  LCA.dbo.OrderItems			AS OI  WITH(NOLOCK) ON MO.FirstOrderItemID = OI.OrderItemID
			INNER JOIN  LCA.dbo.Styles				AS ST  WITH(NOLOCK) ON OI.StyleID = st.StyleID
			INNER JOIN  LCA.dbo.StyleColors			AS STC WITH(NOLOCK) ON OI.StyleColorID = STC.StyleColorID
			LEFT JOIN	LCA.dbo.DropDownValues3		AS DV  WITH(NOLOCK) ON MO.ProductionStatusID = DV.DropDownValueID
			LEFT JOIN	LCA.dbo.PackedItems			AS PKI WITH(NOLOCK) ON MO.ManufactureID = PKI.ManufactureID
			LEFT JOIN   LCA.dbo.PackedBoxes			AS PB  WITH(NOLOCK) ON PKI.PackedBoxID = PB.PackedBoxID AND PB.WarehouseID <> 8
			INNER JOIN  LCA.dbo.StatusNames			AS SN2 WITH(NOLOCK) ON OD.StatusID = SN2.StatusID

			GROUP BY

				OD.PONumber
				,SN2.StatusName
				,MO.ManufactureNumber
				,SN.StatusName
				,OD.Comments5
				,DV.DropDownValue
				,OD.Comments6
				,ST.StyleNumber
				,STC.StyleColorName
				,OD.Comments4
				-- ,PB.BoxNumber
				-- ,PB.WarehouseID
				--,RA.QuantityWithdrawn

			UNION ALL

			SELECT DISTINCT 
				 
				 [CustomerOrder] =  CASE WHEN ( od.[PONumber] LIKE 'ORD%') AND CHARINDEX('-',OD.Comments6) > 0 THEN SUBSTRING(od.Comments6,1,CHARINDEX('-',OD.Comments6) -1) ELSE NULL END
				,[ItemDetailID]         = CASE
											WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
												NULL
											WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
												cast(REPLACE ( od.[PONumber],'ORD-','') AS VARCHAR)
											ELSE
												NULL
										  END
				,OD.PONumber
				,SN3.StatusName			 AS ORDStatus
				,MO.ManufactureNumber		
				,SUM(MO.QuantityOrdered) AS Make
				,ST.StyleNumber AS Style
				,STC.StyleColorName AS Color	
				,SN2.StatusName	AS MOStatus
				,SN.StatusName	AS BoxStatus
				,OD.Comments5 AS [Status/Date]
				,DV.DropDownValue AS ProductionStatus
				,OD.Comments4 AS Customer
				-- ,SUM(PKI.Quantity) AS Qty
				-- ,PB.BoxNumber
				-- ,PB.WarehouseID

			FROM LCA.dbo.StatusNames				AS SN  WITH(NOLOCK) 
			INNER JOIN  LCA.dbo.PackedBoxes			AS PB  WITH(NOLOCK) ON PB.StatusID = SN.StatusID AND SN.StatusID IN (27,25) --AND MO.StatusID <> 67
			INNER JOIN	LCA.dbo.PackedItems			AS PKI WITH(NOLOCK) ON PB.PackedBoxID = PKI.PackedBoxID
			INNER JOIN  LCA.dbo.FinishedGoods		AS FG  WITH(NOLOCK) ON PKI.FinishedGoodsID = FG.FinishedGoodsID
			INNER JOIN  LCA.dbo.Styles				AS ST  WITH(NOLOCK) ON FG.StyleID = st.StyleID
			INNER JOIN  LCA.dbo.StyleColors			AS STC WITH(NOLOCK) ON FG.StyleColorID = STC.StyleColorID
			INNER JOIN  LCA.dbo.ManufactureOrders	AS MO  WITH(NOLOCK) ON MO.ManufactureID = PKI.ManufactureID
			INNER JOIN  LCA.dbo.Orders				AS OD  WITH(NOLOCK) ON OD.OrderID = MO.OrderID AND OD.Comments6 IS NOT NULL
			LEFT  JOIN	LCA.dbo.DropDownValues3		AS DV  WITH(NOLOCK) ON MO.ProductionStatusID = DV.DropDownValueID
			INNER JOIN  LCA.dbo.StatusNames			AS SN2 WITH(NOLOCK) ON MO.StatusID = SN2.StatusID
			INNER JOIN  LCA.dbo.StatusNames			AS SN3 WITH(NOLOCK) ON OD.StatusID = SN3.StatusID
			

			GROUP BY

				OD.PONumber
				,SN3.StatusName
				,MO.ManufactureNumber
				,SN2.StatusName
				,SN.StatusName
				,OD.Comments5
				,DV.DropDownValue
				,OD.Comments6
				,ST.StyleNumber
				,STC.StyleColorName
				,OD.Comments4

				-- ,PB.BoxNumber
				-- ,PB.WarehouseID
				--,RA.QuantityWithdrawn
		
		) AS TB

		DROP TABLE IF EXISTS #TB_GROUP_ItemDetailID
        SELECT  DISTINCT ItemDetailID INTO #TB_GROUP_ItemDetailID FROM #TB_Supp

		DROP TABLE IF EXISTS #L2_OrderItemDetail_Remote
		DECLARE @ids_ItemDetail NVARCHAR(MAX)-- 1. Convertimos la lista de IDs en un string

		SELECT @ids_ItemDetail = STRING_AGG(CONVERT(NVARCHAR(MAX), ItemDetailID), ',') FROM #TB_GROUP_ItemDetailID

		-- 2. Ejecutamos la consulta remota con un filtro explícito
		DECLARE @sql NVARCHAR(MAX) = '
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
		EXEC (@sql)
		
		UPDATE TBS SET
		TBS.Supplier = OE.SupplNo

		FROM #TB_Supp AS TBS
		INNER JOIN #L2_OrderItemDetail_Remote AS OE WITH(NOLOCK) ON OE.ItemDetailID = TBS.ItemDetailID
	
		SET @result =
		(
			select 
				CustomerOrder
				,CAST(ItemDetailID AS VARCHAR(50)) AS ItemDetailID
				,PONumber
				,ORDStatus
				,ManufactureNumber
				,MOStatus
				,Style
				,Color
				,Make
				,BoxStatus
				,[Status/Date]
				,ProductionStatus
				,Customer
				,ISNULL(Supplier, 'ELIMINADO EN L2Brand') AS Supplier
			from #TB_Supp WHERE (Supplier is null OR Supplier <> 162)
			AND ItemDetailID IS NOT NULL
			FOR JSON PATH ,INCLUDE_NULL_VALUES
		)

		SET @error		= 0
		SET @message	= 'Datos obtenidos correctamente.' 

	

	END --- FIN IF PROCESS SUPPLIER

	IF @process = 'supplier.flex'
	BEGIN

		DROP TABLE IF EXISTS #TB_Supp_Flex

		--- Proceso para cancelar las órdenes que en Status/Date de L2Brands tienen Cancel

		SELECT 
			TB.*
			,CAST(NULL AS NVARCHAR(MAX)) AS SupplNo
		INTO #TB_Supp_Flex
		FROM
		(	
			SELECT DISTINCT 
				
				 [CustomerOrder] =  CASE WHEN ( od.[PONumber] LIKE 'ORD%') AND CHARINDEX('-',OD.Comments6) > 0 THEN SUBSTRING(od.Comments6,1,CHARINDEX('-',OD.Comments6) -1) ELSE NULL END
				,[ItemDetailID]         = CASE
											WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
												NULL
											WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
												cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT)
											ELSE
												NULL
										  END
				,OD.PONumber
				,SN2.StatusName			 AS ORDStatus
				,[ORDStatusColor]        = CONCAT('#',SUBSTRING(RIGHT('000000' + FORMAT(sn2.[#StatusName], 'X'), 6), 5, 2) +
                                                    SUBSTRING(RIGHT('000000' + FORMAT(sn2.[#StatusName], 'X'), 6), 3, 2) +
                                                    SUBSTRING(RIGHT('000000' + FORMAT(sn2.[#StatusName], 'X'), 6), 1, 2))
				,MO.ManufactureNumber
				,SUM(MO.QuantityOrdered) AS Make
				,ST.StyleNumber AS Style
				,STC.StyleColorName AS Color
				,SN.StatusName AS MOStatus
				,[MOStatusColor]        = CONCAT('#',SUBSTRING(RIGHT('000000' + FORMAT(sn.[#StatusName], 'X'), 6), 5, 2) +
                                                    SUBSTRING(RIGHT('000000' + FORMAT(sn.[#StatusName], 'X'), 6), 3, 2) +
                                                    SUBSTRING(RIGHT('000000' + FORMAT(sn.[#StatusName], 'X'), 6), 1, 2))
				,NULL AS BoxStatus
				,'#FFFFFF' AS BoxStatusColor
				,OD.Comments5 AS [Status/Date]
				,DV.DropDownValue AS ProductionStatus
				,OD.Comments4
				-- ,SUM(PKI.Quantity) AS Qty
				-- ,PB.BoxNumber
				-- ,PB.WarehouseID

			FROM LCA.dbo.StatusNames				AS SN  WITH(NOLOCK) 
			INNER JOIN  LCA.dbo.ManufactureOrders	AS MO  WITH(NOLOCK) ON MO.StatusID = SN.StatusID AND SN.StatusID < 90 --AND MO.StatusID <> 67
			INNER JOIN  LCA.dbo.Orders				AS OD  WITH(NOLOCK) ON OD.OrderID = MO.OrderID AND OD.Comments6 IS NOT NULL
			INNER JOIN  LCA.dbo.OrderItems			AS OI  WITH(NOLOCK) ON MO.FirstOrderItemID = OI.OrderItemID
			INNER JOIN  LCA.dbo.Styles				AS ST  WITH(NOLOCK) ON OI.StyleID = st.StyleID
			INNER JOIN  LCA.dbo.StyleColors			AS STC WITH(NOLOCK) ON OI.StyleColorID = STC.StyleColorID
			LEFT JOIN	LCA.dbo.DropDownValues3		AS DV  WITH(NOLOCK) ON MO.ProductionStatusID = DV.DropDownValueID
			LEFT JOIN	LCA.dbo.PackedItems			AS PKI WITH(NOLOCK) ON MO.ManufactureID = PKI.ManufactureID
			LEFT JOIN   LCA.dbo.PackedBoxes			AS PB  WITH(NOLOCK) ON PKI.PackedBoxID = PB.PackedBoxID AND PB.WarehouseID <> 8
			INNER JOIN  LCA.dbo.StatusNames			AS SN2 WITH(NOLOCK) ON OD.StatusID = SN2.StatusID

			GROUP BY

				OD.PONumber
				,SN2.StatusName
				,sn2.[#StatusName]
				,MO.ManufactureNumber
				,SN.StatusName
				,sn.[#StatusName]
				,OD.Comments5
				,DV.DropDownValue
				,OD.Comments6
				,ST.StyleNumber
				,STC.StyleColorName
				,OD.Comments4
				-- ,PB.BoxNumber
				-- ,PB.WarehouseID
				--,RA.QuantityWithdrawn

			UNION ALL

			SELECT DISTINCT 
				 
				 [CustomerOrder] =  CASE WHEN ( od.[PONumber] LIKE 'ORD%') AND CHARINDEX('-',OD.Comments6) > 0 THEN SUBSTRING(od.Comments6,1,CHARINDEX('-',OD.Comments6) -1) ELSE NULL END
				,[ItemDetailID]         = CASE
											WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
												NULL
											WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
												cast(REPLACE ( od.[PONumber],'ORD-','') AS VARCHAR)
											ELSE
												NULL
										  END
				,OD.PONumber
				,SN3.StatusName			 AS ORDStatus
				,[ORDStatusColor]        = CONCAT('#',SUBSTRING(RIGHT('000000' + FORMAT(sn3.[#StatusName], 'X'), 6), 5, 2) +
                                                    SUBSTRING(RIGHT('000000' + FORMAT(sn3.[#StatusName], 'X'), 6), 3, 2) +
                                                    SUBSTRING(RIGHT('000000' + FORMAT(sn3.[#StatusName], 'X'), 6), 1, 2))
				,MO.ManufactureNumber		
				,SUM(MO.QuantityOrdered) AS Make
				,ST.StyleNumber AS Style
				,STC.StyleColorName AS Color	
				,SN2.StatusName	AS MOStatus
				,[MOStatusColor]        = CONCAT('#',SUBSTRING(RIGHT('000000' + FORMAT(sn2.[#StatusName], 'X'), 6), 5, 2) +
                                                    SUBSTRING(RIGHT('000000' + FORMAT(sn2.[#StatusName], 'X'), 6), 3, 2) +
                                                    SUBSTRING(RIGHT('000000' + FORMAT(sn2.[#StatusName], 'X'), 6), 1, 2))
				,SN.StatusName	AS BoxStatus
				,[BoxStatusColor]        = CONCAT('#',SUBSTRING(RIGHT('000000' + FORMAT(sn.[#StatusName], 'X'), 6), 5, 2) +
                                                    SUBSTRING(RIGHT('000000' + FORMAT(sn.[#StatusName], 'X'), 6), 3, 2) +
                                                    SUBSTRING(RIGHT('000000' + FORMAT(sn.[#StatusName], 'X'), 6), 1, 2))
				,OD.Comments5 AS [Status/Date]
				,DV.DropDownValue AS ProductionStatus
				,OD.Comments4
				-- ,SUM(PKI.Quantity) AS Qty
				-- ,PB.BoxNumber
				-- ,PB.WarehouseID

			FROM LCA.dbo.StatusNames				AS SN  WITH(NOLOCK) 
			INNER JOIN  LCA.dbo.PackedBoxes			AS PB  WITH(NOLOCK) ON PB.StatusID = SN.StatusID AND SN.StatusID IN (27,25) --AND MO.StatusID <> 67
			INNER JOIN	LCA.dbo.PackedItems			AS PKI WITH(NOLOCK) ON PB.PackedBoxID = PKI.PackedBoxID
			INNER JOIN  LCA.dbo.FinishedGoods		AS FG  WITH(NOLOCK) ON PKI.FinishedGoodsID = FG.FinishedGoodsID
			INNER JOIN  LCA.dbo.Styles				AS ST  WITH(NOLOCK) ON FG.StyleID = st.StyleID
			INNER JOIN  LCA.dbo.StyleColors			AS STC WITH(NOLOCK) ON FG.StyleColorID = STC.StyleColorID
			INNER JOIN  LCA.dbo.ManufactureOrders	AS MO  WITH(NOLOCK) ON MO.ManufactureID = PKI.ManufactureID
			INNER JOIN  LCA.dbo.Orders				AS OD  WITH(NOLOCK) ON OD.OrderID = MO.OrderID AND OD.Comments6 IS NOT NULL
			LEFT  JOIN	LCA.dbo.DropDownValues3		AS DV  WITH(NOLOCK) ON MO.ProductionStatusID = DV.DropDownValueID
			INNER JOIN  LCA.dbo.StatusNames			AS SN2 WITH(NOLOCK) ON MO.StatusID = SN2.StatusID
			INNER JOIN  LCA.dbo.StatusNames			AS SN3 WITH(NOLOCK) ON OD.StatusID = SN3.StatusID
			

			GROUP BY

				OD.PONumber
				,SN3.StatusName
				,sn3.[#StatusName]
				,MO.ManufactureNumber
				,SN2.StatusName
				,sn2.[#StatusName]
				,SN.StatusName
				,sn.[#StatusName]
				,OD.Comments5
				,DV.DropDownValue
				,OD.Comments6
				,ST.StyleNumber
				,STC.StyleColorName
				,OD.Comments4

				-- ,PB.BoxNumber
				-- ,PB.WarehouseID
				--,RA.QuantityWithdrawn
		
		) AS TB

		DROP TABLE IF EXISTS #TB_ItemDetailID
        SELECT  DISTINCT ItemDetailID INTO #TB_ItemDetailID FROM #TB_Supp_Flex

		DROP TABLE IF EXISTS #L2_OrderItemDetail
		DECLARE @ItemDetail NVARCHAR(MAX)-- 1. Convertimos la lista de IDs en un string

		SELECT @ItemDetail = STRING_AGG(CONVERT(NVARCHAR(MAX), ItemDetailID), ',') FROM #TB_ItemDetailID

		-- 2. Ejecutamos la consulta remota con un filtro explícito
		DECLARE @sqlflex NVARCHAR(MAX) = '
			SELECT ItemDetailID, DetailStatus , Quantity , SupplNo
			FROM [db1.legacycaps.com].[Production].[dbo].[order_ItemDetail] WITH(NOLOCK)
			WHERE ItemDetailID IN (' + @ItemDetail + ')'

		-- 3. Creamos tabla temporal con los resultados
		CREATE TABLE #L2_OrderItemDetail (
			 [ItemDetailID]     INT
			,[DetailStatus]     INT
			,[Quantity]         INT
			,[SupplNo]          INT     
		)

		-- PRINT @sql
		INSERT INTO #L2_OrderItemDetail
		EXEC (@sqlflex)
		
		UPDATE TBS SET
		TBS.SupplNo = OE.SupplNo

		FROM #TB_Supp_Flex AS TBS
		INNER JOIN #L2_OrderItemDetail AS OE WITH(NOLOCK) ON OE.ItemDetailID = TBS.ItemDetailID
	
		SELECT 
			 CustomerOrder
			,CAST(ItemDetailID AS VARCHAR(50)) AS ItemDetailID
			,PONumber
			,ORDStatus
			,ORDStatusColor
			,ManufactureNumber
			,MOStatus
			,MOStatusColor
			,Style
			,Color
			,Make
			,BoxStatus
			,BoxStatusColor
			,[Status/Date]
			,ProductionStatus
			,Comments4 as Customer
			,ISNULL(SupplNo, 'ELIMINADO EN L2Brand') AS Supplier
		FROM #TB_Supp_Flex WHERE (SupplNo is null OR SupplNo <> 162)
		RETURN

	END --- FIN IF PROCESS SUPPLIER
	--wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww--wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww

	END TRY
	BEGIN CATCH
		SET @message = 'Error in Database'
		SET @error = 1
		SET @result = '[]'
	END CATCH

	-- Devolver JSON unificado
	SELECT 
		[Error]	= @error
		,[message]	= @message
		,[Result]	= JSON_QUERY(@result)
	FOR JSON PATH  ,INCLUDE_NULL_VALUES--, WITHOUT_ARRAY_WRAPPER

END
