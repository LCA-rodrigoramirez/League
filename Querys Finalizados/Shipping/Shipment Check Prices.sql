USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_ShipmentCheckPrices]    Script Date: 04/09/2026 09:09:42 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[SP_ShipmentCheckPrices] 
       @process	VARCHAR(MAX)
		,@data		NVARCHAR(MAX)
		, @NoSelect BIT = 0 
		, @otherData NVARCHAR(MAX) =NULL OUTPUT   -- nuevo parámetro
AS
BEGIN
    SET NOCOUNT ON;

	    -- DECLARE @process	AS VARCHAR(MAX)
		-- DECLARE @data		AS NVARCHAR(MAX)
		-- DECLARE @otherData  AS NVARCHAR(MAX)    = NULL
		-- DECLARE @NoSelect   AS BIT              
		-- SET     @NoSelect   = 0
		-- SET     @process	= 'checkprices.list'
 		-- -- {"process":"checkprices.list","data":{"selectedOptions":[{"R":1,"Waybill":"AIR-APP-20260206","ShipDate":"2026-02-06"}],"updatePrices":1,"userCode":"01715"}}
 		-- SET     @data		= '{"selectedOptions":[
		-- 		 		                             {"R":1
		-- 		 		                             ,"Waybill":"AIR-HW-20260505"
		-- 		 		                             ,"ShipDate":"2026-05-05"
		-- 		 		                             }
 		--                              ]
 		--                              ,"updatePrices":0
 		--                              ,"userCode":"01715"
 		--                     }'
 		-- SET     @data		= '{"selectedOptions":[
		-- 		 		                             {"R":1
		-- 		 		                             ,"Waybill":"AIR-HW-20260622"
		-- 		 		                             ,"ShipDate":"2026-06-22"
		-- 		 		                             },
		-- 		 		                             {"R":2
		-- 		 		                             ,"Waybill":"APP-20260622"
		-- 		 		                             ,"ShipDate":"2026-06-22"
		-- 		 		                             },
		-- 		 		                             {"R":3
		-- 		 		                             ,"Waybill":"SMS-20260529"
		-- 		 		                             ,"ShipDate":"2026-06-29"
		-- 		 		                             }
 		--                              ]
 		--                              ,"updatePrices":0
 		--                              ,"userCode":"01715"
 		--                     }'
-- {"process":"checkprices.list","data":

	
	DECLARE @DATE_NEW_OUTBOUND  AS DATE = CAST('2027-01-01' AS DATE) --- Espera a la Aprobacion de Ivan 
	DECLARE @DATE_GETDATE       AS DATE = CAST(GETDATE() AS DATE)
    DECLARE @message        AS VARCHAR(100)
    DECLARE @messageData    AS NVARCHAR(MAX)
    DECLARE @error          AS BIT
    DECLARE @result         AS NVARCHAR(MAX)
	DECLARE @versionCheckPrices AS VARCHAR(100) = '20260630.0.0.3 Espera Aprobacion de OutboundFreigh 20260901'
	SET @messageData    = '[]' 
	SET @result         = '[]' 
	SET @error          = 0
    SET @message        = CONCAT('Error version ',@versionCheckPrices)  

    BEGIN TRY
        
		-- ----------------------------------------------------------------------------------------------------
		-- ---------------------------checkprices.list------------------------------------------------
		-- ----------------------------------------------------------------------------------------------------
		IF @process = 'checkprices.list'
		BEGIN
				PRINT CONCAT(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'checkprices.list')
				
				
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		----------TABLAS A UTILIZAR EN CODIGO--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				DROP TABLE IF EXISTS #TB_ParametersJOIN				---Tabla de parametros de las waybill, la cual llena segun filtros enviados
				DROP TABLE IF EXISTS #TB_ParametersColumns			---Tabla que contiene todas las columnas que se agregan para los decorados.
				DROP TABLE IF EXISTS #FINALTABLE					---TABLA FINAL PARA VER DATOS CON VALIDACIONES, FORMULAS, PRECIOS UNITARIOS, ETC
			    ---##TB_Result_Decoration                           ---Tabla por decorados que se crea y se elimina para actualizacion de la tabla FINAL
                
                DROP TABLE IF EXISTS #TB_Parameters_PigmentDye      ---Tabla de precios para pygment dye.               TABLA: [AppsLCA].[dbo].[TB_Parameters_BillingPigmentDye] 
                DROP TABLE IF EXISTS #TB_Parameters_Formulas        ---Tabla de formulas por decorado.                  TABLA: [AppsLCA].[dbo].[TB_Parameters_BillingDecoration_FreightCost]
				DROP TABLE IF EXISTS #TB_PAR_BILLINGPRICES			---Tabla de precios por taskname.                   TABLA: [AppsLCA].[dbo].[TB_Parameters_BillingPrices]
				DROP TABLE IF EXISTS #TB_PRICES_NEW			        ---Tabla de catalogo de precios LCA.                TABLA: [AppsLCA].[dbo].[Prices_New]
				                                                    ---Tabla de Costos para purchasePrice.              TABLA: [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Materials]
				DROP TABLE IF EXISTS #TB_StyleInvoiceDescription    ---Tabla de una vista de invoice description        TABLA: [LCA].[dboReaders].[VW_CommercialInvoice_FabricContent_Options]
				DROP TABLE IF EXISTS #TB_FAMO_SUMMARY               ---Tabla de Costos Summary                          TABLA: [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Summary]
				
				DROP TABLE IF EXISTS #TB_MOS_REVIEW					---Tabla con todas las EO/RO/MO para revisar
				DROP TABLE IF EXISTS #TB_DATA_ACTIVE_MOS			---Tabla con las MOS activas donde se toma dato real de MOS
				DROP TABLE IF EXISTS #TB_DATA_ACTIVE_MOS_WORKTASK	---Tabla de MOs con sus tareas
				DROP TABLE IF EXISTS #TB_Group_MO					---Tabla de MOS a revisar
				DROP TABLE IF EXISTS #AllGroupMOExport				---Tabla de MOS de tabla #FINALTABLE
				DROP TABLE IF EXISTS #TB_WF_EORO					---Tablas que busca sus ROs de las EOs
                
                
                -----TABLAS AUXILIARES PARA PIGMENT DYE
                DROP TABLE IF EXISTS #RawMaterialsPigmentDye        ---Tabla de PartNumbers PDT y con color PFG
                DROP TABLE IF EXISTS #TB_MOS_PigmentDye             ---Tabla de MOS segun transacciones de los partnumbers PDT y con color PFG
                
                
                -----TABLAS AUXILIARES PARA BORDADO
                DROP TABLE IF EXISTS #TB_Group_MO_Embroidery        ---Tabla de MOS con decorados que son EmbroideryApparel y EmbroideryHeadwear
			    DROP TABLE IF EXISTS #TB_Data_MO_Bordado            ---Tabla con la informacion con las MO Bordadas
			    DROP TABLE IF EXISTS #TB_Data_MO_BordadoTotal       ---Tabla con totales de bordados por catalogo
		        DROP TABLE IF EXISTS #TB_Data_Sales_Embroidery      ---Tabla con totales de bordados segun  por MO
			    DROP TABLE IF EXISTS #Final_MO_Embroidery           ---Tabla final de Bordados para actualizar mi tabla FINAL
			    
			    -----TABLAS AUXILIARES PARA ESTILOS
                DROP TABLE IF EXISTS #TB_Group_Style                ---Tabla de agrupacion por estilos de mi tabla FINAL
                
                -----TABLAS AUXILIARES PARA VALIDACION DE FORMULAS DINAMICAS
                DROP TABLE IF EXISTS #TB_FinalCols                 ---Tabla que contiene todas las columnas disponibles en la tabla #FINALTABLE (destino de las formulas)
                DROP TABLE IF EXISTS #TB_AllowedFormulaCols        ---Tabla con las columnas permitidas provenientes de [AppsLCA].[dbo].[TB_Parameters_BillingDecoration_FreightCost] (parametros de formulas)
                DROP TABLE IF EXISTS #TB_FormulaTokens             ---Tabla que descompone cada formula en tokens (columnas) encontradas entre corchetes [ ]
                DROP TABLE IF EXISTS #TB_MissingTokens             ---Tabla que identifica los tokens usados en formulas que NO existen ni en #FINALTABLE ni en parametros permitidos
                DROP TABLE IF EXISTS #TB_MissingAgg                ---Tabla que agrupa por decorado (NameDecoration) los errores de columnas faltantes en formulas

		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				
				
				DECLARE @userCode           AS VARCHAR(10)
				DECLARE @updatePrices       AS INT
				DECLARE @password           AS VARCHAR(200)
				
				SET @userCode       = JSON_VALUE(@data,'$.userCode')
				SET @password       = JSON_VALUE(@data,'$.password')
				SET @updatePrices   = TRY_CONVERT(INT, JSON_VALUE(@data,'$.updatePrices'))
				SET @updatePrices   = ISNULL(@updatePrices,0)



				DECLARE @listWaybills		AS NVARCHAR(MAX)
				SET @listWaybills			= (SELECT JSON_QUERY(@data, '$.selectedOptions'))
				
				
				-----CAMBIAR PARA TOMAR PERIODO JH COMENTAR
				SELECT 
				     [rowN]			= STJ.[R]
					,[Waybill]		= STJ.[Waybill] 
					,[ShipDate]     = CAST(STJ.[ShipDate] AS DATE)
				INTO #TB_ParametersJOIN
				FROM OPENJSON(@listWaybills)
				WITH (	 
					     [R]			INT
						,[Waybill]		VARCHAR(200)
						,[ShipDate]     DATE
					) AS STJ
				-----CAMBIAR PARA TOMAR PERIODO JH COMENTAR
				
				-- SELECT * FROM #TB_ParametersJOIN
				-- RETURN
				-----CAMBIAR PARA TOMAR PERIODO JH DESCOMENTAR
				-- SET @userCode     = '01715'
				-- SET @updatePrices = 1
				-- SELECT 
				-- 	[rowN]  = ROW_NUMBER() OVER(ORDER BY [ShipDate],[Waybill])
				-- 	,[Waybill]
				-- INTO #TB_ParametersJOIN
				-- FROM(
				-- 	SELECT 
				-- 		     [Waybill]          = SH.WayBill   
			    --             ,[ShipDate]         = CAST(MAX(SHC.ShipDate) AS DATE)
			    --     FROM (SELECT StatusID,StatusName FROM [LCA].[dbo].StatusNames WITH(NOLOCK) WHERE [StatusID] <=90) AS SNMO ---MOs Activas y complete
			    --     INNER JOIN  [LCA].[dbo].ManufactureOrders   AS MO	WITH(NOLOCK) ON MO.StatusID               = SNMO.StatusID     AND MO.StatusID <= 90
			    --     INNER JOIN  [LCA].[dbo].PackedItems         AS PI	WITH(NOLOCK) ON PI.ManufactureID          = MO.ManufactureID  AND PI.Quantity > 0
			    --     INNER JOIN  [LCA].[dbo].PackedBoxes         AS PB	WITH(NOLOCK) ON PB.PackedBoxID            = PI.PackedBoxID    AND PB.StatusID IN (25,27,75) ---MOS Que esten en estatus Packed o Picked
			    --     INNER JOIN  [LCA].[dbo].Shipments           AS SH	WITH(NOLOCK) ON SH.ShipmentID             = PB.ShipmentID
			    --     INNER JOIN  [LCA].[dbo].ShippingContainers  AS SHC  WITH(NOLOCK) ON SHC.ShippingContainerID   = SH.ShippingContainerID 
			    --                                                                                                     AND CAST(SHC.ShipDate AS DATE) >= CAST('2026-01-01' AS DATE)
			    --                                                                                                     AND CAST(SHC.ShipDate AS DATE) < CAST('2026-02-10' AS DATE)
			        
				-- 	GROUP BY 
				-- 		[WayBill]
				-- 	)AS TB	
				-----CAMBIAR PARA TOMAR PERIODO JH DESCOMENTAR	
					
				
				-- si viene updatePrices=1 entonces el password es obligatorio
				IF ISNULL(@updatePrices,0) = 1
				AND (NULLIF(LTRIM(RTRIM(@password)),'') IS NULL)
				BEGIN
				    SET @error = 1
				    SET @message = 'Password requerido para actualizar precios.'
				    GOTO EndProcedureCheckPrices
				END

				
				IF @error = 0 AND @updatePrices = 1
				AND NOT EXISTS (
				    SELECT 1
				    FROM [AppsLCA].[dbo].[PID_InventoryUsers] WITH(NOLOCK)
				    WHERE [status] = 1
				      AND [CheckPrice] = 1
				      AND [user] = @userCode
				      AND [pin] = @password
				)
				BEGIN
				    SET @error = 1
				    SET @message = 'Contraseña incorrecta o usuario sin permiso para actualizar precios.'
				    GOTO EndProcedureCheckPrices
				END

				-- -----CAMBIAR PARA TOMAR PERIODO JH COMENTAR
				IF @error = 0 AND @updatePrices = 1
				AND EXISTS (
				    SELECT 1
				    FROM #TB_ParametersJOIN AS W
				    INNER JOIN AppsLCA.dbo.DTE_FACTURAS_ELECTRONICAS AS FE WITH(NOLOCK)
				        ON FE.factura = W.Waybill
				       AND FE.invalidado = 0
				)
				BEGIN
				    SET @error = 1
				    SET @message = 'No se puede actualizar. Hay Waybills ya facturados (DTE).'
				    GOTO EndProcedureCheckPrices
				END
				-----CAMBIAR PARA TOMAR PERIODO JH COMENTAR

	
        
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		----------TABLAS PARAMETROS GLOBALES---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		    SELECT
		         [LCABasePrice]		                    = CAST(NULL AS DECIMAL(18,2))	        ---Precio base LCA (Blank producido en LCA)
				,[SublimationBasePrice]                 = CAST(NULL AS DECIMAL(18,2))	        ---Precio base del proceso de Sublimation
				,[PurchaseBasePrice]                    = CAST(NULL AS DECIMAL(18,2))	        ---Precio base de compra (Purchase)
				,[PurchaseFreightPrice]                 = CAST(NULL AS DECIMAL(18,2))	        ---Costo de flete asociado a la compra
				,[PigmentDyeBasePrice]                  = CAST(NULL AS DECIMAL(18,2))	        ---Precio base del proceso Pigment Dye
				,[TariffCategory]                       = CAST(NULL AS VARCHAR(200))	        ---Categoría arancelaria / HTS
							
		        ,[ScreenPrint]			                = CAST(0 AS INT)		                ---Cantidad tareas de procesos Screen Print
		        ,[Sublimation]			                = CAST(0 AS INT)		                ---Cantidad tareas de procesos Sublimation
		        ,[EmbroideryAPP]		                = CAST(0 AS INT)		                ---Cantidad tareas de bordados Apparel
		        ,[EmbroideryHW]			                = CAST(0 AS INT)		                ---Cantidad tareas de bordados Headwear
		        ,[Relabel]				                = CAST(0 AS INT)		                ---Cantidad tareas de procesos Re-label
		        ,[SubApplication]		                = CAST(0 AS INT)		                ---Cantidad tareas de Sub Applications
		        ,[HDP]					                = CAST(0 AS INT)		                ---Cantidad tareas de procesos HDP
		        ,[SpecialPK]    		                = CAST(0 AS INT)		                ---Cantidad tareas de empaques especiales
		        ,[PigmentDye]    		                = CAST(0 AS INT)		                ---Cantidad tareas de procesos Pigment Dye
		        ,[Samples]    		                    = CAST(0 AS INT)		                ---Cantidad tareas de procesos Samples
		        -- ,[SNApplication]    		            = CAST(0 AS INT)		                ---Cantidad tareas de procesos SNApplication
		        ,[BlankLCA]    		                    = CAST(0 AS INT)		                ---Cantidad tareas en workflow de blanks LCA
		        ,[BlankSemiApp]    		                = CAST(0 AS INT)		                ---Cantidad tareas en workflow de blanks Semi Apparel
		        ,[BlankSemiHW]    		                = CAST(0 AS INT)		                ---Cantidad tareas en workflow de blanks Semi Headwear
		        
		        ,[InlandFreight]	                    = CAST(0 AS INT)		                ---Proceso si es Inland, Envio de MIAMI A OTRO LUGAR DE USA
		        ,[AirFreight]	                        = CAST(0 AS INT)		                ---Proceso si es Air, ENVIO POR AEREO
		        ,[OceanFreight]		                    = CAST(0 AS INT)		                ---Proceso si es Ocean, ENVIO POR CONTENEDOR
				                        
				,[UnitPrice_ScreenPrint]                = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario segun tareas para procesos de Screen Print
				,[UnitPrice_Sublimation]                = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario segun tareas para procesos de Sublimation
				,[UnitPrice_EmbroideryApp]              = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario segun tareas para procesos de Embroidery Apparel
				,[UnitPrice_EmbroideryHW]               = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario segun tareas para procesos de Embroidery Headwear
				,[UnitPrice_Relabel]                    = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario segun tareas para procesos de Re-label
				,[UnitPrice_SubApplication]             = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario segun tareas para procesos de Sub Application
				,[UnitPrice_HDP]                        = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario segun tareas para procesos de HDP
				,[UnitPrice_SpecialPK]                  = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario segun tareas para procesos de Special Packaging
				,[UnitPrice_PigmentDye]                 = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario segun tareas para procesos de Pigment Dye
				,[UnitPrice_Samples]                    = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario segun tareas para procesos de Samples
				-- ,[UnitPrice_SNApplication]              = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario segun tareas para procesos de SNApplication
				,[UnitPrice_BlankLCA]    	            = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario segun tareas para procesos de Blank LCA
				,[UnitPrice_BlankSemiApp]               = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario segun tareas para procesos de Blank Semi Apparel
				,[UnitPrice_BlankSemiHW]                = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario segun tareas para procesos de Blank Semi Headwear
						                
						                
		        ,[CodePrice_EmbroideryApp]              = CAST(NULL AS DECIMAL(18,2))	        ---Precio por codigos Embroidery Apparel
		        ,[CodePrice_EmbroideryHW]               = CAST(NULL AS DECIMAL(18,2))	        ---Precio por codigos Embroidery Headwear
				,[Price_ScreenPrint]                    = CAST(NULL AS DECIMAL(18,2))	        ---Precio Unitario total calculado para el proceso de Screen Print
		        ,[Price_Sublimation]                    = CAST(NULL AS DECIMAL(18,2))	        ---Precio Unitario total calculado para el proceso de Sublimation
		        ,[Price_EmbroideryApp]                  = CAST(NULL AS DECIMAL(18,2))	        ---Precio Unitario total calculado para el proceso de Embroidery Apparel
		        ,[Price_EmbroideryHW]                   = CAST(NULL AS DECIMAL(18,2))	        ---Precio Unitario total calculado para el proceso de Embroidery Headwear
		        ,[Price_Relabel]                        = CAST(NULL AS DECIMAL(18,2))	        ---Precio Unitario total calculado para el proceso de Re-label
		        ,[Price_SubApplication]                 = CAST(NULL AS DECIMAL(18,2))	        ---Precio Unitario total calculado para el proceso de Sub Application
		        ,[Price_HDP]                            = CAST(NULL AS DECIMAL(18,2))	        ---Precio Unitario total calculado para el proceso de HDP
		        ,[Price_SpecialPK]                      = CAST(NULL AS DECIMAL(18,2))	        ---Precio Unitario total calculado para el proceso de Special Packaging
		        ,[Price_PigmentDye]                     = CAST(NULL AS DECIMAL(18,2))	        ---Precio Unitario total calculado para el proceso de Pigment Dye
		        ,[Price_Samples]                        = CAST(NULL AS DECIMAL(18,2))	        ---Precio Unitario total calculado para el proceso de Samples
		        -- ,[Price_SNApplication]                  = CAST(NULL AS DECIMAL(18,2))	        ---Precio Unitario total calculado para el proceso de SNApplication
		        ,[Price_BlankLCA]                       = CAST(NULL AS DECIMAL(18,2))	        ---Precio Unitario total calculado para el proceso de Blank LCA
		        ,[Price_BlankSemiApp]                   = CAST(NULL AS DECIMAL(18,2))	        ---Precio Unitario total calculado para el proceso de Blank Semi Apparel
		        ,[Price_BlankSemiHW]                    = CAST(NULL AS DECIMAL(18,2))	        ---Precio Unitario total calculado para el proceso de Blank Semi Headwear
		        
		        ,[Price_InlandFreight]   		        = CAST(NULL AS DECIMAL(18,2))
                ,[Price_AirFreight]  		            = CAST(NULL AS DECIMAL(18,2))
                ,[Price_OceanFreight]   		        = CAST(NULL AS DECIMAL(18,2))
		        
			    ,[TotalBlank]                           = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario total calculado para Blank
				,[OutboundFreight]                      = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario total calculado para Outbound Freight
			    ,[TotalDecoration]                      = CAST(NULL AS DECIMAL(18,2))	        ---Precio unitario total calculado para Decoration
				                
				,[Rev_ScreenPrint]		                = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Screen Print
		        ,[Rev_Sublimation]		                = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Sublimation
		        ,[Rev_EmbroideryApp]                    = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Embroidery Apparel
		        ,[Rev_EmbroideryHW]		                = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Embroidery Headwear
		        ,[Rev_Relabel]			                = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Re-label
		        ,[Rev_SubApplication]	                = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Sub Application
		        ,[Rev_HDP]				                = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos HDP
		        ,[Rev_SpecialPK]    	                = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Special Packaging
		        ,[Rev_PigmentDye]    	                = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Pigment Dye
		        ,[Rev_Samples]    	                    = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Samples
		        -- ,[Rev_SNApplication]    	            = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos SNApplication
				,[Rev_OutboundFreight]                  = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Outbound Freight
			    ,[Rev_BlankLCA]    	                    = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Blank LCA
		        ,[Rev_BlankSemiApp]    	                = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Blank Semi Apparel
		        ,[Rev_BlankSemiHW]    	                = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Blank Semi Headwear
		        ,[Rev_InvoicingDescription]             = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Invoice Description
		        ,[Rev_OrderType]                        = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Order Type
		        ,[Rev_DecorationWorkflow]               = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Decoration Workflow
		        ,[Rev_TariffCategory]                   = CAST(NULL AS VARCHAR(MAX))	        ---Revisión de procesos Tariff Category
		        
				,[Rev_Final]		                    = CAST(0 AS INT)		                ---Flag final de revisión donde se coloca todos los datos
				,[Rev_Comments]		                    = CAST(NULL AS VARCHAR(MAX))	        ---Comentarios generales de revisión, unión de todas las revisiones
						                
				,[Formula_ScreenPrint]                  = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de Screen Print
			    ,[Formula_Sublimation]                  = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de Sublimation
			    ,[Formula_EmbroideryApp]                = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de Embroidery Apparel
			    ,[Formula_EmbroideryHW]                 = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de Embroidery Headwear
			    ,[Formula_Relabel]                      = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de Re-label
			    ,[Formula_SubApplication]               = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de Sub Application
			    ,[Formula_HDP]                          = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de HDP
			    ,[Formula_SpecialPK]                    = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de Special Packaging
			    ,[Formula_PigmentDye]                   = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de Pigment Dye
			    ,[Formula_Samples]                      = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de Samples
			    -- ,[Formula_SNApplication]                = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de SNApplication
			    
			    ,[Formula_InlandFreight]               = CAST(NULL AS VARCHAR(MAX))	            ---
			    ,[Formula_AirFreight]                  = CAST(NULL AS VARCHAR(MAX))	            ---
			    ,[Formula_OceanFreight]                = CAST(NULL AS VARCHAR(MAX))	            ---
			    
			    ,[Formula_OutboundFreight]             = CAST(NULL AS VARCHAR(MAX))	            ---
			    
			    ,[Formula_BlankLCA]                     = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de Blank LCA
			    ,[Formula_BlankSemiApp]                 = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de Blank Semi Apparel
			    ,[Formula_BlankSemiHW]                  = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de Blank Semi Headwear
			    ,[Formula_TotalBlank]                   = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de Total Blank
			    ,[Formula_TotalDecoration]              = CAST(NULL AS VARCHAR(MAX))	        ---Fórmula donde se colocan los datos de columnas para el proceso de Total Decoration
		INTO #TB_ParametersColumns

		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		----------PROCEDIMIENTO PARA OBETENER MOS----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------    
		    -------*MOS PARA VER DATOS-------
		        SELECT DISTINCT
		             [ManufactureID]    = MO.ManufactureID
		            ,[MO]               = MO.ManufactureNumber
		            ,[Season]           = ISNULL(SN.SeasonName,'')
		            ,[Waybill]          = SH.WayBill   
		            ,[TotalUnitsExport] = SUM(PI.[Quantity])
					,[FilterMOExport]	= CAST(1 AS BIT)
					,[PigmentDye]       = CAST(0 AS INT)
		        INTO #TB_MOS_REVIEW
		        FROM (SELECT StatusID,StatusName FROM [LCA].[dbo].StatusNames WITH(NOLOCK) WHERE [StatusID] <=90) AS SNMO ---MOs Activas y complete
		        INNER JOIN  [LCA].[dbo].ManufactureOrders   AS MO	WITH(NOLOCK) ON MO.StatusID               = SNMO.StatusID     AND MO.StatusID <= 90
		        INNER JOIN  [LCA].[dbo].PackedItems         AS PI	WITH(NOLOCK) ON PI.ManufactureID          = MO.ManufactureID  AND PI.Quantity > 0
		        INNER JOIN  [LCA].[dbo].PackedBoxes         AS PB	WITH(NOLOCK) ON PB.PackedBoxID            = PI.PackedBoxID    AND PB.StatusID IN (25,27,75) ---MOS Que esten en estatus Packed o Picked
		        INNER JOIN  [LCA].[dbo].Shipments           AS SH	WITH(NOLOCK) ON SH.ShipmentID             = PB.ShipmentID
				INNER JOIN	#TB_ParametersJOIN				AS FSH				 ON FSH.Waybill				  = SH.WayBill
		        INNER JOIN  [LCA].[dbo].OrderItems          AS OI	WITH(NOLOCK) ON OI.OrderItemID            = MO.FirstOrderItemID
		        INNER JOIN  [LCA].[dbo].Styles              AS ST	WITH(NOLOCK) ON ST.StyleID                = OI.StyleID
		        INNER JOIN  [LCA].[dbo].Seasons             AS SN	WITH(NOLOCK) ON SN.SeasonID               = ST.SeasonID
		        GROUP BY 
		              MO.ManufactureID
                     ,MO.ManufactureNumber
                     ,ISNULL(SN.SeasonName,'')
                     ,SH.WayBill   
                     
                    
		        -------*EOS--------
				    SELECT DISTINCT [ManufactureID],[Waybill]
				    INTO #TB_Group_MO 
				    FROM #TB_MOS_REVIEW
				    WHERE [Season] IN ('EMB','EMB FG') 
					        
		        
		            SELECT
						 [Waybill]      = FMO.Waybill
						,[EO_ID]		= eo.ManufactureID
						,[EO]			= eo.ManufactureNumber
						,[RO_ID]		= mo.ManufactureID
						,[RO]			= mo.ManufactureNumber
						,[UnitsEORO]    = SUM(pit.Quantity)
		                ,[Season]       = ISNULL(SNS.SeasonName,'')
						
					INTO #TB_WF_EORO
					FROM  	     (SELECT StatusID,StatusName FROM [LCA].[dbo].StatusNames WITH(NOLOCK) WHERE StatusID<=90)             AS SN   
					INNER JOIN  [LCA].[dbo].ManufactureOrders 	    AS mo   WITH(NOLOCK) ON SN.StatusID  = mo.StatusID AND MO.StatusID <=90
					INNER JOIN  [LCA].[dbo].PackedItems 			AS pit  WITH(NOLOCK) ON mo.ManufactureID 	= pit.ManufactureID
					INNER JOIN  [LCA].[dbo].ManufactureOrders 	    AS eo   WITH(NOLOCK) ON eo.ManufactureID 	= pit.AttachedManufactureID		AND (eo.ManufactureNumber IS NOT NULL)
					INNER JOIN  #TB_Group_MO                        AS FMO               ON FMO.ManufactureID	= eo.ManufactureID 
					INNER JOIN  [LCA].[dbo].OrderItems              AS OI   WITH(NOLOCK) ON OI.OrderItemID      = MO.FirstOrderItemID
		            INNER JOIN  [LCA].[dbo].Styles                  AS ST   WITH(NOLOCK) ON ST.StyleID          = OI.StyleID
		            INNER JOIN  [LCA].[dbo].Seasons                 AS SNS  WITH(NOLOCK) ON SNS.SeasonID        = ST.SeasonID
					GROUP BY
						eo.ManufactureID
						,eo.ManufactureNumber
						,mo.ManufactureID
						,mo.ManufactureNumber
						,ISNULL(SNS.SeasonName,'')
						,FMO.Waybill
						
					HAVING
						SUM(pit.Quantity) > 0
						
						-- select * from #TB_WF_EORO
						-- WHERE eo IN ('EO5159232-600','EO5495321-493')
						-- return
		        -------*EOS--------
		        
				INSERT INTO #TB_MOS_REVIEW
				SELECT DISTINCT  [RO_ID]  
		                        ,[RO]             
		                        ,[Season]  
		                        ,[WAYBILL]          = [Waybill]
		                        ,[TotalUnitsExport] = 0
								,[FilterMOExport]   = 0
								,[PigmentDye] = CAST(0 AS INT)
		        FROM #TB_WF_EORO 
		                
		    -------*MOS PARA VER DATOS-------
		     
				
		    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		    -----PYGMENT DYE PROCESS---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
						    
					SELECT * INTO #TB_Parameters_PigmentDye FROM [AppsLCA].[dbo].[TB_Parameters_BillingPigmentDye] WITH(NOLOCK)
					
				
				    SELECT 
				        [Category]          = CC.CategoryName
				        ,[SubCategory]      = CS.SubCategoryName
				        ,[Component]        = C.ComponentName
				        ,[PartNumber]       = RM.PartNumber
				        ,[RawMaterialID]    = RM.RawMaterialID
				    INTO #RawMaterialsPigmentDye    
				    FROM [LCA].[dbo].ComponentCategories            AS CC   WITH(NOLOCK)
				    INNER JOIN [LCA].[dbo].ComponentSubcategories   AS CS   WITH(NOLOCK) ON CS.ComponentCategoryID = CC.ComponentCategoryID 
				                                                                            AND CC.ComponentCategoryID = 11  --Contracts
				                                                                            AND CS.SubCategoryName LIKE '%FINISH%'
				                                                                            AND CS.SubCategoryName LIKE '%GOOD%'
				    INNER JOIN [LCA].[dbo].ComponentLibrary         AS C    WITH(NOLOCK) ON CC.ComponentCategoryID = C.ComponentCategoryID AND CS.SubCategoryID = C.SubCategoryID
				                                                                            AND C.ComponentName LIKE '%PDT%'
				    INNER JOIN [LCA].[dbo].RawMaterials             AS RM   WITH(NOLOCK) ON C.ComponentID = RM.ComponentID
				                                                                            AND RM.PartNumber LIKE '%PFD%' 
				    
				
				
				    SELECT 
				         [ManufactureID]    = RT.ManufactureID
				        ,[MO]               = MO.ManufactureNumber
				        ,[Qty]              = SUM(CT.[Quantity]) 
				    INTO #TB_MOS_PigmentDye
				    FROM #RawMaterialsPigmentDye AS PD
				    INNER JOIN  [LCA].[dbo].RawTransactions         AS RT WITH(NOLOCK) ON RT.RawMaterialID = PD.RawMaterialID AND RT.ManufactureID IS NOT NULL
				    LEFT JOIN   [LCA].[dbo].ContainerTransfers      AS CT WITH(NOLOCK) ON RT.RawTransactionID         = CT.RawTransactionID
				    LEFT JOIN   [LCA].[dbo].ManufactureOrders       AS MO WITH(NOLOCK) ON RT.ManufactureID      = MO.ManufactureID
				    GROUP BY RT.ManufactureID ,MO.ManufactureNumber
				    HAVING SUM(CT.[Quantity]) <> 0
				    
				    UPDATE S SET
				        [PigmentDye] = 1
	                FROM #TB_MOS_REVIEW AS S
	                INNER JOIN #TB_MOS_PigmentDye AS PY ON S.ManufactureID = PY.ManufactureID
		    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		    -----PYGMENT DYE PROCESS---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		    
		        
		        
		    -------*MOS CON DATOS QUE SE REVISAN-------
		        SELECT 
		             [Waybill]                  = MOPB.Waybill
		            ,[ManufactureID]            = MO.ManufactureID
		            ,[MO]                       = MO.ManufactureNumber
		            ,[OrderID]                  = ISNULL(MO.OrderID, OI.OrderID)
		            ,[PONumber]                 = OD.PONumber
					,[OrderItemID]		        = OI.OrderItemID
		            ,[ItemDetailID]             = CASE 
		                                            WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
		                                                NULL
		                                            WHEN ( od.[PONumber] LIKE 'ORD-%') AND ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
		                                                try_cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT) 
		                                            WHEN ( od.[PONumber] LIKE 'ORD%') AND (ISNUMERIC(od.Comments6) = 1 ) THEN
		                                                try_cast(od.[Comments6] AS BIGINT)
		                                            ELSE
		                                                NULL 
		                                            END 
		            ,[StatusMOID]              = SNMO.StatusID
		            ,[StatusMO]                = SNMO.StatusName
		            ,[SaveDate]                = MO.SaveDate
		            ,[StyleID]                 = ST.StyleID
		            ,[Style]                   = ST.StyleNumber
					,[Color]			       = SC.StyleColorName
		            ,[Season]                  = COALESCE(SS.SeasonName,'')
		            ,[BlankStyleID]            = ST.[BlankStyleID]
		            ,[BlankStyle]              = STB.[StyleNumber]
		            ,[StyleDivision]	       = IIF(TRIM(ST.Comments9) = 'Headwear'	,'Headwear','Apparel')
					,[TotalUnitsExport]        = MOPB.[TotalUnitsExport]
					,[BasePrice]		       = OI.PricingUnitCost2
					,[TotalPrintValue]	       = OI.PricingUnitCost 
					,[UnitPrice]		       = OI.UnitPrice
					,[InvoicingDescription]    = CAST(NULL AS VARCHAR(200))
					,[OrderType2]              = OT2.DropDownValue
					,[PrintCount]		       = IIF( TRY_CAST(OD.Comments14 AS INT) IS NULL, 0, OD.Comments14 )
					,[Comments17]              = MO.Comments17
					,[StyleOptionID]	       =
										            	TRY_CONVERT(INT,
										            		LTRIM(RTRIM(
										            			CASE
										            				WHEN CHARINDEX('|', MO.Comments17) > 0
										            					THEN LEFT(MO.Comments17, CHARINDEX('|', MO.Comments17) - 1)
										            				ELSE MO.Comments17
										            			END
										            		))
										            	)
		                                        
					,[StyleOption]		       =
										            	LTRIM(RTRIM(
										            		CASE
										            			WHEN CHARINDEX('|', MO.Comments17) > 0
										            				THEN SUBSTRING(
										            						MO.Comments17,
										            						CHARINDEX('|', MO.Comments17) + 1,
										            						LEN(MO.Comments17)
										            					 )
										            			ELSE ''
										            		END
										            	))
		                                            
					,[Code]				       = OD.Comments26
					,[FilterMOExport]	       = MOPB.FilterMOExport
					,[PigmentDyeTransaction]   = MOPB.PigmentDye
					
		            ,PAR.*
		            
		        INTO #TB_DATA_ACTIVE_MOS
		        FROM (SELECT StatusID,StatusName FROM [LCA].[dbo].StatusNames WITH(NOLOCK) WHERE [StatusID] > 40 AND [StatusID] <=90) AS SNMO ---MOs que no esten Forecast 20, Relesead 40, Active 30, Incomplete 10
		        INNER JOIN  [LCA].[dbo].ManufactureOrders   AS MO   WITH(NOLOCK) ON MO.StatusID         = SNMO.StatusID AND MO.StatusID <= 90
		        INNER JOIN   #TB_MOS_REVIEW                 AS MOPB              ON MOPB.ManufactureID  = MO.ManufactureID
		        LEFT JOIN   [LCA].[dbo].OrderItems          AS OI   WITH(NOLOCK) ON OI.OrderItemID      = MO.FirstOrderItemID
		        LEFT JOIN   [LCA].[dbo].Orders              AS OD   WITH(NOLOCK) ON OD.OrderID          = ISNULL(MO.OrderID, OI.OrderID)
		        LEFT JOIN   [LCA].[dbo].Styles              AS ST   WITH(NOLOCK) ON ST.StyleID          = OI.StyleID
				INNER JOIN	[LCA].[dbo].StyleColors			AS SC	WITH(NOLOCK) ON SC.StyleColorID		= OI.StyleColorID
		        LEFT JOIN   [LCA].[dbo].Seasons             AS SS   WITH(NOLOCK) ON SS.SeasonID         = ST.SeasonID
		        LEFT JOIN   [LCA].[dbo].DropDownValues2     AS OT2  WITH(NOLOCK) ON OD.OrderTypeID2     = OT2.DropDownValueID   
		        LEFT JOIN   [LCA].[dbo].Styles              AS STB  WITH(NOLOCK) ON STB.StyleID         = ST.BlankStyleID
		        CROSS APPLY #TB_ParametersColumns AS PAR
		 
		    -------*MOS CON DATOS QUE SE REVISAN-------
		
		
				
		    -------*WORK FLOWS TASK-------
		        SELECT 
		            FMO.*
		            ,[Sequence]         = WT.Sequence
		            ,[TaskName]         = WT.TaskName
		            ,[WTStartDate]      = WT.StartDate
		            ,[WTFinishDate]     = WT.FinishDate
		        INTO #TB_DATA_ACTIVE_MOS_WORKTASK
		        FROM #TB_DATA_ACTIVE_MOS AS FMO
		        INNER JOIN [LCA].[dbo].WorkFlows            AS WF   WITH(NOLOCK) ON WF.ManufactureID    = FMO.ManufactureID
		        INNER JOIN [LCA].[dbo].WorkTasks            AS WT   WITH(NOLOCK) ON WT.WorkFlowID       = WF.WorkFlowID
		    -------*WORK FLOWS TASK-------
		
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------    
			
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------    
		------ACTUALIZACION DE PROCESOS SEGUN TABLA PARAMETERS---------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------    
			SELECT * INTO #TB_PAR_BILLINGPRICES FROM [AppsLCA].[dbo].[TB_Parameters_BillingPrices] WITH(NOLOCK)
		
			UPDATE S SET
		     
				[ScreenPrint] = CASE
								  WHEN EXISTS
								  (
									  SELECT 1 FROM #TB_PAR_BILLINGPRICES AS R WITH(NOLOCK) WHERE R.[NameDecoration] = 'ScreenPrint'
										AND (R.[PONumberStartsWith] IS NULL OR S.[PONumber] LIKE R.[PONumberStartsWith] + N'%')
                                    AND (R.[SeasonIn]    IS NULL OR (N',' + R.[SeasonIn]    + N',') LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[SeasonNotIn] IS NULL OR (N',' + R.[SeasonNotIn] + N',') NOT LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[StyleDivisionIn] IS NULL OR (N',' + R.[StyleDivisionIn]    + N',') LIKE N'%,' + S.[StyleDivision] + N',%')
                                    AND (R.[StyleDivisionNotIn] IS NULL OR (N',' + R.[StyleDivisionNotIn] + N',') NOT LIKE N'%,' + S.[StyleDivision] + N',%')
										AND (
												R.[Condition] = 'none'
												OR R.[TaskName] = N''
												OR (R.[Condition] = 'equal'    AND S.[TaskName] = R.[TaskName])
												OR (R.[Condition] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskName] + N'%')
												OR (R.[Condition] = 'start'    AND S.[TaskName] LIKE R.[TaskName] + N'%')
												OR (R.[Condition] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskName])
											)
										AND (
												R.[ConditionNo] = 'none'
												OR R.[TaskNameNo] = N''
												OR NOT
												(
													   (R.[ConditionNo] = 'equal'    AND S.[TaskName] = R.[TaskNameNo])
													OR (R.[ConditionNo] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'start'    AND S.[TaskName] LIKE R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] )
												)
											)
								  )
								  THEN 1
								  ELSE 0
							  END
				,[Sublimation] = CASE
								  WHEN EXISTS
								  (
									  SELECT 1 FROM #TB_PAR_BILLINGPRICES AS R WITH(NOLOCK) WHERE R.[NameDecoration] = 'Sublimation'
										AND (R.[PONumberStartsWith] IS NULL OR S.[PONumber] LIKE R.[PONumberStartsWith] + N'%')
                                    AND (R.[SeasonIn]    IS NULL OR (N',' + R.[SeasonIn]    + N',') LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[SeasonNotIn] IS NULL OR (N',' + R.[SeasonNotIn] + N',') NOT LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[StyleDivisionIn] IS NULL OR (N',' + R.[StyleDivisionIn]    + N',') LIKE N'%,' + S.[StyleDivision] + N',%')
                                    AND (R.[StyleDivisionNotIn] IS NULL OR (N',' + R.[StyleDivisionNotIn] + N',') NOT LIKE N'%,' + S.[StyleDivision] + N',%')
										AND (
												R.[Condition] = 'none'
												OR R.[TaskName] = N''
												OR (R.[Condition] = 'equal'    AND S.[TaskName] = R.[TaskName])
												OR (R.[Condition] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskName] + N'%')
												OR (R.[Condition] = 'start'    AND S.[TaskName] LIKE R.[TaskName] + N'%')
												OR (R.[Condition] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskName])
											)
										AND (
												R.[ConditionNo] = 'none'
												OR R.[TaskNameNo] = N''
												OR NOT
												(
													   (R.[ConditionNo] = 'equal'    AND S.[TaskName] = R.[TaskNameNo])
													OR (R.[ConditionNo] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'start'    AND S.[TaskName] LIKE R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] )
												)
											)
								  )
								  THEN 1
								  ELSE 0
							  END
				,[EmbroideryAPP]  = CASE
								  WHEN EXISTS
								  (
									  SELECT 1 FROM #TB_PAR_BILLINGPRICES AS R WITH(NOLOCK) WHERE R.[NameDecoration] = 'EmbroideryAPP'
										AND (R.[PONumberStartsWith] IS NULL OR S.[PONumber] LIKE R.[PONumberStartsWith] + N'%')
                                    AND (R.[SeasonIn]    IS NULL OR (N',' + R.[SeasonIn]    + N',') LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[SeasonNotIn] IS NULL OR (N',' + R.[SeasonNotIn] + N',') NOT LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[StyleDivisionIn] IS NULL OR (N',' + R.[StyleDivisionIn]    + N',') LIKE N'%,' + S.[StyleDivision] + N',%')
                                    AND (R.[StyleDivisionNotIn] IS NULL OR (N',' + R.[StyleDivisionNotIn] + N',') NOT LIKE N'%,' + S.[StyleDivision] + N',%')
										AND (
												R.[Condition] = 'none'
												OR R.[TaskName] = N''
												OR (R.[Condition] = 'equal'    AND S.[TaskName] = R.[TaskName])
												OR (R.[Condition] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskName] + N'%')
												OR (R.[Condition] = 'start'    AND S.[TaskName] LIKE R.[TaskName] + N'%')
												OR (R.[Condition] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskName])
											)
										AND (
												R.[ConditionNo] = 'none'
												OR R.[TaskNameNo] = N''
												OR NOT
												(
													   (R.[ConditionNo] = 'equal'    AND S.[TaskName] = R.[TaskNameNo])
													OR (R.[ConditionNo] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'start'    AND S.[TaskName] LIKE R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] )
												)
											)
								  )
								  THEN 1
								  ELSE 0
							  END
				,[EmbroideryHW] = CASE
								  WHEN EXISTS
								  (
									  SELECT 1 FROM #TB_PAR_BILLINGPRICES AS R WITH(NOLOCK) WHERE R.[NameDecoration] = 'EmbroideryHW'
										AND (R.[PONumberStartsWith] IS NULL OR S.[PONumber] LIKE R.[PONumberStartsWith] + N'%')
                                    AND (R.[SeasonIn]    IS NULL OR (N',' + R.[SeasonIn]    + N',') LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[SeasonNotIn] IS NULL OR (N',' + R.[SeasonNotIn] + N',') NOT LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[StyleDivisionIn] IS NULL OR (N',' + R.[StyleDivisionIn]    + N',') LIKE N'%,' + S.[StyleDivision] + N',%')
                                    AND (R.[StyleDivisionNotIn] IS NULL OR (N',' + R.[StyleDivisionNotIn] + N',') NOT LIKE N'%,' + S.[StyleDivision] + N',%')
										AND (
												R.[Condition] = 'none'
												OR R.[TaskName] = N''
												OR (R.[Condition] = 'equal'    AND S.[TaskName] = R.[TaskName])
												OR (R.[Condition] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskName] + N'%')
												OR (R.[Condition] = 'start'    AND S.[TaskName] LIKE R.[TaskName] + N'%')
												OR (R.[Condition] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskName])
											)
										AND (
												R.[ConditionNo] = 'none'
												OR R.[TaskNameNo] = N''
												OR NOT
												(
													   (R.[ConditionNo] = 'equal'    AND S.[TaskName] = R.[TaskNameNo])
													OR (R.[ConditionNo] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'start'    AND S.[TaskName] LIKE R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] )
												)
											)
								  )
								  THEN 1
								  ELSE 0
							  END
				,[Relabel] = CASE
								  WHEN EXISTS
								  (
									  SELECT 1 FROM #TB_PAR_BILLINGPRICES AS R WITH(NOLOCK) WHERE R.[NameDecoration] = 'Relabel'
										AND (R.[PONumberStartsWith] IS NULL OR S.[PONumber] LIKE R.[PONumberStartsWith] + N'%')
                                    AND (R.[SeasonIn]    IS NULL OR (N',' + R.[SeasonIn]    + N',') LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[SeasonNotIn] IS NULL OR (N',' + R.[SeasonNotIn] + N',') NOT LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[StyleDivisionIn] IS NULL OR (N',' + R.[StyleDivisionIn]    + N',') LIKE N'%,' + S.[StyleDivision] + N',%')
                                    AND (R.[StyleDivisionNotIn] IS NULL OR (N',' + R.[StyleDivisionNotIn] + N',') NOT LIKE N'%,' + S.[StyleDivision] + N',%')
										AND (
												R.[Condition] = 'none'
												OR R.[TaskName] = N''
												OR (R.[Condition] = 'equal'    AND S.[TaskName] = R.[TaskName])
												OR (R.[Condition] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskName] + N'%')
												OR (R.[Condition] = 'start'    AND S.[TaskName] LIKE R.[TaskName] + N'%')
												OR (R.[Condition] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskName])
											)
										AND (
												R.[ConditionNo] = 'none'
												OR R.[TaskNameNo] = N''
												OR NOT
												(
													   (R.[ConditionNo] = 'equal'    AND S.[TaskName] = R.[TaskNameNo])
													OR (R.[ConditionNo] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'start'    AND S.[TaskName] LIKE R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] )
												)
											)
								  )
								  THEN 1
								  ELSE 0
							  END
				,[SubApplication] = CASE
								  WHEN EXISTS
								  (
									  SELECT 1 FROM #TB_PAR_BILLINGPRICES AS R WITH(NOLOCK) WHERE R.[NameDecoration] = 'SubApplication'
										AND (R.[PONumberStartsWith] IS NULL OR S.[PONumber] LIKE R.[PONumberStartsWith] + N'%')
                                    AND (R.[SeasonIn]    IS NULL OR (N',' + R.[SeasonIn]    + N',') LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[SeasonNotIn] IS NULL OR (N',' + R.[SeasonNotIn] + N',') NOT LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[StyleDivisionIn] IS NULL OR (N',' + R.[StyleDivisionIn]    + N',') LIKE N'%,' + S.[StyleDivision] + N',%')
                                    AND (R.[StyleDivisionNotIn] IS NULL OR (N',' + R.[StyleDivisionNotIn] + N',') NOT LIKE N'%,' + S.[StyleDivision] + N',%')
										AND (
												R.[Condition] = 'none'
												OR R.[TaskName] = N''
												OR (R.[Condition] = 'equal'    AND S.[TaskName] = R.[TaskName])
												OR (R.[Condition] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskName] + N'%')
												OR (R.[Condition] = 'start'    AND S.[TaskName] LIKE R.[TaskName] + N'%')
												OR (R.[Condition] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskName])
											)
										AND (
												R.[ConditionNo] = 'none'
												OR R.[TaskNameNo] = N''
												OR NOT
												(
													   (R.[ConditionNo] = 'equal'    AND S.[TaskName] = R.[TaskNameNo])
													OR (R.[ConditionNo] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'start'    AND S.[TaskName] LIKE R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] )
												)
											)
								  )
								  THEN 1
								  ELSE 0
							  END
				,[HDP] = CASE
								  WHEN EXISTS
								  (
									  SELECT 1 FROM #TB_PAR_BILLINGPRICES AS R WITH(NOLOCK) WHERE R.[NameDecoration] = 'HDP'
										AND (R.[PONumberStartsWith] IS NULL OR S.[PONumber] LIKE R.[PONumberStartsWith] + N'%')
                                    AND (R.[SeasonIn]    IS NULL OR (N',' + R.[SeasonIn]    + N',') LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[SeasonNotIn] IS NULL OR (N',' + R.[SeasonNotIn] + N',') NOT LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[StyleDivisionIn] IS NULL OR (N',' + R.[StyleDivisionIn]    + N',') LIKE N'%,' + S.[StyleDivision] + N',%')
                                    AND (R.[StyleDivisionNotIn] IS NULL OR (N',' + R.[StyleDivisionNotIn] + N',') NOT LIKE N'%,' + S.[StyleDivision] + N',%')
										AND (
												R.[Condition] = 'none'
												OR R.[TaskName] = N''
												OR (R.[Condition] = 'equal'    AND S.[TaskName] = R.[TaskName])
												OR (R.[Condition] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskName] + N'%')
												OR (R.[Condition] = 'start'    AND S.[TaskName] LIKE R.[TaskName] + N'%')
												OR (R.[Condition] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskName])
											)
										AND (
												R.[ConditionNo] = 'none'
												OR R.[TaskNameNo] = N''
												OR NOT
												(
													   (R.[ConditionNo] = 'equal'    AND S.[TaskName] = R.[TaskNameNo])
													OR (R.[ConditionNo] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'start'    AND S.[TaskName] LIKE R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] )
												)
											)
								  )
								  THEN 1
								  ELSE 0
							  END
				,[SpecialPK] = CASE
								  WHEN EXISTS
								  (
									  SELECT 1 FROM #TB_PAR_BILLINGPRICES AS R WITH(NOLOCK) WHERE R.[NameDecoration] = 'SpecialPK'
										AND (R.[PONumberStartsWith] IS NULL OR S.[PONumber] LIKE R.[PONumberStartsWith] + N'%')
                                    AND (R.[SeasonIn]    IS NULL OR (N',' + R.[SeasonIn]    + N',') LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[SeasonNotIn] IS NULL OR (N',' + R.[SeasonNotIn] + N',') NOT LIKE N'%,' + S.[Season] + N',%')
                                    AND (R.[StyleDivisionIn] IS NULL OR (N',' + R.[StyleDivisionIn]    + N',') LIKE N'%,' + S.[StyleDivision] + N',%')
                                    AND (R.[StyleDivisionNotIn] IS NULL OR (N',' + R.[StyleDivisionNotIn] + N',') NOT LIKE N'%,' + S.[StyleDivision] + N',%')
										AND (
												R.[Condition] = 'none'
												OR R.[TaskName] = N''
												OR (R.[Condition] = 'equal'    AND S.[TaskName] = R.[TaskName])
												OR (R.[Condition] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskName] + N'%')
												OR (R.[Condition] = 'start'    AND S.[TaskName] LIKE R.[TaskName] + N'%')
												OR (R.[Condition] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskName])
											)
										AND (
												R.[ConditionNo] = 'none'
												OR R.[TaskNameNo] = N''
												OR NOT
												(
													   (R.[ConditionNo] = 'equal'    AND S.[TaskName] = R.[TaskNameNo])
													OR (R.[ConditionNo] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'start'    AND S.[TaskName] LIKE R.[TaskNameNo] + N'%')
													OR (R.[ConditionNo] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] )
												)
											)
								  )
								  THEN 1
								  ELSE 0
							  END
				-- ,[SNApplication] = CASE
				-- 				  WHEN EXISTS
				-- 				  (
				-- 					  SELECT 1 FROM #TB_PAR_BILLINGPRICES AS R WITH(NOLOCK) WHERE R.[NameDecoration] = 'SNApplication'
				-- 						AND (R.[PONumberStartsWith] IS NULL OR S.[PONumber] LIKE R.[PONumberStartsWith] + N'%')
                --                     AND (R.[SeasonIn]    IS NULL OR (N',' + R.[SeasonIn]    + N',') LIKE N'%,' + S.[Season] + N',%')
                --                     AND (R.[SeasonNotIn] IS NULL OR (N',' + R.[SeasonNotIn] + N',') NOT LIKE N'%,' + S.[Season] + N',%')
                --                     AND (R.[StyleDivisionIn] IS NULL OR (N',' + R.[StyleDivisionIn]    + N',') LIKE N'%,' + S.[StyleDivision] + N',%')
                --                     AND (R.[StyleDivisionNotIn] IS NULL OR (N',' + R.[StyleDivisionNotIn] + N',') NOT LIKE N'%,' + S.[StyleDivision] + N',%')
				-- 						AND (
				-- 								R.[Condition] = 'none'
				-- 								OR R.[TaskName] = N''
				-- 								OR (R.[Condition] = 'equal'    AND S.[TaskName] = R.[TaskName])
				-- 								OR (R.[Condition] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskName] + N'%')
				-- 								OR (R.[Condition] = 'start'    AND S.[TaskName] LIKE R.[TaskName] + N'%')
				-- 								OR (R.[Condition] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskName])
				-- 							)
				-- 						AND (
				-- 								R.[ConditionNo] = 'none'
				-- 								OR R.[TaskNameNo] = N''
				-- 								OR NOT
				-- 								(
				-- 									   (R.[ConditionNo] = 'equal'    AND S.[TaskName] = R.[TaskNameNo])
				-- 									OR (R.[ConditionNo] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] + N'%')
				-- 									OR (R.[ConditionNo] = 'start'    AND S.[TaskName] LIKE R.[TaskNameNo] + N'%')
				-- 									OR (R.[ConditionNo] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] )
				-- 								)
				-- 							)
				-- 				  )
				-- 				  THEN 1
				-- 				  ELSE 0
				-- 			  END
				,[Samples] = IIF(S.[Season] NOT IN ('EMB FG', 'BLANK FG') AND (S.[Waybill] LIKE '%SMS%' OR S.[Waybill] LIKE 'SM%'),1,0)
							-- 	CASE
							-- 	  WHEN EXISTS
							-- 	  (
							-- 		  SELECT 1 FROM #TB_PAR_BILLINGPRICES AS R WITH(NOLOCK) WHERE R.[NameDecoration] = 'Samples'
							-- 			AND (R.[PONumberStartsWith] IS NULL OR S.[PONumber] LIKE R.[PONumberStartsWith] + N'%')
                            --         AND (R.[SeasonIn]    IS NULL OR (N',' + R.[SeasonIn]    + N',') LIKE N'%,' + S.[Season] + N',%')
                            --         AND (R.[SeasonNotIn] IS NULL OR (N',' + R.[SeasonNotIn] + N',') NOT LIKE N'%,' + S.[Season] + N',%')
                            --         AND (R.[StyleDivisionIn] IS NULL OR (N',' + R.[StyleDivisionIn]    + N',') LIKE N'%,' + S.[StyleDivision] + N',%')
                            --         AND (R.[StyleDivisionNotIn] IS NULL OR (N',' + R.[StyleDivisionNotIn] + N',') NOT LIKE N'%,' + S.[StyleDivision] + N',%')
							-- 			AND (
							-- 					R.[Condition] = 'none'
							-- 					OR R.[TaskName] = N''
							-- 					OR (R.[Condition] = 'equal'    AND S.[TaskName] = R.[TaskName])
							-- 					OR (R.[Condition] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskName] + N'%')
							-- 					OR (R.[Condition] = 'start'    AND S.[TaskName] LIKE R.[TaskName] + N'%')
							-- 					OR (R.[Condition] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskName])
							-- 				)
							-- 			AND (
							-- 					R.[ConditionNo] = 'none'
							-- 					OR R.[TaskNameNo] = N''
							-- 					OR NOT
							-- 					(
							-- 						   (R.[ConditionNo] = 'equal'    AND S.[TaskName] = R.[TaskNameNo])
							-- 						OR (R.[ConditionNo] = 'contains' AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] + N'%')
							-- 						OR (R.[ConditionNo] = 'start'    AND S.[TaskName] LIKE R.[TaskNameNo] + N'%')
							-- 						OR (R.[ConditionNo] = 'finish'   AND S.[TaskName] LIKE N'%' + R.[TaskNameNo] )
							-- 					)
							-- 				)
							-- 	  )
							-- 	  THEN 1
							-- 	  ELSE 0
							--   END
							  

				,[PigmentDye]               =   IIF(S.[PigmentDyeTransaction]>=1,1,0)
				,[BlankLCA]                 =   IIF(S.[Season] NOT IN ('EMB FG', 'BLANK FG'),1,0)
				,[BlankSemiApp]             =   IIF(S.[StyleDivision] = 'Apparel' AND S.[Season] IN ('EMB FG', 'BLANK FG'),1,0)
				,[BlankSemiHW]              =   IIF(S.[StyleDivision] = 'Headwear' AND S.[Season] IN ('EMB FG', 'BLANK FG'),1,0)
				
			FROM #TB_DATA_ACTIVE_MOS_WORKTASK AS S
			
			
			
			   
		
			UPDATE S SET 
				 [ScreenPrint]      = B.[ScreenPrint]   
				,[Sublimation]      = B.[Sublimation]   
				,[EmbroideryAPP]    = B.[EmbroideryAPP] 
				,[EmbroideryHW]     = B.[EmbroideryHW]  
				,[Relabel]          = B.[Relabel]       
				,[SubApplication]   = B.[SubApplication]
				,[HDP]              = B.[HDP]
				,[SpecialPK]        = B.[SpecialPK]
				,[PigmentDye]       = B.[PigmentDye]
				,[Samples]          = B.[Samples]
				-- ,[SNApplication]    = B.[SNApplication]
				,[BlankLCA]         = B.[BlankLCA]
				,[BlankSemiApp]     = B.[BlankSemiApp]
				,[BlankSemiHW]      = B.[BlankSemiHW]
			FROM #TB_DATA_ACTIVE_MOS AS S
			LEFT JOIN (
				SELECT 
					 [ManufactureID]
					,[Waybill]
					,[ScreenPrint]      =   SUM([ScreenPrint])
					,[Sublimation]      =   SUM([Sublimation])
					,[EmbroideryAPP]    =   SUM([EmbroideryAPP])
					,[EmbroideryHW]     =   SUM([EmbroideryHW])
					,[Relabel]          =   SUM([Relabel])
					,[SubApplication]   =   SUM([SubApplication])
					,[HDP]              =   SUM([HDP])
					,[SpecialPK]        =   SUM([SpecialPK])
					,[PigmentDye]       =   SUM([PigmentDye])
					,[Samples]          =   SUM([Samples])
					-- ,[SNApplication]    =   SUM([SNApplication])
					,[BlankLCA]         =   SUM([BlankLCA])
					,[BlankSemiApp]     =   SUM([BlankSemiApp])
					,[BlankSemiHW]      =   SUM([BlankSemiHW])
				FROM #TB_DATA_ACTIVE_MOS_WORKTASK AS C 
				GROUP BY
					[ManufactureID]
					,[Waybill]
			) AS B ON B.ManufactureID = S.ManufactureID AND B.[Waybill] = S.[Waybill]
		
		
				
		    
		    
		    
			UPDATE MO SET
						 [ScreenPrint]      =   COALESCE(MO.[ScreenPrint]        ,0) + COALESCE(EORO.[ScreenPrint]     ,0)
						,[Sublimation]      =   COALESCE(MO.[Sublimation]        ,0) + COALESCE(EORO.[Sublimation]     ,0)
						,[EmbroideryAPP]    =   COALESCE(MO.[EmbroideryAPP]      ,0) + COALESCE(EORO.[EmbroideryAPP]   ,0)
						,[EmbroideryHW]     =   COALESCE(MO.[EmbroideryHW]       ,0) + COALESCE(EORO.[EmbroideryHW]    ,0)
						,[Relabel]          =   COALESCE(MO.[Relabel]            ,0) + COALESCE(EORO.[Relabel]         ,0)
						,[SubApplication]   =   COALESCE(MO.[SubApplication]     ,0) + COALESCE(EORO.[SubApplication]  ,0)
						,[HDP]              =   COALESCE(MO.[HDP]                ,0) + COALESCE(EORO.[HDP]             ,0)
						,[SpecialPK]        =   COALESCE(MO.[SpecialPK]          ,0) + COALESCE(EORO.[SpecialPK]       ,0)
						,[PigmentDye]       =   COALESCE(MO.[PigmentDye]         ,0) + COALESCE(EORO.[PigmentDye]      ,0)
						,[Samples]          =   COALESCE(MO.[Samples]            ,0) + COALESCE(EORO.[Samples]         ,0)
						-- ,[SNApplication]    =   COALESCE(MO.[SNApplication]      ,0) + COALESCE(EORO.[SNApplication]   ,0)
						,[BlankLCA]         =   COALESCE(MO.[BlankLCA]           ,0) + COALESCE(EORO.[BlankLCA]        ,0)
						,[BlankSemiApp]     =   COALESCE(MO.[BlankSemiApp]       ,0) + COALESCE(EORO.[BlankSemiApp]    ,0)
						,[BlankSemiHW]      =   COALESCE(MO.[BlankSemiHW]        ,0) + COALESCE(EORO.[BlankSemiHW]     ,0)
					FROM #TB_DATA_ACTIVE_MOS AS MO
					INNER JOIN (
						SELECT
							[EO_ID]            = EORO.EO_ID
							,[ScreenPrint]     = IIF(SUM(COALESCE([ScreenPrint]       ,0))>0,1,0)
							,[Sublimation]     = IIF(SUM(COALESCE([Sublimation]       ,0))>0,1,0)
							,[EmbroideryAPP]   = IIF(SUM(COALESCE([EmbroideryAPP]     ,0))>0,1,0)
							,[EmbroideryHW]    = IIF(SUM(COALESCE([EmbroideryHW]      ,0))>0,1,0)
							,[Relabel]         = IIF(SUM(COALESCE([Relabel]           ,0))>0,1,0)
							,[SubApplication]  = IIF(SUM(COALESCE([SubApplication]    ,0))>0,1,0)
							,[HDP]             = IIF(SUM(COALESCE([HDP]               ,0))>0,1,0)
							,[SpecialPK]       = IIF(SUM(COALESCE([SpecialPK]         ,0))>0,1,0)
							,[PigmentDye]      = IIF(SUM(COALESCE([PigmentDye]        ,0))>0,1,0)
							,[Samples]         = IIF(SUM(COALESCE([Samples]           ,0))>0,1,0)
							-- ,[SNApplication]   = IIF(SUM(COALESCE([SNApplication]     ,0))>0,1,0)
							,[BlankLCA]        = IIF(SUM(COALESCE([BlankLCA]          ,0))>0,1,0)
							,[BlankSemiApp]    = IIF(SUM(COALESCE([BlankSemiApp]      ,0))>0,1,0)
							,[BlankSemiHW]     = IIF(SUM(COALESCE([BlankSemiHW]       ,0))>0,1,0)
						FROM        #TB_WF_EORO     AS EORO
						LEFT JOIN   #TB_DATA_ACTIVE_MOS  AS RO   ON RO.ManufactureID = EORO.RO_ID		---TENGO QUE VER EL WORKFLOW DEBIDO A QUE YA ES UN DATO QUE SE COMPLETARON LAS BLANK RO - BLANK FG
						GROUP BY EORO.EO_ID
					) AS EORO ON EORO.EO_ID = MO.ManufactureID
				
		
		
			UPDATE S SET
				 [UnitPrice_ScreenPrint]    = IIF(B.[NameDecoration] = 'ScreenPrint'      , ISNULL(B.[PerTechnique],0.00),0.00  )
				,[UnitPrice_Sublimation]    = IIF(B.[NameDecoration] = 'Sublimation'      , ISNULL(B.[PerTechnique],0.00),0.00  )
				,[UnitPrice_EmbroideryApp]  = IIF(B.[NameDecoration] = 'EmbroideryApp'    , ISNULL(B.[PerTechnique],0.00),0.00  )
				,[UnitPrice_EmbroideryHW]   = IIF(B.[NameDecoration] = 'EmbroideryHW'     , ISNULL(B.[PerTechnique],0.00),0.00  )
				,[UnitPrice_Relabel]        = IIF(B.[NameDecoration] = 'Relabel'          , ISNULL(B.[PerTechnique],0.00),0.00  )
				,[UnitPrice_SubApplication] = IIF(B.[NameDecoration] = 'SubApplication'   , ISNULL(B.[PerTechnique],0.00),0.00  )
				,[UnitPrice_HDP]            = IIF(B.[NameDecoration] = 'HDP'              , ISNULL(B.[PerTechnique],0.00),0.00  )
				,[UnitPrice_SpecialPK]      = IIF(B.[NameDecoration] = 'SpecialPK'        , ISNULL(B.[PerTechnique],0.00),0.00  )
				,[UnitPrice_PigmentDye]     = IIF(B.[NameDecoration] = 'PigmentDye'       , ISNULL(B.[PerTechnique],0.00),0.00  )
				,[UnitPrice_Samples]        = IIF(B.[NameDecoration] = 'Samples'          , ISNULL(B.[PerTechnique],0.00),0.00  )
				-- ,[UnitPrice_SNApplication]  = IIF(B.[NameDecoration] = 'SNApplication'    , ISNULL(B.[PerTechnique],0.00),0.00  )
				,[UnitPrice_BlankLCA]       = IIF(B.[NameDecoration] = 'BlankLCA'         , ISNULL(B.[PerTechnique],0.00),0.00  )
				,[UnitPrice_BlankSemiApp]   = IIF(B.[NameDecoration] = 'BlankSemiApp'     , ISNULL(B.[PerTechnique],0.00),0.00  )
				,[UnitPrice_BlankSemiHW]    = IIF(B.[NameDecoration] = 'BlankSemiHW'      , ISNULL(B.[PerTechnique],0.00),0.00  )
			FROM #TB_DATA_ACTIVE_MOS_WORKTASK AS S
			LEFT JOIN #TB_PAR_BILLINGPRICES AS B ON B.[TaskName] = S.[TaskName] AND B.[PerTechnique] IS NOT NULL
			
			
			UPDATE S SET
				 [UnitPrice_ScreenPrint]     = B.[UnitPrice_ScreenPrint]   
				,[UnitPrice_Sublimation]     = B.[UnitPrice_Sublimation]   
				,[UnitPrice_EmbroideryApp]   = B.[UnitPrice_EmbroideryApp]    
				,[UnitPrice_EmbroideryHW]    = B.[UnitPrice_EmbroideryHW]    
				,[UnitPrice_Relabel]         = B.[UnitPrice_Relabel]       
				,[UnitPrice_SubApplication]  = B.[UnitPrice_SubApplication]
				,[UnitPrice_HDP]             = B.[UnitPrice_HDP]           
				,[UnitPrice_SpecialPK]       = B.[UnitPrice_SpecialPK]     
				,[UnitPrice_PigmentDye]      = B.[UnitPrice_PigmentDye]     
				,[UnitPrice_Samples]         = B.[UnitPrice_Samples]     
				-- ,[UnitPrice_SNApplication]   = B.[UnitPrice_SNApplication]     
				,[UnitPrice_BlankLCA]        = B.[UnitPrice_BlankLCA]     
				,[UnitPrice_BlankSemiApp]    = B.[UnitPrice_BlankSemiApp]     
				,[UnitPrice_BlankSemiHW]     = B.[UnitPrice_BlankSemiHW]     
			FROM #TB_DATA_ACTIVE_MOS AS S
			LEFT JOIN ( SELECT
							 [ManufactureID]
							,[Waybill]
							,[UnitPrice_ScreenPrint]    = SUM([UnitPrice_ScreenPrint]   )
							,[UnitPrice_Sublimation]    = SUM([UnitPrice_Sublimation]   )
							,[UnitPrice_EmbroideryApp]  = SUM([UnitPrice_EmbroideryApp] )
							,[UnitPrice_EmbroideryHW]   = SUM([UnitPrice_EmbroideryHW]  )
							,[UnitPrice_Relabel]        = SUM([UnitPrice_Relabel]       )
							,[UnitPrice_SubApplication] = SUM([UnitPrice_SubApplication])
							,[UnitPrice_HDP]            = SUM([UnitPrice_HDP]           )
							,[UnitPrice_SpecialPK]      = SUM([UnitPrice_SpecialPK]     )
							,[UnitPrice_PigmentDye]     = SUM([UnitPrice_PigmentDye]    )
							,[UnitPrice_Samples]        = SUM([UnitPrice_Samples]       )
							-- ,[UnitPrice_SNApplication]  = SUM([UnitPrice_SNApplication] )
							,[UnitPrice_BlankLCA]       = SUM([UnitPrice_BlankLCA]      )
							,[UnitPrice_BlankSemiApp]   = SUM([UnitPrice_BlankSemiApp]  )
							,[UnitPrice_BlankSemiHW]    = SUM([UnitPrice_BlankSemiHW]   )
						FROM #TB_DATA_ACTIVE_MOS_WORKTASK AS C
						GROUP BY [ManufactureID] ,[Waybill]
			) AS B ON S.ManufactureID = B.ManufactureID AND B.[Waybill] = S.[Waybill]
			
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-------TABLA FINAL DE MOS PARA ACTUALIZAR----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			SELECT	
				[RowData]   = ROW_NUMBER() OVER (ORDER BY 
													 B.[rowN]
													,M.[Waybill]
													,M.[Style]
													,M.[Color]
													,M.[PONumber]
													,M.[MO]
												)
				,M.*
			INTO #FINALTABLE
			FROM #TB_DATA_ACTIVE_MOS AS M
			LEFT JOIN #TB_ParametersJOIN AS B ON B.Waybill = M.Waybill
			
			WHERE M.[FilterMOExport] = 1	---SOLO MOS DE EXPORTACION, NO INCLUIR ROS YA QUE NO VAMOS ACTUALIZAR ESTA INFORMACION.
			
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-----ADD PONumber Export--------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		ALTER TABLE #FINALTABLE ADD OrderIDExport       INT          NULL;
		ALTER TABLE #FINALTABLE ADD PONumberExport      VARCHAR(200) NULL;
		ALTER TABLE #FINALTABLE ADD PuertoDestino       VARCHAR(50) NULL;
		ALTER TABLE #FINALTABLE ADD ShipTo              VARCHAR(50) NULL;
		ALTER TABLE #FINALTABLE ADD TypeDestination     VARCHAR(50) NULL;
	
	   	DROP TABLE IF EXISTS #TB_PONumberExport_MO
		SELECT DISTINCT
             [ManufactureID]    = MO.ManufactureID
			,[MO]               = MO.ManufactureNumber
			,[OrderIDExport]    = O.OrderID
			,[PONumberExport]   = O.PONumber
            ,[Waybill]          = FSH.Waybill    
            ,[PuertoDestino] 	= ddv2.dropDownValue
            ,[TypeDestination] 	= ddv2.Description2
        INTO #TB_PONumberExport_MO
        FROM (SELECT StatusID,StatusName FROM [LCA].[dbo].StatusNames WITH(NOLOCK) WHERE [StatusID] <=90) AS SNMO ---MOs Activas y complete
        INNER JOIN  [LCA].[dbo].ManufactureOrders   AS MO	WITH(NOLOCK) ON MO.StatusID               = SNMO.StatusID     AND MO.StatusID <= 90
        INNER JOIN  [LCA].[dbo].PackedItems         AS PI	WITH(NOLOCK) ON PI.ManufactureID          = MO.ManufactureID  AND PI.Quantity > 0
        INNER JOIN  [LCA].[dbo].PackedBoxes         AS PB	WITH(NOLOCK) ON PB.PackedBoxID            = PI.PackedBoxID    AND PB.StatusID IN (25,27,75) ---MOS Que esten en estatus Packed o Picked
        INNER JOIN  [LCA].[dbo].Shipments           AS SH	WITH(NOLOCK) ON SH.ShipmentID             = PB.ShipmentID
		INNER JOIN	#TB_ParametersJOIN				AS FSH				 ON FSH.Waybill				  = SH.WayBill
        INNER JOIN  [LCA].[dbo].OrderDetails        AS ODD  WITH(NOLOCK) ON ODD.OrderDetailsID        = PI.OrderDetailsID
        INNER JOIN  [LCA].[dbo].Orders              AS O	WITH(NOLOCK) ON O.OrderID                = ODD.OrderID   
        LEFT JOIN   [LCA].[dbo].[DropDownValues2]   AS DDV2 WITH(NOLOCK) ON DDV2.DropDownValueID      = O.OrderTypeID3   
		        
		        -- select * from  [LCA].[dbo].[DropDownValues2]
		        -- where dropdownvalue = 'HANOVER'
		        
		UPDATE S SET
			 [OrderIDExport]    = B.[OrderIDExport]  
			,[PONumberExport]   = B.[PONumberExport] 
			,[PuertoDestino]    = B.[PuertoDestino]
			,[TypeDestination]  = B.[TypeDestination]
		FROM #FINALTABLE AS S
		INNER JOIN #TB_PONumberExport_MO AS B ON B.Waybill = S.Waybill AND S.ManufactureID = B.ManufactureID 
		
		-- drop table #FINALTABLE
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-----MANUAL PRICE OVERRIDE: TB_Parameters_ManualPrice--------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		ALTER TABLE #FINALTABLE ADD IsManualPrice       BIT           NOT NULL DEFAULT 0;
		ALTER TABLE #FINALTABLE ADD ManualBlankPrice    DECIMAL(18,2) NULL;
		ALTER TABLE #FINALTABLE ADD ManualDecoPrice     DECIMAL(18,2) NULL;
		ALTER TABLE #FINALTABLE ADD ManualCommentPrice  VARCHAR(200) NULL;

		UPDATE F SET
			 F.IsManualPrice        = 1
			,F.ManualBlankPrice     = MP.BlankPrice
			,F.ManualDecoPrice      = MP.DecorationPrice
			,F.ManualCommentPrice   = MP.Comment
		FROM #FINALTABLE AS F
		INNER JOIN AppsLCA.dbo.TB_Parameters_ManualPrice AS MP WITH(NOLOCK) ON F.PONumber = MP.PONumber

		UPDATE F SET
			 F.IsManualPrice        = 1
			,F.ManualBlankPrice     = MP.BlankPrice
			,F.ManualDecoPrice      = MP.DecorationPrice
			,F.ManualCommentPrice   = MP.Comment
		FROM #FINALTABLE AS F
		INNER JOIN AppsLCA.dbo.TB_Parameters_ManualPrice AS MP WITH(NOLOCK) ON F.PONumberExport = MP.PONumber

		UPDATE F SET
			 F.IsManualPrice        = 1
			,F.ManualBlankPrice     = MP.BlankPrice
			,F.ManualDecoPrice      = MP.DecorationPrice
			,F.ManualCommentPrice   = MP.Comment
		FROM #FINALTABLE AS F
		INNER JOIN AppsLCA.dbo.TB_Parameters_ManualPrice_MO AS MP WITH(NOLOCK) ON F.ManufactureID = MP.ManufactureID AND F.Waybill = MP.Waybill
		
		-- select * from #FINALTABLE
		-- return
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

			UPDATE S SET
				[PigmentDyeBasePrice]  = IIF(S.[PigmentDye] = 1,PD.[Price],0.00)
			FROM #FINALTABLE    AS S
			LEFT JOIN #TB_Parameters_PigmentDye AS PD ON PD.[Style] = S.[Style] AND PD.[Color] = S.[Color]
	
	
		
		  
		
		DROP TABLE IF EXISTS #GROUP_ITEMDETAILID
		SELECT DISTINCT ItemDetailID INTO #GROUP_ITEMDETAILID FROM #FINALTABLE 
		
		
		 DROP TABLE IF EXISTS #TB_BACKLOG_LOOKUP_STATUSDATE
		 DROP TABLE IF EXISTS #TB_ORDER_EXPORT_LOGS_SHIPTO
         SELECT
              [ItemDetailID]     = SRC.[ItemDetailID]
             ,[ShipTo]           = CASE
												WHEN SRC.ItemDetailID IN (
																 5777500    ---20260702 CORREO Larissa Stiles
																,5777497    ---20260702 CORREO Larissa Stiles
																,5790228    ---20260702 CORREO Larissa Stiles
																,5777493    ---20260702 CORREO Larissa Stiles
																,5793888    ---20260702 CORREO Larissa Stiles
																,5793890    ---20260702 CORREO Larissa Stiles
																,5777523    ---20260702 CORREO Larissa Stiles
																,5777522    ---20260702 CORREO Larissa Stiles
																,5777499	---20260702 CORREO Larissa Stiles
																,5777513	---20260702 CORREO Larissa Stiles
																,5777526	---20260702 CORREO Larissa Stiles
																,6019264	---20260702 CORREO Larissa Stiles
																,6019267	---20260702 CORREO Larissa Stiles
																,5790246	---20260702 CORREO Ordenes de DICKS
																,5816550	---20260702 CORREO Ordenes de DICKS
																,6034515	---20260702 CORREO Ordenes de DICKS
																,5793889	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008398	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008397	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008396	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008394	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008392	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008391	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008389	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008393	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008395	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6008399	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5775385	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5777531	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5777534	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5790232	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6046147	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6046155	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6046156	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6046157	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6046158	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6046159	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6046160	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6046161	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5775377	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5775387	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5775389	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5775393	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5775397	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5777492	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5777514	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5777521	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5777527	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5793894	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6034514	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6034516	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,6034520	--- 20260711 Ordenes de Dicks autorizado por RA y BH
																,5972087	--- 20260729 Ordenes de Dicks 
																,5972088	--- 20260729 Ordenes de Dicks 
																,5972095	--- 20260729 Ordenes de Dicks 
																,5972096	--- 20260729 Ordenes de Dicks 
																,5972086	--- 20260729 Ordenes de Dicks 
																,5972097	--- 20260729 Ordenes de Dicks 
																,5993561	--- 20260729 Ordenes de Dicks 
																,5993562	--- 20260729 Ordenes de Dicks 
																,5993564	--- 20260729 Ordenes de Dicks 
																,5993570	--- 20260729 Ordenes de Dicks 
																,6004416	--- 20260729 Ordenes de Dicks 
																,6004418	--- 20260729 Ordenes de Dicks 
																,6010679	--- 20260729 Ordenes de Dicks 
																,6010681	--- 20260729 Ordenes de Dicks 
																,6094443	--- 20260729 Ordenes de Dicks 
																,6010680	--- 20260729 Ordenes de Dicks 
																,5971940	--- 20260729 Ordenes de Dicks 
																,5993559	--- 20260729 Ordenes de Dicks 
																,5971942	--- 20260730 Ordenes de Dicks
																,5972091	--- 20260730 Ordenes de Dicks
																,6069800	--- 20260730 Ordenes de Dicks
																,6069799	--- 20260731 Ordenes de Dicks
																,6010679	--- 20260731 Ordenes de Dicks
																,6010681	--- 20260731 Ordenes de Dicks
																,5920877	--- 20260810 Ordenes de Dicks
																,5920878	--- 20260731 Ordenes de Dicks
																,5920986	--- 20260731 Ordenes de Dicks
																,5921129	--- 20260731 Ordenes de Dicks
																,5921130	--- 20260731 Ordenes de Dicks
																,5921131	--- 20260731 Ordenes de Dicks
																,6037535	--- 20260813 Waybill APP-20260813 
																,5814934	--- 20260813 Waybill APP-20260813
																,5920982	--- 20260813 Waybill APP-20260813
																,5920983	--- 20260813 Waybill APP-20260813
																,5920984	--- 20260813 Waybill APP-20260813
																,5920994	--- 20260813 Waybill APP-20260813
																,5920995	--- 20260813 Waybill APP-20260813
																,5920996	--- 20260813 Waybill APP-20260813
																,5921135	--- 20260813 Waybill APP-20260813
																,5921136	--- 20260813 Waybill APP-20260813
																,5921137	--- 20260813 Waybill APP-20260813
																,5921147	--- 20260813 Waybill APP-20260813
																,5921149	--- 20260813 Waybill APP-20260813
																,5921150	--- 20260813 Waybill APP-20260813
																,5921151	--- 20260813 Waybill APP-20260813
																,6021988	--- 20260813 Waybill APP-20260813
																,6022007	--- 20260813 Waybill APP-20260813
																,6022008	--- 20260813 Waybill APP-20260813
																,6069791	--- 20260813 Waybill APP-20260813
																,6010676	--- 20260813 Waybill AIR-APP-20260813
																,6010677	--- 20260813 Waybill AIR-APP-20260813
																,6010678	--- 20260813 Waybill AIR-APP-20260813
																,6061787	--- 20260813 Waybill AIR-APP-20260813
																,6061784	--- 20260813 Waybill AIR-APP-20260813
																,6021989	--- 20260813 Waybill AIR-APP-20260813
																,6061791	--- 20260813 Waybill AIR-APP-20260813
																,6061795	--- 20260813 Waybill AIR-APP-20260813
																,6045738	--- 20260813 Waybill AIR-APP-20260813
																,6045739	--- 20260813 Waybill AIR-APP-20260813
																,6052444
																,6052446
																,5920873
																,5920874
																,6069794
																,5920879
																,5920880
																,6021974
																,6152196
																,6021980
																,6016258
																,6059756
																,5510446
																,6131467
																,5865732
																,6021981
																,6061734
																,5920989
																,5920992
																,5921133
																,5930237
																,5801576
																,5921155
																,6059586
																,6152177
																,6152206
																,5920979
																,5920980
																,5920981
																,5920999
																,5921001
																,5921002
																,5921004
																		)
													THEN 'Hanover'
													ELSE SRC.[ShipTo] END
         INTO #TB_ORDER_EXPORT_LOGS_SHIPTO
         FROM (
             SELECT
                  LOGS.[ItemDetailID]
                 ,[ShipTo]               = LOGS.[Ship To]
                 ,[RN]                   = ROW_NUMBER() OVER (
                                                 PARTITION BY LOGS.[ItemDetailID]
                                                 ORDER BY LOGS.[Insert_Time] DESC
                                             )   
             -- FROM [192.168.1.93].[AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export_Logs] AS LOGS WITH(NOLOCK)
             FROM #GROUP_ITEMDETAILID AS GROUPS
             INNER JOIN [192.168.1.93].[AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export_Logs] AS LOGS WITH(NOLOCK)
                 ON LOGS.[ItemDetailID] = GROUPS.[ItemDetailID]
         ) AS SRC
         WHERE SRC.[RN] = 1
        
        UPDATE S SET
			 S.[ShipTo]           = LOGS.[ShipTo]
        FROM #TB_ORDER_EXPORT_LOGS_SHIPTO AS LOGS
        INNER JOIN #FINALTABLE AS S ON S.ItemDetailID = LOGS.ItemDetailID
        
        UPDATE S SET
            [ShipTo] = IIF(S.[PONumber] LIKE 'PO%','Hanover',NULL)
        FROM #FINALTABLE AS S
        WHERE S.ShipTo IS NULL
        
		-- 	SELECT * FROM #FINALTABLE
        
                
		-- RETURN
		-----PUERTO DESTINO.. FALTA
		
		
		DROP TABLE IF EXISTS #TB_GROUP_WAYBILL
		SELECT DISTINCT 
			 [Waybill]
			,[AirFreight]       = CAST(NULL AS BIT)
			,[OceanFreight]     = CAST(NULL AS BIT)
		INTO #TB_GROUP_WAYBILL
		FROM #FINALTABLE AS S
		
		
		DROP TABLE IF EXISTS #TB_PAR_BILLINGCONTAINERS
		SELECT * INTO #TB_PAR_BILLINGCONTAINERS FROM [AppsLCA].[dbo].[TB_Parameters_BillingContainers] WITH(NOLOCK)
			
		UPDATE S SET
		 
			[OceanFreight] = CASE
							  WHEN EXISTS
							  (
								  SELECT 1 FROM #TB_PAR_BILLINGCONTAINERS AS R WITH(NOLOCK) WHERE R.[TypeContainer] = 'Container'
									AND (
											R.[Condition] = 'none'
											OR R.[Waybill] = N''
											OR (R.[Condition] = 'equal'    AND S.[Waybill] = R.[Waybill])
											OR (R.[Condition] = 'contains' AND S.[Waybill] LIKE N'%' + R.[Waybill] + N'%')
											OR (R.[Condition] = 'start'    AND S.[Waybill] LIKE R.[Waybill] + N'%')
											OR (R.[Condition] = 'finish'   AND S.[Waybill] LIKE N'%' + R.[Waybill])
										)
							  )
							  THEN 1
							  ELSE 0
						  END
			,[AirFreight] = CASE
							  WHEN EXISTS
							  (
								  SELECT 1 FROM #TB_PAR_BILLINGCONTAINERS AS R WITH(NOLOCK) WHERE R.[TypeContainer] = 'AIR'
									AND (
											R.[Condition] = 'none'
											OR R.[Waybill] = N''
											OR (R.[Condition] = 'equal'    AND S.[Waybill] = R.[Waybill])
											OR (R.[Condition] = 'contains' AND S.[Waybill] LIKE N'%' + R.[Waybill] + N'%')
											OR (R.[Condition] = 'start'    AND S.[Waybill] LIKE R.[Waybill] + N'%')
											OR (R.[Condition] = 'finish'   AND S.[Waybill] LIKE N'%' + R.[Waybill])
										)
							  )
							  THEN 1
							  ELSE 0
						  END
			FROM #TB_GROUP_WAYBILL AS S
							  
		UPDATE S SET
			 [AirFreight]       = IIF(GWB.[AirFreight] = 1,1,0)
			,[OceanFreight]     = IIF(GWB.[OceanFreight] = 1,1,0)
			,[InlandFreight]    = IIF(S.[TypeDestination] LIKE '%Inland%',1,0)
		FROM #FINALTABLE    AS S
		LEFT JOIN #TB_GROUP_WAYBILL AS GWB ON S.Waybill = GWB.Waybill
			
		
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-------ACTUALIZACION DE INVOICE DESCRIPTION SEGUN VISTA--------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		    SELECT DISTINCT [Style] INTO #TB_Group_Style FROM #FINALTABLE 
		    
			SELECT DISTINCT
                 [Style]				= FC.[Style]
                ,[StyleColorName]		= FC.[StyleColorName]
                ,[StyleOptionID]		= FC.[StyleOptionID]
                ,[StyleOptionName]		= FC.[StyleOptionName]
                ,[DescribeText]			= FC.[DescribeText]
                ,[InvoicingDescription] = FC.[InvoicingDescription]
            INTO #TB_StyleInvoiceDescription
            FROM #TB_Group_Style AS GST
            INNER JOIN [LCA].[dboReaders].[VW_CommercialInvoice_FabricContent_Options] AS FC WITH (NOLOCK) ON GST.Style = FC.Style
            
            UPDATE S SET
                [InvoicingDescription] = FC.[InvoicingDescription]
            FROM #FINALTABLE AS S
            INNER JOIN #TB_StyleInvoiceDescription AS FC ON S.Style = FC.Style
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-------ACTUALIZACION DE INVOICE DESCRIPTION SEGUN VISTA--------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		        

		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-------ACTUALIZACION DE BASE PRICE-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			    SELECT 
			         [Style]            = pri.[Style]                 
			        ,[Color]            = pri.[Color]                 
			        ,[Season]           = pri.[Season]                
			        ,[Category]         = pri.[Category]              
			        ,[StyleOptionID]    = pri.[StyleOptionID]                 
			        ,[CostBlank]        = pri.[CostBlank]                 
			        ,[Embellishment]    = pri.[Embellishment]                 
			        ,[OtherEmbCost]     = pri.[OtherEmbCost]                  
			    INTO #TB_PRICES_NEW 
			    FROM #TB_Group_Style  AS GST 
			    INNER JOIN [AppsLCA].[dbo].[Prices_New] AS Pri WITH(NOLOCK) ON GST.Style = Pri.Style
			    
		
			-----OPCION PARA ACTUALIZAR POR: Style-Color-Option-Season
				UPDATE   TB
				SET 
					 [LCABasePrice]             = SPN.CostBlank
					,[SublimationBasePrice]     = IIF(TB.[Sublimation] >= 1,(SPN.Embellishment + SPN.OtherEmbCost),NULL)
				FROM #FINALTABLE				AS TB
				INNER JOIN #TB_PRICES_NEW AS SPN	WITH(NOLOCK) ON TB.Style = SPN.Style 
																						AND SPN.Color = TB.Color 
																						AND TB.StyleOptionID = SPN.StyleOptionID 
																						AND SPN.Season NOT IN ('EMB FG', 'BLANK FG')
			-- ======================== Si no encuentra la option en el catalogo de precios pone la que coincida estilo color ==============================
			-----OPCION PARA ACTUALIZAR POR: Style-Color-Season
				UPDATE   TB	SET 
					[LCABasePrice]              = IIF( TB.[BlankLCA] >= 1
					                                ,
    					                                CASE 
            												WHEN TB.[LCABasePrice] IS NULL 
            												THEN SPN.[CostBlank]
            												ELSE TB.[LCABasePrice]
        												END
        											, NULL
                                                    )
					,[SublimationBasePrice]    = IIF(TB.[Sublimation] >= 1,(SPN.[Embellishment] + SPN.[OtherEmbCost]),NULL)
				FROM #FINALTABLE				AS TB
				INNER JOIN #TB_PRICES_NEW AS SPN	WITH(NOLOCK) ON TB.Style = SPN.Style 
																						AND SPN.Color = TB.Color  
																						AND SPN.Season NOT IN ('EMB FG', 'BLANK FG')
				
			
		
			----======================== Actualiza Precios para FG ==============================
			-----OPCION PARA ACTUALIZAR POR: ManufactureID
				UPDATE TB	SET 
					--  [PurchaseBasePrice]	= ROUND(((ROUND(ISNULL(FM.[Contracts_PurchasePrice],0.00),2) + ROUND(ISNULL(FM.[Contracts_FreightPrice],0.00),2) )/ FM.[Make]),2)
					 [PurchaseBasePrice]	= ROUND(((ROUND(ISNULL(FM.[Contracts_PurchasePrice],0.00),2) )/ FM.[Make]),2)
					,[PurchaseFreightPrice]	= ROUND(((ROUND(ISNULL(FM.[Contracts_FreightPrice] ,0.00),2) )/ FM.[Make]),2)
				FROM #FINALTABLE				AS TB
				INNER JOIN [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Materials] 	AS FM	WITH(NOLOCK) ON FM.ManufactureID	= TB.ManufactureID
				WHERE (TB.[BlankSemiApp] >= 1 OR TB.[BlankSemiHW] >= 1)
			
			
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-------ACTUALIZACION DE BASE PRICE-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-------ACTUALIZACION DE TARIFF CATEGORY-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
                SELECT DISTINCT [ManufactureID] INTO #AllGroupMOExport FROM #FINALTABLE
                
                SELECT 
                    [ManufactureID]         = B.ManufactureID
                    ,[MO]                   = B.MO
                    ,[Manufacturer]         = B.Manufacturer
                    ,[Proportion]           = B.Proportion
                    ,[CountryOfOrigin]      = B.CountryOfOrigin
                    ,[TariffCategory]       = B.TariffCategory
                    ,[R]                    = ROW_NUMBER() OVER(PARTITION BY S.ManufactureID ORDER BY S.ManufactureID,Consumption DESC)
                INTO #TB_FAMO_SUMMARY
                FROM #AllGroupMOExport AS S
                INNER JOIN [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Summary] AS B WITH(NOLOCK) ON S.ManufactureID = B.ManufactureID
                
                UPDATE TB	SET 
					 [TariffCategory]	= FM.[TariffCategory]
				FROM #FINALTABLE				AS TB
				INNER JOIN #TB_FAMO_SUMMARY	AS FM	WITH(NOLOCK) ON FM.ManufactureID	= TB.ManufactureID AND FM.[R] = 1
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-------ACTUALIZACION DE TARIFF CATEGORY-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	




		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-----PRECIOS BORDADO------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
			
		
			SELECT DISTINCT ManufactureID 
			INTO #TB_Group_MO_Embroidery
			FROM #FINALTABLE
			WHERE (
					([EmbroideryAPP] >= 1)
					OR
					([EmbroideryHW] >= 1)
				)
		
		    SELECT
		         [ManufactureID]    = mo.ManufactureID
				,[MO]               = mo.ManufactureNumber
		        ,[Code]             = od.Comments26
				,[EmbroideryPrice]	= CAST(NULL AS FLOAT)
				,[ReviewComment]	= CAST(NULL AS VARCHAR(MAX))
		    INTO #TB_Data_MO_Bordado
		    FROM        (SELECT StatusID FROM [LCA].[dbo].StatusNames WITH(NOLOCK) WHERE StatusID <=90)         AS SNS
		    INNER JOIN  [LCA].[dbo].ManufactureOrders   AS MO   WITH(NOLOCK) ON SNS.StatusID            = MO.StatusID                       AND SNS.StatusID <= 90
		    INNER JOIN  #TB_Group_MO_Embroidery	        AS FMO               ON FMO.ManufactureID		= MO.ManufactureID
		    INNER JOIN  [LCA].[dbo].OrderItems          AS oi   WITH(NOLOCK) ON oi.OrderItemID          = mo.FirstOrderItemID
		    LEFT JOIN   [LCA].[dbo].Orders              AS od   WITH(NOLOCK) ON od.OrderID              = ISNULL(mo.OrderID,oi.OrderID )
		    
			
		    SELECT
		         [Code]             = [Code]
		        ,[stitches]         = CAST(COALESCE([stitches]         , 0) AS DECIMAL(18,4))
		        ,[pellums]          = CAST(COALESCE([pellums]          , 0) AS DECIMAL(18,4))
		        ,[Threads]          = CAST(COALESCE([Threads]          , 0) AS DECIMAL(18,4))
		        ,[Labor]            = CAST(COALESCE([Labor]            , 0) AS DECIMAL(18,4))
		        ,[Fabric]           = CAST(COALESCE([Fabric]           , 0) AS DECIMAL(18,4))
		        ,[ShippingHandling] = CAST(COALESCE([ShippingHandling] , 0) AS DECIMAL(18,4))
		    INTO #TB_Data_Sales_Embroidery
		    FROM OPENQUERY([MARIADB],'SELECT * FROM `wordpress`.`Sales_Embroidery`'
		    ) AS TBM
		                       
		    SELECT
		         [ManufactureID]        = t.[ManufactureID]
		        ,[MO]                   = t.[MO]
		        ,[Code]                 = t.[Code]
		        ,[value]                = split_values.[value]
		        ,[stitches]             = [stitches]          
		        ,[pellums]              = [pellums]           
		        ,[Threads]              = [Threads]           
		        ,[Fabric]               = [Fabric]            
		        ,[Labor]                = [Labor]             
		        ,[ShippingHandling]     = [ShippingHandling]  
				-- ,[TotalEmbroidery]		= ISNULL([stitches], 0)	+ ISNULL([pellums], 0)	+ ISNULL([Threads], 0)	+ ISNULL([Labor], 0)	+ ISNULL([Fabric], 0)	+ ISNULL([ShippingHandling], 0)     ---20250306 ANTES DE ESTA FECHA
				,[TotalEmbroidery]		= ISNULL([stitches], 0)	+ ISNULL([pellums], 0)	+ ISNULL([Threads], 0)	+ ISNULL([Labor], 0)	+ ISNULL([Fabric], 0)	                                       ---20250306 SE QUITA PORQUE EL SHIPPING LO HACE DIFERENTE
				,[Error]				= CAST(IIF(tb_Emb.[Code] IS NULL, 1,0) AS INT)
		    INTO #TB_Data_MO_BordadoTotal
			FROM #TB_Data_MO_Bordado AS t
		    CROSS APPLY STRING_SPLIT(t.[Code], ',') AS split_values
		    LEFT JOIN  #TB_Data_Sales_Embroidery AS tb_Emb on tb_Emb.[Code] = split_values.[value]

			
			
			SELECT 
				 [ManufactureID]
				,[TotalEmbroidery]	= CAST(SUM([TotalEmbroidery]) AS DECIMAL(18,4))
				,[Error]			= IIF(SUM([Error])>0, 'CODIGO DE BORDADO NO EXISTE EN CATALOGO','OK')
				,[FlagError]		= CAST(IIF(SUM([Error])>0, 1,0) AS BIT)
			INTO #Final_MO_Embroidery
			FROM #TB_Data_MO_BordadoTotal 
			GROUP BY [ManufactureID]
		
			UPDATE S SET 
				 [CodePrice_EmbroideryApp]  = IIF(S.[EmbroideryAPP] >= 1, CAST(FMEB.TotalEmbroidery AS DECIMAL(18,4)), NULL)
				,[Rev_EmbroideryApp]	    = IIF(S.[EmbroideryAPP] >= 1, IIF( FMEB.FlagError  IS NULL OR FMEB.FlagError = 1  , ISNULL(FMEB.Error , 'NO CODE EMB APP'), 'OK') ,NULL)
				,[CodePrice_EmbroideryHW]   = IIF(S.[EmbroideryHW] >= 1 , CAST(FMEB.TotalEmbroidery AS DECIMAL(18,4)),NULL)
				,[Rev_EmbroideryHW]	        = IIF(S.[EmbroideryHW] >= 1 , IIF( FMEB.FlagError  IS NULL OR FMEB.FlagError = 1  , ISNULL(FMEB.Error , 'NO CODE EMB HW'), 'OK') ,NULL)
				,[Rev_Final]		        = IIF( FMEB.FlagError  IS NULL OR FMEB.FlagError = 1  , 1 , S.[Rev_Final])
			FROM #FINALTABLE				AS S
			LEFT JOIN #Final_MO_Embroidery AS FMEB ON S.ManufactureID = FMEB.ManufactureID
			WHERE (
					(S.[EmbroideryAPP] >= 1)
					OR
					(S.[EmbroideryHW] >= 1)
				)
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-----PRECIOS BORDADO------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        -----VALIDACION DE TOKENS EN FORMULAS (ANTES DE ACTUALIZACION FORMULAS)
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

            -- 1) Columnas disponibles en #FINALTABLE
            SELECT
                [ColName] = c.[name]
            INTO #TB_FinalCols
            FROM tempdb.sys.columns c WITH(NOLOCK)
            WHERE c.[object_id] = OBJECT_ID(N'tempdb..#FINALTABLE')
            
            -- 2) Columnas permitidas en TB_Parameters_BillingDecoration_FreightCost (parámetros)
            SELECT
                [ColName] = c.[name]
            INTO #TB_AllowedFormulaCols
            FROM [AppsLCA].[sys].[columns] c WITH(NOLOCK)
            WHERE c.[object_id] = OBJECT_ID(N'[AppsLCA].[dbo].[TB_Parameters_BillingDecoration_FreightCost]')
              AND c.[name] NOT IN ('id','NameDecoration','formula','status','created_at','updated_at')
            
            -- 3) Extraer tokens de cada formula (lo que está entre [ ])
            --    Técnica: reemplaza [ y ] por separador | y luego STRING_SPLIT
            SELECT
                 [NameDecoration] = P.[NameDecoration]
                ,[Token]          = LTRIM(RTRIM(S.value))
            INTO #TB_FormulaTokens
            FROM [AppsLCA].[dbo].[TB_Parameters_BillingDecoration_FreightCost] P WITH(NOLOCK)
            CROSS APPLY STRING_SPLIT(REPLACE(REPLACE(P.[formula], '[', '|'), ']', '|'), '|') S
            WHERE P.[Status] = 1
              AND LTRIM(RTRIM(S.value)) <> ''
              -- solo tokens "tipo columna" (evita pedazos como "(", ")+", "'Headwear'" etc.)
              AND PATINDEX('%[^A-Za-z0-9_]%', LTRIM(RTRIM(S.value))) = 0
            
            -- 4) Detectar tokens faltantes (no existen ni en #FINALTABLE ni en params de BillingDecoration)
            SELECT
                 T.[NameDecoration]
                ,T.[Token]
            INTO #TB_MissingTokens
            FROM #TB_FormulaTokens T
            LEFT JOIN #TB_FinalCols             AS FC ON FC.[ColName] = T.[Token]
            LEFT JOIN #TB_AllowedFormulaCols    AS AC ON AC.[ColName] = T.[Token]
            WHERE FC.[ColName] IS NULL AND AC.[ColName] IS NULL
            
            -- 5) Agrupar mensaje por NameDecoration
            SELECT
                 [NameDecoration]
                ,[MissingList] = STRING_AGG('[' + [Token] + ']', ', ')
                ,[Msg] = 'Error in Formula: ' + STRING_AGG('[' + [Token] + ']', ', ')
            INTO #TB_MissingAgg
            FROM #TB_MissingTokens
            GROUP BY [NameDecoration]
            
            -- (A) Si quieres SOLO LISTAR ERRORES y seguir el proceso sin tronar:
            --     (esto te devuelve el listado para ver qué está malo)
            -- SELECT * FROM #TB_MissingAgg ORDER BY [NameDecoration]
  
            -- (B) Si quieres MARCAR EN #FINALTABLE SOLO EL REV DEL DECORADO QUE FALLÓ (sin afectar los demás):
            IF EXISTS (SELECT 1 FROM #TB_MissingAgg)
            BEGIN
                UPDATE F SET
                     [Rev_ScreenPrint]     = CASE WHEN F.[ScreenPrint]      >= 1 AND M1.[Msg]   IS NOT NULL THEN CONCAT('Screenprint'   ,'->',M1.[Msg]  ) ELSE F.[Rev_ScreenPrint]     END
                    ,[Rev_Sublimation]     = CASE WHEN F.[Sublimation]      >= 1 AND M2.[Msg]   IS NOT NULL THEN CONCAT('Sublimation'   ,'->',M2.[Msg]  ) ELSE F.[Rev_Sublimation]     END
                    ,[Rev_EmbroideryApp]   = CASE WHEN F.[EmbroideryAPP]    >= 1 AND M3.[Msg]   IS NOT NULL THEN CONCAT('EmbroideryApp' ,'->',M3.[Msg]  ) ELSE F.[Rev_EmbroideryApp]   END
                    ,[Rev_EmbroideryHW]    = CASE WHEN F.[EmbroideryHW]     >= 1 AND M4.[Msg]   IS NOT NULL THEN CONCAT('EmbroideryHW'  ,'->',M4.[Msg]  ) ELSE F.[Rev_EmbroideryHW]    END
                    ,[Rev_Relabel]         = CASE WHEN F.[Relabel]          >= 1 AND M5.[Msg]   IS NOT NULL THEN CONCAT('Relabel'       ,'->',M5.[Msg]  ) ELSE F.[Rev_Relabel]         END
                    ,[Rev_SubApplication]  = CASE WHEN F.[SubApplication]   >= 1 AND M6.[Msg]   IS NOT NULL THEN CONCAT('SubApplication','->',M6.[Msg]  ) ELSE F.[Rev_SubApplication]  END
                    ,[Rev_HDP]             = CASE WHEN F.[HDP]              >= 1 AND M7.[Msg]   IS NOT NULL THEN CONCAT('HDP'           ,'->',M7.[Msg]  ) ELSE F.[Rev_HDP]             END
                    ,[Rev_SpecialPK]       = CASE WHEN F.[SpecialPK]        >= 1 AND M8.[Msg]   IS NOT NULL THEN CONCAT('SpecialPK'     ,'->',M8.[Msg]  ) ELSE F.[Rev_SpecialPK]       END
                    ,[Rev_PigmentDye]      = CASE WHEN F.[PigmentDye]       >= 1 AND M9.[Msg]   IS NOT NULL THEN CONCAT('PigmentDye'    ,'->',M9.[Msg]  ) ELSE F.[Rev_PigmentDye]      END
                    ,[Rev_Samples]         = CASE WHEN F.[Samples]          >= 1 AND M13.[Msg]  IS NOT NULL THEN CONCAT('Samples'       ,'->',M13.[Msg] ) ELSE F.[Rev_Samples]         END
                    -- ,[Rev_SNApplication]   = CASE WHEN F.[SNApplication]    >= 1 AND M14.[Msg]  IS NOT NULL THEN CONCAT('SNApplication' ,'->',M14.[Msg] ) ELSE F.[Rev_SNApplication]   END
                    ,[Rev_BlankLCA]        = CASE WHEN F.[BlankLCA]         >= 1 AND M10.[Msg]  IS NOT NULL THEN CONCAT('BlankLCA'      ,'->',M10.[Msg] ) ELSE F.[Rev_BlankLCA]        END
                    ,[Rev_BlankSemiApp]    = CASE WHEN F.[BlankSemiApp]     >= 1 AND M11.[Msg]  IS NOT NULL THEN CONCAT('BlankSemiApp'  ,'->',M11.[Msg] ) ELSE F.[Rev_BlankSemiApp]    END
                    ,[Rev_BlankSemiHW]     = CASE WHEN F.[BlankSemiHW]      >= 1 AND M12.[Msg]  IS NOT NULL THEN CONCAT('BlankSemiHW'   ,'->',M12.[Msg] ) ELSE F.[Rev_BlankSemiHW]     END
                    ,[Rev_Final]           = CASE
                                                WHEN
                                                    (F.[ScreenPrint]   >= 1 AND M1.[Msg]  IS NOT NULL)
                                                 OR (F.[Sublimation]   >= 1 AND M2.[Msg]  IS NOT NULL)
                                                 OR (F.[EmbroideryAPP] >= 1 AND M3.[Msg]  IS NOT NULL)
                                                 OR (F.[EmbroideryHW]  >= 1 AND M4.[Msg]  IS NOT NULL)
                                                 OR (F.[Relabel]       >= 1 AND M5.[Msg]  IS NOT NULL)
                                                 OR (F.[SubApplication]>= 1 AND M6.[Msg]  IS NOT NULL)
                                                 OR (F.[HDP]           >= 1 AND M7.[Msg]  IS NOT NULL)
                                                 OR (F.[SpecialPK]     >= 1 AND M8.[Msg]  IS NOT NULL)
                                                 OR (F.[PigmentDye]    >= 1 AND M9.[Msg]  IS NOT NULL)
                                                 OR (F.[Samples]       >= 1 AND M13.[Msg] IS NOT NULL)
                                                --  OR (F.[SNApplication] >= 1 AND M14.[Msg] IS NOT NULL)
                                                 OR (F.[BlankLCA]      >= 1 AND M10.[Msg] IS NOT NULL)
                                                 OR (F.[BlankSemiApp]  >= 1 AND M11.[Msg] IS NOT NULL)
                                                 OR (F.[BlankSemiHW]   >= 1 AND M12.[Msg] IS NOT NULL)
                                                THEN 1
                                                ELSE F.[Rev_Final]
                                              END
                FROM #FINALTABLE F
                LEFT JOIN #TB_MissingAgg M1  ON M1.[NameDecoration]     = 'Screenprint'
                LEFT JOIN #TB_MissingAgg M2  ON M2.[NameDecoration]     = 'Sublimation'
                LEFT JOIN #TB_MissingAgg M3  ON M3.[NameDecoration]     = 'EmbroideryApp'
                LEFT JOIN #TB_MissingAgg M4  ON M4.[NameDecoration]     = 'EmbroideryHW'
                LEFT JOIN #TB_MissingAgg M5  ON M5.[NameDecoration]     = 'Relabel'
                LEFT JOIN #TB_MissingAgg M6  ON M6.[NameDecoration]     = 'SubApplication'
                LEFT JOIN #TB_MissingAgg M7  ON M7.[NameDecoration]     = 'HDP'
                LEFT JOIN #TB_MissingAgg M8  ON M8.[NameDecoration]     = 'SpecialPK'
                LEFT JOIN #TB_MissingAgg M9  ON M9.[NameDecoration]     = 'PigmentDye'
                LEFT JOIN #TB_MissingAgg M13 ON M13.[NameDecoration]    = 'Samples'
                -- LEFT JOIN #TB_MissingAgg M14 ON M14.[NameDecoration]    = 'SNApplication'
                LEFT JOIN #TB_MissingAgg M10 ON M10.[NameDecoration]    = 'BlankLCA'
                LEFT JOIN #TB_MissingAgg M11 ON M11.[NameDecoration]    = 'BlankSemiApp'
                LEFT JOIN #TB_MissingAgg M12 ON M12.[NameDecoration]    = 'BlankSemiHW'
            END
        
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        -----FIN VALIDACION DE TOKENS EN FORMULAS
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-----ACTUALIZACION FORMULAS-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			/* =========================
			   FORMULAS DINAMICAS
			   - Lee columnas de [AppsLCA].[dbo].[TB_Parameters_BillingDecoration_FreightCost]
			   - Reemplaza Columnas: [perLocation], [perUnit], [packingLabor], [MaterialCost], etc.
			   - Sin tocar código al agregar columnas nuevas
			========================= */
			SELECT *
			INTO #TB_Parameters_Formulas
			FROM [AppsLCA].[dbo].TB_Parameters_BillingDecoration_FreightCost WITH (NOLOCK)
			WHERE [Status] = 1;
			
			DECLARE 
			     @ReplaceExpr_Base      NVARCHAR(MAX) = N'{ALIAS}.[formula]'
			    ,@sqlUpdateDecoration   NVARCHAR(MAX) = N'';
			
			;WITH Cols AS (
			    SELECT
			        c.[name],
			        c.[column_id]
			    FROM [AppsLCA].[sys].[columns] c WITH(NOLOCK)
			    WHERE c.[object_id] = OBJECT_ID(N'[AppsLCA].[dbo].[TB_Parameters_BillingDecoration_FreightCost]')
			      AND c.[name] NOT IN (
			            'id','NameDecoration','formula','status','created_at','updated_at'
			        )
			)
			SELECT
			    @ReplaceExpr_Base =
			        N'REPLACE(' + @ReplaceExpr_Base
			        + N', ''[' + C.[name] + N']'', CONVERT(VARCHAR(50), COALESCE({ALIAS}.'
			        + QUOTENAME(C.[name]) + N',0)))'
			FROM Cols AS C
			ORDER BY C.[column_id];
			
			-- SELECT @ReplaceExpr_Base
			-- RETURN
			
			
			DECLARE
			     @R_SCR   NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_SCR')
			    ,@R_SUBL  NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_SUBL')
			    ,@R_EMBA  NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_EMB_App')
			    ,@R_EMBH  NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_EMB_HW')
			    ,@R_REL   NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_REL')
			    ,@R_SUBA  NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_SUBA')
			    ,@R_HDP   NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_HDP')
			    ,@R_SPK   NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_SpecialPK')
			    ,@R_PYD   NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_PigmentDye')
			    ,@R_SMP   NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_Samples')
			    
			    ,@R_FILA   NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_InlandFreight')
			    ,@R_FAIR   NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_AirFreight')
			    ,@R_FOCE   NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_OceanFreight')
			    -- ,@R_SNAP  NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_SNApplication')
			    ,@R_OFC  NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_OutboundFreight')
			    
			    ,@R_BLCA  NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_BlankLCA')
			    ,@R_BSA   NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_BlankSemiApp')
			    ,@R_BSH   NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_BlankSemiHW')
			    ,@R_TDECO NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_TOTAL_DECO')
			    ,@R_TBLK  NVARCHAR(MAX) = REPLACE(@ReplaceExpr_Base, N'{ALIAS}', N'P_TOTAL_BLANK');
		
		-- ,[Formula_SNApplication]    = CASE WHEN F.[SNApplication]  >= 1 THEN ''('' + ' + @R_SNAP  + N' + '')''  END
		-- OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''SNApplication'')    AS P_SNApplication
			SET @sqlUpdateDecoration = N'
			UPDATE F SET
			     [Formula_ScreenPrint]      = CASE WHEN F.[ScreenPrint]    >= 1 THEN ''('' + ' + @R_SCR   + N' + '')''  END
			    ,[Formula_Sublimation]      = CASE WHEN F.[Sublimation]    >= 1 THEN ''('' + ' + @R_SUBL  + N' + '')''  END
			    ,[Formula_EmbroideryApp]    = CASE WHEN F.[EmbroideryAPP]  >= 1 THEN ''('' + ' + @R_EMBA  + N' + '')''  END
			    ,[Formula_EmbroideryHW]     = CASE WHEN F.[EmbroideryHW]   >= 1 THEN ''('' + ' + @R_EMBH  + N' + '')''  END
			    ,[Formula_Relabel]          = CASE WHEN F.[Relabel]        >= 1 THEN ''('' + ' + @R_REL   + N' + '')''  END
			    ,[Formula_SubApplication]   = CASE WHEN F.[SubApplication] >= 1 THEN ''('' + ' + @R_SUBA  + N' + '')''  END
			    ,[Formula_HDP]              = CASE WHEN F.[HDP]            >= 1 THEN ''('' + ' + @R_HDP   + N' + '')''  END
			    ,[Formula_SpecialPK]        = CASE WHEN F.[SpecialPK]      >= 1 THEN ''('' + ' + @R_SPK   + N' + '')''  END
			    ,[Formula_PigmentDye]       = CASE WHEN F.[PigmentDye]     >= 1 THEN ''('' + ' + @R_PYD   + N' + '')''  END
			    ,[Formula_Samples]          = CASE WHEN F.[Samples]        >= 1 THEN ''('' + ' + @R_SMP   + N' + '')''  END
				,[Formula_BlankLCA]         = CASE WHEN F.[BlankLCA]       >= 1 THEN ''('' + ' + @R_BLCA  + N' + '')''  END
				,[Formula_BlankSemiApp]     = CASE WHEN F.[BlankSemiApp]   >= 1 THEN ''('' + ' + @R_BSA   + N' + '')''  END
				,[Formula_BlankSemiHW]      = CASE WHEN F.[BlankSemiHW]    >= 1 THEN ''('' + ' + @R_BSH   + N' + '')''  END
				,[Formula_InlandFreight]    = CASE WHEN F.[InlandFreight]  >= 1 THEN ''('' + ' + @R_FILA   + N' + '')''  END
				,[Formula_AirFreight]       = CASE WHEN F.[AirFreight]     >= 1 THEN ''('' + ' + @R_FAIR   + N' + '')''  END
				,[Formula_OceanFreight]     = CASE WHEN F.[OceanFreight]   >= 1 THEN ''('' + ' + @R_FOCE   + N' + '')''  END
				
				,[Formula_OutboundFreight]  = ''('' + ' + @R_OFC + N' + '')''
				,[Formula_TotalDecoration]  = ''('' + ' + @R_TDECO + N' + '')''
				,[Formula_TotalBlank]       = ''('' + ' + @R_TBLK  + N' + '')''
			FROM #FINALTABLE AS F
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''Screenprint'')      AS P_SCR
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''Sublimation'')      AS P_SUBL
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''EmbroideryApp'')    AS P_EMB_App
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''EmbroideryHW'')     AS P_EMB_HW
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''Relabel'')          AS P_REL
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''SubApplication'')   AS P_SUBA
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''HDP'')              AS P_HDP
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''SpecialPK'')        AS P_SpecialPK
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''PigmentDye'')       AS P_PigmentDye
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''Samples'')          AS P_Samples
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''BlankLCA'')         AS P_BlankLCA
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''BlankSemiApp'')     AS P_BlankSemiApp
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''BlankSemiHW'')      AS P_BlankSemiHW
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''InlandFreight'')    AS P_InlandFreight
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''AirFreight'')       AS P_AirFreight
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''OceanFreight'')     AS P_OceanFreight
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''OutboundFreight'')  AS P_OutboundFreight
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''TotalDecoration'')  AS P_TOTAL_DECO
			OUTER APPLY (SELECT TOP (1) * FROM #TB_Parameters_Formulas WHERE [NameDecoration] = ''TotalBlank'')       AS P_TOTAL_BLANK;
			';
			
			EXEC sp_executesql @sqlUpdateDecoration
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-----ACTUALIZACION FORMULAS-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- SELECT * FROM #FINALTABLE
		
		
		-- return
		
		
		
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-----ACTUALIZACION VALORES CON DATOS SEGUN FORMULA------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	        DECLARE 
			     @GlobalTableName NVARCHAR(128) = '##TB_Result_Decoration' + CAST(@@SPID AS NVARCHAR(10))
			    ,@sql NVARCHAR(MAX)
			    ,@RowData INT = 1
			    ,@Total INT
			    ,@F1    NVARCHAR(MAX)
			    ,@F2    NVARCHAR(MAX)
			    ,@F3    NVARCHAR(MAX)
			    ,@F4    NVARCHAR(MAX)
			    ,@F5    NVARCHAR(MAX)
			    ,@F6    NVARCHAR(MAX)
			    ,@F7    NVARCHAR(MAX)
			    ,@F8    NVARCHAR(MAX)
			    ,@F9    NVARCHAR(MAX)
			    ,@F15   NVARCHAR(MAX)
			    ,@F10   NVARCHAR(MAX)
			    ,@F16   NVARCHAR(MAX)
			    ,@F11   NVARCHAR(MAX)
			    ,@F12   NVARCHAR(MAX)
			    ,@F13   NVARCHAR(MAX)
			    ,@F14   NVARCHAR(MAX)
                ,@F17   NVARCHAR(MAX)
                ,@F18   NVARCHAR(MAX)
                ,@F19   NVARCHAR(MAX)

			-- ,[Price_SNApplication]  DECIMAL(18,2) NULL
			SET @sql = '
			DROP TABLE IF EXISTS ' + @GlobalTableName + ';
			CREATE TABLE ' + @GlobalTableName + ' (
			     [RowData] INT
			    ,[Price_ScreenPrint]        DECIMAL(18,2) NULL
			    ,[Price_Sublimation]        DECIMAL(18,2) NULL
			    ,[Price_EmbroideryApp]      DECIMAL(18,2) NULL
			    ,[Price_EmbroideryHW]       DECIMAL(18,2) NULL
			    ,[Price_Relabel]            DECIMAL(18,2) NULL
			    ,[Price_SubApplication]     DECIMAL(18,2) NULL
			    ,[Price_HDP]                DECIMAL(18,2) NULL
			    ,[Price_SpecialPK]          DECIMAL(18,2) NULL
			    ,[Price_PigmentDye]         DECIMAL(18,2) NULL
			    ,[Price_Samples]            DECIMAL(18,2) NULL
			    ,[Price_BlankLCA]           DECIMAL(18,2) NULL
			    ,[Price_BlankSemiApp]       DECIMAL(18,2) NULL
			    ,[Price_BlankSemiHW]        DECIMAL(18,2) NULL
			    ,[Price_InlandFreight]      DECIMAL(18,2) NULL
			    ,[Price_AirFreight]         DECIMAL(18,2) NULL
			    ,[Price_OceanFreight]       DECIMAL(18,2) NULL
			    ,[OutboundFreight]    DECIMAL(18,2) NULL
			    ,[TotalBlank]               DECIMAL(18,2) NULL
			    ,[TotalDecoration]          DECIMAL(18,2) NULL
			    ,[ManualBlankPrice]         DECIMAL(18,2) NULL
			    ,[ManualDecoPrice]          DECIMAL(18,2) NULL
			    ,[IsManualPrice]            DECIMAL(18,2) NULL
			)';
			EXEC sp_executesql @sql;
			
			SELECT @Total = MAX([RowData]) FROM #FINALTABLE
	        -- SELECT @Total, @RowData
	       
	        WHILE @RowData <= @Total
    			BEGIN
    			    SELECT
    			         @F1    = [Formula_ScreenPrint]
    			        ,@F2    = [Formula_Sublimation]
    			        ,@F3    = [Formula_EmbroideryApp]
    			        ,@F4    = [Formula_EmbroideryHW]
    			        ,@F5    = [Formula_Relabel]
    			        ,@F6    = [Formula_SubApplication]
    			        ,@F7    = [Formula_HDP]
    			        ,@F8    = [Formula_SpecialPK]
    			        ,@F9    = [Formula_PigmentDye]
    			        ,@F10   = [Formula_Samples]
    			        -- ,@F16   = [Formula_SNApplication]
    			        ,@F11   = [Formula_BlankLCA]
    			        ,@F12   = [Formula_BlankSemiApp]
    			        ,@F13   = [Formula_BlankSemiHW]
    			        
    			        ,@F14   = [Formula_TotalBlank]
    			        ,@F15   = [Formula_TotalDecoration]
    			        
    			        ,@F19   = [Formula_InlandFreight]
    			        ,@F16   = [Formula_AirFreight]
    			        ,@F17   = [Formula_OceanFreight]
    			        ,@F18   = [Formula_OutboundFreight]
    			        
    			    FROM #FINALTABLE
    			    WHERE [RowData] = @RowData
    			
    			    --  select @F19
    			    BEGIN TRY
    			    -- ,[Price_SNApplication]
    			    -- ,', COALESCE(NULLIF(LTRIM(RTRIM(@F16)),''),'0'), '
            			    SET @sql = CONCAT('
            			        INSERT INTO ', @GlobalTableName, ' (
            			             [RowData]
            			            ,[Price_ScreenPrint]
            			            ,[Price_Sublimation]
            			            ,[Price_EmbroideryApp]
            			            ,[Price_EmbroideryHW]
            			            ,[Price_Relabel]
            			            ,[Price_SubApplication]
            			            ,[Price_HDP]
            			            ,[Price_SpecialPK]
            			            ,[Price_PigmentDye]
            			            ,[Price_Samples]
            			            
            			            ,[Price_InlandFreight]
            			            ,[Price_AirFreight]
            			            ,[Price_OceanFreight]
            			            
            			            ,[Price_BlankLCA]
            						,[Price_BlankSemiApp] 
            						,[Price_BlankSemiHW]  
            						
            			            ,[ManualBlankPrice]
            			            ,[ManualDecoPrice]
            			            ,[IsManualPrice]
            			        )
            			        SELECT
            			             ', @RowData, '
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F1)),''),'0'), '
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F2)),''),'0'), '
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F3)),''),'0'), '
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F4)),''),'0'), '
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F5)),''),'0'), '
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F6)),''),'0'), '
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F7)),''),'0'), '
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F8)),''),'0'), '
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F9)),''),'0'), '
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F10)),''),'0'), '
            			            
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F19)),''),'0'), '
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F16)),''),'0'), '
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F17)),''),'0'), '

            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F11)),''),'0'), '
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F12)),''),'0'), '
            			            ,', COALESCE(NULLIF(LTRIM(RTRIM(@F13)),''),'0'), '
            			            
            			            ,[ManualBlankPrice]
            			            ,[ManualDecoPrice]
            			            ,[IsManualPrice]
            			         FROM #FINALTABLE
            	            WHERE RowData = ' , @RowData
            	            )
            			
            		
            			    EXEC sp_executesql @sql
            			

            		
            			EXEC sp_executesql @sql

            			-- print @sql
            				SET @sql = CONCAT('
            				  UPDATE S SET
            	                     [TotalBlank]      = ', COALESCE(NULLIF(LTRIM(RTRIM(@F14)),''),'0'), '
            	                    ,[TotalDecoration] = ', COALESCE(NULLIF(LTRIM(RTRIM(@F15)),''),'0'), '
            	                    
            	                    ,[OutboundFreight]      = ', COALESCE(NULLIF(LTRIM(RTRIM(@F18)),''),'0'), '
            	                FROM ', @GlobalTableName, ' AS S
            	            WHERE S.RowData = ' , @RowData
            	            )
            			
            			    EXEC sp_executesql @sql
    	            END TRY
                    BEGIN CATCH
                        -- DECLARE @ErrMsg2 NVARCHAR(MAX) = ERROR_MESSAGE()
                
                        
                        -- THROW 50001, CONCAT(
                        --     'ERROR evaluando formulas. RowData=', @RowData,
                        --     CHAR(10), 'SQL=', @sql,
                        --     CHAR(10), 'MSG=', @ErrMsg2
                        -- ), 1
                    END CATCH

    			    SET @RowData += 1
    			END
	
			    -- ,[Price_SNApplication]  = CAST(R.[Price_SNApplication]  AS DECIMAL(18,2))
   
			SET @sql = '
			UPDATE F    SET
			     [Price_ScreenPrint]     = CAST(R.[Price_ScreenPrint]     AS DECIMAL(18,2))
			    ,[Price_Sublimation]     = CAST(R.[Price_Sublimation]     AS DECIMAL(18,2))
			    ,[Price_EmbroideryApp]   = CAST(R.[Price_EmbroideryApp]   AS DECIMAL(18,2))
			    ,[Price_EmbroideryHW]    = CAST(R.[Price_EmbroideryHW]    AS DECIMAL(18,2))
			    ,[Price_Relabel]         = CAST(R.[Price_Relabel]         AS DECIMAL(18,2))
			    ,[Price_SubApplication]  = CAST(R.[Price_SubApplication]  AS DECIMAL(18,2))
			    ,[Price_HDP]             = CAST(R.[Price_HDP]             AS DECIMAL(18,2))
			    ,[Price_SpecialPK]       = CAST(R.[Price_SpecialPK]       AS DECIMAL(18,2))
			    ,[Price_PigmentDye]      = CAST(R.[Price_PigmentDye]      AS DECIMAL(18,2))
			    ,[Price_Samples]         = CAST(R.[Price_Samples]         AS DECIMAL(18,2))
			      
			    ,[Price_InlandFreight]   = CAST(R.[Price_InlandFreight]   AS DECIMAL(18,2))
			    ,[Price_AirFreight]      = CAST(R.[Price_AirFreight]      AS DECIMAL(18,2))
			    ,[Price_OceanFreight]    = CAST(R.[Price_OceanFreight]    AS DECIMAL(18,2))
			    ,[OutboundFreight]       = CAST(R.[OutboundFreight] AS DECIMAL(18,2))

			    ,[Price_BlankLCA]        = CAST(R.[Price_BlankLCA]        AS DECIMAL(18,2))
			    ,[Price_BlankSemiApp]    = CAST(R.[Price_BlankSemiApp]    AS DECIMAL(18,2))
			    ,[Price_BlankSemiHW]     = CAST(R.[Price_BlankSemiHW]     AS DECIMAL(18,2))
			    ,[TotalBlank]            = CAST(R.[TotalBlank]            AS DECIMAL(18,2))
			    ,[TotalDecoration]       = CAST(R.[TotalDecoration]       AS DECIMAL(18,2))
			FROM #FINALTABLE AS F
			INNER JOIN ' + @GlobalTableName + ' AS R
			    ON R.[RowData] = F.[RowData]
			    ;
			    --SELECT * FROM ' + @GlobalTableName + ' AS R
			    '
			EXEC sp_executesql @sql
			
			SET @sql = 'DROP TABLE IF EXISTS ' + @GlobalTableName + ''
			EXEC sp_executesql @sql
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-----ACTUALIZACION VALORES CON DATOS SEGUN FORMULA------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
		-- SELECT * FROM #FINALTABLE
		-- RETURN
			
			IF  @DATE_GETDATE < @DATE_NEW_OUTBOUND
			BEGIN
				UPDATE S SET
					 [InlandFreight]            = 0
					,[AirFreight]               = 0
					,[OceanFreight]             = 0
					,[Price_InlandFreight]      = 0
					,[Price_AirFreight]         = 0
					,[Price_OceanFreight]       = 0
					,[OutboundFreight]          = 0
					,[Formula_InlandFreight]    = NULL
					,[Formula_AirFreight]       = NULL   
					,[Formula_OceanFreight]     = NULL   
					,[Formula_OutboundFreight]  = NULL   
				FROM #FINALTABLE AS S
			END
		
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-----OVERRIDE TotalBlank/TotalDecoration PARA ORDENES CON PRECIO MANUAL--------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			UPDATE F SET
				 F.TotalBlank      = F.ManualBlankPrice
				,F.TotalDecoration = F.ManualDecoPrice
			FROM #FINALTABLE AS F
			WHERE F.IsManualPrice = 1
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
		-- SELECT * FROM #FINALTABLE
		-- RETURN
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-----REVISION PRICES DE COLUMNAS DE DECORADO------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			UPDATE S SET

		     [Rev_ScreenPrint] =
		        CASE
		            WHEN S.[ScreenPrint] < 1 THEN NULL
		            WHEN S.[Rev_ScreenPrint] IS NOT NULL AND S.[Rev_ScreenPrint] <> 'OK' THEN S.[Rev_ScreenPrint]
		            WHEN COALESCE(S.[Price_ScreenPrint],0) <= 0 THEN 'Screen Print Price = 0'
		            ELSE 'OK'
		        END
		
		    ,[Rev_Sublimation] =
		        CASE
		            WHEN S.[Sublimation] < 1 THEN NULL
		            WHEN S.[Rev_Sublimation] IS NOT NULL AND S.[Rev_Sublimation] <> 'OK' THEN S.[Rev_Sublimation]
		            WHEN COALESCE(S.[Price_Sublimation],0) <= 0 THEN 'Sublimation Price = 0'
		            ELSE 'OK'
		        END
		
		    ,[Rev_EmbroideryApp] =
		        CASE
		            WHEN S.[EmbroideryAPP] < 1 THEN NULL
		            WHEN S.[Rev_EmbroideryApp] IS NOT NULL AND S.[Rev_EmbroideryApp] <> 'OK' THEN S.[Rev_EmbroideryApp]
		            WHEN COALESCE(S.[Price_EmbroideryApp],0) <= 0 THEN 'Embroidery Apparel Price = 0'
		            ELSE 'OK'
		        END
		
		    ,[Rev_EmbroideryHW] =
		        CASE
		            WHEN S.[EmbroideryHW] < 1 THEN NULL
		            WHEN S.[Rev_EmbroideryHW] IS NOT NULL AND S.[Rev_EmbroideryHW] <> 'OK' THEN S.[Rev_EmbroideryHW]
		            WHEN COALESCE(S.[Price_EmbroideryHW],0) <= 0 THEN 'Embroidery Headwear Price = 0'
		            ELSE 'OK'
		        END
		
		    ,[Rev_Relabel] =
		        CASE
		            WHEN S.[Relabel] < 1 THEN NULL
		            WHEN S.[Rev_Relabel] IS NOT NULL AND S.[Rev_Relabel] <> 'OK' THEN S.[Rev_Relabel]
		            WHEN COALESCE(S.[Price_Relabel],0) <= 0 THEN 'Relabel Price = 0'
		            ELSE 'OK'
		        END
		
		    ,[Rev_SubApplication] =
		        CASE
		            WHEN S.[SubApplication] < 1 THEN NULL
		            WHEN S.[Rev_SubApplication] IS NOT NULL AND S.[Rev_SubApplication] <> 'OK' THEN S.[Rev_SubApplication]
		            WHEN COALESCE(S.[Price_SubApplication],0) <= 0 THEN 'Sub Aplication Price = 0'
		            ELSE 'OK'
		        END
		
		    ,[Rev_HDP] =
		        CASE
		            WHEN S.[HDP] < 1 THEN NULL
		            WHEN S.[Rev_HDP] IS NOT NULL AND S.[Rev_HDP] <> 'OK' THEN S.[Rev_HDP]
		            WHEN COALESCE(S.[Price_HDP],0) <= 0 THEN 'High definition print Price = 0'
		            ELSE 'OK'
		        END
		
		    ,[Rev_SpecialPK] =
		        CASE
		            WHEN S.[SpecialPK] < 1 THEN NULL
		            WHEN S.[Rev_SpecialPK] IS NOT NULL AND S.[Rev_SpecialPK] <> 'OK' THEN S.[Rev_SpecialPK]
		            WHEN COALESCE(S.[Price_SpecialPK],0) <= 0 THEN 'Special Packing Price = 0'
		            ELSE 'OK'
		        END
		
		    ,[Rev_PigmentDye] =
		        CASE
		            WHEN S.[PigmentDye] < 1 THEN NULL
		            WHEN S.[Rev_PigmentDye] IS NOT NULL AND S.[Rev_PigmentDye] <> 'OK' THEN S.[Rev_PigmentDye]
		            WHEN COALESCE(S.[Price_PigmentDye],0) <= 0 THEN 'Pigment Dye Price = 0'
		            ELSE 'OK'
		        END
		
		    ,[Rev_BlankLCA] =
		        CASE
		            WHEN S.[BlankLCA] < 1 THEN NULL
		            WHEN S.[Rev_BlankLCA] IS NOT NULL AND S.[Rev_BlankLCA] <> 'OK' THEN S.[Rev_BlankLCA]
		            WHEN COALESCE(S.[LCABasePrice],0)   <= 0 THEN 'Blank LCA Price = 0' 
		            WHEN COALESCE(S.[Price_BlankLCA],0) <= 0 THEN 'Formula Blank LCA Price = 0' 
		            ELSE 'OK'
		        END
		
		    ,[Rev_BlankSemiApp] =
		        CASE
		            WHEN S.[BlankSemiApp] < 1 THEN NULL
		            WHEN S.[Rev_BlankSemiApp] IS NOT NULL AND S.[Rev_BlankSemiApp] <> 'OK' THEN S.[Rev_BlankSemiApp]
		            WHEN COALESCE(S.[PurchaseBasePrice],0) <= 0 THEN 'Blank Semi Apparel Price = 0'
		            WHEN COALESCE(S.[Price_BlankSemiApp],0) <= 0 THEN 'Formula Blank Semi Apparel Price = 0'
		            ELSE 'OK'
		        END
		
		    ,[Rev_BlankSemiHW] =
		        CASE
		            WHEN S.[BlankSemiHW] < 1 THEN NULL
		            WHEN S.[Rev_BlankSemiHW] IS NOT NULL AND S.[Rev_BlankSemiHW] <> 'OK' THEN S.[Rev_BlankSemiHW]
		            WHEN COALESCE(S.[PurchaseBasePrice],0) <= 0 THEN 'Blank Semi Headwear Price = 0'
		            WHEN COALESCE(S.[Price_BlankSemiHW],0) <= 0 THEN 'Formula Blank Semi Headwear Price = 0'
		            ELSE 'OK'
		        END
		    
		
		FROM #FINALTABLE AS S
		WHERE ISNULL(S.[Samples],0) = 0 -----VALIDACION QUE SE AGREGA SOLO PARA PONER LO DE SAMPLES.
		

        UPDATE S SET 
            [Rev_InvoicingDescription]	    = IIF(S.[InvoicingDescription] IS NULL OR [AppsLCA].[dbo].[cleanString](S.[InvoicingDescription]) = '' 
                                                    ,'Column: "Invoicing Description"'
                                                    ,'OK'
                                                    )
		FROM #FINALTABLE AS S
        
        UPDATE S SET 
            [Rev_TariffCategory]	       = IIF(S.[TariffCategory] IS NULL OR [AppsLCA].[dbo].[cleanString](S.[TariffCategory]) = '' 
                                                    ,'Column: "TariffCategory"'
                                                    ,'OK'
                                                    )
		FROM #FINALTABLE AS S
		

		-- DECLARE @DATE_NEW_OUTBOUND  AS DATE = CAST('2026-07-01' AS DATE)
		-- DECLARE @DATE_GETDATE       AS DATE = CAST(GETDATE() AS DATE)
            
        UPDATE S SET
            [Rev_OutboundFreight] = COALESCE(RF.Comments, 'OK')
        FROM #FINALTABLE AS S
        OUTER APPLY (
            SELECT
                [Comments] = STRING_AGG(V.Msg, ', ')
            FROM (
                -- 1: OutboundFreight price must be greater than zero
                SELECT Msg = 'El precio de OutboundFreight debe ser mayor a cero' 
                WHERE COALESCE(S.[OutboundFreight], 0) <= 0
                AND @DATE_GETDATE >= @DATE_NEW_OUTBOUND

                UNION ALL
                -- 2: TypeDestination cannot be null (update Description2 in OrderType3)
                SELECT Msg = 'TypeDestination no puede ser nulo (actualizar Description2 en OrderType3)'
                WHERE S.[TypeDestination] IS NULL OR LTRIM(RTRIM(S.[TypeDestination])) = ''
				AND @DATE_GETDATE >= @DATE_NEW_OUTBOUND
                
                UNION ALL
                -- 3: LEFT(PuertoDestino) must match ShipTo — ORD orders only
                SELECT Msg = 'PuertoDestino (PO)'
                WHERE LEFT(S.[PONumber], 3) <> 'ORD'
                  AND S.[PuertoDestino] IS NOT NULL
                  AND S.[ShipTo] IS NOT NULL
                  AND LEFT(S.[PuertoDestino], LEN(S.[ShipTo])) <> S.[ShipTo]
				-- AND @DATE_GETDATE >= @DATE_NEW_OUTBOUND

                UNION ALL
                -- 3: LEFT(PuertoDestino) must match ShipTo — ORD orders only
                SELECT Msg = 'PuertoDestino debe ser igual a ShipTo (solo ordenes ORD)'
                WHERE LEFT(S.[PONumber], 3) = 'ORD'
                  AND S.[PuertoDestino] IS NOT NULL
                  AND S.[ShipTo] IS NOT NULL
                  AND LEFT(S.[PuertoDestino], LEN(S.[ShipTo])) <> S.[ShipTo]
				-- AND @DATE_GETDATE >= @DATE_NEW_OUTBOUND

                UNION ALL
                -- 4: PuertoDestino cannot be null
                SELECT Msg = 'PuertoDestino no puede ser nulo'
                WHERE S.[PuertoDestino] IS NULL
				-- AND @DATE_GETDATE >= @DATE_NEW_OUTBOUND

                UNION ALL
                -- 5: AirFreight and OceanFreight cannot both be 1 at the same time
                SELECT Msg = 'AirFreight y OceanFreight no pueden estar activos al mismo tiempo'
                WHERE COALESCE(S.[AirFreight], 0) = 1
                  AND COALESCE(S.[OceanFreight], 0) = 1
                AND @DATE_GETDATE >= @DATE_NEW_OUTBOUND

                UNION ALL
                -- 6: AirFreight and OceanFreight cannot both be zero
                SELECT Msg = 'AirFreight y OceanFreight no pueden ser ambos cero'
                WHERE COALESCE(S.[AirFreight], 0) = 0
                  AND COALESCE(S.[OceanFreight], 0) = 0
                AND @DATE_GETDATE >= @DATE_NEW_OUTBOUND

                UNION ALL
                -- 7: AirFreight and OceanFreight cannot both be null
                SELECT Msg = 'AirFreight y OceanFreight no pueden ser ambos nulos'
                WHERE S.[AirFreight] IS NULL
                  AND S.[OceanFreight] IS NULL
                AND @DATE_GETDATE >= @DATE_NEW_OUTBOUND

                UNION ALL
                -- 8: Price_AirFreight must be greater than zero when AirFreight = 1
                SELECT Msg = 'Price_AirFreight debe ser mayor a cero cuando AirFreight esta activo'
                WHERE COALESCE(S.[AirFreight], 0) = 1
                  AND COALESCE(S.[Price_AirFreight], 0) <= 0
                AND @DATE_GETDATE >= @DATE_NEW_OUTBOUND

                UNION ALL
                -- 9: Price_OceanFreight must be greater than zero when OceanFreight = 1
                SELECT Msg = 'Price_OceanFreight debe ser mayor a cero cuando OceanFreight esta activo'
                WHERE COALESCE(S.[OceanFreight], 0) = 1
                  AND COALESCE(S.[Price_OceanFreight], 0) <= 0
                AND @DATE_GETDATE >= @DATE_NEW_OUTBOUND

                UNION ALL
                -- 10: Price_InlandFreight must be greater than zero when InlandFreight = 1
                SELECT Msg = 'Price_InlandFreight debe ser mayor a cero cuando InlandFreight esta activo'
                WHERE COALESCE(S.[InlandFreight], 0) = 1
                  AND COALESCE(S.[Price_InlandFreight], 0) <= 0
                AND @DATE_GETDATE >= @DATE_NEW_OUTBOUND

                UNION ALL
                -- 11: InlandFreight must be 1 when TypeDestination = 'Inland'
                SELECT Msg = 'InlandFreight debe estar activo cuando TypeDestination es Inland'
                WHERE S.[TypeDestination] LIKE '%Inland%'
                  AND COALESCE(S.[InlandFreight], 0) = 0
                AND @DATE_GETDATE >= @DATE_NEW_OUTBOUND

            ) AS V
            WHERE V.Msg IS NOT NULL
        ) AS RF


        UPDATE S SET
                [Rev_OrderType]     = COALESCE(X.Msg, 'OK')
            FROM #FINALTABLE AS S
            OUTER APPLY (
                SELECT
                    [Msg] = STRING_AGG(V.Msg, ', ')
                FROM (
                    -- si es blank -> OK (no agregamos errores)
                    SELECT Msg = CAST(NULL AS VARCHAR(MAX))
                    WHERE S.[OrderType2] LIKE '%blank%'
            
                    UNION ALL
                    -- A) transfer o DHT => HDP >= 1
                    SELECT Msg = 'ORDER TYPE HDP >= 1'
                    WHERE (S.[OrderType2] LIKE '%transfer%' OR S.[OrderType2] LIKE '%DHT%')
                      AND COALESCE(S.[HDP],0) < 1
            
                    UNION ALL
                    -- B) Sublim => Sublimation >= 1
                    SELECT Msg = 'ORDER TYPE Sublimation >= 1'
                    WHERE S.[OrderType2] LIKE '%Sublim%' 
                      AND (COALESCE(S.[Sublimation],0) < 1
                        AND COALESCE(S.[SubApplication],0) < 1
                        )
            
                    UNION ALL
                    -- C) Embro => EmbroideryAPP o EmbroideryHW >= 1
                    SELECT Msg = 'ORDER TYPE EmbroideryAPP o EmbroideryHW >= 1'
                    WHERE S.[OrderType2] LIKE '%Embro%'
                      AND (COALESCE(S.[EmbroideryAPP],0) < 1 AND COALESCE(S.[EmbroideryHW],0) < 1)
            
                    UNION ALL
                    -- E) Print => ScreenPrint >= 1
                    SELECT Msg = 'ORDER TYPE  ScreenPrint >= 1'
                    WHERE S.[OrderType2] LIKE '%Print%'
                      AND COALESCE(S.[ScreenPrint],0) < 1
            
                ) AS V
                WHERE V.Msg IS NOT NULL
            ) AS X


        UPDATE S SET
            [Rev_DecorationWorkflow] = COALESCE(RW.Comments,'OK')
        FROM #FINALTABLE AS S
        OUTER APPLY (
            SELECT
                [CodeCount] = COUNT(*)
            FROM STRING_SPLIT(CONVERT(VARCHAR(MAX), COALESCE(S.[Code],'')), ',') AS X
            WHERE LTRIM(RTRIM(X.value)) <> ''
        ) CA
        OUTER APPLY (
            SELECT STRING_AGG(V.Msg, ', ') AS Comments
            FROM (VALUES
                (
                    CASE
                        WHEN COALESCE(S.[ScreenPrint],0) > 0
                         AND COALESCE(S.[PrintCount],0) <> COALESCE(S.[ScreenPrint],0)
                        THEN CONCAT(
                                'WORKFLOW ScreenPrint (', COALESCE(S.[ScreenPrint],0),
                                ') debe ser igual a PrintCount (', COALESCE(S.[PrintCount],0), ')'
                             )
                    END
                ),
                (
                    CASE
                        WHEN COALESCE(S.[EmbroideryAPP],0) > 0
                         AND COALESCE(S.[EmbroideryAPP],0) <> COALESCE(CA.[CodeCount],0)
                        THEN CONCAT(
                                'WORKFLOW EmbroideryAPP (', COALESCE(S.[EmbroideryAPP],0),
                                ') debe ser igual a #Codes (', COALESCE(CA.[CodeCount],0), ')'
                             )
                    END
                ),
                (
                    CASE
                        WHEN COALESCE(S.[EmbroideryHW],0) > 0 
                         AND COALESCE(S.[EmbroideryHW],0) <> COALESCE(CA.[CodeCount],0)
                        THEN CONCAT(
                                'WORKFLOW EmbroideryHW (', COALESCE(S.[EmbroideryHW],0),
                                ') debe ser igual a #Codes (', COALESCE(CA.[CodeCount],0), ')'
                             )
                    END
                )
            ) V(Msg)
            WHERE V.Msg IS NOT NULL
        ) RW
		WHERE ISNULL(S.[Samples],0) = 0  -----VALIDACION QUE SE AGREGA SOLO PARA PONER LO DE SAMPLES.



		-- UPDATE S SET
		-- 	[Rev_OutboundFreight] = COALESCE(RF.Comments,'OK')
		-- FROM #FINALTABLE AS S


		UPDATE S SET 
			[Rev_Final] =
			    CASE
			        WHEN EXISTS (
			            SELECT 1
			            FROM (VALUES
			                 (S.[Rev_ScreenPrint])
			                ,(S.[Rev_Sublimation])
			                ,(S.[Rev_EmbroideryApp])
			                ,(S.[Rev_EmbroideryHW])
			                ,(S.[Rev_Relabel])
			                ,(S.[Rev_SubApplication])
			                ,(S.[Rev_HDP])
			                ,(S.[Rev_SpecialPK])
			                ,(S.[Rev_PigmentDye])
			                ,(S.[Rev_Samples])
			                -- ,(S.[Rev_SNApplication])
			                ,(S.[Rev_BlankLCA])
			                ,(S.[Rev_BlankSemiApp])
			                ,(S.[Rev_BlankSemiHW])
			                ,(S.[Rev_InvoicingDescription])
			                ,(S.[Rev_OrderType])
			                ,(S.[Rev_DecorationWorkflow])
			                ,(S.[Rev_TariffCategory])
			                ,(S.[Rev_OutboundFreight])
			            ) V(Rev)
			            WHERE V.Rev IS NOT NULL
			              AND V.Rev <> 'OK'
			        )
			        THEN 1
			        ELSE 0
			    END
			FROM #FINALTABLE AS S



			UPDATE S SET
			    [Rev_Comments] = COALESCE(RC.Comments, 'OK')
			FROM #FINALTABLE AS S
			OUTER APPLY (
			    SELECT STRING_AGG(V.Rev, ', ') AS Comments
			    FROM (VALUES
			         (NULLIF(S.[Rev_ScreenPrint]            ,'OK'))
			        ,(NULLIF(S.[Rev_Sublimation]            ,'OK'))
			        ,(NULLIF(S.[Rev_EmbroideryApp]          ,'OK'))
			        ,(NULLIF(S.[Rev_EmbroideryHW]           ,'OK'))
			        ,(NULLIF(S.[Rev_Relabel]                ,'OK'))
			        ,(NULLIF(S.[Rev_SubApplication]         ,'OK'))
			        ,(NULLIF(S.[Rev_HDP]                    ,'OK'))
			        ,(NULLIF(S.[Rev_SpecialPK]              ,'OK'))
			        ,(NULLIF(S.[Rev_PigmentDye]             ,'OK'))
			        ,(NULLIF(S.[Rev_Samples]                ,'OK'))
			        -- ,(NULLIF(S.[Rev_SNApplication]          ,'OK'))
			        ,(NULLIF(S.[Rev_BlankLCA]               ,'OK'))
			        ,(NULLIF(S.[Rev_BlankSemiApp]           ,'OK'))
			        ,(NULLIF(S.[Rev_BlankSemiHW]            ,'OK'))
			        ,(NULLIF(S.[Rev_InvoicingDescription]   ,'OK'))
			        ,(NULLIF(S.[Rev_OrderType]              ,'OK'))
			        ,(NULLIF(S.[Rev_DecorationWorkflow]     ,'OK'))
			        ,(NULLIF(S.[Rev_TariffCategory]         ,'OK'))
			        ,(NULLIF(S.[Rev_OutboundFreight]         ,'OK'))
			    ) V(Rev)
			    WHERE V.Rev IS NOT NULL
			) AS RC
      

			UPDATE F SET
			     [Formula_ScreenPrint]      = ISNULL([Formula_ScreenPrint]     ,'-')
			    ,[Formula_Sublimation]      = ISNULL([Formula_Sublimation]     ,'-')
			    ,[Formula_EmbroideryApp]    = ISNULL([Formula_EmbroideryApp]   ,'-')
			    ,[Formula_EmbroideryHW]     = ISNULL([Formula_EmbroideryHW]    ,'-')
			    ,[Formula_Relabel]          = ISNULL([Formula_Relabel]         ,'-')
			    ,[Formula_SubApplication]   = ISNULL([Formula_SubApplication]  ,'-')
			    ,[Formula_HDP]              = ISNULL([Formula_HDP]             ,'-')
			    ,[Formula_SpecialPK]        = ISNULL([Formula_SpecialPK]       ,'-')
			    ,[Formula_PigmentDye]       = ISNULL([Formula_PigmentDye]      ,'-')
			    ,[Formula_Samples]          = ISNULL([Formula_Samples]         ,'-')
			    -- ,[Formula_SNApplication]    = ISNULL([Formula_SNApplication]   ,'-')
				,[Formula_BlankLCA]         = ISNULL([Formula_BlankLCA]        ,'-')
				,[Formula_BlankSemiApp]     = ISNULL([Formula_BlankSemiApp]    ,'-')
				,[Formula_BlankSemiHW]      = ISNULL([Formula_BlankSemiHW]     ,'-')
				,[Formula_TotalDecoration]  = ISNULL([Formula_TotalDecoration] ,'-')
				,[Formula_TotalBlank]       = ISNULL([Formula_TotalBlank]      ,'-')
				
				,[Formula_InlandFreight]    = ISNULL([Formula_InlandFreight]      ,'-')
				,[Formula_AirFreight]       = ISNULL([Formula_AirFreight]      ,'-')
				,[Formula_OceanFreight]     = ISNULL([Formula_OceanFreight]      ,'-')
				,[Formula_OutboundFreight]  = ISNULL([Formula_OutboundFreight]      ,'-')
				
				-----CAMBIAR PARA TOMAR PERIODO JH DESCOMENTAR
				-- ,[Rev_Final]                = 0 
				-----CAMBIAR PARA TOMAR PERIODO JH DESCOMENTAR
				
			FROM #FINALTABLE AS F

		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-----REVISION PRICES DE COLUMNAS DE DECORADO------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-----OVERRIDE Rev_Final Y Rev_Comments PARA ORDENES CON PRECIO MANUAL-------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			UPDATE F SET
				 F.Rev_Final    = 0
				,F.Rev_Comments = F.ManualCommentPrice --'Price defined by parameters by approved'
			FROM #FINALTABLE AS F
			WHERE F.IsManualPrice = 1
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-----ORDENES ESPERANDO APROBACION DE IT (SP_Shipping_ValidateItemDetailID_In_Waybill / wo-waiting-approve)------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			DECLARE @dataWOWaitingApprove NVARCHAR(MAX) = (
				SELECT [Waybills] = (
					SELECT DISTINCT [Waybill]
					FROM #FINALTABLE
					FOR JSON PATH
				)
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
			)

			DROP TABLE IF EXISTS #TB_WOWaitingApproveResult
			CREATE TABLE #TB_WOWaitingApproveResult ([Result] NVARCHAR(MAX))

			INSERT INTO #TB_WOWaitingApproveResult ([Result])
			EXEC [dbo].[SP_Shipping_ValidateItemDetailID_In_Waybill] @process = 'wo-waiting-approve', @data = @dataWOWaitingApprove

			DECLARE @resultWOWaitingApprove NVARCHAR(MAX)
			SELECT @resultWOWaitingApprove = [Result] FROM #TB_WOWaitingApproveResult

			DROP TABLE IF EXISTS #TB_WOWaitingApprove
			SELECT
				 [Waybill]
				,[ItemDetailID]
				,[MO]
				,[Style]
				,[Color]
				,[CommentError]
			INTO #TB_WOWaitingApprove
			FROM OPENJSON(@resultWOWaitingApprove)
			WITH (
				 [Waybill]       VARCHAR(100)
				,[ItemDetailID]  INT
				,[MO]            VARCHAR(100)
				,[Style]         VARCHAR(100)
				,[Color]         VARCHAR(100)
				,[CommentError]  VARCHAR(500)
			)

			-- Nota: Check Prices no maneja Size, por eso el match es por Waybill/ItemDetailID/MO/Style/Color
			UPDATE F SET
				 [Rev_Comments] = TV.[CommentError]
				,[Rev_Final]    = 1
			FROM #FINALTABLE AS F
			INNER JOIN #TB_WOWaitingApprove AS TV
				ON F.[Waybill]      = TV.[Waybill]
			   AND F.[ItemDetailID] = TV.[ItemDetailID]
			   AND F.[MO]           = TV.[MO]
			   AND F.[Style]        = TV.[Style]
			   AND F.[Color]        = TV.[Color]
			WHERE TV.[CommentError] IS NOT NULL
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



	    DECLARE @MESSAGE2 VARCHAR(MAX) = CONCAT('Datos obtenidos correctamente. Version: ',@versionCheckPrices)

	   IF @error = 0 AND @updatePrices = 1
		BEGIN
		    
		    IF @error = 0
			AND EXISTS (
			    SELECT 1
			    FROM #FINALTABLE
			    WHERE COALESCE([Rev_Final],0) = 1
			)
			BEGIN
			    SET @error = 1
			    SET @message = 'Existen errores de validación (Rev_Final = 1).'
			    GOTO EndProcedureCheckPrices
			END
		
		    BEGIN TRY
		        BEGIN TRANSACTION
		
		            DROP TABLE IF EXISTS #TB_Map_Master
		
		            CREATE TABLE #TB_Map_Master
		            (
		                 [Waybill]   VARCHAR(200)
		                ,[MasterID]  INT
		            )
		
		            -- UPDATE existentes
		            UPDATE M SET
		                 [codeUser]     = @userCode
		                ,[payload]      = @data
		                ,[updated_at]   = GETDATE()
		            OUTPUT
		                 inserted.[waybill]
		                ,inserted.[id]
		            INTO #TB_Map_Master
		            FROM [AppsLCA].[dbo].[TB_ShipmentCheckPrices] AS M
		            INNER JOIN #TB_ParametersJOIN AS W
		                ON W.Waybill = M.waybill
		
		            -- INSERT nuevos
		            INSERT INTO [AppsLCA].[dbo].[TB_ShipmentCheckPrices]
		            (
		                 [waybill]
		                ,[codeUser]
		                ,[ShipDate]
		                ,[payload]
		                ,[versionCheckPrices]
		                ,[status]
		                ,[created_at]
		            )
		            OUTPUT
		                 inserted.[waybill]
		                ,inserted.[id]
		            INTO #TB_Map_Master
		            SELECT
		                 W.Waybill
		                ,@userCode
		                ,W.ShipDate
		                ,@data
		                ,@versionCheckPrices
		                ,1
		                ,GETDATE()
		            FROM #TB_ParametersJOIN AS W
		            WHERE NOT EXISTS (
		                SELECT 1
		                FROM [AppsLCA].[dbo].[TB_ShipmentCheckPrices] M
		                WHERE M.waybill = W.Waybill
		            )
		
		            DELETE D
		            FROM [AppsLCA].[dbo].[TB_ShipmentCheckPricesDetail] AS D
		            INNER JOIN #TB_Map_Master AS M
		                ON M.MasterID = D.shipmentCheckPrices_id
		
		
		
		-----------
	
		            INSERT INTO [AppsLCA].[dbo].[TB_ShipmentCheckPricesDetail]
					(
					     [shipmentCheckPrices_id]
					    ,[RowData]
					    ,[Waybill]
					    ,[Rev_Final]
					    ,[Rev_Comments]
					    ,[ManufactureID]
					    ,[MO]
					    ,[OrderID]
					    ,[PONumber]
					    
					    ,[OrderIDExport]  
						,[PONumberExport] 
					    
					    ,[OrderItemID]
					    
					    ,[ShipTo]
					    ,[PuertoDestino]
					    ,[TypeDestination]
					    
					    ,[TotalUnitsExport]
					    ,[BasePrice]
					    ,[TotalPrintValue]
					    ,[UnitPrice]
					    
					    ,[TotalBlank]
					    ,[OutboundFreight]
					    ,[TotalDecoration]
					    
					    ,[ItemDetailID]
					    ,[StyleID]
					    ,[Style]
					    ,[Color]
					    ,[Season]
					    ,[BlankStyleID]
					    ,[BlankStyle]
					    ,[StyleDivision]
					    ,[TariffCategory]
					    ,[InvoicingDescription]
					    ,[StyleOptionID]
					    ,[StyleOption]
					    ,[Code]
					    ,[OrderType2]
					    ,[PrintCount]
					    ,[LCABasePrice]
					    ,[PurchaseBasePrice]
					    ,[PurchaseFreightPrice]
					    ,[SublimationBasePrice]
					    ,[CodePrice_EmbroideryApp]
					    ,[CodePrice_EmbroideryHW]
					    ,[PigmentDyeBasePrice]
					    ,[ScreenPrint]
					    ,[Sublimation]
					    ,[EmbroideryAPP]
					    ,[EmbroideryHW]
					    ,[Relabel]
					    ,[SubApplication]
					    ,[HDP]
					    ,[SpecialPK]
					    ,[PigmentDye]
					    ,[Samples]
					    -- ,[SNApplication]
					    ,[BlankLCA]
					    ,[BlankSemiApp]
					    ,[BlankSemiHW]
					    
					    ,[InlandFreight]
					    ,[AirFreight]
					    ,[OceanFreight]
					    
					    ,[UnitPrice_ScreenPrint]
					    ,[UnitPrice_Sublimation]
					    ,[UnitPrice_EmbroideryApp]
					    ,[UnitPrice_EmbroideryHW]
					    ,[UnitPrice_Relabel]
					    ,[UnitPrice_SubApplication]
					    ,[UnitPrice_HDP]
					    ,[UnitPrice_SpecialPK]
					    ,[UnitPrice_PigmentDye]
					    ,[UnitPrice_Samples]
					    -- ,[UnitPrice_SNApplication]
					    ,[UnitPrice_BlankLCA]
					    ,[UnitPrice_BlankSemiApp]
					    ,[UnitPrice_BlankSemiHW]
					    
					    ,[ManualDecoPrice]
					    ,[Price_ScreenPrint]
					    ,[Price_Sublimation]
					    ,[Price_EmbroideryApp]
					    ,[Price_EmbroideryHW]
					    ,[Price_Relabel]
					    ,[Price_SubApplication]
					    ,[Price_HDP]
					    ,[Price_SpecialPK]
					    ,[Price_PigmentDye]
					    
					    ,[ManualBlankPrice]
					    ,[Price_Samples]
					    -- ,[Price_SNApplication]
					    ,[Price_BlankLCA]
					    ,[Price_BlankSemiApp]
					    ,[Price_BlankSemiHW]
					    
					    ,[Price_InlandFreight]
					    ,[Price_AirFreight]
					    ,[Price_OceanFreight]
					    
					    ,[Formula_ScreenPrint]
					    ,[Formula_Sublimation]
					    ,[Formula_EmbroideryApp]
					    ,[Formula_EmbroideryHW]
					    ,[Formula_Relabel]
					    ,[Formula_SubApplication]
					    ,[Formula_HDP]
					    ,[Formula_SpecialPK]
					    ,[Formula_PigmentDye]
					    ,[Formula_Samples]
					    -- ,[Formula_SNApplication]
					    ,[Formula_BlankLCA]
					    ,[Formula_BlankSemiApp]
					    ,[Formula_BlankSemiHW]
					    
					    ,[Formula_InlandFreight]
					    ,[Formula_AirFreight]
					    ,[Formula_OceanFreight]
					    ,[Formula_OutboundFreight]
					    
					    ,[Formula_TotalBlank]
					    ,[Formula_TotalDecoration]
					)
					SELECT
					     M.MasterID
					    ,F.[RowData]
					    ,F.[Waybill]
					    ,F.[Rev_Final]
					    ,F.[Rev_Comments]
					    ,F.[ManufactureID]
					    ,F.[MO]
					    ,F.[OrderID]
					    ,F.[PONumber]
					    
					    ,F.[OrderIDExport]  
						,F.[PONumberExport] 
						
					    ,F.[OrderItemID]
					    
					    ,F.[ShipTo]
					    ,F.[PuertoDestino]
					    ,F.[TypeDestination]
					    
					    ,F.[TotalUnitsExport]
					    ,F.[BasePrice]
					    ,F.[TotalPrintValue]
					    ,F.[UnitPrice]
					    
					    ,F.[TotalBlank]
					    ,F.[OutboundFreight]
					    ,F.[TotalDecoration]
					    
					    ,F.[ItemDetailID]
					    ,F.[StyleID]
					    ,F.[Style]
					    ,F.[Color]
					    ,F.[Season]
					    ,F.[BlankStyleID]
					    ,F.[BlankStyle]
					    ,F.[StyleDivision]
					    ,F.[TariffCategory]
					    ,F.[InvoicingDescription]
					    ,F.[StyleOptionID]
					    ,F.[StyleOption]
					    ,F.[Code]
					    ,F.[OrderType2]
					    ,F.[PrintCount]
					    ,F.[LCABasePrice]
					    ,F.[PurchaseBasePrice]
					    ,F.[PurchaseFreightPrice]
					    ,F.[SublimationBasePrice]
					    ,F.[CodePrice_EmbroideryApp]
					    ,F.[CodePrice_EmbroideryHW]
					    ,F.[PigmentDyeBasePrice]
					    ,F.[ScreenPrint]
					    ,F.[Sublimation]
					    ,F.[EmbroideryAPP]
					    ,F.[EmbroideryHW]
					    ,F.[Relabel]
					    ,F.[SubApplication]
					    ,F.[HDP]
					    ,F.[SpecialPK]
					    ,F.[PigmentDye]
					    ,F.[Samples]
					    -- ,F.[SNApplication]
					    ,F.[BlankLCA]
					    ,F.[BlankSemiApp]
					    ,F.[BlankSemiHW]
					    
					    ,F.[InlandFreight]
					    ,F.[AirFreight]
					    ,F.[OceanFreight]
					    
					    ,F.[UnitPrice_ScreenPrint]
					    ,F.[UnitPrice_Sublimation]
					    ,F.[UnitPrice_EmbroideryApp]
					    ,F.[UnitPrice_EmbroideryHW]
					    ,F.[UnitPrice_Relabel]
					    ,F.[UnitPrice_SubApplication]
					    ,F.[UnitPrice_HDP]
					    ,F.[UnitPrice_SpecialPK]
					    ,F.[UnitPrice_PigmentDye]
					    ,F.[UnitPrice_Samples]
					    -- ,F.[UnitPrice_SNApplication]
					    ,F.[UnitPrice_BlankLCA]
					    ,F.[UnitPrice_BlankSemiApp]
					    ,F.[UnitPrice_BlankSemiHW]
					    
					    ,F.[ManualDecoPrice]
					    ,F.[Price_ScreenPrint]
					    ,F.[Price_Sublimation]
					    ,F.[Price_EmbroideryApp]
					    ,F.[Price_EmbroideryHW]
					    ,F.[Price_Relabel]
					    ,F.[Price_SubApplication]
					    ,F.[Price_HDP]
					    ,F.[Price_SpecialPK]
					    ,F.[Price_PigmentDye]
					    
					    ,F.[ManualBlankPrice]
					    ,F.[Price_Samples]
					    -- ,F.[Price_SNApplication]
					    ,F.[Price_BlankLCA]
					    ,F.[Price_BlankSemiApp]
					    ,F.[Price_BlankSemiHW]
					    
					    ,F.[Price_InlandFreight]
						,F.[Price_AirFreight]
						,F.[Price_OceanFreight]
					    
					    ,F.[Formula_ScreenPrint]
					    ,F.[Formula_Sublimation]
					    ,F.[Formula_EmbroideryApp]
					    ,F.[Formula_EmbroideryHW]
					    ,F.[Formula_Relabel]
					    ,F.[Formula_SubApplication]
					    ,F.[Formula_HDP]
					    ,F.[Formula_SpecialPK]
					    ,F.[Formula_PigmentDye]
					    ,F.[Formula_Samples]
					    -- ,F.[Formula_SNApplication]
					    ,F.[Formula_BlankLCA]
					    ,F.[Formula_BlankSemiApp]
					    ,F.[Formula_BlankSemiHW]
					    
					    ,F.[Formula_InlandFreight]
					    ,F.[Formula_AirFreight]
					    ,F.[Formula_OceanFreight]
					    ,F.[Formula_OutboundFreight]
					    
					    ,F.[Formula_TotalBlank]
					    ,F.[Formula_TotalDecoration]
					FROM #FINALTABLE AS F
					INNER JOIN #TB_Map_Master AS M
					    ON M.[Waybill] = F.[Waybill]

					
					-------- UPDATE LCA.dbo.OrderItems (precios finales)
					UPDATE OI SET
					     OI.UnitPrice         = CAST(F.TotalBlank + F.OutboundFreight + F.TotalDecoration  AS DECIMAL(18,2))
					    ,OI.PricingUnitCost2  = CAST(F.TotalBlank + F.OutboundFreight                      AS DECIMAL(18,2))
					    ,OI.PricingUnitCost   = CAST(F.TotalDecoration                                     AS DECIMAL(18,2))
					FROM LCA.dbo.OrderItems AS OI WITH(ROWLOCK)
					INNER JOIN #FINALTABLE AS F
					    ON F.OrderItemID = OI.OrderItemID
					WHERE F.FilterMOExport = 1 AND F.Waybill IS NOT NULL AND F.IsManualPrice = 0


		        COMMIT TRANSACTION
		
		        SET @error = 0
		        SET @MESSAGE2 = CONCAT('Proceso ejecutado correctamente.',' Version: ',@versionCheckPrices, ' User: ',@userCode)
		    END TRY
		    BEGIN CATCH
		        IF XACT_STATE() <> 0
		            ROLLBACK TRANSACTION
		
		        SET @error = 1
		        SET @message = CONCAT('Error al actualizar precios: ', LEFT(ERROR_MESSAGE(), 200))
		        SET @result = '[]'
		
		        GOTO EndProcedureCheckPrices
		    END CATCH
		END






					    -- 	SELECT * FROM #FINALTABLE
					    -- 	where ponumber like 'PO%'
					    -- 	AND REV_Final = 1
						-- RETURN

			 		SET @result =
                			 		 (
                						 SELECT
                							(
                                        		SELECT
                                            		 [Total]             = CAST(SUM(ROUND(S.[TotalUnitsExport] * 
                                            		                                                  (       ISNULL(S.[TotalBlank]        ,0.00) 
                                            		                                                      +   ISNULL(S.[OutboundFreight]   ,0.00) 
                                            		                                                      +   ISNULL(S.[TotalDecoration]   ,0.00) 
                                            		                                                ),2))    AS DECIMAL(18,2))
													,[TotalUnits]        = SUM(S.[TotalUnitsExport])
                                            		,[BlankLCA]          = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_BlankLCA]        ,0.00),2))    AS DECIMAL(18,2))
                                            		,[BlankSemiApp]      = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_BlankSemiApp]    ,0.00),2))    AS DECIMAL(18,2))
                                            		,[BlankSemiHW]       = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_BlankSemiHW]     ,0.00),2))    AS DECIMAL(18,2))
                                            		,[Samples]           = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_Samples]         ,0.00),2))    AS DECIMAL(18,2))
                                            		
                                            		,[InlandFreight]     = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_InlandFreight]   ,0.00),2))    AS DECIMAL(18,2))
                                            		,[AirFreight]        = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_AirFreight]      ,0.00),2))    AS DECIMAL(18,2))
                                            		,[OceanFreight]      = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_OceanFreight]    ,0.00),2))    AS DECIMAL(18,2))
                                            		-- ,[SNApplication]     = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_SNApplication]   ,0.00),2))    AS DECIMAL(18,2))
                                            		,[ScreenPrint]       = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_ScreenPrint]     ,0.00),2))    AS DECIMAL(18,2))
                                            		,[Sublimation]       = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_Sublimation]     ,0.00),2))    AS DECIMAL(18,2))
                                            		,[EmbroideryAPP]     = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_EmbroideryApp]   ,0.00),2))    AS DECIMAL(18,2))
                                            		,[EmbroideryHW]      = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_EmbroideryHW]    ,0.00),2))    AS DECIMAL(18,2))
                                            		,[Relabel]           = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_Relabel]         ,0.00),2))    AS DECIMAL(18,2))
                                            		,[SubApplication]    = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_SubApplication]  ,0.00),2))    AS DECIMAL(18,2))
                                            		,[HDP]               = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_HDP]             ,0.00),2))    AS DECIMAL(18,2))
                                            		,[SpecialPK]         = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_SpecialPK]       ,0.00),2))    AS DECIMAL(18,2))
                                            		,[PigmentDye]        = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[Price_PigmentDye]      ,0.00),2))    AS DECIMAL(18,2))
                                            		,[ManualBlankPrice]  = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[ManualBlankPrice]      ,0.00),2))    AS DECIMAL(18,2))
                                            		,[ManualDecoPrice]   = CAST(SUM(ROUND(S.[TotalUnitsExport] * ISNULL(S.[ManualDecoPrice]       ,0.00),2))    AS DECIMAL(18,2))
                                            		,[Rev_Final]         = CAST(SUM(S.[Rev_Final]                                                          )    AS INT          )
                                        	    FROM #FINALTABLE AS S
                								FOR JSON PATH, INCLUDE_NULL_VALUES
                							) AS DataKPI
                							,(
                								SELECT 
                                                    [RowData]
                                        			,[Waybill]
                                        			,[Rev_Final]
                                        			,[Rev_Comments]
                                        			,[ManufactureID]
                                        			,[MO]
                                        			,[OrderID]
                                        			,[PONumber]
                                        			,[OrderIDExport]  
													,[PONumberExport] 
                                        			,[OrderItemID]
                                        			,[ShipTo]
												    ,[PuertoDestino]
												    ,[TypeDestination]
                                        			,[TotalUnitsExport]
                                        			,[BasePrice]
                                        			,[TotalPrintValue]
                                        			,[UnitPrice]
                                        			,[TotalBlank]
                                        			,[OutboundFreight]
                                        			,[TotalDecoration]
                                        			,[ItemDetailID]
                                        			,[StyleID]
                                        			,[Style]
                                        			,[Color]
                                        			,[Season]
                                        			,[BlankStyleID]
                                                    ,[BlankStyle]  
                                        			,[StyleDivision]
                                        			,[TariffCategory]
                                        			,[InvoicingDescription]
                                        			,[StyleOptionID]
                                        			,[StyleOption]
                                        			,[Code]
                                        			,[OrderType2]
                                                    ,[PrintCount]
                                        			,[LCABasePrice]		
                                        			,[PurchaseBasePrice]
                                        			,[PurchaseFreightPrice]
                                        			,[SublimationBasePrice]
                                        			,[CodePrice_EmbroideryApp] 
                                        			,[CodePrice_EmbroideryHW] 
                                        			,[PigmentDyeBasePrice]
                                        			,[ScreenPrint]
                                        			,[Sublimation]
                                        			,[EmbroideryAPP]
                                        			,[EmbroideryHW]
                                        			,[Relabel]
                                        			,[SubApplication]
                                        			,[HDP]
                                        			,[SpecialPK]
                                        			,[PigmentDye]
                                        			,[Samples]
                                        			-- ,[SNApplication]
                                        			,[BlankLCA]
                                        			,[BlankSemiApp]
                                        			,[BlankSemiHW]
                                        			
                                        			,[InlandFreight]
												    ,[AirFreight]
												    ,[OceanFreight]
					    
                                        			,[UnitPrice_ScreenPrint]
                                        			,[UnitPrice_Sublimation]
                                        			,[UnitPrice_EmbroideryApp]
                                        			,[UnitPrice_EmbroideryHW]
                                        			,[UnitPrice_Relabel]
                                        			,[UnitPrice_SubApplication]
                                        			,[UnitPrice_HDP]
                                        			,[UnitPrice_SpecialPK]
                                        			,[UnitPrice_PigmentDye]
                                        			,[UnitPrice_Samples]
                                        			-- ,[UnitPrice_SNApplication]
                                        			,[UnitPrice_BlankLCA]
                                        			,[UnitPrice_BlankSemiApp]
                                        			,[UnitPrice_BlankSemiHW]
                                        			
                                        			,[ManualDecoPrice]
                                        			,[Price_ScreenPrint]
                                        			,[Price_Sublimation]
                                        			,[Price_EmbroideryApp]
                                        			,[Price_EmbroideryHW]
                                        			,[Price_Relabel]
                                        			,[Price_SubApplication]
                                        			,[Price_HDP]
                                        			,[Price_SpecialPK]
                                        			,[Price_PigmentDye]
                                        			
                                        			,[ManualBlankPrice]
                                        			,[Price_Samples]
                                        			-- ,[Price_SNApplication]
                                        			,[Price_BlankLCA]
                                        			,[Price_BlankSemiApp]
                                        			,[Price_BlankSemiHW]
                                        			
                                        			,[Price_InlandFreight]
												    ,[Price_AirFreight]
												    ,[Price_OceanFreight]
												    
                                        			-- ,[Rev_ScreenPrint]
                                        			-- ,[Rev_Sublimation]
                                        			-- ,[Rev_EmbroideryApp]
                                        			-- ,[Rev_EmbroideryHW]
                                        			-- ,[Rev_Relabel]
                                        			-- ,[Rev_SubApplication]
                                        			-- ,[Rev_HDP]
                                        			-- ,[Rev_SpecialPK]
                                        			-- ,[Rev_PigmentDye]
                                        			-- ,[Rev_BlankLCA]
                                        			-- ,[Rev_BlankSemiApp]
                                        			-- ,[Rev_BlankSemiHW]
                                        			-- ,[Rev_InvoicingDescription]
                                        			-- ,[Rev_OrderType]            
                                                    -- ,[Rev_DecorationWorkflow]   
                                                    -- ,[Rev_TariffCategory]       
                                        			,[Formula_ScreenPrint]     
                                        			,[Formula_Sublimation]     
                                        			,[Formula_EmbroideryApp]   
                                        			,[Formula_EmbroideryHW]    
                                        			,[Formula_Relabel]         
                                        			,[Formula_SubApplication]  
                                        			,[Formula_HDP]             
                                        			,[Formula_SpecialPK]       
                                        			,[Formula_PigmentDye]      
                                        			,[Formula_Samples]      
                                        			-- ,[Formula_SNApplication]      
                                        			,[Formula_BlankLCA]        
                                        			,[Formula_BlankSemiApp]    
                                        			,[Formula_BlankSemiHW]  
                                        			
                                        			,[Formula_InlandFreight]
												    ,[Formula_AirFreight]
												    ,[Formula_OceanFreight]
												    ,[Formula_OutboundFreight]
					    
                                        			,[Formula_TotalBlank]      
                                        			,[Formula_TotalDecoration] 
                                                FROM #FINALTABLE
                                           
                                                ORDER BY [RowData]
                			 					FOR JSON PATH, INCLUDE_NULL_VALUES
                							) AS DataDetail
                							
                						FOR JSON PATH, INCLUDE_NULL_VALUES
                								
                                        )
                        
	                    
	                         

    		 		SET @error		= 0
    		 		-- SET @message	= 'Datos obtenidos correctamente.'
    		 		SET @message	= @MESSAGE2
			
	
				
				
		END
		-- ----------------------------------------------------------------------------------------------------
		-- ---------------------------amazon.update------------------------------------------------
		-- ----------------------------------------------------------------------------------------------------


   END TRY
   BEGIN CATCH
       -- Manejo de errores
       SET @message = CONCAT( 'Error in Database. Please contact IT.',' version',@versionCheckPrices,' ',CHAR(10),LEFT(ERROR_MESSAGE(), 200))
       SET @error = 1
       SET @result = '[]' 
   END CATCH
	
EndProcedureCheckPrices:

    -- set @error = 1
    -- set @message = 'PRUEBA'
    -- set @result = '[]' 
    
	SET @otherData =  (SELECT 
							 [Error]	         = @error
							,[message]	         = @message
							,[messageData]	     = JSON_QUERY(COALESCE(@messageData, '[]'))
							,[Result]	         = JSON_QUERY(@result)
					   FOR JSON PATH ,INCLUDE_NULL_VALUES --, WITHOUT_ARRAY_WRAPPER
   )
--    @messageData
   -- Devolver JSON unificado
   
	IF @NoSelect =0 
        SELECT @otherData 
		 

END




						
					
