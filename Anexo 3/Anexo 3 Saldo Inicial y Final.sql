
use LCA


SELECT  
   ddvdes
  ,Units
  ,ddv
  ,SUM(OH) as SaldoIncial_Units
  ,SUM(Cost) as SaldoInicial_Total
FROM(
                 select 

                              ddv.DropDownValue as ddv
                              ,ddv2.DropDownValue as ddv2
                              ,ddv.Description as ddvdes
                              ,ddv2.Description as ddv2des
                              ,left (ct.SAC + '0000000000', 10) as SAC 
                               ,ct.Category
                              ,ct.Units
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
               left outer join Financial.dbo.RawMaterials on RawMaterials.PartNumber = ct.[Part Number]
   LEFT OUTER JOIN Financial.dbo.DropDownValues ddv ON RawMaterials.HTSCodeID = ddv.DropDownValueID
   left outer join Financial.dbo.DropDownValues ddv2 on ddv2.DropDownValue = left (ct.SAC + '0000000000', 10) and ddv.DropDownValue is null 

  where 
    -- Fecha = '2025-03-31'  --SALDO INICIAL
    Fecha = '2025-06-30'  --SALDO FINAL

    and ct.category<>'Expandable'
    and ct.category<>'Expendable'
  group by  CT.[Part Number],ddv.DropDownValue ,ct.Units,ddv.Description,ct.Category,left (ct.SAC + '0000000000', 10) ,ddv2.DropDownValue,ddv2.Description
                   
)TB
WHERE Category <> 'Expendable'
AND Category <> 'Contracts'
AND ddv <> 'N/A'
GROUP BY ddv,ddv2,ddvdes,ddv2des,Category,Units