ALTER PROCEDURE [dbo].[Acc_CustomerUpdSuper_MinMaxBetHR]
	@custid int,
	@MinBet money,
	@MaxBet money,
	@MaxPerMatch money,
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20081022@VinhTruong
Task : Update super's minbet, maxbet, max per match for Horseracing
DB: DB02.bodb02

Revisions:
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


if 
	@MinBet<0
	or @MaxBet < 0
	or @MaxPerMatch <0	
BEGIN
	 
	Select @ErrMsg = case @Language 
						when 'E' then 'Wrong Min bet/ Max bet/ Max per match.'
						when 'CS' then N'最低投注/最高投注/单场最高投注不正确.'	
						when 'CT' then N'最低投注/最高投注/單場最高投注不正確.'	
						when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง.'						
						when 'J' then N'Wrong Min bet/ Max bet/ Max per match.'						
						when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대.'						
						else N'Wrong Min bet/ Max bet/ Max per match.'					
					end, @ErrCode = 101
	return
END

if(@MinBet<>0 and @MaxBet <> 0 and  @MinBet>@MaxBet) 
	or (@MaxBet<> 0 and @MaxPerMatch <> 0 and @MaxBet>@MaxPerMatch) 
	or (@MinBet <> 0 and @MaxPerMatch <> 0 and @MinBet>@MaxPerMatch) 
BEGIN
	SELECT
		@ErrMsg =	case @Language 
							when 'E' then 'Sorry, min bet must be less than max bet and max bet must be less than max bet per match.'
							when 'CS' then N'对不起，最低投注不能高于最高投注，最高投注不能高于单场最高投注设定.'
							when 'CT' then N'對不起,最低投注不能高於最高投注,最高投注不能高於單場最高投注設定.'					
							when 'TH' then N'ขออภัยจำนวนเงินในการเล่นขั้นต่ำต้องน้อยกว่าจำนวนเงินสูงสุดที่จะเล่นได้และจำนวนเงินสูงสุดที่เล่นได้ต้องน้อยกว่าจำนวนเงินเดิมพันต่อเกมการแข่งขัน.'
							when 'J' then N'Sorry, min bet must be less than max bet and max bet must be less than max bet per match.'
							when 'KO' then N'죄송합니다, 최소 배팅은 최대 배팅보다 작아야 하고  최대 배팅은 경기당 최대 배팅보다 작아야 합니다.'
							else N'Sorry, min bet must be less than max bet and max bet must be less than max bet per match.'
					end, @ErrCode = 102
	RETURN
END


update CustSetting3rd with (ROWLOCK, UPDLOCK)
set	
	MinBet = @MinBet, MaxBet= @MaxBet
where custid=@custid and sporttype = 151
if (@@error <> 0)
begin
	
	Select @ErrMsg = case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'	
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end	, @ErrCode = 103 
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
Select @LogSPData ='<Acc_CustomerUpdSuper_MinMaxBetHR custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'MinB="'+ coalesce(cast(@MinBet as varchar(50)),space(1)) + '" ' +
'MaxB="'+ coalesce(cast(@MaxBet as varchar(50)),space(1)) + '" ' +
'MPM="'+ coalesce(cast(@MaxPerMatch as varchar(50)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 309,
	@TrackingValue = @LogSPData

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSuper_MinMaxBetHR] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMinMaxBetFI] TO [vnteam]