/*<info serverAlias="DBCUST-CustDB" executers="bodbadminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Acc_CustomerUpdSuspendedInfo
	@CustID		INT,
	@UserID		INT,
	@Language	VARCHAR(2) = 'E',	
	@IP			VARCHAR(15)= '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(500) = '' OUTPUT
AS
/*
	Created: 20200216@Thien
	Task : Update suspendInfo when admin add customer into locked suspend list
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20200216@Elodie: Initial SP [Redmine:#128451]  
	
	Param's Explanation:
*/
BEGIN

	SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT
	DECLARE @RoleID TINYINT, @Old_Suspended BIT, @UplineClosed BIT, @UplineSuspended BIT, @Suspended BIT,
			@srecommend INT, @mrecommend INT, @recommend INT
	SET @startRun = GETDATE()

	SELECT 
		@RoleID = RoleID, 
		@Old_Suspended = ISNULL(reject,0),
		@srecommend = srecommend,
		@mrecommend = mrecommend,
		@recommend = recommend
	FROM Custinfo WITH (NOLOCK)
	WHERE CustID = @CustID

	IF @roleid = 1
		SELECT	@UplineSuspended = ISNULL(reject,0),
				@UplineClosed = ISNULL(closed,0)
		FROM Custinfo with (nolock) where custid = @recommend 
	ELSE IF @roleid = 2
		SELECT  @UplineSuspended = ISNULL(reject,0),
				@UplineClosed = ISNULL(closed,0)
		FROM Custinfo with (nolock) where custid = @mrecommend 
	ELSE IF @roleid = 3
		SELECT  @UplineSuspended = ISNULL(reject,0), 
				@UplineClosed = ISNULL(closed,0)
		FROM Custinfo with (nolock) where custid = @srecommend 
	ELSE IF @roleid = 4
		SELECT @UplineSuspended = 0, @UplineClosed = 0
	
	IF @RoleID NOT IN (1,2,3,4)
	BEGIN
		SELECT @ErrMsg = CASE @Language 
							WHEN 'E' then 'Invalid user!!'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language)
						END, @ErrCode = 100	
		RETURN
	END

	-------------
	UPDATE	cs 
	SET	SuspendInfo = (SELECT suspendinfo FROM dbo.f_GenerateSuspendInfo(@roleid,@Suspended,ISNULL(SuspendInfo,0)))	
	FROM CustProductStatus cs WITH (ROWLOCK, UPDLOCK) 		
	WHERE custid = @CustID;	
	
	IF @RoleID BETWEEN 2 AND 4 
	BEGIN
		EXEC Acc_DynamicCustomerInfo_04
			@CustID		= @CustID
			,@RoleID	= @RoleID
			,@Action	= 'SuspendInfo'
			,@Suspended	= @Suspended					
	END

	---------------
	DECLARE @LogSPData varchar(8000),
			@ActionID INT 

	SELECT @LogSPData = '<R Suspended="'+ COALESCE(CAST(@Suspended AS VARCHAR(50)),space(1)) + '" '+
						'UserID="'+ COALESCE(CAST(@UserID AS VARCHAR(50)),space(1)) + '" '+
						'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),space(1))+'" '+
						'IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),space(1))+'" />'

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF (millisecond,@startRun,@endRun)

	--write log for themself
	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper 
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 1104,
		@TrackingValue = @LogSPData,
		@duration = @duration
		
	--write log to support downlines view upline's actions
	IF @roleid = 4
	BEGIN
		EXEC Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 65018,--master view on super action
			@TrackingValue = @LogSPData,
			@duration = @duration
			
		EXEC Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 70027,--agent view on super action
			@TrackingValue = @LogSPData,
			@duration = @duration
			
		EXEC Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 75036,--member view on super action
			@TrackingValue = @LogSPData,
			@duration = @duration
	END
		
	IF @roleid = 3
	BEGIN	
		EXEC Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 70028,--agent view on master action
			@TrackingValue = @LogSPData,
			@duration = @duration
			
		EXEC Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 75037,--member view on master action
			@TrackingValue = @LogSPData,
			@duration = @duration
	END
		
	IF @roleid = 2
	BEGIN	
		EXEC Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 75038,--member view on agent action
			@TrackingValue = @LogSPData,
			@duration = @duration
	END								
END
GO