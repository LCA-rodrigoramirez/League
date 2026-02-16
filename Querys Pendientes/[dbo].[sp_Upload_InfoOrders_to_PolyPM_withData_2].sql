USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[sp_Upload_InfoOrders_to_PolyPM_withData_2]    Script Date: 13/02/2026 01:55:56 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		RODRIGO RAMIREZ
-- Create date: 2025-01-22
-- Description:	Se realiza proceso para actualizacion de campos de Ordenes segun el PWModulo dentro de las MO. Devuelve tabla con datos.
-- Proceso:		Se realiza update segun tabla de la replica
--				Se devuelven datos actualizados ya en base LCA
-- =============================================
ALTER PROCEDURE [dbo].[sp_Upload_InfoOrders_to_PolyPM_withData_2]
	@PWModulo varchar(100)
AS
BEGIN
 	SET NOCOUNT on;

	--DECLARE @PWModulo varchar(100)
	SET @PWModulo = LTRIM(RTRIM(@PWModulo))

	--SET @PWModulo = 'ASSIGMENT HW FG #777 2025-10-30'
	IF @PWModulo LIKE '%HW%'
	BEGIN

		UPDATE od SET
		--SELECT 
				--[OrderID]		= oi.OrderID
			 [Comments26]	= (CASE WHEN od.Comments26 IS NULL OR od.Comments26 = ''		THEN oi.Codes			ELSE od.Comments26		END)
			,[Comments27]   = (CASE WHEN od.Comments27 IS NULL OR od.Comments27 = ''		THEN oi.StitchCount		ELSE od.Comments27		END)
			,[Comments25]   = (CASE WHEN od.Comments25 IS NULL OR od.Comments25 = ''		THEN oi.SequenceNo		ELSE od.Comments25		END)
			,[OrderTypeID4] = (CASE WHEN		od.OrderTypeID4 IS NULL 
											OR	od.OrderTypeID4 = '' 
											OR	od.OrderTypeID4 = 28						THEN oi.OrderTypeID4	ELSE od.OrderTypeID4	END)
			,[Comments30]   = (CASE WHEN od.Comments30 IS NULL OR od.Comments30 = ''		THEN oi.ThreadID		ELSE od.Comments30		END)
			,[Comments29]   = (CASE WHEN od.Comments29 IS NULL OR od.Comments29 = ''		THEN oi.AppliqueColor	ELSE od.Comments29		END)
			,[Comments7]	= (CASE WHEN od.Comments7  IS NULL OR od.Comments7  = ''		THEN oi.LogoStyleName	ELSE od.Comments7		END)
			,[Comments32]	= (CASE WHEN od.Comments32  IS NULL OR od.Comments32  = ''		THEN oi.LogoStyle	ELSE od.Comments32		END)
			,[OrderTypeID2] = (CASE WHEN		od.OrderTypeID2 IS NULL 
											OR	od.OrderTypeID2 = ''						THEN oi.OrderTypeID2	ELSE od.OrderTypeID2	END)

			FROM [192.168.1.93].AppsLCA.dbo.VW_InfoOrdersToPolyPM	AS oi	WITH(NOLOCK) 
			--FROM AppsLCA.dbo.VW_InfoOrdersToPolyPM	AS oi	WITH(NOLOCK)
			INNER JOIN LCA.dbo.Orders								AS od	WITH(NOLOCK) ON od.OrderID	= oi.OrderID
			INNER JOIN (
							SELECT DISTINCT 
								OD.orderID 
							FROM		LCA.dbo.Orders				AS od WITH(NOLOCK)
							INNER JOIN	LCA.dbo.ManufactureOrders	AS mo WITH(NOLOCK) ON mo.OrderID	= od.OrderID 
																							AND LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(mo.Comments7, CHAR(10), ''), CHAR(9), ''), CHAR(13), ''))) = @PWModulo
																							and mo.StatusID < 90
						) AS odo ON odo.OrderID = od.OrderID

			SELECT 
				 [PWModulo]				= @PWModulo
				,[PONumber]				= od.PONumber
				,[Location_Desc]		= ddv5.DropDownValue
				,[Code]					= od.Comments26
				,[ApplicationType]		= od.Comments32
				,[LogoStyleName]		= od.Comments7
				,[Sequence_Qty]			= od.Comments25
				,[StitchCount]			= od.Comments27
				,[ThreadID]				= od.Comments30
				,[OrderType]			= ddv2.DropDownValue
				FROM	(
							SELECT DISTINCT 
								OD.orderID 
							FROM		LCA.dbo.Orders				AS od WITH(NOLOCK)
							INNER JOIN	LCA.dbo.ManufactureOrders	AS mo WITH(NOLOCK) ON mo.OrderID	= od.OrderID 
																							AND LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(mo.Comments7, CHAR(10), ''), CHAR(9), ''), CHAR(13), ''))) = @PWModulo
						) AS odo 
				LEFT JOIN	LCA.dbo.Orders			AS od	WITH (NOLOCK) ON odo.OrderID = od.OrderID
				LEFT JOIN	LCA.dbo.DropDownValues5 AS ddv5 WITH (NOLOCK) ON od.OrderTypeID4 = ddv5.DropDownValueID
				LEFT JOIN	LCA.dbo.DropDownValues2 AS ddv2 WITH (NOLOCK) ON od.OrderTypeID2 = ddv2.DropDownValueID AND ddv2.DropDownID = 13
	END
	ELSE
	BEGIN
		UPDATE od SET
		--SELECT 
		-- [OrderID]		= oi.OrderID,
		-- [ItemDetailID] = oi.ItemDetailID
		-- ,[ORD]			= od.PONumber
		 [Comments26]	=  oi.Codes		
		,[Comments27]   =  oi.StitchCount
		,[Comments25]   =  oi.SequenceNo
		,[OrderTypeID4] =  oi.OrderTypeID4
		,[Comments30]   =  oi.ThreadID		
		,[Comments29]   =  oi.AppliqueColor	
		,[Comments32]	=  oi.LogoStyle	
		,[OrderTypeID2] = (CASE WHEN		od.OrderTypeID2 IS NULL 
										OR	od.OrderTypeID2 = '' 						THEN oi.OrderTypeID2	ELSE od.OrderTypeID2	END)

		FROM [192.168.1.93].AppsLCA.dbo.VW_InfoOrdersToPolyPM_Emb_Apparel	AS oi	WITH(NOLOCK)
		INNER JOIN LCA.dbo.Orders								AS od	WITH(NOLOCK) ON od.OrderID	= oi.OrderID
		INNER JOIN (
						SELECT DISTINCT 
							OD.orderID 
						FROM		LCA.dbo.Orders				AS od WITH(NOLOCK)
						INNER JOIN	LCA.dbo.ManufactureOrders	AS mo WITH(NOLOCK) ON mo.OrderID	= od.OrderID 
																						AND mo.Comments7 = @PWModulo
					) AS odo ON odo.OrderID = od.OrderID

		SELECT 
		 [PWModulo]				= @PWModulo
		,[PONumber]				= od.PONumber
		,[Location_Desc]		= ddv5.DropDownValue
		,[Code]					= od.Comments26
		,[ApplicationType]		= od.Comments32
		,[Sequence_Qty]			= od.Comments25
		,[StitchCount]			= od.Comments27
		,[ThreadID]				= od.Comments30
		,[OrderType]			= ddv2.DropDownValue
		FROM	(
					SELECT DISTINCT 
						OD.orderID 
					FROM		LCA.dbo.Orders				AS od WITH(NOLOCK)
					INNER JOIN	LCA.dbo.ManufactureOrders	AS mo WITH(NOLOCK) ON mo.OrderID	= od.OrderID 
																					AND mo.Comments7 = @PWModulo
				) AS odo 
		LEFT JOIN	LCA.dbo.Orders			AS od	WITH (NOLOCK) ON odo.OrderID = od.OrderID
		LEFT JOIN	LCA.dbo.DropDownValues5 AS ddv5 WITH (NOLOCK) ON od.OrderTypeID4 = ddv5.DropDownValueID
		LEFT JOIN	LCA.dbo.DropDownValues2 AS ddv2 WITH (NOLOCK) ON od.OrderTypeID2 = ddv2.DropDownValueID AND ddv2.DropDownID = 13

	END


	
    
	
	
END
