SELECT
	 COO.CountryCode
	--,COALESCE(CI.US_HTSCode2, CI.US_HTSCode) AS US_HTSCode
	,AE.US_HTSCode
	,SUM(CI.TotalFobValue) AS TotalValue
	,SUM(CI.TotalFobValue) AS TotalFob
	,SUM(CI.TotalPrice) as total
	,SUM(CI.TotalBlankPrice) as totalblank
	,(AE.[HTS_%] * 100) AS [HTS_%]
	,(AE.[Recip_%] * 100) AS [Recip_%]
	,(AE.[Fenta_%] * 100) AS [Fenta_%]
	,(AE.[301China_%] * 100) AS [301China_%]
	,SUM(AE.[HTS_%] * CI.TotalFobValue) AS NewTariffAmount
	,SUM(AE.[Recip_%] * CI.TotalFobValue) AS NewRecip
	,SUM(AE.[Fenta_%] * CI.TotalFobValue) AS NewFenta
	,SUM(AE.[301China_%] * CI.TotalFobValue) AS New301
	,CI.Manufacturer
	,'CI'

FROM [192.168.1.93].AppsLCA.dbo.CI_Import_Export_CommercialInvoice_Drawback AS CI WITH(NOLOCK)
INNER JOIN LCA.dbo.CountryOfOrigin AS COO WITH(NOLOCK) ON CI.CountryOfOrigin = COO.CountryName AND COO.StatusID = 30
INNER JOIN AppsLCA.dbo.TB_Transfer_Validation_allExport AS AE WITH(NOLOCK) ON CI.IDExport = AE.Original_IDExport
WHERE AE.[Entry #] = 'BHE04298994'
GROUP BY
	 COO.CountryCode
	--,COALESCE(CI.US_HTSCode2, CI.US_HTSCode)
	,AE.US_HTSCode
	,(AE.[HTS_%] * 100)
	,(AE.[Recip_%] * 100) 
	,(AE.[Fenta_%] * 100) 
	,(AE.[301China_%] * 100)
	,CI.Manufacturer

UNION ALL

SELECT
	 COO.CountryCode
	--,COALESCE(CI.US_HTSCode2, CI.US_HTSCode) AS US_HTSCode
	,AE.US_HTSCode
	,SUM(CI.TotalDecorationValue) AS TotalValue
	,SUM(CI.TotalFobValue) AS TotalFob
	,SUM(CI.TotalPrice) as total
	,SUM(CI.TotalBlankPrice) as totalblank
	,(AE.[HTS_%] * 100) AS [HTS_%]
	,(AE.[Recip_%] * 100) AS [Recip_%]
	,(AE.[Fenta_%] * 100) AS [Fenta_%]
	,(AE.[301China_%] * 100) AS [301China_%]
	,SUM(AE.[HTS_%] * CI.TotalDecorationValue) AS NewTariffAmount
	,SUM(AE.[Recip_%] * CI.TotalDecorationValue) AS NewRecip
	,SUM(AE.[Fenta_%] * CI.TotalDecorationValue) AS NewFenta
	,SUM(AE.[301China_%] * CI.TotalDecorationValue) AS New301
	,CI.Manufacturer
	,'9802'

FROM [192.168.1.93].AppsLCA.dbo.CI_Import_Export_DeclarationExport_Drawback AS CI WITH(NOLOCK)
INNER JOIN LCA.dbo.CountryOfOrigin AS COO WITH(NOLOCK) ON CI.CountryOfOrigin = COO.CountryName AND COO.StatusID = 30
INNER JOIN AppsLCA.dbo.TB_Transfer_Validation_allExport AS AE WITH(NOLOCK) ON CI.IDExport = AE.Original_IDExport
WHERE AE.[Entry #] = 'BHE04298994'
GROUP BY
	 COO.CountryCode
	--,COALESCE(CI.US_HTSCode2, CI.US_HTSCode)
	,AE.US_HTSCode
	,CI.TariffCategory
	,(AE.[HTS_%] * 100)
	,(AE.[Recip_%] * 100) 
	,(AE.[Fenta_%] * 100) 
	,(AE.[301China_%] * 100)
	,CI.Manufacturer



SELECT
	 COO.CountryCode
	,AE.US_HTSCode AS US_HTSCode
	,COALESCE(CI.US_HTSCode2, CI.US_HTSCode)
	,CI.InvoicingGroupKelly
	,CI.InvoicingDescription
	,CI.StyleNumber
	,CI.StyleColor
	,SUM(CI.TotalDecorationValue) AS TotalDeco
	,SUM(CI.TotalFobValue) AS TotalValue
	,SUM(CI.TotalPrice) as total
	,(AE.[HTS_%] * 100) AS [HTS_%]
	,SUM(AE.[HTS_%] * CI.TotalDecorationValue) AS NewTariffAmount
	,CI.Manufacturer
	,CI.BasePrice
	,'CI'
FROM [192.168.1.93].AppsLCA.dbo.CI_Import_Export_CommercialInvoice_Drawback AS CI WITH(NOLOCK)
INNER JOIN LCA.dbo.CountryOfOrigin AS COO WITH(NOLOCK) ON CI.CountryOfOrigin = COO.CountryName AND COO.StatusID = 30
INNER JOIN AppsLCA.dbo.TB_Transfer_Validation_allExport AS AE WITH(NOLOCK) ON CI.IDExport = AE.Original_IDExport
WHERE AE.[Entry #] = 'BHE04298994' AND COO.CountryCode = 'CN'
GROUP BY
	 COO.CountryCode
	,AE.US_HTSCode
	,COALESCE(CI.US_HTSCode2, CI.US_HTSCode)
	,CI.InvoicingGroupKelly
	,CI.InvoicingDescription
	,CI.StyleNumber
	,CI.StyleColor
	,(AE.[HTS_%] * 100)
	,CI.Manufacturer
	,CI.BasePrice

union all

SELECT
	 COO.CountryCode
	,AE.US_HTSCode AS US_HTSCode
	,COALESCE(CI.US_HTSCode2, CI.US_HTSCode)
	,CI.InvoicingGroupKelly
	,CI.InvoicingDescription
	,CI.StyleNumber
	,CI.StyleColor
	,SUM(CI.TotalDecorationValue) AS TotalDeco
	,SUM(CI.TotalFobValue) AS TotalValue
	,SUM(CI.TotalPrice) as total
	,(AE.[HTS_%] * 100) AS [HTS_%]
	,SUM(AE.[HTS_%] * CI.TotalDecorationValue) AS NewTariffAmount
	,CI.Manufacturer
	,CI.BasePrice
	,'9802'
FROM [192.168.1.93].AppsLCA.dbo.CI_Import_Export_DeclarationExport_Drawback AS CI WITH(NOLOCK)
INNER JOIN LCA.dbo.CountryOfOrigin AS COO WITH(NOLOCK) ON CI.CountryOfOrigin = COO.CountryName AND COO.StatusID = 30
INNER JOIN AppsLCA.dbo.TB_Transfer_Validation_allExport AS AE WITH(NOLOCK) ON CI.IDExport = AE.Original_IDExport
WHERE AE.[Entry #] = 'BHE04298994' AND COO.CountryCode = 'CN'
GROUP BY
	 COO.CountryCode
	,AE.US_HTSCode
	,COALESCE(CI.US_HTSCode2, CI.US_HTSCode)
	,CI.InvoicingGroupKelly
	,CI.InvoicingDescription
	,CI.StyleNumber
	,CI.StyleColor
	,(AE.[HTS_%] * 100)
	,CI.Manufacturer
	,CI.BasePrice

-- select distinct Style, StyleColorName, DescribeText, InvoicingDescription	
-- from [LCA].[dboReaders].[VW_CommercialInvoice_FabricContent_Ver2]  with (nolock)
-- where Style = 'AC240'