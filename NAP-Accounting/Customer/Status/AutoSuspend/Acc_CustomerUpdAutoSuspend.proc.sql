ALTER PROCEDURE [dbo].[Acc_CustomerUpdAutoSuspend]
	@CustID			INT,
	@AutoSuspend	BIT = NULL, -- Auto-suspend Soccer
	@AutoSuspendOther BIT = NULL, -- Auto-suspend non-soccer sports
	@UserID			INT,
	@Language		nvarchar(5)='E',
	@IP				varchar(15),
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(200) = '' OUTPUT
AS
/*	Created by: [Creator]
	Date: 2008
	Task: Update auto-suspend status of customer
	DB: DBTXN/CustDB 

	Revisions:
		- 20090319@PhuongDao: 
			+ Update auto-suspend of all downlines under the unpline
			+ Remove @ReturnErrCode param
		- 20090801@Shifu: check disabled user	
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]				
		- 20090917@Phuc: Write log to dblog	
		- 20091008@Kiwi: Remove WriteLog_UserLog
		- 20100101@Lewin: Remove string 'update customer autosuspend' from param @LogSPData
		- 20101021@Henry: Record execution time
		- 20110709@Johnson: Change to use new server BD053 instead DB052
		- 20121206@Scott : Check Allowed downlines during peak hour at weekend 
		- 20130306@Lukas: change linked-server alias & add more write log section
		- 20131024@Kathy: Separate auto-suspend into Soccer and Other Sport [Redmine:#5520]
							+ Add @AutoSuspendOther param
							+ Apply execRep
		- 20131108@Elodie: Splitting bodb02 into CustDB (call Acc_ExecRep_Cust_04 instead of Acc_ExecRep_04)								
		- 20141125@Jamie: Change DB location & Acc_CustomerInfo_Execrep_04 instead of Acc_ExecRep_Cust_04 [Redmine:#26497]
		- 20150606@Elodie: Separate CustDB to DBCUST server (Move Acc_CustomerSelCheckAllowedDownlines, Acc_CustomerSelCheckEnable to DBCUST.CustDB)
	Param's Explanation:
		@IsUpdDownline: auto-suspended all downlines

*/
	SET NOCOUNT ON 
	
	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()
	
	--Check permission for account site: @phuc20080213
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[AutoSuspend]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
	--Check disable user
	EXEC Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
	--end
	DECLARE	@roleID	TINYINT,
			@old_AutoSuspend BIT,
			@old_AutoSuspendOther BIT,
			@old_AutoSuspendDownlines BIT,
			@old_AutoSuspendDownlinesOther BIT,
			@uplineAutoSuspend BIT,
			@uplineAutoSuspendOther BIT 
			
	
	SELECT	@roleID = roleID, 
			@old_AutoSuspend = isnull(autosuspend,0),
			@old_AutoSuspendOther = ISNULL(autosuspend2, 0)
	FROM	custinfo WITH (NOLOCK) 
	WHERE	custID = @custid 

	IF @roleID NOT IN (1,2,3,4)
	BEGIN 
		SELECT	@ErrMsg = CASE @Language 
								WHEN 'E'	THEN 'Invalid user!'
								WHEN 'CS'	THEN N'账号无效!'
								WHEN 'CT'	THEN N'帳號無效.!'
								WHEN 'TH'	THEN N'ผู้ใช้ไม่ถูกต้อง!'
								WHEN 'J'	THEN N'Invalid user!'
								WHEN 'KO'	THEN N'잘못된 사용자 입니다.'
								ELSE N'Invalid user!'
								END, 
				@ErrCode = 100	
		RETURN
	END

	select @AutoSuspend = ISNULL(@AutoSuspend, @old_AutoSuspend),
			@AutoSuspendOther = ISNULL(@AutoSuspendOther, @old_AutoSuspendOther)

	IF @old_AutoSuspend = @AutoSuspend and @old_AutoSuspendOther = @AutoSuspendOther
		RETURN

	-- Check Allowed downlines during peak hour at weekend 
	EXEC Acc_CustomerSelCheckAllowedDownlines	@custid=@custid,
											@roleid=@roleid,
											@isExecRep=1,
											@Language=@Language,
											@ErrMsg=@ErrMsg output,
											@ErrCode=@ErrCode output
	if @ErrCode <>0 return 
	--End 


	IF @AutoSuspend = 0 or @AutoSuspendOther = 0 -- need to check upline when enable Auto-suspend
	BEGIN
		IF @roleID = 1	SELECT	@uplineAutoSuspend = ISNULL(autosuspend,0),
								@uplineAutoSuspendOther = ISNULL(autosuspend2, 0)	
						FROM	custinfo WITH (NOLOCK)
						WHERE	custid = (SELECT recommend 
											FROM custinfo WITH (NOLOCK) 
											WHERE custid = @custID)

		IF @roleID = 2	SELECT	@uplineAutoSuspend = ISNULL(autosuspend,0),	
								@uplineAutoSuspendOther = ISNULL(autosuspend2, 0)	
						FROM	custinfo WITH (NOLOCK)
						WHERE	custid = (SELECT mrecommend 
											FROM custinfo WITH (NOLOCK) 
											WHERE custid = @custID) 

		IF @roleID = 3	SELECT	@uplineAutoSuspend = ISNULL(autosuspend,0),	
								@uplineAutoSuspendOther = ISNULL(autosuspend2, 0)	
						FROM	custinfo WITH (NOLOCK)
						WHERE	custid = (SELECT srecommend 
											FROM custinfo WITH (NOLOCK) 
											WHERE custid = @custID) 

		IF @roleID = 4	SELECT	@uplineAutoSuspend = 0, @uplineAutoSuspendOther = 0  
		
		IF @uplineAutoSuspendOther = 1 and @old_AutoSuspendOther <> @AutoSuspendOther
		begin
			SELECT	@ErrMsg =  CASE @Language 
									WHEN 'E' THEN 'Upline has been auto-suspended for other sports. Cannot edit customer.'
									WHEN 'CS' THEN N'Upline has been auto-suspended for other sports. Cannot edit customer.'
									WHEN 'CT' THEN N'Upline has been auto-suspended for other sports. Cannot edit customer.'
									WHEN 'TH' THEN N'Upline has been auto-suspended for other sports. Cannot edit customer.'					
									WHEN 'J' THEN N'Upline has been auto-suspended for other sports. Cannot edit customer.'
									WHEN 'KO' THEN N'Upline has been auto-suspended for other sports. Cannot edit customer.'
									ELSE N'Upline has been auto-suspended for other sports. Cannot edit customer.'
									END, 
					@ErrCode = 101
			RETURN			
		END

		IF @uplineAutoSuspend = 1 and @old_AutoSuspend <> @AutoSuspend
		BEGIN
			SELECT	@ErrMsg =  CASE @Language 
									WHEN 'E' THEN 'Upline has been auto-suspended for Soccer sport. Cannot edit customer.'
									WHEN 'CS' THEN N'Upline has been auto-suspended for Soccer sport. Cannot edit customer.'
									WHEN 'CT' THEN N'Upline has been auto-suspended for Soccer sport. Cannot edit customer.'
									WHEN 'TH' THEN N'Upline has been auto-suspended for Soccer sport. Cannot edit customer.'			
									WHEN 'J' THEN N'Upline has been auto-suspended for Soccer sport. Cannot edit customer.'
									WHEN 'KO' THEN N'Upline has been auto-suspended for Soccer sport. Cannot edit customer.'
									ELSE N'Upline has been auto-suspended for Soccer sport. Cannot edit customer.'
									END, 
					@ErrCode = 102
			RETURN			
		END
	END	

	UPDATE	custinfo WITH (ROWLOCK, UPDLOCK)	
	SET	autosuspend = @Autosuspend	,
		autosuspend2 = @AutoSuspendOther
	WHERE	custid = @custID 

	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrMsg =
					CASE @Language 
							WHEN 'E'	THEN 'Update process is unsuccessful.'
							WHEN 'CS'	THEN N'更新程序不成功。'
							WHEN 'CT'	THEN N'更新程序不成功。'
							WHEN 'TH'	THEN N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น'
							WHEN 'J'	THEN N'アップデート出来ません。'
							WHEN 'KO'	THEN N'업데이트에 실패했습니다.'
							ELSE N'Update process is unsuccessful.'
							END	, 
				@ErrCode = 103
		RETURN			
	END
	-- check condition for update all downline for Soccer
	if @old_AutoSuspend <> @AutoSuspend and @old_AutoSuspendOther <> @AutoSuspendOther
	begin
		-- apply exec rep for all: Soccer and Other sports
		EXEC [Acc_CustomerInfo_Execrep_04]
		@CustID		= @CustID,
		@RoleID		= @RoleID,
		@Action		= 'AutoSuspend',
		@AutoSuspendSoccer = @AutoSuspend,
		@AutoSuspendOtherSports = @AutoSuspendOther
	end
	else if @old_AutoSuspend <> @AutoSuspend
	begin
		-- apply exec rep for Soccer
		EXEC [Acc_CustomerInfo_Execrep_04]
		@CustID		= @CustID,
		@RoleID		= @RoleID,
		@Action		= 'AutoSuspendSoccer',
		@AutoSuspendSoccer = @AutoSuspend
	end
	else if @old_AutoSuspendOther <> @AutoSuspendOther
	begin
		-- apply exec rep for other sports
		EXEC [Acc_CustomerInfo_Execrep_04]
		@CustID		= @CustID,
		@RoleID		= @RoleID,
		@Action		= 'AutoSuspendOther',
		@AutoSuspendOtherSports = @AutoSuspendOther
	end

	Declare @LogSPData varchar(MAX),
		@TrackingValueDB varchar(max)

	SELECT	@LogSPData =  '<Acc_CustomerUpdAutoSuspend CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" '+
						  'AutoSuspend="'+ coalesce(cast(@AutoSuspend as varchar(2)),space(1)) + '" '+
						  'AutoSuspendOtherSports="'+ coalesce(cast(@AutoSuspendOther as varchar(2)),space(1)) + '" '+
						  'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
						  'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1))+'" '+
						  'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
						  'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" '+
						  'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'"  />'

	SELECT	@TrackingValueDB =  '<Acc_CustomerUpdAutoSuspend CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" '+
						  'AutoSuspend="'+ coalesce(cast(@old_AutoSuspend as varchar(2)),space(1)) + '" '+
						  'AutoSuspendOtherSports="'+ coalesce(cast(@old_AutoSuspendOther as varchar(2)),space(1)) + '" '+
						  'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
						  'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1))+'" '+
						  'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
						  'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" '+
						  'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'"  />'
	
	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)
	
	/* 1110	Acc_CustomerUpdAutoSuspend	Update Auto Suspended status */	
	BEGIN TRY											  						  	 
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 1110,
			@TrackingValue = @LogSPData	,
			@TrackingValue2 = @TrackingValueDB,
			@duration = @duration 
	END TRY
	BEGIN CATCH
		SELECT	@LogSPData =   '<Acc_CustomerUpdAutoSuspend CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" '+
						  'AutoSuspend="'+ coalesce(cast(@AutoSuspend as varchar(2)),space(1)) + '" '+
						  'AutoSuspendOtherSports="'+ coalesce(cast(@AutoSuspendOther as varchar(2)),space(1)) + '" '+
						  'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
						  'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1))+'" '+
						  'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
						  'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(400)),space(1))+'" '+
						  'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'"  />'
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 1110,
			@TrackingValue = @LogSPData	,
			@TrackingValue2 = @TrackingValueDB,
			@duration = @duration 
	END CATCH


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAutoSuspend] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdAutoSuspend] TO [vnteam] AS [dbo]