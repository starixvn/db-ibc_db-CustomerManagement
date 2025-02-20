/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserInfoUpdSubGroupAdminPwd]
	@UserID		INT,
	@CustID		INT,	
	@UserPwd	nvarchar(50),		
	@IP			VARCHAR(50),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: 20201112@Johnson	
		Task: Admin main group reset pwd for admin sub group
		DB: DBCUST/CUSTDB
		
		Revisions:
			- 20201112@Johnson: initial sp [redmine:#145199]	
			- 20240812@Tacy: Remove check permission on function [redmineID: #208402]
			- 20241210@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]
		Parameter's Explanation:
	*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @startRun datetime  
		,@endRun datetime  
		,@duration int		
	
	SET @startRun=GETDATE()

	DECLARE @db_userpwd NVARCHAR(50)
	
	SELECT @db_userpwd = userpwd FROM Customer WITH(NOLOCK) WHERE custid = @custid
	
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrMsg = 'This user does not exist',
				@ErrCode = 100
		RETURN		
	END
	
	IF @db_userpwd = @userpwd
		RETURN	
				
	DECLARE @GroupID INT,
			@SubGroupID INT
			
	SELECT @GroupID = MAX( CASE WHEN userid = @userid THEN GroupID ELSE 0 END),
		@SubGroupID = MAX( CASE WHEN userid = @custid THEN GroupID ELSE 0 END)
	FROM NAP_UserControl.dbo.eaUserInfo WITH(NOLOCK)
	WHERE userid IN (@custid, @userid)
	
	IF @GroupID <> 1 --IT 
		AND NOT EXISTS(SELECT 1 
						FROM NAP_UserControl.dbo.eaGroup WITH(NOLOCK)
						WHERE GroupID = @SubGroupID
							AND ParentID = @GroupID
					)
	BEGIN
		SELECT @ErrMsg = 'You are not authorized to do this action.',
				@ErrCode = 101
		RETURN
	END
	
	DECLARE @PwdExpiry DATETIME

	SELECT @pwdexpiry = DATEADD(dd, 30, GETDATE())

	UPDATE customer  with (ROWLOCK, UPDLOCK)
	SET userpwd=@UserPwd, 
		pwdexpiry=@PwdExpiry,
		RepUpdateTime = dbo.f_GetDateTime2()
	WHERE custid=@CustID
		
	DECLARE @LogData NVARCHAR(MAX)
	SELECT @LogData = '<EAS_UserInfoUpdSubGroupAdminPwd>' + 				
						'<CustID>' + COALESCE(CAST(@CustID AS Varchar(50)),'') + '</CustID>' + 
						'<IP>' + COALESCE(@IP,'') + '</IP>' + 
					'</EAS_UserInfoUpdSubGroupAdminPwd>'
				
	SET @endRun = GETDATE()  
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)

	--Write log in IBC
	EXEC NAP_UserControl.[dbo].[WriteLog_UserLog_RunSP_Wrapper]
		@UserID			= @UserID, 
		@CustID			= @CustID,				
		@ActionID		= 20302, 
		@TrackingValue	= @LogData, 
		@duration		= @duration

	--Write log in EAS
	EXEC NAP_UserControl.[dbo].[EAS_WriteLog_UserLog_RunSP_Wrapper]
		@UserID			= @UserID, 
		@CustID			= @CustID,				
		@ActionID		= 20302, 
		@TrackingValue	= @LogData, 
		@duration		= @duration
END