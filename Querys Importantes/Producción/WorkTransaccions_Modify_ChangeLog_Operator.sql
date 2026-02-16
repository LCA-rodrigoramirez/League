                
                USE AppsLCA
                
                
                DECLARE @json NVARCHAR(MAX) = N'[
  {
    "MO": "4752254-849",
    "AddressID": "1297"
  },
  {
    "MO": "EO5083202-866",
    "AddressID": "1297"
  },
  {
    "MO": "EO4956053-DKSEA",
    "AddressID": "1297"
  },
  {
    "MO": "4752151-901",
    "AddressID": "1298"
  },
  {
    "MO": "4752151-901",
    "AddressID": "1298"
  },
  {
    "MO": "EO5061863-DEN",
    "AddressID": "1298"
  },
  {
    "MO": "EO5089183-OAH",
    "AddressID": "1298"
  },
  {
    "MO": "EO5086059-CWHT",
    "AddressID": "1298"
  },
  {
    "MO": "EO4763140-5445",
    "AddressID": "1298"
  },
  {
    "MO": "EO4763140-5445",
    "AddressID": "1298"
  },
  {
    "MO": "EO4763140-5445",
    "AddressID": "1298"
  },
  {
    "MO": "EO4763140-5445",
    "AddressID": "1298"
  },
  {
    "MO": "EO5062833-850",
    "AddressID": "1299"
  },
  {
    "MO": "EO5062833-850",
    "AddressID": "1299"
  },
  {
    "MO": "EO5081643-901",
    "AddressID": "1299"
  },
  {
    "MO": "EO5081654-901",
    "AddressID": "1299"
  },
  {
    "MO": "EO5081643-901",
    "AddressID": "1299"
  },
  {
    "MO": "EO5088127-HGY",
    "AddressID": "1299"
  },
  {
    "MO": "EO5066212-110",
    "AddressID": "1299"
  },
  {
    "MO": "EO5078398-003",
    "AddressID": "1299"
  },
  {
    "MO": "EO5077384-CAR",
    "AddressID": "1299"
  },
  {
    "MO": "EO5077429-809",
    "AddressID": "1299"
  },
  {
    "MO": "EO5059923-507",
    "AddressID": "1299"
  },
  {
    "MO": "EO5087525-906",
    "AddressID": "1299"
  },
  {
    "MO": "EO5091286-809",
    "AddressID": "1299"
  },
  {
    "MO": "EO5071927-906H",
    "AddressID": "1299"
  },
  {
    "MO": "EO5074005-211",
    "AddressID": "1299"
  },
  {
    "MO": "EO4783507-416",
    "AddressID": "1300"
  },
  {
    "MO": "EO4501793-416",
    "AddressID": "1300"
  },
  {
    "MO": "EO5081674-WHT",
    "AddressID": "1300"
  },
  {
    "MO": "EO5081628-CWHT",
    "AddressID": "1300"
  },
  {
    "MO": "EO5060949-408",
    "AddressID": "1300"
  },
  {
    "MO": "EO5078653-640",
    "AddressID": "1300"
  },
  {
    "MO": "EO5085218-640",
    "AddressID": "1300"
  },
  {
    "MO": "EO5051380-837-1",
    "AddressID": "1300"
  },
  {
    "MO": "EO5054745-703",
    "AddressID": "1300"
  },
  {
    "MO": "4686085-003",
    "AddressID": "1301"
  },
  {
    "MO": "4686085-003",
    "AddressID": "1301"
  },
  {
    "MO": "EO5037395-SND-1",
    "AddressID": "1301"
  },
  {
    "MO": "EO4866979-BLK",
    "AddressID": "1301"
  },
  {
    "MO": "EO4866979-BLK",
    "AddressID": "1301"
  },
  {
    "MO": "EO4984616-HSC",
    "AddressID": "1301"
  },
  {
    "MO": "EO5076234-DOR",
    "AddressID": "1301"
  },
  {
    "MO": "EO5089357-600",
    "AddressID": "1301"
  },
  {
    "MO": "EO5089357-600",
    "AddressID": "1301"
  },
  {
    "MO": "EO4883791-EG",
    "AddressID": "1302"
  },
  {
    "MO": "EO5055599-HGY",
    "AddressID": "1302"
  },
  {
    "MO": "EO4923851-4286",
    "AddressID": "1303"
  },
  {
    "MO": "EO4923851-4286",
    "AddressID": "1303"
  },
  {
    "MO": "EO5022544-2746",
    "AddressID": "1303"
  },
  {
    "MO": "EO5022544-2746",
    "AddressID": "1303"
  },
  {
    "MO": "EO5022544-2746",
    "AddressID": "1303"
  },
  {
    "MO": "EO4994791-PHE",
    "AddressID": "1303"
  },
  {
    "MO": "EO4934908-PHE",
    "AddressID": "1303"
  },
  {
    "MO": "EO5089989-HSC",
    "AddressID": "1303"
  },
  {
    "MO": "EO5089194-849",
    "AddressID": "1303"
  },
  {
    "MO": "EO4501793-416",
    "AddressID": "1304"
  },
  {
    "MO": "EO4501793-416",
    "AddressID": "1304"
  },
  {
    "MO": "EO5081651-600",
    "AddressID": "1304"
  },
  {
    "MO": "EO5047482-041",
    "AddressID": "1304"
  },
  {
    "MO": "EO5084319-125",
    "AddressID": "1304"
  },
  {
    "MO": "EO5084136-368",
    "AddressID": "1304"
  },
  {
    "MO": "EO5027740-637",
    "AddressID": "1304"
  },
  {
    "MO": "EO5027740-637",
    "AddressID": "1304"
  },
  {
    "MO": "EO5080712-305",
    "AddressID": "1304"
  },
  {
    "MO": "EO5044506-081",
    "AddressID": "1304"
  },
  {
    "MO": "EO5042974-609-070",
    "AddressID": "1305"
  },
  {
    "MO": "EO5076237-611",
    "AddressID": "1305"
  },
  {
    "MO": "EO5081814-611",
    "AddressID": "1305"
  },
  {
    "MO": "EO5081814-611",
    "AddressID": "1305"
  },
  {
    "MO": "EO5085243-082",
    "AddressID": "1305"
  },
  {
    "MO": "EO5089489-817",
    "AddressID": "1305"
  },
  {
    "MO": "4500723-849",
    "AddressID": "1306"
  },
  {
    "MO": "EO5069378-SCA",
    "AddressID": "1306"
  },
  {
    "MO": "EO4952271-405",
    "AddressID": "1306"
  },
  {
    "MO": "EO5080240-CWHT",
    "AddressID": "1307"
  },
  {
    "MO": "EO5080240-CWHT",
    "AddressID": "1307"
  },
  {
    "MO": "EO5059864-211",
    "AddressID": "1307"
  },
  {
    "MO": "EO5062840-370",
    "AddressID": "1307"
  },
  {
    "MO": "EO5009251-ADOBEC",
    "AddressID": "1307"
  },
  {
    "MO": "EO5089350-PHE",
    "AddressID": "1307"
  },
  {
    "MO": "EO4653259-901S",
    "AddressID": "1307"
  },
  {
    "MO": "EO4954424-703",
    "AddressID": "1307"
  },
  {
    "MO": "EO4954422-429",
    "AddressID": "1307"
  },
  {
    "MO": "EO5064245-404H",
    "AddressID": "1307"
  },
  {
    "MO": "EO4813240-039",
    "AddressID": "1307"
  },
  {
    "MO": "EO4813240-039",
    "AddressID": "1307"
  },
  {
    "MO": "EO5047859-082",
    "AddressID": "1307"
  },
  {
    "MO": "EO5069600-618",
    "AddressID": "1307"
  },
  {
    "MO": "EO5070598-600",
    "AddressID": "1307"
  },
  {
    "MO": "EO5078769-611",
    "AddressID": "1307"
  },
  {
    "MO": "EO5081616-817W",
    "AddressID": "1307"
  },
  {
    "MO": "EO5081616-817W",
    "AddressID": "1307"
  },
  {
    "MO": "EO5081616-817W",
    "AddressID": "1307"
  },
  {
    "MO": "EO5087538-441",
    "AddressID": "1307"
  },
  {
    "MO": "EO5087538-441",
    "AddressID": "1307"
  },
  {
    "MO": "EO5078822-007",
    "AddressID": "1307"
  },
  {
    "MO": "EO5057242-837-1",
    "AddressID": "1307"
  },
  {
    "MO": "EO5057242-837",
    "AddressID": "1307"
  },
  {
    "MO": "EO4941104-3750",
    "AddressID": "1307"
  },
  {
    "MO": "EO4941104-3750",
    "AddressID": "1307"
  },
  {
    "MO": "EO5022138-003",
    "AddressID": "1308"
  },
  {
    "MO": "EO5051867-012",
    "AddressID": "1308"
  },
  {
    "MO": "EO4880032-006",
    "AddressID": "1308"
  },
  {
    "MO": "EO4913882-416",
    "AddressID": "1308"
  },
  {
    "MO": "EO5030068-866",
    "AddressID": "1308"
  },
  {
    "MO": "EO5022766-BLK",
    "AddressID": "1308"
  },
  {
    "MO": "EO4808940-809",
    "AddressID": "1308"
  },
  {
    "MO": "EO4810723-809",
    "AddressID": "1308"
  },
  {
    "MO": "EO4810723-809",
    "AddressID": "1308"
  },
  {
    "MO": "EO4809179-809",
    "AddressID": "1308"
  },
  {
    "MO": "EO5064692-012",
    "AddressID": "1309"
  },
  {
    "MO": "EO5064692-012",
    "AddressID": "1309"
  },
  {
    "MO": "EO5064692-012",
    "AddressID": "1309"
  },
  {
    "MO": "EO5064692-012",
    "AddressID": "1309"
  },
  {
    "MO": "EO5064692-012",
    "AddressID": "1309"
  },
  {
    "MO": "EO4690693-PHE",
    "AddressID": "1309"
  },
  {
    "MO": "EO5044623-NAV",
    "AddressID": "1309"
  },
  {
    "MO": "EO5079656-480",
    "AddressID": "1309"
  },
  {
    "MO": "EO5081793-HGY",
    "AddressID": "1309"
  },
  {
    "MO": "EO5089473-DGR",
    "AddressID": "1309"
  },
  {
    "MO": "EO4689544-488",
    "AddressID": "1309"
  },
  {
    "MO": "EO4689582-809",
    "AddressID": "1309"
  },
  {
    "MO": "EO4809213-809",
    "AddressID": "1309"
  },
  {
    "MO": "EO5062845-HWTROH",
    "AddressID": "1309"
  },
  {
    "MO": "EO5067147-450",
    "AddressID": "1309"
  },
  {
    "MO": "EO5079341-143",
    "AddressID": "1311"
  },
  {
    "MO": "EO5028249-450",
    "AddressID": "1311"
  },
  {
    "MO": "EO5080697-485",
    "AddressID": "1311"
  },
  {
    "MO": "EO5088845-630",
    "AddressID": "1311"
  },
  {
    "MO": "EO5061728-404H",
    "AddressID": "1311"
  },
  {
    "MO": "EO5029059-BLK",
    "AddressID": "1312"
  },
  {
    "MO": "EO5051865-872",
    "AddressID": "1312"
  },
  {
    "MO": "EO5050003-471",
    "AddressID": "1312"
  },
  {
    "MO": "EO5051868-370",
    "AddressID": "1312"
  },
  {
    "MO": "EO5043963-450",
    "AddressID": "1312"
  },
  {
    "MO": "EO5038748-809",
    "AddressID": "1312"
  },
  {
    "MO": "EO5060139-817",
    "AddressID": "1312"
  },
  {
    "MO": "EO5031464-BLK",
    "AddressID": "1312"
  },
  {
    "MO": "EO5074741-600",
    "AddressID": "1312"
  },
  {
    "MO": "EO5074741-600",
    "AddressID": "1312"
  },
  {
    "MO": "EO4792362-ROY",
    "AddressID": "3186"
  },
  {
    "MO": "EO5067463-BKH",
    "AddressID": "3186"
  },
  {
    "MO": "EO5063193-809",
    "AddressID": "3186"
  },
  {
    "MO": "EO5063193-809",
    "AddressID": "3186"
  },
  {
    "MO": "EO5063193-809",
    "AddressID": "3186"
  },
  {
    "MO": "EO5063193-809",
    "AddressID": "3186"
  },
  {
    "MO": "EO5063193-809",
    "AddressID": "3186"
  },
  {
    "MO": "EO5063193-809",
    "AddressID": "3186"
  },
  {
    "MO": "EO5070578-611",
    "AddressID": "3186"
  },
  {
    "MO": "EO5070578-611",
    "AddressID": "3186"
  },
  {
    "MO": "EO4696184-BLK",
    "AddressID": "36907"
  },
  {
    "MO": "EO5045425-PHE",
    "AddressID": "36907"
  },
  {
    "MO": "EO4675415-PHE",
    "AddressID": "36909"
  },
  {
    "MO": "EO4937582-BLFGH",
    "AddressID": "36909"
  },
  {
    "MO": "EO5005555-503",
    "AddressID": "36912"
  },
  {
    "MO": "EO5005555-503",
    "AddressID": "36912"
  },
  {
    "MO": "EO5005470-837",
    "AddressID": "36912"
  },
  {
    "MO": "EO5069158-069",
    "AddressID": "36912"
  },
  {
    "MO": "EO4517412-837",
    "AddressID": "36913"
  },
  {
    "MO": "EO5066408-003",
    "AddressID": "36913"
  },
  {
    "MO": "EO5077294-306",
    "AddressID": "36913"
  },
  {
    "MO": "EO5077294-306",
    "AddressID": "36913"
  },
  {
    "MO": "EO5065592-416",
    "AddressID": "36913"
  },
  {
    "MO": "EO5065592-416",
    "AddressID": "36913"
  },
  {
    "MO": "EO5065592-416",
    "AddressID": "36913"
  },
  {
    "MO": "EO5005507-801",
    "AddressID": "36914"
  },
  {
    "MO": "EO4961941-416",
    "AddressID": "36914"
  },
  {
    "MO": "EO4933685-615",
    "AddressID": "36914"
  },
  {
    "MO": "EO4933685-615",
    "AddressID": "36914"
  },
  {
    "MO": "EO4933685-615",
    "AddressID": "36914"
  },
  {
    "MO": "EO4981787-416",
    "AddressID": "36915"
  },
  {
    "MO": "EO5034488-416S",
    "AddressID": "36915"
  },
  {
    "MO": "EO4948988-906",
    "AddressID": "36915"
  }
]'
                                
                                -- Crear tabla temporal (usando la forma moderna)
                                DROP TABLE IF EXISTS #TB_DATOS_MOS_OPERATOS;
                                
                                CREATE TABLE #TB_DATOS_MOS_OPERATOS
                                (
                                     [MO]        VARCHAR(100)
                                    ,[AddressID] INT
                                )
                                
                                -- Insertar datos desde JSON
                                INSERT INTO #TB_DATOS_MOS_OPERATOS (MO, AddressID)
                                SELECT 
                                    j.MO,
                                    j.AddressID
                                FROM OPENJSON(@json)
                                WITH (
                                    MO NVARCHAR(100) '$.MO',
                                    AddressID INT '$.AddressID'
                                ) j
                                
                                -- Verificar los datos
                                -- SELECT * FROM #TB_DATOS_MOS_OPERATOS;


                DROP TABLE IF EXISTS #TB_TRANS_BUNDLES_LIST
                CREATE TABLE #TB_TRANS_BUNDLES_LIST (BundleID INT,AddressID INT)
                
                
                 INSERT INTO #TB_TRANS_BUNDLES_LIST (BundleID,AddressID)
                 (
                    SELECT 
                        B.BundleID 
                        ,FMO.AddressID
                    FROM        LCA.dbo.ManufactureOrders   AS M WITH(NOLOCK)
                    LEFT JOIN   LCA.dbo.Bundles             AS B WITH(NOLOCK) ON B.ManufactureID = M.ManufactureID
                    INNER JOIN  #TB_DATOS_MOS_OPERATOS      AS FMO ON FMO.MO = M.ManufactureNumber
                 )
                 
                 DECLARE @TaskSearch AS VARCHAR(200) = 'Received in Packing'
                 
                
            
                DROP TABLE IF EXISTS #TB_Transactions_Bundles_List
                SELECT 
                     [R]                   = ROW_NUMBER() OVER (ORDER BY MO.ManufactureID, b.BundleNumber, ChLog.ChangeDate ASC)
                    ,[ManufactureID]       = b.ManufactureID
                    ,[MO]                  = mo.ManufactureNumber
                    ,[Make]                = mo.QuantityOrdered
                    ,[BundleID]            = b.BundleID
                    ,[BundleNumber]        = b.BundleNumber
                    ,[PPBU]                = 'PPBU' + LTRIM(STR(b.BundleID + 10000000))
                    ,[StyleID]             = s.StyleID
                    ,[Style]               = s.StyleNumber
                    ,[StyleColorID]        = sc.StyleColorID
                    ,[Color]               = sc.StyleColorName
                    ,[SeasonID]            = sns.SeasonID
                    ,[Size]                = fg.GarmentSize
                    ,[Quantity]            = CAST(wt.Quantity AS INT)
                    ,[TaskID]              = wt.TaskID
                    ,[TaskName]            = t.TaskName
                    ,[PPAD]                = 'PPAD' + LTRIM(STR(opr.[AddressID] + 10000))
                    ,[Operator]            = opr.CompanyNumber
                    ,[OperatorName]        = opr.CompanyName
                    ,[ChangeLogID]         = CHLog.ChangeLogID
                    ,[ChangeDate]          = CHLog.ChangeDate
                    ,[OrderID]             = ORD.OrderID
                    ,[PONumber]            = ORD.PONumber
                    ,[UserName]            = US.UserName
                    ,[UserDepartment]      = US.Comment
                    ,[WorkTransactionID]   = wt.WorkTransactionID
                    ,[TransactionComment]  = CHLog.Comment
                    ,[DamageID]            = wt.DamageID
                    ,[DamageQuantity]      = DMG.Quantity
                    ,[NEW_OperatorID]      = BNDF.AddressID
                INTO #TB_Transactions_Bundles_List
                FROM            #TB_TRANS_BUNDLES_LIST          AS BNDF  
                    INNER JOIN  LCA.dbo.[Bundles]               AS B     WITH(NOLOCK) ON B.BundleID             = BNDF.BundleID
                    INNER JOIN  LCA.dbo.[ManufactureOrders]     AS mo    WITH(NOLOCK) ON B.ManufactureID        = mo.ManufactureID
                    INNER JOIN  LCA.dbo.[ManufactureDetails]    AS md    WITH(NOLOCK) ON b.ManufactureDetailID  = md.ManufactureDetailID
                    INNER JOIN  LCA.dbo.[FinishedGoods]         AS fg    WITH(NOLOCK) ON md.FinishedGoodsID     = fg.FinishedGoodsID
                    INNER JOIN  LCA.dbo.[Styles]                AS s     WITH(NOLOCK) ON fg.StyleID             = s.StyleID
                    INNER JOIN  LCA.dbo.[StyleColors]           AS sc    WITH(NOLOCK) ON fg.StyleColorID        = sc.StyleColorID
                    LEFT JOIN   LCA.dbo.[Seasons]               AS SNS   WITH(NOLOCK) ON SNS.SeasonID           = s.SeasonID
                    INNER JOIN  LCA.dbo.[WorkTransactions]      AS wt    WITH(NOLOCK) ON b.BundleID             = wt.BundleID
                    INNER JOIN  LCA.dbo.[WorkTasks]             AS t     WITH(NOLOCK) ON wt.TaskID              = t.TaskID              AND T.TaskName = @TaskSearch
                    INNER JOIN   LCA.dbo.[ChangeLog]             AS CHLog WITH(NOLOCK) ON wt.ChangeLogID         = CHLog.ChangeLogID
                    LEFT JOIN   LCA.dbo.[OrderItems]            AS ORDit WITH(NOLOCK) ON mo.FirstOrderItemID    = ORDit.OrderItemID
                    LEFT JOIN   LCA.dbo.[Orders]                AS ORD   WITH(NOLOCK) ON ORDit.OrderID          = ORD.OrderID
                    LEFT JOIN   LCA.dbo.[Users]                 AS US    WITH(NOLOCK) ON CHLog.UserID           = US.UserID
                    LEFT JOIN   LCA.dbo.[Addresses]             AS opr   WITH(NOLOCK) ON wt.OperatorID          = opr.AddressID
                    INNER JOIN   LCA.dbo.[Damages]               AS DMG   WITH(NOLOCK) ON DMG.DamageID           = WT.DamageID
                   
			        
                
                    -- -- select * ,
                    -- UPDATE DMG SET 
                    --     [OperatorID] = tb.NEW_OperatorID
                    -- from                 
                    -- (SELECT DISTINCT DamageID,NEW_OperatorID FROM #TB_Transactions_Bundles_List) as tb
                    -- INNER JOIN   LCA.dbo.[Damages]               AS DMG   WITH(NOLOCK) ON DMG.DamageID           = tb.DamageID
                
                    
                    -- -- select * ,
                    -- UPDATE wt SET 
                    --     [OperatorID] = tb.NEW_OperatorID
                    -- from                 
                    -- (SELECT DISTINCT WorkTransactionID,NEW_OperatorID FROM #TB_Transactions_Bundles_List) as tb
                    -- INNER JOIN  LCA.dbo.[WorkTransactions]      AS wt    WITH(NOLOCK) ON tb.WorkTransactionID             = wt.WorkTransactionID

    -- select * from
    --    (SELECT DISTINCT WorkTransactionID,NEW_OperatorID FROM #TB_Transactions_Bundles_List) as tb
    --              INNER JOIN  LCA.dbo.[ChangeLog]      AS ch    WITH(NOLOCK) ON ch.ChangeLogID             = tb.ChangeLogID

                
                SELECT * FROM #TB_Transactions_Bundles_List
                
                
                
                -- SELECT * FROM LCA.DBO._ColumnSpecs$ WHERE FinalColumn = 'DamageQuantity' ORDER BY TableName
                
                --  SELECT 
                --     CompanyNumber
                --     ,CompanyName
                --     ,AddressID
                --     ,ProductionTaskName
                --  FROM LCA.dbo.[Addresses] 
                --  WHERE 
                --     (    ProductionTaskName = 'QC Embroidery'
                --     and (CompanyName like '%50%' OR CompanyName like '%51%' ))
                    
                --     OR
                --     (    ProductionTaskName IS NULL
                --         and 
                --     (CompanyName like 'Press%' ))
                -- order by CompanyName
                