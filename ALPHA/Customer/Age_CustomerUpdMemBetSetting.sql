/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerUpdMemBetSetting]	
	@CustId int,	
	@UpdateMinMaxBet BIT = 1,	
	@UpdateMinMaxBetv2 BIT = 1,	
	@UpdateMinMaxBetv3 BIT = 1,	
	@UpdateMinMaxBetv5 BIT = 1,	
	@UpdateMinMaxBetv8 BIT = 1,	
	@UpdateMinMaxBetv10 BIT = 1,
	@UpdateMinMaxBetv11 BIT = 1,	
	@UpdateMinMaxBetv99 BIT = 1,
	@UpdateMinMaxBetv99MP BIT = 1,
	@UpdateMinMaxBetv1MP BIT = 1,

	@UpdateMinMaxBetv161 BIT = 1,
	@UpdateMinMaxBetv164 BIT = 1,
	 
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
	
	@MinBetv99MP MONEY,
	@MaxBetv99MP MONEY,
	@MaxPerMatchv99MP MONEY,
	
	@MinBetv1MP MONEY,
	@MaxBetv1MP MONEY,
	@MaxPerMatchv1MP MONEY,
	

	@MinBetv161 MONEY,
	@MaxBetv161 MONEY,
	@MaxPerBallv161 MONEY = 0.00,
	@MaxPerMatchv161 MONEY,
	
	@MinBetv164 MONEY =0 ,
	@MaxBetv164 MONEY = 0,	
	@MaxPerMatchv164 MONEY = 0,
	
	@userid int, --updater Id	
	@subaccid int = 0, --Sub-AccountID
	@language varchar(2) = 'E',
	@IP varchar(15)='',	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

 /*
Created: 20090214@nqminh
Task : Update member min max bet
DB: DBTXN/bodb02
Original: Age_Customer_UpdMemberBetSetting

Revisions:
    - 20090122@[Reviewer]: [Description of revision]   
    - 20090318@Hanh: add Korean language 
    - 20090411@Minh: remove constraint: if upline disable FI then do not allow customer to update FI
	- 20090429@Phuc: remove code for calling sp Acc_CustomerUpdMember_MinMaxBet.
	- 20090526@Minh: remove code of finance
	- 20090729@Phuc: Write log subaccname instead of subaccid.
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Kiwi: amend to write log in xml format.
	- 20100919@Terry: add Mixed Sports and Number Game Bet Setting
	- 20101019@Henry: Record execution time
	- 20101029@Johnson: Include max per ball for number game
	- 20110404@Lukas: correct updated condition(in case update min/max bet Other Sport and Parlay Mixed Sports)
	- 20110427@Simon: Add Popup Message For Betting Limit.
	- 20110511@Amy: change SP name Age_CustomerSelMinMax to Acc_
	- 20110606@Amy: Write log Old values
					Write log Current value = Old Value incase of not updated
    - 20110907@Sophia: Change Linked Server from DB052 to DB053	
    - 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
    - 20130311@Dan: Change linked server DB053 to DBAGE, DB03 to DBONUSER; Write more log on DBTXN server in case of DBLOG server failure
    - 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
    - 20150611@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable, Age_CustomerSelMinMaxLimit to DBCUST.CustDB) [Redmine:#36216]
    - 20161109@Helen: Separate Bet Setting for Soccer - Parlay - [Redmine:66265]
    - 20180125@Winnie: Hide inactive products [RedmineID: #86086]
	- 20181218@Johnson: Add Happy 5 [Redmine: #104006]
	- 20200724@Eden: Minimize UM Time - Lock updating customer settings [#136464]

Param's Explanation:
• @custid: custid that need to be viewed.   
• @UpdateMinMaxBet: is update min max bet?
• @UpdateMinMaxBetv2: ...
• @UpdateMinMaxBetv3: ...
• @UpdateMinMaxBetv5:
• @UpdateMinMaxBetv8:
• @UpdateMinMaxBetv10:
• @UpdateMinMaxBetv11:
• @UpdateMinMaxBetv99: ...
	 
• @MinBet: new min bet value to be updated
• @MaxBet: new max bet value to be updated
• @MaxPerMatch: new max per match to be updated
*/

SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

--> Check UM config
EXEC [Acc_CheckUM] @CustID = @CustID, @ProductID = 1
	, @Language = @Language, @FunctionType = 1
	, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT 
	, @ReturnUMData = 0
		
IF @ErrCode <>0 
	RETURN

--Check disable user
EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end

Declare @MinMinBet money, @MaxMaxBet money,	@MaxMaxPerMatch money,
	@MinMinBetv2 money, @MaxMaxBetv2 money, @MaxMaxPerMatchv2 money,
	@MinMinBetv3 money, @MaxMaxBetv3 money, @MaxMaxPerMatchv3 money,
	@MinMinBetv5 money, @MaxMaxBetv5 money, @MaxMaxPerMatchv5 money,
	@MinMinBetv8 money, @MaxMaxBetv8 money, @MaxMaxPerMatchv8 money,
	@MinMinBetv10 money, @MaxMaxBetv10 money, @MaxMaxPerMatchv10 money,
	@MinMinBetv11 money, @MaxMaxBetv11 money, @MaxMaxPerMatchv11 money,
	
	@MinMinBetv99 money, @MaxMaxBetv99 money, @MaxMaxPerMatchv99 money,
	@MinMinBetv99MP money, @MaxMaxBetv99MP money, @MaxMaxPerMatchv99MP money,
	
	@MinMinBetv1MP money, @MaxMaxBetv1MP money, @MaxMaxPerMatchv1MP money,	

	@MinMinBetv161 money, @MaxMaxBetv161 money, @MaxMaxPerMatchv161 money, @MaxMaxPerBallv161 money,
	@MinMinBetv164 money, @MaxMaxBetv164 money, @MaxMaxPerMatchv164 money
	
declare @ErrAcc varchar(4000), @ErrType varchar(4000),
		@UserName varchar(30), @recommend int, @UpAgent int

		
Select @UserName = username, @recommend = recommend
from customer with (NOLOCK)
where CustID = @CustID

----- get Upagent
SELECT @UpAgent = CASE RoleID WHEN 1 THEN recommend
							  WHEN 2 THEN mrecommend	
							  WHEN 3 THEN srecommend
					   ELSE 0 END
FROM custinfo WITH(NOLOCK)
WHERE custid = @CustID


----------------------------------------------
-- Get old minbet, old maxbet & old MaxPerMatch_Min before Update
	DECLARE @old_MinBet MONEY, @old_MaxBet MONEY,	@old_MaxPerMatch MONEY,
		@old_MinBetv2 MONEY, @old_MaxBetv2 MONEY, @old_MaxPerMatchv2 MONEY,
		@old_MinBetv3 MONEY, @old_MaxBetv3 MONEY, @old_MaxPerMatchv3 MONEY,
		@old_MinBetv5 MONEY, @old_MaxBetv5 MONEY, @old_MaxPerMatchv5 MONEY,
		@old_MinBetv8 MONEY, @old_MaxBetv8 MONEY, @old_MaxPerMatchv8 MONEY,
		@old_MinBetv10 MONEY, @old_MaxBetv10 MONEY, @old_MaxPerMatchv10 MONEY,
		@old_MinBetv11 MONEY, @old_MaxBetv11 MONEY, @old_MaxPerMatchv11 MONEY,	
		@old_MinBetv99 MONEY, @old_MaxBetv99 MONEY, @old_MaxPerMatchv99 MONEY,
		@old_MinBetv99MP MONEY, @old_MaxBetv99MP MONEY, @old_MaxPerMatchv99MP MONEY,
		
		@old_MinBetv1MP MONEY, @old_MaxBetv1MP MONEY, @old_MaxPerMatchv1MP MONEY,
	
		@old_MinBetv161 MONEY, @old_MaxBetv161 MONEY, @old_MaxPerMatchv161 MONEY, @old_MaxPerBallv161 MONEY,
		@old_MinBetv164 MONEY, @old_MaxBetv164 MONEY, @old_MaxPerMatchv164 MONEY
		
	EXEC Acc_CustomerSelMinMax @custid,
		@MinBet = @old_MinBet output, @MaxBet = @old_MaxBet output, @MaxPerMatch =@old_MaxPerMatch output,
		@MinBetv2 = @old_MinBetv2 output, @MaxBetv2 =@old_MaxBetv2 output, @MaxPerMatchv2 =@old_MaxPerMatchv2 output,
		@MinBetv3 = @old_MinBetv3 output, @MaxBetv3 =@old_MaxBetv3 output, @MaxPerMatchv3 =@old_MaxPerMatchv3 output,
		@MinBetv5 = @old_MinBetv5 output, @MaxBetv5 =@old_MaxBetv5 output, @MaxPerMatchv5 =@old_MaxPerMatchv5 output,
		@MinBetv8 = @old_MinBetv8 output, @MaxBetv8 =@old_MaxBetv8 output, @MaxPerMatchv8 =@old_MaxPerMatchv8 output,
		@MinBetv10 = @old_MinBetv10 output, @MaxBetv10 =@old_MaxBetv10 output, @MaxPerMatchv10 =@old_MaxPerMatchv10 output,
		@MinBetv11 = @old_MinBetv11 output, @MaxBetv11 =@old_MaxBetv11 output, @MaxPerMatchv11 =@old_MaxPerMatchv11 output,
		@MinBetv99 = @old_MinBetv99 output, @MaxBetv99 =@old_MaxBetv99 output, @MaxPerMatchv99 =@old_MaxPerMatchv99 output,
		@MinBetv99MP = @old_MinBetv99MP output, @MaxBetv99MP =@old_MaxBetv99MP output, @MaxPerMatchv99MP =@old_MaxPerMatchv99MP output,
		@MinBetv1MP = @old_MinBetv1MP output, @MaxBetv1MP =@old_MaxBetv1MP output, @MaxPerMatchv1MP =@old_MaxPerMatchv1MP output,	
		@MinBetv161 = @old_MinBetv161 output, @MaxBetv161 =@old_MaxBetv161 output, @MaxPerMatchv161 =@old_MaxPerMatchv161 output, @MaxPerBallv161 =@old_MaxPerBallv161 output,
		@MinBetv164 = @old_MinBetv164 output, @MaxBetv164 =@old_MaxBetv164 output, @MaxPerMatchv164 =@old_MaxPerMatchv164 output

---------------------------------------------------------------
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
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10003,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](1,@Language) + ')'
					end
		return
	END
END
ELSE
BEGIN
	SELECT @MinBet = @Old_MinBet, @MaxBet = @Old_MaxBet, @MaxPerMatch = @Old_MaxPerMatch
END

if @UpdateMinMaxBetv1MP = 1 
BEGIN
	if 
		@MinBetv1MP<0
		or @MaxBetv1MP < 0
		or @MaxPerMatchv1MP <0		
	BEGIN
		select @ErrCode = 2
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Soccer Parlay).'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10003,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](1,@Language) + ')'
					end
		return
	END
END
ELSE
BEGIN
	SELECT @MinBetv1MP = @old_MinBetv1MP, @MaxBetv1MP = @old_MaxBetv1MP, @MaxPerMatchv1MP = @old_MaxPerMatchv1MP
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
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10003,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](2,@Language) + ')'
					end
		return
	END
END
ELSE
BEGIN
	SELECT @MinBetv2 = @Old_MinBetv2, @MaxBetv2 = @Old_MaxBetv2, @MaxPerMatchv2 = @Old_MaxPerMatchv2
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
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10003,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](3,@Language) + ')'
					end
		return
	END
END
ELSE
BEGIN
	SELECT @MinBetv3 = @Old_MinBetv3, @MaxBetv3 = @Old_MaxBetv3, @MaxPerMatchv3 = @Old_MaxPerMatchv3
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
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10003,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](5,@Language) + ')'
					end
		return
	END
END
ELSE
BEGIN
	SELECT @MinBetv5 = @Old_MinBetv5, @MaxBetv5 = @Old_MaxBetv5, @MaxPerMatchv5 = @Old_MaxPerMatchv5
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
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10003,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](8,@Language) + ')'
					end
		return
	END
END
ELSE
BEGIN
	SELECT @MinBetv8 = @Old_MinBetv8, @MaxBetv8 = @Old_MaxBetv8, @MaxPerMatchv8 = @Old_MaxPerMatchv8
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
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10003,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](10,@Language) + ')'
					end
		return
	END
END
ELSE
BEGIN
	SELECT @MinBetv10 = @Old_MinBetv10, @MaxBetv10 = @Old_MaxBetv10, @MaxPerMatchv10 = @Old_MaxPerMatchv10
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
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10003,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](11,@Language) + ')'
					end
		return
	END
END
ELSE
BEGIN
	SELECT @MinBetv11 = @Old_MinBetv11, @MaxBetv11 = @Old_MaxBetv11, @MaxPerMatchv11 = @Old_MaxPerMatchv11
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
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10003,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](99,@Language) + ')'
					end
		return
	END
END
ELSE
BEGIN
	SELECT @MinBetv99 = @Old_MinBetv99, @MaxBetv99 = @Old_MaxBetv99, @MaxPerMatchv99 = @Old_MaxPerMatchv99
END

if @UpdateMinMaxBetv161 = 1
BEGIN
	if 
		@MinBetv161 <0
		or @MaxBetv161 <0
		or @MaxPerMatchv161 <0
		OR @MaxPerBallv161 < 0		
	BEGIN
		select @ErrCode = 3
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match/ Max per ball (for Number Game).'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10004,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](161,@Language) + ')'
					end
		return
	END
END
ELSE
BEGIN
	SELECT @MinBetv161 = @Old_MinBetv161, @MaxBetv161 = @Old_MaxBetv161, @MaxPerMatchv161 = @Old_MaxPerMatchv161,
			@MaxPerBallv161 = @Old_MaxPerBallv161 
END

if @UpdateMinMaxBetv164 = 1
BEGIN
	if 
		@MinBetv164 <0
		or @MaxBetv164 <0
		or @MaxPerMatchv164 <0				
	BEGIN
		select @ErrCode = 3
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Happy 5).'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10004,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](164,@Language) + ')'
					end
		return
	END
END
ELSE
BEGIN
	SELECT @MinBetv164 = @Old_MinBetv164, @MaxBetv164 = @Old_MaxBetv164, @MaxPerMatchv164 = @Old_MaxPerMatchv164			
END

if @UpdateMinMaxBetv99MP = 1
BEGIN
	if 
		@MinBetv99MP <0
		or @MaxBetv99MP <0
		or @MaxPerMatchv99MP <0		
	BEGIN
		select @ErrCode = 3
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong Min bet/ Max bet/ Max per match (for Mix Sports Parlay).'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10003,@Language)  + case @Language 
																							when 'CS' then N'(供混合体育过关)'
																							when 'CT' then N'(供混合體育過關)'
																							when 'TH' then N'(สำหรับกีฬาบอลชุด)'
																							when 'J' then N'(Mix Sports Parlay)'
																							when 'KO' then N'(Mix Sports Parlay)'
																							when 'VI' then N'(Mix Sports Parlay)'
																							else N'(Mix Sports Parlay)' END					
							end
		return
	END
END
ELSE
BEGIN
	SELECT @MinBetv99MP = @Old_MinBetv99MP, @MaxBetv99MP = @Old_MaxBetv99MP, @MaxPerMatchv99MP = @Old_MaxPerMatchv99MP
END

--------------------------------------------------------------

	EXEC dbo.Age_CustomerSelMinMaxLimit @custid, @userid, 
		@MinBet_Max = @MinMinBet output, @MaxBet_Min = @MaxMaxBet output, @MaxPerMatch_Max = @MaxMaxperMatch output,
		@MinBetv2_Max = @MinMinBetv2 output, @MaxBetv2_Min = @MaxMaxBetv2 output, @MaxPerMatchv2_Max = @MaxMaxPerMatchv2 output,
		@MinBetv3_Max = @MinMinBetv3 output, @MaxBetv3_Min = @MaxMaxBetv3 output, @MaxPerMatchv3_Max = @MaxMaxPerMatchv3 output,
		@MinBetv5_Max = @MinMinBetv5 output, @MaxBetv5_Min = @MaxMaxBetv5 output, @MaxPerMatchv5_Max = @MaxMaxPerMatchv5 output, 
		@MinBetv8_Max = @MinMinBetv8 output, @MaxBetv8_Min = @MaxMaxBetv8 output, @MaxPerMatchv8_Max = @MaxMaxPerMatchv8 output,
		@MinBetv10_Max = @MinMinBetv10 output, @MaxBetv10_Min = @MaxMaxBetv10 output, @MaxPerMatchv10_Max = @MaxMaxPerMatchv10 output,
		@MinBetv11_Max = @MinMinBetv11 output, @MaxBetv11_Min = @MaxMaxBetv11 output, @MaxPerMatchv11_Max = @MaxMaxPerMatchv11 output,
		@MinBetv99_Max = @MinMinBetv99 output, @MaxBetv99_Min = @MaxMaxBetv99 output, @MaxPerMatchv99_Max = @MaxMaxPerMatchv99 output,		
		@MinBetv99MP_Max = @MinMinBetv99MP output, @MaxBetv99MP_Min = @MaxMaxBetv99MP output, @MaxPerMatchv99MP_Max = @MaxMaxPerMatchv99MP output,
		
		@MinBetv1MP_Max = @MinMinBetv1MP output, @MaxBetv1MP_Min = @MaxMaxBetv1MP output, @MaxPerMatchv1MP_Max = @MaxMaxPerMatchv1MP output,
		
	
		@MinBetv161_Max = @MinMinBetv161 output, @MaxBetv161_Min = @MaxMaxBetv161 output, @MaxPerMatchv161_Max = @MaxMaxPerMatchv161 output, @MaxPerBallv161_Max = @MaxMaxPerBallv161 output,
		@MinBetv164_Max = @MinMinBetv164 output, @MaxBetv164_Min = @MaxMaxBetv164 output, @MaxPerMatchv164_Max = @MaxMaxPerMatchv164 output
	
	
	
IF @UpdateMinMaxBet = 1
BEGIN
	if (@MinBet<>0 and @MaxBet <> 0 and  @MinBet>@MaxBet) or (@MaxBet<> 0 and @MaxPerMatch <> 0 and @MaxBet>@MaxPerMatch) 
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Min bet must be less than max bet and max bet must be less than max bet per match'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10005,@Language)
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBet) + '-' + convert(varchar(20), @MaxBet) + '-' + convert(varchar(20), @MaxPerMatch), @ErrCode = 108
			
		return
		
	END
	
	IF (@MinMinBet>0 AND @MinBet>0 AND @MinBet<@MinMinBet)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': ' +
						CASE @Language 
							WHEN 'E' THEN 'Min bet must be equal to or greater than Agent min bet'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10006,@Language)
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBet) + ').', @ErrCode = 109
				
		return
	END
	
	IF (@MaxMaxBet>0 AND @MaxBet>0 AND @MaxBet>@MaxMaxBet)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max bet must be equal to or less than Agent max bet'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10007,@Language)
						END						
						+'(' + CONVERT(VARCHAR(20), @MaxMaxBet) + ').', @ErrCode = 110
				
		return
	END
	
	IF (@MaxMaxPerMatch>0 AND @MaxPerMatch>0 AND @MaxPerMatch>@MaxMaxPerMatch)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10008,@Language)
						END						
						+'(' + CONVERT(VARCHAR(20), @MaxMaxPerMatch) + ').', @ErrCode = 110
				
		return
	END

END


	
IF @UpdateMinMaxBetv1MP = 1
BEGIN
	if (@MinBetv1MP<>0 and @MaxBetv1MP <> 0 and  @MinBetv1MP>@MaxBetv1MP) or (@MaxBetv1MP<> 0 and @MaxPerMatchv1MP <> 0 and @MaxBetv1MP>@MaxPerMatchv1MP) 
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Min bet must be less than max bet and max bet must be less than max bet per match'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10005,@Language)
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv1MP) + '-' + convert(varchar(20), @MaxBetv1MP) + '-' + convert(varchar(20), @MaxPerMatchv1MP), @ErrCode = 108
			
		return
		
	END
	
	IF (@MinMinBetv1MP>0 AND @MinBetv1MP>0 AND @MinBetv1MP<@MinMinBetv1MP)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': ' +
						CASE @Language 
							WHEN 'E' THEN 'Min bet must be equal to or greater than Agent min bet'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10006,@Language)
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv1MP) + ').', @ErrCode = 109
				
		return
	END
	
	IF (@MaxMaxBetv1MP>0 AND @MaxBetv1MP>0 AND @MaxBetv1MP>@MaxMaxBetv1MP)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max bet must be equal to or less than Agent max bet'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10007,@Language)
						END						
						+'(' + CONVERT(VARCHAR(20), @MaxMaxBetv1MP) + ').', @ErrCode = 110
				
		return
	END
	
	IF (@MaxMaxPerMatchv1MP>0 AND @MaxPerMatchv1MP>0 AND @MaxPerMatchv1MP>@MaxMaxPerMatchv1MP)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10008,@Language)
						END						
						+'(' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv1MP) + ').', @ErrCode = 110
				
		return
	END

END

IF @UpdateMinMaxBetv2 = 1
BEGIN
	if (@MinBetv2 <> 0 and @MaxBetv2 <> 0 and @MinBetv2>@MaxBetv2) or (@MaxBetv2 <> 0 and @MaxPerMatchv2 <> 0 and @MaxBetv2>@MaxPerMatchv2)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Min bet must be less than max bet and max bet must be less than max bet per match (for Basketball)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10005,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](2,@Language) + ')'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv2) + '-' + convert(varchar(20), @MaxBetv2) + '-' + convert(varchar(20), @MaxPerMatchv2), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv2>0 AND @MinBetv2>0 AND @MinBetv2<@MinMinBetv2)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Min bet must be equal to or greater than Agent min bet (for Basketball)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10006,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](2,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv2) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv2>0 AND @MaxBetv2>0 AND @MaxBetv2>@MaxMaxBetv2)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max bet must be equal to or less than Agent max bet (for Basketball)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10007,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](2,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv2) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv2>0 AND @MaxPerMatchv2>0 AND @MaxPerMatchv2>@MaxMaxPerMatchv2)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Basketball)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10008,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](2,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv2) + ').', @ErrCode = 113
				
		return
	END
END

IF @UpdateMinMaxBetv3 = 1
BEGIN
	if (@MinBetv3 <> 0 and @MaxBetv3 <> 0 and @MinBetv3>@MaxBetv3) or (@MaxBetv3 <> 0 and @MaxPerMatchv3 <> 0 and @MaxBetv3>@MaxPerMatchv3)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Min bet must be less than max bet and max bet must be less than max bet per match (for Football)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10005,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](3,@Language) + ')'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv3) + '-' + convert(varchar(20), @MaxBetv3) + '-' + convert(varchar(20), @MaxPerMatchv3), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv3>0 AND @MinBetv3>0 AND @MinBetv3<@MinMinBetv3)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Min bet must be equal to or greater than Agent min bet (for Football)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10006,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](3,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv3) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv3>0 AND @MaxBetv3>0 AND @MaxBetv3>@MaxMaxBetv3)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max bet must be equal to or less than Agent max bet (for Football)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10007,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](3,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv3) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv3>0 AND @MaxPerMatchv3>0 AND @MaxPerMatchv3>@MaxMaxPerMatchv3)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Football)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10008,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](3,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv3) + ').', @ErrCode = 113
				
		return
	END
END

IF @UpdateMinMaxBetv5 = 1
BEGIN
	if (@MinBetv5 <> 0 and @MaxBetv5 <> 0 and @MinBetv5>@MaxBetv5) or (@MaxBetv5 <> 0 and @MaxPerMatchv5 <> 0 and @MaxBetv5>@MaxPerMatchv5)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Min bet must be less than max bet and max bet must be less than max bet per match (for Tennis)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10005,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](5,@Language) + ')'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv5) + '-' + convert(varchar(20), @MaxBetv5) + '-' + convert(varchar(20), @MaxPerMatchv5), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv5>0 AND @MinBetv5>0 AND @MinBetv5<@MinMinBetv5)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Min bet must be equal to or greater than Agent min bet (for Tennis)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10006,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](5,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv5) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv5>0 AND @MaxBetv5>0 AND @MaxBetv5>@MaxMaxBetv5)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max bet must be equal to or less than Agent max bet (for Tennis)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10007,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](5,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv5) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv5>0 AND @MaxPerMatchv5>0 AND @MaxPerMatchv5>@MaxMaxPerMatchv5)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match  (for Tennis)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10008,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](5,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv5) + ').', @ErrCode = 113
				
		return
	END
END

IF @UpdateMinMaxBetv8 = 1
BEGIN
	if (@MinBetv8 <> 0 and @MaxBetv8 <> 0 and @MinBetv8>@MaxBetv8) or (@MaxBetv8 <> 0 and @MaxPerMatchv8 <> 0 and @MaxBetv8>@MaxPerMatchv8)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Min bet must be less than max bet and max bet must be less than max bet per match (for Baseball)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10005,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](8,@Language) + ')'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv8) + '-' + convert(varchar(20), @MaxBetv8) + '-' + convert(varchar(20), @MaxPerMatchv8), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv8>0 AND @MinBetv8>0 AND @MinBetv8<@MinMinBetv8)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Min bet must be equal to or greater than Agent min bet (for Baseball)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10006,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](8,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv8) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv8>0 AND @MaxBetv8>0 AND @MaxBetv8>@MaxMaxBetv8)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max bet must be equal to or less than Agent max bet (for Baseball)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10007,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](8,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv8) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv8>0 AND @MaxPerMatchv8>0 AND @MaxPerMatchv8>@MaxMaxPerMatchv8)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Baseball)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10008,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](8,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv8) + ').', @ErrCode = 113
				
		return
	END
END

IF @UpdateMinMaxBetv10 = 1
BEGIN
	if (@MinBetv10 <> 0 and @MaxBetv10 <> 0 and @MinBetv10>@MaxBetv10) or (@MaxBetv10 <> 0 and @MaxPerMatchv10 <> 0 and @MaxBetv10>@MaxPerMatchv10)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Min bet must be less than max bet and max bet must be less than max bet per match (for Golf)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10005,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](10,@Language) + ')'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv10) + '-' + convert(varchar(20), @MaxBetv10) + '-' + convert(varchar(20), @MaxPerMatchv10), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv10>0 AND @MinBetv10>0 AND @MinBetv10<@MinMinBetv10)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Min bet must be equal to or greater than Agent min bet (for Golf)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10006,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](10,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv10) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv10>0 AND @MaxBetv10>0 AND @MaxBetv10>@MaxMaxBetv10)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max bet must be equal to or less than Agent max bet (for Golf)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10007,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](10,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv10) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv10>0 AND @MaxPerMatchv10>0 AND @MaxPerMatchv10>@MaxMaxPerMatchv10)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Golf)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10008,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](10,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv10) + ').', @ErrCode = 113
				
		return
	END
END

IF @UpdateMinMaxBetv11 = 1
BEGIN
	if (@MinBetv11 <> 0 and @MaxBetv11 <> 0 and @MinBetv11>@MaxBetv11) or (@MaxBetv11 <> 0 and @MaxPerMatchv11 <> 0 and @MaxBetv11>@MaxPerMatchv11)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Min bet must be less than max bet and max bet must be less than max bet per match (for Motorsports)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10005,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](11,@Language) + ')'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv11) + '-' + convert(varchar(20), @MaxBetv11) + '-' + convert(varchar(20), @MaxPerMatchv11), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv11>0 AND @MinBetv11>0 AND @MinBetv11<@MinMinBetv11)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Min bet must be equal to or greater than Agent min bet (for Motorsports)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10006,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](11,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv11) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv11>0 AND @MaxBetv11>0 AND @MaxBetv11>@MaxMaxBetv11)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max bet must be equal to or less than Agent max bet (for Motorsports)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10007,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](11,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv11) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv11>0 AND @MaxPerMatchv11>0 AND @MaxPerMatchv11>@MaxMaxPerMatchv11)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Motorsports)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10008,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](11,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv11) + ').', @ErrCode = 113
				
		return
	END
END

IF @UpdateMinMaxBetv99 = 1
BEGIN
	if (@MinBetv99 <> 0 and @MaxBetv99 <> 0 and @MinBetv99>@MaxBetv99) or (@MaxBetv99 <> 0 and @MaxPerMatchv99 <> 0 and @MaxBetv99>@MaxPerMatchv99)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Min bet must be less than max bet and max bet must be less than max bet per match (for Other sports)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10005,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](99,@Language) + ')'
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv99) + '-' + convert(varchar(20), @MaxBetv99) + '-' + convert(varchar(20), @MaxPerMatchv99), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv99>0 AND @MinBetv99>0 AND @MinBetv99<@MinMinBetv99)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Min bet must be equal to or greater than Agent min bet (for Other sports)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10006,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](99,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv99) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv99>0 AND @MaxBetv99>0 AND @MaxBetv99>@MaxMaxBetv99)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max bet must be equal to or less than Agent max bet (for Other sports)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10007,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](99,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv99) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv99>0 AND @MaxPerMatchv99>0 AND @MaxPerMatchv99>@MaxMaxPerMatchv99)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Other sports)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10008,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](99,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv99) + ').', @ErrCode = 113
				
		return
	END
END

IF @UpdateMinMaxBetv161 = 1
BEGIN
	if (@MinBetv161 <> 0 and @MaxBetv161 <> 0 and @MinBetv161>@MaxBetv161) or (@MaxBetv161 <> 0 and @MaxPerMatchv161 <> 0 and @MaxBetv161>@MaxPerMatchv161)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Min bet must be less than max bet , max bet must be less than max bet per match(for Number Game) '
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10005,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](161,@Language) + ')'
						END						
						+ CHAR(13) + CHAR(10) + ' ('+ CONVERT(VARCHAR(20), @MinBetv161) + '-' + CONVERT(VARCHAR(20), @MaxBetv161) + '-' + CONVERT(VARCHAR(20), @MaxPerMatchv161) +').', @ErrCode = 111
							
		RETURN
	END
	/*      ----------Lukas
	IF  (@MaxBetv161 <> 0 and @MaxPerBallv161 <> 0  and @MaxBetv161>@MaxPerBallv161) or (@MaxPerBallv161 <> 0 and @MaxPerMatchv161 <> 0  and @MaxPerBallv161>@MaxPerMatchv161)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
							CASE @Language 
								WHEN 'E' THEN 'Max Per Ball must be greater than or equal to Max Bet and less than or equal to Max Per Match (for Number Game) '
								WHEN 'CS' THEN N'单粒球最高投注必須大於最高投注和低於单场游戏最高投注'
								WHEN 'CT' THEN N'單粒球最高投注必須大於最高投注和低於單場遊戲最高投注'
								WHEN 'TH' THEN N'ค่าสูงสุดต่อบอลต้องสูงกว่าการเดิมพันสูงสุดและน้อยกว่าการตั้งค่าสูงสุดของการแข่งขัน'
								WHEN 'J' THEN N'Max Per Ball must be greater than or equal to Max Bet and less than or equal to Max Per Match (for Number Game)'
								WHEN 'KO' THEN N'Max Per Ball must be greater than or equal to Max Bet and less than or equal to Max Per Match (for Number Game)'
								ELSE N'Max Per Ball must be greater than or equal to Max Bet and less than or equal to Max Per Match (for Number Game)'
							END						
							+ CHAR(13) + CHAR(10) + ' (' + CONVERT(VARCHAR(20), @MaxBetv161) + '-' + CONVERT(VARCHAR(20), @MaxPerMatchv161) + '-' + CONVERT(VARCHAR(20), @MaxPerBallv161) +').', @ErrCode = 111							
			RETURN
	END
	*/
	IF (@MinMinBetv161>0 AND @MinBetv161>0 AND @MinBetv161<@MinMinBetv161)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Min bet must be equal to or greater than Agent min bet (for Number Game)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10006,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](161,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv161) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv161>0 AND @MaxBetv161>0 AND @MaxBetv161>@MaxMaxBetv161)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max bet must be equal to or less than Agent max bet (for Number Game)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10007,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](161,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv161) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv161>0 AND @MaxPerMatchv161>0 AND @MaxPerMatchv161>@MaxMaxPerMatchv161)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Number Game)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10008,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](161,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv161) + ').', @ErrCode = 113
				
		return
	END	
	
	IF (@MaxMaxPerBallv161 > 0 AND @MaxPerBallv161 > 0 AND @MaxPerBallv161 > @MaxMaxPerBallv161)
	BEGIN
		SELECT @ErrMsg=		@UserName + ': '+
						CASE @Language
							WHEN 'E' THEN 'Max Per Ball must be equal to or less than Agent Max Per Ball (Number Game).'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10009,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](161,@Language) + ')'
						END
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerBallv161) + ').', @ErrCode = 113
		RETURN
	END
	
END

IF @UpdateMinMaxBetv164 = 1
BEGIN
	if (@MinBetv164 <> 0 and @MaxBetv164 <> 0 and @MinBetv164>@MaxBetv164) or (@MaxBetv164 <> 0 and @MaxPerMatchv164 <> 0 and @MaxBetv164>@MaxPerMatchv164)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Min bet must be less than max bet , max bet must be less than max bet per match(for Happy 5) '
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10005,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](164,@Language) + ')'
						END						
						+ CHAR(13) + CHAR(10) + ' ('+ CONVERT(VARCHAR(20), @MinBetv164) + '-' + CONVERT(VARCHAR(20), @MaxBetv164) + '-' + CONVERT(VARCHAR(20), @MaxPerMatchv164) +').', @ErrCode = 111
							
		RETURN
	END
	
	IF (@MinMinBetv164>0 AND @MinBetv164>0 AND @MinBetv164<@MinMinBetv164)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Min bet must be equal to or greater than Agent min bet (for Happy 5)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10006,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](164,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv164) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv164>0 AND @MaxBetv164>0 AND @MaxBetv164>@MaxMaxBetv164)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max bet must be equal to or less than Agent max bet (for Happy 5)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10007,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](164,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv164) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv164>0 AND @MaxPerMatchv164>0 AND @MaxPerMatchv164>@MaxMaxPerMatchv164)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Happy 5)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10008,@Language) + ' (' + [dbo].[f_Get_SportNameBySporttype](164,@Language) + ')'
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv164) + ').', @ErrCode = 113
				
		return
	END	
END

IF @UpdateMinMaxBetv99MP = 1
BEGIN
	if (@MinBetv99MP <> 0 and @MaxBetv99MP <> 0 and @MinBetv99MP>@MaxBetv99MP) or (@MaxBetv99MP <> 0 and @MaxPerMatchv99MP <> 0 and @MaxBetv99MP>@MaxPerMatchv99MP)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Min bet must be less than max bet and max bet must be less than max bet per match (for Mix Sports Parlay)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10005,@Language) + case @Language 
																							when 'CS' then N'(供混合体育过关)'
																							when 'CT' then N'(供混合體育過關)'
																							when 'TH' then N'(สำหรับกีฬาบอลชุด)'
																							when 'J' then N'(Mix Sports Parlay)'
																							when 'KO' then N'(Mix Sports Parlay)'
																							when 'VI' then N'(Mix Sports Parlay)'
																							else N'(Mix Sports Parlay)' END
						end						
						+ char(13) + char(10) + convert(varchar(20), @MinBetv99MP) + '-' + convert(varchar(20), @MaxBetv99MP) + '-' + convert(varchar(20), @MaxPerMatchv99MP), @ErrCode = 111
				
		return
	END
	
	IF (@MinMinBetv99MP>0 AND @MinBetv99MP>0 AND @MinBetv99MP<@MinMinBetv99MP)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Min bet must be equal to or greater than Agent min bet (for Mix Sports Parlay)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10006,@Language) + case @Language 
																							when 'CS' then N'(供混合体育过关)'
																							when 'CT' then N'(供混合體育過關)'
																							when 'TH' then N'(สำหรับกีฬาบอลชุด)'
																							when 'J' then N'(Mix Sports Parlay)'
																							when 'KO' then N'(Mix Sports Parlay)'
																							when 'VI' then N'(Mix Sports Parlay)'
																							else N'(Mix Sports Parlay)' END
						END						
						+' (' + CONVERT(VARCHAR(20), @MinMinBetv99MP) + ').', @ErrCode = 112
				
		return
	END	
	IF (@MaxMaxBetv99MP>0 AND @MaxBetv99MP>0 AND @MaxBetv99MP>@MaxMaxBetv99MP)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max bet must be equal to or less than Agent max bet (for Mix Sports Parlay)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10007,@Language) + case @Language 
																							when 'CS' then N'(供混合体育过关)'
																							when 'CT' then N'(供混合體育過關)'
																							when 'TH' then N'(สำหรับกีฬาบอลชุด)'
																							when 'J' then N'(Mix Sports Parlay)'
																							when 'KO' then N'(Mix Sports Parlay)'
																							when 'VI' then N'(Mix Sports Parlay)'
																							else N'(Mix Sports Parlay)' END
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxBetv99MP) + ').', @ErrCode = 113
				
		return
	END
	
	IF (@MaxMaxPerMatchv99MP>0 AND @MaxPerMatchv99MP>0 AND @MaxPerMatchv99MP>@MaxMaxPerMatchv99MP)
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Max Per Match must be equal to or less than Agent Max Per Match (for Mix Sports Parlay)'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](10008,@Language) + case @Language 
																							when 'CS' then N'(供混合体育过关)'
																							when 'CT' then N'(供混合體育過關)'
																							when 'TH' then N'(สำหรับกีฬาบอลชุด)'
																							when 'J' then N'(Mix Sports Parlay)'
																							when 'KO' then N'(Mix Sports Parlay)'
																							when 'VI' then N'(Mix Sports Parlay)'
																							else N'(Mix Sports Parlay)' END
						END						
						+' (' + CONVERT(VARCHAR(20), @MaxMaxPerMatchv99MP) + ').', @ErrCode = 113
				
		return
	END
END


----------
UPDATE custsetting WITH (ROWLOCK, UPDLOCK)
SET
	MinBet = CASE 
				WHEN sporttype=1 THEN (CASE WHEN @UpdateMinMaxBetv1MP = 1 AND bettype = 9 THEN @MinBetv1MP
											WHEN @UpdateMinMaxBet = 1 THEN @MinBet ELSE MinBet END)
											 
				--WHEN (@UpdateMinMaxBet = 1 AND sporttype=1) THEN @MinBet
	
				WHEN (@UpdateMinMaxBetv2 = 1 AND sporttype=2) THEN @MinBetv2
				WHEN (@UpdateMinMaxBetv3 = 1 AND sporttype=3) THEN @MinBetv3
				WHEN (@UpdateMinMaxBetv5 = 1 AND sporttype=5) THEN @MinBetv5
				WHEN (@UpdateMinMaxBetv8 = 1 AND sporttype=8) THEN @MinBetv8
				WHEN (@UpdateMinMaxBetv10 = 1 AND sporttype=10) THEN @MinBetv10
				WHEN (@UpdateMinMaxBetv11 = 1 AND sporttype=11) THEN @MinBetv11				
--				WHEN (@UpdateMinMaxBetv99 = 1 AND sporttype=99) THEN @MinBetv99
--				WHEN (@UpdateMinMaxBetv99MP = 1 AND sporttype=99) THEN @MinBetv99MP
			
				
				WHEN sporttype=99 THEN (CASE WHEN @UpdateMinMaxBetv99MP = 1 AND bettype = 9 THEN @MinBetv99MP
											 WHEN @UpdateMinMaxBetv99 = 1 AND bettype <> 9 THEN @MinBetv99 ELSE MinBet END)
			
			ELSE minbet END,
	MaxBet = CASE 
				
				WHEN sporttype=1 THEN (CASE WHEN @UpdateMinMaxBetv1MP = 1 AND bettype = 9 THEN @MaxBetv1MP
											 WHEN @UpdateMinMaxBet = 1 THEN @MaxBet ELSE MaxBet END)
				
				
				WHEN (@UpdateMinMaxBet = 1 AND sporttype=1) THEN @MaxBet
				WHEN (@UpdateMinMaxBetv2 = 1 AND sporttype=2) THEN @MaxBetv2
				WHEN (@UpdateMinMaxBetv3 = 1 AND sporttype=3) THEN @MaxBetv3
				WHEN (@UpdateMinMaxBetv5 = 1 AND sporttype=5) THEN @MaxBetv5
				WHEN (@UpdateMinMaxBetv8 = 1 AND sporttype=8) THEN @MaxBetv8
				WHEN (@UpdateMinMaxBetv10 = 1 AND sporttype=10) THEN @MaxBetv10
				WHEN (@UpdateMinMaxBetv11 = 1 AND sporttype=11) THEN @MaxBetv11
			
				WHEN sporttype=99 THEN (CASE WHEN @UpdateMinMaxBetv99MP = 1 AND bettype = 9 THEN @MaxBetv99MP
											 WHEN @UpdateMinMaxBetv99 = 1 AND bettype <> 9 THEN @MaxBetv99 ELSE MaxBet END)
				
			ELSE MaxBet END
WHERE custid=@custid

UPDATE custsetting3rd WITH (ROWLOCK, UPDLOCK)
SET
	MinBet = CASE WHEN (@UpdateMinMaxBetv161 = 1 AND sporttype=161) THEN @MinBetv161
				WHEN (@UpdateMinMaxBetv164 = 1 AND sporttype=164) THEN @MinBetv164	
			ELSE minbet END,
	MaxBet = CASE WHEN (@UpdateMinMaxBetv161 = 1 AND sporttype=161) THEN @MaxBetv161				
				WHEN (@UpdateMinMaxBetv164 = 1 AND sporttype=164) THEN @MaxBetv164	
			ELSE MaxBet END
WHERE custid=@custid

if (@@error <> 0)
begin
	
	Select @ErrMsg = @UserName + ': '+
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						ELSE [dbo].[f_Get_MsgNamebyMsgID](90001,@Language)
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
	MaxPerMatch99MP=case when @UpdateMinMaxBetv99MP=1 then @MaxPerMatchv99MP else MaxPerMatch99MP end,
	
	MaxPerMatch1MP=case when @UpdateMinMaxBetv1MP=1 then @MaxPerMatchv1MP else MaxPerMatch1MP end,
	
	
	MaxPerMatch161=case when @UpdateMinMaxBetv161=1 then @MaxPerMatchv161 else MaxPerMatch161 end,
	MaxPerBall161 = CASE WHEN @UpdateMinMaxBetv161=1 THEN @MaxPerBallv161 ELSE MaxPerBall161 END,
	MaxPerMatch164=case when @UpdateMinMaxBetv164=1 then @MaxPerMatchv164 else MaxPerMatch164 end
where custid = @custid 

if (@@error <> 0)
begin
	
	Select @ErrMsg = @UserName + ': '+
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						ELSE [dbo].[f_Get_MsgNamebyMsgID](90001,@Language)
					end, @ErrCode = 115
	return
end

Declare @RoleID int
SELECT @RoleID = RoleID
FROM custinfo WITH(NOLOCK)
WHERE custid = @CustID
IF @RoleID=2 --Agent Level
BEGIN	
	-- Compare old value & new value Betting Limit: Popup Message For Betting Limit 
	IF (@MinBet != @old_MinBet OR @MaxBet != @old_MaxBet OR @MaxPerMatch != @old_MaxPerMatch
		OR @MinBetv2 != @old_MinBetv2 OR @MaxBetv2 != @old_MaxBetv2 OR @MaxPerMatchv2 != @old_MaxPerMatchv2
		OR @MinBetv3 != @old_MinBetv3 OR @MaxBetv3 != @old_MaxBetv3 OR @MaxPerMatchv3 != @old_MaxPerMatchv3
		OR @MinBetv5 != @old_MinBetv5 OR @MaxBetv5 != @old_MaxBetv5 OR @MaxPerMatchv5 != @old_MaxPerMatchv5
		OR @MinBetv8 != @old_MinBetv8 OR @MaxBetv8 != @old_MaxBetv8 OR @MaxPerMatchv8 != @old_MaxPerMatchv8
		OR @MinBetv10 != @old_MinBetv10 OR @MaxBetv10 != @old_MaxBetv10 OR @MaxPerMatchv10 != @old_MaxPerMatchv10
		OR @MinBetv11 != @old_MinBetv11 OR @MaxBetv11 != @old_MaxBetv11 OR @MaxPerMatchv11 != @old_MaxPerMatchv11
		OR @MinBetv99 != @old_MinBetv99 OR @MaxBetv99 != @old_MaxBetv99 OR @MaxPerMatchv99 != @old_MaxPerMatchv99
		OR @MinBetv99MP != @old_MinBetv99MP OR @MaxBetv99MP != @old_MaxBetv99MP OR @MaxPerMatchv99MP != @old_MaxPerMatchv99MP
		
		OR @MinBetv1MP != @old_MinBetv1MP OR @MaxBetv1MP != @old_MaxBetv1MP OR @MaxPerMatchv1MP != @old_MaxPerMatchv1MP
		
		
		OR @MinBetv161 != @old_MinBetv161 OR @MaxBetv161 != @old_MaxBetv161 OR @MaxPerMatchv161 != @old_MaxPerMatchv161 OR @MaxPerBallv161 != @old_MaxPerBallv161 
		OR @MinBetv164 != @old_MinBetv164 OR @MaxBetv164 != @old_MaxBetv164 OR @MaxPerMatchv164 != @old_MaxPerMatchv164)
	BEGIN
		EXEC DBONUSER.On_User.dbo.Age_MessageNoticeUpd @custID = @custid, @userID = @UserID, @TypeID = 2
	END		
END

Declare @LogSPData varchar(8000)
Declare @TrackingValue2 varchar(8000)

Select @LogSPData ='<Age_CustomerUpdMemBetSetting custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'MinB="'+ coalesce(cast(@minbet as varchar(50)),space(1))  + '" ' +
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
'MinBv99MP="'+ coalesce(cast(@minbetv99mp as varchar(50)),space(1)) + '" ' +
'MaxBv99MP="'+ coalesce(cast(@maxbetv99mp as varchar(50)),space(1)) + '" ' +
'MPMv99MP="'+ coalesce(cast(@maxpermatchv99mp as varchar(50)),space(1)) + '" ' +

'MinBv1MP="'+ coalesce(cast(@minbetv1mp as varchar(50)),space(1)) + '" ' +
'MaxBv1MP="'+ coalesce(cast(@maxbetv1mp as varchar(50)),space(1)) + '" ' +
'MPMv1MP="'+ coalesce(cast(@maxpermatchv1mp as varchar(50)),space(1)) + '" ' +


'MinBv161="'+ coalesce(cast(@minbetv161 as varchar(50)),space(1)) + '" ' +
'MaxBv161="'+ coalesce(cast(@maxbetv161 as varchar(50)),space(1)) + '" ' +
'MPBv161="'+ coalesce(cast(@maxperballv161 as varchar(50)),space(1)) + '" ' +
'MPMv161="'+ coalesce(cast(@maxpermatchv161 as varchar(50)),space(1)) + '" ' +

'MinBv164="'+ coalesce(cast(@minbetv164 as varchar(50)),space(1)) + '" ' +
'MaxBv164="'+ coalesce(cast(@maxbetv164 as varchar(50)),space(1)) + '" ' +
'MPMv164="'+ coalesce(cast(@maxpermatchv164 as varchar(50)),space(1)) + '" ' +

'UMMB="'+ coalesce(cast(@UpdateMinMaxBet as varchar(50)),space(1)) + '" ' +
'UMMBv2="'+ coalesce(cast(@UpdateMinMaxBetv2 as varchar(50)),space(1)) + '" ' +
'UMMBv3="'+ coalesce(cast(@UpdateMinMaxBetv3 as varchar(50)),space(1)) + '" ' +
'UMMBv5="'+ coalesce(cast(@UpdateMinMaxBetv5 as varchar(50)),space(1)) + '" ' +
'UMMBv8="'+ coalesce(cast(@UpdateMinMaxBetv8 as varchar(50)),space(1)) + '" ' +
'UMMBv10="'+ coalesce(cast(@UpdateMinMaxBetv10 as varchar(50)),space(1)) + '" ' +
'UMMBv11="'+ coalesce(cast(@UpdateMinMaxBetv11 as varchar(50)),space(1)) + '" ' +
'UMMBv99="'+ coalesce(cast(@UpdateMinMaxBetv99 as varchar(50)),space(1)) + '" ' +
'UMMBv99MP="'+ coalesce(cast(@UpdateMinMaxBetv99MP as varchar(50)),space(1)) + '" ' +

'UMMBv1MP="'+ coalesce(cast(@UpdateMinMaxBetv1MP as varchar(50)),space(1)) + '" ' +


'UMMBv161="'+ coalesce(cast(@UpdateMinMaxBetv161 as varchar(50)),space(1)) + '" ' +
'UMMBv164="'+ coalesce(cast(@UpdateMinMaxBetv164 as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1))  + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />'


Select @TrackingValue2 ='<Age_CustomerUpdMemBetSetting custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'MinB="'+ coalesce(cast(@Old_minbet as varchar(50)),space(1))  + '" ' +
'MaxB="'+ coalesce(cast(@Old_maxbet as varchar(50)),space(1)) + '" ' +
'MPM="'+ coalesce(cast(@Old_maxpermatch as varchar(50)),space(1)) + '" ' +
'MinBv2="'+ coalesce(cast(@Old_minbetv2 as varchar(50)),space(1)) + '" ' +
'MaxBv2="'+ coalesce(cast(@Old_maxbetv2 as varchar(50)),space(1)) + '" ' +
'MPMv2="'+ coalesce(cast(@Old_maxpermatchv2 as varchar(50)),space(1)) + '" ' +
'MinBv3="'+ coalesce(cast(@Old_minbetv3 as varchar(50)),space(1)) + '" ' +
'MaxBv3="'+ coalesce(cast(@Old_maxbetv3 as varchar(50)),space(1)) + '" ' +
'MPMv3="'+ coalesce(cast(@Old_maxpermatchv3 as varchar(50)),space(1)) + '" ' +
'MinBv5="'+ coalesce(cast(@Old_minbetv5 as varchar(50)),space(1)) + '" ' +
'MaxBv5="'+ coalesce(cast(@Old_maxbetv5 as varchar(50)),space(1)) + '" ' +
'MPMv5="'+ coalesce(cast(@Old_maxpermatchv5 as varchar(50)),space(1)) + '" ' +
'MinBv8="'+ coalesce(cast(@Old_minbetv8 as varchar(50)),space(1)) + '" ' +
'MaxBv8="'+ coalesce(cast(@Old_maxbetv8 as varchar(50)),space(1)) + '" ' +
'MPMv8="'+ coalesce(cast(@Old_maxpermatchv8 as varchar(50)),space(1)) + '" ' +
'MinBv10="'+ coalesce(cast(@Old_minbetv10 as varchar(50)),space(1)) + '" ' +
'MaxBv10="'+ coalesce(cast(@Old_maxbetv10 as varchar(50)),space(1)) + '" ' +
'MPMv10="'+ coalesce(cast(@Old_maxpermatchv10 as varchar(50)),space(1)) + '" ' +
'MinBv11="'+ coalesce(cast(@Old_minbetv11 as varchar(50)),space(1)) + '" ' +
'MaxBv11="'+ coalesce(cast(@Old_maxbetv11 as varchar(50)),space(1)) + '" ' +
'MPMv11="'+ coalesce(cast(@Old_maxpermatchv11 as varchar(50)),space(1)) + '" ' +
'MinBv99="'+ coalesce(cast(@Old_minbetv99 as varchar(50)),space(1)) + '" ' +
'MaxBv99="'+ coalesce(cast(@Old_maxbetv99 as varchar(50)),space(1)) + '" ' +
'MPMv99="'+ coalesce(cast(@Old_maxpermatchv99 as varchar(50)),space(1)) + '" ' +
'MinBv99MP="'+ coalesce(cast(@Old_minbetv99mp as varchar(50)),space(1)) + '" ' +
'MaxBv99MP="'+ coalesce(cast(@Old_maxbetv99mp as varchar(50)),space(1)) + '" ' +
'MPMv99MP="'+ coalesce(cast(@Old_maxpermatchv99mp as varchar(50)),space(1)) + '" ' +

'MinBv1MP="'+ coalesce(cast(@Old_minbetv1mp as varchar(50)),space(1)) + '" ' +
'MaxBv1MP="'+ coalesce(cast(@Old_maxbetv1mp as varchar(50)),space(1)) + '" ' +
'MPMv1MP="'+ coalesce(cast(@Old_maxpermatchv1mp as varchar(50)),space(1)) + '" ' +

'MinBv161="'+ coalesce(cast(@Old_minbetv161 as varchar(50)),space(1)) + '" ' +
'MaxBv161="'+ coalesce(cast(@Old_maxbetv161 as varchar(50)),space(1)) + '" ' +
'MPBv161="'+ coalesce(cast(@Old_maxperballv161 as varchar(50)),space(1)) + '" ' +
'MPMv161="'+ coalesce(cast(@Old_maxpermatchv161 as varchar(50)),space(1)) + '" ' +

'MinBv164="'+ coalesce(cast(@Old_minbetv164 as varchar(50)),space(1)) + '" ' +
'MaxBv164="'+ coalesce(cast(@Old_maxbetv164 as varchar(50)),space(1)) + '" ' +
'MPMv164="'+ coalesce(cast(@Old_maxpermatchv164 as varchar(50)),space(1)) + '" ' +

'UMMB="'+ coalesce(cast(@UpdateMinMaxBet as varchar(50)),space(1)) + '" ' +
'UMMBv2="'+ coalesce(cast(@UpdateMinMaxBetv2 as varchar(50)),space(1)) + '" ' +
'UMMBv3="'+ coalesce(cast(@UpdateMinMaxBetv3 as varchar(50)),space(1)) + '" ' +
'UMMBv5="'+ coalesce(cast(@UpdateMinMaxBetv5 as varchar(50)),space(1)) + '" ' +
'UMMBv8="'+ coalesce(cast(@UpdateMinMaxBetv8 as varchar(50)),space(1)) + '" ' +
'UMMBv10="'+ coalesce(cast(@UpdateMinMaxBetv10 as varchar(50)),space(1)) + '" ' +
'UMMBv11="'+ coalesce(cast(@UpdateMinMaxBetv11 as varchar(50)),space(1)) + '" ' +
'UMMBv99="'+ coalesce(cast(@UpdateMinMaxBetv99 as varchar(50)),space(1)) + '" ' +
'UMMBv99MP="'+ coalesce(cast(@UpdateMinMaxBetv99MP as varchar(50)),space(1)) + '" ' +

'UMMBv1MP="'+ coalesce(cast(@UpdateMinMaxBetv1MP as varchar(50)),space(1)) + '" ' +
'UMMBv161="'+ coalesce(cast(@UpdateMinMaxBetv161 as varchar(50)),space(1)) + '" ' +
'UMMBv164="'+ coalesce(cast(@UpdateMinMaxBetv164 as varchar(50)),space(1)) + '" ' +

'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1))  + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 313,
		@TrackingValue = @LogSPData,
		@TrackingValue2 = @TrackingValue2,
		@duration = @duration
END TRY
BEGIN CATCH
	Select @LogSPData ='<Age_CustomerUpdMemBetSetting custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
	'MinB="'+ coalesce(cast(@minbet as varchar(50)),space(1))  + '" ' +
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
	'MinBv99MP="'+ coalesce(cast(@minbetv99mp as varchar(50)),space(1)) + '" ' +
	'MaxBv99MP="'+ coalesce(cast(@maxbetv99mp as varchar(50)),space(1)) + '" ' +
	'MPMv99MP="'+ coalesce(cast(@maxpermatchv99mp as varchar(50)),space(1)) + '" ' +
	
	'MinBv1MP="'+ coalesce(cast(@minbetv1mp as varchar(50)),space(1)) + '" ' +
	'MaxBv1MP="'+ coalesce(cast(@maxbetv1mp as varchar(50)),space(1)) + '" ' +
	'MPMv1MP="'+ coalesce(cast(@maxpermatchv1mp as varchar(50)),space(1)) + '" ' +
	

	'MinBv161="'+ coalesce(cast(@minbetv161 as varchar(50)),space(1)) + '" ' +
	'MaxBv161="'+ coalesce(cast(@maxbetv161 as varchar(50)),space(1)) + '" ' +
	'MPBv161="'+ coalesce(cast(@maxperballv161 as varchar(50)),space(1)) + '" ' +
	'MPMv161="'+ coalesce(cast(@maxpermatchv161 as varchar(50)),space(1)) + '" ' +
	
	'MinBv164="'+ coalesce(cast(@minbetv164 as varchar(50)),space(1)) + '" ' +
	'MaxBv164="'+ coalesce(cast(@maxbetv164 as varchar(50)),space(1)) + '" ' +	
	'MPMv164="'+ coalesce(cast(@maxpermatchv164 as varchar(50)),space(1)) + '" ' +
	
	'UMMB="'+ coalesce(cast(@UpdateMinMaxBet as varchar(50)),space(1)) + '" ' +
	'UMMBv2="'+ coalesce(cast(@UpdateMinMaxBetv2 as varchar(50)),space(1)) + '" ' +
	'UMMBv3="'+ coalesce(cast(@UpdateMinMaxBetv3 as varchar(50)),space(1)) + '" ' +
	'UMMBv5="'+ coalesce(cast(@UpdateMinMaxBetv5 as varchar(50)),space(1)) + '" ' +
	'UMMBv8="'+ coalesce(cast(@UpdateMinMaxBetv8 as varchar(50)),space(1)) + '" ' +
	'UMMBv10="'+ coalesce(cast(@UpdateMinMaxBetv10 as varchar(50)),space(1)) + '" ' +
	'UMMBv11="'+ coalesce(cast(@UpdateMinMaxBetv11 as varchar(50)),space(1)) + '" ' +
	'UMMBv99="'+ coalesce(cast(@UpdateMinMaxBetv99 as varchar(50)),space(1)) + '" ' +
	'UMMBv99MP="'+ coalesce(cast(@UpdateMinMaxBetv99MP as varchar(50)),space(1)) + '" ' +
	
	'UMMBv1MP="'+ coalesce(cast(@UpdateMinMaxBetv1MP as varchar(50)),space(1)) + '" ' +
	

	'UMMBv161="'+ coalesce(cast(@UpdateMinMaxBetv161 as varchar(50)),space(1)) + '" ' +
	'UMMBv164="'+ coalesce(cast(@UpdateMinMaxBetv164 as varchar(50)),space(1)) + '" ' +
	'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
	'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1))  + '" ' +
	'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
	'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
	'ErrCode="'+ coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + '" ' +
	'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(5000)),space(1)) + '" />'


	Select @TrackingValue2 ='<Age_CustomerUpdMemBetSetting custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
	'MinB="'+ coalesce(cast(@Old_minbet as varchar(50)),space(1))  + '" ' +
	'MaxB="'+ coalesce(cast(@Old_maxbet as varchar(50)),space(1)) + '" ' +
	'MPM="'+ coalesce(cast(@Old_maxpermatch as varchar(50)),space(1)) + '" ' +
	'MinBv2="'+ coalesce(cast(@Old_minbetv2 as varchar(50)),space(1)) + '" ' +
	'MaxBv2="'+ coalesce(cast(@Old_maxbetv2 as varchar(50)),space(1)) + '" ' +
	'MPMv2="'+ coalesce(cast(@Old_maxpermatchv2 as varchar(50)),space(1)) + '" ' +
	'MinBv3="'+ coalesce(cast(@Old_minbetv3 as varchar(50)),space(1)) + '" ' +
	'MaxBv3="'+ coalesce(cast(@Old_maxbetv3 as varchar(50)),space(1)) + '" ' +
	'MPMv3="'+ coalesce(cast(@Old_maxpermatchv3 as varchar(50)),space(1)) + '" ' +
	'MinBv5="'+ coalesce(cast(@Old_minbetv5 as varchar(50)),space(1)) + '" ' +
	'MaxBv5="'+ coalesce(cast(@Old_maxbetv5 as varchar(50)),space(1)) + '" ' +
	'MPMv5="'+ coalesce(cast(@Old_maxpermatchv5 as varchar(50)),space(1)) + '" ' +
	'MinBv8="'+ coalesce(cast(@Old_minbetv8 as varchar(50)),space(1)) + '" ' +
	'MaxBv8="'+ coalesce(cast(@Old_maxbetv8 as varchar(50)),space(1)) + '" ' +
	'MPMv8="'+ coalesce(cast(@Old_maxpermatchv8 as varchar(50)),space(1)) + '" ' +
	'MinBv10="'+ coalesce(cast(@Old_minbetv10 as varchar(50)),space(1)) + '" ' +
	'MaxBv10="'+ coalesce(cast(@Old_maxbetv10 as varchar(50)),space(1)) + '" ' +
	'MPMv10="'+ coalesce(cast(@Old_maxpermatchv10 as varchar(50)),space(1)) + '" ' +
	'MinBv11="'+ coalesce(cast(@Old_minbetv11 as varchar(50)),space(1)) + '" ' +
	'MaxBv11="'+ coalesce(cast(@Old_maxbetv11 as varchar(50)),space(1)) + '" ' +
	'MPMv11="'+ coalesce(cast(@Old_maxpermatchv11 as varchar(50)),space(1)) + '" ' +
	'MinBv99="'+ coalesce(cast(@Old_minbetv99 as varchar(50)),space(1)) + '" ' +
	'MaxBv99="'+ coalesce(cast(@Old_maxbetv99 as varchar(50)),space(1)) + '" ' +
	'MPMv99="'+ coalesce(cast(@Old_maxpermatchv99 as varchar(50)),space(1)) + '" ' +
	'MinBv99MP="'+ coalesce(cast(@Old_minbetv99mp as varchar(50)),space(1)) + '" ' +
	'MaxBv99MP="'+ coalesce(cast(@Old_maxbetv99mp as varchar(50)),space(1)) + '" ' +
	'MPMv99MP="'+ coalesce(cast(@Old_maxpermatchv99mp as varchar(50)),space(1)) + '" ' +
	
	'MinBv1MP="'+ coalesce(cast(@Old_minbetv1mp as varchar(50)),space(1)) + '" ' +
	'MaxBv1MP="'+ coalesce(cast(@Old_maxbetv1mp as varchar(50)),space(1)) + '" ' +
	'MPMv1MP="'+ coalesce(cast(@Old_maxpermatchv1mp as varchar(50)),space(1)) + '" ' +

	'MinBv161="'+ coalesce(cast(@Old_minbetv161 as varchar(50)),space(1)) + '" ' +
	'MaxBv161="'+ coalesce(cast(@Old_maxbetv161 as varchar(50)),space(1)) + '" ' +
	'MPBv161="'+ coalesce(cast(@Old_maxperballv161 as varchar(50)),space(1)) + '" ' +
	'MPMv161="'+ coalesce(cast(@Old_maxpermatchv161 as varchar(50)),space(1)) + '" ' +
	
	'MinBv164="'+ coalesce(cast(@Old_minbetv164 as varchar(50)),space(1)) + '" ' +
	'MaxBv164="'+ coalesce(cast(@Old_maxbetv164 as varchar(50)),space(1)) + '" ' +	
	'MPMv164="'+ coalesce(cast(@Old_maxpermatchv164 as varchar(50)),space(1)) + '" ' +
	
	'UMMB="'+ coalesce(cast(@UpdateMinMaxBet as varchar(50)),space(1)) + '" ' +
	'UMMBv2="'+ coalesce(cast(@UpdateMinMaxBetv2 as varchar(50)),space(1)) + '" ' +
	'UMMBv3="'+ coalesce(cast(@UpdateMinMaxBetv3 as varchar(50)),space(1)) + '" ' +
	'UMMBv5="'+ coalesce(cast(@UpdateMinMaxBetv5 as varchar(50)),space(1)) + '" ' +
	'UMMBv8="'+ coalesce(cast(@UpdateMinMaxBetv8 as varchar(50)),space(1)) + '" ' +
	'UMMBv10="'+ coalesce(cast(@UpdateMinMaxBetv10 as varchar(50)),space(1)) + '" ' +
	'UMMBv11="'+ coalesce(cast(@UpdateMinMaxBetv11 as varchar(50)),space(1)) + '" ' +
	'UMMBv99="'+ coalesce(cast(@UpdateMinMaxBetv99 as varchar(50)),space(1)) + '" ' +
	'UMMBv99MP="'+ coalesce(cast(@UpdateMinMaxBetv99MP as varchar(50)),space(1)) + '" ' +
	
	'UMMBv1MP="'+ coalesce(cast(@UpdateMinMaxBetv1MP as varchar(50)),space(1)) + '" ' +

	'UMMBv161="'+ coalesce(cast(@UpdateMinMaxBetv161 as varchar(50)),space(1)) + '" ' +
	'UMMBv164="'+ coalesce(cast(@UpdateMinMaxBetv164 as varchar(50)),space(1)) + '" ' +
	'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
	'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1))  + '" ' +
	'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
	'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
	'ErrCode="'+ coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + '" ' +
	'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(5000)),space(1)) + '" />'

	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 313,
		@TrackingValue = @LogSPData,
		@TrackingValue2 = @TrackingValue2,
		@duration = @duration
END CATCH

GO
