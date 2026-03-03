DROP TABLE IF EXISTS #TB_ActiveStyle
DROP TABLE IF EXISTS #TB_AllStyleInfo
DROP TABLE IF EXISTS #TB_StyleComponents
DROP TABLE IF EXISTS #TB_StyleComponents_QtyDesc
DROP TABLE IF EXISTS #TB_StyleComponentsRawMaterial
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

----------------------------------------------------------- Component Invoicing Description ------------------------------------------------------------------------------
SELECT
      [StyleNumber]                               = ST.[StyleNumber]
     ,[StyleColor]                                = STC.[StyleColorName]
     ,[DescribeText]                              = ST.[DescribeText]
     ,[InvoicingDescription_Styles]               = ST.[InvoicingDescription_Styles]
     ,[InvoicingDescription_Component]            = CAST(NULL AS VARCHAR(200))
     ,[InvoicingDescription_Component2]           = CAST(NULL AS VARCHAR(200))
     ,[InvoicingDescription_RawMaterial]          = CAST(NULL AS VARCHAR(200))
     ,[InvoicingDescription_StyleColorOption]     = CAST(NULL AS VARCHAR(200))
     ,[InvoicingDescription_Component_QtyDesc]    = CAST(NULL AS VARCHAR(200))
     ,[FinalCI_InvoicingDescription]              = CAST(NULL AS VARCHAR(200))
     ,[OptionCI_InvoicingDescription]             = CAST(NULL AS INT)
INTO #TB_AllStyleInfo
FROM #TB_ActiveStyle AS ST
LEFT JOIN  [LCA].[dbo].[StyleVariations]         AS   STV  WITH(NOLOCK)   ON   ST.[StyleID]             = STV.[StyleID]
LEFT JOIN  [LCA].[dbo].[StyleColors]             AS   STC WITH(NOLOCK)    ON   STV.[StyleColorID]       = STC.[StyleColorID]

GROUP BY
      ST.[StyleNumber]
     ,STC.[StyleColorName]
     ,ST.[DescribeText]
     ,ST.[InvoicingDescription_Styles]

UPDATE SI SET
      [InvoicingDescription_Component]            = SC.[InvoicingDescription_Components]
     ,[InvoicingDescription_Component2]           = SCR.[InvoicingDescription_Components]
     ,[InvoicingDescription_RawMaterial]          = SCR.[InvoicingDescription_RawMaterials]
     ,[FinalCI_InvoicingDescription]              = CASE
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
                                                       WHEN SI.[InvoicingDescription_Styles] IS NOT NULL THEN SI.[InvoicingDescription_Styles]
                                                       WHEN SCQ.[InvoicingDescription_Components] IS NOT NULL THEN SCQ.[InvoicingDescription_Components]
                                                       ELSE ''
                                                    END
     ,[OptionCI_InvoicingDescription]             = CASE
                                                       WHEN (SCR.[InvoicingDescription_Components] IS NOT NULL AND REPLACE(REPLACE(REPLACE(TRIM(SCR.[InvoicingDescription_Components]),CHAR(10),''),CHAR(13),''),CHAR(9),'') != '')
                                                            AND SCR.[InvoicingDescription_RawMaterials] IS NOT NULL
                                                                 THEN 1
                                                       WHEN (SCR.[InvoicingDescription_Components] IS NULL OR REPLACE(REPLACE(REPLACE(TRIM(SCR.[InvoicingDescription_Components]),CHAR(10),''),CHAR(13),''),CHAR(9),'') = '')
                                                            AND SCR.[InvoicingDescription_RawMaterials] IS NOT NULL
                                                                 THEN 2
                                                       WHEN (SCR.[InvoicingDescription_Components] IS NOT NULL AND REPLACE(REPLACE(REPLACE(TRIM(SCR.[InvoicingDescription_Components]),CHAR(10),''),CHAR(13),''),CHAR(9),'') != '')
                                                            AND SCR.[InvoicingDescription_RawMaterials] IS NULL
                                                                 THEN 3
                                                       WHEN SC.[InvoicingDescription_Components] IS NOT NULL THEN 4
                                                       WHEN SI.[InvoicingDescription_Styles] IS NOT NULL THEN 5
                                                       WHEN SCQ.[InvoicingDescription_Components] IS NOT NULL THEN 7
                                                       ELSE 8
                                                    END
FROM #TB_AllStyleInfo AS SI
LEFT JOIN #TB_StyleComponents AS SC ON SI.[StyleNumber] = SC.[StyleNumber] and SC.[RowN] = 1
LEFT JOIN #TB_StyleComponentsRawMaterial AS SCR ON SI.[StyleNumber] = SCR.[StyleNumber] AND SI.[StyleColor] = SCR.[StyleColor] AND SCR.[RowN] = 1
LEFT JOIN #TB_StyleComponents_QtyDesc AS SCQ ON SI.[StyleNumber] = SCQ.[StyleNumber] AND SCQ.[RowN] = 1

SELECT 
*
FROM #TB_AllStyleInfo
WHERE StyleColor IS NOT NULL
ORDER BY StyleNumber, StyleColor
