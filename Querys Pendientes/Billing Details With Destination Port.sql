USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_BillingDetails_Report]    Script Date: 09/06/2026 07:45:24 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--ALTER PROCEDURE [dbo].[SP_BillingDetails_Report]
--    @InitialDate AS DATE
--    ,@FinalDate AS DATE
--AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @InitialDate AS DATE = '2026-01-01'
	DECLARE @FinalDate AS DATE = '2026-05-31'

	DROP TABLE IF EXISTS #TB_CI
	DROP TABLE IF EXISTS #TB_BillingDetails

	SELECT *
	INTO #TB_CI
	FROM
	(
		SELECT
			DocumentID
			,IDExport
		FROM [192.168.1.93].AppsLCA.dbo.CI_Import_Export_CommercialInvoice AS CI WITH(NOLOCK)
		WHERE ShipDate >= @InitialDate AND ShipDate <= @FinalDate

		UNION

		SELECT
			DocumentID
			,IDExport
		FROM [192.168.1.93].AppsLCA.dbo.CI_Import_Export_DeclarationExport AS CI WITH(NOLOCK)
		WHERE ShipDate >= @InitialDate AND ShipDate <= @FinalDate

	) AS CI

	SELECT 
		af.ShipDate,
		TRIM(REPLACE(REPLACE(REPLACE(af.[Waybill], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS Waybill,
		CI.DocumentID AS CI_DocumentID,
		af.InvoiceBatch,
		af.Batch,
		TRIM(REPLACE(REPLACE(REPLACE(af.PONumber, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS PONumber,
		af.BoxNumber,
		af.StyleNumber,
		TRIM(REPLACE(REPLACE(REPLACE(af.StyleColor, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS StyleColor,
		af.SeasonName,
		af.Qty,
		TRIM(REPLACE(REPLACE(REPLACE(af.Supplier, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS Supplier,
		af.SAC AS HTSCode,
		TRIM(REPLACE(REPLACE(REPLACE(af.HTSDescription, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS HTSDescription,
		SBA.US_HTSCode,
		DDV.DropDownValue AS PuertoDestino,
		af.BasePrice,
		af.Handling,
		af.Total_Handling,
		af.Freight,
		af.Total_Freight,
		af.BaseCost,
		af.Total_Base_Cost,
		af.Receiving_Cost,
		af.Total_Receiving_Cost,
		af.Purchase_order,
		af.PrintCount,
		af.Screen_Print,
		af.Total_Screen_Print,
		af.Embroidery,
		af.Total_Embroidery,
		af.Sublimation,
		af.Total_Sublimation,
		af.Price,
		af.[Total$],
		af.MO,
		af.Embr_Code1,
		af.Embr_Code2,
		af.Embr_Code3,
		af.Embr_Code4,
		TRIM(REPLACE(REPLACE(REPLACE(af.PrintLocations, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS PrintLocations,
		TRIM(REPLACE(REPLACE(REPLACE(af.CountryOfOrigin, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS CountryOfOrigin,
		TRIM(REPLACE(REPLACE(REPLACE(af.ProductDivision, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS ProductDivision,
		TRIM(REPLACE(REPLACE(REPLACE(af.Manufacturer, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS Manufacturer,
		af.SemiFinishProductCost,
		af.SemiFinishProductCost_Fabric,
		af.SemiFinishProductCost_Thread,
		af.SemiFinishProductCost_Trim,
		af.SemiFinishProductCost_Supplies,
		af.SemiFinishProductCost_Contracts,
		af.SemiFinishProductCost_SubAssembly,
		af.FinishProductCost,
		af.FinishProductCost_Fabric,
		af.FinishProductCost_Thread,
		af.FinishProductCost_Trim,
		af.FinishProductCost_Supplies,
		af.FinishProductCost_Contracts,
		af.FinishProductCost_SubAssembly,
		af.Incoterm,
		af.Gross_Weight_kgs,
		af.Net_Weight_kgs,
		TRIM(REPLACE(REPLACE(REPLACE(af.Container, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS Container,
		CAST(NULL AS varchar(20)) AS DM,
		af.Consigned,
		TRIM(REPLACE(REPLACE(REPLACE(af.PartNumber, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS PartNumber,
		fe.codigoGeneracion,
		fe.sello,
		fe.numeroControl,
		af.Size,
		TRIM(REPLACE(REPLACE(REPLACE(af.RO, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS RO,
		af.Receiving_Cost_Ponderado,
		af.Total_Receiving_Cost_Ponderado

        ,AF.OrderId
	INTO #TB_BillingDetails
	FROM  
		[AppsLCA].[dbo].[ImportExport_AnexoFacturacion] af WITH(NOLOCK)
	LEFT JOIN  
		(
			SELECT DISTINCT 
				factura AS waybill, 
				items AS batch, 
				numeroControl, 
				codigoGeneracion, 
				sello, 
				mensajeRecepcion,
				ROW_NUMBER() OVER(PARTITION BY factura, items ORDER BY factura, items) AS cuenta
			FROM 
				[AppsLCA].[dbo].[DTE_FACTURAS_ELECTRONICAS]
			WHERE 
				mensajeRecepcion LIKE '%RECIBIDO%' 
				AND CAST(fecEmi AS DATE) >= '2024-08-01'
		) fe

	ON 
		TRIM(REPLACE(REPLACE(REPLACE(af.Waybill, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) = fe.waybill
	AND 
		af.Batch = fe.batch
	AND 
		fe.cuenta = 1 
	LEFT JOIN
	(
		SELECT  
				WayBill
			,BoxNumber
			,StyleNumber
			,StyleColor
			,GarmentSize
			,US_HTSCode
			,US_HTSDescription
			,InvoicingDescription
		FROM [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] with (nolock)
		--WHERE ShipDate >= '".$InitialDate."' AND ShipDate <= '".$FinalDate."'
		GROUP BY WayBill 
				,BoxNumber
				,StyleNumber
				,StyleColor
				,GarmentSize
				,US_HTSCode
				,US_HTSDescription
				,InvoicingDescription
	) AS SBA ON SBA.Waybill = AF.WayBill AND SBA.BoxNumber = AF.BoxNumber AND SBA.StyleNumber = af.StyleNumber 
				AND SBA.StyleColor = af.StyleColor AND SBA.GarmentSize = af.Size
	LEFT JOIN #TB_CI AS CI ON af.ID = CI.IDExport
	LEFT JOIN LCA.dbo.Orders AS OD  WITH(NOLOCK) ON af.OrderId = OD.OrderID
	LEFT JOIN LCA.dbo.DropDownValues2 AS DDV WITH(NOLOCK) ON OD.OrderTypeID3 = DDV.DropDownValueID
	WHERE 
		(af.ShipDate < '2024-08-01' OR fe.mensajeRecepcion IS NOT NULL)
		AND
		af.ShipDate >= @InitialDate
		AND 
		af.ShipDate <= @FinalDate 	
        AND AF.StyleNumber NOT IN ('-','Fabric','Trim','Supplies','SWATCH')			
	
	UPDATE BD SET
		DM = SH.DM
	FROM #TB_BillingDetails AS BD
	INNER JOIN
	(
		SELECT DISTINCT
			SH.WayBill
			,SH.BookingNumber AS DM
		FROM LCA.dbo.Shipments AS SH WITH(NOLOCK)
	) AS SH ON BD.Waybill = SH.WayBill

    UPDATE BD SET
        PuertoDestino = DP.PuertoDestino
    FROM #TB_BillingDetails AS BD
    INNER JOIN
    (

        SELECT
             BD.OrderId
            ,DDV.DropDownValue AS PuertoDestino      
        FROM #TB_BillingDetails AS BD
        LEFT JOIN LCA.dbo.PackedBoxes       AS PB WITH(NOLOCK)  ON BD.BoxNumber = PB.BoxNumber AND PB.StatusID = 75
        LEFT JOIN LCA.dbo.Orders            AS OD WITH(NOLOCK)  ON PB.OrderId = OD.OrderID
        LEFT JOIN LCA.dbo.DropDownValues2   AS DDV WITH(NOLOCK) ON OD.OrderTypeID3 = DDV.DropDownValueID 
    ) AS DP ON BD.OrderId = DP.OrderId AND BD.PuertoDestino IS NULL

	SELECT
		 [ShipDate]
        ,[Waybill]
        ,[CI_DocumentID]
        ,[InvoiceBatch]
        ,[Batch]
        ,[PONumber]
        ,[BoxNumber]
        ,[StyleNumber]
        ,[StyleColor]
        ,[SeasonName]
        ,[Qty]
        ,[Supplier]
        ,[HTSCode]
        ,[HTSDescription]
        ,[US_HTSCode]
        ,[PuertoDestino]
        ,[BasePrice]
        ,[Handling]
        ,[Total_Handling]
        ,[Freight]
        ,[Total_Freight]
        ,[BaseCost]
        ,[Total_Base_Cost]
        ,[Receiving_Cost]
        ,[Total_Receiving_Cost]
        ,[Purchase_order]
        ,[PrintCount]
        ,[Screen_Print]
        ,[Total_Screen_Print]
        ,[Embroidery]
        ,[Total_Embroidery]
        ,[Sublimation]
        ,[Total_Sublimation]
        ,[Price]
        ,[Total$]
        ,[MO]
        ,[Embr_Code1]
        ,[Embr_Code2]
        ,[Embr_Code3]
        ,[Embr_Code4]
        ,[PrintLocations]
        ,[CountryOfOrigin]
        ,[ProductDivision]
        ,[Manufacturer]
        ,[SemiFinishProductCost]
        ,[SemiFinishProductCost_Fabric]
        ,[SemiFinishProductCost_Thread]
        ,[SemiFinishProductCost_Trim]
        ,[SemiFinishProductCost_Supplies]
        ,[SemiFinishProductCost_Contracts]
        ,[SemiFinishProductCost_SubAssembly]
        ,[FinishProductCost]
        ,[FinishProductCost_Fabric]
        ,[FinishProductCost_Thread]
        ,[FinishProductCost_Trim]
        ,[FinishProductCost_Supplies]
        ,[FinishProductCost_Contracts]
        ,[FinishProductCost_SubAssembly]
        ,[Incoterm]
        ,[Gross_Weight_kgs]
        ,[Net_Weight_kgs]
        ,[Container]
        ,[DM]
        ,[Consigned]
        ,[PartNumber]
        ,[codigoGeneracion]
        ,[sello]
        ,[numeroControl]
        ,[Size]
        ,[RO]
        ,[Receiving_Cost_Ponderado]
        ,[Total_Receiving_Cost_Ponderado]
        ,[FlagBlank] =      CASE
                                WHEN (Embroidery = 0.00 AND Screen_Print = 0.00 AND Sublimation = 0.00) THEN 'Blanks/Transfers'
                                ELSE 'Customer Orders'
                            END
        ,[TypeContainer] =  CASE
                                WHEN LEFT(Waybill,3) = 'AIR' THEN 'AIR'
                                ELSE 'OCEAN'
                            END 
	FROM #TB_BillingDetails
	ORDER BY ShipDate DESC, WayBill
END