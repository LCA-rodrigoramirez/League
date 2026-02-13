

SELECT * FROM [192.168.1.93].[AppsLCA].[dbo].[Import_Export_CommercialInvoice] WHERE waybill = 'AIR-HW-20250108'
SELECT * FROM [192.168.1.93].[AppsLCA].[dbo].[Import_Export_CommercialInvoice] WHERE waybill = 'AIR-HW-20240920'

SELECT * FROM [192.168.1.93].[AppsLCA].[dbo].[Import_Export_DeclarationExport] WHERE waybill = 'AIR-HW-20250514'

--INSERT INTO [192.168.1.93].[AppsLCA].[dbo].[Import_Export_CommercialInvoice]
SELECT  
	Waybill
	,ContainerNumber
	,StyleNumber
	,InvoicingDescription
	,US_HTSDescription
	,CA_HTSCode
	,UnitPrice
	,ShipDate
	,SUM(Quantity) AS Quantity
	,SUM(TotalPrice) AS TotalPrice
	,MinBatch
	,SUM(WeightKg) AS Weightkg
	,MaxBatch
	,Cafta
	,SUM(Pallets) AS Pallets
	,SUM(Boxes) AS Boxes
	,Manufactured
	,CountryOfOrigin
	,0.25 AS Freight
	,4 AS Orden
FROM [192.168.1.93].[AppsLCA].[dbo].[Import_Export_DeclarationExport] WHERE waybill = 'AIR-HW-20250520'
GROUP BY
	Waybill
	,ContainerNumber
	,StyleNumber
	,InvoicingDescription
	,US_HTSDescription
	,CA_HTSCode
	,UnitPrice
	,ShipDate
	,MinBatch
	,MaxBatch
	,Cafta
	,Manufactured
	,CountryOfOrigin
	ORDER BY StyleNumber


--UPDATE [192.168.1.93].[AppsLCA].[dbo].[Import_Export_CommercialInvoice]
--SET Orden = 4
--WHERE waybill = 'AIR-APP-20250520' AND Manufactured NOT LIKE 'League%' AND Manufactured NOT LIKE 'NG TEXT%'


SELECT * FROM AppsLCA.dbo.TB_Transfer_CuadreCI_KellyGlobal AS KG WITH(NOLOCK)  WHERE waybill = 'AIR-APP-20250520' AND Orden = 3

---------- REVIEW WAYBILLS
  SELECT DISTINCT
	 KG.WayBill
	,KG.TypeData
	,KG.Entry#
  FROM AppsLCA.dbo.TB_Transfer_CuadreCI_KellyGlobal AS KG WITH(NOLOCK)
  LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_WaybillEntry] WE WITH(NOLOCK) ON KG.WayBill = WE.Waybill AND KG.TypeData = WE.InvoiceLCA

  WHERE KG.Entry# IS NULL
  ORDER BY Waybill

  