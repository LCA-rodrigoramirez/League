USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_InfoOrdersToPolyPM_Emb_HW]    Script Date: 13/03/2026 12:54:39 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ALTER   PROCEDURE [dbo].[SP_InfoOrdersToPolyPM_Emb_HW]
-- AS
BEGIN
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #ORDERS;
	DROP TABLE IF EXISTS #DIGITIZING;
	DROP TABLE IF EXISTS #APPLIQUE;
	DROP TABLE IF EXISTS #TB_Final;

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
	,OE.Brand
	,mo.ManufactureID
	,od.OrderID
	,od.PONumber
INTO #ORDERS
FROM (SELECT StatusID FROM [192.168.1.53].LCA.dbo.StatusNames sn with (nolock) WHERE StatusID in (40,51,53,55,78,90)) AS SN
	INNER JOIN
	[192.168.1.53].LCA.dbo.ManufactureOrders mo WITH (NOLOCK)
	ON SN.StatusID = MO.StatusID
	INNER JOIN
	[192.168.1.53].LCA.dbo.Orders od with (nolock)
	ON OD.OrderID = mo.OrderID
	LEFT JOIN
	[192.168.1.53].LCA.dbo.OrderItems oi with (nolock)
	ON od.OrderID = oi.OrderID AND mo.FirstOrderItemID = oi.OrderItemID
	INNER JOIN
	[192.168.1.53].LCA.dbo.Styles st with (nolock)
	ON oi.StyleID = st.StyleID and st.Comments9 LIKE '%Headwear%'
	LEFT JOIN 
	[192.168.1.53].[AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export] AS OE WITH(NOLOCK)
	ON 'ORD-' + CAST(OE.ItemDetailID AS varchar) = od.PONumber

SELECT
	 co.ItemDetailID
	,[Location]
	,SequenceNo
	,EmbType
	,SpoolID
INTO #DIGITIZING
FROM #ORDERS AS CO WITH(NOLOCK)
LEFT JOIN AppsLCA.legacycaps.VW_view_LCA_Digitizing VLD WITH (NOLOCK) ON VLD.ItemDetailID = CO.ItemDetailID

SELECT
	VVLA.ItemDetailID
	,VVLA.SKUID
	,VVLA.EmbType
	,VVLA.Location
	,VVLA.DesignItemID
	,VVLA.DesignItemNo
	,VVLA.LogoStyle
	,VVLA.LogoStyleName
	,VVLA.DesignWidthmm
	,VVLA.DesignHeightmm
	,VVLA.DigitizingID
	,VVLA.DigitizingWidthmm
	,DigitizingHeightmm
	,DigitizeDate
	,DigitizedBy
	,StitchCount
	,AppliqueFilename
	,AppliqueMaterial
	,AppliqueColor
INTO #APPLIQUE
FROM #ORDERS AS CO WITH(NOLOCK) 
INNER JOIN AppsLCA.legacycaps.VW_view_LCA_Applique VVLA WITH (NOLOCK) 
ON VVLA.ItemDetailID = CO.ItemDetailID;

SELECT
	 CO.OrderID
	,CO.PONumber
	,VLD.ItemDetailID
	--,VLD2.[Location]
	,VLA.[Location]
	,VLA.Codes
	,VLA.LogoStyleName
	,VLG.LogoStyle
	,VLA.StitchCount
	,VLD2.SequenceNo
	,ISNULL(EL2BPPM.ID_PPM_Location,28) AS OrderTypeID4
	,VLG.OrderTypeID AS OrderTypeID2
	,VLD3.ThreadID
	,VLA.AppliqueColor
	,SKUAtt.SKUAttribute
INTO #TB_Final
	
FROM #DIGITIZING VLD WITH (NOLOCK)

INNER JOIN #ORDERS AS CO WITH(NOLOCK) ON VLD.ItemDetailID = CO.ItemDetailID

LEFT JOIN 
		(SELECT 
			ItemDetailID,
			STRING_AGG([Location], ',') WITHIN GROUP (ORDER BY EmbType) as [Location],
			STRING_AGG(SequenceNo, ',') WITHIN GROUP (ORDER BY EmbType) as SequenceNo 
		FROM
		(
			SELECT DISTINCT 
				ItemDetailID,
				[Location],
				STRING_AGG(SpoolID,',') AS SpoolID,
				EmbType,
				MAX(SequenceNo) as SequenceNo 
			FROM #DIGITIZING WITH (NOLOCK)
			--where ItemDetailID = 4098052
			GROUP BY ItemDetailID,[Location],EmbType
		) VLD
		GROUP BY ItemDetailID) 
		VLD2 ON VLD.ItemDetailID = VLD2.ItemDetailID

LEFT JOIN
		(SELECT 
			ItemDetailID,
			STRING_AGG([Location], ',') WITHIN GROUP (ORDER BY EmbType) as [Location],
			STRING_AGG(SpoolID, ',') WITHIN GROUP (ORDER BY EmbType) as ThreadID 
		FROM
		(
			SELECT DISTINCT 
				ItemDetailID,
				[Location],
				SpoolID,
				EmbType
			FROM #DIGITIZING  WITH (NOLOCK)
			--where ItemDetailID = 4098052
		) VLD
		GROUP BY ItemDetailID) 
		VLD3 ON VLD.ItemDetailID = VLD3.ItemDetailID
		
LEFT JOIN 
		(
		SELECT 
			ItemDetailID, 
			STRING_AGG(StitchCount, ',') WITHIN GROUP (ORDER BY EmbType) AS StitchCount, 
			STRING_AGG([Location], ',') WITHIN GROUP (ORDER BY EmbType) AS [Location],
			STRING_AGG(Code, ',') WITHIN GROUP (ORDER BY EmbType) AS Codes,
			STRING_AGG(LogoStyleName, ',') WITHIN GROUP (ORDER BY EmbType) AS LogoStyleName,
			STRING_AGG(AppliqueColor, ',') WITHIN GROUP (ORDER BY EmbType) AS AppliqueColor
		FROM (
				SELECT DISTINCT
				ItemDetailID,
				[Location],
				COALESCE(StitchCount,0) AS StitchCount,
				EmbType,
				Code,
				LogoStyleName,
				STRING_AGG(AppliqueColor, ',') WITHIN GROUP (ORDER BY EmbType) AS AppliqueColor
			FROM (
				SELECT DISTINCT 
					vvla.ItemDetailID,
					[Location],
					LogoStyleName,
					StitchCount,
					EmbType,
					AppliqueColor,
					CASE 
						WHEN CAST (StitchCount as INT) >= 0 and CAST (StitchCount as INT) <= 2000 
						THEN VVLA.LogoStyle + '2'
						WHEN CAST (StitchCount as INT) >= 2001 and CAST (StitchCount as INT) <= 4000 
						THEN VVLA.LogoStyle + '4'
						WHEN CAST (StitchCount as INT) >= 4001 and CAST (StitchCount as INT) <= 6000 
						THEN VVLA.LogoStyle + '6'
						WHEN CAST (StitchCount as INT) >= 6001 and CAST (StitchCount as INT) <= 8000 
						THEN VVLA.LogoStyle + '8'
						WHEN CAST (StitchCount as INT) >= 8001 and CAST (StitchCount as INT) <= 10000 
						THEN VVLA.LogoStyle + '10'
						WHEN CAST (StitchCount as INT) >= 10001 and CAST (StitchCount as INT) <= 12000 
						THEN VVLA.LogoStyle + '12'
						WHEN CAST (StitchCount as INT) >= 12001 and CAST (StitchCount as INT) <= 14000 
						THEN VVLA.LogoStyle + '14'
						WHEN CAST (StitchCount as INT) >= 14001 and CAST (StitchCount as INT) <= 16000 
						THEN VVLA.LogoStyle + '16'
						WHEN StitchCount IS NULL THEN VVLA.LogoStyle
						ELSE VVLA.LogoStyle + '16'
					END AS Code
				FROM #APPLIQUE VVLA WITH (NOLOCK) 
				--where ItemDetailID IN (4902554)
			)abc
		GROUP BY 
		ItemDetailID,
		[Location],
		StitchCount,
		EmbType,
		Code,
		LogoStyleName
			--WHERE AppliqueMaterial IS NOT NULL
			--AND 

		) tb
		GROUP BY ItemDetailID
		) 
		as VLA ON VLD2.ItemDetailID = VLA.ItemDetailID

		LEFT JOIN
		(
			SELECT
				 TB_F.ItemDetailID
				,TB_F.LogoStyle
				,CASE 
					WHEN BLANK = 1 THEN 11
					WHEN DHT = 1 AND (EMB = 0 AND SP = 0 AND SUB = 0 AND BLANK = 0) THEN 92
					WHEN SP = 1 AND SUB = 1 AND EMB = 1 THEN 91
					WHEN SP = 1 AND SUB = 1 AND EMB = 0 THEN 90
					WHEN SP = 1 AND EMB = 1 THEN 89
					WHEN EMB = 1 AND SUB = 1 THEN 88
					WHEN SUB = 1 THEN 87
					WHEN EMB = 1 THEN 85
					WHEN SP = 1 THEN 15
				 ELSE NULL
				 END AS OrderTypeID
			FROM
			(
				SELECT
					TB.ItemDetailID
					,STRING_AGG(TB.LogoStyle, ',') WITHIN GROUP (ORDER BY TB.EmbType) AS LogoStyle
					,TB_OT.OrderType
					,IIF(TB_OT.OrderType LIKE '%Print%',1,0) AS SP
					,IIF(TB_OT.OrderType LIKE '%Embroidery%',1,0) AS EMB
					,IIF(TB_OT.OrderType LIKE '%Sublimation%',1,0) AS SUB
					,IIF(TB_OT.OrderType LIKE '%Blank%',1,0) AS BLANK
					,IIF(TB_OT.OrderType LIKE '%DHT%',1,0) AS DHT
				FROM
				(
					SELECT DISTINCT
						 VVLA.ItemDetailID
						,VVLA.[Location]
						,VVLA.EmbType
						,VVLA.LogoStyle AS LogoStyleL2
						,IIF(LG.LogoStyle IS NULL, 'TBD', LG.LogoStyle) AS LogoStyle
					FROM #APPLIQUE VVLA WITH (NOLOCK) 
					LEFT JOIN OPENQUERY([MARIADB],'SELECT LogoStyle, OrderTypeDescription AS OrdType FROM wordpress.L2Brands_LogoStyle') AS LG ON VVLA.LogoStyle = LG.LogoStyle
				) AS TB
				LEFT JOIN
				(
					SELECT
						TB_OT.ItemDetailID
						,STRING_AGG(TB_OT.OrderType, ',') AS OrderType
					FROM
					(
						SELECT DISTINCT
							 VVLA.ItemDetailID
							,IIF(LG.OrderType IS NULL, 'TBD', LG.OrderType) AS OrderType
						FROM #APPLIQUE VVLA WITH (NOLOCK) 
						LEFT JOIN OPENQUERY([MARIADB],'SELECT LogoStyle, OrderTypeDescription AS OrderType FROM wordpress.L2Brands_LogoStyle') AS LG ON VVLA.LogoStyle = LG.LogoStyle
						--ORDER BY ItemDetailID
					) AS TB_OT
					GROUP BY
					TB_OT.ItemDetailID
				) AS TB_OT ON TB.ItemDetailID = TB_OT.ItemDetailID
				GROUP BY TB.ItemDetailID,TB_OT.OrderType
			) AS TB_F
		) AS VLG ON VLD.ItemDetailID = VLG.ItemDetailID

		LEFT JOIN
		(
			SELECT
				ItemDetailID
				,STRING_AGG(Attribute, ',') WITHIN GROUP (ORDER BY AttribPosition) AS SKUAttribute
			FROM
			(
				SELECT
					 ItemDetailID
					,CONCAT(Attribute, ' - ', Color) as Attribute
					,AttribPosition
				FROM AppsLCA.legacycaps.VW_view_LCA_SKUAttributes WITH(NOLOCK)
				WHERE ItemDetailID IN (SELECT DISTINCT ItemDetailID FROM #ORDERS)
				AND Attribute like '%Paracord%'
			) AS SKU
				GROUP BY
					ItemDetailID
		) AS SKUAtt ON VLD.ItemDetailID = SKUAtt.ItemDetailID

--LEFT JOIN 
--	LCA.dbo.Orders od with (nolock)
--	ON 'ORD-' + CAST(VLD.ItemDetailID AS varchar) = od.PONumber
--INNER JOIN
--	LCA.dbo.ManufactureOrders mo WITH (NOLOCK)
--	ON od.OrderID = mo.OrderID AND MO.StatusID < 90			
--LEFT JOIN
--	LCA.dbo.OrderItems oi with (nolock)
--	ON od.OrderID = oi.OrderID AND mo.FirstOrderItemID = oi.OrderItemID
--INNER JOIN
--	LCA.dbo.Styles st with (nolock)
--	ON oi.StyleID = st.StyleID and st.Comments9 LIKE '%Headwear%'

LEFT JOIN 
	(SELECT * FROM OPENQUERY([MARIADB],'SELECT * FROM wordpress.Embelishment_Location_L2B_PPM')) EL2BPPM
	ON EL2BPPM.[Location_L2B] = VLA.[Location]

--where VLD.ItemDetailID = 4902554		
GROUP BY 
		 CO.OrderID
		,VLD.ItemDetailID
		,co.PONumber
		--,VLD2.[Location]
		,VLA.[Location]
		,VLD2.SequenceNo
		,VLA.StitchCount
		,VLA.Codes
		,VLA.LogoStyleName
		,VLG.LogoStyle
		,EL2BPPM.ID_PPM_Location
		,VLG.OrderTypeID
		,VLD3.ThreadID
		,VLA.AppliqueColor
		,SKUAtt.SKUAttribute


SELECT 
    OE.Codes
    ,OD.Comments26
    ,OE.ItemDetailID
-- UPDATE OD SET
--     Comments26 = OE.Codes
FROM #TB_Final AS OE
INNER JOIN [192.168.1.53].LCA.dbo.Orders AS OD WITH(NOLOCK) ON OE.OrderID = OD.OrderID
WHERE ItemDetailID IN (5605886)

-- SELECT*
-- FROM #APPLIQUE
-- WHERE ItemDetailID = 5262808
END
