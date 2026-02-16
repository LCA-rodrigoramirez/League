USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[Barcode_Update_ShippingBins]    Script Date: 16/02/2026 08:00:27 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Barcode_Update_ShippingBins]
  @json NVARCHAR(MAX)
AS
BEGIN
  SET NOCOUNT ON 

   --DECLARE @json NVARCHAR(MAX) = '
   --{     
   --  "pppa": ["PPPA1000307-001","PPPA1000823"],
   --  "code": ["AMZNCC00006671764969","0000112"],
   --  "ppgb": "PPGB1000587",
	  -- "portDestinationId":"69"
   --}';
  DECLARE @code		NVARCHAR(MAX) = JSON_QUERY(@json, '$.code');

  DECLARE @pppa		NVARCHAR(MAX) = JSON_QUERY(@json, '$.pppa');

  DECLARE @ppgb		NVARCHAR(MAX) = JSON_VALUE(@json, '$.ppgb')

  DECLARE @PortId	NVARCHAR(MAX) = JSON_VALUE(@json, '$.portDestinationId')
  
  DECLARE @BoxComments3	NVARCHAR(MAX) = JSON_VALUE(@json, '$.comments')			---ADD JH 20250619 NUEVA SOLICITUD PARA ACTUALIZAR BOXCOMMENTS3

  DECLARE @BoxComments6 NVARCHAR(MAX)

  BEGIN TRY
	
    DECLARE @IDPPGB AS INT
	IF SUBSTRING(@ppgb,1,4) = 'PPGB'
	BEGIN
		SET @IDPPGB = CAST(SUBSTRING(@ppgb,5,LEN(JSON_VALUE(@json, '$.ppgb')))- 1000000 AS INT)
	END
	ELSE
	BEGIN
		SET @BoxComments6 = @ppgb
	END

    DROP TABLE IF EXISTS #TB_Boxes
    DROP TABLE IF EXISTS #TB_Boxes_001
    DROP TABLE IF EXISTS #TB_Pallets
	  DROP TABLE IF EXISTS #TB_OrderID

	CREATE TABLE #TB_OrderID (
		OrderID INT
	);

    SELECT value AS BoxNumber
    INTO #TB_Boxes_001
    FROM OPENJSON(@code);
    
    ---CAMBIO PARA AGREGAR LAS CAJAS DE AMAZON QUE EMPIEZAN CON AMZN EN BOXCOMMENTS4 PPM (JH,RR)
    SELECT BoxNumber 
    INTO #TB_Boxes
    FROM (
      SELECT PB.BoxNumber 
      FROM #TB_Boxes_001 AS A
      INNER JOIN LCA.dbo.PackedBoxes AS PB WITH(NOLOCK) ON PB.BoxComments4 = A.BoxNumber
      WHERE A.BoxNumber LIKE 'AMZN%'
      UNION ALL
      SELECT A.BoxNumber
      FROM #TB_Boxes_001 AS A
      WHERE A.BoxNumber NOT LIKE 'AMZN%'
      ) AS TB
      
      
    
    -- SELECT value AS BoxNumber
    -- INTO #TB_Boxes
    -- FROM OPENJSON(@code);

    SELECT 
      CASE 
        WHEN CHARINDEX('-',value) > 0 
          THEN SUBSTRING(value,5,CHARINDEX('-',SUBSTRING(value,5,LEN(value))) - 1)
        ELSE
         SUBSTRING(value,5,LEN(value))
      END AS PalletID
      ,CASE 
        WHEN CHARINDEX('-',value) > 0 
          THEN SUBSTRING(value,CHARINDEX('-',value) + 1, LEN(value))
        ELSE
         NULL
      END AS Tag

    INTO #TB_Pallets
    FROM OPENJSON(@pppa);
    
    -- SELECT * FROM #TB_PALLETS
    
    

    UPDATE #TB_Pallets SET PalletID = CAST(PalletID AS INT) - 1000000 

	IF SUBSTRING(@ppgb,1,4) = 'PPGB'
	BEGIN
		----------------------------- CUANDO ENVIAN CAJAS ---------------------------------
		-- SELECT PB.BoxNumber, PB.GoodsBinID, PB.PackedPalletID, @IDPPGB AS NEWGB
	
		UPDATE PB	SET 
			GoodsBinID		= @IDPPGB
			,BoxComments3	= @BoxComments3			---ADD JH 20250619 NUEVA SOLICITUD PARA ACTUALIZAR BOXCOMMENTS3
		FROM [LCA].[dbo].[PackedBoxes] AS PB WITH(NOLOCK)
		INNER JOIN #TB_Boxes AS TBB ON PB.BoxNumber = TBB.BoxNumber AND PB.StatusID IN (25,27,75) ---Modify JH 20250619 0807 Por problemas de eliminar info de Bins cuando es shipped.
		--INNER JOIN #TB_Boxes AS TBB ON PB.BoxNumber = TBB.BoxNumber AND PB.StatusID = 27
	

		--SELECT * FROM LCA.dbo.StatusNames order by StatusName
		--- Obteniendo OrderID de Boxes
		INSERT INTO #TB_OrderID (OrderID)
		SELECT PB.OrderID
		FROM [LCA].[dbo].[PackedBoxes] AS PB WITH (NOLOCK)
		INNER JOIN #TB_Boxes AS TBB 
			ON PB.BoxNumber = TBB.BoxNumber 
		WHERE PB.StatusID IN (25,27,75) ---Modify JH 20250619 0807 Por problemas de eliminar info de Bins cuando es shipped.
		--WHERE PB.StatusID = 27;
	 
		----------------------------- CUANDO ENVIAN PALLETS ---------------------------------
		-- SELECT PB.BoxNumber, PB.GoodsBinID, PB.PackedPalletID, @IDPPGB AS NEWGB
    
		UPDATE PB SET
			GoodsBinID = @IDPPGB
			,BoxComments3	= @BoxComments3			---ADD JH 20250619 NUEVA SOLICITUD PARA ACTUALIZAR BOXCOMMENTS3
		FROM        #TB_Pallets                    AS TBP
		INNER JOIN  [LCA].[dbo].[PackedBoxes]      AS PB WITH(NOLOCK)    ON PB.PackedPalletID = TBP.PalletID AND PB.StatusID IN (25,27,75) ---Modify JH 20250619 0807 Por problemas de eliminar info de Bins cuando es shipped.
		LEFT JOIN   [LCA].[dbo].[DropDownValues3]  AS DDV3 WITH(NOLOCK)  ON PB.BoxTagID = DDV3.DropDownValueID 
		WHERE (CASE WHEN  TBP.Tag IS NULL THEN 1
				  WHEN RIGHT(DDV3.DropDownValue,3) = TBP.Tag THEN 1
				  ELSE 0 END ) = 1 
		--INNER JOIN #TB_Pallets AS TBP ON PB.PackedPalletID = TBP.PalletID AND PB.StatusID = 27

		--- Obteniendo OrderID de Pallet
		INSERT INTO #TB_OrderID (OrderID)
		SELECT PB.OrderID
		FROM        #TB_Pallets                    AS TBP
	  INNER JOIN  [LCA].[dbo].[PackedBoxes]      AS PB WITH(NOLOCK)    ON PB.PackedPalletID = TBP.PalletID AND PB.StatusID IN (25,27,75) ---Modify JH 20250619 0807 Por problemas de eliminar info de Bins cuando es shipped.
	  LEFT JOIN   [LCA].[dbo].[DropDownValues3]  AS DDV3 WITH(NOLOCK)  ON PB.BoxTagID = DDV3.DropDownValueID 
	  WHERE (CASE WHEN  TBP.Tag IS NULL THEN 1
				WHEN RIGHT(DDV3.DropDownValue,3) = TBP.Tag THEN 1
				ELSE 0 END ) = 1
		--WHERE PB.StatusID = 27
	
		-- Actualizando el puerto de destino
		--UPDATE LCA.DBO.Orders SET OrderTypeID3=@PortId WHERE orderid in (SELECT DISTINCT OrderID FROM #TB_OrderID) AND (OrderTypeID3 IS NULL  AND @PortId IS NOT NULL)
		UPDATE LCA.DBO.Orders
		SET OrderTypeID3 = @PortId
		WHERE @PortId IS NOT NULL
		AND OrderID IN (
			SELECT DISTINCT OrderID 
			FROM #TB_OrderID
		)


	END
	ELSE
	BEGIN
		----------------------------- CUANDO ENVIAN CAJAS ---------------------------------
		-- SELECT PB.BoxNumber, PB.GoodsBinID, PB.PackedPalletID, @IDPPGB AS NEWGB
	
		UPDATE PB	SET 
			BoxComments6	= @BoxComments6			---ADD JH 20250619 NUEVA SOLICITUD PARA ACTUALIZAR BOXCOMMENTS3
		FROM [LCA].[dbo].[PackedBoxes] AS PB WITH(NOLOCK)
		INNER JOIN #TB_Boxes AS TBB ON PB.BoxNumber = TBB.BoxNumber AND PB.StatusID IN (25,27,75) ---Modify JH 20250619 0807 Por problemas de eliminar info de Bins cuando es shipped.

		----------------------------- CUANDO ENVIAN PALLETS ---------------------------------
		-- SELECT PB.BoxNumber, PB.GoodsBinID, PB.PackedPalletID, @IDPPGB AS NEWGB
    
		UPDATE PB SET
			BoxComments6	= @BoxComments6			---ADD JH 20250619 NUEVA SOLICITUD PARA ACTUALIZAR BOXCOMMENTS3
		FROM        #TB_Pallets                    AS TBP
		INNER JOIN  [LCA].[dbo].[PackedBoxes]      AS PB WITH(NOLOCK)    ON PB.PackedPalletID = TBP.PalletID AND PB.StatusID IN (25,27,75) ---Modify JH 20250619 0807 Por problemas de eliminar info de Bins cuando es shipped.
		LEFT JOIN   [LCA].[dbo].[DropDownValues3]  AS DDV3 WITH(NOLOCK)  ON PB.BoxTagID = DDV3.DropDownValueID 
		WHERE (CASE WHEN  TBP.Tag IS NULL THEN 1
				  WHEN RIGHT(DDV3.DropDownValue,3) = TBP.Tag THEN 1
				  ELSE 0 END ) = 1 
	END

    DROP TABLE IF EXISTS #Response;

    CREATE TABLE #Response (
        ppgb NVARCHAR(100),
        pppa NVARCHAR(MAX),
        code NVARCHAR(MAX),
        flag BIT,
        Msg NVARCHAR(200),
        FinalComponent NVARCHAR(100)
    );

    INSERT INTO #Response (ppgb, pppa, code, flag, Msg, FinalComponent)
    VALUES (
        @ppgb,
        @pppa,
        @code,
        1,                      -- flag = true
        'Se escaneo con exito',
        '[Completed]'
    );

    SELECT *
    FROM #Response
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;

  END TRY
  BEGIN CATCH
    DROP TABLE IF EXISTS #Response2;

    CREATE TABLE #Response2 (
        ppgb NVARCHAR(100),
        pppa NVARCHAR(MAX),
        code NVARCHAR(MAX),
        flag BIT,
        Msg NVARCHAR(200),
        FinalComponent NVARCHAR(100)
    );

    INSERT INTO #Response2 (ppgb, pppa, code, flag, Msg, FinalComponent)
    VALUES (
        @ppgb,
        @pppa,
        @code,
        0,                      -- flag = true
        'No se pudo actualizar',
        '[DataBase]'
    );

    SELECT *
    FROM #Response2
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
  END CATCH

END
