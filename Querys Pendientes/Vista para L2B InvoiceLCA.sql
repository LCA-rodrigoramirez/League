WITH CTE_Prices
AS
(
    SELECT
    *
    FROM AppsLCA.dbo.TB_ShipmentCheckPrices AS SCP WITH(NOLOCK)
    WHERE SCP.ShipDate  >= '2026-02-01'
),
CTE_Bill
AS
(

    SELECT
        Waybill
        ,BoxNumber
        ,ManufactureID
        ,StyleNumber
        ,StyleColor
        ,[Size]
        ,BasePrice
    FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK)
    GROUP BY
        Waybill
        ,BoxNumber
        ,ManufactureID
        ,StyleNumber
        ,StyleColor
        ,[Size]
        ,BasePrice
)

SELECT 
     [Size]             = FG.GarmentSize
    ,[StyleColor]       = SCPD.Color
    ,[Quantity]         = SUM(PBI.Quantity)
    ,[Style]            = AF.StyleNumber
    ,[StyleID]          = SCPD.StyleID
    ,[TransactionDate]  = SCP.ShipDate
    ,[MO]               = SCPD.MO
    ,[MO_ID]            = SCPD.ManufactureID
    ,[ItemDetailID]     = SCPD.ItemDetailID
    ,[Item #]           = L2BInv.InvItemID
    ,[InvoicedPrice]    = CASE 
                            WHEN SCP.ShipDate < '2026-02-10' THEN AF.BasePrice
                            ELSE SCPD.TotalBlank
                          END
    ,[CustomerPO]       = CASE WHEN ( od.[PONumber] LIKE 'ORD%') AND CHARINDEX('-',OD.Comments6) > 0 THEN SUBSTRING(od.Comments6,1,CHARINDEX('-',OD.Comments6) -1) ELSE OD.Comments6 END
    ,[StyleOption]      = SCPD.StyleOption
    ,[Waybill]          = SCP.Waybill
    -- ,[StyleOptionID]    = SCPD.StyleOptionID
    -- ,[Season]           = SCPD.Season
FROM            CTE_Prices                                          AS SCP      WITH(NOLOCK)
INNER JOIN      AppsLCA.dbo.TB_ShipmentCheckPricesDetail            AS SCPD     WITH(NOLOCK)    ON  SCP.id                  = SCPD.shipmentCheckPrices_id
INNER JOIN      LCA.dbo.PackedItems                                 AS PBI      WITH(NOLOCK)    ON  SCPD.ManufactureID      = PBI.ManufactureID     AND PBI.Quantity > 0
INNER JOIN      LCA.dbo.PackedBoxes                                 AS PB       WITH(NOLOCK)    ON  PBI.PackedBoxID         = PB.PackedBoxID
INNER JOIN      LCA.dbo.Shipments                                   AS SH       WITH(NOLOCK)    ON  PB.ShipmentID           = SH.ShipmentID AND SCP.waybill = SH.WayBill
INNER JOIN      LCA.dbo.FinishedGoods                               AS FG       WITH(NOLOCK)    ON  FG.FinishedGoodsID      = PBI.FinishedGoodsID
INNER JOIN      LCA.dbo.Orders                                      AS OD       WITH(NOLOCK)    ON  SCPD.OrderID            = OD.OrderID
INNER JOIN      LCA.dbo.Styles                                      AS ST       WITH(NOLOCK)    ON  ST.StyleID              = FG.StyleID
LEFT  JOIN      LCA.dbo.Styles                                      AS STB      WITH(NOLOCK)    ON  STB.StyleID             = ST.BlankStyleID               
LEFT  JOIN      AppsLCA.legacycaps.VW_LCA_L2B_InventoryID           AS L2BInv   WITH(NOLOCK)    ON  ISNULL(STB.StyleNumber, SCPD.Style) = L2BInv.Style
                                                                                                AND SCPD.Color              = L2BInv.Color
                                                                                                AND FG.GarmentSize          = L2BInv.[Size]
LEFT  JOIN      CTE_Bill                                            AS AF       WITH(NOLOCK)    ON  SCPD.ManufactureID      = AF.ManufactureID
                                                                                                AND ISNULL(STB.StyleNumber, SCPD.Style) = AF.StyleNumber
                                                                                                AND SCPD.Color              = AF.StyleColor
                                                                                                AND FG.GarmentSize          = AF.[Size]
                                                                                                AND PB.BoxNumber            = AF.BoxNumber
GROUP BY
    FG.GarmentSize
    ,SCPD.Color
    ,AF.StyleNumber
    ,SCPD.StyleID
    ,SCP.ShipDate
    ,SCPD.MO
    ,SCPD.ManufactureID
    ,SCPD.ItemDetailID
    ,L2BInv.InvItemID
    ,CASE 
       WHEN SCP.ShipDate < '2026-02-10' THEN AF.BasePrice
       ELSE SCPD.TotalBlank
     END
    ,CASE WHEN ( od.[PONumber] LIKE 'ORD%') AND CHARINDEX('-',OD.Comments6) > 0 THEN SUBSTRING(od.Comments6,1,CHARINDEX('-',OD.Comments6) -1) ELSE OD.Comments6 END
    ,SCPD.StyleOption
    ,SCP.Waybill
