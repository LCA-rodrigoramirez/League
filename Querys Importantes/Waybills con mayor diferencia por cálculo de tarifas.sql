select
	[Entry #]
	,ExportDate
	,Waybill
	,CountryOfOrigin
	,FAMOCountryOfOrigin
	,ProductDivision
	,US_HTSCode
	,Style
	,KellyReport
	,[301China_%]
	,[TValue_301China_$]
	,[Fenta_%]
	,TValue_Fenta_$
	,[Recip_%]
	,TValue_Recip_$
	,[HTS_%]
	,TValue_HTS_$
	,T_Total_$
	,QtyExport

from AppsLCA.dbo.TB_Transfer_Validation_allExport WHERE Waybill = 'APP-20250327' AND TariffCategory = 'CAFTA'

select
	[Entry #]
	,ExportDate
	,Waybill
	,CountryOfOrigin
	,FAMOCountryOfOrigin
	,ProductDivision
	,US_HTSCode
	,Style
	,KellyReport
	,[301China_%]
	,[TValue_301China_$]
	,[Fenta_%]
	,TValue_Fenta_$
	,[Recip_%]
	,TValue_Recip_$
	,[HTS_%]
	,TValue_HTS_$
	,T_Total_$
	,QtyExport
from AppsLCA.dbo.TB_Transfer_Validation_allExport WHERE Waybill = '20240126-NONCAFTA'

select
	[Entry #]
	,ExportDate
	,Waybill
	,CountryOfOrigin
	,FAMOCountryOfOrigin
	,ProductDivision
	,US_HTSCode
	,Style
	,KellyReport
	,[301China_%]
	,[TValue_301China_$]
	,[Fenta_%]
	,TValue_Fenta_$
	,[Recip_%]
	,TValue_Recip_$
	,[HTS_%]
	,TValue_HTS_$
	,T_Total_$
	,QtyExport
from AppsLCA.dbo.TB_Transfer_Validation_allExport WHERE Waybill = 'HW-20250328' AND TariffCategory = 'NO CAFTA'

select
	[Entry #]
	,ExportDate
	,Waybill
	,CountryOfOrigin
	,FAMOCountryOfOrigin
	,ProductDivision
	,US_HTSCode
	,Style
	,KellyReport
	,[301China_%]
	,[TValue_301China_$]
	,[Fenta_%]
	,TValue_Fenta_$
	,[Recip_%]
	,TValue_Recip_$
	,[HTS_%]
	,TValue_HTS_$
	,T_Total_$
	,QtyExport
from AppsLCA.dbo.TB_Transfer_Validation_allExport WHERE Waybill = 'AIR-HW-20250407' AND TariffCategory = 'NO CAFTA'

select
	[Entry #]
	,ExportDate
	,Waybill
	,CountryOfOrigin
	,FAMOCountryOfOrigin
	,ProductDivision
	,US_HTSCode
	,Style
	,KellyReport
	,[301China_%]
	,[TValue_301China_$]
	,[Fenta_%]
	,TValue_Fenta_$
	,[Recip_%]
	,TValue_Recip_$
	,[HTS_%]
	,TValue_HTS_$
	,T_Total_$
	,QtyExport
from AppsLCA.dbo.TB_Transfer_Validation_allExport WHERE Waybill = 'APP-20250328' AND TariffCategory = 'NO CAFTA'

select
	[Entry #]
	,ExportDate
	,Waybill
	,CountryOfOrigin
	,FAMOCountryOfOrigin
	,ProductDivision
	,US_HTSCode
	,Style
	,KellyReport
	,[301China_%]
	,[TValue_301China_$]
	,[Fenta_%]
	,TValue_Fenta_$
	,[Recip_%]
	,TValue_Recip_$
	,[HTS_%]
	,TValue_HTS_$
	,T_Total_$
	,QtyExport
from AppsLCA.dbo.TB_Transfer_Validation_allExport WHERE Waybill = '20240119-NONCAFTA' AND TariffCategory = 'NO CAFTA'

select
	[Entry #]
	,ExportDate
	,Waybill
	,CountryOfOrigin
	,FAMOCountryOfOrigin
	,ProductDivision
	,US_HTSCode
	,Style
	,KellyReport
	,[301China_%]
	,[TValue_301China_$]
	,[Fenta_%]
	,TValue_Fenta_$
	,[Recip_%]
	,TValue_Recip_$
	,[HTS_%]
	,TValue_HTS_$
	,T_Total_$
	,QtyExport
from AppsLCA.dbo.TB_Transfer_Validation_allExport WHERE Waybill = 'AIR-HW-20250407' AND TariffCategory = 'NO CAFTA'

SELECT * FROM TB_Transfer_WaybillEntry WHERE [Entry #] = 'BHE04305518'

SELECT
	[Entry #]
	,[Entry Date]
	,[Invoice #]
	,SUM(Duty) as Duty
	,SUM(QtyTotal) as Qty
	,SUM(IIF(Flag = 1, [Value], 0.00)) as [Value]
FROM TB_Transfer_TablaKelly WHERE [Entry #] = 'BHE04305518'
GROUP BY
	[Entry #]
		,[Entry Date]
		,[Invoice #]

SELECT * FROM AppsLCA.dbo.TB_Transfer_TariffCOO WHERE Type = 'Apparel'
ORDER BY DateFrom

SELECT * FROM AppsLCA.dbo.TB_Transfer_TariffCOO WHERE Type = 'HeadWear'
ORDER BY DateFrom