/*<info serverAlias="DBGLOB-GLOBCUSTDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerEditUserName_Register]
(
	@oldname varchar(30), 
	@newname varchar(30),
	@isRollback BIT = 0,
	@custId INT OUTPUT,
	@roleid TINYINT OUTPUT,
	@site VARCHAR(10) OUTPUT,
	@sitedbgroupid SMALLINT = 0 OUTPUT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
)
AS
/*
	Created: Helen
	Date: 2024-10-10
	Task: edit username for CREDIT 
	DB: DBGLOB-GLOBCUSTDB
	
	Revisions:
		- 20241010@Helen:edit username for CREDIT - [Redmine:#212007]
		
	Parameter's Explanation:
		
*/	
BEGIN
	SET NOCOUNT ON

	IF @isRollback = 1 AND @custId IS NOT NULL
	BEGIN
		UPDATE c	
			SET username = @oldname, RepUpdateTime = SYSDATETIME ()
		FROM CustInfoMini c WITH (ROWLOCK,UPDLOCK)
		WHERE custid = @custId

		RETURN
	END

	SELECT @custId = custid, @site = site, @roleid = roleid 
	FROM CustInfoMini WITH (NOLOCK) 
	WHERE username = @oldname

	IF @@ROWCOUNT = 0
	BEGIN
		IF @oldname = @newname
			SELECT @ErrMsg = 'An error occurs. New username and old username are the same!', @ErrCode = 101
		ELSE
			SELECT @ErrMsg = 'An error occurs. The user does not exist or new username is not available: ['+ @oldname + '] - ['+@newname+']', @ErrCode = 102		
		
		RETURN

	END

	-- check exist new username and register new username 
	SELECT  @newname = RTRIM(LTRIM(@newname))

	IF EXISTS (SELECT 1 FROM dbo.CustInfoMini WITH(NOLOCK) WHERE username = @newname)
			OR EXISTS (SELECT 1 FROM dbo.CustInfoMini WITH (NOLOCK) WHERE username2 = @newname)
			OR EXISTS (SELECT 1 FROM dbo.CustSubMini WITH (NOLOCK) WHERE username = @newname)
			OR EXISTS (SELECT 1 FROM dbo.CustSubMini WITH (NOLOCK) WHERE username2 = @newname)
	BEGIN
		SELECT @ErrMsg = 'An error occurs. The user does not exist or new username is not available: ['+ @oldname + '] - ['+@newname+']', @ErrCode = 102	
			    , @ErrCode = 201
		RETURN
	END
	
	BEGIN TRY
		UPDATE c	
			SET username = @newname, RepUpdateTime = SYSDATETIME ()
		FROM CustInfoMini c WITH (ROWLOCK,UPDLOCK)
		WHERE custid = @custId

	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = 'An error occurs. The user does not exist or new username is not available: ['+ @oldname + '] - ['+@newname+']', @ErrCode = 102	
			    , @ErrCode = 201
		RETURN
	END CATCH
END
GO

