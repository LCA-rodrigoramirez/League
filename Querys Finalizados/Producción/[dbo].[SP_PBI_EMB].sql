USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[SP_PBI_EMB]    Script Date: 22/07/2026 03:47:23 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_PBI_EMB]
AS
BEGIN

    SET NOCOUNT ON;
	--AQUI VA EL SELECT PARA LA CONSULTA
DECLARE @HoraInicioDia      time(7) = '06:00:00';
DECLARE @HoraMaximaTurnoC   time(7) = '06:15:00';

SELECT 
     [Date]             = emb.[ChangeDate]

    ,[DateAdjust]       = FechaOperativa.DateAdjust

    ,[PO Number]        = emb.[PONumber]
    ,[MO]               = emb.[ManufactureNumber]
    ,[Bundle Barcode]   = emb.[PPBU]
    ,[Task]             = emb.[TaskName]
    ,[Style]            = emb.[StyleNumber]
    ,[Color]            = emb.[StyleColorName]
    ,[Size]             = emb.[GarmentSize]
    ,[Make]             = emb.[QuantityOrdered]
    ,[Embroidery]       = emb.[Quantity]
    ,[Op_name]          = emb.[CompanyName]
    ,[ID_Modulo]        = md.ID

	 -- CASE PARA FECHAS ANTES DE MAY-26
    ,[Turno]            =
        CASE 
            WHEN emb.ChangeDate < '2026-05-04'
                THEN 
                    CASE 
                        WHEN CAST(emb.ChangeDate AS time) >= '06:00:00'
                         AND CAST(emb.ChangeDate AS time) <  '18:00:00'
                            THEN 'Dia'
                        ELSE 'Noche'
                    END
            ELSE tr.PowerBITurno
        END

    ,[Stitches]         = stc.StitchCount
    ,[Total Stitch]     = emb.Quantity * stc.StitchCount

    ,[Category3]        =
        CASE 
            WHEN lam.AppliqueMaterial = 'Direct'
              OR lam.AppliqueMaterial IS NULL
                THEN 'Direct'
            ELSE 'LBA'
        END

    ,[Applique]         =
        CASE 
            WHEN
                CASE 
                    WHEN lam.AppliqueMaterial = 'Direct'
                      OR lam.AppliqueMaterial IS NULL
                        THEN 'Direct'
                    ELSE 'LBA'
                END = 'Direct'
                THEN 0
            ELSE
                CASE 
                    WHEN ISNULL(app.Appliques, 0) = 0
                        THEN 1
                    ELSE app.Appliques
                END
        END

    ,[Garment]          =
        CASE 
            WHEN emb.[TaskName] IN ('Finish Embroidery 1')
                THEN emb.Quantity
            ELSE 0
        END

    ,[Average Stitch]   =
        CASE 
            WHEN emb.[Quantity] = 0
                THEN 0
            ELSE
                (emb.Quantity * stc.StitchCount) / emb.[Quantity]
        END

    ,stc.LogoStyleEMB

    ,[AppliqueMaterial] =
        CASE 
            WHEN
                CASE 
                    WHEN lam.AppliqueMaterial = 'Direct'
                      OR lam.AppliqueMaterial IS NULL
                        THEN 'Direct'
                    ELSE 'LBA'
                END = 'Direct'
                THEN 'Direct'
            ELSE lam.AppliqueMaterial
        END

FROM [AppsLCA].[dbo].[PBI_Embroidery_HW] AS emb WITH(NOLOCK)

--=========================================================
-- MÓDULO
--=========================================================
LEFT JOIN [192.168.1.53].[AppsLCA].[dbo].[TV_Modulos] AS md WITH(NOLOCK)
    ON emb.CompanyName = md.Modulo
   AND md.Area_ID = 4

--=========================================================
-- FECHA Y HORA NATURAL DEL ESCANEO
--=========================================================
CROSS APPLY
(
    SELECT
         FechaNatural = CAST(emb.ChangeDate AS date)
        ,HoraEscaneo  = CAST(emb.ChangeDate AS time(7))
) AS FechaBase

--=========================================================
-- REVISA SI EL MÓDULO TENÍA TURNO C EL DÍA ANTERIOR
--=========================================================
OUTER APPLY
(
    SELECT TOP (1)
         ScheduleID    = gsC.ID
        ,ScheduleDate  = gsC.ScheduleDate
        ,TurnoID       = gsC.Turno_ID
        ,PowerBITurno  = trC.PowerBITurno

    FROM [192.168.1.53].[AppsLCA].[dbo].[TV_Cal_GroupSchedule] AS gsC WITH(NOLOCK)

    INNER JOIN [192.168.1.53].[AppsLCA].[dbo].[TV_Cal_Turnos] AS trC WITH(NOLOCK)
        ON trC.ID = gsC.Turno_ID

    WHERE gsC.Modulo_ID = md.ID

      AND gsC.ScheduleDate =
          DATEADD(DAY, -1, FechaBase.FechaNatural)

      AND trC.PowerBITurno = 'C'

      AND gsC.Status = 1

    ORDER BY gsC.ID DESC
) AS TurnoCAnterior

--=========================================================
-- CÁLCULO CENTRALIZADO DE DATEADJUST
--=========================================================
CROSS APPLY
(
    SELECT
        DateAdjust =
            CASE
                -- Escaneos antes de las 6:00 pertenecen al día anterior
                WHEN FechaBase.HoraEscaneo < @HoraInicioDia
                    THEN DATEADD(DAY, -1, FechaBase.FechaNatural)

                -- Excepción:
                -- De 6:00 a 6:15 y existía turno C el día anterior
                WHEN FechaBase.HoraEscaneo >= @HoraInicioDia
                 AND FechaBase.HoraEscaneo <= @HoraMaximaTurnoC
                 AND TurnoCAnterior.ScheduleID IS NOT NULL
                    THEN DATEADD(DAY, -1, FechaBase.FechaNatural)

                -- Los demás pertenecen al día natural
                ELSE FechaBase.FechaNatural
            END
) AS FechaOperativa

--=========================================================
-- CALENDARIO DEL TURNO SEGÚN DATEADJUST
--=========================================================
LEFT JOIN [192.168.1.53].[AppsLCA].[dbo].[TV_Cal_GroupSchedule] AS gs WITH(NOLOCK)
    ON md.ID = gs.Modulo_ID
   AND gs.ScheduleDate = FechaOperativa.DateAdjust
   AND gs.Status = 1

LEFT JOIN [192.168.1.53].[AppsLCA].[dbo].[TV_Cal_Turnos] AS tr WITH(NOLOCK)
    ON tr.ID = gs.Turno_ID

--=========================================================
-- TABLAS DE PRODUCCIÓN
--=========================================================
LEFT JOIN AppsLCA.dbo.PBI_EMB_StitchesLogobyTask AS stc WITH(NOLOCK)
    ON emb.PONumber = stc.PONumber
   AND emb.TaskName = stc.TaskName

LEFT JOIN
(
    SELECT
         PONumber
        ,TaskName
        ,MAX(Appliques) AS Appliques

    FROM [AppsLCA].[dbo].[PBI_EMB_AppliquebyTaskLoc] WITH(NOLOCK)

    GROUP BY
         PONumber
        ,TaskName
) AS app
    ON app.PONumber = emb.PONumber
   AND app.TaskName = emb.TaskName

LEFT JOIN [AppsLCA].[dbo].[PBI_EMB_LogoApliqueMaterial] AS lam WITH(NOLOCK)
    ON stc.LogoStyleEMB = lam.LogoStyle

WHERE emb.TaskName IN
(
     'Finish Embroidery 1'
    ,'Finish Embroidery 2'
    ,'Finish Embroidery 3'
    ,'Finish Embroidery 4'
    ,'Finish Embroidery 5'
    ,'Finish Embroidery 6'
    ,'Finish Embroidery 7'
    ,'Finish Embroidery 8'
    ,'Finish Embroidery 9'
    ,'Finish Embroidery 10'
)

--AND emb.ChangeDate = '2026-07-14 06:06:22.000'

ORDER BY emb.ChangeDate DESC

END
