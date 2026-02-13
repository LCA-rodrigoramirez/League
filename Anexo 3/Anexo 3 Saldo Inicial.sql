
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
                 select distinct

                              ISNULL(ddv.DropDownValue,ct.SAC) as ddv
                              ,ddv2.DropDownValue as ddv2
                              ,ISNULL(ddv.Description,ct.[Technical Desc.]) as ddvdes
                              ,ddv2.Description as ddv2des
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
                                , CT.[Part Number] ,'INCIAL' as [Type]
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
    Fecha = '2024-12-31'  --SALDO INICIAL
  --AND DDV.DropDownValueID IS NULL 
  -- and ct.Warehouse not in ('CMT Warehouse','Obsolete (liquidate)' ,'Quarentine')
  and ct.category<>'Expandable'
  and ct.category<>'Expendable'
  and ct.category<>'Contracts'
  --and  ddv.DropDownValue = '5607909000'
  --and SAC = '3506100000'
  
  group by  CT.[Part Number],ddv.DropDownValue ,ct.Units,ddv.Description,ct.Category,left (ct.SAC + '0000000000', 10) ,ddv2.DropDownValue,ddv2.Description,ct.[Technical Desc.],ct.SAC
--   ) as tb
)TB
WHERE ddvdes <> 'NO APLICA'
GROUP BY ddv,ddv2,ddvdes,ddv2des,Category,Units
order by ddvdes

-- --where tb.ddv = '7319401000'

--   group by isnull( tb.ddv , tb.ddv2) 
--                               --,Category
--                               ,Units
--                               ,isnull( tb.ddvdes , tb.ddv2des)
  
--   order by isnull( tb.ddv , tb.ddv2) 
                               
