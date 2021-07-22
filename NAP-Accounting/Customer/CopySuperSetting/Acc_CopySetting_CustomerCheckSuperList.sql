/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_CopySetting_CustomerCheckSuperList] 
	@username VARCHAR(50),
	@SuperList VARCHAR(MAX) = '',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg  NVARCHAR(1000)='' OUTPUT
AS
/*
	Created: 20210719@Johnson
	Task : get list products is offered to copy winlimit setting from super 
	DB: DBCUST/CustDB
	Original:

	Revision:
		- 20210716@Johnson: initial sp [redmine:#158174]
	
	Parameter's Explanation:
		@custid: source custid
		@SuperList: super list destination
		@ProductList: List product need to copy setting
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @strUsername  NVARCHAR(100)	= '',
			@site VARCHAR(50)
	DECLARE @tblCust TABLE(username NVARCHAR(50))
	
	INSERT INTO @tblCust(username)
	SELECT val
	FROM dbo.strSplit(@SuperList,',')
	
	IF NOT EXISTS(SELECT 1 FROM custinfo WITH(NOLOCK) 
				WHERE username = @username
					AND roleid = 4
					AND Enabled = 1
					AND custid NOT IN (SELECT custid FROM Dep_CustSuper WITH(NOLOCK))
					AND custid > 100--dummy account
				)
	BEGIN
		SELECT @ErrCode = 100,
			@ErrMsg = 'Invalid source super account.'
		RETURN;
	END	
	
	SELECT @strUsername = ''
	;WITH t AS(
		SELECT t.username, c.custid, c.roleid, c.enabled
		FROM @tblCust t 
			LEFT JOIN custinfo c WITH(NOLOCK) ON c.username = t.username
	)
	SELECT @strUsername = @strUsername +','+ username
	FROM t
	WHERE custid IS NULL
		OR custid <= 100
		OR roleid <> 4
		OR enabled = 0
		OR custid IN (SELECT custid FROM Dep_CustSuper WITH(NOLOCK))

	IF @strUsername <> ''
	BEGIN
		SELECT @strUsername = STUFF(@strUsername,1,1,'')
		SELECT @ErrCode = 101,
				@ErrMsg = 'Invalid super account(s): ' + @strUsername
		RETURN;		
	END
	
	
	SELECT @site = site FROM customer WITH(NOLOCK) WHERE username = @username
	
	SELECT @strUsername = ''
	SELECT @strUsername = @strUsername +','+ username
	FROM customer WITH(NOLOCK)
	WHERE username IN (SELECT username FROM @tblCust)
		AND site <> @site
		
	IF @strUsername <> ''
	BEGIN
		SELECT @strUsername = STUFF(@strUsername,1,1,'')
		SELECT @ErrCode = 102,
				@ErrMsg = 'The following accounts are not the same site with the source account: ' + @strUsername
		RETURN;		
	END
		
		
END