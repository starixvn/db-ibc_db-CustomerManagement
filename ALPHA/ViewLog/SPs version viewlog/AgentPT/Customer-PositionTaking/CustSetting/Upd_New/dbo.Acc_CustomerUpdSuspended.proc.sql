ALTER PROCEDURE [dbo].[Acc_CustomerUpdSuspended]
	@CustID int,
	@Suspended bit,	
	@disCasino bit =0,
	@SubAccID int = 0, --Sub-AccountID
	@UserID int,
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IP varchar(15)=''
AS
/*
Created: 20090121@Thien
Task : Update suspended
DB: DB02.bodb02
Original:

Revisions:
    - 20090314@HanhVu: add Korean language
    - 20090341@HanhVu: hardcode: not allow agent and master to active 2 members 'S1p0106001','S1P0106002'
    - 20090430@kIWI: ROLLBACK --and @Old_Suspended <> @Suspended
	- 20090723@Phuc: Write log subaccname instead of subaccid.
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090917@Phuc: write log into DBLOG.
	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20091105@Hanh: Hardcode to not allow update closed status by moving Casino DB
	- 20091125@Terry : add one more para @disCasino check disabled Casino
	- 20100107@Lewin: Modify LogSPData Format, call new version write log
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON

--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end
IF exists(select 1 from custinfo with (nolock) where synccasino = 1 and custid = @CustID)
BEGIN
IF @disCasino = 1
	BEGIN	
		Select @ErrMsg = case @Language 
							when 'E' then 'This SUSPENDED function is temporarily unavailable, please update later.'
							when 'CS' then N'This SUSPENDED function is temporarily unavailable, please update later.'
							when 'CT' then N'This SUSPENDED function is temporarily unavailable, please update later.'
							when 'TH' then N'This SUSPENDED function is temporarily unavailable, please update later.'
							when 'J' then N'This SUSPENDED function is temporarily unavailable, please update later.'
							when 'KO' then N'This SUSPENDED function is temporarily unavailable, please update later.'
							else N'This SUSPENDED function is temporarily unavailable, please update later.'
						end	,
			@ErrCode = 105
			return
	END
END
---hardcode: force agent or master not able to active 2 member
Declare @custid_Edited int,@recommend int, @mrecommend int, @srecommend int
select @custid_Edited=custid,@recommend=recommend, @mrecommend=srecommend
from custinfo with (nolock) where username in ('S1p0106001','S1P0106002')
if @custid_Edited =@CustID and (@UserID=@recommend or @UserID=@mrecommend) and @Suspended = 0
begin
	SELECT @ErrMsg =  'This account was suspended by your upline!', @ErrCode = 105
	return
end
----------

Declare @RoleID tinyint , @UplineSuspended bit , @Old_Suspended bit, @UplineClosed bit
select 
	@RoleID = RoleID, 
	@Old_Suspended = isnull(reject,0),
	@srecommend = srecommend,
	@mrecommend = mrecommend,
	@recommend = recommend
from Custinfo with (nolock)
where CustID = @CustID

IF @roleid = 1
	Select @UplineSuspended = isnull(reject,0),
		@UplineClosed = isnull(closed,0)
	from Custinfo with (nolock) where custid = @recommend 
ELSE IF @roleid = 2
	Select @UplineSuspended = isnull(reject,0),
		@UplineClosed = isnull(closed,0)
	from Custinfo with (nolock) where custid = @mrecommend 
ELSE IF @roleid = 3
	Select @UplineSuspended = isnull(reject,0), 
		@UplineClosed = isnull(closed,0)
	from Custinfo with (nolock) where custid = @srecommend 
ELSE IF @roleid = 4
	Select @UplineSuspended = 0, @UplineClosed = 0

IF @UplineSuspended = 1 and @Old_Suspended <> @Suspended
BEGIN
	SELECT @ErrMsg =  CASE @Language 
						WHEN 'E' THEN 'This user''s upline was suspended. Cannot edit.'
						WHEN 'CS' THEN N'此用户的上线暂停，不能编辑。'
						WHEN 'CT' THEN N'此用戶的上線暫停，不能編輯。'
						WHEN 'TH' THEN N'ยูเซอร์นี้ได้ถูกระงับการใช้งานโดยอัพลายร์. ไม่สามารถแก้ไขได้'
						WHEN 'J' THEN N'This user''s upline was suspended. Cannot edit.'
						WHEN 'KO' THEN N'This user''s upline was suspended. Cannot edit.'
						ELSE N'This user''s upline was suspended. Cannot edit.'
					END, @ErrCode = 105
	return
END 
IF @UplineClosed = 1 AND @Old_Suspended <> @Suspended
BEGIN
	SELECT @ErrMsg =  CASE @Language 
							WHEN 'E' THEN 'This user''s upline was closed. Cannot edit.'
							WHEN 'CS' THEN N'此用户的上线关闭，不能编辑。'
							WHEN 'CT' THEN N'此用户的上线关闭，不能编辑。'
							WHEN 'TH' THEN N'ยูเซอร์นี้ได้ถูกปิดการใช้งานโดยอัพลายร์. ไม่สามารถแก้ไขได้'
							WHEN 'J' THEN N'This user''s upline was closed. Cannot edit.'
							ELSE N'This user''s upline was closed. Cannot edit.'
						END, @ErrCode = 106
	return
END
select @RoleID = isnull(@RoleID, 0)

if @RoleID not in (1,2,3,4)
BEGIN
	Select @ErrMsg = case @Language 
						when 'E' then 'Invalid user!!'
						when 'CS' then N'账号无效 !'
						when 'CT' then N'帳號無效. !'
						when 'TH' then N'ผู้ใช้ไม่ถูกต้อง!!'
						when 'J' then N'Invalid user!!'
						when 'KO' then N'잘못된 사용자 입니다!!'
						else N'Invalid user!!'
					end
	
	,
		@ErrCode = 100	
	return
END

IF @Old_Suspended = @Suspended RETURN 
-------------

update CustInfo with (ROWLOCK, UPDLOCK) set Reject = @Suspended
where CustID = @CustID
if (@@error <> 0)
begin
	
	Select @ErrMsg =
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end	, @ErrCode = 101
	return
end

if @RoleID = 4 
BEGIN
	update CustInfo with (ROWLOCK, UPDLOCK) set Reject = @Suspended where SRecommend = @CustID
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = 
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end	, @ErrCode = 102
	return
	end
END

if @RoleID = 3 
BEGIN
	update CustInfo with (ROWLOCK, UPDLOCK) set Reject = @Suspended where MRecommend = @CustID
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = 
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end	, @ErrCode = 103
	return
	end
END

if @RoleID = 2 
BEGIN
	update CustInfo with (ROWLOCK, UPDLOCK) set Reject = @Suspended where Recommend = @CustID
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = 
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end	, @ErrCode = 104
	return
	end
END
---------------
declare @LogSPData varchar(2000)

Select @LogSPData = '<Acc_CustomerUpdSuspended CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" '+
					'Suspended="'+ coalesce(cast(@Suspended as varchar(50)),space(1)) + '" '+
					'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" '+
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
					'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
					'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" '+
					'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 1104,
	@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSuspended] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSuspended] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSuspended] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdSuspended] TO [vnteam]
