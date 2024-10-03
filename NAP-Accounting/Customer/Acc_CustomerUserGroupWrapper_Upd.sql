/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUserGroupWrapper_Upd]
	@username varchar(50), 
	@ugroup varchar(3),
	@userid int,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: 20190820@Johnson
	Task : sp wrapper to move group for MBC & Cn88
	DB: DBCUST/CUSTDB
	Original:

	Revisions:  
		- 20190820@Johnson: initial sp [redmine: #116691]
		- 20240909@Tacy: remove old SQL account [redmine: #208709]
	
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @custid INT, 			 
			@site VARCHAR(10)
			
	SELECT
		@custid = custid,
		@site = site
	FROM customer with(nolock)
	WHERE
		username = @username
		AND roleid = 1
	
	IF ISNULL(@custid, 0) = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid user. Member '+@username+' is not found.',
			@ErrCode = 102					 	
		RETURN	
	END
	
	IF @site = 'CN88'
	BEGIN
		EXEC CS_CustomerUserGroup_Upd
			@username = @username, 
			@ugroup = @ugroup,
			@userid = @userid,
			@IP = @IP,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT
	END
	ELSE
	BEGIN
		EXEC Acc_CustomerUpdUserGroup
			@username = @username, 
			@ugroup = @ugroup,
			@userid = @userid,
			@IP = @IP,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT
	END
END
GO
