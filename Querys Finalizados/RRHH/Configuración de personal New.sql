USE AppsLCA

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ALTER PROCEDURE [dbo].[SP_Modules_PersonalConfiguration]
--      @DateReport DATE
--     ,@Module VARCHAR(100)
-- 	,@Area	 VARCHAR(100)
-- 	,@process NVARCHAR(10)
-- AS
-- BEGIN
    SET NOCOUNT ON;

    -- Asegurar idioma español para días y meses
--    SET LANGUAGE English;

DECLARE @process AS VARCHAR(100) = 'report'
DECLARE @Area AS VARCHAR(100) = 'Embroidery Headwear'
DECLARE @DateReport AS DATE = '2025-11-07'
DECLARE @Module AS VARCHAR(100) = 'ALL'



	IF @process = 'areas.list'
	BEGIN
			SELECT DISTINCT 
				 [Areas]	= AD.Comments6
			FROM lca.dbo.Addresses	AS AD	WITH(NOLOCK)
			WHERE AD.Comments6 IS NOT NULL
	END

	IF @process = 'areas'
	BEGIN
			IF @Area = 'ALL'
			BEGIN
				SELECT DISTINCT 
					  [Modules]	= AD.CompanyName
					 ,[Area]	= AD.Comments6
				FROM lca.dbo.Addresses	AS AD	WITH(NOLOCK)
				WHERE AD.Comments6 IS NOT NULL
			END
			ELSE
			BEGIN
				SELECT DISTINCT 
					  [Modules]	= AD.CompanyName
					 ,[Area]	= AD.Comments6
				FROM lca.dbo.Addresses	AS AD	WITH(NOLOCK)
				WHERE AD.Comments6 = @Area
			END
	END

	IF @process = 'report'
	BEGIN

	
			/************************************ 
			 ***** BORRAR TABLAS TEMPORALES *****
			 ************************************/

			DROP TABLE IF EXISTS #EmplData				--- DATA DE INGRESO Y SALIDA DE LOS EMPLEADOS EN LA APP
			DROP TABLE IF EXISTS #Conteo				--- CUENTA LOS COMENTARIOS QUE HAN DECLARADO (IMPORTANTE PARA GENERAR UNA LINEA MÁS DE SER NECESARIO)
			DROP TABLE IF EXISTS #AsignacionesExtra		--- SI HAY COMENTARIOS EN AMBOS REGISTROS DE ENTRADA Y SALIDA, ESTA TABLA SE LLENA PARA INSERTAR UN REGISTRO MÁS AL REPORTE FINAL
			DROP TABLE IF EXISTS #Emparejado			--- DATOS AGRUPADOS PARA IDENTIFICAR LA ENTRADA Y SALIDA Y ASI MOSTRAR LA HORA DE ENTRADA Y SALIDA EN TODOS LOS REGISTROS
			DROP TABLE IF EXISTS #Incapacidades			--- TRAE LOS REGISTROS DE INCAPACIDAD QUE SE HAYAN INGRESADO PARA MOSTRAR EN EL REPORTE HASTA QUE LLEGUE EL DÍA DE FIN DE LA ACCION

			/************************************ 
			 ***** BORRAR TABLAS TEMPORALES *****
			 ************************************/
	

			/**************************************************************
			 **************** CREACIÓN DE TABLAS TEMPORALES ***************
			 **************************************************************/


			--- TABLA BASE CON LOS REGISTROS DE ENTRADA Y SALIDA DE LOS EMEPLEADOS DURANTE EL DÍA
			CREATE TABLE #EmplData (
				 ID INT
				,InsertDate DATETIME
				,codEmp VARCHAR(10)
				,NombreEmpl VARCHAR(100)
				,DepEmpl VARCHAR(100)
				,CargEmpl VARCHAR(100)
				,Status_Reg VARCHAR(50)
				,Modulo VARCHAR(50)
				,Operador VARCHAR(10)
				,ScanNo INT
				,Fecha INT
				,Hora INT
				,Tipo VARCHAR(50)
				,Comment1 VARCHAR(255)
				,CommentsUsers VARCHAR(255)
				,RealModule VARCHAR(100)
				,Area VARCHAR(100)
				,CommentScan VARCHAR(255)
				,FechaDia DATE
				,EndActionDate DATE
				,ActionDays DECIMAL (5,2)
			)

			--- INDICE PARA MEJORAR LAS RELACIONES
			CREATE NONCLUSTERED INDEX IX_EmplData_codEmp_FechaDia ON #EmplData (codEmp, FechaDia)

			--- EN CASO DE REGISTRAR UNA INCAPACIDAD POR N CANTIDAD DE DIAS, NO SERÁ NECESARIO INGRESAR AL EMPLEADO CADA VEZ, EL REPORTE SE ENCARGARÁ DE MOSTRAR
			--- ESOS EMPLEADOS CON INCAPACIDAD HASTA QUE InsertDate SEA = EndActionDate

			CREATE TABLE #Incapacidades (
				 codEmp VARCHAR(10)
				,NombreEmpl VARCHAR(100)
				,DepEmpl VARCHAR(100)
				,InsertDate DATETIME
				,RealModule VARCHAR(100)
				,Area VARCHAR(100)
				,Asignacion VARCHAR(255)
				,FechaDia DATE
				,HoraEntrada VARCHAR(8)
				,HoraSalida VARCHAR(8)
				,DiaSemana VARCHAR(20)
				,FechaReporte VARCHAR(30)
				,EndActionDate DATE
				,ActionDays DECIMAL(5,2)
				,Horas_Extra VARCHAR(50)
				,Supervisor VARCHAR(50)
				,HorasTrabajadas DECIMAL(5,2)
				,HorasNormales DECIMAL(5,2)
				,Categoria VARCHAR(20)
			)

			--- INDICE PARA MEJORAR LAS RELACIONES

			CREATE NONCLUSTERED INDEX IX_Incapacidades_codEmp_FechaDia ON #Incapacidades (codEmp, FechaDia)

			--- CUENTA LOS COMENTARIOS POR AGRUPACION DE CodEmp y Fecha, ESTO ES IMPORTANTE PARA EL REPORTE FINAL Y UN CAMPO EN ESPECÍFICO
			CREATE TABLE #Conteo (
				 codEmp VARCHAR(10)
				,FechaDia DATE
				,Comentarios INT
				,RealModule VARCHAR(100)
				,NombreEmpl VARCHAR(100)
				,DepEmpl VARCHAR(100)
				,Area VARCHAR(100)
				,InsertDateEntrada DATETIME
				,HoraEntrada VARCHAR(8)
				,HoraSalida VARCHAR(8)
				,DiaSemana VARCHAR(20)
				,FechaReporte VARCHAR(30)
				,HorasTrabajadas DECIMAL(5,2)
				,HorasNormales DECIMAL(5,2)
				,Categoria VARCHAR(20)
			)

			--- INDICE PARA MEJORAR RELACIONES

			CREATE NONCLUSTERED INDEX IX_Conteo_codEmp_FechaDia ON #Conteo (codEmp, FechaDia)

			--- EN CASO QUE #Conteo DIGA QUE HAYA COMENTARIOS EN LOS REGISTROS DE ENTRADA Y SALIDA, ESTA TABLA INSERTARÁ UN CAMPO PARA MOSTRAR EN EL REPORTE FINAL

			CREATE TABLE #AsignacionesExtra (
				 codEmp VARCHAR(10)
				,NombreEmpl VARCHAR(100)
				,DepEmpl VARCHAR(100)
				,InsertDate DATETIME
				,RealModule VARCHAR(100)
				,Area VARCHAR(100)
				,Asignacion VARCHAR(255)
				,FechaDia DATE
				,HoraEntrada VARCHAR(8)
				,HoraSalida VARCHAR(8)
				,DiaSemana VARCHAR(20)
				,FechaReporte VARCHAR(30)
				,Horas_Extra VARCHAR(50)
				,Supervisor VARCHAR(50)
				,HorasTrabajadas DECIMAL(5,2)
				,HorasNormales DECIMAL(5,2)
				,Categoria VARCHAR(20)
			)

			--- INDICE PARA MEJORAR REALCIONES

			CREATE NONCLUSTERED INDEX IX_Asignaciones_codEmp_FechaDia ON #AsignacionesExtra (codEmp, FechaDia)

			--- LOS DATOS OBTENIDOS EN #EmplData SE AGRUPAN EN #Emparejado PARA PODER IDENTIFICAR CORRECTAMENTE EL REGISTRO DE ENTRADA Y SALIDA (PAREJA DE DATOS),
			--- IDENTIFICAR SI HAY REGISTROS QUE NO TIENEN SALIDA Y AGRUPARLOS DE FORMA CORRECTA Y EL OBJETIVO FINAL ES ASIGNAR LA HORA DE ENTRADA Y SALIDA A LA PAREJA DE DATOS,
			--- LO CUAL SE LOGRA CON UN UPDATE LUEGO DEL INSERT

			CREATE TABLE #Emparejado (
				 ID INT
				,InsertDate DATETIME
				,codEmp VARCHAR(10)
				,NombreEmpl VARCHAR(100)
				,DepEmpl VARCHAR(100)
				,CargEmpl VARCHAR(100)
				,Status_Reg VARCHAR(50)
				,Modulo VARCHAR(50)
				,Operador VARCHAR(10)
				,ScanNo INT
				,Fecha INT
				,Hora INT
				,Tipo VARCHAR(50)
				,Comment1 VARCHAR(255)
				,CommentsUsers VARCHAR(255)
				,RealModule VARCHAR(100)
				,Area VARCHAR(100)
				,CommentScan VARCHAR(255)
				,FechaDia DATE
				,HoraEntrada DATETIME
				,HoraSalida DATETIME
				,DiaSemana VARCHAR(20)
				,FechaReporte VARCHAR(30)
				,HorasTrabajadas DECIMAL(5,2)
				,HorasNormales DECIMAL(5,2)
				,Categoria VARCHAR(20)
				,rn INT
				,Comentarios INT
				,EstadoPar VARCHAR(20)
				,EndActionDate DATE
				,ActionDays DECIMAL(5,2)
			)

			/**************************************************************
			 **************** CREACIÓN DE TABLAS TEMPORALES ***************
			 **************************************************************/

			/********************************************************************
			 **************** INSERT DE DATA EN TABLAS TEMPORALES ***************
			 ********************************************************************/

				--- DATOS BASE
			IF @Module = 'ALL'
			BEGIN
				IF @Area = 'ALL'
				BEGIN
					INSERT INTO #EmplData
					SELECT 
							 SMR.ID
							,CAST(CONCAT(
										LEFT([SMR].[Fecha],4)			----YEAR
										,'-'
										,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
										,'-'
										,RIGHT([SMR].[Fecha],2)			----DAY
										,' '	
										,LEFT([SMR].[Hora],2)			----HOUR
										,':'
										,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
										,':'
										,RIGHT([SMR].[Hora],2)			----SECOND
										,'.000'										
										)
							AS DATETIME) AS InsertDate
							,SMR.codEmp
							,SMR.NombreEmpl
							,SMR.DepEmpl
							,SMR.CargEmpl
							,SMR.Status_Reg
							,SMR.Modulo
							,SMR.Operador
							,SMR.ScanNo
							,SMR.Fecha
							,SMR.Hora
							,SMR.Tipo
							,SMR.Comment1
							,SMR.CommentsUsers
							,AD.CompanyName
							,AD.Comments6
							,ISNULL(SMC.Comment,'')
							,CASE 
								WHEN CONVERT(TIME, CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME)) < '05:00:00' THEN DATEADD(DAY, -1, CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE))
								ELSE CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE)
							 END AS FechaDia
							,EndActionDate
							,CASE WHEN EndActionDate IS NOT NULL THEN DATEDIFF(DAY, CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME), EndActionDate) ELSE NULL END as ActionDays

						FROM [AppsLCA].[LinkUp].[ScanModReg] SMR WITH(NOLOCK)
						LEFT JOIN LCA.dbo.Addresses AD WITH(NOLOCK) 
							ON 'PPAD'+LTRIM(STR(AD.AddressID+10000)) = SMR.Modulo
						LEFT JOIN [AppsLCA].[LinkUp].[ScanModReg_Details] SMD WITH(NOLOCK) 
							ON SMR.ID = SMD.ScanModRegID
						LEFT JOIN [AppsLCA].[LinkUp].[ScanModReg_Comments] SMC WITH(NOLOCK) 
							ON SMD.CommentId = SMC.Id
						WHERE
							SMR.InsertDate >= @DateReport 
							AND SMR.InsertDate < DATEADD(MINUTE, 360, CAST(DATEADD(DAY, 1, @DateReport) AS DATETIME))
				END
				ELSE
				BEGIN
						INSERT INTO #EmplData
						SELECT 
							 SMR.ID
							,CAST(CONCAT(
										LEFT([SMR].[Fecha],4)			----YEAR
										,'-'
										,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
										,'-'
										,RIGHT([SMR].[Fecha],2)			----DAY
										,' '	
										,LEFT([SMR].[Hora],2)			----HOUR
										,':'
										,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
										,':'
										,RIGHT([SMR].[Hora],2)			----SECOND
										,'.000'										
										)
							AS DATETIME) AS InsertDate
							,SMR.codEmp
							,SMR.NombreEmpl
							,SMR.DepEmpl
							,SMR.CargEmpl
							,SMR.Status_Reg
							,SMR.Modulo
							,SMR.Operador
							,SMR.ScanNo
							,SMR.Fecha
							,SMR.Hora
							,SMR.Tipo
							,SMR.Comment1
							,SMR.CommentsUsers
							,AD.CompanyName
							,AD.Comments6
							,ISNULL(SMC.Comment,'')
							,CASE 
								WHEN CONVERT(TIME, CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME)) < '05:00:00' THEN DATEADD(DAY, -1, CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE))
								ELSE CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE)
							 END AS FechaDia
							,EndActionDate
							,CASE 
								WHEN EndActionDate IS NOT NULL THEN DATEDIFF(DAY, CAST(CONCAT(
																								LEFT([SMR].[Fecha],4)			----YEAR
																								,'-'
																								,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																								,'-'
																								,RIGHT([SMR].[Fecha],2)			----DAY
																								,' '	
																								,LEFT([SMR].[Hora],2)			----HOUR
																								,':'
																								,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																								,':'
																								,RIGHT([SMR].[Hora],2)			----SECOND
																								,'.000'										
																								)
																					AS DATETIME), EndActionDate) 
								ELSE NULL 
							END as ActionDays

						FROM [AppsLCA].[LinkUp].[ScanModReg] SMR WITH(NOLOCK)
						LEFT JOIN LCA.dbo.Addresses AD WITH(NOLOCK) 
							ON 'PPAD'+LTRIM(STR(AD.AddressID+10000)) = SMR.Modulo
						LEFT JOIN [AppsLCA].[LinkUp].[ScanModReg_Details] SMD WITH(NOLOCK) 
							ON SMR.ID = SMD.ScanModRegID
						LEFT JOIN [AppsLCA].[LinkUp].[ScanModReg_Comments] SMC WITH(NOLOCK) 
							ON SMD.CommentId = SMC.Id
						WHERE
							SMR.InsertDate >= @DateReport 
							AND SMR.InsertDate < DATEADD(MINUTE, 360, CAST(DATEADD(DAY, 1, @DateReport) AS DATETIME))
							AND AD.Comments6 = @Area
				END

			END
			ELSE
			BEGIN
				INSERT INTO #EmplData
					SELECT 
						 SMR.ID
						,CAST(CONCAT(
									LEFT([SMR].[Fecha],4)			----YEAR									
									,'-'
									,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
									,'-'
									,RIGHT([SMR].[Fecha],2)			----DAY
									
									,' '	
									,LEFT([SMR].[Hora],2)			----HOUR
									,':'
									,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
									,':'
									,RIGHT([SMR].[Hora],2)			----SECOND
									,'.000'										
									)
						AS DATETIME) AS InsertDate
					
						,SMR.codEmp
						,SMR.NombreEmpl
						,SMR.DepEmpl
						,SMR.CargEmpl
						,SMR.Status_Reg
						,SMR.Modulo
						,SMR.Operador
						,SMR.ScanNo
						,SMR.Fecha
						,SMR.Hora
						,SMR.Tipo
						,SMR.Comment1
						,SMR.CommentsUsers
						,AD.CompanyName
						,AD.Comments6
						,ISNULL(SMC.Comment,'')
						,CASE 
								WHEN CONVERT(TIME, CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME)) < '05:00:00' THEN DATEADD(DAY, -1, CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE))
								ELSE CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE)
							 END AS FechaDia
							,EndActionDate
							,CASE 
								WHEN EndActionDate IS NOT NULL THEN DATEDIFF(DAY, CAST(CONCAT(
																								LEFT([SMR].[Fecha],4)			----YEAR
																								,'-'
																								,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																								,'-'
																								,RIGHT([SMR].[Fecha],2)			----DAY
																								,' '	
																								,LEFT([SMR].[Hora],2)			----HOUR
																								,':'
																								,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																								,':'
																								,RIGHT([SMR].[Hora],2)			----SECOND
																								,'.000'										
																								)
																					AS DATETIME), EndActionDate) 
								ELSE NULL 
							END as ActionDays

					FROM [AppsLCA].[LinkUp].[ScanModReg] SMR WITH(NOLOCK)
					LEFT JOIN LCA.dbo.Addresses AD WITH(NOLOCK) 
						ON 'PPAD'+LTRIM(STR(AD.AddressID+10000)) = SMR.Modulo
					LEFT JOIN [AppsLCA].[LinkUp].[ScanModReg_Details] SMD WITH(NOLOCK) 
						ON SMR.ID = SMD.ScanModRegID
					LEFT JOIN [AppsLCA].[LinkUp].[ScanModReg_Comments] SMC WITH(NOLOCK) 
						ON SMD.CommentId = SMC.Id
					WHERE
						SMR.InsertDate >= @DateReport
						AND SMR.InsertDate < DATEADD(MINUTE, 360, CAST(DATEADD(DAY, 1, @DateReport) AS DATETIME))
						AND CompanyName = @Module
				END
					

			--- INSERT INCAPACIDADES
			IF @Module = 'ALL'
			BEGIN
				IF @Area = 'ALL'
				BEGIN
					INSERT INTO #Incapacidades
						SELECT 
							 SMR.codEmp
							,SMR.NombreEmpl
							,SMR.DepEmpl
							,CAST(CONCAT(
										LEFT([SMR].[Fecha],4)			----YEAR
										,'-'
										,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
										,'-'
										,RIGHT([SMR].[Fecha],2)			----DAY
										,' '	
										,LEFT([SMR].[Hora],2)			----HOUR
										,':'
										,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
										,':'
										,RIGHT([SMR].[Hora],2)			----SECOND
										,'.000'										
										)
							AS DATETIME) AS InsertDate
							,SMC.Comment
							,AD.Comments6
							,SMC.Comment
							,NULL
							,NULL
							,NULL
							,DATENAME(WEEKDAY,
								CASE 
									WHEN CONVERT(TIME, CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME)) < '05:00:00'
										THEN DATEADD(DAY, -1, CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE))
									ELSE CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE)
								END
							 ) AS DiaSemana

							,FORMAT(
								CASE 
									WHEN CONVERT(TIME, CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME)) < '05:00:00'
										THEN DATEADD(DAY, -1, CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE))
									ELSE CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE)
								END,
								'd-MMMM-yyyy',
								'es-SV'
							 ) AS FechaReporte
							,EndActionDate
							,CASE 
								WHEN EndActionDate IS NOT NULL THEN DATEDIFF(DAY, DATEADD(DAY,-1,CAST(CONCAT(
																											LEFT([SMR].[Fecha],4)			----YEAR
																											,'-'
																											,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																											,'-'
																											,RIGHT([SMR].[Fecha],2)			----DAY
																											,' '	
																											,LEFT([SMR].[Hora],2)			----HOUR
																											,':'
																											,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																											,':'
																											,RIGHT([SMR].[Hora],2)			----SECOND
																											,'.000'										
																											)
																								AS DATETIME)), EndActionDate) 
								ELSE NULL 
							END as ActionDays
							,NULL
							,NULL
							,NULL
							,NULL
							,'DIRECTO' AS Categoria
						FROM [AppsLCA].[LinkUp].[ScanModReg] SMR WITH(NOLOCK)
						LEFT JOIN LCA.dbo.Addresses AD WITH(NOLOCK) 
							ON 'PPAD'+LTRIM(STR(AD.AddressID+10000)) = SMR.Modulo
						LEFT JOIN [AppsLCA].[LinkUp].[ScanModReg_Details] SMD WITH(NOLOCK) 
							ON SMR.ID = SMD.ScanModRegID
						LEFT JOIN [AppsLCA].[LinkUp].[ScanModReg_Comments] SMC WITH(NOLOCK) 
							ON SMD.CommentId = SMC.Id
						WHERE
						SMR.InsertDate < @DateReport
						AND	DATEDIFF(DAY, CAST(SMR.InsertDate AS DATE),@DateReport) <= 112
						AND DATEDIFF(DAY, CAST(SMD.EndActionDate AS DATE),@DateReport) <= 0 
				END
				ELSE
				BEGIN
					INSERT INTO #Incapacidades
						SELECT 
							 SMR.codEmp
							,SMR.NombreEmpl
							,SMR.DepEmpl
							,CAST(CONCAT(
										LEFT([SMR].[Fecha],4)			----YEAR
										,'-'
										,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
										,'-'
										,RIGHT([SMR].[Fecha],2)			----DAY
										,' '	
										,LEFT([SMR].[Hora],2)			----HOUR
										,':'
										,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
										,':'
										,RIGHT([SMR].[Hora],2)			----SECOND
										,'.000'										
										)
							AS DATETIME) AS InsertDate
							,SMC.Comment
							,AD.Comments6
							,SMC.Comment
							,NULL
							,NULL
							,NULL
							,DATENAME(WEEKDAY,
								CASE 
									WHEN CONVERT(TIME, CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME)) < '05:00:00'
										THEN DATEADD(DAY, -1, CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE))
									ELSE CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE)
								END
							 ) AS DiaSemana

							,FORMAT(
								CASE 
									WHEN CONVERT(TIME, CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME)) < '05:00:00'
										THEN DATEADD(DAY, -1, CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE))
									ELSE CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE)
								END,
								'd-MMMM-yyyy',
								'es-SV'
							 ) AS FechaReporte
							,EndActionDate
							,CASE WHEN EndActionDate IS NOT NULL THEN DATEDIFF(DAY, DATEADD(DAY,-1,CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME)), EndActionDate) ELSE NULL END as ActionDays
							,NULL
							,NULL
							,NULL
							,NULL
							,'DIRECTO' AS Categoria
						FROM [AppsLCA].[LinkUp].[ScanModReg] SMR WITH(NOLOCK)
						LEFT JOIN LCA.dbo.Addresses AD WITH(NOLOCK) 
							ON 'PPAD'+LTRIM(STR(AD.AddressID+10000)) = SMR.Modulo
						LEFT JOIN [AppsLCA].[LinkUp].[ScanModReg_Details] SMD WITH(NOLOCK) 
							ON SMR.ID = SMD.ScanModRegID
						LEFT JOIN [AppsLCA].[LinkUp].[ScanModReg_Comments] SMC WITH(NOLOCK) 
							ON SMD.CommentId = SMC.Id
						WHERE
						SMR.InsertDate < @DateReport
						AND	DATEDIFF(DAY, CAST(SMR.InsertDate AS DATE),@DateReport) <= 112
						AND DATEDIFF(DAY, CAST(SMD.EndActionDate AS DATE),@DateReport) <= 0 
						AND AD.Comments6 = @Area
				END

			END
			ELSE
			BEGIN

				INSERT INTO #Incapacidades
					SELECT 
						 SMR.codEmp
						,SMR.NombreEmpl
						,SMR.DepEmpl
						,CAST(CONCAT(
										LEFT([SMR].[Fecha],4)			----YEAR
										,'-'
										,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
										,'-'
										,RIGHT([SMR].[Fecha],2)			----DAY
										,' '	
										,LEFT([SMR].[Hora],2)			----HOUR
										,':'
										,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
										,':'
										,RIGHT([SMR].[Hora],2)			----SECOND
										,'.000'										
										)
							AS DATETIME) AS InsertDate
						,SMC.Comment
						,AD.Comments6
						,SMC.Comment
						,NULL
						,NULL
						,NULL
						,DATENAME(WEEKDAY,
							CASE 
								WHEN CONVERT(TIME, CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME)) < '05:00:00'
									THEN DATEADD(DAY, -1, CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE))
								ELSE CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE)
							END
						 ) AS DiaSemana

						,FORMAT(
							CASE 
								WHEN CONVERT(TIME, CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME)) < '05:00:00'
									THEN DATEADD(DAY, -1, CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE))
								ELSE CAST(CAST(CONCAT(
																LEFT([SMR].[Fecha],4)			----YEAR
																,'-'
																,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																,'-'
																,RIGHT([SMR].[Fecha],2)			----DAY
																,' '	
																,LEFT([SMR].[Hora],2)			----HOUR
																,':'
																,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																,':'
																,RIGHT([SMR].[Hora],2)			----SECOND
																,'.000'										
																)
													AS DATETIME) AS DATE)
							END,
							'd-MMMM-yyyy',
							'es-SV'
						 ) AS FechaReporte
						,EndActionDate
						,CASE 
							WHEN EndActionDate IS NOT NULL THEN DATEDIFF(DAY, DATEADD(DAY,-1,CAST(CONCAT(
																											LEFT([SMR].[Fecha],4)			----YEAR
																											,'-'
																											,SUBSTRING([SMR].[Fecha],5,2)	----MONTH
																											,'-'
																											,RIGHT([SMR].[Fecha],2)			----DAY
																											,' '	
																											,LEFT([SMR].[Hora],2)			----HOUR
																											,':'
																											,SUBSTRING([SMR].[Hora],3,2)		----MINUTE
																											,':'
																											,RIGHT([SMR].[Hora],2)			----SECOND
																											,'.000'										
																											)
																								AS DATETIME)), EndActionDate) 
							ELSE NULL 
						END as ActionDays
						,NULL
						,NULL
						,NULL
						,NULL
						,'DIRECTO' AS Categoria
					FROM [AppsLCA].[LinkUp].[ScanModReg] SMR WITH(NOLOCK)
					LEFT JOIN LCA.dbo.Addresses AD WITH(NOLOCK) 
						ON 'PPAD'+LTRIM(STR(AD.AddressID+10000)) = SMR.Modulo
					LEFT JOIN [AppsLCA].[LinkUp].[ScanModReg_Details] SMD WITH(NOLOCK) 
						ON SMR.ID = SMD.ScanModRegID
					LEFT JOIN [AppsLCA].[LinkUp].[ScanModReg_Comments] SMC WITH(NOLOCK) 
						ON SMD.CommentId = SMC.Id
					WHERE
					SMR.InsertDate < @DateReport
					AND	DATEDIFF(DAY, CAST(SMR.InsertDate AS DATE),@DateReport) <= 112
					AND CompanyName = @Module
					AND DATEDIFF(DAY, CAST(SMD.EndActionDate AS DATE),@DateReport) <= 0 

			END

			--- INSERT CONTEO

			INSERT INTO #Conteo
			SELECT 
				 codEmp
				,FechaDia
				,COUNT(CASE WHEN LEN(CommentScan) > 0 THEN 1 END) AS Comentarios
				,MAX(RealModule)
				,MAX(NombreEmpl)
				,MAX(DepEmpl)
				,MAX(Area)
				,MIN(InsertDate) AS InsertDateEntrada
				,FORMAT(MIN(InsertDate), 'HH:mm:ss') AS HoraEntrada
				,FORMAT(MAX(InsertDate), 'HH:mm:ss') AS HoraSalida
				,DATENAME(WEEKDAY,
				 CASE 
					WHEN CONVERT(TIME, MIN(InsertDate)) < '05:00:00' 
						THEN DATEADD(DAY, -1, CAST(MIN(InsertDate) AS DATE))
					ELSE CAST(MIN(InsertDate) AS DATE)
				 END
				 ) AS DiaSemana

				,FORMAT(
					CASE 
						WHEN CONVERT(TIME, MIN(InsertDate)) < '05:00:00' 
							THEN DATEADD(DAY, -1, CAST(MIN(InsertDate) AS DATE))
						ELSE CAST(MIN(InsertDate) AS DATE)
					END,
					'd-MMMM-yyyy',
					'es-SV'
				 ) AS FechaReporte

				,CAST(DATEDIFF(MINUTE, MIN(InsertDate), MAX(InsertDate)) / 60.0 AS DECIMAL(5,2)) AS HorasTrabajadas

				,CAST(
					CASE 
						WHEN DATENAME(WEEKDAY, MIN(InsertDate)) = 'viernes' THEN
							(DATEDIFF(MINUTE, '06:30:00', '15:05:00') - 45) / 60.0
						ELSE
							(DATEDIFF(MINUTE, '06:30:00', '16:05:00') - 45) / 60.0
					END
				 AS DECIMAL(5,2)) AS HorasNormales
				 ,'DIRECTO' AS Categoria
			FROM #EmplData
			GROUP BY codEmp, FechaDia


			--- ASIGNACIONES ADICIONALES SOLO SI HAY 2 COMENTARIOS
			INSERT INTO #AsignacionesExtra
			SELECT 
				 codEmp
				,NombreEmpl
				,DepEmpl
				,InsertDateEntrada
				,RealModule
				,Area
				,RealModule
				,FechaDia
				,HoraEntrada
				,HoraSalida
				,DiaSemana
				,FechaReporte
				,NULL
				,NULL
				,HorasTrabajadas
				,HorasNormales
				,Categoria
			FROM #Conteo
			WHERE Comentarios = 2

			--- INSERTAR CON EMPAREJAMIENTO
			INSERT INTO #Emparejado
			SELECT 
				 E.ID
				,E.InsertDate
				,E.codEmp
				,E.NombreEmpl
				,E.DepEmpl
				,E.CargEmpl
				,E.Status_Reg
				,E.Modulo
				,E.Operador
				,E.ScanNo
				,E.Fecha
				,E.Hora
				,E.Tipo
				,E.Comment1
				,E.CommentsUsers
				,E.RealModule
				,E.Area
				,E.CommentScan
				,E.FechaDia

				-- Emparejar entrada y salida por posición
				,CASE 
					WHEN ROW_NUMBER() OVER (PARTITION BY E.codEmp, E.FechaDia ORDER BY E.InsertDate) % 2 = 0
					AND CommentScan in ('INCAPACIDAD POR ENFERMEDAD', 'CONSULTA ISSS', 'PERMISO PERSONAL')
						THEN E.InsertDate
					WHEN ROW_NUMBER() OVER (PARTITION BY E.codEmp, E.FechaDia ORDER BY E.InsertDate) % 2 = 1 
					AND CommentScan in ('LLEGADA TARDE', 'LACTANCIA MATERNA','CONSULTA ISSS', 'PERMISO PERSONAL')
						THEN CONCAT(E.FechaDia, ' 06:40:00')
					WHEN ROW_NUMBER() OVER (PARTITION BY E.codEmp, E.FechaDia ORDER BY E.InsertDate) % 2 = 1 
						THEN E.InsertDate
					ELSE LAG(E.InsertDate) OVER (PARTITION BY E.codEmp, E.FechaDia ORDER BY E.InsertDate)
				 END AS HoraEntrada

				,CASE 
					WHEN ROW_NUMBER() OVER (PARTITION BY E.codEmp, E.FechaDia ORDER BY E.InsertDate) % 2 = 1 
					AND CommentScan in ('LLEGADA TARDE', 'LACTANCIA MATERNA','CONSULTA ISSS', 'PERMISO PERSONAL')
						THEN E.InsertDate
					WHEN ROW_NUMBER() OVER (PARTITION BY E.codEmp, E.FechaDia ORDER BY E.InsertDate) % 2 = 0
					AND CommentScan in ('INCAPACIDAD POR ENFERMEDAD', 'CONSULTA ISSS', 'PERMISO PERSONAL')
						THEN CONCAT(E.FechaDia,CASE 
										WHEN DATENAME(WEEKDAY, E.FechaDia) = 'viernes' THEN ' 15:05:00'
										ELSE ' 16:05:00' END)
					WHEN ROW_NUMBER() OVER (PARTITION BY E.codEmp, E.FechaDia ORDER BY E.InsertDate) % 2 = 0 
						THEN E.InsertDate
					ELSE LEAD(E.InsertDate) OVER (PARTITION BY E.codEmp, E.FechaDia ORDER BY E.InsertDate)
				 END AS HoraSalida

				,DATENAME(WEEKDAY,
					CASE 
						WHEN CONVERT(TIME, E.InsertDate) < '05:00:00' 
							THEN DATEADD(DAY, -1, CAST(E.InsertDate AS DATE))
						ELSE CAST(E.InsertDate AS DATE)
					END
				 ) AS DiaSemana

				,FORMAT(
					CASE 
						WHEN CONVERT(TIME, E.InsertDate) < '05:00:00' 
							THEN DATEADD(DAY, -1, CAST(E.InsertDate AS DATE))
						ELSE CAST(E.InsertDate AS DATE)
					END,
					'd-MMMM-yyyy',
					'es-SV'
				 ) AS FechaReporte


				,NULL AS HorasTrabajadas -- Se actualiza luego
				,NULL AS HorasNormales
				,'DIRECTO' AS Categoria

				,ROW_NUMBER() OVER (PARTITION BY E.codEmp, E.FechaDia ORDER BY E.InsertDate) AS rn

				,C.Comentarios
				,null as emp
				,E.EndActionDate
				,E.ActionDays
			FROM #EmplData E
			LEFT JOIN #Conteo C 
				ON E.codEmp = C.codEmp AND E.FechaDia = C.FechaDia


			--- PRIMER UPDATE PARA SABER SI UN REGISTRO ESTA COMPLETO O NO
			UPDATE #Emparejado
			SET EstadoPar = 
				CASE 
					WHEN HoraEntrada IS NULL OR HoraSalida IS NULL THEN 'INCOMPLETO'
					ELSE 'COMPLETO'
				END

			--- SEGUNDO UPDATE PARA CALCULAR LAS HORAS TRABAJADAS Y LAS NORMALES DURANTE EL DIA
			UPDATE #Emparejado
			SET HorasTrabajadas = 
				CASE 
					WHEN HoraEntrada IS NOT NULL AND HoraSalida IS NOT NULL AND CONVERT(TIME, HoraEntrada) >= '18:00:00' THEN 
						CASE 
							WHEN CAST((DATEDIFF(MINUTE, HoraEntrada, HoraSalida) - 60) / 60.0 AS DECIMAL(5,2)) >= 1 THEN
								CAST((DATEDIFF(MINUTE, HoraEntrada, HoraSalida) - 60) / 60.0 AS DECIMAL(5,2))
							ELSE
								CAST((DATEDIFF(MINUTE, HoraEntrada, HoraSalida)) / 60.0 AS DECIMAL(5,2))
						END
					WHEN HoraEntrada IS NOT NULL AND HoraSalida IS NOT NULL THEN
						CASE 
							WHEN CAST((DATEDIFF(MINUTE, HoraEntrada, HoraSalida) - 35) / 60.0 AS DECIMAL(5,2)) >= 1 THEN
								CAST((DATEDIFF(MINUTE, HoraEntrada, HoraSalida) - 35) / 60.0 AS DECIMAL(5,2))
							ELSE
								CAST((DATEDIFF(MINUTE, HoraEntrada, HoraSalida)) / 60.0 AS DECIMAL(5,2))
						END
					ELSE NULL
				END
				,HorasNormales = CAST(
				CASE 
					WHEN CONVERT(TIME, HoraEntrada) >= '18:00:00' THEN 
						(DATEDIFF(MINUTE, 
							CAST(CAST(HoraEntrada AS DATE) AS DATETIME) + '18:00:00',
							DATEADD(DAY, 1, CAST(CAST(HoraEntrada AS DATE) AS DATETIME)) + '05:00:00'
						) - 60) / 60.0

					WHEN DATENAME(WEEKDAY, HoraEntrada) = 'viernes' THEN 
						(DATEDIFF(MINUTE, '06:30:00', '15:05:00') - 45) / 60.0

					ELSE 
						(DATEDIFF(MINUTE, '06:30:00', '16:05:00') - 45) / 60.0
				END
					AS DECIMAL(5,2))

			/********************************************************************
			 **************** INSERT DE DATA EN TABLAS TEMPORALES ***************
			 ********************************************************************/

			 --- CONSULTA FINAL DEL REPORTE

			SELECT DISTINCT
				 TB.HoraEntrada as [IN]
				,TB.HoraSalida as [OUT]
				,TB.HorasTrabajadas as [Total Horas]
				,CASE 
					WHEN TB.Area = 'Sewing' THEN 'COSTURA - PRODUCCION'
					WHEN TB.Area = 'Embroidery' THEN 'BORDADO LBA'
					WHEN TB.Area = 'Embroidery Headwear' THEN 'BORDADO HW'
		
				  END AS Area
				,TB.FechaReporte AS [Date]
				,TB.DiaSemana	 AS [Day]
				,TB.codEmp AS [Codigo]
				,TB.NombreEmpl AS [Nombre Completo]
				,TB.DepEmpl AS [Departamento]
				,TB.RealModule AS [Depto. Real]
				,NULL AS H_E
				,TB.Categoria AS [Categ.Lab]
				,TB.CommentScan AS Comentario
				,NULL AS Supervisor
				,TB.HorasTrabajadas AS [T.real]
				,TB.HorasNormales AS [H_Nor]		
				,CAST(TB.EndActionDate AS date) AS [Fin Permiso]
				,TB.ActionDays AS [Dias Permiso]
				,TB.Asignacion
				,TB.EstadoAsistencia
				,FechaDia

			FROM
			(

				SELECT 
				 R.codEmp
				,R.NombreEmpl
				,R.DepEmpl
				,R.RealModule
				,R.Area
				,R.CommentScan
				,CASE 
					WHEN LEN(R.CommentScan) = 0 AND R.Comentarios = 1 THEN R.RealModule
					WHEN LEN(R.CommentScan) = 0 AND R.Comentarios = 0 THEN R.RealModule
					ELSE R.CommentScan
				 END AS Asignacion
				,R.FechaDia
				,FORMAT(CAST(R.HoraEntrada AS datetime), 'HH:mm:ss') AS HoraEntrada
				,FORMAT(CAST(R.HoraSalida AS datetime), 'HH:mm:ss') AS HoraSalida
				,R.DiaSemana
				,R.FechaReporte
				,R.HorasTrabajadas
				,R.HorasNormales
				,R.Categoria
				,R.EndActionDate AS EndActionDate
				,R.ActionDays
				,CASE
					WHEN R.Comentarios = 2 AND LEN(R.CommentScan) > 0 THEN 'AUSENCIAS'
					WHEN R.Comentarios = 1 AND R.rn = 1 AND LEN(R.CommentScan) > 0 THEN 'AUSENCIAS'
					WHEN R.Comentarios = 1 AND R.rn = 2 AND LEN(R.CommentScan) > 0 THEN 'AUSENCIAS'
					ELSE 'PRESENTE'
				 END AS EstadoAsistencia
				FROM (
					SELECT 
						R.*
						,ROW_NUMBER() OVER (
							PARTITION BY 
								 R.codEmp
								,R.FechaDia
								,R.NombreEmpl
								,R.DepEmpl
								,R.RealModule
								,R.Area
								,R.CommentScan
								,R.HoraEntrada
								,R.HoraSalida
								,R.HorasTrabajadas
								,R.HorasNormales
								,R.Categoria
							ORDER BY R.InsertDate ASC
						) AS FilaNeutral
					FROM #Emparejado R

				) R
				WHERE NOT (
					LEN(R.CommentScan) = 0 AND R.FilaNeutral > 1
				)


				UNION ALL

				SELECT 
					 A.codEmp
					,A.NombreEmpl
					,A.DepEmpl
				   -- ,A.InsertDate
					,A.RealModule
					,A.Area 
					,NULL AS CommentScan
					,A.Asignacion
					,A.FechaDia
					,FORMAT(CAST(A.HoraEntrada AS datetime), 'HH:mm:ss') AS HoraEntrada
					,FORMAT(CAST(A.HoraSalida AS datetime), 'HH:mm:ss') AS HoraSalida
					,A.DiaSemana
					,A.FechaReporte
					,A.HorasTrabajadas
					,A.HorasNormales
					,A.Categoria
					,null AS EndActionDate
					,null AS ActionDays
					,'PRESENTE' AS EstadoAsistencia
				FROM #AsignacionesExtra A

				UNION ALL

				SELECT 
					 I.codEmp
					,I.NombreEmpl
					,I.DepEmpl
				   -- ,A.InsertDate
					,I.RealModule
					,I.Area 
					,NULL AS CommentScan
					,I.Asignacion
					,I.FechaDia
					,I.HoraEntrada
					,I.HoraSalida
					,I.DiaSemana
					,I.FechaReporte
					,I.HorasTrabajadas
					,I.HorasNormales
					,I.Categoria
					,I.EndActionDate
					,I.ActionDays
					,'AUSENTE' AS EstadoAsistencia
				FROM #Incapacidades I

			) AS TB
			ORDER BY FechaDia, CodEmp,RealModule, HoraEntrada
	END
	
-- END
GO