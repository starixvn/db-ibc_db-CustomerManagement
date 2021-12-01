/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CopySetting_CustomerSelStatus] 	
	@SuperList VARCHAR(MAX) = '',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg  NVARCHAR(MAX)='' OUTPUT
AS
/*
	Created: 20210928@Johnson
	Task : get status of super list
	DB: DBCUST/CustDB
	Original:

	Revision:
		- 20210928@Johnson: initial sp [redmine:#160980]
	
	Parameter's Explanation:
		@SuperList: super list		
*/
BEGIN
	SET NOCOUNT ON
		
	DECLARE @tblCust TABLE (username VARCHAR(50), custid INT, site VARCHAR(30), roleid TINYINT, IsInternal BIT, Closed BIT, Suspended BIT, Enabled BIT, Locked BIT, IsProcted BIT)
	DECLARE @strUsername VARCHAR(MAX) =''
	
	
	INSERT INTO @tblCust(username)
	SELECT val
	FROM dbo.strSplit(@SuperList,',')
	
	UPDATE t
	SET t.custid = c.custid,
		t.roleid = c.roleid,
		t.closed = CASE WHEN cs.CloseInfo > 0 THEN 1 ELSE 0 END,
		t.Suspended = CASE WHEN cs.SuspendInfo > 0 THEN 1 ELSE 0 END,
		t.Enabled = c.Enabled,
		t.IsInternal = ISNULL(s.IsInternal,0)
	FROM @tblCust t
		INNER JOIN custinfo c WITH(NOLOCK) ON t.username = c.username
		LEFT JOIN custsuper s WITH(NOLOCK) ON c.custid = t.custid
		LEFT JOIN CustProductStatus cs WITH(NOLOCK) ON c.custid = cs.custid
		
	IF NOT EXISTS (SELECT 1 
				FROM @tblCust t 
				WHERE roleid = 4
					AND custid > 100 --dummy account
					AND custid NOT IN (SELECT custid FROM Dep_CustSuper WITH(NOLOCK))					
					AND Enabled = 1
					AND IsInternal = 0
				)
	BEGIN
		SELECT @ErrCode = 100,
			@ErrMsg = N'Inputted Usernames are not valid Super Accounts'
		RETURN
	END

	SELECT @strUsername = @strUsername + ', ' + username 
	FROM @tblCust t 
	WHERE roleid <> 4
		OR custid <= 100 --dummy account
		OR custid IS NULL
		OR custid IN (SELECT custid FROM Dep_CustSuper WITH(NOLOCK))					
		OR Enabled = 0	
		OR IsInternal = 1
	
	IF @strUsername <> ''
	BEGIN
		SELECT @strUsername = STUFF(@strUsername,1,1,'')
		SELECT @ErrCode = 100,
			@ErrMsg = @strUsername + N' are not valid Super Accounts.'		
	END
	
	SELECT t.custid, t.username, c.site, t.closed, t.suspended, ISNULL(ci.IsProtectedMode,0) IsProtectedMode
	FROM @tblCust t
		INNER JOIN customer c WITH(NOLOCK) ON t.custid = c.custid		
		INNER JOIN CustLoginInfo ci WITH(NOLOCK) ON t.custid = ci.custid
	WHERE t.roleid = 4
		AND t.custid > 100 --dummy account		
		AND t.custid NOT IN (SELECT custid FROM Dep_CustSuper WITH(NOLOCK))					
		AND t.Enabled = 1
		AND t.IsInternal = 0
END	