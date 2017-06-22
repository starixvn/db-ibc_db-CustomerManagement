ALTER PROCEDURE [dbo].[Acc_CustomerUpdSyncLiveCS]
	@custid		INT,
	@syncLiveCS	BIT = 1,
	
	@UserID		INT = 0,
	@SubAccID	INT = 0, --Sub-AccountID
	@IP			VARCHAR(20)= '',
	@Language	VARCHAR(2) = 'E',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(4000) = '' OUTPUT
AS
	/*
		Created: Johnson
		Date: 2012-02-01
		DB: DBTXN/BODB02
		Task: Update synchronize status of live casino
		
		Revisions:
			- 20120327@Jamie: Checking Disabled/Enabled account on DBTRANS instead of DB053 
			- 20130124@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
			- 20130307@Lukas: add more write log section in case of DBLOG failed
		Parameters Explanation:
		
	*/
SET NOCOUNT ON 

	DECLARE @startRun DATETIME
	DECLARE @endRun DATETIME
	DECLARE @duration INT
	SET @startRun = GETDATE()
	
	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <>0 RETURN
	
	DECLARE @status INT, @Allow2Update BIT, @Old_SyncLiveCS BIT, @RoleID TINYINT, @UplineSyncLiveCS BIT
	
	SELECT @Old_SyncLiveCS=SyncLiveCasino,@RoleID=RoleID FROM custinfo(NOLOCK) WHERE custid=@custid
	
	IF(@RoleID IS NULL OR @roleid > 4) 
	BEGIN
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Account does not exist or invalid customer account'
											ELSE [dbo].[f_Get_MsgNamebyMsgID](40019,@Language) END, @ErrCode = 100	
		RETURN
	END
	
	IF @roleid = 4
		SELECT @ALlow2Update = 1
	ELSE
	BEGIN
		SELECT @UplineSyncLiveCS = SyncLiveCasino
		FROM CustInfo WITH(NOLOCK)
		WHERE custid = (SELECT CASE WHEN roleid = 1 THEN recommend
									WHEN roleid = 2 THEN mrecommend 
									WHEN roleid = 3 THEN srecommend END
						FROM CustInfo WITH(NOLOCK)
						WHERE custid = @custid
					)
		
		IF @UplineSyncLiveCS = 1
			SELECT @Allow2Update = 1
		ELSE 
			SELECT @Allow2Update = 0		
	END
	
	IF @Allow2Update = 0
	BEGIN
		SELECT @ErrMsg= CASE @Language WHEN 'E' THEN 'Cannot synchronize live casino because this account''s upline not synchronize live casino setting.'
											ELSE [dbo].[f_Get_MsgNamebyMsgID](60028,@Language) END, @ErrCode = 102	
		RETURN
	END
		
	UPDATE CustInfo WITH(ROWLOCK, UPDLOCK)
	SET synclivecasino = ISNULL(@SyncLiveCS,SyncLiveCasino)
	WHERE custid = @custid 
	
	--Log data
	DECLARE @LogData NVARCHAR(4000)
	DECLARE @TrackingValue2 NVARCHAR(4000)	

	SELECT @LogData ='<Acc_CustomerUpdSyncLiveCS custid="'+ COALESCE(CAST(@custid AS VARCHAR(50)),SPACE(1)) + '" ' +
	'SyncLiveCS="'+ COALESCE(CAST(@SyncLiveCS AS VARCHAR(50)),SPACE(1)) + '" ' +
	'ErrMsg="'+ COALESCE(CAST(@ErrMsg AS VARCHAR(400)),SPACE(1)) + '" ' +
	'UserID="'+ COALESCE(CAST(@UserID AS VARCHAR(50)),SPACE(1)) + '" ' +
	'SubAccName="'+ COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)),SPACE(1)) + '" ' +
	'IP="'+ COALESCE(CAST(@IP AS VARCHAR(20)),SPACE(1)) + '" ' +
	'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1))  + '" />'

	SELECT @TrackingValue2 ='<Acc_CustomerUpdSyncLiveCS custid="'+ COALESCE(CAST(@custid AS VARCHAR(50)),SPACE(1)) + '" ' +
	'SyncLiveCS="'+ COALESCE(CAST(@Old_SyncLiveCS AS VARCHAR(50)),SPACE(1)) + '" ' +
	'ErrMsg="'+ COALESCE(CAST(@ErrMsg AS VARCHAR(400)),SPACE(1)) + '" ' +
	'UserID="'+ COALESCE(CAST(@UserID AS VARCHAR(50)),SPACE(1)) + '" ' +
	'SubAccName="'+ COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)),SPACE(1)) + '" ' +
	'IP="'+ COALESCE(CAST(@IP AS VARCHAR(20)),SPACE(1)) + '" ' +
	'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1))  + '" />'
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
	BEGIN TRY	
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @UserID, 
			@CustID = @custid,
			@ActionID = 1135,
			@TrackingValue = @LogData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END TRY
	BEGIN CATCH
	
		SELECT @LogData ='<Acc_CustomerUpdSyncLiveCS custid="'+ COALESCE(CAST(@custid AS VARCHAR(50)),SPACE(1)) + '" ' +
		'SyncLiveCS="'+ COALESCE(CAST(@SyncLiveCS AS VARCHAR(50)),SPACE(1)) + '" ' +
		'ErrMsg="'+ COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(400)),SPACE(1)) + '" ' +
		'UserID="'+ COALESCE(CAST(@UserID AS VARCHAR(50)),SPACE(1)) + '" ' +
		'SubAccName="'+ COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)),SPACE(1)) + '" ' +
		'IP="'+ COALESCE(CAST(@IP AS VARCHAR(20)),SPACE(1)) + '" ' +
		'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1))  + '" />'

		SELECT @TrackingValue2 ='<Acc_CustomerUpdSyncLiveCS custid="'+ COALESCE(CAST(@custid AS VARCHAR(50)),SPACE(1)) + '" ' +
		'SyncLiveCS="'+ COALESCE(CAST(@Old_SyncLiveCS AS VARCHAR(50)),SPACE(1)) + '" ' +
		'ErrMsg="'+ COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(400)),SPACE(1)) + '" ' +
		'UserID="'+ COALESCE(CAST(@UserID AS VARCHAR(50)),SPACE(1)) + '" ' +
		'SubAccName="'+ COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)),SPACE(1)) + '" ' +
		'IP="'+ COALESCE(CAST(@IP AS VARCHAR(20)),SPACE(1)) + '" ' +
		'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1))  + '" />'
		
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @UserID, 
			@CustID = @custid,
			@ActionID = 1135,
			@TrackingValue = @LogData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END CATCH

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSyncLiveCS] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSyncLiveCS] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdSyncLiveCS] TO [vnteam]