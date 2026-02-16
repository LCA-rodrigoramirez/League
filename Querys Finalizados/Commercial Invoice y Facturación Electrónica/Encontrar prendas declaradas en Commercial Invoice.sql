USE [AppsLCA]
GO
/****** Object:  StoredProcedure [dbo].[sp_Update_Import_Export_Commercial_Invoice]    Script Date: 13/06/2025 09:16:30 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ALTER PROCEDURE [dbo].[sp_Update_Import_Export_Commercial_Invoice]
-- AS
-- BEGIN

Declare @WayBill varchar(100) = null
Declare @ShipDate DATE = null
Declare @ShipDateEnd DATE = null
Declare @Status varchar(100) = null
Declare @Pending_Date datetime = null
Declare @Executing_Date datetime = null
Declare @Finished_Date datetime=null
Declare @TransferVal INT = 0

SET @ShipDate = '2025-05-27'
SET @ShipDateEnd = '2025-10-10'
-- declare WayBill_status cursor for select  * from [192.168.1.53].[AppsLCA].[dbo].[ImportExport_CommercialInvoice_Status]
-- 		where status='Pending'

-- open WayBill_status
-- Fetch next from WayBill_status into  @Waybill, @Status, @Pending_Date, @Executing_date, @Finished_Date

-- while @@Fetch_status=0
-- 	begin

-- --  delete from appslca.dbo.Import_Export_CommercialInvoice_TEST where WayBill =@WayBill
-- delete from appslca.dbo.Import_Export_CommercialInvoice where WayBill =@WayBill
-- delete from AppsLCA.dbo.Import_Export_DeclarationExport where WayBill =@WayBill
--  update [192.168.1.53].[AppsLCA].[dbo].[ImportExport_CommercialInvoice_Status] set [Status] = 'Executing', Executing_Date=getdate() 
--  	where waybill =@WayBill

-----COMMERCIAL INVOICE


DROP TABLE IF EXISTS #TB_Transfer_Kardex
DROP TABLE IF EXISTS #TB_DataCI
DROP TABLE IF EXISTS #TB_Transfer
DROP TABLE IF EXISTS #TB_ContentFabric

SELECT *
INTO #TB_Transfer_Kardex
FROM [192.168.1.53].[AppsLCA].[dbo].[TB_Transfer_Kardex_Duty] WITH(NOLOCK)
WHERE Waybill = @WayBill
AND QtyTransfer > 0

SELECT *
INTO #TB_ContentFabric
FROM 
(
	select distinct Style, StyleColorName, DescribeText, InvoicingDescription	
	from [192.168.1.53].[LCA].[dboReaders].[VW_CommercialInvoice_FabricContent_Ver2]  with (nolock)
	where RowN = 1
) AS FabCont

CREATE INDEX Style_TB_ContentFabric ON #TB_ContentFabric (Style)

SET @TransferVal = (SELECT COUNT(*) FROM #TB_Transfer_Kardex WHERE QtyTransfer > 0)

--- Pre ingreso de datos en #TB_DataCI para evitar contar cajas 2 veces


SELECT 
        [ShipDate]					=	SB.[ShipDate]
    ,[Waybill]					=	SB.[Waybill]
    ,[Container]				=	SB.[Container]
    ,[InvoiceBatch]				=	SB.[InvoiceBatch]
    ,[Batch]					=	SB.[Batch]
    ,[PONumber]					=	SB.[PONumber]
    ,[BoxNumber]				=	SB.[BoxNumber]
    ,[FormattedBoxNumber]		=	TB_GROUP.[FormattedBoxNumber]
    ,[StyleNumber]				=	SB.[StyleNumber]
    ,[StyleColor]				=	SB.[StyleColor]
    ,[Size]						=	SB.[Size]
    ,[PalletNumber]				=	TB_GROUP.[PalletNumber]
    ,[Price]					=	SB.[Price]
    ,[CA_HTSCode]				=	case 
                                        when lmn.US_HTSCode is not null then lmn.US_HTSCode
                                        when lmn.US_HTSCode is null and lmn.CA_HTSCode is not null then lmn.CA_HTSCode
                                        else   SB.[SAC] 
                                    end
    ,[CA_HTSDescription]		=	SB.[HTSDescription]
    ,[US_HTSCode]				=	case 
                                        when lmn.US_HTSCode is not null then lmn.US_HTSCode
                                        when lmn.US_HTSCode is null and lmn.CA_HTSCode is not null then lmn.CA_HTSCode
                                        else   TB_GROUP.[US_HTSCode] 
                                    end 
    ,[US_HTSDescription]		=	TB_GROUP.US_HTSDescription
    ,[InvoicingDescription]		=	case 
                                        when SB.ManufactureID is not null 
                                                and (FabCont.DescribeText is not null or FabCont.InvoicingDescription is not null)
                                                then  concat(FabCont.DescribeText, ' ',FabCont.InvoicingDescription)
                                        when FabCont2.DescribeText is not null or FabCont2.InvoicingDescription is not null
                                                then  concat(FabCont2.DescribeText, ' ',FabCont2.InvoicingDescription)
                                        else TB_GROUP.[InvoicingDescription]
                                    end
    -- ,[GrossWeightKGSXUnits]		=	TB_GROUP.[GrossWeightKGSXUnits]
    ,[GrossWeightKGSXUnits]		=	SB.[Gross_Weight_kgs]
    --,[Qty]						=	SB.Qty
    ,[Qty]						=	CASE 
                                        WHEN TK.IDExport IS NOT NULL THEN TK.QtyNoTransfer
                                        ELSE SB.Qty
                                    END
    ,[Manufactured]				=	COALESCE(SB.Manufacturer, TB_MO_02.Manufacturer,TB_MO_2.Manufacturer)
    ,[CountryOfOrigin]			=	COALESCE(SB.CountryOfOrigin, TB_MO_02.CountryOfOrigin,TB_MO_2.CountryOfOrigin)
    ,[ProductDivision]			=	ST.Comments9 
    ,[US_HTSCode2]				=	HTS.US_HTSCode  
    ,[TariffCategory]			=	case 
                                        when TB_MO_02.TariffCategory is not null or TB_MO_2.TariffCategory is not null
                                            then COALESCE(TB_MO_02.TariffCategory,TB_MO_2.TariffCategory)
                                        else TMO_APri.comments16
                                        end 
    ,SB.ID
INTO #TB_DataCI	
FROM 
(
    SELECT  
            WayBill
        ,BoxNumber
        ,FormattedBoxNumber
        ,StyleNumber
        ,StyleColor
        ,GarmentSize
        ,PalletNumber 	=	CASE WHEN Bin IS NOT NULL THEN Bin ELSE PalletNumber END
        ,US_HTSCode
        ,US_HTSDescription
        ,InvoicingDescription
        ,GrossWeightKGSXUnits
    FROM [192.168.1.53].[AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] with (nolock)
    -- FROM [AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] with (nolock)
    -- WHERE WayBill IN (@waybill) --'AIR20240409'
    WHERE ShipDate >= @ShipDate AND ShipDate <= @ShipDateEnd
    GROUP BY WayBill 
            ,BoxNumber
            ,FormattedBoxNumber
            ,StyleNumber
            ,StyleColor
            ,GarmentSize
            ,PalletNumber
            ,Bin
            ,US_HTSCode
            ,US_HTSDescription
            ,InvoicingDescription
            ,GrossWeightKGSXUnits
) AS TB_GROUP
INNER JOIN	[192.168.1.53].[AppsLCA].[dbo].[ImportExport_AnexoFacturacion]		AS SB	WITH(NOLOCK)	ON SB.Waybill = TB_GROUP.WayBill AND SB.BoxNumber = TB_GROUP.BoxNumber 
-- INNER JOIN	[AppsLCA].[dbo].[ImportExport_AnexoFacturacion]		AS SB	WITH(NOLOCK)	ON SB.Waybill = TB_GROUP.WayBill AND SB.BoxNumber = TB_GROUP.BoxNumber 
                                                                                                                            AND SB.StyleNumber = TB_GROUP.StyleNumber 
                                                                                                                            AND SB.StyleColor = TB_GROUP.StyleColor
                                                                                                                            AND SB.Size = TB_GROUP.GarmentSize
left outer join (Select * from 
                        (select Color, Style, CA_HTSCode, US_HTSCode from 
                                        (select RW.PartNumber, RW.HTSCodeID, Col.ColorName as Color, CL.ComponentName as Style,
                                        DRD.DropDownValue as CA_HTSCode, DRD.Description3 as US_HTSCode	,
                                        row_number() over(partition by Col.ColorName, CL.ComponentName order by Col.ColorName, CL.ComponentName) as Cuenta
                                            FROM [192.168.1.53].[LCA].[dbo].[RawMaterials]  RW with (nolock)
                                            left outer join [192.168.1.53].lca.dbo.Colors COL with (nolock)
                                                on RW.ColorID = Col.ColorID
                                            left outer join [192.168.1.53].lca.dbo.ComponentLibrary CL with (nolock)
                                                on RW.ComponentID = CL.ComponentID and CL.ComponentCategoryID=11
                                            left outer join [192.168.1.53].lca.dbo.DropDownValues DRD with (nolock)
                                                on RW.HTSCodeID = DRD.DropDownValueID
                                            where Cl.ComponentName is not null and Col.ColorName is not null
                                        ) abc123 where Cuenta=1
                        ) fgh
                ) lmn	on SB.StyleNumber = lmn.Style and SB.StyleColor=lmn.Color
--left outer join (
--					SELECT
--							MOID		= BKD.ManufactureID
--						,BlankStyle = ST2.StyleNumber
--						,StyleColor = STC.StyleColorName
--						,Size 		= BK.GarmentSize
--						,PB.BoxNumber
--					FROM 	  [192.168.1.53].AppsLCA.dbo.TB_PackedItem_MO_BundlesKit_Details	AS BKD WITH(NOLOCK)
--					LEFT JOIN [192.168.1.53].AppsLCA.dbo.TB_PackedItem_MO_BundlesKit			AS BK  WITH(NOLOCK) ON BK.PackedItemID = BKD.PackedItemID
--					LEFT JOIN [192.168.1.53].LCA.dbo.Styles										AS ST  WITH(NOLOCK) ON ST.StyleID = BK.StyleID
--					LEFT JOIN [192.168.1.53].LCA.dbo.StyleColors								AS STC WITH(NOLOCK) ON STC.StyleColorID = BK.StyleColorID
--					LEFT JOIN [192.168.1.53].LCA.dbo.PackedItems								AS PKI WITH(NOLOCK) ON PKI.PackedItemID = BKD.PackedItemID
--					LEFT JOIN [192.168.1.53].LCA.dbo.PackedBoxes								AS PB  WITH(NOLOCK) ON PB.PackedBoxID = PKI.PackedBoxID
--					LEFT JOIN [192.168.1.53].LCA.dbo.Styles										AS ST2 WITH(NOLOCK) ON ST2.StyleID = ST.BlankStyleID

--				)AS SMO
left outer join [192.168.1.53].[LCA].[dbo].[VW_Check_Sales_Prices_in_Invoices_SeekMO_Bundle] AS SMO with (nolock)
        ON SB.BoxNumber = SMO.BoxNumber AND SB.StyleNumber = SMO.BlankStyleNumber AND SB.StyleColor = SMO.Stylecolor AND SB.Size = SMO.Size
left outer join [192.168.1.53].lca.dbo.ManufactureOrders TMO_APri with (nolock) 
        ON COALESCE(SB.ManufactureID,SMO.MOID) = TMO_APri.manufactureid
left outer join [192.168.1.53].lca.dbo.OrderItems ODT_PRI with (nolock)
        on TMO_APri.FirstOrderItemID = ODT_PRI.OrderItemID   and
            TMO_APri.OrderID = ODT_PRI.OrderID 
LEFT JOIN [192.168.1.53].LCA.dbo.Styles AS ST WITH(NOLOCK) ON ODT_PRI.StyleID = ST.StyleID

LEFT JOIN [192.168.1.53].LCA.dbo.Styles AS BST WITH(NOLOCK) ON BST.StyleID = ST.BlankStyleID

left outer join [192.168.1.53].lca.dbo.HTSStyleCodes HTS with (nolock) on st.HTSStyleCodeID = HTS.HTSStyleCodeID 

left outer join #TB_ContentFabric AS FabCont
        on BST.StyleNumber = FabCont.Style and SB.StyleColor = FabCont.StyleColorName

left outer join #TB_ContentFabric AS  FabCont2
        on SB.StyleNumber = FabCont2.Style and SB.StyleColor = FabCont2.StyleColorName

left outer join 
(
    select ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category,Style,Size
        from 
            (
                select ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category,Style,Size,
                    row_number() over(Partition by Manufactureid, Size 
                    order by  Manufactureid, Size, Consumption desc )
                    as Ncuenta
                from [192.168.1.53].appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
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
ON SB.RO_ID = TB_MO_02.ManufactureID and
    SB.StyleNumber = TB_MO_02.Style and
    SB.Size = TB_MO_02.Size

left outer join 
        (select distinct ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category
            from 
                (	Select * from (
                                    select *,row_number() over (partition by Manufactureid order by Manufactureid, consumption desc ) as Cuenta
                                            from [192.168.1.53].appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
                                    where (Size is null or rtrim(Size)='') and category='Fabric'
                                    --and mo in ('RO123021CCW115-837-5','TO1018CCW115-837-1')
                                ) SubFabric01 where Cuenta =1
                    union all
            
                    SELECT * FROM (
                                    select *, row_number() over (partition by Manufactureid order by Manufactureid, consumption desc ) as Cuenta
                                    from [192.168.1.53].appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
                                    where (Size is null or rtrim(Size)='') and category='Contracts'
                                    --and mo in ('RO123021CCW115-837-5','TO1018CCW115-837-1')
                                    )SubContract WHERE Cuenta =1
                ) TB_MO_1
            --where TB_MO_1.ncuenta=1
        ) TB_MO_2
        ON COALESCE(SB.ManufactureID,SMO.MOID) = TB_MO_2.ManufactureID 

    LEFT JOIN #TB_Transfer_Kardex AS TK ON SB.ID = TK.IDExport


--- Pre ingreso de datos en #TB_Transfer para evitar contar cajas 2 veces


SELECT 
    [ShipDate]					=	TE.[ShipDate]
    ,[Waybill]					=	TE.[Waybill]
    ,[Container]				=	TB_GROUP.[Container]
    ,[InvoiceBatch]				=	TE.[InvoiceBatch]
    ,[Batch]					=	TE.[Batch]
    ,[PONumber]					=	TE.[PONumber]
    ,[BoxNumber]				=	TE.[BoxNumber]
    ,[FormattedBoxNumber]		=	TB_GROUP.[FormattedBoxNumber]
    ,[StyleNumber]				=	TE.[StyleNumber]
    ,[StyleColor]				=	TE.[StyleColor]
    ,[Size]						=	TE.[Size]
    ,[PalletNumber]				=	TB_GROUP.[PalletNumber]
    ,[Price]					=	TE.[Price]
    ,[CA_HTSCode]				=	case 
                                        when lmn.US_HTSCode is not null then lmn.US_HTSCode
                                        when lmn.US_HTSCode is null and lmn.CA_HTSCode is not null then lmn.CA_HTSCode
                                        else   TE.[SAC] 
                                    end
    ,[CA_HTSDescription]		=	TE.[HTSDescription]
    ,[US_HTSCode]				=	case 
                                        when lmn.US_HTSCode is not null then lmn.US_HTSCode
                                        when lmn.US_HTSCode is null and lmn.CA_HTSCode is not null then lmn.CA_HTSCode
                                        else   TB_GROUP.[US_HTSCode] 
                                    end 
    ,[US_HTSDescription]		=	TB_GROUP.US_HTSDescription
    ,[InvoicingDescription]		=	case 
                                        when TE.ManufactureID is not null 
                                            and (FabCont.DescribeText is not null or FabCont.InvoicingDescription is not null)
                                            then  concat(FabCont.DescribeText, ' ',FabCont.InvoicingDescription)
                                        when FabCont2.DescribeText is not null or FabCont2.InvoicingDescription is not null
                                            then  concat(FabCont2.DescribeText, ' ',FabCont2.InvoicingDescription)
                                        else TB_GROUP.[InvoicingDescription]
                                    end
    -- ,[GrossWeightKGSXUnits]		=	TB_GROUP.[GrossWeightKGSXUnits]
    ,[GrossWeightKGSXUnits]		=	SB.[Gross_Weight_kgs]
    --,[Qty]						=	SB.Qty
    ,[Qty]						=	TK.QtyTransfer
                                        
    ,[Manufactured]				=	COALESCE(TI.Manufacturer, TB_MO_02.Manufacturer,TB_MO_2.Manufacturer)
    ,[CountryOfOrigin]			=	COALESCE(TI.CountryOfOriginName, TB_MO_02.CountryOfOrigin,TB_MO_2.CountryOfOrigin)
    ,[ProductDivision]			=	ST.Comments9 
    ,[US_HTSCode2]				=	HTS.US_HTSCode  
    ,[TariffCategory]			=	case 
                                        when TB_MO_02.TariffCategory is not null or TB_MO_2.TariffCategory is not null
                                            then COALESCE(TB_MO_02.TariffCategory,TB_MO_2.TariffCategory)
                                        else TMO_APri.comments16
                                    end 
    ,[IDExport] 				=	TE.ID
    ,[IM5]						=	TI.IM5
    ,[DeclarationDate]			=	TI.DeclarationDate
    ,[ArrivalDate]				=	TI.ArrivalDate
    ,[DepartureDate]			=	TI.DepartureDate
    ,[PortOfLoading]			=	TI.PortOfLoading
    ,[Screen_Print]				=	COALESCE(TE.Screen_Print,0.00)
    ,[Embroidery]				=	COALESCE(TE.Embroidery,0.00)
    ,[Sublimation]				=	COALESCE(TE.Sublimation,0.00)
    ,[UnitDecoration]			=	COALESCE(TE.[Unit Decoration],0.00)
INTO #TB_Transfer
FROM 
(
    SELECT  
        WayBill
        ,ContainerNumber AS Container
        ,BoxNumber
        ,FormattedBoxNumber
        ,StyleNumber
        ,StyleColor
        ,GarmentSize
        ,PalletNumber 	=	CASE WHEN Bin IS NOT NULL THEN Bin ELSE PalletNumber END
        ,US_HTSCode
        ,US_HTSDescription
        ,InvoicingDescription
        ,GrossWeightKGSXUnits
    FROM [192.168.1.53].[AppsLCA].[dbo].[ImportExport_ShipmentBoxAll] with (nolock)
    -- WHERE WayBill IN (@WayBill) --'AIR20240409'
    WHERE ShipDate >= @ShipDate AND ShipDate <= @ShipDateEnd
    GROUP BY WayBill 
            ,ContainerNumber
            ,BoxNumber
            ,FormattedBoxNumber
            ,StyleNumber
            ,StyleColor
            ,GarmentSize
            ,PalletNumber
            ,Bin
            ,US_HTSCode
            ,US_HTSDescription
            ,InvoicingDescription
            ,GrossWeightKGSXUnits
) AS TB_GROUP
INNER JOIN	[192.168.1.53].[AppsLCA].[dbo].[TB_Transfer_Export]		AS TE	WITH(NOLOCK)	ON TE.Waybill = TB_GROUP.WayBill AND TE.BoxNumber = TB_GROUP.BoxNumber 
                                                                                                                        AND TE.StyleNumber = TB_GROUP.StyleNumber 
                                                                                                                        AND TE.StyleColor = TB_GROUP.StyleColor
                                                                                                                        AND TE.Size = TB_GROUP.GarmentSize
                                                                                                                        AND TE.[status] = 1
INNER JOIN  [192.168.1.53].[AppsLCA].[dbo].[ImportExport_AnexoFacturacion]	AS SB	WITH(NOLOCK) ON TE.ID = SB.ID
LEFT JOIN #TB_Transfer_Kardex AS TK ON TK.IDExport = TE.ID
LEFT JOIN [192.168.1.53].[AppsLCA].[dbo].[TB_Transfer_Import]		AS TI	WITH(NOLOCK)	ON TI.ID = TK.IDImport
                                                                                                                        
left outer join (Select * from 
                        (select Color, Style, CA_HTSCode, US_HTSCode from 
                                        (select RW.PartNumber, RW.HTSCodeID, Col.ColorName as Color, CL.ComponentName as Style,
                                        DRD.DropDownValue as CA_HTSCode, DRD.Description3 as US_HTSCode	,
                                        row_number() over(partition by Col.ColorName, CL.ComponentName order by Col.ColorName, CL.ComponentName) as Cuenta
                                            FROM [192.168.1.53].[LCA].[dbo].[RawMaterials]  RW with (nolock)
                                            left outer join [192.168.1.53].lca.dbo.Colors COL with (nolock)
                                                on RW.ColorID = Col.ColorID
                                            left outer join [192.168.1.53].lca.dbo.ComponentLibrary CL with (nolock)
                                                on RW.ComponentID = CL.ComponentID and CL.ComponentCategoryID=11
                                            left outer join [192.168.1.53].lca.dbo.DropDownValues DRD with (nolock)
                                                on RW.HTSCodeID = DRD.DropDownValueID
                                            where Cl.ComponentName is not null and Col.ColorName is not null
                                        ) abc123 where Cuenta=1
                        ) fgh
                ) lmn	on TE.StyleNumber = lmn.Style and TE.StyleColor=lmn.Color
--left outer join (
--					SELECT
--						MOID		= BKD.ManufactureID
--						,BlankStyle = ST2.StyleNumber
--						,StyleColor = STC.StyleColorName
--						,Size 		= BK.GarmentSize
--						,PB.BoxNumber
--					FROM 	   [192.168.1.53].AppsLCA.dbo.TB_PackedItem_MO_BundlesKit_Details	AS BKD WITH(NOLOCK)
--					INNER JOIN [192.168.1.53].AppsLCA.dbo.TB_PackedItem_MO_BundlesKit			AS BK  WITH(NOLOCK) ON BK.PackedItemID = BKD.PackedItemID
--					INNER JOIN [192.168.1.53].LCA.dbo.Styles									AS ST  WITH(NOLOCK) ON ST.StyleID = BK.StyleID
--					INNER JOIN [192.168.1.53].LCA.dbo.StyleColors								AS STC WITH(NOLOCK) ON STC.StyleColorID = BK.StyleColorID
--					INNER JOIN [192.168.1.53].LCA.dbo.PackedItems								AS PKI WITH(NOLOCK) ON PKI.PackedItemID = BKD.PackedItemID
--					INNER JOIN [192.168.1.53].LCA.dbo.PackedBoxes								AS PB  WITH(NOLOCK) ON PB.PackedBoxID = PKI.PackedBoxID
--					LEFT JOIN  [192.168.1.53].LCA.dbo.Styles									AS ST2 WITH(NOLOCK) ON ST2.StyleID = ST.BlankStyleID

--				)AS SMO
left outer join [192.168.1.53].[LCA].[dbo].[VW_Check_Sales_Prices_in_Invoices_SeekMO_Bundle] AS SMO with (nolock)
        ON TE.BoxNumber = SMO.BoxNumber AND TE.StyleNumber = SMO.BlankStyleNumber AND TE.StyleColor = SMO.Stylecolor AND TE.Size = SMO.Size
left outer join [192.168.1.53].lca.dbo.ManufactureOrders TMO_APri with (nolock) 
        ON COALESCE(TE.ManufactureID,SMO.MOID) = TMO_APri.manufactureid
left outer join [192.168.1.53].lca.dbo.OrderItems ODT_PRI with (nolock)
        on TMO_APri.FirstOrderItemID = ODT_PRI.OrderItemID   and
            TMO_APri.OrderID = ODT_PRI.OrderID 
LEFT JOIN [192.168.1.53].LCA.dbo.Styles AS ST WITH(NOLOCK) ON ODT_PRI.StyleID = ST.StyleID

LEFT JOIN [192.168.1.53].LCA.dbo.Styles AS BST WITH(NOLOCK) ON BST.StyleID = ST.BlankStyleID

left outer join [192.168.1.53].lca.dbo.HTSStyleCodes HTS with (nolock) on st.HTSStyleCodeID = HTS.HTSStyleCodeID 

left outer join #TB_ContentFabric AS FabCont
        on BST.StyleNumber = FabCont.Style and TE.StyleColor = FabCont.StyleColorName

left outer join #TB_ContentFabric AS FabCont2
        on TE.StyleNumber = FabCont2.Style and TE.StyleColor = FabCont2.StyleColorName

left outer join 
(
    select ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category,Style,Size
        from 
            (
                select ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category,Style,Size,
                    row_number() over(Partition by Manufactureid, Size 
                    order by  Manufactureid, Size, Consumption desc )
                    as Ncuenta
                from [192.168.1.53].appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
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
ON TE.RO_ID = TB_MO_02.ManufactureID and
    TE.StyleNumber = TB_MO_02.Style and
    TE.Size = TB_MO_02.Size

left outer join 
        (select distinct ManufactureId, CountryOfOrigin , Manufacturer, TariffCategory,Category
            from 
                (	Select * from (
                                    select *,row_number() over (partition by Manufactureid order by Manufactureid, consumption desc ) as Cuenta
                                            from [192.168.1.53].appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
                                    where (Size is null or rtrim(Size)='') and category='Fabric'
                                    --and mo in ('RO123021CCW115-837-5','TO1018CCW115-837-1')
                                ) SubFabric01 where Cuenta =1
                    union all
            
                    SELECT * FROM (
                                    select *, row_number() over (partition by Manufactureid order by Manufactureid, consumption desc ) as Cuenta
                                    from [192.168.1.53].appslca.dbo.TB_MO_PartNumber_IM_Summary with (nolock)
                                    where (Size is null or rtrim(Size)='') and category='Contracts'
                                    --and mo in ('RO123021CCW115-837-5','TO1018CCW115-837-1')
                                    )SubContract WHERE Cuenta =1
                ) TB_MO_1
            --where TB_MO_1.ncuenta=1
        ) TB_MO_2
ON COALESCE(TE.ManufactureID,SMO.MOID) = TB_MO_2.ManufactureID 
	

-- --- UPDATE para evitar contar cajas 2 veces
-- UPDATE CI
-- 	SET CI.GroupBox =  CASE WHEN CI.GroupBox = 1 THEN 0 ELSE CI.GroupBox END
-- FROM #TB_DataCI AS CI
-- INNER JOIN #TB_Transfer AS TR ON CI.FormattedBoxNumber = TR.FormattedBoxNumber


-- UPDATE CI 
-- SET CI.GroupBox = CASE
-- 					 WHEN SUMCI.Quantity > TR.Quantity AND CI.GroupBox = 1 THEN 1 
-- 					 WHEN SUMCI.Quantity = TR.Quantity AND CI.GroupBox = 1 THEN 1
-- 					ELSE 0 
-- 				  END
-- FROM #TB_DataCI AS CI
-- INNER JOIN (SELECT SUM(Quantity) as Quantity, FormattedBoxNumber FROM #TB_DataCI GROUP BY FormattedBoxNumber) AS SUMCI ON SUMCI.FormattedBoxNumber = CI.FormattedBoxNumber
-- INNER JOIN (SELECT SUM(Quantity) as Quantity, FormattedBoxNumber FROM #TB_Transfer GROUP BY FormattedBoxNumber) AS TR ON TR.FormattedBoxNumber = SUMCI.FormattedBoxNumber

-- UPDATE TR 
-- SET TR.GroupBox = CASE 
-- 						WHEN SUMTR.Quantity > SUMCI.Quantity AND TR.GroupBox = 1 THEN 1 
-- 						WHEN SUMTR.Quantity = SUMCI.Quantity AND TR.GroupBox = 1 THEN 0 
-- 						ELSE 0 
-- 				  END
-- FROM #TB_Transfer AS TR
-- INNER JOIN (SELECT SUM(Quantity) as Quantity, FormattedBoxNumber FROM #TB_DataCI GROUP BY FormattedBoxNumber) AS SUMCI ON SUMCI.FormattedBoxNumber = TR.FormattedBoxNumber
-- INNER JOIN (SELECT SUM(Quantity) as Quantity, FormattedBoxNumber FROM #TB_Transfer GROUP BY FormattedBoxNumber) AS SUMTR ON SUMTR.FormattedBoxNumber = SUMCI.FormattedBoxNumber

SELECT * FROM #TB_DataCI
-- 	union all 
SELECT * FROM #TB_Transfer
return
-- select *, ROW_NUMBER() OVER(PARTITION BY BoxNumber ORDER BY BoxNumber) as cuenta FROM
-- (
-- 	SELECT BoxNumber, StyleNumber, Quantity, GroupBox AS GRCI FROM #TB_DataCI
-- 	union all 
-- 	SELECT BoxNumber, StyleNumber, Quantity, GroupBox AS GRTR FROM #TB_Transfer
-- ) as tb

--- INSERT FINAL EN AMBAS TABLAS

-- insert into Import_Export_CommercialInvoice_TEST
-- insert into Import_Export_CommercialInvoice
-- select  top 100 percent @Waybill as WayBill,
-- CI_Ver2.* , 
-- 		case when Cafta='Y' then 1
-- 			when Cafta='N' then 2 
-- 			else 2
-- 		end as Orden
-- 		from 	
-- 	(
-- 	SELECT
-- 		 [Container]					=	TB.[Container]
-- 		,[StyleNumber]					=	TB.[StyleNumber]
-- 		,[InvoicingDescription]			=	TB.[InvoicingDescription]
-- 		,[US_HTSDescription]			=	TB.[US_HTSDescription]
-- 		,[CA_HTSCode]					=	TB.[CA_HTSCode]
-- 		,[Price]						=	TB.[Price]
-- 		,[ShipDate]						=	MAX([ShipDate])
-- 		,[Quantity]						=	ROUND(SUM(TB.[Quantity]),2)
-- 		,[TotalPrice]					=	SUM(TB.[TotalPrice])
-- 		,[MinBatch]						=	MIN(TB.[Batch])
-- 		,[WeightKg]						=	SUM(TB.[WeightKg])
-- 		,[MaxBatch]						=	MAX(TB.[Batch])
-- 		,[Cafta]						=	TB.[Cafta]
-- 		,[Pallets]						=	SUM(CASE WHEN [GroupPallet]  = 1 THEN 1 ELSE 0 END)
-- 		,[Boxes]						=	SUM(CASE WHEN [GroupBox]     = 1 THEN 1 ELSE 0 END)
-- 		,[Manufactured]					=	COALESCE(TB.[Manufactured], 'League LTDA')
-- 		,[CountryOfOrigin]				=	COALESCE(TB.[CountryOfOrigin], 'El Salvador')
-- 	FROM #TB_DataCI AS TB
-- 	GROUP BY
-- 		TB.Container
-- 		,TB.StyleNumber
-- 		,TB.InvoicingDescription
-- 		,TB.US_HTSDescription
-- 		,TB.CA_HTSCode
-- 		,TB.Price
-- 		,TB.Cafta 
-- 		,TB.Manufactured
-- 		,TB.CountryOfOrigin
-- 	) CI_ver2
-- 	Order by 
-- 			 Orden
-- 			,Cafta desc
-- 			,CountryOfOrigin
-- 			,StyleNumber
-- 			,Container
-- 			,US_HTSDescription
-- 			,CA_HTSCode
-- 			,Price
-- 			,InvoicingDescription
-- 			,Manufactured

-- IF @TransferVal > 0
-- BEGIN
-- 	-- insert into  dbo.Import_Export_DeclarationExport
-- 	select  top 100 percent @Waybill as WayBill,
-- 	CI_Ver2.* , 
-- 	3 AS Orden
-- 	from 	
-- 	(	
-- 		SELECT
-- 			[Container]					=	TB.[Container]
-- 			,[StyleNumber]					=	TB.[StyleNumber]
-- 			,[InvoicingDescription]			=	TB.[InvoicingDescription]
-- 			,[US_HTSDescription]			=	TB.[US_HTSDescription]
-- 			,[CA_HTSCode]					=	TB.[CA_HTSCode]
-- 			,[Price]						=	TB.[Price]
-- 			,[ShipDate]						=	MAX([ShipDate])
-- 			,[Quantity]						=	ROUND(SUM(TB.[Quantity]),2)
-- 			,[TotalPrice]					=	SUM(TB.[TotalPrice])
-- 			,[MinBatch]						=	MIN(TB.[Batch])
-- 			,[WeightKg]						=	SUM(TB.[WeightKg])
-- 			,[MaxBatch]						=	MAX(TB.[Batch])
-- 			,[Cafta]						=	TB.[Cafta]
-- 			,[Pallets]						=	SUM(CASE WHEN [GroupPallet]  = 1 THEN 1 ELSE 0 END)
-- 			,[Boxes]						=	SUM(CASE WHEN [GroupBox]     = 1 THEN 1 ELSE 0 END)
-- 			,[Manufactured]					=	COALESCE(TB.[Manufactured], 'League LTDA')
-- 			,[CountryOfOrigin]				=	COALESCE(TB.[CountryOfOrigin], 'El Salvador')

-- 			,[IM5]							=	TB.[IM5]				
-- 			,[DeclarationDate]				=	TB.[DeclarationDate]
-- 			,[ArrivalDate]					=	TB.[ArrivalDate]
-- 			,[DepartureDate]				=	TB.[DepartureDate]
-- 			,[PortOfLoading]				=	TB.[PortOfLoading]
-- 			,[DecorationDesc]				=	TB.[DecorationDesc]
-- 			,[DecorationValue]				=	ROUND(SUM(TB.[DecorationValue]),2)
-- 		FROM #TB_Transfer AS TB
-- 		GROUP BY
-- 			TB.Container
-- 			,TB.StyleNumber
-- 			,TB.InvoicingDescription
-- 			,TB.US_HTSDescription
-- 			,TB.CA_HTSCode
-- 			,TB.Price
-- 			,TB.Cafta 
-- 			,TB.Manufactured
-- 			,TB.CountryOfOrigin

-- 			,TB.IM5
-- 			,TB.DeclarationDate
-- 			,TB.ArrivalDate
-- 			,TB.DepartureDate
-- 			,TB.PortOfLoading
-- 			,TB.DecorationDesc
-- 	) CI_ver2
-- 	Order by 
-- 			 Orden
-- 			,IM5
-- 			,CountryOfOrigin
-- 			,StyleNumber
-- 			,Container
-- 			,US_HTSDescription
-- 			,CA_HTSCode
-- 			,Price
-- 			,InvoicingDescription
-- 			,Manufactured
-- END
	
-- update [192.168.1.53].[AppsLCA].[dbo].[ImportExport_CommercialInvoice_Status] set [Status] = 'Finished', Finished_Date=getdate() 
-- 	where waybill =@WayBill
	

-- 	Fetch next from WayBill_status into  @Waybill, @Status, @Pending_Date, @Executing_date, @Finished_Date


-- 	end
-- close WayBill_status
-- deallocate WayBill_status

-- END