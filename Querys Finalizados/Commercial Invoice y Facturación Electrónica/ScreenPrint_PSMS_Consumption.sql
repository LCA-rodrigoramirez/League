USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_InfoOrdersToPolyPM_SP_Apparel]    Script Date: 26/08/2026 11:38:23 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER   PROCEDURE [dbo].[SP_ScreenPrint_PMS_Consumption]
(
     @process NVARCHAR(MAX)
    ,@data    NVARCHAR(MAX)
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Component AS NVARCHAR(200)
	DECLARE @Error     AS BIT
	DECLARE @message   AS NVARCHAR(200)
	DECLARE @result    AS NVARCHAR(MAX)

	BEGIN TRY

        DROP TABLE IF EXISTS #ORDERS;
        DROP TABLE IF EXISTS #COLORS;
        DROP TABLE IF EXISTS #TB_Final;

        IF @process = 'report-pms'
        BEGIN

            SELECT DISTINCT
                ItemDetailID	= CASE
                                    WHEN OE.ItemDetailID IS NOT NULL THEN OE.ItemDetailID
                                    WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
                                        NULL
                                    WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
                                        cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT)
                                    ELSE
                                        NULL
                                    END
                ,OE.Brand
                ,mo.ManufactureID
                ,od.OrderID
                ,od.PONumber
                ,SN.StatusName
                ,DDV.DropDownValue
                ,MO.QuantityOrdered
                ,ST.StyleNumber
                ,STC.StyleColorName
                ,OD.RequiredDate
                ,MO.Comments7
                ,[ScreenPrint]      = CAST(NULL AS BIT)
                ,[WorkFlowID]       = CAST(NULL AS INT)
            INTO #ORDERS
            FROM (SELECT StatusID,StatusName FROM LCA.dbo.StatusNames sn with (nolock) WHERE StatusID in (40,51,53,55,78)) AS SN
            INNER JOIN
            LCA.dbo.ManufactureOrders mo WITH (NOLOCK)
            ON SN.StatusID = MO.StatusID
            INNER JOIN
            LCA.dbo.Orders od with (nolock)
            ON OD.OrderID = mo.OrderID
            LEFT JOIN
            LCA.dbo.OrderItems oi with (nolock)
            ON od.OrderID = oi.OrderID AND mo.FirstOrderItemID = oi.OrderItemID
            INNER JOIN
            LCA.dbo.Styles st with (nolock)
            ON oi.StyleID = st.StyleID and st.Comments9 LIKE '%Apparel%'
            INNER JOIN
            LCA.dbo.StyleColors stc with (nolock)
            ON oi.StyleColorID = stc.StyleColorID
            LEFT JOIN 
            [AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export] AS OE WITH(NOLOCK)
            ON 'ORD-' + CAST(OE.ItemDetailID AS varchar) = od.PONumber
            LEFT JOIN LCA.dbo.DropDownValues3 AS DDV WITH(NOLOCK) 
            ON MO.ProductionStatusID = DDV.DropDownValueID

            UPDATE O SET
                WorkFlowID = WF.WorkFlowID
            FROM #ORDERS AS O
            INNER JOIN LCA.dbo.WorkFlows AS WF WITH(NOLOCK) ON O.ManufactureID = WF.ManufactureID

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

            FROM #ORDERS                          AS MO
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

            DELETE FROM #ORDERS WHERE ScreenPrint > 0

            SELECT
                [ItemDetailID]       = DC.[ItemDetailID]
                ,[PONumber]           = CO.[PONumber]
                ,[Style]              = CO.[StyleNumber]
                ,[Color]              = CO.[StyleColorName]
                ,[StatusMO]           = CO.[StatusName]
                ,[ProductionStatus]   = CO.[DropDownValue]
                ,[Make]               = CO.[QuantityOrdered]
                ,[Assignment]         = CO.[Comments7]
                ,[Location]           = DC.[Location]
                ,[Tecnica]            = DC.[LogoStyle]
                --   ,[ColorSpoolID]       = DC.[ColorSpoolID]
                --   ,[ColorPMS]           = DC.[ColorPMS]
                ,[ColorName]          = DC.[ColorName]
                ,[CountColors]        = ROW_NUMBER() OVER (PARTITION BY DC.ItemDetailID ORDER BY DC.ItemDetailID)
                ,[ColorPiv]           = CAST(NULL AS VARCHAR(50))
            INTO #COLORS
            FROM #ORDERS AS CO WITH(NOLOCK)
            INNER JOIN [192.168.1.93].AppsLCA.legacycaps.VW_view_LCA_DesignColors DC WITH (NOLOCK)
            ON DC.ItemDetailID = CO.ItemDetailID
            where (LogoStyleName LIKE '%Screen Print%') AND (LogoStyleName <> 'Sublimation' AND LogoStyleName NOT LIKE '%High Definition Print%' AND LogoStyleName <> 'Direct White Label') 

            UPDATE C SET
                [ColorPiv] = CONCAT('Color ',CAST(CountColors AS VARCHAR(10)))
            FROM #COLORS AS C

            DECLARE @Cols NVARCHAR(MAX), @Query NVARCHAR(MAX);

            SELECT @Cols = STRING_AGG(QUOTENAME(ColorPiv),',') WITHIN GROUP (ORDER BY CountColors)
            FROM (SELECT DISTINCT ColorPiv, CountColors FROM #COLORS) AS X;

            SET @Query = N'
            SELECT @ResultOut = (
                SELECT
                    ItemDetailID
                    ,PONumber
                    ,Style
                    ,Color
                    ,StatusMO
                    ,ProductionStatus
                    ,Make
                    ,Assignment
                    ,Location
                    ,Tecnica
                    ,' + @Cols + N'
                FROM (
                    SELECT
                        ItemDetailID
                        ,PONumber
                        ,Style
                        ,Color
                        ,StatusMO
                        ,ProductionStatus
                        ,Make
                        ,Assignment
                        ,Location
                        ,Tecnica
                        ,ColorName
                        ,ColorPiv
                    FROM #COLORS
                ) AS SourceTable
                PIVOT (
                    MAX(ColorName)
                    FOR ColorPiv IN (' + @Cols + N')
                ) AS PivotTable
                FOR JSON PATH, INCLUDE_NULL_VALUES
            )
            '
            ;

            EXEC sp_executesql @Query, N'@ResultOut NVARCHAR(MAX) OUTPUT', @ResultOut = @result OUTPUT;

            SET @Error     = 0
            SET @Component = '[200]'
            SET @message   = 'Datos generados correctamente'
            
        END

    END TRY
    BEGIN CATCH

        SET @Error     = 1
        SET @result    = '[]'
        SET @Component = '[404]'
        SET @message   = ERROR_MESSAGE()

    END CATCH

    SELECT
        [Error]        = @Error
        ,[Component]    = @Component
        ,[Message]      = @message
        ,[result]       = JSON_QUERY(@result)
    FOR JSON PATH, INCLUDE_NULL_VALUES

END
