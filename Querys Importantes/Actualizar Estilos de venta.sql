--UPDATE AIG SET Style = SaleST.InventoryStyle
select *
from AppsLCA.dbo.ImportExport_ApproveInvoice_Generated AIG WITH(NOLOCK) 
INNER JOIN 
(
	SELECT 
			[SaleStyle]		= ST1.[StyleNumber]
		,[InventoryStyle]	= ST2.[StyleNumber]
	FROM LCA.dbo.Styles			AS ST1 WITH(NOLOCK)
	INNER JOIN LCA.dbo.Styles	AS ST2 WITH(NOLOCK) ON ST1.BlankStyleID = ST2.StyleID AND ST1.BlankStyleID IS NOT NULL and IIF(ST2.StyleNumber = ST1.StyleNumber,1,0) = 0
	GROUP BY ST1.StyleNumber, ST2.StyleNumber
) AS SaleST ON AIG.Style = SaleST.SaleStyle AND WayBill = @WayBill

--UPDATE SBA SET StyleNumber = SaleST.InventoryStyle
select *
from AppsLCA.dbo.ImportExport_ShipmentBoxAll SBA WITH(NOLOCK)
INNER JOIN 
(
	SELECT 
			[SaleStyle]		= ST1.[StyleNumber]
		,[InventoryStyle]	= ST2.[StyleNumber]
	FROM LCA.dbo.Styles			AS ST1 WITH(NOLOCK)
	INNER JOIN LCA.dbo.Styles	AS ST2 WITH(NOLOCK) ON ST1.BlankStyleID = ST2.StyleID AND ST1.BlankStyleID IS NOT NULL and IIF(ST2.StyleNumber = ST1.StyleNumber,1,0) = 0
	GROUP BY ST1.StyleNumber, ST2.StyleNumber
) AS SaleST ON SBA.StyleNumber = SaleST.SaleStyle AND WayBill = @WayBill