DROP TABLE IF EXISTS #TB_ActiveStyle
DROP TABLE IF EXISTS #TB_AllStyleInfo
DROP TABLE IF EXISTS #TB_StyleComponents
DROP TABLE IF EXISTS #TB_StyleComponents_QtyDesc
DROP TABLE IF EXISTS #TB_StyleComponentsRawMaterial
DROP TABLE IF EXISTS #TB_StyleComponents_Options
DROP TABLE IF EXISTS #TB_Seasons
DROP TABLE IF EXISTS #TB_FabricContentVer2
DROP TABLE IF EXISTS #TB_FabricContentSBA
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
      [StyleNumber]                               = ST.[StyleNumber]
     ,[StyleID]                                   = ST.[StyleID]
     ,[DescribeText]                              = ST.[DescribeText]
     ,[InvoicingDescription_Styles]               = ST.[Description3]
INTO #TB_ActiveStyle
FROM (SELECT * FROM [LCA].[dbo].[StatusNames] AS SN WITH(NOLOCK) WHERE [StatusID] = 64) AS FILSN
     INNER JOIN  [LCA].[dbo].[Styles]             AS   ST   WITH(NOLOCK)   ON   ST.[StatusID]            = FILSN.[StatusID]
     INNER JOIN  #TB_Seasons                      AS   SNS  WITH(NOLOCK)   ON   ST.[SeasonID]            = SNS.[SeasonID]


--------------------------------------------------------- Component + RawMaterials Invoicing Description --------------------------------------------------------------------------
     
     SELECT
           [StyleNumber]                                    = ST.[StyleNumber]
          ,[StyleColor]                                     = STC.[StyleColorName]
          ,[DescribeText]                                   = ST.[DescribeText]
          ,[InvoicingDescription_Components]                = CL.[FabricContent]
          ,[InvoicingDescription_RawMaterials]              = PNCont.[FabricContent]
          ,[RowN]                                           = ROW_NUMBER() OVER(
                                                                                     PARTITION BY 
                                                                                                     st.[StyleNumber]
                                                                                                    ,STC.[StyleColorName] 

                                                                                     ORDER BY        st.[StyleNumber]
                                                                                                    ,STC.[StyleColorName] 
                                                                                                    ,std.[Quantity] 
                                                                                )
          ,[FinalInvoicingDescription_ComponentRawMaterial] = CAST(NULL AS VARCHAR(200))
     INTO #TB_StyleComponentsRawMaterial
     FROM        #TB_ActiveStyle                       AS   ST
     INNER JOIN  [LCA].[dbo].[StyleVariations]         AS   STV  WITH(NOLOCK)   ON   ST.[StyleID]             = STV.[StyleID]
     INNER JOIN  [LCA].[dbo].[StyleColors]             AS   STC WITH(NOLOCK)    ON   STV.[StyleColorID]       = STC.[StyleColorID]
     INNER JOIN  [LCA].[dbo].[StyleDetails]            AS   STD  WITH(NOLOCK)   ON   STV.[StyleDetailID]      = STD.[StyleDetailID]   
     INNER JOIN  [LCA].[dbo].[ComponentLibrary]        AS   CL   WITH(NOLOCK)   ON   STD.[ComponentID]        = CL.[ComponentID] AND CL.ComponentCategoryID IN (1,11)
     INNER JOIN  [LCA].[dbo].[ComponentCategories]	AS   CC   WITH(NOLOCK)   ON   CC.[ComponentCategoryID]	= cl.[ComponentCategoryID]
     LEFT  JOIN
						(select distinct case when charindex('-',PartNumber)>0
										then substring( PartNumber ,1, charindex('-',PartNumber)-1)
									else '' end as NewStyle
									,case	when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-') =1
												then substring(Partnumber, charindex('-',PartNumber)+1,99 )
											when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-') >=2
												then 
													substring(PartNumber,charindex('-',PartNumber)+1,
				 									charindex('-',PartNumber,charindex('-',PartNumber)+1) -
													len(substring(PartNumber,1, charindex('-',PartNumber)-1)) -2) 
											else ''
										end as Newcolor
									,RW.PartNumber
									,RW.FabricContent
								FROM		     [LCA].[dbo].[StatusNames]		AS SN	WITH(NOLOCK)	
								INNER JOIN	[LCA].[dbo].[RawMaterials]		AS RW	WITH(NOLOCK)	ON sn.StatusID = RW.StatusID		AND	RW.Statusid<=90 
								INNER JOIN	[LCA].[dbo].[ComponentLibrary]	AS CL2	WITH(NOLOCK)	ON RW.ComponentID = CL2.ComponentID AND CL2.ComponentCategoryID in (11)
							) PNCont
					on St.StyleNumber = PNCont.NewStyle and Stc.StyleColorName = PNCont.Newcolor

     UPDATE SCFC SET
          [FinalInvoicingDescription_ComponentRawMaterial]  = CASE 
                                                                 WHEN      Com.[InvoicingDescription_RawMaterials] IS NOT NULL 
                                                                      AND  (Com.[InvoicingDescription_Components] IS NOT NULL 
                                                                      AND  REPLACE(REPLACE(REPLACE(TRIM(Com.[InvoicingDescription_Components]),CHAR(10),''),CHAR(13),''),CHAR(9),'') != '')
                                                                           THEN Com.[InvoicingDescription_Components]+Com.[InvoicingDescription_RawMaterials]
                                                                 WHEN      Com.[InvoicingDescription_RawMaterials] IS NOT NULL 
                                                                      AND  (Com.[InvoicingDescription_Components] IS NULL 
                                                                      OR   REPLACE(REPLACE(REPLACE(TRIM(Com.[InvoicingDescription_Components]),CHAR(10),''),CHAR(13),''),CHAR(9),'') = '')
                                                                           THEN Com.[InvoicingDescription_RawMaterials]
                                                                 WHEN      Com.[InvoicingDescription_RawMaterials] IS NULL 
                                                                      AND  (Com.[InvoicingDescription_Components] IS NOT NULL 
                                                                      AND  REPLACE(REPLACE(REPLACE(TRIM(Com.[InvoicingDescription_Components]),CHAR(10),''),CHAR(13),''),CHAR(9),'') != '')
                                                                           THEN REPLACE(REPLACE(REPLACE(TRIM(Com.[InvoicingDescription_Components]),CHAR(10),''),CHAR(13),''),CHAR(9),'')
                                                                 ELSE
                                                                      Com.[DescribeText]
                                                              END
     FROM #TB_StyleComponentsRawMaterial AS SCFC
     LEFT JOIN
     (
          SELECT
                [StyleNumber]
               ,[StyleColor]
               ,[InvoicingDescription_Components]
               ,[InvoicingDescription_RawMaterials]
               ,[DescribeText]
          FROM #TB_StyleComponentsRawMaterial
          WHERE RowN = 1
     ) AS Com ON SCFC.[StyleNumber] = Com.[StyleNumber] AND SCFC.[StyleColor] = Com.[StyleColor]

--------------------------------------------------------- Component + RawMaterials Invoicing Description --------------------------------------------------------------------------

----------------------------------------------------------- Component Invoicing Description ------------------------------------------------------------------------------
     SELECT
           [StyleNumber]                          = ST.[StyleNumber]
          ,[DescribeText]                         = ST.[DescribeText]
          ,[InvoicingDescription_Components]      = CL.[FabricContent]
          ,[RowN]                                 = ROW_NUMBER() OVER(
                                                                           PARTITION BY 
                                                                                           st.[StyleNumber]
                                                                                          
                                                                           ORDER BY 
                                                                                           st.[StyleNumber]
                                                                                          ,std.[Quantity] 
                                                                      )
          ,[FinalInvoicingDescription_Component]  = CAST(NULL AS VARCHAR(200))
     INTO #TB_StyleComponents
     FROM        #TB_ActiveStyle                       AS   ST
     INNER JOIN  [LCA].[dbo].[StyleDetails]            AS   STD  WITH(NOLOCK)   ON   ST.[StyleID]             = STD.[StyleID]
     INNER JOIN  [LCA].[dbo].[ComponentLibrary]        AS   CL   WITH(NOLOCK)   ON   STD.[ComponentID]        = CL.[ComponentID] AND CL.ComponentCategoryID IN (1,11)
     INNER JOIN  [LCA].[dbo].[ComponentCategories]	AS   CC   WITH(NOLOCK)   ON   CC.[ComponentCategoryID]	= cl.[ComponentCategoryID]
     WHERE 
                         (       cl.FabricContent IS NOT NULL 
                         OR 
                              REPLACE(REPLACE(REPLACE(TRIM(cl.FabricContent),CHAR(10),''),CHAR(13),''),CHAR(9),'') <> ''
                    )

     UPDATE SCFC SET
          [FinalInvoicingDescription_Component] = Com.[InvoicingDescription_Components]
     FROM #TB_StyleComponents AS SCFC
     LEFT JOIN
     (
          SELECT
                [StyleNumber]
               ,[InvoicingDescription_Components]
          FROM #TB_StyleComponents
          WHERE RowN = 1
     ) AS Com ON SCFC.[StyleNumber] = Com.[StyleNumber]

----------------------------------------------------------- Component Invoicing Description ------------------------------------------------------------------------------

----------------------------------------------------------- Component Invoicing Description (Qty DESC) -------------------------------------------------------------------
     SELECT
           [StyleNumber]                          = ST.[StyleNumber]
          ,[DescribeText]                         = ST.[DescribeText]
          ,[InvoicingDescription_Components]      = CL.[FabricContent]
          ,[RowN]                                 = ROW_NUMBER() OVER(
                                                                           PARTITION BY 
                                                                                           st.[StyleNumber]
                                                                                          
                                                                           ORDER BY 
                                                                                           st.[StyleNumber]
                                                                                          ,std.[Quantity] DESC
                                                                      )
          ,[FinalInvoicingDescription_Component]  = CAST(NULL AS VARCHAR(200))
     INTO #TB_StyleComponents_QtyDesc
     FROM        #TB_ActiveStyle                       AS   ST
     INNER JOIN  [LCA].[dbo].[StyleDetails]            AS   STD  WITH(NOLOCK)   ON   ST.[StyleID]             = STD.[StyleID]
     INNER JOIN  [LCA].[dbo].[ComponentLibrary]        AS   CL   WITH(NOLOCK)   ON   STD.[ComponentID]        = CL.[ComponentID] AND CL.ComponentCategoryID IN (1,11)
     INNER JOIN  [LCA].[dbo].[ComponentCategories]	AS   CC   WITH(NOLOCK)   ON   CC.[ComponentCategoryID]	= cl.[ComponentCategoryID]
     WHERE 
                         (       cl.FabricContent IS NOT NULL 
                         OR 
                              REPLACE(REPLACE(REPLACE(TRIM(cl.FabricContent),CHAR(10),''),CHAR(13),''),CHAR(9),'') <> ''
                    )

     UPDATE SCFC SET
          [FinalInvoicingDescription_Component] = Com.[InvoicingDescription_Components]
     FROM #TB_StyleComponents_QtyDesc AS SCFC
     LEFT JOIN
     (
          SELECT
                [StyleNumber]
               ,[InvoicingDescription_Components]
          FROM #TB_StyleComponents_QtyDesc
          WHERE RowN = 1
     ) AS Com ON SCFC.[StyleNumber] = Com.[StyleNumber]

----------------------------------------------------------- Component Invoicing Description (Qty DESC) -------------------------------------------------------------------

----------------------------------------------------------- Component Invoicing Description por StyleOption --------------------------------------------------------------

SELECT
      [StyleNumber]				                    = ST.StyleNumber						                    
     ,[StyleColor]		                              = STC.StyleColorName
     ,[StyleOptionID]		                         = COALESCE(SOPT.StyleOptionID,0)
     ,[InvoicingDescription_ComponentsSO]		     = CL.[FabricContent] 
     ,[RowN]				                         = ROW_NUMBER() OVER (
                                                                                PARTITION BY 
                                                                                     ST.StyleNumber 
                                                                                     ,STC.StyleColorName
                                                                                     ,ISNULL(SOPT.StyleOptionID,0)
                                                                                ORDER BY 
                                                                                     ST.StyleNumber 
                                                                                     ,STC.StyleColorName 
                                                                                     ,ISNULL(SOPT.StyleOptionID,0)
                                                                                     ,STV.Quantity DESC
                                                                           )
     ,[FinalInvoicingDescription_ComponentStyleOption] = CAST(NULL AS VARCHAR(200))
INTO #TB_StyleComponents_Options
FROM		     [LCA].[dbo].[StatusNames]          AS snst   WITH(NOLOCK)
INNER JOIN	[LCA].[dbo].[styles]               AS st	WITH(NOLOCK) ON snst.StatusID           = st.StatusID				AND snst.StatusID = 64
INNER JOIN     [LCA].[dbo].[StyleVariations]		AS STV	WITH(NOLOCK) ON STV.StyleID			= ST.StyleID				AND STV.Quantity <> 0
INNER JOIN	[LCA].[dbo].[ComponentLibrary]	AS CL	WITH(NOLOCK) ON STV.ComponentID		= CL.ComponentID			AND CL.ComponentCategoryID = 1
INNER JOIN	[LCA].[dbo].[ComponentCategories]	AS cc	WITH(NOLOCK) ON cc.ComponentCategoryID  = CL.ComponentCategoryID	
INNER JOIN	[LCA].[dbo].[StyleDetails]		AS std	WITH(NOLOCK) ON std.StyleDetailID	     = STV.StyleDetailID
LEFT  JOIN	[LCA].[dbo].[BodyParts]			AS bp	WITH(NOLOCK) ON bp.BodyPartID		     = std.BodyPartID
LEFT  JOIN	[LCA].[dbo].[StyleColors]		AS STC	WITH(NOLOCK) ON STV.StyleColorID		= STC.StyleColorID 
LEFT  JOIN	[LCA].[dbo].[StyleOptions]		AS SOPT	WITH(NOLOCK) ON STV.StyleOptionID1	     = SOPT.StyleOptionID
WHERE
          BP.BodyPart LIKE '%Body%'

UPDATE SCFC SET
          [FinalInvoicingDescription_ComponentStyleOption] = Com.[InvoicingDescription_ComponentsSO]
     FROM #TB_StyleComponents_Options AS SCFC
     LEFT JOIN
     (
          SELECT
                [StyleNumber]
               ,[StyleColor]
               ,[StyleOptionID]
               ,[InvoicingDescription_ComponentsSO]
          FROM #TB_StyleComponents_Options
          WHERE RowN = 1
     ) AS Com ON SCFC.[StyleNumber] = Com.[StyleNumber] AND SCFC.[StyleColor] = Com.[StyleColor] AND SCFC.[StyleOptionID] = Com.[StyleOptionID]

----------------------------------------------------------- Component Invoicing Description por StyleOption --------------------------------------------------------------

---------------------------------------------------------------- HTS Codes Style Number - Style Color --------------------------------------------------------------------

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
                                                  WHEN ST.[Comments9] NOT LIKE '%Head%' AND HTS.[US_HTSCode] IS NOT NULL THEN '1- HTSStyleCodes Apparel Only'
                                                  WHEN LMN.[US_HTSCode] IS NOT NULL THEN '2- US_HTSCode RawMaterials using Component and PartColor'
                                                  WHEN LMN.[CA_HTSCode] IS NOT NULL THEN '3- CA_HTSCode RawMaterials using Component and PartColor'
                                                  WHEN HTS.[US_HTSCode] IS NOT NULL THEN '4- HTSStyleCodes'
                                                  ELSE 'NOT FOUND'
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
          WHEN ST.[Comments9] NOT LIKE '%Head%' AND HTS.[US_HTSCode] IS NOT NULL THEN '1- HTSStyleCodes Apparel Only'
          WHEN LMN.[US_HTSCode] IS NOT NULL THEN '2- US_HTSCode RawMaterials using Component and PartColor'
          WHEN LMN.[CA_HTSCode] IS NOT NULL THEN '3- CA_HTSCode RawMaterials using Component and PartColor'
          WHEN HTS.[US_HTSCode] IS NOT NULL THEN '4- HTSStyleCodes'
          ELSE 'NOT FOUND'
      END

---------------------------------------------------------------- HTS Codes Style Number - Style Color --------------------------------------------------------------------

SELECT
      [StyleNumber]                               = ST.[StyleNumber]
     ,[StyleColor]                                = STC.[StyleColorName]
     ,[DescribeText]                              = ST.[DescribeText]
     ,[InvoicingDescription_Styles]               = ST.[InvoicingDescription_Styles]
     ,[StyleOptionID]                             = STV.[StyleOptionID1]
     ,[InvoicingDescription_Component]            = CAST(NULL AS VARCHAR(200))
     ,[InvoicingDescription_Component2]           = CAST(NULL AS VARCHAR(200))
     ,[InvoicingDescription_RawMaterial]          = CAST(NULL AS VARCHAR(200))
     ,[InvoicingDescription_StyleColorOption]     = CAST(NULL AS VARCHAR(200))
     ,[InvoicingDescription_Component_QtyDesc]    = CAST(NULL AS VARCHAR(200))
     ,[Final_InvoicingDescription]                = CAST(NULL AS VARCHAR(200))
     ,[OptionCI_InvoicingDescription]             = CAST(NULL AS VARCHAR(100))
     ,[FinalReportCI_InvoicingDescription]        = CAST(NULL AS VARCHAR(200))
     ,[US_HTSCode_StyleCodes]                     = CAST(NULL AS VARCHAR(100))
     ,[US_HTSCode_RawMaterials]                   = CAST(NULL AS VARCHAR(100))
     ,[CA_HTSCode_RawMaterials]                   = CAST(NULL AS VARCHAR(100))
     ,[US_HTSCode_StyleCodes2]                    = CAST(NULL AS VARCHAR(100))
     ,[FinalCI_US_HTSCode]                        = CAST(NULL AS VARCHAR(100))
     ,[Option_US_HTSCode]                         = CAST(NULL AS VARCHAR(100))
INTO #TB_AllStyleInfo
FROM #TB_ActiveStyle AS ST
LEFT JOIN  [LCA].[dbo].[StyleVariations]         AS   STV  WITH(NOLOCK)   ON   ST.[StyleID]             = STV.[StyleID]
LEFT JOIN  [LCA].[dbo].[StyleColors]             AS   STC WITH(NOLOCK)    ON   STV.[StyleColorID]       = STC.[StyleColorID]

GROUP BY
      ST.[StyleNumber]
     ,STC.[StyleColorName]
     ,ST.[DescribeText]
     ,ST.[InvoicingDescription_Styles]
     ,STV.[StyleOptionID1]

UPDATE SI SET
      [InvoicingDescription_Component]            = SC.[InvoicingDescription_Components]
     ,[InvoicingDescription_Component2]           = SCR.[InvoicingDescription_Components]
     ,[InvoicingDescription_RawMaterial]          = SCR.[InvoicingDescription_RawMaterials]
     ,[Final_InvoicingDescription]                = CASE
                                                       WHEN (SCR.[InvoicingDescription_Components] IS NOT NULL AND REPLACE(REPLACE(REPLACE(TRIM(SCR.[InvoicingDescription_Components]),CHAR(10),''),CHAR(13),''),CHAR(9),'') != '')
                                                            AND SCR.[InvoicingDescription_RawMaterials] IS NOT NULL
                                                                 THEN SCR.[InvoicingDescription_Components] + SCR.[InvoicingDescription_RawMaterials]
                                                       WHEN (SCR.[InvoicingDescription_Components] IS NULL OR REPLACE(REPLACE(REPLACE(TRIM(SCR.[InvoicingDescription_Components]),CHAR(10),''),CHAR(13),''),CHAR(9),'') = '')
                                                            AND SCR.[InvoicingDescription_RawMaterials] IS NOT NULL
                                                                 THEN SCR.[InvoicingDescription_RawMaterials]
                                                       WHEN (SCR.[InvoicingDescription_Components] IS NOT NULL AND REPLACE(REPLACE(REPLACE(TRIM(SCR.[InvoicingDescription_Components]),CHAR(10),''),CHAR(13),''),CHAR(9),'') != '')
                                                            AND SCR.[InvoicingDescription_RawMaterials] IS NULL
                                                                 THEN SCR.[InvoicingDescription_Components]
                                                       WHEN SC.[InvoicingDescription_Components] IS NOT NULL THEN SC.[InvoicingDescription_Components]
                                                       WHEN SCO.[InvoicingDescription_ComponentsSO] IS NOT NULL THEN SCO.[InvoicingDescription_ComponentsSO]
                                                       WHEN SCQ.[InvoicingDescription_Components] IS NOT NULL THEN SCQ.[InvoicingDescription_Components]
                                                       WHEN SI.[InvoicingDescription_Styles] IS NOT NULL THEN SI.[InvoicingDescription_Styles]
                                                       ELSE ''
                                                    END
     ,[OptionCI_InvoicingDescription]             = CASE
                                                       WHEN (SCR.[InvoicingDescription_Components] IS NOT NULL AND REPLACE(REPLACE(REPLACE(TRIM(SCR.[InvoicingDescription_Components]),CHAR(10),''),CHAR(13),''),CHAR(9),'') != '')
                                                            AND SCR.[InvoicingDescription_RawMaterials] IS NOT NULL
                                                                 THEN '1- Concat FabricContent RawMaterials + Components'
                                                       WHEN (SCR.[InvoicingDescription_Components] IS NULL OR REPLACE(REPLACE(REPLACE(TRIM(SCR.[InvoicingDescription_Components]),CHAR(10),''),CHAR(13),''),CHAR(9),'') = '')
                                                            AND SCR.[InvoicingDescription_RawMaterials] IS NOT NULL
                                                                 THEN '2- FabricContent RawMaterials'
                                                       WHEN (SCR.[InvoicingDescription_Components] IS NOT NULL AND REPLACE(REPLACE(REPLACE(TRIM(SCR.[InvoicingDescription_Components]),CHAR(10),''),CHAR(13),''),CHAR(9),'') != '')
                                                            AND SCR.[InvoicingDescription_RawMaterials] IS NULL
                                                                 THEN '3- FabricContent Components from StyleVariations'
                                                       WHEN SC.[InvoicingDescription_Components] IS NOT NULL THEN '4- FabricContent Components from StyleDetails'
                                                       WHEN SI.[InvoicingDescription_Styles] IS NOT NULL THEN '5- Description3 Styles'
                                                       WHEN SCO.[InvoicingDescription_ComponentsSO] IS NOT NULL THEN '6- FabricContent Components using StyleOptions'
                                                       WHEN SCQ.[InvoicingDescription_Components] IS NOT NULL THEN '7- FabricContent Components (RowNumber order by Quantity desc of StyleDetails)'
                                                       ELSE 'NOT FOUND'
                                                    END
     ,[US_HTSCode_StyleCodes]                     = SCH.[US_HTSCode_StyleCodes]
     ,[US_HTSCode_RawMaterials]                   = SCH.[US_HTSCode_RawMaterials]
     ,[CA_HTSCode_RawMaterials]                   = SCH.[CA_HTSCode_RawMaterials]
     ,[US_HTSCode_StyleCodes2]                    = SCH.[US_HTSCode_StyleCodes2]
     ,[FinalCI_US_HTSCode]                        = SCH.[FinalCI_US_HTSCode]
     ,[Option_US_HTSCode]                         = SCH.[Option_US_HTSCode]
FROM #TB_AllStyleInfo AS SI
LEFT JOIN #TB_StyleComponents AS SC ON SI.[StyleNumber] = SC.[StyleNumber] and SC.[RowN] = 1
LEFT JOIN #TB_StyleComponentsRawMaterial AS SCR ON SI.[StyleNumber] = SCR.[StyleNumber] AND SI.[StyleColor] = SCR.[StyleColor] AND SCR.[RowN] = 1
LEFT JOIN #TB_StyleComponents_QtyDesc AS SCQ ON SI.[StyleNumber] = SCQ.[StyleNumber] AND SCQ.[RowN] = 1
LEFT JOIN #TB_StyleComponents_Options AS SCO ON SI.[StyleNumber] = SCO.[StyleNumber] AND SI.[StyleColor] = SCO.[StyleColor] AND SI.[StyleOptionID] = SCO.[StyleOptionID] AND SCO.[RowN] = 1
LEFT JOIN #TB_StyleColor_HTS          AS SCH ON SI.[StyleNumber] = SCH.[StyleNumber] AND SI.[StyleColor] = SCH.[StyleColor]

UPDATE ASI SET
     [FinalReportCI_InvoicingDescription] = CONCAT([DescribeText],' ',[Final_InvoicingDescription])
FROM #TB_AllStyleInfo AS ASI

SELECT 
      [StyleNumber]
     ,[StyleColor]
     ,[InvoicingDescription_Component]
     ,[InvoicingDescription_Component2]
     ,[InvoicingDescription_RawMaterial]
     ,[InvoicingDescription_Styles]
     ,[Final_InvoicingDescription]
     ,[OptionCI_InvoicingDescription]
     ,[US_HTSCode_StyleCodes]
     ,[US_HTSCode_RawMaterials]
     ,[CA_HTSCode_RawMaterials]
     ,[US_HTSCode_StyleCodes2]
FROM #TB_AllStyleInfo
WHERE StyleColor IS NOT NULL
ORDER BY StyleNumber, StyleColor

SELECT 
*
FROM #TB_AllStyleInfo
WHERE StyleColor IS NOT NULL
ORDER BY StyleNumber, StyleColor
