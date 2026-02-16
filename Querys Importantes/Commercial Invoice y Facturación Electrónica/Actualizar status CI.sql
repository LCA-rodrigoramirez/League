SELECT * FROM AppsLCA.dbo.ImportExport_CommercialInvoice_Status WITH(NOLOCK) WHERE waybill like '%20260211%'
SELECT * FROM AppsLCA.dbo.ImportExport_CommercialInvoice_Status_Drawback WITH(NOLOCK) WHERE waybill = 'HW-20250616'

INSERT INTO AppsLCA.dbo.ImportExport_CommercialInvoice_Status
VALUES
('AIR-APP-20260211','Pending',GETDATE(),NULL,NULL)

--update AppsLCA.dbo.ImportExport_CommercialInvoice_Status set Status = 'Pending' WHERE waybill = 'AIR-SMS-20260213'
--update AppsLCA.dbo.ImportExport_CommercialInvoice_Status_Drawback set Status = 'Pending' WHERE waybill = 'AIR-APP-20250319'

INSERT INTO AppsLCA.dbo.ImportExport_CommercialInvoice_Status_Drawback
VALUES
('HW-20250307','Pending',GETDATE(),NULL,NULL)
,('BUND-20250307','Pending',GETDATE(),NULL,NULL)
-- ,('HW-20250410','Pending',GETDATE(),NULL,NULL)