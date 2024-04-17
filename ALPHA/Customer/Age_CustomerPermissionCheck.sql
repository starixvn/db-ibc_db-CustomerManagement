ALTER PROCEDURE [dbo].[Age_CustomerPermissionCheck]
	@SessionCustID int, --uplineID	
	@custid int = NULL,
	@SubAccountID INT = 0,
	@spPageAccess VARCHAR(50)='',	
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(500) = '' OUTPUT,	
	@username VARCHAR(30) = '' OUTPUT,
	@roleid tinyint = 0 OUTPUT --0: not belonged to
AS
	/*
		Created: Johnson
		Date: 2015-03-02
		Task: Check permission of user on update actions
		DB: DBAGE/bodb02
		
		Revisions:
		
		Parameter's Explantion:
			- @SessionCustID: session of user do action
			- @subAccountID : sub-account id 
			- @spPageAccess: page need to check permission of sub-account on this
			- @ErrCode = 0: user is allowed to do actions
						> 0: not allowed			
	*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @SessionRoleID TINYINT
		,@pageAccess VARCHAR(50)
		,@mrecommend INT
		,@srecommend INT
		,@isAllowedAccess BIT = 1--sub-account is allowed access or not on that page
		,@isActive BIT = 1 --check account is closed/disabled or not
		,@IsUplineActive BIT = 1--check upline is closed/disabled or not

	IF @SessionCustID IS NULL --Not check
	BEGIN
		--get active status of user
		SELECT @roleid = roleid
			,@mrecommend = mrecommend
			,@srecommend = srecommend
			,@isActive = CASE WHEN closed = 1 OR Enabled = 0 THEN 0 ELSE 1 END	
		FROM custinfo c WITH (NOLOCK)
		WHERE c.custid = @custid
		
		--get upline active status
		IF @roleid IN (2,3)
		BEGIN
			SELECT @isUplineActive = CASE WHEN closed = 1 OR Enabled = 0 THEN 0 ELSE 1 END	
			FROM custinfo c WITH (NOLOCK)
			WHERE c.custid = CASE WHEN @roleid = 2 THEN @mrecommend 
									WHEN @roleid = 3 THEN @srecommend END
		END
		RETURN
	END
	
	SELECT	@SessionRoleID = roleid
		,@mrecommend = mrecommend
		,@srecommend = srecommend
		,@isActive = CASE WHEN closed = 1 OR Enabled = 0 THEN 0 ELSE 1 END
	FROM custinfo WITH(NOLOCK)
	WHERE custID = @SessionCustID
		
	IF ISNULL(@sessionRoleid ,0) = 0 RETURN
	
	--get upline status if user do action is master or agent
	IF @sessionRoleid IN (2,3)	
	BEGIN
		SELECT @isUplineActive = CASE WHEN closed = 1 OR Enabled = 0 THEN 0 ELSE 1 END	
		FROM custinfo c WITH (NOLOCK)
		WHERE c.custid = CASE WHEN @roleid = 2 THEN @mrecommend 
								WHEN @roleid = 3 THEN @srecommend END
	END
	
	SELECT	@roleid = roleid, @username = username		
	FROM custinfo c WITH (NOLOCK)
	WHERE c.custid = @custid
		AND
		(c.srecommend = @SessionCustID OR c.mrecommend = @SessionCustID
			OR c.recommend = @SessionCustID OR c.custid = @SessionCustID
			OR @SessionRoleID >= 5)
	
	--if sub account do actions
	IF @SubAccountID <> 0
	BEGIN
		--get status of sub-account and permission on page access
		SELECT @isActive = CASE WHEN closed = 0 THEN 1 ELSE 0 END ,
			@pageAccess = PageAccess
		FROM dbo.custSub WITH(NOLOCK) 
		WHERE subaccID = @SubAccountID AND custid = @SessionCustID
		
		--check sub-account permission on page is allowed or not
		/*IF ( CHARINDEX(@spPageAccess, @PageAccess) > 0 AND (@IsActive = 1) )
			SET @isAllowedAccess = 1
		ELSE 
			SET @isAllowedAccess = 0
		*/
	END
	
	IF @isActive <> 1 OR @IsUplineActive <> 1 OR @isAllowedAccess <> 1 OR @roleid = 0
	BEGIN
		SELECT @ErrCode = 100,
			@ErrMsg= 'You can''t do this action this moment.'
	END
	
END
GO
GRANT EXECUTE ON [dbo].[Age_CustomerPermissionCheck] TO [wsv_nap]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerPermissionCheck] TO [bodbDownlineNet,wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerPermissionCheck] TO [bodbExtAccNet,wsv_xnap]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerPermissionCheck] TO [bodbDownlineNetView,wsv_alpv]
