USE LCA;

DROP TABLE IF EXISTS #TB_Pre_Inventory_SHIP

SELECT DISTINCT
		 DateAnexo
		,ISNULL(BoxNumber,BundleBarcode) as BoxNumber
		,Style			= ISNULL(BS.StyleNumber,Style)
		,PackedItemID
		,Color
		,Size
		,warehousename
		,INV.ManufactureID
		,Bin
		,inv.MO
		--,StyleID		= INV.StyleID
		,HTSCode		= DDV.DropDownValue
		,HTSDescription	= DDV.Description
	 	,Quantity 
		,Costo			= ROUND(Contracts+[Trim]+[Supplies],4)
	INTO #TB_Pre_Inventory_SHIP
	FROM AppsLCA.dbo.TB_INVENTORY_SHIP	AS INV WITH(NOLOCK)
	LEFT JOIN Styles								AS ST  WITH(NOLOCK) ON INV.StyleID = ST.StyleID
	LEFT JOIN Styles								AS BS  WITH(NOLOCK) ON ST.BlankStyleID = BS.StyleID
	LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON INV.ManufactureID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-',INV.Size) = lpmW.PartNumber AND lpmW.UnitCost IS NOT NULL
	LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW2 WITH (NOLOCK) ON INV.ManufactureID = lpmW2.ManufactureID AND lpmW2.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-F-',INV.Size) = lpmW2.PartNumber AND lpmW2.UnitCost IS NOT NULL
	LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW3 WITH (NOLOCK) ON INV.ManufactureID = lpmW3.ManufactureID AND lpmW3.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-U-',INV.Size) = lpmW3.PartNumber AND lpmW3.UnitCost IS NOT NULL
	LEFT JOIN RawMaterials RM WITH (NOLOCK) ON ISNULL(ISNULL(lpmW.RawMaterialID,lpmw2.RawMaterialID),lpmw3.RawMaterialID) = RM.RawMaterialID
	LEFT JOIN DropDownValues						AS DDV WITH(NOLOCK) ON RM.HTSCodeID	= DDV.DropDownValueID

	WHERE TypeQueryN <> 4 AND FilterSemi = 1
	and (FilterTakeUnits = 1 or (FilterTakeUnits = 0  and TypeQueryN <> 1))
	and DateAnexo = '2025-01-01'
	
SELECT
		 HTSCode
		,HTSDescription
		,SUM(Quantity) as Quantity
		,SUM(Costo) as Costo
	FROM
	(
		SELECT DISTINCT
			 HTSCode		= ISNULL(ISNULL(HTSCode,DDV.DropDownValue),
								CASE WHEN Style = 'LU430' THEN '6104620000'
									 WHEN Style = '82196' THEN '6110300000'
									 WHEN Style = 'RW209' THEN '6109900000'
								END)
			,HTSDescription = ISNULL(ISNULL(HTSDescription,DDV.Description),
								CASE WHEN Style = 'LU430' THEN 'PANTALONES Y SHORTS DE ALGODON CONFECCINADOS P/MUJERES'
									 WHEN Style = '82196' THEN 'SUDADERAS DE FIBRA SINTETICA CONFECCIONADAS P/MUJERES'
									 WHEN Style = 'RW209' THEN 'CAMISETAS PLAYERAS  DE FIBRAS SINTETICAS PARA MUJERES'
								END)
			,Style
			,Color
			,Size
			,BoxNumber
			,Quantity
			,TB1.ManufactureID
			,MO
			,Costo
			,PackedItemID
		FROM #TB_Pre_Inventory_SHIP AS TB1
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON TB1.ManufactureID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND lpmW.UnitCost IS NOT NULL
		LEFT JOIN RawMaterials RM WITH (NOLOCK) ON lpmW.RawMaterialID = RM.RawMaterialID
		LEFT JOIN (SELECT DISTINCT PartNumber, HTSCodeID FROM RawMaterials WITH(NOLOCK)) AS RM2 ON CONCAT(Style,'-',Color,'-',Size) = RM2.PartNumber
		LEFT JOIN (SELECT DISTINCT PartNumber, HTSCodeID FROM RawMaterials WITH(NOLOCK)) AS RM3 ON CONCAT(Style,'-',Color) = RM3.PartNumber
		LEFT JOIN (SELECT DISTINCT PartNumber, HTSCodeID FROM RawMaterials WITH(NOLOCK)) AS RM4 ON CONCAT(Style,'-',Color,'-F-',Size) = RM4.PartNumber
		LEFT JOIN (SELECT DISTINCT PartNumber, HTSCodeID FROM RawMaterials WITH(NOLOCK)) AS RM5 ON CONCAT(Style,'-',Color,'-U-',Size) = RM5.PartNumber
		LEFT JOIN (SELECT DISTINCT PartNumber, HTSCodeID FROM RawMaterials WITH(NOLOCK)) AS RM6 ON CONCAT(Style,'C-',Color,'-',Size) = RM6.PartNumber
		LEFT JOIN (SELECT DISTINCT PartNumber, HTSCodeID FROM RawMaterials WITH(NOLOCK)) AS RM7 ON CONCAT(Style,'C-',Color) = RM7.PartNumber
		LEFT JOIN (SELECT DISTINCT PartNumber, HTSCodeID FROM RawMaterials WITH(NOLOCK)) AS RM8 ON CONCAT(Style,'-PFD-',Size) = RM8.PartNumber
		LEFT JOIN DropDownValues DDV WITH (NOLOCK) 
		ON 
		ISNULL(ISNULL(ISNULL(ISNULL(ISNULL(ISNULL(ISNULL(RM.HTSCodeID,RM2.HTSCodeID),RM3.HTSCodeID),RM4.HTSCodeID),RM5.HTSCodeID),RM6.HTSCodeID),RM7.HTSCodeID),RM8.HTSCodeID) = DDV.DropDownValueID

		--WHERE ISNULL(HTSCode,DDV.DropDownValue) IS NULL
	) TBF
	GROUP BY 
		 HTSCode
		,HTSDescription