/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbExtAccNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[SLI_CustomerSelSCustomer]  
	@CustId int,
	@Srecommend int
AS
BEGIN
/*
Created: Tiara
Task : VIEW MASTER
DB: DBCUST/CUSTDB
Original: Acc_CustomerSelCEditCustomer 

Revisions:
	- 20200107@Tiara: View Master setting information on NAP-U3 site [Redmine: #123584] 
	- 20210721@Winfred: Remove Comm on U3 site [Redmine: #123584]
Param's Explanation:
	@CustID: Master ID
	@Srecommend
*/
	SET NOCOUNT ON

	DECLARE 
		--Number game PT
		@v161mspositiontaking_81_max SMALLMONEY,
		@v161mspositiontaking_83_max SMALLMONEY,	
		@v161mspositiontaking_86_max SMALLMONEY,
		@v161mspositiontaking_88_max SMALLMONEY,

		@v161mslivepositiontaking_85_max SMALLMONEY,
		@v161mslivepositiontaking_86_max SMALLMONEY,
		@v161mslivepositiontaking_87_max SMALLMONEY,
		@v161mslivepositiontaking_89_max SMALLMONEY,
		@v161mslivepositiontaking_90_max SMALLMONEY,

		@v161mspositiontaking_81_min SMALLMONEY,	
		@v161mspositiontaking_83_min SMALLMONEY,	
		@v161mspositiontaking_86_min SMALLMONEY,
		@v161mspositiontaking_88_min SMALLMONEY,	

		@v161mslivepositiontaking_85_min SMALLMONEY,	
		@v161mslivepositiontaking_86_min SMALLMONEY,	
		@v161mslivepositiontaking_87_min SMALLMONEY,
		@v161mslivepositiontaking_89_min SMALLMONEY,
		@v161mslivepositiontaking_90_min SMALLMONEY,

		----------------------------------
		--Number game
		@v161mpositiontaking_81_max SMALLMONEY,
		@v161mpositiontaking_83_max SMALLMONEY,	
		@v161mpositiontaking_86_max SMALLMONEY,
		@v161mpositiontaking_88_max SMALLMONEY,

		@v161mlivepositiontaking_85_max SMALLMONEY,
		@v161mlivepositiontaking_86_max SMALLMONEY,
		@v161mlivepositiontaking_87_max SMALLMONEY,
		@v161mlivepositiontaking_89_max SMALLMONEY,
		@v161mlivepositiontaking_90_max SMALLMONEY,
	
	
		----------------------------------
		@maxdownline SMALLMONEY 

	DECLARE @MinBetv161_Max MONEY,
		@MaxBetv161_Min MONEY,
		@MaxPerMatchv161_Min MONEY,
		@MaxPerMatchv161_Max MONEY,

		@MaxPerBallv161_Max MONEY,
	
		@MinBetv164_Max MONEY,
		@MaxBetv164_Min MONEY,
		@MaxPerMatchv164_Min MONEY,
		@MaxPerMatchv164_Max MONEY

	SELECT 
		@MinBetv161_Max = MinBet,
		@MaxBetv161_Min = MaxBet
	FROM
		custsetting3rd AS CS3 WITH(NOLOCK)
	WHERE CS3.custid = @srecommend AND CS3.bettype = 81 AND CS3.sporttype = 161

	SELECT 
		@MinBetv164_Max = MinBet,
		@MaxBetv164_Min = MaxBet
	FROM
		custsetting3rd AS CS3 WITH(NOLOCK)
	WHERE CS3.custid = @srecommend AND CS3.bettype = 8101 AND CS3.sporttype = 164

	SELECT @MaxPerMatchv164_Min = 0,
		@MaxPerMatchv164_Max = MaxPerMatch164,
	
		@MaxPerMatchv161_Min = 0,
		@MaxPerMatchv161_Max = MaxPerMatch161,
	
		@MaxPerBallv161_Max = MaxPerBall161
	FROM 
		custinfo AS CI WITH (NOLOCK) 
	WHERE CI.custid = @Srecommend
	
	--Number game
	SELECT 
		@v161mpositiontaking_81_max = MAX(CASE WHEN CS3.bettype=81 AND CS3.sporttype = 161 THEN CS3.mpositiontaking ELSE 0 END),
		@v161mpositiontaking_83_max = MAX(CASE WHEN CS3.bettype=83 AND CS3.sporttype = 161 THEN CS3.mpositiontaking ELSE 0 END),	
		@v161mpositiontaking_86_max = MAX(CASE WHEN CS3.bettype=86 AND CS3.sporttype = 161 THEN CS3.mpositiontaking ELSE 0 END),
		@v161mpositiontaking_88_max = MAX(CASE WHEN CS3.bettype=88 AND CS3.sporttype = 161 THEN CS3.mpositiontaking ELSE 0 END),
		@v161mlivepositiontaking_85_max = MAX(CASE WHEN CS3.bettype=85 AND CS3.sporttype = 161 THEN CS3.mlivepositiontaking ELSE 0 END),
		@v161mlivepositiontaking_86_max = MAX(CASE WHEN CS3.bettype=86 AND CS3.sporttype = 161 THEN CS3.mlivepositiontaking ELSE 0 END),
		@v161mlivepositiontaking_87_max = MAX(CASE WHEN CS3.bettype=87 AND CS3.sporttype = 161 THEN CS3.mlivepositiontaking ELSE 0 END),
		@v161mlivepositiontaking_89_max = MAX(CASE WHEN CS3.bettype=89 AND CS3.sporttype = 161 THEN CS3.mlivepositiontaking ELSE 0 END),
		@v161mlivepositiontaking_90_max = MAX(CASE WHEN CS3.bettype=90 AND CS3.sporttype = 161 THEN CS3.mlivepositiontaking ELSE 0 END),

		@v161mspositiontaking_81_max = MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype = 161 THEN CASE WHEN CS3.spositiontaking < CO3.maxpositiontaking THEN CS3.spositiontaking ELSE CO3.maxpositiontaking END ELSE 0 END),
		@v161mspositiontaking_83_max = MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype = 161 THEN CASE WHEN CS3.spositiontaking < CO3.maxpositiontaking THEN CS3.spositiontaking ELSE CO3.maxpositiontaking END ELSE 0 END),	
		@v161mspositiontaking_86_max = MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype = 161 THEN CASE WHEN CS3.spositiontaking < CO3.maxpositiontaking THEN CS3.spositiontaking ELSE CO3.maxpositiontaking END ELSE 0 END),
		@v161mspositiontaking_88_max = MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype = 161 THEN CASE WHEN CS3.spositiontaking < CO3.maxpositiontaking THEN CS3.spositiontaking ELSE CO3.maxpositiontaking END ELSE 0 END),
		@v161mslivepositiontaking_85_max = MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype = 161 THEN CASE WHEN CS3.slivepositiontaking < CO3.maxlivepositiontaking THEN CS3.slivepositiontaking ELSE CO3.maxlivepositiontaking END ELSE 0 END),
		@v161mslivepositiontaking_86_max = MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype = 161 THEN CASE WHEN CS3.slivepositiontaking < CO3.maxlivepositiontaking THEN CS3.slivepositiontaking ELSE CO3.maxlivepositiontaking END ELSE 0 END),
		@v161mslivepositiontaking_87_max = MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype = 161 THEN CASE WHEN CS3.slivepositiontaking < CO3.maxlivepositiontaking THEN CS3.slivepositiontaking ELSE CO3.maxlivepositiontaking END ELSE 0 END),
		@v161mslivepositiontaking_89_max = MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype = 161 THEN CASE WHEN CS3.slivepositiontaking < CO3.maxlivepositiontaking THEN CS3.slivepositiontaking ELSE CO3.maxlivepositiontaking END ELSE 0 END),
		@v161mslivepositiontaking_90_max = MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype = 161 THEN CASE WHEN CS3.slivepositiontaking < CO3.maxlivepositiontaking THEN CS3.slivepositiontaking ELSE CO3.maxlivepositiontaking END ELSE 0 END),
	
		@v161mspositiontaking_81_min = MAX(CASE WHEN CO3.bettype = 81 AND CO3.sporttype = 161 THEN CO3.minpositiontaking ELSE 0 END),
		@v161mspositiontaking_83_min = MAX(CASE WHEN CO3.bettype = 83 AND CO3.sporttype = 161 THEN CO3.minpositiontaking ELSE 0 END),	
		@v161mspositiontaking_86_min = MAX(CASE WHEN CO3.bettype = 86 AND CO3.sporttype = 161 THEN CO3.minpositiontaking ELSE 0 END),
		@v161mspositiontaking_88_min = MAX(CASE WHEN CO3.bettype = 88 AND CO3.sporttype = 161 THEN CO3.minpositiontaking ELSE 0 END),
		@v161mslivepositiontaking_85_min = MAX(CASE WHEN CO3.bettype = 85 AND CO3.sporttype = 161 THEN CO3.minlivepositiontaking ELSE 0 END),
		@v161mslivepositiontaking_86_min = MAX(CASE WHEN CO3.bettype = 86 AND CO3.sporttype = 161 THEN CO3.minlivepositiontaking ELSE 0 END),
		@v161mslivepositiontaking_87_min = MAX(CASE WHEN CO3.bettype = 87 AND CO3.sporttype = 161 THEN CO3.minlivepositiontaking ELSE 0 END),
		@v161mslivepositiontaking_89_min = MAX(CASE WHEN CO3.bettype = 89 AND CO3.sporttype = 161 THEN CO3.minlivepositiontaking ELSE 0 END),
		@v161mslivepositiontaking_90_min = MAX(CASE WHEN CO3.bettype = 90 AND CO3.sporttype = 161 THEN CO3.minlivepositiontaking ELSE 0 END)

	FROM custsetting3rd AS CS3 WITH(NOLOCK)
		 LEFT JOIN custoverride3rd AS CO3 WITH(NOLOCK) ON CS3.custid = CO3.custid AND CS3.sporttype = CO3.sporttype AND CS3.bettype = CO3.bettype
	WHERE CS3.custid = @srecommend AND CS3.sporttype = 161


	SELECT 
		C.firstname, 
		C.lastname, 
		C.roleid,
		C.username,
		ISNULL(C.phone, '') AS phone, 
		ISNULL(C.mobilephone, '') AS mobilephone, 
		ISNULL(C.email, '') AS email,
		ISNULL(C.fax, '') AS fax,	
		CI.maxpermatch161 AS maxpermatchv161,
		CI.maxperball161 AS maxperballv161,
		CI.maxpermatch164 AS maxpermatchv164,

		--Number game
		MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.minbet ELSE 0 END) AS minbetv161,
		MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.maxbet ELSE 0 END) AS maxbetv161,
		MAX(CASE WHEN CS3.bettype = 8101 AND CS3.sporttype=164 THEN CS3.minbet ELSE 0 END) AS minbetv164,
		MAX(CASE WHEN CS3.bettype = 8101 AND CS3.sporttype=164 THEN CS3.maxbet ELSE 0 END) AS maxbetv164,
		MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.spositiontaking ELSE 0 END) AS v161spositiontaking_81,
		MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype=161 THEN CS3.spositiontaking ELSE 0 END) AS v161spositiontaking_83,	
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.spositiontaking ELSE 0 END) AS v161spositiontaking_86,
		MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype=161 THEN CS3.spositiontaking ELSE 0 END) AS v161spositiontaking_88,
		MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype=161 THEN CS3.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_85,
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_86,
		MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype=161 THEN CS3.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_87,
		MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype=161 THEN CS3.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_89,
		MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype=161 THEN CS3.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_90,
	
		--Number game
		MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.mpositiontaking ELSE 0 END) AS v161mpositiontaking_81,
		MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype=161 THEN CS3.mpositiontaking ELSE 0 END) AS v161mpositiontaking_83,	
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.mpositiontaking ELSE 0 END) AS v161mpositiontaking_86,
		MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype=161 THEN CS3.mpositiontaking ELSE 0 END) AS v161mpositiontaking_88,
		MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_85,
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_86,
		MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_87,
		MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_89,
		MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_90,

		--Number game
		MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.autopositiontaking ELSE 0 END) AS auto_v161spositiontaking_81,
		MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype=161 THEN CS3.autopositiontaking ELSE 0 END) AS auto_v161spositiontaking_83,	
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.autopositiontaking ELSE 0 END) AS auto_v161spositiontaking_86,
		MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype=161 THEN CS3.autopositiontaking ELSE 0 END) AS auto_v161spositiontaking_88,
		MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype=161 THEN CS3.autolivepositiontaking ELSE 0 END) AS auto_v161slivepositiontaking_85,
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.autolivepositiontaking ELSE 0 END) AS auto_v161slivepositiontaking_86,
		MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype=161 THEN CS3.autolivepositiontaking ELSE 0 END) AS auto_v161slivepositiontaking_87,
		MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype=161 THEN CS3.autolivepositiontaking ELSE 0 END) AS auto_v161slivepositiontaking_89,
		MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype=161 THEN CS3.autolivepositiontaking ELSE 0 END) AS auto_v161slivepositiontaking_90,
		--Number game
		@v161mspositiontaking_81_max AS v161spositiontaking_81_max,
		@v161mspositiontaking_83_max AS v161spositiontaking_83_max,	
		@v161mspositiontaking_86_max AS v161spositiontaking_86_max,
		@v161mspositiontaking_88_max AS v161spositiontaking_88_max,
		@v161mslivepositiontaking_85_max AS v161slivepositiontaking_85_max,
		@v161mslivepositiontaking_86_max AS v161slivepositiontaking_86_max,
		@v161mslivepositiontaking_87_max AS v161slivepositiontaking_87_max,
		@v161mslivepositiontaking_89_max AS v161slivepositiontaking_89_max,
		@v161mslivepositiontaking_90_max AS v161slivepositiontaking_90_max,
		--Number game
		@v161mspositiontaking_81_max AS auto_v161spositiontaking_81_max,
		@v161mspositiontaking_83_max AS auto_v161spositiontaking_83_max,	
		@v161mspositiontaking_86_max AS auto_v161spositiontaking_86_max,
		@v161mspositiontaking_88_max AS auto_v161spositiontaking_88_max,
		@v161mslivepositiontaking_85_max AS auto_v161slivepositiontaking_85_max,
		@v161mslivepositiontaking_86_max AS auto_v161slivepositiontaking_86_max,
		@v161mslivepositiontaking_87_max AS auto_v161slivepositiontaking_87_max,
		@v161mslivepositiontaking_89_max AS auto_v161slivepositiontaking_89_max,
		@v161mslivepositiontaking_90_max AS auto_v161slivepositiontaking_90_max,
		ISNULL(@MinBetv161_Max, 0) AS MinBetv161_Max,
		ISNULL(@MaxBetv161_Min, 0) AS MaxBetv161_Min,	
		ISNULL(@MaxPerMatchv161_Min, 0) AS MaxPerMatchv161_Min,	
		ISNULL(@MaxPerMatchv161_Max, 0) AS MaxPerMatchv161_Max,

		ISNULL(@MaxPerBallv161_Max, 0) AS MaxPerBallv161_Max,
	
		ISNULL(@MinBetv164_Max, 0) AS MinBetv164_Max,
		ISNULL(@MaxBetv164_Min, 0) AS MaxBetv164_Min,	
		ISNULL(@MaxPerMatchv164_Min, 0) AS MaxPerMatchv164_Min,	
		ISNULL(@MaxPerMatchv164_Max, 0) AS MaxPerMatchv164_Max,
		
		-- number game
		MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.isautopositiontaking ELSE 0 END) AS isauto_v161spositiontaking_81,
		MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype=161 THEN CS3.isautopositiontaking ELSE 0 END) AS isauto_v161spositiontaking_83,	
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.isautopositiontaking ELSE 0 END) AS isauto_v161spositiontaking_86,
		MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype=161 THEN CS3.isautopositiontaking ELSE 0 END) AS isauto_v161spositiontaking_88,
		MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype=161 THEN CS3.isautolivepositiontaking ELSE 0 END) AS isauto_v161slivepositiontaking_85,
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.isautolivepositiontaking ELSE 0 END) AS isauto_v161slivepositiontaking_86,
		MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype=161 THEN CS3.isautolivepositiontaking ELSE 0 END) AS isauto_v161slivepositiontaking_87,
		MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype=161 THEN CS3.isautolivepositiontaking ELSE 0 END) AS isauto_v161slivepositiontaking_89,
		MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype=161 THEN CS3.isautolivepositiontaking ELSE 0 END) AS isauto_v161slivepositiontaking_90,

		-- number game
		@v161mspositiontaking_81_max AS v161mspositiontaking_81_max,
		@v161mspositiontaking_83_max AS v161mspositiontaking_83_max,	
		@v161mspositiontaking_86_max AS v161mspositiontaking_86_max,
		@v161mspositiontaking_88_max AS v161mspositiontaking_88_max,
		@v161mslivepositiontaking_85_max AS v161mslivepositiontaking_85_max,
		@v161mslivepositiontaking_86_max AS v161mslivepositiontaking_86_max,
		@v161mslivepositiontaking_87_max AS v161mslivepositiontaking_87_max,
		@v161mslivepositiontaking_89_max AS v161mslivepositiontaking_89_max,
		@v161mslivepositiontaking_90_max AS v161mslivepositiontaking_90_max,

		@v161mspositiontaking_81_min AS v161mspositiontaking_81_min,
		@v161mspositiontaking_83_min AS v161mspositiontaking_83_min,	
		@v161mspositiontaking_86_min AS v161mspositiontaking_86_min,
		@v161mspositiontaking_88_min AS v161mspositiontaking_88_min,
		@v161mslivepositiontaking_85_min AS v161mslivepositiontaking_85_min,
		@v161mslivepositiontaking_86_min AS v161mslivepositiontaking_86_min,
		@v161mslivepositiontaking_87_min AS v161mslivepositiontaking_87_min,
		@v161mslivepositiontaking_89_min AS v161mslivepositiontaking_89_min,
		@v161mslivepositiontaking_90_min AS v161mslivepositiontaking_90_min,
	
		-- number game
		MAX(CASE WHEN CO3.bettype = 81 AND CO3.sporttype= 161 THEN CO3.minpositiontaking ELSE 0 END) AS v161mpositiontaking_81_min,
		MAX(CASE WHEN CO3.bettype = 83 AND CO3.sporttype= 161 THEN CO3.minpositiontaking ELSE 0 END) AS v161mpositiontaking_83_min,	
		MAX(CASE WHEN CO3.bettype = 86 AND CO3.sporttype= 161 THEN CO3.minpositiontaking ELSE 0 END) AS v161mpositiontaking_86_min,
		MAX(CASE WHEN CO3.bettype = 88 AND CO3.sporttype= 161 THEN CO3.minpositiontaking ELSE 0 END) AS v161mpositiontaking_88_min,
		MAX(CASE WHEN CO3.bettype = 85 AND CO3.sporttype= 161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_85_min,
		MAX(CASE WHEN CO3.bettype = 86 AND CO3.sporttype= 161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_86_min,
		MAX(CASE WHEN CO3.bettype = 87 AND CO3.sporttype= 161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_87_min,
		MAX(CASE WHEN CO3.bettype = 89 AND CO3.sporttype= 161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_89_min,
		MAX(CASE WHEN CO3.bettype = 90 AND CO3.sporttype= 161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_90_min,

		--number game
		MAX(CASE WHEN CO3.bettype = 81 AND CO3.sporttype = 161 THEN CASE WHEN @v161mpositiontaking_81_max < CO3.maxpositiontaking THEN @v161mpositiontaking_81_max ELSE CO3.maxpositiontaking END ELSE 0 END) AS v161mpositiontaking_81_max,
		MAX(CASE WHEN CO3.bettype = 83 AND CO3.sporttype = 161 THEN CASE WHEN @v161mpositiontaking_83_max < CO3.maxpositiontaking THEN @v161mpositiontaking_83_max ELSE CO3.maxpositiontaking END ELSE 0 END) AS v161mpositiontaking_83_max,	
		MAX(CASE WHEN CO3.bettype = 86 AND CO3.sporttype = 161 THEN CASE WHEN @v161mpositiontaking_86_max < CO3.maxpositiontaking THEN @v161mpositiontaking_86_max ELSE CO3.maxpositiontaking END ELSE 0 END) AS v161mpositiontaking_86_max,
		MAX(CASE WHEN CO3.bettype = 88 AND CO3.sporttype = 161 THEN CASE WHEN @v161mpositiontaking_88_max < CO3.maxpositiontaking THEN @v161mpositiontaking_88_max ELSE CO3.maxpositiontaking END ELSE 0 END) AS v161mpositiontaking_88_max,
		MAX(CASE WHEN CO3.bettype = 85 AND CO3.sporttype = 161 THEN CASE WHEN @v161mlivepositiontaking_85_max < CO3.maxlivepositiontaking THEN @v161mlivepositiontaking_85_max ELSE CO3.maxlivepositiontaking END ELSE 0 END) AS v161mlivepositiontaking_85_max,
		MAX(CASE WHEN CO3.bettype = 86 AND CO3.sporttype = 161 THEN CASE WHEN @v161mlivepositiontaking_86_max < CO3.maxlivepositiontaking THEN @v161mlivepositiontaking_86_max ELSE CO3.maxlivepositiontaking END ELSE 0 END) AS v161mlivepositiontaking_86_max,
		MAX(CASE WHEN CO3.bettype = 87 AND CO3.sporttype = 161 THEN CASE WHEN @v161mlivepositiontaking_87_max < CO3.maxlivepositiontaking THEN @v161mlivepositiontaking_87_max ELSE CO3.maxlivepositiontaking END ELSE 0 END) AS v161mlivepositiontaking_87_max,
		MAX(CASE WHEN CO3.bettype = 89 AND CO3.sporttype = 161 THEN CASE WHEN @v161mlivepositiontaking_89_max < CO3.maxlivepositiontaking THEN @v161mlivepositiontaking_89_max ELSE CO3.maxlivepositiontaking END ELSE 0 END) AS v161mlivepositiontaking_89_max,
		MAX(CASE WHEN CO3.bettype = 90 AND CO3.sporttype = 161 THEN CASE WHEN @v161mlivepositiontaking_90_max < CO3.maxlivepositiontaking THEN @v161mlivepositiontaking_90_max ELSE CO3.maxlivepositiontaking END ELSE 0 END) AS v161mlivepositiontaking_90_max,
			
		-- number game
		CI.DisableNumber
		---------------------------------------------------------------------
	FROM 
		customer AS C WITH (NOLOCK) 
		INNER JOIN custinfo AS CI WITH (NOLOCK) on c.custid = CI.custid
		INNER JOIN custsetting AS cs WITH (NOLOCK) on c.custid = cs.custid
		INNER JOIN custsetting3rd AS CS3 WITH(NOLOCK) on c.custid = CS3.custid
		INNER JOIN custoverride AS co WITH (NOLOCK) on co.custid = cs.custid AND co.sporttype=cs.sporttype AND co.bettype=cs.bettype
		LEFT JOIN custoverride3rd AS CO3 WITH(NOLOCK) on CO3.custid = CS3.custid AND CO3.sporttype = CS3.sporttype AND CO3.bettype = CS3.bettype
	WHERE 
		C.roleid=3 
		AND C.custid=@CustID 
		AND C.srecommend=@Srecommend
	GROUP BY
		C.firstname, C.lastname, C.roleid, C.username,
		C.phone, C.mobilephone, C.email,C.fax,
		-- number game
		CI.maxpermatch161,
		CI.maxpermatch164,
		CI.maxperball161,
		-- number game
		CI.DisableNumber
END
GO



