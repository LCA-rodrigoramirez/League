USE [LCA]

----- [dboReaders].[VW_ImpExp_ShipmentBoxGlobal]
    SELECT 
         [WayBill]                       = sbal.[WayBill]
        ,[BoxNumber]                     = sbal.[BoxNumber]
        ,[Units]                         = sbal.[Units]
        -- ,[GrossWeight]                   = IIF(sbal.[PalletTypeID] = 4 
        --                                           ,sbal.[GrossWeight] +   (sbal.[PalletWeight] / (SUM(sbal.[units]) OVER (PARTITION BY sbal.[FormattedBoxNumber])) ) * sbal.[Units]
        --                                           ,sbal.[GrossWeight]
        --                                     )

        ,[GrossWeight]                   = sbal.[GrossWeight]   ---antes de inner box
        ,[NetWeight]                     = sbal.[NetWeight]
        ,[ShipDate]                      = sbal.[ShipDate]
        ,[PONumber]                      = sbal.[PONumber]
        ,[GrossWeightKGS]                = CASE 
                                                WHEN sbal.[CreateDate] >= '2019-06-24T12:05:00.000' 
                                                THEN sbal.[GrossWeight] 
                                                ELSE sbal.[GrossWeight]/2.20462 
                                              END
        ,[NetWeightKGS]                  = CASE 
                                                WHEN sbal.[CreateDate] >= '2019-06-24T12:05:00.000' 
                                                THEN sbal.[NetWeight] 
                                                ELSE sbal.[NetWeight]/2.20462 
                                              END
        ,[GrossWeightKGSXUnits]          = CASE 
                                                WHEN sbal.[CreateDate] >= '2019-06-24T12:05:00.000' 
                                                THEN (sbal.[GrossWeight]) / (sbal.[Units]) 
                                                ELSE (sbal.[GrossWeight]/2.20462) / (sbal.[Units]) 
                                              END
        ,[NetWeightKGSXUnits]            = CASE 
                                              WHEN sbal.[CreateDate] >= '2019-06-24T12:05:00.000' 
                                              THEN (sbal.[NetWeight]) / (sbal.[Units]) 
                                              ELSE (sbal.[NetWeight]/2.20462) / (sbal.[Units]) 
                                            END
		,[PackedPalletID]				 = sbal.[PackedPalletID]
        ,[PalletNumber]                  = sbal.[PalletNumber]
        ,[PackedBoxID]                   = sbal.[PackedBoxID]
        ,[Bin]                           = sbal.[Bin]
        ,[PalletTypeID]                  = sbal.[PalletTypeID]
        ,[PalletWeight]                  = sbal.[PalletWeight]
        ,[FormattedBoxNumber]            = sbal.[FormattedBoxNumber]
        -- ,[SumUnitFormattedBoxNumber]     = SUM(sbal.[units]) OVER (PARTITION BY sbal.[FormattedBoxNumber])
        -- ,[NewWeightPallet]               = (sbal.[PalletWeight] / (SUM(sbal.[units]) OVER (PARTITION BY sbal.[FormattedBoxNumber])) ) * sbal.[Units]    ---MADE BY "LA PROGRAMACION" 2025-06-12
    FROM(
      SELECT 
        [WayBill]             = sh.[waybill]
        ,[BoxNumber]           = pb.[boxnumber]
        ,[Units]               = ( SELECT SUM(pbi.[quantity]) FROM dbo.packeditems as pbi WITH(NOLOCK) WHERE pbi.[packedboxid] = [pb].[packedboxid] )
        ,[BoxType]             = bxtp.[boxtypename]
        -- ,[GrossWeight]         = pb.[weight]                      ---Se agrega en el select arriba la porcion de la consolidateBox por las unidades de cada item 2025-06-12
        -- ,[GrossWeight]         =  
        --                             IIF(pp.[PalletTypeID] = 4 
        --                                           ,pb.[weight] +   (ppt.[PalletWeight] / (SUM(
        --                                                                                       ( SELECT SUM(pbi.[quantity]) FROM dbo.packeditems as pbi WITH(NOLOCK) WHERE pbi.[packedboxid] = [pb].[packedboxid] )
        --                                                                                       ) 
        --                                                                                       OVER (PARTITION BY 
        --                                                                                               IIF(pp.PalletTypeID = 4 , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[Dropdownvalue] ,'000'),3) ) 
        --                                                                                                         ,pb.[BoxNumber] 
        --                                                                                                     )
        --                                                                                               )) ) 
        --                                                                                     * ( SELECT SUM(pbi.[quantity]) FROM dbo.packeditems as pbi WITH(NOLOCK) WHERE pbi.[packedboxid] = [pb].[packedboxid] )
        --                                           ,pb.[weight]
        --                                     )
        ,[GrossWeight]         =  
                                    IIF(pp.PalletTypeID <> 1 AND pp.PalletTypeID IS NOT NULL
                                                  ,pb.[weight] +   (ppt.[PalletWeight] / (SUM(
                                                                                              ( SELECT SUM(pbi.[quantity]) FROM dbo.packeditems as pbi WITH(NOLOCK) WHERE pbi.[packedboxid] = [pb].[packedboxid] )
                                                                                              ) 
                                                                                              OVER (PARTITION BY 
                                                                                                      IIF(pp.PalletTypeID <> 1 AND pp.PalletTypeID IS NOT NULL , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[Dropdownvalue] ,'000'),3) ) 
                                                                                                                ,pb.[BoxNumber] 
                                                                                                            )
                                                                                                      )) ) 
                                                                                            * ( SELECT SUM(pbi.[quantity]) FROM dbo.packeditems as pbi WITH(NOLOCK) WHERE pbi.[packedboxid] = [pb].[packedboxid] )
                                                  ,pb.[weight]
                                            )

        ,[NetWeight]           = pb.[weight] - bxtp.[boxweight]   
        -- ,[BoxWeight]           = bxtp.[boxweight]
        -- ,[BoxWeight]           = IIF(pp.[PalletTypeID] = 4
        --                                   ,bxtp.[boxweight] +     (ppt.[PalletWeight] / (SUM(
        --                                                                                       ( SELECT SUM(pbi.[quantity]) FROM dbo.packeditems as pbi WITH(NOLOCK) WHERE pbi.[packedboxid] = [pb].[packedboxid] )
        --                                                                                       ) 
        --                                                                                       OVER (PARTITION BY 
        --                                                                                               IIF(pp.PalletTypeID = 4 , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[Dropdownvalue] ,'000'),3) ) 
        --                                                                                                         ,pb.[BoxNumber] 
        --                                                                                                     )
        --                                                                                               )) ) 
        --                                                                                     * ( SELECT SUM(pbi.[quantity]) FROM dbo.packeditems as pbi WITH(NOLOCK) WHERE pbi.[packedboxid] = [pb].[packedboxid] )
        --                                   ,bxtp.[boxweight]   
        --                               )  
        ,[BoxWeight]           = IIF(pp.PalletTypeID <> 1 AND pp.PalletTypeID IS NOT NULL
                                          ,bxtp.[boxweight] +     (ppt.[PalletWeight] / (SUM(
                                                                                              ( SELECT SUM(pbi.[quantity]) FROM dbo.packeditems as pbi WITH(NOLOCK) WHERE pbi.[packedboxid] = [pb].[packedboxid] )
                                                                                              ) 
                                                                                              OVER (PARTITION BY 
                                                                                                      IIF(pp.PalletTypeID <> 1 AND pp.PalletTypeID IS NOT NULL, CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[Dropdownvalue] ,'000'),3) ) 
                                                                                                                ,pb.[BoxNumber] 
                                                                                                            )
                                                                                                      )) ) 
                                                                                            * ( SELECT SUM(pbi.[quantity]) FROM dbo.packeditems as pbi WITH(NOLOCK) WHERE pbi.[packedboxid] = [pb].[packedboxid] )
                                          ,bxtp.[boxweight]   
                                      )  

		,[PalletNumber]        = pp.[palletnumber]
        ,[PackedBoxID]         = pb.[packedboxid]
        ,[ShipDate]            = sh.[shipdate]
        ,[BoxTypeID]           = pb.[boxtypeid]
        ,[OrderID]             = pb.[orderid]
        ,[PONumber]            = od.[ponumber]
        ,[ShipmentID]          = pb.[shipmentid]
        ,[ShipStatusID]        = sh.[statusid]
        ,[StatusID]            = pb.[statusid]
        ,[WarehouseID]         = pb.[warehouseid]
        ,[PackedPalletID]      = pb.[packedpalletid]
        ,[ContainerShipDate_]  = shc.[shipdate]
        ,[CreateDate]          = pb.[CreateDate]
        ,[Bin]                 = gb.[Bin]
        ,[PalletTypeID]        = pp.[PalletTypeID]
        -- ,[PalletWeight]        = IIF(pp.PalletTypeID = 4 , COALESCE(ppt.[PalletWeight],0.00) ,0.00)
        -- ,[FormattedBoxNumber]	 = IIF(pp.PalletTypeID = 4 , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[Dropdownvalue] ,'000'),3) ) 
        --                                             ,pb.[BoxNumber] 
        --                                         )
        ,[PalletWeight]        = IIF(pp.PalletTypeID <> 1 AND pp.PalletTypeID IS NOT NULL , COALESCE(ppt.[PalletWeight],0.00) ,0.00)
        ,[FormattedBoxNumber]	 = IIF(pp.PalletTypeID <> 1 AND pp.PalletTypeID IS NOT NULL , CONCAT( pp.[PalletNumber] ,'-', RIGHT(COALESCE(btg.[Dropdownvalue] ,'000'),3) ) 
                                                    ,pb.[BoxNumber] 
                                                )
      FROM		    dbo.statusNames				  AS snpb WITH(NOLOCK)
      INNER JOIN	dbo.packedboxes				  AS pb	  WITH(NOLOCK)	ON pb.StatusID				    = snpb.StatusID		AND pb.orderid IS NOT NULL AND ( pb.statusid < 110  OR pb.statusid = 113 )  
      INNER JOIN	dbo.shipments				    AS sh	  WITH(NOLOCK)	ON pb.shipmentid			    = sh.shipmentid		AND sh.ShipDate > DATEADD(month,-4,convert(date,getdate()))
      LEFT JOIN	  dbo.boxtypes				    AS bxtp WITH(NOLOCK)	ON pb.boxtypeid				    = bxtp.boxtypeid 
      LEFT JOIN	  dbo.orders					    AS od	  WITH(NOLOCK)	ON pb.orderid				      = od.orderid 
      LEFT JOIN	  dbo.shippingcontainers	AS shc	WITH(NOLOCK)	ON sh.shippingcontainerid	= shc.shippingcontainerid 
      LEFT JOIN	  dbo.goodsbins				    AS gb	  WITH(NOLOCK)	ON pb.goodsbinid			    = gb.goodsbinid 
      LEFT JOIN	  dbo.packedpallets			  AS pp	  WITH(NOLOCK)	ON pb.packedpalletid		  = pp.packedpalletid 
      LEFT JOIN   dbo.PalletTypes         AS ppt  WITH(NOLOCK)  ON pp.PalletTypeID        = ppt.PalletTypeID  
      LEFT JOIN   dbo.DropDownValues3     AS btg  WITH(NOLOCK)  ON pb.BoxTagID            = btg.DropDownValueID
    ) AS sbal


------ [dboReaders].[VW_ImpExp_ShipmentBoxItems_withColor]

WITH CTE_ANEXO
AS
(
	SELECT
		 Waybill
		,PONumber
		,OrderID
		,MO
		,ManufactureID
		,Price
		,BasePrice
	FROM AppsLCA.dbo.ImportExport_AnexoFacturacion WITH(NOLOCK)
	WHERE ShipDate > DATEADD(month,-3,convert(date,getdate()))
	--AND Waybill = 'APP-MST-20260203'
	GROUP BY
		Waybill
		,PONumber
		,OrderID
		,MO
		,ManufactureID
		,Price
		,BasePrice
)

SELECT				
sh.WayBill				As WayBill,
sc.ContainerNumber				AS ContainerNumber,
inb.invoicebatch     AS InvoiceBatch,
--substring(invoicebatches.invoicebatch, charindex('-',invoicebatches.InvoiceBatch)+1,10) as Batch,
RIGHT(inb.invoicebatch,4)     AS Batch,
od.ponumber                AS PONumber,
od.Comments6				AS APS,
od.Comments14				AS PrintCount,
pb.boxnumber           AS BoxNumber,
sti.stylenumber              AS StyleNumber,
sti.CostMaterials			AS StyleCostMaterials,
stc.stylecolorname      AS StyleColor,
stc.StyleColorDescription,
fg.garmentsize       AS GarmentSize,
pbi.quantity            AS Quantity,
ddv2ot.DropDownValue			AS PuertoDestino,

sti.htsstylecodeid			AS HTSStyleCodeIDOriginal,
hts.ca_htscode        AS CA_HTSCodeOriginal, 
hts.ca_htsdescription AS CA_HTSDescriptionOriginal,

hts.us_htscode        AS US_HTSCodeOriginal, 
hts.us_htsdescription AS US_HTSDescriptionOriginal,


case 
		when sti.[StyleNumber] like 'RW505%' and stc.stylecolorname  = '840' then 23
		when sti.[StyleNumber] like 'RW510%' and stc.stylecolorname  = '840' then 22
		when sti.[StyleNumber] like 'RW515%' and stc.stylecolorname  = '840' then 23
		when sti.[StyleNumber] like 'RW520%' and stc.stylecolorname  = '840' then 23
		when sti.[StyleNumber] like 'RW530%' and stc.stylecolorname  = '840' then 23

	else 
		sti.htsstylecodeid

end as HTSStyleCodeID,

case 
	when sti.[StyleNumber] like 'RW505%' and stc.stylecolorname  = '840' then '6110200000'
	when sti.[StyleNumber] like 'RW510%' and stc.stylecolorname  = '840' then '6104620000'
	when sti.[StyleNumber] like 'RW515%' and stc.stylecolorname  = '840' then '6110200000'
	when sti.[StyleNumber] like 'RW520%' and stc.stylecolorname  = '840' then '6110200000'
	when sti.[StyleNumber] like 'RW530%' and stc.stylecolorname  = '840' then '6110200000'


	else 
		hts.ca_htscode

end as [CA_HTSCode],

			replace(replace(replace(replace(replace(replace(

case 
		when sti.[StyleNumber] like 'RW505%' and stc.stylecolorname  = '840' then 'SUDADERA ALGODON CONFECCIONADA P/MUJER'
		when sti.[StyleNumber] like 'RW510%' and stc.stylecolorname  = '840' then 'PANTALON ALGODON CONFECCIONADA P/MUJER'
		when sti.[StyleNumber] like 'RW515%' and stc.stylecolorname  = '840' then 'SUDADERA ALGODON CONFECCIONADA P/MUJER'
		when sti.[StyleNumber] like 'RW520%' and stc.stylecolorname  = '840' then 'SUDADERA ALGODON CONFECCIONADA P/MUJER'
		when sti.[StyleNumber] like 'RW530%' and stc.stylecolorname  = '840' then 'SUDADERA ALGODON CONFECCIONADA P/MUJER'


	else 
		hts.ca_htsdescription
	end
			
			
	,'ñ','N'),'á','A'),'é','E'),'í','I'),'ó','O'),'ú','U') as [CA_HTSDescription],

case 
	when sti.[StyleNumber] like 'RW505%' and stc.stylecolorname  = '840' then '6110200000'
	when sti.[StyleNumber] like 'RW510%' and stc.stylecolorname  = '840' then '6104620000'
	when sti.[StyleNumber] like 'RW515%' and stc.stylecolorname  = '840' then '6110200000'
	when sti.[StyleNumber] like 'RW520%' and stc.stylecolorname  = '840' then '6110200000'
	when sti.[StyleNumber] like 'RW530%' and stc.stylecolorname  = '840' then '6110200000'


	else 
		hts.ca_htscode

end as [US_HTSCode],

case 
		when sti.[StyleNumber] like 'RW505%' and stc.stylecolorname  = '840' then 'WOMEN'+CHAR(39)+'S COTTON SWEATS'
		when sti.[StyleNumber] like 'RW510%' and stc.stylecolorname  = '840' then 'WOMEN'+CHAR(39)+'S COTTON PANTS'
		when sti.[StyleNumber] like 'RW515%' and stc.stylecolorname  = '840' then 'WOMEN'+CHAR(39)+'S COTTON SWEATS'
		when sti.[StyleNumber] like 'RW520%' and stc.stylecolorname  = '840' then 'WOMEN'+CHAR(39)+'S COTTON SWEATS'
		when sti.[StyleNumber] like 'RW530%' and stc.stylecolorname  = '840' then 'WOMEN'+CHAR(39)+'S COTTON SWEATS'


	else 
		hts.US_HTSDescription
	end as [US_HTSDescription],




CASE 
	WHEN CAST(sc.ShipDate AS DATE) < '2026-02-10' AND AF.Price IS NULL THEN oi2.unitprice
	WHEN CAST(sc.ShipDate AS DATE) < '2026-02-10' AND AF.Price IS NOT NULL THEN AF.Price
	WHEN SCPD.id IS NOT NULL THEN (SCPD.TotalBlank + SCPD.TotalDecoration)
	ELSE oi2.unitprice
END														AS UnitPrice,

CASE 
	WHEN CAST(sc.ShipDate AS DATE) < '2026-02-10' AND AF.BasePrice IS NULL THEN oi2.PricingUnitCost2
	WHEN CAST(sc.ShipDate AS DATE) < '2026-02-10' AND AF.BasePrice IS NOT NULL THEN AF.BasePrice
	WHEN SCPD.id IS NOT NULL THEN SCPD.TotalBlank
	WHEN AF.BasePrice IS NOT NULL THEN AF.BasePrice
	ELSE oi2.PricingUnitCost2
END														AS BasePrice,
--Shipments.ShipDate				AS ShipDate,
sc.ShipDate						AS ShipDate,
snpb.StatusName					AS BoxStatusName,
wh.WarehouseName				AS BoxWarehouseName,
st.CostMaterials				AS BlankStyleCostMaterials,


pbi.packeditemid        AS PackedItemID, 
pbi.finishedgoodsid     AS FinishedGoodsID, 
sti.seasonid                 AS SeasonID, 
pbi.packedboxid         AS PackedBoxID,
pbi.orderdetailsid      AS OrderDetailsID,
sc.ShippingContainerID as ShippingContainerID,
sh.ShipmentID as ShipmentID,
bxt.DropDownValue as BoxTag,
pb.BoxComments6		AS TrackingNumber
--select *
FROM   		(SELECT StatusID,StatusName FROM dbo.statusnames WITH(NOLOCK) WHERE StatusID = 75) AS FSN 
	INNER JOIN	dbo.statusnames						AS snpb	WITH(NOLOCK)	ON snpb.StatusID			= FSN.StatusID			AND snpb.StatusID = 75
	INNER JOIN	dbo.packedboxes						AS pb	WITH(NOLOCK)	ON pb.statusid				= snpb.statusid			AND pb.orderid IS NOT NULL
	INNER JOIN	dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid			AND (sh.ShipDate > DATEADD(month,-3,convert(date,getdate()))) --AND YEAR(sh.ShipDate) >= YEAR(DATEADD(YEAR,-1,GETDATE()))
	INNER JOIN	dbo.packeditems						AS pbi	WITH(NOLOCK)	ON pbi.packedboxid			= pb.packedboxid		AND pbi.quantity > 0  
	INNER JOIN	dbo.finishedgoods					AS fg	WITH(NOLOCK)	ON pbi.finishedgoodsid		= fg.finishedgoodsid 
	INNER JOIN	dbo.styles							AS sti	WITH(NOLOCK)	ON fg.styleid				= sti.styleid 
	LEFT JOIN	dbo.GoodsBins						AS gb	WITH(NOLOCK)	ON gb.GoodsBinID			= pb.GoodsBinID
	LEFT JOIN	dbo.ManufactureOrders				AS MO	WITH(NOLOCK)	ON MO.ManufactureID			= pbi.ManufactureID	
	LEFT JOIN	dbo.htsstylecodes					AS hts	WITH(NOLOCK)	ON sti.htsstylecodeid		= hts.htsstylecodeid 
	LEFT JOIN	dbo.stylecolors						AS stc	WITH(NOLOCK)	ON fg.stylecolorid			= stc.stylecolorid 	
	LEFT JOIN	dbo.orderdetails					AS odd	WITH(NOLOCK)	ON pbi.orderdetailsid		= odd.orderdetailsid 
	LEFT JOIN	dbo.orderitems						AS oi2	WITH(NOLOCK)	ON odd.orderitemid			= oi2.orderitemid 
	---SE COMENTA PORQUE ESTÁ TOMANDO EL DATO DE ORDER DETAILS Y DEBE SER POR LA MO, RR, DD, JH 20260210
	LEFT JOIN	dbo.orderitems						AS oi	WITH(NOLOCK)	ON oi.OrderItemID			= MO.FirstOrderItemID
	LEFT JOIN	dbo.invoicebatches					AS inb	WITH(NOLOCK)	ON sh.invoicebatchid		= inb.invoicebatchid 
	LEFT JOIN	dbo.orders							AS od	WITH(NOLOCK)	ON pb.orderid				= od.orderid 
	LEFT JOIN	dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid 
	LEFT JOIN	dbo.Warehouses						AS wh	WITH(NOLOCK)	ON wh.WarehouseID			= pb.WarehouseID
	LEFT JOIN	dbo.Styles							AS st	WITH(NOLOCK)	ON st.StyleID				= sti.BlankStyleID
	LEFT JOIN	dbo.ShippingContainers				AS sc	WITH(NOLOCK)	ON sc.ShippingContainerID	= sh.ShippingContainerID
	LEFT JOIN	dbo.DropDownValues3					AS bxt	WITH(NOLOCK)	ON bxt.DropDownValueID		= pb.BoxTagID -- Agregue esta tabla para traer BoxTag Diego Perez 20250605
	LEFT JOIN   dbo.Seasons							AS SEAS WITH(NOLOCK)	ON sti.SeasonID				= SEAS.SeasonID --Tabla agregada 2025 08 22 por Boris Hernandez y Rodrigo Ramirez
	LEFT JOIN	dbo.DropDownValues2					AS ddv2ot with(nolock) on ddv2ot.DropDownValueID = od.OrderTypeID3
	--- se agrega debido cambios en los precios por MO de famosisima --- RR Y DP 2026-02-27
	LEFT JOIN AppsLCA.dbo.TB_ShipmentCheckPricesDetail AS SCPD WITH(NOLOCK) ON oi.OrderItemID			= SCPD.OrderItemID
																			AND pbi.ManufactureID		= SCPD.ManufactureID
																			AND sh.WayBill				= SCPD.Waybill
	LEFT JOIN CTE_ANEXO								AS AF	WITH(NOLOCK)	ON pbi.ManufactureID = AF.ManufactureID
																			AND sh.WayBill = AF.Waybill
	--WHERE SH.Waybill = 'APP-MST-20260203' AND OD.PONumber = 'ORD-5159232'

GO

----- [dboReaders].[VW_ImpExp_ShippingPackingSlip]

select Waybill, Skid, ItemCode, Style, Color, ColorGreatPlain, Size, Qty, XX, OrderNo,L2Order, Box, Fact, Gender, Location, Note, TrackingNumber, BoxNo, ColorPolyPM, iif(qty>0,TotalPrices / Qty,0) as Price, TotalPrices, 
 CONVERT(VARCHAR(10), InvoiceDate, 23) as InvoiceDate	
	from 
	(select Waybill, Skid, ItemCode, Style, Color, ColorGreatPlain, Size, sum(qty) as qty, XX, OrderNO,L2Order, Box, Fact, Gender, [Location], Note, TrackingNumber, BoxNO, ColorPOlyPM, sum(TotalPrices) as totalPrices, InvoiceDate	
	   FROM --LCA.dboReaders.VW_ImpExp_ShippingPackingSlip  
		(
		SELECT
			 'Waybill'			= SBI.[WayBill]
			,'Barcode'			= SBI.[PackedItemID]
			-- ,'Skid'				= CASE 
			-- 						WHEN SBG.[PalletTypeID] = 4 AND SBI.[BoxTag] IS NOT NULL THEN COALESCE(SBG.[Bin],'0')
			-- 						ELSE COALESCE(SBG.[Bin],'0')
			-- 					  END
			,'Skid'				= CASE 
									WHEN SBG.[PalletTypeID] <> 1 AND SBG.[PalletTypeID] IS NOT NULL AND SBI.[BoxTag] IS NOT NULL THEN COALESCE(SBG.[Bin],'0')
									ELSE COALESCE(SBG.[Bin],'0')
								  END
			,'ItemCode'			= CASE
									WHEN L2B_LCA.InvItemNo IS NOT NULL THEN L2B_LCA.InvItemID
									WHEN SBI.[GarmentSize] = 'XS' THEN SBI.[StyleNumber] + '-' + [StyleColor] + 'A' + '-' + SBI.[GarmentSize]
									WHEN SBI.[GarmentSize] = 'S' THEN SBI.[StyleNumber] + '-' + [StyleColor] + 'B' + '-' + SBI.[GarmentSize]
									WHEN SBI.[GarmentSize] = 'M' THEN SBI.[StyleNumber] + '-' + [StyleColor] + 'C' + '-' + SBI.[GarmentSize]
									WHEN SBI.[GarmentSize] = 'QTY' THEN SBI.[StyleNumber] + '-' + [StyleColor] + 'C-M'
									WHEN SBI.[GarmentSize] = 'L' THEN SBI.[StyleNumber] + '-' + [StyleColor] + 'D' + '-' + SBI.[GarmentSize]
									WHEN SBI.[GarmentSize] = 'XL' THEN SBI.[StyleNumber] + '-' + [StyleColor] + 'E' + '-' + SBI.[GarmentSize]
									WHEN SBI.[GarmentSize] = '2XL' THEN SBI.[StyleNumber] + '-' + [StyleColor] + 'F' + '-' + SBI.[GarmentSize]
									WHEN SBI.[GarmentSize] = '3XL' THEN SBI.[StyleNumber] + '-' + [StyleColor] + 'G' + '-' + SBI.[GarmentSize]
									WHEN SBI.[GarmentSize] = '4XL' THEN SBI.[StyleNumber] + '-' + [StyleColor] + 'H' + '-' + SBI.[GarmentSize]
								  END
			,'Style'			= SBI.[StyleNumber]
			,'Color'			= SBI.[StyleColorDescription]
			,'ColorGreatPlain'	= SBI.[StyleColor]
			,'Size'				= CASE
									WHEN SBI.[GarmentSize] = 'QTY'
									THEN 'M'
									ELSE SBI.[GarmentSize]
								  END
			,'Qty'				= SBI.[Quantity]
			,'XX'				= ''
			,'OrderNo'			= SBI.[PONumber]
			,'L2Order'			= SBI.[APS]
			,'Box'				= ''
			,'Fact'				= SBI.[Batch]
			,'Gender'			= SBI.[CA_HTSDescriptionOriginal]
			,'Location'			= CASE
									WHEN SBI.[PuertoDestino] = 'Miami, FL 33182' THEN 'Account'
									WHEN SBI.[PuertoDestino] = 'Hanover' AND LEFT(SBI.[PONumber], 3) = 'ORD' THEN 'Printed to Hanover'
									ELSE SBI.[PuertoDestino]
								  END
			,'Note'				= ''
			,'TrackingNumber'	= CASE
									WHEN SBI.[PuertoDestino] = 'Miami, FL 33182' THEN SBI.TrackingNumber
									WHEN SBI.[PuertoDestino] = 'Hanover' AND LEFT(SBI.[PONumber], 3) = 'ORD' THEN ''
									ELSE ''
								  END
			,'BoxNo'			= IIF(SBG.[PalletTypeID] <> 1 AND SBG.[PalletTypeID] IS NOT NULL AND SBI.[BoxTag] IS NOT NULL, CONCAT('PPPA'+Ltrim(Str(SBG.PackedPalletID+1000000)),'-',RIGHT(SBI.[BoxTag],3))
																			,SBI.[BoxNumber]
																		)
			,'ColorPolyPM'		= SBI.[StyleColor]
			,'Price'			= SBI.[UnitPrice]
			,'TotalPrices'		= cast(SBI.[Quantity] as decimal(10,2)) * cast(SBI.[UnitPrice]  as decimal(10,2))
			,'InvoiceDate'		= SBI.ShipDate
		FROM [dboReaders].[VW_ImpExp_ShipmentBoxItems_withColor] SBI with(nolock)
		LEFT JOIN [dboReaders].[VW_ImpExp_ShipmentBoxGlobal] SBG with(nolock)
			ON SBI.PackedBoxID = SBG.PackedBoxID
		LEFT JOIN AppsLCA.legacycaps.VW_LCA_L2B_InventoryID L2B_LCA with (nolock)
			ON SBI.StyleNumber = L2B_LCA.style AND SBI.StyleColor= L2B_LCA.Color AND SBI.GarmentSize = L2B_LCA.SIZE

		)adf123

--WHERE adf123.Waybill ='APP-20260421' and adf123.barcode in (4516574, 4516575)
	group by Waybill, Skid, ItemCode, Style, Color, ColorGreatPlain, Size,  XX, OrderNO,L2Order, Box, Fact, Gender, [Location], Note, TrackingNumber, BoxNO, ColorPOlyPM,  InvoiceDate	
	)abcd


/* ============================================================================
   ANALISIS: ¿SE PUEDEN UNIR AMBAS VISTAS EN UNA SOLA?
   ============================================================================
   SI, con condiciones. No es un simple UNION/paste porque tienen GRANO distinto:

     - VW_ImpExp_ShipmentBoxGlobal        -> 1 fila por CAJA   (PackedBoxID)
     - VW_ImpExp_ShipmentBoxItems_withColor -> 1 fila por ITEM  (PackedItemID)

   La vista fusionada debe quedar a nivel de ITEM (grano mas fino). Las columnas
   de caja/pallet/peso de la Global se repiten en cada item de la misma caja,
   que es el comportamiento esperado en un packing slip.

   CONFLICTOS A DECIDIR ANTES DE CREAR LA VISTA (no son solo tecnicos):

   1) ShipDate NO es lo mismo en las dos vistas:
        - Global: sh.shipdate            (fecha del SHIPMENT)
        - Items : sc.ShipDate            (fecha del SHIPPING CONTAINER)
      Abajo dejo "ShipDate" = container (como esta hoy en Items, que parece ser
      el criterio vigente segun el codigo comentado) y agrego "ShipmentShipDate"
      aparte para no perder el dato de Global. CONFIRMAR cual debe ser la
      "ShipDate" oficial de la vista unificada.

   2) Filtro de Status distinto:
        - Global: pb.statusid < 110 OR pb.statusid = 113   (rango amplio)
        - Items : snpb.StatusID = 75                       (status puntual)
      Deje el filtro de Items (75) porque es el que trae hoy el detalle de
      producto. Si se necesita el universo amplio de Global, hay que decidir
      si se amplia el filtro o se maneja como parametro/columna adicional
      (BoxStatusID ya viene expuesto para poder filtrar despues).

   3) Rango de fecha distinto:
        - Global: DATEADD(month,-4,...)
        - Items : DATEADD(month,-3,...)
      Deje -3 meses (el de Items) por ser el mismo que ya trae el filtro de
      status/detalle. Ajustar si se requiere el rango de Global.

   JOINS DUPLICADOS QUE SI SE FUSIONAN SIN CONFLICTO (misma tabla, misma
   condicion en ambas vistas): packedpallets (pp), goodsbins (gb), orders (od),
   DropDownValues3 por BoxTagID, ShippingContainers.

   CALCULOS QUE DEBEN QUEDAR A NIVEL DE CAJA (no se pueden mover a nivel de
   item): los pesos que usan SUM(...) OVER (PARTITION BY FormattedBoxNumber)
   dependen de calcularse una sola vez por caja. Si se calculan a nivel de
   item, el SUM se multiplica por la cantidad de items de cada caja y el peso
   queda inflado. Por eso quedan en el CTE BoxAgg (grano caja) y se unen por
   PackedBoxID al resultado final (grano item).

   Nada de esto crea la vista todavia; es el borrador del query interno para
   revisar antes de convertirlo en VIEW.
   ============================================================================ */

;WITH CTE_ANEXO
AS
(
	SELECT
		 Waybill
		,PONumber
		,OrderID
		,MO
		,ManufactureID
		,Price
		,BasePrice
	FROM AppsLCA.dbo.ImportExport_AnexoFacturacion WITH(NOLOCK)
	WHERE ShipDate > DATEADD(month,-3,convert(date,getdate()))
	GROUP BY
		Waybill
		,PONumber
		,OrderID
		,MO
		,ManufactureID
		,Price
		,BasePrice
),
BoxAgg          -- ex VW_ImpExp_ShipmentBoxGlobal, agregado a nivel de CAJA
AS
(
	SELECT
		 [PackedBoxID]         = pb.[packedboxid]
		,[BoxUnits]            = ( SELECT SUM(pbi2.[quantity]) FROM dbo.packeditems AS pbi2 WITH(NOLOCK) WHERE pbi2.[packedboxid] = pb.[packedboxid] )
		,[BoxType]             = bxtp.[boxtypename]
		,[GrossWeight]         = IIF(pp.PalletTypeID <> 1 AND pp.PalletTypeID IS NOT NULL
										,pb.[weight] + ( ppt.[PalletWeight] / ( SUM( ( SELECT SUM(pbi2.[quantity]) FROM dbo.packeditems AS pbi2 WITH(NOLOCK) WHERE pbi2.[packedboxid] = pb.[packedboxid] ) )
																				OVER ( PARTITION BY IIF(pp.PalletTypeID <> 1 AND pp.PalletTypeID IS NOT NULL, CONCAT(pp.[PalletNumber],'-',RIGHT(COALESCE(btg.[Dropdownvalue],'000'),3)) ,pb.[BoxNumber]) ) ) )
																	* ( SELECT SUM(pbi2.[quantity]) FROM dbo.packeditems AS pbi2 WITH(NOLOCK) WHERE pbi2.[packedboxid] = pb.[packedboxid] )
										,pb.[weight]
									)
		,[NetWeight]           = pb.[weight] - bxtp.[boxweight]
		,[BoxWeight]           = IIF(pp.PalletTypeID <> 1 AND pp.PalletTypeID IS NOT NULL
										,bxtp.[boxweight] + ( ppt.[PalletWeight] / ( SUM( ( SELECT SUM(pbi2.[quantity]) FROM dbo.packeditems AS pbi2 WITH(NOLOCK) WHERE pbi2.[packedboxid] = pb.[packedboxid] ) )
																				OVER ( PARTITION BY IIF(pp.PalletTypeID <> 1 AND pp.PalletTypeID IS NOT NULL, CONCAT(pp.[PalletNumber],'-',RIGHT(COALESCE(btg.[Dropdownvalue],'000'),3)) ,pb.[BoxNumber]) ) ) )
																	* ( SELECT SUM(pbi2.[quantity]) FROM dbo.packeditems AS pbi2 WITH(NOLOCK) WHERE pbi2.[packedboxid] = pb.[packedboxid] )
										,bxtp.[boxweight]
									)
		,[PalletWeight]        = IIF(pp.PalletTypeID <> 1 AND pp.PalletTypeID IS NOT NULL, COALESCE(ppt.[PalletWeight],0.00) ,0.00)
		,[FormattedBoxNumber]  = IIF(pp.PalletTypeID <> 1 AND pp.PalletTypeID IS NOT NULL, CONCAT(pp.[PalletNumber],'-',RIGHT(COALESCE(btg.[Dropdownvalue],'000'),3)) ,pb.[BoxNumber])
		,[GrossWeightKGS]      = CASE WHEN pb.[CreateDate] >= '2019-06-24T12:05:00.000' THEN pb.[weight] ELSE pb.[weight]/2.20462 END
		,[NetWeightKGS]        = CASE WHEN pb.[CreateDate] >= '2019-06-24T12:05:00.000' THEN (pb.[weight]-bxtp.[boxweight]) ELSE (pb.[weight]-bxtp.[boxweight])/2.20462 END
	FROM		dbo.packedboxes			AS pb	WITH(NOLOCK)
	LEFT JOIN	dbo.boxtypes			AS bxtp	WITH(NOLOCK)	ON pb.boxtypeid			= bxtp.boxtypeid
	LEFT JOIN	dbo.packedpallets		AS pp	WITH(NOLOCK)	ON pb.packedpalletid	= pp.packedpalletid
	LEFT JOIN	dbo.PalletTypes			AS ppt	WITH(NOLOCK)	ON pp.PalletTypeID		= ppt.PalletTypeID
	LEFT JOIN	dbo.DropDownValues3		AS btg	WITH(NOLOCK)	ON pb.BoxTagID			= btg.DropDownValueID
	-- Sin WHERE aqui a proposito: se filtra en el SELECT final (item) para que
	-- el LEFT JOIN por PackedBoxID no descarte cajas que si aplican en el
	-- filtro de status/fecha del detalle. Ver punto 2 y 3 del analisis arriba.
)

SELECT
	 sh.WayBill							AS WayBill
	,sc.ContainerNumber					AS ContainerNumber
	,inb.invoicebatch						AS InvoiceBatch
	,RIGHT(inb.invoicebatch,4)				AS Batch
	,od.ponumber							AS PONumber
	,od.Comments6							AS APS
	,od.Comments14							AS PrintCount
	,pb.boxnumber							AS BoxNumber
	,sti.stylenumber						AS StyleNumber
	,sti.CostMaterials						AS StyleCostMaterials
	,stc.stylecolorname						AS StyleColor
	,stc.StyleColorDescription
	,fg.garmentsize							AS GarmentSize
	,pbi.quantity							AS Quantity				-- unidades a nivel de ITEM (linea)
	,ddv2ot.DropDownValue					AS PuertoDestino

	,sti.htsstylecodeid						AS HTSStyleCodeIDOriginal
	,hts.ca_htscode							AS CA_HTSCodeOriginal
	,hts.ca_htsdescription					AS CA_HTSDescriptionOriginal
	,hts.us_htscode							AS US_HTSCodeOriginal
	,hts.us_htsdescription					AS US_HTSDescriptionOriginal

	,CASE
			WHEN sti.[StyleNumber] LIKE 'RW505%' AND stc.stylecolorname = '840' THEN 23
			WHEN sti.[StyleNumber] LIKE 'RW510%' AND stc.stylecolorname = '840' THEN 22
			WHEN sti.[StyleNumber] LIKE 'RW515%' AND stc.stylecolorname = '840' THEN 23
			WHEN sti.[StyleNumber] LIKE 'RW520%' AND stc.stylecolorname = '840' THEN 23
			WHEN sti.[StyleNumber] LIKE 'RW530%' AND stc.stylecolorname = '840' THEN 23
			ELSE sti.htsstylecodeid
	 END										AS HTSStyleCodeID

	,CASE
			WHEN sti.[StyleNumber] LIKE 'RW505%' AND stc.stylecolorname = '840' THEN '6110200000'
			WHEN sti.[StyleNumber] LIKE 'RW510%' AND stc.stylecolorname = '840' THEN '6104620000'
			WHEN sti.[StyleNumber] LIKE 'RW515%' AND stc.stylecolorname = '840' THEN '6110200000'
			WHEN sti.[StyleNumber] LIKE 'RW520%' AND stc.stylecolorname = '840' THEN '6110200000'
			WHEN sti.[StyleNumber] LIKE 'RW530%' AND stc.stylecolorname = '840' THEN '6110200000'
			ELSE hts.ca_htscode
	 END										AS CA_HTSCode

	,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
		CASE
			WHEN sti.[StyleNumber] LIKE 'RW505%' AND stc.stylecolorname = '840' THEN 'SUDADERA ALGODON CONFECCIONADA P/MUJER'
			WHEN sti.[StyleNumber] LIKE 'RW510%' AND stc.stylecolorname = '840' THEN 'PANTALON ALGODON CONFECCIONADA P/MUJER'
			WHEN sti.[StyleNumber] LIKE 'RW515%' AND stc.stylecolorname = '840' THEN 'SUDADERA ALGODON CONFECCIONADA P/MUJER'
			WHEN sti.[StyleNumber] LIKE 'RW520%' AND stc.stylecolorname = '840' THEN 'SUDADERA ALGODON CONFECCIONADA P/MUJER'
			WHEN sti.[StyleNumber] LIKE 'RW530%' AND stc.stylecolorname = '840' THEN 'SUDADERA ALGODON CONFECCIONADA P/MUJER'
			ELSE hts.ca_htsdescription
		END
	,'ñ','N'),'á','A'),'é','E'),'í','I'),'ó','O'),'ú','U')	AS CA_HTSDescription

	,CASE
			WHEN sti.[StyleNumber] LIKE 'RW505%' AND stc.stylecolorname = '840' THEN '6110200000'
			WHEN sti.[StyleNumber] LIKE 'RW510%' AND stc.stylecolorname = '840' THEN '6104620000'
			WHEN sti.[StyleNumber] LIKE 'RW515%' AND stc.stylecolorname = '840' THEN '6110200000'
			WHEN sti.[StyleNumber] LIKE 'RW520%' AND stc.stylecolorname = '840' THEN '6110200000'
			WHEN sti.[StyleNumber] LIKE 'RW530%' AND stc.stylecolorname = '840' THEN '6110200000'
			ELSE hts.ca_htscode
	 END										AS US_HTSCode

	,CASE
			WHEN sti.[StyleNumber] LIKE 'RW505%' AND stc.stylecolorname = '840' THEN 'WOMEN'+CHAR(39)+'S COTTON SWEATS'
			WHEN sti.[StyleNumber] LIKE 'RW510%' AND stc.stylecolorname = '840' THEN 'WOMEN'+CHAR(39)+'S COTTON PANTS'
			WHEN sti.[StyleNumber] LIKE 'RW515%' AND stc.stylecolorname = '840' THEN 'WOMEN'+CHAR(39)+'S COTTON SWEATS'
			WHEN sti.[StyleNumber] LIKE 'RW520%' AND stc.stylecolorname = '840' THEN 'WOMEN'+CHAR(39)+'S COTTON SWEATS'
			WHEN sti.[StyleNumber] LIKE 'RW530%' AND stc.stylecolorname = '840' THEN 'WOMEN'+CHAR(39)+'S COTTON SWEATS'
			ELSE hts.US_HTSDescription
	 END										AS US_HTSDescription

	,CASE
			WHEN CAST(sc.ShipDate AS DATE) < '2026-02-10' AND AF.Price IS NULL		THEN oi2.unitprice
			WHEN CAST(sc.ShipDate AS DATE) < '2026-02-10' AND AF.Price IS NOT NULL	THEN AF.Price
			WHEN SCPD.id IS NOT NULL													THEN (SCPD.TotalBlank + SCPD.TotalDecoration)
			ELSE oi2.unitprice
	 END										AS UnitPrice

	,CASE
			WHEN CAST(sc.ShipDate AS DATE) < '2026-02-10' AND AF.BasePrice IS NULL		THEN oi2.PricingUnitCost2
			WHEN CAST(sc.ShipDate AS DATE) < '2026-02-10' AND AF.BasePrice IS NOT NULL	THEN AF.BasePrice
			WHEN SCPD.id IS NOT NULL														THEN SCPD.TotalBlank
			WHEN AF.BasePrice IS NOT NULL													THEN AF.BasePrice
			ELSE oi2.PricingUnitCost2
	 END										AS BasePrice

	,sc.ShipDate							AS ShipDate				-- fecha del SHIPPING CONTAINER (definicion actual de Items)
	,sh.shipdate							AS ShipmentShipDate	-- fecha del SHIPMENT (definicion original de Global) -- CONFIRMAR cual se usa como "ShipDate" oficial
	,snpb.StatusName						AS BoxStatusName
	,pb.StatusID							AS BoxStatusID			-- nuevo: antes solo en Global
	,sh.StatusID							AS ShipStatusID			-- nuevo: antes solo en Global
	,wh.WarehouseName						AS BoxWarehouseName
	,pb.WarehouseID							AS BoxWarehouseID		-- nuevo: antes solo en Global
	,st.CostMaterials						AS BlankStyleCostMaterials

	,pbi.packeditemid						AS PackedItemID
	,pbi.finishedgoodsid					AS FinishedGoodsID
	,sti.seasonid							AS SeasonID
	,pbi.packedboxid						AS PackedBoxID
	,pbi.orderdetailsid						AS OrderDetailsID
	,sc.ShippingContainerID					AS ShippingContainerID
	,sh.ShipmentID							AS ShipmentID
	,bxt.DropDownValue						AS BoxTag
	,pb.BoxComments6						AS TrackingNumber

	-- columnas que antes solo vivian en VW_ImpExp_ShipmentBoxGlobal:
	,pb.packedpalletid						AS PackedPalletID
	,pp.palletnumber						AS PalletNumber
	,pp.PalletTypeID						AS PalletTypeID
	,gb.Bin									AS Bin
	,box.BoxUnits							AS BoxUnits				-- antes "Units" en Global; renombrado para no confundir con Quantity (a nivel item)
	,box.BoxType							AS BoxType
	,box.GrossWeight						AS GrossWeight
	,box.NetWeight							AS NetWeight
	,box.BoxWeight							AS BoxWeight
	,box.PalletWeight						AS PalletWeight
	,box.FormattedBoxNumber					AS FormattedBoxNumber
	,box.GrossWeightKGS						AS GrossWeightKGS
	,box.NetWeightKGS						AS NetWeightKGS
	,box.GrossWeightKGS / NULLIF(box.BoxUnits,0)	AS GrossWeightKGSXUnits
	,box.NetWeightKGS / NULLIF(box.BoxUnits,0)		AS NetWeightKGSXUnits

FROM   		(SELECT StatusID,StatusName FROM dbo.statusnames WITH(NOLOCK) WHERE StatusID = 75) AS FSN
	INNER JOIN	dbo.statusnames						AS snpb	WITH(NOLOCK)	ON snpb.StatusID			= FSN.StatusID			AND snpb.StatusID = 75
	INNER JOIN	dbo.packedboxes						AS pb	WITH(NOLOCK)	ON pb.statusid				= snpb.statusid			AND pb.orderid IS NOT NULL
	INNER JOIN	dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid			AND (sh.ShipDate > DATEADD(month,-3,convert(date,getdate())))
	INNER JOIN	dbo.packeditems						AS pbi	WITH(NOLOCK)	ON pbi.packedboxid			= pb.packedboxid		AND pbi.quantity > 0
	INNER JOIN	dbo.finishedgoods					AS fg	WITH(NOLOCK)	ON pbi.finishedgoodsid		= fg.finishedgoodsid
	INNER JOIN	dbo.styles							AS sti	WITH(NOLOCK)	ON fg.styleid				= sti.styleid
	LEFT JOIN	dbo.GoodsBins						AS gb	WITH(NOLOCK)	ON gb.GoodsBinID			= pb.GoodsBinID
	LEFT JOIN	dbo.ManufactureOrders				AS MO	WITH(NOLOCK)	ON MO.ManufactureID			= pbi.ManufactureID
	LEFT JOIN	dbo.htsstylecodes					AS hts	WITH(NOLOCK)	ON sti.htsstylecodeid		= hts.htsstylecodeid
	LEFT JOIN	dbo.stylecolors						AS stc	WITH(NOLOCK)	ON fg.stylecolorid			= stc.stylecolorid
	LEFT JOIN	dbo.orderdetails					AS odd	WITH(NOLOCK)	ON pbi.orderdetailsid		= odd.orderdetailsid
	LEFT JOIN	dbo.orderitems						AS oi2	WITH(NOLOCK)	ON odd.orderitemid			= oi2.orderitemid
	---SE COMENTA PORQUE ESTÁ TOMANDO EL DATO DE ORDER DETAILS Y DEBE SER POR LA MO, RR, DD, JH 20260210
	LEFT JOIN	dbo.orderitems						AS oi	WITH(NOLOCK)	ON oi.OrderItemID			= MO.FirstOrderItemID
	LEFT JOIN	dbo.invoicebatches					AS inb	WITH(NOLOCK)	ON sh.invoicebatchid		= inb.invoicebatchid
	LEFT JOIN	dbo.orders							AS od	WITH(NOLOCK)	ON pb.orderid				= od.orderid
	LEFT JOIN	dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid
	LEFT JOIN	dbo.Warehouses						AS wh	WITH(NOLOCK)	ON wh.WarehouseID			= pb.WarehouseID
	LEFT JOIN	dbo.Styles							AS st	WITH(NOLOCK)	ON st.StyleID				= sti.BlankStyleID
	LEFT JOIN	dbo.ShippingContainers				AS sc	WITH(NOLOCK)	ON sc.ShippingContainerID	= sh.ShippingContainerID
	LEFT JOIN	dbo.DropDownValues3					AS bxt	WITH(NOLOCK)	ON bxt.DropDownValueID		= pb.BoxTagID -- Agregue esta tabla para traer BoxTag Diego Perez 20250605
	LEFT JOIN   dbo.Seasons							AS SEAS WITH(NOLOCK)	ON sti.SeasonID				= SEAS.SeasonID --Tabla agregada 2025 08 22 por Boris Hernandez y Rodrigo Ramirez
	LEFT JOIN	dbo.DropDownValues2					AS ddv2ot with(nolock) on ddv2ot.DropDownValueID = od.OrderTypeID3
	--- se agrega debido cambios en los precios por MO de famosisima --- RR Y DP 2026-02-27
	LEFT JOIN AppsLCA.dbo.TB_ShipmentCheckPricesDetail AS SCPD WITH(NOLOCK) ON oi.OrderItemID			= SCPD.OrderItemID
																			AND pbi.ManufactureID		= SCPD.ManufactureID
																			AND sh.WayBill				= SCPD.Waybill
	LEFT JOIN CTE_ANEXO								AS AF	WITH(NOLOCK)	ON pbi.ManufactureID = AF.ManufactureID
																			AND sh.WayBill = AF.Waybill
	LEFT JOIN BoxAgg									AS box					ON box.PackedBoxID = pb.packedboxid
	--WHERE SH.Waybill = 'APP-MST-20260203' AND OD.PONumber = 'ORD-5159232'


GO


/* ============================================================================
   ANALISIS: VW_ImpExp_ShippingPackingSlip DEPURADA (directo a tablas base)
   ============================================================================
   La vista actual arma el reporte a partir de las dos vistas de arriba
   (SBI = Items, SBG = Global) + AppsLCA.legacycaps.VW_LCA_L2B_InventoryID.
   Revisando columna por columna cual de SBI/SBG realmente sale (o se usa
   en un CASE) en el SELECT final del packing slip, se ve que se usa una
   fraccion minima de ambas vistas:

   DE VW_ImpExp_ShipmentBoxGlobal (SBG) SOLO SE USAN:
       PalletTypeID, Bin, PackedPalletID
     -> Todo el calculo de pesos (GrossWeight, NetWeight, BoxWeight,
        PalletWeight, KGS, FormattedBoxNumber, BoxType, BoxUnits) -osea el
        CTE BoxAgg completo que armamos en el paso anterior- NO SE USA en
        este reporte. No hace falta boxtypes ni PalletTypes aqui.

   DE VW_ImpExp_ShipmentBoxItems_withColor (SBI) NO SE USAN:
     - Todo el bloque de CASE por estilo RW505/RW510/RW515/RW520/RW530
       (HTSStyleCodeID, CA_HTSCode, CA_HTSDescription, US_HTSCode,
       US_HTSDescription). El reporte solo toma "Gender" = el HTS
       ORIGINAL sin override (hts.ca_htsdescription).
     - BasePrice (solo se usa UnitPrice)
     - ContainerNumber, InvoiceBatch completo (solo se usa RIGHT(...,4)),
       PrintCount, StyleCostMaterials, BlankStyleCostMaterials,
       BoxStatusName, BoxWarehouseName, Season
     - PackedItemID/"Barcode": se calcula en el query actual pero nunca
       sale en el SELECT final -> ya esta muerto hoy.

   CON ESO, LA VISTA FINAL YA NO NECESITA PASAR POR LAS DOS VISTAS
   INTERMEDIAS: puede ir directo a las tablas base y ademas se eliminan
   estos joins que solo estaban por las columnas no usadas:
       statusnames (se reemplaza por filtro directo pb.statusid = 75),
       boxtypes, PalletTypes, Warehouses, Styles (blank style), Seasons.

   HALLAZGO A CONFIRMAR: en "Skid" el CASE original tiene dos ramas
   (WHEN ... THEN COALESCE(SBG.Bin,'0') / ELSE COALESCE(SBG.Bin,'0'))
   que devuelven EXACTAMENTE LO MISMO sin importar la condicion. Lo dejo
   simplificado a COALESCE(gb.Bin,'0') directo. Si la condicion alguna vez
   debia diferenciar un caso, avisame porque tal como esta hoy no hace nada.

   SE QUITO CTE_ANEXO (AppsLCA.dbo.ImportExport_AnexoFacturacion): dentro
   del query solo se usaba en 2 ramas del CASE de Price/TotalPrices, ambas
   condicionadas a CAST(sc.ShipDate AS DATE) < '2026-02-10'. Como el filtro
   principal exige sh.ShipDate > DATEADD(month,-3,getdate()) y esa ventana
   es rodante hacia adelante en el tiempo mientras '2026-02-10' es una fecha
   fija en el pasado, esas ramas quedaron inalcanzables de forma permanente
   (hoy 2026-08-12 la ventana ya arranca en 2026-05-12). El CASE se redujo a
   SCPD.id IS NOT NULL / ELSE oi2.unitprice. OJO: si en el futuro se amplia
   el filtro de fecha para incluir shipments anteriores a 2026-02-10, esta
   logica (y el join a CTE_ANEXO) volveria a ser necesaria.

   Se mantiene la relacion con AppsLCA.legacycaps.VW_LCA_L2B_InventoryID
   (L2B_LCA) por estilo/color/talla, igual que en la vista actual.

   Se mantiene la logica de negocio de consolidar lineas (detalle a nivel de
   PackedItemID/Barcode -> una fila por Skid/ItemCode/Box/etc. sumando Qty y
   TotalPrices), pero en un solo nivel: el SELECT final agrupa directo sobre
   "det" y calcula Price = SUM(TotalPrices)/SUM(Qty) ahi mismo, sin la CTE
   "agg" intermedia que se usaba antes solo para poder reusar esos SUM.

   Nada de esto crea la vista todavia; es el borrador del query interno
   para revisar antes de convertirlo en VIEW.
   ============================================================================ */

;WITH det          -- detalle a nivel de ITEM, directo a tablas base (sin pasar por SBG/SBI)
AS
(
	SELECT
		 'Waybill'			= sh.[WayBill]
		,'Skid'				= COALESCE(gb.[Bin],'0')     -- ver hallazgo arriba: el CASE original no cambiaba el resultado
		,'ItemCode'			= CASE
									WHEN L2B_LCA.InvItemNo IS NOT NULL THEN L2B_LCA.InvItemID
									WHEN fg.[garmentsize] = 'XS'  THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'A' + '-' + fg.[garmentsize]
									WHEN fg.[garmentsize] = 'S'   THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'B' + '-' + fg.[garmentsize]
									WHEN fg.[garmentsize] = 'M'   THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'C' + '-' + fg.[garmentsize]
									WHEN fg.[garmentsize] = 'QTY' THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'C-M'
									WHEN fg.[garmentsize] = 'L'   THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'D' + '-' + fg.[garmentsize]
									WHEN fg.[garmentsize] = 'XL'  THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'E' + '-' + fg.[garmentsize]
									WHEN fg.[garmentsize] = '2XL' THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'F' + '-' + fg.[garmentsize]
									WHEN fg.[garmentsize] = '3XL' THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'G' + '-' + fg.[garmentsize]
									WHEN fg.[garmentsize] = '4XL' THEN sti.[stylenumber] + '-' + stc.[stylecolorname] + 'H' + '-' + fg.[garmentsize]
								  END
		,'Style'			= sti.[stylenumber]
		,'Color'			= stc.[StyleColorDescription]
		,'ColorGreatPlain'	= stc.[stylecolorname]
		,'Size'				= CASE WHEN fg.[garmentsize] = 'QTY' THEN 'M' ELSE fg.[garmentsize] END
		,'Qty'				= pbi.[quantity]
		,'XX'				= ''
		,'OrderNo'			= od.[ponumber]
		,'L2Order'			= od.[Comments6]
		,'Box'				= ''
		,'Fact'				= RIGHT(inb.[invoicebatch],4)
		,'Gender'			= hts.[ca_htsdescription]
		,'Location'			= CASE
									WHEN ddv2ot.[DropDownValue] = 'Miami, FL 33182' THEN 'Account'
									WHEN ddv2ot.[DropDownValue] = 'Hanover' AND LEFT(od.[ponumber], 3) = 'ORD' THEN 'Printed to Hanover'
									ELSE ddv2ot.[DropDownValue]
								  END
		,'Note'				= ''
		,'TrackingNumber'	= CASE
									WHEN ddv2ot.[DropDownValue] = 'Miami, FL 33182' THEN pb.[BoxComments6]
									WHEN ddv2ot.[DropDownValue] = 'Hanover' AND LEFT(od.[ponumber], 3) = 'ORD' THEN ''
									ELSE ''
								  END
		,'BoxNo'			= IIF(pp.[PalletTypeID] <> 1 AND pp.[PalletTypeID] IS NOT NULL AND bxt.[DropDownValue] IS NOT NULL
									,CONCAT('PPPA'+LTRIM(STR(pb.[packedpalletid]+1000000)),'-',RIGHT(bxt.[DropDownValue],3))
									,pb.[boxnumber]
								)
		,'ColorPolyPM'		= stc.[stylecolorname]
		,'Price'			= CASE
									WHEN SCPD.[id] IS NOT NULL	THEN (SCPD.[TotalBlank] + SCPD.[TotalDecoration])
									ELSE oi2.[unitprice]
								  END
		,'TotalPrices'		= CAST(pbi.[quantity] AS DECIMAL(10,2)) * CAST((
									CASE
										WHEN SCPD.[id] IS NOT NULL	THEN (SCPD.[TotalBlank] + SCPD.[TotalDecoration])
										ELSE oi2.[unitprice]
									END
								) AS DECIMAL(10,2))
		,'InvoiceDate'		= sc.[ShipDate]
	FROM		dbo.packedboxes						AS pb	WITH(NOLOCK)
	INNER JOIN	dbo.shipments						AS sh	WITH(NOLOCK)	ON pb.shipmentid			= sh.shipmentid		
	INNER JOIN	dbo.ShippingContainers				AS sc	WITH(NOLOCK)	ON sc.ShippingContainerID	= sh.ShippingContainerID AND sc.ShipDate > DATEADD(month,-3,convert(date,getdate()))
	INNER JOIN	dbo.packeditems						AS pbi	WITH(NOLOCK)	ON pbi.packedboxid			= pb.packedboxid	AND pbi.quantity > 0
	INNER JOIN	dbo.finishedgoods					AS fg	WITH(NOLOCK)	ON pbi.finishedgoodsid		= fg.finishedgoodsid
	INNER JOIN	dbo.styles							AS sti	WITH(NOLOCK)	ON fg.styleid				= sti.styleid
	LEFT JOIN	dbo.stylecolors						AS stc	WITH(NOLOCK)	ON fg.stylecolorid			= stc.stylecolorid
	LEFT JOIN	dbo.htsstylecodes					AS hts	WITH(NOLOCK)	ON sti.htsstylecodeid		= hts.htsstylecodeid
	LEFT JOIN	dbo.orders							AS od	WITH(NOLOCK)	ON pb.orderid				= od.orderid
	LEFT JOIN	dbo.invoicebatches					AS inb	WITH(NOLOCK)	ON sh.invoicebatchid		= inb.invoicebatchid
	LEFT JOIN	dbo.goodsbins						AS gb	WITH(NOLOCK)	ON pb.goodsbinid			= gb.goodsbinid
	LEFT JOIN	dbo.packedpallets					AS pp	WITH(NOLOCK)	ON pb.packedpalletid		= pp.packedpalletid
	LEFT JOIN	dbo.DropDownValues3					AS bxt	WITH(NOLOCK)	ON bxt.DropDownValueID		= pb.BoxTagID
	LEFT JOIN	dbo.DropDownValues2					AS ddv2ot WITH(NOLOCK)	ON ddv2ot.DropDownValueID	= od.OrderTypeID3
	LEFT JOIN	dbo.ManufactureOrders				AS MO	WITH(NOLOCK)	ON MO.ManufactureID			= pbi.ManufactureID
	LEFT JOIN	dbo.orderdetails					AS odd	WITH(NOLOCK)	ON pbi.orderdetailsid		= odd.orderdetailsid
	LEFT JOIN	dbo.orderitems						AS oi2	WITH(NOLOCK)	ON odd.orderitemid			= oi2.orderitemid
	LEFT JOIN	dbo.orderitems						AS oi	WITH(NOLOCK)	ON oi.OrderItemID			= MO.FirstOrderItemID
	LEFT JOIN	AppsLCA.dbo.TB_ShipmentCheckPricesDetail AS SCPD WITH(NOLOCK) ON oi.OrderItemID		= SCPD.OrderItemID
																				AND pbi.ManufactureID	= SCPD.ManufactureID
																				AND sh.WayBill			= SCPD.Waybill
	LEFT JOIN	AppsLCA.legacycaps.VW_LCA_L2B_InventoryID AS L2B_LCA WITH(NOLOCK) ON sti.stylenumber	= L2B_LCA.style
																				AND stc.stylecolorname	= L2B_LCA.Color
																				AND fg.garmentsize		= L2B_LCA.SIZE
	WHERE pb.statusid = 75			-- reemplaza el join a statusnames: BoxStatusName no se usa en el reporte
	  AND pb.orderid IS NOT NULL
)
-- consolida lineas iguales (mismo Skid/ItemCode/Box/etc.) sumando Qty y TotalPrices
-- de varios PackedItemID (Barcode) en una sola linea de packing slip; Price
-- sale del promedio ponderado SUM(TotalPrices)/SUM(Qty), calculado en el mismo
-- nivel del GROUP BY (sin necesidad de una segunda CTE para reusar los SUM)
SELECT
	 Waybill, Skid, ItemCode, Style, Color, ColorGreatPlain, Size, XX, OrderNo, L2Order, Box, Fact, Gender, Location, Note, TrackingNumber, BoxNo, ColorPolyPM
	,SUM(Qty)											AS Qty
	,IIF(SUM(Qty) > 0, SUM(TotalPrices) / SUM(Qty), 0)	AS Price
	,SUM(TotalPrices)									AS TotalPrices
	,CONVERT(VARCHAR(10), InvoiceDate, 23)				AS InvoiceDate
FROM det
GROUP BY
	Waybill, Skid, ItemCode, Style, Color, ColorGreatPlain, Size, XX, OrderNo, L2Order, Box, Fact, Gender, Location, Note, TrackingNumber, BoxNo, ColorPolyPM, InvoiceDate
--WHERE Waybill = 'APP-MST-20260203' AND OrderNo = 'ORD-5159232'

GO



