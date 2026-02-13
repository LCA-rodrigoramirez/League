USE [LCA]
GO
/****** Object:  StoredProcedure [dboReaders].[Sp_GetEffIncentByORD_Embroidery]    Script Date: 12/08/2025 02:50:14 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dboReaders].[Sp_GetEffIncentByORD_Embroidery_BK20250815]
	-- Add the parameters for the stored procedure here
--declare	@ORD varchar(20) = '2417919'
@ORD varchar(20) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON

-- declare	@ORD varchar(20) = '3505280'

DROP TABLE IF EXISTS #TB_DATA_ORD
DROP TABLE IF EXISTS #TB_SPLIT

----------------------------------------------------- DATA COMPLETA POR ORD ---------------------------------------------------------------

SELECT
	mo.manufacturenumber as MO 
	,COALESCE(ord.PONumber, od.PONumber) PO
	,COALESCE(ord.Comments7, od.Comments7) as Dimensions
	,COALESCE(ord.Comments26, od.Comments26) as Code  --Descomponer valores
	,COALESCE(ord.Comments27, od.Comments27) as Stitches
	,COALESCE(ord.Comments25, od.Comments25) as SequenceQty
	,COALESCE(ord.comments28, od.comments28) as MachineNumber
	,DD5.[Description] as LocationDesc --Descomponer Valores
	,mo.QuantityOrdered as CANTIDAD
	,sn.StatusName as [STATUS]
	,case when mo.Numeric2 is null  then round(isnull(mo.Numeric2,0.0),1)
			when len(mo.Numeric2) > 3 then 0.0
			when mo.Numeric2 is not null and Len(mo.Numeric2)<=3  then round(isnull(mo.Numeric2,0.0),1)
			else 0.0
	end as PANTALLAS	 
	--,mo.Numeric4 as VUELTA1
	--,mo.Numeric5 as VUELTA2
	--,CASE WHEN mo.Numeric6 IS NULL THEN 0 ELSE mo.Numeric6 END  as VUELTA3
	,ad.CompanyName as Press
	--,ISNULL(mo.SewLocationID,0) as EQ1
	--,ISNULL(mo.ScreenPrintLocationID,0) as EQ2
	--,isnull(mo.EmbroideryLocationID,0) as EQ3
	,DD3.DropDownValue AS ProductionStatus
	,st.StyleNumber as StyleNumber
	,mo.ManufactureID
	,COALESCE(ord.OrderID,od.OrderID) AS OrderID

INTO #TB_DATA_ORD

FROM (SELECT StatusID FROM StatusNames with (nolock) WHERE StatusID IN(10, 40, 47, 48, 49, 51, 53, 55, 67, 78,90)) AS STN
INNER JOIN StatusNames 			AS SN 	WITH(NOLOCK) ON STN.StatusID = SN.StatusID
INNER JOIN ManufactureOrders 	AS MO 	WITH(NOLOCK) ON SN.StatusID = MO.StatusID
INNER JOIN Orders				AS ord	WITH(NOLOCK) ON MO.OrderID = Ord.OrderID AND (ord.PONumber LIKE 'ORD%' or ord.PONumber like 'PO%')
INNER JOIN OrderItems			AS OI	WITH(NOLOCK) ON MO.FirstOrderItemID = oi.OrderItemID
INNER JOIN Orders				AS od	WITH(NOLOCK) ON OI.OrderID = Od.OrderID AND (OD.PONumber LIKE 'ORD%' or OD.PONumber like 'PO%')
LEFT  JOIN OrderTypes			AS OT	WITH(NOLOCK) ON COALESCE(Ord.OrderTypeID, OD.OrderTypeID) = ot.OrderTypeID
LEFT  JOIN DropDownValues5		AS DD5	WITH(NOLOCK) ON COALESCE(ord.OrderTypeID4, OD.OrderTypeID4) = DD5.DropDownValueID
INNER JOIN Styles				AS ST	WITH(NOLOCK) ON OI.StyleID = ST.StyleID
LEFT  JOIN Addresses			AS AD	WITH(NOLOCK) ON MO.SewLocationID = AD.AddressID
LEFT  JOIN DropDownValues3 		AS DD3  WITH(NOLOCK) ON mo.ProductionStatusID = DD3.DropDownValueID

WHERE (ord.PONumber = CONCAT('ORD0',@ORD) or ord.PONumber = CONCAT('ORD-',@ORD) or ord.PONumber = CONCAT('ORD',@ORD)  or
				ord.PONumber = CONCAT('PO0',@ORD)  or ord.PONumber = CONCAT('PO-',@ORD)  or ord.PONumber = CONCAT('PO',@ORD)	 )


---------------- SEPARACION DE LOCALIDADES, CODE, STITCHES, SEQUENCE, DIMENSIONS Y MANCHINES EN VARIAS COLUMNAS ----------------

SELECT
    t.OrderID,
    ISNULL(LTRIM(RTRIM(jd.value)),'') 				AS Dimensions,
	ISNULL(LTRIM(RTRIM(jc.value)),'') 				AS Code,
	ISNULL(CONCAT('Code', jc.[key] + 1),'')			AS TYPECode,
    ISNULL(LTRIM(RTRIM(js.value)),'') 				AS Stitches,
    ISNULL(LTRIM(RTRIM(jq.value)),'') 				AS SequenceQty,
    ISNULL(LTRIM(RTRIM(jm.value)),'') 				AS MachineNumber,
    ISNULL(LTRIM(RTRIM(jl.value)),'') 				AS LocationDesc,
	ISNULL(CONCAT('LocationDesc', jl.[key] + 1),'') AS TYPELocationDesc,
	jl.[key] + 1           							AS TaskWF,
	CAST(NULL AS VARCHAR(30)) 						AS TaskName,
    ISNULL(LTRIM(RTRIM(left(ja.value,1))),'') 		AS Appliques

INTO #TB_SPLIT
FROM #TB_DATA_ORD t
-- 1) Expandimos la columna ancla (LocationDesc)
CROSS APPLY OPENJSON(
    '["' + REPLACE(STRING_ESCAPE(ISNULL(t.LocationDesc,''),  'json'), ',', '","') + '"]'
) AS jl
-- 2) Tomamos el elemento con la misma clave en cada columna (permitiendo faltantes con OUTER APPLY)
OUTER APPLY (
    SELECT value FROM OPENJSON('["' + REPLACE(STRING_ESCAPE(ISNULL(t.Dimensions,''),    'json'), ',', '","') + '"]')
    WHERE [key] = jl.[key]
) AS jd
OUTER APPLY (
    SELECT value,[key] FROM OPENJSON('["' + REPLACE(STRING_ESCAPE(ISNULL(t.Code,''),          'json'), ',', '","') + '"]')
    WHERE [key] = jl.[key]
) AS jc
OUTER APPLY (
    SELECT value FROM OPENJSON('["' + REPLACE(STRING_ESCAPE(ISNULL(t.Stitches,''),      'json'), ',', '","') + '"]')
    WHERE [key] = jl.[key]
) AS js
OUTER APPLY (
    SELECT value FROM OPENJSON('["' + REPLACE(STRING_ESCAPE(ISNULL(t.SequenceQty,''),   'json'), ',', '","') + '"]')
    WHERE [key] = jl.[key]
) AS jq
OUTER APPLY (
    SELECT value FROM OPENJSON('["' + REPLACE(STRING_ESCAPE(ISNULL(t.MachineNumber,''), 'json'), ',', '","') + '"]')
    WHERE [key] = jl.[key]
) AS jm
OUTER APPLY (
    SELECT value FROM OPENJSON('["' + REPLACE(STRING_ESCAPE(ISNULL(t.Code,''),          'json'), ',', '","') + '"]')
    WHERE [key] = jl.[key]
) AS ja


--------------------------------------- ACTUALIZANDO TASK NAME SEGUN CADA LOCALIDAD --------------------------------------

UPDATE TBS SET
TBS.TaskName = Task.TaskName
-- SELECT *
FROM #TB_DATA_ORD AS TDO
INNER JOIN
(
	SELECT  DISTINCT
		TDO.ManufactureID, TDO.OrderID,WT.TaskName
	FROM #TB_DATA_ORD AS TDO
	INNER JOIN dbo.ManufactureOrders AS MO  WITH(NOLOCK) ON TDO.ManufactureID = MO.ManufactureID
	INNER JOIN dbo.WorkFlows		 AS WF  WITH(NOLOCK) ON WF.ManufactureID = MO.ManufactureID
	INNER JOIN dbo.WorkTasks		 AS WT  WITH(NOLOCK) ON WF.WorkFlowID = WT.WorkFlowID AND WT.TaskName LIKE 'Finish Embro%'
	INNER JOIN dbo.WorkTransactions	 AS WTR WITH(NOLOCK) ON WT.TaskID = WTR.TaskID
) AS Task ON TDO.ManufactureID = Task.ManufactureID
LEFT JOIN #TB_SPLIT AS TBS ON Task.OrderID = TBS.OrderID
WHERE TBS.TaskWF = RIGHT(Task.TaskName,1)


-------------------------------------- CONSULTA FINAL DEVUELTA A LA HOJA ESTÁNDAR -----------------------------------------
select 
	tout.MO
	,tout.PO 
	,tout.[STATUS]
	,tout.CANTIDAD
    ,tout.LocationDesc
	,tout.Code
    ,tout.TypeCode
	,tout.Dimensions
	,tout.Stitches
    ,tout.SequenceQty
	,tout.Appliques
    --,concat('Bordadora #',tout.MachineNumber) as MachineNumber
	--,concat('Bordadora #',REPLACE(STR(tout.MachineNumber,2),' ','0')) as MachineNumber
	, case when len(ltrim(tout.MachineNumber))<3 then 
		concat('Bordadora #',RIGHT(REPLICATE('0',2)+tout.MachineNumber,2)) 
		else 
		concat('Bordadora #',RIGHT(REPLICATE('0',3)+tout.MachineNumber,3)) 
		end 
		as MachineNumber
	
    --,tout.TYPEEQ
    ,tout.TYPELocationDesc
    --,tout.TYPEPANTALLAS

	-- ,tout.LOCALIDAD
	--,tout.PANTALLAS
	-- ,tout.VUELTAS
	--,isnull(ad.CompanyName,'') as Prensa
	--,isnull(ad.Comments,'') as TypeMachine 
	--,	   (Select SAM.[TiempoSetup]    from [AppsLCA].[dbo].[vw_ScreePrintSAMs] SAM where SAM.[COD_SAM] = CONCAT(ltrim(rtrim(ad.Comments)), tout.LOCALIDAD, tout.PANTALLAS,tout.VUELTAS) ) as TiempoSeteo
	--,round((Select SAM.[TiempoCicloMin] from [AppsLCA].[dbo].[vw_ScreePrintSAMs] SAM where SAM.[COD_SAM] = CONCAT(ltrim(rtrim(ad.Comments)), tout.LOCALIDAD, tout.PANTALLAS,tout.VUELTAS)),4) as TiempoCiclomin
	,tout.ProductionStatus
	--,case when isnull(ad.Comments,'') = 'Manual' and tout.PANTALLAS > tout.VUELTAS  then 'NO APLICA' WHEN tout.PANTALLAS = tout.VUELTAS THEN '' ELSE 'APLICA' END as Aplica  
	,tout.TaskName
	  ,NULL Keys
	  ,tout.StyleNumber
	  ,'MOID'+cast(tout.ManufactureID as varchar(20)) as ManufactureID
	  ,tout.OrderID

	from(

	select 
			TB.MO
			,TB.PO
			,TB.CANTIDAD
			,TS.Dimensions
			,TS.SequenceQty
			,TS.Stitches
			,TS.MachineNumber
			,TS.Code
			,TS.TYPECode
			,TS.LocationDesc
			,TS.TYPELocationDesc
			,ISNULL(TS.TaskName,'PENDIENTE DE BORDADO') AS TaskName
            ,TS.Appliques
			,TB.[STATUS]
			,TB.ProductionStatus 
			,TB.StyleNumber
			,TB.ManufactureID
			,TB.OrderID
	from #TB_DATA_ORD AS tb
	inner join #TB_SPLIT as ts on tb.OrderID = ts.OrderID

	--select distinct mfgordertypeid from ManufactureOrders

	
--    AND right(TYPEVUELTA, 1) = right(TYPEPANTALLAS, 1)
--    AND right(TYPEVUELTA, 1) = right(TYPEEQ, 1)
--    AND LOCALIDAD <> ''

--    right(TYPEVUELTA, 1) = right(TYPELOCALIDAD, 1)
--    AND right(TYPEVUELTA, 1) = right(TYPEPANTALLAS, 1)
--    AND right(TYPEVUELTA, 1) = right(TYPEEQ, 1)
--    AND LOCALIDAD <> ''

--    ORDER BY MO


   ) as tout
   WHERE LocationDesc <> ''
   --left  join lca.dbo.Addresses as ad on ad.AddressID= tout.prensa

END

