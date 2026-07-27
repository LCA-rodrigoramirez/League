DROP TABLE IF EXISTS #TB_Transfer_Kardex_For_RO_ID
DROP TABLE IF EXISTS #TB_Transfer_Kardex
drop table if exists #doble_im_ro


SELECT
MO
into #doble_im_ro
FROM
(
    SELECT
    *
    ,ROW_NUMBER() OVER(PARTITION BY MO ORDER BY MO) as R

    FROM
    (
    SELECT
    IM5
    ,MO
    FROM AppsLCA.dbo.TB_Transfer_Import_Duty WITH(NOLOCK)
    GROUP BY
    IM5
    ,MO
    ) AS A
) AS B
WHERE B.R > 1

SELECT 
     K.IDExport
    ,K.IDImport
    ,K.IDKardex
    ,QtyExport  = K.QtyExport
    ,k.RO_ID
INTO #TB_Transfer_Kardex_For_RO_ID
FROM [AppsLCA].[dbo].[TB_Transfer_Kardex_Duty] AS K WITH(NOLOCK)
-- WHERE K.Waybill = @WayBill
-- and k.IDKardex = 36156


;WITH CTE_Import_Distinct AS (
    SELECT 
         I.ManufactureID
        ,I.IM5
        ,ID= MAX(I.ID)
    FROM [AppsLCA].[dbo].[TB_Transfer_Import_Duty] AS I WITH(NOLOCK)
    INNER JOIN #TB_Transfer_Kardex_For_RO_ID AS K ON K.RO_ID = I.ManufactureID
    GROUP BY 
     I.ManufactureID
        ,I.IM5
),
CTE_Proporcion AS (
    SELECT
         K.IDExport
        ,K.IDImport
        ,K.IDKardex
        ,QtyExport      = K.QtyExport
        ,K.RO_ID
        ,I.IM5
        ,I.ID
        ,Cnt = COUNT(I.ID) OVER (PARTITION BY K.IDKardex)
        ,RN  = ROW_NUMBER()  OVER (PARTITION BY K.IDKardex ORDER BY I.ID)
    FROM #TB_Transfer_Kardex_For_RO_ID  AS K
    LEFT JOIN CTE_Import_Distinct AS I ON K.RO_ID = I.ManufactureID
    -- WHERE K.RO_ID = 505446
)
SELECT
     IDExport
    ,IDImport   = ID
    ,IDKardex
    ,QtyExport          = CAST( (QtyExport / Cnt) + CASE 
                            WHEN RN <= QtyExport % Cnt THEN 1 ELSE 0 END AS INT)
    ,QtyExport_Original = QtyExport
    ,RO_ID
    ,IM5
    -- ,ID
INTO #TB_Transfer_Kardex
FROM CTE_Proporcion
WHERE CAST( (QtyExport / Cnt) + CASE 
                            WHEN RN <= QtyExport % Cnt THEN 1 ELSE 0 END AS INT) > 0 


SELECT
     ID.[MO]
    ,TK.[IM5]
    ,SUM(COALESCE(KD.[QtyImport],0))
    ,SUM(COALESCE(KD.[QtyExport],0))
FROM #TB_Transfer_Kardex AS TK
LEFT  JOIN [AppsLCA].[dbo].[TB_Transfer_Import_Duty] AS ID WITH(NOLOCK) ON TK.[IDImport] = ID.[ID]
-- LEFT  JOIN [AppsLCA].[dbo].[TB_Transfer_Export_Duty] AS ED WITH(NOLOCK) ON TK.[IDExport] = ED.[ID]

SELECT
    --  RO
     IM5
    ,SUM(QtyImport) AS QtyImport
    ,SUM(QtyExport) AS QtyExport
    ,SUM(QtyImport - QtyExport) AS Balance
FROM
(
    SELECT
        RO
        ,ISNULL(QtyImport,0) AS QtyImport
        ,ISNULL(QtyExport,0) AS QtyExport
        ,COALESCE(K.IM5,ID.IM5) AS IM5
    FROM [AppsLCA].[dbo].[TB_Transfer_Kardex_Duty] AS K WITH(NOLOCK)
    LEFT  JOIN [AppsLCA].[dbo].[TB_Transfer_Import_Duty] AS ID WITH(NOLOCK) ON K.[IDImport] = ID.[ID]
) A

GROUP BY IM5

SELECT
    --  RO
     IM5
    ,SUM(QtyImport) AS QtyImport
    ,SUM(QtyExport) AS QtyExport
    ,SUM(QtyImport - QtyExport) AS Balance
FROM
(
    SELECT
        MO
        ,ISNULL(Qty,0)      AS QtyImport
        ,ISNULL(QtyExport,0) AS QtyExport
        ,COALESCE(K.IM5,ID.IM5) AS IM5
    FROM #TB_Transfer_Kardex AS K WITH(NOLOCK)
    LEFT  JOIN [AppsLCA].[dbo].[TB_Transfer_Import_Duty] AS ID WITH(NOLOCK) ON K.[IDImport] = ID.[ID]
) A

GROUP BY IM5
