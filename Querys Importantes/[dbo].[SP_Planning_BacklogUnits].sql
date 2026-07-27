USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_Planning_BacklogUnits]    Script Date: 21/07/2026 07:31:54 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
                                                                                                                                  
ALTER PROCEDURE [dbo].[SP_Planning_BacklogUnits]
     @process    VARCHAR(MAX)
    ,@data       NVARCHAR(MAX)
    ,@NoSelect   BIT = 0
    ,@otherData  NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- -- -- -- -- =========================================================================================================
    -- -- -- -- -- PRUEBA RAPIDA (DESCOMENTAR PARA PROBAR)
    -- -- -- -- -- =========================================================================================================
    -- DECLARE @process   VARCHAR(MAX)
    -- DECLARE @data      NVARCHAR(MAX)
    -- DECLARE @NoSelect  BIT = 0
    -- DECLARE @otherData NVARCHAR(MAX)
    
    
    -- SET @process = 'dispatchinventory.run'
    
    -- SET @data = '{
    --   "key":"PRUEBA20260715_001",
    --   "flag":true,
    --   "reserveUnits":true,
    --   "runDate":"ReqShip"
    -- }'
    
    
    
    -- {"process":"dispatchinventory.run","data":{"key":"c9180ccf-75de-4aab-b669-18fe9c6c96e3","reserveUnits":true,"runDate":"ReqShip"}}
    -- SET @data = '{
    --   "key":"BARN_Urgentes20260720"
    --   ,"flag":true
    --   ,"runDate":"ReqShip"
    --   ,"flagDispatchSamples":true
    -- }'
    
    -- "runDate":"ReqShip"             -> [RequiredDate]      (default)
    -- "runDate":"PromiseDate"         -> [PromiseDate]
    -- "runDate":"DocDate"             -> [Doc Date]
    -- "runDate":"CustDueDate"         -> [Cust Due Date]
    -- "runDate":"OriginalRequestDate" -> [Original Request Date]
    
    
    -- -- -- -- -- EXEC [dbo].[SP_Planning_DispatchInventory]
    -- -- -- -- --      @process   = @processTest
    -- -- -- --     ,@data      = @dataTest
    -- -- -- --     ,@NoSelect  = @NoSelectTest
    -- -- -- --     ,@otherData = @otherDataTest OUTPUT
    -- -- -- -- 
    -- -- -- -- SELECT @otherDataTest AS [otherDataTest]
    -- -- -- -- RETURN
    -- -- -- =========================================================================================================


    -- SELECT 
    --     PONumber 
    --     ,RequiredDate               = RequiredDate
    --     ,[Doc Date]                 = BuyDate
    --     ,[Cust Due Date]            = StartShipDate
    --     ,[Original Request Date]    = CustomerDueDate
    -- FROM LCA.dbo.Orders WITH(NOLOCK)
    -- WHERE PONumber LIKE  '%2987582%'
    
    DECLARE @message            VARCHAR(MAX)
    DECLARE @messageData        NVARCHAR(MAX)
    DECLARE @error              BIT
    DECLARE @result             NVARCHAR(MAX)
    DECLARE @version            VARCHAR(100) = 'v20260715.0.0.1'
    DECLARE @ProcessName        VARCHAR(150) = 'dispatchinventory.run'
    DECLARE @KeyGenerated       VARCHAR(200)
    DECLARE @TestData           BIT = 0
    DECLARE @FlagBacklog         BIT = 0
    DECLARE @RunDate             VARCHAR(50) = 'ReqShip'
    DECLARE @flagDispatchSamples BIT = 0

    SET @messageData = '[]'
    SET @result      = '[]'
    SET @error       = 0
    SET @message     = CONCAT('OK version ', @version)

    BEGIN TRY
        -- DROP TABLE #TB_FINAL_PROC_ORDENES_DEMAND
        IF ISNULL(@process,'') <> @ProcessName
        BEGIN
            SET @error = 1
            SET @message = CONCAT('Proceso no soportado: ',ISNULL(@process,''))
            GOTO EndProcedureDispatchInventory
        END

        SET @KeyGenerated = COALESCE(
             NULLIF(JSON_VALUE(@data,'$.key'),'')
            ,NULLIF(JSON_VALUE(@data,'$.KeyGenerated'),'')
            ,NULLIF(JSON_VALUE(@data,'$.keyGenerated'),'')
        )
        SET @TestData    = ISNULL(TRY_CONVERT(BIT, JSON_VALUE(@data,'$.testData')),0)
        SET @FlagBacklog = ISNULL(TRY_CONVERT(BIT, JSON_VALUE(@data,'$.flag')),0)--------MEMIIN1194
        SET @RunDate             = ISNULL(NULLIF(LTRIM(RTRIM(JSON_VALUE(@data,'$.runDate'))),  ''), 'ReqShip')
        SET @flagDispatchSamples = ISNULL(TRY_CONVERT(BIT, JSON_VALUE(@data,'$.flagDispatchSamples')), 0)

        IF ISNULL(@KeyGenerated,'') = ''
        BEGIN
            SET @error = 1
            SET @message = 'No se recibio key en JSON.'
            GOTO EndProcedureDispatchInventory
        END

        IF OBJECT_ID('[AppsLCA].[dbo].[TB_Global_Process]','U') IS NULL
        BEGIN
            SET @error = 1
            SET @message = 'No existe [AppsLCA].[dbo].[TB_Global_Process]. Ejecuta primero el script de creacion de tabla.'
            GOTO EndProcedureDispatchInventory
        END

        IF @flagDispatchSamples = 1 AND OBJECT_ID('[AppsLCA].[dbo].[TB_Backlog_Parameters_OrdersDispatch]','U') IS NULL
        BEGIN
            SET @error   = 1
            SET @message = 'No existe [AppsLCA].[dbo].[TB_Backlog_Parameters_OrdersDispatch]. Crea la tabla antes de usar flagDispatchSamples=1.'
            GOTO EndProcedureDispatchInventory
        END

        MERGE [AppsLCA].[dbo].[TB_Global_Process] AS T
        USING (SELECT @KeyGenerated AS [KeyGenerated], @ProcessName AS [Process]) AS S
           ON T.[KeyGenerated] = S.[KeyGenerated]
          AND T.[Process]      = S.[Process]
        WHEN MATCHED THEN
            UPDATE SET
                 [Process]      = @ProcessName
                ,[Status]       = 'RUNNING'
                ,[Percent]      = 5
                ,[StepCode]     = 'START'
                ,[StepNameUser] = 'Iniciando proceso'
                ,[MessageUser]  = 'Estamos preparando la informacion de despacho de inventario.'
                ,[MessageTech]  = CONCAT(CONVERT(VARCHAR(23),SYSDATETIME(),121),' - Inicio de proceso')
                ,[StartedAt]    = ISNULL(T.[StartedAt],SYSDATETIME())
                ,[UpdatedAt]    = SYSDATETIME()
                ,[FinishedAt]   = NULL
                ,[DataJson]     = @data
        WHEN NOT MATCHED THEN
            INSERT ([KeyGenerated],[Process],[Status],[Percent],[StepCode],[StepNameUser],[MessageUser],[MessageTech],[DataJson],[StartedAt],[UpdatedAt],[FinishedAt])
            VALUES (@KeyGenerated,@ProcessName,'RUNNING',5,'START','Iniciando proceso','Estamos preparando la informacion de despacho.',CONCAT(CONVERT(VARCHAR(23),SYSDATETIME(),121),' - Inicio de proceso'),@data,SYSDATETIME(),SYSDATETIME(),NULL);
        

        ----Explicacion general del procedimiento
        -------------------         Objetivo global
        ------------------- Generar tablas finales de ordenes e inventario para dispatch y backlog por talla, en tiempo real, sin depender de tablas guardadas en wordpress.
        -------------------         Flujo de procesos (N bloques principales)
        ------------------- 1) Fechas de contenedor: arma calendario operativo de contenedores y due dates.
        ------------------- 2) Ordenes activas para despacho: construye demanda por orden/talla y enriquece con lookups L2.
        ------------------- 3) Inventario activo warehouse: calcula inventario on hand en bodegas permitidas.
        ------------------- 4) Inventario en MOS en WIP: agrega unidades de MOs activas por talla.
        ------------------- 5) Inventario en bultos WIP: agrega unidades activas por bundle/tarea/ubicacion.
        ------------------- 6) Inventario consolidado: une warehouse + MOS WIP en una sola bolsa de inventario.
        ------------------- 7) Despacho desde inventario WIP: asigna inventario a demanda con reglas FIFO.
        ------------------- 8) Datos CSV: genera layout final de exportacion para analisis operativo.
        -------------------         Filtros globales mas relevantes
        ------------------- Ordenes: MO StatusID IN (20,40), QuantityOrdered > 0, exclusion de temporadas BLANK (salvo excepciones definidas).
        ------------------- Inventario warehouse: PackedBoxes.StatusID IN (0,8,98,100), WarehouseID IN (35,53,60), Quantity <> 0.
        ------------------- Inventario MOS WIP: StatusID IN (20,40,51,53), Cutting/Preproduction con BundleCreateDate IS NULL.
        ------------------- Inventario bultos WIP: MO.StatusID < 90, TypeQueryN = 1, Quantity > 0, excluye ubicaciones NO WIP.
        ------------------- Asignacion dispatch: demanda por talla > 0, excluye ordenes DiscardMPA/SuspendOrd, inventario con QTY > 0.

  
        


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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 6,
                [StepCode] = 'DATES',
                [StepNameUser] = 'Fechas de contenedor',
                [MessageUser] = 'Generando calendario de contenedores.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - INICIO PROCEDIMIENTO PARA FECHAS DE CONTENEDOR'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA FECHAS DE CONTENEDOR. DROP/CREATE #TB_FINAL_PROC_DATES')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 7,
                [StepCode] = 'DATES',
                [StepNameUser] = 'Fechas de contenedor',
                [MessageUser] = 'Generando calendario de contenedores.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA FECHAS DE CONTENEDOR. DROP/CREATE #TB_FINAL_PROC_DATES'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 8,
                [StepCode] = 'DATES',
                [StepNameUser] = 'Fechas de contenedor',
                [MessageUser] = 'Generando calendario de contenedores.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA FECHAS DE CONTENEDOR. PARAMETROS INICIALES'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 9,
                [StepCode] = 'DATES',
                [StepNameUser] = 'Fechas de contenedor',
                [MessageUser] = 'Generando calendario de contenedores.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA FECHAS DE CONTENEDOR. AJUSTE FECHA INICIAL'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 10,
                [StepCode] = 'DATES',
                [StepNameUser] = 'Fechas de contenedor',
                [MessageUser] = 'Generando calendario de contenedores.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA FECHAS DE CONTENEDOR. CTE_Dates + INSERT #TB_FINAL_PROC_DATES'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 11,
                [StepCode] = 'DATES',
                [StepNameUser] = 'Fechas de contenedor',
                [MessageUser] = 'Generando calendario de contenedores. Verificando ultima fecha de contenedor',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA FECHAS DE CONTENEDOR. CALCULO LAST CONTAINER'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            SET @LastContainer = (SELECT MAX([Date_Container]) FROM #TB_FINAL_PROC_DATES )
            
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    PROCEDIMIENTO PARA FECHAS DE CONTENEDOR')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 12,
                [StepCode] = 'DATES',
                [StepNameUser] = 'Fechas de contenedor',
                [MessageUser] = 'Generando calendario de contenedores finalizado.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - FIN    PROCEDIMIENTO PARA FECHAS DE CONTENEDOR'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            -- SELECT * FROM #TB_FINAL_PROC_DATES
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA FECHAS DE CONTENEDOR--------------------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO-----------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 13,
                [StepCode] = 'ORDERS',
                [StepNameUser] = 'Preparando ordenes',
                [MessageUser] = 'Estamos preparando y validando las ordenes para despacho.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - INICIO PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            

            ----Explicacion del procedimiento para ordenes activas para despacho
            -------------------         Que hace el bloque
            ------------------- Limpia tablas temporales (final e intermedias) para evitar residuos de ejecuciones previas.
            ------------------- Construye la base de demanda por talla desde MO/Order/Style y reglas de filtrado de planeacion.
            ------------------- Convierte la demanda a formato pivot por tallas (XS, S, M, etc.) manteniendo 1 fila por orden/MO.
            ------------------- Crea tabla final temporal #TB_FINAL_PROC_ORDENES_DEMAND con estructura destino.
            ------------------- Prepara tablas auxiliares de grupo (MO e ItemDetailID) para acotar joins de lookups.
            ------------------- Carga lookups (L2, Box, SalesStyle, Export Order, ETA, OTLO y OrdersSuspended) en tablas temporales.
            ------------------- Actualiza la tabla final por etapas con UPDATE (alias S/B) para enriquecer campos de negocio y defaults.
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
            DROP TABLE IF EXISTS #TB_LOOKUP_MO_SIZE_WITHDRAW                 ---Lookup de retiro de blanks por MO y talla
        	DROP TABLE IF EXISTS #TB_LOOKUP_L2                                 ---Tabla lookup de datos L2 por ItemDetailID (SKU/Logo/Status/CustPO)
        	DROP TABLE IF EXISTS #TB_LOOKUP_BOX                                ---Tabla lookup de primer FirstBlankBoxNumber por ManufactureID
        	DROP TABLE IF EXISTS #TB_LOOKUP_SALESSTYLE                         ---Tabla lookup de equivalencia Style Embroidery -> Style Blank
        	DROP TABLE IF EXISTS #TB_LOOKUP_ORD                                ---Tabla lookup de export order (Color/MachineGroup/Relabel/DocDate)
        	DROP TABLE IF EXISTS #TB_LOOKUP_ETA                                ---Tabla lookup de tipo de aplicacion por LogoStyle
            DROP TABLE IF EXISTS #TB_LOOKUP_OTLO                               ---Tabla lookup de tipo de orden por LogoStyle
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
                     ,[OriginalMake]               = TB2.[MAKE1]
                     ,[QtyWithdraw]                = CAST(0 AS FLOAT)
                     ,[StyleSubcategory]           = TB2.[StyleSubcategory]
                     ,[StockCategory]              = TB2.[StockCategory]
                     ,[APS]                        = TB2.[APS]
                     ,[CustomerOrder]              = TB2.[CustomerOrder]
                     ,[PWModulo]                   = TB2.[PWModulo]
                     ,[ItemDetailID]             = CASE 
     		                                            WHEN ( TB2.[PONumber] LIKE 'ORD-PO%') THEN
     		                                                NULL
    		                                            WHEN ( TB2.[PONumber] LIKE 'ORD-%') AND ( ISNUMERIC ( REPLACE ( TB2.[PONumber],'ORD-','') ) = 1)  THEN
    		                                                TRY_CAST(REPLACE ( TB2.[PONumber],'ORD-','') AS BIGINT)
    		                                            WHEN ( TB2.[PONumber] LIKE 'ORD%') AND (ISNUMERIC(TB2.Comments6) = 1 ) THEN
    		                                                TRY_CAST(TB2.[Comments6] AS BIGINT)
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
    						 ,[CustomerOrder]              = SUBSTRING(ord.[Comments6], 1, 9)
    						 ,[Collection]                 = STCL.[CollectionName]
    						 ,[Comments6]                  = ord.[Comments6]
    						 ,[PWModulo]                   = mo.[Comments7]  
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
    					        -- Modo normal: todos los filtros de planeacion existentes
    					        @flagDispatchSamples = 0
    					        AND (
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
    					    )
    					    OR (
    					        -- Modo dispatch samples: solo ordenes de la tabla de parametros, sin restricciones de planeacion
    					        @flagDispatchSamples = 1
    					        AND MO.[ManufactureID] IN (
    					            SELECT [ManufactureID]
    					            FROM [AppsLCA].[dbo].[TB_Backlog_Parameters_OrdersDispatch] WITH(NOLOCK)
    					            WHERE [Status] = 1
    					        )
    					    )
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
    						,mo.[Comments7]
                    ) AS TB2
		    ) AS TB_T

            
            SELECT DISTINCT [MO_ID]         INTO #TB_GROUP_MOS_ORDENES_DEMAND           FROM #TB_MOS_ORDENES_DEMAND_BY_SIZE
            SELECT DISTINCT [ItemDetailID]  INTO #TB_GROUP_ITEMDETAILID_ORDENES_DEMAND  FROM #TB_MOS_ORDENES_DEMAND_BY_SIZE
            
            
            -- SELECT * FROM #TB_GROUP_MOS_ORDENES_DEMAND
            
            
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 14,
                [StepCode] = 'ORDERS_WITHDRAW',
                [StepNameUser] = 'Actualizando inventario withdraw',
                [MessageUser] = 'Estamos actualizando el inventario withdraw de las ordenes con assigment.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. UPDATE WITHDRAW'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            


            SELECT 
                 [MO_ID]        = S.[MO_ID]
                 ,[Size]        = FG.[garmentSize] 
                ,[QtyWithdraw]  = SUM(ISNULL(MB.[QuantityWithdrawn],0))
            INTO #TB_LOOKUP_MO_SIZE_WITHDRAW
            FROM #TB_GROUP_MOS_ORDENES_DEMAND AS S
            INNER JOIN [LCA].[dbo].ManufactureBlanks AS MB ON MB.ManufactureID = S.MO_ID
            INNER JOIN [LCA].[dbo].FinishedGoods AS FG ON FG.FinishedGoodsID = MB.FinishedGoodsID
            GROUP BY
                S.[MO_ID]
                ,FG.[garmentSize] 

            UPDATE T
            SET
                 [QtyWithdraw] = ISNULL(W.[QtyWithdraw],0)
                ,[QTY] = CASE
                            WHEN ISNULL(T.[OriginalMake],0) - ISNULL(W.[QtyWithdraw],0) < 0 THEN 0
                            ELSE ISNULL(T.[OriginalMake],0) - ISNULL(W.[QtyWithdraw],0)
                         END
            FROM #TB_MOS_ORDENES_DEMAND_BY_SIZE AS T
            LEFT JOIN #TB_LOOKUP_MO_SIZE_WITHDRAW AS W
                   ON W.[MO_ID] = T.[MO_ID]
                  AND W.[Size]  = T.[Size]
            
           
            
            SELECT
                 *
            INTO #TB_MOS_ORDENES_DEMAND_PIVOT
            FROM (
                SELECT
                     TB_T.[ordenEmb]
                    ,TB_T.[KeyT]
                    ,TB_T.[KeyStyle]
                    ,TB_T.[Style]
                    ,TB_T.[Season]
                    ,TB_T.[Color]
                    ,TB_T.[ColorDescription]
                    ,TB_T.[POStat]
                    ,TB_T.[OrderID]
                    ,TB_T.[PONum]
                    ,TB_T.[ItemDetailID]
                    ,TB_T.[MO_ID]
                    ,TB_T.[Purno]
                    ,TB_T.[RequiredDate]
                    ,TB_T.[StyleSubcategory]
                    ,TB_T.[StockCategory]
                    ,TB_T.[APS]
                    ,TB_T.[CustomerOrder]
                    ,TB_T.[PWModulo]
                    ,TB_T.[Collection]
                    ,[OriginalMake] = SUM(ISNULL(TB_T.[OriginalMake],0)) OVER (
                        PARTITION BY
                             TB_T.[ordenEmb]
                            ,TB_T.[KeyT]
                            ,TB_T.[KeyStyle]
                            ,TB_T.[Style]
                            ,TB_T.[Season]
                            ,TB_T.[Color]
                            ,TB_T.[ColorDescription]
                            ,TB_T.[POStat]
                            ,TB_T.[OrderID]
                            ,TB_T.[PONum]
                            ,TB_T.[ItemDetailID]
                            ,TB_T.[MO_ID]
                            ,TB_T.[Purno]
                            ,TB_T.[RequiredDate]
                            ,TB_T.[StyleSubcategory]
                            ,TB_T.[StockCategory]
                            ,TB_T.[APS]
                            ,TB_T.[CustomerOrder]
                            ,TB_T.[PWModulo]
                            ,TB_T.[Collection]
                    )
                    ,[QtyWithdraw] = SUM(ISNULL(TB_T.[QtyWithdraw],0)) OVER (
                        PARTITION BY
                             TB_T.[ordenEmb]
                            ,TB_T.[KeyT]
                            ,TB_T.[KeyStyle]
                            ,TB_T.[Style]
                            ,TB_T.[Season]
                            ,TB_T.[Color]
                            ,TB_T.[ColorDescription]
                            ,TB_T.[POStat]
                            ,TB_T.[OrderID]
                            ,TB_T.[PONum]
                            ,TB_T.[ItemDetailID]
                            ,TB_T.[MO_ID]
                            ,TB_T.[Purno]
                            ,TB_T.[RequiredDate]
                            ,TB_T.[StyleSubcategory]
                            ,TB_T.[StockCategory]
                            ,TB_T.[APS]
                            ,TB_T.[CustomerOrder]
                            ,TB_T.[PWModulo]
                            ,TB_T.[Collection]
                    )
                    ,TB_T.[SIZE]
                    ,TB_T.[QTY]
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
                ,[Validate_Color]        = CAST(''      AS VARCHAR(100))
                ,[RequiredDate]          = TB_ALL_PIVOT.[RequiredDate]
                ,[StyleSubcategory]      = TB_ALL_PIVOT.[StyleSubcategory]
                ,[StockCategory]         = TB_ALL_PIVOT.[StockCategory]
                ,[APS]                   = TB_ALL_PIVOT.[APS]
                ,[CustomerOrder]         = TB_ALL_PIVOT.[CustomerOrder]
                ,[PWModulo]              = TB_ALL_PIVOT.[PWModulo]
                ,[SKUStatus]             = CAST(NULL    AS VARCHAR(100))
                ,[DetailStatus]          = CAST(NULL    AS VARCHAR(100))
                ,[Status]                = CAST(NULL    AS VARCHAR(100))
                ,[LogoStyle]             = CAST(NULL    AS VARCHAR(100))
                ,[EmbroideryApplication] = CAST(NULL    AS VARCHAR(100))
                ,[TypeEmbroidery]        = CAST(NULL    AS VARCHAR(MAX))
                ,[Technique]             = CAST(NULL    AS VARCHAR(MAX))
                ,[ScreenPrint]           = CAST(0       AS INT)
                ,[ScreenPrintAfter]      = CAST(0       AS INT)
                ,[ScreenPrintBefore]     = CAST(0       AS INT)
                ,[Embroidery]            = CAST(0       AS INT)
                ,[SublimationBefore]     = CAST(0       AS INT)
                ,[SublimationAfter]      = CAST(0       AS INT)
                ,[HDP]                   = CAST(0       AS INT)
                ,[Blanks]                = CAST(0       AS INT)
                ,[EmbHWApplique]         = CAST(0       AS INT)
                ,[EmbHWDirect]           = CAST(0       AS INT)
                ,[EmbHWPatch]            = CAST(0       AS INT)
                ,[EmbHWHDP]              = CAST(0       AS INT)
                ,[EmbAppDirect]          = CAST(0       AS INT)
                ,[EmbAppLBA]             = CAST(0       AS INT)
                ,[Type]                  = CAST(NULL    AS VARCHAR(MAX))
                ,[OrderTypeDescription]  = CAST(NULL    AS VARCHAR(60))
                ,[ApplicationOrder]      = CAST(NULL    AS VARCHAR(50))
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
                ,[OriginalMake]          = CAST(ISNULL(TB_ALL_PIVOT.[OriginalMake], 0) AS FLOAT)
                ,[QtyWithdraw]           = CAST(ISNULL(TB_ALL_PIVOT.[QtyWithdraw], 0) AS FLOAT)
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
                ,[Cust Due Date]         = CAST(NULL    AS DATE)
                ,[Original Request Date] = CAST(NULL    AS DATE)
                ,[DiscardMPA]            = CAST(0       AS BIT)
                ,[SuspendOrd]            = CAST(0       AS BIT)
                ,[SuspendType]           = CAST(NULL    AS VARCHAR(100))
                ,[Inv_Pack_Date]         = CAST(NULL    AS DATE)
                ,[discard_by_percentage] = CAST(NULL    AS DECIMAL(10,4))
                ,[PriceCode]             = CAST(NULL    AS VARCHAR(50))
                ,[PromiseDate]           = CAST(NULL    AS DATE)
                ,[InventoryDate]         = CAST(NULL    AS DATE)
                ,[RunDate]               = CAST(NULL    AS DATE)
            INTO #TB_FINAL_PROC_ORDENES_DEMAND
            FROM #TB_MOS_ORDENES_DEMAND_PIVOT AS TB_ALL_PIVOT

            -----------SELECT PARA TRAER EN TABLAS TEMPORALES LOS DATOS NECESARIOS PARA PLANIFICACION DE DESPACHO DE PRENDAS
                
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_L2')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 15,
                [StepCode] = 'ORDERS',
                [StepNameUser] = 'Preparando ordenes',
                [MessageUser] = 'Preparando ordenes para despacho. Tablas L2Brand qryOpenOrderSuppl_162.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_L2'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 16,
                [StepCode] = 'ORDERS',
                [StepNameUser] = 'Preparando ordenes',
                [MessageUser] = 'Estamos preparando y validando las ordenes para despacho.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_BOX'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

                SELECT TB.*
                INTO #TB_LOOKUP_BOX
                FROM (
                    SELECT
                         [ManufactureID]    = PB.[AttachedManufactureID]
                        ,[BoxNumber]        = PB.[BoxNumber]
                        ,ROW_NUMBER() OVER(PARTITION BY [AttachedManufactureID] ORDER BY [PackedBoxID]) AS R_Num
                    FROM #TB_GROUP_MOS_ORDENES_DEMAND AS S
                    INNER JOIN [LCA].[dbo].PackedBoxes AS PB WITH(NOLOCK) ON PB.[AttachedManufactureID] = S.[MO_ID]
                ) AS TB
                WHERE TB.R_Num = 1
    
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_SALESSTYLE')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 17,
                [StepCode] = 'ORDERS',
                [StepNameUser] = 'Preparando ordenes',
                [MessageUser] = 'Estamos preparando y validando las ordenes para despacho.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_SALESSTYLE'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 18,
            [StepCode] = 'ORDERS',
                [StepNameUser] = 'Preparando ordenes',
                [MessageUser] = 'Estamos preparando y validando las ordenes para despacho.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_ORD'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 19,
                [StepCode] = 'ORDERS',
                [StepNameUser] = 'Preparando ordenes',
                [MessageUser] = 'Estamos preparando y validando las ordenes para despacho.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_ETA'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

                SELECT
                    ETA.[LogoStyle]
                    ,[ApplicationType] = MAX(ETA.[ApplicationType])
                INTO #TB_LOOKUP_ETA
                FROM [AppsLCA].[dbo].[Planning_Backlog_EmbroideryTypeApplique] AS ETA WITH(NOLOCK)
                GROUP BY ETA.[LogoStyle]
                
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_ORDER_TYPE_LOGOSTYLE')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 20,
                [StepCode] = 'ORDERS',
                [StepNameUser] = 'Preparando ordenes',
                [MessageUser] = 'Estamos preparando y validando las ordenes para despacho.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_ORDER_TYPE_LOGOSTYLE'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

                SELECT  
                     [LogoStyle]              = CAST([LogoStyle]             AS VARCHAR(20) )
                    ,[OrderTypeID]            = CAST([OrderTypeID]           AS INTEGER     )
                    ,[OrderTypeDescription]   = CAST([OrderTypeDescription]  AS VARCHAR(60) )
                    ,[ApplicationOrder]       = CAST([ApplicationOrder]      AS VARCHAR(50) )
                INTO #TB_LOOKUP_OTLO
                FROM OPENQUERY([MARIADB],'SELECT * FROM wordpress.L2Brands_LogoStyle')  AS TBM
                  
    
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_OS')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 21,
                [StepCode] = 'ORDERS',
                [StepNameUser] = 'Preparando ordenes',
                [MessageUser] = 'Estamos preparando y validando las ordenes para despacho.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. TABLA TB_LOOKUP_OS'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 22,
                [StepCode] = 'ORDERS',
                [StepNameUser] = 'Preparando ordenes',
                [MessageUser] = 'Estamos preparando y validando las ordenes para despacho.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO. UPDATE DE TABLAS TEMPORALES'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

                UPDATE S SET
                     [SKUStatus]                = B.[SKUStatus]
                    ,[DetailStatus]             = B.[DetailStatus]
                    ,[Status]                   = B.[Status]
                    ,[LogoStyle]                = B.[LogoStyle]
                    ,[GroupID]                  = B.[GroupID]
                    ,[CustPO]                   = B.[CustPO]
                    ,[MakeL2]                   = B.[Quantity]
                    ,[L2B_OrderStatus]          = B.[Status]
                    ,[PriceCode]                = B.[PriceCode]    
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
                    ,[Validate_Color]           = IIF(S.[Color] <> ISNULL(B.[Color], ''),'Color not match','ok')
                    ,[MachineGroup]             = B.[MachineGroup]
                    ,[Relabel]                  = B.[Relabel] 
                    ,[DocDate]                  = B.[Doc Date]
                    ,[Cust Due Date]            = TRY_CAST(B.[CustDueDate] AS DATE)
                    ,[Original Request Date]    = TRY_CAST(B.[OriginalRequestDate] AS DATE)
                    ,[DiscardMPA]               = CASE
                                                        WHEN @flagDispatchSamples = 1 THEN 0
                                                        WHEN B.[MovedPerAllocation] = 1 AND
                                                            CASE @RunDate
                                                                WHEN 'DocDate'             THEN B.[Doc Date]
                                                                WHEN 'CustDueDate'         THEN TRY_CAST(B.[CustDueDate]         AS DATE)
                                                                WHEN 'OriginalRequestDate' THEN TRY_CAST(B.[OriginalRequestDate] AS DATE)
                                                                WHEN 'PromiseDate'         THEN TRY_CAST(B.[PromiseDate]         AS DATE)
                                                                ELSE                            B.[Req Ship]
                                                            END >= DATEADD(DAY, 21, GETDATE()) THEN 1
                                                        ELSE 0
                                                    END
                    ,[PromiseDate]              = TRY_CAST(B.[PromiseDate] AS DATE)
                    ,[InventoryDate]            = TRY_CAST(B.[InventoryDate] AS DATE)
                FROM #TB_FINAL_PROC_ORDENES_DEMAND         AS S
                INNER JOIN #TB_LOOKUP_ORD           AS B ON B.[ItemDetailID] = S.[ItemDetailID]
                -- SELECT * fROM #TB_LOOKUP_ORD
                UPDATE S SET
                     [EmbroideryApplication]    = B.[ApplicationType]
                FROM #TB_FINAL_PROC_ORDENES_DEMAND         AS S
                INNER JOIN #TB_LOOKUP_ETA           AS B ON B.[LogoStyle] = S.[LogoStyle]

                -- Crear lookup de LogoStyle → tipo de proceso de aplicacion
                DROP TABLE IF EXISTS #TB_LOOKUP_LOGOSTYLEAPPLICATION_D
                SELECT [LogoStyle]       = CAST([LogoStyle] AS VARCHAR(20))
                      ,[ScreenPrintAfter]  = CASE WHEN ([OrderTypeDescription] LIKE '%To Print%' AND ([ApplicationOrder] IS NULL OR [ApplicationOrder] = 'AFTER')) OR [LogoStyle] = 'DTG' THEN 1 ELSE 0 END
                      ,[ScreenPrintBefore] = CASE WHEN [OrderTypeDescription] LIKE '%To Print%' AND [ApplicationOrder] = 'BEFORE' THEN 1 ELSE 0 END
                      ,[Embroidery]        = CASE WHEN [OrderTypeDescription] LIKE '%To Embroidery%' THEN 1 ELSE 0 END
                      ,[SublimationBefore] = CASE WHEN [OrderTypeDescription] LIKE '%To Sublimation%' AND ([ApplicationOrder] = '' OR [ApplicationOrder] = 'BEFORE') THEN 1 ELSE 0 END
                      ,[SublimationAfter]  = CASE WHEN [OrderTypeDescription] LIKE '%To Sublimation%' AND [ApplicationOrder] = 'AFTER' THEN 1 ELSE 0 END
                      ,[HDP]               = CASE WHEN [OrderTypeDescription] LIKE '%Only DHT%' AND [LogoStyle] <> 'DTG' THEN 1 ELSE 0 END
                      ,[Blanks]            = CASE WHEN [OrderTypeDescription] LIKE '%Blanks%' THEN 1 ELSE 0 END
                INTO #TB_LOOKUP_LOGOSTYLEAPPLICATION_D
                FROM OPENQUERY([MARIADB],'SELECT * FROM wordpress.L2Brands_LogoStyle')

                IF NOT EXISTS (SELECT 1 FROM #TB_LOOKUP_LOGOSTYLEAPPLICATION_D WHERE [LogoStyle] = 'DTG')
                    INSERT INTO #TB_LOOKUP_LOGOSTYLEAPPLICATION_D ([LogoStyle],[ScreenPrintAfter],[ScreenPrintBefore],[Embroidery],[SublimationBefore],[SublimationAfter],[HDP],[Blanks])
                    VALUES ('DTG', 1, 0, 0, 0, 0, 0, 0)

                -- Agregacion de flags de aplicacion por RowData
                DROP TABLE IF EXISTS #TB_DEMAND_LOGOSTYLE_APPLICATION
                SELECT
                     [RowData]
                    ,[ScreenPrintAfter]  = SUM([ScreenPrintAfter])
                    ,[ScreenPrintBefore] = SUM([ScreenPrintBefore])
                    ,[Embroidery]        = SUM([Embroidery])
                    ,[SublimationBefore] = SUM([SublimationBefore])
                    ,[SublimationAfter]  = SUM([SublimationAfter])
                    ,[HDP]               = SUM([HDP])
                    ,[Blanks]            = SUM([Blanks])
                INTO #TB_DEMAND_LOGOSTYLE_APPLICATION
                FROM (
                    SELECT S.[RowData]
                          ,ISNULL(LK.[ScreenPrintAfter],  0) AS [ScreenPrintAfter]
                          ,ISNULL(LK.[ScreenPrintBefore], 0) AS [ScreenPrintBefore]
                          ,ISNULL(LK.[Embroidery],        0) AS [Embroidery]
                          ,ISNULL(LK.[SublimationBefore], 0) AS [SublimationBefore]
                          ,ISNULL(LK.[SublimationAfter],  0) AS [SublimationAfter]
                          ,ISNULL(LK.[HDP],               0) AS [HDP]
                          ,ISNULL(LK.[Blanks],            0) AS [Blanks]
                    FROM #TB_FINAL_PROC_ORDENES_DEMAND AS S
                    CROSS APPLY STRING_SPLIT(ISNULL(S.[EmbroideryApplication],''), ',') AS sv
                    LEFT JOIN #TB_LOOKUP_LOGOSTYLEAPPLICATION_D AS LK ON LK.[LogoStyle] = TRIM(sv.[value])
                    WHERE S.[EmbroideryApplication] IS NOT NULL AND S.[EmbroideryApplication] <> ''
                ) AS F
                GROUP BY [RowData]

                UPDATE S
                SET [ScreenPrintAfter]  = ISNULL(APP.[ScreenPrintAfter],  0)
                   ,[ScreenPrintBefore] = ISNULL(APP.[ScreenPrintBefore], 0)
                   ,[Embroidery]        = ISNULL(APP.[Embroidery],        0)
                   ,[SublimationBefore] = ISNULL(APP.[SublimationBefore], 0)
                   ,[SublimationAfter]  = ISNULL(APP.[SublimationAfter],  0)
                   ,[HDP]               = ISNULL(APP.[HDP],               0)
                   ,[Blanks]            = ISNULL(APP.[Blanks],             0)
                --    ,[ScreenPrint]       = CAST(IIF(ISNULL(APP.[ScreenPrintAfter],0) > 0 OR ISNULL(APP.[ScreenPrintBefore],0) > 0, 1, 0) AS INT)---cambio SCREENPRINT
                   ,[ScreenPrint]          = CAST(ISNULL(APP.[ScreenPrintAfter],0) + ISNULL(APP.[ScreenPrintBefore],0) AS INT)
                FROM #TB_FINAL_PROC_ORDENES_DEMAND AS S
                LEFT JOIN #TB_DEMAND_LOGOSTYLE_APPLICATION AS APP ON APP.[RowData] = S.[RowData]

                DROP TABLE IF EXISTS #TB_DEMAND_LOGOSTYLE_APPLICATION
                DROP TABLE IF EXISTS #TB_LOOKUP_LOGOSTYLEAPPLICATION_D

                DROP TABLE IF EXISTS #TB_LOOKUP_TYPEEMBROIDERY_1
                SELECT [LogoStyle] = [Code], [Category], [Technique], [IsHeadwear] = CAST(1 AS BIT)
                INTO #TB_LOOKUP_TYPEEMBROIDERY_1
                FROM [192.168.1.93].[AppsLCA].[dbo].[PBI_EMH_CodeClasif] WITH(NOLOCK)

                INSERT INTO #TB_LOOKUP_TYPEEMBROIDERY_1
                SELECT [LogoStyle]  = lam.[LogoStyle]
                      ,[Category]   = CASE WHEN lam.[AppliqueMaterial] = 'Direct' OR lam.[AppliqueMaterial] IS NULL THEN 'Direct' ELSE 'LBA' END
                      ,[Technique]  = CASE WHEN lam.[AppliqueMaterial] = 'Direct' OR lam.[AppliqueMaterial] IS NULL THEN 'Direct' ELSE 'LBA' END
                      ,[IsHeadwear] = CAST(0 AS BIT)
                FROM [192.168.1.93].[AppsLCA].[dbo].[PBI_EMB_LogoApliqueMaterial] AS lam WITH(NOLOCK)

                UPDATE S
                SET [TypeEmbroidery] = NULLIF(STUFF((
                    SELECT DISTINCT ',' + LTE.[Category]
                    FROM STRING_SPLIT(ISNULL(S.[EmbroideryApplication],''), ',') AS sv
                    INNER JOIN #TB_LOOKUP_TYPEEMBROIDERY_1 AS LTE
                        ON LTE.[LogoStyle]   = TRIM(sv.[value])
                        AND LTE.[IsHeadwear] = CAST(IIF(S.[StyleSubcategory] = 'Headwear', 1, 0) AS BIT)
                    FOR XML PATH(''), TYPE
                ).value('.','VARCHAR(MAX)'), 1, 1, ''), '')
                FROM #TB_FINAL_PROC_ORDENES_DEMAND AS S
                WHERE S.[EmbroideryApplication] IS NOT NULL AND S.[EmbroideryApplication] <> ''

                -- Agregacion de Emb* por RowData
                DROP TABLE IF EXISTS #TB_DEMAND_EMBCATEGORY
                SELECT
                     [RowData]
                    ,[EmbHWApplique] = SUM(CASE WHEN LTE.[IsHeadwear] = 1 AND LTE.[Category] = 'Applique' THEN 1 ELSE 0 END)
                    ,[EmbHWDirect]   = SUM(CASE WHEN LTE.[IsHeadwear] = 1 AND LTE.[Category] = 'Direct'   THEN 1 ELSE 0 END)
                    ,[EmbHWPatch]    = SUM(CASE WHEN LTE.[IsHeadwear] = 1 AND LTE.[Category] = 'Patch'    THEN 1 ELSE 0 END)
                    ,[EmbHWHDP]      = SUM(CASE WHEN LTE.[IsHeadwear] = 1 AND LTE.[Category] = 'Transfer' THEN 1 ELSE 0 END)
                    ,[EmbAppDirect]  = SUM(CASE WHEN LTE.[IsHeadwear] = 0 AND LTE.[Category] = 'Direct'   THEN 1 ELSE 0 END)
                    ,[EmbAppLBA]     = SUM(CASE WHEN LTE.[IsHeadwear] = 0 AND LTE.[Category] = 'LBA'      THEN 1 ELSE 0 END)
                INTO #TB_DEMAND_EMBCATEGORY
                FROM #TB_FINAL_PROC_ORDENES_DEMAND AS S
                CROSS APPLY STRING_SPLIT(ISNULL(S.[EmbroideryApplication],''), ',') AS sv
                INNER JOIN #TB_LOOKUP_TYPEEMBROIDERY_1 AS LTE
                    ON LTE.[LogoStyle]   = TRIM(sv.[value])
                    AND LTE.[IsHeadwear] = CAST(IIF(S.[StyleSubcategory] = 'Headwear', 1, 0) AS BIT)
                WHERE S.[EmbroideryApplication] IS NOT NULL AND S.[EmbroideryApplication] <> ''
                GROUP BY S.[RowData]

                UPDATE S
                SET [EmbHWApplique] = ISNULL(EMB.[EmbHWApplique], 0)
                   ,[EmbHWDirect]   = ISNULL(EMB.[EmbHWDirect],   0)
                   ,[EmbHWPatch]    = ISNULL(EMB.[EmbHWPatch],     0)
                   ,[EmbHWHDP]      = ISNULL(EMB.[EmbHWHDP],       0)
                   ,[EmbAppDirect]  = ISNULL(EMB.[EmbAppDirect],   0)
                   ,[EmbAppLBA]     = ISNULL(EMB.[EmbAppLBA],      0)
                   ,[HDP]           = IIF(S.[StyleSubcategory] ='Headwear',0, ISNULL(S.[HDP],          0))
                FROM #TB_FINAL_PROC_ORDENES_DEMAND AS S
                LEFT JOIN #TB_DEMAND_EMBCATEGORY AS EMB ON EMB.[RowData] = S.[RowData]

                DROP TABLE IF EXISTS #TB_DEMAND_EMBCATEGORY

                -- Actualizar [Technique] con las tecnicas de bordado concatenadas
                UPDATE S
                SET [Technique] = NULLIF(STUFF((
                    SELECT DISTINCT ',' + LTE.[Technique]
                    FROM STRING_SPLIT(ISNULL(S.[EmbroideryApplication],''), ',') AS sv
                    INNER JOIN #TB_LOOKUP_TYPEEMBROIDERY_1 AS LTE
                        ON LTE.[LogoStyle]   = TRIM(sv.[value])
                        AND LTE.[IsHeadwear] = CAST(IIF(S.[StyleSubcategory] = 'Headwear', 1, 0) AS BIT)
                    FOR XML PATH(''), TYPE
                ).value('.','VARCHAR(MAX)'), 1, 1, ''), '')
                FROM #TB_FINAL_PROC_ORDENES_DEMAND AS S
                WHERE S.[EmbroideryApplication] IS NOT NULL AND S.[EmbroideryApplication] <> ''

                DROP TABLE IF EXISTS #TB_LOOKUP_TYPEEMBROIDERY_1

                -- Actualizar [Type] con todos los procesos activos incluyendo desglose de bordado
                UPDATE S
                SET [Type] = NULLIF(STUFF(
                      CASE WHEN S.[ScreenPrintAfter]  > 0 THEN ',Screen Print After'     ELSE '' END
                    + CASE WHEN S.[ScreenPrintBefore] > 0 THEN ',Screen Print Before'    ELSE '' END
                    -- + CASE WHEN S.[Embroidery]        > 0 THEN ',Embroidery'             ELSE '' END
                    + CASE WHEN S.[EmbHWApplique]     > 0 THEN ',Embroidery HW Applique' ELSE '' END
                    + CASE WHEN S.[EmbHWDirect]       > 0 THEN ',Embroidery HW Direct'   ELSE '' END
                    + CASE WHEN S.[EmbHWPatch]        > 0 THEN ',Embroidery HW Patch'    ELSE '' END
                    + CASE WHEN S.[EmbHWHDP]          > 0 THEN ',Embroidery HW HDP'      ELSE '' END
                    + CASE WHEN S.[EmbAppDirect]      > 0 THEN ',Embroidery APP Direct'  ELSE '' END
                    + CASE WHEN S.[EmbAppLBA]         > 0 THEN ',Embroidery APP LBA'     ELSE '' END
                    + CASE WHEN S.[SublimationBefore] > 0 THEN ',Sublimation Before'     ELSE '' END
                    + CASE WHEN S.[SublimationAfter]  > 0 THEN ',Sublimation After'      ELSE '' END
                    + CASE WHEN S.[HDP]               > 0 AND S.[StyleSubcategory] <> 'Headwear' THEN ',High Definition Print'  ELSE '' END
                    + CASE WHEN S.[Blanks]            > 0 THEN ',Blanks'                 ELSE '' END
                , 1, 1, ''), '')
                FROM #TB_FINAL_PROC_ORDENES_DEMAND AS S

                UPDATE S SET
                     [OrderTypeDescription]       = B.[OrderTypeDescription]
                    ,[ApplicationOrder]           = B.[ApplicationOrder]
                FROM #TB_FINAL_PROC_ORDENES_DEMAND         AS S
                INNER JOIN #TB_LOOKUP_OTLO          AS B ON B.[LogoStyle] = S.[LogoStyle]
    
                UPDATE S SET
                     [SuspendOrd]               = ISNULL(B.[SWHOLD], 0)
                    ,[SuspendType]              = B.[SuspendType]
                FROM #TB_FINAL_PROC_ORDENES_DEMAND         AS S
                INNER JOIN #TB_LOOKUP_OS            AS B ON B.[ManufactureID] = S.[MO_ID]

                UPDATE S SET
                    [RunDate] = CASE @RunDate
                                    WHEN 'DocDate'             THEN S.[DocDate]
                                    WHEN 'CustDueDate'         THEN S.[Cust Due Date]
                                    WHEN 'OriginalRequestDate' THEN S.[Original Request Date]
                                    WHEN 'PromiseDate'         THEN S.[PromiseDate]
                                    ELSE                            S.[RequiredDate]
                                END
                FROM #TB_FINAL_PROC_ORDENES_DEMAND AS S

            -----------UPDATE DE DATOS NECESARIOS PARA PLANIFICACION DE DESPACHO DE PRENDAS
			-----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #TB_FINAL_PROC_ORDENES_DEMAND)
			DROP TABLE IF EXISTS #TB_MOS_ORDENES_DEMAND_BY_SIZE        ---Tabla base de demanda por talla (detalle por Size)
			DROP TABLE IF EXISTS #TB_MOS_ORDENES_DEMAND_PIVOT          ---Tabla de demanda pivot por tallas en columnas
			DROP TABLE IF EXISTS #TB_GROUP_MOS_ORDENES_DEMAND          ---Tabla auxiliar para agrupacion de MOs de demanda
			DROP TABLE IF EXISTS #TB_GROUP_ITEMDETAILID_ORDENES_DEMAND ---Tabla auxiliar para agrupacion de ItemDetailID de demanda
            DROP TABLE IF EXISTS #TB_LOOKUP_MO_SIZE_WITHDRAW         ---Lookup de retiro de blanks por MO y talla
			DROP TABLE IF EXISTS #TB_LOOKUP_L2                         ---Tabla lookup de datos L2 por ItemDetailID (SKU/Logo/Status/CustPO)
			DROP TABLE IF EXISTS #TB_LOOKUP_BOX                        ---Tabla lookup de primer FirstBlankBoxNumber por ManufactureID
			DROP TABLE IF EXISTS #TB_LOOKUP_SALESSTYLE                 ---Tabla lookup de equivalencia Style Embroidery -> Style Blank
			DROP TABLE IF EXISTS #TB_LOOKUP_ORD                        ---Tabla lookup de export order (Color/MachineGroup/Relabel/DocDate)
			DROP TABLE IF EXISTS #TB_LOOKUP_ETA                        ---Tabla lookup de tipo de aplicacion por LogoStyle
            DROP TABLE IF EXISTS #TB_LOOKUP_OTLO                       ---Tabla lookup de tipo de orden por LogoStyle
			DROP TABLE IF EXISTS #TB_LOOKUP_OS                         ---Tabla lookup de ordenes suspendidas por ManufactureID
			-----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #TB_FINAL_PROC_ORDENES_DEMAND)

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 23,
                [StepCode] = 'ORDERS',
                [StepNameUser] = 'Preparando ordenes',
                [MessageUser] = 'Estamos preparando y validando las ordenes para despacho.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - FIN    PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

			-- SELECT * FROM #TB_FINAL_PROC_ORDENES_DEMAND
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA ORDENES ACTIVAS PARA DESPACHO-----------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA INVENTARIO ACTIVO-----------------------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 24,
                [StepCode] = 'INV_WH',
                [StepNameUser] = 'Calculando inventario activo',
                [MessageUser] = 'Estamos calculando el inventario activo en warehouse.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - INICIO PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 25,
                [StepCode] = 'INV_WH',
                [StepNameUser] = 'Calculando inventario activo',
                [MessageUser] = 'Estamos calculando el inventario activo en warehouse.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA BASE'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 26,
                [StepCode] = 'INV_WH',
                [StepNameUser] = 'Calculando inventario activo',
                [MessageUser] = 'Estamos calculando el inventario activo en warehouse.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA TB_INV_GROUP_MO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

			SELECT DISTINCT [MO_ID] = B.[ManufactureID]
			INTO #TB_INV_GROUP_MO
			FROM #TB_INV_WAREHOUSE_BASE AS B

			PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA TB_INV_GROUP_STYLE')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 27,
                [StepCode] = 'INV_WH',
                [StepNameUser] = 'Calculando inventario activo',
                [MessageUser] = 'Estamos calculando el inventario activo en warehouse.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA TB_INV_GROUP_STYLE'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

			SELECT DISTINCT [StyleID] = B.[StyleID]
			INTO #TB_INV_GROUP_STYLE
			FROM #TB_INV_WAREHOUSE_BASE AS B

			PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA TB_INV_LOOKUP_VENDOR')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 28,
                [StepCode] = 'INV_WH',
                [StepNameUser] = 'Calculando inventario activo',
                [MessageUser] = 'Estamos calculando el inventario activo en warehouse.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA TB_INV_LOOKUP_VENDOR'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 29,
                [StepCode] = 'INV_WH',
                [StepNameUser] = 'Calculando inventario activo',
                [MessageUser] = 'Estamos calculando el inventario activo en warehouse.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA TB_INV_LOOKUP_TAG'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 30,
                [StepCode] = 'INV_WH',
                [StepNameUser] = 'Calculando inventario activo',
                [MessageUser] = 'Estamos calculando el inventario activo en warehouse.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA TB_INV_LOOKUP_BOM'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 31,
                [StepCode] = 'INV_WH',
                [StepNameUser] = 'Calculando inventario activo',
                [MessageUser] = 'Estamos calculando el inventario activo en warehouse.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. UPDATE DE LOOKUPS'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 32,
                [StepCode] = 'INV_WH',
                [StepNameUser] = 'Calculando inventario activo',
                [MessageUser] = 'Estamos calculando el inventario activo en warehouse.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE. TABLA FINAL TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
                ,[OriginalMake]          = SUM(B.[Quantity])
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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 33,
                [StepCode] = 'INV_WH',
                [StepNameUser] = 'Calculando inventario activo',
                [MessageUser] = 'Estamos calculando el inventario activo en warehouse.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - FIN    PROCEDIMIENTO PARA INVENTARIO ACTIVO WAREHOUSE'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            -- SELECT * FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA INVENTARIO ACTIVO-----------------------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA INVENTARIO EN MOS EN WIP---------------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO PROCEDIMIENTO PARA INVENTARIO EN MOS EN WIP')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 34,
                [StepCode] = 'INV_MOS_WIP',
                [StepNameUser] = 'Calculando inventario en WIP',
                [MessageUser] = 'Estamos calculando inventario asociado a MOs en proceso.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - INICIO PROCEDIMIENTO PARA INVENTARIO EN MOS EN WIP'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            
            ----Explicacion del procedimiento para inventario en mos en wip
            -------------------         Que hace el bloque
            ------------------- Construye la base de inventario de MOS en WIP para el consolidado final.
            ------------------- Identifica MOs vigentes en Forecast, Released, Cutting y Preproduction.
            ------------------- Para Cutting/Preproduction solo toma MOs sin BundleCreateDate para evitar duplicados ya cerrados.
            ------------------- Arma #TB_DATA_MOS_INVENTORY_RFCB con datos de MO, orden, estilo, color, talla y costo.
            ------------------- Mantiene #TB_DATA_MOS_INVENTORY_RFCB y limpia tablas temporales intermedias al cierre.
            -------------------     Filtros utilizados
            -------------------         StatusID IN (20,40,51,53)
            -------------------             20 = Forecast
            -------------------             40 = Released
            -------------------             51 = Cutting
            -------------------             53 = Preproduction
            -------------------         QuantityOrdered > 0
            -------------------         Seasons en ('BLANK RO','BLANK FG')
			
			PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO EN MOS EN WIP. TABLA ROS/MOS EN RELEASED, FORECAST, CORTE TELA')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 35,
                [StepCode] = 'INV_MOS_WIP',
                [StepNameUser] = 'Calculando inventario en WIP',
                [MessageUser] = 'Estamos calculando inventario asociado a MOs en proceso.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO EN MOS EN WIP. TABLA ROS/MOS EN RELEASED, FORECAST, CORTE TELA'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 36,
                [StepCode] = 'INV_MOS_WIP',
                [StepNameUser] = 'Calculando inventario en WIP',
                [MessageUser] = 'Estamos calculando inventario asociado a MOs en proceso.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - FIN    PROCEDIMIENTO PARA INVENTARIO EN MOS EN WIP'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 37,
                [StepCode] = 'INV_BUNDLES_WIP',
                [StepNameUser] = 'Procesando bultos en WIP',
                [MessageUser] = 'Estamos procesando el inventario de bultos en WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - INICIO PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            

        
        
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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 38,
                [StepCode] = 'INV_BUNDLES_WIP',
                [StepNameUser] = 'Procesando bultos en WIP',
                [MessageUser] = 'Estamos procesando el inventario de bultos en WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP. TYPEQUERY 1'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

        			
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
                                                        FROM [LCA].[dbo].WorkFlows WF		WITH (NOLOCK)
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
                    LEFT JOIN   [LCA].[dbo].PackedBoxes 		AS pb		WITH(NOLOCK) 	ON pb.PackedBoxID 			= BND.PackedBoxID	        AND pb.StatusID IN(25,27,75)
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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 38,
                [StepCode] = 'INV_BUNDLES_WIP',
                [StepNameUser] = 'Procesando bultos en WIP',
                [MessageUser] = 'Estamos procesando el inventario de bultos en WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP. UPDATE NEXTTASK'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

      
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
                							         
                										SELECT *
                                                                FROM(
                                                                    SELECT
                                                                         [BundleID]
                                                                        ,[R]                            = ROW_NUMBER() OVER(PARTITION BY EA.[BundleID] ORDER BY EA.[ChangeDate] DESC,EA.[MaxChangeDateID] DESC,EA.[MaxSequence] DESC)
                                                                        ,[LastTransactionWithOutDamage]
                                                                    FROM(
                                                                        SELECT
                                                                             [BundleID]                      = BND.[BundleID]
                                                                            ,[LastTransactionWithOutDamage]  = MAX(WT.[WorkTransactionID])
                                                                            ,[Quantity]                      = SUM(WT.[Quantity])
                                                                            ,[ChangeDate]                    = MAX(CH.[ChangeDate])
                                                                            ,[TaskID]                        = WT.[TaskID]
                                                                            ,[MaxChangeDateID]               = MAX(CH.[ChangeLogID])
                                                                            ,[MaxSequence]                   = WTS.[Sequence]
                                                                        FROM #TB_Data_For_Bundles AS FIL
                                                                        INNER JOIN [LCA].[dbo].[Bundles]            AS BND  WITH(NOLOCK) ON FIL.[BundleID]      = BND.[BundleID]
                                                                        INNER JOIN [LCA].[dbo].[ManufactureOrders]  AS MO   WITH(NOLOCK) ON BND.[ManufactureID] = MO.[ManufactureID] AND MO.[StatusID] < 90
                                                                        INNER JOIN [LCA].[dbo].[WorkTransactions]    AS WT   WITH(NOLOCK) ON BND.[BundleID]      = WT.[BundleID] AND WT.[DamageID] IS NULL AND WT.[Quantity] <> 0
                                                                        INNER JOIN [LCA].[dbo].[ChangeLog]           AS CH   WITH(NOLOCK) ON CH.[ChangeLogID]    = WT.[ChangeLogID]
                                                                        LEFT JOIN  [LCA].[dbo].[WorkTasks]           AS WTS  WITH(NOLOCK) ON WT.[TaskID]         = WTS.[TaskID]
                                                                        GROUP BY BND.[BundleID],WT.[TaskID],WTS.[Sequence]
                                                                        HAVING SUM(WT.[Quantity]) > 0
                                                                    ) AS EA
                                                                ) AS TBW
                                                                WHERE TBW.[R] = 1
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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 39,
                [StepCode] = 'INV_BUNDLES_WIP',
                [StepNameUser] = 'Procesando bultos en WIP',
                [MessageUser] = 'Estamos procesando el inventario de bultos en WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP. UPDATE NextTaskName'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

        
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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 39,
                [StepCode] = 'INV_BUNDLES_WIP',
                [StepNameUser] = 'Procesando bultos en WIP',
                [MessageUser] = 'Estamos procesando el inventario de bultos en WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP. UPDATE MO RELEASED'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

        		
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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 40,
                [StepCode] = 'INV_BUNDLES_WIP',
                [StepNameUser] = 'Procesando bultos en WIP',
                [MessageUser] = 'Estamos procesando el inventario de bultos en WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP. UPDATE MO COMPLETE'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

        
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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 41,
                [StepCode] = 'INV_BUNDLES_WIP',
                [StepNameUser] = 'Procesando bultos en WIP',
                [MessageUser] = 'Estamos procesando el inventario de bultos en WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO EN MOS EN WIP. INSERT BULTOS ACTIVOS A TB_DATA_MOS_INVENTORY_RFCB'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;


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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 42,
                [StepCode] = 'INV_BUNDLES_WIP',
                [StepNameUser] = 'Procesando bultos en WIP',
                [MessageUser] = 'Estamos procesando el inventario de bultos en WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - FIN    PROCEDIMIENTO PARA INVENTARIO EN BULTOS WIP'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            ------------------- Consolida inventario de bodega + inventario MOS WIP en #TB_FINAL_PROC_INVENTARIO_ACTIVO.

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 43,
                [StepCode] = 'INV_CONSOLIDATED',
                [StepNameUser] = 'Consolidando inventario',
                [MessageUser] = 'Estamos consolidando inventario activo y WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - INICIO PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            

            DROP TABLE IF EXISTS #TB_INV_WIP_GROUP_MO
            DROP TABLE IF EXISTS #TB_INV_WIP_GROUP_STYLE
            DROP TABLE IF EXISTS #TB_INV_WIP_LOOKUP_VENDOR
            DROP TABLE IF EXISTS #TB_INV_WIP_LOOKUP_TAG
            DROP TABLE IF EXISTS #TB_INV_WIP_LOOKUP_BOM
            DROP TABLE IF EXISTS #TB_FINAL_PROC_INVENTARIO_MOS_WIP
            DROP TABLE IF EXISTS #TB_FINAL_PROC_INVENTARIO_ACTIVO

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. LIMPIEZA TABLAS TEMPORALES')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 44,
                [StepCode] = 'INV_CONSOLIDATED',
                [StepNameUser] = 'Consolidando inventario',
                [MessageUser] = 'Estamos consolidando inventario activo y WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. LIMPIEZA TABLAS TEMPORALES'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_INV_WIP_GROUP_MO')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 44,
                [StepCode] = 'INV_CONSOLIDATED',
                [StepNameUser] = 'Consolidando inventario',
                [MessageUser] = 'Estamos consolidando inventario activo y WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_INV_WIP_GROUP_MO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            SELECT
                 [MO_ID] = S.[MO_ID]
            INTO #TB_INV_WIP_GROUP_MO
            FROM #TB_DATA_MOS_INVENTORY_RFCB AS S
            GROUP BY S.[MO_ID]

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_INV_WIP_GROUP_STYLE')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 45,
                [StepCode] = 'INV_CONSOLIDATED',
                [StepNameUser] = 'Consolidando inventario',
                [MessageUser] = 'Estamos consolidando inventario activo y WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_INV_WIP_GROUP_STYLE'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            SELECT
                 [StyleID] = S.[StyleID]
            INTO #TB_INV_WIP_GROUP_STYLE
            FROM #TB_DATA_MOS_INVENTORY_RFCB AS S
            GROUP BY S.[StyleID]

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_INV_WIP_LOOKUP_VENDOR')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 45,
                [StepCode] = 'INV_CONSOLIDATED',
                [StepNameUser] = 'Consolidando inventario',
                [MessageUser] = 'Estamos consolidando inventario activo y WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_INV_WIP_LOOKUP_VENDOR'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 46,
                [StepCode] = 'INV_CONSOLIDATED',
                [StepNameUser] = 'Consolidando inventario',
                [MessageUser] = 'Estamos consolidando inventario activo y WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_INV_WIP_LOOKUP_TAG'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 46,
                [StepCode] = 'INV_CONSOLIDATED',
                [StepNameUser] = 'Consolidando inventario',
                [MessageUser] = 'Estamos consolidando inventario activo y WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_INV_WIP_LOOKUP_BOM'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 46,
                [StepCode] = 'INV_CONSOLIDATED',
                [StepNameUser] = 'Consolidando inventario',
                [MessageUser] = 'Estamos consolidando inventario activo y WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA TB_FINAL_PROC_INVENTARIO_MOS_WIP'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
                ,[OriginalMake]          = SUM(ISNULL(S.[OriginalMake], ISNULL(S.[MAKE1],0)))
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
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 47,
                [StepCode] = 'INV_CONSOLIDATED',
                [StepNameUser] = 'Consolidando inventario',
                [MessageUser] = 'Estamos consolidando inventario activo y WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. TABLA BASE TB_FINAL_PROC_INVENTARIO_ACTIVO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
                ,[OriginalMake]
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
                ,[CountryOfOrigin]  = CAST(NULL AS VARCHAR(200))
            INTO #TB_FINAL_PROC_INVENTARIO_ACTIVO
            FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. INSERT INVENTARIO WAREHOUSE')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 47,
                [StepCode] = 'INV_CONSOLIDATED',
                [StepNameUser] = 'Consolidando inventario',
                [MessageUser] = 'Estamos consolidando inventario activo y WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. INSERT INVENTARIO WAREHOUSE'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
                ,[OriginalMake]
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
                ,[CountryOfOrigin]  = CAST(NULL AS VARCHAR(200))
            FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO_WAREHOUSE

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. INSERT INVENTARIO MOS WIP')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 47,
                [StepCode] = 'INV_CONSOLIDATED',
                [StepNameUser] = 'Consolidando inventario',
                [MessageUser] = 'Estamos consolidando inventario activo y WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. INSERT INVENTARIO MOS WIP'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
                ,[OriginalMake]
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
                ,[CountryOfOrigin]  = CAST(NULL AS VARCHAR(200))
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

            -- UPDATE CountryOfOrigin: lookup filtrado por MO_IDs presentes en inventario activo
            DROP TABLE IF EXISTS #TB_LOOKUP_COUNTRY_OF_ORIGIN
            SELECT [ManufactureID], [CountryOfOrigin]
            INTO #TB_LOOKUP_COUNTRY_OF_ORIGIN
            FROM (
                SELECT ManufactureID, CountryOfOrigin,
                     ROW_NUMBER() OVER (PARTITION BY ManufactureID, Category ORDER BY ManufactureID, Category, Consumption DESC) AS ncuenta
                FROM appslca.dbo.TB_MO_PartNumber_IM WITH (NOLOCK)
                WHERE Category IN ('Fabric','Contracts')
                  AND ManufactureID IN (SELECT DISTINCT [MO_ID] FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO WHERE [MO_ID] IS NOT NULL)
            ) ABC_XYZ WHERE ncuenta = 1

            UPDATE ACTIVO
            SET [CountryOfOrigin] = LK.[CountryOfOrigin]
            FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO AS ACTIVO
            INNER JOIN #TB_LOOKUP_COUNTRY_OF_ORIGIN AS LK
                ON LK.[ManufactureID] = ACTIVO.[MO_ID]

            DROP TABLE IF EXISTS #TB_LOOKUP_COUNTRY_OF_ORIGIN

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. LIMPIEZA INTERMEDIA')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 47,
                [StepCode] = 'INV_CONSOLIDATED',
                [StepNameUser] = 'Consolidando inventario',
                [MessageUser] = 'Estamos consolidando inventario activo y WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO. LIMPIEZA INTERMEDIA'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            -----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #TB_FINAL_PROC_INVENTARIO_MOS_WIP Y #TB_FINAL_PROC_INVENTARIO_ACTIVO)
                DROP TABLE IF EXISTS #TB_INV_WIP_GROUP_MO
                DROP TABLE IF EXISTS #TB_INV_WIP_GROUP_STYLE
                DROP TABLE IF EXISTS #TB_INV_WIP_LOOKUP_VENDOR
                DROP TABLE IF EXISTS #TB_INV_WIP_LOOKUP_TAG
                DROP TABLE IF EXISTS #TB_INV_WIP_LOOKUP_BOM
            -----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #TB_FINAL_PROC_INVENTARIO_MOS_WIP Y #TB_FINAL_PROC_INVENTARIO_ACTIVO)

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 47,
                [StepCode] = 'INV_CONSOLIDATED',
                [StepNameUser] = 'Consolidando inventario',
                [MessageUser] = 'Estamos consolidando inventario activo y WIP.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - FIN    PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA INVENTARIO ACTIVO MOS WIP Y CONSOLIDADO----------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        

            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP---------------------------------------------------------------------------------------------------------------
            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----Explicacion del procedimiento para despacho desde inventario wip
            -------------------         Objetivo del bloque
            ------------------- Asignar inventario activo (warehouse + MOS WIP consolidado) contra demanda de ordenes usando criterio FIFO.
            ------------------- Construir demanda por talla e inventario por talla para poder comparar requerimiento vs disponibilidad.
            ------------------- Seleccionar grupo de inventario por orden (vendor/typequery) que cubra tallas completas cuando aplica.
            ------------------- Ejecutar asignacion secuencial por prioridad y consolidar ordenes despachadas / no despachadas.
            ------------------- Aplicar validacion estricta y fallback mixed para rescatar ordenes con combinacion de vendors.
            ------------------- Aplicar regla final de porcentaje minimo por CustomerOrder antes de publicar resultados finales.
            ------------------- Salidas finales del bloque:
            -------------------   1) #DispatchOrdersFromInventoryWIP (detalle asignado por talla/caja)
            -------------------   2) #DispatchOrdersFromInventoryWIP_OrdersDispatched (resumen ordenes despachadas)
            -------------------   3) #DispatchOrdersFromInventoryWIP_OrdersNotDispatched (ordenes no despachadas con motivo)
            -------------------         Reglas de prioridad
            ------------------- Prioridad ordenes: Style, Color, ordenEmb, RequiredDate, DocDate, OrderID.
            ------------------- Prioridad inventario: TypeQuery, OrderWIP, Style, Color, PackDate, BoxNumber.
            -------------------         Trazabilidad (TRACE): como leer cada mensaje
            ------------------- DeltaMs = milisegundos consumidos desde el trace inmediatamente anterior.
            ------------------- TotalMs = milisegundos acumulados desde inicio del bloque despacho.
            ------------------- TRACE PASO 5 DISPONIBLE POR GRUPO/TALLA: volumen de grupos y disponibilidad agregada por talla.
            ------------------- TRACE PASO 6 PREVIO: tamano de insumos antes de calcular candidatos por orden.
            ------------------- TRACE PASO 6 POST CANDIDATOS: total de combinaciones orden-grupo que pasan reglas de cobertura.
            ------------------- TRACE PASO 6/6A GRUPO POR ORDEN: candidatos vs grupo definitivo seleccionado por orden.
            ------------------- TRACE PASO 7 ACUMULADO DEMANDA: filas de demanda secuenciada por orden/talla para asignacion.
            ------------------- TRACE PASO 8 ACUMULADO INVENTARIO: filas de inventario secuenciado por grupo/talla para asignacion.
            ------------------- TRACE PASO 9 ASIGNACION FIFO: filas asignadas y cantidad total asignada en la corrida principal.
            ------------------- TRACE PASO 10 MODO ESTRICTO: ordenes que cumplen cobertura completa y filas vigentes tras filtro estricto.
            ------------------- TRACE PASO 10A FALLBACK MIXED: remanente, pendientes y resultado del fallback style/color vendor mixed.
            ------------------- TRACE PASO 11/12 SALIDAS DESPACHADAS: volumen final de detalle y resumen de ordenes despachadas.
            ------------------- TRACE PASO 13 NO DESPACHADAS: total de ordenes catalogadas como no despachadas con razon.
            ------------------- TRACE PASO 14 CUSTOMER ORDER %: efecto del umbral de CustomerOrder sobre despachadas/no despachadas.
            ------------------- TRACE FIN DESPACHO (CONSOLIDADO): snapshot final de las 3 tablas de salida del bloque.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 48,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Iniciando motor de despacho FIFO.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - INICIO PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            
            -- Variables de trace:
            -- @TraceStartDispatch: tiempo base del bloque.
            -- @TracePrevDispatch/@TraceNowDispatch: ventana para medir DeltaMs entre pasos.
            -- @TraceCountA..D y @TraceQtyAssigned: contadores de apoyo para reportar volumen por etapa.
            DECLARE @TraceStartDispatch DATETIME2(3) = SYSDATETIME()
            DECLARE @TracePrevDispatch  DATETIME2(3) = @TraceStartDispatch
            DECLARE @TraceNowDispatch   DATETIME2(3)
            DECLARE @TraceCountA BIGINT = 0
            DECLARE @TraceCountB BIGINT = 0
            DECLARE @TraceCountC BIGINT = 0
            DECLARE @TraceCountD BIGINT = 0
            DECLARE @TraceQtyAssigned VARCHAR(30) = '0'

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
            DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_OK_STRICT
            DROP TABLE IF EXISTS #TB_DISPATCH_INV_REMAIN
            DROP TABLE IF EXISTS #TB_DISPATCH_ORD_SIZE_PENDING
            DROP TABLE IF EXISTS #TB_DISPATCH_ORD_REQ_SEQ_MIX
            DROP TABLE IF EXISTS #TB_DISPATCH_INV_SEQ_MIX
            DROP TABLE IF EXISTS #TB_DISPATCH_ALLOC_RAW_MIX
            DROP TABLE IF EXISTS #TB_DISPATCH_ALLOC_SIZE_MIX
            DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_OK_MIX
            DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_MIXED_FLAG
            DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_ALLOC_SUMMARY
            DROP TABLE IF EXISTS #DispatchOrdersFromInventoryWIP
            DROP TABLE IF EXISTS #DispatchOrdersFromInventoryWIP_OrdersDispatched
            DROP TABLE IF EXISTS #DispatchOrdersFromInventoryWIP_OrdersNotDispatched
            DROP TABLE IF EXISTS #TB_RESERVE_INV_WORKING

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. LIMPIEZA TABLAS TEMPORALES')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 49,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Limpiando tablas temporales de despacho.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. LIMPIEZA TABLAS TEMPORALES'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;


            -- 1) Base de ordenes con prioridad FIFO.
            --    Se construye OrderRow para preservar el orden de despacho.
            -- Tabla temporal: #TB_DISPATCH_ORD_BASE
            -- Snapshot base de ordenes con atributos comerciales, flags y demanda por talla.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 1 BASE ORDENES FIFO')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 50,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Construyendo base de ordenes FIFO.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 1 BASE ORDENES FIFO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            SELECT
                [OrderRow]      = ROW_NUMBER() OVER (
                                        ORDER BY S.[Style] ASC, S.[Color] ASC, S.[ordenEmb] ASC, S.[RunDate] ASC, S.[DocDate] ASC, S.[OrderID] ASC
                                    )
                ,[Style]         = CAST(S.[Style] AS VARCHAR(200))
                ,[Color]         = CAST(S.[Color] AS VARCHAR(200))
                ,[RequiredDate]  = S.[RequiredDate]
                ,[ordenEmb]      = CAST(S.[ordenEmb] AS VARCHAR(50))
                ,[DocDate]               = S.[DocDate]
                ,[Cust Due Date]         = S.[Cust Due Date]
                ,[Original Request Date] = S.[Original Request Date]
                ,[OrderID]       = S.[OrderID]
                ,[PONumber]      = S.[PONumber]
                ,[CustomerOrder] = S.[CustomerOrder]
                ,[PWModulo]      = CAST(ISNULL(S.[PWModulo],'') AS VARCHAR(100))
                ,[FirstBlanksBoxNumber] = CAST(ISNULL(S.[FirstBlanksBoxNumber],'') AS VARCHAR(50))
                ,[MO]            = S.[MO]
                ,[MO_ID]         = S.[MO_ID]
                ,[StatusOrder]   = CAST(ISNULL(S.[StatusOrder],'') AS VARCHAR(100))
                ,[SKUStatus]     = CAST(ISNULL(S.[SKUStatus],'') AS VARCHAR(100))
                ,[Status]        = CAST(ISNULL(S.[Status],'') AS VARCHAR(100))
                ,[Season]        = CAST(ISNULL(S.[Season],'') AS VARCHAR(100))
                ,[OrderTypeDescription] = CAST(ISNULL(S.[OrderTypeDescription],'') AS VARCHAR(60))
                ,[ApplicationOrder]     = CAST(ISNULL(S.[ApplicationOrder],'') AS VARCHAR(50))
                ,[MakeL2]        = CAST(ISNULL(S.[MakeL2],0) AS FLOAT)
                ,[Make]          = CAST(ISNULL(S.[Make],0) AS FLOAT)
                ,[QtyWithdraw]   = CAST(ISNULL(S.[QtyWithdraw],0) AS FLOAT)
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
                ,[Validate_Color] = CAST(ISNULL(S.[Validate_Color],'') AS VARCHAR(100))
                ,[TypeEmbroidery] = S.[TypeEmbroidery]
                ,[Technique]      = S.[Technique]
                ,[APS]            = S.[APS]
                ,[Type]           = S.[Type]
                ,[ScreenPrint]    = S.[ScreenPrint]
                ,[ScreenPrintAfter]  = S.[ScreenPrintAfter]
                ,[ScreenPrintBefore] = S.[ScreenPrintBefore]
                ,[Embroidery]        = S.[Embroidery]
                ,[SublimationBefore] = S.[SublimationBefore]
                ,[SublimationAfter]  = S.[SublimationAfter]
                ,[HDP]               = S.[HDP]
                ,[Blanks]            = S.[Blanks]
                ,[EmbHWApplique]     = S.[EmbHWApplique]
                ,[EmbHWDirect]       = S.[EmbHWDirect]
                ,[EmbHWPatch]        = S.[EmbHWPatch]
                ,[EmbHWHDP]          = S.[EmbHWHDP]
                ,[EmbAppDirect]      = S.[EmbAppDirect]
                ,[EmbAppLBA]         = S.[EmbAppLBA]
                ,[PriceCode]         = S.[PriceCode]
                ,[PromiseDate]       = S.[PromiseDate]
                ,[InventoryDate]     = S.[InventoryDate]
                ,[RunDate]           = S.[RunDate]
            INTO #TB_DISPATCH_ORD_BASE
            FROM #TB_FINAL_PROC_ORDENES_DEMAND AS S


            -- 2) Demanda por talla (unpivot con CROSS APPLY VALUES).
            --    Solo tallas con demanda > 0 y ordenes no bloqueadas.
            -- Tabla temporal: #TB_DISPATCH_ORD_SIZE
            -- Demanda normalizada por OrderRow-Style-Color-Size para el motor de asignacion.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 2 DEMANDA POR TALLA')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 51,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Calculando demanda por talla.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 2 DEMANDA POR TALLA'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
              AND O.[SuspendOrd] = 0

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 2A INDEX DEMANDA')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 52,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Indexando demanda por talla.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 2A INDEX DEMANDA'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            CREATE CLUSTERED INDEX IX_TB_DISPATCH_ORD_SIZE_CI
                ON #TB_DISPATCH_ORD_SIZE([OrderRow],[Size])

            CREATE NONCLUSTERED INDEX IX_TB_DISPATCH_ORD_SIZE_SC
                ON #TB_DISPATCH_ORD_SIZE([Style],[Color],[Size],[OrderRow])
                INCLUDE([QtyRequired])

            -- 3) Inventario base por talla.
            --    Es la bolsa de disponibilidad que se consumira durante la asignacion.
            -- Tabla temporal: #TB_DISPATCH_INV_POOL
            -- Pool de inventario positivo por talla con trazabilidad de caja/MO y vendor.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 3 INVENTARIO BASE')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 53,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Construyendo pool de inventario disponible.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 3 INVENTARIO BASE'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
                ,[CSVBoxNumber]          = CAST(ISNULL(S.[CSVBoxNumber],'') AS VARCHAR(100))
                ,[PPFG]                  = CAST(ISNULL(S.[PPFG],'') AS VARCHAR(100))
                ,[MO]                    = CAST(ISNULL(S.[MO],'') AS VARCHAR(120))
                ,[MO_ID]                 = S.[MO_ID]
                ,[Size]                  = CAST(ISNULL(S.[Size],'') AS VARCHAR(20))
                ,[QtyAvailable]          = CAST(ISNULL(S.[QTY],0) AS FLOAT)
                ,[BIN]                   = S.[BIN]
                ,[PNHangtag]             = S.[PNHangtag]
                ,[CountryOfOrigin]       = S.[CountryOfOrigin]
            INTO #TB_DISPATCH_INV_POOL
            FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO AS S
            WHERE ISNULL(S.[QTY],0) > 0

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 3A INDEX INVENTARIO')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 54,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Indexando inventario disponible por talla.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 3A INDEX INVENTARIO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            CREATE CLUSTERED INDEX IX_TB_DISPATCH_INV_POOL_CI
                ON #TB_DISPATCH_INV_POOL([InvPoolRow])

            CREATE NONCLUSTERED INDEX IX_TB_DISPATCH_INV_POOL
                ON #TB_DISPATCH_INV_POOL([Style],[Color],[OrigFabricVendorName],[TypeQuery],[Size],[OrderWIP],[PackDate],[BoxNumber],[Season],[InvPoolRow])
                INCLUDE([QtyAvailable],[MO],[MO_ID])

            -- Pre-creacion de tablas compartidas entre ambos modos (IF/ELSE).
            -- Se crean antes del IF/ELSE para evitar conflicto de compilacion de SQL Server
            -- cuando ambas ramas crean el mismo nombre de tabla temporal.
            DROP TABLE IF EXISTS #TB_DISPATCH_ALLOC_RAW
            CREATE TABLE #TB_DISPATCH_ALLOC_RAW (
                 [OrderRow]              INT
                ,[Style]                 VARCHAR(200)
                ,[Color]                 VARCHAR(200)
                ,[RequiredDate]          DATE
                ,[ordenEmb]              VARCHAR(50)
                ,[DocDate]               DATE
                ,[Cust Due Date]         DATE
                ,[Original Request Date] DATE
                ,[OrderID]               VARCHAR(200)
                ,[PONumber]              VARCHAR(200)
                ,[CustomerOrder]         VARCHAR(200)
                ,[PWModulo]              VARCHAR(100)
                ,[QtyWithdraw]           FLOAT
                ,[FirstBlanksBoxNumber]  VARCHAR(50)
                ,[MO]                    VARCHAR(200)
                ,[MO_ID]                 INT
                ,[StatusOrder]           VARCHAR(100)
                ,[SKUStatus]             VARCHAR(100)
                ,[Status]                VARCHAR(100)
                ,[Season]                VARCHAR(100)
                ,[OrderTypeDescription]  VARCHAR(60)
                ,[ApplicationOrder]      VARCHAR(50)
                ,[TypeQuery]             INT
                ,[OrigFabricVendorName]  VARCHAR(500)
                ,[Size]                  VARCHAR(50)
                ,[QtyRequired]           FLOAT
                ,[QtyAssigned]           FLOAT
                ,[InvPoolRow]            INT
                ,[OrderWIP]              VARCHAR(200)
                ,[Inv_Pack_Date]         DATE
                ,[BoxNumber]             VARCHAR(200)
                ,[CSVBoxNumber]          VARCHAR(200)
                ,[PPFG]                  VARCHAR(200)
                ,[InvMO]                 VARCHAR(200)
                ,[InvMO_ID]              INT
                ,[BIN]                   VARCHAR(200)
                ,[PNHangtag]             VARCHAR(200)
                ,[CountryOfOrigin]       VARCHAR(200)
                ,[inv_Style]             VARCHAR(200)
                ,[inv_Color]             VARCHAR(200)
                ,[inv_Season]            VARCHAR(200)
                ,[PromiseDate]           DATE
                ,[InventoryDate]         DATE
                ,[RunDate]               DATE
            )
            DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_OK
            CREATE TABLE #TB_DISPATCH_ORDER_OK ([OrderRow] INT)
            DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_GROUP
            CREATE TABLE #TB_DISPATCH_ORDER_GROUP (
                 [OrderRow]              INT
                ,[Style]                 VARCHAR(200)
                ,[Color]                 VARCHAR(200)
                ,[OrigFabricVendorName]  VARCHAR(500)
                ,[TypeQuery]             INT
            )
            DROP TABLE IF EXISTS #TB_DISPATCH_ALLOC_RAW_MIX
            CREATE TABLE #TB_DISPATCH_ALLOC_RAW_MIX (
                 [OrderRow]              INT
                ,[Style]                 VARCHAR(200)
                ,[Color]                 VARCHAR(200)
                ,[RequiredDate]          DATE
                ,[ordenEmb]              VARCHAR(50)
                ,[DocDate]               DATE
                ,[Cust Due Date]         DATE
                ,[Original Request Date] DATE
                ,[OrderID]               VARCHAR(200)
                ,[PONumber]              VARCHAR(200)
                ,[CustomerOrder]         VARCHAR(200)
                ,[PWModulo]              VARCHAR(100)
                ,[QtyWithdraw]           FLOAT
                ,[FirstBlanksBoxNumber]  VARCHAR(50)
                ,[MO]                    VARCHAR(200)
                ,[MO_ID]                 INT
                ,[StatusOrder]           VARCHAR(100)
                ,[SKUStatus]             VARCHAR(100)
                ,[Status]                VARCHAR(100)
                ,[Season]                VARCHAR(100)
                ,[OrderTypeDescription]  VARCHAR(60)
                ,[ApplicationOrder]      VARCHAR(50)
                ,[TypeQuery]             INT
                ,[OrigFabricVendorName]  VARCHAR(500)
                ,[Size]                  VARCHAR(50)
                ,[QtyRequired]           FLOAT
                ,[QtyAssigned]           FLOAT
                ,[InvPoolRow]            INT
                ,[OrderWIP]              VARCHAR(200)
                ,[Inv_Pack_Date]         DATE
                ,[BoxNumber]             VARCHAR(200)
                ,[CSVBoxNumber]          VARCHAR(200)
                ,[PPFG]                  VARCHAR(200)
                ,[InvMO]                 VARCHAR(200)
                ,[InvMO_ID]              INT
                ,[BIN]                   VARCHAR(200)
                ,[PNHangtag]             VARCHAR(200)
                ,[CountryOfOrigin]       VARCHAR(200)
                ,[inv_Style]             VARCHAR(200)
                ,[inv_Color]             VARCHAR(200)
                ,[inv_Season]            VARCHAR(200)
                ,[PromiseDate]           DATE
                ,[InventoryDate]         DATE
                ,[RunDate]               DATE
            )

            IF @FlagBacklog = 0
            BEGIN -- inicio modo FIFO con grupos y vendor (flag=false)

            -- Tabla temporal: #TB_DISPATCH_GROUP_RANK_BASE
            -- Minimos por grupo (Style-Color-Vendor-TypeQuery) para ordenar prioridad de uso.
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
            -- Tabla temporal: #TB_DISPATCH_GROUP_RANK
            -- Ranking final por Style/Color para escoger grupo candidato de abastecimiento.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 4 RANKING GRUPOS')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 55,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Calculando ranking de grupos de abastecimiento.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 4 RANKING GRUPOS'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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

          
            -- Tabla temporal: #TB_DISPATCH_GROUP_SIZE_AVAIL
            -- Disponibilidad agregada por grupo y talla para validar cobertura completa.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 5 DISPONIBLE POR GRUPO/TALLA')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 56,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Validando disponibilidad por grupo y talla.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 5 DISPONIBLE POR GRUPO/TALLA'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

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
            SET @TraceNowDispatch = SYSDATETIME()
            SELECT
                @TraceCountA = COUNT_BIG(*)
            FROM #TB_DISPATCH_GROUP_SIZE_AVAIL
            SELECT
                @TraceCountB = COUNT_BIG(*)
            FROM #TB_DISPATCH_GROUP_RANK
            PRINT CONCAT(
                FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff')
                ,'         TRACE PASO 5 DISPONIBLE POR GRUPO/TALLA'
                ,' | DeltaMs=',DATEDIFF(MILLISECOND,@TracePrevDispatch,@TraceNowDispatch)
                ,' | TotalMs=',DATEDIFF(MILLISECOND,@TraceStartDispatch,@TraceNowDispatch)
                ,' | RowsGroupSizeAvail=',@TraceCountA
                ,' | GroupsRank=',@TraceCountB
            )
            SET @TracePrevDispatch = @TraceNowDispatch
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 57,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Procesando candidatos de despacho.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - TRACE PASO 5 DISPONIBLE POR GRUPO/TALLA'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;


            -- Grupo candidato por orden:
            -- solo pasa el grupo que cubre TODAS las tallas requeridas de la orden.
            -- Tabla temporal: #TB_DISPATCH_ORDER_GROUP_CAND
            -- Candidatos OrderRow-Grupo que cumplen cobertura total por talla.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 6 CANDIDATOS POR ORDEN')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 58,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Seleccionando candidatos por orden.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 6 CANDIDATOS POR ORDEN'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            SET @TraceNowDispatch = SYSDATETIME()
            SELECT
                @TraceCountA = COUNT_BIG(*)
            FROM #TB_DISPATCH_ORD_SIZE
            SELECT
                @TraceCountB = COUNT_BIG(*)
            FROM #TB_DISPATCH_GROUP_RANK
            SELECT
                @TraceCountC = COUNT_BIG(*)
            FROM #TB_DISPATCH_GROUP_SIZE_AVAIL
            PRINT CONCAT(
                FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff')
                ,'         TRACE PASO 6 PREVIO'
                ,' | DeltaMs=',DATEDIFF(MILLISECOND,@TracePrevDispatch,@TraceNowDispatch)
                ,' | TotalMs=',DATEDIFF(MILLISECOND,@TraceStartDispatch,@TraceNowDispatch)
                ,' | RowsOrdSize=',@TraceCountA
                ,' | RowsGroupRank=',@TraceCountB
                ,' | RowsGroupSizeAvail=',@TraceCountC
            )
            SET @TracePrevDispatch = @TraceNowDispatch
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
            
            SET @TraceNowDispatch = SYSDATETIME()
            SELECT
                @TraceCountA = COUNT_BIG(*)
            FROM #TB_DISPATCH_ORDER_GROUP_CAND
            PRINT CONCAT(
                FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff')
                ,'         TRACE PASO 6 POST CANDIDATOS'
                ,' | DeltaMs=',DATEDIFF(MILLISECOND,@TracePrevDispatch,@TraceNowDispatch)
                ,' | TotalMs=',DATEDIFF(MILLISECOND,@TraceStartDispatch,@TraceNowDispatch)
                ,' | RowsOrderGroupCand=',@TraceCountA
            )
            SET @TracePrevDispatch = @TraceNowDispatch


            -- Tabla temporal: #TB_DISPATCH_ORDER_GROUP
            -- Grupo definitivo por orden (1 fila por OrderRow, priorizado por GroupRank).
            INSERT INTO #TB_DISPATCH_ORDER_GROUP (
                [OrderRow],[Style],[Color],[OrigFabricVendorName],[TypeQuery]
            )
            SELECT
                 [OrderRow]
                ,[Style]
                ,[Color]
                ,[OrigFabricVendorName]
                ,[TypeQuery]
            FROM #TB_DISPATCH_ORDER_GROUP_CAND
            WHERE [Rnk] = 1

            -- Grupo definitivo (1 grupo por orden).
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 6A GRUPO DEFINITIVO')
            CREATE UNIQUE CLUSTERED INDEX IX_TB_DISPATCH_ORDER_GROUP
                ON #TB_DISPATCH_ORDER_GROUP([OrderRow])
            SET @TraceNowDispatch = SYSDATETIME()
            SELECT
                @TraceCountA = COUNT_BIG(*)
            FROM #TB_DISPATCH_ORDER_GROUP_CAND
            SELECT
                @TraceCountB = COUNT_BIG(*)
            FROM #TB_DISPATCH_ORDER_GROUP
            PRINT CONCAT(
                FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff')
                ,'         TRACE PASO 6/6A GRUPO POR ORDEN'
                ,' | DeltaMs=',DATEDIFF(MILLISECOND,@TracePrevDispatch,@TraceNowDispatch)
                ,' | TotalMs=',DATEDIFF(MILLISECOND,@TraceStartDispatch,@TraceNowDispatch)
                ,' | RowsOrderGroupCand=',@TraceCountA
                ,' | RowsOrderGroup=',@TraceCountB
            )
            SET @TracePrevDispatch = @TraceNowDispatch

            -- Demanda acumulada por talla dentro del grupo elegido.
            -- Tabla temporal: #TB_DISPATCH_ORD_REQ_SEQ
            -- Serie acumulada de demanda por talla para calcular traslape contra inventario.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 7 ACUMULADO DEMANDA')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 59,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Calculando acumulado de demanda por talla.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 7 ACUMULADO DEMANDA'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
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
            SET @TraceNowDispatch = SYSDATETIME()
            SELECT
                @TraceCountA = COUNT_BIG(*)
            FROM #TB_DISPATCH_ORD_REQ_SEQ
            PRINT CONCAT(
                FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff')
                ,'         TRACE PASO 7 ACUMULADO DEMANDA'
                ,' | DeltaMs=',DATEDIFF(MILLISECOND,@TracePrevDispatch,@TraceNowDispatch)
                ,' | TotalMs=',DATEDIFF(MILLISECOND,@TraceStartDispatch,@TraceNowDispatch)
                ,' | RowsOrdReqSeq=',@TraceCountA
            )
            SET @TracePrevDispatch = @TraceNowDispatch

            -- Inventario acumulado por talla en secuencia FIFO de cajas.
            -- Tabla temporal: #TB_DISPATCH_INV_SEQ
            -- Serie acumulada de inventario por talla segun prioridad FIFO del grupo elegido.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 8 ACUMULADO INVENTARIO')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 60,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Calculando acumulado de inventario FIFO.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 8 ACUMULADO INVENTARIO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            
            
            
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
            SET @TraceNowDispatch = SYSDATETIME()
            SELECT
                @TraceCountA = COUNT_BIG(*)
            FROM #TB_DISPATCH_INV_SEQ
            PRINT CONCAT(
                FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff')
                ,'         TRACE PASO 8 ACUMULADO INVENTARIO'
                ,' | DeltaMs=',DATEDIFF(MILLISECOND,@TracePrevDispatch,@TraceNowDispatch)
                ,' | TotalMs=',DATEDIFF(MILLISECOND,@TraceStartDispatch,@TraceNowDispatch)
                ,' | RowsInvSeq=',@TraceCountA
            )
            SET @TracePrevDispatch = @TraceNowDispatch

            -- Asignacion set-based por interseccion de rangos acumulados:
            -- QtyAssigned = overlap([CumReqPrev,CumReq], [CumInvPrev,CumInv]).
            -- Tabla temporal: #TB_DISPATCH_ALLOC_RAW
            -- Asignacion detallada por OrderRow-Size-Inventario (linea a linea).
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 9 ASIGNACION FIFO')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 61,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Ejecutando asignacion FIFO orden por orden.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 9 ASIGNACION FIFO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            INSERT INTO #TB_DISPATCH_ALLOC_RAW (
                 [OrderRow],[Style],[Color],[RequiredDate],[ordenEmb],[DocDate],[Cust Due Date],[Original Request Date],[OrderID],[PONumber]
                ,[CustomerOrder],[PWModulo],[QtyWithdraw],[FirstBlanksBoxNumber],[MO],[MO_ID]
                ,[StatusOrder],[SKUStatus],[Status],[Season],[OrderTypeDescription],[ApplicationOrder]
                ,[TypeQuery],[OrigFabricVendorName],[Size],[QtyRequired],[QtyAssigned]
                ,[InvPoolRow],[OrderWIP],[Inv_Pack_Date],[BoxNumber],[CSVBoxNumber],[PPFG]
                ,[InvMO],[InvMO_ID],[BIN],[PNHangtag],[CountryOfOrigin],[inv_Style],[inv_Color],[inv_Season]
                ,[PromiseDate],[InventoryDate],[RunDate]
            )
            SELECT
                 O.[OrderRow]
                ,O.[Style]
                ,O.[Color]
                ,OB.[RequiredDate]
                ,OB.[ordenEmb]
                ,OB.[DocDate]
                ,OB.[Cust Due Date]
                ,OB.[Original Request Date]
                ,OB.[OrderID]
                ,OB.[PONumber]
                ,OB.[CustomerOrder]
                ,OB.[PWModulo]
                ,OB.[QtyWithdraw]
                ,OB.[FirstBlanksBoxNumber]
                ,OB.[MO]
                ,OB.[MO_ID]
                ,OB.[StatusOrder]
                ,OB.[SKUStatus]
                ,OB.[Status]
                ,OB.[Season]
                ,OB.[OrderTypeDescription]
                ,OB.[ApplicationOrder]
                ,O.[TypeQuery]
                ,O.[OrigFabricVendorName]
                ,O.[Size]
                ,[QtyRequired] = O.[QtyRequired]
                ,[QtyAssigned] = CAST(X.[EndPoint] - X.[StartPoint] AS FLOAT)
                ,I.[InvPoolRow]
                ,I.[OrderWIP]
                ,I.[PackDate]
                ,I.[BoxNumber]
                ,I.[CSVBoxNumber]
                ,I.[PPFG]
                ,I.[MO]
                ,I.[MO_ID]
                ,I.[BIN]
                ,I.[PNHangtag]
                ,I.[CountryOfOrigin]
                ,I.[Style]
                ,I.[Color]
                ,I.[Season]
                ,OB.[PromiseDate]
                ,OB.[InventoryDate]
                ,OB.[RunDate]
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

            -- Tabla temporal: #TB_DISPATCH_ALLOC_SIZE
            -- Resumen de asignacion por OrderRow-Size para validar cobertura completa.
            SELECT
                 [OrderRow]
                ,[Size]
                ,[QtyRequired] = MAX([QtyRequired])
                ,[QtyAssigned] = SUM([QtyAssigned])
            INTO #TB_DISPATCH_ALLOC_SIZE
            FROM #TB_DISPATCH_ALLOC_RAW
            GROUP BY [OrderRow],[Size]
            SET @TraceNowDispatch = SYSDATETIME()
            SELECT
                @TraceCountA = COUNT_BIG(*)
            FROM #TB_DISPATCH_ALLOC_RAW
            SELECT
                @TraceCountB = COUNT_BIG(*)
            FROM #TB_DISPATCH_ALLOC_SIZE
            SELECT
                @TraceQtyAssigned = CAST(ISNULL(SUM([QtyAssigned]),0) AS VARCHAR(30))
            FROM #TB_DISPATCH_ALLOC_RAW
            PRINT CONCAT(
                FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff')
                ,'         TRACE PASO 9 ASIGNACION FIFO'
                ,' | DeltaMs=',DATEDIFF(MILLISECOND,@TracePrevDispatch,@TraceNowDispatch)
                ,' | TotalMs=',DATEDIFF(MILLISECOND,@TraceStartDispatch,@TraceNowDispatch)
                ,' | RowsAllocRaw=',@TraceCountA
                ,' | RowsAllocSize=',@TraceCountB
                ,' | QtyAssignedRaw=',@TraceQtyAssigned
            )
            SET @TracePrevDispatch = @TraceNowDispatch

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 10 VALIDAR ORDENES COMPLETAS (MODO ESTRICTO)')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 62,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Validando ordenes completamente cubiertas.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 10 VALIDAR ORDENES COMPLETAS (MODO ESTRICTO)'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            -- Tabla temporal: #TB_DISPATCH_ORDER_OK
            -- Ordenes con todas sus tallas cubiertas en modo estricto (vendor+typequery).
            INSERT INTO #TB_DISPATCH_ORDER_OK ([OrderRow])
            SELECT
                 R.[OrderRow]
            FROM #TB_DISPATCH_ORD_SIZE AS R
            LEFT JOIN #TB_DISPATCH_ALLOC_SIZE AS A
                ON A.[OrderRow] = R.[OrderRow]
               AND A.[Size] = R.[Size]
            GROUP BY R.[OrderRow]
            HAVING SUM(CASE WHEN ISNULL(A.[QtyAssigned],0) >= R.[QtyRequired] THEN 1 ELSE 0 END) = COUNT(*)

            -- Tabla temporal: #TB_DISPATCH_ORDER_OK_STRICT
            -- Copia fija del set estricto para separarlo del fallback mixed.
            SELECT
                 [OrderRow]
            INTO #TB_DISPATCH_ORDER_OK_STRICT
            FROM #TB_DISPATCH_ORDER_OK

            -- Mantener solo asignaciones del modo estricto para ordenes completas.
            DELETE A
            FROM #TB_DISPATCH_ALLOC_RAW AS A
            LEFT JOIN #TB_DISPATCH_ORDER_OK_STRICT AS K
                ON K.[OrderRow] = A.[OrderRow]
            WHERE K.[OrderRow] IS NULL
            SET @TraceNowDispatch = SYSDATETIME()
            SELECT
                @TraceCountA = COUNT_BIG(*)
            FROM #TB_DISPATCH_ORDER_OK_STRICT
            SELECT
                @TraceCountB = COUNT_BIG(*)
            FROM #TB_DISPATCH_ALLOC_RAW
            PRINT CONCAT(
                FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff')
                ,'         TRACE PASO 10 MODO ESTRICTO'
                ,' | DeltaMs=',DATEDIFF(MILLISECOND,@TracePrevDispatch,@TraceNowDispatch)
                ,' | TotalMs=',DATEDIFF(MILLISECOND,@TraceStartDispatch,@TraceNowDispatch)
                ,' | OrdersOKStrict=',@TraceCountA
                ,' | RowsAllocRawAfterStrict=',@TraceCountB
            )
            SET @TracePrevDispatch = @TraceNowDispatch

            -- Fallback: para ordenes no cubiertas por vendor unico, intentar por Style/Color (vendor mixed).
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 10A FALLBACK STYLE/COLOR (VENDOR MIXED)')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 63,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Aplicando fallback vendor mixed para ordenes no cubiertas.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 10A FALLBACK STYLE/COLOR (VENDOR MIXED)'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            -- Tabla temporal: #TB_DISPATCH_INV_REMAIN
            -- Remanente de inventario despues del modo estricto (disponible para mixed).
            SELECT
                 I.[InvPoolRow]
                ,I.[Style]
                ,I.[Color]
                ,I.[Season]
                ,I.[TypeQuery]
                ,I.[OrderWIP]
                ,I.[OrigFabricVendorName]
                ,I.[PackDate]
                ,I.[BoxNumber]
                ,I.[CSVBoxNumber]
                ,I.[PPFG]
                ,I.[MO]
                ,I.[MO_ID]
                ,I.[Size]
                ,[QtyAvailable] = CAST(I.[QtyAvailable] - ISNULL(A.[QtyAssigned],0) AS FLOAT)
                ,I.[BIN]
                ,I.[PNHangtag]
                ,I.[CountryOfOrigin]
            INTO #TB_DISPATCH_INV_REMAIN
            FROM #TB_DISPATCH_INV_POOL AS I
            LEFT JOIN (
                SELECT
                     [InvPoolRow]
                    ,[QtyAssigned] = SUM([QtyAssigned])
                FROM #TB_DISPATCH_ALLOC_RAW
                GROUP BY [InvPoolRow]
            ) AS A
                ON A.[InvPoolRow] = I.[InvPoolRow]
            WHERE CAST(I.[QtyAvailable] - ISNULL(A.[QtyAssigned],0) AS FLOAT) > 0

            -- Tabla temporal: #TB_DISPATCH_ORD_SIZE_PENDING
            -- Demanda pendiente de ordenes no cubiertas por el modo estricto.
            SELECT
                 O.[OrderRow]
                ,O.[Style]
                ,O.[Color]
                ,O.[Size]
                ,O.[QtyRequired]
            INTO #TB_DISPATCH_ORD_SIZE_PENDING
            FROM #TB_DISPATCH_ORD_SIZE AS O
            LEFT JOIN #TB_DISPATCH_ORDER_OK_STRICT AS K
                ON K.[OrderRow] = O.[OrderRow]
            WHERE K.[OrderRow] IS NULL

            -- Tabla temporal: #TB_DISPATCH_ORD_REQ_SEQ_MIX
            -- Demanda acumulada por talla para fallback mixed (sin vendor en particion).
            SELECT
                 O.[OrderRow]
                ,O.[Style]
                ,O.[Color]
                ,O.[Size]
                ,O.[QtyRequired]
                ,[CumReq]     = SUM(O.[QtyRequired]) OVER (
                                    PARTITION BY O.[Style],O.[Color],O.[Size]
                                    ORDER BY O.[OrderRow] ASC
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                                 )
                ,[CumReqPrev] = SUM(O.[QtyRequired]) OVER (
                                    PARTITION BY O.[Style],O.[Color],O.[Size]
                                    ORDER BY O.[OrderRow] ASC
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                                 )
            INTO #TB_DISPATCH_ORD_REQ_SEQ_MIX
            FROM #TB_DISPATCH_ORD_SIZE_PENDING AS O

            UPDATE S SET [CumReqPrev] = ISNULL([CumReqPrev],0)
            FROM #TB_DISPATCH_ORD_REQ_SEQ_MIX AS S

            -- Tabla temporal: #TB_DISPATCH_INV_SEQ_MIX
            -- Inventario acumulado por talla para mixed, priorizando TypeQuery y FIFO.
            SELECT
                 I.*
                ,[CumInv]     = SUM(I.[QtyAvailable]) OVER (
                                    PARTITION BY I.[Style],I.[Color],I.[Size]
                                    ORDER BY I.[TypeQuery] ASC,I.[OrderWIP] ASC,I.[PackDate] ASC,I.[BoxNumber] ASC,I.[Season] DESC,I.[InvPoolRow] ASC
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                                 )
                ,[CumInvPrev] = SUM(I.[QtyAvailable]) OVER (
                                    PARTITION BY I.[Style],I.[Color],I.[Size]
                                    ORDER BY I.[TypeQuery] ASC,I.[OrderWIP] ASC,I.[PackDate] ASC,I.[BoxNumber] ASC,I.[Season] DESC,I.[InvPoolRow] ASC
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                                 )
            INTO #TB_DISPATCH_INV_SEQ_MIX
            FROM #TB_DISPATCH_INV_REMAIN AS I
            INNER JOIN (
                SELECT DISTINCT [Style],[Color]
                FROM #TB_DISPATCH_ORD_SIZE_PENDING
            ) AS G
                ON G.[Style] = I.[Style]
               AND G.[Color] = I.[Color]

            UPDATE S SET [CumInvPrev] = ISNULL([CumInvPrev],0)
            FROM #TB_DISPATCH_INV_SEQ_MIX AS S

            -- Tabla temporal: #TB_DISPATCH_ALLOC_RAW_MIX
            -- Asignacion detallada candidata en fallback mixed por Style/Color.
            INSERT INTO #TB_DISPATCH_ALLOC_RAW_MIX (
                 [OrderRow],[Style],[Color],[RequiredDate],[ordenEmb],[DocDate],[Cust Due Date],[Original Request Date],[OrderID],[PONumber]
                ,[CustomerOrder],[PWModulo],[QtyWithdraw],[FirstBlanksBoxNumber],[MO],[MO_ID]
                ,[StatusOrder],[SKUStatus],[Status],[Season],[OrderTypeDescription],[ApplicationOrder]
                ,[TypeQuery],[OrigFabricVendorName],[Size],[QtyRequired],[QtyAssigned]
                ,[InvPoolRow],[OrderWIP],[Inv_Pack_Date],[BoxNumber],[CSVBoxNumber],[PPFG]
                ,[InvMO],[InvMO_ID],[BIN],[PNHangtag],[CountryOfOrigin],[inv_Style],[inv_Color],[inv_Season]
                ,[PromiseDate],[InventoryDate],[RunDate]
            )
            SELECT
                 O.[OrderRow]
                ,O.[Style]
                ,O.[Color]
                ,OB.[RequiredDate]
                ,OB.[ordenEmb]
                ,OB.[DocDate]
                ,OB.[Cust Due Date]
                ,OB.[Original Request Date]
                ,OB.[OrderID]
                ,OB.[PONumber]
                ,OB.[CustomerOrder]
                ,OB.[PWModulo]
                ,OB.[QtyWithdraw]
                ,OB.[FirstBlanksBoxNumber]
                ,OB.[MO]
                ,OB.[MO_ID]
                ,OB.[StatusOrder]
                ,OB.[SKUStatus]
                ,OB.[Status]
                ,OB.[Season]
                ,OB.[OrderTypeDescription]
                ,OB.[ApplicationOrder]
                ,I.[TypeQuery]
                ,I.[OrigFabricVendorName]
                ,O.[Size]
                ,[QtyRequired] = O.[QtyRequired]
                ,[QtyAssigned] = CAST(X.[EndPoint] - X.[StartPoint] AS FLOAT)
                ,I.[InvPoolRow]
                ,I.[OrderWIP]
                ,I.[PackDate]
                ,I.[BoxNumber]
                ,I.[CSVBoxNumber]
                ,I.[PPFG]
                ,I.[MO]
                ,I.[MO_ID]
                ,I.[BIN]
                ,I.[PNHangtag]
                ,I.[CountryOfOrigin]
                ,I.[Style]
                ,I.[Color]
                ,I.[Season]
                ,OB.[PromiseDate]
                ,OB.[InventoryDate]
                ,OB.[RunDate]
            FROM #TB_DISPATCH_ORD_REQ_SEQ_MIX AS O
            INNER JOIN #TB_DISPATCH_ORD_BASE AS OB
                ON OB.[OrderRow] = O.[OrderRow]
            INNER JOIN #TB_DISPATCH_INV_SEQ_MIX AS I
                ON I.[Style] = O.[Style]
               AND I.[Color] = O.[Color]
               AND I.[Size] = O.[Size]
            CROSS APPLY (
                SELECT
                     [StartPoint] = CASE WHEN O.[CumReqPrev] > I.[CumInvPrev] THEN O.[CumReqPrev] ELSE I.[CumInvPrev] END
                    ,[EndPoint]   = CASE WHEN O.[CumReq] < I.[CumInv] THEN O.[CumReq] ELSE I.[CumInv] END
            ) AS X
            WHERE X.[EndPoint] > X.[StartPoint]

            -- Tabla temporal: #TB_DISPATCH_ALLOC_SIZE_MIX
            -- Resumen por talla del resultado mixed para validar orden completa.
            SELECT
                 [OrderRow]
                ,[Size]
                ,[QtyRequired] = MAX([QtyRequired])
                ,[QtyAssigned] = SUM([QtyAssigned])
            INTO #TB_DISPATCH_ALLOC_SIZE_MIX
            FROM #TB_DISPATCH_ALLOC_RAW_MIX
            GROUP BY [OrderRow],[Size]

            -- Tabla temporal: #TB_DISPATCH_ORDER_OK_MIX
            -- Ordenes pendientes que si logran cobertura total usando mixed.
            SELECT
                 R.[OrderRow]
            INTO #TB_DISPATCH_ORDER_OK_MIX
            FROM #TB_DISPATCH_ORD_SIZE_PENDING AS R
            LEFT JOIN #TB_DISPATCH_ALLOC_SIZE_MIX AS A
                ON A.[OrderRow] = R.[OrderRow]
               AND A.[Size] = R.[Size]
            GROUP BY R.[OrderRow]
            HAVING SUM(CASE WHEN ISNULL(A.[QtyAssigned],0) >= R.[QtyRequired] THEN 1 ELSE 0 END) = COUNT(*)

            INSERT INTO #TB_DISPATCH_ALLOC_RAW (
                 [OrderRow],[Style],[Color],[RequiredDate],[ordenEmb],[DocDate],[Cust Due Date],[Original Request Date],[OrderID],[PONumber],[CustomerOrder],[PWModulo],[QtyWithdraw],[FirstBlanksBoxNumber],[MO],[MO_ID],[StatusOrder],[SKUStatus],[Status],[Season],[OrderTypeDescription],[ApplicationOrder],[TypeQuery],[OrigFabricVendorName],[Size],[QtyRequired],[QtyAssigned],[InvPoolRow],[OrderWIP],[Inv_Pack_Date],[BoxNumber],[CSVBoxNumber],[PPFG],[InvMO],[InvMO_ID],[BIN],[PNHangtag],[CountryOfOrigin],[inv_Style],[inv_Color],[inv_Season],[PromiseDate],[InventoryDate],[RunDate]
            )
            SELECT
                 [OrderRow],[Style],[Color],[RequiredDate],[ordenEmb],[DocDate],[Cust Due Date],[Original Request Date],[OrderID],[PONumber],[CustomerOrder],[PWModulo],[QtyWithdraw],[FirstBlanksBoxNumber],[MO],[MO_ID],[StatusOrder],[SKUStatus],[Status],[Season],[OrderTypeDescription],[ApplicationOrder],[TypeQuery],[OrigFabricVendorName],[Size],[QtyRequired],[QtyAssigned],[InvPoolRow],[OrderWIP],[Inv_Pack_Date],[BoxNumber],[CSVBoxNumber],[PPFG],[InvMO],[InvMO_ID],[BIN],[PNHangtag],[CountryOfOrigin],[inv_Style],[inv_Color],[inv_Season],[PromiseDate],[InventoryDate],[RunDate]
            FROM #TB_DISPATCH_ALLOC_RAW_MIX
            WHERE [OrderRow] IN (SELECT [OrderRow] FROM #TB_DISPATCH_ORDER_OK_MIX)

            INSERT INTO #TB_DISPATCH_ORDER_OK([OrderRow])
            SELECT
                 M.[OrderRow]
            FROM #TB_DISPATCH_ORDER_OK_MIX AS M
            LEFT JOIN #TB_DISPATCH_ORDER_OK AS K
                ON K.[OrderRow] = M.[OrderRow]
            WHERE K.[OrderRow] IS NULL
            SET @TraceNowDispatch = SYSDATETIME()
            SELECT
                @TraceCountA = COUNT_BIG(*)
            FROM #TB_DISPATCH_INV_REMAIN
            SELECT
                @TraceCountB = COUNT_BIG(*)
            FROM #TB_DISPATCH_ORD_SIZE_PENDING
            SELECT
                @TraceCountC = COUNT_BIG(*)
            FROM #TB_DISPATCH_ALLOC_RAW_MIX
            SELECT
                @TraceCountD = COUNT_BIG(*)
            FROM #TB_DISPATCH_ORDER_OK_MIX
            SELECT
                @TraceQtyAssigned = CAST(COUNT_BIG(*) AS VARCHAR(30))
            FROM #TB_DISPATCH_ORDER_OK
            PRINT CONCAT(
                FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff')
                ,'         TRACE PASO 10A FALLBACK MIXED'
                ,' | DeltaMs=',DATEDIFF(MILLISECOND,@TracePrevDispatch,@TraceNowDispatch)
                ,' | TotalMs=',DATEDIFF(MILLISECOND,@TraceStartDispatch,@TraceNowDispatch)
                ,' | RowsInvRemain=',@TraceCountA
                ,' | RowsOrdPending=',@TraceCountB
                ,' | RowsAllocRawMix=',@TraceCountC
                ,' | OrdersOKMix=',@TraceCountD
                ,' | OrdersOKTotal=',@TraceQtyAssigned
            )
            SET @TracePrevDispatch = @TraceNowDispatch

            END -- fin modo FIFO con grupos y vendor (flag=false)
            ELSE
            BEGIN -- inicio modo RESERVA todo-o-nada (flag=true)

            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. MODO RESERVA (flag=true)------------------------------------------------------------------------------------------
            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----Explicacion del procedimiento para despacho en modo reserva
            -------------------         Que hace el bloque
            ------------------- Implementa despacho todo-o-nada por orden en orden FIFO, optimizado en 2 fases:
            ------------------- FASE 1 - Loop FIFO ligero: determina que ordenes se pueden despachar.
            -------------------   Para cada orden (en orden FIFO) verifica si TODAS las tallas requeridas
            -------------------   tienen stock disponible (inventario total - ya comprometido por ordenes anteriores OK).
            -------------------   Si aplica: registra la orden en #TB_DISPATCH_ORDER_OK y acumula comprometidos.
            -------------------   Si no aplica: la orden queda pendiente sin consumir inventario.
            -------------------   El check usa totales agregados (#TB_RESERVE_INV_AGG y #TB_RESERVE_COMMITTED),
            -------------------   no window functions, lo que lo hace muy rapido aun con muchas ordenes.
            ------------------- FASE 2 - Asignacion FIFO set-based (un solo paso):
            -------------------   Con las ordenes OK ya determinadas, construye secuencias acumuladas de
            -------------------   demanda (solo ordenes OK) e inventario (FIFO por TypeQuery/PackDate/BoxNumber),
            -------------------   y usa CROSS APPLY de traslape para asignar cajas/MO especificas.
            -------------------   Esta fase es equivalente a PASO 9 del modo normal pero ejecuta una sola vez.
            ------------------- Notas:
            -------------------   DiscardMPA y SuspendOrd se omiten sin consumir inventario.
            -------------------   No aplica fallback mixed-vendor (la cobertura es total o la orden no despacha).
            -------------------   Salidas: mismas tablas finales (#DispatchOrdersFromInventoryWIP, etc.).

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. MODO RESERVA PASO R1 INVENTARIO AGREGADO')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 55,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Calculando inventario disponible por talla.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. MODO RESERVA PASO R1 INVENTARIO AGREGADO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            -- Tabla: #TB_RESERVE_INV_AGG
            -- Inventario total por (Style, Color, Size). Lookup fijo para el loop de verificacion.
            DROP TABLE IF EXISTS #TB_RESERVE_INV_AGG
            SELECT
                 [Style]    = I.[Style]
                ,[Color]    = I.[Color]
                ,[Size]     = I.[Size]
                ,[QtyTotal] = SUM(I.[QtyAvailable])
            INTO #TB_RESERVE_INV_AGG
            FROM #TB_DISPATCH_INV_POOL AS I
            GROUP BY I.[Style], I.[Color], I.[Size]

            CREATE CLUSTERED INDEX IX_TB_RESERVE_INV_AGG
                ON #TB_RESERVE_INV_AGG([Style],[Color],[Size])

            -- Tabla: #TB_RESERVE_COMMITTED
            -- Unidades ya comprometidas por (Style, Color, Size) a medida que avanzan las ordenes OK en el loop.
            DROP TABLE IF EXISTS #TB_RESERVE_COMMITTED
            SELECT
                 [Style]        = D.[Style]
                ,[Color]        = D.[Color]
                ,[Size]         = D.[Size]
                ,[QtyCommitted] = CAST(0 AS FLOAT)
            INTO #TB_RESERVE_COMMITTED
            FROM (
                SELECT DISTINCT [Style],[Color],[Size]
                FROM #TB_DISPATCH_ORD_SIZE
            ) AS D

            CREATE CLUSTERED INDEX IX_TB_RESERVE_COMMITTED
                ON #TB_RESERVE_COMMITTED([Style],[Color],[Size])

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. MODO RESERVA PASO R2 LOOP FIFO ORDENES')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 58,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Evaluando ordenes en modo reserva (todo-o-nada FIFO).',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. MODO RESERVA PASO R2 LOOP FIFO ORDENES'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            -- Loop FIFO ligero: solo verifica disponibilidad con totales; no hace window functions.
            -- Itera unicamente sobre ordenes activas (sin gaps de OrderRow) para maxima eficiencia.
            -- #TB_DISPATCH_ORDER_OK ya fue pre-creada vacia antes del IF/ELSE.
            DECLARE @LoopOrderRow INT
            DECLARE @LoopStart    INT = 0

            WHILE 1 = 1
            BEGIN
                -- Avanzar al siguiente OrderRow activo (saltar bloqueadas y gaps)
                SELECT @LoopOrderRow = MIN([OrderRow])
                FROM #TB_DISPATCH_ORD_BASE
                WHERE [OrderRow]   > @LoopStart
                  AND [SuspendOrd] = 0

                IF @LoopOrderRow IS NULL BREAK

                -- Verificar que TODAS las tallas tienen stock disponible (total - comprometido)
                IF NOT EXISTS (
                    SELECT 1
                    FROM #TB_DISPATCH_ORD_SIZE AS D
                    LEFT JOIN #TB_RESERVE_INV_AGG AS IA
                        ON IA.[Style] = D.[Style] AND IA.[Color] = D.[Color] AND IA.[Size] = D.[Size]
                    LEFT JOIN #TB_RESERVE_COMMITTED AS C
                        ON C.[Style]  = D.[Style] AND C.[Color]  = D.[Color] AND C.[Size]  = D.[Size]
                    WHERE D.[OrderRow] = @LoopOrderRow
                      AND D.[QtyRequired] > ISNULL(IA.[QtyTotal], 0) - ISNULL(C.[QtyCommitted], 0)
                )
                BEGIN
                    -- Orden despachable: registrar y acumular comprometidos para siguientes ordenes
                    INSERT INTO #TB_DISPATCH_ORDER_OK ([OrderRow]) VALUES (@LoopOrderRow)

                    UPDATE C
                    SET C.[QtyCommitted] = C.[QtyCommitted] + D.[QtyRequired]
                    FROM #TB_RESERVE_COMMITTED AS C
                    INNER JOIN #TB_DISPATCH_ORD_SIZE AS D
                        ON D.[Style] = C.[Style] AND D.[Color] = C.[Color] AND D.[Size] = C.[Size]
                    WHERE D.[OrderRow] = @LoopOrderRow
                END

                SET @LoopStart = @LoopOrderRow
            END -- fin WHILE loop FIFO

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. MODO RESERVA PASO R3 SECUENCIA DEMANDA')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 61,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Construyendo secuencia de demanda para asignacion FIFO.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. MODO RESERVA PASO R3 SECUENCIA DEMANDA'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            -- Secuencia acumulada de demanda por (Style, Color, Size) solo para ordenes OK.
            -- Equivalente a #TB_DISPATCH_ORD_REQ_SEQ del modo normal pero sin particion por vendor.
            DROP TABLE IF EXISTS #TB_RESERVE_ORD_SEQ
            SELECT
                 O.[OrderRow]
                ,O.[Style]
                ,O.[Color]
                ,O.[Size]
                ,O.[QtyRequired]
                ,[CumReq]     = SUM(O.[QtyRequired]) OVER (
                                    PARTITION BY O.[Style],O.[Color],O.[Size]
                                    ORDER BY O.[OrderRow] ASC
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                                )
                ,[CumReqPrev] = ISNULL(SUM(O.[QtyRequired]) OVER (
                                    PARTITION BY O.[Style],O.[Color],O.[Size]
                                    ORDER BY O.[OrderRow] ASC
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                                ), 0)
            INTO #TB_RESERVE_ORD_SEQ
            FROM #TB_DISPATCH_ORD_SIZE AS O
            INNER JOIN #TB_DISPATCH_ORDER_OK AS K
                ON K.[OrderRow] = O.[OrderRow]

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. MODO RESERVA PASO R4 SECUENCIA INVENTARIO')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 62,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Construyendo secuencia de inventario FIFO.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. MODO RESERVA PASO R4 SECUENCIA INVENTARIO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            -- Secuencia acumulada de inventario FIFO por (Style, Color, Size).
            -- Equivalente a #TB_DISPATCH_INV_SEQ pero sin particion por vendor (todas las cajas disponibles).
            -- Solo incluye Style/Color que tienen al menos una orden OK.
            DROP TABLE IF EXISTS #TB_RESERVE_INV_SEQ
            SELECT
                 I.[InvPoolRow]
                ,I.[Style], I.[Color], I.[Season]
                ,I.[TypeQuery], I.[OrderWIP], I.[OrigFabricVendorName]
                ,I.[PackDate], I.[BoxNumber], I.[CSVBoxNumber], I.[PPFG]
                ,I.[MO], I.[MO_ID], I.[Size]
                ,I.[QtyAvailable]
                ,I.[BIN], I.[PNHangtag], I.[CountryOfOrigin]
                ,[CumInv]     = SUM(I.[QtyAvailable]) OVER (
                                    PARTITION BY I.[Style],I.[Color],I.[Size]
                                    ORDER BY I.[TypeQuery] ASC,I.[OrderWIP] ASC,I.[PackDate] ASC,I.[BoxNumber] ASC,I.[Season] DESC,I.[InvPoolRow] ASC
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                                )
                ,[CumInvPrev] = ISNULL(SUM(I.[QtyAvailable]) OVER (
                                    PARTITION BY I.[Style],I.[Color],I.[Size]
                                    ORDER BY I.[TypeQuery] ASC,I.[OrderWIP] ASC,I.[PackDate] ASC,I.[BoxNumber] ASC,I.[Season] DESC,I.[InvPoolRow] ASC
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                                ), 0)
            INTO #TB_RESERVE_INV_SEQ
            FROM #TB_DISPATCH_INV_POOL AS I
            INNER JOIN (
                SELECT DISTINCT OB.[Style], OB.[Color]
                FROM #TB_DISPATCH_ORDER_OK AS K
                INNER JOIN #TB_DISPATCH_ORD_BASE AS OB ON OB.[OrderRow] = K.[OrderRow]
            ) AS G
                ON G.[Style] = I.[Style] AND G.[Color] = I.[Color]
            WHERE ISNULL(I.[QtyAvailable], 0) > 0

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. MODO RESERVA PASO R5 ASIGNACION FIFO')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 63,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Asignando inventario FIFO a ordenes despachadas.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. MODO RESERVA PASO R5 ASIGNACION FIFO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

            -- Asignacion FIFO: traslape acumulado demanda vs inventario (un solo paso set-based).
            -- Equivalente a PASO 9 del modo normal. Se ejecuta una sola vez para todas las ordenes OK.
            INSERT INTO #TB_DISPATCH_ALLOC_RAW (
                 [OrderRow],[Style],[Color],[RequiredDate],[ordenEmb],[DocDate],[Cust Due Date],[Original Request Date],[OrderID],[PONumber]
                ,[CustomerOrder],[PWModulo],[QtyWithdraw],[FirstBlanksBoxNumber],[MO],[MO_ID]
                ,[StatusOrder],[SKUStatus],[Status],[Season],[OrderTypeDescription],[ApplicationOrder]
                ,[TypeQuery],[OrigFabricVendorName],[Size],[QtyRequired],[QtyAssigned]
                ,[InvPoolRow],[OrderWIP],[Inv_Pack_Date],[BoxNumber],[CSVBoxNumber],[PPFG]
                ,[InvMO],[InvMO_ID],[BIN],[PNHangtag],[CountryOfOrigin],[inv_Style],[inv_Color],[inv_Season]
                ,[PromiseDate],[InventoryDate],[RunDate]
            )
            SELECT
                 OB.[OrderRow]
                ,OB.[Style]
                ,OB.[Color]
                ,OB.[RequiredDate]
                ,OB.[ordenEmb]
                ,OB.[DocDate]
                ,OB.[Cust Due Date]
                ,OB.[Original Request Date]
                ,OB.[OrderID]
                ,OB.[PONumber]
                ,OB.[CustomerOrder]
                ,OB.[PWModulo]
                ,OB.[QtyWithdraw]
                ,OB.[FirstBlanksBoxNumber]
                ,OB.[MO]
                ,OB.[MO_ID]
                ,OB.[StatusOrder]
                ,OB.[SKUStatus]
                ,OB.[Status]
                ,OB.[Season]
                ,OB.[OrderTypeDescription]
                ,OB.[ApplicationOrder]
                ,I.[TypeQuery]
                ,I.[OrigFabricVendorName]
                ,O.[Size]
                ,[QtyRequired] = O.[QtyRequired]
                ,[QtyAssigned] = CAST(X.[EndPoint] - X.[StartPoint] AS FLOAT)
                ,I.[InvPoolRow]
                ,I.[OrderWIP]
                ,I.[PackDate]
                ,I.[BoxNumber]
                ,I.[CSVBoxNumber]
                ,I.[PPFG]
                ,I.[MO]
                ,I.[MO_ID]
                ,I.[BIN]
                ,I.[PNHangtag]
                ,I.[CountryOfOrigin]
                ,I.[Style]
                ,I.[Color]
                ,I.[Season]
                ,OB.[PromiseDate]
                ,OB.[InventoryDate]
                ,OB.[RunDate]
            FROM #TB_RESERVE_ORD_SEQ AS O
            INNER JOIN #TB_RESERVE_INV_SEQ AS I
                ON I.[Style] = O.[Style]
               AND I.[Color] = O.[Color]
               AND I.[Size]  = O.[Size]
            INNER JOIN #TB_DISPATCH_ORD_BASE AS OB
                ON OB.[OrderRow] = O.[OrderRow]
            CROSS APPLY (
                SELECT
                     [StartPoint] = CASE WHEN O.[CumReqPrev] > I.[CumInvPrev] THEN O.[CumReqPrev] ELSE I.[CumInvPrev] END
                    ,[EndPoint]   = CASE WHEN O.[CumReq] < I.[CumInv] THEN O.[CumReq] ELSE I.[CumInv] END
            ) AS X
            WHERE X.[EndPoint] > X.[StartPoint]

            -- #TB_DISPATCH_ORDER_GROUP y #TB_DISPATCH_ALLOC_RAW_MIX quedan vacias (no aplica en modo reserva).

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. MODO RESERVA')

            END -- fin modo RESERVA todo-o-nada (flag=true)

            -- Detalle de despacho (linea por orden+talla+caja usada).
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 11 GENERAR DETALLE DESPACHADO')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 64,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Generando detalle de ordenes despachadas.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 11 GENERAR DETALLE DESPACHADO'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            -- Tabla temporal: #TB_DISPATCH_ORDER_MIXED_FLAG
            -- Bandera por orden para indicar si uso mas de un vendor en asignacion final.
            SELECT
                 A.[OrderRow]
                ,[IsVendorMixed] = CAST(CASE WHEN COUNT(DISTINCT ISNULL(A.[OrigFabricVendorName],'')) > 1 THEN 1 ELSE 0 END AS BIT)
            INTO #TB_DISPATCH_ORDER_MIXED_FLAG
            FROM #TB_DISPATCH_ALLOC_RAW AS A
            GROUP BY A.[OrderRow]

            -- Tabla temporal final: #DispatchOrdersFromInventoryWIP
            -- Detalle operativo final del despacho por orden, talla e item de inventario usado.
            SELECT
                 [RowData]             = ROW_NUMBER() OVER (
                                            ORDER BY A.[TypeQuery] ASC,A.[OrderWIP] ASC,A.[Style] ASC,A.[Color] ASC,A.[ordenEmb] ASC,A.[RunDate] ASC,A.[DocDate] ASC,A.[BoxNumber] ASC,A.[OrderRow] ASC,A.[Size] ASC
                                          )
                ,[DispatchSeq]         = ROW_NUMBER() OVER (
                                            ORDER BY A.[TypeQuery] ASC,A.[OrderWIP] ASC,A.[Style] ASC,A.[Color] ASC,A.[ordenEmb] ASC,A.[RunDate] ASC,A.[DocDate] ASC,A.[BoxNumber] ASC,A.[OrderRow] ASC,A.[Size] ASC
                                          )
                ,A.[OrderRow]
                ,A.[Style]
                ,A.[Color]
                ,A.[RequiredDate]
                ,A.[ordenEmb]
                ,A.[DocDate]
                ,A.[Cust Due Date]
                ,A.[Original Request Date]
                ,A.[OrderID]
                ,A.[PONumber]
                ,A.[CustomerOrder]
                ,A.[PWModulo]
                ,A.[QtyWithdraw]
                ,A.[FirstBlanksBoxNumber]
                ,A.[StatusOrder]
                ,A.[SKUStatus]
                ,A.[Status]
                ,A.[Season]
                ,A.[OrderTypeDescription]
                ,A.[ApplicationOrder]
                ,[OrderMO]              = A.[MO]
                ,[OrderMO_ID]           = A.[MO_ID]
                ,A.[TypeQuery]
                ,A.[OrderWIP]
                ,A.[OrigFabricVendorName]
                ,A.[Size]
                ,A.[QtyAssigned]
                ,[Inv_Pack_Date]         = CAST(A.[Inv_Pack_Date] AS DATE)
                ,[InvBoxNumber]         = A.[BoxNumber]
                ,[CSVBoxNumber]         = A.[CSVBoxNumber]
                ,[PPFG]                 = A.[PPFG]
                ,A.[InvMO]
                ,A.[InvMO_ID]
                ,[IsVendorMixed]        = ISNULL(M.[IsVendorMixed],0)
                ,[IsFromWIP]            = CAST(ISNULL(WF.[IsFromWIP],0) AS BIT)
                ,[discard_by_percentage] = CAST(NULL AS DECIMAL(10,4))
                ,[CommentFinalNum]      = CAST(CASE
                                                WHEN ISNULL(BASE_ORD.[DiscardMPA],0) = 1 AND ISNULL(WF.[IsFromWIP],0) = 1 THEN 6
                                                WHEN ISNULL(BASE_ORD.[DiscardMPA],0) = 1                                  THEN 5
                                                WHEN ISNULL(M.[IsVendorMixed],0) = 1                                      THEN 2
                                                ELSE 1
                                               END AS INT)
                ,[CommentFinal]         = CAST(CASE
                                                WHEN ISNULL(BASE_ORD.[DiscardMPA],0) = 1 AND ISNULL(M.[IsVendorMixed],0) = 1 AND ISNULL(WF.[IsFromWIP],0) = 1   THEN    'Dispatched MPA WIP Mixed vendor'
                                                WHEN ISNULL(BASE_ORD.[DiscardMPA],0) = 1 AND ISNULL(M.[IsVendorMixed],0) = 1                                    THEN    'Dispatched MPA Mixed Vendor'
                                                WHEN ISNULL(BASE_ORD.[DiscardMPA],0) = 1 AND ISNULL(WF.[IsFromWIP],0) = 1                                       THEN    'Dispatched MPA WIP'
                                                WHEN ISNULL(BASE_ORD.[DiscardMPA],0) = 1                                                                        THEN    'Dispatched MPA'
                                                WHEN ISNULL(M.[IsVendorMixed],0) = 1 AND ISNULL(WF.[IsFromWIP],0) = 1                                           THEN    'Dispatched WIP: mixed vendor'
                                                WHEN ISNULL(M.[IsVendorMixed],0) = 1                                                                            THEN    'Dispatched: mixed vendor'
                                                WHEN ISNULL(WF.[IsFromWIP],0) = 1                                                                               THEN    'Dispatched WIP'
                                                ELSE                                                                                                                    'Dispatched'
                                               END AS VARCHAR(255))
                ,[Validate_Color]       = CAST(ISNULL(BASE_ORD.[Validate_Color],'') AS VARCHAR(100))
                ,[TypeEmbroidery]       = BASE_ORD.[TypeEmbroidery]
                ,[Technique]            = BASE_ORD.[Technique]
                ,[BIN]                  = A.[BIN]
                ,[PNHangtag]            = A.[PNHangtag]
                ,[CountryOfOrigin]      = A.[CountryOfOrigin]
                ,[APS]                  = BASE_ORD.[APS]
                ,[Type]                 = BASE_ORD.[Type]
                ,[inv_Style]            = A.[inv_Style]
                ,[inv_Color]            = A.[inv_Color]
                ,[inv_Season]           = A.[inv_Season]
                ,[PriceCode]            = BASE_ORD.[PriceCode]
                ,A.[PromiseDate]
                ,A.[InventoryDate]
                ,A.[RunDate]
            INTO #DispatchOrdersFromInventoryWIP
            FROM        #TB_DISPATCH_ALLOC_RAW          AS A
            INNER JOIN  #TB_DISPATCH_ORDER_OK           AS K    ON K.[OrderRow] = A.[OrderRow]
            LEFT JOIN   #TB_DISPATCH_ORDER_MIXED_FLAG   AS M    ON M.[OrderRow] = A.[OrderRow]
            LEFT JOIN (
                SELECT
                     A2.[OrderRow]
                    ,[IsFromWIP] = CAST(MAX(CASE WHEN A2.[TypeQuery] = 2 THEN 1 ELSE 0 END) AS BIT)
                FROM #TB_DISPATCH_ALLOC_RAW AS A2
                GROUP BY A2.[OrderRow]
            ) AS WF
                ON WF.[OrderRow] = A.[OrderRow]
            LEFT JOIN #TB_DISPATCH_ORD_BASE AS BASE_ORD
                ON BASE_ORD.[OrderRow] = A.[OrderRow]

            -- Resumen de ordenes despachadas.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 12 GENERAR RESUMEN DESPACHADAS')
            -- Tabla temporal: #TB_DISPATCH_ORDER_ALLOC_SUMMARY
            -- Consolidado por orden del origen de inventario asignado (tipo/vendor/box).
            SELECT
                 A.[OrderRow]
                ,[TypeQuery]            = CASE WHEN COUNT(DISTINCT A.[TypeQuery]) = 1 THEN MIN(A.[TypeQuery]) ELSE 0 END
                ,[OrigFabricVendorName] = CASE WHEN COUNT(DISTINCT ISNULL(A.[OrigFabricVendorName],'')) = 1 THEN MAX(ISNULL(A.[OrigFabricVendorName],'')) ELSE 'MIXED' END
                ,[CSVBoxNumber]         = CASE WHEN COUNT(DISTINCT ISNULL(A.[CSVBoxNumber],'')) = 1 THEN MAX(ISNULL(A.[CSVBoxNumber],'')) ELSE 'MIXED' END
                ,[PPFG]                 = CASE WHEN COUNT(DISTINCT ISNULL(A.[PPFG],'')) = 1 THEN MAX(ISNULL(A.[PPFG],'')) ELSE 'MIXED' END
                ,[Inv_Pack_Date]        = MAX(CAST(A.[Inv_Pack_Date] AS DATE))
            INTO #TB_DISPATCH_ORDER_ALLOC_SUMMARY
            FROM #TB_DISPATCH_ALLOC_RAW AS A
            GROUP BY A.[OrderRow]

            -- Tabla temporal final: #DispatchOrdersFromInventoryWIP_OrdersDispatched
            -- Salida final por orden despachada (1 fila por orderrow) con estatus y comentario.
            SELECT
                 [RowData] = ROW_NUMBER() OVER (
                                ORDER BY O.[Style] ASC,O.[Color] ASC,O.[ordenEmb] ASC,O.[RunDate] ASC,O.[DocDate] ASC,O.[OrderID] ASC
                             )
                ,O.[OrderRow]
                ,O.[Style]
                ,O.[Color]
                ,O.[RequiredDate]
                ,O.[ordenEmb]
                ,O.[DocDate]
                ,O.[Cust Due Date]
                ,O.[Original Request Date]
                ,O.[OrderID]
                ,O.[PONumber]
                ,O.[CustomerOrder]
                ,O.[PWModulo]
                ,[QtyWithdraw] = CAST(ISNULL(O.[QtyWithdraw],0) AS FLOAT)
                ,O.[FirstBlanksBoxNumber]
                ,O.[MO]
                ,O.[MO_ID]
                ,O.[StatusOrder]
                ,O.[SKUStatus]
                ,O.[Status]
                ,O.[Season]
                ,O.[OrderTypeDescription]
                ,O.[ApplicationOrder]
                ,[MakeL2] = CAST(ISNULL(O.[MakeL2],0) AS FLOAT)
                ,[Make]   = CAST(ISNULL(O.[Make],0) AS FLOAT)
                ,S.[TypeQuery]
                ,S.[OrigFabricVendorName]
                ,S.[CSVBoxNumber]
                ,S.[PPFG]
                ,[Inv_Pack_Date] = S.[Inv_Pack_Date]
                ,[IsVendorMixed] = ISNULL(M.[IsVendorMixed],0)
                ,[IsFromWIP]     = CAST(CASE WHEN S.[TypeQuery] <> 1 THEN 1 ELSE 0 END AS BIT)
                ,[discard_by_percentage] = CAST(NULL AS DECIMAL(10,4))
                ,[CommentFinalNum] = CAST(CASE WHEN ISNULL(M.[IsVendorMixed],0) = 1 THEN 2 ELSE 1 END AS INT)
                ,[CommentFinal]  = CAST(CASE
                                            WHEN ISNULL(M.[IsVendorMixed],0) = 1 AND S.[TypeQuery] <> 1 THEN 'Dispatched WIP: mixed vendor'
                                            WHEN ISNULL(M.[IsVendorMixed],0) = 1                        THEN 'Dispatched: mixed vendor'
                                            WHEN S.[TypeQuery] <> 1                                     THEN 'Dispatched WIP'
                                            ELSE                                                             'Dispatched'
                                        END AS VARCHAR(255))
                ,O.[Validate_Color]
                ,O.[TypeEmbroidery]
                ,O.[Technique]
                ,O.[APS]
                ,O.[Type]
                ,[PriceCode]            = O.[PriceCode]
                ,O.[PromiseDate]
                ,O.[InventoryDate]
                ,O.[RunDate]
            INTO #DispatchOrdersFromInventoryWIP_OrdersDispatched
            FROM        #TB_DISPATCH_ORD_BASE               AS O
            INNER JOIN  #TB_DISPATCH_ORDER_OK               AS K   ON K.[OrderRow] = O.[OrderRow]
            INNER JOIN  #TB_DISPATCH_ORDER_ALLOC_SUMMARY    AS S   ON S.[OrderRow] = O.[OrderRow]
            LEFT JOIN   #TB_DISPATCH_ORDER_MIXED_FLAG       AS M   ON M.[OrderRow] = O.[OrderRow]
            WHERE O.[DiscardMPA] = 0

            SET @TraceNowDispatch = SYSDATETIME()
            SELECT
                @TraceCountA = COUNT_BIG(*)
            FROM #DispatchOrdersFromInventoryWIP
            SELECT
                @TraceCountB = COUNT_BIG(*)
            FROM #DispatchOrdersFromInventoryWIP_OrdersDispatched
            PRINT CONCAT(
                FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff')
                ,'         TRACE PASO 11/12 SALIDAS DESPACHADAS'
                ,' | DeltaMs=',DATEDIFF(MILLISECOND,@TracePrevDispatch,@TraceNowDispatch)
                ,' | TotalMs=',DATEDIFF(MILLISECOND,@TraceStartDispatch,@TraceNowDispatch)
                ,' | RowsDispatchDetail=',@TraceCountA
                ,' | RowsDispatchOrders=',@TraceCountB
            )
            SET @TracePrevDispatch = @TraceNowDispatch

            -- Ordenes no despachadas con motivo principal.
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 13 GENERAR NO DESPACHADAS')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 65,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Clasificando ordenes no despachadas.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 13 GENERAR NO DESPACHADAS'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            -- Tabla temporal final: #DispatchOrdersFromInventoryWIP_OrdersNotDispatched
            -- Salida final por orden no despachada con motivo principal y faltantes por talla.
            ;WITH CTE_SizeAssigned AS (
                SELECT
                     A.[OrderRow]
                    ,A.[Size]
                    ,[QtyAssigned] = SUM(A.[QtyAssigned])
                FROM (
                    SELECT
                         [OrderRow]
                        ,[Size]
                        ,[QtyAssigned]
                    FROM #TB_DISPATCH_ALLOC_RAW

                    UNION ALL

                    SELECT
                         [OrderRow]
                        ,[Size]
                        ,[QtyAssigned]
                    FROM #TB_DISPATCH_ALLOC_RAW_MIX
                ) AS A
                GROUP BY A.[OrderRow],A.[Size]
            )
            ,CTE_SizeMissing AS (
                SELECT
                     R.[OrderRow]
                    ,[MissingSizes] = CAST(
                        STUFF((
                            SELECT
                                 ', ' + R2.[Size]
                            FROM #TB_DISPATCH_ORD_SIZE AS R2
                            LEFT JOIN CTE_SizeAssigned AS A2
                                ON A2.[OrderRow] = R2.[OrderRow]
                               AND A2.[Size] = R2.[Size]
                            WHERE R2.[OrderRow] = R.[OrderRow]
                              AND ISNULL(A2.[QtyAssigned],0) < R2.[QtyRequired]
                            ORDER BY R2.[Size]
                            FOR XML PATH(''), TYPE
                        ).value('.','VARCHAR(MAX)'),1,2,'')
                    AS VARCHAR(255))
                FROM #TB_DISPATCH_ORD_SIZE AS R
                GROUP BY R.[OrderRow]
            )
            ,CTE_Reasons AS (
                -- MPA despachada (inventario disponible): va a Discards con comment de despacho
                SELECT
                     O.[OrderRow],O.[Style],O.[Color],O.[RequiredDate],O.[ordenEmb],O.[DocDate],O.[Cust Due Date],O.[Original Request Date],O.[OrderID],O.[PONumber],O.[CustomerOrder],O.[PWModulo],O.[QtyWithdraw],O.[MO],O.[MO_ID],O.[StatusOrder],O.[SKUStatus],O.[Status],O.[Season],O.[OrderTypeDescription],O.[ApplicationOrder],O.[MakeL2],O.[Make],O.[Validate_Color],O.[TypeEmbroidery],O.[APS],O.[Type],O.[Technique],O.[PriceCode],O.[PromiseDate],O.[InventoryDate],O.[RunDate]
                    ,[CommentFinal]          = CAST(CASE
                                                  WHEN ISNULL(M.[IsVendorMixed],0) = 1 AND S.[TypeQuery] <> 1 THEN 'Dispatched MPA WIP Mixed vendor'
                                                  WHEN ISNULL(M.[IsVendorMixed],0) = 1                        THEN 'Dispatched MPA Mixed Vendor'
                                                  WHEN S.[TypeQuery] <> 1                                     THEN 'Dispatched MPA WIP'
                                                  ELSE                                                             'Dispatched MPA'
                                              END AS VARCHAR(255))
                    ,[CommentFinalNum]       = CAST(CASE WHEN S.[TypeQuery] <> 1 THEN 6 ELSE 5 END AS INT)
                    ,[CommentSizeMissing]    = CAST(NULL AS VARCHAR(255))
                    ,[Inv_Pack_Date]         = S.[Inv_Pack_Date]
                    ,[discard_by_percentage] = CAST(NULL AS DECIMAL(10,4))
                    ,[ReasonRank]            = 1
                FROM #TB_DISPATCH_ORD_BASE AS O
                INNER JOIN #TB_DISPATCH_ORDER_OK AS K
                    ON K.[OrderRow] = O.[OrderRow]
                INNER JOIN #TB_DISPATCH_ORDER_ALLOC_SUMMARY AS S
                    ON S.[OrderRow] = O.[OrderRow]
                LEFT JOIN #TB_DISPATCH_ORDER_MIXED_FLAG AS M
                    ON M.[OrderRow] = O.[OrderRow]
                WHERE O.[DiscardMPA] = 1

                UNION ALL

                -- MPA no despachada (sin inventario): va a Discards con 'Not dispatched: MPA flag'
                SELECT
                     O.[OrderRow],O.[Style],O.[Color],O.[RequiredDate],O.[ordenEmb],O.[DocDate],O.[Cust Due Date],O.[Original Request Date],O.[OrderID],O.[PONumber],O.[CustomerOrder],O.[PWModulo],O.[QtyWithdraw],O.[MO],O.[MO_ID],O.[StatusOrder],O.[SKUStatus],O.[Status],O.[Season],O.[OrderTypeDescription],O.[ApplicationOrder],O.[MakeL2],O.[Make],O.[Validate_Color],O.[TypeEmbroidery],O.[APS],O.[Type],O.[Technique],O.[PriceCode],O.[PromiseDate],O.[InventoryDate],O.[RunDate]
                    ,[CommentFinal]          = CAST('Not dispatched: MPA flag' AS VARCHAR(255))
                    ,[CommentFinalNum]       = CAST(3 AS INT)
                    ,[CommentSizeMissing]    = CAST(NULL AS VARCHAR(255))
                    ,[Inv_Pack_Date]         = CAST(NULL AS DATE)
                    ,[discard_by_percentage] = CAST(NULL AS DECIMAL(10,4))
                    ,[ReasonRank]            = 1
                FROM #TB_DISPATCH_ORD_BASE AS O
                WHERE O.[DiscardMPA] = 1
                  AND NOT EXISTS (
                      SELECT 1 FROM #TB_DISPATCH_ORDER_OK AS K2
                      WHERE K2.[OrderRow] = O.[OrderRow]
                  )

                UNION ALL

                SELECT
                     O.[OrderRow],O.[Style],O.[Color],O.[RequiredDate],O.[ordenEmb],O.[DocDate],O.[Cust Due Date],O.[Original Request Date],O.[OrderID],O.[PONumber],O.[CustomerOrder],O.[PWModulo],O.[QtyWithdraw],O.[MO],O.[MO_ID],O.[StatusOrder],O.[SKUStatus],O.[Status],O.[Season],O.[OrderTypeDescription],O.[ApplicationOrder],O.[MakeL2],O.[Make],O.[Validate_Color],O.[TypeEmbroidery],O.[APS],O.[Type],O.[Technique],O.[PriceCode],O.[PromiseDate],O.[InventoryDate],O.[RunDate]
                    ,[CommentFinal] = CAST('Not dispatched: Suspend flag' AS VARCHAR(255))
                    ,[CommentFinalNum] = CAST(4 AS INT)
                    ,[CommentSizeMissing] = CAST(NULL AS VARCHAR(255))
                    ,[Inv_Pack_Date] = CAST(NULL AS DATE)
                    ,[discard_by_percentage] = CAST(NULL AS DECIMAL(10,4))
                    ,[ReasonRank]   = 2
                FROM #TB_DISPATCH_ORD_BASE AS O
                WHERE O.[SuspendOrd] = 1

                UNION ALL

                SELECT
                     O.[OrderRow],O.[Style],O.[Color],O.[RequiredDate],O.[ordenEmb],O.[DocDate],O.[Cust Due Date],O.[Original Request Date],O.[OrderID],O.[PONumber],O.[CustomerOrder],O.[PWModulo],O.[QtyWithdraw],O.[MO],O.[MO_ID],O.[StatusOrder],O.[SKUStatus],O.[Status],O.[Season],O.[OrderTypeDescription],O.[ApplicationOrder],O.[MakeL2],O.[Make],O.[Validate_Color],O.[TypeEmbroidery],O.[APS],O.[Type],O.[Technique],O.[PriceCode],O.[PromiseDate],O.[InventoryDate],O.[RunDate]
                    ,[CommentFinal] = CAST('Not dispatched: inventory not enough by Style/Color (single-vendor and mixed)' AS VARCHAR(255))
                    ,[CommentFinalNum] = CAST(5 AS INT)
                    ,[CommentSizeMissing] = CAST(
                        CASE
                            WHEN ISNULL(MS.[MissingSizes],'') = '' THEN NULL
                            ELSE CONCAT('Missing size(s): ',MS.[MissingSizes])
                        END
                    AS VARCHAR(255))
                    ,[Inv_Pack_Date] = CAST(NULL AS DATE)
                    ,[discard_by_percentage] = CAST(NULL AS DECIMAL(10,4))
                    ,[ReasonRank]   = 3
                FROM #TB_DISPATCH_ORD_BASE AS O
                LEFT JOIN #TB_DISPATCH_ORDER_GROUP AS G
                    ON G.[OrderRow] = O.[OrderRow]
                LEFT JOIN #TB_DISPATCH_ORDER_OK AS K
                    ON K.[OrderRow] = O.[OrderRow]
                LEFT JOIN CTE_SizeMissing AS MS
                    ON MS.[OrderRow] = O.[OrderRow]
                WHERE O.[DiscardMPA] = 0
                  AND O.[SuspendOrd] = 0
                  AND G.[OrderRow] IS NULL
                  AND K.[OrderRow] IS NULL

                UNION ALL

                SELECT
                     O.[OrderRow],O.[Style],O.[Color],O.[RequiredDate],O.[ordenEmb],O.[DocDate],O.[Cust Due Date],O.[Original Request Date],O.[OrderID],O.[PONumber],O.[CustomerOrder],O.[PWModulo],O.[QtyWithdraw],O.[MO],O.[MO_ID],O.[StatusOrder],O.[SKUStatus],O.[Status],O.[Season],O.[OrderTypeDescription],O.[ApplicationOrder],O.[MakeL2],O.[Make],O.[Validate_Color],O.[TypeEmbroidery],O.[APS],O.[Type],O.[Technique],O.[PriceCode],O.[PromiseDate],O.[InventoryDate],O.[RunDate]
                    ,[CommentFinal] = CAST('Not dispatched: inventory exhausted in FIFO sequence' AS VARCHAR(255))
                    ,[CommentFinalNum] = CAST(6 AS INT)
                    ,[CommentSizeMissing] = CAST(
                        CASE
                            WHEN ISNULL(MS.[MissingSizes],'') = '' THEN NULL
                            ELSE CONCAT('Missing size(s): ',MS.[MissingSizes])
                        END
                    AS VARCHAR(255))
                    ,[Inv_Pack_Date] = CAST(NULL AS DATE)
                    ,[discard_by_percentage] = CAST(NULL AS DECIMAL(10,4))
                    ,[ReasonRank]   = 4
                FROM #TB_DISPATCH_ORD_BASE AS O
                INNER JOIN #TB_DISPATCH_ORDER_GROUP AS G
                    ON G.[OrderRow] = O.[OrderRow]
                LEFT JOIN #TB_DISPATCH_ORDER_OK AS K
                    ON K.[OrderRow] = O.[OrderRow]
                LEFT JOIN CTE_SizeMissing AS MS
                    ON MS.[OrderRow] = O.[OrderRow]
                WHERE O.[DiscardMPA] = 0
                  AND O.[SuspendOrd] = 0
                  AND K.[OrderRow] IS NULL
            )
            SELECT
                 [RowData] = ROW_NUMBER() OVER (
                                ORDER BY [Style] ASC,[Color] ASC,[ordenEmb] ASC,[RunDate] ASC,[DocDate] ASC,[OrderID] ASC
                             )
                ,[OrderRow],[Style],[Color],[RequiredDate],[ordenEmb],[DocDate],[Cust Due Date],[Original Request Date],[OrderID],[PONumber],[CustomerOrder],[PWModulo],[QtyWithdraw],[MO],[MO_ID],[StatusOrder],[SKUStatus],[Status],[Season],[OrderTypeDescription],[ApplicationOrder],[MakeL2],[Make],[CommentFinal],[CommentFinalNum],[CommentSizeMissing],[Inv_Pack_Date],[discard_by_percentage],[Validate_Color],[TypeEmbroidery],[APS],[Type],[Technique],[PriceCode],[PromiseDate],[InventoryDate],[RunDate]
            INTO #DispatchOrdersFromInventoryWIP_OrdersNotDispatched
            FROM (
                SELECT
                     R.*
                    ,[RN] = ROW_NUMBER() OVER(PARTITION BY R.[OrderRow] ORDER BY R.[ReasonRank] ASC)
                FROM CTE_Reasons AS R
            ) AS X
            WHERE X.[RN] = 1
            SET @TraceNowDispatch = SYSDATETIME()
            SELECT
                @TraceCountA = COUNT_BIG(*)
            FROM #DispatchOrdersFromInventoryWIP_OrdersNotDispatched
            PRINT CONCAT(
                FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff')
                ,'         TRACE PASO 13 NO DESPACHADAS'
                ,' | DeltaMs=',DATEDIFF(MILLISECOND,@TracePrevDispatch,@TraceNowDispatch)
                ,' | TotalMs=',DATEDIFF(MILLISECOND,@TraceStartDispatch,@TraceNowDispatch)
                ,' | RowsNotDispatched=',@TraceCountA
            )
            SET @TracePrevDispatch = @TraceNowDispatch

            -- Regla final por CustomerOrder:
            -- si el % de ordenes despachadas por CustomerOrder es menor al umbral configurado,
            -- mover esas ordenes a no despachadas (discard by percentage threshold).
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 14 VALIDAR PORCENTAJE CUSTOMER ORDER')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 66,
                [StepCode] = 'DISPATCH',
                [StepNameUser] = 'Asignando inventario a ordenes',
                [MessageUser] = 'Validando umbral de porcentaje por Customer Order.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP. PASO 14 VALIDAR PORCENTAJE CUSTOMER ORDER'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            DECLARE @PctCustomerOrderRaw    AS DECIMAL(10,4) = NULL
            DECLARE @PctCustomerOrderTarget AS DECIMAL(10,4) = NULL

            SELECT
                @PctCustomerOrderRaw = MAX(CAST(TB.[Percentage] AS DECIMAL(10,4)))
            FROM [AppsLCA].[dbo].[TB_OrderCustomer_OrderLCA_PercentCriterial] AS TB WITH(NOLOCK)
            WHERE TB.[Status] = 1
              AND TB.[Application] = 'AppsLCA.dbo.TB_OrderCustomer_OrderLCA'

            SET @PctCustomerOrderTarget =
                CASE
                    WHEN @PctCustomerOrderRaw IS NULL THEN NULL
                    WHEN @PctCustomerOrderRaw <= 1 THEN @PctCustomerOrderRaw * 100
                    ELSE @PctCustomerOrderRaw
                END

            IF ISNULL(@PctCustomerOrderTarget,0) > 0 AND @flagDispatchSamples = 0
            BEGIN
                DROP TABLE IF EXISTS #TB_DISPATCH_CO_TOTAL
                DROP TABLE IF EXISTS #TB_DISPATCH_CO_DISPATCHED
                DROP TABLE IF EXISTS #TB_DISPATCH_CO_PCT_FAIL
                DROP TABLE IF EXISTS #TB_DISPATCH_ORD_MOVE_BY_CO

                -- Tabla temporal: #TB_DISPATCH_CO_TOTAL
                -- Total de ordenes por CustomerOrder en universo evaluado.
                SELECT
                     [CustomerOrder] = O.[CustomerOrder]
                    ,[TotalOrders]   = COUNT(DISTINCT O.[OrderRow])
                INTO #TB_DISPATCH_CO_TOTAL
                FROM #TB_DISPATCH_ORD_BASE AS O
                WHERE ISNULL(O.[CustomerOrder],'') <> ''
                GROUP BY O.[CustomerOrder]

                -- Tabla temporal: #TB_DISPATCH_CO_DISPATCHED
                -- Total de ordenes despachadas por CustomerOrder.
                SELECT
                     [CustomerOrder]    = D.[CustomerOrder]
                    ,[DispatchedOrders] = COUNT(DISTINCT D.[OrderRow])
                INTO #TB_DISPATCH_CO_DISPATCHED
                FROM #DispatchOrdersFromInventoryWIP_OrdersDispatched AS D
                WHERE ISNULL(D.[CustomerOrder],'') <> ''
                GROUP BY D.[CustomerOrder]

                -- Tabla temporal: #TB_DISPATCH_CO_PCT_FAIL
                -- CustomerOrder cuyo porcentaje despachado queda debajo del umbral configurado.
                SELECT
                     T.[CustomerOrder]
                    ,T.[TotalOrders]
                    ,[DispatchedOrders] = ISNULL(D.[DispatchedOrders],0)
                    ,[DispatchedPct]    = CAST(
                        CASE
                            WHEN T.[TotalOrders] <= 0 THEN 0
                            ELSE (ISNULL(D.[DispatchedOrders],0) * 100.0) / T.[TotalOrders]
                        END
                    AS DECIMAL(10,4))
                INTO #TB_DISPATCH_CO_PCT_FAIL
                FROM #TB_DISPATCH_CO_TOTAL AS T
                LEFT JOIN #TB_DISPATCH_CO_DISPATCHED AS D
                    ON D.[CustomerOrder] = T.[CustomerOrder]
                WHERE CAST(
                        CASE
                            WHEN T.[TotalOrders] <= 0 THEN 0
                            ELSE (ISNULL(D.[DispatchedOrders],0) * 100.0) / T.[TotalOrders]
                        END
                    AS DECIMAL(10,4)) < @PctCustomerOrderTarget

                -- Tabla temporal: #TB_DISPATCH_ORD_MOVE_BY_CO
                -- Ordenes despachadas que deben moverse a no despachadas por regla de porcentaje.
                SELECT DISTINCT
                     D.[OrderRow]
                    ,D.[CustomerOrder]
                INTO #TB_DISPATCH_ORD_MOVE_BY_CO
                FROM #DispatchOrdersFromInventoryWIP_OrdersDispatched AS D
                INNER JOIN #TB_DISPATCH_CO_PCT_FAIL AS F
                    ON F.[CustomerOrder] = D.[CustomerOrder]

                DECLARE @RowDataStartNotDispatched AS BIGINT = ISNULL((SELECT MAX([RowData]) FROM #DispatchOrdersFromInventoryWIP_OrdersNotDispatched),0)

                INSERT INTO #DispatchOrdersFromInventoryWIP_OrdersNotDispatched (
                     [RowData],[OrderRow],[Style],[Color],[RequiredDate],[ordenEmb],[DocDate],[OrderID],[PONumber],[CustomerOrder],[PWModulo],[QtyWithdraw],[MO],[MO_ID],[StatusOrder],[SKUStatus],[Status],[Season],[OrderTypeDescription],[ApplicationOrder],[MakeL2],[Make],[CommentFinal],[CommentFinalNum],[CommentSizeMissing],[Inv_Pack_Date],[discard_by_percentage],[Validate_Color],[TypeEmbroidery],[APS],[Type],[Technique],[RunDate]
                )
                SELECT
                     [RowData]         = @RowDataStartNotDispatched + ROW_NUMBER() OVER (
                                            ORDER BY D.[Style] ASC,D.[Color] ASC,D.[ordenEmb] ASC,D.[RunDate] ASC,D.[DocDate] ASC,D.[OrderID] ASC
                                        )
                    ,D.[OrderRow]
                    ,D.[Style]
                    ,D.[Color]
                    ,D.[RequiredDate]
                    ,D.[ordenEmb]
                    ,D.[DocDate]
                    ,D.[OrderID]
                    ,D.[PONumber]
                    ,D.[CustomerOrder]
                    ,D.[PWModulo]
                    ,D.[QtyWithdraw]
                    ,D.[MO]
                    ,D.[MO_ID]
                    ,D.[StatusOrder]
                    ,D.[SKUStatus]
                    ,D.[Status]
                    ,D.[Season]
                    ,D.[OrderTypeDescription]
                    ,D.[ApplicationOrder]
                    ,D.[MakeL2]
                    ,D.[Make]
                    ,[CommentFinal]    = CAST('Not dispatched: customer order below percentage' AS VARCHAR(255))
                    ,[CommentFinalNum] = CAST(7 AS INT)
                    ,[CommentSizeMissing] = CAST(
                        CONCAT(
                            'CustomerOrder threshold ',CAST(@PctCustomerOrderTarget AS VARCHAR(20)),'%. ',
                            'Dispatched ',CAST(F.[DispatchedOrders] AS VARCHAR(20)),'/',CAST(F.[TotalOrders] AS VARCHAR(20)),
                            ' (',CAST(F.[DispatchedPct] AS VARCHAR(20)),'%).'
                        )
                    AS VARCHAR(255))
                    ,[Inv_Pack_Date] = D.[Inv_Pack_Date]
                    ,[discard_by_percentage] = CAST(@PctCustomerOrderTarget AS DECIMAL(10,4))
                    ,D.[Validate_Color]
                    ,D.[TypeEmbroidery]
                    ,D.[APS]
                    ,D.[Type]
                    ,D.[Technique]
                    ,D.[RunDate]
                FROM        #DispatchOrdersFromInventoryWIP_OrdersDispatched    AS D
                INNER JOIN  #TB_DISPATCH_ORD_MOVE_BY_CO                         AS M    ON M.[OrderRow] = D.[OrderRow]
                INNER JOIN  #TB_DISPATCH_CO_PCT_FAIL                            AS F    ON F.[CustomerOrder] = D.[CustomerOrder]
                LEFT JOIN #DispatchOrdersFromInventoryWIP_OrdersNotDispatched   AS ND   ON ND.[OrderRow] = D.[OrderRow]
                WHERE ND.[OrderRow] IS NULL

                DELETE S
                FROM #DispatchOrdersFromInventoryWIP AS S
                INNER JOIN #TB_DISPATCH_ORD_MOVE_BY_CO AS M
                    ON M.[OrderRow] = S.[OrderRow]

                DELETE S
                FROM #DispatchOrdersFromInventoryWIP_OrdersDispatched AS S
                INNER JOIN #TB_DISPATCH_ORD_MOVE_BY_CO AS M
                    ON M.[OrderRow] = S.[OrderRow]
            END
            SET @TraceNowDispatch = SYSDATETIME()
            SELECT
                @TraceCountA = COUNT_BIG(*)
            FROM #DispatchOrdersFromInventoryWIP_OrdersDispatched
            SELECT
                @TraceCountB = COUNT_BIG(*)
            FROM #DispatchOrdersFromInventoryWIP_OrdersNotDispatched
            PRINT CONCAT(
                FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff')
                ,'         TRACE PASO 14 CUSTOMER ORDER %'
                ,' | DeltaMs=',DATEDIFF(MILLISECOND,@TracePrevDispatch,@TraceNowDispatch)
                ,' | TotalMs=',DATEDIFF(MILLISECOND,@TraceStartDispatch,@TraceNowDispatch)
                ,' | PctTarget=',ISNULL(CAST(@PctCustomerOrderTarget AS VARCHAR(30)),'NULL')
                ,' | RowsDispatchOrders=',@TraceCountA
                ,' | RowsNotDispatched=',@TraceCountB
            )
            SET @TracePrevDispatch = @TraceNowDispatch

            DROP TABLE IF EXISTS #TB_LOOKUP_ORD_INV_PACK_DATE
            SELECT
                 [MO_ID]          = SRC.[MO_ID]
                ,[Inv_Pack_Date]  = MAX(SRC.[Inv_Pack_Date])
            INTO #TB_LOOKUP_ORD_INV_PACK_DATE
            FROM (
                SELECT
                     [MO_ID] = CAST(D.[OrderMO_ID] AS INT)
                    ,[Inv_Pack_Date] = CAST(D.[Inv_Pack_Date] AS DATE)
                FROM #DispatchOrdersFromInventoryWIP AS D
                WHERE D.[OrderMO_ID] IS NOT NULL
                  AND D.[Inv_Pack_Date] IS NOT NULL

                UNION ALL

                SELECT
                     [MO_ID] = CAST(ND.[MO_ID] AS INT)
                    ,[Inv_Pack_Date] = CAST(ND.[Inv_Pack_Date] AS DATE)
                FROM #DispatchOrdersFromInventoryWIP_OrdersNotDispatched AS ND
                WHERE ND.[MO_ID] IS NOT NULL
                  AND ND.[Inv_Pack_Date] IS NOT NULL
            ) AS SRC
            GROUP BY SRC.[MO_ID]

            DROP TABLE IF EXISTS #TB_LOOKUP_ORD_DISCARD_BY_PCT
            SELECT
                 [MO_ID]                  = CAST(D.[MO_ID] AS INT)
                ,[discard_by_percentage]  = MAX(CAST(D.[discard_by_percentage] AS DECIMAL(10,4)))
            INTO #TB_LOOKUP_ORD_DISCARD_BY_PCT
            FROM #DispatchOrdersFromInventoryWIP_OrdersNotDispatched AS D
            WHERE D.[MO_ID] IS NOT NULL
              AND D.[discard_by_percentage] IS NOT NULL
            GROUP BY CAST(D.[MO_ID] AS INT)

            UPDATE D
            SET [Inv_Pack_Date] = L.[Inv_Pack_Date]
            FROM        #DispatchOrdersFromInventoryWIP_OrdersDispatched    AS D
            INNER JOIN  #TB_LOOKUP_ORD_INV_PACK_DATE                        AS L    ON L.[MO_ID] = D.[MO_ID]

            UPDATE ND
            SET [Inv_Pack_Date] = L.[Inv_Pack_Date]
            FROM       #DispatchOrdersFromInventoryWIP_OrdersNotDispatched  AS ND
            INNER JOIN #TB_LOOKUP_ORD_INV_PACK_DATE                         AS L    ON L.[MO_ID] = ND.[MO_ID]

            UPDATE O
            SET
                 [Inv_Pack_Date]         = I.[Inv_Pack_Date]
                ,[discard_by_percentage] = P.[discard_by_percentage]
            FROM #TB_FINAL_PROC_ORDENES_DEMAND AS O
            LEFT JOIN #TB_LOOKUP_ORD_INV_PACK_DATE      AS I ON I.[MO_ID] = O.[MO_ID]
            LEFT JOIN #TB_LOOKUP_ORD_DISCARD_BY_PCT     AS P ON P.[MO_ID] = O.[MO_ID]

            -----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #DispatchOrdersFromInventoryWIP, #DispatchOrdersFromInventoryWIP_OrdersDispatched, #DispatchOrdersFromInventoryWIP_OrdersNotDispatched)
                DROP TABLE IF EXISTS #TB_DISPATCH_CO_TOTAL
                DROP TABLE IF EXISTS #TB_DISPATCH_CO_DISPATCHED
                DROP TABLE IF EXISTS #TB_DISPATCH_CO_PCT_FAIL
                DROP TABLE IF EXISTS #TB_DISPATCH_ORD_MOVE_BY_CO
                DROP TABLE IF EXISTS #TB_LOOKUP_ORD_INV_PACK_DATE
                DROP TABLE IF EXISTS #TB_LOOKUP_ORD_DISCARD_BY_PCT
                DROP TABLE IF EXISTS #TB_DISPATCH_INV_POOL
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
                DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_OK_STRICT
                DROP TABLE IF EXISTS #TB_DISPATCH_INV_REMAIN
                DROP TABLE IF EXISTS #TB_DISPATCH_ORD_SIZE_PENDING
                DROP TABLE IF EXISTS #TB_DISPATCH_ORD_REQ_SEQ_MIX
                DROP TABLE IF EXISTS #TB_DISPATCH_INV_SEQ_MIX
                DROP TABLE IF EXISTS #TB_DISPATCH_ALLOC_RAW_MIX
                DROP TABLE IF EXISTS #TB_DISPATCH_ALLOC_SIZE_MIX
                DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_OK_MIX
                DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_MIXED_FLAG
                DROP TABLE IF EXISTS #TB_DISPATCH_ORDER_ALLOC_SUMMARY
            -----------LIMPIEZA DE TABLAS TEMPORALES INTERMEDIAS (SE CONSERVA #DispatchOrdersFromInventoryWIP, #DispatchOrdersFromInventoryWIP_OrdersDispatched, #DispatchOrdersFromInventoryWIP_OrdersNotDispatched)
            SET @TraceNowDispatch = SYSDATETIME()
            SELECT
                @TraceCountA = COUNT_BIG(*)
            FROM #DispatchOrdersFromInventoryWIP
            SELECT
                @TraceCountB = COUNT_BIG(*)
            FROM #DispatchOrdersFromInventoryWIP_OrdersDispatched
            SELECT
                @TraceCountD = COUNT_BIG(*)
            FROM #DispatchOrdersFromInventoryWIP_OrdersNotDispatched
            PRINT CONCAT(
                FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff')
                ,'         TRACE FIN DESPACHO (CONSOLIDADO)'
                ,' | DeltaMs=',DATEDIFF(MILLISECOND,@TracePrevDispatch,@TraceNowDispatch)
                ,' | TotalMs=',DATEDIFF(MILLISECOND,@TraceStartDispatch,@TraceNowDispatch)
                ,' | RowsDispatchDetail=',@TraceCountA
                ,' | RowsDispatchOrders=',@TraceCountB
                ,' | RowsNotDispatched=',@TraceCountD
            )

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP')
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA DESPACHO DESDE INVENTARIO WIP---------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA DATOS DEL CSV---------------------------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO PROCEDIMIENTO PARA DATOS DEL CSV')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 67,
                [StepCode] = 'CSV',
                [StepNameUser] = 'Generando archivo de CSV por ordenes despachadas',
                [MessageUser] = 'Estamos preparando el CSV final para el usuario.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - INICIO PROCEDIMIENTO PARA DATOS DEL CSV'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            
            
            ----Explicacion del procedimiento para datos del CSV
            -------------------         Que hace el bloque
            ------------------- Construye CTE_CSV_MDB a partir de #DispatchOrdersFromInventoryWIP para normalizar campos de salida para carga CSV.
            ------------------- Estandariza datos clave: fecha/hora, CodeBoxNumber, PPFG, unidades, estatus de orden y datos de estilo/color/season.
            ------------------- Genera el SELECT FINAL CSV con la estructura esperada por SP_Planning_CSV_UPLOADPPM.
            ------------------- Calcula RepeatBox por inv_box_number y ord_mo para control de repetidos.
            ------------------- Ordena la salida para asegurar consistencia de exportacion y consumo aguas abajo.
            
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA DATOS DEL CSV. CTE_CSV_MDB + SELECT FINAL CSV')
                
                DROP TABLE IF EXISTS #TB_FINAL_PROC_CSV
                ;WITH CTE_CSV_MDB AS (
                    SELECT
                         [BlankBoxPPM]      = D.[FirstBlanksBoxNumber]
                        ,[fecha_update]     = DATEADD(SECOND, ISNULL(D.[DispatchSeq], D.[RowData]), GETDATE())
                        ,[CodeBoxNumber]    = D.[CSVBoxNumber]
                        ,[PPFG]             = D.[PPFG]
                        ,[Total]            = CAST(ROUND(ISNULL(D.[QtyAssigned],0),0) AS INT)
                        ,[size]             = D.[Size]
                        ,[inv_box_number]   = D.[InvBoxNumber]
                        ,[ord_mo]           = D.[OrderMO]
                        ,[ord_sku_status]   = CAST(
                                                CASE
                                                    WHEN TRY_CAST(D.[SKUStatus] AS INT) IS NOT NULL THEN TRY_CAST(d.[SKUStatus] AS INT)
                                                    WHEN D.[StatusOrder] = 'Released' THEN 40
                                                    WHEN D.[StatusOrder] = 'Forecast' THEN 20
                                                    ELSE NULL
                                                END
                                              AS INT)
                        ,[ord_status]       = D.[StatusOrder]
                        ,[ord_require_date] = D.[RequiredDate]
                        ,[ord_style]        = D.[Style]
                        ,[inv_color]        = D.[Color]
                        ,[ord_season]       = D.[Season]
                        ,[ord_make_l2]      = CAST(ROUND(ISNULL(O.[MakeL2],0),0) AS INT)
                        ,[ord_make]         = CAST(ROUND(ISNULL(O.[Make],0),0) AS INT)
                        ,[CommentFinal]     = D.[CommentFinal]
                        ,[Validate_Color]   = D.[Validate_Color]
                        ,[TypeEmbroidery]   = D.[TypeEmbroidery]
                        ,[Technique]        = D.[Technique]
                        ,[APS]              = D.[APS]
                        ,[Type]             = D.[Type] ---memiin
                        ,[Cust Due Date]         = D.[Cust Due Date]
                        ,[Original Request Date] = D.[Original Request Date]
                        ,[PromiseDate]           = D.[PromiseDate]
                        ,[InventoryDate]         = D.[InventoryDate]
                   FROM #DispatchOrdersFromInventoryWIP AS D
                   LEFT JOIN #TB_DISPATCH_ORD_BASE AS O
                        ON O.[OrderRow] = D.[OrderRow]
                   WHERE D.[CommentFinal] = 'Dispatched'

                )
                SELECT
                    -- 'BOX'                                                               AS [Box]
                    [Box]               = 'B0X'
                    -- ,TBox.[BoxNumber]                                                    AS [BlankBox]                   
                    ,[BlankBox]         = IIF( MDB.[BlankBoxPPM]= '' OR MDB.[BlankBoxPPM] IS NULL, 'PLANIFICACION DEBE CREAR CAJA A ORDEN',MDB.[BlankBoxPPM])
                    ,[Date]             = REPLACE(CONVERT(VARCHAR, MDB.[fecha_update], 23), '-', '')
                    -- ,REPLACE(CONVERT(VARCHAR,MDB.[fecha_update],8),':','')              AS [Hour]   
                    ,[Hour]             = REPLACE(CONVERT(VARCHAR, MDB.[fecha_update], 8), ':', CAST(FLOOR(RAND() * (9 - 1) + 1) AS VARCHAR))
                    ,[Num]              = 11
                    -- ,1                                                                  AS [Num]
                    -- ,'TBUQ'                                                             AS [TBUQ]
                    ,[TBUQ]             = 'TBU0'
                    -- ,'PPBX'+Ltrim(Str(PB.[PackedBoxID]+10000000))                       AS [BoxNumber]          
                    ,[BoxNumber]        = MDB.[CodeBoxNumber]
                    ,[PPFG]             = MDB.[PPFG]
                    ,[Units]            = MDB.[Total]
                    ,[keyGenerator]     = @KeyGenerated
                    ,[FinalCSV]         = '<<Final CSV>>'
                    ,[Size]             = MDB.[size]
                    ,[inv_box_number]   = MDB.[inv_box_number]
                    ,[RepeatBox]        = ROW_NUMBER() OVER (
                                            PARTITION BY MDB.[inv_box_number]
                                            ORDER BY MDB.[inv_box_number]
                                                    , MDB.[ord_mo]
                                          )
                    ,[ord_mo]           = MDB.[ord_mo]
                    ,[ord_sku_status]   = MDB.[ord_sku_status]
                    ,[ord_status]       = MDB.[ord_status]
                    ,[ord_require_date] = MDB.[ord_require_date]
                    ,[ord_style]        = MDB.[ord_style]
                    ,[inv_color]        = MDB.[inv_color]
                    ,[ord_season]       = MDB.[ord_season]
                    ,[Style_Color]      = CONCAT(MDB.[ord_style], '-', MDB.[inv_color])
                    ,[ord_make_l2]      = MDB.[ord_make_l2]
                    ,[ord_make]         = MDB.[ord_make]
                    ,[DiffMake]         = MDB.[ord_make_l2] - MDB.[ord_make]
                    ,[CommentFinal]     = MDB.[CommentFinal]
                    ,[Validate_Color]   = MDB.[Validate_Color]
                    ,[TypeEmbroidery]   = MDB.[TypeEmbroidery]
                    ,[Technique]        = MDB.[Technique]
                    ,[APS]              = MDB.[APS]
                    ,[Type]             = MDB.[Type]
                    ,[Cust Due Date]         = MDB.[Cust Due Date]
                    ,[Original Request Date] = MDB.[Original Request Date]
                    ,[PromiseDate]           = MDB.[PromiseDate]
                    ,[InventoryDate]         = MDB.[InventoryDate]

                INTO #TB_FINAL_PROC_CSV
                FROM CTE_CSV_MDB AS MDB  
                ORDER BY 
                     REPLACE(CONVERT(VARCHAR,MDB.[fecha_update],23),'-','') 
                    ,REPLACE(CONVERT(VARCHAR,MDB.[fecha_update],8),':','')  
                    ,MDB.[CodeBoxNumber]
                    ,MDB.[PPFG]
                    ,MDB.[size]             
                    ,MDB.[inv_box_number]   
                    ,MDB.[ord_mo]           
                    ,MDB.[ord_sku_status]   
                    ,MDB.[ord_status]       
                    ,MDB.[ord_require_date] 
                    ,MDB.[ord_style]        
                    ,MDB.[inv_color]        
                    ,MDB.[ord_season]

            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    PROCEDIMIENTO PARA DATOS DEL CSV')

            -- flagDispatchSamples: insertar en NotDispatched las ordenes de la tabla de parametros que no aparecen en el CSV
            IF @flagDispatchSamples = 1
            BEGIN
                DECLARE @RowDataStartND AS BIGINT = ISNULL((SELECT MAX([RowData]) FROM #DispatchOrdersFromInventoryWIP_OrdersNotDispatched), 0)

                INSERT INTO #DispatchOrdersFromInventoryWIP_OrdersNotDispatched (
                     [RowData],[OrderRow],[Style],[Color],[RequiredDate],[ordenEmb],[DocDate]
                    ,[Cust Due Date],[Original Request Date],[OrderID],[PONumber],[CustomerOrder]
                    ,[PWModulo],[QtyWithdraw],[MO],[MO_ID],[StatusOrder],[SKUStatus],[Status]
                    ,[Season],[OrderTypeDescription],[ApplicationOrder],[MakeL2],[Make]
                    ,[CommentFinal],[CommentFinalNum],[CommentSizeMissing],[Inv_Pack_Date]
                    ,[discard_by_percentage],[Validate_Color],[TypeEmbroidery],[APS],[Type]
                    ,[Technique],[PriceCode],[PromiseDate],[InventoryDate],[RunDate]
                )
                SELECT
                     [RowData]               = @RowDataStartND + ROW_NUMBER() OVER (ORDER BY D.[Style] ASC, D.[Color] ASC, D.[ordenEmb] ASC, D.[RequiredDate] ASC, D.[OrderID] ASC)
                    ,[OrderRow]              = D.[RowData]
                    ,[Style]                 = D.[Style]
                    ,[Color]                 = D.[Color]
                    ,[RequiredDate]          = D.[RequiredDate]
                    ,[ordenEmb]              = D.[ordenEmb]
                    ,[DocDate]               = D.[DocDate]
                    ,[Cust Due Date]         = D.[Cust Due Date]
                    ,[Original Request Date] = D.[Original Request Date]
                    ,[OrderID]               = D.[OrderID]
                    ,[PONumber]              = D.[PONumber]
                    ,[CustomerOrder]         = D.[CustomerOrder]
                    ,[PWModulo]              = D.[PWModulo]
                    ,[QtyWithdraw]           = D.[QtyWithdraw]
                    ,[MO]                    = D.[MO]
                    ,[MO_ID]                 = D.[MO_ID]
                    ,[StatusOrder]           = D.[StatusOrder]
                    ,[SKUStatus]             = D.[SKUStatus]
                    ,[Status]                = D.[Status]
                    ,[Season]                = D.[Season]
                    ,[OrderTypeDescription]  = D.[OrderTypeDescription]
                    ,[ApplicationOrder]      = D.[ApplicationOrder]
                    ,[MakeL2]                = D.[MakeL2]
                    ,[Make]                  = D.[Make]
                    ,[CommentFinal]          = CAST('Not dispatched: no inventory' AS VARCHAR(255))
                    ,[CommentFinalNum]       = CAST(8 AS INT)
                    ,[CommentSizeMissing]    = CAST(NULL AS VARCHAR(255))
                    ,[Inv_Pack_Date]         = CAST(NULL AS DATE)
                    ,[discard_by_percentage] = CAST(NULL AS DECIMAL(10,4))
                    ,[Validate_Color]        = D.[Validate_Color]
                    ,[TypeEmbroidery]        = D.[TypeEmbroidery]
                    ,[APS]                   = D.[APS]
                    ,[Type]                  = D.[Type]
                    ,[Technique]             = D.[Technique]
                    ,[PriceCode]             = D.[PriceCode]
                    ,[PromiseDate]           = D.[PromiseDate]
                    ,[InventoryDate]         = D.[InventoryDate]
                    ,[RunDate]               = D.[RunDate]
                FROM #TB_FINAL_PROC_ORDENES_DEMAND AS D
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM #TB_FINAL_PROC_CSV AS C
                    WHERE C.[ord_mo] = D.[MO]
                )
            END
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA DATOS DEL CSV---------------------------------------------------------------------------------------------------------------------------------------
         --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA GENERACION DE BACKLOG-------------------------------------------------------------------------------------------------------------------------------
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  INICIO PROCEDIMIENTO PARA GENERACION DE BACKLOG')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 68,
                [StepCode] = 'BACKLOG',
                [StepNameUser] = 'Generando backlog',
                [MessageUser] = 'Estamos preparando la base activa de L2Brand para backlog.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - INICIO PROCEDIMIENTO PARA GENERACION DE BACKLOG'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            
            
            DROP TABLE IF EXISTS #TB_LCAComments
            SELECT
                 [LCAComments]
                ,[OrderReport]
                ,[OrderDispatch]
                ,[DaysArriveInPacking]
                ,[DateInPacking]
            INTO #TB_LCAComments
            FROM OPENQUERY([MARIADB],'SELECT * FROM wordpress.Planning_Backlog_LCAComments')

            DROP TABLE IF EXISTS #TB_LOOKUP_ORD_DEMAND_BY_MO
            SELECT
                 [MO_ID]                  = CAST(S.[MO_ID] AS INT)
                ,[Inv_Pack_Date]          = MAX(CAST(S.[Inv_Pack_Date] AS DATE))
                ,[discard_by_percentage]  = MAX(CAST(S.[discard_by_percentage] AS DECIMAL(10,4)))
            INTO #TB_LOOKUP_ORD_DEMAND_BY_MO
            FROM #TB_FINAL_PROC_ORDENES_DEMAND AS S
            WHERE S.[MO_ID] IS NOT NULL
            GROUP BY CAST(S.[MO_ID] AS INT)
            
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA GENERACION DE BACKLOG. LOOKUPS LCA COMMENTS / INV_PACK_DATE')
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Percent] = 69,
                [StepCode] = 'BACKLOG',
                [StepNameUser] = 'Generando backlog',
                [MessageUser] = 'Estamos preparando la base activa de L2Brand para backlog.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. LOOKUPS LCA COMMENTS / INV_PACK_DATE'),500),
                [UpdatedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA ORDENES ACTIVAS EN L2BRAND--------------------------------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                ----Explicacion del procedimiento para generacion de backlog
                -------------------         Que hace el bloque
                ------------------- Crea la base inicial del backlog con ordenes activas de L2Brand.
                ------------------- Conserva una fila por ItemDetailID para evitar duplicados de origen.
                ------------------- Deja lista la tabla temporal para cruces siguientes contra inventario por talla.
                -------------------     Filtros utilizados
                -------------------         SKUStatus <= 40 (ordenes activas)
                -------------------         Quantity > 0
                -------------------         ItemDetailID IS NOT NULL
    
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE L2BRAND ACTIVAS')
                UPDATE [AppsLCA].[dbo].[TB_Global_Process]
                SET [Percent] = 70,
                    [StepCode] = 'BACKLOG',
                    [StepNameUser] = 'Generando backlog',
                    [MessageUser] = 'Estamos preparando la base activa de L2Brand para backlog.',
                    [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE L2BRAND ACTIVAS'),500),
                    [UpdatedAt] = SYSDATETIME()
                WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
                
                DROP TABLE IF EXISTS #TB_BACKLOG_L2BRAND_ACTIVE
                
                SELECT
                     [RowData]               
                    -- ,[RowItem]               
                    ,[created_at]            
                    ,[DueDate]               
                    ,[Week]                  
                    ,[CustomerOrder]         
                    ,[CustName]              
                    ,[Order_No]              
                    ,[ItemDetailID]          
                    ,[Quantity]              
                    ,[DetailStatus]          
                    ,[SKUStatus]             
                    ,[Status]                
                    ,[ArtStatus]             
                    ,[Status/Date]       
                    ,[PriceCode]
                    ,[ProductDivision]       
                    ,[Relabel]               
                    ,[MachineGroup]          
                    ,[SalesChannel]          
                    ,[ShipEarly]             
                    ,[ShipTo]                
                    ,[Type]                  
                    ,[TypeEmbroidery]        
                    ,[Technique]             
                    ,[Group]                 
                    ,[window]                
                    ,[LogoStyle]             
                    ,[ApplicationType]       
                    ,[GroupID]               
                    ,[RS_Priority]           
                    ,[EventDate]             
                    ,[LicenseSticker]        
                    ,[HotOrder]              
                    ,[Style_Color]           
                    ,[StyleID]               
                    ,[CSRID]                 
                    ,[CSRName]               
                    ,[Style_Sales_Status]    
                    ,[DesignNo]              
                    ,[SKUID]                 
                    ,[SKLogoNo]              
                    ,[CustPO]                
                    ,[ScreenPrint]           
                    ,[ScreenPrintAfter]	     
                    ,[ScreenPrintBefore]     
                    ,[SublimationBefore]     
                    ,[SublimationAfter]	     
                    ,[HDP]			         
                    ,[Blanks]			     
                    ,[Embroidery]		     
                    ,[EmbHWApplique]         
                    ,[EmbHWDirect]           
                    ,[EmbHWPatch]            
                    ,[EmbHWHDP]              
                    ,[EmbAppDirect]          
                    ,[EmbAppLBA]             
                INTO #TB_BACKLOG_L2BRAND_ACTIVE
            FROM(
                SELECT
                     [RowData]                  = ROW_NUMBER() OVER(ORDER BY CAST(L2.[DueDate] AS DATE) ASC, L2.[Order_No] ASC, L2.[ItemDetailID] ASC)
                    ,[RowItem]                  = ROW_NUMBER() OVER(PARTITION BY L2.[ItemDetailID] ORDER BY L2.[LicEntityID] DESC)
                    ,[created_at]               = L2.[created_at]
                    ,[DueDate]                  = CAST(L2.[DueDate] AS DATE)
                    ,[Week]                     = CONCAT('WEEK ',RIGHT(CONCAT('00',CAST(DATEPART(WEEK, CAST(L2.[DueDate] AS DATE)) AS VARCHAR(2))),2))
        			,[CustomerOrder]            = SUBSTRING(L2.[Order_No], 1, 9)
                    ,[CustName]                 = L2.[CustName]
                    ,[Order_No]                 = L2.[Order_No]
                    ,[ItemDetailID]             = L2.[ItemDetailID]
                    ,[Quantity]                 = ISNULL(L2.[Quantity],0)
                    ,[DetailStatus]             = L2.[DetailStatus]
                    ,[SKUStatus]                = L2.[SKUStatus]
                    ,[Status]                   = L2.[Status]
                    ,[ArtStatus]                = CAST(NULL AS VARCHAR(50))
                    ,[Status/Date]              = CAST(NULL AS VARCHAR(200))
                    ,[PriceCode]                = L2.[PriceCode]
                    ,[ProductDivision]          = CAST(NULL AS VARCHAR(200))
                    ,[Relabel]                  = CAST(NULL AS VARCHAR(100))
                    ,[MachineGroup]             = CAST(NULL AS VARCHAR(100))
                    ,[SalesChannel]             = CAST(NULL AS VARCHAR(200))
                    ,[ShipEarly]                = CAST(NULL AS INT)
                    ,[ShipTo]                   = CAST(NULL AS VARCHAR(200))
                    ,[Type]                     = CAST(NULL AS VARCHAR(MAX))
                    ,[TypeEmbroidery]           = CAST(NULL AS VARCHAR(MAX))
                    ,[Technique]                = CAST(NULL AS VARCHAR(MAX))
                    ,[Group]                    = CAST(NULL AS VARCHAR(100))
                    ,[window]                   = CAST(NULL AS DATE)
                    ,[LogoStyle]                = L2.[LogoStyle]
                    ,[ApplicationType]          = CAST(NULL AS VARCHAR(200))
                    ,[GroupID]                  = L2.[GroupID]
                    ,[RS_Priority]              = CAST(NULL AS VARCHAR(50))
                    ,[EventDate]                = L2.[EventDate]
                    ,[LicenseSticker]           = CAST(NULL AS VARCHAR(200))
                    ,[HotOrder]                 = CAST(NULL AS VARCHAR(200))
                    ,[Style_Color]              = L2.[Style Color]
                    ,[StyleID]                  = L2.[StyleID]
                    ,[CSRID]                    = L2.[CSRID]
                    ,[CSRName]                  = L2.[CSRName]
                    ,[Style_Sales_Status]       = L2.[Style Sales Status]
                    ,[DesignNo]                 = L2.[DesignNo]
                    ,[SKUID]                    = L2.[SKUID]
                    ,[SKLogoNo]                 = L2.[SKLogoNo]
                    ,[CustPO]                   = L2.[CustPO]
                    ,[ScreenPrint]              = CAST(0 AS INT)
                    ,[ScreenPrintAfter]	        = CAST(0 AS INT)            
                    ,[ScreenPrintBefore]        = CAST(0 AS INT)    
                    ,[SublimationBefore]        = CAST(0 AS INT)    
                    ,[SublimationAfter]	        = CAST(0 AS INT)    
                    ,[HDP]			            = CAST(0 AS INT)  
                    ,[Blanks]			        = CAST(0 AS INT)
                    ,[Embroidery]		        = CAST(0 AS INT) 
                    ,[EmbHWApplique]            = CAST(0 AS INT)
                    ,[EmbHWDirect]              = CAST(0 AS INT)
                    ,[EmbHWPatch]               = CAST(0 AS INT)
                    ,[EmbHWHDP]                 = CAST(0 AS INT)
                    ,[EmbAppDirect]             = CAST(0 AS INT)
                    ,[EmbAppLBA]                = CAST(0 AS INT)
                FROM [AppsLCA].[dbo].[TB_L2Brand_view_qryOpenOrderSuppl_162] AS L2 WITH(NOLOCK)
                WHERE 
                    ISNULL(L2.[SKUStatus],0) <= 40
                  AND 
                  ISNULL(L2.[Quantity],0) > 0
                  AND L2.[ItemDetailID] IS NOT NULL
                  AND L2.[CustName] NOT LIKE 'L2 SKU Set Up%'
             ) AS TB
             WHERE TB.[RowItem]  = 1            ----cambio dio error por item.. 
             ORDER BY  TB.[RowData]
    

                
                
                CREATE UNIQUE CLUSTERED INDEX IX_TB_BACKLOG_L2BRAND_ACTIVE  ON #TB_BACKLOG_L2BRAND_ACTIVE([ItemDetailID])
                    
                DROP TABLE IF EXISTS #TB_BACKLOG_L2BRAND_ACTIVE_UNIQUE_ITEMDETAILID
                -- select count(*) from #TB_BACKLOG_L2BRAND_ACTIVE_UNIQUE_ITEMDETAILID
                SELECT 
                     [ItemDetailID]
                    ,[ArtStatus] 
                INTO #TB_BACKLOG_L2BRAND_ACTIVE_UNIQUE_ITEMDETAILID
                FROM #TB_BACKLOG_L2BRAND_ACTIVE
                
                CREATE UNIQUE CLUSTERED INDEX IX_TB_BACKLOG_L2BRAND_ACTIVE_UNIQUE  ON #TB_BACKLOG_L2BRAND_ACTIVE_UNIQUE_ITEMDETAILID([ItemDetailID])
                
           

                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA GENERACION DE BACKLOG. LOOKUP STATUS/DATE')
                UPDATE [AppsLCA].[dbo].[TB_Global_Process]
                SET [Percent] = 71,
                    [StepCode] = 'BACKLOG',
                    [StepNameUser] = 'Generando backlog',
                    [MessageUser] = 'Estamos preparando la base activa de L2Brand para backlog.',
                    [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. LOOKUP STATUS/DATE (PRIMARY)'),500),
                    [UpdatedAt] = SYSDATETIME()
                WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
                
                DROP TABLE IF EXISTS #TB_BACKLOG_LOOKUP_STATUSDATE
                SELECT
                     [ItemDetailID]     = SRC.[ItemDetailID]
                    ,[Status/Date]      = SRC.[Status/Date]
                    ,[ProductDivision]  = SRC.[ProductDivision]
                    ,[ApplicationType]  = SRC.[ApplicationType]
                    ,[RS_Priority]      = SRC.[RS_Priority]
                    ,[Relabel]          = SRC.[Relabel]
                    ,[MachineGroup]     = SRC.[MachineGroup]
                    ,[SalesChannel]     = SRC.[SalesChannel]
                    ,[ShipTo]           = SRC.[ShipTo]
                    ,[LicenseSticker]   = SRC.[LicenseSticker]
                    ,[HotOrder]         = SRC.[HotOrder]
                    ,[ArtStatus]        = CASE
                                                     WHEN UPPER(ISNULL(SRC.[Status/Date],'')) LIKE '%RFP%' THEN 'RFP'
                                                     ELSE 'NO RFP'
                                                   END
                INTO #TB_BACKLOG_LOOKUP_STATUSDATE
                FROM (
                    SELECT
                         LOGS.[ItemDetailID]
                        ,[Status/Date]          = CAST(LOGS.[Status/Date] AS VARCHAR(200))
                        ,[ProductDivision]      = CAST(LOGS.[ProductDivision] AS VARCHAR(200))
                        ,[ApplicationType]      = CASt(LOGS.[Application Type] AS VARCHAR(200))
                        ,[RS_Priority]          = CAST(LOGS.[R/S Priority] AS VARCHAR(50))
                        ,[Relabel]              = CAST(LOGS.[Relabel] AS VARCHAR(100))
                        ,[MachineGroup]         = CAST(LOGS.[MachineGroup] AS VARCHAR(100))
                        ,[SalesChannel]         = CAST(LOGS.[SalesChannel] AS VARCHAR(200))
                        ,[ShipTo]               = LOGS.[Ship To]
                        ,[LicenseSticker]       = LOGS.[License Sticker]
                        ,[HotOrder]             = LOGS.[Hot Order]
                        ,[RN]                   = ROW_NUMBER() OVER (
                                                        PARTITION BY LOGS.[ItemDetailID]
                                                        ORDER BY LOGS.[Insert_Time] DESC
                                                    )   
                    -- FROM [192.168.1.93].[AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export_Logs] AS LOGS WITH(NOLOCK)
                    -- FROM #TB_BACKLOG_L2BRAND_ACTIVE AS FIL
                    FROM #TB_BACKLOG_L2BRAND_ACTIVE_UNIQUE_ITEMDETAILID AS FIL
                    INNER JOIN [AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export] AS LOGS WITH(NOLOCK)    ON FIL.[ItemDetailID] = LOGS.[ItemDetailID]  
                ) AS SRC
                WHERE SRC.[RN] = 1
                

-- select top 1 * from  [192.168.1.93].[AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export_Logs]
-- select top 1 * from  [AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export]

                UPDATE L2
                SET
                     [Status/Date]          = LOGS.[Status/Date]
                    ,[ProductDivision]      = LOGS.[ProductDivision]
                    ,[ArtStatus]            = LOGS.[ArtStatus]
                    ,[ApplicationType]      = LOGS.[ApplicationType]
                    ,[RS_Priority]          = LOGS.[RS_Priority]
                    ,[Relabel]              = LOGS.[Relabel]  
                    ,[MachineGroup]         = LOGS.[MachineGroup]  
                    ,[SalesChannel]         = LOGS.[SalesChannel]  
                    ,[ShipTo]               = LOGS.[ShipTo]  
                    ,[LicenseSticker]       = LOGS.[LicenseSticker]  
                    ,[HotOrder]             = LOGS.[HotOrder]  
                FROM #TB_BACKLOG_L2BRAND_ACTIVE AS L2
                LEFT JOIN #TB_BACKLOG_LOOKUP_STATUSDATE AS LOGS ON LOGS.[ItemDetailID] = L2.[ItemDetailID]

                DROP TABLE IF EXISTS #TB_BACKLOG_LOOKUP_STATUSDATE
                
                
                
                
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA GENERACION DE BACKLOG. LOOKUP STATUS/DATE')
                UPDATE [AppsLCA].[dbo].[TB_Global_Process]
                SET [Percent] = 73,
                    [StepCode] = 'BACKLOG',
                    [StepNameUser] = 'Generando backlog',
                    [MessageUser] = 'Estamos preparando la base activa de L2Brand para backlog.',
                    [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. LOOKUP STATUS/DATE (ALL LOGS)'),500),
                    [UpdatedAt] = SYSDATETIME()
                WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
                
                
                DROP TABLE IF EXISTS #TB_BACKLOG_LOOKUP_STATUSDATE_ALLLOGS
                SELECT
                     [ItemDetailID]     = SRC.[ItemDetailID]
                    ,[Status/Date]      = SRC.[Status/Date]
                    ,[ProductDivision]  = SRC.[ProductDivision]
                    ,[ApplicationType]  = SRC.[ApplicationType]
                    ,[RS_Priority]      = SRC.[RS_Priority]
                    ,[Relabel]          = SRC.[Relabel]
                    ,[MachineGroup]     = SRC.[MachineGroup]
                    ,[SalesChannel]     = SRC.[SalesChannel]
                    ,[ShipTo]           = SRC.[ShipTo]
                    ,[LicenseSticker]   = SRC.[LicenseSticker]
                    ,[HotOrder]         = SRC.[HotOrder]
                    ,[ArtStatus]        = CASE
                                                     WHEN UPPER(ISNULL(SRC.[Status/Date],'')) LIKE '%RFP%' THEN 'RFP'
                                                     ELSE 'NO RFP'
                                                   END
                INTO #TB_BACKLOG_LOOKUP_STATUSDATE_ALLLOGS
                FROM (
                    SELECT
                         LOGS.[ItemDetailID]
                        ,[Status/Date]          = CAST(LOGS.[Status/Date] AS VARCHAR(200))
                        ,[ProductDivision]      = CAST(LOGS.[ProductDivision] AS VARCHAR(200))
                        ,[ApplicationType]      = CASt(LOGS.[Application Type] AS VARCHAR(200))
                        ,[RS_Priority]          = CAST(LOGS.[R/S Priority] AS VARCHAR(50))
                        ,[Relabel]              = CAST(LOGS.[Relabel] AS VARCHAR(100))
                        ,[MachineGroup]         = CAST(LOGS.[MachineGroup] AS VARCHAR(100))
                        ,[SalesChannel]         = CAST(LOGS.[SalesChannel] AS VARCHAR(200))
                        ,[ShipTo]               = LOGS.[Ship To]
                        ,[LicenseSticker]       = LOGS.[License Sticker]
                        ,[HotOrder]             = LOGS.[Hot Order]
                        ,[RN]                   = ROW_NUMBER() OVER (
                                                        PARTITION BY LOGS.[ItemDetailID]
                                                        ORDER BY LOGS.[Insert_Time] DESC
                                                    )
                    -- FROM [AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export] AS LOGS WITH(NOLOCK)
                    -- FROM #TB_BACKLOG_L2BRAND_ACTIVE AS FIL
                    FROM
                        #TB_BACKLOG_L2BRAND_ACTIVE_UNIQUE_ITEMDETAILID AS FIL
                    INNER JOIN
                        [192.168.1.93].[AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export_Logs] AS LOGS WITH(NOLOCK)
                        ON FIL.[ItemDetailID] = LOGS.[ItemDetailID] AND (FIL.[ArtStatus] IS NULL OR FIL.[ArtStatus] ='')
                ) AS SRC
                WHERE SRC.[RN] = 1


                UPDATE L2
                SET
                     [Status/Date]          = LOGS.[Status/Date]
                    ,[ProductDivision]      = LOGS.[ProductDivision]
                    ,[ArtStatus]            = LOGS.[ArtStatus]
                    ,[ApplicationType]      = LOGS.[ApplicationType]
                    ,[RS_Priority]          = LOGS.[RS_Priority]
                    ,[Relabel]              = LOGS.[Relabel]
                    ,[MachineGroup]         = LOGS.[MachineGroup]  
                    ,[SalesChannel]         = LOGS.[SalesChannel]  
                    ,[ShipTo]               = LOGS.[ShipTo]  
                    ,[LicenseSticker]       = LOGS.[LicenseSticker]
                    ,[HotOrder]             = LOGS.[HotOrder]
                FROM #TB_BACKLOG_L2BRAND_ACTIVE AS L2
                LEFT JOIN #TB_BACKLOG_LOOKUP_STATUSDATE_ALLLOGS AS LOGS
                    ON LOGS.[ItemDetailID] = L2.[ItemDetailID]
                WHERE L2.[ArtStatus] IS NULL OR L2.[ArtStatus] =''

                DROP TABLE IF EXISTS #TB_BACKLOG_LOOKUP_STATUSDATE_ALLLOGS
                
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA GENERACION DE BACKLOG. LOOKUP GROUPID')
                DROP TABLE IF EXISTS #TB_GROUPID
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
                
                UPDATE L2 SET
                    [ShipEarly]            = CASE 
                                                WHEN L2.[RS_Priority] = 'SWR'
                                                THEN 1 
                                                ELSE B.[ShipEarly]
                                              END    
                    ,[Group]                    = CASE
                                                        WHEN (L2.[Style_Color] LIKE '%BUNDLE%')        THEN 'Bundles'       -- WHEN TB_OrdBund.[Group] IS NOT NULL THEN TB_OrdBund.[Group]
                                                        WHEN L2.[GroupID]             = 'SAMPLE'       THEN 'SAMPLE'
                                                        WHEN L2.[GroupID]             = 'BRNSM'        THEN 'Barnesmith'
                                                        WHEN L2.[GroupID]             = 'ACADEM'       THEN 'Academy'
                                                        WHEN LEFT(L2.[StyleID],2)     = 'RW'           THEN 'Redshirt'
                                                        WHEN LEFT(L2.[StyleID],2)     = 'FR'           THEN 'Fall Rush'
                                                        WHEN LEFT(L2.[StyleID],3)     = 'NDS'          THEN 'ND The Shirt'
                                                        WHEN LEFT(L2.[StyleID],3)     = 'MST'          THEN 'Masters'
                                                        WHEN LEFT(L2.[StyleID],2)     = 'CB'           THEN 'Casa Bonita'
                                                        WHEN LEFT(L2.[StyleID],2)     = 'RH'           THEN 'Rally House'
                                                        WHEN LEFT(L2.[StyleID],2)     = 'LC'           THEN 'LOCALE'
                                                        WHEN LEFT(L2.[StyleID],2)     = 'UW'           THEN 'Unwind'
                                                        WHEN RIGHT(L2.[StyleID],3)    = 'PDT'          THEN 'Pigment Dye'
                                                        WHEN UPPER(L2.[SalesChannel]) = 'DESTINATION'  THEN 'Resort'         ---agregada 20230718
                                                        ELSE B.[GRDescription]
                                                    END        
                FROM #TB_BACKLOG_L2BRAND_ACTIVE AS L2
                LEFT JOIN #TB_GROUPID           AS B ON L2.[GroupID]      = B.[GroupID]
                
                UPDATE S SET
                    [window]        = CASE
                                        WHEN S.[RS_Priority] = 'SWR' THEN DATEADD(DAY,-28,S.[DueDate])
                                        WHEN S.[RS_Priority] = 'DSE' THEN DATEADD(DAY, -7,S.[DueDate])
                                        ELSE DATEADD(DAY,-21,S.[DueDate])
                                        END
                FROM #TB_BACKLOG_L2BRAND_ACTIVE AS S
                
                DROP TABLE IF EXISTS #TB_LOOKUP_LOGOSTYLEAPPLICATION
                    SELECT  
                     [LogoStyle]              = CAST([LogoStyle]             AS VARCHAR(20) )
                   
					,[ScreenPrintAfter]		 = CASE WHEN
					                                ( [OrderTypeDescription] like '%To Print%' 
													and ([ApplicationOrder] is null or  [ApplicationOrder] = 'AFTER')
													)
													OR 
													([LogoStyle] = 'DTG')
												THEN 1
												ELSE 0 END
					,[ScreenPrintBefore]	 = CASE WHEN [OrderTypeDescription] like '%To Print%' 
													and ([ApplicationOrder] = 'BEFORE')
												THEN 1
												ELSE 0 END
					,[Embroidery]			= CASE WHEN [OrderTypeDescription] like '%To Embroidery%' 
												THEN 1
												ELSE 0 END
					,[SublimationBefore]	= CASE WHEN [OrderTypeDescription] like '%To Sublimation%' 
													AND ([ApplicationOrder] = '' OR [ApplicationOrder] = 'BEFORE' )
												THEN 1
												ELSE 0 END
					,[SublimationAfter]		= CASE WHEN [OrderTypeDescription] like '%To Sublimation%' 
													AND ([ApplicationOrder] = 'AFTER' )
												THEN 1
												ELSE 0 END
					,[HDP]				= CASE WHEN [OrderTypeDescription] like '%Only DHT%' AND [LogoStyle] <> 'DTG'
												THEN 1
												ELSE 0 END
					,[Blanks]				= CASE WHEN [OrderTypeDescription] like '%Blanks%' 
												THEN 1
												ELSE 0 END
					--,*
                INTO #TB_LOOKUP_LOGOSTYLEAPPLICATION
                FROM OPENQUERY([MARIADB],'SELECT * FROM wordpress.L2Brands_LogoStyle')  AS TBM



                DROP TABLE IF EXISTS #TB_BACKLOG_L2BRAND_ACTIVE_LOGOSTYLE_APPLICATION
                SELECT
    				 [ItemDetailID]         = [ItemDetailID]
    				,[ScreenPrintAfter]		= SUM([ScreenPrintAfter]	)
                    ,[ScreenPrintBefore]	= SUM([ScreenPrintBefore]	)
                    ,[Embroidery]			= SUM([Embroidery]			)
                    ,[SublimationBefore]	= SUM([SublimationBefore]	)
                    ,[SublimationAfter]		= SUM([SublimationAfter]	)
                    ,[HDP]				= SUM([HDP]			)
                    ,[Blanks]				= SUM([Blanks]				)
    			INTO #TB_BACKLOG_L2BRAND_ACTIVE_LOGOSTYLE_APPLICATION
    			FROM(    
        				SELECT
        				     [ItemDetailID]         = t.[ItemDetailID]
        				    ,[ScreenPrintAfter]		= tb_Emb.[ScreenPrintAfter]
                            ,[ScreenPrintBefore]	= tb_Emb.[ScreenPrintBefore]
                            ,[Embroidery]			= tb_Emb.[Embroidery]
                            ,[SublimationBefore]	= tb_Emb.[SublimationBefore]
                            ,[SublimationAfter]		= tb_Emb.[SublimationAfter]
                            ,[HDP]				= tb_Emb.[HDP]
                            ,[Blanks]				= tb_Emb.[Blanks]
        				FROM #TB_BACKLOG_L2BRAND_ACTIVE AS t
        				CROSS APPLY STRING_SPLIT(t.[ApplicationType], ',') AS split_values
        				LEFT JOIN  #TB_LOOKUP_LOGOSTYLEAPPLICATION AS tb_Emb on tb_Emb.[LogoStyle] = split_values.[value]
            		)AS f
            		--  where ItemDetailID = '5476707'
            		GROUP BY [ItemDetailID]

                -- Actualizar #TB_BACKLOG_L2BRAND_ACTIVE con los valores calculados de LogoStyle/Application
                UPDATE L2
                SET  [ScreenPrintAfter]     = ISNULL(APP.[ScreenPrintAfter],  0)
                    ,[ScreenPrintBefore]    = ISNULL(APP.[ScreenPrintBefore], 0)
                    ,[Embroidery]           = ISNULL(APP.[Embroidery],        0)
                    ,[SublimationBefore]    = ISNULL(APP.[SublimationBefore], 0)
                    ,[SublimationAfter]     = ISNULL(APP.[SublimationAfter],  0)
                    ,[HDP]                  = ISNULL(APP.[HDP],          0)
                    ,[Blanks]               = ISNULL(APP.[Blanks],            0)
                    -- ,[ScreenPrint]          = CAST(IIF(ISNULL(APP.[ScreenPrintAfter],0) > 0 OR ISNULL(APP.[ScreenPrintBefore],0) > 0, 1, 0) AS INT)---cambio SCREENPRINT
                    ,[ScreenPrint]          = CAST(ISNULL(APP.[ScreenPrintAfter],0) + ISNULL(APP.[ScreenPrintBefore],0) AS INT)
                FROM #TB_BACKLOG_L2BRAND_ACTIVE AS L2
                INNER JOIN #TB_BACKLOG_L2BRAND_ACTIVE_LOGOSTYLE_APPLICATION AS APP
                    ON APP.[ItemDetailID] = L2.[ItemDetailID]

-- [ScreenPrint]              --Para type seria: Screen Print (no aparece porque esta desglozado por after y before)
-- [ScreenPrintAfter]         --Para type seria: Screen Print After
-- [ScreenPrintBefore]        --Para type seria: Screen Print Before

-- [Embroidery]               --Para type seria: Embroidery (ya no apareceria, solo si no entra en ningun por la technica)
-- [EmbHWApplique]            --Para type seria: Embroidery HW Applique
-- [EmbHWDirect]              --Para type seria: Embroidery HW Direct
-- [EmbHWPatch]               --Para type seria: Embroidery HW Patch
-- [EmbHWHDP]                 --Para type seria: Embroidery HW HDP

-- [EmbAppDirect]             --Para type seria: Embroidery APP Direct
-- [EmbAppLBA]                --Para type seria: Embroidery APP LBA

-- [SublimationBefore]        --Para type seria: Sublimation Before
-- [SublimationAfter]         --Para type seria: Sublimation After
-- [HDP]                      --Para type seria: High Definition Print
-- [Blanks]                   --Para type seria: Blanks

                -- Actualizar [TypeEmbroidery] clasificando el tipo de bordado/aplicacion por ApplicationType
                DROP TABLE IF EXISTS #TB_LOOKUP_TYPEEMBROIDERY
                SELECT [LogoStyle] = [Code], [Category], [Technique], [IsHeadwear] = CAST(1 AS BIT)
                INTO #TB_LOOKUP_TYPEEMBROIDERY
                FROM [192.168.1.93].[AppsLCA].[dbo].[PBI_EMH_CodeClasif] WITH(NOLOCK)

                INSERT INTO #TB_LOOKUP_TYPEEMBROIDERY
                SELECT [LogoStyle]  = lam.[LogoStyle]
                      ,[Category]   = CASE WHEN lam.[AppliqueMaterial] = 'Direct' OR lam.[AppliqueMaterial] IS NULL THEN 'Direct' ELSE 'LBA' END
                      ,[Technique]  = CASE WHEN lam.[AppliqueMaterial] = 'Direct' OR lam.[AppliqueMaterial] IS NULL THEN 'Direct' ELSE 'LBA' END
                      ,[IsHeadwear] = CAST(0 AS BIT)
                FROM [192.168.1.93].[AppsLCA].[dbo].[PBI_EMB_LogoApliqueMaterial] AS lam WITH(NOLOCK)

                UPDATE L2
                SET [TypeEmbroidery] = NULLIF(STUFF((
                    SELECT DISTINCT ',' + LTE.[Category]
                    FROM STRING_SPLIT(ISNULL(L2.[ApplicationType],''), ',') AS sv
                    INNER JOIN #TB_LOOKUP_TYPEEMBROIDERY AS LTE
                        ON LTE.[LogoStyle]   = TRIM(sv.[value])
                        AND LTE.[IsHeadwear] = CAST(IIF(L2.[ProductDivision] IN ('Headwear','Winter Knits'), 1, 0) AS BIT)
                    FOR XML PATH(''), TYPE
                ).value('.','VARCHAR(MAX)'), 1, 1, ''), '')
                FROM #TB_BACKLOG_L2BRAND_ACTIVE AS L2
                WHERE L2.[ApplicationType] IS NOT NULL AND L2.[ApplicationType] <> ''

                -- Agregacion de Emb* por ItemDetailID
                DROP TABLE IF EXISTS #TB_BACKLOG_EMBCATEGORY
                SELECT
                     [ItemDetailID]
                    ,[EmbHWApplique] = SUM(CASE WHEN LTE.[IsHeadwear] = 1 AND LTE.[Category] = 'Applique' THEN 1 ELSE 0 END)
                    ,[EmbHWDirect]   = SUM(CASE WHEN LTE.[IsHeadwear] = 1 AND LTE.[Category] = 'Direct'   THEN 1 ELSE 0 END)
                    ,[EmbHWPatch]    = SUM(CASE WHEN LTE.[IsHeadwear] = 1 AND LTE.[Category] = 'Patch'    THEN 1 ELSE 0 END)
                    ,[EmbHWHDP]      = SUM(CASE WHEN LTE.[IsHeadwear] = 1 AND LTE.[Category] = 'Transfer' THEN 1 ELSE 0 END)
                    ,[EmbAppDirect]  = SUM(CASE WHEN LTE.[IsHeadwear] = 0 AND LTE.[Category] = 'Direct'   THEN 1 ELSE 0 END)
                    ,[EmbAppLBA]     = SUM(CASE WHEN LTE.[IsHeadwear] = 0 AND LTE.[Category] = 'LBA'      THEN 1 ELSE 0 END)
                INTO #TB_BACKLOG_EMBCATEGORY
                FROM #TB_BACKLOG_L2BRAND_ACTIVE AS L2
                CROSS APPLY STRING_SPLIT(ISNULL(L2.[ApplicationType],''), ',') AS sv
                INNER JOIN #TB_LOOKUP_TYPEEMBROIDERY AS LTE
                    ON LTE.[LogoStyle]   = TRIM(sv.[value])
                    AND LTE.[IsHeadwear] = CAST(IIF(L2.[ProductDivision] IN ('Headwear','Winter Knits'), 1, 0) AS BIT)
                WHERE L2.[ApplicationType] IS NOT NULL AND L2.[ApplicationType] <> ''
                GROUP BY L2.[ItemDetailID]

                UPDATE L2
                SET [EmbHWApplique] = ISNULL(EMB.[EmbHWApplique], 0)
                   ,[EmbHWDirect]   = ISNULL(EMB.[EmbHWDirect],   0)
                   ,[EmbHWPatch]    = ISNULL(EMB.[EmbHWPatch],     0)
                   ,[EmbHWHDP]      = ISNULL(EMB.[EmbHWHDP],       0)
                   ,[EmbAppDirect]  = ISNULL(EMB.[EmbAppDirect],   0)
                   ,[EmbAppLBA]     = ISNULL(EMB.[EmbAppLBA],      0)
                   ,[HDP]           = IIF(L2.[ProductDivision] IN ('Headwear','Winter Knits'),0, ISNULL(L2.[HDP],          0))
                FROM #TB_BACKLOG_L2BRAND_ACTIVE AS L2
                LEFT JOIN #TB_BACKLOG_EMBCATEGORY AS EMB ON EMB.[ItemDetailID] = L2.[ItemDetailID]

                DROP TABLE IF EXISTS #TB_BACKLOG_EMBCATEGORY

                -- Actualizar [Technique] con las tecnicas de bordado concatenadas
                UPDATE L2
                SET [Technique] = NULLIF(STUFF((
                    SELECT DISTINCT ',' + LTE.[Technique]
                    FROM STRING_SPLIT(ISNULL(L2.[ApplicationType],''), ',') AS sv
                    INNER JOIN #TB_LOOKUP_TYPEEMBROIDERY AS LTE
                        ON LTE.[LogoStyle]   = TRIM(sv.[value])
                        AND LTE.[IsHeadwear] = CAST(IIF(L2.[ProductDivision] IN ('Headwear','Winter Knits'), 1, 0) AS BIT)
                    FOR XML PATH(''), TYPE
                ).value('.','VARCHAR(MAX)'), 1, 1, ''), '')
                FROM #TB_BACKLOG_L2BRAND_ACTIVE AS L2
                WHERE L2.[ApplicationType] IS NOT NULL AND L2.[ApplicationType] <> ''

                DROP TABLE IF EXISTS #TB_LOOKUP_TYPEEMBROIDERY

                -- Actualizar [Type] con todos los procesos activos incluyendo desglose de bordado
                UPDATE L2
                SET [Type] = NULLIF(STUFF(
                      CASE WHEN L2.[ScreenPrintAfter]  > 0 THEN ',Screen Print After'     ELSE '' END
                    + CASE WHEN L2.[ScreenPrintBefore] > 0 THEN ',Screen Print Before'    ELSE '' END
                    -- + CASE WHEN L2.[Embroidery]        > 0 THEN ',Embroidery'             ELSE '' END
                    + CASE WHEN L2.[EmbHWApplique]     > 0 THEN ',Embroidery HW Applique' ELSE '' END
                    + CASE WHEN L2.[EmbHWDirect]       > 0 THEN ',Embroidery HW Direct'   ELSE '' END
                    + CASE WHEN L2.[EmbHWPatch]        > 0 THEN ',Embroidery HW Patch'    ELSE '' END
                    + CASE WHEN L2.[EmbHWHDP]          > 0 THEN ',Embroidery HW HDP'      ELSE '' END
                    + CASE WHEN L2.[EmbAppDirect]      > 0 THEN ',Embroidery APP Direct'  ELSE '' END
                    + CASE WHEN L2.[EmbAppLBA]         > 0 THEN ',Embroidery APP LBA'     ELSE '' END
                    + CASE WHEN L2.[SublimationBefore] > 0 THEN ',Sublimation Before'     ELSE '' END
                    + CASE WHEN L2.[SublimationAfter]  > 0 THEN ',Sublimation After'      ELSE '' END
                    + CASE WHEN L2.[HDP]               > 0 AND  L2.[ProductDivision] NOT IN ('Headwear','Winter Knits') THEN ',High Definition Print'  ELSE '' END
                    + CASE WHEN L2.[Blanks]            > 0 THEN ',Blanks'                 ELSE '' END
                , 1, 1, ''), '')
                FROM #TB_BACKLOG_L2BRAND_ACTIVE AS L2

                
                UPDATE S
                SET [Type] = 'Technique not defined'
                FROM #TB_BACKLOG_L2BRAND_ACTIVE AS S
                WHERE S.[Type] = '' OR S.[Type] IS NULL
                -- return
            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA ORDENES ACTIVAS EN L2BRAND--------------------------------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
         
           
            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA INVENTARIO RELEASED Y FORECAST (BASE POR TALLA)----------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE RELEASED/FORECAST POR TALLA')
                UPDATE [AppsLCA].[dbo].[TB_Global_Process]
                SET [Percent] = 84,
                    [StepCode] = 'BACKLOG',
                    [StepNameUser] = 'Generando backlog',
                    [MessageUser] = 'Estamos preparando la base activa de LCA para backlog. Ordenes Released/Forecast por talla.',
                    [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE RELEASED/FORECAST POR TALLA'),500),
                    [UpdatedAt] = SYSDATETIME()
                WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;

                -- PROCESO BASE-1: Construir tabla base por talla para MOs Released/Forecast
                -- Incluye cruce contra backlog activo L2Brand y datos produccion por talla.
                -- Filtros utilizados:
                --   - StatusID de MO en (20,40) [Released, Forecast]
                --   - MD.QuantityOrdered > 0
                --   - Coincidencia obligatoria con #TB_BACKLOG_L2BRAND_ACTIVE por ItemDetailID
                DROP TABLE IF EXISTS #TB_BACKLOG_INV_01_RF
                SELECT
                     [RowData]                    = ROW_NUMBER() OVER(ORDER BY BL.[DueDate] ASC , BL.[Order_No] ASC, ORD_MAP.[ItemDetailID] ASC, MO.[ManufactureID] ASC)
                    ,[DueDate]                    = BL.[DueDate]
                    ,[CustomerOrder]              = BL.[CustomerOrder]
                    ,[Order_No]                   = BL.[Order_No]
                    ,[ItemDetailID]               = ORD_MAP.[ItemDetailID]
                    ,[ManufactureID]              = MO.[ManufactureID]
                    ,[MO]                         = MO.[ManufactureNumber]
                    ,[BundleID]                   = CAST(NULL AS INT)
                    ,[BundleBarcode]              = CAST(NULL AS VARCHAR(200))
                    ,[BoxID]                      = CAST(NULL AS INT)
                    ,[BoxNumber]                  = CAST(NULL AS VARCHAR(200))
                    ,[FormattedBoxNumber]         = CAST(NULL AS VARCHAR(200))
                    ,[RequiredDate]               = COALESCE( CAST(OI.[requiredDate] AS DATE) ,CAST(ORD.[requiredDate] AS DATE))
                    ,[PONumber]                   = ORD.[PONumber]
                    ,[Style]                      = ST.[StyleNumber]
                    ,[Season]                     = SEAS.[SeasonName]
                    ,[Color]                      = STC.[StyleColorName]
                    ,[Size]                       = FG.[GarmentSize]
                    ,[Quantity]                   = SUM(MD.[QuantityOrdered])
                    ,[OriginalQuantity]           = SUM(MD.[QuantityOrdered])
                    ,[QtyWithDraw]                = CAST(0 AS INT)
                    ,[Status]                     = SN.[StatusName]
                    ,[ProductionStatus]           = PST.[DropDownValue]
                    ,[PreviewLCAComments]         = REPLACE(REPLACE(REPLACE(PST.[Description],CHAR(10),''),CHAR(9),''),CHAR(13),'')
                    ,[OrderID]                    = ORD.[OrderID]
                    ,[Bucket]                     = REPLACE(MO.[Comments3],'BU ','')
                    ,[StyleSubcategory]           = STCT.[StyleSubcategoryName]
                    ,[StockCategory]              = ISNULL(STRG.[RegionName],'')
                    ,[APS]                        = ORD.[Comments6]
                    ,[Collection]                 = STCL.[CollectionName]
                    ,[PWModulo]                   = MO.[Comments7]
                    ,[Availability]               = MO.[PlanTransferCost]
                    ,[SewingDate]                 = CAST(MO.[SchedFinish] AS DATE)
                    ,[FabricDD]                   = REPLACE(REPLACE(REPLACE(MO.[Comments8], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')
                    ,[Waybill]                    = CAST(NULL AS VARCHAR(200))
                    ,[ShipDate]                   = CAST(NULL AS DATE)

                INTO #TB_BACKLOG_INV_01_RF
                FROM (SELECT [StatusID],[StatusName] FROM [LCA].[dbo].[StatusNames] WITH(NOLOCK) WHERE [StatusID] IN(20,40)) AS SN
                INNER JOIN [LCA].[dbo].[ManufactureOrders]      AS MO    WITH(NOLOCK) ON SN.[StatusID]          = MO.[StatusID]      AND MO.[StatusID] IN(20,40)
                INNER JOIN [LCA].[dbo].[ManufactureDetails]     AS MD    WITH(NOLOCK) ON MD.[ManufactureID]     = MO.[ManufactureID] AND MD.[QuantityOrdered] > 0
                LEFT JOIN  [LCA].[dbo].[FinishedGoods]          AS FG    WITH(NOLOCK) ON FG.[FinishedGoodsID]   = MD.[FinishedGoodsID]
                LEFT JOIN  [LCA].[dbo].[StyleColors]            AS STC   WITH(NOLOCK) ON STC.[StyleColorID]     = FG.[StyleColorID]
                LEFT JOIN  [LCA].[dbo].[Styles]                 AS ST    WITH(NOLOCK) ON ST.[StyleID]           = FG.[StyleID]
                LEFT JOIN  [LCA].[dbo].[Seasons]                AS SEAS  WITH(NOLOCK) ON SEAS.[SeasonID]        = ST.[SeasonID]
                LEFT JOIN  [LCA].[dbo].[Orders]                 AS ORD   WITH(NOLOCK) ON ORD.[OrderID]          = MO.[OrderID]
                LEFT JOIN  [LCA].[dbo].[StyleCategories]        AS STCT  WITH(NOLOCK) ON STCT.[StyleCategoryID] = ST.[StyleCategoryID]
                LEFT JOIN  [LCA].[dbo].[StyleRegions]           AS STRG  WITH(NOLOCK) ON STRG.[RegionID]        = ST.[RegionID]
                LEFT JOIN  [LCA].[dbo].[OrderItems]             AS OI    WITH(NOLOCK) ON OI.[OrderItemID]       = MO.[FirstOrderItemID]
                LEFT JOIN  [LCA].[dbo].[StyleCollections]       AS STCL  WITH(NOLOCK) ON ST.[CollectionID]      = STCL.[CollectionID]
                LEFT JOIN  [LCA].[dbo].[DropDownValues3]        AS PST   WITH(NOLOCK) ON PST.[DropDownValueID]  = MO.[ProductionStatusID]
                CROSS APPLY (
                    SELECT [ItemDetailID] = CASE
                        WHEN ORD.[PONumber] LIKE 'ORD-PO%' THEN NULL
                        WHEN ORD.[PONumber] LIKE 'ORD-%' AND ISNUMERIC(REPLACE(ORD.[PONumber],'ORD-','')) = 1 THEN TRY_CAST(REPLACE(ORD.[PONumber],'ORD-','') AS BIGINT)
                        WHEN ORD.[PONumber] LIKE 'ORD%' AND ISNUMERIC(ORD.[Comments6]) = 1 THEN TRY_CAST(ORD.[Comments6] AS BIGINT)
                        ELSE NULL
                    END
                ) AS ORD_MAP
                INNER JOIN #TB_BACKLOG_L2BRAND_ACTIVE AS BL ON BL.[ItemDetailID] = ORD_MAP.[ItemDetailID]
                GROUP BY
                    BL.[DueDate]
                    ,BL.[CustomerOrder]
                    ,BL.[Order_No]
                    ,ORD_MAP.[ItemDetailID]
                    ,MO.[ManufactureID]
                    ,MO.[ManufactureNumber]
                    ,COALESCE( CAST(OI.[requiredDate] AS DATE) ,CAST(ORD.[requiredDate] AS DATE))
                    ,ORD.[PONumber]
                    ,ST.[StyleNumber]
                    ,SEAS.[SeasonName]
                    ,STC.[StyleColorName]
                    ,FG.[GarmentSize]
                    -- ,SUM(MD.[QuantityOrdered])
                    -- ,SUM(MD.[QuantityOrdered])
                    -- ,CAST(0 AS INT)
                    ,SN.[StatusName]
                    ,PST.[DropDownValue]
                    ,REPLACE(REPLACE(REPLACE(PST.[Description],CHAR(10),''),CHAR(9),''),CHAR(13),'')
                    ,ORD.[OrderID]
                    ,REPLACE(MO.[Comments3],'BU ','')
                    ,STCT.[StyleSubcategoryName]
                    ,ISNULL(STRG.[RegionName],'')
                    ,ORD.[Comments6]
                    ,STCL.[CollectionName]
                    ,MO.[Comments7]
                    ,MO.[PlanTransferCost]
                    ,CAST(MO.[SchedFinish] AS DATE)
                    ,REPLACE(REPLACE(REPLACE(MO.[Comments8], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')
                    
    -- SELECT * FROM #TB_BACKLOG_INV_01_RF
    -- WHERE ItemDetailID = 5599936
    -- RETURN        
            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA INVENTARIO RELEASED Y FORECAST (BASE POR TALLA)----------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA GENERACION DE BACKLOG. EXCLUIR MOS CON BULTOS')

                -- PROCESO BASE-2: Excluir MOs que ya tienen bultos creados
                -- Estos registros se manejan en el flujo de inventario por bulto y no deben duplicarse.
                -- Filtro utilizado:
                --   - EXISTS Bundles por ManufactureID
                DELETE S
                FROM #TB_BACKLOG_INV_01_RF AS S
                WHERE EXISTS (
                    SELECT 1
                    FROM [LCA].[dbo].[Bundles] AS B WITH(NOLOCK)
                    WHERE B.[ManufactureID] = S.[ManufactureID]
                )

            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA INVENTARIO RELEASED Y FORECAST (WITHDRAW Y RESTANTE)------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA GENERACION DE BACKLOG. WITHDRAW Y RESTANTE EN RELEASED/FORECAST')
                 UPDATE [AppsLCA].[dbo].[TB_Global_Process]
                SET [Percent] = 86,
                    [StepCode] = 'BACKLOG',
                    [StepNameUser] = 'Generando backlog',
                    [MessageUser] = 'Estamos preparando la base activa de LCA para backlog. Ajuste de cantidad por unidades despachadas',
                    [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE RELEASED/FORECAST POR TALLA'),500),
                    [UpdatedAt] = SYSDATETIME()
                WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
                -- PROCESO RF-WR-1: Calcular QtyWithDraw por ManufactureID y Size
                -- Fuente: ManufactureBlanks + FinishedGoods para distribuir el withdraw por talla.
                -- Filtros utilizados:
                --   - Universo base: ManufactureID de #TB_BACKLOG_INV_01_RF
                --   - MO.StatusID < 90
                DROP TABLE IF EXISTS #TB_BACKLOG_LOOKUP_MO_SIZE_WITHDRAW
                SELECT
                     [ManufactureID] = MO.[ManufactureID]
                    ,[Size]          = FG.[GarmentSize]
                    ,[QtyWithDraw]   = SUM(ISNULL(MB.[QuantityWithdrawn],0))
                INTO #TB_BACKLOG_LOOKUP_MO_SIZE_WITHDRAW
                FROM (
                    SELECT DISTINCT
                         [ManufactureID]
                    FROM #TB_BACKLOG_INV_01_RF
                ) AS S
                INNER JOIN [LCA].[dbo].[ManufactureOrders] AS MO WITH(NOLOCK)   ON MO.[ManufactureID] = S.[ManufactureID] AND MO.[StatusID] < 90
                INNER JOIN [LCA].[dbo].[ManufactureBlanks] AS MB WITH(NOLOCK)   ON MB.[ManufactureID] = MO.[ManufactureID]
                INNER JOIN [LCA].[dbo].[FinishedGoods]     AS FG WITH(NOLOCK)   ON FG.[FinishedGoodsID] = MB.[FinishedGoodsID]
                GROUP BY
                     MO.[ManufactureID]
                    ,FG.[GarmentSize]

                -- PROCESO RF-WR-2: Aplicar QtyWithDraw a la base RF y recalcular Quantity restante
                UPDATE T
                SET
                     [QtyWithDraw] = ISNULL(W.[QtyWithDraw],0)
                    ,[Quantity]    = CASE
                                        WHEN ISNULL(T.[OriginalQuantity],0) - ISNULL(W.[QtyWithDraw],0) < 0 THEN 0
                                        ELSE ISNULL(T.[OriginalQuantity],0) - ISNULL(W.[QtyWithDraw],0)
                                     END
                FROM #TB_BACKLOG_INV_01_RF AS T
                LEFT JOIN #TB_BACKLOG_LOOKUP_MO_SIZE_WITHDRAW AS W ON W.[ManufactureID] = T.[ManufactureID] AND W.[Size] = T.[Size]

                -- PROCESO RF-WR-3: Generar datasets REMAIN y WITHDRAW desde la base RF ajustada
                -- 1) REMAIN   => Quantity = OriginalQuantity - QtyWithDraw (minimo 0)
                -- 2) WITHDRAW => Quantity = QtyWithDraw
                -- Filtros utilizados:
                --   - REMAIN: (OriginalQuantity - QtyWithDraw) > 0
                --   - WITHDRAW: QtyWithDraw > 0
                DROP TABLE IF EXISTS #TB_BACKLOG_INV_01_RF_REMAIN
                DROP TABLE IF EXISTS #TB_BACKLOG_INV_01_RF_WITHDRAW

                SELECT
                     *
                INTO #TB_BACKLOG_INV_01_RF_REMAIN
                FROM #TB_BACKLOG_INV_01_RF
                WHERE
                    CASE
                        WHEN ISNULL([OriginalQuantity],0) - ISNULL([QtyWithDraw],0) < 0 THEN 0
                        ELSE ISNULL([OriginalQuantity],0) - ISNULL([QtyWithDraw],0)
                    END > 0

                UPDATE R
                SET
                     [Quantity] = CASE
                                    WHEN ISNULL(R.[OriginalQuantity],0) - ISNULL(R.[QtyWithDraw],0) < 0 THEN 0
                                    ELSE ISNULL(R.[OriginalQuantity],0) - ISNULL(R.[QtyWithDraw],0)
                                  END
                FROM #TB_BACKLOG_INV_01_RF_REMAIN AS R

                SELECT
                     *
                INTO #TB_BACKLOG_INV_01_RF_WITHDRAW
                FROM #TB_BACKLOG_INV_01_RF
                WHERE ISNULL([QtyWithDraw],0) > 0

                UPDATE W
                SET
                     [Quantity] = ISNULL(W.[QtyWithDraw],0)
                FROM #TB_BACKLOG_INV_01_RF_WITHDRAW AS W


                
                -- PROCESO RF-WR-4: Insertar REMAIN y WITHDRAW en tabla unificada final
                -- Layout final:
                --   1) [R] (orden final global)
                --   2) [RowData]
                --   3) [InventoryLineTypeN]
                --   4) resto de columnas
                DROP TABLE IF EXISTS #TB_BACKLOG_INVENTORY_UNIFIED
                CREATE TABLE #TB_BACKLOG_INVENTORY_UNIFIED
                (
                     [R]                                BIGINT          NULL
                    ,[RowData]                          BIGINT          NULL
                    ,[InventoryLineTypeN]               INT             NULL
                    ,[InventoryLineType]                VARCHAR(50)     NULL
                    ,[DueDate]                          DATE            NULL
                    ,[CustomerOrder]                    VARCHAR(100)    NULL
                    ,[Order_No]                         VARCHAR(100)    NULL
                    ,[ItemDetailID]                     BIGINT          NULL
                    ,[OrderID]                          INT             NULL
                    ,[PONumber]                         VARCHAR(100)    NULL
                    ,[RequiredDate]                     DATE            NULL
                    ,[ManufactureID]                    INT             NULL
                    ,[MO]                               VARCHAR(100)    NULL
                    ,[Style]                            VARCHAR(100)    NULL
                    ,[Season]                           VARCHAR(100)    NULL
                    ,[Color]                            VARCHAR(100)    NULL
                    ,[Size]                             VARCHAR(50)     NULL
                    ,[Quantity]                         FLOAT           NULL
                    ,[OriginalQuantity]                 FLOAT           NULL
                    ,[QtyWithDraw]                      FLOAT           NULL
                    ,[BundleID]                         INT             NULL
                    ,[BundleBarcode]                    VARCHAR(200)    NULL
                    ,[BoxID]                            INT             NULL
                    ,[BoxNumber]                        VARCHAR(200)    NULL
                    ,[FormattedBoxNumber]               VARCHAR(200)    NULL
                    ,[Status]                           VARCHAR(100)    NULL
                    ,[ProductionStatus]                 VARCHAR(200)    NULL
                    ,[StyleSubcategory]                 VARCHAR(100)    NULL
                    ,[StockCategory]                    VARCHAR(100)    NULL
                    ,[Collection]                       VARCHAR(100)    NULL
                    ,[PWModulo]                         VARCHAR(100)    NULL
                    ,[Bucket]                           VARCHAR(100)    NULL
                    ,[NewBucket]                        VARCHAR(100)    NULL
                    ,[FabricDD]                         VARCHAR(200)    NULL
                    ,[SewingDate]                       DATE            NULL
                    ,[Inv_Pack_Date]                    DATE            NULL
                    ,[Availability]                     FLOAT           NULL
                    ,[ProductDivision]                  VARCHAR(100)    NULL
                    ,[Waybill]                          VARCHAR(200)    NULL
                    ,[ShipDate]                         DATE            NULL
                    ,[discard_by_percentage]            DECIMAL(10,4)   NULL
                    ,[DateArriveInPackingForOrder]      DATE            NULL
                    ,[PreviewLCAComments]               VARCHAR(MAX)    NULL
                    ,[LCAComments]                      VARCHAR(200)    NULL
                    ,[TakeForProcedure]                 INT             NULL
                    ,[DateForConteiner]                 DATE            NULL
                    ,[LateOrder]                        INT             NULL
                    ,[DaysLateOrder]                    INT             NULL
                )
                
                UPDATE [AppsLCA].[dbo].[TB_Global_Process]
                SET [Percent] = 87,
                    [StepCode] = 'BACKLOG',
                    [StepNameUser] = 'Generando backlog',
                    [MessageUser] = 'Preparando base LCA para backlog. Ordenes sin despacho (REMAIN).',
                    [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE RELEASED/FORECAST POR TALLA'),500),
                    [UpdatedAt] = SYSDATETIME()
                WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
                
                INSERT INTO #TB_BACKLOG_INVENTORY_UNIFIED
                (
                     [R]
                    ,[RowData]
                    ,[InventoryLineTypeN]
                    ,[InventoryLineType]
                    ,[DueDate]
                    ,[CustomerOrder]
                    ,[Order_No]
                    ,[ItemDetailID]
                    ,[ManufactureID]
                    ,[MO]
                    ,[BundleID]
                    ,[BundleBarcode]
                    ,[BoxID]
                    ,[BoxNumber]
                    ,[FormattedBoxNumber]
                    ,[RequiredDate]
                    ,[PONumber]
                    ,[Style]
                    ,[Season]
                    ,[Color]
                    ,[Size]
                    ,[Quantity]
                    ,[OriginalQuantity]
                    ,[QtyWithDraw]
                    ,[Status]
                    ,[ProductionStatus]
                    ,[PreviewLCAComments]
                    ,[OrderID]
                    ,[Bucket]
                    ,[StyleSubcategory]
                    ,[StockCategory]
                    ,[Collection]
                    ,[PWModulo]
                    ,[Availability]
                    ,[SewingDate]
                    ,[FabricDD]
                    ,[Waybill]
                    ,[ShipDate]
                )
                SELECT
                     [R]                    = CAST(NULL AS BIGINT)
                    ,[RowData]              = R.[RowData]
                    ,[InventoryLineTypeN]   = CAST(1 AS INT)
                    ,[InventoryLineType]    = CAST('REMAIN' AS VARCHAR(50))
                    ,[DueDate]              = R.[DueDate]
                    ,[CustomerOrder]        = R.[CustomerOrder]
                    ,[Order_No]             = R.[Order_No]
                    ,[ItemDetailID]         = R.[ItemDetailID]
                    ,[ManufactureID]        = R.[ManufactureID]
                    ,[MO]                   = R.[MO]
                    ,[BundleID]             = R.[BundleID]
                    ,[BundleBarcode]        = R.[BundleBarcode]
                    ,[BoxID]                = R.[BoxID]
                    ,[BoxNumber]            = R.[BoxNumber]
                    ,[FormattedBoxNumber]   = R.[FormattedBoxNumber]
                    ,[RequiredDate]         = R.[RequiredDate]
                    ,[PONumber]             = R.[PONumber]
                    ,[Style]                = R.[Style]
                    ,[Season]               = R.[Season]
                    ,[Color]                = R.[Color]
                    ,[Size]                 = R.[Size]
                    ,[Quantity]             = R.[Quantity]
                    ,[OriginalQuantity]     = R.[OriginalQuantity]
                    ,[QtyWithDraw]          = R.[QtyWithDraw]
                    ,[Status]               = R.[Status]
                    ,[ProductionStatus]     = R.[ProductionStatus]
                    ,[PreviewLCAComments]   = R.[PreviewLCAComments]
                    ,[OrderID]              = R.[OrderID]
                    ,[Bucket]               = R.[Bucket]
                    ,[StyleSubcategory]     = R.[StyleSubcategory]
                    ,[StockCategory]        = R.[StockCategory]
                    ,[Collection]           = R.[Collection]
                    ,[PWModulo]             = R.[PWModulo]
                    ,[Availability]         = R.[Availability]
                    ,[SewingDate]           = R.[SewingDate]
                    ,[FabricDD]             = R.[FabricDD]
                    ,[Waybill]              = R.[Waybill]
                    ,[ShipDate]             = R.[ShipDate]
                FROM #TB_BACKLOG_INV_01_RF_REMAIN AS R
 
                UPDATE [AppsLCA].[dbo].[TB_Global_Process]
                SET [Percent] = 88,
                    [StepCode] = 'BACKLOG',
                    [StepNameUser] = 'Generando backlog',
                    [MessageUser] = 'Preparando base LCA para backlog. Ordenes con despacho (WITHDRAW).',
                    [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE RELEASED/FORECAST POR TALLA'),500),
                    [UpdatedAt] = SYSDATETIME()
                WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
                INSERT INTO #TB_BACKLOG_INVENTORY_UNIFIED
                (
                     [R]
                    ,[RowData]
                    ,[InventoryLineTypeN]
                    ,[InventoryLineType]
                    ,[DueDate]
                    ,[CustomerOrder]
                    ,[Order_No]
                    ,[ItemDetailID]
                    ,[ManufactureID]
                    ,[MO]
                    ,[BundleID]
                    ,[BundleBarcode]
                    ,[BoxID]
                    ,[BoxNumber]
                    ,[FormattedBoxNumber]
                    ,[RequiredDate]
                    ,[PONumber]
                    ,[Style]
                    ,[Season]
                    ,[Color]
                    ,[Size]
                    ,[Quantity]
                    ,[OriginalQuantity]
                    ,[QtyWithDraw]
                    ,[Status]
                    ,[ProductionStatus]
                    ,[PreviewLCAComments]
                    ,[OrderID]
                    ,[Bucket]
                    ,[StyleSubcategory]
                    ,[StockCategory]
                    ,[Collection]
                    ,[PWModulo]
                    ,[Availability]
                    ,[SewingDate]
                    ,[FabricDD]
                    ,[Waybill]
                    ,[ShipDate]
                )
                SELECT
                     [R]                    = CAST(NULL AS BIGINT)
                    ,[RowData]              = W.[RowData]
                    ,[InventoryLineTypeN]   = CAST(2 AS INT)
                    ,[InventoryLineType]    = CAST('WITHDRAW' AS VARCHAR(50))
                    ,[DueDate]              = W.[DueDate]
                    ,[CustomerOrder]        = W.[CustomerOrder]
                    ,[Order_No]             = W.[Order_No]
                    ,[ItemDetailID]         = W.[ItemDetailID]
                    ,[ManufactureID]        = W.[ManufactureID]
                    ,[MO]                   = W.[MO]
                    ,[BundleID]             = W.[BundleID]
                    ,[BundleBarcode]        = W.[BundleBarcode]
                    ,[BoxID]                = W.[BoxID]
                    ,[BoxNumber]            = W.[BoxNumber]
                    ,[FormattedBoxNumber]   = W.[FormattedBoxNumber]
                    ,[RequiredDate]         = W.[RequiredDate]
                    ,[PONumber]             = W.[PONumber]
                    ,[Style]                = W.[Style]
                    ,[Season]               = W.[Season]
                    ,[Color]                = W.[Color]
                    ,[Size]                 = W.[Size]
                    ,[Quantity]             = W.[Quantity]
                    ,[OriginalQuantity]     = W.[OriginalQuantity]
                    ,[QtyWithDraw]          = W.[QtyWithDraw]
                    ,[Status]               = W.[Status]
                    ,[ProductionStatus]     = W.[ProductionStatus]
                    ,[PreviewLCAComments]   = W.[PreviewLCAComments]
                    ,[OrderID]              = W.[OrderID]
                    ,[Bucket]               = W.[Bucket]
                    ,[StyleSubcategory]     = W.[StyleSubcategory]
                    ,[StockCategory]        = W.[StockCategory]
                    ,[Collection]           = W.[Collection]
                    ,[PWModulo]             = W.[PWModulo]
                    ,[Availability]         = W.[Availability]
                    ,[SewingDate]           = W.[SewingDate]
                    ,[FabricDD]             = W.[FabricDD]
                    ,[Waybill]              = W.[Waybill]
                    ,[ShipDate]             = W.[ShipDate]
                FROM #TB_BACKLOG_INV_01_RF_WITHDRAW AS W


            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA INVENTARIO RELEASED Y FORECAST (WITHDRAW Y RESTANTE)------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            
            
            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA INVENTARIO CORTE TELA-------------------------------------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------													
        		PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE CORTE TELA POR TALLA')
                UPDATE [AppsLCA].[dbo].[TB_Global_Process]
                SET [Percent] = 90,
                    [StepCode] = 'BACKLOG',
                    [StepNameUser] = 'Generando backlog',
                    [MessageUser] = 'Preparando base LCA para backlog. Ordenes en Corte Tela (CT).',
                    [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE RELEASED/FORECAST POR TALLA'),500),
                    [UpdatedAt] = SYSDATETIME()
                WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
                -- PROCESO CT-1: Insertar inventario de Corte Tela en la tabla unificada final
                -- Filtros utilizados:
                --   - StatusID en (51,53) [Cutting, Preproduction]
                --   - MO.BundleCreateDate IS NULL
                --   - MD.QuantityOrdered > 0
                --   - Coincidencia obligatoria con #TB_BACKLOG_L2BRAND_ACTIVE por ItemDetailID (ORD_MAP)
                INSERT INTO #TB_BACKLOG_INVENTORY_UNIFIED
                (
                     [R]
                    ,[RowData]
                    ,[InventoryLineTypeN]
                    ,[InventoryLineType]
                    ,[DueDate]
                    ,[CustomerOrder]
                    ,[Order_No]
                    ,[ItemDetailID]
                    ,[ManufactureID]
                    ,[MO]
                    ,[BundleID]
                    ,[BundleBarcode]
                    ,[BoxID]
                    ,[BoxNumber]
                    ,[FormattedBoxNumber]
                    ,[RequiredDate]
                    ,[PONumber]
                    ,[Style]
                    ,[Season]
                    ,[Color]
                    ,[Size]
                    ,[Quantity]
                    ,[OriginalQuantity]
                    ,[QtyWithDraw]
                    ,[Status]
                    ,[ProductionStatus]
                    ,[PreviewLCAComments]
                    ,[OrderID]
                    ,[Bucket]
                    ,[StyleSubcategory]
                    ,[StockCategory]
                    ,[Collection]
                    ,[PWModulo]
                    ,[Availability]
                    ,[SewingDate]
                    ,[FabricDD]
                    ,[Waybill]
                    ,[ShipDate]
                )
                SELECT
                     [R]                          = CAST(NULL AS BIGINT)
                    ,[RowData]                    = ROW_NUMBER() OVER(ORDER BY BL.[DueDate] ASC , BL.[Order_No] ASC, ORD_MAP.[ItemDetailID] ASC, MO.[ManufactureID] ASC)
                    ,[InventoryLineTypeN]         = CAST(3 AS INT)
                    ,[InventoryLineType]          = CAST('CorteTela' AS VARCHAR(50))
                    ,[DueDate]                    = BL.[DueDate]
                    ,[CustomerOrder]              = BL.[CustomerOrder]
                    ,[Order_No]                   = BL.[Order_No]
                    ,[ItemDetailID]               = ORD_MAP.[ItemDetailID]
                    ,[ManufactureID]              = MO.[ManufactureID]
                    ,[MO]                         = MO.[ManufactureNumber]
                    ,[BundleID]                   = CAST(NULL AS INT)
                    ,[BundleBarcode]              = CAST(NULL AS VARCHAR(200))
                    ,[BoxID]                      = CAST(NULL AS INT)
                    ,[BoxNumber]                  = CAST(NULL AS VARCHAR(200))
                    ,[FormattedBoxNumber]         = CAST(NULL AS VARCHAR(200))
                    ,[RequiredDate]               = COALESCE( CAST(OI.[requiredDate] AS DATE) ,CAST(ORD.[requiredDate] AS DATE))
                    ,[PONumber]                   = ORD.[PONumber]
                    ,[Style]                      = ST.[StyleNumber]
                    ,[Season]                     = SEAS.[SeasonName]
                    ,[Color]                      = STC.[StyleColorName]
                    ,[Size]                       = FG.[GarmentSize]
                    ,[Quantity]                   = SUM(MD.[QuantityOrdered])
                    ,[OriginalQuantity]           = SUM(MD.[QuantityOrdered])
                    ,[QtyWithDraw]                = CAST(0 AS INT)
                    ,[Status]                     = SN.[StatusName]
                    ,[ProductionStatus]           = PST.[DropDownValue]
                    ,[PreviewLCAComments]         = REPLACE(REPLACE(REPLACE(PST.[Description],CHAR(10),''),CHAR(9),''),CHAR(13),'')
                    ,[OrderID]                    = ORD.[OrderID]
                    ,[Bucket]                     = REPLACE(MO.[Comments3],'BU ','')
                    ,[StyleSubcategory]           = STCT.[StyleSubcategoryName]
                    ,[StockCategory]              = ISNULL(STRG.[RegionName],'')
                    ,[Collection]                 = STCL.[CollectionName]
                    ,[PWModulo]                   = MO.[Comments7]
                    ,[Availability]               = MO.[PlanTransferCost]
                    ,[SewingDate]                 = CAST(MO.[SchedFinish] AS DATE)
                    ,[FabricDD]                   = REPLACE(REPLACE(REPLACE(MO.[Comments8], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')
                    ,[Waybill]                    = CAST(NULL AS VARCHAR(200))
                    ,[ShipDate]                   = CAST(NULL AS DATE)
                FROM (SELECT [StatusID],[StatusName] FROM [LCA].[dbo].[StatusNames] WITH(NOLOCK) WHERE [StatusID] IN(51,53)) AS SN
                INNER JOIN [LCA].[dbo].[ManufactureOrders]      AS MO    WITH(NOLOCK) ON SN.[StatusID]          = MO.[StatusID]      AND MO.[StatusID] IN(51,53) AND mo.BundleCreateDate IS NULL
                INNER JOIN [LCA].[dbo].[ManufactureDetails]     AS MD    WITH(NOLOCK) ON MD.[ManufactureID]     = MO.[ManufactureID] AND MD.[QuantityOrdered] > 0
                LEFT JOIN  [LCA].[dbo].[FinishedGoods]          AS FG    WITH(NOLOCK) ON FG.[FinishedGoodsID]   = MD.[FinishedGoodsID]
                LEFT JOIN  [LCA].[dbo].[StyleColors]            AS STC   WITH(NOLOCK) ON STC.[StyleColorID]     = FG.[StyleColorID]
                LEFT JOIN  [LCA].[dbo].[Styles]                 AS ST    WITH(NOLOCK) ON ST.[StyleID]           = FG.[StyleID]
                LEFT JOIN  [LCA].[dbo].[Seasons]                AS SEAS  WITH(NOLOCK) ON SEAS.[SeasonID]        = ST.[SeasonID]
                LEFT JOIN  [LCA].[dbo].[Orders]                 AS ORD   WITH(NOLOCK) ON ORD.[OrderID]          = MO.[OrderID]
                LEFT JOIN  [LCA].[dbo].[StyleCategories]        AS STCT  WITH(NOLOCK) ON STCT.[StyleCategoryID] = ST.[StyleCategoryID]
                LEFT JOIN  [LCA].[dbo].[StyleRegions]           AS STRG  WITH(NOLOCK) ON STRG.[RegionID]        = ST.[RegionID]
                LEFT JOIN  [LCA].[dbo].[OrderItems]             AS OI    WITH(NOLOCK) ON OI.[OrderItemID]       = MO.[FirstOrderItemID]
                LEFT JOIN  [LCA].[dbo].[StyleCollections]       AS STCL  WITH(NOLOCK) ON ST.[CollectionID]      = STCL.[CollectionID]
                LEFT JOIN  [LCA].[dbo].[DropDownValues3]        AS PST   WITH(NOLOCK) ON PST.[DropDownValueID]  = MO.[ProductionStatusID]
                CROSS APPLY (
                    SELECT [ItemDetailID] = CASE
                        WHEN ORD.[PONumber] LIKE 'ORD-PO%' THEN NULL
                        WHEN ORD.[PONumber] LIKE 'ORD-%' AND ISNUMERIC(REPLACE(ORD.[PONumber],'ORD-','')) = 1 THEN TRY_CAST(REPLACE(ORD.[PONumber],'ORD-','') AS BIGINT)
                        WHEN ORD.[PONumber] LIKE 'ORD%' AND ISNUMERIC(ORD.[Comments6]) = 1 THEN TRY_CAST(ORD.[Comments6] AS BIGINT)
                        ELSE NULL
                    END
                ) AS ORD_MAP
                INNER JOIN #TB_BACKLOG_L2BRAND_ACTIVE AS BL ON BL.[ItemDetailID] = ORD_MAP.[ItemDetailID]
                GROUP BY
                    BL.[DueDate]
                    ,BL.[CustomerOrder]
                    ,BL.[Order_No]
                    ,ORD_MAP.[ItemDetailID]
                    ,MO.[ManufactureID]
                    ,MO.[ManufactureNumber]
                    ,COALESCE( CAST(OI.[requiredDate] AS DATE) ,CAST(ORD.[requiredDate] AS DATE))
                    ,ORD.[PONumber]
                    ,ST.[StyleNumber]
                    ,SEAS.[SeasonName]
                    ,STC.[StyleColorName]
                    ,FG.[GarmentSize]
                    -- ,SUM(MD.[QuantityOrdered])
                    -- ,SUM(MD.[QuantityOrdered])
                    -- ,CAST(0 AS INT)
                    ,SN.[StatusName]
                    ,PST.[DropDownValue]
                    ,REPLACE(REPLACE(REPLACE(PST.[Description],CHAR(10),''),CHAR(9),''),CHAR(13),'')
                    ,ORD.[OrderID]
                    ,REPLACE(MO.[Comments3],'BU ','')
                    ,STCT.[StyleSubcategoryName]
                    ,ISNULL(STRG.[RegionName],'')
                    ,ORD.[Comments6]
                    ,STCL.[CollectionName]
                    ,MO.[Comments7]
                    ,MO.[PlanTransferCost]
                    ,CAST(MO.[SchedFinish] AS DATE)
                    ,REPLACE(REPLACE(REPLACE(MO.[Comments8], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')
                    
            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA INVENTARIO CORTE TELA-------------------------------------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            
            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA INVENTARIO HOLD-------------------------------------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

                ----Explicacion del procedimiento para inventario hold
                -------------------         Que hace el bloque
                ------------------- Inserta en #TB_BACKLOG_INVENTORY_UNIFIED las ordenes de manufactura en estado HOLD (StatusID = 67).
                ------------------- Agrega unidades por talla vinculadas a demanda activa de L2 Brand desde #TB_BACKLOG_L2BRAND_ACTIVE.
                ------------------- Asigna InventoryLineTypeN = 7 e InventoryLineType = 'HOLD'.
                ------------------- Enriquece con datos de estilo, color, talla, temporada, coleccion, subcategoria, region, estado productivo y comentarios LCA.
                ------------------- Usa CROSS APPLY para mapear ItemDetailID desde PONumber (prefijo ORD-) o Comments6 de la orden.
                ------------------- Agrupa por todos los campos clave para sumar Quantity y OriginalQuantity desde ManufactureDetails.
                -------------------         Filtros utilizados
                ------------------- StatusNames.StatusID IN (67): solo estado HOLD.
                ------------------- ManufactureOrders.StatusID IN (67): MOs en estado HOLD.
                ------------------- ManufactureDetails.QuantityOrdered > 0: unidades positivas.
                ------------------- INNER JOIN con #TB_BACKLOG_L2BRAND_ACTIVE: solo ordenes activas con ItemDetailID mapeado.
                ------------------- PONumber LIKE 'ORD-%' (excluye 'ORD-PO') para extraer ItemDetailID; alternativa via Comments6 con prefijo 'ORD%'.
                UPDATE [AppsLCA].[dbo].[TB_Global_Process]
                SET [Percent] = 91,
                    [StepCode] = 'BACKLOG',
                    [StepNameUser] = 'Generando backlog',
                    [MessageUser] = 'Preparando base LCA para backlog. Ordenes canceladas (HOLD).',
                    [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE RELEASED/FORECAST POR TALLA'),500),
                    [UpdatedAt] = SYSDATETIME()
                WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
                INSERT INTO #TB_BACKLOG_INVENTORY_UNIFIED
                (
                     [R]
                    ,[RowData]
                    ,[InventoryLineTypeN]
                    ,[InventoryLineType]
                    ,[DueDate]
                    ,[CustomerOrder]
                    ,[Order_No]
                    ,[ItemDetailID]
                    ,[ManufactureID]
                    ,[MO]
                    ,[BundleID]
                    ,[BundleBarcode]
                    ,[BoxID]
                    ,[BoxNumber]
                    ,[FormattedBoxNumber]
                    ,[RequiredDate]
                    ,[PONumber]
                    ,[Style]
                    ,[Season]
                    ,[Color]
                    ,[Size]
                    ,[Quantity]
                    ,[OriginalQuantity]
                    ,[QtyWithDraw]
                    ,[Status]
                    ,[ProductionStatus]
                    ,[PreviewLCAComments]
                    ,[OrderID]
                    ,[Bucket]
                    ,[StyleSubcategory]
                    ,[StockCategory]
                    ,[Collection]
                    ,[PWModulo]
                    ,[Availability]
                    ,[SewingDate]
                    ,[FabricDD]
                    ,[Waybill]
                    ,[ShipDate]
                )
                SELECT
                     [R]                          = CAST(NULL AS BIGINT)
                    ,[RowData]                    = ROW_NUMBER() OVER(ORDER BY BL.[DueDate] ASC , BL.[Order_No] ASC, ORD_MAP.[ItemDetailID] ASC, MO.[ManufactureID] ASC)
                    ,[InventoryLineTypeN]         = CAST(7 AS INT)
                    ,[InventoryLineType]          = CAST('HOLD' AS VARCHAR(50))
                    ,[DueDate]                    = BL.[DueDate]
                    ,[CustomerOrder]              = BL.[CustomerOrder]
                    ,[Order_No]                   = BL.[Order_No]
                    ,[ItemDetailID]               = ORD_MAP.[ItemDetailID]
                    ,[ManufactureID]              = MO.[ManufactureID]
                    ,[MO]                         = MO.[ManufactureNumber]
                    ,[BundleID]                   = CAST(NULL AS INT)
                    ,[BundleBarcode]              = CAST(NULL AS VARCHAR(200))
                    ,[BoxID]                      = CAST(NULL AS INT)
                    ,[BoxNumber]                  = CAST(NULL AS VARCHAR(200))
                    ,[FormattedBoxNumber]         = CAST(NULL AS VARCHAR(200))
                    ,[RequiredDate]               = COALESCE( CAST(OI.[requiredDate] AS DATE) ,CAST(ORD.[requiredDate] AS DATE))
                    ,[PONumber]                   = ORD.[PONumber]
                    ,[Style]                      = ST.[StyleNumber]
                    ,[Season]                     = SEAS.[SeasonName]
                    ,[Color]                      = STC.[StyleColorName]
                    ,[Size]                       = FG.[GarmentSize]
                    ,[Quantity]                   = SUM(MD.[QuantityOrdered])
                    ,[OriginalQuantity]           = SUM(MD.[QuantityOrdered])
                    ,[QtyWithDraw]                = CAST(0 AS INT)
                    ,[Status]                     = SN.[StatusName]
                    ,[ProductionStatus]           = PST.[DropDownValue]
                    ,[PreviewLCAComments]         = REPLACE(REPLACE(REPLACE(PST.[Description],CHAR(10),''),CHAR(9),''),CHAR(13),'')
                    ,[OrderID]                    = ORD.[OrderID]
                    ,[Bucket]                     = REPLACE(MO.[Comments3],'BU ','')
                    ,[StyleSubcategory]           = STCT.[StyleSubcategoryName]
                    ,[StockCategory]              = ISNULL(STRG.[RegionName],'')
                    ,[Collection]                 = STCL.[CollectionName]
                    ,[PWModulo]                   = MO.[Comments7]
                    ,[Availability]               = MO.[PlanTransferCost]
                    ,[SewingDate]                 = CAST(MO.[SchedFinish] AS DATE)
                    ,[FabricDD]                   = REPLACE(REPLACE(REPLACE(MO.[Comments8], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')
                    ,[Waybill]                    = CAST(NULL AS VARCHAR(200))
                    ,[ShipDate]                   = CAST(NULL AS DATE)
                FROM (SELECT [StatusID],[StatusName] FROM [LCA].[dbo].[StatusNames] WITH(NOLOCK) WHERE [StatusID] IN(67)) AS SN --HOLD
                INNER JOIN [LCA].[dbo].[ManufactureOrders]      AS MO    WITH(NOLOCK) ON SN.[StatusID]          = MO.[StatusID]      AND MO.[StatusID] IN(67)-- AND mo.BundleCreateDate IS NULL
                INNER JOIN [LCA].[dbo].[ManufactureDetails]     AS MD    WITH(NOLOCK) ON MD.[ManufactureID]     = MO.[ManufactureID] AND MD.[QuantityOrdered] > 0
                LEFT JOIN  [LCA].[dbo].[FinishedGoods]          AS FG    WITH(NOLOCK) ON FG.[FinishedGoodsID]   = MD.[FinishedGoodsID]
                LEFT JOIN  [LCA].[dbo].[StyleColors]            AS STC   WITH(NOLOCK) ON STC.[StyleColorID]     = FG.[StyleColorID]
                LEFT JOIN  [LCA].[dbo].[Styles]                 AS ST    WITH(NOLOCK) ON ST.[StyleID]           = FG.[StyleID]
                LEFT JOIN  [LCA].[dbo].[Seasons]                AS SEAS  WITH(NOLOCK) ON SEAS.[SeasonID]        = ST.[SeasonID]
                LEFT JOIN  [LCA].[dbo].[Orders]                 AS ORD   WITH(NOLOCK) ON ORD.[OrderID]          = MO.[OrderID]
                LEFT JOIN  [LCA].[dbo].[StyleCategories]        AS STCT  WITH(NOLOCK) ON STCT.[StyleCategoryID] = ST.[StyleCategoryID]
                LEFT JOIN  [LCA].[dbo].[StyleRegions]           AS STRG  WITH(NOLOCK) ON STRG.[RegionID]        = ST.[RegionID]
                LEFT JOIN  [LCA].[dbo].[OrderItems]             AS OI    WITH(NOLOCK) ON OI.[OrderItemID]       = MO.[FirstOrderItemID]
                LEFT JOIN  [LCA].[dbo].[StyleCollections]       AS STCL  WITH(NOLOCK) ON ST.[CollectionID]      = STCL.[CollectionID]
                LEFT JOIN  [LCA].[dbo].[DropDownValues3]        AS PST   WITH(NOLOCK) ON PST.[DropDownValueID]  = MO.[ProductionStatusID]
                CROSS APPLY (
                    SELECT [ItemDetailID] = CASE
                        WHEN ORD.[PONumber] LIKE 'ORD-PO%' THEN NULL
                        WHEN ORD.[PONumber] LIKE 'ORD-%' AND ISNUMERIC(REPLACE(ORD.[PONumber],'ORD-','')) = 1 THEN TRY_CAST(REPLACE(ORD.[PONumber],'ORD-','') AS BIGINT)
                        WHEN ORD.[PONumber] LIKE 'ORD%' AND ISNUMERIC(ORD.[Comments6]) = 1 THEN TRY_CAST(ORD.[Comments6] AS BIGINT)
                        ELSE NULL
                    END
                ) AS ORD_MAP
                INNER JOIN #TB_BACKLOG_L2BRAND_ACTIVE AS BL ON BL.[ItemDetailID] = ORD_MAP.[ItemDetailID]
                GROUP BY
                    BL.[DueDate]
                    ,BL.[CustomerOrder]
                    ,BL.[Order_No]
                    ,ORD_MAP.[ItemDetailID]
                    ,MO.[ManufactureID]
                    ,MO.[ManufactureNumber]
                    ,COALESCE( CAST(OI.[requiredDate] AS DATE) ,CAST(ORD.[requiredDate] AS DATE))
                    ,ORD.[PONumber]
                    ,ST.[StyleNumber]
                    ,SEAS.[SeasonName]
                    ,STC.[StyleColorName]
                    ,FG.[GarmentSize]
                    -- ,SUM(MD.[QuantityOrdered])
                    -- ,SUM(MD.[QuantityOrdered])
                    -- ,CAST(0 AS INT)
                    ,SN.[StatusName]
                    ,PST.[DropDownValue]
                    ,REPLACE(REPLACE(REPLACE(PST.[Description],CHAR(10),''),CHAR(9),''),CHAR(13),'')
                    ,ORD.[OrderID]
                    ,REPLACE(MO.[Comments3],'BU ','')
                    ,STCT.[StyleSubcategoryName]
                    ,ISNULL(STRG.[RegionName],'')
                    ,ORD.[Comments6]
                    ,STCL.[CollectionName]
                    ,MO.[Comments7]
                    ,MO.[PlanTransferCost]
                    ,CAST(MO.[SchedFinish] AS DATE)
                    ,REPLACE(REPLACE(REPLACE(MO.[Comments8], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')
                    

            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA INVENTARIO HOLD------------------------------------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA INVENTARIO BUNDLES----------------------------------------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

                ----Explicacion del procedimiento para inventario bundles (BASE_LCA)
                -------------------         Que hace el bloque
                ------------------- Construye la base de inventario de bultos (WIP) para backlog con enfoque por BundleID.
                ------------------- Calcula siguiente tarea de workflow, ubicacion fisica/contable y estatus productivo del bulto.
                ------------------- Normaliza columnas al layout unificado de #TB_BACKLOG_INVENTORY_UNIFIED.
                ------------------- Usa DueDate/CustomerOrder/Order_No/ItemDetailID desde #TB_BACKLOG_L2BRAND_ACTIVE.
                -------------------         Filtros utilizados
                ------------------- MO.StatusID < 90
                ------------------- Quantity > 0
                ------------------- TypeQueryN = 1 (BundlesLoc)
                ------------------- Excluye NO WIP mediante FilterTakeUnits = 1

                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE BUNDLES')
                UPDATE [AppsLCA].[dbo].[TB_Global_Process]
                SET [Percent] = 92,
                    [StepCode] = 'BACKLOG',
                    [StepNameUser] = 'Generando backlog',
                    [MessageUser] = 'Preparando base LCA para backlog. Ordenes en bultos (BundlesLoc).',
                    [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE RELEASED/FORECAST POR TALLA'),500),
                    [UpdatedAt] = SYSDATETIME()
                WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
                
                DROP TABLE IF EXISTS #TB_BACKLOG_BUNDLES_IDS
                DROP TABLE IF EXISTS #TB_BACKLOG_BUNDLES_WIP

                SELECT
                     [BundleID] = BND.[BundleID]
                INTO #TB_BACKLOG_BUNDLES_IDS
                FROM [LCA].[dbo].[ManufactureOrders]   AS MO  WITH(NOLOCK)
                INNER JOIN [LCA].[dbo].[Bundles]       AS BND WITH(NOLOCK) ON BND.[ManufactureID] = MO.[ManufactureID]
                WHERE MO.[StatusID] < 90 AND MO.[StatusID] <> 67
                -- AND MO.ManufactureNumber = 'EO5275278-850'
                
                -- SELECT * fROM #TB_BACKLOG_BUNDLES_IDS

                SELECT
                     [TypeQueryN]                    = 1
                    ,[BundleID]                      = BND.[BundleID]
                    ,[BundleBarcode]                 = 'PPBU' + LTRIM(STR(BND.[BundleID] + 10000000))
                    ,[ManufactureID]                 = BND.[ManufactureID]
                    ,[MO]                            = MO.[ManufactureNumber]
                    ,[MOStatus]                      = SN.[StatusName]
                    ,[ProductionStatus]              = PST.[DropDownValue]
                    ,[PreviewLCAComments]            = PST.[Description]
                    ,[BundleProductionStatus]        = CAST(NULL AS VARCHAR(100))
                    ,[BundlePreviewLCAComments]      = CAST(NULL AS VARCHAR(MAX))
                    ,[PWModulo]                      = MO.[Comments7]
                    ,[Style]                         = ST.[StyleNumber]
                    ,[Season]                        = SEAS.[SeasonName]
                    ,[Color]                         = STC.[StyleColorName]
                    ,[Size]                          = FG.[GarmentSize]
                    ,[Quantity]                      = BND.[QuantityOrdered] - BND.[QuantityThirds]
                    ,[OrderID]                       = OD.[OrderID]
                    ,[PONumber]                      = OD.[PONumber]
                    ,[RequiredDate]                  = COALESCE(CAST(OI.[requiredDate] AS DATE), CAST(OD.[requiredDate] AS DATE))
                    ,[ItemDetailID]                  = CASE
                                                            WHEN OD.[PONumber] LIKE 'ORD-PO%' THEN NULL
                                                            WHEN OD.[PONumber] LIKE 'ORD-%' AND ISNUMERIC(REPLACE(OD.[PONumber],'ORD-','')) = 1
                                                                THEN TRY_CAST(REPLACE(OD.[PONumber],'ORD-','') AS BIGINT)
                                                            WHEN OD.[PONumber] LIKE 'ORD%' AND ISNUMERIC(OD.[Comments6]) = 1
                                                                THEN TRY_CAST(OD.[Comments6] AS BIGINT)
                                                            ELSE NULL
                                                        END
                    ,[RealLastTaskID]                = CAST(NULL AS INT)
                    ,[NextTaskID]                    = CAST(NULL AS INT)
                    ,[NextTaskName]                  = CAST(NULL AS VARCHAR(200))
                    ,[PhysicalLocation]              = CAST(NULL AS VARCHAR(200))
                    ,[AccountingLocation]            = CAST(NULL AS VARCHAR(200))
                    ,[LocationCost]                  = CAST(NULL AS VARCHAR(100))
                    ,[Area]                          = CAST(NULL AS VARCHAR(100))
                    ,[BoxNumber]                     = PB.[BoxNumber]
                    ,[FilterTakeUnits]               = CAST(0 AS BIT)
                    ,[Bucket]                        = REPLACE(MO.[Comments3],'BU ','')       
                    
                    ,[StyleSubcategory]              = STCT.[StyleSubcategoryName]
                    ,[StockCategory]                 = ISNULL(STRG.[RegionName],'')
                    ,[APS]                           = OD.[Comments6]
                    ,[Collection]                    = STCL.[CollectionName]
                    ,[Availability]                  = MO.[PlanTransferCost]
                    ,[SewingDate]                    = CAST(MO.[SchedFinish] AS DATE)
                    ,[FabricDD]                      = REPLACE(REPLACE(REPLACE(MO.[Comments8], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')
                INTO #TB_BACKLOG_BUNDLES_WIP
                FROM #TB_BACKLOG_BUNDLES_IDS              AS FIL
                INNER JOIN [LCA].[dbo].[Bundles]          AS BND   WITH(NOLOCK) ON FIL.[BundleID]                = BND.[BundleID]
                INNER JOIN [LCA].[dbo].[ManufactureOrders]AS MO    WITH(NOLOCK) ON BND.[ManufactureID]           = MO.[ManufactureID] AND MO.[StatusID] < 90
                LEFT JOIN  [LCA].[dbo].[PackedBoxes]      AS PB    WITH(NOLOCK) ON PB.[PackedBoxID]              = BND.[PackedBoxID]            AND PB.StatusID IN(25,27,75)
                INNER JOIN [LCA].[dbo].[ManufactureDetails]AS MD   WITH(NOLOCK) ON BND.[ManufactureDetailID]     = MD.[ManufactureDetailID]
                INNER JOIN [LCA].[dbo].[FinishedGoods]    AS FG    WITH(NOLOCK) ON MD.[FinishedGoodsID]          = FG.[FinishedGoodsID]
                INNER JOIN [LCA].[dbo].[Styles]           AS ST    WITH(NOLOCK) ON FG.[StyleID]                  = ST.[StyleID]
                INNER JOIN [LCA].[dbo].[StyleColors]      AS STC   WITH(NOLOCK) ON FG.[StyleColorID]             = STC.[StyleColorID]
                INNER JOIN [LCA].[dbo].[OrderItems]       AS OI    WITH(NOLOCK) ON OI.[OrderItemID]              = MO.[FirstOrderItemID]
                INNER JOIN [LCA].[dbo].[Orders]           AS OD    WITH(NOLOCK) ON OD.[OrderID]                  = OI.[OrderID]
                LEFT JOIN  [LCA].[dbo].[StyleCategories]  AS STCT  WITH(NOLOCK) ON STCT.[StyleCategoryID]        = ST.[StyleCategoryID]
                LEFT JOIN  [LCA].[dbo].[StyleRegions]     AS STRG  WITH(NOLOCK) ON STRG.[RegionID]               = ST.[RegionID]
                LEFT JOIN  [LCA].[dbo].[StatusNames]      AS SN    WITH(NOLOCK) ON SN.[StatusID]                 = MO.[StatusID]
                LEFT JOIN  [LCA].[dbo].[Seasons]          AS SEAS  WITH(NOLOCK) ON SEAS.[SeasonID]               = ST.[SeasonID]
                LEFT JOIN  [LCA].[dbo].[DropDownValues3]  AS PST   WITH(NOLOCK) ON PST.[DropDownValueID]         = MO.[ProductionStatusID]
    			LEFT JOIN   [LCA].[dbo].StyleCollections  AS STCL  WITH(NOLOCK) ON ST.[CollectionID]             = STCL.[CollectionID]

                UPDATE TB
                SET
                -- select *,
                     [NextTaskID]    = COALESCE(TBW1.[NextTaskID],TBW2.[TaskID])
                    ,[RealLastTaskID]= COALESCE(TBW1.[LastTaskID],TBW2.[TaskID])
                FROM #TB_BACKLOG_BUNDLES_WIP AS TB
                LEFT JOIN (
                    SELECT *
                    FROM(
                        SELECT
                             [BundleID]    = BND.[BundleID]
                            ,[R]           = ROW_NUMBER() OVER(PARTITION BY BND.[BundleID] ORDER BY BND.[BundleID],WT2.[Sequence] ASC)
                            ,[LastTaskID]  = WTS.[TaskID]
                            ,[NextTaskID]  = COALESCE(WT2.[TaskID],0)
                        FROM #TB_BACKLOG_BUNDLES_IDS AS FIL
                        INNER JOIN [LCA].[dbo].[Bundles]            AS BND  WITH(NOLOCK) ON FIL.[BundleID]      = BND.[BundleID]
                        INNER JOIN [LCA].[dbo].[ManufactureOrders]  AS MO   WITH(NOLOCK) ON BND.[ManufactureID] = MO.[ManufactureID] AND MO.[StatusID] < 90
                        LEFT JOIN (
                            SELECT *
                            FROM(
                                SELECT
                                     [BundleID]
                                    ,[R]                            = ROW_NUMBER() OVER(PARTITION BY EA.[BundleID] ORDER BY EA.[ChangeDate] DESC,EA.[MaxChangeDateID] DESC,EA.[MaxSequence] DESC)
                                    ,[LastTransactionWithOutDamage]
                                FROM(
                                    SELECT
                                         [BundleID]                      = BND.[BundleID]
                                        ,[LastTransactionWithOutDamage]  = MAX(WT.[WorkTransactionID])
                                        ,[Quantity]                      = SUM(WT.[Quantity])
                                        ,[ChangeDate]                    = MAX(CH.[ChangeDate])
                                        ,[TaskID]                        = WT.[TaskID]
                                        ,[MaxChangeDateID]               = MAX(CH.[ChangeLogID])
                                        ,[MaxSequence]                   = WTS.[Sequence]
                                    FROM #TB_BACKLOG_BUNDLES_IDS AS FIL
                                    INNER JOIN [LCA].[dbo].[Bundles]            AS BND  WITH(NOLOCK) ON FIL.[BundleID]      = BND.[BundleID]
                                    INNER JOIN [LCA].[dbo].[ManufactureOrders]  AS MO   WITH(NOLOCK) ON BND.[ManufactureID] = MO.[ManufactureID] AND MO.[StatusID] < 90
                                    INNER JOIN [LCA].[dbo].[WorkTransactions]    AS WT   WITH(NOLOCK) ON BND.[BundleID]      = WT.[BundleID] AND WT.[DamageID] IS NULL AND WT.[Quantity] <> 0
                                    INNER JOIN [LCA].[dbo].[ChangeLog]           AS CH   WITH(NOLOCK) ON CH.[ChangeLogID]    = WT.[ChangeLogID]
                                    LEFT JOIN  [LCA].[dbo].[WorkTasks]           AS WTS  WITH(NOLOCK) ON WT.[TaskID]         = WTS.[TaskID]
                                    GROUP BY BND.[BundleID],WT.[TaskID],WTS.[Sequence]
                                    HAVING SUM(WT.[Quantity]) > 0
                                ) AS EA
                            ) AS TBW
                            WHERE TBW.[R] = 1
                        ) AS BNTR ON BNTR.[BundleID] = BND.[BundleID]
                        INNER JOIN [LCA].[dbo].[WorkTransactions]    AS WT   WITH(NOLOCK) ON COALESCE(BNTR.[LastTransactionWithOutDamage],BND.[LastTransactionID]) = WT.[WorkTransactionID]
                        LEFT JOIN  [LCA].[dbo].[WorkTasks]           AS WTS  WITH(NOLOCK) ON WT.[TaskID]                  = WTS.[TaskID]
                        LEFT JOIN  [LCA].[dbo].[WorkTasks]           AS WT2  WITH(NOLOCK) ON WT2.[WorkFlowID]             = WTS.[WorkFlowID] AND WTS.[NextNodeNumber] = WT2.[NodeNumber]
                    ) AS TB1
                    WHERE TB1.[R] = 1
                ) AS TBW1 ON TBW1.[BundleID] = TB.[BundleID]
                LEFT JOIN (
                
                        SELECT
        					[ManufactureID] = [ManufactureID]
        					,[TaskID]       = ISNULL([LagTaskID],[TaskID])
        					,[R]            = [R]
        				FROM(
        					SELECT
                                [R]			 = ROW_NUMBER() OVER(PARTITION BY [ManufactureID] ORDER BY [Sequence] ASC)
        						,*
                            FROM(
                                SELECT
                                     [ManufactureID] = MO.[ManufactureID]
                                    ,[TaskID]        = WT.[TaskID]
        							,[TaskName]		 = WT.TaskName
        							,[Sequence]		 = WT.[Sequence]
        							,[UseBundles]	 = WT.[UseBundles] --<> 0 
        							,TaskStatusID	 = WT.[StatusID] --<= 45
        							,[LagTaskID]	 = LAG(TaskID) OVER(PARTITION BY MO.[ManufactureID] ORDER BY WT.[Sequence] ASC)
                                FROM(
                                    SELECT MO.[ManufactureID]
                                    FROM [LCA].[dbo].[ManufactureOrders] AS MO WITH(NOLOCK)
                                    WHERE MO.[StatusID] < 90
                                ) AS FIL
                                INNER JOIN [LCA].[dbo].[ManufactureOrders] AS MO WITH(NOLOCK) ON FIL.[ManufactureID] = MO.[ManufactureID]
                                INNER JOIN [LCA].[dbo].[WorkFlows]         AS WF WITH(NOLOCK) ON WF.[ManufactureID]  = FIL.[ManufactureID] AND MO.[StatusID] < 90
                                INNER JOIN [LCA].[dbo].[WorkTasks]         AS WT WITH(NOLOCK) ON WT.[WorkFlowID]     = WF.[WorkFlowID] 
        																			AND WT.[AutoComplete] = 0 
        																			--AND (WT.[UseBundles] <> 0 
        																			--	OR WT.[StatusID] <= 45
        																			--	)
        
                            ) AS TB
        					WHERE ([UseBundles] <> 0  OR [TaskStatusID] <= 45)
                           ) AS TB2
        				   WHERE TB2.[R] = 1
        					-- and ManufactureID = 886441
        					
                    -- SELECT *
                    -- FROM(
                    --     SELECT
                    --          [ManufactureID] = MO.[ManufactureID]
                    --         ,[TaskID]        = WT.[TaskID]
                    --         ,[R]             = ROW_NUMBER() OVER(PARTITION BY MO.[ManufactureID] ORDER BY WT.[Sequence] ASC)
                    --     FROM(
                    --         SELECT MO.[ManufactureID]
                    --         FROM [LCA].[dbo].[ManufactureOrders] AS MO WITH(NOLOCK)
                    --         WHERE MO.[StatusID] < 90
                    --     ) AS FIL
                    --     INNER JOIN [LCA].[dbo].[ManufactureOrders] AS MO WITH(NOLOCK) ON FIL.[ManufactureID] = MO.[ManufactureID]
                    --     INNER JOIN [LCA].[dbo].[WorkFlows]         AS WF WITH(NOLOCK) ON WF.[ManufactureID]  = FIL.[ManufactureID] AND MO.[StatusID] < 90
                    --     INNER JOIN [LCA].[dbo].[WorkTasks]         AS WT WITH(NOLOCK) ON WT.[WorkFlowID]     = WF.[WorkFlowID] AND WT.[AutoComplete] = 0 AND (WT.[UseBundles] <> 0 OR WT.[StatusID] <= 45)
                    -- ) AS TB2
                    -- WHERE TB2.[R] = 1
                ) AS TBW2 ON TBW2.[ManufactureID] = TB.[ManufactureID]
                WHERE TB.[TypeQueryN] = 1

                UPDATE S
                SET
                     [NextTaskName]             = IIF(S.[MOStatus] = 'Released','NO WIP (Released)', IIF(S.[NextTaskID] = 0,'Complete',COALESCE(WNT.[TaskName],'NO NEXT TASK')))
                    ,[PhysicalLocation]         = IIF(S.[MOStatus] = 'Released','NO WIP (Released)', IIF(S.[NextTaskID] = 0,'NO WIP (Complete)',COALESCE(DRP.[DropDownValue],ODRP.[DropDownValue],'NO LOCATION')))
                    ,[AccountingLocation]       = IIF(S.[MOStatus] = 'Released','NO WIP (Released)', IIF(S.[NextTaskID] = 0,'NO WIP (Complete)',COALESCE(DRC.[DropDownValue],DRCP.[DropDownValue],'NO LOCATION')))
                    ,[LocationCost]             = IIF(S.[MOStatus] = 'Released','NO WIP (Released)', IIF(S.[NextTaskID] = 0,'NO WIP (Complete)',COALESCE(DRC.[DropDownValue],DRCP.[DropDownValue],'NO LOCATION')))
                    ,[Area]                     = IIF(S.[MOStatus] = 'Released','NO WIP (Released)', IIF(S.[NextTaskID] = 0,'NO WIP (Complete)',COALESCE(DRP.[DropDownValue],ODRP.[DropDownValue],'NO LOCATION')))
                    ,[BundleProductionStatus]   = IIF(S.[MOStatus] = 'Released','NO WIP (Released)', IIF(S.[NextTaskID] = 0,'NO WIP (Complete)',COALESCE(LPST.[DropDownValue],S.[ProductionStatus],'')))
                    ,[BundlePreviewLCAComments] = IIF(S.[MOStatus] = 'Released','NO WIP (Released)', IIF(S.[NextTaskID] = 0,'NO WIP (Complete)',COALESCE(LPST.[Description],S.[PreviewLCAComments],'')))
                FROM #TB_BACKLOG_BUNDLES_WIP           AS S
                LEFT JOIN [LCA].[dbo].[WorkTasks]      AS WNT  WITH(NOLOCK) ON WNT.[TaskID]             = S.[NextTaskID]
                LEFT JOIN [LCA].[dbo].[DropDownValues4]AS DRP  WITH(NOLOCK) ON DRP.[DropDownValueID]    = WNT.[DelayReasonCodeID]
                LEFT JOIN [LCA].[dbo].[DropDownValues3]AS DRC  WITH(NOLOCK) ON DRC.[DropDownValueID]    = WNT.[TaskCategoryID]
                LEFT JOIN [LCA].[dbo].[WorkFlows]      AS WF   WITH(NOLOCK) ON WF.[WorkFlowID]          = WNT.[WorkFlowID]
                LEFT JOIN [LCA].[dbo].[WorkTasks]      AS OWT  WITH(NOLOCK) ON OWT.[TaskID]             = WNT.[TemplateID]
                LEFT JOIN [LCA].[dbo].[DropDownValues4]AS ODRP WITH(NOLOCK) ON ODRP.[DropDownValueID]   = OWT.[DelayReasonCodeID]
                LEFT JOIN [LCA].[dbo].[DropDownValues3]AS DRCP WITH(NOLOCK) ON DRCP.[DropDownValueID]   = OWT.[TaskCategoryID]
                LEFT JOIN [LCA].[dbo].[WorkTasks]      AS WLT  WITH(NOLOCK) ON WLT.[TaskID]             = S.[RealLastTaskID]
                LEFT JOIN [LCA].[dbo].[DropDownValues3]AS LPST WITH(NOLOCK) ON LPST.[DropDownValueID]   = WLT.[SetProductionStatusID]

                UPDATE S
                SET
                     [NextTaskName]      = 'MO RELEASED WITH DISPATCH'
                    ,[PhysicalLocation]  = 'MO RELEASED WITH DISPATCH'
                    ,[AccountingLocation]= 'MO RELEASED WITH DISPATCH'
                    ,[LocationCost]      = 'WH RO'
                FROM #TB_BACKLOG_BUNDLES_WIP AS S
                INNER JOIN (
                    SELECT
                         [ManufactureID] = MO.[ManufactureID]
                        ,[Dispatch]      = SUM(COALESCE(MB.[QuantityWithdrawn],0))
                    FROM [LCA].[dbo].[ManufactureOrders] AS MO WITH(NOLOCK)
                    LEFT JOIN [LCA].[dbo].[ManufactureBlanks] AS MB WITH(NOLOCK) ON MB.[ManufactureID] = MO.[ManufactureID]
                    WHERE MO.[StatusID] < 90
                    GROUP BY MO.[ManufactureID]
                    HAVING SUM(COALESCE(MB.[QuantityWithdrawn],0)) > 0
                ) AS MBD ON MBD.[ManufactureID] = S.[ManufactureID]
                WHERE S.[MOStatus] = 'Released' AND S.[TypeQueryN] = 1

                UPDATE S
                SET
                     [NextTaskName]        = 'Complete'
                    ,[PhysicalLocation]    = 'NO WIP (Complete)'
                    ,[AccountingLocation]  = 'NO WIP (Complete)'
                    ,[LocationCost]        = 'NO WIP (Complete)'
                    ,[Area]                = 'NO WIP (Complete)'
                FROM #TB_BACKLOG_BUNDLES_WIP AS S
                WHERE S.[BoxNumber] IS NOT NULL AND S.[TypeQueryN] = 1

                UPDATE S
                SET
                     [FilterTakeUnits] = CASE
                                            WHEN S.[TypeQueryN] = 1 AND S.[PhysicalLocation] IN('NO WIP (Released)') THEN 1 --------------ANCLADO GLOBAL PORQUE SE QUITAN DE RELEASED. SE VA A TOMAR ACA POR TALLA.
                                            WHEN S.[TypeQueryN] = 1 AND S.[PhysicalLocation] IN('NO WIP (Complete)','NO WIP','NO WIP (Released)') THEN 0
                                            ELSE 1
                                         END
                FROM #TB_BACKLOG_BUNDLES_WIP AS S

                -- SELECT * FROM #TB_BACKLOG_BUNDLES_WIP
                -- WHERE MO = 'EO5295768-801'
                -- RETURN
                
                INSERT INTO #TB_BACKLOG_INVENTORY_UNIFIED
                (
                     [R]
                    ,[RowData]
                    ,[InventoryLineTypeN]
                    ,[InventoryLineType]
                    ,[DueDate]
                    ,[CustomerOrder]
                    ,[Order_No]
                    ,[ItemDetailID]
                    ,[ManufactureID]
                    ,[MO]
                    ,[BundleID]
                    ,[BundleBarcode]
                    ,[BoxID]
                    ,[BoxNumber]
                    ,[FormattedBoxNumber]
                    ,[RequiredDate]
                    ,[PONumber]
                    ,[Style]
                    ,[Season]
                    ,[Color]
                    ,[Size]
                    ,[Quantity]
                    ,[OriginalQuantity]
                    ,[QtyWithDraw]
                    ,[Status]
                    ,[ProductionStatus]
                    ,[PreviewLCAComments]
                    ,[OrderID]
                    ,[Bucket]
                    ,[StyleSubcategory]
                    ,[StockCategory]
                    ,[Collection]
                    ,[PWModulo]
                    ,[Availability]
                    ,[SewingDate]
                    ,[FabricDD]
                    ,[Waybill]
                    ,[ShipDate]
                )
                SELECT
                     [R]                          = CAST(NULL AS BIGINT)
                    ,[RowData]                    = ROW_NUMBER() OVER(ORDER BY BL.[DueDate] ASC, BL.[Order_No] ASC, S.[ItemDetailID] ASC, S.[ManufactureID] ASC, S.[BundleID] ASC)
                    ,[InventoryLineTypeN]         = CAST(4 AS INT)
                    ,[InventoryLineType]          = CAST('BundlesLoc' AS VARCHAR(50))
                    ,[DueDate]                    = BL.[DueDate]
                    ,[CustomerOrder]              = BL.[CustomerOrder]
                    ,[Order_No]                   = BL.[Order_No]
                    ,[ItemDetailID]               = S.[ItemDetailID]
                    ,[ManufactureID]              = S.[ManufactureID]
                    ,[MO]                         = S.[MO]
                    ,[BundleID]                   = S.[BundleID]
                    ,[BundleBarcode]              = S.[BundleBarcode]
                    ,[BoxID]                      = CAST(NULL AS INT)
                    ,[BoxNumber]                  = CAST(NULL AS VARCHAR(200))
                    ,[FormattedBoxNumber]         = CAST(NULL AS VARCHAR(200))
                    ,[RequiredDate]               = S.[RequiredDate]
                    ,[PONumber]                   = S.[PONumber]
                    ,[Style]                      = S.[Style]
                    ,[Season]                     = S.[Season]
                    ,[Color]                      = S.[Color]
                    ,[Size]                       = S.[Size]
                    ,[Quantity]                   = S.[Quantity]
                    ,[OriginalQuantity]           = S.[Quantity]
                    ,[QtyWithDraw]                = CAST(0 AS INT)
                    ,[Status]                     = S.[MOStatus]
                    ,[ProductionStatus]           = S.[BundleProductionStatus]
                    ,[PreviewLCAComments]         = S.[BundlePreviewLCAComments]
                    ,[OrderID]                    = S.[OrderID]
                    ,[Bucket]                     = S.[Bucket]
                    ,[StyleSubcategory]           = S.[StyleSubcategory]
                    ,[StockCategory]              = S.[StockCategory]
                    ,[Collection]                 = S.[Collection]
                    ,[PWModulo]                   = S.[PWModulo]
                    ,[Availability]               = S.[Availability]
                    ,[SewingDate]                 = S.[SewingDate]
                    ,[FabricDD]                   = S.[FabricDD]
                    ,[Waybill]                    = CAST(NULL AS VARCHAR(200))
                    ,[ShipDate]                   = CAST(NULL AS DATE)
                FROM #TB_BACKLOG_BUNDLES_WIP AS S
                INNER JOIN #TB_BACKLOG_L2BRAND_ACTIVE AS BL ON BL.[ItemDetailID] = S.[ItemDetailID]
                WHERE S.[TypeQueryN] = 1
                  AND S.[FilterTakeUnits] = 1
                  AND ISNULL(S.[Quantity],0) > 0
                  
                  
		-- AND MO = 'EO5614601-HGY'



                DROP TABLE IF EXISTS #TB_BACKLOG_BUNDLES_WIP
                DROP TABLE IF EXISTS #TB_BACKLOG_BUNDLES_IDS

                -- SELECT * FROM #TB_BACKLOG_INVENTORY_UNIFIED
                
            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA INVENTARIO BUNDLES----------------------------------------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA INVENTARIO PACK AND SHIP----------------------------------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

                ----Explicacion del procedimiento para inventario pack and ship (BASE_LCA)
                -------------------         Que hace el bloque
                ------------------- Construye la base de inventario de cajas en empaque/picked/shipped usando WIP_PACKING_SHIP.
                ------------------- Mapea columnas al layout unificado de backlog y agrega Waybill/ShipDate al final.
                ------------------- Define InventoryLineType por estado de caja:
                -------------------     StatusID IN (25,27) => Packed
                -------------------     StatusID = 75       => Shipped
                ------------------- DueDate/CustomerOrder/Order_No/ItemDetailID se toman de #TB_BACKLOG_L2BRAND_ACTIVE.
                -------------------         Filtros utilizados
                ------------------- PackedItems.Quantity > 0
                ------------------- Cajas activas en status 25,27,75
                ------------------- Para status 75 solo ultimos 180 dias por ShipDate

                PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'         PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE PACK AND SHIP')
                UPDATE [AppsLCA].[dbo].[TB_Global_Process]
                SET [Percent] = 93,
                    [StepCode] = 'BACKLOG',
                    [StepNameUser] = 'Generando backlog',
                    [MessageUser] = 'Preparando base LCA para backlog. Ordenes en cajas exportacion (PACKED/SHIPPED).',
                    [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE RELEASED/FORECAST POR TALLA'),500),
                    [UpdatedAt] = SYSDATETIME()
                WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
                DROP TABLE IF EXISTS #TB_BACKLOG_PACKING_SHIP_WIP

                SELECT
                     [BoxStatusID]                = SN.[StatusID]
                    ,[BoxStatus]                  = SN.[StatusName]
                    ,[ManufactureID]              = MO.[ManufactureID]
                    ,[MO]                         = MO.[ManufactureNumber]
                    ,[BoxID]                      = PB.[PackedBoxID]
                    ,[BoxNumber]                  = PB.[BoxNumber]
                    ,[FormattedBoxNumber]         = IIF(PP.[PalletTypeID] <> 1 AND PP.[PalletTypeID] IS NOT NULL,
                                                        CONCAT('PPPA'+LTRIM(STR(PP.[PackedPalletID] + 1000000)),'-',RIGHT(BTG.[DropDownValue],3)),
                                                        PB.[BoxNumber])
                    ,[RequiredDate]               = COALESCE(CAST(OI.[requiredDate] AS DATE), CAST(ORD.[requiredDate] AS DATE))
                    ,[PONumber]                   = ORD.[PONumber]
                    ,[Style]                      = ST.[StyleNumber]
                    ,[Season]                     = SNS.[SeasonName]
                    ,[Color]                      = STC.[StyleColorName]
                    ,[Size]                       = FG.[GarmentSize]
                    ,[Quantity]                   = PBI.[Quantity]
                    ,[OrderID]                    = ORD.[OrderID]
                    ,[Bucket]                     = REPLACE(MO.[Comments3],'BU ','')
                    ,[StyleSubcategory]           = STCT.[StyleSubcategoryName]
                    ,[StockCategory]              = ISNULL(STRG.[RegionName],'')
                    ,[APS]                        = ORD.[Comments6]
                    ,[Collection]                 = STCL.[CollectionName]
                    ,[PWModulo]                   = MO.[Comments7]
                    ,[Availability]               = MO.[PlanTransferCost]
                    ,[SewingDate]                 = CAST(MO.[SchedFinish] AS DATE)
                    ,[FabricDD]                   = REPLACE(REPLACE(REPLACE(MO.[Comments8], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')
                    ,[Waybill]                    = SH.[Waybill]
                    ,[ShipDate]                   = CAST(SH.[ShipDate] AS DATE)
                    ,[ItemDetailID]               = CASE
                                                        WHEN ORD.[PONumber] LIKE 'ORD-PO%' THEN NULL
                                                        WHEN ORD.[PONumber] LIKE 'ORD-%' AND ISNUMERIC(REPLACE(ORD.[PONumber],'ORD-','')) = 1 THEN TRY_CAST(REPLACE(ORD.[PONumber],'ORD-','') AS BIGINT)
                                                        WHEN ORD.[PONumber] LIKE 'ORD%' AND ISNUMERIC(ORD.[Comments6]) = 1 THEN TRY_CAST(ORD.[Comments6] AS BIGINT)
                                                        ELSE NULL
                                                     END
					,[Bin]						  = gb.[Bin]
					,[Invoiced]                   = CAST(0 AS BIT)
					,[Shelf]                      = gb.[Shelf]  
                                                     
                INTO #TB_BACKLOG_PACKING_SHIP_WIP
                FROM (SELECT [StatusID],[StatusName] FROM [LCA].[dbo].[StatusNames] WITH(NOLOCK) WHERE [StatusID] IN (25,27,75)) AS SN
                INNER JOIN [LCA].[dbo].[PackedBoxes]       AS PB   WITH(NOLOCK) ON PB.[StatusID]        = SN.[StatusID]
                INNER JOIN [LCA].[dbo].[PackedItems]       AS PBI  WITH(NOLOCK) ON PB.[PackedBoxID]     = PBI.[PackedBoxID] AND PBI.[Quantity] <> 0
                LEFT JOIN  [LCA].[dbo].[Shipments]         AS SH   WITH(NOLOCK) ON PB.[ShipmentID]      = SH.[ShipmentID]
                LEFT JOIN  [LCA].[dbo].[ManufactureOrders] AS MO   WITH(NOLOCK) ON MO.[ManufactureID]   = PBI.[ManufactureID]
                INNER JOIN [LCA].[dbo].[FinishedGoods]     AS FG   WITH(NOLOCK) ON PBI.[FinishedGoodsID]= FG.[FinishedGoodsID]
                                                                    AND (
                                                                            SN.[StatusID] IN (25,27)
                                                                            OR (SN.[StatusID] = 75 AND CAST(SH.[ShipDate] AS DATE) >= CAST(DATEADD(DAY,-450,GETDATE()) AS DATE))
                                                                        )
                INNER JOIN [LCA].[dbo].[Styles]            AS ST   WITH(NOLOCK) ON FG.[StyleID]         = ST.[StyleID]
                LEFT JOIN  [LCA].[dbo].[Seasons]           AS SNS  WITH(NOLOCK) ON SNS.[SeasonID]       = ST.[SeasonID]
                INNER JOIN [LCA].[dbo].[StyleColors]       AS STC  WITH(NOLOCK) ON FG.[StyleColorID]    = STC.[StyleColorID]
                LEFT JOIN  [LCA].[dbo].[OrderDetails]      AS OD   WITH(NOLOCK) ON OD.[OrderDetailsID]  = PBI.[OrderDetailsID]
                LEFT JOIN  [LCA].[dbo].[OrderItems]        AS OI   WITH(NOLOCK) ON OI.[OrderItemID]     = MO.[FirstOrderItemID]
                LEFT JOIN  [LCA].[dbo].[Orders]            AS ORD  WITH(NOLOCK) ON ORD.[OrderID]        = OI.[OrderID]
                LEFT JOIN  [LCA].[dbo].[Orders]            AS ORD2 WITH(NOLOCK) ON ORD2.[OrderID]        = OD.[OrderID]
                LEFT JOIN  [LCA].[dbo].[PackedPallets]     AS PP   WITH(NOLOCK) ON PP.[PackedPalletID]  = PB.[PackedPalletID]
                LEFT JOIN  [LCA].[dbo].[DropDownValues3]   AS BTG  WITH(NOLOCK) ON BTG.[DropDownValueID]= PB.[BoxTagID] AND BTG.[DropDownID] = 19
                LEFT JOIN  [LCA].[dbo].[StyleCollections]  AS STCL WITH(NOLOCK) ON ST.[CollectionID]    = STCL.[CollectionID]
                LEFT JOIN  [LCA].[dbo].[StyleCategories]   AS STCT WITH(NOLOCK) ON STCT.[StyleCategoryID]= ST.[StyleCategoryID]
                LEFT JOIN  [LCA].[dbo].[StyleRegions]      AS STRG WITH(NOLOCK) ON STRG.[RegionID]      = ST.[RegionID]
				LEFT JOIN  [LCA].[dbo].[GoodsBins]		   AS gb   WITH(NOLOCK)	ON gb.[GoodsBinID]			= pb.[GoodsBinID]
				
				UPDATE S SET
				    S.[Invoiced] = 1
				FROM #TB_BACKLOG_PACKING_SHIP_WIP AS S
				INNER JOIN AppsLCA.dbo.DTE_FACTURAS_ELECTRONICAS AS FE WITH(NOLOCK) ON FE.factura = S.[Waybill] AND FE.invalidado = 0
				
                
                -- WHERE MO.ManufactureNumber = 'EO5241313-SFTM'
                
                INSERT INTO #TB_BACKLOG_INVENTORY_UNIFIED
                (
                     [R]
                    ,[RowData]
                    ,[InventoryLineTypeN]
                    ,[InventoryLineType]
                    ,[DueDate]
                    ,[CustomerOrder]
                    ,[Order_No]
                    ,[ItemDetailID]
                    ,[ManufactureID]
                    ,[MO]
                    ,[BundleID]
                    ,[BundleBarcode]
                    ,[BoxID]
                    ,[BoxNumber]
                    ,[FormattedBoxNumber]
                    ,[RequiredDate]
                    ,[PONumber]
                    ,[Style]
                    ,[Season]
                    ,[Color]
                    ,[Size]
                    ,[Quantity]
                    ,[OriginalQuantity]
                    ,[QtyWithDraw]
                    ,[Status]
                    ,[ProductionStatus]
                    ,[PreviewLCAComments]
                    ,[OrderID]
                    ,[Bucket]
                    ,[StyleSubcategory]
                    ,[StockCategory]
                    ,[Collection]
                    ,[PWModulo]
                    ,[Availability]
                    ,[SewingDate]
                    ,[FabricDD]
                    ,[Waybill]
                    ,[ShipDate]
                )
                SELECT
                     [R]                          = CAST(NULL AS BIGINT)
                    ,[RowData]                    = ROW_NUMBER() OVER(ORDER BY BL.[DueDate] ASC, BL.[Order_No] ASC, S.[ItemDetailID] ASC, S.[ManufactureID] ASC, S.[BoxID] ASC, S.[Size] ASC)
                    ,[InventoryLineTypeN]         = CAST(CASE
                                                            WHEN S.[BoxStatusID] = 75       THEN 6
                                                            WHEN S.[BoxStatusID] IN (25,27) THEN 5
                                                            ELSE NULL
                                                        END AS INT)
                    ,[InventoryLineType]          = CAST(CASE
                                                            ----InventoryLineTypeN = 6
                                                            WHEN S.[BoxStatusID] = 75   AND S.[Invoiced] = 1    THEN 'Shipped'
                                                            WHEN S.[BoxStatusID] = 75                           THEN 'Ready To Ship'
                                                            ----InventoryLineTypeN = 5
                                                            WHEN S.[BoxStatusID] = 25                           THEN S.[BoxStatus]
                                                            WHEN S.[BoxStatusID] = 27 
                                                                AND  S.[Shelf] IN (   'ENVIO PLANTA N A S' 
                                                                                    , 'SHIPPING HW N' 
                                                                                    , 'WAITING HW N' )          THEN 'Packed in Block N'
                                                            WHEN S.[BoxStatusID] = 27 
                                                                    AND  S.[Shelf] IN ( 'SCREENPRINT S' )       THEN 'Packed in Block S'
                                                            WHEN S.[BoxStatusID] = 27 
                                                                    AND  S.[Shelf] IN ( 'EXPORT' )              THEN 'Packed Ready To Export'
                                                            WHEN S.[BoxStatusID] = 27 
                                                                    AND  S.[Shelf] IN ( 'SHIPPING S' )          THEN 'Packed'
                                                            ELSE ISNULL(S.[BoxStatus],'')
                                                        END AS VARCHAR(50))
                    ,[DueDate]                    = BL.[DueDate]
                    ,[CustomerOrder]              = BL.[CustomerOrder]
                    ,[Order_No]                   = BL.[Order_No]
                    ,[ItemDetailID]               = S.[ItemDetailID]
                    ,[ManufactureID]              = S.[ManufactureID]
                    ,[MO]                         = S.[MO]
                    ,[BundleID]                   = CAST(NULL AS INT)
                    ,[BundleBarcode]              = CAST(NULL AS VARCHAR(200))
                    ,[BoxID]                      = S.[BoxID]
                    ,[BoxNumber]                  = S.[BoxNumber]
                    ,[FormattedBoxNumber]         = S.[FormattedBoxNumber]
                    ,[RequiredDate]               = S.[RequiredDate]
                    ,[PONumber]                   = S.[PONumber]
                    ,[Style]                      = S.[Style]
                    ,[Season]                     = S.[Season]
                    ,[Color]                      = S.[Color]
                    ,[Size]                       = S.[Size]
                    ,[Quantity]                   = S.[Quantity]
                    ,[OriginalQuantity]           = S.[Quantity]
                    ,[QtyWithDraw]                = CAST(0 AS INT)
                    ,[Status]                     = S.[BoxStatus]
                    ,[ProductionStatus]           = S.[BoxStatus]
                    ,[PreviewLCAComments]         = S.[BoxStatus]
                    ,[OrderID]                    = S.[OrderID]
                    ,[Bucket]                     = S.[Bucket]
                    ,[StyleSubcategory]           = S.[StyleSubcategory]
                    ,[StockCategory]              = S.[StockCategory]
                    ,[Collection]                 = S.[Collection]
                    ,[PWModulo]                   = S.[PWModulo]
                    ,[Availability]               = S.[Availability]
                    ,[SewingDate]                 = S.[SewingDate]
                    ,[FabricDD]                   = S.[FabricDD]
                    ,[Waybill]                    = S.[Waybill]
                    ,[ShipDate]                   = S.[ShipDate]
                FROM #TB_BACKLOG_PACKING_SHIP_WIP AS S
                INNER JOIN #TB_BACKLOG_L2BRAND_ACTIVE AS BL ON BL.[ItemDetailID] = S.[ItemDetailID]
                WHERE ISNULL(S.[Quantity],0) > 0
                
                -- SELECT * FROM #TB_BACKLOG_INVENTORY_UNIFIED
                -- RETURN
                
                -- SELECT * FROM LCA.DBO.STATUSNAMES WHERE STATUSID IN (25,27,75)
                ---Memiin1194
                
                -- select * from #TB_BACKLOG_PACKING_SHIP_WIP
                -- where ItemDetailID in( 
                --     5988003
                --     ,5851617
                -- )
                
                -- return


                -- DROP TABLE IF EXISTS #TB_BACKLOG_PACKING_SHIP_WIP

                UPDATE U
                SET
                     [Inv_Pack_Date]          = L.[Inv_Pack_Date]
                    ,[discard_by_percentage]  = L.[discard_by_percentage]
                FROM #TB_BACKLOG_INVENTORY_UNIFIED AS U
                LEFT JOIN #TB_LOOKUP_ORD_DEMAND_BY_MO AS L
                    ON L.[MO_ID] = U.[ManufactureID]

                UPDATE U
                SET [ProductDivision] = IIF(TRIM(ISNULL(ST.[Comments9],'')) = 'Headwear','Headwear','Apparel')
                FROM #TB_BACKLOG_INVENTORY_UNIFIED AS U
                LEFT JOIN [LCA].[dbo].[Styles] AS ST WITH(NOLOCK)
                    ON REPLACE(REPLACE(REPLACE(RTRIM(ST.[StyleNumber]), CHAR(9), ''), CHAR(10), ''), CHAR(13), '') =
                       REPLACE(REPLACE(REPLACE(RTRIM(U.[Style]), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')

                DROP TABLE IF EXISTS #TB_LOOKUP_BACKLOG_DISPATCHED_BY_MO
                SELECT
                     [MO_ID]               = CAST(D.[MO_ID] AS INT)
                    ,[IsNonMixedApproved]  = MAX(CAST(CASE WHEN ISNULL(D.[IsVendorMixed],0) = 0 AND ISNULL(D.[IsFromWIP],0) = 0 THEN 1 ELSE 0 END AS INT))
                    ,[IsMixedApproved]     = MAX(CAST(CASE WHEN ISNULL(D.[IsVendorMixed],0) = 1 AND ISNULL(D.[IsFromWIP],0) = 0 THEN 1 ELSE 0 END AS INT))
                    ,[IsWIPApproved]       = MAX(CAST(CASE WHEN ISNULL(D.[IsFromWIP],0) = 1                                   THEN 1 ELSE 0 END AS INT))
                INTO #TB_LOOKUP_BACKLOG_DISPATCHED_BY_MO
                FROM #DispatchOrdersFromInventoryWIP_OrdersDispatched AS D
                WHERE D.[MO_ID] IS NOT NULL
                GROUP BY CAST(D.[MO_ID] AS INT)

                DROP TABLE IF EXISTS #TB_LOOKUP_BACKLOG_NOTDISPATCHED_BY_MO
                SELECT
                     [MO_ID]                  = CAST(ND.[MO_ID] AS INT)
                    ,[IsDiscardByMPA]         = MAX(CAST(CASE WHEN ND.[CommentFinalNum] = 3 THEN 1 ELSE 0 END AS INT))
                    ,[IsDiscardBySuspended]   = MAX(CAST(CASE WHEN ND.[CommentFinalNum] = 4 THEN 1 ELSE 0 END AS INT))
                    ,[IsDiscardByPercentage]  = MAX(CAST(CASE WHEN ND.[discard_by_percentage] IS NOT NULL OR ND.[CommentFinalNum] = 7 THEN 1 ELSE 0 END AS INT))
                    -- MPA despachada desde warehouse (CommentFinalNum = 5): 'MPA. No inventory on hand'
                    ,[IsMPAApproved]          = MAX(CAST(CASE WHEN ND.[CommentFinal] IN ('Dispatched MPA','Dispatched MPA Mixed Vendor')             THEN 1 ELSE 0 END AS INT))
                    -- MPA despachada desde WIP (CommentFinalNum = 6): 'MPA. No inventory on hand, (in coming)'
                    ,[IsMPAWIPApproved]       = MAX(CAST(CASE WHEN ND.[CommentFinal] IN ('Dispatched MPA WIP','Dispatched MPA WIP Mixed vendor')     THEN 1 ELSE 0 END AS INT))
                INTO #TB_LOOKUP_BACKLOG_NOTDISPATCHED_BY_MO
                FROM #DispatchOrdersFromInventoryWIP_OrdersNotDispatched AS ND
                WHERE ND.[MO_ID] IS NOT NULL
                GROUP BY CAST(ND.[MO_ID] AS INT)

                
            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ----------PROCEDIMIENTO PARA INVENTARIO PACK AND SHIP----------------------------------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            
            
            
            
            UPDATE U
                SET [PreviewLCAComments] = CASE
                                                -- Regla especial: linea HOLD, CANCELED (InventoryLineTypeN = 7)
                                                WHEN U.InventoryLineTypeN = 7 -----QUERY DE HOLD
                                                THEN 'Order Supended'
                                                
                                                -- Regla especial: linea Shipped de exportacion (InventoryLineTypeN = 6)
                                                WHEN U.InventoryLineTypeN = 6 -----QUERY DE EXPORTACION.
                                                THEN U.InventoryLineType
                                                
                                                -- Regla especial: linea Packed/Picked cajas para exportacion (InventoryLineTypeN = 5)
                                                WHEN U.InventoryLineTypeN = 5
                                                THEN U.InventoryLineType
                                                
                                                -- Regla especial: linea Bundles en piso de produccion (InventoryLineTypeN = 4)
                                                WHEN U.InventoryLineTypeN = 4 AND U.PreviewLCAComments = 'NO WIP (Released)'
                                                THEN 'Taking units from warehouse'
                                                
                                                -- Regla especial: linea Bundles en piso de produccion (InventoryLineTypeN = 4)
                                                WHEN U.InventoryLineTypeN = 4 
                                                THEN U.PreviewLCAComments
                                                
                                                -- Regla especial: linea CorteTela en piso de produccion (InventoryLineTypeN = 3)
                                                WHEN U.InventoryLineTypeN = 3 
                                                THEN U.PreviewLCAComments
                                                
                                                -- Regla especial: linea WITHDRAW de bodega (InventoryLineTypeN = 2)
                                                WHEN U.InventoryLineTypeN = 2 
                                                THEN 'Taking units from warehouse'
                                                
                                                -- Regla especial: linea released/forecast no despachadas  de produccion (InventoryLineTypeN = 1)
                                                -- WHEN U.InventoryLineTypeN = 1
                                                -- THEN U.PreviewLCAComments
                        
                                                -- MPA despachada desde warehouse: inventario disponible pero reservado para MPA
                                                WHEN ISNULL(NDSP.[IsMPAApproved],0) = 1
                                                THEN 'MPA. Inventory on hand'
                                                
                                                -- MPA despachada desde WIP: inventario incoming pero reservado para MPA
                                                WHEN ISNULL(NDSP.[IsMPAWIPApproved],0) = 1
                                                THEN 'MPA. No inventory on hand, (in coming)'

                                                -- MPA sin inventario disponible
                                                WHEN ISNULL(NDSP.[IsDiscardByMPA],0) = 1
                                                THEN 'MPA. No inventory on hand'

                                                -- Aprobadas sin mezcla de vendor en despacho (warehouse) Que ya fueron enviadas en un listado.
                                                WHEN ISNULL(DSP.[IsNonMixedApproved],0) = 1 AND U.[PWModulo] LIKE 'ASSIGNMENT%'
                                                THEN 'Orders in assigment' 
                                                
                                                -- Aprobadas sin mezcla de vendor en despacho (warehouse)
                                                WHEN ISNULL(DSP.[IsNonMixedApproved],0) = 1
                                                THEN 'Inventory on hand'

                                                -- Aprobadas con mezcla de vendor en despacho (warehouse)
                                                WHEN ISNULL(DSP.[IsMixedApproved],0) = 1
                                                THEN 'Split Inventory'

                                                -- Aprobadas desde WIP (con o sin mezcla de vendor)
                                                WHEN ISNULL(DSP.[IsWIPApproved],0) = 1
                                                THEN 'No inventory on hand, (in coming)'
                        
                                                -- No despachada por suspend
                                                WHEN ISNULL(NDSP.[IsDiscardBySuspended],0) = 1
                                                THEN 'Order Supended'
                        
                                                -- No despachada por porcentaje de cumplimiento de CustomerOrder
                                                WHEN ISNULL(NDSP.[IsDiscardByPercentage],0) = 1
                                                THEN 'PO is not cover by fullfiment percentage'
                        
                                                -- Si no entro en reglas anteriores y Season es EMB/EMB FG
                                                WHEN UPPER(LTRIM(RTRIM(ISNULL(U.[Season],'')))) IN ('EMB','EMB FG')
                                                THEN 'No Inventory on hand'
                        
                                                -- Si no entro en reglas anteriores, Season no EMB/EMB FG y Availability = 100
                                                WHEN UPPER(LTRIM(RTRIM(ISNULL(U.[Season],'')))) NOT IN ('EMB','EMB FG')
                                                     AND TRY_CAST(U.[Availability] AS DECIMAL(18,4)) = CAST(100 AS DECIMAL(18,4))
                                                THEN 'Fabric on hand'
                        
                                                -- Si no entro en reglas anteriores, Season no EMB/EMB FG y Availability <> 100 o NULL
                                                WHEN UPPER(LTRIM(RTRIM(ISNULL(U.[Season],'')))) NOT IN ('EMB','EMB FG')
                                                     AND (U.[Availability] IS NULL OR TRY_CAST(U.[Availability] AS DECIMAL(18,4)) <> CAST(100 AS DECIMAL(18,4)))
                                                THEN 'Waiting for the arrival of fabric'
                                                
                                                -- Fallback temporal para auditoria
                                                ELSE 'OTRO'
                                            END
                FROM #TB_BACKLOG_INVENTORY_UNIFIED AS U
                LEFT JOIN #TB_LOOKUP_BACKLOG_DISPATCHED_BY_MO    AS DSP  ON DSP.[MO_ID]  = U.[ManufactureID]
                LEFT JOIN #TB_LOOKUP_BACKLOG_NOTDISPATCHED_BY_MO AS NDSP ON NDSP.[MO_ID] = U.[ManufactureID]

                DROP TABLE IF EXISTS #TB_LOOKUP_BACKLOG_DISPATCHED_BY_MO
                DROP TABLE IF EXISTS #TB_LOOKUP_BACKLOG_NOTDISPATCHED_BY_MO

            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
                SET [Percent] = 95,
                    [StepCode] = 'BACKLOG',
                    [StepNameUser] = 'Generando backlog',
                    [MessageUser] = 'Estamos preparando la base final para backlog tomando informacion de L2BRAND -> LCA por talla.',
                    [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE RELEASED/FORECAST POR TALLA'),500),
                    [UpdatedAt] = SYSDATETIME()
                WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            
            
           
                
            
            -- DateInsertAOO: fecha (MIN Insert_time) en que la orden entro al sistema.
            -- Prioridad: log remoto (VW_view_qryLCA_Order_Export_Logs); si el ItemDetailID no tiene
            -- ningun registro en el log, se usa el MIN Insert_time de VW_view_qryLCA_Order_Export (local).
            DROP TABLE IF EXISTS #TB_LOOKUP_BACKLOG_DATEINSERT_LOG
            SELECT
                 LOGS.[ItemDetailID]
                ,[MinInsertLog] = MIN(LOGS.[Insert_time])
            INTO #TB_LOOKUP_BACKLOG_DATEINSERT_LOG
            FROM #TB_BACKLOG_L2BRAND_ACTIVE_UNIQUE_ITEMDETAILID AS FIL
            INNER JOIN [192.168.1.93].[AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export_Logs] AS LOGS WITH(NOLOCK)
                ON LOGS.[ItemDetailID] = FIL.[ItemDetailID]
            GROUP BY LOGS.[ItemDetailID]

            DROP TABLE IF EXISTS #TB_LOOKUP_BACKLOG_DATEINSERT_ORD
            SELECT
                 ORD.[ItemDetailID]
                ,[MinInsertOrd] = MIN(ORD.[Insert_time])
            INTO #TB_LOOKUP_BACKLOG_DATEINSERT_ORD
            FROM #TB_BACKLOG_L2BRAND_ACTIVE_UNIQUE_ITEMDETAILID AS FIL
            INNER JOIN [AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export] AS ORD WITH(NOLOCK)
                ON ORD.[ItemDetailID] = FIL.[ItemDetailID]
            GROUP BY ORD.[ItemDetailID]

            DROP TABLE IF EXISTS #TB_LOOKUP_BACKLOG_DATEINSERT_AOO
            SELECT
                 FIL.[ItemDetailID]
                ,[DateInsertAOO] = CAST(COALESCE(LG.[MinInsertLog], OD2.[MinInsertOrd]) AS DATE)
            INTO #TB_LOOKUP_BACKLOG_DATEINSERT_AOO
            FROM #TB_BACKLOG_L2BRAND_ACTIVE_UNIQUE_ITEMDETAILID AS FIL
            LEFT JOIN #TB_LOOKUP_BACKLOG_DATEINSERT_LOG AS LG  ON LG.[ItemDetailID]  = FIL.[ItemDetailID]
            LEFT JOIN #TB_LOOKUP_BACKLOG_DATEINSERT_ORD AS OD2 ON OD2.[ItemDetailID] = FIL.[ItemDetailID]

            DROP TABLE IF EXISTS #TB_LOOKUP_BACKLOG_DATEINSERT_LOG
            DROP TABLE IF EXISTS #TB_LOOKUP_BACKLOG_DATEINSERT_ORD

            DROP TABLE IF EXISTS #TB_LOOKUP_BACKLOG_ORD_DATES
            SELECT TB.*
            INTO #TB_LOOKUP_BACKLOG_ORD_DATES
            FROM (
                SELECT
                     ORD.[ItemDetailID]
                    ,[Doc Date]              = ORD.[Doc Date]
                    ,[Cust Due Date]         = TRY_CAST(ORD.[CustDueDate] AS DATE)
                    ,[Original Request Date] = TRY_CAST(ORD.[OriginalRequestDate] AS DATE)
                    ,[PromiseDate]           = TRY_CAST(ORD.[PromiseDate] AS DATE)
                    ,[InventoryDate]         = TRY_CAST(ORD.[InventoryDate] AS DATE)
                    ,[R_Num] = ROW_NUMBER() OVER(PARTITION BY ORD.[ItemDetailID] ORDER BY ORD.[ItemDetailID])
                FROM #TB_BACKLOG_L2BRAND_ACTIVE AS S
                INNER JOIN [AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export] AS ORD WITH(NOLOCK)
                    ON ORD.[ItemDetailID] = S.[ItemDetailID]
            ) AS TB
            WHERE TB.[R_Num] = 1

            DROP TABLE IF EXISTS #TB_BACKLOG_FINAL
            SELECT
                 [FinalRowData]                     = ROW_NUMBER() OVER(
                                                        ORDER BY
                                                             L2.[DueDate] ASC
                                                            ,L2.[Order_No] ASC
                                                            ,L2.[ItemDetailID] ASC
                                                            ,ISNULL(U.[InventoryLineTypeN],99) ASC
                                                            ,ISNULL(U.[RowData],0) ASC
                                                      )
                ,[L2_RowData]                       = L2.[RowData]
                ,[L2_created_at]                    = L2.[created_at]
                ,[L2_DueDate]                       = L2.[DueDate]
                ,[L2_Week]                          = L2.[Week]
                ,[L2_CustomerOrder]                 = L2.[CustomerOrder]
                ,[L2_CustName]                      = L2.[CustName]
                ,[L2_Order_No]                      = L2.[Order_No]
                ,[L2_ItemDetailID]                  = L2.[ItemDetailID]
                ,[L2_Quantity]                      = L2.[Quantity]
                ,[L2_DetailStatus]                  = L2.[DetailStatus]
                ,[L2_SKUStatus]                     = L2.[SKUStatus]
                ,[L2_Status]                        = L2.[Status]
                ,[ArtStatus]                        = L2.[ArtStatus]
                ,[Status/Date]                      = L2.[Status/Date]
                ,[PriceCode]                        = L2.[PriceCode]
                ,[L2_ProductDivision]               = L2.[ProductDivision]
                ,[L2_LogoStyle]                     = L2.[LogoStyle]
                ,[L2_ApplicationType]               = L2.[ApplicationType]
                ,[L2_GroupID]                       = L2.[GroupID]
                ,[L2_RS_Priority]                   = L2.[RS_Priority]
                ,[L2_Style_Color]                   = L2.[Style_Color]
                ,[L2_StyleID]                       = L2.[StyleID]
                ,[L2_CSRID]                         = L2.[CSRID]
                ,[L2_CSRName]                       = L2.[CSRName]
                ,[L2_Style_Sales_Status]            = L2.[Style_Sales_Status]
                ,[L2_DesignNo]                      = L2.[DesignNo]
                ,[L2_SKUID]                         = L2.[SKUID]
                ,[L2_Relabel]                       = L2.[Relabel]
                ,[L2_EventDate]                     = L2.[EventDate]
                ,[L2_SKLogoNo]                      = L2.[SKLogoNo]
                ,[L2_CustPO]                        = L2.[CustPO]             
                ,[L2_ShipEarly]                     = L2.[ShipEarly]
                ,[L2_ShipTo]                        = L2.[ShipTo]
                ,[L2_Group]                         = L2.[Group]
                ,[L2_MachineGroup]                  = L2.[MachineGroup]
                ,[L2_SalesChannel]                  = L2.[SalesChannel]
                ,[L2_LicenseSticker]                = L2.[LicenseSticker]  
                ,[L2_HotOrder]                      = L2.[HotOrder]        
                ,[L2_Window]                        = L2.[window]
                ,[Type]                             = L2.[Type]
                ,[TypeEmbroidery]                   = L2.[TypeEmbroidery]
                ,[Technique]                        = L2.[Technique]
                
                ,[ScreenPrint]                      = L2.[ScreenPrint]          
                ,[ScreenPrintAfter]	                = L2.[ScreenPrintAfter]	    
                ,[ScreenPrintBefore]                = L2.[ScreenPrintBefore]    
                ,[SublimationBefore]                = L2.[SublimationBefore]    
                ,[SublimationAfter]	                = L2.[SublimationAfter]	    
                ,[HDP]			                    = L2.[HDP]			        
                ,[Blanks]			                = L2.[Blanks]			    
                ,[Embroidery]		                = L2.[Embroidery]		    
                ,[EmbHWApplique]                    = L2.[EmbHWApplique]        
                ,[EmbHWDirect]                      = L2.[EmbHWDirect]          
                ,[EmbHWPatch]                       = L2.[EmbHWPatch]           
                ,[EmbHWHDP]                         = L2.[EmbHWHDP]             
                ,[EmbAppDirect]                     = L2.[EmbAppDirect]         
                ,[EmbAppLBA]                        = L2.[EmbAppLBA]            
                
                ,[Qty_ScreenPrint]                  = IIF(U.[InventoryLineTypeN] IS NULL, L2.[Quantity], U.[Quantity]) * L2.[ScreenPrint]          
                ,[Qty_ScreenPrintAfter]	            = IIF(U.[InventoryLineTypeN] IS NULL, L2.[Quantity], U.[Quantity]) * L2.[ScreenPrintAfter]	    
                ,[Qty_ScreenPrintBefore]            = IIF(U.[InventoryLineTypeN] IS NULL, L2.[Quantity], U.[Quantity]) * L2.[ScreenPrintBefore]    
                ,[Qty_SublimationBefore]            = IIF(U.[InventoryLineTypeN] IS NULL, L2.[Quantity], U.[Quantity]) * L2.[SublimationBefore]    
                ,[Qty_SublimationAfter]	            = IIF(U.[InventoryLineTypeN] IS NULL, L2.[Quantity], U.[Quantity]) * L2.[SublimationAfter]	    
                ,[Qty_HDP]			                = IIF(U.[InventoryLineTypeN] IS NULL, L2.[Quantity], U.[Quantity]) * L2.[HDP]			        
                ,[Qty_Blanks]			            = IIF(U.[InventoryLineTypeN] IS NULL, L2.[Quantity], U.[Quantity]) * L2.[Blanks]			    
                ,[Qty_Embroidery]		            = IIF(U.[InventoryLineTypeN] IS NULL, L2.[Quantity], U.[Quantity]) * L2.[Embroidery]		    
                ,[Qty_EmbHWApplique]                = IIF(U.[InventoryLineTypeN] IS NULL, L2.[Quantity], U.[Quantity]) * L2.[EmbHWApplique]        
                ,[Qty_EmbHWDirect]                  = IIF(U.[InventoryLineTypeN] IS NULL, L2.[Quantity], U.[Quantity]) * L2.[EmbHWDirect]          
                ,[Qty_EmbHWPatch]                   = IIF(U.[InventoryLineTypeN] IS NULL, L2.[Quantity], U.[Quantity]) * L2.[EmbHWPatch]           
                ,[Qty_EmbHWHDP]                     = IIF(U.[InventoryLineTypeN] IS NULL, L2.[Quantity], U.[Quantity]) * L2.[EmbHWHDP]             
                ,[Qty_EmbAppDirect]                 = IIF(U.[InventoryLineTypeN] IS NULL, L2.[Quantity], U.[Quantity]) * L2.[EmbAppDirect]         
                ,[Qty_EmbAppLBA]                    = IIF(U.[InventoryLineTypeN] IS NULL, L2.[Quantity], U.[Quantity]) * L2.[EmbAppLBA]            

                
                ,[InventoryLineTypeN]               = U.[InventoryLineTypeN]
                ,[InventoryLineType]                = U.[InventoryLineType]
                ,[OrderID]                          = U.[OrderID]
                ,[PONumber]                         = U.[PONumber]
                ,[RequiredDate]                     = U.[RequiredDate]
                ,[ManufactureID]                    = U.[ManufactureID]
                ,[MO]                               = U.[MO]
                ,[Style]                            = U.[Style]
                ,[Season]                           = U.[Season]
                ,[Color]                            = U.[Color]
                ,[Size]                             = U.[Size]
                ,[Quantity]                         = CASE 
                                                        WHEN U.[InventoryLineTypeN] IS NULL
                                                        THEN L2.[Quantity]
                                                        ELSE U.[Quantity]
                                                        END
                ,[OriginalQuantity]                 = U.[OriginalQuantity]
                ,[QtyWithDraw]                      = U.[QtyWithDraw]
                ,[BundleID]                         = U.[BundleID]
                ,[BundleBarcode]                    = U.[BundleBarcode]
                ,[BoxID]                            = U.[BoxID]
                ,[BoxNumber]                        = U.[BoxNumber]
                ,[FormattedBoxNumber]               = U.[FormattedBoxNumber]
                ,[Status]                           = U.[Status]
                ,[ProductionStatus]                 = U.[ProductionStatus]
                ,[StyleSubcategory]                 = U.[StyleSubcategory]
                ,[StockCategory]                    = U.[StockCategory]
                ,[Collection]                       = U.[Collection]
                ,[PWModulo]                         = U.[PWModulo]
                ,[Bucket]                           = U.[Bucket]
                ,[NewBucket]                        = U.[NewBucket]
                ,[FabricDD]                         = U.[FabricDD]
                ,[SewingDate]                       = U.[SewingDate]
                ,[Inv_Pack_Date]                    = U.[Inv_Pack_Date]
                ,[Availability]                     = U.[Availability]
                ,[ProductDivision]                  = IIF((L2.[Style_Color] LIKE '%BUNDLE%'),'Bundles',U.[ProductDivision])
                ,[Waybill]                          = U.[Waybill]
                ,[ShipDate]                         = U.[ShipDate]
                ,[discard_by_percentage]            = U.[discard_by_percentage]
                ,[DateArriveInPackingForOrder]      = U.[DateArriveInPackingForOrder]
                ,[PreviewLCAComments]               = CASE
                                                        
                                                            WHEN L2.[Style_Color] LIKE '%BUNDLE%'
                                                            THEN 'Bundle order'
                                                            
                                                            WHEN  U.[InventoryLineTypeN] IS NULL
                                                            -- WHEN L2.[ArtStatus] = 'NO RFP' AND U.[InventoryLineTypeN] IS NULL
                                                            THEN 'Orders in process to be imported into PolyPM'
                                                             
                                                            
                                                        ELSE
                                                            U.[PreviewLCAComments]
                                                        END
                ,[LCAComments]                      = U.[LCAComments]
                ,[TakeForProcedure]                 = U.[TakeForProcedure]
                ,[DateForConteiner]                 = U.[DateForConteiner]
                ,[LateOrder]                        = U.[LateOrder]
                ,[DaysLateOrder]                    = U.[DaysLateOrder]
                ,[Doc Date]                         = OD.[Doc Date]
                ,[Cust Due Date]                    = OD.[Cust Due Date]
                ,[Original Request Date]            = OD.[Original Request Date]
                ,[PromiseDate]                      = OD.[PromiseDate]
                ,[InventoryDate]                    = OD.[InventoryDate]
                ,[DateInsertAOO]                    = DIA.[DateInsertAOO]
                ,[RunDate]                          = CASE @RunDate
                                                         WHEN 'DocDate'             THEN OD.[Doc Date]
                                                         WHEN 'CustDueDate'         THEN OD.[Cust Due Date]
                                                         WHEN 'OriginalRequestDate' THEN OD.[Original Request Date]
                                                         WHEN 'PromiseDate'         THEN OD.[PromiseDate]
                                                         ELSE                            L2.[DueDate]
                                                         
                                                     END
                                                    --  CASE @RunDate
                                                    --         WHEN 'DocDate'             THEN B.[Doc Date]
                                                    --         WHEN 'CustDueDate'         THEN TRY_CAST(B.[CustDueDate]         AS DATE)
                                                    --         WHEN 'OriginalRequestDate' THEN TRY_CAST(B.[OriginalRequestDate] AS DATE)
                                                    --         WHEN 'PromiseDate'         THEN TRY_CAST(B.[PromiseDate]         AS DATE)
                                                    --         ELSE                            B.[Req Ship]
            INTO #TB_BACKLOG_FINAL
            FROM #TB_BACKLOG_L2BRAND_ACTIVE AS L2
            LEFT JOIN #TB_BACKLOG_INVENTORY_UNIFIED AS U
                ON U.[ItemDetailID] = L2.[ItemDetailID]
            LEFT JOIN #TB_LOOKUP_BACKLOG_ORD_DATES AS OD
                ON OD.[ItemDetailID] = L2.[ItemDetailID]
            LEFT JOIN #TB_LOOKUP_BACKLOG_DATEINSERT_AOO AS DIA
                ON DIA.[ItemDetailID] = L2.[ItemDetailID]

                
                --   select * from #TB_BACKLOG_FINAL
                -- where L2_ItemDetailID in( 
                --     5988003
                --     ,5851617
                --     ,5973100
                --     ,6005187
                --     ,6008849
                --     ,6010242
                --     ,6032559
                --     ,6032858

                -- )
                
            DROP TABLE IF EXISTS #TB_ORDERS_CREATE_MO
            
            SELECT DISTINCT [ItemDetailID] 
            INTO #TB_ORDERS_CREATE_MO
            FROM(
            	SELECT 
            		[ItemDetailID]               = CASE
            															WHEN ORD.[PONumber] LIKE 'ORD-PO%' THEN NULL
            															WHEN ORD.[PONumber] LIKE 'ORD-%' AND ISNUMERIC(REPLACE(ORD.[PONumber],'ORD-','')) = 1 THEN TRY_CAST(REPLACE(ORD.[PONumber],'ORD-','') AS BIGINT)
            															WHEN ORD.[PONumber] LIKE 'ORD%' AND ISNUMERIC(ORD.[Comments6]) = 1 THEN TRY_CAST(ORD.[Comments6] AS BIGINT)
            															ELSE NULL
            														 END
            		,ORD.PONumber
            		,SN.StatusID
            		,SN.StatusName
            	FROM LCA.dbo.Orders AS ORD WITH(NOLOCK)
            	INNER JOIN LCA.DBO.StatusNames AS SN WITH(NOLOCK) ON SN.StatusID = ORD.StatusID AND SN.StatusID IN (10,20,40)
            	LEFT JOIN LCA.DBO.OrderItems AS OI WITH(NOLOCK) ON OI.OrderID = ORD.OrderID
            	LEFT JOIN LCA.DBO.ManufactureOrders AS MO WITH(NOLOCK) ON MO.FirstOrderItemID = OI.OrderItemID
            	WHERE MO.ManufactureID IS NULL
            ) AS TB
            WHERE ItemDetailID IS NOT NULL
            
            UPDATE S SET
                [PreviewLCAComments] = 'Orders in process to create MO'
            FROM #TB_BACKLOG_FINAL AS S
            INNER JOIN #TB_ORDERS_CREATE_MO AS B ON B.ItemDetailID = S.L2_ItemDetailID
            WHERE S.[PreviewLCAComments] = 'Orders in process to be imported into PolyPM'
            
          
            
            
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
                SET [Percent] = 97,
                    [StepCode] = 'BACKLOG',
                    [StepNameUser] = 'Generando backlog',
                    [MessageUser] = 'Backlog LCA por talla. Actualizando LCAComments y fecha de arribo en packing.',
                    [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE RELEASED/FORECAST POR TALLA'),500),
                    [UpdatedAt] = SYSDATETIME()
                WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
                
            UPDATE F
            SET [LCAComments] = CASE
                    WHEN ISNULL(LTRIM(RTRIM(TB_LCM.[OrderReport])),'') = ''
                    THEN F.[PreviewLCAComments]
                    ELSE CONCAT(
                             RIGHT(CONCAT('0000',CAST(TRY_CAST(TB_LCM.[OrderReport] AS INT) AS VARCHAR(20))),4)
                            ,','
                            ,F.[PreviewLCAComments]
                         )
                END
            FROM #TB_BACKLOG_FINAL AS F
            LEFT JOIN #TB_LCAComments AS TB_LCM
                ON REPLACE(REPLACE(REPLACE(TB_LCM.[LCAComments], CHAR(10), ''), CHAR(9), ''), CHAR(13), '') =
                   REPLACE(REPLACE(REPLACE(F.[PreviewLCAComments], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')

            UPDATE F
            SET [NewBucket] = CASE
                    WHEN F.[PreviewLCAComments] = 'Shipped'
                    THEN '00-Shipped'
                    WHEN F.[ArtStatus] = 'NO RFP'
                    THEN 'NO RFP'
                    WHEN F.[L2_DueDate] >= CAST(DATEADD(DAY,91,GETDATE()) AS DATE)
                    THEN 'TBD'
                    ELSE NULL
                END
            FROM #TB_BACKLOG_FINAL AS F

            ;WITH CTE_BacklogOrder AS (
                SELECT
                     F.[FinalRowData]
                    ,[RN] = ROW_NUMBER() OVER(
                                ORDER BY
                                     F.[L2_DueDate] ASC
                                    ,F.[L2_Order_No] ASC
                                    ,F.[L2_ItemDetailID] ASC
                                    ,F.[InventoryLineTypeN] ASC
                                    ,F.[FinalRowData] ASC
                              )
                FROM #TB_BACKLOG_FINAL AS F
            )
            UPDATE CTE_BacklogOrder
            SET [FinalRowData] = [RN]

            UPDATE F
            SET [DateArriveInPackingForOrder] = CASE
                    WHEN    TB_LCM.[DateInPacking] = 'Today'
                        AND F.[NewBucket] IS NULL
                    THEN DATEADD(DAY,TB_LCM.[DaysArriveInPacking],CAST(GETDATE() AS DATE))

                    WHEN    TB_LCM.[DateInPacking] = 'Sewing'
                        AND F.[SewingDate] IS NOT NULL
                        AND F.[NewBucket] IS NULL
                    THEN DATEADD(DAY,TB_LCM.[DaysArriveInPacking],CAST(F.[SewingDate] AS DATE))

                    WHEN    TB_LCM.[DateInPacking] = 'FabricDD'
                        AND TRY_CAST(F.[FabricDD] AS DATE) IS NOT NULL
                        AND F.[NewBucket] IS NULL
                    THEN DATEADD(DAY,TB_LCM.[DaysArriveInPacking],TRY_CAST(F.[FabricDD] AS DATE))

                    WHEN    TB_LCM.[DateInPacking] = 'Inv_Pack_Date'
                        AND TB_IPD.[Inv_Pack_Date] IS NOT NULL
                        AND F.[NewBucket] IS NULL
                    THEN DATEADD(DAY,TB_LCM.[DaysArriveInPacking],CAST(TB_IPD.[Inv_Pack_Date] AS DATE))

                    ELSE NULL
                END
            FROM #TB_BACKLOG_FINAL AS F
            LEFT JOIN #TB_LCAComments AS TB_LCM
                ON REPLACE(REPLACE(REPLACE(TB_LCM.[LCAComments], CHAR(10), ''), CHAR(9), ''), CHAR(13), '') =
                   REPLACE(REPLACE(REPLACE(F.[PreviewLCAComments], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')
            LEFT JOIN #TB_LOOKUP_ORD_DEMAND_BY_MO AS TB_IPD
                ON TB_IPD.[MO_ID] = F.[ManufactureID]

            UPDATE F
            SET [TakeForProcedure] = CASE 
                    WHEN   ( TB_LCM.[OrderDispatch] = 0                 )
                        OR ( F.[NewBucket] IS NOT NULL                  )
                        OR (    TB_LCM.[DateInPacking] = 'Sewing'       
                            AND F.[SewingDate] IS NULL                  )
                        OR (    TB_LCM.[DateInPacking] = 'FabricDD'     
                            AND F.[FabricDD] IS  NULL                   )
                        OR (    TB_LCM.[DateInPacking] = 'Inv_Pack_Date'
                            AND F.[Inv_Pack_Date] IS  NULL              )
                    THEN 0 
                    ELSE 1
                END
            FROM #TB_BACKLOG_FINAL AS F
            LEFT JOIN #TB_LCAComments AS TB_LCM
                ON REPLACE(REPLACE(REPLACE(TB_LCM.[LCAComments], CHAR(10), ''), CHAR(9), ''), CHAR(13), '') =
                   REPLACE(REPLACE(REPLACE(F.[PreviewLCAComments], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')
            
            ------------------------------------------------------------
            -- SET-BASED: ASIGNACION DE DATE_CONTAINER A BACKLOG
            ------------------------------------------------------------
            IF OBJECT_ID('tempdb..#TB_BACKLOG_FINAL') IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM tempdb.sys.indexes
                    WHERE [name] = 'IX_TB_BACKLOG_FINAL_L2ItemDetailID'
                      AND [object_id] = OBJECT_ID('tempdb..#TB_BACKLOG_FINAL')
               )
            BEGIN
                CREATE INDEX IX_TB_BACKLOG_FINAL_L2ItemDetailID
                    ON #TB_BACKLOG_FINAL ([L2_ItemDetailID]);
            END

            IF OBJECT_ID('tempdb..#TB_FINAL_PROC_DATES') IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM tempdb.sys.indexes
                    WHERE [name] = 'IX_TB_FINAL_PROC_DATES_Row'
                      AND [object_id] = OBJECT_ID('tempdb..#TB_FINAL_PROC_DATES')
               )
            BEGIN
                CREATE INDEX IX_TB_FINAL_PROC_DATES_Row
                    ON #TB_FINAL_PROC_DATES ([Row]);
            END

            DROP TABLE IF EXISTS #TB_BACKLOG_CONTAINER_CANDIDATE
            SELECT
                 [OrderForProcedure]  = F.[L2_ItemDetailID]
                ,[Ord_DueDate]        = MIN(F.[L2_DueDate])
                ,[ShipEarly]          = MAX(F.[L2_ShipEarly])
                ,[Ord_Volume]         = CAST(
                                            CASE
                                                WHEN SUM(ISNULL(F.[Quantity],0)) <= 0 OR ISNULL(@UnitsInBox,0) = 0
                                                THEN 0
                                                ELSE CEILING((SUM(ISNULL(F.[Quantity],0)) * ISNULL(@UnitVolume,1.0)) / NULLIF(@UnitsInBox,0)) * ISNULL(@UnitVolume,1.0)
                                            END
                                         AS FLOAT)
                ,[Ord_Units]          = SUM(ISNULL(F.[Quantity],0))
                ,[Ord_PackDate]       = MAX(F.[DateArriveInPackingForOrder])
            INTO #TB_BACKLOG_CONTAINER_CANDIDATE
            FROM #TB_BACKLOG_FINAL AS F
            WHERE F.[TakeForProcedure] = 1
              AND F.[NewBucket] IS NULL
              AND F.[L2_ItemDetailID] IS NOT NULL
            GROUP BY
                 F.[L2_ItemDetailID]

            IF OBJECT_ID('tempdb..#TB_BACKLOG_CONTAINER_CANDIDATE') IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM tempdb.sys.indexes
                    WHERE [name] = 'IX_TB_BACKLOG_CONTAINER_CANDIDATE_Order'
                      AND [object_id] = OBJECT_ID('tempdb..#TB_BACKLOG_CONTAINER_CANDIDATE')
               )
            BEGIN
                CREATE INDEX IX_TB_BACKLOG_CONTAINER_CANDIDATE_Order
                    ON #TB_BACKLOG_CONTAINER_CANDIDATE ([OrderForProcedure]);
            END

            ;WITH MatchContainer AS (
                SELECT
                     D.[OrderForProcedure]
                    ,C.[Row]               AS MatchedContainerRow
                    ,C.[Date_Container]    AS Cont_DateContainer
                    ,ROW_NUMBER() OVER (
                        PARTITION BY D.[OrderForProcedure]
                        ORDER BY C.[Date_Container] ASC
                    ) AS rn
                FROM #TB_BACKLOG_CONTAINER_CANDIDATE AS D
                CROSS APPLY (
                    SELECT C.*
                    FROM #TB_FINAL_PROC_DATES AS C
                    WHERE
                        (C.[Box_InContainer] + D.[Ord_Volume]) <= C.[Max_InContainer]
                        AND (
                                D.[Ord_DueDate] <= C.[DueDate_Container]
                                OR D.[ShipEarly] = 1
                            )
                        AND D.[Ord_PackDate] <= DATEADD(DAY, -3, C.[Date_Container])
                ) AS C
            ),
            FirstValidContainer AS (
                SELECT *
                FROM MatchContainer
                WHERE rn = 1
            )
            
            UPDATE F
            SET
                F.[NewBucket]         = CAST(FVC.[Cont_DateContainer] AS VARCHAR(20))
               ,F.[DateForConteiner]  = FVC.[Cont_DateContainer]
               ,F.[LateOrder]         = CASE WHEN FVC.[Cont_DateContainer] >= F.[L2_DueDate] THEN 1 ELSE 0 END
               ,F.[DaysLateOrder]     = DATEDIFF(DAY, F.[L2_DueDate], FVC.[Cont_DateContainer])
            FROM #TB_BACKLOG_FINAL AS F
            INNER JOIN FirstValidContainer AS FVC
                ON FVC.[OrderForProcedure] = F.[L2_ItemDetailID]
            WHERE F.[TakeForProcedure] = 1
              AND F.[NewBucket] IS NULL

            ;WITH MatchContainer AS (
                SELECT
                     D.[OrderForProcedure]
                    ,C.[Row]                   AS MatchedContainerRow
                    ,D.[Ord_Volume]
                    ,D.[Ord_Units]
                    ,ROW_NUMBER() OVER (
                        PARTITION BY D.[OrderForProcedure]
                        ORDER BY C.[Date_Container] ASC
                    ) AS rn
                FROM #TB_BACKLOG_CONTAINER_CANDIDATE AS D
                CROSS APPLY (
                    SELECT C.*
                    FROM #TB_FINAL_PROC_DATES AS C
                    WHERE
                        (C.[Box_InContainer] + D.[Ord_Volume]) <= C.[Max_InContainer]
                        AND (
                                D.[Ord_DueDate] <= C.[DueDate_Container]
                                OR D.[ShipEarly] = 1
                            )
                        AND D.[Ord_PackDate] <= DATEADD(DAY, -3, C.[Date_Container])
                ) AS C
            ),
            FirstValidContainer AS (
                SELECT *
                FROM MatchContainer
                WHERE rn = 1
            )
            UPDATE C
            SET
                C.[Box_InContainer]   = C.[Box_InContainer] + SUMS.[TotalBoxes]
               ,C.[Units_InContainer] = C.[Units_InContainer] + SUMS.[TotalUnits]
            FROM #TB_FINAL_PROC_DATES AS C
            INNER JOIN (
                SELECT
                     FVC.[MatchedContainerRow]
                    ,SUM(FVC.[Ord_Volume]) AS [TotalBoxes]
                    ,SUM(FVC.[Ord_Units])  AS [TotalUnits]
                FROM FirstValidContainer AS FVC
                GROUP BY FVC.[MatchedContainerRow]
            ) AS SUMS
                ON C.[Row] = SUMS.[MatchedContainerRow]

            UPDATE F
            SET
                F.[NewBucket]        = 'Review: Order could not be shipped'
               ,F.[DateForConteiner] = NULL
               ,F.[LateOrder]        = 1
            FROM #TB_BACKLOG_FINAL AS F
            WHERE F.[TakeForProcedure] = 1
              AND F.[NewBucket] IS NULL

            UPDATE F
            SET
                F.[NewBucket] = CONCAT('Review: ',TB_LCM.[DateInPacking],'. Date Parameters do not match')
            FROM #TB_BACKLOG_FINAL AS F
            INNER JOIN #TB_LCAComments AS TB_LCM
                ON REPLACE(REPLACE(REPLACE(TB_LCM.[LCAComments], CHAR(10), ''), CHAR(9), ''), CHAR(13), '') =
                   REPLACE(REPLACE(REPLACE(F.[PreviewLCAComments], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')
            WHERE TB_LCM.[OrderDispatch] <> 0
              AND F.[NewBucket] IS NULL
              AND F.[LCAComments] <> 'No Inventory on hand'

            UPDATE F
            SET
                F.[NewBucket] = 'Review: Create a Blank Order'
            FROM #TB_BACKLOG_FINAL AS F
            INNER JOIN #TB_LCAComments AS TB_LCM
                ON REPLACE(REPLACE(REPLACE(TB_LCM.[LCAComments], CHAR(10), ''), CHAR(9), ''), CHAR(13), '') =
                   REPLACE(REPLACE(REPLACE(F.[PreviewLCAComments], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')
            WHERE TB_LCM.[OrderDispatch] <> 0
              AND F.[NewBucket] IS NULL
              AND F.[LCAComments] = 'No Inventory on hand'

            UPDATE F
            SET
                F.[NewBucket] = 'Review: Orders in process to be imported into PolyPM'
            FROM #TB_BACKLOG_FINAL AS F
            WHERE F.[LCAComments] = 'Orders in process to be imported into PolyPM'
              AND F.[NewBucket] IS NULL

            UPDATE F
            SET
                F.[NewBucket] = 'Review: Orders in process to create MO'
            FROM #TB_BACKLOG_FINAL AS F
            WHERE F.[LCAComments] = 'Orders in process to create MO'
              AND F.[NewBucket] IS NULL

            -- select * from #TB_LCAComments
            
            PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff'),'  FIN    PROCEDIMIENTO PARA GENERACION DE BACKLOG')

        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ----------PROCEDIMIENTO PARA GENERACION DE BACKLOG-------------------------------------------------------------------------------------------------------------------------------
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
         UPDATE [AppsLCA].[dbo].[TB_Global_Process]
                SET [Percent] = 98,
                    [StepCode] = 'BACKLOG',
                    [StepNameUser] = 'Generando backlog',
                    [MessageUser] = 'Generando tablas finales para backlog y DispatchInventory.',
                    [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - PROCEDIMIENTO PARA GENERACION DE BACKLOG. TABLA BASE RELEASED/FORECAST POR TALLA'),500),
                    [UpdatedAt] = SYSDATETIME()
                WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
                
        SET @result = (
            SELECT
                 [KeyGenerated] = @KeyGenerated
                ,[Status]       = 'DONE'
                ,[Process]      = @ProcessName
                ,[DataTables]   = JSON_QUERY(
                    (
                SELECT
                     [Ordenes]                    = JSON_QUERY((SELECT A.* FROM #TB_FINAL_PROC_ORDENES_DEMAND                           AS A ORDER BY A.[RowData]           FOR JSON PATH, INCLUDE_NULL_VALUES))
                    ,[InventarioActivo]           = JSON_QUERY((SELECT A.* FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO                        AS A ORDER BY A.[RowData]           FOR JSON PATH, INCLUDE_NULL_VALUES))
                    ,[DetalleOrdenesDespachadas]  = JSON_QUERY((SELECT A.* FROM #DispatchOrdersFromInventoryWIP                         AS A ORDER BY A.[RowData]           FOR JSON PATH, INCLUDE_NULL_VALUES))
                    ,[OrdenesDespachadas]         = JSON_QUERY((SELECT A.* FROM #DispatchOrdersFromInventoryWIP_OrdersDispatched        AS A ORDER BY A.[RowData]           FOR JSON PATH, INCLUDE_NULL_VALUES))
                    ,[OrdenesNoDespachadas]       = JSON_QUERY((SELECT A.* FROM #DispatchOrdersFromInventoryWIP_OrdersNotDispatched     AS A ORDER BY A.[RowData]           FOR JSON PATH, INCLUDE_NULL_VALUES))
                    ,[CsvFinal]                   = JSON_QUERY((SELECT A.* FROM #TB_FINAL_PROC_CSV                                      AS A ORDER BY A.[Date], A.[Hour]    FOR JSON PATH, INCLUDE_NULL_VALUES))
                    -- ,[BacklogL2BrandActive]       = JSON_QUERY((SELECT A.* FROM #TB_BACKLOG_L2BRAND_ACTIVE                             AS A ORDER BY A.[RowData]            FOR JSON PATH, INCLUDE_NULL_VALUES))
                    -- ,[BacklogLCA]                 = JSON_QUERY((SELECT A.* FROM #TB_BACKLOG_INVENTORY_UNIFIED                          AS A ORDER BY A.[R],A.[RowData]      FOR JSON PATH, INCLUDE_NULL_VALUES))
                    -- ,[Backlog]               = JSON_QUERY((SELECT A.* FROM #TB_BACKLOG_FINAL                                      AS A ORDER BY A.[FinalRowData]       FOR JSON PATH, INCLUDE_NULL_VALUES))
                    ,[Backlog]                    = JSON_QUERY((    
                                                                SELECT 
                                                                     [TypeRunDate] = @RunDate
                                                                    ,[RunDate]                      = A.[RunDate]
                                                                    ,[DueDate]                      = A.[L2_DueDate]
                                                                    ,[PromiseDate]                  = A.[PromiseDate]
                                                                    ,[Doc Date]                     = A.[Doc Date]
                                                                    ,[Cust Due Date]                = A.[Cust Due Date]
                                                                    ,[Original Request Date]        = A.[Original Request Date]
                                                                    ,[DateInsertAOO]                = CAST(A.[DateInsertAOO] AS DATE)
                                                                    ,[Week]                         = CONCAT('WEEK ',RIGHT(CONCAT('00',CAST(DATEPART(WEEK, CAST(A.[RunDate] AS DATE)) AS VARCHAR(2))),2))
                                                                    ,[CustName]                     = A.[L2_CustName]
                                                                    
                                                                    ,[Order_No]                     = A.[L2_Order_No]
                                                                    ,[ItemDetailID]                 = A.[L2_ItemDetailID]
                                                                    ,[L2_Quantity]                  = A.[L2_Quantity]           --COLUMNAS AGREGADA BACKLOG
                                                                    ,[Size]                         = A.[Size]                          ----COLUMNAS AGREGADA BACKLOG             
                                                                    ,[Quantity]                     = A.[Quantity]
                                                                    ,[QtyWithDraw]                  = A.[QtyWithDraw]           --COLUMNAS AGREGADA BACKLOG
                                                                    ,[DetailStatus]                 = A.[L2_DetailStatus]
                                                                    ,[SKUStatus]                    = A.[L2_SKUStatus]
                                                                    ,[Status]                       = A.[L2_Status]
                                                                    ,[LogoStyle]                    = A.[L2_LogoStyle]
                                                                    ,[GroupID]                      = A.[L2_GroupID]
                                                                    ,[RS_Priority]                  = A.[L2_RS_Priority]
                                                                    ,[Style Color]                  = A.[L2_Style_Color]
                                                                    ,[StyleID]                      = A.[L2_StyleID]
                                                                    ,[CSRName]                      = A.[L2_CSRName]
                                                                    ,[DesignNo]                     = A.[L2_DesignNo]
                                                                    ,[SKUID]                        = A.[L2_SKUID]
                                                                    ,[CustPO]                       = A.[L2_CustPO]
                                                                    ,[PriceCode]                    = A.[PriceCode]
                                                                    ,[Product Division]             = A.[L2_ProductDivision]
                                                                    ,[Type]                         = A.[Type]  
                                                                    ,[TypeEmbroidery]               = A.[TypeEmbroidery]  
                                                                    ,[Technique]                    = A.[Technique]
                                                                    ,[MachineGroup]                 = A.[L2_MachineGroup]
                                                                    ,[ApplicationType]              = A.[L2_ApplicationType]       
                                                                    ,[Group]                        = A.[L2_Group]           
                                                                    ,[SalesChannel]                 = A.[L2_SalesChannel]               
                                                                    ,[ArtStatus]                    = A.[ArtStatus]
                                                                    ,[LCAComments]                  = A.[LCAComments]      
                                                                    ,[Last BU]                      = NULL
                                                                    ,[New BU]                       = A.[NewBucket]           
                                                                    ,[Delta]                        = NULL    
                                                                    ,[window]                       = A.[L2_Window]
                                                                    ,[PONumber]                     = A.[PONumber]  
                                                                    ,[MO]                           = A.[MO]
                                                                    ,[ShipTo]                       = A.[L2_ShipTo]           
                                                                    ,[InventoryDate]                = A.[InventoryDate]
                                                                    ,[Status/Date]                  = A.[Status/Date]               
                                                                    ,[Relabel]                      = A.[L2_Relabel]           
                                                                    ,[License Sticker]              = A.[L2_LicenseSticker]                   
                                                                    ,[Hot Order]                    = A.[L2_HotOrder]               
                                                                    ,[EventDate]                    = A.[L2_EventDate]               
                                                                    ,[Collection]                   = A.[Collection]           
                                                                        
                                                                    ,[Style]                        = A.[Style]                         ----COLUMNAS AGREGADA BACKLOG            
                                                                    ,[Season]                       = A.[Season]                        ----COLUMNAS AGREGADA BACKLOG            
                                                                    ,[Color]                        = A.[Color]                         ----COLUMNAS AGREGADA BACKLOG             
                                                                    ,[BundleBarcode]                = A.[BundleBarcode]                 ----COLUMNAS AGREGADA BACKLOG
                                                                    ,[BoxNumber]                    = A.[BoxNumber]                     ----COLUMNAS AGREGADA BACKLOG
                                                                    ,[MOStatus]                     = A.[Status]                        ----COLUMNAS AGREGADA BACKLOG                
                                                                    ,[ProductionStatus]             = A.[ProductionStatus]              ----COLUMNAS AGREGADA BACKLOG                
                                                                    ,[PWModulo]                     = A.[PWModulo]                      ----COLUMNAS AGREGADA BACKLOG
                                                                    ,[FabricDD]                     = A.[FabricDD]                      ----COLUMNAS AGREGADA BACKLOG    
                                                                    ,[SewingDate]                   = A.[SewingDate]                    ----COLUMNAS AGREGADA BACKLOG      
                                                                    ,[Inv_Pack_Date]                = A.[Inv_Pack_Date]                 ----COLUMNAS AGREGADA BACKLOG         
                                                                    ,[Availability]                 = A.[Availability]                  ----COLUMNAS AGREGADA BACKLOG        
                                                                    ,[discard_by_percentage]        = A.[discard_by_percentage]         ----COLUMNAS AGREGADA BACKLOG                    
                                                                    ,[DateArriveInPackingForOrder]  = A.[DateArriveInPackingForOrder]   ----COLUMNAS AGREGADA BACKLOG                          
                                                                    ,[PreviewLCAComments]           = A.[PreviewLCAComments]            ----COLUMNAS AGREGADA BACKLOG                     
                                                                    ,[TakeForProcedure]             = A.[TakeForProcedure]              ----COLUMNAS AGREGADA BACKLOG       
                                                                    ,[DateForConteiner]             = A.[DateForConteiner]              ----COLUMNAS AGREGADA BACKLOG       
                                                                    ,[LateOrder]                    = A.[LateOrder]                     ----COLUMNAS AGREGADA BACKLOG
                                                                    ,[DaysLateOrder]                = A.[DaysLateOrder]                 ----COLUMNAS AGREGADA BACKLOG
                                                                    ,[Waybill]                      = A.[Waybill]                       ----COLUMNAS AGREGADA BACKLOG
                                                                    ,[ShipDate]                     = A.[ShipDate]                      ----COLUMNAS AGREGADA BACKLOG
                                                                    ,[InventoryLineType]            = A.[InventoryLineType]             ----COLUMNAS AGREGADA BACKLOG
                                                                                
                                                                    ,[ScreenPrint]                  = A.[ScreenPrint]               
                                                                    ,[ScreenPrintAfter]	            = A.[ScreenPrintAfter]	         
                                                                    ,[ScreenPrintBefore]            = A.[ScreenPrintBefore]         
                                                                    ,[SublimationBefore]            = A.[SublimationBefore]         
                                                                    ,[SublimationAfter]	            = A.[SublimationAfter]	         
                                                                    ,[HDP]			                = A.[HDP]			             
                                                                    ,[Blanks]			            = A.[Blanks]			         
                                                                    ,[Embroidery]		            = A.[Embroidery]		         
                                                                    ,[EmbHWApplique]                = A.[EmbHWApplique]             
                                                                    ,[EmbHWDirect]                  = A.[EmbHWDirect]               
                                                                    ,[EmbHWPatch]                   = A.[EmbHWPatch]                
                                                                    ,[EmbHWHDP]                     = A.[EmbHWHDP]                  
                                                                    ,[EmbAppDirect]                 = A.[EmbAppDirect]              
                                                                    ,[EmbAppLBA]                    = A.[EmbAppLBA]                 
                                                                                    

                                                                    ,[Qty_ScreenPrint]              = A.[Qty_ScreenPrint]           
                                                                    ,[Qty_ScreenPrintAfter]	        = A.[Qty_ScreenPrintAfter]	     
                                                                    ,[Qty_ScreenPrintBefore]        = A.[Qty_ScreenPrintBefore]     
                                                                    ,[Qty_SublimationBefore]        = A.[Qty_SublimationBefore]     
                                                                    ,[Qty_SublimationAfter]	        = A.[Qty_SublimationAfter]	     
                                                                    ,[Qty_HDP]			            = A.[Qty_HDP]			         
                                                                    ,[Qty_Blanks]			        = A.[Qty_Blanks]			     
                                                                    ,[Qty_Embroidery]		        = A.[Qty_Embroidery]		     
                                                                    ,[Qty_EmbHWApplique]            = A.[Qty_EmbHWApplique]         
                                                                    ,[Qty_EmbHWDirect]              = A.[Qty_EmbHWDirect]           
                                                                    ,[Qty_EmbHWPatch]               = A.[Qty_EmbHWPatch]            
                                                                    ,[Qty_EmbHWHDP]                 = A.[Qty_EmbHWHDP]              
                                                                    ,[Qty_EmbAppDirect]             = A.[Qty_EmbAppDirect]          
                                                                    ,[Qty_EmbAppLBA]                = A.[Qty_EmbAppLBA]             
                                                                FROM #TB_BACKLOG_FINAL    AS A 
                                                                ORDER BY A.[FinalRowData]   
                                                                    FOR JSON PATH, INCLUDE_NULL_VALUES))
                    FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER

                    )
                )
            FOR JSON PATH, INCLUDE_NULL_VALUES
        )   
        
                                                               
        -- SELECT mANUFACTURENUMBER,ManufactureID,sTATUSID FROM LCA.dbo.ManufactureOrders
        -- where ManufactureNumber in (
        -- 'EO5935782-441','EO5934609-869','EO5859406-315','EO5859409-485','EO5953386-869','EO5935797-315','EO5953477-315','EO5935617-089','EO5934600-416','EO5934666-315','EO5934649-441','EO5934629-724','EO5935554-101','EO5953408-752','EO5934632-391','EO5935610-752','EO5859770-305','EO5959384-632','EO5938546-461','EO5953518-632','EO5935636-225','EO5938515-632','EO5934673-315','EO5938575-632','EO5859154-NAV'
        --     )

        -- SELECT A.* FROM #TB_FINAL_PROC_ORDENES_DEMAND                           AS A ORDER BY A.[RowData]           
        -- SELECT A.* FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO                        AS A ORDER BY A.[RowData]           
        -- SELECT A.* FROM #DispatchOrdersFromInventoryWIP                         AS A ORDER BY A.[RowData]           
        -- SELECT A.* FROM #DispatchOrdersFromInventoryWIP_OrdersDispatched        AS A ORDER BY A.[RowData]           
        -- SELECT A.* FROM #DispatchOrdersFromInventoryWIP_OrdersNotDispatched     AS A ORDER BY A.[RowData]           
        -- SELECT A.* FROM #TB_FINAL_PROC_CSV                                      AS A ORDER BY A.[Date], A.[Hour]    
        
        
        
--         SELECT OrderRow, Style, Color, Make, CommentFinal, CommentSizeMissing
-- FROM #DispatchOrdersFromInventoryWIP_OrdersNotDispatched
-- ORDER BY Style, Color

-- -- Demanda total de las ordenes del flagDispatchSamples
-- SELECT Style, Color, 
--        SUM(XS) XS, SUM(S) S, SUM(M) M, SUM(L) L, SUM(XL) XL, 
--        SUM([2XL]) [2XL], SUM([3XL]) [3XL]
-- FROM #TB_FINAL_PROC_ORDENES_DEMAND
-- GROUP BY Style, Color

-- -- Inventario disponible para esos mismos estilos/colores
-- SELECT Style, Color, TypeQuery,
--        size,
--        sum(qty)
-- FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO
-- where CONCAT(style,'-',Color) in (select distinct CONCAT(style,'-',Color) from #TB_FINAL_PROC_ORDENES_DEMAND)
-- GROUP BY Style, Color, TypeQuery,size
-- ORDER BY Style, Color

        UPDATE [AppsLCA].[dbo].[TB_Global_Process]
        SET [Status] = 'DONE',
            [Percent] = 100,
            [StepCode] = 'DONE',
            [StepNameUser] = 'Proceso finalizado',
            [MessageUser] = 'El proceso termino correctamente. Enviando informacion.',
            [MessageTech] = NULL, --RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - OK'),500),
            [UpdatedAt] = SYSDATETIME(),
            [FinishedAt] = SYSDATETIME(),
            [DataJson] = NULL
        WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            

    END TRY
    BEGIN CATCH
        SET @message = CONCAT('Error in Database. Please contact IT.',' version',@version,' ',CHAR(10),LEFT(ERROR_MESSAGE(), 300))
        SET @error = 1
        SET @result = '[]'

        IF ISNULL(@KeyGenerated,'') <> '' AND OBJECT_ID('[AppsLCA].[dbo].[TB_Global_Process]','U') IS NOT NULL
        BEGIN
            UPDATE [AppsLCA].[dbo].[TB_Global_Process]
            SET [Status] = 'ERROR',
                [Percent] = CASE WHEN [Percent] < 1 THEN 1 ELSE [Percent] END,
                [StepCode] = 'ERROR',
                [StepNameUser] = 'Ocurrio un error',
                [MessageUser] = 'No se pudo completar el proceso. Intenta nuevamente o contacta IT.',
                [MessageTech] = RIGHT(CONCAT(NULLIF([MessageTech],''), CASE WHEN NULLIF([MessageTech],'') IS NULL THEN '' ELSE CHAR(10) END, CONVERT(VARCHAR(23),SYSDATETIME(),121), ' - ERROR: ', LEFT(ERROR_MESSAGE(),850)),500),
                [UpdatedAt] = SYSDATETIME(),
                [FinishedAt] = SYSDATETIME()
            WHERE [KeyGenerated] = @KeyGenerated AND [Process] = @ProcessName;
            
            WAITFOR DELAY '00:00:05'
            
            
        END
    END CATCH

EndProcedureDispatchInventory:

    SET @otherData = (
        SELECT
             [Error]       = @error
            ,[message]     = @message
            ,[messageData] = JSON_QUERY(COALESCE(@messageData,'[]'))
            ,[Result]      = JSON_QUERY(COALESCE(@result,'[]'))
        FOR JSON PATH, INCLUDE_NULL_VALUES
    )

    IF @NoSelect = 0
        SELECT @otherData
        
        
-- SELECT @otherData

END









-- SELECT A.* FROM #DispatchOrdersFromInventoryWIP AS A 
-- WHERE Style = 'NDS110' 
-- ORDER BY A.[RowData] 


-- SELECT A.* FROM #DispatchOrdersFromInventoryWIP_OrdersNotDispatched AS A 
-- WHERE Style = 'NDS110' 
-- ORDER BY A.[RowData] 


-- SELECT * FROM #TB_FINAL_PROC_ORDENES_DEMAND
-- WHERE Style = 'NDS110' 

-- SELECT * FROM #TB_FINAL_PROC_CSV
-- WHERE ord_style = 'NDS110' 

-- ----RFP

-- ----PONER COLUMNAS DE L2BRAND
-- ----AGREGAR LAS QUE NO ESTAN EN BASE LCA

-- SELECT A.* FROM #TB_FINAL_PROC_ORDENES_DEMAND                           AS A ORDER BY A.[RowData]        
-- SELECT A.* FROM #TB_FINAL_PROC_INVENTARIO_ACTIVO                        AS A ORDER BY A.[RowData]        
-- SELECT A.* FROM #DispatchOrdersFromInventoryWIP                         AS A ORDER BY A.[RowData]        
-- SELECT A.* FROM #DispatchOrdersFromInventoryWIP_OrdersDispatched        AS A ORDER BY A.[RowData]        
-- SELECT A.* FROM #DispatchOrdersFromInventoryWIP_OrdersNotDispatched     AS A ORDER BY A.[RowData]        
-- SELECT A.* FROM #TB_FINAL_PROC_CSV                                      AS A ORDER BY A.[Date], A.[Hour] 
-- SELECT A.* FROM #TB_BACKLOG_L2BRAND_ACTIVE                             AS A ORDER BY A.[RowData]         
-- SELECT A.* FROM #TB_BACKLOG_INVENTORY_UNIFIED                          AS A ORDER BY A.[R],A.[RowData]   





-- select 
--     SKUStatus,
-- * 
--  FROM [AppsLCA].[dbo].[TB_L2Brand_view_qryOpenOrderSuppl_162] AS L2 WITH(NOLOCK)
--                 WHERE ItemDetailID = '5795075' 
                 
--                  and ISNULL(L2.[SKUStatus],0) <= 40
--                   AND ISNULL(L2.[Quantity],0) > 0
--                   AND L2.[ItemDetailID] IS NOT NULL
--                   AND L2.[CustName] NOT LIKE 'L2 SKU Set Up%'