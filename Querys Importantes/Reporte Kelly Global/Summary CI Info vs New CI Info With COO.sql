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
        ,[CountryCode]      = LEFT(MANUFID,2)
        ,[Kelly_TotalQty]   = CAST(SUM(QtyTotal) AS DECIMAL(18,2))
        ,[Kelly_TotalFOB]   = CAST(SUM(IIF(Flag = 1, [Value], 0.00)) AS DECIMAL(18,2))
        ,[Kelly_TotalDuty]  = CAST(SUM(Duty) AS DECIMAL(18,2))
        -- ,[Kelly_301China$]	= CAST(SUM(IIF(TK.Commodity LIKE '%ARTICLE OF CHINA%',Duty,0.0000)) AS DECIMAL(18,2))
        -- ,[Kelly_Fenta$]		= CAST(SUM(IIF(TK.Commodity LIKE '%CHINA/HONG KONG%' OR TK.Commodity LIKE '%CH/HK%' OR TK.Commodity LIKE '%CN/HK%',Duty,0.0000)) AS DECIMAL(18,2))
        -- ,[Kelly_Recip$]		= CAST(SUM(IIF(TK.Commodity LIKE '%PRD ANY CTRY%' OR TK.Commodity LIKE '%RECIP%' OR TK.Commodity LIKE '%RU-IN%',Duty,0.0000)) AS DECIMAL(18,2))
        -- ,[Kelly_301China$]	= CAST(SUM(IIF(TK.SACKellyGlobal IN ('99038803','99038815'),Duty,0.0000)) AS DECIMAL(18,2))
        -- ,[Kelly_Fenta$]		= CAST(SUM(IIF(TK.SACKellyGlobal IN ('99030124','99030120'),Duty,0.0000)) AS DECIMAL(18,2))
        -- ,[Kelly_Recip$]		= CAST(SUM(IIF(TK.SACKellyGlobal IN ('99030125','99030163','99030184','99030205','99030226','99030243','99030251','99030253','99030260','99030261','99030264','99030269'),Duty,0.0000)) AS DECIMAL(18,2))
        ,[Kelly_301China$]	= CAST(SUM(IIF(KTC.Codigo IS NOT NULL AND Tarifa = '301 China',Duty,0.0000)) AS DECIMAL(18,2))
        ,[Kelly_Fenta$]		= CAST(SUM(IIF(KTC.Codigo IS NOT NULL AND Tarifa = 'Fentanylo',Duty,0.0000)) AS DECIMAL(18,2))
        ,[Kelly_Recip$]		= CAST(SUM(IIF(KTC.Codigo IS NOT NULL AND Tarifa = 'Reciprocal',Duty,0.0000)) AS DECIMAL(18,2))
        ,[Kelly_HTS$]		= CAST(SUM(IIF(TK.SACKellyGlobal = TTH.SACKellyGlobal,Duty,0.0000)) AS DECIMAL(18,2))
    FROM [dbo].[TB_Transfer_TablaKelly] AS TK WITH(NOLOCK)
    LEFT JOIN
    (
        SELECT DISTINCT  
            SACKellyGlobal			
        FROM AppsLCA.dbo.TB_Transfer_HTSTariff AS TTH WITH(NOLOCK)
        WHERE SACKellyGlobal NOT IN (
                                        '99030120'
                                        ,'99030124'
                                        ,'99030125'
                                        ,'99030163'
                                        ,'99030184'
                                        ,'99030205'
                                        ,'99030226'
                                        ,'99030243'
                                        ,'99030251'
                                        ,'99030253'
                                        ,'99030260'
                                        ,'99030261'
                                        ,'99030264'
                                        ,'99030269'
                                        ,'99038803'
                                        ,'99038815'
                                    )
    ) AS TTH ON TK.SACKellyGlobal = TTH.SACKellyGlobal
    LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_KellyTariffCodes] AS KTC WITH(NOLOCK) ON TK.SACKellyGlobal = KTC.Codigo
    GROUP BY
        -- CONCAT([Entry #],'-',CAST([Invoice #] as VARCHAR(10)))
         YEAR([Entry Date])
        ,MONTH([Entry Date])
        ,[Entry #]
        ,[Entry Date]
        ,[Invoice #]
        ,LEFT(MANUFID,2)
        -- ,[Origin]
) AS TB

SELECT *
INTO #TB_CI_New
FROM (
    SELECT
        --  [KeySearch]        = CONCAT([Entry#],'-',CAST([InvoiceKelly] as VARCHAR(10)))
        [YearEntry]        = YEAR([EntryDate])
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
        ,[CountryOfOrigin]  = ISNULL(CI.[CountryOfOrigin],'El Salvador')
        ,[CountryCode]      = CI.[CountryCode]
        ,[CI_TotalQty]      = SUM(CI.[Quantity])
        ,[CI_TotalFOB]      = SUM(CI.[CI_Total])    
        ,[CI_TotalPrice]    = SUM(CI.[TotalPrice])
        ,[Kelly_TotalQty]   = CAST(NULL AS DECIMAL(18,2))
        ,[Kelly_TotalFOB]   = CAST(NULL AS DECIMAL(18,2))
        ,[Kelly_TotalDuty]  = CAST(NULL AS DECIMAL(18,2))
        ,[Kelly_301China$]  = CAST(NULL AS DECIMAL(18,2))
        ,[Kelly_Fenta$]	    = CAST(NULL AS DECIMAL(18,2))
        ,[Kelly_Recip$]	    = CAST(NULL AS DECIMAL(18,2))
        ,[Kelly_HTS$]	    = CAST(NULL AS DECIMAL(18,2))
    FROM [dbo].[TB_Transfer_CuadreCI_KellyGlobal] AS CI WITH(NOLOCK)
    WHERE [EntryDate] <= '2025-11-10'
    GROUP BY
        --  CONCAT([Entry#],'-',CAST([InvoiceKelly] as VARCHAR(10)))
         YEAR([EntryDate])
        ,MONTH([EntryDate])
        ,CI.[Entry#]
        ,CI.[EntryDate]
        ,CI.[InvoiceKelly]
        ,CI.[WayBill]
        ,CASE 
            WHEN LEN(InvoiceKelly) - LEN(REPLACE(InvoiceKelly, ',', '')) = 2 THEN 3
            WHEN LEN(InvoiceKelly) - LEN(REPLACE(InvoiceKelly, ',', '')) = 1 THEN 2
            WHEN LEN(InvoiceKelly) - LEN(REPLACE(InvoiceKelly, ',', '')) = 0 THEN 1
         END
        ,CI.[TypeData]
        ,ISNULL(CI.[CountryOfOrigin],'El Salvador')
        ,CI.[CountryCode]
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
    -- ,[CountryCode]
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
        ,[CountryOfOrigin]  = [FAMOCountryOfOrigin] 
        -- ,[CountryCode]      = [CountryCode] 
        ,[New_TotalQty]     = CAST(SUM([QtyExport]) AS DECIMAL(18,2))
        ,[New_TotalFOB]     = CAST(SUM([KellyReport]) AS DECIMAL(18,2))
        ,[New_TotalDuty]    = CAST(SUM([T_Total_$]) AS DECIMAL(18,2))
        ,[New_301China$]    = CAST(SUM([TValue_301China_$]) AS DECIMAL(18,2))
        ,[New_Recip$]       = CAST(SUM([TValue_Recip_$]) AS DECIMAL(18,2))
        ,[New_Fenta$]       = CAST(SUM([TValue_Fenta_$]) AS DECIMAL(18,2))
        ,[New_HTS$]         = CAST(SUM([TValue_HTS_$]) AS DECIMAL(18,2))
        --select *
    FROM [dbo].[TB_Transfer_Validation_allExport] AS AE WITH(NOLOCK)
    WHERE [ExportDate] <= '2025-11-10'
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
        ,[FAMOCountryOfOrigin] 
        -- ,[CountryCode]

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
        -- ,[CountryCode]      = 'SV'
        ,[New_TotalQty]     = CAST(SUM([Qty]) AS DECIMAL(18,2))
        ,[New_TotalFOB]     = CAST(SUM([Total]) AS DECIMAL(18,2))
        ,[New_TotalDuty]    = 0.0000
        ,[New_301China$]    = 0.0000
        ,[New_Recip$]       = 0.0000
        ,[New_Fenta$]       = 0.0000
        ,[New_HTS$]         = 0.0000
    FROM #TB_WAYBILL_MATERIALS
    WHERE [Entry Date] <= '2025-11-10'
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
    -- ,[CountryCode]

UPDATE TBS SET
     [Kelly_TotalDuty] = ROUND(TBK.[TotalDutyKelly],2)
    ,[Kelly_TotalQty]  = ROUND(TBK.[TotalQtyKelly],2)
    ,[Kelly_TotalFOB]  = ROUND(TBK.[TotalFOBKelly],2)
    ,[Kelly_301China$] = ROUND(TBK.[Total301Kelly],2)
    ,[Kelly_Fenta$]	   = ROUND(TBK.[TotalFentaKelly],2)  
    ,[Kelly_Recip$]	   = ROUND(TBK.[TotalRecipKelly],2)
    ,[Kelly_HTS$]	   = ROUND(TBK.[TotalHTSKelly],2)
FROM #TB_CI_New AS TBS
-- FROM #TB_Summary AS TBS
LEFT JOIN
(
    SELECT 
        TBS.[Entry#]
        ,TBS.[EntryDate]
        ,TBS.[Invoice#]
        ,TBS.[CountryCode]
        ,TotalDutyKelly = SUM(
                            COALESCE(CASE
                                        WHEN TBS.[CountInvoice] = 1 THEN
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-',TBS.[Invoice#]) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalDuty],0),2)
                                                                        END
                                        WHEN TBS.[CountInvoice] = 2 THEN 
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,LEFT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalDuty],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,RIGHT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalDuty],0),2)
                                                                            ELSE 0
                                                                        END 
                                        WHEN TBS.[CountInvoice] = 3 THEN
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,LEFT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalDuty],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,TRIM(
                                                                                                                    SUBSTRING(TBS.[Invoice#]
                                                                                                                                ,CHARINDEX(',',TBS.[Invoice#])+1
                                                                                                                                ,CHARINDEX(',',TBS.[Invoice#]
                                                                                                                                            ,CHARINDEX(',',TBS.[Invoice#])+1
                                                                                                                                        ) - CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                            )
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalDuty],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,RIGHT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalDuty],0),2)
                                                                            ELSE 0
                                                                        END 
                                    END
                                ,0)
                            )
        ,TotalQtyKelly = SUM(
                            COALESCE(CASE
                                        WHEN TBS.[CountInvoice] = 1 THEN
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-',TBS.[Invoice#]) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalQty],0),2)
                                                                        END
                                        WHEN TBS.[CountInvoice] = 2 THEN 
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,LEFT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalQty],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,RIGHT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalQty],0),2)
                                                                            ELSE 0
                                                                        END 
                                        WHEN TBS.[CountInvoice] = 3 THEN
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,LEFT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalQty],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,TRIM(
                                                                                                                    SUBSTRING(TBS.[Invoice#]
                                                                                                                                ,CHARINDEX(',',TBS.[Invoice#])+1
                                                                                                                                ,CHARINDEX(',',TBS.[Invoice#]
                                                                                                                                            ,CHARINDEX(',',TBS.[Invoice#])+1
                                                                                                                                        ) - CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                            )
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalQty],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,RIGHT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalQty],0),2)
                                                                            ELSE 0
                                                                        END 
                                    END
                                ,0)
                            )
        ,TotalFOBKelly = SUM(
                            COALESCE(CASE
                                        WHEN TBS.[CountInvoice] = 1 THEN
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-',TBS.[Invoice#]) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalFOB],0),2)
                                                                        END
                                        WHEN TBS.[CountInvoice] = 2 THEN 
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,LEFT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalFOB],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,RIGHT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalFOB],0),2)
                                                                            ELSE 0
                                                                        END 
                                        WHEN TBS.[CountInvoice] = 3 THEN
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,LEFT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalFOB],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,TRIM(
                                                                                                                    SUBSTRING(TBS.[Invoice#]
                                                                                                                                ,CHARINDEX(',',TBS.[Invoice#])+1
                                                                                                                                ,CHARINDEX(',',TBS.[Invoice#]
                                                                                                                                            ,CHARINDEX(',',TBS.[Invoice#])+1
                                                                                                                                        ) - CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                            )
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalFOB],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,RIGHT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalFOB],0),2)
                                                                            ELSE 0
                                                                        END 
                                    END
                                ,0)
                            )
        ,Total301Kelly = SUM(
                            COALESCE(CASE
                                        WHEN TBS.[CountInvoice] = 1 THEN
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-',TBS.[Invoice#]) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Total301],0),2)
                                                                        END
                                        WHEN TBS.[CountInvoice] = 2 THEN 
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,LEFT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Total301],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,RIGHT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Total301],0),2)
                                                                            ELSE 0
                                                                        END 
                                        WHEN TBS.[CountInvoice] = 3 THEN
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,LEFT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Total301],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,TRIM(
                                                                                                                    SUBSTRING(TBS.[Invoice#]
                                                                                                                                ,CHARINDEX(',',TBS.[Invoice#])+1
                                                                                                                                ,CHARINDEX(',',TBS.[Invoice#]
                                                                                                                                            ,CHARINDEX(',',TBS.[Invoice#])+1
                                                                                                                                        ) - CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                            )
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Total301],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,RIGHT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[Total301],0),2)
                                                                            ELSE 0
                                                                        END 
                                    END
                                ,0)
                            )
        ,TotalFentaKelly = SUM(
                            COALESCE(CASE
                                        WHEN TBS.[CountInvoice] = 1 THEN
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-',TBS.[Invoice#]) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalFenta],0),2)
                                                                        END
                                        WHEN TBS.[CountInvoice] = 2 THEN 
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,LEFT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalFenta],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,RIGHT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalFenta],0),2)
                                                                            ELSE 0
                                                                        END 
                                        WHEN TBS.[CountInvoice] = 3 THEN
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,LEFT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalFenta],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,TRIM(
                                                                                                                    SUBSTRING(TBS.[Invoice#]
                                                                                                                                ,CHARINDEX(',',TBS.[Invoice#])+1
                                                                                                                                ,CHARINDEX(',',TBS.[Invoice#]
                                                                                                                                            ,CHARINDEX(',',TBS.[Invoice#])+1
                                                                                                                                        ) - CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                            )
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalFenta],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,RIGHT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalFenta],0),2)
                                                                            ELSE 0
                                                                        END 
                                    END
                                ,0)
                            )
        ,TotalRecipKelly = SUM(
                            COALESCE(CASE
                                        WHEN TBS.[CountInvoice] = 1 THEN
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-',TBS.[Invoice#]) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalRecip],0),2)
                                                                        END
                                        WHEN TBS.[CountInvoice] = 2 THEN 
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,LEFT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalRecip],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,RIGHT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalRecip],0),2)
                                                                            ELSE 0
                                                                        END 
                                        WHEN TBS.[CountInvoice] = 3 THEN
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,LEFT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalRecip],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,TRIM(
                                                                                                                    SUBSTRING(TBS.[Invoice#]
                                                                                                                                ,CHARINDEX(',',TBS.[Invoice#])+1
                                                                                                                                ,CHARINDEX(',',TBS.[Invoice#]
                                                                                                                                            ,CHARINDEX(',',TBS.[Invoice#])+1
                                                                                                                                        ) - CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                            )
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalRecip],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,RIGHT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalRecip],0),2)
                                                                            ELSE 0
                                                                        END 
                                    END
                                ,0)
                            )
        ,TotalHTSKelly = SUM(
                            COALESCE(CASE
                                        WHEN TBS.[CountInvoice] = 1 THEN
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-',TBS.[Invoice#]) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalHTS],0),2)
                                                                        END
                                        WHEN TBS.[CountInvoice] = 2 THEN 
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,LEFT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalHTS],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,RIGHT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalHTS],0),2)
                                                                            ELSE 0
                                                                        END 
                                        WHEN TBS.[CountInvoice] = 3 THEN
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,LEFT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalHTS],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,TRIM(
                                                                                                                    SUBSTRING(TBS.[Invoice#]
                                                                                                                                ,CHARINDEX(',',TBS.[Invoice#])+1
                                                                                                                                ,CHARINDEX(',',TBS.[Invoice#]
                                                                                                                                            ,CHARINDEX(',',TBS.[Invoice#])+1
                                                                                                                                        ) - CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                            )
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalHTS],0),2)
                                                                            ELSE 0
                                                                        END 
                                                                        +
                                                                        CASE
                                                                            WHEN CONCAT(TBS.[Entry#],'-'
                                                                                                            ,RIGHT(TBS.[Invoice#]
                                                                                                                    ,CHARINDEX(',',TBS.[Invoice#])-1
                                                                                                                )
                                                                                        ) = TBK.[KeySearch] THEN ROUND(COALESCE(TBK.[TotalHTS],0),2)
                                                                            ELSE 0
                                                                        END 
                                    END
                                ,0)
                            )
                            
    -- FROM #TB_Summary AS TBS
    FROM #TB_CI_New AS TBS
    LEFT JOIN
    (
         SELECT
             [Entry#]       = TBK.[Entry#]
            ,[EntryDate]    = TBK.[EntryDate]
            ,[Invoice#]     = TBK.[Invoice#]
            ,[KeySearch]    = TBK.[KeySearch]
            ,[CountryCode]  = TBK.[CountryCode]
            ,[TotalQty]     = SUM(TBK.Kelly_TotalQty)
            ,[TotalFOB]     = SUM(TBK.Kelly_TotalFOB)
            ,[TotalDuty]    = SUM(TBK.Kelly_TotalDuty)
            ,[Total301]     = SUM(TBK.Kelly_301China$)
            ,[TotalFenta]   = SUM(TBK.Kelly_Fenta$)
            ,[TotalRecip]   = SUM(TBK.Kelly_Recip$)
            ,[TotalHTS]     = SUM(TBK.Kelly_HTS$)
        FROM #TB_Kelly_New AS TBK
        GROUP BY
             TBK.[Entry#]
            ,TBK.[EntryDate]
            ,TBK.[Invoice#]
            ,TBK.[KeySearch]
            ,TBK.[CountryCode]
    ) AS TBK ON TBK.[Entry#] = TBS.[Entry#] AND TBK.[EntryDate] = TBS.[EntryDate] AND TBK.[CountryCode] = TBS.[CountryCode]
    -- WHERE tbs.[Entry#] = 'BHE04228579'
    GROUP BY
    TBS.[Entry#]
    ,TBS.[EntryDate]
    ,TBS.[Invoice#]
    ,TBS.[CountryCode]
) AS TBK ON TBS.[Entry#] = TBK.[Entry#] AND TBS.[EntryDate] = TBK.[EntryDate] AND TBS.[Invoice#] = TBK.[Invoice#] AND TBK.[CountryCode] = TBS.[CountryCode]
-- SELECT * FROM AppsLCA.dbo.TB_Transfer_Waybill_Void

UPDATE TBS SET
    Kelly_TotalQty = (Kelly_TotalQty / 2) - 34
    ,Kelly_TotalFOB = (Kelly_TotalFOB / 2) - 526.66
FROM #TB_CI_New AS TBS
WHERE Waybill = '20240112'

UPDATE TBS SET
    Kelly_TotalQty = 34
    ,Kelly_TotalFOB = 526.66
FROM #TB_CI_New AS TBS
WHERE Waybill = '20240112-1'

UPDATE TBS SET
    Kelly_TotalQty = (Kelly_TotalQty / 2) - 12
    ,Kelly_TotalFOB = (Kelly_TotalFOB / 2) - 209.88
    ,Kelly_TotalDuty = (Kelly_TotalDuty / 2) - 19.56
    ,Kelly_HTS$     = (Kelly_HTS$ / 2) - 19.56
FROM #TB_CI_New AS TBS
WHERE Waybill = '20240112-NONCAFTA'

UPDATE TBS SET
    Kelly_TotalQty = 12
    ,Kelly_TotalFOB = 209.88
    ,Kelly_TotalDuty = 19.56
    ,Kelly_HTS$     = 19.56
FROM #TB_CI_New AS TBS
WHERE Waybill = '20240112-NONCAFTA-1'

UPDATE TBS SET
    Kelly_TotalQty = (Kelly_TotalQty / 2) - 40
    ,Kelly_TotalFOB = (Kelly_TotalFOB / 2) - 288
FROM #TB_CI_New AS TBS
WHERE Waybill = 'MASTER20240131-1'

UPDATE TBS SET
    Kelly_TotalQty = 40
    ,Kelly_TotalFOB = 288
FROM #TB_CI_New AS TBS
WHERE Waybill = 'MASTER20240131-2'

SELECT
*
FROM #TB_CI_New
RETURN

-- select * from #TB_CI_New
-- where Entry# = 'BHE04206898'

SELECT
     [YearEntry]                = COALESCE(TBC.[YearEntry], TBA.[YearEntry])
    ,[MonthEntry]               = COALESCE(TBC.[MonthEntry], TBA.[MonthEntry])
    -- ,[OriginalTariffCategory]   = TBC.[TypeData]
    ,[NewTariffCategory]        = TBA.[TariffCategory]
    ,[Entry#]                   = COALESCE(TBC.[Entry#], TBA.[Entry#])
    ,[EntryDate]                = COALESCE(TBC.[EntryDate], TBA.[EntryDate])
    ,[WayBill]                  = COALESCE(TBC.[WayBill], TBA.[Waybill])
    ,[OriginalCOO]              = TBC.[CountryOfOrigin]
    ,[NewCOO]                   = TBA.[CountryOfOrigin]
    -- ,[Kelly_TotalQty]           = TBC.[Kelly_TotalQty]
    -- ,[Kelly_TotalFOB]           = TBC.[Kelly_TotalFOB]
    -- ,[Kelly_TotalDuty]          = TBC.[Kelly_TotalDuty]
    -- ,[Kelly_301China$]          = TBC.[Kelly_301China$]
    -- ,[Kelly_Fenta$]             = TBC.[Kelly_Fenta$]
    -- ,[Kelly_Recip$]             = TBC.[Kelly_Recip$]
    -- ,[Kelly_HTS$]               = TBC.[Kelly_HTS$]
    ,[New_TotalQty]             = TBA.[New_TotalQty]
    ,[New_TotalFOB]             = TBA.[New_TotalFOB]
    -- ,[New_TotalDuty]            = TBA.[New_TotalDuty]
    -- ,[New_301China$]            = TBA.[New_301China$]        
    -- ,[New_Fenta$]               = TBA.[New_Fenta$]    
    -- ,[New_Recip$]               = TBA.[New_Recip$]    
    -- ,[New_HTS$]                 = TBA.[New_HTS$]
    -- ,[NewDrawBack]              = ISNULL(TBA.[New_TotalDuty],0) - ISNULL(TBC.[Kelly_TotalDuty],0.00)
    -- ,[DrawBack301China]         = ISNULL(TBA.[New_301China$],0) - ISNULL(TBC.[Kelly_301China$],0.00)
    -- ,[DrawBackFenta]            = ISNULL(TBA.[New_Fenta$],0) - ISNULL(TBC.[Kelly_Fenta$],0.00)
    -- ,[DrawBackRecip]            = ISNULL(TBA.[New_Recip$],0) - ISNULL(TBC.[Kelly_Recip$],0.00)
    -- ,[DrawBackHTS]              = ISNULL(TBA.[New_HTS$],0) - ISNULL(TBC.[Kelly_HTS$],0.00)
    ,[CI_TotalQty]              = TBC.[CI_TotalQty]
    ,[CI_TotalFOB]              = TBC.[CI_TotalFOB]
    ,[CI_TotalPrice]            = TBC.[CI_TotalPrice]
INTO #TB_Summary
FROM #TB_CI_New AS TBC
FULL JOIN #TB_AllExport_New AS TBA ON TBA.[Entry#] = TBC.[Entry#] AND TBA.[EntryDate] = TBC.[EntryDate] AND TBA.Waybill = TBC.Waybill AND TBC.CountryOfOrigin = TBA.CountryOfOrigin --AND TBC.TypeData = TBA.TariffCategory
ORDER BY 
     COALESCE(TBC.[YearEntry], TBA.[YearEntry])
    ,COALESCE(TBC.[MonthEntry], TBA.[MonthEntry])

SELECT *
FROM #TB_Summary

return

SELECT *
FROM #TB_Summary
where WayBill = 'AIR-BUND-20240709'

SELECT *
FROM #TB_AllExport_New
where WayBill = 'AIR-BUND-20240709'

select * from #TB_AllExport_New where Waybill = 'AIR-APP-20240927'
select * from #TB_Summary where Waybill = 'AIR-APP-20240927'
select * from #TB_CI_New where Waybill in 
(
'AIR-APP-20250930'
)

RETURN
-- UPDATE TBS SET
--      [CI_TotalQty]      = TBC.[CI_TotalQty]
--     ,[CI_TotalFOB]      = TBC.[CI_TotalFOB]
--     ,[Kelly_TotalQty]   = TBC.[Kelly_TotalQty]
--     ,[Kelly_TotalFOB]   = TBC.[Kelly_TotalFOB]
--     ,[Kelly_TotalDuty]  = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN #TB_CI_New AS TBC ON TBS.[Entry#] = TBC.[Entry#] AND TBS.[EntryDate] = TBC.[EntryDate] AND TBS.Waybill = TBC.Waybill
-- WHERE TBS.Kelly_TotalQty IS NULL
-- AND TBS.Waybill IN (
--     select distinct waybill
--     from
--     (
--         SELECT DISTINCT Waybill, sum(Kelly_Tota  lQty) as qty
--         FROM #TB_Summary group by Waybill
--     ) as tb where qty  is null
-- )

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = '20240223'
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = 'AIR-LCA-20240523-CAFTA'
--     -- AND CountInvoice = 2
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NOT NULL

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = '2-LCA-20240524-CAFTA'
--     -- AND Invoice# = 5
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NOT NULL

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = 'AIR-LCA-20240530-CAFTA'
--     -- AND Invoice# = 4
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NOT NULL

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = 'LCA-20240529-CAFTA'
--     -- AND Invoice# = 2
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NOT NULL

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = 'AIR-LCA-20240604-CAFTA'
--     -- AND Invoice# = 2
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NOT NULL

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = 'AIR-LCA-20240605-CAFTA'
--     -- AND Invoice# = 2
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NOT NULL

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = 'AIR-LCA-20240607-CAFTA'
--     -- AND Invoice# = 2
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NOT NULL

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = 'AIR-LCA-20240613-CAFTA'
--     -- AND Invoice# = 2
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NOT NULL

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = 'AIR-LCA-20240621-CAFTA'
--     -- AND Invoice# = 2
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NOT NULL

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = 'LCA-20240621-CAFTA'
--     -- AND Invoice# = 2
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NOT NULL

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = 'LCA-20240620-CAFTA'
--     -- AND Invoice# = 2
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NOT NULL

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = 'AIR-SMS-20240920'
--     -- AND Invoice# = 2
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NOT NULL

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = 'AIR-APP-20241112'
--     AND Invoice# = '3'
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NULL

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = 'APP-20241114'
--     AND Invoice# = '3'
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NULL

-- UPDATE TBS SET
--     Kelly_TotalQty      = TBC.[Kelly_TotalQty]
--     ,Kelly_TotalFOB     = TBC.[Kelly_TotalFOB]
--     ,Kelly_TotalDuty    = TBC.[Kelly_TotalDuty]
-- FROM #TB_Summary AS TBS
-- INNER JOIN (
--     SELECT
--          Waybill
--         ,[Kelly_TotalQty]   = SUM(Kelly_TotalQty) 
--         ,[Kelly_TotalFOB]   = SUM(Kelly_TotalFOB)
--         ,[Kelly_TotalDuty]  = SUM(Kelly_TotalDuty)
--     FROM #TB_CI_New
--     WHERE Waybill = 'AIR-SMS-20250131'
--     -- AND Invoice# = '3'
--     GROUP BY
--         Waybill
-- ) AS TBC ON TBS.Waybill = TBC.Waybill AND Invoice# IS NOT NULL

-- UPDATE TBS SET
--     [NewDrawBack] = TBS.[New_TotalDuty] - ISNULL(TBS.[Kelly_TotalDuty],0.00)
-- FROM #TB_Summary AS TBS
-- WHERE TariffCategory <> 'MATERIALS'

-- UPDATE TBS SET
--     TBS.TariffCategory = TWM.InvoiceLCA
-- FROM #TB_Summary AS TBS
-- INNER JOIN #TB_WAYBILL_MATERIALS AS TWM ON TBS.Waybill = TWM.Waybill AND TBS.TariffCategory = 'MATERIALS'
-- return
-- INSERT INTO AppsLCA.dbo.TB_Transfer_SummaryNewCIKelly
-- SELECT * FROM #TB_Summary WHERE WayBill = 'AIR-BUND-20240724'

SELECT * FROM #TB_CI_New WHERE Entry# = 'BHE04203689' 

DROP TABLE IF EXISTS AppsLCA.dbo.TB_Transfer_SummaryNewCIKelly

SELECT * 
INTO AppsLCA.dbo.TB_Transfer_SummaryNewCIKelly
FROM #TB_Summary
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