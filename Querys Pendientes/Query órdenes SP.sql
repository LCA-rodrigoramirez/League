DROP TABLE IF EXISTS #TB_MO_FILTER
            DROP TABLE IF EXISTS #TB_ORD_LIST

            SELECT
                 [ItemDetailID]	    = CASE
                                        WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
                                            NULL
                                        WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
                                            cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT)
                                        ELSE
                                            NULL
                                        END
                ,[WorkOrder]        = OD.[PONumber]
                ,[Req Ship]         = CAST(OD.[RequiredDate] AS DATE)
                ,[ManufactureID]    = MO.[ManufactureID]
                ,[MO]               = MO.[ManufactureNumber]
                ,[ProductionStatus] = DV.[DropDownValue]
                ,[Style]            = ST.[StyleNumber]
                ,[Color]            = SC.[StyleColorName]
                ,[Make]             = OD.[RequestCount]
                ,[PWModulo]         = MO.[Comments7]
                ,[WorkFlowID]       = WF.[WorkFlowID]
                ,[MinReqShip]       = CAST(NULL AS DATE)
                ,[Design]           = CAST(NULL AS VARCHAR(100))
                ,[OrderType]        = CAST(NULL AS VARCHAR(100))
                ,[ImageLink]        = CAST(NULL AS VARCHAR(MAX))
                ,[StatusPrePress]   = POS.[StatusPrePress]
                ,[ScreensWO]        = POS.[ScreensWO]
                ,[BinPrePress]      = POS.[BinPrePress]
                ,[ScreenPrint]      = CAST(NULL AS BIT)
            INTO #TB_MO_FILTER
            FROM (SELECT StatusID FROM [LCA].[dbo].[StatusNames] sn with (nolock) WHERE StatusID < 90 and StatusID not in (67,20)) AS SN
            INNER JOIN [LCA].[dbo].[ManufactureOrders]              AS MO WITH(NOLOCK) ON SN.[StatusID] = MO.[StatusID]
            INNER JOIN [LCA].[dbo].[Orders]                         AS OD WITH(NOLOCK) ON MO.[OrderID] = OD.[OrderID]
            INNER JOIN [LCA].[dbo].[OrderItems]                     AS OI WITH(NOLOCK) ON OI.[OrderItemID] = MO.[FirstOrderItemID]
            INNER JOIN [LCA].[dbo].[Styles]                         AS ST WITH(NOLOCK) ON OI.[StyleID] = ST.[StyleID]
            INNER JOIN [LCA].[dbo].[StyleColors]                    AS SC WITH(NOLOCK) ON OI.[StyleColorID] = SC.[StyleColorID]
            LEFT  JOIN [LCA].[dbo].[DropDownValues3]                AS DV WITH(NOLOCK) ON MO.[ProductionStatusID] = DV.[DropDownValueID]
            LEFT  JOIN [LCA].[dbo].[WorkFlows]                      AS WF WITH(NOLOCK) ON MO.[ManufactureID] = WF.[ManufactureID]
            LEFT  JOIN 
            (
                SELECT
                     [ManufactureID]    = OS.[ManufactureID]
                    ,[ScreensWO]        = OS.[ScreensByLocations]
                    ,[StatusPrePress]   = ST.[Task]
                    ,[BinPrePress]      = IIF(ST.[Sequence] = 4, PB.[Bin], NULL)
                FROM
                (
                    SELECT 
                         [ManufactureID]         = [ManufactureID]
                        ,[ScreensByLocations]   = [ScreensByLocations]
                        ,[MaxSequence]          = MAX([Prepress_SequenceTasks_ID])
                        ,[MaxBin]               = MAX([Prepress_Bins_ID])
                    FROM [AppsLCA].[dbo].[TB_Prepress_OrdersScanned] WITH(NOLOCK) 
                    -- WHERE WorkOrder = 'ORD-5331406'
                    GROUP BY
                         [ManufactureID]
                        ,[ScreensByLocations]
                ) AS OS
                INNER JOIN [AppsLCA].[dbo].[TB_Prepress_SequenceTasks]  AS ST WITH(NOLOCK) ON OS.[MaxSequence] = ST.[ID]
                LEFT  JOIN [AppsLCA].[dbo].[TB_Prepress_Bins]           AS PB WITH(NOLOCK) ON OS.[MaxBin] = PB.[Bin]
                    
            ) AS POS ON MO.[ManufactureID] = POS.[ManufactureID]
            
            WHERE CASE
                                    WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
                                        NULL
                                    WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
                                        cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT)
                                    ELSE
                                        NULL
                                    END IS NOT NULL AND MO.[Comments7] IS NOT NULL
            
            UPDATE MF SET
                 [Design]       = DC.[DesignNo]
                ,[OrderType]    = LG.[OrderTypeDescription]
            FROM #TB_MO_FILTER                                                            AS MF
            INNER JOIN [192.168.1.93].[AppsLCA].[legacycaps].[VW_view_LCA_DesignColors]   AS DC ON DC.[ItemDetailID] = MF.[ItemDetailID] AND DC.[LogoStyleName] LIKE '%Screen Print%'
            LEFT JOIN OPENQUERY([MARIADB],'SELECT * FROM wordpress.L2Brands_LogoStyle') AS LG ON DC.[LogoStyle] = LG.[LogoStyle]

            DELETE FROM #TB_MO_FILTER WHERE [OrderType] NOT LIKE '%Print%' OR [OrderType] IS NULL

            UPDATE MO SET
                [ScreenPrint]      =   IIF(WT_01.[TaskName]  IS NOT NULL, 1, 0) +
                                        IIF(WT_02.[TaskName]  IS NOT NULL, 1, 0) +
                                        IIF(WT_03.[TaskName]  IS NOT NULL, 1, 0) +
                                        IIF(WT_04.[TaskName]  IS NOT NULL, 1, 0) +
                                        IIF(WT_05.[TaskName]  IS NOT NULL, 1, 0) +
                                        IIF(WT_06.[TaskName]  IS NOT NULL, 1, 0) +
                                        IIF(WT_07.[TaskName]  IS NOT NULL, 1, 0) +
                                        IIF(WT_08.[TaskName]  IS NOT NULL, 1, 0) +
                                        IIF(WT_09.[TaskName]  IS NOT NULL, 1, 0) +
                                        IIF(WT_10.[TaskName]  IS NOT NULL, 1, 0)

            FROM #TB_MO_FILTER                    AS MO
            LEFT JOIN [LCA].[dbo].[WorkTasks]     AS WT_01     WITH(NOLOCK) ON MO.[WorkFlowID] = WT_01.[WorkFlowID]    AND WT_01.[TaskName]  = 'Start Print 1'     AND WT_01.[FinishDate] IS NOT NULL
            LEFT JOIN [LCA].[dbo].[WorkTasks]     AS WT_02     WITH(NOLOCK) ON MO.[WorkFlowID] = WT_02.[WorkFlowID]    AND WT_02.[TaskName]  = 'Start Print 2'     AND WT_02.[FinishDate] IS NOT NULL
            LEFT JOIN [LCA].[dbo].[WorkTasks]     AS WT_03     WITH(NOLOCK) ON MO.[WorkFlowID] = WT_03.[WorkFlowID]    AND WT_03.[TaskName]  = 'Start Print 3'     AND WT_03.[FinishDate] IS NOT NULL
            LEFT JOIN [LCA].[dbo].[WorkTasks]     AS WT_04     WITH(NOLOCK) ON MO.[WorkFlowID] = WT_04.[WorkFlowID]    AND WT_04.[TaskName]  = 'Start Print 4'     AND WT_04.[FinishDate] IS NOT NULL
            LEFT JOIN [LCA].[dbo].[WorkTasks]     AS WT_05     WITH(NOLOCK) ON MO.[WorkFlowID] = WT_05.[WorkFlowID]    AND WT_05.[TaskName]  = 'Start Print 5'     AND WT_05.[FinishDate] IS NOT NULL
            LEFT JOIN [LCA].[dbo].[WorkTasks]     AS WT_06     WITH(NOLOCK) ON MO.[WorkFlowID] = WT_06.[WorkFlowID]    AND WT_06.[TaskName]  = 'Start Print 6'     AND WT_06.[FinishDate] IS NOT NULL
            LEFT JOIN [LCA].[dbo].[WorkTasks]     AS WT_07     WITH(NOLOCK) ON MO.[WorkFlowID] = WT_07.[WorkFlowID]    AND WT_07.[TaskName]  = 'Start Print 7'     AND WT_07.[FinishDate] IS NOT NULL
            LEFT JOIN [LCA].[dbo].[WorkTasks]     AS WT_08     WITH(NOLOCK) ON MO.[WorkFlowID] = WT_08.[WorkFlowID]    AND WT_08.[TaskName]  = 'Start Print 8'     AND WT_08.[FinishDate] IS NOT NULL
            LEFT JOIN [LCA].[dbo].[WorkTasks]     AS WT_09     WITH(NOLOCK) ON MO.[WorkFlowID] = WT_09.[WorkFlowID]    AND WT_09.[TaskName]  = 'Start Print 9'     AND WT_09.[FinishDate] IS NOT NULL
            LEFT JOIN [LCA].[dbo].[WorkTasks]     AS WT_10     WITH(NOLOCK) ON MO.[WorkFlowID] = WT_10.[WorkFlowID]    AND WT_10.[TaskName]  = 'Start Print 10'    AND WT_10.[FinishDate] IS NOT NULL

            DELETE FROM #TB_MO_FILTER WHERE [ScreenPrint] = 1

            UPDATE MF SET
                [ImageLink]    = CONCAT(
                                                'l2lookup.l2brands.org/p_drive/Production%20Data/Photos/SKU/',
                                                RIGHT(OE.[SKUID Link], CHARINDEX('=', REVERSE(OE.[SKUID Link])) - 1),
                                                '.jpg'
                                            )
            FROM #TB_MO_FILTER                                              AS MF
            INNER JOIN [AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export] AS OE ON MF.[ItemDetailID] = OE.[ItemDetailID]

            UPDATE MF SET
                [MinReqShip] = A.[Min_ReqShip]
            FROM #TB_MO_FILTER AS MF
            INNER JOIN
            (
                SELECT
                     Design
                    ,MIN([Req Ship]) AS Min_ReqShip 
                FROM #TB_MO_FILTER
                GROUP BY
                     Design
            ) AS A ON MF.[Design] = A.[Design]

            SELECT * FROM #TB_MO_FILTER
