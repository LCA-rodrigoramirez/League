SELECT * FROM AppsLCA.dbo.ImportExport_CommercialInvoice_Status WITH(NOLOCK) WHERE waybill = 'APP-20260217'
SELECT * FROM AppsLCA.dbo.ImportExport_CommercialInvoice_Status_Drawback WITH(NOLOCK) WHERE waybill = 'HW-20250616'

 

--update AppsLCA.dbo.ImportExport_CommercialInvoice_Status set Status = 'Pending' WHERE waybill = 'AIR-APP-20260330'
--update AppsLCA.dbo.ImportExport_CommercialInvoice_Status_Drawback set Status = 'Pending' WHERE waybill = 'AIR-APP-20250319'

INSERT INTO AppsLCA.dbo.ImportExport_CommercialInvoice_Status
VALUES
('HW-20260330','Pending',GETDATE(),NULL,NULL)
--,('BUND-20250307','Pending',GETDATE(),NULL,NULL)
-- ,('HW-20250410','Pending',GETDATE(),NULL,NULL)