
 DROP TABLE IF EXISTS #TB_TEST_MO_SBI
 DROP TABLE IF EXISTS #TB_TEST_MO_BD
 DROP TABLE IF EXISTS #TB_TEST_ANEXOFACTURACION


  SELECT
    [ManufactureID]
   ,[MO]
   ,[Waybill]
   ,[ProductDivision]
   ,[Qty]        
   ,[Total_Receiving_Cost] 
   ,[Total_UnitFreightCost_Ponderado]  = CAST(NULL AS NUMERIC(18,4))
   ,[RO_ID]
  INTO #TB_TEST_ANEXOFACTURACION
  FROM [AppsLCA].[dbo].[ImportExport_AnexoFacturacion] with(nolock)
  WHERE Year(ShipDate) = 2026 
   and month(shipdate) = 7
   -- and [ProductDivision] = 'Headwear'
   
  
  
   UPDATE T SET
        --  T.[UnitFreightCost_Ponderado]       = IIF(
        --                                             FAMF2.[MAKE] > 0
        --                                         AND FAMF2.[Contracts_FreightPrice] IS NOT NULL
        --                                         ,CONVERT(NUMERIC(18,4), ROUND(FAMF2.[Contracts_FreightPrice] / FAMF2.[MAKE], 4))
        --                                         ,0
        --                                     )
        -- ,
                T.[Total_UnitFreightCost_Ponderado] = T.[Qty] * IIF(
                                                                    FAMF2.[MAKE] > 0
                                                                AND FAMF2.[Contracts_FreightPrice] IS NOT NULL
                                                                ,CONVERT(NUMERIC(18,4), ROUND(FAMF2.[Contracts_FreightPrice] / FAMF2.[MAKE], 4))
                                                                ,0
                                                            )
      FROM #TB_TEST_ANEXOFACTURACION AS T
      LEFT JOIN [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Materials] AS FAMF2 WITH(NOLOCK) ON T.[RO_ID] = FAMF2.[ManufactureID]
    
      
   
  SELECT 
    [ManufactureID]
   ,[MO]
   ,[Waybill]
   ,[StyleDivision]
   ,[TypeData]
   ,[Quantity]         = SUM([Quantity])
   ,[Contracts]        = SUM([Contracts]) 
   ,[UnitCost]         = SUM([Contracts]) / SUM([Quantity])
  INTO #TB_TEST_MO_SBI
  FROM [AppsLCA].[dbo].[TB_CierreConta_AllDataSTD] with(nolock)
  WHERE [YearData] = 2026 
  and [MonthData] = 7
  -- and [StyleDivision] = 'Headwear'
  group by 
  [ManufactureID]
   ,[MO]
   ,[Waybill]
   ,[StyleDivision]
   ,[TypeData]
  
  
  
  SELECT
    [ManufactureID]
   ,[MO]
   ,[Waybill]
   ,[StyleDivision]     = [ProductDivision]
   ,[Quantity]         = SUM([Qty])
   ,[Contracts]        = SUM([Total_Receiving_Cost] + ISNULL([Total_UnitFreightCost_Ponderado],0)) 
   ,[UnitCost]         = SUM([Total_Receiving_Cost] + ISNULL([Total_UnitFreightCost_Ponderado],0)) / SUM([Qty])
  INTO #TB_TEST_MO_BD
  -- FROM [AppsLCA].[dbo].[ImportExport_AnexoFacturacion] with(nolock)
  FROM #TB_TEST_ANEXOFACTURACION
  -- WHERE Year(ShipDate) = 2026 
  --  and month(shipdate) = 7
  --  and [ProductDivision] = 'Headwear'
  GROUP BY 
   [ManufactureID]
   ,[MO]
   ,[Waybill]
   ,[ProductDivision]
  
  
  
  SELECT 
    [SBI_ManufactureID]    = SBI.[ManufactureID]                    
   ,[SBI_MO]               = SBI.[MO]        
   ,[SBI_Waybill]          = SBI.[Waybill]    
   ,[TypeData]             = SBI.[TypeData]
   ,[SBI_StyleDivision]    = SBI.[StyleDivision]                        
   ,[SBI_Quantity]         = SBI.[Quantity]                             
   ,[SBI_Contracts]        = SBI.[Contracts]                            
   ,[SBI_UnitCost]         = SBI.[UnitCost]                             
   
   ,[BD_ManufactureID]     = BD.[ManufactureID]                    
   ,[BD_MO]                = BD.[MO]        
   ,[BD_Waybill]           = BD.[Waybill]            
   ,[BD_StyleDivision]     = BD.[StyleDivision]                        
   ,[BD_Quantity]          = BD.[Quantity]                             
   ,[BD_ReceivingCost]     = BD.[Contracts]                            
   ,[BD_UnitCost]          = BD.[UnitCost]                             
   
   ,[DIFF_Quantity]        = ISNULL(SBI.[Quantity],0) - ISNULL(BD.[Quantity],0)
   ,[DIFF_UnitCost]        = ISNULL(SBI.[UnitCost],0) - ISNULL(BD.[UnitCost],0)
   ,[DIFF_TotalCost]       = ISNULL(SBI.[Contracts],0) - ISNULL(BD.[Contracts],0)
   
  FROM        #TB_TEST_MO_SBI   AS SBI
  FULL JOIN   #TB_TEST_MO_BD    AS BD   ON SBI.ManufactureID = BD.ManufactureID AND SBI.WayBill = BD.Waybill
  WHERE ISNULL(SBI.[Contracts],0) - ISNULL(BD.[Contracts],0) >= 1 AND SBI.[TypeData] = 'SEMI'
  
  -- SELECT 
  --  [Contracts]   =   ROUND(TB_MO_Mat.[Contracts]     /IIF(TB_MO_Mat.Make=0, 1,TB_MO_Mat.Make) ,4)
  -- ,[ContractsRecCost]   =   ROUND(TB_MO_Mat.[Contracts_PurchasePrice]     /IIF(TB_MO_Mat.Make=0, 1,TB_MO_Mat.Make) ,4)
  -- ,* 
  -- FROM [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Materials] as TB_MO_Mat with(nolock)
  -- where mo = 'EO5795070-416'

  SELECT 
    AF.ID
    ,AF.Waybill
    ,af.ShipDate
    ,AF.MO
    ,AF.ManufactureID 
    ,AF.RO
    ,AF.RO_ID
    ,RO_Cost = CAST(NULL AS VARCHAR(100))
    ,ROID_Cost = CAST(NULL AS INT)
  FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK)
  WHERE ManufactureID = 978897 AND MONTH(ShipDate) = 7

