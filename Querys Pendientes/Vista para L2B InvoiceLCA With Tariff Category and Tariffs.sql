USE [AppsLCA]
GO

/****** Object:  View [L2Brand].[VW_L2Brands_Units_Invoiced]    Script Date: 03/03/2026 07:30:28 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







ALTER   VIEW [L2Brand].[VW_L2Brands_Units_Invoiced_WithTariffs]
AS
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------VISTA PARA L2B INVOICE LCA-------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	  UIWT.Size
	 ,UIWT.StyleColor
	 ,SUM(UIWT.Quantity) AS Quantity
	 ,UIWT.Style
	 ,UIWT.StyleID
	 ,UIWT.TransactionDate
	 ,UIWT.MO
	 ,UIWT.MO_ID
	 ,UIWT.ItemDetailID
	 ,[Item #]
	 ,UIWT.Blank_InvoicedPrice
	 ,UIWT.CustomerPO
	 ,UIWT.StyleOption
	 ,UIWT.Waybill
	 ,UIWT.TariffCategory
	 ,UIWT.CountryOfOrigin
	 ,UIWT.US_HTSCode
	 ,UIWT.Decoration_Invoiced_Price
	 ,UIWT.Unit_Invoiced_Price
	 ,SUM(UIWT.TotalTariff) AS TotalTariff
	 ,SUM(UIWT.[301China_Tariff]) AS [301China_Tariff]
	 ,SUM(UIWT.Fenta_Tariff) AS Fenta_Tariff
	 ,SUM(UIWT.Recip_Tariff) AS Recip_Tariff
	 ,SUM(UIWT.HTS_Tariff) AS HTS_Tariff
	 ,SUM(UIWT.Tariff122_Tariff) AS Tariff122

FROM [AppsLCA].[legacycaps].[TB_L2Brands_Units_Invoiced_WithTariffs] AS UIWT WITH(NOLOCK)
GROUP BY
	  UIWT.Size
	 ,UIWT.StyleColor
	 ,UIWT.Style
	 ,UIWT.StyleID
	 ,UIWT.TransactionDate
	 ,UIWT.MO
	 ,UIWT.MO_ID
	 ,UIWT.ItemDetailID
	 ,[Item #]
	 ,UIWT.Blank_InvoicedPrice
	 ,UIWT.CustomerPO
	 ,UIWT.StyleOption
	 ,UIWT.Waybill
	 ,UIWT.TariffCategory
	 ,UIWT.CountryOfOrigin
	 ,UIWT.US_HTSCode
	 ,UIWT.Decoration_Invoiced_Price
	 ,UIWT.Unit_Invoiced_Price
     
GO

