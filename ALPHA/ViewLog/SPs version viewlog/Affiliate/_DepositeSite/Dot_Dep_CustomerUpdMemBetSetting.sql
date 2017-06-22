ALTER PROCEDURE [dbo].Dot_Dep_CustomerUpdMemBetSetting
	@CustId int, --MemberID
	
	@UpdateMinMaxBet BIT = 1,	
	@UpdateMinMaxBetv2 BIT = 1,	
	@UpdateMinMaxBetv3 BIT = 1,	
	@UpdateMinMaxBetv5 BIT = 1,	
	@UpdateMinMaxBetv8 BIT = 1,	
	@UpdateMinMaxBetv10 BIT = 1,
	@UpdateMinMaxBetv11 BIT = 1,
	@UpdateMinMaxBetv99 BIT = 1,
	
	@UpdateMinMaxBetv201 BIT = 0,
	@UpdateMinMaxBetv151 BIT = 0,
 
	@MinBet MONEY,
	@MaxBet MONEY,
	@MaxPerMatch MONEY,
	
	@MinBetv2 MONEY,
	@MaxBetv2 MONEY,
	@MaxPerMatchv2 MONEY,

	@MinBetv3 MONEY,
	@MaxBetv3 MONEY,
	@MaxPerMatchv3 MONEY,

	@MinBetv5 MONEY,
	@MaxBetv5 MONEY,
	@MaxPerMatchv5 MONEY,

	@MinBetv8 MONEY,
	@MaxBetv8 MONEY,
	@MaxPerMatchv8 MONEY,

	@MinBetv10 MONEY,
	@MaxBetv10 MONEY,
	@MaxPerMatchv10 MONEY,

	@MinBetv11 MONEY,
	@MaxBetv11 MONEY,
	@MaxPerMatchv11 MONEY,
	
	@MinBetv99 MONEY,
	@MaxBetv99 MONEY,
	@MaxPerMatchv99 MONEY,

	@MinBetv201 MONEY,
	@MaxBetv201 MONEY,
	@MaxPerMatchv201 MONEY,

	@MinBetv151 MONEY,
	@MaxBetv151 MONEY,
	@MaxPerMatchv151 MONEY,

	@userid int, --updater Id	
	@language varchar(2) = 'E',
	@IP varchar(15)='',	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*
Created: 20090721@Phuc (Tommy)
Task : Update member min max bet.
DB: DB02.bodb02

Revisions:
    - 20090402@Phuc: write log for logout.
    - 20091303@Peter : #353 IRP - DBA - Separate HorseRacing and Financial's setting from custsetting and custoverride
	- 20100112@Kiwi: Amend to write log in xml format.
Param's Explanation:
*/

SET NOCOUNT ON

--Check Closed?
Declare @UplineClosed bit
Declare @MinMinBet money, @MaxMaxBet money,	@MaxMaxPerMatch money,
	@MinMinBetv2 money, @MaxMaxBetv2 money, @MaxMaxPerMatchv2 money,
	@MinMinBetv3 money, @MaxMaxBetv3 money, @MaxMaxPerMatchv3 money,
	@MinMinBetv5 money, @MaxMaxBetv5 money, @MaxMaxPerMatchv5 money,
	@MinMinBetv8 money, @MaxMaxBetv8 money, @MaxMaxPerMatchv8 money,
	@MinMinBetv10 money, @MaxMaxBetv10 money, @MaxMaxPerMatchv10 money,
	@MinMinBetv11 money, @MaxMaxBetv11 money, @MaxMaxPerMatchv11 money,
	@MinMinBetv99 money, @MaxMaxBetv99 money, @MaxMaxPerMatchv99 money,

	@MinMinBetv201 money, @MaxMaxBetv201 money, @MaxMaxPerMatchv201 money,
	@MinMinBetv151 money, @MaxMaxBetv151 money, @MaxMaxPerMatchv151 money
	
declare @ErrAcc varchar(4000), @ErrType varchar(4000),
		@UserName varchar(30), @recommend int, @roleid tinyint

select @UplineClosed = isnull(closed,0)
from custinfo (nolock) 
where custid = @UserID 
		
Select @UserName = username, @recommend = recommend, @roleid = roleid
from customer with (NOLOCK)
where CustID = @CustID

if isnull(@roleid,0) <> 1
begin
	Select @ErrMsg = case @Language 
						when 'E' then 'Invalid user!!'
						when 'CS' then N'账号无效.'
						when 'CT' then N'帳號無效.'
						when 'TH' then N'ผู้ใช้ไม่ถูกต้อง!!'
						when 'J' then N'Invalid user!!'
						when 'KO' then N'잘못된 사용자 입니다!!'
						else N'Invalid user!!'
					end	,
		@ErrCode = 100	
	return
end

IF @UplineClosed = 1 
BEGIN
	SELECT @ErrMsg =  CASE @Language 
						WHEN 'E' THEN 'Your account was closed. Cannot edit member.'
						WHEN 'CS' THEN N'您的账号已关闭，无法更改会员.'
						WHEN 'CT' THEN N'您的帳戶已關閉. 無法更改會員.'
						WHEN 'TH' THEN N'บัญชีของคุณถูกระงับใช้ ไม่สามารถแก้ไข.'
						WHEN 'J' THEN N'貴方のアカウントは閉鎖されています。新規メンバーの受付はできません。'
						WHEN 'KO' THEN N'계정이용이 정지되었습니다. 회원정보를 수정 할 수 없습니다.'
						ELSE N'Your account was closed. Cannot edit member.'
					END, @ErrCode = 100
	return
END 


----------------------------------------------
--Update MinBet, MaxBet, MaxPerMatch
----------------------------------------------
--Check Param
if @UpdateMinMaxBet = 1 
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
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬาเทนนิส).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Soccer).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (축구).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Soccer).'
					end
		return
	END
END

if @UpdateMinMaxBetv2 = 1 
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

if @UpdateMinMaxBetv3 = 1 
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

if @UpdateMinMaxBetv5 = 1
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

if @UpdateMinMaxBetv8 = 1 
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

if @UpdateMinMaxBetv10 = 1 
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

if @UpdateMinMaxBetv11 = 1 
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

if @UpdateMinMaxBetv99 = 1
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

if @UpdateMinMaxBetv201 = 1
BEGIN
	if 
		@MinBetv201 <0
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
END

if @UpdateMinMaxBetv151 = 1
BEGIN
	if 
		@MinBetv151 <0
		or @MaxBetv151 <0
		or @MaxPerMatchv151 <0		
	BEGIN
		select @ErrCode = 3
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Horse Racing).'
							when 'CS' then N'Wrong Min bet/ Max bet/ Max per match (for Horse Racing).'
							when 'CT' then N'Wrong Min bet/ Max bet/ Max per match (for Horse Racing).'
							when 'TH' then N'Wrong Min bet/ Max bet/ Max per match (for Horse Racing).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Other sports).'
							when 'KO' then N'Wrong Min bet/ Max bet/ Max per match (for Horse Racing).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Horse Racing).'
					end
		return
	END
END

Select
	@MinMinBet = Max(case when MinBet = 0 then NULL else MinBet end), 
	@MaxMaxBet = Min(case when MaxBet = 0 then NULL else MaxBet end)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
	and cs.bettype = 1 and cs.sporttype=1
where ci.custid = @recommend

Select 
	@MinMinBetv2 = Max(case when MinBet = 0 then NULL else MinBet end), 
	@MaxMaxBetv2 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
	and cs.bettype = 1 and cs.sporttype=2
where ci.custid = @recommend

Select 
	@MinMinBetv3 = Max(case when MinBet = 0 then NULL else MinBet end), 
	@MaxMaxBetv3 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
	and cs.bettype = 1 and cs.sporttype=3
where ci.custid = @recommend

Select 
	@MinMinBetv5 = Max(case when MinBet = 0 then NULL else MinBet end), 
	@MaxMaxBetv5 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
	and cs.bettype = 1 and cs.sporttype=5
where ci.custid = @recommend

Select 
	@MinMinBetv8 = Max(case when MinBet = 0 then NULL else MinBet end), 
	@MaxMaxBetv8 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
	and cs.bettype = 1 and cs.sporttype=8
where ci.custid = @recommend

Select 
	@MinMinBetv10 = Max(case when MinBet = 0 then NULL else MinBet end), 
	@MaxMaxBetv10 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
	and cs.bettype = 1 and cs.sporttype=10
where ci.custid = @recommend

Select 
	@MinMinBetv11 = Max(case when MinBet = 0 then NULL else MinBet end), 
	@MaxMaxBetv11 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
	and cs.bettype = 1 and cs.sporttype=11
where ci.custid = @recommend

Select 
	@MinMinBetv99 = Max(case when MinBet = 0 then NULL else MinBet end), 
	@MaxMaxBetv99 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
	and cs.bettype = 1 and cs.sporttype=99
where ci.custid = @recommend

Select 
	@MinMinBetv201 = Max(case when MinBet = 0 then NULL else MinBet end), 
	@MaxMaxBetv201 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from 
	custsetting3rd as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
	and cs.bettype = 2 and cs.sporttype=201
where ci.custid = @recommend

Select 
	@MinMinBetv151 = Max(case when MinBet = 0 then NULL else MinBet end), 
	@MaxMaxBetv151 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from 
	custsetting3rd as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
	and cs.bettype = 31 and cs.sporttype=151
where ci.custid = @recommend


Select 
	@MaxMaxperMatch = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end), 
	@MaxMaxPerMatchv2 = Min(case when cs.MaxPerMatch2 = 0 then NULL else cs.MaxPerMatch2 end), 
	@MaxMaxPerMatchv3 = Min(case when cs.MaxPerMatch3 = 0 then NULL else cs.MaxPerMatch3 end), 
	@MaxMaxPerMatchv5 = Min(case when cs.MaxPerMatch5 = 0 then NULL else cs.MaxPerMatch5 end), 
	@MaxMaxPerMatchv8 = Min(case when cs.MaxPerMatch8 = 0 then NULL else cs.MaxPerMatch8 end), 
	@MaxMaxPerMatchv10 = Min(case when cs.MaxPerMatch10 = 0 then NULL else cs.MaxPerMatch10 end), 
	@MaxMaxPerMatchv11 = Min(case when cs.MaxPerMatch11 = 0 then NULL else cs.MaxPerMatch11 end), 	
	@MaxMaxPerMatchv99 = Min(case when cs.MaxPerMatch99 = 0 then NULL else cs.MaxPerMatch99 end),
	
	@MaxMaxPerMatchv201 = Min(case when cs.MaxPerMatch201 = 0 then NULL else cs.MaxPerMatch201 end),
	@MaxMaxPerMatchv151 = Min(case when cs.MaxPerMatch151 = 0 then NULL else cs.MaxPerMatch151 end)
from 
	custinfo as cs WITH (NOLOCK) 
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
where ci.custid = @recommend


IF @UpdateMinMaxBet = 1
BEGIN
	if ((@MinBet<>0 or @MaxBet<>0 or @MaxPerMatch<>0) AND (@MinBet>@MaxBet OR @MaxBet>@MaxPerMatch))
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม.'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다.'
							else N'min bet must be less than max bet and max bet must be less than max bet per match'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBet) + '-' + convert(varchar(20), @MaxBet) + '-' + convert(varchar(20), @MaxPerMatch), @ErrCode = 108
			
		return
		
	END
	
	IF (@MinMinBet>0 AND @MinBet>0 AND @MinBet<@MinMinBet)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': ' +
						CASE @Language 
							WHEN 'E' THEN 'min bet must be equal to or greater than Agent min bet'
							WHEN 'CS' THEN N'最低投注需相等于或少于代理最低投注'
							WHEN 'CT' THEN N'最低投注需相等於或少於代理最低投注'
							WHEN 'TH' THEN N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้ของตัวแทน'
							WHEN 'J' THEN N'min bet must be equal to or greater than Agent min bet'
							WHEN 'KO' THEN N'최소 배팅은 에이전트의 최소 배팅 이상이여야 합니다.'
							ELSE N'min bet must be equal to or greater than Agent min bet'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBet) + ').', @ErrCode = 109
				
		return
	END
	
	IF (@MaxMaxBet>0 AND @MaxBet>0 AND @MaxBet>@MaxMaxBet)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'max bet must be equal to or less than Agent max bet'
							WHEN 'CS' THEN N'最高投注需相等于或少于代理最高投注'
							WHEN 'CT' THEN N'最高投注需相等於或少於代理最高投注'
							WHEN 'TH' THEN N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทน '
							WHEN 'J' THEN N'max bet must be equal to or less than Agent max bet'
							WHEN 'KO' THEN N'최대 배팅은 에이전트의 최대 배팅 이하이여야 합니다.'
							ELSE N'max bet must be equal to or less than Agent max bet'
						END						
						+'(' + CONVERT(VARCHAR(20), @MaxMaxBet) + ').', @ErrCode = 110
				
		return
	END
	
	IF (@MaxMaxPerMatch>0 AND @MaxPerMatch>0 AND @MaxPerMatch>@MaxMaxPerMatch)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match'
							WHEN 'CS' THEN N'单场最高投注需相等于或少于代理单场最高投注'
							WHEN 'CT' THEN N'單場最高投注需相等於或少於代理單場最高投注'
							WHEN 'TH' THEN N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทน  '
							WHEN 'J' THEN N'Max Per Match must be equal to or less than Agent Max Per Match'
							WHEN 'KO' THEN N'최대 경기는 에이전트의 최대 경기보다 작아야 합니다.'
							ELSE N'Max Per Match must be equal to or less than Agent Max Per Match'
						END						
						+'(' + CONVERT(VARCHAR(20), @MaxMaxPerMatch) + ').', @ErrCode = 110
				
		return
	END

END

IF @UpdateMinMaxBetv2 = 1
BEGIN
	if ((@MinBetv2<>0 or @MaxBetv2<>0 or @MaxPerMatchv2<>0) AND (@MinBetv2>@MaxBetv2 OR @MaxBetv2>@MaxPerMatchv2))
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Basketball)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于篮球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於籃球)'
							WHEN 'TH' THEN N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาบาสเก็ตบอล)'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Basketball)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (농구)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Basketball)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv2) + '-' + convert(varchar(20), @MaxBetv2) + '-' + convert(varchar(20), @MaxPerMatchv2), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv2>0 AND @MinBetv2>0 AND @MinBetv2<@MinMinBetv2)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'min bet must be equal to or greater than Agent min bet (for Basketball)'
							WHEN 'CS' THEN N'最低投注需相等于或少于代理最低投注(于篮球)'
							WHEN 'CT' THEN N'最低投注需相等於或少於代理最低投注(於籃球)'
							WHEN 'TH' THEN N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้ของตัวแทน (สำหรับกีฬาบาสเก็ตบอล)'
							WHEN 'J' THEN N'min bet must be equal to or greater than Agent min bet (for Basketball)'
							WHEN 'KO' THEN N'최소 배팅은 에이전트의 최소 배팅 이상이여야 합니다 (농구)'
							ELSE N'min bet must be equal to or greater than Agent min bet (for Basketball)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv2) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv2>0 AND @MaxBetv2>0 AND @MaxBetv2>@MaxMaxBetv2)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'max bet must be equal to or less than Agent max bet (for Basketball)'
							WHEN 'CS' THEN N'最高投注需相等于或少于代理最高投注(于篮球)'
							WHEN 'CT' THEN N'最高投注需相等於或少於代理最高投注(於籃球)'
							WHEN 'TH' THEN N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทน (สำหรับกีฬาบาสเก็ตบอล)'
							WHEN 'J' THEN N'max bet must be equal to or less than Agent max bet (for Basketball)'
							WHEN 'KO' THEN N'최대 배팅은 에이전트의 최대 배팅 이하이여야 합니다 (농구)'
							ELSE N'max bet must be equal to or less than Agent max bet (for Basketball)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv2) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv2>0 AND @MaxPerMatchv2>0 AND @MaxPerMatchv2>@MaxMaxPerMatchv2)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Basketball)'
							WHEN 'CS' THEN N'单场最高投注需相等于或少于代理单场最高投注(于篮球)'
							WHEN 'CT' THEN N'單場最高投注需相等於或少於代理單場最高投注(於籃球)'
							WHEN 'TH' THEN N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทน (สำหรับกีฬาบาสเก็ตบอล)  '
							WHEN 'J' THEN N'Max Per Match must be equal to or less than Agent Max Per Match (for Basketball)'
							WHEN 'KO' THEN N'최대 경기는 에이전트의 최대 경기보다 작아야 합니다 (농구)'
							ELSE N'Max Per Match must be equal to or less than Agent Max Per Match (for Basketball)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv2) + ').', @ErrCode = 113
				
		return
	END
END

IF @UpdateMinMaxBetv3 = 1
BEGIN
	if ((@MinBetv3<>0 or @MaxBetv3<>0 or @MaxPerMatchv3<>0) AND (@MinBetv3>@MaxBetv3 OR @MaxBetv3>@MaxPerMatchv3))
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Football)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于美式足球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於美式足球)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาอเมริกันฟุตบอล)'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Football)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (풋볼)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Football)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv3) + '-' + convert(varchar(20), @MaxBetv3) + '-' + convert(varchar(20), @MaxPerMatchv3), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv3>0 AND @MinBetv3>0 AND @MinBetv3<@MinMinBetv3)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'min bet must be equal to or greater than Agent min bet (for Football)'
							WHEN 'CS' THEN N'最低投注需相等于或少于代理最低投注(于美式足球)'
							WHEN 'CT' THEN N'最低投注需相等於或少於代理最低投注(於美式足球)'
							WHEN 'TH' THEN N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้ของตัวแทน (สำหรับกีฬาอเมริกันฟุตบอล)'
							WHEN 'J' THEN N'min bet must be equal to or greater than Agent min bet (for Football)'
							WHEN 'KO' THEN N'최소 배팅은 에이전트의 최소 배팅 이상이여야 합니다 (풋볼)'
							ELSE N'min bet must be equal to or greater than Agent min bet (for Football)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv3) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv3>0 AND @MaxBetv3>0 AND @MaxBetv3>@MaxMaxBetv3)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'max bet must be equal to or less than Agent max bet (for Football)'
							WHEN 'CS' THEN N'最高投注需相等于或少于代理最高投注(于美式足球)'
							WHEN 'CT' THEN N'最高投注需相等於或少於代理最高投注(於美式足球)'
							WHEN 'TH' THEN N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทน (สำหรับกีฬาอเมริกันฟุตบอล)'
							WHEN 'J' THEN N'max bet must be equal to or less than Agent max bet (for Football)'
							WHEN 'KO' THEN N'최대 배팅은 에이전트의 최대 배팅 이하이여야 합니다 (풋볼)'
							ELSE N'max bet must be equal to or less than Agent max bet (for Football)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv3) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv3>0 AND @MaxPerMatchv3>0 AND @MaxPerMatchv3>@MaxMaxPerMatchv3)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Football)'
							WHEN 'CS' THEN N'单场最高投注需相等于或少于代理单场最高投注(于美式足球)'
							WHEN 'CT' THEN N'單場最高投注需相等於或少於代理單場最高投注(於美式足球)'
							WHEN 'TH' THEN N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทน (สำหรับกีฬาอเมริกันฟุตบอล) '
							WHEN 'J' THEN N'Max Per Match must be equal to or less than Agent Max Per Match (for Football)'
							WHEN 'KO' THEN N'최대 경기는 에이전트의 최대 경기보다 작아야 합니다 (풋볼)'
							ELSE N'Max Per Match must be equal to or less than Agent Max Per Match (for Football)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv3) + ').', @ErrCode = 113
				
		return
	END
END

IF @UpdateMinMaxBetv5 = 1
BEGIN
	if ((@MinBetv5<>0 or @MaxBetv5<>0 or @MaxPerMatchv5<>0) AND (@MinBetv5>@MaxBetv5 OR @MaxBetv5>@MaxPerMatchv5))
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Tennis)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于网球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於網球)'
							WHEN 'TH' THEN N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาเทนนิส)'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Tennis)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (테니스)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Tennis)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv5) + '-' + convert(varchar(20), @MaxBetv5) + '-' + convert(varchar(20), @MaxPerMatchv5), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv5>0 AND @MinBetv5>0 AND @MinBetv5<@MinMinBetv5)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'min bet must be equal to or greater than Agent min bet (for Tennis)'
							WHEN 'CS' THEN N'最低投注需相等于或少于代理最低投注(于网球)'
							WHEN 'CT' THEN N'最低投注需相等於或少於代理最低投注(於網球)'
							WHEN 'TH' THEN N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้ของตัวแทน (สำหรับกีฬาเทนนิส)'
							WHEN 'J' THEN N'min bet must be equal to or greater than Agent min bet (for Tennis)'
							WHEN 'KO' THEN N'최소 배팅은 에이전트의 최소 배팅 이상이여야 합니다 (테니스)'
							ELSE N'min bet must be equal to or greater than Agent min bet (for Tennis)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv5) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv5>0 AND @MaxBetv5>0 AND @MaxBetv5>@MaxMaxBetv5)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'max bet must be equal to or less than Agent max bet (for Tennis)'
							WHEN 'CS' THEN N'最高投注需相等于或少于代理最高投注(于网球)'
							WHEN 'CT' THEN N'最高投注需相等於或少於代理最高投注(於網球)'
							WHEN 'TH' THEN N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทน (สำหรับกีฬาเทนนิส)'
							WHEN 'J' THEN N'max bet must be equal to or less than Agent max bet (for Tennis)'
							WHEN 'KO' THEN N'최대 배팅은 에이전트의 최대 배팅 이하이여야 합니다 (테니스)'
							ELSE N'max bet must be equal to or less than Agent max bet (for Tennis)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv5) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv5>0 AND @MaxPerMatchv5>0 AND @MaxPerMatchv5>@MaxMaxPerMatchv5)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match  (for Tennis)'
							WHEN 'CS' THEN N'单场最高投注需相等于或少于代理单场最高投注(于网球)'
							WHEN 'CT' THEN N'單場最高投注需相等於或少於代理單場最高投注(於網球)'
							WHEN 'TH' THEN N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทน (สำหรับกีฬาเทนนิส)  '
							WHEN 'J' THEN N'Max Per Match must be equal to or less than Agent Max Per Match  (for Tennis)'
							WHEN 'KO' THEN N'최대 경기는 에이전트의 최대 경기보다 작아야 합니다 (테니스)'
							ELSE N'Max Per Match must be equal to or less than Agent Max Per Match  (for Tennis)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv5) + ').', @ErrCode = 113
				
		return
	END
END

IF @UpdateMinMaxBetv8 = 1
BEGIN
	if ((@MinBetv8<>0 or @MaxBetv8<>0 or @MaxPerMatchv8<>0) AND (@MinBetv8>@MaxBetv8 OR @MaxBetv8>@MaxPerMatchv8))
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Baseball)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于棒球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於棒球)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาเบสบอล)'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Baseball)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (야구)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Baseball)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv8) + '-' + convert(varchar(20), @MaxBetv8) + '-' + convert(varchar(20), @MaxPerMatchv8), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv8>0 AND @MinBetv8>0 AND @MinBetv8<@MinMinBetv8)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'min bet must be equal to or greater than Agent min bet (for Baseball)'
							WHEN 'CS' THEN N'最低投注需相等于或少于代理最低投注(于棒球)'
							WHEN 'CT' THEN N'最低投注需相等於或少於代理最低投注(於棒球)'
							WHEN 'TH' THEN N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้ของตัวแทน (สำหรับกีฬาเบสบอล)'
							WHEN 'J' THEN N'min bet must be equal to or greater than Agent min bet (for Baseball)'
							WHEN 'KO' THEN N'최소 배팅은 에이전트의 최소 배팅 이상이여야 합니다 (야구)'
							ELSE N'min bet must be equal to or greater than Agent min bet (for Baseball)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv8) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv8>0 AND @MaxBetv8>0 AND @MaxBetv8>@MaxMaxBetv8)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'max bet must be equal to or less than Agent max bet (for Baseball)'
							WHEN 'CS' THEN N'最高投注需相等于或少于代理最高投注(于棒球)'
							WHEN 'CT' THEN N'最高投注需相等於或少於代理最高投注(於棒球)'
							WHEN 'TH' THEN N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทน (สำหรับกีฬาเบสบอล)'
							WHEN 'J' THEN N'max bet must be equal to or less than Agent max bet (for Baseball)'
							WHEN 'KO' THEN N'최대 배팅은 에이전트의 최대 배팅 이하이여야 합니다 (야구)'
							ELSE N'max bet must be equal to or less than Agent max bet (for Baseball)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv8) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv8>0 AND @MaxPerMatchv8>0 AND @MaxPerMatchv8>@MaxMaxPerMatchv8)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Baseball)'
							WHEN 'CS' THEN N'单场最高投注需相等于或少于代理单场最高投注(于棒球)'
							WHEN 'CT' THEN N'單場最高投注需相等於或少於代理單場最高投注(於棒球)'
							WHEN 'TH' THEN N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทน (สำหรับกีฬาเบสบอล)  '
							WHEN 'J' THEN N'Max Per Match must be equal to or less than Agent Max Per Match (for Baseball)'
							WHEN 'KO' THEN N'최대 경기는 에이전트의 최대 경기보다 작아야 합니다 (야구)'
							ELSE N'Max Per Match must be equal to or less than Agent Max Per Match (for Baseball)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv8) + ').', @ErrCode = 113
				
		return
	END
END

IF @UpdateMinMaxBetv10 = 1
BEGIN
	if ((@MinBetv10<>0 or @MaxBetv10<>0 or @MaxPerMatchv10<>0) AND (@MinBetv10>@MaxBetv10 OR @MaxBetv10>@MaxPerMatchv10))
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Golf)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于高尔夫球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於高爾夫球)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬากอฟล์)'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Golf)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (골프)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Golf)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv10) + '-' + convert(varchar(20), @MaxBetv10) + '-' + convert(varchar(20), @MaxPerMatchv10), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv10>0 AND @MinBetv10>0 AND @MinBetv10<@MinMinBetv10)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'min bet must be equal to or greater than Agent min bet (for Golf)'
							WHEN 'CS' THEN N'最低投注需相等于或少于代理最低投注(于高尔夫球)'
							WHEN 'CT' THEN N'最低投注需相等於或少於代理最低投注(於高爾夫球)'
							WHEN 'TH' THEN N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้ของตัวแทน (สำหรับกีฬากอฟล์)'
							WHEN 'J' THEN N'min bet must be equal to or greater than Agent min bet (for Golf)'
							WHEN 'KO' THEN N'최소 배팅은 에이전트의 최소 배팅 이상이여야 합니다 (골프)'
							ELSE N'min bet must be equal to or greater than Agent min bet (for Golf)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv10) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv10>0 AND @MaxBetv10>0 AND @MaxBetv10>@MaxMaxBetv10)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'max bet must be equal to or less than Agent max bet (for Golf)'
							WHEN 'CS' THEN N'最高投注需相等于或少于代理最高投注(于高尔夫球)'
							WHEN 'CT' THEN N'最高投注需相等於或少於代理最高投注(於高爾夫球)'
							WHEN 'TH' THEN N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทน (สำหรับกีฬากอฟล์)'
							WHEN 'J' THEN N'max bet must be equal to or less than Agent max bet (for Golf)'
							WHEN 'KO' THEN N'최대 배팅은 에이전트의 최대 배팅 이하이여야 합니다 (골프)'
							ELSE N'max bet must be equal to or less than Agent max bet (for Golf)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv10) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv10>0 AND @MaxPerMatchv10>0 AND @MaxPerMatchv10>@MaxMaxPerMatchv10)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Golf)'
							WHEN 'CS' THEN N'单场最高投注需相等于或少于代理单场最高投注(于高尔夫球)'
							WHEN 'CT' THEN N'單場最高投注需相等於或少於代理單場最高投注(於高爾夫球)'
							WHEN 'TH' THEN N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทน (สำหรับกีฬากอฟล์) '
							WHEN 'J' THEN N'Max Per Match must be equal to or less than Agent Max Per Match (for Golf)'
							WHEN 'KO' THEN N'최대 경기는 에이전트의 최대 경기보다 작아야 합니다 (골프)'
							ELSE N'Max Per Match must be equal to or less than Agent Max Per Match (for Golf)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv10) + ').', @ErrCode = 113
				
		return
	END
END

IF @UpdateMinMaxBetv11 = 1
BEGIN
	if ((@MinBetv11<>0 or @MaxBetv11<>0 or @MaxPerMatchv11<>0) AND (@MinBetv11>@MaxBetv11 OR @MaxBetv11>@MaxPerMatchv11))
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Motorsports)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于赛车)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於賽車)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬารถแข่ง)'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Motorsports)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (모토스포츠)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Motorsports)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv11) + '-' + convert(varchar(20), @MaxBetv11) + '-' + convert(varchar(20), @MaxPerMatchv11), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv11>0 AND @MinBetv11>0 AND @MinBetv11<@MinMinBetv11)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'min bet must be equal to or greater than Agent min bet (for Motorsports)'
							WHEN 'CS' THEN N'最低投注需相等于或少于代理最低投注(于赛车)'
							WHEN 'CT' THEN N'最低投注需相等於或少於代理最低投注(於賽車)'
							WHEN 'TH' THEN N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้ของตัวแทน (สำหรับกีฬารถแข่ง)'
							WHEN 'J' THEN N'min bet must be equal to or greater than Agent min bet (for Motorsports)'
							WHEN 'KO' THEN N'최소 배팅은 에이전트의 최소 배팅 이상이여야 합니다 (모토스포츠)'
							ELSE N'min bet must be equal to or greater than Agent min bet (for Motorsports)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv11) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv11>0 AND @MaxBetv11>0 AND @MaxBetv11>@MaxMaxBetv11)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'max bet must be equal to or less than Agent max bet (for Motorsports)'
							WHEN 'CS' THEN N'最高投注需相等于或少于代理最高投注(于赛车)'
							WHEN 'CT' THEN N'最高投注需相等於或少於代理最高投注(於賽車)'
							WHEN 'TH' THEN N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทน (สำหรับกีฬารถแข่ง)'
							WHEN 'J' THEN N'max bet must be equal to or less than Agent max bet (for Motorsports)'
							WHEN 'KO' THEN N'최대 배팅은 에이전트의 최대 배팅 이하이여야 합니다 (모토스포츠)'
							ELSE N'max bet must be equal to or less than Agent max bet (for Motorsports)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv11) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv11>0 AND @MaxPerMatchv11>0 AND @MaxPerMatchv11>@MaxMaxPerMatchv11)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Motorsports)'
							WHEN 'CS' THEN N'单场最高投注需相等于或少于代理单场最高投注(于赛车)'
							WHEN 'CT' THEN N'單場最高投注需相等於或少於代理單場最高投注(於賽車)'
							WHEN 'TH' THEN N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทน (สำหรับกีฬารถแข่ง) '
							WHEN 'J' THEN N'Max Per Match must be equal to or less than Agent Max Per Match (for Motorsports)'
							WHEN 'KO' THEN N'최대 경기는 에이전트의 최대 경기보다 작아야 합니다 (모토스포츠)'
							ELSE N'Max Per Match must be equal to or less than Agent Max Per Match (for Motorsports)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv11) + ').', @ErrCode = 113
				
		return
	END
END

IF @UpdateMinMaxBetv99 = 1
BEGIN
	if ((@MinBetv99<>0 or @MaxBetv99<>0 or @MaxPerMatchv99<>0) AND (@MinBetv99>@MaxBetv99 OR @MaxBetv99>@MaxPerMatchv99))
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Other sports)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于其他)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於其他)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาอื่นๆ)'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Other sports)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (기타 스포츠)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Other sports)'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv99) + '-' + convert(varchar(20), @MaxBetv99) + '-' + convert(varchar(20), @MaxPerMatchv99), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv99>0 AND @MinBetv99>0 AND @MinBetv99<@MinMinBetv99)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'min bet must be equal to or greater than Agent min bet (for Other sports)'
							WHEN 'CS' THEN N'最低投注需相等于或少于代理最低投注(于其他)'
							WHEN 'CT' THEN N'最低投注需相等於或少於代理最低投注(於其他)'
							WHEN 'TH' THEN N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้ของตัวแทน (สำหรับกีฬาอื่นๆ)'
							WHEN 'J' THEN N'min bet must be equal to or greater than Agent min bet (for Other sports)'
							WHEN 'KO' THEN N'최소 배팅은 에이전트의 최소 배팅 이상이여야 합니다 (기타 스포츠)'
							ELSE N'min bet must be equal to or greater than Agent min bet (for Other sports)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv99) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv99>0 AND @MaxBetv99>0 AND @MaxBetv99>@MaxMaxBetv99)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'max bet must be equal to or less than Agent max bet (for Other sports)'
							WHEN 'CS' THEN N'最高投注需相等于或少于代理最高投注(于其他)'
							WHEN 'CT' THEN N'最高投注需相等於或少於代理最高投注(於其他)'
							WHEN 'TH' THEN N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทน (สำหรับกีฬาอื่นๆ)'
							WHEN 'J' THEN N'max bet must be equal to or less than Agent max bet (for Other sports)'
							WHEN 'KO' THEN N'최대 배팅은 에이전트의 최대 배팅 이하이여야 합니다 (기타 스포츠)'
							ELSE N'max bet must be equal to or less than Agent max bet (for Other sports)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv99) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv99>0 AND @MaxPerMatchv99>0 AND @MaxPerMatchv99>@MaxMaxPerMatchv99)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Other sports)'
							WHEN 'CS' THEN N'单场最高投注需相等于或少于代理单场最高投注(于其他)'
							WHEN 'CT' THEN N'單場最高投注需相等於或少於代理單場最高投注(於其他)'
							WHEN 'TH' THEN N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทน (สำหรับกีฬาอื่นๆ) '
							WHEN 'J' THEN N'Max Per Match must be equal to or less than Agent Max Per Match (for Other sports)'
							WHEN 'KO' THEN N'최대 경기는 에이전트의 최대 경기보다 작아야 합니다 (기타 스포츠)'
							ELSE N'Max Per Match must be equal to or less than Agent Max Per Match (for Other sports)'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv99) + ').', @ErrCode = 113
				
		return
	END
END

--v201
IF @UpdateMinMaxBetv201 = 1
BEGIN
	if ((@MinBetv201<>0 or @MaxBetv201<>0 or @MaxPerMatchv201<>0) AND (@MinBetv201>@MaxBetv201 OR @MaxBetv201>@MaxPerMatchv201))
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Finance) '
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于金融)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於金融)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับการเงิน)'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Finance) '
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (금융) '
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Finance) '
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv201) + '-' + convert(varchar(20), @MaxBetv201) + '-' + convert(varchar(20), @MaxPerMatchv201), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv201>0 AND @MinBetv201>0 AND @MinBetv201<@MinMinBetv201)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'min bet must be equal to or greater than Agent min bet (for Finance) '
							WHEN 'CS' THEN N'最低投注需相等于或少于代理最低投注(于金融)'
							WHEN 'CT' THEN N'最低投注需相等於或少於代理最低投注(於金融)'
							WHEN 'TH' THEN N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่าจำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้ของตัวแทน (สำหรับการเงิน)'
							WHEN 'J' THEN N'min bet must be equal to or greater than Agent min bet (for Finance) '
							WHEN 'KO' THEN N'최소 배팅은 에이전트의 최소 배팅 이상이여야 합니다 (금융) '
							ELSE N'min bet must be equal to or greater than Agent min bet (for Finance) '
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv201) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv201>0 AND @MaxBetv201>0 AND @MaxBetv201>@MaxMaxBetv201)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'max bet must be equal to or less than Agent max bet (for Finance) '
							WHEN 'CS' THEN N'最高投注需相等于或少于代理最高投注(于金融)'
							WHEN 'CT' THEN N'最高投注需相等於或少於代理最高投注(於金融)'
							WHEN 'TH' THEN N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทน (สำหรับการเงิน)'
							WHEN 'J' THEN N'max bet must be equal to or less than Agent max bet (for Finance) '
							WHEN 'KO' THEN N'최대 배팅은 에이전트의 최대 배팅 이하이여야 합니다 (금융) '
							ELSE N'max bet must be equal to or less than Agent max bet (for Finance) '
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv201) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv201>0 AND @MaxPerMatchv201>0 AND @MaxPerMatchv201>@MaxMaxPerMatchv201)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match  (for Finance) '
							WHEN 'CS' THEN N'单场最高投注需相等于或少于代理单场最高投注(于金融)'
							WHEN 'CT' THEN N'單場最高投注需相等於或少於代理單場最高投注(於金融)'
							WHEN 'TH' THEN N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทน (สำหรับการเงิน)'
							WHEN 'J' THEN N'Max Per Match must be equal to or less than Agent Max Per Match  (for Finance) '
							WHEN 'KO' THEN N'최대 경기는 에이전트의 최대 경기보다 작아야 합니다 (금융) '
							ELSE N'Max Per Match must be equal to or less than Agent Max Per Match  (for Finance) '
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv201) + ').', @ErrCode = 113
				
		return
	END
END

--v151
IF @UpdateMinMaxBetv151 = 1
BEGIN
	if ((@MinBetv151<>0 or @MaxBetv151<>0 or @MaxPerMatchv151<>0) AND (@MinBetv151>@MaxBetv151 OR @MaxBetv151>@MaxPerMatchv151))
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Horse Racing) '
							when 'CS' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Horse Racing)'
							when 'CT' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Horse Racing)'
							when 'TH' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Horse Racing)'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Horse Racing)'
							when 'KO' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Horse Racing)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Horse Racing) '
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv151) + '-' + convert(varchar(20), @MaxBetv151) + '-' + convert(varchar(20), @MaxPerMatchv151), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv151>0 AND @MinBetv151>0 AND @MinBetv151<@MinMinBetv151)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'min bet must be equal to or greater than Agent min bet (for Horse Racing) '
							WHEN 'CS' THEN N'min bet must be equal to or greater than Agent min bet (for Horse Racing)'
							WHEN 'CT' THEN N'min bet must be equal to or greater than Agent min bet (for Horse Racing)'
							WHEN 'TH' THEN N'min bet must be equal to or greater than Agent min bet (for Horse Racing)'
							WHEN 'J' THEN N'min bet must be equal to or greater than Agent min bet (for Horse Racing) '
							WHEN 'KO' THEN N'min bet must be equal to or greater than Agent min bet (for Horse Racing) '
							ELSE N'min bet must be equal to or greater than Agent min bet (for Horse Racing) '
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv151) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv151>0 AND @MaxBetv151>0 AND @MaxBetv151>@MaxMaxBetv151)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'max bet must be equal to or less than Agent max bet (for Horse Racing) '
							WHEN 'CS' THEN N'max bet must be equal to or less than Agent max bet (for Horse Racing)'
							WHEN 'CT' THEN N'max bet must be equal to or less than Agent max bet (for Horse Racing)'
							WHEN 'TH' THEN N'max bet must be equal to or less than Agent max bet (for Horse Racing)'
							WHEN 'J' THEN N'max bet must be equal to or less than Agent max bet (for Horse Racing) '
							WHEN 'KO' THEN N'max bet must be equal to or less than Agent max bet (for Horse Racing) '
							ELSE N'max bet must be equal to or less than Agent max bet (for Horse Racing) '
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv151) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv151>0 AND @MaxPerMatchv151>0 AND @MaxPerMatchv151>@MaxMaxPerMatchv151)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match  (for Horse Racing) '
							WHEN 'CS' THEN N'Max Per Match must be equal to or less than Agent Max Per Match  (for Horse Racing) '
							WHEN 'CT' THEN N'Max Per Match must be equal to or less than Agent Max Per Match  (for Horse Racing) '
							WHEN 'TH' THEN N'Max Per Match must be equal to or less than Agent Max Per Match  (for Horse Racing) '
							WHEN 'J' THEN N'Max Per Match must be equal to or less than Agent Max Per Match  (for Horse Racing) '
							WHEN 'KO' THEN N'Max Per Match must be equal to or less than Agent Max Per Match  (for Horse Racing) '
							ELSE N'Max Per Match must be equal to or less than Agent Max Per Match  (for Horse Racing)  '
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv151) + ').', @ErrCode = 113
				
		return
	END
END


----------
UPDATE custsetting WITH (ROWLOCK, UPDLOCK)
SET
	MinBet = CASE WHEN (@UpdateMinMaxBet = 1 AND sporttype=1) THEN @MinBet
				WHEN (@UpdateMinMaxBetv2 = 1 AND sporttype=2) THEN @MinBetv2
				WHEN (@UpdateMinMaxBetv3 = 1 AND sporttype=3) THEN @MinBetv3
				WHEN (@UpdateMinMaxBetv5 = 1 AND sporttype=5) THEN @MinBetv5
				WHEN (@UpdateMinMaxBetv8 = 1 AND sporttype=8) THEN @MinBetv8
				WHEN (@UpdateMinMaxBetv10 = 1 AND sporttype=10) THEN @MinBetv10
				WHEN (@UpdateMinMaxBetv11 = 1 AND sporttype=11) THEN @MinBetv11				
				WHEN (@UpdateMinMaxBetv99 = 1 AND sporttype=99) THEN @MinBetv99				
			ELSE minbet END,
	MaxBet = CASE WHEN (@UpdateMinMaxBet = 1 AND sporttype=1) THEN @MaxBet
				WHEN (@UpdateMinMaxBetv2 = 1 AND sporttype=2) THEN @MaxBetv2
				WHEN (@UpdateMinMaxBetv3 = 1 AND sporttype=3) THEN @MaxBetv3
				WHEN (@UpdateMinMaxBetv5 = 1 AND sporttype=5) THEN @MaxBetv5
				WHEN (@UpdateMinMaxBetv8 = 1 AND sporttype=8) THEN @MaxBetv8
				WHEN (@UpdateMinMaxBetv10 = 1 AND sporttype=10) THEN @MaxBetv10
				WHEN (@UpdateMinMaxBetv11 = 1 AND sporttype=11) THEN @MaxBetv11				
				WHEN (@UpdateMinMaxBetv99 = 1 AND sporttype=99) THEN @MaxBetv99				
			ELSE MaxBet END
WHERE custid=@custid

UPDATE custsetting3rd WITH (ROWLOCK, UPDLOCK)
SET
	MinBet = CASE WHEN (@UpdateMinMaxBetv201 = 1 AND sporttype=201) THEN @MinBetv201
				WHEN (@UpdateMinMaxBetv151 = 1 AND sporttype=151) THEN @MinBetv151
			ELSE minbet END,
	MaxBet = CASE WHEN (@UpdateMinMaxBetv201 = 1 AND sporttype=201) THEN @MaxBetv201
				WHEN (@UpdateMinMaxBetv151 = 1 AND sporttype=151) THEN @MaxBetv151

			ELSE MaxBet END
WHERE custid=@custid


if (@@error <> 0)
begin
	
	Select @ErrMsg = @UserName + ': '+
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น!'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end, @ErrCode = 115
	return
end

update custinfo with (ROWLOCK, UPDLOCK)
set 	
	MaxPerMatch=case when @UpdateMinMaxBet=1 then @MaxPerMatch else MaxPerMatch end,
	MaxPerMatch2=case when @UpdateMinMaxBetv2=1 then @MaxPerMatchv2 else MaxPerMatch2 end,
	MaxPerMatch3=case when @UpdateMinMaxBetv3=1 then @MaxPerMatchv3 else MaxPerMatch3 end,
	MaxPerMatch5=case when @UpdateMinMaxBetv5=1 then @MaxPerMatchv5 else MaxPerMatch5 end,
	MaxPerMatch8=case when @UpdateMinMaxBetv8=1 then @MaxPerMatchv8 else MaxPerMatch8 end,
	MaxPerMatch10=case when @UpdateMinMaxBetv10=1 then @MaxPerMatchv10 else MaxPerMatch10 end,
	MaxPerMatch11=case when @UpdateMinMaxBetv11=1 then @MaxPerMatchv11 else MaxPerMatch11 end,	
	MaxPerMatch99=case when @UpdateMinMaxBetv99=1 then @MaxPerMatchv99 else MaxPerMatch99 end,
	MaxPerMatch201=case when @UpdateMinMaxBetv201=1 then @MaxPerMatchv201 else MaxPerMatch201 end,
	MaxPerMatch151=case when @UpdateMinMaxBetv151=1 then @MaxPerMatchv151 else MaxPerMatch151 end
where custid = @custid 

if (@@error <> 0)
begin
	
	Select @ErrMsg = @UserName + ': '+
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น!'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end, @ErrCode = 115
	return
end

Declare @LogSPData varchar(5000)
Select @LogSPData ='<Dot_Dep_CustomerUpdMemBetSetting custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
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
'MinBv201="'+ coalesce(cast(@minbetv201 as varchar(50)),space(1)) + '" ' +
'MaxBv201="'+ coalesce(cast(@maxbetv201 as varchar(50)),space(1)) + '" ' +
'MPMv201="'+ coalesce(cast(@maxpermatchv201 as varchar(50)),space(1)) + '" ' +
'MinBv151="'+ coalesce(cast(@minbetv151 as varchar(50)),space(1)) + '" ' +
'MaxBv151="'+ coalesce(cast(@maxbetv151 as varchar(50)),space(1)) + '" ' +
'MPMv151="'+ coalesce(cast(@maxpermatchv151 as varchar(50)),space(1)) + '" ' +
'UMMB="'+ coalesce(cast(@UpdateMinMaxBet as varchar(50)),space(1)) + '" ' +
'UMMBv2="'+ coalesce(cast(@UpdateMinMaxBetv2 as varchar(50)),space(1)) + '" ' +
'UMMBv3="'+ coalesce(cast(@UpdateMinMaxBetv3 as varchar(50)),space(1)) + '" ' +
'UMMBv5="'+ coalesce(cast(@UpdateMinMaxBetv5 as varchar(50)),space(1)) + '" ' +
'UMMBv8="'+ coalesce(cast(@UpdateMinMaxBetv8 as varchar(50)),space(1)) + '" ' +
'UMMBv10="'+ coalesce(cast(@UpdateMinMaxBetv10 as varchar(50)),space(1)) + '" ' +
'UMMBv11="'+ coalesce(cast(@UpdateMinMaxBetv11 as varchar(50)),space(1)) + '" ' +
'UMMBv99="'+ coalesce(cast(@UpdateMinMaxBetv99 as varchar(50)),space(1)) + '" ' +
'UMMBv201="'+ coalesce(cast(@UpdateMinMaxBetv201 as varchar(50)),space(1)) + '" ' +
'UMMBv151="'+ coalesce(cast(@UpdateMinMaxBetv151 as varchar(50)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 314,
	@TrackingValue = @LogSPData

GO
GRANT EXECUTE ON [dbo].[Dot_Dep_CustomerUpdMemBetSetting] TO [Dot_Admin]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Dep_CustomerUpdMemBetSetting] TO [ITVivi]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Dep_CustomerUpdMemBetSetting] TO [vnteam]