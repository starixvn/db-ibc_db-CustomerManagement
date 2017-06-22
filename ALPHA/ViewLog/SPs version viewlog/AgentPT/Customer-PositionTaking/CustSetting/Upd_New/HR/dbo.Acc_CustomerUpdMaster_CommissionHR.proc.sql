ALTER PROCEDURE [dbo].[Acc_CustomerUpdMaster_CommissionHR]
	@custid int,-- masterId
	@v151discount_31 decimal(9,8),--commission for tote.
	@v151discount_41 decimal(9,8),--commission for FO.
	@SubAccID int = 0, --Sub-AccountID
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20081023@VinhTruong
Task : Update Master's commission for Horseracing
DB: DB02.bodb02

Revisions:
	- 20090515@Phuc: commission for tote and fixed odds.
					Write log subaccname instead of subaccid.
	- 20090917@Phuc: write log into DBLOG.
	- 20091201@Kiwi: Move custsetting to the separated table CustSetting3rd.
	- 20100112@Kiwi: amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON

--Check Param
if @v151discount_31 < 0 or @v151discount_31 > 0.01
BEGIN		
	Select @ErrMsg = 	case @Language 
						when 'E' then 'Wrong discount (Tote).'
						when 'CS' then N'佣金折扣错误（体彩）.'
						when 'CT' then N'佣金折扣錯誤（體彩）.'
						when 'TH' then N'ผู้ใช้ไม่ถูกต้อง (Tote).'
						when 'J' then N'Wrong discount (Tote).'
						when 'KO' then N'잘못된 수수료 (Tote).'
						else N'Wrong discount (Tote).'
				end, @ErrCode = 101
	return
END
if @v151discount_41 < 0	or @v151discount_41 > 0.01
BEGIN		
	Select @ErrMsg = 	case @Language 
						when 'E' then 'Wrong discount (Fixed Odds).'
						when 'CS' then N'佣金折扣错误（固定赔率）.'
						when 'CT' then N'佣金折扣錯誤（固定賠率）.'
						when 'TH' then N'ผู้ใช้ไม่ถูกต้อง (Fixed Odds).'
						when 'J' then N'Wrong discount (Fixed Odds).'
						when 'KO' then N'잘못된 수수료 (Fixed Odds).'
						else N'Wrong discount (Fixed Odds).'
				end, @ErrCode = 101
	return
END

---------------------------------------
Declare @srecommend int, @username varchar(40), 
	@db_v151discount_31 decimal(9,8), @db_v151discount_41 decimal(9,8)
select @username = username,
	@srecommend = srecommend
from custinfo with (nolock)
where custid = @custid and roleid = 3

SELECT @db_v151discount_31 = adiscount	FROM CustSetting3rd with (NOLOCK) WHERE custid = @custid AND bettype = 31
SELECT @db_v151discount_41 = adiscount	FROM CustSetting3rd with (NOLOCK) WHERE custid = @custid AND bettype = 41

-- Check whether user edits commission or not - If not - RETURN 
--20090305: Thien comment out the make sure the commission is updated correctly
--IF @db_UKComm = @UKComm and @db_OtherComm = @OtherComm 
--	RETURN 

---------------------------------------

---------------------------------------
	IF @db_v151discount_31 <> @v151discount_31
	BEGIN
		--Get g3=g4 if g3>g4
		Select @v151discount_31 = case when @v151discount_31 >sdiscount then sdiscount else @v151discount_31 end
		from CustSetting3rd as cs with (nolock) 
		where custid = @srecommend and bettype=31 and sporttype = 151
		--Update @Master: g3, m3
		update CustSetting3rd with (ROWLOCK, UPDLOCK)
		set    adiscount = @v151discount_31
		where custid=@custid and bettype in(31,32) and sporttype = 151
		if (@@error <> 0)
		begin
		
			Select @ErrMsg = @UserName + ': '+
							case @Language 
								when 'E' then 'Update process is unsuccessful !'
								when 'CS' then N'更新程序不成功 !'
								when 'CT' then N'更新程序不成功 !'
								when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
								when 'J' then N'アップデート出来ません。'
								when 'KO' then N'업데이트에 실패했습니다.'
								else N'Update process is unsuccessful !'
							end	, @ErrCode = 102
			return
		end
		---------------------------------------
		--Update g2 = g3 if g2>g3 at agent
		UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
		SET    discount = @v151discount_31 
		From CustSetting3rd as cs
		inner join custinfo as ci with (NOLOCK) on cs.custid = ci.custid
		WHERE ci.mrecommend = @custid AND ci.roleid = 2 and cs.bettype in(31,32) and cs.sporttype = 151 and discount> @v151discount_31
		if (@@error <> 0)
		begin
			
			Select @ErrMsg = @UserName + ': '+
							case @Language 
								when 'E' then 'Update process is unsuccessful !'
								when 'CS' then N'更新程序不成功 !'
								when 'CT' then N'更新程序不成功 !'
								when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
								when 'J' then N'アップデート出来ません。'
								when 'KO' then N'업데이트에 실패했습니다.'
								else N'Update process is unsuccessful !'
							end, @ErrCode = 103					 
			
			return
		end

		---------------------------------------
		--Update g3 @ member level
		UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
		SET adiscount = @v151discount_31
		From CustSetting3rd as cs
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		WHERE c.mrecommend = @custid AND c.roleid = 1 and cs.bettype in(31,32) and cs.sporttype = 151
		if (@@error <> 0)
		begin
			
			Select @ErrMsg = @UserName + ': '+
							case @Language 
								when 'E' then 'Update process is unsuccessful !'
								when 'CS' then N'更新程序不成功 !'
								when 'CT' then N'更新程序不成功 !'
								when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
								when 'J' then N'アップデート出来ません。'
								when 'KO' then N'업데이트에 실패했습니다.'
								else N'Update process is unsuccessful !'
							end, @ErrCode = 105	
			
			return
		end
	END 

	IF @db_v151discount_41 <> @v151discount_41 
	BEGIN 
		--Get m3=s4 if m3>s4
		Select @v151discount_41 = case when @v151discount_41 > sdiscount then sdiscount else @v151discount_41 end 
		from CustSetting3rd as cs with (nolock) 
		where custid = @srecommend and bettype = 41 and sporttype = 151 
		
		--Update @Master: g3, m3
		update CustSetting3rd with (ROWLOCK, UPDLOCK)
		set    adiscount = @v151discount_41 
		where custid=@custid and bettype in(41,42) and sporttype = 151 
		if (@@error <> 0)
		begin
			
			Select @ErrMsg = @UserName + ': '+
							case @Language 
								when 'E' then 'Update process is unsuccessful !'
								when 'CS' then N'更新程序不成功 !'
								when 'CT' then N'更新程序不成功 !'
								when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
								when 'J' then N'アップデート出来ません。'
								when 'KO' then N'업데이트에 실패했습니다.'
								else N'Update process is unsuccessful !'
							end	, @ErrCode = 109
			return
		end
		---------------------------------------
		--Update a2 = m3 if a2>m3 at agent
		UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
		SET    discount = @v151discount_41
		From CustSetting3rd as cs
		inner join custinfo as ci with (NOLOCK) on cs.custid = ci.custid
		WHERE ci.mrecommend = @custid AND ci.roleid = 2 and cs.bettype in(41,42) and cs.sporttype = 151 and discount>@v151discount_41
		if (@@error <> 0)
		begin
			
			Select @ErrMsg = @UserName + ': '+
							case @Language 
								when 'E' then 'Update process is unsuccessful !'
								when 'CS' then N'更新程序不成功 !'
								when 'CT' then N'更新程序不成功 !'
								when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
								when 'J' then N'アップデート出来ません。'
								when 'KO' then N'업데이트에 실패했습니다.'
								else N'Update process is unsuccessful !'
							end, @ErrCode = 104				 
			
			return
		end
		
		
		
		---------------------------------------
		--Update m3 @ member level
		UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
		SET    adiscount = @v151discount_41
		From CustSetting3rd as cs
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		WHERE c.mrecommend = @custid AND c.roleid = 1 and cs.bettype in(41,42) and cs.sporttype = 151
		if (@@error <> 0)
		begin
			
			Select @ErrMsg = @UserName + ': '+
							case @Language 
								when 'E' then 'Update process is unsuccessful !'
								when 'CS' then N'更新程序不成功 !'
								when 'CT' then N'更新程序不成功 !'
								when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
								when 'J' then N'アップデート出来ません。'
								when 'KO' then N'업데이트에 실패했습니다.'
								else N'Update process is unsuccessful !'
							end	, @ErrCode = 106
			return
		end
	END 
	---------------------------------------
	--At member level, update discount = adiscount  if discount > adiscount
	UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
	SET 	
		discount = adiscount
	From CustSetting3rd as cs
	inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.mrecommend = @custid AND c.roleid = 1 and cs.discount>cs.adiscount and sporttype = 151
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = @UserName + ': '+
						case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end	, @ErrCode = 107
		return
	end

	---------------------------------------
	--At member level, update playerdiscount = discount  if playerdiscount > discount
	UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
	SET 	
		playerdiscount = discount
	From CustSetting3rd as cs
	inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.mrecommend = @custid AND c.roleid = 1 and cs.playerdiscount>cs.discount and sporttype = 151
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = @UserName + ': '+
						case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 108
		return
	end


Declare @LogSPData varchar(3000)
Select @LogSPData = '<Acc_CustomerUpdMaster_CommissionHR custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'v151discount_31="'+ coalesce(cast(@v151discount_31 as varchar(50)),space(1)) + '" ' +
'v151discount_41="'+ coalesce(cast(@v151discount_41 as varchar(50)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />'

--Log customer info 
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 210,
	@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaster_CommissionHR] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaster_CommissionHR] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMaster_CommissionHR] TO [vnteam]

