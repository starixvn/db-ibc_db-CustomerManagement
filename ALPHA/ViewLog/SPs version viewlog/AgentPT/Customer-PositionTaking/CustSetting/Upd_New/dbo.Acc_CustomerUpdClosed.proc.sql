ALTER PROCEDURE [dbo].[Acc_CustomerUpdClosed]
	@CustID int,
	@Closed bit,	
	@SubAccID int = 0, --Sub-AccountID
	@UserID int,
	@disCasino bit =0,
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IP varchar(15)=''
AS
/*
Created: 20080911@whoknow
Task : Update status 'closed' for customer
DB: DB02.bodb02
Original:

Revisions:
    - 20090314@HanhVu: add Korean language
    - 20090801@Shifu: check disabled user
	- 20090917@Phuc: write log into DBLOG.
	- 20090308@Phuc: check if @old_closed=@closed and @logincount > 5(closed by over 5 times attempt login with wrong password)=> do nothing
					Write log subaccname instead of subaccid.
	- 20090407@HanhVu: update logincount in case member got closed by entering wrong pass.
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)	

	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20091125@Terry : add one more para @disCasino check disabled Casino
	- 20100102@Lewin : modify LogSP Data, call WriteLog_UserLog_RunSPNew instead of WriteLog_UserLog_RunSP 
Param's Explanation:
• @custid: custid that need to be viewed.   

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
								when 'E' then 'This CLOSED function is temporarily unavailable, please update later.'
								when 'CS' then N'This CLOSED function is temporarily unavailable, please update later.'
								when 'CT' then N'This CLOSED function is temporarily unavailable, please update later.'
								when 'TH' then N'This CLOSED function is temporarily unavailable, please update later.'
								when 'J' then N'This CLOSED function is temporarily unavailable, please update later.'
								when 'KO' then N'This CLOSED function is temporarily unavailable, please update later.'
								else N'This CLOSED function is temporarily unavailable, please update later.'
							end	,
				@ErrCode = 106
				return
		END
END
---------------------------

Declare @roleid tinyint, @LoginCount int, @Old_Closed bit, @UplineClosed bit, @srecommend int, @mrecommend int, @recommend int 
select @roleid = roleid, @LoginCount = logincount
from customer with (nolock)
where custid = @custid

select @Old_Closed = closed,
	@srecommend = srecommend,
	@mrecommend = mrecommend,
	@recommend = recommend
from custinfo with (nolock)
where custid = @custid

IF @Old_Closed = @Closed and @LoginCount > 5
	return

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

IF @roleid = 1
	Select @UplineClosed = isnull(closed,0)
	from Custinfo with (nolock) where custid = @recommend 
ELSE IF @roleid = 2
	Select @UplineClosed = isnull(closed,0)
	from Custinfo with (nolock) where custid = @mrecommend 
ELSE IF @roleid = 3
	Select @UplineClosed = isnull(closed,0)
	from Custinfo with (nolock) where custid = @srecommend 
ELSE IF @roleid = 4
	Select @UplineClosed = 0
	
IF @UplineClosed = 1 AND @Old_Closed <> @Closed
BEGIN
	SELECT @ErrMsg =  CASE @Language 
							WHEN 'E' THEN 'This user''s upline was closed. Cannot edit.'
							WHEN 'CS' THEN N'This user''s upline was closed. Cannot edit.'
							WHEN 'CT' THEN N'This user''s upline was closed. Cannot edit.'
							WHEN 'TH' THEN N'This user''s upline was closed. Cannot edit.'
							WHEN 'J' THEN N'This user''s upline was closed. Cannot edit.'
							ELSE N'This user''s upline was closed. Cannot edit.'
						END, @ErrCode = 105
	return
END


BEGIN TRANSACTION

update custinfo with (ROWLOCK, UPDLOCK) set Closed = @Closed
where custid = @custid

IF (@Old_Closed = 1 and @Closed = 0 and @LoginCount > 5) or (@Old_Closed = 1 and @Closed = 0 and @roleid = 1 and @logincount = 5)
	update customer with (ROWLOCK, UPDLOCK) set logincount = 0
	where custid = @custid 

if (@@error <> 0)
begin
	ROLLBACK TRANSACTION
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

if @closed = 1 and @roleid = 4
begin
	update custinfo with (ROWLOCK, UPDLOCK) set closed = @closed where srecommend = @custid
	if (@@error <> 0)
	begin
		ROLLBACK TRANSACTION
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

if @closed = 1 and @roleid = 3
begin
	update custinfo with (ROWLOCK, UPDLOCK) set closed = @closed where mrecommend = @custid
	if (@@error <> 0)
	begin
		ROLLBACK TRANSACTION
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

if @closed = 1 and @roleid = 2
begin
	update custinfo with (ROWLOCK, UPDLOCK) set closed = @closed where recommend = @custid
	if (@@error <> 0)
	begin
		ROLLBACK TRANSACTION
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

COMMIT TRANSACTION

declare @LogSPData varchar(2000)

Select @LogSPData = '<Acc_CustomerUpdClosed CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" ' +
					'Closed="'+ coalesce(cast(@Closed as varchar(50)),space(1)) + '" ' +
					'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
					'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" ' +
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
					'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" ' +
					'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

/* 1105	Acc_CustomerUpdClosed	Update Closed status  */

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 1105,
	@TrackingValue = @LogSPData	

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdClosed] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdClosed] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdClosed] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdClosed] TO [vnteam]