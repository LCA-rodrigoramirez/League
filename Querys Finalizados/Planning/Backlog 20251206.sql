USE [LCA]
GO
/****** Object:  StoredProcedure [dboReaders].[sp_Planning_Backlog]    Script Date: 06/12/2025 02:49:58 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 ALTER PROCEDURE [dboReaders].[sp_Planning_Backlog] 
 	 @KeyDLI VARCHAR(MAX)	
 AS
BEGIN
    
        SET NOCOUNT ON 
        --  DECLARE @KeyDLI AS VARCHAR(MAX)
        --  SET @KeyDLI = '11beafbb-32b8-487f-9902-bbc22c20fae1'


        DECLARE @NextContainer AS DATE
        SET @NextContainer = CAST(GETDATE() AS DATE)


        ---Dias que se le restara a la fecha de contenedor para tomar el DUE DATE DE LAS ORDENES
        DECLARE @DueDateContainer AS INTEGER
        SET @DueDateContainer = 15


        DECLARE @UnitVolume AS FLOAT
        SET @UnitVolume = 1
        DECLARE @UnitsInBox AS INTEGER
        SET @UnitsInBox = 50


        DROP TABLE IF EXISTS #TB_Dates
        DROP TABLE IF EXISTS #TB_Approved
        DROP TABLE IF EXISTS #TB_Approved_Mixed
        DROP TABLE IF EXISTS #TB_DateUpdated_DLI
        DROP TABLE IF EXISTS #TB_DISCARD_ORD
        DROP TABLE IF EXISTS #TB_LogoStyle
        DROP TABLE IF EXISTS #TB_CustName
        DROP TABLE IF EXISTS #TB_GROUPID
        DROP TABLE IF EXISTS #TB_LCAComments
        DROP TABLE IF EXISTS #TB_DATA
        DROP TABLE IF EXISTS #TB_MO_DATA
        DROP TABLE IF EXISTS #TB_GROUP_PONUMBER
        DROP TABLE IF EXISTS #TB_LOG_CREATE_ORDS
        DROP TABLE IF EXISTS #TB_LOG_CREATE_MOS
        DROP TABLE IF EXISTS #TB_SHIP_DATA
        DROP TABLE IF EXISTS #TB_ORD_SHIP
        DROP TABLE IF EXISTS #ORD_SPL
        DROP TABLE IF EXISTS #DAT_SUPPL
        DROP TABLE IF EXISTS #Group_Bundles_ORD
        DROP TABLE IF EXISTS #Group_NewStyleDivision
        DROP TABLE IF EXISTS #ITEMDETAIL_PB
        DROP TABLE IF EXISTS #TB_DATA_UNION
        


        -----------------------------------------------------------
        ----------PROCEDIMIENTO PARA FECHAS DE CONTENEDOR----------
        -----------------------------------------------------------
            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  PROCEDIMIENTO PARA FECHAS DE CONTENEDOR')
            DECLARE @TotalInContainer AS FLOAT
            SET @TotalInContainer =920 ---CAJAS


            ---Ultimo contenedor dentro de tres meses, del dia viernes.
            ---SE ASUME QUE EL ULTIMO CONTENEDOR SIEMPRE ES VIERNES
            DECLARE @LastContainer AS DATE
            SET @LastContainer = DATEADD(WK,DATEDIFF(WK,4,DATEADD(DAY,90,@NextContainer)),4) 

            CREATE TABLE #TB_Dates (
                [Row]                  INTEGER NOT NULL
                ,[Date_Container]       DATE    NOT NULL
                ,[Day_Container]        NVARCHAR(50)
                ,[DueDate_Container]    DATE    NOT NULL
                ,[DueDay_Conteiner]     NVARCHAR(50)
                ,[Max_InContainer]      FLOAT
                ,[Box_InContainer]      FLOAT
                ,[Units_InContainer]    INTEGER
            )


            DECLARE @ContainersPerWeek AS INTEGER
            SET @ContainersPerWeek = 0

            DECLARE @i          AS INTEGER
            DECLARE @Fecha_i    AS DATE
            SET @i = 1
            SET @Fecha_i = @NextContainer

                
                ---Si Contenedor es Jueves o Domingo    
                ------(Solicitud de Rogelio Alvarez 20220812, Fecha en que se va el Barco)
                -- SELECT DATEADD(WK,DATEDIFF(WK,3,'2022-08-14'),3)  
                -- SELECT DATEADD(WK,DATEDIFF(WK,6,DATEADD(WK,1,'2022-08-17')),6)  
                IF @ContainersPerWeek = 0
                BEGIN
                    IF ( DATEPART(WEEKDAY,@Fecha_i) IN (1,2,3))                           --Domingo,Lunes,Martes
                        SET @Fecha_i = DATEADD(WK,DATEDIFF(WK,3,@Fecha_i),3)                    --Jueves
                    ELSE
                    IF ( DATEPART(WEEKDAY,@Fecha_i) IN (4,5,6))                           --Miercoles,Jueves,Viernes
                        SET @Fecha_i = DATEADD(WK,DATEDIFF(WK,6,DATEADD(WK,1,@Fecha_i)),6)      --Domingo
                    ELSE
                    IF ( DATEPART(WEEKDAY,@Fecha_i) IN (7))                                 --Sabado
                        SET @Fecha_i = DATEADD(WK,DATEDIFF(WK,3,DATEADD(WK,1,@Fecha_i)),3)      --Jueves
                END

            
            WHILE @Fecha_i <= @LastContainer ---SE ASUME QUE EL ULTIMO CONTENEDOR SIEMPRE ES VIERNES
            BEGIN
                INSERT INTO #TB_Dates   (       
                                            [Row]
                                            ,[Date_Container]
                                            ,[Day_Container]
                                            ,[DueDate_Container]
                                            ,[DueDay_Conteiner]
                                            ,[Max_InContainer]
                                            ,[Box_InContainer]
                                            ,[Units_InContainer] 
                                        )
                                        (SELECT 
                                            @i                                                         AS [Row]
                                            ,@Fecha_i                                                   AS [Date_Container]
                                            ,DATENAME(WEEKDAY,@Fecha_i)                                 AS [Day_Container]
                                            ,DATEADD(DAY,@DueDateContainer,@Fecha_i)                    AS [DueDate_Container]
                                            ,DATENAME(WEEKDAY,DATEADD(DAY,@DueDateContainer,@Fecha_i))  AS [DueDay_Conteiner]
                                            ,@TotalInContainer                                          AS [Max_InContainer]
                                            ,0.0000                                                     AS [Box_InContainer]
                                            ,0.0000                                                     AS [Units_InContainer]
                                        )


                
                ---Si Contenedor es Jueves o Domingo
                IF @ContainersPerWeek = 0
                BEGIN
                    IF (DATEPART(WEEKDAY,@Fecha_i) = 5)
                    BEGIN
                        SET @i = @i + 1
                        SET @Fecha_i =DATEADD(DAY,3,@Fecha_i)  
                    END
                    ELSE
                    IF (DATEPART(WEEKDAY,@Fecha_i) = 1)
                    BEGIN
                        SET @i = @i + 1
                        SET @Fecha_i =DATEADD(DAY,4,@Fecha_i)
                    END
                END

                
                
            END

            SET @LastContainer = (SELECT MAX([Date_Container]) FROM #TB_Dates )
        -----------------------------------------------------------
        ----------PROCEDIMIENTO PARA FECHAS DE CONTENEDOR----------
        -----------------------------------------------------------

        
        -----------------------------------------------------------
        -------------------INFORMACION MARIADB---------------------
        -----------------------------------------------------------
            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  PROCEDIMIENTO PARA INFORMACION MARIADB')
            ----CAPTURAR LA INFORMACION DE LA PAGINA DE DESPACHO DE DLI.
            -----http://lca.l2brandca.com/planning/delivery-stock
            -----Se debe tomar el Key que es enviado en el Procedimiento
                DECLARE @SQL_MARIA_DB   AS VARCHAR(8000)
                DECLARE @SQL_MARIA_DB_2 AS VARCHAR(8000)
                DECLARE @SQL_EXEC       AS NVARCHAR(MAX)

                SET @SQL_MARIA_DB = 'SELECT ord_mo_id,SUM(inv_type_query) AS dat ,max(inv_pack_date) as inv_pack_date FROM (
                SELECT ord_mo_id, inv_type_query ,max(inv_pack_date) as inv_pack_date FROM `wordpress`.`Planning_DispatchRO_Approved_Dispatches`
                WHERE `id_key` =  ( SELECT `id` FROM `wordpress`.`Planning_DispatchRO_Generated`
                WHERE `key` = ' + '''' + '''' + @KeyDLI + '''' + ''') 
                GROUP BY ord_mo_id, inv_type_query
                ) AS TB
                GROUP BY ord_mo_id'

                SET @SQL_MARIA_DB_2 = 'SELECT DISTINCT dis_mo_id as ord_mo_id,inv_type_query AS dat, dis_require_date as inv_pack_date FROM `wordpress`.`Planning_DispatchRO_Approved_Mixed`
                WHERE `id_key` =  ( SELECT `id` FROM `wordpress`.`Planning_DispatchRO_Generated`
                WHERE `key` = ' + '''' + '''' + @KeyDLI + '''' + ''')'

                SET @SQL_EXEC = 'SELECT ord_mo_id, CASE WHEN dat > 1 THEN 2 ELSE 1 END AS Dat , CAST(inv_pack_date AS DATE) AS inv_pack_date
                    FROM OPENQUERY([MARIADB],' + '''' + @SQL_MARIA_DB + ''''  + ') '

            --Tabla de inventario temporal disponible
                CREATE TABLE #TB_Approved ( 
                    [ord_mo_id]        INT 
                    ,[Dat]              INT 
                    ,[inv_pack_date]    DATE
                )
                INSERT INTO #TB_Approved 
                EXEC (@SQL_EXEC)

                SET @SQL_EXEC = 'SELECT ord_mo_id, CASE WHEN dat > 1 THEN 2 ELSE 1 END AS Dat , CAST(inv_pack_date AS DATE) AS inv_pack_date
                    FROM OPENQUERY([MARIADB],' + '''' + @SQL_MARIA_DB_2 + ''''  + ') '

            --NUEVA TABLA PARA SEPARAR INVENTARIO DISPONIBLE NORMAL DEL INVENTARIO DISPONIBLE QUE REQUIERE HACER MAS DE 1 ORDEN
                CREATE TABLE #TB_Approved_Mixed ( 
                    [ord_mo_id]        INT 
                    ,[Dat]              INT 
                    ,[inv_pack_date]    DATE
                )
                INSERT INTO #TB_Approved_Mixed 
                EXEC (@SQL_EXEC)
 

            --TABLA PARA OBTENER LA ULTIMA FECHA DE ACTUALIZACION DE DLI
                DECLARE @SQL_MARIA_DateUpdated_DLI VARCHAR(8000)
                DECLARE @SQL_EXEC_DateUpdated_DLI NVARCHAR(MAX)

                SET @SQL_MARIA_DateUpdated_DLI = 'SELECT `created_at` AS DateUpdated_DLI FROM `wordpress`.`Planning_DispatchRO_Generated`
                WHERE `key` = ' + '''' + '''' + @KeyDLI + '''' + ''' LIMIT 1 ' 

                SET @SQL_EXEC_DateUpdated_DLI = 'SELECT DateUpdated_DLI  
                    FROM OPENQUERY([MARIADB],' + '''' + @SQL_MARIA_DateUpdated_DLI + ''''  + ') '


                CREATE TABLE #TB_DateUpdated_DLI(
                    [DateUpdated_DLI]  DATETIME
                )
                INSERT INTO #TB_DateUpdated_DLI
                EXEC (@SQL_EXEC_DateUpdated_DLI)
                DECLARE @DateUpdated_DLI AS DATETIME
                SET @DateUpdated_DLI = (SELECT TOP 1 [DateUpdated_DLI] FROM #TB_DateUpdated_DLI)
           
            --TABLA PARA OBTENER LOS DISCARDS DE LAS ORDENES
                DECLARE @SQL_MARIA_DB_DISCARD   AS VARCHAR(8000)
                DECLARE @SQL_EXEC_DB_DISCARD       AS NVARCHAR(MAX)

                SET @SQL_EXEC_DB_DISCARD = 'SELECT DISTINCT dis_mo_id, discard_by_mpa, discard_by_percentage FROM `wordpress`.`Planning_DispatchRO_DiscardORD`
                WHERE `id_key` =  ( SELECT `id` FROM `wordpress`.`Planning_DispatchRO_Generated`
                WHERE `key` = ' + '''' + '''' + @KeyDLI + '''' + ''')'

                SET @SQL_EXEC = 'SELECT dis_mo_id, discard_by_mpa, discard_by_percentage
                    FROM OPENQUERY([MARIADB],' + '''' + @SQL_EXEC_DB_DISCARD + ''''  + ') '


            --Tabla de ordenes discard
                CREATE TABLE #TB_DISCARD_ORD ( 
                     [dis_mo_id]                INT 
                    ,[discard_by_mpa]           DECIMAL(10,4) 
                    ,[discard_by_percentage]    DECIMAL(10,4) 
                )
                INSERT INTO #TB_DISCARD_ORD 
                EXEC (@SQL_EXEC)



            ---Tabla de Logos, se guarda en Maria. Viene de L2Brand. Ya existe pagina para ctualizar OrderTypeID y OrderTypeDescription 
            ---http://www.l2brandca.com/index.php/logostyleinorders/
            ---Tabla de Wordpress 192.168.1.126 wordpress.L2Brands_LogoStyle
                CREATE TABLE #TB_LogoStyle(
                [LogoStyle]              VARCHAR(20)
                ,[OrderTypeID]            INTEGER
                ,[OrderTypeDescription]   VARCHAR(60)
                ,[ApplicationOrder]		VARCHAR(50)
                ) 
                INSERT INTO #TB_LogoStyle(
                    [LogoStyle]           
                    ,[OrderTypeID]         
                    ,[OrderTypeDescription]
                    ,[ApplicationOrder]
                )
                (
                    SELECT  
                        [LogoStyle]           
                        ,[OrderTypeID]         
                        ,[OrderTypeDescription]
                        ,[ApplicationOrder]
                    FROM OPENQUERY([MARIADB],'SELECT * FROM wordpress.L2Brands_LogoStyle')  AS TBM
                )



            ---Tabla de CustName, se guarda en Maria. Viene de L2Brand. Es para identificar los blanks y las fakeOrd
                CREATE TABLE #TB_CustName(
                     [CustName]     VARCHAR(100)     
                    ,[Type]         VARCHAR(45)  
                    ,[LCAComments]  VARCHAR(45)  
                    ,[NewBucket]    VARCHAR(125)  
                ) 
                INSERT INTO #TB_CustName(
                    [CustName]    
                    ,[Type]        
                    ,[LCAComments] 
                    ,[NewBucket]   
                    )
                (
                    SELECT  
                        [CustName]    
                        ,[Type]        
                        ,[LCAComments] 
                        ,[NewBucket]   
                    FROM OPENQUERY([MARIADB],'SELECT * FROM wordpress.Planning_Backlog_CustName')  AS TBM
                )

            ---Tabla de GroupID de L2Brands
                CREATE TABLE #TB_GROUPID(
                    [GroupID]          NVARCHAR(45)
                    ,[GRDescription]    NVARCHAR(100)
                    ,[ShipEarly]        INTEGER
                )
                INSERT INTO #TB_GROUPID(
                    [GroupID]
                    ,[GRDescription]
                    ,[ShipEarly]
                )(
                SELECT 
                    [GroupID]
                    ,[Description] 
                    ,[ShipEarly]

                FROM OPENQUERY([MARIADB],'SELECT * FROM wordpress.L2Brands_GroupID')
                )

            ---Tabla de Backlog LCAComments, se guarda en Maria. Esta es data que se tiene que ir llenando.
            ---Tabla de Wordpress 192.168.1.126 wordpress.Planning_Backlog_LCAComments
                CREATE TABLE #TB_LCAComments(
                    [LCAComments]          NVARCHAR(200)
                    ,[OrderDispatch]        INTEGER
                    ,[DaysArriveInPacking]  INTEGER
                    ,[DateInPacking]        NVARCHAR(200)
                    ,[OrderReport]          INTEGER
                )
                INSERT INTO #TB_LCAComments(
                    [LCAComments]        
                    ,[OrderDispatch]      
                    ,[DaysArriveInPacking]
                    ,[DateInPacking]
                    ,[OrderReport]      
                )(
                SELECT 
                    [LCAComments]        
                    ,[OrderDispatch]      
                    ,[DaysArriveInPacking]
                    ,[DateInPacking]  
                    ,[OrderReport]
                FROM OPENQUERY([MARIADB],'SELECT * FROM wordpress.Planning_Backlog_LCAComments;')
                )

        -----------------------------------------------------------
        -------------------INFORMACION MARIADB---------------------
        -----------------------------------------------------------

        ------------------------------------------------------------    
        --------------TABLAS BASE PARA SELECT POLYPM----------------    
        ------------------------------------------------------------
                -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  PROCEDIMIENTO PARA TABLAS BASE PARA SELECT POLYPM')
            
                -- DROP TABLE IF EXISTS #TB_MO_DATA
                -- DROP TABLE IF EXISTS #TB_GROUP_PONUMBER
                -- DROP TABLE IF EXISTS #TB_LOG_CREATE_ORDS
                -- DROP TABLE IF EXISTS #TB_LOG_CREATE_MOS
                -- DROP TABLE IF EXISTS #TB_SHIP_DATA

                -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  PROCEDIMIENTO PARA CREATE TEMPORAL #TB_MO_DATA')
                SELECT 
                     [PONumber]             =   CASE 
                                                    WHEN CHARINDEX('.', OD.[PONumber]) > 0 THEN LEFT(OD.[PONumber], CHARINDEX('.', OD.[PONumber]) - 1)
                                                    ELSE OD.[PONumber]
                                                END
                    ,[APS]                  = REPLACE(REPLACE(REPLACE(OD.[Comments6],CHAR(10),''),CHAR(9),''),CHAR(13),'')
                    ,[OrderDate]            = OD.[OrderDate]
                    ,[CreateORD]            = CASt(NULL AS DATE)
                    ,[CreateMO]             = CASt(NULL AS DATE)
                    ,[RequiredDate]         = COALESCE( CAST(OI.[requiredDate] AS DATE)      
                                                        ,CAST(OD.[requiredDate] AS DATE))
                    ,[MO_ID]                = MO.[ManufactureID]
                    ,[MO]                   = MO.[ManufactureNumber]
                    ,[MOStatusID]           = SNMO.[StatusID]
                    ,[MOStatus]             = SNMO.[StatusName]
                    ,[Style]                = ST.[StyleNumber]
                    ,[Season]               = SNS.[SeasonName]
                    ,[Color]                = STC.[StyleColorName]
                    ,[ColorDescription]     = STC.[StyleColorDescription]
                    ,[Make]                 = MO.[QuantityOrdered]
                    ,[SewingDate]           = MO.[SchedFinish]
                    ,[PWModulo]             = REPLACE(REPLACE(REPLACE(MO.[Comments7], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')   
                    ,[Bucket]               = REPLACE(REPLACE(REPLACE(MO.[Comments3], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')   
                    ,[ProductionStatus]     = PST.[DropDownValue]
                    ,[PreviewLCAComments]   = REPLACE(REPLACE(REPLACE(PST.[Description],CHAR(10),''),CHAR(9),''),CHAR(13),'')
                    ,[Availability]         = MO.[PlanTransferCost]
                    ,[FabricDD]             = REPLACE(REPLACE(REPLACE(MO.[Comments8], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')   
                    ,[OrderID]              = OD.[OrderID]
                    ,[RowN]                 = CAST(NULL AS BIGINT)
                    ,[ItemDetailID]         = CAST(NULL AS VARCHAR(MAX))
                    ,[WorkID]               = CAST(NULL AS VARCHAR(MAX))
                    ,[Comments6]            = REPLACE(REPLACE(REPLACE(OD.[Comments6],CHAR(10),''),CHAR(9),''),CHAR(13),'')  
                    ,[ProductDivision]      = ST.[Comments9]
                    ,[Collection]           = STCL.[CollectionName]
                    -- ,[ProductionStatusID]   = MO.[ProductionStatusID]
                    -- ,[FirstOrderItemID]     = MO.[FirstOrderItemID]
                    -- ,[PlanTransferCost]     = MO.[PlanTransferCost]
                INTO #TB_MO_DATA
                FROM (
                    SELECT [StatusID], [StatusName]
                    FROM dbo.StatusNames WITH (NOLOCK)
                    WHERE [StatusID] <= 90
                ) AS FSN
                INNER JOIN      dbo.StatusNames                 AS SNMO WITH(NOLOCK) ON SNMO.[StatusID]     = FSN.[StatusID]
                INNER JOIN      dbo.ManufactureOrders           AS MO   WITH(NOLOCK) ON MO.[StatusID]       = SNMO.[StatusID]         AND MO.[ManufactureNumber] IS NOT NULL
                LEFT JOIN       dbo.OrderItems                  AS OI   WITH(NOLOCK) ON OI.OrderItemID      = MO.FirstOrderItemID
				INNER JOIN		dbo.Orders                      AS OD   WITH(NOLOCK) ON OD.OrderID          = OI.OrderID              AND OD.PONumber IS NOT NULL
                INNER JOIN      dbo.Styles                      AS ST   WITH(NOLOCK) ON ST.StyleID          = OI.StyleID
                INNER JOIN      dbo.StyleColors                 AS STC  WITH(NOLOCK) ON STC.StyleColorID    = OI.StyleColorID
                LEFT JOIN       dbo.Seasons                     AS SNS  WITH(NOLOCK) ON SNS.SeasonID        = ST.SeasonID
                LEFT JOIN       dbo.DropDownValues3             AS PST	WITH(NOLOCK) ON PST.DropDownValueID = MO.ProductionStatusID
                LEFT JOIN       dbo.StyleCollections			AS STCL WITH(NOLOCK) ON ST.CollectionID     = STCL.CollectionID
                
                
                -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  PROCEDIMIENTO PARA UPDATE ItemDetailID')
                UPDATE S SET
                    [ItemDetailID]  = CASE 
                                            WHEN [PONumber] IS NULL	THEN 
                                                NULL
                                            WHEN ( [PONumber] LIKE 'ORD-PO%') THEN
                                                NULL
                                            WHEN ( [PONumber] LIKE 'ORD-%') AND ( ISNUMERIC ( REPLACE ( [PONumber],'ORD-','') ) = 1)  THEN
                                                REPLACE ( [PONumber],'ORD-','') 
                                            WHEN ( [PONumber] LIKE 'ORD%') AND ( ISNUMERIC ( REPLACE ( [PONumber],'ORD','') ) = 1)  THEN
                                                REPLACE ( [PONumber],'ORD','') 
                                            WHEN ( [PONumber] LIKE 'ORD%') AND (ISNUMERIC(LEFT([Comments6],1)) = 1 ) THEN
                                                [Comments6]
                                            ELSE
                                                NULL 		
                                        END
                FROM #TB_MO_DATA AS S

                -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  PROCEDIMIENTO PARA UPDATE WorkID')
                UPDATE S SET
                    [WorkID]      = CASE 
                                            WHEN [PONumber] IS NULL	THEN 
                                                NULL
                                            WHEN ( [PONumber] LIKE 'ORD-%') AND ( ISNUMERIC ( REPLACE ( [PONumber],'ORD-','') ) = 1 ) THEN
                                                REPLACE ( [PONumber],'ORD-','')
                                            WHEN ( [PONumber] LIKE 'ORD%') AND (ISNUMERIC(LEFT([Comments6],1)) = 1 ) THEN
                                                [Comments6]
                                            ELSE
                                                [PONumber] 
                                        END
                FROM #TB_MO_DATA AS S

                -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  PROCEDIMIENTO PARA UPDATE CreateORD')
                 ;WITH CTE_CHANGELOG_ORD AS (
                    select RecordID,tableID,[ACTION],ChangeDate from dbo.ChangeLog as cl WITH(NOLOCK)
                    where  CL.tableID = 37 AND CL.ACTION like 'Create%'
                )
                SELECT
                    [OrderID]   = TB.[OrderID]
                    ,[CreateORD] = CAST(COD.[CreateORD]    AS DATE) 
                INTO #TB_LOG_CREATE_ORDS
                FROM (SELECT DISTINCT [OrderID] FROM #TB_MO_DATA) AS TB
                INNER JOIN  (
                                SELECT  
                                    [OrderID]   
                                    ,[CreateORD]  
                                FROM(
                                SELECT  
                                        [OrderID]      = TB.[OrderID]
                                        ,[CreateORD]    = CL.[ChangeDate]
                                        ,[ROW_N]        = ROW_NUMBER() OVER(PARTITION BY TB.OrderID
                                                            ORDER BY TB.OrderID
                                                            ,CL.ChangeDate DESC)
                                FROM (SELECT DISTINCT [OrderID] FROM #TB_MO_DATA) AS TB
                                INNER JOIN	CTE_CHANGELOG_ORD	AS	CL	WITH(NOLOCK)	ON	TB.OrderID = CL.RecordID AND CL.tableID = 37 AND CL.ACTION like 'Create%'
                                -- INNER JOIN	ChangeLog	AS	CL	WITH(NOLOCK)	ON	TB.OrderID = CL.RecordID AND CL.tableID = 37 AND CL.ACTION like 'Create%'
                                ) AS TB WHERE TB.ROW_N = 1
                )  AS COD  ON COD.OrderID = TB.OrderID

                UPDATE S SET
                    [CreateORD] = COD.[CreateORD]
                FROM #TB_MO_DATA AS S
                INNER JOIN #TB_LOG_CREATE_ORDS     AS COD  ON COD.OrderID = S.OrderID
                
                -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  PROCEDIMIENTO PARA UPDATE CreateMO')
                ;WITH CTE_CHANGELOG_MO AS (
                    select RecordID,tableID,[ACTION],ChangeDate from dbo.ChangeLog as cl    WITH(NOLOCK)
                    where  CL.tableID = 30 AND CL.ACTION like 'Create%'
                )
                SELECT
                    [MO_ID]   = TB.[MO_ID]
                    ,[CreateMO] = CAST(COD.[CreateMO]    AS DATE) 
                INTO #TB_LOG_CREATE_MOS 
                FROM (SELECT DISTINCT [MO_ID] FROM #TB_MO_DATA) AS TB
                INNER JOIN  (
                                SELECT  
                                    [MO_ID]   
                                    ,[CreateMO]  
                                FROM(
                                SELECT  
                                         [MO_ID]      = TB.[MO_ID]
                                        ,[CreateMO]   = CL.[ChangeDate]
                                        ,[ROW_N]      = ROW_NUMBER() OVER(PARTITION BY TB.MO_ID
                                                            ORDER BY TB.MO_ID
                                                            ,CL.ChangeDate DESC)
                                FROM (SELECT DISTINCT [MO_ID] FROM #TB_MO_DATA) AS TB
                                INNER JOIN	CTE_CHANGELOG_MO	AS	CL	WITH(NOLOCK)	ON	TB.MO_ID = CL.RecordID AND CL.tableID = 30 AND CL.ACTION like 'Create%'
                                -- INNER JOIN	ChangeLog	AS	CL	WITH(NOLOCK)	ON	TB.MO_ID = CL.RecordID AND CL.tableID = 30 AND CL.ACTION like 'Create%'
                                ) AS TB WHERE TB.ROW_N = 1
                )  AS COD  ON COD.MO_ID = TB.MO_ID

                UPDATE S SET
                    [CreateMO] = CMO.[CreateMO]
                FROM #TB_MO_DATA AS S
                INNER JOIN  #TB_LOG_CREATE_MOS      AS CMO  ON CMO.MO_ID = S.MO_ID
            
                -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  PROCEDIMIENTO PARA UPDATE RowN')
                ;WITH CTE_RowNumbers AS (
                    SELECT 
                        [RowN] = ROW_NUMBER() OVER (
                                    PARTITION BY [PONumber]
                                    ORDER BY [PONumber], [CreateMO] ASC
                                ),
                        [MO_ID] 
                    FROM #TB_MO_DATA    
                )

                UPDATE S SET
                    S.[RowN] = CTE.[RowN]
                FROM #TB_MO_DATA AS S
                JOIN CTE_RowNumbers AS CTE ON S.[MO_ID] = CTE.[MO_ID]


                
                -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  PROCEDIMIENTO PARA DELETE ROWN > 1')
                DELETE FROM #TB_MO_DATA WHERE [RowN] > 1


                --------------------------esportacion
                -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  PROCEDIMIENTO PARA EXPORTACION MO')
                        ----SELECT DE POLYPM EXPORTACION.
                        ----Este es que nos va a dar el primer Waybill con el BoxStatus que tiene por cada Orden.
                        ----Ordena 1- Shipped   2- Picked   3- Packed
                    SELECT 
                        [WayBill]
                        ,[ShipDate]
                        ,[BoxStatus]
                        ,[MO_ID]
                    INTO #TB_SHIP_DATA
                    FROM(
                        SELECT
                            sh.WayBill                          AS [WayBill]
                            ,CAST(sh.ShipDate AS DATE)          AS [ShipDate]
                            ,pci.ManufactureID                  AS [MO_ID]
                            ,snpcb.StatusName                   AS [BoxStatus]
                            ,ROW_NUMBER() OVER(
                            PARTITION BY 
                                pci.ManufactureID
                            ORDER BY 
                                pci.ManufactureID
                                ,CAST(ISNULL(sh.ShipDate,GETDATE()) AS DATE) 
                                ,CASE
                                    WHEN snpcb.StatusID = 75 THEN 1 --Shipped
                                    WHEN snpcb.StatusID = 25 THEN 2 --Picked
                                    WHEN snpcb.StatusID = 27 THEN 3 --Packed
                                    ELSE 1000 END 
                                )                                               AS [Row_Data]
                        FROM			dbo.StatusNames			    AS snpcb WITH (NOLOCK)
                        INNER JOIN		dbo.PackedBoxes				AS PCB	 WITH (NOLOCK)	ON	snpcb.StatusID = PCB.StatusID AND snpcb.StatusID IN (75,25,27) AND PCB.WarehouseID = 8
                        INNER JOIN		dbo.PackedItems				AS PCI	 WITH (NOLOCK)	ON	PCB.PackedBoxID = PCI.PackedBoxID AND PCI.ManufactureID IS NOT NULL
                        INNER JOIN      #TB_MO_DATA                 AS MO                   ON  MO.MO_ID        = PCI.ManufactureID
                        LEFT OUTER JOIN dbo.Shipments				AS sh	 WITH (NOLOCK)	ON	sh.ShipmentID = PCB.ShipmentID
                    ) AS TB
                    WHERE [Row_Data] = 1                        ---Solo la primera MO segun la fecha de exportacion.
                
                -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  PROCEDIMIENTO PARA EXPORTACION ORD')
                    ----SELECT DE POLYPM EXPORTACION.
                        ----Este es que nos va a dar el primer Waybill con el BoxStatus que tiene por cada Orden.
                        ----Ordena 1- Shipped   2- Picked   3- Packed
                    SELECT 
                        [WayBill]
                        ,[ShipDate]
                        ,[BoxStatus]
                        ,[OrderID]
                    INTO #TB_ORD_SHIP
                    FROM(
                        SELECT
                            sh.WayBill                          AS [WayBill]
                            ,CAST(sh.ShipDate AS DATE)          AS [ShipDate]
                            ,pcb.OrderID						AS [OrderID]
                            ,snpcb.StatusName                   AS [BoxStatus]
                            ,ROW_NUMBER() OVER(
                            PARTITION BY 
                                pcb.OrderID
                            ORDER BY 
                                pcb.OrderID
                                ,CAST(ISNULL(sh.ShipDate,GETDATE()) AS DATE) 
                                ,CASE
                                    WHEN snpcb.StatusID = 75 THEN 1 --Shipped
                                    WHEN snpcb.StatusID = 25 THEN 2 --Picked
                                    WHEN snpcb.StatusID = 27 THEN 3 --Packed
                                    ELSE 1000 END 
                                )                                               AS [Row_Data]
                        FROM			dbo.StatusNames			    AS snpcb WITH (NOLOCK)
                        INNER JOIN		dbo.PackedBoxes				AS PCB	 WITH (NOLOCK)	ON	snpcb.StatusID = PCB.StatusID AND snpcb.StatusID IN (75,25,27) AND PCB.WarehouseID = 8
                        INNER JOIN		dbo.PackedItems				AS PCI	 WITH (NOLOCK)	ON	PCB.PackedBoxID = PCI.PackedBoxID AND PCI.ManufactureID IS NOT NULL
                        LEFT OUTER JOIN dbo.Shipments				AS sh	 WITH (NOLOCK)	ON	sh.ShipmentID = PCB.ShipmentID
                    ) AS TB
                    WHERE [Row_Data] = 1                        ---Solo la primera MO segun la fecha de exportacion.
                
                --------------------------esportacion

        ------------------------------------------------------------    
        --------------TABLAS BASE PARA SELECT POLYPM----------------    
        ------------------------------------------------------------    



        ------------------------------------------------------------    
        -------------------TABLAS BASE L2BRANDS---------------------    
        ------------------------------------------------------------    
            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  TABLAS L2BRANDS')

            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  TABLA VW_view_qryLCA_Order_Export')
            SELECT DISTINCT 
                 [ItemDetailID]             = [ItemDetailID]
                ,[RS_Priority]              = [R/S Priority]                    
                ,[DateUpdated_Priority]     = [Insert_time]                     
                ,[SalesChannel]             = [SalesChannel]                    
                ,[ShipTo]                   = [Ship To]                         
                ,[CustDueDate]              =  CAST([CustDueDate] AS DATE)       
                ,[MachineGroup]             = [MachineGroup]
                ,[OrderType]                = [OrderType]
                ,[Status/Date]              = [Status/Date]
                ,[Relabel]                  = [Relabel]
                ,[License Sticker]          = [License Sticker]
                ,[Application Type]         = [Application Type]
                ,[Hot Order]                = [Hot Order]
                ,[ProductDivision]          = [ProductDivision]
                ,[ORD #]                    = [ORD #]
                ,[NewStyle]                 = [NewStyle]
            INTO #ORD_SPL
            FROM [AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export]  WITH (NOLOCK)  

            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  TABLA Group_Bundles_ORD')
            SELECT DISTINCT 
                [ItemDetailID]
                ,[ORD #]
                ,[Group]    = 'Bundles'
            INTO #Group_Bundles_ORD
            FROM #ORD_SPL  WITH (NOLOCK)
            WHERE [ORD #] IN (
                    SELECT DISTINCT 
                        [ORD #]
                    FROM #ORD_SPL  WITH (NOLOCK)
                    WHERE [ProductDivision] = 'Bundles'
                )

            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  TABLA Group_NewStyleDivision')
            SELECT DISTINCT 
                 [NewStyle]
                ,[ProductDivision]
            INTO #Group_NewStyleDivision
            FROM #ORD_SPL  WITH (NOLOCK)

            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  TABLA TB_L2Brand_view_qryOpenOrderSuppl_162')
            SELECT 
                 [created_at]
                ,[DueDate]
                ,[CustName]
                ,[Order_No]
                ,[ItemDetailID]
                ,[Quantity]
                ,[DetailStatus]
                ,[SKUStatus]
                ,[Status]
                ,[LogoStyle]
                ,[GroupID]
                ,[Style Color]
                ,[StyleID]
                ,[CSRID]
                ,[CSRName]
                ,[Style Sales Status]
                ,[DesignNo]
                ,[SKUID]
                ,[SKLogoNo]
                ,[CustPO]
                ,[EventDate]
            INTO #DAT_SUPPL
            FROM [AppsLCA].[dbo].[TB_L2Brand_view_qryOpenOrderSuppl_162]    AS TBL2B   WITH (NOLOCK)
            WHERE TBL2B.[SKUStatus] <= 40 ---Solo las ordenes menores a Status 40 de L2Brand (ORDENES ACTIVAS)

            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  TABLA ITEMDETAIL_PB')
            SELECT DISTINCT 
                 [ItemDetailID]         = L2BOE.ItemDetailID
                ,[OrderID]              = OD.OrderID 
                ,[PONumber]             = OD.PONumber
                ,[OrderDate]            = CAST(OD.OrderDate AS DATE)
                ,[RequiredDate]         = CAST(OD.RequiredDate AS DATE)
                ,[APS]                  = L2BOE.[ORD #]
                ,[ChangeDate]           = CAST(COD.ChangeDate AS DATE)
            INTO #ITEMDETAIL_PB
            FROM        dbo.PackedBoxes     AS PB       WITH(NOLOCK)
            LEFT JOIN   dbo.Orders          AS OD       WITH(NOLOCK)    ON PB.OrderID                                   = OD.OrderID
            INNER JOIN  #ORD_SPL            AS L2BOE    WITH(NOLOCK)    ON SUBSTRING(OD.PONumber,5,LEN(OD.PONumber))    = CAST (L2BOE.ItemDetailID as VARCHAR(100))
                                                                            AND REPLACE(REPLACE(REPLACE(OD.Comments6,CHAR(10),''),CHAR(9),''),CHAR(13),'') = L2BOE.[ORD #]
                                                                            AND ProductDivision = 'Bundles'
            LEFT JOIN dboReaders.VW_LOG_CreateORD     AS COD  WITH (NOLOCK) ON COD.OrderID = OD.OrderID

        ------------------------------------------------------------    
        -------------------TABLAS BASE L2BRANDS---------------------    
        ------------------------------------------------------------  
        
        
        ------------------------------------------------------------    
        --------------UNION TABLAS L2BRANDS POLYPM------------------
        ------------------------------------------------------------  
            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  UNION TABLAS L2BRANDS POLYPM')
        
            SELECT 
                ROW_NUMBER() OVER (
                                ORDER BY 
                                    TBL2B.[DueDate]
                                    ,TBL2B.[ItemDetailID])  AS [RowNum]
                ,GETDATE()                                  AS [DataUpdated_LCA] 
                ----DATOS DE L2Brand
                ,TBL2B.[created_at]                         AS [DataUpdated_L2Brand]
                ,@DateUpdated_DLI                           AS [DateUpdated_DLI]
                ,TBL2B.[DueDate]
                ,TBL2B.[CustName]
                ,TBL2B.[Order_No]
                ,TBL2B.[ItemDetailID]
                ,TBL2B.[Quantity]
                ,TBL2B.[DetailStatus]
                ,TBL2B.[SKUStatus]
                ,TBL2B.[Status]
                ,TBL2B.[LogoStyle]
                ,TBL2B.[GroupID]

                ,CASE 
                    WHEN TB_AAOO.[RS_Priority] = 'SWR'
                    THEN 1 
                    ELSE TBGrp.[ShipEarly]
                END                            AS [ShipEarly]
                ,TBL2B.[Style Color]
                ,TBL2B.[StyleID]
                ,TBL2B.[CSRID]
                ,TBL2B.[CSRName]
                ,TBL2B.[Style Sales Status]
                ,TBL2B.[DesignNo]
                ,TBL2B.[SKUID]					---AGREGADA EL 28/02/2024 A PETICION DE INGRID MAGA�A --- RODRIGO RAM�REZ ---
                ,TBL2B.[SKLogoNo]
                ,TBL2B.[CustPO]

                ----DATOS CALCULADOS
                ,CASE
                    WHEN TBLST.[OrderTypeID] =   15 THEN concat('SCREEN PRINT ',TBLST.ApplicationOrder)
                    WHEN TBLST.[OrderTypeID] =   85 THEN 'EMBROIDERY' 
                    WHEN TBLST.[OrderTypeID] =   87 THEN concat('SUBLIMATION ',TBLST.ApplicationOrder)
                    WHEN TBLST.[OrderTypeID] =   11 THEN 'BLANKS'
                    WHEN TBLST.[OrderTypeID] =	 92 THEN 'TRANSFER'
                    ELSE '' 
                    END AS [Type]
                ,CASE
                    WHEN TB_OrdBund.[Group] IS NOT NULL THEN TB_OrdBund.[Group]
                    WHEN TBL2B.GroupID = 'SAMPLE' THEN  'SAMPLE'
                    WHEN TBL2B.GroupID = 'BRNSM' THEN  'Barnesmith'
                    WHEN TBL2B.GroupID = 'ACADEM' THEN  'Academy'
                    WHEN LEFT(TBL2B.[StyleID],2) = 'RW' THEN 'Redshirt'
                    WHEN LEFT(TBL2B.[StyleID],2) = 'FR' THEN 'Fall Rush'
                    WHEN LEFT(TBL2B.[StyleID],3) = 'NDS' THEN 'ND The Shirt'
                    WHEN LEFT(TBL2B.[StyleID],3) = 'MST' THEN 'Masters'
                    WHEN LEFT(TBL2B.[StyleID],2) = 'CB' THEN 'Casa Bonita'
                    WHEN LEFT(TBL2B.[StyleID],2) = 'RH' THEN 'Rally House'
                    WHEN LEFT(TBL2B.[StyleID],2) = 'LC' THEN 'LOCALE'
                    WHEN LEFT(TBL2B.[StyleID],2) = 'UW' THEN 'Unwind'
                    WHEN RIGHT(TBL2B.[StyleID],3) = 'PDT' THEN 'Pigment Dye'
                    WHEN UPPER(TB_AAOO.[SalesChannel]) = 'DESTINATION' THEN 'Resort' ---agregada 20230718
                    ELSE TBGrp.[GRDescription]
                END        AS [Group]
                ,TB_AAOO.[SalesChannel]

                ,CASE 
                    WHEN TBL2B.[SKUStatus] = 40 THEN 'RFP'
                    WHEN TBL2B.[SKUStatus] < 40 THEN 'NO RFP'
                    ELSE ''
                END        AS [ArtStatus] 

                ----DATOS DE POLYPM MANUFACTUREORDERS
                ,ISNULL(TBPPM.[PONumber],TBBUND.PONumber) AS PONumber
                ,ISNULL(TBPPM.[OrderID],TBBUND.OrderID) AS OrderID
                    -- ,TBPPM.[ItemDetailID]
                ,TBPPM.[WorkID]
                ,ISNULL(TBPPM.[APS],TBBUND.APS) AS APS
                ,ISNULL(TBPPM.[OrderDate],TBBUND.OrderDate) AS OrderDate
                ,ISNULL(TBPPM.[CreateORD],TBBUND.ChangeDate) AS CreateORD
                ,TBPPM.[CreateMO]
                ,ISNULL(TBPPM.[RequiredDate],TBBUND.RequiredDate) AS RequiredDate
                ,TBPPM.[MO_ID]
                ,TBPPM.[MO]
                ,TBPPM.[MOStatusID]
                ,TBPPM.[MOStatus]
                ,TBPPM.[Style]
                ,TBPPM.[Season]
                ,TBPPM.[Color]
                ,TBPPM.[ColorDescription]
                ,TBPPM.[Make]
                ,TBPPM.[SewingDate]
                ,TBPPM.[PWModulo]
                ,TBPPM.[Bucket]
                ,TBPPM.[ProductionStatus]
                ,TBPPM.[PreviewLCAComments]
                ,TBPPM.[Availability]
                ,TBPPM.[FabricDD]

                ----DATOS DE LOGOSTYLE
                ,TBLST.[OrderTypeID]         
                ,TBLST.[OrderTypeDescription]

                ----DATOS DE PRIORIDAD, DATA VIENE DE L2Brand
                ,TB_AAOO.[RS_Priority]
                ,TB_AAOO.[DateUpdated_Priority]  

                ----Datos solicitados 20230718 (KevinRivas y CasaMatriz)
                ,TB_AAOO.[ShipTo]
                ,TB_AAOO.[CustDueDate]
                ,CASE WHEN TB_OE.ProductDivision LIKE 'Apparel%' THEN 'Apparel'
                    ELSE TB_OE.ProductDivision
                    END AS ProductDivision
                ,TB_AAOO.[MachineGroup]
                ,TB_AAOO.[OrderType]
                ,TB_AAOO.[Status/Date]
                ,TB_AAOO.[Relabel]
                ,TB_AAOO.[License Sticker]
                ,TB_AAOO.[Application Type]
                ,TB_AAOO.[Hot Order]
                ,TBL2B.[EventDate]
                ,TBPPM.[Collection]
                --,TBPPM.ProductDivision
                ----Tabla que viene de L2Brand, contiene todas las ordenes.
            INTO #TB_DATA_UNION
            FROM        #DAT_SUPPL                  AS TBL2B
            LEFT JOIN   #ORD_SPL                    AS TB_AAOO      ON TB_AAOO.[ItemDetailID]   = TBL2B.[ItemDetailID]
            LEFT JOIN   #Group_Bundles_ORD          AS TB_OrdBund   ON TB_AAOO.[ItemDetailID]   = TB_OrdBund.[ItemDetailID]
            LEFT JOIN   #TB_LogoStyle               AS TBLST        ON TBLST.[LogoStyle]        = TBL2B.[LogoStyle]        ----Tabla de LogoStyle, que viene de L2Brand. Se creo en MARIADB
            LEFT JOIN   #TB_GROUPID                 AS TBGrp        ON TBGrp.[GroupID]          = TBL2B.[GroupID]          ----Tabla de GroupID, que viene de L2Brand. Se creo en MARIADB
            INNER JOIN  #Group_NewStyleDivision     AS TB_OE        ON TB_OE.[NewStyle]         = TBL2B.[StyleID]
            LEFT JOIN   #TB_MO_DATA                 AS TBPPM        ON TBPPM.[ItemDetailID]     = CAST(TBL2B.[ItemDetailID] AS VARCHAR)
            LEFT JOIN   #ITEMDETAIL_PB              AS TBBUND       ON TBBUND.[ItemDetailID]    = TBL2B.[ItemDetailID]

        ------------------------------------------------------------    
        --------------UNION TABLAS L2BRANDS POLYPM------------------
        ------------------------------------------------------------  

        --------------------------------------------------------------------    
        --------------UPDATE TABLA UNION CON DATOS DEL LOG------------------
        --------------------------------------------------------------------
        -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  PROCEDIMIENTO PARA UPDATE TABLA UNION CON DATOS DEL LOG')
            UPDATE TDU set

                 [RS_Priority]          = Logs.[RS_Priority]
                ,[DateUpdated_Priority] = Logs.[DateUpdated_Priority]
                ,[SalesChannel]         = Logs.[SalesChannel]
                ,[ShipTo]               = Logs.[ShipTo]
                ,[CustDueDate]          = Logs.[CustDueDate]
                ,[MachineGroup]         = Logs.[MachineGroup]
                ,[OrderType]            = Logs.[OrderType]
                ,[Status/Date]          = Logs.[Status/Date]
                ,[Relabel]              = Logs.[Relabel]
                ,[License Sticker]      = Logs.[License Sticker]
                ,[Application Type]     = Logs.[Application Type]
                ,[Hot Order]            = Logs.[Hot Order]
                ,[Group]                = CASE
                                            WHEN TB_OrdBund.[Group] IS NOT NULL THEN TB_OrdBund.[Group]
                                            WHEN TBL2B.GroupID = 'SAMPLE' THEN  'SAMPLE'
                                            WHEN TBL2B.GroupID = 'BRNSM' THEN  'Barnesmith'
                                            WHEN TBL2B.GroupID = 'ACADEM' THEN  'Academy'
                                            WHEN LEFT(TBL2B.[StyleID],2) = 'RW' THEN 'Redshirt'
                                            WHEN LEFT(TBL2B.[StyleID],2) = 'FR' THEN 'Fall Rush'
                                            WHEN LEFT(TBL2B.[StyleID],3) = 'NDS' THEN 'ND The Shirt'
                                            WHEN LEFT(TBL2B.[StyleID],3) = 'MST' THEN 'Masters'
                                            WHEN LEFT(TBL2B.[StyleID],2) = 'CB' THEN 'Casa Bonita'
                                            WHEN LEFT(TBL2B.[StyleID],2) = 'RH' THEN 'Rally House'
                                            WHEN LEFT(TBL2B.[StyleID],2) = 'LC' THEN 'LOCALE'
                                            WHEN LEFT(TBL2B.[StyleID],2) = 'UW' THEN 'Unwind'
                                            WHEN RIGHT(TBL2B.[StyleID],3) = 'PDT' THEN 'Pigment Dye'
                                            WHEN UPPER(Logs.[SalesChannel]) = 'DESTINATION' THEN 'Resort' ---agregada 20230718
                                            ELSE TBGrp.[GRDescription]
                                          END
                ,[ShipEarly]            = CASE 
                                            WHEN TDU.[RS_Priority] = 'SWR'
                                            THEN 1 
                                            ELSE TBGrp.[ShipEarly]
                                          END                            
            FROM #TB_DATA_UNION AS TDU
            INNER JOIN
            (
                SELECT DISTINCT
                    [ItemDetailID]         = TBLog.[ItemDetailID]
                    ,[RS_Priority]          = TBLog.[R/S Priority]
                    ,[DateUpdated_Priority] = TBLog.[Insert_Time]
                    ,[SalesChannel]         = TBLog.[SalesChannel]
                    ,[ShipTo]               = TBLog.[Ship To]
                    ,[CustDueDate]          = CAST(TBLog.[CustDueDate] AS DATE)
                    ,[MachineGroup]         = TBLog.[MachineGroup]
                    ,[OrderType]            = TBLog.[OrderType]
                    ,[Status/Date]          = TBLog.[Status/Date]
                    ,[Relabel]              = TBLog.[Relabel]
                    ,[License Sticker]      = TBLog.[License Sticker]
                    ,[Application Type]     = TBLog.[Application Type]
                    ,[Hot Order]            = TBLog.[Hot Order]
				FROM [192.168.1.93].[AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export_Logs] AS TBLog WITH(NOLOCK)
                INNER JOIN 
                (
                    SELECT
                        [ItemDetailID]     = [ItemDetailID]
                        ,[Max_Insert_Time]  = MAX([Insert_Time])
                    FROM [192.168.1.93].[AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export_Logs] AS TBLog WITH(NOLOCK)
                    WHERE TBLog.ItemDetailID IN (SELECT DISTINCT ItemDetailID FROM #TB_DATA_UNION WHERE [DateUpdated_Priority] IS NULL)
                    GROUP BY
                        [ItemDetailID]
                ) AS FilterLog   ON TBLog.ItemDetailID   = FilterLog.ItemDetailID AND TBLog.Insert_Time = FilterLog.Max_Insert_Time
            )                               AS Logs         ON TDU.ItemDetailID     = Logs.ItemDetailID
            LEFT JOIN #DAT_SUPPL            AS TBL2B        ON TDU.[ItemDetailID]   = TBL2B.[ItemDetailID]
            LEFT JOIN #TB_GROUPID           AS TBGrp        ON TBGrp.[GroupID]      = TBL2B.[GroupID]          ----Tabla de GroupID, que viene de L2Brand. Se creo en MARIADB
            LEFT JOIN #Group_Bundles_ORD    AS TB_OrdBund   ON TDU.[ItemDetailID]   = TB_OrdBund.[ItemDetailID]

        

        --------------------------------------------------------------------
        --------------UPDATE TABLA UNION CON DATOS DEL LOG------------------
        --------------------------------------------------------------------
       


       
        ------------------------------------------------------------    
        -------------------TABLA CON DATA FINAL---------------------    
        ------------------------------------------------------------  
            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  CREATE TABLA #TB_DATA')

            ----Tabla Final Que se mostrara al usuario.f
            ----Es donde se une la informacion de L2Brand y la informacion de PolyPM MOS, PolyPM Shipment, LogoStyle, GroupID.

            CREATE TABLE #TB_DATA(
                [RowNum]                       [INTEGER]           NOT NULL
                ,[DataUpdated_L2Brand]          [datetime]          NULL
                ,[DataUpdated_LCA]              [datetime]          NULL
                ,[DateUpdated_DLI]              [datetime]          NULL
                ,[DateUpdated_Priority]         [datetime]          NULL

                ,[DueDate]                      [datetime2](0)      NULL
                ,[Week]                         [nvarchar](50)      NULL
                ,[CustName]                     [nvarchar](50)      NULL
                ,[Order_No]                     [nvarchar](4000)    NULL
                ,[ItemDetailID]                 [int]               NULL
                ,[Quantity]                     [int]               NULL
                ,[DetailStatus]                 [smallint]          NULL
                ,[SKUStatus]                    [int]               NULL
                ,[Status]                       [int]               NULL
                ,[LogoStyle]                    [nvarchar](20)      NULL
                ,[ApplicationType]              [nvarchar](100)      NULL
                ,[GroupID]                      [nvarchar](50)      NULL
                ,[RS_Priority]                  [nvarchar](50)      NULL

                ,[ShipEarly]                    [int]               NULL
                ,[Style Color]                  [nvarchar](50)      NULL
                ,[StyleID]                      [nvarchar](75)      NULL
                ,[CSRID]                        [int]               NULL
                ,[CSRName]                      [nvarchar](100)     NULL
                ,[Style Sales Status]           [varchar](50)       NULL
                ,[DesignNo]                     [nvarchar](50)      NULL
                ,[SKUID]		                [int]		        NULL
                ,[SKLogoNo]                     [nvarchar](50)      NULL
                ,[CustPO]                       [nvarchar](50)      NULL
                ,[Product Division]				[nvarchar](50)		NULL
                ,[Type]                         [varchar](50)       NULL
                ,[Group]                        [varchar](100)      NULL
                ,[SalesChannel]                 [varchar](200)      NULL
                ,[ArtStatus]                    [varchar](8)        NULL
                
                ,[PONumber]                     [nvarchar](50)      NULL
                ,[OrderID]                      [INTEGER]           NULL
                ,[WorkID]                       [nvarchar](4000)    NULL
                ,[APS]                          [nvarchar](512)     NULL
                ,[OrderDate]                    [date]              NULL
                ,[CreateORD]                    [date]              NULL
                ,[CreateMO]                     [date]              NULL
                ,[RequiredDate]                 [date]              NULL
                ,[MO_ID]                        [int]               NULL
                ,[MO]                           [nvarchar](40)      NULL
                ,[MOStatusID]                   [tinyint]           NULL
                ,[MOStatus]                     [nvarchar](30)      NULL
                ,[Style]                        [nvarchar](80)      NULL
                ,[Season]                       [nvarchar](60)      NULL
                ,[Color]                        [nvarchar](60)      NULL
                ,[ColorDescription]             [nvarchar](180)     NULL
                ,[Make]                         [float]             NULL
                ,[SewingDate]                   [smalldatetime]     NULL
                ,[PWModulo]                     [nvarchar](255)     NULL
                ,[Bucket]                       [nvarchar](1200)    NULL
                ,[ProductionStatus]             [nvarchar](50)      NULL
                ,[PreviewLCAComments]           [nvarchar](100)     NULL
                ,[Availability]                 [nvarchar](100)     NULL
                ,[FabricDD]                     [nvarchar](200)     NULL
                ,[OrderTypeID]                  [int]               NULL
                ,[OrderTypeDescription]         [varchar](60)       NULL
                ,[Waybill]                      [varchar](100)      NULL
                ,[PACKING]                      [varchar](100)      NULL
                ,[ShipDate]                     [date]              NULL
                ,[LCAComments]                  [varchar](100)      NULL
                ,[NewBucket]                    [varchar](125)      NULL
                ,[VolumeDAT]                    [float]             NULL
                ,[OrderDispatch]                [int]               NULL
                ,[DaysArriveInPacking]          [int]               NULL
                ,[DateInPacking]                [varchar](50)       NULL
                ,[TakeForProcedure] 	        [int]               NULL
                ,[DateArriveInPackingForOrder]  [date]              NULL
                ,[OrderForProcedure]            [int]               NULL
                ,[DateForConteiner]             [date]              NULL
                ,[LateOrder]                    [int]               NULL
                ,[DaysLateOrder]                [int]               NULL
                ,[Comments]                     [varchar](250)      NULL
                ,[Rev_DueDate]                  [int]               NULL
                ,[inv_pack_date]                [date]              NULL
                ,[ShipTo]                       [varchar](100)       NULL
                ,[CustDueDate]                  [date]              NULL
                ,[OrderReport]                  [int]               NULL
                ,[MachineGroup]					[varchar](100)		NULL
                ,[OrderType]					[varchar](100)		NULL
                ,[Status/Date]					[varchar](100)		NULL
                ,[Relabel]						[varchar](100)		NULL
                ,[License Sticker]				[varchar](100)		NULL
                ,[Application Type]				[varchar](100)		NULL
                ,[Hot Order]					[varchar](100)		NULL
                ,[EventDate]					[date]				NULL
                ,[Collection]					[varchar](100)		NULL
            )

            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  INSERT TABLA #TB_DATA')
            INSERT INTO #TB_DATA(
                [RowNum]  
                ----DATOS DE L2Brand
                ,[DataUpdated_L2Brand] 
                ,[DataUpdated_LCA]
                ,[DateUpdated_DLI]
                ,[DateUpdated_Priority]   

                ,[DueDate]              
                ,[Week]              
                ,[CustName]             
                ,[Order_No]             
                ,[ItemDetailID]         
                ,[Quantity]             
                ,[DetailStatus]         
                ,[SKUStatus]            
                ,[Status]               
                ,[LogoStyle]            
                ,[ApplicationType]            
                ,[GroupID]  
                ,[RS_Priority]
                ,[ShipEarly]

                ,[Style Color]          
                ,[StyleID]              
                ,[CSRID]                
                ,[CSRName]              
                ,[Style Sales Status]   
                ,[DesignNo]
                ,[SKUID]
                ,[SKLogoNo]             
                ,[CustPO]
                ,[Product Division]
                
                ----DATOS CALCULADOS
                ,[Type]                 
                ,[Group]   
                ,[SalesChannel]             
                ,[ArtStatus]  

                ----DATOS DE POLYPM MANUFACTUREORDERS
                ,[PONumber]             
                ,[OrderID] 
                ,[WorkID]               
                ,[APS]                  
                ,[OrderDate]            
                ,[CreateORD]            
                ,[CreateMO]             
                ,[RequiredDate]         
                ,[MO_ID]                
                ,[MO]                   
                ,[MOStatusID]           
                ,[MOStatus]             
                ,[Style]                
                ,[Season]               
                ,[Color]                
                ,[ColorDescription]     
                ,[Make]                 
                ,[SewingDate]           
                ,[PWModulo]             
                ,[Bucket]               
                ,[ProductionStatus]  
                ,[PreviewLCAComments]   
                ,[Availability]         
                ,[FabricDD]     

                ----DATOS DE LOGOSTYLE        
                ,[OrderTypeID]          
                ,[OrderTypeDescription] 

                ----DATOS DE POLYPM EXPORTACION
                ,[Waybill]
                ,[PACKING]
                ,[ShipDate]

                ----DATOS CALCULADOS
                ,[LCAComments]
                ,[NewBucket]
                ,[VolumeDAT]

                -----DATOS CALCULADOS TABLA LCAComments
                ,[OrderDispatch]
                ,[DaysArriveInPacking]
                ,[DateInPacking]

                ,[TakeForProcedure]
                ,[DateArriveInPackingForOrder]
                ,[OrderForProcedure]

                ,[DateForConteiner]

                ,[LateOrder]
                ,[DaysLateOrder]
                ,[Comments]

                ,[Rev_DueDate]
                ,[inv_pack_date]
                ,[ShipTo]
                ,[CustDueDate]

                ,[OrderReport]
                ,[MachineGroup]
                ,[OrderType]
                ,[Status/Date]
                ,[Relabel]
                ,[License Sticker]
                ,[Application Type]
                ,[Hot Order]
                ,[EventDate]
                ,[Collection]
            )(
                SELECT 
                    TBDAT_F.[RowNum]    
                    ,TBDAT_F.[DataUpdated_L2Brand]
                    ,TBDAT_F.[DataUpdated_LCA] 
                    ,TBDAT_F.[DateUpdated_DLI]
                    ,TBDAT_F.[DateUpdated_Priority]
                    ,TBDAT_F.[DueDate]           
                    ,CONCAT('WEEK ',DATEPART(WEEK, CAST(TBDAT_F.[DueDate] AS DATE))) AS [Week]
                    ,TBDAT_F.[CustName]          
                    ,TBDAT_F.[Order_No]          
                    ,TBDAT_F.[ItemDetailID]      
                    ,TBDAT_F.[Quantity]          
                    ,TBDAT_F.[DetailStatus]      
                    ,TBDAT_F.[SKUStatus]         
                    ,TBDAT_F.[Status]            
                    ,TBDAT_F.[LogoStyle]         
                    ,TBDAT_F.[ApplicationType]         
                    ,TBDAT_F.[GroupID]   
                    ,TBDAT_F.[RS_Priority]
                    ,TBDAT_F.[ShipEarly]        
                    ,TBDAT_F.[Style Color]       
                    ,TBDAT_F.[StyleID]           
                    ,TBDAT_F.[CSRID]             
                    ,TBDAT_F.[CSRName]           
                    ,TBDAT_F.[Style Sales Status]
                    ,TBDAT_F.[DesignNo]
                    ,TBDAT_F.[SKUID]				---AGREGADA EL 28/02/2025 A PETICION DE INGRID MAGA�A --- RODRIGO RAM�REZ ---
                    ,TBDAT_F.[SKLogoNo]          
                    ,TBDAT_F.[CustPO]    
                    ,TBDAT_F.[ProductDivision]
                    ,TBDAT_F.[Type]              
                    ,TBDAT_F.[Group] 
                    ,TBDAT_F.[SalesChannel]            
                    ,TBDAT_F.[ArtStatus]  
                    ,TBDAT_F.[PONumber]   
                    ,TBDAT_F.[OrderID]          
                    ,TBDAT_F.[WorkID]              
                    ,TBDAT_F.[APS]                 
                    ,TBDAT_F.[OrderDate]           
                    ,TBDAT_F.[CreateORD]           
                    ,TBDAT_F.[CreateMO]            
                    ,TBDAT_F.[RequiredDate]        
                    ,TBDAT_F.[MO_ID]               
                    ,TBDAT_F.[MO]                  
                    ,TBDAT_F.[MOStatusID]          
                    ,TBDAT_F.[MOStatus]            
                    ,TBDAT_F.[Style]               
                    ,TBDAT_F.[Season]              
                    ,TBDAT_F.[Color]               
                    ,TBDAT_F.[ColorDescription]    
                    ,TBDAT_F.[Make]                
                    ,TBDAT_F.[SewingDate]          
                    ,TBDAT_F.[PWModulo]            
                    ,TBDAT_F.[Bucket]              
                    ,TBDAT_F.[ProductionStatus]  
                    ,TBDAT_F.[PreviewLCAComments]  
                    ,TBDAT_F.[Availability]        
                    ,TBDAT_F.[FabricDD]            
                    ,TBDAT_F.[OrderTypeID]         
                    ,TBDAT_F.[OrderTypeDescription]
                    ,TBDAT_F.[Waybill]
                    ,TBDAT_F.[PACKING]
                    ,TBDAT_F.[ShipDate]
                    ,TBDAT_F.[LCAComments]
                    ,TBDAT_F.[NewBucket]
                    ,TBDAT_F.[VolumeDAT]

                    ,TBDAT_F.[OrderDispatch]	
                    ,TBDAT_F.[DaysArriveInPacking]	
                    ,TBDAT_F.[DateInPacking]
                    ,TBDAT_F.[TakeForProcedure]

                    -- ,TBDAT_F.[DateArriveInPackingForOrder]
                    ,CASE
                        WHEN ( DATEPART(WEEKDAY,TBDAT_F.[DateArriveInPackingForOrder]) = 1)     --Domingo
                        THEN DATEADD(DAY,1,TBDAT_F.[DateArriveInPackingForOrder])               --Lunes
                        ELSE 
                            TBDAT_F.[DateArriveInPackingForOrder]
                        END AS [DateArriveInPackingForOrder]

                        
                    ,CASE WHEN TBDAT_F.[TakeForProcedure] = 0 THEN 0 
                        ELSE ROW_NUMBER() OVER(
                            ORDER BY 
                                TBDAT_F.[TakeForProcedure]             DESC
                                ,TBDAT_F.[OrderDispatch]                ASC
                                ,TBDAT_F.[DueDate]                      ASC
                                ,TBDAT_F.[ShipEarly]                    DESC
                                ,TBDAT_F.[DateArriveInPackingForOrder]  ASC
                        ) END AS [OrderForProcedure]

                    ,NULL AS [DateForConteiner]
                    ,CASE 
                        WHEN    TBDAT_F.[LCAComments] = 'Shipped'
                        THEN 2
                        WHEN  TBDAT_F.[TakeForProcedure] = 0 
                            AND CAST(TBDAT_F.[DueDate] AS DATE ) > CAST(@LastContainer AS DATE) 
                        THEN 0
                        WHEN  TBDAT_F.[TakeForProcedure] = 0 
                            AND CAST(TBDAT_F.[DueDate] AS DATE ) <= CAST(@LastContainer AS DATE) 
                        THEN 1
                        ELSE   NULL END AS [LateOrder]

                        
                    ,CASE 
                        WHEN    TBDAT_F.[LCAComments] = 'Shipped'
                        THEN 0
                        WHEN  TBDAT_F.[TakeForProcedure] = 0 
                        THEN (DATEDIFF (DAY, TBDAT_F.[DueDate] , @LastContainer ) )
                        ELSE   NULL END AS [DaysLateOrder]
                    ,CASE 
                        WHEN    TBDAT_F.[LCAComments] = 'Shipped'
                        THEN 'OK'
                        WHEN  TBDAT_F.[TakeForProcedure] = 0 
                            AND CAST(TBDAT_F.[DueDate] AS DATE ) > CAST(@LastContainer AS DATE) 
                        THEN '0'
                        WHEN  TBDAT_F.[TakeForProcedure] = 0 
                            AND CAST(TBDAT_F.[DueDate] AS DATE ) <= CAST(@LastContainer AS DATE) 
                        THEN 'Late Order'
                        ELSE   NULL END AS [Comments]

                    ,TBDAT_F.[Rev_DueDate]
                    ,TBDAT_F.[inv_pack_date]

                    ,TBDAT_F.[ShipTo]
                    ,TBDAT_F.[CustDueDate]
                    ,TBDAT_F.[OrderReport]
                    ,TBDAT_F.[MachineGroup]
                    ,TBDAT_F.[OrderType]
                    ,TBDAT_F.[Status/Date]
                    ,TBDAT_F.[Relabel]
                    ,TBDAT_F.[License Sticker]
                    ,TBDAT_F.[Application Type]
                    ,TBDAT_F.[Hot Order]
                    ,TBDAT_F.[EventDate]			---AGREGADA EL 07/04/2025 A PETICION DE INGRID MAGA�A --- RODRIGO RAM�REZ ---
                    ,TBDAT_F.[Collection]			---AGREGADA EL 12/03/2025 A PETICION DE INGRID MAGA�A --- RODRIGO RAM�REZ ---
                FROM(
                    SELECT 
                        TB_DAT.*

                        ,TB_LCM.[OrderDispatch]	
                        ,TB_LCM.[DaysArriveInPacking]	
                        ,TB_LCM.[DateInPacking]
                        ,TB_LCM.[OrderReport]

                        ,CASE 
                            WHEN   ( TB_LCM.[OrderDispatch] = 0                 )

                                OR ( TB_DAT.[NewBucket] IS NOT NULL             )

                                OR (    TB_LCM.[DateInPacking] = 'Sewing' 
                                    AND TB_DAT.[SewingDate] IS NULL             )

                                OR (    TB_LCM.[DateInPacking] = 'FabricDD' 
                                    AND TB_DAT.[FabricDD] IS  NULL              )

                                OR (    TB_LCM.[DateInPacking] = 'Inv_Pack_Date' 
                                    AND TB_DAT.[inv_pack_date] IS  NULL          )
                                
                            THEN 0 
                            ELSE 1 END AS [TakeForProcedure]

                        

                        ,CASE 
                            WHEN    TB_LCM.[DateInPacking] = 'Today'
                                AND TB_DAT.[NewBucket] IS NULL
                            THEN DATEADD(DAY,[DaysArriveInPacking],CAST(GETDATE() AS DATE))
                            
                            WHEN    TB_LCM.[DateInPacking] = 'Sewing' 
                                AND TB_DAT.[SewingDate] IS NOT NULL
                                AND TB_DAT.[NewBucket] IS NULL
                            THEN DATEADD(DAY,[DaysArriveInPacking],CAST(TB_DAT.[SewingDate] AS DATE))
                        
                            WHEN    TB_LCM.[DateInPacking] = 'FabricDD' 
                                AND TB_DAT.[FabricDD] IS NOT NULL
                                AND TB_DAT.[NewBucket] IS NULL
                            THEN DATEADD(DAY,[DaysArriveInPacking],CAST(TB_DAT.[FabricDD] AS DATE))

                            WHEN    TB_LCM.[DateInPacking] = 'Inv_Pack_Date' 
                                AND TB_DAT.[inv_pack_date] IS NOT NULL
                                AND TB_DAT.[NewBucket] IS NULL
                            THEN DATEADD(DAY,[DaysArriveInPacking],CAST(TB_DAT.[inv_pack_date] AS DATE))

                            ELSE
                                NULL END [DateArriveInPackingForOrder]
                                
                FROM(
                    SELECT 
                        TB_DATA_ALL.*
                        
                        ,CASE
                            ---Ordenes ya exportadas, solo pondra shipped y la fecha de exportacion, segun el waybill.
                            WHEN TB_DATA_ALL.[LCAComments] = 'Shipped'
                            -- THEN CONCAT('Shipped ' , CAST(TB_DATA_ALL.[ShipDate] AS VARCHAR) )
                            THEN '00-Shipped'

                            ---A las ordenes NO RFP (Status Menor que 40) No se define todavia cuando podran ser exportadas.
                            WHEN TB_DATA_ALL.[ArtStatus] = 'NO RFP'
                            THEN 'NO RFP'

                            ---Las ordenes con fecha de requerido mayor a 3 meses (90 dias) no se define todavia fecha de exportacion.
                            WHEN TB_DATA_ALL.[DueDate] >= CAST(DATEADD(DAY,91,GETDATE()) AS DATE)
                            THEN 'TBD'
                            
                            ELSE NULL END AS [NewBucket]
                        
                        ,(CEILING(
                                (   (
                                        (Quantity *  @UnitVolume)
                                            /@UnitsInBox)
                                    /@UnitVolume)
                            ))* @UnitVolume                         AS [VolumeDAT]
                            
                    FROM(
                        SELECT
                            TB_ALL.[RowNum]    
                            ,TB_ALL.[DataUpdated_L2Brand]    
                            ,TB_ALL.[DataUpdated_LCA]  
                            ,TB_ALL.[DateUpdated_DLI]
                            ,TB_ALL.[DateUpdated_Priority]

                            ,TB_ALL.[DueDate]              
                            ,TB_ALL.[CustName]             
                            ,TB_ALL.[Order_No]             
                            ,TB_ALL.[ItemDetailID]         
                            ,TB_ALL.[Quantity]             
                            ,TB_ALL.[DetailStatus]         
                            ,TB_ALL.[SKUStatus]            
                            ,TB_ALL.[Status]               
                            ,TB_ALL.[LogoStyle]            
                            ,ETA.[ApplicationType]            
                            ,TB_ALL.[GroupID]     
                            ,TB_ALL.[RS_Priority]
                            ,TB_ALL.[ShipEarly]         
                            ,TB_ALL.[Style Color]          
                            ,TB_ALL.[StyleID]              
                            ,TB_ALL.[CSRID]                
                            ,TB_ALL.[CSRName]              
                            ,TB_ALL.[Style Sales Status]   
                            ,TB_ALL.[DesignNo]
                            ,TB_ALL.[SKUID]				---AGREGADA EL 28/02/2024 A PETICION DE INGRID MAGA�A --- RODRIGO RAM�REZ ---
                            ,TB_ALL.[SKLogoNo]             
                            ,TB_ALL.[CustPO]               
                            ,TB_ALL.[Type]                 
                            ,TB_ALL.[Group]
                            ,TB_ALL.[SalesChannel]
                            ,TB_ALL.[ArtStatus]  

                            ,TB_ALL.[PONumber]   
                            ,TB_ALL.[OrderID]          
                            ,TB_ALL.[WorkID]               
                            ,TB_ALL.[APS]                  
                            ,TB_ALL.[OrderDate]            
                            ,TB_ALL.[CreateORD]            
                            ,TB_ALL.[CreateMO]             
                            ,TB_ALL.[RequiredDate]         
                            ,TB_ALL.[MO_ID]                
                            ,TB_ALL.[MO]                   
                            ,TB_ALL.[MOStatusID]           
                            ,TB_ALL.[MOStatus]             
                            ,TB_ALL.[Style]                
                            ,TB_ALL.[Season]               
                            ,TB_ALL.[Color]                
                            ,TB_ALL.[ColorDescription]     
                            ,TB_ALL.[Make]                 
                            ,TB_ALL.[SewingDate]           
                            ,TB_ALL.[PWModulo]             
                            ,TB_ALL.[Bucket]               
                            ,TB_ALL.[ProductionStatus]  
                            ,TB_ALL.[PreviewLCAComments]   
                            ,TB_ALL.[Availability]         
                            ,TB_ALL.[FabricDD]             
                            ,TB_ALL.[OrderTypeID]          
                            ,TB_ALL.[OrderTypeDescription] 

                            ----DATOS DE POLYPM EXPORTACION
                            ,ISNULL(TBPCK.[WayBill],TBPCK2.WayBill)    AS [Waybill]
                            ,ISNULL(TBPCK.[BoxStatus],TBPCK2.BoxStatus)  AS [PACKING]
                            ,ISNULL(TBPCK.[ShipDate],TBPCK2.ShipDate)   AS [ShipDate]

                            ,CASE
                                WHEN TBPCK.[BoxStatus]  IS NOT NULL 
                                THEN TBPCK.[BoxStatus] --Aqui le pondra Shipped,Picked,Packed

                                WHEN TBPCK2.[BoxStatus] IS NOT NULL
                                THEN TBPCK2.[BoxStatus] --Aqui le pondra Shipped,Picked,Packed
                            
                                ----Si tiene production Status debe colocar la descripcion asignada en PolyPM
                                WHEN TB_ALL.[PreviewLCAComments] IS NOT NULL 
                                THEN TB_ALL.[PreviewLCAComments] ---Si tiene Production Status

                                ----Si ya tiene un Listado de Prendas de Stock Warehouse ya se puede decir que estan haciendo las transacciones en PolyPM
                                WHEN TB_ALL.[PreviewLCAComments] IS NULL AND
                                    ISDATE(RIGHT(TB_ALL.[PWModulo]  ,10)) = 1
                                THEN 'Taking units from warehouse'

                                ----Ordenes que todavia no se han ingresado al sistema de PolyPM
                                WHEN TB_ALL.[PONumber] IS NULL
                                THEN 'Orders in process to be imported into PolyPM'
                                
                                ----Ordenes que MPA = 1
                                WHEN TBDis.[discard_by_mpa] = 1 AND TBDis.[discard_by_percentage] IS NULL
                                THEN 'Inventory already reserved'
                                
                                ----Ordenes que POR PORCENTAJE DE INVENTARIO DISPONIBLE SEGUN ORD NO ALCANZA
                                WHEN TBDis.[discard_by_percentage] IS NOT NULL
                                THEN 'PO is not cover by fullfiment percentage'

                                ----Ordenes EMB o EMB FG que se pueden sacar de la bodega pero todavia no han sido asignadas a un listado
                                WHEN TBApp.Dat = 1 
                                THEN 'Inventory on hand'

                                ----Ordenes EMB o EMB FG que se pueden sacar de la bodega pero necesitan hacerse m�s de 1 MO para ser asignadas a un listado 
                                WHEN TBAppMix.Dat = 1 
                                THEN 'Split Inventory'
                                
                                ----Ordenes EMB o EMB FG que ya no se puedan sacar de la bodega, no tiene todo el inventario completo en DLI.
                                WHEN (TB_ALL.[Season]= 'EMB' OR TB_ALL.[Season]='EMB FG') 
                                THEN 'No Inventory on hand'
                                
                                ----Ordenes que van desde Corte ya tiene tela asignada a su 100%
                                WHEN CAST(TB_ALL.[Availability] AS INTEGER)  = 100
                                THEN 'Fabric on hand'

                                ----Ordenes que van desde corte no tienen el 100% de tela asignada.
                                WHEN NOT(CAST(TB_ALL.[Availability] AS INTEGER)  = 100)
                                THEN 'Waiting for the arrival of fabric'
                                
                                ----Ordenes que no se les ha colocado Availability, estan siendo ingresadas en ese momento. (Esperando Tela, y correr el MRP.)
                                WHEN TB_ALL.[Availability] IS NULL
                                THEN 'Waiting for the arrival of fabric'

                                ELSE ''

                            END AS [LCAComments]

                            ,CASE 
                                WHEN CAST(TB_ALL.[DueDate] AS DATE) = CAST(TB_ALL.[RequiredDate]   AS DATE) THEN 1
                                ELSE 0 END [Rev_DueDate]
                            
                            ,CASE 
                                WHEN TBApp.Dat = 1 
                                THEN NULL
                                ELSE TBApp.[inv_pack_date] END [inv_pack_date]
                            ,TB_ALL.[ShipTo]
                            ,TB_ALL.[CustDueDate]
                            ,TB_ALL.[ProductDivision]
                            ,TB_ALL.[MachineGroup]
                            ,TB_ALL.[OrderType]
                            ,TB_ALL.[Status/Date]
                            ,TB_ALL.[Relabel]
                            ,TB_ALL.[License Sticker]
                            ,TB_ALL.[Application Type]
                            ,TB_ALL.[Hot Order]
                            ,TB_ALL.[EventDate]
                            ,TB_ALL.[Collection]
                        FROM        #TB_DATA_UNION          AS TB_ALL
                        LEFT JOIN   #TB_Approved            AS TBApp        ON TBApp.[ord_mo_id]    = TB_ALL.[MO_ID]
                        LEFT JOIN   #TB_DISCARD_ORD         AS TBDis        ON TBDis.[dis_mo_id]    = TB_ALL.[MO_ID]
                        LEFT JOIN   #TB_Approved_Mixed      AS TBAppMix     ON TBAppMix.[ord_mo_id] = TB_ALL.[MO_ID]
                        LEFT JOIN   #TB_SHIP_DATA           AS TBPCK        ON TBPCK.[MO_ID]        = TB_ALL.[MO_ID]
                        LEFT JOIN   #TB_ORD_SHIP            AS TBPCK2       ON TBPCK2.[OrderID]     = TB_ALL.[OrderID]
                        LEFT JOIN   AppsLCA.dbo.Planning_Backlog_EmbroideryTypeApplique AS ETA WITH(NOLOCK) ON TB_ALL.[LogoStyle] = ETA.[LogoStyle]
                    ) AS TB_DATA_ALL
                    -- LEFT OUTER JOIN #TB_LCAComments AS TB_LCM ON TB_LCM.[LCAComments] = TB_DATA_ALL.[LCAComments]

                ) AS TB_DAT
                    LEFT JOIN #TB_LCAComments AS TB_LCM ON TB_LCM.[LCAComments] = TB_DAT.[LCAComments]
                ) AS TBDAT_F
            ) --PARENTESIS DE INSERT


        ------------------------------------------------------------    
        -------------------TABLA CON DATA FINAL---------------------    
        ------------------------------------------------------------ 


            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  INICIO PROCESO SET-BASED OPTIMIZADO')

            ------------------------------------------------------------
            -- 1️⃣ Crear índices temporales (si no existen)
            ------------------------------------------------------------
            IF NOT EXISTS (SELECT 1 FROM tempdb.sys.indexes WHERE name = 'IX_TB_DATA_OrderForProcedure')
                CREATE INDEX IX_TB_DATA_OrderForProcedure ON #TB_DATA (OrderForProcedure);

            IF NOT EXISTS (SELECT 1 FROM tempdb.sys.indexes WHERE name = 'IX_TB_DATES_Row')
                CREATE INDEX IX_TB_DATES_Row ON #TB_Dates ([Row]);

            ------------------------------------------------------------
            -- 2️⃣ Actualizar órdenes con el primer contenedor válido
            ------------------------------------------------------------
            ;WITH MatchContainer AS (
                SELECT
                    D.OrderForProcedure,
                    C.[Row]                         AS MatchedContainerRow,
                    C.[Date_Container]              AS Cont_DateContainer,
                    C.[DueDate_Container]           AS Cont_DueDate,
                    C.[Box_InContainer]             AS Cont_Boxes,
                    C.[Units_InContainer]           AS Cont_Units,
                    C.[Max_InContainer]             AS Cont_MaxBox,
                    D.[DueDate]                     AS Ord_DueDate,
                    D.[ShipEarly],
                    D.[VolumeDat]                   AS Ord_Volume,
                    D.[Quantity]                    AS Ord_Units,
                    D.[DateArriveInPackingForOrder] AS Ord_PackDate,
                    ROW_NUMBER() OVER (
                        PARTITION BY D.OrderForProcedure
                        ORDER BY C.[Date_Container] ASC
                    ) AS rn
                FROM #TB_DATA AS D
                CROSS APPLY (
                    SELECT C.*
                    FROM #TB_Dates AS C
                    WHERE
                        (C.[Box_InContainer] + D.[VolumeDat]) <= C.[Max_InContainer]
                        AND (
                                D.[DueDate] <= C.[DueDate_Container]
                            OR D.[ShipEarly] = 1
                            )
                        AND D.[DateArriveInPackingForOrder] <= DATEADD(DAY, -3, C.[Date_Container])
                ) AS C
            ),
            FirstValidContainer AS (
                SELECT *
                FROM MatchContainer
                WHERE rn = 1
            )
            UPDATE D
            SET
                D.[DateForConteiner]  = FVC.Cont_DateContainer,
                D.[LateOrder]         = CASE WHEN FVC.Cont_DateContainer >= D.[DueDate] THEN 1 ELSE 0 END,
                D.[Comments]          = CASE WHEN FVC.Cont_DateContainer >= D.[DueDate]
                                            THEN 'Late Order' ELSE 'Order on Time' END,
                D.[DaysLateOrder]     = DATEDIFF(DAY, D.[DueDate], FVC.Cont_DateContainer),
                D.[NewBucket]         = CAST(FVC.Cont_DateContainer AS VARCHAR(20))
            FROM #TB_DATA AS D
            INNER JOIN FirstValidContainer AS FVC
                ON FVC.OrderForProcedure = D.OrderForProcedure;

            ------------------------------------------------------------
            -- 3️⃣ Actualizar los contenedores con los totales asignados
            ------------------------------------------------------------
            ;WITH MatchContainer AS (
                SELECT
                    D.OrderForProcedure,
                    C.[Row] AS MatchedContainerRow,
                    D.[VolumeDat] AS Ord_Volume,
                    D.[Quantity] AS Ord_Units,
                    ROW_NUMBER() OVER (
                        PARTITION BY D.OrderForProcedure
                        ORDER BY C.[Date_Container] ASC
                    ) AS rn
                FROM #TB_DATA AS D
                CROSS APPLY (
                    SELECT C.*
                    FROM #TB_Dates AS C
                    WHERE
                        (C.[Box_InContainer] + D.[VolumeDat]) <= C.[Max_InContainer]
                        AND (
                                D.[DueDate] <= C.[DueDate_Container]
                            OR D.[ShipEarly] = 1
                            )
                        AND D.[DateArriveInPackingForOrder] <= DATEADD(DAY, -3, C.[Date_Container])
                ) AS C
            ),
            FirstValidContainer AS (
                SELECT *
                FROM MatchContainer
                WHERE rn = 1
            )
            UPDATE C
            SET
                C.[Box_InContainer]   = C.[Box_InContainer] + SUMS.TotalBoxes,
                C.[Units_InContainer] = C.[Units_InContainer] + SUMS.TotalUnits
            FROM #TB_Dates AS C
            INNER JOIN (
                SELECT
                    FVC.MatchedContainerRow,
                    SUM(FVC.Ord_Volume) AS TotalBoxes,
                    SUM(FVC.Ord_Units)  AS TotalUnits
                FROM FirstValidContainer AS FVC
                GROUP BY FVC.MatchedContainerRow
            ) AS SUMS
                ON C.[Row] = SUMS.MatchedContainerRow;

            ------------------------------------------------------------
            -- 4️⃣ Marcar órdenes no asignadas a ningún contenedor
            ------------------------------------------------------------
            UPDATE D
            SET
                D.[DateForConteiner]  = NULL,
                D.[LateOrder]         = 1,
                D.[NewBucket]         = 'Review: Order could not be shipped',
                D.[Comments]          = 'Review: Procedure could not dispatch orders'
            FROM #TB_DATA AS D
            WHERE D.[DateForConteiner] IS NULL;

            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  FIN PROCESO SET-BASED OPTIMIZADO')




            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  UPDATE Comments, NewBucket PARTE-1')
            ----no concuerda informacion para procedimiento diferente a NO INVENTORY ON HAND
                UPDATE #TB_DATA
                SET [Comments]  = (CONCAT('Review: ',[DateInPacking],'. Date Parameters do not match'))
                , [NewBucket]   = (CONCAT('Review: ',[DateInPacking],'. Date Parameters do not match'))
                WHERE   [OrderDispatch] <> 0 
                    AND [NewBucket] IS NULL
                    AND [LCAComments] <> 'No Inventory on hand'

            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  UPDATE Comments, NewBucket PARTE-2')
            ----no concuerda informacion para procedimiento IGUAL NO INVENTORY ON HAND
                UPDATE #TB_DATA
                SET [Comments]  = (CONCAT('Review: ',[DateInPacking],'. Date Parameters do not match'))
                , [NewBucket]   = ('Review: Create a Blank Order')
                WHERE   [OrderDispatch] <> 0 
                    AND [NewBucket] IS NULL
                    AND [LCAComments] = 'No Inventory on hand'
            
            -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  UPDATE Comments, NewBucket PARTE-3')
            ----INGRESADAS A POLYPM
                UPDATE #TB_DATA
                SET [Comments]  = ('Review: Orders in process to be imported into PolyPM')
                , [NewBucket]   = ('Review: Orders in process to be imported into PolyPM')
                WHERE   [LCAComments] = 'Orders in process to be imported into PolyPM'
                    AND [NewBucket] IS NULL


-- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  INICIO SELECT FINAL')
SELECT 
     TB_DAT.[RowNum]                                                                    AS [RowNum]                         --[INTEGER]           NOT NULL
	,CAST(FORMAT(TB_DAT.[DataUpdated_L2Brand]   ,'yyyy-MM-dd H:mm:ss') AS VARCHAR)      AS [DataUpdated_L2Brand]            --[datetime]          NULL
	,CAST(FORMAT(TB_DAT.[DataUpdated_LCA]       ,'yyyy-MM-dd H:mm:ss') AS VARCHAR)      AS [DataUpdated_LCA]                --[datetime]          NULL
	,CAST(FORMAT(TB_DAT.[DateUpdated_DLI]       ,'yyyy-MM-dd H:mm:ss') AS VARCHAR)      AS [DateUpdated_DLI]                --[datetime]          NULL
	,CAST(FORMAT(TB_DAT.[DateUpdated_Priority]  ,'yyyy-MM-dd H:mm:ss') AS VARCHAR)      AS [DateUpdated_Priority]           --[datetime]          NULL
	,CAST(CAST(TB_DAT.[DueDate] AS DATE)    AS VARCHAR)                                 AS [DueDate]                        --[datetime2](0)      NULL
    ,TB_DAT.[Week]                                                                      AS [Week]     
    ,YEAR(TB_DAT.[DueDate])                                                             AS [YearDueDate]
    ,SUBSTRING(DATENAME(MONTH,TB_DAT.[DueDate]),0,4)                                                            AS [MonthDueDate]
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[CustName]       ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))                   AS [CustName] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[Order_No]       ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))                   AS [Order_No] 
	,CAST(TB_DAT.[ItemDetailID] AS VARCHAR)                                             AS [ItemDetailID]                   --[int]               NULL
	,TB_DAT.[Quantity]                                                                  AS [Quantity]                       --[int]               NULL
	,CAST(TB_DAT.[DetailStatus] AS VARCHAR)                                             AS [DetailStatus]                   --[smallint]          NULL
	,CAST(TB_DAT.[SKUStatus] AS VARCHAR)                                                AS [SKUStatus]                      --[int]               NULL
	,CAST(TB_DAT.[Status] AS VARCHAR)                                                   AS [Status]                         --[smallint]          NULL
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[LogoStyle]            ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [LogoStyle] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[ApplicationType]            ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [EmbroideryApplication] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[GroupID]              ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [GroupID] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[RS_Priority]          ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [RS_Priority] 
    ,TB_DAT.[ShipEarly]                                                                 AS [ShipEarly]                      --[int]               NULL
	,REPLACE(REPLACE(REPLACE(TB_DAT.[Style Color], CHAR(9), ''), CHAR(10), ''), CHAR(13), '')                    AS [Style Color]                    --[nvarchar](50)      NULL
	,CAST(TB_DAT.[StyleID] AS VARCHAR)                                                  AS [StyleID]                        --[nvarchar](75)      NULL
	,CAST(TB_DAT.[CSRID] AS VARCHAR)                                                    AS [CSRID]                          --[int]               NULL
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[CSRName]              ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [CSRName] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[Style Sales Status]   ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [Style Sales Status]
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[DesignNo]             ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [DesignNo]
	,CAST(TB_DAT.[SKUID] AS VARCHAR)					 																															  AS [SKUID]
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[SKLogoNo]             ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [SKLogoNo] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[CustPO]               ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [CustPO]
	,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[Product Division]               ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [Product Division]
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[Type]                 ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [Type] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[Group]                ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [Group] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[SalesChannel]         ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [SalesChannel] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[ArtStatus]            ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [ArtStatus] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[PONumber]             ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [PONumber] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[OrderID]              ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [OrderID] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[WorkID]               ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [WorkID] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[APS]                  ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [APS] 
	,CAST(CAST(TB_DAT.[OrderDate]    AS DATE)    AS VARCHAR)                            AS [OrderDate]                      --[date]              NULL
	,CAST(CAST(TB_DAT.[CreateORD]    AS DATE)    AS VARCHAR)                            AS [CreateORD]                      --[date]              NULL
	,CAST(CAST(TB_DAT.[CreateMO]     AS DATE)    AS VARCHAR)                            AS [CreateMO]                       --[date]              NULL
	,CAST(CAST(TB_DAT.[RequiredDate]  AS DATE)  AS VARCHAR)                           AS [RequiredDate]                   --[date]              NULL
	,CAST(TB_DAT.[MO_ID]  AS VARCHAR)                                                   AS [MO_ID]                          --[int]               NULL
	,REPLACE(REPLACE(REPLACE(TB_DAT.[MO], CHAR(9), ''), CHAR(10), ''), CHAR(13), '')    AS [MO]                             --[nvarchar](40)      NULL
	,CAST(TB_DAT.[MOStatusID] AS VARCHAR)                                               AS [MOStatusID]                     --[tinyint]           NULL
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[MOStatus]                  ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [MOStatus] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[Style]                     ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [Style] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[Season]                    ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [Season] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[Color]                     ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [Color] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[ColorDescription]          ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [ColorDescription] 
	,TB_DAT.[Make]                                                                      AS [Make]                           --[float]             NULL
	,CAST(CAST(TB_DAT.[SewingDate]  AS DATE)  AS VARCHAR)                               AS [SewingDate]                     --[smalldatetime]     NULL
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[PWModulo]                     ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [PWModulo] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[Bucket]                       ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [Bucket] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[ProductionStatus]             ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [ProductionStatus] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[PreviewLCAComments]           ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [PreviewLCAComments] 
	,REPLACE(REPLACE(REPLACE(TB_DAT.[Availability], CHAR(9), ''), CHAR(10), ''), CHAR(13), '')        AS [Availability]                   --[nvarchar](100)     NULL
	,REPLACE(REPLACE(REPLACE(TB_DAT.[FabricDD], CHAR(9), ''), CHAR(10), ''), CHAR(13), '')            AS [FabricDD]                       --[nvarchar](200)     NULL
	,CAST(TB_DAT.[OrderTypeID] AS VARCHAR)                                              AS [OrderTypeID]                    --[int]               NULL
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[OrderTypeDescription]         ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [OrderTypeDescription] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[Waybill]                      ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [Waybill] 
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[PACKING]                      ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [PACKING] 
	,CAST(CAST(TB_DAT.[ShipDate] AS DATE) AS VARCHAR)                                   AS [ShipDate]                       --[date]              NULL
	-- ,CASE 
    --     WHEN TBCust.[LCAComments] IS NOT NULL 
	--         THEN TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TBCust.[LCAComments],'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),'')) 
    --     ELSE 
	-- 		--TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(CONCAT(RIGHT('0000' + CAST(OrderReport AS VARCHAR), 4)   ,',',TB_DAT.[LCAComments]),'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))  
	-- 		---CAMBIO SOLICITADO POR PLANNING Y DANILO FLORES
	-- 		TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(CONCAT(RIGHT('0000' + CAST(OrderReport AS VARCHAR), 4)   ,',',
    --         IIF(TB_DAT.[LCAComments] = 'Shipped', TB_DAT.[LCAComments], ISNULL(TB_DAT.[ProductionStatus],TB_DAT.[LCAComments]))),'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))  
    --     END                                                                             AS [LCAComments]                    --[varchar](100)      NULL
	,CASE 
        WHEN TBCust.[LCAComments] IS NOT NULL 
	        THEN TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TBCust.[LCAComments],'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),'')) 
        ELSE 
			TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(CONCAT(RIGHT('0000' + CAST(OrderReport AS VARCHAR), 4)   ,',',TB_DAT.[LCAComments]),'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))  
			
        END                                                                             AS [LCAComments]                    --[varchar](100)      NULL

    ,REPLACE(REPLACE(REPLACE(ISNULL(TBCust.[NewBucket], TB_DAT.[NewBucket]), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')  AS [NewBucket]                      --[varchar](100)      NULL
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[VolumeDAT]                 ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [VolumeDAT] 
    -- ,TB_DAT.[VolumeDAT]                                                                 AS [VolumeDAT]                      --[float]             NULL
    ,CAST(TB_DAT.[OrderDispatch] AS VARCHAR)                                            AS [OrderDispatch]                  --[int]               NULL
    ,TB_DAT.[DaysArriveInPacking]                                                       AS [DaysArriveInPacking]            --[int]               NULL
    ,TB_DAT.[DateInPacking]                                                             AS [DateInPacking]                  --[varchar](50)       NULL
    ,CAST(TB_DAT.[TakeForProcedure] AS VARCHAR)                                         AS [TakeForProcedure] 	            --[int]               NULL
	,CAST(CAST(TB_DAT.[DateArriveInPackingForOrder]   AS DATE) AS VARCHAR)              AS [DateArriveInPackingForOrder]    --[date]              NULL
    ,TB_DAT.[OrderForProcedure]                                                         AS [OrderForProcedure]              --[int]               NULL
	,CAST(CAST(TB_DAT.[DateForConteiner]   AS DATE)   AS VARCHAR)                       AS [DateForConteiner]               --[date]              NULL
    ,TB_DAT.[LateOrder]                                                                 AS [LateOrder]                      --[int]               NULL
    ,TB_DAT.[DaysLateOrder]                                                             AS [DaysLateOrder]                  --[int]               NULL
    ,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(replace(REPLACE(REPLACE(TB_DAT.[Comments]                 ,'"',' ') ,'\\',''),'\',''),'"',' '),CHAR(10),''),CHAR(9),''),CHAR(13),''))         AS [Comments] 
    -- ,TB_DAT.[Comments]                                                                  AS [Comments]                       --[varchar](250)      NULL
    ,TB_DAT.[Rev_DueDate]                                                               AS [Rev_DueDate]                    --[int]               NULL
    ,CAST(CAST(TB_DAT.[inv_pack_date]    AS DATE)    AS VARCHAR)                        AS [inv_pack_date]                  --[date]              NULL
    ,CASE
        WHEN LEFT(ISNULL(TBCust.[NewBucket], TB_DAT.[NewBucket]) ,6) = 'Review'
        THEN 1
        ELSE 0 END                                                                      AS [Review]
    ,TB_DAT.[ShipTo]       
    ,CAST(CAST(TB_DAT.[CustDueDate]   AS DATE) AS VARCHAR)  AS [CustDueDate]
	,TB_DAT.MachineGroup																AS [MachineGroup]
	,TB_DAT.[OrderType]																	AS [OrderType]
	,TB_DAT.[Status/Date]																AS [Status/Date]
	,TB_DAT.[Relabel]																	AS [Relabel]
	,TB_DAT.[License Sticker]															AS [License Sticker]
	,TB_DAT.[Application Type]															AS [Application Type]
	,TB_DAT.[Hot Order]																	AS [Hot Order]
	,ISNULL(CAST(CAST(TB_DAT.[EventDate] AS date) AS VARCHAR),'')						AS [EventDate]
	,TB_DAT.[Collection]																AS [Collection]
FROM #TB_DATA AS TB_DAT
LEFT OUTER JOIN #TB_CustName AS TBCust  ON TBCust.[CustName] = TB_DAT.[CustName]
                                            AND TBCust.[Type] = TB_DAT.[Type]
-- WHERE [PONumber] LIKE '%2601515%'
--WHERE [Product Division] = 'Bundles'
ORDER BY [RowNum]

-- -- PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  FIN SELECT FINAL')



END
