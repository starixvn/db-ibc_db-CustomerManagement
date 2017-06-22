ALTER PROCEDURE [dbo].[Acc_CustomerUpdSuper_Commission]
	@custid int,-- superid
	
	@groupa decimal(9,8),
	@groupb decimal(9,8),
	@groupc decimal(9,8),
	@groupd decimal(9,8),
	@discountcs decimal(9,8),	
	@discount1x2 decimal(9,8)=0,
	@updatecomm_old bit =1,
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20080514@Thien
Task : Update Super's Commission
DB: DB02.bodb02
Original:[Acc_CustomerUpdSuper_Commission]

Revisions:
    - 20090424@Phuc:Separate finance sporttype(201).
    - 20090514@PhuongDao: Add 1x2 Commission
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Kiwi: amend to write log in xml format.

Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON


if 
	@discountcs<0 or @discountcs>0.2
		or @discount1x2<0 or @discount1x2>0.2
		or @groupa<0 or @groupa>0.2
		or @groupb<0 or @groupb>0.2
		or @groupc<0 or @groupc>0.2
		or @groupd<0 or @groupd>0.2
BEGIN	
	Select @ErrMsg = 	case @Language 
						when 'E' then 'Wrong discount.'
						when 'CS' then N'折扣不正确.'
						when 'CT' then N'折扣不正確.'
						when 'TH' then N'การให้ส่วนลดไม่ถูกต้อง.'
						when 'J' then N'Wrong discount.'
						else N'Wrong discount.'
				end, @ErrCode = 101
	return
END

--Check modify group(other) or financial
if @updatecomm_old = 1
begin
	---------------------------------------------------
	--Update @Super: g4, s4
	update custsetting with (ROWLOCK, UPDLOCK)
	set
		groupa = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupa else groupa end,
		groupb = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupb else groupb end,
		groupc = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupc else groupc end,
		groupd = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupd else groupd end,
		sdiscount = case when bettype in (4,6,9,10,20,21,22) then @discountcs when bettype = 5 then @discount1x2 else sdiscount end
	where custid = @custid 

	if (@@error <> 0)
	begin	
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							else N'Update process is unsuccessful !'
						end	, @ErrCode = 102
		return
	end
	
	---------------------------------------------------
	--Update g3=g4 if g3>g4
	--		 g2=g4 if g2>g4
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	
		groupa = @groupa 
	From custsetting inner join custinfo as ci with (NOLOCK) on custsetting.custid = ci.custid
	WHERE ci.srecommend = @custid AND ci.roleid in (2,3) 
		and custsetting.bettype in(1,2,3,7,8) and sporttype <> 201 and groupa>@groupa
	
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	
		groupb = @groupb 
	From custsetting inner join custinfo as ci with (NOLOCK) on custsetting.custid = ci.custid
	WHERE ci.srecommend = @custid AND ci.roleid in (2,3) 
		and custsetting.bettype in(1,2,3,7,8) and sporttype <> 201 and groupb>@groupb
	
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	
		groupc = @groupc 
	From custsetting inner join custinfo as ci with (NOLOCK) on custsetting.custid = ci.custid
	WHERE ci.srecommend = @custid AND ci.roleid in (2,3) 
		and custsetting.bettype in(1,2,3,7,8) and sporttype <> 201 and groupc>@groupc
	
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	
		groupd = @groupd 
	From custsetting inner join custinfo as ci with (NOLOCK) on custsetting.custid = ci.custid
	WHERE ci.srecommend = @custid AND ci.roleid in (2,3) 
		and custsetting.bettype in(1,2,3,7,8) and sporttype <> 201 and groupd>@groupd
		
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							else N'Update process is unsuccessful !'
						end	, @ErrCode = 103
		return
	end
	---------------------------------------------------
	--Update g4 to Member level
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	
		sdiscount = case when c.ugroup in ('a','hka') then @groupa 
						 when c.ugroup in ('b','hkb') then @groupb 
						 when c.ugroup in ('c','hkc') then @groupc 
						 when c.ugroup in ('d','hkd', 'e') then @groupd else @groupa end 
	From custsetting inner join customer as c with (NOLOCK) on custsetting.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 1 and custsetting.bettype in(1,2,3,7,8) and sporttype <> 201
	if (@@error <> 0) 
	begin
		
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							else N'Update process is unsuccessful !'
						end	, @ErrCode = 104	
		return
	end
	
	---------------------------------------------------
	--Update s4 to member level
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	
		sdiscount =  @discountcs 
	From custsetting inner join customer as c with (NOLOCK) on custsetting.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 1 and bettype in(4,6,9,10,20,21,22) 
	if (@@error <> 0)
	begin
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 105	
		return
	end
	
	---------------------------------------------------
	--Update s4 to member level --1x2
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	
		sdiscount =  @discount1x2 
	From custsetting inner join customer as c with (NOLOCK) on custsetting.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 1 and bettype = 5
	if (@@error <> 0)
	begin
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 105	
		return
	end
	---------------------------------------------------
	--Update m3=s4 if m3>s4
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	
		adiscount = @discountcs 
	From custsetting inner join custinfo as ci with (NOLOCK) on custsetting.custid = ci.custid
	WHERE ci.srecommend = @custid AND ci.roleid = 3 and bettype in(4,6,9,10,20,21,22) and adiscount>@discountcs 
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 106	
		return
	end
	
	---------------------------------------------------
	--Update m3=s4 if m3>s4  --1x2
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	
		adiscount = @discount1x2
	From custsetting inner join custinfo as ci with (NOLOCK) on custsetting.custid = ci.custid
	WHERE ci.srecommend = @custid AND ci.roleid = 3 and bettype = 5 and adiscount>@discount1x2 
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 106	
		return
	end
	---------------------------------------------------
	--Update a2=s4 if a2>s4
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	
		discount = @discountcs 
	From custsetting inner join custinfo as ci with (NOLOCK) on custsetting.custid = ci.custid
	WHERE ci.srecommend = @custid AND ci.roleid = 2  and bettype in(4,6,9,10,20,21,22) and discount>@discountcs
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 107	
		return
	end
	
	---------------------------------------------------
	--Update a2=s4 if a2>s4  --1x2
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	
		discount = @discount1x2
	From custsetting inner join custinfo as ci with (NOLOCK) on custsetting.custid = ci.custid
	WHERE ci.srecommend = @custid AND ci.roleid = 2  and bettype = 5 and discount>@discount1x2
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 107	
		return
	end

	---------------------------------------------------
	--At member level, update adiscount = sdiscount  if adiscount > sdiscount
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	
		adiscount = sdiscount
	From custsetting inner join customer as c with (NOLOCK) on custsetting.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 1 and custsetting.adiscount>custsetting.sdiscount
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 108
		return
	end

	---------------------------------------------------
	--At member level, update discount = adiscount  if discount > adiscount
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	
		discount = adiscount
	From custsetting inner join customer as c with (NOLOCK) on custsetting.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 1 and custsetting.discount>custsetting.adiscount
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 109	
		return
	end

	---------------------------------------------------
	--At member level, update playerdiscount = discount  if playerdiscount > discount
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	
		playerdiscount = discount
	From custsetting inner join customer as c with (NOLOCK) on custsetting.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 1 and custsetting.playerdiscount>custsetting.discount
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 110	
		return
	end
end			
--204	Acc_CustomerUpdSuper_Commission	Update Sportsbook Commission for super
Declare @LogSPData varchar(5000)
Select @LogSPData = '<Acc_CustomerUpdSuper_Commission custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'groupa="'+ coalesce(cast(@groupa as varchar(50)),space(1)) + '" ' +
'groupb="'+ coalesce(cast(@groupb as varchar(50)),space(1)) + '" ' +
'groupc="'+ coalesce(cast(@groupc as varchar(50)),space(1)) + '" ' +
'groupd="'+ coalesce(cast(@groupd as varchar(50)),space(1)) + '" ' +
'discountcs="'+ coalesce(cast(@discountcs as varchar(50)),space(1)) + '" ' +
'discount1x2="'+ coalesce(cast(@discount1x2 as varchar(50)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+ '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+ '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1))+ '" />'

--Log customer info 
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 204,
	@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSuper_Commission] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdSuper_Commission] TO vnteam