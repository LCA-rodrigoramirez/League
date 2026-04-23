USE LCA
GO

CREATE OR ALTER VIEW [L2BrandDB].[VW_L2BRands_LCAReconciliation] AS

WITH CTE_SH AS (
	SELECT
		 [P.O.]					= A.PONumber
		,[Style]				= A.StyleNumber
		,[Description]			= CASE
									WHEN A.[StyleNumber] NOT IN ('-','Fabric','Trim','Supplies','SWATCH')
									THEN NULL
									ELSE A.HTSDescription
									END
		,[Base Price]			= A.BasePrice
		,[Emb Price]			= (ISNULL(A.Screen_Print,0) + ISNULL(A.Sublimation,0) + ISNULL(A.Embroidery,0))
		,[Unit Price]			= A.Price
		,[Pcs E]				= A.Qty
		,[Total $]				= A.[Total$]
		,[Invoice Date]			= A.ShipDate
		,[Invoice]				= SH.DM
		,[Container]			= CASE
									WHEN A.[StyleNumber] NOT IN ('-','Fabric','Trim','Supplies','SWATCH')
									THEN A.Container
									ELSE A.Waybill
									END
		,[Direct Materials]		= CASE
									WHEN A.[StyleNumber] NOT IN ('-','Fabric','Trim','Supplies','SWATCH')
										AND A.PONumber NOT LIKE 'SM%'
									THEN A.BasePrice * A.Qty
									ELSE 0 END
		,[Embellishment]		= CASE
									WHEN A.[StyleNumber] NOT IN ('-','Fabric','Trim','Supplies','SWATCH')
										AND A.PONumber NOT LIKE 'SM%'
									THEN (ISNULL(A.Screen_Print,0) + ISNULL(A.Sublimation,0) + ISNULL(A.Embroidery,0)) * A.Qty
									ELSE 0 END
		,[PD]					= CASE
									WHEN A.PONumber LIKE 'SM%'
									THEN A.BasePrice * A.Qty
									ELSE 0 END
		,[Components]			= CASE
									WHEN A.[StyleNumber] IN ('-','Fabric','Trim','Supplies','SWATCH')
									THEN A.BasePrice * A.Qty
									ELSE 0 END
		,[ManufactureID]        = A.[ManufactureID]
	FROM AppsLCA.dbo.ImportExport_AnexoFacturacion AS A WITH(NOLOCK)
	 LEFT JOIN
                (
                    SELECT DISTINCT
                        SH.[WayBill]
                        ,SH.[BookingNumber] AS [DM]
                    FROM [LCA].[dbo].[Shipments] AS SH WITH(NOLOCK)
                ) AS SH ON A.[Waybill] = SH.[WayBill]
	WHERE CAST(A.ShipDate AS DATE) >= CAST(DATEADD(DAY, 1, EOMONTH(GETDATE(), -4)) AS DATE)
)
,CTE_StyleHTS AS (
	SELECT
		[ManufactureID]         = S.[ManufactureID]
		,[US_HTSDescription]    = HTS.[US_HTSDescription]
	FROM (SELECT DISTINCT ManufactureID FROM CTE_SH) AS S
	LEFT JOIN LCA.dbo.ManufactureOrders     AS MO   WITH(NOLOCK) ON MO.ManufactureID = S.ManufactureID
	LEFT JOIN LCA.dbo.OrderItems            AS OI   WITH(NOLOCK) ON OI.OrderItemID = MO.FirstOrderItemID
	LEFT JOIN LCA.dbo.Styles                AS ST   WITH(NOLOCK) ON ST.StyleID = OI.StyleID
	LEFT JOIN LCA.dbo.HTSStyleCodes         AS HTS  WITH(NOLOCK) ON HTS.HTSStyleCodeID = ST.HTSStyleCodeID
)

SELECT
	 [P.O.]
	,[Style]
	,[Description]
	,[Base Price]
	,[Emb Price]
	,[Unit Price]
	,[Pcs E]
	,[Total $]
	,[Invoice Date]
	,[Invoice]
	,[Container]
	,[Direct Materials]
	,[Embellishment]
	,[PD]
	,[Components]
	,[Check]            = ([Total $]) - ([Direct Materials] + [Embellishment] + [PD] + [Components])
FROM (
	SELECT
		 [P.O.]
		,[Style]
		,[Description]			= ISNULL(A.[Description], B.[US_HTSDescription])
		,[Base Price]
		,[Emb Price]
		,[Unit Price]
		,[Pcs E]				= SUM(A.[Pcs E])
		,[Total $]				= SUM(A.[Total $])
		,[Invoice Date]			= MAX([Invoice Date])
		,[Invoice]
		,[Container]
		,[Direct Materials]		= SUM(A.[Direct Materials])
		,[Embellishment]		= SUM(A.[Embellishment])
		,[PD]					= SUM(A.[PD])
		,[Components]			= SUM(A.[Components])
	FROM CTE_SH AS A
	LEFT JOIN CTE_StyleHTS AS B ON B.ManufactureID = A.ManufactureID
	GROUP BY
		 A.[P.O.]
		,A.[Style]
		,ISNULL(A.[Description], B.[US_HTSDescription])
		,A.[Base Price]
		,A.[Emb Price]
		,A.[Unit Price]
		,A.[Invoice Date]
		,A.[Invoice]
		,A.[Container]
) AS TB

GO
