SELECT SUM(Qty) as qty, SUM(Total$) as total FROM AppsLCA.dbo.ImportExport_AnexoFacturacion WHERE Waybill = 'AIR-HW-20250307' 

SELECT SUM(quantity) as qty, SUM(TotalPrice) as total
FROM [192.168.1.93].AppsLCA.dbo.Import_Export_CommercialInvoice WHERE  Waybill = 'AIR-HW-20250307' 


SELECT SUM(Qty) as qty, SUM(Total$) as total, StyleNumber 
FROM AppsLCA.dbo.ImportExport_AnexoFacturacion WHERE  Waybill = 'AIR-HW-20250307'  Group by StyleNumber order by StyleNumber

SELECT SUM(quantity) as qty, SUM(TotalPrice) as total, StyleNumber
FROM [192.168.1.93].AppsLCA.dbo.Import_Export_CommercialInvoice WHERE  Waybill = 'AIR-HW-20250307' 
GROUP BY StyleNumber

SELECT SUM(Qty) as qty, SUM(Total$) as total,SUM(Gross_Weight_kgs) as peso, StyleNumber, Price, Manufacturer, CountryOfOrigin,MO
FROM AppsLCA.dbo.ImportExport_AnexoFacturacion WHERE  Waybill = 'AIR-APP-20250307' and styleNumber = 'CCW115'
Group by StyleNumber, Price, Manufacturer, CountryOfOrigin,MO order by StyleNumber

SELECT * FROM [192.168.1.93].AppsLCA.dbo.Import_Export_CommercialInvoice WHERE Waybill = 'AIR-APP-20250307' AND StyleNumber = 'EZ100'

SELECT * FROM AppsLCA.dbo.TB_MO_PartNumber_IM WHERE MO = 'EO4652092-837'