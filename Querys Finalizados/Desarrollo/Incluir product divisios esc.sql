USE [LCA]
GO

/****** Object:  View [dboReaders].[VW_ESC_Pricing_VS_Costing_BlankEMBCost]    Script Date: 19/03/2025 04:08:55 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- ALTER VIEW [dboReaders].[VW_ESC_Pricing_VS_Costing_BlankEMBCost]
--AS 

SELECT TOP 100 PERCENT
     PvC.[Style]   
    ,PvC.[StyleName]
	,PvC.[EngineSeason]
	,PvC.[StyleOptionName1]
    ,PvC.[Color]
    ,PvC.[ColorDescription]       
    ,PvC.[ColorCategory]		AS [Category]      
    ,PvC.[PricingSeason]     
    ,PvC.[BlankPricing]   
    ,PvC.[EmbellismentPricing]   
    ,PvC.[EMBPricing]
    ,PvC.[TotalPricing]    
    ,PvC.[BlankCosting]
    ,PvC.[EmbellismentCosting] 
    ,PvC.[EMBCosting]
    ,PvC.[TotalCosting]
	,PvC.[DIF_Pricing_Costing]
	--,ST.[ProductDivision]
FROM [dboReaders].[VW_ESC_Pricing_VS_Costing] AS PvC
--LEFT OUTER JOIN (SELECT StyleNumber, Comments9 AS ProductDivision FROM [dbo].[Styles] GROUP BY StyleNumber,Comments9) as ST ON pvc.Style = ST.StyleNumber
GO


