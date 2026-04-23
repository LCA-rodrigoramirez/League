USE [LCA]
GO

/****** Object:  View [dboReaders].[VW_ImpExp_OrderSummarySubTotal]    Script Date: 18/03/2026 04:55:45 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




ALTER VIEW [dboReaders].[VW_ImpExp_OrderSummarySubTotal]
AS

WITH CTE_Group as (
	select
			lt.WayBill as WayBill
			,lt.CountryOfOrigin
			,lt.[CA_HTSCode] 
			,lt.CA_HTSDescription as CA_HTSDescription
			,lt.US_HTSDescription as US_HTSDescription
			,lt.StyleNumber
			,sum(lt.[Quantity]) as [Quantity]
			,sum(lt.[SalePrice]) as [SalePrice]
			-- ,sum(lt.BoxesXQty) as BoxesXQty
			,sum(lt.[GroupBoxes]) as BoxesXQty
			,sum(lt.[PalletXQty]) as [PalletXQty]
			,sum(lt.MatPrimaCostTotal)   as MatPrimaCostTotal
			,sum(lt.[ValorAgregado]) as [ValorAgregado]
			,case when lt.StyleNumber is not null then '' else sum(lt.[SalePrice]) end AS Total
			,sum(lt.[GrossWeightKGS]) as [GrossWeightKGS]
			,sum(lt.[NetWeightKGS]) as [NetWeightKGS]
			--,lt.CodigoGeneracion
		from [dboReaders].[VW_ImpExp_OrderSummaryReport_US_HTSDescription] lt with (nolock)
		-- where lt.WayBill = 'APP-20260318'
		group by lt.WayBill,lt.CountryOfOrigin,lt.[CA_HTSCode],lt.CA_HTSDescription,lt.US_HTSDescription,lt.StyleNumber -- ,lt.CodigoGeneracion
)


SELECT TB_Final.* FROM
(
	select DISTINCT
		tb.WayBill
		,tb.CountryOfOrigin
		,case 
			when tb.CA_HTSCode is null 
				then 'TOTAL'
			else  tb.CA_HTSCode
		end AS SAC
		,case 
			when tb.US_Description is null 
				then 'TOTAL'
			when tb.StyleNumber is null 
				then tb.US_Description
			else tb.US_Description 
		end AS US_Descripcion
		,case 
			when tb.Descripcion is null 
				then 'TOTAL' 
			when tb.StyleNumber is null 
				then tb.Descripcion+' SUB TOTAL'
			else tb.Descripcion 
		end AS Descripcion
		,case 
			when tb.Descripcion is null 
				then 'TOTAL' 
			when tb.StyleNumber is null 
				then 'SUB TOTAL'
			else tb.StyleNumber 
		end AS StyleNumber

		  ,tb.[Cantidad]
		  ,tb.[SalePrice]
		  ,tb.[Boxes]
		  ,tb.[Pallet]
		  ,tb.[MatPrimaCostTotal]
		  ,tb.[ValorAgregado]
		  ,tb.[Total]
		  ,tb.[GrossWeightKGS]
		  ,tb.[NetWeightKGS]
		  --,tb.[CodigoGeneracion]

		  ---cambio solicitado por Magda Men�ndez para no mostrar Total por COO
		  ,CASE WHEN (Descripcion IS null or US_Description is null) and CountryOfOrigin is not null THEN 0 ELSE 1 END AS Mostrar

	from(
		select
			lt.WayBill as WayBill
			,lt.CountryOfOrigin
			,lt.[CA_HTSCode] 
			,lt.CA_HTSDescription as Descripcion
			,lt.US_HTSDescription as US_Description
			,lt.StyleNumber
			,sum(lt.[Quantity]) as Cantidad
			,round(sum(lt.[SalePrice]),2) as [SalePrice]
			,round(sum(lt.BoxesXQty),0) as [Boxes]
			,sum(lt.[PalletXQty]) as [Pallet]
			,sum(lt.MatPrimaCostTotal)   as MatPrimaCostTotal
			,sum(lt.[ValorAgregado]) as [ValorAgregado]
			,case when lt.StyleNumber is not null then '' else round(sum(lt.[SalePrice]),2) end AS Total
			,round(sum(lt.[GrossWeightKGS]),2) as [GrossWeightKGS]
			,round(sum(lt.[NetWeightKGS]),2) as [NetWeightKGS]
			--,lt.CodigoGeneracion
		from CTE_Group lt with (nolock)
		--where lt.WayBill = 'APP-20250221-1'
		group by rollup(lt.WayBill,lt.CountryOfOrigin,lt.[CA_HTSCode],lt.CA_HTSDescription,lt.US_HTSDescription,lt.StyleNumber )-- , lt.CodigoGeneracion)
		--group by rollup(lt.WayBill,lt.[CA_HTSCode],lt.CA_HTSDescription ,lt.StyleNumber)
	) as tb

	where
		not (tb.Descripcion is null and tb.US_Description is null and tb.StyleNumber is null and tb.WayBill is not null and tb.CA_HTSCode is not null)
		and not(tb.Descripcion is null and tb.US_Description is null and tb.StyleNumber is null and tb.WayBill is null and tb.CA_HTSCode is null)
) AS TB_Final


	WHERE Mostrar = 1
	
GO


