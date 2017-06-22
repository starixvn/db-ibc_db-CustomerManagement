ALTER PROCEDURE [dbo].[Acc_CustomerUpdDisableFI]
	@CustID int,
	@DisableFinancial bit,
	@DisableDownlineFI bit = 1,--Disable all downline
	@SubAccID int = 0, --Sub-AccountID
	@UserID int,
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IP varchar(15)=''
AS
/*
Created: 
Task : update financial customer's status!
DB: DB02.bodb02
Original: Acc_CustomerUpdDisableFI

Revisions:
    - 20090314@HanhVu: add Korean language
    - 20090317@Phuc: open all downline; not check upline for super.
	- 20090320@PhuongDao:
		+ Change param @IsUpdDownline to @DisableDownline 
		+ Not checking whether a user change his own FI status or not 
	- 20090723@Phuc: Write log subaccname instead of subaccid.
	- 20090801@Shifu: check disabled user
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090917@Phuc: write log into DBLOG.
	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20100102@Lewin: Modify @LogSPData, writelog by function WriteLog_UserLog_RunSPNew
Param's Explanation:
• @CustId: customer id
• @DisableFinancial: status
*/
SET NOCOUNT ON
--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end

Declare @RoleID tinyint , @UplineDisableFinancial bit,  @Old_DisableFinancial bit, @Username varchar(40)

select @Username=username, @RoleID = RoleID, @Old_DisableFinancial = isnull(DisableFinancial, 0)
from Custinfo with (nolock)
where CustID = @CustID

if @RoleID not in (1,2,3,4)
BEGIN
	Select @ErrMsg = case @Language 
						when 'E' then 'Invalid user!'
						when 'CS' then N'账号无效!'
						when 'CT' then N'帳號無效.!'
						when 'TH' then N'ผู้ใช้ไม่ถูกต้อง!'
						when 'J' then N'Invalid user!'
						when 'KO' then N'잘못된 사용자 입니다!'
						else N'Invalid user!'
					end, @ErrCode = 100	
	return
END

--current status change or not?
--Do not need to show the alert thus this Sp use for all setting 
if @Old_DisableFinancial = @DisableFinancial RETURN

if @DisableFinancial = 0 -- check status upline
begin			
	if @RoleID = 3
		SELECT @UplineDisableFinancial = isnull(DisableFinancial,0) FROM CustInfo with (nolock)
		WHERE custid = (SELECT SRecommend FROM Custinfo with (nolock) WHERE custid = @CustID)
	if @RoleID = 2
		SELECT @UplineDisableFinancial = isnull(DisableFinancial,0) FROM CustInfo with (nolock)
		WHERE custid = (SELECT MRecommend FROM Custinfo with (nolock) WHERE custid = @CustID)
	if @RoleID = 1
		SELECT @UplineDisableFinancial = isnull(DisableFinancial,0) FROM CustInfo with (nolock)
		WHERE custid = (SELECT Recommend FROM Custinfo with (nolock) WHERE custid = @CustID)
	if @RoleID = 4 
		Select @UplineDisableFinancial = 0
		
	IF @UplineDisableFinancial = 1
	BEGIN
		SELECT @ErrMsg =    @Username + ': ' +
			CASE @Language 
							WHEN 'E' THEN 'Your account was disabled Finance betting. Cannot edit customer.'
							WHEN 'CS' THEN N'金融投注目前已被上线限制。无法修改会员。'
							WHEN 'CT' THEN N'金融投注目前已被上線限制。無法修改會員。'
							WHEN 'TH' THEN N'Your account was disabled Financial betting. Cannot edit customer.'
							WHEN 'J' THEN N'Your account was disabled Financial betting. Cannot edit customer.'
							WHEN 'KO' THEN N'Your account was disabled Financial betting. Cannot edit customer.'
							ELSE N'Your account was disabled Financial betting. Cannot edit customer.'
						END, @ErrCode = 105
		return
	END 
end




update CustInfo with (ROWLOCK, UPDLOCK) set DisableFinancial = @DisableFinancial
where CustID = @CustID
if (@@error <> 0)
begin
	
	Select @ErrMsg =  @Username + ': ' +
					case @Language 
						when 'E' then 'Update process is unsuccessful.'
						when 'CS' then N'更新程序不成功。'
						when 'CT' then N'更新程序不成功。'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful.'
					end	, @ErrCode = 101
	return
end
--Check condition for update all downline
if (@DisableFinancial = 1 or (@DisableFinancial = 0 and @DisableDownlineFI = 0)) --Disable all downline or enable all downline
begin
	if @RoleID = 4 
	BEGIN
		update CustInfo with (ROWLOCK, UPDLOCK) set DisableFinancial = @DisableFinancial where SRecommend = @CustID
		if (@@error <> 0)
		begin
			
			Select @ErrMsg =   @Username + ': ' +
						case @Language 
							when 'E' then 'Update process is unsuccessful.'
							when 'CS' then N'更新程序不成功。'
							when 'CT' then N'更新程序不成功。'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful.'
						end	, @ErrCode = 102
		return
		end
	END

	if @RoleID = 3 
	BEGIN
		update CustInfo with (ROWLOCK, UPDLOCK) set DisableFinancial = @DisableFinancial where MRecommend = @CustID
		if (@@error <> 0)
		begin
			
			Select @ErrMsg =   @Username + ': ' +
						case @Language 
							when 'E' then 'Update process is unsuccessful.'
							when 'CS' then N'更新程序不成功。'
							when 'CT' then N'更新程序不成功。'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful.'
						end	, @ErrCode = 103
		return
		end
	END

	if @RoleID = 2 
	BEGIN
		update CustInfo with (ROWLOCK, UPDLOCK) set DisableFinancial = @DisableFinancial where Recommend = @CustID
		if (@@error <> 0)
		begin
			
			Select @ErrMsg =   @Username + ': ' +
						case @Language 
							when 'E' then 'Update process is unsuccessful.'
							when 'CS' then N'更新程序不成功。'
							when 'CT' then N'更新程序不成功'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful.'
						end	, @ErrCode = 104
		return
		end
	END
END

declare @LogSPData varchar(2000)

Select @LogSPData = '<Acc_CustomerUpdDisableFI CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" '+
					'DisableFinancial="'+ coalesce(cast(@DisableFinancial as varchar(50)),space(1)) + '" '+
					'DisableDownline="'+ coalesce(cast(@DisableDownlineFI as varchar(50)),space(1)) + '" '+
					'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
					'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" ' +
					'ErrCode='+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
					'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" ' +
					'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
	
/* 1108	Acc_CustomerUpdDisableFI	Update Enabled/Disabled Finance's Status*/
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 1108,
	@TrackingValue = @LogSPData

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDisableFI] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDisableFI] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDisableFI] TO [bodbDownlineNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdDisableFI] TO [vnteam]