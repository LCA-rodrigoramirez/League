USE AppsLCA;
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_ImportExport_CertificateOfOrigin]
(
    @data AS NVARCHAR(MAX)
)
AS
BEGIN
    SET NOCOUNT ON;    
    -- DECLARE @data AS NVARCHAR(MAX)
    -- SET @data	= '{"selectedOptions":[{"Waybill":"AIR-APP-20260415"},{"Waybill":"AIR-HW-20260415"},{"Waybill":"AIR-SMS-20260415"}]}'
    DECLARE @Component AS NVARCHAR(200)
    DECLARE @Error AS BIT
    DECLARE @message AS NVARCHAR(200)
    DECLARE @resultDetails AS NVARCHAR(MAX)
    DECLARE @resultHeader  AS NVARCHAR(MAX)
    DECLARE @ShipDate      AS DATE

    BEGIN TRY

        DECLARE @listWaybill	AS NVARCHAR(MAX)
        SET @listWaybill	    = (SELECT JSON_QUERY(@data, '$.selectedOptions'))

        DROP TABLE IF EXISTS #TB_Data_COO
        DROP TABLE IF EXISTS #TB_COO
        DROP TABLE IF EXISTS #TB_DATA_JSON_WAYBILL
        
        SELECT 
            [R]                = ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
            ,[Waybill]	        = STJ.[Waybill]
        INTO #TB_DATA_JSON_WAYBILL
        FROM OPENJSON(@listWaybill)
        WITH (	 
                [Waybill]		VARCHAR(200)
            ) AS STJ

        SELECT
            [Waybill]                  = SUBSTRING(SBA.[Waybill], PATINDEX('%[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]%', SBA.[Waybill]), 8)
            ,[Container_Tracking]       = (SELECT [dbo].[cleanString](SC.[Invoice8]))
            ,[StyleNumber]              = SBA.[StyleNumber]
            ,[CA_HTSDescription]        = SBA.[CA_HTSDescription]
            ,[US_HTSDescription]        = SBA.[US_HTSDescription]
            ,[US_HTSCode]               = SUBSTRING(SBA.[US_HTSCode],1,6)
            ,[Preferential_Treatment]   = 'GN29 "(b)(i)" CAFTA'
            ,[Other_Criteria]           = 'N/A'
            ,[Productor]                = 'YES'
            ,[TariffCategory]           = SBA.[Cafta]
            -- ,SUM(SBA.Quantity)
            ,[ShipDate]                 = CAST(SBA.[ShipDate] AS DATE)
            ,[DateFrom_Day]             = DATEPART(DAY,CAST(SBA.[ShipDate] AS DATE))
            ,[DateFrom_Month]           = DATEPART(MONTH,CAST(SBA.[ShipDate] AS DATE))
            ,[DateFrom_Year]            = DATEPART(YEAR,CAST(SBA.[ShipDate] AS DATE))
            ,[DateTo_Day]               = DATEPART(DAY,DATEFROMPARTS(YEAR(GETDATE()), 12, 31))
            ,[DateTo_Month]             = DATEPART(MONTH,DATEFROMPARTS(YEAR(GETDATE()), 12, 31))
            ,[DateTo_Year]              = DATEPART(YEAR,DATEFROMPARTS(YEAR(GETDATE()), 12, 31))
        INTO #TB_Data_COO
        FROM #TB_DATA_JSON_WAYBILL AS JSW
        INNER JOIN [192.168.1.93].[AppsLCA].[dbo].[CI_import_export_CommercialInvoice] AS SBA WITH(NOLOCK) ON JSW.[Waybill] = SBA.[WayBill]
        INNER JOIN (SELECT DISTINCT Waybill, ShippingContainerID FROM [dbo].[ImportExport_ShipmentBoxAll]  AS SBA  WITH(NOLOCK)) AS SBS ON SBA.[Waybill] = SBS.[WayBill]
        INNER JOIN [LCA].[dbo].[ShippingContainers]     AS SC   WITH(NOLOCK) ON SBS.[ShippingContainerID] = SC.[ShippingContainerID]
        WHERE Cafta = 'Y'
        GROUP BY
            SBA.[WayBill]
            ,SC.[Invoice8]
            ,SBA.[StyleNumber]
            ,SBA.[CA_HTSDescription]
            ,SBA.[US_HTSDescription]
            ,SBA.[US_HTSCode]
            ,SBA.[Cafta]
            ,SBA.[ShipDate]


        -- Validación: el Container debe tener un único ShipDate
        IF (SELECT COUNT(DISTINCT ShipDate) FROM #TB_Data_COO) > 1
        BEGIN
            SET @Error = 1
            SET @Component = '[400]'
            SET @message = 'El container tiene más de un ShipDate, no es posible generar el certificado'
            GOTO SELECTFINAL
        END

        SELECT
            [Waybill]               
            ,[Container_Tracking]    
            ,[CA_HTSDescription]     
            ,[US_HTSDescription]     
            ,[US_HTSCode]            
            ,[Preferential_Treatment]
            ,[Other_Criteria]        
            ,[Productor]             
            ,[TariffCategory]        
            ,[StyleForDescription]      = STRING_AGG([StyleNumber],',') WITHIN GROUP(ORDER BY [StyleNumber])
            ,[CA_Description]           = CAST(NULL AS VARCHAR(200))
            ,[US_Description]           = CAST(NULL AS VARCHAR(200))
            ,[DateFrom_Day]  
            ,[DateFrom_Month]
            ,[DateFrom_Year] 
            ,[DateTo_Day]    
            ,[DateTo_Month]  
            ,[DateTo_Year]   
            
        INTO #TB_COO
        FROM #TB_Data_COO
        GROUP BY
            [Waybill]               
            ,[Container_Tracking]    
            ,[CA_HTSDescription]     
            ,[US_HTSDescription]     
            ,[US_HTSCode]            
            ,[Preferential_Treatment]
            ,[Other_Criteria]        
            ,[Productor]             
            ,[TariffCategory]
            ,[DateFrom_Day]  
            ,[DateFrom_Month]
            ,[DateFrom_Year] 
            ,[DateTo_Day]    
            ,[DateTo_Month]  
            ,[DateTo_Year]

        UPDATE TB SET
             [CA_Description] = CONCAT(CA_HTSDescription, ' / ')
            ,[US_Description] = CONCAT(US_HTSDescription , ' No: ' ,StyleForDescription)
        FROM #TB_COO AS TB

        SET @resultDetails = (
                                SELECT
                                     [CA_Description]
                                    ,[US_Description]
                                    ,[US_HTSCode]
                                    ,[Preferential_Treatment]
                                    ,[Other_Criteria]
                                    ,[Productor]
                                FROM #TB_COO
                                FOR JSON PATH, INCLUDE_NULL_VALUES
                            )
        
        SET @resultHeader = (
                                SELECT DISTINCT
                                     [Waybill]
                                    ,[Container_Tracking]
                                    ,[DateFrom_Day]  
                                    ,[DateFrom_Month]
                                    ,[DateFrom_Year] 
                                    ,[DateTo_Day]    
                                    ,[DateTo_Month]  
                                    ,[DateTo_Year]
                                FROM #TB_COO
                                FOR JSON PATH, INCLUDE_NULL_VALUES
                            )


        SET @Error = 0
        SET @Component = '[200]'
        SET @message = 'Datos generados correctamente'

    END TRY
    BEGIN CATCH
        SET @Error = 1
        SET @resultDetails = '[]'
        SET @resultHeader = '[]'
        SET @Component = '[200]'
        SET @message = 'Datos generados correctamente'
    END CATCH

    SELECTFINAL:

    SELECT
        [Error]             = @Error
        ,[Component]        = @Component
        ,[Message]          = @message
        ,[DocumentBody]     = @resultDetails
        ,[DocumentHeader]   = @resultHeader
    FOR JSON PATH, INCLUDE_NULL_VALUES

END

-- INSERT INTO [dbo].[ImportExport_CertificateOfOrigin_Header]
-- (
--      [ReportTitle_Spanish]
--     ,[ReportTitle_English]
--     ,[ExporterName]
--     ,[BP_DateFrom]
--     ,[BP_DateTo]
--     ,[ProducerName]
--     ,[ImporterName]
--     ,[DescriptionHeader]
--     ,[HTSHeader]
--     ,[PreferentialHeader]
--     ,[OtherCriteriaHeader]
--     ,[ProducerHeader]
-- )
-- VALUES
-- (
--     -- ReportTitle_Spanish
--     'Tratado de Libre Comercio entre Centroamérica, República' + CHAR(13)+CHAR(10) +  'Dominicana y los Estados Unidos' + CHAR(13)+CHAR(10) +
--     'CERTIFICADO DE ORIGEN',

--     -- ReportTitle_English
--     'Central America-Dominican Republic-United States Free Trade Agreement' + CHAR(13)+CHAR(10) +
--     'CERTIFICATE OF ORIGIN',

--     -- ExporterName
--     '1. Exporter''s name, address and tax identification number:' + CHAR(13)+CHAR(10) +
--     'Nombre dirección y número de registro fiscal del exportador:' + CHAR(13)+CHAR(10) +
--     'LEAGUE C.A. LTDA. DE C.V.' + CHAR(13)+CHAR(10) +
--     'KM. 36 CARRETERA A SANTA ANA, ZONA FRANCA' + CHAR(13)+CHAR(10) +
--     'AMERICAN PARK, CIUDAD ARCE, LA LIBERTAD.' + CHAR(13)+CHAR(10) +
--     'NIT:0614-130209-105-0',

--     -- BP_DateFrom (referencia dinámica)
--     'SBA.ShipDate',

--     -- BP_DateTo (referencia dinámica)
--     'DATEFROMPARTS(YEAR(GETDATE()), 12, 31)',

--     -- ProducerName
--     '3. Producer''s name address and tax identification number:' + CHAR(13)+CHAR(10) +
--     'Nombre, dirección, y número de registro fiscal del productor:' + CHAR(13)+CHAR(10) +
--     'IGUAL/SAME',

--     -- ImporterName
--     '4. Importer''s name, address and tax identification number:' + CHAR(13)+CHAR(10) +
--     'Nombre, dirección y número de registro fiscal del importador:' + CHAR(13)+CHAR(10) +
--     'L2 BRANDS, LLC' + CHAR(13)+CHAR(10) +
--     '300 FAME AVENUE,' + CHAR(13)+CHAR(10) +
--     '17331 HANOVER PENNSYLVANIA, USA',

--     -- DescriptionHeader
--     '5 Description of good(s) - Descripción de la(s) mercancía(s)',

--     -- HTSHeader
--     '6 HS tariff Classification' + CHAR(13)+CHAR(10) +
--     'Clasificación arancelaria',

--     -- PreferentialHeader
--     '7 Preferential tariff treatment criteria' + CHAR(13)+CHAR(10) +
--     'Criterio para trato arancelario preferencial',

--     -- OtherCriteriaHeader
--     '8. Other criteria' + CHAR(13)+CHAR(10) +
--     'Otros Criterios',

--     -- ProducerHeader
--     '9 Producer' + CHAR(13)+CHAR(10) +
--     'Productor'
-- );
