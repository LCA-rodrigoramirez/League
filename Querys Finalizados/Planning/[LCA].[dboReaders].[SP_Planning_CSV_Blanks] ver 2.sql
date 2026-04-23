USE [LCA]
GO
/****** Object:  StoredProcedure [dboReaders].[SP_Planning_CSV_Blanks]    Script Date: 06/03/2026 07:00:08 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







-- ALTER PROCEDURE [dboReaders].[SP_Planning_CSV_Blanks]
-- (
-- 	-- Add the parameters for the function here
--      @SeasonCSV NVARCHAR(50)
--     ,@json      NVARCHAR(MAX)
    
-- )
-- AS
BEGIN
    
    SET NOCOUNT ON 

		declare @SeasonCSV as Nvarchar(50)='Blank FG'
		declare @json as nvarchar(max)

    SET @json = '[
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TSSOG-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "2BAR-TSSOG-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 240,
			"rowNumber": 27,
			"size": "ADJ",
			"style": "2BAR",
			"unitPrice": 4.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C377",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "5PTKR-C377-ADJ",
			"po": "POLCA23461-L2",
			"qty": 360,
			"rowNumber": 28,
			"size": "ADJ",
			"style": "5PTKR",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C381",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "5PTKR-C381-ADJ",
			"po": "POLCA23461-L2",
			"qty": 275,
			"rowNumber": 29,
			"size": "ADJ",
			"style": "5PTKR",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C620",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "5PTKR-C620-ADJ",
			"po": "POLCA23461-L2",
			"qty": 25,
			"rowNumber": 30,
			"size": "ADJ",
			"style": "5PTKR",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C621",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "5PTKR-C621-ADJ",
			"po": "POLCA23461-L2",
			"qty": 20,
			"rowNumber": 31,
			"size": "ADJ",
			"style": "5PTKR",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C622",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "5PTKR-C622-ADJ",
			"po": "POLCA23461-L2",
			"qty": 22,
			"rowNumber": 32,
			"size": "ADJ",
			"style": "5PTKR",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C666",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "5PTKR-C666-ADJ",
			"po": "POLCA23461-L2",
			"qty": 59,
			"rowNumber": 33,
			"size": "ADJ",
			"style": "5PTKR",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C668",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "5PTKR-C668-ADJ",
			"po": "POLCA23461-L2",
			"qty": 60,
			"rowNumber": 34,
			"size": "ADJ",
			"style": "5PTKR",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C332",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "6PTKR-C332-ADJ",
			"po": "POLCA23461-L2",
			"qty": 240,
			"rowNumber": 35,
			"size": "ADJ",
			"style": "6PTKR",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C395",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "6PTKR-C395-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 36,
			"size": "ADJ",
			"style": "6PTKR",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C60",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "6PTKR-C60-ADJ",
			"po": "POLCA23461-L2",
			"qty": 106,
			"rowNumber": 37,
			"size": "ADJ",
			"style": "6PTKR",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C67",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "6PTKR-C67-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 38,
			"size": "ADJ",
			"style": "6PTKR",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C593",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "APPRCH-C593-ADJ",
			"po": "POLCA23461-L2",
			"qty": 45,
			"rowNumber": 39,
			"size": "ADJ",
			"style": "APPRCH",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "BOC-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "ATV-BOC-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 40,
			"size": "ADJ",
			"style": "ATV",
			"unitPrice": 3.22
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "IBL-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "B9A-IBL-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 240,
			"rowNumber": 41,
			"size": "ADJ",
			"style": "B9A",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "SBL-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "B9A-SBL-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 360,
			"rowNumber": 42,
			"size": "ADJ",
			"style": "B9A",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "DAWB",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "BACKPKT-DAWB-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 43,
			"size": "ADJ",
			"style": "BACKPKT",
			"unitPrice": 3.02
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "DGDGR-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "CADDY-DGDGR-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 44,
			"size": "ADJ",
			"style": "CADDY",
			"unitPrice": 3.52
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "MMR-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "CADDY-MMR-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 45,
			"size": "ADJ",
			"style": "CADDY",
			"unitPrice": 3.52
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "NNWR-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "CADDY-NNWR-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 360,
			"rowNumber": 46,
			"size": "ADJ",
			"style": "CADDY",
			"unitPrice": 3.52
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C233",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "CAMPER-C233-ADJ",
			"po": "POLCA23461-L2",
			"qty": 360,
			"rowNumber": 47,
			"size": "ADJ",
			"style": "CAMPER",
			"unitPrice": 3.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C578",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "CAMPER-C578-ADJ",
			"po": "POLCA23461-L2",
			"qty": 46,
			"rowNumber": 48,
			"size": "ADJ",
			"style": "CAMPER",
			"unitPrice": 3.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "CHSB-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "CHILL-CHSB-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 360,
			"rowNumber": 49,
			"size": "ADJ",
			"style": "CHILL",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "DUS-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "CHILL-DUS-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 360,
			"rowNumber": 50,
			"size": "ADJ",
			"style": "CHILL",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "OLRU-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "CHILL-OLRU-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 480,
			"rowNumber": 51,
			"size": "ADJ",
			"style": "CHILL",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "RUNV-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "CHILL-RUNV-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 240,
			"rowNumber": 52,
			"size": "ADJ",
			"style": "CHILL",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "CAR-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "CUT-CAR-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 360,
			"rowNumber": 53,
			"size": "ADJ",
			"style": "CUT",
			"unitPrice": 3.62
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TEX-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "EZA-TEX-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 240,
			"rowNumber": 54,
			"size": "ADJ",
			"style": "EZA",
			"unitPrice": 2.87
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8872",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "FROSTY-8872-ONE",
			"po": "POLCA23461-L2",
			"qty": 134,
			"rowNumber": 55,
			"size": "ONE",
			"style": "FROSTY",
			"unitPrice": 4.02
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8613",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "GRNDSR-8613-ONE",
			"po": "POLCA23461-L2",
			"qty": 75,
			"rowNumber": 56,
			"size": "ONE",
			"style": "GRNDSR",
			"unitPrice": 4.47
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8666",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "GRNDSR-8666-ONE",
			"po": "POLCA23461-L2",
			"qty": 76,
			"rowNumber": 57,
			"size": "ONE",
			"style": "GRNDSR",
			"unitPrice": 4.47
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8831",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "GRNDSR-8831-ONE",
			"po": "POLCA23461-L2",
			"qty": 30,
			"rowNumber": 58,
			"size": "ONE",
			"style": "GRNDSR",
			"unitPrice": 4.47
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "THGBK-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "H7FB-THGBK-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 59,
			"size": "ADJ",
			"style": "H7FB",
			"unitPrice": 3.22
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TOB-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "H7FB-TOB-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 360,
			"rowNumber": 60,
			"size": "ADJ",
			"style": "H7FB",
			"unitPrice": 3.22
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8726",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "HIGHR-8726-ONE",
			"po": "POLCA23461-L2",
			"qty": 287,
			"rowNumber": 61,
			"size": "ONE",
			"style": "HIGHR",
			"unitPrice": 4.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8742",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "HIGHR-8742-ONE",
			"po": "POLCA23461-L2",
			"qty": 341,
			"rowNumber": 62,
			"size": "ONE",
			"style": "HIGHR",
			"unitPrice": 4.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8835",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "HIGHR-8835-ONE",
			"po": "POLCA23461-L2",
			"qty": 840,
			"rowNumber": 63,
			"size": "ONE",
			"style": "HIGHR",
			"unitPrice": 4.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8836",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "HIGHR-8836-ONE",
			"po": "POLCA23461-L2",
			"qty": 124,
			"rowNumber": 64,
			"size": "ONE",
			"style": "HIGHR",
			"unitPrice": 4.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8205",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "HIGHS-8205-ONE",
			"po": "POLCA23461-L2",
			"qty": 360,
			"rowNumber": 65,
			"size": "ONE",
			"style": "HIGHS",
			"unitPrice": 3.22
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8569",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "HIGHS-8569-ONE",
			"po": "POLCA23461-L2",
			"qty": 750,
			"rowNumber": 66,
			"size": "ONE",
			"style": "HIGHS",
			"unitPrice": 3.22
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8588",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "HIGHS-8588-ONE",
			"po": "POLCA23461-L2",
			"qty": 150,
			"rowNumber": 67,
			"size": "ONE",
			"style": "HIGHS",
			"unitPrice": 3.22
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8856",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "HIGHS-8856-ONE",
			"po": "POLCA23461-L2",
			"qty": 156,
			"rowNumber": 68,
			"size": "ONE",
			"style": "HIGHS",
			"unitPrice": 3.22
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8858",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "HIGHS-8858-ONE",
			"po": "POLCA23461-L2",
			"qty": 594,
			"rowNumber": 69,
			"size": "ONE",
			"style": "HIGHS",
			"unitPrice": 3.22
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "CABR-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "HTA-CABR-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 240,
			"rowNumber": 70,
			"size": "ADJ",
			"style": "HTA",
			"unitPrice": 3.03
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8794",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "IGRDSR-8794-ONE",
			"po": "POLCA23461-L2",
			"qty": 2,
			"rowNumber": 71,
			"size": "ONE",
			"style": "IGRDSR",
			"unitPrice": 4.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C598",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "LOCH-C598-ADJ",
			"po": "POLCA23461-L2",
			"qty": 60,
			"rowNumber": 72,
			"size": "ADJ",
			"style": "LOCH",
			"unitPrice": 4.17
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TBLO-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "LPS-TBLO-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 73,
			"size": "ADJ",
			"style": "LPS",
			"unitPrice": 2.97
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TCDG-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "LPS-TCDG-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 74,
			"size": "ADJ",
			"style": "LPS",
			"unitPrice": 2.97
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TBK-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "LTA-TBK-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 240,
			"rowNumber": 75,
			"size": "ADJ",
			"style": "LTA",
			"unitPrice": 2.72
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TMAS-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "LTA-TMAS-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 144,
			"rowNumber": 76,
			"size": "ADJ",
			"style": "LTA",
			"unitPrice": 2.72
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8855",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "MAINER-8855-ONE",
			"po": "POLCA23461-L2",
			"qty": 49,
			"rowNumber": 77,
			"size": "ONE",
			"style": "MAINER",
			"unitPrice": 3.82
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "DGY-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "MPS-DGY-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 78,
			"size": "ADJ",
			"style": "MPS",
			"unitPrice": 3.17
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TARMRB-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "MPS-TARMRB-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 79,
			"size": "ADJ",
			"style": "MPS",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TMMN-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "MPS-TMMN-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 80,
			"size": "ADJ",
			"style": "MPS",
			"unitPrice": 3.02
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TMSCW-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "MPS-TMSCW-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 480,
			"rowNumber": 81,
			"size": "ADJ",
			"style": "MPS",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TPSES-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "MPS-TPSES-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 240,
			"rowNumber": 82,
			"size": "ADJ",
			"style": "MPS",
			"unitPrice": 3.02
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TVON-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "MPS-TVON-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 144,
			"rowNumber": 83,
			"size": "ADJ",
			"style": "MPS",
			"unitPrice": 3.02
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TWNV-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "MPS-TWNV-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 360,
			"rowNumber": 84,
			"size": "ADJ",
			"style": "MPS",
			"unitPrice": 3.02
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C659",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "NELSON-C659-ADJ",
			"po": "POLCA23461-L2",
			"qty": 57,
			"rowNumber": 85,
			"size": "ADJ",
			"style": "NELSON",
			"unitPrice": 3.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8594",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "NORTH-8594-ONE",
			"po": "POLCA23461-L2",
			"qty": 104,
			"rowNumber": 86,
			"size": "ONE",
			"style": "NORTH",
			"unitPrice": 4.02
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8755",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "NORTH-8755-ONE",
			"po": "POLCA23461-L2",
			"qty": 750,
			"rowNumber": 87,
			"size": "ONE",
			"style": "NORTH",
			"unitPrice": 4.02
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "EDGW-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "REMPA-EDGW-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 88,
			"size": "ADJ",
			"style": "REMPA",
			"unitPrice": 3.72
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "ENAV-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "REMPA-ENAV-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 240,
			"rowNumber": 89,
			"size": "ADJ",
			"style": "REMPA",
			"unitPrice": 3.72
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "NCD-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "REMPA-NCD-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 90,
			"size": "ADJ",
			"style": "REMPA",
			"unitPrice": 3.72
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "KHC-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "ROADIE-KHC-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 480,
			"rowNumber": 91,
			"size": "ADJ",
			"style": "ROADIE",
			"unitPrice": 3.22
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "OCEC-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "ROADIE-OCEC-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 240,
			"rowNumber": 92,
			"size": "ADJ",
			"style": "ROADIE",
			"unitPrice": 3.22
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TBLWR-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "Roadie-TBLWR-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 240,
			"rowNumber": 93,
			"size": "ADJ",
			"style": "Roadie",
			"unitPrice": 3.22
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "PL-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "SKULLY-PL-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 94,
			"size": "ADJ",
			"style": "SKULLY",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "RUS-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "SKULLY-RUS-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 360,
			"rowNumber": 95,
			"size": "ADJ",
			"style": "SKULLY",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "TG-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "SKULLY-TG-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 96,
			"size": "ADJ",
			"style": "SKULLY",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C609-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "SWTBK-C609-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 22,
			"rowNumber": 97,
			"size": "ADJ",
			"style": "SWTBK",
			"unitPrice": 3.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C610-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "SWTBK-C610-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 60,
			"rowNumber": 98,
			"size": "ADJ",
			"style": "SWTBK",
			"unitPrice": 3.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C611-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "SWTBK-C611-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 34,
			"rowNumber": 99,
			"size": "ADJ",
			"style": "SWTBK",
			"unitPrice": 3.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C612-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "SWTBK-C612-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 75,
			"rowNumber": 100,
			"size": "ADJ",
			"style": "SWTBK",
			"unitPrice": 3.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "DGR-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "TTA-DGR-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 360,
			"rowNumber": 101,
			"size": "ADJ",
			"style": "TTA",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "DUS-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "TTA-DUS-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 600,
			"rowNumber": 102,
			"size": "ADJ",
			"style": "TTA",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "KHA-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "TTA-KHA-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 240,
			"rowNumber": 103,
			"size": "ADJ",
			"style": "TTA",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "KHB",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "TTA-KHB-ADJ",
			"po": "POLCA23461-L2",
			"qty": 240,
			"rowNumber": 104,
			"size": "ADJ",
			"style": "TTA",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "KHNR",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "TTA-KHNR-ADJ",
			"po": "POLCA23461-L2",
			"qty": 240,
			"rowNumber": 105,
			"size": "ADJ",
			"style": "TTA",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "KHSB",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "TTA-KHSB-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 106,
			"size": "ADJ",
			"style": "TTA",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "HONY-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "TTA-HONY-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 480,
			"rowNumber": 107,
			"size": "ADJ",
			"style": "TTA",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "LSP-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "TTA-LSP-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 360,
			"rowNumber": 108,
			"size": "ADJ",
			"style": "TTA",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "MAB-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "TTA-MAB-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 120,
			"rowNumber": 109,
			"size": "ADJ",
			"style": "TTA",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "SBA-F",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "TTA-SBA-F-ADJ",
			"po": "POLCA23461-L2",
			"qty": 360,
			"rowNumber": 110,
			"size": "ADJ",
			"style": "TTA",
			"unitPrice": 3.12
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C520",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "WILSON-C520-ADJ",
			"po": "POLCA23461-L2",
			"qty": 288,
			"rowNumber": 111,
			"size": "ADJ",
			"style": "WILSON",
			"unitPrice": 3.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C523",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "WILSON-C523-ADJ",
			"po": "POLCA23461-L2",
			"qty": 75,
			"rowNumber": 112,
			"size": "ADJ",
			"style": "WILSON",
			"unitPrice": 3.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C557",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "WILSON-C557-ADJ",
			"po": "POLCA23461-L2",
			"qty": 6,
			"rowNumber": 113,
			"size": "ADJ",
			"style": "WILSON",
			"unitPrice": 3.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C558",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "WILSON-C558-ADJ",
			"po": "POLCA23461-L2",
			"qty": 52,
			"rowNumber": 114,
			"size": "ADJ",
			"style": "WILSON",
			"unitPrice": 3.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C631",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "WILSON-C631-ADJ",
			"po": "POLCA23461-L2",
			"qty": 7,
			"rowNumber": 115,
			"size": "ADJ",
			"style": "WILSON",
			"unitPrice": 3.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "C632",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "WILSON-C632-ADJ",
			"po": "POLCA23461-L2",
			"qty": 3,
			"rowNumber": 116,
			"size": "ADJ",
			"style": "WILSON",
			"unitPrice": 3.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "CY101",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "Y5PTKR-CY101-ADJ",
			"po": "POLCA23461-L2",
			"qty": 14,
			"rowNumber": 117,
			"size": "ADJ",
			"style": "Y5PTKR",
			"unitPrice": 3.57
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "CY32",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "Y5PTKR-CY32-ADJ",
			"po": "POLCA23461-L2",
			"qty": 111,
			"rowNumber": 118,
			"size": "ADJ",
			"style": "Y5PTKR",
			"unitPrice": 3.57
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "CY38",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "Y5PTKR-CY38-ADJ",
			"po": "POLCA23461-L2",
			"qty": 284,
			"rowNumber": 119,
			"size": "ADJ",
			"style": "Y5PTKR",
			"unitPrice": 3.57
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "CY95",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "Y5PTKR-CY95-ADJ",
			"po": "POLCA23461-L2",
			"qty": 46,
			"rowNumber": 120,
			"size": "ADJ",
			"style": "Y5PTKR",
			"unitPrice": 3.57
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "CY99",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "Y5PTKR-CY99-ADJ",
			"po": "POLCA23461-L2",
			"qty": 7,
			"rowNumber": 121,
			"size": "ADJ",
			"style": "Y5PTKR",
			"unitPrice": 3.57
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "CY107",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "YCMPR-CY107-ADJ",
			"po": "POLCA23461-L2",
			"qty": 5,
			"rowNumber": 122,
			"size": "ADJ",
			"style": "YCMPR",
			"unitPrice": 3.27
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8648",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "YGRDSR-8648-ONE",
			"po": "POLCA23461-L2",
			"qty": 14,
			"rowNumber": 123,
			"size": "ONE",
			"style": "YGRDSR",
			"unitPrice": 4.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8875",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "YGRDSR-8875-ONE",
			"po": "POLCA23461-L2",
			"qty": 712,
			"rowNumber": 124,
			"size": "ONE",
			"style": "YGRDSR",
			"unitPrice": 4.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "8876",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "YGRDSR-8876-ONE",
			"po": "POLCA23461-L2",
			"qty": 811,
			"rowNumber": 125,
			"size": "ONE",
			"style": "YGRDSR",
			"unitPrice": 4.32
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "CY109",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "YWILSON-CY109-ADJ",
			"po": "POLCA23461-L2",
			"qty": 11,
			"rowNumber": 126,
			"size": "ADJ",
			"style": "YWILSON",
			"unitPrice": 3.27
		},
		{
			"cancelDate": "2026-04-05T00:00:00.000Z",
			"color": "CY110",
			"dudeDate": "2026-03-27T00:00:00.000Z",
			"fullValue": "YWILSON-CY110-ADJ",
			"po": "POLCA23461-L2",
			"qty": 9,
			"rowNumber": 127,
			"size": "ADJ",
			"style": "YWILSON",
			"unitPrice": 3.27
		}
	]'


    SET @json = REPLACE(@json,'/','');
	SET @json = REPLACE(@json,'\','/');
    SET @json = SUBSTRING(@json, 2, len(@json))  
    SET @json = SUBSTRING(@json, 1, len(@json)-1)  
    SET @json = CONCAT('[',@json,']')
    -- SET @json = SUBSTRING(@json, 2, len(@json))  
    -- select @json
    -- SET @json = REPLACE(@json,',',CONCAT(char(13),','));

    DECLARE @VJson AS NVARCHAR(MAX)
    SET @VJson = (SELECT JSON_MODIFY(@json,'$.rowNumber',NULL) AS 'Updated JSON'   )

-- SELECT @VJson 

    -----------INGRESAMOS LOS DATOS DEL JSON EN UNA TABLA
    DECLARE @Table_JSON AS TABLE (
         [rowNumber]        INT           NULL  
        ,[style]            NVARCHAR(50)  NULL 
        ,[color]            NVARCHAR(50)  NULL 
        ,[size]             NVARCHAR(10)  NULL 
        ,[qty]              INT           NULL 
        ,[po]               NVARCHAR(50)  NULL 
        ,[MO]               NVARCHAR(50)  NULL 
        ,[dudeDate]         DATETIME      NULL 
        ,[cancelDate]       DATETIME      NULL 
        ,[Make]             INT           NULL

        ,[Recommended]      INT           NULL
        ,[Min]              INT           NULL
        ,[Max]              INT           NULL
        ,[PARTICIONAR]      INT           NULL
        
        ,[UnitPrice]        FLOAT NULL
        ,[Season]           NVARCHAR(50)  NULL 

        ,[Season_Dat]       INT           NULL
        ,[Color_Dat]        INT           NULL
        ,[Price_Dat]        INT           NULL
    )

SELECT   
									 1 AS [rowNumber]  
									,[style]      
									,[color]   
									,[size]       
									-- ,[UnitPrice]           
									,[qty]        
									,REPLACE([po],' ','')                                   AS [po]
									,CONCAT(REPLACE([po],' ',''),'-',[style],'-',[color])   AS [MO]
									,[dudeDate]   
									,[cancelDate] 
									,[FullValue]
									--,[Make]	= SUM([qty]) OVER(PARTITION BY [po],[style],[color])
								FROM OPENJSON(@VJson)
								WITH (
									--  [rowNumber]     INT             'strict $.rowNumber'
									 [style]         NVARCHAR(50)    'strict $.style'
									,[color]         NVARCHAR(50)    'strict $.color'
									,[size]          NVARCHAR(10)    'strict $.size'
									-- ,[UnitPrice]     FLOAT           'strict $.unitPrice'
									,[qty]           INT             'strict $.qty'
									,[po]            NVARCHAR(50)    'strict $.po'
									,[dudeDate]      DATETIME        'strict $.dudeDate'
									,[cancelDate]    DATETIME        'strict $.cancelDate'
									,[FullValue]     NVARCHAR(100)   'strict $.fullValue'
									)
    -- INSERT INTO @Table_JSON(
    --      [rowNumber]  
    --     ,[style]      
    --     ,[color]      
    --     ,[size]       
    --     ,[qty]        
    --     ,[po]         
    --     ,[MO]         
    --     ,[dudeDate]   
    --     ,[cancelDate] 
    --     ,[Make]      

    --     ,[Recommended]
    --     ,[Min]        
    --     ,[Max]        
    --     ,[PARTICIONAR] 
    --     ,[UnitPrice]
    --     ,[Season]

    --     ,[Season_Dat]
    --     ,[Color_Dat]
    --     ,[Price_Dat]
    -- )
    -- (
        SELECT
             TB_JSON.[rowNumber]  
            ,TB_JSON.[style]      
			,TB_JSON.[color]
    --        ,case 
				--when charindex ('-f',TB_JSON.[color] )>0
				--	then  substring(TB_JSON.[color],1,charindex ('-f',TB_JSON.[color])-1)
				--	else TB_JSON.[color]
			 --end as Color
			,TB_JSON.[size]       
            ,TB_JSON.[qty]        
            ,TB_JSON.[po]  
            ,TB_JSON.[MO]
            ,TB_JSON.[dudeDate]
            ,TB_JSON.[cancelDate]
            --,TB_JSON.[Make]
			,SUM(TB_JSON.qty) OVER(PARTITION BY TB_JSON.po, TB_JSON.style , TB_JSON.color) AS Make

            ----CAMBIO SOLICITADO POR ROGELIO ALVAREZ 08 NOVIEMBRE 2022
            ----YA NO SE TOMA EL MINIMO SINO EL RECOMENDADO                  
            ,ISNULL(unit.[Recommended],0)     AS [Recommended] 
            -- ,ISNULL(unit.[Min],0)               AS [Min]
            ,ISNULL(unit.[Recommended],0)     AS [Min]
            ,ISNULL(unit.[Max],0)             AS [Max]
            ,CASE 
                WHEN (unit.[Style] IS NULL) THEN 0
                ELSE 1
                END                                 AS [PARTICIONAR]
            ,ISNULL(TB_Price.[BlankPrice] ,0)       AS [UnitPrice]
            ,StSn.SeasonPPM                         AS [Season]
            
            ,CASE 
                WHEN (StSn.Style IS NULL) THEN 0
                ELSE 1
                END                                 AS [Season_Dat]

            ,CASE 
                WHEN (StCo.Style IS NULL) THEN 0
                ELSE 1
                END                                 AS [Color_Dat]
            
            ,CASE 
                WHEN (TB_Price.Style IS NULL) THEN 0
                ELSE 1
                END                                 AS [Price_Dat]
			--,concat(StCo.Style, ' ' ,StCo.Season,' ', StCo.Color) as  TB_StCo
        FROM
			(
					SELECT [RowNumber], LCA_L2B.Style 
					,LCA_L2B.color as [Color]
					,LCA_L2B.size, TB_JSON_OLD.qty, TB_JSON_OLD.po, TB_JSON_OLD.MO, 
					 TB_JSON_OLD.dudeDate, TB_JSON_OLD.cancelDate, TB_JSON_OLD.FullValue
						--, [Make] 
						from 
							(
									SELECT   
									 1 AS [rowNumber]  
									,[style]      
									,[color]   
									,[size]       
									-- ,[UnitPrice]           
									,[qty]        
									,REPLACE([po],' ','')                                   AS [po]
									,CONCAT(REPLACE([po],' ',''),'-',[style],'-',[color])   AS [MO]
									,[dudeDate]   
									,[cancelDate] 
									,[FullValue]
									--,[Make]	= SUM([qty]) OVER(PARTITION BY [po],[style],[color])
								FROM OPENJSON(@VJson)
								WITH (
									--  [rowNumber]     INT             'strict $.rowNumber'
									 [style]         NVARCHAR(50)    'strict $.style'
									,[color]         NVARCHAR(50)    'strict $.color'
									,[size]          NVARCHAR(10)    'strict $.size'
									-- ,[UnitPrice]     FLOAT           'strict $.unitPrice'
									,[qty]           INT             'strict $.qty'
									,[po]            NVARCHAR(50)    'strict $.po'
									,[dudeDate]      DATETIME        'strict $.dudeDate'
									,[cancelDate]    DATETIME        'strict $.cancelDate'
									,[FullValue]     NVARCHAR(100)   'strict $.fullValue'
									)
							) as TB_JSON_OLD

						--Cambio realizado por BH, 2026- 03 03 para enviar los InvItemID de L2B desde la vista de Appslca
						left outer join lca.dbo.styles as Styles90 with (nolock) 
							on TB_JSON_OLD.style =Styles90.StyleNumber 

						left outer join appslca.legacycaps.VW_LCA_L2B_InventoryID as LCA_L2B with (nolock) 
							on TB_JSON_OLD.FullValue = LCA_L2B.InvItemID
							/* Se añade relación con Style debido a que el archivo descargaba otros estilos que no estaban en el archivo subido, porque reciben
							prendas (blanks) de estilos que si están en el archivo RR 2026-03-06*/
							and TB_JSON_OLD.style = LCA_L2B.Style

						left outer join lca.dbo.Seasons with (nolock)
						    on Styles90.SeasonID = Seasons.SeasonID 
						where   Seasons.SeasonName=@SeasonCSV 
								and Styles90.StatusID=64

			) AS TB_JSON

        LEFT OUTER JOIN AppsLCA.dbo.UnitsPerStyleAndSew     AS unit WITH (NOLOCK) ON unit.Style = TB_JSON.style
        LEFT OUTER JOIN [dboReaders].[VW_Planning_Styles]   AS StSn WITH (NOLOCK) ON StSn.Style = TB_JSON.style 
                                                                                        AND StSn.Season = @SeasonCSV
        LEFT OUTER JOIN [dboReaders].[VW_Planning_StylesAndColors]   AS StCo WITH (NOLOCK) ON StCo.Style = TB_JSON.style 
                                                                                        AND StCo.Season  = @SeasonCSV
                                                                                        AND StCo.Color   = TB_JSON.color
		--select * from [dboReaders].[VW_Planning_StylesAndColors] where season= 'BLANK RO' AND 
		--STYLE='NDS150' order by color

        LEFT OUTER JOIN ( 
                            SELECT 
                                [Style]
                                ,[Color]
                                ,[Season]
                                ,[BlankPrice]
                            FROM(
                            SELECT 
                                [Style]
                                ,[Color]
                                ,[Season]
                                ,[CostBlank]    AS [BlankPrice]
                                ,ROW_NUMBER() OVER(PARTITION BY [Style],[Color] ORDER BY [Style],[Color]) AS [RowN]
                            FROM OPENQUERY(MARIADB,'SELECT * FROM `wordpress`.`Sales_Prices_New`
                                WHERE ( 
                                        NOT(Season IN (''BLANK'',''BLANK FG'',''EXP BO'',''EMB'',''EMB FG'',''EMB Cost'')) OR  Season is null )' )
                            ) AS TB_PriceMDB
                            WHERE TB_PriceMDB.[RowN] = 1
                        ) AS TB_Price   ON TB_Price.Style = TB_JSON.style AND TB_Price.Color   = TB_JSON.color

			
        WHERE TB_JSON.[qty] > 0 
		   --and TB_JSON.color in ('DSTSGH','CHH','MCLYH')
		   --and StCo.Style IS NULL
    -- )

	--SELECT * FROM @Table_JSON  
	return



    DECLARE @Count_NoInTableUnitsPerStyleAndSew AS INT
    SET @Count_NoInTableUnitsPerStyleAndSew = (SELECT COUNT(*) FROM @Table_JSON WHERE [PARTICIONAR] = 0)
    
    DECLARE @Count_NoInVWPlanningStyles AS INT
    SET @Count_NoInVWPlanningStyles = (SELECT COUNT(*) FROM @Table_JSON WHERE [Season_Dat] = 0)

    DECLARE @Count_NoInVWPlanningStylesAndColors AS INT
    SET @Count_NoInVWPlanningStylesAndColors = (SELECT COUNT(*) FROM @Table_JSON WHERE [Color_Dat] = 0)

    DECLARE @Count_NoInTB_PriceMDB AS INT
    SET @Count_NoInTB_PriceMDB = 0 -- Eliminado temporalmente por Boris Herndandez Ago 19 2022 (SELECT COUNT(*) FROM @Table_JSON WHERE [Price_Dat] = 0)


 --   SELECT @Count_NoInTableUnitsPerStyleAndSew 
	--SELECT @Count_NoInVWPlanningStyles 
	--SELECT @Count_NoInVWPlanningStylesAndColors 
	--SELECT @Count_NoInTB_PriceMDB 


    IF (   
                (
                        (    @SeasonCSV = 'EMB FG'
                        OR @SeasonCSV = 'BLANK FG')
                        AND @Count_NoInVWPlanningStyles             = 0
                        AND @Count_NoInVWPlanningStylesAndColors    = 0
                )
                OR
                (       ( @SeasonCSV <> 'EMB FG'
                        AND @SeasonCSV <> 'BLANK FG')
                    AND @Count_NoInTableUnitsPerStyleAndSew     = 0 
                    AND @Count_NoInTB_PriceMDB                  = 0
                    AND @Count_NoInVWPlanningStyles             = 0
                    AND @Count_NoInVWPlanningStylesAndColors    = 0
                        
                )
        )
    -----EMPIEZA IF @Count_NoInTableUnitsPerStyleAndSew
    BEGIN   
        DECLARE @TableMOS_ALLDATA AS TABLE(
             [MO]               NVARCHAR(50)    NULL
            ,[PONumber]         NVARCHAR(50)    NULL
            ,[Style]            NVARCHAR(50)    NULL
            ,[Color]            NVARCHAR(50)    NULL
            ,[Make]             INT             NULL
            ,[Size]             NVARCHAR(50)    NULL
            ,[Quantity]         INT             NULL
            ,[Recommended]      INT             NULL
            ,[Min]              INT             NULL
            ,[Max]              INT             NULL
            ,[dudeDate]         DATETIME        NULL
            ,[cancelDate]       DATETIME        NULL
            ,[Final_NMos_Orig]  INT             NULL
            ,[UnitsPorcSize]    INT             NULL

            ,[TotalQuantity]    INT             NULL
            ,[RowSize]          INT             NULL
            ,[UnitPrice]        FLOAT           NULL
            
            ,[Season]           NVARCHAR(50)    NULL
        )


        INSERT INTO @TableMOS_ALLDATA(
             [MO]             
            ,[PONumber]       
            ,[Style]          
            ,[Color]          
            ,[Make]           
            ,[Size]           
            ,[Quantity]       
            ,[Recommended]    
            ,[Min]            
            ,[Max]            
            ,[dudeDate]       
            ,[cancelDate]     
            ,[Final_NMos_Orig]
            ,[UnitsPorcSize]  
            ,[TotalQuantity]
            ,[RowSize]
            ,[UnitPrice]
            ,[Season]
        )(
            SELECT
                 [MO]
                ,[PONumber]
                ,[Style]
                ,[Color]
                ,[Make]
                ,[Size]
                ,[Quantity]
                ,[Recommended]
                ,[Min]
                ,[Max]
                ,[dudeDate]
                ,[cancelDate]
                ,[Final_NMos_Orig]
                ,[UnitsPorcSize]
                ,[Quantity]                                 AS [TotalQuantity]
                ,ROW_NUMBER() OVER (PARTITION BY [MO]
                                    ORDER BY [MO],[Size])   AS [RowSize] 
                ,[UnitPrice]
                ,[Season]
            FROM
            (
                SELECT
                    TB5.*
                    ,([UnitxSizeMO_1] * [Final_NMos_1])                     AS [TotalQuantitySize]
                    ,[Quantity] - ([UnitxSizeMO_1] * [Final_NMos_1])        AS [DIFF]
                    
                FROM(
                    SELECT
                        TB4.*
                        ,CASE 
                            WHEN ([UnitxSizeMO_1] * [Final_NMos_Orig]) < [Make] 
                                    AND [Final_NMos_Orig] >0 THEN
                                [Final_NMos_Orig] - 1 
                            ELSE
                                [Final_NMos_Orig]      END    AS [Final_NMos_1]
                    FROM(
                        SELECT 
                            TB3.*
                            ,CASE WHEN [MinE] = 0 THEN 0 
                            ELSE CAST(([Make]  / [Sum_UnitxSizeMO_1]) AS INTEGER) END AS [Final_NMos_Orig]
                        FROM(
                            SELECT 
                                TB2.*
                                ,[Sum_UnitxSizeMO_1]	= SUM([UnitxSizeMO_1]) 
                                    OVER(PARTITION BY [MO])
                            FROM(
                                SELECT 
                                    TB1.*
                                    ,CASE WHEN [MinE] = 0 THEN 0 
                                    ELSE 
                                    CEILING(([UnitsPorcSize] / [MinE]))  END          AS [RatioSize]
                                    ,CASE WHEN [MinE] = 0 THEN 0 
                                    ELSE 
                                    ROUND(
                                        (
                                            CEILING(([UnitsPorcSize] / [MinE]))
                                            * [MinE]
                                        ),0)                                          END      AS [UnitxSizeMO_1]
                                FROM(
                                    SELECT 
                                        TB0.*
                                        ,CEILING(([Porc_Ratio] * [Quantity]))        AS [UnitsPorcSize]  ---RATIO / unitSize
                                        ,[MinE]	= MIN(ROUND(([Porc_Ratio] * [QuantityMinE]),0)) 
                                            OVER(PARTITION BY [MO])
                                    FROM (
                                        SELECT 
                                            TB_JSON_DATA.[MO]                AS [MO]
                                            ,TB_JSON_DATA.[po]                AS [PONumber]
                                            ,TB_JSON_DATA.[style]             AS [Style]
                                            ,TB_JSON_DATA.[color]             AS [Color]
                                            ,TB_JSON_DATA.[Make]              AS [Make]
                                            ,TB_JSON_DATA.[size]              AS [Size]
                                            ,TB_JSON_DATA.[qty]               AS [Quantity]
                                            ,TB_JSON_DATA.[Recommended]       AS [Recommended]                   
                                            ,TB_JSON_DATA.[Min]               AS [Min]
                                            ,TB_JSON_DATA.[Max]               AS [Max]
                                            ,TB_JSON_DATA.[dudeDate]          AS [dudeDate]   
                                            ,TB_JSON_DATA.[cancelDate]        AS [cancelDate] 
                                        ----MINIMO.
                                            ,CASE 
                                                WHEN ISNULL(TB_JSON_DATA.[Min],0) = 0 THEN 0
                                                ELSE
                                                    CAST(TB_JSON_DATA.[Make]  /ISNULL(TB_JSON_DATA.[Min],0) AS INTEGER)  
                                                END                                             AS [NMos] ---CEILING( MAKE / MIN)
                                                ,(CAST(ISNULL(TB_JSON_DATA.[Min],0)AS FLOAT) / CAST(TB_JSON_DATA.[Make] AS FLOAT))      AS [Porc_Ratio] ---MIN / MAKE
                                        
                                            ,CASE 
                                                WHEN TB_JSON_DATA.[Size] IN ('XS','S','M','L','XL','2XL','3XL','4XL','5XL','6XL','2T','3T','4T','5T','6T','7T','8T','ADJ','S_M','L_XL','S/M','L/XL','ONE') 
                                                THEN TB_JSON_DATA.[qty] 
                                            ELSE 0 END [QuantityMinE]
                                            ,CASE WHEN (TB_JSON_DATA.[Make] >= TB_JSON_DATA.[Max] OR TB_JSON_DATA.[Max] IS NULL) THEN 1
                                                ELSE 0
                                                END     AS [PARTICIONAR]
                                            ,TB_JSON_DATA.[UnitPrice]
                                            ,TB_JSON_DATA.[Season]
                                        FROM @Table_JSON AS TB_JSON_DATA
                
                                    ) AS TB0
                                ) AS TB1
                            ) AS TB2
                        ) AS TB3
                    ) AS TB4
                ) AS TB5
            ) AS TB_WHILE
        )


   --      SELECT * FROM @TableMOS_ALLDATA
		 --return

            -- END
            -- MEMIIN
        DECLARE @TableRepeat AS TABLE( 
             [MO]               NVARCHAR(50)    NULL
            ,[PONumber_ORIG]    NVARCHAR(50)    NULL
            ,[PONumber]         NVARCHAR(50)    NULL
            ,[Style]            NVARCHAR(50)    NULL
            ,[Color]            NVARCHAR(50)    NULL
            ,[Size]             NVARCHAR(10)    NULL
            ,[Quantity]         INT             NULL
            ,[Repeat]           INT             NULL
            ,[dudeDate]         DATETIME        NULL
            ,[cancelDate]       DATETIME        NULL
            ,[UnitPrice]        FLOAT           NULL
            ,[Season]           NVARCHAR(50)    NULL
        )

        
        DECLARE @TableMOS AS TABLE(
             [MO]               NVARCHAR(50)    NULL
            ,[PONumber]         NVARCHAR(50)    NULL
            ,[RowN]             INT             NULL
            ,[Style]            NVARCHAR(50)    NULL
            ,[Color]            NVARCHAR(50)    NULL
            ,[dudeDate]         DATETIME        NULL
            ,[cancelDate]       DATETIME        NULL
            ,[TotalMO]          INT             NULL
        )


        INSERT INTO @TableMOS(
             [MO]      
            ,[PONumber]
            ,[RowN]
            ,[Style]     
            ,[Color]     
            ,[dudeDate]  
            ,[cancelDate]
            ,[TotalMO]
        )
        (
            SELECT 
                 [MO]      
                ,[PONumber]
                ,ROW_NUMBER() OVER (ORDER BY [MO],[PONumber]) AS [RowN]
                ,[Style]     
                ,[Color]     
                ,[dudeDate]  
                ,[cancelDate]
                ,SUM([Quantity])    AS [TotalMO]
            FROM @TableMOS_ALLDATA
            GROUP BY
                 [MO]      
                ,[PONumber]
                ,[Style]     
                ,[Color]     
                ,[dudeDate]  
                ,[cancelDate]
        )
        -- SELECT * FROM @TableMOS

        IF @SeasonCSV = 'Blank RO' OR @SeasonCSV = 'BLANK' OR @SeasonCSV = 'FULL'
        BEGIN ---BEGIN IF SEASONCSV
            DECLARE @i_while1           AS INT
            DECLARE @t_while1           AS INT

            DECLARE @t_while2           AS INT
            DECLARE @i_while2           AS INT

            SET @i_while1 = 1
            SET @t_while1 = (SELECT MAX([RowN]) FROM @TableMOS)

            DECLARE @MO_while           AS NVARCHAR(50)
            DECLARE @PONumber_while     AS NVARCHAR(50)

            DECLARE @TotalQuantity      AS INT
            DECLARE @RestQuantity       AS INT
            DECLARE @qty_size           AS INT
            DECLARE @Size_Size          AS NVARCHAR(10)
            DECLARE @UnitPrice_Size     AS FLOAT
            DECLARE @Season_Size        AS NVARCHAR(50)

            DECLARE @RepMOS             AS INT
        
            DECLARE @FLAG_FINISH        AS INT


            -- SELECT * FROM @TableMOS
            WHILE (@i_while1 <= @t_while1 )
            BEGIN
                SET @MO_while               = (SELECT TOP 1 [MO]        FROM @TableMOS  WHERE [RowN] = @i_while1 )
                SET @PONumber_while         = (SELECT TOP 1 [PONumber]  FROM @TableMOS  WHERE [RowN] = @i_while1 )
                
                
                -- PRINT CONCAT('MO_while:',@MO_while ,'i_while1:' ,@i_while1 ,char(13))

                SET @i_while2 = 1
                SET @t_while2               = (SELECT MAX([RowSize])    FROM @TableMOS_ALLDATA  WHERE [MO] = @MO_while  )
                
                WHILE (@i_while2 <= @t_while2 )
                BEGIN    
                    -- PRINT CONCAT('MO_while:',@MO_while ,'i_while1:' ,@i_while1 ,char(13))
                    SET @TotalQuantity      = (  SELECT [TotalQuantity] FROM @TableMOS_ALLDATA  WHERE [MO] = @MO_while AND [RowSize] = @i_while2)
                    SET @qty_size           = (  SELECT [UnitsPorcSize] FROM @TableMOS_ALLDATA  WHERE [MO] = @MO_while AND [RowSize] = @i_while2)
                    SET @Size_Size          = (  SELECT [Size]          FROM @TableMOS_ALLDATA  WHERE [MO] = @MO_while AND [RowSize] = @i_while2)
                    SET @UnitPrice_Size     = (  SELECT [UnitPrice]     FROM @TableMOS_ALLDATA  WHERE [MO] = @MO_while AND [RowSize] = @i_while2)
                    SET @Season_Size        = (  SELECT [Season]        FROM @TableMOS_ALLDATA  WHERE [MO] = @MO_while AND [RowSize] = @i_while2)

                    SET @RestQuantity       = 0
                    SET @RepMOS             = 1
                    SET @FLAG_FINISH        = 0

                    WHILE ((@RestQuantity <= @TotalQuantity) AND  (@FLAG_FINISH = 0))
                    BEGIN
                        IF ( ( @RestQuantity + @qty_size) <=  @TotalQuantity)
                        BEGIN
                            -- PRINT CONCAT(@MO_while,'-',CAST(@RepMOS AS VARCHAR),' :',@qty_size )
                            INSERT INTO @TableRepeat ( 
                                [MO]      
                                ,[PONumber_ORIG]
                                ,[PONumber]
                                ,[Style]     
                                ,[Color]  
                                ,[Size]    
                                ,[Quantity] 
                                ,[Repeat]   
                                ,[dudeDate]  
                                ,[cancelDate]
                                ,[UnitPrice]
                                ,[Season]
                                )
                                (
                                    SELECT 
                                        [MO]      
                                        ,[PONumber] AS [PONumber_ORIG]
                                        ,CONCAT(@PONumber_while,'_',FORMAT(@RepMOS, '000')) AS [PONumber]
                                        -- ,@PONumber_while    AS [PONumber]
                                        -- ,[RowN]
                                        ,[Style]     
                                        ,[Color]  
                                        ,@Size_Size AS [Size]    
                                        ,@qty_size  AS [Quantity] 
                                        ,@RepMOS AS [Repeat]   
                                        ,[dudeDate]  
                                        ,[cancelDate]
                                        ,@UnitPrice_Size    AS [UnitPrice]
                                        ,@Season_Size       AS [Season]
                                    FROM @TableMOS 
                                    WHERE [RowN] = @i_while1
                                )
                                
                            SET @RestQuantity = @RestQuantity + @qty_size
                        END
                        ELSE
                        BEGIN
                            SET @FLAG_FINISH = 1
                            -- PRINT CONCAT(@MO_while,'-',CAST(@RepMOS AS VARCHAR),' :',(@TotalQuantity - @RestQuantity) )
                            INSERT INTO @TableRepeat ( 
                                [MO]      
                                ,[PONumber_ORIG]
                                ,[PONumber]
                                ,[Style]     
                                ,[Color]  
                                ,[Size]    
                                ,[Quantity] 
                                ,[Repeat]   
                                ,[dudeDate]  
                                ,[cancelDate]
                                ,[UnitPrice]
                                ,[Season]
                                )
                                (
                                    SELECT 
                                        [MO]      
                                        ,[PONumber] AS [PONumber_ORIG]
                                        ,CONCAT(@PONumber_while,'_',FORMAT(@RepMOS, '000')) AS [PONumber]
                                        -- ,@PONumber_while    AS [PONumber]

                                        -- ,[RowN]
                                        ,[Style]     
                                        ,[Color]  
                                        ,@Size_Size                         AS [Size]    
                                        ,(@TotalQuantity - @RestQuantity)   AS [Quantity] 
                                        ,@RepMOS AS [Repeat]   
                                        ,[dudeDate]  
                                        ,[cancelDate]
                                        ,@UnitPrice_Size    AS [UnitPrice]
                                        ,@Season_Size       AS [Season]
                                    FROM @TableMOS 
                                    WHERE [RowN] = @i_while1
                                )
                        END
                        
                        SET @RepMOS = @RepMOS + 1
                    END
                    SET @i_while2 = @i_while2 + 1 
                END
        
                
                SET @i_while1 = @i_while1 + 1 
            END ---END WHILE
       END ---END IF SEASONCSV
            --    SELECT * FROM @TableRepeat

       ELSE
       BEGIN
            INSERT INTO @TableRepeat ( 
                [MO]      
                ,[PONumber_ORIG]
                ,[PONumber]
                ,[Style]     
                ,[Color]  
                ,[Size]    
                ,[Quantity] 
                ,[Repeat]   
                ,[dudeDate]  
                ,[cancelDate]
                ,[UnitPrice]
                ,[Season]
            )
            (
                SELECT 
                    [MO]      
                    ,[PONumber] AS [PONumber_ORIG]
                    -- ,CONCAT(@PONumber_while,'_',FORMAT(@RepMOS, '000')) AS [PONumber]
                    ,[PONumber] AS [PONumber]
                    -- ,@PONumber_while    AS [PONumber]

                    -- ,[RowN]
                    ,[Style]     
                    ,[Color]  
                    -- ,@Size_Size                         AS [Size]    
                    ,[Size]                         AS [Size]    
                    -- ,(@TotalQuantity - @RestQuantity)   AS [Quantity] 
                    ,[Quantity]   AS [Quantity] 
                    ,1 AS [Repeat]   
                    ,[dudeDate]  
                    ,[cancelDate]
                    -- ,@UnitPrice_Size    AS [UnitPrice]
                    ,[UnitPrice]    AS [UnitPrice]
                    ,[Season]       AS [Season]
                FROM @TableMOS_ALLDATA 
                -- WHERE [RowN] = @i_while1
            )
            -- SELECT * , 'HOLA' AS [HOLA] FROM @TableMOS
            -- SELECT * , 'HOLA2' AS [HOLA] FROM @TableMOS_ALLDATA
            -- SELECT * FROM @TableRepeat
       END

            --    SELECT * FROM @TableRepeat 
                    --      [MO]      
                    --     ,[PONumber_ORIG]
                    --     ,[PONumber]
                    --     ,[Style]        
                    --     ,[Color]  
                    --     ,[Size]    
                    --     ,SUM([Quantity] ) AS [Quantity]
                    --     -- ,[Repeat]   
                    --     ,[dudeDate]     
                    --     ,[cancelDate]   
                    --     ,[Season]
                    --     ,[UnitPrice]
                    -- FROM @TableRepeat  
                    -- WHERE [Quantity] <> 0
                    -- GROUP BY 
                    --      [PONumber]
                    --     ,[Style]        
                    --     ,[Color]  
                    --     ,[Size]    
                    --     -- ,[Quantity] 
                    --     -- ,[Repeat]   
                    --     ,[dudeDate]     
                    --     ,[cancelDate]   
                    --     ,[Season]
                    --     ,[UnitPrice]

    

        DECLARE @OrderTable            AS INTEGER
        SET @OrderTable = 0

        DECLARE @T1_A   AS NVARCHAR(50)
        DECLARE @T1_B   AS NVARCHAR(50)
        DECLARE @T1_C   AS NVARCHAR(50)
        DECLARE @T1_D   AS NVARCHAR(50)
        DECLARE @T1_E   AS NVARCHAR(50)
        DECLARE @T1_F   AS NVARCHAR(50)
        DECLARE @T1_G   AS NVARCHAR(50)
        DECLARE @T1_H   AS NVARCHAR(50)
        DECLARE @T1_I   AS NVARCHAR(50)
        DECLARE @T1_J   AS NVARCHAR(50)
        DECLARE @T1_K   AS NVARCHAR(50)
        DECLARE @T1_L   AS NVARCHAR(50)
        DECLARE @T1_M   AS NVARCHAR(50)
        DECLARE @T1_N   AS NVARCHAR(50)
        DECLARE @T1_O   AS NVARCHAR(50)
        DECLARE @T1_P   AS NVARCHAR(50)
        DECLARE @T1_Q   AS NVARCHAR(50)

        DECLARE @T1_R   AS NVARCHAR(50)
        DECLARE @T1_S   AS NVARCHAR(50)
        DECLARE @T1_T   AS NVARCHAR(50)

        SET @T1_A   = 'type'
        SET @T1_B   = 'direction'
        SET @T1_C   = 'section'
        SET @T1_D   = 'CustomerNumber'
        SET @T1_E   = 'PONumber'
        SET @T1_F   = 'OrderRequiredDate'
        SET @T1_G   = 'Comments'
        SET @T1_H   = 'Comments4'
        SET @T1_I   = 'Comments5'
        SET @T1_J   = 'Comments6'
        SET @T1_K   = 'Comments7'
        SET @T1_L   = 'OrderCancelDate'
        SET @T1_M   = 'Comments9'
        SET @T1_N   = 'Comments12'
        SET @T1_O   = 'Comments3'
        SET @T1_P   = 'Comments13'
        SET @T1_Q   = 'OrderDeliveryDate'

        SET @T1_R   = 'Comments19'
        SET @T1_S   = 'Comments17'
        SET @T1_T   = 'Comments18'


        DECLARE @T1D_A   AS NVARCHAR(50)
        DECLARE @T1D_B   AS NVARCHAR(50)
        DECLARE @T1D_C   AS NVARCHAR(50)
        SET @T1D_A   = 'SALES'
        SET @T1D_B   = 'IN'
        SET @T1D_C   = 'HDR'


        DECLARE @T2_A   AS NVARCHAR(50)
        DECLARE @T2_B   AS NVARCHAR(50)
        DECLARE @T2_C   AS NVARCHAR(50)
        DECLARE @T2_D   AS NVARCHAR(50)
        DECLARE @T2_E   AS NVARCHAR(50)
        DECLARE @T2_F   AS NVARCHAR(50)
        DECLARE @T2_G   AS NVARCHAR(50)
        DECLARE @T2_H   AS NVARCHAR(50)
        DECLARE @T2_I   AS NVARCHAR(50)
        DECLARE @T2_J   AS NVARCHAR(50)
        DECLARE @T2_K   AS NVARCHAR(50)
        DECLARE @T2_L   AS NVARCHAR(50)
        DECLARE @T2_M   AS NVARCHAR(50)
        DECLARE @T2_N   AS NVARCHAR(50)
        DECLARE @T2_O   AS NVARCHAR(50)
        DECLARE @T2_P   AS NVARCHAR(50)
        DECLARE @T2_Q   AS NVARCHAR(50)
        DECLARE @T2_R   AS NVARCHAR(50)
        DECLARE @T2_S   AS NVARCHAR(50)
        DECLARE @T2_T   AS NVARCHAR(50)

        SET @T2_A   = 'type'
        SET @T2_B   = 'direction'
        SET @T2_C   = 'section'
        SET @T2_D   = 'CustomerNumber'
        SET @T2_E   = 'PONumber'
        SET @T2_F   = 'UnitPrice'
        SET @T2_G   = 'StyleNumber'
        SET @T2_H   = 'Season'
        SET @T2_I   = 'StyleCustomerNumber'
        SET @T2_J   = 'CustomerColorName'
        SET @T2_K   = 'GarmentSize'
        SET @T2_L   = 'DetailRequestCount'
        SET @T2_M   = 'SizePackQuantity'
        SET @T2_N   = 'PricingUnitCost2'
        SET @T2_O   = 'PricingUnitCost'
        SET @T2_P   = NULL
        SET @T2_Q   = NULL
        SET @T2_R   = NULL
        SET @T2_S   = NULL
        SET @T2_T   = NULL

        DECLARE @T2D_A   AS NVARCHAR(50)
        DECLARE @T2D_B   AS NVARCHAR(50)
        DECLARE @T2D_C   AS NVARCHAR(50)
        SET @T2D_A   = 'SALES'
        SET @T2D_B   = 'IN'
        SET @T2D_C   = 'DTL'

        DECLARE @Table_Final AS TABLE(
             [A]             [VARCHAR](50)  NULL
            ,[B]             [VARCHAR](50)  NULL
            ,[C]             [VARCHAR](50)  NULL
            ,[D]             [VARCHAR](50)  NULL
            ,[E]             [VARCHAR](50)  NULL
            ,[F]             [VARCHAR](50)  NULL
            ,[G]             [VARCHAR](50)  NULL
            ,[H]             [VARCHAR](50)  NULL
            ,[I]             [VARCHAR](50)  NULL
            ,[J]             [VARCHAR](50)  NULL
            ,[K]             [VARCHAR](50)  NULL
            ,[L]             [VARCHAR](50)  NULL
            ,[M]             [VARCHAR](50)  NULL
            ,[N]             [VARCHAR](50)  NULL
            ,[O]             [VARCHAR](50)  NULL
            ,[P]             [VARCHAR](50)  NULL
            ,[Q]             [VARCHAR](50)  NULL
            ,[R]             [VARCHAR](50)  NULL
            ,[S]             [VARCHAR](50)  NULL
            ,[T]             [VARCHAR](50)  NULL
            ,[OrderTable]    [INT]          NULL 
        )

        DECLARE @Table_Data AS TABLE (
             [CustomerNumber]       [VARCHAR](50)  NULL
            ,[PONumber]             [VARCHAR](50)  NULL
            ,[UnitPrice]            [VARCHAR](50)  NULL
            ,[StyleNumber]          [VARCHAR](50)  NULL
            ,[SeasonPPM]            [VARCHAR](50)  NULL
            ,[Season]               [VARCHAR](50)  NULL
            ,[StyleCustomerNumber]  [VARCHAR](50)  NULL
            ,[CustomerColorName]    [VARCHAR](50)  NULL
            ,[GarmentSize]          [VARCHAR](50)  NULL
            ,[DetailRequestCount]   [VARCHAR](50)  NULL
            ,[SizePackQuantity]     [VARCHAR](50)  NULL
            ,[PricingUnitCost2]     [VARCHAR](50)  NULL
            ,[PricingUnitCost]      [VARCHAR](50)  NULL

            ,[OrderRequiredDate]    [VARCHAR](50)  NULL
            ,[Comments]             [VARCHAR](50)  NULL
            ,[Comments4]            [VARCHAR](100)  NULL
            ,[Comments5]            [VARCHAR](100)  NULL
            ,[Comments6]            [VARCHAR](100)  NULL
            ,[Comments7]            [VARCHAR](100)  NULL
            ,[OrderCancelDate]      [VARCHAR](50)  NULL
            ,[Comments9]            [VARCHAR](100)  NULL
            ,[Comments12]           [VARCHAR](100)  NULL
            ,[Comments3]            [VARCHAR](100)  NULL
            ,[Comments13]           [VARCHAR](100)  NULL
            ,[OrderDeliveryDate]    [VARCHAR](50)  NULL
            ,[Comments19]           [VARCHAR](100)  NULL
            ,[Comments17]           [VARCHAR](100)  NULL
            ,[Comments18]           [VARCHAR](100)  NULL
        )

        INSERT INTO @Table_Data(
             [CustomerNumber]      
            ,[PONumber]            
            ,[UnitPrice]           
            ,[StyleNumber]         
            ,[SeasonPPM]              
            ,[Season]              
            ,[StyleCustomerNumber] 
            ,[CustomerColorName]   
            ,[GarmentSize]         
            ,[DetailRequestCount]  
            ,[SizePackQuantity]    
            ,[PricingUnitCost2]    
            ,[PricingUnitCost]  

            ,[OrderRequiredDate]     
            ,[Comments]     
            ,[Comments4]     
            ,[Comments5]     
            ,[Comments6]     
            ,[Comments7]     
            ,[OrderCancelDate]     
            ,[Comments9]     
            ,[Comments12]     
            ,[Comments3]     
            ,[Comments13]     
            ,[OrderDeliveryDate]     
            ,[Comments19]     
            ,[Comments17]     
            ,[Comments18]     
        )(
            SELECT
                'L2BRANDS'                                            AS [CustomerNumber]
                -- ,[PONumber]                                         AS [PONumber]
                ,[PONumber_ORIG]                                    AS [PONumber]
                ,[UnitPrice]                                        AS [UnitPrice]
                -- ,TB_Proc.UnitPrice                                  AS [UnitPrice]
                ,[Style]                                            AS [StyleNumber]
                ,[Season]                                           AS [SeasonPPM]
                ,[Season]                                           AS [Season]
                ,'L2BRANDS'                                           AS [StyleCustomerNumber]
                ,[Color]                                            AS [CustomerColorName]
                ,[Size]                                             AS [GarmentSize]
                ,[Quantity]                                         AS [DetailRequestCount]
                ,200                                                AS [SizePackQuantity]
                ,[UnitPrice]                                        AS [PricingUnitCost2]
                ,0.00                                               AS [PricingUnitCost]

                -- ,CAST(CAST(GETDATE() AS DATE) AS VARCHAR)           AS [OrderRequiredDate]
                ,CAST(CAST([dudeDate] AS DATE) AS VARCHAR)           AS [OrderRequiredDate]
                ,[Style]                                            AS [Comments]
                ,[Season]                                           AS [Comments4]
                -- ,[MO]                                               AS [Comments4]
                ,''                                                 AS [Comments5]
                ,''                                                 AS [Comments6]
                ,''                                                 AS [Comments7]
                ,CAST(CAST([cancelDate] AS DATE) AS VARCHAR)        AS [OrderCancelDate]
                ,''                                                 AS [Comments9]
                ,''                                                 AS [Comments12]
                ,''                                                 AS [Comments3]
                ,''                                                 AS [Comments13]
                ,CAST(CAST([dudeDate] AS DATE) AS VARCHAR)          AS [OrderDeliveryDate]
                ,''                                                 AS [Comments19]
                ,''                                                 AS [Comments17]
                ,''                                                 AS [Comments18]
                    --  [MO]      
                    -- ,[PONumber_ORIG]
                    -- ,[PONumber]
                    -- ,[Style]        AS [StyleNumber] 
                    -- ,[Color]  
                    -- ,[Size]    
                    -- ,[Quantity] 
                    -- ,[Repeat]   
                    -- ,[dudeDate]     AS [OrderDeliveryDate]
                    -- ,[cancelDate]   AS [OrderCancelDate]
                    -- ,[Season]
            -- FROM @TableRepeat   
            FROM (
                SELECT
                    --  [MO]      
                     [PONumber_ORIG]
                    ,[PONumber]
                    ,[Style]        
                    ,[Color]  
                    ,[Size]    
                    ,SUM([Quantity] ) AS [Quantity]
                    -- ,[Repeat]   
                    ,[dudeDate]     
                    ,[cancelDate]   
                    ,[Season]
                    ,[UnitPrice]
                FROM @TableRepeat  
                WHERE [Quantity] <> 0
                GROUP BY 
                     [PONumber_ORIG]
                    ,[PONumber]
                    ,[Style]        
                    ,[Color]  
                    ,[Size]    
                    -- ,[Quantity] 
                    -- ,[Repeat]   
                    ,[dudeDate]     
                    ,[cancelDate]   
                    ,[Season]
                    ,[UnitPrice]
            ) AS TB_TableRepeat
        )





    

        DECLARE @Table_PONumber AS TABLE (
            [CustomerNumber]       [VARCHAR](50)  NULL
            ,[PONumber]             [VARCHAR](50)  NULL
            ,[OrderRequiredDate]    [VARCHAR](50)  NULL
            ,[Comments]             [VARCHAR](50)  NULL
            ,[Comments4]            [VARCHAR](100)  NULL
            ,[Comments5]            [VARCHAR](100)  NULL
            ,[Comments6]            [VARCHAR](100)  NULL
            ,[Comments7]            [VARCHAR](100)  NULL
            ,[OrderCancelDate]      [VARCHAR](50)  NULL
            ,[Comments9]            [VARCHAR](100)  NULL
            ,[Comments12]           [VARCHAR](100)  NULL
            ,[Comments3]            [VARCHAR](100)  NULL
            ,[Comments13]           [VARCHAR](100)  NULL
            ,[OrderDeliveryDate]    [VARCHAR](50)  NULL
            ,[Comments19]           [VARCHAR](100)  NULL
            ,[Comments17]           [VARCHAR](100)  NULL
            ,[Comments18]           [VARCHAR](100)  NULL

            ,[SeasonPPM]                [VARCHAR](50)  NULL
            ,[Season]                   [VARCHAR](50)  NULL
            ,[CustomerColorName]        [VARCHAR](50)  NULL
            ,[StyleNumber]          [VARCHAR](50)  NULL
            -- ,[UnitPrice]            [VARCHAR](50)  NULL
            -- ,[SeasonPPM]            [VARCHAR](50)  NULL
            -- ,[Season]               [VARCHAR](50)  NULL
            -- ,[StyleCustomerNumber]  [VARCHAR](50)  NULL
            -- ,[CustomerColorName]    [VARCHAR](50)  NULL
            -- ,[GarmentSize]          [VARCHAR](50)  NULL
            -- ,[DetailRequestCount]   [VARCHAR](50)  NULL
            -- ,[SizePackQuantity]     [VARCHAR](50)  NULL
            -- ,[PricingUnitCost2]     [VARCHAR](50)  NULL
            -- ,[PricingUnitCost]      [VARCHAR](50)  NULL

            --  [ROW_PONumber]          [INT]          NULL   
        )

        INSERT INTO @Table_PONumber(
             [CustomerNumber]      
            ,[PONumber]            
            ,[OrderRequiredDate]   
            ,[Comments]            
            ,[Comments4]           
            ,[Comments5]           
            ,[Comments6]           
            ,[Comments7]           
            ,[OrderCancelDate]     
            ,[Comments9]           
            ,[Comments12]          
            ,[Comments3]           
            ,[Comments13]          
            ,[OrderDeliveryDate]   
            ,[Comments19]          
            ,[Comments17]          
            ,[Comments18]                      
            ,[SeasonPPM]           
            ,[Season]              
            ,[CustomerColorName]   
            ,[StyleNumber]
        )
        (
            SELECT
                 [CustomerNumber]      
                ,[PONumber]            
                ,[OrderRequiredDate]   
                ,[Comments]            
                ,[Comments4]           
                ,[Comments5]           
                ,[Comments6]           
                ,[Comments7]           
                ,[OrderCancelDate]     
                ,[Comments9]           
                ,[Comments12]          
                ,[Comments3]           
                ,[Comments13]          
                ,[OrderDeliveryDate]   
                ,[Comments19]          
                ,[Comments17]          
                ,[Comments18] 
                ,[SeasonPPM]           
                ,[Season]              
                ,[CustomerColorName]   
                ,[StyleNumber]
            FROM @Table_Data
            GROUP BY 
                 [CustomerNumber]      
                ,[PONumber]            
                ,[OrderRequiredDate]   
                ,[Comments]            
                ,[Comments4]           
                ,[Comments5]           
                ,[Comments6]           
                ,[Comments7]           
                ,[OrderCancelDate]     
                ,[Comments9]           
                ,[Comments12]          
                ,[Comments3]           
                ,[Comments13]          
                ,[OrderDeliveryDate]   
                ,[Comments19]          
                ,[Comments17]          
                ,[Comments18]                          
                ,[SeasonPPM]           
                ,[Season]              
                ,[CustomerColorName] 
                ,[StyleNumber]  
            
        )
        -- SELECT * FROM @Table_PONumber

        DECLARE @CustomerNumber         AS 	[VARCHAR](50)
        DECLARE @PONumber               AS  [VARCHAR](50)
        DECLARE @OrderRequiredDate	    AS  [VARCHAR](50)
        DECLARE @Comments               AS  [VARCHAR](100)
        DECLARE @Comments4              AS  [VARCHAR](100)
        DECLARE @Comments5              AS  [VARCHAR](100)
        DECLARE @Comments6              AS  [VARCHAR](100)
        DECLARE @Comments7              AS  [VARCHAR](100)
        DECLARE @OrderCancelDate        AS  [VARCHAR](50)
        DECLARE @Comments9              AS  [VARCHAR](100)
        DECLARE @Comments12             AS  [VARCHAR](100)
        DECLARE @Comments3              AS  [VARCHAR](100)
        DECLARE @Comments13             AS  [VARCHAR](100)
        DECLARE @OrderDeliveryDate      AS  [VARCHAR](50)
        DECLARE @Comments19             AS  [VARCHAR](100)
        DECLARE @Comments17             AS  [VARCHAR](100)
        DECLARE @Comments18             AS  [VARCHAR](100)
        DECLARE @SeasonPPM              AS  [VARCHAR](50)
        DECLARE @Season                 AS  [VARCHAR](50)
        DECLARE @CustomerColorName      AS  [VARCHAR](50)
        DECLARE @StyleNumber            AS  [VARCHAR](50)

        DECLARE @CountData AS INT
        SET @CountData = (SELECT Count(*) FROM @Table_PONumber)

        IF @CountData > 0 
        BEGIN
            DECLARE CursorTB_ALL CURSOR GLOBAL  --LOCAL
            FOR 
            SELECT 
                 [CustomerNumber]      
                ,[PONumber]            
                ,[OrderRequiredDate]   
                ,[Comments]            
                ,[Comments4]           
                ,[Comments5]           
                ,[Comments6]           
                ,[Comments7]           
                ,[OrderCancelDate]     
                ,[Comments9]           
                ,[Comments12]          
                ,[Comments3]           
                ,[Comments13]          
                ,[OrderDeliveryDate]   
                ,[Comments19]          
                ,[Comments17]          
                ,[Comments18]          
                                    
                ,[SeasonPPM]           
                ,[Season]              
                ,[CustomerColorName]   
                ,[StyleNumber]   
            FROM @Table_PONumber 
            ORDER BY 
                 [PONumber]
                ,[StyleNumber]
                ,[CustomerColorName] 
            FOR UPDATE

            OPEN CursorTB_ALL
            FETCH CursorTB_ALL 
            INTO 
                 @CustomerNumber     
                ,@PONumber           
                ,@OrderRequiredDate	
                ,@Comments           
                ,@Comments4          
                ,@Comments5          
                ,@Comments6          
                ,@Comments7          
                ,@OrderCancelDate    
                ,@Comments9          
                ,@Comments12         
                ,@Comments3          
                ,@Comments13         
                ,@OrderDeliveryDate  
                ,@Comments19         
                ,@Comments17         
                ,@Comments18         
                ,@SeasonPPM          
                ,@Season             
                ,@CustomerColorName  
                ,@StyleNumber      	

            DECLARE @PONumber_ANTERIOR      AS NVARCHAR(50)
            DECLARE @PONumber_ANTERIOR_N    AS INT
            SET @PONumber_ANTERIOR      = @PONumber
            SET @PONumber_ANTERIOR_N    = 1


            WHILE (@@FETCH_STATUS = 0)
                BEGIN
                    
                    ----actualizando Columna de PolyPM de CAFTA
                    IF @PONumber IS NOT NULL 
                    BEGIN
                        SET @OrderTable = @OrderTable +1
                        
                        IF ((@PONumber_ANTERIOR <> @PONumber  ) OR (@PONumber_ANTERIOR_N = 1))
                        BEGIN
                                -----titulos de la PONumber del header
                            INSERT INTO @Table_Final(
                                    [A]          
                                    ,[B]          
                                    ,[C]          
                                    ,[D]          
                                    ,[E]          
                                    ,[F]          
                                    ,[G]          
                                    ,[H]          
                                    ,[I]          
                                    ,[J]          
                                    ,[K]          
                                    ,[L]          
                                    ,[M]          
                                    ,[N]          
                                    ,[O]          
                                    ,[P]          
                                    ,[Q]          
                                    ,[R]          
                                    ,[S]          
                                    ,[T]          
                                    ,[OrderTable] 
                            )
                            VALUES
                            (
                                    @T1_A
                                    ,@T1_B
                                    ,@T1_C
                                    ,@T1_D
                                    ,@T1_E
                                    ,@T1_F
                                    ,@T1_G
                                    ,@T1_H
                                    ,@T1_I
                                    ,@T1_J
                                    ,@T1_K
                                    ,@T1_L
                                    ,@T1_M
                                    ,@T1_N                
                                    ,@T1_O                
                                    ,@T1_P                
                                    ,@T1_Q                
                                    ,@T1_R                
                                    ,@T1_S                
                                    ,@T1_T                
                                    ,@OrderTable
                            )
                        

                            SET @OrderTable = @OrderTable +1
                                -----values de la PONumber del header
                            INSERT INTO @Table_Final(
                                    [A]          
                                    ,[B]          
                                    ,[C]          
                                    ,[D]          
                                    ,[E]          
                                    ,[F]          
                                    ,[G]          
                                    ,[H]          
                                    ,[I]          
                                    ,[J]          
                                    ,[K]          
                                    ,[L]          
                                    ,[M]          
                                    ,[N]          
                                    ,[O]          
                                    ,[P]          
                                    ,[Q]          
                                    ,[R]          
                                    ,[S]          
                                    ,[T]          
                                    ,[OrderTable] 
                            )
                            VALUES
                            (
                                    @T1D_A      
                                    ,@T1D_B
                                    ,@T1D_C
                                    ,@CustomerNumber     
                                    ,@PONumber           
                                    ,@OrderRequiredDate	
                                    ,@Comments           
                                    ,@Comments4          
                                    ,@Comments5          
                                    ,@Comments6          
                                    ,@Comments7          
                                    ,@OrderCancelDate    
                                    ,@Comments9          
                                    ,@Comments12         
                                    ,@Comments3          
                                    ,@Comments13         
                                    ,@OrderDeliveryDate  
                                    ,@Comments19         
                                    ,@Comments17         
                                    ,@Comments18  
                                    ,@OrderTable
                            )
                        

                            SET @OrderTable = @OrderTable +1
                                -----titulos del detalle de la PONumber
                            INSERT INTO @Table_Final(
                                    [A]          
                                    ,[B]          
                                    ,[C]          
                                    ,[D]          
                                    ,[E]          
                                    ,[F]          
                                    ,[G]          
                                    ,[H]          
                                    ,[I]          
                                    ,[J]          
                                    ,[K]          
                                    ,[L]          
                                    ,[M]          
                                    ,[N]          
                                    ,[O]          
                                    ,[P]          
                                    ,[Q]          
                                    ,[R]          
                                    ,[S]          
                                    ,[T]          
                                    ,[OrderTable] 
                            )
                            VALUES
                            (
                                    @T2_A            
                                    ,@T2_B    
                                    ,@T2_C    
                                    ,@T2_D      
                                    ,@T2_E  
                                    ,@T2_F
                                    ,@T2_G
                                    ,@T2_H
                                    ,@T2_I
                                    ,@T2_J
                                    ,@T2_K
                                    ,@T2_L
                                    ,@T2_M 
                                    ,@T2_N
                                    ,@T2_O
                                    ,@T2_P
                                    ,@T2_Q
                                    ,@T2_R
                                    ,@T2_S
                                    ,@T2_T
                                    ,@OrderTable
                            )
                        
                        END
                        
                        SET @OrderTable = @OrderTable +1
                            -----VALUES del detalle de la PONumber
                        INSERT INTO @Table_Final(
                                 [A]          
                                ,[B]          
                                ,[C]          
                                ,[D]          
                                ,[E]          
                                ,[F]          
                                ,[G]          
                                ,[H]          
                                ,[I]          
                                ,[J]          
                                ,[K]          
                                ,[L]          
                                ,[M]          
                                ,[N]          
                                ,[O]          
                                ,[P]          
                                ,[Q]          
                                ,[R]          
                                ,[S]          
                                ,[T]          
                                ,[OrderTable] 
                        )
                        (
                            SELECT --TOP 1 ---no quitar TOP 1 debido a que sino va a poner todos los items.. 
                                 @T2D_A            
                                ,@T2D_B    
                                ,@T2D_C    
                                ,[CustomerNumber]     
                                ,[PONumber]           
                                ,[UnitPrice]          
                                ,[StyleNumber]        
                                ,[Season]             
                                ,[StyleCustomerNumber] 
                                ,[CustomerColorName]  
                                ,[GarmentSize]        
                                ,[DetailRequestCount] 
                                ,[SizePackQuantity]
                                ,[PricingUnitCost2]   
                                ,[PricingUnitCost]
                                ,NULL    
                                ,NULL    
                                ,NULL    
                                ,NULL    
                                ,NULL    
                                ,@OrderTable
                            FROM @Table_Data 
                            WHERE   [PONumber]          = @PONumber
                                AND [StyleNumber]       = @StyleNumber
                                AND [Season]            = @Season
                                AND [SeasonPPM]         = @SeasonPPM
                                AND [CustomerColorName] = @CustomerColorName
                        )
                    
                    END

                    SET @PONumber_ANTERIOR      = @PONumber
                    SET @PONumber_ANTERIOR_N    = @PONumber_ANTERIOR_N + 1

                    FETCH CursorTB_ALL 
                    INTO 
                         @CustomerNumber     
                        ,@PONumber           
                        ,@OrderRequiredDate	
                        ,@Comments           
                        ,@Comments4          
                        ,@Comments5          
                        ,@Comments6          
                        ,@Comments7          
                        ,@OrderCancelDate    
                        ,@Comments9          
                        ,@Comments12         
                        ,@Comments3          
                        ,@Comments13         
                        ,@OrderDeliveryDate  
                        ,@Comments19         
                        ,@Comments17         
                        ,@Comments18         
                        ,@SeasonPPM          
                        ,@Season             
                        ,@CustomerColorName  
                        ,@StyleNumber  

                    
                END ---END WHILE

            CLOSE CursorTB_ALL
            DEALLOCATE CursorTB_ALL

            SELECT TOP 100 PERCENT 
                     [A]          
                    ,[B]         
                    ,[C]         
                    ,[D]         
                    ,[E]         
                    ,[F]         
                    ,[G]         
                    ,[H]         
                    ,[I]         
                    ,[J]         
                    ,[K]         
                    ,[L]         
                    ,[M]         
                    ,[N]         
                    ,[O]         
                    ,[P]         
                    ,[Q]         
                    ,[R]         
                    ,[S]         
                    ,[T]         
                    ,[OrderTable] 
            FROM @Table_Final ORDER BY [OrderTable]

        END ---END DE COUNT
        ELSE
        BEGIN
            -- PRINT 'NO EXISTEN ORDENES PARA ACTUALIZAR'
            
            SELECT 'NO EXISTEN ORDENES PARA ACTUALIZAR CSV' AS [Comment]
        END

    END
    -----FINALIZA IF @Count_NoInTableUnitsPerStyleAndSew

    -----EMPIEZA ELSE DE IF @Count_NoInTableUnitsPerStyleAndSew
    ELSE
    BEGIN

        IF @Count_NoInVWPlanningStyles <> 0 
            BEGIN 
                SELECT 'No existe Season en PPM para los estilos: ' 
                    + STUFF((
                            SELECT ',' + SPACE(1) + [Dat]
                                FROM (
                                    SELECT DISTINCT 
                                        Style AS Dat
                                    FROM @Table_JSON 
                                    WHERE [Season_Dat] = 0
                                ) AS tb
                                FOR XML PATH(''), TYPE
                            ).value('.', 'VARCHAR(MAX)'), 1, 1, ''
                    )     AS [Comment]
            END
        ELSE
            IF @Count_NoInVWPlanningStylesAndColors <> 0 
                BEGIN 
                    SELECT 'No existe Color en PPM para los estilos: ' 
                        + STUFF((
                                SELECT ',' + SPACE(1) + [Dat]
                                    FROM (
                                        SELECT DISTINCT 
                                            CONCAT(Style,'-',ISNULL(Color,''),char(13)) AS Dat
                                        FROM @Table_JSON 
                                        WHERE [Color_Dat] = 0
                                    ) AS tb
                                    FOR XML PATH(''), TYPE
                                ).value('.', 'VARCHAR(MAX)'), 1, 1, ''
                        )     
                        AS [Comment]
                END
            ELSE
                IF @Count_NoInTB_PriceMDB <> 0 
                    BEGIN 
                        SELECT 'No existe Precio agregado para los estilos: ' 
                            + STUFF((
                                    SELECT ',' + SPACE(1) + [Dat]
                                        FROM (
                                            SELECT DISTINCT 
                                                CONCAT(Style,'-',ISNULL(Color,''),char(13)) AS Dat
                                            FROM @Table_JSON 
                                            WHERE [Price_Dat] = 0
                                        ) AS tb
                                        FOR XML PATH(''), TYPE
                                    ).value('.', 'VARCHAR(MAX)'), 1, 1, ''
                            )     AS [Comment]
                    END
                ELSE
                    IF @Count_NoInTableUnitsPerStyleAndSew <> 0 
                        BEGIN 
                            SELECT 'No existe Estilo en Tabla de Recomendado. ' 
                                + STUFF((
                                        SELECT ',' + SPACE(1) + [Dat]
                                            FROM (
                                                SELECT DISTINCT 
                                                    Style AS Dat
                                                FROM @Table_JSON 
                                                WHERE [PARTICIONAR] = 0
                                            ) AS tb
                                            FOR XML PATH(''), TYPE
                                        ).value('.', 'VARCHAR(MAX)'), 1, 1, ''
                                )     AS [Comment]
                        END
        
         
    END
    -----FINALIZA ELSE DE IF @Count_NoInTableUnitsPerStyleAndSew

END
