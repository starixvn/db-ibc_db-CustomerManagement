ALTER PROCEDURE [dbo].[Acc_CustomerUpdAutoSuspend]
	@CustID			INT,
	@AutoSuspend	BIT,
	@UserID			INT,
	@Language		nvarchar(5)='E',
	@IP				varchar(15),
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(200) = '' OUTPUT
AS
/*	Created by: [Creator]
	Date: 2008
	Task: Update auto-suspend status of customer
	DB: DB02.bodb02

	Revisions:
		- 20090319@PhuongDao: 
			+ Update auto-suspend of all downlines under the unpline
			+ Remove @ReturnErrCode param
		- 20090801@Shifu: check disabled user	
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]				
		- 20090917@Phuc: Write log to dblog	
		- 20091008@Kiwi: Remove WriteLog_UserLog
		- 20100101@Lewin: Remove string 'update customer autosuspend' from param @LogSPData
		
	Param's Explanation:
		@IsUpdDownline: auto-suspended all downlines

*/
	SET NOCOUNT ON 
	--Check permission for account site: @phuc20080213
	EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
	--Check disable user
	EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
	--end
	DECLARE	@roleID	TINYINT,
			@old_AutoSuspend BIT,
			@uplineAutoSuspend BIT 
	
	SELECT	@roleID = roleID, 
			@old_AutoSuspend = isnull(autosuspend,0)
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

	IF @old_AutoSuspend = @AutoSuspend	RETURN

	IF @AutoSuspend = 0
	BEGIN
		IF @roleID = 1	SELECT	@uplineAutoSuspend = ISNULL(autosuspend,0)	
						FROM	custinfo WITH (NOLOCK)
						WHERE	custid = (SELECT recommend FROM custinfo WITH (NOLOCK) WHERE custid = @custID)
		IF @roleID = 2	SELECT	@uplineAutoSuspend = ISNULL(autosuspend,0)	
						FROM	custinfo WITH (NOLOCK)
						WHERE	custid = (SELECT mrecommend FROM custinfo WITH (NOLOCK) WHERE custid = @custID) 
		IF @roleID = 3	SELECT	@uplineAutoSuspend = ISNULL(autosuspend,0)	
						FROM	custinfo WITH (NOLOCK)
						WHERE	custid = (SELECT srecommend FROM custinfo WITH (NOLOCK) WHERE custid = @custID) 
		IF @roleID = 4	SELECT	@uplineAutoSuspend = 0  
	
		IF @uplineAutoSuspend = 1 
		BEGIN
			SELECT	@ErrMsg =  CASE @Language 
									WHEN 'E' THEN 'Upline has been auto-suspended. Cannot edit customer.'
									WHEN 'CS' THEN N'Upline has been auto-suspended. Cannot edit customer.'
									WHEN 'CT' THEN N'Upline has been auto-suspended. Cannot edit customer.'
									WHEN 'TH' THEN N'Upline has been auto-suspended. Cannot edit customer.'							
									WHEN 'J' THEN N'Upline has been auto-suspended. Cannot edit customer.'
									WHEN 'KO' THEN N'Upline has been auto-suspended. Cannot edit customer.'
									ELSE N'Upline has been auto-suspended. Cannot edit customer.'
									END, 
					@ErrCode = 102
			RETURN			
		END

	END	
	UPDATE	custinfo WITH (ROWLOCK, UPDLOCK)	SET	autosuspend = @Autosuspend	WHERE	custid = @custID 
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

	IF @roleID = 4 
	BEGIN
		UPDATE custinfo WITH (ROWLOCK,UPDLOCK)	SET	autosuspend = @Autosuspend	WHERE srecommend = @custID 
		IF @@ERROR <> 0
		BEGIN
			SELECT	@ErrMsg =	CASE @Language 
										WHEN 'E'	THEN 'Update process is unsuccessful.'
										WHEN 'CS'	THEN N'更新程序不成功。'
										WHEN 'CT'	THEN N'更新程序不成功。'
										WHEN 'TH'	THEN N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น'
										WHEN 'J'	THEN N'アップデート出来ません。'
										WHEN 'KO'	THEN N'업데이트에 실패했습니다.'
										ELSE N'Update process is unsuccessful.'
										END	, 
					@ErrCode = 104
			RETURN			
		END			
	END

	IF @roleID = 3 
	BEGIN
		UPDATE custinfo WITH (ROWLOCK,UPDLOCK)	SET	autosuspend = @Autosuspend	WHERE mrecommend = @custID 
		IF @@ERROR <> 0
		BEGIN
			SELECT	@ErrMsg =	CASE @Language 
									WHEN 'E'	THEN 'Update process is unsuccessful.'
									WHEN 'CS'	THEN N'更新程序不成功。'
									WHEN 'CT'	THEN N'更新程序不成功。'
									WHEN 'TH'	THEN N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น'
									WHEN 'J'	THEN N'アップデート出来ません。'
									WHEN 'KO'	THEN N'업데이트에 실패했습니다.'
									ELSE N'Update process is unsuccessful.'
									END	, 
					@ErrCode = 105
			RETURN			
		END			

	END

	IF @roleID = 2 
	BEGIN
		UPDATE custinfo WITH (ROWLOCK,UPDLOCK)	SET	autosuspend = @Autosuspend	WHERE recommend = @custID 
		IF @@ERROR <> 0
		BEGIN
			SELECT	@ErrMsg =	CASE @Language 
									WHEN 'E'	THEN 'Update process is unsuccessful.'
									WHEN 'CS'	THEN N'更新程序不成功。'
									WHEN 'CT'	THEN N'更新程序不成功。'
									WHEN 'TH'	THEN N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น'
									WHEN 'J'	THEN N'アップデート出来ません。'
									WHEN 'KO'	THEN N'업데이트에 실패했습니다.'
									ELSE N'Update process is unsuccessful.'
									END	, 
					@ErrCode = 106
			RETURN			
		END			
	END

	DECLARE @LogSPData varchar(2000)

	SELECT	@LogSPData =  '<Acc_CustomerUpdAutoSuspend CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" '+
						  'AutoSuspend="'+ coalesce(cast(@AutoSuspend as varchar(50)),space(1)) + '" '+
						  'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
						  'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
						  'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" '+
						  'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'"  />'
	
	/* 1110	Acc_CustomerUpdAutoSuspend	Update Auto Suspended status */												  						  	 
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 1110,
		@TrackingValue = @LogSPData	 

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAutoSuspend] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdAutoSuspend] TO [vnteam]