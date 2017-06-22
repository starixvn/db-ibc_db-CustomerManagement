ALTER PROCEDURE [dbo].[Acc_MT_GetLiveCSPT]
	@username	VARCHAR(50),
	@GameType	INT			= 0
AS
/*
	Created: Johnson
	Date: 2012-02-01
	Task: View PT setting of customer
	DB: DBCUST.CustDB

	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)

	Parameters Explanation:
		- @GameType = 0: All game typye
					>0 : by game type
*/
SET NOCOUNT ON

	DECLARE @roleid INT, @custid INT, @srecommend INT, @mrecommend INT, @recommend INT,
		@susername	VARCHAR(50), @musername VARCHAR(50), @ausername VARCHAR(50),
		@DisableAutoMPT BIT
	
	DECLARE @tmpSetting TABLE
	(
		roleid		INT,
		[level]		NVARCHAR(20),		
		custid		INT,
		username   VARCHAR(50),
		spositiontaking DECIMAL(9,8),
		mpositiontaking DECIMAL(9,8),
		apositiontaking DECIMAL(9,8),
		minpositiontaking DECIMAL(9,8),
		isautopositiontaking BIT,
		autopositiontaking	 DECIMAL(9,8),
		isautompositiontaking BIT,
		autompositiontaking  DECIMAL(9,8),
		commission			 DECIMAL(9,8)
	)
	
	SELECT @roleid = roleid, @custid = custid, @srecommend = srecommend , @mrecommend = mrecommend , @recommend = recommend
	FROM CustInfo WITH(NOLOCK)
	WHERE username = @username
	
	IF @roleid IS NULL
		RETURN
	
	SELECT @susername = username FROM CustInfo WITH(NOLOCK) WHERE custid = @srecommend 
	SELECT @musername = username FROM CustInfo WITH(NOLOCK) WHERE custid = @mrecommend
	SELECT @ausername = username FROM CustInfo WITH(NOLOCK) WHERE custid = @recommend 
	
	INSERT INTO @tmpSetting
	SELECT 4,'super', cs.custid, @susername, spositiontaking, mpositiontaking, apositiontaking, minpositiontaking, isautopositiontaking, autopositiontaking, isautompositiontaking, autompositiontaking, sdiscount
	FROM CustSettingGame cs WITH(NOLOCK)
		INNER JOIN CustOverrideGame co WITH(NOLOCK) ON cs.custid = co.custid AND cs.sporttype = co.sporttype AND cs.bettype = co.bettype 
	WHERE cs.custid = @srecommend AND cs.sporttype = 162 AND cs.bettype = 1101

	IF @roleid <4
		INSERT INTO @tmpSetting
		SELECT 3, 'master', cs.custid, @musername, spositiontaking, mpositiontaking, apositiontaking, minpositiontaking, isautopositiontaking, autopositiontaking, isautompositiontaking, autompositiontaking, adiscount
		FROM CustSettingGame cs WITH(NOLOCK)
			INNER JOIN CustOverrideGame co WITH(NOLOCK) ON cs.custid = co.custid AND cs.sporttype = co.sporttype AND cs.bettype = co.bettype 
		WHERE cs.custid = @mrecommend AND cs.sporttype = 162 AND cs.bettype = 1101
	
	IF @roleid <3
		INSERT INTO @tmpSetting
		SELECT 2, 'agent', cs.custid, @ausername, spositiontaking, mpositiontaking, apositiontaking, minpositiontaking, isautopositiontaking, autopositiontaking, isautompositiontaking, autompositiontaking, discount
		FROM CustSettingGame cs WITH(NOLOCK)
			INNER JOIN CustOverrideGame co WITH(NOLOCK) ON cs.custid = co.custid AND cs.sporttype = co.sporttype AND cs.bettype = co.bettype 
		WHERE cs.custid = @recommend AND cs.sporttype = 162 AND cs.bettype = 1101
	
	IF @roleid <2
		INSERT INTO @tmpSetting
		SELECT 1, 'player', cs.custid, @username, spositiontaking, mpositiontaking, apositiontaking, 0, isautopositiontaking, autopositiontaking, isautompositiontaking, autompositiontaking, playerdiscount
		FROM CustSettingGame cs WITH(NOLOCK)
			WHERE cs.custid = @custid AND cs.sporttype = 162 AND cs.bettype = 1101
	
	SELECT * FROM @tmpSetting ORDER BY roleid 
	
	SELECT @DisableAutoMPT = DisableAutoMPT FROM CustMaster WITH(NOLOCK) WHERE custid = @mrecommend 
	
	SELECT ISNULL(@DisableAutoMPT,0) as DisableAutoMPT


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MT_GetLiveCSPT] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_MT_GetLiveCSPT] TO [bodbAdminNet]

