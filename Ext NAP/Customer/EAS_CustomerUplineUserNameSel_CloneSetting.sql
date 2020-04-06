/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerUplineUserNameSel]
	@UserName NVARCHAR(50)
AS
/*
	Created: 20200406@Johnson
	Task : Get upline's username
	DB: DBCust/CustDB
	Original:Acc_CustomerUplineUserNameSel_CloneSetting

	Revisions:
		- 20200406@Johnson: initial sp [redmine:#130647]
		
	Param's Explanation:
		@Username: @Username want to get upline's username
*/		
BEGIN
    SET NOCOUNT ON
    
    DECLARE @RoleID INT, @MemberID INT, @AgentID INT, @SuperID INT, @MasterID INT,
			@MemberUserName NVARCHAR(50), @AgentUserName NVARCHAR(50), @SuperUserName NVARCHAR(50), 
			@MasterUserName NVARCHAR(50), @currency INT, @currencyName VARCHAR(10)
       
    SELECT @RoleID = roleID, @SuperID = srecommend, @currency = currency
	FROM customer WITH(NOLOCK)
	WHERE username = @UserName
		AND site <> 'CN88'
	
	SELECT @currencyName = currency 
	FROM Exchange WITH(NOLOCK)
	WHERE ExchangeID = @currency
	
	IF @RoleID = 1 AND NOT EXISTS(SELECT TOP 1 custid FROM customer WITH(NOLOCK) WHERE custid = @SuperID AND site <> 'CN88')
	BEGIN
		SELECT @RoleID = NULL
	END
	
	IF @RoleID IS NULL OR @RoleID > 4
	BEGIN
		SELECT NULL AS CustId,NULL AS UserName, 1 AS RoleId
		UNION ALL 
		SELECT NULL AS CustId,NULL AS UserName, 2 AS RoleId
		UNION ALL 
		SELECT NULL AS CustId,NULL AS UserName, 3 AS RoleId
		UNION ALL 
		SELECT NULL AS CustId,NULL AS UserName, 4 AS RoleId
		RETURN
	END
    ELSE IF @RoleID = 1
	BEGIN
		SELECT @MemberID = ci.custid, 
				@AgentID = ci.recommend,
				@MasterID = ci.mrecommend,
				@SuperID = ci.srecommend,
				@MemberUserName = ci.username
		FROM dbo.custInfo ci WITH (NOLOCK)
		WHERE ci.username = @Username

		SELECT @AgentUserName = ci.username
		FROM dbo.custInfo ci WITH (NOLOCK)
		WHERE ci.custid = @AgentID

		SELECT @MasterUserName = ci.username
		FROM dbo.custInfo ci WITH (NOLOCK)
		WHERE ci.custid = @MasterID

		SELECT @SuperUserName = ci.username
		FROM dbo.custInfo ci WITH (NOLOCK)
		WHERE ci.custid = @SuperID
	END
	ELSE IF @RoleID = 2
	BEGIN
		SELECT @MemberID = NULL,
				@AgentID = ci.recommend,
				@MasterID = ci.mrecommend,
				@SuperID = ci.srecommend,
				@MemberUserName = NULL,
				@AgentUserName = ci.username
		FROM dbo.custInfo ci WITH (NOLOCK)
		WHERE ci.username = @Username

		SELECT @MasterUserName = ci.username
		FROM dbo.custInfo ci WITH (NOLOCK)
		WHERE ci.custid = @MasterID

		SELECT @SuperUserName = ci.username
		FROM dbo.custInfo ci WITH (NOLOCK)
		WHERE ci.custid = @SuperID
	END
	ELSE IF @RoleID = 3
	BEGIN
		SELECT @MemberID = NULL, 
				@AgentID = NULL,
				@MasterID = ci.mrecommend,
				@SuperID = ci.srecommend,
				@MemberUserName = NULL,
				@AgentUserName = NULL,
				@MasterUserName = ci.username
		FROM dbo.custInfo ci WITH (NOLOCK)
		WHERE ci.username = @Username

		SELECT @SuperUserName = ci.username 
		FROM dbo.custInfo ci WITH (NOLOCK)
		WHERE ci.custid = @SuperID
	END
	ELSE IF @RoleID = 4
	BEGIN
		SELECT @MemberID = NULL, 
				@AgentID = NULL,
				@MasterID = NULL,
				@SuperID = ci.srecommend,
				@MemberUserName = NULL,
				@AgentUserName = NULL,
				@MasterUserName = NULL,
				@SuperUserName = ci.username
		FROM dbo.custInfo ci WITH (NOLOCK)
		WHERE ci.username = @Username

	END
	
	SELECT @MemberID AS CustId,@MemberUserName AS UserName, 1 AS RoleId, @currencyName currencyName
	UNION ALL
	SELECT @AgentID AS CustId,@AgentUserName AS UserName, 2 AS RoleId, @currencyName currencyName
	UNION ALL
	SELECT @MasterID AS CustId,@MasterUserName AS UserName, 3 AS RoleId, @currencyName currencyName
	UNION ALL
	SELECT @SuperID AS CustId,@SuperUserName AS UserName, 4 AS RoleId, @currencyName currencyName
	   
END