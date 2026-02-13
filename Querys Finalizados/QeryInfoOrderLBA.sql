USE [AppsLCA]
GO

/****** Object:  View [dbo].[VW_InfoOrdersToPolyPM_Emb_Apparel]    Script Date: 10/04/2025 10:32:20 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO









ALTER VIEW [dbo].[VW_InfoOrdersToPolyPM_Emb_Apparel]
AS

SELECT
	od.OrderID,
	od.PONumber,
	VLD.ItemDetailID, 
	VLD2.[Location], 
	VLA.Codes,
	VLA.StitchCount, 
	VLD2.SequenceNo,
	ISNULL(EL2BPPM.ID_PPM_Location,28) AS OrderTypeID4
	,VLD3.ThreadID
	,VLA.AppliqueColor
	,VLA.LogoStyle
	,st.Comments9
	,st.StyleNumber
FROM AppsLCA.legacycaps.VW_view_LCA_Digitizing VLD WITH (NOLOCK)


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
			FROM AppsLCA.legacycaps.VW_view_LCA_Digitizing  WITH (NOLOCK)
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
			FROM AppsLCA.legacycaps.VW_view_LCA_Digitizing  WITH (NOLOCK)
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
						WHEN AppliqueMaterial like '%Felt%' THEN CONCAT(CAST(Num_Applique as VARCHAR),CodeStitches,'F')
						WHEN AppliqueMaterial like '%Jersey%' AND Num_Applique = 0 THEN 
							CASE 
								WHEN [Location] like '%Sleeve%' or [Location] like '%Leg%' THEN CONCAT(CAST(Num_Applique as VARCHAR),'S',CodeStitches)
								WHEN [Location] like '%Front%' or [Location] like '%Back%' or [Location] like '%Rear%' THEN CONCAT(CAST(Num_Applique as VARCHAR),'L',CodeStitches)
							END
						WHEN AppliqueMaterial like '%Jersey%' AND Num_Applique > 0 THEN CONCAT(CAST(Num_Applique as VARCHAR),CodeStitches)							
						
						WHEN AppliqueMaterial like '%Twill%' OR LogoStyle LIKE 'PV%' THEN CONCAT(CAST(Num_Applique as VARCHAR),CodeStitches)
						WHEN LogoStyle IN ('EM','DEM','FCE','FCEP','FCEM') AND Num_Applique = 0 AND [Location] LIKE 'Front%' OR [Location] LIKE 'Back%' THEN
							CONCAT(CAST(Num_Applique as VARCHAR),'L',CodeStitches)
						WHEN LogoStyle IN ('EM','DEM','FCE','FCEP','FCEM') AND Num_Applique = 0 AND [Location] LIKE 'Left Chest%' OR [Location] LIKE 'Right Chest%' 
							OR [Location] LIKE '%Sleeve%' OR [Location] LIKE '%Leg%' OR [Location] LIKE '%HIP%' OR [Location] LIKE '%POCKET%' OR [Location] LIKE '%SHOULDER%'
							THEN CONCAT(CAST(Num_Applique as VARCHAR),'S',CodeStitches)
						ELSE CONCAT(CAST(Num_Applique as VARCHAR),CodeStitches)
					END AS Code
				FROM
					(
						SELECT DISTINCT 
							 VVLA.ItemDetailID
							,[Location]
							,StitchCount
							,CASE 
								WHEN App_Mat.AppliqueMaterial like '%Twill%' OR LogoStyle LIKE 'PV%' THEN
									CASE
										WHEN StitchCount >= 0	  AND StitchCount <= 14999	    THEN 'A'
										WHEN StitchCount >= 15000 AND StitchCount <= 24999		THEN 'B'
										WHEN StitchCount >= 25000 AND StitchCount <= 34999		THEN 'C'
										WHEN StitchCount >= 35000 AND StitchCount <= 45000		THEN 'D'
										WHEN StitchCount >  45000								THEN 'E'
										
									END
								ELSE
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
										WHEN StitchCount >= 45001 AND StitchCount <= 50000 THEN 'J'
									END
							 END AS CodeStitches
							,EmbType
							,LogoStyle
							,App_Mat.AppliqueColor
							,App_Mat.AppliqueMaterial
							,App_Mat.Num_Applique
						FROM AppsLCA.legacycaps.VW_view_LCA_Applique VVLA WITH (NOLOCK) 
						LEFT JOIN 
						(
							SELECT
								 ItemDetailID
								,MAX(Num_Applique) as Num_Applique
								,STRING_AGG(AppliqueColor, ',') WITHIN GROUP (ORDER BY EmbType, AppliqueColor) AS AppliqueColor
								,STRING_AGG(RTRIM(AppliqueMaterial), ',') WITHIN GROUP (ORDER BY EmbType) AS AppliqueMaterial
							FROM
								(
								SELECT 
									 CASE 
										WHEN (SELECT COUNT(AppliqueMaterial) as AppliqueMaterial FROM AppsLCA.legacycaps.VW_view_LCA_Applique VV WITH (NOLOCK) 
												WHERE VV.ItemDetailID = VVLA.ItemDetailID GROUP BY ItemDetailID) = 0 AND LogoStyleName LIKE '%Foam%' THEN 1
										ELSE (SELECT COUNT(AppliqueMaterial) as AppliqueMaterial FROM AppsLCA.legacycaps.VW_view_LCA_Applique VV WITH (NOLOCK) 
												WHERE VV.ItemDetailID = VVLA.ItemDetailID GROUP BY ItemDetailID)
										END as Num_Applique
									,ItemDetailID
									,AppliqueColor
									,EmbType
									,AppliqueMaterial
								FROM
								AppsLCA.legacycaps.VW_view_LCA_Applique VVLA WITH (NOLOCK)
								) AS TB
							GROUP BY
								ItemDetailID
						) AS App_Mat ON VVLA.ItemDetailID = App_Mat.ItemDetailID
						where (LogoStyleName NOT LIKE '%Screen Print%' AND LogoStyleName NOT LIKE '%Over Print%' AND LogoStyleName <> 'Sublimation' AND LogoStyleName NOT LIKE '%High Definition Print%' AND LogoStyleName <> 'Direct White Label') 
					--	and VVLA.ItemDetailID = 4761254
						
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
	[192.168.1.53].LCA.dbo.Orders od with (nolock)
	ON 'ORD-' + CAST(VLD.ItemDetailID AS varchar) = od.PONumber
INNER JOIN
	[192.168.1.53].LCA.dbo.ManufactureOrders mo WITH (NOLOCK)
	ON od.OrderID = mo.OrderID AND MO.StatusID < 90			
LEFT JOIN
	[192.168.1.53].LCA.dbo.OrderItems oi with (nolock)
	ON od.OrderID = oi.OrderID AND mo.FirstOrderItemID = oi.OrderItemID
INNER JOIN
	[192.168.1.53].LCA.dbo.Styles st with (nolock)
	ON oi.StyleID = st.StyleID and st.Comments9 LIKE '%Apparel%'

LEFT JOIN 
	(SELECT * FROM OPENQUERY([MARIADB],'SELECT * FROM wordpress.Embelishment_Location_L2B_PPM')) EL2BPPM
	ON EL2BPPM.[Location_L2B] = VLD2.[Location]

--WHERE VLA.Codes LIKE '0%'
GROUP BY od.OrderID,VLD.ItemDetailID, od.PONumber,VLD2.[Location], VLD2.SequenceNo,VLA.StitchCount,VLA.Codes,EL2BPPM.ID_PPM_Location,VLD3.ThreadID,VLA.AppliqueColor,VLA.LogoStyle,st.Comments9,st.StyleNumber

GO