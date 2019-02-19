/*<info serverAlias="DBCust-CustDB" executers="bodbadminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="vnteam" isFunction="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Acc_CustomerSelList]
	@custid int,
	@PageSize int = 500,
	@PageIndex int = 1,
	@Mode BIT = 0,
	@TotalPages int = 1 output
AS
/*
	Created by: []
	Date:[]
	Task: Customer List in left panel 
	DB: DBCUST/CustDB
	
	Revisions:	
		- 2009115@Ryan: apply paging.
		- 20110301@Johnson: change the length of username in @CustList upto 30
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20170620@Winnie: Apply color for closed accounts [RedmineID: #74494]
		- 20180627@Elodie: Enhance SP [RedmineID: #95978]	
		- 20180627@Elodie: Get total downline info [RedmineID: #58776]	
	Explanation: 
		@Mode:	0: Don't get total downline info
				1: Get total downline info
	
	Example: EXEC Acc_CustomerSelList @CustID=24471545, @Mode = 1
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @RowCount int, @RowStart int, @RowEnd int
	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 

	DECLARE @CustList TABLE(	
		username NVARCHAR(30),
		Custid INT
	)
	
	DECLARE @roleid TINYINT

	SELECT @roleid = roleid
	FROM custinfo WITH (NOLOCK)
	WHERE custid = @custid

	IF @roleid = 2
	BEGIN	
		INSERT INTO @CustList(username,Custid)
		SELECT c.username,c.Custid
		FROM custinfo c WITH (NOLOCK)
		WHERE c.roleid = 1 and c.recommend = @custid
		ORDER BY c.enabled DESC, c.closed, c.reject, c.username	
	END
	ELSE IF @roleid = 3
	BEGIN
		INSERT INTO @CustList(username,Custid)		
		SELECT  c.username,c.Custid
		FROM custinfo c WITH (NOLOCK)
		WHERE c.roleid = 2 and c.mrecommend = @custid
		ORDER BY c.enabled DESC, c.closed, c.reject, c.username	
	END
	ELSE IF @roleid = 4
	BEGIN
		INSERT INTO @CustList(username,Custid)		
		SELECT  c.username,c.Custid
		FROM custinfo  c WITH (NOLOCK)
		WHERE c.roleid = 3 and c.srecommend = @custid
		ORDER BY c.enabled DESC, c.closed, c.reject, c.username	
	END

	--Paging
	IF @TotalPages = 0
	BEGIN
		SELECT 
			@TotalPages = COUNT(1),@TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
		FROM @CustList c 
	END
		
	SELECT UserName,Custid INTO #tmpList
	FROM 
	(
		SELECT 
			UserName,Custid,
			ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS RowNumber 
		FROM @CustList 
	) c
	WHERE c.RowNumber BETWEEN @RowStart AND @RowEnd

	IF @roleid = 2
		SELECT UserName,cl.ClosedReason
		FROM #tmpList c
			LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON c.custid=cl.CustID
	ELSE IF @roleid IN (3,4)
		SELECT UserName,cl.ClosedReason
		FROM #tmpList c
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID

	IF @Mode = 1
	BEGIN
		DECLARE @TotalMemberActive INT, @TotalMemberClosed INT, @TotalMemberSuspended INT,
				@TotalAgentActive INT, @TotalAgentClosed INT, @TotalAgentSuspended INT		
		
		IF @roleid = 2
		BEGIN
			SELECT @TotalMemberActive = ISNULL(SUM(CASE WHEN Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
				   @TotalMemberClosed = ISNULL(SUM(CASE WHEN Closed = 1 THEN 1 ELSE 0 END), 0),
				   @TotalMemberSuspended = ISNULL(SUM(CASE WHEN ISNULL(reject,0) = 1 AND closed = 0 THEN 1 ELSE 0 END), 0) 
			FROM custinfo (NOLOCK) 
			WHERE recommend = @custID AND RoleID=1
		END
		ELSE IF @roleid = 3
		BEGIN
			SELECT @TotalAgentActive = ISNULL(SUM(CASE WHEN RoleID = 2 AND Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
				   @TotalAgentClosed = ISNULL(SUM(CASE WHEN RoleID = 2 AND Closed = 1 THEN 1 ELSE 0 END), 0),
				   @TotalAgentSuspended = ISNULL(SUM(CASE WHEN RoleID = 2 AND ISNULL(reject,0) = 1 AND closed = 0 THEN 1 ELSE 0 END), 0),			
				   @TotalMemberActive = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 0 and ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
				   @TotalMemberClosed = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 1 THEN 1 ELSE 0 END), 0),
				   @TotalMemberSuspended = ISNULL(SUM(CASE WHEN RoleID = 1 AND ISNULL(reject,0) = 1 AND closed = 0 THEN 1 ELSE 0 END), 0)
			FROM custinfo (NOLOCK) 
			WHERE mrecommend = @custID
		END

		SELECT	@TotalAgentActive AS [TotalAgActive], 
				@TotalAgentClosed AS [TotalAgClosed], 
				@TotalAgentSuspended AS [TotalAgSuspended],	
				@TotalMemberActive AS [TotalMemActive], 
				@TotalMemberClosed AS [TotalMemClosed], 
				@TotalMemberSuspended AS [TotalMemSuspended]
	END

	IF @roleid = 2
		SELECT UserName,cl.ClosedReason
		FROM #tmpList c
			LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON c.custid=cl.CustID
	ELSE IF @roleid IN (3,4)
		SELECT UserName,cl.ClosedReason
		FROM #tmpList c
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID
END
GO
