USE [AppsLCA]
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------SP PARA L2B INVOICE LCA WITH TARIFFS-----------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----Que hace este script
------1) Carga embarques desde '2025-01-01' en tabla temporal #TB_Prices.
------2) Inserta en #TB_Bill solo columnas directas de AF (INSERT liviano, sin JOINs pesados).
------3) Calcula campos derivados de otras tablas via UPDATEs independientes:
-----------  UPDATE A: TariffCategory, CountryOfOrigin  (TE + TB_MO_Key1..5 + TB_MO_2)
-----------  UPDATE B: MO, US_HTSCode, ProductDivision  (TMO_APri -> ODT_PRI -> ST -> HTS + LMN)
-----------  UPDATE C: Entry#, EntryDate, ExportDate, TypeExport  (WaybillEntry)
-----------  UPDATE D: Porcentajes y montos de tarifa  (TariffCOO + HTSTariff)
------4) Carga lookups de inventario L2B y PO en tablas temporales.
------5) Construye el resultado final y lo guarda en AppsLCA.legacycaps.TB_L2Brands_Units_Invoiced_WithTariffs.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE [dbo].[SP_L2Brands_Units_Invoiced_WithTariffs_Ver2]
(
    @Waybill NVARCHAR(200)
)
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #TB_Prices;
    DROP TABLE IF EXISTS #TB_Bill;
    DROP TABLE IF EXISTS #TB_MOS_FOR_SUMMARY_GROUP;
    DROP TABLE IF EXISTS #TB_FAMO_SUMMARY;
    DROP TABLE IF EXISTS #TB_L2BrandInv;
    DROP TABLE IF EXISTS #TB_Orders;

    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] SP iniciado.';

    -----------------------------------------------------------------------------------------
    -- 1. Embarques a considerar  (#TB_Prices = CTE_Prices)
    -----------------------------------------------------------------------------------------
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] Paso 1: Cargando #TB_Prices (embarques desde 2025-01-01)...';
    SELECT
         [ID]       = SCP.[ID]
        ,[Waybill]  = ISNULL(SCP.[Waybill], AF.[Waybill])
        ,[ShipDate] = ISNULL(SCP.[ShipDate], AF.[ShipDate])
    INTO #TB_Prices
    FROM
    (
        SELECT DISTINCT
             [Waybill]  = AF.[Waybill]
            ,[ShipDate] = AF.[ShipDate]
        FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH (NOLOCK)
        WHERE Waybill = @Waybill
          AND ShipDate >= '2025-01-01'
          AND StyleNumber NOT IN ('-','Fabric','Trim','Supplies','SWATCH')
    ) AS AF
    LEFT JOIN AppsLCA.dbo.TB_ShipmentCheckPrices AS SCP WITH (NOLOCK)
            ON SCP.[Waybill] = AF.[Waybill];

    CREATE NONCLUSTERED INDEX IX_Prices_Waybill ON #TB_Prices (Waybill, ShipDate);

    -----------------------------------------------------------------------------------------
    -- 2. Base de facturacion  (#TB_Bill = CTE_Bill)
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] Paso 2: Cargando #TB_Bill (base de facturacion)...';
    --    Solo columnas directas de AF. Los campos derivados se calculan en los UPDATEs A-D.
    --    SeasonName y RO_ID se incluyen como helpers internos para los UPDATEs (no son output).
    -----------------------------------------------------------------------------------------
    SELECT
         [ID]                   = AF.[ID]
        ,[ShipDate]             = AF.[ShipDate]
        ,[Waybill]              = AF.[Waybill]
        ,[ManufactureID]        = AF.[ManufactureID]
        ,[RO_ID]                = AF.[RO_ID]          -- helper interno para UPDATEs de TariffCategory
        ,[RO]                   = AF.[RO]
        ,[SeasonName]           = AF.[SeasonName]      -- helper interno para UPDATEs de TariffCategory/CountryOfOrigin
        ,[OrderID]              = AF.[OrderID]
        ,[StyleNumber]          = AF.[StyleNumber]
        ,[StyleColor]           = AF.[StyleColor]
        ,[Size]                 = AF.[Size]
        ,[BasePrice]            = AF.[BasePrice]
        ,[TotalDecoration]      = AF.[Price] - AF.[BasePrice] - AF.[OutboundFreight]
        ,[UnitPrice]            = AF.[Price]
        ,[StyleOption]          = AF.[StyleOptionName]
        ,[Quantity]             = AF.[Qty]
        ,[FOBTotal]             = AF.[Total$] - ((AF.[Price]  - AF.[OutboundFreight]) * AF.[Qty]) 
        -- ,[FOBTotal]         = IIF(AF.[ShipDate] >= '2025-11-21' AND AF.[Waybill] LIKE '%AIR%' AND CHARINDEX('FG', AF.[SeasonName]) > 0
        --                          ,AF.[Total$] - (AF.[Qty] * 0.64)
        --                          ,AF.[Total$] - (AF.[Qty] * 0.25))
        ,[NorthBoundFreight]    = AF.[Price_AirFreight] + AF.[Price_OceanFreight]
        ,[InlandFreight]        = AF.[InlandFreight]
        ,[OutboundFreight]      = AF.[OutboundFreight]
        ,[InboundFreight]       = AF.[InboundFreight]
        ,[ShipTo Port]          = COALESCE(AF.[ShipTo],AF.[PuertoDestino])
        ----Campos calculados por UPDATE A
        ,[TariffCategory]       = CAST(NULL AS NVARCHAR(50))
        ,[CountryOfOrigin]      = AF.[CountryOfOrigin]
        ----Campos calculados por UPDATE B
        ,[MO]                   = CAST(NULL AS NVARCHAR(100))
        ,[US_HTSCode]           = CAST(NULL AS NVARCHAR(50))
        ,[ProductDivision]      = CAST(NULL AS NVARCHAR(100))
        ----Campos calculados por UPDATE C
        ,[Entry #]              = CAST(NULL AS NVARCHAR(100))
        ,[EntryDate]            = CAST(NULL AS DATE)
        ,[ExportDate]           = CAST(NULL AS DATE)
        ,[TypeExport]           = CAST(NULL AS NVARCHAR(50))
        ----Campos calculados por UPDATE D (tarifas)
        ,[301China_%]           = CAST(NULL AS DECIMAL(18,6))
        ,[Fenta_%]              = CAST(NULL AS DECIMAL(18,6))
        ,[Recip_%]              = CAST(NULL AS DECIMAL(18,6))
        ,[Tariff122_%]          = CAST(NULL AS DECIMAL(18,6))
        ,[Tariff301_%]          = CAST(NULL AS DECIMAL(18,6))
        ,[HTS_%]                = CAST(NULL AS DECIMAL(18,6))
        ,[HTS_Spec_%]           = CAST(NULL AS DECIMAL(18,6))
        ,[MPF_%]                = CAST(NULL AS DECIMAL(18,6))
        ,[HMF_%]                = CAST(NULL AS DECIMAL(18,5))
        ,[301China_Tariff]      = CAST(NULL AS DECIMAL(18,4))
        ,[Fenta_Tariff]         = CAST(NULL AS DECIMAL(18,4))
        ,[Recip_Tariff]         = CAST(NULL AS DECIMAL(18,4))
        ,[HTS_Tariff]           = CAST(NULL AS DECIMAL(18,4))
        ,[Tariff122_Tariff]     = CAST(NULL AS DECIMAL(18,4))
        ,[Tariff301_Tariff]     = CAST(NULL AS DECIMAL(18,4))
        ,[MPF_Tariff]           = CAST(NULL AS DECIMAL(18,4))
        ,[HMF_Tariff]           = CAST(NULL AS DECIMAL(18,4))
        ,[TotalTariff]          = CAST(NULL AS DECIMAL(18,4))
        ----Campos calculados por UPDATE B (estilo en blanco y StyleID)
        ,[BlankStyle]           = CAST(NULL AS NVARCHAR(100))
        ,[StyleID]              = CAST(NULL AS INT)
        ----Helpers internos para UPDATE A (keys de busqueda en #TB_FAMO_SUMMARY)
        ,[Key1]                 = CAST(NULL AS NVARCHAR(200))
        ,[Key2]                 = CAST(NULL AS NVARCHAR(200))
        ,[Key3]                 = CAST(NULL AS NVARCHAR(200))
    INTO #TB_Bill
    FROM #TB_Prices AS CP
    INNER JOIN AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH (NOLOCK)
            ON CP.Waybill = AF.Waybill AND CP.ShipDate = AF.ShipDate;

    CREATE NONCLUSTERED INDEX IX_Bill_ID          ON #TB_Bill ([ID]);
    CREATE NONCLUSTERED INDEX IX_Bill_RO_ID       ON #TB_Bill ([RO_ID], [StyleNumber], [StyleColor], [Size]);
    CREATE NONCLUSTERED INDEX IX_Bill_ManufID     ON #TB_Bill ([ManufactureID]);
    CREATE NONCLUSTERED INDEX IX_Bill_Waybill     ON #TB_Bill ([Waybill], [ShipDate]);
    CREATE NONCLUSTERED INDEX IX_Bill_StyleColor  ON #TB_Bill ([StyleNumber], [StyleColor]);

    -----------------------------------------------------------------------------------------
    -- Paso 2b: Keys de busqueda en #TB_Bill  (helpers para K1/K2/K3 en UPDATE A)
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] Paso 2b: Calculando Keys de busqueda en #TB_Bill...';
    -----------------------------------------------------------------------------------------
    UPDATE #TB_Bill
    SET  [Key1] = CONCAT([StyleNumber], '-', [StyleColor], '-', [Size])
        ,[Key2] = CONCAT([StyleNumber], '-', [StyleColor])
        ,[Key3] = [StyleNumber];

    CREATE NONCLUSTERED INDEX IX_Bill_Key1 ON #TB_Bill ([RO_ID], [Key1]);
    CREATE NONCLUSTERED INDEX IX_Bill_Key2 ON #TB_Bill ([RO_ID], [Key2]);
    CREATE NONCLUSTERED INDEX IX_Bill_Key3 ON #TB_Bill ([RO_ID], [Key3]);

    -----------------------------------------------------------------------------------------
    -- Paso 2c: MOs relevantes  (#TB_MOS_FOR_SUMMARY_GROUP)
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] Paso 2c: Cargando #TB_MOS_FOR_SUMMARY_GROUP...';
    -----------------------------------------------------------------------------------------
    SELECT DISTINCT
         [ManufactureID] = TB.[ManufactureID]
    INTO #TB_MOS_FOR_SUMMARY_GROUP
    FROM
    (
        SELECT DISTINCT
             [ManufactureID] = B.[RO_ID]
        FROM #TB_Bill AS B
        WHERE B.[RO_ID] IS NOT NULL
          AND B.[RO_ID] <> 0
        UNION ALL
        SELECT DISTINCT
             [ManufactureID] = B.[ManufactureID]
        FROM #TB_Bill AS B
        WHERE B.[ManufactureID] IS NOT NULL
          AND B.[ManufactureID] <> 0
    ) AS TB;

    -----------------------------------------------------------------------------------------
    -- Paso 2d: Resumen de MOs  (#TB_FAMO_SUMMARY = precalculo de TB_MO_PartNumber_IM_Summary)
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] Paso 2d: Cargando #TB_FAMO_SUMMARY...';
    -----------------------------------------------------------------------------------------
    SELECT
         [ManufactureID]        = B.[ManufactureId]
        ,[TariffCategory]       = B.[TariffCategory]
        ,[CountryOfOrigin]      = B.[CountryOfOrigin]
        ,[Category]             = B.[Category]
        ,[Size]                 = B.[Size]
        ,[Color]                = B.[Color]
        ,[Consumption]          = B.[Consumption]
        ,[Key1]                 = CONCAT(B.[Style], '-', B.[Color], '-', B.[Size])
        ,[Key2]                 = CONCAT(B.[Style], '-', B.[Color])
        ,[Key3]                 = B.[Style]
        ,[RTariffCategory]      = ROW_NUMBER() OVER(PARTITION BY B.[ManufactureId]
                                                    ORDER BY B.[Consumption] DESC)
        ,[RTariffCategoryKey1]  = ROW_NUMBER() OVER(PARTITION BY B.[ManufactureId], CONCAT(B.[Style],'-',B.[Color],'-',B.[Size])
                                                    ORDER BY B.[Consumption] DESC)
        ,[RTariffCategoryKey2]  = ROW_NUMBER() OVER(PARTITION BY B.[ManufactureId], CONCAT(B.[Style],'-',B.[Color])
                                                    ORDER BY B.[Consumption] DESC)
        ,[RTariffCategoryKey3]  = ROW_NUMBER() OVER(PARTITION BY B.[ManufactureId], B.[Style]
                                                    ORDER BY B.[Consumption] DESC)
        ,[RTariffCategoryK2B]   = ROW_NUMBER() OVER(PARTITION BY B.[ManufactureId], B.[Category]
                                                    ORDER BY B.[Consumption] DESC)
    INTO #TB_FAMO_SUMMARY
    FROM #TB_MOS_FOR_SUMMARY_GROUP AS S
    INNER JOIN [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Summary] AS B WITH (NOLOCK)
            ON S.[ManufactureID] = B.[ManufactureId];

    CREATE NONCLUSTERED INDEX IX_FAMO_ManufID ON #TB_FAMO_SUMMARY ([ManufactureID]);
    CREATE NONCLUSTERED INDEX IX_FAMO_Key1    ON #TB_FAMO_SUMMARY ([ManufactureID], [Key1],     [RTariffCategoryKey1]);
    CREATE NONCLUSTERED INDEX IX_FAMO_Key2    ON #TB_FAMO_SUMMARY ([ManufactureID], [Key2],     [RTariffCategoryKey2]);
    CREATE NONCLUSTERED INDEX IX_FAMO_Key3    ON #TB_FAMO_SUMMARY ([ManufactureID], [Key3],     [RTariffCategoryKey3]);
    CREATE NONCLUSTERED INDEX IX_FAMO_K2B     ON #TB_FAMO_SUMMARY ([ManufactureID], [Category], [RTariffCategoryK2B]);

    -----------------------------------------------------------------------------------------
    -- UPDATE A: TariffCategory + CountryOfOrigin
    --   K1-K2B desde #TB_FAMO_SUMMARY: ambos campos en un mismo UPDATE por prioridad de llave
    --   TC-8/9/10: solo TariffCategory (fallback por SeasonName)
    --   COO-7:     solo CountryOfOrigin (fallback por SeasonName / RO / StyleNumber)
    -----------------------------------------------------------------------------------------

    ---- TC-1: Regla 9802 (Export Duty) -- Solo TariffCategory
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE A - TC-1: TariffCategory 9802 (Export Duty)...';
    UPDATE B
    SET [TariffCategory] = 'NO CAFTA RULE 9802'
    FROM #TB_Bill AS B
    INNER JOIN
    (
        SELECT
             [ID] = TE.[ID]
        FROM AppsLCA.dbo.TB_Transfer_Export_Duty AS TE WITH (NOLOCK)
        WHERE TE.[status] = 1
    ) AS TE
            ON B.[ID] = TE.[ID]
    WHERE B.[TariffCategory] IS NULL;

    ---- K1: RO_ID + Key1 (Style+Color+Size) -- TariffCategory + CountryOfOrigin
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE A - K1: TariffCategory + CountryOfOrigin por RO_ID + Key1...';
    UPDATE B
    SET  [TariffCategory]  = CASE WHEN B.[TariffCategory] IS NULL AND F.[TariffCategory] IN ('CAFTA','NonCAFTA','Non CAFTA','NONCAFTA')
                                   THEN CASE WHEN F.[TariffCategory] = 'CAFTA' THEN 'CAFTA' ELSE 'NO CAFTA' END
                                   ELSE B.[TariffCategory] END
        ,[CountryOfOrigin] = CASE WHEN B.[CountryOfOrigin] IS NULL THEN F.[CountryOfOrigin] ELSE B.[CountryOfOrigin] END
    FROM #TB_Bill AS B
    INNER JOIN #TB_FAMO_SUMMARY AS F
            ON B.[RO_ID] = F.[ManufactureID] AND B.[Key1] = F.[Key1] AND F.[RTariffCategoryKey1] = 1
    WHERE (B.[TariffCategory]  IS NULL AND F.[TariffCategory]  IN ('CAFTA','NonCAFTA','Non CAFTA','NONCAFTA'))
       OR (B.[CountryOfOrigin] IS NULL AND F.[CountryOfOrigin] IS NOT NULL);

    ---- K2: RO_ID + Key2 (Style+Color, sin Size) -- TariffCategory + CountryOfOrigin
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE A - K2: TariffCategory + CountryOfOrigin por RO_ID + Key2...';
    UPDATE B
    SET  [TariffCategory]  = CASE WHEN B.[TariffCategory] IS NULL AND F.[TariffCategory] IN ('CAFTA','NonCAFTA','Non CAFTA','NONCAFTA')
                                   THEN CASE WHEN F.[TariffCategory] = 'CAFTA' THEN 'CAFTA' ELSE 'NO CAFTA' END
                                   ELSE B.[TariffCategory] END
        ,[CountryOfOrigin] = CASE WHEN B.[CountryOfOrigin] IS NULL THEN F.[CountryOfOrigin] ELSE B.[CountryOfOrigin] END
    FROM #TB_Bill AS B
    INNER JOIN #TB_FAMO_SUMMARY AS F
            ON B.[RO_ID] = F.[ManufactureID] AND B.[Key2] = F.[Key2] AND F.[RTariffCategoryKey2] = 1
           AND (F.[Size] IS NULL OR RTRIM(F.[Size]) = '')
    WHERE (B.[TariffCategory]  IS NULL AND F.[TariffCategory]  IN ('CAFTA','NonCAFTA','Non CAFTA','NONCAFTA'))
       OR (B.[CountryOfOrigin] IS NULL AND F.[CountryOfOrigin] IS NOT NULL);

    ---- K3: RO_ID + Key3 (Style, sin Size ni Color) -- TariffCategory + CountryOfOrigin
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE A - K3: TariffCategory + CountryOfOrigin por RO_ID + Key3...';
    UPDATE B
    SET  [TariffCategory]  = CASE WHEN B.[TariffCategory] IS NULL AND F.[TariffCategory] IN ('CAFTA','NonCAFTA','Non CAFTA','NONCAFTA')
                                   THEN CASE WHEN F.[TariffCategory] = 'CAFTA' THEN 'CAFTA' ELSE 'NO CAFTA' END
                                   ELSE B.[TariffCategory] END
        ,[CountryOfOrigin] = CASE WHEN B.[CountryOfOrigin] IS NULL THEN F.[CountryOfOrigin] ELSE B.[CountryOfOrigin] END
    FROM #TB_Bill AS B
    INNER JOIN #TB_FAMO_SUMMARY AS F
            ON B.[RO_ID] = F.[ManufactureID] AND B.[Key3] = F.[Key3] AND F.[RTariffCategoryKey3] = 1
           AND (F.[Size] IS NULL OR RTRIM(F.[Size]) = '') AND (F.[Color] IS NULL OR RTRIM(F.[Color]) = '')
    WHERE (B.[TariffCategory]  IS NULL AND F.[TariffCategory]  IN ('CAFTA','NonCAFTA','Non CAFTA','NONCAFTA'))
       OR (B.[CountryOfOrigin] IS NULL AND F.[CountryOfOrigin] IS NOT NULL);

    ---- K4: RO_ID solo -- TariffCategory + CountryOfOrigin
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE A - K4: TariffCategory + CountryOfOrigin por RO_ID...';
    UPDATE B
    SET  [TariffCategory]  = CASE WHEN B.[TariffCategory] IS NULL AND F.[TariffCategory] IN ('CAFTA','NonCAFTA','Non CAFTA','NONCAFTA')
                                   THEN CASE WHEN F.[TariffCategory] = 'CAFTA' THEN 'CAFTA' ELSE 'NO CAFTA' END
                                   ELSE B.[TariffCategory] END
        ,[CountryOfOrigin] = CASE WHEN B.[CountryOfOrigin] IS NULL THEN F.[CountryOfOrigin] ELSE B.[CountryOfOrigin] END
    FROM #TB_Bill AS B
    INNER JOIN #TB_FAMO_SUMMARY AS F
            ON B.[RO_ID] = F.[ManufactureID] AND F.[RTariffCategory] = 1
    WHERE (B.[TariffCategory]  IS NULL AND F.[TariffCategory]  IN ('CAFTA','NonCAFTA','Non CAFTA','NONCAFTA'))
       OR (B.[CountryOfOrigin] IS NULL AND F.[CountryOfOrigin] IS NOT NULL);

    ---- K5: ManufactureID solo -- TariffCategory + CountryOfOrigin
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE A - K5: TariffCategory + CountryOfOrigin por ManufactureID...';
    UPDATE B
    SET  [TariffCategory]  = CASE WHEN B.[TariffCategory] IS NULL AND F.[TariffCategory] IN ('CAFTA','NonCAFTA','Non CAFTA','NONCAFTA')
                                   THEN CASE WHEN F.[TariffCategory] = 'CAFTA' THEN 'CAFTA' ELSE 'NO CAFTA' END
                                   ELSE B.[TariffCategory] END
        ,[CountryOfOrigin] = CASE WHEN B.[CountryOfOrigin] IS NULL THEN F.[CountryOfOrigin] ELSE B.[CountryOfOrigin] END
    FROM #TB_Bill AS B
    INNER JOIN #TB_FAMO_SUMMARY AS F
            ON B.[ManufactureID] = F.[ManufactureID] AND F.[RTariffCategory] = 1
    WHERE (B.[TariffCategory]  IS NULL AND F.[TariffCategory]  IN ('CAFTA','NonCAFTA','Non CAFTA','NONCAFTA'))
       OR (B.[CountryOfOrigin] IS NULL AND F.[CountryOfOrigin] IS NOT NULL);

    ---- K2B: ManufactureID + Category Fabric/Contracts (sin Size) -- TariffCategory + CountryOfOrigin
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE A - K2B: TariffCategory + CountryOfOrigin por ManufactureID + Fabric/Contracts...';
    UPDATE B
    SET  [TariffCategory]  = CASE WHEN B.[TariffCategory] IS NULL AND F.[TariffCategory] IN ('CAFTA','NonCAFTA','Non CAFTA','NONCAFTA')
                                   THEN CASE WHEN F.[TariffCategory] = 'CAFTA' THEN 'CAFTA' ELSE 'NO CAFTA' END
                                   ELSE B.[TariffCategory] END
        ,[CountryOfOrigin] = CASE WHEN B.[CountryOfOrigin] IS NULL THEN F.[CountryOfOrigin] ELSE B.[CountryOfOrigin] END
    FROM #TB_Bill AS B
    INNER JOIN #TB_FAMO_SUMMARY AS F
            ON B.[ManufactureID] = F.[ManufactureID] AND F.[RTariffCategoryK2B] = 1
           AND F.[Category] IN ('Fabric','Contracts')
           AND (F.[Size] IS NULL OR RTRIM(F.[Size]) = '')
    WHERE (B.[TariffCategory]  IS NULL AND F.[TariffCategory]  IN ('CAFTA','NonCAFTA','Non CAFTA','NONCAFTA'))
       OR (B.[CountryOfOrigin] IS NULL AND F.[CountryOfOrigin] IS NOT NULL);

    ---- TC-8: Fallback SeasonName = 'EMB FG' -- Solo TariffCategory
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE A - TC-8: TariffCategory por SeasonName EMB FG...';
    UPDATE #TB_Bill SET [TariffCategory] = 'NO CAFTA'
    WHERE [TariffCategory] IS NULL AND [SeasonName] = 'EMB FG';

    ---- TC-9: Fallback SeasonName <> 'EMB FG' -- Solo TariffCategory
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE A - TC-9: TariffCategory por SeasonName <> EMB FG...';
    UPDATE #TB_Bill SET [TariffCategory] = 'CAFTA'
    WHERE [TariffCategory] IS NULL AND [SeasonName] <> 'EMB FG' AND [SeasonName] IS NOT NULL;

    ---- TC-10: Fallback final -- Solo TariffCategory
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE A - TC-10: TariffCategory NOT FOUND (fallback)...';
    UPDATE #TB_Bill SET [TariffCategory] = 'NOT FOUND'
    WHERE [TariffCategory] IS NULL;

    ---- COO-7: Fallback por SeasonName / RO / StyleNumber -- Solo CountryOfOrigin
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE A - COO-7: CountryOfOrigin por fallback SeasonName/RO/Style...';
    UPDATE #TB_Bill
    SET [CountryOfOrigin] = CASE
                                WHEN [SeasonName] <> 'EMB FG'                                                     THEN 'El Salvador'
                                WHEN [RO] IN ('16131-32022-WHT-1','19084-144-SYH-1','19547-31014-485-1')          THEN 'Pakistan'
                                WHEN [RO] = '16730-EZ100-LAB'                                                     THEN 'Honduras'
                                WHEN [StyleNumber] IN ('05PDT','10PDT','15PDT')                                   THEN 'India'
                            END
    WHERE [CountryOfOrigin] IS NULL
      AND (  [SeasonName] <> 'EMB FG'
          OR [RO]         IN ('16131-32022-WHT-1','19084-144-SYH-1','19547-31014-485-1')
          OR [RO]          = '16730-EZ100-LAB'
          OR [StyleNumber] IN ('05PDT','10PDT','15PDT'));

    ---- COO-8: COO Validation All Export <= 2025-11-10
    UPDATE B
    SET  
        [CountryOfOrigin] = VAE.[FAMOCountryOfOrigin]
    FROM #TB_Bill AS B
    INNER JOIN AppsLCA.dbo.TB_Transfer_Validation_allExport AS VAE WITH(NOLOCK) on b.ID = VAE.Original_IDExport

    -----------------------------------------------------------------------------------------
    -- UPDATE BASE PRICE & TOTAL DECORATION: TariffCategory = NO CAFTA RULE 9802 &
    -- Total Decoration = 0.00 -> Base Price = BasePrice - 0.08 & TotalDecoration = 0.08
    -----------------------------------------------------------------------------------------

    UPDATE #TB_Bill
    SET
         [BasePrice] = IIF([TotalDecoration] = 0.00,[BasePrice] - 0.08,[BasePrice])
        ,[TotalDecoration] = IIF([TotalDecoration] = 0.00,[TotalDecoration] + 0.08,[TotalDecoration])

    UPDATE #TB_Bill
    SET
         [BasePrice] = [UnitPrice] - 1.75
        ,[TotalDecoration] = 1.75
    WHERE ID = 1240785

    -----------------------------------------------------------------------------------------
    -- UPDATE B: MO (ManufactureNumber) + US_HTSCode + ProductDivision + BlankStyle + StyleID
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE B: MO + US_HTSCode + ProductDivision + BlankStyle + StyleID...';
    --           Joins: TMO_APri -> ODT_PRI -> ST -> STB -> HTS  +  LMN (RawMaterials)
    -----------------------------------------------------------------------------------------
    UPDATE B
    SET
         [MO]              = TMO_APri.[ManufactureNumber]
        ,[BlankStyle]      = COALESCE(STB.[StyleNumber], ST.[StyleNumber])
        ,[StyleID]         = ODT_PRI.[StyleID]
        ,[US_HTSCode]      = CASE
                                WHEN COALESCE(IIF(AF_PD.[ProductDivision] IN ('Accesories','Fleece'), 'Apparel', AF_PD.[ProductDivision]),
                                              IIF(ST.[Comments9] = 'Accesories','Apparel', ST.[Comments9]))
                                     NOT LIKE '%Head%' AND HTS.[US_HTSCode] IS NOT NULL THEN HTS.[US_HTSCode]
                                WHEN LMN.[US_HTSCode] IS NOT NULL THEN LMN.[US_HTSCode]
                                WHEN LMN.[CA_HTSCode] IS NOT NULL THEN LMN.[CA_HTSCode]
                                WHEN HTS.[US_HTSCode] IS NOT NULL THEN HTS.[US_HTSCode]
                                ELSE NULL
                             END
        ,[ProductDivision] = COALESCE(IIF(ST.[Comments9] = 'Accesories','Apparel', ST.[Comments9]),
                                      IIF(AF_PD.[ProductDivision] IN ('Accesories','Fleece'), 'Apparel', AF_PD.[ProductDivision]))
    FROM #TB_Bill AS B
    ----Join a AF para obtener ProductDivision original (necesario para el COALESCE de ProductDivision y US_HTSCode)
    LEFT JOIN AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF_PD WITH (NOLOCK)
            ON B.[ID] = AF_PD.[ID]
    LEFT JOIN lca.dbo.ManufactureOrders AS TMO_APri WITH (NOLOCK)
            ON B.[ManufactureID] = TMO_APri.[ManufactureID]
    LEFT JOIN lca.dbo.OrderItems AS ODT_PRI WITH (NOLOCK)
            ON TMO_APri.[FirstOrderItemID] = ODT_PRI.[OrderItemID]
    LEFT JOIN LCA.dbo.Styles AS ST WITH (NOLOCK)
            ON ODT_PRI.[StyleID] = ST.[StyleID]
    LEFT JOIN LCA.dbo.Styles AS STB WITH (NOLOCK)
            ON STB.[StyleID] = ST.[BlankStyleID]
    LEFT JOIN lca.dbo.HTSStyleCodes AS HTS WITH (NOLOCK)
            ON ST.[HTSStyleCodeID] = HTS.[HTSStyleCodeID]
    LEFT JOIN
    (
        SELECT
             [Color]      = abc123.[Color]
            ,[Style]      = abc123.[Style]
            ,[CA_HTSCode] = abc123.[CA_HTSCode]
            ,[US_HTSCode] = abc123.[US_HTSCode]
        FROM
        (
            SELECT
                 COL.ColorName     AS Color
                ,CL.ComponentName  AS Style
                ,DRD.DropDownValue AS CA_HTSCode
                ,DRD.Description3  AS US_HTSCode
                ,ROW_NUMBER() OVER (PARTITION BY COL.ColorName, CL.ComponentName
                                    ORDER BY COL.ColorName, CL.ComponentName, RW.HTSCodeID) AS Cuenta
            FROM [LCA].[dbo].[RawMaterials] AS RW WITH (NOLOCK)
            LEFT JOIN lca.dbo.Colors AS COL WITH (NOLOCK)
                    ON RW.[ColorID] = COL.[ColorID]
            LEFT JOIN lca.dbo.ComponentLibrary AS CL WITH (NOLOCK)
                    ON RW.[ComponentID] = CL.[ComponentID]
                   AND CL.[ComponentCategoryID] = 11
            LEFT JOIN lca.dbo.DropDownValues AS DRD WITH (NOLOCK)
                    ON RW.[HTSCodeID] = DRD.[DropDownValueID]
            WHERE CL.ComponentName IS NOT NULL
              AND COL.ColorName    IS NOT NULL
              AND RW.HTSCodeID     IS NOT NULL
        ) AS abc123
        WHERE Cuenta = 1
    ) AS LMN
            ON B.[StyleNumber] = LMN.Style
           AND B.[StyleColor]  = LMN.Color;

    -----------------------------------------------------------------------------------------
    -- UPDATE C: Entry#, EntryDate, ExportDate, TypeExport
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE C: Entry#, EntryDate, ExportDate, TypeExport...';
    --           Join: TB_Transfer_WaybillEntry por Waybill
    -----------------------------------------------------------------------------------------
    UPDATE B
    SET
         [Entry #]   = WE.[Entry #]
        ,[EntryDate] = WE.[EntryDate]
        ,[ExportDate]= COALESCE(WE.[EntryDate], B.[ShipDate])
        ,[TypeExport]= CASE
                           WHEN YEAR(B.[ShipDate]) = 2025 AND WE.[Waybill] IS NOT NULL THEN 'KGL'
                           WHEN YEAR(B.[ShipDate]) = 2025 AND WE.[Waybill] IS NULL     THEN 'NO KGL'
                           WHEN B.[ShipDate] < '2026-01-15' AND WE.[Waybill] IS NULL   THEN 'NO KGL'
                           WHEN B.[ShipDate] >= '2026-01-15'                           THEN 'NO DATA FROM 7501 LOG'
                           ELSE 'NO KGL'
                       END
    FROM #TB_Bill AS B
    LEFT JOIN
    (
        SELECT DISTINCT
             [Waybill] = WE.[Waybill]
            ,[Entry #] = WE.[Entry #]
            ,[EntryDate] = WE.[EntryDate]
        FROM AppsLCA.dbo.TB_Transfer_WaybillEntry AS WE WITH (NOLOCK)
    ) AS WE
            ON WE.[Waybill] = B.[Waybill];

    CREATE NONCLUSTERED INDEX IX_Bill_Tariff ON #TB_Bill ([ProductDivision], [CountryOfOrigin], [ExportDate]);
    CREATE NONCLUSTERED INDEX IX_Bill_HTS    ON #TB_Bill ([US_HTSCode]);

    -----------------------------------------------------------------------------------------
    -- UPDATE D-1a: Porcentajes TariffCOO  (301China, Fenta, Recip, Tariff122)
    --              Subquery C resuelve COALESCE(TT, TT2) por ID antes del UPDATE
    -----------------------------------------------------------------------------------------
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE D-1a: Porcentajes TariffCOO (301China, Fenta, Recip, Tariff122)...';
    UPDATE B
    SET
         [301China_%]  = C.[301China_%]
        ,[Fenta_%]     = C.[Fenta_%]
        ,[Recip_%]     = C.[Recip_%]
        ,[Tariff122_%] = C.[Tariff122_%]
        ,[Tariff301_%] = C.[Tariff301_%]
        ,[MPF_%]       = 0.003464
        ,[HMF_%]       = 0.00125
    FROM #TB_Bill AS B
    INNER JOIN
    (
        SELECT
             [ID]          = A.[ID]
            ,[301China_%]  = COALESCE(TT.[301China],  TT2.[301China] )
            ,[Fenta_%]     = COALESCE(TT.[Fenta],     TT2.[Fenta]    )
            ,[Recip_%]     = COALESCE(TT.[Recip],     TT2.[Recip]    )
            ,[Tariff122_%] = COALESCE(TT.[Tariff122], TT2.[Tariff122])
            ,[Tariff301_%] = COALESCE(TT.[Tariff301], TT2.[Tariff122])
        FROM #TB_Bill AS A
        LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_TariffCOO] AS TT WITH (NOLOCK)
                ON TT.[Type]            = A.[ProductDivision]
               AND TT.[CountryOfOrigin] = A.[CountryOfOrigin]
               AND A.[ExportDate]      >= TT.[DateFrom]
               AND A.[ExportDate]      <= TT.[DateTo]
        LEFT JOIN
        (
            SELECT S.[Type], S.[COO], S.[CountryOfOrigin], S.[DateFrom]
                  ,S.[301China], S.[Fenta], S.[Recip], S.[Tariff122], S.[Tariff301]
            FROM [AppsLCA].[dbo].[TB_Transfer_TariffCOO] AS S WITH (NOLOCK)
            INNER JOIN
            (
                SELECT [Type]            = D.[Type]
                      ,[COO]             = D.[COO]
                      ,[CountryOfOrigin] = D.[CountryOfOrigin]
                      ,[DateTo]          = MAX(D.[DateTo])
                FROM [AppsLCA].[dbo].[TB_Transfer_TariffCOO] AS D WITH (NOLOCK)
                GROUP BY D.[Type], D.[COO], D.[CountryOfOrigin]
            ) AS MaxDates
                    ON MaxDates.[Type]            = S.[Type]
                   AND MaxDates.[COO]             = S.[COO]
                   AND MaxDates.[CountryOfOrigin] = S.[CountryOfOrigin]
                   AND MaxDates.[DateTo]          = S.[DateTo]
        ) AS TT2
                ON TT2.[Type]            = A.[ProductDivision]
               AND TT2.[CountryOfOrigin] = A.[CountryOfOrigin]
               AND A.[ExportDate]        > TT2.[DateFrom]
        WHERE A.[ExportDate] IS NOT NULL
    ) AS C ON C.[ID] = B.[ID]
    WHERE b.ExportDate >= '2025-12-12'

    -----------------------------------------------------------------------------------------
    -- UPDATE D-1b: Porcentaje HTS  (TB_Transfer_HTSTariff por US_HTSCode)
    -----------------------------------------------------------------------------------------
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE D-1b: Porcentaje HTS...';
    UPDATE B
    SET [HTS_%] = CASE
                      WHEN B.[TariffCategory] = 'CAFTA'                                THEN THTS.[ADValoremRate]
                      WHEN THTS.[ADValoremRate] IS NULL AND B.[StyleNumber] = 'YBKT'   THEN 0.075
                      ELSE THTS.[ADValoremRate]
                  END
        ,[HTS_Spec_%] = THTS.[SpecRate]
    FROM #TB_Bill AS B
    LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_HTSTariff] AS THTS WITH (NOLOCK)
            ON THTS.[SACKellyGlobal] = B.[US_HTSCode]
    WHERE b.ExportDate >= '2025-12-12'


    UPDATE B
    SET
         [301China_%]  = VAE.[301China_%]
        ,[Fenta_%]     = VAE.[Fenta_%]
        ,[Recip_%]     = VAE.[Recip_%]
        ,[HTS_%]       = VAE.[HTS_%]
    FROM #TB_Bill AS B
    LEFT JOIN AppsLCA.dbo.TB_Transfer_Validation_allExport AS VAE WITH(NOLOCK) ON B.ID = VAE.Original_IDExport
    WHERE b.ExportDate < '2025-12-12'

    -----------------------------------------------------------------------------------------
    -- UPDATE D-2: Montos de tarifa  (usa los porcentajes ya calculados en D-1)
    --             301China / Fenta / Recip: base TotalDecoration si 9802, sino FOBTotal
    --             HTS / Tariff122:          0 si CAFTA, TotalDecoration si 9802, FOBTotal si NO CAFTA
    -----------------------------------------------------------------------------------------
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] UPDATE D-2: Montos de tarifa...';
    UPDATE #TB_Bill
    SET
         [301China_Tariff]  = [301China_%]  * IIF([TariffCategory] = 'NO CAFTA RULE 9802', ([TotalDecoration] * Quantity), [FOBTotal])
        ,[Fenta_Tariff]     = [Fenta_%]     * IIF([TariffCategory] = 'NO CAFTA RULE 9802', ([TotalDecoration] * Quantity), [FOBTotal])
        ,[Recip_Tariff]     = [Recip_%]     * IIF([TariffCategory] = 'NO CAFTA RULE 9802', ([TotalDecoration] * Quantity), [FOBTotal])
        ,[HTS_Tariff]       = [HTS_%]       * CASE WHEN [TariffCategory] = 'CAFTA'              THEN 0.000
                                                    WHEN [TariffCategory] = 'NO CAFTA RULE 9802' THEN ([TotalDecoration] * Quantity)
                                                    WHEN [TariffCategory] = 'NO CAFTA'           THEN [FOBTotal]
                                              END
        ,[Tariff122_Tariff] = [Tariff122_%] * CASE WHEN [TariffCategory] = 'CAFTA'              THEN 0.000
                                                    WHEN [TariffCategory] = 'NO CAFTA RULE 9802' THEN ([TotalDecoration] * Quantity)
                                                    WHEN [TariffCategory] = 'NO CAFTA'           THEN [FOBTotal]
                                              END
        ,[Tariff301_Tariff] = [Tariff301_%] * CASE WHEN [TariffCategory] = 'CAFTA'              THEN 0.000
                                                    WHEN [TariffCategory] = 'NO CAFTA RULE 9802' THEN ([TotalDecoration] * Quantity)
                                                    WHEN [TariffCategory] = 'NO CAFTA'           THEN [FOBTotal]
                                              END
        ,[MPF_Tariff]       = [MPF_%]       * CASE WHEN [TariffCategory] = 'CAFTA'              THEN 0.000
                                                    WHEN [TariffCategory] = 'NO CAFTA RULE 9802' THEN ([TotalDecoration] * Quantity)
                                                    WHEN [TariffCategory] = 'NO CAFTA'           THEN [FOBTotal]
                                              END
        ,[HMF_Tariff]       = [HMF_%]       * CASE WHEN [TariffCategory] = 'CAFTA' AND [Waybill] NOT LIKE '%AIR%'               THEN [FOBTotal]
                                                    WHEN [TariffCategory] = 'NO CAFTA RULE 9802' AND [Waybill] NOT LIKE '%AIR%' THEN (([TotalDecoration] + [BasePrice]) * Quantity)
                                                    WHEN [TariffCategory] = 'NO CAFTA'           AND [Waybill] NOT LIKE '%AIR%' THEN [FOBTotal]
                                              END
    WHERE ExportDate >= '2025-12-12'

    UPDATE B SET
         [301China_Tariff]  = COALESCE(VAE.TValue_301China_$,0.00)
        ,[Fenta_Tariff]     = COALESCE(VAE.TValue_Fenta_$,0.00)
        ,[Recip_Tariff]     = COALESCE(VAE.TValue_Recip_$,0.00)
        ,[HTS_Tariff]       = COALESCE(VAE.TValue_HTS_$,0.00)
        ,[Tariff122_Tariff] = 0.00
        ,[Tariff301_Tariff] = 0.00
        ,[MPF_Tariff] = 0.00
        ,[HMF_Tariff] = 0.00
        
    FROM #TB_Bill AS B
    LEFT JOIN AppsLCA.dbo.TB_Transfer_Validation_allExport AS VAE WITH(NOLOCK) ON B.ID = VAE.Original_IDExport
    WHERE B.ExportDate < '2025-12-12'
    -- select * from #TB_Bill

    UPDATE #TB_Bill
    SET [TotalTariff] =   COALESCE([301China_Tariff],0.00)
                        + COALESCE([Fenta_Tariff],0.00)
                        + COALESCE([Recip_Tariff],0.00)
                        + COALESCE([HTS_Tariff],0.00)
                        + COALESCE([Tariff122_Tariff],0.00)
                        + COALESCE([Tariff301_Tariff],0.00)
                        + COALESCE([MPF_Tariff],0.00)
                        + COALESCE([HMF_Tariff],0.00)

    -----------------------------------------------------------------------------------------
    -- 3. Lookup inventario L2B  (#TB_L2BrandInv = CTE_L2BrandInv)
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] Paso 3: Cargando #TB_L2BrandInv...';
    -----------------------------------------------------------------------------------------
    SELECT
         [Style]     = L2B.[Style]
        ,[Color]     = L2B.[Color]
        ,[Size]      = L2B.[Size]
        ,[InvItemID] = L2B.[InvItemID]
        ,[R]         = ROW_NUMBER() OVER (PARTITION BY L2B.[Style], L2B.[Color], L2B.[Size]
                                          ORDER BY L2B.[Style], L2B.[Color], L2B.[Size])
    INTO #TB_L2BrandInv
    FROM AppsLCA.legacycaps.VW_LCA_L2B_InventoryID AS L2B WITH (NOLOCK);

    CREATE NONCLUSTERED INDEX IX_L2BInv ON #TB_L2BrandInv (Style, Color, Size, R);

    -----------------------------------------------------------------------------------------
    -- 4. Lookup ordenes  (#TB_Orders = CTE_Orders)
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] Paso 4: Cargando #TB_Orders...';
    -----------------------------------------------------------------------------------------
    SELECT
         [OrderID]           = OD.[OrderID]
        ,[ItemDetailID_Calc] = CASE
                                   WHEN OD.[PONumber] LIKE 'ORD-PO%' THEN NULL
                                   WHEN OD.[PONumber] LIKE 'ORD-%'   THEN TRY_CAST(REPLACE(OD.[PONumber], 'ORD-', '') AS BIGINT)
                                   WHEN OD.[PONumber] LIKE 'ORD%'    THEN TRY_CAST(OD.[Comments6] AS BIGINT)
                                   ELSE NULL
                               END
        ,[CustomerPO_Calc]   = CASE
                                   WHEN OD.[PONumber] LIKE 'ORD%' AND CHARINDEX('-', OD.[Comments6]) > 0
                                       THEN SUBSTRING(OD.[Comments6], 1, CHARINDEX('-', OD.[Comments6]) - 1)
                                   ELSE OD.[Comments6]
                               END
    INTO #TB_Orders
    FROM LCA.dbo.Orders AS OD WITH (NOLOCK);

    CREATE NONCLUSTERED INDEX IX_Orders ON #TB_Orders (OrderID);

    -----------------------------------------------------------------------------------------
    -- 5. TRUNCATE + INSERT en tabla destino  (equivale a CTE_Final -> SELECT final)
    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] Paso 5: Construyendo resultado final...';
    -----------------------------------------------------------------------------------------
    -- TRUNCATE TABLE AppsLCA.legacycaps.TB_L2Brands_Units_Invoiced_WithTariffs;

    DELETE FROM AppsLCA.legacycaps.TB_L2Brands_Units_Invoiced_WithTariffs WHERE Waybill = @Waybill
    INSERT INTO AppsLCA.legacycaps.TB_L2Brands_Units_Invoiced_WithTariffs
    (
        [IDExport]
        ,[Size]
        ,[StyleColor]
        ,[Quantity]
        ,[Style]
        ,[StyleID]
        ,[TariffCategory]
        ,[TransactionDate]
        ,[MO]
        ,[MO_ID]
        ,[ItemDetailID]
        ,[Item #]
        ,[Blank_InvoicedPrice]
        ,[CustomerPO]
        ,[StyleOption]
        ,[Waybill]
        ,[Decoration_Invoiced_Price]
        ,[Unit_Invoiced_Price]
        ,[CountryOfOrigin]
        ,[US_HTSCode]
        ,[FOBTotal]
        ,[301China_Tariff]
        ,[Fenta_Tariff]
        ,[Recip_Tariff]
        ,[HTS_Tariff]
        ,[Tariff122_Tariff]
        ,[Tariff301_Tariff]
        ,[MPF_Tariff]
        ,[HMF_Tariff]
        ,[TotalTariff]
        ,[Entry #]  
        ,[EntryDate]
        ,[ShipToPort]
        ,[InlandFreight]
        ,[NorthBoundFreight]
        ,[OutboundFreight]
        ,[InboundFreight]
    )

    SELECT
         [IDExport]                  = AF.[ID]
        ,[Size]                      = AF.[Size]
        ,[StyleColor]                = AF.[StyleColor]
        ,[Quantity]                  = AF.[Quantity]
        ,[Style]                     = AF.[StyleNumber]
        ,[StyleID]                   = COALESCE(SCPD.[StyleID], AF.[StyleID])
        ,[TariffCategory]            = AF.[TariffCategory]
        ,[TransactionDate]           = SCP.[ShipDate]
        ,[MO]                        = AF.[MO]
        ,[MO_ID]                     = AF.[ManufactureID]
        ,[ItemDetailID]              = COALESCE(SCPD.[ItemDetailID], OD.[ItemDetailID_Calc])
        ,[Item #]                    = L2BInv.[InvItemID]
        ,[Blank_InvoicedPrice]       = CASE
                                           WHEN SCP.[ShipDate] < '2026-02-10' THEN AF.[BasePrice]
                                           ELSE SCPD.[TotalBlank]
                                       END
        ,[CustomerPO]                = OD.[CustomerPO_Calc]
        ,[StyleOption]               = AF.[StyleOption]
        ,[Waybill]                   = AF.[Waybill]
        ,[Decoration_Invoiced_Price] = CASE
                                           WHEN SCP.[ShipDate] < '2026-02-10' THEN AF.[TotalDecoration]
                                           ELSE SCPD.[TotalDecoration]
                                       END
        ,[Unit_Invoiced_Price]       = CASE
                                           WHEN SCP.[ShipDate] < '2026-02-10' THEN AF.[UnitPrice]
                                           ELSE SCPD.[TotalBlank] + SCPD.[TotalDecoration]
                                       END
        ,[CountryOfOrigin]           = AF.[CountryOfOrigin]
        ,[US_HTSCode]                = AF.[US_HTSCode]
        -- ,[ProductDivision]           = AF.[ProductDivision]
        ,[FOBTotal]                  = AF.[FOBTotal]
        ,[301China_Tariff]           = AF.[301China_Tariff]
        ,[Fenta_Tariff]              = AF.[Fenta_Tariff]
        ,[Recip_Tariff]              = AF.[Recip_Tariff]
        ,[HTS_Tariff]                = AF.[HTS_Tariff]
        ,[Tariff122_Tariff]          = AF.[Tariff122_Tariff]
        ,[Tariff301_Tariff]          = AF.[Tariff301_Tariff]
        ,[MPF_Tariff]                = AF.[MPF_Tariff]
        ,[HMF_Tariff]                = AF.[HMF_Tariff]
        ,[TotalTariff]               = AF.[TotalTariff]
        ,[Entry #]                   = AF.[Entry #]
        ,[EntryDate]                 = AF.[EntryDate]
        ,[ShipTo Port]               = AF.[ShipTo Port]
        ,[InlandFreight]             = AF.[InlandFreight]
        ,[NorthBoundFreight]         = AF.[NorthBoundFreight]
        ,[OutboundFreight]           = AF.[OutboundFreight]
        ,[InboundFreight]            = AF.[InboundFreight]
        -- ,[TypeExport]                = AF.[TypeExport]
    -- INTO AppsLCA.legacycaps.TB_L2Brands_Units_Invoiced_WithTariffs
    FROM #TB_Prices AS SCP
    INNER JOIN #TB_Bill AS AF
            ON SCP.[Waybill]  = AF.[Waybill]
           AND SCP.[ShipDate] = AF.[ShipDate]
    LEFT JOIN AppsLCA.dbo.TB_ShipmentCheckPricesDetail AS SCPD WITH (NOLOCK)
            ON SCP.[ID] = SCPD.[shipmentCheckPrices_id]
           AND SCPD.[ManufactureID] = AF.[ManufactureID]
    LEFT JOIN #TB_Orders AS OD
            ON AF.[OrderID] = OD.[OrderID]
    LEFT JOIN #TB_L2BrandInv AS L2BInv
            ON AF.[BlankStyle] = L2BInv.[Style]
           AND COALESCE(SCPD.[Color], AF.[StyleColor]) = L2BInv.[Color]
           AND AF.[Size] = L2BInv.[Size]
           AND L2BInv.[R] = 1
    -- WHERE AF.Waybill = 'HW-20260116'

    PRINT '[ ' + CONVERT(VARCHAR(23), GETDATE(), 121) + ' ] SP finalizado.';
END
GO
