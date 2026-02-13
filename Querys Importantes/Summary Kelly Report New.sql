USE AppsLCA

DROP TABLE IF EXISTS #TB_Kelly_New
DROP TABLE IF EXISTS #TB_CI_New
DROP TABLE IF EXISTS #TB_AllExport_New
DROP TABLE IF EXISTS #TB_Summary

SELECT *
INTO #TB_Kelly_New
FROM(
    SELECT
        --  [KeySearch]        = CONCAT([Entry #],'-',CAST([Invoice #] as VARCHAR(10)))
        ,[YearEntry]        = YEAR([Entry Date])
        ,[MonthEntry]       = MONTH([Entry Date])
        ,[Entry#]           = [Entry #]
        ,[EntryDate]        = [Entry Date]
        ,[Invoice#]         = [Invoice #]
        ,[Kelly_TotalQty]   = CAST(SUM(QtyTotal) AS DECIMAL(18,2))
        ,[Kelly_TotalFOB]   = CAST(SUM(IIF(Flag = 1, [Value], 0.00)) AS DECIMAL(18,2))
        ,[Kelly_TotalDuty]  = CAST(SUM(Duty) AS DECIMAL(18,2))
    FROM [dbo].[TB_Transfer_TablaKelly] AS TK WITH(NOLOCK)
    GROUP BY
        -- CONCAT([Entry #],'-',CAST([Invoice #] as VARCHAR(10)))
         YEAR([Entry Date])
        ,MONTH([Entry Date])
        ,[Entry #]
        ,[Invoice #]
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
        ,[CI_TotalQty]      = SUM(CI.[Quantity])
        ,[CI_TotalFOB]      = SUM(CI.[CI_Total])    
        ,[CI_TotalPrice]    = SUM(CI.[TotalPrice])
    FROM [dbo].[TB_Transfer_CuadreCI_KellyGlobal] AS CI WITH(NOLOCK)
    GROUP BY
        --  CONCAT([Entry#],'-',CAST([InvoiceKelly] as VARCHAR(10)))
         YEAR([EntryDate])
        ,MONTH([EntryDate])
        ,CI.[Entry#]
        ,CI.[EntryDate]
        ,CI.[InvoiceKelly]
) AS TB

SELECT *
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
        ,[New_TotalQty]     = CAST(SUM([QtyExport]) AS DECIMAL(18,2))
        ,[New_TotalFOB]     = CAST(SUM([KellyReport]) AS DECIMAL(18,2))
        ,[Kelly_TotalDuty]  = CAST(SUM([T_Total_$]) AS DECIMAL(18,2))
    FROM [dbo].[TB_Transfer_Validation_allExport] AS AE WITH(NOLOCK)
    WHERE [Entry #] NOT LIKE '%BHE04309999%'
    GROUP BY
        --  CONCAT([Entry #],'-',CAST([InvoiceKelly] as VARCHAR(10)))
         [Year_ExportDate]
        ,[Month_ExportDate]
        ,[Entry #]
        ,[ExportDate]
        ,[InvoiceKelly]
) AS TB
