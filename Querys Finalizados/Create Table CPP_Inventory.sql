DROP TABLE IF EXISTS CPP_Inventory;


CREATE TABLE CPP_Inventory (
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

ALTER TABLE [CCP_Inventory] 
    ADD CONSTRAINT [FK_Inventory_IDReport_IDReport_Report] 
    FOREIGN KEY ([IDReport]) REFERENCES [CCP_Report]([ID]);

-- Índice combinado para IDReport, BoxID y GoodsBinsID en CCP_Inventory
CREATE INDEX [IX_Inventory_IDReport_BoxID_GoodsBinID] ON [CCP_Inventory] ([IDReport], [BoxID], [GoodsBinID]);

-- Índice combinado para IDReport, MO_ID y StyleID en CCP_Inventory
CREATE INDEX [IX_Inventory_IDReport_MO_ID_StyleID] ON [CCP_Inventory] ([IDReport], [MO_ID], [StyleID]);