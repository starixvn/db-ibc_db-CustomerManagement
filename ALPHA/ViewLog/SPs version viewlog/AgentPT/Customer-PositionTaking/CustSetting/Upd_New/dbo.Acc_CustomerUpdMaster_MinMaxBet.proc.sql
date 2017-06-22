ALTER PROCEDURE [dbo].[Acc_CustomerUpdMaster_MinMaxBet]
	@custid int,-- masterid
	
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
Task : Update master's min/max bet/maxpermatch 
DB: DB02.bodb02
Original: [Acc_CustomerUpdMaster_MinMaxBet]

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
	--v151
	--@MinMinBetv151 money, @MaxMaxBetv151 money, @MaxMaxPerMatchv151 money,

	@MinMinBetv99 money, @MaxMaxBetv99 money, @MaxMaxPerMatchv99 money
	
declare @ErrAcc varchar(4000), @ErrType varchar(4000),
		@UserName varchar(30), @srecommend int
		
Select @UserName = username, @srecommend = srecommend
from customer with (NOLOCK)
where CustID = @CustID


if @UpdateMinMaxBet = 1 or @UpdateMultiple = 0
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
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대.'
							else N'Wrong Min bet/ Max bet/ Max per match.'
					end, @ErrCode = 101
		return
	END
END

if @UpdateMinMaxBetv2 = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@minbetv2 <0
		or @maxbetv2 <0
		or @maxpermatchv2 <0
	BEGIN	
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Basketball).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于篮球).'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於籃球).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬาบาสเก็ตบอล).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Basketball).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (농구).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Basketball).'
					end, @ErrCode = 102
		return
	END
END

if @UpdateMinMaxBetv3 = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@minbetv3 <0
		or @maxbetv3 <0
		or @maxpermatchv3 <0
	BEGIN
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Football).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于美式足球.'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於美式足球).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬาอเมริกันฟุตบอล).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Football).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (풋볼).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Football).'
					end, @ErrCode = 103
		return
	END
END

if @UpdateMinMaxBetv5 = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@minbetv5 <0
		or @maxbetv5 <0
		or @maxpermatchv5 <0
	BEGIN
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Tennis).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于网球).'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於網球).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬาเทนนิส).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Tennis).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (테니스).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Tennis).'
					end, @ErrCode = 104
		return
	END
END

if @UpdateMinMaxBetv8 = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@minbetv8 <0
		or @maxbetv8 <0
		or @maxpermatchv8 <0
	BEGIN
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Baseball).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于棒球).'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於棒球).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬาเบสบอล).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Baseball).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (야구).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Baseball).'
					end, @ErrCode = 105
		return
	END
END

if @UpdateMinMaxBetv10 = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@minbetv10 <0
		or @maxbetv10 <0
		or @maxpermatchv10 <0
	BEGIN
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Golf).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于高尔夫球).'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於高爾夫球).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬากอฟล์).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Golf).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (골프).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Golf).'
					end, @ErrCode = 106
		return
	END
END

if @UpdateMinMaxBetv11 = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@minbetv11 <0
		or @maxbetv11 <0
		or @maxpermatchv11 <0
	BEGIN
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Motosports).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于赛车).'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於賽車).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬารถแข่ง).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Motosports).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (모토스포츠).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Motosports).'
					end, @ErrCode = 107
		return
	END
END

--v151
--if @UpdateMinMaxBetv151 = 1 or @UpdateMultiple = 0
--BEGIN
	--if 
		--@minbetv151 <0
		--or @maxbetv151 <0
		--or @maxpermatchv151 <0
	--BEGIN
		--Select @ErrMsg = 	case @Language 
							--when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Financial).'
							--when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于金融).'
							--when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於金融).'
							--when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับการเงิน).'
							--when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Financial).'
							--else N'Wrong Min bet/ Max bet/ Max per match (for Financial).'
					--end, @ErrCode = 108
		--return
	--END
--END

if @UpdateMinMaxBetv99 = 1 or @UpdateMultiple = 0
BEGIN
	if 
		@minbetv99 <0
		or @maxbetv99 <0
		or @maxpermatchv99 <0
	BEGIN
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Other Sports).'
							when 'CS' then N'最低投注/最高投注/单场最高投注不正确(于其他).'
							when 'CT' then N'最低投注/最高投注/單場最高投注不正確(於其他).'
							when 'TH' then N'การกำหนดจำนวนเงินสำหรับการวางเดิมพันต่ำสุด/ สูงสุด/สูงสดต่อรายการไม่ถูกต้อง (สำหรับกีฬาอื่นๆ).'
							when 'J' then N'Wrong Min bet/ Max bet/ Max per match (for Other Sports).'
							when 'KO' then N'잘못된 최소 배팅/최대 배팅/경기당 최대 (기타 스포츠).'
							else N'Wrong Min bet/ Max bet/ Max per match (for Other Sports).'
					end, @ErrCode = 109
		return
	END
END

---------------------------------------------------------
if @UpdateMultiple = 0 or @UpdateMinMaxBet=1 
BEGIN
	if 
	(@minbet<>0 and @maxbet <> 0 and  @minbet>@maxbet) 
	or (@maxbet<> 0 and @maxpermatch <> 0 and @maxbet>@maxpermatch) 
	or (@minbet <> 0 and @maxpermatch <> 0 and @minbet>@maxpermatch)
	BEGIN
		SELECT @ErrMsg =  @UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม.'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다.'
							else N'min bet must be less than max bet and max bet must be less than max bet per match'
						end	, @ErrCode = 110
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv2=1 
BEGIN
	if (@minbetv2 <> 0 and @maxbetv2 <> 0 and @minbetv2>@maxbetv2) 
	or (@maxbetv2 <> 0 and @maxpermatchv2 <> 0 and @maxbetv2>@maxpermatchv2)
	or (@minbetv2 <> 0 and @maxpermatchv2 <> 0 and @minbetv2>@maxpermatchv2) 
	BEGIN
		SELECT @ErrMsg =  @UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Basketball)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于篮球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於籃球)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาบาสเก็ตบอล).'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Basketball)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (농구)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Basketball)'
						end, @ErrCode = 111
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv3=1 
BEGIN
	if (@minbetv3 <> 0 and @maxbetv3 <> 0 and @minbetv3>@maxbetv3) 
	or (@maxbetv3 <> 0 and @maxpermatchv3 <> 0 and @maxbetv3>@maxpermatchv3)
	or (@minbetv3 <> 0 and @maxpermatchv3 <> 0 and @minbetv3>@maxpermatchv3) 
	BEGIN
		SELECT @ErrMsg =  @UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Football)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于美式足球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於美式足球)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาอเมริกันฟุตบอล).'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Football)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (풋볼)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Football)'
						end, @ErrCode = 112
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv5=1 
BEGIN
	if (@minbetv5 <> 0 and @maxbetv5 <> 0 and @minbetv5>@maxbetv5) 
	or (@maxbetv5 <> 0 and @maxpermatchv5 <> 0 and @maxbetv5>@maxpermatchv5)
	or (@minbetv5 <> 0 and @maxpermatchv5 <> 0 and @minbetv5>@maxpermatchv5) 
	BEGIN
		SELECT @ErrMsg =  @UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Tennis)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于网球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於網球)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาเทนนิส).'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Tennis)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (테니스)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Tennis)'
						end, @ErrCode = 113
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv8=1 
BEGIN
	if (@minbetv8 <> 0 and @maxbetv8 <> 0 and @minbetv8>@maxbetv8) 
	or (@maxbetv8 <> 0 and @maxpermatchv8 <> 0 and @maxbetv8>@maxpermatchv8)
	or (@minbetv8 <> 0 and @maxpermatchv8 <> 0 and @minbetv8>@maxpermatchv8) 
	BEGIN
		SELECT @ErrMsg =  @UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Baseball)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于棒球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於棒球)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาเบสบอล).'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Baseball)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (야구)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Baseball)'
						end, @ErrCode = 114	
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv10=1 
BEGIN
	if (@minbetv10 <> 0 and @maxbetv10 <> 0 and @minbetv10>@maxbetv10) 
	or (@maxbetv10 <> 0 and @maxpermatchv10 <> 0 and @maxbetv10>@maxpermatchv10)
	or (@minbetv10 <> 0 and @maxpermatchv10 <> 0 and @minbetv10>@maxpermatchv10) 
	BEGIN
		SELECT @ErrMsg =  @UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Golf)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于高尔夫球)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於高爾夫球)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬากอฟล์).'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Golf)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (골프)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Golf)'
						end, @ErrCode = 115
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv11=1 
BEGIN
	if (@minbetv11 <> 0 and @maxbetv11 <> 0 and @minbetv11>@maxbetv11) 
	or (@maxbetv11 <> 0 and @maxpermatchv11 <> 0 and @maxbetv11>@maxpermatchv11)
	or (@minbetv11 <> 0 and @maxpermatchv11 <> 0 and @minbetv11>@maxpermatchv11) 
	BEGIN
		SELECT @ErrMsg =  @UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Motorsports)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于赛车)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於賽車)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬารถแข่ง).'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Motorsports)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (모토스포츠)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Motorsports)'
						end, @ErrCode = 116
		return
	END
END

--v151
--if @UpdateMultiple = 0 or @UpdateMinMaxBetv151=1 
--BEGIN
	--if (@minbetv151 <> 0 and @maxbetv151 <> 0 and @minbetv151>@maxbetv151) 
	--or (@maxbetv151 <> 0 and @maxpermatchv151 <> 0 and @maxbetv151>@maxpermatchv151)
	--or (@minbetv151 <> 0 and @maxpermatchv151 <> 0 and @minbetv151>@maxpermatchv151) 
	--BEGIN
		--SELECT @ErrMsg =  @UserName + ': '+
						--case @Language 
							--when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Financial)'
							--when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于金融)'
							--when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於金融)'
							--when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับการเงิน).'
							--when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Financial)'
							--else N'min bet must be less than max bet and max bet must be less than max bet per match (for Financial)'
						--end, @ErrCode = 117
		--return
	--END
--END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv99=1 
BEGIN
	if (@minbetv99 <> 0 and @maxbetv99 <> 0 and @minbetv99>@maxbetv99) 
	or (@maxbetv99 <> 0 and @maxpermatchv99 <> 0 and @maxbetv99>@maxpermatchv99)
	or (@minbetv99 <> 0 and @maxpermatchv99 <> 0 and @minbetv99>@maxpermatchv99) 
	BEGIN
		SELECT @ErrMsg =  @UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be less than max bet and max bet must be less than max bet per match (for Other sports)'
							when 'CS' then N'最低投注不能高于最高投注，最高投注不能高于单场最高投注设定(于其他)'
							when 'CT' then N'最低投注不能高於最高投注,最高投注不能高於單場最高投注設定(於其他)'
							when 'TH' then N'จำนวนเงินต่ำสุดที่วางเดิมพันได้ต้องน้อยกว่าจำนวนเงินสูงสุดในการวางเดิมพันและจำนวนเงินสูงสุดในการวางเดิมพันต้องน้อยกว่าจำนวนเงินสูงสุดของเงินเดิมพันต่อเกม (สำหรับกีฬาอื่นๆ).'
							when 'J' then N'min bet must be less than max bet and max bet must be less than max bet per match (for Other sports)'
							when 'KO' then N'최소 배팅은 최대 배팅 이하이여야 하고 최대 배팅은 경기당 최대 배팅보다 작아야 합니다 (기타 스포츠)'
							else N'min bet must be less than max bet and max bet must be less than max bet per match (for Other sports)'
						end, @ErrCode = 118
		return
	END
END
-------------------------------------------------
Select @MaxMaxPerMatch = MaxPerMatch,
		@MaxMaxPerMatchv2 = MaxPerMatch2,
		@MaxMaxPerMatchv3 = MaxPerMatch3,
		@MaxMaxPerMatchv5 = MaxPerMatch5,
		@MaxMaxPerMatchv8 = MaxPerMatch8,
		@MaxMaxPerMatchv10 = MaxPerMatch10,
		@MaxMaxPerMatchv11 = MaxPerMatch11,
		--v151
		--@MaxMaxPerMatchv151 = MaxPerMatch151,
		@MaxMaxPerMatchv99 = MaxPerMatch99		
from custinfo with (NOLOCK) where custid = @srecommend

---------------------------------------------------------
Select 
	@MinMinBet = MinBet,
	@MaxMaxBet = MaxBet
From custsetting with (NOLOCK)
where CustID = @srecommend and bettype=1 and sporttype=1

Select 
	@MinMinBetv2 = MinBet,
	@MaxMaxBetv2 = MaxBet
From custsetting with (NOLOCK)
where CustID = @srecommend and bettype=1 and sporttype=2

Select 
	@MinMinBetv3 = MinBet,
	@MaxMaxBetv3 = MaxBet
From custsetting with (NOLOCK)
where CustID = @srecommend and bettype=1 and sporttype=3

Select 
	@MinMinBetv5 = MinBet,
	@MaxMaxBetv5 = MaxBet
From custsetting with (NOLOCK)
where CustID = @srecommend and bettype=1 and sporttype=5

Select 
	@MinMinBetv8 = MinBet,
	@MaxMaxBetv8 = MaxBet
From custsetting with (NOLOCK)
where CustID = @srecommend and bettype=1 and sporttype=8

Select 
	@MinMinBetv10 = MinBet,
	@MaxMaxBetv10 = MaxBet
From custsetting with (NOLOCK)
where CustID = @srecommend and bettype=1 and sporttype=10

Select 
	@MinMinBetv11 = MinBet,
	@MaxMaxBetv11 = MaxBet
From custsetting with (NOLOCK)
where CustID = @srecommend and bettype=1 and sporttype=11

Select 
	@MinMinBetv99 = MinBet,
	@MaxMaxBetv99 = MaxBet
From custsetting with (NOLOCK)
where CustID = @srecommend and bettype=1 and sporttype=99


if @UpdateMultiple = 0 or @UpdateMinMaxBet=1 
BEGIN
	if (@MinMinBet>0 and @MinBet>0 and @minbet<@MinMinBet)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Super Agent min bet (for Soccer)'
							when 'CS' then N'最低投注需相等于或少于超级总代理最低投注(于足球)'
							when 'CT' then N'最低投注需相等於或少於超級總代理最低投注(於足球)'
							when 'TH' then N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่า จำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้จากตัวแทนสูงสุด ( สำหรับฟุตบอล ).'
							when 'J' then N'min bet must be equal to or greater than Super Agent min bet (for Soccer)'
							when 'KO' then N'최소 배팅은 슈퍼 에이전트의 최소 배팅 이상이여야 합니다 (축구)'
							else N'min bet must be equal to or greater than Super Agent min bet (for Soccer)'
						end						
						+' (' + convert(varchar(20), @MinMinBet) + ').', @ErrCode = 119	
		return
	END
	
	if (@MaxMaxBet>0 and @MaxBet>0 and @maxbet>@MaxMaxBet)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Super Agent max bet (for Soccer)'
							when 'CS' then N'最高投注需相等于或少于超级总代理最高投注(于足球)'
							when 'CT' then N'最高投注需相等於或少於超級總代理最高投注(於足球)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนสูงสุด(สำหรับกีฬาฟุตบอล) .'
							when 'J' then N'max bet must be equal to or less than Super Agent max bet (for Soccer)'
							when 'KO' then N'최대 배팅은 슈퍼에이전트의 최대 배팅 이하이여야 합니다 (축구)'
							else N'max bet must be equal to or less than Super Agent max bet (for Soccer)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBet) + ').', @ErrCode = 120	
		return
	END
	
	if (@MaxMaxPerMatch>0 and @MaxPerMatch>0 and @MaxPerMatch>@MaxMaxPerMatch)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Super Agent Max Per Match (for Soccer)'
							when 'CS' then N'单场最高投注需相等于或少于超级总代理单场最高投注(于足球)'
							when 'CT' then N'單場最高投注需相等於或少於超級總代理單場最高投注(於足球)'
							when 'TH' then N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนสูงสุด ( สำหรับฟุตบอล ).'
							when 'J' then N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Soccer)'
							when 'KO' then N'최대 경기는 슈퍼 에이전트 최대 경기보다 작아야 합니다 (축구)'
							else N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Soccer)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatch) + ').', @ErrCode = 121	
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv2=1 
BEGIN
	if (@MaxMaxBetv2>0 and @maxbetv2>0 and @maxbetv2>@MaxMaxBetv2)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Super Agent max bet (for Basketball)'
							when 'CS' then N'最高投注需相等于或少于超级总代理最高投注(于篮球)'
							when 'CT' then N'最高投注需相等於或少於超級總代理最高投注(於籃球)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนสูงสุด (สำหรับกีฬาบาสเก็ตบอล).'
							when 'J' then N'max bet must be equal to or less than Super Agent max bet (for Basketball)'
							when 'KO' then N'최대 배팅은 슈퍼에이전트의 최대 배팅 이하이여야 합니다 (농구)'
							else N'max bet must be equal to or less than Super Agent max bet (for Basketball)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBetv2) + ').', @ErrCode = 122	
		return
	END
	
	if (@MaxMaxPerMatchv2>0 and @MaxPerMatchv2>0 and @MaxPerMatchv2>@MaxMaxPerMatchv2)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Super Agent Max Per Match (for Basketball)'
							when 'CS' then N'单场最高投注需相等于或少于超级总代理单场最高投注(于篮球)'
							when 'CT' then N'單場最高投注需相等於或少於超級總代理單場最高投注(於籃球)'
							when 'TH' then N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนสูงสุด (สำหรับกีฬาบาสเก็ตบอล).'
							when 'J' then N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Basketball)'
							when 'KO' then N'최대 경기는 슈퍼 에이전트 최대 경기보다 작아야 합니다 (농구)'
							else N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Basketball)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatchv2) + ').', @ErrCode = 123	
		return
	END
	
	if (@MinMinBetv2>0 and @minbetv2>0 and @minbetv2<@MinMinBetv2)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Super Agent min bet (for Basketball)'
							when 'CS' then N'最低投注需相等于或少于超级总代理最低投注(于篮球)'
							when 'CT' then N'最低投注需相等於或少於超級總代理最低投注(於籃球)'
							when 'TH' then N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่า จำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้จากตัวแทนสูงสุด (สำหรับกีฬาบาสเก็ตบอล).'
							when 'J' then N'min bet must be equal to or greater than Super Agent min bet (for Basketball)'
							when 'KO' then N'최소 배팅은 슈퍼 에이전트의 최소 배팅 이상이여야 합니다 (농구)'
							else N'min bet must be equal to or greater than Super Agent min bet (for Basketball)'
						end						
						+' (' + convert(varchar(20), @MinMinBetv2) + ').', @ErrCode = 124	
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv3=1 
BEGIN
	if (@MaxMaxBetv3>0 and @maxbetv3>0 and @maxbetv3>@MaxMaxBetv3)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Super Agent max bet (for Football)'
							when 'CS' then N'最高投注需相等于或少于超级总代理最高投注(于美式足球)'
							when 'CT' then N'最高投注需相等於或少於超級總代理最高投注(於美式足球)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนสูงสุด (สำหรับกีฬาอเมริกันฟุตบอล).'
							when 'J' then N'max bet must be equal to or less than Super Agent max bet (for Football)'
							when 'KO' then N'최대 배팅은 슈퍼에이전트의 최대 배팅 이하이여야 합니다 (풋볼)'
							else N'max bet must be equal to or less than Super Agent max bet (for Football)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBetv3) + ').', @ErrCode = 125	
		return
	END
	
	if (@MaxMaxPerMatchv3>0 and @MaxPerMatchv3>0 and @MaxPerMatchv3>@MaxMaxPerMatchv3)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Super Agent Max Per Match (for Football)'
							when 'CS' then N'单场最高投注需相等于或少于超级总代理单场最高投注(于美式足球)'
							when 'CT' then N'單場最高投注需相等於或少於超級總代理單場最高投注(於美式足球)'
							when 'TH' then N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนสูงสุด (สำหรับกีฬาอเมริกันฟุตบอล).'
							when 'J' then N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Football)'
							when 'KO' then N'최대 경기는 슈퍼 에이전트 최대 경기보다 작아야 합니다 (풋볼)'
							else N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Football)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatchv3) + ').', @ErrCode = 126	
		return
	END
	
	if (@MinMinBetv3>0 and @minbetv3>0 and @minbetv3<@MinMinBetv3)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Super Agent min bet (for Football)'
							when 'CS' then N'最低投注需相等于或少于超级总代理最低投注(于美式足球)'
							when 'CT' then N'最低投注需相等於或少於超級總代理最低投注(於美式足球)'
							when 'TH' then N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่า จำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้จากตัวแทนสูงสุด (สำหรับกีฬาอเมริกันฟุตบอล).'
							when 'J' then N'min bet must be equal to or greater than Super Agent min bet (for Football)'
							when 'KO' then N'최소 배팅은 슈퍼 에이전트의 최소 배팅 이상이여야 합니다 (풋볼)'
							else N'min bet must be equal to or greater than Super Agent min bet (for Football)'
						end						
						+' (' + convert(varchar(20), @MinMinBetv3) + ').', @ErrCode = 127	
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv5=1 
BEGIN
	if (@MaxMaxBetv5>0 and @maxbetv5>0 and @maxbetv5>@MaxMaxBetv5)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Super Agent max bet (for Tennis)'
							when 'CS' then N'最高投注需相等于或少于超级总代理最高投注(于网球)'
							when 'CT' then N'最高投注需相等於或少於超級總代理最高投注(於網球)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนสูงสุด (สำหรับกีฬาเทนนิส).'
							when 'J' then N'max bet must be equal to or less than Super Agent max bet (for Tennis)'
							when 'KO' then N'최대 배팅은 슈퍼에이전트의 최대 배팅 이하이여야 합니다 (테니스)'
							else N'max bet must be equal to or less than Super Agent max bet (for Tennis)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBetv5) + ').', @ErrCode = 128	
		return
	END
	
	if (@MaxMaxPerMatchv5>0 and @MaxPerMatchv5>0 and @MaxPerMatchv5>@MaxMaxPerMatchv5)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Super Agent Max Per Match (for Tennis)'
							when 'CS' then N'单场最高投注需相等于或少于超级总代理单场最高投注(于网球)'
							when 'CT' then N'單場最高投注需相等於或少於超級總代理單場最高投注(於網球)'
							when 'TH' then N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนสูงสุด (สำหรับกีฬาเทนนิส).'
							when 'J' then N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Tennis)'
							when 'KO' then N'최대 경기는 슈퍼 에이전트 최대 경기보다 작아야 합니다 (테니스)'
							else N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Tennis)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatchv5) + ').', @ErrCode = 129	
		return
	END
	
	if (@MinMinBetv5>0 and @minbetv5>0 and @minbetv5<@MinMinBetv5)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Super Agent min bet (for Tennis)'
							when 'CS' then N'最低投注需相等于或少于超级总代理最低投注(于网球)'
							when 'CT' then N'最低投注需相等於或少於超級總代理最低投注(於網球)'
							when 'TH' then N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่า จำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้จากตัวแทนสูงสุด (สำหรับกีฬาเทนนิส).'
							when 'J' then N'min bet must be equal to or greater than Super Agent min bet (for Tennis)'
							when 'KO' then N'최소 배팅은 슈퍼 에이전트의 최소 배팅 이상이여야 합니다 (테니스)'
							else N'min bet must be equal to or greater than Super Agent min bet (for Tennis)'
						end						
						+' (' + convert(varchar(20), @MinMinBetv5) + ').', @ErrCode = 130	
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv8=1 
BEGIN
	if (@MaxMaxBetv8>0 and @maxbetv8>0 and @maxbetv8>@MaxMaxBetv8)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Super Agent max bet (for Baseball)'
							when 'CS' then N'最高投注需相等于或少于超级总代理最高投注(于棒球)'
							when 'CT' then N'最高投注需相等於或少於超級總代理最高投注(於棒球)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนสูงสุด (สำหรับกีฬาเบสบอล).'
							when 'J' then N'max bet must be equal to or less than Super Agent max bet (for Baseball)'
							when 'KO' then N'최대 배팅은 슈퍼에이전트의 최대 배팅 이하이여야 합니다 (야구)'
							else N'max bet must be equal to or less than Super Agent max bet (for Baseball)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBetv8) + ').', @ErrCode = 131	
		return
	END
	
	if (@MaxMaxPerMatchv8>0 and @MaxPerMatchv8>0 and @MaxPerMatchv8>@MaxMaxPerMatchv8)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Super Agent Max Per Match (for Baseball)'
							when 'CS' then N'单场最高投注需相等于或少于超级总代理单场最高投注(于棒球)'
							when 'CT' then N'單場最高投注需相等於或少於超級總代理單場最高投注(於棒球)'
							when 'TH' then N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนสูงสุด (สำหรับกีฬาเบสบอล).'
							when 'J' then N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Baseball)'
							when 'KO' then N'최대 경기는 슈퍼 에이전트 최대 경기보다 작아야 합니다 (야구)'
							else N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Baseball)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatchv8) + ').', @ErrCode = 132	
		return
	END
	
	if (@MinMinBetv8>0 and @minbetv8>0 and @minbetv8<@MinMinBetv8)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Super Agent min bet (for Baseball)'
							when 'CS' then N'最低投注需相等于或少于超级总代理最低投注(于棒球)'
							when 'CT' then N'最低投注需相等於或少於超級總代理最低投注(於棒球)'
							when 'TH' then N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่า จำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้จากตัวแทนสูงสุด (สำหรับกีฬาเบสบอล).'
							when 'J' then N'min bet must be equal to or greater than Super Agent min bet (for Baseball)'
							when 'KO' then N'최소 배팅은 슈퍼 에이전트의 최소 배팅 이상이여야 합니다 (야구)'
							else N'min bet must be equal to or greater than Super Agent min bet (for Baseball)'
						end						
						+' (' + convert(varchar(20), @MinMinBetv8) + ').', @ErrCode = 133	
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv10=1 
BEGIN
	if (@MaxMaxBetv10>0 and @maxbetv10>0 and @maxbetv10>@MaxMaxBetv10)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Super Agent max bet (for Golf)'
							when 'CS' then N'最高投注需相等于或少于超级总代理最高投注(于高尔夫球)'
							when 'CT' then N'最高投注需相等於或少於超級總代理最高投注(於高爾夫球)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนสูงสุด (สำหรับกีฬากอฟล์).'
							when 'J' then N'max bet must be equal to or less than Super Agent max bet (for Golf)'
							when 'KO' then N'최대 배팅은 슈퍼에이전트의 최대 배팅 이하이여야 합니다 (골프)'
							else N'max bet must be equal to or less than Super Agent max bet (for Golf)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBetv10) + ').', @ErrCode = 134	
		return
	END
	
	if (@MaxMaxPerMatchv10>0 and @MaxPerMatchv10>0 and @MaxPerMatchv10>@MaxMaxPerMatchv10)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Super Agent Max Per Match (for Golf)'
							when 'CS' then N'单场最高投注需相等于或少于超级总代理单场最高投注(于高尔夫球)'
							when 'CT' then N'單場最高投注需相等於或少於超級總代理單場最高投注(於高爾夫球)'
							when 'TH' then N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนสูงสุด (สำหรับกีฬากอฟล์).'
							when 'J' then N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Golf)'
							when 'KO' then N'최대 경기는 슈퍼 에이전트 최대 경기보다 작아야 합니다 (골프)'
							else N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Golf)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatchv10) + ').', @ErrCode = 135	
		return
	END
	
	if (@MinMinBetv10>0 and @minbetv10>0 and @minbetv10<@MinMinBetv10)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Super Agent min bet (for Golf)'
							when 'CS' then N'最低投注需相等于或少于超级总代理最低投注(于高尔夫球)'
							when 'CT' then N'最低投注需相等於或少於超級總代理最低投注(於高爾夫球)'
							when 'TH' then N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่า จำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้จากตัวแทนสูงสุด (สำหรับกีฬากอฟล์).'
							when 'J' then N'min bet must be equal to or greater than Super Agent min bet (for Golf)'
							when 'KO' then N'최소 배팅은 슈퍼 에이전트의 최소 배팅 이상이여야 합니다 (골프)'
							else N'min bet must be equal to or greater than Super Agent min bet (for Golf)'
						end						
						+' (' + convert(varchar(20), @MinMinBetv10) + ').', @ErrCode = 136	
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv11=1 
BEGIN
	if (@MaxMaxBetv11>0 and @maxbetv11>0 and @maxbetv11>@MaxMaxBetv11)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Super Agent max bet (for Motorsports)'
							when 'CS' then N'最高投注需相等于或少于超级总代理最高投注(于赛车'
							when 'CT' then N'最高投注需相等於或少於超級總代理最高投注(於賽車)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนสูงสุด (สำหรับกีฬารถแข่ง).'
							when 'J' then N'max bet must be equal to or less than Super Agent max bet (for Motorsports)'
							when 'KO' then N'최대 배팅은 슈퍼에이전트의 최대 배팅 이하이여야 합니다 (모토스포츠)'
							else N'max bet must be equal to or less than Super Agent max bet (for Motorsports)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBetv11) + ').', @ErrCode = 137	
		return
	END
	
	if (@MaxMaxPerMatchv11>0 and @MaxPerMatchv11>0 and @MaxPerMatchv11>@MaxMaxPerMatchv11)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Super Agent Max Per Match (for Motorsports)'
							when 'CS' then N'单场最高投注需相等于或少于超级总代理单场最高投注(于赛车)'
							when 'CT' then N'單場最高投注需相等於或少於超級總代理單場最高投注(於賽車)'
							when 'TH' then N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนสูงสุด (สำหรับกีฬารถแข่ง).'
							when 'J' then N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Motorsports)'
							when 'KO' then N'최대 경기는 슈퍼 에이전트 최대 경기보다 작아야 합니다 (모토스포츠)'
							else N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Motorsports)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatchv11) + ').', @ErrCode = 138	
		return
	END
	
	if (@MinMinBetv11>0 and @minbetv11>0 and @minbetv11<@MinMinBetv11)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Super Agent min bet (for Motorsports)'
							when 'CS' then N'最低投注需相等于或少于超级总代理最低投注(于赛车)'
							when 'CT' then N'最低投注需相等於或少於超級總代理最低投注(於賽車)'
							when 'TH' then N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่า จำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้จากตัวแทนสูงสุด (สำหรับกีฬารถแข่ง).'
							when 'J' then N'min bet must be equal to or greater than Super Agent min bet (for Motorsports)'
							when 'KO' then N'최소 배팅은 슈퍼 에이전트의 최소 배팅 이상이여야 합니다 (모토스포츠)'
							else N'min bet must be equal to or greater than Super Agent min bet (for Motorsports)'
						end						
						+' (' + convert(varchar(20), @MinMinBetv11) + ').', @ErrCode = 139	
		return
	END
END

if @UpdateMultiple = 0 or @UpdateMinMaxBetv99=1 
BEGIN
	if (@MaxMaxBetv99>0 and @maxbetv99>0 and @maxbetv99>@MaxMaxBetv99)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'max bet must be equal to or less than Super Agent max bet (for Other sports)'
							when 'CS' then N'最高投注需相等于或少于超级总代理最高投注(于其他)'
							when 'CT' then N'最高投注需相等於或少於超級總代理最高投注(於其他)'
							when 'TH' then N'จำนวนการวางเดิมพันสูงสุดต้องเท่ากับ หรือ น้อยกว่าราคาเดิมพันสูงสุดของตัวแทนสูงสุด (สำหรับกีฬาอื่นๆ).'
							when 'J' then N'max bet must be equal to or less than Super Agent max bet (for Other sports)'
							when 'KO' then N'최대 배팅은 슈퍼에이전트의 최대 배팅 이하이여야 합니다 (기타 스포츠)'
							else N'max bet must be equal to or less than Super Agent max bet (for Other sports)'
						end						
						+' (' + convert(varchar(20), @MaxMaxBetv99) + ').', @ErrCode = 143	
		return
	END
	
	if (@MaxMaxPerMatchv99>0 and @MaxPerMatchv99>0 and @MaxPerMatchv99>@MaxMaxPerMatchv99)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Max Per Match must be equal to or less than Super Agent Max Per Match (for Other sports)'
							when 'CS' then N'单场最高投注需相等于或少于超级总代理单场最高投注(于其他)'
							when 'CT' then N'單場最高投注需相等於或少於超級總代理單場最高投注(於其他)'
							when 'TH' then N'จำนวนเงินสูงสุดในการเล่นต่อรายการต้องเท่ากับหรือน้อยกว่าจำนวนเงินสูงสุดต่อรายการที่กำหนดไว้ของตัวแทนสูงสุด (สำหรับกีฬาอื่นๆ).'
							when 'J' then N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Other sports)'
							when 'KO' then N'최대 경기는 슈퍼 에이전트 최대 경기보다 작아야 합니다 (기타 스포츠)'
							else N'Max Per Match must be equal to or less than Super Agent Max Per Match (for Other sports)'
						end						
						+' (' + convert(varchar(20), @MaxMaxPerMatchv99) + ').', @ErrCode = 144	
		return
	END
	
	if (@MinMinBetv99>0 and @minbetv99>0 and @minbetv99<@MinMinBetv99)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'min bet must be equal to or greater than Super Agent min bet (for Other sports)'
							when 'CS' then N'最低投注需相等于或少于超级总代理最低投注(于其他)'
							when 'CT' then N'最低投注需相等於或少於超級總代理最低投注(於其他)'
							when 'TH' then N'จำนวนเงินต่ำสุดในการเล่นต้องเท่ากับหรือมากกว่า จำนวนเงินขั้นต่ำในการเล่นที่กำหนดไว้จากตัวแทนสูงสุด (สำหรับกีฬาอื่นๆ).'
							when 'J' then N'min bet must be equal to or greater than Super Agent min bet (for Other sports)'
							when 'KO' then N'최소 배팅은 슈퍼 에이전트의 최소 배팅 이상이여야 합니다 (기타 스포츠)'
							else N'min bet must be equal to or greater than Super Agent min bet (for Other sports)'
						end						
						+' (' + convert(varchar(20), @MinMinBetv99) + ').', @ErrCode = 145	
		return
	END
END

------------

------------
update custsetting with (ROWLOCK, UPDLOCK)
set	
	minbet = case when @UpdateMultiple = 1 and ((sporttype=1 and @UpdateMinMaxBet = 0) or (sporttype=2 and @UpdateMinMaxBetv2 = 0) or (sporttype=3 and @UpdateMinMaxBetv3 = 0) or (sporttype=5 and @UpdateMinMaxBetv5 = 0) or (sporttype=8 and @UpdateMinMaxBetv8 = 0) or (sporttype=10 and @UpdateMinMaxBetv10 = 0) or (sporttype=11 and @UpdateMinMaxBetv11 = 0) or (sporttype=99 and @UpdateMinMaxBetv99 = 0)) then minbet else case sporttype when 1 then @minbet when 2 then @minbetv2 when 3 then @minbetv3 when 5 then @minbetv5 when 8 then @minbetv8 when 10 then @minbetv10 when 11 then @minbetv11  when 99 then @minbetv99 else minbet end end,
	maxbet = case when @UpdateMultiple = 1 and ((sporttype=1 and @UpdateMinMaxBet = 0) or (sporttype=2 and @UpdateMinMaxBetv2 = 0) or (sporttype=3 and @UpdateMinMaxBetv3 = 0) or (sporttype=5 and @UpdateMinMaxBetv5 = 0) or (sporttype=8 and @UpdateMinMaxBetv8 = 0) or (sporttype=10 and @UpdateMinMaxBetv10 = 0) or (sporttype=11 and @UpdateMinMaxBetv11 = 0) or (sporttype=99 and @UpdateMinMaxBetv99 = 0)) then maxbet else case sporttype when 1 then @maxbet when 2 then @maxbetv2 when 3 then @maxbetv3 when 5 then @maxbetv5 when 8 then @maxbetv8 when 10 then @maxbetv10 when 11 then @maxbetv11  when 99 then @maxbetv99 else maxbet end end	
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
					end	, @ErrCode = 147
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
Select @LogSPData ='<Acc_CustomerUpdMaster_MinMaxBet custid="'+ coalesce(cast(@custid as varchar(50)),space(1))+ '" ' +
'MinB="'+ coalesce(cast(@minbet as varchar(50)),space(1))+ '" ' +
'MaxB="'+ coalesce(cast(@maxbet as varchar(50)),space(1))+ '" ' +
'MPM="'+ coalesce(cast(@maxpermatch as varchar(50)),space(1))+ '" ' +
'MinBv2="'+ coalesce(cast(@minbetv2 as varchar(50)),space(1))+ '" ' +
'MaxBv2="'+ coalesce(cast(@maxbetv2 as varchar(50)),space(1))+ '" ' +
'MPMv2="'+ coalesce(cast(@maxpermatchv2 as varchar(50)),space(1))+ '" ' +
'MinBv3="'+ coalesce(cast(@minbetv3 as varchar(50)),space(1))+ '" ' +
'MaxBv3="'+ coalesce(cast(@maxbetv3 as varchar(50)),space(1))+ '" ' +
'MPMv3="'+ coalesce(cast(@maxpermatchv3 as varchar(50)),space(1))+ '" ' +
'MinBv5="'+ coalesce(cast(@minbetv5 as varchar(50)),space(1)) + '" ' +
'MaxBv5="'+ coalesce(cast(@maxbetv5 as varchar(50)),space(1))+ '" ' +
'MPMv5="'+ coalesce(cast(@maxpermatchv5 as varchar(50)),space(1))+ '" ' +
'MinBv8="'+ coalesce(cast(@minbetv8 as varchar(50)),space(1))+ '" ' +
'MaxBv8="'+ coalesce(cast(@maxbetv8 as varchar(50)),space(1))+ '" ' +
'MPMv8="'+ coalesce(cast(@maxpermatchv8 as varchar(50)),space(1))+ '" ' +
'MinBv10="'+ coalesce(cast(@minbetv10 as varchar(50)),space(1))+ '" ' +
'MaxBv10="'+ coalesce(cast(@maxbetv10 as varchar(50)),space(1))+ '" ' +
'MPMv10="'+ coalesce(cast(@maxpermatchv10 as varchar(50)),space(1))+ '" ' +
'MinBv11="'+ coalesce(cast(@minbetv11 as varchar(50)),space(1))+ '" ' +
'MaxBv11="'+ coalesce(cast(@maxbetv11 as varchar(50)),space(1))+ '" ' +
'MPMv11="'+ coalesce(cast(@maxpermatchv11 as varchar(50)),space(1))+ '" ' +
'MinBv99="'+ coalesce(cast(@minbetv99 as varchar(50)),space(1))+ '" ' +
'MaxBv99="'+ coalesce(cast(@maxbetv99 as varchar(50)),space(1))+ '" ' +
'MPMv99="'+ coalesce(cast(@maxpermatchv99 as varchar(50)),space(1))+ '" ' +
'UpdMultiple="'+ coalesce(cast(@UpdateMultiple as varchar(50)),space(1))+ '" ' +
'UMMB="'+ coalesce(cast(@UpdateMinMaxBet as varchar(50)),space(1))+ '" ' +
'UMMBv2="'+ coalesce(cast(@UpdateMinMaxBetv2 as varchar(50)),space(1))+ '" ' +
'UMMBv3="'+ coalesce(cast(@UpdateMinMaxBetv3 as varchar(50)),space(1))+ '" ' +
'UMMBv5="'+ coalesce(cast(@UpdateMinMaxBetv5 as varchar(50)),space(1))+ '" ' +
'UMMBv8="'+ coalesce(cast(@UpdateMinMaxBetv8 as varchar(50)),space(1))+ '" ' +
'UMMBv10="'+ coalesce(cast(@UpdateMinMaxBetv10 as varchar(50)),space(1))+ '" ' +
'UMMBv11="'+ coalesce(cast(@UpdateMinMaxBetv11 as varchar(50)),space(1))+ '" ' +
'UMMBv99="'+ coalesce(cast(@UpdateMinMaxBetv99 as varchar(50)),space(1))+ '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1))+ '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1))+ '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+ '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+ '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1))+ '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1))+ '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 305,
	@TrackingValue = @LogSPData

---------------------------------------------------------

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaster_MinMaxBet] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaster_MinMaxBet] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMaster_MinMaxBet] TO vnteam