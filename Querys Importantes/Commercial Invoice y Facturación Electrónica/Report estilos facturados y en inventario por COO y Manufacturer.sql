-- Limpieza por si el script quedó a medias en una corrida anterior
DROP TABLE IF EXISTS #AF
DROP TABLE IF EXISTS #TB_MOS_FOR_SUMMARY_GROUP
DROP TABLE IF EXISTS #TB_FAMO_SUMMARY
DROP TABLE IF EXISTS #TB_InventoryStyles
DROP TABLE IF EXISTS #TB_Final
DROP TABLE IF EXISTS #TB_Final

-- 1) Datos iniciales de AF (se guardan también copias "Raw" de los campos
--    que los JOIN posteriores necesitan evaluar con su valor original,
--    ya que el SELECT original usa AF.* crudo en las condiciones de JOIN,
--    no el valor ya resuelto por COALESCE).
--    Key1/Key2/Key3 = estilo-color-talla / estilo-color / estilo, usadas
--    para emparejar contra #TB_FAMO_SUMMARY con distintos niveles de detalle.
SELECT
	 StyleNumber      = CASE WHEN AF.StyleNumber IN ('ESMZ230','ESMS235') THEN '31118' ELSE AF.StyleNumber END
	,Manufacturer     = AF.Manufacturer
	,CountryOfOrigin  = AF.CountryOfOrigin
	,MO               = AF.MO
	,ManufactureID    = AF.ManufactureID
	,RO               = AF.RO
	,RO_ID            = AF.RO_ID
	,ShipDate         = AF.ShipDate
	,Qty              = AF.Qty
	,BoxNumber        = AF.BoxNumber
	,ManufactureID_Raw = AF.ManufactureID
	,RO_Raw            = AF.RO
	,RO_ID_Raw         = AF.RO_ID
    ,[Key1]            = CONCAT(AF.StyleNumber , '-' , AF.StyleColor , '-' , AF.[Size])
    ,[Key2]            = CONCAT(AF.StyleNumber , '-' , AF.StyleColor )
    ,[Key3]            = CONCAT(AF.StyleNumber  ,'')
INTO #AF
FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK)
WHERE AF.StyleNumber IN ('30028','31118','33032','82176','82182','ESMZ230','ESMS235');

-- 2) MO / ManufactureID = COALESCE(AF.MO/ManufactureID, SMO.MO/MOID)
UPDATE T
SET T.MO            = SMO.MO,
    T.ManufactureID = SMO.MOID
FROM #AF AS T
INNER JOIN LCA.dbo.VW_Check_Sales_Prices_in_Invoices_SeekMO_2 AS SMO WITH(NOLOCK)
	ON SMO.BoxNumber = T.BoxNumber
WHERE T.ManufactureID_Raw IS NULL;

-- 3) RO / RO_ID = COALESCE(AF.RO/RO_ID, EORO.RO/RO_ID)
--    EORO se une por COALESCE(AF.ManufactureID, SMO.MOID), que ya quedó
--    resuelto en T.ManufactureID tras el paso anterior
UPDATE T
SET T.RO    = EORO.RO,
    T.RO_ID = EORO.RO_ID
FROM #AF AS T
INNER JOIN LCA.dboReaders.VW_EORO AS EORO WITH(NOLOCK)
	ON T.ManufactureID = EORO.EO_ID
WHERE T.RO_Raw IS NULL;

-- Lista única de ManufactureID (tomados de RO_ID y de ManufactureID en #AF)
-- que se van a buscar en TB_MO_PartNumber_IM_Summary, para no consultar esa
-- tabla con el universo completo
SELECT DISTINCT
		[ManufactureID]
INTO #TB_MOS_FOR_SUMMARY_GROUP
FROM(
	SELECT DISTINCT [RO_ID] AS [ManufactureID]  FROM #AF WHERE RO_ID IS NOT NULL
	UNION ALL
	SELECT DISTINCT [ManufactureID] AS [ManufactureID]  FROM #AF WHERE ManufactureID IS NOT NULL
)AS TB

-- Detalle de Manufacturer/CountryOfOrigin/TariffCategory por ManufactureID,
-- con Key1/Key2/Key3 (estilo-color-talla / estilo-color / estilo) y un
-- ROW_NUMBER por cada nivel de clave para poder elegir, en las cascadas de
-- UPDATE que siguen, la mejor coincidencia disponible por cada ManufactureID
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

-- 4) Manufacturer / CountryOfOrigin = COALESCE(AF.Manufacturer/CountryOfOrigin, COO.*)
--    COO se une por AF.RO_ID crudo, tal como en el SELECT original.
--    Cascada de 4 UPDATEs que intentan la coincidencia más específica primero
--    (Key1: estilo-color-talla, Key2: estilo-color, Key3: estilo) y, si nada
--    matchea, caen a un JOIN solo por RO_ID sin usar ninguna Key
UPDATE T
SET T.Manufacturer    = COO.Manufacturer,
    T.CountryOfOrigin = COO.CountryOfOrigin
FROM #AF AS T
INNER JOIN #TB_FAMO_SUMMARY AS COO
	ON T.RO_ID_Raw = COO.ManufactureID
    AND COO.[Key1] = T.[Key1]
WHERE T.Manufacturer IS NULL OR T.CountryOfOrigin IS NULL;

UPDATE T
SET T.Manufacturer    = COO.Manufacturer,
    T.CountryOfOrigin = COO.CountryOfOrigin
FROM #AF AS T
INNER JOIN #TB_FAMO_SUMMARY AS COO
	ON T.RO_ID_Raw = COO.ManufactureID
    AND COO.[Key2] = T.[Key2]
WHERE T.Manufacturer IS NULL OR T.CountryOfOrigin IS NULL;

UPDATE T
SET T.Manufacturer    = COO.Manufacturer,
    T.CountryOfOrigin = COO.CountryOfOrigin
FROM #AF AS T
INNER JOIN #TB_FAMO_SUMMARY AS COO
	ON T.RO_ID_Raw = COO.ManufactureID
    AND COO.[Key3] = T.[Key3]
WHERE T.Manufacturer IS NULL OR T.CountryOfOrigin IS NULL;

UPDATE T
SET T.Manufacturer    = COO.Manufacturer,
    T.CountryOfOrigin = COO.CountryOfOrigin
FROM #AF AS T
INNER JOIN #TB_FAMO_SUMMARY AS COO
	ON T.RO_ID_Raw = COO.ManufactureID
WHERE T.Manufacturer IS NULL OR T.CountryOfOrigin IS NULL;

-- 5) Manufacturer / CountryOfOrigin = COALESCE(..., CO2.*)
--    CO2 se une por EORO.RO_ID (ya resuelto en T.RO_ID en el paso 3),
--    y solo aplica cuando EORO se resolvió (AF.RO era NULL).
--    Misma cascada Key1 -> Key2 -> Key3 -> solo RO_ID que el bloque anterior
UPDATE T
SET T.Manufacturer    = COALESCE(T.Manufacturer, CO2.Manufacturer),
    T.CountryOfOrigin = COALESCE(T.CountryOfOrigin, CO2.CountryOfOrigin)
FROM #AF AS T
INNER JOIN #TB_FAMO_SUMMARY AS CO2
	ON T.RO_ID = CO2.ManufactureID
    AND CO2.[Key1] = T.[Key1]
WHERE (T.Manufacturer IS NULL OR T.CountryOfOrigin IS NULL)
	AND T.RO_Raw IS NULL;

UPDATE T
SET T.Manufacturer    = COALESCE(T.Manufacturer, CO2.Manufacturer),
    T.CountryOfOrigin = COALESCE(T.CountryOfOrigin, CO2.CountryOfOrigin)
FROM #AF AS T
INNER JOIN #TB_FAMO_SUMMARY AS CO2
	ON T.RO_ID = CO2.ManufactureID
    AND CO2.[Key2] = T.[Key2]
WHERE (T.Manufacturer IS NULL OR T.CountryOfOrigin IS NULL)
	AND T.RO_Raw IS NULL;

UPDATE T
SET T.Manufacturer    = COALESCE(T.Manufacturer, CO2.Manufacturer),
    T.CountryOfOrigin = COALESCE(T.CountryOfOrigin, CO2.CountryOfOrigin)
FROM #AF AS T
INNER JOIN #TB_FAMO_SUMMARY AS CO2
	ON T.RO_ID = CO2.ManufactureID
    AND CO2.[Key3] = T.[Key3]
WHERE (T.Manufacturer IS NULL OR T.CountryOfOrigin IS NULL)
	AND T.RO_Raw IS NULL;

UPDATE T
SET T.Manufacturer    = COALESCE(T.Manufacturer, CO2.Manufacturer),
    T.CountryOfOrigin = COALESCE(T.CountryOfOrigin, CO2.CountryOfOrigin)
FROM #AF AS T
INNER JOIN #TB_FAMO_SUMMARY AS CO2
	ON T.RO_ID = CO2.ManufactureID
WHERE (T.Manufacturer IS NULL OR T.CountryOfOrigin IS NULL)
	AND T.RO_Raw IS NULL;

-- 6) Último fallback: IIF(AF.RO = '19084-144-SYH-1', ...)
UPDATE T
SET T.Manufacturer    = 'AL-AMEERA',
    T.CountryOfOrigin = 'Pakistan'
FROM #AF AS T
WHERE (T.Manufacturer IS NULL OR T.CountryOfOrigin IS NULL)
	AND T.RO_Raw = '19084-144-SYH-1';

----- Inventario
-- A partir de aquí se arma #TB_PACKED_BOXES: el inventario "on hand" (no
-- facturado) que se suma al resultado de #AF (lo ya facturado/shipped).
-- Se llena en dos INSERT: 1) cajas empacadas/picked (TypeQueryN 3) y
-- 2) prendas sueltas en almacén por FinishedGoods (TypeQueryN 2)
DROP TABLE IF EXISTS #TB_PACKED_BOXES
  SELECT
             [TypeQuery]        	= 'Empaque'
            ,[TypeQueryN]       	= 3
            ,[R] 					= ROW_NUMBER() OVER(ORDER BY ORD.OrderID,PB.PackedBoxID,PBI.PackedItemID) 
            ,[Area]		            = CAST(
                                             CONCAT('Empaque', ' - ',
												CASE
													WHEN ISNULL(gb.Bin,'TBD') LIKE 'Skid%'	THEN 'Skid'
													WHEN ISNULL(gb.Bin,'TBD') LIKE 'TRUCK%' THEN 'TRUCK'
													WHEN ISNULL(gb.Bin,'TBD') LIKE 'SFL%'	THEN 'SFL'
													WHEN ISNULL(gb.Bin,'TBD') LIKE 'TMP%'	THEN 'TMP'
													WHEN ISNULL(gb.Bin,'TBD') LIKE 'AIR%'	THEN 'AIR'
													WHEN ISNULL(gb.Bin,'TBD') LIKE 'CONT%'	THEN 'CONT'
													WHEN ISNULL(gb.Bin,'TBD') LIKE 'RTS%'	THEN 'RTS'
													WHEN ISNULL(gb.Bin,'TBD') LIKE 'SHIP%'	THEN 'SHIP'
													WHEN ISNULL(gb.Bin,'TBD') LIKE 'SM%'	THEN 'SM'
													WHEN ISNULL(gb.Bin,'TBD') LIKE 'JSP%'	THEN 'JSP'
													WHEN ISNULL(gb.Bin,'TBD') LIKE '%-%'	THEN LEFT(ISNULL(gb.Bin,'TBD'),3)
													ELSE 'OTHER'
												END
											)
                                            AS VARCHAR(100))
			,[Location]             = CAST(ISNULL(gb.bin,'TBD') AS VARCHAR(100))
			,[LocationCost]         = CAST('Empaque' AS VARCHAR(100))
            ,[WarehouseID]			= WH.WarehouseID
            ,[warehousename]		= WH.WarehouseName
            ,[BoxID]				= PB.PackedBoxID
            ,[BoxCode]				= 'PPBX'+LTRIM(STR(PB.PackedBoxID+10000000))
            ,[BoxNumber]			= PB.BoxNumber
            ,[FormattedBoxNumber]			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL , CONCAT('PPPA'+Ltrim(Str(pp.PackedPalletID+1000000)),'-',RIGHT(btg.DropDownValue,3)) 
																	,pb.[BoxNumber] 
																)
            ,[BoxComments]			= PB.BoxComments
            ,[BoxComments5]			= PB.BoxComments5
            ,[StatusID]				= SN.StatusID
            ,[BoxStatus]			= SN.StatusName
            ,[PackedItemID]			= PBI.PackedItemID
                        
            ,[BundleID]		    	= NULL
            ,[BundleNumber]	    	= NULL	
            ,[BundleBarcode]    	= NULL
                        
            ,[ManufactureID]		= MO.ManufactureID
            ,[MO]					= MO.ManufactureNumber
            ,[MOStatusID]       	= SNM.StatusID
            ,[MOStatus]         	= SNM.StatusName
            ,[ProductionStatus]		= PST.DropDownValue
            ,[PWModulo]         	= MO.Comments7 
            ,[StyleID]				= ST.StyleID
            ,[Style]				= ST.StyleNumber
            ,[SeasonID]				= SNS.SeasonID
            ,[Season]				= SNS.SeasonName
            ,[ColorID]				= STC.StyleColorID
            ,[Color]				= STC.StyleColorName
			,[OptionMO]            	= MO.Comments17
			,[OptionID]            	= CAST(NULL AS INT)
            ,[FinishedGoodsID]		= PBI.FinishedGoodsID
            ,[Size]					= FG.GarmentSize
            ,[Quantity]				= PBI.Quantity
            ,[OrderID]				= ORD.OrderID
            ,[PONumber]				= ORD.PONumber
            ,[PrintCount]			= COALESCE(TRY_CAST(ORD.Comments14 AS NUMERIC(18,2)),0.00)
            ,[CodeEmbroidery]		= ORD.Comments26
            ,[ProductDivision]		= ST.Comments9
			,[StyleDivision]		= CAST(NULL AS VARCHAR(50))     
            ,[GoodsBinID]			= pb.[GoodsBinID]
			,[Bin]					= gb.Bin
			,[PalletID]				= PP.PackedPalletID
			,[Pallet]				= PP.PalletNumber
            ,[BoxTypeID]			= BT.BoxTypeID
            ,[OrderDetailsID]		= PBI.OrderDetailsID
            ,[PackerID]				= PB.PackerID
            ,[PackerUser]			= USPK.UserName
            ,[PackerName]			= USPK.[Description]		
            ,[PackDate]             = PB.PackDate
            ,[ManufactureDate]      = MO.ManufacturedDate
        INTO #TB_PACKED_BOXES
        FROM 		(SELECT StatusID,StatusName FROM LCA.dbo.statusnames WITH(NOLOCK) WHERE StatusID IN( 27,25,75)) 	AS SN 	
        INNER JOIN	LCA.dbo.PackedBoxes			AS PB	WITH(NOLOCK) ON PB.StatusID			    = SN.StatusID			AND SN.StatusID IN (25,27,75) --Packed and Picked
        INNER JOIN	LCA.dbo.PackedItems			AS PBI	WITH(NOLOCK) ON PB.PackedBoxID		    = PBI.PackedBoxID		AND PBI.Quantity <> 0
		LEFT JOIN   LCA.dbo.Shipments           AS SH   WITH(NOLOCK) ON PB.ShipmentID           = SH.ShipmentID
        LEFT JOIN	LCA.dbo.Warehouses			AS WH	WITH(NOLOCK) ON PB.WarehouseID		    = WH.WarehouseID
        LEFT JOIN	LCA.dbo.ManufactureOrders	AS MO	WITH(NOLOCK) ON MO.ManufactureID	    = PBI.ManufactureID
        INNER JOIN	LCA.dbo.FinishedGoods		AS FG	WITH(NOLOCK) ON PBI.FinishedGoodsID	    = FG.FinishedGoodsID   
                                                                                AND
																				(
																					(SN.StatusID IN(25,27))
																					OR
																					(SN.StatusID = 75 AND SH.InvoiceBatchID IS NULL AND CAST(sh.ShipDate AS DATE) >= CAST('2025-07-01' AS DATE))
																				)
        INNER JOIN	LCA.dbo.Styles				AS ST	WITH(NOLOCK) ON FG.StyleID			    = ST.StyleID AND ST.StyleNumber IN ('30028','31118','33032','82176','82182','ESMZ230','ESMS235')
        LEFT JOIN	LCA.dbo.Seasons				AS SNS	WITH(NOLOCK) ON SNS.SeasonID		    = ST.SeasonID
        INNER JOIN	LCA.dbo.StyleColors			AS STC	WITH(NOLOCK) ON FG.StyleColorID		    = STC.StyleColorID
        LEFT JOIN	LCA.dbo.StatusNames			AS SNM 	WITH(NOLOCK) ON SNM.StatusID		    = MO.StatusID
        LEFT JOIN	LCA.dbo.BoxTypes			AS BT	WITH(NOLOCK) ON PB.BoxTypeID		    = BT.BoxTypeID
        LEFT JOIN	LCA.dbo.OrderDetails		AS OD	WITH(NOLOCK) ON OD.OrderDetailsID	    = PBI.OrderDetailsID
        LEFT JOIN	LCA.dbo.Orders 				AS ORD	WITH(NOLOCK) ON OD.OrderID			    = ORD.OrderID
        LEFT JOIN	LCA.dbo.PackedPallets		AS PP	WITH(NOLOCK) ON PP.PackedPalletID	    = PB.PackedPalletID
        LEFT JOIN	LCA.dbo.Users				AS USPK	WITH(NOLOCK) ON PB.PackerID			    = USPK.UserID
        LEFT JOIN 	LCA.dbo.DropDownValues3 	AS PST	WITH(NOLOCK) ON MO.ProductionStatusID 	= PST.DropDownValueID
        LEFT JOIN	LCA.dbo.DropDownValues3	    AS btg	WITH(NOLOCK) ON btg.DropDownValueID		= pb.BoxTagID			AND btg.DropDownID = 19
		LEFT JOIN   LCA.dbo.PalletTypes		    AS ppt  WITH(NOLOCK) ON pp.PalletTypeID			= ppt.PalletTypeID  
		LEFT JOIN	LCA.dbo.boxtypes		    AS bxtp WITH(NOLOCK) ON pb.boxtypeid			= bxtp.boxtypeid
		LEFT JOIN	LCA.dbo.GoodsBins           AS gb	WITH(NOLOCK) ON gb.GoodsBinID			= pb.GoodsBinID
		-- CROSS APPLY #TB_Parameters			AS PRM	
    ----------------------------------------------------------------------------------------------------------------
	------------------------------*INVENTARIO PACKED AND PICKED------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------
    
	
	
	
	----------------------------------------------------------------------------------------------------------------
	------------------------------*INVENTARIO WAREHOUSE FINISH GOOD--------------------------------------------------
	----------------------------------------------------------------------------------------------------------------
			PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'  INVENTARIO WAREHOUSE TYPEQUERY 2')
			
			
			INSERT INTO #TB_PACKED_BOXES
			SELECT 
				 [TypeQuery]            = 'Prendas'
                ,[TypeQueryN]           = 2
                ,[R]					= ROW_NUMBER() OVER(ORDER BY WH.WarehouseID,PBB.PackedBoxID,PKI.PackedItemID )
                ,[Area]		            = CAST(
                                            CASE
												WHEN WH.WarehouseID= 35 THEN
													 WH.WarehouseName +
													 CASE
													   WHEN gb.bin LIKE 'TBD%' THEN ' - TBD'
													   WHEN LEFT(gb.bin,1) IN ('A','B','C','D','E','F','G','S','Z','X','H','I','J','K','N','M','L')
															THEN ' - ' + LEFT(gb.bin,1)
													   ELSE ' '
													 END
												WHEN WH.WarehouseID= 53 THEN
													 WH.WarehouseName +
													 CASE
													   WHEN LEFT(gb.bin,1) IN ('A','B','C','D','H','E','F')
															THEN ' - ' + LEFT(gb.bin,1)
													   ELSE ' '
													 END
												WHEN WH.WarehouseID= 60 THEN
													 CASE
													   WHEN LEFT(gb.bin,2) IN ('NB','NC','ND','NE','NF')
															THEN WH.WarehouseName + ' - '+ LEFT(gb.bin,2)
													   ELSE WH.WarehouseName
													 END
												WHEN WH.WarehouseID= 1  THEN 'WH PT First'
												WHEN WH.WarehouseID= 11 THEN 'WH Duplicate'
												
												WHEN WH.WarehouseID = 7 AND SNS.SeasonName = 'EMB FG'   
												THEN 'WH NOVA SECONDS'
										    	WHEN WH.WarehouseID = 7 AND SNS.SeasonName = 'BLANK FG' 
										    	THEN CONCAT(WH.WarehouseName,' FG')
												
												WHEN WH.WarehouseID = 8 THEN CONCAT('WH ',WH.WarehouseName)
												ELSE WH.WarehouseName END
                                            AS VARCHAR(100))
				,[Location]             = CAST(ISNULL(gb.bin,'TBD') AS VARCHAR(100))
				,[LocationCost]         = CAST(
												CASE
												WHEN WH.WarehouseID = 1	THEN 'WH PT'
												-- WHEN WH.WarehouseID = 7	AND SNS.SeasonName = 'EMB FG'   THEN 'WH PT'--'WH NOVA SECONDS'--1
												-- WHEN WH.WarehouseID = 7	AND SNS.SeasonName = 'BLANK FG' THEN 'WH PT'--CONCAT(WH.WarehouseName,' FG')--1
												WHEN WH.WarehouseID IN(7,10,8,51,52,56,58)	AND SNS.SeasonName IN( 'BLANK FG','EMB FG') THEN 'WH PT'--CONCAT(WH.WarehouseName,' FG')--1
												
												WHEN WH.WarehouseID = 7	THEN 'WH NOT INCLUDED'--0                            ---DEMAS DE SECONDS
												WHEN WH.WarehouseID = 8	THEN 'WH NOT INCLUDED'--0
												WHEN WH.WarehouseID = 10	THEN 'WH NOT INCLUDED'--0
												WHEN WH.WarehouseID = 11	THEN 'WH PT'--1
												WHEN WH.WarehouseID = 35	THEN 'WH RO'--1
												WHEN WH.WarehouseID = 51	THEN 'WH NOT INCLUDED'--0
												WHEN WH.WarehouseID = 52	THEN 'WH NOT INCLUDED'--0
												WHEN WH.WarehouseID = 53	THEN 'Headwear DLI'
												WHEN WH.WarehouseID = 56	THEN 'WH NOT INCLUDED'--0
												WHEN WH.WarehouseID = 58	THEN 'WH NOT INCLUDED'--0
												WHEN WH.WarehouseID = 59	THEN 'WH First Semi Finish'
												WHEN WH.WarehouseID = 60	THEN 'WH RO'
												WHEN WH.WarehouseID = 37	THEN 'WH NOT INCLUDED'--0
												ELSE 'WH NOT DEFINED'
											END
										    AS VARCHAR(100))
				,[WarehouseID]			= WH.WarehouseID
				,[warehousename]		= WH.WarehouseName 
				,[BoxID]				= PBB.PackedBoxID
				,[BoxCode]				= 'PPBX'+LTRIM(STR(PBB.PackedBoxID+10000000))
				,[BoxNumber]			= PBB.[BoxNumber]
				,[FormatterBoxNumber]   = NULL
				,[BoxComments]			= PBB.BoxComments 
				,[BoxComments5]			= PBB.BoxComments5
				,[StatusID]				= PBB.StatusID
				,[BoxStatus]			= SNPB.StatusName
				,[PackedItemID]			= PKI.[PackedItemID]
                ,[BundleID]		        = NULL
                ,[BundleNumber]	        = NULL
                ,[BundleBarcode]        = NULL

				,[ManufactureID]		= PKI.[ManufactureID]
				,[MO]					= MO.ManufactureNumber
                ,[MOStatusID]           = SN.StatusID
                ,[MOStatus]             = sn.StatusName
                ,[ProductionStatus]		= PST.DropDownValue
                ,[PWModulo]				= MO.Comments7 
				,[StyleID]				= ST.StyleID
				,[Style]				= ST.StyleNumber
				,[SeasonID]				= SNS.SeasonID
				,[Season]				= SNS.SeasonName
				,[ColorID]				= FG.StyleColorID
				,[Color]				= col.StyleColorName
				,[OptionMO]            	= MO.Comments17
				,[OptionID]            	= CAST(NULL AS INT)
				,[FinishedGoodsID]		= PKI.[FinishedGoodsID]
				,[Size]					= FG.GarmentSize
				,[Quantity]				= PKI.[Quantity]
				,[OrderID]				= ORD.OrderID
				,[PONumber]				= ORD.PONumber
				,[PrintCount]			= COALESCE(TRY_CAST(ORD.Comments14 AS NUMERIC(18,2)),0.00)
				,[CodeEmbroidery]		= ORD.Comments26
				,[ProductDivision]		= ST.Comments9
				,[StyleDivision]		= CAST(NULL AS VARCHAR(50))     
				,[GoodsBinID]			= PBB.[GoodsBinID]
				,[Bin]					= gb.Bin
				,[PalletID]				= NULL
				,[Pallet]				= NULL
				,[BoxTypeID]			= PBB.BoxTypeID
				,[OrderDetailsID]		= PKI.[OrderDetailsID]
				,[PackerID]				= PBB.PackerID
				,[PackerUser]			= USPK.UserName
				,[PackerName]			= USPK.[Description]
				,[PackDate]             = PBB.PackDate
				,[ManufactureDate]      = MO.ManufacturedDate
			FROM		(	SELECT 
								WH.WarehouseID
		                    FROM		LCA.dbo.Warehouses AS WH WITH(NOLOCK)
                            WHERE WH.StatusID = 30 AND WarehouseID in (35,8,51)
		                )	AS fil
			INNER JOIN  LCA.dbo.Warehouses 			AS WH	WITH(NOLOCK) ON fil.[WarehouseID]       = WH.[WarehouseID]      AND WH.[StatusID] = 30
			INNER JOIN	LCA.dbo.PackedBoxes 		AS PBB	WITH(NOLOCK) ON PBB.[WarehouseID]		= WH.[WarehouseID]		AND PBB.[StatusID] IN(0, 8, 98, 100)	
			INNER JOIN	LCA.dbo.PackedItems			AS PKI	WITH(NOLOCK) ON PKI.[PackedBoxID]		= PBB.[PackedBoxID]		AND PKI.[Quantity] <> 0
			LEFT JOIN	LCA.dbo.GoodsBins			AS gb	WITH(NOLOCK) ON gb.[GoodsBinID]		    = PBB.[GoodsBinID]
			LEFT JOIN	LCA.dbo.FinishedGoods		AS FG	WITH(NOLOCK) ON FG.[FinishedGoodsID]	= PKI.[FinishedGoodsID]
			LEFT JOIN	LCA.dbo.Styles				AS ST	WITH(NOLOCK) ON ST.[StyleID]			= FG.[StyleID]
			LEFT JOIN	LCA.dbo.Seasons				AS SNS	WITH(NOLOCK) ON SNS.[SeasonID]			= ST.[SeasonID]
			LEFT JOIN	LCA.dbo.StyleColors			AS Col	WITH(NOLOCK) ON Col.[StyleColorID]		= FG.[StyleColorID]
			LEFT JOIN	LCA.dbo.ManufactureOrders	AS MO	WITH(NOLOCK) ON MO.[ManufactureID]		= PKI.[ManufactureID]
			LEFT JOIN	LCA.dbo.StatusNames			AS SNPB WITH(NOLOCK) ON SNPB.[StatusID]			= PBB.[StatusID]
			LEFT JOIN	LCA.dbo.OrderDetails		AS OD	WITH(NOLOCK) ON OD.[OrderDetailsID]		= PKI.[OrderDetailsID]
			LEFT JOIN	LCA.dbo.Orders				AS ORD	WITH(NOLOCK) ON OD.[OrderID]			= ORD.[OrderID]
			LEFT JOIN	LCA.dbo.Users				AS USPK	WITH(NOLOCK) ON USPK.[UserID]			= PBB.[PackerID]
            LEFT JOIN   LCA.dbo.StatusNames 		AS sn	WITH(NOLOCK) ON sn.[StatusID] 			= MO.[StatusID]
            LEFT JOIN 	LCA.dbo.DropDownValues3 	AS PST	WITH(NOLOCK) ON MO.[ProductionStatusID] = PST.[DropDownValueID]
            WHERE ST.StyleNumber IN ('30028','31118','33032','82176','82182','ESMZ230','ESMS235')

-- Agrega a #TB_FAMO_SUMMARY los ManufactureID que aparecen en el inventario
-- (#TB_PACKED_BOXES) y que todavía no estaban cubiertos por el universo de #AF
INSERT INTO #TB_FAMO_SUMMARY
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
FROM (SELECT DISTINCT ManufactureID FROM #TB_PACKED_BOXES) AS S
INNER JOIN [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Summary] AS B WITH(NOLOCK) ON S.ManufactureID = B.ManufactureId
			
			
-- Reduce #TB_PACKED_BOXES a una fila por estilo/MO/almacén con Manufacturer
-- y CountryOfOrigin en blanco, para llenarlos con la misma lógica de cascada
-- (Key1 -> Key2 -> Key3 -> solo ManufactureID) usada arriba para #AF
SELECT
	Style
    ,ManufactureID
    ,MO
    ,Quantity
    ,warehousename
    ,Manufacturer       = CAST(NULL AS VARCHAR(100))
    ,CountryOfOrigin    = CAST(NULL AS VARCHAR(100))
    ,[Key1]             = CONCAT(Style , '-' , Color , '-' , [Size])
    ,[Key2]             = CONCAT(Style , '-' , Color )
    ,[Key3]             = CONCAT(Style  ,'')
INTO #TB_InventoryStyles
FROM #TB_PACKED_BOXES

UPDATE TIS SET
    [Manufacturer] = TFS.[Manufacturer]
    ,[CountryOfOrigin] = TFS.[CountryOfOrigin]
FROM #TB_InventoryStyles    AS TIS
INNER JOIN #TB_FAMO_SUMMARY AS TFS ON TIS.[ManufactureID] = TFS.[ManufactureID] AND TFS.[Key1] = TIS.[Key1]
WHERE (TIS.[Manufacturer] IS NULL OR TIS.[CountryOfOrigin] IS NULL)

UPDATE TIS SET
    [Manufacturer] = TFS.[Manufacturer]
    ,[CountryOfOrigin] = TFS.[CountryOfOrigin]
FROM #TB_InventoryStyles    AS TIS
INNER JOIN #TB_FAMO_SUMMARY AS TFS ON TIS.[ManufactureID] = TFS.[ManufactureID] AND TFS.[Key2] = TIS.[Key2]
WHERE (TIS.[Manufacturer] IS NULL OR TIS.[CountryOfOrigin] IS NULL)

UPDATE TIS SET
    [Manufacturer] = TFS.[Manufacturer]
    ,[CountryOfOrigin] = TFS.[CountryOfOrigin]
FROM #TB_InventoryStyles    AS TIS
INNER JOIN #TB_FAMO_SUMMARY AS TFS ON TIS.[ManufactureID] = TFS.[ManufactureID] AND TFS.[Key3] = TIS.[Key3]
WHERE (TIS.[Manufacturer] IS NULL OR TIS.[CountryOfOrigin] IS NULL)

UPDATE TIS SET
    [Manufacturer] = TFS.[Manufacturer]
    ,[CountryOfOrigin] = TFS.[CountryOfOrigin]
FROM #TB_InventoryStyles    AS TIS
INNER JOIN #TB_FAMO_SUMMARY AS TFS ON TIS.[ManufactureID] = TFS.[ManufactureID]
WHERE (TIS.[Manufacturer] IS NULL OR TIS.[CountryOfOrigin] IS NULL)

-- Mismo fallback especial que en #AF, pero aplicado por MO en vez de por RO
UPDATE T
SET T.Manufacturer    = 'AL-AMEERA',
    T.CountryOfOrigin = 'Pakistan'
FROM #TB_InventoryStyles AS T
WHERE (T.Manufacturer IS NULL OR T.CountryOfOrigin IS NULL)
	AND T.MO = '19084-144-SYH-1';

-- 7) Resultado final: une lo ya facturado ("Shipped", desde #AF) con lo que
--    sigue en inventario ("On Hand", desde #TB_InventoryStyles), agrupado
--    por estilo/Manufacturer/CountryOfOrigin (equivalente al '' final del
--    COALESCE original cuando no hubo match en ningún JOIN)
SELECT
*
INTO #TB_Final
FROM
(
    SELECT
        Style           = StyleNumber
        ,Manufacturer    = COALESCE(CASE
                                        WHEN Manufacturer LIKE '%Meera%' THEN 'AL-AMEERA'
                                        WHEN Manufacturer LIKE '%League%' THEN 'League LTDA'
                                        ELSE Manufacturer
                                        END, '')
        ,CountryOfOrigin = COALESCE(CountryOfOrigin, '')
        ,[Status]        = 'Shipped'
        ,Qty             = SUM(Qty)
    FROM #AF
    GROUP BY
        StyleNumber
        ,COALESCE(CASE
                                        WHEN Manufacturer LIKE '%Meera%' THEN 'AL-AMEERA'
                                        WHEN Manufacturer LIKE '%League%' THEN 'League LTDA'
                                        ELSE Manufacturer
                                        END, '')
        ,COALESCE(CountryOfOrigin, '')
    UNION
    SELECT
        Style               = CASE WHEN Style IN ('ESMZ230','ESMS235') THEN '31118' ELSE Style END
        ,Manufacturer       = COALESCE(CASE
                                        WHEN Manufacturer LIKE '%Meera%' THEN 'AL-AMEERA'
                                        WHEN Manufacturer LIKE '%League%' THEN 'League LTDA'
                                        ELSE Manufacturer
                                        END, '')
        ,CountryOfOrigin    = COALESCE(CountryOfOrigin, '')
        ,[Status]           = 'On Hand'
        ,Qty                = SUM(Quantity)
    FROM #TB_InventoryStyles
    GROUP BY
        Style
        ,COALESCE(CASE
                                        WHEN Manufacturer LIKE '%Meera%' THEN 'AL-AMEERA'
                                        WHEN Manufacturer LIKE '%League%' THEN 'League LTDA'
                                        ELSE Manufacturer
                                        END, '')
        ,COALESCE(CountryOfOrigin, '')
) AS A
ORDER BY Style, [Status]

-- 8) Pivot de #TB_Final: una columna por cada valor de Status ('Shipped' /
--    'On Hand') con la suma de Qty, una fila por Style/Manufacturer/CountryOfOrigin
SELECT
	 Style
	,Manufacturer
	,CountryOfOrigin
	,Shipped = ISNULL([Shipped], 0)
	,[On Hand] = ISNULL([On Hand], 0)
FROM #TB_Final
PIVOT (
	SUM(Qty) FOR [Status] IN ([Shipped], [On Hand])
) AS PVT
ORDER BY Style;

SELECT * FROM #AF WHERE Manufacturer IS NULL