DROP TABLE IF EXISTS #TB_Seasons
DROP TABLE IF EXISTS #TB_StyleColor_HTS

SELECT
     [SeasonID]
    ,[SeasonName]
INTO #TB_Seasons
FROM [LCA].[dbo].[Seasons] AS SNS WITH(NOLOCK)
WHERE SeasonID NOT IN
(
     1698	-- Blank RO
    ,1699	-- EMB
    ,2229	-- BLANK
    ,2231	-- EMB Cost
    ,16193	-- 2023 Approved Prices
    ,27225	-- EMB FG
    ,27432	-- EXP BO
    ,31485	-- GREIGE
    ,31518	-- LCA APPAREL PRICE
    ,31519	-- CONTRACTOR HEADWEAR PRICE    
    ,31520	-- CONTRACTOR APPAREL PRICE
    ,31533	-- BUNDLE
)

SELECT
     [StyleNumber]              = ST.[StyleNumber]
    ,[StyleColor]               = STC.[StyleColorName]
    ,[US_HTSCode_StyleCodes]    = HTS.[US_HTSCode]
    ,[US_HTSCode_RawMaterials]  = LMN.[US_HTSCode]
    ,[CA_HTSCode_RawMaterials]  = LMN.[CA_HTSCode]
    ,[US_HTSCode_StyleCodes2]   = HTS.[US_HTSCode]
    ,[FinalCI_US_HTSCode]       = CASE
                                        WHEN ST.[Comments9] NOT LIKE '%Head%' AND HTS.[US_HTSCode] IS NOT NULL THEN HTS.[US_HTSCode]
                                        WHEN LMN.[US_HTSCode] IS NOT NULL THEN LMN.[US_HTSCode]
                                        WHEN LMN.[CA_HTSCode] IS NOT NULL THEN LMN.[CA_HTSCode]
                                        WHEN HTS.[US_HTSCode] IS NOT NULL THEN HTS.[US_HTSCode]
                                        ELSE NULL
                                  END
    ,[Option_US_HTSCode]        = CASE
                                        WHEN ST.[Comments9] NOT LIKE '%Head%' AND HTS.[US_HTSCode] IS NOT NULL THEN 1
                                        WHEN LMN.[US_HTSCode] IS NOT NULL THEN 2
                                        WHEN LMN.[CA_HTSCode] IS NOT NULL THEN 3
                                        WHEN HTS.[US_HTSCode] IS NOT NULL THEN 4
                                        ELSE 5
                                  END
INTO #TB_StyleColor_HTS
FROM (SELECT * FROM [LCA].[dbo].[StatusNames] AS SN WITH(NOLOCK) WHERE [StatusID] = 64) AS FILSN
INNER JOIN  [LCA].[dbo].[Styles]            AS  ST  WITH(NOLOCK)    ON  ST.[StatusID]           = FILSN.[StatusID]
INNER JOIN  #TB_Seasons                     AS  SNS WITH(NOLOCK)    ON  ST.[SeasonID]           = SNS.[SeasonID]
LEFT  JOIN  [LCA].[dbo].[HTSStyleCodes]     AS  HTS WITH(NOLOCK)    ON  ST.[HTSStyleCodeID]     = HTS.[HTSStyleCodeID]
LEFT  JOIN  [LCA].[dbo].[StyleVariations]   AS  STV WITH(NOLOCK)    ON  ST.[StyleID]            = STV.[StyleID]
LEFT  JOIN  [LCA].[dbo].[StyleColors]       AS  STC WITH(NOLOCK)    ON  STV.[StyleColorID]      = STC.[StyleColorID]
LEFT  JOIN  
(
    SELECT 
        * 
    FROM 
    (
        SELECT
             [Color]          = FIL.[Color]
            ,[Style]          = FIL.[Style]
            ,[CA_HTSCode]     = FIL.[CA_HTSCode]
            ,[US_HTSCode]     = FIL.[US_HTSCode]
        FROM (
            SELECT
                 [Color]      = COL.[ColorName]
                ,[Style]      = CL.[ComponentName]
                ,[CA_HTSCode] = DRD.[DropDownValue]
                ,[US_HTSCode] = DRD.[Description3]
                ,[Cuenta]     = ROW_NUMBER() OVER (
                                    PARTITION BY COL.[ColorName], CL.[ComponentName]
                                    ORDER BY     COL.[ColorName], CL.[ComponentName]
                                )
            FROM        [LCA].[dbo].[RawMaterials]        AS RW  WITH(NOLOCK)
            LEFT JOIN   [LCA].[dbo].[Colors]              AS COL WITH(NOLOCK) ON  RW.[ColorID]                = COL.[ColorID]
            LEFT JOIN   [LCA].[dbo].[ComponentLibrary]    AS CL  WITH(NOLOCK) ON  RW.[ComponentID]            = CL.[ComponentID]
                                                                              AND CL.[ComponentCategoryID]    = 11
            LEFT JOIN [LCA].[dbo].[DropDownValues]      AS DRD WITH(NOLOCK)   ON  RW.[HTSCodeID]              = DRD.[DropDownValueID]
            WHERE CL.[ComponentName] IS NOT NULL
            AND COL.[ColorName]    IS NOT NULL
        ) AS FIL
        WHERE FIL.[Cuenta] = 1
    ) FGH
) AS LMN	ON ST.StyleNumber = LMN.Style AND STC.StyleColorName = LMN.Color

GROUP BY
    ST.[StyleNumber]
    ,STC.[StyleColorName]
    ,HTS.[US_HTSCode]
    ,LMN.[US_HTSCode]
    ,LMN.[CA_HTSCode]
    ,HTS.[US_HTSCode]
    ,CASE
        WHEN ST.[Comments9] NOT LIKE '%Head%' AND HTS.[US_HTSCode] IS NOT NULL THEN HTS.[US_HTSCode]
        WHEN LMN.[US_HTSCode] IS NOT NULL THEN LMN.[US_HTSCode]
        WHEN LMN.[CA_HTSCode] IS NOT NULL THEN LMN.[CA_HTSCode]
        WHEN HTS.[US_HTSCode] IS NOT NULL THEN HTS.[US_HTSCode]
        ELSE NULL
    END
    ,CASE
        WHEN ST.[Comments9] NOT LIKE '%Head%' AND HTS.[US_HTSCode] IS NOT NULL THEN 1
        WHEN LMN.[US_HTSCode] IS NOT NULL THEN 2
        WHEN LMN.[CA_HTSCode] IS NOT NULL THEN 3
        WHEN HTS.[US_HTSCode] IS NOT NULL THEN 4
        ELSE 5
    END

SELECT
*
FROM #TB_StyleColor_HTS    