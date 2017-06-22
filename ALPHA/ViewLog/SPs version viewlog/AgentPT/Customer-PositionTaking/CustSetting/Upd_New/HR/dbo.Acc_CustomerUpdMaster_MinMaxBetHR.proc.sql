ALTER PROCEDURE [dbo].[Acc_CustomerUpdMaster_MinMaxBetHR]
	@custid int,-- masterid	
	@minbet money,
	@maxbet money,
	@maxpermatch money,
	@UpdateMultiple bit = 0,				
	@SubAccID int = 0, --Sub-AccountID		
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
/*
Created: 20081022@Vinh Truong
Task : Update master's minbet, maxbet, max per match for Horseracing
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
	@MinMinBet money, @MaxMaxBet money,	@MaxMaxPerMatch money
	
declare @UserName varchar(30), @srecommend int
		
Select @UserName = username, @srecommend = srecommend
from customer with (NOLOCK)
where CustID = @CustID and roleid = 3

if (@username = NULL) return

if @UpdateMultiple = 0
BEGIN
	if 
		@minbet<0
		or @maxbet < 0
		or @maxpermatch <0
	BEGIN	 
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match.'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确.'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確.'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง.'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match.'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대'
							else N'Wrong Min bet/ Max bet/ Max per match.'
					end, @ErrCode = 101
		return
	END
END

---------------------------------------------------------
if @UpdateMultiple = 0 
BEGIN
	if 
	(@minbet<>0 and @maxbet <> 0 and  @minbet>@maxbet) 
	or (@maxbet<> 0 and @maxpermatch <> 0 and @maxbet>@maxpermatch) 
	or (@minbet <> 0 and @maxpermatch <> 0 and @minbet>@maxpermatch)
	BEGIN
		SELECT @ErrMsg =  @UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match!!!'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定!!!'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定!!!'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม.'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match!!!'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다'
							else N'min bet must be less than max bet and max bet must be less than max bet per match!!!'
						end	, @ErrCode = 110
		return
	END
END

-------------------------------------------------
Select @MaxMaxPerMatch = isnull(MaxPerMatch151, 0)
from custinfo with (NOLOCK) where custid = @srecommend

---------------------------------------------------------
Select 
	@MinMinBet = MinBet,
	@MaxMaxBet = MaxBet
From CustSetting3rd with (NOLOCK)
where CustID = @srecommend and bettype=31 and sporttype=151



if @UpdateMultiple = 0
BEGIN
	if (@MinMinBet>0 and @MinBet>0 and @minbet<@MinMinBet)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Super Agent min bet'
							when 'CS' then N'最低投注需相等于或少于超级总代理最低投注'
							when 'CT' then N'最低投注需相等於或少於超級總代理最低投注'
							when 'TH' then N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่า จำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้จากตัวแทนสูงสุด.'
							when 'J' then N'min bet must be equal to or greater than Super Agent min bet'
							when 'KO' then N'죄송합니다. 최소 배팅은 슈퍼 에이전트 최소 베팅보다 많아야 합니다'
							else N'min bet must be equal to or greater than Super Agent min bet'
						end						
						+' (' + convert(varchar(20), @MinMinBet) + ').', @ErrCode = 119	
		return
	END
	
	if (@MaxMaxBet>0 and @MaxBet>0 and @maxbet>@MaxMaxBet)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Super Agent max bet'
							when 'CS' then N'最高投注需相等于或少于超级总代理最高投注'
							when 'CT' then N'最高投注需相等於或少於超級總代理最高投注'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนสูงสุด .'
							when 'J' then N'max bet must be equal to or less than Super Agent max bet'
							when 'KO' then N'죄송합니다. 최대 배팅은 슈퍼 에이전트의 최대 배팅 이하이여야 합니다'
							else N'max bet must be equal to or less than Super Agent max bet'
						end						
						+' (' + convert(varchar(20), @MaxMaxBet) + ').', @ErrCode = 120	
		return
	END
	
	if (@MaxMaxPerMatch>0 and @MaxPerMatch>0 and @MaxPerMatch>@MaxMaxPerMatch)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Super Agent Max Per Match'
							when 'CS' then N'单场最高投注需相等于或少于超级总代理单场最高投注(于足球)'
							when 'CT' then N'單場最高投注需相等於或少於超級總代理單場最高投注(於足球)'
							when 'TH' then N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนสูงสุด'
							when 'J' then N'Max Per Match must be equal to or less than Super AgentMax Per Match'
							when 'KO' then N'죄송합니다. 경기당 최대는 슈퍼 에이전트 최대 경기보다 이하이여야 합니다'
							else N'Max Per Match must be equal to or less than Super Agent Max Per Match '
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatch) + ').', @ErrCode = 121	
		return
	END
END

------------

------------
update CustSetting3rd with (ROWLOCK, UPDLOCK)
set	
	MinBet=CASE WHEN @UpdateMultiple = 1 THEN MinBet ELSE @MinBet END,
	MaxBet=CASE WHEN @UpdateMultiple = 1 THEN MaxBet ELSE @MaxBet END
where custid=@custid AND sporttype = 151
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
					end	, @ErrCode = 147
	return
end


EXEC dbo.Acc_CustomerUpdMaxPerMatchHR
	@custid = @custid,
	@MaxPerMatch = @MaxPerMatch,
	@Language = @Language,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT
	if @ErrCode > 0
	BEGIN
		return
	END

Declare @LogSPData varchar(5000)
Select @LogSPData ='<Acc_CustomerUpdMaster_MinMaxBetHR custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'MinB="'+ coalesce(cast(@minbet as varchar(50)),space(1)) + '" ' +
'MaxB="'+ coalesce(cast(@maxbet as varchar(50)),space(1)) + '" ' +
'MPM="'+ coalesce(cast(@maxpermatch as varchar(50)),space(1)) + '" ' +
'UpdMultiple="'+ coalesce(cast(@UpdateMultiple as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 310,
	@TrackingValue = @LogSPData

---------------------------------------------------------

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaster_MinMaxBetHR] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaster_MinMaxBetHR] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMaster_MinMaxBetHR] TO [vnteam]