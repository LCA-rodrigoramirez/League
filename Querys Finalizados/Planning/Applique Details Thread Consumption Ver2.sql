USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_Orders_AppliqueDetails_ThreadConsumption]    Script Date: 21/01/2026 02:05:11 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Rodrigo Ramirez
-- Create date: 2025-09-12
-- Description:	Detalle de Applique y consumo de hilo en Yardas por cada Orden activa de bordado
-- =============================================
ALTER PROCEDURE [dbo].[SP_Orders_AppliqueDetails_ThreadConsumption_New]
	@process	VARCHAR(100)
	,@data		NVARCHAR(MAX) = NULL
AS
BEGIN

SET NOCOUNT ON;

	/*************************************************************************** VARIABLES SECTION ***************************************************************************/

		DECLARE @Component AS NVARCHAR(200)
		DECLARE @Error AS BIT
		DECLARE @message AS NVARCHAR(200)
		DECLARE @result AS NVARCHAR(MAX)
		-- DECLARE @process AS VARCHAR(100) = 'report-general'

	/*************************************************************************** VARIABLES SECTION ***************************************************************************/	
	BEGIN TRY

		/*************************************************************************** DROP TABLES SECTION ***************************************************************************/

			DROP TABLE IF EXISTS #TB_MO_FILTER
			DROP TABLE IF EXISTS #TB_MO
			DROP TABLE IF EXISTS #L2_Applique
			DROP TABLE IF EXISTS #L2_AppliqueInfo
			DROP TABLE IF EXISTS #L2_ThreadInfo
			DROP TABLE IF EXISTS #TB_MO_CONSUMPTION
			DROP TABLE IF EXISTS #TB_MO_Applique
			DROP TABLE IF EXISTS #L2_DigitizingInfo
			DROP TABLE IF EXISTS #TB_MO_DIGITIZING
			DROP TABLE IF EXISTS #TB_RESPONSE
			DROP TABLE IF EXISTS #TB_PAIR_FIX
			DROP TABLE IF EXISTS #L2_TotalThreadPerWO
			DROP TABLE IF EXISTS #TB_InventoryThread

		/*************************************************************************** DROP TABLES SECTION ***************************************************************************/

		/********************************* FILTER MO STATUS < 90 Y UPDATES PARA EXTRAER ORDENES DE BORDADO Y SABER SI YA FINALIZARON EL PROCESO O NO *******************************/
			
			
			SELECT
				[ManufactureID]    = MO.ManufactureID
				,[MO]               = MO.ManufactureNumber
				,[WorkFlowID]       = CAST(NULL AS INT)
				,[WorkFlowName]     = CAST(NULL AS VARCHAR(MAX))
				,[EmbHW]            = CAST(0 AS BIT)
				,[EmbAPP]           = CAST(0 AS BIT)
				,[EmbHWFinish]      = CAST(0 AS BIT)
				,[EmbAPPFinish]     = CAST(0 AS BIT)
			INTO #TB_MO_FILTER
			--SELECT*
			FROM (
				SELECT 
					[StatusID]
				FROM LCA.dbo.StatusNames WITH (NOLOCK)
				WHERE [StatusID] < 90
			) AS FSN
			INNER JOIN      LCA.dbo.ManufactureOrders           AS MO   WITH(NOLOCK) ON MO.[StatusID]       = FSN.[StatusID] 
			INNER JOIN       LCA.dbo.OrderItems                  AS OI   WITH(NOLOCK) ON OI.OrderItemID      = MO.FirstOrderItemID
			INNER JOIN      LCA.dbo.Orders                      AS OD   WITH(NOLOCK) ON OD.OrderID          = OI.OrderID              AND OD.PONumber IS NOT NULL
			

			--- BORDADO DE PRENDAS ---

			UPDATE MO SET
					[WorkFlowID]       = WF.WorkFlowID
				,[WorkFlowName]     = WF.WorkFlowName
			FROM #TB_MO_FILTER AS MO
			INNER JOIN LCA.dbo.WorkFlows AS WF WITH (NOLOCK) ON MO.ManufactureID = WF.ManufactureID


			UPDATE MO SET
				[EmbAPP]           =   IIF(WT_01.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_02.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_03.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_04.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_05.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_06.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_07.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_08.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_09.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_10.TaskName  IS NOT NULL, 1, 0)
			FROM #TB_MO_FILTER       AS MO
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Start Embroidery 1'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Start Embroidery 2'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Start Embroidery 3'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Start Embroidery 4'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'Start Embroidery 5'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'Start Embroidery 6'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'Start Embroidery 7'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'Start Embroidery 8'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_09    WITH(NOLOCK) ON MO.WorkFlowID = WT_09.WorkFlowID    AND WT_09.TaskName  = 'Start Embroidery 9'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_10    WITH(NOLOCK) ON MO.WorkFlowID = WT_10.WorkFlowID    AND WT_10.TaskName  = 'Start Embroidery 10'


			--- BORDADO DE GORRAS
			
			UPDATE MO SET
				[EmbHW]            =   IIF(WT_01.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_02.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_03.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_04.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_05.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_06.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_07.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_08.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_09.TaskName  IS NOT NULL, 1, 0) +
										IIF(WT_10.TaskName  IS NOT NULL, 1, 0) 
										--SELECT * 
			FROM #TB_MO_FILTER       AS MO
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Start  Embroidery HW 1'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Start  Embroidery HW 2'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Start  Embroidery HW 3'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Start  Embroidery HW 4'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'Start  Embroidery HW 5'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'Start  Embroidery HW 6'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'Start  Embroidery HW 7'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'Start  Embroidery HW 8'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_09    WITH(NOLOCK) ON MO.WorkFlowID = WT_09.WorkFlowID    AND WT_09.TaskName  = 'Start  Embroidery HW 9'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_10    WITH(NOLOCK) ON MO.WorkFlowID = WT_10.WorkFlowID    AND WT_10.TaskName  = 'Start  Embroidery HW 10'
			
			--- SABER SI EL PROCESO DE BORDADO DE PRENDAS YA SE EMPEZÓ --- 
			
			UPDATE MO SET
				[EmbAPPFinish]      =   IIF(WT_01.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_02.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_03.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_04.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_05.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_06.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_07.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_08.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_09.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_10.FinishDate  IS NOT NULL, 1, 0) 
										
			FROM #TB_MO_FILTER       AS MO
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Start Embroidery 1'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Start Embroidery 2'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Start Embroidery 3'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Start Embroidery 4'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'Start Embroidery 5'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'Start Embroidery 6'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'Start Embroidery 7'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'Start Embroidery 8'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_09    WITH(NOLOCK) ON MO.WorkFlowID = WT_09.WorkFlowID    AND WT_09.TaskName  = 'Start Embroidery 9'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_10    WITH(NOLOCK) ON MO.WorkFlowID = WT_10.WorkFlowID    AND WT_10.TaskName  = 'Start Embroidery 10'
			
			
			--- SABER SI EL PROCESO DE BORDADO DE GORRAS YA SE FINALIZÓ --- 

			UPDATE MO SET
				[EmbHWFinish]       =   IIF(WT_01.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_02.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_03.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_04.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_05.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_06.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_07.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_08.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_09.FinishDate  IS NOT NULL, 1, 0) +
										IIF(WT_10.FinishDate  IS NOT NULL, 1, 0) 
			FROM #TB_MO_FILTER       AS MO
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Start  Embroidery HW 1'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Start  Embroidery HW 2'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Start  Embroidery HW 3'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Start  Embroidery HW 4'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'Start  Embroidery HW 5'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'Start  Embroidery HW 6'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'Start  Embroidery HW 7'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'Start  Embroidery HW 8'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_09    WITH(NOLOCK) ON MO.WorkFlowID = WT_09.WorkFlowID    AND WT_09.TaskName  = 'Start  Embroidery HW 9'
			LEFT JOIN LCA.dbo.WorkTasks     AS WT_10    WITH(NOLOCK) ON MO.WorkFlowID = WT_10.WorkFlowID    AND WT_10.TaskName  = 'Start  Embroidery HW 10'

			-------------- INSERT FINAL CON LAS MO A UTILIZAR Y LA INFORMACION NECESARIA PARA EL REPORTE FINAL ----------------

			SELECT
				[ManufactureID]	= MO.ManufactureID
				,[MO]				= MO.ManufactureNumber
				,[PONumber]			= OD.PONumber
				-- ,[CustomerOrder] 	= SUBSTRING(OD.[Comments6], 1, 9)
				,[CustomerOrder] 	= OD.[Comments6]
				,[CustomerName]		= OD.Comments4
				,[Style]			= ST.StyleNumber
				,[Color]			= STC.StyleColorName
				,[Make]				= MO.QuantityOrdered
				,[ProductDivision]	= ST.Comments9
				,[RequiredDate]		= OD.RequiredDate
				,[Status/Date]		= OD.Comments5
				,[ItemDetailID]     = CASE 
										WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
											NULL
										WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
											cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT) 
										WHEN ( od.[PONumber] LIKE 'ORD%') and (ISNUMERIC(od.Comments6) = 1 ) THEN
											cast(od.[Comments6] AS BIGINT)
										ELSE
											NULL 
										END
				,[ProductionStatus] = DDV.DropDownValue
				,[ProcessFinish]	= IIF([EmbAPPFinish] = 1 OR [EmbHWFinish] = 1,1,0)
				,[EmbAPP]			= [EmbAPP]
				,[EmbHW]			= [EmbHW]
			INTO #TB_MO
			--select *
			FROM #TB_MO_FILTER									AS MOF
			INNER JOIN      LCA.dbo.ManufactureOrders           AS MO   WITH(NOLOCK) ON MO.ManufactureID 			= MOF.ManufactureID 
			INNER JOIN      LCA.dbo.OrderItems                  AS OI   WITH(NOLOCK) ON OI.OrderItemID      		= MO.FirstOrderItemID
			INNER JOIN      LCA.dbo.Orders                      AS OD   WITH(NOLOCK) ON OD.OrderID          		= OI.OrderID              AND OD.StatusID < 90      --AND OD.Comments5 LIKE '%RFP%'
			INNER JOIN      LCA.dbo.Styles                      AS ST   WITH(NOLOCK) ON ST.StyleID          		= OI.StyleID
			INNER JOIN      LCA.dbo.StyleColors                 AS STC  WITH(NOLOCK) ON STC.StyleColorID    		= OI.StyleColorID
			LEFT  JOIN      LCA.dbo.DropDownValues3             AS DDV  WITH(NOLOCK) ON MO.ProductionStatusID    	= DDV.DropDownValueID

			SELECT
				app.*
			INTO #L2_Applique
			FROM #TB_MO AS TMO
			INNER JOIN [192.168.1.93].AppsLCA.legacycaps.VW_view_LCA_Applique AS APP WITH(NOLOCK) ON TMO.ItemDetailID = APP.ItemDetailID
			

			--- ACTUALIZAR ORDENES DE BORDADO QUE NO TIENEN WORKFLOW CORRECTO ---
			UPDATE MO SET
				MO.EmbAPP = IIF(MO.ProductDivision = 'Apparel',1,0)
				,MO.EmbHW  = IIF(MO.ProductDivision = 'Headwear',1,0)
			FROM #TB_MO AS MO
			INNER JOIN
			(	
				SELECT DISTINCT
					ManufactureID
					,OrderTypeDescription
				FROM
				(
					SELECT A.ManufactureID,A.LogoStyle, MDB.OrderTypeDescription
					FROM
					(
						SELECT DISTINCT MO.ManufactureID,MO.ItemDetailID,APP.LogoStyle
						FROM #TB_MO AS MO
						INNER JOIN #L2_Applique AS APP ON MO.ItemDetailID = APP.ItemDetailID AND EmbAPP = 0 AND EmbHW = 0
					) AS A
					INNER JOIN OPENQUERY([MARIADB],'SELECT LogoStyle, OrderTypeDescription FROM wordpress.L2Brands_LogoStyle') AS MDB ON A.LogoStyle = MDB.LogoStyle AND MDB.OrderTypeDescription LIKE '%Embroidery%'
				) AS B
			) AS EMB ON MO.ManufactureID = EMB.ManufactureID


			--- ELIMINAMOS LAS QUE NO SEAN ÓRDENES DE BORDADO ---

			DELETE FROM #TB_MO_FILTER 
			WHERE NOT(EmbHW =1 OR EmbAPP =1)

			DELETE FROM #TB_MO
			WHERE NOT(EmbHW =1 OR EmbAPP =1)

		/********************************* FILTER MO STATUS < 90 Y UPDATES PARA EXTRAER ORDENES DE BORDADO Y SABER SI YA FINALIZARON EL PROCESO O NO *******************************/
		
		
		IF @process = 'report-general' OR @process = 'pivot-thread'
		BEGIN

			/******************************************* Obteniendo info de los hilos y appliques por ItemDetailID, Location y Color de Hilo *******************************************/
				--- INSERT PARA INFO DE DIGITIZING ---
				
				SELECT
					*
				INTO #L2_DigitizingInfo
				FROM [192.168.1.93].AppsLCA.legacycaps.VW_view_LCA_Digitizing AS D WITH(NOLOCK)
				
				DELETE FROM #L2_DigitizingInfo
				WHERE ItemDetailID NOT IN (SELECT DISTINCT ItemDetailID FROM #TB_MO)

				--- INFORMACION DE HILOS EN TABLA AppsLCA.legacycaps.VW_view_LCA_DesignColors EN EL SERVER 93, SE ACTUALIZA CADA 6 HORAS ---

				SELECT DISTINCT
					DC.ItemDetailID
					,SKUID
					,EmbType
					,[Location]
					,LogoStyle
					,LogoStyleName
					,StitchCount
					,ColorSpoolID
					,ColorName
					,IIF(CHARINDEX('Poly',ColorName) > 0, RTRIM(SUBSTRING(ColorName,1,CHARINDEX('Poly',ColorName) -1)), ColorName) AS ColorShort --- EXTRAIGO SOLO UNA PARTE DEL COLOR, NECESARIO PARA LOS UPDATE
					,CAST(NULL AS INT)				AS StitchCountPerThread
					,CAST(NULL AS INT)				AS CountApplique
					,CAST(NULL AS INT)				AS CountSpoolID
					,CAST(NULL AS decimal(10,2))	AS TotalYards
					,CAST(NULL AS decimal(10,2))	AS TotalYardsNeedle
					,CAST(NULL AS decimal(10,2))	AS TotalYardsBobine
				INTO #L2_ThreadInfo
				FROM [192.168.1.93].AppsLCA.legacycaps.VW_view_LCA_DesignColors AS DC WITH(NOLOCK)
				WHERE ItemDetailID IN (SELECT DISTINCT ItemDetailID FROM #TB_MO)

				--- INFORMACION DEL TOTAL DE HILOS EN SEQUENCIA POR ORDEN Y LOCALIDAD ---

				SELECT
					*
					,ROW_NUMBER() OVER(PARTITION BY DI.ItemDetailID, DI.EmbType, DI.Location ORDER BY DI.ItemDetailID, DI.EmbType, DI.Location) AS R_Thread
					,ROW_NUMBER() OVER(PARTITION BY DI.ItemDetailID, DI.EmbType, DI.Location, DI.ThreadID ORDER BY DI.ItemDetailID, DI.EmbType, DI.Location, DI.ThreadID) AS R_ThreadColor
					,CAST(NULL AS decimal(10,4)) AS TotalThread
					,CAST(NULL AS decimal(10,4)) AS TotalThreadColor
					,CAST(NULL AS decimal(10,4)) AS Proportion
				INTO #L2_TotalThreadPerWO
				FROM
				(
					SELECT
							DI.ItemDetailID AS ItemDetailID
						,DI.EmbType AS EmbType
						,DI.[Location] AS [Location]
						,DI.SequenceNo AS SequenceNo
						,DI.SpoolID AS ThreadID
						,DI.Color AS ThreadColor
						,DC.StitchCount AS StitichCount
					FROM #L2_DigitizingInfo AS DI --27654
					INNER JOIN 
					(
						SELECT 
							ItemDetailID
							,[Location]
							,StitchCount
						FROM #L2_ThreadInfo
						-- WHERE ItemDetailID = 6046572
						GROUP BY
							ItemDetailID
							,[Location]
							,StitchCount
					) AS DC ON DI.ItemDetailID = DC.ItemDetailID AND DI.[Location] = DC.[Location]
					WHERE DI.SpoolID IS NOT NULL
				) AS DI

				UPDATE L2 SET
					TotalThread = L2_MaxThread.TotalThread
					,TotalThreadColor = L2_MaxColor.TotalThreadColor
					--SELECT *
				FROM #L2_TotalThreadPerWO AS L2
				INNER JOIN
				(
					SELECT
						ItemDetailID
						,EmbType
						,[Location]
						,MAX(R_Thread) AS TotalThread
					FROM #L2_TotalThreadPerWO
					-- WHERE ItemDetailID = 6046572
					GROUP BY
						ItemDetailID
						,EmbType
						,[Location]
				) AS L2_MaxThread ON L2.ItemDetailID = L2_MaxThread.ItemDetailID AND L2.[Location] = L2_MaxThread.[Location]
				INNER JOIN
				(
					SELECT
						ItemDetailID
						,EmbType
						,[Location]
						,ThreadID
						,MAX(R_ThreadColor) AS TotalThreadColor
					FROM #L2_TotalThreadPerWO
					GROUP BY
						ItemDetailID
						,EmbType
						,[Location]
						,ThreadID
				) AS L2_MaxColor ON L2.ItemDetailID = L2_MaxColor.ItemDetailID AND L2.[Location] = L2_MaxColor.[Location] AND L2.ThreadID = L2_MaxColor.ThreadID

				UPDATE L2 SET
					Proportion = ROUND(TotalThreadColor / TotalThread,4)
				FROM #L2_TotalThreadPerWO AS L2

				--- PRIMER UPDATE: SE OBTIENE LAS PUNTADAS POR HILO (Proporción determianda por la cantidad de puntadas divida entre la cantidad de hilos por ItemDetailID y Location) DESDE TABLA #L2_ThreadInfo ---
				--- ADEMÁS SE OBTIENE CÚANTOS APPLIQUE POR ItemDetailID y Location HAY DESDE TABLA [192.168.1.93].AppsLCA.legacycaps.VW_view_LCA_Applique --- 

				UPDATE DC SET
				DC.StitchCountPerThread = ROUND((TT.NewStitchPerThread),0)
				,DC.CountApplique			 	 = CA.CountApp
				,DC.CountSpoolID		 		 = CT.CountSpool
				--select *
				FROM #L2_ThreadInfo AS DC
				INNER JOIN
				(
					SELECT 
						ItemDetailID
						,[Location]
						,COUNT(DISTINCT ColorSpoolID) AS CountSpool
					FROM #L2_ThreadInfo
					GROUP BY ItemDetailID,[Location]
				) AS CT ON DC.ItemDetailID = CT.ItemDetailID AND DC.[Location] = ct.[Location]
				INNER JOIN
				(
					SELECT DISTINCT
						ItemDetailID
						,[Location]
						,MAX(CountApp) AS CountApp
					FROM 
					(
						SELECT 
							APP.ItemDetailID
							,[Location]
							,IIF(AppliqueMaterial IS NOT NULL, ROW_NUMBER() OVER(PARTITION BY APP.ItemDetailID,[Location] ORDER BY APP.ItemDetailID), 0) AS CountApp
						FROM (SELECT DISTINCT ItemDetailID FROM #TB_MO) AS MO
						INNER JOIN #L2_Applique AS APP ON MO.ItemDetailID = APP.ItemDetailID
						-- AND mo.ItemDetailID = 6046572
					) AS TB
					GROUP BY 
						ItemDetailID
						,[Location]
				) AS CA ON DC.ItemDetailID = CA.ItemDetailID AND DC.[Location] = CA.[Location]
				INNER JOIN
				(
					SELECT
						ItemDetailID
						,EmbType
						,[Location]
						,ThreadID
						,ThreadColor
						,StitichCount
						,Proportion
						,CAST(ROUND(StitichCount * Proportion,0) AS INT) AS NewStitchPerThread
					FROM #L2_TotalThreadPerWO
					-- WHERE ItemDetailID = 6046572
					GROUP BY
						ItemDetailID
						,EmbType
						,[Location]
						,ThreadID
						,ThreadColor
						,StitichCount
						,Proportion
				) AS TT ON DC.ItemDetailID = TT.ItemDetailID AND DC.[Location] = TT.[Location] AND DC.ColorSpoolID = TT.ThreadID


				--- SEGUNDO UPDATE: A PARTIR DE UNA SERIE DE FÓRMULAS, SE OBTIENE LA CANTIDAD DE YARDAS POR HILO, EL CALCULO CAMBIA DEPENDIENDO DE SI LA ORDEN TIENE APPLIQUE O NO ---

				UPDATE DC SET
					DC.TotalYards			 = TY.TotalYardsPerThread
					,DC.TotalYardsNeedle	 = TY.TotalYardsNeedle
					,DC.TotalYardsBobine	 = TY.TotalYardsBobine
				FROM #L2_ThreadInfo AS DC
				INNER JOIN
				(
					SELECT DISTINCT
					ItemDetailID
					,[Location]
					,ColorSpoolID
					,CAST(ROUND(TotalWithWaste,2) AS decimal(10,2)) AS TotalYardsPerThread
					,CAST(ROUND(TotalWithWaste * 0.55,2) AS decimal(10,2)) AS TotalYardsNeedle
					,CAST(ROUND(TotalWithWaste * 0.45,2) AS decimal(10,2)) AS TotalYardsBobine
					FROM
					(
						SELECT
							*
							,IIF(SLI > 0,((SLI/36)*(2+2*((1.8/25.4)*7)))*1,0) AS TotalYardsOp
							,(IIF(SLI > 0,((SLI/36)*(2+2*((1.8/25.4)*7)))*1,0)) * 0.05 AS YardsWaste
							,(IIF(SLI > 0,((SLI/36)*(2+2*((1.8/25.4)*7)))*1,0)) + ((IIF(SLI > 0,((SLI/36)*(2+2*((1.8/25.4)*7)))*1,0)) * 0.05) AS TotalWithWaste
						FROM
						(
							SELECT 
								*
								,IIF(CountApplique = 0,5.5,3.5) AS PromedioPuntada
								,((StitchCountPerThread * IIF(CountApplique = 0,5.5,3.5))/1000) * 39.370079 AS SLI
							FROM #L2_ThreadInfo
						) AS TB
					) AS TB2
				) AS TY ON DC.ItemDetailID = TY.ItemDetailID AND DC.[Location] = TY.[Location] AND DC.[ColorSpoolID] = TY.ColorSpoolID


				------------------------------------------------------------------ INVENTARIO DE HILOS EN LCA --------------------------------------------------------------------------

					SELECT
						 [Qty]			= SUM(Qty)	
						,[StockMinimo]	= StockMinimo
						,[ThreadID]		= ThreadID
						,[UnitMeasure]	= UnitMeasure
						,[PartNumbers]	= STRING_AGG(COALESCE([Part Number LCA],''),',') WITHIN GROUP (ORDER BY [RawMaterialID])

					INTO #TB_InventoryThread
					FROM
					(
						SELECT
							 [Qty]				= SUM(RC.[QuantityOnHand])
							,[StockMinimo]		= PP.[Stock Minimo]
							,[ThreadID]			= PP.[ThreadID L2]
							,[UnitMeasure]		= UN.[UnitName]
							,[Part Number LCA]	= PP.[Part Number LCA]
							,[RawMaterialID]	= PP.[RawMaterialID]
							-- ,C.[ColorName]
						FROM [LCA].[dbo].[RawContainers]						AS RC WITH(NOLOCK)
						INNER JOIN [LCA].[dbo].[RawMaterials] 					AS RM WITH(NOLOCK)	ON RC.[RawMaterialID] = RM.[RawMaterialID] 
																									AND RC.[StockWarehouseID] IN (50,55)
																									AND RC.[StatusID] < 90 
																									AND RC.[ContainerCode] <> '<Default>' 
																									AND RC.[QuantityOnHand] > 0
						INNER JOIN [LCA].[dbo].[Colors]							AS C  WITH(NOLOCK) ON RM.[ColorID] = C.[ColorID]
						INNER JOIN [LCA].[dbo].[ComponentLibrary]				AS CL WITH(NOLOCK) ON RM.[ComponentID] = CL.[ComponentID]
						INNER JOIN [LCA].[dbo].[ComponentCategories]			AS CC WITH(NOLOCK) ON CL.[ComponentCategoryID] = CC.[ComponentCategoryID] AND CC.[CategoryName] = 'Thread'
						INNER JOIN [LCA].[dbo].[UnitNames]						AS UN WITH(NOLOCK) ON CL.[DatabaseUnitID] = UN.[UnitNameID]
						INNER JOIN [AppsLCA].[dbo].[Planning_PartNumber_L2]		AS PP WITH(NOLOCK) ON RM.[RawMaterialID] = PP.[RawMaterialID]
						GROUP BY
							
							PP.[Stock Minimo]
							,PP.[ThreadID L2]
							,UN.[UnitName]
							,PP.[Part Number LCA]
							,PP.[RawMaterialID]
					) AS TB
					GROUP BY
						 [StockMinimo]
						,[ThreadID]
						,[UnitMeasure]

				------------------------------------------------------------------ INVENTARIO DE HILOS EN LCA --------------------------------------------------------------------------

			------------------- INSERT FINAL EN #TB_MO_CONSUMPTION CON LA INFO DE LAS MO Y EL CONSUMO DE HILO POR QTY y COLOR DE HILO -------------------
			
			SELECT 
				MO.ManufactureID
				,MO.MO
				,MO.ProductionStatus
				,MO.PONumber AS WorkOrder
				,MO.ItemDetailID
				,MO.[CustomerName]
				,MO.CustomerOrder
				,MO.Style
				,MO.Color
				,MO.Make AS Qty
				,MO.ProductDivision
				,MO.RequiredDate
				,MO.[Status/Date]
				,MO.ProcessFinish
				,MO.EmbAPP
				,MO.EmbHW
				,TI.SKUID
				,TI.EmbType
				,TI.[Location]
				,TI.LogoStyle
				,TI.LogoStyleName
				,TI.ColorSpoolID 	AS ThreadID
				,TI.ColorName		AS ThreadColor
				,TI.StitchCount
				,TI.StitchCountPerThread
				,TI.TotalYards AS TotalYardsPerUnit
				,TI.TotalYardsNeedle AS TotalYardsNeedlePerUnit
				,TI.TotalYardsBobine AS TotalYardsBobinePerUnit
				,ROUND(TI.TotalYards * Make,2) AS TotalYardsPerQty
				,ROUND(TI.TotalYardsNeedle * Make,2) AS TotalYardsNeedlePerQty
				,ROUND(TI.TotalYardsBobine * Make,2) AS TotalYardsBobinePerQty
				,COALESCE(IT.StockMinimo,0) AS StockMinimo
				,COALESCE(IT.Qty,0) AS Inventory_OnHand
				,COALESCE(IT.UnitMeasure,'') AS UnitMeasure
				,COALESCE(IT.PartNumbers,'') AS PartNumbers
				,TI.CountApplique
			INTO #TB_MO_CONSUMPTION
			FROM #TB_MO AS MO
			INNER JOIN #L2_ThreadInfo AS TI ON MO.ItemDetailID = TI.ItemDetailID
			LEFT JOIN #TB_InventoryThread AS IT ON TI.ColorSpoolID = IT.ThreadID
			-- WHERE MO.EmbAPP = 1 AND ProcessFinish = 0
			ORDER BY MO.ItemDetailID,MO.MO,TI.[Location]


		/******************************************* Obteniendo info de los hilos y appliques por ItemDetailID, Location y Color de Hilo *******************************************/

		/************************************************* Obteniendo info del Digitizing (Design, Sequence, Comment por Sequence) *************************************************/

			--- JUNTAMOS LA INFO DE DIGITIZING CON LAS MO, ASÍ OBTENEMOS UNA RELACIÓN MÁS EXACTA POR MANUFACTUREID ---

			SELECT
				MO.ManufactureID
				,MO.MO
				,MO.ProductionStatus
				,MO.PONumber AS WorkOrder
				,MO.[CustomerName]
				,MO.CustomerOrder
				,MO.Style
				,MO.Color
				,MO.Make AS Qty
				,MO.ProductDivision
				,MO.RequiredDate
				,MO.[Status/Date]
				,MO.ProcessFinish
				,MO.EmbAPP
				,MO.EmbHW
				,DI.ItemDetailID
				,DI.SKUID
				,DI.[Location]
				,DI.EmbType
				,DI.Design
				,DI.DigitizingID
				,DI.SequenceNo
				,DI.Comment
				,DI.SpoolID
			INTO #TB_MO_DIGITIZING
			FROM #TB_MO AS MO
			INNER JOIN #L2_DigitizingInfo AS DI ON MO.ItemDetailID = DI.ItemDetailID
			-- WHERE MO.EmbAPP = 1 AND ProcessFinish = 0

			--- CONSULTA FINAL E INSERT EN #TB_RESPONSE PARA MOSTRAR AL USUARIO

			SELECT 
				ROW_NUMBER() OVER(ORDER BY CAST(CAST(MOC.RequiredDate AS DATE) AS VARCHAR(100)),MOC.ItemDetailID, MOC.MO, MOC.EmbType, DI.SequenceNo, MOC.[Location]) AS R
				,IIF(DI.Comment LIKE '%tackdown%' OR DI.Comment LIKE '%TACK DOWN%' OR DI.Comment LIKE '%tac down%' OR DI.Comment LIKE '%TAKCDOWN%' OR DI.Comment LIKE '%TACK DWON%',1,0) AS TackDown
				,MOC.MO
				,MOC.ProductionStatus
				,MOC.WorkOrder
				,MOC.ItemDetailID
				,MOC.[CustomerName]
				,MOC.CustomerOrder
				,MOC.Style
				,MOC.Color
				,MOC.Qty
				,MOC.ProductDivision
				,CAST(CAST(MOC.RequiredDate AS DATE) AS VARCHAR(100)) AS [Req Ship]
				,MOC.[Status/Date]
				,MOC.SKUID
				,COALESCE(MOC.EmbType,DI.EmbType) AS EmbType
				,COALESCE(MOC.[Location],DI.[Location]) AS [Location]
				,DI.Design
				,DI.SequenceNo
				,DI.Comment
				-- ,COALESCE(MOC.LogoStyle,MOC2.LogoStyle,'-') AS LogoStyle
				-- ,COALESCE(MOC.LogoStyleName,MOC2.LogoStyleName,'-') AS LogoStyleName
				-- ,COALESCE(MOC.ThreadID,MOC2.ThreadID,'-') AS ThreadID
				-- ,COALESCE(MOC.ThreadColor,MOC2.ThreadColor,'-') AS ThreadColor
				-- ,COALESCE(MOC.StitchCount,MOC2.StitchCount,0) AS StitchCount
				-- ,COALESCE(MOC.StitchCountPerThread,MOC2.StitchCountPerThread,0) AS StitchCountPerThread
				-- ,COALESCE(MOC.TotalYardsNeedlePerUnit,MOC2.TotalYardsNeedlePerUnit,0) AS TotalYardsNeedlePerUnit
				-- ,COALESCE(MOC.TotalYardsBobinePerUnit,MOC2.TotalYardsBobinePerUnit,0) AS TotalYardsBobinePerUnit
				-- ,COALESCE(MOC.TotalYardsPerUnit,MOC2.TotalYardsPerUnit,0) AS TotalYardsPerUnit
				-- ,COALESCE(MOC.TotalYardsNeedlePerQty,MOC2.TotalYardsNeedlePerQty,0) AS TotalYardsNeedlePerQty
				-- ,COALESCE(MOC.TotalYardsBobinePerQty,MOC2.TotalYardsBobinePerQty,0) AS TotalYardsBobinePerQty
				-- ,COALESCE(MOC.TotalYardsPerQty,MOC2.TotalYardsPerQty,0) AS TotalYardsPerQty
				-- ,COALESCE(MOC.StockMinimo,MOC2.StockMinimo,0) AS StockMinimo
				,MOC.LogoStyle AS LogoStyle
				,MOC.LogoStyleName AS LogoStyleName
				,MOC.ThreadID AS ThreadID
				,MOC.ThreadColor AS ThreadColor
				,MOC.StitchCount AS StitchCount
				,MOC.StitchCountPerThread AS StitchCountPerThread
				,MOC.TotalYardsNeedlePerUnit AS TotalYardsNeedlePerUnit
				,MOC.TotalYardsBobinePerUnit AS TotalYardsBobinePerUnit
				,MOC.TotalYardsPerUnit AS TotalYardsPerUnit
				,MOC.TotalYardsNeedlePerQty AS TotalYardsNeedlePerQty
				,MOC.TotalYardsBobinePerQty AS TotalYardsBobinePerQty
				,MOC.TotalYardsPerQty AS TotalYardsPerQty
				,MOC.StockMinimo AS StockMinimo
				,MOC.Inventory_OnHand AS Inventory_OnHand
				,MOC.UnitMeasure
				,MOC.PartNumbers
				
			INTO #TB_RESPONSE
			-- SELECT COUNT(*)
			FROM #TB_MO_CONSUMPTION AS MOC
			LEFT JOIN #TB_MO_DIGITIZING  AS DI  ON DI.ManufactureID = MOC.ManufactureID AND DI.[Location] = MOC.[Location] AND DI.SpoolID = MOC.ThreadID
			-- LEFT JOIN #TB_MO_CONSUMPTION AS MOC2 ON DI.ManufactureID = MOC2.ManufactureID AND DI.[Location] = MOC2.[Location] AND MOC.ManufactureID IS NULL AND DI.SpoolID IS NOT NULL
			WHERE 
			-- 	DI.EmbAPP = 1 
			-- AND 
				DI.ProcessFinish = 0
				-- or DI.ItemDetailID = 5167504
			ORDER BY MOC.ItemDetailID, MOC.MO, MOC.EmbType, DI.SequenceNo, MOC.[Location]

			
		--- SELECT FINAL ---
		IF @process = 'report-general'
		BEGIN
			SET @result =
			(
				SELECT
					MO
					,ProductionStatus
					,WorkOrder
					,TRIM(REPLACE(REPLACE(REPLACE(CustomerName, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) as CustomerName
					,CustomerOrder
					,Style
					,Color
					,Qty
					,TRIM(REPLACE(REPLACE(REPLACE(ProductDivision, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS ProductDivision
					,[Req Ship]
					,DATEPART(WEEK, CAST([Req Ship] AS DATE)) AS [Week Req Ship]
					,DATEPART(YEAR, CAST([Req Ship] AS DATE)) AS [Year Req Ship]
					,TRIM(REPLACE(REPLACE(REPLACE([Status/Date], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS [Status/Date]
					,SKUID
					,EmbType
					,[Location]
					,Design
					,SequenceNo
					,Comment
					,LogoStyle
					,LogoStyleName
					,ThreadID
					,ThreadColor
					,PartNumbers AS [LCA PartNumber]
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,StitchCount, 0) AS StitchCount
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,StitchCountPerThread, 0) AS StitchCountPerThread
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,CAST(TotalYardsNeedlePerUnit / 5000 AS DECIMAL(18,5)), 0.00) AS [Poly Thread Colors Demand]
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,CAST(TotalYardsBobinePerUnit / 3000 AS DECIMAL(18,5)), 0.00) AS [Bobine Thread Demand]
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,TotalYardsNeedlePerUnit, 0.00) AS UnitYardConsumptionNeedle
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,TotalYardsBobinePerUnit, 0.00) AS UnitYardConsumptionBobine
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,TotalYardsPerUnit, 0.00) AS UnitYardConsumption
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,CAST(TotalYardsNeedlePerQty / 5000 AS DECIMAL(18,5)), 0.00) AS [Total Poly Thread Colors Demand]
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,CAST(TotalYardsBobinePerQty / 3000 AS DECIMAL(18,5)), 0.00) AS [Total Bobine Thread Demand]
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,TotalYardsNeedlePerQty, 0.00) AS TotalYardNeedlePerQty
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,TotalYardsBobinePerQty, 0.00) AS TotalYardBobinePerQty
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,TotalYardsPerQty, 0.00) AS TotalYardsPerQty
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,StockMinimo, 0.00) AS [Minimum Stock]
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,Inventory_OnHand, 0.00) AS [Inventory OnHand]
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,UnitMeasure, '') AS [Unit of Measure]
					,IIF(IIF(FirstThread = 1 AND ThreadID IS NOT NULL,Inventory_OnHand, 0.00) 
							<= IIF(FirstThread = 1 AND ThreadID IS NOT NULL,StockMinimo, 0.00)
							AND IIF(FirstThread = 1 AND ThreadID IS NOT NULL,StockMinimo, 0.00) <> 0.00, 1,0) AS Rev_Inventory
				FROM
				(
					SELECT 
						R
						,MO
						,ProductionStatus
						,WorkOrder
						,CustomerName
						,CustomerOrder
						,Style
						,Color
						,Qty
						,ProductDivision
						,[Req Ship]
						,[Status/Date]
						,SKUID
						,EmbType
						,[Location]
						,Design
						,SequenceNo
						,Comment
						,LogoStyle
						,LogoStyleName
						,ROW_NUMBER() OVER(PARTITION BY MO,[Location],ThreadColor order by MO,SequenceNo,[Location],ThreadColor) AS FirstThread
						,TackDown
						,ThreadID
						,ThreadColor
						,PartNumbers
						,StitchCount
						,StitchCountPerThread
						,TotalYardsNeedlePerUnit
						,TotalYardsBobinePerUnit
						,TotalYardsPerUnit
						,TotalYardsNeedlePerQty
						,TotalYardsBobinePerQty
						,TotalYardsPerQty
						,StockMinimo
						,Inventory_OnHand
						,UnitMeasure
					FROM #TB_RESPONSE
					-- WHERE ThreadID = '80114'
				) AS F
				-- WHERE WorkOrder = 'ORD-5255453'
				-- WHERE WorkOrder ='ORD-5666226'
				ORDER BY R--, FirstThread
				FOR JSON PATH, INCLUDE_NULL_VALUES
			)
		END

		IF @process = 'pivot-thread'
		BEGIN
			SET @result =
			(
				SELECT
					MO
					,ProductionStatus
					,WorkOrder
					,TRIM(REPLACE(REPLACE(REPLACE(CustomerName, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) as CustomerName
					,CustomerOrder
					,Style
					,Color
					,Qty
					,TRIM(REPLACE(REPLACE(REPLACE(ProductDivision, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS ProductDivision
					,[Req Ship]
					,DATEPART(WEEK, CAST([Req Ship] AS DATE)) AS [Week Req Ship]
					,DATEPART(YEAR, CAST([Req Ship] AS DATE)) AS [Year Req Ship]
					,TRIM(REPLACE(REPLACE(REPLACE([Status/Date], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS [Status/Date]
					,SKUID
					,EmbType
					,[Location]
					,Design
					,SequenceNo
					,Comment
					,LogoStyle
					,LogoStyleName
					,ThreadID
					,ThreadColor
					,PartNumbers AS [LCA PartNumber]
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,StitchCount, 0) AS StitchCount
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,StitchCountPerThread, 0) AS StitchCountPerThread
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,CAST(TotalYardsNeedlePerUnit / 5000 AS DECIMAL(18,5)), 0.00) AS [Poly Thread Colors Demand]
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,CAST(TotalYardsBobinePerUnit / 3000 AS DECIMAL(18,5)), 0.00) AS [Bobine Thread Demand]
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,TotalYardsNeedlePerUnit, 0.00) AS UnitYardConsumptionNeedle
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,TotalYardsBobinePerUnit, 0.00) AS UnitYardConsumptionBobine
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,TotalYardsPerUnit, 0.00) AS UnitYardConsumption
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,CAST(TotalYardsNeedlePerQty / 5000 AS DECIMAL(18,5)), 0.00) AS [Total Poly Thread Colors Demand]
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,CAST(TotalYardsBobinePerQty / 3000 AS DECIMAL(18,5)), 0.00) AS [Total Bobine Thread Demand]
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,TotalYardsNeedlePerQty, 0.00) AS TotalYardNeedlePerQty
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,TotalYardsBobinePerQty, 0.00) AS TotalYardBobinePerQty
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,TotalYardsPerQty, 0.00) AS TotalYardsPerQty
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,StockMinimo, 0.00) AS [Minimum Stock]
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,Inventory_OnHand, 0.00) AS [Inventory OnHand]
					,IIF(FirstThread = 1 AND ThreadID IS NOT NULL,UnitMeasure, '') AS [Unit of Measure]
					,IIF(IIF(FirstThread = 1 AND ThreadID IS NOT NULL,Inventory_OnHand, 0.00) 
							<= IIF(FirstThread = 1 AND ThreadID IS NOT NULL,StockMinimo, 0.00)
							AND IIF(FirstThread = 1 AND ThreadID IS NOT NULL,StockMinimo, 0.00) <> 0.00, 1,0) AS Rev_Inventory
				FROM
				(
					SELECT 
						R
						,MO
						,ProductionStatus
						,WorkOrder
						,CustomerName
						,CustomerOrder
						,Style
						,Color
						,Qty
						,ProductDivision
						,[Req Ship]
						,[Status/Date]
						,SKUID
						,EmbType
						,[Location]
						,Design
						,SequenceNo
						,Comment
						,LogoStyle
						,LogoStyleName
						,ROW_NUMBER() OVER(PARTITION BY MO,[Location],ThreadColor order by MO,SequenceNo,[Location],ThreadColor) AS FirstThread
						,TackDown
						,ThreadID
						,ThreadColor
						,PartNumbers
						,StitchCount
						,StitchCountPerThread
						,TotalYardsNeedlePerUnit
						,TotalYardsBobinePerUnit
						,TotalYardsPerUnit
						,TotalYardsNeedlePerQty
						,TotalYardsBobinePerQty
						,TotalYardsPerQty
						,StockMinimo
						,Inventory_OnHand
						,UnitMeasure
					FROM #TB_RESPONSE
					-- WHERE ThreadID = '80114'
				) AS F
				-- WHERE WorkOrder = 'ORD-5255453'
				-- WHERE WorkOrder ='ORD-5666226'
				WHERE IIF(FirstThread = 1 AND ThreadID IS NOT NULL,TotalYardsPerQty, 0.00) > 0
				ORDER BY R, Rev_Inventory--, FirstThread
				FOR JSON PATH, INCLUDE_NULL_VALUES
			)
		END

		SET @Error = 0
		SET @Component = '[200]'
		SET @message = 'Datos Generados correctamente'

		END -- IF @process = 'report-general'

		IF @process = 'applique-consumption'
		BEGIN

			--- INFORMACION DE HILOS EN TABLA AppsLCA.legacycaps.VW_view_LCA_Applique EN EL SERVER 93, SE ACTUALIZA CADA 6 HORAS ---

				SELECT DISTINCT
					 APP.ItemDetailID
					,SKUID
					,EmbType
					,[Location]
					,LogoStyle
					,LogoStyleName
					,StitchCount
					,DesignNo
					,AppliqueMaterial 	AS AppliqueMaterial
					,AppliqueColor 		AS AppliqueColor
					,AppliqueFilename 	AS AppliqueFilename
					,CAST(NULL AS INT)				AS CountApplique
					,CAST(NULL AS INT)				AS CountAppliquePerThread
				INTO #L2_AppliqueInfo
				FROM (SELECT DISTINCT ItemDetailID FROM #TB_MO) AS MO
				INNER JOIN #L2_Applique AS APP ON MO.ItemDetailID = APP.ItemDetailID
				

			-- PRIMER UPDATE: SE OBTIENE CÚANTOS APPLIQUE POR ItemDetailID y Location HAY DESDE TABLA [192.168.1.93].AppsLCA.legacycaps.VW_view_LCA_Applique --- 

				UPDATE DC SET
					DC.CountApplique			 	 = CA.CountApp
				FROM #L2_AppliqueInfo AS DC
				INNER JOIN
				(
					SELECT DISTINCT
						ItemDetailID
						,[Location]
						,MAX(CountApp) AS CountApp
					FROM 
					(
						SELECT 
							ItemDetailID
							,[Location]
							,IIF(AppliqueMaterial IS NOT NULL, ROW_NUMBER() OVER(PARTITION BY ItemDetailID,[Location] ORDER BY ItemDetailID), 0) AS CountApp
						FROM #L2_Applique AS APP
						WHERE ItemDetailID IN (SELECT DISTINCT ItemDetailID FROM #TB_MO_FILTER)
					) AS TB
					GROUP BY 
						ItemDetailID
						,[Location]
				) AS CA ON DC.ItemDetailID = CA.ItemDetailID AND DC.[Location] = CA.[Location]
			
			--- SEGUNDO UPDATE: SE OBTIENE LA CANTIDAD DE APPLIQUE POR CADA COLOR DE HILO DESDE TABLA [192.168.1.93].AppsLCA.legacycaps.VW_view_LCA_Applique ---

				UPDATE DC SET
					DC.CountAppliquePerThread		 = CAP.CountApp
				--select *
				FROM #L2_AppliqueInfo AS DC
				INNER JOIN
				(
					SELECT DISTINCT
						ItemDetailID
						,[Location]
						,AppliqueColor
						,MAX(CountApp) AS CountApp
					FROM 
					(
						SELECT 
							ItemDetailID
							,[Location]
							,AppliqueColor
							,IIF(AppliqueMaterial IS NOT NULL, ROW_NUMBER() OVER(PARTITION BY ItemDetailID,[Location],AppliqueColor ORDER BY ItemDetailID), 0) AS CountApp
						FROM #L2_Applique AS APP 
						WHERE ItemDetailID IN (SELECT DISTINCT ItemDetailID FROM #TB_MO_FILTER)
						-- AND ItemDetailID in (5244848,5244847)
					) AS TB
					GROUP BY 
						ItemDetailID
						,[Location]
						,AppliqueColor
				) AS CAP ON DC.ItemDetailID = CAP.ItemDetailID AND DC.[Location] = CAP.[Location] AND CAP.AppliqueColor = DC.AppliqueColor

			------------------- INSERT FINAL EN #TB_MO_Applique CON LA INFO DE LAS MO Y LA CANTIDAD DE APPLIQUE POR LOCALIDAD -------------------
		
				SELECT 
					ROW_NUMBER() OVER(ORDER BY MO.ItemDetailID, MO.MO, TI.EmbType, TI.[Location], TI.AppliqueColor) AS R
					,MO.ManufactureID
					,MO.MO
					,MO.ProductionStatus
					,MO.PONumber AS WorkOrder
					,MO.ItemDetailID
					,MO.[CustomerName]
					,MO.CustomerOrder
					,MO.Style
					,MO.Color
					,MO.Make AS Qty
					,MO.ProductDivision
					,MO.RequiredDate
					,MO.[Status/Date]
					,MO.ProcessFinish
					,MO.EmbAPP
					,MO.EmbHW
					,TI.SKUID
					,TI.EmbType
					,TI.[Location]
					,TI.LogoStyle
					,TI.LogoStyleName
					,TI.StitchCount
					,TI.AppliqueFilename
					,TI.AppliqueMaterial
					,TI.AppliqueColor
					,COALESCE(TI.CountAppliquePerThread,0) AS AppliquePerUnit
					,ROUND(COALESCE(TI.CountAppliquePerThread,0) * MO.Make,2) AS TotalAppliquePerQty
				INTO #TB_MO_Applique
				FROM #TB_MO AS MO
				INNER JOIN #L2_AppliqueInfo AS TI ON MO.ItemDetailID = TI.ItemDetailID
				-- WHERE MO.EmbAPP = 1 AND ProcessFinish = 0
				ORDER BY MO.ItemDetailID,MO.MO,TI.[Location]

			SET @result =
			(
				SELECT
					 [MO]
					,[ProductionStatus]
					,[WorkOrder]
					-- ,[ItemDetailID]
					,[CustomerName]
					,[CustomerOrder]
					,[Style]
					,[Color]
					,[Qty]
					,[ProductDivision]
					,[RequiredDate] AS [Req Ship]
					,[Status/Date]
					,[SKUID]
					,[EmbType]
					,[Location]
					,[LogoStyle]
					,[LogoStyleName]
					,[StitchCount]
					,[AppliqueFilename]
					,[AppliqueMaterial]
					,[AppliqueColor]
					,[AppliquePerUnit]
					,[TotalAppliquePerQty]
				FROM #TB_MO_Applique
				WHERE [ProcessFinish] = 0 AND (EmbAPP = 1 OR EmbHW = 1)
				ORDER BY R
				FOR JSON PATH, INCLUDE_NULL_VALUES
			)

			SET @Error = 0
			SET @Component = '[200]'
			SET @message = 'Datos Generados correctamente'

		END -- IF @process = 'applique-consumption'

	END TRY
	BEGIN CATCH

		SET @Error = 1
		SET @Component = '[404]'
		SET @message = 'Error in Database, Please Contact IT'
		SET @result = '[]'

	END CATCH

	SELECT
		 [Error]	 	= @Error
		,[Component] 	= @Component
		,[Message]		= @message
		,[Result]		= JSON_QUERY(@result)
	FOR JSON PATH, INCLUDE_NULL_VALUES
	
	return

END