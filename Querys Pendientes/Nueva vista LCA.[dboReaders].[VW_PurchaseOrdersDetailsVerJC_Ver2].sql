USE [LCA]
GO

/****** Object:  View [dboReaders].[VW_PurchaseOrdersDetailsVerJC_Ver2]    Script Date: 27/05/2026 07:15:28 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/****** Object:  View [dboReaders].[VW_RawContainers_GreigeItems]    Script Date: 2/29/2024 8:58:42 AM ******/
ALTER view [dboReaders].[VW_PurchaseOrdersDetailsVerJC_Ver2]
as


SELECT TOP 100 PERCENT
     [Code]                     = RC.[ContainerCode]
    ,[Category]                 = CC.[CategoryName]
    ,[SubCategoryName]          = CS.[SubCategoryName]
    ,[OrderDate]                = PO.[OrderDate]     
    ,[OriginalScheduleDate]     = PO.[OriginalScheduleDate]
    ,[CancelDate]               = PO.[CancelDate]
    ,[ScheduledShipDate]        = PO.[ScheduledShipDate]
    ,[PartNumber]               = RM.[PartNumber]
    ,[PartColor]                = C.[ColorName]
    ,[StatusName]               = SN.[StatusName]
    ,[RollNumber]               = RC.[RollNumber]
    ,[PONumber]                 = PO.[PONumber]
    ,[Description]              = RM.[Description]
    ,[Fabric Width]             = RC.[FabricWidth]
    ,[On Hand]                  = RC.[QuantityOnHand]
    ,[Units]                    = UN.[UnitName]
    ,[Bin]                      = RB.[Bin]
    ,[Warehouse]                = WH.[WarehouseName]
    ,[ComponentName]            = CL.[ComponentName]
    ,[IM5/IM9]                  = RS.[WayBill]
    ,[SAC]                      = RC.[Label]
    ,[Technical Desc.]          = RC.[Comments3]
    ,[Average Material Cost]    = RM.[AverageUnitCost]
    ,[Container Unit Cost]      = RC.[AverageUnitCost]
    ,[Unit Freight Cost]        = RC.[UnitFreightCost]
    ,[FabricWidth_Component]    = CL.[FabricWidth]
    ,[ColorDescription]         = C.[ColorDescription]
    ,[ShipNumber]               = RS.[ShipNumber]
    ,[RawMaterialID]            = RM.[RawMaterialID]
FROM (SELECT StatusID, StatusName FROM [LCA].[dbo].[StatusNames] AS SN WITH(NOLOCK) WHERE StatusID IN (7, 30, 105)) AS SN -- StatusID IN (7, 30, 58, 105, 113)
INNER JOIN [LCA].[dbo].[RawContainers]          AS RC WITH(NOLOCK) ON SN.[StatusID] = RC.[StatusID] AND RC.[ContainerCode] NOT IN ('<Default>')
LEFT  JOIN [LCA].[dbo].[RawMaterials]           AS RM WITH(NOLOCK) ON RC.[RawMaterialID] = RM.[RawMaterialID]
LEFT  JOIN [LCA].[dbo].[ComponentLibrary]       AS CL WITH(NOLOCK) ON RM.[ComponentID] = CL.[ComponentID]
LEFT  JOIN [LCA].[dbo].[ComponentCategories]    AS CC WITH(NOLOCK) ON CL.[ComponentCategoryID] = CC.[ComponentCategoryID]
LEFT  JOIN [LCA].[dbo].[ComponentSubcategories] AS CS WITH(NOLOCK) ON CL.[SubCategoryID] = CS.[SubCategoryID]
LEFT  JOIN [LCA].[dbo].[UnitNames]              AS UN WITH(NOLOCK) ON UN.[UnitNameID] = CL.[DatabaseUnitID]
LEFT  JOIN [LCA].[dbo].[Colors]                 AS C  WITH(NOLOCK) ON RM.[ColorID] = C.[ColorID]
LEFT  JOIN [LCA].[dbo].[RawBins]                AS RB WITH(NOLOCK) ON RC.[RawBinID] = RB.[RawBinID]
LEFT  JOIN [LCA].[dbo].[Warehouses]             AS WH WITH(NOLOCK) ON RC.[StockWarehouseID] = WH.[WarehouseID]
LEFT  JOIN [LCA].[dbo].[ReceiveSlips]           AS RS WITH(NOLOCK) ON RC.[ReceiveID] = RS.[ReceiveID]
LEFT  JOIN [LCA].[dbo].[Addresses]              AS VD WITH(NOLOCK) ON RS.[VendorID] = VD.[AddressID]
LEFT  JOIN [LCA].[dbo].[PurchaseDetails]        AS PD WITH(NOLOCK) ON RC.[PurchaseDetailID] = PD.[PurchaseDetailID]
LEFT  JOIN [LCA].[dbo].[PurchaseOrders]         AS PO WITH(NOLOCK) ON PD.[PurchaseID] = PO.[PurchaseID]

WHERE SN.[StatusID] IN (7,30) OR PO.[PONumber] = 'LCA23015'

ORDER BY [Code]
--and RawContainers.ContainerCode = 'PPRC1163193'


GO


