ALTER PROCEDURE [dbo].[Acc_CustomerUpdAgent_CommissionHR]
	@custid int,-- AgentId
	@v151discount_31 decimal(9,8),--Comm for tote
	@v151discount_41 decimal(9,8),--Comm for FO
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
						when 'TH' then N'การให้ส่วนลดไม่ถูกต้อง (Tote).'
						when 'J' then N'Wrong discount (Tote).'
						when 'KO' then N'잘못된 수수료(Tote)'
						else N'Wrong discount (Tote).'
				end, @ErrCode = 101
	return
END

if @v151discount_41 < 0 or @v151discount_41 > 0.01
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

---------------------------------------
Declare @username varchar(40), @mrecommend int , @db_v151discount_31 decimal(9,8), @db_v151discount_41 decimal(9,8)
Select @UserName  = username, @mrecommend = mrecommend
from customer with (NOLOCK) where CustID = @CustID
 
SELECT  @db_v151discount_31 = discount	FROM CustSetting3rd with (NOLOCK) WHERE custid = @custid and bettype = 31 and sporttype = 151
SELECT  @db_v151discount_41 = discount	FROM CustSetting3rd with (NOLOCK) WHERE custid = @custid and bettype = 41 and sporttype = 151

--20090305: Thien comment out the make sure the commission is updated correctly
--IF @db_UKComm = @UKComm and @db_OtherComm = @OtherComm
--	RETURN 
	
--Get g2=g3 if g2>g3
Select 
	@v151discount_31 = case when @v151discount_31 > adiscount then adiscount else @v151discount_31 end
from CustSetting3rd as cs with (nolock) 
where custid = @mrecommend and bettype = 31 and sporttype = 151
--Get a2=m3 if a2>m3
Select @v151discount_41 = case when @v151discount_41 > adiscount then adiscount else @v151discount_41 end 
from CustSetting3rd as cs with (nolock) 
where custid = @mrecommend and bettype = 41 and sporttype = 151 

---------------------------------------
---------------------------------------
--Update @Agent: g2, a2
update CustSetting3rd with (ROWLOCK, UPDLOCK)
set
	discount = case when bettype in(31,32) then @v151discount_31 when bettype in (41,42) then @v151discount_41 else discount end
where custid=@custid and sporttype = 151
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
UPDATE cs
	SET cs.discount = case when cs.bettype in(31,32) then @v151discount_31 when cs.bettype in (41,42) then @v151discount_41 else discount end 
From CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
WHERE c.recommend = @custid AND c.roleid = 1 and sporttype = 151
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

---------------------------------------
--At member level, update playerdiscount = discount  if playerdiscount > discount
UPDATE cs 
	SET cs.playerdiscount = cs.discount 
From CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
inner join custinfo as c with (nolock) on cs.custid = c.custid
WHERE c.recommend = @custid AND c.roleid = 1 AND sporttype = 151 AND cs.playerdiscount > cs.discount
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

Declare @LogSPData varchar(5000)
Select @LogSPData = '<Acc_CustomerUpdAgent_CommissionHR custid="'+ coalesce(cast(@custid as varchar(50)),space(1))+ '" ' +
'v151discount_31="'+ coalesce(cast(@v151discount_31 as varchar(50)),space(1))+ '" ' +
'v151discount_41="'+ coalesce(cast(@v151discount_41 as varchar(50)),space(1))+ '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1))+ '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1))+ '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+ '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+ '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1))+ '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />'

--Log customer info 
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 211,
	@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgent_CommissionHR] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgent_CommissionHR] TO [bodbDownlineNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdAgent_CommissionHR] TO [vnteam]