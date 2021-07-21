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
		@maxperballv161_min MONEY


	DECLARE	@tmpSetting3rd TABLE(
		CustID	INT,
		--min/max 
		minbetv161	MONEY,
		maxbetv161	MONEY,
		minbetv164 MONEY,
		maxbetv164 MONEY,
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
		minbetv161	,
		maxbetv161	,
		minbetv164	,
		maxbetv164	,
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
		MAX(CASE WHEN CS3.bettype = 81 and CS3.sporttype=161 THEN CS3.minbet ELSE 0 END) AS minbetv161,
		MAX(CASE WHEN CS3.bettype = 81 and CS3.sporttype=161 THEN CS3.maxbet ELSE 0 END) AS maxbetv161,
		MAX(CASE WHEN CS3.bettype = 8101 and CS3.sporttype=164 THEN CS3.minbet ELSE 0 END) AS minbetv164,
		MAX(CASE WHEN CS3.bettype = 8101 and CS3.sporttype=164 THEN CS3.maxbet ELSE 0 END) AS maxbetv164,

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
		@firstname AS firstname, 
		@lastname lastname, 
		4 AS roleid, 
		CI.username,
		ISNULL(@phone,'') AS phone, 
		ISNULL(@mobilephone,'') AS mobilephone, 
		ISNULL(@email,'') AS email, 
		ISNULL(@fax,'') AS fax,
		--@Site AS site, 	
		CI.maxpermatch161, 	
		CI.maxperball161,
		CI.maxpermatch164, 
		CI.DisableNumber,
		CS3.minbetv161,
		CS3.maxbetv161,
		CS3.minbetv164,
		CS3.maxbetv164,
		--v161
		CS3.v161spositiontaking_81_min,
		CS3.v161spositiontaking_83_min,
		CS3.v161spositiontaking_86_min,
		CS3.v161spositiontaking_88_min,
		CS3.v161slivepositiontaking_85_min,
		CS3.v161slivepositiontaking_86_min,
		CS3.v161slivepositiontaking_87_min,
		CS3.v161slivepositiontaking_89_min,
		CS3.v161slivepositiontaking_90_min,
		--v161
		0.9 AS v161spositiontaking_81_max,
		0.9 AS v161spositiontaking_83_max,
		0.9 AS v161spositiontaking_86_max,
		0.9 AS v161spositiontaking_88_max,
		0.9 AS v161slivepositiontaking_85_max,
		0.9 AS v161slivepositiontaking_86_max,
		0.9 AS v161slivepositiontaking_87_max,
		0.9 AS v161slivepositiontaking_89_max,
		0.9 AS v161slivepositiontaking_90_max,
		--v161
		CS3.v161spositiontaking_81,
		CS3.v161spositiontaking_83,
		CS3.v161spositiontaking_86,
		CS3.v161spositiontaking_88,
		CS3.v161slivepositiontaking_85,
		CS3.v161slivepositiontaking_86,
		CS3.v161slivepositiontaking_87,
		CS3.v161slivepositiontaking_89,
		CS3.v161slivepositiontaking_90,
		
		CS3.v161mpositiontaking_81,
		CS3.v161mpositiontaking_83,	
		CS3.v161mpositiontaking_86,
		CS3.v161mpositiontaking_88,
		CS3.v161mlivepositiontaking_85,
		CS3.v161mlivepositiontaking_86,
		CS3.v161mlivepositiontaking_87,
		CS3.v161mlivepositiontaking_89,
		CS3.v161mlivepositiontaking_90,
		--v161
		CS3.v161apositiontaking_81,
		CS3.v161apositiontaking_83,	
		CS3.v161apositiontaking_86,
		CS3.v161apositiontaking_88,
		CS3.v161alivepositiontaking_85,
		CS3.v161alivepositiontaking_86,
		CS3.v161alivepositiontaking_87,
		CS3.v161alivepositiontaking_89,
		CS3.v161alivepositiontaking_90,
	
		ISNULL(@maxpermatchv161_min, 0) AS MaxPerMatchv161_Min,
		ISNULL(@maxperballv161_min, 0) AS MaxPerBallv161_Min		
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