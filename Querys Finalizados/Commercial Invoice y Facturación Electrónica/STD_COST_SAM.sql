
USE AppsLCA

	----------------------------------------------------------------------------------------------------------------
	------------------CREACION TABLA COSTOS BOM CUT SEW PACK SCREENPRINT SUBLIMATION--------------------------------
	----------------------------------------------------------------------------------------------------------------

		PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'CREACION TABLA COSTOS BOM CUT SEW PACK')
		

		DROP TABLE IF EXISTS #TB_LABOR
		DROP TABLE IF EXISTS #CTE_LABOR
        DROP TABLE IF EXISTS #TB_AnexoFacturacion

        SELECT 
             [ID]                   = [ID]
            ,[StyleNumber]          = [StyleNumber]
            ,[SeasonName]           = [SeasonName]
            ,[ShipDate]             = [ShipDate]
            ,[SewLabor_SAM]         = CAST(0.00 AS DECIMAL(18,4))
            ,[SewLaborExpected_SAM] = CAST(0.00 AS DECIMAL(18,4))
        INTO #TB_AnexoFacturacion
        FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK)
        WHERE ShipDate >= '2026-01-01'
		
		-- ;WITH CTE_LABOR AS(
			SELECT
				 [StyleID]		= STT.StyleID
				,[StyleNumber]	= STT.Style
				,[Season]		= STT.Season
				,[Status]       = STT.[Status]
				--,[BlankStyleID]	= STT.BlankStyleID
				--,[BlankStyle]	= STT.BlankStyle
				--,[BlankSeason]	= STT.BlankSeason
				,[Category]		= CASE
										WHEN (	CC.ComponentCategoryID = 6												) THEN--Cut Labor
											'CutLabor'
										WHEN (	CC.ComponentCategoryID = 9  AND  NOT (CL.ComponentName LIKE '%expec%')	) THEN--Sew Labor Y no expected
											'SewLabor'
										WHEN (	CC.ComponentCategoryID = 9  AND  (CL.ComponentName LIKE '%expec%')	) THEN--Sew Labor Expected only
											'SewLaborExpcted'
										WHEN (	CC.ComponentCategoryID = 12	AND CB.SubCategoryName LIKE '%Pack%'		) THEN--Handling y PACK
											'PackLabor'
										WHEN (	CC.ComponentCategoryID = 12	AND CL.ComponentName like '%Screen Print%'	) THEN --Handling y ScreenPrint
											'ScreenPrintLabor'
										WHEN (	CC.ComponentCategoryID = 12 AND NOT( CL.ComponentName LIKE '%MateR%') AND CL.ComponentName LIKE '%Subl%') THEN --SublimationLabor
											'SublimationLabor'
										WHEN  (	(CC.ComponentCategoryID = 4 OR CC.ComponentCategoryID = 12) AND CL.ComponentName LIKE '%Mater%'	) THEN--SublimationMaterials
											'Sublimation'
									ELSE ''
									END
				-- ,[StyleStatus]  =  
				,[Costo]		= ROUND(SUM(SD.Subtotal), 2)
				,[Quantity]		= ROUND(SUM(SD.Quantity), 4)
			INTO #CTE_LABOR
			--SELECT *
			FROM			LCA.dbo.ComponentCategories		AS CC WITH(NOLOCK)
			INNER JOIN		LCA.dbo.ComponentLibrary		AS CL WITH(NOLOCK) ON CL.ComponentCategoryID	= CC.ComponentCategoryID AND CC.ComponentCategoryID IN( 4,6,9,12) --Trim,CutLabor, SewLabor, Handling
			INNER JOIN		LCA.dbo.ComponentSubcategories	AS CB WITH(NOLOCK) ON CB.SubCategoryID			= CL.SubCategoryID
																				AND (
																				(	CC.ComponentCategoryID = 6												) --Cut Labor
																			OR	(	CC.ComponentCategoryID = 9  AND  NOT (CL.ComponentName LIKE '%expec%')	) --Sew Labor Y no expected
																			OR	(	CC.ComponentCategoryID = 9  AND (CL.ComponentName LIKE '%expec%')	) --Sew Labor Y no expected
																			OR	(	CC.ComponentCategoryID = 12	AND CB.SubCategoryName LIKE '%Pack%'		) --Handling y Packing en subcategoria
																			OR	(	CC.ComponentCategoryID = 12	AND CL.ComponentName like '%Screen Print%'	) --Handling y Screen Print en componente
																			OR	(	CC.ComponentCategoryID = 12 AND NOT( CL.ComponentName LIKE '%MateR%') AND CL.ComponentName LIKE '%Subl%') --Handling y Sublimation
																			OR  (	(CC.ComponentCategoryID = 4 OR CC.ComponentCategoryID = 12) AND CL.ComponentName LIKE '%Mater%'	) --SublimationMaterials										)
																		)
			INNER JOIN		LCA.dbo.StyleDetails			AS SD WITH(NOLOCK) ON SD.ComponentID			= CL.ComponentID
			--LEFT JOIN		dbo.RawMaterials			AS RM WITH(NOLOCK) ON RM.RawMaterialID			= SD.RawMaterialID
			INNER JOIN	(
							SELECT
								 [StyleID]		= ST1.StyleID
								,[Style]		= ST1.StyleNumber
								,[Season]		= SN1.SeasonName
								,[Status]       = S1.StatusName
								,[BlankStyleID]	= COALESCE(ST2.StyleID		,ST3.BlankStyleID	,ST1.StyleID	)
								,[BlankStyle]	= COALESCE(ST2.StyleNumber	,ST3.BlankStyle		,ST1.StyleNumber)
								,[BlankSeason]	= COALESCE(SN2.SeasonName	,ST3.BlankSeason	,SN1.SeasonName	)
							FROM		LCA.dbo.Styles				AS ST1 WITH(NOLOCK)
							LEFT JOIN	LCA.dbo.Styles				AS ST2 WITH(NOLOCK) ON ST1.BlankStyleID		= ST2.StyleID
							LEFT JOIN	LCA.dbo.Seasons				AS SN1 WITH(NOLOCK) ON SN1.SeasonID			= ST1.SeasonID
							LEFT JOIN	LCA.dbo.Seasons				AS SN2 WITH(NOLOCK) ON SN2.SeasonID			= ST2.SeasonID
							LEFT JOIN   LCA.dbo.StatusNames         AS S1  WITH(NOLOCK) ON S1.StatusID          = ST1.StatusID
							LEFT JOIN (
										SELECT
												[StyleID]		= ST.StyleID
												,[Style]		= ST.StyleNumber
												,[Season]		= SN.SeasonName
											,[BlankStyleID]	= STB.StyleID
											,[BlankStyle]	= STB.StyleNumber
											,[BlankSeason]	= SNB.SeasonName
										FROM		LCA.dbo.Styles	AS ST	WITH(NOLOCK)
										INNER JOIN	LCA.dbo.Seasons	AS SN	WITH(NOLOCK) ON ST.SeasonID = SN.SeasonID AND SN.SeasonID = 2231	--Season EMB Cost
										LEFT JOIN	LCA.dbo.Styles	AS STB	WITH(NOLOCK) ON ST.StyleNumber = STB.StyleNumber
										INNER JOIN	LCA.dbo.Seasons AS SNB	WITH(NOLOCK) ON SNB.SeasonID = STB.SeasonID	AND SNB.SeasonID = 2229	--Season BLANK
									) AS ST3 ON ST3.StyleID = ST1.StyleID

			)	AS STT ON STT.BlankStyleID = SD.StyleID OR STT.StyleID = SD.StyleID
			--where STT.Style = 'BT300'
			GROUP BY
				 STT.StyleID
				,STT.Style
				,STT.Season
				,STT.[Status]
				--,STT.BlankStyleID
				--,STT.BlankStyle
				--,STT.BlankSeason
				,CASE
						WHEN (	CC.ComponentCategoryID = 6												) THEN--Cut Labor
							'CutLabor'
						WHEN (	CC.ComponentCategoryID = 9  AND  NOT (CL.ComponentName LIKE '%expec%')	) THEN--Sew Labor Y no expected
							'SewLabor'
						WHEN (	CC.ComponentCategoryID = 9  AND  (CL.ComponentName LIKE '%expec%')	) THEN--Sew Labor Expected only
							'SewLaborExpcted'
						WHEN (	CC.ComponentCategoryID = 12	AND CB.SubCategoryName LIKE '%Pack%'		) THEN--Handling y
							'PackLabor'
						WHEN (	CC.ComponentCategoryID = 12	AND CL.ComponentName like '%Screen Print%'	) THEN --Handling y ScreenPrint
							'ScreenPrintLabor'
						WHEN (	CC.ComponentCategoryID = 12 AND NOT( CL.ComponentName LIKE '%MateR%') AND CL.ComponentName LIKE '%Subl%') THEN --SublimationLabor
							'SublimationLabor'
						WHEN  (	(CC.ComponentCategoryID = 4 OR CC.ComponentCategoryID = 12) AND CL.ComponentName LIKE '%Mater%'	) THEN--SublimationMaterials
							'Sublimation'
					ELSE ''
					END
		-- )

		SELECT
			 [StyleID]                = S.StyleID
			,[StyleNumber]            = S.StyleNumber
			,[Season]                 = S.Season
			,[Status]                 = S.[Status]
			-- ,[CutLabor_Cost]          = SUM(CASE WHEN S.Category = 'CutLabor'                            THEN S.Costo    ELSE 0.00 END)
			,[SewLabor_Cost]          = SUM(CASE WHEN S.Category = 'SewLabor'                            THEN S.Costo    ELSE 0.00 END)
			,[SewLaborExpcted_Cost]   = SUM(CASE WHEN S.Category = 'SewLaborExpcted'                     THEN S.Costo    ELSE 0.00 END)
			-- ,[ScreenPrintLabor_Cost]  = SUM(CASE WHEN S.Category = 'ScreenPrintLabor' AND S.Costo <> 0   THEN 0.95       ELSE 0.00 END)
			-- ,[SublimationLabor_Cost]  = SUM(CASE WHEN S.Category = 'SublimationLabor'                    THEN S.Costo    ELSE 0.00 END)
			-- ,[Sublimation_Cost]       = SUM(CASE WHEN S.Category = 'Sublimation'                         THEN S.Costo    ELSE 0.00 END)
			-- ,[PackLabor_Cost]         = SUM(CASE WHEN S.Category = 'PackLabor'                           THEN S.Costo    ELSE 0.00 END)
			-- ,[CutLabor_SAM]           = SUM(CASE WHEN S.Category = 'CutLabor'                            THEN S.Quantity ELSE 0.00 END)
			,[SewLabor_SAM]           = SUM(CASE WHEN S.Category = 'SewLabor'                            THEN S.Quantity ELSE 0.00 END)
			,[SewLaborExpcted_SAM]    = SUM(CASE WHEN S.Category = 'SewLaborExpcted'                     THEN S.Quantity ELSE 0.00 END)
			-- ,[ScreenPrintLabor_SAM]   = SUM(CASE WHEN S.Category = 'ScreenPrintLabor'                    THEN S.Quantity ELSE 0.00 END)
			-- ,[SublimationLabor_SAM]   = SUM(CASE WHEN S.Category = 'SublimationLabor'                    THEN S.Quantity ELSE 0.00 END)
			-- ,[Sublimation_SAM]        = SUM(CASE WHEN S.Category = 'Sublimation'                         THEN S.Quantity ELSE 0.00 END)
			-- ,[PackLabor_SAM]          = SUM(CASE WHEN S.Category = 'PackLabor'                           THEN S.Quantity ELSE 0.00 END)
		INTO #TB_LABOR
		FROM #CTE_LABOR AS S
		-- INNER JOIN #TB_Group_Style AS GP ON GP.Style = S.StyleNumber
		GROUP BY
			 S.StyleID
			,S.StyleNumber
			,S.Season
			,S.[Status]

        UPDATE AF SET
             SewLabor_SAM = TL.SewLabor_SAM
            ,SewLaborExpected_SAM = TL.SewLaborExpcted_SAM
        FROM #TB_AnexoFacturacion AS AF
        INNER JOIN #TB_LABOR AS TL ON AF.StyleNumber = TL.StyleNumber AND AF.SeasonName = TL.Season

		SELECT * FROM #TB_LABOR

        UPDATE AF2 SET
             SewingLabor_SAM = AF.SewLabor_SAM
            ,SewingLaborExpected_SAM = AF.SewLaborExpected_SAM
        FROM #TB_AnexoFacturacion AS AF
        INNER JOIN AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF2 WITH(NOLOCK) ON AF.ID = AF2.ID


        ORDER BY ID
		-- WHERE Season = 'Blank FG'
		-- where StyleNumber = 'RW218'
		
		
		-- SELECT
		--     SNS.SeasonName
		--     ,ST.StyleNumber
		--     ,ST.*
		-- FROM LCA.DBO.Styles AS ST WITH(NOLOCK)
		-- LEFT JOIN LCA.DBO.Seasons   AS SNS WITH(NOLOCK) ON SNS.SeasonID = ST.SeasonID
		-- WHERE ST.StyleNumber = 'RW218'
		
		
		
		-- SELECT * FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK)
		-- WHERE YEAR(AF.Shipdate) = 2025
		return
	----------------------------------------------------------------------------------------------------------------
	------------------CREACION TABLA COSTOS BOM CUT SEW PACK SCREENPRINT SUBLIMATION--------------------------------
	----------------------------------------------------------------------------------------------------------------