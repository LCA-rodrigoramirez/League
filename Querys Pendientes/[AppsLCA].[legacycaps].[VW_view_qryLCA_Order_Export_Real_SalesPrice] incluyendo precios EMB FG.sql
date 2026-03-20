USE [AppsLCA]
GO

/****** Object:  View [legacycaps].[VW_view_qryLCA_Order_Export_Real_SalesPrice]    Script Date: 09/03/2026 09:05:51 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER VIEW [legacycaps].[VW_view_qryLCA_Order_Export_Real_SalesPrice]
						 --VW_view_qryLCA_Order_Export_Real_SalesPrice
AS

--- ################################## PRECIO DESDE ÚLTIMA ORDEN DE COMPRA POR CADA STYLE Y COLOR #########################################

WITH CTE_TB_Component	AS (
		SELECT 
			 [ComponentID]			= cl.ComponentID 
			,[ComponentName]        = cl.ComponentName
		FROM [LCA].[dbo].[ComponentLibrary] AS cl WITH(NOLOCK) 
		WHERE  (cl.ComponentCategoryID in ( 11))
)
,CTE_ComponentColor
AS
(
    SELECT
         [ComponentName]        = LTRIM(RTRIM(CL.[ComponentName]))
        ,[ComponentID]          = CL.[ComponentID]
        ,[ColorName]            = PC.[ColorName]
        ,[ColorID]              = PC.[ColorID]
        ,[OrderDate]            = MAX(PO.[OrderDate])
    --select *
    FROM CTE_TB_Component                       AS CL
    INNER JOIN [LCA].[dbo].[RawMaterials]       AS RM ON CL.[ComponentID] = RM.[ComponentID] AND RM.[StatusID] <= 90
    INNER JOIN [LCA].[dbo].[Colors]             AS PC ON RM.[ColorID] = PC.[ColorID]
    INNER JOIN [LCA].[dbo].[PurchaseDetails]    AS PD ON RM.[RawMaterialID] = PD.[RawMaterialID]
    INNER JOIN [LCA].[dbo].[PurchaseOrders]     AS PO ON PD.[PurchaseID] = PO.[PurchaseID]
    GROUP BY
         CL.[ComponentName]
        ,CL.[ComponentID]
        ,PC.[ColorName]
        ,PC.[ColorID]   
)

,CTE_PricePurchaseOrder
AS
(
    SELECT 
         [ComponentName]        = TRIM(REPLACE(REPLACE(REPLACE(CC.[ComponentName], CHAR(10), ''), CHAR(9), ''), CHAR(13), ''))
        ,[ComponentID]          = CC.[ComponentID]
        ,[ColorName]            = CC.[ColorName]
        ,[ColorID]              = CC.[ColorID]
        ,[UnitPrice]            = MAX(PD.[UnitPrice])
    FROM CTE_ComponentColor AS CC
    INNER JOIN [LCA].[dbo].[RawMaterials]       AS RM ON CC.[ComponentID] = RM.[ComponentID] AND RM.[ColorID] = CC.[ColorID] AND RM.[StatusID] <= 90
    INNER JOIN [LCA].[dbo].[PurchaseDetails]    AS PD ON RM.[RawMaterialID] = PD.[RawMaterialID]
    INNER JOIN [LCA].[dbo].[PurchaseOrders]     AS PO ON PD.[PurchaseID] = PO.[PurchaseID] AND PO.[OrderDate] = CC.[OrderDate]
    GROUP BY
         CC.[ComponentName]
        ,CC.[ComponentID]
        ,CC.[ColorName]
        ,CC.[ColorID]
)
-- SELECT * FROM CTE_PricePurchaseOrder WHERE ComponentName = '30028'

--- ################################## PRECIO DESDE ÚLTIMA ORDEN DE COMPRA POR CADA STYLE Y COLOR #########################################

SELECT DISTINCT TOP 100 PERCENT
        --################################## CAMPOS QUERY LEGACY Y CALCULO DE SIZE, STYLE Y COLOR ##########################################
       	TBM.*
    --################################ CAMPOS SALESPRICE POR COLOR Y STYLES ####################################
    ,COALESCE(sp.[Embellishment], sp4.[Embellishment], sp3.[Embellishment], sp5.Embellishment, 0.00)                  AS Embellishment
    ,COALESCE(sp.[CostBlank], sp4.[CostBlank], sp3.[CostBlank], sp5.CostBlank, CPPO.UnitPrice, CPPO2.UnitPrice,0.00) AS CostBlank
    ,COALESCE(sp.[OtherEmbCost], sp4.[OtherEmbCost], sp3.[OtherEmbCost], sp5.OtherEmbCost, 0.00)                     AS OtherEmbCost

	,COALESCE(sp.[Embellishment], sp4.[Embellishment], sp3.[Embellishment], sp5.Embellishment, 0.00) +
	COALESCE(sp.[CostBlank], sp4.[CostBlank], sp3.[CostBlank], sp5.CostBlank, CPPO.UnitPrice, CPPO2.UnitPrice, 0.00) +
	COALESCE(sp.[OtherEmbCost], sp4.[OtherEmbCost], sp3.[OtherEmbCost], sp5.OtherEmbCost, 0.00)		AS [Unit Price]
    --######################## BUSCA SEASON EN DOS VISTAS DIFERENTES EN CASO QUE SEA NUEVA #################### 
	,s2.Season                            AS Season2
	,s3.Season                            AS Season3
    --############################## OPTENEMOS PORCION DE TEXTO DE STATUSDATE #################################
    ,CASE   
            WHEN TBM.[Status/Date] = NULL OR TBM.[Status/Date] = '' THEN   
                'NULL' 
            WHEN CHARINDEX(' ', TBM.[Status/Date]) = 0 THEN
                TBM.[Status/Date]
            ELSE 
                SUBSTRING( TBM.[Status/Date], 1, ( CHARINDEX(' ', TBM.[Status/Date]) - 1 ) )
        END                                AS [StatusLegacy]
        --########################## CAMPOS PARA EXCEPCIONES DE STYLE DE TALLA UNICA ############################
    --,us.ItemNewText                     AS [ItemNewText_US]
    --,us.Size                            as [Size_US]
FROM  [AppsLCA].[legacycaps].[VW_Planning_DataLegacy_Process_SizeStyleColor]    AS TBM
LEFT  JOIN    [AppsLCA].[legacycaps].[VW_Planning_ImportMO_Season]  AS s2
ON TBM.Style = s2.Style AND TBM.Color = s2.Color

LEFT  JOIN [AppsLCA].[legacycaps].[VW_Planning_Distinct_Season_VW_StyleMaster]  AS s3 
ON TBM.Style = s3.StyleNumber  

LEFT  JOIN [LCA].[dbo].[Styles]   AS ST   WITH(NOLOCK) ON ST.StyleID = S2.StyleID
LEFT  JOIN [LCA].[dbo].[Styles]   AS PST  WITH(NOLOCK) ON ST.BlankStyleID = PST.StyleID
LEFT  JOIN CTE_PricePurchaseOrder AS CPPO WITH(NOLOCK) ON COALESCE(PST.StyleNumber,ST.StyleNumber) = CPPO.ComponentName AND TBM.Color = CPPO.ColorName
LEFT  JOIN
(
    SELECT
         [ComponentName]    = [ComponentName]
        ,[ComponentID]      = [ComponentID]
        ,[UnitPrice]        = MAX([UnitPrice])
    FROM CTE_PricePurchaseOrder WITH(NOLOCK)
    GROUP BY
         [ComponentName]
        ,[ComponentID]
) AS CPPO2 ON COALESCE(PST.StyleNumber,ST.StyleNumber) = CPPO2.ComponentName
--Para estilos con precio en el seson SemiElaborados
LEFT JOIN OPENQUERY([mariadb],'SELECT   `Sales_Prices_New`.`Style`,                                         
                                                `Sales_Prices_New`.`Color`,                                  
                                                `Sales_Prices_New`.`Embellishment`,                            
                                                `Sales_Prices_New`.`CostBlank`,                                                
                                                `Sales_Prices_New`.`OtherEmbCost`,
												`Sales_Prices_New`.`Season`,                               
												`Sales_Prices_New`.`StyleID`,
												ROW_NUMBER() OVER(PARTITION BY `Sales_Prices_New`.`StyleID`, `Sales_Prices_New`.`Color`
																  ORDER BY `Sales_Prices_New`.`StyleID`, `Sales_Prices_New`.`Color`,
																			`Sales_Prices_New`.`CostBlank` DESC) AS RowN
                                            FROM `wordpress`.`Sales_Prices_New`
											where (styleoptionname1 like "%stand%" or styleoptionname1 is null OR styleoptionname1 = ''''
													   OR styleoptionname1 LIKE "%NO OPTION%")
											and Season  NOT IN ("BLANK","Blank RO","EXP BO","EMB","BLANK FG")
											') AS sp
on s2.Styleid = sp.Styleid and s2.Color=sp.Color and sp.RowN = 1 --and s2.Season=sp.Season

LEFT JOIN OPENQUERY([mariadb],'SELECT   `Sales_Prices_New`.`Style`,                                         
                                                `Sales_Prices_New`.`Color`,                                  
                                                `Sales_Prices_New`.`Embellishment`,                            
                                                `Sales_Prices_New`.`CostBlank`,                                                
                                                `Sales_Prices_New`.`OtherEmbCost`,
												`Sales_Prices_New`.`Season`,                               
												`Sales_Prices_New`.`StyleID`,
												ROW_NUMBER() OVER(PARTITION BY `Sales_Prices_New`.`StyleID`, `Sales_Prices_New`.`Color`
																  ORDER BY `Sales_Prices_New`.`StyleID`, `Sales_Prices_New`.`Color`,
																			`Sales_Prices_New`.`CostBlank` DESC) AS RowN
												
                                            FROM `wordpress`.`Sales_Prices_New`
											where (styleoptionname1 like "%stand%" or styleoptionname1 is null OR styleoptionname1 = ''''
													   OR styleoptionname1 LIKE "%NO OPTION%")
											and Season  IN ("EMB FG")
											') AS sp5
on TBM.Style = sp5.Style and TBM.Color=sp5.Color and sp5.RowN = 1

--on s2.Style = sp.Style and s2.Color=sp.Color --and s2.Season=sp.Season
--Para Estilos con Season Full
LEFT JOIN OPENQUERY([mariadb],'SELECT `Sales_Prices_New`.`Style`,                                         
                                                `Sales_Prices_New`.`Color`,                                  
                                                `Sales_Prices_New`.`Embellishment`,                            
                                                `Sales_Prices_New`.`CostBlank`,                                                
                                                `Sales_Prices_New`.`OtherEmbCost`,
												`Sales_Prices_New`.`Season`,                               
												`Sales_Prices_New`.`StyleID`,
												ROW_NUMBER() OVER(PARTITION BY `Sales_Prices_New`.`StyleID`, `Sales_Prices_New`.`Color`,`Sales_Prices_New`.`Season`
																  ORDER BY `Sales_Prices_New`.`StyleID`, `Sales_Prices_New`.`Color`,`Sales_Prices_New`.`Season`, 
																			`Sales_Prices_New`.`CostBlank` DESC) AS RowN
                                            FROM `wordpress`.`Sales_Prices_New` 
											where (styleoptionname1 is null
													   OR styleoptionname1 = ''''
													   OR styleoptionname1 LIKE "%NO OPTION%"
													   OR styleoptionname1 LIKE "%2nd%"
													   OR styleoptionname1 LIKE "%3rd%" 
													   OR styleoptionname1 LIKE "%4th%" 
													   OR styleoptionname1 LIKE "%5th%"
													   OR styleoptionname1 LIKE "%N/A%")
											and Season NOT IN ("BLANK","Blank RO","EXP BO","EMB","BLANK FG")
											')  AS sp3
--on s3.StyleID =sp3.Styleid and TBM.Color=sp3.Color --and s3.Season=sp3.Season
on s3.StyleNumber =sp3.Style and TBM.Color=sp3.Color and s3.Season=sp3.Season and sp3.RowN = 1

---Para estilos con Season Full
LEFT JOIN OPENQUERY([mariadb],'SELECT   `Sales_Prices_New`.`Style`,                                         
                                                `Sales_Prices_New`.`Color`,                                  
                                                `Sales_Prices_New`.`Embellishment`,                            
                                                `Sales_Prices_New`.`CostBlank`,                                                
                                                `Sales_Prices_New`.`OtherEmbCost`,
												`Sales_Prices_New`.`Season`,                               
												`Sales_Prices_New`.`StyleID`,
												ROW_NUMBER() OVER(PARTITION BY `Sales_Prices_New`.`StyleID`, `Sales_Prices_New`.`Color`,`Sales_Prices_New`.`Season`
																  ORDER BY `Sales_Prices_New`.`StyleID`, `Sales_Prices_New`.`Color`,`Sales_Prices_New`.`Season`, 
																			`Sales_Prices_New`.`CostBlank` DESC) AS RowN
                                            FROM `wordpress`.`Sales_Prices_New`
											where styleoptionname1 like "%stand%" 
											and Season NOT IN ("BLANK","Blank RO","EXP BO","EMB","BLANK FG")
											') AS sp4
--on s3.StyleID =sp4.Styleid and TBM.Color=sp4.Color --and s3.Season=sp4.Season
on s3.StyleNumber =sp4.Style and TBM.Color=sp4.Color and s3.Season=sp4.Season and sp4.RowN = 1

ORDER BY 
TBM.[APS#],
TBM.[Style]

GO
