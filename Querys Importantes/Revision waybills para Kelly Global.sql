select *
--UPDATE NR SET
--	Sublimation = Price - BasePrice
--	,Total_Sublimation = (Price - BasePrice) * Qty
	--Screen_Print = Price - BasePrice
	--,Total_Screen_Print = (Price - BasePrice) * Qty
	--Embroidery = Price - BasePrice
	--,Total_Embroidery = (Price - BasePrice) * Qty
	--Manufacturer = 'Wollomtex'
	--,CountryOfOrigin = 'China'
	
from AppsLCA.dbo.ImportExport_AnexoFacturacion AS NR
--INNER JOIN [AppsLCA].[dbo].[ImportExport_AnexoFacturacion_BK20260115] AS AF ON NR.ID = AF.ID
where NR.Waybill = 'APP-20250306'
AND BasePrice + ISNULL(Screen_Print,0) + ISNULL(Sublimation,0) + ISNULL(Embroidery,0) <> Price 
AND Price = BasePrice
--AND Manufacturer IS NULL
AND ManufactureID in (604420)

select *
--UPDATE NR SET
--	 Embroidery = Price - BasePrice

--	,Total_Embroidery = (Price - BasePrice) * Qty
--	,Screen_Print = 0
--	,[Unit Decoration] = Price - BasePrice
--	,Total_Screen_Print = 0
--	,Tecnica = 'EMBROIDERY'
from AppsLCA.dbo.TB_Transfer_Export_Duty AS NR
where Waybill = 'APP-20250306' AND BasePrice + [Unit Decoration] <> Price 
AND Price = BasePrice
AND ManufactureID in (617038)

SELECT * FROM AppsLCA.dbo.TB_MO_PartNumber_IM_MOProcess WHERE ManufactureID in (549190,549191)
SELECT * FROM AppsLCA.dbo.TB_MO_PartNumber_IM WHERE ManufactureID = 386659

SELECT
	*
FROM [192.168.1.93].[AppsLCA].[dbo].[CI_import_export_CommercialInvoice_Drawback] AS CI WITH(NOLOCK) 
WHERE Waybill = 'APP-20250411-1'
AND LineGroupKelly = 3 AND InvoicingDescription = 'Boy''s Long Sleeve T-shirt 100% Recycled Polyester'

SELECT
	*
FROM [192.168.1.93].[AppsLCA].[dbo].[CI_import_export_DeclarationExport_Drawback] AS CI WITH(NOLOCK) 
WHERE Waybill = 'APP-20250306'
AND LineGroupKelly = 2 AND InvoicingDescription = 'Boy''s Sweatshirt 65% COTTON / 35% POLYESTER'
 
 SELECT * FROM LCA.dbo.ManufactureOrders WHERE ManufactureID = 571963

SELECT
*
--UPDATE S SET
--	Total_Screen_Print = 3.93 *
FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS S 
WHERE
ID in
(803721
,802152
,802673
,803258
,803746
,803208
,802303
,803827
,804073
,804063
,803067
,803101)

--update AppsLCA.dbo.ImportExport_CommercialInvoice_Status_Drawback set Status = 'Pending' WHERE waybill = 'APP-20250411-1'


SELECT * FROM AppsLCA.dbo.ImportExport_CommercialInvoice_Status_Drawback WHERE waybill
IN
(
'APP-20250307'
)