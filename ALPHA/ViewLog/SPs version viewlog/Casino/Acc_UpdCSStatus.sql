ALTER PROCEDURE [dbo].[Acc_UpdCSStatus]
	@custid INT,
	@disabledCS BIT=NULL,
	@syncCS BIT=NULL,
	@enableDownline BIT=0,
	@status BIT=0 OUTPUT,
	
	@ErrMsg NVARCHAR(200) = '' OUTPUT,	
	
	@UserID INT = 0,
	@SubAccID INT = 0, --Sub-AccountID
	@LoginIP VARCHAR(20)='',
	@Language VARCHAR(2) = 'E'
AS
/*

Created: 20090310@QuiNV
Task: Update casino status
DB: DB02.bodb02
Original:

   Revisions:
	- 20090421@Lee: Add params and add write log section.
	- 20090729@Phuc: write log subaccname instead of subaccid.
	- 20090801@Shifu: check disabled user
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090402@Phuc: write log into dblog.
	- 20100105@Hanh: Replace Chinese language.
	- 20100114@Simon: Update disable status for Casino.
	- 20100112@Kiwi: amend to write log in xml format.
*/
SET NOCOUNT ON
Declare @ErrCode int
--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end

BEGIN TRY

-- Checking

DECLARE @Allow2Udpate BIT, @SyncCasino BIT ,@RoleID TINYINT
SELECT @SyncCasino=SyncCasino,@RoleID=RoleID FROM custinfo(NOLOCK) WHERE custid=@custid
IF(@RoleID IS NULL OR @roleid > 4) 
BEGIN
	SELECT @status=0,@ErrMsg=
					CASE @Language 
						WHEN 'E' THEN 'Account does not exist or invalid customer account'
						WHEN 'CS' THEN N'此账号无效或不存在'
						WHEN 'CT' THEN N'此賬號無效或不存在'
						WHEN 'TH' THEN N'Account does not exist or invalid customer account'
						WHEN 'J' THEN N'Account does not exist or invalid customer account'
						WHEN 'KO' THEN N'Account does not exist or invalid customer account'
						ELSE N'Account does not exist or invalid customer account'
					END	
	RETURN
END

IF @SyncCasino = 0  AND @syncCS = 0 AND @disabledCS = 0
BEGIN
	SELECT @status=0,@ErrMsg=
					CASE @Language 
						WHEN 'E' THEN 'Cannot enable casino because this account does not have casino setting.'
						WHEN 'CS' THEN N'不能启用娱乐城由于这个帐户没有娱乐城设定'
						WHEN 'CT' THEN N'不能啟用娛樂城由於這個帳戶沒有娛樂城設定'
						WHEN 'TH' THEN N'ไม่สามารถเปิดใช้งานคาสิโนได้  เนื่องด้วยยูเซอร์นี้ยังไม่ได้ตั้งค่าคาสิโน'
						WHEN 'J' THEN N'Cannot enable casino because this account does not have casino setting.'
						WHEN 'KO' THEN N'Cannot enable casino because this account does not have casino setting.'
						ELSE N'Cannot enable casino because this account does not have casino setting.'
					END		
	RETURN
END

IF(@roleid = 4)
	SELECT @Allow2Udpate=1
ELSE
	SELECT @Allow2Udpate= ISNULL((SyncCasino),0)
	FROM custinfo(NOLOCK)
	WHERE
	custid = (SELECT CASE roleid WHEN 1 THEN recommend
								WHEN 2 THEN mrecommend
								WHEN 3 THEN srecommend END
		  FROM custinfo(NOLOCK) WHERE custid=@custid)

IF @Allow2Udpate = 0
BEGIN
	SELECT @status=0,@ErrMsg=
					CASE @Language 
						WHEN 'E' THEN 'Cannot enable casino because this account''s upline is disabled or does not have casino setting.'
						WHEN 'CS' THEN N'不能启用娱乐城，由于此帐户的上线被禁用或没有娱乐城设定。'
						WHEN 'CT' THEN N'不能啟用娛樂城，由於此帳戶的上線被禁用或沒有娛樂城設定。'
						WHEN 'TH' THEN N'ไม่สามารถเปิดใช้งานคาสิยูเซอร์ เนื่องด้วยอัพลายร์ปิดการใช้งานหรือไม่ได้ตั้งค่าคาสิโน'
						WHEN 'J' THEN N'Cannot enable casino because this account''s upline is disabled or does not have casino setting.'
						WHEN 'KO' THEN N'Cannot enable casino because this account''s upline is disabled or does not have casino setting.'
						ELSE N'Cannot enable casino because this account''s upline is disabled or does not have casino setting.'
					END	
	RETURN
END

-- Update itself
UPDATE CustInfo SET
	DisableCasino = ISNULL(@disabledCS, DisableCasino),
	SyncCasino = CASE @syncCS WHEN 1 THEN 1 ELSE SyncCasino END
WHERE custid=@custid

-- Update downline
IF @disabledCS = 1 OR @enableDownline = 1
BEGIN
UPDATE CustInfo SET
	DisableCasino = @disabledCS
WHERE SyncCasino=1 AND srecommend=@custid OR mrecommend=@custid OR recommend=@custid
END 

SELECT @status = 1
	
END TRY

BEGIN CATCH
	SELECT @status = 0
END CATCH



--Log data
DECLARE @LogData NVARCHAR(200)
---------------------------
select @LogData ='<Acc_UpdCSStatus custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'disabledCS="'+ coalesce(cast(@disabledCS as varchar(50)),space(1)) + '" ' +
'syncCS="'+ coalesce(cast(@syncCS as varchar(50)),space(1)) + '" ' +
'enableDownline="'+ coalesce(cast(@enableDownline as varchar(50)),space(1)) + '" ' +
'status="'+ coalesce(cast(@status as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'LoginIP="'+ coalesce(cast(@LoginIP as varchar(20)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))  + '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID, 
	@CustID = @custid,
	@ActionID = 1109,
	@TrackingValue = @LogData

GO
GRANT EXECUTE ON [dbo].[Acc_UpdCSStatus] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_UpdCSStatus] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UpdCSStatus] TO [vnteam]
GO