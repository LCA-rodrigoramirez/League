USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[sp_Update_Import_Export_Commercial_Invoice_WithDetails]    Script Date: 23/03/2026 01:21:35 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_Update_Import_Export_Commercial_Invoice_WithDetails]
AS
BEGIN

Declare @WayBill varchar(100) = null
Declare @Status varchar(100) = null
Declare @Pending_Date datetime = null
Declare @Executing_Date datetime = null
Declare @Finished_Date datetime=null
Declare @TransferVal INT = 0

-- SET @WayBill = 'APP-20260706'
declare WayBill_status cursor for select  * from [AppsLCA].[dbo].[ImportExport_CommercialInvoice_Status]
		where status='Pending'

open WayBill_status
Fetch next from WayBill_status into  @Waybill, @Status, @Pending_Date, @Executing_date, @Finished_Date

while @@Fetch_status=0
	begin

-- --  delete from appslca.dbo.Import_Export_CommercialInvoice_TEST where WayBill =@WayBill
-- delete from appslca.dbo.Import_Export_CommercialInvoice where WayBill =@WayBill
-- delete from AppsLCA.dbo.Import_Export_DeclarationExport where WayBill =@WayBill
delete from [192.168.1.93].appslca.dbo.CI_Import_Export_CommercialInvoice where WayBill =@WayBill
delete from [192.168.1.93].AppsLCA.dbo.CI_Import_Export_DeclarationExport where WayBill =@WayBill

  update [AppsLCA].[dbo].[ImportExport_CommercialInvoice_Status] set [Status] = 'Executing', Executing_Date=getdate() 
  	where waybill =@WayBill

-----COMMERCIAL INVOICE


DROP TABLE IF EXISTS #TB_Transfer_Kardex
DROP TABLE IF EXISTS #TB_DataCI
DROP TABLE IF EXISTS #TB_Transfer
DROP TABLE IF EXISTS #TB_ContentFabric
DROP TABLE IF EXISTS #TB_Data_All
DROP TABLE IF EXISTS #TB_MOS_FOR_SUMMARY_GROUP
DROP TABLE IF EXISTS #TB_FAMO_SUMMARY

DROP TABLE IF EXISTS #TB_COMPOSITION
DROP TABLE IF EXISTS #Positions
DROP TABLE IF EXISTS #Extracted
DROP TABLE IF EXISTS #Cleaned

-- SELECT *
-- INTO #TB_Transfer_Kardex
-- FROM [AppsLCA].[dbo].[TB_Transfer_Kardex_Duty] WITH(NOLOCK)
-- WHERE Waybill = @WayBill


DROP TABLE IF EXISTS #TB_Transfer_Kardex_For_RO_ID

drop table if exists #doble_im_ro
SELECT
MO
into #doble_im_ro
FROM
(
    SELECT
    *
    ,ROW_NUMBER() OVER(PARTITION BY MO ORDER BY MO) as R

    FROM
    (
    SELECT
    IM5
    ,MO
    FROM AppsLCA.dbo.TB_Transfer_Import_Duty WITH(NOLOCK)
    GROUP BY
    IM5
    ,MO
    ) AS A
) AS B
WHERE B.R > 1

SELECT 
     K.IDExport
    ,K.IDImport
    ,K.IDKardex
    ,QtyExport  = K.QtyExport
    ,k.RO_ID
INTO #TB_Transfer_Kardex_For_RO_ID
FROM [AppsLCA].[dbo].[TB_Transfer_Kardex_Duty] AS K WITH(NOLOCK)
WHERE K.Waybill = @WayBill
-- and k.IDKardex = 36156


;WITH CTE_Import_Distinct AS (
    SELECT 
         I.ManufactureID
        ,I.IM5
        ,ID= MAX(I.ID)
    FROM [AppsLCA].[dbo].[TB_Transfer_Import_Duty] AS I WITH(NOLOCK)
    INNER JOIN #TB_Transfer_Kardex_For_RO_ID AS K ON K.RO_ID = I.ManufactureID
    GROUP BY 
     I.ManufactureID
        ,I.IM5
),
CTE_Proporcion AS (
    SELECT
         K.IDExport
        ,K.IDImport
        ,K.IDKardex
        ,QtyExport      = K.QtyExport
        ,K.RO_ID
        ,I.IM5
        ,I.ID
        ,Cnt = COUNT(I.ID) OVER (PARTITION BY K.IDKardex)
        ,RN  = ROW_NUMBER()  OVER (PARTITION BY K.IDKardex ORDER BY I.ID)
    FROM #TB_Transfer_Kardex_For_RO_ID  AS K
    LEFT JOIN CTE_Import_Distinct AS I ON K.RO_ID = I.ManufactureID
    -- WHERE K.RO_ID = 505446
)
SELECT
     IDExport
    ,IDImport   = ID
    ,IDKardex
    ,QtyExport          = CAST( (QtyExport / Cnt) + CASE 
                            WHEN RN <= QtyExport % Cnt THEN 1 ELSE 0 END AS INT)
    ,QtyExport_Original = QtyExport
    ,RO_ID
    ,IM5
    -- ,ID
INTO #TB_Transfer_Kardex
FROM CTE_Proporcion
WHERE CAST( (QtyExport / Cnt) + CASE 
                            WHEN RN <= QtyExport % Cnt THEN 1 ELSE 0 END AS INT) > 0 

SELECT *
INTO #TB_ContentFabric
FROM 
(
	select distinct Style, StyleColorName, DescribeText, InvoicingDescription	
	from [LCA].[dboReaders].[VW_CommercialInvoice_FabricContent_Ver2]  with (nolock)
	where RowN = 1
) AS FabCont

CREATE INDEX Style_TB_ContentFabric ON #TB_ContentFabric (Style)

SELECT DISTINCT 
		[ManufactureID]
INTO #TB_MOS_FOR_SUMMARY_GROUP
FROM(
	SELECT DISTINCT [RO_ID] AS [ManufactureID]  FROM AppsLCA.dbo.ImportExport_AnexoFacturacion WITH(NOLOCK) WHERE RO_ID IS NOT NULL AND Waybill = @WayBill
	UNION ALL
	SELECT DISTINCT [ManufactureID] AS [ManufactureID]  FROM AppsLCA.dbo.ImportExport_AnexoFacturacion WITH(NOLOCK) WHERE ManufactureID IS NOT NULL AND Waybill = @WayBill
)AS TB

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

SET @TransferVal = (SELECT COUNT(*) FROM #TB_Transfer_Kardex)

--- UPDATE a Import para que no vayan campos vacíos

UPDATE TI SET
	ArrivalDate = CD.ArrivalDate
	,DepartureDate = CD.DepartureDate
	,DestinationPort = CD.DeparturePort
	,PortOfLoading = CD.ArrivalPort
	--select *
FROM AppsLCA.dbo.TB_Transfer_Import_Duty AS TI
INNER JOIN LCA.dbo.CustomDeclarations as CD WITH(NOLOCK) ON TI.CustomDeclarationID = CD.CustomDeclarationID
WHERE ManufactureID IN
(SELECT DISTINCT RO_ID FROM AppsLCA.dbo.TB_Transfer_Kardex_Duty WITH(NOLOCK) WHERE Waybill = @WayBill)
AND TI.DepartureDate IS NULL

--- Pre ingreso de datos en #TB_DataCI para evitar contar cajas 2 veces

	SELECT  
		 [Entry#]          		 	= 	CAST(NULL AS VARCHAR(200))
		,[EntryDate]       		 	= 	CAST(NULL AS DATE)
		,[Material]        		 	= 	CAST(NULL AS VARCHAR(100))
		,[Percentage]      		 	= 	CAST(NULL AS FLOAT)
		,[ArticleTypeRaw]  		 	= 	CAST(NULL AS VARCHAR(100))
		,[GroupType]       		 	= 	CAST(NULL AS VARCHAR(100))
		,[GarmentType]     		 	= 	CAST(NULL AS VARCHAR(100))
		,[InvoicingGroupKelly]     	= 	CAST(NULL AS VARCHAR(200))
		,[ManufacturerGroupKelly]   = 	CAST(NULL AS VARCHAR(200))
		,[LineGroupKelly]   		= 	CAST(NULL AS INT)
		,[TypeData]					=	'CommercialInvoice'
		,[ShipDate]					=	WB99.[ShipDate]				
		,[Waybill]					=	WB99.[Waybill]				
		,[Container]				=	WB99.[Container]			
		,[InvoiceBatch]				=	WB99.[InvoiceBatch]			
		,[Batch]					=	WB99.[Batch]				
		,[PONumber]					=	WB99.[PONumber]				
		,[BoxNumber]				=	WB99.[BoxNumber]			
		,[FormattedBoxNumber]		=	WB99.[FormattedBoxNumber]	
		,[StyleNumber]				=	WB99.[StyleNumber]			
		,[StyleColor]				=	WB99.[StyleColor]			
		,[Size]						=	WB99.[Size]					
		,[PalletNumber]				=	WB99.[PalletNumber]			
		,[Price]					=	WB99.[Price]				
		,[BasePrice]				=	WB99.[BasePrice]			
		,[Screen_Print]				=	WB99.[Screen_Print]			
		,[Total_Screen_Print]		=	WB99.[Total_Screen_Print]	
		,[Embroidery]				=	WB99.[Embroidery]			
		,[Total_Embroidery]			=	WB99.[Total_Embroidery]		
		,[Sublimation]				=	WB99.[Sublimation]			
		,[Total_Sublimation]		=	WB99.[Total_Sublimation]	
		,[DecorationSP]				=	WB99.[DecorationSP]			
		,[DecorationEMB]			=	WB99.[DecorationEMB]		
		,[DecorationSUB]			=	WB99.[DecorationSUB]		
		,[DecorationPack]			=	WB99.[DecorationPack]	
		,[DecorationDesc]			=	CASE 
											WHEN WB99.[DecorationSP] IS NOT NULL AND WB99.[DecorationEMB] IS NOT NULL AND WB99.[DecorationSUB] IS NOT NULL 
												THEN CONCAT(WB99.[DecorationSP],'/',WB99.[DecorationEMB],'/',WB99.[DecorationSUB])
											WHEN WB99.[DecorationSP] IS NOT NULL AND WB99.[DecorationEMB] IS NOT NULL
												THEN CONCAT(WB99.[DecorationSP],'/',WB99.[DecorationEMB])
											WHEN WB99.[DecorationSP] IS NOT NULL AND WB99.[DecorationSUB] IS NOT NULL
												THEN CONCAT(WB99.[DecorationSP],'/',WB99.[DecorationSUB])
											WHEN WB99.[DecorationSUB] IS NOT NULL AND WB99.[DecorationEMB] IS NOT NULL
												THEN CONCAT(WB99.[DecorationEMB],'/',WB99.[DecorationSUB])
											WHEN WB99.[DecorationSP] IS NOT NULL
												THEN WB99.[DecorationSP]
											WHEN WB99.[DecorationEMB] IS NOT NULL
												THEN WB99.[DecorationEMB]
											WHEN WB99.[DecorationSUB] IS NOT NULL
												THEN WB99.[DecorationSUB]
											WHEN WB99.[DecorationPack] IS NOT NULL
												THEN WB99.[DecorationPack]
										END
		,[UnitDecorationExport]		=	WB99.[UnitDecorationExport]	
		,[UnitDecorationValue]		=	WB99.[UnitDecorationValue]	
		,[TotalDecorationExport]	=	WB99.[TotalDecorationExport]
		,[TotalDecorationValue]		=	WB99.[TotalDecorationValue]	
		,[TotalExport]				=	WB99.[TotalExport]			
		,[TotalPrice]				=	WB99.[TotalPrice]			
		,[TotalBlankPrice]			=	WB99.[TotalBlankPrice]			
		,[TotalFobValue]			=	WB99.[TotalFobValue]		
		,[Freight]					=	WB99.[Freight]
		,[CA_HTSCode]				=	WB99.[CA_HTSCode]
		,[CA_HTSDescription]		=	WB99.[CA_HTSDescription]
		,[US_HTSCode]				=	WB99.[US_HTSCode]
		,[US_HTSDescription]		=	WB99.[US_HTSDescription]	
		,[InvoicingDescription]		=	WB99.[InvoicingDescription]		
		,[GrossWeightKGSXUnits]		=	WB99.[GrossWeightKGSXUnits]	
		,[Quantity]					=	WB99.[Quantity]				
		,[Manufacturer]				=	WB99.[Manufacturer]			
		,[CountryOfOrigin]			=	WB99.[CountryOfOrigin]		
		,[ProductDivision]			=	WB99.[ProductDivision]		
		,[US_HTSCode2]				=	WB99.[US_HTSCode2]			
		,[TariffCategory]			=	CAST(NULL AS VARCHAR(100))
		,[RO_ID]					=	WB99.[RO_ID]			
		,[RO]						=	WB99.[RO]				
		,[ManufactureID]			=	WB99.[ManufactureID]	
		,[MO]						=	WB99.[MO]				
		,[IDExport] 				=	WB99.[IDExport]
		,[IDImport] 				=	CAST(NULL AS INT)
		,[IDKardex] 				=	CAST(NULL AS INT)
		,[IM5]						=	CAST(NULL AS VARCHAR(100))
		,[DeclarationDate]			=	CAST(NULL AS DATE)
		,[ArrivalDate]				=	CAST(NULL AS DATE)
		,[DepartureDate]			=	CAST(NULL AS DATE)
		,[PortOfLoading]			=	CAST(NULL AS VARCHAR(100))
		,[Cafta]					=	CAST(NULL AS VARCHAR(10))
		,[Orden]					=	CAST(NULL AS INT)
		,[GroupBox]					=	ROW_NUMBER() OVER(PARTITION BY WB99.[FormattedBoxNumber] ORDER BY WB99.[FormattedBoxNumber])
		,[GroupPallet]				=	ROW_NUMBER() OVER (PARTITION BY WB99.[PalletNumber] ORDER BY WB99.[PalletNumber])
		,[DocumentID]				=	CAST(NULL AS VARCHAR(100))
		,[Key1] 					= 	CONCAT(StyleNumber , '-' , StyleColor , '-' , [Size])
		,[Key2] 					= 	CONCAT(StyleNumber , '-' , StyleColor )
		,[Key3] 					= 	CONCAT(StyleNumber  ,'')
	INTO #TB_DataCI
	FROM 
	(
		SELECT 
			 [ShipDate]					=	SB.[ShipDate]
			,[Waybill]					=	SB.[Waybill]
			,[Container]				=	SB.[Container]
			,[InvoiceBatch]				=	SB.[InvoiceBatch]
			,[Batch]					=	SB.[Batch]
			,[PONumber]					=	SB.[PONumber]
			,[BoxNumber]				=	SB.[BoxNumber]
			,[FormattedBoxNumber]		=	TB_GROUP.[FormattedBoxNumber]			
			,[StyleNumber]				=	SB.[StyleNumber]
			,[StyleColor]				=	SB.[StyleColor]
			,[Size]						=	SB.[Size]
			,[PalletNumber]				=	TB_GROUP.[PalletNumber]
			,[Price]					=	SB.[Price]
			,[BasePrice]				=	SB.[BasePrice]
			,[Screen_Print]				=	SB.Screen_Print
			,[Total_Screen_Print]		=	SB.Total_Screen_Print
			,[Embroidery]				=	SB.Embroidery
			,[Total_Embroidery]			=	SB.Total_Embroidery
			,[Sublimation]				=	SB.Sublimation
			,[Total_Sublimation]		=	SB.Total_Sublimation
			,[DecorationSP]				=	CASE WHEN SB.[Screen_Print] > 0 THEN 'SCREENPRINT' ELSE NULL END
			,[DecorationEMB]			=	CASE WHEN SB.[Embroidery] > 0 THEN 'EMBROIDERY' ELSE NULL END
			,[DecorationSUB]			=	CASE WHEN SB.[Sublimation] > 0 THEN 'SUBLIMATION' ELSE NULL END
			,[DecorationPack]			=	CASE WHEN SB.[Sublimation] = 0 AND SB.[Embroidery] = 0 AND SB.[Screen_Print] = 0 THEN 'PACKAGING AND LABELING' ELSE NULL END
			,[UnitDecorationExport]		= 	COALESCE(SB.Screen_Print,0)  + COALESCE(SB.Embroidery,0) + COALESCE(SB.Sublimation,0)
			,[UnitDecorationValue]		= 	COALESCE(SB.Screen_Print,0)  + COALESCE(SB.Embroidery,0) + COALESCE(SB.Sublimation,0)
			,[TotalDecorationExport]	=	(COALESCE(SB.Total_Screen_Print,0) + COALESCE(SB.Total_Embroidery,0) + COALESCE(SB.Total_Sublimation,0))
			,[TotalDecorationValue]		=	(COALESCE(SB.Total_Screen_Print,0) + COALESCE(SB.Total_Embroidery,0) + COALESCE(SB.Total_Sublimation,0))
			,[TotalExport]				=	SB.Total$
			,[TotalPrice]				=	SB.Price * CASE 
															WHEN TK.IDExport IS NOT NULL THEN 0
															ELSE SB.Qty
														END
			,[TotalBlankPrice]			=	SB.BasePrice * CASE 
																WHEN TK.IDExport IS NOT NULL THEN 0
																ELSE SB.Qty
															END
			,[TotalFobValue]			=	(SB.Price * CASE 
															WHEN TK.IDExport IS NOT NULL THEN 0
															ELSE SB.Qty
														END) 
											- (CASE 
													WHEN CHARINDEX('FG',SB.SeasonName) > 0 AND SB.Waybill LIKE 'AIR%' AND SB.ShipDate >= '2025-11-21' THEN 0.64
														ELSE 0.25
												END * CASE 
																WHEN TK.IDExport IS NOT NULL THEN 0
																ELSE SB.Qty
															END
												)
			,[Freight]					=	CASE 
												WHEN CHARINDEX('FG',SB.SeasonName) > 0 AND SB.Waybill LIKE 'AIR%' AND SB.ShipDate >= '2025-11-21' THEN 0.64
												ELSE 0.25
										  	END
			,[CA_HTSCode]				=	case 
												when lmn.CA_HTSCode is not null then lmn.CA_HTSCode
												when lmn.CA_HTSCode is null and lmn.US_HTSCode is not null then lmn.US_HTSCode
												else   SB.[SAC] 
											end
			,[CA_HTSDescription]		=	SB.[HTSDescription]
			,[US_HTSCode]				=	case 
												when lmn.US_HTSCode is not null then lmn.US_HTSCode
												when lmn.US_HTSCode is null and lmn.CA_HTSCode is not null then lmn.CA_HTSCode
												else   TB_GROUP.[US_HTSCode] 
											end 
			,[US_HTSDescription]		=	TB_GROUP.US_HTSDescription
			,[InvoicingDescription]		=	case 
												when SB.ManufactureID is not null 
														and (FabCont.DescribeText is not null or FabCont.InvoicingDescription is not null)
														then  concat(FabCont.DescribeText, ' ',FabCont.InvoicingDescription)
												when FabCont2.DescribeText is not null or FabCont2.InvoicingDescription is not null
														then  concat(FabCont2.DescribeText, ' ',FabCont2.InvoicingDescription)
												else TB_GROUP.[InvoicingDescription]
											end
			,[GrossWeightKGSXUnits]		=	ROUND(SB.[Gross_Weight_kgs],3)
			,[Quantity]					=	CASE 
												WHEN TK.IDExport IS NOT NULL THEN 0
												ELSE SB.Qty
											END
			,[Manufacturer]				=	COALESCE(SB.Manufacturer, TB_MO_02.Manufacturer,TB_MO_2.Manufacturer)
			,[CountryOfOrigin]			=	COALESCE(SB.CountryOfOrigin, TB_MO_02.CountryOfOrigin,TB_MO_2.CountryOfOrigin)
			,[ProductDivision]			=	ST.Comments9
			,[US_HTSCode2]				=	case 
												when ST.Comments9 not like '%Head%' then HTS.US_HTSCode 
												else null 
											end 
			,[TariffCategory]			=	case 
												when TB_MO_02.TariffCategory is not null or TB_MO_2.TariffCategory is not null
													then COALESCE(
															TRIM(REPLACE(REPLACE(REPLACE(REPLACE(TB_MO_02.TariffCategory, CHAR(10), ''), CHAR(9), ''), CHAR(13), ''),CHAR(32),''))
															,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(TB_MO_2.TariffCategory, CHAR(10), ''), CHAR(9), ''), CHAR(13), ''),CHAR(32),''))
															)
												else TRIM(REPLACE(REPLACE(REPLACE(REPLACE(TMO_APri.comments16, CHAR(10), ''), CHAR(9), ''), CHAR(13), ''),CHAR(32),''))

											end 
			,[RO_ID]					=	SB.RO_ID
			,[RO]						=	SB.RO
			,[ManufactureID]			=	SB.ManufactureID
			,[MO]						=	SB.MO
			,[IDExport]					=	SB.ID
			--select *
		FROM 
		(
			SELECT  
					WayBill
				,BoxNumber
				,FormattedBoxNumber
				,StyleNumber
				,StyleColor
				,GarmentSize
				,PalletNumber 	=	CASE WHEN Bin IS NOT NULL THEN Bin ELSE PalletNumber END
				,US_HTSCode
				,US_HTSDescription
				,InvoicingDescription
				,GrossWeightKGSXUnits
			FROM [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] with (nolock)
			-- FROM [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] with (nolock)
			WHERE WayBill IN (@WayBill) --'AIR20240409'
			-- AND BoxNumber = '01160749'
			GROUP BY WayBill 
					,BoxNumber
					,FormattedBoxNumber
					,StyleNumber
					,StyleColor
					,GarmentSize
					,PalletNumber
					,Bin
					,US_HTSCode
					,US_HTSDescription
					,InvoicingDescription
					,GrossWeightKGSXUnits
		) AS TB_GROUP
		INNER JOIN	[AppsLCA].[dbo].[ImportExport_AnexoFacturacion]		AS SB	WITH(NOLOCK)	ON SB.Waybill = TB_GROUP.WayBill AND SB.BoxNumber = TB_GROUP.BoxNumber 
		-- INNER JOIN	[AppsLCA].[dbo].[ImportExport_AnexoFacturacion]		AS SB	WITH(NOLOCK)	ON SB.Waybill = TB_GROUP.WayBill AND SB.BoxNumber = TB_GROUP.BoxNumber 
																																	AND SB.StyleNumber = TB_GROUP.StyleNumber 
																																	AND SB.StyleColor = TB_GROUP.StyleColor
																																	AND SB.Size = TB_GROUP.GarmentSize
		left outer join (Select * from 
								(select Color, Style, CA_HTSCode, US_HTSCode from 
												(select RW.PartNumber, RW.HTSCodeID, Col.ColorName as Color, CL.ComponentName as Style,
												DRD.DropDownValue as CA_HTSCode, DRD.Description3 as US_HTSCode	,
												row_number() over(partition by Col.ColorName, CL.ComponentName order by Col.ColorName, CL.ComponentName) as Cuenta
													FROM [LCA].[dbo].[RawMaterials]  RW with (nolock)
													left outer join lca.dbo.Colors COL with (nolock)
														on RW.ColorID = Col.ColorID
													left outer join lca.dbo.ComponentLibrary CL with (nolock)
														on RW.ComponentID = CL.ComponentID and CL.ComponentCategoryID=11
													left outer join lca.dbo.DropDownValues DRD with (nolock)
														on RW.HTSCodeID = DRD.DropDownValueID
													where Cl.ComponentName is not null and Col.ColorName is not null and RW.HTSCodeID is not null
												) abc123 where Cuenta=1
								) fgh
						) lmn	on SB.StyleNumber = lmn.Style and SB.StyleColor=lmn.Color

		left outer join lca.dbo.ManufactureOrders TMO_APri with (nolock) 
				ON SB.ManufactureID = TMO_APri.manufactureid
		left outer join lca.dbo.OrderItems ODT_PRI with (nolock)
				on TMO_APri.FirstOrderItemID = ODT_PRI.OrderItemID   and
					TMO_APri.OrderID = ODT_PRI.OrderID 
		LEFT JOIN LCA.dbo.Styles AS ST WITH(NOLOCK) ON ODT_PRI.StyleID = ST.StyleID

		LEFT JOIN LCA.dbo.Styles AS BST WITH(NOLOCK) ON BST.StyleID = ST.BlankStyleID
		
		left outer join lca.dbo.HTSStyleCodes HTS with (nolock) on st.HTSStyleCodeID = HTS.HTSStyleCodeID 
		
		left outer join #TB_ContentFabric AS FabCont
				on BST.StyleNumber = FabCont.Style and SB.StyleColor = FabCont.StyleColorName

		left outer join #TB_ContentFabric AS  FabCont2
				on SB.StyleNumber = FabCont2.Style and SB.StyleColor = FabCont2.StyleColorName
		
		left outer join 
		(
			select ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category,Style,Size
				from 
					(
						select ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category,Style,Size,
							row_number() over(Partition by Manufactureid, Size 
							order by  Manufactureid, Size, Consumption desc )
							as Ncuenta
						from appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
						where (Size is not null and rtrim(Size)<>'')
						--and mo in('RO123021CCW115-837-5','TO1018CCW115-837-1')  --='EO3902696-BKH' mo='EO3774316-LBL'
							group by ManufactureId, 
								CountryOfOrigin , 
								Manufacturer,
								TariffCategory,
								Category,
								Style, Size, Consumption
					) TB_MO_01
				where Ncuenta=1
		) TB_MO_02
		ON SB.RO_ID = TB_MO_02.ManufactureID and
			SB.StyleNumber = TB_MO_02.Style and
			SB.Size = TB_MO_02.Size

		left outer join 
				(select distinct ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category
				,ROW_NUMBER() OVER(PARTITION BY ManufactureID ORDER BY ManufactureID, Consumption desc) as cuenta2
					from 
						(	Select * from (
											select *,row_number() over (partition by Manufactureid order by Manufactureid, consumption desc ) as Cuenta
													from appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
											where (Size is null or rtrim(Size)='') and category='Fabric'
											--and mo in ('RO123021CCW115-837-5','TO1018CCW115-837-1')
										) SubFabric01 where Cuenta =1
							union all
					
							SELECT * FROM (
											select *, row_number() over (partition by Manufactureid order by Manufactureid, consumption desc ) as Cuenta
											from appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
											where (Size is null or rtrim(Size)='') and category='Contracts'
											--and mo in ('RO123021CCW115-837-5','TO1018CCW115-837-1')
											)SubContract WHERE Cuenta =1
						) TB_MO_1
					--where TB_MO_1.ncuenta=1
				) TB_MO_2
				ON SB.ManufactureID = TB_MO_2.ManufactureID and cuenta2 = 1

			LEFT JOIN #TB_Transfer_Kardex AS TK ON SB.ID = TK.IDExport

	) AS WB99
	WHERE Quantity > 0

--- Pre ingreso de datos en #TB_Transfer para evitar contar cajas 2 veces
	
	SELECT 
		 [Entry#]          		 	= 	CAST(NULL AS VARCHAR(200))
		,[EntryDate]       		 	= 	CAST(NULL AS DATE)
		,[Material]        		 	= 	CAST(NULL AS VARCHAR(100))
		,[Percentage]      		 	= 	CAST(NULL AS FLOAT)
		,[ArticleTypeRaw]  		 	= 	CAST(NULL AS VARCHAR(100))
		,[GroupType]       		 	= 	CAST(NULL AS VARCHAR(100))
		,[GarmentType]     		 	= 	CAST(NULL AS VARCHAR(100))
		,[InvoicingGroupKelly]     	= 	CAST(NULL AS VARCHAR(200))
		,[ManufacturerGroupKelly]   = 	CAST(NULL AS VARCHAR(200))
		,[LineGroupKelly]   		= 	CAST(NULL AS INT)
		,[TypeData]					=	'DeclarationExport'
		,[ShipDate]					=	WB99.[ShipDate]				
		,[Waybill]					=	WB99.[Waybill]				
		,[Container]				=	WB99.[Container]			
		,[InvoiceBatch]				=	WB99.[InvoiceBatch]			
		,[Batch]					=	WB99.[Batch]				
		,[PONumber]					=	WB99.[PONumber]				
		,[BoxNumber]				=	WB99.[BoxNumber]			
		,[FormattedBoxNumber]		=	WB99.[FormattedBoxNumber]	
		,[StyleNumber]				=	WB99.[StyleNumber]			
		,[StyleColor]				=	WB99.[StyleColor]			
		,[Size]						=	WB99.[Size]					
		,[PalletNumber]				=	WB99.[PalletNumber]			
		,[Price]					=	WB99.[Price]				
		,[BasePrice]				=	WB99.[BasePrice]			
		,[Screen_Print]				=	WB99.[Screen_Print]			
		,[Total_Screen_Print]		=	WB99.[Total_Screen_Print]	
		,[Embroidery]				=	WB99.[Embroidery]			
		,[Total_Embroidery]			=	WB99.[Total_Embroidery]		
		,[Sublimation]				=	WB99.[Sublimation]			
		,[Total_Sublimation]		=	WB99.[Total_Sublimation]	
		,[DecorationSP]				=	WB99.[DecorationSP]			
		,[DecorationEMB]			=	WB99.[DecorationEMB]		
		,[DecorationSUB]			=	WB99.[DecorationSUB]		
		,[DecorationPack]			=	WB99.[DecorationPack]		
		,[DecorationDesc]			=	CASE 
											WHEN WB99.[DecorationSP] IS NOT NULL AND WB99.[DecorationEMB] IS NOT NULL AND WB99.[DecorationSUB] IS NOT NULL 
												THEN CONCAT(WB99.[DecorationSP],'/',WB99.[DecorationEMB],'/',WB99.[DecorationSUB])
											WHEN WB99.[DecorationSP] IS NOT NULL AND WB99.[DecorationEMB] IS NOT NULL
												THEN CONCAT(WB99.[DecorationSP],'/',WB99.[DecorationEMB])
											WHEN WB99.[DecorationSP] IS NOT NULL AND WB99.[DecorationSUB] IS NOT NULL
												THEN CONCAT(WB99.[DecorationSP],'/',WB99.[DecorationSUB])
											WHEN WB99.[DecorationSUB] IS NOT NULL AND WB99.[DecorationEMB] IS NOT NULL
												THEN CONCAT(WB99.[DecorationEMB],'/',WB99.[DecorationSUB])
											WHEN WB99.[DecorationSP] IS NOT NULL
												THEN WB99.[DecorationSP]
											WHEN WB99.[DecorationEMB] IS NOT NULL
												THEN WB99.[DecorationEMB]
											WHEN WB99.[DecorationSUB] IS NOT NULL
												THEN WB99.[DecorationSUB]
											WHEN WB99.[DecorationPack] IS NOT NULL
												THEN WB99.[DecorationPack]
										END
		,[UnitDecorationExport]		=	WB99.[UnitDecorationExport]	
		,[UnitDecorationValue]		=	WB99.[UnitDecorationValue]	
		,[TotalDecorationExport]	=	WB99.[TotalDecorationExport]
		,[TotalDecorationValue]		=	WB99.[TotalDecorationValue]	
		,[TotalExport]				=	WB99.[TotalExport]			
		,[TotalPrice]				=	WB99.[TotalPrice]			
		,[TotalBlankPrice]			=	WB99.[TotalBlankPrice]			
		,[TotalFobValue]			=	WB99.[TotalFobValue]		
		,[Freight]					=	WB99.[Freight]
		,[CA_HTSCode]				=	WB99.[CA_HTSCode]
		,[CA_HTSDescription]		=	WB99.[CA_HTSDescription]
		,[US_HTSCode]				=	WB99.[US_HTSCode]
		,[US_HTSDescription]		=	WB99.[US_HTSDescription]	
		,[InvoicingDescription]		=	WB99.[InvoicingDescription]		
		,[GrossWeightKGSXUnits]		=	WB99.[GrossWeightKGSXUnits]	
		,[Quantity]					=	WB99.[Quantity]				
		,[Manufacturer]				=	WB99.[Manufacturer]			
		,[CountryOfOrigin]			=	WB99.[CountryOfOrigin]		
		,[ProductDivision]			=	WB99.[ProductDivision]		
		,[US_HTSCode2]				=	WB99.[US_HTSCode2]			
		,[TariffCategory]			=	CAST(NULL AS VARCHAR(100))
		,[RO_ID]					=	WB99.[RO_ID]			
		,[RO]						=	WB99.[RO]				
		,[ManufactureID]			=	WB99.[ManufactureID]	
		,[MO]						=	WB99.[MO]				
		,[IDExport] 				=	WB99.[IDExport] 		
		,[IDImport] 				=	WB99.[IDImport] 		
		,[IDKardex] 				=	WB99.[IDKardex] 		
		,[IM5]						=	WB99.[IM5]				
		,[DeclarationDate]			=	WB99.[DeclarationDate]	
		,[ArrivalDate]				=	WB99.[ArrivalDate]		
		,[DepartureDate]			=	WB99.[DepartureDate]	
		,[PortOfLoading]			=	WB99.[PortOfLoading]	
		,[Cafta]					=	CAST(NULL AS VARCHAR(100))
		,[Orden]					=	3
		,[GroupBox]					=	ROW_NUMBER() OVER(PARTITION BY WB99.[FormattedBoxNumber] ORDER BY WB99.[FormattedBoxNumber])
		,[GroupPallet]				=	ROW_NUMBER() OVER (PARTITION BY WB99.[PalletNumber] ORDER BY WB99.[PalletNumber])
		,[DocumentID]				=	CONCAT(WB99.Waybill,'.9802')
		,[Key1] 					= CONCAT(StyleNumber , '-' , StyleColor , '-' , [Size])
		,[Key2] 					= CONCAT(StyleNumber , '-' , StyleColor )
		,[Key3] 					= CONCAT(StyleNumber  ,'')
	INTO #TB_Transfer
	FROM
	(
		SELECT 
			[ShipDate]					=	TE.[ShipDate]
			,[Waybill]					=	TE.[Waybill]
			,[Container]				=	TB_GROUP.[Container]
			,[InvoiceBatch]				=	TE.[InvoiceBatch]
			,[Batch]					=	TE.[Batch]
			,[PONumber]					=	TE.[PONumber]
			,[BoxNumber]				=	TE.[BoxNumber]
			,[FormattedBoxNumber]		=	TB_GROUP.[FormattedBoxNumber]
			,[StyleNumber]				=	TE.[StyleNumber]
			,[StyleColor]				=	TE.[StyleColor]
			,[Size]						=	TE.[Size]
			,[PalletNumber]				=	TB_GROUP.[PalletNumber]
			,[Price]					=	TE.[Price]
			,[BasePrice]				=	SB.[BasePrice]
			,[Screen_Print]				=	SB.Screen_Print
			,[Total_Screen_Print]		=	SB.Total_Screen_Print
			,[Embroidery]				=	SB.Embroidery
			,[Total_Embroidery]			=	SB.Total_Embroidery
			,[Sublimation]				=	SB.Sublimation
			,[Total_Sublimation]		=	SB.Total_Sublimation
			,[DecorationSP]				=	CASE WHEN COALESCE(SB.[Screen_Print],0) > 0 THEN 'SCREENPRINT' ELSE NULL END
			,[DecorationEMB]			=	CASE WHEN COALESCE(SB.[Embroidery],0) > 0 THEN 'EMBROIDERY' ELSE NULL END
			,[DecorationSUB]			=	CASE WHEN COALESCE(SB.[Sublimation],0) > 0 THEN 'SUBLIMATION' ELSE NULL END
			,[DecorationPack]			=	CASE WHEN COALESCE(SB.[Sublimation],0) = 0 AND COALESCE(SB.[Embroidery],0) = 0 AND COALESCE(SB.[Screen_Print],0) = 0 THEN 'PACKAGING AND LABELING' ELSE NULL END
			,[UnitDecorationExport]		= 	COALESCE(SB.Screen_Print,0)  + COALESCE(SB.Embroidery,0) + COALESCE(SB.Sublimation,0)
			,[UnitDecorationValue]		=	IIF(COALESCE(TE.[Unit Decoration],0) = 0,0.00,TE.[Unit Decoration]) 
			,[TotalDecorationExport]	=	(COALESCE(SB.Total_Screen_Print,0) + COALESCE(SB.Total_Embroidery,0) + COALESCE(SB.Total_Sublimation,0))
			,[TotalDecorationValue]		=	(TK.QtyExport * COALESCE(TE.[Unit Decoration],0.00)) + IIF(COALESCE(TE.[Unit Decoration],0.00) = 0.00 OR COALESCE(TE.[Unit Decoration],0.00) IS NULL, (TK.QtyExport * 0.08) , 0)
			,[TotalExport]				=	TE.Total$
			,[TotalPrice]				=	TE.Price * TK.QtyExport
			,[TotalBlankPrice]			=	TE.BasePrice * TK.QtyExport
			,[TotalFobValue]			=	(TE.Price * TK.QtyExport) 
			
											- ( CASE 
													WHEN CHARINDEX('FG',SB.SeasonName) > 0 AND SB.Waybill LIKE 'AIR%' AND SB.ShipDate >= '2025-11-21' THEN 0.64
													ELSE 0.25
										  		END * TK.QtyExport)
			,[Freight]					= 	CASE 
												WHEN CHARINDEX('FG',SB.SeasonName) > 0 AND SB.Waybill LIKE 'AIR%' AND SB.ShipDate >= '2025-11-21' THEN 0.64
												ELSE 0.25
											END
			,[CA_HTSCode]				=	case 
												when lmn.CA_HTSCode is not null then lmn.CA_HTSCode
												when lmn.CA_HTSCode is null and lmn.US_HTSCode is not null then lmn.US_HTSCode
												else   SB.[SAC] 
											end
			,[CA_HTSDescription]		=	TE.[HTSDescription]
			,[US_HTSCode]				=	case 
												when lmn.US_HTSCode is not null then lmn.US_HTSCode
												when lmn.US_HTSCode is null and lmn.CA_HTSCode is not null then lmn.CA_HTSCode
												else   TB_GROUP.[US_HTSCode] 
											end 
			,[US_HTSDescription]		=	TB_GROUP.US_HTSDescription
			,[InvoicingDescription]		=	case 
												when TE.ManufactureID is not null 
													and (FabCont.DescribeText is not null or FabCont.InvoicingDescription is not null)
													then  concat(FabCont.DescribeText, ' ',FabCont.InvoicingDescription)
												when FabCont2.DescribeText is not null or FabCont2.InvoicingDescription is not null
													then  concat(FabCont2.DescribeText, ' ',FabCont2.InvoicingDescription)
												else TB_GROUP.[InvoicingDescription]
											end
			,[GrossWeightKGSXUnits]		=	ROUND(SB.[Gross_Weight_kgs],3)
			,[Quantity]					=	TK.QtyExport									
			,[Manufacturer]				=	COALESCE(TI.Manufacturer, TB_MO_02.Manufacturer,TB_MO_2.Manufacturer)
			,[CountryOfOrigin]			=	COALESCE(TI.CountryOfOriginName, TB_MO_02.CountryOfOrigin,TB_MO_2.CountryOfOrigin)
			,[ProductDivision]			=	ST.Comments9 
			,[US_HTSCode2]				=	case 
												when ST.Comments9 not like '%Head%' then HTS.US_HTSCode 
												else null 
											end 
			,[TariffCategory]			=	case 
												when TB_MO_02.TariffCategory is not null or TB_MO_2.TariffCategory is not null
													then COALESCE(
															TRIM(REPLACE(REPLACE(REPLACE(REPLACE(TB_MO_02.TariffCategory, CHAR(10), ''), CHAR(9), ''), CHAR(13), ''),CHAR(32),''))
															,TRIM(REPLACE(REPLACE(REPLACE(REPLACE(TB_MO_2.TariffCategory, CHAR(10), ''), CHAR(9), ''), CHAR(13), ''),CHAR(32),''))
															)
												else TRIM(REPLACE(REPLACE(REPLACE(REPLACE(TMO_APri.comments16, CHAR(10), ''), CHAR(9), ''), CHAR(13), ''),CHAR(32),''))

											end 
			,[RO_ID]					=	SB.RO_ID
			,[RO]						=	SB.RO
			,[ManufactureID]			=	SB.ManufactureID
			,[MO]						=	SB.MO
			,[IDExport] 				=	TE.ID
			,[IDImport] 				=	TK.IDImport
			,[IDKardex] 				=	TK.IDKardex
			,[IM5]						=	TI.IM5
			,[DeclarationDate]			=	TI.DeclarationDate
			,[ArrivalDate]				=	TI.ArrivalDate
			,[DepartureDate]			=	TI.DepartureDate
			,[PortOfLoading]			=	TI.PortOfLoading
		--SELECT *
		FROM 
		(
			SELECT  
				WayBill
				,ContainerNumber AS Container
				,BoxNumber
				,FormattedBoxNumber
				,StyleNumber
				,StyleColor
				,GarmentSize
				,PalletNumber 	=	CASE WHEN Bin IS NOT NULL THEN Bin ELSE PalletNumber END
				,US_HTSCode
				,US_HTSDescription
				,InvoicingDescription
				,GrossWeightKGSXUnits
			FROM [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] with (nolock)
			WHERE WayBill IN (@WayBill) --'AIR20240409'
			-- AND BoxNumber = '01166741'
			GROUP BY WayBill 
					,ContainerNumber
					,BoxNumber
					,FormattedBoxNumber
					,StyleNumber
					,StyleColor
					,GarmentSize
					,PalletNumber
					,Bin
					,US_HTSCode
					,US_HTSDescription
					,InvoicingDescription
					,GrossWeightKGSXUnits
		) AS TB_GROUP
		INNER JOIN  [AppsLCA].[dbo].[ImportExport_AnexoFacturacion]	AS SB	WITH(NOLOCK) ON SB.Waybill = TB_GROUP.WayBill AND SB.BoxNumber = TB_GROUP.BoxNumber 
																																AND SB.StyleNumber = TB_GROUP.StyleNumber 
																																AND SB.StyleColor = TB_GROUP.StyleColor
																																AND SB.Size = TB_GROUP.GarmentSize
		INNER JOIN	[AppsLCA].[dbo].[TB_Transfer_Export_Duty]		AS TE	WITH(NOLOCK)	
																																ON TE.ID = SB.ID
																																AND TE.[status] = 1
		LEFT JOIN #TB_Transfer_Kardex AS TK ON TK.IDExport = TE.ID
		LEFT JOIN [AppsLCA].[dbo].[TB_Transfer_Import_Duty]		AS TI	WITH(NOLOCK)	ON TI.ID = TK.IDImport
																																
		left outer join (Select * from 
								(select Color, Style, CA_HTSCode, US_HTSCode from 
												(select RW.PartNumber, RW.HTSCodeID, Col.ColorName as Color, CL.ComponentName as Style,
												DRD.DropDownValue as CA_HTSCode, DRD.Description3 as US_HTSCode	,
												row_number() over(partition by Col.ColorName, CL.ComponentName order by Col.ColorName, CL.ComponentName) as Cuenta
													FROM [LCA].[dbo].[RawMaterials]  RW with (nolock)
													left outer join lca.dbo.Colors COL with (nolock)
														on RW.ColorID = Col.ColorID
													left outer join lca.dbo.ComponentLibrary CL with (nolock)
														on RW.ComponentID = CL.ComponentID and CL.ComponentCategoryID=11
													left outer join lca.dbo.DropDownValues DRD with (nolock)
														on RW.HTSCodeID = DRD.DropDownValueID
													where Cl.ComponentName is not null and Col.ColorName is not null and RW.HTSCodeID is not null
												) abc123 where Cuenta=1
								) fgh
						) lmn	on TE.StyleNumber = lmn.Style and TE.StyleColor=lmn.Color

		left outer join lca.dbo.ManufactureOrders TMO_APri with (nolock) 
				ON TE.ManufactureID = TMO_APri.manufactureid
		left outer join lca.dbo.OrderItems ODT_PRI with (nolock)
				on TMO_APri.FirstOrderItemID = ODT_PRI.OrderItemID   and
					TMO_APri.OrderID = ODT_PRI.OrderID 
		LEFT JOIN LCA.dbo.Styles AS ST WITH(NOLOCK) ON ODT_PRI.StyleID = ST.StyleID

		LEFT JOIN LCA.dbo.Styles AS BST WITH(NOLOCK) ON BST.StyleID = ST.BlankStyleID
		
		left outer join lca.dbo.HTSStyleCodes HTS with (nolock) on st.HTSStyleCodeID = HTS.HTSStyleCodeID 
		
		left outer join #TB_ContentFabric AS FabCont
				on BST.StyleNumber = FabCont.Style and TE.StyleColor = FabCont.StyleColorName

		left outer join #TB_ContentFabric AS FabCont2
				on TE.StyleNumber = FabCont2.Style and TE.StyleColor = FabCont2.StyleColorName
		
		left outer join 
		(
			select ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category,Style,Size
				from 
					(
						select ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category,Style,Size,
							row_number() over(Partition by Manufactureid, Size 
							order by  Manufactureid, Size, Consumption desc )
							as Ncuenta
						from appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
						where (Size is not null and rtrim(Size)<>'')
						--and mo in('RO123021CCW115-837-5','TO1018CCW115-837-1')  --='EO3902696-BKH' mo='EO3774316-LBL'
							group by ManufactureId, 
								CountryOfOrigin , 
								Manufacturer,
								TariffCategory,
								Category,
								Style, Size, Consumption
					) TB_MO_01
				where Ncuenta=1
		) TB_MO_02
		ON TE.RO_ID = TB_MO_02.ManufactureID and
			TE.StyleNumber = TB_MO_02.Style and
			TE.Size = TB_MO_02.Size

		left outer join 
				(select distinct ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category
				,ROW_NUMBER() OVER(PARTITION BY ManufactureID ORDER BY ManufactureID, Consumption desc) as cuenta2
					from 
						(	Select * from (
											select *,row_number() over (partition by Manufactureid order by Manufactureid, consumption desc ) as Cuenta
													from appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
											where (Size is null or rtrim(Size)='') and category='Fabric'
											-- and ManufactureId = 987592
											--and mo in ('RO123021CCW115-837-5','TO1018CCW115-837-1')
										) SubFabric01 where Cuenta =1
							union all
					
							SELECT * FROM (
											select *, row_number() over (partition by Manufactureid order by Manufactureid, consumption desc ) as Cuenta
											from appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
											where (Size is null or rtrim(Size)='') and category='Contracts'
											-- and ManufactureId = 987592
											--and mo in ('RO123021CCW115-837-5','TO1018CCW115-837-1')
											)SubContract WHERE Cuenta =1
						) TB_MO_1
					--where TB_MO_1.ncuenta=1
				) TB_MO_2
		ON TE.ManufactureID = TB_MO_2.ManufactureID AND cuenta2 = 1
	) WB99
	WHERE Quantity > 0

--- UPDATE para evitar contar cajas 2 veces

UPDATE CI
	SET CI.GroupBox =  CASE WHEN CI.GroupBox = 1 THEN 0 ELSE CI.GroupBox END
FROM #TB_DataCI AS CI
INNER JOIN #TB_Transfer AS TR ON CI.FormattedBoxNumber = TR.FormattedBoxNumber

	------- UPDATE TARIFF CATEGORY DE DATA CI DESDE FAMO SUMMARY --------
		----option 1: RO_ID + Style + Color + Size
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_DataCI  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.RO_ID = F.ManufactureID    AND S.[Key1] = F.[Key1] AND F.Proportion = 1 AND F.RTariffCategoryKey1 = 1
			WHERE S.RO_ID IS NOT NULL
			
			----option 2: RO_ID + Style + Color 
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_DataCI  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.RO_ID = F.ManufactureID    AND S.[Key2] = F.[Key2] AND F.Proportion = 1 AND F.RTariffCategoryKey2 = 1
			WHERE S.RO_ID IS NOT NULL
			
			----option 3: RO_ID + Style
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_DataCI  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.RO_ID = F.ManufactureID    AND S.[Key3] = F.[Key3] AND F.Proportion = 1 AND F.RTariffCategoryKey3 = 1
			WHERE S.RO_ID IS NOT NULL
			
			----option 5: RO_ID
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_DataCI  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.RO_ID = F.ManufactureID    AND S.[Key1] = F.[Key1] AND F.Proportion = 1 AND F.RTariffCategory = 1
			WHERE S.RO_ID IS NOT NULL
						

			----option 1: RO_ID + Style + Color + Size
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_DataCI  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.ManufactureID = F.ManufactureID    AND S.[Key1] = F.[Key1] AND F.Proportion = 1 AND F.RTariffCategoryKey1 = 1
			WHERE S.TariffCategory IS NULL
			
			----option 2: RO_ID + Style + Color 
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_DataCI  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.ManufactureID = F.ManufactureID    AND S.[Key2] = F.[Key2] AND F.Proportion = 1 AND F.RTariffCategoryKey2 = 1
			WHERE S.TariffCategory IS NULL
			
			----option 3: RO_ID + Style
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_DataCI  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.ManufactureID = F.ManufactureID    AND S.[Key3] = F.[Key3] AND F.Proportion = 1 AND F.RTariffCategoryKey3 = 1
			WHERE S.TariffCategory IS NULL
			
			----option 5: RO_ID
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_DataCI  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.ManufactureID = F.ManufactureID    AND F.RTariffCategory = 1 
			WHERE S.TariffCategory IS NULL

	------- UPDATE TARIFF CATEGORY DE DATA TRANSFER DESDE FAMO SUMMARY --------
		UPDATE S SET
			S.TariffCategory = NULL
		FROM #TB_Transfer  AS S
		----option 1: RO_ID + Style + Color + Size
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_Transfer  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.RO_ID = F.ManufactureID    AND S.[Key1] = F.[Key1] AND F.Proportion = 1 AND F.RTariffCategoryKey1 = 1
			WHERE S.RO_ID IS NOT NULL
			
			----option 2: RO_ID + Style + Color 
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_Transfer  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.RO_ID = F.ManufactureID    AND S.[Key2] = F.[Key2] AND F.Proportion = 1 AND F.RTariffCategoryKey2 = 1
			WHERE S.RO_ID IS NOT NULL
			
			----option 3: RO_ID + Style
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_Transfer  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.RO_ID = F.ManufactureID    AND S.[Key3] = F.[Key3] AND F.Proportion = 1 AND F.RTariffCategoryKey3 = 1
			WHERE S.RO_ID IS NOT NULL
			
			----option 5: RO_ID
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_Transfer  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.RO_ID = F.ManufactureID    AND S.[Key1] = F.[Key1] AND F.Proportion = 1 AND F.RTariffCategory = 1
			WHERE S.RO_ID IS NOT NULL
						

			----option 1: RO_ID + Style + Color + Size
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_Transfer  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.ManufactureID = F.ManufactureID    AND S.[Key1] = F.[Key1] AND F.Proportion = 1 AND F.RTariffCategoryKey1 = 1
			WHERE S.TariffCategory IS NULL
			
			----option 2: RO_ID + Style + Color 
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_Transfer  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.ManufactureID = F.ManufactureID    AND S.[Key2] = F.[Key2] AND F.Proportion = 1 AND F.RTariffCategoryKey2 = 1
			WHERE S.TariffCategory IS NULL
			
			----option 3: RO_ID + Style
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_Transfer  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.ManufactureID = F.ManufactureID    AND S.[Key3] = F.[Key3] AND F.Proportion = 1 AND F.RTariffCategoryKey3 = 1
			WHERE S.TariffCategory IS NULL
			
			----option 5: RO_ID
			UPDATE S SET
				[TariffCategory] = F.TariffCategory
			FROM #TB_Transfer  AS S
			INNER JOIN #TB_FAMO_SUMMARY     AS F ON S.ManufactureID = F.ManufactureID    AND F.RTariffCategory = 1 
			WHERE S.TariffCategory IS NULL

	------- UPDATE DE CAMPOS QUE DEPENDEN DEL TARIFF CATEGORY ----------
		UPDATE S SET
			 [Cafta]					=	CASE WHEN S.[TariffCategory] ='CAFTA' THEN 'Y' 	ELSE 'N' END
			,[Orden]					=	CASE WHEN S.[TariffCategory] ='CAFTA' THEN 1 	ELSE 2 END
			,[DocumentID]				=	CASE WHEN S.[TariffCategory] ='CAFTA' THEN CONCAT(S.[Waybill],'.C') ELSE CONCAT(S.[Waybill],'.NC') END
		FROM #TB_DataCI  AS S

		UPDATE S SET
			 [Cafta]					=	CASE WHEN S.[TariffCategory] ='CAFTA' THEN 'Y' 	ELSE 'N' END
		FROM #TB_Transfer  AS S
		
	
--- UPDATE agrupación para Kelly Global Logistics

--- GUARDAMOS PRIMERO EN OTRA TABLA GLOBAL PARA QUE SEA MÁS FÁCIL EL UPDATE

SELECT
[R]	=	ROW_NUMBER() OVER(ORDER BY IDExport,Orden)
,*
INTO #TB_Data_All
FROM
(
	SELECT * FROM #TB_DataCI
	UNION ALL
	SELECT * FROM #TB_Transfer

)TB_ALL

SELECT
    D.R,
    v.Pos AS PosPercent
INTO #Positions
FROM #TB_Data_All AS D
CROSS APPLY (
    SELECT 
        Pos = CHARINDEX('%', D.InvoicingDescription)
    UNION ALL
    SELECT 
        CHARINDEX('%', D.InvoicingDescription, CHARINDEX('%', D.InvoicingDescription) + 1)
    UNION ALL
    SELECT 
        CHARINDEX('%', D.InvoicingDescription, CHARINDEX('%', D.InvoicingDescription, CHARINDEX('%', D.InvoicingDescription) + 1) + 1)
    UNION ALL
    SELECT 
        CHARINDEX('%', D.InvoicingDescription, CHARINDEX('%', D.InvoicingDescription, CHARINDEX('%', D.InvoicingDescription, CHARINDEX('%', D.InvoicingDescription) + 1) + 1) + 1)
) v
WHERE v.Pos > 0;

CREATE INDEX IX_Positions_R ON #Positions(R)

SELECT
    P.R AS R,
    P.PosPercent AS PosPercent,
    PercentageRaw =
        LTRIM(RTRIM(
            SUBSTRING(
                D.InvoicingDescription,
                P.PosPercent - 10,
                10
            )
        )),
    MaterialRaw =
        LTRIM(RTRIM(
            SUBSTRING(
                D.InvoicingDescription,
                P.PosPercent + 1,
                50
            )
        ))
INTO #Extracted
FROM #Positions AS P
JOIN #TB_Data_All AS D ON D.R = P.R

CREATE INDEX IX_Extracted_R ON #Extracted(R)

SELECT
    R,
    Percentage =
        TRY_CAST(
            REVERSE(
                SUBSTRING(
                    REVERSE(PercentageRaw),
                    1,
                    PATINDEX('%[^0-9.]%', REVERSE(PercentageRaw) + 'X') - 1
                )
            ) AS FLOAT
        ),
    Material =
        LTRIM(RTRIM(
            LEFT(MaterialRaw,
                NULLIF(PATINDEX('%[0-9]%', MaterialRaw + '0') - 1, -1)
            )
        ))
INTO #Cleaned
FROM #Extracted

CREATE INDEX IX_Cleaned_R ON #Cleaned(R)

SELECT
    R,
    Percentage,
    CASE
        WHEN Material LIKE 'COT%' OR Material LIKE 'CTTN%' OR Material LIKE '%Cotton%' THEN 'Cotton'
        WHEN Material LIKE '%POLY%' OR Material LIKE 'RAY%' OR Material LIKE 'SPAN%' THEN 'Polyester'
		WHEN Material LIKE '%Nylon%' THEN 'Nylon'
		WHEN Material LIKE '%Acrilyc%' OR Material LIKE '%Acrylic%' THEN 'Acrylic'
        ELSE 'NOT IN CASE'
    END as Material,
	CAST(NULL AS INT)  AS CountMaterial50
INTO #TB_COMPOSITION 
FROM #Cleaned
WHERE Percentage IS NOT NULL AND Material <> ''

UPDATE TC SET
	CountMaterial50 = TBC.CountMaterial
FROM #TB_COMPOSITION AS TC
INNER JOIN
(
	SELECT
		R
		,SUM(CASE 
				WHEN [Percentage] = 50 AND Material = 'Cotton' THEN 1
				WHEN [Percentage] = 50 AND Material = 'Polyester' THEN 1
				ELSE 0
				END) AS CountMaterial
	FROM
	(
		SELECT DISTINCT
			R
			,[Percentage]
			,Material
		FROM #TB_COMPOSITION AS TC
	) AS TB
	GROUP BY R
) AS TBC ON TC.R = TBC.R

UPDATE #TB_COMPOSITION SET Material = 'Polyester' WHERE CountMaterial50 = 2

;WITH MaxComp AS (
    SELECT 
        R,
        Percentage,
        Material,
        ROW_NUMBER() OVER (PARTITION BY R ORDER BY Percentage DESC) AS rn
    FROM #TB_COMPOSITION
)
UPDATE D SET 
    Material = M.Material,
    Percentage = M.Percentage
FROM #TB_Data_All D
JOIN MaxComp M ON D.R = M.R
WHERE M.rn = 1

UPDATE #TB_Data_All SET 
    ArticleTypeRaw =
        CASE 
            WHEN PATINDEX('%[0-9]%', InvoicingDescription) > 0
                THEN LTRIM(RTRIM(
                        LEFT(InvoicingDescription,
                            PATINDEX('%[0-9]%', InvoicingDescription)-1)))
            ELSE InvoicingDescription
        END

UPDATE #TB_Data_All SET 
    GroupType =
        CASE
            WHEN ArticleTypeRaw LIKE 'Men%'     THEN 'Mens'
            WHEN ArticleTypeRaw LIKE 'Women%'   THEN 'Womens'
            WHEN ArticleTypeRaw LIKE 'Boy%'     THEN 'Boys'
            WHEN ArticleTypeRaw LIKE 'Girl%'    THEN 'Girls'
            WHEN ArticleTypeRaw LIKE '%Youth%'                                        THEN 'Youth'
            WHEN ArticleTypeRaw LIKE '%Kid%'                                          THEN 'Kids'
            ELSE NULL
        END

UPDATE #TB_Data_All
SET GarmentType =
    CASE
        WHEN ArticleTypeRaw LIKE '%hood%' THEN 'Hood'
        WHEN ArticleTypeRaw LIKE '%sweatshirt%' THEN 'Sweatshirt'
        WHEN ArticleTypeRaw LIKE '%t-shirt%' OR ArticleTypeRaw LIKE '%t shirt%' THEN 'T-shirt'
        WHEN ArticleTypeRaw LIKE '%polo%' THEN 'Polo'
        WHEN ArticleTypeRaw LIKE '%tank%' THEN 'Tank Top'
        WHEN ArticleTypeRaw LIKE '%pant%' THEN 'Pants'
        WHEN ArticleTypeRaw LIKE '%blanket%' THEN 'Blanket'
        WHEN ArticleTypeRaw LIKE '%hoodie%' THEN 'Hood'
        WHEN ArticleTypeRaw LIKE '%sweater%' THEN 'Sweater'
        WHEN ArticleTypeRaw LIKE '%shirt%' THEN 'Shirt'
        WHEN ArticleTypeRaw LIKE '%Hat%' THEN 'Hat'
        WHEN ArticleTypeRaw LIKE '%Short%' THEN 'Short'
        WHEN ArticleTypeRaw LIKE '%Dress%' THEN 'Dress'
        ELSE 'Other'
    END

UPDATE #TB_Data_All	SET 
	 [InvoicingGroupKelly] 		= CASE 
									WHEN GroupType IS NOT NULL THEN CONCAT(GroupType, ' ', GarmentType, ' ', Material)
									ELSE CONCAT(GarmentType, ' ', Material)
								  END
	,[ManufacturerGroupKelly] 	= CONCAT([Manufacturer], '/', [CountryOfOrigin])

UPDATE TDA SET
	[LineGroupKelly] = TDA2.[Line]
FROM #TB_Data_All AS TDA
LEFT JOIN
(
	SELECT
		
		-- [R_Order] = CI.[R]  -- SOLO PARA ORDEN GLOBAL, NO ES Line
		 [Line] = ROW_NUMBER() OVER(PARTITION BY CI.[DocumentID]
									ORDER BY CI.[Orden])  -- <-- AQUI ORDER = correlativo interno
		, [DocumentID]           	= CI.[DocumentID]  
		, [InvoicingDescription] 	= CI.[InvoicingGroupKelly]            
		, [US_HTSCode]           	= COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode])    
		, [ManufacturerGroupKelly]  = CI.ManufacturerGroupKelly
		, [Orden]                	= CI.[Orden]
	FROM #TB_Data_All as ci
	WHERE Waybill = @WayBill
	GROUP BY  
                CI.[DocumentID]
                , CI.[InvoicingGroupKelly]
                , COALESCE(CI.[US_HTSCode2],CI.[US_HTSCode]) 
                , CI.[ManufacturerGroupKelly]
                , CI.[Orden]

) AS TDA2 ON TDA.InvoicingGroupKelly = TDA2.InvoicingDescription
		 AND TDA.DocumentID = TDA2.DocumentID
		 AND COALESCE(TDA.[US_HTSCode2],TDA.[US_HTSCode])    = TDA2.US_HTSCode
		 AND TDA.ManufacturerGroupKelly = TDA2.ManufacturerGroupKelly
		 AND TDA.Orden = TDA2.Orden 

--- INSERT FINAL EN AMBAS TABLAS

-- DROP TABLE IF EXISTS dbo.CI_Import_Export_CommercialInvoice
-- DROP TABLE IF EXISTS dbo.CI_Import_Export_DeclarationExport

INSERT INTO [192.168.1.93].AppsLCA.dbo.CI_Import_Export_CommercialInvoice
([ShipDate]
      ,[Waybill]
      ,[Container]
      ,[InvoiceBatch]
      ,[Batch]
      ,[PONumber]
      ,[BoxNumber]
      ,[FormattedBoxNumber]
      ,[StyleNumber]
      ,[StyleColor]
      ,[Size]
      ,[PalletNumber]
      ,[Price]
      ,[BasePrice]
      ,[Screen_Print]
      ,[Total_Screen_Print]
      ,[Embroidery]
      ,[Total_Embroidery]
      ,[Sublimation]
      ,[Total_Sublimation]
      ,[DecorationSP]
      ,[DecorationEMB]
      ,[DecorationSUB]
      ,[DecorationPack]
      ,[DecorationDesc]
      ,[UnitDecorationExport]
      ,[UnitDecorationValue]
      ,[TotalDecorationExport]
      ,[TotalDecorationValue]
      ,[TotalExport]
      ,[TotalPrice]
	  ,[TotalBlankPrice]
	  ,[TotalFobValue]
	  ,[Freight]
      ,[CA_HTSCode]
      ,[CA_HTSDescription]
      ,[US_HTSCode]
      ,[US_HTSDescription]
      ,[InvoicingDescription]
      ,[InvoicingGroupKelly]
      ,[ManufacturerGroupKelly]
      ,[LineGroupKelly]
      ,[GrossWeightKGSXUnits]
      ,[Quantity]
      ,[Manufacturer]
      ,[CountryOfOrigin]
      ,[ProductDivision]
      ,[US_HTSCode2]
      ,[TariffCategory]
      ,[RO_ID]
      ,[RO]
      ,[ManufactureID]
      ,[MO]
      ,[IDExport]
      ,[Cafta]
      ,[Orden]
      ,[GroupBox]
      ,[GroupPallet]
      ,[DocumentID])
SELECT  TOP 100 PERCENT 
	   TDC.[ShipDate]
      ,TDC.[Waybill]
      ,TDC.[Container]
      ,TDC.[InvoiceBatch]
      ,TDC.[Batch]
      ,TDC.[PONumber]
      ,TDC.[BoxNumber]
      ,TDC.[FormattedBoxNumber]
      ,TDC.[StyleNumber]
      ,TDC.[StyleColor]
      ,TDC.[Size]
      ,TDC.[PalletNumber]
      ,TDC.[Price]
      ,TDC.[BasePrice]
      ,TDC.[Screen_Print]
      ,TDC.[Total_Screen_Print]
      ,TDC.[Embroidery]
      ,TDC.[Total_Embroidery]
      ,TDC.[Sublimation]
      ,TDC.[Total_Sublimation]
      ,TDC.[DecorationSP]
      ,TDC.[DecorationEMB]
      ,TDC.[DecorationSUB]
      ,TDC.[DecorationPack]
	  ,TDC.[DecorationDesc]
      ,TDC.[UnitDecorationExport]
      ,TDC.[UnitDecorationValue]
      ,TDC.[TotalDecorationExport]
      ,TDC.[TotalDecorationValue]
      ,TDC.[TotalExport]
      ,TDC.[TotalPrice]
      ,TDC.[TotalBlankPrice]
	  ,TDC.[TotalFobValue]
	  ,TDC.[Freight]
      ,TDC.[CA_HTSCode]
      ,TDC.[CA_HTSDescription]
      ,TDC.[US_HTSCode]
      ,TDC.[US_HTSDescription]
      ,TDC.[InvoicingDescription]
      ,TDC.[InvoicingGroupKelly]
	  ,TDC.[ManufacturerGroupKelly]
      ,TDC.[LineGroupKelly]
      ,TDC.[GrossWeightKGSXUnits]
      ,TDC.[Quantity]
      ,TDC.[Manufacturer]
      ,TDC.[CountryOfOrigin]
      ,TDC.[ProductDivision]
      ,TDC.[US_HTSCode2]
      ,TDC.[TariffCategory]
      ,TDC.[RO_ID]
      ,TDC.[RO]
      ,TDC.[ManufactureID]
      ,TDC.[MO]
      ,TDC.[IDExport]
      ,TDC.[Cafta]
      ,TDC.[Orden]
      ,TDC.[GroupBox]
      ,TDC.[GroupPallet]
      ,TDC.[DocumentID]
-- INTO CI_Import_Export_CommercialInvoice
FROM #TB_Data_All AS TDC
where TypeData = 'CommercialInvoice'
ORDER BY 
		 [Orden]
		,[Cafta] DESC
		,[CountryOfOrigin]
		,[StyleNumber]
		,[Container]
		,[US_HTSDescription]
		,[CA_HTSCode]
		,[Price]
		,[InvoicingDescription]
		,[Manufacturer]


IF @TransferVal > 0
BEGIN
	INSERT INTO  [192.168.1.93].AppsLCA.dbo.CI_Import_Export_DeclarationExport
	([ShipDate]
      ,[Waybill]
      ,[Container]
      ,[InvoiceBatch]
      ,[Batch]
      ,[PONumber]
      ,[BoxNumber]
      ,[FormattedBoxNumber]
      ,[StyleNumber]
      ,[StyleColor]
      ,[Size]
      ,[PalletNumber]
      ,[Price]
      ,[BasePrice]
      ,[Screen_Print]
      ,[Total_Screen_Print]
      ,[Embroidery]
      ,[Total_Embroidery]
      ,[Sublimation]
      ,[Total_Sublimation]
      ,[DecorationSP]
      ,[DecorationEMB]
      ,[DecorationSUB]
      ,[DecorationPack]
      ,[DecorationDesc]
      ,[UnitDecorationExport]
      ,[UnitDecorationValue]
      ,[TotalDecorationExport]
      ,[TotalDecorationValue]
      ,[TotalExport]
      ,[TotalPrice]
      ,[TotalBlankPrice]
      ,[TotalFobValue]
	  ,[Freight]
      ,[CA_HTSCode]
      ,[CA_HTSDescription]
      ,[US_HTSCode]
      ,[US_HTSDescription]
      ,[InvoicingDescription]
      ,[InvoicingGroupKelly]
	  ,[ManufacturerGroupKelly]
      ,[LineGroupKelly]
      ,[GrossWeightKGSXUnits]
      ,[Quantity]
      ,[Manufacturer]
      ,[CountryOfOrigin]
      ,[ProductDivision]
      ,[US_HTSCode2]
      ,[TariffCategory]
      ,[RO_ID]
      ,[RO]
      ,[ManufactureID]
      ,[MO]
      ,[IDExport]
      ,[IDImport]
      ,[IDKardex]
      ,[IM5]
      ,[DeclarationDate]
      ,[ArrivalDate]
      ,[DepartureDate]
      ,[PortOfLoading]
      ,[Cafta]
      ,[Orden]
      ,[GroupBox]
      ,[GroupPallet]
      ,[DocumentID])
	SELECT  TOP 100 PERCENT 
		 TT.[ShipDate]
		,TT.[Waybill]
		,TT.[Container]
		,TT.[InvoiceBatch]
		,TT.[Batch]
		,TT.[PONumber]
		,TT.[BoxNumber]
		,TT.[FormattedBoxNumber]
		,TT.[StyleNumber]
		,TT.[StyleColor]
		,TT.[Size]
		,TT.[PalletNumber]
		,TT.[Price]
		,TT.[BasePrice]
		,TT.[Screen_Print]
		,TT.[Total_Screen_Print]
		,TT.[Embroidery]
		,TT.[Total_Embroidery]
		,TT.[Sublimation]
		,TT.[Total_Sublimation]
		,TT.[DecorationSP]
		,TT.[DecorationEMB]
		,TT.[DecorationSUB]
		,TT.[DecorationPack]
		,TT.[DecorationDesc]
		,TT.[UnitDecorationExport]
		,TT.[UnitDecorationValue]
		,TT.[TotalDecorationExport]
		,TT.[TotalDecorationValue]
		,TT.[TotalExport]
		,TT.[TotalPrice]
		,TT.[TotalBlankPrice]
		,TT.[TotalFobValue]
		,TT.[Freight]
		,TT.[CA_HTSCode]
		,TT.[CA_HTSDescription]
		,TT.[US_HTSCode]
		,TT.[US_HTSDescription]
		,TT.[InvoicingDescription]
		,TT.[InvoicingGroupKelly]
		,TT.[ManufacturerGroupKelly]
      	,TT.[LineGroupKelly]
		,TT.[GrossWeightKGSXUnits]
		,TT.[Quantity]
		,TT.[Manufacturer]
		,TT.[CountryOfOrigin]
		,TT.[ProductDivision]
		,TT.[US_HTSCode2]
		,TT.[TariffCategory]
		,TT.[RO_ID]
		,TT.[RO]
		,TT.[ManufactureID]
		,TT.[MO]
		,TT.[IDExport]
		,TT.[IDImport]
		,TT.[IDKardex]
		,TT.[IM5]
		,TT.[DeclarationDate]
		,TT.[ArrivalDate]
		,TT.[DepartureDate]
		,TT.[PortOfLoading]
		,TT.[Cafta]
		,TT.[Orden]
		,TT.[GroupBox]
		,TT.[GroupPallet]
		,TT.[DocumentID]
	-- INTO CI_Import_Export_DeclarationExport
	FROM #TB_Data_All AS TT
	where TypeData = 'DeclarationExport'
	ORDER BY 
		 [Orden]
		,[Cafta] DESC
		,[CountryOfOrigin]
		,[StyleNumber]
		,[Container]
		,[US_HTSDescription]
		,[CA_HTSCode]
		,[Price]
		,[InvoicingDescription]
		,[Manufacturer]
END
	
update [AppsLCA].[dbo].[ImportExport_CommercialInvoice_Status] set [Status] = 'Finished', Finished_Date=getdate() 
	where waybill =@WayBill
	

	Fetch next from WayBill_status into  @Waybill, @Status, @Pending_Date, @Executing_date, @Finished_Date


	end
close WayBill_status
deallocate WayBill_status

END