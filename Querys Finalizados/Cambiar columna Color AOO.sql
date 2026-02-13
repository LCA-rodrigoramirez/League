USE [AppsLCA]
GO

/****** Object:  View [legacycaps].[VW_view_qryLCA_Order_Export_Real]    Script Date: 26/03/2025 08:20:15 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--ALTER VIEW [legacycaps].[VW_view_qryLCA_Order_Export_Real]
--AS

SELECT 
	   TBM.[Cust #]
      ,TBM.[Short Name]
      ,TBM.[SOP Type]
      ,TBM.[ORD #]
      --,case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end as [Item #]
	  ,TBM.[Item #]
	  ,TBM.[Item # L2]
      ,TBM.[Item Desc]
	  ,TBM.Brand
	  ,TBM.[Relabel]
      ,TBM.[Qty]
      ,TBM.[Req Ship]
      ,TBM.[Status]
      ,TBM.[E or S]
      ,TBM.[Customer]
      ,TBM.[Outsource]
      ,TBM.[Return Date]
      ,TBM.[Sent Out]
      ,TBM.[Status/Date]
      ,TBM.[Doc Date]
      ,TBM.[Design]
      ,TBM.[Design Desc]
      ,TBM.[Cust PO #]
      ,TBM.[Cust Class]
      ,TBM.[Cancel]
      ,TBM.[Hold Status]
      ,TBM.[Pulled]
      ,TBM.[Cust Priority]
      ,TBM.[APS#]
      ,TBM.[R/S Priority]
      ,TBM.[Unit Price]
      ,TBM.[Document Amount]
      ,TBM.[Comment 3]
      ,TBM.[OriginalRequestDate]
      ,TBM.[Ship To]
      ,TBM.[SizingID]
      ,TBM.[ItemDetailID]
      ,TBM.[Shipto Name]
      ,TBM.[Address 1]
      ,TBM.[Address 2]
      ,TBM.[City]
      ,TBM.[State]
      ,TBM.[Zip]
      ,TBM.[Ship Via]
      ,TBM.[Ship Acct No]
      ,TBM.[SKUID Link]
      ,TBM.[OrderNo]
      ,TBM.[Application Type]
      ,TBM.[SKU Number]
      ,TBM.[DetailStatus]
      ,TBM.[CXR Name]
      ,TBM.[OrderItemID]
      ,TBM.[License Sticker]
      ,TBM.[Primary Design #]
      ,TBM.[OrderType]
      ,TBM.[OrderHOLD]
      ,TBM.[Email]
      ,TBM.[Phone]
	   ,CASE 
		 	WHEN trim(SUBSTRING(   case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,   LEN(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end) - Charindex('-', REVERSE(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end) ,1) +2,    LEN(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end))) = '' THEN
		 		    'AGREGAR'
		 	ELSE   
			         -- YA VIENE CORRECTO EN EL FORMATO
			         trim(SUBSTRING(   case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,   LEN(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end) - Charindex('-', REVERSE(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end) ,1) +2,    LEN(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)))
	   END	 AS Size	

  , substring( (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end),1, (case when  charindex( '-',(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)) = 0 then  100 else charindex( '-',(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)) end)-1 )   as Style
  
--  top 1000 [aps#], [item #] , [acctngID]

--select * FROM OPENQUERY([192.168.100.26],'SELECT  * FROM [Production].[dbo].[view_qryLCA_Order_Export]  where [APS#] in (4217609,4730971,4615695,4613673,4252794) ')   
----'4613673'
----[item #] like ''rempa-enaw%'' ')  
----[APS#] in (4217609,4730971,4615695) ')  
--select * from [AppsLCA].[legacycaps].[VW_Planning_importMOWithUniqSize] where item='REMPA-ENAW-F-ADJ'
--select * from [legacycaps].[VW_view_qryLCA_Order_Export_Real] where aps# =4252794

	  ,CASE
	      WHEN  Charindex('-', case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end) = 0 AND
			Charindex('-', REVERSE(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)) = 0 THEN
                     -- CASO 'L900'       
                     'AGREGAR'
		  WHEN  ( Charindex('-', case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end) 
			+ Charindex('-', REVERSE(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)) ) 
			> LEN(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end) THEN
                     -- CASO 'L900-CUS'   
		 	 		'AGREGAR'
		  WHEN 
				--isnumeric( substring(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
				--CHARINDEX('-', case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end) +1,3))=0 then
				ST.Comments10 = 1 AND isnumeric( substring(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
				CHARINDEX('-', case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end) +1,1))= 1 THEN
					CASE 
						WHEN CHARINDEX('A-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end))) > 0 
						THEN SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
							 CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
							 CHARINDEX('A-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)))-1)
						WHEN CHARINDEX('B-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end))) > 0 
						THEN SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
							 CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
							 CHARINDEX('B-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)))-1)
						WHEN CHARINDEX('C-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end))) > 0 
						THEN SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
							 CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
							 CHARINDEX('C-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)))-1)
						WHEN CHARINDEX('D-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end))) > 0 
						THEN SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
							 CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
							 CHARINDEX('D-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)))-1)
						WHEN CHARINDEX('E-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end))) > 0 
						THEN SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
							 CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
							 CHARINDEX('E-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)))-1)
						WHEN CHARINDEX('F-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end))) > 0 
						THEN SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
							 CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
							 CHARINDEX('F-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)))-1)
						WHEN CHARINDEX('G-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end))) > 0 
						THEN SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
							 CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
							 CHARINDEX('G-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)))-1)
						WHEN CHARINDEX('H-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end))) > 0 
						THEN SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
							 CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
							 CHARINDEX('H-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)))-1)
						WHEN CHARINDEX('I-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end))) > 0 
						THEN SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
							 CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
							 CHARINDEX('-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)))-1)
					END
		 WHEN 
				ST.Comments10 = 1 AND isnumeric( substring(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
				CHARINDEX('-', case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end) +1,1))= 0
				THEN SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
							 CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
							 CHARINDEX('-',
										SUBSTRING(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
										CHARINDEX('-',case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
										LEN (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)))-1)
				
						--substring(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
						--CHARINDEX('-', case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end) +1,
						--CHARINDEX('-',substring(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,
						--		CHARINDEX('-', case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,
						--		LEN(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)))-2)
          ELSE
		             -- CASO 'L900-809A-XS' YA VIENE CORRECTO EN EL FORMATO
	            SUBSTRING(  case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end,   
                            Charindex('-', case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)+1,    
                            LEN(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end) -
							Charindex('-', case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)-
							Charindex('-', REVERSE(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)) -1 
                )
		  END   AS Color


		,TBM.ContactName
		,TBM.[Sales Channel] AS [SalesChannel]
		,TBM.[CustDueDate]	AS [CustDueDate]
		,TBM.GroupID
	    ,TBM.EventDate
		,TBM.[Hot Order]
	    ,TBM.IsNovaStyle
		,TBM.ShipInstructions
		,TBM.OrderNote
		,TBM.CustProdNote
		,TBM.LogoStyleName
		,TBM.MachineGroup
		,TBM.ClassName as ProductDivision
		,TBM.StyleID as NewStyle

		,replace (replace([item # L2], concat(StyleID,'-'), ''),  concat('-',
				iif(ItemSize in ('2Tod','3Tod','4Tod','5Tod','6Tod','7Tod','8Tod'),substring(ItemSize,1,2),ItemSize)
				), '') 
		 as NewColor

		,case when ItemSize in ('2Tod','3Tod','4Tod','5Tod','6Tod','7Tod','8Tod')
				then substring(ItemSize,1,2)
			else itemSize
			end  as NewSize
			---- campos nuevos
			,TBM.AcctngID
			,TBM.UPC
			,TBM.CustomerRetail
	  FROM OPENQUERY([192.168.100.26],'SELECT  * FROM [Production].[dbo].[view_qryLCA_Order_Export] ') as TBM
       LEFT JOIN [AppsLCA].[legacycaps].[VW_Planning_importMOWithUniqSize] as IMOW
       on LTRIM(RTRIM(TBM.[Item #])) = LTRIM(RTRIM(IMOW.Item))
	   INNER JOIN (SELECT ST.StyleNumber, ST.Comments10, ROW_NUMBER() OVER(PARTITION BY ST.StyleNumber ORDER BY StyleNumber) as R FROM LCA.dbo.Styles AS ST WITH(NOLOCK)) AS ST
	   ON ST.R = 1 AND substring( (case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end),1, (case when  charindex( '-',(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)) = 0 then  100 else charindex( '-',(case when IMOW.ItemNewText is null then ltrim(rtrim(TBM.[Item #])) else ltrim(rtrim(IMOW.ItemNewText)) end)) end)-1 )  = ST.StyleNumber

	where ST.Comments10 = 1  
 -- SELECT [item # L2],
	--	replace (replace([item # L2], concat(StyleID,'-'), ''),  concat('-',ItemSize), '')     
	--	as NewColor
 --  FROM OPENQUERY([192.168.100.26],'SELECT  * FROM [Production].[dbo].[view_qryLCA_Order_Export] ')  as TBM
	--WHERE  styleID='pc400'

GO


