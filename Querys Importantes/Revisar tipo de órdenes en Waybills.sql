SELECT
    OD.PONumber
    ,OD.Comments14
    ,DD2.DropDownValue

-- UPDATE OD SET
--     Comments14 = null
FROM LCA.dbo.PackedBoxes AS PB WITH(NOLOCK)
INNER JOIN LCA.dbo.Shipments AS SH WITH(NOLOCK) ON PB.ShipmentID = SH.ShipmentID AND SH.WayBill = 'AIR-APP-20260126'
INNER JOIN LCA.dbo.Orders AS OD WITH(NOLOCK) ON PB.OrderID = OD.OrderID
INNER JOIN LCA.dbo.DropDownValues2 AS DD2 WITH(NOLOCK) ON OD.OrderTypeID2 = DD2.DropDownValueID
WHERE DD2.DropDownValue IN ('Transfer', 'Blanks')

-- SELECT * FROM LCA.dbo.DropDownValues2