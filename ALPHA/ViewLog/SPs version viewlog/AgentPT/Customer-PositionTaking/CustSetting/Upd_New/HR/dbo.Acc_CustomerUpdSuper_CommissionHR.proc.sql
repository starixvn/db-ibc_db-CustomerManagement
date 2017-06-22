ALTER PROCEDURE [dbo].[Acc_CustomerUpdSuper_CommissionHR]
	@custid int,-- superid
	@v151discount_31 decimal(9,8),--commission for tote.
	@v151discount_41 decimal(9,8),--commission for FO.	
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*
Created: 20081023@VinhTruong
Task : Update Super's commission for Horseracing.
DB: DB02.bodb02

Revisions:
	- 20090515@Phuc: commission for tote and fixed odds.
	- 20090917@Phuc: write log into DBLOG.
	- 20091201@Kiwi: Move custsetting to the separated table CustSetting3rd.
	- 20100112@Kiwi: Amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON


if @v151discount_31 <0 or @v151discount_31 > 0.01
BEGIN	
	Select @ErrMsg = 	case @Language 
						when 'E' then 'Wrong discount (Tote).'
						when 'CS' then N'佣金折扣错误（体彩）.'
						when 'CT' then N'佣金折扣錯誤（體彩）.'
						when 'TH' then N'การให้ส่วนลดไม่ถูกต้อง (Tote).'
						when 'J' then N'Wrong discount (Tote).'
						when 'KO' then N'잘못된 수수료 (Tote).'
						else N'Wrong discount (Tote).'
				end, @ErrCode = 101
	return
END
if @v151discount_41 <0 or @v151discount_41 > 0.01
BEGIN	
	Select @ErrMsg = 	case @Language 
						when 'E' then 'Wrong discount (Fixed Odds).'
						when 'CS' then N'佣金折扣错误（固定赔率）.'
						when 'CT' then N'佣金折扣錯誤（固定賠率）.'
						when 'TH' then N'การให้ส่วนลดไม่ถูกต้อง (Fixed Odds).'
						when 'J' then N'Wrong discount (Fixed Odds).'
						when 'KO' then N'잘못된 수수료 (Fixed Odds).'
						else N'Wrong discount (Fixed Odds).'
				end, @ErrCode = 101
	return
END

DECLARE @db_v151discount_31 decimal(9,8) , @db_v151discount_41 decimal(9,8)

SELECT @db_v151discount_31 =  sdiscount FROM CustSetting3rd with (NOLOCK) WHERE custid = @custid and bettype = 31 and sporttype = 151
SELECT @db_v151discount_41 =  sdiscount FROM CustSetting3rd with (NOLOCK) WHERE custid = @custid and bettype = 41 and sporttype = 151

-- Check whether user updates or not - RETURN if not change commission
IF @db_v151discount_31 = @v151discount_31 and @db_v151discount_41 = @v151discount_41 
	RETURN 

---------------------------------------------------
--Update @Super: g4, s4
update CustSetting3rd with (ROWLOCK, UPDLOCK)
set
	sdiscount = case when bettype in (31,32) then @v151discount_31 when bettype in (41,42) then @v151discount_41 else sdiscount end
where custid=@custid and sporttype = 151

if (@@error <> 0)
begin	
	Select @ErrMsg = case @Language 
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
--Update commission (tote).
IF @db_v151discount_31 <> @v151discount_31
BEGIN
	---------------------------------------------------
	--Update g3=g4 if g3>g4 

	UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
	SET adiscount = case when cs.adiscount>@v151discount_31 then @v151discount_31 else adiscount end
	From CustSetting3rd as cs inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 3 and cs.bettype in(31,32) and cs.sporttype = 151
	if (@@error <> 0)
	begin
		ROLLBACK TRANSACTION
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end	, @ErrCode = 103
		return
	end

	---------------------------------------------------
	--Update g2=g4 if g2>g4
	UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
	SET discount = case when cs.discount > @v151discount_31  then  @v151discount_31 else discount end 
	From CustSetting3rd as cs inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 2 and cs.bettype in(31,32) and cs.sporttype = 151
	if (@@error <> 0)
	begin
		ROLLBACK TRANSACTION
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end	, @ErrCode = 111
		return
	end

	---------------------------------------------------


	--Update g4 at Member level
	UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
	SET sdiscount = @v151discount_31
	From CustSetting3rd as cs inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 1 and cs.bettype in(31,32) and cs.sporttype = 151
	if (@@error <> 0)
	begin
		ROLLBACK TRANSACTION
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end	, @ErrCode = 104	
		return
	end
END

IF @db_v151discount_41 <> @v151discount_41--(fixed odds) 
BEGIN
	
	---------------------------------------------------
	--Update m3=s4 if m3>s4
	UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
	SET adiscount = case when cs.adiscount>@v151discount_41 then @v151discount_41 else adiscount end 
	From CustSetting3rd as cs inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 3 and cs.bettype in (41,42) and cs.sporttype = 151 
	if (@@error <> 0)
	begin
		ROLLBACK TRANSACTION
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 106	
		return
	end

	---------------------------------------------------
	--Update a2=s4 if a2>s4
	UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
	SET	discount = case when cs.discount>@v151discount_41 then @v151discount_41 else discount end 
	From CustSetting3rd as cs inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 2 and cs.bettype in(41,42) and cs.sporttype = 151 
	if (@@error <> 0)
	begin
		ROLLBACK TRANSACTION
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 107	
		return
	end
	
	---------------------------------------------------
	--Update s4 to member level
	UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
	SET	 sdiscount = @v151discount_41
	From CustSetting3rd as cs inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 1 and cs.bettype in(41,42) and cs.sporttype = 151
	if (@@error <> 0)
	begin
		ROLLBACK TRANSACTION
		Select @ErrMsg = case @Language 
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
---------------------------------------------------
--At member level, update adiscount = sdiscount  if adiscount > sdiscount
UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
SET adiscount = case when cs.adiscount>cs.sdiscount then cs.sdiscount else adiscount end 
From CustSetting3rd as cs inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
WHERE c.srecommend = @custid AND c.roleid = 1 and sporttype = 151
--and cs.adiscount>cs.sdiscount
if (@@error <> 0)
begin
	ROLLBACK TRANSACTION
	Select @ErrMsg = case @Language 
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

---------------------------------------------------
--At member level, update discount = adiscount  if discount > adiscount
UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
SET    discount = case when cs.discount>cs.adiscount then adiscount else discount end 
From CustSetting3rd as cs inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
WHERE c.srecommend = @custid AND c.roleid = 1 and sporttype = 151
--and cs.discount>cs.adiscount
if (@@error <> 0)
begin
	ROLLBACK TRANSACTION
	Select @ErrMsg = case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end, @ErrCode = 109	
	return
end

---------------------------------------------------
--At member level, update playerdiscount = discount  if playerdiscount > discount
UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
SET    playerdiscount = case when cs.playerdiscount>cs.discount then discount else playerdiscount end 
From CustSetting3rd as cs inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
WHERE c.srecommend = @custid AND c.roleid = 1  and sporttype = 151
-- and cs.playerdiscount>cs.discount
if (@@error <> 0)
begin
	ROLLBACK TRANSACTION
	Select @ErrMsg = case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end, @ErrCode = 110	
	return
end

Declare @LogSPData varchar(5000)
Select @LogSPData = '<Acc_CustomerUpdSuper_CommissionHR custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'v151discount_31="'+ coalesce(cast(@v151discount_31 as varchar(50)),space(1)) + '" ' +
'v151discount_41="'+ coalesce(cast(@v151discount_41 as varchar(50)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />'

--Log customer info 
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 209,
	@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSuper_CommissionHR] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdSuper_CommissionHR] TO [vnteam]