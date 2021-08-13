/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[SLI_CustomerSelCustomer]
	@CustID int
AS
BEGIN
/*
Created: Tiara
Task : VIEW MEMBER
DB: DBCUST/CustDB
Original: Acc_CustomerSelEditCustomer

Revisions:
    - 20200601@Tiara: View Member setting information on NAP-U3 site [Redmine: #123584]  
	- 20210721@Winfred: Remove Comm and get PT SMA on U3 site [Redmine: #123584]
 
Param's Explanation:
• @CustID: member ID
*/


	DECLARE @MinBetv161_Max money, @MaxBetv161_Min money, @MaxPerMatchv161_Min money, @MaxPerMatchv161_Max money, @MaxPerBallv161_Max money,
			@MinBetv164_Max money, @MaxBetv164_Min money, @MaxPerMatchv164_Min money, @MaxPerMatchv164_Max money,
		
		@v161ap_81 smallmoney,@v161ap_83 smallmoney,@v161ap_86 smallmoney,@v161ap_88 smallmoney,
		@v161alp_85 smallmoney,@v161alp_86 smallmoney,@v161alp_87 smallmoney,@v161alp_89 smallmoney,@v161alp_90 smallmoney,
		@CS_v161ap_81 smallmoney,@CS_v161ap_83 smallmoney,@CS_v161ap_86 smallmoney,@CS_v161ap_88 smallmoney,
		@CS_v161alp_85 smallmoney,@CS_v161alp_86 smallmoney,@CS_v161alp_87 smallmoney,@CS_v161alp_89 smallmoney,@CS_v161alp_90 smallmoney,

		@v161sp_81 smallmoney,@v161sp_83 smallmoney,@v161sp_86 smallmoney,@v161sp_88 smallmoney,
		@v161slp_85 smallmoney, @v161slp_86 smallmoney,@v161slp_87 smallmoney,@v161slp_89 smallmoney,@v161slp_90 smallmoney
	----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	DECLARE @srecommend  INT, @mrecommend INT, @recommend INT
	SELECT	@srecommend  = srecommend  ,@mrecommend = mrecommend, @recommend=recommend 
	FROM custinfo WITH (NOLOCK) 
	WHERE custid = @custid


	----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	DECLARE 
		--v161
		@v161apositiontaking_81_max smallmoney,
		@v161apositiontaking_83_max smallmoney,
		@v161apositiontaking_86_max smallmoney,
		@v161apositiontaking_88_max smallmoney,
		@v161alivepositiontaking_85_max smallmoney,
		@v161alivepositiontaking_86_max smallmoney,
		@v161alivepositiontaking_87_max smallmoney,
		@v161alivepositiontaking_89_max smallmoney,
		@v161alivepositiontaking_90_max smallmoney,

		@v161apositiontaking_81_min smallmoney,
		@v161apositiontaking_83_min smallmoney,
		@v161apositiontaking_86_min smallmoney,
		@v161apositiontaking_88_min smallmoney,
		@v161alivepositiontaking_85_min smallmoney,
		@v161alivepositiontaking_86_min smallmoney,
		@v161alivepositiontaking_87_min smallmoney,
		@v161alivepositiontaking_89_min smallmoney,
		@v161alivepositiontaking_90_min smallmoney


	SELECT
		--v161
		@v161apositiontaking_81_max = MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CASE WHEN CS3.apositiontaking<CO3.maxpositiontaking THEN CS3.apositiontaking ELSE CO3.maxpositiontaking END ELSE 0 END),
		@v161apositiontaking_83_max = MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype=161 THEN CASE WHEN CS3.apositiontaking<CO3.maxpositiontaking THEN CS3.apositiontaking ELSE CO3.maxpositiontaking END ELSE 0 END),	
		@v161apositiontaking_86_max = MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CASE WHEN CS3.apositiontaking<CO3.maxpositiontaking THEN CS3.apositiontaking ELSE CO3.maxpositiontaking END ELSE 0 END),
		@v161apositiontaking_88_max = MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype=161 THEN CASE WHEN CS3.apositiontaking<CO3.maxpositiontaking THEN CS3.apositiontaking ELSE CO3.maxpositiontaking END ELSE 0 END),
	
		@v161alivepositiontaking_85_max = MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype=161 THEN CASE WHEN CS3.alivepositiontaking<CO3.maxlivepositiontaking THEN CS3.alivepositiontaking ELSE CO3.maxlivepositiontaking END ELSE 0 END),
		@v161alivepositiontaking_86_max = MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CASE WHEN CS3.alivepositiontaking<CO3.maxlivepositiontaking THEN CS3.alivepositiontaking ELSE CO3.maxlivepositiontaking END ELSE 0 END),
		@v161alivepositiontaking_87_max = MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype=161 THEN CASE WHEN CS3.alivepositiontaking<CO3.maxlivepositiontaking THEN CS3.alivepositiontaking ELSE CO3.maxlivepositiontaking END ELSE 0 END),
		@v161alivepositiontaking_89_max = MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype=161 THEN CASE WHEN CS3.alivepositiontaking<CO3.maxlivepositiontaking THEN CS3.alivepositiontaking ELSE CO3.maxlivepositiontaking END ELSE 0 END),
		@v161alivepositiontaking_90_max = MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype=161 THEN CASE WHEN CS3.alivepositiontaking<CO3.maxlivepositiontaking THEN CS3.alivepositiontaking ELSE CO3.maxlivepositiontaking END ELSE 0 END),

		@v161apositiontaking_81_min = MAX(CASE WHEN CO3.bettype = 81 AND CO3.sporttype=161 THEN CO3.minpositiontaking ELSE 0 END),
		@v161apositiontaking_83_min = MAX(CASE WHEN CO3.bettype = 83 AND CO3.sporttype=161 THEN CO3.minpositiontaking ELSE 0 END),
		@v161apositiontaking_86_min = MAX(CASE WHEN CO3.bettype = 86 AND CO3.sporttype=161 THEN CO3.minpositiontaking ELSE 0 END),
		@v161apositiontaking_88_min = MAX(CASE WHEN CO3.bettype = 88 AND CO3.sporttype=161 THEN CO3.minpositiontaking ELSE 0 END),
	
		@v161alivepositiontaking_85_min = MAX(CASE WHEN CO3.bettype = 85 AND CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END),
		@v161alivepositiontaking_86_min = MAX(CASE WHEN CO3.bettype = 86 AND CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END),
		@v161alivepositiontaking_87_min = MAX(CASE WHEN CO3.bettype = 87 AND CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END),
		@v161alivepositiontaking_89_min = MAX(CASE WHEN CO3.bettype = 89 AND CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END),
		@v161alivepositiontaking_90_min = MAX(CASE WHEN CO3.bettype = 90 AND CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END)
	FROM
		CustSetting3rd AS CS3 WITH (NOLOCK) 
		LEFT JOIN CustOverride3rd AS CO3 WITH (NOLOCK) ON CO3.custid = CS3.custid 
														AND CO3.sporttype = CS3.sporttype 
														AND CO3.bettype = CS3.bettype
	WHERE CS3.CustID = @recommend


	SELECT 
		@MinBetv161_Max = MAX(CASE WHEN MinBet = 0 THEN NULL ELSE MinBet END), 
		@MaxBetv161_Min = MIN(CASE WHEN MaxBet = 0 THEN NULL ELSE MaxBet END)
	FROM 
		custsetting3rd AS CS WITH (NOLOCK)
		INNER JOIN custinfo AS CI WITH (NOLOCK) ON (CS.CustID = CI.recommend OR CS.CustID = CI.Mrecommend OR CS.CustID = CI.srecommend )
		AND CS.bettype = 81 AND CS.sporttype=161
	WHERE CI.custid = @CustID

	SELECT 
		@MinBetv164_Max = MAX(CASE WHEN MinBet = 0 THEN NULL ELSE MinBet END), 
		@MaxBetv164_Min = MIN(CASE WHEN MaxBet = 0 THEN NULL ELSE MaxBet END)
	FROM 
		custsetting3rd AS CS WITH (NOLOCK)
		INNER JOIN custinfo AS CI WITH (NOLOCK) ON (CS.CustID = CI.recommend OR CS.CustID = CI.Mrecommend OR CS.CustID = CI.srecommend )
		AND CS.bettype = 8101 AND CS.sporttype=164
	WHERE CI.custid = @CustID

	SELECT
		@MaxPerMatchv161_Min = 0,
		@MaxPerMatchv161_Max = MIN(CASE WHEN CS.MaxPerMatch161 = 0 THEN NULL ELSE CS.MaxPerMatch161 END),	
		@MaxPerBallv161_Max = MIN(CASE WHEN CS.MaxPerBall161 = 0  THEN NULL ELSE CS.MaxPerBall161 END),
		@MaxPerMatchv164_Min = 0,
		@MaxPerMatchv164_Max = MIN(CASE WHEN CS.MaxPerMatch164 = 0 THEN NULL ELSE CS.MaxPerMatch164 END)	
	FROM 
		custinfo AS CS WITH (NOLOCK) 
		INNER JOIN custinfo AS CI WITH (NOLOCK) ON (CS.CustID = CI.recommend OR CS.CustID = CI.Mrecommend OR CS.CustID = CI.srecommend )
	WHERE CI.custid = @CustID

	SELECT
		--v161
		@v161sp_81 = MAX(CASE WHEN SCS3.bettype = 81 AND SCS3.sporttype=161 THEN SCS3.spositiontaking ELSE 0 END),
		@v161sp_83 = MAX(CASE WHEN SCS3.bettype = 83 AND SCS3.sporttype=161 THEN SCS3.spositiontaking ELSE 0 END),
		@v161sp_86 = MAX(CASE WHEN SCS3.bettype = 86 AND SCS3.sporttype=161 THEN SCS3.spositiontaking ELSE 0 END),
		@v161sp_88 = MAX(CASE WHEN SCS3.bettype = 88 AND SCS3.sporttype=161 THEN SCS3.spositiontaking ELSE 0 END),
		@v161slp_85 = MAX(CASE WHEN SCS3.bettype = 85 AND SCS3.sporttype=161 THEN SCS3.slivepositiontaking ELSE 0 END),	
		@v161slp_86 = MAX(CASE WHEN SCS3.bettype = 86 AND SCS3.sporttype=161 THEN SCS3.slivepositiontaking ELSE 0 END),	
		@v161slp_87 = MAX(CASE WHEN SCS3.bettype = 87 AND SCS3.sporttype=161 THEN SCS3.slivepositiontaking ELSE 0 END),
		@v161slp_89 = MAX(CASE WHEN SCS3.bettype = 89 AND SCS3.sporttype=161 THEN SCS3.slivepositiontaking ELSE 0 END),
		@v161slp_90 = MAX(CASE WHEN SCS3.bettype = 90 AND SCS3.sporttype=161 THEN SCS3.slivepositiontaking ELSE 0 END),
	
		--v161
		--@apos_max = min(a4,a2,l2)
		@v161apositiontaking_81_max = MAX(CASE WHEN SCS3.bettype = 81 AND SCS3.sporttype=161 THEN CASE WHEN SCS3.apositiontaking<@v161apositiontaking_81_max THEN SCS3.apositiontaking ELSE @v161apositiontaking_81_max END ELSE 0 END),
		@v161apositiontaking_83_max = MAX(CASE WHEN SCS3.bettype = 83 AND SCS3.sporttype=161 THEN CASE WHEN SCS3.apositiontaking<@v161apositiontaking_83_max THEN SCS3.apositiontaking ELSE @v161apositiontaking_83_max END ELSE 0 END),	
		@v161apositiontaking_86_max = MAX(CASE WHEN SCS3.bettype = 86 AND SCS3.sporttype=161 THEN CASE WHEN SCS3.apositiontaking<@v161apositiontaking_86_max THEN SCS3.apositiontaking ELSE @v161apositiontaking_86_max END ELSE 0 END),
		@v161apositiontaking_88_max = MAX(CASE WHEN SCS3.bettype = 88 AND SCS3.sporttype=161 THEN CASE WHEN SCS3.apositiontaking<@v161apositiontaking_88_max THEN SCS3.apositiontaking ELSE @v161apositiontaking_88_max END ELSE 0 END),
	
		@v161alivepositiontaking_85_max = MAX(CASE WHEN SCS3.bettype = 85 AND SCS3.sporttype=161 THEN CASE WHEN SCS3.alivepositiontaking<@v161alivepositiontaking_85_max THEN SCS3.alivepositiontaking ELSE @v161alivepositiontaking_85_max END ELSE 0 END),
		@v161alivepositiontaking_86_max = MAX(CASE WHEN SCS3.bettype = 86 AND SCS3.sporttype=161 THEN CASE WHEN SCS3.alivepositiontaking<@v161alivepositiontaking_86_max THEN SCS3.alivepositiontaking ELSE @v161alivepositiontaking_86_max END ELSE 0 END),
		@v161alivepositiontaking_87_max = MAX(CASE WHEN SCS3.bettype = 87 AND SCS3.sporttype=161 THEN CASE WHEN SCS3.alivepositiontaking<@v161alivepositiontaking_87_max THEN SCS3.alivepositiontaking ELSE @v161alivepositiontaking_87_max END ELSE 0 END),
		@v161alivepositiontaking_89_max = MAX(CASE WHEN SCS3.bettype = 89 AND SCS3.sporttype=161 THEN CASE WHEN SCS3.alivepositiontaking<@v161alivepositiontaking_89_max THEN SCS3.alivepositiontaking ELSE @v161alivepositiontaking_89_max END ELSE 0 END),
		@v161alivepositiontaking_90_max = MAX(CASE WHEN SCS3.bettype = 90 AND SCS3.sporttype=161 THEN CASE WHEN SCS3.alivepositiontaking<@v161alivepositiontaking_90_max THEN SCS3.alivepositiontaking ELSE @v161alivepositiontaking_90_max END ELSE 0 END)
	FROM
		CustSetting3rd AS SCS3 WITH (NOLOCK)
	WHERE 
		SCS3.custid = @srecommend 
	--PRINT 's4: ' + convert(varchar(10),@v2sp_9)

	--=iff(im,a2:iif(i1|i3,m3-m1,min(m3-m1,s4-s1-m1)))
	SELECT
		--v161
		@CS_v161ap_81 = MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CASE WHEN (aCS3.isautompositiontaking = 1 or CS3.isautompositiontaking = 1) THEN aCS3.apositiontaking ELSE CASE WHEN not (CS3.isautopositiontaking=0 AND mCS3.isautopositiontaking=0 ) THEN mCS3.mpositiontaking-CS3.mpositiontaking ELSE CASE WHEN mCS3.mpositiontaking-CS3.mpositiontaking<=@v161sp_81-CS3.spositiontaking-CS3.mpositiontaking THEN  mCS3.mpositiontaking-CS3.mpositiontaking ELSE @v161sp_81-CS3.spositiontaking-CS3.mpositiontaking END END END ELSE 0 END),
		@CS_v161ap_83 = MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype=161 THEN CASE WHEN (aCS3.isautompositiontaking = 1 or CS3.isautompositiontaking = 1) THEN aCS3.apositiontaking ELSE CASE WHEN not (CS3.isautopositiontaking=0 AND mCS3.isautopositiontaking=0 ) THEN mCS3.mpositiontaking-CS3.mpositiontaking ELSE CASE WHEN mCS3.mpositiontaking-CS3.mpositiontaking<=@v161sp_83-CS3.spositiontaking-CS3.mpositiontaking THEN  mCS3.mpositiontaking-CS3.mpositiontaking ELSE @v161sp_83-CS3.spositiontaking-CS3.mpositiontaking END END END ELSE 0 END),
		@CS_v161ap_86 = MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CASE WHEN (aCS3.isautompositiontaking = 1 or CS3.isautompositiontaking = 1) THEN aCS3.apositiontaking ELSE CASE WHEN not (CS3.isautopositiontaking=0 AND mCS3.isautopositiontaking=0 ) THEN mCS3.mpositiontaking-CS3.mpositiontaking ELSE CASE WHEN mCS3.mpositiontaking-CS3.mpositiontaking<=@v161sp_86-CS3.spositiontaking-CS3.mpositiontaking THEN  mCS3.mpositiontaking-CS3.mpositiontaking ELSE @v161sp_86-CS3.spositiontaking-CS3.mpositiontaking END END END ELSE 0 END),
		@CS_v161ap_88 = MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype=161 THEN CASE WHEN (aCS3.isautompositiontaking = 1 or CS3.isautompositiontaking = 1) THEN aCS3.apositiontaking ELSE CASE WHEN not (CS3.isautopositiontaking=0 AND mCS3.isautopositiontaking=0 ) THEN mCS3.mpositiontaking-CS3.mpositiontaking ELSE CASE WHEN mCS3.mpositiontaking-CS3.mpositiontaking<=@v161sp_88-CS3.spositiontaking-CS3.mpositiontaking THEN  mCS3.mpositiontaking-CS3.mpositiontaking ELSE @v161sp_88-CS3.spositiontaking-CS3.mpositiontaking END END END ELSE 0 END),
		@CS_v161alp_85 = MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype=161 THEN CASE WHEN (aCS3.isautolivempositiontaking = 1 or CS3.isautolivempositiontaking = 1) THEN aCS3.alivepositiontaking ELSE CASE WHEN not (CS3.isautolivepositiontaking=0 AND mCS3.isautolivepositiontaking=0 ) THEN mCS3.mlivepositiontaking-CS3.mlivepositiontaking ELSE CASE WHEN mCS3.mlivepositiontaking-CS3.mlivepositiontaking<=@v161slp_85-CS3.slivepositiontaking-CS3.mlivepositiontaking THEN  mCS3.mlivepositiontaking-CS3.mlivepositiontaking ELSE @v161slp_85-CS3.slivepositiontaking-CS3.mlivepositiontaking END END END ELSE 0 END),
		@CS_v161alp_86 = MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CASE WHEN (aCS3.isautolivempositiontaking = 1 or CS3.isautolivempositiontaking = 1) THEN aCS3.alivepositiontaking ELSE CASE WHEN not (CS3.isautolivepositiontaking=0 AND mCS3.isautolivepositiontaking=0 ) THEN mCS3.mlivepositiontaking-CS3.mlivepositiontaking ELSE CASE WHEN mCS3.mlivepositiontaking-CS3.mlivepositiontaking<=@v161slp_86-CS3.slivepositiontaking-CS3.mlivepositiontaking THEN  mCS3.mlivepositiontaking-CS3.mlivepositiontaking ELSE @v161slp_86-CS3.slivepositiontaking-CS3.mlivepositiontaking END END END ELSE 0 END),
		@CS_v161alp_87 = MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype=161 THEN CASE WHEN (aCS3.isautolivempositiontaking = 1 or CS3.isautolivempositiontaking = 1) THEN aCS3.alivepositiontaking ELSE CASE WHEN not (CS3.isautolivepositiontaking=0 AND mCS3.isautolivepositiontaking=0 ) THEN mCS3.mlivepositiontaking-CS3.mlivepositiontaking ELSE CASE WHEN mCS3.mlivepositiontaking-CS3.mlivepositiontaking<=@v161slp_87-CS3.slivepositiontaking-CS3.mlivepositiontaking THEN  mCS3.mlivepositiontaking-CS3.mlivepositiontaking ELSE @v161slp_87-CS3.slivepositiontaking-CS3.mlivepositiontaking END END END ELSE 0 END),
		@CS_v161alp_89 = MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype=161 THEN CASE WHEN (aCS3.isautolivempositiontaking = 1 or CS3.isautolivempositiontaking = 1) THEN aCS3.alivepositiontaking ELSE CASE WHEN not (CS3.isautolivepositiontaking=0 AND mCS3.isautolivepositiontaking=0 ) THEN mCS3.mlivepositiontaking-CS3.mlivepositiontaking ELSE CASE WHEN mCS3.mlivepositiontaking-CS3.mlivepositiontaking<=@v161slp_89-CS3.slivepositiontaking-CS3.mlivepositiontaking THEN  mCS3.mlivepositiontaking-CS3.mlivepositiontaking ELSE @v161slp_89-CS3.slivepositiontaking-CS3.mlivepositiontaking END END END ELSE 0 END),
		@CS_v161alp_90 = MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype=161 THEN CASE WHEN (aCS3.isautolivempositiontaking = 1 or CS3.isautolivempositiontaking = 1) THEN aCS3.alivepositiontaking ELSE CASE WHEN not (CS3.isautolivepositiontaking=0 AND mCS3.isautolivepositiontaking=0 ) THEN mCS3.mlivepositiontaking-CS3.mlivepositiontaking ELSE CASE WHEN mCS3.mlivepositiontaking-CS3.mlivepositiontaking<=@v161slp_90-CS3.slivepositiontaking-CS3.mlivepositiontaking THEN  mCS3.mlivepositiontaking-CS3.mlivepositiontaking ELSE @v161slp_90-CS3.slivepositiontaking-CS3.mlivepositiontaking END END END ELSE 0 END)
	FROM
		Customer AS C WITH (NOLOCK)	
		INNER JOIN CustSetting3rd AS CS3 WITH (NOLOCK)  ON CS3.custid = C.custid
		INNER JOIN custsetting3rd AS MCS3 WITH (NOLOCK) ON MCS3.custid = C.mrecommend AND MCS3.bettype = CS3.bettype AND MCS3.sporttype = CS3.sporttype
		INNER JOIN custsetting3rd AS ACS3 WITH (NOLOCK) ON ACS3.custid = C.recommend AND ACS3.bettype = CS3.bettype AND ACS3.sporttype = CS3.sporttype
	WHERE C.custid = @custid

	--PRINT 'ap: ' + convert(varchar(10),@CS_v2ap_9)

	SELECT 
		--v161
		@v161apositiontaking_81_max = CASE WHEN @v161apositiontaking_81_max <= @CS_v161ap_81 THEN @v161apositiontaking_81_max ELSE @CS_v161ap_81 END,
		@v161apositiontaking_83_max = CASE WHEN @v161apositiontaking_83_max <= @CS_v161ap_83 THEN @v161apositiontaking_83_max ELSE @CS_v161ap_83 END,	
		@v161apositiontaking_86_max = CASE WHEN @v161apositiontaking_86_max <= @CS_v161ap_86 THEN @v161apositiontaking_86_max ELSE @CS_v161ap_86 END,
		@v161apositiontaking_88_max = CASE WHEN @v161apositiontaking_88_max <= @CS_v161ap_88 THEN @v161apositiontaking_88_max ELSE @CS_v161ap_88 END,
		@v161alivepositiontaking_85_max = CASE WHEN @v161alivepositiontaking_85_max <= @CS_v161alp_85 THEN @v161alivepositiontaking_85_max ELSE @CS_v161alp_85 END,
		@v161alivepositiontaking_86_max = CASE WHEN @v161alivepositiontaking_86_max <= @CS_v161alp_86 THEN @v161alivepositiontaking_86_max ELSE @CS_v161alp_86 END,
		@v161alivepositiontaking_87_max = CASE WHEN @v161alivepositiontaking_87_max <= @CS_v161alp_87 THEN @v161alivepositiontaking_87_max ELSE @CS_v161alp_87 END,
		@v161alivepositiontaking_89_max = CASE WHEN @v161alivepositiontaking_89_max <= @CS_v161alp_89 THEN @v161alivepositiontaking_89_max ELSE @CS_v161alp_89 END,
		@v161alivepositiontaking_90_max = CASE WHEN @v161alivepositiontaking_90_max <= @CS_v161alp_90 THEN @v161alivepositiontaking_90_max ELSE @CS_v161alp_90 END

	SELECT 
		C.FirstName, 
		C.LastName, 
		C.RoleID, 
		C.UserName, 
		ISNULL(C.phone,'') AS Phone, 
		ISNULL(C.mobilephone,'') AS MobilePhone, 
		ISNULL(C.email,'') AS Email, 
		ISNULL(C.fax,'') AS Fax, 
		ISNULL(CI.maxpermatch161, 0)	AS MaxPerMatchv161,
		ISNULL(CI.maxperball161,0)		AS MaxPerBallv161,	
		ISNULL(CI.maxpermatch164, 0)	AS MaxPerMatchv164,			
		ISNULL(MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.minbet ELSE 0 END), 0) AS MinBetv161,
		ISNULL(MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.maxbet ELSE 0 END), 0) AS MaxBetv161,	
		ISNULL(MAX(CASE WHEN CS3.bettype = 8101 AND CS3.sporttype=164 THEN CS3.minbet ELSE 0 END), 0) AS MinBetv164,
		ISNULL(MAX(CASE WHEN CS3.bettype = 8101 AND CS3.sporttype=164 THEN CS3.maxbet ELSE 0 END), 0) AS MaxBetv164,		
	
		--v161
		ISNULL(MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END), 0) AS v161aPositionTaking_81,
		ISNULL(MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END), 0) AS v161aPositionTaking_83,
		ISNULL(MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END), 0) AS v161aPositionTaking_86,
		ISNULL(MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END), 0) AS v161aPositionTaking_88,
		
		ISNULL(MAX(CASE WHEN cs3.bettype = 81 AND cs3.sporttype=161 THEN cs3.mpositiontaking ELSE 0 END), 0) AS v161mPositionTaking_81,    
		ISNULL(MAX(CASE WHEN cs3.bettype = 83 AND cs3.sporttype=161 THEN cs3.mpositiontaking ELSE 0 END), 0) AS v161mPositionTaking_83,    
		ISNULL(MAX(CASE WHEN cs3.bettype = 86 AND cs3.sporttype=161 THEN cs3.mpositiontaking ELSE 0 END), 0) AS v161mPositionTaking_86,    
		ISNULL(MAX(CASE WHEN cs3.bettype = 88 AND cs3.sporttype=161 THEN cs3.mpositiontaking ELSE 0 END), 0) AS v161mPositionTaking_88,    
		  
		ISNULL(MAX(CASE WHEN cs3.bettype = 81 AND cs3.sporttype=161 THEN cs3.spositiontaking ELSE 0 END), 0) AS v161sPositionTaking_81,    
		ISNULL(MAX(CASE WHEN cs3.bettype = 83 AND cs3.sporttype=161 THEN cs3.spositiontaking ELSE 0 END), 0) AS v161sPositionTaking_83,    
		ISNULL(MAX(CASE WHEN cs3.bettype = 86 AND cs3.sporttype=161 THEN cs3.spositiontaking ELSE 0 END), 0) AS v161sPositionTaking_86,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 88 AND cs3.sporttype=161 THEN cs3.spositiontaking ELSE 0 END), 0) AS v161sPositionTaking_88,    
  
  		ISNULL(MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END), 0) AS v161aLivePositionTaking_85,
		ISNULL(MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END), 0) AS v161aLivePositionTaking_86,
		ISNULL(MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END), 0) AS v161aLivePositionTaking_87,
		ISNULL(MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END), 0) AS v161aLivePositionTaking_89,
		ISNULL(MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END), 0) AS v161aLivePositionTaking_90,

		ISNULL(MAX(CASE WHEN cs3.bettype = 85 AND cs3.sporttype=161 THEN cs3.mlivepositiontaking ELSE 0 END), 0) AS v161mLivePositionTaking_85,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 86 AND cs3.sporttype=161 THEN cs3.mlivepositiontaking ELSE 0 END), 0) AS v161mLivePositionTaking_86,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 87 AND cs3.sporttype=161 THEN cs3.mlivepositiontaking ELSE 0 END), 0) AS v161mLivePositionTaking_87,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 89 AND cs3.sporttype=161 THEN cs3.mlivepositiontaking ELSE 0 END), 0) AS v161mLivePositionTaking_89,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 90 AND cs3.sporttype=161 THEN cs3.mlivepositiontaking ELSE 0 END), 0) AS v161mLivePositionTaking_90,  

		ISNULL(MAX(CASE WHEN cs3.bettype = 85 AND cs3.sporttype=161 THEN cs3.slivepositiontaking ELSE 0 END), 0) AS v161sLivePositionTaking_85,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 86 AND cs3.sporttype=161 THEN cs3.slivepositiontaking ELSE 0 END), 0) AS v161sLivePositionTaking_86,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 87 AND cs3.sporttype=161 THEN cs3.slivepositiontaking ELSE 0 END), 0) AS v161sLivePositionTaking_87,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 89 AND cs3.sporttype=161 THEN cs3.slivepositiontaking ELSE 0 END), 0) AS v161sLivePositionTaking_89,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 90 AND cs3.sporttype=161 THEN cs3.slivepositiontaking ELSE 0 END), 0) AS v161sLivePositionTaking_90,  
		
		ISNULL(MAX(CASE when cs3.bettype = 81 and cs3.sporttype=161 then cs3.autompositiontaking else 0 end), 0) as Auto_v161mPositionTaking_81,  
		ISNULL(MAX(CASE when cs3.bettype = 83 and cs3.sporttype=161 then cs3.autompositiontaking else 0 end), 0) as Auto_v161mPositionTaking_83,  
		ISNULL(MAX(CASE when cs3.bettype = 86 and cs3.sporttype=161 then cs3.autompositiontaking else 0 end), 0) as Auto_v161mPositionTaking_86,  
		ISNULL(MAX(CASE when cs3.bettype = 88 and cs3.sporttype=161 then cs3.autompositiontaking else 0 end), 0) as Auto_v161mPositionTaking_88,  
		  
		ISNULL(MAX(CASE WHEN cs3.bettype = 85 and cs3.sporttype=161 then cs3.autolivempositiontaking else 0 end), 0) as Auto_v161mLivePositionTaking_85,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 86 and cs3.sporttype=161 then cs3.autolivempositiontaking else 0 end), 0) as Auto_v161mLivePositionTaking_86,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 87 and cs3.sporttype=161 then cs3.autolivempositiontaking else 0 end), 0) as Auto_v161mLivePositionTaking_87,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 89 and cs3.sporttype=161 then cs3.autolivempositiontaking else 0 end), 0) as Auto_v161mLivePositionTaking_89,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 90 and cs3.sporttype=161 then cs3.autolivempositiontaking else 0 end), 0) as Auto_v161mLivePositionTaking_90,  
	
		ISNULL(MAX(CASE WHEN cs3.bettype = 81 AND cs3.sporttype=161 THEN cs3.autopositiontaking ELSE 0 END), 0) AS Auto_v161sPositionTaking_81,   
		ISNULL(MAX(CASE WHEN cs3.bettype = 83 AND cs3.sporttype=161 THEN cs3.autopositiontaking ELSE 0 END), 0) AS Auto_v161sPositionTaking_83,   
		ISNULL(MAX(CASE WHEN cs3.bettype = 86 AND cs3.sporttype=161 THEN cs3.autopositiontaking ELSE 0 END), 0) AS Auto_v161sPositionTaking_86, 
		ISNULL(MAX(CASE WHEN cs3.bettype = 88 AND cs3.sporttype=161 THEN cs3.autopositiontaking ELSE 0 END), 0) AS Auto_v161sPositionTaking_88,   
		    
		ISNULL(MAX(CASE WHEN cs3.bettype = 85 AND cs3.sporttype=161 THEN cs3.autolivepositiontaking ELSE 0 END), 0) AS Auto_v161sLivePositionTaking_85,   
		ISNULL(MAX(CASE WHEN cs3.bettype = 86 AND cs3.sporttype=161 THEN cs3.autolivepositiontaking ELSE 0 END), 0) AS Auto_v161sLivePositionTaking_86,   
		ISNULL(MAX(CASE WHEN cs3.bettype = 87 AND cs3.sporttype=161 THEN cs3.autolivepositiontaking ELSE 0 END), 0) AS Auto_v161sLivePositionTaking_87,   
		ISNULL(MAX(CASE WHEN cs3.bettype = 89 AND cs3.sporttype=161 THEN cs3.autolivepositiontaking ELSE 0 END), 0) AS Auto_v161sLivePositionTaking_89,   
		ISNULL(MAX(CASE WHEN cs3.bettype = 90 AND cs3.sporttype=161 THEN cs3.autolivepositiontaking ELSE 0 END), 0) AS Auto_v161sLivePositionTaking_90,
		
		ISNULL(MAX(CASE WHEN cs3.bettype = 81 AND cs3.sporttype=161 THEN cs3.isautopositiontaking ELSE 0 END), 0) AS IsAuto_v161sPositionTaking_81,   
		ISNULL(MAX(CASE WHEN cs3.bettype = 83 AND cs3.sporttype=161 THEN cs3.isautopositiontaking ELSE 0 END), 0) AS IsAuto_v161sPositionTaking_83,   
		ISNULL(MAX(CASE WHEN cs3.bettype = 86 AND cs3.sporttype=161 THEN cs3.isautopositiontaking ELSE 0 END), 0) AS IsAuto_v161sPositionTaking_86,   
		ISNULL(MAX(CASE WHEN cs3.bettype = 88 AND cs3.sporttype=161 THEN cs3.isautopositiontaking ELSE 0 END), 0) AS IsAuto_v161sPositionTaking_88,   
		    
		ISNULL(MAX(CASE WHEN cs3.bettype = 85 AND cs3.sporttype=161 THEN cs3.isautolivepositiontaking ELSE 0 END), 0)  AS IsAuto_v161sLivePositionTaking_85,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 86 AND cs3.sporttype=161 THEN cs3.isautolivepositiontaking ELSE 0 END), 0)  AS IsAuto_v161sLivePositionTaking_86,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 87 AND cs3.sporttype=161 THEN cs3.isautolivepositiontaking ELSE 0 END), 0)  AS IsAuto_v161sLivePositionTaking_87,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 89 AND cs3.sporttype=161 THEN cs3.isautolivepositiontaking ELSE 0 END), 0)  AS IsAuto_v161sLivePositionTaking_89,  
		ISNULL(MAX(CASE WHEN cs3.bettype = 90 AND cs3.sporttype=161 THEN cs3.isautolivepositiontaking ELSE 0 END), 0)  AS IsAuto_v161sLivePositionTaking_90,  
		
		ISNULL(max(case when cs3.bettype = 81 and cs3.sporttype=161 then cs3.isautompositiontaking else 0 end), 0) AS IsAuto_v161mPositionTaking_81,
		ISNULL(max(case when cs3.bettype = 83 and cs3.sporttype=161 then cs3.isautompositiontaking else 0 end), 0) AS IsAuto_v161mPositionTaking_83,
		ISNULL(max(case when cs3.bettype = 86 and cs3.sporttype=161 then cs3.isautompositiontaking else 0 end), 0) AS IsAuto_v161mPositionTaking_86,
		ISNULL(max(case when cs3.bettype = 88 and cs3.sporttype=161 then cs3.isautompositiontaking else 0 end), 0) AS IsAuto_v161mPositionTaking_88,
		  
		ISNULL(max(case when cs3.bettype = 85 and cs3.sporttype=161 then cs3.isautolivempositiontaking else 0 end), 0) AS IsAuto_v161mLivePositionTaking_85,  
		ISNULL(max(case when cs3.bettype = 86 and cs3.sporttype=161 then cs3.isautolivempositiontaking else 0 end), 0) AS IsAuto_v161mLivePositionTaking_86,  
		ISNULL(max(case when cs3.bettype = 87 and cs3.sporttype=161 then cs3.isautolivempositiontaking else 0 end), 0) AS IsAuto_v161mLivePositionTaking_87,  
		ISNULL(max(case when cs3.bettype = 89 and cs3.sporttype=161 then cs3.isautolivempositiontaking else 0 end), 0) AS IsAuto_v161mLivePositionTaking_89,  
		ISNULL(max(case when cs3.bettype = 90 and cs3.sporttype=161 then cs3.isautolivempositiontaking else 0 end), 0) AS IsAuto_v161mLivePositionTaking_90,  
		
		--v161
		ISNULL(@v161apositiontaking_81_max, 0) AS v161aPositionTaking_81_Max,
		ISNULL(@v161apositiontaking_83_max, 0) AS v161aPositionTaking_83_Max,
		ISNULL(@v161apositiontaking_86_max, 0) AS v161aPositionTaking_86_Max,
		ISNULL(@v161apositiontaking_88_max, 0) AS v161aPositionTaking_88_Max,

		ISNULL(@v161alivepositiontaking_85_max, 0) AS v161aLivePositionTaking_85_Max,
		ISNULL(@v161alivepositiontaking_86_max, 0) AS v161aLivePositionTaking_86_Max,
		ISNULL(@v161alivepositiontaking_87_max, 0) AS v161aLivePositionTaking_87_Max,
		ISNULL(@v161alivepositiontaking_89_max, 0) AS v161aLivePositionTaking_89_Max,
		ISNULL(@v161alivepositiontaking_90_max, 0) AS v161aLivePositionTaking_90_Max,

		ISNULL(@MinBetv161_Max, 0)		AS MinBetv161_Max,
		ISNULL(@MaxBetv161_Min, 0)		AS MaxBetv161_Min,	
		ISNULL(@MaxPerMatchv161_Min, 0) AS MaxPerMatchv161_Min,	
		ISNULL(@MaxPerMatchv161_Max, 0) AS MaxPerMatchv161_Max,
		ISNULL(@MaxPerBallv161_Max, 0)	AS MaxPerBallv161_Max,
	
		ISNULL(@MinBetv164_Max, 0) AS MinBetv164_Max,	
		ISNULL(@MaxBetv164_Min, 0) AS MaxBetv164_Min,	
		ISNULL(@MaxPerMatchv164_Min, 0) AS MaxPerMatchv164_Min,	
		ISNULL(@MaxPerMatchv164_Max, 0) AS MaxPerMatchv164_Max,
	
		--v161
		ISNULL(@v161apositiontaking_81_min, 0) AS v161aPositionTaking_81_Min,
		ISNULL(@v161apositiontaking_83_min, 0) AS v161aPositionTaking_83_Min,
		ISNULL(@v161apositiontaking_86_min, 0) AS v161aPositionTaking_86_Min,
		ISNULL(@v161apositiontaking_88_min, 0) AS v161aPositionTaking_88_Min,
		ISNULL(@v161alivepositiontaking_85_min, 0) AS v161aLivePositionTaking_85_Min,
		ISNULL(@v161alivepositiontaking_86_min, 0) AS v161aLivePositionTaking_86_Min,
		ISNULL(@v161alivepositiontaking_87_min, 0) AS v161aLivePositionTaking_87_Min,
		ISNULL(@v161alivepositiontaking_89_min, 0) AS v161aLivePositionTaking_89_Min,
		ISNULL(@v161alivepositiontaking_90_min, 0) AS v161aLivePositionTaking_90_Min,
		CI.DisableNumber
	FROM 
		customer AS C WITH (NOLOCK) 
		INNER JOIN CustInfo AS CI WITH (NOLOCK) ON C.custid = CI.custid
		INNER JOIN CustSetting AS CS WITH (NOLOCK) ON C.custid = CS.custid
		INNER JOIN CustSetting3rd CS3 WITH (NOLOCK) ON CS.custid = CS3.custid
	WHERE C.custid=@CustID
	group by 
		C.username, 
		C.firstname, 
		C.lastname,
		C.email, 
		C.phone, 
		C.mobilephone, 
		C.fax, 	
		-- number game
		CI.maxpermatch161,
		CI.maxperball161,
		CI.maxpermatch164,
		-- number game
		C.site, 
		C.roleid,
		CI.disablenumber
    
END
GO 



