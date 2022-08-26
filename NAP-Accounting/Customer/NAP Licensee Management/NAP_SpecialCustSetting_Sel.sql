/*<info serverAlias="DBCUST-CUSTDB" executers="bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_SpecialCustSetting_Sel]
	@Licensee NVARCHAR(100)
	,@CurrencyID INT
	,@AgentID INT = NULL
	,@HasSetting BIT = 0 OUTPUT
	,@AgentName NVARCHAR(30) = '' OUTPUT
	,@CurrencyName NVARCHAR(30) = '' OUTPUT
AS
/*
	Created: Dom
		Date: 2014-09-03
		Task: Get list Product Hardcode setting by licensee and currency
		DB: DBCUST/CustDB
		
		Revisions:
			- 20150609@Alex: Separate CustDB to DBCUST server (Use temp table for sports, bettype, GameType table)
			- 20170809@Winnie: Change Data Type of Sporttype [RedmineID: #73545]
			- 20191225@Eden: NAP LM - Remove Inactive products [RedmineID: #119443]
			- 20200616@Johnson: add soccer parlay [redmine:#135261]
			- 202202220@Elodie: Apply DCS for SB [RedmineID: #167898] 
			
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @tmp_Sports TABLE(SportType SMALLINT,SportName NVARCHAR(50))
	
	BEGIN TRY
		INSERT INTO @tmp_Sports(SportType, SportName)
		SELECT SportType, SportName FROM DBAGE.bodb02.dbo.Sports WITH (NOLOCK)
	END TRY
	BEGIN CATCH
		INSERT INTO @tmp_Sports(SportType, SportName)
		SELECT SportType, SportName FROM DBTXN.bodb02.dbo.Sports WITH (NOLOCK) 
	END CATCH
	
	SELECT @AgentName = username FROM CustInfo WITH(NOLOCK) WHERE custid = @AgentID
	SELECT @CurrencyName = Currency FROM Exchange ex WITH(NOLOCK) WHERE exchangeid = @CurrencyID

	DECLARE @SportTable TABLE([site] VARCHAR(100), CurrencyID INT, sporttype INT, bettype INT, maxbet MONEY,maxpermatch MONEY,maxperball MONEY,maxpayoutpermatch MONEY,[group] VARCHAR(5))
	INSERT INTO @SportTable
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=1, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=9901, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=1, bettype=9, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=43, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=2, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=9902, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=3, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=5, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=8, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=10, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=11, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=99, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=99, bettype=9, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=161, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='NG' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=180, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='VS' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=181, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='VS' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=182, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='VS' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=183, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='VS' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=184, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='VS' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=185, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='VS' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=186, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='VS' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=202, bettype=1501, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,maxpayoutpermatch=NULL,[group]='KN' 

	IF NOT EXISTS(SELECT TOP 1 1 FROM [Dep_CustBetLimit_Special] cbs WITH(NOLOCK) WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID=@CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR (AgentID = @AgentID)) )	
	BEGIN
		SET @HasSetting = 0
		SELECT sp.[Site] Licensee
			,sp.CurrencyID
			,@AgentID AgentID
			,sp.SportType
			,sp.[Group]
			,sp.Bettype
			,CASE WHEN sp.SportType=99 AND sp.bettype=9 THEN 'Mix Sports Parlay' 
					WHEN sp.SportType=9901 AND sp.bettype=1 THEN 'Saba Soccer' 
					WHEN sp.SportType=9902 AND sp.bettype=1 THEN 'Saba BasketBall' 
					WHEN sp.SportType=1 AND sp.bettype=9 THEN 'Soccer Parlay' ELSE s.SportName END SportName
			,sp.MaxBet
			,sp.MaxPerMatch
			,sp.MaxPerBall
			,sp.MaxPayoutPerMatch
		FROM @SportTable sp
			LEFT JOIN @tmp_Sports s ON s.SportType = sp.SportType
	END
	ELSE
	BEGIN
		SET @HasSetting = 1
		SELECT sp.[Site] Licensee
			,sp.CurrencyID
			,AgentID
			,sp.SportType
			,sp.[Group]
			,sp.Bettype
			,CASE WHEN sp.SportType=99 AND sp.bettype=9 THEN 'Mix Sports Parlay' 
					WHEN sp.SportType=9901 AND sp.bettype=1 THEN 'Saba Soccer' 
					WHEN sp.SportType=9902 AND sp.bettype=1 THEN 'Saba BasketBall' 
					WHEN sp.SportType=1 AND sp.bettype=9 THEN 'Soccer Parlay' ELSE s.SportName END SportName
			,tmp.MaxBet
			,tmp.MaxPerMatch
			,tmp.MaxPerBall
			,tmp.MaxPayoutPerMatch
		FROM @SportTable sp
		LEFT JOIN @tmp_Sports s ON s.SportType = sp.SportType
		LEFT JOIN (
			SELECT cbs.Site,cbs.SportType, cbs.bettype,cbs.AgentID,cbs.CurrencyID,cbs.MaxBet,cbs.MaxPerMatch,cbs.MaxPerBall, cbs.MaxPayoutPerMatch
			FROM [dbo].[Dep_CustBetLimit_Special] cbs WITH(NOLOCK) 
			WHERE CurrencyID = @CurrencyID
			AND [Site] = @Licensee
			AND ( (@AgentID is null AND AgentID IS NULL) OR AgentID = @AgentID )
			
		) tmp ON tmp.SportType = sp.sporttype and tmp.Bettype = sp.bettype
	END
END

GO
