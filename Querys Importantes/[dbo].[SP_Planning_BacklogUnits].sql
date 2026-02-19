



SET NOCOUNT ON
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA FECHAS DE CONTENEDOR--------------------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        ----Explicacion del procedimiento para fechas de contenedor
        -------------------         Qu� hace el bloque
        ------------------- Inicializa par�metros de planificaci�n: fecha del siguiente contenedor (@NextContainer), horizonte de 90 d�as, desfase de due date (@DueDateContainer), capacidad por contenedor, etc.
        ------------------- Alinea @Fecha_i al siguiente jueves o domingo seg�n el d�a actual si @ContainersPerWeek = 0 (patr�n jueves/domingo solicitado).
        ------------------- Usa un CTE recursivo (CTE_Dates) en vez de WHILE para generar secuencialmente las fechas de contenedor:
        ------------------- Parte de @Fecha_i como fila 1.
        ------------------- Si la fecha es jueves (weekday=5) salta 3 d�as ? domingo; si es domingo (weekday=1) salta 4 d�as ? jueves.
        ------------------- Contin�a mientras la nueva fecha no pase @LastContainer.
        ------------------- Inserta el resultado en #TB_FINAL_PROC_DATES calculando:
        ------------------- Row: consecutivo.
        ------------------- Date_Container y su nombre de d�a.
        ------------------- DueDate_Container = fecha + @DueDateContainer d�as y su nombre de d�a.
        ------------------- Capacidad m�xima y valores iniciales de cajas/unidades en 0.
        ------------------- Ajusta @LastContainer al m�ximo generado (�ltimo contenedor) y al final hace SELECT * para devolver la tabla.
        ------------------- Por qu� es equivalente al WHILE
        ------------------- El CTE recursivo replica la l�gica de incrementos 3/4 d�as y termina con el mismo l�mite @LastContainer, pero sin bucle imperativo; RowNum sustituye al contador @i.
        ------------------- C�mo verificar
        ------------------- Ejecuta el procedimiento y revisa que la secuencia sea jueves ? domingo ? jueves, etc., hasta ~90 d�as; confirma que DueDate_Container suma los 15 d�as configurados.
        
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO PROCEDIMIENTO PARA FECHAS DE CONTENEDOR')
            
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA FECHAS DE CONTENEDOR. DROP/CREATE #TB_FINAL_PROC_DATES')
            DROP TABLE IF EXISTS #TB_FINAL_PROC_DATES
            CREATE TABLE #TB_FINAL_PROC_DATES (
                 [Row]                  INTEGER NOT NULL
                ,[RowData]              BIGINT  NULL
                ,[Date_Container]       DATE    NOT NULL
                ,[Day_Container]        NVARCHAR(50)
                ,[DueDate_Container]    DATE    NOT NULL
                ,[DueDay_Conteiner]     NVARCHAR(50)
                ,[Max_InContainer]      FLOAT
                ,[Box_InContainer]      FLOAT
                ,[Units_InContainer]    INTEGER
            )
        
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA FECHAS DE CONTENEDOR. PARAMETROS INICIALES')
            DECLARE @NextContainer      AS DATE
            DECLARE @DueDateContainer   AS INTEGER        ---Dias que se le restara a la fecha de contenedor para tomar el DUE DATE DE LAS ORDENES
            DECLARE @UnitVolume         AS FLOAT
            DECLARE @UnitsInBox         AS INTEGER
            DECLARE @TotalInContainer   AS FLOAT
            DECLARE @DaysLastContainer  AS INT
            DECLARE @ContainersPerWeek  AS INTEGER
            DECLARE @LastContainer      AS DATE      ---SE ASUME QUE EL ULTIMO CONTENEDOR SIEMPRE ES VIERNES
            DECLARE @Fecha_i            AS DATE
    
            SET @NextContainer          = CAST(GETDATE() AS DATE)
            SET @DaysLastContainer      = 90                            ---Ultimo contenedor dentro de tres meses, del dia viernes.
            SET @DueDateContainer       = 15
            SET @UnitVolume             = 1
            SET @UnitsInBox             = 50
            SET @TotalInContainer       = 920 ---CAJAS
            SET @ContainersPerWeek      = 0
            SET @LastContainer          = DATEADD(WK,DATEDIFF(WK,4,DATEADD(DAY,@DaysLastContainer,@NextContainer)),4) 
            SET @Fecha_i                = @NextContainer
                
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA FECHAS DE CONTENEDOR. AJUSTE FECHA INICIAL')
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

            
            ----CTE Recursiva para generar las fechas de contenedor a partir de la fecha inicial, hasta el ultimo contenedor definido 
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA FECHAS DE CONTENEDOR. CTE_Dates + INSERT #TB_FINAL_PROC_DATES')
            ;WITH CTE_Dates AS (
                SELECT 
                     [RowNum] = 1
                    ,[Fecha]  = @Fecha_i
                WHERE @Fecha_i <= @LastContainer
                UNION ALL
                SELECT 
                     [RowNum]   = [RowNum] + 1
                    ,[Fecha]    = DATEADD(DAY, CASE WHEN DATEPART(WEEKDAY,[Fecha]) = 5 THEN 3 ELSE 4 END, [Fecha])
                FROM CTE_Dates
                WHERE DATEADD(DAY, CASE WHEN DATEPART(WEEKDAY,[Fecha]) = 5 THEN 3 ELSE 4 END, [Fecha]) <= @LastContainer
            )
            
            INSERT INTO #TB_FINAL_PROC_DATES   (       
                [Row]
                ,[RowData]
                ,[Date_Container]
                ,[Day_Container]
                ,[DueDate_Container]
                ,[DueDay_Conteiner]
                ,[Max_InContainer]
                ,[Box_InContainer]
                ,[Units_InContainer] 
            )
            SELECT  
                [Row]                   = [RowNum]
               ,[RowData]               = [RowNum]
               ,[Date_Container]        = [Fecha]
               ,[Day_Container]         = DATENAME(WEEKDAY,[Fecha])
               ,[DueDate_Container]     = DATEADD(DAY,@DueDateContainer,[Fecha])
               ,[DueDay_Conteiner]      = DATENAME(WEEKDAY,DATEADD(DAY,@DueDateContainer,[Fecha]))
               ,[Max_InContainer]       = @TotalInContainer
               ,[Box_InContainer]       = 0.0000
               ,[Units_InContainer]     = 0.0000
            FROM CTE_Dates
            OPTION (MAXRECURSION 0)


            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA FECHAS DE CONTENEDOR. CALCULO LAST CONTAINER')
            SET @LastContainer = (SELECT MAX([Date_Container]) FROM #TB_FINAL_PROC_DATES )
            
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    PROCEDIMIENTO PARA FECHAS DE CONTENEDOR')
            -- SELECT * FROM #TB_FINAL_PROC_DATES
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA FECHAS DE CONTENEDOR--------------------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        
        



        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO-----------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO')

            ----Explicacion del procedimiento para ordenes activas para despacho
            -------------------         Que hace el bloque
            ------------------- Limpia tablas temporales (final e intermedias) para evitar residuos de ejecuciones previas.
            ------------------- Construye la base de demanda por talla desde MO/Order/Style y reglas de filtrado de planeacion.
            ------------------- Convierte la demanda a formato pivot por tallas (XS, S, M, etc.).
            ------------------- Crea tabla final temporal #TB_FINAL_PROC_ORDENES_DEMAND con estructura destino.
            ------------------- Prepara tablas auxiliares de grupo (MO e ItemDetailID) para acotar joins de lookups.
            ------------------- Carga lookups (L2, Box, SalesStyle, Export Order, ETA, OrdersSuspended) en tablas temporales.
            ------------------- Actualiza la tabla final por etapas con UPDATE (alias S/B) para enriquecer campos de negocio.
            ------------------- Conserva la tabla final y limpia solo tablas intermedias al cierre del bloque.
            -------------------     Filtros utilizados
            -------------------         StatusID de MO IN (20,40)
            -------------------             20 = Forecast
            -------------------             40 = Released
            -------------------         ManufactureDetails.QuantityOrdered > 0
            -------------------         SeasonName IS NULL o NOT IN ('BLANK','Blank RO','Blank FG')
            -------------------         Exclusion de estilos no productivos y excepcion StyleNumber LIKE 'PROTO%'
            -------------------         PONumber NOT LIKE 'SM%' y NOT LIKE 'IO%'
            -------------------         StyleSubcategory <> 'Sublimation' o StyleNumber = '31144'
            
        	DROP TABLE IF EXISTS #TB_FINAL_PROC_ORDENES_DEMAND                        ---Tabla final de ordenes para despacho con campos enriquecidos
        	
        	DROP TABLE IF EXISTS #TB_MOS_ORDENES_DEMAND_BY_SIZE                ---Tabla base de demanda por talla (detalle por Size)
        	DROP TABLE IF EXISTS #TB_MOS_ORDENES_DEMAND_PIVOT                  ---Tabla de demanda pivot por tallas en columnas
        	DROP TABLE IF EXISTS #TB_GROUP_MOS_ORDENES_DEMAND                  ---Tabla auxiliar para agrupacion de MOs de demanda
        	DROP TABLE IF EXISTS #TB_GROUP_ITEMDETAILID_ORDENES_DEMAND         ---Tabla auxiliar para agrupacion de ItemDetailID de demanda
        	DROP TABLE IF EXISTS #TB_LOOKUP_L2                                 ---Tabla lookup de datos L2 por ItemDetailID (SKU/Logo/Status/CustPO)
        	DROP TABLE IF EXISTS #TB_LOOKUP_BOX                                ---Tabla lookup de primer FirstBlankBoxNumber por ManufactureID
        	DROP TABLE IF EXISTS #TB_LOOKUP_SALESSTYLE                         ---Tabla lookup de equivalencia Style Embroidery -> Style Blank
        	DROP TABLE IF EXISTS #TB_LOOKUP_ORD                                ---Tabla lookup de export order (Color/MachineGroup/Relabel/DocDate)
        	DROP TABLE IF EXISTS #TB_LOOKUP_ETA                                ---Tabla lookup de tipo de aplicacion por LogoStyle
        	DROP TABLE IF EXISTS #TB_LOOKUP_OS                                 ---Tabla lookup de ordenes suspendidas por ManufactureID
            
            
            
            SELECT 
                *
            INTO #TB_MOS_ORDENES_DEMAND_BY_SIZE
            FROM(
                SELECT
                      [ordenEmb]                   = TB2.[ordenTomado]
                     ,[KeyT]                       = CAST(TB2.[ordenTomado] AS VARCHAR(20)) + '-' + CAST(TB2.[SeasonName] AS VARCHAR(100))
                     ,[KeyStyle]                   = TB2.[Style] + '-' + TB2.[Color]
                     ,[Style]                      = TB2.[Style]
                     ,[Season]                     = TB2.[SeasonName]
                     ,[Color]                      = TB2.[Color]
                     ,[ColorDescription]           = TB2.[ColorDescription]
                     ,[POStat]                     = TB2.[Status]
                     ,[OrderID]                    = TB2.[OrderID]
                     ,[PONum]                      = TB2.[PONumber]
                     ,[MO_ID]                      = TB2.[MO_ID]
                     ,[Purno]                      = TB2.[MO]
                     ,[RequiredDate]               = TB2.[RequiredDate]
                     ,[Size]                       = TB2.[Size]
                     ,[QTY]                        = TB2.[MAKE1]
                     ,[StyleSubcategory]           = TB2.[StyleSubcategory]
                     ,[StockCategory]              = TB2.[StockCategory]
                     ,[APS]                        = TB2.[APS]
                     ,[ItemDetailID]             = CASE 
    		                                            WHEN ( TB2.[PONumber] LIKE 'ORD-PO%') THEN
    		                                                NULL
    		                                            WHEN ( TB2.[PONumber] LIKE 'ORD-%') AND ( ISNUMERIC ( REPLACE ( TB2.[PONumber],'ORD-','') ) = 1)  THEN
    		                                                cast(REPLACE ( TB2.[PONumber],'ORD-','') AS BIGINT) 
    		                                            WHEN ( TB2.[PONumber] LIKE 'ORD%') AND (ISNUMERIC(TB2.Comments6) = 1 ) THEN
    		                                                cast(TB2.[Comments6] AS BIGINT)
    		                                            ELSE
    		                                                NULL 
    		                                            END 
                     ,[Collection]                 = TB2.[Collection]
                FROM (
    					SELECT 
    						  [ordenTomado]                = CASE
    																WHEN SN.[StatusID] = 40 THEN '1' ----'Released'
    																WHEN SN.[StatusID] = 20 THEN '2' ----'Forecast'
    															END
    						 ,[MO_ID]                      = MO.[ManufactureID]
    						 ,[MO]                         = MO.[ManufactureNumber]
    						 ,[PONumber]                   = Ord.[PONumber]
    						 ,[Style]                      = st.[StyleNumber]
    						 ,[Season]                     = seas.[SeasonName]        
    						 ,[Color]                      = stc.[StyleColorName]
    						 ,[ColorDescription]           = stc.[StyleColorDescription]
    						 ,[Size]                       = fg.[GarmentSize]
    						 ,[TypeSize]                   = CASE
    															WHEN fg.[GarmentSize] IN ('XS','2T')       THEN 'A'
    															WHEN fg.[GarmentSize] IN ('S','3T')        THEN 'B'
    															WHEN fg.[GarmentSize] IN ('M','4T')        THEN 'C'
    															WHEN fg.[GarmentSize] IN ('L','5T')        THEN 'D'
    															WHEN fg.[GarmentSize] IN ('XL','6T')       THEN 'E'
    															WHEN fg.[GarmentSize] IN ('2XL','7T')      THEN 'F'
    															WHEN fg.[GarmentSize] IN ('3XL','8T')      THEN 'G'
    															WHEN fg.[GarmentSize] = '4XL'              THEN 'H'
    															WHEN fg.[GarmentSize] = '5XL'              THEN 'I'
    															WHEN fg.[GarmentSize] IN ('QTY','ADJ')     THEN 'ADJ'
    															WHEN fg.[GarmentSize] = 'S/M'              THEN 'U'
    															WHEN fg.[GarmentSize] = 'L/XL'             THEN 'U'
    															WHEN fg.[GarmentSize] = 'S_M'              THEN 'U'
    															WHEN fg.[GarmentSize] = 'L_XL'             THEN 'U'
    														END
    						 ,[MAKE1]                      = SUM(md.[QuantityOrdered])
    						 ,[Status]                     = SN.[StatusName]
    						 ,[OrderID]                    = ord.[OrderID]
    						 ,[Bucket]                     = REPLACE(MO.[Comments3],'BU ','')
    						 ,[SeasonName]                 = seas.[SeasonName]
    						 ,[RequiredDate]               = ISNULL(OI.[requiredDate],ord.[requiredDate])
    						 ,[StyleSubcategory]           = stct.[StyleSubcategoryName]
    						 ,[StockCategory]              = ISNULL(strg.[RegionName],'')
    						 ,[APS]                        = ord.[Comments6]
    						 ,[Collection]                 = STCL.[CollectionName]
    						 ,[Comments6]                  = ord.[Comments6]
    					FROM (SELECT StatusID,StatusName FROM [LCA].[dbo].StatusNames WITH(NOLOCK) WHERE [StatusID] IN(20,40) ) AS SN ---20 Forecast, 40 Released
    					INNER JOIN  [LCA].[dbo].ManufactureOrders        AS MO    WITH(NOLOCK) ON SN.StatusID          = MO.StatusID            AND MO.[StatusID] IN(20,40) ---20 Forecast, 40 Released
    					INNER JOIN  [LCA].[dbo].ManufactureDetails       AS md    WITH(NOLOCK) ON md.ManufactureID     = mo.ManufactureID       AND md.QuantityOrdered > 0 
    					LEFT JOIN   [LCA].[dbo].FinishedGoods            AS fg    WITH(NOLOCK) ON fg.FinishedGoodsID   = md.FinishedGoodsID
    					LEFT JOIN   [LCA].[dbo].StyleColors              AS stc   WITH(NOLOCK) ON stc.StyleColorID     = fg.StyleColorID
    					LEFT JOIN   [LCA].[dbo].Styles                   AS st    WITH(NOLOCK) ON st.StyleID           = fg.StyleID
    					LEFT JOIN   [LCA].[dbo].Seasons                  AS seas  WITH(NOLOCK) ON seas.SeasonID        = st.SeasonID
    					LEFT JOIN   [LCA].[dbo].Orders                   AS ord   WITH(NOLOCK) ON ord.OrderID          = MO.OrderID
    					LEFT JOIN   [LCA].[dbo].StyleCategories          AS stct  WITH(NOLOCK) ON stct.StyleCategoryID = st.StyleCategoryID
    					LEFT JOIN   [LCA].[dbo].StyleRegions             AS strg  WITH(NOLOCK) ON strg.RegionID        = st.RegionID
    					LEFT JOIN   [LCA].[dbo].OrderItems	             AS OI	  WITH(NOLOCK) ON OI.OrderItemID	   = MO.FirstOrderItemID
    					LEFT JOIN   [LCA].[dbo].StyleCollections         AS STCL  WITH(NOLOCK) ON ST.CollectionID      = STCL.CollectionID
    					WHERE (
    							seas.[SeasonName] IS NULL
    							OR seas.[SeasonName] NOT IN ('BLANK','Blank RO','Blank FG')
    						  )
    						  AND ( st.[StyleNumber] NOT IN (
            										'Accessories'
            										,'Accessories By Size'
            										,'Fabric Sales'
            										,'Fabric Sales II'
            										,'Fabric Sales III'
            										,'Fabric Sales IV'
            										,'DTG SWATCH'
            										,'1CopyStyle  NO BORRAR'
            										,'642WBT (Test BOMs)'
            										,'Returned Fabric'
            										,'SWATCH'
            										,'CSB605'
            										,'CSB375'
            										,'LA040'
            										,'PC400'
            										,'PC450'
            										,'PC480'
    										)
    									OR  (st.[StyleNumber] LIKE 'PROTO%')
    					        )
    					        AND ord.PONumber NOT LIKE 'SM%'
    					        AND ord.PONumber NOT LIKE 'IO%'
    					        AND (stct.[StyleSubcategoryName] <> 'Sublimation' OR st.[StyleNumber] = '31144')
    					GROUP BY  
    						 ord.[OrderID]
    						,Ord.[PONumber]
    						,MO.[ManufactureID]
    						,MO.[ManufactureNumber]
    						,sn.[StatusName]
    						,sn.[StatusID]
    						,st.[StyleID]
    						,st.[StyleNumber]
    						,seas.[SeasonName]        
    						,stc.[StyleColorName]
    						,stc.[StyleColorDescription]
    						,fg.[GarmentSize]
    						,REPLACE(MO.[Comments3], 'BU ', '')
    						,seas.[SeasonName]
    						,ISNULL(OI.[requiredDate], ord.[requiredDate])
    						,stct.[StyleSubcategoryName]
    						,ISNULL(strg.[RegionName], '')
    						,ord.[Comments6]
    						,STCL.[CollectionName]
                    ) AS TB2
		    ) AS TB_T

            
            SELECT DISTINCT [MO_ID]         INTO #TB_GROUP_MOS_ORDENES_DEMAND           FROM #TB_MOS_ORDENES_DEMAND_BY_SIZE
            SELECT DISTINCT [ItemDetailID]  INTO #TB_GROUP_ITEMDETAILID_ORDENES_DEMAND  FROM #TB_MOS_ORDENES_DEMAND_BY_SIZE
            
            SELECT
                 *
            INTO #TB_MOS_ORDENES_DEMAND_PIVOT
            FROM (
                SELECT 
                    *
                FROM #TB_MOS_ORDENES_DEMAND_BY_SIZE AS TB_T
            ) AS TB_T
            PIVOT  
                (  
                    SUM(TB_T.[QTY])  
                    FOR TB_T.[SIZE] IN  
                        ( [XS],[S],[M],[L],[XL],[2XL],[3XL],[4XL],[5XL],[2T],[3T],[4T],[5T],[6T],[7T],[8T],[ADJ],[S_M],[L_XL],[S/M],[L/XL],[ONE] )  
                ) AS pvt

             

            SELECT
                 [RowData]               = ROW_NUMBER() OVER (
                                                ORDER BY TB_ALL_PIVOT.[Style] ASC, TB_ALL_PIVOT.[Color] ASC, TB_ALL_PIVOT.[ordenEmb] ASC, TB_ALL_PIVOT.[RequiredDate] ASC, TB_ALL_PIVOT.[OrderID] ASC
                                            )
                ,[ordenEmb]              = TB_ALL_PIVOT.[ordenEmb]
                ,[KeyT]                  = TB_ALL_PIVOT.[KeyT]
                ,[KeyStyle]              = TB_ALL_PIVOT.[KeyStyle]
                ,[Style]                 = TB_ALL_PIVOT.[Style]
                ,[Season]                = TB_ALL_PIVOT.[Season]
                ,[Color]                 = TB_ALL_PIVOT.[Color]
                ,[ColorDescription]      = TB_ALL_PIVOT.[ColorDescription]
                ,[StatusOrder]           = TB_ALL_PIVOT.[POStat]
                ,[OrderID]               = TB_ALL_PIVOT.[OrderID]
                ,[PONumber]              = TB_ALL_PIVOT.[PONum]
                ,[ItemDetailID]          = TB_ALL_PIVOT.[ItemDetailID]
                ,[Barcode]               = 'PPMO' + LTRIM(STR(TB_ALL_PIVOT.[MO_ID] + 1000000))
                ,[MO_ID]                 = TB_ALL_PIVOT.[MO_ID]
                ,[MO]                    = TB_ALL_PIVOT.[Purno]
                ,[L2_Color]              = CAST(''      AS VARCHAR(100))
                ,[RequiredDate]          = TB_ALL_PIVOT.[RequiredDate]
                ,[StyleSubcategory]      = TB_ALL_PIVOT.[StyleSubcategory]
                ,[StockCategory]         = TB_ALL_PIVOT.[StockCategory]
                ,[APS]                   = TB_ALL_PIVOT.[APS]
                ,[SKUStatus]             = CAST(NULL    AS VARCHAR(100))
                ,[DetailStatus]          = CAST(NULL    AS VARCHAR(100))
                ,[LogoStyle]             = CAST(NULL    AS VARCHAR(100))
                ,[EmbroideryApplication] = CAST(NULL    AS VARCHAR(100))
                ,[GroupID]               = CAST(NULL    AS VARCHAR(100))
                ,[CustPO]                = CAST(NULL    AS VARCHAR(100))
                ,[XS]                    = ISNULL(TB_ALL_PIVOT.[XS], 0)
                ,[S]                     = ISNULL(TB_ALL_PIVOT.[S], 0)
                ,[M]                     = ISNULL(TB_ALL_PIVOT.[M], 0)
                ,[L]                     = ISNULL(TB_ALL_PIVOT.[L], 0)
                ,[XL]                    = ISNULL(TB_ALL_PIVOT.[XL], 0)
                ,[2XL]                   = ISNULL(TB_ALL_PIVOT.[2XL], 0)
                ,[3XL]                   = ISNULL(TB_ALL_PIVOT.[3XL], 0)
                ,[4XL]                   = ISNULL(TB_ALL_PIVOT.[4XL], 0)
                ,[5XL]                   = ISNULL(TB_ALL_PIVOT.[5XL], 0)
                ,[2T]                    = ISNULL(TB_ALL_PIVOT.[2T], 0)
                ,[3T]                    = ISNULL(TB_ALL_PIVOT.[3T], 0)
                ,[4T]                    = ISNULL(TB_ALL_PIVOT.[4T], 0)
                ,[5T]                    = ISNULL(TB_ALL_PIVOT.[5T], 0)
                ,[6T]                    = ISNULL(TB_ALL_PIVOT.[6T], 0)
                ,[7T]                    = ISNULL(TB_ALL_PIVOT.[7T], 0)
                ,[8T]                    = ISNULL(TB_ALL_PIVOT.[8T], 0)
                ,[ADJ]                   = ISNULL(TB_ALL_PIVOT.[ADJ], 0)
                ,[S_M]                   = ISNULL(TB_ALL_PIVOT.[S_M], 0)
                ,[L_XL]                  = ISNULL(TB_ALL_PIVOT.[L_XL], 0)
                ,[S/M]                   = ISNULL(TB_ALL_PIVOT.[S/M], 0)
                ,[L/XL]                  = ISNULL(TB_ALL_PIVOT.[L/XL], 0)
                ,[ONE]                   = ISNULL(TB_ALL_PIVOT.[ONE], 0)
                ,[Make]                  = ISNULL(TB_ALL_PIVOT.[XS], 0)
                                           + ISNULL(TB_ALL_PIVOT.[S], 0)
                                           + ISNULL(TB_ALL_PIVOT.[M], 0)
                                           + ISNULL(TB_ALL_PIVOT.[L], 0)
                                           + ISNULL(TB_ALL_PIVOT.[XL], 0)
                                           + ISNULL(TB_ALL_PIVOT.[2XL], 0)
                                           + ISNULL(TB_ALL_PIVOT.[3XL], 0)
                                           + ISNULL(TB_ALL_PIVOT.[4XL], 0)
                                           + ISNULL(TB_ALL_PIVOT.[5XL], 0)
                                           + ISNULL(TB_ALL_PIVOT.[2T], 0)
                                           + ISNULL(TB_ALL_PIVOT.[3T], 0)
                                           + ISNULL(TB_ALL_PIVOT.[4T], 0)
                                           + ISNULL(TB_ALL_PIVOT.[5T], 0)
                                           + ISNULL(TB_ALL_PIVOT.[6T], 0)
                                           + ISNULL(TB_ALL_PIVOT.[7T], 0)
                                           + ISNULL(TB_ALL_PIVOT.[8T], 0)
                                           + ISNULL(TB_ALL_PIVOT.[ADJ], 0)
                                           + ISNULL(TB_ALL_PIVOT.[S_M], 0)
                                           + ISNULL(TB_ALL_PIVOT.[L_XL], 0)
                                           + ISNULL(TB_ALL_PIVOT.[S/M], 0)
                                           + ISNULL(TB_ALL_PIVOT.[L/XL], 0)
                                           + ISNULL(TB_ALL_PIVOT.[ONE], 0)
                ,[MakeL2]                = CAST(NULL    AS FLOAT)
                ,[DispatchOrd]           = 1
                ,[FirstBlanksBoxNumber]  = CAST(NULL    AS VARCHAR(50))
                ,[CSVDate]               = REPLACE(CONVERT(VARCHAR, GETDATE(), 23), '-', '')
                ,[CSVHour]               = REPLACE(CONVERT(VARCHAR, GETDATE(), 8), ':', '')
                ,[SalesStyle]            = CAST(''      AS VARCHAR(100))
                ,[L2B_OrderStatus]       = CAST(NULL    AS VARCHAR(100))
                ,[MachineGroup]          = CAST(NULL    AS VARCHAR(100))
                ,[Relabel]               = CAST(NULL    AS VARCHAR(100))
                ,[Collection]            = TB_ALL_PIVOT.[Collection]
                ,[DocDate]               = CAST(NULL    AS DATE)
                ,[DiscardMPA]            = CAST(0       AS BIT)
                ,[SuspendOrd]            = CAST(0       AS BIT)
                ,[SuspendType]           = CAST(NULL    AS VARCHAR(100))
            INTO #TB_FINAL_PROC_ORDENES_DEMAND
            FROM #TB_MOS_ORDENES_DEMAND_PIVOT AS TB_ALL_PIVOT

            -----------SELECT PARA TRAER EN TABLAS TEMPORALES LOS DATOS NECESARIOS PARA PLANIFICACION DE DESPACHO DE PRENDAS
                
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_L2')
                SELECT TB.*
                INTO #TB_LOOKUP_L2
                FROM (
                    SELECT
                        L2.*
                        ,ROW_NUMBER() OVER (PARTITION BY L2.[ItemDetailID] ORDER BY L2.[ItemDetailID]) AS R_Num
                    FROM #TB_GROUP_ITEMDETAILID_ORDENES_DEMAND  AS S
                    INNER JOIN [AppsLCA].[dbo].[TB_L2Brand_view_qryOpenOrderSuppl_162] AS L2 WITH(NOLOCK) ON S.[ItemDetailID] = L2.[ItemDetailID]
                ) AS TB
                WHERE TB.R_Num = 1
    
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_BOX')
                SELECT TB.*
                INTO #TB_LOOKUP_BOX
                FROM (
                    SELECT
                         [ManufactureID]    = PB.[AttachedManufactureID]
                        ,[BoxNumber]        = PB.[BoxNumber]
                        ,ROW_NUMBER() OVER(PARTITION BY [AttachedManufactureID] ORDER BY [PackedBoxID]) AS R_Num
                    FROM #TB_GROUP_MOS_ORDENES_DEMAND AS S
                    INNER JOIN [LCA].[dbo].PackedBoxes AS PB WITH(NOLOCK) ON PB.[ManufactureID] = S.[MO_ID]
                ) AS TB
                WHERE TB.R_Num = 1
    
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_SALESSTYLE')
                SELECT TB.*
                INTO #TB_LOOKUP_SALESSTYLE
                FROM (
                    SELECT
                         [ManufactureID]    = ManuDet.[ManufactureID]
                        ,[Style_Blank]      = SalesStyles.[Style_Blank]
                        ,[R_Num]            = ROW_NUMBER() OVER(PARTITION BY ManuDet.[ManufactureID] ORDER BY SalesStyles.[Style_Blank])
                    FROM        #TB_GROUP_MOS_ORDENES_DEMAND AS S
                    INNER JOIN  [LCA].[dbo].[ManufactureDetails]    AS ManuDet  WITH(NOLOCK)    ON S.[MO_ID]                 = ManuDet.[ManufactureID]
                    INNER JOIN  [LCA].[dbo].[FinishedGoods]         AS FGood    WITH(NOLOCK)    ON ManuDet.[FinishedGoodsID] = FGood.[FinishedGoodsID]
                    INNER JOIN (
                                    SELECT
                                         [Style_Emb]
                                        ,[Style_Blank]
                                        ,[StyleID_EMB]
                                    FROM [LCA].[dboReaders].[VW_ESC_StyleStructure] WITH(NOLOCK)
                                    WHERE       [SeasonID_BLANK] IN (27224,1698)  
                                            AND [Style_BLANK] <> [Style_EMB]
                                ) AS SalesStyles    ON FGood.[StyleID] = SalesStyles.[StyleID_EMB]
                ) AS TB
                WHERE TB.[R_Num] = 1
    
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_ORD')
                SELECT TB.*
                INTO #TB_LOOKUP_ORD
                FROM (
                    SELECT
                         ORD.*
                        ,[R_Num]        = ROW_NUMBER() OVER(PARTITION BY ORD.[ItemDetailID] ORDER BY ORD.[ItemDetailID])
                    FROM #TB_GROUP_ITEMDETAILID_ORDENES_DEMAND AS S
                    INNER JOIN [AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export] AS ORD WITH(NOLOCK) ON S.[ItemDetailID] = ORD.[ItemDetailID]
                ) AS TB
                WHERE TB.[R_Num] = 1
    
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_ETA')
                SELECT
                    ETA.[LogoStyle]
                    ,[ApplicationType] = MAX(ETA.[ApplicationType])
                INTO #TB_LOOKUP_ETA
                FROM [AppsLCA].[dbo].[Planning_Backlog_EmbroideryTypeApplique] AS ETA WITH(NOLOCK)
                GROUP BY ETA.[LogoStyle]
    
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_OS')
                SELECT TB.*
                INTO #TB_LOOKUP_OS
                FROM (
                    SELECT
                        OS.[ManufactureID]
                        ,OS.[SWHOLD]
                        ,OS.[SuspendType]
                        ,ROW_NUMBER() OVER(PARTITION BY OS.[ManufactureID] ORDER BY OS.[ManufactureID]) AS R_Num
                    FROM [AppsLCA].[legacycaps].[OrdersSuspended] AS OS WITH(NOLOCK)
                ) AS TB
                WHERE TB.R_Num = 1
            -----------SELECT PARA TRAER EN TABLAS TEMPORALES LOS DATOS NECESARIOS PARA PLANIFICACION DE DESPACHO DE PRENDAS


            -----------UPDATE DE DATOS NECESARIOS PARA PLANIFICACION DE DESPACHO DE PRENDAS
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. UPDATE DE TABLAS TEMPORALES')
                UPDATE S SET
                     [SKUStatus]                = B.[SKUStatus]
                    ,[DetailStatus]             = B.[DetailStatus]
                    ,[LogoStyle]                = B.[LogoStyle]
                    ,[GroupID]                  = B.[GroupID]
                    ,[CustPO]                   = B.[CustPO]
                    ,[MakeL2]                   = B.[Quantity]
                    ,[L2B_OrderStatus]          = B.[Status]
                FROM #TB_FINAL_PROC_ORDENES_DEMAND         AS S
                INNER JOIN #TB_LOOKUP_L2            AS B  ON B.[ItemDetailID] = S.[ItemDetailID]
    
                UPDATE S SET
                    [FirstBlanksBoxNumber]      = B.[BoxNumber]
                FROM #TB_FINAL_PROC_ORDENES_DEMAND         AS S
                INNER JOIN #TB_LOOKUP_BOX           AS B ON B.[ManufactureID] = S.[MO_ID]
    
                UPDATE S SET
                     [SalesStyle]               = B.[Style_Blank]
                    ,[Style]                    = B.[Style_Blank]
                FROM #TB_FINAL_PROC_ORDENES_DEMAND         AS S
                INNER JOIN #TB_LOOKUP_SALESSTYLE    AS B ON B.[ManufactureID] = S.[MO_ID]
    
                UPDATE S SET
                     [L2_Color]                 = ISNULL(B.[Color], '')
                    ,[MachineGroup]             = B.[MachineGroup]
                    ,[Relabel]                  = B.[Relabel]
                    ,[DocDate]                  = B.[Doc Date]
                    ,[DiscardMPA]               = IIF(B.[MovedPerAllocation] = 1 AND B.[Req Ship] >= DATEADD(DAY, 21, GETDATE()), 1, 0)
                FROM #TB_FINAL_PROC_ORDENES_DEMAND         AS S
                INNER JOIN #TB_LOOKUP_ORD           AS B ON B.[ItemDetailID] = S.[ItemDetailID]
    
                UPDATE S SET
                     [EmbroideryApplication]    = B.[ApplicationType]
                FROM #TB_FINAL_PROC_ORDENES_DEMAND         AS S
                INNER JOIN #TB_LOOKUP_ETA           AS B ON B.[LogoStyle] = S.[LogoStyle]
    
                UPDATE S SET
                     [SuspendOrd]               = ISNULL(B.[SWHOLD], 0)
                    ,[SuspendType]              = B.[SuspendType]
                FROM #TB_FINAL_PROC_ORDENES_DEMAND         AS S
                INNER JOIN #TB_LOOKUP_OS            AS B ON B.[ManufactureID] = S.[MO_ID]

            -----------UPDATE DE DATOS NECESARIOS PARA PLANIFICACION DE DESPACHO DE PRENDAS
            
			-----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #TB_FINAL_PROC_ORDENES_DEMAND)
			DROP TABLE IF EXISTS #TB_MOS_ORDENES_DEMAND_BY_SIZE        ---Tabla base de demanda por talla (detalle por Size)
			DROP TABLE IF EXISTS #TB_MOS_ORDENES_DEMAND_PIVOT          ---Tabla de demanda pivot por tallas en columnas
			DROP TABLE IF EXISTS #TB_GROUP_MOS_ORDENES_DEMAND          ---Tabla auxiliar para agrupacion de MOs de demanda
			DROP TABLE IF EXISTS #TB_GROUP_ITEMDETAILID_ORDENES_DEMAND ---Tabla auxiliar para agrupacion de ItemDetailID de demanda
			DROP TABLE IF EXISTS #TB_LOOKUP_L2                         ---Tabla lookup de datos L2 por ItemDetailID (SKU/Logo/Status/CustPO)
			DROP TABLE IF EXISTS #TB_LOOKUP_BOX                        ---Tabla lookup de primer FirstBlankBoxNumber por ManufactureID
			DROP TABLE IF EXISTS #TB_LOOKUP_SALESSTYLE                 ---Tabla lookup de equivalencia Style Embroidery -> Style Blank
			DROP TABLE IF EXISTS #TB_LOOKUP_ORD                        ---Tabla lookup de export order (Color/MachineGroup/Relabel/DocDate)
			DROP TABLE IF EXISTS #TB_LOOKUP_ETA                        ---Tabla lookup de tipo de aplicacion por LogoStyle
			DROP TABLE IF EXISTS #TB_LOOKUP_OS                         ---Tabla lookup de ordenes suspendidas por ManufactureID
			-----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #TB_FINAL_PROC_ORDENES_DEMAND)

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO')
			-- SELECT * FROM #TB_FINAL_PROC_ORDENES_DEMAND
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO-----------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA INVENTARIO ACTIVO-----------------------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE')

            ----Explicacion del procedimiento para inventario activo warehouse
            -------------------         Que hace el bloque
            ------------------- Limpia tablas temporales (final e intermedias) para iniciar el proceso sin residuos.
            ------------------- Construye tabla base de inventario activo por PackedItem con datos de Box, MO, FG, Style y Order.
            ------------------- Genera tablas de grupo por MO y StyleID para acotar las consultas de tablas lookup.
            ------------------- Carga lookups de vendor original, bandera de hangtag y BOM de hangtag en tablas temporales.
            ------------------- Actualiza la tabla base por etapas con UPDATE (alias S/B) para completar campos derivados.
            ------------------- Inserta el resultado final formateado en #TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE.
            ------------------- Conserva la tabla final y elimina solo tablas temporales intermedias al terminar.
            -------------------     Filtros utilizados
            -------------------         PackedBoxes.StatusID IN (0,8,98,100)
            -------------------             0   = New
            -------------------             8   = Inventory
            -------------------             98  = SlowMoving
            -------------------             100 = Obsolete
            -------------------         PackedBoxes.WarehouseID IN (35,53,60)
            -------------------         Warehouses.WarehouseID IN (35,53,60)
            -------------------             35 = Stock Warehouse
            -------------------             53 = Headwear DLI
            -------------------             60 = DLI Block N
            -------------------         PackedItems.Quantity <> 0

			DROP TABLE IF EXISTS #TB_INV_WAREHOUSE_BASE                         ---Tabla base de inventario activo por PackedItem
			DROP TABLE IF EXISTS #TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE     ---Tabla final de inventario activo con formato de salida
			DROP TABLE IF EXISTS #TB_INV_GROUP_MO                               ---Tabla auxiliar de MOs del inventario activo
			DROP TABLE IF EXISTS #TB_INV_GROUP_STYLE                            ---Tabla auxiliar de estilos del inventario activo
			DROP TABLE IF EXISTS #TB_INV_LOOKUP_VENDOR                          ---Tabla lookup de vendor original por ManufactureID
			DROP TABLE IF EXISTS #TB_INV_LOOKUP_TAG                             ---Tabla lookup de bandera RequireHangtag por ManufactureID
			DROP TABLE IF EXISTS #TB_INV_LOOKUP_BOM                             ---Tabla lookup de partnumber de hangtag por StyleID

			PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA BASE')
			SELECT 
				 [PackedBoxID]           = PB.[PackedBoxID]
				,[PackedItemID]          = PBI.[PackedItemID]
				,[CSVBoxNumber]          = 'PPBX' + LTRIM(STR(PB.[PackedBoxID] + 10000000))
				,[GoodsBinID]            = PB.[GoodsBinID]
				,[PackDate]              = COALESCE(PB.[PackDate], MO.[ManufacturedDate])
				,[OriginalPackDate]      = PB.[PackDate]
				,[BoxNumber]             = PB.[BoxNumber]
				,[Quantity]              = PBI.[Quantity]
				,[FinishedGoodsID]       = PBI.[FinishedGoodsID]
				,[PPFG]                  = 'PPFG' + LTRIM(STR(PBI.[FinishedGoodsID] + 1000000))
				,[ManufactureID]         = PBI.[ManufactureID]
				,[WarehouseID]           = WH.[WarehouseID]
				,[StyleID]               = ST.[StyleID]
				,[Style]                 = REPLACE(REPLACE(REPLACE(RTRIM(ST.[StyleNumber]), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')
				,[Season]                = SNsst.[SeasonName]
				,[StockCategory]         = COALESCE(STRG.[RegionName], '')
				,[Color]                 = REPLACE(REPLACE(REPLACE(RTRIM(STC.[StyleColorName]), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')
				,[Size]                  = FG.[GarmentSize]
				,[ManufacturedDate]      = MO.[ManufacturedDate]
				,[MO]                    = COALESCE(MO.[ManufactureNumber], '')
				,[OPTION]                = MO.[Comments17]
				,[TariffCategory]        = MO.[Comments16]
				,[OrderID]               = OD.[OrderID]
				,[PONumber]              = COALESCE(OD.[PONumber], '')
				,[BIN]                   = REPLACE(REPLACE(REPLACE(RTRIM(GB.[Bin]), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')
				,[OrigFabricVendorName]  = CAST('' AS VARCHAR(500))
				,[RequireHangtag]        = CAST(1 AS INT)
				,[PNHangtag]             = CAST('NO Hangtag Assigned' AS VARCHAR(500))
				,[ProductDivison]        = ST.[Comments9]
			INTO #TB_INV_WAREHOUSE_BASE
			FROM			(SELECT [StatusID] FROM [LCA].[dbo].[StatusNames] WITH(NOLOCK) WHERE [StatusID] IN (0, 8, 98, 100))	AS SNPB
				INNER JOIN	[LCA].[dbo].[PackedBoxes]			AS PB		WITH(NOLOCK) ON PB.[StatusID]		  = SNPB.[StatusID]        AND PB.[WarehouseID] IN (35,53,60)
				INNER JOIN	[LCA].[dbo].[Warehouses]			AS WH		WITH(NOLOCK) ON PB.[WarehouseID]	  = WH.[WarehouseID]       AND WH.[WarehouseID] IN (35,53,60)
				INNER JOIN	[LCA].[dbo].[PackedItems]			AS PBI		WITH(NOLOCK) ON PB.[PackedBoxID]	  = PBI.[PackedBoxID]      AND PBI.[Quantity] <> 0
				LEFT JOIN	[LCA].[dbo].[FinishedGoods]			AS FG		WITH(NOLOCK) ON FG.[FinishedGoodsID]  = PBI.[FinishedGoodsID]
				LEFT JOIN	[LCA].[dbo].[Styles]				AS ST		WITH(NOLOCK) ON ST.[StyleID]          = FG.[StyleID]
				LEFT JOIN	[LCA].[dbo].[Seasons]				AS SNsst	WITH(NOLOCK) ON SNsst.[SeasonID]      = ST.[SeasonID]
				LEFT JOIN	[LCA].[dbo].[StyleRegions]			AS STRG		WITH(NOLOCK) ON STRG.[RegionID]       = ST.[RegionID]
				LEFT JOIN	[LCA].[dbo].[StyleColors]			AS STC		WITH(NOLOCK) ON FG.[StyleColorID]     = STC.[StyleColorID]
				LEFT JOIN	[LCA].[dbo].[ManufactureOrders]		AS MO		WITH(NOLOCK) ON MO.[ManufactureID]    = PBI.[ManufactureID]
				LEFT JOIN	[LCA].[dbo].[OrderItems]			AS OI		WITH(NOLOCK) ON OI.[OrderItemID]      = MO.[FirstOrderItemID]
				LEFT JOIN	[LCA].[dbo].[Orders]				AS OD		WITH(NOLOCK) ON OD.[OrderID]          = OI.[OrderID]
				LEFT JOIN	[LCA].[dbo].[GoodsBins]				AS GB		WITH(NOLOCK) ON PB.[GoodsBinID]       = GB.[GoodsBinID]

			PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA TB_INV_GROUP_MO')
			SELECT DISTINCT [MO_ID] = B.[ManufactureID]
			INTO #TB_INV_GROUP_MO
			FROM #TB_INV_WAREHOUSE_BASE AS B

			PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA TB_INV_GROUP_STYLE')
			SELECT DISTINCT [StyleID] = B.[StyleID]
			INTO #TB_INV_GROUP_STYLE
			FROM #TB_INV_WAREHOUSE_BASE AS B

			PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA TB_INV_LOOKUP_VENDOR')
			SELECT TB.*
			INTO #TB_INV_LOOKUP_VENDOR
			FROM (
				SELECT
					 [ManufactureID]       = VND.[ManufactureID]
					,[OrigFabricVendorName] = VND.[OrigFabricVendorName]
					,[R_Num]               = ROW_NUMBER() OVER (PARTITION BY VND.[ManufactureID] ORDER BY VND.[ManufactureID])
				FROM        #TB_INV_GROUP_MO                                            AS G
				INNER JOIN  [LCA].[dboReaders].[VW_Planning_DispatchRO_OriginalVendor]  AS VND WITH(NOLOCK)  ON G.[MO_ID] = VND.[ManufactureID]
			) AS TB
			WHERE TB.[R_Num] = 1

			PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA TB_INV_LOOKUP_TAG')
			SELECT TB.*
			INTO #TB_INV_LOOKUP_TAG
			FROM (
				SELECT
					 [ManufactureID] = TAG.[ManufactureID]
					,[DAT]          = TAG.[DAT]
					,[R_Num]        = ROW_NUMBER() OVER (PARTITION BY TAG.[ManufactureID] ORDER BY TAG.[ManufactureID])
				FROM        #TB_INV_GROUP_MO                                                    AS G
				INNER JOIN  [LCA].[dboReaders].[VW_Planning_DispatchRO_RawMaterialHangtagYesNo] AS TAG WITH(NOLOCK) ON G.[MO_ID] = TAG.[ManufactureID]
			) AS TB
			WHERE TB.[R_Num] = 1

			PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA TB_INV_LOOKUP_BOM')
			SELECT TB.*
			INTO #TB_INV_LOOKUP_BOM
			FROM (
				SELECT
					 [StyleID]     = BOM.[StyleID]
					,[PartNumber]  = BOM.[PartNumber]
					,[R_Num]       = ROW_NUMBER() OVER (PARTITION BY BOM.[StyleID] ORDER BY BOM.[StyleID])
				FROM        #TB_INV_GROUP_STYLE                                             AS G
				INNER JOIN  [LCA].[dboReaders].[VW_Planning_DispatchRO_BOMRequireHangtag]   AS BOM WITH(NOLOCK) ON G.[StyleID] = BOM.[StyleID]
			) AS TB
			WHERE TB.[R_Num] = 1


			PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. UPDATE DE LOOKUPS')
			UPDATE S SET
				 [OrigFabricVendorName]     = ISNULL(B.[OrigFabricVendorName], '')
			FROM       #TB_INV_WAREHOUSE_BASE   AS S
			INNER JOIN #TB_INV_LOOKUP_VENDOR    AS B ON B.[ManufactureID] = S.[ManufactureID]

			UPDATE S SET
				 [RequireHangtag]           = ISNULL(B.[DAT], 1)
			FROM        #TB_INV_WAREHOUSE_BASE  AS S
			INNER JOIN  #TB_INV_LOOKUP_TAG      AS B ON B.[ManufactureID] = S.[ManufactureID]

			UPDATE S SET
				 [PNHangtag]                = ISNULL(B.[PartNumber], 'NO Hangtag Assigned')
			FROM        #TB_INV_WAREHOUSE_BASE  AS S
			INNER JOIN  #TB_INV_LOOKUP_BOM      AS B ON B.[StyleID] = S.[StyleID]

			PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA FINAL TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE')
			SELECT
				 [StyleID]				= B.[StyleID]
				,[Style]				= B.[Style]
				,[Season]				= B.[Season]
				,[Color]				= B.[Color]
				,[BoxStat]				= 'RO_Packed'
				,[BoxNumber]			= B.[BoxNumber]
				,[BIN]					= B.[BIN]
				,[PackDate]				= B.[PackDate]
				,[Size]					= B.[Size]
				,[QTY]					= SUM(B.[Quantity])
				,[StockCategory]		= B.[StockCategory]
				,[MO_ID]				= B.[ManufactureID]
				,[MO]					= B.[MO]
				,[OrderID]				= B.[OrderID]
				,[PONumber]				= B.[PONumber]
				,[OrigFabricVendorName]	= B.[OrigFabricVendorName]
				,[RequireHangtag]		= B.[RequireHangtag]
				,[PNHangtag]			= B.[PNHangtag]
				,[TariffCategory]		= B.[TariffCategory]
				,[CSVBoxNumber]			= B.[CSVBoxNumber]
				,[PPFG]					= B.[PPFG]
				,[TypeQuery]			= 1
				,[OrderWIP]				= 0
				,[OPTION]				= B.[OPTION]
				,[ProductDivison]       = B.[ProductDivison]
			INTO #TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE
			FROM #TB_INV_WAREHOUSE_BASE AS B
			GROUP BY
				 B.[StyleID]
				,B.[Style]
				,B.[Season]
				,B.[Color]
				,B.[BoxNumber]
				,B.[BIN]
				,B.[PackDate]
				,B.[Size]
				,B.[StockCategory]
				,B.[ManufactureID]
				,B.[MO]
				,B.[OrderID]
				,B.[PONumber]
				,B.[OrigFabricVendorName]
				,B.[RequireHangtag]
				,B.[PNHangtag]
				,B.[TariffCategory]
				,B.[CSVBoxNumber]
				,B.[PPFG]
				,B.[OPTION]
				,B.[ProductDivison]

			
            -----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE)
    			DROP TABLE IF EXISTS #TB_INV_GROUP_MO                   ---Tabla auxiliar de MOs del inventario activo
    			DROP TABLE IF EXISTS #TB_INV_GROUP_STYLE                ---Tabla auxiliar de estilos del inventario activo
    			DROP TABLE IF EXISTS #TB_INV_LOOKUP_VENDOR              ---Tabla lookup de vendor original por ManufactureID
    			DROP TABLE IF EXISTS #TB_INV_LOOKUP_TAG                 ---Tabla lookup de bandera RequireHangtag por ManufactureID
    			DROP TABLE IF EXISTS #TB_INV_LOOKUP_BOM                 ---Tabla lookup de partnumber de hangtag por StyleID
    			DROP TABLE IF EXISTS #TB_INV_WAREHOUSE_BASE             ---Tabla base de inventario activo por PackedItem
            -----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE)

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE')
            -- SELECT * FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA INVENTARIO ACTIVO-----------------------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA INVENTARIO EN MOS EN WIP---------------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO PROCEDIMIENTO PARA INVENTARIO EN MOS EN WIP')
			
			PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO EN MOS EN WIP. TABLA ROS/MOS EN RELEASED, FORECAST, CORTE TELA')
                DROP TABLE IF EXISTS #TB_DATA_MOS_INVENTORY_RFCB
                DROP TABLE IF EXISTS #TB_Data_MOS_WIP_RELEASED_FORECAST_CUTTING
                
                SELECT 
        			 [ManufactureID]    = MO.ManufactureID 
        			,[StatusID]         = SN.StatusID
        			,[StatusName]       = SN.StatusName 
        		INTO #TB_Data_MOS_WIP_RELEASED_FORECAST_CUTTING
        		FROM (SELECT StatusID,StatusName FROM [LCA].[dbo].StatusNames WITH(NOLOCK) WHERE [StatusID] IN(20,40,51,53) ) AS SN ---20 Forecast, 40 Released, 51 Cutting, 53 Preproduction
        		INNER JOIN [LCA].[dbo].ManufactureOrders AS MO WITH(NOLOCK) ON MO.StatusID 				= SN.StatusID				AND MO.[StatusID] IN(20,40,51,53)	    ---20 Forecast, 40 Released, 51 Cutting, 53 Preproduction	 
                WHERE       (SN.[StatusID] IN(20,40) )
                        OR
        					(SN.[StatusID] IN(51,53) AND mo.BundleCreateDate IS NULL  )
                    
                SELECT  
					 [MO_ID]                        = MO.[ManufactureID]
                    ,[MO]                           = MO.[ManufactureNumber]
                    ,[PONumber]                     = ISNULL(ord.[PONumber], ord2.[PONumber])
                    ,[Style]                        = st.[StyleNumber]
                    ,[Color]                        = stc.[StyleColorName]
                    ,[ColorDescription]             = stc.[StyleColorDescription]
                    ,[Size]                         = fg.[GarmentSize]
                    ,[Season]                       = seas.[SeasonName]
                    ,[TypeSize]                     = CASE
															WHEN fg.[GarmentSize] IN ('XS','2T')       THEN 'A'
															WHEN fg.[GarmentSize] IN ('S','3T')        THEN 'B'
															WHEN fg.[GarmentSize] IN ('M','4T')        THEN 'C'
															WHEN fg.[GarmentSize] IN ('L','5T')        THEN 'D'
															WHEN fg.[GarmentSize] IN ('XL','6T')       THEN 'E'
															WHEN fg.[GarmentSize] IN ('2XL','7T')      THEN 'F'
															WHEN fg.[GarmentSize] IN ('3XL','8T')      THEN 'G'
															WHEN fg.[GarmentSize] = '4XL'              THEN 'H'
															WHEN fg.[GarmentSize] = '5XL'              THEN 'I'
															WHEN fg.[GarmentSize] IN ('QTY','ADJ')     THEN 'ADJ'
															WHEN fg.[GarmentSize] = 'S/M'              THEN 'U'
															WHEN fg.[GarmentSize] = 'L/XL'             THEN 'U'
															WHEN fg.[GarmentSize] = 'S_M'              THEN 'U'
															WHEN fg.[GarmentSize] = 'L_XL'             THEN 'U'
														END
                    ,[MAKE1]                        = SUM(md.[QuantityOrdered])
                    ,[OriginalMake]                 = md.[QuantityOrdered]
                    ,[Status]                       = SN.[StatusName]
                    ,[OrderID]                      = ISNULL(ord.[OrderID], ord2.[OrderID])
                    ,[Bucket]                       = REPLACE(MO.[Comments3], 'BU ', '')
                    ,[Availability]                 = mo.[PlanTransferCost]
                    ,[SewingDate]                   = CAST(mo.[SchedFinish] AS DATE)
                    ,[FabricDD]                     = CASE 
                                                        WHEN TRY_PARSE(mo.[Comments8] AS DATE) IS NOT NULL 
                                                        THEN CAST(mo.[Comments8] AS DATE) 
                                                        ELSE NULL 
                                                      END
                    ,[RequiredDate]                 = ISNULL(OI.[requiredDate], ISNULL(ord.[RequiredDate], ord2.[RequiredDate]))
                    ,[POLineItem]                   = md.[ManufactureDetailID]
                    ,[StyleID]                      = st.[StyleID]
                    ,[SupplierCode]                 = CASE 
                                                        WHEN Addre.[CompanyName] = 'League Internal Order'
                                                             OR Addre.[CompanyName] IS NULL
                                                             OR Addre.[CompanyName] = ''
                                                        THEN 'LCA'
                                                        ELSE Addre.[CompanyName]
                                                      END
                    ,[PurchaseUnitCost]             = ISNULL(OI.[PricingUnitCost2], 0)
                    ,[TariffCategory]               = MO.[Comments16]
                INTO #TB_DATA_MOS_INVENTORY_RFCB
				FROM (SELECT StatusID,StatusName FROM [LCA].[dbo].StatusNames WITH(NOLOCK) WHERE [StatusID] IN(20,40,51,53) ) AS SN ---20 Forecast, 40 Released, 51 Cutting, 53 Preproduction
				INNER JOIN  [LCA].[dbo].ManufactureOrders               AS MO    WITH(NOLOCK) ON SN.StatusID            = MO.StatusID            AND MO.[StatusID] IN(20,40,51,53) ---20 Forecast, 40 Released, 51 Cutting, 53 Preproduction
				INNER JOIN  #TB_Data_MOS_WIP_RELEASED_FORECAST_CUTTING  AS WIP                ON WIP.ManufactureID      = MO.ManufactureID   
				INNER JOIN  [LCA].[dbo].ManufactureDetails              AS md    WITH(NOLOCK) ON md.ManufactureID       = mo.ManufactureID       AND md.QuantityOrdered > 0
				INNER JOIN  [LCA].[dbo].FinishedGoods                   AS fg    WITH(NOLOCK) ON fg.FinishedGoodsID     = md.FinishedGoodsID
				INNER JOIN  [LCA].[dbo].StyleColors                     AS stc   WITH(NOLOCK) ON stc.StyleColorID       = fg.StyleColorID
				INNER JOIN  [LCA].[dbo].Styles                          AS st    WITH(NOLOCK) ON st.StyleID             = fg.StyleID
				INNER JOIN  [LCA].[dbo].Seasons                         AS seas  WITH(NOLOCK) ON seas.SeasonID          = st.SeasonID            AND (seas.SeasonName = 'BLANK RO' OR seas.SeasonName ='BLANK FG'  )
				LEFT JOIN   [LCA].[dbo].Orders                          AS ord   WITH(NOLOCK) ON ord.OrderID            = MO.OrderID
				LEFT JOIN   [LCA].[dbo].Addresses                       AS Addre WITH(NOLOCK) ON mo.ContractorID        = Addre.AddressID
				LEFT JOIN   [LCA].[dbo].OrderItems                      AS OI    WITH(NOLOCK) ON OI.OrderItemID         = mo.FirstOrderItemID
				LEFT JOIN   [LCA].[dbo].Orders                          AS ord2  WITH(NOLOCK) ON ord2.OrderID           = oi.OrderID
				GROUP BY  
					ISNULL(ord.OrderID ,ord2.OrderID)
					,ISNULL(ord.PONumber    ,ord2.PONumber)
					-- ,Ord.PONumber 
					,MO.ManufactureID
					,MO.ManufactureNumber
					,sn.StatusName 
					,st.StyleID
					,st.StyleNumber 
					,stc.StyleColorName
					,stc.StyleColorDescription
					,fg.GarmentSize    
					,seas.SeasonName
                    ,md.[QuantityOrdered]
					,Replace(MO.Comments3,'BU ','') 
					,mo.PlanTransferCost
					,mo.SchedFinish     
					,mo.Comments8   
					,ISNULL( OI.requiredDate,isnull(ord.[RequiredDate],ord2.[RequiredDate]) )
					,md.ManufactureDetailID
					,CASE WHEN Addre.CompanyName='League Internal Order' OR Addre.CompanyName IS NULL OR Addre.CompanyName='' THEN 'LCA' ELSE Addre.CompanyName END
					,isnull(OI.PricingUnitCost2,0)
					,MO.Comments16 --TARIFF CATEGORY
        
        
                DROP TABLE IF EXISTS #TB_Data_MOS_WIP_RELEASED_FORECAST_CUTTING
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    PROCEDIMIENTO PARA INVENTARIO EN MOS EN WIP')
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA INVENTARIO EN MOS EN WIP---------------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP--------------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----Explicacion del procedimiento para inventario en bultos wip
            -------------------         Que hace el bloque
            ------------------- Construye tabla temporal de bultos por MO activa (StatusID < 90).
            ------------------- Carga inventario de bultos con datos de MO, FG, Style, Order y workflow.
            ------------------- Calcula NextTask y mapea PhysicalLocation/AccountingLocation segun workflow.
            ------------------- Ajusta reglas especiales para MO Released con dispatch y bultos ya en caja.
            ------------------- Inserta el resultado activo al formato RFC en #TB_DATA_MOS_INVENTORY_RFCB.
            -------------------     Filtros utilizados
            -------------------         TypeQueryN = 1 (BundlesLoc)
            -------------------         Quantity > 0
            -------------------         Excluye PhysicalLocation en NO WIP (Complete/Released)

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP')

        
        
              DROP TABLE IF EXISTS #TB_ALL_Data
              DROP TABLE IF EXISTS #TB_Data_For_Bundles
               SELECT BundleID 
               INTO #TB_Data_For_Bundles
               FROM(
                            SELECT 
                                MO.ManufactureID
                                ,BND.BundleID
                            FROM		(SELECT StatusID FROM [LCA].[dbo].StatusNames WITH(NOLOCK) WHERE StatusID < 90) AS FSN
                            INNER JOIN [LCA].[dbo].ManufactureOrders	AS MO 	WITH(NOLOCK)	ON MO.StatusID       = FSN.StatusID AND MO.StatusID < 90
                            INNER JOIN  [LCA].[dbo].Bundles				AS BND	WITH(NOLOCK)	ON MO.ManufactureID	 = BND.ManufactureID
                            
                        )	AS fil
               
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP. TYPEQUERY 1')
        			
        		-- INSERT INTO #TB_ALL_Data
                SELECT	
                     [TypeQuery]            = 'BundlesLoc'      
                    ,[TypeQueryN]           = 1
                    ,[R] 				    = ROW_NUMBER() OVER(ORDER BY MO.ManufactureID,BND.BundleID)
                    ,[Area]		            = CAST(NULL AS VARCHAR(100))
        			,[Location]             = CAST(NULL AS VARCHAR(100))
        			,[LocationCost]         = CAST(NULL AS VARCHAR(100))
                    ,[WarehouseID]		    = NULL
                    ,[warehousename]	    = NULL
                    ,[BoxID]			    = pb.PackedBoxID
                    ,[BoxCode]				= 'PPBX'+LTRIM(STR(pb.PackedBoxID+10000000))
                    ,[BoxNumber]			= pb.BoxNumber		
                    ,[FormatterBoxNumber]   = NULL
                    ,[BoxComments]		    = NULL
                    ,[BoxComments5]		    = NULL
                    ,[StatusID]			    = NULL    
                    ,[BoxStatus]		    = NULL
                    ,[PackedItemID]		    = NULL
                    ,[BundleID]				= BND.BundleID
                    ,[BundleNumber]			= BND.BundleNumber 
                    ,[BundleBarcode]		= 'PPBU' + LTRIM(STR(BND.BundleID + 10000000))     
                    ,[ManufactureID]		= BND.ManufactureID
                    ,[MO]					= MO.ManufactureNumber			
                    ,[MOStatusID]			= SN.StatusID
                    ,[MOStatus]				= sn.StatusName   
                    ,[ProductionStatus]		= PST.DropDownValue   
                    ,[PWModulo]				= MO.Comments7       
                    ,[StyleID]				= ST.StyleID
                    ,[Style]				= ST.StyleNumber
                    ,[SeasonID]				= SNsS.SeasonID
                    ,[Season]				= SNSs.SeasonName	
                    ,[ColorID]				= stc.StyleColorID
                    ,[Color]				= STC.StyleColorName	
        			,[OptionMO]             = MO.Comments17
        			,[OptionID]             = CAST(NULL AS INT)		
                    ,[FinishedGoodsID]		= FG.FinishedGoodsID
                    ,[Size]					= FG.GarmentSize
                    ,[Quantity]				= BND.QuantityOrdered - BND.QuantityThirds
                    ,[OrderID]				= od.OrderID
                    ,[PONumber]				= od.PONumber
                    ,[PrintCount]			= COALESCE(TRY_CAST(od.Comments14 AS NUMERIC(18,2)),0.00)
                    ,[CodeEmbroidery]		= od.Comments26 	
                    ,[ProductDivision]		= ST.Comments9
        			,[StyleDivision]		= CAST(NULL AS VARCHAR(50))   
                    ,[GoodsBinID]			= NULL
                    ,[Bin]					= NULL
        			,[PalletID]				= NULL
        			,[Pallet]				= NULL
                    ,[BoxTypeID]			= NULL
                    ,[OrderDetailsID]		= NULL	
                    ,[PackerID]			    = NULL
                    ,[PackerUser]		    = NULL
                    ,[PackerName]		    = NULL
                    ,[SewLocation]			= Ad7.CompanyNumber
                    ,[MachineNumber]        = OD.Comments28
                    ,[operator]				= Ad5.CompanyName
                    ,[OperatoNumber]		= Ad5.CompanyNumber
                    ,[LastTaskID]			= WTS.TaskID
                    ,[LastTask]				= WTS.TaskName
                    ,[NextTaskID]			= CAST(NULL AS INT)
                    ,[NextTaskName]			= CAST(NULL AS VARCHAR(200))
                    ,[PhysicalLocation]		= CAST(NULL AS VARCHAR(200))
                    ,[AccountingLocation]	= CAST(NULL AS VARCHAR(200))
                    ,[LastDateBundle]		= Chl.ChangeDate
                    ,[SewLocation2]			= adrsc.CompanyNumber
                    ,[SewLocation3]			= adren.CompanyNumber     
                    ,[WorkFlowID]			= WTS.WorkFlowID
                    ,[WorkFlow]				= (	SELECT TOP 1 WF.WorkFlowName
                                                        FROM WorkFlows WF		WITH (NOLOCK)
                                                        WHERE 	WF.ManufactureID
                                                            = MO.ManufactureID
                                                                AND StatusID < 90
                                                        ORDER BY  WF.WorkFlowID
                                                )
                    ,[SewLocation4]			= MO.Comments13
                    ,[SewLocation5]			= MO.Comments14
                    ,[SewLocationBINSP]		= MO.Comments25  	
                    
        			,[PPRCCategory]			= NULL
        			,[PPRCSubcategory]		= NULL
        			,[PartNumber]			= NULL
        			,[PPRCColor]			= NULL
        			,[DyeLot]				= NULL
        			,[RollNumber]			= NULL
        			,[RawContainerID]		= NULL
        			,[PPRC]					= NULL
        			,[PPRCCost]				= NULL
        			
        			,[Consigned]			= CAST(NULL AS VARCHAR(5))
                    ,[PurchaseOrder]		= CAST(NULL AS VARCHAR(200))
                    ,[Vendor]				= CAST(NULL AS VARCHAR(200))
                    ,[ManufactureCostID]	= CAST(NULL AS INT)
                    ,[MOCost]				= CAST(NULL AS VARCHAR(200))
                    ,[Conf_LCA_Contract]	= CAST(NULL AS VARCHAR(MAX))
        			-- ,[LocationFinal]		= CAST(NULL AS VARCHAR(100))
                    -- ,PRM.*
        			-- SELECT * FROM #TB_BND
            --    INTO #TB_BND 
            INTO #TB_ALL_Data
        	   FROM 	        #TB_Data_For_Bundles    AS fil
                    INNER JOIN  [LCA].[dbo].Bundles				AS BND		WITH(NOLOCK)	ON fil.BundleID		        = BND.BundleID
                    INNER JOIN  [LCA].[dbo].ManufactureOrders	AS MO 		WITH(NOLOCK)	ON BND.ManufactureID 		= MO.ManufactureID		    AND  MO.StatusID < 90
                    LEFT JOIN   [LCA].[dbo].PackedBoxes 		AS pb		WITH(NOLOCK) 	ON pb.PackedBoxID 			= BND.PackedBoxID	
                    INNER JOIN  [LCA].[dbo].ManufactureDetails	AS MD		WITH(NOLOCK)	ON BND.ManufactureDetailID 	= MD.ManufactureDetailID
                    INNER JOIN  [LCA].[dbo].FinishedGoods		AS FG		WITH(NOLOCK)	ON MD.FinishedGoodsID 		= FG.FinishedGoodsID 
                    INNER JOIN  [LCA].[dbo].Styles				AS ST		WITH(NOLOCK) 	ON FG.StyleID 				= ST.StyleID
                    INNER JOIN  [LCA].[dbo].StyleColors			AS STC		WITH(NOLOCK) 	ON FG.StyleColorID 			= STC.StyleColorID
                    INNER JOIN  [LCA].[dbo].OrderItems 			AS oi		WITH(NOLOCK) 	ON oi.OrderItemID 			= MO.FirstOrderItemID
                    INNER JOIN  [LCA].[dbo].Orders 				AS od		WITH(NOLOCK) 	ON od.orderid 				= oi.OrderID
                    LEFT JOIN   [LCA].[dbo].WorkTransactions	AS WT		WITH(NOLOCK)	ON BND.LastTransactionID 	= WT.WorkTransactionID
                    LEFT JOIN   [LCA].[dbo].WorkTasks			AS WTS		WITH(NOLOCK) 	ON WT.TaskID 				= WTS.TaskID
                    LEFT JOIN   [LCA].[dbo].ChangeLog			AS Chl		WITH(NOLOCK) 	ON WT.ChangeLogID 			= Chl.ChangeLogID
                    LEFT JOIN   [LCA].[dbo].StatusNames 		AS sn		WITH(NOLOCK) 	ON sn.StatusID 				= MO.StatusID
                    INNER JOIN  [LCA].[dbo].Seasons 			AS SNSS		WITH(NOLOCK) 	ON SNSS.SeasonID 			= ST.SeasonID                 AND (SNSS.SeasonName = 'BLANK RO' OR SNSS.SeasonName ='BLANK FG'  ) 
                    -- LEFT JOIN   [LCA].[dbo].Seasons 			AS SNSS		WITH(NOLOCK) 	ON SNSS.SeasonID 			= ST.SeasonID
                    LEFT JOIN 	[LCA].[dbo].DropDownValues3 	AS PST	    WITH(NOLOCK)    ON MO.ProductionStatusID 	= PST.DropDownValueID
                    LEFT JOIN   [LCA].[dbo].Addresses 			AS Ad5 		WITH(NOLOCK) 	ON WT.OperatorID 			= Ad5.AddressID 
                    LEFT JOIN   [LCA].[dbo].Addresses 			AS Ad7 		WITH(NOLOCK) 	ON Ad7.AddressID 			= MO.SewLocationID
                    LEFT JOIN   [LCA].[dbo].Addresses 			AS adrsc	WITH(NOLOCK) 	ON adrsc.AddressID 			= MO.ScreenPrintLocationID
                    LEFT JOIN   [LCA].[dbo].Addresses 			AS adren	WITH(NOLOCK) 	ON adren.AddressID 			= MO.EmbroideryLocationID
                    LEFT JOIN   [LCA].[dbo].Users				AS us       WITH(NOLOCK)	ON us.UserID				= Chl.UserID
                    LEFT JOIN (
                            SELECT bundleBarcode
        					FROM OPENQUERY([MARIADB],'SELECT * FROM wordpress.Warehouse_BoxReceiving where Year(InsertDate) >= 2024 ')  AS TBM
        					-- FROM OPENQUERY([MARIADB],'SELECT * FROM wordpress.Warehouse_BoxReceiving where Year(InsertDate) >= 2024 AND DATE(InsertDate) < STR_TO_DATE(''2026-01-01'', ''%Y-%m-%d'') ')  as TBM
                            GROUP BY  
                            bundleBarcode
                    ) AS COWRO ON COWRO.bundleBarcode = 'PPBU' + LTRIM(STR(BND.BundleID + 10000000))
                    -- CROSS APPLY #TB_Parameters				AS PRM	
                ----se comentarea porque se hace una validacion en el if del dato.
                -- WHERE	 pb.BoxNumber IS NULL
                -- AND COWRO.bundleBarcode IS  NULL
        
		    PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP. UPDATE NEXTTASK')
        
        		UPDATE TB
                		SET NextTaskID = COALESCE(TBW1.[NextTaskID],TBW2.[TaskID])
                		FROM #TB_ALL_Data AS TB
                		LEFT JOIN (
                					SELECT * FROM(
                							SELECT 
                	
                								  [BundleID]			= BND.BundleID
                								 ,[R]					= ROW_NUMBER() OVER(PARTITION BY BND.BundleID ORDER BY BND.BundleID,WT2.[Sequence] ASC)
                								 --,[BundleBarcode]		= 'PPBU' + LTRIM(STR(BND.BundleID + 10000000))
                								 ,[LastTaskID]			= WTS.TaskID
                								 ,[LastTask]			= WTS.TaskName
                								 --,[LastSequence]		= WTS.[Sequence]
                								 --,[ActualNodeNumber]	= WTS.NodeNumber
                								 --,[NextNodeNumber]		= WTS.NextNodeNumber
                
                								 ,[NextTaskID]			= COALESCE(WT2.TaskID,0)
                								 ,[NextTask]			= COALESCE(WT2.TaskName,'Complete')
                								 --,[NextSequence]		= WT2.[Sequence] 
                								 --,[NLastNodeNumber]		= WT2.NodeNumber
                								 --,[NNextNodeNumber]		= WT2.NextNodeNumber
                								 --,MO.ManufactureNumber
                							--	 ,a = bnd.LastTransactionID
                							--	 ,b = bntr.LastTransactionWithOutDamage
                							--	 ,c = COALESCE(BNTR.LastTransactionWithOutDamage,BND.LastTransactionID )
                							FROM 	   #TB_Data_For_Bundles	    AS fil
                							INNER JOIN [LCA].[dbo].Bundles				AS BND	WITH(NOLOCK) ON fil.BundleID		    = BND.BundleID
                							INNER JOIN [LCA].[dbo].ManufactureOrders	AS MO 	WITH(NOLOCK) ON BND.ManufactureID 		= MO.ManufactureID		AND  MO.StatusID < 90		
                							LEFT JOIN (
                							         
                										SELECT * FROM (
                										              SELECT
                                                                                [BundleID]
                                                                                --,[R]                            = ROW_NUMBER() OVER(PARTITION BY EA.BundleID ORDER BY EA.ChangeDate DESC,EA.)
                                                                                ,[R]                            = ROW_NUMBER() OVER(PARTITION BY EA.BundleID ORDER BY EA.ChangeDate DESC,[MaxChangeDateID] desc)
        
                                                                                ,[LastTransactionWithOutDamage]
                                                                            FROM(
                											                         SELECT
                                                                                                    [BundleID]                      = BND.BundleID
                                                                                                    -- ,[R]                         = ROW_NUMBER() OVER(PARTITION BY BND.BundleID ORDER BY ch.ChangeDate DESC)
                                                                                                    --,[BundleBarcode]              = 'PPBU' + LTRIM(STR(BND.BundleID + 10000000))
                                                                                                    ,[LastTransactionWithOutDamage] = MAX(WT.WorkTransactionID)
                                                                                                    ,[Quantity]                     = SUM(wt.Quantity)
                                                                                                    ,[ChangeDate]                   = MAX(ch.ChangeDate)
                                                                                                    ,[TaskID]                       = WT.TaskID  
        																							,[MaxChangeDateID]				= MAX(ch.ChangeLogID)
                                                                                                FROM        #TB_Data_For_Bundles    AS fil
                                                                                                INNER JOIN  [LCA].[dbo].Bundles             AS BND  WITH(NOLOCK) ON fil.BundleID            = BND.BundleID
                                                                                                INNER JOIN  [LCA].[dbo].ManufactureOrders   AS MO   WITH(NOLOCK) ON BND.ManufactureID       = MO.ManufactureID  AND  MO.StatusID < 90      
                                                                                                INNER JOIN  [LCA].[dbo].WorkTransactions    AS WT   WITH(NOLOCK) ON BND.BundleID            = WT.BundleID       AND WT.DamageID IS NULL AND WT.Quantity<>0
                                                                                                INNER join  [LCA].[dbo].ChangeLog           AS ch   WITH(NOLOCK) ON ch.ChangeLogID          = wt.ChangeLogID
                                                                                       GROUP BY BND.BundleID, WT.TaskID
                                                                                       HAVING SUM(wt.Quantity) >0
                                                                             ) AS EA
                											) AS TB
                											WHERE TB.R = 1
                											) AS BNTR on BNTR.BundleID = BND.BundleID
                							INNER JOIN  [LCA].[dbo].WorkTransactions		AS WT	WITH(NOLOCK) ON COALESCE(BNTR.LastTransactionWithOutDamage,BND.LastTransactionID ) = WT.WorkTransactionID --BND.LastTransactionID = WT.WorkTransactionID
                							LEFT JOIN   [LCA].[dbo].WorkTasks				AS WTS	WITH(NOLOCK) ON WT.TaskID 				= WTS.TaskID
                							LEFT JOIN   [LCA].[dbo].WorkTasks			    AS WT2	WITH(NOLOCK) ON WT2.WorkFlowID			= WTS.WorkFlowID		AND WTS.NextNodeNumber = WT2.NodeNumber  
                							) AS TB
                							WHERE TB.R = 1
                					) AS TBW1 ON TBW1.BundleID = TB.BundleID
                    		LEFT JOIN (
                    					SELECT * FROM(
                    						SELECT 
                    							 [ManufactureID]		= MO.ManufactureID
                    							,[TaskID]				= WT.TaskID
                    							--,[Sequence]				= WT.[Sequence]
                    							,[R]					= ROW_NUMBER() OVER(PARTITION BY MO.ManufactureID ORDER BY WT.[Sequence] ASC)
                    						FROM (	SELECT 
                    											MO.ManufactureID
                    										FROM		[LCA].[dbo].ManufactureOrders	AS MO 	WITH(NOLOCK)	
                    										WHERE MO.StatusID < 90
                    									)	AS fil
                    						INNER JOIN [LCA].[dbo].ManufactureOrders	AS MO WITH(NOLOCK) ON Fil.ManufactureID = MO.ManufactureID
                    						INNER JOIN [LCA].[dbo].WorkFlows			AS WF WITH(NOLOCK) ON WF.ManufactureID = Fil.ManufactureID AND MO.StatusID < 90
                    						INNER JOIN [LCA].[dbo].WorkTasks			AS WT WITH(NOLOCK) ON WT.WorkFlowID = WF.WorkFlowID AND WT.AutoComplete = 0 AND (WT.UseBundles <> 0 OR WT.StatusID <=45)
                    					) AS TB
                    					WHERE TB.R = 1 
                    					) AS TBW2 ON TBW2.ManufactureID = TB.ManufactureID
                            WHERE TB.[TypeQueryN] = 1
        
        
		    PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP. UPDATE NextTaskName')
        
        		UPDATE S SET 
        			 [NextTaskName]			= IIF(S.MOStatus = 'Released','NO WIP (Released)', IIF(S.NextTaskID = 0,'Complete'			,COALESCE(WNT.TaskName,'NO NEXT TASK')))
        			,[PhysicalLocation]		= IIF(S.MOStatus = 'Released','NO WIP (Released)', IIF(S.NextTaskID = 0, 'NO WIP (Complete)'	,COALESCE(DRP.DropDownValue,ODRP.DropDownValue,'NO LOCATION')))
        			,[AccountingLocation]	= IIF(S.MOStatus = 'Released','NO WIP (Released)', IIF(S.NextTaskID = 0, 'NO WIP (Complete)'	,COALESCE(DRC.DropDownValue,DRCP.DropDownValue,'NO LOCATION')))
        			,[LocationCost]	        = IIF(S.MOStatus = 'Released','NO WIP (Released)', IIF(S.NextTaskID = 0, 'NO WIP (Complete)'	,COALESCE(DRC.DropDownValue,DRCP.DropDownValue,'NO LOCATION')))
        			,[Area]		            = IIF(S.MOStatus = 'Released','NO WIP (Released)', IIF(S.NextTaskID = 0, 'NO WIP (Complete)'	,COALESCE(DRP.DropDownValue,ODRP.DropDownValue,'NO LOCATION')))
        		FROM	  #TB_ALL_Data				AS S
        		LEFT JOIN [LCA].[dbo].WorkTasks			AS WNT	WITH(NOLOCK) ON WNT.TaskID				= S.NextTaskID
        		LEFT JOIN [LCA].[dbo].DropDownValues4	AS DRP	WITH(NOLOCK) ON DRP.DropDownValueID		= WNT.DelayReasonCodeID
        		LEFT JOIN [LCA].[dbo].DropDownValues3	AS DRC	WITH(NOLOCK) ON DRC.DropDownValueID		= WNT.TaskCategoryID
        		LEFT JOIN [LCA].[dbo].WorkFlows			AS WF	WITH(NOLOCK) ON WF.WorkFlowID			= WNT.WorkFlowID
        		LEFT JOIN [LCA].[dbo].WorkTasks			AS OWT	WITH(NOLOCK) ON OWT.TaskID				= WNT.TemplateID
        		LEFT JOIN [LCA].[dbo].DropDownValues4	AS ODRP	WITH(NOLOCK) ON ODRP.DropDownValueID	= OWT.DelayReasonCodeID
        		LEFT JOIN [LCA].[dbo].DropDownValues3	AS DRCP	WITH(NOLOCK) ON DRCP.DropDownValueID	= OWT.TaskCategoryID
        
		    PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP. UPDATE MO RELEASED')
        		
        		UPDATE S SET
                             [NextTaskName]		      = 'MO RELEASED WITH DISPATCH'      
                            ,[PhysicalLocation]	      = 'MO RELEASED WITH DISPATCH'  
                            ,[AccountingLocation]     = 'MO RELEASED WITH DISPATCH' 
                            ,[LocationCost]	          = 'WH RO' 
                            -- ,[CommentsReview]         = 'TOMAR INVENTARIO. Despacho realizado pero en released.'
                FROM	  #TB_ALL_Data				AS S
                INNER JOIN (
                        SELECT 
                            [ManufactureID]    = MO.ManufactureID
                            ,[MO]               = MO.ManufactureNumber
                            ,[Dispatch]         = SUM(COALESCE(MB.QuantityWithdrawn,0))
                        FROM       (SELECT StatusID FROM [LCA].[dbo].StatusNames WITH(NOLOCK) WHERE StatusID < 90) AS FSN
                            INNER JOIN  [LCA].[dbo].ManufactureOrders	AS MO WITH(NOLOCK) ON MO.StatusID       = FSN.StatusID AND MO.StatusID < 90
                            LEFT JOIN   [LCA].[dbo].ManufactureBlanks   AS MB WITH(NOLOCK) ON MB.ManufactureID  = MO.ManufactureID
                        GROUP BY
                            MO.ManufactureID
                            ,MO.ManufactureNumber
                        HAVING SUM(COALESCE(MB.QuantityWithdrawn,0)) >0
                ) AS MBD ON MBD.ManufactureID = S.ManufactureID
                WHERE S.[MOStatus] = 'Released' AND S.[TypeQueryN] = 1
        		
        		
        		
        		
		    PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP. UPDATE MO COMPLETE')
        
                UPDATE S SET 
        			 [NextTaskName]			= 'Complete'
        			,[PhysicalLocation]		= 'NO WIP (Complete)'
        			,[AccountingLocation]	= 'NO WIP (Complete)'
        			,[LocationCost]	        = 'NO WIP (Complete)'
        			,[Area]	                = 'NO WIP (Complete)'       --EO5382567-TUGM
        			-- ,[CommentsReview]       = IIF(LEFT(S.[BoxNumber],4)='PPBU','Bultos ingresados en DLI','Bultos ingreados en empaque')
        		FROM	  #TB_ALL_Data				AS S
        		WHERE S.[BoxNumber] IS NOT NULL AND S.[TypeQueryN] = 1
        		
		PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO EN MOS EN WIP. INSERT BULTOS ACTIVOS A TB_DATA_MOS_INVENTORY_RFCB')

		INSERT INTO #TB_DATA_MOS_INVENTORY_RFCB
		(
        			 [MO_ID]
        			,[MO]
        			,[PONumber]
        			,[Style]
        			,[Color]
        			,[ColorDescription]
        			,[Size]
        			,[Season]
        			,[TypeSize]
        			,[MAKE1]
        			,[OriginalMake]
        			,[Status]
        			,[OrderID]
        			,[Bucket]
        			,[Availability]
        			,[SewingDate]
        			,[FabricDD]
        			,[RequiredDate]
        			,[POLineItem]
        			,[StyleID]
        			,[SupplierCode]
        			,[PurchaseUnitCost]
        			,[TariffCategory]
        		)
        		SELECT
        			 [MO_ID]                        = S.[ManufactureID]
        			,[MO]                           = S.[MO]
        			,[PONumber]                     = ISNULL(ORD.[PONumber], ORD2.[PONumber])
        			,[Style]                        = S.[Style]
        			,[Color]                        = S.[Color]
        			,[ColorDescription]             = STC.[StyleColorDescription]
        			,[Size]                         = S.[Size]
        			,[Season]                       = S.[Season]
			        ,[TypeSize]                     = CASE
        												WHEN S.[Size] IN ('XS','2T')       THEN 'A'
        												WHEN S.[Size] IN ('S','3T')        THEN 'B'
        												WHEN S.[Size] IN ('M','4T')        THEN 'C'
        												WHEN S.[Size] IN ('L','5T')        THEN 'D'
        												WHEN S.[Size] IN ('XL','6T')       THEN 'E'
        												WHEN S.[Size] IN ('2XL','7T')      THEN 'F'
        												WHEN S.[Size] IN ('3XL','8T')      THEN 'G'
        												WHEN S.[Size] = '4XL'              THEN 'H'
        												WHEN S.[Size] = '5XL'              THEN 'I'
        												WHEN S.[Size] IN ('QTY','ADJ')     THEN 'ADJ'
        												WHEN S.[Size] IN ('S/M','L/XL','S_M','L_XL') THEN 'U'
        											END
        			,[MAKE1]                        = SUM(S.[Quantity])
        			,[OriginalMake]                 = MD.[QuantityOrdered]
        			,[Status]                       = S.[MOStatus]
        			,[OrderID]                      = ISNULL(ORD.[OrderID], ORD2.[OrderID])
        			,[Bucket]                       = REPLACE(MO.[Comments3], 'BU ', '')
        			,[Availability]                 = MO.[PlanTransferCost]
        			,[SewingDate]                   = CAST(MO.[SchedFinish] AS DATE)
        			,[FabricDD]                     = CASE
        												WHEN TRY_PARSE(MO.[Comments8] AS DATE) IS NOT NULL
        												THEN CAST(MO.[Comments8] AS DATE)
        												ELSE NULL
        											END
        			,[RequiredDate]                 = ISNULL(OI.[requiredDate], ISNULL(ORD.[RequiredDate], ORD2.[RequiredDate]))
        			,[POLineItem]                   = MD.[ManufactureDetailID]
        			,[StyleID]                      = S.[StyleID]
        			,[SupplierCode]                 = CASE
        												WHEN ADR.[CompanyName] = 'League Internal Order'
        													OR ADR.[CompanyName] IS NULL
        													OR ADR.[CompanyName] = ''
        												THEN 'LCA'
        												ELSE ADR.[CompanyName]
        											END
        			,[PurchaseUnitCost]             = ISNULL(OI.[PricingUnitCost2], 0)
        			,[TariffCategory]               = MO.[Comments16]
        		FROM #TB_ALL_Data AS S
        		INNER JOIN [LCA].[dbo].[ManufactureOrders]   AS MO   WITH(NOLOCK) ON MO.[ManufactureID]      = S.[ManufactureID]
        		LEFT JOIN  [LCA].[dbo].[StyleColors]         AS STC  WITH(NOLOCK) ON STC.[StyleColorID]       = S.[ColorID]
        		LEFT JOIN  [LCA].[dbo].[Addresses]           AS ADR  WITH(NOLOCK) ON ADR.[AddressID]           = MO.[ContractorID]
        		LEFT JOIN  [LCA].[dbo].[OrderItems]          AS OI   WITH(NOLOCK) ON OI.[OrderItemID]          = MO.[FirstOrderItemID]
        		LEFT JOIN  [LCA].[dbo].[Orders]              AS ORD  WITH(NOLOCK) ON ORD.[OrderID]             = MO.[OrderID]
        		LEFT JOIN  [LCA].[dbo].[Orders]              AS ORD2 WITH(NOLOCK) ON ORD2.[OrderID]            = OI.[OrderID]
        		LEFT JOIN  [LCA].[dbo].[Bundles]             AS BND  WITH(NOLOCK) ON BND.[BundleID]            = S.[BundleID]
        		LEFT JOIN  [LCA].[dbo].[ManufactureDetails]  AS MD   WITH(NOLOCK) ON MD.[ManufactureDetailID]  = BND.[ManufactureDetailID]
        		WHERE S.[TypeQueryN] = 1
        		  AND S.[Quantity] > 0
        		  AND ISNULL(S.[PhysicalLocation], '') NOT IN ('NO WIP (Complete)','NO WIP','NO WIP (Released)')
        		GROUP BY
        			 S.[ManufactureID]
        			,S.[MO]
        			,ISNULL(ORD.[PONumber], ORD2.[PONumber])
        			,S.[Style]
        			,S.[Color]
        			,STC.[StyleColorDescription]
        			,S.[Size]
        			,S.[Season]
        			,S.[MOStatus]
        			,MD.[QuantityOrdered]
        			,ISNULL(ORD.[OrderID], ORD2.[OrderID])
        			,REPLACE(MO.[Comments3], 'BU ', '')
        			,MO.[PlanTransferCost]
        			,CAST(MO.[SchedFinish] AS DATE)
        			,CASE
        				WHEN TRY_PARSE(MO.[Comments8] AS DATE) IS NOT NULL
        				THEN CAST(MO.[Comments8] AS DATE)
        				ELSE NULL
        			END
        			,ISNULL(OI.[requiredDate], ISNULL(ORD.[RequiredDate], ORD2.[RequiredDate]))
        			,MD.[ManufactureDetailID]
        			,S.[StyleID]
        			,CASE
        				WHEN ADR.[CompanyName] = 'League Internal Order'
        					OR ADR.[CompanyName] IS NULL
        					OR ADR.[CompanyName] = ''
        				THEN 'LCA'
        				ELSE ADR.[CompanyName]
        			END
        			,ISNULL(OI.[PricingUnitCost2], 0)
        			,MO.[Comments16]
			,CASE
				WHEN S.[Size] IN ('XS','2T')       THEN 'A'
				WHEN S.[Size] IN ('S','3T')        THEN 'B'
        				WHEN S.[Size] IN ('M','4T')        THEN 'C'
        				WHEN S.[Size] IN ('L','5T')        THEN 'D'
        				WHEN S.[Size] IN ('XL','6T')       THEN 'E'
        				WHEN S.[Size] IN ('2XL','7T')      THEN 'F'
        				WHEN S.[Size] IN ('3XL','8T')      THEN 'G'
        				WHEN S.[Size] = '4XL'              THEN 'H'
        				WHEN S.[Size] = '5XL'              THEN 'I'
				WHEN S.[Size] IN ('QTY','ADJ')     THEN 'ADJ'
				WHEN S.[Size] IN ('S/M','L/XL','S_M','L_XL') THEN 'U'
			END

            -----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #TB_DATA_MOS_INVENTORY_RFCB)
                DROP TABLE IF EXISTS #TB_ALL_Data
                DROP TABLE IF EXISTS #TB_Data_For_Bundles
            -----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #TB_DATA_MOS_INVENTORY_RFCB)

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP')
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP--------------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO----------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----Explicacion del procedimiento para inventario activo mos wip y consolidado
            -------------------         Que hace el bloque
            ------------------- Genera inventario MOS WIP en el mismo layout de #TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE.
            ------------------- Enriquece vendor/hangtag usando los mismos lookups de planning.
            ------------------- Consolida inventario de bodega + inventario MOS WIP en una sola tabla final.

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO')

            DROP TABLE IF EXISTS #TB_INV_WIP_GROUP_MO
            DROP TABLE IF EXISTS #TB_INV_WIP_GROUP_STYLE
            DROP TABLE IF EXISTS #TB_INV_WIP_LOOKUP_VENDOR
            DROP TABLE IF EXISTS #TB_INV_WIP_LOOKUP_TAG
            DROP TABLE IF EXISTS #TB_INV_WIP_LOOKUP_BOM
            DROP TABLE IF EXISTS #TB_FINAL_PROC_INVENTARIO_MOS_WIP
            DROP TABLE IF EXISTS #TB_FINAL_PROC_INVENTARIO_ACTIVO

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. LIMPIEZA TABLAS TEMPORALES')
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_INV_WIP_GROUP_MO')
            SELECT
                 [MO_ID] = S.[MO_ID]
            INTO #TB_INV_WIP_GROUP_MO
            FROM #TB_DATA_MOS_INVENTORY_RFCB AS S
            GROUP BY S.[MO_ID]

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_INV_WIP_GROUP_STYLE')
            SELECT
                 [StyleID] = S.[StyleID]
            INTO #TB_INV_WIP_GROUP_STYLE
            FROM #TB_DATA_MOS_INVENTORY_RFCB AS S
            GROUP BY S.[StyleID]

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_INV_WIP_LOOKUP_VENDOR')
            SELECT
                 [ManufactureID]       = TB.[ManufactureID]
                ,[OrigFabricVendorName] = TB.[OrigFabricVendorName]
            INTO #TB_INV_WIP_LOOKUP_VENDOR
            FROM (
                SELECT
                     VND.[ManufactureID]
                    ,VND.[OrigFabricVendorName]
                    ,[R] = ROW_NUMBER() OVER (PARTITION BY VND.[ManufactureID] ORDER BY VND.[ManufactureID])
                FROM #TB_INV_WIP_GROUP_MO AS G
                INNER JOIN [LCA].[dboReaders].[VW_Planning_DispatchRO_OriginalVendor] AS VND WITH(NOLOCK)
                    ON G.[MO_ID] = VND.[ManufactureID]
            ) AS TB
            WHERE TB.[R] = 1

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_INV_WIP_LOOKUP_TAG')
            SELECT
                 [ManufactureID] = SRC.[ManufactureID]
                ,[DAT]           = SRC.[DAT]
            INTO #TB_INV_WIP_LOOKUP_TAG
            FROM (
                SELECT
                     TAG.[ManufactureID]
                    ,TAG.[DAT]
                    ,[R] = ROW_NUMBER() OVER (PARTITION BY TAG.[ManufactureID] ORDER BY TAG.[ManufactureID])
                FROM #TB_INV_WIP_GROUP_MO AS G
                INNER JOIN [LCA].[dboReaders].[VW_Planning_DispatchRO_RawMaterialHangtagYesNo] AS TAG WITH(NOLOCK)
                    ON G.[MO_ID] = TAG.[ManufactureID]
            ) AS SRC
            WHERE SRC.[R] = 1

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_INV_WIP_LOOKUP_BOM')
            SELECT
                 [StyleID]    = TB.[StyleID]
                ,[PartNumber] = TB.[PartNumber]
            INTO #TB_INV_WIP_LOOKUP_BOM
            FROM (
                SELECT
                     BOM.[StyleID]
                    ,BOM.[PartNumber]
                    ,[R] = ROW_NUMBER() OVER (PARTITION BY BOM.[StyleID] ORDER BY BOM.[StyleID])
                FROM #TB_INV_WIP_GROUP_STYLE AS G
                INNER JOIN [LCA].[dboReaders].[VW_Planning_DispatchRO_BOMRequireHangtag] AS BOM WITH(NOLOCK)
                    ON G.[StyleID] = BOM.[StyleID]
            ) AS TB
            WHERE TB.[R] = 1

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_FINAL_PROC_INVENTARIO_MOS_WIP')
            SELECT
                 [StyleID]				= S.[StyleID]
                ,[Style]				= S.[Style]
                ,[Season]				= S.[Season]
                ,[Color]				= S.[Color]
                ,[BoxStat]				= 'WIP'
                ,[BoxNumber]			= S.[MO]
                ,[BIN]					= 'WIP'
                ,[PackDate]				= CASE
                                                WHEN ISDATE(S.[Bucket]) <> 1 THEN ISNULL(TRY_CAST(S.[RequiredDate] AS DATE), '')
                                                WHEN S.[Bucket] IS NULL
                                                  OR S.[Bucket] = 'N/A'
                                                  OR S.[Bucket] = 'Urgente'
                                                  OR S.[Bucket] = 'Imprimir'
                                                  THEN ISNULL(TRY_CAST(S.[RequiredDate] AS DATE), '')
                                                ELSE ISNULL(TRY_CAST(S.[Bucket] AS DATE), '')
                                              END
                ,[Size]					= S.[Size]
                ,[QTY]					= SUM(ISNULL(S.[MAKE1],0))
                ,[StockCategory]		= 'WIP'
                ,[MO_ID]				= S.[MO_ID]
                ,[MO]					= S.[MO]
                ,[OrderID]				= S.[OrderID]
                ,[PONumber]				= S.[PONumber]
                ,[OrigFabricVendorName]	= ISNULL(VND.[OrigFabricVendorName],'')
                ,[RequireHangtag]		= ISNULL(TAG.[DAT],1)
                ,[PNHangtag]			= ISNULL(BOM.[PartNumber], 'NO Hangtag Assigned')
                ,[TariffCategory]		= S.[TariffCategory]
                ,[CSVBoxNumber]			= CAST('' AS VARCHAR(100))
                ,[PPFG]					= CAST('' AS VARCHAR(100))
                ,[TypeQuery]			= 2
                ,[OrderWIP]				= CASE
                                                WHEN S.[Status] LIKE '%Postproduction%' THEN 2
                                                WHEN S.[Status] LIKE '%Manufacture%'    THEN 3
                                                WHEN S.[Status] LIKE '%Cutting%'        THEN 4
                                                WHEN S.[Status] LIKE '%Released%'       THEN 5
                                                WHEN S.[Status] LIKE '%Forecast%'       THEN 6
                                                ELSE 7
                                              END
                ,[OPTION]				= MO.[Comments17]
                ,[ProductDivison]       = ST.[Comments9]
            INTO #TB_FINAL_PROC_INVENTARIO_MOS_WIP
            FROM #TB_DATA_MOS_INVENTORY_RFCB AS S
            LEFT JOIN [LCA].[dbo].[ManufactureOrders] AS MO   WITH(NOLOCK) ON MO.[ManufactureID]   = S.[MO_ID]
            LEFT JOIN [LCA].[dbo].[Styles]            AS ST   WITH(NOLOCK) ON ST.[StyleID]         = S.[StyleID]
            LEFT JOIN #TB_INV_WIP_LOOKUP_VENDOR       AS VND               ON VND.[ManufactureID]  = S.[MO_ID]
            LEFT JOIN #TB_INV_WIP_LOOKUP_TAG          AS TAG               ON TAG.[ManufactureID]  = S.[MO_ID]
            LEFT JOIN #TB_INV_WIP_LOOKUP_BOM          AS BOM               ON BOM.[StyleID]        = S.[StyleID]
            WHERE ISNULL(S.[MAKE1],0) > 0
            GROUP BY
                 S.[StyleID]
                ,S.[Style]
                ,S.[Season]
                ,S.[Color]
                ,S.[MO]
                ,S.[Size]
                ,S.[MO_ID]
                ,S.[OrderID]
                ,S.[PONumber]
                ,ISNULL(VND.[OrigFabricVendorName],'')
                ,ISNULL(TAG.[DAT],1)
                ,ISNULL(BOM.[PartNumber], 'NO Hangtag Assigned')
                ,S.[TariffCategory]
                ,CASE
                    WHEN ISDATE(S.[Bucket]) <> 1 THEN ISNULL(TRY_CAST(S.[RequiredDate] AS DATE), '')
                    WHEN S.[Bucket] IS NULL
                      OR S.[Bucket] = 'N/A'
                      OR S.[Bucket] = 'Urgente'
                      OR S.[Bucket] = 'Imprimir'
                      THEN ISNULL(TRY_CAST(S.[RequiredDate] AS DATE), '')
                    ELSE ISNULL(TRY_CAST(S.[Bucket] AS DATE), '')
                 END
                ,CASE
                    WHEN S.[Status] LIKE '%Postproduction%' THEN 2
                    WHEN S.[Status] LIKE '%Manufacture%'    THEN 3
                    WHEN S.[Status] LIKE '%Cutting%'        THEN 4
                    WHEN S.[Status] LIKE '%Released%'       THEN 5
                    WHEN S.[Status] LIKE '%Forecast%'       THEN 6
                    ELSE 7
                 END
                ,MO.[Comments17]
                ,ST.[Comments9]

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA BASE TB_FINAL_PROC_INVENTARIO_ACTIVO')
            SELECT TOP 0
                 [RowData] = CAST(NULL AS BIGINT)
                ,[StyleID]
                ,[Style]
                ,[Season]
                ,[Color]
                ,[BoxStat]
                ,[BoxNumber]
                ,[BIN]
                ,[PackDate]
                ,[Size]
                ,[QTY]
                ,[StockCategory]
                ,[MO_ID]
                ,[MO]
                ,[OrderID]
                ,[PONumber]
                ,[OrigFabricVendorName]
                ,[RequireHangtag]
                ,[PNHangtag]
                ,[TariffCategory]
                ,[CSVBoxNumber]
                ,[PPFG]
                ,[TypeQuery]
                ,[OrderWIP]
                ,[OPTION]
                ,[ProductDivison]
            INTO #TB_FINAL_PROC_INVENTARIO_ACTIVO
            FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. INSERT INVENTARIO WAREHOUSE')
            INSERT INTO #TB_FINAL_PROC_INVENTARIO_ACTIVO
            SELECT
                 [RowData] = CAST(NULL AS BIGINT)
                ,[StyleID]
                ,[Style]
                ,[Season]
                ,[Color]
                ,[BoxStat]
                ,[BoxNumber]
                ,[BIN]
                ,[PackDate]
                ,[Size]
                ,[QTY]
                ,[StockCategory]
                ,[MO_ID]
                ,[MO]
                ,[OrderID]
                ,[PONumber]
                ,[OrigFabricVendorName]
                ,[RequireHangtag]
                ,[PNHangtag]
                ,[TariffCategory]
                ,[CSVBoxNumber]
                ,[PPFG]
                ,[TypeQuery]
                ,[OrderWIP]
                ,[OPTION]
                ,[ProductDivison]
            FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. INSERT INVENTARIO MOS WIP')
            INSERT INTO #TB_FINAL_PROC_INVENTARIO_ACTIVO
            SELECT
                 [RowData] = CAST(NULL AS BIGINT)
                ,[StyleID]
                ,[Style]
                ,[Season]
                ,[Color]
                ,[BoxStat]
                ,[BoxNumber]
                ,[BIN]
                ,[PackDate]
                ,[Size]
                ,[QTY]
                ,[StockCategory]
                ,[MO_ID]
                ,[MO]
                ,[OrderID]
                ,[PONumber]
                ,[OrigFabricVendorName]
                ,[RequireHangtag]
                ,[PNHangtag]
                ,[TariffCategory]
                ,[CSVBoxNumber]
                ,[PPFG]
                ,[TypeQuery]
                ,[OrderWIP]
                ,[OPTION]
                ,[ProductDivison]
            FROM #TB_FINAL_PROC_INVENTARIO_MOS_WIP

            ;WITH CTE_RowData AS (
                SELECT
                     [RowData]
                    ,[RN] = ROW_NUMBER() OVER (
                                ORDER BY [TypeQuery] ASC,[OrderWIP] ASC,[Style] ASC,[Color] ASC,[PackDate] ASC,[BoxNumber] ASC,[Season] DESC,[Size] ASC,[MO_ID] ASC,[OrderID] ASC
                           )
                FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO
            )
            UPDATE CTE_RowData
            SET [RowData] = [RN]

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. LIMPIEZA INTERMEDIA')
            -----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #TB_FINAL_PROC_INVENTARIO_MOS_WIP Y #TB_FINAL_PROC_INVENTARIO_ACTIVO)
                DROP TABLE IF EXISTS #TB_INV_WIP_GROUP_MO
                DROP TABLE IF EXISTS #TB_INV_WIP_GROUP_STYLE
                DROP TABLE IF EXISTS #TB_INV_WIP_LOOKUP_VENDOR
                DROP TABLE IF EXISTS #TB_INV_WIP_LOOKUP_TAG
                DROP TABLE IF EXISTS #TB_INV_WIP_LOOKUP_BOM
            -----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #TB_FINAL_PROC_INVENTARIO_MOS_WIP Y #TB_FINAL_PROC_INVENTARIO_ACTIVO)

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO')
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO----------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        -- ----------SELECT TOP 10 TABLAS FINALES-------------------------------------------------------------------------------------------------------------------------------------------
        -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        --     PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO SELECT TOP 10 TABLAS FINALES')

        --     SELECT TOP 10 * FROM #TB_FINAL_PROC_DATES
        --     SELECT TOP 10 * FROM #TB_FINAL_PROC_ORDENES_DEMAND
        --     SELECT TOP 10 * FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE
        --     SELECT TOP 10 * FROM #TB_DATA_MOS_INVENTORY_RFCB
        --     SELECT TOP 10 * FROM #TB_FINAL_PROC_INVENTARIO_MOS_WIP
        --     SELECT TOP 10 * FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO

        --     PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    SELECT TOP 10 TABLAS FINALES')
        -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        -- ----------SELECT TOP 10 TABLAS FINALES-------------------------------------------------------------------------------------------------------------------------------------------
        -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP---------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            -- Objetivo del bloque:
            -- Asignar inventario activo (Warehouse + MOS WIP consolidado) a ordenes
            -- respetando prioridad FIFO en ordenes y en secuencia de inventario.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP')

            DROP TABLE IF EXISTS #TB_DISPATCH_INV_POOL
            DROP TABLE IF EXISTS #TB_DISPATCH_ORD_BASE
            DROP TABLE IF EXISTS #TB_DISPATCH_ORD_SIZE
            DROP TABLE IF EXISTS #TB_DISPATCH_INV_SIZE
            DROP TABLE IF EXISTS #TB_DISPATCH_GROUP_RANK_BASE
            DROP TABLE IF EXISTS #TB_DISPATCH_GROUP_RANK
            DROP TABLE IF EXISTS #TB_DISPATCH_GROUP_SIZE_AVAIL
            DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_GROUP_CAND
            DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_GROUP
            DROP TABLE IF EXISTS #TB_DISPATCH_ORD_REQ_SEQ
            DROP TABLE IF EXISTS #TB_DISPATCH_INV_SEQ
            DROP TABLE IF EXISTS #TB_DISPATCH_ALLOC_RAW
            DROP TABLE IF EXISTS #TB_DISPATCH_ALLOC_SIZE
            DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_OK
            DROP TABLE IF EXISTS #DispatchOrdersFromInventoryWIP
            DROP TABLE IF EXISTS #DispatchOrdersFromInventoryWIP_OrdersDispatched
            DROP TABLE IF EXISTS #DispatchOrdersFromInventoryWIP_OrdersNotDispatched

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. LIMPIEZA TABLAS TEMPORALES')

            -- 1) Base de ordenes con prioridad FIFO.
            --    Se construye OrderRow para preservar el orden de despacho.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 1 BASE ORDENES FIFO')
            SELECT
                [OrderRow]      = ROW_NUMBER() OVER (
                                        ORDER BY S.[Style] ASC, S.[Color] ASC, S.[ordenEmb] ASC, S.[RequiredDate] ASC, S.[DocDate] ASC, S.[OrderID] ASC
                                    )
                ,[Style]         = CAST(S.[Style] AS VARCHAR(200))
                ,[Color]         = CAST(S.[Color] AS VARCHAR(200))
                ,[RequiredDate]  = S.[RequiredDate]
                ,[ordenEmb]      = CAST(S.[ordenEmb] AS VARCHAR(50))
                ,[DocDate]       = S.[DocDate]
                ,[OrderID]       = S.[OrderID]
                ,[PONumber]      = S.[PONumber]
                ,[MO]            = S.[MO]
                ,[MO_ID]         = S.[MO_ID]
                ,[DiscardMPA]    = ISNULL(S.[DiscardMPA],0)
                ,[SuspendOrd]    = ISNULL(S.[SuspendOrd],0)
                ,[XS]            = CAST(ISNULL(S.[XS],0)    AS FLOAT)
                ,[S]             = CAST(ISNULL(S.[S],0)     AS FLOAT)
                ,[M]             = CAST(ISNULL(S.[M],0)     AS FLOAT)
                ,[L]             = CAST(ISNULL(S.[L],0)     AS FLOAT)
                ,[XL]            = CAST(ISNULL(S.[XL],0)    AS FLOAT)
                ,[2XL]           = CAST(ISNULL(S.[2XL],0)   AS FLOAT)
                ,[3XL]           = CAST(ISNULL(S.[3XL],0)   AS FLOAT)
                ,[4XL]           = CAST(ISNULL(S.[4XL],0)   AS FLOAT)
                ,[5XL]           = CAST(ISNULL(S.[5XL],0)   AS FLOAT)
                ,[2T]            = CAST(ISNULL(S.[2T],0)    AS FLOAT)
                ,[3T]            = CAST(ISNULL(S.[3T],0)    AS FLOAT)
                ,[4T]            = CAST(ISNULL(S.[4T],0)    AS FLOAT)
                ,[5T]            = CAST(ISNULL(S.[5T],0)    AS FLOAT)
                ,[6T]            = CAST(ISNULL(S.[6T],0)    AS FLOAT)
                ,[7T]            = CAST(ISNULL(S.[7T],0)    AS FLOAT)
                ,[8T]            = CAST(ISNULL(S.[8T],0)    AS FLOAT)
                ,[ADJ]           = CAST(ISNULL(S.[ADJ],0)   AS FLOAT)
                ,[S_M]           = CAST(ISNULL(S.[S_M],0)   AS FLOAT)
                ,[L_XL]          = CAST(ISNULL(S.[L_XL],0)  AS FLOAT)
                ,[S/M]           = CAST(ISNULL(S.[S/M],0)   AS FLOAT)
                ,[L/XL]          = CAST(ISNULL(S.[L/XL],0)  AS FLOAT)
                ,[ONE]           = CAST(ISNULL(S.[ONE],0)   AS FLOAT)
            INTO #TB_DISPATCH_ORD_BASE
            FROM #TB_FINAL_PROC_ORDENES_DEMAND AS S


            -- SELECT * FROM #TB_DISPATCH_ORD_BASE
            -- RETURN
            -- 2) Demanda por talla (unpivot con CROSS APPLY VALUES).
            --    Solo tallas con demanda > 0 y ordenes no bloqueadas.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 2 DEMANDA POR TALLA')
            SELECT
                 O.[OrderRow]
                ,O.[Style]
                ,O.[Color]
                ,[Size]        = CAST(D.[Size] AS VARCHAR(20))
                ,[QtyRequired] = D.[Qty]
            INTO #TB_DISPATCH_ORD_SIZE
            FROM #TB_DISPATCH_ORD_BASE AS O
            CROSS APPLY (
                VALUES
                     ('XS'  ,O.[XS]  ),('S'   ,O.[S]   ),('M'   ,O.[M]   ),('L'   ,O.[L]   ),('XL'  ,O.[XL]  )
                    ,('2XL' ,O.[2XL] ),('3XL' ,O.[3XL] ),('4XL' ,O.[4XL] ),('5XL' ,O.[5XL] )
                    ,('2T'  ,O.[2T]  ),('3T'  ,O.[3T]  ),('4T'  ,O.[4T]  ),('5T'  ,O.[5T]  ),('6T'  ,O.[6T]  ),('7T'  ,O.[7T]  ),('8T'  ,O.[8T]  )
                    ,('ADJ' ,O.[ADJ] ),('S_M' ,O.[S_M] ),('L_XL',O.[L_XL]),('S/M' ,O.[S/M] ),('L/XL',O.[L/XL]),('ONE' ,O.[ONE] )
            ) AS D([Size],[Qty])
            WHERE D.[Qty] > 0
              AND O.[DiscardMPA] = 0
              AND O.[SuspendOrd] = 0

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 2A INDEX DEMANDA')
            CREATE CLUSTERED INDEX IX_TB_DISPATCH_ORD_SIZE_CI
                ON #TB_DISPATCH_ORD_SIZE([OrderRow],[Size])

            CREATE NONCLUSTERED INDEX IX_TB_DISPATCH_ORD_SIZE_SC
                ON #TB_DISPATCH_ORD_SIZE([Style],[Color],[Size],[OrderRow])
                INCLUDE([QtyRequired])

            -- 3) Inventario base por talla.
            --    Es la bolsa de disponibilidad que se consumira durante la asignacion.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 3 INVENTARIO BASE')
            SELECT
                 [InvPoolRow]            = IDENTITY(BIGINT,1,1)
                ,[Style]                 = CAST(S.[Style] AS VARCHAR(200))
                ,[Color]                 = CAST(S.[Color] AS VARCHAR(200))
                ,[Season]                = CAST(ISNULL(S.[Season],'') AS VARCHAR(50))
                ,[TypeQuery]             = CAST(ISNULL(S.[TypeQuery],0) AS INT)
                ,[OrderWIP]              = CAST(ISNULL(S.[OrderWIP],9999) AS INT)
                ,[OrigFabricVendorName]  = CAST(ISNULL(S.[OrigFabricVendorName],'') AS VARCHAR(200))
                ,[PackDate]              = CAST(S.[PackDate] AS DATE)
                ,[BoxNumber]             = CAST(ISNULL(S.[BoxNumber],'') AS VARCHAR(120))
                ,[MO]                    = CAST(ISNULL(S.[MO],'') AS VARCHAR(120))
                ,[MO_ID]                 = S.[MO_ID]
                ,[Size]                  = CAST(ISNULL(S.[Size],'') AS VARCHAR(20))
                ,[QtyAvailable]          = CAST(ISNULL(S.[QTY],0) AS FLOAT)
            INTO #TB_DISPATCH_INV_POOL
            FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO AS S
            WHERE ISNULL(S.[QTY],0) > 0

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 3A INDEX INVENTARIO')
            CREATE CLUSTERED INDEX IX_TB_DISPATCH_INV_POOL_CI
                ON #TB_DISPATCH_INV_POOL([InvPoolRow])

            CREATE NONCLUSTERED INDEX IX_TB_DISPATCH_INV_POOL
                ON #TB_DISPATCH_INV_POOL([Style],[Color],[OrigFabricVendorName],[TypeQuery],[Size],[OrderWIP],[PackDate],[BoxNumber],[Season],[InvPoolRow])
                INCLUDE([QtyAvailable],[MO],[MO_ID])

            SELECT
                 [Style]                = I.[Style]
                ,[Color]                = I.[Color]
                ,[OrigFabricVendorName] = I.[OrigFabricVendorName]
                ,[TypeQuery]            = I.[TypeQuery]
                ,[MinOrderWIP]          = MIN(I.[OrderWIP])
                ,[MinPackDate]          = MIN(I.[PackDate])
            INTO #TB_DISPATCH_GROUP_RANK_BASE
            FROM #TB_DISPATCH_INV_POOL AS I
            GROUP BY I.[Style],I.[Color],I.[OrigFabricVendorName],I.[TypeQuery]

            -- Ranking de grupos por Style/Color:
            -- primero TypeQuery y luego antiguedad (OrderWIP, PackDate).
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 4 RANKING GRUPOS')
            SELECT
                 B.[Style]
                ,B.[Color]
                ,B.[OrigFabricVendorName]
                ,B.[TypeQuery]
                ,[GroupRank]            = ROW_NUMBER() OVER (
                                            PARTITION BY B.[Style],B.[Color]
                                            ORDER BY B.[TypeQuery] ASC, B.[MinOrderWIP] ASC, B.[MinPackDate] ASC, B.[OrigFabricVendorName] ASC
                                          )
            INTO #TB_DISPATCH_GROUP_RANK
            FROM #TB_DISPATCH_GROUP_RANK_BASE AS B

            CREATE NONCLUSTERED INDEX IX_TB_DISPATCH_GROUP_RANK
                ON #TB_DISPATCH_GROUP_RANK([Style],[Color],[GroupRank],[OrigFabricVendorName],[TypeQuery])

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 5 DISPONIBLE POR GRUPO/TALLA')
            SELECT
                 [Style]
                ,[Color]
                ,[OrigFabricVendorName]
                ,[TypeQuery]
                ,[Size]
                ,[QtyAvailable] = SUM([QtyAvailable])
            INTO #TB_DISPATCH_GROUP_SIZE_AVAIL
            FROM #TB_DISPATCH_INV_POOL
            GROUP BY [Style],[Color],[OrigFabricVendorName],[TypeQuery],[Size]

            CREATE NONCLUSTERED INDEX IX_TB_DISPATCH_GROUP_SIZE_AVAIL
                ON #TB_DISPATCH_GROUP_SIZE_AVAIL([Style],[Color],[OrigFabricVendorName],[TypeQuery],[Size])
                INCLUDE([QtyAvailable])

            -- Grupo candidato por orden:
            -- solo pasa el grupo que cubre TODAS las tallas requeridas de la orden.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 6 CANDIDATOS POR ORDEN')
            SELECT
                 X.[OrderRow]
                ,X.[Style]
                ,X.[Color]
                ,X.[OrigFabricVendorName]
                ,X.[TypeQuery]
                ,X.[GroupRank]
                ,[Rnk] = ROW_NUMBER() OVER(PARTITION BY X.[OrderRow] ORDER BY X.[GroupRank] ASC)
            INTO #TB_DISPATCH_ORDER_GROUP_CAND
            FROM (
                SELECT
                     OD.[OrderRow]
                    ,G.[Style]
                    ,G.[Color]
                    ,G.[OrigFabricVendorName]
                    ,G.[TypeQuery]
                    ,G.[GroupRank]
                    ,[CntNeeded]  = COUNT(*)
                    ,[CntCovered] = SUM(CASE WHEN ISNULL(GA.[QtyAvailable],0) >= OD.[QtyRequired] THEN 1 ELSE 0 END)
                FROM #TB_DISPATCH_ORD_SIZE AS OD
                INNER JOIN #TB_DISPATCH_GROUP_RANK AS G
                    ON G.[Style] = OD.[Style]
                   AND G.[Color] = OD.[Color]
                LEFT JOIN #TB_DISPATCH_GROUP_SIZE_AVAIL AS GA
                    ON GA.[Style] = G.[Style]
                   AND GA.[Color] = G.[Color]
                   AND GA.[OrigFabricVendorName] = G.[OrigFabricVendorName]
                   AND GA.[TypeQuery] = G.[TypeQuery]
                   AND GA.[Size]  = OD.[Size]
                GROUP BY
                     OD.[OrderRow]
                    ,G.[Style]
                    ,G.[Color]
                    ,G.[OrigFabricVendorName]
                    ,G.[TypeQuery]
                    ,G.[GroupRank]
            ) AS X
            WHERE X.[CntCovered] = X.[CntNeeded]

            SELECT
                 [OrderRow]
                ,[Style]
                ,[Color]
                ,[OrigFabricVendorName]
                ,[TypeQuery]
            INTO #TB_DISPATCH_ORDER_GROUP
            FROM #TB_DISPATCH_ORDER_GROUP_CAND
            WHERE [Rnk] = 1

            -- Grupo definitivo (1 grupo por orden).
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 6A GRUPO DEFINITIVO')
            CREATE UNIQUE CLUSTERED INDEX IX_TB_DISPATCH_ORDER_GROUP
                ON #TB_DISPATCH_ORDER_GROUP([OrderRow])

            -- Demanda acumulada por talla dentro del grupo elegido.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 7 ACUMULADO DEMANDA')
            SELECT
                 O.[OrderRow]
                ,O.[Style]
                ,O.[Color]
                ,O.[Size]
                ,O.[QtyRequired]
                ,G.[OrigFabricVendorName]
                ,G.[TypeQuery]
                ,[CumReq]     = SUM(O.[QtyRequired]) OVER (
                                    PARTITION BY O.[Style],O.[Color],G.[OrigFabricVendorName],G.[TypeQuery],O.[Size]
                                    ORDER BY O.[OrderRow] ASC
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                                 )
                ,[CumReqPrev] = SUM(O.[QtyRequired]) OVER (
                                    PARTITION BY O.[Style],O.[Color],G.[OrigFabricVendorName],G.[TypeQuery],O.[Size]
                                    ORDER BY O.[OrderRow] ASC
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                                 )
            INTO #TB_DISPATCH_ORD_REQ_SEQ
            FROM #TB_DISPATCH_ORD_SIZE AS O
            INNER JOIN #TB_DISPATCH_ORDER_GROUP AS G
                ON G.[OrderRow] = O.[OrderRow]

            UPDATE S SET [CumReqPrev] = ISNULL([CumReqPrev],0)
            FROM #TB_DISPATCH_ORD_REQ_SEQ AS S

            -- Inventario acumulado por talla en secuencia FIFO de cajas.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 8 ACUMULADO INVENTARIO')
            SELECT
                 I.*
                ,[CumInv]     = SUM(I.[QtyAvailable]) OVER (
                                    PARTITION BY I.[Style],I.[Color],I.[OrigFabricVendorName],I.[TypeQuery],I.[Size]
                                    ORDER BY I.[OrderWIP] ASC, I.[PackDate] ASC, I.[BoxNumber] ASC, I.[Season] DESC, I.[InvPoolRow] ASC
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                                 )
                ,[CumInvPrev] = SUM(I.[QtyAvailable]) OVER (
                                    PARTITION BY I.[Style],I.[Color],I.[OrigFabricVendorName],I.[TypeQuery],I.[Size]
                                    ORDER BY I.[OrderWIP] ASC, I.[PackDate] ASC, I.[BoxNumber] ASC, I.[Season] DESC, I.[InvPoolRow] ASC
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                                 )
            INTO #TB_DISPATCH_INV_SEQ
            FROM #TB_DISPATCH_INV_POOL AS I
            INNER JOIN (
                SELECT DISTINCT [Style],[Color],[OrigFabricVendorName],[TypeQuery]
                FROM #TB_DISPATCH_ORDER_GROUP
            ) AS G
                ON G.[Style] = I.[Style]
               AND G.[Color] = I.[Color]
               AND G.[OrigFabricVendorName] = I.[OrigFabricVendorName]
               AND G.[TypeQuery] = I.[TypeQuery]

            UPDATE S SET [CumInvPrev] = ISNULL([CumInvPrev],0)
            FROM #TB_DISPATCH_INV_SEQ AS S

            -- Asignacion set-based por interseccion de rangos acumulados:
            -- QtyAssigned = overlap([CumReqPrev,CumReq], [CumInvPrev,CumInv]).
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 9 ASIGNACION FIFO')
            SELECT
                 O.[OrderRow]
                ,O.[Style]
                ,O.[Color]
                ,OB.[RequiredDate]
                ,OB.[ordenEmb]
                ,OB.[DocDate]
                ,OB.[OrderID]
                ,OB.[PONumber]
                ,OB.[MO]
                ,OB.[MO_ID]
                ,O.[TypeQuery]
                ,O.[OrigFabricVendorName]
                ,O.[Size]
                ,[QtyRequired] = O.[QtyRequired]
                ,[QtyAssigned] = CAST(X.[EndPoint] - X.[StartPoint] AS FLOAT)
                ,I.[InvPoolRow]
                ,I.[OrderWIP]
                ,I.[BoxNumber]
                ,I.[MO]    AS [InvMO]
                ,I.[MO_ID] AS [InvMO_ID]
            INTO #TB_DISPATCH_ALLOC_RAW
            FROM #TB_DISPATCH_ORD_REQ_SEQ AS O
            INNER JOIN #TB_DISPATCH_ORD_BASE AS OB
                ON OB.[OrderRow] = O.[OrderRow]
            INNER JOIN #TB_DISPATCH_INV_SEQ AS I
                ON I.[Style] = O.[Style]
               AND I.[Color] = O.[Color]
               AND I.[OrigFabricVendorName] = O.[OrigFabricVendorName]
               AND I.[TypeQuery] = O.[TypeQuery]
               AND I.[Size] = O.[Size]
            CROSS APPLY (
                SELECT
                     [StartPoint] = CASE WHEN O.[CumReqPrev] > I.[CumInvPrev] THEN O.[CumReqPrev] ELSE I.[CumInvPrev] END
                    ,[EndPoint]   = CASE WHEN O.[CumReq] < I.[CumInv] THEN O.[CumReq] ELSE I.[CumInv] END
            ) AS X
            WHERE X.[EndPoint] > X.[StartPoint]

            SELECT
                 [OrderRow]
                ,[Size]
                ,[QtyRequired] = MAX([QtyRequired])
                ,[QtyAssigned] = SUM([QtyAssigned])
            INTO #TB_DISPATCH_ALLOC_SIZE
            FROM #TB_DISPATCH_ALLOC_RAW
            GROUP BY [OrderRow],[Size]

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 10 VALIDAR ORDENES COMPLETAS')
            SELECT
                 R.[OrderRow]
            INTO #TB_DISPATCH_ORDER_OK
            FROM #TB_DISPATCH_ORD_SIZE AS R
            LEFT JOIN #TB_DISPATCH_ALLOC_SIZE AS A
                ON A.[OrderRow] = R.[OrderRow]
               AND A.[Size] = R.[Size]
            GROUP BY R.[OrderRow]
            HAVING SUM(CASE WHEN ISNULL(A.[QtyAssigned],0) >= R.[QtyRequired] THEN 1 ELSE 0 END) = COUNT(*)

            -- Detalle de despacho (linea por orden+talla+caja usada).
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 11 GENERAR DETALLE DESPACHADO')
            SELECT
                 [RowData]             = ROW_NUMBER() OVER (
                                            ORDER BY [TypeQuery] ASC,[OrderWIP] ASC,[Style] ASC,[Color] ASC,[ordenEmb] ASC,[RequiredDate] ASC,[DocDate] ASC,[BoxNumber] ASC,[OrderRow] ASC,[Size] ASC
                                          )
                ,[DispatchSeq]         = ROW_NUMBER() OVER (
                                            ORDER BY [TypeQuery] ASC,[OrderWIP] ASC,[Style] ASC,[Color] ASC,[ordenEmb] ASC,[RequiredDate] ASC,[DocDate] ASC,[BoxNumber] ASC,[OrderRow] ASC,[Size] ASC
                                          )
                ,[OrderRow]
                ,[Style]
                ,[Color]
                ,[RequiredDate]
                ,[ordenEmb]
                ,[DocDate]
                ,[OrderID]
                ,[PONumber]
                ,[OrderMO]              = [MO]
                ,[OrderMO_ID]           = [MO_ID]
                ,[TypeQuery]
                ,[OrderWIP]
                ,[OrigFabricVendorName]
                ,[Size]
                ,[QtyAssigned]
                ,[InvBoxNumber]         = [BoxNumber]
                ,[InvMO]
                ,[InvMO_ID]
                ,[CommentFinal]         = CAST('Dispatched' AS VARCHAR(255))
            INTO #DispatchOrdersFromInventoryWIP
            FROM #TB_DISPATCH_ALLOC_RAW
            WHERE [OrderRow] IN (SELECT [OrderRow] FROM #TB_DISPATCH_ORDER_OK)

            -- Resumen de ordenes despachadas.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 12 GENERAR RESUMEN DESPACHADAS')
            SELECT
                 [RowData] = ROW_NUMBER() OVER (
                                ORDER BY O.[Style] ASC,O.[Color] ASC,O.[ordenEmb] ASC,O.[RequiredDate] ASC,O.[DocDate] ASC,O.[OrderID] ASC
                             )
                ,O.[OrderRow]
                ,O.[Style]
                ,O.[Color]
                ,O.[RequiredDate]
                ,O.[ordenEmb]
                ,O.[DocDate]
                ,O.[OrderID]
                ,O.[PONumber]
                ,O.[MO]
                ,O.[MO_ID]
                ,G.[TypeQuery]
                ,G.[OrigFabricVendorName]
                ,[CommentFinal] = CAST('Dispatched' AS VARCHAR(255))
            INTO #DispatchOrdersFromInventoryWIP_OrdersDispatched
            FROM #TB_DISPATCH_ORD_BASE AS O
            INNER JOIN #TB_DISPATCH_ORDER_OK AS K
                ON K.[OrderRow] = O.[OrderRow]
            INNER JOIN #TB_DISPATCH_ORDER_GROUP AS G
                ON G.[OrderRow] = O.[OrderRow]

            -- Ordenes no despachadas con motivo principal.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 13 GENERAR NO DESPACHADAS')
            ;WITH CTE_Reasons AS (
                SELECT
                     O.[OrderRow],O.[Style],O.[Color],O.[RequiredDate],O.[ordenEmb],O.[DocDate],O.[OrderID],O.[PONumber],O.[MO],O.[MO_ID]
                    ,[CommentFinal] = CAST('Not dispatched: Discard/Suspend flag' AS VARCHAR(255))
                    ,[ReasonRank]   = 1
                FROM #TB_DISPATCH_ORD_BASE AS O
                WHERE O.[DiscardMPA] = 1 OR O.[SuspendOrd] = 1

                UNION ALL

                SELECT
                     O.[OrderRow],O.[Style],O.[Color],O.[RequiredDate],O.[ordenEmb],O.[DocDate],O.[OrderID],O.[PONumber],O.[MO],O.[MO_ID]
                    ,[CommentFinal] = CAST('Not dispatched: inventory not enough by Style/Color/Vendor/TypeQuery' AS VARCHAR(255))
                    ,[ReasonRank]   = 2
                FROM #TB_DISPATCH_ORD_BASE AS O
                LEFT JOIN #TB_DISPATCH_ORDER_GROUP AS G
                    ON G.[OrderRow] = O.[OrderRow]
                WHERE O.[DiscardMPA] = 0
                  AND O.[SuspendOrd] = 0
                  AND G.[OrderRow] IS NULL

                UNION ALL

                SELECT
                     O.[OrderRow],O.[Style],O.[Color],O.[RequiredDate],O.[ordenEmb],O.[DocDate],O.[OrderID],O.[PONumber],O.[MO],O.[MO_ID]
                    ,[CommentFinal] = CAST('Not dispatched: inventory exhausted in FIFO sequence' AS VARCHAR(255))
                    ,[ReasonRank]   = 3
                FROM #TB_DISPATCH_ORD_BASE AS O
                INNER JOIN #TB_DISPATCH_ORDER_GROUP AS G
                    ON G.[OrderRow] = O.[OrderRow]
                LEFT JOIN #TB_DISPATCH_ORDER_OK AS K
                    ON K.[OrderRow] = O.[OrderRow]
                WHERE O.[DiscardMPA] = 0
                  AND O.[SuspendOrd] = 0
                  AND K.[OrderRow] IS NULL
            )
            SELECT
                 [RowData] = ROW_NUMBER() OVER (
                                ORDER BY [Style] ASC,[Color] ASC,[ordenEmb] ASC,[RequiredDate] ASC,[DocDate] ASC,[OrderID] ASC
                             )
                ,[OrderRow],[Style],[Color],[RequiredDate],[ordenEmb],[DocDate],[OrderID],[PONumber],[MO],[MO_ID],[CommentFinal]
            INTO #DispatchOrdersFromInventoryWIP_OrdersNotDispatched
            FROM (
                SELECT
                     R.*
                    ,[RN] = ROW_NUMBER() OVER(PARTITION BY R.[OrderRow] ORDER BY R.[ReasonRank] ASC)
                FROM CTE_Reasons AS R
            ) AS X
            WHERE X.[RN] = 1

            -----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #DispatchOrdersFromInventoryWIP, #DispatchOrdersFromInventoryWIP_OrdersDispatched, #DispatchOrdersFromInventoryWIP_OrdersNotDispatched)
                DROP TABLE IF EXISTS #TB_DISPATCH_INV_POOL
                DROP TABLE IF EXISTS #TB_DISPATCH_ORD_BASE
                DROP TABLE IF EXISTS #TB_DISPATCH_ORD_SIZE
                DROP TABLE IF EXISTS #TB_DISPATCH_INV_SIZE
                DROP TABLE IF EXISTS #TB_DISPATCH_GROUP_RANK_BASE
                DROP TABLE IF EXISTS #TB_DISPATCH_GROUP_RANK
                DROP TABLE IF EXISTS #TB_DISPATCH_GROUP_SIZE_AVAIL
                DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_GROUP_CAND
                DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_GROUP
                DROP TABLE IF EXISTS #TB_DISPATCH_ORD_REQ_SEQ
                DROP TABLE IF EXISTS #TB_DISPATCH_INV_SEQ
                DROP TABLE IF EXISTS #TB_DISPATCH_ALLOC_RAW
                DROP TABLE IF EXISTS #TB_DISPATCH_ALLOC_SIZE
                DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_OK
            -----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #DispatchOrdersFromInventoryWIP, #DispatchOrdersFromInventoryWIP_OrdersDispatched, #DispatchOrdersFromInventoryWIP_OrdersNotDispatched)

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP')
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP---------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        SELECT * FROM #TB_FINAL_PROC_DATES ORDER BY RowData ASC
        SELECT * FROM #TB_FINAL_PROC_ORDENES_DEMAND ORDER BY RowData ASC
        SELECT * FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO ORDER BY RowData ASC
        SELECT * FROM #DispatchOrdersFromInventoryWIP ORDER BY RowData ASC
        SELECT * FROM #DispatchOrdersFromInventoryWIP_OrdersDispatched ORDER BY RowData ASC
        SELECT * FROM #DispatchOrdersFromInventoryWIP_OrdersNotDispatched ORDER BY RowData ASC
