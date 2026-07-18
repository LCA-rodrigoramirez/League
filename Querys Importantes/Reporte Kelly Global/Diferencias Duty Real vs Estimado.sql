SELECT ci.DocumentID, iwt.waybill, iwt.TariffCategory,
                       SUM(ci.Quantity)                                          AS ci_qty,
                       SUM(ci.TotalFobValue)                                     AS ci_fob,
                       SUM(ci.TotalDecorationValue)                              AS ci_deco,
                       SUM(ci.TotalExport)                                       AS ci_entry_inv,
                       (select sum(el.duty) as Duty_Entry
                       ,RIGHT(
                                ei.invoice_code,
                                LEN(ei.invoice_code) - CHARINDEX('/', ei.invoice_code)
                                ) as invoice
                        ,el.htsus
                        from AppsLCA.dbo.entry_lines as el with(nolock)
                        inner join AppsLCA.dbo.entry_invoices as ei with(nolock)
                            ON el.invoice_id = ei.id
                        inner join AppsLCA.dbo.entry_documents as ed with(nolock)
                            ON ei.document_id = ed.id

                        group by
                            RIGHT(
                                ei.invoice_code,
                                LEN(ei.invoice_code) - CHARINDEX('/', ei.invoice_code)
                                )
                            ,el.htsus
                        where   RIGHT(
                                ei.invoice_code,
                                LEN(ei.invoice_code) - CHARINDEX('/', ei.invoice_code)
                                ) = ci.DocumentID
                                and el.htsus is not null)                        AS Duty_Entry,
                       SUM(iwt.quantity)                                         AS vw_qty,
                       SUM((iwt.Unit_Invoiced_Price - ci.Freight)*iwt.quantity)  AS vw_fob,
                       SUM(iwt.Decoration_invoiced_Price * iwt.quantity)         AS vw_deco,
                       SUM(iwt.Unit_Invoiced_Price * iwt.quantity)               AS vw_unit,
                       SUM(iwt.TotalTariff)                                      AS Total_Tariff_L2
                FROM [AppsLCA].[legacycaps].[TB_L2Brands_Units_Invoiced_WithTariffs] AS iwt WITH(NOLOCK)
                INNER JOIN [192.168.1.93].AppsLCA.dbo.ci_Import_Export_CommercialInvoice AS ci WITH(NOLOCK)
                    ON iwt.IDExport = ci.IDExport AND iwt.Waybill = 'BND-20260519'
                GROUP BY ci.DocumentID, iwt.waybill, iwt.TariffCategory

SELECT ci.DocumentID, iwt.waybill, iwt.TariffCategory,
                       SUM(ci.Quantity)                                          AS ci_qty,
                       SUM(ci.TotalFobValue)                                     AS ci_fob,
                       SUM(ci.TotalDecorationValue)                              AS ci_deco,
                       SUM(ci.TotalExport)                                       AS ci_entry_inv,
                       (select sum(el.duty) as Duty_Entry
                        from AppsLCA.dbo.entry_lines as el with(nolock)
                        inner join AppsLCA.dbo.entry_invoices as ei with(nolock)
                            ON el.invoice_id = ei.id
                        inner join AppsLCA.dbo.entry_documents as ed with(nolock)
                            ON ei.document_id = ed.id
                        where   RIGHT(
                                ei.invoice_code,
                                LEN(ei.invoice_code) - CHARINDEX('/', ei.invoice_code)
                                ) = ci.DocumentID
                                and el.htsus is not null)                        AS Duty_Entry, 
                       SUM(iwt.quantity)                                         AS vw_qty,
                       SUM((iwt.Unit_Invoiced_Price - ci.Freight)*iwt.quantity)  AS vw_fob,
                       SUM(iwt.Decoration_invoiced_Price * iwt.quantity)         AS vw_deco,
                       SUM(iwt.Unit_Invoiced_Price * iwt.quantity)               AS vw_unit,
                       SUM(iwt.TotalTariff)                                      AS Total_Tariff_L2
                FROM [AppsLCA].[legacycaps].[TB_L2Brands_Units_Invoiced_WithTariffs] AS iwt WITH(NOLOCK)
                INNER JOIN [192.168.1.93].AppsLCA.dbo.ci_Import_Export_DeclarationExport AS ci WITH(NOLOCK)
                    ON iwt.IDExport = ci.IDExport AND iwt.Waybill = 'BND-20260519'
                GROUP BY ci.DocumentID, iwt.waybill, iwt.TariffCategory

SELECT *,[Decoration_Invoiced_Price] * Quantity FROM [AppsLCA].[legacycaps].[TB_L2Brands_Units_Invoiced_WithTariffs] AS iwt WITH(NOLOCK) WHERE Waybill = 'BND-20260519'
SELECT
*
from AppsLCA.dbo.entry_lines as el with(nolock) WHERE invoice_id IN (147) AND htsus IS NOT NULL

select * from AppsLCA.dbo.entry_invoices as ei with(nolock) WHERE ID IN (287)
select * from AppsLCA.dbo.entry_invoices as ei with(nolock) WHERE invoice_code LIKE '%APP-20260608%'

select * from AppsLCA.dbo.entry_documents as ed with(nolock) where id = 28
