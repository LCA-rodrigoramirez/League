DROP TABLE IF EXISTS #TB_LOOKUP_LOGOSTYLEAPPLICATION
DROP TABLE IF EXISTS #TB_L2BRAND_ACTIVE
DROP TABLE IF EXISTS #TB_ActiveMO
DROP TABLE IF EXISTS #TB_ProcessDetail

-----------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------- PROCESO PARA SABER OBTENER ÓREDENES ACTIVAS SEGÚN ALL OPEN ORDERS ------------------------------------------------

    SELECT  
        [ItemDetailID]
       ,[OrderNo]
       ,[Application Type]
    INTO #TB_L2BRAND_ACTIVE
    FROM [AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export] AS OE WITH(NOLOCK)
    GROUP BY
        [ItemDetailID]
       ,[OrderNo]
       ,[Application Type]

-----------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------- PROCESO PARA SABER OBTENER ÓREDENES ACTIVAS SEGÚN ALL OPEN ORDERS ------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------- PROCESO PARA SABER A QUÉ PROCESO SE DIRIGE CADA TÉCNICA (LOGOSTYLE) -----------------------------------------------

    SELECT  
        [LogoStyle]              = CAST([LogoStyle]             AS VARCHAR(20) )

        ,[ScreenPrintAfter]		 = CASE WHEN
                                        ( [OrderTypeDescription] like '%To Print%' 
                                        and ([ApplicationOrder] is null or  [ApplicationOrder] = 'AFTER')
                                        )
                                        OR 
                                        ([LogoStyle] = 'DTG')
                                    THEN 1
                                    ELSE 0 END
        ,[ScreenPrintBefore]	 = CASE WHEN [OrderTypeDescription] like '%To Print%' 
                                        and ([ApplicationOrder] = 'BEFORE')
                                    THEN 1
                                    ELSE 0 END
        ,[Embroidery]			= CASE WHEN [OrderTypeDescription] like '%To Embroidery%' 
                                    THEN 1
                                    ELSE 0 END
        ,[SublimationBefore]	= CASE WHEN [OrderTypeDescription] like '%To Sublimation%' 
                                        AND ([ApplicationOrder] = '' OR [ApplicationOrder] = 'BEFORE' )
                                    THEN 1
                                    ELSE 0 END
        ,[SublimationAfter]		= CASE WHEN [OrderTypeDescription] like '%To Sublimation%' 
                                        AND ([ApplicationOrder] = 'AFTER' )
                                    THEN 1
                                    ELSE 0 END
        ,[HDP]				= CASE WHEN [OrderTypeDescription] like '%Only DHT%' AND [LogoStyle] <> 'DTG'
                                    THEN 1
                                    ELSE 0 END
        ,[Blanks]				= CASE WHEN [OrderTypeDescription] like '%Blanks%' 
                                    THEN 1
                                    ELSE 0 END
        --,*
    INTO #TB_LOOKUP_LOGOSTYLEAPPLICATION
    FROM OPENQUERY([MARIADB],'SELECT * FROM wordpress.L2Brands_LogoStyle')  AS TBM

--------------------------------------- PROCESO PARA SABER A QUÉ PROCESO SE DIRIGE CADA TÉCNICA (LOGOSTYLE) -----------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------ PROCESO PARA OBTENER LAS MO ACTIVAS DESDE POLY PM --------------------------------------------------------

    SELECT
         [MO]                   = MO.[ManufactureNumber]
        ,[WorkOrder]            = OD.[PONumber]
        ,[ItemDetailID]         = CASE
                                    WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
                                        NULL
                                    WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
                                        cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT)
                                    ELSE
                                        NULL
                                  END
        ,[CustomerOrder]        = CASE
                                    WHEN (OD.[PONumber] LIKE 'ORD%') AND CHARINDEX('-', OD.Comments6) > 0
                                        THEN SUBSTRING(OD.Comments6, 1, CHARINDEX('-', OD.Comments6) - 1)
                                    ELSE OD.Comments6
                                  END
        ,[PWModulo]             = MO.[Comments7]
        ,[OrderTypePPM]         = DDV2.[DropDownValue]
        ,[MOStatus]             = SN.[StatusName]
    INTO #TB_ActiveMO        
    FROM (SELECT [StatusID], [StatusName] FROM [LCA].[dbo].[StatusNames] WITH(NOLOCK) WHERE StatusID < 90 AND StatusID <> 67) AS SN
    INNER JOIN [LCA].[dbo].[ManufactureOrders]                      AS MO   WITH(NOLOCK) ON SN.[StatusID]                             = MO.[StatusID]
    INNER JOIN [LCA].[dbo].[Orders]                                 AS OD   WITH(NOLOCK) ON MO.[OrderID]                              = OD.[OrderID]
    LEFT  JOIN [LCA].[dbo].[DropDownValues2]                        AS DDV2 WITH(NOLOCK) ON OD.[OrderTypeID2]                         = DDV2.[DropDownValueID]

-----------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------- PROCESO PARA ACTUALIZAR APLICATION TYPE DESDE ALL OPEN ORDERS -------------------------------------------------

    SELECT
         [MO]                   = AM.[MO]          
        ,[WorkOrder]            = AM.[WorkOrder]   
        ,[ItemDetailID]         = AM.[ItemDetailID]
        ,[CustomerOrder]        = AM.[CustomerOrder]
        ,[PWModulo]             = AM.[PWModulo]       
        ,[OrderTypePPM]         = AM.[OrderTypePPM]   
        ,[MOStatus]             = AM.[MOStatus]       
        ,[ApplicationType]      = CAST(NULL AS VARCHAR(200))
        ,[LogoStyle]            = split_values.[value]
        ,[Type]                 = CAST(NULL AS VARCHAR(200)) 
        ,[ScreenPrintAfter]		= tb_Emb.[ScreenPrintAfter]
        ,[ScreenPrintBefore]	= tb_Emb.[ScreenPrintBefore]
        ,[Embroidery]			= tb_Emb.[Embroidery]
        ,[SublimationBefore]	= tb_Emb.[SublimationBefore]
        ,[SublimationAfter]		= tb_Emb.[SublimationAfter]
        ,[HDP]					= tb_Emb.[HDP]
        ,[Blanks]				= tb_Emb.[Blanks]
        ,[KeyOrder]             = split_values.[key]
    INTO #TB_ProcessDetail
    FROM #TB_ActiveMO AS AM
    LEFT JOIN #TB_L2BRAND_ACTIVE AS OE WITH(NOLOCK) ON 'ORD-' + CAST(OE.[ItemDetailID] AS varchar) = AM.[WorkOrder]
    CROSS APPLY OPENJSON(
        '["' + REPLACE(STRING_ESCAPE(ISNULL(OE.[Application Type],''),  'json'), ',', '","') + '"]'
    ) AS split_values
    LEFT JOIN  #TB_LOOKUP_LOGOSTYLEAPPLICATION AS tb_Emb on tb_Emb.[LogoStyle] = split_values.[value]
    WHERE AM.ItemDetailID IS NOT NULL

    SELECT
         [MO]
        ,[WorkOrder]
        ,[ItemDetailID]
        ,[CustomerOrder]
        ,[PWModulo]
        ,[OrderTypePPM]
        ,[MOStatus]
        ,[ApplicationType]      = STRING_AGG([LogoStyle], ',') WITHIN GROUP (ORDER BY [KeyOrder])
        ,[Type]                 = STRING_AGG(
                                             CASE   
                                                    WHEN [ScreenPrintAfter]  > 0 THEN 'Screen Print After'
                                                    WHEN [ScreenPrintBefore] > 0 THEN 'Screen Print Before' 
                                                    WHEN [Embroidery]        > 0 THEN 'Embroidery'
                                                    WHEN [SublimationBefore] > 0 THEN 'Sublimation Before'
                                                    WHEN [SublimationAfter]  > 0 THEN 'Sublimation After'
                                                    WHEN [HDP]               > 0 THEN 'High Definition Print'
                                                    WHEN [Blanks]            > 0 THEN 'Blanks'
                                                    ELSE '' 
                                             END,',') WITHIN GROUP (ORDER BY [KeyOrder])
        ,[ScreenPrintAfter]	    = SUM([ScreenPrintAfter])
        ,[ScreenPrintBefore]    = SUM([ScreenPrintBefore])
        ,[Embroidery]		    = SUM([Embroidery])
        ,[SublimationBefore]    = SUM([SublimationBefore])
        ,[SublimationAfter]	    = SUM([SublimationAfter])
        ,[HDP]				    = SUM([HDP])
        ,[Blanks]			    = SUM([Blanks])
    FROM #TB_ProcessDetail
    GROUP BY
         [MO]
        ,[WorkOrder]
        ,[ItemDetailID]
        ,[CustomerOrder]
        ,[PWModulo]
        ,[OrderTypePPM]
        ,[MOStatus]

-----------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------- PROCESO PARA ACTUALIZAR APLICATION TYPE DESDE ALL OPEN ORDERS -------------------------------------------------