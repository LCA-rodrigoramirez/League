DROP TABLE IF EXISTS #TB_CodesEMB
DROP TABLE IF EXISTS #TB_OrdersExport

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
ON oi.StyleID = st.StyleID and st.Comments9 LIKE '%Apparel%'
LEFT JOIN 
[192.168.1.53].[AppsLCA].[legacycaps].[VW_view_qryLCA_Order_Export] AS OE WITH(NOLOCK)
ON 'ORD-' + CAST(OE.ItemDetailID AS varchar) = od.PONumber

SELECT
	CO.ItemDetailID
	,[Location]
	,SequenceNo
	,EmbType
	,SpoolID
INTO #DIGITIZING
FROM #ORDERS AS CO WITH(NOLOCK)
INNER JOIN AppsLCA.legacycaps.VW_view_LCA_Digitizing VLD WITH (NOLOCK) ON VLD.ItemDetailID = CO.ItemDetailID

SELECT DISTINCT
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
ON VVLA.ItemDetailID = CO.ItemDetailID

SELECT 
	CO.OrderID,
	CO.PONumber,
	VLD.ItemDetailID, 
	ISNULL(VLD2.[Location],VLA.[Location]) AS [Location], 
	VLA.Codes,
	VLA.StitchCount, 
	VLD2.SequenceNo,
	ISNULL(EL2BPPM.ID_PPM_Location,28) AS OrderTypeID4
	,VLD3.ThreadID
	,VLA.AppliqueColor
	,VLG.LogoStyle
	,VLG.OrderTypeID as OrderTypeID2
	
INTO #TB_Final

FROM #DIGITIZING AS VLD WITH (NOLOCK)

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
			FROM #DIGITIZING  WITH (NOLOCK)
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
			FROM #DIGITIZING WITH (NOLOCK)
			--where ItemDetailID = 4098052
		) VLD
		GROUP BY ItemDetailID) 
		VLD3 ON VLD.ItemDetailID = VLD3.ItemDetailID
		
INNER JOIN 
		(
		SELECT 
			ItemDetailID, 
			STRING_AGG(StitchCount, ',') WITHIN GROUP (ORDER BY EmbType) AS StitchCount, 
			STRING_AGG([Location], ',') WITHIN GROUP (ORDER BY EmbType) AS [Location],
			STRING_AGG(Code, ',') WITHIN GROUP (ORDER BY EmbType) AS Codes,
			STRING_AGG(AppliqueColor, ',') WITHIN GROUP (ORDER BY EmbType, AppliqueColor) AS AppliqueColor,
			STRING_AGG(LogoStyle, ',') WITHIN GROUP (ORDER BY EmbType) AS LogoStyle
		FROM (
				SELECT DISTINCT
				ItemDetailID,
				[Location],
				StitchCount,
				EmbType,
				Code,
				LogoStyle,
				AppliqueColor
			FROM (
				SELECT DISTINCT 
					ItemDetailID,
					[Location],
					StitchCount,
					EmbType,
					AppliqueColor,
					LogoStyle,
					CASE
						WHEN AppliqueMaterial = 'Felt' THEN CONCAT(CAST(Num_Applique as VARCHAR),CodeStitches)
						WHEN AppliqueMaterial = 'Direct' AND Num_Applique = 0 THEN 
							CASE 
								WHEN [Location] LIKE 'Left Chest%' OR [Location] LIKE 'Right Chest%' 
							OR [Location] LIKE '%Sleeve%' OR [Location] LIKE '%Leg%' OR [Location] LIKE '%HIP%' OR [Location] LIKE '%POCKET%' OR [Location] LIKE '%SHOULDER%'
							OR [Location] LIKE '%ADULT CENTER CHEST%' OR [Location] LIKE '%COLLAR%' OR [Location] LIKE '%Cuff%' OR [Location] LIKE '%Back Neck%' THEN CONCAT(CAST(Num_Applique as VARCHAR),'S',CodeStitches)
						WHEN [Location] like '%Front%' or [Location] like '%Back%' or [Location] like '%Rear%' THEN CONCAT(CAST(Num_Applique as VARCHAR),'L',CodeStitches)
							END
						WHEN AppliqueMaterial = 'Jersey' AND Num_Applique > 0 THEN CONCAT(CAST(Num_Applique as VARCHAR),CodeStitches)							
						
						WHEN AppliqueMaterial = 'Canvas' THEN CONCAT(CAST(Num_Applique as VARCHAR),CodeStitches)
						WHEN AppliqueMaterial = 'Foam' THEN CONCAT(CAST(Num_Applique as VARCHAR),CodeStitches)
						
					END AS Code
				FROM
					(
						SELECT DISTINCT 
							 VVLA.ItemDetailID
							,VVLA.[Location]
							,StitchCount
							,CASE 
								WHEN LAM.AppliqueMaterial = 'Direct' THEN
									CASE
										WHEN StitchCount >= 0 AND StitchCount <= 5000 THEN 'A'
										WHEN StitchCount >= 5001 AND StitchCount <= 10000 THEN 'B'
										WHEN StitchCount >= 10001 AND StitchCount <= 15000 THEN 'C'
										WHEN StitchCount >= 15001 AND StitchCount <= 20000 THEN 'D'
										WHEN StitchCount >= 20001 AND StitchCount <= 25000 THEN 'E'
										WHEN StitchCount >= 25001 AND StitchCount <= 30000 THEN 'F'
										WHEN StitchCount >= 30001 AND StitchCount <= 35000 THEN 'G'
										WHEN StitchCount >= 35001 AND StitchCount <= 40000 THEN 'H'
										WHEN StitchCount >= 40001 AND StitchCount <= 45000 THEN 'I'
										WHEN StitchCount >= 45001 THEN 'J'
									END
								WHEN LAM.AppliqueMaterial = 'Jersey' THEN
									CASE
										WHEN StitchCount >= 0 AND StitchCount <= 5000 THEN 'AJS'
										WHEN StitchCount >= 5001 AND StitchCount <= 10000 THEN 'BJS'
										WHEN StitchCount >= 10001 AND StitchCount <= 15000 THEN 'CJS'
										WHEN StitchCount >= 15001 AND StitchCount <= 20000 THEN 'DJS'
										WHEN StitchCount >= 20001 AND StitchCount <= 25000 THEN 'EJS'
										WHEN StitchCount >= 25001 AND StitchCount <= 30000 THEN 'FJS'
										WHEN StitchCount >= 30001 AND StitchCount <= 35000 THEN 'GJS'
										WHEN StitchCount >= 35001 AND StitchCount <= 40000 THEN 'HJS'
										WHEN StitchCount >= 40001 AND StitchCount <= 45000 THEN 'IJS'
										WHEN StitchCount >= 45001 AND StitchCount <= 50000 THEN 'JJS'
									END
								WHEN LAM.AppliqueMaterial = 'Canvas' THEN
									CASE
										WHEN StitchCount >= 0 AND StitchCount <= 5000 THEN 'ACV'
										WHEN StitchCount >= 5001 AND StitchCount <= 10000 THEN 'BCV'
										WHEN StitchCount >= 10001 AND StitchCount <= 15000 THEN 'CCV'
										WHEN StitchCount >= 15001 AND StitchCount <= 20000 THEN 'DCV'
										WHEN StitchCount >= 20001 AND StitchCount <= 25000 THEN 'ECV'
										WHEN StitchCount >= 25001 AND StitchCount <= 30000 THEN 'FCV'
										WHEN StitchCount >= 30001 AND StitchCount <= 35000 THEN 'GCV'
										WHEN StitchCount >= 35001 AND StitchCount <= 40000 THEN 'HCV'
										WHEN StitchCount >= 40001 AND StitchCount <= 45000 THEN 'ICV'
										-- WHEN StitchCount >= 45001 AND StitchCount <= 50000 THEN 'JCV'
										WHEN StitchCount >= 45001 THEN 'JCV'
									END
								WHEN LAM.AppliqueMaterial = 'Felt' THEN
									CASE
										WHEN StitchCount >= 0 AND StitchCount <= 5000 THEN 'AFE'
										WHEN StitchCount >= 5001 AND StitchCount <= 10000 THEN 'BFE'
										WHEN StitchCount >= 10001 AND StitchCount <= 15000 THEN 'CFE'
										WHEN StitchCount >= 15001 AND StitchCount <= 20000 THEN 'DFE'
										WHEN StitchCount >= 20001 AND StitchCount <= 25000 THEN 'EFE'
										WHEN StitchCount >= 25001 AND StitchCount <= 30000 THEN 'FFE'
										WHEN StitchCount >= 30001 AND StitchCount <= 35000 THEN 'GFE'
										WHEN StitchCount >= 35001 AND StitchCount <= 40000 THEN 'HFE'
										WHEN StitchCount >= 40001 AND StitchCount <= 45000 THEN 'IFE'
										WHEN StitchCount >= 45001 AND StitchCount <= 50000 THEN 'JFE'
									END
								WHEN LAM.AppliqueMaterial = 'Foam' THEN
									CASE
										WHEN StitchCount >= 0 AND StitchCount <= 5000 THEN 'AFO'
										WHEN StitchCount >= 5001 AND StitchCount <= 10000 THEN 'BFO'
										WHEN StitchCount >= 10001 AND StitchCount <= 15000 THEN 'CFO'
										WHEN StitchCount >= 15001 AND StitchCount <= 20000 THEN 'DFO'
										WHEN StitchCount >= 20001 AND StitchCount <= 25000 THEN 'EFO'
										WHEN StitchCount >= 25001 AND StitchCount <= 30000 THEN 'FFO'
										WHEN StitchCount >= 30001 AND StitchCount <= 35000 THEN 'GFO'
										WHEN StitchCount >= 35001 AND StitchCount <= 40000 THEN 'HFO'
										WHEN StitchCount >= 40001 AND StitchCount <= 45000 THEN 'IFO'
										WHEN StitchCount >= 45001 AND StitchCount <= 50000 THEN 'JFO'
									END
							 END AS CodeStitches
							,EmbType
							,VVLA.LogoStyle
							,App_Mat.AppliqueColor
							,LAM.AppliqueMaterial
							,App_Mat.Num_Applique
						FROM #APPLIQUE AS VVLA WITH(NOLOCK)
						
						LEFT JOIN 
						(
							SELECT
								 ItemDetailID
								,[Location]
								,MAX(Num_Applique) as Num_Applique
								,STRING_AGG(AppliqueColor, ',') WITHIN GROUP (ORDER BY EmbType, AppliqueColor) AS AppliqueColor
								,STRING_AGG(RTRIM(AppliqueMaterial), ',') WITHIN GROUP (ORDER BY EmbType) AS AppliqueMaterial
							FROM
								(
								SELECT DISTINCT
									 CASE 
										WHEN ISNULL((SELECT COUNT(AppliqueMaterial) as AppliqueMaterial FROM #APPLIQUE VV WITH (NOLOCK) 
												WHERE VV.ItemDetailID = VVLA.ItemDetailID AND VV.[Location] = VVLA.[Location] AND VVLA.AppliqueMaterial IS NOT NULL GROUP BY VV.ItemDetailID,[Location]),0) = 0 AND LogoStyleName LIKE '%Foam%' THEN 1
										ELSE ISNULL((SELECT COUNT(AppliqueMaterial) as AppliqueMaterial FROM #APPLIQUE VV WITH (NOLOCK) 
												WHERE VV.ItemDetailID = VVLA.ItemDetailID AND VV.[Location] = VVLA.[Location] AND VVLA.AppliqueMaterial IS NOT NULL GROUP BY VV.ItemDetailID,[Location]),0)
										END as Num_Applique
									,VVLA.ItemDetailID
									,[Location]
									,AppliqueColor
									,EmbType
									,AppliqueMaterial
								FROM #APPLIQUE AS VVLA WITH(NOLOCK)
								-- where vvla.ItemDetailID in (5235241,5178518)
								) AS TB
							GROUP BY
								ItemDetailID
								,[Location]
						) AS App_Mat ON VVLA.ItemDetailID = App_Mat.ItemDetailID AND VVLA.[Location] = App_Mat.[Location]
						LEFT JOIN [AppsLCA].[dbo].[PBI_EMB_LogoApliqueMaterial] AS LAM WITH(NOLOCK) ON VVLA.LogoStyle = LAM.LogoStyle
						where (LogoStyleName NOT LIKE '%Screen Print%' AND LogoStyleName NOT LIKE '%Over Print%' AND LogoStyleName <> 'Sublimation' AND LogoStyleName NOT LIKE '%High Definition Print%' AND LogoStyleName <> 'Direct White Label') 
						-- AND VVLA.ItemDetailID = 5974893
						
					) TB_Ini
				
				--where ItemDetailID IN (4537723)
			)abc
			--WHERE AppliqueMaterial IS NOT NULL
			--AND 

		) tb
		GROUP BY ItemDetailID
		) 
		as VLA ON VLD.ItemDetailID = VLA.ItemDetailID
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
					FROM #APPLIQUE AS VVLA WITH(NOLOCK)
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
						FROM #APPLIQUE AS VVLA WITH(NOLOCK)
						LEFT JOIN OPENQUERY([MARIADB],'SELECT LogoStyle, OrderTypeDescription AS OrderType FROM wordpress.L2Brands_LogoStyle') AS LG ON VVLA.LogoStyle = LG.LogoStyle
						--ORDER BY ItemDetailID
					) AS TB_OT
					GROUP BY
					TB_OT.ItemDetailID
				) AS TB_OT ON TB.ItemDetailID = TB_OT.ItemDetailID
				GROUP BY TB.ItemDetailID,TB_OT.OrderType
			) AS TB_F
		) AS VLG ON VLD.ItemDetailID = VLG.ItemDetailID

-- LEFT JOIN 
-- 	[192.168.1.53].LCA.dbo.Orders od with (nolock)
-- 	ON 'ORD-' + CAST(VLD.ItemDetailID AS varchar) = od.PONumber

-- INNER JOIN
-- 	[192.168.1.53].LCA.dbo.ManufactureOrders mo WITH (NOLOCK)
-- 	ON od.OrderID = mo.OrderID AND MO.StatusID < 90			
-- LEFT JOIN
-- 	[192.168.1.53].LCA.dbo.OrderItems oi with (nolock)
-- 	ON od.OrderID = oi.OrderID AND mo.FirstOrderItemID = oi.OrderItemID
-- INNER JOIN
-- 	[192.168.1.53].LCA.dbo.Styles st with (nolock)
-- 	ON oi.StyleID = st.StyleID and st.Comments9 LIKE '%Apparel%'

LEFT JOIN 
	(SELECT * FROM OPENQUERY([MARIADB],'SELECT * FROM wordpress.Embelishment_Location_L2B_PPM')) EL2BPPM
	ON EL2BPPM.[Location_L2B] = VLD2.[Location]

--WHERE VLA.Codes LIKE '0%'
GROUP BY 
	 CO.OrderID
	,VLD.ItemDetailID
	,CO.PONumber
	,ISNULL(VLD2.[Location],VLA.[Location])
	,VLD2.SequenceNo
	,VLA.StitchCount
	,VLA.Codes
	,EL2BPPM.ID_PPM_Location
	,VLD3.ThreadID
	,VLA.AppliqueColor
	,VLG.LogoStyle
	,VLG.OrderTypeID


SELECT
*
INTO #TB_CodesEmb
FROM #TB_Final

 SELECT DISTINCT
	 OD.OrderID
	,OD.PONumber
	,OD.Comments26
INTO #TB_OrdersExport
FROM (SELECT StatusID FROM [192.168.1.53].LCA.dbo.StatusNames sn with (nolock) WHERE StatusID in (40,51,53,55,78,90)) AS SN
INNER JOIN [192.168.1.53].LCA.dbo.ManufactureOrders					AS MO	WITH(NOLOCK) ON SN.StatusID			= MO.StatusID 
INNER JOIN [192.168.1.53].LCA.dbo.Orders							AS OD	WITH(NOLOCK) ON MO.OrderID			= OD.OrderID
INNER JOIN [192.168.1.53].AppsLCA.dbo.TB_MO_PartNumber_IM_MOProcess	AS MOP	WITH(NOLOCK) ON MO.ManufactureID	= MOP.ManufactureID AND (EmbAPP = 1)
 
--  SELECT DISTINCT
-- 	 OD.OrderID
-- 	,OD.PONumber
-- 	,OD.Comments26
-- 	,SH.WayBill
-- INTO #TB_OrdersExport
-- FROM (SELECT ShipmentID,WayBill FROM [192.168.1.53].LCA.dbo.Shipments AS SH WITH(NOLOCK) WHERE WayBill LIKE '%20260224%') AS SH
-- INNER JOIN [192.168.1.53].LCA.dbo.PackedBoxes							AS PB	WITH(NOLOCK) ON SH.ShipmentID		= PB.ShipmentID
-- INNER JOIN [192.168.1.53].LCA.dbo.Orders								AS OD	WITH(NOLOCK) ON PB.OrderID			= OD.OrderID
-- INNER JOIN [192.168.1.53].LCA.dbo.ManufactureOrders					AS MO	WITH(NOLOCK) ON OD.OrderID			= MO.OrderID AND MO.StatusID <= 90
-- INNER JOIN [192.168.1.53].AppsLCA.dbo.TB_MO_PartNumber_IM_MOProcess	AS MOP	WITH(NOLOCK) ON MO.ManufactureID	= MOP.ManufactureID AND (EmbAPP = 1)
--WHERE PONumber = 'ORD-5616598'
-- SELECT DISTINCT
-- 	 OD.OrderID
-- 	,OD.PONumber
-- 	,OD.Comments26
-- INTO #TB_OrdersExport

-- FROM (SELECT ShipmentID,OrderID FROM [192.168.1.53].LCA.dbo.PackedBoxes	AS PB	WITH(NOLOCK) WHERE StatusID IN (25,27)) AS PB
-- INNER JOIN [192.168.1.53].LCA.dbo.Orders								AS OD	WITH(NOLOCK) ON PB.OrderID			= OD.OrderID
-- INNER JOIN [192.168.1.53].LCA.dbo.ManufactureOrders					AS MO	WITH(NOLOCK) ON OD.OrderID			= MO.OrderID AND MO.StatusID <= 90
-- INNER JOIN [192.168.1.53].AppsLCA.dbo.TB_MO_PartNumber_IM_MOProcess	AS MOP	WITH(NOLOCK) ON MO.ManufactureID	= MOP.ManufactureID AND (EmbAPP = 1)


SELECT 
	OE.OrderID
	,OE.PONumber
	,OE.Comments26
	-- ,OE.WayBill
	,CE.ItemDetailID
	,CE.Codes
	,CE.StitchCount
	,CE.LogoStyle
	,CE.[Location]
-- UPDATE OD SET
-- 	Comments26 = 'MIS2'
FROM #TB_OrdersExport AS OE
LEFT  JOIN #TB_CodesEMB AS CE ON OE.OrderID = CE.OrderID
INNER JOIN [192.168.1.53].LCA.dbo.Orders AS OD WITH(NOLOCK) ON OE.OrderID = OD.OrderID
WHERE ItemDetailID in (6000911)
return

--SELECT * FROM #TB_CodesEMB WHERE PONumber = 'ORD-5557634'

SELECT 
	 OD.OrderID
	,OD.PONumber
	,OD.Comments26
	,vvla.app
	,CE.*
	-- UPDATE OD SET
	-- Comments26 = CE.Codes
FROM #TB_CodesEMB AS CE
INNER JOIN [192.168.1.53].LCA.dbo.Orders AS OD WITH(NOLOCK) ON CE.OrderID = OD.OrderID
INNER JOIN (SELECT ItemDetailID,COUNT(AppliqueMaterial) as app FROM AppsLCA.legacycaps.VW_view_LCA_Applique GROUP BY ItemDetailID) AS VVLA ON CE.ItemDetailID = vvla.ItemDetailID
WHERE Codes <> OD.Comments26
-- LEFT(Codes,1) <> VVLA.app

SELECT
*
FROM [AppsLCA].[dbo].[InfoOrdersToPolyPM_Emb_Apparel]
where ItemDetailID = 5461466

-- SELECT*
-- FROM AppsLCA.legacycaps.VW_view_LCA_Applique VVLA WITH (NOLOCK)
-- WHERE ItemDetailID in (5616598)


SELECT *
FROM AppsLCA.legacycaps.VW_view_LCA_DesignColors VVLA WITH (NOLOCK)
WHERE ItemDetailID = 5631957
-- SELECT *
-- FROM AppsLCA.legacycaps.VW_view_LCA_Applique VVLA WITH (NOLOCK)
-- WHERE DesignNo = 'DTG069764'
SELECT
*
FROM [AppsLCA].[dbo].[PBI_EMB_LogoApliqueMaterial]
WHERE LogoStyle IN ('SVO','EM')
