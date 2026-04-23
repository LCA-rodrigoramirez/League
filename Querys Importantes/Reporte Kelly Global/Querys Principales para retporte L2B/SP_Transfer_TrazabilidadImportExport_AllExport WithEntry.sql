

USE AppsLCA


-- GO

-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO


-- ALTER PROCEDURE [dbo].[SP_Transfer_TrazabilidadImportExport_AllDataExport] 
       
-- AS
BEGIN
	SET NOCOUNT ON

DROP TABLE IF EXISTS #TB_Transfer_Trazabilidad
DROP TABLE IF EXISTS #TB_Waybills_9802
DROP TABLE IF EXISTS #TB_Group_Waybills_9802
DROP TABLE IF EXISTS #AnexoFacturacion_ShipDate
DROP TABLE IF EXISTS #DATA_AnexoFacturacion_NoTransfer
DROP TABLE IF EXISTS #DATA_AnexoFacturacion_Transfer
DROP TABLE IF EXISTS #TB_MOS_FOR_SUMMARY_GROUP
DROP TABLE IF EXISTS #TB_FAMO_SUMMARY



    SELECT  
        E.[Waybill] 
        ,[ShipDate] = MAX(CAST(E.[ShipDate] AS DATE))
    INTO #TB_Waybills_9802
    FROM [AppsLCA].[dbo].[TB_Transfer_Export_Duty] AS E WITH(NOLOCK)
    
    GROUP BY E.[Waybill] 
    -- WHERE E.[Waybill] IN(
    --     'HW-20250410'
    --     ,
    --     'AIR-HW-20250821'
    --     -- ,
    --     -- 'APP-20251107'
    --     )
    
    
    SELECT TOP 1 * 
    INTO #TB_Group_Waybills_9802 FROM #TB_Waybills_9802
    ORDER BY [ShipDate] ASC
    
    -- -- SELECT * FROM #TB_Group_Waybills_9802
    -- -- SELECT * FROM #TB_Waybills_9802
    -- -- ORDER BY ShipDate ASC
    
    -- -- SELECT DISTINCT ShipDate,Waybill FROM AppsLCA.DBO.ImportExport_AnexoFacturacion
    -- -- ORDER BY ShipDate ASC
    
    -- -- SELECT  AF.* FROM AppsLCA.DBO.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK)
    -- -- INNER JOIN #TB_Waybills_9802 AS B ON B.Waybill = AF.Waybill
    -- -- LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_Export_Duty] AS E WITH(NOLOCK) ON E.ID = AF.ID
    -- -- WHERE E.ID IS NULL
    -- -- AND E.RO_ID IS NULL
    -- -- -- AND (AF.SeasonName IS NULL OR AF.SeasonName NOT IN ('EMB FG') )
    -- -- -- AND (AF.CountryOfOrigin is null or  AF.CountryOfOrigin = '')
    -- -- AND (AF.RO_ID IS NULL AND AF.SeasonName = 'EMB FG')
    
    
    SELECT  
         AF.* 
        ,[TypeData]                 = 'Export'
        ,[Receiving_Cost_Update]    = CAST(NULL AS DECIMAL(12,2))
        ,[Freight_Cost_Update]      = CAST(NULL AS DECIMAL(12,2))
        ,[UnitReceiveCost_Update]   = CAST(NULL AS DECIMAL(12,2))
        ,[ProductDivision_Update]   = CAST(NULL AS VARCHAR(200))
    INTO #AnexoFacturacion_ShipDate
    FROM AppsLCA.DBO.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK)
    LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_Export_Duty] AS E WITH(NOLOCK) ON E.ID = AF.ID
    LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_Waybill_Void] AS WNO WITH(NOLOCK) ON WNO.waybill = AF.Waybill
    WHERE E.ID IS NULL
    AND WNO.waybill IS NULL
	AND AF.ShipDate >= '2024-01-12' AND AF.ShipDate <= '2025-12-09'
    -- AND E.RO_ID IS NULL
    
    
    UPDATE S SET
         [Receiving_Cost_Update]     = COALESCE(B.[Receiving_Cost_Update]   ,0.0000)
        ,[Freight_Cost_Update]       = COALESCE(B.[Freight_Cost_Update]     ,0.0000)
        ,[UnitReceiveCost_Update]    = COALESCE(B.[UnitReceiveCost_Update]  ,0.0000)
    FROM #AnexoFacturacion_ShipDate AS S
    LEFT JOIN(
                SELECT 
                     [ManufactureID]
                    ,[Receiving_Cost_Update]    = CAST(ROUND(SUM( (ISNULL([Contracts_PurchasePrice],0.00) ) ),2) AS DECIMAL (12,2)) / SUM([Make])
                    ,[Freight_Cost_Update]      = CAST(ROUND(SUM(  (ISNULL([Contracts_FreightPrice] ,0.00) ) ),2) AS DECIMAL (12,2)) / SUM([Make])
                    ,[UnitReceiveCost_Update]   = CAST(ROUND(SUM( (ISNULL([Contracts_PurchasePrice],0.00) ) + (ISNULL([Contracts_FreightPrice] ,0.00) ) ),2) AS DECIMAL (12,2)) / SUM([Make])
                    ,[Make_1]                   = SUM([Make])
				FROM(
		                select distinct  
		                      [OrderID]                     = MOS.OrderID
		                     ,[ManufactureID]               = MOS.ManufactureID
		                     ,[ManufactureNumber]           = MOs.ManufactureNumber
		                     ,[Contracts_PurchasePrice]     = FAM1.Contracts_PurchasePrice
		                     ,[Contracts_FreightPrice]      = FAM1.Contracts_FreightPrice
		                     ,[Make]                        = Fam1.Make
                        FROM (
                                SELECT DISTINCT 
                                    RO_ID 
                                FROM #AnexoFacturacion_ShipDate 
                                WHERE RO_ID IS NOT NULL
                        ) AS TB
                        INNER JOIN lca.dbo.ManufactureOrders                    AS MOS  WITH(NOLOCK) ON MOS.ManufactureID = TB.RO_ID
                        INNER JOIN AppsLCA.dbo.TB_MO_PartNumber_IM_Materials    AS FAM1 WITH(NOLOCK) ON MOS.ManufactureID = FAM1.ManufactureID
					) AS TB2
					GROUP BY TB2.ManufactureID
	) AS B ON B.ManufactureID = S.RO_ID 
    
    -- select DISTINCT productDivision FROM #AnexoFacturacion_ShipDate
    -- select * FROM #AnexoFacturacion_ShipDate WHERE ProductDivision = 'Accesories'    
    
    
    UPDATE S SET
         [ProductDivision_Update]     = COALESCE(B.[ProductDivision]   ,S.[ProductDivision])
    FROM #AnexoFacturacion_ShipDate AS S
    LEFT JOIN (
		    SELECT 
		        [ManufactureID]     = DAT.ManufactureID
		        ,[ProductDivision]  = IIF(ST.Comments9 = 'Headwear','Headwear','Apparel')
		    FROM (SELECT DISTINCT 
		                                    ManufactureID
		                                FROM #AnexoFacturacion_ShipDate 
		                                WHERE ManufactureID IS NOT NULL
		                ) AS DAT
		    LEFT JOIN LCA.dbo.ManufactureOrders AS MO WITH(NOLOCK) ON MO.ManufactureID = DAT.ManufactureID
		    LEFT JOIN LCA.dbo.OrderItems        AS OI WITH(NOLOCK) ON OI.OrderItemID   = MO.FirstOrderItemID
		    LEFT JOIN LCA.dbo.Styles            AS ST WITH(NOLOCK) ON ST.StyleID       = OI.StyleID
	    ) AS B ON B.ManufactureID = S.ManufactureID
    
    -- SELECT DISTINCT ManufactureID,count(*) FROM #AnexoFacturacion_ShipDate
    -- where ManufactureID is null
    -- group by ManufactureID
    
    -- select top 1000 *
    --  FROM #AnexoFacturacion_ShipDate
    -- where ManufactureID is null
    
    SELECT
	     [R]					                        = ROW_NUMBER() OVER ( ORDER BY 
                                							E.WAYBILL
                                							,E.BOXNUMBER
                                							,E.STYLENUMBER
                                							,E.STYLECOLOR
                                							,E.SIZE)
		,[DeclarationDate]	                            = CAST(NULL AS DATE)--i.DeclarationDate
	    ,[DeclarationNumber]                            = CAST(NULL AS VARCHAR(100))--i.DeclarationNumber
		,[IM5]				                            = CAST(NULL AS VARCHAR(50))--i.IM5
		,[InvoiceNumber]	                            = CAST(NULL AS VARCHAR(200))--i.InvoiceNumber
		,[Manufacturer]		                            = e.Manufacturer
		,[CountryOfOrigin]	                            = E.CountryOfOrigin  --COALESCE(k.CountryOfOrigin, i.CountryOfOriginName )
		,[RO]				                            = E.RO
		,[RO_ID]			                            = E.RO_ID
		,[Style]			                            = E.StyleNumber
		,[SeasonName]                                   = E.SeasonName
		,[Color]			                            = E.StyleColor
		,[Size]			                                = e.[Size]
		,[Date]				                            = E.ShipDate
		,[QtyImport]		                            = CAST(NULL AS INT) --k.QtyImport
		,[Waybill]			                            = E.Waybill
		,[Boxnumber]		                            = E.Boxnumber
		,[PoNumber]			                            = E.Ponumber
		,[ItemDetailID]		                            = REPLACE(E.Ponumber,'ORD-','')
		,[ManufactureID]                                = e.ManufactureID
		,[MO]                                           = e.MO
		,[QtyExport]		                            = E.Qty --k.QtyExport
		,[Balance]			                            = CAST(NULL AS INT)
		,[Unit_Purchase_Price]	                        = COALESCE(	E.Receiving_Cost_Update	 ,0)
		,[Unit_Receive_Freight]	                        = COALESCE(	E.Freight_Cost_Update	 ,0)
		,[UnitReceiveCost (PurchasePrice + Freight)]	= COALESCE( E.UnitReceiveCost_Update ,0)
		--,[UnitBasePrice]		= IIF(k.TypeData = 'Export',e.BasePrice,0)
		,[UnitBasePrice]	                            = CAST(IIF(
							                                		 IIF(E.TypeData = 'Export',e.Price -e.BasePrice,0) = 0
							                                		,IIF(E.TypeData = 'Export',e.BasePrice,0) - IIF(e.TypeData = 'Export',0.08,0)
							                                		,IIF(E.TypeData = 'Export',e.BasePrice,0)
							                                	  ) AS DECIMAL(18,2))
		,[QtyTransfer]		                            = 0 --k.QtyTransfer
		,[QtyNoTransfer]	                            = 0 --k.QtyNoTransfer
		,[UnitValueAdded]	                            = CAST((IIF(E.TypeData = 'Export',e.Price -e.BasePrice,0)) 
							                                		+ 
							                                		IIF(
							                                			IIF(E.TypeData = 'Export',e.Price -e.BasePrice,0) = 0 
							                                			OR IIF(E.TypeData = 'Export',e.Price -e.BasePrice,0) IS NULL
							                                			,IIF(E.TypeData = 'Export',0.08,0) 
							                                			, 0) AS decimal(18,2))
		,[UnitTotalValue]	                            = IIF(E.TypeData = 'Export' , e.Price,0)
		,[UnitTotalValue - OutFreight]	                = IIF(E.TypeData = 'Export' , e.Price -0.25,0)
	    ,[year]				                            = CAST(NULL AS INT) -- year(cast(i.DeclarationDate as date))
	    ,[month]                                        = CAST(NULL AS INT) -- month(cast(i.DeclarationDate as date))
		,[ProductDivision]	                            = E.ProductDivision_Update
		,IDKardex			                            = CAST(NULL AS INT) --k.idKardex
		,[Import Value (Purchase Price * QtyImport)]	= NULL --IIF(k.TypeData = 'Import' and k.qtyImport>0,	i.receivingCost	,0) * k.QtyImport
		
		,[Export Blank Value]	                        = (IIF(
																 IIF(E.TypeData = 'Export',e.Price -e.BasePrice,0) = 0
																,IIF(E.TypeData = 'Export',e.BasePrice,0) - IIF(E.TypeData = 'Export',0.08,0)
																,IIF(E.TypeData = 'Export',e.BasePrice,0)
															  )) * E.Qty
		,[Export Value Added]	                        = ( 
																(IIF(E.TypeData = 'Export',e.Price -e.BasePrice,0)) 
																+ 
																IIF(
																		IIF(E.TypeData = 'Export',e.Price -e.BasePrice,0) = 0 
																	OR  IIF(E.TypeData = 'Export',e.Price -e.BasePrice,0) IS NULL
																	,   IIF(E.TypeData = 'Export',0.08,0) 
																	, 0) 
															 ) * E.Qty
		
		,[Total Export Value]	                        = IIF(E.TypeData = 'Export',e.Price ,0) * E.Qty
	    ,[OriginalExportDate]                           = IIF(E.TypeData = 'Export',cast( E.ShipDate AS DATE) ,NULL)
	    ,[Entry #]                                   	= CAST(NULL AS VARCHAR(100))
	    ,[ExportDate]                                   = CAST(NULL AS DATE)
	    ,[Month_ExportDate]                             = CAST(NULL AS INT) -- IIF(k.TypeData = 'Export',month(cast( k.FechaMovimiento as Date)) ,null)
	    ,[Year_ExportDate]                              = CAST(NULL AS INT) -- IIF(k.TypeData = 'Export',year(cast( k.FechaMovimiento as Date)) ,null)
		,[US_HTSCode]                                   =  case 
					        								    when E.[ProductDivision] = 'Headwear' AND lmn.US_HTSCode is not null then lmn.US_HTSCode
					        								    when E.[ProductDivision] = 'Headwear' AND lmn.US_HTSCode is null and lmn.CA_HTSCode is not null then lmn.CA_HTSCode
					        								    else COALESCE(HT.US_HTSCode,e.SAC)
					                                        end 
		,[301China_$]                                   = CAST(NULL AS DECIMAL(18,4))
		,[Fenta_$]                                      = CAST(NULL AS DECIMAL(18,4))
		,[Recip_$]                                      = CAST(NULL AS DECIMAL(18,4))
		,[HTS_$]                                        = CAST(NULL AS DECIMAL(18,4))
		,[Total_$]                                      = CAST(NULL AS DECIMAL(18,4))
		
		,[TValue_301China_$]                            = CAST(NULL AS DECIMAL(18,4))
		,[TValue_Fenta_$]                               = CAST(NULL AS DECIMAL(18,4))
		,[TValue_Recip_$]                               = CAST(NULL AS DECIMAL(18,4))
		,[TValue_HTS_$]                                 = CAST(NULL AS DECIMAL(18,4))
		,[TValue_Total_$]                               = CAST(NULL AS DECIMAL(18,4))
		,[TValue_Total_$2]                              = CAST(NULL AS DECIMAL(18,4))
		
		,[T_301China_$]                                 = CAST(NULL AS DECIMAL(18,4))
		,[T_Fenta_$]                                    = CAST(NULL AS DECIMAL(18,4))
		,[T_Recip_$]                                    = CAST(NULL AS DECIMAL(18,4))
		,[T_HTS_$]                                      = CAST(NULL AS DECIMAL(18,4))
		,[T_Total_$]                                    = CAST(NULL AS DECIMAL(18,4))
		
		,[301China_%]                                   = CAST(NULL AS DECIMAL(18,4))
		,[Fenta_%]                                      = CAST(NULL AS DECIMAL(18,4))
		,[Recip_%]                                      = CAST(NULL AS DECIMAL(18,4))
		,[HTS_%]                                        = CAST(NULL AS DECIMAL(18,4))
		
		,[Drawback]                                     = CAST(NULL AS DECIMAL(18,4))
		,[TypeData]                                     = e.TypeData
		,[FilterEntryDate]                              = CAST(NULL AS BIT)
		,[Filter2024]                                   = CAST(NULL AS BIT)
		,[Filter2024-202505]                            = CAST(NULL AS BIT)
		,[Filter202505-Today]                           = CAST(NULL AS BIT)
		,[Original_BasePrice]                           = E.BasePrice
		,[Original_Price]                               = E.Price
		,[Original_IDExport]                            = E.ID
    INTO #DATA_AnexoFacturacion_NoTransfer
    FROM #AnexoFacturacion_ShipDate AS E
    left  join (Select * from 
        								(   select Color, Style, CA_HTSCode, US_HTSCode 
        								    from(
        								            select 
        								                 [PartNumber]   = RW.PartNumber
        								                ,[HTSCodeID]    = RW.HTSCodeID
        								                ,[Color]        = Col.ColorName
        								                ,[Style]        = CL.ComponentName
        								                ,[CA_HTSCode]   = DRD.DropDownValue
        								                ,[US_HTSCode]   = DRD.Description3
        								                ,[Cuenta]       = row_number() over( partition by 
        								                                                Col.ColorName
        								                                                ,CL.ComponentName 
        								                                    order by Col.ColorName, CL.ComponentName, RW.HTSCOdeID)
        										    FROM        [LCA].[dbo].[RawMaterials]  AS RW   WITH(NOLOCK)
        											left join   lca.dbo.Colors              AS COL  WITH(NOLOCK) on RW.ColorID = Col.ColorID
        											left join   lca.dbo.ComponentLibrary    AS CL   WITH(NOLOCK) on RW.ComponentID = CL.ComponentID and CL.ComponentCategoryID=11
        											left outer join lca.dbo.DropDownValues DRD with (nolock)
        												on RW.HTSCodeID = DRD.DropDownValueID
        											where Cl.ComponentName is not null and Col.ColorName is not null and RW.HTSCodeID is not null
        										 ) abc123 where Cuenta=1
        								) fgh
        						) lmn	on E.StyleNumber = lmn.Style and E.StyleColor=lmn.Color
	LEFT JOIN [LCA].[dbo].[ManufactureOrders]   AS MO WITH(NOLOCK) ON COALESCE(E.RO_ID,e.ManufactureID ) = MO.ManufactureID
	LEFT JOIN [LCA].[dbo].[OrderItems]          AS OI WITH(NOLOCK) ON MO.FirstOrderItemID = OI.OrderItemID
	LEFT JOIN [LCA].[dbo].[Styles]              AS ST WITH(NOLOCK) ON OI.StyleID = ST.StyleID
	LEFT JOIN [LCA].[dbo].[HTSStyleCodes]       AS HT WITH(NOLOCK) ON HT.HTSStyleCodeID = ST.HTSStyleCodeID
	WHERE E.ShipDate <= '2025-12-09'
    
    -- RETURN
    
    -- -- SELECT  AF.* FROM AppsLCA.DBO.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK)
    -- -- INNER JOIN #TB_Waybills_9802 AS B ON B.Waybill = AF.Waybill
    -- -- LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_Export_Duty] AS E WITH(NOLOCK) ON E.ID = AF.ID
    -- -- WHERE E.ID IS NULL
    -- -- AND E.RO_ID IS NULL
    
-- SELECT  
--      [ExportQty]        = E.Qty
--     ,[AnexoQty]         = AF.Qty
--     ,E.[id]
--     ,[Dif]              = E.Qty - AF.Qty
-- FROM AppsLCA.dbo.TB_Transfer_Export_Duty AS E WITH(NOLOCK)
-- LEFT JOIN AppsLCA.DBO.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK) ON AF.ID = E.ID
-- WHERE (E.Qty - AF.Qty) <> 0
 
     
SELECT 
	[R]					                            = ROW_NUMBER() OVER ( ORDER BY 
                                							i.DeclarationDate
                                							,i.IM5
                                							,i.InvoiceNumber
                                							,k.Manufacturer
                                							,COALESCE(k.CountryOfOrigin, i.CountryOfOriginName )
                                							,K.RO
                                							,K.FechaMovimiento
                                							,k.Correlativo)
	,[DeclarationDate]	                            = i.DeclarationDate
    ,[DeclarationNumber]                            = i.DeclarationNumber
	,[IM5]				                            = i.IM5
	,[InvoiceNumber]	                            = i.InvoiceNumber
	,[Manufacturer]		                            = k.Manufacturer
	,[CountryOfOrigin]	                            = COALESCE(k.CountryOfOrigin, i.CountryOfOriginName )
	,[RO]				                            = K.RO
	,[RO_ID]			                            = k.RO_ID
	,[Style]			                            = k.StyleNumber
	,[SeasonName]                                   = E.SeasonName
	,[Color]			                            = k.Color
	,[Size]			                                = e.[Size]
	,[Date]				                            = k.FechaMovimiento
	,[QtyImport]		                            = k.QtyImport
	,[Waybill]			                            = k.Waybill
	,[Boxnumber]		                            = e.Boxnumber
	,[PoNumber]			                            = e.Ponumber
	,[ItemDetailID]		                            = replace(e.Ponumber,'ORD-','')
	,[ManufactureID]                                = e.ManufactureID
	,[MO]                                           = e.MO
	,[QtyExport]		                            = k.QtyExport
	,[Balance]			                            = k.Balance
	,[Unit_Purchase_Price]	                        = IIF(k.TypeData = 'Import' and k.qtyImport>0,	i.receivingCost	,0)
	,[Unit_Receive_Freight]	                        = IIF(k.TypeData = 'Import' and k.qtyImport>0,	i.FreightCost	,0)
	,[UnitReceiveCost (PurchasePrice + Freight)]	= IIF(k.TypeData = 'Import' and k.qtyImport>0,CAST(ROUND(i.TotalCost / k.qtyImport,2) AS DECIMAL(18,2)),0)
	
	,[UnitBasePrice]	                            = CAST(IIF(
						                                		IIF(k.TypeData = 'Export',EE.Price -EE.BasePrice,0) = 0
						                                		,IIF(k.TypeData = 'Export',EE.BasePrice,0) - IIF(k.TypeData = 'Export',0.08,0)
						                                		,IIF(k.TypeData = 'Export',EE.BasePrice,0)
						                                	  ) AS decimal(18,2))
	,[QtyTransfer]		                            = k.QtyTransfer
	,[QtyNoTransfer]	                            = k.QtyNoTransfer
	,[UnitValueAdded]	                            = CAST((IIF(k.TypeData = 'Export',EE.Price -EE.BasePrice,0)) 
						                                		+ 
						                                		IIF(
						                                			IIF(k.TypeData = 'Export',EE.Price -EE.BasePrice,0) = 0 
						                                			OR IIF(k.TypeData = 'Export',EE.Price -EE.BasePrice,0) IS NULL
						                                			,IIF(k.TypeData = 'Export',0.08,0) 
						                                			, 0) AS decimal(18,2))
	
	,[UnitTotalValue]	                            = IIF(k.TypeData = 'Export' , EE.Price,0)
	,[UnitTotalValue - OutFreight]	                = IIF(k.TypeData = 'Export' , EE.Price -0.25,0)
    ,[year]				                            = CAST(year(cast(i.DeclarationDate as date)) AS INT)
    ,[month]                                        = CAST(month(cast(i.DeclarationDate as date)) AS INT)
	,[ProductDivision]	                            = i.ProductDivision
	,IDKardex			                            = k.idKardex
	,[Import Value (Purchase Price * QtyImport)]	= IIF(k.TypeData = 'Import' and k.qtyImport>0,	i.receivingCost	,0) * k.QtyImport
	
	,[Export Blank Value]	                        = (IIF(
																IIF(k.TypeData = 'Export',EE.Price -EE.BasePrice,0) = 0
																,IIF(k.TypeData = 'Export',EE.BasePrice,0) - IIF(k.TypeData = 'Export',0.08,0)
																,IIF(k.TypeData = 'Export',EE.BasePrice,0)
															  )) * k.QtyExport
	,[Export Value Added]	                        = ( 
															(IIF(k.TypeData = 'Export',EE.Price -EE.BasePrice,0)) 
															+ 
															IIF(
																IIF(k.TypeData = 'Export',EE.Price -EE.BasePrice,0) = 0 
																OR IIF(k.TypeData = 'Export',EE.Price -EE.BasePrice,0) IS NULL
																,IIF(k.TypeData = 'Export',0.08,0) 
																, 0) 
														 ) * k.QtyExport
	
	,[Total Export Value]	                        = IIF(k.TypeData = 'Export',EE.Price ,0) * k.QtyExport
    ,[OriginalExportDate]                           = IIF(k.TypeData = 'Export',cast( k.FechaMovimiento as Date) ,null)
    ,[Entry #]                                   	= CAST(NULL AS VARCHAR(100))
    ,[ExportDate]                                   = CAST(NULL AS DATE)
    ,[Month_ExportDate]                             = CAST(NULL AS INT) -- IIF(k.TypeData = 'Export',month(cast( k.FechaMovimiento as Date)) ,null)
    ,[Year_ExportDate]                              = CAST(NULL AS INT) -- IIF(k.TypeData = 'Export',year(cast( k.FechaMovimiento as Date)) ,null)
	,[US_HTSCode]                                   =  case 
				        								    when k.[ProductDivision] = 'Headwear' AND lmn.US_HTSCode is not null then lmn.US_HTSCode
				        								    when k.[ProductDivision] = 'Headwear' AND lmn.US_HTSCode is null and lmn.CA_HTSCode is not null then lmn.CA_HTSCode
				        								    else COALESCE(HT.US_HTSCode,e.SAC)
				        								    -- else COALESCE(HT.US_HTSCode,'RODRIGO')
				        								    -- else HT.US_HTSCode
				                                        end 
	
	,[301China_$]                                   = CAST(NULL AS DECIMAL(18,4))
	,[Fenta_$]                                      = CAST(NULL AS DECIMAL(18,4))
	,[Recip_$]                                      = CAST(NULL AS DECIMAL(18,4))
	,[HTS_$]                                        = CAST(NULL AS DECIMAL(18,4))
	,[Total_$]                                      = CAST(NULL AS DECIMAL(18,4))
	
	,[TValue_301China_$]                            = CAST(NULL AS DECIMAL(18,4))
	,[TValue_Fenta_$]                               = CAST(NULL AS DECIMAL(18,4))
	,[TValue_Recip_$]                               = CAST(NULL AS DECIMAL(18,4))
	,[TValue_HTS_$]                                 = CAST(NULL AS DECIMAL(18,4))
	,[TValue_Total_$]                               = CAST(NULL AS DECIMAL(18,4))
	,[TValue_Total_$2]                              = CAST(NULL AS DECIMAL(18,4))
	
	,[T_301China_$]                                 = CAST(NULL AS DECIMAL(18,4))
	,[T_Fenta_$]                                    = CAST(NULL AS DECIMAL(18,4))
	,[T_Recip_$]                                    = CAST(NULL AS DECIMAL(18,4))
	,[T_HTS_$]                                      = CAST(NULL AS DECIMAL(18,4))
	,[T_Total_$]                                    = CAST(NULL AS DECIMAL(18,4))
	
	,[301China_%]                                   = CAST(NULL AS DECIMAL(18,4))
	,[Fenta_%]                                      = CAST(NULL AS DECIMAL(18,4))
	,[Recip_%]                                      = CAST(NULL AS DECIMAL(18,4))
	,[HTS_%]                                        = CAST(NULL AS DECIMAL(18,4))
	
	,[Drawback]                                     = CAST(NULL AS DECIMAL(18,4))
	,[TypeData]                                     = k.TypeData
	,[FilterEntryDate]                              = CAST(NULL AS BIT)
	,[Filter2024]                                   = CAST(NULL AS BIT)
	,[Filter2024-202505]                            = CAST(NULL AS BIT)
	,[Filter202505-Today]                           = CAST(NULL AS BIT)
	,[Original_BasePrice]                           = EE.BasePrice
	,[Original_Price]                               = EE.Price
	,[Original_IDExport]                            = EE.ID
	--,k.*
	--		select * 
-- INTO #TB_Transfer_Trazabilidad
INTO #DATA_AnexoFacturacion_Transfer
from AppsLCA.dbo.TB_Transfer_Kardex_Duty as k with(nolock)
left join AppsLCA.dbo.TB_Transfer_Import_Duty as i with(nolock) on i.id = k.IDImport and i.[status]=1
left join AppsLCA.dbo.TB_Transfer_Export_Duty as e with(nolock) on e.id = k.IDExport and e.[status]=1
left join AppsLCA.dbo.ImportExport_AnexoFacturacion as EE with(nolock) on EE.ID = E.ID 
LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_Waybill_Void] AS WNO WITH(NOLOCK) ON WNO.waybill = k.Waybill
-- INNER JOIN #TB_Waybills_9802 AS WB ON k.Waybill = WB.Waybill
left  join (Select * from 
        								(   select Color, Style, CA_HTSCode, US_HTSCode 
        								    from(
        								            select 
        								                 [PartNumber]   = RW.PartNumber
        								                ,[HTSCodeID]    = RW.HTSCodeID
        								                ,[Color]        = Col.ColorName
        								                ,[Style]        = CL.ComponentName
        								                ,[CA_HTSCode]   = DRD.DropDownValue
        								                ,[US_HTSCode]   = DRD.Description3
        								                ,[Cuenta]       = row_number() over( partition by 
        								                                                Col.ColorName
        								                                                ,CL.ComponentName 
        								                                    order by Col.ColorName, CL.ComponentName, RW.HTSCOdeID)
        										    FROM        [LCA].[dbo].[RawMaterials]  AS RW   WITH(NOLOCK)
        											left join   lca.dbo.Colors              AS COL  WITH(NOLOCK) on RW.ColorID = Col.ColorID
        											left join   lca.dbo.ComponentLibrary    AS CL   WITH(NOLOCK) on RW.ComponentID = CL.ComponentID and CL.ComponentCategoryID=11
        											left outer join lca.dbo.DropDownValues DRD with (nolock)
        												on RW.HTSCodeID = DRD.DropDownValueID
        											where Cl.ComponentName is not null and Col.ColorName is not null and RW.HTSCodeID is not null
        										 ) abc123 where Cuenta=1
        								) fgh
        						) lmn	on k.StyleNumber = lmn.Style and k.Color=lmn.Color
LEFT JOIN [LCA].[dbo].[ManufactureOrders]   AS MO WITH(NOLOCK) ON COALESCE(K.RO_ID,e.ManufactureID ) = MO.ManufactureID
LEFT JOIN [LCA].[dbo].[OrderItems]          AS OI WITH(NOLOCK) ON MO.FirstOrderItemID = OI.OrderItemID
LEFT JOIN [LCA].[dbo].[Styles]              AS ST WITH(NOLOCK) ON OI.StyleID = ST.StyleID
LEFT JOIN [LCA].[dbo].[HTSStyleCodes]       AS HT WITH(NOLOCK) ON HT.HTSStyleCodeID = ST.HTSStyleCodeID
where (k.qtyimport >0 or k.qtyexport>0 )
AND E.ShipDate <= '2025-12-09'
AND WNO.waybill IS NULL
--AND k.RO = '22293-CHILL-ROY'
--and i.IM5 = '5-745'
--cast(i.DeclarationDate as date) >='2023-12-01'
--and (k.qtyimport >0 or k.qtyexport>0 )
--where k.RO_ID = 754358
--where k.RO_ID = 378373

-- SELECT COUNT(*) AS TotalRecords
-- FROM #TB_Transfer_Trazabilidad AS A
-- WHERE A.[ExportDate] IS NOT NULL

--75682 

SELECT 
	*
	,[R]                    = ROW_NUMBER() OVER(ORDER BY TypeQueryData,[RR])
	,[TariffCategory]       = CAST(NULL AS VARCHAR(MAX))
	,[FAMOManufacturer]     = CAST(NULL AS VARCHAR(MAX))
	,[FAMOCountryOfOrigin]  = CAST(NULL AS VARCHAR(MAX))
	,[FAMOTariffCategory]   = CAST(NULL AS VARCHAR(MAX))
	,[FAMOOption]           = CAST(NULL AS INT)
	,[Key1]                 = CAST(NULL AS VARCHAR(MAX))
	,[Key2]                 = CAST(NULL AS VARCHAR(MAX))
	,[Key3]                 = CAST(NULL AS VARCHAR(MAX))
	,[FinalComment]         = CAST(NULL AS VARCHAR(MAX))
	,[InvoiceKelly]         = CAST(NULL AS VARCHAR(MAX))
	,[TotalFobValue]        = CAST(NULL AS DECIMAL(18,2))
	,[CountryCode]			= CAST(NULL AS VARCHAR(10))
INTO #TB_Transfer_Trazabilidad FROM(
	SELECT 
		 [RR]   = [R]				
		,[DeclarationDate]	                           
		,[DeclarationNumber]                           
		,[IM5]				                           
		,[InvoiceNumber]	                           
		,[Manufacturer]		                           
		,[CountryOfOrigin]	                           
		,[RO]				                           
		,[RO_ID]			                           
		,[Style]	
		,[SeasonName]
		,[Color]			                           
		,[Size]			                           
		,[Date]				                           
		,[QtyImport]		                           
		,[Waybill]			                           
		,[Boxnumber]		                           
		,[PoNumber]			                           
		,[ItemDetailID]		   
		,[ManufactureID]
		,[MO]           
		,[QtyExport]		                           
		,[Balance]			                           
		,[Unit_Purchase_Price]	                       
		,[Unit_Receive_Freight]	                       
		,[UnitReceiveCost (PurchasePrice + Freight)]	
		,[UnitBasePrice]	 
		,[QtyTransfer]		                           
		,[QtyNoTransfer]	                           
		,[UnitValueAdded]	
		,[UnitTotalValue]	                           
		,[UnitTotalValue - OutFreight]	               
		,[year]				                           
		,[month]                                       
		,[ProductDivision]	                           
		,[IDKardex]			                           
		,[Import Value (Purchase Price * QtyImport)]	
		,[Export Blank Value]		
		,[Export Value Added]
		,[Total Export Value]	                       
		,[OriginalExportDate]          
		,[Entry #]                
		,[ExportDate]                                  
		,[Month_ExportDate]                            
		,[Year_ExportDate]                             
		,[US_HTSCode]       
		,[301China_$]                                  
		,[Fenta_$]                                     
		,[Recip_$]                                     
		,[HTS_$]                                       
		,[Total_$]                                     
		,[TValue_301China_$]                           
		,[TValue_Fenta_$]                              
		,[TValue_Recip_$]                              
		,[TValue_HTS_$]                                
		,[TValue_Total_$]                              
		,[TValue_Total_$2]                             
		,[T_301China_$]                                
		,[T_Fenta_$]                                   
		,[T_Recip_$]                                   
		,[T_HTS_$]                                     
		,[T_Total_$]                                   
		,[301China_%]                                  
		,[Fenta_%]                                     
		,[Recip_%]                                     
		,[HTS_%]                                       
		,[Drawback]                                    
		,[TypeData]                                    
		,[FilterEntryDate]                             
		,[Filter2024]                                  
		,[Filter2024-202505]                           
		,[Filter202505-Today]        
		,[TypeQueryData]            = 1
		,[Original_BasePrice]      
		,[Original_Price]          
		,[Original_IDExport]
	FROM #DATA_AnexoFacturacion_Transfer
	UNION ALL
	SELECT
		[RR]   = [R]	  			
		,[DeclarationDate]	                           
		,[DeclarationNumber]                           
		,[IM5]				                           
		,[InvoiceNumber]	                           
		,[Manufacturer]		                           
		,[CountryOfOrigin]	                           
		,[RO]				                           
		,[RO_ID]			                           
		,[Style]	
		,[SeasonName]
		,[Color]		
		,[Size]			                           
		,[Date]				                           
		,[QtyImport]		                           
		,[Waybill]			                           
		,[Boxnumber]		                           
		,[PoNumber]			                           
		,[ItemDetailID]		  
		,[ManufactureID]
		,[MO]           
		,[QtyExport]		                           
		,[Balance]			                           
		,[Unit_Purchase_Price]	                       
		,[Unit_Receive_Freight]	                       
		,[UnitReceiveCost (PurchasePrice + Freight)]	
		,[UnitBasePrice]	 
		,[QtyTransfer]		                           
		,[QtyNoTransfer]	                           
		,[UnitValueAdded]	
		,[UnitTotalValue]	                           
		,[UnitTotalValue - OutFreight]	               
		,[year]				                           
		,[month]                                       
		,[ProductDivision]	                           
		,[IDKardex]			                           
		,[Import Value (Purchase Price * QtyImport)]	
		,[Export Blank Value]		
		,[Export Value Added]
		,[Total Export Value]	                       
		,[OriginalExportDate]  
		,[Entry #]                        
		,[ExportDate]                                  
		,[Month_ExportDate]                            
		,[Year_ExportDate]                             
		,[US_HTSCode]       
		,[301China_$]                                  
		,[Fenta_$]                                     
		,[Recip_$]                                     
		,[HTS_$]                                       
		,[Total_$]                                     
		,[TValue_301China_$]                           
		,[TValue_Fenta_$]                              
		,[TValue_Recip_$]                              
		,[TValue_HTS_$]                                
		,[TValue_Total_$]                              
		,[TValue_Total_$2]                             
		,[T_301China_$]                                
		,[T_Fenta_$]                                   
		,[T_Recip_$]                                   
		,[T_HTS_$]                                     
		,[T_Total_$]                                   
		,[301China_%]                                  
		,[Fenta_%]                                     
		,[Recip_%]                                     
		,[HTS_%]                                       
		,[Drawback]                                    
		,[TypeData]                                    
		,[FilterEntryDate]                             
		,[Filter2024]                                  
		,[Filter2024-202505]                           
		,[Filter202505-Today] 
		,[TypeQueryData]            = 2
		,[Original_BasePrice]      
		,[Original_Price]          
		,[Original_IDExport]
	FROM #DATA_AnexoFacturacion_NoTransfer
) AS TB

--  SELECT count(*) FROM #TB_Transfer_Trazabilidad
--  where US_HTSCode is null
-- RETURN
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------

		
		
	SELECT DISTINCT 
		[ManufactureID]
	INTO #TB_MOS_FOR_SUMMARY_GROUP
	FROM(
		SELECT DISTINCT [RO_ID] AS [ManufactureID]  FROM #TB_Transfer_Trazabilidad WHERE RO_ID IS NOT NULL AND RO_ID <> 0 
		UNION ALL
		SELECT DISTINCT [ManufactureID] AS [ManufactureID]  FROM #TB_Transfer_Trazabilidad WHERE ManufactureID IS NOT NULL AND ManufactureID <> 0
	)AS TB
	-- DROP TABLE IF EXISTS #TB_FAMO_SUMMARY
SELECT 
    [ManufactureID]         = B.ManufactureId
    ,[MO]                   = B.MO
    ,[Manufacturer]         = B.Manufacturer
    ,[Proportion]           = B.Proportion
    ,[CountryOfOrigin]      = B.CountryOfOrigin
    ,[TariffCategory]       = B.TariffCategory
    ,[Key1]                 = CONCAT(Style , '-' , Color , '-' , [Size])
    ,[Key2]                 = CONCAT(Style , '-' , Color )
    ,[Key3]                 = CONCAT(Style  ,'')
    ,[Consumption]          = B.Consumption
    ,[RTariffCategory]      = ROW_NUMBER() OVER(PARTITION BY B.ManufactureId ORDER BY B.MO,B.Consumption DESC)
    ,[RTariffCategoryKey1]  = ROW_NUMBER() OVER(PARTITION BY B.ManufactureId,CONCAT(Style , '-' , Color , '-' , [Size]) ORDER BY B.MO,B.Consumption DESC)
    ,[RTariffCategoryKey2]  = ROW_NUMBER() OVER(PARTITION BY B.ManufactureId,CONCAT(Style , '-' , Color )               ORDER BY B.MO,B.Consumption DESC)
    ,[RTariffCategoryKey3]  = ROW_NUMBER() OVER(PARTITION BY B.ManufactureId,CONCAT(Style  ,'')                         ORDER BY B.MO,B.Consumption DESC)
INTO #TB_FAMO_SUMMARY
FROM #TB_MOS_FOR_SUMMARY_GROUP AS S
INNER JOIN [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Summary] AS B WITH(NOLOCK) ON S.ManufactureID = B.ManufactureId


	UPDATE S SET
	S.[FAMOOption] = NULL
FROM #TB_Transfer_Trazabilidad AS S

		UPDATE S SET
		     [Key1] = CONCAT(Style , '-' , Color , '-' , [Size])
		    ,[Key2] = CONCAT(Style , '-' , Color )
		    ,[Key3] = CONCAT(Style  ,'')
		FROM #TB_Transfer_Trazabilidad  AS S
			------actualizando Manufacturer y Country
			
					
		----option 1: RO_ID + Style + Color + Size
		UPDATE S SET
		     [FAMOManufacturer]     = F.[Manufacturer]
		    ,[FAMOCountryOfOrigin]  = F.[CountryOfOrigin]
		    ,[FAMOTariffCategory]   = F.[TariffCategory]
		    ,[FAMOOption]           = 11
		FROM #TB_Transfer_Trazabilidad  AS S
		INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.RO_ID = F.ManufactureID    AND S.[Key1] = F.[Key1] AND F.Proportion = 1 AND F.RTariffCategoryKey1 = 1
		WHERE S.[FAMOOption] IS NULL AND S.RO_ID IS NOT NULL
		
		----option 2: RO_ID + Style + Color 
		UPDATE S SET
		     [FAMOManufacturer]     = F.[Manufacturer]
		    ,[FAMOCountryOfOrigin]  = F.[CountryOfOrigin]
		    ,[FAMOTariffCategory]   = F.[TariffCategory]
		    ,[FAMOOption]           = 12
		FROM #TB_Transfer_Trazabilidad  AS S
		INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.RO_ID = F.ManufactureID    AND S.[Key2] = F.[Key2] AND F.Proportion = 1 AND F.RTariffCategoryKey2 = 1
		WHERE S.[FAMOOption] IS NULL AND S.RO_ID IS NOT NULL
		
		----option 3: RO_ID + Style
		UPDATE S SET
		     [FAMOManufacturer]     = F.[Manufacturer]
		    ,[FAMOCountryOfOrigin]  = F.[CountryOfOrigin]
		    ,[FAMOTariffCategory]   = F.[TariffCategory]
		    ,[FAMOOption]           = 13
		FROM #TB_Transfer_Trazabilidad  AS S
		INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.RO_ID = F.ManufactureID    AND S.[Key3] = F.[Key3] AND F.Proportion = 1 AND F.RTariffCategoryKey3 = 1
		WHERE S.[FAMOOption] IS NULL AND S.RO_ID IS NOT NULL
		
		----option 4: [Manufacturer] ANEXO FACTURACION DONDE NO SEA NULL
		-- UPDATE S SET
		--      [FAMOManufacturer] = S.[Manufacturer]
		--     ,[FAMOOption]       = 4
		-- FROM #TB_Transfer_Trazabilidad AS S
		-- WHERE S.[FAMOOption] IS NULL AND S.[Manufacturer] IS NOT NULL AND RO_ID IS NOT NULL
		-- -- WHERE S.[FAMOOption] IS NULL 
		
		----option 5: RO_ID
		UPDATE S SET
		     [FAMOManufacturer]     = F.[Manufacturer]
		    ,[FAMOCountryOfOrigin]  = F.[CountryOfOrigin]
		    ,[FAMOTariffCategory]   = F.[TariffCategory]
		    ,[FAMOOption]           = 15
		FROM #TB_Transfer_Trazabilidad  AS S
		INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.RO_ID = F.ManufactureID  AND F.RTariffCategory = 1   
		WHERE S.[FAMOOption] IS NULL AND S.RO_ID IS NOT NULL
					
					
					
					
					
					
		----option 1: RO_ID + Style + Color + Size
		UPDATE S SET
		     [FAMOManufacturer]     = F.[Manufacturer]
		    ,[FAMOCountryOfOrigin]  = F.[CountryOfOrigin]
		    ,[FAMOTariffCategory]   = F.[TariffCategory]
		    ,[FAMOOption]           = 21
		FROM #TB_Transfer_Trazabilidad  AS S
		INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.ManufactureID = F.ManufactureID    AND S.[Key1] = F.[Key1] AND F.Proportion = 1 AND F.RTariffCategoryKey1 = 1
		WHERE S.[FAMOOption] IS NULL --AND S.RO_ID IS NULL
		
		----option 2: RO_ID + Style + Color 
		UPDATE S SET
		     [FAMOManufacturer]     = F.[Manufacturer]
		    ,[FAMOCountryOfOrigin]  = F.[CountryOfOrigin]
		    ,[FAMOTariffCategory]   = F.[TariffCategory]
		    ,[FAMOOption]           = 22
		FROM #TB_Transfer_Trazabilidad  AS S
		INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.ManufactureID = F.ManufactureID    AND S.[Key2] = F.[Key2] AND F.Proportion = 1 AND F.RTariffCategoryKey2 = 1
		WHERE S.[FAMOOption] IS NULL --AND S.RO_ID IS NULL
		
		----option 3: RO_ID + Style
		UPDATE S SET
		     [FAMOManufacturer]     = F.[Manufacturer]
		    ,[FAMOCountryOfOrigin]  = F.[CountryOfOrigin]
		    ,[FAMOTariffCategory]   = F.[TariffCategory]
		    ,[FAMOOption]           = 23
		FROM #TB_Transfer_Trazabilidad  AS S
		INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.ManufactureID = F.ManufactureID    AND S.[Key3] = F.[Key3] AND F.Proportion = 1 AND F.RTariffCategoryKey3 = 1
		WHERE S.[FAMOOption] IS NULL --AND S.RO_ID IS NULL
		
		----option 4: [Manufacturer] ANEXO FACTURACION DONDE NO SEA NULL
		-- UPDATE S SET
		--      [FAMOManufacturer] = S.[Manufacturer]
		--     ,[FAMOOption]       = 4
		-- FROM #TB_Transfer_Trazabilidad AS S
		-- WHERE S.[FAMOOption] IS NULL AND S.[Manufacturer] IS NOT NULL AND RO_ID IS NOT NULL
		-- -- WHERE S.[FAMOOption] IS NULL 
		
		----option 5: RO_ID
		UPDATE S SET
		     [FAMOManufacturer]     = F.[Manufacturer]
		    ,[FAMOCountryOfOrigin]  = F.[CountryOfOrigin]
		    ,[FAMOTariffCategory]   = F.[TariffCategory]
		    ,[FAMOOption]           = 25
		FROM #TB_Transfer_Trazabilidad  AS S
		INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.ManufactureID = F.ManufactureID    AND F.RTariffCategory = 1 
		WHERE S.[FAMOOption] IS NULL --AND S.RO_ID IS NULL




		UPDATE S SET
			[TariffCategory]        = CASE
										WHEN S.[TypeQueryData]      = 1                                     THEN 'NO CAFTA RULE 9802'
										WHEN S.[FAMOTariffCategory] = 'CAFTA'                               THEN 'CAFTA'
										WHEN S.[FAMOTariffCategory] IN( 'NonCAFTA','Non CAFTA','NONCAFTA')  THEN 'NO CAFTA'
										WHEN S.[FAMOTariffCategory] IS NULL AND S.[SeasonName] = 'EMB FG'   THEN 'NO CAFTA'
										WHEN S.[FAMOTariffCategory] IS NULL AND S.[SeasonName] <> 'EMB FG'  THEN 'CAFTA'
									ELSE 'NO FOUND' END
		FROM #TB_Transfer_Trazabilidad AS S
		
		
		-------quitano los datos malos
		UPDATE S SET
			[FAMOCountryOfOrigin] = 'El Salvador'
		FROM #TB_Transfer_Trazabilidad AS S
		WHERE S.[FAMOCountryOfOrigin] IS NULL AND [TariffCategory] = 'CAFTA'
		
		
		UPDATE S SET
			[FAMOCountryOfOrigin] = 'El Salvador'
		FROM #TB_Transfer_Trazabilidad AS S
		WHERE [TariffCategory] = 'NO CAFTA RULE 9802' AND [Style] = 'BT300' AND [Manufacturer] = 'L2 BRANDS'
		
		
		UPDATE S SET
			[FAMOCountryOfOrigin] = 'India'
		FROM #TB_Transfer_Trazabilidad AS S
		WHERE [TariffCategory] = 'NO CAFTA' AND [Style] in('05PDT','10PDT','15PDT')  AND [Manufacturer] IS NULL
										
		UPDATE S SET
			[FAMOCountryOfOrigin] = 'Pakistan'
		FROM #TB_Transfer_Trazabilidad AS S
		WHERE [TariffCategory] = 'NO CAFTA' AND [RO] = '16131-32022-WHT-1'  AND [Manufacturer] IS NULL
		
		UPDATE S SET
			[FAMOCountryOfOrigin] = 'El Salvador'
		FROM #TB_Transfer_Trazabilidad AS S
		WHERE [TariffCategory] = 'NO CAFTA' AND [RO] = '16729-20058-MUH-1'  AND [Manufacturer] IS NULL
		
		UPDATE S SET
			[FAMOCountryOfOrigin] = 'Honduras'
		FROM #TB_Transfer_Trazabilidad AS S
		WHERE [TariffCategory] = 'NO CAFTA' AND [RO] = '16730-EZ100-LAB'  AND [Manufacturer] IS NULL
		
		UPDATE S SET
			[FAMOCountryOfOrigin] = 'Pakistan'
		FROM #TB_Transfer_Trazabilidad AS S
		WHERE [TariffCategory] = 'NO CAFTA' AND [RO] = '19084-144-SYH-1'  AND [Manufacturer] IS NULL
		
		UPDATE S SET
			[FAMOCountryOfOrigin] = 'Pakistan'
		FROM #TB_Transfer_Trazabilidad AS S
		WHERE [TariffCategory] = 'NO CAFTA' AND [RO] = '19547-31014-485-1'  AND [Manufacturer] IS NULL
		
		UPDATE S SET
			[FAMOCountryOfOrigin] = 'Guatemala'
			,[TariffCategory] = 'CAFTA'
		FROM #TB_Transfer_Trazabilidad AS S
		WHERE [TariffCategory] = 'NO CAFTA' AND [MO] = 'EO3640720-416'  AND [Manufacturer] IS NULL
										
		UPDATE S SET
			[FAMOCountryOfOrigin] = 'Philippines'
		FROM #TB_Transfer_Trazabilidad AS S
		WHERE [TariffCategory] = 'NO CAFTA' AND [MO] = 'EO3742877-ROY'  AND [Manufacturer] IS NULL
										
		UPDATE S SET
			[FAMOCountryOfOrigin] = 'China'
		FROM #TB_Transfer_Trazabilidad AS S
		WHERE [TariffCategory] = 'NO CAFTA' AND [PoNumber] = 'PO0830O-STOCK-LCA'  AND [Manufacturer] IS NULL
		
		UPDATE S SET
			[FAMOCountryOfOrigin] = 'Guatemala'
		FROM #TB_Transfer_Trazabilidad AS S
		WHERE [TariffCategory] = 'NO CAFTA' AND [ManufactureID] = 488559  AND [Manufacturer] IS NULL
										


------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------


-- SELECT COUNT(*) FROM #TB_Transfer_Trazabilidad WHERE [FAMOOption] IS NULL AND TypeData = 'Export'
-- SELECT * INTO appslca.dbo.TB_Transfer_MO_NOT_FOUND_FAMOSummary FROM (
-- SELECT DISTINCT RO_ID,RO,ManufactureID,MO FROM #TB_Transfer_Trazabilidad WHERE [FAMOOption] IS NULL AND TypeData = 'Export') as tb
-- SELECT * FROM #TB_Transfer_Trazabilidad WHERE [FAMOOption] IS NULL AND TypeData = 'Export'
-- select DISTINCT FAMOTariffCategory from #TB_Transfer_Trazabilidad
-- select  FAMOTariffCategory,COUNT(*) from #TB_Transfer_Trazabilidad GROUP BY FAMOTariffCategory
-- select  TariffCategory,COUNT(*) from #TB_Transfer_Trazabilidad GROUP BY TariffCategory


-- select * from #TB_Transfer_Trazabilidad where mo = 'SM250207PT1470-404-837'
-- select * from #TB_FAMO_SUMMARY where mo = 'SM250207PT1470-404-837'


-- -- select * from #TB_Transfer_Trazabilidad where FAMOTariffCategory = 'Fabric Duty'

-- -- select * from #TB_Transfer_Trazabilidad where FAMOTariffCategory IS NULL
-- RETURN
-- select   distinct ro_id,ManufactureID,ro,mo into #tb_prueba1 from #TB_Transfer_Trazabilidad where FAMOTariffCategory is null
-- select   distinct ro_id,ManufactureID,ro,mo into #tb_prueba2 from #TB_Transfer_Trazabilidad where FAMOTariffCategory is null

-- select *,1 as dat from #tb_prueba1
-- union all
-- select *,2 as dat from #tb_prueba2


UPDATE TTT SET
	CountryCode = COO.CountryCode
FROM #TB_Transfer_Trazabilidad AS TTT
LEFT JOIN
(
	SELECT DISTINCT
		CountryCode
		,CountryName
	FROM LCA.dbo.CountryOfOrigin AS COO WITH(NOLOCK)
) AS COO ON TTT.FAMOCountryOfOrigin = COO.CountryName


DROP TABLE IF EXISTS #tb_entry_kelly
SELECT DISTINCT
      ShipDate = CAST(
                        CONCAT(
                            LEFT([ShipDate], 4), '-', 
                            SUBSTRING([ShipDate], 5, 2), '-', 
                            RIGHT([ShipDate], 2)
                        ) 
                       AS date)
    , [Entry Date] = CAST([Entry Date] AS date)
INTO #tb_entry_kelly
FROM [AppsLCA].[dbo].[ImportExport_DutyKellyGlobal_All2024_202511] AS DAT WITH (NOLOCK)
WHERE ID <= 36385 

-- select * from #tb_entry_kelly

DROP TABLE IF EXISTS #TB_SHIPDATE_ENTRYDATE
SELECT
	 [Waybill]   = S.[Waybill]
	,[DAT]       = S.[DAT]
	,[ShipDate]  = IIF(S.[DAT] = 1, MIN([ShipDate]),MAX([ShipDate]))
INTO #TB_SHIPDATE_ENTRYDATE
FROM(
	SELECT 
		 [Waybill]      = A.Waybill
		,[DAT]          = iif(LEFT(A.[Waybill],3) IN( 'AIR','SMS'),1,0)
		,[ShipDate]     = B.[Entry Date]
	FROM #TB_Waybills_9802 AS A
	LEFT JOIN #tb_entry_kelly AS B ON CAST(A.ShipDate AS DATE) = CAST(B.ShipDate AS DATE)
) AS S
GROUP BY
	 [Waybill]
	,[DAT]



-----PONER ENTRY# Y ENTRYDATE (EXPORTDATE)
------CON LA TABLA NUEVA

UPDATE S SET
	 [Entry #]        	 = B.[Entry #]
	,[ExportDate]        = COALESCE(B.EntryDate ,S.OriginalExportDate)
	,[Month_ExportDate]  = MONTH(COALESCE(B.EntryDate ,S.OriginalExportDate))
	,[Year_ExportDate]   = YEAR(COALESCE(B.EntryDate ,S.OriginalExportDate))
    ,[InvoiceKelly]     = B.[Invoice #]
--SELECT *
FROM #TB_Transfer_Trazabilidad AS S
LEFT JOIN
(
    SELECT
        [Entry #]
        ,[EntryDate]
        ,[WayBill]
        ,[InvoiceLCA]
        ,STRING_AGG([Invoice #],',') WITHIN GROUP(ORDER BY [Invoice #]) AS [Invoice #] 
    FROM [AppsLCA].[dbo].[TB_Transfer_WaybillEntry] AS B WITH(NOLOCK)
    WHERE B.Status = 1 --AND Waybill = 'APP-20250311'
    GROUP BY
    [Entry #]
        ,[EntryDate]
        ,[WayBill]
        ,[InvoiceLCA]
) AS B ON B.Waybill = S.Waybill AND S.TariffCategory = B.InvoiceLCA

UPDATE S SET
	 [Entry #]        	 = B.[Entry #]
	,[ExportDate]        = COALESCE(B.EntryDate ,S.OriginalExportDate)
	,[Month_ExportDate]  = MONTH(COALESCE(B.EntryDate ,S.OriginalExportDate))
	,[Year_ExportDate]   = YEAR(COALESCE(B.EntryDate ,S.OriginalExportDate))
FROM #TB_Transfer_Trazabilidad AS S
LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_WaybillEntry] AS B WITH(NOLOCK) ON B.Waybill = S.Waybill
where s.[Entry #] IS NULL

UPDATE S SET
	 [ExportDate]        = COALESCE(B.ShipDate ,S.OriginalExportDate)
	,[Month_ExportDate]  = MONTH(COALESCE(B.ShipDate ,S.OriginalExportDate))
	,[Year_ExportDate]   = YEAR(COALESCE(B.ShipDate ,S.OriginalExportDate))
FROM #TB_Transfer_Trazabilidad AS S
LEFT JOIN #TB_SHIPDATE_ENTRYDATE AS B ON B.Waybill = S.Waybill
WHERE [ExportDate] IS NULL

-- SELECT * FROM AppsLCA.dbo.TB_Transfer_Export_Duty WHERE ShipDate IS NULL or ShipDate = ''
-- SELECT * FROM [AppsLCA].[dbo].[ImportExport_DutyKellyGlobal_All2024_202511] AS DAT WITH(NOLOCK)
-- WHERE [Entry Date] = '2025-09-19'
-- WHERE ShipDate IS NULL


UPDATE S SET
		 [301China_%]       = C.[301China_%]   
		,[Fenta_%]          = C.[Fenta_%]      
		,[Recip_%]          = C.[Recip_%]      
		-- ,[HTS_%]            = IIF(S.[TariffCategory] = 'CAFTA',0.0000, C.[HTS_%]        )
FROM #TB_Transfer_Trazabilidad AS S
INNER JOIN (
	SELECT 
		 [R]                    = A.[R]
		,[CountryOfOrigin]      = A.[CountryOfOrigin]
		,[ExportDate]           = A.[ExportDate]
		,[Type]                 = A.[ProductDivision]
		,[301China_%]           = COALESCE(TT.[301China]      ,TT2.[301China]      )
		,[Fenta_%]              = COALESCE(TT.[Fenta]         ,TT2.[Fenta]         )
		,[Recip_%]              = COALESCE(TT.[Recip]         ,TT2.[Recip]         )
		,[HTS_%]                = COALESCE(TT.[HTS]           ,TT2.[HTS]           )
		,[Tariff122_%]          = COALESCE(TT.[Tariff122]     ,TT2.[Tariff122]     )
		
	FROM #TB_Transfer_Trazabilidad AS A
	LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_TariffCOO] AS TT WITH(NOLOCK) ON TT.[Type] = A.[ProductDivision]
															AND TT.[CountryOfOrigin] = A.[FAMOCountryOfOrigin]
															AND (       A.[ExportDate] >= TT.[DateFrom]  
																	AND A.[ExportDate] <= TT.[DateTo] )
	LEFT JOIN (
				SELECT [id]              = S.[id]
				    ,[Type]            = S.[Type]
				    ,[DateFrom]        = S.[DateFrom]
				    ,[DateTo]          = S.[DateTo]
				    ,[COO]             = S.[COO]
				    ,[CountryOfOrigin] = S.[CountryOfOrigin]
				    ,[301China]        = S.[301China]
				    ,[Fenta]           = S.[Fenta]
				    ,[Recip]           = S.[Recip]
				    ,[HTS]             = S.[HTS]
				    ,[Tariff122]       = S.[Tariff122]
				    ,[Total]           = S.[Total]
				FROM [AppsLCA].[dbo].[TB_Transfer_TariffCOO] AS S WITH(NOLOCK)
				INNER JOIN (
				    SELECT [Type]            = D.[Type]
				        ,[COO]             = D.[COO]
				        ,[CountryOfOrigin] = D.[CountryOfOrigin]
				        ,[DateTo]          = MAX(D.[DateTo])
				    FROM [AppsLCA].[dbo].[TB_Transfer_TariffCOO] AS D WITH(NOLOCK)
				    GROUP BY D.[Type]
				        ,D.[COO]
				        ,D.[CountryOfOrigin]
				) AS B
				    ON B.[Type]            = S.[Type]
				    AND B.[COO]             = S.[COO]
				    AND B.[CountryOfOrigin] = S.[CountryOfOrigin]
				    AND B.[DateTo]          = S.[DateTo]
			) AS TT2  ON    TT2.[Type] = A.[ProductDivision]
										AND TT2.[CountryOfOrigin] = A.[FAMOCountryOfOrigin]
										AND        A.[ExportDate] > TT2.[DateFrom]  
										 
							
	WHERE A.[ExportDate] IS NOT NULL
	-- and TT.COUNTRYOFORIGIN IS NULL
	-- ORDER BY R
 ) AS C ON C.R = S.R

--  select * from #TB_Transfer_Trazabilidad where Waybill = '20240112-NONCAFTA-1'

-- SELECT * FROM [AppsLCA].[dbo].[TB_Transfer_TariffCOO]

UPDATE S SET
	-- [HTS_%]     = B.ADValoremRate 
	-- [HTS_%]        = IIF(S.[TariffCategory] = 'CAFTA',0.0000, B.ADValoremRate )
	[HTS_%]        = CASE 
						WHEN S.[TariffCategory] = 'CAFTA' THEN B.ADValoremRate
						WHEN B.ADValoremRate IS NULL AND S.[Style] = 'YBKT' THEN '0.075'
						ELSE B.ADValoremRate
						END
FROM #TB_Transfer_Trazabilidad AS S
LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_HTSTariff] AS B WITH(NOLOCK) ON B.SACKellyGlobal = S.US_HTSCode

UPDATE S SET
	[TotalFobValue]	= [Total Export Value] - (QtyExport * 0.25)
FROM #TB_Transfer_Trazabilidad AS S

UPDATE S SET
	 [301China_$]           = IIF(S.[TariffCategory] = 'NO CAFTA RULE 9802', S.[301China_%]     * S.[Export Value Added] , 0.0000)
	,[Fenta_$]              = IIF(S.[TariffCategory] = 'NO CAFTA RULE 9802', S.[Fenta_%]        * S.[Export Value Added] , 0.0000)
	,[Recip_$]              = IIF(S.[TariffCategory] = 'NO CAFTA RULE 9802', S.[Recip_%]        * S.[Export Value Added] , 0.0000)
	-- ,[HTS_$]                = IIF(S.[TariffCategory] = 'NO CAFTA RULE 9802', S.[HTS_%]          * S.[Export Value Added] , 0.0000)
	,[HTS_$]                = IIF(S.[TariffCategory] = 'NO CAFTA RULE 9802', S.[HTS_%]          * S.[Export Value Added] 
							, IIF(S.[TariffCategory] = 'NO CAFTA',S.[HTS_%] * [Total Export Value] - (QtyExport * 0.25),0.0000))
	
	,[TValue_301China_$]    = S.[301China_%]     * IIF(TariffCategory = 'NO CAFTA RULE 9802'
													,[Export Value Added]
													,IIF([Date] >= '2025-11-21' AND Waybill LIKE '%AIR%' AND CHARINDEX('FG',SeasonName) > 0
														,[Total Export Value] - (QtyExport * 0.64) 
														,[Total Export Value] - (QtyExport * 0.25)))
	,[TValue_Fenta_$]       = S.[Fenta_%]        * IIF(TariffCategory = 'NO CAFTA RULE 9802'
													,[Export Value Added]
													,IIF([Date] >= '2025-11-21' AND Waybill LIKE '%AIR%' AND CHARINDEX('FG',SeasonName) > 0
														,[Total Export Value] - (QtyExport * 0.64) 
														,[Total Export Value] - (QtyExport * 0.25)))
	,[TValue_Recip_$]       = S.[Recip_%]        * IIF(TariffCategory = 'NO CAFTA RULE 9802'
													,[Export Value Added]
													,IIF([Date] >= '2025-11-21' AND Waybill LIKE '%AIR%' AND CHARINDEX('FG',SeasonName) > 0
														,[Total Export Value] - (QtyExport * 0.64) 
														,[Total Export Value] - (QtyExport * 0.25)))
	,[TValue_HTS_$]         = S.[HTS_%]          * CASE 
														WHEN TariffCategory = 'NO CAFTA RULE 9802' THEN [Export Value Added]
														WHEN TariffCategory = 'CAFTA' THEN 0.0000
														WHEN TariffCategory = 'NO CAFTA' THEN 
																								IIF([Date] >= '2025-11-21' AND Waybill LIKE '%AIR%' AND CHARINDEX('FG',SeasonName) > 0
																								,[Total Export Value] - (QtyExport * 0.64) 
																								,[Total Export Value] - (QtyExport * 0.25))						  
													END
										
	-- ,[TValue_301China_$]    = S.[301China_%]     * S.[Total Export Value]
	-- ,[TValue_Fenta_$]       = S.[Fenta_%]        * S.[Total Export Value]
	-- ,[TValue_Recip_$]       = S.[Recip_%]        * S.[Total Export Value]
	-- ,[TValue_HTS_$]         = S.[HTS_%]          * S.[Total Export Value]
	
FROM #TB_Transfer_Trazabilidad AS S



UPDATE S SET
	 [Total_$]              =   ISNULL(S.[301China_$] ,0.0000)
								+   ISNULL(S.[Fenta_$] ,0.0000)
								+   ISNULL(S.[Recip_$] ,0.0000)
								+   ISNULL(S.[HTS_$],0.0000)
								
								
	-- ,[TValue_Total_$]       =   IIF( S.[ExportDate]< '2025-05-27'
	-- 								,ISNULL(S.[TValue_301China_$] ,0.0000)
	-- 							+   ISNULL(S.[TValue_Fenta_$] ,0.0000)
	-- 							+   ISNULL(S.[TValue_Recip_$] ,0.0000)
	-- 							+   ISNULL(S.[TValue_HTS_$],0.0000)
	-- 							,0.0000)
	,[TValue_Total_$]       =   
								 	ISNULL(S.[TValue_301China_$] ,0.0000)
								+   ISNULL(S.[TValue_Fenta_$] ,0.0000)
								+   ISNULL(S.[TValue_Recip_$] ,0.0000)
								+   ISNULL(S.[TValue_HTS_$],0.0000)
								
	,[TValue_Total_$2]      =  IIF( S.[ExportDate]< '2025-05-27'
								,0.0000
								,	ISNULL(S.[TValue_301China_$] ,0.0000)
								+   ISNULL(S.[TValue_Fenta_$] ,0.0000)
								+   ISNULL(S.[TValue_Recip_$] ,0.0000)
								+   ISNULL(S.[HTS_$],0.0000)
									)
FROM #TB_Transfer_Trazabilidad AS S


UPDATE S SET
	-- [T_Total_$]  = IIF( S.[ExportDate]< '2025-05-27'
	-- 						,S.[TValue_Total_$]	
	-- 						,S.[TValue_Total_$2]
	-- 				)
	[T_Total_$]  = S.[TValue_Total_$]	

FROM #TB_Transfer_Trazabilidad AS S

UPDATE S SET
	[Drawback]          = IIF(S.[TariffCategory] = 'NO CAFTA RULE 9802', [T_Total_$] - [Total_$],0.0000)
	,[FilterEntryDate]  = IIF([ExportDate]>=CAST('2025-05-27' AS DATE),1,0)
FROM #TB_Transfer_Trazabilidad AS S

UPDATE S SET
	 [Filter2024]          = iif(YEAR([ExportDate])=2024,1,0)
	,[Filter2024-202505]   = iif([ExportDate]>='2025-01-01 'AND [ExportDate]<'2025-05-27',1,0)
	,[Filter202505-Today]  = iif([ExportDate]>='2025-05-27',1,0)
FROM #TB_Transfer_Trazabilidad AS S

-- SELECT * FROM #TB_Transfer_Trazabilidad
-- WHERE 
-- 	(	[HTS_%] IS NULL 
-- 	OR [301China_%]    IS NULL
-- 	OR [Fenta_%]       IS NULL
-- 	OR [Recip_%]       IS NULL
-- 	OR [HTS_%]         IS NULL
-- 	)
-- 	AND [ExportDate] >= '2024-01-01'
	
-- SELECT count(distinct waybill),sum(QtyExport) FROM #TB_Transfer_Trazabilidad
-- WHERE ([HTS_%] IS NULL 
-- 	OR [301China_%]    IS NULL
-- 	OR [Fenta_%]       IS NULL
-- 	OR [Recip_%]       IS NULL
-- 	OR [HTS_%]         IS NULL)
-- AND [ExportDate] >= '2024-01-01'

-- SELECT DISTINCT [Waybill],[OriginalExportDate],[ExportDate]
-- FROM #TB_Transfer_Trazabilidad 
-- where ExportDate is null and [TypeData] = 'Export'
-- ORDER BY [OriginalExportDate]

-- SELECT * FROM #TB_Transfer_Trazabilidad 
-- where Waybill = '20240216-NONCAFTA'

-- SELECT * FROM #TB_SHIPDATE_ENTRYDATE
-- where Waybill = '20240216-NONCAFTA'
-- return

-- INSERT INTO [AppsLCA].[dbo].[TB_Transfer_ALL]

-- -----ver manufacturer
-- SELECT [Manufacturer],[TypeQueryData],COUNT(*) FROM #TB_Transfer_Trazabilidad
-- GROUP BY [Manufacturer],[TypeQueryData]
-- order by [Manufacturer],[TypeQueryData]


-- SELECT [Manufacturer],* FROM #TB_Transfer_Trazabilidad
-- WHERE [Manufacturer] IS NULL

-- SELECT [Manufacturer],* FROM #TB_Transfer_Trazabilidad
-- WHERE [RO] = '22453-HTA-STNV'


-- SELECT * FROM [AppsLCA].[dbo].[ImportExport_AnexoFacturacion]
-- WHERE [RO] = '22453-HTA-STNV'

-- SELECT * FROM [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Summary]
-- WHERE MO = '22453-HTA-STNV'

-- HENAN J&F HEADWEAR CO., LTD


-- ---para cuadrar manufacturere league ltda
-- SELECT [Manufacturer],COUNT(*) FROM #TB_Transfer_Trazabilidad
-- WHERE 
-- 	 SeasonName IS NULL OR SeasonName <> 'EMB FG'
-- GROUP BY [Manufacturer]
-- order by [Manufacturer]

-- SELECT [Manufacturer],COUNT(*) FROM #TB_Transfer_Trazabilidad
-- WHERE (SeasonName IS NULL AND RO_ID IS  NULL) OR SeasonName <> 'EMB FG'
-- GROUP BY [Manufacturer]
-- order by [Manufacturer]

-- SELECT * FROM #TB_Transfer_Trazabilidad
-- WHERE (SeasonName IS NULL AND RO_ID IS  NULL) OR SeasonName <> 'EMB FG'
-- order by [Manufacturer]

-- SELECT [Manufacturer],* FROM #TB_Transfer_Trazabilidad
-- WHERE 
-- 	 SeasonName IS NULL OR SeasonName <> 'EMB FG'
-- -- GROUP BY [Manufacturer]
-- -- order by [Manufacturer]



-- SELECT *INTO [AppsLCA].[dbo].[TB_Transfer_Validation_Test_1] FROM #TB_Transfer_Trazabilidad WHERE [UnitValueAdded] is null AND [TypeData] = 'Export'

-- SELECT * FROM [AppsLCA].[dbo].[TB_Transfer_Validation_Test_1]

-- SELECT *FROM #TB_Transfer_Trazabilidad WHERE [UnitValueAdded] is null AND [TypeData] = 'Export'
-- SELECT COUNT(*) FROM #TB_Transfer_Trazabilidad WHERE [UnitValueAdded] is null AND [TypeData] = 'Export'


UPDATE S SET
	[FinalComment]  =   CASE 
							WHEN [TypeData] = 'Import' THEN 'OK'
							WHEN [Original_Price]  IS NULL THEN 'No Total Price'
							WHEN [HTS_%] IS NULL THEN 'No HTS%'
							WHEN [301China_%] IS NULL OR [Fenta_%] IS NULL OR [Recip_%] IS NULL THEN 'No China%/Fenta%/Recip%'
						ELSE 'OK'
						END
FROM #TB_Transfer_Trazabilidad AS S



-- SELECT [FinalComment],COUNT(*) as rowsdata, sum(ISNULL(QtyExport,QTYIMPORT)) AS UNITS FROM #TB_Transfer_Trazabilidad  GROUP BY [FinalComment]

-- SELECT TariffCategory AS TariffCategory2, CountryOfOrigin AS CountryOfOrigin2,FAMOCountryOfOrigin AS FAMOCountryOfOrigin2,*FROM #TB_Transfer_Trazabilidad 
-- WHERE [301China_%] IS NULL OR [Fenta_%] IS NULL OR [Recip_%] IS NULL 
-- ORDER BY TariffCategory

-- SELECT 
-- 	[Original_Price]
-- 	,[TypeQueryData]
-- 	,[QtyExport]
-- 	,[Original_IDExport]
-- 	,[Waybill]
-- 	,[TariffCategory]
-- FROM #TB_Transfer_Trazabilidad 
-- WHERE [FinalComment] = 'No Total Price'
-- ORDER BY TariffCategory

-- select distinct Waybill 
-- FROM #TB_Transfer_Trazabilidad 
-- WHERE [FinalComment] = 'No Total Price'

-- select * from #TB_Transfer_Trazabilidad WHERE [Entry #] IS NOT NULL

-- RETURN


-- SELECT * FROM #TB_Transfer_Trazabilidad
-- WHERE [Entry #] IN ('BHE04298259')
-- AND Waybill = 'AIR-APP-20250815' AND TariffCategory = 'NO CAFTA' AND CountryOfOrigin = 'India'
-- RETURN


-- SELECT *FROM #TB_Transfer_Trazabilidad 
-- -- WHERE [Waybill] = 'SM20250910'
-- WHERE [HTS_%] IS NULL

-- SELECT COUNT(*) FROM #TB_Transfer_Trazabilidad WHERE [FinalComment] <> 'OK'
-- SELECT SUM(QtyExport) FROM #TB_Transfer_Trazabilidad WHERE [FinalComment] <> 'OK'
-- SELECT * FROM #TB_Transfer_Trazabilidad WHERE [FinalComment] <> 'OK'

-- SELECT FAMOCountryOfOrigin,TariffCategory,*FROM #TB_Transfer_Trazabilidad          WHERE [HTS_%] IS NULL AND [TypeData] = 'Export' AND [Style] = 'AC275' --AND [Waybill] = 'AIR-APP-20250701'
-- SELECT COUNT(*)FROM #TB_Transfer_Trazabilidad          WHERE [HTS_%] IS NULL AND [TypeData] = 'Export' --AND [Style] = 'LCST50'
-- SELECT DISTINCT [Style],[SeasonName],[US_HTSCode] FROM #TB_Transfer_Trazabilidad          WHERE [HTS_%] IS NULL AND [TypeData] = 'Export' ORDER BY SeasonName,Style

-- -- SELECT DISTINCT [Style],[Color],[SeasonName] FROM #TB_Transfer_Trazabilidad          WHERE [HTS_%] IS NULL AND [TypeData] = 'Export' ORDER BY SeasonName,Style,Color
-- SELECT COUNT(*) FROM (SELECT DISTINCT [Style],[SeasonName] FROM #TB_Transfer_Trazabilidad          WHERE [HTS_%] IS NULL AND [TypeData] = 'Export' ) AS TB

-- SELECT *, IIF(TariffCategory = '9802',[Export Value Added],[Total Export Value] - (QtyExport * 0.25)) FROM #TB_Transfer_Trazabilidad
-- WHERE [Entry #] = 'BHE04290421'
-- RETURN

DROP TABLE [AppsLCA].[dbo].[TB_Transfer_Validation_allExport]

SELECT *,IIF(TariffCategory = 'NO CAFTA RULE 9802'
			,[Export Value Added]
			,IIF([Date] >= '2025-11-21' AND Waybill LIKE '%AIR%' AND CHARINDEX('FG',SeasonName) > 0
				,[Total Export Value] - (QtyExport * 0.64) 
				,[Total Export Value] - (QtyExport * 0.25))) AS KellyReport
,CASE 
	WHEN LEN(InvoiceKelly) - LEN(REPLACE(InvoiceKelly, ',', '')) = 2 THEN 3
	WHEN LEN(InvoiceKelly) - LEN(REPLACE(InvoiceKelly, ',', '')) = 1 THEN 2
	WHEN LEN(InvoiceKelly) - LEN(REPLACE(InvoiceKelly, ',', '')) = 0 THEN 1
 END AS CountInvoice
INTO [AppsLCA].[dbo].[TB_Transfer_Validation_allExport]
FROM #TB_Transfer_Trazabilidad 
WHERE Waybill NOT IN ('APP-20251205','HW-20251205','APP-20251209','HW-20251209')
-- where [Entry #] Like '%BHE04309999%'
-- WHERE [Entry #] = 'BHE04254518'
order by R
RETURN

SELECT * 
FROM [AppsLCA].[dbo].[TB_Transfer_Validation_allExport]
WHERE [Entry #] IN ('BHE04312779') AND TariffCategory = 'NO CAFTA' AND Waybill = 'APP-20251118'
RETURN 
select 
	[Entry #]
	,Waybill
	,TariffCategory 
	,[301China_%]
	,[Fenta_%]
	,[Recip_%]
	,[HTS_%]	
	,SUM(TotalFobValue)
	,SUM([Export Value Added])
from [AppsLCA].[dbo].[TB_Transfer_Validation_allExport]
WHERE [Entry #] = 'BHE04309684'
group by
[Entry #]
	,Waybill
	,TariffCategory 
	,[301China_%]
	,[Fenta_%]
	,[Recip_%]
	,[HTS_%]

SELECT DISTINCT Waybill, TypeQueryData FROM [AppsLCA].[dbo].[TB_Transfer_Validation_allExport] 
WHERE Waybill IN (SELECT DISTINCT Waybill FROM AppsLCA.dbo.TB_Transfer_Waybill_Void)
AND Waybill LIKE '%2025%'

SELECT 
	Waybill
	,SUM([Total Export Value]) as Total
FROM [AppsLCA].[dbo].[TB_Transfer_Validation_allExport] 
WHERE ExportDate >= '2025-01-01'
GROUP BY
	Waybill
ORDER BY
	Waybill

SELECT
	Waybill
	,SUM([TotalPrice]) as Total
FROM AppsLCA.dbo.TB_Transfer_CuadreCI_KellyGlobal
WHERE EntryDate >= '2025-01-01'
GROUP BY
	Waybill
ORDER BY
	Waybill

-- TRUNCATE TABLE [AppsLCA].[dbo].[TB_Transfer_Validation_allExport]

-- INSERT INTO [AppsLCA].[dbo].[TB_Transfer_Validation_allExport]
-- UPDATE N SET
-- 	Container = TBC.ContainerNumber
-- FROM #TB_Transfer_Trazabilidad AS N
-- INNER JOIN
-- (
-- SELECT DISTINCT TTT.WayBill, TTT.ExportDate, TBC.ContainerNumber
-- FROM #TB_Transfer_Trazabilidad AS TTT
-- INNER JOIN
-- (
-- 	SELECT DISTINCT
-- 		SH.WayBill
-- 		,SHC.ContainerNumber
-- 	FROM LCA.dbo.Shipments AS SH WITH(NOLOCK)
-- 	INNER JOIN LCA.dbo.ShippingContainers AS SHC WITH(NOLOCK) ON SH.ShippingContainerID = SHC.ShippingContainerID AND SH.WayBill NOT IN 
-- 	(
-- 	'AIR20240424'
-- 	,'AIR20240424-NONCAFTA'
-- 	,'AIR-HW20240424-NONCAFTA'
-- 	,'AIR-APP-20251029'
-- 	,'AIR-HW-20251029'
-- 	,'AIR-APP-20251031'
-- 	,'AIR-HW-20251031'
-- 	,'AIR-HW-20251031-1'
-- 	,'APP-20251031'
-- 	,'BND-20251031'
-- 	,'HW-20251031'
-- 	)
-- 	AND SH.WayBill NOT LIKE '%AIR%'
-- 	AND SH.StatusID = 85
-- ) AS TBC ON TTT.Waybill = TBC.WayBill
-- ) AS TBC ON N.Waybill = TBC.Waybill

-- SELECT DISTINCT ExportDate, Waybill, Container 
-- FROM #TB_Transfer_Trazabilidad 
-- WHERE WayBill NOT IN 
-- 	(
-- 	'AIR20240424'
-- 	,'AIR20240424-NONCAFTA'
-- 	,'AIR-HW20240424-NONCAFTA'
-- 	,'AIR-APP-20251029'
-- 	,'AIR-HW-20251029'
-- 	,'AIR-APP-20251031'
-- 	,'AIR-HW-20251031'
-- 	,'AIR-HW-20251031-1'
-- 	,'APP-20251031'
-- 	,'BND-20251031'
-- 	,'HW-20251031'
-- 	)

-- ORDER BY ExportDate desc, Waybill
END

SELECT * FROM TB_Transfer_WaybillEntry WHERE Waybill like '%APP-20250311%'