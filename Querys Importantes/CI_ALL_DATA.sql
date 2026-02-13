
PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  INICIO PROCEDIMIENTO')

DROP TABLE IF EXISTS #TB_DATA_CI
DROP TABLE IF EXISTS #TB_COMPOSITION
DROP TABLE IF EXISTS #Numbers
DROP TABLE IF EXISTS #Positions
DROP TABLE IF EXISTS #Extracted
DROP TABLE IF EXISTS #Cleaned
DROP TABLE IF EXISTS #TB_WAYBILL_MATERIALS

-- SELECT * FROM AppsLCA.dbo.TB_Transfer_WaybillEntry where Waybill = 'AIR-APP-20240709'
-- SELECT * FROM AppsLCA.dbo.TB_Transfer_Waybill_Void where Waybill LIKE '%20240530%'


CREATE TABLE #TB_WAYBILL_MATERIALS (
     [Shipdate]        DATE
    ,[Waybill]         VARCHAR(MAX)
    ,[InvoiceLCA]      VARCHAR(MAX)
    ,[Entry #]         VARCHAR(MAX)
    ,[Entry Date]      DATE
    ,[InvoiceKelly]    VARCHAR(MAX)
    ,[Qty]             DECIMAL(10,2)
    ,[Total]           DECIMAL(10,2)
)

INSERT INTO #TB_WAYBILL_MATERIALS (Shipdate, Waybill, InvoiceLCA, [Entry #], [Entry Date], InvoiceKelly, Qty, Total)
VALUES
     ('2024-12-20', 'SALE-HANTAG20241220'            , 'NO CAFTA', 'BHE04258691', '2025-01-02', '5', 55000      , 5500  )
    ,('2025-03-07', 'SALE-HANTAG20250307'            , 'NO CAFTA', 'BHE04269979', '2025-03-17', '7', 3000       , 510   )
    ,('2025-03-07', 'SALE-Polybag Adhesive20250307'  , 'NO CAFTA', 'BHE04269979', '2025-03-17', '6', 13000      , 780   )
    ,('2025-04-24', 'SALE-SUPPLIES20250424'          , 'CAFTA'   , 'BHE04278798', '2025-04-28', '5', 100800     , 3024  )
    ,('2025-09-12', 'SALE-HANTAG20251009-1'          , 'CAFTA'   , 'BHE04302473', '2025-09-19', '8', 20000      , 600   )
    ,('2025-09-12', 'SALE-HANTAG20251009'            , 'NO CAFTA', 'BHE04302473', '2025-09-19', '9', 20000      , 2060  )
    ,('2024-11-12', 'SALE-HANTAG20241112'            , 'NO CAFTA', 'BHE04253395', '2024-11-21', '4', 115000     , 5200  )
    ,('2024-09-24', 'SALE-HANTAG20241112'            , 'CAFTA'   , 'BHE04245672', '2024-10-04', '3', 252        , 640.76)
    ,('2024-09-27', 'AIR-APP-20240927'               , 'CAFTA'   , 'BHE04245540', '2024-09-30', '1,2,5', 200        , 332   )
    ,('2024-08-30', 'SALE-FABRIC20240830'            , 'CAFTA'   , 'BHE04240772', '2024-09-08', '4', 254        , 703.14)
    ,('2024-08-22', 'SALE-FABRIC20240821'            , 'NO CAFTA', 'BHE04239188', '2024-08-29', '4', 313.40     , 595.60)
    ,('2024-03-19', 'HAG TAG'                        , 'NO CAFTA', 'BHE04213019', '2024-03-27', '6', 5500       , 564.83)
    ,('2024-08-16', 'APP-20240816'                   , 'CAFTA'   , 'BHE04237778', '2024-08-22', '1,2', 2104.00    , 4378.21)
    ,('2024-08-23', 'APP-20240823'                   , 'CAFTA'   , 'BHE04239170', '2024-08-29', '1,2', 94         , 66.74)
    ,('2024-07-19', 'APP-20240719'                   , 'CAFTA'   , 'BHE04232605', '2024-07-31', '1,2', 30         , 505.69)
    ,('2024-06-28', 'APP-20240628'                   , 'CAFTA'   , 'BHE04228967', '2024-07-09', '1,2', 12         , 29.79)
    ,('2024-06-28', 'APP-20240628'                   , 'CAFTA'   , 'BHE04228967', '2024-07-09', '1,2', 15000.00   , 832.05)
    ,('2024-06-07', 'LCA-20240607-CAFTA'             , 'CAFTA'   , 'BHE04224974', '2024-06-14', '1', 5000.00    , 471.50)
    ,('2024-06-07', 'LCA-20240530-CAFTA'             , 'CAFTA'   , 'BHE04223836', '2024-06-10', '1', 35         , 589.97)
    ,('2025-11-21','SALE-TRIMS20252111'              , 'CAFTA'   , 'BHE04313207', '2025-12-04', '2', 216000     , 43200)



select 
     [R]                = ROW_NUMBER() OVER (ORDER BY ShipDate,Waybill, Orden,InvoicingDescription ASC)
    ,[Entry#]           = CAST(NULL AS VARCHAR(200))
    ,[EntryDate]        = CAST(NULL AS DATE)
    ,[Material]         = CAST(NULL AS VARCHAR(100))
    ,[Percentage]       = CAST(NULL AS FLOAT)
    ,[ArticleTypeRaw]   = CAST(NULL AS VARCHAR(100))
    ,[GroupType]        = CAST(NULL AS VARCHAR(100))
    ,[GarmentType]      = CAST(NULL AS VARCHAR(100))
    ,[ArticleType]      = CAST(NULL AS VARCHAR(200))
    ,[Line]             = CAST(NULL AS INT)
    ,[InvoiceKelly]     = CAST(NULL AS VARCHAR(100))
    ,[CountryCode]      = CAST(NULL AS VARCHAR(10))
    ,*
INTO #TB_DATA_CI from (
SELECT [WayBill]                              = CI.[WayBill]
    , [TypeData]                            = 'NO CAFTA RULE 9802'
    , [ContainerNumber]                     = CI.[ContainerNumber]
    , [StyleNumber]                         = CI.[StyleNumber]
    , [InvoicingDescription]                = CI.[InvoicingDescription]
    , [US_HTSDescription]                   = CI.[US_HTSDescription]
    , [US_HTSCode]                          = CI.[CA_HTSCode]
    , [UnitPrice]                           = CI.[UnitPrice]
    , [ShipDate]                            = CI.[ShipDate]
    , [Quantity]                            = CI.[Quantity]
    , [TotalPrice]                          = CI.[TotalPrice]
    , [MinBatch]                            = CI.[MinBatch]
    , [WeightKg]                            = CI.[WeightKg]
    , [MaxBatch]                            = CI.[MaxBatch]
    , [Cafta]                               = CI.[Cafta]
    , [Pallets]                             = CI.[Pallets]
    , [Boxes]                               = CI.[Boxes]
    , [Manufactured]                        = CI.[Manufactured]
    , [CountryOfOrigin]                     = CI.[CountryOfOrigin]
    , [Freight]                             = NULL
    , [IM5]                                 = CI.[IM5]
    , [DeclarationDate]                     = CI.[DeclarationDate]
    , [ArrivalDate]                         = CI.[ArrivalDate]
    , [DepartureDate]                       = CI.[DepartureDate]
    , [PortOfLoading]                       = CI.[PortOfLoading]
    , [DecorationDesc]                      = CI.[DecorationDesc]
    , [DecorationValue]                     = CI.[DecorationValue]
    , [Orden]                               = CI.[Orden]
    , [CI_Total]                            = CI.[DecorationValue]
    , [ManufacturerGroup]                   = CONCAT(CI.[Manufactured], '/', CI.[CountryOfOrigin])
FROM [192.168.1.93].[AppsLCA].[dbo].[import_export_DeclarationExport] CI WITH(NOLOCK)
LEFT JOIN AppsLCA.dbo.TB_Transfer_Waybill_Void AS  WV WITH(NOLOCK) ON CI.Waybill = WV.waybill
WHERE WV.waybill IS NULL AND CI.WayBill NOT IN ('AIR-BUND-20250516','AIR-APP-20250519','AIR-APP-20250520','AIR-HW-20250520','AIR-HW-20250514','HW-20250509','HW-20250513','HW-20250516')

UNION ALL

SELECT [WayBill]                              = CI.[WayBill]
    , [TypeData]                            = CASE 
                                                WHEN CAST(CI.[ShipDate] AS DATE) <= '2025-05-20' AND CI.[Orden] IN (1,2,3) AND CI.Waybill LIKE '%AIR%' THEN 'CAFTA'
                                                WHEN CAST(CI.[ShipDate] AS DATE) <= '2025-05-20' AND CI.[Orden] = 4 AND CI.Waybill LIKE '%AIR%' THEN 'NO CAFTA'
                                                WHEN CAST(CI.[ShipDate] AS DATE) <= '2025-05-18' AND CI.[Orden] IN (1,2,3) AND CI.Waybill NOT LIKE '%AIR%' THEN 'CAFTA'
                                                WHEN CAST(CI.[ShipDate] AS DATE) <= '2025-05-18' AND CI.[Orden] = 4 AND CI.Waybill NOT LIKE '%AIR%' THEN 'NO CAFTA'
                                                WHEN CAST(CI.[ShipDate] AS DATE) >= '2025-05-19' AND CI.[Orden] = 1 AND CI.Waybill NOT LIKE '%AIR%' THEN 'CAFTA'
                                                WHEN CAST(CI.[ShipDate] AS DATE) >= '2025-05-19' AND CI.[Orden] = 2 AND CI.Waybill NOT LIKE '%AIR%' THEN 'NO CAFTA'
                                                WHEN CAST(CI.[ShipDate] AS DATE) > '2025-05-20' AND CI.[Orden] = 1 THEN 'CAFTA'
                                                WHEN CAST(CI.[ShipDate] AS DATE) > '2025-05-20' AND CI.[Orden] = 2 THEN 'NO CAFTA'
                                                WHEN CAST(CI.[ShipDate] AS DATE) > '2025-05-20' AND CI.[Orden] = 3 THEN 'NO CAFTA RULE 9802'
                                                ELSE 'UNKNOWN'
                                              END
    , [ContainerNumber]                     = CI.[ContainerNumber]
    , [StyleNumber]                         = CI.[StyleNumber]
    , [InvoicingDescription]                = CI.[InvoicingDescription]
    , [US_HTSDescription]                   = CI.[US_HTSDescription]
    , [US_HTSCode]                          = CI.[CA_HTSCode]
    , [UnitPrice]                           = CI.[UnitPrice]
    , [ShipDate]                            = CI.[ShipDate]
    , [Quantity]                            = CI.[Quantity]
    , [TotalPrice]                          = CI.[TotalPrice]
    , [MinBatch]                            = CI.[MinBatch]
    , [WeightKg]                            = CI.[WeightKg]
    , [MaxBatch]                            = CI.[MaxBatch]
    , [Cafta]                               = CI.[Cafta]
    , [Pallets]                             = CI.[Pallets]
    , [Boxes]                               = CI.[Boxes]
    , [Manufactured]                        = CI.[Manufactured]
    , [CountryOfOrigin]                     = CI.[CountryOfOrigin]
    , [Freight]                             = CI.[Freight]
    , [IM5]                                 = NULL
    , [DeclarationDate]                     = NULL
    , [ArrivalDate]                         = NULL
    , [DepartureDate]                       = NULL
    , [PortOfLoading]                       = NULL
    , [DecorationDesc]                      = NULL
    , [DecorationValue]                     = NULL
    , [Orden]                               = CI.[Orden]
    , [CI_Total]                            = CASE 
                                                WHEN CI.Waybill IN ('APP-20250304','BUND-20250304','HW-20250304') AND CI.Orden IN (4) THEN CI.[TotalPrice] - (CI.[Quantity] * CI.[Freight])
                                                WHEN CI.Waybill IN ('APP-20250304') AND CI.Orden IN (1,2,3) THEN CI.[TotalPrice]
                                                WHEN CI.ShipDate < '2025-03-06' THEN CI.[TotalPrice]
                                                WHEN CI.ShipDate <= '2025-04-14' AND CI.Orden IN (1,2,3) THEN CI.[TotalPrice]
                                                ELSE CI.[TotalPrice] - (CI.[Quantity] * CI.[Freight])
                                              END
    , [ManufacturerGroup]                   = CONCAT(CI.[Manufactured], '/', CI.[CountryOfOrigin])
FROM [192.168.1.93].[AppsLCA].[dbo].[import_export_CommercialInvoice] CI WITH(NOLOCK)
LEFT JOIN AppsLCA.dbo.TB_Transfer_Waybill_Void AS  WV WITH(NOLOCK) ON CI.Waybill = WV.waybill
WHERE WV.waybill IS NULL --AND CI.Quantity > 0

UNION ALL

SELECT [WayBill]                            = CI.[WayBill]
    , [TypeData]                            = CASE 
                                                WHEN CI.Orden IN (1,2,3) THEN 'CAFTA'
                                                WHEN CI.Orden IN (4) THEN 'NO CAFTA'
                                                ELSE 'UNKNOWN'
                                              END
    , [ContainerNumber]                     = CI.[ContainerNumber]
    , [StyleNumber]                         = CI.[StyleNumber]
    , [InvoicingDescription]                = CI.[InvoicingDescription]
    , [US_HTSDescription]                   = CI.[US_HTSDescription]
    , [US_HTSCode]                          = CI.[CA_HTSCode]
    , [UnitPrice]                           = CI.[UnitPrice]
    , [ShipDate]                            = CI.[ShipDate]
    , [Quantity]                            = CI.[Quantity]
    , [TotalPrice]                          = CI.[TotalPrice]
    , [MinBatch]                            = CI.[MinBatch]
    , [WeightKg]                            = CI.[WeightKg]
    , [MaxBatch]                            = CI.[MaxBatch]
    , [Cafta]                               = CI.[Cafta]
    , [Pallets]                             = CI.[Pallets]
    , [Boxes]                               = CI.[Boxes]
    , [Manufactured]                        = CI.[Manufactured]
    , [CountryOfOrigin]                     = CI.[CountryOfOrigin]
    , [Freight]                             = CI.[Freight]
    , [IM5]                                 = NULL
    , [DeclarationDate]                     = NULL
    , [ArrivalDate]                         = NULL
    , [DepartureDate]                       = NULL
    , [PortOfLoading]                       = NULL
    , [DecorationDesc]                      = NULL
    , [DecorationValue]                     = NULL
    , [Orden]                               = CI.[Orden]
    , [CI_Total]                            = CI.[TotalPrice]
    , [ManufacturerGroup]                   = CONCAT(CI.[Manufactured], '/', CI.[CountryOfOrigin])
FROM [192.168.1.93].[AppsLCA].[dbo].[Import_Export_CommercialInvoice_Before20240801] CI WITH(NOLOCK)
LEFT JOIN AppsLCA.dbo.TB_Transfer_Waybill_Void AS  WV WITH(NOLOCK) ON CI.Waybill = WV.waybill
WHERE WV.waybill IS NULL --AND CI.Quantity > 0

	) as tb

CREATE CLUSTERED INDEX IX_TB_DATA_CI_R ON #TB_DATA_CI(R)
CREATE NONCLUSTERED INDEX IX_TB_DATA_CI_InvDesc ON #TB_DATA_CI(InvoicingDescription)

-- DROP TABLE IF EXISTS #tb_entry_kelly
-- SELECT DISTINCT
--       ShipDate = CAST(
--                         CONCAT(
--                             LEFT([ShipDate], 4), '-', 
--                             SUBSTRING([ShipDate], 5, 2), '-', 
--                             RIGHT([ShipDate], 2)
--                         ) 
--                        AS date)
--     , [Entry Date] = CAST([Entry Date] AS date)
-- INTO #tb_entry_kelly
-- FROM [AppsLCA].[dbo].[ImportExport_DutyKellyGlobal_2025_2026_AfterPSC] AS DAT WITH (NOLOCK)
-- -- WHERE ID <= 36385
-- select * from #tb_entry_kelly

DROP TABLE IF EXISTS #TB_SHIPDATE_ENTRYDATE
SELECT
	 [Waybill]   = S.[Waybill]
	,[DAT]       = S.[DAT]
	,[ShipDate]  = IIF(S.[DAT] = 1, MIN([ShipDate]),MAX([ShipDate]))
INTO #TB_SHIPDATE_ENTRYDATE
FROM(
	SELECT  DISTINCT
		 [Waybill]      = A.Waybill
		,[DAT]          = iif(LEFT(A.[Waybill],3) IN( 'AIR','SMS'),1,0)
		,[ShipDate]     = B.[Entry Date]
	FROM #TB_DATA_CI AS A
	LEFT JOIN #tb_entry_kelly AS B ON CAST(A.ShipDate AS DATE) = CAST(B.ShipDate AS DATE)
) AS S
GROUP BY
	 [Waybill]
	,[DAT]



-----PONER ENTRY# Y ENTRYDATE (EXPORTDATE)
------CON LA TABLA NUEVA
UPDATE S SET
	 [Entry#]        	 = B.[Entry #]
	,[EntryDate]        = COALESCE(B.EntryDate ,S.Shipdate)
    ,[InvoiceKelly]     = B.[Invoice #]
--SELECT *
FROM #TB_DATA_CI AS S
LEFT JOIN
(
    SELECT
        [Entry #]
        ,[EntryDate]
        ,[WayBill]
        ,[InvoiceLCA]
        ,STRING_AGG([Invoice #],',') WITHIN GROUP(ORDER BY [Invoice #]) AS [Invoice #] 
    FROM [AppsLCA].[dbo].[TB_Transfer_WaybillEntry] AS B WITH(NOLOCK)
    WHERE B.Status = 1 --AND Waybill = 'AIR-HW-20251010'
    GROUP BY
    [Entry #]
        ,[EntryDate]
        ,[WayBill]
        ,[InvoiceLCA]
) AS B ON B.Waybill = S.Waybill AND S.TypeData = B.InvoiceLCA
--  WHERE S.WayBill= 'AIR-HW-20251010'


UPDATE S SET
	 [EntryDate]        = COALESCE(B.ShipDate ,S.Shipdate)
FROM #TB_DATA_CI AS S
LEFT JOIN #TB_SHIPDATE_ENTRYDATE AS B ON B.Waybill = S.Waybill
WHERE [EntryDate] IS NULL

PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  FIN #TB_DATA_CI')

SELECT TOP (8000)
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
INTO #Numbers
FROM master..spt_values

CREATE UNIQUE CLUSTERED INDEX IX_Numbers_n ON #Numbers(n)

PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  FIN Numbers')

SELECT
    D.R,
    v.Pos AS PosPercent
INTO #Positions
FROM #TB_DATA_CI AS D
CROSS APPLY (
    SELECT 
        Pos = CHARINDEX('%', D.InvoicingDescription)
    UNION ALL
    SELECT 
        CHARINDEX('%', D.InvoicingDescription, CHARINDEX('%', D.InvoicingDescription) + 1)
    UNION ALL
    SELECT 
        CHARINDEX('%', D.InvoicingDescription, CHARINDEX('%', D.InvoicingDescription, CHARINDEX('%', D.InvoicingDescription) + 1) + 1)
    UNION ALL
    SELECT 
        CHARINDEX('%', D.InvoicingDescription, CHARINDEX('%', D.InvoicingDescription, CHARINDEX('%', D.InvoicingDescription, CHARINDEX('%', D.InvoicingDescription) + 1) + 1) + 1)
) v
WHERE v.Pos > 0;

CREATE INDEX IX_Positions_R ON #Positions(R)

PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  FIN Positions')

SELECT
    P.R AS R,
    P.PosPercent AS PosPercent,
    PercentageRaw =
        LTRIM(RTRIM(
            SUBSTRING(
                D.InvoicingDescription,
                P.PosPercent - 10,
                10
            )
        )),
    MaterialRaw =
        LTRIM(RTRIM(
            SUBSTRING(
                D.InvoicingDescription,
                P.PosPercent + 1,
                50
            )
        ))
INTO #Extracted
FROM #Positions AS P
JOIN #TB_DATA_CI AS D ON D.R = P.R

CREATE INDEX IX_Extracted_R ON #Extracted(R)

PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  FIN Extracted')

SELECT
    R,
    Percentage =
        TRY_CAST(
            REVERSE(
                SUBSTRING(
                    REVERSE(PercentageRaw),
                    1,
                    PATINDEX('%[^0-9.]%', REVERSE(PercentageRaw) + 'X') - 1
                )
            ) AS FLOAT
        ),
    Material =
        LTRIM(RTRIM(
            LEFT(MaterialRaw,
                NULLIF(PATINDEX('%[0-9]%', MaterialRaw + '0') - 1, -1)
            )
        ))
INTO #Cleaned
FROM #Extracted

CREATE INDEX IX_Cleaned_R ON #Cleaned(R)

PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  FIN Cleaned')

SELECT
    R,
    Percentage,
    CASE
        WHEN Material LIKE 'COT%' OR Material LIKE 'CTTN%' OR Material LIKE '%Cotton%' THEN 'Cotton'
        WHEN Material LIKE '%POLY%' OR Material LIKE 'RAY%' OR Material LIKE 'SPAN%' THEN 'Polyester'
		WHEN Material LIKE '%Nylon%' THEN 'Nylon'
		WHEN Material LIKE '%Acrilyc%' OR Material LIKE '%Acrylic%' THEN 'Acrylic'
        ELSE 'NOT IN CASE'
    END as Material
INTO #TB_COMPOSITION 
FROM #Cleaned
WHERE Percentage IS NOT NULL AND Material <> ''

PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  FIN COMPOSITION')

;WITH MaxComp AS (
    SELECT 
        R,
        Percentage,
        Material,
        ROW_NUMBER() OVER (PARTITION BY R ORDER BY Percentage DESC) AS rn
    FROM #TB_COMPOSITION
)
UPDATE D SET 
    Material = M.Material,
    Percentage = M.Percentage
FROM #TB_DATA_CI D
JOIN MaxComp M ON D.R = M.R
WHERE M.rn = 1

UPDATE #TB_DATA_CI SET 
    ArticleTypeRaw =
        CASE 
            WHEN PATINDEX('%[0-9]%', InvoicingDescription) > 0
                THEN LTRIM(RTRIM(
                        LEFT(InvoicingDescription,
                            PATINDEX('%[0-9]%', InvoicingDescription)-1)))
            ELSE InvoicingDescription
        END

UPDATE #TB_DATA_CI SET 
    GroupType =
        CASE
            WHEN ArticleTypeRaw LIKE 'Men%'     THEN 'Mens'
            WHEN ArticleTypeRaw LIKE 'Women%'   THEN 'Womens'
            WHEN ArticleTypeRaw LIKE 'Boy%'     THEN 'Boys'
            WHEN ArticleTypeRaw LIKE 'Girl%'    THEN 'Girls'
            WHEN ArticleTypeRaw LIKE '%Youth%'                                        THEN 'Youth'
            WHEN ArticleTypeRaw LIKE '%Kid%'                                          THEN 'Kids'
            ELSE NULL
        END

UPDATE #TB_DATA_CI
SET GarmentType =
    CASE
        WHEN ArticleTypeRaw LIKE '%hood%' THEN 'Hood'
        WHEN ArticleTypeRaw LIKE '%sweatshirt%' THEN 'Sweatshirt'
        WHEN ArticleTypeRaw LIKE '%t-shirt%' OR ArticleTypeRaw LIKE '%t shirt%' THEN 'T-shirt'
        WHEN ArticleTypeRaw LIKE '%polo%' THEN 'Polo'
        WHEN ArticleTypeRaw LIKE '%tank%' THEN 'Tank Top'
        WHEN ArticleTypeRaw LIKE '%pant%' THEN 'Pants'
        WHEN ArticleTypeRaw LIKE '%blanket%' THEN 'Blanket'
        WHEN ArticleTypeRaw LIKE '%hoodie%' THEN 'Hood'
        WHEN ArticleTypeRaw LIKE '%sweater%' THEN 'Sweater'
        WHEN ArticleTypeRaw LIKE '%shirt%' THEN 'Shirt'
        WHEN ArticleTypeRaw LIKE '%Hat%' THEN 'Hat'
        WHEN ArticleTypeRaw LIKE '%Short%' THEN 'Short'
        WHEN ArticleTypeRaw LIKE '%Dress%' THEN 'Dress'
        ELSE 'Other'
    END

UPDATE #TB_DATA_CI
SET ArticleType = CASE 
                    WHEN GroupType IS NOT NULL THEN CONCAT(GroupType, ' ', GarmentType, ' ', Material)
                    ELSE CONCAT(GarmentType, ' ', Material)
                  END


UPDATE DC SET
    [Line] = LDC.Line
FROM #TB_DATA_CI AS DC
INNER JOIN
(
    SELECT
        *
        ,[Line] = ROW_NUMBER() OVER (PARTITION BY WayBill,Orden ORDER BY WayBill, Orden, ArticleType, US_HTSCode, ManufacturerGroup)
    FROM
    (
        SELECT
            WayBill
            ,Orden
            ,US_HTSCode
            ,ArticleType
            ,ManufacturerGroup
            -- ,[Line] = ROW_NUMBER() OVER (PARTITION BY WayBill,Orden ORDER BY WayBill, Orden, ArticleType, ManufacturerGroup)
        FROM #TB_DATA_CI
        GROUP BY 
            WayBill
            ,Orden
            ,US_HTSCode
            ,ArticleType
            ,ManufacturerGroup
    ) AS TB
) AS LDC ON DC.WayBill = LDC.WayBill AND DC.Orden = LDC.Orden AND DC.ArticleType = LDC.ArticleType AND DC.ManufacturerGroup = LDC.ManufacturerGroup AND DC.US_HTSCode = LDC.US_HTSCode

PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  FIN UPDATE')

UPDATE TDC SET
	CountryCode = COO.CountryCode
FROM #TB_DATA_CI AS TDC
LEFT JOIN
(
	SELECT DISTINCT
		CountryCode
		,CountryName
	FROM LCA.dbo.CountryOfOrigin AS COO WITH(NOLOCK)
) AS COO ON TDC.CountryOfOrigin = COO.CountryName

    TRUNCATE TABLE AppsLCA.dbo.TB_Transfer_CuadreCI_KellyGlobal
    INSERT INTO AppsLCA.dbo.TB_Transfer_CuadreCI_KellyGlobal

    -- DROP TABLE IF EXISTS AppsLCA.dbo.TB_Transfer_CuadreCI_KellyGlobal
	SELECT * 
    -- INTO AppsLCA.dbo.TB_Transfer_CuadreCI_KellyGlobal    
    FROM #TB_DATA_CI
	-- WHERE ShipDate <= '2025-12-09'
    -- AND WayBill NOT IN ('APP-20251205','HW-20251205','APP-20251209','HW-20251209')
    -- AND [Entry#] Like '%BHE04309999%'
    ORDER BY R
    
    INSERT INTO AppsLCA.dbo.TB_Transfer_CuadreCI_KellyGlobal
    (
        [Shipdate]    
        ,[Waybill]     
        ,[TypeData]  
        ,[Entry#]     
        ,[EntryDate]  
        ,[InvoiceKelly]
        ,[Quantity]         
        ,[TotalPrice]       
        ,[CI_Total]
        ,[Cafta]
        ,[Orden]
        ,[CountryCode]      
    )
    SELECT
        [Shipdate]    
        ,[Waybill]     
        -- ,'MATERIALS'  
        ,[InvoiceLCA]  
        ,[Entry #]     
        ,[Entry Date]  
        ,[InvoiceKelly]
        ,[Qty]         
        ,0      
        ,[Total]
        ,IIF([InvoiceLCA] = 'CAFTA','Y','N')
        ,IIF([InvoiceLCA] = 'CAFTA',1,2)
        ,'SV'
    FROM #TB_WAYBILL_MATERIALS 
    -- "BHE04309999"
    -- DELETE
    -- FROM AppsLCA.dbo.TB_Transfer_CuadreCI_KellyGlobal
    -- WHERE Entry# IS NULL

    SELECT DISTINCT WayBill, EntryDate, TypeData
    FROM AppsLCA.dbo.TB_Transfer_CuadreCI_KellyGlobal 
    WHERE Entry# IS NULL

    RETURN

    SELECT * 
    FROM AppsLCA.dbo.TB_Transfer_Waybill_Void WHERE waybill IN
    (

    'AIR20240423-NOVA'
    )

    -- AND Waybill in ('AIR-APP-20251029')
    
    SELECT *
    FROM [192.168.1.93].[AppsLCA].[dbo].[Import_Export_CommercialInvoice] CI WITH(NOLOCK)
    WHERE Waybill = 'APP-20250910' AND Orden = 1

	-- WHERE   Waybill in ('AIR-APP-20251029','AIR-HW-20251029')