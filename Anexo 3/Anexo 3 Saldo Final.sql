
use LCA

                --  select 
                --               isnull( tb.ddvdes , tb.ddv2des) as [desc]
                --               ,isnull( tb.ddv , tb.ddv2) as ddv
                --               --,Category
                --               ,Units
                              
                --               ,SUM(OH) as OH
                --               ,sum (round(cost,2))  as cost
                --  from (
SELECT  ddv,ddvdes,Units,SUM(OH) as OnHand,SUM(Cost) as Cost
FROM(
                 select 

                              ISNULL(ddv.DropDownValue,ddv2.DropDownValue) as ddv
                              --as ddv2
                              ,ISNULL(ddv.Description,ddv2.Description) as ddvdes
                              -- as ddv2des
                              ,left (ct.SAC + '0000000000', 10) as SAC 
                               ,ct.Category
                              ,ct.Units
                              -- ,sum ( case 
                              --   when  CT.Warehouse = 'Obsolete (liquidate)' or 
                              --         CT.Warehouse = 'Picacho. SemiConfeccionado' or
                              --         CT.Warehouse = 'Write-off' or
                              --         CT.Warehouse = 'Bodega Maquinaria, Repuestos y Suministros'
                              --         then 0 * ct.[On Hand]
                              --         else
                              -- ct.[Container Unit Cost] * ct.[On Hand] end) as cost

                              ,sum (ct.[Container Unit Cost] * ct.[On Hand]) as cost
                              ,sum (ct.[On Hand]) as OH
                                , CT.[Part Number] ,'FINAL' as [Type]
								,ct.Code
  FROM (SELECT DISTINCT
      [Code]
      ,[Category]
      ,[Subcategory]
      ,[Family]
      ,[Inv Accounting]
      ,[Part Number]
      ,[Part Color]
      ,[Status]
      ,[Roll]
      ,[PO Number]
      ,[Description]
      ,[Fabric Width]
      ,[On Hand]
      ,[Units]
      ,[Bin]
      ,[Warehouse]
      ,[Dye Lot]
      ,[Vendor Name]
      ,[IM5/IM9]
      ,[SAC]
      ,[Technical Desc.]
      ,[Invoice Number]
      ,[Unit Symbol]
      ,[Average Material Cost]
      ,[Container Unit Cost]
      ,[Unit Freight Cost]
      ,[Total]
      ,[Total With Freight]
      ,[Deadline]
      ,[Month]
      ,[Counting]
      ,[Fam]
      ,[Acou]
      ,[Fecha]
  FROM [AppsLCA].[dbo].[CostoWarehouse])ct
               left outer join dbo.RawMaterials on RawMaterials.PartNumber = ct.[Part Number]
   LEFT OUTER JOIN [dbo].DropDownValues ddv ON RawMaterials.HTSCodeID = ddv.DropDownValueID
   left outer join DropDownValues ddv2 on ddv2.DropDownValue = left (ct.SAC + '0000000000', 10) and ddv.DropDownValue is null 
  
  
-- CMT Warehouse
-- Picacho. SemiConfeccionado 
-- Write-off
-- Bodega Maquinaria, Repuestos y Suministros


  where 
    Fecha = '2025-06-30'  --SALDO INICIAL
  --AND DDV.DropDownValueID IS NULL 
  -- and ct.Warehouse not in ('CMT Warehouse','Obsolete (liquidate)' ,'Quarentine')
  and ct.category<>'Expandable'
  and ct.category<>'Expendable'
  and ct.category<>'Contracts'
 -- AND ddv.Description = 'NO APLICA'
  --and ddv.DropDownValue = '3923219000'
  --and  ddv.DropDownValue = '5607909000'
  
  group by  ct.Code,CT.[Part Number],ddv.DropDownValue ,ct.Units,ddv.Description,ct.Category,left (ct.SAC + '0000000000', 10) ,ddv2.DropDownValue,ddv2.Description
--   ) as tb

-- --where tb.ddv = '7319401000'

--   group by isnull( tb.ddv , tb.ddv2) 
--                               --,Category
--                               ,Units
--                               ,isnull( tb.ddvdes , tb.ddv2des)
  
--   order by isnull( tb.ddv , tb.ddv2) 
                               
)TB
WHERE ddvdes <> 'NO APLICA'
--AND ddv = '6310909000'
GROUP BY ddv,ddvdes,Units
order by ddvdes