
		SELECT
             [AF_ID]
			,[ShipDate]
            ,[Waybill]
            ,[InvoiceBatch]
            ,[Batch]
            ,[PONumber]
            ,[BoxNumber]                         	= AF.[BoxNumber]
            ,[StyleNumber]
            ,[StyleID]							 	= AF.[StyleID]
            ,[StyleColor]                        	= AF.[StyleColor]
            ,[StyleColorID]                      	= AF.[StyleColorID]
            ,[SeasonName]
            ,[Qty]
            ,[Supplier]
            ,[SAC]
            ,[HTSDescription]
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
            ,[ManufactureID]                     	= AF.[ManufactureID]
            ,[MO]
            ,[Embr_Code1]
            ,[Embr_Code2]
            ,[Embr_Code3]
            ,[Embr_Code4]
            ,[PrintLocations]
            ,[CountryOfOrigin]
            ,[ProductDivision]
            ,[OriginalProductDivision]
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
            ,[Consigned]
            ,[PartNumber]                       	= AF.[PartNumber]
            ,[Size]
            ,[RO_ID]                            	= AF.[RO_ID]
            ,[RO]
            ,[Receiving_Cost_Ponderado]      		= AF.[Receiving_Cost_Ponderado]
            ,[Total_Receiving_Cost_Ponderado]		= AF.[Total_Receiving_Cost_Ponderado]
            ,[OrderType]
            ,[TypeContainer]
            ,[Price_ScreenPrint]
            ,[Price_Sublimation]
            ,[Price_SubApplication]
            ,[CodePrice_EmbroideryApp]
            ,[Price_EmbroideryApp]
            ,[CodePrice_EmbroideryHW]
            ,[Cost_PackingMaterial]
            ,[Price_EmbroideryHW]
            ,[Price_HDP]
            ,[Price_SpecialPK]
            ,[Price_Relabel]
            ,[Price_PigmentDye]
            ,[Price_InlandFreight]
            ,[Price_AirFreight]
            ,[Price_OceanFreight]
            ,[OutboundFreight]
            ,[NumeroControl]
            ,[CodigoGeneracion]
            ,[Sello]
            ,[MensajeRecepcion]
			,[UnitFreightCost_Ponderado]       		= CONVERT(NUMERIC(18,4), 0)
        	,[Total_UnitFreightCost_Ponderado] 		= CONVERT(NUMERIC(18,4), 0)
        	,[UnitFreightCost]                 		= CONVERT(NUMERIC(18,4), 0)
        	,[Total_UnitFreightCost]           		= CONVERT(NUMERIC(18,4), 0)
        	,[Invoice]                         		= CAST(NULL AS NVARCHAR(500))
        	,[US_HTSCode]                      		= CAST(NULL AS NVARCHAR(50))
			,[DM]							   		= CAST(NULL AS varchar(20))
			,[CI_DocumentID]						= CAST(NULL AS VARCHAR(100))
			,[TypeData]								= CAST(NULL AS VARCHAR(50))
			,[BlankROStyleID]						= CAST(NULL AS INT)				
			,[UnitMin]								= CAST(NULL AS DECIMAL(18,2))
			,[TotalMin]								= CAST(NULL AS DECIMAL(18,2))
		INTO #TB_BillingDetails
        FROM
        (
            SELECT
                 [AF_ID]							 = AF.[ID]
				,[ShipDate]                          = AF.[ShipDate]
                ,[Waybill]                           = TRIM(REPLACE(REPLACE(REPLACE(AF.[Waybill], CHAR(10), ''), CHAR(9), ''), CHAR(13), ''))
                ,[InvoiceBatch]
                ,[Batch]                             = AF.[Batch]
                ,[PONumber]                          = AF.[PONumber]
                ,[BoxNumber]                         = AF.[BoxNumber]
                ,[StyleNumber]
                ,[StyleID]							 = SPD.[StyleID]
                ,[StyleColor]
                ,[StyleColorID]						 = OI.[StyleColorID]
                ,[SeasonName]
                ,[Qty]
                ,[Supplier]
                ,[SAC]
                ,[HTSDescription]                    = TRIM(REPLACE(REPLACE(REPLACE(AF.[HTSDescription], CHAR(10), ''), CHAR(9), ''), CHAR(13), ''))
                ,[PuertoDestino]                     = AF.[PuertoDestino]
                ,[BasePrice]                         = AF.[BasePrice]
                ,[Handling]
                ,[Total_Handling]
                ,[Freight]                           = AF.[Freight]
                ,[Total_Freight]
                ,[BaseCost]
                ,[Total_Base_Cost]
                ,[Receiving_Cost]
                ,[Total_Receiving_Cost]
                ,[Purchase_order]
                ,[PrintCount]                        = AF.[PrintCount]
                ,[Screen_Print]
                ,[Total_Screen_Print]
                ,[Embroidery]
                ,[Total_Embroidery]
                ,[Sublimation]                       = AF.[Sublimation]
                ,[Total_Sublimation]
                ,[Price]
                ,[Total$]
                ,[ManufactureID]                     = AF.[ManufactureID]
                ,[MO]                                = AF.[MO]
                ,[Embr_Code1]
                ,[Embr_Code2]
                ,[Embr_Code3]
                ,[Embr_Code4]
                ,[PrintLocations]                    = TRIM(REPLACE(REPLACE(REPLACE(AF.[PrintLocations], CHAR(10), ''), CHAR(9), ''), CHAR(13), ''))
                ,[CountryOfOrigin]
                ,[ProductDivision]					 =  CASE 
															WHEN AF.[ProductDivision] IS NULL AND AF.[StyleNumber] IN ('-','Fabric','Trim','Supplies','SWATCH') THEN 'Other Service' 
															WHEN AF.[ProductDivision] = 'Accesories' THEN 'Apparel'
															ELSE AF.[ProductDivision]
														END
                ,[OriginalProductDivision]			=   AF.[ProductDivision]
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
                ,[Consigned]
                ,[PartNumber]
                ,[Size]
                ,[RO_ID]
                ,[RO]
                ,[Receiving_Cost_Ponderado]
                ,[Total_Receiving_Cost_Ponderado]
                ,[OrderType]                         = CASE
                                                        WHEN [Embroidery] = 0.00 AND [Screen_Print] = 0.00 AND AF.[Sublimation] = 0.00 THEN 'Blanks/Transfers'
                                                        ELSE 'Customer Orders'
                                                      END
                ,[TypeContainer]                     = CASE
                                                        WHEN LEFT(AF.[Waybill], 3) = 'AIR' THEN 'AIR'
                                                        ELSE 'OCEAN'
                                                      END
                ,[Price_ScreenPrint]                = SPD.[Price_ScreenPrint]
                ,[Price_Sublimation]                = SPD.[Price_Sublimation]
                ,[Price_SubApplication]             = SPD.[Price_SubApplication]
                ,[CodePrice_EmbroideryApp]          = SPD.[CodePrice_EmbroideryApp]
                ,[Price_EmbroideryApp]              = SPD.[Price_EmbroideryApp]
                ,[CodePrice_EmbroideryHW]           = SPD.[CodePrice_EmbroideryHW]
                ,[Cost_PackingMaterial]             = SPD.[Price_EmbroideryHW] - SPD.[CodePrice_EmbroideryHW]
                ,[Price_EmbroideryHW]               = SPD.[Price_EmbroideryHW]
                ,[Price_HDP]                        = SPD.[Price_HDP]
                ,[Price_SpecialPK]                  = SPD.[Price_SpecialPK]
                ,[Price_Relabel]                    = SPD.[Price_Relabel]
                ,[Price_PigmentDye]                 = SPD.[Price_PigmentDye]
                ,[Price_InlandFreight]              = SPD.[Price_InlandFreight]
                ,[Price_AirFreight]                 = SPD.[Price_AirFreight]
                ,[Price_OceanFreight]               = SPD.[Price_OceanFreight]
                ,[OutboundFreight]                  = SPD.[OutboundFreight]
                ,[NumeroControl]                     = FE.[numeroControl]
                ,[CodigoGeneracion]                  = FE.[codigoGeneracion]
                ,[Sello]                             = FE.[sello]
                ,[MensajeRecepcion]                  = FE.[mensajeRecepcion]
            FROM #TB_FIL_Waybills AS TWF
			INNER JOIN [AppsLCA].[dbo].[ImportExport_AnexoFacturacion]        AS AF WITH(NOLOCK)  ON TWF.[ID] = AF.[ID]
            LEFT  JOIN [AppsLCA].[dbo].[TB_ShipmentCheckPricesDetail]    	  AS SPD WITH(NOLOCK) ON SPD.[id] = AF.[IDCheckPrices]
			LEFT  JOIN [LCA].[dbo].[OrderItems]								  AS OI  WITH(NOLOCK) ON SPD.[OrderItemID] = OI.[OrderItemID]
            LEFT JOIN
            (
                SELECT DISTINCT
                     [waybill]         = [factura]
                    ,[batch]           = [items]
                    ,[numeroControl]
                    ,[codigoGeneracion]
                    ,[sello]
                    ,[mensajeRecepcion]
                    ,[cuenta]          = ROW_NUMBER() OVER(PARTITION BY [factura], [items] ORDER BY [factura], [items])
                FROM [AppsLCA].[dbo].[DTE_FACTURAS_ELECTRONICAS]
                WHERE [mensajeRecepcion] LIKE 'RECIBIDO%'
                  AND CAST([fecEmi] AS DATE) >= '2024-08-01'
            ) AS FE ON TRIM(REPLACE(REPLACE(REPLACE(AF.[Waybill], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) = FE.[waybill]
                   AND AF.[Batch] = FE.[batch]
                   AND FE.[cuenta] = 1
            WHERE (AF.[ShipDate] < '2024-08-01' OR [fe].[mensajeRecepcion] IS NOT NULL)
        ) AS AF

		UPDATE BD SET
			[DM] = SH.[DM]
		FROM #TB_BillingDetails AS BD
		INNER JOIN
		(
			SELECT DISTINCT
				 [WayBill] = SH.[WayBill]
				,[DM]      = SH.[BookingNumber]
			FROM [LCA].[dbo].[Shipments] AS SH WITH(NOLOCK)
		) AS SH ON BD.[Waybill] = SH.[WayBill]

		UPDATE BD SET
			[CI_DocumentID] = CI.[DocumentID]
		FROM #TB_BillingDetails AS BD
		INNER JOIN #TB_CI AS CI ON BD.[AF_ID] = CI.[IDExport]

		UPDATE BD SET
			[US_HTSCode] = SBA.[US_HTSCode]
		FROM #TB_BillingDetails AS BD
		INNER JOIN
		(
			SELECT
				 [WayBill]
				,[BoxNumber]
				,[StyleNumber]
				,[StyleColor]
				,[GarmentSize]
				,[US_HTSCode]
				,[US_HTSDescription]
				,[InvoicingDescription]
			FROM [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] WITH(NOLOCK)
			GROUP BY [WayBill]
					,[BoxNumber]
					,[StyleNumber]
					,[StyleColor]
					,[GarmentSize]
					,[US_HTSCode]
					,[US_HTSDescription]
					,[InvoicingDescription]
		) AS SBA
			ON TRIM(REPLACE(REPLACE(REPLACE(SBA.[WayBill], CHAR(10), ''), CHAR(9), ''), CHAR(13), '')) = BD.[Waybill]
			AND SBA.[BoxNumber] = BD.[BoxNumber]
			AND SBA.[StyleNumber] = BD.[StyleNumber]
			AND SBA.[StyleColor] = BD.[StyleColor]
			AND SBA.[GarmentSize] = BD.[Size]

        -------------------------------------------------------------------------------------------------------------------------------------------------------
		-- UPDATE de Invoice (antes JOIN directo contra ManufactureOrders)
		-------------------------------------------------------------------------------------------------------------------------------------------------------
		UPDATE T SET
			T.[Invoice] = LTRIM(
								SUBSTRING(
									MOS.[Comments12]
									,CHARINDEX('Invoice: ', MOS.[Comments12]) + LEN('Invoice: ')
									,CHARINDEX(' |', MOS.[Comments12] + ' |', CHARINDEX('Invoice: ', MOS.[Comments12])) - (CHARINDEX('Invoice: ', MOS.[Comments12]) + LEN('Invoice: '))
								)
							)
		FROM #TB_BillingDetails AS T
		INNER JOIN [LCA].[dbo].[ManufactureOrders] AS MOS WITH(NOLOCK) ON T.[ManufactureID] = MOS.[ManufactureID]
		WHERE T.[Manufacturer] = 'NG TEXTILES GUATEMALA S.A.'

        -------------------------------------------------------------------------------------------------------------------------------------------------------
		-- UPDATE de PartNumber (antes JOIN directo contra VW_RawMaterials_Fabric_AllMOs_Pricing). Va antes del UPDATE de
		-- UnitFreightCost: ese UPDATE hace JOIN por T.[PartNumber], así que necesita el valor ya resuelto.
		-------------------------------------------------------------------------------------------------------------------------------------------------------
		UPDATE T SET
			T.[PartNumber] = VWRAW.[PartNumber]
		FROM #TB_BillingDetails AS T
		INNER JOIN
		(
			SELECT
				 [StyleID]
				,[StyleColorID]
				,[ManufactureID]
				,[RO_ID]
				,[Season]
				,[StyleColor]
				,[NewSize] = CASE
								WHEN RIGHT([PartNumber], 4) IN ('L_XL','L/XL') THEN RIGHT([PartNumber], 4)
								WHEN RIGHT([PartNumber], 3) IN ('2XL','3XL','4XL','5XL','XXL','S_M','S_M','S/M','ONE','ADJ') THEN RIGHT([PartNumber], 3)
								WHEN RIGHT([PartNumber], 2) IN ('XS','XL','2T','3T','4T','5T','6T','7T','8T') THEN RIGHT([PartNumber], 2)
								WHEN RIGHT([PartNumber], 1) IN ('S','M','L') THEN RIGHT([PartNumber], 1)
								ELSE ''
							 END
				,[PartNumber]
			FROM [LCA].[dboReaders].[VW_RawMaterials_Fabric_AllMOs_Pricing] WITH(NOLOCK)
			WHERE Season = 'EMB FG'
		) AS VWRAW ON T.[StyleID] = VWRAW.[StyleID]
				  AND T.[StyleColorID] = VWRAW.[StyleColorID]
				  AND T.[StyleColor] = VWRAW.[StyleColor]
				  AND T.[ManufactureID] = VWRAW.[ManufactureID]
				  AND T.[RO_ID] = VWRAW.[RO_ID]
				  AND T.[SeasonName] = VWRAW.[Season]
				  AND T.[Size] = VWRAW.[NewSize]
		WHERE (T.[PartNumber] IS NULL OR T.[PartNumber] = '')


		-------------------------------------------------------------------------------------------------------------------------------------------------------
		-- UPDATE de UnitFreightCost_Ponderado / Total_UnitFreightCost_Ponderado (antes JOIN directo contra TB_MO_PartNumber_IM_Materials)
		-------------------------------------------------------------------------------------------------------------------------------------------------------
		UPDATE T SET
			T.[UnitFreightCost_Ponderado]       = IIF(
														FAMF2.[MAKE] > 0
													AND FAMF2.[Contracts_FreightPrice] IS NOT NULL
													,CONVERT(NUMERIC(18,4), ROUND(FAMF2.[Contracts_FreightPrice] / FAMF2.[MAKE], 4))
													,0
												)
			,T.[Total_UnitFreightCost_Ponderado] = T.[Qty] * IIF(
																		FAMF2.[MAKE] > 0
																	AND FAMF2.[Contracts_FreightPrice] IS NOT NULL
																	,CONVERT(NUMERIC(18,4), ROUND(FAMF2.[Contracts_FreightPrice] / FAMF2.[MAKE], 4))
																	,0
																)
		FROM #TB_BillingDetails AS T
		LEFT JOIN [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Materials] AS FAMF2 WITH(NOLOCK) ON T.[RO_ID] = FAMF2.[ManufactureID]

		-------------------------------------------------------------------------------------------------------------------------------------------------------
		-- UPDATE de UnitFreightCost / Total_UnitFreightCost (antes JOIN directo contra TB_MO_PartNumber_IM)
		-------------------------------------------------------------------------------------------------------------------------------------------------------
		UPDATE T SET
			T.[UnitFreightCost]       = ISNULL(FAMF.[UnitFreightCost_Ponderado], 0)
			,T.[Total_UnitFreightCost] = T.[Qty] * ISNULL(FAMF.[UnitFreightCost_Ponderado], 0)
		FROM #TB_BillingDetails AS T
		LEFT JOIN
		(
			SELECT
				[ManufactureID]
				,[PartNumber]
				,[UnitFreightCost_Ponderado] = ([UF1] / IIF([TC] = 0,1,[TC]))
				,[Style]
				,[Color]
				,[Size]
			FROM
			(
				SELECT
					[ManufactureID] = TF1.[ManufactureID]
					,[PartNumber]   = TF1.[PartNumber]
					,[UF1]          = SUM(TF1.[Consumption] * TF1.[UnitFreightCost])
					,[TC]           = SUM(TF1.[Consumption])
					,[Style]        = STC.[Style]
					,[Color]        = STC.[Color]
					,[Size]         = STC.[Size]
				FROM [AppsLCA].[dbo].[TB_MO_PartNumber_IM] AS TF1 WITH(NOLOCK)
				LEFT JOIN
				(
					SELECT DISTINCT
						[ManufactureID]
						,[PartNumber]
						,[Style]
						,[Color]
						,[Size]
					FROM [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Freight] WITH(NOLOCK)
				) AS STC ON TF1.[ManufactureID] = STC.[ManufactureID]
						AND TF1.[PartNumber] = STC.[PartNumber]
				WHERE TF1.[Category] = 'Contracts'
				GROUP BY
					TF1.[ManufactureID]
					,TF1.[PartNumber]
					,STC.[Style]
					,STC.[Color]
					,STC.[Size]
			) AS ABC132
		) AS FAMF ON T.[RO_ID] = FAMF.[ManufactureID]
				AND (
							T.[StyleNumber] = FAMF.[Style]
						AND T.[StyleColor] = FAMF.[Color]
						AND T.[Size] = FAMF.[Size]
					OR
						CASE
							WHEN T.[StyleNumber] = '21014' THEN 'EZ100-' + T.[StyleColor] + '-' + T.[Size]
							WHEN T.[StyleNumber] IN ('10PDT','05PDT') THEN T.[StyleNumber] + '-PFD-' + T.[Size]
							ELSE T.[PartNumber]
						END = FAMF.[PartNumber]
				)