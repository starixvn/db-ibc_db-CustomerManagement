/*<info serverAlias="DBCust-CustDB" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelList]
	@custid int,
	@isDirectDownline BIT,
	@PageSize int = 500,
	@PageIndex int = 1,
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
		- 20190520@Johnson: support customer list for headline cn88 [redmine: #112225]	
		- 20210513@Tina: Lock account & indirect close account [redmine: #148600]
		- 20220620@Johnson: define temp table to avoid dump db [redmine:#174035]
		- 20221101@Elodie: Enhance SP [RedmineID: #179269]
		- 20241107@Helios: Offer Direct Member for Super/Master [redmine: #211969] 
	Explanation: 
		
		@isDirectDownline : 
			0 - Just get Master or Agent Downline
			1 - Get Direct Member Downline
	Example: EXEC Acc_CustomerSelList @CustID=24471545
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @RowCount int, @RowStart int, @RowEnd int
	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 

	DECLARE @CustList TABLE(	
		username VARCHAR(30),
		Custid INT,
		Enabled BIT,
		Closed BIT,
		Reject BIT
	)
	
	DECLARE @roleid TINYINT

	SELECT @roleid = roleid
	FROM custinfo WITH (NOLOCK)
	WHERE custid = @custid
	
	IF @roleid = 0--headline of cn88
	BEGIN
		INSERT INTO @CustList(username,Custid,[Enabled],Closed,Reject)
		SELECT c.username,c.Custid,c.Enabled, cps.closed, cps.reject
		FROM custinfo c WITH (NOLOCK)
			CROSS APPLY  (SELECT TOP 1 CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = c.custid
								) AS cps
		WHERE c.roleid = 4 
			AND c.custid IN (SELECT custid 
							FROM custSuper WITH(NOLOCK) 
							WHERE uplineID = @custid)
	END
	ELSE IF @roleid = 2
	BEGIN	
		INSERT INTO @CustList(username,Custid,[Enabled],Closed,Reject)
		SELECT c.username,c.Custid, c.Enabled, ISNULL(cps.closed, c.closed), ISNULL(cps.reject,c.reject)
		FROM custinfo c WITH (NOLOCK)
			OUTER APPLY  (SELECT TOP 1 CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = c.custid
								) AS cps
		WHERE c.roleid = 1 and c.recommend = @custid
	END
	ELSE IF @roleid = 3
	BEGIN
		INSERT INTO @CustList(username,Custid,[Enabled],Closed,Reject)	
		SELECT c.username,c.Custid, c.Enabled, ISNULL(cps.closed, c.closed), ISNULL(cps.reject,c.reject)
		FROM custinfo c WITH (NOLOCK)
			OUTER APPLY  (SELECT TOP 1 CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = c.custid
								) AS cps
		WHERE c.mrecommend = @custid
		AND c.roleid = CASE 
					WHEN @isDirectDownline = 0 AND c.roleid = 2 THEN  2						-- GET AGENT
					WHEN @isDirectDownline = 1 AND c.roleid = 1 AND c.recommend = -3 THEN  1		-- GET MASTER DIRECT MEMBER
					END
	END
	ELSE IF @roleid = 4
	BEGIN
		
		INSERT INTO @CustList(username,Custid,[Enabled],Closed,Reject)	
		SELECT c.username,c.Custid, c.Enabled, ISNULL(cps.closed, c.closed), ISNULL(cps.reject,c.reject)
		FROM custinfo  c WITH (NOLOCK)
			OUTER APPLY  (SELECT TOP 1 CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = c.custid
								) AS cps
		WHERE c.srecommend = @custid
		AND c.roleid = CASE 
						WHEN @isDirectDownline = 0 AND c.roleid = 3 THEN  3						-- GET MASTER
						WHEN @isDirectDownline = 1 AND c.roleid = 1 AND c.recommend = -4 THEN  1		-- GET SUPER DIRECT MEMBER
					   END
	END

	--Paging
	IF @TotalPages = 0
	BEGIN
		SELECT 
			@TotalPages = COUNT(1),@TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
		FROM @CustList c 
	END
	
	CREATE TABLE #tmpList(username VARCHAR(30),custid INT)
	
	INSERT INTO #tmpList(username,custid)	
	SELECT UserName,Custid 
	FROM 
	(
		SELECT 
			c.UserName,c.Custid,
			ROW_NUMBER() OVER (ORDER BY c.[enabled] DESC, c.closed, c.reject, c.username) AS RowNumber 
		FROM @CustList c
	) c
	WHERE c.RowNumber BETWEEN @RowStart AND @RowEnd

	IF @roleid = 2
		SELECT UserName,cl.ClosedReason
		FROM #tmpList c
			INNER JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON c.custid=cl.CustID
	ELSE IF @roleid IN (0,3,4)
	BEGIN
		IF @isDirectDownline = 0
		BEGIN
			SELECT UserName,cl.ClosedReason
			FROM #tmpList c
			INNER JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID
		END
		IF @isDirectDownline = 1
		BEGIN
			SELECT UserName,clogin.ClosedReason
			FROM #tmpList c
			CROSS APPLY (
				SELECT TOP 1 ClosedReason
				FROM CustLoginInfo cl WITH (NOLOCK)
				WHERE c.CustID = cl.CustID
			
				UNION ALL
			
				SELECT TOP 1 ClosedReason
				FROM CustLoginInfo_Member clm WITH (NOLOCK)
				WHERE c.CustID = clm.CustID	
			) AS clogin
		END

	END
	
	DROP TABLE #tmpList
END
GO
