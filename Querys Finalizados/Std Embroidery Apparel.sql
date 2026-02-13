USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_Std_TimeHeadWearN]    Script Date: 21/07/2025 09:18:06 a. m. ******/
-- SET ANSI_NULLS ON
-- GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_Std_TimeApparel]
	 @process		NVARCHAR(MAX)
	,@data			NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @result     AS NVARCHAR(MAX)
    DECLARE @result2    AS NVARCHAR(MAX) = ''
    DECLARE @FinalComponent AS NVARCHAR(MAX) = ''
	DECLARE @Error		AS BIT
    DECLARE @Msg AS NVARCHAR(MAX) = ''
	-- DECLARE @process		NVARCHAR(MAX)
	-- DECLARE @data			NVARCHAR(MAX)


	--SET @process = 'selects.list'
	--SET @data = '{"selectedOptions":[]}'

	-- SET @process = 'data.Flex'
	-- SET @data = '{"selectedOptions":[{"FechaIni":"2025-11-05","FechaFin":"2025-11-05","Equipo":"","Bordadora":""}]}'

	-- SET @process = 'data.PONumber'
	-- SET @data = '{"selectedOptions":[{"FechaIni":"","FechaFin":"","Equipo":"","Bordadora":"","PONumber":"ORD-5206478"}]}'

	IF @process = 'selects.list'
	BEGIN
		SET @result = 
					(
						SELECT DISTINCT 
							CompanyName = IIF(CHARINDEX('#',CompanyName) > 0 AND CompanyName NOT LIKE 'Sample%',CONCAT('EM',SUBSTRING(CompanyName,CHARINDEX('#',CompanyName) + 2, LEN(CompanyName))),CompanyName)
						FROM LCA.dbo.Addresses WITH(NOLOCK) 
						WHERE ProductionTaskName in ('Finish Embroidery 1','Finish Embroidery 2','Finish Embroidery 3','Finish Embroidery 4', 'Finish Embroidery 5')
						FOR JSON PATH, INCLUDE_NULL_VALUES
					)

		SET @result2 =
					 (
						SELECT 
							*
						FROM OPENQUERY(MARIADB,'SELECT DISTINCT Bordadora FROM wordpress.StdTimeEmbroidery')
						ORDER BY Bordadora
						FOR JSON PATH, INCLUDE_NULL_VALUES
					 )

		SET @Error = 0
		SET @FinalComponent = '[Completed]'
		SET @Msg = 'Datos obtenidos correctamente'

	END
	
	DECLARE @FechaInicial	DATE		= (SELECT CASE WHEN JSON_VALUE(@data, '$.selectedOptions[0].FechaIni')= '' THEN NULL ELSE JSON_VALUE(@data, '$.selectedOptions[0].FechaIni') END)
	DECLARE @FechaFinal		DATE		= (SELECT CASE WHEN JSON_VALUE(@data, '$.selectedOptions[0].FechaFin') = '' THEN NULL ELSE JSON_VALUE(@data, '$.selectedOptions[0].FechaFin') END)
	DECLARE @Equipo			VARCHAR(50) = (SELECT CASE WHEN JSON_VALUE(@data, '$.selectedOptions[0].Equipo') = '' THEN NULL ELSE JSON_VALUE(@data, '$.selectedOptions[0].Equipo') END)
	DECLARE @Bordadora		VARCHAR(50) = (SELECT CASE WHEN JSON_VALUE(@data, '$.selectedOptions[0].Bordadora') = '' THEN NULL ELSE JSON_VALUE(@data, '$.selectedOptions[0].Bordadora') END)
	DECLARE @PONumber		VARCHAR(50) = (SELECT CASE WHEN JSON_VALUE(@data, '$.selectedOptions[0].PONumber') = '' THEN NULL ELSE JSON_VALUE(@data, '$.selectedOptions[0].PONumber') END)
	

		------------BORRO LAS TABLAS TEMPORALES------------
		---------------------------------------------------
			DROP TABLE IF EXISTS #TB_ProdEM
			DROP TABLE IF EXISTS #TB_ProdEM_Final
			DROP TABLE IF EXISTS #TB_Loc
			DROP TABLE IF EXISTS #TB_Maria
			DROP TABLE IF EXISTS #TB_Final
			DROP TABLE IF EXISTS #TB_DateTransactions

		------------CREO LAS TABLAS TEMPORALES-------------
		---------------------------------------------------

		CREATE TABLE #TB_ProdEM (
			 PONumber           VARCHAR(100)			
			,OrderID           	INT
			,MO        			VARCHAR(100)
			,CompanyName        VARCHAR(100)
			,Equipo      		VARCHAR(100)
			,StyleNumber        VARCHAR(100)
			,StyleColorName     VARCHAR(100)
			,Turno              VARCHAR(10)
			,ChangeDate         DATE
			,FechaAjustada      DATE
			,TaskName           VARCHAR(100)
			,[#Ciclos]          INT
			,Quantity           INT
			,ConteoPONumber     INT
			,Muestra			FLOAT
			,Machine     		VARCHAR(MAX)
			,Make           	INT
		);
		
		CREATE INDEX IDX_TB_ProdEMH_TaskName_PONumber ON #TB_ProdEM (TaskName, PONumber);

		CREATE TABLE #TB_Loc (
			 PoNumber		VARCHAR(50)   -- N�mero de orden
			,OrderID		INT            -- N�mero de localizaci�n
			,[DescripValue]	VARCHAR(100)  -- Ubicaci�n o tipo de bordado
			,[MachineValue]	VARCHAR(MAX)  -- Ubicaci�n o tipo de bordado
			,Loca1			INT            -- N�mero de localizaci�n
		);
		
		CREATE INDEX IDX_TB_Loc_PoNumber_Loca1 ON #TB_Loc (PoNumber, Loca1);

		CREATE TABLE #TB_Maria (
			ID					INT,
			CreateDate			DATE,
			[Order]				VARCHAR(50),
			Equipo				VARCHAR(50),
			Bordadora			VARCHAR(50),
			CantidadDePuntadas	INT,
			Secuencias			INT,
			Apliques			INT,
			TipoDePellum		VARCHAR(50),
			CostingCode			VARCHAR(50),
			Localidad			VARCHAR(50),
			Estilo				VARCHAR(50),
			SetUP				FLOAT,
			TCicloIndiv			FLOAT,
			OrderID				INT,
			Cabezales			INT,
			rn					INT,
			Conteo				INT
		);
	
		CREATE INDEX IDX_TB_Maria_Order_Localidad ON #TB_Maria ([Order], Localidad);

		---------INSERT EN LAS TABLAS TEMPORALES-------------
		---------------------------------------------------
		INSERT INTO #TB_ProdEM
		
		SELECT
			 PONumber					= ORD.PONumber
			,OrderID					= ORD.OrderID
			,MO							= MO.ManufactureNumber
			-- ,PPBU						= 'PPBU' + LTRIM(STR(b.BundleID + 10000000))
			,CompanyName				= ISNULL(TADD1.CompanyName, '')					 
			,Equipo = IIF(CHARINDEX('#',CompanyName) > 0 AND CompanyName NOT LIKE 'Sample%',CONCAT('EM',SUBSTRING(CompanyName,CHARINDEX('#',CompanyName) + 2, LEN(CompanyName))),CompanyName)
			-- ,PPAD						= 'PPAD' + LTRIM(STR(TADD1.AddressID + 10000))	 
			-- ,StatusID					= st.StatusID									 
			-- ,StatusName					= st.StatusName									 
			,StyleNumber				= s.StyleNumber									 
			,StyleColorName				= sc.StyleColorName								 
			-- ,QuantityOrdered			= CAST(b.QuantityOrdered AS int)					  
			,Turno						= CASE 
											WHEN DATEPART(HOUR, ChangeDate) >= 6 AND DATEPART(HOUR, ChangeDate) < 18 THEN 'DÍA'
											ELSE 'NOCHE'
										END
			,ChangeDate					= CAST(CHLog.ChangeDate AS DATE)
			,FechaAjustada				= CASE 
											WHEN DATEPART(HOUR, ChangeDate) < 6 AND 
											(DATEPART(HOUR, ChangeDate) >= 18 OR DATEPART(HOUR, ChangeDate) < 6) THEN DATEADD(DAY, -1, CAST (ChangeDate AS DATE))
											ELSE CAST (ChangeDate AS DATE)
										END 
			,TaskName					= t.TaskName										 
			,[#Ciclos]					= CAST(NULL AS DECIMAL)
			,Quantity					= IIF(t.TaskName LIKE 'Start%',0,CAST(wt.Quantity AS int)) 
			,ConteoPONumber				= ROW_NUMBER() OVER (PARTITION BY ORD.PONumber,T.TaskName ORDER BY CHLog.ChangeDate)
			,Muestra					= NULL
			,Machine					= case when len(ltrim(ORD.Comments28))<3 then 
											concat('Bordadora #',RIGHT(REPLICATE('0',2)+ORD.Comments28,2)) 
											else 
											concat('Bordadora #',RIGHT(REPLICATE('0',3)+ORD.Comments28,3)) 
											end
			,Make						= IIF(t.TaskName LIKE 'Start%',0,CAST(MO.QuantityOrdered AS int))
			-- ,CHLog.ChangeDate
		FROM			[lca].[dbo].[Bundles]			AS b		WITH(NOLOCK)
		INNER JOIN		[lca].[dbo].[ManufactureOrders]	AS mo		WITH(NOLOCK) ON b.ManufactureID		= mo.ManufactureID AND MO.StatusID < 95
		INNER JOIN		[lca].[dbo].[WorkTransactions]	AS wt		WITH(NOLOCK) ON b.BundleID			= wt.BundleID--wt.OperatorID		= TADD1.AddressID
		INNER JOIN		[lca].[dbo].[WorkTasks]			AS t		WITH (NOLOCK) ON wt.TaskID			= t.TaskID  AND t.taskname IN 
		('Finish Embroidery 1','Finish Embroidery 2','Finish Embroidery 3','Finish Embroidery 4', 'Finish Embroidery 5'
		,'Start Embroidery 1','Start Embroidery 2','Start Embroidery 3','Start Embroidery 4', 'Start Embroidery 5'
		)
		INNER JOIN		[lca].[dbo].[ChangeLog]			AS CHLog	WITH(NOLOCK) ON wt.ChangeLogID		= CHLog.ChangeLogID --AND CHLog.ChangeDate>='2024-01-01'
		LEFT OUTER JOIN [lca].[dbo].[OrderItems]		AS ORDi		WITH(NOLOCK) ON mo.FirstOrderItemID	= ORDi.OrderItemID
		LEFT OUTER JOIN [lca].[dbo].[Orders]			AS ORD		WITH(NOLOCK) ON ORDi.OrderID		= ORD.OrderID 
		INNER JOIN		[lca].[dbo].[Styles]			AS s		WITH(NOLOCK) ON ordi.StyleID		= s.StyleID
		INNER JOIN		[lca].[dbo].[StyleColors]		AS sc		WITH(NOLOCK) ON ordi.StyleColorID	= sc.StyleColorID
		LEFT OUTER JOIN	[lca].[dbo].[Addresses]			AS TADD1	WITH(NOLOCK) ON wt.OperatorID		= TADD1.AddressID --ORD-3530610
		LEFT OUTER JOIN	[lca].[dbo].[StatusNames]		AS st		WITH(NOLOCK) ON st.StatusID			= t.StatusID


		SELECT
			 OrderID					= ORD.OrderID
			,PONumber					= ORD.PONumber
			,ChangeDate 				= CHLog.ChangeDate
		INTO #TB_DateTransactions
		FROM			[lca].[dbo].[Bundles]			AS b		WITH(NOLOCK)
		INNER JOIN		[lca].[dbo].[ManufactureOrders]	AS mo		WITH(NOLOCK) ON b.ManufactureID		= mo.ManufactureID AND MO.StatusID < 95
		INNER JOIN		[lca].[dbo].[WorkTransactions]	AS wt		WITH(NOLOCK) ON b.BundleID			= wt.BundleID--wt.OperatorID		= TADD1.AddressID
		INNER JOIN		[lca].[dbo].[WorkTasks]			AS t		WITH (NOLOCK) ON wt.TaskID			= t.TaskID  AND t.taskname IN 
		('Finish Embroidery 1','Finish Embroidery 2','Finish Embroidery 3','Finish Embroidery 4', 'Finish Embroidery 5'
		,'Start Embroidery 1','Start Embroidery 2','Start Embroidery 3','Start Embroidery 4', 'Start Embroidery 5'
		)
		INNER JOIN		[lca].[dbo].[ChangeLog]			AS CHLog	WITH(NOLOCK) ON wt.ChangeLogID		= CHLog.ChangeLogID 
		LEFT OUTER JOIN [lca].[dbo].[OrderItems]		AS ORDi		WITH(NOLOCK) ON mo.FirstOrderItemID	= ORDi.OrderItemID
		LEFT OUTER JOIN [lca].[dbo].[Orders]			AS ORD		WITH(NOLOCK) ON ORDi.OrderID		= ORD.OrderID 
		INNER JOIN		[lca].[dbo].[Styles]			AS s		WITH(NOLOCK) ON ordi.StyleID		= s.StyleID
		INNER JOIN		[lca].[dbo].[StyleColors]		AS sc		WITH(NOLOCK) ON ordi.StyleColorID	= sc.StyleColorID
		LEFT OUTER JOIN	[lca].[dbo].[Addresses]			AS TADD1	WITH(NOLOCK) ON wt.OperatorID		= TADD1.AddressID --ORD-3530610
		LEFT OUTER JOIN	[lca].[dbo].[StatusNames]		AS st		WITH(NOLOCK) ON st.StatusID			= t.StatusID
		-- WHERE ord.PONumber = 'ORD-5077519'		
		
		INSERT INTO #TB_Loc
		SELECT
			PONumber
			,OrderID
			,DescripValue
			,case when len(ltrim(MachineValue))<3 then 
											concat('Bordadora #',RIGHT(REPLICATE('0',2)+MachineValue,2)) 
											else 
											concat('Bordadora #',RIGHT(REPLICATE('0',3)+MachineValue,3)) 
											end
			,ROW_NUMBER() OVER(PARTITION BY OrderID ORDER BY OrderID,rn) AS Loca1
		FROM
		(
			SELECT
				ord.PONumber
				,ord.OrderID
				,ord.OrderTypeID4
				,ISNULL(LTRIM(RTRIM(jm.value)),'') 				AS MachineValue
				,ISNULL(LTRIM(RTRIM(jl.value)),'') 				AS DescripValue
				,ROW_NUMBER() OVER(PARTITION BY OrderID ORDER BY OrderID) AS rn

			FROM lca.dbo.DropDownValues5 AS DR5 WITH(NOLOCK)
					INNER JOIN lca.dbo.Orders AS ORD WITH(NOLOCK)
						ON ord.OrderTypeID4 = dr5.DropDownValueID
						
			-- 1) Expandimos la columna ancla (LocationDesc)
			CROSS APPLY OPENJSON(
				'["' + REPLACE(STRING_ESCAPE(ISNULL(dr5.Description,''),  'json'), ',', '","') + '"]'
			) AS jl
			-- 2) Tomamos el elemento con la misma clave en cada columna (permitiendo faltantes con OUTER APPLY)
			OUTER APPLY (
				SELECT value FROM OPENJSON('["' + REPLACE(STRING_ESCAPE(ISNULL(ord.Comments28,''), 'json'), ',', '","') + '"]')
				WHERE [key] = jl.[key]
			) AS jm
			--WHERE PONumber = 'ORD-5067594'
		)AS TB

		-- SELECT
		-- 	PONumber
		-- 	,DescripValue
		-- 	,case when len(ltrim(MachineValue))<3 then 
		-- 									concat('Bordadora #',RIGHT(REPLICATE('0',2)+MachineValue,2)) 
		-- 									else 
		-- 									concat('Bordadora #',RIGHT(REPLICATE('0',3)+MachineValue,3)) 
		-- 									end
		-- 	,ROW_NUMBER() OVER(PARTITION BY ponumber ORDER BY ponumber,DescripValue) AS Loca1
		-- FROM
		-- (
		-- 	SELECT
		-- 		PoNumber,
		-- 		DescripSplit.value AS DescripValue,
		-- 		MachineSplit.value AS MachineValue,
		-- 		ROW_NUMBER() OVER(PARTITION BY ponumber,DescripSplit.value ORDER BY ponumber) AS rn
		-- 	FROM
		-- 	(
		-- 		SELECT
		-- 			ord.PONumber,
		-- 			ord.OrderTypeID4,
		-- 			dr5.Description AS Descrip,
		-- 			ord.Comments28 AS Machine
		-- 		FROM lca.dbo.DropDownValues5 AS DR5 WITH(NOLOCK)
		-- 		INNER JOIN lca.dbo.Orders AS ORD WITH(NOLOCK)
		-- 			ON ord.OrderTypeID4 = dr5.DropDownValueID
		-- 	) abc
		-- 	CROSS APPLY STRING_SPLIT(Descrip, ',') AS DescripSplit
		-- 	CROSS APPLY STRING_SPLIT(Machine, ',') AS MachineSplit
		-- 	WHERE PONumber = 'ORD-5172597'
		-- ) AS TB
		-- WHERE rn = 1


		INSERT INTO #TB_Maria
		SELECT 
			* 
		FROM OPENQUERY([MARIADB], '
			SELECT
				ID, 
				CreateDate,
				`Order`,
				Equipo,
				Bordadora,
				CantidadDePuntadas,
				Secuencias,
				Apliques,
				TipoDePellum,
				CostingCode,
				Localidad,
				Estilo,
				SetUP,
				TCicloIndiv, 
				OrderID,
				Cabezales,
				ROW_NUMBER() OVER(PARTITION BY `Order`, Localidad, Equipo ORDER BY CreateDate ASC) as rn,
				ROW_NUMBER() OVER(PARTITION BY `Order`, Localidad, Bordadora ORDER BY CreateDate ASC) as Conteo 
			FROM wordpress.StdTimeEmbroidery_New
			WHERE 
				Status is null
				
				') AS MARIA_DB_QUERY
			-- WHERE MARIA_DB_QUERY.rn = 1;
		
		UPDATE HW1 SET
		--select hw1.*,
			Muestra = CASE 
							WHEN TB.ConteoPOBordadora = 1 THEN TB.SetUP 
							ELSE 0 
						END
		--select * from #TB_Loc where ponumber = 'ORD-5088854'
		FROM #TB_ProdEM AS HW1
		LEFT JOIN
		(
			SELECT
				HW1.*
				,ROW_NUMBER() OVER(PARTITION BY PONumber, BordadoraMDB ORDER BY PONumber,ConteoPONumber) AS ConteoPOBordadora
			FROM
			(
				SELECT 
					HW1.*
					,STEMAR.Bordadora AS BordadoraMDB
					,STEMAR.SetUP AS SetUP
					-- ,COALESCE(STEMAR.Bordadora,STEMAR2.Bordadora) AS BordadoraMDB
					-- ,COALESCE(STEMAR.SetUP,STEMAR2.SetUP) AS SetUP
				--select *
				FROM			#TB_ProdEM		AS HW1
				LEFT  JOIN		#TB_Loc			AS HW2		ON HW1.OrderID						= HW2.OrderID and right(rtrim(HW1.TaskName),1) = HW2.Loca1
				LEFT  JOIN		#TB_Maria		AS STEMAR	ON CONCAT(HW1.PONumber,HW2.[DescripValue],HW1.Equipo) = CONCAT(STEMAR.[Order],STEMAR.Localidad,STEMAR.Equipo) AND STEMAR.rn = 1
				-- LEFT  JOIN		#TB_Maria		AS STEMAR2	ON CONCAT(HW1.PONumber,HW2.[DescripValue],HW2.MachineValue) = CONCAT(STEMAR2.[Order],STEMAR2.Localidad,STEMAR2.Bordadora) AND STEMAR2.Conteo = 1
				WHERE HW1.TaskName LIKE 'Start%'
				-- AND 
				-- HW1.PONumber = 'ORD-5067594'
			) AS HW1
		) AS TB ON HW1.PONumber = TB.PONumber AND HW1.ConteoPONumber = TB.ConteoPONumber AND HW1.TaskName = TB.TaskName
		-- where HW1.PONumber = 'ORD-5134283'

		SELECT
			 PONumber
			,OrderID
			,MO
			,CompanyName
			,Equipo
			,StyleNumber
			,StyleColorName
			,Turno
			,FechaAjustada
			-- ,ChangeDate
			,CAST(null AS datetime) AS ChangeDate
			,TaskName
			,#Ciclos
			,Machine
			,Make
			,SUM(Quantity) AS Quantity
			,SUM(Muestra) AS Muestra
			,ROW_NUMBER() OVER(PARTITION BY OrderID, TaskName, Equipo, FechaAjustada ORDER BY OrderID, TaskName, Equipo, FechaAjustada) AS RN
		INTO #TB_ProdEM_Final
		FROM #TB_ProdEM
		WHERE TaskName LIKE 'Finish%' OR Muestra <> 0
		GROUP BY
			 PONumber
			,OrderID
			,MO
			,CompanyName
			,Equipo
			,StyleNumber
			,StyleColorName
			,Turno
			,FechaAjustada
			-- ,ChangeDate
			,TaskName
			,#Ciclos
			,Machine
			,Make

		-- return
		UPDATE HW1 SET
		#Ciclos = CASE WHEN HW1.RN = 1 THEN CEILING(1.0 * HW1_Cons.Quantity / CAST(COALESCE(STEMAR.Cabezales,STEMAR2.Cabezales,PPM.Cabezales) AS INT)) ELSE 0 END
		-- select *
		FROM			
		(
			SELECT
				OrderID
				,PONumber
				,TaskName
				,Equipo
				,FechaAjustada
				,SUM(Quantity) AS Quantity
		 	FROM #TB_ProdEM_Final
			-- where PONumber = 'ORD-5206442'
			GROUP BY 
				OrderID
				,PONumber
				,TaskName
				,Equipo
				,FechaAjustada
		) AS HW1_Cons
		INNER JOIN		#TB_ProdEM_Final		AS HW1		ON HW1_Cons.OrderID = HW1.OrderID and HW1_Cons.TaskName = hw1.TaskName AND HW1_Cons.Equipo = HW1.Equipo AND HW1_Cons.FechaAjustada = HW1.FechaAjustada
		LEFT  JOIN		#TB_Loc					AS HW2		ON HW1_Cons.OrderID						= HW2.OrderID and right(rtrim(HW1_Cons.TaskName),1) = HW2.Loca1
		LEFT  JOIN		#TB_Maria				AS STEMAR	ON CONCAT(HW1_Cons.PONumber,HW2.[DescripValue],HW1_Cons.Equipo) = CONCAT(STEMAR.[Order],STEMAR.Localidad,STEMAR.Equipo) AND STEMAR.rn = 1
		LEFT  JOIN		#TB_Maria				AS STEMAR2	ON CONCAT(HW1_Cons.PONumber,HW2.[DescripValue],HW2.MachineValue) = CONCAT(STEMAR2.[Order],STEMAR2.Localidad,STEMAR2.Bordadora) AND STEMAR2.Conteo = 1
		LEFT  JOIN      (
							SELECT 
								RM.Comments AS Machine, LEFT(CL.[Label],1) AS Cabezales 
							FROM LCA.dbo.RawMaterials AS RM WITH(NOLOCK)
							INNER JOIN LCA.dbo.ComponentLibrary AS CL WITH(NOLOCK) ON RM.ComponentID = CL.ComponentID 
																					AND CL.ComponentCategoryID = 18 
																					AND CL.SubCategoryID = 1746
																					AND CL.[Description] <> 'Barudan'
						) AS PPM ON RIGHT(STEMAR.Bordadora,3) = RIGHT(PPM.Machine,3)
						-- where hw1.PONumber = 'ORD-4928625'
		--INSERT INTO #TB_Final

		SELECT 
			HW1.FechaAjustada,
			HW1.ChangeDate as ProdDate,
			COALESCE(STEMAR.CreateDate,STEMAR2.CreateDate) as StdCreateDate,
			HW1.Equipo as Equipo,
			HW1.PONumber,
			HW1.OrderID,
			HW1.MO,
			HW2.[DescripValue] AS Locacion,
			HW1.Quantity, 
			HW1.Make,
			COALESCE(STEMAR.Bordadora,STEMAR2.Bordadora) as Bordadora,
			COALESCE(STEMAR.CantidadDePuntadas,STEMAR2.CantidadDePuntadas) as qtyPuntadas,
			COALESCE(STEMAR.Secuencias,STEMAR2.Secuencias) as Secuencias,
			COALESCE(STEMAR.Apliques,STEMAR2.Apliques) as Apliques,
			COALESCE(STEMAR.TipoDePellum,STEMAR2.TipoDePellum) as tBordado,
			COALESCE(STEMAR.CostingCode,STEMAR2.CostingCode) as CtgCode,
			COALESCE(STEMAR.Estilo,STEMAR2.Estilo) as Estilo,
	
			hw1.Muestra, --SETUP
			COALESCE(STEMAR.TCicloIndiv,STEMAR2.TCicloIndiv) AS TCicloIndiv,
	
			HW1.[#Ciclos],
			HW1.Muestra + (COALESCE(STEMAR.TCicloIndiv,STEMAR2.TCicloIndiv) * HW1.[#Ciclos]) AS [Tiempo Estandar],
	
	
			ROUND((
			HW1.Muestra + (COALESCE(STEMAR.TCicloIndiv,STEMAR2.TCicloIndiv) * HW1.[#Ciclos])) / 60 * 3.02 * 2, 2) AS [Devengado],
	
			HW1.Turno,
			ISNULL(COALESCE(STEMAR.Cabezales,STEMAR2.Cabezales),PPM.Cabezales) as Cabezales,
			HW2.MachineValue,
			STEMAR.ID AS ID

		INTO #TB_Final
		--select *
		FROM			#TB_ProdEM_Final		AS HW1
		LEFT  JOIN		#TB_Loc					AS HW2		ON HW1.OrderID						= HW2.OrderID and right(rtrim(HW1.TaskName),1) = HW2.Loca1
		LEFT  JOIN		#TB_Maria				AS STEMAR	ON CONCAT(HW1.PONumber,HW2.[DescripValue],HW1.Equipo) = CONCAT(STEMAR.[Order],STEMAR.Localidad,STEMAR.Equipo) AND STEMAR.rn = 1
		LEFT  JOIN		#TB_Maria				AS STEMAR2	ON CONCAT(HW1.PONumber,HW2.[DescripValue],HW2.MachineValue) = CONCAT(STEMAR2.[Order],STEMAR2.Localidad,STEMAR2.Bordadora) AND STEMAR2.Conteo = 1
		LEFT  JOIN      (
							SELECT 
								RM.Comments AS Machine, LEFT(CL.[Label],1) AS Cabezales 
							FROM LCA.dbo.RawMaterials AS RM WITH(NOLOCK)
							INNER JOIN LCA.dbo.ComponentLibrary AS CL WITH(NOLOCK) ON RM.ComponentID = CL.ComponentID 
																					AND CL.ComponentCategoryID = 18 
																					AND CL.SubCategoryID = 1746
																					AND CL.[Description] <> 'Barudan'
						) AS PPM ON RIGHT(STEMAR.Bordadora,3) = RIGHT(PPM.Machine,3)
		-- WHERE hw1.PoNumber = 'ORD-4778475'	
		
		-- UPDATE TF SET
		IF @FechaFinal IS NOT NULL
		BEGIN
			UPDATE TF SET
				ProdDate = td.ChangeDate
			FROM #TB_Final AS TF
			INNER JOIN 
			(
			select
				PONumber
				,MAX(ChangeDate) as ChangeDate
			from #TB_DateTransactions
			where (CAST(ChangeDate AS DATE) <= @FechaFinal)
			GROUP BY PONumber
			) AS TD ON TF.PONumber = TD.PONumber 
		END
		ELSE
		BEGIN
			UPDATE TF SET
				ProdDate = td.ChangeDate
			FROM #TB_Final AS TF
			INNER JOIN 
			(
			select
				PONumber
				,MAX(ChangeDate) as ChangeDate
			from #TB_DateTransactions
			GROUP BY PONumber
			) AS TD ON TF.PONumber = TD.PONumber 
		END

    	IF @process = 'data.Flex'
		BEGIN

			SELECT
			*
			FROM
			(
				SELECT 
					 StdCreateDate
					,ProdDate
					,FechaAjustada
					,PONumber
					,Equipo
					,Bordadora
					,SUM(Make) AS Make
					,qtyPuntadas
					,Secuencias
					,Apliques
					,tBordado
					,CtgCode
					-- ,MO
					,Locacion
					,Estilo
					,SUM(Quantity) AS Quantity
					,SUM(Muestra) AS Muestra
					,TCicloIndiv
					,SUM([#Ciclos]) AS [#Ciclos]
					,SUM([Tiempo Estandar]) AS [Tiempo Estandar]
					,Cabezales
					,SUM(Devengado) AS Devengado
					,Turno

				FROM #TB_Final  
				GROUP BY
				FechaAjustada
					,ProdDate
					,StdCreateDate
					,Equipo
					,PONumber
					-- ,MO
					,Locacion
					,Bordadora
					,qtyPuntadas
					,Secuencias
					,Apliques
					,tBordado
					,CtgCode
					,Estilo
					,TCicloIndiv
					-- ,[#Ciclos]
					,Cabezales
					,Turno
			) AS TB
			WHERE
			FechaAjustada BETWEEN @FechaInicial AND @FechaFinal
			AND (@Equipo IS NULL OR Equipo = @Equipo)  -- Filtra solo si @Equipo tiene valor
			AND (@Bordadora IS NULL OR Bordadora = @Bordadora)  -- Filtra solo si @Bordadora tiene valor
			-- and PONumber = 'ORD-5077519'	
			-- AND Quantity <> 0
			ORDER BY FechaAjustada, Quantity

			RETURN
					 
		END
    	IF @process = 'data.PONumber'
		BEGIN

			SELECT
			*
			FROM
			(
				SELECT 
					 StdCreateDate
					,ProdDate
					,FechaAjustada
					,PONumber
					,Equipo
					,Bordadora
					,SUM(Make) AS Make
					,qtyPuntadas
					,Secuencias
					,Apliques
					,tBordado
					,CtgCode
					-- ,MO
					,Locacion
					,Estilo
					,SUM(Quantity) AS Quantity
					,SUM(Muestra) AS Muestra
					,TCicloIndiv
					,SUM([#Ciclos]) AS [#Ciclos]
					,SUM([Tiempo Estandar]) AS [Tiempo Estandar]
					,Cabezales
					,SUM(Devengado) AS Devengado
					,Turno

				FROM #TB_Final  
				GROUP BY
				FechaAjustada
					,ProdDate
					,StdCreateDate
					,Equipo
					,PONumber
					-- ,MO
					,Locacion
					,Bordadora
					,qtyPuntadas
					,Secuencias
					,Apliques
					,tBordado
					,CtgCode
					,Estilo
					,TCicloIndiv
					-- ,[#Ciclos]
					,Cabezales
					,Turno
			) AS TB     
			WHERE
			PONumber LIKE '%' + @PONumber
			-- AND Quantity <> 0
			ORDER BY FechaAjustada, Quantity

			RETURN
					 
		END

		IF @process = 'data.totales'
		BEGIN
		
			SET @result =
						(
							SELECT 
								COALESCE(CAST(SUM([Tiempo Estandar]) AS DECIMAL(18, 3)),0.00) AS TotalTiempoEstandar,
								COALESCE(SUM(Quantity),0) AS Bordados,
								COALESCE(CAST(SUM(Devengado) AS DECIMAL(18, 2)),0.00) AS Devengado
							FROM #TB_Final     
							WHERE FechaAjustada BETWEEN @FechaInicial AND @FechaFinal
							AND (@Equipo IS NULL OR Equipo = @Equipo)
							AND (@Bordadora IS NULL OR Bordadora = @Bordadora)
							FOR JSON PATH, INCLUDE_NULL_VALUES
						)
			SET @Error = 0
			SET @FinalComponent = '[Completed]'
			SET @Msg = 'Datos obtenidos correctamente'
					
		END

	SELECT 
             [Result]           = @result
            ,[Result2]          = @result2
			,[Error]			= @Error
            ,[FinalComponent]   = @FinalComponent
            ,[Msg]              = @Msg
END;