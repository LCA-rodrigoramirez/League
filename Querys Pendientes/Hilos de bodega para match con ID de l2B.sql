SELECT
	  SUM(RC.[QuantityOnHand]) AS Qty
	 ,RM.[PartNumber]
	 ,C.[ColorName]
FROM [LCA].[dbo].[RawContainers]				AS RC WITH(NOLOCK)
INNER JOIN [LCA].[dbo].[RawMaterials] 			AS RM WITH(NOLOCK)	ON RC.[RawMaterialID] = RM.[RawMaterialID] 
																	AND RC.[StockWarehouseID] IN (50,55)
																	AND RC.[StatusID] < 90 
																	AND RC.[ContainerCode] <> '<Default>' 
																	AND RC.[QuantityOnHand] > 0
INNER JOIN [LCA].[dbo].[Colors]					AS C  WITH(NOLOCK) ON RM.[ColorID] = C.[ColorID]
INNER JOIN [LCA].[dbo].[ComponentLibrary]		AS CL WITH(NOLOCK) ON RM.[ComponentID] = CL.[ComponentID]
INNER JOIN [LCA].[dbo].[ComponentCategories]	AS CC WITH(NOLOCK) ON CL.[ComponentCategoryID] = CC.[ComponentCategoryID] AND CC.[CategoryName] = 'Thread'
GROUP BY
	  RM.[PartNumber]
	 ,C.[ColorName]


--SELECT * FROM LCA.dbo.RawMaterials WHERE PartNumber = 'THE0006-I32002'
--SELECT * FROM LCA.dbo.ComponentLibrary WHERE ComponentID = 10096
--SELECT * FROM LCA.dbo.Warehouses WHERE WarehouseID in (4,14,46,50,55)
