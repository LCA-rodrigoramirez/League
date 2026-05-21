DECLARE @MO AS VARCHAR(100) = '23938-FLOW-C587'

SELECT
	 MO.ManufactureID
	,MO.ManufactureNumber
	,RA.RawMaterialID
	,RM.PartNumber
	,STV.RawMaterialID
	,RMS.PartNumber AS PartNumberStyle
--UPDATE STV SET
--	RawMaterialID = RM.RawMaterialID
FROM LCA.dbo.ManufactureOrders		AS MO	WITH(NOLOCK)
INNER JOIN LCA.dbo.RawAllocations	AS RA	WITH(NOLOCK) ON MO.ManufactureID = RA.ManufactureID AND MO.ManufactureNumber = @MO AND MO.StatusID < 90 AND RA.QuantityRequired > 0
INNER JOIN LCA.dbo.RawMaterials		AS RM	WITH(NOLOCK) ON RM.RawMaterialID = RA.RawMaterialID
INNER JOIN LCA.dbo.OrderItems		AS OI	WITH(NOLOCK) ON MO.FirstOrderItemID = OI.OrderItemID
INNER JOIN LCA.dbo.StyleVariations	AS STV	WITH(NOLOCK) ON OI.StyleID = STV.StyleID AND OI.StyleColorID = STV.StyleColorID
INNER JOIN LCA.dbo.RawMaterials		AS RMS	WITH(NOLOCK) ON RMS.RawMaterialID = STV.RawMaterialID