CREATE VIEW dboReaders.VW_L2Brands_AssigmentsOrdersStatusLCA
AS

SELECT
     [R]                    =  TB.R
    ,[Assigment]            =  TB.PWModulo
    ,[AssigmentDate]        =  SUBSTRING(RTRIM(TB.PWModulo),LEN(TB.PWModulo) - 9, LEN(TB.PWModulo))
    ,[MO]                   =  TB.ManufactureNumber
    ,[PONumber]             =  TB.PONumber
    ,[Style]                =  TB.Style
    ,[Color]                =  TB.Color
    ,[Size]                 =  TB.[Size]
    ,[Qty_Required]         =  TB.Qty_Required
    ,[Qty_Withdrawn]        =  TB.Qty_Withdrawn
    ,[Qty_Needed]           =  TB.Qty_Needed
    ,[StatusWithdraw]       =  CASE
                                 WHEN TB.Qty_Needed = 0 THEN 'WITHDRAW COMPLETE'
                                 WHEN TB.Assig_QtyNeeded > 0 THEN 'WITHDRAW PENDING'
                                 ELSE ''
                               END
    ,[Assigment_Required]   =  TB.Assig_QtyRequired
    ,[Assigment_Withdrawn]  =  TB.Assig_QtyWithdrawn
    ,[Assigment_Needed]     =  TB.Assig_QtyNeeded
    ,[StatusAssigment]      =  CASE
                                 WHEN TB.Assig_QtyNeeded = 0 AND Assig_Count = 1 THEN 'ASSIGMENT COMPLETE'
                                 WHEN TB.Assig_QtyNeeded > 0 AND Assig_Count = 1 THEN 'ASSIGMENT PENDING'
                                 ELSE ''
                               END
FROM
(
    SELECT
        R                  = ROW_NUMBER() OVER(ORDER BY TB_Det.PWModulo)
        ,TB_Det.*
        ,Assig_QtyRequired  = CASE WHEN TB_Det.Assig_Count = 1 THEN SUM(TB_Det.Qty_Required) OVER (PARTITION BY TB_Det.PWModulo) ELSE '' END
        ,Assig_QtyWithdrawn = CASE WHEN TB_Det.Assig_Count = 1 THEN SUM(TB_Det.Qty_Withdrawn) OVER (PARTITION BY TB_Det.PWModulo) ELSE '' END
        ,Assig_QtyNeeded    = CASE WHEN TB_Det.Assig_Count = 1 THEN SUM(TB_Det.Qty_Required-TB_Det.Qty_Withdrawn) OVER (PARTITION BY TB_Det.PWModulo) ELSE '' END
        
    FROM
    (
        SELECT  
            MO2.Comments7 AS PWModulo
            ,MO2.ManufactureNumber
            ,OD.PONumber
            ,ST.StyleNumber AS Style
            ,SC.StyleColorName AS Color
            ,FG.GarmentSize AS Size
            ,SUM(MB.QuantityRequired) AS Qty_Required
            ,SUM(MB.QuantityWithdrawn) AS Qty_Withdrawn
            ,SUM(MB.QuantityRequired - MB.QuantityWithdrawn) AS Qty_Needed
            ,ROW_NUMBER() OVER(PARTITION BY MO2.Comments7 ORDER BY MO2.Comments7) AS Assig_Count
        FROM dbo.ManufactureOrders AS MO2 
        INNER JOIN dbo.ManufactureBlanks MB 
            ON MO2.ManufactureID = MB.ManufactureID 
            AND MO2.StatusID <= 90 
            AND MO2.StatusID >= 40 
            --AND (MO2.Comments7 LIKE 'DLI%' OR MO2.Comments7 LIKE 'NG%' OR MO2.Comments7 LIKE 'ASSIGMENT%') 
            AND (MO2.Comments7 LIKE 'ASSIGMENT%') 
            --  AND MO2.Comments7 = 'ASSIGMENT DLI #177 2025-02-26'
        INNER JOIN dbo.FinishedGoods FG ON MB.FinishedGoodsID = FG.FinishedGoodsID
        INNER JOIN dbo.StyleColors SC ON FG.StyleColorID = SC.StyleColorID
        INNER JOIN dbo.Styles St ON FG.StyleID = St.StyleID
        INNER JOIN dbo.Orders OD ON MO2.OrderID = OD.OrderID AND OD.StatusID <> 95
        GROUP BY 
                MO2.Comments7,
                MO2.ManufactureNumber,
                OD.PONumber,
                ST.StyleNumber,
                SC.StyleColorName,
                FG.GarmentSize

    ) AS TB_Det    
) AS TB