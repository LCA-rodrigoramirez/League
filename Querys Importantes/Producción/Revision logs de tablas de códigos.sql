SELECT
*
FROM AppsLCA.legacycaps.VW_view_LCA_Applique_Logs
WHERE ItemDetailID IN (
5583143
--5632984 --no se actualizo
--5610078 --no se actualizo
--5450548
--5561744
--5338804
)
ORDER BY InsertDate DESC

SELECT
*
FROM AppsLCA.dbo.InfoOrdersToPolyPM_Emb_Apparel_Logs
WHERE ItemDetailID IN (
5583143
--5632984 -- no se actualizo
--5610078 -- no se actualizo
--5450548
--5561744
--5338804
)

ORDER BY InsertDate DESC