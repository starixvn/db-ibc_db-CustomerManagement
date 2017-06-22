ALTER PROCEDURE [dbo].[Acc_CustomerUpdDisableOutright]
	@CustID int,
	@DisableOutright bit,	
	@SubAccID int = 0, --Sub-AccountID
	@UserID int,
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IP varchar(15)=''
AS
/*
Created: 
Task : Update status 'DisableOutright' for custinfo
DB: DB02.bodb02
Original:

Revisions:
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090909@Phuc: check upline suspended.
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Kiwi: amend to write log in xml format.
Param's Explanation:
*/

SET NOCOUNT ON
--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end

---------------------------

Declare @roleid tinyint, @Old_DisableOutright bit, @UplineDisableOutright bit, @srecommend int, @mrecommend int, @recommend int

select 
	@roleid = roleid, 
	@Old_DisableOutright = DisableOutright,
	@srecommend = srecommend,
	@mrecommend = mrecommend,
	@recommend = recommend
from custinfo with (nolock)
where custid = @custid


IF @Old_DisableOutright = @DisableOutright 
	return

IF @roleid = 1
	Select @UplineDisableOutright = isnull(disableoutright,0) from Custinfo with (nolock) where custid = @recommend 
ELSE IF @roleid = 2
	Select @UplineDisableOutright = isnull(disableoutright,0) from Custinfo with (nolock) where custid = @mrecommend 
ELSE IF @roleid = 3
	Select @UplineDisableOutright = isnull(disableoutright,0) from Custinfo with (nolock) where custid = @srecommend 
ELSE IF @roleid = 4
	Select @UplineDisableOutright = 0

IF @UplineDisableOutright = 1
BEGIN
	SELECT @ErrMsg =  CASE @Language 
						WHEN 'E' THEN 'Your account was disabled outright. Cannot edit member.'
						WHEN 'CS' THEN N'您的帐户已被禁用优胜冠军。不能编辑会员'
						WHEN 'CT' THEN N'您的帳戶已被禁用優勝冠軍。不能編輯會員'
						WHEN 'TH' THEN N'บัญชีของท่านเอาท์ไรท์ได้ถูดปิดใช้งาน ไม่สามารถแก้ไขสมาชิกได้'
						WHEN 'J' THEN N'Your account was disabled outright. Cannot edit member.'
						WHEN 'KO' THEN N'Your account was disabled outright. Cannot edit member.'
						ELSE N'Your account was disabled outright. Cannot edit member.'
					END, @ErrCode = 105
	return
END 


select @roleid = isnull(@roleid, 0)

if @roleid not in (1,2,3,4)
BEGIN
	Select @ErrMsg = case @Language 
						when 'E' then 'Invalid user!!'
						when 'CS' then N'账号无效.'
						when 'CT' then N'帳號無效.'
						when 'TH' then N'ผู้ใช้ไม่ถูกต้อง!!'
						when 'J' then N'Invalid user!!'
						when 'KO' then N'잘못된 사용자 입니다!!'
						else N'Invalid user!!'
					end	,
		@ErrCode = 100	
	return
END


update custinfo with (ROWLOCK, UPDLOCK) set DisableOutright = @DisableOutright
where custid = @custid

if (@@error <> 0)
begin
	Select @ErrMsg =
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น!!'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end	, @ErrCode = 101
	return
end

if @roleid = 4
begin
	update custinfo with (ROWLOCK, UPDLOCK) set DisableOutright = @DisableOutright where srecommend = @custid
	if (@@error <> 0)
	begin
		Select @ErrMsg = 
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น!!'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end	, @ErrCode = 102
	return
	end
end

if @roleid = 3
begin
	update custinfo with (ROWLOCK, UPDLOCK) set DisableOutright = @DisableOutright where mrecommend = @custid
	if (@@error <> 0)
	begin
		Select @ErrMsg = 
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น!!'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end	, @ErrCode = 103
	return
	end
end

if @roleid = 2
begin
	update custinfo with (ROWLOCK, UPDLOCK) set DisableOutright = @DisableOutright where recommend = @custid
	if (@@error <> 0)
	begin
		Select @ErrMsg = 
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น!!'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end	, @ErrCode = 104
	return
	end
end

Declare @LogSPData varchar(5000)
Select @LogSPData = '<Acc_CustomerUpdDisableOutright CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" ' +
'DisableOutright="'+ coalesce(cast(@DisableOutright as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))  + '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 1111,
	@TrackingValue = @LogSPData

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDisableOutright] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDisableOutright] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDisableOutright] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdDisableOutright] TO vnteam