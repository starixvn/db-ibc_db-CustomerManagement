/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[CS_Acc_CustomerInfo_HeadlineSel]
	@custid INT
AS
/*
	Created: 20190425@Johnson
	Task : Get headline info for cn88
	DB: DBAGE/bodb02
	
	Revisions:
		- 20190425@Johnson: initial sp [redmine: 105338]
		- 20190527@Paul: Apply new status [RedmineID: #113198]
		- 20190910@Bobby: Implement headline - balance info [Redmine:119961]
		- 20230222@Sophia: Rebuild CN88, move balance info of HL to SP Acc_CustomerSelBalanceCashInfo [Redmine: #184187]
	

	Param's Explanation:		
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE  
			@roleID TINYINT,
			@closed BIT,
			@TotalSAgentActive INT,
		    @TotalSAgentViewOnly INT,
		    @TotalSAgentSuspended INT,
			@TotalSAgentInactive INT,
			@TotalMAgentActive INT,
			@TotalMAgentClosed INT,
		    @TotalMAgentSuspended INT,
		    @TotalMAgentViewOnly INT,
			@TotalMAgentInactive INT,
		    @TotalAgentActive INT,
			@TotalAgentClosed INT,
		    @TotalAgentSuspended INT,
		    @TotalAgentViewOnly INT,
			@TotalAgentInactive INT,
		    @TotalMemberActive INT,
			@TotalMemberClosed INT,
		    @TotalMemberSuspended INT,
		    @TotalMemberViewOnly INT,
			@TotalMemberInactive INT,
			@LastChangedSecurityCodeDate DATETIME,
			@IsInternal BIT,
			@yesterday SMALLDATETIME,
			@today SMALLDATETIME

	SELECT @today		= CAST(CURRENT_TIMESTAMP AS DATE) 
		, @yesterday	= CONVERT(DATE, DATEADD(DAY, -1, @today))
		,@IsInternal	= 0 -- hardcode for roleId = 0
			
	DECLARE @tblSupers TABLE(CustID INT)
		
	SELECT @roleid = roleID, @closed = closed
	FROM custinfo WITH(NOLOCK)
	WHERE custid = @custid
	
	IF @roleid <> 0
		RETURN
	
	INSERT INTO @tblSupers(custid)
	SELECT custid
	FROM CustSuper WITH(NOLOCK)
	WHERE uplineID = @custid
	
	SELECT @TotalSAgentActive = ISNULL(SUM(CASE WHEN RoleID = 4 AND cs.CustStatus = 4 THEN 1 ELSE 0 END), 0)
	        , @TotalSAgentViewOnly = ISNULL(SUM(CASE WHEN RoleID = 4 AND cs.CustStatus = 3 THEN 1 ELSE 0 END), 0)
            , @TotalSAgentSuspended = ISNULL(SUM(CASE  WHEN RoleID = 4 AND cs.CustStatus = 2 THEN 1 ELSE 0 END), 0)
            , @TotalSAgentInactive = ISNULL(SUM(CASE WHEN RoleID = 4 AND cs.CustStatus = 1 THEN 1 ELSE 0 END), 0)
			
			, @TotalMAgentActive = ISNULL(SUM(CASE WHEN RoleID = 3 AND cs.CustStatus = 4 THEN 1 ELSE 0 END), 0)
			, @TotalMAgentViewOnly = ISNULL(SUM(CASE WHEN RoleID = 3 AND cs.CustStatus = 3 THEN 1 ELSE 0 END), 0)
			, @TotalMAgentSuspended = ISNULL(SUM(CASE WHEN RoleID = 3 AND cs.CustStatus = 2 THEN 1 ELSE 0 END), 0)
			, @TotalMAgentInactive = ISNULL(SUM(CASE WHEN RoleID = 3 AND cs.CustStatus = 1 THEN 1 ELSE 0 END), 0)

			, @TotalAgentActive = ISNULL(SUM(CASE WHEN RoleID = 2 AND cs.CustStatus = 4 THEN 1 ELSE 0 END), 0)
			, @TotalAgentViewOnly = ISNULL(SUM(CASE WHEN RoleID = 2 AND cs.CustStatus = 3 THEN 1 ELSE 0 END), 0)
			, @TotalAgentSuspended = ISNULL(SUM(CASE WHEN RoleID = 2 AND cs.CustStatus = 2 THEN 1 ELSE 0 END), 0)
			, @TotalAgentInactive = ISNULL(SUM(CASE WHEN RoleID = 2 AND cs.CustStatus = 1 THEN 1 ELSE 0 END), 0)

			, @TotalMemberActive = ISNULL(SUM(CASE WHEN RoleID = 1 AND cs.CustStatus = 4 THEN 1 ELSE 0 END), 0)
			, @TotalMemberViewOnly = ISNULL(SUM(CASE WHEN RoleID = 1 AND cs.CustStatus = 3 THEN 1 ELSE 0 END), 0)
			, @TotalMemberSuspended = ISNULL(SUM(CASE WHEN RoleID = 1 AND cs.CustStatus = 2 THEN 1 ELSE 0 END), 0)
			, @TotalMemberInactive = ISNULL(SUM(CASE WHEN RoleID = 1 AND cs.CustStatus = 1 THEN 1 ELSE 0 END), 0)
	FROM dbo.custinfo ci WITH(NOLOCK)
		CROSS APPLY dbo.f_CS_GetCustomerStatus(ci.custid) cs
	WHERE srecommend IN (SELECT custid FROM @tblSupers)
	
	SELECT @LastChangedSecurityCodeDate = LastChangedSecurityCodeDate
	FROM DBCUST.CustDB.dbo.CustLoginInfo WITH(NOLOCK)
	WHERE custid = @custid
		
	SELECT custid,
		roleID,
		username,
		e.currency,
		firstname,
		lastname,
		username2,
		phone, 
		mobilephone, 
		fax,
		site,
		lastlogged,
		c.creatdate as createdate,
		iplogin lastloginip, 
	    pwdexpiry, 
		@LastChangedSecurityCodeDate as LastChangedSecurityCodeDate,
		@closed as closed,
		cs.CustStatus AS CN88CustStatus,
		@IsInternal AS IsInternal
	FROM customer c WITH(NOLOCK)
		INNER JOIN exchange e WITH(NOLOCK) on c.currency = e.exchangeid
		OUTER APPLY f_CS_GetCustomerStatus(@custid) cs
	WHERE custid = @custid	
	
	--hardcode to return data table for web to map current model
	SELECT custID as CustID, Enabled as headlineEnabled
	FROM custinfo (NOLOCK)
	WHERE custid = @custid
	
	
	/*
	--Implement headline - account page - balance info [Redmine:119961]
	-- Get Balance Information --
	DECLARE @balanceInfo TABLE (CustId INT, totalBalance MONEY, TotalBalance_RM MONEY, YesterdayTotalBalance MONEY, YesterdayTotalBalance_RM MONEY)
	INSERT @balanceInfo
	EXEC [dbo].[Acc_CustomerSelBalanceInfo] @CustId=@custid

	SELECT 0 AS Cash
		,ISNULL(cash.YesterdayCash,0) AS YesterdayCash
		,ISNULL(bal.YesterdayTotalBalance,0) AS YesterdayBalance
	FROM @balanceInfo bal
	OUTER APPLY (
		SELECT 
			SUM(b.winlost-b.actual_stake) AS yesterdayCash
		FROM dbo.bettrans b WITH(NOLOCK)
		WHERE b.custid = @custid
			AND b.matchid = 0
			AND b.bettype >= 20000
			AND b.winlostdate <= @today

	) AS cash
	*/
	
	SELECT  @TotalSAgentActive SAgentActive,
		    @TotalSAgentViewOnly SAgentViewOnly,
		    @TotalSAgentSuspended SAgentSuspended,
			@TotalSAgentInactive SAgentInactive,
			@TotalMAgentActive MAgentActive,
			@TotalMAgentClosed MAgentClosed,
		    @TotalMAgentSuspended MAgentSuspended,
		    @TotalMAgentViewOnly MAgentViewOnly,
			@TotalMAgentInactive MAgentInactive,
		    @TotalAgentActive AgentActive,
			@TotalAgentClosed AgentClosed,
		    @TotalAgentSuspended AgentSuspended,
		    @TotalAgentViewOnly AgentViewOnly,
			@TotalAgentInactive AgentInactive,
		    @TotalMemberActive MemberActive,
			@TotalMemberClosed MemberClosed,
		    @TotalMemberSuspended MemberSuspended,
		    @TotalMemberViewOnly MemberViewOnly,
		    @TotalMemberInactive MemberInactive
	
	--hardcode to return data table for web to map current Product status table
	SELECT 0 as ProductID 
	
END
GO

