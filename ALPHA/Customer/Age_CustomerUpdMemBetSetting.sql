/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap,wsv_alp,wsv_xnap" viewers="" isFunction="0"></info>*/
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
	@UpdateMinMaxBetMP BIT = 1,	
	 
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

	@maxPOpermatch      MONEY = NULL, 
    @maxPOpermatchv2    MONEY = NULL, 
    @maxPOpermatchv3    MONEY = NULL, 
    @maxPOpermatchv5    MONEY = NULL, 
    @maxPOpermatchv8    MONEY = NULL, 
    @maxPOpermatchv10   MONEY = NULL, 
    @maxPOpermatchv11   MONEY = NULL, 
    @maxPOpermatchv99   MONEY = NULL, 
    @maxPOpermatchv99mp MONEY = NULL, 
    @maxPOpermatchv1mp  MONEY = NULL,

	--- Saba soccer
	@minbetv1saba money = NULL,
	@maxbetv1saba money = NULL,
	@maxpermatchv1saba money  = NULL,
	@maxPOpermatchv1saba money = NULL,

	--- Saba basketball
	@minbetv2saba money = NULL,
	@maxbetv2saba money = NULL,
	@maxpermatchv2saba money  = NULL,
	@maxPOpermatchv2saba money = NULL,

	@UpdateMinMaxBetv1saba bit = 1,
	@UpdateMinMaxBetv2saba bit = 1,

	-- Update Multiple
	@UpdateMultiple bit = 0,	
	@UpdateMultipleSuper bit = 0,
	
	@systemID TINYINT = NULL,
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
	- 20210510@Eden: Enhancement for not relying on DB On_User [redmine: #154507]
	- 20210802@Eden: Max Payout Per Match [redmine: #158073]
	- 20211005@Johnson: change param @UpdateMinMaxBetv1MP to @UpdateMinMaxBetMP [redmine:#161425]
	- 20210831@Eden: Break setting for Saba Soccer/Basketball [redmine: #159626]
	- 20221123@Elodie: Migrate NG and Keno to DCS structure [Redmine: #179711]
	- 20230515@Tacy: EXT NAP - Allow headlines update Bet Settings on multiple supers [RedmineID: #186773]

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
BEGIN
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

	EXEC dbo.Acc_CustomerUpd_BetSetting
		@custid = @custid,
		@minbet = @minbet,
		@maxbet = @maxbet,
		@maxpermatch = @maxpermatch,
		@minbetv2 = @minbetv2,
		@maxbetv2 = @maxbetv2,
		@maxpermatchv2 = @maxpermatchv2,
		@minbetv3 = @minbetv3,
		@maxbetv3 = @maxbetv3,
		@maxpermatchv3 = @maxpermatchv3,
		@minbetv5 = @minbetv5,
		@maxbetv5 = @maxbetv5,
		@maxpermatchv5 = @maxpermatchv5,
		@minbetv8 = @minbetv8,
		@maxbetv8 = @maxbetv8,
		@maxpermatchv8 = @maxpermatchv8,
		@minbetv10 = @minbetv10,
		@maxbetv10 = @maxbetv10,
		@maxpermatchv10 = @maxpermatchv10,
		@minbetv11 = @minbetv11,
		@maxbetv11 = @maxbetv11,
		@maxpermatchv11 = @maxpermatchv11,

		@minbetv99 = @minbetv99,
		@maxbetv99 = @maxbetv99,
		@maxpermatchv99 = @maxpermatchv99,

		-- mixed sports	
		@minbetv99mp = @minbetv99mp,
		@maxbetv99mp = @maxbetv99mp,
		@maxpermatchv99mp = @maxpermatchv99mp,
			
		-- soccer sports	
		@minbetv1mp = @minbetv1mp,
		@maxbetv1mp = @maxbetv1mp,
		@maxpermatchv1mp = @maxpermatchv1mp,			
				
		--MaxPayOutPerMatch
		@maxPOpermatch      = @maxPOpermatch,
		@maxPOpermatchv2    = @maxPOpermatchv2,    
		@maxPOpermatchv3    = @maxPOpermatchv3,    
		@maxPOpermatchv5    = @maxPOpermatchv5,   
		@maxPOpermatchv8    = @maxPOpermatchv8,    
		@maxPOpermatchv10   = @maxPOpermatchv10,   
		@maxPOpermatchv11   = @maxPOpermatchv11,   
		@maxPOpermatchv99   = @maxPOpermatchv99,   
		@maxPOpermatchv99mp = @maxPOpermatchv99mp, 
		@maxPOpermatchv1mp  = @maxPOpermatchv1mp, 

		@UpdateMinMaxBet = @UpdateMinMaxBet,
		@UpdateMinMaxBetv2 = @UpdateMinMaxBetv2,
		@UpdateMinMaxBetv3 = @UpdateMinMaxBetv3,
		@UpdateMinMaxBetv5 = @UpdateMinMaxBetv5,
		@UpdateMinMaxBetv8 = @UpdateMinMaxBetv8,
		@UpdateMinMaxBetv10 = @UpdateMinMaxBetv10,
		@UpdateMinMaxBetv11 = @UpdateMinMaxBetv11,
		@UpdateMinMaxBetv99 = @UpdateMinMaxBetv99,
		@UpdateMinMaxBetv99MP = @UpdateMinMaxBetv99MP,
		@UpdateMinMaxBetMP = @UpdateMinMaxBetMP,				
		--Saba
		@minbetv1saba              	= @minbetv1saba,
		@maxbetv1saba              	= @maxbetv1saba,
		@maxpermatchv1saba         	= @maxpermatchv1saba ,
		@MaxPOpermatchv1saba   		= @MaxPOpermatchv1saba ,

		@minbetv2saba              	= @minbetv2saba,
		@maxbetv2saba              	= @maxbetv2saba,
		@maxpermatchv2saba         	= @maxpermatchv2saba ,
		@MaxPOpermatchv2saba   		= @MaxPOpermatchv2saba ,

		@UpdateMinMaxBetv1saba		= @UpdateMinMaxBetv1saba,
		@UpdateMinMaxBetv2saba		= @UpdateMinMaxBetv2saba,

		@UpdateMultiple = @UpdateMultiple,	
		@UpdateMultipleSuper = @UpdateMultipleSuper,

		@SubAccID = @SubAccID,
		@UserID = @UserID,
		@Language = @Language,
		@IP = @IP,
		@SystemID = @SystemID,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END
GO
