USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_Transfer_TablaKelly]    Script Date: 23/01/2026 09:03:51 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--ALTER   PROCEDURE [dbo].[SP_Transfer_TablaKelly] 
       
--AS
BEGIN	
    
    DROP TABLE IF EXISTS #TB_KELLY
    DROP TABLE IF EXISTS #TB_Group_Invoice
    DROP TABLE IF EXISTS #TB_Group_Invoice
    DROP TABLE IF EXISTS #TB_Group_Invoice_Detaill
    
    SELECT 
         [ID]               = DAT.[ID]
        ,[Entry]            = DAT.[Entry #]
        ,[PortEntry]        = DAT.[PortEntry]
        ,[Invoice]          = DAT.[Invoice #]
        ,[EntryDate]        = CAST(DAT.[Entry Date] AS DATE)
        ,[SAC]              = DAT.[SACKellyGlobal]
        ,[Origin]           = DAT.[Origin]
        ,[Line]             = DAT.[Line #]
        ,[Qty]              = DAT.[Qty/Units]
        ,[QtyTotal]         = DAT.[QtyTotal]
        ,[VALOREM]          = DAT.[AdValoremRate]
        ,[Value]            = DAT.[Value]
        ,[Duty]             = DAT.[Duty]
    
        ,[Line_Left]        = CAST(NULL AS VARCHAR(10))
        ,[Line_Right]       = CAST(NULL AS VARCHAR(10))
        ,[ID_INVOICE]       = CAST(NULL AS INT)
        ,[ID_INVOICE_DET]   = CAST(NULL AS INT)
        ,[MaxLine_Invoice]  = CAST(NULL AS INT)
        ,[Value_Down]       = CAST(NULL AS DECIMAL(18,2))
        ,[F_Valorem]        = CAST(NULL AS INT)
        ,[F_Value]          = CAST(NULL AS INT)
        ,[DUTY_Down]        = CAST(NULL AS DECIMAL(18,2))
        ,[Valorem_Down]     = CAST(NULL AS DECIMAL(18,4))
        ,[New_Duty]         = CAST(NULL AS DECIMAL(18,2)) 
        ,[Dif]              = CAST(NULL AS DECIMAL(18,2)) 
    INTO #TB_KELLY 
    -- SELECT TOP 10*
    FROM [AppsLCA].[dbo].[ImportExport_DutyKellyGlobal_2025_2026_AfterPSC] AS DAT WITH(NOLOCK)
    
    
    
    SELECT *
    INTO #TB_Group_Invoice 
    FROM(
        SELECT 
            [RR]           = ROW_NUMBER()OVER(ORDER BY
                                                     TB.[Entry] 
                                                    ,TB.[PortEntry]
                                                    ,TB.[Invoice]
                                                )
            ,TB.*
        FROM(
            SELECT DISTINCT
                 
                 [Entry]        = DAT.[Entry] 
                ,[PortEntry]    = DAT.[PortEntry]
                ,[Invoice]      = DAT.[Invoice]
            FROM #TB_KELLY AS DAT
        ) AS TB
    ) AS TB2
    
    -- SELECT * FROM #TB_Group_Invoice
    -- WHERE [Entry] = 'BHE04308371'
    
    UPDATE S SET
         [ID_INVOICE]   = B.[RR]
        ,[Line_Left]        = LEFT(S.[Line], CHARINDEX('-', S.[Line]) - 1)
        ,[Line_Right]       = SUBSTRING(S.[Line], CHARINDEX('-', S.[Line]) + 1, LEN(S.[Line]))
    FROM #TB_KELLY  AS S
    INNER JOIN #TB_Group_Invoice AS B ON B.[Entry] = S.[Entry] AND B.[PortEntry] = S.[PortEntry] AND B.[Invoice] = S.[Invoice]
    
    SELECT *
    INTO #TB_Group_Invoice_Detaill 
    FROM(
        SELECT 
            [RR]           = ROW_NUMBER()OVER(ORDER BY
                                                     TB.[ID_INVOICE] 
                                                    ,TB.[Line_Left]
                                                )
            ,TB.*
        FROM(
            SELECT DISTINCT
                 [ID_INVOICE]
                ,[Line_Left]
                ,[MaxLine]      = MAX(ID)
            FROM #TB_KELLY AS DAT
            GROUP BY 
                [ID_INVOICE]
                ,[Line_Left]
       ) AS TB
    ) AS TB2
    
    
    UPDATE S SET
         [ID_INVOICE_DET]       = B.[RR]
         ,[MaxLine_Invoice]     = B.[MaxLine]
    FROM #TB_KELLY  AS S
    INNER JOIN #TB_Group_Invoice_Detaill AS B ON B.[ID_INVOICE] = S.[ID_INVOICE] AND B.[Line_Left] = S.[Line_Left]
    
    
    
    UPDATE S SET
         [Value_Down]       = B.[Value]
        ,[F_Valorem]        = CASE 
                                    WHEN S.[MaxLine_Invoice] = S.[ID]       THEN 0
                                    WHEN S.[MaxLine_Invoice] IS NOT NULL    THEN 1
                                    ELSE  0
                                END
                                
        ,[F_Value]          = IIF(B.[Value] <> S.[Value] ,1,0)
        ,[DUTY_Down]        = B.[Duty]
        ,[Valorem_Down]     = B.[VALOREM]
    FROM #TB_KELLY AS S
    LEFT JOIN #TB_KELLY AS B                       ON S.[MaxLine_Invoice] = B.[ID]
    
    
    
    
    UPDATE C SET
         [New_Duty]     =   IIF(
                                    (       C.[F_Valorem] = 1
                                        AND C.[F_Value]   = 1
                                    )
                                    ,C.[Value_Down] *C.[VALOREM]
                                    ,C.[Duty]
                                )
        ,[Value_Down]   = IIF(C.[F_Valorem] = 0,NULL, C.[Value_Down])
        ,[DUTY_Down]    = IIF(C.[F_Valorem] = 0,NULL, c.[DUTY_Down])
        ,[Valorem_Down] = IIF(C.[F_Valorem] = 0,NULL, c.[Valorem_Down])
                            
    FROM #TB_KELLY AS C
    
    
    UPDATE S SET
        [Dif]              = S.[New_Duty] - S.[Duty]
    FROM #TB_KELLY AS S
    
    
    -- SELECT * FROM #TB_KELLY
    -- WHERE [Entry] = 'BHE04308371' AND Invoice = 4
    -- -- WHERE [Entry] = 'BHE04308371' AND Invoice = 4
    -- ORDER BY ID
    
    
    
    
    
    
    -- ;WITH CTE AS
    -- (
    --     SELECT 
    --          [ID]               = S.[ID]
    --         -- ,[Line_Left]        = LEFT(S.[Line], CHARINDEX('-', S.[Line]) - 1)
    --         -- ,[Line_Right]       = SUBSTRING(S.[Line], CHARINDEX('-', S.[Line]) + 1, LEN(S.[Line]))
    --         ,[Value_Down]       = LEAD(S.[Value]) OVER (PARTITION BY S.[Entry]
    --                                                                 -- ,LEFT(S.[Line], CHARINDEX('-', S.[Line]) - 1)
    --                                                     ORDER BY S.[ID])
    --         ,[F_Valorem]        = IIF(S.[VALOREM] = 0.1, 1, 0)
    --         ,[DUTY_Down]        = LEAD(S.[Duty]) OVER ( PARTITION BY S.[Entry]
    --                                                                 -- ,LEFT(S.[Line], CHARINDEX('-', S.[Line]) - 1)
    --                                                     ORDER BY S.[ID])
    --         ,[Valorem_Down]      = LEAD(S.[VALOREM]) OVER (PARTITION BY S.[Entry]
    --                                                                 -- ,LEFT(S.[Line], CHARINDEX('-', S.[Line]) - 1)
    --                                                         ORDER BY S.[ID])
    --     FROM #TB_KELLY AS S
    -- )
    
    -- UPDATE S SET 
    --     --  [Line_Left]    = C.[Line_Left]
    --     -- ,[Line_Right]   = C.[Line_Right]
    --      [Value_Down]   = IIF(C.[F_Valorem] = 0,NULL, C.[Value_Down])
    --     ,[F_Valorem]    = C.[F_Valorem]
    --     ,[F_Value]      = IIF(C.[Value_Down] <> S.[Value] ,1,0)
    --     ,[DUTY_Down]    = IIF(C.[F_Valorem] = 0,NULL, c.[DUTY_Down])
    --     ,[Valorem_Down] = IIF(C.[F_Valorem] = 0,NULL, c.[Valorem_Down])
        
    -- FROM #TB_KELLY AS S
    -- INNER JOIN CTE AS C ON S.ID = C.ID
    
    
    
    
    -- ;WITH CTE2 AS(
    -- SELECT 
    --      [ID]           = C.ID 
    --     ,[New_Duty]     =   IIF(
    --                                 (       C.[F_Valorem] = 1
    --                                     AND C.[F_Value]   = 1
    --                                 )
    --                                 ,C.[Value_Down] *C.[VALOREM]
    --                                 ,C.[Duty]
    --                             )
                            
    -- FROM #TB_KELLY AS C
    -- )
    
    
    -- UPDATE S SET 
    --      [New_Duty]    = C.[New_Duty]
    -- FROM #TB_KELLY AS S
    -- INNER JOIN CTE2 AS C ON S.ID = C.ID
    
    DROP TABLE IF EXISTS AppsLCA.dbo.TB_Transfer_TablaKelly_AfterPSC
    SELECT 
        dat.*
         ,[Line_Left]       = S.[Line_Left]      
         ,[Line_Right]      = S.[Line_Right]     
         ,[ID_INVOICE]      = S.[ID_INVOICE]     
         ,[ID_INVOICE_DET]  = S.[ID_INVOICE_DET] 
         ,[MaxLine_Invoice] = S.[MaxLine_Invoice]
         ,[Value_Down]      = S.[Value_Down]     
         ,[F_Valorem]       = S.[F_Valorem]      
         ,[F_Value]         = S.[F_Value]        
         ,[DUTY_Down]       = S.[DUTY_Down]      
         ,[Valorem_Down]    = S.[Valorem_Down]   
         ,[New_Duty]        = S.[New_Duty]       
         ,[Dif]             = S.[Dif]  
         ,[Flag]            = IIF(S.[MaxLine_Invoice] = S.ID,1,0)
	INTO AppsLCA.dbo.TB_Transfer_TablaKelly_AfterPSC
    FROM [AppsLCA].[dbo].[ImportExport_DutyKellyGlobal_2025_2026_AfterPSC] AS DAT WITH(NOLOCK)
    INNER JOIN  #TB_KELLY AS S ON S.ID = DAT.ID

	--WHERE DAT.[Entry #] not in ('BHE04299810','BHE04304941','BHE04283368','BHE04258691','BHE04269979','BHE04278798','BHE04302473','BHE04299521')
    -- where S.[MaxLine_Invoice] = S.ID
    -- where s.dif > 0
    -- WHERE DAT.[Entry #] = 'BHE04293318'
    -- and [Invoice #] = 3
    -- and [Line_Left] = '006'
    -- and [MaxLine_Invoice] = 8686
    -- -- WHERE 
    -- --    DAT.[Entry #] = 'BHE04282865'
    --    OR
    --    DAT.[Entry #] = 'BHE04308868'
    --     OR DAT.[Entry #] = 'BHE04308371'
    -- -- WHERE DAT.[Entry #] = 'BHE04308371'
    ORDER BY ID




-- select distinct 
--     [ShipDate]
--     ,[Entry Date] = CAST([Entry Date] as date)
    
-- FROM [AppsLCA].[dbo].[ImportExport_DutyKellyGlobal_All2024_202511] AS DAT WITH(NOLOCK)

-- select * from(
--     select [ShipDate],sum(dat) as dat from(
--     select distinct [ShipDate],[Entry Date],1 as dat
--     FROM [AppsLCA].[dbo].[ImportExport_DutyKellyGlobal_All2024_202511] AS DAT WITH(NOLOCK)
--     -- WHERE [ShipDate] = '20240422'
--     ) as tb
--     group by [ShipDate]
-- ) as tb2
-- where tb2.dat > 2


-- where [Origin] = 'cn'
-- order by [Entry Date]


END

