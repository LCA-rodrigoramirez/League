SELECT DISTINCT
	DC.DesignNo
FROM AppsLCA.legacycaps.VW_view_LCA_DesignColors AS DC WITH(NOLOCK)
INNER JOIN
(
	SELECT DISTINCT
		ItemDetailID	= CASE
							WHEN OE.ItemDetailID IS NOT NULL THEN OE.ItemDetailID
							WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
								NULL
							WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
								cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT)
							ELSE
								NULL
							END
	FROM (SELECT StatusID FROM [192.168.1.53].LCA.dbo.StatusNames sn with (nolock) WHERE StatusID in (40,20)) AS SN
	INNER JOIN
	[192.168.1.53].LCA.dbo.ManufactureOrders mo WITH (NOLOCK)
	ON SN.StatusID = MO.StatusID
	INNER JOIN
	[192.168.1.53].LCA.dbo.Orders od with (nolock)
	ON OD.OrderID = mo.OrderID
	LEFT JOIN 
	[192.168.1.53].[AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export] AS OE WITH(NOLOCK)
	ON 'ORD-' + CAST(OE.ItemDetailID AS varchar) = od.PONumber

) AS OE ON OE.ItemDetailID = DC.ItemDetailID
LEFT JOIN OPENQUERY([MARIADB],'SELECT * FROM wordpress.L2Brands_LogoStyle') AS LG ON DC.LogoStyle = LG.LogoStyle
WHERE LG.OrderTypeDescription = 'To Print (Screen Print Only)'

SELECT DISTINCT
	DC.ItemDetailID
FROM AppsLCA.legacycaps.VW_view_LCA_DesignColors AS DC WITH(NOLOCK)
INNER JOIN
(
	SELECT DISTINCT
		ItemDetailID	= CASE
							WHEN OE.ItemDetailID IS NOT NULL THEN OE.ItemDetailID
							WHEN ( od.[PONumber] LIKE 'ORD-PO%') THEN
								NULL
							WHEN ( od.[PONumber] LIKE 'ORD-%') and ( ISNUMERIC ( REPLACE ( od.[PONumber],'ORD-','') ) = 1)  THEN
								cast(REPLACE ( od.[PONumber],'ORD-','') AS BIGINT)
							ELSE
								NULL
							END
	FROM (SELECT StatusID FROM [192.168.1.53].LCA.dbo.StatusNames sn with (nolock) WHERE StatusID in (40,20)) AS SN
	INNER JOIN
	[192.168.1.53].LCA.dbo.ManufactureOrders mo WITH (NOLOCK)
	ON SN.StatusID = MO.StatusID
	INNER JOIN
	[192.168.1.53].LCA.dbo.Orders od with (nolock)
	ON OD.OrderID = mo.OrderID
	LEFT JOIN 
	[192.168.1.53].[AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export] AS OE WITH(NOLOCK)
	ON 'ORD-' + CAST(OE.ItemDetailID AS varchar) = od.PONumber

) AS OE ON OE.ItemDetailID = DC.ItemDetailID
LEFT JOIN OPENQUERY([MARIADB],'SELECT * FROM wordpress.L2Brands_LogoStyle') AS LG ON DC.LogoStyle = LG.LogoStyle
WHERE LG.OrderTypeDescription = 'To Print (Screen Print Only)'

