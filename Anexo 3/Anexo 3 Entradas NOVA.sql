use Financial
select 
tt.DropDownValue
,tt.Description
,sum(tt.Quantity) as Quantity
,sum(tt.[UnitCost * Quantity]) AS cost

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
			-- changedate,
      -- convert( varchar(10),changedate, 111) as conver 
    FROM ChangeLog 
    -- WHERE convert( varchar(10),changedate, 111) >= '2020-12-30'  and   convert( varchar(10),changedate, 111) <= '2021-06-30'
    -- WHERE changedate > '2021-01-30'  
    WHERE convert( varchar(10),changedate, 111) BETWEEN '2025/04/01'  AND '2025/06/30'
        
))

--and WHH.WarehouseName not in ('CMT Warehouse','Obsolete (liquidate)' ,'Quarentine')
--and RawTransactions.[RawTransactionID] <> '3144989' 
-- and Dictionary2.TranslatedText <> 'Expendable'
and Dictionary2.TranslatedText = 'Contracts'
and Dictionary2.TranslatedText <>'Expendable'
and RawContainers.ContainerCode <> '<Default>'
and EnumValues.Description in ('Receive','Receive Excess')--ENTRADAS
--AND NOT(PurchaseOrders.PONumber IN('FEL-72-1','FEL-96-1'))
-- and EnumValues.Description in ('adjust minus','adjust plus','MO Return','MO Withdraw')--SALIDAS
--and ddv.DropDownValue = '3212909000'
 )  as tt 

 group by 
tt.DropDownValue
,tt.Description
,tt.DatabaseUnits

order by DropDownValue
