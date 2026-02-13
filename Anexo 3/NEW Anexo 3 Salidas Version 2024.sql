SELECT HTSCode,HTSDescription,SUM(abs(Quantity)) as Quantity, SUM(abs(UnitCost*Quantity)) as Cost
FROM
(
	SELECT DISTINCT ISNULL(HTSCode,DDV.DropDownValue) as HTSCode, ISNULL(HTSDescription,DDV.Description) as HTSDescription,id,Quantity,TB1.ManufactureID, TB1.MO,TB1.UnitCost FROM
	(SELECT DISTINCT DDV.DropDownValue AS HTSCode,DDV.Description AS HTSDescription,VBT.id,VBT.Quantity, VBT.ManufactureID, VBT.ManufactureNumber as MO, Style, StyleColor, Size, ISNULL(ISNULL(ISNULL(lpmw.UnitCost,lpmw2.UnitCost),lpmw3.UnitCost),TMPI.PurchaseOrderUnitPrice) as UnitCost
	FROM LCA.dboReaders.VW_BoxTransactions_AnexoIII VBT WITH (NOLOCK)
	LEFT JOIN lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON VBT.ManufactureID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND CONCAT(Style+'-',StyleColor+'-',Size) = lpmW.PartNumber AND lpmW.UnitCost IS NOT NULL
	--AND VBT.ManufactureID NOT IN (415461
	--,415464
	--,443438
	--,415448
	--,415494
	--,415465
	--,415459
	--,446607
	--)
	LEFT JOIN lpmWithdrawals_Ver3 lpmW2 WITH (NOLOCK) ON VBT.ManufactureID = lpmW2.ManufactureID AND lpmW2.CategoryName = 'Contracts' AND CONCAT(Style+'-',StyleColor+'-F-',Size) = lpmW2.PartNumber AND lpmW2.UnitCost IS NOT NULL
	--AND VBT.ManufactureID NOT IN (415461
	--,415464
	--,443438
	--,415448
	--,415494
	--,415465
	--,415459
	--,446607
	--)
	LEFT JOIN lpmWithdrawals_Ver3 lpmW3 WITH (NOLOCK) ON VBT.ManufactureID = lpmW3.ManufactureID AND lpmW3.CategoryName = 'Contracts' AND CONCAT(Style+'-',StyleColor+'-U-',Size) = lpmW3.PartNumber AND lpmW3.UnitCost IS NOT NULL
	--AND VBT.ManufactureID NOT IN (415461
	--,415464
	--,443438
	--,415448
	--,415494
	--,415465
	--,415459
	--,446607
	--)
	LEFT JOIN AppsLCA.dbo.TB_MO_PartNumber_IM TMPI WITH (NOLOCK) ON VBT.ManufactureID = TMPI.ManufactureID AND PurchaseOrderUnitPrice <> 0
	--AND VBT.ManufactureID NOT IN (415461
	--,415464
	--,443438
	--,415448
	--,415494
	--,415465
	--,415459
	--,446607
	--)
	LEFT JOIN RawMaterials RM WITH (NOLOCK) ON ISNULL(ISNULL(lpmW.RawMaterialID,lpmw2.RawMaterialID),lpmw3.RawMaterialID) = RM.RawMaterialID
	LEFT JOIN DropDownValues DDV WITH (NOLOCK) ON RM.HTSCodeID = DDV.DropDownValueID


	WHERE --VBT.ManufactureID = 473965 and
	Season in ('BLANK FG','EMB FG') AND TransactionDate >= '2024-10-01' AND TransactionDate <= '2024-12-31'
	--AND Style NOT IN ('05PDT','10PDT','15PDT')
	--AND VBT.ManufactureID NOT IN (271319,240710)
	--order by id
	) TB1
	LEFT JOIN lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON TB1.ManufactureID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND lpmW.UnitCost IS NOT NULL
	--AND TB1.ManufactureID NOT IN (415461
	--,415464
	--,443438
	--,415448
	--,415494
	--,415465
	--,415459
	--,446607
	--)
	LEFT JOIN RawMaterials RM WITH (NOLOCK) ON lpmW.RawMaterialID = RM.RawMaterialID
	LEFT JOIN DropDownValues DDV WITH (NOLOCK) ON RM.HTSCodeID = DDV.DropDownValueID
	WHERE (HTSCode IS NOT NULL and DDV.DropDownValue IS NOT NULL)
) XD
GROUP BY HTSCode,HTSDescription
