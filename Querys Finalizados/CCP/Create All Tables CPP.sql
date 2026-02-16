DROP TABLE IF EXISTS [CPP_Inventory];
DROP TABLE IF EXISTS [CCP_BoxesSelected];
DROP TABLE IF EXISTS [CCP_Report];
DROP TABLE IF EXISTS [CCP_Fecha];



CREATE TABLE [CPP_Inventory] (
							 [ID]									INT IDENTITY(1,1) PRIMARY KEY
							,[IDReport]								INT				NOT NULL
							,[MO_ID]								INT				NULL
							,[MO]									VARCHAR(100)	NULL
							,[OrderID]								INT				NULL
							,[PONumber]								VARCHAR(100)	NULL
							,[StyleID]								INT				NULL
							,[StyleNumber]							VARCHAR(50)		NULL
							,[SeasonName]							VARCHAR(50)		NULL
							,[BoxNumber]							VARCHAR(50)		NULL
							,[WarehouseName]						VARCHAR(50)		NULL
							,[BIN]									VARCHAR(50)		NULL
							,[QTY]									INT				NULL
							,[FinishedGoodsID]						INT				NULL
							,[GarmentSize]							VARCHAR(50)		NULL
							,[StyleColor]							VARCHAR(50)		NULL
							,[StyleColorDescription]				VARCHAR(100)	NULL
							,[TypeMO]								VARCHAR(50)		NULL
							,[OrigFabricVendorName]					VARCHAR(100)	NULL
							,[RequireHangtag]						INT				NULL
							,[Option]								VARCHAR(100)	NULL
							,[CAFTA]								VARCHAR(50)		NULL
							,[BoxCode]								VARCHAR(50)		NULL
							,[ReceivedInWarehouse]					DATETIME		NULL
							,[StyleOptionID]						INT				NULL
							,[BlankPrice]							DECIMAL(18,6)	NULL
							,[BoxComments]							VARCHAR(200)	NULL
							,[BoxComments5]							VARCHAR(200)	NULL
							,[UniversityComments4]					VARCHAR(200)	NULL
							,[CountryOfOrigin]						VARCHAR(100)	NULL
							,[ProductDivision]						VARCHAR(100)	NULL
							,[Invoice]								VARCHAR(100)	NULL
							,[InvoiceDate]							DATE			NULL
							,[UnitPrice]							DECIMAL(18,6)	NULL
							,[MoCreateDate]							DATE			NULL
							,[IM5]									VARCHAR(50)		NULL
							,[DateIM5]								DATE			NULL
							,[PurchaseOrder]						VARCHAR(50)		NULL
							,[Vendor]								VARCHAR(100)	NULL
							,[VendorCountry]						VARCHAR(50)		NULL
							,[Manufacturer]							VARCHAR(50)		NULL
							,[Fabric]								DECIMAL(18,6)	NULL
							,[Thread]								DECIMAL(18,6)	NULL
							,[Trim]									DECIMAL(18,6)	NULL
							,[Supplies]								DECIMAL(18,6)	NULL
							,[Contracts]							DECIMAL(18,6)	NULL
							,[Subassembly]							DECIMAL(18,6)	NULL
							,[Total_Materials_$]					DECIMAL(18,6)	NULL
							,[Consigned]							VARCHAR(50)		NULL
							,[PurchaseOrderTotalPrice_withFreight]	DECIMAL(18,6)	NULL
							,[PurchaseOrderUnitPrice_Ponderado]		DECIMAL(18,6)	NULL
							,[UnitFreightCost_Ponderado]			DECIMAL(18,6)	NULL
							,[BoxID]								INT				NULL
							,[GoodsBinID]							INT				NULL
							,[FlagStyle]							BIT				NULL
							,[FlagBin]								BIT				NULL
							,[RowNStyle]							INT				NULL
							,[sampleUnits]							INT				NULL
							,[FlagBoxSelected]						INT				NULL
							,[FlagBinSelected]						INT				NULL
						);

CREATE TABLE [CCP_Fecha] (
    [ID] INT IDENTITY(1,1) PRIMARY KEY
    ,[Fecha] DATE NOT NULL
);

CREATE TABLE [CCP_Report] (
    [ID] INT IDENTITY(1,1) PRIMARY KEY
    ,[IDFecha] INT NOT NULL
    ,[jsonParameters] NVARCHAR(MAX) NOT NULL
);

CREATE TABLE [CCP_BoxesSelected] (
    [ID] INT IDENTITY(1,1) PRIMARY KEY
    ,[IDReport] INT NOT NULL
    ,[BoxID] INT NOT NULL
    ,[BoxNumber] NVARCHAR(100) NOT NULL
);



ALTER TABLE [CCP_Report] 
    ADD CONSTRAINT [FK_Report_IDFecha_IDFecha_Fecha] 
    FOREIGN KEY ([IDFecha]) REFERENCES [CCP_Fecha]([ID]);

ALTER TABLE [CCP_BoxesSelected] 
    ADD CONSTRAINT [FK_BoxesSelected_IDReport_IDReport_Report] 
    FOREIGN KEY ([IDReport]) REFERENCES [CCP_Report]([ID]);

ALTER TABLE [CCP_Inventory] 
    ADD CONSTRAINT [FK_Inventory_IDReport_IDReport_Report] 
    FOREIGN KEY ([IDReport]) REFERENCES [CCP_Report]([ID]);

-- Índice para IDFecha en CCP_Report
CREATE INDEX [IX_Report_IDFecha] ON [CCP_Report] ([IDFecha]);

-- Índice combinado para IDReport y BoxID en CCP_BoxesSelected
CREATE INDEX [IX_BoxesSelected_IDReport_BoxID] ON [CCP_BoxesSelected] ([IDReport], [BoxID]);

-- Índice combinado para IDReport, BoxID y GoodsBinsID en CCP_Inventory
CREATE INDEX [IX_Inventory_IDReport_BoxID_GoodsBinID] ON [CCP_Inventory] ([IDReport], [BoxID], [GoodsBinID]);

-- Índice combinado para IDReport, MO_ID y StyleID en CCP_Inventory
CREATE INDEX [IX_Inventory_IDReport_MO_ID_StyleID] ON [CCP_Inventory] ([IDReport], [MO_ID], [StyleID]);