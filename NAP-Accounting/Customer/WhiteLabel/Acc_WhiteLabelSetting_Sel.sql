/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Acc_WhiteLabelSetting_Sel
	-- Add the parameters for the stored procedure here
	 @Username	VARCHAR(30)	= NULL	-- WhiteLabel's Username
	,@CustID	INT	= 0				-- WhiteLabel's CustID
AS
/*
	Created: Tacy
	Task: NAP - Configure White Label rate
	DB: DBCUST-CUSTDB

	Revisions:
		- 20240827@Tacy: Create SP [Redmine: #209807]

	Param's Explanation:

*/
BEGIN 
	SET NOCOUNT ON;

	DECLARE @today DATETIME
	
	SELECT  @today = CONVERT(DATE, GETDATE())

	SELECT @Username = ISNULL(@Username,'')
		, @CustID = ISNULL(@CustID,0)

	CREATE TABLE #tmpWhiteLabel (
		 CustID			INT PRIMARY KEY
		,Username		VARCHAR(30)
		,Site			VARCHAR(10)
		,WhiteLabel		NVARCHAR(50)
		,LaunchedDate	SMALLDATETIME
		,Agent			VARCHAR(30)
		,[Master]		VARCHAR(30)
		,Super			VARCHAR(30)
		,CustDirect	INT
		,Headline		VARCHAR(30) NULL
	)

	CREATE TABLE #tmpGroupHeadline 
    (
        CustHeadlineID	INT PRIMARY KEY
      , GroupHeadline	VARCHAR(30)
      , GroupHeadlineID	SMALLINT 
    )
	
	IF @CustID=0 -- GET ALL
	BEGIN
		INSERT INTO #tmpWhiteLabel (CustID, Username, Site, WhiteLabel, LaunchedDate, Agent, [Master], Super, CustDirect)
		SELECT c.custid, c.username, c.site
			, wli.WhiteLabel, wli.LaunchedDate
			, a.username [Agent] 
			, m.username [Master] 
			, s.username [Super]
			, CASE WHEN cda.CustID IS NULL THEN c.srecommend ELSE cda.CustID END CustDirect
		FROM WhiteLabelInfo wli WITH (NOLOCK)
			INNER JOIN Customer c with (nolock) ON c.custid=wli.CustID
			LEFT JOIN Customer a with (nolock) ON a.custid=c.recommend
			LEFT JOIN Customer m with (nolock) ON m.custid=c.mrecommend
			LEFT JOIN Customer s with (nolock) ON s.custid=c.srecommend
			OUTER APPLY (SELECT TOP 1 cda.CustID
						 FROM CustDirectAccount cda WITH (NOLOCK)
						 WHERE cda.CustID in (c.recommend, c.mrecommend, c.srecommend)
						 ) cda
		WHERE (c.username LIKE @Username + '%' OR @Username='')
	END
	ELSE
	BEGIN
		INSERT INTO #tmpWhiteLabel (CustID, Username, Site, WhiteLabel, LaunchedDate, Agent, [Master], Super, CustDirect)
		SELECT c.custid, c.username, c.site
			, wli.WhiteLabel, wli.LaunchedDate
			, a.username [Agent] 
			, m.username [Master] 
			, s.username [Super]
			, CASE WHEN cda.CustID IS NULL THEN c.srecommend ELSE cda.CustID END CustDirect
		FROM WhiteLabelInfo wli WITH (NOLOCK)
			INNER JOIN Customer c with (nolock) ON c.custid=wli.CustID
			LEFT JOIN Customer a with (nolock) ON a.custid=c.recommend
			LEFT JOIN Customer m with (nolock) ON m.custid=c.mrecommend
			LEFT JOIN Customer s with (nolock) ON s.custid=c.srecommend
			OUTER APPLY (SELECT TOP 1 cda.CustID
						 FROM CustDirectAccount cda WITH (NOLOCK)
						 WHERE cda.CustID in (c.recommend, c.mrecommend, c.srecommend)
						 ) cda
		WHERE wli.CustID=@CustID
			AND (c.username LIKE @Username + '%' OR @Username='')
	END

	-- Get Headline
	INSERT INTO #tmpGroupHeadline(CustHeadlineID, GroupHeadline, GroupHeadlineID)
	SELECT hl.CustID, cu.username, hl.GroupID
    FROM dbo.CustGroupHeadline hl WITH (NOLOCK)
        INNER JOIN dbo.Customer cu WITH (NOLOCK) ON hl.CustID = cu.custid
	WHERE hl.GroupID <> 0

	--Headline name
	UPDATE wl
	SET wl.Headline=t.GroupHeadline
	FROM #tmpWhiteLabel wl
		LEFT JOIN custaccount AS ca WITH (NOLOCK) ON ca.custid = wl.CustDirect
		LEFT JOIN #tmpGroupHeadline t ON t.GroupHeadlineID=ca.groupID

	SELECT t.CustID, t.Username, t.site
		, t.WhiteLabel, t.LaunchedDate
		, t.Agent, wls.AgentRate
		, t.[Master], wls.MasterRate
		, t.Super, wls.SuperRate
		, t.Headline, wls.HeadlineRate
		, wls.Remark
	FROM #tmpWhiteLabel t
	OUTER APPLY (SELECT wls.AgentRate, wls.HeadlineRate
					, wls.SuperRate, wls.MasterRate
					, wls.Remark
				 FROM WhiteLabelSetting wls WITH (NOLOCK)
				 WHERE wls.CustID=t.CustID
				 AND wls.ToDate > @today) wls
	ORDER BY t.LaunchedDate DESC, t.WhiteLabel, t.Username
END
GO