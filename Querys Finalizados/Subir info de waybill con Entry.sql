SELECT DISTINCT 
	[Entry #]
	,[EntryDate] = CAST([Entry Date] AS DATE)
	--,[Waybill] = SUBSTRING(ShipDate,1,CHARINDEX('.',ShipDate) - 1)
	--,[InvoiceLCA] = SUBSTRING(ShipDate,CHARINDEX('.',ShipDate) + 1,LEN(ShipDate))
  FROM [AppsLCA].[dbo].[ImportExport_DutyKellyGlobal_2025_2026_AfterPSC]
  WHERE [Entry #] NOT IN (SELECT DISTINCT [Entry #] FROM AppsLCA.dbo.TB_Transfer_WaybillEntry)

  SELECT * FROM AppsLCA.dbo.TB_Transfer_WaybillEntry

  