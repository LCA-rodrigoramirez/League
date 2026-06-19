USE AppsLCA

DECLARE @data NVARCHAR(MAX)
 SET @data = '{
      "selectedOptions":[{"PO":"LCA22663"}]
    }'

DROP TABLE IF EXISTS #TempPOsContainers;
DROP TABLE IF EXISTS #TB_MOs;

SELECT
        [PO] = j.[PO]
INTO #TempPOsContainers
FROM OPENJSON(@data, '$.selectedOptions')
WITH (PO NVARCHAR(200) '$.PO') AS j;

SELECT 
     TPO.[PO]
    ,OD.[PONumber]
    ,MO.[ManufactureNumber]
    ,PB.[BoxNumber]
    ,PI.[Quantity]
    ,GB.[Bin]
FROM #TempPOsContainers                         AS TPO
LEFT  JOIN [LCA].[dbo].[Orders]                 AS OD  WITH(NOLOCK) ON OD.[PONumber] LIKE '%' + TPO.[PO] + '%'
INNER JOIN [LCA].[dbo].[ManufactureOrders]      AS MO  WITH(NOLOCK) ON MO.[OrderID] = OD.[OrderID]
INNER JOIN [LCA].[dbo].[PackedItems]            AS PI  WITH(NOLOCK) ON MO.[ManufactureID] = PI.[ManufactureID]
INNER JOIN [LCA].[dbo].[PackedBoxes]            AS PB  WITH(NOLOCK) ON PI.[PackedBoxID] = PB.[PackedBoxID] AND PB.[WarehouseID] IN (35,53,60)
LEFT  JOIN [LCA].[dbo].[GoodsBins]              AS GB  WITH(NOLOCK) ON PB.[GoodsBinID] = GB.[GoodsBinID]

SELECT
     TPO.[PO]
    ,OD.[PONumber]
    ,MO.[ManufactureNumber]
    ,MO.[ManufactureID]
INTO #TB_MOs
FROM #TempPOsContainers                         AS TPO
INNER JOIN [LCA].[dbo].[PurchaseOrders]         AS PO WITH(NOLOCK) ON PO.[PONumber] = TPO.[PO]
INNER JOIN [LCA].[dbo].[PurchaseDetails]        AS PD WITH(NOLOCK) ON PO.[PurchaseID] = PD.[PurchaseID]
INNER JOIN [LCA].[dbo].[RawContainers]          AS RC WITH(NOLOCK) ON RC.[PurchaseDetailID] = PD.[PurchaseDetailID]
INNER JOIN [LCA].[dbo].[ContainerTransfers]     AS CT WITH(NOLOCK) ON CT.[RawContainerID] = RC.[RawContainerID]
INNER JOIN [LCA].[dbo].[RawTransactions]        AS RT WITH(NOLOCK) ON RT.[RawTransactionID] = CT.[RawTransactionID]
INNER JOIN [LCA].[dbo].[ManufactureOrders]      AS MO WITH(NOLOCK) ON RT.[ManufactureID] = MO.[ManufactureID]
INNER JOIN [LCA].[dbo].[Orders]                 AS OD WITH(NOLOCK) ON MO.[OrderID] = OD.[OrderID]
GROUP BY
     TPO.[PO]
    ,OD.[PONumber]
    ,MO.[ManufactureNumber]
    ,MO.[ManufactureID]

SELECT
     TMO.[PO]
    ,TMO.[PONumber]
    ,TMO.[ManufactureNumber]
    ,TMO.[ManufactureID]
    ,PB.[BoxNumber]
    ,PI.[Quantity]
    ,GB.[Bin]
FROM #TB_MOs as TMO
INNER JOIN [LCA].[dbo].[PackedItems]            AS PI  WITH(NOLOCK) ON TMO.[ManufactureID] = PI.[ManufactureID]
INNER JOIN [LCA].[dbo].[PackedBoxes]            AS PB  WITH(NOLOCK) ON PI.[PackedBoxID] = PB.[PackedBoxID] AND PB.[WarehouseID] IN (35,53,60)
LEFT  JOIN [LCA].[dbo].[GoodsBins]              AS GB  WITH(NOLOCK) ON PB.[GoodsBinID] = GB.[GoodsBinID]