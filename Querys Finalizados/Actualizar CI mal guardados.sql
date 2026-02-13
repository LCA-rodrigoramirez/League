DROP TABLE IF EXISTS #TB_NEW_CI

CREATE TABLE #TB_NEW_CI
(   
     Waybill               VARCHAR(MAX)          
    ,ContainerNumber       VARCHAR(MAX)          
    ,StyleNumber           VARCHAR(MAX)      
    ,InvoicingDescription  VARCHAR(MAX)                  
    ,US_HTSDescription     VARCHAR(MAX)              
    ,CA_HTSCode            VARCHAR(MAX)      
    ,UnitPrice             DECIMAL(18,2)
    ,ShipDate              DATE     
    ,Quantity              INT
    ,TotalPrice            DECIMAL(18,2)
    ,MinBatch              VARCHAR(MAX)      
    ,WeightKg              DECIMAL(18,2)
    ,MaxBatch              VARCHAR(MAX)      
    ,Cafta                 VARCHAR(MAX)  
    ,Pallets               INT
    ,Boxes                 INT
    ,Manufactured          VARCHAR(MAX)          
    ,CountryOfOrigin       VARCHAR(MAX)          
    ,Freight               DECIMAL(18,2)
    ,Orden                 INT  
)

DROP TABLE IF EXISTS #TB_NEW_DECLARATION

CREATE TABLE #TB_NEW_DECLARATION
(   
     WayBill               VARCHAR(MAX)     
    ,ContainerNumber       VARCHAR(MAX)             
    ,StyleNumber           VARCHAR(MAX)         
    ,InvoicingDescription  VARCHAR(MAX)                 
    ,US_HTSDescription     VARCHAR(MAX)             
    ,CA_HTSCode            VARCHAR(MAX)     
    ,UnitPrice             DECIMAL(18,2)
    ,ShipDate              DATE
    ,Quantity              INT
    ,TotalPrice            DECIMAL(18,2)    
    ,MinBatch              VARCHAR(MAX)     
    ,WeightKg              DECIMAL(18,2)
    ,MaxBatch              VARCHAR(MAX)     
    ,Cafta                 VARCHAR(MAX) 
    ,Pallets               INT
    ,Boxes                 INT
    ,Manufactured          VARCHAR(MAX)         
    ,CountryOfOrigin       VARCHAR(MAX)             
    ,IM5                   VARCHAR(MAX) 
    ,DeclarationDate       DATE
    ,ArrivalDate           DATE
    ,DepartureDate         DATE
    ,PortOfLoading         VARCHAR(MAX)         
    ,DecorationDesc        VARCHAR(MAX)         
    ,DecorationValue       DECIMAL(18,2)
    ,Orden                 INT
)

INSERT INTO #TB_NEW_CI
(
     Waybill
    ,ContainerNumber      
    ,StyleNumber         
    ,InvoicingDescription
    ,US_HTSDescription   
    ,CA_HTSCode          
    ,UnitPrice           
    ,ShipDate            
    ,Quantity            
    ,TotalPrice          
    ,MinBatch            
    ,WeightKg            
    ,MaxBatch            
    ,Cafta               
    ,Pallets             
    ,Boxes               
    ,Manufactured        
    ,CountryOfOrigin     
    ,Freight             
    ,Orden               
)
VALUES
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'ESYZ230',	'Boy''s Sweatshirt 60% COTTON/ 40% POLYESTER',	'BOYS COTTON SWEATSHIRT',	'6110202044',	'10.93',	'	2025-08-27	',	'6',	'65.58',	'7582',	'2.24',	'7582',	'N',	'0',	'3',	'INNO',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'10PDT',	'Men''s Long Sleeve T-shirt 100% Cotton100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'7.31',	'	2025-08-27	',	'47',	'343.57',	'7582',	'13.25',	'7582',	'N',	'0',	'3',	'JWIN FASHIONS',	'India',	'0.25',	'2'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'10PDT',	'Men''s Long Sleeve T-shirt 100% Cotton100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'6.36',	'	2025-08-27	',	'48',	'305.28',	'7582',	'13.9',	'7582',	'N',	'0',	'3',	'JWIN FASHIONS',	'India',	'0.25',	'2'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'33032',	'Men''s Pants 52% COTTON 48% POLYESTER',	'MEN''S COTTON PANTS',	'6103421020',	'9.91',	'	2025-08-27	',	'41',	'406.31',	'7582',	'22.06',	'7582',	'N',	'0',	'3',	'Metrotex Industries',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'05PDT',	'Men''s Long Sleeve T-shirt 100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'6.98',	'	2025-08-27	',	'254',	'1772.92',	'7582',	'57.25',	'7582',	'N',	'0',	'3',	'JWIN FASHIONS',	'India',	'0.25',	'2'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'05PDT',	'Men''s Long Sleeve T-shirt 100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'6.03',	'	2025-08-27	',	'48',	'289.44',	'7582',	'10.85',	'7582',	'N',	'0',	'3',	'JWIN FASHIONS',	'India',	'0.25',	'2'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'20058',	'Men''s Short Sleeve T-shirt 60% Cotton 40% Polyester',	'MEN''S COTTON SWEATSHIRT',	'6109100012',	'6.05',	'	2025-08-27	',	'7',	'42.35',	'7582',	'1.29',	'7582',	'N',	'1',	'3',	'Fruit of the Loom  (SV)',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'30008',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATSHIRT',	'6110202041',	'10.21',	'	2025-08-27	',	'24',	'245.04',	'7582',	'10.5',	'7582',	'N',	'0',	'3',	'Metrotex Industries',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'30008',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATSHIRT',	'6110202041',	'9.46',	'	2025-08-27	',	'27',	'255.42',	'7582',	'16.2',	'7582',	'N',	'0',	'3',	'INNO',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'31014',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATSHIRT',	'6110202041',	'12.2',	'	2025-08-27	',	'55',	'671',	'7582',	'38.25',	'7582',	'N',	'0',	'3',	'INNO',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'31014',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATSHIRT',	'6110202041',	'11.79',	'	2025-08-27	',	'52',	'613.08',	'7582',	'33.55',	'7582',	'N',	'0',	'2',	'INNO',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'31014',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATSHIRT',	'6110202041',	'11.26',	'	2025-08-27	',	'24',	'270.24',	'7582',	'15.45',	'7582',	'N',	'0',	'1',	'INNO',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'31014',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATSHIRT',	'6110202041',	'10.94',	'	2025-08-27	',	'48',	'525.12',	'7582',	'31.05',	'7582',	'N',	'0',	'1',	'INNO',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'ESYS235',	'Boy''s Pant''s 60% COTTON/ 40% POLYESTER ',	'BOY''S COTTON PANTS',	'6103420000',	'8.05',	'	2025-08-27	',	'24',	'193.2',	'7694',	'7.05',	'7694',	'N',	'0',	'1',	'INNO',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'ESYS235',	'Boy''s Pant''s 65% COTTON / 35% POLYESTER',	'BOY''S COTTON PANTS',	'6103420000',	'7.36',	'	2025-08-27	',	'24',	'176.64',	'7694',	'7.2',	'7694',	'N',	'0',	'1',	'Metrotex Industries',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'ESYC200',	'Boy''s Sweatshirt 60% COTTON/ 40% POLYESTER',	'BOYS COTTON SWEATS',	'6110202044',	'8.63',	'	2025-08-27	',	'14',	'120.82',	'7694',	'4.03',	'7694',	'N',	'0',	'0',	'Metrotex Industries',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'ESYH210',	'Boy''s Sweatshirt 65% COTTON / 35% POLYESTER',	'BOYS COTTON SWEATS',	'6110202044',	'8.7',	'	2025-08-27	',	'18',	'156.6',	'7694',	'6.34',	'7694',	'N',	'0',	'0',	'INNO',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'ESYH210',	'Boy''s Sweatshirt 65% COTTON / 35% POLYESTER',	'BOYS COTTON SWEATS',	'6110202044',	'9.04',	'	2025-08-27	',	'10',	'90.4',	'7694',	'3',	'7694',	'N',	'0',	'0',	'Metrotex Industries',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'31018',	'Men''s Hood 100% Polyester',	'MEN''S SYNTHETIC SWEATS',	'6110303041',	'14.09',	'	2025-08-27	',	'8',	'112.72',	'7694',	'4.65',	'7694',	'N',	'0',	'1',	'Eastwood VN',	'Vietnam',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'10PDT',	'Men''s Long Sleeve T-shirt 100% Cotton100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.73',	'	2025-08-27	',	'24',	'137.52',	'7694',	'7.2',	'7694',	'N',	'0',	'1',	'JWIN FASHIONS',	'India',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'10PDT',	'Men''s Long Sleeve T-shirt 100% Cotton100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.79',	'	2025-08-27	',	'24',	'138.96',	'7694',	'7.1',	'7694',	'N',	'0',	'1',	'JWIN FASHIONS',	'India',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'110WF',	'Mens Pants 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'MEN''S COTTON PANTS',	'6103421020',	'8.29',	'	2025-08-27	',	'24',	'198.96',	'7694',	'11.85',	'7694',	'N',	'0',	'2',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'110WF',	'Mens Pants 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'MEN''S COTTON PANTS',	'6103421020',	'8.32',	'	2025-08-27	',	'28',	'232.96',	'7694',	'10.65',	'7694',	'N',	'0',	'2',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'110WF',	'Mens Pants 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'MEN''S COTTON PANTS',	'6103421020',	'8.37',	'	2025-08-27	',	'68',	'569.16',	'7694',	'30.63',	'7694',	'N',	'1',	'4',	'Metrotex Industries',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'110WF',	'Mens Pants 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'MEN''S COTTON PANTS',	'6103421020',	'8.37',	'	2025-08-27	',	'4',	'33.48',	'7694',	'1.73',	'7694',	'N',	'0',	'0',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'110WF',	'Mens Pants 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'MEN''S COTTON PANTS',	'6103421020',	'8.4',	'	2025-08-27	',	'24',	'201.6',	'7694',	'10.3',	'7694',	'N',	'0',	'2',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'110WF',	'Mens Pants 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'MEN''S COTTON PANTS',	'6103421020',	'8.46',	'	2025-08-27	',	'32',	'270.72',	'7694',	'15',	'7694',	'N',	'0',	'2',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'110WF',	'Mens Pants 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'MEN''S COTTON PANTS',	'6103421020',	'8.49',	'	2025-08-27	',	'2',	'16.98',	'7694',	'1.85',	'7694',	'N',	'0',	'1',	'Metrotex Industries',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'110WF',	'Mens Pants 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'MEN''S COTTON PANTS',	'6103421020',	'8.49',	'	2025-08-27	',	'46',	'390.54',	'7694',	'20.95',	'7694',	'N',	'0',	'3',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'110WF',	'Mens Pants 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'MEN''S COTTON PANTS',	'6103421020',	'8.61',	'	2025-08-27	',	'24',	'206.64',	'7694',	'10.9',	'7694',	'N',	'0',	'1',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'110WF',	'Mens Pants 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'MEN''S COTTON PANTS',	'6103421020',	'9.45',	'	2025-08-27	',	'78',	'737.1',	'7694',	'35.9',	'7694',	'N',	'0',	'4',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'4.75',	'	2025-08-27	',	'11',	'52.25',	'7694',	'1.8',	'7694',	'N',	'0',	'0',	'Fruit of the Loom  (SV)',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'4.78',	'	2025-08-27	',	'19',	'90.82',	'7694',	'3.26',	'7694',	'N',	'0',	'0',	'Fruit of the Loom  (SV)',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'4.92',	'	2025-08-27	',	'72',	'354.24',	'7694',	'12.75',	'7694',	'N',	'0',	'1',	'Fruit of the Loom  (SV)',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'4.97',	'	2025-08-27	',	'30',	'149.1',	'7694',	'5.35',	'7694',	'N',	'0',	'1',	'Fruit of the Loom  (SV)',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'05PDT',	'Men''s Short Sleeve T-shirt 100% Cotton100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'4.25',	'	2025-08-27	',	'462',	'1963.5',	'7694',	'93.9',	'7694',	'N',	'0',	'7',	'JWIN FASHIONS',	'India',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'05PDT',	'Men''s Short Sleeve T-shirt 100% Cotton100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.18',	'	2025-08-27	',	'26',	'134.68',	'7694',	'5.53',	'7694',	'N',	'0',	'0',	'JWIN FASHIONS',	'India',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'05PDT',	'Men''s Short Sleeve T-shirt 100% Cotton100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.21',	'	2025-08-27	',	'26',	'135.46',	'7694',	'5.53',	'7694',	'N',	'0',	'0',	'JWIN FASHIONS',	'India',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'05PDT',	'Men''s Short Sleeve T-shirt 100% Cotton100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.3',	'	2025-08-27	',	'26',	'137.8',	'7694',	'5.53',	'7694',	'N',	'0',	'1',	'JWIN FASHIONS',	'India',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'20058',	'Men''s Short Sleeve T-shirt 60% Cotton 40% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.88',	'	2025-08-27	',	'24',	'141.12',	'7694',	'3.05',	'7694',	'N',	'0',	'1',	'Fruit of the Loom  (SV)',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'20058',	'Men''s Short Sleeve T-shirt 60% Cotton 40% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'6.01',	'	2025-08-27	',	'24',	'144.24',	'7694',	'3.9',	'7694',	'N',	'0',	'1',	'Fruit of the Loom  (SV)',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.01',	'	2025-08-27	',	'8',	'40.08',	'7694',	'1.7',	'7694',	'N',	'0',	'0',	'Fruit of the Loom  (SV)',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.03',	'	2025-08-27	',	'6',	'30.18',	'7694',	'1.48',	'7694',	'N',	'0',	'0',	'Fruit of the Loom  (SV)',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.04',	'	2025-08-27	',	'10',	'50.4',	'7694',	'2.43',	'7694',	'N',	'0',	'0',	'Fruit of the Loom  (SV)',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.05',	'	2025-08-27	',	'5',	'25.25',	'7694',	'1.19',	'7694',	'N',	'0',	'0',	'Fruit of the Loom  (SV)',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.07',	'	2025-08-27	',	'6',	'30.42',	'7694',	'1.21',	'7694',	'N',	'0',	'0',	'Fruit of the Loom  (SV)',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'31118',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATS',	'6110202041',	'14.2',	'	2025-08-27	',	'237',	'3365.4',	'7694',	'179.05',	'7694',	'N',	'0',	'16',	'INNO',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'31118',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATS',	'6110202041',	'14.25',	'	2025-08-27	',	'102',	'1453.5',	'7694',	'77.15',	'7694',	'N',	'0',	'8',	'INNO',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'30008',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATS',	'6110202041',	'9.22',	'	2025-08-27	',	'43',	'396.46',	'7694',	'20.65',	'7694',	'N',	'0',	'1',	'Metrotex Industries',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'30008',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATS',	'6110202041',	'9.48',	'	2025-08-27	',	'24',	'227.52',	'7694',	'11.3',	'7694',	'N',	'0',	'1',	'Metrotex Industries',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'30008',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATS',	'6110202041',	'9.64',	'	2025-08-27	',	'23',	'221.72',	'7694',	'10.49',	'7694',	'N',	'0',	'0',	'INNO',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'30008',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATS',	'6110202041',	'9.82',	'	2025-08-27	',	'72',	'707.04',	'7694',	'34.6',	'7694',	'N',	'0',	'4',	'INNO',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'30008',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATS',	'6110202041',	'11.51',	'	2025-08-27	',	'29',	'333.79',	'7694',	'14.02',	'7694',	'N',	'0',	'2',	'Metrotex Industries',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'30008',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATS',	'6110202041',	'12.6',	'	2025-08-27	',	'48',	'604.8',	'7694',	'27.94',	'7694',	'N',	'0',	'3',	'Metrotex Industries',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'31014',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATS',	'6110202041',	'10.4',	'	2025-08-27	',	'57',	'592.8',	'7694',	'36.45',	'7694',	'N',	'0',	'4',	'Metrotex Industries',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'31014',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATS',	'6110202041',	'12.23',	'	2025-08-27	',	'47',	'574.81',	'7694',	'30.35',	'7694',	'N',	'1',	'4',	'Metrotex Industries',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'200WF',	'Womens Short 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'WOMEN''S COTTON SHORTS',	'6104622030',	'6.12',	'	2025-08-27	',	'48',	'293.76',	'7694',	'9.7',	'7694',	'N',	'0',	'1',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'200WF',	'Womens Short 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'WOMEN''S COTTON SHORTS',	'6104622030',	'6.37',	'	2025-08-27	',	'102',	'649.74',	'7694',	'22.54',	'7694',	'N',	'0',	'4',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'200WF',	'Womens Short 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'WOMEN''S COTTON SHORTS',	'6104622030',	'6.45',	'	2025-08-27	',	'87',	'561.15',	'7694',	'22.54',	'7694',	'N',	'0',	'1',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'200WF',	'Womens Short 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'WOMEN''S COTTON SHORTS',	'6104622030',	'6.58',	'	2025-08-27	',	'34',	'223.72',	'7694',	'7.36',	'7694',	'N',	'0',	'1',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'60PDT',	'Womens Short Sleeve T-Shirt 100% Cotton100% Cotton',	'WOMEN''S COTTON T-SHIRT',	'6109100040',	'5.09',	'	2025-08-27	',	'49',	'249.41',	'7694',	'8.95',	'7694',	'N',	'0',	'1',	'JWIN FASHIONS',	'India',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'60PDT',	'Womens Short Sleeve T-Shirt 100% Cotton100% Cotton',	'WOMEN''S COTTON T-SHIRT',	'6109100040',	'5.41',	'	2025-08-27	',	'75',	'405.75',	'7694',	'12.35',	'7694',	'N',	'0',	'1',	'NG TEXTILES GUATEMALA S.A.',	'Guatemala',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'60PDT',	'Womens Short Sleeve T-Shirt 100% Cotton100% Cotton',	'WOMEN''S COTTON T-SHIRT',	'6109100040',	'6.19',	'	2025-08-27	',	'35',	'216.65',	'7694',	'6.75',	'7694',	'N',	'0',	'1',	'NG TEXTILES GUATEMALA S.A.',	'Guatemala',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'60PDT',	'Womens Short Sleeve T-Shirt 100% Cotton100% Cotton',	'WOMEN''S COTTON T-SHIRT',	'6109100040',	'6.84',	'	2025-08-27	',	'50',	'342',	'7694',	'8.6',	'7694',	'N',	'0',	'1',	'NG TEXTILES GUATEMALA S.A.',	'Guatemala',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'CCW115',	'Women''s Short Sleeve T-shirt 100% Cotton99% Cotton / 1% Polyester',	'WOMEN''S COTTON T-SHIRT',	'6109100040',	'3.73',	'	2025-08-27	',	'41',	'152.93',	'7694',	'5.5',	'7694',	'N',	'0',	'1',	'League LTDA',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'CCW115',	'Women''s Short Sleeve T-shirt 100% Cotton99% Cotton / 1% Polyester',	'WOMEN''S COTTON T-SHIRT',	'6109100040',	'4.53',	'	2025-08-27	',	'9',	'40.77',	'7694',	'1.48',	'7694',	'N',	'0',	'0',	'League LTDA',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'CCW115',	'Women''s Short Sleeve T-shirt 100% Cotton99% Cotton / 1% Polyester',	'WOMEN''S COTTON T-SHIRT',	'6109100040',	'4.62',	'	2025-08-27	',	'17',	'78.54',	'7694',	'2.41',	'7694',	'N',	'0',	'0',	'League LTDA',	'El Salvador',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'82250',	'Women''s Sweatshirt 52%COTTON-48%POLYESTER52%COTTON-48%POLYESTER',	'WOMEN''S COTTON SWEATS',	'6110202046',	'8.4',	'	2025-08-27	',	'24',	'201.6',	'7694',	'12.4',	'7694',	'N',	'0',	'2',	'Metrotex Industries',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'82250',	'Women''s Sweatshirt 52%COTTON-48%POLYESTER52%COTTON-48%POLYESTER',	'WOMEN''S COTTON SWEATS',	'6110202046',	'8.47',	'	2025-08-27	',	'24',	'203.28',	'7694',	'12.7',	'7694',	'N',	'1',	'2',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'82250',	'Women''s Sweatshirt 52%COTTON-48%POLYESTER52%COTTON-48%POLYESTER',	'WOMEN''S COTTON SWEATS',	'6110202046',	'8.53',	'	2025-08-27	',	'24',	'204.72',	'7694',	'12.3',	'7694',	'N',	'0',	'2',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'82250',	'Women''s Sweatshirt 52%COTTON-48%POLYESTER52%COTTON-48%POLYESTER',	'WOMEN''S COTTON SWEATS',	'6110202046',	'8.54',	'	2025-08-27	',	'48',	'409.92',	'7694',	'23.8',	'7694',	'N',	'1',	'0',	'Milestone Textiles',	'Pakistan',	'0.25',	'2'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'82250',	'Women''s Sweatshirt 52%COTTON-48%POLYESTER52%COTTON-48%POLYESTER',	'WOMEN''S COTTON SWEATS',	'6110202046',	'8.6',	'	2025-08-27	',	'23',	'197.8',	'7694',	'12.46',	'7694',	'N',	'0',	'1',	'Milestone Textiles',	'Pakistan',	'0.25',	'2')


INSERT INTO #TB_NEW_DECLARATION
(
     WayBill             
    ,ContainerNumber     
    ,StyleNumber         
    ,InvoicingDescription
    ,US_HTSDescription   
    ,CA_HTSCode          
    ,UnitPrice           
    ,ShipDate            
    ,Quantity            
    ,TotalPrice          
    ,MinBatch            
    ,WeightKg            
    ,MaxBatch            
    ,Cafta               
    ,Pallets             
    ,Boxes               
    ,Manufactured        
    ,CountryOfOrigin     
    ,IM5                 
    ,DeclarationDate     
    ,ArrivalDate         
    ,DepartureDate       
    ,PortOfLoading       
    ,DecorationDesc      
    ,DecorationValue     
    ,Orden                           
)
VALUES
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'ESYZ230',	'Boy''s Sweatshirt 60% COTTON/ 40% POLYESTER',	'BOYS COTTON SWEATSHIRT',	'6110202044',	'10.93',	'	2025-08-27	',	'17',	'185.81',	'7582',	'6.36',	'7582',	'N',	'0',	'1',	'Metrotex Industries',	'Pakistan',	'5-2140',	NULL,	NULL,	NULL,	NULL,	NULL,	'40.12',	'3'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'33032',	'Men''s Pants 52% COTTON 48% POLYESTER',	'MEN''S COTTON PANTS',	'6103421020',	'9.91',	'	2025-08-27	',	'7',	'69.37',	'7582',	'3.64',	'7582',	'N',	'0',	'1',	'Metrotex Industries',	'Pakistan',	'5-18685',	NULL,	NULL,	NULL,	NULL,	NULL,	'15.33',	'3'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'20058',	'Men''s Short Sleeve T-shirt 60% Cotton 40% Polyester',	'MEN''S COTTON SWEATSHIRT',	'6109100012',	'5.72',	'	2025-08-27	',	'48',	'274.56',	'7582',	'8.25',	'7582',	'N',	'0',	'1',	'Fruit of the Loom  (SV)',	'El Salvador',	'5-6914',	NULL,	NULL,	NULL,	NULL,	NULL,	'105.12',	'3'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'20058',	'Men''s Short Sleeve T-shirt 60% Cotton 40% Polyester',	'MEN''S COTTON SWEATSHIRT',	'6109100012',	'6.05',	'	2025-08-27	',	'25',	'151.25',	'7582',	'4.61',	'7582',	'N',	'1',	'1',	'Fruit of the Loom  (SV)',	'El Salvador',	'5-14536',	NULL,	NULL,	NULL,	NULL,	NULL,	'54.75',	'3'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'20058',	'Men''s Short Sleeve T-shirt 60% Cotton 40% Polyester',	'MEN''S COTTON SWEATSHIRT',	'6109100012',	'6.05',	'	2025-08-27	',	'14',	'84.7',	'7582',	'2.58',	'7582',	'N',	'0',	'1',	'Fruit of the Loom  (SV)',	'El Salvador',	'5-6536',	NULL,	NULL,	NULL,	NULL,	NULL,	'30.66',	'3'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'20058',	'Men''s Short Sleeve T-shirt 60% Cotton 40% Polyester',	'MEN''S COTTON SWEATSHIRT',	'6109100012',	'6.05',	'	2025-08-27	',	'2',	'12.1',	'7582',	'0.37',	'7582',	'N',	'0',	'0',	'Fruit of the Loom (HN)',	'Honduras',	'5-6536',	NULL,	NULL,	NULL,	NULL,	NULL,	'4.38',	'3'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'20058',	'Men''s Short Sleeve T-shirt 60% Cotton 40% Polyester',	'MEN''S COTTON SWEATSHIRT',	'6109100012',	'6.42',	'	2025-08-27	',	'6',	'38.52',	'7582',	'1.15',	'7582',	'N',	'0',	'0',	'Fruit of the Loom  (SV)',	'El Salvador',	'5-5682',	NULL,	NULL,	NULL,	NULL,	NULL,	'13.14',	'3'),
('AIR-APP-20250827-1',	'AIR-APP-20250827-1',	'20058',	'Men''s Short Sleeve T-shirt 60% Cotton 40% Polyester',	'MEN''S COTTON SWEATSHIRT',	'6109100012',	'6.42',	'	2025-08-27	',	'42',	'269.64',	'7582',	'8.05',	'7582',	'N',	'0',	'0',	'Fruit of the Loom  (SV)',	'El Salvador',	'5-6914',	NULL,	NULL,	NULL,	NULL,	NULL,	'91.98',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'ESYC200',	'Boy''s Sweatshirt 60% COTTON/ 40% POLYESTER',	'BOYS COTTON SWEATS',	'6110202044',	'8.63',	'	2025-09-29	',	'10',	'86.3',	'7694',	'2.875',	'7694',	'N',	'0',	'1',	'Metrotex Industries',	'Pakistan',	'5-2140',	'	2025-02-12	',	'	2025-02-12	',	'	2025-02-05	',	'MIAMI, FL.',	'SCREENPRINT',	'24.1',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'ESYH210',	'Boy''s Sweatshirt 65% COTTON / 35% POLYESTER',	'BOYS COTTON SWEATS',	'6110202044',	'8.7',	'	2025-09-29	',	'6',	'52.2',	'7694',	'2.1125',	'7694',	'N',	'0',	'1',	'Metrotex Industries',	'Pakistan',	'5-2140',	'	2025-02-12	',	'	2025-02-12	',	'	2025-02-05	',	'MIAMI, FL.',	'SCREENPRINT',	'8.76',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'ESYH210',	'Boy''s Sweatshirt 65% COTTON / 35% POLYESTER',	'BOYS COTTON SWEATS',	'6110202044',	'9.04',	'	2025-09-29	',	'14',	'126.56',	'7694',	'4.2',	'7694',	'N',	'0',	'1',	'Metrotex Industries',	'Pakistan',	'5-2140',	'	2025-02-12	',	'	2025-02-12	',	'	2025-02-05	',	'MIAMI, FL.',	'SCREENPRINT',	'20.44',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'31018',	'Men''s Hood 100% Polyester',	'MEN''S SYNTHETIC SWEATS',	'6110303041',	'14.09',	'	2025-09-29	',	'37',	'521.33',	'7694',	'23.78',	'7694',	'N',	'0',	'3',	'Wollomtex',	'China',	'5-18693',	'	2024-12-02	',	'	2024-12-02	',	'	2024-11-26	',	'MIAMI, FL.',	'SCREENPRINT',	'54.02',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'31018',	'Men''s Hood 100% Polyester',	'MEN''S SYNTHETIC SWEATS',	'6110303041',	'14.09',	'	2025-09-29	',	'3',	'42.27',	'7694',	'2.02',	'7694',	'N',	'0',	'0',	'Wollomtex',	'China',	'5-8140',	'	2024-05-24	',	'	2024-05-24	',	'	2024-05-12	',	'PHILADELPHIA, PA.',	'SCREENPRINT',	'4.38',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'ML540',	'Men''s Pants 36% Cotton 48% Polyester 12% Rayon 4% Spandex  50% POLYESTER 45% COTTON 5% RAYON',	'MEN''S SYNTHETIC PANTS',	'6103430000',	'10.74',	'	2025-09-29	',	'4',	'42.96',	'7694',	'1.8615',	'7694',	'Y',	'1',	'1',	'NG TEXTILES GUATEMALA S.A.',	'Guatemala',	'5-18693',	'	2024-12-02	',	'	2024-12-02	',	'	2024-11-26	',	'MIAMI, FL.',	'SCREENPRINT',	'5.84',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'4.75',	'	2025-09-29	',	'36',	'171',	'7694',	'5.8875',	'7694',	'N',	'0',	'0',	'Fruit of the Loom  (SV)',	'El Salvador',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'88.56',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'4.75',	'	2025-09-29	',	'1',	'4.75',	'7694',	'0.1635',	'7694',	'N',	'0',	'1',	'Fruit of the Loom (HN)',	'Honduras',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'2.46',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'4.78',	'	2025-09-29	',	'45',	'215.1',	'7694',	'7.7324',	'7694',	'N',	'0',	'0',	'Fruit of the Loom  (SV)',	'El Salvador',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'108.45',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'4.78',	'	2025-09-29	',	'7',	'33.46',	'7694',	'1.2028',	'7694',	'N',	'0',	'1',	'Fruit of the Loom (HN)',	'Honduras',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'16.87',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'4.89',	'	2025-09-29	',	'100',	'489',	'7694',	'17.118',	'7694',	'N',	'0',	'0',	'Fruit of the Loom  (SV)',	'El Salvador',	'5-5682',	'	2025-04-14	',	'	2025-04-14	',	'	2025-04-07	',	'MIAMI, FL.',	'SCREENPRINT',	'246',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'4.89',	'	2025-09-29	',	'24',	'117.36',	'7694',	'4.1083',	'7694',	'N',	'0',	'0',	'Fruit of the Loom  (SV)',	'El Salvador',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'59.04',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'4.89',	'	2025-09-29	',	'6',	'29.34',	'7694',	'1.03',	'7694',	'N',	'0',	'0',	'Fruit of the Loom (HN)',	'Honduras',	'5-2281',	'	2025-02-14	',	'	2025-02-14	',	'	2025-02-08	',	'MIAMI, FL.',	'SCREENPRINT',	'14.76',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 100% Cotton',	'MEN''S COTTON T-SHIRT',	'6109100012',	'4.89',	'	2025-09-29	',	'14',	'68.46',	'7694',	'2.3965',	'7694',	'N',	'1',	'2',	'Fruit of the Loom (HN)',	'Honduras',	'5-5682',	'	2025-04-14	',	'	2025-04-14	',	'	2025-04-07	',	'MIAMI, FL.',	'SCREENPRINT',	'34.44',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.01',	'	2025-09-29	',	'9',	'45.09',	'7694',	'1.9125',	'7694',	'N',	'0',	'1',	'Fruit of the Loom  (SV)',	'El Salvador',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'22.14',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.01',	'	2025-09-29	',	'7',	'35.07',	'7694',	'1.4875',	'7694',	'N',	'0',	'0',	'Fruit of the Loom (HN)',	'Honduras',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'17.22',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.03',	'	2025-09-29	',	'12',	'60.36',	'7694',	'2.9572',	'7694',	'N',	'0',	'2',	'Fruit of the Loom  (SV)',	'El Salvador',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'29.52',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.03',	'	2025-09-29	',	'10',	'50.3',	'7694',	'2.4642',	'7694',	'N',	'0',	'0',	'Fruit of the Loom (HN)',	'Honduras',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'24.6',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.04',	'	2025-09-29	',	'10',	'50.4',	'7694',	'2.4286',	'7694',	'N',	'0',	'2',	'Fruit of the Loom  (SV)',	'El Salvador',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'24.6',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.04',	'	2025-09-29	',	'8',	'40.32',	'7694',	'1.943',	'7694',	'N',	'0',	'0',	'Fruit of the Loom (HN)',	'Honduras',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'19.68',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.05',	'	2025-09-29	',	'6',	'30.3',	'7694',	'1.425',	'7694',	'N',	'1',	'1',	'Fruit of the Loom  (SV)',	'El Salvador',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'14.76',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.05',	'	2025-09-29	',	'5',	'25.25',	'7694',	'1.1875',	'7694',	'N',	'0',	'0',	'Fruit of the Loom (HN)',	'Honduras',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'12.3',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.07',	'	2025-09-29	',	'3',	'15.21',	'7694',	'0.6064',	'7694',	'N',	'0',	'1',	'Fruit of the Loom  (SV)',	'El Salvador',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'7.38',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'EZ100',	'Men''s Short Sleeve T-shirt 90% Cotton 10% Polyester',	'MEN''S COTTON T-SHIRT',	'6109100012',	'5.07',	'	2025-09-29	',	'5',	'25.35',	'7694',	'1.0107',	'7694',	'N',	'0',	'0',	'Fruit of the Loom (HN)',	'Honduras',	'5-6914',	'	2025-05-12	',	'	2025-04-22	',	'	2025-04-20	',	'MIAMI, FL.',	'SCREENPRINT',	'12.3',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'30008',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATS',	'6110202041',	'9.22',	'	2025-09-29	',	'5',	'46.1',	'7694',	'2.4',	'7694',	'N',	'0',	'2',	'Metrotex Industries',	'Pakistan',	'5-18316',	'	2024-11-25	',	'	2024-11-25	',	'	2024-11-18	',	'MIAMI, FL.',	'SCREENPRINT',	'12.3',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'30008',	'Men''s Sweatshirt 65% COTTON 35% POLYESTER',	'MEN''S COTTON SWEATS',	'6110202041',	'9.64',	'	2025-09-29	',	'1',	'9.64',	'7694',	'0.4563',	'7694',	'N',	'0',	'1',	'Metrotex Industries',	'Pakistan',	'5-20205',	'	2024-01-30	',	'	2023-12-26	',	'	2023-11-28	',	'HOUSTON, UNITED STATES.',	'SCREENPRINT',	'2.46',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'200WF',	'Womens Short 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'WOMEN''S COTTON SHORTS',	'6104622030',	'6.45',	'	2025-09-29	',	'25',	'161.25',	'7694',	'5.4072',	'7694',	'N',	'0',	'2',	'Milestone Textiles',	'Pakistan',	'5-18685',	'	2024-12-02	',	'	2024-12-02	',	'	2024-11-26	',	'MIAMI, FL.',	'SCREENPRINT',	'36.5',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'200WF',	'Womens Short 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'WOMEN''S COTTON SHORTS',	'6104622030',	'6.45',	'	2025-09-29	',	'1',	'6.45',	'7694',	'0.205',	'7694',	'N',	'0',	'1',	'Milestone Textiles',	'Pakistan',	'5-2140',	'	2025-02-12	',	'	2025-02-12	',	'	2025-02-05	',	'MIAMI, FL.',	'SCREENPRINT',	'1.46',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'200WF',	'Womens Short 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'WOMEN''S COTTON SHORTS',	'6104622030',	'6.45',	'	2025-09-29	',	'11',	'70.95',	'7694',	'3.46',	'7694',	'N',	'0',	'0',	'Milestone Textiles',	'Pakistan',	'5-1536',	'	2025-02-03	',	'	2025-02-03	',	'	2025-01-27	',	'PORT EVERGLADES, FL.',	'SCREENPRINT',	'16.06',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'200WF',	'Womens Short 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'WOMEN''S COTTON SHORTS',	'6104622030',	'6.37',	'	2025-09-29	',	'8',	'50.96',	'7694',	'1.93',	'7694',	'N',	'0',	'1',	'Milestone Textiles',	'Pakistan',	'5-18693',	'	2024-12-02	',	'	2024-12-02	',	'	2024-11-26	',	'MIAMI, FL.',	'SCREENPRINT',	'11.68',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'200WF',	'Womens Short 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'WOMEN''S COTTON SHORTS',	'6104622030',	'6.37',	'	2025-09-29	',	'14',	'89.18',	'7694',	'3.13',	'7694',	'N',	'0',	'1',	'Milestone Textiles',	'Pakistan',	'5-1536',	'	2025-02-03	',	'	2025-02-03	',	'	2025-01-27	',	'PORT EVERGLADES, FL.',	'SCREENPRINT',	'20.44',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'200WF',	'Womens Short 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'WOMEN''S COTTON SHORTS',	'6104622030',	'6.58',	'	2025-09-29	',	'34',	'223.72',	'7694',	'7.41',	'7694',	'N',	'0',	'1',	'Milestone Textiles',	'Pakistan',	'5-1536',	'	2025-02-03	',	'	2025-02-03	',	'	2025-01-27	',	'PORT EVERGLADES, FL.',	'SCREENPRINT',	'49.64',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'200WF',	'Womens Short 52% Cotton 48% Polyester52% Cotton 48% Polyester',	'WOMEN''S COTTON SHORTS',	'6104622030',	'6.58',	'	2025-09-29	',	'4',	'26.32',	'7694',	'0.8304',	'7694',	'N',	'1',	'1',	'Milestone Textiles',	'Pakistan',	'5-18693',	'	2024-12-02	',	'	2024-12-02	',	'	2024-11-26	',	'MIAMI, FL.',	'SCREENPRINT',	'5.84',	'3'),
('AIR-APP-20250929',	'AIR-APP-20250929',	'82250',	'Women''s Sweatshirt 52%COTTON-48%POLYESTER52%COTTON-48%POLYESTER',	'WOMEN''S COTTON SWEATS',	'6110202046',	'8.6',	'	2025-09-29	',	'1',	'8.6',	'7694',	'0.5176',	'7694',	'N',	'1',	'1',	'Milestone Textiles',	'Pakistan',	'5-18693',	'	2025-02-12	',	'	2025-02-12	',	'	2025-02-05	',	'MIAMI, FL.',	'SCREENPRINT',	'1.46',	'3')



INSERT INTO [192.168.1.93].AppsLCA.dbo.Import_Export_CommercialInvoice
SELECT *
FROM #TB_NEW_CI
WHERE Waybill = 'AIR-APP-20250929'

INSERT INTO [192.168.1.93].AppsLCA.dbo.Import_Export_DeclarationExport
SELECT *
FROM #TB_NEW_DECLARATION
WHERE Waybill = 'AIR-APP-20250929'