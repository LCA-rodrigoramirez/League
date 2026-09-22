DROP TABLE IF EXISTS #TB_AnexoFacturacion
DROP TABLE IF EXISTS #TB_DetailedPrice

SELECT
*
,LCA_CONTRACT = CASE
                    WHEN (ProductDivision LIKE 'Apparel%' OR ProductDivision LIKE 'Accesories%') AND CHARINDEX('FG',SeasonName) > 0
                        THEN 'SEMI Apparel'
                    WHEN (ProductDivision LIKE 'Apparel%' OR ProductDivision LIKE 'Accesories%') AND CHARINDEX('FG',SeasonName) = 0
                        THEN 'LCA Apparel'
                    WHEN ProductDivision LIKE 'HeadWear%'
                        THEN 'SEMI Headwear'
                    ELSE 'OTHER'
                END
,[IsBlank] = IIF(Screen_Print = 0 AND Embroidery = 0 AND Sublimation = 0,1,0)
INTO #TB_AnexoFacturacion
FROM AppsLCA.dbo.ImportExport_AnexoFacturacion WITH(NOLOCK)
WHERE ShipDate >= '2026-01-01'

SELECT
     [Year]                 = YEAR(AF.ShipDate)
    ,[Month]                = MONTH(AF.ShipDate)
    ,LCA_CONTRACT           = AF.LCA_CONTRACT
    ,ProductDivision        = AF.ProductDivision
    ,IsBlank                = AF.IsBlank
    ,[CalcBasePrice]        = AF.Total$ / AF.Qty
    ,CalculatedBlankAPP     = CAST(NULL AS DECIMAL(18,2))
    ,CalculatedBlankHW      = CAST(NULL AS DECIMAL(18,2))
    ,Price                  = AF.Price
    ,CalculatedPriceAPP     = CAST(NULL AS DECIMAL(18,2))
    ,CalculatedPriceHW      = CAST(NULL AS DECIMAL(18,2))
    ,Total                  = AF.Total$
    ,Qty                    = AF.Qty
    ,IDExport               = AF.ID
    ,Waybill                = AF.Waybill
    ,Style                  = AF.[StyleNumber]
    ,MO                     = AF.MO
    ,ManufactureID          = AF.ManufactureID
    ,RO                     = AF.RO
    ,RO_ID                  = AF.RO_ID
    ,Samples                = SCPD.Samples
    ,PigmentDye             = SCPD.PigmentDye
    ,Price_BlankLCA         = SCPD.Price_BlankLCA
    ,Price_BlankSemiApp     = IIF(SCPD.Samples > 0, SCPD.Samples,SCPD.Price_BlankSemiApp)
    ,Price_BlankSemiHW      = SCPD.Price_BlankSemiHW
    ,PurchaseBasePrice      = SCPD.PurchaseBasePrice
    ,PurchaseFreightPrice   = SCPD.PurchaseFreightPrice
    ,[InventoryManagment]   = 0.04
    ,[Shipping]             = 0.10
    ,[ShippingSupplies]     = 0.02
    ,[NorthBoundFreight]    = 0.25
    ,[SuppliesPD]           = 0.10
    ,Price_PigmentDye       = SCPD.Price_PigmentDye
    ,Price_ScreenPrint      = SCPD.Price_ScreenPrint
    ,Price_EmbroideryApp    = SCPD.Price_EmbroideryApp
    ,Price_EmbroideryHW     = SCPD.Price_EmbroideryHW
    ,Price_Sublimation      = SCPD.Price_Sublimation
    ,Price_SubApplication   = SCPD.Price_SubApplication
    ,Price_SpecialPK        = SCPD.Price_SpecialPK
    ,Price_HDP              = SCPD.Price_HDP
    ,Price_Relabel          = SCPD.Price_Relabel
INTO #TB_DetailedPrice
FROM #TB_AnexoFacturacion AS AF
INNER JOIN AppsLCA.dbo.TB_ShipmentCheckPricesDetail AS SCPD WITH(NOLOCK) ON AF.IDCheckPrices = SCPD.id
WHERE AF.LCA_CONTRACT LIKE 'SEMI%' AND AF.Qty > 0

UPDATE DP SET
     CalculatedBlankAPP = CASE
                            WHEN ProductDivision IN ('Apparel','Accesories') AND PigmentDye = 0
                                THEN PurchaseBasePrice + PurchaseFreightPrice + InventoryManagment + Shipping + ShippingSupplies + NorthBoundFreight
                            WHEN ProductDivision IN ('Apparel','Accesories') AND PigmentDye = 0
                                THEN PurchaseBasePrice + PurchaseFreightPrice + InventoryManagment + Shipping + ShippingSupplies + NorthBoundFreight + Price_PigmentDye + SuppliesPD
                            ELSE 0
                          END

    ,CalculatedBlankHW  = CASE
                            WHEN ProductDivision = 'Headwear'
                                THEN PurchaseBasePrice + PurchaseFreightPrice + InventoryManagment + Shipping + ShippingSupplies + NorthBoundFreight
                            ELSE 0
                          END
FROM #TB_DetailedPrice AS DP

UPDATE DP SET
     CalculatedPriceAPP = CASE
                            WHEN CalculatedBlankAPP > 0
                                THEN CalculatedBlankAPP + Price_ScreenPrint + Price_EmbroideryApp + Price_Sublimation + Price_SubApplication + Price_SpecialPK + Price_HDP + Price_Relabel
                            ELSE 0
                          END

    ,CalculatedPriceHW  = CASE
                            WHEN CalculatedBlankHW > 0
                                THEN CalculatedBlankHW + Price_ScreenPrint + Price_EmbroideryHW + Price_Sublimation + Price_SubApplication + Price_SpecialPK + Price_HDP + Price_Relabel
                            ELSE 0
                          END
FROM #TB_DetailedPrice AS DP

SELECT
     SUM(Total)
    ,SUM(Total2)
    ,SUM(Total - Total2)
FROM
(
    SELECT
    *
    ,CalculatedPriceAPP * Qty AS Total2
    FROM #TB_DetailedPrice
    -- WHERE Style = 'QU100' 
    WHERE CalculatedPriceAPP <> Price AND CalculatedBlankAPP > 0
) AS A

SELECT
    *
    ,CalculatedPriceAPP * Qty AS Total2
    FROM #TB_DetailedPrice
    -- WHERE Style = 'QU100' 
    WHERE CalculatedPriceAPP <> Price AND CalculatedBlankAPP > 0

    return

SELECT
*
,CalculatedPriceAPP * Qty AS Total2
FROM #TB_DetailedPrice
-- WHERE Style = 'QU100' 
WHERE [Month] = 4 AND Style IN ('COR210','MON140')

SELECT
*
,CalculatedPriceAPP * Qty AS Total2
FROM #TB_DetailedPrice
WHERE Style = 'MON140' 
AND [Month] = 8
ORDER BY Price DESC