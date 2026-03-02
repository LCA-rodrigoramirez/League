DROP TABLE IF EXISTS #TB_Seasons

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
      [StyleNumber]                     = ST.[StyleNumber]
     ,[StyleColor]                      = STC.[StyleColorName]
     ,[DescribeText]                    = ST.[DescribeText]
     ,[InvoicingDescription_Styles]     = ST.[Description3]
     ,[InvoicingDescription_Components] = CL.[FabricContent]
FROM (SELECT * FROM [LCA].[dbo].[StatusNames] AS SN WITH(NOLOCK) WHERE [StatusID] = 64) AS FILSN
INNER JOIN  [LCA].[dbo].[Styles]             AS   ST   WITH(NOLOCK)   ON   ST.[StatusID]            = FILSN.[StatusID]
INNER JOIN  #TB_Seasons                      AS   SNS  WITH(NOLOCK)   ON   ST.[SeasonID]            = SNS.[SeasonID]
LEFT  JOIN  [LCA].[dbo].[StyleVariations]    AS   STV  WITH(NOLOCK)   ON   ST.[StyleID]             = STV.[StyleID]
LEFT  JOIN  [LCA].[dbo].[StyleColors]        AS   STC  WITH(NOLOCK)   ON   STV.[StyleColorID]       = STC.[StyleColorID]
LEFT  JOIN  [LCA].[dbo].[StyleDetails]       AS   STD  WITH(NOLOCK)   ON   ST.[StyleID]             = STD.[StyleID]
                                                                      AND  STV.[StyleDetailID]      = STD.StyleDetailID
LEFT  JOIN  [LCA].[dbo].[ComponentLibrary]   AS   CL   WITH(NOLOCK)   ON   STD.[ComponentID]        = CL.[ComponentID]
GROUP BY
      ST.[StyleNumber]
     ,STC.[StyleColorName]
     ,ST.[DescribeText]
     ,ST.[Description3]
     ,CL.[FabricContent]
     