ALTER PROCEDURE [dbo].[Acc_CustomerUpdAgent_MinMaxBet]
	@custid int,-- agentID
	
	@minbet money,
	@maxbet money,
	@maxpermatch money,
	
	@minbetv2 money,
	@maxbetv2 money,
	@maxpermatchv2 money,
	
	@minbetv3 money,
	@maxbetv3 money,
	@maxpermatchv3 money,
	
	@minbetv5 money,
	@maxbetv5 money,
	@maxpermatchv5 money,
	
	@minbetv8 money,
	@maxbetv8 money,
	@maxpermatchv8 money,
	
	@minbetv10 money,
	@maxbetv10 money,
	@maxpermatchv10 money,
	
	@minbetv11 money,
	@maxbetv11 money,
	@maxpermatchv11 money,

	@minbetv99 money,
	@maxbetv99 money,
	@maxpermatchv99 money,	
	
	@UpdateMultiple bit = 0,	
	
	@UpdateMinMaxBet bit = 1,
	@UpdateMinMaxBetv2 bit = 1,
	@UpdateMinMaxBetv3 bit = 1,
	@UpdateMinMaxBetv5 bit = 1,
	@UpdateMinMaxBetv8 bit = 1,
	@UpdateMinMaxBetv10 bit = 1,
	@UpdateMinMaxBetv11 bit = 1,
	@UpdateMinMaxBetv99 bit = 1,
		
	@SubAccID int = 0, --Sub-AccountID	
	
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
--@Source Control
/*
Created: 20080515@Thien
Task : Update Agent MinBet, MaxBet, MaxPerMatch
DB: DB02.bodb02
Original:[Acc_CustomerUpdAgent_MinMaxBet]

Revisions:
    - 20090314@HanhVu: add Korean language
    - 20090424@Phuc:Separate finance sporttype(201).
					Write log subaccname instead of subaccid.	
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Kiwi: amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON

Declare 
	@MinMinBet money, @MaxMaxBet money,	@MaxMaxPerMatch money,
	@MinMinBetv2 money, @MaxMaxBetv2 money, @MaxMaxPerMatchv2 money,
	@MinMinBetv3 money, @MaxMaxBetv3 money, @MaxMaxPerMatchv3 money,
	@MinMinBetv5 money, @MaxMaxBetv5 money, @MaxMaxPerMatchv5 money,
	@MinMinBetv8 money, @MaxMaxBetv8 money, @MaxMaxPerMatchv8 money,
	@MinMinBetv10 money, @MaxMaxBetv10 money, @MaxMaxPerMatchv10 money,
	@MinMinBetv11 money, @MaxMaxBetv11 money, @MaxMaxPerMatchv11 money,
	@MinMinBetv99 money, @MaxMaxBetv99 money, @MaxMaxPerMatchv99 money
	
declare @ErrAcc varchar(4000), @ErrType varchar(4000),
		@UserName varchar(30), @mrecommend int
		
Select @UserName = username, @mrecommend = mrecommend
from customer with (NOLOCK)
where CustID = @CustID

if @UpdateMinMaxBet = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@MinBet<0
		or @MaxBet < 0
		or @MaxPerMatch <0
	BEGIN
		select @ErrCode = 2
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Soccer).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于足球).'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於足球).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬาฟุตบอล).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Soccer).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (축구).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Soccer).'
					end
		return
	END
END

if @UpdateMinMaxBetv2 = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@MinBetv2 <0
		or @MaxBetv2 <0
		or @MaxPerMatchv2 <0
	BEGIN
		select @ErrCode = 3
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Basketball).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于篮球).'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於籃球).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬาบาสเก็ตบอล).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Basketball).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (농구).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Basketball).'
					end
		return
	END
END

if @UpdateMinMaxBetv3 = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@MinBetv3 <0
		or @MaxBetv3 <0
		or @MaxPerMatchv3 <0
	BEGIN
		select @ErrCode = 3
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Football).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于美式足球).'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於美式足球).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬาอเมริกันฟุตบอล).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Football).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (풋볼).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Football).'
					end
		return
	END
END

if @UpdateMinMaxBetv5 = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@MinBetv5 <0
		or @MaxBetv5 <0
		or @MaxPerMatchv5 <0
	BEGIN
		select @ErrCode = 3
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Tennis).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于网球).'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於網球).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬาเทนนิส).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Tennis).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (테니스).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Tennis).'
					end
		return
	END
END

if @UpdateMinMaxBetv8 = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@MinBetv8 <0
		or @MaxBetv8 <0
		or @MaxPerMatchv8 <0
	BEGIN
		select @ErrCode = 3
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Baseball).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于棒球).'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於棒球).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬาเบสบอล).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Baseball).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (야구).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Baseball).'
					end
		return
	END
END

if @UpdateMinMaxBetv10 = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@MinBetv10 <0
		or @MaxBetv10 <0
		or @MaxPerMatchv10 <0
	BEGIN
		select @ErrCode = 3
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Golf).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于高尔夫球).'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於高爾夫球).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬากอฟล์).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Golf).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (골프).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Golf).'
					end
		return
	END
END

if @UpdateMinMaxBetv11 = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@MinBetv11 <0
		or @MaxBetv11 <0
		or @MaxPerMatchv11 <0
	BEGIN
		select @ErrCode = 3
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Motorsports).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于赛车).'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於賽車).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬารถแข่ง).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Motorsports).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (모토스포츠).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Motorsports).'
					end
		return
	END
END

if @UpdateMinMaxBetv99 = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@MinBetv99 <0
		or @MaxBetv99 <0
		or @MaxPerMatchv99 <0
	BEGIN
		select @ErrCode = 3
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Other sports).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于其他).'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於其他).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬาอื่นๆ).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Other sports).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (기타 스포츠).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Other sports).'
					end
		return
	END
END

Select @MinMinBet = 0, @MaxMaxBet = 0,
	@MinMinBetv2 = 0, @MaxMaxBetv2 = 0,
	@MinMinBetv3 = 0, @MaxMaxBetv3 = 0,
	@MinMinBetv5 = 0, @MaxMaxBetv5 = 0,
	@MinMinBetv8 = 0, @MaxMaxBetv8 = 0,
	@MinMinBetv10 = 0, @MaxMaxBetv10 = 0,
	@MinMinBetv11 = 0, @MaxMaxBetv11 = 0,
	@MinMinBetv99 = 0, @MaxMaxBetv99 = 0

Select 
	@MinMinBet = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBet = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=1
where ci.custid = @MRecommend

Select 
	@MinMinBetv2 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv2 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=2
where ci.custid = @MRecommend

Select 
	@MinMinBetv3 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv3 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=3
where ci.custid = @MRecommend

Select 
	@MinMinBetv5 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv5 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=5
where ci.custid = @MRecommend

Select 
	@MinMinBetv8 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv8 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=8
where ci.custid = @MRecommend

Select 
	@MinMinBetv10 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv10 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=10
where ci.custid = @MRecommend

Select 
	@MinMinBetv11 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv11 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=11
where ci.custid = @MRecommend

Select 
	@MinMinBetv99 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv99 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=99
where ci.custid = @MRecommend

Select	
	@MaxMaxperMatch = isnull(Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end),0), 
	@MaxMaxPerMatchv2 = isnull(Min(case when cs.MaxPerMatch2 = 0 then NULL else cs.MaxPerMatch2 end),0),
	@MaxMaxPerMatchv3 = isnull(Min(case when cs.MaxPerMatch3 = 0 then NULL else cs.MaxPerMatch3 end),0),
	@MaxMaxPerMatchv5 = isnull(Min(case when cs.MaxPerMatch5 = 0 then NULL else cs.MaxPerMatch5 end),0),
	@MaxMaxPerMatchv8 = isnull(Min(case when cs.MaxPerMatch8 = 0 then NULL else cs.MaxPerMatch8 end),0),
	@MaxMaxPerMatchv10 = isnull(Min(case when cs.MaxPerMatch10 = 0 then NULL else cs.MaxPerMatch10 end),0),
	@MaxMaxPerMatchv11 = isnull(Min(case when cs.MaxPerMatch11 = 0 then NULL else cs.MaxPerMatch11 end),0),
	@MaxMaxPerMatchv99 = isnull(Min(case when cs.MaxPerMatch99 = 0 then NULL else cs.MaxPerMatch99 end),0)
from 
	custinfo as cs WITH (NOLOCK) 
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
where ci.custid = @CustID

if @UpdateMultiple = 0 or @UpdateMinMaxBet = 1
BEGIN

	if (@MinBet<>0 and @MaxBet <> 0 and  @MinBet>@MaxBet) or (@MaxBet<> 0 and @MaxPerMatch <> 0 and @MaxBet>@MaxPerMatch) 
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Soccer)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于足球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於足球)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม ( สำหรับฟุตบอล ) .'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Soccer)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (축구)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Soccer)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBet) + '-' + convert(varchar(20), @MaxBet) + '-' + convert(varchar(20), @MaxPerMatch), @ErrCode = 109					 
		
		return
	END

	if (@MinMinBet>0 and @MinBet>0 and @MinBet<@MinMinBet)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Master Agent min bet (for Soccer)'
							when 'CS' then N'最低投注需相等于或少于总代理最低投注(于足球)'
							when 'CT' then N'最低投注需相等於或少於總代理最低投注(於足球)'
							when 'TH' then N'จำนวนเงินขั้นต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำที่ในการเล่นที่กำหนดไว้ของตัวแทนหลัก (สำหรับกีฬาฟุตบอล).'
							when 'J' then N'min bet must be equal to or greater than Master Agent min bet (for Soccer)'
							when 'KO' then N'최소 배팅은 마스터 에이전트 최소 배팅 이상이여야 합니다 (축구)'
							else N'min bet must be equal to or greater than Master Agent min bet (for Soccer)'
						end						
						+' (' + convert(varchar(20), @MinMinBet) + ').', @ErrCode = 110				 
		
		return
	END
	
	if (@MaxMaxBet>0 and @MaxBet>0 and @MaxBet>@MaxMaxBet)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Master Agent max bet (for Soccer)'
							when 'CS' then N'最高投注需相等于或少于总代理最高投注(于足球)'
							when 'CT' then N'最高投注需相等於或少於總代理最高投注(於足球)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนหลัก(สำหรับกีฬาฟุตบอล) .'
							when 'J' then N'max bet must be equal to or less than Master Agent max bet (for Soccer)'
							when 'KO' then N'초대 배팅은 마스터 에이전트의 최대 배팅 이하여야 합니다 (축구)'
							else N'max bet must be equal to or less than Master Agent max bet (for Soccer)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBet) + ').', @ErrCode = 111					 
		
		return
	END
	
	if (@MaxMaxPerMatch>0 and @MaxPerMatch>0 and @MaxPerMatch>@MaxMaxPerMatch)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Master Agent Max Per Match (for Soccer)'
							when 'CS' then N'单场最高投注需相等于或少于总代理单场最高投注(于足球)'
							when 'CT' then N'單場最高投注需相等於或少於總代理單場最高投注(於足球)'
							when 'TH' then N'จำนวนเงินในการเล่นสูงสุดต่อรายการต้องเท่ากับ หรือน้อยกว่า จำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนหลักต่อเกมการแข่งขัน (สำหรับกีฬาฟุตบอล).'
							when 'J' then N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Soccer)'
							when 'KO' then N'최대 경기는 마스터 에이전트 최대 경기보다 자아야 합니다 (축구)'
							else N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Soccer)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatch) + ').', @ErrCode = 111					 
		
		return
	END
END


if @UpdateMultiple = 0 or @UpdateMinMaxBetv2 = 1
BEGIN
	if (@MinBetv2 <> 0 and @MaxBetv2 <> 0 and @MinBetv2>@MaxBetv2) or (@MaxBetv2 <> 0 and @MaxPerMatchv2 <> 0 and @MaxBetv2>@MaxPerMatchv2)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Basketball)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于篮球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於籃球)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาบาสเก็ตบอล).'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Basketball)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (농구)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Basketball)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv2) + '-' + convert(varchar(20), @MaxBetv2) + '-' + convert(varchar(20), @MaxPerMatchv2), @ErrCode = 112					 
		
		return
	END

	if (@MinMinBetv2>0 and @MinBetv2>0 and @MinBetv2<@MinMinBetv2)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Master Agent min bet (for Basketball)'
							when 'CS' then N'最低投注需相等于或少于总代理最低投注(于篮球)'
							when 'CT' then N'最低投注需相等於或少於總代理最低投注(於籃球)'
							when 'TH' then N'จำนวนเงินขั้นต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำที่ในการเล่นที่กำหนดไว้ของตัวแทนหลัก (สำหรับกีฬาบาสเก็ตบอล).'
							when 'J' then N'min bet must be equal to or greater than Master Agent min bet (for Basketball)'
							when 'KO' then N'최소 배팅은 마스터 에이전트 최소 배팅 이상이여야 합니다 (농구)'
							else N'min bet must be equal to or greater than Master Agent min bet (for Basketball)'
						end						
						+' (' + convert(varchar(20), @MinMinBetv2) + ').', @ErrCode = 113					 
		
		return
	END

	if (@MaxMaxBetv2>0 and @MaxBetv2>0 and @MaxBetv2>@MaxMaxBetv2)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Master Agent max bet (for Basketball)'
							when 'CS' then N'最高投注需相等于或少于总代理最高投注(于篮球)'
							when 'CT' then N'最高投注需相等於或少於總代理最高投注(於籃球)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนหลัก (สำหรับกีฬาบาสเก็ตบอล).'
							when 'J' then N'max bet must be equal to or less than Master Agent max bet (for Basketball)'
							when 'KO' then N'초대 배팅은 마스터 에이전트의 최대 배팅 이하여야 합니다 (농구)'
							else N'max bet must be equal to or less than Master Agent max bet (for Basketball)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBetv2) + ').', @ErrCode = 114					 
		
		return
	END
	if (@MaxMaxPerMatchv2>0 and @MaxPerMatchv2>0 and @MaxPerMatchv2>@MaxMaxPerMatchv2)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Master Agent Max Per Match (for Basketball)'
							when 'CS' then N'单场最高投注需相等于或少于总代理单场最高投注(于篮球)'
							when 'CT' then N'單場最高投注需相等於或少於總代理單場最高投注(於籃球)'
							when 'TH' then N'จำนวนเงินในการเล่นสูงสุดต่อรายการต้องเท่ากับ หรือน้อยกว่า จำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนหลักต่อเกมการแข่งขัน (สำหรับกีฬาบาสเก็ตบอล).'
							when 'J' then N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Basketball)'
							when 'KO' then N'최대 경기는 마스터 에이전트 최대 경기보다 자아야 합니다 (농구)'
							else N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Basketball)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatchv2) + ').', @ErrCode = 114					 
		
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv3 = 1
BEGIN
	if (@MinBetv3 <> 0 and @MaxBetv3 <> 0 and @MinBetv3>@MaxBetv3) or (@MaxBetv3 <> 0 and @MaxPerMatchv3 <> 0 and @MaxBetv3>@MaxPerMatchv3)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Football)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于美式足球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於美式足球)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาอเมริกันฟุตบอล).'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Football)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (풋볼)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Football)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv3) + '-' + convert(varchar(20), @MaxBetv3) + '-' + convert(varchar(20), @MaxPerMatchv3), @ErrCode = 112					 
		
		return
	END

	if (@MinMinBetv3>0 and @MinBetv3>0 and @MinBetv3<@MinMinBetv3)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Master Agent min bet (for Football)'
							when 'CS' then N'最低投注需相等于或少于总代理最低投注(于美式足球)'
							when 'CT' then N'最低投注需相等於或少於總代理最低投注(於美式足球)'
							when 'TH' then N'จำนวนเงินขั้นต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำที่ในการเล่นที่กำหนดไว้ของตัวแทนหลัก (สำหรับกีฬาอเมริกันฟุตบอล).'
							when 'J' then N'min bet must be equal to or greater than Master Agent min bet (for Football)'
							when 'KO' then N'최소 배팅은 마스터 에이전트 최소 배팅 이상이여야 합니다 (풋볼)'
							else N'min bet must be equal to or greater than Master Agent min bet (for Football)'
						end						
						+' (' + convert(varchar(20), @MinMinBetv3) + ').', @ErrCode = 113					 
		
		return
	END

	if (@MaxMaxBetv3>0 and @MaxBetv3>0 and @MaxBetv3>@MaxMaxBetv3)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Master Agent max bet (for Football)'
							when 'CS' then N'最高投注需相等于或少于总代理最高投注(于美式足球)'
							when 'CT' then N'最高投注需相等於或少於總代理最高投注(於美式足球)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนหลัก (สำหรับกีฬาอเมริกันฟุตบอล).'
							when 'J' then N'max bet must be equal to or less than Master Agent max bet (for Football)'
							when 'KO' then N'초대 배팅은 마스터 에이전트의 최대 배팅 이하여야 합니다 (풋볼)'
							else N'max bet must be equal to or less than Master Agent max bet (for Football)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBetv3) + ').', @ErrCode = 114					 
		
		return
	END
	if (@MaxMaxPerMatchv3>0 and @MaxPerMatchv3>0 and @MaxPerMatchv3>@MaxMaxPerMatchv3)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Master Agent Max Per Match (for Football)'
							when 'CS' then N'单场最高投注需相等于或少于总代理单场最高投注(于美式足球)'
							when 'CT' then N'單場最高投注需相等於或少於總代理單場最高投注(於美式足球)'
							when 'TH' then N'จำนวนเงินในการเล่นสูงสุดต่อรายการต้องเท่ากับ หรือน้อยกว่า จำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนหลักต่อเกมการแข่งขัน (สำหรับกีฬาอเมริกันฟุตบอล).'
							when 'J' then N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Football)'
							when 'KO' then N'최대 경기는 마스터 에이전트 최대 경기보다 자아야 합니다 (풋볼)'
							else N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Football)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatchv3) + ').', @ErrCode = 114					 
		
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv5 = 1
BEGIN
	if (@MinBetv5 <> 0 and @MaxBetv5 <> 0 and @MinBetv5>@MaxBetv5) or (@MaxBetv5 <> 0 and @MaxPerMatchv5 <> 0 and @MaxBetv5>@MaxPerMatchv5)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Tennis)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于网球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於網球)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาเทนนิส).'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Tennis)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (테니스)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Tennis)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv5) + '-' + convert(varchar(20), @MaxBetv5) + '-' + convert(varchar(20), @MaxPerMatchv5), @ErrCode = 112					 
		
		return
	END

	if (@MinMinBetv5>0 and @MinBetv5>0 and @MinBetv5<@MinMinBetv5)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Master Agent min bet (for Tennis)'
							when 'CS' then N'最低投注需相等于或少于总代理最低投注(于网球)'
							when 'CT' then N'最低投注需相等於或少於總代理最低投注(於網球)'
							when 'TH' then N'จำนวนเงินขั้นต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำที่ในการเล่นที่กำหนดไว้ของตัวแทนหลัก (สำหรับกีฬาเทนนิส).'
							when 'J' then N'min bet must be equal to or greater than Master Agent min bet (for Tennis)'
							when 'KO' then N'최소 배팅은 마스터 에이전트 최소 배팅 이상이여야 합니다 (테니스)'
							else N'min bet must be equal to or greater than Master Agent min bet (for Tennis)'
						end						
						+' (' + convert(varchar(20), @MinMinBetv5) + ').', @ErrCode = 113					 
		
		return
	END

	if (@MaxMaxBetv5>0 and @MaxBetv5>0 and @MaxBetv5>@MaxMaxBetv5)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Master Agent max bet (for Tennis)'
							when 'CS' then N'最高投注需相等于或少于总代理最高投注(于网球)'
							when 'CT' then N'最高投注需相等於或少於總代理最高投注(於網球)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนหลัก (สำหรับกีฬาเทนนิส).'
							when 'J' then N'max bet must be equal to or less than Master Agent max bet (for Tennis)'
							when 'KO' then N'초대 배팅은 마스터 에이전트의 최대 배팅 이하여야 합니다 (테니스)'
							else N'max bet must be equal to or less than Master Agent max bet (for Tennis)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBetv5) + ').', @ErrCode = 114					 
		
		return
	END
	if (@MaxMaxPerMatchv5>0 and @MaxPerMatchv5>0 and @MaxPerMatchv5>@MaxMaxPerMatchv5)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Master Agent Max Per Match (for Tennis)'
							when 'CS' then N'单场最高投注需相等于或少于总代理单场最高投注(于网球)'
							when 'CT' then N'單場最高投注需相等於或少於總代理單場最高投注(於網球)'
							when 'TH' then N'จำนวนเงินในการเล่นสูงสุดต่อรายการต้องเท่ากับ หรือน้อยกว่า จำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนหลักต่อเกมการแข่งขัน (สำหรับกีฬาเทนนิส).'
							when 'J' then N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Tennis)'
							when 'KO' then N'최대 경기는 마스터 에이전트 최대 경기보다 자아야 합니다 (테니스)'
							else N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Tennis)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatchv5) + ').', @ErrCode = 114					 
		
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv8 = 1
BEGIN
	if (@MinBetv8 <> 0 and @MaxBetv8 <> 0 and @MinBetv8>@MaxBetv8) or (@MaxBetv8 <> 0 and @MaxPerMatchv8 <> 0 and @MaxBetv8>@MaxPerMatchv8)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Baseball)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于棒球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於棒球)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาเบสบอล).'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Baseball)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (야구)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Baseball)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv8) + '-' + convert(varchar(20), @MaxBetv8) + '-' + convert(varchar(20), @MaxPerMatchv8), @ErrCode = 112					 
		
		return
	END

	if (@MinMinBetv8>0 and @MinBetv8>0 and @MinBetv8<@MinMinBetv8)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Master Agent min bet (for Baseball)'
							when 'CS' then N'最低投注需相等于或少于总代理最低投注(于棒球)'
							when 'CT' then N'最低投注需相等於或少於總代理最低投注(於棒球)'
							when 'TH' then N'จำนวนเงินขั้นต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำที่ในการเล่นที่กำหนดไว้ของตัวแทนหลัก (สำหรับกีฬาเบสบอล).'
							when 'J' then N'min bet must be equal to or greater than Master Agent min bet (for Baseball)'
							when 'KO' then N'최소 배팅은 마스터 에이전트 최소 배팅 이상이여야 합니다 (야구)'
							else N'min bet must be equal to or greater than Master Agent min bet (for Baseball)'
						end						
						+' (' + convert(varchar(20), @MinMinBetv8) + ').', @ErrCode = 113					 
		
		return
	END

	if (@MaxMaxBetv8>0 and @MaxBetv8>0 and @MaxBetv8>@MaxMaxBetv8)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Master Agent max bet (for Baseball)'
							when 'CS' then N'最高投注需相等于或少于总代理最高投注(于棒球)'
							when 'CT' then N'最高投注需相等於或少於總代理最高投注(於棒球)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนหลัก (สำหรับกีฬาเบสบอล).'
							when 'J' then N'max bet must be equal to or less than Master Agent max bet (for Baseball)'
							when 'KO' then N'초대 배팅은 마스터 에이전트의 최대 배팅 이하여야 합니다 (야구)'
							else N'max bet must be equal to or less than Master Agent max bet (for Baseball)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBetv8) + ').', @ErrCode = 114					 
		
		return
	END
	if (@MaxMaxPerMatchv8>0 and @MaxPerMatchv8>0 and @MaxPerMatchv8>@MaxMaxPerMatchv8)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Master Agent Max Per Match (for Baseball)'
							when 'CS' then N'单场最高投注需相等于或少于总代理单场最高投注(于棒球)'
							when 'CT' then N'單場最高投注需相等於或少於總代理單場最高投注(於棒球)'
							when 'TH' then N'จำนวนเงินในการเล่นสูงสุดต่อรายการต้องเท่ากับ หรือน้อยกว่า จำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนหลักต่อเกมการแข่งขัน (สำหรับกีฬาเบสบอล).'
							when 'J' then N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Baseball)'
							when 'KO' then N'최대 경기는 마스터 에이전트 최대 경기보다 자아야 합니다 (야구)'
							else N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Baseball)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatchv8) + ').', @ErrCode = 114					 
		
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv10 = 1
BEGIN
	if (@MinBetv10 <> 0 and @MaxBetv10 <> 0 and @MinBetv10>@MaxBetv10) or (@MaxBetv10 <> 0 and @MaxPerMatchv10 <> 0 and @MaxBetv10>@MaxPerMatchv10)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Golf)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于高尔夫球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於高爾夫球)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬากอฟล์).'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Golf)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (골프)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Golf)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv10) + '-' + convert(varchar(20), @MaxBetv10) + '-' + convert(varchar(20), @MaxPerMatchv10), @ErrCode = 112					 
		
		return
	END

	if (@MinMinBetv10>0 and @MinBetv10>0 and @MinBetv10<@MinMinBetv10)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Master Agent min bet (for Golf)'
							when 'CS' then N'最低投注需相等于或少于总代理最低投注(于高尔夫球)'
							when 'CT' then N'最低投注需相等於或少於總代理最低投注(於高爾夫球)'
							when 'TH' then N'จำนวนเงินขั้นต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำที่ในการเล่นที่กำหนดไว้ของตัวแทนหลัก (สำหรับกีฬากอฟล์).'
							when 'J' then N'min bet must be equal to or greater than Master Agent min bet (for Golf)'
							when 'KO' then N'최소 배팅은 마스터 에이전트 최소 배팅 이상이여야 합니다 (골프)'
							else N'min bet must be equal to or greater than Master Agent min bet (for Golf)'
						end						
						+' (' + convert(varchar(20), @MinMinBetv10) + ').', @ErrCode = 113					 
		
		return
	END

	if (@MaxMaxBetv10>0 and @MaxBetv10>0 and @MaxBetv10>@MaxMaxBetv10)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Master Agent max bet (for Golf)'
							when 'CS' then N'最高投注需相等于或少于总代理最高投注(于高尔夫球)'
							when 'CT' then N'最高投注需相等於或少於總代理最高投注(於高爾夫球)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนหลัก (สำหรับกีฬากอฟล์).'
							when 'J' then N'max bet must be equal to or less than Master Agent max bet (for Golf)'
							when 'KO' then N'초대 배팅은 마스터 에이전트의 최대 배팅 이하여야 합니다 (골프)'
							else N'max bet must be equal to or less than Master Agent max bet (for Golf)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBetv10) + ').', @ErrCode = 114					 
		
		return
	END
	if (@MaxMaxPerMatchv10>0 and @MaxPerMatchv10>0 and @MaxPerMatchv10>@MaxMaxPerMatchv10)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Master Agent Max Per Match (for Golf)'
							when 'CS' then N'单场最高投注需相等于或少于总代理单场最高投注(于高尔夫球)'
							when 'CT' then N'單場最高投注需相等於或少於總代理單場最高投注(於高爾夫球)'
							when 'TH' then N'จำนวนเงินในการเล่นสูงสุดต่อรายการต้องเท่ากับ หรือน้อยกว่า จำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนหลักต่อเกมการแข่งขัน (สำหรับกีฬากอฟล์).'
							when 'J' then N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Golf)'
							when 'KO' then N'최대 경기는 마스터 에이전트 최대 경기보다 자아야 합니다 (골프)'
							else N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Golf)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatchv10) + ').', @ErrCode = 114					 
		
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv11 = 1
BEGIN
	if (@MinBetv11 <> 0 and @MaxBetv11 <> 0 and @MinBetv11>@MaxBetv11) or (@MaxBetv11 <> 0 and @MaxPerMatchv11 <> 0 and @MaxBetv11>@MaxPerMatchv11)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Motorsports)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于赛车)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於賽車)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬารถแข่ง).'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Motorsports)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (모토스포츠)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Motorsports)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv11) + '-' + convert(varchar(20), @MaxBetv11) + '-' + convert(varchar(20), @MaxPerMatchv11), @ErrCode = 112					 
		
		return
	END

	if (@MinMinBetv11>0 and @MinBetv11>0 and @MinBetv11<@MinMinBetv11)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Master Agent min bet (for Motorsports)'
							when 'CS' then N'最低投注需相等于或少于总代理最低投注(于赛车)'
							when 'CT' then N'最低投注需相等於或少於總代理最低投注(於賽車)'
							when 'TH' then N'จำนวนเงินขั้นต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำที่ในการเล่นที่กำหนดไว้ของตัวแทนหลัก (สำหรับกีฬารถแข่ง).'
							when 'J' then N'min bet must be equal to or greater than Master Agent min bet (for Motorsports)'
							when 'KO' then N'최소 배팅은 마스터 에이전트 최소 배팅 이상이여야 합니다 (모토스포츠)'
							else N'min bet must be equal to or greater than Master Agent min bet (for Motorsports)'
						end						
						+' (' + convert(varchar(20), @MinMinBetv11) + ').', @ErrCode = 113					 
		
		return
	END

	if (@MaxMaxBetv11>0 and @MaxBetv11>0 and @MaxBetv11>@MaxMaxBetv11)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Master Agent max bet (for Motorsports)'
							when 'CS' then N'最高投注需相等于或少于总代理最高投注(于赛车)'
							when 'CT' then N'最高投注需相等於或少於總代理最高投注(於賽車)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนหลัก (สำหรับกีฬารถแข่ง).'
							when 'J' then N'max bet must be equal to or less than Master Agent max bet (for Motorsports)'
							when 'KO' then N'초대 배팅은 마스터 에이전트의 최대 배팅 이하여야 합니다 (모토스포츠)'
							else N'max bet must be equal to or less than Master Agent max bet (for Motorsports)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBetv11) + ').', @ErrCode = 114					 
		
		return
	END
	if (@MaxMaxPerMatchv11>0 and @MaxPerMatchv11>0 and @MaxPerMatchv11>@MaxMaxPerMatchv11)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Master Agent Max Per Match (for Motorsports)'
							when 'CS' then N'单场最高投注需相等于或少于总代理单场最高投注(于赛车)'
							when 'CT' then N'單場最高投注需相等於或少於總代理單場最高投注(於賽車)'
							when 'TH' then N'จำนวนเงินในการเล่นสูงสุดต่อรายการต้องเท่ากับ หรือน้อยกว่า จำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนหลักต่อเกมการแข่งขัน (สำหรับกีฬารถแข่ง)).'
							when 'J' then N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Motorsports)'
							when 'KO' then N'최대 경기는 마스터 에이전트 최대 경기보다 자아야 합니다 (모토스포츠)'
							else N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Motorsports)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatchv11) + ').', @ErrCode = 114					 
		
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv99 = 1
BEGIN
	if (@MinBetv99 <> 0 and @MaxBetv99 <> 0 and @MinBetv99>@MaxBetv99) or (@MaxBetv99 <> 0 and @MaxPerMatchv99 <> 0 and @MaxBetv99>@MaxPerMatchv99)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Other sports)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于其他)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於其他)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาอื่นๆ).'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Other sports)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (기타 스포츠)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Other sports)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv99) + '-' + convert(varchar(20), @MaxBetv99) + '-' + convert(varchar(20), @MaxPerMatchv99), @ErrCode = 112					 
		
		return
	END

	if (@MinMinBetv99>0 and @MinBetv99>0 and @MinBetv99<@MinMinBetv99)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Master Agent min bet (for Other sports)'
							when 'CS' then N'最低投注需相等于或少于总代理最低投注(于其他)'
							when 'CT' then N'最低投注需相等於或少於總代理最低投注(於其他)'
							when 'TH' then N'จำนวนเงินขั้นต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำที่ในการเล่นที่กำหนดไว้ของตัวแทนหลัก (สำหรับกีฬาอื่นๆ).'
							when 'J' then N'min bet must be equal to or greater than Master Agent min bet (for Other sports)'
							when 'KO' then N'최소 배팅은 마스터 에이전트 최소 배팅 이상이여야 합니다 (기타 스포츠)'
							else N'min bet must be equal to or greater than Master Agent min bet (for Other sports)'
						end						
						+' (' + convert(varchar(20), @MinMinBetv99) + ').', @ErrCode = 113					 
		
		return
	END

	if (@MaxMaxBetv99>0 and @MaxBetv99>0 and @MaxBetv99>@MaxMaxBetv99)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Master Agent max bet (for Other sports)'
							when 'CS' then N'最高投注需相等于或少于总代理最高投注(于其他)'
							when 'CT' then N'最高投注需相等於或少於總代理最高投注(於其他)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนหลัก (สำหรับกีฬาอื่นๆ).'
							when 'J' then N'max bet must be equal to or less than Master Agent max bet (for Other sports)'
							when 'KO' then N'초대 배팅은 마스터 에이전트의 최대 배팅 이하여야 합니다 (기타 스포츠)'
							else N'max bet must be equal to or less than Master Agent max bet (for Other sports)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBetv99) + ').', @ErrCode = 114					 
		
		return
	END
	if (@MaxMaxPerMatchv99>0 and @MaxPerMatchv99>0 and @MaxPerMatchv99>@MaxMaxPerMatchv99)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Master Agent Max Per Match (for Other sports)'
							when 'CS' then N'单场最高投注需相等于或少于总代理单场最高投注(于其他)'
							when 'CT' then N'單場最高投注需相等於或少於總代理單場最高投注(於其他)'
							when 'TH' then N'จำนวนเงินในการเล่นสูงสุดต่อรายการต้องเท่ากับ หรือน้อยกว่า จำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนหลักต่อเกมการแข่งขัน (สำหรับกีฬาอื่นๆ).'
							when 'J' then N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Other sports)'
							when 'KO' then N'최대 경기는 마스터 에이전트 최대 경기보다 자아야 합니다 (기타 스포츠)'
							else N'Max Per Match must be equal to or less than Master Agent Max Per Match (for Other sports)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatchv99) + ').', @ErrCode = 114					 
		
		return
	END
END
---------------------------------------------------------------


update custsetting with (ROWLOCK, UPDLOCK)
set
	MinBet = case when @UpdateMultiple = 1 and ((@UpdateMinMaxBet = 0 and sporttype=1) or (@UpdateMinMaxBetv2 = 0 and sporttype=2) or (@UpdateMinMaxBetv3 = 0 and sporttype=3) or (@UpdateMinMaxBetv5 = 0 and sporttype=5) or (@UpdateMinMaxBetv8 = 0 and sporttype=8) or (@UpdateMinMaxBetv10 = 0 and sporttype=10) or (@UpdateMinMaxBetv11 = 0 and sporttype=11)  or (@UpdateMinMaxBetv99 = 0 and sporttype=99)) then MinBet else case sporttype when 1 then @MinBet when 2 then @MinBetv2 when 3 then @MinBetv3 when 5 then @MinBetv5 when 8 then @MinBetv8 when 10 then @MinBetv10 when 11 then @MinBetv11 when 99 then @MinBetv99 else minbet end end,																																																																																																																																																		
	MaxBet = case when @UpdateMultiple = 1 and ((@UpdateMinMaxBet = 0 and sporttype=1) or (@UpdateMinMaxBetv2 = 0 and sporttype=2)  or (@UpdateMinMaxBetv3 = 0 and sporttype=3) or (@UpdateMinMaxBetv5 = 0 and sporttype=5) or (@UpdateMinMaxBetv8 = 0 and sporttype=8) or (@UpdateMinMaxBetv10 = 0 and sporttype=10) or (@UpdateMinMaxBetv11 = 0 and sporttype=11) or (@UpdateMinMaxBetv99 = 0 and sporttype=99)) then MaxBet else case sporttype when 1 then @MaxBet when 2 then @MaxBetv2 when 3 then @MaxBetv3 when 5 then @MaxBetv5 when 8 then @MaxBetv8 when 10 then @MaxBetv10 when 11 then @MaxBetv11 when 99 then @MaxBetv99 else maxbet end end
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
					end, @ErrCode = 115	
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
	@UpdateMultiple = @UpdateMultiple,
	@UpdateMinMaxBet = @UpdateMinMaxBet,
	@UpdateMinMaxBetv2 = @UpdateMinMaxBetv2,
	@UpdateMinMaxBetv3 = @UpdateMinMaxBetv3,
	@UpdateMinMaxBetv5 = @UpdateMinMaxBetv5,
	@UpdateMinMaxBetv8 = @UpdateMinMaxBetv8,
	@UpdateMinMaxBetv10 = @UpdateMinMaxBetv10,
	@UpdateMinMaxBetv11 = @UpdateMinMaxBetv11,
	@UpdateMinMaxBetv99 = @UpdateMinMaxBetv99,
	@Language = @Language,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT
	if @ErrCode > 0
	BEGIN
		return
	END

Declare @LogSPData varchar(5000)
Select @LogSPData ='<Acc_CustomerUpdAgent_MinMaxBet custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'MinB="'+ coalesce(cast(@minbet as varchar(50)),space(1)) + '" ' +
'MaxB="'+ coalesce(cast(@maxbet as varchar(50)),space(1)) + '" ' +
'MPM="'+ coalesce(cast(@maxpermatch as varchar(50)),space(1)) + '" ' +
'MinBv2="'+ coalesce(cast(@minbetv2 as varchar(50)),space(1)) + '" ' +
'MaxBv2="'+ coalesce(cast(@maxbetv2 as varchar(50)),space(1)) + '" ' +
'MPMv2="'+ coalesce(cast(@maxpermatchv2 as varchar(50)),space(1)) + '" ' +
'MinBv3="'+ coalesce(cast(@minbetv3 as varchar(50)),space(1)) + '" ' +
'MaxBv3="'+ coalesce(cast(@maxbetv3 as varchar(50)),space(1)) + '" ' +
'MPMv3="'+ coalesce(cast(@maxpermatchv3 as varchar(50)),space(1)) + '" ' +
'MinBv5="'+ coalesce(cast(@minbetv5 as varchar(50)),space(1)) + '" ' +
'MaxBv5="'+ coalesce(cast(@maxbetv5 as varchar(50)),space(1)) + '" ' +
'MPMv5="'+ coalesce(cast(@maxpermatchv5 as varchar(50)),space(1)) + '" ' +
'MinBv8="'+ coalesce(cast(@minbetv8 as varchar(50)),space(1)) + '" ' +
'MaxBv8="'+ coalesce(cast(@maxbetv8 as varchar(50)),space(1)) + '" ' +
'MPMv8="'+ coalesce(cast(@maxpermatchv8 as varchar(50)),space(1)) + '" ' +
'MinBv10="'+ coalesce(cast(@minbetv10 as varchar(50)),space(1)) + '" ' +
'MaxBv10="'+ coalesce(cast(@maxbetv10 as varchar(50)),space(1)) + '" ' +
'MPMv10="'+ coalesce(cast(@maxpermatchv10 as varchar(50)),space(1)) + '" ' +
'MinBv11="'+ coalesce(cast(@minbetv11 as varchar(50)),space(1)) + '" ' +
'MaxBv11="'+ coalesce(cast(@maxbetv11 as varchar(50)),space(1)) + '" ' +
'MPMv11="'+ coalesce(cast(@maxpermatchv11 as varchar(50)),space(1)) + '" ' +
'MinBv99="'+ coalesce(cast(@minbetv99 as varchar(50)),space(1)) + '" ' +
'MaxBv99="'+ coalesce(cast(@maxbetv99 as varchar(50)),space(1)) + '" ' +
'MPMv99="'+ coalesce(cast(@maxpermatchv99 as varchar(50)),space(1)) + '" ' +
'UpdMultiple="'+ coalesce(cast(@UpdateMultiple as varchar(50)),space(1)) + '" ' +
'UMMB="'+ coalesce(cast(@UpdateMinMaxBet as varchar(50)),space(1)) + '" ' +
'UMMBv2="'+ coalesce(cast(@UpdateMinMaxBetv2 as varchar(50)),space(1)) + '" ' +
'UMMBv3="'+ coalesce(cast(@UpdateMinMaxBetv3 as varchar(50)),space(1)) + '" ' +
'UMMBv5="'+ coalesce(cast(@UpdateMinMaxBetv5 as varchar(50)),space(1)) + '" ' +
'UMMBv8="'+ coalesce(cast(@UpdateMinMaxBetv8 as varchar(50)),space(1)) + '" ' +
'UMMBv10="'+ coalesce(cast(@UpdateMinMaxBetv10 as varchar(50)),space(1)) + '" ' +
'UMMBv11="'+ coalesce(cast(@UpdateMinMaxBetv11 as varchar(50)),space(1)) + '" ' +
'UMMBv99="'+ coalesce(cast(@UpdateMinMaxBetv99 as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 306,
	@TrackingValue = @LogSPData

---------------------------------------------------------

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgent_MinMaxBet] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgent_MinMaxBet] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdAgent_MinMaxBet] TO vnteam