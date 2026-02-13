USE AppsLCA

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_TB_MO_PartNumber_IM_MOProcess] 
AS

BEGIN
SET NOCOUNT ON 

	----------------------------------------------------------------------------------------------------------------
	-------------------------------CREACION TABLA WORKFLOWS---------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------
		PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  CREACION TABLA WORKFLOWS')
		

		DROP TABLE IF EXISTS #TB_WF_EORO
		DROP TABLE IF EXISTS #TB_WF_MO
		DROP TABLE IF EXISTS #TB_LOG_CREATE_MOS

		----TABLA DE DESPACHO POR RO TO EO
		SELECT
				[EO_ID]			= eo.ManufactureID
				,[EO]			= eo.ManufactureNumber
				,[RO_ID]		= mo.ManufactureID
				,[RO]			= mo.ManufactureNumber
				,[UnitsEORO]    = SUM(pit.Quantity)
			INTO #TB_WF_EORO
			FROM  	    LCA.dbo.ManufactureOrders 	    AS mo   WITH(NOLOCK)
			INNER JOIN  LCA.dbo.PackedItems 			AS pit  WITH(NOLOCK) ON mo.ManufactureID 	= pit.ManufactureID
			INNER JOIN  LCA.dbo.ManufactureOrders 	    AS eo   WITH(NOLOCK) ON eo.ManufactureID 	= pit.AttachedManufactureID		AND (eo.ManufactureNumber IS NOT NULL)
			GROUP BY
				eo.ManufactureID
				,eo.ManufactureNumber
				,mo.ManufactureID
				,mo.ManufactureNumber
			HAVING
				SUM(pit.Quantity) > 0

		----TODAS LAS MO ACTIVAS Y COMPLETE
		SELECT
			 [ManufactureID]        = MO.ManufactureID
			,[OrderID]				= MO.OrderID
			,[PONumber]				= OD.PONumber
			,[FirstOrderItemID]		= MO.FirstOrderItemID
			,[MO]                   = MO.ManufactureNumber
			,[Status]               = SN.StatusName
			,[StyleID]              = ST.StyleID
			,[Style]                = ST.StyleNumber
			,[Season]               = SNS.SeasonName
			,[Color]                = SC.StyleColorName
			,[Code]					= CAST(NULL AS VARCHAR(100))
			,[PrintCount]			= CAST(NULL AS INT)
			,[OrderType]			= CAST(NULL AS VARCHAR(100))
			,[PWModulo]             = MO.Comments7
			,[WorkFlowID]           = CAST(NULL AS INT)
			,[WorkFlowName]         = CAST(NULL AS VARCHAR(MAX))
			,[CreateMO]				= CAST(NULL AS DATE)
			,[Cut]                  = CAST(0 AS BIT)
			,[Sew]                  = CAST(0 AS BIT)
			,[ScreenPrint]          = CAST(0 AS BIT)
			,[Sublimation]          = CAST(0 AS BIT)
			,[EmbAPP]               = CAST(0 AS BIT)
			,[EmbHW]                = CAST(0 AS BIT)
			--,[otherApplication]     = CAST(0 AS BIT)
			,[PygmentDye]           = CAST(0 AS BIT)
			,[ExternalLaundry]      = CAST(0 AS BIT)
			,[HDPApplication]      	= CAST(0 AS BIT)
			,[DHTApplication]      	= CAST(0 AS BIT)
			,[SUBApplication]      	= CAST(0 AS BIT)
			,[ReLabel]      		= CAST(0 AS BIT)
			,[SpecialPacking]      	= CAST(0 AS BIT)
			,[HasEmbCode]			= CAST(0 AS BIT)
			,[HasPrintCount]		= CAST(0 AS BIT)
			-- ,[TotalApplication] = CAST(0 AS BIT)
		INTO #TB_WF_MO
		FROM        LCA.dbo.StatusNames         AS SN   WITH(NOLOCK)
		INNER JOIN  LCA.dbo.ManufactureOrders   AS MO   WITH(NOLOCK) ON SN.StatusID             = MO.StatusID       AND SN.StatusID <=90
		INNER JOIN  LCA.dbo.OrderItems          AS OI   WITH(NOLOCK) ON MO.FirstOrderItemID     = OI.OrderItemID
		INNER JOIN  LCA.dbo.Orders   			AS OD   WITH(NOLOCK) ON ISNULL(MO.OrderID,OI.OrderID) 				= OD.OrderID
		INNER JOIN  LCA.dbo.styles              AS ST   WITH(NOLOCK) ON ST.StyleID              = OI.StyleID
		INNER JOIN  LCA.dbo.StyleColors         AS SC   WITH(NOLOCK) ON SC.StyleColorID         = OI.StyleColorID
		LEFT JOIN   LCA.dbo.seasons             AS SNS  WITH(NOLOCK) ON SNS.SeasonID            = ST.SeasonID
		-- WHERE (MO.ManufactureID IN (643507)) OR (MO.ManufactureNumber IN ('4691985-632','EO4582867-MAR','EO4796724-BLFGFL'))


		---Actualizacion de Workflow
		UPDATE MO SET
			[WorkFlowID]       = WF.WorkFlowID
			,[WorkFlowName]     = WF.WorkFlowName
		FROM #TB_WF_MO AS MO
		INNER JOIN LCA.dbo.WorkFlows AS WF WITH (NOLOCK) ON MO.ManufactureID = WF.ManufactureID

		--Actualizacion de Code,PrintCount y OrderType
		UPDATE MO SET
			 [Code] 		= COALESCE(O.Comments26,O2.Comments26)
			,[PrintCount] 	= TRY_CAST(COALESCE(O.Comments14,O2.Comments14,'0') AS INT)
			,[OrderType] 	= COALESCE(DDV.DropDownValue,DDV2.DropDownValue)
		FROM #TB_WF_MO AS MO
		-- INNER JOIN dbo.ManufactureOrders 	AS MO2 	WITH(NOLOCK) ON MO.ManufactureID 	= MO2.ManufactureID
		LEFT  JOIN LCA.dbo.Orders 				AS O 	WITH(NOLOCK) ON MO.OrderID 			= O.OrderID
		LEFT  JOIN LCA.dbo.OrderItems 			AS OI 	WITH(NOLOCK) ON OI.OrderItemID 		= MO.FirstOrderItemID
		LEFT  JOIN LCA.dbo.Orders				AS O2	WITH(NOLOCK) ON OI.OrderID			= O2.OrderID
		LEFT  JOIN LCA.dbo.DropDownValues2		AS DDV	WITH(NOLOCK) ON O.OrderTypeID2		= DDV.DropDownValueID
		LEFT  JOIN LCA.dbo.DropDownValues2		AS DDV2	WITH(NOLOCK) ON O2.OrderTypeID2		= DDV2.DropDownValueID

		--- Actualizacion de CreateMO
		;WITH CTE_CHANGELOG_MO AS (
                    select RecordID,tableID,[ACTION],ChangeDate from LCA.dbo.ChangeLog as cl    WITH(NOLOCK)
                    where  CL.tableID = 30 AND CL.ACTION like 'Create%'
                )
                SELECT
                    [ManufactureID]   = TB.[ManufactureID]
                    ,[CreateMO] = CAST(COD.[CreateMO]    AS DATE) 
                INTO #TB_LOG_CREATE_MOS 
                FROM (SELECT DISTINCT [ManufactureID] FROM #TB_WF_MO) AS TB
                INNER JOIN  (
                                SELECT  
                                    [ManufactureID]   
                                    ,[CreateMO]  
                                FROM(
                                SELECT  
                                         [ManufactureID]      = TB.[ManufactureID]
                                        ,[CreateMO]   = CL.[ChangeDate]
                                        ,[ROW_N]      = ROW_NUMBER() OVER(PARTITION BY TB.ManufactureID
                                                            ORDER BY TB.ManufactureID
                                                            ,CL.ChangeDate DESC)
                                FROM (SELECT DISTINCT [ManufactureID] FROM #TB_WF_MO) AS TB
                                INNER JOIN	CTE_CHANGELOG_MO	AS	CL	WITH(NOLOCK)	ON	TB.ManufactureID = CL.RecordID AND CL.tableID = 30 AND CL.ACTION like 'Create%'
                                -- INNER JOIN	ChangeLog	AS	CL	WITH(NOLOCK)	ON	TB.ManufactureID = CL.RecordID AND CL.tableID = 30 AND CL.ACTION like 'Create%'
                                ) AS TB WHERE TB.ROW_N = 1
                )  AS COD  ON COD.ManufactureID = TB.ManufactureID

                UPDATE S SET
                    [CreateMO] = CMO.[CreateMO]
                FROM #TB_WF_MO AS S
                INNER JOIN  #TB_LOG_CREATE_MOS      AS CMO  ON CMO.ManufactureID = S.ManufactureID

		---Actualizacion en Cutting
		UPDATE MO SET
			[Cut]              =   IIF(WT_01.TaskName   IS NOT NULL, 1, 0) +
									IIF(WT_02.TaskName   IS NOT NULL, 1, 0)
		FROM #TB_WF_MO       AS MO
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_01     WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID     AND WT_01.TaskName   = 'Finish - Cutting'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_02     WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID     AND WT_02.TaskName   = 'Finish  Bundling'
		WHERE MO.Season NOT IN ('EMB FG', 'BLANK FG')


		---Actualizacion en Sewing
		UPDATE MO SET
			[Sew]              =   IIF(WT_01.TaskName   IS NOT NULL, 1, 0) +
									IIF(WT_02.TaskName   IS NOT NULL, 1, 0)
		FROM #TB_WF_MO       AS MO
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_01     WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID     AND WT_01.TaskName   = 'Finish Sewing Process'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_02     WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID     AND WT_02.TaskName   = 'Finish Sewing Assembly'
		WHERE MO.Season NOT IN ('EMB FG', 'BLANK FG')

		---Actualizacion en ScreenPrint
		;WITH ScreenPrintTasks AS (
			SELECT DISTINCT WorkFlowID
			FROM LCA.dbo.WorkTasks WITH(NOLOCK)
			WHERE TaskName LIKE 'Finish Print %'
		)
		UPDATE MO
		SET [ScreenPrint] = 1
		FROM #TB_WF_MO AS MO
		INNER JOIN ScreenPrintTasks AS SPT ON MO.WorkFlowID = SPT.WorkFlowID

		-- UPDATE MO SET
		--      [ScreenPrint]      =   IIF(WT_01.TaskName  IS NOT NULL, 1, 0) +
		--                             IIF(WT_02.TaskName  IS NOT NULL, 1, 0) +
		--                             IIF(WT_03.TaskName  IS NOT NULL, 1, 0) +
		--                             IIF(WT_04.TaskName  IS NOT NULL, 1, 0) +
		--                             IIF(WT_05.TaskName  IS NOT NULL, 1, 0) +
		--                             IIF(WT_06.TaskName  IS NOT NULL, 1, 0) +
		--                             IIF(WT_07.TaskName  IS NOT NULL, 1, 0) +
		--                             IIF(WT_08.TaskName  IS NOT NULL, 1, 0) +
		--                             IIF(WT_09.TaskName  IS NOT NULL, 1, 0) +
		--                             IIF(WT_10.TaskName  IS NOT NULL, 1, 0)

		-- FROM #TB_WF_MO       AS MO
		-- LEFT JOIN dbo.WorkTasks     AS WT_01     WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish Print 1'
		-- LEFT JOIN dbo.WorkTasks     AS WT_02     WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish Print 2'
		-- LEFT JOIN dbo.WorkTasks     AS WT_03     WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish Print 3'
		-- LEFT JOIN dbo.WorkTasks     AS WT_04     WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Finish Print 4'
		-- LEFT JOIN dbo.WorkTasks     AS WT_05     WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'Finish Print 5'
		-- LEFT JOIN dbo.WorkTasks     AS WT_06     WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'Finish Print 6'
		-- LEFT JOIN dbo.WorkTasks     AS WT_07     WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'Finish Print 7'
		-- LEFT JOIN dbo.WorkTasks     AS WT_08     WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'Finish Print 8'
		-- LEFT JOIN dbo.WorkTasks     AS WT_09     WITH(NOLOCK) ON MO.WorkFlowID = WT_09.WorkFlowID    AND WT_09.TaskName  = 'Finish Print 9'
		-- LEFT JOIN dbo.WorkTasks     AS WT_10     WITH(NOLOCK) ON MO.WorkFlowID = WT_10.WorkFlowID    AND WT_10.TaskName  = 'Finish Print 10'


		---Actualizacion en Sublimation
		UPDATE MO SET
			[Sublimation]     =   IIF(WT_01.TaskName IS NOT NULL, 1, 0)
		FROM #TB_WF_MO       AS MO
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_01 WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID AND WT_01.TaskName = 'Finish Sublimation Process'


		---Actualizacion en Embroidery Apparel
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
		FROM #TB_WF_MO       AS MO
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish Embroidery 1'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish Embroidery 2'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish Embroidery 3'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Finish Embroidery 4'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'Finish Embroidery 5'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'Finish Embroidery 6'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'Finish Embroidery 7'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'Finish Embroidery 8'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_09    WITH(NOLOCK) ON MO.WorkFlowID = WT_09.WorkFlowID    AND WT_09.TaskName  = 'Finish Embroidery 9'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_10    WITH(NOLOCK) ON MO.WorkFlowID = WT_10.WorkFlowID    AND WT_10.TaskName  = 'Finish Embroidery 10'

		---Actualizacion en Embroidery HW
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
									IIF(WT_10.TaskName  IS NOT NULL, 1, 0) +
									IIF(WT_11.TaskName  IS NOT NULL, 1, 0) +
									IIF(WT_12.TaskName  IS NOT NULL, 1, 0) +
									IIF(WT_13.TaskName  IS NOT NULL, 1, 0) +
									IIF(WT_14.TaskName  IS NOT NULL, 1, 0) 
		FROM #TB_WF_MO       AS MO
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish Embroidery  HW 1'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish Embroidery  HW 2'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish Embroidery  HW 3'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Finish Embroidery  HW 4'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'Finish Embroidery  HW 5'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'Finish Embroidery  HW 6'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'Finish Embroidery  HW 7'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'Finish Embroidery  HW 8'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_09    WITH(NOLOCK) ON MO.WorkFlowID = WT_09.WorkFlowID    AND WT_09.TaskName  = 'Finish Embroidery  HW 9'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_10    WITH(NOLOCK) ON MO.WorkFlowID = WT_10.WorkFlowID    AND WT_10.TaskName  = 'Finish Embroidery  HW 10'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_11    WITH(NOLOCK) ON MO.WorkFlowID = WT_11.WorkFlowID    AND WT_11.TaskName  = 'Finish Embroidery Post HW 1'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_12    WITH(NOLOCK) ON MO.WorkFlowID = WT_12.WorkFlowID    AND WT_12.TaskName  = 'Finish Embroidery Post HW 2'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_13    WITH(NOLOCK) ON MO.WorkFlowID = WT_13.WorkFlowID    AND WT_13.TaskName  = 'Finish Embroidery Post HW 3'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_14    WITH(NOLOCK) ON MO.WorkFlowID = WT_14.WorkFlowID    AND WT_14.TaskName  = 'Finish Embroidery Post HW 4'

        -- SELECT * FROM dbo.WorkTasks     AS WT_01    WITH(NOLOCK) WHERE WT_01.TaskName  = 'Finish Embroidery  HW 1'
		---Actualizacion en HDP Application
		UPDATE MO SET
			[HDPApplication] =   IIF(WT_01.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_02.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_03.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_04.TaskName IS NOT NULL, 1, 0) 
		FROM #TB_WF_MO       AS MO
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish HDP Application 1'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish HDP Application 2'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish HDP Application 3'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Finish HDP Application 4'

		---Actualizacion en DHT Application
		UPDATE MO SET
			[DHTApplication] =   IIF(WT_01.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_02.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_03.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_04.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_05.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_06.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_07.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_08.TaskName IS NOT NULL, 1, 0) 
		FROM #TB_WF_MO       AS MO
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish DHT Application 1'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish DHT Application 2'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish DHT Application 3'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Finish DHT Application 4'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'DHT Application 1'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'DHT Application 2'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'DHT Application 3'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'DHT Application 4'

		---Actualizacion en SUB Application
		UPDATE MO SET
			[SUBApplication] =   IIF(WT_01.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_02.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_03.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_04.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_05.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_06.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_07.TaskName IS NOT NULL, 1, 0) +
									IIF(WT_08.TaskName IS NOT NULL, 1, 0) 
		FROM #TB_WF_MO       AS MO
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish SUB Application 1'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish SUB Application 2'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish SUB Application 3'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Finish SUB Application 4'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'SUB Application 1'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'SUB Application 2'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'SUB Application 3'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'SUB Application 4'

		---Actualizacion en Re-label
		UPDATE MO SET
			[ReLabel] =   IIF(WT_01.TaskName IS NOT NULL, 1, 0)+
						  IIF(WT_02.TaskName IS NOT NULL, 1, 0)
		FROM #TB_WF_MO       AS MO
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish Re-label'
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish ReLab Type01'


		---Actualizacion en Special Packing
		UPDATE MO SET
			[SpecialPacking] =   IIF(WT_01.TaskName IS NOT NULL, 1, 0)
		FROM #TB_WF_MO       AS MO
		LEFT JOIN LCA.dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Special Packing'
		

		---Actualizacion en Other Application
		-- UPDATE MO SET
		-- 	[otherApplication] =   IIF(WT_01.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_02.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_03.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_04.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_05.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_06.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_07.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_08.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_09.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_10.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_11.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_12.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_13.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_14.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_15.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_16.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_17.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_18.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_19.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_20.TaskName IS NOT NULL, 1, 0) +
		-- 							IIF(WT_21.TaskName IS NOT NULL, 1, 0)
		-- FROM #TB_WF_MO       AS MO
		-- LEFT JOIN dbo.WorkTasks     AS WT_01    WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID    AND WT_01.TaskName  = 'Finish HDP Application 1'
		-- LEFT JOIN dbo.WorkTasks     AS WT_02    WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID    AND WT_02.TaskName  = 'Finish HDP Application 2'
		-- LEFT JOIN dbo.WorkTasks     AS WT_03    WITH(NOLOCK) ON MO.WorkFlowID = WT_03.WorkFlowID    AND WT_03.TaskName  = 'Finish HDP Application 3'
		-- LEFT JOIN dbo.WorkTasks     AS WT_04    WITH(NOLOCK) ON MO.WorkFlowID = WT_04.WorkFlowID    AND WT_04.TaskName  = 'Finish HDP Application 4'
		-- LEFT JOIN dbo.WorkTasks     AS WT_05    WITH(NOLOCK) ON MO.WorkFlowID = WT_05.WorkFlowID    AND WT_05.TaskName  = 'DHT Application 1'
		-- LEFT JOIN dbo.WorkTasks     AS WT_06    WITH(NOLOCK) ON MO.WorkFlowID = WT_06.WorkFlowID    AND WT_06.TaskName  = 'DHT Application 2'
		-- LEFT JOIN dbo.WorkTasks     AS WT_07    WITH(NOLOCK) ON MO.WorkFlowID = WT_07.WorkFlowID    AND WT_07.TaskName  = 'DHT Application 3'
		-- LEFT JOIN dbo.WorkTasks     AS WT_08    WITH(NOLOCK) ON MO.WorkFlowID = WT_08.WorkFlowID    AND WT_08.TaskName  = 'DHT Application 4'
		-- LEFT JOIN dbo.WorkTasks     AS WT_09    WITH(NOLOCK) ON MO.WorkFlowID = WT_09.WorkFlowID    AND WT_09.TaskName  = 'Finish Re-label'
		-- LEFT JOIN dbo.WorkTasks     AS WT_10    WITH(NOLOCK) ON MO.WorkFlowID = WT_10.WorkFlowID    AND WT_10.TaskName  = 'Finish SUB Application 1'
		-- LEFT JOIN dbo.WorkTasks     AS WT_11    WITH(NOLOCK) ON MO.WorkFlowID = WT_11.WorkFlowID    AND WT_11.TaskName  = 'Finish SUB Application 2'
		-- LEFT JOIN dbo.WorkTasks     AS WT_12    WITH(NOLOCK) ON MO.WorkFlowID = WT_12.WorkFlowID    AND WT_12.TaskName  = 'Finish SUB Application 3'
		-- LEFT JOIN dbo.WorkTasks     AS WT_13    WITH(NOLOCK) ON MO.WorkFlowID = WT_13.WorkFlowID    AND WT_13.TaskName  = 'Finish SUB Application 4'
		-- LEFT JOIN dbo.WorkTasks     AS WT_14    WITH(NOLOCK) ON MO.WorkFlowID = WT_14.WorkFlowID    AND WT_14.TaskName  = 'SUB Application 1'
		-- LEFT JOIN dbo.WorkTasks     AS WT_15    WITH(NOLOCK) ON MO.WorkFlowID = WT_15.WorkFlowID    AND WT_15.TaskName  = 'SUB Application 2'
		-- LEFT JOIN dbo.WorkTasks     AS WT_16    WITH(NOLOCK) ON MO.WorkFlowID = WT_16.WorkFlowID    AND WT_16.TaskName  = 'SUB Application 3'
		-- LEFT JOIN dbo.WorkTasks     AS WT_17    WITH(NOLOCK) ON MO.WorkFlowID = WT_17.WorkFlowID    AND WT_17.TaskName  = 'SUB Application 4'
		-- LEFT JOIN dbo.WorkTasks     AS WT_18    WITH(NOLOCK) ON MO.WorkFlowID = WT_18.WorkFlowID    AND WT_18.TaskName  = 'Finish DHT Application 1'
		-- LEFT JOIN dbo.WorkTasks     AS WT_19    WITH(NOLOCK) ON MO.WorkFlowID = WT_19.WorkFlowID    AND WT_19.TaskName  = 'Finish DHT Application 2'
		-- LEFT JOIN dbo.WorkTasks     AS WT_20    WITH(NOLOCK) ON MO.WorkFlowID = WT_20.WorkFlowID    AND WT_20.TaskName  = 'Finish DHT Application 3'
		-- LEFT JOIN dbo.WorkTasks     AS WT_21    WITH(NOLOCK) ON MO.WorkFlowID = WT_21.WorkFlowID    AND WT_21.TaskName  = 'Finish DHT Application 4'

		-- ---Actualizacion en PygmentDye
		-- UPDATE MO SET
		-- 	[PygmentDye]           =   IIF(WT_01.TaskName   IS NOT NULL, 1, 0) --+
		-- 							-- IIF(WT_02.TaskName   IS NOT NULL, 1, 0)
		-- FROM #TB_WF_MO       AS MO
		-- LEFT JOIN dbo.WorkTasks     AS WT_01     WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID     AND WT_01.TaskName   = 'Received from External Laundry '
		-- -- LEFT JOIN dbo.WorkTasks     AS WT_02     WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID     AND WT_02.TaskName   = 'Finish Sewing Assembly'
		
        -- ---Actualizacion en ExternalLaundry
        -- UPDATE MO SET
		-- 	[ExternalLaundry]           =   IIF(WT_01.TaskName   IS NOT NULL, 1, 0) --+
		-- 							-- IIF(WT_02.TaskName   IS NOT NULL, 1, 0)
		-- FROM #TB_WF_MO       AS MO
		-- LEFT JOIN dbo.WorkTasks     AS WT_01     WITH(NOLOCK) ON MO.WorkFlowID = WT_01.WorkFlowID     AND WT_01.TaskName   = 'Received from External Laundry '
		-- -- LEFT JOIN dbo.WorkTasks     AS WT_02     WITH(NOLOCK) ON MO.WorkFlowID = WT_02.WorkFlowID     AND WT_02.TaskName   = 'Finish Sewing Assembly'



		---Actualizacion de EO con el workflow de RO
		UPDATE MO SET
			 [Cut]                  =   COALESCE(MO.[Cut]                   ,0) + COALESCE(EORO.[Cut]               ,0)
			,[Sew]                  =   COALESCE(MO.[Sew]                   ,0) + COALESCE(EORO.[Sew]               ,0)
			,[ScreenPrint]          =   COALESCE(MO.[ScreenPrint]           ,0) + COALESCE(EORO.[ScreenPrint]       ,0)
			,[Sublimation]          =   COALESCE(MO.[Sublimation]           ,0) + COALESCE(EORO.[Sublimation]       ,0)
			,[EmbAPP]               =   COALESCE(MO.[EmbAPP]                ,0) + COALESCE(EORO.[EmbAPP]            ,0)
			,[EmbHW]                =   COALESCE(MO.[EmbHW]                 ,0) + COALESCE(EORO.[EmbHW]             ,0)
		--	,[otherApplication]     =   COALESCE(MO.[otherApplication]      ,0) + COALESCE(EORO.[otherApplication]  ,0)
			,[PygmentDye]           =   COALESCE(MO.[PygmentDye]            ,0) + COALESCE(EORO.[PygmentDye]  		,0)
			,[ExternalLaundry]      =   COALESCE(MO.[ExternalLaundry]       ,0) + COALESCE(EORO.[ExternalLaundry]  	,0)
			,[HDPApplication]      	=   COALESCE(MO.[HDPApplication]       	,0) + COALESCE(EORO.[HDPApplication]  	,0)
			,[DHTApplication]      	=   COALESCE(MO.[DHTApplication]       	,0) + COALESCE(EORO.[DHTApplication]  	,0)
			,[SUBApplication]      	=   COALESCE(MO.[SUBApplication]       	,0) + COALESCE(EORO.[SUBApplication]  	,0)
			,[ReLabel]      		=   COALESCE(MO.[ReLabel]       		,0) + COALESCE(EORO.[ReLabel]  			,0)
		FROM #TB_WF_MO AS MO
		INNER JOIN (
			SELECT
				[EO_ID]            = EORO.EO_ID
				,[Cut]              = IIF(SUM(COALESCE([Cut]                ,0))>0,1,0)
				,[Sew]              = IIF(SUM(COALESCE([Sew]                ,0))>0,1,0)
				,[ScreenPrint]      = IIF(SUM(COALESCE([ScreenPrint]        ,0))>0,1,0)
				,[Sublimation]      = IIF(SUM(COALESCE([Sublimation]        ,0))>0,1,0)
				,[EmbAPP]           = IIF(SUM(COALESCE([EmbAPP]             ,0))>0,1,0)
				,[EmbHW]            = IIF(SUM(COALESCE([EmbHW]              ,0))>0,1,0)
			--	,[otherApplication] = IIF(SUM(COALESCE([otherApplication]   ,0))>0,1,0)
				,[PygmentDye]       = IIF(SUM(COALESCE([PygmentDye]   		,0))>0,1,0)
				,[ExternalLaundry]  = IIF(SUM(COALESCE([ExternalLaundry]   	,0))>0,1,0)
				,[HDPApplication]  	= IIF(SUM(COALESCE([HDPApplication]   	,0))>0,1,0)
				,[DHTApplication]  	= IIF(SUM(COALESCE([DHTApplication]   	,0))>0,1,0)
				,[SUBApplication]  	= IIF(SUM(COALESCE([SUBApplication]   	,0))>0,1,0)
				,[ReLabel]  		= IIF(SUM(COALESCE([ReLabel]   			,0))>0,1,0)
			FROM        #TB_WF_EORO    AS EORO
			LEFT JOIN   #TB_WF_MO     AS RO   ON RO.ManufactureID = EORO.RO_ID
			GROUP BY EORO.EO_ID
		) AS EORO ON EORO.EO_ID = MO.ManufactureID

		---Actualizacion de si tiene código de bordado (diferente de NULL, vacio o TBD) y si tiene Print Count
		UPDATE MO SET
			 [HasEmbCode]		= 	IIF((MO.Code IS NOT NULL OR MO.Code <> '' OR MO.Code <> 'TBD') AND (MO.EmbAPP = 1 OR MO.EmbHW = 1) ,1,0)
			,[HasPrintCount]	= 	IIF((MO.PrintCount IS NOT NULL OR MO.PrintCount <> '' OR MO.PrintCount <> '0') AND MO.ScreenPrint = 1,1,0)
		FROM #TB_WF_MO AS MO

	TRUNCATE TABLE AppsLCA.dbo.TB_MO_PartNumber_IM_MOProcess	
	INSERT INTO AppsLCA.dbo.TB_MO_PartNumber_IM_MOProcess	
	SELECT * 
	FROM #TB_WF_MO AS MO
	
	
    -- where PygmentDye = 1
	-- WHERE [ScreenPrint] >0 AND [Sublimation] >0 AND EmbAPP >0

	----------------------------------------------------------------------------------------------------------------
	-------------------------------CREACION TABLA WORKFLOWS---------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------

END