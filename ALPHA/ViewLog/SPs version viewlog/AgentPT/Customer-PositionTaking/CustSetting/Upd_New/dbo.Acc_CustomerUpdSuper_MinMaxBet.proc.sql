ALTER PROCEDURE [dbo].[Acc_CustomerUpdSuper_MinMaxBet]
	@custid int,
	
	@MinBet money,
	@MaxBet money,
	@MaxPerMatch money,
	
	@MinBetv2 money,
	@MaxBetv2 money,
	@MaxPerMatchv2 money,

	@MinBetv3 money,
	@MaxBetv3 money,
	@MaxPerMatchv3 money,

	@MinBetv5 money,
	@MaxBetv5 money,
	@MaxPerMatchv5 money,

	@MinBetv8 money,
	@MaxBetv8 money,
	@MaxPerMatchv8 money,

	@MinBetv10 money,
	@MaxBetv10 money,
	@MaxPerMatchv10 money,

	@MinBetv11 money,
	@MaxBetv11 money,
	@MaxPerMatchv11 money,

	@MinBetv99 money,
	@MaxBetv99 money,
	@MaxPerMatchv99 money,	
	
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20080514@Thien
Task : Update MinBet, MaxBet, MaxPerMatch
DB: DB02.bodb02
Original: [Acc_CustomerUpdSuper_MinMaxBet]
Revisions:
    - 20090424@Phuc:Separate finance sporttype(201).
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Kiwi: amend to write log in xml format.

Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON

declare @ErrType varchar(1000)

if 
	@MinBet<0
	or @MaxBet < 0
	or @MaxPerMatch <0
	
	or @MinBetv2 <0
	or @MaxBetv2 <0
	or @MaxPerMatchv2 <0

	or @MinBetv3 <0
	or @MaxBetv3 <0
	or @MaxPerMatchv3 <0

	or @MinBetv5 <0
	or @MaxBetv5 <0
	or @MaxPerMatchv5 <0

	or @MinBetv8 <0
	or @MaxBetv8 <0
	or @MaxPerMatchv8 <0

	or @MinBetv10 <0
	or @MaxBetv10 <0
	or @MaxPerMatchv10 <0

	or @MinBetv11 <0
	or @MaxBetv11 <0
	or @MaxPerMatchv11 <0

	or @MinBetv99 <0
	or @MaxBetv99 <0
	or @MaxPerMatchv99 <0
BEGIN
	 
	Select @ErrMsg = case @Language 
						when 'E' then 'Wrong Min bet/ Max bet/ Max per match.'
						when 'CS' then N'最低投注/最高投注/单场最高投注不正确.'	
						when 'CT' then N'最低投注/最高投注/單場最高投注不正確.'	
						when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง.'						
						else N'Wrong Min bet/ Max bet/ Max per match.'					
					end, @ErrCode = 101
	return
END

select @ErrType = ''
select @ErrType = @ErrType + sportname + ', '
from sports with (NOLOCK) inner join
(
				select 1 as sporttype, @MinBet as MinBet, @MaxBet as MaxBet, @MaxPerMatch as MaxPerMatch
	union all	select 2 as sporttype, @MinBetv2 as MinBet, @MaxBetv2 as MaxBet, @MaxPerMatchv2 as MaxPerMatch
	union all	select 3 as sporttype, @MinBetv3 as MinBet, @MaxBetv3 as MaxBet, @MaxPerMatchv3 as MaxPerMatch
	union all	select 5 as sporttype, @MinBetv5 as MinBet, @MaxBetv5 as MaxBet, @MaxPerMatchv5 as MaxPerMatch
	union all	select 8 as sporttype, @MinBetv8 as MinBet, @MaxBetv8 as MaxBet, @MaxPerMatchv8 as MaxPerMatch
	union all	select 10 as sporttype, @MinBetv10 as MinBet, @MaxBetv10 as MaxBet, @MaxPerMatchv10 as MaxPerMatch
	union all	select 11 as sporttype, @MinBetv11 as MinBet, @MaxBetv11 as MaxBet, @MaxPerMatchv11 as MaxPerMatch
	union all	select 99 as sporttype, @MinBetv99 as MinBet, @MaxBetv99 as MaxBet, @MaxPerMatchv99 as MaxPerMatch	 
) as b on sports.sporttype = b.sporttype
where (MinBet<>0 and MaxBet <> 0 and  MinBet>MaxBet) 
or (MaxBet<> 0 and MaxPerMatch <> 0 and MaxBet>MaxPerMatch) 
or (MinBet <> 0 and MaxPerMatch <> 0 and MinBet>MaxPerMatch) 

if @ErrType <>''
BEGIN
	SELECT
		@ErrMsg =	case @Language 
							when 'E' then 'Sorry, min bet must be less than max bet and max bet must be less than max bet per match ('+@ErrType+').'
							when 'CS' then N'对不起，最低投注不能高于最高投注，最高投注不能高于单场最高投注设定('+@ErrType+').'
							when 'CT' then N'對不起,最低投注不能高於最高投注,最高投注不能高於單場最高投注設定('+@ErrType+').'					
							when 'TH' then N'ขออภัยจำนวนเงินในการเล่นขั้นต่ำต้องน้อยกว่าจำนวนเงินสูงสุดที่จะเล่นได้และจำนวนเงินสูงสุดที่เล่นได้ต้องน้อยกว่าจำนวนเงินเดิมพันต่อเกมการแข่งขัน('+@ErrType+').'
							else N'Sorry, min bet must be less than max bet and max bet must be less than max bet per match ('+@ErrType+').'
					end, @ErrCode = 102
	RETURN
END


update custsetting with (ROWLOCK, UPDLOCK)
set	
	MinBet = case sporttype when 1 then @MinBet when 2 then @MinBetv2 when 3 then @MinBetv3 when 5 then @MinBetv5 when 8 then @MinBetv8 when 10 then @MinBetv10 when 11 then @MinBetv11 when 99 then @MinBetv99 else MinBet end,
	MaxBet = case sporttype when 1 then @MaxBet when 2 then @MaxBetv2 when 3 then @MaxBetv3 when 5 then @MaxBetv5 when 8 then @MaxBetv8 when 10 then @MaxBetv10 when 11 then @MaxBetv11 when 99 then @MaxBetv99 else MaxBet end
where custid=@custid
if (@@error <> 0)
begin
	
	Select @ErrMsg = case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'	
						when 'J' then N'アップデート出来ません。'
						else N'Update process is unsuccessful !'
					end	, @ErrCode = 103 
	return
end

EXEC dbo.Acc_CustomerUpdMaxPerMatch 
	@custid = @custid,
	@maxpermatch = @maxpermatch,
	@maxpermatchv2 = @maxpermatchv2,
	@maxpermatchv3 = @maxpermatchv3,
	@maxpermatchv5 = @maxpermatchv5,
	@maxpermatchv8 = @maxpermatchv8,
	@maxpermatchv10 = @maxpermatchv10,
	@maxpermatchv11 = @maxpermatchv11,
	@maxpermatchv99 = @maxpermatchv99,
	@Language = @Language,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT
	if @ErrCode > 0
	BEGIN
		return
	END

Declare @LogSPData varchar(5000)
Select @LogSPData ='<Acc_CustomerUpdSuper_MinMaxBet custid="'+ coalesce(cast(@custid as varchar(50)),space(1))+ '" ' +
'MinB="'+ coalesce(cast(@MinBet as varchar(50)),space(1))+ '" ' +
'MaxB="'+ coalesce(cast(@MaxBet as varchar(50)),space(1))+ '" ' +
'MPM="'+ coalesce(cast(@MaxPerMatch as varchar(50)),space(1))+ '" ' +
'MinBv2="'+ coalesce(cast(@MinBetv2 as varchar(50)),space(1))+ '" ' +
'MaxBv2="'+ coalesce(cast(@MaxBetv2 as varchar(50)),space(1))+ '" ' +
'MPMv2="'+ coalesce(cast(@MaxPerMatchv2 as varchar(50)),space(1))+ '" ' +
'MinBv3="'+ coalesce(cast(@MinBetv3 as varchar(50)),space(1))+ '" ' +
'MaxBv3="'+ coalesce(cast(@MaxBetv3 as varchar(50)),space(1))+ '" ' +
'MPMv3="'+ coalesce(cast(@MaxPerMatchv3 as varchar(50)),space(1))+ '" ' +
'MinBv5="'+ coalesce(cast(@MinBetv5 as varchar(50)),space(1))+ '" ' +
'MaxBv5="'+ coalesce(cast(@MaxBetv5 as varchar(50)),space(1))+ '" ' +
'MPMv5="'+ coalesce(cast(@MaxPerMatchv5 as varchar(50)),space(1))+ '" ' +
'MinBv8="'+ coalesce(cast(@MinBetv8 as varchar(50)),space(1))+ '" ' +
'MaxBv8="'+ coalesce(cast(@MaxBetv8 as varchar(50)),space(1))+ '" ' +
'MPMv8="'+ coalesce(cast(@MaxPerMatchv8 as varchar(50)),space(1))+ '" ' +
'MinBv10="'+ coalesce(cast(@MinBetv10 as varchar(50)),space(1))+ '" ' +
'MaxBv10="'+ coalesce(cast(@MaxBetv10 as varchar(50)),space(1))+ '" ' +
'MPMv10="'+ coalesce(cast(@MaxPerMatchv10 as varchar(50)),space(1))+ '" ' +
'MinBv11="'+ coalesce(cast(@MinBetv11 as varchar(50)),space(1))+ '" ' +
'MaxBv11="'+ coalesce(cast(@MaxBetv11 as varchar(50)),space(1))+ '" ' +
'MPMv11="'+ coalesce(cast(@MaxPerMatchv11 as varchar(50)),space(1))+ '" ' +
'MinBv99="'+ coalesce(cast(@MinBetv99 as varchar(50)),space(1))+ '" ' +
'MaxBv99="'+ coalesce(cast(@MaxBetv99 as varchar(50)),space(1))+ '" ' +
'MPMv99="'+ coalesce(cast(@MaxPerMatchv99 as varchar(50)),space(1))+ '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1))+ '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+ '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+ '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 304,
	@TrackingValue = @LogSPData

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSuper_MinMaxBet] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdSuper_MinMaxBet] TO [vnteam]