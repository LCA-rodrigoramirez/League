DECLARE @WayBill VARCHAR(50) = 'APP-20260706'

-- Boxes donde las cantidades NO cuadran
SELECT
	COALESCE(SH.PONumber, AF.PONumber)	AS BoxNumber
	,COALESCE(SH.Style, AF.Style)	AS Style
	,SH.Price
	,AF.Price
	,ISNULL(SH.Price, 0) - ISNULL(AF.Price, 0) AS Diferencia
FROM (
	SELECT PONumber, SUM(Price * Quantity)  AS Price
	,Style
	FROM LCA.dboReaders.VW_ImportExport_ApproveInvoice WITH(NOLOCK)
	WHERE WayBill = @WayBill
	GROUP BY PONumber,Style
) AS SH
FULL OUTER JOIN (
	SELECT PONumber, SUM(Price * Quantity) AS Price
	,Style
	FROM LCA.dboReaders.VW_ImportExport_ApproveInvoice_BK20260514 WITH(NOLOCK)
	WHERE WayBill = @WayBill
	GROUP BY PONumber,Style
) AS AF ON SH.PONumber = AF.PONumber AND SH.Style = AF.Style
WHERE ISNULL(SH.Price, 0) <> ISNULL(AF.Price, 0)
ORDER BY COALESCE(SH.PONumber, AF.PONumber)


