USE [LCA]
GO

/****** Object:  View [dboReaders].[VW_PACKED_PARTITION_PONUMBER_PACKED]    Script Date: 16/02/2026 08:02:23 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO













ALTER  VIEW [dboReaders].[VW_PACKED_PARTITION_PONUMBER_PACKED]
AS

 
    ---EMPAQUE
WITH CTE AS (SELECT
		--  ManufactureOrders.ManufactureID                AS [ManufactureID]
		-- ,ManufactureOrders.ManufactureNumber            AS [MO]
		 Orders2.OrderID                                AS [OrderID]
		,Orders2.PONumber                               AS [PONumber]
		,Styles.StyleNumber                             AS [StyleNumber]
        ,CASE
            WHEN SNS.SeasonName = 'EMB FG' THEN 'EMBFG'
            ELSE 'SEASON' END                           AS [SeasonF]
        ,PackedBoxes.BoxNumber                          AS [BoxNumber]
		,CASE
			WHEN PackedPallets.PalletTypeID = 4 
				AND DDV3.DropDownValue IS NOT NULL
				THEN CONCAT(PackedPallets.PalletNumber,'-',RIGHT(DDV3.DropDownValue,3))
			ELSE ''
		 END											AS [ConsolidatedBox]

		--- NUEVAS COLUMNAS PARA REPORTE				AGREGADO POR RODRIGO RAMIREZ 20250604
		,PackedBoxes.BoxComments6						AS [LCA_TrackingNumber]
		,GB.Bin											AS [Bin]
								--AS [LCA_TrackingNumber]

        ,isnull(ManufactureOrders.Comments16,TBMO.TariffCategory)   AS [TariffCategory]
        ,PackedPallets.PalletNumber                     AS [PalletNumber]
		,StyleColors.StyleColorName                     AS [StyleColor]
		,PackedItems.Quantity                           AS [Quantity]
        ,SNS.seasonName                                 AS [Season]
		,FinishedGoods.GarmentSize                      AS [GarmentSize]
        ,Dictionary5.OriginalText                       AS [STATUS]
		,OrderItems.PricingUnitCost2					AS [BasePrice]
        ,OrderItems.PricingUnitCost                     AS [TotalPrintValue]
		,TBMO.CountryOfOrigin							as [CountryOfOrigin]
		,ManufactureOrders.ManufactureID				as ManufactureID
		,ManufactureOrders.ManufactureNumber
		,Styles.Comments9								AS ProductDivision
		,CASE 
			WHEN ( Orders.[PONumber] LIKE 'ORD%') AND CHARINDEX('-',Orders.Comments6) > 0 
				THEN SUBSTRING(Orders.Comments6,1,CHARINDEX('-',Orders.Comments6) -1) 
			ELSE Orders.Comments6 END						AS CustomerOrder					


	FROM                PackedItems                         WITH (NOLOCK)
		LEFT OUTER JOIN FinishedGoods                       WITH (NOLOCK)
		LEFT OUTER JOIN Styles                              WITH (NOLOCK)   ON FinishedGoods.StyleID = Styles.StyleID
		LEFT OUTER JOIN StyleColors                         WITH (NOLOCK)   ON FinishedGoods.StyleColorID = StyleColors.StyleColorID 
                                                                            ON PackedItems.FinishedGoodsID = FinishedGoods.FinishedGoodsID
		LEFT OUTER JOIN OrderDetails                        WITH (NOLOCK)
		LEFT OUTER JOIN Orders                              WITH (NOLOCK)   ON OrderDetails.OrderID = Orders.OrderID
		LEFT OUTER JOIN OrderItems                          WITH (NOLOCK)   ON OrderDetails.OrderItemID = OrderItems.OrderItemID 
                                                                            ON PackedItems.OrderDetailsID = OrderDetails.OrderDetailsID
		LEFT OUTER JOIN PackedBoxes							WITH (NOLOCK)
		LEFT OUTER JOIN BoxTypes        AS BoxTypes2        WITH (NOLOCK)   ON PackedBoxes.BoxTypeID = BoxTypes2.BoxTypeID
		LEFT OUTER JOIN Shipments							WITH (NOLOCK)
		LEFT OUTER JOIN InvoiceBatches                      WITH (NOLOCK)   ON Shipments.InvoiceBatchID = InvoiceBatches.InvoiceBatchID 
                                                                            ON PackedBoxes.ShipmentID = Shipments.ShipmentID
		LEFT OUTER JOIN Orders          AS Orders2			WITH (NOLOCK)
		LEFT OUTER JOIN DropDownValues2 AS DropDownValues24 WITH (NOLOCK)   ON Orders2.OrderTypeID3 = DropDownValues24.DropDownValueID 
                                                                            ON PackedBoxes.OrderID = Orders2.OrderID
		LEFT OUTER JOIN StatusNames							WITH (NOLOCK)
		LEFT OUTER JOIN Dictionary      AS Dictionary5      WITH (NOLOCK)   ON StatusNames.StatusName = Dictionary5.OriginalText
			                                                                    AND Dictionary5.MessageSource = 'StatusNames'
			                                                                    AND Dictionary5.LanguageID  = 1 
                                                                            ON PackedBoxes.StatusID = StatusNames.StatusID
		LEFT OUTER JOIN Users                               WITH (NOLOCK)   ON PackedBoxes.PackerID = Users.UserID
		LEFT OUTER JOIN Warehouses                          WITH (NOLOCK)   ON PackedBoxes.WarehouseID = Warehouses.WarehouseID
		LEFT OUTER JOIN PackedPallets                       WITH (NOLOCK)   ON PackedBoxes.PackedPalletID = PackedPallets.PackedPalletID 
                                                                            ON PackedItems.PackedBoxID = PackedBoxes.PackedBoxID
		LEFT OUTER JOIN ManufactureOrders                   WITH (NOLOCK)   ON PackedItems.ManufactureID = ManufactureOrders.ManufactureID --left outer join WorkFlows wf on wf.ManufactureID = ManufactureOrders.ManufactureID
		-- left outer join StyleCategories stc on stc.StyleCategoryID = Styles.StyleCategoryID 
		LEFT OUTER JOIN Seasons         AS SNS              WITH (NOLOCK)   ON SNS.SeasonID = Styles.SeasonID
		LEFT OUTER JOIN StyleCategories AS stc              WITH (NOLOCK)   ON stc.StyleCategoryID = Styles.StyleCategoryID
		LEFT OUTER JOIN ( 
						select distinct Manufactureid, CountryOfOrigin,TariffCategory from 
						  [AppsLCA].[dbo].[TB_MO_PartNumber_IM] WITH (NOLOCK)
						  where Category in ('Fabric','Contracts')
						)  TBMO            									on ManufactureOrders.ManufactureID = TBMO.ManufactureID

		--- RELACION A GoodsBin PAARA AGREGAR EL BIN DE LA CAJA		AGREGADO POR RODRIGO RAMIREZ 20250604
		LEFT OUTER JOIN GoodsBins		AS GB				WITH(NOLOCK)	ON PackedBoxes.GoodsBinID = GB.GoodsBinID
		LEFT OUTER JOIN DropDownValues3	AS DDV3				WITH(NOLOCK)	ON PackedBoxes.BoxTagID = DDV3.DropDownValueID

	--left outer join StyleColors	stylecol on stylecol.StyleColorID = OrderItems.StyleColorID
	--select * from _ColumnSpecs$ where FinalColumn = 'StyleColor' order by TableName
	WHERE
        -- ( PackedItems.PackedBoxID IN (
        --         SELECT PackedBoxID FROM PackedBoxes WHERE
        --             ((StatusID IN (SELECT StatusID FROM StatusNames WHERE
        --                             ( ( StatusName IN ( SELECT OriginalText
        --                                     FROM Dictionary WHERE
        --                             (((TranslatedText <> 'Shipped')))
        --                                 AND MessageSource = 'StatusNames'
        --                                     AND LanguageID = 1
        --                                     )
        --                                 )
        --                             ))
        --                 )))
        -- )
        Dictionary5.OriginalText = 'Packed'
        -- AND (Orders2.PONumber like 'PO%')
		 and (PackedBoxes.OrderID IS NOT NULL)
        --AND PackedPallets.PalletNumber IS NOT NULL
        AND GB.Bin IS NOT NULL
		AND (GB.Bin LIKE 'Skid%' OR GB.Bin LIKE 'RT%' OR GB.Bin LIKE 'AIR%' OR GB.Bin LIKE 'SM%' OR GB.Bin LIKE 'TRUCK%')
        -- and orders2.ponumber = 'PO021122-STOCK-LCA'
        -- AND Orders2.OrderID=    181773
        -- AND Orders2.PONumber LIKE '%po021122-stock-lca%'
    -- GROUP BY
    --  Orders2.OrderID                            
    -- ,Orders2.PONumber                           
    -- ,Styles.StyleNumber                         
    -- -- ,SNS.SeasonName                             
    -- ,PackedBoxes.BoxNumber                      
    -- ,ManufactureOrders.Comments16   
    --  ,CASE
    --  WHEN SNS.SeasonName = 'EMB FG' THEN 'EMBFG'
    --  ELSE 'SEASON' END        
    -- ,CASE 
    --         WHEN Orders2.PONumber LIKE 'ORD%' THEN
    --             'ORD_'
    --         ELSE 
    --             CAST(Orders2.OrderID AS VARCHAR )
    --         END   
    --     ,Dictionary5.OriginalText              
)
--SELECT * FROM CTE WHERE BOXNUMBER ='00648574'

SELECT top 100 percent

------------- SE MODIFICÓ PARA REALIZAR UN SOLO SHIPMENT
  --   CONCAT(TB.[TariffCategory],'-',
	 --   TB.CountryOfOrigin,'-',
		--TB.[SeasonF],'_'
  --      ,FORMAT(ISNULL(TBG.[ROWF],
  --        (TBG_2.[ROWF] +10000)
  --      ),'0000') )     AS [KeyDat]
  [KeyDat] = 'ONE SHIPMENT'
    -- ,TBG.[ROWF]
    ,TB.[OrderID]
    ,TB.[PONumber]
    ,TB.[StyleNumber]
    ,TB.[StyleColor]
    ,TB.[BoxNumber]
	,TB.[ConsolidatedBox]
	,TB.[LCA_TrackingNumber]
	,TB.[Bin]
    ,SUM(TB.[Quantity]) AS [Quantity]
    ,TB.[SeasonF]
    ,TB.[TariffCategory]
    ,TB.[PalletNumber]
    -- ,TB.[Season]
    -- ,TB.[GarmentSize]
    ,TB.[STATUS]
	,TB.[BasePrice]
	,TB.[TotalPrintValue]
	,TB.ProductDivision
	,TB.CustomerOrder

FROM CTE AS TB
LEFT OUTER JOIN  (
 
            SELECT 
                [TariffCategory] 
                ,[SeasonF]
                ,[OrderID]
                ,[StyleNumber]
                ,[StyleColor]
                ,   ROW_NUMBER() OVER(PARTITION BY      [TariffCategory] , [CountryOfOrigin], [OrderID]
                                            ORDER BY    [TariffCategory] ,[CountryOfOrigin], [SeasonF],[OrderID],[StyleNumber],[StyleColor],[BasePrice],[TotalPrintValue]
                                            )  AS ROWF
				,[BasePrice]
                ,[TotalPrintValue]
				,CountryOfOrigin
                from (     select [OrderID]
                                ,[StyleNumber]   
                                ,[TariffCategory] 
                                ,[SeasonF]
								,[BasePrice]
                                ,[TotalPrintValue]
                                ,[StyleColor]
								,CountryOfOrigin
                        FROM CTE
                        group by 
                            [OrderID]
                            ,[StyleNumber]
                            ,[TariffCategory] 
                            ,[SeasonF]
							,[BasePrice]
							,[TotalPrintValue]
                            ,[StyleColor]
							,CountryOfOrigin
                ) as tb
            ) AS TBG ON     TBG.[OrderID]           = TB.[OrderID] 
                        AND TBG.[TariffCategory]    = TB.[TariffCategory]
                        AND TBG.[StyleNumber]		= TB.[StyleNumber]
                        AND TBG.[StyleColor]          = TB.[StyleColor] 
                        AND TBG.[SeasonF]           = TB.[SeasonF] 
                        AND TBG.[BasePrice]         = TB.[BasePrice] 
                        AND TBG.[TotalPrintValue]   = TB.[TotalPrintValue] 
						AND TBG.CountryOfOrigin     = TB.CountryOfOrigin 
LEFT OUTER JOIN  (
 
            SELECT 
                [TariffCategory] 
                ,[SeasonF]
                ,[OrderID]
                ,[StyleNumber]
                ,[StyleColor]
                ,   ROW_NUMBER() OVER(PARTITION BY      [TariffCategory],CountryOfOrigin ,[OrderID]
                                            ORDER BY    [TariffCategory],CountryOfOrigin ,[SeasonF],[OrderID],[StyleNumber],[StyleColor]
                                            )  AS ROWF
				,CountryOfOrigin
                from (     select [OrderID]
                                ,[StyleNumber]   
                                ,[TariffCategory] 
                                ,[SeasonF]
                                ,[StyleColor]
								,CountryOfOrigin
                        FROM CTE
                        group by 
                            [OrderID]
                            ,[StyleNumber]
                            ,[TariffCategory] 
                            ,[SeasonF]
                            ,[StyleColor]
							,CountryOfOrigin
                ) as tb
            ) AS TBG_2 ON       TBG_2.[OrderID]           = TB.[OrderID] 
                            AND TBG_2.[TariffCategory]    = TB.[TariffCategory]
                            AND TBG_2.[StyleNumber]		= TB.[StyleNumber]
                            AND TBG_2.[SeasonF]           = TB.[SeasonF] 
                            AND TBG_2.[StyleColor]           = TB.[StyleColor] 
                       
-- WHERE TB.PONumber ='ORD-2796736'
-- WHERE TB.PONumber ='PO0728-STOCK-LCA'
GROUP BY 
------------- SE MODIFICÓ PARA REALIZAR UN SOLO SHIPMENT
     -- CONCAT(TB.[TariffCategory],'-',
	    --TB.CountryOfOrigin,'-',
	    --TB.[SeasonF],'_'
     --   ,FORMAT(ISNULL(TBG.[ROWF],
     --     (TBG_2.[ROWF] +10000)
     --   ),'0000') )   
    TB.[OrderID]
    ,TB.[PONumber]
    ,TB.[StyleNumber]
    ,TB.[StyleColor]
    ,TB.[BoxNumber]
	,TB.[ConsolidatedBox]
	,TB.[LCA_TrackingNumber]
	,TB.[Bin]
    -- ,SUM(TB.[Quantity]) AS [Quantity]
    ,TB.[SeasonF]
    ,TB.[TariffCategory]
    ,TB.[PalletNumber]
    -- ,TB.[Season]
    -- ,TB.[GarmentSize]
    ,TB.[STATUS]
	,TB.[BasePrice]
	,TB.[TotalPrintValue]
	,TB.ProductDivision
	,TB.CustomerOrder

    -- ,TBG.[ROWF]
    -- ,TBG_2.[ROWF]
ORDER BY 
------------- SE MODIFICÓ PARA REALIZAR UN SOLO SHIPMENT
   --      CONCAT(TB.[TariffCategory],'-',
		 --TB.CountryOfOrigin,'-',
		 --TB.[SeasonF],'_'
   --     ,FORMAT(ISNULL(TBG.[ROWF],
   --       (TBG_2.[ROWF] +10000)
   --     ),'0000') )
        TB.[OrderID]
        ,TB.[PONumber]
        ,TB.[BoxNumber]
		
GO


