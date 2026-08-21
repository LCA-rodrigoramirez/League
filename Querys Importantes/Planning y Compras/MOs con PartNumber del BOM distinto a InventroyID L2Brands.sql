


DROP TABLE IF EXISTS #TB_MO
DROP TABLE IF EXISTS #TB_PO_Details
DROP TABLE IF EXISTS #TempPOs
DROP TABLE IF EXISTS #TB_MO_FIL

DECLARE @data AS NVARCHAR(MAX) = '{
                                    "selectedOptions":[
                                        {"PONumber":"LCA23320"},
                                        {"PONumber":"LCA22858"},
                                        {"PONumber":"LCA23331"},
                                        {"PONumber":"LCA23069"},
                                        {"PONumber":"LCA23342"}
                                    ]
                                }'

SELECT
        [PO] = j.[PO]
INTO #TempPOs
FROM OPENJSON(@data, '$.selectedOptions')
WITH (PO NVARCHAR(200) '$.PONumber') AS j;

CREATE TABLE #TB_MO_FIL (
     [PO]                   VARCHAR(200)
    ,[PurchaseID]           INT
    ,[PONumber]             VARCHAR(200)
    ,[ManufactureNumber]    VARCHAR(200)
    ,[ManufactureID]        INT
)
INSERT INTO #TB_MO_FIL
SELECT
    TPO.[PO]
    ,PO.[PurchaseID]
    ,OD.[PONumber]
    ,MO.[ManufactureNumber]
    ,MO.[ManufactureID]
    --select *
FROM #TempPOs                                   AS TPO
INNER JOIN [LCA].[dbo].[PurchaseOrders]         AS PO   WITH(NOLOCK) ON TPO.[PO] = PO.[PONumber]
INNER JOIN [LCA].[dbo].[Orders]                 AS OD WITH(NOLOCK) ON OD.[PONumber] LIKE '%' + IIF(CHARINDEX('-',TPO.[PO]) > 0,SUBSTRING(TPO.[PO],1,CHARINDEX('-',TPO.[PO])-1),TPO.[PO]) + '%'
INNER JOIN [LCA].[dbo].[ManufactureOrders]      AS MO WITH(NOLOCK) ON OD.[OrderID] = MO.[OrderID] AND MO.[StatusID] < 90 --OR MO.ManufactureNumber = '23701-RVF400-632-3'
GROUP BY
    TPO.[PO]
    ,PO.[PurchaseID]
    ,OD.[PONumber]
    ,MO.[ManufactureNumber]
    ,MO.[ManufactureID]

SELECT
     [PO]               = TPO.[PO]
    ,[PurchaseID]       = PO.[PurchaseID]
    ,[PurchaseDetailID] = PD.[PurchaseDetailID]
    ,[PartNumber]       = RM.[PartNumber]
    ,[Style]            = CAST(NULL AS VARCHAR(100))
    ,[Color]            = CAST(NULL AS VARCHAR(100))
    ,[Size]             = CAST(NULL AS VARCHAR(100))
    ,[PartNumberL2]		= L2.[InvItemId]
INTO #TB_PO_Details
FROM #TempPOs                               AS TPO
INNER JOIN [LCA].[dbo].[PurchaseOrders]     AS PO   WITH(NOLOCK) ON TPO.[PO] = PO.[PONumber]
INNER JOIN [LCA].[dbo].[PurchaseDetails]    AS PD   WITH(NOLOCK) ON PO.[PurchaseID] = PD.[PurchaseID]
INNER JOIN [LCA].[dbo].[RawMaterials]       AS RM   WITH(NOLOCK) ON PD.[RawMaterialID] = RM.[RawMaterialID]
LEFT  JOIN AppsLCA.legacycaps.LCA_L2B_InventoryID AS L2 WITH(NOLOCK) ON RM.[PartNumber] = L2.[InvItemId]
WHERE L2.InvItemId IS NULL

UPDATE TPD SET
     [Style] = case when charindex('-',TPD.PartNumber)>0
											then substring( TPD.PartNumber ,1, charindex('-',TPD.PartNumber)-1)
										  else NULL end
    ,[Color] = case when CHARINDEX('-', TPD.PartNumber, CHARINDEX('-', TPD.PartNumber) + 1) > 0
											then	substring(TPD.PartNumber,charindex('-',TPD.PartNumber)+1,
				 									charindex('-',TPD.PartNumber,charindex('-',TPD.PartNumber)+1) -
													len(substring(TPD.PartNumber,1, charindex('-',TPD.PartNumber)-1)) -2) 
											else NULL
											end 
    ,[Size]  = SizeValue.[value]
FROM #TB_PO_Details AS TPD
LEFT JOIN (select  distinct * from (select  PurchaseDetailID,PartNumber, [value] 
																 from  (select PurchaseDetailID, PartNumber from #TB_PO_Details AS TPO
																) abc234
																cross apply string_split(PartNumber,'-')) abcrty
																where [value] in (
																'0X','1X','2T','2X','2XB','2XL','2XT','3T','3X','3XL','3XT','4T','4XB','4XL','4XT','5T','5XL','6T','3XB','6XL','7T',
																'8T','ADJ','L','L/XL','L_XL','LT','LXL','M','ML','ONE','QTY','S','S/M','S_M','SM','XL','XLT','XS','XXL','YDS'
																)
																--where [value] in ('L_XL','L/XL',
																-- '2XL','3XL','4XL','5XL','6XL','XXL','S_M','ADJ','S/M',
																-- 'XS','XL','2T','3T','4T','5T','6T','7T','8T',
																--'S','M','L')
													) SizeValue ON TPD.[PurchaseDetailID] = SizeValue.[PurchaseDetailID]

UPDATE TPD SET
	PartNumberL2 = L2.[InvItemId]
FROM #TB_PO_Details AS TPD
LEFT  JOIN AppsLCA.legacycaps.LCA_L2B_InventoryID AS L2 WITH(NOLOCK) ON TPD.[Style] = L2.[Style] AND TPD.[Color] = L2.[Color] AND TPD.[Size] = L2.[GarmentSize]


SELECT
     PO                 = FIL_MO.PO
    ,PurchaseID         = FIL_MO.PurchaseID
	,MO					= MO.ManufactureNumber
	,StatusMO			= SN.StatusName
	,Style				= ST.StyleNumber
	,Color				= SC.StyleColorName
	,Size				= FG.GarmentSize
	,PartNumberMO		= RM.PartNumber
	,SeasonName			= SE.SeasonName
	,PartNumberL2		= L2.InvItemId
	,ProductionComments = MO.Comments2
INTO #TB_MO
FROM #TB_MO_FIL                         AS FIL_MO
INNER JOIN LCA.dbo.ManufactureOrders	AS MO WITH(NOLOCK) ON MO.ManufactureID = FIL_MO.[ManufactureID]
INNER JOIN LCA.dbo.StatusNames	        AS SN WITH(NOLOCK) ON MO.StatusID = SN.StatusID
INNER JOIN LCA.dbo.ManufactureDetails	AS MD WITH(NOLOCK) ON MD.ManufactureID = MO.ManufactureID AND MD.QuantityOrdered > 0
INNER JOIN LCA.dbo.OrderItems			AS OI WITH(NOLOCK) ON MO.FirstOrderItemID = OI.OrderItemID
INNER JOIN LCA.dbo.Styles				AS ST WITH(NOLOCK) ON OI.StyleID = ST.StyleID AND ST.Comments9 = 'Headwear'
INNER JOIN LCA.dbo.StyleColors			AS SC WITH(NOLOCK) ON OI.StyleColorID = SC.StyleColorID
INNER JOIN LCA.dbo.FinishedGoods		AS FG WITH(NOLOCK) ON MD.FinishedGoodsID = FG.FinishedGoodsID
INNER JOIN LCA.dbo.Seasons				AS SE WITH(NOLOCK) ON ST.SeasonID = SE.SeasonID AND SeasonName = 'BLANK FG'
LEFT  JOIN LCA.dbo.RawAllocations		AS RA WITH(NOLOCK) ON MO.ManufactureID = RA.ManufactureID
LEFT  JOIN LCA.dbo.RawMaterials			AS RM WITH(NOLOCK) ON RA.RawMaterialID = RM.RawMaterialID
LEFT  JOIN AppsLCA.legacycaps.LCA_L2B_InventoryID AS L2 WITH(NOLOCK) ON RM.PartNumber = L2.InvItemId
WHERE L2.InvItemId IS NULL 

UPDATE TM SET
	PartNumberL2 = L2.InvItemId
FROM #TB_MO AS TM
LEFT  JOIN AppsLCA.legacycaps.LCA_L2B_InventoryID AS L2 WITH(NOLOCK) ON TM.Style = L2.Style AND TM.Color = L2.Color AND TM.Size = L2.GarmentSize

SELECT 
        PO
        ,[PartNumberPO] = PartNumber
        ,[PartNumberL2]
        ,[Style]
        ,[Color]
        ,[Size] 
from #TB_PO_Details

select 
    PO
    ,[MO]
    ,[StatusMO]
    ,[PartNumberMO]
    ,[PartNumberL2]
    ,[Style]
    ,[Color]
    ,[Size]
    ,[SeasonName]
    ,[ProductionComments] 
from #TB_MO
RETURN

SELECT
* 
,ROW_NUMBER() OVER(PARTITION BY MO ORDER BY MO) AS Rep
,CASE 
	WHEN MO LIKE '23958%' OR MO LIKE '24865%' OR MO LIKE '23042%' THEN 1
	WHEN ProductionComments IS NOT NULL THEN 2
	ELSE 3
	END AS Ord
FROM #TB_MO
ORDER BY Ord