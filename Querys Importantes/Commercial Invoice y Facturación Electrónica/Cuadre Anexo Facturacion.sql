DECLARE @WayBill VARCHAR(50) = 'AIR-APP-20260527-1'

-- Boxes donde las cantidades NO cuadran
SELECT
	COALESCE(SH.BoxNumber, AF.BoxNumber)	AS BoxNumber
	,SH.QtyShipment
	,AF.QtyAnexo
	,ISNULL(SH.QtyShipment, 0) - ISNULL(AF.QtyAnexo, 0) AS Diferencia
FROM (
	SELECT BoxNumber, SUM(Quantity) AS QtyShipment
	FROM AppsLCA.dbo.ImportExport_ShipmentBoxAll WITH(NOLOCK)
	WHERE WayBill = @WayBill
	GROUP BY BoxNumber
) AS SH
FULL OUTER JOIN (
	SELECT BoxNumber, SUM(Qty) AS QtyAnexo
	FROM AppsLCA.dbo.ImportExport_AnexoFacturacion WITH(NOLOCK)
	WHERE WayBill = @WayBill
	GROUP BY BoxNumber
) AS AF ON SH.BoxNumber = AF.BoxNumber
WHERE ISNULL(SH.QtyShipment, 0) <> ISNULL(AF.QtyAnexo, 0)
ORDER BY COALESCE(SH.BoxNumber, AF.BoxNumber)


