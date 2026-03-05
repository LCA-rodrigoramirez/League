------==================================================== SECCIÓN DE ELIMINACIÓN DE TABLAS TEMPORALES =============================================------

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

------==================================================== SECCIÓN DE ELIMINACIÓN DE TABLAS TEMPORALES =============================================------

------=================================================== FILTRO DE SEASONS QUE NO SEAN FULL NI BLANK FG ===========================================------

     /*
      Objetivo:
      Construir un catálogo de seasons válidas para excluir las que no están relacionadas con estilos Blank FG y Full
      Relación:
      Se consulta directamente LCA.dbo.Seasons y se filtra por SeasonID usando una lista de exclusión funcional.
      Resultado:
      #TB_Seasons se usa como dimensión de control para limitar los estilos a seasons principales.
     */
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

------=================================================== FILTRO DE SEASONS QUE NO SEAN FULL NI BLANK FG ===========================================------

------=================================================== FILTRO DE STYLES FINAL REL CON SEASONS VÁLIDAS ===========================================------

     /*
      Objetivo:
      Obtener la base de estilos activos o Final Rel (StatusID = 64) que además pertenezcan a seasons válidas.
      Relaciones:
      1) StatusNames (filtro de estado "Final Rel") -> Styles por StatusID.
      2) Styles -> #TB_Seasons por SeasonID para aplicar el alcance de temporadas permitido.
      Resultado:
      #TB_ActiveStyle concentra StyleNumber, StyleID y textos descriptivos que alimentan todo el proceso.
     */
     SELECT
          [StyleNumber]                               = ST.[StyleNumber]
          ,[StyleID]                                   = ST.[StyleID]
          ,[DescribeText]                              = ST.[DescribeText]
          ,[InvoicingDescription_Styles]               = ST.[Description3]
     INTO #TB_ActiveStyle
     FROM (SELECT * FROM [LCA].[dbo].[StatusNames] AS SN WITH(NOLOCK) WHERE [StatusID] = 64) AS FILSN
          INNER JOIN  [LCA].[dbo].[Styles]             AS   ST   WITH(NOLOCK)   ON   ST.[StatusID]            = FILSN.[StatusID]
          INNER JOIN  #TB_Seasons                      AS   SNS  WITH(NOLOCK)   ON   ST.[SeasonID]            = SNS.[SeasonID]

------=================================================== FILTRO DE STYLES FINAL REL CON SEASONS VÁLIDAS ===========================================------


--------------------------------------------------------- Component + RawMaterials Invoicing Description --------------------------------------------------------------------------
     
     /*
      Objetivo:
      Consolidar por Style+Color los posibles FabricContent de Components y RawMaterials, priorizando un registro con ROW_NUMBER().
      Relaciones:
      1) #TB_ActiveStyle -> StyleVariations -> StyleColors -> StyleDetails -> ComponentLibrary.
      2) ComponentLibrary se restringe a categorías 1 y 11 para contenido textil dentro de Fabric y Contracts.
      3) LEFT JOIN a subconsulta de RawMaterials:
         - Descompone PartNumber para derivar Style y Color (NewStyle/NewColor).
         - Filtra materiales con StatusID <= 90 y ComponentCategoryID = 11.
         - Relaciona por StyleNumber + StyleColorName.
      Lógica técnica:
      ROW_NUMBER() particiona por StyleNumber y StyleColor para permitir seleccionar el registro prioritario (RowN = 1) ordenado por Quantity
      de StyleDetails.
      */
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


     /*
      Objetivo:
      Definir FinalInvoicingDescription_ComponentRawMaterial con prioridad funcional entre Components, RawMaterials y DescribeText.
      Relación:
      Se actualiza #TB_StyleComponentsRawMaterial usando un LEFT JOIN a sí misma filtrada en RowN = 1 (registro representativo por Style+Color).
      CASE aplicado:
      1) Si existen Components (no vacío tras limpieza de espacios/CR/LF/TAB) y RawMaterials -> concatena ambos.
      2) Si Components está nulo/vacío y RawMaterials existe -> usa RawMaterials.
      3) Si RawMaterials no existe y Components válido -> usa Components normalizado.
      4) Fallback -> DescribeText del style.
      */
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
     /*
      Objetivo:
      Obtener FabricContent de Components por Style desde StyleDetails (sin nivel de color), seleccionando un candidato por cantidad ascendente.
      Relaciones:
      #TB_ActiveStyle -> StyleDetails -> ComponentLibrary (categorías 1 y 11) -> ComponentCategories.
      Criterio:
      Se excluyen FabricContent nulos/vacíos (limpieza con TRIM + reemplazo de CR/LF/TAB).
      ROW_NUMBER():
      Particiona por StyleNumber y ordena por Quantity ascendente para identificar RowN = 1.
      */
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

     /*
      Objetivo:
      Propagar a todas las filas del style el FabricContent base elegido (RowN = 1).
      Relación:
      #TB_StyleComponents se actualiza mediante LEFT JOIN a su subconjunto RowN = 1 por StyleNumber.
      */
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
     /*
      Objetivo:
      Generar una alternativa de FabricContent por Style, priorizando componentes de mayor Quantity.
      Relaciones:
      #TB_ActiveStyle -> StyleDetails -> ComponentLibrary (cat. 1 y 11) -> ComponentCategories.
      Diferencia frente al bloque anterior:
      ROW_NUMBER() ordena por Quantity DESC para capturar primero el componente con mayor peso/cantidad.
      */
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

     /*
      Objetivo:
      Fijar FinalInvoicingDescription_Component usando la versión priorizada por Quantity descendente (RowN = 1).
      Relación:
      UPDATE sobre #TB_StyleComponents_QtyDesc enlazando por StyleNumber contra su propio subconjunto de primera fila.
      */
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

/*
 Objetivo:
 Obtener FabricContent por combinación Style + Color + StyleOption, útil cuando la composición varía por opción.
 Relaciones:
 1) StatusNames (64) -> Styles.
 2) Styles -> StyleVariations (solo Quantity <> 0).
 3) StyleVariations -> ComponentLibrary (solo categoría 1).
 4) StyleVariations -> StyleDetails -> BodyParts (filtro BodyPart LIKE '%Body%').
 5) StyleVariations -> StyleColors y StyleOptions para granularidad color/opción.
 Lógica:
 ROW_NUMBER() por Style+Color+StyleOption ordenado por Quantity DESC para seleccionar el componente dominante.
*/
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

/*
 Objetivo:
 Asignar a cada combinación Style+Color+StyleOption su FabricContent principal (RowN = 1).
 Relación:
 UPDATE sobre #TB_StyleComponents_Options con LEFT JOIN al subconjunto líder por las tres llaves.
*/
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

     /*
      Objetivo:
      Resolver el HTS final por Style+Color combinando fuentes de Styles (HTSStyleCodes) y RawMaterials.
      Relaciones:
      1) StatusNames(64) -> Styles -> #TB_Seasons para limitar estilos válidos.
      2) Styles -> HTSStyleCodes para HTS directo de style.
      3) Styles -> StyleVariations -> StyleColors para nivel de color.
      4) LEFT JOIN a subconsulta LMN de RawMaterials:
         - RawMaterials -> Colors + ComponentLibrary(cat.11) + DropDownValues.
         - ROW_NUMBER() por Color+ComponentName para evitar duplicados y dejar un HTS por combinación.
         - Mapeo final por StyleNumber = LMN.Style y StyleColorName = LMN.Color.
      CASE en FinalCI_US_HTSCode:
      Prioriza HTS de StyleCodes para apparel no Headwear; luego US_HTSCode de RawMaterials; luego CA_HTSCode; luego fallback a HTSStyleCodes.
      CASE en Option_US_HTSCode:
      Etiqueta la ruta de decisión aplicada para trazabilidad del origen del HTS.
      */
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

/*
 Objetivo:
 Crear tabla consolidada base por Style+Color+StyleOption para montar la descripción final de CI y HTS final.
 Relaciones:
 #TB_ActiveStyle -> StyleVariations -> StyleColors para generar las combinaciones comerciales y columnas en NULL inicial.
 Nota:
 El GROUP BY elimina duplicidad natural por múltiples variaciones del mismo style/color/opción.
*/
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

/*
 Objetivo:
 Enriquecer #TB_AllStyleInfo con descripciones de tela y HTS provenientes de todas las fuentes temporales.
 Relaciones:
 1) SI <- SC (components por StyleDetails).
 2) SI <- SCR (components + rawmaterials por Style+Color).
 3) SI <- SCQ (alternativa por Quantity DESC).
 4) SI <- SCO (components por StyleOption).
 5) SI <- SCH (HTS final por Style+Color).
 CASE en Final_InvoicingDescription:
 Prioridad de composición:
 1) Concat Components + RawMaterials cuando ambos existen.
 2) Solo RawMaterials si Components está nulo/vacío.
 3) Solo Components de SCR si RawMaterials no existe.
 4) Components desde SC.
 5) Components desde SCO.
 6) Components desde SCQ.
 7) InvoicingDescription_Styles como fallback final.
 CASE en OptionCI_InvoicingDescription:
 Registra la ruta exacta usada para construir Final_InvoicingDescription con etiquetas 1..7 y NOT FOUND.
*/
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

/*
 Objetivo:
 Construir el campo final de reporte uniendo la descripción corta del estilo con la composición resuelta.
 Relación:
 UPDATE directo sobre #TB_AllStyleInfo sin joins externos.
*/
UPDATE ASI SET
     [FinalReportCI_InvoicingDescription] = CONCAT([DescribeText],' ',[Final_InvoicingDescription])
FROM #TB_AllStyleInfo AS ASI

----- RESULTADO FINAL ------
SELECT 
*
FROM #TB_AllStyleInfo
WHERE StyleColor IS NOT NULL
ORDER BY StyleNumber, StyleColor
