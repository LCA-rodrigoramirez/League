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

	SELECT DISTINCT
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
			,HTSCode		= DDV.DropDownValue
			,HTSDescription	= DDV.Description
			,Quantity 
			,Costo			= ROUND(Contracts+[Trim]+[Supplies],4)
		INTO #TB_Pre_Inventory_INI
		FROM AppsLCA.dbo.TB_INVENTORY_WH_BND_CT_PACK	AS INV WITH(NOLOCK)
		LEFT JOIN Styles								AS ST  WITH(NOLOCK) ON INV.StyleID = ST.StyleID
		LEFT JOIN Styles								AS BS  WITH(NOLOCK) ON ST.BlankStyleID = BS.StyleID
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON INV.ManufactureID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-',INV.Size) = lpmW.PartNumber AND lpmW.UnitCost IS NOT NULL
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW2 WITH (NOLOCK) ON INV.ManufactureID = lpmW2.ManufactureID AND lpmW2.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-F-',INV.Size) = lpmW2.PartNumber AND lpmW2.UnitCost IS NOT NULL
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW3 WITH (NOLOCK) ON INV.ManufactureID = lpmW3.ManufactureID AND lpmW3.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-U-',INV.Size) = lpmW3.PartNumber AND lpmW3.UnitCost IS NOT NULL
		LEFT JOIN RawMaterials RM WITH (NOLOCK) ON ISNULL(ISNULL(lpmW.RawMaterialID,lpmw2.RawMaterialID),lpmw3.RawMaterialID) = RM.RawMaterialID
		LEFT JOIN DropDownValues						AS DDV WITH(NOLOCK) ON RM.HTSCodeID	= DDV.DropDownValueID

		WHERE TypeQueryN <> 4 AND FilterSemi = 1
		and (FilterTakeUnits = 1 or (FilterTakeUnits = 0  and TypeQueryN <> 1))
		and dateInventory = '2025-03-31' 

	-- select * from #tb_pre_Inventory_INI
	-- return

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
			SELECT DISTINCT
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
				,Style
				,Color
				,Size
				,BoxNumber
				,Quantity
				,TB1.ManufactureID
				,MO
				,Costo
			FROM #TB_Pre_Inventory_INI AS TB1
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
		WHERE dateInventory = '2025-03-31'
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
			Fecha = '2025-03-31'  --SALDO INICIAL
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

									ddv.DropDownValue,
									ddv.Description,
									RawTransactions.RawTransactionID AS RawTransactionID,
									
									Orders.OrderID                                       AS orderID,
									Orders.PONumber                                      AS PONumber,
									RawTransactions.ManufactureID AS ManufactureID,
					ManufactureOrders.ManufactureNumber AS ManufactureNumber,
		--               ManufactureOrders.StockAccountID AS MfgStockAccountID,
		--             ManufactureOrders.StatusID AS MOStatusID,
					styles.StyleID AS StyleID,
								Styles.StyleNumber AS StyleNumber,
								Seasons.SeasonName      AS SeasonName,
			--           RawTransactions.PurchaseDetailID AS PurchaseDetailID,
					PurchaseOrders.PONumber AS PONumber_Purchase,
					PurchaseDetails.QuantityOrdered AS QuantityOrdered,
					Addresses.CompanyNumber AS VendorNumber,
					Addresses.#CompanyNumber AS #VendorNumber,
					ReceiveSlips.ShipNumber AS ReceiveNumber,
			--         RawTransactions.ReceiveID AS ReceiveID,
					ReceiveSlips.InvoiceNumber AS InvoiceNumber,
					RawMaterials.PartNumber AS PartNumber,
				--       RawTransactions.RawMaterialID AS RawMaterialID,
					Colors.ColorName AS PartColor,
					RawMaterials.ComponentID AS ComponentID,
					Dictionary2.TranslatedText AS CategoryName,
					ComponentCategories.#CategoryName AS #CategoryName,
					ComponentSubcategories.SubcategoryName AS SubcategoryName,
					ComponentSubcategories.#SubcategoryName AS #SubcategoryName,
					IsNull(RawMaterials.Description, '')+' '+IsNull(Colors.ColorName, '')+' '+IsNull(FabricUsage.FabricUsageName, '')+' '+IsNull(ComponentLibrary.FabricWeight, '')+' '+IsNull(ComponentLibrary.FabricWidth, '') AS PartSummary,
				--     RawMaterials.DefaultContainerID AS DefaultContainerID,
					Dictionary3.TranslatedText AS DatabaseUnits,
					Dictionary4.TranslatedText AS DatabaseUnitSymbol,
					--  ManufactureOrders3.StatusID AS CutStatusID,
					--   RawTransactions.CutOrderID AS CutOrderID,
					--  RawTransactions.ManufactureSourceID AS ManufactureSourceID,
					RawTransactions.Quantity AS QuantitySubtotal,
					RawTransactions.UserTransactionDate AS UserTransactionDate,
					DropDownValues32.DropDownValue AS TransactionReason,
					--  RawTransactions.TransactionReasonID AS TransactionReasonID,
					RawTransactions.UnitCost AS UnitCost,
					RawTransactions.IsReturn AS IsReturn,
					EnumValues.Description AS TransactionTypeName,
					--RawTransactions.RawTransactionTypeID AS RawTransactionTypeID,
					RawTransactions.GroupCode AS SetGroupCode,
					LTRIM(STR(IsNull(GroupCode, RawTransactions.ChangeLogID)+1000000)) AS TransactionGroupCode,
					ChangeLog.ChangeDate AS TransactionDate,
					--RawTransactions.ChangeLogID AS ChangeLogID,
					Users.UserName AS UserName,
					ChangeLog.ACTION AS ACTION,
					ChangeLog.Comment AS Comment,
					--ContainerTransfers.RawContainerID AS RawContainerID,
					RawContainers.ContainerCode AS ContainerCode,
					RawContainers.Label AS Label,
					RawContainers.DyeLot AS DyeLot,
					RawContainers.Comments3 AS Comments3,
					--RawContainers.QALotID AS QALotID,
					IsNull(RawContainers.ReceiveDate, ReceiveSlips.ReceiveDate) AS ReceiveDate,
					RawContainers.InitialReceived AS InitialReceived,
					RawContainers.UnitFreightCost AS UnitFreightCost,
					ContainerTransfers.Quantity AS Quantity,
					ReceiveSlips2.WayBill AS OrigReceiveWayBill,
					Addresses4.CompanyName AS OrigVendorName,
					ContainerTransfers.InternalKey AS InternalKey,
					ManufactureOrders5.ManufactureNumber AS ManufactureGroup_,
					ReceiveSlips.WayBill AS WayBill_
								,RawContainers.UnitFreightCost * ContainerTransfers.Quantity as [UnitFreightCost * Quantity]
								,RawTransactions.UnitCost * ContainerTransfers.Quantity as [UnitCost * Quantity]
	FROM RawTransactions
		LEFT OUTER JOIN ManufactureOrders
		LEFT OUTER JOIN OrderItems
		LEFT OUTER JOIN Styles ON OrderItems.StyleID = Styles.StyleID ON ManufactureOrders.FirstOrderItemID = OrderItems.OrderItemID
		LEFT OUTER JOIN ManufactureOrders AS ManufactureOrders5 ON ManufactureOrders.ManufactureGroupID = ManufactureOrders5.ManufactureID ON RawTransactions.ManufactureID = ManufactureOrders.ManufactureID
		LEFT OUTER JOIN PurchaseDetails
		LEFT OUTER JOIN PurchaseOrders
		LEFT OUTER JOIN Addresses ON PurchaseOrders.VendorID = Addresses.AddressID ON PurchaseDetails.PurchaseID = PurchaseOrders.PurchaseID ON RawTransactions.PurchaseDetailID = PurchaseDetails.PurchaseDetailID
		LEFT OUTER JOIN ReceiveSlips ON RawTransactions.ReceiveID = ReceiveSlips.ReceiveID
		LEFT OUTER JOIN RawMaterials
		LEFT OUTER JOIN Colors ON RawMaterials.ColorID = Colors.ColorID
		LEFT OUTER JOIN ComponentLibrary
		LEFT OUTER JOIN ComponentCategories
		LEFT OUTER JOIN Dictionary AS Dictionary2 ON ComponentCategories.CategoryName = Dictionary2.OriginalText
													AND Dictionary2.MessageSource = 'ComponentCategories'
													AND Dictionary2.LanguageID = 1 ON ComponentLibrary.ComponentCategoryID = ComponentCategories.ComponentCategoryID
		LEFT OUTER JOIN ComponentSubcategories ON ComponentLibrary.SubcategoryID = ComponentSubcategories.SubcategoryID
		LEFT OUTER JOIN FabricUsage ON ComponentLibrary.FabricUsageID = FabricUsage.FabricUsageID
		LEFT OUTER JOIN UnitNames
		LEFT OUTER JOIN Dictionary AS Dictionary3 ON UnitNames.UnitName = Dictionary3.OriginalText
													AND Dictionary3.MessageSource = 'UnitNames'
													AND Dictionary3.LanguageID = 1
		LEFT OUTER JOIN Dictionary AS Dictionary4 ON UnitNames.UnitSymbol = Dictionary4.OriginalText
													AND Dictionary4.MessageSource = 'UnitNames'
													AND Dictionary4.LanguageID = 1 ON ComponentLibrary.DatabaseUnitID = UnitNames.UnitNameID ON RawMaterials.ComponentID = ComponentLibrary.ComponentID ON RawTransactions.RawMaterialID = RawMaterials.RawMaterialID
		LEFT OUTER JOIN ManufactureOrders AS ManufactureOrders3 ON RawTransactions.CutOrderID = ManufactureOrders3.ManufactureID
		LEFT OUTER JOIN DropDownValues3 AS DropDownValues32 ON RawTransactions.TransactionReasonID = DropDownValues32.DropDownValueID
		LEFT OUTER JOIN EnumValues ON RawTransactions.RawTransactionTypeID = EnumValues.EnumValueID
		LEFT OUTER JOIN ChangeLog
		LEFT OUTER JOIN Users ON ChangeLog.UserID = Users.UserID ON RawTransactions.ChangeLogID = ChangeLog.ChangeLogID
		LEFT OUTER JOIN ContainerTransfers
		LEFT OUTER JOIN RawContainers
		LEFT OUTER JOIN ReceiveSlips AS ReceiveSlips2
		LEFT OUTER JOIN Addresses AS Addresses4 ON ReceiveSlips2.VendorID = Addresses4.AddressID ON RawContainers.ReceiveID = ReceiveSlips2.ReceiveID ON ContainerTransfers.RawContainerID = RawContainers.RawContainerID ON RawTransactions.RawTransactionID = ContainerTransfers.RawTransactionID
		LEFT OUTER JOIN Seasons as Seasons on Seasons.SeasonID = styles.SeasonID
		LEFT OUTER JOIN Orders as orders on orders.orderID = OrderItems.OrderID
		LEFT OUTER JOIN [dbo].DropDownValues ddv ON RawMaterials.HTSCodeID = ddv.DropDownValueID
		--LEFT OUTER JOIN warehouses as WHH on WHH.WarehouseID = RawTransactions.StockWarehouseID

	WHERE


	(RawTransactions.ChangeLogID IN
	(
		SELECT ChangeLogID
		FROM ChangeLog 
		WHERE convert( varchar(10),changedate, 111) BETWEEN '2025/04/01'  AND '2025/06/30'
			
	))

	-- and Dictionary2.TranslatedText = 'Contracts'
	and Dictionary2.TranslatedText <>'Expendable'
	and RawContainers.ContainerCode <> '<Default>'
	and EnumValues.Description in ('Receive','Receive Excess')--ENTRADAS
	and ddv.DropDownValue <> 'N/A'

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
		and DateAnexo = '2025-04-01'
		
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

											ddv.DropDownValue,
											ddv.Description,
											RawTransactions.RawTransactionID AS RawTransactionID,
											
											Orders.OrderID                                       AS orderID,
											Orders.PONumber                                      AS PONumber,
											RawTransactions.ManufactureID AS ManufactureID,
							ManufactureOrders.ManufactureNumber AS ManufactureNumber,
				--               ManufactureOrders.StockAccountID AS MfgStockAccountID,
				--             ManufactureOrders.StatusID AS MOStatusID,
							styles.StyleID AS StyleID,
										Styles.StyleNumber AS StyleNumber,
										Seasons.SeasonName      AS SeasonName,
					--           RawTransactions.PurchaseDetailID AS PurchaseDetailID,
							PurchaseOrders.PONumber AS PONumber_Purchase,
							PurchaseDetails.QuantityOrdered AS QuantityOrdered,
							Addresses.CompanyNumber AS VendorNumber,
							Addresses.#CompanyNumber AS #VendorNumber,
							ReceiveSlips.ShipNumber AS ReceiveNumber,
					--         RawTransactions.ReceiveID AS ReceiveID,
							ReceiveSlips.InvoiceNumber AS InvoiceNumber,
							RawMaterials.PartNumber AS PartNumber,
						--       RawTransactions.RawMaterialID AS RawMaterialID,
							Colors.ColorName AS PartColor,
							RawMaterials.ComponentID AS ComponentID,
							Dictionary2.TranslatedText AS CategoryName,
							ComponentCategories.#CategoryName AS #CategoryName,
							ComponentSubcategories.SubcategoryName AS SubcategoryName,
							ComponentSubcategories.#SubcategoryName AS #SubcategoryName,
							IsNull(RawMaterials.Description, '')+' '+IsNull(Colors.ColorName, '')+' '+IsNull(FabricUsage.FabricUsageName, '')+' '+IsNull(ComponentLibrary.FabricWeight, '')+' '+IsNull(ComponentLibrary.FabricWidth, '') AS PartSummary,
						--     RawMaterials.DefaultContainerID AS DefaultContainerID,
							Dictionary3.TranslatedText AS DatabaseUnits,
							Dictionary4.TranslatedText AS DatabaseUnitSymbol,
							--  ManufactureOrders3.StatusID AS CutStatusID,
							--   RawTransactions.CutOrderID AS CutOrderID,
							--  RawTransactions.ManufactureSourceID AS ManufactureSourceID,
							RawTransactions.Quantity AS QuantitySubtotal,
							RawTransactions.UserTransactionDate AS UserTransactionDate,
							DropDownValues32.DropDownValue AS TransactionReason,
							--  RawTransactions.TransactionReasonID AS TransactionReasonID,
							RawTransactions.UnitCost AS UnitCost,
							RawTransactions.IsReturn AS IsReturn,
							EnumValues.Description AS TransactionTypeName,
							--RawTransactions.RawTransactionTypeID AS RawTransactionTypeID,
							RawTransactions.GroupCode AS SetGroupCode,
							LTRIM(STR(IsNull(GroupCode, RawTransactions.ChangeLogID)+1000000)) AS TransactionGroupCode,
							ChangeLog.ChangeDate AS TransactionDate,
							--RawTransactions.ChangeLogID AS ChangeLogID,
							Users.UserName AS UserName,
							ChangeLog.ACTION AS ACTION,
							ChangeLog.Comment AS Comment,
							--ContainerTransfers.RawContainerID AS RawContainerID,
							RawContainers.ContainerCode AS ContainerCode,
							RawContainers.Label AS Label,
							RawContainers.DyeLot AS DyeLot,
							RawContainers.Comments3 AS Comments3,
							--RawContainers.QALotID AS QALotID,
							IsNull(RawContainers.ReceiveDate, ReceiveSlips.ReceiveDate) AS ReceiveDate,
							RawContainers.InitialReceived AS InitialReceived,
							RawContainers.UnitFreightCost AS UnitFreightCost,
							ContainerTransfers.Quantity AS Quantity,
							ReceiveSlips2.WayBill AS OrigReceiveWayBill,
							Addresses4.CompanyName AS OrigVendorName,
							ContainerTransfers.InternalKey AS InternalKey,
							ManufactureOrders5.ManufactureNumber AS ManufactureGroup_,
							ReceiveSlips.WayBill AS WayBill_
										,RawContainers.UnitFreightCost * ContainerTransfers.Quantity as [UnitFreightCost * Quantity]
										,RawTransactions.UnitCost * ContainerTransfers.Quantity as [UnitCost * Quantity]
			FROM RawTransactions
				LEFT OUTER JOIN ManufactureOrders
				LEFT OUTER JOIN OrderItems
				LEFT OUTER JOIN Styles ON OrderItems.StyleID = Styles.StyleID ON ManufactureOrders.FirstOrderItemID = OrderItems.OrderItemID
				LEFT OUTER JOIN ManufactureOrders AS ManufactureOrders5 ON ManufactureOrders.ManufactureGroupID = ManufactureOrders5.ManufactureID ON RawTransactions.ManufactureID = ManufactureOrders.ManufactureID
				LEFT OUTER JOIN PurchaseDetails
				LEFT OUTER JOIN PurchaseOrders
				LEFT OUTER JOIN Addresses ON PurchaseOrders.VendorID = Addresses.AddressID ON PurchaseDetails.PurchaseID = PurchaseOrders.PurchaseID ON RawTransactions.PurchaseDetailID = PurchaseDetails.PurchaseDetailID
				LEFT OUTER JOIN ReceiveSlips ON RawTransactions.ReceiveID = ReceiveSlips.ReceiveID
				LEFT OUTER JOIN RawMaterials
				LEFT OUTER JOIN Colors ON RawMaterials.ColorID = Colors.ColorID
				LEFT OUTER JOIN ComponentLibrary
				LEFT OUTER JOIN ComponentCategories
				LEFT OUTER JOIN Dictionary AS Dictionary2 ON ComponentCategories.CategoryName = Dictionary2.OriginalText
															AND Dictionary2.MessageSource = 'ComponentCategories'
															AND Dictionary2.LanguageID = 1 ON ComponentLibrary.ComponentCategoryID = ComponentCategories.ComponentCategoryID
				LEFT OUTER JOIN ComponentSubcategories ON ComponentLibrary.SubcategoryID = ComponentSubcategories.SubcategoryID
				LEFT OUTER JOIN FabricUsage ON ComponentLibrary.FabricUsageID = FabricUsage.FabricUsageID
				LEFT OUTER JOIN UnitNames
				LEFT OUTER JOIN Dictionary AS Dictionary3 ON UnitNames.UnitName = Dictionary3.OriginalText
															AND Dictionary3.MessageSource = 'UnitNames'
															AND Dictionary3.LanguageID = 1
				LEFT OUTER JOIN Dictionary AS Dictionary4 ON UnitNames.UnitSymbol = Dictionary4.OriginalText
															AND Dictionary4.MessageSource = 'UnitNames'
															AND Dictionary4.LanguageID = 1 ON ComponentLibrary.DatabaseUnitID = UnitNames.UnitNameID ON RawMaterials.ComponentID = ComponentLibrary.ComponentID ON RawTransactions.RawMaterialID = RawMaterials.RawMaterialID
				LEFT OUTER JOIN ManufactureOrders AS ManufactureOrders3 ON RawTransactions.CutOrderID = ManufactureOrders3.ManufactureID
				LEFT OUTER JOIN DropDownValues3 AS DropDownValues32 ON RawTransactions.TransactionReasonID = DropDownValues32.DropDownValueID
				LEFT OUTER JOIN EnumValues ON RawTransactions.RawTransactionTypeID = EnumValues.EnumValueID
				LEFT OUTER JOIN ChangeLog
				LEFT OUTER JOIN Users ON ChangeLog.UserID = Users.UserID ON RawTransactions.ChangeLogID = ChangeLog.ChangeLogID
				LEFT OUTER JOIN ContainerTransfers
				LEFT OUTER JOIN RawContainers
				LEFT OUTER JOIN ReceiveSlips AS ReceiveSlips2
				LEFT OUTER JOIN Addresses AS Addresses4 ON ReceiveSlips2.VendorID = Addresses4.AddressID ON RawContainers.ReceiveID = ReceiveSlips2.ReceiveID ON ContainerTransfers.RawContainerID = RawContainers.RawContainerID ON RawTransactions.RawTransactionID = ContainerTransfers.RawTransactionID
				LEFT OUTER JOIN Seasons as Seasons on Seasons.SeasonID = styles.SeasonID
				LEFT OUTER JOIN Orders as orders on orders.orderID = OrderItems.OrderID
				LEFT OUTER JOIN [dbo].DropDownValues ddv ON RawMaterials.HTSCodeID = ddv.DropDownValueID
				--LEFT OUTER JOIN warehouses as WHH on WHH.WarehouseID = RawTransactions.StockWarehouseID

			WHERE


			(RawTransactions.ChangeLogID IN
			(
				SELECT ChangeLogID
				FROM ChangeLog 
				WHERE convert( varchar(10),changedate, 111) BETWEEN '2025/04/01'  AND '2025/06/30'
					
			))

			and Dictionary2.TranslatedText <> 'Contracts'
			and Dictionary2.TranslatedText <>'Expendable'
			and RawContainers.ContainerCode <> '<Default>'
			and EnumValues.Description in ('adjust minus','adjust plus','MO Return','MO Withdraw')--SALIDAS
			and ddv.DropDownValue <> 'N/A'

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
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW WITH (NOLOCK) ON INV.ManufactureID = lpmW.ManufactureID AND lpmW.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-',INV.Size) = lpmW.PartNumber AND lpmW.UnitCost IS NOT NULL
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW2 WITH (NOLOCK) ON INV.ManufactureID = lpmW2.ManufactureID AND lpmW2.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-F-',INV.Size) = lpmW2.PartNumber AND lpmW2.UnitCost IS NOT NULL
		LEFT JOIN LCA.dbo.lpmWithdrawals_Ver3 lpmW3 WITH (NOLOCK) ON INV.ManufactureID = lpmW3.ManufactureID AND lpmW3.CategoryName = 'Contracts' AND CONCAT(INV.Style+'-',INV.Color+'-U-',INV.Size) = lpmW3.PartNumber AND lpmW3.UnitCost IS NOT NULL
		LEFT JOIN RawMaterials RM WITH (NOLOCK) ON ISNULL(ISNULL(lpmW.RawMaterialID,lpmw2.RawMaterialID),lpmw3.RawMaterialID) = RM.RawMaterialID
		LEFT JOIN DropDownValues						AS DDV WITH(NOLOCK) ON RM.HTSCodeID	= DDV.DropDownValueID

		WHERE TypeQueryN <> 4 AND FilterSemi = 1
		and (FilterTakeUnits = 1 or (FilterTakeUnits = 0  and TypeQueryN <> 1))
		and dateInventory = '2025-06-30' 


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
		WHERE dateInventory = '2025-06-30'
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
				Fecha = '2025-06-30'  --SALDO FINAL

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

