DROP TABLE IF EXISTS #TB_LOOKUP_LOGOSTYLEAPPLICATION
DROP TABLE IF EXISTS #TB_ActiveMO


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
--------------------------------------- PROCESO PARA OBTENER LAS MO ACTIVAS DESDE POLY PM Y ALL OPEN ORDERS -----------------------------------------------

    SELECT
         [MO]               = MO.[ManufactureNumber]
        ,[WorkOrder]        = OD.[PONumber]
        ,[ItemDetailID]     = CASE
                                WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
                                    NULL
                                WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
                                    cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT)
                                ELSE
                                    NULL
                              END
        ,[CustomerOrder]    = CASE
                                WHEN (OD.[PONumber] LIKE 'ORD%') AND CHARINDEX('-', OD.Comments6) > 0
                                    THEN SUBSTRING(OD.Comments6, 1, CHARINDEX('-', OD.Comments6) - 1)
                                ELSE OD.Comments6
                              END
        ,[PWModulo]         = MO.[Comments7]
        ,[OrderTypePPM]     = DDV2.[DropDownValue]
        ,[MOStatus]         = SN.[StatusName]
        ,[ApplicationType]  = CAST(NULL AS VARCHAR(200))
        ,[Type]             = CAST(NULL AS VARCHAR(200))
        
    FROM (SELECT [StatusID], [StatusName] FROM [LCA].[dbo].[StatusNames] WITH(NOLOCK) WHERE StatusID < 90 AND StatusID <> 67) AS SN
    INNER JOIN [LCA].[dbo].[ManufactureOrders]                      AS MO   WITH(NOLOCK) ON SN.[StatusID]                             = MO.[StatusID]
    INNER JOIN [LCA].[dbo].[Orders]                                 AS OD   WITH(NOLOCK) ON MO.[OrderID]                              = OD.[OrderID]
    LEFT  JOIN [LCA].[dbo].[DropDownValues2]                        AS DDV2 WITH(NOLOCK) ON OD.[OrderTypeID2]                         = DDV2.[DropDownValueID]

--------------------------------------- PROCESO PARA OBTENER LAS MO ACTIVAS DESDE POLY PM Y ALL OPEN ORDERS -----------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------
