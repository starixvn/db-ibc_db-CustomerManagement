/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelBetSetting]
	  @custid			INT 
	, @userid			INT
	, @ProductID		TINYINT
	, @GroupType		SMALLINT	= 151
	, @SettingStatus		TINYINT	= 0
AS
/*
Created: 20090211@nqminh
Task : Select customer bet settings
DB: DBCUST.CustDB
Original:

Revisions:
    - 20090122@[Reviewer]: [Description of revision]    
	- 20101029@Johnson: Inlcude max per ball for number game
	- 20131021@Kathy: Add HR Fixed Odds (154) [Redmine:#6505]
	- 20161109@Helen: Separate Bet Setting for Soccer - Parlay - [Redmine:66265]
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
	- 20180404@Razor: Security in Jan 2018 - Issue #2: uper/Master can edit bet setting of its indirect donwlines [RedmineID: #91896]
	- 20181218@Johnson: add Happy 5 [Redmine: #104006]
	- 20210802@Eden: Max Payout Per Match [redmine: #158073]
	- 20210831@Eden: Break setting for Saba Soccer/Basketball [redmine: #159626]
	- 20230227@Eden: Migrate NG and Keno to DCS structure [Redmine: #179711]
	- 20231019@Helios: Customer Setting - Migrate Sportsbook to DCS [RedmineID: #193083] 

Param's Explanation:
• @custid: custid that need to be viewed.   
*/
BEGIN
	SET NOCOUNT ON

	DECLARE	@Currency		TINYINT,
			@RoleID		TINYINT,
			@Login_RoleId	TINYINT,
			@SuperID		INT,
			@MasterID		INT,
			@AgentID		INT,
			@CurrencyID		INT,
			@SiteID		INT

	CREATE TABLE #ProductSettingProfile(
		ProductID		TINYINT,	
		SportType		SMALLINT,
		BetType		SMALLINT,
		MaxDiscount		DECIMAL(19,8),
		IntervalValue	DECIMAL(19,8),
		SubType		TINYINT,
		Child_DisplayOrder TINYINT
	)

	----------------------------------------------------------------

	SELECT	
			@RoleID		= c.roleid,
			@SuperID		= c.srecommend,
			@MasterID		= c.mrecommend,
			@AgentID		= c.recommend,
			@siteid		= s.siteid,
			@CurrencyID		= c.currency
	FROM	Customer c WITH (NOLOCK)
			INNER JOIN Site s WITH (NOLOCK) ON s.site = c.site
	WHERE	c.custID = @CustID 

	SELECT @Login_RoleId = RoleId FROM dbo.custInfo WITH(NOLOCK) WHERE custid = @userid

	-- Collect Product Setting Profile
	INSERT INTO #ProductSettingProfile 	(ProductID , SportType , BetType , MaxDiscount , IntervalValue , SubType , Child_DisplayOrder )
	SELECT ProductID , SportType , Bettype , MaxDiscount , IntervalValue  , SubType , Child_DisplayOrder 
	FROM f_CustSetting_ProductProfileSelByGroupType (@GroupType, @SettingStatus , @SiteID , @CurrencyID)
	WHERE ProductID = @ProductID


	IF @RoleId = 4 OR @Login_RoleId - 1 = @RoleId
	BEGIN
		SELECT		
			psp.SportType,
			psp.BetType,
			bl.MinBet,
			bl.MaxBet,
			bl.MaxPerMatch		AS MaxPerMatch,
			0				AS MaxPerMatchMin,
			bl.MaxPayoutPerMatch	AS MaxPayoutPerMatch
		FROM #ProductSettingProfile psp
			INNER JOIN dbo.CustBetSetting_Agent bl WITH (NOLOCK) ON psp.SportType = bl.sporttype AND psp.BetType = bl.bettype
		WHERE bl.CustID = @CustID
		ORDER BY psp.Child_DisplayOrder , psp.SportType , psp.BetType
	END
END
GO