

SELECT 
    * 
FROM AppsLCA.dbo.ImportExport_ApproveInvoice_Generated
WHERE WayBill = 'APP-20260514'

INSERT INTO AppsLCA.dbo.ImportExport_ApproveInvoice_Generated
(
	[KeyTB]
     ,[InvoiceBatch]
     ,[Style]
     ,[PONumber]
     ,[PuertoDestino]
     ,[Quantity]
     ,[WayBill]
     ,[HTSDescription]
     ,[HTSCode]
     ,[BasePrice]
     ,[PrintCount]
     ,[TotalPrintValue]
     ,[Price]
     ,[ShipmentID]
     ,[ShipNotes]
     ,[created_at]
     ,[optionInvoice]
)
SELECT
	 '9d887568-0350-4e7e-b957-e169c0ece360'  AS keyTB
	,IB.InvoiceBatch
	,AP.Style
	,AP.PONumber
	,AP.PuertoDestino
	,AP.Quantity
	,AP.WayBill
	,AP.HTSDescription
	,AP.HTSCode
	,AP.BasePrice
	,AP.PrintCount
	,AP.TotalPrintValue
	,AP.Price
	,AP.ShipmentID
	,RIGHT(IB.InvoiceBatch,4) AS ShipNotes
	,GETDATE() AS Created_at
	,'Insert Rodrigo' AS OptionInvoice
FROM LCA.dboReaders.VW_ImportExport_ApproveInvoice	AS AP WITH(NOLOCK)
INNER JOIN LCA.dbo.Shipments						AS SH WITH(NOLOCK) ON AP.ShipmentID = SH.ShipmentID AND AP.WayBill = 'APP-20260514'
INNER JOIN LCA.dbo.InvoiceBatches					AS IB WITH(NOLOCK) ON SH.InvoiceBatchID = IB.InvoiceBatchID