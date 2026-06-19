DROP TABLE IF EXISTS #TB_Orders_Prepress

SELECT
	MO.ManufactureID
	,MO.ManufactureNumber
	,OD.PONumber
	,MO.Comments7
	,GETDATE() AS StartDate
	,GETDATE() AS FinishDate
	,CAST(NULL AS INT) AS ScreensMO
	,IIF(A.Prepress_SequenceTasks_ID = 4,ISNULL(MO.Numeric2,0),NULL) AS ScreensByLocation
	,A.Prepress_SequenceTasks_ID
	,IIF(A.Prepress_SequenceTasks_ID = 4, MO.Numeric1, NULL) AS Bin
INTO #TB_Orders_Prepress
FROM LCA.dbo.ManufactureOrders AS MO WITH(NOLOCK)
INNER JOIN LCA.dbo.Orders AS OD WITH(NOLOCK) ON MO.OrderID = OD.OrderID
CROSS APPLY (SELECT ID AS Prepress_SequenceTasks_ID FROM AppsLCA.dbo.TB_Prepress_SequenceTasks WHERE ID < 5) AS A
WHERE MO.Comments30 IS NOT NULL

UPDATE #TB_Orders_Prepress
SET ScreensMO = (
	SELECT SUM(CAST(SUBSTRING(str, pos, 1) AS INT))
	FROM (VALUES (CAST(ScreensByLocation AS VARCHAR(10)))) AS t(str)
	CROSS JOIN (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) AS positions(pos)
	WHERE positions.pos <= LEN(str) AND ScreensByLocation IS NOT NULL
)

SELECT 
    ManufactureID
    ,ManufactureNumber
    ,SUBSTRING(PONumber,5,LEN(PONumber))
    ,Comments7
    ,StartDate
    ,FinishDate
    ,ScreensMO
    ,Prepress_SequenceTasks_ID
    ,Bin
    ,GETDATE()
FROM #TB_Orders_Prepress

SELECT * FROM AppsLCA.dbo.TB_Prepress_OrdersScanned