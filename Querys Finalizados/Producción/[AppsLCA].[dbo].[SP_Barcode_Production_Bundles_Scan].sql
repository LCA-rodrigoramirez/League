USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_Barcode_Production_Bundles_Scan]    Script Date: 16/02/2026 07:56:35 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_Barcode_Production_Bundles_Scan]
	 @PPBU		VARCHAR(MAX)
	,@PPAD		VARCHAR(MAX)
	,@Scanner	VARCHAR(10)
	,@IsPartial BIT
	,@Qty		INT
AS
SET NOCOUNT ON 
BEGIN
		--DECLARE @PPBU AS VARCHAR(MAX)
		----SET @PPBU = 'PPTK21577181'
		--SET @PPBU = 'PPBU12488848'
		--DECLARE @PPAD AS VARCHAR(MAX)
		----SET @PPAD = 'PPAD46279'
		--SET @PPAD = 'PPAD45393'
		--DECLARE @Scanner AS VARCHAR(10)
		--SET @Scanner = '1'
		--DECLARE @IsPartial AS BIT
		--SET @IsPartial = 0
		--DECLARE @Qty AS INT;
		--SET @Qty = 0;
		DECLARE @MaxTime AS INT = 10
		DECLARE @InitialTime AS DATETIME = GETDATE()
		DECLARE @ActualTime AS DATETIME = GETDATE()
		DECLARE @DateResponse AS varchar(50) = FORMAT(CAST(GETDATE() AS DATETIME), 'yyyy-MM-dd hh:mm:ss tt')
		DECLARE @msg AS NVARCHAR(MAX)
		DECLARE @Component AS NVARCHAR(MAX)
		DECLARE @IsValid	  AS BIT

	BEGIN TRY
		
		DECLARE @Fecha AS VARCHAR(20)
		SET @Fecha = (SELECT CONVERT(VARCHAR(8), GETDATE(), 112))
		DECLARE @Hora AS VARCHAR(20)
		SET @Hora = (	SELECT 
						RIGHT('0' + CAST(DATEPART(HOUR, GETDATE()) AS VARCHAR(2)), 2) +
						RIGHT('0' + CAST(DATEPART(MINUTE, GETDATE()) AS VARCHAR(2)), 2) +
						RIGHT('0' + CAST(DATEPART(SECOND, GETDATE()) AS VARCHAR(2)), 2) +
						CAST(DATEPART(MILLISECOND, GETDATE()) / 100 AS VARCHAR(1))	)
    
		DECLARE @TaskComplete AS VARCHAR(MAX)
		DECLARE @TaskPending  AS VARCHAR(MAX)
		DECLARE @TaskActual AS VARCHAR(MAX)
		DECLARE @MOStatus AS INT
		
		DECLARE @ID_PPBU AS INT 
		SET @ID_PPBU = (CAST(SUBSTRING(@PPBU,5,len(@PPBU)) AS INT) - 10000000)
		DECLARE @ID_PPAD AS INT
		SET @ID_PPAD = (CAST(SUBSTRING(@PPAD,5,len(@PPAD)) AS INT) - 10000)

		DECLARE @Datos              VARCHAR(200)    --Variable que tiene los datos que iran en el archivo TXT
		DECLARE @DatosEnviarAPI		NVARCHAR(MAX) 
		DECLARE @flagJson		AS BIT
		DECLARE @responsePPM	AS NVARCHAR(MAX)
		DECLARE @jsonResponse	AS NVARCHAR(MAX)
		DECLARE @FinalComponent AS NVARCHAR(MAX)


		DROP TABLE IF EXISTS #TB_EORO_Packing
		CREATE TABLE #TB_EORO_Packing (
			 [ManufactureID]	INT
			,[Size]				VARCHAR(30)
			,[Validation]		BIT
		)

		IF OBJECT_ID('tempdb..#TB_FlowChart') IS NOT NULL  DROP TABLE #TB_FlowChart
		CREATE TABLE #TB_FlowChart (
			 [BundleID]				INT
			,[seq]					INT
			,[nodenumber]			INT
			,[nextnodenumber]		INT
			,[taskname]				VARCHAR(100)
			,[Quantity]				INT
	
		)

		IF OBJECT_ID('tempdb..#TB_Response') IS NOT NULL  DROP TABLE #TB_Response
		CREATE TABLE #TB_Response (
			 [PPBU]				VARCHAR(100)
			,[PPAD]				VARCHAR(100)
			,[Flag]				BIT
			,[Msg]				NVARCHAR(MAX)
			,[FinalComponent]	NVARCHAR(MAX)
		)

		IF SUBSTRING(@PPBU,1,4) = 'PPBU'
		BEGIN

			IF EXISTS
			(
				SELECT
					TB.*
				FROM
				(
					SELECT 
						[R]                = ROW_NUMBER() OVER (PARTITION BY b.ManufactureID ORDER BY WT.Sequence)
						,b.*
						,[Sequence]         = WT.Sequence
						,[TaskName]         = WT.TaskName
						,[WTStartDate]      = WT.StartDate
						,[WTFinishDate]     = WT.FinishDate
						,[WTUseBundles]		= WT.UseBundles
						,[LastUseBundles]	= LAG(WT.UseBundles) OVER (PARTITION BY b.ManufactureID ORDER BY b.ManufactureID, WT.Sequence)
						,[LastTask]			= LAG(WT.TaskName) OVER (PARTITION BY b.ManufactureID ORDER BY b.ManufactureID, WT.Sequence)
					FROM  (SELECT ManufactureID FROM LCA.dbo.Bundles AS b with(nolock) WHERE b.[BundleID] = @ID_PPBU) AS b
					INNER JOIN [LCA].[dbo].WorkFlows            AS WF   WITH(NOLOCK) ON WF.ManufactureID    = B.ManufactureID
					INNER JOIN [LCA].[dbo].WorkTasks            AS WT   WITH(NOLOCK) ON WT.WorkFlowID       = WF.WorkFlowID
				) AS TB
				INNER JOIN [LCA].[dbo].[Addresses]				AS AD	WITH(NOLOCK) ON TB.TaskName	= AD.ProductionTaskName AND AD.AddressID = @ID_PPAD
				WHERE TB.WTUseBundles = 1 AND TB.LastUseBundles = 0 AND TB.WTStartDate IS NULL
			)
			BEGIN
				SET @TaskActual = (SELECT 
										a.ProductionTaskName 
									FROM LCA.dbo.Addresses as a WITH(NOLOCK)
									WHERE AddressID = @ID_PPAD)

				SET @TaskPending = (SELECT
										TB.LastTask
									FROM
									(
										SELECT 
											[R]                = ROW_NUMBER() OVER (PARTITION BY b.ManufactureID ORDER BY WT.Sequence)
											,b.*
											,[Sequence]         = WT.Sequence
											,[TaskName]         = WT.TaskName
											,[WTStartDate]      = WT.StartDate
											,[WTFinishDate]     = WT.FinishDate
											,[WTUseBundles]		= WT.UseBundles
											,[LastUseBundles]	= LAG(WT.UseBundles) OVER (PARTITION BY b.ManufactureID ORDER BY b.ManufactureID, WT.Sequence)
											,[LastTask]			= LAG(WT.TaskName) OVER (PARTITION BY b.ManufactureID ORDER BY b.ManufactureID, WT.Sequence)
										FROM  (SELECT ManufactureID FROM LCA.dbo.Bundles AS b with(nolock) WHERE b.[BundleID] = @ID_PPBU) AS b
										INNER JOIN [LCA].[dbo].WorkFlows            AS WF   WITH(NOLOCK) ON WF.ManufactureID    = B.ManufactureID
										INNER JOIN [LCA].[dbo].WorkTasks            AS WT   WITH(NOLOCK) ON WT.WorkFlowID       = WF.WorkFlowID
									) AS TB
									INNER JOIN [LCA].[dbo].[Addresses]				AS AD	WITH(NOLOCK) ON TB.TaskName	= AD.ProductionTaskName AND AD.AddressID = @ID_PPAD
									)
				SET @IsValid = 0
				SET @msg = 'No se pudo escanear el bulto '+@PPBU+' con la tarea '+@TaskActual+', porque la tarea '+@TaskPending+' está pendiente.'
				SET @Component = '[LastBarcode]'
			END
			ELSE
			BEGIN

				INSERT INTO #TB_EORO_Packing
				SELECT
					 [ManufactureID]    = [ManufactureID]
					,[Size]             = [Size]
					,[Validation]       = MAX(IIF( [QuantityNeeded] <> 0 OR [QuantityWithdrawn] > [QuantityRequired] ,1,0))
				FROM(
					SELECT
						 [ManufactureID]        = TB.ManufactureID
						,[MO]                   = MO.ManufactureNumber
						,[Size]                 = FG.GarmentSize
						,[QuantityRequired]     = MB.QuantityRequired
						,[QuantityWithdrawn]    = MB.QuantityWithdrawn
						,[QuantityNeeded]       = MB.QuantityRequired - MB.QuantityWithdrawn

					FROM (SELECT ManufactureID FROM LCA.dbo.Bundles WITH(NOLOCK) WHERE BundleID = @ID_PPBU) AS TB
					INNER JOIN  LCA.dbo.ManufactureOrders    AS MO WITH(NOLOCK) ON TB.ManufactureID     = MO.ManufactureID 
					INNER JOIN  LCA.dbo.ManufactureBlanks    AS MB WITH(NOLOCK) ON MB.ManufactureID     = MO.ManufactureID      ---AND (MB.QuantityRequired - MB.QuantityWithdrawn) <> 0
					INNER JOIN  LCA.dbo.FinishedGoods        AS FG WITH(NOLOCK) ON FG.FinishedGoodsID   = MB.FinishedGoodsID
				) AS TB
				WHERE IIF( [QuantityNeeded] <> 0 OR [QuantityWithdrawn] > [QuantityRequired] ,1,0) = 1
				GROUP BY
					[ManufactureID]
					,[Size]

				IF EXISTS (SELECT * FROM #TB_EORO_Packing)
				BEGIN
					SET @IsValid = 0 
					SET @msg = 'El Bulto '+@PPBU+', no se puede escanear porque la MO tiene discrepancias en Make o en Unidades despachadas por Bodega'
					SET @Component = '[401]'
				END
				ELSE
				BEGIN


					SET @MOStatus = (SELECT StatusID FROM LCA.dbo.ManufactureOrders WITH(NOLOCK) WHERE ManufactureID = (SELECT TOP 1 ManufactureID 
																														FROM LCA.dbo.Bundles WITH(NOLOCK) 
																														WHERE BundleID = @ID_PPBU) )
               

					--- Se agrega para evitar que escaneen los bultos si la MO está en Status Hold (StatusID = 67) --- Rodrigo Ramírez 20250707
					IF @MOStatus = 67
					BEGIN
						SET @IsValid = 0 
						SET @msg = 'El Bulto '+@PPBU+', no se puede escanear porque la MO está Hold.'
						SET @Component = '[401]'
					END
					ELSE
					BEGIN
						--- Se agrega para evitar que escaneen el PPAD para crear cajas en empaque --- Rodrigo Ramírez 20250625
						IF EXISTS (SELECT * FROM LCA.dbo.Addresses WITH(NOLOCK) WHERE AddressID = @ID_PPAD AND Fax = 1)
							BEGIN
								SET @IsValid = 0 
								SET @msg = 'El PPAD '+@PPAD+' no es valido para este proceso, favor escanear el correcto.'
								SET @Component = '[401]'
							END
						ELSE


						BEGIN
							IF NOT EXISTS (SELECT * from LCA.dbo.Bundles with(nolock) where BundleID = @ID_PPBU)
								BEGIN
									SET @IsValid = 0 
									SET @msg = 'El bulto '+@PPBU+' no existe, favor actualizar Traveler de orden.'
									SET @Component = '[Barcode]'
						

								END
							ELSE
								BEGIN
									SET @TaskComplete =	 (
															SELECT
																 TB_Com.TaskName

															FROM
																(
																	SELECT   [BundleID]		=	b.[BundleID]
												
																			--,[OperatorID]		=	wt.[OperatorID]
																			,[TaskName]		=	RTRIM(t.[TaskName])
																			,[QtyBundle]	= b.QuantityOrdered
																			,[Quantity]		=	SUM(wt.[Quantity])
																	FROM		LCA.dbo.Bundles				AS b  with(nolock)
																	INNER JOIN  LCA.dbo.WorkTransactions    AS wt with(nolock)   ON b.[BundleID] = wt.[BundleID]
																																 AND b.[BundleID] = @ID_PPBU-- AND wt.[OperatorID] = 35466
																	INNER JOIN  LCA.dbo.WorkTasks			AS t  with(nolock)	 ON wt.[TaskID]  = t.[TaskID]
																																 AND t.TaskName = (SELECT TOP 1 ProductionTaskName FROM LCA.dbo.Addresses AS AD WITH(NOLOCK) WHERE AddressID = @ID_PPAD)
																	GROUP BY b.[BundleID],t.[TaskName],b.QuantityOrdered
																) TB_Com
															WHERE IIF(Quantity <> [QtyBundle],0,1) = 1
														 )
									---CAMBIO REALIZADO CON DP, PARA VERIFICAR LA CANTIDAD COMPLETA DE LAS TRANSACCIONES CON LOS BULTOS. (ERROR CON DATA QUE TIENE SEGUNDAS)
									--SET @TaskComplete =	 (
									--						SELECT
									--							 TB_Com.TaskName

									--						FROM
									--							(
									--								SELECT   [BundleID]		=	b.[BundleID]
												
									--										--,[OperatorID]		=	wt.[OperatorID]
									--										,[TaskName]		=	RTRIM(t.[TaskName])
									--										,[Quantity]		=	SUM(wt.[Quantity])
									--								FROM		LCA.dbo.Bundles				AS b  with(nolock)
									--								INNER JOIN  LCA.dbo.WorkTransactions    AS wt with(nolock)   ON b.[BundleID] = wt.[BundleID]
									--																							 AND b.[BundleID] = @ID_PPBU-- AND wt.[OperatorID] = 35466
									--								INNER JOIN  LCA.dbo.WorkTasks			AS t  with(nolock)	 ON wt.[TaskID]  = t.[TaskID]
									--																							 AND t.TaskName = (SELECT TOP 1 ProductionTaskName FROM LCA.dbo.Addresses AS AD WITH(NOLOCK) WHERE AddressID = @ID_PPAD)
									--								GROUP BY b.[BundleID],t.[TaskName]
									--							) TB_Com
									--						WHERE IIF(Quantity <= 0,0,1) = 1
									--					 )
									IF @TaskComplete <> ''
					
										BEGIN
											SET @IsValid = 1
											SET @msg = 'El bulto '+@PPBU+', con la tarea '+@TaskComplete+' ya fue escaneado.'
											SET @Component = '[Barcode]'

										END
									ELSE
										BEGIN
											INSERT INTO #TB_FlowChart
											select   @ID_PPBU
													,[sequence]
													,nodenumber
													,nextnodenumber
													,taskname
													,Quantity

											from 
													(
													SELECT 
														 [Sequence]			=	t.[Sequence]
														,[NodeNumber]		=	t.[NodeNumber]
														,[NextNodeNumber]	=	t.[NextNodeNumber]
														,[TaskName]			=	t.[TaskName]
														,[FinishDate]		=	wf.[FinishDate]
														,Quantity			=	SUM(wt.[Quantity])
												
													FROM  (SELECT ManufactureID FROM LCA.dbo.Bundles AS b with(nolock) WHERE b.[BundleID] = @ID_PPBU) AS b
													INNER JOIN	LCA.dbo.WorkFlows			AS wf  with(nolock)   ON b.ManufactureID = wf.ManufactureID
													INNER JOIN  LCA.dbo.WorkTasks			AS t   with(nolock)	  ON wf.[WorkFlowID] = t.[WorkFlowID] 
													INNER JOIN  LCA.dbo.WorkTransactions    AS wt  with(nolock)   ON wt.[TaskID]	 = t.[TaskID]
													GROUP BY
														 t.[Sequence]
														,t.[NodeNumber]
														,t.[NextNodeNumber]
														,t.[TaskName]
														,wf.[FinishDate]

							
													) tb_task
					
											
											SET @TaskActual = (SELECT 
																	a.ProductionTaskName 
																FROM LCA.dbo.Addresses as a WITH(NOLOCK)
																WHERE AddressID = @ID_PPAD)

											DECLARE @NodeNumber AS INT
											SET @NodeNumber =	(SELECT 
																	fc.nodenumber	
																 FROM #TB_FlowChart as fc 
																 WHERE taskname = @TaskActual)

											WHILE (1 = 1)
											BEGIN
												SET @IsValid = 0
												IF EXISTS (SELECT top 1
																fc.taskname 
														   FROM #TB_FlowChart AS fc 
														   WHERE nextnodenumber = @NodeNumber AND IIF(Quantity <= 0,0,1) = 0
														  )
													BEGIN
														SET @TaskPending = (SELECT fc.taskname 
																			FROM #TB_FlowChart as fc 
																			WHERE nextnodenumber = @NodeNumber AND IIF(Quantity <= 0,0,1) = 0)
													END
												ELSE
													BEGIN
														IF EXISTS (SELECT top 1 
																		fc.taskname 
																   FROM #TB_FlowChart as fc 
																   WHERE nextnodenumber = @NodeNumber AND IIF(Quantity <= 0,0,1) = 1
																  )
														BEGIN
															SET @NodeNumber = (SELECT top 1 
																					fc.nodenumber
																				FROM #TB_FlowChart as fc 
																				WHERE nextnodenumber = @NodeNumber)
														END
														ELSE
														BEGIN
															SET @TaskPending = 'No hay Tareas Pendientes'
															SET @IsValid = 1
														END
													END

												IF @TaskPending <> ''
												BEGIN
													BREAK
												END
												SET @ActualTime = GETDATE()
												IF DATEDIFF(SECOND,@InitialTime,@ActualTime) >= @MaxTime
												BEGIN
													GOTO APIPPM
												END
					
					
 											END
									
											IF @TaskPending <> '' AND @IsValid <> 1
											BEGIN
												SET @msg = 'No se pudo escanear el bulto '+@PPBU+' con la tarea '+@TaskActual+', porque la tarea '+@TaskPending+' está pendiente.'
												SET @Component = '[LastBarcode]'

											END
											ELSE
											BEGIN
											APIPPM:

												-- Construcción robusta de @Datos
												IF (@IsPartial = 1)
												BEGIN
											
													SET @Datos = CONCAT(
														'OPR,', @PPAD, ',', @Fecha, ',', @Hora, ',', @Scanner, ',WIPT,', @PPBU, ',', CONVERT(VARCHAR(12), @Qty)
													);
												END
												ELSE
												BEGIN
													SET @Datos = CONCAT(
														'OPR,', @PPAD, ',', @Fecha, ',', @Hora, ',', @Scanner, ',WIPT,', @PPBU
													);
												END


												-- SET @Datos              = 'OPR,'+@PPAD+','+@Fecha+','+@Hora+','+@Scanner+',WIPT,'+@PPBU
												SET @DatosEnviarAPI= @Datos
										
												--SELECT @DatosEnviarAPI
												--DECLARE @flagJson		AS BIT
												--DECLARE @responsePPM	AS NVARCHAR(MAX)
												--DECLARE @jsonResponse	AS NVARCHAR(MAX)
												--DECLARE @FinalComponent AS NVARCHAR(MAX)
 
												--- Ejecutar el procedimiento almacenado y capturar el resultado JSON en una variable de salida
												EXEC [AppsLCA].[dbo].[SP_Barcode_TransactionAPI] 
												--EXEC [192.168.1.93].[AppsLCA].[dbo].[SP_Barcode_TransactionAPI] 
													@VarTransaction = @DatosEnviarAPI,				--'BOX,PPMB1606768,20250214,1325890,1,TBUQ,PPBX11441940,PPFG1196505,1',
													@jsonResponse = @jsonResponse OUTPUT
 
												--- Extraer los valores del JSON de salida
												SET @msg = JSON_VALUE(@jsonResponse, '$[0].MessagePPM')
												SET @IsValid = JSON_VALUE(@jsonResponse, '$[0].FlagCompleted')
												SET @Component = JSON_VALUE(@jsonResponse, '$[0].FinalComponent')
 
												 --- Ver los valores extraídos
												--INSERT INTO #TB_Response
												--SELECT @PPBU,@PPAD,@flagJson,@responsePPM + ' TransactionDate: ' + @DateResponse, @FinalComponent

					
											END --- FIN ENVIO DE PETICION API ---
										END --- FIN IF TaskComplete ---
		
								END --- FIN IF Bulto no existe ---
							END --- FIN IF PPAD Shipping NO VALIDO
						END --- FIN IF MO STATUS HOLD
					END --- FIN IF DESPACHO DE PRENDAS
				END --- FIN IF PRIMER TAREA QUE NO USA BULTOS
			END --- FIN IF PPBU
			ELSE
			BEGIN
				
				INSERT INTO #TB_EORO_Packing
				SELECT
						[ManufactureID]    = [ManufactureID]
					,[Size]             = [Size]
					,[Validation]       = MAX(IIF( [QuantityNeeded] <> 0 OR [QuantityWithdrawn] > [QuantityRequired] ,1,0))
				FROM(
					SELECT
							[ManufactureID]        = MO.ManufactureID
						,[MO]                   = MO.ManufactureNumber
						,[Size]                 = FG.GarmentSize
						,[QuantityRequired]     = MB.QuantityRequired
						,[QuantityWithdrawn]    = MB.QuantityWithdrawn
						,[QuantityNeeded]       = MB.QuantityRequired - MB.QuantityWithdrawn

					FROM (SELECT WorkFlowID FROM LCA.dbo.WorkTasks WITH(NOLOCK) WHERE TaskID = @ID_PPBU) AS TB
					INNER JOIN  LCA.dbo.WorkFlows			 AS WF WITH(NOLOCK) ON TB.WorkFlowID		= WF.WorkFlowID
					INNER JOIN  LCA.dbo.ManufactureOrders    AS MO WITH(NOLOCK) ON WF.ManufactureID     = MO.ManufactureID 
					INNER JOIN  LCA.dbo.ManufactureBlanks    AS MB WITH(NOLOCK) ON MB.ManufactureID     = MO.ManufactureID      ---AND (MB.QuantityRequired - MB.QuantityWithdrawn) <> 0
					INNER JOIN  LCA.dbo.FinishedGoods        AS FG WITH(NOLOCK) ON FG.FinishedGoodsID   = MB.FinishedGoodsID
				) AS TB
				WHERE IIF( [QuantityNeeded] <> 0 OR [QuantityWithdrawn] > [QuantityRequired] ,1,0) = 1
				GROUP BY
					[ManufactureID]
					,[Size]

					

				IF EXISTS (SELECT * FROM #TB_EORO_Packing)
				BEGIN
					SET @IsValid = 0 
					SET @msg = 'El Código '+@PPBU+', no se puede escanear porque la MO tiene discrepancias en Make o en Unidades despachadas por Bodega'
					SET @Component = '[401]'
				END
				ELSE
				BEGIN


					SET @MOStatus = (SELECT StatusID FROM LCA.dbo.ManufactureOrders WITH(NOLOCK) 
										WHERE ManufactureID = (SELECT TOP 1 ManufactureID 
															FROM LCA.dbo.WorkFlows WITH(NOLOCK)
															WHERE WorkFlowID = (SELECT TOP 1 WorkFlowID
																				FROM LCA.dbo.WorkTasks WITH(NOLOCK)
																				WHERE TaskID = @ID_PPBU
																				)
															)
									)
               

					--- Se agrega para evitar que escaneen los bultos si la MO está en Status Hold (StatusID = 67) --- Rodrigo Ramírez 20250707
					IF @MOStatus = 67
					BEGIN
						SET @IsValid = 0 
						SET @msg = 'El Código '+@PPBU+', no se puede escanear porque la MO está Hold.'
						SET @Component = '[401]'
					END
					ELSE
					BEGIN
						--- Se agrega para evitar que escaneen el PPAD para crear cajas en empaque --- Rodrigo Ramírez 20250625
						IF EXISTS (SELECT * FROM LCA.dbo.Addresses WITH(NOLOCK) WHERE AddressID = @ID_PPAD AND Fax = 1)
							BEGIN
								SET @IsValid = 0 
								SET @msg = 'El PPAD '+@PPAD+' no es valido para este proceso, favor escanear el correcto.'
								SET @Component = '[401]'
							END
						ELSE


						BEGIN
								--BEGIN
								--	INSERT INTO #TB_FlowChart
								--	select   @ID_PPBU
								--			,[sequence]
								--			,nodenumber
								--			,nextnodenumber
								--			,taskname
								--			,Quantity

								--	from 
								--			(
								--			SELECT 
								--					[Sequence]			=	t.[Sequence]
								--				,[NodeNumber]		=	t.[NodeNumber]
								--				,[NextNodeNumber]	=	t.[NextNodeNumber]
								--				,[TaskName]			=	t.[TaskName]
								--				,Quantity			=	SUM(wt.[Quantity])
							
								--			FROM  LCA.dbo.Bundles AS b with(nolock)
								--			INNER JOIN  LCA.dbo.WorkTransactions   AS wt  with(nolock)   ON b.[BundleID] = wt.[BundleID] AND b.[BundleID] = @ID_PPBU
								--			INNER JOIN  LCA.dbo.WorkTasks			AS t   with(nolock)  ON wt.[TaskID]  = t.[TaskID] 
								--			GROUP BY
								--					t.[Sequence]
								--				,t.[NodeNumber]
								--				,t.[NextNodeNumber]
								--				,t.[TaskName]
							
								--			) tb_task
					
								--	DECLARE @TaskActual AS VARCHAR(MAX)
								--	SET @TaskActual = (SELECT 
								--							a.ProductionTaskName 
								--						FROM LCA.dbo.Addresses as a WITH(NOLOCK)
								--						WHERE AddressID = @ID_PPAD)

								--	DECLARE @NodeNumber AS INT
								--	SET @NodeNumber =	(SELECT 
								--							fc.nodenumber	
								--							FROM #TB_FlowChart as fc 
								--							WHERE taskname = @TaskActual)

								--	WHILE (1 = 1)
								--	BEGIN
								--		SET @IsValid = 0
								--		IF EXISTS (SELECT top 1
								--						fc.taskname 
								--					FROM #TB_FlowChart AS fc 
								--					WHERE nextnodenumber = @NodeNumber AND IIF(Quantity <= 0,0,1) = 0
								--					)
								--			BEGIN
								--				SET @TaskPending = (SELECT fc.taskname 
								--									FROM #TB_FlowChart as fc 
								--									WHERE nextnodenumber = @NodeNumber AND IIF(Quantity <= 0,0,1) = 0)
								--			END
								--		ELSE
								--			BEGIN
								--				IF EXISTS (SELECT top 1 
								--								fc.taskname 
								--							FROM #TB_FlowChart as fc 
								--							WHERE nextnodenumber = @NodeNumber AND IIF(Quantity <= 0,0,1) = 1
								--							)
								--				BEGIN
								--					SET @NodeNumber = (SELECT top 1 
								--											fc.nodenumber
								--										FROM #TB_FlowChart as fc 
								--										WHERE nextnodenumber = @NodeNumber)
								--				END
								--				ELSE
								--				BEGIN
								--					SET @TaskPending = 'No hay Tareas Pendientes'
								--					SET @IsValid = 1
								--				END
								--			END

								--		IF @TaskPending <> ''
								--		BEGIN
								--			BREAK
								--		END
								--		SET @ActualTime = GETDATE()
								--		IF DATEDIFF(SECOND,@InitialTime,@ActualTime) >= @MaxTime
								--		BEGIN
								--			GOTO APIPPM
								--		END
					
					
 							--		END
									
								--	IF @TaskPending <> '' AND @IsValid <> 1
								--	BEGIN
								--		SET @msg = 'No se pudo escanear el bulto '+@PPBU+' con la tarea '+@TaskActual+', porque la tarea '+@TaskPending+' está pendiente.'
								--		SET @Component = '[LastBarcode]'

								--	END
								--	ELSE
									BEGIN
									--APIPPM:
										-- Construcción robusta de @Datos
										
										SET @Datos = CONCAT(
											'OPR,', @Fecha, ',', @Hora, ',', '1', ',', @PPAD, ',CTSK,', @PPBU
										);


										--SET @Datos              = 'OPR,'+@PPAD+','+@Fecha+','+@Hora+','+@Scanner+',WIPT,'+@PPBU
										SET @DatosEnviarAPI= @Datos
										
										--SELECT @DatosEnviarAPI

 
										--- Ejecutar el procedimiento almacenado y capturar el resultado JSON en una variable de salida
										EXEC [AppsLCA].[dbo].[SP_Barcode_TransactionAPI] 
										--EXEC [192.168.1.93].[AppsLCA].[dbo].[SP_Barcode_TransactionAPI] 
											@VarTransaction = @DatosEnviarAPI,				--'BOX,PPMB1606768,20250214,1325890,1,TBUQ,PPBX11441940,PPFG1196505,1',
											@jsonResponse = @jsonResponse OUTPUT
 
										--- Extraer los valores del JSON de salida
										SET @msg = JSON_VALUE(@jsonResponse, '$[0].MessagePPM')
										SET @IsValid = JSON_VALUE(@jsonResponse, '$[0].FlagCompleted')
										SET @Component = JSON_VALUE(@jsonResponse, '$[0].FinalComponent')
 
											--- Ver los valores extraídos
										--INSERT INTO #TB_Response
										--SELECT @PPBU,@PPAD,@flagJson,@responsePPM + ' TransactionDate: ' + @DateResponse, @FinalComponent

					
									END --- FIN ENVIO DE PETICION API ---
							END --- FIN IF PPAD Shipping NO VALIDO
						END --- FIN IF MO STATUS HOLD
					END --- FIN IF DESPACHO DE PRENDAS
			END --- FIN IF PPTK
			INSERT INTO #TB_Response
			SELECT @PPBU,@PPAD,@IsValid,@msg + ' TransactionDate: ' + @DateResponse, @Component
			 ----Devolver Respuesta----
			SELECT * FROM #TB_Response FOR JSON PATH
	END TRY
	BEGIN CATCH
		SELECT
		 [PPBU]				=	@PPBU	
		,[PPAD]				=	@PPAD
		,[Flag]				=	0
		,[Msg]				=	'Database error'
		,[FinalComponent]	=	'[DataBase]'
		 
	END CATCH
END
