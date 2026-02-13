USE Financial;
SELECT HTSCode,HTSDescription,SUM(abs(QTY)) as Quantity, SUM(abs(Receiving_Cost*QTY)) as Cost
FROM
(
	SELECT DISTINCT ISNULL(HTSCode,DDV.DropDownValue) as HTSCode, ISNULL(HTSDescription,DDV.Description) as HTSDescription,Box,QTY,MO_ID,MO,Receiving_Cost FROM (
	SELECT DISTINCT
		DDV.DropDownValue AS HTSCode
		,ISNULL(DDV.Description,VBT.StyleNumber) AS HTSDescription
		,[MO_ID]
		  ,[MO]
		  ,[BoxNumber | PPBU] as Box
		  ,[Warehouse | LocationCost]
		  ,[BIN | SewLocation]
		  ,[QTY]
		  ,[GarmentSize]
		  ,[StyleColor]
		  ,[Receiving_Cost]
	  FROM [Financial].[dboReaders].[VW_Warehouse_And_WIP_Inventory] VBT
	  LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON VBT.MO_ID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND CONCAT(StyleNumber+'-',StyleColor+'-',GarmentSize) = lpmW.PartNumber AND lpmW.UnitCost IS NOT NULL
		--AND VBT.MO_ID NOT IN (415461
		--,415464
		--,443438
		--,415448
		--,415494
		--,415465
		--,415459
		--,446607
		--)
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW2 WITH (NOLOCK) ON VBT.MO_ID = lpmW2.ManufactureID AND lpmW2.CategoryName = 'Contracts' AND CONCAT(StyleNUmber+'-',StyleColor+'-F-',GarmentSize) = lpmW2.PartNumber AND lpmW2.UnitCost IS NOT NULL
		--AND VBT.MO_ID NOT IN (415461
		--,415464
		--,443438
		--,415448
		--,415494
		--,415465
		--,415459
		--,446607
		--)
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW3 WITH (NOLOCK) ON VBT.MO_ID = lpmW3.ManufactureID AND lpmW3.CategoryName = 'Contracts' AND CONCAT(StyleNumber+'-',StyleColor+'-U-',GarmentSize) = lpmW3.PartNumber AND lpmW3.UnitCost IS NOT NULL
		--AND VBT.MO_ID NOT IN (415461
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
	  WHERE [Warehouse | LocationCost] IN ('Stock Warehouse','HeadWear DLI')
	  AND SeasonName in ('BLANK FG','EMB FG')
	  --AND StyleNumber NOT IN ('05PDT','10PDT','15PDT')

	  ) TB1
	  LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON TB1.MO_ID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND lpmW.UnitCost IS NOT NULL
		--AND TB1.MO_ID NOT IN (415461
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
		--WHERE --(HTSCode IS NOT NULL and DDV.DropDownValue IS NOT NULL)
--		MO_ID IN (
--		446607
--,415461
--,415464
--,443438
--,415448
--,415494
--,415465
--,415459
--)
) XD
GROUP BY HTSCode,HTSDescription