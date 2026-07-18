DROP TABLE IF EXISTS #TB_Entry_Kelly
DROP TABLE IF EXISTS #TB_CommercialInvoice
DROP TABLE IF EXISTS #PIV_EntryKelly
DROP TABLE IF EXISTS #TB_Units_Invoiced

select 
     RIGHT(
            ei.invoice_code,
            LEN(ei.invoice_code) - CHARINDEX('/', ei.invoice_code)
            ) as invoice
    ,el.htsus
    ,COALESCE(tc.Tarifa,'HTS') AS Tarifa
    ,el.[description]
    ,el.rate
    ,sum(el.entered_value) as entered_value
    ,sum(el.duty) as Duty_Entry
into #TB_Entry_Kelly
--SELECT *
from AppsLCA.dbo.entry_lines as el with(nolock)
inner join AppsLCA.dbo.entry_invoices as ei with(nolock)
    ON el.invoice_id = ei.id
inner join AppsLCA.dbo.entry_documents as ed with(nolock)
    ON ei.document_id = ed.id
left join AppsLCA.dbo.TB_Transfer_KellyTariffCodes as tc with(nolock)
    ON tc.Codigo = REPLACE(el.htsus,'.','')
WHERE el.duty IS NOT NULL AND el.htsus IS NOT NULL 
group by
     RIGHT(
        ei.invoice_code,
        LEN(ei.invoice_code) - CHARINDEX('/', ei.invoice_code)
        )
    ,el.htsus
    ,tc.Tarifa
    ,el.[description]
    ,el.rate
    -- ,el.entered_value
ORDER BY invoice

SELECT 
    [R] = ROW_NUMBER() OVER(ORDER BY TB.[R_Order],TB.[Line] , TB.[InvoicingDescription], TB.[Manufacturer])
    , [Line] = TB.[Line]
    , TB.[DocumentID]
    , TB.[InvoicingDescription]
    , TB.[US_HTSCode]
    , TB.[Manufacturer]
    , TB.[Orden]
    , TB.[Quantity]
    , TB.[QuantityDoz]
    , TB.[TotalPrice]
    , TB.[TotalBlankPrice]
    , TB.[TotalFobValue]
    , TB.[DecorationValue]
    , TB.[TariffCategory]
    , TB.[Waybill]
    , [Rate_Tariff122]  = CAST(NULL AS DECIMAL(18,4))
    , [Rate_301China]   = CAST(NULL AS DECIMAL(18,4))
    , [Rate_Reciprocal] = CAST(NULL AS DECIMAL(18,4))
    , [Rate_Fentanylo]  = CAST(NULL AS DECIMAL(18,4))
    , [$_Tariff122]     = CAST(NULL AS DECIMAL(18,2))
    , [$_301China]      = CAST(NULL AS DECIMAL(18,2))
    , [$_Reciprocal]    = CAST(NULL AS DECIMAL(18,2))
    , [$_Fentanylo]     = CAST(NULL AS DECIMAL(18,2))
INTO #TB_CommercialInvoice
FROM
(
    SELECT
        [R_Order] = CI.[Orden]  -- SOLO PARA ORDEN GLOBAL, NO ES Line
        , [Line]                 = CI.[LineGroupKelly]
        , [DocumentID]           = CI.[DocumentID]  
        , [InvoicingDescription] = CI.[InvoicingGroupKelly]                
        , [US_HTSCode]           = COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
        , [Manufacturer]         = CONCAT(CI.[Manufacturer], '/', CI.[CountryOfOrigin])
        , [Orden]                = CI.[Orden]
        , [Quantity]             = SUM(CI.[Quantity])
        , [QuantityDoz]          = IIF(SUM(CI.[Quantity] / 12) < 1,ROUND(CEILING(SUM(CI.[Quantity]) / 12),0),ROUND(SUM(CI.[Quantity]) / 12, 0))
        , [TotalPrice]           = SUM(CI.[TotalPrice])
        , [TotalBlankPrice]      = SUM(CI.[TotalBlankPrice])
        , [TotalFobValue]        = SUM(CI.[TotalFobValue])
        , [DecorationValue]      = SUM(CI.[TotalDecorationValue])
        , [TariffCategory]       = IIF(CI.[Orden] = 1, 'CAFTA', 'NO CAFTA')
        , [Waybill]              = CI.[Waybill]
        --select *
    FROM (SELECT DISTINCT invoice FROM #TB_Entry_Kelly) AS TEK
    INNER JOIN [192.168.1.93].appslca.dbo.CI_Import_Export_CommercialInvoice AS CI WITH(NOLOCK) ON TEK.[invoice] = CI.[DocumentID]
    -- WHERE CI.[Waybill] IN (@WayBill)
    GROUP BY  
            CI.[LineGroupKelly]
        , CI.[DocumentID]
        , CI.[InvoicingGroupKelly]
        , COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
        , CONCAT(CI.[Manufacturer], '/', CI.[CountryOfOrigin])
        , CI.[Orden]
        , IIF(CI.[Orden] = 1, 'CAFTA', 'NO CAFTA')
        , CI.[Waybill]

    UNION ALL

    SELECT
        [R_Order] = CI.[Orden]
        , [Line]                 = CI.[LineGroupKelly]
        , [DocumentID]           = CI.[DocumentID]  
        , [InvoicingDescription] = CI.[InvoicingGroupKelly]    
        , [US_HTSCode]           = COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])    
        , [Manufacturer]         = CONCAT(CI.[Manufacturer], '/', CI.[CountryOfOrigin])
        , [Orden]                = CI.[Orden]   
        , [Quantity]             = SUM(CI.[Quantity])
        , [QuantityDoz]          = IIF(SUM(CI.[Quantity] / 12) < 1,ROUND(CEILING(SUM(CI.[Quantity]) / 12),0),ROUND(SUM(CI.[Quantity]) / 12, 0))
        , [TotalPrice]           = SUM(CI.[TotalPrice])
        , [TotalBlankPrice]      = SUM(CI.[TotalBlankPrice])
        , [TotalFobValue]        = SUM(CI.[TotalFobValue])
        , [DecorationValue]      = SUM(CI.[TotalDecorationValue])
        , [TariffCategory]       = 'NO CAFTA RULE 9802'
        , [Waybill]              = CI.[Waybill]
    FROM (SELECT DISTINCT invoice FROM #TB_Entry_Kelly) AS TEK
    INNER JOIN [192.168.1.93].appslca.dbo.CI_Import_Export_DeclarationExport AS CI WITH(NOLOCK) ON TEK.[invoice] = CI.[DocumentID]
    -- WHERE CI.[Waybill] IN (@WayBill)
    GROUP BY
            CI.[LineGroupKelly]
        , CI.[DocumentID]
        , CI.[InvoicingGroupKelly]
        , COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
        , CONCAT(CI.[Manufacturer], '/', CI.[CountryOfOrigin])
        , CI.[Orden]
        , CI.[Waybill]
) AS TB

SELECT
     IWT.*
    ,[DocumentID]       = CAST(NULL AS VARCHAR(200))
    ,[Rate_Tariff122]   = CAST(NULL AS DECIMAL(18,4))
    ,[Rate_301China]    = CAST(NULL AS DECIMAL(18,4))
    ,[Rate_Reciprocal]  = CAST(NULL AS DECIMAL(18,4))
    ,[Rate_Fentanylo]   = CAST(NULL AS DECIMAL(18,4))
    ,[$_KGLTariff122]   = CAST(NULL AS DECIMAL(18,2))
    ,[$_KGL301China]    = CAST(NULL AS DECIMAL(18,2))
    ,[$_KGLReciprocal]  = CAST(NULL AS DECIMAL(18,2))
    ,[$_KGLFentanylo]   = CAST(NULL AS DECIMAL(18,2))
INTO #TB_Units_Invoiced
FROM (SELECT DISTINCT Waybill  FROM #TB_CommercialInvoice) AS CI
INNER JOIN [AppsLCA].[legacycaps].[TB_L2Brands_Units_Invoiced_WithTariffs] AS IWT WITH(NOLOCK) ON CI.[Waybill] = IWT.[Waybill]

UPDATE UI SET
    [DocumentID] = CI.[DocumentID]
FROM #TB_Units_Invoiced AS UI
INNER JOIN (SELECT DISTINCT DocumentID, TariffCategory, Waybill FROM #TB_CommercialInvoice) AS CI ON UI.[Waybill] = CI.[Waybill] AND UI.[TariffCategory] = CI.[TariffCategory]

select * from #TB_CommercialInvoice

SELECT
     invoice
    ,[Tariff 122]
    ,[301 China]
    ,[Reciprocal]
    ,[Fentanylo]
INTO #PIV_EntryKelly
FROM
(
    SELECT invoice, Duty_Entry, Tarifa
    FROM #TB_Entry_Kelly 
    WHERE Tarifa <> 'HTS'
) AS origen
PIVOT
(
    SUM(Duty_Entry)
    FOR Tarifa IN ([Tariff 122], [301 China], [Reciprocal], [Fentanylo])
) AS pivote;

UPDATE A SET
-- select *,
     [Rate_Tariff122]  = ISNULL(B.[Tariff 122],0.0000) / C.[Quantity]
    ,[Rate_301China]   = ISNULL(B.[301 China], 0.0000) / C.[Quantity]
    ,[Rate_Reciprocal] = ISNULL(B.[Reciprocal],0.0000) / C.[Quantity]
    ,[Rate_Fentanylo]  = ISNULL(B.[Fentanylo], 0.0000) / C.[Quantity]
FROM #TB_CommercialInvoice AS A
INNER JOIN
(
    SELECT
        invoice
        ,[Tariff 122]
        ,[301 China]
        ,[Reciprocal]
        ,[Fentanylo]
    FROM #PIV_EntryKelly 
) AS B ON A.[DocumentID] = B.[invoice]
INNER JOIN
(
    SELECT 
        DocumentID
        -- ,US_HTSCode
        ,SUM(Quantity) AS Quantity
        ,ROUND(SUM(CASE WHEN Orden = 3 THEN DecorationValue ELSE TotalFobValue END),0) AS Entered_Value
    FROM #TB_CommercialInvoice 
    -- WHERE DocumentID = 'AIR-APP-20260513.9802'
    GROUP BY
        DocumentID
) AS C ON A.[DocumentID] = C.[DocumentID]

UPDATE A SET
-- select *,
     [Rate_Tariff122] = ISNULL(B.[Tariff 122],0.0000) / C.[Quantity]
    ,[Rate_301China]  = ISNULL(B.[301 China], 0.0000) / C.[Quantity]
    ,[Rate_Reciprocal] = ISNULL(B.[Reciprocal],0.0000) / C.[Quantity]
    ,[Rate_Fentanylo]  = ISNULL(B.[Fentanylo], 0.0000) / C.[Quantity]
FROM #TB_Units_Invoiced AS A
INNER JOIN
(
    SELECT
        invoice
        ,[Tariff 122]
        ,[301 China]
        ,[Reciprocal]
        ,[Fentanylo]
    FROM #PIV_EntryKelly 
) AS B ON A.[DocumentID] = B.[invoice]
INNER JOIN
(
    SELECT 
        DocumentID
        -- ,US_HTSCode
        ,SUM(Quantity) AS Quantity
        ,ROUND(SUM(CASE WHEN TariffCategory = 'NO CAFTA RULE 9802' THEN (Decoration_Invoiced_Price * Quantity) ELSE FOBTotal END),0) AS Entered_Value
    FROM #TB_Units_Invoiced 
    -- WHERE DocumentID = 'AIR-APP-20260513.9802'
    GROUP BY
        DocumentID
) AS C ON A.[DocumentID] = C.[DocumentID]

UPDATE TC SET
     [$_Tariff122] = [Quantity] * [Rate_Tariff122]
    ,[$_301China]  = [Quantity] * [Rate_301China]
FROM #TB_CommercialInvoice AS TC

UPDATE TC SET
     [$_KGLTariff122] = [Quantity] * [Rate_Tariff122]
    ,[$_KGL301China]  = [Quantity] * [Rate_301China]
FROM #TB_Units_Invoiced AS TC

SELECT
    CI.[DocumentID]
    ,ek.[invoice]
    ,CI.[$_Calc_Tariff122]
    ,CI.[Tariff122_Estimated]
    ,ISNULL(EK.[Tariff 122],0) AS [Tariff 122]
    ,CI.[$_Calc_301China]
    ,CI.[Tariff122_Estimated]
    ,ISNULL(EK.[301 China],0) AS [301 China]
    ,CI.[$_Calc_Tariff122] - ISNULL(EK.[Tariff 122],0) diff_122_CalcVSReal
    ,CI.[$_Calc_301China] - ISNULL(EK.[301 China],0) diff_301_CalcVSReal
    ,CI.[Tariff122_Estimated] - ISNULL(EK.[Tariff 122],0) diff_122_EstimVSReal
    ,CI.[301China_Estimated] - ISNULL(EK.[301 China],0) diff_301_EstimVSReal
FROM
(
    SELECT 
        [DocumentID]
        ,[TotalFobValue]        = SUM(IIF(TariffCategory = 'NO CAFTA RULE 9802', (Decoration_Invoiced_Price * Quantity), FOBTotal)) 
        ,[$_Calc_Tariff122]     = SUM([$_KGLTariff122])
        ,[$_Calc_301China]      = SUM([$_KGL301China])
        ,[Tariff122_Estimated]  = SUM([Tariff122_Tariff])
        ,[301China_Estimated]   = SUM([301China_Tariff])
    FROM #TB_Units_Invoiced AS CI
    GROUP BY
        [DocumentID]
) AS CI
FULL JOIN #PIV_EntryKelly AS EK ON CI.[DocumentID] = EK.[invoice]
WHERE ci.[DocumentID] IS NOT NULL
ORDER BY [DocumentID]

RETURN
SELECT
     [invoice]
    ,[TotalFobValue]    = SUM(IIF([Tarifa] = 'HTS',entered_value,0.00)) 
    ,[$_Tariff122]      = SUM(IIF([Tarifa] = 'Tariff 122',[Duty_Entry],0.00))
    ,[$_301China]       = SUM(IIF([Tarifa] = '301 China',[Duty_Entry],0.00))
FROM #TB_Entry_Kelly
GROUP BY 
    [invoice]
ORDER BY [invoice]

SELECT * FROM #TB_CommercialInvoice WHERE DocumentID = 'AIR-APP-20260513.9802'
SELECT * FROM #TB_Entry_Kelly WHERE invoice = 'AIR-APP-20260513.9802'