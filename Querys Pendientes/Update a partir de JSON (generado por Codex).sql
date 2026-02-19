
DROP TABLE IF EXISTS #PayloadShipDates;

CREATE TABLE #PayloadShipDates
(
     Waybill            VARCHAR(200) NOT NULL
    ,ShipDate           DATE NULL
    ,JsonShipDate       VARCHAR(50) NULL
    ,WaybillTable       VARCHAR(200) NULL
    ,CurrentShipDate    DATE NULL
);

INSERT INTO #PayloadShipDates
(
     Waybill
    ,ShipDate
    ,JsonShipDate
    ,WaybillTable
    ,CurrentShipDate
)
SELECT
     Waybill        = X.WaybillJson
    ,ShipDate       = X.ShipDateJson
    ,JsonShipDate   = X.ShipDateRaw
    ,WaybillTable   = T.Waybill
    ,CurrentShipDate = T.ShipDate
FROM AppsLCA.dbo.TB_ShipmentCheckPrices AS T
CROSS APPLY OPENJSON(T.payload, '$.selectedOptions')
WITH
(
     Waybill  VARCHAR(200) '$.Waybill'
    ,ShipDate VARCHAR(50) '$.ShipDate'
) AS J
CROSS APPLY
(
    SELECT
         WaybillJson = LTRIM(RTRIM(J.Waybill))
        ,ShipDateJson = TRY_CONVERT(DATE, J.ShipDate)
        ,ShipDateRaw = J.ShipDate
) AS X
WHERE ISJSON(T.payload) = 1
  AND X.WaybillJson IS NOT NULL
  AND X.WaybillJson <> '';

SELECT
     Waybill
    ,JsonShipDate
    ,ShipDate
    ,WaybillTable
    ,CurrentShipDate
    ,WillUpdate = CASE
        WHEN ShipDate IS NULL THEN 0
        WHEN CurrentShipDate IS NULL OR CurrentShipDate <> ShipDate THEN 1
        ELSE 0
    END
FROM #PayloadShipDates
ORDER BY Waybill;

;WITH SourceByWaybill AS
(
    SELECT
         Waybill
        ,ShipDate = MAX(ShipDate)
    FROM #PayloadShipDates
    WHERE ShipDate IS NOT NULL
    GROUP BY Waybill
)
UPDATE T
SET T.ShipDate = S.ShipDate
FROM AppsLCA.dbo.TB_ShipmentCheckPrices AS T
INNER JOIN SourceByWaybill AS S
    ON LTRIM(RTRIM(T.Waybill)) = S.Waybill
WHERE T.ShipDate IS NULL
   OR T.ShipDate <> S.ShipDate;

SELECT @@ROWCOUNT AS UpdatedRows;

SELECT
     T.Waybill
    ,T.ShipDate
    ,ShipDateInJson = TRY_CONVERT(DATE, JSON_VALUE(T.payload, '$.selectedOptions[0].ShipDate'))
FROM AppsLCA.dbo.TB_ShipmentCheckPrices AS T
WHERE ISJSON(T.payload) = 1
ORDER BY T.Waybill;

select * FROM AppsLCA.dbo.TB_ShipmentCheckPrices AS T
