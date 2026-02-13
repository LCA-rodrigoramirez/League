

SELECT * 
FROM AppsLCA.dbo.ImportExport_ApproveInvoice_Generated
WHERE WayBill = 'AIR-APP-20240916'

--INSERT INTO AppsLCA.dbo.ImportExport_ApproveInvoice_Generated
--(
--	[KeyTB]
--      ,[InvoiceBatch]
--      ,[Style]
--      ,[PONumber]
--      ,[PuertoDestino]
--      ,[Quantity]
--      ,[WayBill]
--      ,[HTSDescription]
--      ,[HTSCode]
--      ,[BasePrice]
--      ,[PrintCount]
--      ,[TotalPrintValue]
--      ,[Price]
--      ,[ShipmentID]
--      ,[ShipNotes]
--      ,[created_at]
--      ,[optionInvoice]
--)
--SELECT
--	 '497078CF-4464-4311-9EDC-22EAFBC30488'  AS keyTB
--	,IB.InvoiceBatch
--	,AP.Style
--	,AP.PONumber
--	,AP.PuertoDestino
--	,AP.Quantity
--	,AP.WayBill
--	,AP.HTSDescription
--	,AP.HTSCode
--	,AP.BasePrice
--	,AP.PrintCount
--	,AP.TotalPrintValue
--	,AP.Price
--	,AP.ShipmentID
--	,RIGHT(IB.InvoiceBatch,4) AS ShipNotes
--	,GETDATE() AS Created_at
--	,'Insert Rodrigo' AS OptionInvoice
--FROM LCA.dboReaders.VW_ImportExport_ApproveInvoice	AS AP WITH(NOLOCK)
--INNER JOIN LCA.dbo.Shipments						AS SH WITH(NOLOCK) ON AP.ShipmentID = SH.ShipmentID AND AP.WayBill = 'AIR-APP-20240916'
--INNER JOIN LCA.dbo.InvoiceBatches					AS IB WITH(NOLOCK) ON SH.InvoiceBatchID = IB.InvoiceBatchID