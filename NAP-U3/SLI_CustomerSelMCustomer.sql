/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="" isFunctiON="0"></info>*/
CREATE PROCEDURE [dbo].[SLI_CustomerSelMCustomer]
	@CustId		INT,
	@Mrecommend	INT
AS
BEGIN
/*
Created: Tiara
Task : VIEW AGENT
DB: DBCUST.CustDB
Original: Acc_CustomerSelMEditCustomer

Revisions:
	 - 20200801@Tiara: View Agent setting information on NAP-U3 site [Redmine: #123584] 
	 - 20210721@Winfred: Remove Comm on U3 site [Redmine: #123584]
Param's Explanation:
  @CustID: AgentID
  @Mrecommend
*/

	SET NOCOUNT ON
	--Check Downline Belonging
	DECLARE @roleid tinyint, @Username varchar(30)
	EXEC Age_CustomerSelCheckBelongingByCustID 
		@SessiONCustID = @Mrecommend, 
		@Custid = @custid,
		@Username = @Username OUTPUT,
		@roleid = @roleid OUTPUT
		IF (@roleid = 0) RETURN
	---------------------------

	DECLARE 

		@MinBetv161_Max MONEY,
		@MaxBetv161_Min MONEY,	
		@MaxPerMatchv161_Min MONEY,	
		@MaxPerMatchv161_Max MONEY,
	
		@MaxPerBallv161_Max MONEY,
	
		@MinBetv164_Max MONEY,
		@MaxBetv164_Min MONEY,	
		@MaxPerMatchv164_Min MONEY,	
		@MaxPerMatchv164_Max MONEY
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT 
		@MinBetv161_Max = MAX(CASE WHEN MinBet = 0 THEN NULL ELSE MinBet END), 
		@MaxBetv161_Min = MIN(CASE WHEN MaxBet = 0 THEN NULL ELSE MaxBet END)
	FROM 
		custsetting3rd AS CS WITH (NOLOCK)
		INNER JOIN custinfo AS CI WITH (NOLOCK) ON (CS.CustID = CI.Mrecommend or CS.CustID = CI.Srecommend) AND CS.bettype = 81 AND CS.sporttype=161
	WHERE CI.custid = @CustID

	SELECT 
		@MinBetv164_Max = MAX(CASE WHEN MinBet = 0 THEN NULL ELSE MinBet END), 
		@MaxBetv164_Min = MIN(CASE WHEN MaxBet = 0 THEN NULL ELSE MaxBet END)
	FROM 
		custsetting3rd AS CS WITH (NOLOCK)
		INNER JOIN custinfo AS CI WITH (NOLOCK) ON (CS.CustID = CI.Mrecommend or CS.CustID = CI.Srecommend) AND CS.bettype = 8101 AND CS.sporttype=164
	WHERE CI.custid = @CustID

	SELECT	
		@MaxPerMatchv164_Max = MIN(CASE WHEN CS.MaxPerMatch164 = 0 THEN NULL ELSE CS.MaxPerMatch164 END),	
		@MaxPerMatchv161_Max = MIN(CASE WHEN CS.MaxPerMatch161 = 0 THEN NULL ELSE CS.MaxPerMatch161 END),
		@MaxPerBallv161_Max = MIN(CASE WHEN CS.MaxPerBall161 = 0 THEN NULL ELSE CS.MaxPerBall161 END)
	FROM 
		custinfo AS CS WITH (NOLOCK) 
		INNER JOIN custinfo AS CI WITH (NOLOCK) ON (CS.CustID = CI.Mrecommend or CS.CustID = CI.Srecommend)
	WHERE CI.custid = @CustID

	DECLARE
		@max_v161mapositiontaking_81 SMALLMONEY,
		@max_v161mapositiontaking_83 SMALLMONEY,
		@max_v161mapositiontaking_86 SMALLMONEY,
		@max_v161mapositiontaking_88 SMALLMONEY,
	
		@max_v161malivepositiontaking_85 SMALLMONEY,
		@max_v161malivepositiontaking_86 SMALLMONEY,
		@max_v161malivepositiontaking_87 SMALLMONEY,
		@max_v161malivepositiontaking_89 SMALLMONEY,
		@max_v161malivepositiontaking_90 SMALLMONEY,
	
		@min_v161mapositiontaking_81 SMALLMONEY,
		@min_v161mapositiontaking_83 SMALLMONEY,
		@min_v161mapositiontaking_86 SMALLMONEY,
		@min_v161mapositiontaking_88 SMALLMONEY,
	
		@min_v161malivepositiontaking_85 SMALLMONEY,
		@min_v161malivepositiontaking_86 SMALLMONEY,
		@min_v161malivepositiontaking_87 SMALLMONEY,
		@min_v161malivepositiontaking_89 SMALLMONEY,
		@min_v161malivepositiontaking_90 SMALLMONEY,
	
		@v161apositiontaking_81_max SMALLMONEY,
		@v161apositiontaking_83_max SMALLMONEY,
		@v161apositiontaking_86_max SMALLMONEY,
		@v161apositiontaking_88_max SMALLMONEY,
	
		@v161alivepositiontaking_85_max SMALLMONEY,
		@v161alivepositiontaking_86_max SMALLMONEY,
		@v161alivepositiontaking_87_max SMALLMONEY,
		@v161alivepositiontaking_89_max SMALLMONEY,
		@v161alivepositiontaking_90_max SMALLMONEY
	
	
	SELECT @min_v161mapositiontaking_81 =minpositiontaking, @max_v161mapositiontaking_81 =maxpositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=81 AND sporttype=161
	SELECT @min_v161mapositiontaking_83 =minpositiontaking, @max_v161mapositiontaking_83 =maxpositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=83 AND sporttype=161
	SELECT @min_v161mapositiontaking_86 =minpositiontaking, @max_v161mapositiontaking_86 =maxpositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=86 AND sporttype=161
	SELECT @min_v161mapositiontaking_88 =minpositiontaking, @max_v161mapositiontaking_88 =maxpositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=88 AND sporttype=161

	SELECT @min_v161malivepositiontaking_85 =minlivepositiontaking, @max_v161malivepositiontaking_85 =maxlivepositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=85 AND sporttype=161
	SELECT @min_v161malivepositiontaking_86 =minlivepositiontaking, @max_v161malivepositiontaking_86 =maxlivepositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=86 AND sporttype=161
	SELECT @min_v161malivepositiontaking_87 =minlivepositiontaking, @max_v161malivepositiontaking_87 =maxlivepositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=87 AND sporttype=161
	SELECT @min_v161malivepositiontaking_89 =minlivepositiontaking, @max_v161malivepositiontaking_89 =maxlivepositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=89 AND sporttype=161
	SELECT @min_v161malivepositiontaking_90 =minlivepositiontaking, @max_v161malivepositiontaking_90 =maxlivepositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=90 AND sporttype=161

	SELECT	
		@max_v161mapositiontaking_81 = MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CASE WHEN CS3.mpositiontaking < MCO3.maxpositiontaking THEN CS3.mpositiontaking ELSE MCO3.maxpositiontaking END ELSE 0 END),
		@max_v161mapositiontaking_83 = MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype=161 THEN CASE WHEN CS3.mpositiontaking < MCO3.maxpositiontaking THEN CS3.mpositiontaking ELSE MCO3.maxpositiontaking END ELSE 0 END),
		@max_v161mapositiontaking_86 = MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CASE WHEN CS3.mpositiontaking < MCO3.maxpositiontaking THEN CS3.mpositiontaking ELSE MCO3.maxpositiontaking END ELSE 0 END),
		@max_v161mapositiontaking_88 = MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype=161 THEN CASE WHEN CS3.mpositiontaking < MCO3.maxpositiontaking THEN CS3.mpositiontaking ELSE MCO3.maxpositiontaking END ELSE 0 END),
	
		@max_v161malivepositiontaking_85 = MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype=161 THEN CASE WHEN CS3.mlivepositiontaking < MCO3.maxlivepositiontaking THEN CS3.mlivepositiontaking ELSE MCO3.maxlivepositiontaking END ELSE 0 END),
		@max_v161malivepositiontaking_86 = MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CASE WHEN CS3.mlivepositiontaking < MCO3.maxlivepositiontaking THEN CS3.mlivepositiontaking ELSE MCO3.maxlivepositiontaking END ELSE 0 END),
		@max_v161malivepositiontaking_87 = MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype=161 THEN CASE WHEN CS3.mlivepositiontaking < MCO3.maxlivepositiontaking THEN CS3.mlivepositiontaking ELSE MCO3.maxlivepositiontaking END ELSE 0 END),
		@max_v161malivepositiontaking_89 = MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype=161 THEN CASE WHEN CS3.mlivepositiontaking < MCO3.maxlivepositiontaking THEN CS3.mlivepositiontaking ELSE MCO3.maxlivepositiontaking END ELSE 0 END),
		@max_v161malivepositiontaking_90 = MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype=161 THEN CASE WHEN CS3.mlivepositiontaking < MCO3.maxlivepositiontaking THEN CS3.mlivepositiontaking ELSE MCO3.maxlivepositiontaking END ELSE 0 END)	
	
	FROM
		custsetting AS CS WITH (NOLOCK)
		INNER JOIN custoverride AS MCO WITH (NOLOCK) ON CS.custid = MCO.custid AND CS.sporttype = MCO.sporttype AND CS.bettype = MCO.bettype
		INNER JOIN custoverride3rd AS MCO3 WITH (NOLOCK) ON CS.custid = MCO3.custid 
		INNER JOIN CustSetting3rd AS CS3 WITH (NOLOCK) ON CS3.custid = MCO3.custid AND CS3.sporttype = MCO3.sporttype AND CS3.bettype = MCO3.bettype
	
	WHERE CS.custid = (SELECT mrecommend FROM customer WITH (NOLOCK) WHERE custid = @CustID)

	--get @max_ma = min(m4,m3,l3)
	SELECT		
		@max_v161mapositiontaking_81 = MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CASE WHEN CS3.mpositiontaking < @max_v161mapositiontaking_81 THEN CS3.mpositiontaking ELSE @max_v161mapositiontaking_81 END ELSE 0 END),
		@max_v161mapositiontaking_83 = MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype=161 THEN CASE WHEN CS3.mpositiontaking < @max_v161mapositiontaking_83 THEN CS3.mpositiontaking ELSE @max_v161mapositiontaking_83 END ELSE 0 END),
		@max_v161mapositiontaking_86 = MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CASE WHEN CS3.mpositiontaking < @max_v161mapositiontaking_86 THEN CS3.mpositiontaking ELSE @max_v161mapositiontaking_86 END ELSE 0 END),
		@max_v161mapositiontaking_88 = MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype=161 THEN CASE WHEN CS3.mpositiontaking < @max_v161mapositiontaking_88 THEN CS3.mpositiontaking ELSE @max_v161mapositiontaking_88 END ELSE 0 END),
	
		@max_v161malivepositiontaking_85 = MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype=161 THEN CASE WHEN CS3.mlivepositiontaking < @max_v161malivepositiontaking_85 THEN CS3.mlivepositiontaking ELSE @max_v161malivepositiontaking_85 END ELSE 0 END),
		@max_v161malivepositiontaking_86 = MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CASE WHEN CS3.mlivepositiontaking < @max_v161malivepositiontaking_86 THEN CS3.mlivepositiontaking ELSE @max_v161malivepositiontaking_86 END ELSE 0 END),
		@max_v161malivepositiontaking_87 = MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype=161 THEN CASE WHEN CS3.mlivepositiontaking < @max_v161malivepositiontaking_87 THEN CS3.mlivepositiontaking ELSE @max_v161malivepositiontaking_87 END ELSE 0 END),
		@max_v161malivepositiontaking_89 = MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype=161 THEN CASE WHEN CS3.mlivepositiontaking < @max_v161malivepositiontaking_89 THEN CS3.mlivepositiontaking ELSE @max_v161malivepositiontaking_89 END ELSE 0 END),
		@max_v161malivepositiontaking_90 = MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype=161 THEN CASE WHEN CS3.mlivepositiontaking < @max_v161malivepositiontaking_90 THEN CS3.mlivepositiontaking ELSE @max_v161malivepositiontaking_90 END ELSE 0 END)	
	
	FROM
		custsetting AS CS WITH (NOLOCK)
		INNER JOIN CustSetting3rd AS CS3 WITH (NOLOCK) ON CS3.custid = CS.custid 
	
	WHERE CS.custid = (SELECT srecommend FROM customer WITH (NOLOCK) WHERE custid = @CustID)

	SELECT
		--get @apt_max = a4
		@v161apositiontaking_81_max = MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END),
		@v161apositiontaking_83_max = MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END),
		@v161apositiontaking_86_max = MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END),
		@v161apositiontaking_88_max = MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END),	

		@v161alivepositiontaking_85_max = MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END),
		@v161alivepositiontaking_86_max = MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END),
		@v161alivepositiontaking_87_max = MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END),
		@v161alivepositiontaking_89_max = MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END),
		@v161alivepositiontaking_90_max = MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END)		

	
	FROM custsetting AS CS WITH (NOLOCK)
		INNER JOIN CustSetting3rd AS CS3 WITH (NOLOCK) ON CS.custid = CS3.custid 
	WHERE CS.custid = (SELECT srecommend FROM customer WITH (NOLOCK) WHERE custid = @CustID)

	SELECT  
		ISNULL(c.firstname,'') AS FirstName, 
		ISNULL(c.lastname,'') AS LastName, 
		c.RoleID, c.UserName,
		ISNULL(c.phone,'') AS Phone, 
		ISNULL(c.mobilephone,'') AS MobilePhone, 
		ISNULL(c.email,'') AS Email,
		ISNULL(c.fax,'') AS Fax,
		CI.maxpermatch161 AS v161MaxPerMatch,
		CI.maxperball161  AS v161MaxPerBall,
		CI.maxpermatch164 AS v164MaxPerMatch,
		MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.minbet ELSE 0 END) AS v161MinBet,
		MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.maxbet ELSE 0 END) AS v161MaxBet,
	
		MAX(CASE WHEN CS3.bettype = 8101 AND CS3.sporttype=164 THEN CS3.minbet ELSE 0 END) AS v164MinBet,
		MAX(CASE WHEN CS3.bettype = 8101 AND CS3.sporttype=164 THEN CS3.maxbet ELSE 0 END) AS v164MaxBet,

		MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END) AS v161aPositionTaking_81,
		MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END) AS v161aPositionTaking_83,
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END) AS v161aPositionTaking_86,
		MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END) AS v161aPositionTaking_88,
	
		MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END) AS v161aLivePositionTaking_85,
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END) AS v161aLivePositionTaking_86,
		MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END) AS v161aLivePositionTaking_87,
		MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END) AS v161aLivePositionTaking_89,
		MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END) AS v161aLivePositionTaking_90,
	
		MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.mpositiontaking ELSE 0 END) AS v161mPositionTaking_81,
		MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype=161 THEN CS3.mpositiontaking ELSE 0 END) AS v161mPositionTaking_83,
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.mpositiontaking ELSE 0 END) AS v161mPositionTaking_86,
		MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype=161 THEN CS3.mpositiontaking ELSE 0 END) AS v161mPositionTaking_88,	

		MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mLivePositionTaking_85,
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mLivePositionTaking_86,
		MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mLivePositionTaking_87,
		MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mLivePositionTaking_89,
		MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mLivePositionTaking_90,
	
		--Auto MASter PT
		--u2
		MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.autompositiontaking ELSE 0 END) AS Auto_v161mPositionTaking_81,
		MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype=161 THEN CS3.autompositiontaking ELSE 0 END) AS Auto_v161mPositionTaking_83,
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.autompositiontaking ELSE 0 END) AS Auto_v161mPositionTaking_86,
		MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype=161 THEN CS3.autompositiontaking ELSE 0 END) AS Auto_v161mPositionTaking_88,	

		MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype=161 THEN CS3.autolivempositiontaking ELSE 0 END) AS Auto_v161mLivePositionTaking_85,
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.autolivempositiontaking ELSE 0 END) AS Auto_v161mLivePositionTaking_86,
		MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype=161 THEN CS3.autolivempositiontaking ELSE 0 END) AS Auto_v161mLivePositionTaking_87,	
		MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype=161 THEN CS3.autolivempositiontaking ELSE 0 END) AS Auto_v161mLivePositionTaking_89,
		MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype=161 THEN CS3.autolivempositiontaking ELSE 0 END) AS Auto_v161mLivePositionTaking_90,	
	
		--i2
		MAX(CASE WHEN CS3.bettype = 81 AND CS3.sporttype=161 THEN CS3.isautompositiontaking ELSE 0 END) AS IsAuto_v161mPositionTaking_81,
		MAX(CASE WHEN CS3.bettype = 83 AND CS3.sporttype=161 THEN CS3.isautompositiontaking ELSE 0 END) AS IsAuto_v161mPositionTaking_83,
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.isautompositiontaking ELSE 0 END) AS IsAuto_v161mPositionTaking_86,
		MAX(CASE WHEN CS3.bettype = 88 AND CS3.sporttype=161 THEN CS3.isautompositiontaking ELSE 0 END) AS IsAuto_v161mPositionTaking_88,
	
		MAX(CASE WHEN CS3.bettype = 85 AND CS3.sporttype=161 THEN CS3.isautolivempositiontaking ELSE 0 END) AS IsAuto_v161mLivePositionTaking_85,
		MAX(CASE WHEN CS3.bettype = 86 AND CS3.sporttype=161 THEN CS3.isautolivempositiontaking ELSE 0 END) AS IsAuto_v161mLivePositionTaking_86,
		MAX(CASE WHEN CS3.bettype = 87 AND CS3.sporttype=161 THEN CS3.isautolivempositiontaking ELSE 0 END) AS IsAuto_v161mLivePositionTaking_87,
		MAX(CASE WHEN CS3.bettype = 89 AND CS3.sporttype=161 THEN CS3.isautolivempositiontaking ELSE 0 END) AS IsAuto_v161mLivePositionTaking_89,
		MAX(CASE WHEN CS3.bettype = 90 AND CS3.sporttype=161 THEN CS3.isautolivempositiontaking ELSE 0 END) AS IsAuto_v161mLivePositionTaking_90,
	
		--max u2
		@max_v161mapositiontaking_81 AS Auto_v161mPositionTaking_81_Max,
		@max_v161mapositiontaking_83 AS Auto_v161mPositionTaking_83_Max,
		@max_v161mapositiontaking_86 AS Auto_v161mPositionTaking_86_Max,
		@max_v161mapositiontaking_88 AS Auto_v161mPositionTaking_88_Max,
		
		@max_v161malivepositiontaking_85 AS Auto_v161mLivePositiontaking_85_Max,
		@max_v161malivepositiontaking_86 AS Auto_v161mLivePositiontaking_86_Max,
		@max_v161malivepositiontaking_87 AS Auto_v161mLivePositiontaking_87_Max,
		@max_v161malivepositiontaking_89 AS Auto_v161mLivePositiontaking_89_Max,
		@max_v161malivepositiontaking_90 AS Auto_v161mLivePositiontaking_90_Max,
	
		--------------------------------------------------------------------------------------------------------------
		ISNULL(@MinBetv161_Max, 0)		AS v161MinBet_Max,
		ISNULL(@MaxBetv161_Min, 0)		AS v161MaxBet_Min,	
		ISNULL(@MaxPerMatchv161_Min, 0) AS v161MaxPerMatch_Min,	
		ISNULL(@MaxPerMatchv161_Max, 0) AS v161MaxPerMatch_Max,
		ISNULL(@MaxPerBallv161_Max, 0)  AS v161MaxPerBall_Max,
	
		ISNULL(@MinBetv164_Max, 0) AS v164MinBet_Max,
		ISNULL(@MaxBetv164_Min, 0) AS v164MaxBet_Min,	
		ISNULL(@MaxPerMatchv164_Min, 0) AS v164MaxPerMatch_Min,	
		ISNULL(@MaxPerMatchv164_Max, 0) AS v164MaxPerMatch_Max,
	
		--max (m2+a2)

		@max_v161mapositiontaking_81 AS v161mPositionTaking_81_Max,
		@max_v161mapositiontaking_83 AS v161mPositionTaking_83_Max,
		@max_v161mapositiontaking_86 AS v161mPositionTaking_86_Max,
		@max_v161mapositiontaking_88 AS v161mPositionTaking_88_Max,
		
		@max_v161malivepositiontaking_85 AS v161mLivePositionTaking_85_Max,
		@max_v161malivepositiontaking_86 AS v161mLivePositionTaking_86_Max,
		@max_v161malivepositiontaking_87 AS v161mLivePositionTaking_87_Max,
		@max_v161malivepositiontaking_89 AS v161mLivePositionTaking_89_Max,
		@max_v161malivepositiontaking_90 AS v161mLivePositionTaking_90_Max,
	
		@min_v161mapositiontaking_81 AS v161mPositionTaking_81_Min,
		@min_v161mapositiontaking_83 AS v161mPositionTaking_83_Min,
		@min_v161mapositiontaking_86 AS v161mPositionTaking_86_Min,
		@min_v161mapositiontaking_88 AS v161mPositionTaking_88_Min,
	
		@min_v161malivepositiontaking_85 AS v161mLivePositionTaking_85_Min,
		@min_v161malivepositiontaking_86 AS v161mLivePositionTaking_86_Min,
		@min_v161malivepositiontaking_87 AS v161mLivePositionTaking_87_Min,
		@min_v161malivepositiontaking_89 AS v161mLivePositionTaking_89_Min,
		@min_v161malivepositiontaking_90 AS v161mLivePositionTaking_90_Min,
	
		MAX(CASE WHEN CO3.bettype = 81 AND CO3.sporttype=161 THEN CO3.minpositiontaking ELSE 0 END) AS v161aPositionTaking_81_Min,
		MAX(CASE WHEN CO3.bettype = 83 AND CO3.sporttype=161 THEN CO3.minpositiontaking ELSE 0 END) AS v161aPositionTaking_83_Min,
		MAX(CASE WHEN CO3.bettype = 86 AND CO3.sporttype=161 THEN CO3.minpositiontaking ELSE 0 END) AS v161aPositionTaking_86_Min,	
		MAX(CASE WHEN CO3.bettype = 88 AND CO3.sporttype=161 THEN CO3.minpositiontaking ELSE 0 END) AS v161aPositionTaking_88_Min,

		MAX(CASE WHEN CO3.bettype = 85 AND CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161aLivePositionTaking_85_Min,
		MAX(CASE WHEN CO3.bettype = 86 AND CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161aLivePositionTaking_86_Min,
		MAX(CASE WHEN CO3.bettype = 87 AND CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161aLivePositionTaking_87_Min,
		MAX(CASE WHEN CO3.bettype = 89 AND CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161aLivePositionTaking_89_Min,
		MAX(CASE WHEN CO3.bettype = 90 AND CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161aLivePositionTaking_90_Min,
	
	
		--get apt_max = min(a4, l2) to check a2 < min(a4, l2) ON the web
		MAX(CASE WHEN CO3.bettype = 81 AND CO3.sporttype=161 THEN CASE WHEN CO3.maxpositiontaking<@v161apositiontaking_81_max THEN CO3.maxpositiontaking ELSE @v161apositiontaking_81_max END ELSE 0 END) AS v161aPositionTaking_81_Max,
		MAX(CASE WHEN CO3.bettype = 83 AND CO3.sporttype=161 THEN CASE WHEN CO3.maxpositiontaking<@v161apositiontaking_83_max THEN CO3.maxpositiontaking ELSE @v161apositiontaking_83_max END ELSE 0 END) AS v161aPositionTaking_83_Max,
		MAX(CASE WHEN CO3.bettype = 86 AND CO3.sporttype=161 THEN CASE WHEN CO3.maxpositiontaking<@v161apositiontaking_86_max THEN CO3.maxpositiontaking ELSE @v161apositiontaking_86_max END ELSE 0 END) AS v161aPositionTaking_86_Max,
		MAX(CASE WHEN CO3.bettype = 88 AND CO3.sporttype=161 THEN CASE WHEN CO3.maxpositiontaking<@v161apositiontaking_88_max THEN CO3.maxpositiontaking ELSE @v161apositiontaking_88_max END ELSE 0 END) AS v161aPositionTaking_88_Max,
	
		MAX(CASE WHEN CO3.bettype = 85 AND CO3.sporttype=161 THEN CASE WHEN CO3.maxlivepositiontaking<@v161alivepositiontaking_85_max THEN CO3.maxlivepositiontaking ELSE @v161alivepositiontaking_85_max END ELSE 0 END) AS v161aLivePositionTaking_85_Max,
		MAX(CASE WHEN CO3.bettype = 86 AND CO3.sporttype=161 THEN CASE WHEN CO3.maxlivepositiontaking<@v161alivepositiontaking_86_max THEN CO3.maxlivepositiontaking ELSE @v161alivepositiontaking_86_max END ELSE 0 END) AS v161aLivePositionTaking_86_Max,
		MAX(CASE WHEN CO3.bettype = 87 AND CO3.sporttype=161 THEN CASE WHEN CO3.maxlivepositiontaking<@v161alivepositiontaking_87_max THEN CO3.maxlivepositiontaking ELSE @v161alivepositiontaking_87_max END ELSE 0 END) AS v161aLivePositionTaking_87_Max,
		MAX(CASE WHEN CO3.bettype = 89 AND CO3.sporttype=161 THEN CASE WHEN CO3.maxlivepositiontaking<@v161alivepositiontaking_89_max THEN CO3.maxlivepositiontaking ELSE @v161alivepositiontaking_89_max END ELSE 0 END) AS v161aLivePositionTaking_89_Max,
		MAX(CASE WHEN CO3.bettype = 90 AND CO3.sporttype=161 THEN CASE WHEN CO3.maxlivepositiontaking<@v161alivepositiontaking_90_max THEN CO3.maxlivepositiontaking ELSE @v161alivepositiontaking_90_max END ELSE 0 END) AS v161aLivePositionTaking_90_Max,
		CI.DisableNumber
	FROM 
		customer AS c WITH (NOLOCK) 
		INNER JOIN custinfo AS CI WITH (NOLOCK) ON C.custid = CI.custid
		INNER JOIN custsetting AS CS WITH (NOLOCK) ON C.custid = CS.custid
		INNER JOIN custsetting3rd AS CS3 WITH (NOLOCK) ON C.custid = CS3.custid
		INNER JOIN custoverride AS CO WITH (NOLOCK) ON CO.custid = CS.custid AND CO.sporttype=CS.sporttype AND CO.bettype=CS.bettype
		LEFT JOIN custoverride3rd AS CO3 WITH (NOLOCK) ON CO3.custid = CS3.custid AND CO3.sporttype=CS3.sporttype AND CO3.bettype=CS3.bettype
	WHERE 
		C.roleid=2 AND C.custid=@CustID AND
		C.mrecommend=@Mrecommend
	GROUP BY
		C.firstname, 
		C.lastname, 
		C.roleid, 
		C.username,
		C.phone, 
		C.mobilephone, 
		C.email,
		C.fax,
		CI.maxpermatch161,	
		CI.maxperball161,
		CI.maxpermatch164,
		CI.DisableNumber

END
GO
