USE [LCA]
GO
/****** Object:  StoredProcedure [dbo].[InsertBillingDetails_Each]    Script Date: 10/12/2025 03:09:50 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Batch submitted through debugger: SQLQuery2.sql|7|0|C:\Users\administrator.LCA\AppData\Local\Temp\~vs88B0.sql

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
--select * from  [AppsLCA].[dbo].[ImportExport_AnexoFacturacion] where boxnumber like '%656750%'

--select * from [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] where boxnumber like '%656750%'
--shipdate>='2024-03-01' order by shipdate desc, boxnumber

ALTER PROCEDURE [dbo].[InsertBillingDetails_Each]
	@VWaybill VARCHAR(MAX)
AS
BEGIN
SET NOCOUNT ON;

IF OBJECT_ID(N'tempdb..#TBoxes1') IS NOT NULL
	BEGIN
		DROP TABLE #TBoxes1
	END

IF OBJECT_ID(N'tempdb..#TBoxes1_BAK') IS NOT NULL
	BEGIN
		DROP TABLE #TBoxes1_BAK
	END
IF OBJECT_ID(N'tempdb..#UnitsOriginal_1') IS NOT NULL
	BEGIN
		DROP TABLE #UnitsOriginal_1
	END
IF OBJECT_ID(N'tempdb..#UnitsOriginal_2') IS NOT NULL
	BEGIN
		DROP TABLE #UnitsOriginal_2
	END
IF OBJECT_ID(N'tempdb..#CajasOriginal') IS NOT NULL
	BEGIN
		DROP TABLE #CajasOriginal
	END

IF OBJECT_ID(N'tempdb..#HWEmbroidery') IS NOT NULL
	BEGIN
		DROP TABLE #HWEmbroidery
	END
IF OBJECT_ID(N'tempdb..#TBoxes2') IS NOT NULL
	BEGIN
		DROP TABLE #TBoxes2
	END
IF OBJECT_ID(N'tempdb..#TBaseCost') IS NOT NULL
	BEGIN
		DROP TABLE #TBaseCost
	END
IF OBJECT_ID(N'tempdb..#TBaseCost_Fabric') IS NOT NULL
	BEGIN
		DROP TABLE #TBaseCost_Fabric
	END
IF OBJECT_ID(N'tempdb..#TPartNumber') IS NOT NULL
	BEGIN
		DROP TABLE #TPartNumber
	END
IF OBJECT_ID(N'tempdb..#TBoxes3') IS NOT NULL
	BEGIN
		DROP TABLE #TBoxes3
	END
IF OBJECT_ID(N'tempdb..#TInvoiceBatch') IS NOT NULL
	BEGIN
		DROP TABLE #TInvoiceBatch
	END
IF OBJECT_ID(N'tempdb..#TStdCost_Full') IS NOT NULL
	BEGIN
		DROP TABLE #TStdCost_Full
	END
IF OBJECT_ID(N'tempdb..#TStdCost_FG') IS NOT NULL
	BEGIN
		DROP TABLE #TStdCost_FG
	END
IF OBJECT_ID(N'tempdb..#Report') IS NOT NULL
	BEGIN
		DROP TABLE #Report
	END	
IF OBJECT_ID(N'tempdb..#TCostP1') IS NOT NULL
	BEGIN
		DROP TABLE #TCostP1
	END	
IF OBJECT_ID(N'tempdb..#TPurch') IS NOT NULL
	BEGIN
		DROP TABLE #TPurch
	END	
IF OBJECT_ID(N'tempdb..#TSales_PNew') IS NOT NULL
	BEGIN
		DROP TABLE #TSales_PNew
	END	
IF OBJECT_ID(N'tempdb..#abc4_1') IS NOT NULL
    BEGIN
        DROP TABLE #abc4_1
    END
IF OBJECT_ID(N'tempdb..#abc4_2') IS NOT NULL
    BEGIN
        DROP TABLE #abc4_2
    END

IF OBJECT_ID(N'tempdb..#Tboxes4') IS NOT NULL
    BEGIN
        DROP TABLE #Tboxes4
    END
IF OBJECT_ID(N'tempdb..#Tboxes5') IS NOT NULL
    BEGIN
        DROP TABLE #Tboxes5
    END
IF OBJECT_ID(N'tempdb..#TEmbrCodes') IS NOT NULL
    BEGIN
        DROP TABLE #TEmbrCodes
END

IF OBJECT_ID(N'tempdb..#abc4_3') IS NOT NULL
    BEGIN
        DROP TABLE #abc4_3
END
IF OBJECT_ID(N'tempdb..#BoxList') IS NOT NULL
    BEGIN
        DROP TABLE #BoxList
END
IF OBJECT_ID(N'tempdb..#T_VW_BoxTransactions') IS NOT NULL
    BEGIN
        DROP TABLE #T_VW_BoxTransactions
END
IF OBJECT_ID(N'tempdb..#OrigFab') IS NOT NULL
    BEGIN
        DROP TABLE #OrigFab
END
IF OBJECT_ID(N'tempdb..#ABC11_Pre') IS NOT NULL
    BEGIN
        DROP TABLE #ABC11_Pre
END
IF OBJECT_ID(N'tempdb..#SalesEmbroidery') IS NOT NULL
    BEGIN
        DROP TABLE #SalesEmbroidery
END


--Declare @VFecha date =    CONVERT(DATE, GETDATE() -4 ) 
--Declare @VFecha  date = '2024-07-01'
----Declare @VFecha2 date = '2024-05-31'

--Declare @VWaybill varchar(200) = 'AIR-APP-20251124'-- 'AIR-BUND-20240820' --'AIR-BUND-20240621-NO CAFTA'  
--Declare @VBatch varchar(200) = '27712211240' 


delete from  appslca.dbo.ImportExport_AnexoFacturacion where  waybill = @VWaybill 
--delete from  appslca.dbo.ImportExport_AnexoFacturacion where shipdate >= @VFecha
	--shipdate >= @VFecha
	--shipdate >= @VFecha

Create table #BOxList (
	BoxNumber varchar(200) null,
	ShipDate date null,
	index IX_1 Nonclustered (BoxNumber)
)
	
insert into #BOxList
select distinct BoxNumber, ShipDate from  [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] with (nolock) where waybill =@VWaybill 
	  -- boxnumber in ('00786738') --and boxnumber in ('00762770','00762127','00762131')
	--where shipdate >= @VFecha
	--shipdate >= @VFecha
	-- waybill =@VWaybill
	-- --boxnumber in ('00718618') 


create table #SalesEmbroidery (
	Code varchar(200) null,
	Total decimal(12,2) null,
	LaborProduction decimal(12,2) null
)

insert into #SalesEmbroidery
select Code, Total, LaborProduction FROM OPENQUERY([Mariadb],'SELECT Code, 
	Stitches+Pellums+Threads+Labor+Fabric+ShippingHandling as Total
	, LaborProduction FROM  wordpress.Sales_Embroidery ') 

Declare @VScreenPr decimal(12,2) = null
set @VScreenPr = (select top 1 LaborProduction from #SalesEmbroidery where code='ScreenPr')


create table  #TSales_PNew (
	IDCostColor int null,
	Style		varchar(200) null,
	StyleName	varchar(200) null,
	Color		varchar(200) null,
	ColorDescription varchar(200) null,
	Prints		int null,
	Embellishment decimal(10,2) null,
	CostBlank	  decimal(10,2) null,
	OtherEmbCost  decimal(10,2) null,
	CostEmb		  decimal(10,2) null,
	TotalCost	  decimal(10,2) null,
	Category	 varchar(200) null,
	Season		 varchar(200) null,
	StyleId		 int null,
	PricingSeason varchar(200) null,
	StyleOPtionName1 varchar(200) null,
	StyleOptionID	int null,	
	Index SPIX_1 Nonclustered (Style, Color)
)
--select * from #SalesEmbroidery

insert into #TSales_PNew
select * from  AppsLCA.dbo.Prices_New with (nolock) where Season NOT IN ('BLANK','Blank RO','EXP BO') --and style='82176' and color='632'

--select * from #TSales_PNew where style ='05PDT' and color='211'

create  table #TBoxes1 (
    Waybill varchar(200) null,
	HTSDescription varchar(200) null,
	ShipDate date null,
	InvoiceBatch varchar(200) null,
	Batch varchar(200) null,
	PONumber varchar(200) null,
	BoxNumber varchar(200) null,
	StyleNumber varchar(200) null,
	SeasonName varchar(200) null,
	Stylecolor varchar(200) null,
	Qty decimal(12,2) null,
	OrderId int null,
	EmbroiderCode varchar(200) null,
	GarmentSize varchar(200) null,
	ManufactureID int null,
	ProductDivision varchar(200) null,
	RO varchar(200) null,
	RO_ID int null
)
insert into #TBoxes1
Select 
    replace(REPLACE(REPLACE(REPLACE(RTRIM(IE_Ship.WayBill),CHAR(9), ''),CHAR(10),''),CHAR(13),''),' ','') as Waybill,
    CHP.CA_HTSDescription as HTSDescription, IE_Ship.ShipDate, IE_Ship.InvoiceBatch , IE_Ship.Batch, SMO.PONumber, SMO.BoxNumber, SMO.StyleNumber, 
	SMO.SeasonName, 
	SMO.StyleColor,
	SMO.Quantity as Qty, SMO.OrderID, SMO.EmbroideryCode, SMO.Size as GarmentSize,
	SMO.MOID as ManufactureID, isnull(SMO.ProductDivision,'Apparel') as ProductDivision, null as RO, null as RO_ID
	from [LCA].[dbo].[VW_Check_Sales_Prices_in_Invoices_SeekMO_3] SMO with (nolock)
	    left outer join (
						select distinct ShipDate, WayBill, InvoiceBatch, Batch, BoxNUmber
							from appslca.dbo.[ImportExport_ShipmentBoxAll]  with (nolock)
							where BoxNumber in  (select BoxNumber from #BoxList) --in ('00673224')
						) IE_Ship
				on SMO.BoxNumber = IE_Ship.BoxNumber
		left outer join (
							select distinct ShipDate, WayBill, InvoiceBatch, Batch, BoxNUmber, StyleNumber, StyleColor, GarmentSize, CA_HTSDescription
								from 
									[LCA].[dboReaders].[VW_ImpExp_ShipmentBoxItems_CheckPrice] CHP2  with (nolock)
									where BoxNumber in  (select BoxNumber from #BoxList) --in ('00673224')
						) CHP  
				on SMO.Boxnumber = CHP.BoxNumber and SMO.StyleNumber = CHP.StyleNumber 
				  and SMO.StyleColor = CHP.StyleColor and SMO.Size = CHP.GarmentSize
			where SMO.boxNumber in    (select BoxNumber from #BoxList)  --('00673224') -- ('00673224') --


insert into #TBoxes1
Select 
    replace(REPLACE(REPLACE(REPLACE(RTRIM(IE_Ship.WayBill),CHAR(9), ''),CHAR(10),''),CHAR(13),''),' ','') as Waybill,
    CHP.CA_HTSDescription as HTSDescription, IE_Ship.ShipDate, IE_Ship.InvoiceBatch , IE_Ship.Batch, 
	SMO.PONumber, SMO.BoxNumber, SMO.StyleNumber, 
	SMO.SeasonName, 
	SMO.StyleColor,
	SMO.Quantity as Qty, SMO.OrderID, SMO.EmbroideryCode, SMO.Size as GarmentSize,
	SMO.MOID as ManufactureID, isnull(SMO.ProductDivision,'Apparel') as ProductDivision, null as RO, null as RO_ID
	from [LCA].[dbo].[VW_Check_Sales_Prices_in_Invoices_SeekMO_Bundle] SMO with (nolock)
	    left outer join (
						select distinct ShipDate, WayBill, InvoiceBatch, Batch, BoxNUmber
							from appslca.dbo.[ImportExport_ShipmentBoxAll]  with (nolock)
							where BoxNumber in  (select BoxNumber from #BoxList) --in ('00673224')
						) IE_Ship
				on SMO.BoxNumber = IE_Ship.BoxNumber
		left outer join (
							select distinct ShipDate, WayBill, InvoiceBatch, Batch, BoxNUmber, StyleNumber, StyleColor, GarmentSize, CA_HTSDescription
								from 
									[LCA].[dboReaders].[VW_ImpExp_ShipmentBoxItems_CheckPrice] CHP2  with (nolock)
									where BoxNumber in  (select BoxNumber from #BoxList) --in ('00673224')
						) CHP  
				on SMO.Boxnumber = CHP.BoxNumber and SMO.StyleNumber = CHP.StyleNumber 
				  and SMO.StyleColor = CHP.StyleColor and SMO.Size = CHP.GarmentSize
			where SMO.boxNumber in    (select BoxNumber from #BoxList)  --('00673224') -- ('00673224') --


--select * from #TBoxes1 --where batch in ('2565','2505','2475','2524','2562') --  where boxnumber in ('00694429') order by StyleNumber
--select sum(qty) as qty   from #tboxes1  

--select * from [LCA].[dbo].[VW_Check_Sales_Prices_in_Invoices_SeekMO_3] where boxnumber ='00673224' order by stylenumber

create table #TInvoiceBatch (
	Boxnumber varchar(200) null,
	InvoiceBatch varchar(200) null,
	Batch varchar(200) null
)

insert into #TInvoiceBatch
select distinct Boxnumber, InvoiceBatch, Batch
	from #TBoxes1
	group by Boxnumber, InvoiceBatch, Batch

create  table #TBoxes1_BAK (
    Waybill varchar(200) null,
	HTSDescription varchar(200) null,
	ShipDate date null,
	InvoiceBatch varchar(200) null,
	Batch varchar(200) null,
	PONumber varchar(200) null,
	BoxNumber varchar(200) null,
	StyleNumber varchar(200) null,
	SeasonName varchar(200) null,
	Stylecolor varchar(200) null,
	Qty decimal(12,2) null,
	OrderId int null,
	EmbroiderCode varchar(200) null,
	GarmentSize varchar(200) null,
	ManufactureID int null,
	ProductDivision varchar(200) null,
	RO varchar(200) null,
	RO_ID int null,
	Index IXI_001 NonClustered (ManufactureID, GarmentSize, StyleNumber)
	--ManufactureID = @EO_ID and Garmentsize = @Size and StyleNumber =@EO_Style
)

--Proceso para desmembrar las unidades que lleva cada Caja por la RO original que estaba en la bodega

create table #UnitsOriginal_1 (
	Qty bigint,
	RO varchar(200),
	RO_ID int,
	EO varchar(200),
	EO_ID int,
	Size varchar(200), 
	EO_Style varchar(200) 

)

create table #UnitsOriginal_2 (
	RO varchar(200),
	RO_ID int,
	EO varchar(200),
	EO_ID int,
	Size varchar(200), 
	EO_Style varchar(200) 

)
create table #T_VW_BoxTransactions (
 	   id bigint null,
	  [TransactionType] varchar(200) null,
      [ManufactureNumber] varchar(100) null,
      [Size] varchar(100) null,
      [Quantity] bigint null,
      [Style] varchar(100) null,
      [StyleColor] varchar(100) null,
      [StyleColorID] int null,
      [ManufactureID] int null,
      [StyleID] int null,
      [Season] varchar(100) null,
      [BoxNumber] varchar(100) null,
      [FromBoxNumber] varchar(100) null,
      [UserName] varchar(200) null,
      [TransactionDate] datetime null,
      [Bin] varchar(100) null,
      [Comment] varchar(500) null,
      [AttachedMO]  varchar(100) null,
      [Attached_ID] int null,
      [At_StyleColor] varchar(100) null,
      [At_StyleID] int null,
      [At_Style] varchar(100) null,
      [Priority] varchar(200) null,
      [PW-Modulo] varchar(300) null,
      [ColorDescription] varchar(500) null,
	  Index IX_001 NonClustered (Attached_ID),
	  Index IX_002 NonClustered (AttachedMO,Attached_ID, Size)
)
insert into #T_VW_BoxTransactions
select * from [LCA].[dboReaders].[VW_BoxTransactions] where Attached_ID in (select distinct ManufactureID from #TBoxes1)

--select * from  #T_VW_BoxTransactions

insert into #UnitsOriginal_1
--- Cambio hecho por Rodrigo Ramírez para quitar los negativos de las cajas finales 2025-03-21 --- 
Select  SUM(Quantity) as Qty, ManufactureNumber as RO, ManufactureID as RO_ID, AttachedMO as EO, Attached_ID as EO_ID, 
--Select  Quantity as Qty, ManufactureNumber as RO, ManufactureID as RO_ID, AttachedMO as EO, Attached_ID as EO_ID, 
	Size,AT_Style as EO_Style
	from [LCA].[dboReaders].[VW_BoxTransactions] with (nolock)
	where concat(AttachedMO, Attached_ID, Size) in 
		(
		Select distinct concat(EO, EO_ID, Size)
			from	
				(select row_number() over(Partition by AttachedMO, Size order by AttachedMO, Size ) as Ncuenta,
					Qty, ManufactureNumber as RO, ManufactureID  as RO_ID, AttachedMO as EO, Attached_ID as EO_ID,  Size
						from 
						(select ManufactureNumber, ManufactureID,Size, sum(Quantity) as Qty, AttachedMO, Attached_ID
								from #T_VW_BoxTransactions VW_BT with (nolock)
								where Attached_ID in (select distinct ManufactureID from #TBoxes1)
								and VW_BT.id not in (11049880,11049898,11049896,11053748,11053751) 
								--Validación agregada para que cuadre por transacciones mal realizadas por Luis Canales
								--Agregado por RODRIGO RAMIREZ 20250508
								group by ManufactureNumber, ManufactureID, Size,  AttachedMO, Attached_ID
						) abc123
				) abcdef
				where Ncuenta >1
		)
		and id not in (11305418,11305427,11305421,11305424,11305413,11305410,11305416,11349189,11349190,11349188,11349187,11349185,11349186,11349191)
		GROUP BY ManufactureNumber, ManufactureID, AttachedMO, Attached_ID, Size, AT_Style
	order by AttachedMO, Attached_ID, Size
			
--select * from #UnitsOriginal_1 order by size}

insert into #UnitsOriginal_2
Select distinct ManufactureNumber as RO, ManufactureID as RO_ID, AttachedMO as EO, Attached_ID as EO_ID, 
	Size,AT_Style as EO_Style
	from #T_VW_BoxTransactions with (nolock)
	where concat(AttachedMO, Attached_ID, Size) not in ( select distinct concat(EO, EO_ID, Size) from #UnitsOriginal_1)
	and Attached_ID in (select distinct ManufactureID from #TBoxes1)

--Select * from #UnitsOriginal_2 where eo_id=453200

create table #CajasOriginal (
	Boxnumber varchar(200) null,
	StyleNumber varchar(200) null,
	GarmentSize varchar(200) null,
	Qty bigint null,
	EO_ID int null,
	EO_Style varchar(200)
)

insert into #CajasOriginal
select distinct Boxnumber, StyleNumber, GarmentSize, sum(qty) as qty,  ManufactureID as EO_ID, StyleNumber as EO_Style
	from #TBoxes1
	group by Boxnumber, StyleNumber, GarmentSize, ManufactureID, STyleNumber


--select sum(qty) from #TBoxes1 --where batch='2137'  --where boxnumber in ('00694429')
--select * from #TBoxes1 where ManufactureID = 560853

--select * from #TBoxes1 where manufactureid=560853   --boxnumber ='00694429' --manufactureid ='461795' and GarmentSize ='M'  and StyleNumber = 'L900'
--select * from #CajasOriginal		where eo_id=560853 --and eo_style='L900' and GarmentSize ='M'
--select * from #UnitsOriginal_1 	where eo_id=560853 --and eo_style='L900' and Size ='M'
--select * from #UnitsOriginal_2		where eo_id=560853 --and eo_style='L900' and Size ='M'


declare @EO varchar(200)
declare @EO_ID int
declare @EO_Style varchar(200)
declare @Size varchar(200)
declare @RO varchar(200)
declare @RO_ID int
declare @Qty int

declare @Waybill varchar(200) 
declare @HTSDescription varchar(200) 
declare @ShipDate date 
declare @InvoiceBatch varchar(200) 
declare @Batch varchar(200) 
declare @PONumber varchar(200) 
declare @BoxNumber varchar(200) 
declare @StyleNumber varchar(200) 
declare @SeasonName varchar(200) 
declare @Stylecolor varchar(200) 
declare @OrderId int 
declare @EmbroiderCode varchar(200) 
declare @GarmentSize varchar(200) 
declare @ManufactureID int 
declare @ManufactureID_2 int 
declare @ProductDivision varchar(200) 


declare @CO_Boxnumber varchar(200)
declare @CO_StyleNumber varchar(200)
declare @CO_GarmentSize varchar(200)
declare @CO_Qty int 
declare @CO_EO_ID int 
declare @CO_Style varchar(200)

declare @CU_1_Qty int
declare @CU_1_RO varchar(200)
declare @CU_1_RO_ID int 
declare @CU_1_EO varchar(200)
declare @CU_1_EO_ID int 
declare @CU_1_Size varchar(200)
declare @CU_1_EO_Style varchar(200)

insert into #TBoxes1_BAK
select * from #TBoxes1 where concat( ManufactureID, StyleNumber, GarmentSize) in (select distinct concat(EO_ID, EO_Style, Size) from #UnitsOriginal_1)

declare Cur_UnitsOriginal cursor for select distinct EO, EO_ID, Size, EO_Style from #UnitsOriginal_1

open Cur_UnitsOriginal
Fetch next from Cur_UnitsOriginal into  @EO, @EO_ID, @Size, @EO_Style

while @@Fetch_status=0
	begin
		delete from #TBoxes1 where concat(ManufactureID, GarmentSize, StyleNumber) = concat( @EO_ID, @Size, @EO_Style)
		declare C_AsignUnid cursor for select top 1 * from #TBoxes1_BAK where ManufactureID = @EO_ID and Garmentsize = @Size and StyleNumber =@EO_Style
		open C_AsignUnid
				Fetch next from C_AsignUnid into @Waybill, @HTSDescription, @ShipDate, @InvoiceBatch, @Batch,  @PONumber, @BoxNumber, @StyleNumber, @SeasonName, @StyleColor,
													@Qty, @OrderID, @EmbroiderCode, @GarmentSize, @ManufactureID, @ProductDivision, @RO, @RO_ID
					while @@FETCH_STATUS=0
					begin
						--if @EO_ID=461795 and @GarmentSize ='M' and @EO_Style ='L900'
						--	Begin
						--		print'Revisar'
						--	End

						declare C_CajaOriginal cursor for select * from #CajasOriginal where EO_ID= @EO_ID and GarmentSize =@Size and EO_Style = @EO_Style
						open C_CajaOriginal
						Fetch next from C_CajaOriginal into @CO_Boxnumber, @CO_StyleNumber, @CO_GarmentSize, @CO_Qty, @CO_EO_ID, @CO_Style

						declare C_UnitOriginal_1 cursor for select * from #UnitsOriginal_1  
																where EO_ID= @EO_ID and Size =@Size
																	  and EO_Style = @EO_Style
						open C_UnitOriginal_1  
						Fetch next from C_UnitOriginal_1 into @CU_1_Qty, @CU_1_RO, @CU_1_RO_ID, @CU_1_EO, @CU_1_EO_ID, @CU_1_Size, @CU_1_EO_Style
						While @@FETCH_STATUS =0
							begin
									if @CU_1_Qty < = @CO_Qty 
										begin
											insert into #TBoxes1 values (@Waybill, @HTSDescription, @ShipDate, @InvoiceBatch, @Batch,  @PONumber, @CO_Boxnumber, @StyleNumber,
																		@SeasonName, @StyleColor,
																		@CU_1_Qty, @OrderID, @EmbroiderCode, @GarmentSize, @ManufactureID,
																		@ProductDivision, @CU_1_RO, @CU_1_RO_ID)
										set @CO_Qty = @CO_Qty  - @CU_1_Qty
										if @CO_Qty <=0
											begin
												Fetch next from C_CajaOriginal into @CO_Boxnumber, @CO_StyleNumber, @CO_GarmentSize, @CO_Qty, @CO_EO_ID, @CO_Style
											end
												Fetch next from C_UnitOriginal_1 into @CU_1_Qty, @CU_1_RO, @CU_1_RO_ID, @CU_1_EO, @CU_1_EO_ID, @CU_1_Size, @CU_1_EO_Style
										end
									else --if @CU_1_Qty > @CO_Qty 
										begin
											insert into #TBoxes1 values (@Waybill, @HTSDescription, @ShipDate, @InvoiceBatch, @Batch,  @PONumber, @CO_Boxnumber, @StyleNumber,
																		@SeasonName, @StyleColor,
																		@CO_Qty, @OrderID, @EmbroiderCode, @GarmentSize, @ManufactureID,
																		@ProductDivision, @CU_1_RO, @CU_1_RO_ID)
											set @CU_1_Qty = @CU_1_Qty - @CO_Qty 
											set @CO_Qty=0
											Fetch next from C_CajaOriginal into @CO_Boxnumber, @CO_StyleNumber, @CO_GarmentSize, @CO_Qty, @CO_EO_ID, @CO_Style
										end
							end
							close C_UnitOriginal_1													   
							deallocate C_UnitOriginal_1											   

							close C_CajaOriginal													   
							deallocate C_CajaOriginal											   
						
						Fetch next from C_AsignUnid into @Waybill, @HTSDescription, @ShipDate, @InvoiceBatch, @Batch,  @PONumber, @BoxNumber, @StyleNumber, @SeasonName, @StyleColor,
															@Qty, @OrderID, @EmbroiderCode, @GarmentSize, @ManufactureID, @ProductDivision, @RO, @RO_ID
					end
					close C_AsignUnid													   
					deallocate C_AsignUnid											   
		Fetch next from Cur_UnitsOriginal into  @EO, @EO_ID, @Size, @EO_Style
	end
close Cur_UnitsOriginal													   
deallocate Cur_UnitsOriginal											   

--select sum(qty), batch from #TBoxes1 group by batch--batch='2329'  --where boxnumber in ('00694429')
--select *    from #tboxes1  WHERE BoxNumber='00786738'
---Dado que una misma MO puede ir en dos batch diferentes actualizamos la tabla Temporal #Tboxes1
update TB1 set TB1.InvoiceBatch = TIBatch.InvoiceBatch, TB1.Batch = TIBatch.Batch
	from #TBoxes1 TB1
	left join #TInvoiceBatch TIBatch
	on TB1.BoxNumber = TIBatch.Boxnumber

--select * from #TBoxes1 where batch in ('2565','2505','2475','2524','2562')
--select * from #TBoxes1 where boxnumber in ('00675739') order by boxnumber

--select * from #UnitsOriginal_2

---Proceso para actualizar las columnas RO, Ro_ID en el curstos #Tboxes1
	declare Cur_UpdateRO cursor for select * from #UnitsOriginal_2
	
	open Cur_UpdateRO
	Fetch next from Cur_UpdateRO into @RO, @RO_ID, @EO, @EO_ID, @Size, @EO_Style

	while @@Fetch_status=0
			begin
				update #TBoxes1 set RO=@RO, RO_ID =@RO_ID  where ManufactureID = @EO_ID and StyleNumber = @EO_Style and GarmentSize= @Size
				Fetch next from Cur_UpdateRO into @RO, @RO_ID, @EO, @EO_ID, @Size, @EO_Style
			end
close Cur_UpdateRO													   
deallocate Cur_UpdateRO	

--select * from #TBoxes1  where boxnumber in ('00694429') --where batch = '1926'  --boxnumber in ('00675739')

																		   
--Proceso para cargar codigo de embroidery para Bordado de HW			   
	Create Table #HWEmbroidery (
		BoxNumber varchar(200) null,
		OrderID   int null,
		PONumber  varchar(200) null,
		HWEMB_Code varchar(200) null,
		WorkFlowID int null,
		StyleID varchar(200) null,
		ProductDivision varchar(200) null,
		ManufactureId int null
	)

	insert into #HWEmbroidery
	select distinct ABC10.BoxNumber, EMBR1.OrderID, EMBR1.PONumber, null as HWEMB_Code, WF.WorkFlowID, ORD_Det.StyleID, STY.Comments9, TYU.MOID
		from #TBoxes1 ABC10
			left join  [LCA].[dbo].[VW_Check_Sales_Prices_in_Invoices_SeekMO_2]  TYU with (nolock)
				on ABC10.BoxNumber = TYU.BoxNumber
			left join lca.dbo.ManufactureOrders MO1 with (nolock)
				on TYU.MOID=MO1.manufactureID and MO1.StatusID <=90
			left join lca.dbo.Orders EMBR1 with (nolock)
				on MO1.OrderID = EMBR1.OrderID and EMBR1.StatusID <=90 
			left join lca.dbo.[WorkFlows] WF with (nolock)
				on TYU.MOID = WF.ManufactureID
			left join lca.dbo.OrderItems ORD_Det with (nolock)
				on MO1.FirstOrderItemID = ORD_Det.OrderItemID
			left join lca.dbo.Styles STY with (nolock)
				on ORD_Det.StyleID = STY.StyleId


	declare @HWEMB_Code varchar(200)  =null
	declare @WorkFlowID int =null
	declare @Es_HWEmbr1 int =null
	declare @Es_HWEmbr2 int =null
	declare @Es_HWEmbr3 int =null
	declare @StyleId int =null
	declare @VerificaCampo varchar(200) =null

	declare Cur_HWEmbroidery cursor for select * from #HWEmbroidery
	
	open Cur_HWEMBroidery
	Fetch next from Cur_HWEMBroidery into @BoxNumber, @ORderID, @PONumber, @HWEMB_Code, @WorkFlowID, @StyleID, @ProductDivision, @ManufactureID
	while @@Fetch_status=0
			begin
			if @ProductDivision<>'Apparel'
				begin
					Set @Es_HWEmbr1 =(Select count(*) from [LCA].[dbo].[WorkTasks] with (nolock) 
										where TaskName like 'Finish Embroidery  HW 1' and WorkFlowId=@WorkFlowID )
					Set @Es_HWEmbr2 =(Select count(*) from [LCA].[dbo].[WorkTasks] with (nolock) 
										where TaskName like 'Finish Embroidery  HW 2' and WorkFlowId=@WorkFlowID )
					Set @Es_HWEmbr3 =(Select count(*) from [LCA].[dbo].[WorkTasks] with (nolock) 
										where TaskName like 'Finish Embroidery  HW 3' and WorkFlowId=@WorkFlowID )
					Set @VerificaCampo = (select top 1 comments26 from lca.dbo.Orders  where OrderID = @OrderID)

					if @Es_HWEmbr3>0 and (@VerificaCampo is null or  ltrim(REPLACE(REPLACE(REPLACE(RTRIM(@VerificaCampo),CHAR(9), ''),CHAR(10),''),CHAR(13),'') )='')
						begin
							update #HWEmbroidery set HWEMB_Code ='TBD,TBD,TBD' where BoxNumber=@Boxnumber and ManufactureId=@ManufactureID
							update lca.dbo.Orders set Comments26='TBD,TBD,TBD' where OrderID = @OrderID
						end
					else
						begin
							if @Es_HWEmbr2>0 and (@VerificaCampo is null or  ltrim(REPLACE(REPLACE(REPLACE(RTRIM(@VerificaCampo),CHAR(9), ''),CHAR(10),''),CHAR(13),'') )='')
								begin
									update #HWEmbroidery set HWEMB_Code ='TBD,TBD' where BoxNumber=@Boxnumber and ManufactureId=@ManufactureID
									update lca.dbo.Orders set Comments26='TBD,TBD' where OrderID = @OrderID
								end
							else
								begin
									if @Es_HWEmbr1>0 and (@VerificaCampo is null or ltrim(REPLACE(REPLACE(REPLACE(RTRIM(@VerificaCampo),CHAR(9), ''),CHAR(10),''),CHAR(13),'') )='')
										begin
											update #HWEmbroidery set HWEMB_Code ='TBD' where BoxNumber=@Boxnumber and ManufactureId=@ManufactureID
											update lca.dbo.Orders set Comments26='TBD' where OrderID = @OrderID
										end
								end
						end
						 
				end
			Set @VerificaCampo =null
			Fetch next from Cur_HWEMBroidery into @BoxNumber, @ORderID, @PONumber, @HWEMB_Code, @WorkFlowID, @StyleID, @ProductDivision,@ManufactureID

			end

close Cur_HWEMBroidery
deallocate Cur_HWEMBroidery

--select * from #Tboxes2

--select * from #TBoxes1 where boxnumber ='00786738'

Create Table  #TBoxes2 (
    Waybill varchar(200) null,
	HTSDescription varchar(200) null,
	ShipDate date null,
	InvoiceBatch varchar(200) null,
	Batch varchar(200) null,
	PONumber varchar(200) null,
	BoxNumber varchar(200) null,
	StyleNumber varchar(200) null,
	SeasonName varchar(200) null,
	Stylecolor varchar(200) null,
	Qty decimal(12,2) null,
	OrderID int  null,
	EmbroideryCode varchar(200) null, 
	GarmentSize varchar(200) null,
	ManufactureID int null,
	ProductDivision varchar(200) null,
	RO varchar(200) null,
	RO_ID int  null,
	MO varchar(255) null,
	Embr_Code1 varchar(250) null,
	Embr_Code2 varchar(250) null,
	Embr_Code3 varchar(250) null,
	Embr_Code4 varchar(250) null,
	PrintLocations varchar(250) null,
	PrintCount varchar(250)  null,
	OrderTypeID2 int null,
	StyleOptionID int null,
	CountryOfOrigin varchar(200) null,
	Manufacturer varchar(200) null,
	Vendor_2 varchar(200) null,
	Embr_Total decimal(10,2) null,
	TypeOrd varchar(250) null,
	Total_Sp_Subli decimal(12,2) null,
	Embr_Code_Labor decimal(12,2) null,
	ScreenPrint_Labor decimal(12,2) null,
	Cuenta int null
)

create  table #TBoxes3 (
    Waybill varchar(200) null,
	HTSDescription varchar(200) null,
	ShipDate date null,
	InvoiceBatch varchar(200) null,
	Batch varchar(200) null,
	PONumber varchar(200) null,
	BoxNumber varchar(200) null,
	StyleNumber varchar(200) null,
	SeasonName varchar(200) null,
	Stylecolor varchar(200) null,
	Qty decimal(12,2) null,
	OrderId int null,
	EmbroiderCode varchar(200) null,
	GarmentSize varchar(200) null,
	ManufactureID int null,
	ProductDivision varchar(200) null,
	RO varchar(200) null,
	RO_ID int null
	)

insert into #TBoxes3
select 	Waybill, HTSDescription,ShipDate, InvoiceBatch, Batch, PONumber, BoxNumber, StyleNumber, SeasonName, 
		Stylecolor, sum(Qty) as Qty, OrderId, 
		EmbroiderCode, GarmentSize,	ManufactureID, ProductDivision,	RO,	RO_ID
	from #TBoxes1
	group by Waybill, HTSDescription,ShipDate, InvoiceBatch, Batch, PONumber, BoxNumber, 
		StyleNumber, SeasonName, Stylecolor,  OrderId, 
		EmbroiderCode, GarmentSize,	ManufactureID, ProductDivision,	RO,	RO_ID


---Borrar aquellos registros con qty=0 dado que son devoluciones que hacen en bodega
delete from #TBoxes3 where qty=0

--select sum(qty) from #TBoxes3 where batch='3059'-- where boxnumber ='00715869'
--select * from #TBoxes2 where batch='3059'


create table #TEmbrCodes (
	Orderid int null,
	Embr_Code1 varchar(200) null,
	Embr_Code2 varchar(200) null,
	Embr_Code3 varchar(200) null,
	Embr_Code4 varchar(200) null,
)
insert into #TEmbrCodes
select orderid, max(case when ColN=1 then [Value] end) as EMBR_Code1,
				max(case when ColN=2 then [Value] end) as EMBR_Code2,
				max(case when ColN=3 then [Value] end) as EMBR_Code3,
				max(case when ColN=4 then [Value] end) as EMBR_Code4
	from 
		(select OrderId, [value], row_number() over (partition by Orderid order by Orderid)  as ColN
			from 
				(select Orderid, ponumber, value from 
					(select orderid, ponumber , comments26 from lca.dbo.orders with (nolock)
						where orderid in (select distinct orderid from #TBoxes3) and StatusID <=90 
					) abcde123
					cross apply string_split(Comments26,',')
				) cba123
		) yuy123
	 group by Orderid
union
---Union necesario para los Waybill que son Bundles
select orderid, max(case when ColN=1 then [Value] end) as EMBR_Code1,
				max(case when ColN=2 then [Value] end) as EMBR_Code2,
				max(case when ColN=3 then [Value] end) as EMBR_Code3,
				max(case when ColN=4 then [Value] end) as EMBR_Code4
	from 
		(select OrderId, [value], row_number() over (partition by Orderid order by Orderid)  as ColN
			from 
				(select Orderid, ponumber, value from 
					(select orderid, ponumber , comments26 from lca.dbo.orders with (nolock)
						where orderid in (
										 select distinct Orderid from lca.dbo.OrderItems 
													where OrderItemID in (select firstOrderItemID from Manufactureorders with (nolock)
												where manufactureid in ( select distinct ManufactureID from #TBoxes3))
										)
					) abcde123
					cross apply string_split(Comments26,',')
				) cba123
		) yuy123
	 group by Orderid

--select * from #TSales_PNew where Style='82176'	 and color='632'
create table #ABC11_Pre (
    Waybill varchar(200) null,
	HTSDescription varchar(200) null,
	ShipDate date null,
	InvoiceBatch varchar(200) null,
	Batch varchar(200) null,
	PONumber varchar(200) null,
	BoxNumber varchar(200) null,
	StyleNumber varchar(200) null,
	SeasonName varchar(200) null,
	Stylecolor varchar(200) null,
	Qty_pre decimal(12,2) null,
	Original_qty decimal(12,2) null,
	OrderID int  null,
	EmbroideryCode varchar(200) null, 
	GarmentSize varchar(200) null,
	ManufactureID int null,
	ProductDivision varchar(200) null,
	RO varchar(200) null,
	RO_ID int  null,
	MO varchar(255) null,
	Embr_Code1 varchar(250) null,
	Embr_Code2 varchar(250) null,
	Embr_Code3 varchar(250) null,
	Embr_Code4 varchar(250) null,
	PrintLocations varchar(250) null,
	PrintCount varchar(250)  null,
	OrderTypeID2 int null,
	StyleOptionID int null,
	CountryOfOrigin varchar(200) null,
	Manufacturer varchar(200) null,
	Vendor_2 varchar(200) null
)

insert into #ABC11_Pre
Select
			ABC10.Waybill,
			ABC10.HTSDescription,
			ABC10.ShipDate,
			ABC10.InvoiceBatch,
			ABC10.Batch,
			ABC10.PONumber,
			ABC10.BoxNumber,
			ABC10.StyleNumber,
			ABC10.SeasonName,
			ABC10.Stylecolor,
			case when charindex('bund',ABC10.waybill)=0
					then round(ABC10.Qty * isnull(TB_MO89.Proportion,1)   ,2) 
					else round(ABC10.Qty * isnull(TB_MO892.Proportion,1)  ,2) 
			end as Qty_pre,
			abc10.qty as Original_Qty,
			--TB_MO89.Proportion as propor,
			ABC10.OrderId,
			ABC10.EmbroiderCode,
			ABC10.GarmentSize,
			ABC10.ManufactureID ,
			ABC10.ProductDivision,
			ABC10.RO,
			ABC10.RO_ID,
			isnull(TYU.MO,TYU2.MO) AS MO,
			isnull(NewEmbr.Embr_Code1,isnull(NewEmbr2.Embr_Code1,'')) as Embr_Code1,
			isnull(NewEmbr.Embr_Code2,isnull(NewEmbr2.Embr_Code2,'')) as Embr_Code2,
			isnull(NewEmbr.Embr_Code3,isnull(NewEmbr2.Embr_Code3,'')) as Embr_Code3,
			isnull(NewEmbr.Embr_Code4,isnull(NewEmbr2.Embr_Code4,'')) as Embr_Code4,
			isnull(EMBR1.comments8   ,isnull(EMBR1_2.comments8   ,'')) as PrintLocations, 
			isnull(EMBR1.comments14  ,isnull(EMBR1_2.comments14  ,'')) as PrintCount,
			isnull(EMBR1.OrderTypeId2,isnull(EMBR1_2.OrderTypeId2,'')) as OrderTypeID2,
			case	when charindex('bund',ABC10.waybill)=0 and MO2.Comments17 is not null and ltrim(MO2.Comments17)<>''  
						and MO1.Comments17 is null
					 	then cast( (substring(MO2.Comments17,1,  charindex('|',MO2.Comments17) -1) ) as int) 
					when charindex('bund',ABC10.waybill)=0 and MO1.Comments17 is not null and ltrim(MO1.Comments17)<>''
							and MO1.ManufactureID is not null
						then cast( (substring(MO1.Comments17,1,  charindex('|',MO1.Comments17) -1) ) as int) 

					when charindex('bund',ABC10.waybill)>0 and MO2_2.Comments17 is not null and ltrim(MO2_2.Comments17)<>''  
						and MO1_2.Comments17 is null
					 	then cast( (substring(MO2_2.Comments17,1,  charindex('|',MO2_2.Comments17) -1) ) as int) 
					when charindex('bund',ABC10.waybill)>0 and MO1_2.Comments17 is not null and ltrim(MO1_2.Comments17)<>''
							and MO1_2.ManufactureID is not null
						then cast( (substring(MO1_2.Comments17,1,  charindex('|',MO1_2.Comments17) -1) ) as int) 
					else 0
			end as StyleOptionID
			,case when charindex('bund',ABC10.waybill)=0
					then  isnull(TB_MO89.CountryOfOrigin,TB_MO89_2.CountryOfOrigin) 
					else isnull(TB_MO892.CountryOfOrigin,TB_MO89_2_2.CountryOfOrigin) 
				end as CountryOfOrigin
			,case when charindex('bund',ABC10.waybill)=0 
					then isnull(TB_MO89.Manufacturer,TB_MO89_2.Manufacturer) 
					else isnull(TB_MO892.Manufacturer,TB_MO89_2_2.Manufacturer) 
				end as Manufacturer
			,case when charindex('bund',ABC10.waybill)=0  
					then isnull(TB_MO89.Vendor,TB_MO89_2.Manufacturer)
					else isnull(TB_MO892.Vendor,TB_MO89_2_2.Manufacturer)
				end as Vendor_2
				
	--SELECT *
	from #TBoxes3 ABC10
		left join  [LCA].[dbo].[VW_Check_Sales_Prices_in_Invoices_SeekMO_2]  TYU with (nolock)
			on ABC10.BoxNumber = TYU.BoxNumber
			and ABC10.ManufactureID = TYU.MOID
		left join lca.dbo.ManufactureOrders MO1 with (nolock)
			on TYU.MOID=MO1.manufactureID and MO1.StatusID <=90
		left join lca.dbo.Orders EMBR1 with (nolock)
			on MO1.OrderID = EMBR1.OrderID and EMBR1.StatusID <=90 
		left join [LCA].[dboReaders].[VW_EORO] VWEORO with (nolock)
			on TYU.MOID = VWEORO.EO_ID and ABC10.RO_ID = VWEORO.RO_ID
		left join lca.dbo.ManufactureOrders MO2 with (nolock)
			on VWEORO.RO_ID = MO2.ManufactureID and MO2.StatusID <=90
		left join lca.dbo.Orders EMBR2 with (nolock)
			on MO2.OrderID=EMBR2.OrderID and EMBR1.StatusID <=90 
		left join (SELECT Style_Blank, Style_EMB, StyleID_Emb, StyleID_Blank, SeasonName_BLANK, SeasonName_EMB
									FROM [LCA].[dboReaders].[VW_ESC_StyleStructure] with (nolock) WHERE Style_EMB <> Style_BLANK
					) BlankStyle
			on ABC10.StyleNumber = BlankStyle.Style_EMB AND ABC10.SeasonName = BlankStyle.SeasonName_EMB
			--- SE AGREGA RELACION CON SEASON PARA QUE NO DUPLIQUE CUANDO SEA ESTILOS CONTRACTS Y HECHOS EN LCA  (AGREGADO POR RR Y DP 20251024)
		left join 	[AppsLCA].[dbo].[TB_MO_PartNumber_IM_Summary] TB_MO89 with (nolock) 
			on MO2.ManufactureID = TB_MO89.ManufactureID
			--on ISNULL(MO2.ManufactureID,MO1.ManufactureID) = TB_MO89.ManufactureID

				and isnull(BlankStyle.Style_Blank,ABC10.StyleNumber) = TB_MO89.Style
				and ABC10.StyleColor = TB_MO89.Color
				and ABC10.GarmentSize = TB_MO89.Size
		left join [AppsLCA].[dbo].[TB_MO_PartNumber_IM_COO_Per_MO] TB_MO89_2 with (nolock) 
			on MO1.ManufactureID = TB_MO89_2.ManufactureID
		left join #TEmbrCodes NewEmbr 
			on MO1.OrderID = NewEmbr.OrderID 
		---Agregando por Waybill Bundle
		left join  [LCA].[dbo].[VW_Check_Sales_Prices_in_Invoices_SeekMO_Bundle]  TYU2 with (nolock)
			on ABC10.BoxNumber = TYU2.BoxNumber
			and ABC10.ManufactureID = TYU2.MOID
		left join lca.dbo.ManufactureOrders MO1_2 with (nolock)
			on TYU2.MOID=MO1_2.manufactureID 
		left join #TEmbrCodes NewEmbr2
			on MO1_2.OrderID = NewEmbr2.OrderID 
		left join lca.dbo.Orders EMBR1_2 with (nolock)
			on MO1_2.OrderID = EMBR1_2.OrderID 
		left join [LCA].[dboReaders].[VW_EORO] VWEORO_2 with (nolock)
			on TYU2.MOID = VWEORO_2.EO_ID
		left join lca.dbo.ManufactureOrders MO2_2 with (nolock)
			on VWEORO_2.RO_ID = MO2_2.ManufactureID 
		left join lca.dbo.Orders EMBR2_2 with (nolock)
			on MO2_2.OrderID=EMBR2.OrderID 
		left join 	[AppsLCA].[dbo].[TB_MO_PartNumber_IM_Summary] TB_MO892 with (nolock) 
			on MO1_2.ManufactureID = TB_MO892.ManufactureID
				and isnull(BlankStyle.Style_Blank,ABC10.StyleNumber) = TB_MO892.Style
				and ABC10.StyleColor = TB_MO892.Color
				and ABC10.GarmentSize = TB_MO892.Size
		left join [AppsLCA].[dbo].[TB_MO_PartNumber_IM_COO_Per_MO] TB_MO89_2_2 with (nolock) 
			on MO1_2.ManufactureID = TB_MO89_2_2.ManufactureID
			--where abc10.BoxNumber = '01001683'

---Eliminar valor caracter que vienen en el campo Printcount 2024 09 27 Boris Hernandez, Edwin Figueroa
update #ABC11_Pre set PrintCount = iif( try_cast(PrintCount as int) is null, 0, PrintCount )

--select * from #ABC11_Pre where BoxNumber = '01025177'
--return

insert into #TBoxes2
select distinct ABC11.*,
	--isnull(SaleEmb1.Total,0)+isnull(SaleEmb2.Total,0)+isnull(SaleEmb3.Total,0)+isnull(SaleEmb4.Total,0) as Embr_Total,
	--COALESCE(OrdPR.TotalPrintValue,OrdPR_2.[Total Print Value]) as Embr_Total,
	 CASE WHEN VerProc.Total >0  or VerProc.Techni_qty$>0  then VerProc.Total + VerProc.Techni_qty$
				else COALESCE(OrdPR.TotalPrintValue,OrdPR_2.[Total Print Value]) 
	 END 
	 + case when VerProc.WF_Print >0 and charindex('FG',ABC11.SeasonName)=0 then 0
			when VerProc.Total >0 or VerProc.Techni_qty$>0 then 0.16
			else 0
	   end
	 as Embr_Total,
	--OrdPR.TotalPrintValue as Embr_Total,
	DDV2.DropDownValue as TypeORD, 
		case when charindex('FG',ABC11.SeasonName) >0 and charindex('To Print (Screen Print Only)', DDV2.DropDownValue)>0
				then isnull(SalePri_FG.CostEmb,0)
			when charindex('FG',ABC11.SeasonName) >0 and charindex('To Embroi', DDV2.DropDownValue)>0
				then OrdPR.TotalPrintValue
			when charindex('FG',ABC11.SeasonName)>0 and charindex('Blanks', DDV2.DropDownValue)>0
				then 0
			when charindex('FG',ABC11.SeasonName)=0 and charindex('To Print (Screen Print Only)', DDV2.DropDownValue)>0
				then isnull(SalePri_Full.CostEmb,0)
			when charindex('FG',ABC11.SeasonName)=0 and charindex('To Embroi', DDV2.DropDownValue)>0
				then OrdPR.TotalPrintValue
			when charindex('FG',ABC11.SeasonName)=0 and charindex('Blanks', DDV2.DropDownValue)>0
				then 0
				else isnull(SalePri_Full.CostEmb,0)
			end as Total_SP_Subli
			,isnull(SaleEmb1.LaborProduction,0) + isnull(SaleEmb2.LaborProduction,0) + 
				isnull(SaleEmb3.LaborProduction,0) + isnull(SaleEmb3.LaborProduction,0) as Embr_Code_Labor
			,case when ABC11.PrintLocations is not null and ABC11.PrintCount>0 
				then @VScreenPr * ABC11.PrintCount
				else 0
				end as ScreenPrint_Labor
			,0 as Cuenta
	from 
	---Esta ciclo se ejecuta para asignar correctamente las unidades por MO, cuando una misma talla haya recibido prendas de dos o mas Vendors
	---Boris Hernandez y Rodrigo Ramirez 2024 09 11
		(select waybill, HTSDescription, ShipDate, InvoiceBatch, Batch, PONumber, BoxNumber, StyleNumber,SeasonName, Stylecolor, sum(qty) as qty,
			OrderID, EmbroideryCode, GarmentSize, ManufactureID,ProductDivision,RO,RO_ID,MO,Embr_Code1,Embr_Code2,Embr_Code3,Embr_Code4,PrintLocations,
			PrintCount,OrderTypeID2,StyleOptionID,CountryOfOrigin,Manufacturer,Vendor_2
			from (
					select	Waybill , HTSDescription, ShipDate , InvoiceBatch, Batch , PONumber, BoxNumber, StyleNumber ,
							SeasonName,Stylecolor,	case	when Original_qty = qty_2 and Original_qty=Qty_pre then qty_2
																	when original_qty-cum_qty >0 then qty_2 
																	else qty_2 - abs(original_qty-cum_qty)
															end as Qty,
								OrderID , EmbroideryCode ,	GarmentSize ,	ManufactureID ,	ProductDivision ,
								RO ,RO_ID ,	MO , Embr_Code1 ,	Embr_Code2 ,	Embr_Code3 ,	Embr_Code4 , PrintLocations ,PrintCount ,
								OrderTypeID2 ,	StyleOptionID ,	CountryOfOrigin ,Manufacturer ,	Vendor_2 
					from 
						(select *,round(qty_pre,0) as qty_2,
								 sum(round(qty_pre,0)) over(partition by boxnumber,StyleNumber, StyleColor, GarmentSize, RO 
												order	 by StyleNumber, StyleColor, GarmentSize,RO ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as cum_qty	from #abc11_pre) abc112
				) abc79823 group by waybill, HTSDescription, ShipDate, InvoiceBatch, Batch, PONumber, BoxNumber, StyleNumber,SeasonName, Stylecolor,
									OrderID, EmbroideryCode, GarmentSize, ManufactureID,ProductDivision,RO,RO_ID,MO,Embr_Code1,Embr_Code2,Embr_Code3,
									Embr_Code4,PrintLocations,PrintCount,OrderTypeID2,StyleOptionID,CountryOfOrigin,Manufacturer,Vendor_2
		) ABC11
			left join Appslca.dbo.[ImportExport_AnexoFacturacion_CheckPrices] VerProc with (nolock)
				on ABC11.OrderID = VerProc.OrderID and ABC11.StyleNumber = VerProc.stylenumber and ABC11.Stylecolor = VerProc.StyleColor
				and ABC11.Waybill = VerProc.waybill And ABC11.SeasonName = VerProc.SeasonName --- Se agrega relación por waybill debido a que hay órdenes que no se van en una exportación completa
													--- AGREGADO POR Rodrigo Ramírez 20251031
			left join #SalesEmbroidery SaleEMB1
				on ABC11.Embr_Code1 = SaleEmb1.Code
			left join #SalesEmbroidery SaleEMB2
				on ABC11.Embr_Code2 = SaleEmb2.Code
			left join #SalesEmbroidery SaleEMB3
				on ABC11.Embr_Code3 = SaleEmb3.Code
			left join #SalesEmbroidery SaleEMB4
				on ABC11.Embr_Code4 = SaleEmb4.Code
			left join #TSales_PNew  SalePri_Full 
				on ABC11.StyleNumber=SalePri_Full.Style and ABC11.Stylecolor=SalePri_Full.Color 
					and isnull(ABC11.StyleOPtionId,0) = isnull(SalePri_Full.StyleOptionID,0)
					--and SalePri_Full.Season NOT IN ('BLANK','Blank RO','EXP BO','EMB','EMB FG','BLANK FG')
					and SalePri_Full.Season NOT IN ('BLANK','Blank RO','EXP BO','EMB FG','BLANK FG')
			left join #TSales_PNew  SalePri_FG
				on ABC11.StyleNumber=SalePri_FG.Style and ABC11.Stylecolor=SalePri_FG.Color 
					and ABC11.SeasonName=SalePri_FG.Season and SalePri_FG.Season  IN ('BLANK FG','EMB FG') 
					and isnull(ABC11.StyleOPtionId,0) = isnull(SalePri_FG.StyleOptionID,0)
			left join [LCA].[dbo].[DropDownValues2] DDV2 with (nolock) 
					on ABC11.OrderTypeID2=DDV2.DropDownValueID
			left join [LCA].[dboReaders].[VW_Planning_OrderItemsPriceRev_2] OrdPR with (nolock) 
				on ABC11.ManufactureID = OrdPr.ManufactureID
				and ABC11.PoNumber = OrdPR.Ponumber
				and ABC11.StyleColor = OrdPr.Color
			left join [LCA].[dboReaders].[VW_Planning_OrderItemsPriceRev_3] ORDPR_2 with (nolock)  					--- Vista que trae el precio de Embroidery para los Bundle --- Agregado por Rodrigo Ramirez 20250530
				on	abc11.BoxNumber = OrdPR_2.boxnumber and
					abc11.StyleNumber = ORDPR_2.StyleNumber and
					abc11.GarmentSize = ORDPR_2.GarmentSize and
					abc11.Stylecolor	 = ORDPR_2.StyleColorName

--select * from #TSales_PNew where Style='esmc200' and Color='NAV' and Season='EMB fg' and Season in ('BLANK FG','EMB FG') 
--	and (StyleOptionID=0 or StyleOptionID is null)


--select * from #TBoxes1
--SELECT * FROM #ABC11_Pre

--select * from #TBoxes3

--aqui voy 


Create table #OrigFab (
	EO varchar(200) null,
	OrigFabricVendorName varchar(200),
	Index IX_2 Nonclustered (EO)
)
insert into #OrigFab
Select EO, OrigFabricVendorname
	from 					
		(	Select EO, row_number() over(Partition by EO order by EO, Units desc) as Cuenta,
					RO, OrigFabricVendorName, Units
				from 
					(Select  VWEORO.EO, VWEORO.RO, sum(VWEORO.UnitsEORO) as Units, VWVendor.OrigFabricVendorName
							from  [LCA].[dboReaders].[VW_EORO] VWEORO with (nolock)
						left join  [192.168.1.93].[AppsLCA].[dbo].[TA_Planning_DispatchRO_OriginalVendor] VWVendor with (nolock)
						on VWEORO.RO = VWVendor.MO
						where VWEORO.EO in (select distinct MO from #Tboxes2)
						group by VWEORO.EO, VWEORO.RO,  VWVendor.OrigFabricVendorName
					) XYZ1
		) XYZ2 where Cuenta=1


create table  #TBaseCost  (
	Purchase_Order varchar(max) null,
	CostoPonderado decimal(12,2) null,
	EO varchar(200) null,
	BoxNumber varchar(200) null,
	Style varchar(200) null,
	Color varchar(200) null,
	Size varchar(200) null,
	RO varchar(max),
	EO_ID int null,
	RO_ID int null
)
----fabric
--select * from #TBoxes2 where ro= 'RO240315ESMC100-003'

--select * from #TBoxes2 where mo='TO022825O05PDT-101' --ro='RO022805PDT-101'
--select * from #TBaseCost where eo='TO022825O05PDT-101'-- ro='RO022805PDT-101'

--select * from #TBaseCost where ro in ('RO240315ESMC100-003','RO022805PDT-101') order by ro

insert into #TBaseCost
	select distinct 
		(select string_agg([value],', ') from (select distinct [value] from string_split(string_agg(PONumber, ','),',')) t) as Purchase_Order,
		--sum(CostoPonderado_2*UnitEORO)/ sum(UnitEORO) as CostoPonderado, 
		case when sum(isnull(UnitEORO,0)) > 0 then sum(CostoPonderado_2*UnitEORO)/ sum(UnitEORO) else 0 end as CostoPonderado,
		EO,  BoxNumber, Style, Color, Size,
		(select string_agg([value],', ') from (select distinct [value] from string_split(string_agg(RO, ','),',')) t) as RO,
		 EO_ID, RO_ID
	from 
		(
		Select distinct PoNumber, BoxNumber, Style, EO,  Color,  Size
			,Case when sum(isnull(UnitsEORO,0)) > 0 then round( sum(UnitsEORO*UnitCost)  /	sum(isnull(UnitsEORO,0)),2)
				else 0 end as CostoPonderado_2
			,EO_ID
			,sum(isnull(UnitsEORO,0)) as UnitEORO
			,RO,RO_ID
			from 
			(
					select distinct TBox2.BoxNumber, VWEORO.EO, isnull(TBOX2.RO,VWEORO.RO) as RO,
									VWEORO.UnitsEORO,
									isnull(TBOX2.RO_ID,VWEORO.RO_ID) as RO_ID,
									VWEORO.EO_ID, TBOX2.StyleNumber as Style, TBOX2.StyleColor as Color, TBOX2.GarmentSize as Size, TBOX2.Qty
						,isnull(TempCP.PONumber,TempCP_2.PONumber) as PONumber, isnull(TempCP.Unitcost,TempCP_2.Unitcost) as UnitCost
					from #TBoxes2 TBOX2
					left outer join Appslca.dbo.TB_MO_PartNumber_IM_EORO VWEORO with (nolock)
						on	TBOX2.MO= VWEORO.EO and TBOX2.StyleNUmber = VWEORO.EO_Style
							and TBOX2.GarmentSize = VWEORO.Size 
							AND VWEORO.UnitsEORO > 0

					left outer join 
					 
							(select ManufactureNumber, PartNumber, PONumber, sum(abs(quantity)) as qty, max(UnitCost) as Unitcost , 
									substring(Partnumber,1, CHARINDEX('-',PartNUmber)-1) as Style,
							case when charindex('-',PartNumber)>0
									then substring( PartNumber ,1, charindex('-',PartNumber)-1)
									else '' end as NewStyle,
							case
									when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-')=1
									then
										substring(PartNumber,charindex('-',PartNumber)+1, 5  )
								when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-')>=2
					 					and ( right(PartNumber,1) not in ('S','M','L') and right(PartNumber,2) not in ('XS','XL','2T','3T','4T','5T','6T','7T','8T')
										AND right(PartNumber,3) not in ('2XL','3XL','4XL','5XL','XXL','S_M','ADJ','S/M')
										and right(PartNumber,4) not in ('L_XL','L/XL')
										)
										then 
											substring(PartNumber,charindex('-',PartNumber)+1,99)
									when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-')>=2
										then 
											substring(PartNumber,charindex('-',PartNumber)+1,
											charindex('-',PartNumber,charindex('-',PartNumber)+1) -
											len(substring(PartNumber,1, charindex('-',PartNumber)-1)) -2) 
								else ''
								end as NewColor,
								case	
										when right(PartNumber,5) in ('-L_XL','-L/XL')
													then right(PartNumber,4)
										when right(PartNumber,4) in ('-2XL','-3XL','-4XL','-5XL','-XXL','-S_M','-ADJ','-S/M')
											then right(PartNumber,3)
										when right(PartNumber,3) in ('-XS','-XL','-2T','-3T','-4T','-5T','-6T','-7T','-8T')
											then right(PartNumber,2)
										when right(PartNumber,2) in ('-S','-M','-L')
											Then right(PartNumber,1)
										else ''
								end as NewGarmentSize
										from  [appslca].[dbo].[VW_Check_Sales_Prices_in_ReceiveSlips] with (nolock)
										--where manufacturenumber in ('RO022805PDT-101')
										--where manufacturenumber in ('NG102723CCCW115-600') --('NG122223ESYC100-305-1','L20609ESYC100-305','NG11924CCW115-503','TO0315O82176-HWTROH')
										--where manufacturenumber in ('NG16515-ESMC100-488','NG091523BESMC100-488')
										group by ManufactureNumber, PartNumber, PONumber
							) TempCP
						on isnull(TBOX2.RO,VWEORO.RO) = TempCP.ManufactureNumber
						and VWEORO.RO_Style = TempCP.Style and VWEORO.Size = TempCP.NewGarmentSize
					left outer join 
							(select ManufactureNumber, PartNumber, PONumber, sum(abs(quantity)) as qty, max(UnitCost) as Unitcost , 
									substring(Partnumber,1, CHARINDEX('-',PartNUmber)-1) as Style,
							case when charindex('-',PartNumber)>0
									then substring( PartNumber ,1, charindex('-',PartNumber)-1)
									else '' end as NewStyle,
							case
									 when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-')=1
										then
											substring(PartNumber,charindex('-',PartNumber)+1, 5  )
									 when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-')>=2 and right(PartNumber,5) = 'CAFTA'
										then SUBSTRING(Partnumber,CHARINDEX('-',Partnumber)+1, CHARINDEX('-',Partnumber,CHARINDEX('-',Partnumber)+1) -CHARINDEX('-',Partnumber)-1)
									 when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-')>=2
					 					and ( right(PartNumber,1) not in ('S','M','L') and right(PartNumber,2) not in ('XS','XL','2T','3T','4T','5T','6T','7T','8T')
												AND right(PartNumber,3) not in ('2XL','3XL','4XL','5XL','XXL','S_M','ADJ','S/M')
												and right(PartNumber,4) not in ('L_XL','L/XL')
												)
										then 
										substring(PartNumber,charindex('-',PartNumber)+1,99)
									 when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-')=2
										then 
											 substring(PartNumber,charindex('-',PartNumber)+1,
											 charindex('-',PartNumber,charindex('-',PartNumber)+1) -
											 len(substring(PartNumber,1, charindex('-',PartNumber)-1)) -2) 
									 when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-')>=3
					 					and ( right(PartNumber,1)  in ('S','M','L') OR right(PartNumber,2)  in ('XS','XL','2T','3T','4T','5T','6T','7T','8T')
												or right(PartNumber,3)  in ('2XL','3XL','4XL','5XL','XXL','S_M','ADJ','S/M')
												or right(PartNumber,4)  in ('L_XL','L/XL')
												)
										then 
										SUBSTRING(Partnumber,CHARINDEX('-',Partnumber)+1,
											CHARINDEX('-',Partnumber,CHARINDEX('-',Partnumber, (CHARINDEX('-',Partnumber)+1))+1)  -
											CHARINDEX('-',LTRIM(RTRIM(Partnumber)))  -1)
									 when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-')>2
										then 
											 SUBSTRING(Partnumber,CHARINDEX('-',Partnumber)+1, CHARINDEX('-',Partnumber,CHARINDEX('-',Partnumber)+1) -CHARINDEX('-',Partnumber)-1)
									  else ''
								end as NewColor,
								case
										when right(PartNumber,5) in ('-L_XL','-L/XL')
											then right(PartNumber,4)
										when right(PartNumber,4) in ('-2XL','-3XL','-4XL','-5XL','-XXL','-S_M','-ADJ','-S/M')
											then right(PartNumber,3)
										when right(PartNumber,3) in ('-XS','-XL','-2T','-3T','-4T','-5T','-6T','-7T','-8T')
											then right(PartNumber,2)
										when right(PartNumber,2) in ('-S','-M','-L')
											Then right(PartNumber,1)
										else ''
								end as NewGarmentSize
										from  [appslca].[dbo].[VW_Check_Sales_Prices_in_ReceiveSlips] with (nolock)
										--where manufacturenumber in ('RO022805PDT-101')
										--where manufacturenumber in ('NG16515-ESMC100-488','NG091523BESMC100-488')
										group by ManufactureNumber, PartNumber, PONumber
							) TempCP_2
						on VWEORO.RO = TempCP_2.ManufactureNumber
						and VWEORO.RO_Style = TempCP_2.Style 
					--where eo in ('TO0301ESYC100-305','EO3758875-503','TO0315O82176-HWTROH')

			) ABC1
			group by  ABC1.PONumber, ABC1.Style, ABC1.Color, ABC1.Size, ABC1.RO,
					 ABC1.BoxNumber, ABC1.EO, ABC1.EO_ID, ABC1.RO_ID

		) as ABC2	
		group by BoxNumber, Style, Color, Size, EO,  EO_ID, RO, RO_ID

create table #TBaseCost_Fabric(
	ManufactureNumber varchar(200) null,
	ManufactureID int null,
	PoNumber varchar(300)

)

insert into #TBaseCost_Fabric
SELECT ManufactureNumber, ManufactureID, 
(select string_agg([value],', ') from (select distinct [value] from string_split(string_agg(PoNumber, ','),',')) t) as Ponumber
  FROM [LCA].[dbo].[VW_Check_Sales_Prices_in_ReceiveSlips_Fabric] with (nolock)
  --'3542086-CPTN'
  where manufactureID  in (select distinct ManufactureID from #TBoxes2)   
  group by ManufactureNumber, ManufactureID


create table #TPartNumber (
	ManufactureId int null,
	PartNumber varchar(300) null,
	Category varchar(200) null,
	NewStyle varchar(200) null,
	NewColor varchar(200) null,
	NewSize varchar(200) null
)
insert into #TPartNumber
select ManufactureId, 
	(select string_agg([value],', ') from (select distinct [value] from string_split(string_agg(PartNumber, ','),',')) t) as PartNumber,
	Category,
	substring(PartNumber,1,charindex('-',Partnumber)-1) as NewStyle,
 	case
		when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-')=1
			then
				substring(PartNumber,charindex('-',PartNumber)+1, 5  )
		when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-')>=2
		and ( right(PartNumber,1) not in ('S','M','L') and right(PartNumber,2) not in ('XS','XL','2T','3T','4T','5T','6T','7T','8T')
				AND right(PartNumber,3) not in ('2XL','3XL','4XL','5XL','XXL','S_M','ADJ','S/M')
				and right(PartNumber,4) not in ('L_XL','L/XL')
				)
			then 
			substring(PartNumber,charindex('-',PartNumber)+1,99)
		when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-')=2
			then 
					substring(PartNumber,charindex('-',PartNumber)+1,
					charindex('-',PartNumber,charindex('-',PartNumber)+1) -
					len(substring(PartNumber,1, charindex('-',PartNumber)-1)) -2) 
		when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-')>2  and
			right(
					substring(PartNumber,charindex('-',PartNumber)+1,
					charindex('-',PartNumber,charindex('-',PartNumber,charindex('-',PartNumber)+1)+1) -
					len(substring(PartNumber,1, charindex('-',PartNumber)-1))-2) 
					,2)='-F'
			then 
					substring(PartNumber,charindex('-',PartNumber)+1,
					charindex('-',PartNumber,charindex('-',PartNumber)+1) -
					len(substring(PartNumber,1, charindex('-',PartNumber)-1)) -2) 
		when (len(PartNumber) - len(replace(PartNumber, '-', ''))) / len('-')>2  and
			right(
					substring(PartNumber,charindex('-',PartNumber)+1,
					charindex('-',PartNumber,charindex('-',PartNumber,charindex('-',PartNumber)+1)+1) -
					len(substring(PartNumber,1, charindex('-',PartNumber)-1))-2) 
					,2)<>'-F'
			then 
					substring(PartNumber,charindex('-',PartNumber)+1,
					charindex('-',PartNumber,charindex('-',PartNumber,charindex('-',PartNumber)+1)+1) -
					len(substring(PartNumber,1, charindex('-',PartNumber)-1))-2) 
		else ''
		end as NewColor,
		case
			when right(PartNumber,4) in ('L_XL','L/XL')
				then right(PartNumber,4)
			when right(PartNumber,3) in ('2XL','3XL','4XL','5XL','XXL','S_M','ADJ','S_M','S/M')
				then right(PartNumber,3)
			when right(PartNumber,2) in ('XS','XL','2T','3T','4T','5T','6T','7T','8T')
				then right(PartNumber,2)
			when right(PartNumber,1) in ('S','M','L')
				then right(PartNumber,1)
				else ''
		end as NewSize
	from (
			Select ManufactureID,
			 replace(REPLACE(REPLACE(REPLACE(RTRIM(PartNumber),CHAR(9), ''),CHAR(10),''),CHAR(13),''),' ','')
			  as PartNumber, Category from 
				  appslca.dbo.TB_MO_PartNumber_IM with (nolock)
				where manufactureID  in (select distinct ManufactureID from #TBoxes2)   
			          and category='Contracts' --and Partnumber in ('CFA-WHT-F-ADJ','ML510-809-S','CFV-NAV-F-ADJ  ')
			) abcd
	group by ManufactureID, Category, PartNumber

--select * from #TPartNumber
--select * from #tPartNumber where manufactureid=451182



--completando el Costo Ponderado que va nulo
declare @Purchase_Order varchar(200) 
declare @CostoPonderado decimal(12,2) 
declare @Style varchar(200) 
declare @Color varchar(200) 

declare @EO_ID_2 varchar(200)
declare @RO_ID_2 varchar(200)

--select distinct EO_ID from #TBaseCost where CostoPonderado is null

create table #TCostP1 (
	CostoPonderado decimal(18,4) null,
	ManufactureID int null
	)

insert into #TCostP1
select 
	sum(PurchaseOrderUnitPrice * iif(Consumption is null or Consumption=0,1,Consumption )) / 
	iif(sum(iif(Consumption is null or Consumption=0,1,Consumption ))=0,1,
	sum(iif(Consumption is null or Consumption=0,1,Consumption )))
		as CostoPonderado, ManufactureID
	from appslca.dbo.TB_MO_PartNumber_IM with (nolock)
	--where mo='TO0315O82176-HWTROH' and category='Contracts'
	where  category in ('Contracts','Fabric')
	group by ManufactureID


create table #TPurch (
	Purchase_Order varchar(500) null,
	ManufactureID int null,
	RO_ID int null
)
insert into #TPurch
select substring((select string_agg([value],', ') from (select distinct [value] from string_split(string_agg(PONumber, ','),',')) t),1,500)
	 as Purchase_Order
		,ManufactureID, RO_ID
		from appslca.dbo.TB_MO_PartNumber_IM with (nolock)
			--where mo='TO0315O82176-HWTROH' and category='Contracts'
		where  category in ('Contracts','Fabric')
		group by ManufactureID, RO_ID

 update TBC
	set TBC.CostoPonderado = TCosP1.CostoPonderado
	from  #TBaseCost TBC
	left join  #TCostP1 TCosP1 
		on TBC.EO_ID = TCosP1.ManufactureID
	where TBC.EO_Id is not null

update TBC2
	set TBC2.Purchase_Order = TPC.Purchase_Order
	from  #TBaseCost TBC2
	left join  #TPurch TPC
		on TBC2.EO_ID = TPC.ManufactureID and isnull(TBC2.RO_ID,0) = isnull(TPC.RO_ID,0)
	where TBC2.EO_Id is not null

--Select * from #Tpurch where ManufactureID=469917
--select * from #TBaseCost where eo_id=469917
--select distinct eo_id, ro_id from #TBaseCost where eo_id is not null


--Select * from #TBaseCost-- where eo='EO3956637-600'

create table #TStdCost_Full(
	Style varchar(200) null,
	Color Varchar(200) null,
	StyleOptionID1 int null,
	Fabric decimal(18,4) null,
	Thread decimal(18,4) null,
	Trims  decimal(18,4) null,
	Handling decimal(18,4) null,
	SewLabor decimal(18,4) null,
	Supplies decimal(18,4) null,
	CutLabor decimal(18,4) null,
	Contracts decimal(18,4) null,
	Subassembly decimal(18,4) null,
	index IX_abc Nonclustered (Style, Color, StyleOptionID1)
)

create table #TStdCost_FG(
	Style varchar(200) null,
	Color Varchar(200) null,
	StyleOptionID1 int null,
	Fabric decimal(18,4) null,
	Thread decimal(18,4) null,
	Trims  decimal(18,4) null,
	Handling decimal(18,4) null,
	SewLabor decimal(18,4) null,
	Supplies decimal(18,4) null,
	CutLabor decimal(18,4) null,
	Contracts decimal(18,4) null,
	Subassembly decimal(18,4) null,
	index IX_abc123 Nonclustered (Style, Color, StyleOptionID1)
)
insert into #TStdCost_Full
select * from [192.168.1.93].[AppsLCA].[dbo].[TA_StdCost_Full]

--Select Style, Color, StyleOptionID1, [Fabric] as Fabric, [Thread] as Thread, [Trim] as Trims, [Handling] as Handling, [SewLabor] as SewLabor, [Supplies] as Supplies, [CutLabor] as CutLabor,
--		[Contracts] as Contracts, [Subassembly] as Subassembly
--	from   
--		(	select sum(cast (SubTotal as decimal(18,4))) as SubTotal, CategoryName, Style, Color, StyleOptionID1	
--				from 
--					(SELECT VESC.*,  CCC.CategoryName FROM [LCA].[dboReaders].[VW_ESC_ALL_PARAMETERS_Flex] VESC WITH (NOLOCK)
--					  LEFT OUTER JOIN (
--										  SELECT ComponentName, ComponentCategoryID
--											from 
--												(SELECT  ComponentName, ComponentCategoryID, ROW_NUMBER() OVER(PARTITION BY COMPONENTNAME ORDER BY COMPONENTNAME) AS CUENTA
--												  FROM [LCA].[dbo].[ComponentLibrary] with (nolock)
--												  WHERE StatusID <=90
--												  GROUP BY ComponentName, ComponentCategoryID
		  
--												) abc
--											where cuenta=1
--										) CSB
--						 ON VESC.Component = CSB.ComponentName
--					  LEFT OUTER JOIN [LCA].[dbo].[ComponentCategories] CCC WITH (NOLOCK)
--						 ON CSB.ComponentCategoryID = CCC.ComponentCategoryID
--					where  EngineSeason='BLANK - EMB Cost' -- and style = 'ac240' AND COLOR='003'  AND EngineCategory='Fabric'
--						--and StyleOptionID1=1537
--				   ) abc
--				   group by CategoryName, Style, Color, StyleOptionID1
--			) p
--	Pivot(
--		sum(SubTotal) for CategoryName in ([Fabric], [Thread], [Trim], [Handling], [SewLabor], [Supplies], [CutLabor],[Contracts],[Subassembly] )
--		) as pvt

insert into #TStdCost_FG
select * from [192.168.1.93].[AppsLCA].[dbo].[TA_TStdCost_FG]
--Select Style, Color, StyleOptionID1, [Fabric] as Fabric, [Thread] as Thread, [Trim] as Trims, [Handling] as Handling, [SewLabor] as SewLabor, [Supplies] as Supplies, [CutLabor] as CutLabor,
--		[Contracts] as Contracts, [Subassembly] as Subassembly
--	from   
--		(	select sum(cast (SubTotal as decimal(18,4))) as SubTotal, CategoryName, Style, Color, StyleOptionID1	
--				from 
--					(SELECT VESC.*,  CCC.CategoryName FROM [LCA].[dboReaders].[VW_ESC_ALL_PARAMETERS_Flex] VESC WITH (NOLOCK)
--					  LEFT OUTER JOIN (
--										  SELECT ComponentName, ComponentCategoryID
--											from 
--												(SELECT  ComponentName, ComponentCategoryID, ROW_NUMBER() OVER(PARTITION BY COMPONENTNAME ORDER BY COMPONENTNAME) AS CUENTA
--												  FROM [LCA].[dbo].[ComponentLibrary] with (nolock)
--												  WHERE StatusID <=90
--												  GROUP BY ComponentName, ComponentCategoryID
		  
--												) abc
--											where cuenta=1
--										) CSB
--						 ON VESC.Component = CSB.ComponentName
--					  LEFT OUTER JOIN [LCA].[dbo].[ComponentCategories] CCC WITH (NOLOCK)
--						 ON CSB.ComponentCategoryID = CCC.ComponentCategoryID
--					where  EngineSeason='BLANK FG - EMB FG'  --style = 'UW125' AND COLOR='901' AND
--				   ) abc
--				   group by CategoryName, Style, Color, StyleOptionID1
--			) p
--	Pivot(
--		sum(SubTotal) for CategoryName in ([Fabric], [Thread], [Trim], [Handling], [SewLabor], [Supplies], [CutLabor],[Contracts],[Subassembly] )
--		) as pvt

--select * from  #TStdCost_Full where style ='05pdt' and color='012'
--select * from  #TStdCost_FG   where style ='05pdt' and color='012'
create table #abc4_1 (
	boxnumber varchar(100) null,
	Stylenumber varchar(100) null,
	StyleColor   varchar(100) null,
	GarmentSize  varchar(100)  null,
	CA_HTSCode varchar(100) null,
	SalePrice decimal(12,2) null,
	BlankStyleCostMaterials1 decimal(12,2) null,
	SeasonName varchar(50) null
)

create table #abc4_2 (
	boxnumber varchar(100) null,
	GrossWeightKGSAll decimal(18,4) null,
	NetWeightKGSAll decimal(18,4) null
)

insert into #abc4_1
select distinct boxnumber ,
			   StyleNumber ,
			   StyleColor ,
			   GarmentSize,
			   CA_HTSCode ,
			   SalePrice,
			   BlankStyleCostMaterials1,
			   SeasonName
	from [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll]   with (nolock)
	where  boxnumber in (select distinct boxnumber from #TBoxes1)
		group by boxnumber ,
				StyleNumber ,
				StyleColor ,
				GarmentSize,
				CA_HTSCode ,
			    SalePrice,
				BlankStyleCostMaterials1,
				SeasonName

create table #abc4_3 (
	batch varchar(200) null,
	metodo int null
	)

--select * from #TBoxes2

---Metodo 1: Sales price *0.8
---Metodo 2: (BasePrice * Qty) +  (isnull(BlankStyleCostMaterials1,0) * Qty))
insert into #abc4_3
select batch, --isnull(t1,0) + isnull(t2,0) as t31, t32,
	 iif(isnull(t1,0) + isnull(t2,0) >= isnull(t32,0), 1,2 ) as Metodo
	from (select tyu123.*, abcd123.t2, jkl123.t32
					from (select batch, sum(isnull(BlankStyleCostMaterials1,0) *quantity) as t1 
						from   AppsLCA.dbo.ImportExport_ShipmentBoxAll with (nolock)
						where   waybill in (select distinct waybill from #TBoxes2 )
						group by batch) tyu123
				left join (
							select shipnotes, sum(baseprice * quantity) as t2 
								from AppsLCA.dbo.ImportExport_ApproveInvoice_Generated  with (nolock)
								where waybill in (select distinct waybill from #TBoxes2 )
								group by shipnotes)	abcd123
						on tyu123.Batch = abcd123.ShipNotes
				left join (select batch, sum(SalePrice) as t32
							from   AppsLCA.dbo.ImportExport_ShipmentBoxAll with (nolock)
								where   waybill in (select distinct waybill from #TBoxes2 )
								group by batch) jkl123
						on tyu123.Batch = jkl123.Batch
			) mnb123

insert into #abc4_2
select   boxnumber ,
		sum(GrossWeightKGSAll) as GrossWeightKGSAll ,
		sum(NetWeightKGSAll) as NetWeightKGSAll
	from [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll]   with (nolock)
	where  boxnumber in (select distinct boxnumber from #TBoxes1)
		group by boxnumber 

--select * from #abc4_2 where boxnumber ='00714369'
Create table #TBoxes5(
	InvoiceBatch varchar(200) null,
	BasePrice decimal (12,2) null,
	)
insert into #TBoxes5
select distinct InvoiceBatch, BasePrice from appslca.dbo.ImportExport_ApproveInvoice_Generated with (nolock)
		where InvoiceBatch in (select distinct InvoiceBatch from #TBoxes2)

--select * from #abc4_3


Create Table  #TBoxes4 (
    Waybill varchar(200) null,
	HTSDescription varchar(200) null,
	ShipDate date null,
	InvoiceBatch varchar(200) null,
	Batch varchar(200) null,
	PONumber varchar(200) null,
	BoxNumber varchar(200) null,
	StyleNumber varchar(200) null,
	SeasonName varchar(200) null,
	Stylecolor varchar(200) null,
	Qty decimal(12,2) null,
	OrderID int  null,
	EmbroideryCode varchar(200) null, 
	GarmentSize varchar(200) null,
	ManufactureID int null,
	ProductDivision varchar(200) null,
	RO varchar(200) null,
	RO_ID int  null,
	MO varchar(255) null,
	Embr_Code1 varchar(250) null,
	Embr_Code2 varchar(250) null,
	Embr_Code3 varchar(250) null,
	Embr_Code4 varchar(250) null,
	PrintLocations varchar(250) null,
	PrintCount varchar(250)  null,
	OrderTypeID2 int null,
	StyleOptionID int null,
	CountryOfOrigin varchar(200) null,
	Manufacturer varchar(200) null,
	Vendor_2 varchar(200) null,
	Embr_Total decimal(10,2) null,
	TypeOrd varchar(250) null,
	Total_Sp_Subli decimal(12,2) null,
	Embr_Code_Labor decimal(12,2) null,
	ScreenPrint_Labor decimal(12,2) null,
	Cuenta int null
)
insert into #TBoxes4
select Waybill ,
	HTSDescription ,
	ShipDate ,
	InvoiceBatch ,
	Batch ,
	PONumber ,
	BoxNumber ,
	StyleNumber ,
	SeasonName ,
	Stylecolor ,
	Qty ,
	OrderID ,
	EmbroideryCode , 
	GarmentSize ,
	ManufactureID ,
	ProductDivision ,
	RO ,
	RO_ID,
	MO ,
	Embr_Code1 ,
	Embr_Code2 ,
	Embr_Code3 ,
	Embr_Code4 ,
	PrintLocations ,
	PrintCount ,
	OrderTypeID2 ,
	StyleOptionID ,
	CountryOfOrigin ,
	Manufacturer ,
	Vendor_2 ,
	Embr_Total ,
	TypeOrd ,
	Total_Sp_Subli ,
	Embr_Code_Labor ,
	ScreenPrint_Labor ,
	ROW_NUMBER() over(partition by boxnumber  order by boxnumber ) as Cuenta from #tboxes2

--Borrar tabla temporal #TBoxes2 para prepararla para la acutalizacion del row_number
delete from #TBoxes2

--select * from #tboxes2 where boxnumber ='00718452'

create table  #Report (
	ShipDate date null,
	Waybill varchar(200) null,
	InvoiceBatch varchar(200) null,
	Batch varchar(200) null,
	PONumber varchar(200) null,
	BoxNumber varchar(200) null,
	StyleNumber varchar(200) null,
	SeasonName varchar(200) null,
	Qty decimal(12,2) null,
	Size varchar(200) null,
	Supplier varchar(200) null,
	HTSDescription varchar(200) null,
	BasePrice decimal(12,2) null,
	Handling decimal(12,2) null,
	Total_Handling decimal(12,2) null,
	Freight decimal(12,2) null,
	Total_Freight decimal(12,2) null,
	BaseCost decimal(12,2) null,
	Total_Base_Cost decimal(12,2) null,
	Receiving_Cost decimal(12,2) null,
	Total_Receiving_Cost decimal(12,2) null,
	RO varchar(200) null,
	RO_ID int null, 
	Purchase_order varchar(200) null,
	PrintCount varchar(200) null,
	Screen_Print decimal(12,2) null,
	Total_Screen_Print decimal(12,2) null,
	Embroidery decimal(12,2) null,
	Total_Embroidery decimal(12,2) null,
	Sublimation decimal(12,2) null,
	Total_Sublimation decimal(12,2) null,
	Price decimal(12,2) null,
	[Total$] decimal(12,2) null,
	OrderID int null,
	MO varchar(200) null,
	Embr_Code1 varchar(200) null,
	Embr_Code2 varchar(200) null,
	Embr_Code3 varchar(200) null,
	Embr_Code4 varchar(200) null,
	Embr_Code_Labor decimal(12,2) null,
	ScreenPrint_Labor decimal(12,2) null,
	PrintLocations varchar(200) null,
	CountryOfOrigin varchar(200) null,
	ProductDivision varchar(200) null,
	Manufacturer varchar(200) null,
	SemiFinishProductCost decimal(12,2) null,
	SemiFinishProductCost_Fabric decimal(12,2) null,
	SemiFinishProductCost_Thread decimal(12,2) null,
	SemiFinishProductCost_Trim decimal(12,2) null,
	SemiFinishProductCost_Supplies decimal(12,2) null,
	SemiFinishProductCost_Contracts decimal(12,2) null,
	SemiFinishProductCost_SubAssembly decimal(12,2) null,
	FinishProductCost decimal(12,2) null,
	FinishProductCost_Fabric decimal(12,2) null,
	FinishProductCost_Thread decimal(12,2) null,
	FinishProductCost_Trim decimal(12,2) null,
	FinishProductCost_Supplies decimal(12,2) null,
	FinishProductCost_Contracts decimal(12,2) null,
	FinishProductCost_SubAssembly decimal(12,2) null,
	Consigned varchar(100) null,
	StyleColor varchar(200) null,
	PartNumber varchar(200) null,
	ManufactureID int null,
	STdCost_Fabric   decimal(12, 2) NULL,
	STdCost_Thread   decimal(12, 2) NULL,
	STdCost_Trims    decimal(12, 2) NULL,
	STdCost_Handling decimal(12, 2) NULL,
	STdCost_SewLabor decimal(12, 2) NULL,
	STdCost_Supplies decimal(12, 2) NULL,
	STdCost_CutLabor decimal(12, 2) NULL,
	STdCost_Contracts decimal(12, 2) NULL,
	STdCost_Subassembly decimal(12, 2) NULL,
	StyleOptionID int  NULL,
	StyleOptionName    varchar(200) NULL,
	UnitStdCost_Fabric decimal(12, 4) NULL,
	UnitStdCost_Thread decimal(12, 4) NULL,
	UnitStdCost_Trims decimal(12, 4) NULL,
	UnitStdCost_Handling decimal(12, 4) NULL,
	UnitStdCost_SewLabor decimal(12, 4) NULL,
	UnitStdCost_Supplies decimal(12, 4) NULL,
	UnitStdCost_CutLabor decimal(12, 4) NULL,
	UnitStdCost_Contracts decimal(12, 4) NULL,
	UnitStdCost_Subassembly decimal(12, 4) NULL
	,SAC Varchar(50) null
	,UDM Varchar(50) null
	,ComponentValue decimal(12,4) NULL
	,AssemblyValue decimal(12,4) NULL
	,GrossWeightKGSAll decimal(12,4) NULL
	,NetWeightKGSAll decimal(12,4) NULL
	,Container Varchar(100) null
	,TempGrossWG decimal(12,4)
	,TempoNetWeight decimal(12,4)
	,TempQty decimal(12,2)
	,Cuenta int null
	,Receiving_Cost_Ponderado decimal(12,2) null
	,Total_Receiving_Cost_Ponderado decimal(18,4) null
)

insert into #Tboxes2
select * from #TBoxes4

--Actualizamos valor de Printcount a null para aquellos Print Count =0 2024 09 30 Boris Hernandez
UPDATE #TBoxes2 set PrintCount=null where PrintCount=0

---Actualizamos estilo de venta por estilo de inventario
UPDATE TB2 SET StyleNumber = SaleST.InventoryStyle
from #TBoxes2 TB2 WITH(NOLOCK) 
INNER JOIN 
(
	SELECT 
			[SaleStyle]		= ST1.[StyleNumber]
		,[InventoryStyle]	= ST2.[StyleNumber]
	FROM LCA.dbo.Styles			AS ST1 WITH(NOLOCK)
	INNER JOIN LCA.dbo.Styles	AS ST2 WITH(NOLOCK) ON ST1.BlankStyleID = ST2.StyleID 
	AND ST1.BlankStyleID IS NOT NULL and IIF(ST2.StyleNumber = ST1.StyleNumber,1,0) = 0
	GROUP BY ST1.StyleNumber, ST2.StyleNumber
) AS SaleST ON TB2.StyleNumber = SaleST.SaleStyle AND WayBill = @VWaybill

--select * from #tboxes2 --where boxnumber ='00773784'


insert into #Report
Select distinct	 ABC2.ShipDate, 
	 --isnull(ABC4.Waybill , ABC2.Waybill) as Waybill  ,
	  REPLACE(REPLACE(REPLACE(RTRIM(isnull(ABC4.Waybill , ABC2.Waybill)),CHAR(9), ''),CHAR(10),''),CHAR(13),'') 
	   as waybill,
	 ABC2.InvoiceBatch, ABC2.Batch, ABC2.PONumber, ABC2.BoxNumber, ABC2.StyleNumber,
	 ABC2.SeasonName,
	 ABC2.QTY, ABC2.GarmentSize as Size,
	 isnull(ABC2.OrigFabricVendorName, ABC2.Vendor_2) as Supplier, ABC2.HTSDescription, 
	
	case when substring(ABC2.Waybill,1,2)='SM'	then isnull(ABC3.BasePrice,ABC4.UnitPrice)
		 --when charindex('bund',ABC2.Waybill)=0	then OrdPR.BasePrice
		 when charindex('bund',ABC2.Waybill)=0	then COALESCE(OrdPR.BasePrice,ABC3.BasePrice,ABC4.UnitPrice)
		 when charindex('bund',ABC2.Waybill)>0	then ORDPR_2.BasePrice
		 end as BasePrice,
	
	case  when substring(ABC2.Waybill,1,2)='SM' then 0 
		  when charindex('FG',ABC2.SeasonName)>0 then  0.10 else 0 end as Handling,
	ABC2.QTY * case  when substring(ABC2.Waybill,1,2)='SM' then 0 
		  when charindex('FG',ABC2.SeasonName)>0 then  0.10 else 0 end as Total_Handling,
	case  when substring(ABC2.Waybill,1,2)='SM' then 0 
		  when charindex('FG',ABC2.SeasonName)>0 then  0.25 else 0 end as Freight, 
	ABC2.QTY * case  when substring(ABC2.Waybill,1,2)='SM' then 0 
		  when charindex('FG',ABC2.SeasonName)>0 then  0.25 else 0 end as Total_Freight,
	 
	---Estos campos se van a Revisar con Rogelio e Ivan dada la nueva estructura de precios de venta 2025 10 16
	--case when substring(ABC2.Waybill,1,2)='SM' then isnull(ABC3.BasePrice,ABC4.UnitPrice)
	--	 when CHARINDEX('FG',ABC2.SeasonName)>0  
	--		then ABC4.UnitPrice
	--			---ScreenPrint
	--				- case when ABC2.PrintCount is null or ABC2.PrintCount='' then 0 	
	--					else  COALESCE(ABC3.TotalPrintValue,OrdPR.TotalPrintValue,OrdPR_2.[Total Print Value]) end
	--			---Sublimation
	--				- case when charindex('To Subli',ABC2.TypeOrd)>0 then ABC2.Total_Sp_Subli else 0  end
	--			---Embroidery
	--				- case when charindex('To Embro',ABC2.TypeOrd)>0 then ABC2.Embr_Total else 0  end 
	--			---Handling and Freight
	--			    -- 0.1 - 0.25
	--	 else 
	--			ABC4.UnitPrice
	--			---ScreenPrint
	--				- case when ABC2.PrintCount is null or ABC2.PrintCount='' then 0 	
	--					else  COALESCE(ABC3.TotalPrintValue,OrdPR.TotalPrintValue,OrdPR_2.[Total Print Value]) end
	--			---Sublimation
	--				- case when charindex('To Subli',ABC2.TypeOrd)>0 then ABC2.Total_Sp_Subli else 0  end
	--			---Embroidery
	--				- case when charindex('To Embro',ABC2.TypeOrd)>0 then ABC2.Embr_Total else 0  end 
	--	   end as BaseCost,

	--ABC2.QTY *	case when substring(ABC2.Waybill,1,2)='SM' then isnull(ABC3.BasePrice,ABC4.UnitPrice)
	--			 when CHARINDEX('FG',ABC2.SeasonName)>0  
	--				then ABC4.UnitPrice
	--					---ScreenPrint
	--						- case when ABC2.PrintCount is null or ABC2.PrintCount='' then 0 	else  COALESCE(ABC3.TotalPrintValue,OrdPR.TotalPrintValue,OrdPR_2.[Total Print Value]) end
	--					---Sublimation
	--						- case when charindex('To Subli',ABC2.TypeOrd)>0 then ABC2.Total_Sp_Subli else 0  end
	--					---Embroidery
	--						- case when charindex('To Embro',ABC2.TypeOrd)>0 then ABC2.Embr_Total else 0  end 
	--					---Handling and Freight
	--						-- 0.1 - 0.25
	--			 else 
	--					ABC4.UnitPrice
	--					---ScreenPrint
	--						- case when ABC2.PrintCount is null or ABC2.PrintCount='' then 0 	else  COALESCE(ABC3.TotalPrintValue,OrdPR.TotalPrintValue,OrdPR_2.[Total Print Value]) end
	--					---Sublimation
	--						- case when charindex('To Subli',ABC2.TypeOrd)>0 then ABC2.Total_Sp_Subli else 0  end
	--					---Embroidery
	--						- case when charindex('To Embro',ABC2.TypeOrd)>0 then ABC2.Embr_Total else 0  end 
	--			   end 
	--	 as Total_Base_Cost,
	
	case when substring(ABC2.Waybill,1,2)='SM'	then isnull(ABC3.BasePrice,ABC4.UnitPrice)
		 --when charindex('bund',ABC2.Waybill)=0	then OrdPR.BasePrice
		 when charindex('bund',ABC2.Waybill)=0	then COALESCE(OrdPR.BasePrice,ABC3.BasePrice,ABC4.UnitPrice)
		 when charindex('bund',ABC2.Waybill)>0	then ORDPR_2.BasePrice
		 end as BaseCost,

	ABC2.QTY * case when substring(ABC2.Waybill,1,2)='SM'	then isnull(ABC3.BasePrice,ABC4.UnitPrice)
					--when charindex('bund',ABC2.Waybill)=0	then OrdPR.BasePrice
					when charindex('bund',ABC2.Waybill)=0	then COALESCE(OrdPR.BasePrice,ABC3.BasePrice,ABC4.UnitPrice)
					when charindex('bund',ABC2.Waybill)>0	then ORDPR_2.BasePrice
				end
	as Total_Base_Cost,

	case when charindex('FG',ABC2.SeasonName)>0 then isnull(TBCost.CostoPonderado,TBCost_2.CostoPonderado)
		 else 0
		 end as Receiving_Cost,
	ABC2.QTY * case when charindex('FG',ABC2.SeasonName)>0 then isnull(TBCost.CostoPonderado,TBCost_2.CostoPonderado)
		 else 0
		 end as Total_Receiving_Cost,
	--isnull(ABC2.RO,TBCost_2.RO) as RO,
	ABC2.RO,
	ABC2.RO_ID,
	case when charindex('FG',ABC2.SeasonName)>0 then TBCost.Purchase_Order
		 else isnull(TBCost_Fabric.PoNumber,'')
		 end as Purchase_order,

	isnull(ABC2.PrintCount,'') as PrintCount,  
	
	case when ABC2.PrintCount is null or ABC2.PrintCount='' then 0 
		--else  COALESCE(ABC3.TotalPrintValue,OrdPR.TotalPrintValue,OrdPR_2.[Total Print Value]) 
			else   CASE WHEN ABC3.TotalPrintValue >0 then iif(isnull(VerProc.WF_Print,0)>0, 0.95 * VerProc.WF_Print,0)
						else COALESCE(OrdPR.TotalPrintValue,OrdPR_2.[Total Print Value]) 
				   END
				   + case	when VerProc.WF_Print >0 and charindex('FG',ABC2.SeasonName)=0 then 0.16
	 				 else 0 end
		end as Screen_Print, 

	ABC2.QTY * (CASE when ABC2.PrintCount is null or ABC2.PrintCount='' then 0 
				--else  COALESCE(ABC3.TotalPrintValue,OrdPR.TotalPrintValue,OrdPR_2.[Total Print Value]) 
				ELSE  case when ABC3.TotalPrintValue >0 then iif(isnull(VerProc.WF_Print,0)>0, 0.95 * VerProc.WF_Print,0)
						else COALESCE(OrdPR.TotalPrintValue,OrdPR_2.[Total Print Value]) 
					  END
				+	case	when VerProc.WF_Print >0 and charindex('FG',ABC2.SeasonName)=0 then 0.16
					else 0 end
				end) as Total_Screen_Print,
	
	--case when charindex('To Embro',ABC2.TypeOrd)>0 then ABC2.Embr_Total else 0  
	case
		when CHARINDEX('BND',ABC2.Waybill)>0 and charindex('To Embro',ABC2.TypeOrd)>0 then ABC2.Embr_Total--- QUITAR CUANDO LA REVISION DE PRECIOS DETECTE BIEN LOS WAYBILS BUNDLES AGREGADO POR RODRIGO RAMIREZ 20251121
		when charindex('To Subli',ABC2.TypeOrd)>0 AND VerProc.Subl_qty>0 then 0
		when VerProc.Total >0 or VerProc.Techni_qty$>0  then VerProc.Total + VerProc.Techni_qty$ else 0 end
		 + (case when VerProc.WF_Print >0 and charindex('FG',ABC2.SeasonName)=0 then 0
				when charindex('To Subli',ABC2.TypeOrd)>0 AND VerProc.Subl_qty>0 then 0
				 when (VerProc.Total >0 or VerProc.Techni_qty$>0) and charindex('FG',ABC2.SeasonName)=0 then 0.16
		   else 0 end)
	as Embroidery,

	--ABC2.QTY * case when charindex('To Embro',ABC2.TypeOrd)>0 then ABC2.Embr_Total else 0  end as Total_Embroidery,
	ABC2.QTY * case 
					when CHARINDEX('BND',ABC2.Waybill)>0 and charindex('To Embro',ABC2.TypeOrd)>0 then ABC2.Embr_Total --- QUITAR CUANDO LA REVISION DE PRECIOS DETECTE BIEN LOS WAYBILS BUNDLES AGREGADO POR RODRIGO RAMIREZ 20251121
					when charindex('To Subli',ABC2.TypeOrd)>0 AND VerProc.Subl_qty>0 then 0
					when VerProc.Total >0 or VerProc.Techni_qty$>0 then VerProc.Total + VerProc.Techni_qty$ else 0 end
		 + (case when VerProc.WF_Print >0 and charindex('FG',ABC2.SeasonName)=0 then 0
				when charindex('To Subli',ABC2.TypeOrd)>0 AND VerProc.Subl_qty>0 then 0
				 when (VerProc.Total >0 or VerProc.Techni_qty$>0) and charindex('FG',ABC2.SeasonName)=0 then 0.16
		   else 0 end)
	as Total_Embroidery,

	case when charindex('To Subli',ABC2.TypeOrd)>0 AND VerProc.Subl_qty>0 then VerProc.TotalPrintValue 
		 when ABC2.StyleNumber = '31144' AND ABC2.SeasonName = 'EMB' then ABC2.Total_Sp_Subli - 0.16 else 0  end 
	--+ case when VerProc.WF_Print >0 and charindex('FG',ABC2.SeasonName)=0 then 0
	--			when (VerProc.Total >0 or VerProc.Techni_qty$>0) and charindex('FG',ABC2.SeasonName)=0 then 0
	--			when ABC2.Total_Sp_Subli > 0 and VerProc.Subl_qty > 0 and charindex('FG',ABC2.SeasonName)=0 then 0.16
	--  else 0 end
	as Sublimation,
	
	--ABC2.QTY * case when charindex('To Subli',ABC2.TypeOrd)>0 then ABC2.Total_Sp_Subli else 0  end 
	ABC2.QTY * 	case when charindex('To Subli',ABC2.TypeOrd)>0 AND VerProc.Subl_qty>0 then VerProc.TotalPrintValue 
					 when ABC2.StyleNumber = '31144' AND ABC2.SeasonName = 'EMB' then ABC2.Total_Sp_Subli - 0.16 else 0  end 
					--+ case when VerProc.WF_Print >0 and charindex('FG',ABC2.SeasonName)=0 then 0
					--		when (VerProc.Total >0 or VerProc.Techni_qty$>0) and charindex('FG',ABC2.SeasonName)=0 then 0
					--		when ABC2.Total_Sp_Subli >0 and VerProc.Subl_qty > 0 and charindex('FG',ABC2.SeasonName)=0 then 0.16
					--  else 0 end
	as Total_Sublimation,

	case when substring(ABC2.Waybill,1,2)='SM' then isnull(ABC3.BasePrice,ABC4.UnitPrice)
		 when charindex('bund',ABC2.Waybill)=0 and ABC4.UnitPrice <> COALESCE(ABC3.Price,0.00) then ABC4.UnitPrice
		 when charindex('bund',ABC2.Waybill)=0									then ABC3.Price
		 when charindex('bund',ABC2.Waybill)>0									then ABC4.UnitPrice
	 end as Price,

	case when substring(ABC2.Waybill,1,2)='SM' then isnull(ABC3.BasePrice,ABC4.UnitPrice) * ABC2.Qty
		 when charindex('bund',ABC2.Waybill)=0 and  ABC4.UnitPrice <> COALESCE(ABC3.Price,0.00)	then ABC4.UnitPrice * ABC2.Qty
		 when charindex('bund',ABC2.Waybill)=0										then ABC3.Price * ABC2.Qty 
		 when charindex('bund',ABC2.Waybill)>0										then ABC4.UnitPrice * ABC2.Qty
	end as [Total_$]

	,ABC2.OrderID
	,TB_sum.MO
	,ABC2.Embr_Code1
	,ABC2.Embr_Code2
	,ABC2.Embr_Code3
	,ABC2.Embr_Code4
	,ABC2.Embr_Code_Labor
	,ABC2.ScreenPrint_Labor

	,ABC2.PrintLocations

	,ABC2.CountryOfOrigin
	,ABC2.ProductDivision
	,ABC2.Manufacturer
----Headwear
	, case when charindex('FG',ABC2.SeasonName)>0  
		then	(round(TB_sum.Fabric      / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY) + 
				(round(TB_sum.Thread      / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY) +
				(round(TB_sum.[Trim]      / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY) +
				(round(TB_sum.Supplies    / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY) +
				(round(TB_sum.Contracts   / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY) +
				(round(TB_sum.SubAssembly / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY)
		else 0
		end as SemiFinishProductCost
	,case when charindex('FG',ABC2.SeasonName)>0  then round(TB_sum.Fabric / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY
	    else 0
		end as SemiFinishProductCost_Fabric
	,case when charindex('FG',ABC2.SeasonName)>0  then round(TB_sum.Thread / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY
	    else 0
		end as SemiFinishProductCost_Thread
	,case when charindex('FG',ABC2.SeasonName)>0  then round(TB_sum.[Trim] / iif(TB_sum.Make=0,1,TB_sum.Make) ,2) * ABC2.QTY
	    else 0
		end as SemiFinishProductCost_Trim
	,case when charindex('FG',ABC2.SeasonName)>0  then round(TB_sum.Supplies / iif(TB_sum.Make=0,1,TB_sum.Make) ,2) * ABC2.QTY
	    else 0
		end as SemiFinishProductCost_Supplies
	,case when charindex('FG',ABC2.SeasonName)>0  then round(TB_sum.Contracts / iif(TB_sum.Make=0,1,TB_sum.Make) ,2) * ABC2.QTY
	    else 0
		end as SemiFinishProductCost_Contracts
	,case when charindex('FG',ABC2.SeasonName)>0  then round(TB_sum.SubAssembly / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY
	    else 0
		end as SemiFinishProductCost_SubAssembly
---Apparel
	, case when charindex('FG',ABC2.SeasonName)=0  
		then 
				(round(TB_sum.Fabric      / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY)+ 
				(round(TB_sum.Thread      / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY)+
				(round(TB_sum.[Trim]      / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY)+
				(round(TB_sum.Supplies    / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY)+
				(round(TB_sum.Contracts   / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY)+
				(round(TB_sum.SubAssembly / iif(TB_sum.Make = 0,1,TB_sum.Make) ,2) * ABC2.QTY)
		else 0
		end as FinishProductCost
	,case when charindex('FG',ABC2.SeasonName)=0  then round(TB_sum.Fabric / iif(TB_sum.Make=0,1,TB_sum.Make) ,2) * ABC2.QTY
	    else 0
		end as FinishProductCost_Fabric
	,case when charindex('FG',ABC2.SeasonName)=0  then round(TB_sum.Thread / iif(TB_sum.Make=0,1,TB_sum.Make) ,2) * ABC2.QTY
	    else 0
		end as FinishProductCost_Thread
	,case when charindex('FG',ABC2.SeasonName)=0  then round(TB_sum.[Trim] / iif(TB_sum.Make=0,1,TB_sum.Make) ,2) * ABC2.QTY
	    else 0
		end as FinishProductCost_Trim
	,case when charindex('FG',ABC2.SeasonName)=0  then round(TB_sum.Supplies / iif(TB_sum.Make=0,1,TB_sum.Make) ,2) * ABC2.QTY
	    else 0
		end as FinishProductCost_Supplies
	,case when charindex('FG',ABC2.SeasonName)=0  then round(TB_sum.Contracts / iif(TB_sum.Make=0,1,TB_sum.Make) ,2) * ABC2.QTY
	    else 0
		end as FinishProductCost_Contracts
	,case when charindex('FG',ABC2.SeasonName)=0  then round(TB_sum.SubAssembly / iif(TB_sum.Make=0,1,TB_sum.Make) ,2) * ABC2.QTY
	    else 0
		end as FinishProductCost_SubAssembly
	, case when ABC2.Manufacturer like 'NG TEXTILES%'  and substring(TBCost.Purchase_Order,1,3)='FEL'
			then 'Yes'
		   when ABC2.Manufacturer like 'NG TEXTILES%'  and substring(TBCost.Purchase_Order,1,3)<>'FEL'
		    then 'No'
		   else 'N/A'
		end as Consigned
	, ABC2.Stylecolor as [Color]
	, case when TPart.PartNumber is not null then TPart.PartNumber
			else isnull(TPart_2.PartNumber,'')
	  end as PartNumber
	, ABC2.ManufactureID
	, case when charindex('FG',ABC2.SeasonName)=0  then isnull(TStd_Full.Fabric,0) * ABC2.Qty 
			Else  isnull(TStd_FG.Fabric,0) * ABC2.Qty end as STdCost_Fabric
	, case when charindex('FG',ABC2.SeasonName)=0  then isnull(TStd_Full.Thread,0) * ABC2.Qty 
			Else  isnull(TStd_FG.Thread,0) * ABC2.Qty end as STdCost_Thread
	, case when charindex('FG',ABC2.SeasonName)=0  then isnull(TStd_Full.Trims,0) * ABC2.Qty 
			Else  isnull(TStd_FG.Trims,0) * ABC2.Qty end as STdCost_Trims
	, case when charindex('FG',ABC2.SeasonName)=0  then isnull(TStd_Full.Handling,0) * ABC2.Qty 
			Else  isnull(TStd_FG.Handling,0) * ABC2.Qty end as STdCost_Handling

	, case when charindex('FG',ABC2.SeasonName)=0  then isnull(TStd_Full.SewLabor,0) * ABC2.Qty 
			Else  isnull(TStd_FG.SewLabor,0) * ABC2.Qty end as STdCost_SewLabor

	, case when charindex('FG',ABC2.SeasonName)=0  then isnull(TStd_Full.Supplies,0) * ABC2.Qty 
			Else  isnull(TStd_FG.Supplies,0) * ABC2.Qty end as STdCost_Supplies

	, case when charindex('FG',ABC2.SeasonName)=0  then isnull(TStd_Full.CutLabor,0) * ABC2.Qty 
			Else  isnull(TStd_FG.CutLabor,0) * ABC2.Qty end as STdCost_CutLabor

	, case when charindex('FG',ABC2.SeasonName)=0  then isnull(TStd_Full.Contracts,0) * ABC2.Qty 
			Else  isnull(TStd_FG.Contracts,0) * ABC2.Qty end as STdCost_Contracts

	, case when charindex('FG',ABC2.SeasonName)=0  then isnull(TStd_Full.Subassembly,0) * ABC2.Qty 
			Else  isnull(TStd_FG.Subassembly,0) * ABC2.Qty end as STdCost_Subassembly
	,isnull(abc2.StyleOptionID,0) as StyleOptionID
	,case when isnull(abc2.StyleOptionID,0) = 0 then '0 | NO OPTION AVAILABLE'
		   else StyOpt.StyleOptionName end as StyleOptionName

	,case when charindex('FG',ABC2.SeasonName)=0 then isnull(TStd_Full.Fabric,0)   
		   else isnull(TStd_FG.Fabric,0) end as UnitStdCost_Fabric
	,case when charindex('FG',ABC2.SeasonName)=0 then  isnull(TStd_Full.Thread,0)
		   else isnull(TStd_FG.Thread,0) end  as UnitStdCost_Thread
	,case when charindex('FG',ABC2.SeasonName)=0 then isnull(TStd_Full.Trims,0)  
		   else isnull(TStd_FG.Trims,0) end as UnitStdCost_Trims
	,case when charindex('FG',ABC2.SeasonName)=0 then isnull(TStd_Full.Handling,0) 
		   else isnull(TStd_FG.Handling,0) end as UnitStdCost_Handling
	,case when charindex('FG',ABC2.SeasonName)=0 then isnull(TStd_Full.SewLabor,0) 
	       else isnull(TStd_FG.SewLabor,0) end as UnitStdCost_SewLabor
	,case when charindex('FG',ABC2.SeasonName)=0 then isnull(TStd_Full.Supplies,0)
		   else isnull(TStd_FG.Supplies,0) end as UnitStdCost_Supplies
	,case when charindex('FG',ABC2.SeasonName)=0 then isnull(TStd_Full.CutLabor,0)
		   else isnull(TStd_FG.CutLabor,0)  end  as UnitStdCost_CutLabor
	,case when charindex('FG',ABC2.SeasonName)=0 then isnull(TStd_Full.Contracts,0)
		   else isnull(TStd_FG.Contracts,0) end as UnitStdCost_Contracts
	,case when charindex('FG',ABC2.SeasonName)=0 then isnull(TStd_Full.Subassembly,0) 
	       else isnull(TStd_FG.Subassembly,0) end as UnitStdCost_Subassembly
	
	,ABC4_1.CA_HTSCode as SAC
    ,'each' as UDM
    
	, case when  abc4_3.metodo=1
			then (case when substring(ABC2.Waybill,1,2)='SM' then isnull(ABC3.BasePrice,ABC4.UnitPrice) * ABC2.Qty
						when ABC4.UnitPrice <> COALESCE(ABC3.Price,0.00) then ABC4.UnitPrice * ABC2.Qty
						else ABC3.Price * ABC2.Qty end
					) *0.8
			when charindex('bund',ABC2.Waybill)>0 then isnull(ABC3.BasePrice,ABC4.UnitPrice) * ABC2.Qty *0.8
			else (ABC5_1.BasePrice * ABC2.Qty) +  (isnull(abc4_1.BlankStyleCostMaterials1,0)*ABC2.Qty)
			end as ComponentValue

    , case when  abc4_3.metodo=1
			then (case when substring(ABC2.Waybill,1,2)='SM' then isnull(ABC3.BasePrice,ABC4.UnitPrice) * ABC2.Qty
						when ABC4.UnitPrice <> COALESCE(ABC3.Price,0.00) then ABC4.UnitPrice * ABC2.Qty
						else ABC3.Price * ABC2.Qty end
					) * 0.2
			when charindex('bund',ABC2.Waybill)>0 then isnull(ABC3.BasePrice,ABC4.UnitPrice) * ABC2.Qty *0.2
			else (case when substring(ABC2.Waybill,1,2)='SM' then isnull(ABC3.BasePrice,ABC4.UnitPrice) * ABC2.Qty
						when ABC4.UnitPrice <> COALESCE(ABC3.Price,0.00) then ABC4.UnitPrice * ABC2.Qty
						else ABC3.Price * ABC2.Qty end
					) - 
					((ABC5_1.BasePrice * ABC2.Qty) +  (isnull(abc4_1.BlankStyleCostMaterials1,0)*ABC2.Qty))
			end 
			 as AssemblyValue
	
    ,isnull(ABC4_2.GrossWeightKGSAll,0) as GrossWeightKGSAll
    ,isnull(ABC4_2.NetWeightKGSAll,0) as  NetWeightKGSAll
	,(select distinct shp.ContainerNumber
		from lca.dbo.ShippingContainers  Cont with (nolock)
			left outer join  lca.dbo.Shipments shp with (nolock)
				on cont.ContainerNumber = shp.ContainerNumber
				where shp.WayBill = REPLACE(REPLACE(REPLACE(RTRIM(isnull(ABC4.Waybill , ABC2.Waybill)),CHAR(9), ''),CHAR(10),''),CHAR(13),'')
				AND shp.[StatusID] < 95) as Container
	,0 as TempGrossWG
	,0 as TempoNetWeight
	,0 as TempQty
	,Cuenta
	,0 as Receiving_Cost_Ponderado 
	,0 as Total_Receiving_Cost_Ponderado 
from  
	(
		Select distinct XYZ2.*, XYZ3.OrigFabricVendorName
			from #TBoxes2 XYZ2	
			left join #OrigFab XYZ3
				on XYZ2.MO = XYZ3.EO

			--left join [LCA].[dbo].[VW_Check_Sales_Prices_in_Invoices_SeekMO_2]  VWS1 with (nolock)
			--	on XYZ2.Boxnumber = VWS1.BoxNumber
			--left join #OrigFab XYZ3
			--	on VWS1.MO = XYZ3.EO
	) ABC2
	--select * from #TBoxes2 --where BoxNumber='00709896'

	left join  [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll]   ABC4 with (nolock)
		ON ABC2.BoxNumber = ABC4.BoxNumber
		and ABC2.StyleNumber = ABC4.StyleNumber
		and abc2.Stylecolor = ABC4.StyleColor
		--and abc2.GarmentSize = ABC4.GarmentSize  
		--select * from #TBoxes2 where boxnumber ='00673224'
		
		/* left join Appslca.dbo.[ImportExport_AnexoFacturacion_CheckPrices] VerProc with (nolock)
	
		on ABC2.OrderID = VerProc.OrderId and  abc4.StyleNumber = VerProc.BlankStyle and abc4.StyleColor = VerProc.StyleColor
		and ABC4.WayBill = VerProc.waybill And ABC4.SeasonName = VerProc.SeasonName 
		CAMBIO REALIZADO POR RODRIGO RAMIREZ, DEBIDO A QUE EL STYLE DE LA TABLA NO ES EL BLANK STYLE, CUANDO SE ARREGLE
		EL SOURCE STYLE ID DE LA TABLA Appslca.dbo.[ImportExport_AnexoFacturacion_CheckPrices] SE CAMBIARÁ EL JOIN DE ABAJO
		2025-11-17*/

	left join (
			SELECT 
				VerProc.*
				,ISNULL(BST.StyleNumber,VerProc.stylenumber) AS BlankStyle
			FROM Appslca.dbo.[ImportExport_AnexoFacturacion_CheckPrices] VerProc with (nolock)
			LEFT JOIN LCA.dbo.Styles AS ST WITH(NOLOCK) ON VerProc.StyleID = ST.StyleID
			LEFT JOIN LCA.dbo.Styles AS BST WITH(NOLOCK) ON ST.BlankStyleID = BST.StyleID
		) AS VerProc
		on ABC2.OrderID = VerProc.OrderId and  abc4.StyleNumber = VerProc.BlankStyle and abc4.StyleColor = VerProc.StyleColor
		and ABC4.WayBill = VerProc.waybill And ABC4.SeasonName = VerProc.SeasonName --- Se agrega relación por waybill debido a que hay órdenes que no se van en una exportación completa
											--- AGREGADO POR Rodrigo Ramírez 20251031

	left join #abc4_1 abc4_1
        ON ABC2.BoxNumber = ABC4_1.BoxNumber
        and ABC2.StyleNumber = ABC4_1.StyleNumber
		and abc2.Stylecolor  = ABC4_1.StyleColor
		and abc2.GarmentSize = ABC4_1.GarmentSize
		and abc2.SeasonName = ABC4_1.SeasonName
	left join #abc4_2 abc4_2
        ON ABC2.BoxNumber = ABC4_2.BoxNumber and ABC2.cuenta=1
	left join #abc4_3 abc4_3
		on ABC2.Batch = abc4_3.batch
	left join #TBoxes5 ABC5_1
		on ABC2.InvoiceBatch = ABC5_1.InvoiceBatch

	left join  [AppsLCA].[dbo].[ImportExport_ApproveInvoice_Generated]  ABC3  with (nolock)
		on  ABC4.Batch = ABC3.ShipNotes
			and ABC4.PONumber = ABc3.PONumber and ABC4.StyleNumber=ABC3.Style
			and ABC4.ShipmentID = ABC3.ShipmentID									--- Relacion agregada para que los Bundles aparezcan con el precio de SP correcto --- Rodrigo Ramirez 20250530
		--	and ABC4.InvoiceBatch = ABC3.InvoiceBatch 				--- Esta relacion no funciona para los waybills Bundles
			--AND ABC4.UnitPrice=ABC3.Price
	left join #TBaseCost TBCost
		on ABC2.BoxNumber = TBCost.BoxNumber and ABC2.RO_ID = TBCost.RO_ID and  ABC2.GarmentSize = TBCost.Size
		AND ABC2.ManufactureID = TBCost.EO_ID --- SE AÑADE CONDICION DE EO_ID DEBIDO A QUE LAS RO PUEDEN SUPLIR A MOS CON LA MISMA TALLA 2025-07-21 DP Y RR
	left join (
				select distinct BoxNumber, CostoPonderado, RO
					from #TBaseCost
				) TBCost_2
		on ABC2.BoxNumber = TBCost_2.BoxNumber 
	left join [AppsLCA].[dbo].[TB_MO_PartNumber_IM_Materials] TBMAT with (nolock)
		on ABC2.Manufactureid = TBMAT.ManufactureID
	left join appslca.dbo.TB_MO_PartNumber_IM_Materials TB_sum with (nolock)
		on ABC2.ManufactureId = TB_sum.ManufactureID 
		--select * from appslca.dbo.TB_MO_PartNumber_IM_Materials where ManufactureID='504398'
	left join #TBaseCost_Fabric TBCost_Fabric
		on ABC2.ManufactureID = TBCost_Fabric.ManufactureID
	left outer join #TPartNumber TPart 
		on ABC2.ManufactureID = TPart.ManufactureId and
		   ABC2.StyleNumber   = TPart.NewStyle  and
		   ABC2.Stylecolor	  = TPart.NewColor  and
		   ABC2.GarmentSize   = TPart.NewSize
	left outer join (
						Select distinct ManufactureID, Partnumber, NewStyle, Newcolor 
								from #TPartNumber
								where NewSize is null or NewSize =''
								 --and ManufactureId= 453184
								group by ManufactureID, Partnumber, NewStyle, Newcolor 
					)  TPart_2
		on ABC2.ManufactureID = TPart_2.ManufactureId and
		   ABC2.StyleNumber   = TPart_2.NewStyle  and
		   ABC2.Stylecolor	  = TPart_2.NewColor  
	left outer join #TStdCost_Full TStd_Full with (nolock)
		on ABC2.StyleNumber = TStd_Full.Style and
		   ABC2.Stylecolor  = TStd_Full.Color and
		   isnull(ABC2.StyleOptionID,0) = isnull(TStd_Full.StyleOptionID1,0)

	left outer join #TStdCost_FG TStd_FG with (nolock)
		on ABC2.StyleNumber = TStd_FG.Style and
		   ABC2.Stylecolor  = TStd_FG.Color and
		   isnull(ABC2.StyleOptionID,0) = isnull(TStd_FG.StyleOptionID1,0)
	left outer join lca.dbo.StyleOptions StyOpt with (nolock)
		on ABC2.StyleOptionId = StyOpt.StyleOptionID
	left join [LCA].[dboReaders].[VW_Planning_OrderItemsPriceRev_2] OrdPR with (nolock) 
				on ABC2.ManufactureID = OrdPr.ManufactureID
				and ABC2.PoNumber = OrdPR.Ponumber
				and ABC2.StyleColor = OrdPr.Color
	left join [LCA].[dboReaders].[VW_Planning_OrderItemsPriceRev_3] ORDPR_2 with (nolock)
				on	abc2.BoxNumber = OrdPR_2.boxnumber and
					abc2.StyleNumber = COALESCE(ORDPR_2.BlankStyle,ORDPR_2.StyleNumber) and					--- COALESCE agregado a la relacion para que tome el estilo de inventario --- Rodrigo Ramirez 20250530
					abc2.GarmentSize = ORDPR_2.GarmentSize and
					abc2.Stylecolor	 = ORDPR_2.StyleColorName

--select * from #TBoxes2
update #Report set Qty =0  where BasePrice=0 and substring(waybill,1,2)='SM'

update Rep123  set TempGrossWg = Rep456.GRTotal, TempoNetWeight= Rep789.GRTotal, TempQty= Rep1011.GRTotal
	from #Report Rep123
	left outer join  (select Boxnumber, sum(GrossWeightKGSAll)  over(partition by Boxnumber) as GRTotal from #Report ) Rep456
			on Rep123.BoxNumber = Rep456.BoxNumber
	left outer join  (select Boxnumber, sum(NetWeightKGSAll)	over(partition by Boxnumber) as GRTotal from #Report ) Rep789
			on Rep123.BoxNumber = Rep789.BoxNumber
	left outer join (select Boxnumber, sum(qty)	over(partition by Boxnumber) as GRTotal from #Report ) Rep1011
			on Rep123.BoxNumber = Rep1011.BoxNumber

update #Report set GrossWeightKGSAll =( Qty*TempGrossWg/TempQty) ,  NetWeightKGSAll = (Qty*TempoNetWeight/TempQty)

---2025 02 14 Correguimos el supplier con el valor de Bill to Name que trae la Purchase Order
update BDS set BDS.Supplier = ADR.CompanyName
	FROM #Report  BDs 
	inner join (select distinct ManufactureID, PONumber, PurchaseID 
						from AppsLCA.dbo.TB_MO_PartNumber_IM_Freight  with (nolock)
						where ManufactureID in (select distinct ManufactureID from #Report)
				) abc678
		on BDS.ManufactureID = abc678.ManufactureID and BDs.Purchase_order = abc678.Ponumber
	inner join (select isnull(BilltoID, VendorID) as VendorID, PurchaseID from lca.dbo.purchaseOrders with (nolock)) POs
		on abc678.PurchaseID = POs.PurchaseID
	inner join lca.dbo.Addresses ADR with (nolock)
		on POs.VendorID = ADR.AddressID

--2025 03 14Actualizacion el CostoPonderado en base a la base AppsLCA.dbo.TB_MO_PartNumber_IM_Materials 
--Para que tome el costo ponderado y no el valor maximo por cada Receive slip
update BD set BD.Receiving_Cost_Ponderado = TB1.Contracts_PurchasePrice / tb1.Make,
			  BD.Total_Receiving_Cost_Ponderado = (TB1.Contracts_PurchasePrice / tb1.Make) * BD.Qty
from #Report BD
	inner join AppsLCA.dbo.TB_MO_PartNumber_IM_Materials TB1
		on BD.RO_ID= TB1.ManufactureID
	where TB1.Contracts_PurchasePrice>0

	--SELECT * FROM #Report
	--WHERE BasePrice + Screen_Print + Embroidery + Sublimation <> Price

	--SELECT SUM(Qty), SUM(Total$) FROM #Report

	--select * from #Report where BoxNumber = '01025177'
	--return
	

--Actualizando tabla FROM [AppsLCA].[dbo].[ImportExport_CommercialInvoice_Status] para generar via el job
-- La commercial Invoice
 --declare @waybill VARCHAR(100) ='APP-20240809'
declare @Find_WayBill int = 0
select @Find_WayBill = (Select count(*) from [AppsLCA].[dbo].[ImportExport_CommercialInvoice_Status] where wayBill=@VWayBill )
if @Find_WayBill >0
	begin
		update [AppsLCA].[dbo].[ImportExport_CommercialInvoice_Status] set [Status]='Pending', 
			Pending_date =  getdate(), Executing_Date=null, Finished_Date=null
			where  waybill =@VWayBill
	end
else
	begin
		insert into [AppsLCA].[dbo].[ImportExport_CommercialInvoice_Status] VALUES (@VWayBill,'Pending',getdate(),null,null)
	end

--aqui voy
--select * from #Report where BOXNUMBER ='01001359' --BoxNumber = '00879373'
insert into  appslca.dbo.ImportExport_AnexoFacturacion 
 (
    [ShipDate]
	 ,[Waybill]
	 ,[InvoiceBatch]
	 ,[Batch]
	 ,[PONumber]
	 ,[BoxNumber]
	 ,[StyleNumber]
	 ,[SeasonName]
	 ,[Qty]
	 ,[Size]
	 ,[Supplier]
	 ,[HTSDescription]
	 ,[BasePrice]
	 ,[Handling]
	 ,[Total_Handling]
	 ,[Freight]
	 ,[Total_Freight]
	 ,[BaseCost]
	 ,[Total_Base_Cost]
	 ,[Receiving_Cost]
	 ,[Total_Receiving_Cost]
	 ,RO
	 ,RO_ID
	 ,[Purchase_order]
	 ,[PrintCount]
	 ,[Screen_Print]
	 ,[Total_Screen_Print]
	 ,[Embroidery]
	 ,[Total_Embroidery]
	 ,[Sublimation]
	 ,[Total_Sublimation]
	 ,[Price]
	 ,[Total$]
	 ,OrderID
	 ,MO
	 ,Embr_Code1
	 ,Embr_Code2
	 ,Embr_Code3
	 ,Embr_Code4
	 ,PrintLocations
	 ,CountryOfOrigin
	 ,ProductDivision
	 ,Manufacturer
	 ,SemiFinishProductCost
	 ,SemiFinishProductCost_Fabric
	 ,SemiFinishProductCost_Thread
	 ,SemiFinishProductCost_Trim
	 ,SemiFinishProductCost_Supplies
	 ,SemiFinishProductCost_Contracts
	 ,SemiFinishProductCost_SubAssembly
	 ,FinishProductCost
	 ,FinishProductCost_Fabric
	 ,FinishProductCost_Thread
	 ,FinishProductCost_Trim
	 ,FinishProductCost_Supplies
	 ,FinishProductCost_Contracts
	 ,FinishProductCost_SubAssembly
	 ,Incoterm
	 ,Gross_Weight_kgs
	 ,Net_Weight_kgs
	 ,Container
    ,Consigned
	 ,StyleColor
	 ,PartNumber
	 ,ManufactureID
	 ,STdCost_Fabric   
	 ,STdCost_Thread   
	 ,STdCost_Trims    
	 ,STdCost_Handling 
	 ,STdCost_SewLabor 
	 ,STdCost_Supplies 
	 ,STdCost_CutLabor 
	 ,STdCost_Contracts 
	 ,STdCost_Subassembly 
	 ,StyleOptionID
	 ,StyleOptionName
	 ,UnitStdCost_Fabric
	 ,UnitStdCost_Thread
	 ,UnitStdCost_Trims
	 ,UnitStdCost_Handling
	 ,UnitStdCost_SewLabor
	 ,UnitStdCost_Supplies
	 ,UnitStdCost_CutLabor
	 ,UnitStdCost_Contracts
	 ,UnitStdCost_Subassembly
	 ,SAC
	 ,UDM
	 ,ComponentValue
	 ,AssemblyValue
	 ,Waybill_Freight
	 ,Receiving_Cost_Ponderado
	 ,Total_Receiving_Cost_Ponderado
	 
	)
select
  	   [ShipDate]
     ,[Waybill]
     ,[InvoiceBatch]
     ,[Batch]
     ,[PONumber]
     ,[BoxNumber]
     ,[StyleNumber]
     ,[SeasonName]
     ,IIF( substring(Container,1,4)<>'PPRC', round([Qty],0) , Qty) as Qty
	  ,Size
     ,[Supplier]
     ,[HTSDescription]
     ,[BasePrice]
     ,[Handling]
     ,IIF( substring(Container,1,4)<>'PPRC', round([Qty],0) * [Handling], [Total_Handling] ) as  [Total_Handling] 
     ,[Freight]
     ,IIF( substring(Container,1,4)<>'PPRC',  round(qty,0) * [Freight],  [Total_Freight]) as  [Total_Freight]
     ,[BaseCost]
     ,IIF( substring(Container,1,4)<>'PPRC', round(qty,0) * [BaseCost] ,[Total_Base_Cost]) as [Total_Base_Cost]
     ,[Receiving_Cost]
     ,IIF( substring(Container,1,4)<>'PPRC', round(qty,0) * [Receiving_Cost] ,[Total_Receiving_Cost]) as [Total_Receiving_Cost]
	  ,RO
	  ,RO_ID
     ,[Purchase_order]
     ,[PrintCount]
     ,[Screen_Print]
     ,IIF( substring(Container,1,4)<>'PPRC', round(qty,0) * [Screen_Print], [Total_Screen_Print]) as [Total_Screen_Print]
     ,[Embroidery]
     ,IIF( substring(Container,1,4)<>'PPRC', round(qty,0) * [Embroidery] ,[Total_Embroidery]) as [Total_Embroidery]
     ,[Sublimation]
     ,IIF( substring(Container,1,4)<>'PPRC', round(qty,0) * [Sublimation],[Total_Sublimation]) as [Total_Sublimation]
     ,[Price]
     ,IIF( substring(Container,1,4)<>'PPRC', round(qty,0) * [Price], [Total$]) as [Total$]
	  ,OrderID
	  ,MO
	  ,Embr_Code1
	  ,Embr_Code2
	  ,Embr_Code3
	  ,Embr_Code4
	  ,PrintLocations
	  ,CountryOfOrigin
	  ,ProductDivision
	  ,Manufacturer
	  ,SemiFinishProductCost
	  ,SemiFinishProductCost_Fabric
	  ,SemiFinishProductCost_Thread
	  ,SemiFinishProductCost_Trim
	  ,SemiFinishProductCost_Supplies
	  ,SemiFinishProductCost_Contracts
	  ,SemiFinishProductCost_SubAssembly
	  ,FinishProductCost
	  ,FinishProductCost_Fabric
	  ,FinishProductCost_Thread
	  ,FinishProductCost_Trim
	  ,FinishProductCost_Supplies
	  ,FinishProductCost_Contracts
	  ,FinishProductCost_SubAssembly
	  ,'CIF' as [Incoterm]
	  ,GrossWeightKGSAll
	  ,NetWeightKGSAll
	  ,Container
	  ,Consigned
	  ,StyleColor
	  ,PartNumber
	  ,ManufactureID
	  ,STdCost_Fabric   
	  ,STdCost_Thread   
	  ,STdCost_Trims    
	  ,STdCost_Handling 
	  ,STdCost_SewLabor 
	  ,STdCost_Supplies 
	  ,STdCost_CutLabor 
	  ,STdCost_Contracts 
	  ,STdCost_Subassembly 
	  ,StyleOptionID
	 ,StyleOptionName
	 ,UnitStdCost_Fabric
	 ,UnitStdCost_Thread
	 ,UnitStdCost_Trims
	 ,UnitStdCost_Handling
	 ,UnitStdCost_SewLabor
	 ,UnitStdCost_Supplies
	 ,UnitStdCost_CutLabor
	 ,UnitStdCost_Contracts
	 ,UnitStdCost_Subassembly
    ,SAC
	 ,UDM
	 ,IIF(ComponentValue<0 , 0, ComponentValue) AS ComponentValue
	 ,IIF(AssemblyValue<0, 0, AssemblyValue) AS AssemblyValue
	 ,'0' as Waybill_Freight
	 ,Receiving_Cost_Ponderado
	 ,Total_Receiving_Cost_Ponderado
from #Report

EXEC [AppsLCA].[dbo].[SP_tranfer_register_export] @VWaybill = @VWaybill

END
