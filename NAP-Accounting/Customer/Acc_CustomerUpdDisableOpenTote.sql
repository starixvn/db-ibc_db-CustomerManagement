ALTER PROCEDURE [dbo].[Acc_CustomerUpdDisableOpenTote]
	@CustID int,
	@DisableHorseracing bit,
	@DisableDownline bit = true, --Disable all downline
	@SubAccID int = 0, --Sub-AccountID
	@UserID int,
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IP varchar(15)=''
AS
/*
Created: 20100414@huy.nguyen
Task : Update OpenTote status for customer
DB: DB02.bodb02
Original:

Revisions:
Param's Explanation:
• @custid: customer id.   
• @DisableHorseracing: status
*/
SET NOCOUNT ON
--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end
Declare @RoleID tinyint , @UplineDisableHorseracing bit, @Old_DisableHorseracing bit

select	@RoleID = RoleID,
		@Old_DisableHorseracing = isnull(DisableOpenTote, 0)

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
						when 'KO' then N'잘못된 사용자 입니다.'
						else N'Invalid user!'
					end, @ErrCode = 100	
	return
END

--current status change or not?
-- Qui.Nguyen add "and @IsUpdDownline = 0" for wap
-- Remove @IsUpdDownline

if @Old_DisableHorseracing = @DisableHorseracing RETURN--and @IsUpdDownline = 0
--begin
	--rase message if Account was already disabled!
--	if (@DisableHorseracing = 1 AND @UplineDisableHorseracing = 1)
--	begin
--		SELECT @ErrMsg =  CASE @Language 
--							WHEN 'E' THEN 'Your account was disabled Horse Racing betting. Cannot edit customer.'
--							WHEN 'CS' THEN N'赛马投注目前已被上线限制。无法修改会员。'
--							WHEN 'CT' THEN N'賽馬投注目前已被上線限制。無法修改會員。'
--							WHEN 'TH' THEN N'Your account was disabled Horse Racing betting. Cannot edit customer.'							
--							WHEN 'J' THEN N'Your account was disabled Horse Racing betting. Cannot edit customer.'
--							WHEN 'KO' THEN N'Your account was disabled Horse Racing betting. Cannot edit customer.'
--							ELSE N'Your account was disabled Horse Racing betting. Cannot edit customer.'
--						END
--	end
--
--	return
--end

if @DisableHorseracing = 0 -- check status upline
begin			
	if @RoleID = 3
		SELECT @UplineDisableHorseracing = isnull(DisableOpenTote,0) FROM CustInfo with (nolock)
		WHERE custid = (SELECT SRecommend FROM Custinfo with (nolock) WHERE custid = @CustID)
	if @RoleID = 2
		SELECT @UplineDisableHorseracing = isnull(DisableOpenTote,0) FROM CustInfo with (nolock)
		WHERE custid = (SELECT MRecommend FROM Custinfo with (nolock) WHERE custid = @CustID)
	if @RoleID = 1
		SELECT @UplineDisableHorseracing = isnull(DisableOpenTote,0) FROM CustInfo with (nolock)
		WHERE custid = (SELECT Recommend FROM Custinfo with (nolock) WHERE custid = @CustID)
	IF @RoleID = 4 SELECT @UplineDisableHorseracing = 0   --not checking the upline when the customer is the super
		
	IF @UplineDisableHorseracing = 1
	BEGIN
		SELECT @ErrMsg =  CASE @Language 
							WHEN 'E' THEN 'Your account was disabled Horse Racing betting. Cannot edit customer.'
							WHEN 'CS' THEN N'赛马投注目前已被上线限制。无法修改会员。'
							WHEN 'CT' THEN N'賽馬投注目前已被上線限制。無法修改會員。'
							WHEN 'TH' THEN N'Your account was disabled Horse Racing betting. Cannot edit customer.'							
							WHEN 'J' THEN N'Your account was disabled Horse Racing betting. Cannot edit customer.'
							WHEN 'KO' THEN N'Your account was disabled Horse Racing betting. Cannot edit customer.'
							ELSE N'Your account was disabled Horse Racing betting. Cannot edit customer.'
						END, @ErrCode = 105
		return
	END 
end

---------------------

update CustInfo with (ROWLOCK, UPDLOCK) set DisableOpenTote = @DisableHorseracing
where CustID = @CustID
if (@@error <> 0)
begin

	Select @ErrMsg =
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
if (@DisableHorseracing = 1 or (@DisableHorseracing = 0 and @DisableDownline = 0)) --Disable all downline or enable all downline
begin
	if @RoleID = 4 
	BEGIN
		update CustInfo with (ROWLOCK, UPDLOCK) set DisableOpenTote = @DisableHorseracing where SRecommend = @CustID
		if (@@error <> 0)
		begin
			
			Select @ErrMsg = 
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
		update CustInfo with (ROWLOCK, UPDLOCK) set DisableOpenTote = @DisableHorseracing where MRecommend = @CustID
		if (@@error <> 0)
		begin
			
			Select @ErrMsg = 
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
		update CustInfo with (ROWLOCK, UPDLOCK) set DisableOpenTote = @DisableHorseracing where Recommend = @CustID
		if (@@error <> 0)
		begin
			
			Select @ErrMsg = 
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
End

declare @LogSPData varchar(2000)

Select @LogSPData = '<Acc_CustomerUpdDisableOpenTote CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" '+
					'DisableOpenTote="'+ coalesce(cast(@DisableHorseracing as varchar(50)),space(1)) + '" '+
					'DisableDownline="'+ coalesce(cast(@DisableDownline as varchar(50)),space(1)) + '" '+
					'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" '+
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
					'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
					'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" '+
					'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

/*1107	Acc_CustomerUpdDisableHR	Update Enabled/Disabled Horse racing status*/
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 1107,
	@TrackingValue = @LogSPData	 



GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDisableOpenTote] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDisableOpenTote] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdDisableOpenTote] TO [vnteam] 