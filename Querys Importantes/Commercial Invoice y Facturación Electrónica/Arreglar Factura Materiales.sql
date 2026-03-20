SELECT DISTINCT
	fh.Container
	,fd.G_Weight
	,fd.N_Weight
	,PPM.ContainerWeight
	,PPM.ContainerWeight - 1.27 AS NetWeight

UPDATE fd SET
	 fd.G_Weight = PPM.ContainerWeight
	,fd.N_Weight = PPM.ContainerWeight - 1.27
-- SELECT SUM(cast(TotalCost as decimal(10,2)))	
FROM ImportExport_FET_Header as fh
INNER JOIN ImportExport_FET_Details as fd ON fh.ID = fd.ID
INNER JOIN LCA.dboReaders.VW_PTL_Transactions_Fabric AS PPM ON fh.Container = PPM.ContainerCode
WHERE Waybill = 'SALE-FABRIC20260306'

SELECT AF.Container,AF.Qty,AF.Total$,AF.Price,MatDet.Quantity,MatDet.TotalCost,MatDet.UnitCost
,AF.Gross_Weight_kgs
,af.Net_Weight_kgs
,CAST(MatDet.G_Weight / 2.20462 AS DECIMAL(18,4))
,CAST(MatDet.N_Weight / 2.20462 AS DECIMAL(18,4))
-- UPDATE AF SET 
-- --	 AF.Price = CAST(MatDet.UnitCost AS decimal(10,2)) + CAST(MatDet.UnitFreightCost AS decimal(10,2))
-- 	 AF.Gross_Weight_kgs	= CAST(MatDet.G_Weight / 2.20462 AS DECIMAL(18,4))
-- 	,af.Net_Weight_kgs	= CAST(MatDet.N_Weight / 2.20462 AS DECIMAL(18,4))
FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF
LEFT JOIN AppsLCA.dbo.ImportExport_FET_Header AS MatHead ON AF.Container = MatHead.Container
LEFT JOIN AppsLCA.dbo.ImportExport_FET_Details AS MatDet ON MatHead.ID = MatDet.ID
WHERE AF.Waybill = 'SALE-FABRIC20260306'


