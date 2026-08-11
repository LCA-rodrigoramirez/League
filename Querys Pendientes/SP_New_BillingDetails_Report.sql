USE [AppsLCA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- CREATE OR ALTER PROCEDURE [dbo].[SP_New_BillingDetails_Report]
--     @process AS NVARCHAR(50)
--     ,@data AS NVARCHAR(MAX)
-- AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @process AS NVARCHAR(50) = 'report.dates'
	DECLARE @data AS NVARCHAR(MAX) = '{"selectedOptions":[{"InitialDate":"2026-07-01"},{"FinalDate":"2026-07-31"}]}'

	--DECLARE @process AS NVARCHAR(50) = 'report.waybills'
	--DECLARE @data AS NVARCHAR(MAX) = '{"selectedOptions":[{"Waybill":"12345"},{"Waybill":"67890"}]}'

	DECLARE @Component AS NVARCHAR(200)
	DECLARE @Error AS BIT
	DECLARE @message AS NVARCHAR(200)
	DECLARE @result AS NVARCHAR(MAX)
	DECLARE @vInitialDate AS DATE
	DECLARE @vFinalDate AS DATE

	SET @Component = '[200]'
	SET @Error = 0
	SET @message = 'Datos generados correctamente'

	DROP TABLE IF EXISTS #TB_FIL_Waybills
	DROP TABLE IF EXISTS #TB_CI
	DROP TABLE IF EXISTS #TB_BillingDetails

	BEGIN TRY

		IF @process NOT IN ('report.waybills', 'report.dates')
		BEGIN
			RAISERROR('Proceso no valido. Los valores permitidos son report.waybills y report.dates.', 16, 1)
		END

		CREATE TABLE #TB_FIL_Waybills (ID INT)

		IF @process = 'report.waybills'
		BEGIN
			INSERT INTO #TB_FIL_Waybills (ID)
			SELECT DISTINCT
				af.ID
			FROM [AppsLCA].[dbo].[ImportExport_AnexoFacturacion] af WITH(NOLOCK)
			INNER JOIN OPENJSON(@data, '$.selectedOptions')
				WITH (Waybill NVARCHAR(200) '$.Waybill') AS JS
				ON TRIM(REPLACE(REPLACE(REPLACE(af.Waybill, CHAR(10), ''), CHAR(9), ''), CHAR(13), ''))
					= TRIM(REPLACE(REPLACE(REPLACE(JS.Waybill, CHAR(10), ''), CHAR(9), ''), CHAR(13), ''))
			WHERE JS.Waybill IS NOT NULL;
		END

		IF @process = 'report.dates'
		BEGIN
			SELECT
				@vInitialDate = MAX(JS.InitialDate)
				,@vFinalDate = MAX(JS.FinalDate)
			FROM OPENJSON(@data, '$.selectedOptions')
				WITH (
					InitialDate DATE '$.InitialDate'
					,FinalDate DATE '$.FinalDate'
				) AS JS;

			INSERT INTO #TB_FIL_Waybills (ID)
			SELECT DISTINCT
				af.ID
			FROM [AppsLCA].[dbo].[ImportExport_AnexoFacturacion] af WITH(NOLOCK)
			WHERE af.ShipDate >= @vInitialDate AND af.ShipDate <= @vFinalDate;
		END


		SELECT *
		INTO #TB_CI
		FROM
		(
			SELECT
				DocumentID
				,IDExport
			FROM [192.168.1.93].AppsLCA.dbo.CI_Import_Export_CommercialInvoice AS CI WITH(NOLOCK)
			WHERE IDExport IN (
				SELECT ID
				FROM #TB_FIL_Waybills
			)

			UNION

			SELECT
				DocumentID
				,IDExport
			FROM [192.168.1.93].AppsLCA.dbo.CI_Import_Export_DeclarationExport AS CI WITH(NOLOCK)
			WHERE IDExport IN (
				SELECT ID
				FROM #TB_FIL_Waybills
			)

		) AS CI

		SELECT
			af.ID AS AF_ID,
			af.ShipDate,
			TRIM(REPLACE(REPLACE(REPLACE(af.[Waybill], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS Waybill,
			CAST(NULL AS VARCHAR(100)) AS CI_DocumentID,
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
			CAST(NULL AS NVARCHAR(50)) AS US_HTSCode,
			--DDV.DropDownValue AS PuertoDestino,
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
			af.ManufactureID,
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
			fe.nombreComercial AS Cliente,
			af.Size,
			TRIM(REPLACE(REPLACE(REPLACE(af.RO, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) AS RO,
			af.RO_ID,
			af.Receiving_Cost_Ponderado,
			af.Total_Receiving_Cost_Ponderado

		INTO #TB_BillingDetails
		FROM
			#TB_FIL_Waybills AS FIL
		INNER JOIN
			[AppsLCA].[dbo].[ImportExport_AnexoFacturacion] af WITH(NOLOCK)
			ON af.ID = FIL.ID
		LEFT JOIN
			(
				SELECT DISTINCT
					factura AS waybill,
					items AS batch,
					numeroControl,
					codigoGeneracion,
					sello,
					mensajeRecepcion,
					RC.nombreComercial,
					ROW_NUMBER() OVER(PARTITION BY factura, items ORDER BY factura, items) AS cuenta
				FROM
					[AppsLCA].[dbo].[DTE_FACTURAS_ELECTRONICAS] AS DFE WITH(NOLOCK)
					INNER JOIN [AppsLCA].[dbo].[DTE_RECEPTOR]	AS RC  WITH(NOLOCK) ON DFE.idReceptor = RC.id

				WHERE
					invalidado = 0
					AND CAST(fecEmi AS DATE) >= '2024-08-01'
			) fe

		ON
			TRIM(REPLACE(REPLACE(REPLACE(af.Waybill, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) = fe.waybill
		AND
			af.Batch = fe.batch
		AND
			fe.cuenta = 1
		--LEFT JOIN LCA.dbo.Orders AS OD WITH(NOLOCK) ON af.OrderId = OD.OrderID
		--LEFT JOIN LCA.dbo.DropDownValues2 AS DDV WITH(NOLOCK) ON OD.OrderTypeID3 = DDV.DropDownValueID
		WHERE
			(af.ShipDate < '2024-08-01' OR fe.mensajeRecepcion IS NOT NULL)

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
			CI_DocumentID = CI.DocumentID
		FROM #TB_BillingDetails AS BD
		INNER JOIN #TB_CI AS CI ON BD.AF_ID = CI.IDExport

		UPDATE BD SET
			US_HTSCode = SBA.US_HTSCode
		FROM #TB_BillingDetails AS BD
		INNER JOIN
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
			FROM [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] WITH(NOLOCK)
			GROUP BY WayBill
					,BoxNumber
					,StyleNumber
					,StyleColor
					,GarmentSize
					,US_HTSCode
					,US_HTSDescription
					,InvoicingDescription
		) AS SBA
			ON TRIM(REPLACE(REPLACE(REPLACE(SBA.WayBill, CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) = BD.Waybill
			AND SBA.BoxNumber = BD.BoxNumber
			AND SBA.StyleNumber = BD.StyleNumber
			AND SBA.StyleColor = BD.StyleColor
			AND SBA.GarmentSize = BD.Size

			SET @result = (
				SELECT
					*
				FROM #TB_BillingDetails
				ORDER BY ShipDate DESC, WayBill
				FOR JSON PATH, INCLUDE_NULL_VALUES
			)

	END TRY
	BEGIN CATCH
		SET @Error = 1
		SET @Component = '[' + CAST(ERROR_NUMBER() AS NVARCHAR(20)) + ']'
		SET @message = 'Line ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + ': ' + ERROR_MESSAGE()
	END CATCH

	SELECT
		 [Component] 	= @Component 
		,[Error]		= @Error
		,[Message]		= @message 
		,[Result]		= @result
	FOR JSON PATH, INCLUDE_NULL_VALUES

		
END
