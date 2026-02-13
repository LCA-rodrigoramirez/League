USE Financial;

DROP TABLE IF EXISTS #TB_Pre_Inventory_INI
DROP TABLE IF EXISTS #TB_Pre_Inventory_SHIP
DROP TABLE IF EXISTS #TB_Pre_Inventory_FIN

DROP TABLE IF EXISTS #TB_Inicial
DROP TABLE IF EXISTS #TB_Entradas
DROP TABLE IF EXISTS #TB_Salidas
DROP TABLE IF EXISTS #TB_Final

DROP TABLE IF EXISTS #TB_ALL

--------------------------------------------------- SALDO INICIAL -------------------------------------------------------------

	SELECT 
			DateInventory
			,ISNULL(BoxNumber,BundleBarcode) as BoxNumber
			,Style			= ISNULL(BS.StyleNumber,Style)
			,Color
			,Size
			,warehousename
			,INV.ManufactureID
			,Bin
			,inv.MO
			--,StyleID		= INV.StyleID
			,HTSCode		= CAST(NULL AS varchar(100))
			,HTSDescription	= CAST(NULL AS varchar(100))
			,Quantity 
			,Costo			= ROUND(Contracts+[Trim]+[Supplies],4)
		INTO #TB_Pre_Inventory_INI
		FROM AppsLCA.dbo.TB_INVENTORY_WH_BND_CT_PACK	AS INV WITH(NOLOCK)
		LEFT JOIN Styles								AS ST  WITH(NOLOCK) ON INV.StyleID = ST.StyleID
		LEFT JOIN Styles								AS BS  WITH(NOLOCK) ON ST.BlankStyleID = BS.StyleID
		WHERE TypeQueryN <> 4 AND FilterSemi = 1
		and (FilterTakeUnits = 1 or (FilterTakeUnits = 0  and TypeQueryN <> 1))
		and dateInventory = '2025-06-30' 

		UPDATE INV SET
			INV.HTSCode = COALESCE(EO.DropDownValue,DDV.DropDownValue)
			,INV.HTSDescription = COALESCE(EO.[Description],DDV.[Description])
			--SELECT *
		FROM #TB_Pre_Inventory_INI AS INV
		LEFT JOIN
		(
			SELECT distinct
				 EORO.RO_ID
				,EORO.RO
				,INV.ManufactureID
				,inv.MO
				,ddv.DropDownValue
				,ddv.[Description]
			FROM LCA.dboReaders.VW_EORO AS EORO WITH(NOLOCK)
			INNER JOIN #TB_Pre_Inventory_INI AS INV ON EORO.EO_ID = INV.ManufactureID
			LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON EORO.RO_ID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-',INV.Size) = lpmW.PartNumber AND lpmW.UnitCost IS NOT NULL
			LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW2 WITH (NOLOCK) ON EORO.RO_ID = lpmW2.ManufactureID AND lpmW2.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-F-',INV.Size) = lpmW2.PartNumber AND lpmW2.UnitCost IS NOT NULL
			LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW3 WITH (NOLOCK) ON EORO.RO_ID = lpmw3.ManufactureID AND lpmW3.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-U-',INV.Size) = lpmW3.PartNumber AND lpmW3.UnitCost IS NOT NULL
			LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW4 WITH (NOLOCK) ON EORO.RO_ID = lpmW4.ManufactureID AND lpmW4.CategoryName = 'Contracts' AND lpmW4.UnitCost IS NOT NULL
			LEFT JOIN RawMaterials RM WITH (NOLOCK) ON COALESCE(lpmW.RawMaterialID,lpmw2.RawMaterialID,lpmw3.RawMaterialID,lpmW4.RawMaterialID) = RM.RawMaterialID
			LEFT JOIN DropDownValues						AS DDV WITH(NOLOCK) ON RM.HTSCodeID	= DDV.DropDownValueID
			-- and ddv.DropDownValue = '6109100000'
			-- order by eoro.RO_ID

			--64449
		) 												AS EO				ON INV.ManufactureID = eo.ManufactureID 
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON INV.ManufactureID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-',INV.Size) = lpmW.PartNumber AND lpmW.UnitCost IS NOT NULL
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW2 WITH (NOLOCK) ON INV.ManufactureID = lpmW2.ManufactureID AND lpmW2.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-F-',INV.Size) = lpmW2.PartNumber AND lpmW2.UnitCost IS NOT NULL
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW3 WITH (NOLOCK) ON INV.ManufactureID = lpmW3.ManufactureID AND lpmW3.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-U-',INV.Size) = lpmW3.PartNumber AND lpmW3.UnitCost IS NOT NULL
		LEFT JOIN RawMaterials RM WITH (NOLOCK) ON ISNULL(ISNULL(lpmW.RawMaterialID,lpmw2.RawMaterialID),lpmw3.RawMaterialID) = RM.RawMaterialID
		LEFT JOIN DropDownValues						AS DDV WITH(NOLOCK) ON RM.HTSCodeID	= DDV.DropDownValueID
		-- WHERE DDV.DropDownValue = '6104630000'

		UPDATE INV SET
				HTSCode		= ISNULL(
								ISNULL(HTSCode,DDV.DropDownValue),
									CASE WHEN Style = 'LU430' THEN '6104620000'
										WHEN Style = '82196' THEN '6110300000'
										WHEN Style = 'RW209' THEN '6109900000'
									END)
				,HTSDescription = ISNULL(ISNULL(HTSDescription,DDV.Description),
									CASE WHEN Style = 'LU430' THEN 'PANTALONES Y SHORTS DE ALGODON CONFECCINADOS P/MUJERES'
										WHEN Style = '82196' THEN 'SUDADERAS DE FIBRA SINTETICA CONFECCIONADAS P/MUJERES'
										WHEN Style = 'RW209' THEN 'CAMISETAS PLAYERAS  DE FIBRAS SINTETICAS PARA MUJERES'
									END)
		FROM #TB_Pre_Inventory_INI AS INV
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON INV.ManufactureID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND lpmW.UnitCost IS NOT NULL
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

	SELECT
		
		HTSDescription
		,CASE 
			WHEN UDM = 'each' THEN 'UNIDAD'
			WHEN UDM = 'yard' THEN 'YARD'
			WHEN UDM = 'roll' THEN 'ROLLO'
			WHEN UDM = 'kilogram' THEN 'KILOGRAMO'
			WHEN UDM = 'cone' THEN 'CONO'
			WHEN UDM = 'drum' THEN 'BARRIL'
			WHEN UDM = 'gallon' THEN 'GALON'
			WHEN UDM = 'gram' THEN 'GRAMO'
			WHEN UDM = 'liter' THEN 'LITRO'
			WHEN UDM = 'meter' THEN 'METRO'
			WHEN UDM = 'set' THEN 'SET'
			WHEN UDM = 'sheet' THEN 'HOJA'
			ELSE UDM
		 END AS UDM
		,HTSCode
		,SUM(Quantity) as SaldoInicial_Units
		,SUM(Costo) as SaldoInicial_Total
	INTO #TB_Inicial
	FROM
	(
		SELECT
			HTSCode
			,HTSDescription
			,'UNIDAD' as UDM
			,SUM(Quantity) as Quantity
			,SUM(Costo) as Costo
		FROM
		(
			SELECT 
				HTSCode
				,HTSDescription
				,Style
				,Color
				,Size
				,BoxNumber
				,Quantity
				,TB1.ManufactureID
				,MO
				,Costo
				--SELECT DISTINCT Style, Color, Size, HTSDescription, concat(Style,'-', Color,'-', Size) as PN
			FROM #TB_Pre_Inventory_INI AS TB1
			-- WHERE HTSCode = '6109100000'
			-- AND HTSDescription = 'CAMISETAS DE ALGODON  CONFECCIONADAS P/HOMBRES (SEMI-ELABORADAS)'

			--WHERE ISNULL(HTSCode,DDV.DropDownValue) IS NULL
		) TBF
		GROUP BY 
			HTSCode
			,HTSDescription

		UNION

		select 
			--DateInventory 
		--	,StyleNumber
			--,StyleID
			HTSCode		= DDV.DropDownValue 
			,HTSDescription = DDV.Description
			,'UNIDAD' as UDM
			,Quantity		= SUM(QTY)
			,Costo			= ROUND(SUM((UnitPrice+GI.UnitFreightCost) * QTY),2)
		from AppsLCA.dbo.TB_INVENTORY_GreigeItems	AS GI  WITH(NOLOCK)
		LEFT JOIN RawContainers						AS RC  WITH(NOLOCK) ON RC.ContainerCode = GI.BoxNumber
		LEFT JOIN RawMaterials						AS RM  WITH(NOLOCK) ON RC.RawMaterialID = RM.RawMaterialID
		LEFT JOIN DropDownValues					AS DDV WITH(NOLOCK) ON RM.HTSCodeID = DDV.DropDownValueID
		WHERE dateInventory = '2025-06-30'
		GROUP BY  --DateInventory 
			--	 ,StyleNumber
				-- ,StyleID
				DDV.DropDownValue
				,DDV.Description

		UNION ALL

		
		SELECT  
			 ddv	AS HTSCode
			,ddvdes AS HTSDescription
			,Units AS UDM
			,SUM(OH) as Quantity
			,SUM(Cost) as Costo
		FROM(
						select 

									ddv.DropDownValue as ddv
									,ddv2.DropDownValue as ddv2
									,ddv.Description as ddvdes
									,ddv2.Description as ddv2des
									,left (ct.SAC + '0000000000', 10) as SAC 
									,ct.Category
									,ct.Units
									,sum (ct.[Container Unit Cost] * ct.[On Hand]) as cost
									,sum (ct.[On Hand]) as OH
										, CT.[Part Number] ,'INCIAL' as [Type]
		FROM (SELECT DISTINCT
			[Code]
			,[Category]
			,[Subcategory]
			,[Family]
			,[Inv Accounting]
			,[Part Number]
			,[Part Color]
			,[Status]
			,[Roll]
			,[PO Number]
			,[Description]
			,[Fabric Width]
			,[On Hand]
			,[Units]
			,[Bin]
			,[Warehouse]
			,[Dye Lot]
			,[Vendor Name]
			,[IM5/IM9]
			,[SAC]
			,[Technical Desc.]
			,[Invoice Number]
			,[Unit Symbol]
			,[Average Material Cost]
			,[Container Unit Cost]
			,[Unit Freight Cost]
			,[Total]
			,[Total With Freight]
			,[Deadline]
			,[Month]
			,[Counting]
			,[Fam]
			,[Acou]
			,[Fecha]
		FROM [AppsLCA].[dbo].[CostoWarehouse])ct
					left outer join Financial.dbo.RawMaterials on RawMaterials.PartNumber = ct.[Part Number]
		LEFT OUTER JOIN Financial.dbo.DropDownValues ddv ON RawMaterials.HTSCodeID = ddv.DropDownValueID
		left outer join Financial.dbo.DropDownValues ddv2 on ddv2.DropDownValue = left (ct.SAC + '0000000000', 10) and ddv.DropDownValue is null 

		where 
			Fecha = '2025-06-30'  --SALDO INICIAL
			-- Fecha = '2025-06-30'  --SALDO FINAL
			and ct.category<>'Expandable'
  			and ct.category<>'Expendable'
		
		group by  CT.[Part Number],ddv.DropDownValue ,ct.Units,ddv.Description,ct.Category,left (ct.SAC + '0000000000', 10) ,ddv2.DropDownValue,ddv2.Description
						
		)TB
		WHERE Category <> 'Expendable'
		AND Category <> 'Contracts'
		AND ddv <> 'N/A'

		GROUP BY ddv,ddv2,ddvdes,ddv2des,Category,Units

		
	) AS TB_ALL
	GROUP BY
		HTSDescription
		,UDM
		,HTSCode

--------------------------------------------------- SALDO INICIAL -------------------------------------------------------------

--------------------------------------------------- ENTRADAS -------------------------------------------------------------

	select 
	
	tt.Description AS HTSDescription
	,CASE 
			WHEN tt.DatabaseUnits = 'each' THEN 'UNIDAD'
			WHEN tt.DatabaseUnits = 'yard' THEN 'YARD'
			WHEN tt.DatabaseUnits = 'roll' THEN 'ROLLO'
			WHEN tt.DatabaseUnits = 'kilogram' THEN 'KILOGRAMO'
			WHEN tt.DatabaseUnits = 'cone' THEN 'CONO'
			WHEN tt.DatabaseUnits = 'drum' THEN 'BARRIL'
			WHEN tt.DatabaseUnits = 'gallon' THEN 'GALON'
			WHEN tt.DatabaseUnits = 'gram' THEN 'GRAMO'
			WHEN tt.DatabaseUnits = 'liter' THEN 'LITRO'
			WHEN tt.DatabaseUnits = 'meter' THEN 'METRO'
			WHEN tt.DatabaseUnits = 'set' THEN 'SET'
			WHEN tt.DatabaseUnits = 'sheet' THEN 'HOJA'
			ELSE tt.DatabaseUnits
		 END AS UDM
	,tt.DropDownValue AS HTSCode
	,sum(tt.Quantity) as Entradas_Units
	,sum(tt.[UnitCost * Quantity]) AS Entradas_Total
	into #TB_Entradas
	from (

		SELECT  
			 [RawTransactionID]        		= RT.[RawTransactionID]
			,[ManufactureID]            	= RT.[ManufactureID]
			,[ManufactureNumber]        	= MO.[ManufactureNumber]
			,[StyleID]                  	= ST.[StyleID]
			,[StyleNumber]              	= ST.[StyleNumber]
			,[PONumber_Purchase]        	= PO.[PONumber]
			,[QuantityOrdered]          	= PD.[QuantityOrdered]
			,[VendorNumber]             	= VND.[CompanyNumber]
			,[#VendorNumber]            	= VND.[#CompanyNumber]
			,[ReceiveNumber]            	= REC.[ShipNumber]
			,[ReceiveID]             		= RT.[ReceiveID]
			,[InvoiceNumber]            	= REC.[InvoiceNumber]
			,[PartNumber]               	= RM.[PartNumber]
			,[RawMaterialID]         		= RT.[RawMaterialID]
			,[PartColor]                	= COL.[ColorName]
			,[ComponentID]              	= RM.[ComponentID]
			,[CategoryName]             	= IIF(CC.CategoryName = 'CareLabels','Interlining/Pellon',CC.CategoryName)
			,[SubcategoryName]          	= CB.[SubcategoryName]
			,[PartSummary]              	= ISNULL(RM.[Description], '') + ' ' 
											+ ISNULL(COL.[ColorName], '') + ' ' 
											+ ISNULL(FB.[FabricUsageName], '') + ' ' 
			,[RawContainerID]          		= RC.[RawContainerID]
			-- ,[DatabaseUnits]            	= UN.UnitName
			,[DatabaseUnits]            	= DC.TranslatedText
			,[DatabaseUnitSymbol]       	= UN.UnitSymbol
			,[QuantitySubtotal]         	= RT.[Quantity]
			,[UserTransactionDate]      	= RT.[UserTransactionDate]
			,[TransactionReason]        	= RSN.[DropDownValue]
			,[UnitCost]                 	= RT.[UnitCost]
			,[TransactionTypeName]      	= TTP.[Description]
			,[SetGroupCode]             	= RT.[GroupCode]
			,[TransactionGroupCode]     	= LTRIM(STR(ISNULL([GroupCode], RT.[ChangeLogID]) + 1000000))
			,[TransactionDate]          	= CHL.[ChangeDate]
			,[ChangeLogID]           		= RT.[ChangeLogID]
			,[UserName]                 	= US.[UserName]
			,[ACTION]                   	= CHL.[ACTION]
			,[Comment]                  	= CHL.[Comment]
			,[ContainerCode]            	= RC.[ContainerCode]
			,[Label]                    	= RC.[Label]
			,[DyeLot]                   	= RC.[DyeLot]
			,[Comments3]                	= RC.[Comments3]
			,[ReceiveDate]              	= ISNULL(RC.[ReceiveDate], REC.[ReceiveDate])
			,[InitialReceived]          	= RC.[InitialReceived]
			,[UnitFreightCost]          	= RC.[UnitFreightCost]
			,[Quantity]                 	= CT.[Quantity]
			,[OrigReceiveWayBill]       	= WB.[WayBill]
			,[OrigVendorName]           	= OVN.[CompanyName]
			,[InternalKey]              	= CT.[InternalKey]
			,[ManufactureGroup_]        	= GP.[ManufactureNumber]
			,[WayBill_]                 	= REC.[WayBill]
			,[UnitFreightCost * Quantity] 	= RC.[UnitFreightCost] * CT.[Quantity]
			,[UnitCost * Quantity]        	= RT.[UnitCost] * CT.[Quantity]
			,[MonthTransaction]           	= MONTH(CHL.[ChangeDate])
			,[YearTransaction]            	= YEAR(CHL.[ChangeDate])
			,[DayTransaction]             	= DAY(CHL.[ChangeDate])
			,[DropDownValue]				= DDV.DropDownValue
			,[Description]					= DDV.[Description]
		FROM        LCA.dbo.RawTransactions         AS RT   WITH(NOLOCK)
		LEFT JOIN   LCA.dbo.ContainerTransfers      AS CT   WITH(NOLOCK) ON RT.RawTransactionID         = CT.RawTransactionID
		INNER JOIN  LCA.dbo.RawContainers           AS RC   WITH(NOLOCK) ON CT.RawContainerID           = RC.RawContainerID         AND  RC.ContainerCode <> '<Default>'
		
		
		LEFT JOIN   LCA.dbo.ManufactureOrders       AS MO   WITH(NOLOCK) ON RT.ManufactureID            = MO.ManufactureID 
		LEFT JOIN   LCA.dbo.OrderItems              AS OI   WITH(NOLOCK) ON MO.FirstOrderItemID         = OI.OrderItemID
		LEFT JOIN   LCA.dbo.Styles                  AS ST   WITH(NOLOCK) ON OI.StyleID                  = ST.StyleID 
		LEFT JOIN   LCA.dbo.ManufactureOrders       AS GP   WITH(NOLOCK) ON MO.ManufactureGroupID       = GP.ManufactureID 
		LEFT JOIN   LCA.dbo.PurchaseDetails         AS PD   WITH(NOLOCK) ON RT.PurchaseDetailID         = PD.PurchaseDetailID
		LEFT JOIN   LCA.dbo.PurchaseOrders          AS PO   WITH(NOLOCK) ON PD.PurchaseID               = PO.PurchaseID 
		LEFT JOIN   LCA.dbo.Addresses               AS VND  WITH(NOLOCK) ON PO.VendorID                 = VND.AddressID 
		LEFT JOIN   LCA.dbo.ReceiveSlips            AS REC  WITH(NOLOCK) ON RT.ReceiveID                = REC.ReceiveID
		LEFT JOIN   LCA.dbo.RawMaterials            AS RM   WITH(NOLOCK) ON RT.RawMaterialID            = RM.RawMaterialID 
		LEFT JOIN   LCA.dbo.Colors                  AS COL  WITH(NOLOCK) ON RM.ColorID                  = COL.ColorID
		LEFT JOIN   LCA.dbo.ComponentLibrary        AS CL   WITH(NOLOCK) ON RM.ComponentID              = CL.ComponentID 
		LEFT JOIN   LCA.dbo.ComponentCategories     AS CC   WITH(NOLOCK) ON CC.ComponentCategoryID      = CL.ComponentCategoryID 
		LEFT JOIN   LCA.dbo.ComponentSubcategories  AS CB   WITH(NOLOCK) ON CL.SubcategoryID            = CB.SubcategoryID
		LEFT JOIN   LCA.dbo.FabricUsage             AS FB   WITH(NOLOCK) ON CL.FabricUsageID            = FB.FabricUsageID
		LEFT JOIN   LCA.dbo.UnitNames               AS UN   WITH(NOLOCK) ON CL.DatabaseUnitID           = UN.UnitNameID 
		LEFT JOIN   LCA.dbo.Dictionary              AS DC   WITH(NOLOCK) ON DC.OriginalText             = UN.UnitName				AND DC.MessageSource = 'UnitNames' and DC.LanguageID = 1
		LEFT JOIN   LCA.dbo.DropDownValues3         AS RSN  WITH(NOLOCK) ON RT.TransactionReasonID      = RSN.DropDownValueID
		LEFT JOIN   LCA.dbo.EnumValues              AS TTP  WITH(NOLOCK) ON RT.RawTransactionTypeID     = TTP.EnumValueID
		LEFT JOIN   LCA.dbo.ChangeLog               AS CHL  WITH(NOLOCK) ON CHL.ChangeLogID             = RT.ChangeLogID
		LEFT JOIN   LCA.dbo.Users                   AS US   WITH(NOLOCK) ON CHL.UserID                  = US.UserID 
		LEFT JOIN   LCA.dbo.ReceiveSlips            AS WB   WITH(NOLOCK) ON RC.ReceiveID                = WB.ReceiveID 
		LEFT JOIN   LCA.dbo.Addresses               AS OVN  WITH(NOLOCK) ON WB.VendorID                 = OVN.AddressID 
		LEFT JOIN   LCA.dbo.DropDownValues          AS ddv  WITH(NOLOCK) ON RM.HTSCodeID = ddv.DropDownValueID
		
		WHERE convert( varchar(10),CHL.changedate, 111) BETWEEN '2025/07/01'  AND '2025/09/30'
		AND TTP.[Description] in ('Receive','Receive Excess')--ENTRADAS
		and DDV.DropDownValue <> 'N/A'
		AND CC.CategoryName <> 'Expendable'

	)  as tt 

	group by 
	tt.DropDownValue
	,tt.Description
	,tt.DatabaseUnits

	order by DropDownValue

--------------------------------------------------- ENTRADAS -------------------------------------------------------------

--------------------------------------------------- SALIDAS ---------------------------------------------------------------

	SELECT DISTINCT
			DateAnexo
			,WayBill
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
			,HTSCode		= CAST(NULL AS VARCHAR(100))
			,HTSDescription	= CAST(NULL AS VARCHAR(100))
			,Quantity 
			,Costo			= ROUND(Contracts+[Trim]+[Supplies],4)
		INTO #TB_Pre_Inventory_SHIP
		--select *
		FROM AppsLCA.dbo.TB_INVENTORY_SHIP	AS INV WITH(NOLOCK)
		LEFT JOIN Styles								AS ST  WITH(NOLOCK) ON INV.StyleID = ST.StyleID
		LEFT JOIN Styles								AS BS  WITH(NOLOCK) ON ST.BlankStyleID = BS.StyleID
		

		WHERE TypeQueryN <> 4 AND FilterSemi = 1
		and (FilterTakeUnits = 1 or (FilterTakeUnits = 0  and TypeQueryN <> 1))
		and DateAnexo = '2025-09-01'
		--and ddv.DropDownValue = '6109100000'
		
		-- SELECT SUM(Quantity) FROM #TB_Pre_Inventory_SHIP

		-- SELECT SUM(Quantity) FROM AppsLCA.dbo.TB_INVENTORY_SHIP	AS INV WITH(NOLOCK) WHERE TypeQueryN <> 4 AND FilterSemi = 1
		-- and (FilterTakeUnits = 1 or (FilterTakeUnits = 0  and TypeQueryN <> 1))
		-- and DateAnexo = '2025-09-01'

	UPDATE INV SET
		 HTSCode = COALESCE(EO.DropDownValue,DDV.DropDownValue)
		,HTSDescription = COALESCE(EO.Description,DDV.Description)
	FROM #TB_PRE_Inventory_SHIP AS INV
	LEFT JOIN
		(
			SELECT distinct
				 EORO.RO_ID
				,EORO.RO
				,INV.ManufactureID
				,inv.MO
				,ddv.DropDownValue
				,ddv.[Description]
			FROM LCA.dboReaders.VW_EORO AS EORO WITH(NOLOCK)
			INNER JOIN AppsLCA.dbo.TB_INVENTORY_SHIP	AS INV WITH(NOLOCK) ON EORO.EO_ID = INV.ManufactureID
			LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON EORO.RO_ID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-',INV.Size) = lpmW.PartNumber AND lpmW.UnitCost IS NOT NULL
			LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW2 WITH (NOLOCK) ON EORO.RO_ID = lpmW2.ManufactureID AND lpmW2.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-F-',INV.Size) = lpmW2.PartNumber AND lpmW2.UnitCost IS NOT NULL
			LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW3 WITH (NOLOCK) ON EORO.RO_ID = lpmw3.ManufactureID AND lpmW3.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-U-',INV.Size) = lpmW3.PartNumber AND lpmW3.UnitCost IS NOT NULL
			LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW4 WITH (NOLOCK) ON EORO.RO_ID = lpmW4.ManufactureID AND lpmW4.CategoryName = 'Contracts' AND lpmW4.UnitCost IS NOT NULL
			LEFT JOIN RawMaterials RM WITH (NOLOCK) ON COALESCE(lpmW.RawMaterialID,lpmw2.RawMaterialID,lpmw3.RawMaterialID,lpmW4.RawMaterialID) = RM.RawMaterialID
			LEFT JOIN DropDownValues						AS DDV WITH(NOLOCK) ON RM.HTSCodeID	= DDV.DropDownValueID
			WHERE TypeQueryN <> 4 AND FilterSemi = 1
			and (FilterTakeUnits = 1 or (FilterTakeUnits = 0  and TypeQueryN <> 1))
			and DateAnexo = '2025-09-01' AND DDV.DropDownValue IS NOT NULL
			-- and ddv.DropDownValue = '6109100000'
			-- order by eoro.RO_ID

			--64449
		) 												AS EO				ON INV.ManufactureID = eo.ManufactureID 
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON INV.ManufactureID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-',INV.Size) = lpmW.PartNumber AND lpmW.UnitCost IS NOT NULL
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW2 WITH (NOLOCK) ON INV.ManufactureID = lpmW2.ManufactureID AND lpmW2.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-F-',INV.Size) = lpmW2.PartNumber AND lpmW2.UnitCost IS NOT NULL
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW3 WITH (NOLOCK) ON INV.ManufactureID = lpmW3.ManufactureID AND lpmW3.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-U-',INV.Size) = lpmW3.PartNumber AND lpmW3.UnitCost IS NOT NULL
		LEFT JOIN RawMaterials RM WITH (NOLOCK) ON ISNULL(ISNULL(lpmW.RawMaterialID,lpmw2.RawMaterialID),lpmw3.RawMaterialID) = RM.RawMaterialID
		LEFT JOIN DropDownValues						AS DDV WITH(NOLOCK) ON RM.HTSCodeID	= DDV.DropDownValueID

		
	SELECT
		
		HTSDescription
		,UDM
		,HTSCode
		,SUM(ABS(Salidas_Units)) as Salidas_Units
		,SUM(ABS(Salidas_Total)) as Salidas_Total
	INTO #TB_Salidas
	FROM
	(		
		SELECT
				HTSDescription
				,'UNIDAD' as UDM
				,HTSCode
				,SUM(Quantity) as Salidas_Units
				,SUM(Costo) as Salidas_Total
			FROM
			(
				SELECT DISTINCT
					HTSCode		= ISNULL(ISNULL(HTSCode,DDV.DropDownValue),
										CASE WHEN Style = 'LU430' THEN '6104620000'
											WHEN Style = '82196' THEN '6110300000'
											WHEN Style = 'RW209' THEN '6109900000'
										END)
					,'UNIDAD' as UDM									
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
					--select *
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
				-- where ddv.DropDownValue = '6109100000'
				--WHERE ISNULL(HTSCode,DDV.DropDownValue) IS NULL
			) TBF
			GROUP BY 
				HTSCode
				,HTSDescription
	-- ) as tb
	-- GROUP BY 
	-- 			HTSCode
	-- 			,HTSDescription
	-- 			,udm

	-- SELECT SUM(Salidas_Units) FROM #TB_Salidas
			UNION ALL

			select 
		
			tt.Description AS HTSDescription
			,CASE 
					WHEN tt.DatabaseUnits = 'each' THEN 'UNIDAD'
					WHEN tt.DatabaseUnits = 'yard' THEN 'YARD'
					WHEN tt.DatabaseUnits = 'roll' THEN 'ROLLO'
					WHEN tt.DatabaseUnits = 'kilogram' THEN 'KILOGRAMO'
					WHEN tt.DatabaseUnits = 'cone' THEN 'CONO'
					WHEN tt.DatabaseUnits = 'drum' THEN 'BARRIL'
					WHEN tt.DatabaseUnits = 'gallon' THEN 'GALON'
					WHEN tt.DatabaseUnits = 'gram' THEN 'GRAMO'
					WHEN tt.DatabaseUnits = 'liter' THEN 'LITRO'
					WHEN tt.DatabaseUnits = 'meter' THEN 'METRO'
					WHEN tt.DatabaseUnits = 'set' THEN 'SET'
					WHEN tt.DatabaseUnits = 'sheet' THEN 'HOJA'
					ELSE tt.DatabaseUnits
				END AS UDM
			,tt.DropDownValue AS HTSCode
			,sum(tt.Quantity) as Salidas_Units
			,sum(tt.[UnitCost * Quantity]) AS Salidas_Total
			from (



				SELECT  
					 [RawTransactionID]        		= RT.[RawTransactionID]
					,[ManufactureID]            	= RT.[ManufactureID]
					,[ManufactureNumber]        	= MO.[ManufactureNumber]
					,[StyleID]                  	= ST.[StyleID]
					,[StyleNumber]              	= ST.[StyleNumber]
					,[PONumber_Purchase]        	= PO.[PONumber]
					,[QuantityOrdered]          	= PD.[QuantityOrdered]
					,[VendorNumber]             	= VND.[CompanyNumber]
					,[#VendorNumber]            	= VND.[#CompanyNumber]
					,[ReceiveNumber]            	= REC.[ShipNumber]
					,[ReceiveID]             		= RT.[ReceiveID]
					,[InvoiceNumber]            	= REC.[InvoiceNumber]
					,[PartNumber]               	= RM.[PartNumber]
					,[RawMaterialID]         		= RT.[RawMaterialID]
					,[PartColor]                	= COL.[ColorName]
					,[ComponentID]              	= RM.[ComponentID]
					,[CategoryName]             	= IIF(CC.CategoryName = 'CareLabels','Interlining/Pellon',CC.CategoryName)
					,[SubcategoryName]          	= CB.[SubcategoryName]
					,[PartSummary]              	= ISNULL(RM.[Description], '') + ' ' 
													+ ISNULL(COL.[ColorName], '') + ' ' 
													+ ISNULL(FB.[FabricUsageName], '') + ' ' 
					,[RawContainerID]          		= RC.[RawContainerID]
					-- ,[DatabaseUnits]            	= UN.UnitName
					,[DatabaseUnits]            	= DC.TranslatedText
					,[DatabaseUnitSymbol]       	= UN.UnitSymbol
					,[QuantitySubtotal]         	= RT.[Quantity]
					,[UserTransactionDate]      	= RT.[UserTransactionDate]
					,[TransactionReason]        	= RSN.[DropDownValue]
					,[UnitCost]                 	= RT.[UnitCost]
					,[TransactionTypeName]      	= TTP.[Description]
					,[SetGroupCode]             	= RT.[GroupCode]
					,[TransactionGroupCode]     	= LTRIM(STR(ISNULL([GroupCode], RT.[ChangeLogID]) + 1000000))
					,[TransactionDate]          	= CHL.[ChangeDate]
					,[ChangeLogID]           		= RT.[ChangeLogID]
					,[UserName]                 	= US.[UserName]
					,[ACTION]                   	= CHL.[ACTION]
					,[Comment]                  	= CHL.[Comment]
					,[ContainerCode]            	= RC.[ContainerCode]
					,[Label]                    	= RC.[Label]
					,[DyeLot]                   	= RC.[DyeLot]
					,[Comments3]                	= RC.[Comments3]
					,[ReceiveDate]              	= ISNULL(RC.[ReceiveDate], REC.[ReceiveDate])
					,[InitialReceived]          	= RC.[InitialReceived]
					,[UnitFreightCost]          	= RC.[UnitFreightCost]
					,[Quantity]                 	= CT.[Quantity]
					,[OrigReceiveWayBill]       	= WB.[WayBill]
					,[OrigVendorName]           	= OVN.[CompanyName]
					,[InternalKey]              	= CT.[InternalKey]
					,[ManufactureGroup_]        	= GP.[ManufactureNumber]
					,[WayBill_]                 	= REC.[WayBill]
					,[UnitFreightCost * Quantity] 	= RC.[UnitFreightCost] * CT.[Quantity]
					,[UnitCost * Quantity]        	= RT.[UnitCost] * CT.[Quantity]
					,[MonthTransaction]           	= MONTH(CHL.[ChangeDate])
					,[YearTransaction]            	= YEAR(CHL.[ChangeDate])
					,[DayTransaction]             	= DAY(CHL.[ChangeDate])
					,[DropDownValue]				= DDV.DropDownValue
					,[Description]					= DDV.[Description]
					--select distinct cc.categoryname
				FROM        LCA.dbo.RawTransactions         AS RT   WITH(NOLOCK)
				LEFT JOIN   LCA.dbo.ContainerTransfers      AS CT   WITH(NOLOCK) ON RT.RawTransactionID         = CT.RawTransactionID
				INNER JOIN  LCA.dbo.RawContainers           AS RC   WITH(NOLOCK) ON CT.RawContainerID           = RC.RawContainerID         AND  RC.ContainerCode <> '<Default>'
				
				
				LEFT JOIN   LCA.dbo.ManufactureOrders       AS MO   WITH(NOLOCK) ON RT.ManufactureID            = MO.ManufactureID 
				LEFT JOIN   LCA.dbo.OrderItems              AS OI   WITH(NOLOCK) ON MO.FirstOrderItemID         = OI.OrderItemID
				LEFT JOIN   LCA.dbo.Styles                  AS ST   WITH(NOLOCK) ON OI.StyleID                  = ST.StyleID 
				LEFT JOIN   LCA.dbo.ManufactureOrders       AS GP   WITH(NOLOCK) ON MO.ManufactureGroupID       = GP.ManufactureID 
				LEFT JOIN   LCA.dbo.PurchaseDetails         AS PD   WITH(NOLOCK) ON RT.PurchaseDetailID         = PD.PurchaseDetailID
				LEFT JOIN   LCA.dbo.PurchaseOrders          AS PO   WITH(NOLOCK) ON PD.PurchaseID               = PO.PurchaseID 
				LEFT JOIN   LCA.dbo.Addresses               AS VND  WITH(NOLOCK) ON PO.VendorID                 = VND.AddressID 
				LEFT JOIN   LCA.dbo.ReceiveSlips            AS REC  WITH(NOLOCK) ON RT.ReceiveID                = REC.ReceiveID
				LEFT JOIN   LCA.dbo.RawMaterials            AS RM   WITH(NOLOCK) ON RT.RawMaterialID            = RM.RawMaterialID 
				LEFT JOIN   LCA.dbo.Colors                  AS COL  WITH(NOLOCK) ON RM.ColorID                  = COL.ColorID
				LEFT JOIN   LCA.dbo.ComponentLibrary        AS CL   WITH(NOLOCK) ON RM.ComponentID              = CL.ComponentID 
				LEFT JOIN   LCA.dbo.ComponentCategories     AS CC   WITH(NOLOCK) ON CC.ComponentCategoryID      = CL.ComponentCategoryID 
				LEFT JOIN   LCA.dbo.ComponentSubcategories  AS CB   WITH(NOLOCK) ON CL.SubcategoryID            = CB.SubcategoryID
				LEFT JOIN   LCA.dbo.FabricUsage             AS FB   WITH(NOLOCK) ON CL.FabricUsageID            = FB.FabricUsageID
				LEFT JOIN   LCA.dbo.UnitNames               AS UN   WITH(NOLOCK) ON CL.DatabaseUnitID           = UN.UnitNameID 
				LEFT JOIN   LCA.dbo.Dictionary              AS DC   WITH(NOLOCK) ON DC.OriginalText             = UN.UnitName				AND DC.MessageSource = 'UnitNames' and DC.LanguageID = 1
				LEFT JOIN   LCA.dbo.DropDownValues3         AS RSN  WITH(NOLOCK) ON RT.TransactionReasonID      = RSN.DropDownValueID
				LEFT JOIN   LCA.dbo.EnumValues              AS TTP  WITH(NOLOCK) ON RT.RawTransactionTypeID     = TTP.EnumValueID
				LEFT JOIN   LCA.dbo.ChangeLog               AS CHL  WITH(NOLOCK) ON CHL.ChangeLogID             = RT.ChangeLogID
				LEFT JOIN   LCA.dbo.Users                   AS US   WITH(NOLOCK) ON CHL.UserID                  = US.UserID 
				LEFT JOIN   LCA.dbo.ReceiveSlips            AS WB   WITH(NOLOCK) ON RC.ReceiveID                = WB.ReceiveID 
				LEFT JOIN   LCA.dbo.Addresses               AS OVN  WITH(NOLOCK) ON WB.VendorID                 = OVN.AddressID 
				LEFT JOIN   LCA.dbo.DropDownValues          AS ddv  WITH(NOLOCK) ON RM.HTSCodeID 				= ddv.DropDownValueID
				
				WHERE convert( varchar(10),CHL.changedate, 111) BETWEEN '2025/07/01'  AND '2025/09/30'
				AND TTP.[Description] in ('adjust minus','adjust plus','MO Return','MO Withdraw')--SALIDAS
				and DDV.DropDownValue <> 'N/A'
				AND CC.CategoryName <> 'Expendable'
				AND CC.CategoryName <> 'Contracts'

			)  as tt 

			group by 
			tt.DropDownValue
			,tt.Description
			,tt.DatabaseUnits

			--order by DropDownValue
	) AS TBS
	group by
		 HTSDescription
		,UDM
		,HTSCode

--------------------------------------------------- SALIDAS ---------------------------------------------------------------

--------------------------------------------------- SALDO FINAL -------------------------------------------------------------

	SELECT DISTINCT
			DateInventory
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
		INTO #TB_Pre_Inventory_FIN
		FROM AppsLCA.dbo.TB_INVENTORY_WH_BND_CT_PACK	AS INV WITH(NOLOCK)
		LEFT JOIN Styles								AS ST  WITH(NOLOCK) ON INV.StyleID = ST.StyleID
		LEFT JOIN Styles								AS BS  WITH(NOLOCK) ON ST.BlankStyleID = BS.StyleID
		LEFT JOIN
		(
			SELECT distinct
				 EORO.RO_ID
				,EORO.RO
				,INV.ManufactureID
				,inv.MO
				,ddv.DropDownValue
				,ddv.[Description]
			FROM LCA.dboReaders.VW_EORO AS EORO WITH(NOLOCK)
			INNER JOIN AppsLCA.dbo.TB_INVENTORY_WH_BND_CT_PACK	AS INV WITH(NOLOCK) ON EORO.EO_ID = INV.ManufactureID
			LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON EORO.RO_ID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-',INV.Size) = lpmW.PartNumber AND lpmW.UnitCost IS NOT NULL
			LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW2 WITH (NOLOCK) ON EORO.RO_ID = lpmW2.ManufactureID AND lpmW2.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-F-',INV.Size) = lpmW2.PartNumber AND lpmW2.UnitCost IS NOT NULL
			LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW3 WITH (NOLOCK) ON EORO.RO_ID = lpmw3.ManufactureID AND lpmW3.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-U-',INV.Size) = lpmW3.PartNumber AND lpmW3.UnitCost IS NOT NULL
			LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW4 WITH (NOLOCK) ON EORO.RO_ID = lpmW4.ManufactureID AND lpmW4.CategoryName = 'Contracts' AND lpmW4.UnitCost IS NOT NULL
			LEFT JOIN RawMaterials RM WITH (NOLOCK) ON COALESCE(lpmW.RawMaterialID,lpmw2.RawMaterialID,lpmw3.RawMaterialID,lpmW4.RawMaterialID) = RM.RawMaterialID
			LEFT JOIN DropDownValues						AS DDV WITH(NOLOCK) ON RM.HTSCodeID	= DDV.DropDownValueID
			WHERE TypeQueryN <> 4 AND FilterSemi = 1
			and (FilterTakeUnits = 1 or (FilterTakeUnits = 0  and TypeQueryN <> 1))
			and dateInventory = '2025-09-30' AND DDV.DropDownValue IS NOT NULL
			-- and ddv.DropDownValue = '6109100000'
			-- order by eoro.RO_ID

			--64449
		) 												AS EO				ON INV.ManufactureID = eo.ManufactureID 
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON INV.ManufactureID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-',INV.Size) = lpmW.PartNumber AND lpmW.UnitCost IS NOT NULL
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW2 WITH (NOLOCK) ON INV.ManufactureID = lpmW2.ManufactureID AND lpmW2.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-F-',INV.Size) = lpmW2.PartNumber AND lpmW2.UnitCost IS NOT NULL
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW3 WITH (NOLOCK) ON INV.ManufactureID = lpmW3.ManufactureID AND lpmW3.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-U-',INV.Size) = lpmW3.PartNumber AND lpmW3.UnitCost IS NOT NULL
		LEFT JOIN RawMaterials RM WITH (NOLOCK) ON ISNULL(ISNULL(lpmW.RawMaterialID,lpmw2.RawMaterialID),lpmw3.RawMaterialID) = RM.RawMaterialID
		LEFT JOIN DropDownValues						AS DDV WITH(NOLOCK) ON RM.HTSCodeID	= DDV.DropDownValueID

		WHERE TypeQueryN <> 4 AND FilterSemi = 1
		and (FilterTakeUnits = 1 or (FilterTakeUnits = 0  and TypeQueryN <> 1))
		and dateInventory = '2025-09-30' 


	SELECT 
		 HTSDescription
		,CASE 
			WHEN UDM = 'each' THEN 'UNIDAD'
			WHEN UDM = 'yard' THEN 'YARD'
			WHEN UDM = 'roll' THEN 'ROLLO'
			WHEN UDM = 'kilogram' THEN 'KILOGRAMO'
			WHEN UDM = 'cone' THEN 'CONO'
			WHEN UDM = 'drum' THEN 'BARRIL'
			WHEN UDM = 'gallon' THEN 'GALON'
			WHEN UDM = 'gram' THEN 'GRAMO'
			WHEN UDM = 'liter' THEN 'LITRO'
			WHEN UDM = 'meter' THEN 'METRO'
			WHEN UDM = 'set' THEN 'SET'
			WHEN UDM = 'sheet' THEN 'HOJA'
			ELSE UDM
		 END AS UDM
		,HTSCode
		,SUM(Quantity) as SaldoFinal_Units
		,SUM(Costo) as SaldoFinal_Total
	INTO #TB_Final
	FROM
	(
		SELECT
			HTSCode
			,HTSDescription
			,'UNIDAD' as UDM
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
			FROM #TB_Pre_Inventory_FIN AS TB1
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

		-- select sum(Quantity) from AppsLCA.dbo.TB_INVENTORY_WH_BND_CT_PACK WHERE TypeQueryN <> 4 AND FilterSemi = 1
		--and (FilterTakeUnits = 1 or (FilterTakeUnits = 0  and TypeQueryN <> 1))
		--and dateInventory = '2025-03-31' 
		--and BoxNumber = '00832498'
		--16825
		UNION

		select 
			--DateInventory 
		--	,StyleNumber
			--,StyleID
			HTSCode		= DDV.DropDownValue 
			,HTSDescription = DDV.Description
			,'UNIDAD' as UDM
			,Quantity		= SUM(QTY)
			,Costo			= ROUND(SUM((UnitPrice+GI.UnitFreightCost) * QTY),2)
		from AppsLCA.dbo.TB_INVENTORY_GreigeItems	AS GI  WITH(NOLOCK)
		LEFT JOIN RawContainers						AS RC  WITH(NOLOCK) ON RC.ContainerCode = GI.BoxNumber
		LEFT JOIN RawMaterials						AS RM  WITH(NOLOCK) ON RC.RawMaterialID = RM.RawMaterialID
		LEFT JOIN DropDownValues					AS DDV WITH(NOLOCK) ON RM.HTSCodeID = DDV.DropDownValueID
		WHERE dateInventory = '2025-09-30'
		GROUP BY  --DateInventory 
			--	 ,StyleNumber
				-- ,StyleID
				DDV.DropDownValue
				,DDV.Description

		UNION ALL

		SELECT  
			ddv as HTSCode
			,ddvdes as HTSDescription
			,Units as UDM
			,SUM(OH) as Quantity
			,SUM(Cost) as Costo
			FROM(
							select 

										ddv.DropDownValue as ddv
										,ddv2.DropDownValue as ddv2
										,ddv.Description as ddvdes
										,ddv2.Description as ddv2des
										,left (ct.SAC + '0000000000', 10) as SAC 
										,ct.Category
										,ct.Units
										,sum (ct.[Container Unit Cost] * ct.[On Hand]) as cost
										,sum (ct.[On Hand]) as OH
											, CT.[Part Number] ,'INCIAL' as [Type]
			FROM (SELECT DISTINCT
				[Code]
				,[Category]
				,[Subcategory]
				,[Family]
				,[Inv Accounting]
				,[Part Number]
				,[Part Color]
				,[Status]
				,[Roll]
				,[PO Number]
				,[Description]
				,[Fabric Width]
				,[On Hand]
				,[Units]
				,[Bin]
				,[Warehouse]
				,[Dye Lot]
				,[Vendor Name]
				,[IM5/IM9]
				,[SAC]
				,[Technical Desc.]
				,[Invoice Number]
				,[Unit Symbol]
				,[Average Material Cost]
				,[Container Unit Cost]
				,[Unit Freight Cost]
				,[Total]
				,[Total With Freight]
				,[Deadline]
				,[Month]
				,[Counting]
				,[Fam]
				,[Acou]
				,[Fecha]
			FROM [AppsLCA].[dbo].[CostoWarehouse])ct
						left outer join Financial.dbo.RawMaterials on RawMaterials.PartNumber = ct.[Part Number]
			LEFT OUTER JOIN Financial.dbo.DropDownValues ddv ON RawMaterials.HTSCodeID = ddv.DropDownValueID
			left outer join Financial.dbo.DropDownValues ddv2 on ddv2.DropDownValue = left (ct.SAC + '0000000000', 10) and ddv.DropDownValue is null 

			where 
				-- Fecha = '2025-03-31'  --SALDO INICIAL
				Fecha = '2025-09-30'  --SALDO FINAL

				and ct.category<>'Expandable'
				and ct.category<>'Expendable'
			group by  CT.[Part Number],ddv.DropDownValue ,ct.Units,ddv.Description,ct.Category,left (ct.SAC + '0000000000', 10) ,ddv2.DropDownValue,ddv2.Description
							
			)TB
			WHERE Category <> 'Expendable'
			AND Category <> 'Contracts'
			AND ddv <> 'N/A'
			GROUP BY ddv,ddv2,ddvdes,ddv2des,Category,Units
				) AS TB_ALL		 
				GROUP BY
					HTSDescription
					,UDM
					,HTSCode
				ORDER BY HTSDescription

--------------------------------------------------- SALDO FINAL -------------------------------------------------------------

CREATE TABLE #TB_ALL
(
	 HTSDescription		VARCHAR(200)
	,UDM				VARCHAR(30)
	,HTSCode			VARCHAR(100)
	,SaldoInicial_Units	DECIMAL(15,2)
	,SaldoInicial_Total	DECIMAL(15,2)
	,Entradas_Units		DECIMAL(15,2)
	,Entradas_Total		DECIMAL(15,2)
	,Salidas_Units		DECIMAL(15,2)
	,Salidas_Total		DECIMAL(15,2)
	,SaldoFinal_Units	DECIMAL(15,2)
	,SaldoFinal_Total	DECIMAL(15,2)

)

INSERT INTO #TB_ALL
(
	 HTSDescription
	,UDM
	,HTSCode
	,SaldoInicial_Units
	,SaldoInicial_Total
)
SELECT 
	HTSDescription
	,UDM
	,HTSCode
	,ROUND(SaldoInicial_Units,2)
	,ROUND(SaldoInicial_Total,2)
FROM #TB_Inicial

INSERT INTO #TB_ALL
(
	 HTSDescription
	,UDM
	,HTSCode
	,SaldoInicial_Units
	,SaldoInicial_Total
)
SELECT 
	HTSDescription
	,UDM
	,HTSCode
	,0.00
	,0.00
FROM #TB_Entradas
WHERE CONCAT(HTSCode,HTSDescription,UDM) NOT IN (SELECT CONCAT(HTSCode,HTSDescription,UDM) FROM #TB_ALL)

INSERT INTO #TB_ALL
(
	 HTSDescription
	,UDM
	,HTSCode
	,SaldoInicial_Units
	,SaldoInicial_Total
)
SELECT 
	HTSDescription
	,UDM
	,HTSCode
	,0.00
	,0.00
FROM #TB_Salidas
WHERE CONCAT(HTSCode,HTSDescription,UDM) NOT IN (SELECT CONCAT(HTSCode,HTSDescription,UDM) FROM #TB_ALL)

INSERT INTO #TB_ALL
(
	 HTSDescription
	,UDM
	,HTSCode
	,SaldoInicial_Units
	,SaldoInicial_Total
)
SELECT 
	HTSDescription
	,UDM
	,HTSCode
	,0.00
	,0.00
FROM #TB_Final
WHERE CONCAT(HTSCode,HTSDescription,UDM) NOT IN (SELECT CONCAT(HTSCode,HTSDescription,UDM) FROM #TB_ALL)

UPDATE TA
	SET 
	 Entradas_Units 	= ROUND(ISNULL(TE.Entradas_Units,0.00),2)
	,Entradas_Total 	= ROUND(ISNULL(TE.Entradas_Total,0.00),2)
	,Salidas_Units  	= ROUND(ISNULL(TS.Salidas_Units,0.00),2)
	,Salidas_Total  	= ROUND(ISNULL(TS.Salidas_Total,0.00),2)
	,SaldoFinal_Units  	= ROUND(ISNULL(TF.SaldoFinal_Units,0.00),2)
	,SaldoFinal_Total  	= ROUND(ISNULL(TF.SaldoFinal_Total,0.00),2)

FROM #TB_ALL AS TA
LEFT JOIN #TB_Entradas 	AS TE ON TA.HTSCode = TE.HTSCode AND TA.HTSDescription = TE.HTSDescription AND TA.UDM = TE.UDM
LEFT JOIN #TB_Salidas  	AS TS ON TA.HTSCode = TS.HTSCode AND TA.HTSDescription = TS.HTSDescription AND TA.UDM = TS.UDM
LEFT JOIN #TB_Final  	AS TF ON TA.HTSCode = TF.HTSCode AND TA.HTSDescription = TF.HTSDescription AND TA.UDM = TF.UDM

SELECT * FROM #TB_ALL ORDER BY HTSDescription, HTSCode

SELECT * FROM #TB_Entradas where HTSCode = '6109100000'


SELECT sum(SaldoFinal_Units) FROM #TB_ALL
SELECT SUM(Quantity) FROM AppsLCA.dbo.TB_INVENTORY_WH_BND_CT_PACK	AS INV WITH(NOLOCK)
WHERE TypeQueryN <> 4 AND FilterSemi = 1
		and (FilterTakeUnits = 1 or (FilterTakeUnits = 0  and TypeQueryN <> 1))
		and dateInventory = '2025-09-30'
		
