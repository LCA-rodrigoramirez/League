DROP TABLE IF EXISTS #New_Operators

CREATE TABLE #New_Operators
(
     [ID]                   INT
    ,[CompanyNumber]        VARCHAR(100)
    ,[CompanyName]          VARCHAR(100)
    ,[ProductionTaskName]   VARCHAR(100)
    ,[Comments6]            VARCHAR(100)
    ,[Comments2]            VARCHAR(100)
)

INSERT INTO #New_Operators
VALUES
(36484,'EM044S','Embroidery # 44','Check In','Embroidery','DIA'),
(36485,'EM044F','Embroidery # 44','Check Out','Embroidery','DIA'),
(36497,'EM045S','Embroidery # 45','Check In','Embroidery','DIA'),
(36513,'EM045F','Embroidery # 45','Check Out','Embroidery','DIA'),
(36498,'EM046S','Embroidery # 46','Check In','Embroidery','DIA'),
(36514,'EM046F','Embroidery # 46','Check Out','Embroidery','DIA'),
(36499,'EM047S','Embroidery # 47','Check In','Embroidery','DIA'),
(36515,'EM047F','Embroidery # 47','Check Out','Embroidery','DIA'),
(36500,'EM048S','Embroidery # 48','Check In','Embroidery','DIA'),
(36516,'EM048F','Embroidery # 48','Check Out','Embroidery','DIA'),
(36484,'EM044NOCS','Embroidery # 44','Check In','Embroidery','NOC'),
(36485,'EM044NOCF','Embroidery # 44','Check Out','Embroidery','NOC'),
(36497,'EM045NOCS','Embroidery # 45','Check In','Embroidery','NOC'),
(36513,'EM045NOCF','Embroidery # 45','Check Out','Embroidery','NOC'),
(36498,'EM046NOCS','Embroidery # 46','Check In','Embroidery','NOC'),
(36514,'EM046NOCF','Embroidery # 46','Check Out','Embroidery','NOC'),
(36499,'EM047NOCS','Embroidery # 47','Check In','Embroidery','NOC'),
(36515,'EM047NOCF','Embroidery # 47','Check Out','Embroidery','NOC'),
(36500,'EM048NOCS','Embroidery # 48','Check In','Embroidery','NOC'),
(36516,'EM048NOCF','Embroidery # 48','Check Out','Embroidery','NOC')
-- (36501,'EM06TCS','Embroidery # 06','Check In','Embroidery','TC'),
-- (36517,'EM06TCF','Embroidery # 06','Check Out','Embroidery','TC'),
-- (36502,'EM07TCS','Embroidery # 07','Check In','Embroidery','TC'),
-- (36518,'EM07TCF','Embroidery # 07','Check Out','Embroidery','TC'),
-- (36503,'EM08TCS','Embroidery # 08','Check In','Embroidery','TC'),
-- (36519,'EM08TCF','Embroidery # 08','Check Out','Embroidery','TC'),
-- (36504,'EM09TCS','Embroidery # 09','Check In','Embroidery','TC'),
-- (36520,'EM09TCF','Embroidery # 09','Check Out','Embroidery','TC'),
-- (36505,'EM10TCS','Embroidery # 10','Check In','Embroidery','TC'),
-- (36521,'EM10TCF','Embroidery # 10','Check Out','Embroidery','TC'),
-- (36506,'EM11TCS','Embroidery # 11','Check In','Embroidery','TC'),
-- (36522,'EM11TCF','Embroidery # 11','Check Out','Embroidery','TC'),
-- (36507,'EM12TCS','Embroidery # 12','Check In','Embroidery','TC'),
-- (36523,'EM12TCF','Embroidery # 12','Check Out','Embroidery','TC'),
-- (36508,'EM13TCS','Embroidery # 13','Check In','Embroidery','TC'),
-- (36524,'EM13TCF','Embroidery # 13','Check Out','Embroidery','TC'),
-- (36509,'EM14TCS','Embroidery # 14','Check In','Embroidery','TC'),
-- (36525,'EM14TCF','Embroidery # 14','Check Out','Embroidery','TC'),
-- (36510,'EM15TCS','Embroidery # 15','Check In','Embroidery','TC'),
-- (36526,'EM15TCF','Embroidery # 15','Check Out','Embroidery','TC'),
-- (36511,'EM16TCS','Embroidery # 16','Check In','Embroidery','TC'),
-- (36527,'EM16TCF','Embroidery # 16','Check Out','Embroidery','TC'),
-- (36512,'EM17TCS','Embroidery # 17','Check In','Embroidery','TC'),
-- (36528,'EM17TCF','Embroidery # 17','Check Out','Embroidery','TC'),
-- (36993,'EM18TCS','Embroidery # 18','Check In','Embroidery','TC'),
-- (37001,'EM18TCF','Embroidery # 18','Check Out','Embroidery','TC'),
-- (36998,'EM19TCS','Embroidery # 19','Check In','Embroidery','TC'),
-- (37002,'EM19TCF','Embroidery # 19','Check Out','Embroidery','TC'),
-- (37053,'EM20TCS','Embroidery # 20','Check In','Embroidery','TC'),
-- (37056,'EM20TCF','Embroidery # 20','Check Out','Embroidery','TC'),
-- (37054,'EM21TCS','Embroidery # 21','Check In','Embroidery','TC'),
-- (37057,'EM21TCF','Embroidery # 21','Check Out','Embroidery','TC'),
-- (37055,'EM22TCS','Embroidery # 22','Check In','Embroidery','TC'),
-- (37058,'EM22TCF','Embroidery # 22','Check Out','Embroidery','TC'),
-- (37368,'EM23TCS','Embroidery # 23','Check In','Embroidery','TC'),
-- (37369,'EM23TCF','Embroidery # 23','Check Out','Embroidery','TC'),
-- (37370,'EM24TCS','Embroidery # 24','Check In','Embroidery','TC'),
-- (37371,'EM24TCF','Embroidery # 24','Check Out','Embroidery','TC'),
-- (37372,'EM25TCS','Embroidery # 25','Check In','Embroidery','TC'),
-- (37373,'EM25TCF','Embroidery # 25','Check Out','Embroidery','TC'),
-- (37374,'EM26TCS','Embroidery # 26','Check In','Embroidery','TC'),
-- (37375,'EM26TCF','Embroidery # 26','Check Out','Embroidery','TC'),
-- (37376,'EM27TCS','Embroidery # 27','Check In','Embroidery','TC'),
-- (37377,'EM27TCF','Embroidery # 27','Check Out','Embroidery','TC'),
-- (37378,'EM28TCS','Embroidery # 28','Check In','Embroidery','TC'),
-- (37379,'EM28TCF','Embroidery # 28','Check Out','Embroidery','TC'),
-- (37380,'EM29TCS','Embroidery # 29','Check In','Embroidery','TC'),
-- (37381,'EM29TCF','Embroidery # 29','Check Out','Embroidery','TC'),
-- (37382,'EM30TCS','Embroidery # 30','Check In','Embroidery','TC'),
-- (37383,'EM30TCF','Embroidery # 30','Check Out','Embroidery','TC'),
-- (37384,'EM31TCS','Embroidery # 31','Check In','Embroidery','TC'),
-- (37385,'EM31TCF','Embroidery # 31','Check Out','Embroidery','TC'),
-- (37386,'EM32TCS','Embroidery # 32','Check In','Embroidery','TC'),
-- (37387,'EM32TCF','Embroidery # 32','Check Out','Embroidery','TC'),
-- (37388,'EM33TCS','Embroidery # 33','Check In','Embroidery','TC'),
-- (37389,'EM33TCF','Embroidery # 33','Check Out','Embroidery','TC'),
-- (37390,'EM34TCS','Embroidery # 34','Check In','Embroidery','TC'),
-- (37391,'EM34TCF','Embroidery # 34','Check Out','Embroidery','TC'),
-- (37392,'EM35TCS','Embroidery # 35','Check In','Embroidery','TC'),
-- (37393,'EM35TCF','Embroidery # 35','Check Out','Embroidery','TC'),
-- (37394,'EM36TCS','Embroidery # 36','Check In','Embroidery','TC'),
-- (37395,'EM36TCF','Embroidery # 36','Check Out','Embroidery','TC'),
-- (37396,'EM37TCS','Embroidery # 37','Check In','Embroidery','TC'),
-- (37397,'EM37TCF','Embroidery # 37','Check Out','Embroidery','TC'),
-- (37398,'EM38TCS','Embroidery # 38','Check In','Embroidery','TC'),
-- (37399,'EM38TCF','Embroidery # 38','Check Out','Embroidery','TC'),
-- (37400,'EM39TCS','Embroidery # 39','Check In','Embroidery','TC'),
-- (37401,'EM39TCF','Embroidery # 39','Check Out','Embroidery','TC'),
-- (37402,'EM40TCS','Embroidery # 40','Check In','Embroidery','TC'),
-- (37403,'EM40TCF','Embroidery # 40','Check Out','Embroidery','TC'),
-- (37404,'EM41TCS','Embroidery # 41','Check In','Embroidery','TC'),
-- (37405,'EM41TCF','Embroidery # 41','Check Out','Embroidery','TC'),
-- (37406,'EM42TCS','Embroidery # 42','Check In','Embroidery','TC'),
-- (37407,'EM42TCF','Embroidery # 42','Check Out','Embroidery','TC'),
-- (37003,'EM501TCS','Embroidery # 501','Check In','Embroidery','TC'),
-- (37004,'EM501TCF','Embroidery # 501','Check Out','Embroidery','TC'),
-- (37005,'EM502TCS','Embroidery # 502','Check In','Embroidery','TC'),
-- (37006,'EM502TCF','Embroidery # 502','Check Out','Embroidery','TC'),
-- (36529,'EM503TCS','Embroidery # 503','Check In','Embroidery','TC'),
-- (36535,'EM503TCF','Embroidery # 503','Check Out','Embroidery','TC'),
-- (37007,'EM504TCS','Embroidery # 504','Check In','Embroidery','TC'),
-- (37008,'EM504TCF','Embroidery # 504','Check Out','Embroidery','TC'),
-- (37009,'EM505TCS','Embroidery # 505','Check In','Embroidery','TC'),
-- (37010,'EM505TCF','Embroidery # 505','Check Out','Embroidery','TC'),
-- (36530,'EM506TCS','Embroidery # 506','Check In','Embroidery','TC'),
-- (36536,'EM506TCF','Embroidery # 506','Check Out','Embroidery','TC'),
-- (37011,'EM507TCS','Embroidery # 507','Check In','Embroidery','TC'),
-- (37012,'EM507TCF','Embroidery # 507','Check Out','Embroidery','TC'),
-- (36531,'EM508TCS','Embroidery # 508','Check In','Embroidery','TC'),
-- (36537,'EM508TCF','Embroidery # 508','Check Out','Embroidery','TC'),
-- (37013,'EM509TCS','Embroidery # 509','Check In','Embroidery','TC'),
-- (37014,'EM509TCF','Embroidery # 509','Check Out','Embroidery','TC'),
-- (37015,'EM510TCS','Embroidery # 510','Check In','Embroidery','TC'),
-- (37016,'EM510TCF','Embroidery # 510','Check Out','Embroidery','TC'),
-- (37017,'EM511TCS','Embroidery # 511','Check In','Embroidery','TC'),
-- (37018,'EM511TCF','Embroidery # 511','Check Out','Embroidery','TC'),
-- (37019,'EM512TCS','Embroidery # 512','Check In','Embroidery','TC'),
-- (37020,'EM512TCF','Embroidery # 512','Check Out','Embroidery','TC'),
-- (37412,'EM513TCS','Embroidery # 513','Check In','Embroidery','TC'),
-- (37413,'EM513TCF','Embroidery # 513','Check Out','Embroidery','TC'),
-- (37021,'EM514TCS','Embroidery # 514','Check In','Embroidery','TC'),
-- (37022,'EM514TCF','Embroidery # 514','Check Out','Embroidery','TC'),
-- (36532,'EM515TCS','Embroidery # 515','Check In','Embroidery','TC'),
-- (36538,'EM515TCF','Embroidery # 515','Check Out','Embroidery','TC'),
-- (36533,'EM516TCS','Embroidery # 516','Check In','Embroidery','TC'),
-- (36539,'EM516TCF','Embroidery # 516','Check Out','Embroidery','TC'),
-- (37023,'EM517TCS','Embroidery # 517','Check In','Embroidery','TC'),
-- (37024,'EM517TCF','Embroidery # 517','Check Out','Embroidery','TC'),
-- (36534,'EM518TCS','Embroidery # 518','Check In','Embroidery','TC'),
-- (36540,'EM518TCF','Embroidery # 518','Check Out','Embroidery','TC'),
-- (37025,'EM519TCS','Embroidery # 519','Check In','Embroidery','TC'),
-- (37026,'EM519TCF','Embroidery # 519','Check Out','Embroidery','TC'),
-- (37408,'EM520TCS','Embroidery # 520','Check In','Embroidery','TC'),
-- (37409,'EM520TCF','Embroidery # 520','Check Out','Embroidery','TC'),
-- (37410,'EM521TCS','Embroidery # 521','Check In','Embroidery','TC'),
-- (37411,'EM521TCF','Embroidery # 521','Check Out','Embroidery','TC')
-- (36554,'EMH01NOCS','EMH01','Check In','Embroidery Headwear','NOC'),
-- (36570,'EMH01NOCF','EMH01','Check Out','Embroidery Headwear','NOC'),
-- (36555,'EMH02NOCS','EMH02','Check In','Embroidery Headwear','NOC'),
-- (36571,'EMH02NOCF','EMH02','Check Out','Embroidery Headwear','NOC'),
-- (36556,'EMH03NOCS','EMH03','Check In','Embroidery Headwear','NOC'),
-- (36572,'EMH03NOCF','EMH03','Check Out','Embroidery Headwear','NOC'),
-- (36557,'EMH04NOCS','EMH04','Check In','Embroidery Headwear','NOC'),
-- (36573,'EMH04NOCF','EMH04','Check Out','Embroidery Headwear','NOC'),
-- (36558,'EMH05NOCS','EMH05','Check In','Embroidery Headwear','NOC'),
-- (36574,'EMH05NOCF','EMH05','Check Out','Embroidery Headwear','NOC'),
-- (36559,'EMH06NOCS','EMH06','Check In','Embroidery Headwear','NOC'),
-- (36575,'EMH06NOCF','EMH06','Check Out','Embroidery Headwear','NOC'),
-- (36560,'EMH07NOCS','EMH07','Check In','Embroidery Headwear','NOC'),
-- (36576,'EMH07NOCF','EMH07','Check Out','Embroidery Headwear','NOC'),
-- (36561,'EMH08NOCS','EMH08','Check In','Embroidery Headwear','NOC'),
-- (36577,'EMH08NOCF','EMH08','Check Out','Embroidery Headwear','NOC'),
-- (36562,'EMH09NOCS','EMH09','Check In','Embroidery Headwear','NOC'),
-- (36578,'EMH09NOCF','EMH09','Check Out','Embroidery Headwear','NOC'),
-- (36563,'EMH10NOCS','EMH10','Check In','Embroidery Headwear','NOC'),
-- (36579,'EMH10NOCF','EMH10','Check Out','Embroidery Headwear','NOC'),
-- (36580,'EMH501NOCS','EMH501','Check In','Embroidery Headwear','NOC'),
-- (36588,'EMH501NOCF','EMH501','Check Out','Embroidery Headwear','NOC'),
-- (36581,'EMH502NOCS','EMH502','Check In','Embroidery Headwear','NOC'),
-- (36589,'EMH502NOCF','EMH502','Check Out','Embroidery Headwear','NOC'),
-- (36582,'EMH503NOCS','EMH503','Check In','Embroidery Headwear','NOC'),
-- (36590,'EMH503NOCF','EMH503','Check Out','Embroidery Headwear','NOC'),
-- (36583,'EMH504NOCS','EMH504','Check In','Embroidery Headwear','NOC'),
-- (36591,'EMH504NOCF','EMH504','Check Out','Embroidery Headwear','NOC'),
-- (36584,'EMH505NOCS','EMH505','Check In','Embroidery Headwear','NOC'),
-- (36592,'EMH505NOCF','EMH505','Check Out','Embroidery Headwear','NOC'),
-- (36585,'EMH506NOCS','EMH506','Check In','Embroidery Headwear','NOC'),
-- (36593,'EMH506NOCF','EMH506','Check Out','Embroidery Headwear','NOC'),
-- (36586,'EMH507NOCS','EMH507','Check In','Embroidery Headwear','NOC'),
-- (36594,'EMH507NOCF','EMH507','Check Out','Embroidery Headwear','NOC'),
-- (36587,'EMH508NOCS','EMH508','Check In','Embroidery Headwear','NOC'),
-- (36595,'EMH508NOCF','EMH508','Check Out','Embroidery Headwear','NOC'),
-- (36641,'EMH509NOCS','EMH509','Check In','Embroidery Headwear','NOC'),
-- (36642,'EMH509NOCF','EMH509','Check Out','Embroidery Headwear','NOC'),
-- (36643,'EMH510NOCS','EMH510','Check In','Embroidery Headwear','NOC'),
-- (36646,'EMH510NOCF','EMH510','Check Out','Embroidery Headwear','NOC'),
-- (36564,'Fast TrackNOCS','Fast Track 1','Check In','Sewing','NOC'),
-- (36565,'Fast TrackNOCF','Fast Track 1','Check Out','Sewing','NOC'),
-- (36596,'Inspect 1 HWNOCS','Inspect 1 HW','Check In','Trim & Inspection HW','NOC'),
-- (36601,'Inspect 1 HWNOCF','Inspect 1 HW','Check Out','Trim & Inspection HW','NOC'),
-- (36597,'Inspect 2 HWNOCS','Inspect 2 HW','Check In','Trim & Inspection HW','NOC'),
-- (36602,'Inspect 2 HWNOCF','Inspect 2 HW','Check Out','Trim & Inspection HW','NOC'),
-- (36598,'Inspect 3 HWNOCS','Inspect 3 HW','Check In','Trim & Inspection HW','NOC'),
-- (36603,'Inspect 3 HWNOCF','Inspect 3 HW','Check Out','Trim & Inspection HW','NOC'),
-- (36599,'Inspect 4 HWNOCS','Inspect 4 HW','Check In','Trim & Inspection HW','NOC'),
-- (36604,'Inspect 4 HWNOCF','Inspect 4 HW','Check Out','Trim & Inspection HW','NOC'),
-- (36600,'Inspect 5 HWNOCS','Inspect 5 HW','Check In','Trim & Inspection HW','NOC'),
-- (36605,'Inspect 5 HWNOCF','Inspect 5 HW','Check Out','Trim & Inspection HW','NOC'),
-- (36458,'Modulo01NOCS','Modulo # 01','Check In','Sewing','NOC'),
-- (36459,'Modulo01NOCF','Modulo # 01','Check Out','Sewing','NOC'),
-- (37158,'Modulo01-1NOCS','Modulo # 01-1','Check In','Sewing','NOC'),
-- (37159,'Modulo01-1NOCF','Modulo # 01-1','Check Out','Sewing','NOC'),
-- (36463,'Modulo02NOCS','Modulo # 02','Check In','Sewing','NOC'),
-- (36464,'Modulo02NOCF','Modulo # 02','Check Out','Sewing','NOC'),
-- (36465,'Modulo03NOCS','Modulo # 03','Check In','Sewing','NOC'),
-- (36466,'Modulo03NOCF','Modulo # 03','Check Out','Sewing','NOC'),
-- (36467,'Modulo04NOCS','Modulo # 04','Check In','Sewing','NOC'),
-- (36468,'Modulo04NOCF','Modulo # 04','Check Out','Sewing','NOC'),
-- (36469,'Modulo05NOCS','Modulo # 05','Check In','Sewing','NOC'),
-- (36470,'Modulo05NOCF','Modulo # 05','Check Out','Sewing','NOC'),
-- (36471,'Modulo06NOCS','Modulo # 06','Check In','Sewing','NOC'),
-- (36472,'Modulo06NOCF','Modulo # 06','Check Out','Sewing','NOC'),
-- (36473,'Modulo07NOCS','Modulo # 07','Check In','Sewing','NOC'),
-- (36474,'Modulo07NOCF','Modulo # 07','Check Out','Sewing','NOC'),
-- (36475,'Modulo08NOCS','Modulo # 08','Check In','Sewing','NOC'),
-- (36476,'Modulo08NOCF','Modulo # 08','Check Out','Sewing','NOC'),
-- (36480,'Modulo09NOCS','Modulo # 09','Check In','Sewing','NOC'),
-- (36481,'Modulo09NOCF','Modulo # 09','Check Out','Sewing','NOC'),
-- (36482,'Modulo10NOCS','Modulo # 10','Check In','Sewing','NOC'),
-- (36483,'Modulo10NOCF','Modulo # 10','Check Out','Sewing','NOC'),
-- (36486,'Modulo11NOCS','Modulo # 11','Check In','Sewing','NOC'),
-- (36487,'Modulo11NOCF','Modulo # 11','Check Out','Sewing','NOC'),
-- (36541,'Modulo12NOCS','Modulo # 12','Check In','Sewing','NOC'),
-- (36542,'Modulo12NOCF','Modulo # 12','Check Out','Sewing','NOC'),
-- (36543,'Modulo13NOCS','Modulo # 13','Check In','Sewing','NOC'),
-- (36544,'Modulo13NOCF','Modulo # 13','Check Out','Sewing','NOC'),
-- (36545,'Modulo14NOCS','Modulo # 14','Check In','Sewing','NOC'),
-- (36546,'Modulo14NOCF','Modulo # 14','Check Out','Sewing','NOC'),
-- (36547,'Modulo15NOCS','Modulo # 15','Check In','Sewing','NOC'),
-- (36548,'Modulo15NOCF','Modulo # 15','Check Out','Sewing','NOC'),
-- (36552,'Modulo16NOCS','Modulo # 16','Check In','Sewing','NOC'),
-- (36553,'Modulo16NOCF','Modulo # 16','Check Out','Sewing','NOC'),
-- (36566,'ModuloPreNOCS','Modulo # PRE','Check In','Sewing','NOC'),
-- (36567,'ModuloPreNOCF','Modulo # PRE','Check Out','Sewing','NOC'),
-- (36568,'ModuloMiscNOCS','Modulo MISC','Check In','Sewing','NOC'),
-- (36569,'ModuloMiscNOCF','Modulo MISC','Check Out','Sewing','NOC'),
-- (37030,'RL01NOCS','Modulo Re-label','Check In','Re-Label','NOC'),
-- (37031,'RL01NOCF','Modulo Re-label','Check Out','Re-Label','NOC'),
-- (36454,'SoporteITNOCS','SoporteIT','Check In','IT','NOC'),
-- (36455,'SoporteITNOCF','SoporteIT','Check Out','IT','NOC'),
-- (36953,'SP Group 01 NOCS','SP Group 01','Check In','Screen Print','NOC'),
-- (36977,'SP Group 01 NOCF','SP Group 01','Check Out','Screen Print','NOC'),
-- (36952,'SP Group 02 NOCS','SP Group 02','Check In','Screen Print','NOC'),
-- (36976,'SP Group 02 NOCF','SP Group 02','Check Out','Screen Print','NOC'),
-- (36951,'SP Group 03 NOCS','SP Group 03','Check In','Screen Print','NOC'),
-- (36975,'SP Group 03 NOCF','SP Group 03','Check Out','Screen Print','NOC'),
-- (36950,'SP Group 04 NOCS','SP Group 04','Check In','Screen Print','NOC'),
-- (36974,'SP Group 04 NOCF','SP Group 04','Check Out','Screen Print','NOC'),
-- (36949,'SP Group 05 NOCS','SP Group 05','Check In','Screen Print','NOC'),
-- (36973,'SP Group 05 NOCF','SP Group 05','Check Out','Screen Print','NOC'),
-- (36948,'SP Group 06 NOCS','SP Group 06','Check In','Screen Print','NOC'),
-- (36972,'SP Group 06 NOCF','SP Group 06','Check Out','Screen Print','NOC'),
-- (36947,'SP Group 07 NOCS','SP Group 07','Check In','Screen Print','NOC'),
-- (36971,'SP Group 07 NOCF','SP Group 07','Check Out','Screen Print','NOC'),
-- (36946,'SP Group 08 NOCS','SP Group 08','Check In','Screen Print','NOC'),
-- (36970,'SP Group 08 NOCF','SP Group 08','Check Out','Screen Print','NOC'),
-- (36945,'SP Group 09 NOCS','SP Group 09','Check In','Screen Print','NOC'),
-- (36969,'SP Group 09 NOCF','SP Group 09','Check Out','Screen Print','NOC'),
-- (36944,'SP Group 10 NOCS','SP Group 10','Check In','Screen Print','NOC'),
-- (36968,'SP Group 10 NOCF','SP Group 10','Check Out','Screen Print','NOC'),
-- (36943,'SP Group 11 NOCS','SP Group 11','Check In','Screen Print','NOC'),
-- (36967,'SP Group 11 NOCF','SP Group 11','Check Out','Screen Print','NOC'),
-- (36942,'SP Group 12 NOCS','SP Group 12','Check In','Screen Print','NOC'),
-- (36966,'SP Group 12 NOCF','SP Group 12','Check Out','Screen Print','NOC'),
-- (36941,'SP Group 13 NOCS','SP Group 13','Check In','Screen Print','NOC'),
-- (36965,'SP Group 13 NOCF','SP Group 13','Check Out','Screen Print','NOC'),
-- (36940,'SP Group 14 NOCS','SP Group 14','Check In','Screen Print','NOC'),
-- (36964,'SP Group 14 NOCF','SP Group 14','Check Out','Screen Print','NOC'),
-- (36939,'SP Group 15 NOCS','SP Group 15','Check In','Screen Print','NOC'),
-- (36963,'SP Group 15 NOCF','SP Group 15','Check Out','Screen Print','NOC'),
-- (36938,'SP Group 16 NOCS','SP Group 16','Check In','Screen Print','NOC'),
-- (36962,'SP Group 16 NOCF','SP Group 16','Check Out','Screen Print','NOC'),
-- (36937,'SP Group 17 NOCS','SP Group 17','Check In','Screen Print','NOC'),
-- (36961,'SP Group 17 NOCF','SP Group 17','Check Out','Screen Print','NOC'),
-- (36936,'SP Group 18 NOCS','SP Group 18','Check In','Screen Print','NOC'),
-- (36960,'SP Group 18 NOCF','SP Group 18','Check Out','Screen Print','NOC'),
-- (36935,'SP Group 19 NOCS','SP Group 19','Check In','Screen Print','NOC'),
-- (36959,'SP Group 19 NOCF','SP Group 19','Check Out','Screen Print','NOC'),
-- (36934,'SP Group 20 NOCS','SP Group 20','Check In','Screen Print','NOC'),
-- (36958,'SP Group 20 NOCF','SP Group 20','Check Out','Screen Print','NOC'),
-- (36933,'SP Group 21 NOCS','SP Group 21','Check In','Screen Print','NOC'),
-- (36957,'SP Group 21 NOCF','SP Group 21','Check Out','Screen Print','NOC'),
-- (36932,'SP Group 22 NOCS','SP Group 22','Check In','Screen Print','NOC'),
-- (36956,'SP Group 22 NOCF','SP Group 22','Check Out','Screen Print','NOC'),
-- (36931,'SP Group 23 NOCS','SP Group 23','Check In','Screen Print','NOC'),
-- (36955,'SP Group 23 NOCF','SP Group 23','Check Out','Screen Print','NOC'),
-- (36930,'SP Group 24 NOCS','SP Group 24','Check In','Screen Print','NOC'),
-- (36954,'SP Group 24 NOCF','SP Group 24','Check Out','Screen Print','NOC')

INSERT INTO [LCA].[dbo].[Addresses]
SELECT
	   AD.[AddrCategoryID]
      ,AD.[OwnerID]
      ,AD.[StatusID]
      ,AD.[SalespersonID]
      ,AD.[IsSalesPerson]
      ,AD.[IsBillTo]
      ,AD.[IsShipTo]
      ,AD.[IsShipper]
      ,AD.[IsSubcontractor]
      ,AD.[IsCutter]
      ,AD.[IsSewer]
      ,AD.[IsOutSource]
      ,AD.[IsSendOut]
      ,AD.[IsStyleDesigner]
      ,AD.[IsInsideDesigner]
      ,AD.[IsStyleDeveloper]
      ,AD.[IsStyleManager]
      ,NOS.[CompanyNumber]
    --   ,AD.[CompanyNumber]
      ,NOS.[CompanyName]
    --   ,AD.[CompanyName]
      ,AD.[ContactLastName]
      ,AD.[ContactTitle]
      ,AD.[Street]
      ,AD.[City]
      ,AD.[State]
      ,AD.[Country]
      ,AD.[ZipCode]
      ,AD.[Telephone]
      ,AD.[Fax]
      ,AD.[Email]
      ,AD.[TermsID]
      ,AD.[Comments]
      ,AD.[CustomerCategoryID]
      ,AD.[AccountingCategoryID]
      ,AD.[SalesTaxID]
      ,AD.[Street2]
      ,AD.[Telephone2]
      ,AD.[DefaultShipperID]
      ,AD.[ContactSalutation]
      ,AD.[ContactFirstName]
      ,AD.[FreightTermsID]
      ,NOS.[Comments2]
    --   ,AD.[Comments2]
      ,AD.[IsEmployee]
      ,AD.[ContactMiddleName]
      ,AD.[ContactSuffix]
      ,AD.[Street3]
      ,AD.[Street4]
      ,AD.[AttentionNote]
      ,AD.[Mobile]
      ,AD.[Pager]
      ,AD.[CreditLimit]
      ,AD.[VendorSourcingID]
      ,AD.[CountryOfOriginID]
      ,AD.[SourcingDocumentTagID]
      ,AD.[SourcingEmailRecipients]
      ,AD.[ExternalKey]
      ,AD.[ExternalEditSequence]
      ,AD.[AirTransitDays]
      ,AD.[OceanTransitDays]
      ,AD.[PortOfOriginID]
      ,AD.[OwnershipLocationID]
      ,AD.[ExFactoryLeadTime]
      ,AD.[IncrementalCMTCost]
      ,AD.[CommissionPercent]
      ,AD.[IsSourcingManager]
      ,AD.[AirportOfOriginID]
      ,AD.[IsPurchaseAgent]
      ,AD.[RegionID]
      ,AD.[IsOperator]
      ,AD.[EffectiveDate]
      ,AD.[MessageRecipientID]
      ,AD.[IsAccountManager]
      ,AD.[IsBroker]
      ,AD.[AccountManagerID]
      ,AD.[IsEdiTradePartner]
      ,AD.[IsEdiProvider]
      ,AD.[VendorCategoryID]
      ,AD.[IsResidential]
      ,AD.[IsMill]
      ,AD.[IsProjectManager]
      ,AD.[IsPurchaseRequester]
      ,AD.[IsPurchaseMaker]
      ,AD.[IsPurchaseApprover]
      ,AD.[ProjectManagerID]
      ,AD.[HasWebAccess]
      ,AD.[CurrencyID]
      ,AD.[NeedsDeclarationDocuments]
      ,AD.[NeedsDeclarationNumber]
      ,AD.[ProspectTypeID]
      ,AD.[IsReceiveClerk]
      ,AD.[IsPreliminaryApprover]
      ,AD.[ReceivePercentExtra]
      ,AD.[EnableEvents]
      ,AD.[ExternalError]
      ,AD.[Comments3]
      ,AD.[Comments4]
      ,AD.[Comments5]
      ,AD.[Comments6]
      ,AD.[ShipMethodID]
      ,AD.[IsShipFrom]
      ,AD.[EdiCarrierSCAC]
      ,AD.[EdiTransportationMethodID]
      ,AD.[DunsNumber]
      ,AD.[TaxNumber]
      ,AD.[IsRemitTo]
      ,AD.[BalanceDue]
      ,AD.[CustomerStatusID]
      ,AD.[IsTariffAuthority]
      ,AD.[IsBank]
      ,AD.[IsQALotApprover]
      ,AD.[IsPackingLine]
      ,AD.[IsBuyer]
      ,AD.[IsInspector]
      ,AD.[MakeFreightPayable]
      ,AD.[FreightVendorID]
      ,AD.[DepartmentJoinRuleID]
      ,AD.[#CompanyNumber]
      ,AD.[MinimumSizeOverage]
      ,AD.[MaximumSizeOverage]
      ,AD.[MinimumOrderOverage]
      ,AD.[MaximumOrderOverage]
      ,AD.[MarkerPlanMaximizeYield]
      ,AD.[ShipRegionID]
      ,AD.[FreightHandlingCharge]
      ,AD.[FreightChargeByWeight]
      ,AD.[FreightWeightUnitID]
      ,AD.[TradeCardMemberCode]
      ,AD.[ExpediteShipment]
      ,AD.[Longtitude]
      ,AD.[Lattitude]
      ,AD.[GeographicLevel]
      ,AD.[CMTWarehouseID]
      ,AD.[StandardUnitFreight]
      ,AD.[IsImporter]
      ,AD.[ProductionTaskName]
      ,AD.[IsScreenPrintLocation]
      ,AD.[IsEmbroideryLocation]
      ,AD.[IsSublimationLocation]
      ,AD.[IsPayTo]
      ,AD.[BillToAccountID]
      ,AD.[HighestBalanceDue]
      ,AD.[LastPaymentDate]
      ,AD.[LastPaymentAmount]
      ,AD.[CustomerCaptionID]
      ,AD.[IsInstructionSender]
      ,AD.[SalesCommissionID]
      ,AD.[TaxIDNumber]
      ,AD.[File1099Forms]
      ,AD.[AddShippingCharge]
      ,AD.[AdditionalShippingCharge]
      ,AD.[CreditHold]
      ,AD.[RequireEdiAcknowledgement]
      ,AD.[ShippingMethodID]
      ,AD.[IsGreigeVendor]
      ,AD.[DefaultGoodsUnitID]
      ,AD.[DefaultFabricWeightUnitID]
      ,AD.[DefaultFabricWidthUnitID]
      ,AD.[DefaultFabricYieldUnitID]
      ,AD.[IsYarnOrigin]
      ,AD.[DefaultCustomerOrderUnitID]
      ,AD.[InHouseVendor]
      ,AD.[IsMfgOperator]
      ,AD.[IsKnitOperator]
      ,AD.[UseShipmentProfile]
      ,AD.[DefaultBoxTypeID]
      ,AD.[LaborSubcategoryID]
      ,AD.[IsGCCTestLab]
      ,AD.[TargetWorkHours]
      ,AD.[WorkStationID]
      ,AD.[PayRate]
      ,AD.[IsTransportWorker]
      ,AD.[BadgeNumber]
      ,AD.[ProductionPlanPriorityID]
      ,AD.[BuyingGroupID]
      ,AD.[IsMaintenance]
      ,AD.[IsMaintenanceInspector]
      ,AD.[MaintenanceRate]
      ,AD.[MaintenanceWage]
      ,AD.[MaintenanceActivityID]
      ,AD.[WorkCalendarID]
      ,AD.[IsDeclarationManufacturer]
      ,AD.[CustomerProductionRuleID]
FROM [LCA].[dbo].[Addresses] AS AD WITH(NOLOCK)
INNER JOIN #New_Operators AS NOS WITH(NOLOCK) ON AD.[AddressID] = NOS.[ID]
-- AND AD.[AddressID] = 36484
RETURN


DROP TABLE IF EXISTS #TB_Operators
DROP TABLE IF EXISTS #TB_Turnos

SELECT
     [R]            = ROW_NUMBER() OVER(PARTITION BY AD.[Comments6] ORDER BY AD.[Comments6], AD.[CompanyName], AD.[Comments2], AD.[ProductionTaskName])
    ,[Area]         = AD.[Comments6]
    ,[Modulo]       = AD.[CompanyName]
    ,[TurnoPPM]     = AD.[Comments2]
    ,[TaskName]     = AD.[ProductionTaskName]
    ,[PPAD]         = 'PPAD'+Ltrim(Str(AD.[AddressID]+10000))
    -- ,[Operator]     = AD.[CompanyNumber]
    -- ,[AddressID]    = AD.[AddressID]
    -- ,[StatusID]     = AD.[StatusID]
    -- ,[NIT]          = AD.[Comments4]
INTO #TB_Operators
FROM [LCA].[dbo].[Addresses] AS AD WITH(NOLOCK)
WHERE AD.[IsOperator] = 1 AND AD.[ProductionTaskName] IN ('Check In', 'Check Out') AND AD.[StatusID] = 30

SELECT
	 [R]            = ROW_NUMBER() OVER(ORDER BY TA.[Area], TCT.[Name])
	,[area]         = TA.[area]
	,[Name]         = TCT.[Name]
	,[PPMTurno]     = TCT.[PPMTurno]
	,[StartTime]    = TCT.[StartTime]
	,[EndTime]      = TCT.[EndTime]
INTO #TB_Turnos
FROM [AppsLCA].[dbo].[TV_Cal_Turnos] AS TCT WITH(NOLOCK)
CROSS APPLY
[AppsLCA].[dbo].[TV_Areas] AS TA WITH(NOLOCK) 
WHERE TCT.[Status] = 1 AND TA.[id] IN (1,2,3,4,5)




SELECT 
   [R]            = T.[R]             
  ,[area]         = T.[area]        
  ,[Name]         = T.[Name]        
  ,[PPMTurno]     = T.[PPMTurno]    
  ,[StartTime]    = T.[StartTime]   
  ,[EndTime]      = T.[EndTime]     
  ,[Details]      = (
                        SELECT 
                           [R]         = S.[R]        
                          ,[Area]      = S.[Area]     
                          ,[Modulo]    = S.[Modulo]   
                          ,[TurnoPPM]  = S.[TurnoPPM] 
                          ,[TaskName]  = S.[TaskName] 
                          ,[PPAD]      = S.[PPAD]     
                        FROM #TB_Operators AS S
                        WHERE S.[Area] = T.[area] AND S.[TurnoPPM] = T.[PPMTurno]
                        ORDER BY S.[R]
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    )
FROM #TB_Turnos AS T
