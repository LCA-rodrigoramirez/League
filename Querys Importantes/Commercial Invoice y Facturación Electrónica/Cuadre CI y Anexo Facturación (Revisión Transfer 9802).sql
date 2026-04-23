USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_Transfer_Cuadre_CI_9802_HW-20251031]    Script Date: 16/02/2026 08:07:26 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- ALTER   PROCEDURE [dbo].[SP_Transfer_Cuadre_CI_9802_HW-20251031] 
       
-- AS
BEGIN


DROP TABLE IF EXISTS #TB_Waybills_9802
DROP TABLE IF EXISTS #TB_Dat_Invoice
DROP TABLE IF EXISTS #TB_Dat_Transfer9802
DROP TABLE IF EXISTS #TB_CI_NONCAFTA
DROP TABLE IF EXISTS #TB_CI_ONLY9802
DROP TABLE IF EXISTS #TB_VAL_CI_DATA
DROP TABLE IF EXISTS #TB_VAL_CI_PIV

    
    -- SELECT DISTINCT  E.[Waybill]    FROM [AppsLCA].[dbo].[TB_Transfer_Export_Duty] AS E WITH(NOLOCK)
    -- SELECT count(DISTINCT  E.[Waybill])    FROM [AppsLCA].[dbo].[TB_Transfer_Export_Duty] AS E WITH(NOLOCK)
    
    SELECT DISTINCT 
        E.[Waybill] 
    INTO #TB_Waybills_9802
    -- FROM [AppsLCA].[dbo].[TB_Transfer_Export_Duty] AS E WITH(NOLOCK)
    FROM [AppsLCA].[dbo].[ImportExport_AnexoFacturacion] AS E WITH(NOLOCK)
    WHERE E.[Waybill] IN(
        'AIR-APP-20260422-1'
        
        -- ,
        -- 'AIR-HW-20250821'
        -- ,
        -- 'APP-20251107'
        
        )



    ---------------------INFORMACION FACTURACION-------------------------------------
         
        SELECT * INTO #TB_Dat_Invoice FROM(
         SELECT 
             [ShipDate]             = AF.[ShipDate]
            ,[Waybill]              = AF.[Waybill]
            ,[StyleNumber]          = AF.[StyleNumber]
            ,[US_HTSCode]           =   case 
        								    when AF.[ProductDivision] = 'Headwear' AND lmn.US_HTSCode is not null then lmn.US_HTSCode
        								    when AF.[ProductDivision] = 'Headwear' AND lmn.US_HTSCode is null and lmn.CA_HTSCode is not null then lmn.CA_HTSCode
        								    else COALESCE(HT.US_HTSCode,AF.SAC)
                                        end 
            ,[Manufacturer]         = COALESCE(B.[Manufacturer2],AF.[Manufacturer])
            ,[UnitPrice]            = CAST(AF.[Total$] / NULLIF(AF.[Qty],0) AS DECIMAL(18,2))
            ,[Quantity]             = SUM(AF.[Qty])
            ,[TotalPrice]           = SUM(AF.[Total$])
            -- ,[Boxes]                = NULL
            ,[CountryOfOrigin]      = AF.[CountryOfOrigin]
            ,[TypeData]             = 'Dat_Invoice'  
         FROM [AppsLCA].[dbo].[ImportExport_AnexoFacturacion] AS AF WITH(NOLOCK)
         INNER JOIN #TB_Waybills_9802 AS WB ON AF.Waybill = WB.Waybill
         LEFT JOIN (SELECT 
                         [ID]               = F.ID
                        ,[Manufacturer]     = F.Manufacturer
                        ,[Manufacturer2]    = TK.Manufacturer
                    FROM [AppsLCA].[dbo].[TB_Transfer_Kardex_Duty]  AS TK WITH(NOLOCK)
                    INNER JOIN #TB_Waybills_9802 AS WB ON TK.Waybill = WB.Waybill
                    LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_Export_Duty]    AS E    WITH(NOLOCK)  ON TK.IDExport = E.ID
                    LEFT JOIN [AppsLCA].[dbo].[ImportExport_AnexoFacturacion]  AS F WITH(NOLOCK) ON F.ID = E.ID
                    ) AS B ON B.ID = AF.ID
         LEFT  JOIN (SELECT * FROM 
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
        								                                    order by Col.ColorName, CL.ComponentName)
        										    FROM        [LCA].[dbo].[RawMaterials]  AS RW   WITH(NOLOCK)
        											left join   lca.dbo.Colors              AS COL  WITH(NOLOCK) on RW.ColorID = Col.ColorID
        											left join   lca.dbo.ComponentLibrary    AS CL   WITH(NOLOCK) on RW.ComponentID = CL.ComponentID and CL.ComponentCategoryID=11
        											left outer join lca.dbo.DropDownValues DRD with (nolock)
        												on RW.HTSCodeID = DRD.DropDownValueID
        											where Cl.ComponentName is not null and Col.ColorName is not null
        										 ) abc123 where Cuenta=1
        								) fgh
        						) lmn	on AF.StyleNumber = lmn.Style and AF.StyleColor=lmn.Color
            LEFT JOIN [LCA].[dbo].[ManufactureOrders]   AS MO WITH(NOLOCK) ON AF.RO_ID = MO.ManufactureID
            LEFT JOIN [LCA].[dbo].[OrderItems]          AS OI WITH(NOLOCK) ON MO.FirstOrderItemID = OI.OrderItemID
            LEFT JOIN [LCA].[dbo].[Styles]              AS ST WITH(NOLOCK) ON OI.StyleID = ST.StyleID
            LEFT JOIN [LCA].[dbo].[HTSStyleCodes]       AS HT WITH(NOLOCK) ON HT.HTSStyleCodeID = ST.HTSStyleCodeID
        --   WHERE Waybill ='HW-20250410'
          GROUP BY
             AF.[ShipDate]
            ,AF.[Waybill]
            ,AF.[StyleNumber]
            ,COALESCE(B.[Manufacturer2],AF.[Manufacturer])
            -- ,AF.[Manufacturer]
            ,CAST(AF.[Total$] / NULLIF(AF.[Qty],0) AS DECIMAL(18,2))
            ,AF.[CountryOfOrigin]
            ,case 
        								    when AF.[ProductDivision] = 'Headwear' AND lmn.US_HTSCode is not null then lmn.US_HTSCode
        								    when AF.[ProductDivision] = 'Headwear' AND lmn.US_HTSCode is null and lmn.CA_HTSCode is not null then lmn.CA_HTSCode
        								    else COALESCE(HT.US_HTSCode,AF.SAC)
                                        end 
         ) AS TB 
    
    ---------------------INFORMACION FACTURACION-------------------------------------
 
 
    ---------------------INFORMACION CORRECTA TRANSFER-------------------------------------
 
        SELECT * INTO #TB_Dat_Transfer9802 FROM(
         SELECT 
             [ShipDate]             = TK.[FechaMovimiento]
            ,[Waybill]              = TK.[Waybill]
            ,[StyleNumber]          = TK.[StyleNumber]
            ,[US_HTSCode]           =  case 
        								    when tk.[ProductDivision] = 'Headwear' AND lmn.US_HTSCode is not null then lmn.US_HTSCode
        								    when TK.[ProductDivision] = 'Headwear' AND lmn.US_HTSCode is null and lmn.CA_HTSCode is not null then lmn.CA_HTSCode
        								    else COALESCE(HT.US_HTSCode,E.SAC)
                                        end 
            ,[Manufacturer]         = TK.[Manufacturer]
            ,[UnitPrice]            = CAST(E.[Total$] / NULLIF(TK.[QtyExport],0) AS DECIMAL(18,2))
            ,[Quantity]             = SUM(TK.[QtyExport])
            ,[TotalPrice]           = SUM(E.[Total$])
            -- ,[Boxes]                = NULL
            ,[CountryOfOrigin]      = TK.[CountryOfOrigin]
            ,[TypeData]             = 'Dat_Transfer'
            -- ,[IDExport]             = TK.[IDExport]
            -- ,[IDImport]             = TK.[IDImport]
            -- ,[IDKardex]             = TK.[IDKardex]
            -- ,[RO_ID]                = TK.[RO_ID]
            -- ,[RO]                   = TK.[RO]
         FROM [AppsLCA].[dbo].[TB_Transfer_Kardex_Duty]         AS TK   WITH(NOLOCK) 
         INNER JOIN #TB_Waybills_9802 AS WB ON TK.Waybill = WB.Waybill
         LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_Export_Duty]    AS E    WITH(NOLOCK)  ON TK.IDExport = E.ID
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
        								                                    order by Col.ColorName, CL.ComponentName)
        										    FROM        [LCA].[dbo].[RawMaterials]  AS RW   WITH(NOLOCK)
        											left join   lca.dbo.Colors              AS COL  WITH(NOLOCK) on RW.ColorID = Col.ColorID
        											left join   lca.dbo.ComponentLibrary    AS CL   WITH(NOLOCK) on RW.ComponentID = CL.ComponentID and CL.ComponentCategoryID=11
        											left outer join lca.dbo.DropDownValues DRD with (nolock)
        												on RW.HTSCodeID = DRD.DropDownValueID
        											where Cl.ComponentName is not null and Col.ColorName is not null
        										 ) abc123 where Cuenta=1
        								) fgh
        						) lmn	on TK.StyleNumber = lmn.Style and TK.Color=lmn.Color
        LEFT JOIN [LCA].[dbo].[ManufactureOrders]   AS MO WITH(NOLOCK) ON TK.RO_ID = MO.ManufactureID
        LEFT JOIN [LCA].[dbo].[OrderItems]          AS OI WITH(NOLOCK) ON MO.FirstOrderItemID = OI.OrderItemID
        LEFT JOIN [LCA].[dbo].[Styles]              AS ST WITH(NOLOCK) ON OI.StyleID = ST.StyleID
        LEFT JOIN [LCA].[dbo].[HTSStyleCodes]       AS HT WITH(NOLOCK) ON HT.HTSStyleCodeID = ST.HTSStyleCodeID
            --  WHERE TK.Waybill ='HW-20250410'
         GROUP BY
             TK.[FechaMovimiento]
            ,TK.[Waybill]
            ,TK.[StyleNumber]
            ,TK.[Manufacturer]
            ,CAST(E.[Total$] / NULLIF(TK.[QtyExport],0) AS DECIMAL(18,2))
            -- ,TK.[QtyExport]
            -- ,E.[Total$]
            ,TK.[CountryOfOrigin]
            ,case 
        								    when tk.[ProductDivision] = 'Headwear' AND lmn.US_HTSCode is not null then lmn.US_HTSCode
        								    when TK.[ProductDivision] = 'Headwear' AND lmn.US_HTSCode is null and lmn.CA_HTSCode is not null then lmn.CA_HTSCode
        								    else COALESCE(HT.US_HTSCode,E.SAC)
                                        end 
         ) AS TB 
    ---------------------INFORMACION CORRECTA TRANSFER-------------------------------------
 
 
 
    ---------------------INFORMACION COMERCIAL INVOICE ANTES DE 9802-------------------------------------
        SELECT
        	 [ShipDate]             = CI.[ShipDate]
        	,[Waybill]              = CI.[Waybill]
        	,[Stylenumber]          = CI.[Stylenumber]
        	,[US_HTSCode]           = COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
        	,[Manufacturer]         = CI.[Manufacturer]
        	,[UnitPrice]            = CI.[Price]
        	,[Quantity]             = SUM(CI.[Quantity])
        	,[TotalPrice]           = SUM(CI.[TotalPrice])
        	-- ,[Boxes]                = CI.[Boxes]
        	,[CountryOfOrigin]      = CI.[CountryOfOrigin]
        	,[TypeData]             = CASE
        	                            WHEN CAST(CI.[ShipDate] AS DATE) < '2025-05-01'  AND CI.[Orden] IN (1,2,3) THEN 'CI_Cafta'
        	                            WHEN CAST(CI.[ShipDate] AS DATE) < '2025-05-01'  AND CI.[Orden] = 4 THEN 'CI_NonCafta'
        	                            WHEN CAST(CI.[ShipDate] AS DATE) >= '2025-05-01' AND CI.[Orden] = 1 THEN 'CI_Cafta'
        	                            WHEN CAST(CI.[ShipDate] AS DATE) >= '2025-05-01' AND CI.[Orden] = 2 THEN 'CI_NonCafta'
        	                            WHEN CAST(CI.[ShipDate] AS DATE) >= '2025-05-01' AND CI.[Orden] = 3 THEN 'CI_9802'
        	                            ELSE 'UNKNOWN' END
        INTO #TB_CI_NONCAFTA
        FROM [192.168.1.93].[AppsLCA].[dbo].[CI_import_export_CommercialInvoice] AS CI WITH(NOLOCK) 
        INNER JOIN #TB_Waybills_9802 AS WB ON CI.Waybill = WB.Waybill
        GROUP BY
            CI.[ShipDate]
            ,CI.[Waybill]
            ,CI.[Stylenumber]
            ,COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
            ,CI.[Manufacturer]
            ,CI.[Price]
            -- ,CI.[Quantity]
            -- ,CI.[TotalPrice]
            ,CI.[CountryOfOrigin]
            ,CASE
        	                            WHEN CAST(CI.[ShipDate] AS DATE) < '2025-05-01'  AND CI.[Orden] IN (1,2,3) THEN 'CI_Cafta'
        	                            WHEN CAST(CI.[ShipDate] AS DATE) < '2025-05-01'  AND CI.[Orden] = 4 THEN 'CI_NonCafta'
        	                            WHEN CAST(CI.[ShipDate] AS DATE) >= '2025-05-01' AND CI.[Orden] = 1 THEN 'CI_Cafta'
        	                            WHEN CAST(CI.[ShipDate] AS DATE) >= '2025-05-01' AND CI.[Orden] = 2 THEN 'CI_NonCafta'
        	                            WHEN CAST(CI.[ShipDate] AS DATE) >= '2025-05-01' AND CI.[Orden] = 3 THEN 'CI_9802'
        	                            ELSE 'UNKNOWN' END
    ---------------------INFORMACION COMERCIAL INVOICE ANTES DE 9802-------------------------------------

    ---------------------INFORMACION COMERCIAL INVOICE 9802-------------------------------------
        SELECT 
             [ShipDate]             = CI.[ShipDate]
        	,[Waybill]              = CI.[Waybill]
        	,[Stylenumber]          = CI.[Stylenumber]
        	,[US_HTSCode]           = COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
        	,[Manufacturer]         = CI.[Manufacturer]
        	,[UnitPrice]            = CI.[Price]
        	,[Quantity]             = SUM(CI.[Quantity])
        	,[TotalPrice]           = SUM(CI.[TotalPrice])
        	-- ,[Boxes]                = CI.[Boxes]
        	,[CountryOfOrigin]      = CI.[CountryOfOrigin]
        	,[TypeData]             = 'CI_9802'
        INTO #TB_CI_ONLY9802
       FROM [192.168.1.93].[AppsLCA].[dbo].[CI_import_export_DeclarationExport] AS CI WITH(NOLOCK) 
        INNER JOIN #TB_Waybills_9802 AS WB ON CI.Waybill = WB.Waybill

        GROUP BY
            CI.[ShipDate]
            ,CI.[Waybill]
            ,CI.[Stylenumber]
            ,COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])
            ,CI.[Manufacturer]
            ,CI.[Price]
            -- ,CI.[Quantity]
            -- ,CI.[TotalPrice]
            ,CI.[CountryOfOrigin]
        -- order by Stylenumber
    ---------------------INFORMACION COMERCIAL INVOICE 9802-------------------------------------
 
 SELECT * 
 INTO #TB_VAL_CI_DATA
 FROM(
     SELECT * FROM #TB_Dat_Invoice
     UNION ALL
     SELECT * FROM #TB_Dat_Transfer9802
     UNION ALL
     SELECT * FROM #TB_CI_NONCAFTA
     UNION ALL
     SELECT * FROM #TB_CI_ONLY9802
 ) AS TB
 
 
SELECT * 
 INTO #TB_VAL_CI_PIV
 FROM(
    SELECT 
         [ShipDate]              = S.[ShipDate]
        ,[Waybill]               = S.[Waybill]
        ,[StyleNumber]           = S.[StyleNumber]
        ,[US_HTSCode]            = S.[US_HTSCode]
        ,[Manufacturer]          = S.[Manufacturer]
        ,[CountryOfOrigin]       = S.[CountryOfOrigin]
        ,[UnitPrice]             = S.[UnitPrice]
        
        ,[Qty_Dat_Invoice]       = S.[Qty_Dat_Invoice]
        ,[Qty_Dat_Transfer]      = S.[Qty_Dat_Transfer]
        ,[Qty_CI_CAFTA]          = S.[Qty_CI_CAFTA]
        ,[Qty_CI_NONCAFTA]       = S.[Qty_CI_NONCAFTA]
        ,[Qty_CI_9802]           = S.[Qty_CI_9802]
        ,[QTY_Validation]        = S.[Qty_Dat_Invoice] 
                                        - (
                                              S.[Qty_CI_CAFTA]
                                            + S.[Qty_CI_NONCAFTA]
                                            + S.[Qty_CI_9802]
                                           
                                        )
        ,[Dif_9802]             = S.[Qty_Dat_Transfer] - S.[Qty_CI_9802]
        
        ,[Total_Dat_Invoice]     = S.[Total_Dat_Invoice]
        ,[Total_Dat_Transfer]    = S.[Total_Dat_Transfer]
        ,[Total_CI_CAFTA]        = S.[Total_CI_CAFTA]
        ,[Total_CI_NONCAFTA]     = S.[Total_CI_NONCAFTA]
        ,[Total_CI_9802]         = S.[Total_CI_9802]
        ,[Total_Validation]      = S.[Total_Dat_Invoice] 
                                        - (
                                              S.[Total_CI_CAFTA]
                                            + S.[Total_CI_NONCAFTA]
                                            + S.[Total_CI_9802]
                                           
                                        )
        ,[Dif$_9802]             = S.[Total_Dat_Transfer] - S.[Total_CI_9802]
        
        ,[Qty_UNKNOWN]           = S.[Qty_UNKNOWN]
        ,[Total_UNKNOWN]         = S.[Total_UNKNOWN]
    FROM(
            SELECT
                 b.ShipDate
                ,b.Waybill
                ,b.StyleNumber
                ,[US_HTSCode]       = LEFT(b.US_HTSCode,6)
                ,b.Manufacturer
                ,b.CountryOfOrigin
                ,b.UnitPrice
            
                -------------------------------------------------
                -- CANTIDADES POR TYPEDATA
                -------------------------------------------------
                ,Qty_Dat_Invoice   = SUM(CASE WHEN b.TypeData = 'Dat_Invoice'  THEN b.Quantity ELSE 0 END)
                ,Qty_Dat_Transfer  = SUM(CASE WHEN b.TypeData = 'Dat_Transfer' THEN b.Quantity ELSE 0 END)
                ,Qty_CI_CAFTA      = SUM(CASE WHEN b.TypeData = 'CI_Cafta'     THEN b.Quantity ELSE 0 END)
                ,Qty_CI_NONCAFTA   = SUM(CASE WHEN b.TypeData = 'CI_NonCafta'  THEN b.Quantity ELSE 0 END)
                ,Qty_CI_9802       = SUM(CASE WHEN b.TypeData = 'CI_9802'  THEN b.Quantity ELSE 0 END)
            
                -------------------------------------------------
                -- TOTALES POR TYPEDATA (OPCIONAL)
                -------------------------------------------------
                ,Total_Dat_Invoice   = SUM(CASE WHEN b.TypeData = 'Dat_Invoice'  THEN b.TotalPrice ELSE 0 END)
                ,Total_Dat_Transfer  = SUM(CASE WHEN b.TypeData = 'Dat_Transfer' THEN b.TotalPrice ELSE 0 END)
                ,Total_CI_CAFTA      = SUM(CASE WHEN b.TypeData = 'CI_Cafta'     THEN b.TotalPrice ELSE 0 END)
                ,Total_CI_NONCAFTA   = SUM(CASE WHEN b.TypeData = 'CI_NonCafta'  THEN b.TotalPrice ELSE 0 END)
                ,Total_CI_9802       = SUM(CASE WHEN b.TypeData = 'CI_9802'      THEN b.TotalPrice ELSE 0 END)
                
                ,Qty_UNKNOWN       = SUM(CASE WHEN b.TypeData = 'UNKNOWN'      THEN b.Quantity ELSE 0 END)
                ,Total_UNKNOWN       = SUM(CASE WHEN b.TypeData = 'UNKNOWN'      THEN b.TotalPrice ELSE 0 END)
            
            FROM #TB_VAL_CI_DATA AS b
            GROUP BY
                 b.ShipDate
                ,b.Waybill
                ,b.StyleNumber
                -- ,b.US_HTSCode
                ,LEFT(b.US_HTSCode,6)
                ,b.Manufacturer
                ,b.CountryOfOrigin
                ,b.UnitPrice
            -- HAVING b.StyleNumber = 'CFA'    -- déjalo o quítalo según quieras
        ) AS S
    ) AS TB


     
    --  SELECT 
    --      [Waybill]
    --     ,[Qty_Invoice]      = SUM(Qty_Dat_Invoice)
    --     ,[Qty_NoMatch]      = SUM(QTY_Validation) 
    --     ,[Total_Invoice]    = SUM(Total_Dat_Invoice)
    --     ,[Total_NoMatch]    = SUM(Total_Validation) 
    --  FROM #TB_VAL_CI_PIV 
    --  GROUP BY [Waybill]
     
     SELECT * FROM #TB_VAL_CI_PIV 
	 WHERE Dif_9802 <> 0 OR Dif$_9802 <> 0
     
--  SELECT * FROM #TB_VAL_CI_DATA
 
-- SELECT * FROM [AppsLCA].[dbo].[ImportExport_AnexoFacturacion]  WHERE Waybill = 'AIR-HW-20250821' AND 	StyleNumber 	= 'WILSON'

-- SELECT * FROM 
-- SELECT 
--     F.ID
--     ,F.Manufacturer
--     ,TK.Manufacturer
-- FROM [AppsLCA].[dbo].[TB_Transfer_Kardex_Duty]  AS TK WITH(NOLOCK)
-- INNER JOIN #TB_Waybills_9802 AS WB ON TK.Waybill = WB.Waybill
-- LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_Export_Duty]    AS E    WITH(NOLOCK)  ON TK.IDExport = E.ID
-- LEFT JOIN [AppsLCA].[dbo].[ImportExport_AnexoFacturacion]  AS F WITH(NOLOCK) ON F.ID = E.ID

-- WHERE TK.Waybill = 'AIR-HW-20250821' AND 	TK.StyleNumber 	= 'WILSON' AND TK.[Manufacturer] = 'JEYA HEADWEAR'

--EXEC [AppsLCA].[dbo].[SP_Transfer_Cuadre_CI_9802] 
END


