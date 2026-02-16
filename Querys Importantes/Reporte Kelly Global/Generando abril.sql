USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[sp_Update_Import_Export_Commercial_Invoice_BK20250521]    Script Date: 09/12/2025 09:58:10 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--ALTER PROCEDURE [dbo].[sp_Update_Import_Export_Commercial_Invoice_BK20250521]
--AS
BEGIN

Declare @WayBill varchar(100) = null
Declare @Status varchar(100) = null
Declare @Pending_Date datetime = null
Declare @Executing_Date datetime = null
Declare @Finished_Date datetime=null

-- set @WayBill = 'APP-20240730'
declare WayBill_status cursor for select distinct  Waybill from [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] WHERE ShipDate >= '2024-05-01' AND ShipDate <= '2024-05-31'
		

open WayBill_status
Fetch next from WayBill_status into  @Waybill

while @@Fetch_status=0
	begin

delete from [192.168.1.93].[AppsLCA].[dbo].[Import_Export_CommercialInvoice_Before20240801] where WayBill =@WayBill
--update [AppsLCA].[dbo].[ImportExport_CommercialInvoice_Status] set [Status] = 'Executing', Executing_Date=getdate() 
--	where waybill =@WayBill

-----COMMERCIAL INVOICE

insert into [192.168.1.93].[AppsLCA].[dbo].[Import_Export_CommercialInvoice_Before20240801]
select  top 100 percent @WayBill, CI_Ver2.* , 
		0.25,
		case when Cafta='Y' and Manufactured like '%NG TEXTILES%' then 1
			when Cafta='Y' and Manufactured like '%Leagu%' then 2 
			when Cafta='Y' and Manufactured not like '%NG TEXTILES%' and Manufactured not like '%Leagu%' then 3
			else 4
		end as Orden
		from 

		(SELECT
							TB.ContainerNumber
							,TB.StyleNumber
							,TB.InvoicingDescription
							,TB.US_HTSDescription
							,TB.CA_HTSCode
							,TB.UnitPrice
							,MAX(TB.ShipDate)               AS [ShipDate]
							,ROUND(SUM(TB.Quantity),2)      AS [Quantity]
							,SUM(TB.TotalPrice)             AS [TotalPrice]
							,MIN(TB.Batch)                  AS [MinBatch]
							,SUM(TB.WeightKg)               AS [WeightKg]
							,MAX(TB.Batch)                  AS [MaxBatch]
							,TB.Cafta                       AS [Cafta]
							,SUM(CASE WHEN GroupPallet  = 1 THEN 1 ELSE 0 END)   AS [Pallets]
							,SUM(CASE WHEN GroupBox     = 1 THEN 1 ELSE 0 END)   AS [Boxes]
							,TB.Manufactured
							,TB.CountryOfOrigin
        
						FROM (
							SELECT
								WB.WayBill
								,WB.ContainerNumber
								,CAST(WB.ShipDate AS DATE)      AS [ShipDate]
								,wb.Batch
								,WB.PONumber
								,WB.BoxNumber
								,WB.StyleNumber
								,WB.GarmentSize
								,WB.NewQuantity_2 as Quantity
								,isnull( WB.US_HTSCode_2, WB.CA_HTSCode) as CA_HTSCode
								,WB.US_HTSDescription
								,WB.InvoicingDescription
								,case when WB.TariffCategory ='CAFTA' THEN 'Y' 	ELSE 'N' END AS Cafta
								,WB.PalletNumber
								,WB.UnitPrice
								,(WB.GrossWeightKGSXUnits * WB.NewQuantity_2)        AS [WeightKg]
								,(WB.UnitPrice * WB.NewQuantity_2)                   AS [TotalPrice]
								,ROW_NUMBER() OVER (PARTITION BY WB.PalletNumber
													ORDER BY WB.PalletNumber)   AS [GroupPallet]
								,ROW_NUMBER() OVER (PARTITION BY WB.BoxNumber
													ORDER BY WB.BoxNumber)      AS [GroupBox]
								,WB.Manufactured
								,WB.CountryOfOrigin
							FROM  ( 
									select WB99B.*,	case 
														 when Dif <0 and NewQtyMax=1 then NewQuantity-abs(Dif)
														 when Dif >0 and NewQtyMin=1 then NewQuantity+abs(Dif)
													else NewQuantity
													end as NewQuantity_2
											from (
													select WB99A.*, Quantity- sum(NewQuantity) over(partition by boxnumber, StyleNumber, GarmentSize ) as Dif,
																	row_number() over(partition by BoxNumber, StyleNumber, Garmentsize order by BoxNumber, StyleNumber, GarmentSize, NewQuantity desc) as NewQtyMax,
																	row_number() over(partition by BoxNumber, StyleNumber, Garmentsize order by BoxNumber, StyleNumber, GarmentSize, NewQuantity asc) as NewQtyMin
														from (
																SELECT distinct WB99.*,
																case
																	when isnull(TB_MO_02.CountryOfOrigin, TB_MO_2.CountryOfOrigin)='El Salvador' 
																			and (TB_MO_02.Category= 'Contracts' or TB_MO_2.Category='Contracts' ) 
																			and (isnull(TB_MO_02.Manufacturer,TB_MO_2.Manufacturer)) like '%Brand%'
																		then 'League LTDA'
																	when isnull(TB_MO_02.CountryOfOrigin, TB_MO_2.CountryOfOrigin)='El Salvador' 
																			and (TB_MO_02.Category<> 'Contracts' or TB_MO_2.Category<>'Contracts' )
																		then 'League LTDA'
																	when isnull(TB_MO_02.CountryOfOrigin, TB_MO_2.CountryOfOrigin)='El Salvador' 
																			and (TB_MO_02.Category= 'Contracts' or TB_MO_2.Category='Contracts' )
																		then isnull(TB_MO_02.Manufacturer,TB_MO_2.Manufacturer)
																	 when TB_MO_02.Manufacturer is null and TB_MO_2.Manufacturer is null	
																		then 'League LTDA'
																	else
																		isnull(TB_MO_02.Manufacturer,TB_MO_2.Manufacturer)
																	end as Manufactured,

																case when TB_MO_02.CountryOfOrigin is not null or  TB_MO_2.CountryOfOrigin is not null	
																		then isnull(TB_MO_02.CountryOfOrigin, TB_MO_2.CountryOfOrigin) 
																		else 'El Salvador'
																		end as CountryOfOrigin
																,case when Styles.Comments9 not like '%Head%' then HTS.US_HTSCode
																	else null end as US_HTSCode_2
																, case when TB_MO_02.TariffCategory is not null or TB_MO_2.TariffCategory is not null
																			then isnull(TB_MO_02.TariffCategory,TB_MO_2.TariffCategory)
																			else TMO_A.comments16
																			end as TariffCategory
																,VEOPZ.RO
																,VEOPZ.UnitsEORO
																,VEOPZ.RO_ID
																,VEOPZ.EO_Make
																,TTotQty.MOTotalQty
																,case when TTotQty.MOTotalQty <>0  and VEOPZ.RO is not null 
																		then  round( round(VEOPZ.UnitsEORO/TTotQty.MOTotalQty,6) * WB99.Quantity,0)
																		else WB99.Quantity
																		end as NewQuantity
																	FROM
																			(
																				select distinct
																				   SB.[id], SB.[WayBill], SB.[ContainerNumber], SB.[InvoiceBatch], SB.[Batch], SB.[PONumber], SB.[BoxNumber]
																				  ,SB.[PalletNumber]
																				  ,CASE WHEN  VSeekMO.ManufactureID is not null 
																								and VW_Struc.StyleID_Emb is not null and VW_Struc.Style_Emb <> VW_Struc.Style_Blank
																							then VW_Struc.Style_Blank
																						WHEN  VSeekMO.ManufactureID is not null 
																								and VW_Struc_3.StyleID_Blank is not null and VW_Struc.Style_Emb <> VW_Struc.Style_Blank
																							then VW_Struc.Style_Blank
																						WHEN  VSeekMO.ManufactureID is null 
																							and VW_Struc_2.StyleID_Emb is not null and VW_Struc_2.Style_Emb <> VW_Struc_2.Style_Blank
																							then VW_Struc_2.Style_Blank
																						else SB.[StyleNumber]
																					end as StyleNumber
																				  ,SB.[StyleCostMaterials], SB.[StyleColor], SB.[GarmentSize], SB.[Quantity] ,
																				   case when lmn.US_HTSCode is not null then lmn.US_HTSCode
																						when lmn.US_HTSCode is null and lmn.CA_HTSCode is not null then lmn.CA_HTSCode
																						else   SB.[CA_HTSCode] end as CA_HTSCode,
																				   SB.[CA_HTSDescription],
																				   case when lmn.US_HTSCode is not null then lmn.US_HTSCode
																						when lmn.US_HTSCode is null and lmn.CA_HTSCode is not null then lmn.CA_HTSCode
																						else   SB.[US_HTSCode] end [US_HTSCode],
																				   SB.[US_HTSDescription], SB.[UnitPrice], SB.[ShipDate]
																				  ,SB.[BoxStatusName], SB.[BoxWarehouseName], SB.[ShipmentID], SB.[BlankStyleCostMaterials1]
																				  ,SB.[StyleCostMaterials1], SB.[SalePrice], SB.[MatPrimaCost], SB.[MatPrimaCostBlank]
																				  ,SB.[GrossWeightKGS], SB.[GrossWeightKGSXUnits], SB.[GrossWeightKGSAll], SB.[NetWeightKGS]
																				  ,SB.[NetWeightKGSXUnits], SB.[NetWeightKGSAll], SB.[BoxesXQty], SB.[BoxesXQTYTotal]
																				  ,SB.[HTSStyleCodeID]
																				  ,case when VSeekMO.ManufactureID is not null 
																							and (FabCont.DescribeText is not null or FabCont.InvoicingDescription is not null)
																							and (FabCont_3.DescribeText is null and FabCont_3.InvoicingDescription is  null)
																							then  concat(FabCont.DescribeText, ' ',FabCont.InvoicingDescription)
																						when VSeekMO.ManufactureID is not null 
																							and (FabCont_3.DescribeText is not null or FabCont_3.InvoicingDescription is not null)
																							and (FabCont.DescribeText is null and FabCont.InvoicingDescription is null)
																							then concat(FabCont_3.DescribeText, ' ',FabCont_3.InvoicingDescription)
																						when VSeekMO.ManufactureID is null
																								and (FabCont_2.DescribeText is not null or FabCont_2.InvoicingDescription is not null)
																							then concat(FabCont_2.DescribeText, ' ',FabCont_2.InvoicingDescription)
																						when FabCont_4.Style is not null
																							then concat(FabCont_4.DescribeText, ' ',FabCont_4.InvoicingDescription)
																						else SB.[InvoicingDescription]
																					end  as InvoicingDescription
																				  ,SB.[Cafta], SB.[created_at]
																				  ,SB.[updated_at], SB.[deleted_at]
																				  ,sum(SB.Quantity) over (partition by VSeekMO.MO, SB.GarmentSize 
																									order by VSeekMO.MO, SB.GarmentSize) as TotalQTY
																					,VseekMO.MO, VseekMO.ManufactureID
																					 from
																						(
																							SELECT  
																								WayBill ,created_at
																								,ROW_NUMBER() OVER (PARTITION BY WayBill
																													ORDER BY WayBill,created_at DESC
																													)  AS R
																								FROM [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] with (nolock)
																									WHERE WayBill IN (@WayBill) --'AIR20240409'
																									GROUP BY WayBill ,created_at
																						) AS TB_GROUP
																					right outer JOIN [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll]  AS SB with (nolock)
																							ON SB.WayBill = TB_GROUP.WayBill --and sb.PONumber='PO1018-STOCK-LCA'																							AND SB.created_at = TB_GROUP.created_at
																					left outer join (
																										Select * from 
																													(select Color, Style, CA_HTSCode, US_HTSCode from 
																																  (select RW.PartNumber, RW.HTSCodeID, Col.ColorName as Color, CL.ComponentName as Style,
																																	DRD.DropDownValue as CA_HTSCode, DRD.Description3 as US_HTSCode	,
																																	row_number() over(partition by Col.ColorName, CL.ComponentName order by Col.ColorName, CL.ComponentName) as Cuenta
																																	   FROM [LCA].[dbo].[RawMaterials]  RW with (nolock)
																																		left outer join lca.dbo.Colors COL with (nolock)
																																		   on RW.ColorID = Col.ColorID
																																		left outer join lca.dbo.ComponentLibrary CL with (nolock)
																																			on RW.ComponentID = CL.ComponentID and CL.ComponentCategoryID=11
																																		left outer join lca.dbo.DropDownValues DRD with (nolock)
																																			on RW.HTSCodeID = DRD.DropDownValueID
																																		where Cl.ComponentName is not null and Col.ColorName is not null
																																	) abc123 where Cuenta=1
																													) fgh
																									) lmn 
																							on SB.StyleNumber = lmn.Style and SB.StyleColor=lmn.Color
																					left outer join 
																									(select BoxNumber, ManufactureID, MO, QuantityOrdered 
																										   from (
																												SELECT VSeek2MO.BoxNumber, VSeek2MO.ManufactureID, VSeek2MO.MO,
																													   TMO.QuantityOrdered,
																													   row_number () over(partition by VSeek2MO.BoxNumber 
																																	order by VSeek2MO.BoxNumber, TMO.QuantityOrdered desc)
																														as ncuenta
																													from [LCA].[dbo].[VW_Check_Sales_Prices_in_Invoices_SeekMO] VSeek2MO with (nolock)
																														left outer join lca.dbo.manufactureOrders TMO with (nolock)
																															on VSeek2MO.ManufactureID = TMO.ManufactureID
																												) VSeek3MO
																											where ncuenta=1 --and boxnumber = '00681569'
																									) VSeekMO  
																						ON SB.BoxNumber = VSeekMO.BoxNumber 
																				left outer join lca.dbo.ManufactureOrders TMO_APri with (nolock) 
																						ON VSeekMO.ManufactureID = TMO_APri.manufactureid 
																				left outer join lca.dbo.OrderDetails ODT_PRI with (nolock)
																						on TMO_APri.FirstOrderItemID = ODT_PRI.OrderItemID   and
																						   TMO_APri.OrderID = ODT_PRI.OrderID 
																				left outer join [LCA].[dboReaders].[VW_ESC_StyleStructure] VW_Struc with (nolock) 
																						on ODT_PRI.StyleID = VW_Struc.StyleID_EMB
																				left outer join (
																								select distinct Style, StyleColorName, DescribeText, InvoicingDescription	
																									from [LCA].[dboReaders].[VW_CommercialInvoice_FabricContent_Ver2]  with (nolock)
																									--where Style ='proto1388' --and StyleColorName ='GRH'
																								) FabCont
																						on VW_Struc.Style_Blank = FabCont.Style and SB.StyleColor = FabCont.StyleColorName
																				left outer join  [LCA].[dboReaders].[VW_ESC_StyleStructure] VW_Struc_3 with (nolock)
																						on ODT_PRI.StyleID = VW_Struc_3.StyleID_BLANK and VW_Struc_3.EngineSeason='Full'
																				left outer join (select distinct Style, StyleColorName, DescribeText, InvoicingDescription	
																									 from [LCA].[dboReaders].[VW_CommercialInvoice_FabricContent_Ver2]  with (nolock)
																								) FabCont_3
																						on VW_Struc_3.Style_Blank = FabCont_3.Style and SB.StyleColor = FabCont_3.StyleColorName
																				-----Joins agregados para cuando se factura Bundles 2024 04 29
																				left outer join [LCA].[dboReaders].[VW_ESC_StyleStructure] VW_Struc_2 with (nolock)
																					 on sb.StyleNumber = VW_Struc_2.Style_EMB
																				left outer join (select distinct Style, StyleColorName, DescribeText, InvoicingDescription	
																									from [LCA].[dboReaders].[VW_CommercialInvoice_FabricContent_Ver2]  with (nolock)
																									--where style ='ez100'  and StyleColorName = 'DEN'
																								) FabCont_2
																					 on VW_Struc_2.Style_Blank = FabCont_2.Style and SB.StyleColor = FabCont_2.StyleColorName
																				---Join agregado para los styles Proto... de Desarollo
																				left outer join (select distinct Style, StyleColorName, DescribeText, InvoicingDescription	
																									from [LCA].[dboReaders].[VW_CommercialInvoice_FabricContent_Ver2]  with (nolock)
																								) FabCont_4
																					 on sb.StyleNumber = FabCont_4.Style and SB.StyleColor = FabCont_4.StyleColorName
																				WHERE TB_GROUP.R = 1  --and sb.StyleNumber='SUB100' --and sb.boxnumber ='00681569'
																			)  WB99
																	left outer join appslca.dbo.TB_MO_PartNumber_IM_EORO VEOPZ with (nolock)
																			on   WB99.ManufactureID = VEOPZ.EO_ID  and  WB99.GarmentSize = VEOPZ.Size and
																				 WB99.StyleNumber = isnull(VEOPZ.RO_Style,VEOPZ.EO_Style)
																	left outer join 
																			(
																			select ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category,Style,Size
																				from 
																					(
																						select ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category,Style,Size,
																							row_number() over(Partition by Manufactureid, Size 
																							order by  Manufactureid, Size, Consumption desc )
																							as Ncuenta
																						from appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
																						where (Size is not null and rtrim(Size)<>'')
																						--and mo in('RO123021CCW115-837-5','TO1018CCW115-837-1')  --='EO3902696-BKH' mo='EO3774316-LBL'
																							group by ManufactureId, 
																								CountryOfOrigin , 
																								Manufacturer,
																								TariffCategory,
																								Category,
																								Style, Size, Consumption
																					) TB_MO_01
																				where Ncuenta=1
																			) TB_MO_02
																			ON VEOPZ.RO_ID = TB_MO_02.ManufactureID and
																			   VEOPZ.RO_STyle = TB_MO_02.Style and
																			   VEOPZ.Size = TB_MO_02.Size

																	left outer join 
																			(select distinct ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category
																				from 
																					(	Select * from (
											  															select *,row_number() over (partition by Manufactureid order by Manufactureid, consumption desc ) as Cuenta
																											 from appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
																										where (Size is null or rtrim(Size)='') and category='Fabric'
																										--and mo in ('RO123021CCW115-837-5','TO1018CCW115-837-1')
																									) SubFabric01 where Cuenta =1
																						union all
											  															select *, 1 as Cuenta from appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
																										where (Size is null or rtrim(Size)='') and category='Contracts'
																										--and mo in ('RO123021CCW115-837-5','TO1018CCW115-837-1')
																					) TB_MO_1
																				--where TB_MO_1.ncuenta=1
																			) TB_MO_2
																			ON WB99.ManufactureID = TB_MO_2.ManufactureID 

																	left outer join lca.dbo.ManufactureOrders TMO_A with (nolock) 
																			ON WB99.ManufactureID = TMO_A.manufactureid 
																	left outer join lca.dbo.OrderDetails ODT with (nolock)
																			on TMO_A.FirstOrderItemID = ODT.OrderItemID   and
																			   TMO_A.OrderID = ODT.OrderID 
																	left outer join lca.dbo.styles with (nolock)
																			on ODT.StyleID = styles.styleid 
																	left outer join lca.dbo.HTSStyleCodes HTS with (nolock)
																			on styles.HTSStyleCodeID = HTS.HTSStyleCodeID 
																	left outer join (
																					 select MDET1.manufactureid, MDET1.QuantityOrdered as MOTotalQty, FGD1.GarmentSize
																						from lca.dbo.ManufactureDetails MDET1 with (nolock)
																						left outer join lca.dbo.FinishedGoods FGD1 with (nolock)
																						on MDET1.FinishedGoodsID = FGD1.FinishedGoodsID
																						where MDET1.QuantityOrdered>0
																					) TTotQty
																			on WB99.ManufactureID = TTotQty.ManufactureID and WB99.GarmentSize=TTotQty.GarmentSize
																	WHERE WB99.id is not null --and WB99.BoxNumber='00667351'

														)  WB99A
												) WB99B

								 ) WB
									--where Ncuenta503=1
						) AS TB
						GROUP BY
							Cafta
							,CountryOfOrigin
							,StyleNumber
							,ContainerNumber
							,US_HTSDescription
							,CA_HTSCode
							,UnitPrice
							,InvoicingDescription
							,Manufactured
			 ) CI_Ver2
		Order by 
			 Orden
			,Cafta desc
			,CountryOfOrigin
			,StyleNumber
			,ContainerNumber
			,US_HTSDescription
			,CA_HTSCode
			,UnitPrice
			,InvoicingDescription
			,Manufactured
	
-- update [AppsLCA].[dbo].[ImportExport_CommercialInvoice_Status] set [Status] = 'Finished', Finished_Date=getdate() 
-- 	where waybill =@WayBill
	

	Fetch next from WayBill_status into  @Waybill


	end
close WayBill_status
deallocate WayBill_status

END
