

USE AppsLCA

		

	DROP TABLE IF EXISTS #TB_DATA_WIP
	DROP TABLE IF EXISTS #TB_DATA_RM
	DROP TABLE IF EXISTS #TB_STD_ALL
	DROP TABLE IF EXISTS #CategoryBusiness
	DROP TABLE IF EXISTS #CategoryBusiness_global
	DROP TABLE IF EXISTS #TB_Clasificacion
	DROP TABLE IF EXISTS #TB_CuentasContables
	DROP TABLE IF EXISTS #TB_OrderData
	DROP TABLE IF EXISTS #TB_OrderLocation

--------------------------------------------------------------------------------
			CREATE TABLE #TB_Clasificacion (
				 [LocationCost]  VARCHAR(100)
				,[Clasificacion] VARCHAR(50)
			)
			INSERT INTO #TB_Clasificacion ([LocationCost],[Clasificacion]) VALUES
				 ('Bordado Gorras'        , 'Wip')
				,('Bordado Prendas'       , 'Wip')
				,('Corte'                 , 'Wip')
				,('CorteTela'             , 'Wip')
				,('Costura'               , 'Wip')
				,('Empaque'               , 'Finish Good')
				,('Headwear DLI'          , 'Finish Good')
				,('NO WIP'                , 'Wip')
				,('Serigrafia'            , 'Wip')
				,('Sublimado'             , 'Wip')
				,('WH First Semi Finish'  , 'Finish Good')
				,('WH PT'                 , 'Finish Good')
				,('WH RO'                 , 'Finish Good')
				,('Greige Items'          , 'Finish Good')

			CREATE TABLE #TB_CuentasContables (
				 [CtaCosto]  VARCHAR(20)
				,[DesCuenta] VARCHAR(100)
				,[Category]  VARCHAR(50)
			)

			INSERT INTO #TB_CuentasContables ([CtaCosto],[DesCuenta],[Category]) VALUES
				 ('5041-100-00', 'MANO DE OBRA PRODUCTO EN PROCESO'    , 'Labor')
				,('5026-300-00', 'MATERIALES & SUMINISTROS EMPAQUE'    , 'Packing')
				,('5026-400-00', 'MATERIALES & SUMINISTROS SERIGRAFIA' , 'Screen Print')
				,('5009-400-00', 'COSTO MATERIALES SUBLIMADO'          , 'Sublimation')
				,('5000-100-00', 'COSTO TELAS'                         , 'Tela')
				,('5002-100-00', 'COSTO ETIQUETAS'                     , 'Trims')
				,('5008-100-00', 'COSTO MATERIAL DE LAVANDERIA'        , 'Washing')
				,('5000-100-02', 'COST SEMI-PROCESSED PRODUCT'         , 'Contracts Apparel')
				,('5000-100-03', 'COSTO GORRAS SEMI ELABORADAS'        , 'Contracts Headwear')
				,('0000-000-01', 'Decoration'                          , 'Decoration')
				,('0000-000-02', 'Total Units'                         , 'Total Units')
				,('0000-000-03', 'Units'                               , 'Units')
--------------------------------------------------------------------------------

    -- DECLARE @DateInventory AS DATE = '2026-04-30'
    -- DECLARE @InventoryComment AS VARCHAR(100) = 'New_Model_V2'
    
    DECLARE @DateInventory AS DATE = '2026-07-31'
    DECLARE @InventoryComment AS VARCHAR(100) = 'New_Model_V0'
    
    
		SELECT
			 [TypeQuery]
			,[DateInventory]
			,[LocationCost]
			,[Area]
			,[TypeData]
			,[StyleDivision]
			,[QtyLCA]
			,[QtySemiApp]
			,[QtySemiHW]
			,[GarmentSubl]
			,[GarmentSP]
			,[GarmentEmbHW]
			,[GarmentEmbAPP]
			,[ContractsAPP]
			,[ContractsHW]
			,[SPPrintCount]
			,[SublPrintCount]
			,[EmbCountHW]
			,[EmbCountAPP]
			,[Fabric]
			,[Thread]
			,[Trim]
			,[Supplies]
			,[CutLabor]
			,[SewLabor]
			,[PackLabor]
			,[ScreenPrint]
			,[ScreenPrintLabor]
			,[Sublimation]
			,[SublimationLabor]
			,[FabricEmbroideryHW]
			,[ThreadEmbroideryHW]
			,[EmbroideryHWLabor]
			,[FabricEmbroideryAPP]
			,[ThreadEmbroideryAPP]
			,[EmbroideryAPPLabor]
			,[DefaultZero]  = 0
		INTO #TB_DATA_WIP FROM [AppsLCA].[dbo].[Financial_MonthlyClose_WIP] WITH(NOLOCK)
		WHERE
		    LocationCost 	<> 'NO WIP'
		    AND LocationCost <> 'WH NOT INCLUDED'
		    AND Area <> 'NO WIP (Released)'
		AND DateInventory	= @DateInventory
		AND DateInventoryComment = @InventoryComment

        SELECT
             [TypeQuery]         = 'GreigeItems'
            ,[DateInventory]     = [FinalDate]
            ,[LocationCost]      = IIF([StyleSubcategory] = 'Headwear', 'Headwear DLI', 'Greige Items')
            ,[Area]             = [Area2]   
            ,[StyleDivision]    = IIF([StyleSubcategory] = 'Headwear', 'Headwear', 'Apparel')
            ,[TypeData]         = 'SEMI'
            ,[ContractsAPP]     = IIF([StyleSubcategory] <> 'Headwear'  , [Contracts+Freight] ,0.00)
            ,[ContractsHW]      = IIF([StyleSubcategory] = 'Headwear'   , [Contracts+Freight] ,0.00)
            ,[QtySemiApp]       = IIF([StyleSubcategory] <> 'Headwear'  , [QTY] ,0.00)
            ,[QtySemiHW]        = IIF([StyleSubcategory] = 'Headwear'   , [QTY] ,0.00)
            ,[DefaultZero]      = 0
        INTO #TB_DATA_RM
        FROM  [AppsLCA].[dbo].[Financial_MonthlyClose_GreigeItems]
         WHERE
         FinalDate	= @DateInventory
		AND FinalDateComment = @InventoryComment
        -- SELECT TOP 10 * FROM #TB_DATA_WIP

            DECLARE @SUM_3 AS VARCHAR(50) = 'All Process LCA'
            DECLARE @SUM_2 AS VARCHAR(50) = 'All Process SEMI'
            DECLARE @SUM_1 AS VARCHAR(50) = 'All Units'
            
			DECLARE @VAR_1 AS VARCHAR(50) = 'Summary (Qty)'
			DECLARE @VAR_11 AS VARCHAR(50) = 'Summary (Decoration)'
			DECLARE @VAR_2 AS VARCHAR(50) = 'Semi'
			DECLARE @VAR_3 AS VARCHAR(50) = 'Cut & Sew'
			DECLARE @VAR_4 AS VARCHAR(50) = 'Screen Print'
			DECLARE @VAR_5 AS VARCHAR(50) = 'Sublimation'
			DECLARE @VAR_6 AS VARCHAR(50) = 'Embroidery Headwear'
			DECLARE @VAR_7 AS VARCHAR(50) = 'Embroidery Apparel'
			
			DECLARE @Format_Money AS VARCHAR(100) = '$#,##0.00'
			DECLARE @Format_Number AS VARCHAR(100) = '#,##0'
			
--------------------------------------------------------------------------------
			CREATE TABLE  #TB_STD_ALL(
				 [DateInventory]    DATE
				,[TypeProces]       VARCHAR(100)
				,[Business]		    VARCHAR(100)
				,[Contab]		    VARCHAR(100)
				,[Category] 	    VARCHAR(100)
				,[TypeQuery]        VARCHAR(100)
				,[LocationCost]     VARCHAR(100)
				,[Area]             VARCHAR(100)
				,[TypeData]         VARCHAR(50)
				,[StyleDivision]    VARCHAR(100)
				,[Total] 		    DECIMAL(18,4)
				,[FormatData]       VARCHAR(50)
				,[Clasificacion]    VARCHAR(50)
				,[CtaCosto]                    VARCHAR(20)
				,[DesCuenta]                   VARCHAR(100)
				,[CuentaInventario]            VARCHAR(20)
				,[DescripcionCuentaInventario] VARCHAR(100)
			)

			DECLARE @sql NVARCHAR(MAX) 	= ''
			DECLARE @crlf CHAR(2) 		= CHAR(13) + CHAR(10)
			DECLARE @sep VARCHAR(10) 	= ',' + CHAR(13) + CHAR(10)
			DECLARE @tmp NVARCHAR(MAX)

			CREATE TABLE #CategoryBusiness (
				 [TypeProces]    VARCHAR(100)
				,[Business] 	 VARCHAR(50)
				,[Contab]        VARCHAR(50)
				,[Category] 	 VARCHAR(50)
				,[FieldName] 	 VARCHAR(50)
				,[FormatData]    VARCHAR(50)
			)
--------------------------------------------------------------------------------

			INSERT INTO #CategoryBusiness ([TypeProces],[Business],[Contab], [Category], [FieldName],[FormatData])
			VALUES 
				 (@SUM_1    ,   @VAR_1	,'Total Units'             , 'Total Quantity LCA'					          , 'QtyLCA'                  ,@Format_Number    )	
				,(@SUM_1    ,   @VAR_1	,'Total Units'             , 'Total Quantity SEMI Apparel'			          , 'QtySemiApp'              ,@Format_Number    )
				,(@SUM_1    ,   @VAR_1	,'Total Units'             , 'Total Quantity SEMI Headwear'		              , 'QtySemiHW'               ,@Format_Number    )
				,(@SUM_1    ,   @VAR_1	,'Units'                   , 'Total Garment Sublimation'			          , 'GarmentSubl'             ,@Format_Number    )
				,(@SUM_1    ,   @VAR_1	,'Units'                   , 'Total Garment ScreenPrint'			          , 'GarmentSP'               ,@Format_Number    )
				,(@SUM_1    ,   @VAR_1	,'Units'                   , 'Total Garment Embroidery Headwear'	          , 'GarmentEmbHW'            ,@Format_Number    )
				,(@SUM_1    ,   @VAR_1	,'Units'                   , 'Total Garment Embroidery Apparel'	              , 'GarmentEmbAPP'           ,@Format_Number    )
				,(@SUM_1    ,   @VAR_11	,'Decoration'              , 'Total PrintCount ScreenPrint'		              , 'SPPrintCount'            ,@Format_Number    )
				,(@SUM_1    ,   @VAR_11	,'Decoration'              , 'Total PrintCount Sublimation'		              , 'SublPrintCount'          ,@Format_Number    )
				,(@SUM_1    ,   @VAR_11	,'Decoration'              , 'Total EmbroideryCount Headwear'		          , 'EmbCountHW'              ,@Format_Number    )
				,(@SUM_1    ,   @VAR_11	,'Decoration'              , 'Total Embroidery Count Apparel'		          , 'EmbCountAPP'             ,@Format_Number    )
				,(@SUM_1    ,   @VAR_1	,'Total Units'             , 'Total Quantity SEMI Apparel RawMaterials'       , 'DefaultZero'             ,@Format_Number    )
				,(@SUM_1    ,   @VAR_1	,'Total Units'             , 'Total Quantity SEMI Headwear RawMaterials'      , 'DefaultZero'             ,@Format_Number    )
				
				,(@SUM_2    ,   @VAR_2	,'Contracts Apparel'       , 'Total Contracts Apparel'				          , 'ContractsAPP'	          ,@Format_Money     )
				,(@SUM_2    ,   @VAR_2	,'Contracts Headwear'      , 'Total Contracts Headwear'			              , 'ContractsHW'	          ,@Format_Money     )
				,(@SUM_2    ,   @VAR_2	,'Contracts Apparel'       , 'Total Contracts Apparel RawMaterials'	          , 'DefaultZero'	          ,@Format_Money     )
				,(@SUM_2    ,   @VAR_2	,'Contracts Headwear'      , 'Total Contracts Headwear RawMaterials'	      , 'DefaultZero'	          ,@Format_Money     )
				
				,(@SUM_3    ,   @VAR_3	,'Tela'                    , 'Fabric Mat'							          , 'Fabric'                  ,@Format_Money     )
				,(@SUM_3    ,   @VAR_3	,'Trims'                   , 'Thread Mat'							          , 'Thread'                  ,@Format_Money     )
				,(@SUM_3    ,   @VAR_3	,'Trims'                   , 'Trim Mat'							              , 'Trim'                    ,@Format_Money     )
				,(@SUM_3    ,   @VAR_3	,'Packing'                 , 'Supplies Mat'						              , 'Supplies'                ,@Format_Money     )
				,(@SUM_3    ,   @VAR_3	,'Labor'                   , 'Cut Labor'						              , 'CutLabor'                ,@Format_Money     )
				,(@SUM_3    ,   @VAR_3	,'Labor'                   , 'Sew Labor'						              , 'SewLabor'                ,@Format_Money     )
				,(@SUM_3    ,   @VAR_3	,'Labor'                   , 'Pack Labor'						              , 'PackLabor'               ,@Format_Money     )
				,(@SUM_3    ,   @VAR_4	,'Screen Print'            , 'ScreenPrint Mat'					              , 'ScreenPrint'	          ,@Format_Money     )
				,(@SUM_3    ,   @VAR_4	,'Labor'                   , 'ScreenPrint Labor'				              , 'ScreenPrintLabor'        ,@Format_Money     )
				,(@SUM_3    ,   @VAR_5	,'Sublimation'             , 'Sublimation'						              , 'Sublimation'	          ,@Format_Money     )
				,(@SUM_3    ,   @VAR_5	,'Labor'                   , 'Sublimation Labor'				              , 'SublimationLabor'        ,@Format_Money     )
				,(@SUM_3    ,   @VAR_6	,'Tela'                    , 'Fabric Embroidery Headwear'		              , 'FabricEmbroideryHW'      ,@Format_Money     )
				,(@SUM_3    ,   @VAR_6	,'Trims'                   , 'Thread Embroidery Headwear'		              , 'ThreadEmbroideryHW'      ,@Format_Money     )
				,(@SUM_3    ,   @VAR_6	,'Labor'                   , 'Labor Embroidery Headwear'		              , 'EmbroideryHWLabor'       ,@Format_Money     )
				,(@SUM_3    ,   @VAR_7	,'Tela'                    , 'Fabric Embroidery Apparel'		              , 'FabricEmbroideryAPP'     ,@Format_Money     )
				,(@SUM_3    ,   @VAR_7	,'Trims'                   , 'Thread Embroidery Apparel'		              , 'ThreadEmbroideryAPP'     ,@Format_Money     )
				,(@SUM_3    ,   @VAR_7	,'Labor'                   , 'Labor Embroidery Apparel'			              , 'EmbroideryAPPLabor'      ,@Format_Money     )
				,(@SUM_3    ,   @VAR_3	,'Washing'                 , 'Washing'                                        , 'DefaultZero'             ,@Format_Money     )

				-- ,(@VAR_4	,'No det'  , 'Total ScreenPrint'					, 'SP'                   ,@Format_Money     )
				-- ,(@VAR_3	,'No det'  , 'Total Garment Cut & Sew'				, 'GarmentCutSew'        ,@Format_Number    )
				-- ,(@VAR_3	,'No det'  , 'Total Cut & Sew'						, 'CutSew'               ,@Format_Money     )
				-- ,(@VAR_1	,'No det'  , 'Total Quantity SEMI'					, 'QtySEMI'              ,@Format_Number    )
				-- ,(@VAR_1	,'No det'  , 'Total Quantity'						, 'Quantity'             ,@Format_Number    )
				-- ,(@VAR_2	,'No det'  , 'Total Contracts'						, 'Contracts'	         ,@Format_Money     )
				-- ,(@VAR_5	,'No det'  , 'Total Sublimation'					, 'Subl'                 ,@Format_Money     )
				-- ,(@VAR_6	,'No det'  , 'Total Embroidery Headwear'			, 'EmbHW'                ,@Format_Money     )
				-- ,(@VAR_7	,'No det'  , 'Total Embroidery Apparel'			, 'EmbAPP'                ,@Format_Money     )


-- 			select 
-- 				TypeInventory = CAST('DataWIP' AS VARCHAR(70))
-- 				,*
-- 			INTO #CategoryBusiness_global
-- 			from #CategoryBusiness

-- select CONTAB,Category,FieldName,'Tabla WIP' as tb from #CategoryBusiness

-- return


			SELECT @sql +=
				'SELECT' + @crlf +
				' ' + '[DateInventory] = [DateInventory] ' + @crlf +
				',     [TypeProces] = ''' + cb.TypeProces + '''' + @crlf +
				',     [Business] = ''' + cb.Business + '''' + @crlf +
				',' + '[Contab] = ''' + cb.Contab + '''' + @crlf +
				',' + '[Category] = ''' + cb.Category + '''' + @crlf +
				',' + '[TypeQuery] = [TypeQuery] ' + @crlf +
				',' + '[LocationCost] = [LocationCost] ' + @crlf +
				',' + '[Area] = [Area] ' + @crlf +
				',' + '[TypeData] = [TypeData] ' + @crlf +
				',' + '[StyleDivision] = [StyleDivision] ' + @crlf +
				',' + '[Total] = SUM( ISNULL([' + cb.FieldName + '],0) )' 	+	@crlf +
				',' + '[FormatData] = CAST(''' + cb.FormatData + ''' AS VARCHAR(50))' + @crlf +
				'FROM #TB_DATA_WIP' + @crlf +
				'group by [LocationCost],[Area],[TypeData],[StyleDivision],[TypeQuery],[DateInventory]' + @crlf +
				'UNION ALL' + @crlf
			FROM #CategoryBusiness cb

			SET @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL' + @crlf))			-- Quitar el último UNION ALL

			-- PRINT @sql;
			-- return
			
			DELETE FROM #TB_STD_ALL
			INSERT INTO #TB_STD_ALL (
				[DateInventory],[TypeProces],[Business],[Contab],[Category],
				[TypeQuery],[LocationCost],[Area],[TypeData],[StyleDivision],
				[Total],[FormatData]
			) EXEC sp_executesql @sql
			
			
			
			DELETE FROM #CategoryBusiness
			
			INSERT INTO #CategoryBusiness ([TypeProces],[Business],[Contab], [Category], [FieldName],[FormatData])
			VALUES                  
				 (@SUM_1     ,   @VAR_1	    ,'Total Units'             , 'Total Quantity LCA'					          , 'DefaultZero'             ,@Format_Number    )	
				,(@SUM_1     ,   @VAR_1	    ,'Total Units'             , 'Total Quantity SEMI Apparel'			          , 'DefaultZero'             ,@Format_Number    )
				,(@SUM_1     ,   @VAR_1	    ,'Total Units'             , 'Total Quantity SEMI Headwear'		              , 'DefaultZero'             ,@Format_Number    )
				,(@SUM_1     ,   @VAR_1	    ,'Units'                   , 'Total Garment Sublimation'			          , 'DefaultZero'             ,@Format_Number    )
				,(@SUM_1     ,   @VAR_1	    ,'Units'                   , 'Total Garment ScreenPrint'			          , 'DefaultZero'             ,@Format_Number    )
				,(@SUM_1     ,   @VAR_1	    ,'Units'                   , 'Total Garment Embroidery Headwear'	          , 'DefaultZero'             ,@Format_Number    )
				,(@SUM_1     ,   @VAR_1	    ,'Units'                   , 'Total Garment Embroidery Apparel'	              , 'DefaultZero'             ,@Format_Number    )
				,(@SUM_1     ,   @VAR_11	,'Decoration'              , 'Total PrintCount ScreenPrint'		              , 'DefaultZero'             ,@Format_Number    )
				,(@SUM_1     ,   @VAR_11	,'Decoration'              , 'Total PrintCount Sublimation'		              , 'DefaultZero'             ,@Format_Number    )
				,(@SUM_1     ,   @VAR_11	,'Decoration'              , 'Total EmbroideryCount Headwear'		          , 'DefaultZero'             ,@Format_Number    )
				,(@SUM_1     ,   @VAR_11	,'Decoration'              , 'Total Embroidery Count Apparel'		          , 'DefaultZero'             ,@Format_Number    )
				,(@SUM_1     ,   @VAR_1	    ,'Total Units'             , 'Total Quantity SEMI Apparel RawMaterials'       , 'QtySemiApp'              ,@Format_Number    )
				,(@SUM_1     ,   @VAR_1	    ,'Total Units'             , 'Total Quantity SEMI Headwear RawMaterials'      , 'QtySemiHW'               ,@Format_Number    )
				
				,(@SUM_2     ,   @VAR_2	    ,'Contracts Apparel'       , 'Total Contracts Apparel'				          , 'DefaultZero'	          ,@Format_Money     )
				,(@SUM_2     ,   @VAR_2	    ,'Contracts Headwear'      , 'Total Contracts Headwear'			              , 'DefaultZero'	          ,@Format_Money     )
				,(@SUM_2     ,   @VAR_2	    ,'Contracts Apparel'       , 'Total Contracts Apparel RawMaterials'	          , 'ContractsAPP'	          ,@Format_Money     )
				,(@SUM_2     ,   @VAR_2	    ,'Contracts Headwear'      , 'Total Contracts Headwear RawMaterials'	      , 'ContractsHW'	          ,@Format_Money     )
				
				,(@SUM_3     ,   @VAR_3	    ,'Tela'                    , 'Fabric Mat'							          , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_3	    ,'Trims'                   , 'Thread Mat'							          , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_3	    ,'Trims'                   , 'Trim Mat'							              , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_3	    ,'Packing'                 , 'Supplies Mat'						              , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_3	    ,'Labor'                   , 'Cut Labor'						              , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_3	    ,'Labor'                   , 'Sew Labor'						              , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_3	    ,'Labor'                   , 'Pack Labor'						              , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_4	    ,'Screen Print'            , 'ScreenPrint Mat'					              , 'DefaultZero'	          ,@Format_Money     )
				,(@SUM_3     ,   @VAR_4	    ,'Labor'                   , 'ScreenPrint Labor'				              , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_5	    ,'Sublimation'             , 'Sublimation'						              , 'DefaultZero'	          ,@Format_Money     )
				,(@SUM_3     ,   @VAR_5	    ,'Labor'                   , 'Sublimation Labor'				              , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_6	    ,'Tela'                    , 'Fabric Embroidery Headwear'		              , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_6	    ,'Trims'                   , 'Thread Embroidery Headwear'		              , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_6	    ,'Labor'                   , 'Labor Embroidery Headwear'		              , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_7	    ,'Tela'                    , 'Fabric Embroidery Apparel'		              , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_7	    ,'Trims'                   , 'Thread Embroidery Apparel'		              , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_7	    ,'Labor'                   , 'Labor Embroidery Apparel'			              , 'DefaultZero'             ,@Format_Money     )
				,(@SUM_3     ,   @VAR_3	    ,'Washing'                 , 'Washing'                                        , 'DefaultZero'             ,@Format_Money     )
				
			SET @sql = ''
			SELECT @sql +=
				'SELECT' + @crlf +
				' ' + '[DateInventory] = [DateInventory] ' + @crlf +
				',     [TypeProces] = ''' + cb.TypeProces + '''' + @crlf +
				',     [Business] = ''' + cb.Business + '''' + @crlf +
				',' + '[Contab] = ''' + cb.Contab + '''' + @crlf +
				',' + '[Category] = ''' + cb.Category + '''' + @crlf +
				',' + '[TypeQuery] = [TypeQuery] ' + @crlf +
				',' + '[LocationCost] = [LocationCost] ' + @crlf +
				',' + '[Area] = [Area] ' + @crlf +
				',' + '[TypeData] = [TypeData] ' + @crlf +
				',' + '[StyleDivision] = [StyleDivision] ' + @crlf +
				',' + '[Total] = SUM( ISNULL([' + cb.FieldName + '],0) )' 	+	@crlf +
				',' + '[FormatData] = CAST(''' + cb.FormatData + ''' AS VARCHAR(50))' + @crlf +
				'FROM #TB_DATA_RM' + @crlf +
				'group by [LocationCost],[Area],[TypeData],[StyleDivision],[TypeQuery],[DateInventory]' + @crlf +
				'UNION ALL' + @crlf
			FROM #CategoryBusiness cb

			SET @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL' + @crlf))			-- Quitar el último UNION ALL

			-- PRINT @sql;
-- select CONTAB,Category,FieldName,'Tabla greige' as tb from #CategoryBusiness
-- return

			
			
			INSERT INTO #TB_STD_ALL (
				[DateInventory],[TypeProces],[Business],[Contab],[Category],
				[TypeQuery],[LocationCost],[Area],[TypeData],[StyleDivision],
				[Total],[FormatData]
			) EXEC sp_executesql @sql


			UPDATE s
			SET    s.[Clasificacion] = cl.[Clasificacion]
			FROM   #TB_STD_ALL s
			LEFT JOIN #TB_Clasificacion cl ON s.[LocationCost] = cl.[LocationCost]

			UPDATE s
			SET    s.[CtaCosto]  = cc.[CtaCosto]
			      ,s.[DesCuenta] = cc.[DesCuenta]
			FROM   #TB_STD_ALL s
			LEFT JOIN #TB_CuentasContables cc ON s.[Contab] = cc.[Category]

			UPDATE s
			SET    s.[CuentaInventario] = CASE
			           WHEN s.[Clasificacion] = 'Wip' AND s.[TypeData] = 'LCA'                                            THEN '1210-000-00'
			           WHEN s.[Clasificacion] = 'Wip' AND s.[TypeData] = 'SEMI'                                           THEN '1210-000-01'    --'1210-000-00' -- Futuro: '1210-000-01'
			           WHEN s.[Clasificacion] = 'Finish Good' AND s.[TypeData] = 'LCA'                                    THEN '1216-000-00'
			           WHEN s.[Clasificacion] = 'Finish Good' AND s.[TypeData] = 'SEMI' AND s.[StyleDivision] = 'Headwear' THEN '1221-000-00'
			           WHEN s.[Clasificacion] = 'Finish Good' AND s.[TypeData] = 'SEMI' AND s.[StyleDivision] = 'Apparel'  THEN '1220-000-00'
			       END
			FROM   #TB_STD_ALL s

			UPDATE s
			SET    s.[DescripcionCuentaInventario] = CASE s.[CuentaInventario]
			           WHEN '1210-000-00' THEN 'PROCESO DE CORTE'
			           WHEN '1210-000-01' THEN 'PROCESO SEMIELABORADO'  -- Futuro
			           WHEN '1216-000-00' THEN 'INVENTARIO DE PRODUCTO TERMINADO'
			           WHEN '1220-000-00' THEN 'INVENTARIO DE PRODUCTO SEMIELABORADO'
			           WHEN '1221-000-00' THEN 'INVENTARIO DE GORRAS SEMIELABORADAS'
			       END
			FROM   #TB_STD_ALL s


			SELECT * FROM #TB_STD_ALL
			ORDER BY [DateInventory] DESC, [TypeProces] DESC, [Business], [Contab], [Category], [TypeQuery], [LocationCost], [Area], [TypeData], [StyleDivision]

			RETURN
			
			
			-- INSERT INTO #CategoryBusiness_global
			-- select 
			-- 	TypeInventory = 'DataGreigeItems'
			-- 	,*
			
			-- from #CategoryBusiness
			
			-- RETURN
			
			-- truncate table  AppsLCA.dbo.Financial_WIP_Pivot_Global
			INSERT INTO AppsLCA.dbo.Financial_WIP_Pivot_Global
				    ([MonthlyCloseID]
				    ,[DateInventory]
				    ,[TypeProces]
				    ,[Business]
				    ,[Contab]
				    ,[Category]
				    ,[TypeQuery]
				    ,[LocationCost]
				    ,[Area]
				    ,[TypeData]
				    ,[StyleDivision]
				    ,[Total]
				    ,[FormatData]
				    ,[Clasificacion]
				    ,[CtaCosto]
				    ,[DesCuenta]
				    ,[CuentaInventario]
				    ,[DescripcionCuentaInventario])
				SELECT
				     4
				    ,[DateInventory]
				    ,[TypeProces]
				    ,[Business]
				    ,[Contab]
				    ,[Category]
				    ,[TypeQuery]
				    ,[LocationCost]
				    ,[Area]
				    ,[TypeData]
				    ,[StyleDivision]
				    ,[Total]
				    ,[FormatData]
				    ,[Clasificacion]
				    ,[CtaCosto]
				    ,[DesCuenta]
				    ,[CuentaInventario]
				    ,[DescripcionCuentaInventario]
				FROM #TB_STD_ALL
				ORDER BY [DateInventory] DESC, [TypeProces] DESC,
				         [Business], [Contab], [Category],
				         [TypeQuery], [LocationCost], [Area],
				         [TypeData], [StyleDivision]
			
			-- SELECT * FROM #CategoryBusiness_global
			
			-- SELECT * FROM #CategoryBusiness
			
			RETURN
			
			
			
			-- ----------DESCRIPCION DE PROCESO SEGUN TABLA Y MES---------------
			
			-- DROP TABLE IF EXISTS #TB_OrderData
			-- DROP TABLE IF EXISTS #TB_OrderLocation
			
			-- CREATE TABLE #TB_OrderData (
			-- 	 [OrderData] INT
			-- 	,[Contab]    VARCHAR(50)
			-- 	,[Category]  VARCHAR(100)
			-- )
			-- INSERT INTO #TB_OrderData ([OrderData],[Contab],[Category]) VALUES
			-- 	 ( 1, 'Labor'              , 'Cut Labor'                                  )
			-- 	,( 2, 'Labor'              , 'Sew Labor'                                  )
			-- 	,( 3, 'Labor'              , 'Pack Labor'                                 )
			-- 	,( 4, 'Labor'              , 'Sublimation Labor'                          )
			-- 	,( 5, 'Labor'              , 'ScreenPrint Labor'                          )
			-- 	,( 6, 'Labor'              , 'Labor Embroidery Apparel'                   )
			-- 	,( 7, 'Labor'              , 'Labor Embroidery Headwear'                  )
			-- 	,( 8, 'Packing'            , 'Supplies Mat'                               )
			-- 	,( 9, 'Screen Print'       , 'ScreenPrint Mat'                            )
			-- 	,(10, 'Sublimation'        , 'Sublimation'                                )
			-- 	,(11, 'Tela'               , 'Fabric Mat'                                 )
			-- 	,(12, 'Tela'               , 'Fabric Embroidery Apparel'                  )
			-- 	,(13, 'Tela'               , 'Fabric Embroidery Headwear'                 )
			-- 	,(14, 'Trims'              , 'Thread Mat'                                 )
			-- 	,(15, 'Trims'              , 'Trim Mat'                                   )
			-- 	,(16, 'Trims'              , 'Thread Embroidery Apparel'                  )
			-- 	,(17, 'Trims'              , 'Thread Embroidery Headwear'                 )
			-- 	,(18, 'Washing'            , 'Washing'                                    )
			-- 	,(19, 'Contracts Headwear' , 'Total Contracts Headwear'                   )
			-- 	,(20, 'Contracts Headwear' , 'Total Contracts Headwear RawMaterials'      )
			-- 	,(21, 'Contracts Apparel'  , 'Total Contracts Apparel'                    )
			-- 	,(22, 'Contracts Apparel'  , 'Total Contracts Apparel RawMaterials'       )
			-- 	,(23, 'Total Units'        , 'Total Quantity LCA'                         )
			-- 	,(24, 'Total Units'        , 'Total Quantity SEMI Apparel'                )
			-- 	,(25, 'Total Units'        , 'Total Quantity SEMI Headwear'               )
			-- 	,(26, 'Total Units'        , 'Total Quantity SEMI Apparel RawMaterials'   )
			-- 	,(27, 'Total Units'        , 'Total Quantity SEMI Headwear RawMaterials'  )
			-- 	,(28, 'Units'              , 'Total Garment Sublimation'                  )
			-- 	,(29, 'Units'              , 'Total Garment ScreenPrint'                  )
			-- 	,(30, 'Units'              , 'Total Garment Embroidery Headwear'          )
			-- 	,(31, 'Units'              , 'Total Garment Embroidery Apparel'           )
			-- 	,(32, 'Decoration'         , 'Total PrintCount Sublimation'               )
			-- 	,(33, 'Decoration'         , 'Total PrintCount ScreenPrint'               )
			-- 	,(34, 'Decoration'         , 'Total EmbroideryCount Headwear'             )
			-- 	,(35, 'Decoration'         , 'Total Embroidery Count Apparel'             )

			-- CREATE TABLE #TB_OrderLocation (
			-- 	 [OrderData]    INT
			-- 	,[LocationCost] VARCHAR(100)
			-- )
			-- INSERT INTO #TB_OrderLocation ([OrderData],[LocationCost]) VALUES
			-- 	 ( 1, 'CorteTela'          )
			-- 	,( 2, 'Corte'              )
			-- 	,( 3, 'Costura'            )
			-- 	,( 4, 'Sublimado'          )
			-- 	,( 5, 'Serigrafia'         )
			-- 	,( 6, 'Bordado Prendas'    )
			-- 	,( 7, 'Bordado Gorras'     )
			-- 	,( 8, 'Empaque'            )
			-- 	,( 9, 'WH PT'              )
			-- 	,(10, 'WH RO'              )
			-- 	,(11, 'Headwear DLI'       )
			-- 	,(12, 'WH First Semi Finish')
			-- 	,(13, 'Greige Items'       )

			-- 	-- SELECT * FROM #TB_OrderData
			-- 	-- SELECT * FROM #TB_OrderLocation
			
			-- -- SELECT * FROM        #TB_STD_ALL  AS S
			
			
			-- SELECT
			-- 	 [R]                    = ROW_NUMBER() OVER (ORDER BY S.[DateInventory],S.[Clasificacion] DESC,S.[TypeData],ord.[OrderData],loc.[OrderData])
			-- 	,[DateInventory]        = S.[DateInventory]
			-- 	,[Clasificacion]        = S.[Clasificacion]
			-- 	,[TypeData]             = S.[TypeData]
			-- 	,[StyleDivision]        = S.[StyleDivision]
			-- 	,[Contab]               = S.[Contab]
			-- 	,[Category]             = S.[Category]
			-- 	,[TypeQuery]            = S.[TypeQuery]
			-- 	,[LocationCost]         = S.[LocationCost]
			-- 	,[Formula]              = CAST(NULL AS VARCHAR(MAX))
			-- 	,[Description]          = CAST(NULL AS VARCHAR(MAX))
			-- 	,[DescriptionSpanish]   = CAST(NULL AS VARCHAR(MAX))
			-- -- INTO [AppsLCA].[dbo].[Financial_MonthlyClose_Description]
			-- FROM        #TB_STD_ALL         AS S
			-- LEFT JOIN   #TB_OrderData       AS ord ON ord.[Contab] = S.[Contab] AND ord.[Category] = S.[Category]
			-- LEFT JOIN   #TB_OrderLocation   AS loc ON loc.[LocationCost] = S.[LocationCost]
			-- WHERE S.[DateInventory] = '2026-04-30'
			-- AND s.[contab] NOT IN ('Units','Decoration')
			-- GROUP BY
			-- 	 S.[DateInventory]
			-- 	 ,S.[Clasificacion]
			-- 	,S.[Contab]
			-- 	,S.[Category]
			-- 	,S.[TypeQuery]
			-- 	,S.[LocationCost]
			-- 	,S.[TypeData]
			-- 	,S.[StyleDivision]
			-- 	,ord.[OrderData]
			-- 	,loc.[OrderData]
			
				
			
			
			
/*			
OrdenData	  LocationCost		
1	         'CorteTela'
2	         'Corte'
3	         'Costura'
4	         'Sublimado'
5	         'Serigrafia'
6	         'Bordado Prendas'
7	         'Bordado Gorras'
8	         'Empaque'
9	         'WH PT'
10	         'WH RO'
11	         'Headwear DLI'
12	         'WH First Semi Finish'
13	         'Greige Items'
*/
			
			
			
			
			
			
/*
			
OrderData       Contab	                     Dato
1		     ,'Labor'	                ,'Cut Labor'
2		     ,'Labor'	                ,'Sew Labor'
3		     ,'Labor'	                ,'Pack Labor'
4		     ,'Labor'	                ,'Sublimation Labor'
5		     ,'Labor'	                ,'ScreenPrint Labor'
6		     ,'Labor'	                ,'Labor Embroidery Apparel'
7		     ,'Labor'	                ,'Labor Embroidery Headwear'
8		     ,'Packing'	                ,'Supplies Mat'
9		     ,'Screen Print'	        ,'ScreenPrint Mat'
10		     ,'Sublimation'	            ,'Sublimation'
11		     ,'Tela'	                ,'Fabric Mat'
12		     ,'Tela'	                ,'Fabric Embroidery Apparel'
13		     ,'Tela'	                ,'Fabric Embroidery Headwear'
14		     ,'Trims'	                ,'Thread Mat'
15		     ,'Trims'	                ,'Trim Mat'
16		     ,'Trims'	                ,'Thread Embroidery Apparel'
17		     ,'Trims'	                ,'Thread Embroidery Headwear'
18		     ,'Washing'	                ,'Washing'
19		     ,'Contracts Headwear'	    ,'Total Contracts Headwear'
20		     ,'Contracts Headwear'	    ,'Total Contracts Headwear RawMaterials'
21		     ,'Contracts Apparel'	    ,'Total Contracts Apparel'
22		     ,'Contracts Apparel'	    ,'Total Contracts Apparel RawMaterials'
23		     ,'Total Units'	            ,'Total Quantity LCA'
24		     ,'Total Units'	            ,'Total Quantity SEMI Apparel'
25		     ,'Total Units'	            ,'Total Quantity SEMI Headwear'
26		     ,'Total Units'	            ,'Total Quantity SEMI Apparel RawMaterials'
27		     ,'Total Units'	            ,'Total Quantity SEMI Headwear RawMaterials'
28		     ,'Units' 	                ,'Total Garment Sublimation'
29		     ,'Units' 	                ,'Total Garment ScreenPrint'
30		     ,'Units' 	                ,'Total Garment Embroidery Headwear'
31		     ,'Units' 	                ,'Total Garment Embroidery Apparel'
32		     ,'Decoration' 	            ,'Total PrintCount Sublimation'
33		     ,'Decoration' 	            ,'Total PrintCount ScreenPrint'
34		     ,'Decoration' 	            ,'Total EmbroideryCount Headwear'
35		     ,'Decoration' 	            ,'Total Embroidery Count Apparel'

			
	*/		
			
			
			
-- DescripcionCuentaInventario	CuentaInventario
-- PROCESO DE CORTE	1210-000-00
-- INVENTARIO DE PRODUCTO TERMINADO	1216-000-00
-- INVENTARIO DE PRODUCTO SEMIELABORADO	1220-000-00
-- INVENTARIO DE GORRAS SEMIELABORADAS	1221-000-00
/*
Cuenta:1210-000-00
Descripcion: PROCESO DE CORTE	
Todo lo filtrado en clasificacion como "Wip"

Cuenta:1216-000-00
Descripcion: INVENTARIO DE PRODUCTO TERMINADO
Todo lo filtrado en clasificacion como "Finish Good"
y TypeData = "LCA"

Cuenta:1221-000-00
Descripcion: INVENTARIO DE GORRAS SEMIELABORADAS
Todo lo filtrado en clasificacion como "Finish Good"
y TypeData = "SEMI" 
y StyleDivision = "Headwear"

Cuenta:1220-000-00
Descripcion: INVENTARIO DE PRODUCTO SEMIELABORADO
Todo lo filtrado en clasificacion como "Finish Good"
y TypeData = "SEMI" 
y StyleDivision = "Apparel"
*/
    -- SELECT DISTINCT WorkFlow,TypeQuery 
    -- FROM [AppsLCA].[dbo].[Financial_MonthlyClose_WIP] AS S WITH(NOLOCK)
    -- WHERE
	-- 	--         S.LocationCost 	<> 'NO WIP'
	-- 	--     AND S.LocationCost <> 'WH NOT INCLUDED'
	-- 	-- AND S.DateInventory	        = '2026-04-30'
	-- 	-- AND S.DateInventoryComment  = 'New_Model_V2'

    -- -- AND 
    -- [LocationCost] = 'NO LOCATION'
    
    
    --  select * FROM [AppsLCA].[dbo].[Financial_MonthlyClose_WIP] AS S WITH(NOLOCK)
    -- WHERE
    -- [LocationCost] = 'NO LOCATION'
		
    
    
    -- -- update s set [LocationCost] = 'Bordado Gorras'
    -- -- update s set [LocationCost] = 'Bordado Prendas'
    -- update s set 
    --     [LocationCost] = 'Serigrafia'
    --     ,[Area] = 'Picking Area'
    -- -- select *
    -- FROM [AppsLCA].[dbo].[Financial_MonthlyClose_WIP] AS S WITH(NOLOCK)
    -- WHERE
	-- 	  [LocationCost] = 'NO LOCATION'
    -- and
    -- WorkFlow in (
    --     'Print 1 Screen printing From Finish Good  Y202505 TKU'
    -- )
    

    
    
    -- update s set [LocationCost] = 'Bordado Gorras'
    -- -- update s set [LocationCost] = 'Bordado Prendas'
    -- -- update s set [LocationCost] = 'Serigrafia'
    -- FROM [AppsLCA].[dbo].[Financial_MonthlyClose_WIP] AS S WITH(NOLOCK)
    -- WHERE
	-- 	        S.LocationCost 	<> 'NO WIP'
	-- 	    AND S.LocationCost <> 'WH NOT INCLUDED'
	-- 	AND S.DateInventory	        = '2026-04-30'
	-- 	AND S.DateInventoryComment  = 'New_Model_V2'

    -- AND [LocationCost] = 'NO LOCATION'
    -- and
    -- WorkFlow in (
    --     '1 Embroidery  Headwear Patch Laser Cutting + 1 Hight Definition Print Y202611 TKU'
    --     ,'1 Embroidery  Headwear Y202611 TKU'
    --     --  '1 Embroidery Re-label  From Finish Good  Y202612 TKU'
    --     -- ,'Embroidery From Finish Good 1 Y202612 TKU'
    --     --  '1 Print SP Re-label From Finish Good  BLOCK N Y311025'
    --     -- ,'Print 1 Screen printing From Finish Good  Y202505 TKU'
    --     -- ,'Print 2 Screen printing From Finish Good  Y202505 TKU'
    -- )
    
    -- -- update s set [LocationCost] = 'Bordado Gorras'
    -- update s set [LocationCost] = 'Bordado Prendas'
    -- -- update s set [LocationCost] = 'Serigrafia'
    -- FROM [AppsLCA].[dbo].[Financial_MonthlyClose_WIP] AS S WITH(NOLOCK)
    -- WHERE
	-- 	        S.LocationCost 	<> 'NO WIP'
	-- 	    AND S.LocationCost <> 'WH NOT INCLUDED'
	-- 	AND S.DateInventory	        = '2026-04-30'
	-- 	AND S.DateInventoryComment  = 'New_Model_V2'

    -- AND [LocationCost] = 'NO LOCATION'
    -- and
    -- WorkFlow in (
    --     -- '1 Embroidery  Headwear Patch Laser Cutting + 1 Hight Definition Print Y202611 TKU'
    --     -- ,'1 Embroidery  Headwear Y202611 TKU'
    --      '1 Embroidery Re-label  From Finish Good  Y202612 TKU'
    --     ,'Embroidery From Finish Good 1 Y202612 TKU'
    --     --  '1 Print SP Re-label From Finish Good  BLOCK N Y311025'
    --     -- ,'Print 1 Screen printing From Finish Good  Y202505 TKU'
    --     -- ,'Print 2 Screen printing From Finish Good  Y202505 TKU'
    -- )
    
    -- -- update s set [LocationCost] = 'Bordado Gorras'
    -- -- update s set [LocationCost] = 'Bordado Prendas'
    -- update s set [LocationCost] = 'Serigrafia'
    -- FROM [AppsLCA].[dbo].[Financial_MonthlyClose_WIP] AS S WITH(NOLOCK)
    -- WHERE
	-- 	        S.LocationCost 	<> 'NO WIP'
	-- 	    AND S.LocationCost <> 'WH NOT INCLUDED'
	-- 	AND S.DateInventory	        = '2026-04-30'
	-- 	AND S.DateInventoryComment  = 'New_Model_V2'

    -- AND [LocationCost] = 'NO LOCATION'
    -- and
    -- WorkFlow in (
    --     -- '1 Embroidery  Headwear Patch Laser Cutting + 1 Hight Definition Print Y202611 TKU'
    --     -- ,'1 Embroidery  Headwear Y202611 TKU'
    --     --  '1 Embroidery Re-label  From Finish Good  Y202612 TKU'
    --     -- ,'Embroidery From Finish Good 1 Y202612 TKU'
    --      '1 Print SP Re-label From Finish Good  BLOCK N Y311025'
    --     ,'Print 1 Screen printing From Finish Good  Y202505 TKU'
    --     ,'Print 2 Screen printing From Finish Good  Y202505 TKU'
    --     ,'2 Print SP Re-label From Finish Good Y202626 TKU'
    -- )
    
