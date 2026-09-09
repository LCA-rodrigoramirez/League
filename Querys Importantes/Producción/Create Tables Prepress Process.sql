USE AppsLCA

DROP TABLE IF EXISTS [dbo].[TB_Prepress_OrdersScanned]
DROP TABLE IF EXISTS [dbo].[TB_Prepress_Screens]
DROP TABLE IF EXISTS [dbo].[TB_Prepress_SequenceTasks]
DROP TABLE IF EXISTS [dbo].[TB_Prepress_ImageOperator]
DROP TABLE IF EXISTS [dbo].[TB_Prepress_WorkOrders]
DROP TABLE IF EXISTS [dbo].[TB_Prepress_Bins]


GO
 PRINT('Realizando Tabla:  [dbo].[TB_Prepress_Bins]')/*Tabla: [dbo].[TB_Prepress_Bins] ID: 001 Descripción: Almacena la información de los inventarios fisicos a realizar.*/
GO
 SET ANSI_NULLS ON 
GO
 SET QUOTED_IDENTIFIER ON  
GO
 CREATE TABLE [dbo].[TB_Prepress_Bins](


[id] INT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_TB_Prepress_Bins] PRIMARY KEY,/*Llave primaria que identifica de manera única cada registro en la tabla "dbo.TB_Prepress_Bins".*/
[Bin] VARCHAR(20) NOT NULL,/*Nombre de bines el área de Preprensa*/
[MaxScreens] int NOT NULL,/*Cantidad máxima de pantallas que puede almacenar el bin*/
[status] BIT NOT NULL DEFAULT 1,/*Identifica si la clasificación esta Activa/Inactiva. Ejemplo: 1 = Activo / 0 = Inactivo.*/
[created_at] DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,/*Registra la fecha y hora de creación en la tabla "dbo.TB_Prepress_Bins" con el formato YYYY-MM-DD hh:mm:ss.*/
[updated_at] DATETIME NULL,/*Actualiza la fecha y hora de la última edición del registro en la tabla "dbo.TB_Prepress_Bins" con el formato de fecha YYYY-MM-DD hh:mm:ss.*/
) 

GO
 PRINT('Realizando Tabla:  [dbo].[TB_Prepress_WorkOrders]')/*Tabla: [dbo].[TB_Prepress_WorkOrders] ID: 002 Descripción: Almacena la información de los procesos a ejecutar en base de datos del inventario fisico.*/
GO
 SET ANSI_NULLS ON 
GO
 SET QUOTED_IDENTIFIER ON  
GO
 CREATE TABLE [dbo].[TB_Prepress_WorkOrders](


[id] INT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_TB_Prepress_WorkOrders] PRIMARY KEY,/*Llave primaria que identifica de manera única cada registro en la tabla "dbo.TB_Prepress_WorkOrders".*/
[WorkOrder] int NOT NULL,/*ItemDetailID de la PONumber, parte numérica sin "ORD-"*/
[PONumber] varchar(50) NOT NULL,/*PONumber que viene de Orders de PPM*/
[Assignment] varchar(100) NOT NULL,/*Comments7 de ManufactureOrders de PPM*/
[Distress] BIT NOT NULL DEFAULT 0,/*Campo bit que el usuario declarará para cada WO*/
[status] BIT  NOT NULL DEFAULT 1,/*Almacena el estado del registro. Inactivo = 0, Activo = 1.*/
[created_at] DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,/*Registra la fecha y hora de creación en la tabla "dbo.TB_Prepress_WorkOrders" con el formato YYYY-MM-DD hh:mm:ss.*/
[updated_at] DATETIME NULL,/*Actualiza la fecha y hora de la última edición del registro en la tabla "dbo.TB_Prepress_WorkOrders" con el formato de fecha YYYY-MM-DD hh:mm:ss.*/
) 

GO
 PRINT('Realizando Tabla:  [dbo].[TB_Prepress_ImageOperator]')/*Tabla: [dbo].[TB_Prepress_ImageOperator] ID: 003 Descripción: Almacena la información de los procesos a ejecutar en base de datos del inventario fisico.*/
GO
 SET ANSI_NULLS ON 
GO
 SET QUOTED_IDENTIFIER ON  
GO
 CREATE TABLE [dbo].[TB_Prepress_ImageOperator](


[id] INT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_TB_Prepress_ImageOperator] PRIMARY KEY,/*Llave primaria que identifica de manera única cada registro en la tabla "dbo.TB_Prepress_ImageOperator".*/
[OperatorName] VARCHAR(50) NOT NULL,/*Almacena nombre de Image activas en Preprensa*/
[Distress] BIT NOT NULL DEFAULT 0,/*Flag para saber si una IMAGE puede hacer Distress o no*/
[status] BIT  NOT NULL DEFAULT 1,/*Almacena el estado del registro. Inactivo = 0, Activo = 1.*/
[created_at] DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,/*Registra la fecha y hora de creación en la tabla "dbo.TB_Prepress_ImageOperator" con el formato YYYY-MM-DD hh:mm:ss.*/
[updated_at] DATETIME NULL,/*Actualiza la fecha y hora de la última edición del registro en la tabla "dbo.TB_Prepress_ImageOperator" con el formato de fecha YYYY-MM-DD hh:mm:ss.*/
) 

GO
 PRINT('Realizando Tabla:  [dbo].[TB_Prepress_SequenceTasks]')/*Tabla: [dbo].[TB_Prepress_SequenceTasks] ID: 004 Descripción: Almacena la información de los procesos a ejecutar en base de datos del inventario fisico.*/
GO
 SET ANSI_NULLS ON 
GO
 SET QUOTED_IDENTIFIER ON  
GO
 CREATE TABLE [dbo].[TB_Prepress_SequenceTasks](


[id] INT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_TB_Prepress_SequenceTasks] PRIMARY KEY,/*Llave primaria que identifica de manera única cada registro en la tabla "dbo.TB_Prepress_SequenceTasks".*/
[PPMOperatorID] int NOT NULL,/*ID de operador creado en PPM*/
[OperatorPPM] VARCHAR(20) NOT NULL,/*Almacena el PPAD creado por PPM*/
[prepressImageOperator_id] int  NOT NULL,/*Llave foránea que proviene de la tabla "TB_Prepress_ImageOperator"*/
[Task] varchar(100) NOT NULL,/*Almacena el nombre de la tarea que realizan en Preprensa*/
[Sequence] INT NOT NULL,/*Orden sequencial de las tareas en el flujo de trabajo*/
[RequiresBin] BIT NOT NULL DEFAULT 0,/*Almacena si la tarea requiere guardar también un bin al momento de escanearla*/
[status] BIT  NOT NULL DEFAULT 1,/*Almacena el estado del registro. Inactivo = 0, Activo = 1.*/
[created_at] DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,/*Registra la fecha y hora de creación en la tabla "dbo.TB_Prepress_SequenceTasks" con el formato YYYY-MM-DD hh:mm:ss.*/
[updated_at] DATETIME NULL,/*Actualiza la fecha y hora de la última edición del registro en la tabla "dbo.TB_Prepress_SequenceTasks" con el formato de fecha YYYY-MM-DD hh:mm:ss.*/
) 

GO
 PRINT('Realizando Tabla:  [dbo].[TB_Prepress_Screens]')/*Tabla: [dbo].[TB_Prepress_Screens] ID: 005 Descripción: Almacena la información de las areas para el conteo fisico*/
GO
 SET ANSI_NULLS ON 
GO
 SET QUOTED_IDENTIFIER ON  
GO
 CREATE TABLE [dbo].[TB_Prepress_Screens](


[id] INT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_TB_Prepress_Screens] PRIMARY KEY,/*Llave primaria que identifica de manera única cada registro en la tabla "dbo.TB_Prepress_Screens".*/
[ScreenNumber] int NOT NULL,/*Almacena número de pantalla correlativo por WO*/
[ScreenBarcode] VARCHAR(50) NOT NULL,/*Almacena el valor escaneable por el barcode en el sticker que llevará la pantalla, identificador único*/
[prepressWorkOrders_id] INT  NOT NULL,/*Llave foránea que proviene de la tabla "TB_Prepress_WorkOrders"*/
[prepressBins_id] INT  NOT NULL,/*Llave foránea que proviene de la tabla "TB_Prepress_Bins"*/
[status] BIT  NOT NULL DEFAULT 1,/*Almacena el estado del registro. Inactivo = 0, Activo = 1.*/
[created_at] DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,/*Registra la fecha y hora de creación en la tabla "dbo.TB_Prepress_Screens" con el formato YYYY-MM-DD hh:mm:ss.*/
[updated_at] DATETIME NULL,/*Actualiza la fecha y hora de la última edición del registro en la tabla "dbo.TB_Prepress_Screens" con el formato de fecha YYYY-MM-DD hh:mm:ss.*/
) 

GO
 PRINT('Realizando Tabla:  [dbo].[TB_Prepress_OrdersScanned]')/*Tabla: [dbo].[TB_Prepress_OrdersScanned] ID: 006 Descripción: Almacena la información de las locaciones específicas de los productos en la planta*/
GO
 SET ANSI_NULLS ON 
GO
 SET QUOTED_IDENTIFIER ON  
GO
 CREATE TABLE [dbo].[TB_Prepress_OrdersScanned](


[id] INT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_TB_Prepress_OrdersScanned] PRIMARY KEY,/*Llave primaria que identifica de manera única cada registro en la tabla "dbo.TB_Prepress_OrdersScanned".*/
[prepressScreens_id] INT  NOT NULL,/*Llave foránea que proviene de la tabla "TB_Prepress_Screens"*/
[StartDate] DATETIME NOT NULL,/*Almacena fecha de inicio de la tarea en el flujo de Preprensa*/
[FinishDate] DATETIME NULL,/*Almacena fecha de fin de la tarea en el flujo de Preprensa*/
[prepressSequenceTasks_id] INT  NULL,/*Llave foránea que proviene de la tabla "TB_Prepress_SequenceTasks"*/
[status] BIT  NOT NULL DEFAULT 1,/*Almacena el estado del registro. Inactivo = 0, Activo = 1.*/
[created_at] DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,/*Registra la fecha y hora de creación en la tabla "dbo.TB_Prepress_OrdersScanned" con el formato YYYY-MM-DD hh:mm:ss.*/
[updated_at] DATETIME NULL,/*Actualiza la fecha y hora de la última edición del registro en la tabla "dbo.TB_Prepress_OrdersScanned" con el formato de fecha YYYY-MM-DD hh:mm:ss.*/
) 
PRINT('AGREGANDO FOREING KEY:  [FK_TB_Prepress_SequenceTasks_TB_Prepress_ImageOperator_prepressImageOperator_id]')
ALTER TABLE [dbo].[TB_Prepress_SequenceTasks]  ADD CONSTRAINT [FK_TB_Prepress_SequenceTasks_TB_Prepress_ImageOperator_prepressImageOperator_id] FOREIGN KEY ([prepressImageOperator_id]) REFERENCES [dbo].[TB_Prepress_ImageOperator] ([id]);/*Llave foránea que proviene de la tabla "TB_Prepress_ImageOperator"*/
PRINT('AGREGANDO FOREING KEY:  [FK_TB_Prepress_Screens_TB_Prepress_WorkOrders_prepressWorkOrders_id]')
ALTER TABLE [dbo].[TB_Prepress_Screens]  ADD CONSTRAINT [FK_TB_Prepress_Screens_TB_Prepress_WorkOrders_prepressWorkOrders_id] FOREIGN KEY ([prepressWorkOrders_id]) REFERENCES [dbo].[TB_Prepress_WorkOrders] ([id]);/*Llave foránea que proviene de la tabla "TB_Prepress_WorkOrders"*/
PRINT('AGREGANDO FOREING KEY:  [FK_TB_Prepress_Screens_TB_Prepress_Bins_prepressBins_id]')
ALTER TABLE [dbo].[TB_Prepress_Screens]  ADD CONSTRAINT [FK_TB_Prepress_Screens_TB_Prepress_Bins_prepressBins_id] FOREIGN KEY ([prepressBins_id]) REFERENCES [dbo].[TB_Prepress_Bins] ([id]);/*Llave foránea que proviene de la tabla "TB_Prepress_Bins"*/
PRINT('AGREGANDO FOREING KEY:  [FK_TB_Prepress_OrdersScanned_TB_Prepress_Screens_prepressScreens_id]')
ALTER TABLE [dbo].[TB_Prepress_OrdersScanned]  ADD CONSTRAINT [FK_TB_Prepress_OrdersScanned_TB_Prepress_Screens_prepressScreens_id] FOREIGN KEY ([prepressScreens_id]) REFERENCES [dbo].[TB_Prepress_Screens] ([id]);/*Llave foránea que proviene de la tabla "TB_Prepress_Screens"*/
PRINT('AGREGANDO FOREING KEY:  [FK_TB_Prepress_OrdersScanned_TB_Prepress_SequenceTasks_prepressSequenceTasks_id]')
ALTER TABLE [dbo].[TB_Prepress_OrdersScanned]  ADD CONSTRAINT [FK_TB_Prepress_OrdersScanned_TB_Prepress_SequenceTasks_prepressSequenceTasks_id] FOREIGN KEY ([prepressSequenceTasks_id]) REFERENCES [dbo].[TB_Prepress_SequenceTasks] ([id]);/*Llave foránea que proviene de la tabla "TB_Prepress_SequenceTasks"*/




