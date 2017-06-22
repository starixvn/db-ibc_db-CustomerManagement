ALTER PROCEDURE [dbo].[Acc_CustomerUpdMinMaxBetFI]
	@custid int,
	@roleid tinyint,	
	--v201	
	@minbetv201 money = 0,
	@maxbetv201 money = 0,
	@maxpermatchv201 money = 0,
	
	@SubAccID int = 0, --Sub-AccountID		
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
--@Source Control
/*
Created: 20090415@Phuc
Task : Update Agent FI's MinBet, MaxBet, MaxPerMatch 
DB: DB02.bodb02

Revisions:
	- 20090723@Phuc: Write log subaccname instead of subaccid.
	- 20090917@Phuc: write log into DBLOG.
	- 20091201@Kiwi: Move custsetting to the separated table CustSetting3rd.
	- 20100112@Kiwi: amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON

Declare 
	@MinMinBetv201 money, @MaxMaxBetv201 money, @MaxMaxPerMatchv201 money
	
declare @ErrAcc varchar(4000), @ErrType varchar(4000),
		@UserName varchar(30), @srecommend int, @mrecommend int, @recommend int
		
		
Select @UserName = username, 
	@recommend = case when @roleid = 1 then recommend else 0 end,
	@mrecommend = case when @roleid = 2 then mrecommend else 0 end,
	@srecommend = case when @roleid = 3 then srecommend else 0 end
from customer with (NOLOCK)
where CustID = @CustID and roleid = @roleid

if @MinBetv201 <0
	or @MaxBetv201 <0
	or @MaxPerMatchv201 <0
BEGIN
	select @ErrCode = 3
	Select @ErrMsg = 	case @Language 
						when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Finance).'
						when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于金融).'
						when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於金融).'
						when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับการเงิน).'
						when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Finance).'
						when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (금융).'
						else N'Wrong Min bet/ Max bet/ Max per match (for Finance).'
				end
	return
END

Select @MinMinBetv201 = 0, @MaxMaxBetv201 = 0

if @roleid = 1
begin
	Select 
		@MinMinBetv201 = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxMaxBetv201 = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		CustSetting3rd as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 3 and cs.sporttype=201
	where ci.custid = @recommend
	
	Select 
		--v201
		@MaxMaxPerMatchv201 = Min(case when cs.MaxPerMatch201 = 0 then NULL else cs.MaxPerMatch201 end)
	from 
		custinfo as cs WITH (NOLOCK) 
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
	where ci.custid = @recommend
end
if @roleid = 2 
begin
	Select 
		@MinMinBetv201 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
		@MaxMaxBetv201 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
	from 
		CustSetting3rd as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 3 and cs.sporttype=201
	where ci.custid = @MRecommend

	Select	
		--v201
		@MaxMaxPerMatchv201 = isnull(Min(case when cs.MaxPerMatch201 = 0 then NULL else cs.MaxPerMatch201 end),0)
	from 
		custinfo as cs WITH (NOLOCK) 
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
	where ci.custid = @CustID
end
if @roleid = 3
begin
	Select 
		@MinMinBetv201 = MinBet,
		@MaxMaxBetv201 = MaxBet
	From CustSetting3rd with (NOLOCK)
	where CustID = @srecommend and bettype=3 and sporttype=201
	Select @MaxMaxPerMatchv201 = MaxPerMatch201
	from custinfo with (NOLOCK) where custid = @srecommend
end

if (@MinBetv201 <> 0 and @MaxBetv201 <> 0 and @MinBetv201>@MaxBetv201) or (@MaxBetv201 <> 0 and @MaxPerMatchv201 <> 0 and @MaxBetv201>@MaxPerMatchv201)
BEGIN
	SELECT @ErrMsg =	@UserName + ': '+
					case @Language 
						when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Finance)'
						when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于金融)'
						when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於金融)'
						when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับการเงิน).'
						when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Finance) '
						when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (금융) '
						else N'min bet must be less than max bet and max bet must be less than max bet per match (for Finance) '
					end						
					+ char(13) + char(10) + convert(varchar(20), @MinBetv201) + '-' + convert(varchar(20), @MaxBetv201) + '-' + convert(varchar(20), @MaxPerMatchv201), @ErrCode = 112					 
	return
END

if (@MinMinBetv201>0 and @MinBetv201>0 and @MinBetv201<@MinMinBetv201)
BEGIN
	SELECT @ErrMsg =	@UserName + ': '+
					case @Language 
						when 'E' then 'min bet must be equal to or greater than Master Agent min bet (for Finance)'
						when 'CS' then N'最低投注需相等于或少于总代理最低投注(于金融)'
						when 'CT' then N'最低投注需相等於或少於總代理最低投注(於金融)'
						when 'TH' then N'จำนวนเงินขั้นต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำที่ในการเล่นที่กำหนดไว้ของตัวแทนหลัก (สำหรับกีฬารถแข่ง)).'
						when 'J' then N'min bet must be equal to or greater than Master Agent min bet (for Finance)'
						when 'KO' then N'최소 배팅은 마스터 에이전트 최소 배팅 이상이여야 합니다 (금융)'
						else N'min bet must be equal to or greater than Master Agent min bet (for Finance)'
					end						
					+' (' + convert(varchar(20), @MinMinBetv201) + ').', @ErrCode = 113					 
	
	return
END

if (@MaxMaxBetv201>0 and @MaxBetv201>0 and @MaxBetv201>@MaxMaxBetv201)
BEGIN
	SELECT @ErrMsg =	@UserName + ': '+
					case @Language 
						when 'E' then 'max bet must be equal to or less than Master Agent max bet (for Finance)'
						when 'CS' then N'最高投注需相等于或少于总代理最高投注(于金融)'
						when 'CT' then N'最高投注需相等於或少於總代理最高投注(於金融)'
						when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนหลัก (สำหรับการเงิน).'
						when 'J' then N'max bet must be equal to or less than Master Agent max bet (for Finance)'
						when 'KO' then N'초대 배팅은 마스터 에이전트의 최대 배팅 이하여야 합니다 (금융)'
						else N'max bet must be equal to or less than Master Agent max bet (for Finance)'
					end						
					+' (' + convert(varchar(20), @MaxMaxBetv201) + ').', @ErrCode = 114					 
	
	return
END
if (@MaxMaxPerMatchv201>0 and @MaxPerMatchv201>0 and @MaxPerMatchv201>@MaxMaxPerMatchv201)
BEGIN
	SELECT @ErrMsg =	@UserName + ': '+
					case @Language 
						when 'E' then 'Max Per Match must be equal to or less than Master Agent Max Per Match (for Finance)'
						when 'CS' then N'单场最高投注需相等于或少于总代理单场最高投注(于金融)'
						when 'CT' then N'單場最高投注需相等於或少於總代理單場最高投注(於金融)'
						when 'TH' then N'จำนวนเงินในการเล่นสูงสุดต่อรายการต้องเท่ากับ หรือน้อยกว่า จำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนหลักต่อเกมการแข่งขัน (สำหรับการเงิน).'
						when 'J' then N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Finance)'
						when 'KO' then N'최대 경기는 마스터 에이전트 최대 경기보다 자아야 합니다 (금융)'
						else N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Finance)'
					end						
					+' (' + convert(varchar(20), @MaxMaxPerMatchv201) + ').', @ErrCode = 114					 
	
	return
END
---------------------------------------------------------------
update CustSetting3rd with (ROWLOCK, UPDLOCK)
set
	MinBet = @MinBetv201,																																																																																																																																																		
	MaxBet = @MaxBetv201 
where custid=@custid and sporttype = 201 

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
					end, @ErrCode = 115	
	return
end

update custinfo with (ROWLOCK, UPDLOCK)
set MaxPerMatch201 = @MaxPerMatchv201
where custid = @custid

if (@@error <> 0)
begin
	Select @ErrMsg = case @Language 
						when 'E' then 'Update process is unsuccessful!'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end, @ErrCode = 115
	return
end

Declare @LogSPData varchar(5000)
Select @LogSPData ='<Acc_CustomerUpdMinMaxBetFI custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'MinBv201="'+ coalesce(cast(@minbetv201 as varchar(50)),space(1)) + '" ' +
'MaxBv201="'+ coalesce(cast(@maxbetv201 as varchar(50)),space(1)) + '" ' +
'MPMv201="'+ coalesce(cast(@maxpermatchv201 as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 308,
	@TrackingValue = @LogSPData

---------------------------------------------------------

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMinMaxBetFI] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMinMaxBetFI] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMinMaxBetFI] TO vnteam