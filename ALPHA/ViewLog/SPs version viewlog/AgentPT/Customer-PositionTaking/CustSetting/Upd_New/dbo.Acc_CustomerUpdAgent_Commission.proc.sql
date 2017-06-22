ALTER PROCEDURE [dbo].[Acc_CustomerUpdAgent_Commission]
	@custid int,-- AgentId
	@groupa decimal(9,8),
	@groupb decimal(9,8),
	@groupc decimal(9,8),
	@groupd decimal(9,8),
	@discountcs decimal(9,8),
	@discount1x2 decimal(9,8)=0,
	@updatecomm_old bit = 1,
	@SubAccID int = 0, --Sub-AccountID
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20080514@Thien
Task : Update Agent's Commission
DB: DB02.bodb02
Original:

Revisions:
    - 20090314@HanhVu: add Korean language
    - 20090424@Phuc:Separate finance sporttype(201).
					Write log subaccname instead of subaccid.
    - 20090514@PhuongDao: Add 1x2 Commission  
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Kiwi: amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Update commission successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON


--Check Param
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
						when 'KO' then N'잘못된 수수료.'
						else N'Wrong discount.'
				end, @ErrCode = 101
	return
END

---------------------------------------
Declare @username varchar(40), @mrecommend int
Select @UserName  = username, @mrecommend = mrecommend
from customer with (NOLOCK) where CustID = @CustID

if @updatecomm_old = 1
begin

	--Get g2=g3 if g2>g3
	Select 
		@groupa = case when @groupa>groupa then groupa else @groupa end, 
		@groupb = case when @groupb>groupb then groupb else @groupb end, 
		@groupc = case when @groupc>groupc then groupc else @groupc end, 
		@groupd = case when @groupd>groupd then groupd else @groupd end
	from custsetting as cs with (nolock) 
	where custid = @mrecommend and bettype=1 and sporttype=1

	--Get a2=m3 if a2>m3
	Select 	
		@discountcs = case when @discountcs > adiscount then adiscount else @discountcs end
	from custsetting as cs with (nolock) 
	where custid = @mrecommend and sporttype = 1 and bettype = 4

	---------------------------------------
	--Get a2=m3 if a2>m3  - 1x2 
	Select 	
		@discount1x2 = case when @discount1x2 > adiscount then adiscount else @discount1x2 end
	from custsetting as cs with (nolock) 
	where custid = @mrecommend and sporttype = 1 and bettype = 5
	---------------------------------------
	--Update @Master: g2, a2
	update custsetting with (ROWLOCK, UPDLOCK)
	set
		groupa = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupa else groupa end,
		groupb = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupb else groupb end,
		groupc = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupc else groupc end,
		groupd = case when bettype in (1,2,3,7,8) and sporttype <> 201 then @groupd else groupd end,
		discount = case when bettype in (4,6,9,10,20,21,22) then @discountcs when bettype =5 then @discount1x2 else discount end
	where custid=@custid
	
	if (@@error <> 0)
	begin
		Select @ErrMsg = @UserName + ': '+
						case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 102
		return
	end

	---------------------------------------
	--Update g2, a2 at Member level
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	custsetting.discount = case when customer.ugroup in ('a','hka') then @groupa 
										when customer.ugroup in ('b','hkb') then @groupb 
										when customer.ugroup in ('c','hkc') then @groupc 
										when customer.ugroup in ('d','hkd') then @groupd 
										else @groupa 
									end  
	From custsetting inner join customer with (NOLOCK) on custsetting.custid = customer.custid
	WHERE customer.recommend = @custid AND customer.roleid = 1 and bettype in (1,2,3,7,8) and sporttype <> 201
	
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	custsetting.discount = @discountcs
	From custsetting inner join customer with (NOLOCK) on custsetting.custid = customer.custid
	WHERE customer.recommend = @custid AND customer.roleid = 1 and bettype in (4,6,9,10,20,21,22)
	if (@@error <> 0)
	begin
		Select @ErrMsg = @UserName + ': '+
							case @Language 
								when 'E' then 'Update process is unsuccessful !'
								when 'CS' then N'更新程序不成功 !'
								when 'CT' then N'更新程序不成功 !'
								when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
								when 'J' then N'アップデート出来ません。'
								when 'KO' then N'업데이트에 실패했습니다.'
								else N'Update process is unsuccessful !'
							end, @ErrCode = 103
		return
	end

	--1x2 
	UPDATE custsetting with (ROWLOCK, UPDLOCK) 
	SET 	custsetting.discount = @discount1x2
	From custsetting inner join customer with (NOLOCK) on custsetting.custid = customer.custid
	WHERE customer.recommend = @custid AND customer.roleid = 1 and bettype = 5
	if (@@error <> 0)
	begin
		Select @ErrMsg = @UserName + ': '+
							case @Language 
								when 'E' then 'Update process is unsuccessful !'
								when 'CS' then N'更新程序不成功 !'
								when 'CT' then N'更新程序不成功 !'
								when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
								when 'J' then N'アップデート出来ません。'
								when 'KO' then N'업데이트에 실패했습니다.'
								else N'Update process is unsuccessful !'
							end, @ErrCode = 105
		return
	end
	---------------------------------------
	--At member level, update playerdiscount = discount  if playerdiscount > discount
	UPDATE custsetting with (ROWLOCK, UPDLOCK)
	SET
		custsetting.playerdiscount = custsetting.discount 
	From custsetting inner join customer as c with (nolock) on custsetting.custid = c.custid
	WHERE c.recommend = @custid AND c.roleid = 1 AND custsetting.playerdiscount > custsetting.discount
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = @UserName + ': '+
						case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 104
		return
	end
end

Declare @LogSPData varchar(5000)
Select @LogSPData = '<Acc_CustomerUpdAgent_Commission custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'groupa="'+ coalesce(cast(@groupa as varchar(50)),space(1)) + '" ' +
'groupb="'+ coalesce(cast(@groupb as varchar(50)),space(1)) + '" ' +
'groupc="'+ coalesce(cast(@groupc as varchar(50)),space(1)) + '" ' +
'groupd="'+ coalesce(cast(@groupd as varchar(50)),space(1)) + '" ' +
'discountcs="'+ coalesce(cast(@discountcs as varchar(50)),space(1)) + '" ' +
'discount1x2="'+ coalesce(cast(@discount1x2 as varchar(50)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1))+ '" />'

--Log customer info 
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 206,
	@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgent_Commission] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgent_Commission] TO [bodbDownlineNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdAgent_Commission] TO vnteam 

