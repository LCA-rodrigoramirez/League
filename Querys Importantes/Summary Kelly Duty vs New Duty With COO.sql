USE AppsLCA

DROP TABLE IF EXISTS #TB_Kelly_New
DROP TABLE IF EXISTS #TB_Kelly_New_November
DROP TABLE IF EXISTS #TB_CI_New
DROP TABLE IF EXISTS #TB_AllExport_New
DROP TABLE IF EXISTS #TB_Summary
DROP TABLE IF EXISTS #TB_WAYBILL_MATERIALS
DROP TABLE IF EXISTS #TB_Data_Fill

CREATE TABLE #TB_WAYBILL_MATERIALS (
     [Shipdate]        DATE
    ,[Waybill]         VARCHAR(MAX)
    ,[InvoiceLCA]      VARCHAR(MAX)
    ,[Entry #]         VARCHAR(MAX)
    ,[Entry Date]      DATE
    ,[InvoiceKelly]    VARCHAR(MAX)
    ,[CountInvoice]    VARCHAR(MAX)
    ,[Qty]             DECIMAL(10,2)
    ,[Total]           DECIMAL(10,2)
)

INSERT INTO #TB_WAYBILL_MATERIALS (Shipdate, Waybill, InvoiceLCA, [Entry #], [Entry Date], InvoiceKelly, CountInvoice, Qty, Total)
VALUES
     ('2024-12-20', 'SALE-HANTAG20241220'            , 'NO CAFTA', 'BHE04258691', '2025-01-02', '5', 1,55000      , 5500  )
    ,('2025-03-07', 'SALE-HANTAG20250307'            , 'NO CAFTA', 'BHE04269979', '2025-03-17', '7', 1,3000       , 510   )
    ,('2025-03-07', 'SALE-Polybag Adhesive20250307'  , 'NO CAFTA', 'BHE04269979', '2025-03-17', '6', 1,13000      , 780   )
    ,('2025-04-24', 'SALE-SUPPLIES20250424'          , 'CAFTA'   , 'BHE04278798', '2025-04-28', '5', 1,100800     , 3024  )
    ,('2025-09-12', 'SALE-HANTAG20251009-1'          , 'CAFTA'   , 'BHE04302473', '2025-09-19', '8', 1,20000      , 600   )
    ,('2025-09-12', 'SALE-HANTAG20251009'            , 'NO CAFTA', 'BHE04302473', '2025-09-19', '9', 1,20000      , 2060  )
    ,('2024-11-12', 'SALE-HANTAG20241112'            , 'NO CAFTA', 'BHE04253395', '2024-11-21', '4', 1,115000     , 5200  )
    ,('2024-09-24', 'SALE-HANTAG20241112'            , 'CAFTA'   , 'BHE04245672', '2024-10-04', '3', 1,252        , 640.76)
    ,('2024-09-27', 'AIR-APP-20240927'               , 'CAFTA'   , 'BHE04245540', '2024-09-30', '1,2,5', 3,200        , 332   )
    ,('2024-08-30', 'SALE-FABRIC20240830'            , 'CAFTA'   , 'BHE04240772', '2024-09-08', '4', 1,254        , 703.14)
    ,('2024-08-22', 'SALE-FABRIC20240821'            , 'NO CAFTA', 'BHE04239188', '2024-08-29', '4', 1,313.40     , 595.60)
    ,('2024-03-19', 'HAG TAG'                        , 'NO CAFTA', 'BHE04213019', '2024-03-27', '6', 1,5500       , 564.83)
    ,('2024-08-16', 'APP-20240816'                   , 'CAFTA'   , 'BHE04237778', '2024-08-22', '1,2', 2,2104.00    , 4378.21)
    ,('2024-08-23', 'APP-20240823'                   , 'CAFTA'   , 'BHE04239170', '2024-08-29', '1,2', 2,94         , 66.74)
    ,('2024-07-19', 'APP-20240719'                   , 'CAFTA'   , 'BHE04232605', '2024-07-31', '1,2', 2,30         , 505.69)
    ,('2024-06-28', 'APP-20240628'                   , 'CAFTA'   , 'BHE04228967', '2024-07-09', '1,2', 2,12         , 29.79)
    ,('2024-06-28', 'APP-20240628'                   , 'CAFTA'   , 'BHE04228967', '2024-07-09', '1,2', 2,15000.00   , 832.05)
    ,('2024-06-07', 'LCA-20240607-CAFTA'             , 'CAFTA'   , 'BHE04224974', '2024-06-14', '1', 1,5000.00    , 471.50)
    ,('2024-06-07', 'LCA-20240530-CAFTA'             , 'CAFTA'   , 'BHE04223836', '2024-06-10', '1', 1,35         , 589.97)
    ,('2025-11-21','SALE-TRIMS20252111'              , 'CAFTA'   , 'BHE04313207', '2025-12-04', '2', 1,216000     , 43200)


SELECT *
INTO #TB_Kelly_New
FROM(
    SELECT
         [KeySearch]        = CONCAT([Entry #],'-',CAST([Invoice #] as VARCHAR(10)))
        ,[YearEntry]        = YEAR([Entry Date])
        ,[MonthEntry]       = MONTH([Entry Date])
        ,[Entry#]           = [Entry #]
        ,[EntryDate]        = [Entry Date]
        ,[Invoice#]         = [Invoice #]
        ,[CountryCode]      = [Origin]
        ,[Kelly_TotalQty]   = CAST(SUM(QtyTotal) AS DECIMAL(18,2))
        ,[Kelly_TotalFOB]   = CAST(SUM(IIF(Flag = 1, [Value], 0.00)) AS DECIMAL(18,2))
        ,[Kelly_TotalDuty]  = CAST(SUM(Duty) AS DECIMAL(18,2))
    FROM [dbo].[TB_Transfer_TablaKelly] AS TK WITH(NOLOCK)
    GROUP BY
        -- CONCAT([Entry #],'-',CAST([Invoice #] as VARCHAR(10)))
         YEAR([Entry Date])
        ,MONTH([Entry Date])
        ,[Entry #]
        ,[Entry Date]
        ,[Invoice #]
        ,[Origin]
) AS TB

SELECT *
INTO #TB_CI_New
FROM (
    SELECT
         [KeySearch]        = CONCAT([Entry#],'-',CAST([InvoiceKelly] as VARCHAR(10)))
        ,[YearEntry]        = YEAR([EntryDate])
        ,[MonthEntry]       = MONTH([EntryDate])
        ,[Entry#]           = CI.[Entry#]
        ,[EntryDate]        = CI.[EntryDate]
        ,[Invoice#]         = CI.[InvoiceKelly]
        ,[Waybill]          = CI.[WayBill]
        ,[TypeData]         = CI.[TypeData]
        ,[CountInvoice]     = CASE 
                                WHEN LEN(InvoiceKelly) - LEN(REPLACE(InvoiceKelly, ',', '')) = 2 THEN 3
                                WHEN LEN(InvoiceKelly) - LEN(REPLACE(InvoiceKelly, ',', '')) = 1 THEN 2
                                WHEN LEN(InvoiceKelly) - LEN(REPLACE(InvoiceKelly, ',', '')) = 0 THEN 1
                              END
        -- ,[CountryOfOrigin]  = CI.[CountryOfOrigin]
        -- ,[CountryCode]      = CI.[CountryCode]
        ,[CI_TotalQty]      = SUM(CI.[Quantity])
        ,[CI_TotalFOB]      = SUM(CI.[CI_Total])    
        ,[CI_TotalPrice]    = SUM(CI.[TotalPrice])
        ,[Kelly_TotalQty]   = CAST(NULL AS DECIMAL(18,2))
        ,[Kelly_TotalFOB]   = CAST(NULL AS DECIMAL(18,2))
        ,[Kelly_TotalDuty]  = CAST(NULL AS DECIMAL(18,2))
    FROM [dbo].[TB_Transfer_CuadreCI_KellyGlobal] AS CI WITH(NOLOCK)
    GROUP BY
        --  CONCAT([Entry#],'-',CAST([InvoiceKelly] as VARCHAR(10)))
         YEAR([EntryDate])
        ,MONTH([EntryDate])
        ,CI.[Entry#]
        ,CI.[EntryDate]
        ,CI.[InvoiceKelly]
        ,CI.[WayBill]
        ,CI.[TypeData]
        -- ,CI.[CountryOfOrigin]
        -- ,CI.[CountryCode]
) AS TB

SELECT
    [YearEntry]
    ,[MonthEntry]
    ,[Entry#]
    ,[EntryDate]
    ,[Invoice#]
    ,[Waybill]
    ,[TariffCategory]
    ,[CountInvoice]
    ,[CountryOfOrigin]
    ,[CountryCode]
    ,[New_TotalQty]     = CAST(SUM([New_TotalQty]) AS DECIMAL(18,2))
    ,[New_TotalFOB]     = CAST(SUM([New_TotalFOB]) AS DECIMAL(18,2))
    ,[New_TotalDuty]    = CAST(SUM([New_TotalDuty]) AS DECIMAL(18,2))
    ,[New_301China$]    = CAST(SUM([New_301China$]) AS DECIMAL(18,2))
    ,[New_Recip$]       = CAST(SUM([New_Recip$]) AS DECIMAL(18,2))
    ,[New_Fenta$]       = CAST(SUM([New_Fenta$]) AS DECIMAL(18,2))
    ,[New_HTS$]         = CAST(SUM([New_HTS$]) AS DECIMAL(18,2))
INTO #TB_AllExport_New
FROM
(
    SELECT
        --  [KeySearch]        = CONCAT([Entry #],'-',CAST([InvoiceKelly] as VARCHAR(10)))
         [YearEntry]        = [Year_ExportDate]
        ,[MonthEntry]       = [Month_ExportDate]
        ,[Entry#]           = [Entry #]
        ,[EntryDate]        = [ExportDate]
        ,[Invoice#]         = [InvoiceKelly]
        ,[Waybill]          = [Waybill]
        ,[TariffCategory]   = [TariffCategory]
        ,[CountInvoice]     = [CountInvoice]
        ,[CountryOfOrigin]  = [CountryOfOrigin] 
        ,[CountryCode]      = [CountryCode] 
        ,[New_TotalQty]     = CAST(SUM([QtyExport]) AS DECIMAL(18,2))
        ,[New_TotalFOB]     = CAST(SUM([KellyReport]) AS DECIMAL(18,2))
        ,[New_TotalDuty]    = CAST(SUM([T_Total_$]) AS DECIMAL(18,2))
        ,[New_301China$]    = CAST(SUM([TValue_301China_$]) AS DECIMAL(18,2))
        ,[New_Recip$]       = CAST(SUM([TValue_Recip_$]) AS DECIMAL(18,2))
        ,[New_Fenta$]       = CAST(SUM([TValue_Fenta_$]) AS DECIMAL(18,2))
        ,[New_HTS$]         = CAST(SUM([TValue_HTS_$]) AS DECIMAL(18,2))
        --select *
    FROM [dbo].[TB_Transfer_Validation_allExport] AS AE WITH(NOLOCK)
    -- WHERE [Entry #] LIKE '%BHE04312779%'
    -- WHERE [Entry #] NOT LIKE '%BHE04309999%' AND TypeData = 'Export'
    -- WHERE Waybill = '20240112-NONCAFTA-1'
    GROUP BY
        --  CONCAT([Entry #],'-',CAST([InvoiceKelly] as VARCHAR(10)))
         [Year_ExportDate]
        ,[Month_ExportDate]
        ,[Entry #]
        ,[ExportDate]
        ,[InvoiceKelly]
        ,[Waybill]
        ,[TariffCategory]
        ,[CountInvoice]
        ,[CountryOfOrigin] 
        ,[CountryCode]

    UNION ALL

    SELECT
         [YearEntry]        = YEAR([Entry Date])
        ,[MontEntry]        = MONTH([Entry Date])
        ,[Entry#]           = [Entry #]
        ,[EntryDate]        = [Entry Date]
        ,[Invoice#]         = [InvoiceKelly]
        ,[Waybill]          = [Waybill]
        ,[TariffCategory]   = [InvoiceLCA]
        ,[CountInvoice]     = [CountInvoice]
        ,[CountryOfOrigin]  = 'El Salvador'
        ,[CountryCode]      = 'SV'
        ,[New_TotalQty]     = CAST(SUM([Qty]) AS DECIMAL(18,2))
        ,[New_TotalFOB]     = CAST(SUM([Total]) AS DECIMAL(18,2))
        ,[New_TotalDuty]    = 0.0000
        ,[New_301China$]    = 0.0000
        ,[New_Recip$]       = 0.0000
        ,[New_Fenta$]       = 0.0000
        ,[New_HTS$]         = 0.0000
    FROM #TB_WAYBILL_MATERIALS
    GROUP BY
    YEAR([Entry Date])
    ,MONTH([Entry Date])
    ,[Entry #]
    ,[Entry Date]
    ,[InvoiceKelly]
    ,[Waybill]
    ,[InvoiceLCA]
    ,[CountInvoice]
) AS TB
GROUP BY
    [YearEntry]
    ,[MonthEntry]
    ,[Entry#]
    ,[EntryDate]
    ,[Invoice#]
    ,[Waybill]
    ,[TariffCategory]
    ,[CountInvoice]
    ,[CountryOfOrigin]
    ,[CountryCode]

SELECT
     [YearEntry]                = COALESCE(TBK.[YearEntry], TBA.[YearEntry])
    ,[MonthEntry]               = COALESCE(TBK.[MonthEntry], TBA.[MonthEntry])
    ,[NewTariffCategory]        = TBA.[TariffCategory]
    ,[Entry#]                   = COALESCE(TBK.[Entry#], TBA.[Entry#])
    ,[EntryDate]                = COALESCE(TBK.[EntryDate], TBA.[EntryDate])
    ,[WayBill]                  = TBA.[Waybill]
    ,[CountryOfOrigin]          = COALESCE(TBK.[CountryCode],TBA.[CountryOfOrigin])
    ,[Kelly_TotalQty]           = SUM(
                                    COALESCE(CASE
                                                WHEN TBA.[CountInvoice] = 1 THEN
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-',TBA.[Invoice#]) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalQty],0),2)
                                                                                END
                                                WHEN TBA.[CountInvoice] = 2 THEN 
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,LEFT(TBA.[Invoice#]
                                                                                                                            ,CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalQty],0),2)
                                                                                    ELSE 0
                                                                                END 
                                                                                +
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,RIGHT(TBA.[Invoice#]
                                                                                                                            ,CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalQty],0),2)
                                                                                    ELSE 0
                                                                                END 
                                                WHEN TBA.[CountInvoice] = 3 THEN
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,LEFT(TBA.[Invoice#]
                                                                                                                            ,CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalQty],0),2)
                                                                                    ELSE 0
                                                                                END 
                                                                                +
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,TRIM(
                                                                                                                            SUBSTRING(TBA.[Invoice#]
                                                                                                                                        ,CHARINDEX(',',TBA.[Invoice#])+1
                                                                                                                                        ,CHARINDEX(',',TBA.[Invoice#]
                                                                                                                                                    ,CHARINDEX(',',TBA.[Invoice#])+1
                                                                                                                                                ) - CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                                    )
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalQty],0),2)
                                                                                    ELSE 0
                                                                                END 
                                                                                +
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,RIGHT(TBA.[Invoice#]
                                                                                                                            ,CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalQty],0),2)
                                                                                    ELSE 0
                                                                                END 
                                            END
                                        ,0)
                                    )
    ,[Kelly_TotalFOB]           = SUM(
                                    COALESCE(CASE
                                                WHEN TBA.[CountInvoice] = 1 THEN
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-',TBA.[Invoice#]) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalFOB],0),2)
                                                                                END
                                                WHEN TBA.[CountInvoice] = 2 THEN 
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,LEFT(TBA.[Invoice#]
                                                                                                                            ,CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalFOB],0),2)
                                                                                    ELSE 0
                                                                                END 
                                                                                +
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,RIGHT(TBA.[Invoice#]
                                                                                                                            ,CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalFOB],0),2)
                                                                                    ELSE 0
                                                                                END 
                                                WHEN TBA.[CountInvoice] = 3 THEN
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,LEFT(TBA.[Invoice#]
                                                                                                                            ,CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalFOB],0),2)
                                                                                    ELSE 0
                                                                                END 
                                                                                +
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,TRIM(
                                                                                                                            SUBSTRING(TBA.[Invoice#]
                                                                                                                                        ,CHARINDEX(',',TBA.[Invoice#])+1
                                                                                                                                        ,CHARINDEX(',',TBA.[Invoice#]
                                                                                                                                                    ,CHARINDEX(',',TBA.[Invoice#])+1
                                                                                                                                                ) - CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                                    )
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalFOB],0),2)
                                                                                    ELSE 0
                                                                                END 
                                                                                +
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,RIGHT(TBA.[Invoice#]
                                                                                                                            ,CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalFOB],0),2)
                                                                                    ELSE 0
                                                                                END 
                                            END
                                        ,0)
                                    )
    ,[Kelly_TotalDuty]          = SUM(
                                    COALESCE(
                                            CASE
                                                WHEN TBA.[CountInvoice] = 1 THEN
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-',TBA.[Invoice#]) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalDuty],0),2)
                                                                                END
                                                WHEN TBA.[CountInvoice] = 2 THEN 
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,LEFT(TBA.[Invoice#]
                                                                                                                            ,CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalDuty],0),2)
                                                                                    ELSE 0
                                                                                END 
                                                                                +
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,RIGHT(TBA.[Invoice#]
                                                                                                                            ,CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalDuty],0),2)
                                                                                    ELSE 0
                                                                                END 
                                                WHEN TBA.[CountInvoice] = 3 THEN
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,LEFT(TBA.[Invoice#]
                                                                                                                            ,CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalDuty],0),2)
                                                                                    ELSE 0
                                                                                END 
                                                                                +
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,TRIM(
                                                                                                                            SUBSTRING(TBA.[Invoice#]
                                                                                                                                        ,CHARINDEX(',',TBA.[Invoice#])+1
                                                                                                                                        ,CHARINDEX(',',TBA.[Invoice#]
                                                                                                                                                    ,CHARINDEX(',',TBA.[Invoice#])+1
                                                                                                                                                ) - CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                                    )
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalDuty],0),2)
                                                                                    ELSE 0
                                                                                END 
                                                                                +
                                                                                CASE
                                                                                    WHEN CONCAT(TBA.[Entry#],'-'
                                                                                                                    ,RIGHT(TBA.[Invoice#]
                                                                                                                            ,CHARINDEX(',',TBA.[Invoice#])-1
                                                                                                                        )
                                                                                                ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Kelly_TotalDuty],0),2)
                                                                                    ELSE 0
                                                                                END 
                                            END
                                    ,0))
    ,[New_TotalQty]             = SUM(ISNULL(TBA.[New_TotalQty],0))
    ,[New_TotalFOB]             = SUM(ISNULL(TBA.[New_TotalFOB],0))
    ,[New_TotalDuty]            = SUM(ISNULL(TBA.[New_TotalDuty],0))
    ,[New_301China$]            = SUM(ISNULL(TBA.[New_301China$],0))
    ,[New_Fenta$]               = SUM(ISNULL(TBA.[New_Fenta$],0))
    ,[New_Recip$]               = SUM(ISNULL(TBA.[New_Recip$],0))
    ,[New_HTS$]                 = SUM(ISNULL(TBA.[New_HTS$],0))
    ,[NewDrawBack]              = SUM(ISNULL(TBA.[New_TotalDuty],0)) - SUM(ISNULL(TBK.[Kelly_TotalDuty],0.00))
INTO #TB_Summary
FROM #TB_Kelly_New AS TBK
FULL JOIN #TB_AllExport_New AS TBA 
ON  TBA.[Entry#] = TBK.[Entry#] 
AND TBA.[EntryDate] = TBK.[EntryDate] 
AND TBK.[CountryCode] = TBA.[CountryCode]
GROUP BY
     COALESCE(TBK.[YearEntry], TBA.[YearEntry])
    ,COALESCE(TBK.[MonthEntry], TBA.[MonthEntry])
    ,TBA.[TariffCategory]
    ,COALESCE(TBK.[Entry#], TBA.[Entry#])
    ,COALESCE(TBK.[EntryDate], TBA.[EntryDate])
    ,TBA.[Waybill]
    ,COALESCE(TBK.[CountryCode],TBA.[CountryOfOrigin])

ORDER BY 
     COALESCE(TBK.[YearEntry], TBA.[YearEntry])
    ,COALESCE(TBK.[MonthEntry], TBA.[MonthEntry])


SELECT * 
FROM #TB_Summary

-- DROP TABLE IF EXISTS AppsLCA.dbo.TB_Transfer_SummaryNewCIKelly

-- SELECT * 
-- INTO AppsLCA.dbo.TB_Transfer_SummaryNewCIKelly
-- FROM #TB_Summary
-- where [Entry#] not Like '%BHE04309999%'

return
SELECT 
    [Entry#]
    ,[EntryDate]
    ,SUM(Kelly_TotalQty)
    ,SUM(Kelly_TotalFOB)
    ,SUM(Kelly_TotalDuty)
FROM #TB_CI_New
GROUP BY 
    [Entry#],[EntryDate]
order by [Entry#],[EntryDate]

SELECT
    [Entry #]
    ,[Entry Date]
    ,SUM(QtyTotal)
    ,SUM([Value])
    ,SUM(Duty)
FROM AppsLCA.dbo.TB_Transfer_TablaKelly
GROUP BY 
    [Entry #],[Entry Date]
order by [Entry #],[Entry Date]
    

return
SELECT
    [Entry#]
    ,ROUND(SUM(Kelly_TotalDuty),2)
FROM #TB_Kelly_New
GROUP BY
    [Entry#]
ORDER BY [Entry#]

SELECT
    [Entry#]
    ,SUM(Kelly_TotalDuty)
FROM #TB_Summary
GROUP BY
    [Entry#]
ORDER BY [Entry#]