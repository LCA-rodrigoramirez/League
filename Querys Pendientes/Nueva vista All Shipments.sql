USE [LCA]
GO

/****** Object:  View [L2BrandDB].[VW_L2Brands_AllShipments]    Script Date: 31/08/2026 11:43:46 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




ALTER VIEW [L2BrandDB].[VW_L2Brands_AllShipments]
AS
-- select 
--       tbf.Waybill
--          	 ,[TotalTariff]		= SUM(tbf.TotalTariff) 
--          	 ,[301China_Tariff]	= SUM(tbf.[301China_Tariff])
--          	 ,[Fenta_Tariff]	= SUM(tbf.Fenta_Tariff)
--          	 ,[Recip_Tariff]	= SUM(tbf.Recip_Tariff)
--          	 ,[HTS_Tariff]		= SUM(tbf.HTS_Tariff)
--          	 ,[Tariff122]		= SUM(tbf.Tariff122)
         	 
-- from(
--;
WITH CTE_AnexoFacturacion AS
(
    SELECT
         AF.[ShipDate]
        ,AF.[WayBill]
        ,AF.[Container]
        ,AF.[PuertoDestino]
        ,AF.[InvoiceBatch]
        ,AF.[OrderId]
        ,AF.[PONumber]
        ,AF.[ManufactureID]
        ,AF.[MO]
        ,AF.[StyleColor]
        ,AF.[stylenumber]
        ,AF.[SeasonName]
        ,AF.[Size]
        ,AF.[Qty]
        ,AF.[BoxNumber]
        ,AF.[Gross_Weight_kgs]
        ,AF.[FormattedBoxNumber]
    FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS AF WITH(NOLOCK)
    INNER JOIN AppsLCA.dbo.DTE_FACTURAS_ELECTRONICAS AS DTE WITH(NOLOCK) ON AF.[Waybill] = DTE.[factura] AND AF.[Batch] = DTE.[items] AND DTE.[invalidado] = 0
    WHERE AF.[ShipDate] > '2026-08-28'
)
SELECT
		 TB.[ShipContainerDate]
		,TB.[WayBill]
		,TB.[ContainerNumber]
		,TB.[DestinationPort]
		,TB.[Customer]
		,TB.[InvoiceBatch]
		,TB.[InvoiceBatchPrint]
		,TB.[PalletNumber]
		,TB.[OrderID]
		,TB.[PONumber]
		,TB.[WorkID]
		,TB.[ItemDetailID]
		,TB.[CustomerPONumber]
		,TB.[CustomerNamePONumber]
		,TB.[APS#]
		,TB.[MO_ID]
		,TB.[MO]
		,TB.[Color]
		,TB.[ColorDescription]
		,TB.[StyleID]
		,TB.[Style]
		,TB.[SeasonStyleName]
		,TB.[Size]
		,[Qty]                  = SUM(TB.[Qty])
		,TB.[BoxType]
		,TB.[BoxWidth]
		,TB.[BoxHeight]
		,TB.[BoxLength]
		,TB.[BoxNumber]
		,TB.[Weight]
		,TB.[BoxWeight]
		,TB.[BoxLabel]
		,TB.[ItemNumber]
		,TB.[Location]
		,TB.[CustomerOrderNumber]
		,TB.[ShippingMethod]
		,TB.[FormattedBoxNumber]
		,TB.[ConsolidatedBox]
		,TB.[ConsolidatedBoxWeight]
		,TB.[ConsolidatedBoxHeight]
		,TB.[ConsolidatedBoxLength]
		,TB.[ConsolidatedBoxWidth]
		,TB.[ASNI]
		,TB.[SKUID]
		
FROM
(
            SELECT
                 [ShipContainerDate]     = shc.[ShipDate]
                ,[WayBill]               = sh.[WayBill]
                ,[ContainerNumber]       = sh.[ContainerNumber]
                ,[DestinationPort]       = ISNULL(ddv2od.[DropDownValue], '')
                ,[Customer]              = od.[Comments4]
                ,[InvoiceBatch]          = ib.[InvoiceBatch]
                ,[InvoiceBatchPrint]     = SUBSTRING(ib.[InvoiceBatch],
                                               CHARINDEX('-', ib.[InvoiceBatch], 1) + 1,
                                               LEN(ib.[InvoiceBatch]))
                ,[PalletNumber]          = pcp.[PalletNumber]
                ,[OrderID]               = od.[OrderID]
                --,[PONumber]              = od.[PONumber]
                ,[PONumber]              = Case when od.[PONumber] not like 'ORD-%' and odd.DetailSpec4 is not null
                                                then odd.DetailSpec4
                                                else
                                                    od.[PONumber] 
                                            END
                ,[WorkID]                = CASE
                                               WHEN (od.[PONumber] LIKE 'ORD-%') THEN
                                                   REPLACE(od.[PONumber], 'ORD-', '')
                                               WHEN (od.[PONumber] LIKE 'ORD%') AND (ISNUMERIC(LEFT(od.[Comments6], 1)) = 1) THEN
                                                   od.[Comments6]
                                               ELSE
                                                   od.[PONumber]
                                           END
            
                ---CAMBIO DE INTEGER A BIGINT POR JOSE HERNANDEZ 20220505 06:43AM
                ,[ItemDetailID]          = CASE
                                           WHEN (od.[PONumber] LIKE 'ORD-PO%') THEN
                                               NULL
                                           WHEN (od.[PONumber] LIKE 'ORD-%') AND (ISNUMERIC(REPLACE(od.[PONumber], 'ORD-', '')) = 1) THEN
                                               CAST(REPLACE(od.[PONumber], 'ORD-', '') AS BIGINT)
                                           WHEN (od.[PONumber] LIKE 'ORD%') AND (ISNUMERIC(od.[Comments6]) = 1) THEN
                                               CAST(od.[Comments6] AS INT)
                                           ELSE
                                               NULL
                                           END
                ,[CustomerPONumber]      = Cust.[CompanyNumber]
                ,[CustomerNamePONumber]  = Cust.[CompanyName]
                ,[APS#]                  = od.[Comments6]
                ,[MO_ID]                 = MO.[ManufactureID]
                ,[MO]                    = mo.[ManufactureNumber]
                ,[Color]                 = ISNULL(CCol.[ColorChanged], stc.[StyleColorName])
                ,[ColorDescription]      = ISNULL(CCol.[ColorDescriptionChanged], stc.[StyleColorDescription])
                ,[StyleID]               = st.[StyleID]
                ,[Style]                 = st.[stylenumber]
                ,[SeasonStyleName]       = ISNULL(sns.[SeasonName], '')
                ,[Size]                  = fg.[GarmentSize]
                ,[Qty]                   = pci.[Quantity]
                ,[BoxType]               = bty.[BoxTypeName]
                ,[BoxWidth]              = bty.[BoxWidth]
                ,[BoxHeight]             = bty.[BoxHeight]
                ,[BoxLength]             = bty.[BoxLength]
                ,[BoxNumber]             = pcb.[BoxNumber]
                ,[Weight]                = ISNULL(pcb.[Weight], 0) * 2.204
                ,[BoxWeight]             = ISNULL(bty.[BoxWeight], 0) * 2.204
                ,[BoxLabel]              = pcb.[BoxLabel]
            
                --Cambio realizado 2026 02 25 por BH para mostrar el InvItemID de L2B
                --,CASE WHEN CCol.[ColorChanged] IS NOT NULL	AND ISNUMERIC(LEFT(CCol.[ColorChanged],1)) = 1 THEN
                --		st.stylenumber + '-' +	CCol.[ColorChanged] +
                --			CASE
                --				WHEN fg.GarmentSize = 'XS'		THEN	'A'
                --				WHEN fg.GarmentSize = 'S'		THEN	'B'
                --				WHEN fg.GarmentSize = 'M'		THEN	'C'
                --				WHEN fg.GarmentSize = 'L'		THEN	'D'
                --				WHEN fg.GarmentSize = 'XL'		THEN	'E'
                --				WHEN fg.GarmentSize = '2XL'		THEN	'F'
                --				WHEN fg.GarmentSize = '3XL'		THEN	'G'
                --				WHEN fg.GarmentSize = '4XL'		THEN	'H'
                --				WHEN fg.GarmentSize = '5XL'		THEN	'I'
                --				WHEN fg.GarmentSize = 'QTY'		THEN	'QTY'
                --				ELSE ''
                --			END
                --			+ '-' + fg.GarmentSize
            
                --	WHEN CCol.[ColorChanged] IS NOT NULL AND ISNUMERIC(LEFT(CCol.[ColorChanged],1)) = 0 THEN
                --		st.stylenumber + '-' +	CCol.[ColorChanged]
                --		+ '-' + fg.GarmentSize
            
                --	WHEN CCol.[ColorChanged] IS  NULL AND ISNUMERIC(LEFT(stc.StyleColorName,1)) = 1 THEN
                --		st.stylenumber + '-' +	stc.StyleColorName
                --		+
                --		CASE
                --			WHEN fg.GarmentSize = 'XS'		THEN	'A'
                --			WHEN fg.GarmentSize = 'S'		THEN	'B'
                --			WHEN fg.GarmentSize = 'M'		THEN	'C'
                --			WHEN fg.GarmentSize = 'L'		THEN	'D'
                --			WHEN fg.GarmentSize = 'XL'		THEN	'E'
                --			WHEN fg.GarmentSize = '2XL'		THEN	'F'
                --			WHEN fg.GarmentSize = '3XL'		THEN	'G'
                --			WHEN fg.GarmentSize = '4XL'		THEN	'H'
                --			WHEN fg.GarmentSize = '5XL'		THEN	'I'
                --			WHEN fg.GarmentSize = 'QTY'		THEN	'QTY'
                --			ELSE ''
                --		END
                --		+ '-' + fg.GarmentSize
            
                --	WHEN  CCol.[ColorChanged] IS  NULL	AND ISNUMERIC(LEFT(stc.StyleColorName,1)) = 0 THEN
                --		st.stylenumber + '-' +	stc.StyleColorName +
                --		+ '-' + fg.GarmentSize
            
                --	ELSE	st.stylenumber + '-' +	stc.StyleColorName +
                --		CASE
                --			WHEN fg.GarmentSize = 'XS'		THEN	'A'
                --			WHEN fg.GarmentSize = 'S'		THEN	'B'
                --			WHEN fg.GarmentSize = 'M'		THEN	'C'
                --			WHEN fg.GarmentSize = 'L'		THEN	'D'
                --			WHEN fg.GarmentSize = 'XL'		THEN	'E'
                --			WHEN fg.GarmentSize = '2XL'		THEN	'F'
                --			WHEN fg.GarmentSize = '3XL'		THEN	'G'
                --			WHEN fg.GarmentSize = '4XL'		THEN	'H'
                --			WHEN fg.GarmentSize = '5XL'		THEN	'I'
                --			WHEN fg.GarmentSize = 'QTY'		THEN	'QTY'
                --			ELSE ''
                --		END
                --		+ '-' + fg.GarmentSize
                --	END AS	[ItemNumber]
            
                 --, LCA_L2B.InvItemID as ItemNumber
                 -----CAMBIO JH 2026-03-10
                 -----SOLICITUD DAVID PRINARIS
                 ------itemnumber on the all_shipments view looks to have changed datatype from Unicode to non-Unicode
                 -----or vice versa so our SSIS ETL job is now failing since the data types don't match.
                 ------This was changed between 2/24 and 2/25, can this be reverted by chance or do we need to now update and redeploy our SSIS package?
                ,[ItemNumber]            = CAST(LCA_L2B.[InvItemID] AS NVARCHAR(100))
                ,[Location]              = CASE
                                               WHEN ddv2od.[DropDownValue] = 'Miami, FL 33182' THEN 'Miami, FL 33182' --'Account'
                                               WHEN ddv2od.[DropDownValue] = 'Hanover' AND LEFT(od.[PONumber], 3) = 'ORD' THEN 'Printed to Hanover'
                                               WHEN ddv2od.[DropDownValue] IS NULL AND LEFT(od.[PONumber], 2) IN ('PO', 'BO', 'TO') THEN 'Hanover'
                                               ELSE ISNULL(ddv2od.[DropDownValue], '')
                                           END
                ,[CustomerOrderNumber]   = CASE
                                               WHEN od.[Comments16] IS NOT NULL THEN od.[Comments16]
                                               WHEN od.[Comments6] IS NOT NULL AND CHARINDEX('-', od.[Comments6]) > 0
                                                   THEN SUBSTRING(od.[Comments6], 1, CHARINDEX('-', od.[Comments6]) - 1)
                                               ELSE od.[Comments6]
                                           END
                 --isnull(od.Comments16,od.Comments6) 		AS [Customer Order Number]
                ,[ShippingMethod]        = CASE WHEN CHARINDEX('air', sh.[WayBill]) > 0 THEN 'Air' ELSE 'Boat' END
                --  ,CCol.[ColorChanged]
                ,[FormattedBoxNumber]    = IE_Ship.[FormattedBoxNumber]
                
                --,pcb.BoxNumber as Box
                ,[ConsolidatedBox]       = CASE
                                               WHEN IE_Ship.[FormattedBoxNumber] = pcb.[BoxNumber] OR IE_Ship.[FormattedBoxNumber] IS NULL
                                                   OR LEFT(LTRIM(IE_Ship.[FormattedBoxNumber]), 1) <> '2' THEN ''
                                               ELSE CONCAT('PPPA' + LTRIM(STR(pcp.[PackedPalletID] + 1000000)), '-', RIGHT(btg.[DropDownValue], 3))
                                           END
                --Agregado el 2025 07 22 para L2B vea la caja consolidada
                ,[ConsolidatedBoxWeight] = CASE
                                               WHEN IE_Ship.[FormattedBoxNumber] = pcb.[BoxNumber] OR IE_Ship.[FormattedBoxNumber] IS NULL
                                                   OR LEFT(LTRIM(IE_Ship.[FormattedBoxNumber]), 1) <> '2' THEN ''
                                               ELSE ISNULL(pallf.[palletweight], 0) * 2.204
                                           END
                ,[ConsolidatedBoxHeight] = CASE
                                               WHEN IE_Ship.[FormattedBoxNumber] = pcb.[BoxNumber] OR IE_Ship.[FormattedBoxNumber] IS NULL
                                                   OR LEFT(LTRIM(IE_Ship.[FormattedBoxNumber]), 1) <> '2' THEN ''
                                               ELSE pallf.[PalletHeight]
                                           END
                ,[ConsolidatedBoxLength] = CASE
                                               WHEN IE_Ship.[FormattedBoxNumber] = pcb.[BoxNumber] OR IE_Ship.[FormattedBoxNumber] IS NULL
                                                   OR LEFT(LTRIM(IE_Ship.[FormattedBoxNumber]), 1) <> '2' THEN ''
                                               ELSE pallf.[PalletLength]
                                           END
                ,[ConsolidatedBoxWidth]  = CASE
                                               WHEN IE_Ship.[FormattedBoxNumber] = pcb.[BoxNumber] OR IE_Ship.[FormattedBoxNumber] IS NULL
                                                   OR LEFT(LTRIM(IE_Ship.[FormattedBoxNumber]), 1) <> '2' THEN ''
                                               ELSE pallf.[PalletWidth]
                                           END
                ,[ASNI]                  = odd.[DetailSpec2]
                ,[SKUID]                 = odd.[DetailSpec3]
                --,pci.PackedItemID
                --pallf.*
        FROM (SELECT [StatusID] FROM dbo.StatusNames WITH(NOLOCK) WHERE [StatusID] = 75) AS SNF
    		INNER JOIN dbo.PackedBoxes 			        AS pcb 		WITH (NOLOCK) ON pcb.[StatusID]            = SNF.[StatusID]               AND PCB.StatusID = 75
    		INNER JOIN dbo.Shipments 			        AS sh 		WITH (NOLOCK) ON sh.[ShipmentID]           = pcb.[ShipmentID]             AND sh.StatusID <> 105 --AND NOT(sh.[WayBill] LIKE '%PICACHO')
            INNER JOIN dbo.PackedItems 				    AS pci		WITH (NOLOCK) ON pcb.[PackedBoxID]         = pci.[PackedBoxID]            AND pci.[Quantity] <> 0
    		INNER JOIN dbo.ShippingContainers 	        AS shc 		WITH (NOLOCK) ON shc.[ShippingContainerID] = sh.[ShippingContainerID]     AND CAST(shc.[ShipDate] AS DATE) >= CAST((GETDATE()-730) AS DATE) AND YEAR(shc.[ShipDate]) >= 2025 AND SHC.[ShipDate] <= '2026-08-28'
    		LEFT JOIN dbo.FinishedGoods 		        AS fg 		WITH (NOLOCK) ON fg.[FinishedGoodsID]      = pci.[FinishedGoodsID]
    		LEFT JOIN dbo.Styles 				        AS st 		WITH (NOLOCK) ON st.[StyleID]              = fg.[StyleID]
    		LEFT JOIN dbo.OrderDetails 			        AS odd 		WITH (NOLOCK) ON odd.[OrderDetailsID]      = pci.[OrderDetailsID]
    		LEFT JOIN dbo.OrderItems 			        AS odi 		WITH (NOLOCK) ON odi.[OrderItemID]         = odd.[OrderItemID]
    		LEFT JOIN dbo.StyleColors 			        AS stc 		WITH (NOLOCK) ON stc.[StyleColorID]        = odi.[StyleColorID]
    		LEFT JOIN dbo.Seasons 				        AS sns 		WITH (NOLOCK) ON sns.[SeasonID]            = st.[SeasonID]
    		LEFT JOIN dbo.Orders 				        AS od 		WITH (NOLOCK) ON od.[OrderID]              = pcb.[OrderID]
    		LEFT JOIN dbo.DropDownValues2 		        AS ddv2od 	WITH (NOLOCK) ON ddv2od.[DropDownValueID]  = od.[OrderTypeID3]
    		LEFT JOIN dbo.InvoiceBatches 		        AS ib 		WITH (NOLOCK) ON ib.[InvoiceBatchID]       = sh.[InvoiceBatchID]
    		LEFT JOIN dbo.BoxTypes 				        AS bty 		WITH (NOLOCK) ON bty.[BoxTypeID]           = pcb.[BoxTypeID]
    		LEFT JOIN dbo.StatusNames 			        AS snpcb 	WITH (NOLOCK) ON snpcb.[StatusID]          = pcb.[StatusID]
    		LEFT JOIN dbo.Warehouses 			        AS wh 		WITH (NOLOCK) ON wh.[warehouseID]          = pcb.[warehouseID]
    		LEFT JOIN dbo.DropDownValues3				AS btg	    WITH (NOLOCK) ON pcb.[BoxTagID]            = btg.[DropDownValueID]	      AND btg.[DropDownID] = 19
    		LEFT JOIN dbo.ManufactureOrders 	        AS mo 		WITH (NOLOCK) ON mo.[ManufactureID]        = pci.[ManufactureID]
    		LEFT JOIN dbo.PackedPallets 			    AS pcp 		WITH (NOLOCK) ON pcp.[PackedPalletID]      = pcb.[PackedPalletID]
    		LEFT JOIN dbo.Addresses 			        AS Cust 	WITH (NOLOCK) ON Cust.[AddressID]          = od.[CustomerID]
    		LEFT JOIN dbo.PalletTypes					AS Pallf    WITH (NOLOCK) ON pcp.[PalletTypeID]        = Pallf.[PalletTypeID]
    		LEFT JOIN [AppsLCA].[dbo].[ChangeColor]	    AS CCol		WITH (NOLOCK) ON CCol.[Style]              = st.[StyleNumber]
    																				AND CCol.[Color]           = stc.[StyleColorName]
    		LEFT JOIN (SELECT DISTINCT [FormattedBoxNumber], [BoxNumber]
    							FROM [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] WITH (NOLOCK)
    							WHERE CAST([ShipDate] AS DATE) >= CAST((GETDATE()-730) AS DATE) AND YEAR([ShipDate]) >= 2026
    				) IE_Ship ON pcb.[BoxNumber] = IE_Ship.[BoxNumber]
    							
    		LEFT JOIN [AppsLCA].[legacycaps].[VW_LCA_L2B_InventoryID] LCA_L2B WITH (NOLOCK)
    				ON st.[stylenumber] = LCA_L2B.[Style] AND stc.[StyleColorName] = LCA_L2B.[Color] AND fg.[GarmentSize] = LCA_L2B.[Size]


            UNION ALL

            SELECT
                 [ShipContainerDate]     = AF.[ShipDate]
                ,[WayBill]               = AF.[WayBill]
                ,[ContainerNumber]       = AF.[Container]
                ,[DestinationPort]       = ISNULL(AF.[PuertoDestino], '')
                ,[Customer]              = ORD.[Comments4]
                ,[InvoiceBatch]          = AF.[InvoiceBatch]
                ,[InvoiceBatchPrint]     = SUBSTRING(AF.[InvoiceBatch],
                                               CHARINDEX('-', AF.[InvoiceBatch], 1) + 1,
                                               LEN(AF.[InvoiceBatch]))
                ,[PalletNumber]          = PP.[PalletNumber]
                ,[OrderID]               = AF.[OrderID]
                --,[PONumber]              = od.[PONumber]
                ,[PONumber]              = Case when AF.[PONumber] not like 'ORD-%' and ODT.DetailSpec4 is not null
                                                then ODT.DetailSpec4
                                                else
                                                    AF.[PONumber]
                                            END
                ,[WorkID]                = CASE
                                               WHEN (AF.[PONumber] LIKE 'ORD-%') THEN
                                                   REPLACE(AF.[PONumber], 'ORD-', '')
                                               WHEN (AF.[PONumber] LIKE 'ORD%') AND (ISNUMERIC(LEFT(ORD.[Comments6], 1)) = 1) THEN
                                                   ORD.[Comments6]
                                               ELSE
                                                   AF.[PONumber]
                                           END

                ---CAMBIO DE INTEGER A BIGINT POR JOSE HERNANDEZ 20220505 06:43AM
                ,[ItemDetailID]          = CASE
                                           WHEN (AF.[PONumber] LIKE 'ORD-PO%') THEN
                                               NULL
                                           WHEN (AF.[PONumber] LIKE 'ORD-%') AND (ISNUMERIC(REPLACE(AF.[PONumber], 'ORD-', '')) = 1) THEN
                                               CAST(REPLACE(AF.[PONumber], 'ORD-', '') AS BIGINT)
                                           WHEN (AF.[PONumber] LIKE 'ORD%') AND (ISNUMERIC(ORD.[Comments6]) = 1) THEN
                                               CAST(ORD.[Comments6] AS INT)
                                           ELSE
                                               NULL
                                           END
                ,[CustomerPONumber]      = Cust.[CompanyNumber]
                ,[CustomerNamePONumber]  = Cust.[CompanyName]
                ,[APS#]                  = ORD.[Comments6]
                ,[MO_ID]                 = AF.[ManufactureID]
                ,[MO]                    = AF.[MO]
                ,[Color]                 = ISNULL(CCol.[ColorChanged], AF.[StyleColor])
                ,[ColorDescription]      = ISNULL(CCol.[ColorDescriptionChanged], SC.[StyleColorDescription])
                ,[StyleID]               = OI.[StyleID]
                ,[Style]                 = AF.[stylenumber]
                ,[SeasonStyleName]       = ISNULL(AF.[SeasonName], '')
                ,[Size]                  = AF.[Size]
                ,[Qty]                   = AF.[Qty]
                ,[BoxType]               = BT.[BoxTypeName]
                ,[BoxWidth]              = BT.[BoxWidth]
                ,[BoxHeight]             = BT.[BoxHeight]
                ,[BoxLength]             = BT.[BoxLength]
                ,[BoxNumber]             = AF.[BoxNumber]
                ,[Weight]                = ISNULL(AF.[Gross_Weight_kgs], 0) * 2.204
                ,[BoxWeight]             = ISNULL(BT.[BoxWeight], 0) * 2.204
                ,[BoxLabel]              = PB.[BoxLabel]

                --Cambio realizado 2026 02 25 por BH para mostrar el InvItemID de L2B
                --,CASE WHEN CCol.[ColorChanged] IS NOT NULL	AND ISNUMERIC(LEFT(CCol.[ColorChanged],1)) = 1 THEN
                --		st.stylenumber + '-' +	CCol.[ColorChanged] +
                --			CASE
                --				WHEN fg.GarmentSize = 'XS'		THEN	'A'
                --				WHEN fg.GarmentSize = 'S'		THEN	'B'
                --				WHEN fg.GarmentSize = 'M'		THEN	'C'
                --				WHEN fg.GarmentSize = 'L'		THEN	'D'
                --				WHEN fg.GarmentSize = 'XL'		THEN	'E'
                --				WHEN fg.GarmentSize = '2XL'		THEN	'F'
                --				WHEN fg.GarmentSize = '3XL'		THEN	'G'
                --				WHEN fg.GarmentSize = '4XL'		THEN	'H'
                --				WHEN fg.GarmentSize = '5XL'		THEN	'I'
                --				WHEN fg.GarmentSize = 'QTY'		THEN	'QTY'
                --				ELSE ''
                --			END
                --			+ '-' + fg.GarmentSize

                --	WHEN CCol.[ColorChanged] IS NOT NULL AND ISNUMERIC(LEFT(CCol.[ColorChanged],1)) = 0 THEN
                --		st.stylenumber + '-' +	CCol.[ColorChanged]
                --		+ '-' + fg.GarmentSize

                --	WHEN CCol.[ColorChanged] IS  NULL AND ISNUMERIC(LEFT(stc.StyleColorName,1)) = 1 THEN
                --		st.stylenumber + '-' +	stc.StyleColorName
                --		+
                --		CASE
                --			WHEN fg.GarmentSize = 'XS'		THEN	'A'
                --			WHEN fg.GarmentSize = 'S'		THEN	'B'
                --			WHEN fg.GarmentSize = 'M'		THEN	'C'
                --			WHEN fg.GarmentSize = 'L'		THEN	'D'
                --			WHEN fg.GarmentSize = 'XL'		THEN	'E'
                --			WHEN fg.GarmentSize = '2XL'		THEN	'F'
                --			WHEN fg.GarmentSize = '3XL'		THEN	'G'
                --			WHEN fg.GarmentSize = '4XL'		THEN	'H'
                --			WHEN fg.GarmentSize = '5XL'		THEN	'I'
                --			WHEN fg.GarmentSize = 'QTY'		THEN	'QTY'
                --			ELSE ''
                --		END
                --		+ '-' + fg.GarmentSize

                --	WHEN  CCol.[ColorChanged] IS  NULL	AND ISNUMERIC(LEFT(stc.StyleColorName,1)) = 0 THEN
                --		st.stylenumber + '-' +	stc.StyleColorName +
                --		+ '-' + fg.GarmentSize

                --	ELSE	st.stylenumber + '-' +	stc.StyleColorName +
                --		CASE
                --			WHEN fg.GarmentSize = 'XS'		THEN	'A'
                --			WHEN fg.GarmentSize = 'S'		THEN	'B'
                --			WHEN fg.GarmentSize = 'M'		THEN	'C'
                --			WHEN fg.GarmentSize = 'L'		THEN	'D'
                --			WHEN fg.GarmentSize = 'XL'		THEN	'E'
                --			WHEN fg.GarmentSize = '2XL'		THEN	'F'
                --			WHEN fg.GarmentSize = '3XL'		THEN	'G'
                --			WHEN fg.GarmentSize = '4XL'		THEN	'H'
                --			WHEN fg.GarmentSize = '5XL'		THEN	'I'
                --			WHEN fg.GarmentSize = 'QTY'		THEN	'QTY'
                --			ELSE ''
                --		END
                --		+ '-' + fg.GarmentSize
                --	END AS	[ItemNumber]

                 --, LCA_L2B.InvItemID as ItemNumber
                 -----CAMBIO JH 2026-03-10
                 -----SOLICITUD DAVID PRINARIS
                 ------itemnumber on the all_shipments view looks to have changed datatype from Unicode to non-Unicode
                 -----or vice versa so our SSIS ETL job is now failing since the data types don't match.
                 ------This was changed between 2/24 and 2/25, can this be reverted by chance or do we need to now update and redeploy our SSIS package?
                ,[ItemNumber]            = CAST(LCA_L2B.[InvItemID] AS NVARCHAR(100))
                ,[Location]              = CASE
                                               WHEN AF.[PuertoDestino] = 'Miami, FL 33182' THEN 'Miami, FL 33182' --'Account'
                                               WHEN AF.[PuertoDestino] = 'Hanover' AND LEFT(AF.[PONumber], 3) = 'ORD' THEN 'Printed to Hanover'
                                               WHEN AF.[PuertoDestino] IS NULL AND LEFT(AF.[PONumber], 2) IN ('PO', 'BO', 'TO') THEN 'Hanover'
                                               ELSE ISNULL(AF.[PuertoDestino], '')
                                           END
                ,[CustomerOrderNumber]   = CASE
                                               WHEN ORD.[Comments16] IS NOT NULL THEN ORD.[Comments16]
                                               WHEN ORD.[Comments6] IS NOT NULL AND CHARINDEX('-', ORD.[Comments6]) > 0
                                                   THEN SUBSTRING(ORD.[Comments6], 1, CHARINDEX('-', ORD.[Comments6]) - 1)
                                               ELSE ORD.[Comments6]
                                           END
                 --isnull(od.Comments16,od.Comments6) 		AS [Customer Order Number]
                ,[ShippingMethod]        = CASE WHEN CHARINDEX('air', AF.[WayBill]) > 0 THEN 'Air' ELSE 'Boat' END
                --  ,CCol.[ColorChanged]
                ,[FormattedBoxNumber]    = AF.[FormattedBoxNumber]

                --,pcb.BoxNumber as Box
                ,[ConsolidatedBox]       = CASE
                                               WHEN AF.[FormattedBoxNumber] = AF.[BoxNumber] OR AF.[FormattedBoxNumber] IS NULL
                                                   OR LEFT(LTRIM(AF.[FormattedBoxNumber]), 1) <> '2' THEN ''
                                               ELSE CONCAT('PPPA' + LTRIM(STR(PP.[PackedPalletID] + 1000000)), '-', RIGHT(BG.[DropDownValue], 3))
                                           END
                --Agregado el 2025 07 22 para L2B vea la caja consolidada
                ,[ConsolidatedBoxWeight] = CASE
                                               WHEN AF.[FormattedBoxNumber] = AF.[BoxNumber] OR AF.[FormattedBoxNumber] IS NULL
                                                   OR LEFT(LTRIM(AF.[FormattedBoxNumber]), 1) <> '2' THEN ''
                                               ELSE ISNULL(PT.[palletweight], 0) * 2.204
                                           END
                ,[ConsolidatedBoxHeight] = CASE
                                               WHEN AF.[FormattedBoxNumber] = AF.[BoxNumber] OR AF.[FormattedBoxNumber] IS NULL
                                                   OR LEFT(LTRIM(AF.[FormattedBoxNumber]), 1) <> '2' THEN ''
                                               ELSE PT.[PalletHeight]
                                           END
                ,[ConsolidatedBoxLength] = CASE
                                               WHEN AF.[FormattedBoxNumber] = AF.[BoxNumber] OR AF.[FormattedBoxNumber] IS NULL
                                                   OR LEFT(LTRIM(AF.[FormattedBoxNumber]), 1) <> '2' THEN ''
                                               ELSE PT.[PalletLength]
                                           END
                ,[ConsolidatedBoxWidth]  = CASE
                                               WHEN AF.[FormattedBoxNumber] = AF.[BoxNumber] OR AF.[FormattedBoxNumber] IS NULL
                                                   OR LEFT(LTRIM(AF.[FormattedBoxNumber]), 1) <> '2' THEN ''
                                               ELSE PT.[PalletWidth]
                                           END
                ,[ASNI]                  = ODT.[DetailSpec2]
                ,[SKUID]                 = ODT.[DetailSpec3]
            --SELECT AF.*
            FROM CTE_AnexoFacturacion AS AF
            INNER JOIN LCA.dbo.Orders                   AS ORD      WITH(NOLOCK)    ON AF.[OrderId]              = ORD.[OrderID]
            INNER JOIN LCA.dbo.ManufactureOrders        AS MO       WITH(NOLOCK)    ON AF.[ManufactureID]        = MO.[ManufactureID]
            INNER JOIN LCA.dbo.OrderItems               AS OI       WITH(NOLOCK)    ON MO.[FirstOrderItemID]     = OI.[OrderItemID]
            INNER JOIN LCA.dbo.StyleColors              AS SC       WITH(NOLOCK)    ON OI.[StyleColorID]         = SC.[StyleColorID]
            INNER JOIN LCA.dbo.Shipments                AS SH       WITH(NOLOCK)    ON SH.[WayBill]              = AF.[WayBill]
            INNER JOIN LCA.dbo.PackedBoxes 			    AS PB		WITH(NOLOCK)    ON PB.[BoxNumber]            = AF.[BoxNumber]               AND PB.[StatusID] = 75 AND PB.[ShipmentID] = SH.[ShipmentID]
            LEFT  JOIN LCA.dbo.BoxTypes 				AS BT 		WITH(NOLOCK)    ON BT.[BoxTypeID]            = PB.[BoxTypeID]
            LEFT  JOIN LCA.dbo.DropDownValues3			AS BG	    WITH(NOLOCK)    ON PB.[BoxTagID]             = BG.[DropDownValueID]	        AND BG.[DropDownID] = 19
            LEFT  JOIN LCA.dbo.PackedPallets 			AS PP 		WITH(NOLOCK)    ON PP.[PackedPalletID]       = PB.[PackedPalletID]
            LEFT  JOIN LCA.dbo.PalletTypes				AS PT       WITH(NOLOCK)    ON PP.[PalletTypeID]         = PT.[PalletTypeID]
            LEFT  JOIN LCA.dbo.Addresses                AS Cust 	WITH(NOLOCK)    ON Cust.[AddressID]          = ORD.[CustomerID]
            LEFT  JOIN [AppsLCA].[dbo].[ChangeColor]	AS CCol		WITH(NOLOCK)    ON CCol.[Style]              = AF.[StyleNumber]
    																				AND CCol.[Color]             = AF.[StyleColor]
            LEFT  JOIN [AppsLCA].[legacycaps].[VW_LCA_L2B_InventoryID] LCA_L2B WITH (NOLOCK)
    				ON AF.[stylenumber] = LCA_L2B.[Style] AND AF.[StyleColor] = LCA_L2B.[Color] AND AF.[Size] = LCA_L2B.[Size]
            LEFT  JOIN LCA.dbo.OrderDetails             AS ODT      WITH(NOLOCK)    ON OI.[OrderItemID]          = ODT.[OrderItemID]
                                                                                    AND AF.[Size]                = ODT.[GarmentSize]
                                                                                    AND ODT.[StatusID] = 30

    		-- WHERE shc.ShipDate >= getdate()-730  ---Se cambia a 2 años por el tema de Tarifas, es donde empezo la informacion
    		-- ---'2018-01-01 00:00:00'  Se deja activo los registros de los ultimos 3 años unicamente
    		-- 	AND sh.StatusID <> 105
    		-- 	--AND (Cust.CompanyNumber LIKE '%LEAGUE%' or Cust.CompanyNumber LIKE '%L2 BRANDS%')
    		-- 	and not(sh.WayBill LIKE '%PICACHO')
) AS TB
GROUP BY
    	 TB.[ShipContainerDate]
		,TB.[WayBill]
		,TB.[ContainerNumber]
		,TB.[DestinationPort]
		,TB.[Customer]
		,TB.[InvoiceBatch]
		,TB.[InvoiceBatchPrint]
		,TB.[PalletNumber]
		,TB.[OrderID]
		,TB.[PONumber]
		,TB.[WorkID]
		,TB.[ItemDetailID]
		,TB.[CustomerPONumber]
		,TB.[CustomerNamePONumber]
		,TB.[APS#]
		,TB.[MO_ID]
		,TB.[MO]
		,TB.[Color]
		,TB.[ColorDescription]
		,TB.[StyleID]
		,TB.[Style]
		,TB.[SeasonStyleName]
		,TB.[Size]
		-- ,[Qty]  = SUM([Qty])
		,TB.[BoxType]
		,TB.[BoxWidth]
		,TB.[BoxHeight]
		,TB.[BoxLength]
		,TB.[BoxNumber]
		,TB.[Weight]
		,TB.[BoxWeight]
		,TB.[BoxLabel]
		,TB.[ItemNumber]
		,TB.[Location]
		,TB.[CustomerOrderNumber]
		,TB.[ShippingMethod]
		,TB.[FormattedBoxNumber]
		,TB.[ConsolidatedBox]
		,TB.[ConsolidatedBoxWeight]
		,TB.[ConsolidatedBoxHeight]
		,TB.[ConsolidatedBoxLength]
		,TB.[ConsolidatedBoxWidth]
		,TB.[ASNI]
		,TB.[SKUID]
-- ) as tbf
-- where tbf.WayBill = 'HW-20250411'
-- group by tbf.Waybill
GO


