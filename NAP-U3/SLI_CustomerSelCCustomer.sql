/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[SLI_CustomerSelCCustomer]     
	@CustId int
AS

/*
Created: Tiara
Task : View Super Setting
DB: DBCUST/CustDB
Original: Acc_CustomerSelCEditCustomer 
Revisions:
    - 20200601@Tiara: View Super setting information on NAP-U3 site [Redmine: #123584] 
	- 20210721@Winfred: Remove Comm on U3 site [Redmine: #123584]
    
Param's Explanation:
	@CustID: Super ID
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @maxpermatchv161_min MONEY,
		@maxpermatchv164_min MONEY,	
		@maxperballv161_min MONEY,
		@MinBetv161 MONEY, @MaxBetv161 MONEY, 
		@MaxPerMatchv161 MONEY, @maxperballv161 MONEY, 
		@MinBetv164 MONEY, @MaxBetv164 MONEY, @MaxPerMatchv164 MONEY

	DECLARE	@tmpSetting3rd TABLE(
		CustID	INT,
		--min PT
		v161spositiontaking_81_min	SMALLMONEY,
		v161spositiontaking_83_min	SMALLMONEY,
		v161spositiontaking_86_min	SMALLMONEY,
		v161spositiontaking_88_min	SMALLMONEY,
		--	LIVE
		v161slivepositiontaking_85_min	SMALLMONEY,
		v161slivepositiontaking_86_min	SMALLMONEY,
		v161slivepositiontaking_87_min	SMALLMONEY,
		v161slivepositiontaking_89_min	SMALLMONEY,
		v161slivepositiontaking_90_min	SMALLMONEY,
		-- PT
		v161spositiontaking_81	SMALLMONEY,
		v161spositiontaking_83	SMALLMONEY,
		v161spositiontaking_86	SMALLMONEY,
		v161spositiontaking_88	SMALLMONEY,
		v161slivepositiontaking_85	SMALLMONEY,
		v161slivepositiontaking_86	SMALLMONEY,
		v161slivepositiontaking_87	SMALLMONEY,
		v161slivepositiontaking_89	SMALLMONEY,
		v161slivepositiontaking_90	SMALLMONEY,

		v161mpositiontaking_81	SMALLMONEY,
		v161mpositiontaking_83	SMALLMONEY,
		v161mpositiontaking_86	SMALLMONEY,
		v161mpositiontaking_88	SMALLMONEY,
		v161mlivepositiontaking_85	SMALLMONEY,
		v161mlivepositiontaking_86	SMALLMONEY,
		v161mlivepositiontaking_87	SMALLMONEY,
		v161mlivepositiontaking_89	SMALLMONEY,
		v161mlivepositiontaking_90	SMALLMONEY,

		v161apositiontaking_81	SMALLMONEY,
		v161apositiontaking_83	SMALLMONEY,
		v161apositiontaking_86	SMALLMONEY,
		v161apositiontaking_88	SMALLMONEY,
		v161alivepositiontaking_85	SMALLMONEY,
		v161alivepositiontaking_86	SMALLMONEY,
		v161alivepositiontaking_87	SMALLMONEY,
		v161alivepositiontaking_89	SMALLMONEY,
		v161alivepositiontaking_90	SMALLMONEY
	)

	INSERT INTO @tmpSetting3rd (
		CustID		,
		--Min PT
		v161spositiontaking_81_min	,
		v161spositiontaking_83_min	,
		v161spositiontaking_86_min	,
		v161spositiontaking_88_min	,
		v161slivepositiontaking_85_min	,
		v161slivepositiontaking_86_min	,
		v161slivepositiontaking_87_min	,
		v161slivepositiontaking_89_min	,
		v161slivepositiontaking_90_min	,
		--PT
		v161spositiontaking_81	,
		v161spositiontaking_83	,
		v161spositiontaking_86	,
		v161spositiontaking_88	,
		v161slivepositiontaking_85	,
		v161slivepositiontaking_86	,
		v161slivepositiontaking_87	,
		v161slivepositiontaking_89	,
		v161slivepositiontaking_90	,

		v161mpositiontaking_81	,
		v161mpositiontaking_83	,
		v161mpositiontaking_86	,
		v161mpositiontaking_88	,
		v161mlivepositiontaking_85	,
		v161mlivepositiontaking_86	,
		v161mlivepositiontaking_87	,
		v161mlivepositiontaking_89	,
		v161mlivepositiontaking_90	,

		v161apositiontaking_81	,
		v161apositiontaking_83	,
		v161apositiontaking_86	,
		v161apositiontaking_88	,
		v161alivepositiontaking_85	,
		v161alivepositiontaking_86	,
		v161alivepositiontaking_87	,
		v161alivepositiontaking_89	,
		v161alivepositiontaking_90	
	)

	SELECT	
		CI.CustID,
		MAX(CASE WHEN CO3.bettype = 81 and CO3.sporttype=161 THEN CO3.minpositiontaking ELSE 0 END) AS v161spositiontaking_81_min,
		MAX(CASE WHEN CO3.bettype = 83 and CO3.sporttype=161 THEN CO3.minpositiontaking ELSE 0 END) AS v161spositiontaking_83_min,
		MAX(CASE WHEN CO3.bettype = 86 and CO3.sporttype=161 THEN CO3.minpositiontaking ELSE 0 END) AS v161spositiontaking_86_min,
		MAX(CASE WHEN CO3.bettype = 88 and CO3.sporttype=161 THEN CO3.minpositiontaking ELSE 0 END) AS v161spositiontaking_88_min,
		MAX(CASE WHEN CO3.bettype = 85 and CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161slivepositiontaking_85_min,
		MAX(CASE WHEN CO3.bettype = 86 and CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161slivepositiontaking_86_min,
		MAX(CASE WHEN CO3.bettype = 87 and CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161slivepositiontaking_87_min,
		MAX(CASE WHEN CO3.bettype = 89 and CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161slivepositiontaking_89_min,
		MAX(CASE WHEN CO3.bettype = 90 and CO3.sporttype=161 THEN CO3.minlivepositiontaking ELSE 0 END) AS v161slivepositiontaking_90_min,

		MAX(CASE WHEN CS3.bettype = 81 and CS3.sporttype=161 THEN CS3.spositiontaking ELSE 0 END) AS v161spositiontaking_81,
		MAX(CASE WHEN CS3.bettype = 83 and CS3.sporttype=161 THEN CS3.spositiontaking ELSE 0 END) AS v161spositiontaking_83,
		MAX(CASE WHEN CS3.bettype = 86 and CS3.sporttype=161 THEN CS3.spositiontaking ELSE 0 END) AS v161spositiontaking_86,
		MAX(CASE WHEN CS3.bettype = 88 and CS3.sporttype=161 THEN CS3.spositiontaking ELSE 0 END) AS v161spositiontaking_88,
		MAX(CASE WHEN CS3.bettype = 85 and CS3.sporttype=161 THEN CS3.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_85,
		MAX(CASE WHEN CS3.bettype = 86 and CS3.sporttype=161 THEN CS3.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_86,
		MAX(CASE WHEN CS3.bettype = 87 and CS3.sporttype=161 THEN CS3.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_87,
		MAX(CASE WHEN CS3.bettype = 89 and CS3.sporttype=161 THEN CS3.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_89,
		MAX(CASE WHEN CS3.bettype = 90 and CS3.sporttype=161 THEN CS3.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_90,

		MAX(CASE WHEN CS3.bettype = 81 and CS3.sporttype=161 THEN CS3.mpositiontaking ELSE 0 END) AS v161mpositiontaking_81,
		MAX(CASE WHEN CS3.bettype = 83 and CS3.sporttype=161 THEN CS3.mpositiontaking ELSE 0 END) AS v161mpositiontaking_83,
		MAX(CASE WHEN CS3.bettype = 86 and CS3.sporttype=161 THEN CS3.mpositiontaking ELSE 0 END) AS v161mpositiontaking_86,
		MAX(CASE WHEN CS3.bettype = 88 and CS3.sporttype=161 THEN CS3.mpositiontaking ELSE 0 END) AS v161mpositiontaking_88,
		MAX(CASE WHEN CS3.bettype = 85 and CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_85,
		MAX(CASE WHEN CS3.bettype = 86 and CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_86,
		MAX(CASE WHEN CS3.bettype = 87 and CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_87,
		MAX(CASE WHEN CS3.bettype = 89 and CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_89,
		MAX(CASE WHEN CS3.bettype = 90 and CS3.sporttype=161 THEN CS3.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_90,

		MAX(CASE WHEN CS3.bettype = 81 and CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END) AS v161apositiontaking_81,
		MAX(CASE WHEN CS3.bettype = 83 and CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END) AS v161apositiontaking_83,
		MAX(CASE WHEN CS3.bettype = 86 and CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END) AS v161apositiontaking_86,
		MAX(CASE WHEN CS3.bettype = 88 and CS3.sporttype=161 THEN CS3.apositiontaking ELSE 0 END) AS v161apositiontaking_88,
		MAX(CASE WHEN CS3.bettype = 85 and CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END) AS v161alivepositiontaking_85,
		MAX(CASE WHEN CS3.bettype = 86 and CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END) AS v161alivepositiontaking_86,
		MAX(CASE WHEN CS3.bettype = 87 and CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END) AS v161alivepositiontaking_87,
		MAX(CASE WHEN CS3.bettype = 89 and CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END) AS v161alivepositiontaking_89,
		MAX(CASE WHEN CS3.bettype = 90 and CS3.sporttype=161 THEN CS3.alivepositiontaking ELSE 0 END) AS v161alivepositiontaking_90

	FROM	Custinfo CI WITH (NOLOCK)
			INNER JOIN Custsetting3rd CS3 WITH (NOLOCK) ON CI.custID = CS3.custID 
			LEFT JOIN Custoverride3rd CO3 WITH (NOLOCK) ON CI.custID = CO3.custID AND CO3.sporttype = CS3.sporttype AND CO3.bettype = CS3.bettype 
	WHERE	CI.roleid=4 and CI.custid=@CustID
	GROUP BY CI.CustID 

	 SELECT   
		@MinBetv161			= MAX(CASE WHEN cbs.bettype = 81 and cbs.sporttype=161 THEN cbs.minbet ELSE 0 END)      
	   ,@MaxBetv161			= MAX(CASE WHEN cbs.bettype = 81 and cbs.sporttype=161 THEN cbs.maxbet ELSE 0 END)      
	   ,@MaxPerMatchv161    = MAX(CASE WHEN cbs.bettype = 81 and cbs.sporttype=161 THEN cbs.MaxPerMatch ELSE 0 END)     
	   ,@maxperballv161		= MAX(CASE WHEN cbs.bettype = 81 and cbs.sporttype=161 THEN cbs.MaxPerNumber ELSE 0 END)   
	     
	   ,@MinBetv164			= MAX(CASE WHEN cbs.bettype = 8101 and cbs.sporttype=164 THEN cbs.minbet ELSE 0 END)      
	   ,@MaxBetv164			= MAX(CASE WHEN cbs.bettype = 8101 and cbs.sporttype=164 THEN cbs.maxbet ELSE 0 END)      
	   ,@MaxPerMatchv164    = MAX(CASE WHEN cbs.bettype = 8101 and cbs.sporttype=164 THEN cbs.MaxPerMatch ELSE 0 END)  
	 FROM CustBetSetting_Agent cbs WITH(NOLOCK)   
	  WHERE CustID = @CustId  

	DECLARE	@firstname	nvarchar(50),
			@lastname	nvarchar(50),
			@phone		nvarchar(50),
			@mobilephone	nvarchar(50),
			@email		nvarchar(50),
			@fax		nvarchar(50),
			@Site varchar(10)

	SELECT	@firstname	= C.firstname,
			@lastname	= C.lastname,
			@phone		= C.phone,
			@mobilephone	= C.mobilephone,
			@email		= C.email,
			@fax		= C.fax,
			@Site = C.site
	FROM	Customer C WITH (NOLOCK)
	WHERE	c.custID = @CustID 

	--Facilitate in Web Interface
	SELECT	
		@maxpermatchv161_min =0,
		@maxpermatchv164_min =0,
		@maxperballv161_min = 0

	
	SELECT	
		@firstname AS FirstName, 
		@lastname LastName, 
		4 AS RoleID, 
		CI.UserName,
		ISNULL(@phone,'') AS Phone, 
		ISNULL(@mobilephone,'') AS MobilePhone, 
		ISNULL(@email,'') AS Email, 
		ISNULL(@fax,'') AS Fax,
		--@Site AS site, 	
		@MaxPerMatchv161	AS v161MaxPerMatch,	
		@maxperballv161 	AS v161MaxPerBall,
		@MaxPerMatchv164	AS v164MaxPerMatch,	
		CI.DisableNumber,
		@MinBetv161	AS v161MinBet,
		@MaxBetv161	AS v161MaxBet,	
		@MinBetv164	AS v164MinBet,
		@MaxBetv164	AS v164MaxBet,		
		--v161
		CS3.v161sPositionTaking_81_Min,
		CS3.v161sPositionTaking_83_Min,
		CS3.v161sPositionTaking_86_Min,
		CS3.v161sPositionTaking_88_Min,
		CS3.v161sLivePositionTaking_85_Min,
		CS3.v161sLivePositionTaking_86_Min,
		CS3.v161sLivePositionTaking_87_Min,
		CS3.v161sLivePositionTaking_89_Min,
		CS3.v161sLivePositionTaking_90_Min,
		--v161
		0.9 AS v161sPositionTaking_81_Max,
		0.9 AS v161sPositionTaking_83_Max,
		0.9 AS v161sPositionTaking_86_Max,
		0.9 AS v161sPositionTaking_88_Max,
		0.9 AS v161sLivePositionTaking_85_Max,
		0.9 AS v161sLivePositionTaking_86_Max,
		0.9 AS v161sLivePositionTaking_87_Max,
		0.9 AS v161sLivePositionTaking_89_Max,
		0.9 AS v161sLivePositionTaking_90_Max,
		--v161
		CS3.v161sPositionTaking_81,
		CS3.v161sPositionTaking_83,
		CS3.v161sPositionTaking_86,
		CS3.v161sPositionTaking_88,
		CS3.v161sLivePositionTaking_85,
		CS3.v161sLivePositionTaking_86,
		CS3.v161sLivePositionTaking_87,
		CS3.v161sLivePositionTaking_89,
		CS3.v161sLivePositionTaking_90,
		
		CS3.v161mPositionTaking_81,
		CS3.v161mPositionTaking_83,	
		CS3.v161mPositionTaking_86,
		CS3.v161mPositionTaking_88,
		CS3.v161mLivePositionTaking_85,
		CS3.v161mLivePositionTaking_86,
		CS3.v161mLivePositionTaking_87,
		CS3.v161mLivePositionTaking_89,
		CS3.v161mLivePositionTaking_90,
		--v161
		CS3.v161aPositionTaking_81,
		CS3.v161aPositionTaking_83,	
		CS3.v161aPositionTaking_86,
		CS3.v161aPositionTaking_88,
		CS3.v161aLivePositionTaking_85,
		CS3.v161aLivePositionTaking_86,
		CS3.v161aLivePositionTaking_87,
		CS3.v161aLivePositionTaking_89,
		CS3.v161aLivePositionTaking_90,
	
		ISNULL(@maxpermatchv161_min, 0) AS v161MaxPerMatch_Min,
		ISNULL(@maxperballv161_min, 0)  AS v161MaxPerBall_Min		
	FROM 
		custinfo AS CI with (NOLOCK)
		INNER JOIN custsetting AS CS with (NOLOCK) on CI.custid = CS.custid
		INNER JOIN custoverride AS CO with (NOLOCK) on CI.custid = CO.custid and CO.sporttype = CS.sporttype and CO.bettype = CS.bettype
		INNER JOIN @tmpSetting3rd CS3 ON CI.custID = CS3.custID 
	WHERE 
		CI.roleid=4 and CI.custid=@CustID
	GROUP BY  
		CI.username,
		CI.maxpermatch161,
		CI.maxperball161,
		CI.maxpermatch164,
		CI.disableNumber,
		CS3.minbetv161,
		CS3.maxbetv161,
		CS3.minbetv164,
		CS3.maxbetv164,
		CS3.v161spositiontaking_81_min	,
		CS3.v161spositiontaking_83_min	,
		CS3.v161spositiontaking_86_min	,
		CS3.v161spositiontaking_88_min	,
		CS3.v161slivepositiontaking_85_min	,
		CS3.v161slivepositiontaking_86_min	,
		CS3.v161slivepositiontaking_87_min	,
		CS3.v161slivepositiontaking_89_min	,
		CS3.v161slivepositiontaking_90_min	,
		CS3.v161spositiontaking_81	,
		CS3.v161spositiontaking_83	,
		CS3.v161spositiontaking_86	,
		CS3.v161spositiontaking_88	,
		CS3.v161slivepositiontaking_85	,
		CS3.v161slivepositiontaking_86	,
		CS3.v161slivepositiontaking_87	,
		CS3.v161slivepositiontaking_89	,
		CS3.v161slivepositiontaking_90	,
		CS3.v161mpositiontaking_81	,
		CS3.v161mpositiontaking_83	,
		CS3.v161mpositiontaking_86	,
		CS3.v161mpositiontaking_88	,
		CS3.v161mlivepositiontaking_85	,
		CS3.v161mlivepositiontaking_86	,
		CS3.v161mlivepositiontaking_87	,
		CS3.v161mlivepositiontaking_89	,
		CS3.v161mlivepositiontaking_90	,
		CS3.v161apositiontaking_81	,
		CS3.v161apositiontaking_83	,
		CS3.v161apositiontaking_86	,
		CS3.v161apositiontaking_88	,
		CS3.v161alivepositiontaking_85	,
		CS3.v161alivepositiontaking_86	,
		CS3.v161alivepositiontaking_87,
		CS3.v161alivepositiontaking_89	,
		CS3.v161alivepositiontaking_90
END

GO