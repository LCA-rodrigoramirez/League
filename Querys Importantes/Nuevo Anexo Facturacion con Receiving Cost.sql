SELECT
	AF.*
	,IIF(TBM.NewPrice = 0,TBM2.NewPrice,TBM.NewPrice)
	,ReceivingCost_ForNewBasePrice + (IIF(Price - BasePrice = 0, 0.08, Price - BasePrice ))
	,TBM.*
	,TBM2.*
--UPDATE AF SET
--	ReceivingCost_ForNewBasePrice = IIF(TBM.NewPrice = 0 OR TBM.NewPrice IS NULL,TBM2.NewPrice,TBM.NewPrice)
FROM AppsLCA.dbo.ImportExport_AnexoFacturacion_WithReceivingPricing AS AF WITH(NOLOCK)
LEFT JOIN
(
	SELECT 
		ManufactureID
		,MO
		,Contracts_PurchasePrice
		,Contracts_FreightPrice
		,Make
		,NewPrice = CAST(ROUND((Contracts_PurchasePrice + Contracts_FreightPrice) / IIF(Make = 0,1,Make),2) AS decimal(18,2)) 
	FROM TB_MO_PartNumber_IM_Materials WITH(NOLOCK)
) AS TBM ON AF.ManufactureID = TBM.ManufactureID
LEFT JOIN
(
	SELECT 
		ManufactureID
		,MO
		,Contracts_PurchasePrice
		,Contracts_FreightPrice
		,Make
		,NewPrice = CAST(ROUND((Contracts_PurchasePrice + Contracts_FreightPrice) / IIF(Make = 0,1,Make),2) AS decimal(18,2)) 
	FROM TB_MO_PartNumber_IM_Materials WITH(NOLOCK)
) AS TBM2 ON AF.RO_ID = TBM2.ManufactureID
WHERE SeasonName LIKE '%FG%'
AND (ReceivingCost_ForNewBasePrice IS NULL OR ReceivingCost_ForNewBasePrice = 0)



SELECT
	SUM(Quantity)
FROM AppsLCA.dbo.TB_MO_PartNumber_IM_Ouray_2024_qty
WHERE ManufactureID IN (428081,427806) AND Style = '30008' AND Color = 'VEG'

SELECT
	*
FROM AppsLCA.dbo.TB_MO_PartNumber_IM_Ouray_2024
WHERE PONumber = 'LCA16526' AND PartNumber LIKE '%30008-VEG%'

SELECT * FROM TB_MO_PartNumber_IM WHERE MO = 'EO4085619-003'

SELECT 
		ManufactureID
		,MO
		,Contracts_PurchasePrice
		,Contracts_FreightPrice
		,Make
		,NewPrice = CAST(ROUND((Contracts_PurchasePrice + Contracts_FreightPrice) / IIF(Make = 0,1,Make),2) AS decimal(18,2)) 
	FROM TB_MO_PartNumber_IM_Materials WITH(NOLOCK)
	WHERE ManufactureID in (568539,507273)

