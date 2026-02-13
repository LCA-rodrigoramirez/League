DECLARE @DateTransactionIni AS DATE				--Variable para calculo de fecha de inicio
DECLARE @DateTransactionFin AS DATE				--Variable para calculo de fecha final
DECLARE @HourTransI			AS VARCHAR(8)		--Variable de hora inicio
DECLARE @HourTransF			AS VARCHAR(8)		--Variable de hora de fin (ma�ana siguiente dia)
DECLARE @DateTransI			AS VARCHAR(20)		--Variable de fecha de inicio con hora
DECLARE @DateTransF			AS VARCHAR(20)		--Variable de fecha de fin con hora. Se le agrega un dia por turno 
DECLARE @DATE_FORM          AS DATETIME

SET @DATE_FORM              = DATEADD(DAY, - 1, GETDATE())
SET @DateTransactionIni		= (SELECT CASE 
													WHEN DATEPART(HOUR, @DATE_FORM) < 6 THEN CONVERT(DATE, DATEADD(DAY, -1, @DATE_FORM))
													ELSE CONVERT(DATE, @DATE_FORM)
												END)
SET @DateTransactionFin		= @DateTransactionIni
SET @HourTransI				= '06:00:00'
SET @HourTransF				= '05:59:59'
SET @DateTransI				= DATEADD(SECOND, 0, CAST(@DateTransactionIni AS DATETIME) + CAST(@HourTransI AS DATETIME))
SET @DateTransF				= DATEADD(SECOND, 0, CAST(DATEADD(DAY,1,@DateTransactionFin) AS DATETIME) + CAST(@HourTransF AS DATETIME))

DROP TABLE IF EXISTS #TB_CompanyName
CREATE TABLE #TB_CompanyName (
					[CompanyName]			VARCHAR(100)
				)
INSERT INTO #TB_CompanyName
VALUES
('Inspect 1 HW'),
('Inspect 2 HW'),
('Inspect 3 HW'),
('Inspect 4 HW'),
('Inspect 5 HW')

SELECT 
		[DateEff]				=	CASE 
									WHEN DATEPART(HOUR, Chl.ChangeDate) < 6 THEN
										DATEADD(DAY, -1, CAST(Chl.ChangeDate AS DATE))
									ELSE CAST(Chl.ChangeDate AS DATE)
								END
	,[RowBundle]			= ROW_NUMBER() OVER(	PARTITION BY 
																ad.CompanyName
															,bdn.BundleID 
													ORDER BY 
																ad.CompanyName
															,bdn.BundleID
															,wt.WorkTransactionID
												)
	,[AddressID]			= ad.[AddressID]
	,[orderID]				= od.OrderID
	,[ManufactureID]		= mo.ManufactureID
	,[BundleID]				= bdn.BundleID
	,[WorkTransactionID]	= wt.WorkTransactionID
	,[CompanyName]			= ad.CompanyName 
	,[ProductionTaskName]	= ad.[ProductionTaskName]
	-- ,[ptni]					= ad.[ptni]
	,[stiches]				= [AppsLCA].[dbo].[cleanString](od.Comments27)
	--,[Hits]					= SUM(ISNULL(wt.Quantity,0))
	,[Hits]					= ISNULL(wt.Quantity,0)
	--,[Units]				= AVG(bdn.QuantityOrdered)
	,[Units]				= bdn.QuantityOrdered
	-- ,[SStiches]				= ISNULL([AppsLCA].[dbo].[obtenerKeyAnidadaComa]([AppsLCA].[dbo].[cleanString](od.Comments27) , ad.[ptni]),0)
	,[PONumber]				= od.PONumber
	,[Locations]			= loc.[Description]
	-- ,[SLocation]			= ISNULL([AppsLCA].[dbo].[obtenerKeyAnidadaComa]([AppsLCA].[dbo].[cleanString](loc.[Description]) , ad.[ptni]),0)
	,[ProdDate]				= chl.ChangeDate
FROM (
		SELECT 
			 [AddressID]			= A.AddressID
			,[CompanyName]			= A.CompanyName
			,[ProductionTaskName]	= [AppsLCA].[dbo].[cleanString](A.ProductionTaskName)
			,[ptni]					= 1
		FROM LCA.dbo.Addresses AS A WITH(NOLOCK) 
		INNER JOIN #TB_CompanyName AS T ON T.CompanyName = A.CompanyName
		WHERE		A.ProductionTaskName IS NOT NULL 
			AND (		[AppsLCA].[dbo].[cleanString](A.ProductionTaskName) = 'Trim & Inspection HW'
				)
	) AS ad
	INNER JOIN	LCA.dbo.WorkTransactions 		AS wt 	WITH(NOLOCK) ON ad.AddressID 		= wt.OperatorID 
	INNER JOIN	LCA.dbo.ChangeLog 				AS chl 	WITH(NOLOCK) ON chl.ChangeLogID 	= wt.ChangeLogID AND chl.TableID = 30 AND (CAST(chl.ChangeDate AS DATE) = CAST(@DateTransI AS DATE) OR CAST(chl.ChangeDate AS DATE) = CAST(@DateTransF AS DATE))
	INNER JOIN	LCA.dbo.WorkTasks 				AS wtk 	WITH(NOLOCK) ON wtk.TaskID 			= wt.TaskID 
	INNER JOIN	LCA.dbo.Bundles 				AS bdn 	WITH(NOLOCK) ON bdn.BundleID 		= wt.BundleID
	INNER JOIN	LCA.dbo.ManufactureOrders		AS mo	WITH(NOLOCK) ON mo.ManufactureID	= bdn.ManufactureID
	INNER JOIN	LCA.dbo.OrderItems				AS oi	WITH(NOLOCK) ON oi.OrderItemID		= mo.FirstOrderItemID
	INNER JOIN	LCA.dbo.Orders					AS od	WITH(NOLOCK) ON od.OrderID			= oi.OrderID
	LEFT JOIN	LCA.dbo.DropDownValues5			AS loc	WITH(NOLOCK) ON loc.DropDownValueID	= od.OrderTypeID4
WHERE	 (		[AppsLCA].[dbo].[cleanString](wtk.[TaskName])  = 'Trim & Inspection HW'
		)
		AND CAST(chl.ChangeDate AS DATETIME) >= @DateTransI
		AND CAST(chl.ChangeDate AS DATETIME) <= @DateTransF
		AND CAST(chl.ChangeDate AS DATETIME) <= @DATE_FORM
-- ORDER BY chl.ChangeDate desc