/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView,bodbAdminNet,bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelMinMaxLimit]
	@custid int,
	@userid int = 0,
	@IsCreatedDowline BIT = 0, 
	@MinBet_Max money = 0 output, @MaxBet_Min money = 0 output, @MaxPerMatch_Min money = 0 output, @MaxPerMatch_Max money = 0 output,
	@MinBetv2_Max money = 0 output, @MaxBetv2_Min money = 0 output, @MaxPerMatchv2_Min money = 0 output, @MaxPerMatchv2_Max money = 0 output,
	@MinBetv3_Max money = 0 output, @MaxBetv3_Min money = 0 output, @MaxPerMatchv3_Min money = 0 output, @MaxPerMatchv3_Max money = 0 output,
	@MinBetv5_Max money = 0 output, @MaxBetv5_Min money = 0 output, @MaxPerMatchv5_Min money = 0 output, @MaxPerMatchv5_Max money = 0 output,
	@MinBetv8_Max money = 0 output, @MaxBetv8_Min money = 0 output, @MaxPerMatchv8_Min money = 0 output, @MaxPerMatchv8_Max money = 0 output,
	@MinBetv10_Max money = 0 output, @MaxBetv10_Min money = 0 output, @MaxPerMatchv10_Min money = 0 output, @MaxPerMatchv10_Max money = 0 output,
	@MinBetv11_Max money = 0 output, @MaxBetv11_Min money = 0 output, @MaxPerMatchv11_Min money = 0 output, @MaxPerMatchv11_Max money = 0 output,
	@MinBetv99_Max money = 0 output, @MaxBetv99_Min money = 0 output, @MaxPerMatchv99_Min money = 0 output, @MaxPerMatchv99_Max money = 0 output,	
	@MinBetv99MP_Max money = 0 output, @MaxBetv99MP_Min money = 0 output, @MaxPerMatchv99MP_Min money = 0 output, @MaxPerMatchv99MP_Max money = 0 output,
	@MinBetv1MP_Max money = 0 output, @MaxBetv1MP_Min money = 0 output, @MaxPerMatchv1MP_Min money = 0 output, @MaxPerMatchv1MP_Max money = 0 output,
	@MinBetv161_Max money = 0 output, @MaxBetv161_Min money = 0 output, @MaxPerMatchv161_Min money = 0 output, @MaxPerMatchv161_Max money = 0 output, @MaxPerBallv161_Min money = 0 output, @MaxPerBallv161_Max money = 0 output,
	@MinBetv164_Max money = 0 output, @MaxBetv164_Min money = 0 output, @MaxPerMatchv164_Min money = 0 output, @MaxPerMatchv164_Max money = 0 output,
	--Max Payout Per Match
	@MaxPayoutPerMatch_max money = 0 output,
	@MaxPayoutPerMatchv2_max money = 0 output,
	@MaxPayoutPerMatchv3_max money = 0 output,
	@MaxPayoutPerMatchv5_max money = 0 output,
	@MaxPayoutPerMatchv8_max money = 0 output,
	@MaxPayoutPerMatchv10_max money = 0 output,
	@MaxPayoutPerMatchv11_max money = 0 output,
	@MaxPayoutPerMatchv99_max money = 0 output,
	@MaxPayoutPerMatchv99mp_max money = 0 output,
	@MaxPayoutPerMatchv1mp_max money = 0 output
AS
/*
Created: 20090714@nqminh
Task : Select customer minbet_max, maxbet_min, maxpermatch_min, maxpermatch_max 
DB: DBCUST.CustDB
Original:

Revisions:
	- 20090122@[Reviewer]: [Description of revision]
	- 20100919@Terry: Add Number Game and Mixed Sport
	- 20101029@Johnson: Include max per ball for number game
	- 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
	- 20161109@Helen: Separate Bet Setting for Soccer - Parlay - [Redmine:66265]
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
	- 20181218@Johnson: Add Happy 5 [Redmine: #104006]
	- 20210802@Eden: Max Payout Per Match [redmine: #158073]
Param's Explanation:
	- @custid: custid that need to be viewed. 
	-@IsCreatedDowline = :
		0 : Upline view downline to Update
		1 : Upline Create new Downline 
						
*/

SET NOCOUNT ON
BEGIN
	DECLARE @RoleId int, @srecommend int, @mrecommend int, @recommend int 
	SELECT @RoleId = RoleId, @srecommend = srecommend ,@mrecommend = mrecommend, @recommend=recommend
	FROM CustInfo WITH(NOLOCK)
	WHERE CustId = @CustID

	SET @IsCreatedDowline = ISNULL(@IsCreatedDowline,0)

	IF @IsCreatedDowline = 0
	BEGIN
		IF @RoleId >= 4
			RETURN
		ELSE IF @RoleId = 3 -- get Super
			SELECT @mrecommend = NULL, @recommend = NULL
		ELSE IF @RoleId = 2 -- Get super and master
			SELECT @recommend = NULL
	END
	ELSE
	BEGIN
		IF @RoleID = 1 OR @RoleID > 4
			RETURN
		ELSE IF @RoleId = 4 -- get Super
			SELECT @mrecommend = NULL, @recommend = NULL
		ELSE IF @RoleId = 3 -- Get super and master
			SELECT @recommend = NULL
	END

	--MAX PER MATCH MIN
	SELECT @MaxPerMatch_Min = 0,
		@MaxPerMatchv2_Min = 0,
		@MaxPerMatchv3_Min = 0,
		@MaxPerMatchv5_Min = 0,
		@MaxPerMatchv8_Min = 0,
		@MaxPerMatchv10_Min = 0,
		@MaxPerMatchv11_Min = 0,	
		@MaxPerMatchv99_Min = 0,
		@MaxPerMatchv99MP_Min = 0,
		@MaxPerMatchv1MP_Min = 0,
		@MaxPerBallv161_Min = 0,
		@MaxPerMatchv161_Min = 0,
		@MaxPerMatchv164_Min = 0

	Select 
		@MinBet_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBet_Min = Min(case when MaxBet = 0 then NULL else MaxBet end),
		@MaxperMatch_Max = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end),
		@MaxPayoutPerMatch_max = Min(case when cs.MaxPayoutPerMatch = 0 then NULL else cs.MaxPayoutPerMatch end)
	from CustBetSetting_Agent as cs WITH (NOLOCK)
	where cs.custid IN (@recommend,@MRecommend,@srecommend)
		and cs.bettype = 1 and cs.sporttype=1

	Select 
		@MinBetv2_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv2_Min = Min(case when MaxBet = 0 then NULL else MaxBet end),
		@MaxperMatchv2_Max = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end),
		@MaxPayoutPerMatchv2_max = Min(case when cs.MaxPayoutPerMatch = 0 then NULL else cs.MaxPayoutPerMatch end)
	from CustBetSetting_Agent as cs WITH (NOLOCK)
	where cs.custid IN (@recommend,@MRecommend,@srecommend)
		and cs.bettype = 1 and cs.sporttype=2

	Select 
		@MinBetv3_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv3_Min = Min(case when MaxBet = 0 then NULL else MaxBet end),
		@MaxperMatchv3_Max = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end),
		@MaxPayoutPerMatchv3_max = Min(case when cs.MaxPayoutPerMatch = 0 then NULL else cs.MaxPayoutPerMatch end)
	from CustBetSetting_Agent as cs WITH (NOLOCK)
	where cs.custid IN (@recommend,@MRecommend,@srecommend)
		and cs.bettype = 1 and cs.sporttype=3

	Select 
		@MinBetv5_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv5_Min = Min(case when MaxBet = 0 then NULL else MaxBet end),
		@MaxperMatchv5_Max = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end),
		@MaxPayoutPerMatchv5_max = Min(case when cs.MaxPayoutPerMatch = 0 then NULL else cs.MaxPayoutPerMatch end)
	from CustBetSetting_Agent as cs WITH (NOLOCK)
	where cs.custid IN (@recommend,@MRecommend,@srecommend)
		and cs.bettype = 1 and cs.sporttype=5

	Select 
		@MinBetv8_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv8_Min = Min(case when MaxBet = 0 then NULL else MaxBet end),
		@MaxperMatchv8_Max = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end),
		@MaxPayoutPerMatchv8_max = Min(case when cs.MaxPayoutPerMatch = 0 then NULL else cs.MaxPayoutPerMatch end)
	from CustBetSetting_Agent as cs WITH (NOLOCK)
	where cs.custid IN (@recommend,@MRecommend,@srecommend)
		and cs.bettype = 1 and cs.sporttype=8

	Select 
		@MinBetv10_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv10_Min = Min(case when MaxBet = 0 then NULL else MaxBet end),
		@MaxperMatchv10_Max = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end),
		@MaxPayoutPerMatchv10_max = Min(case when cs.MaxPayoutPerMatch = 0 then NULL else cs.MaxPayoutPerMatch end)
	from CustBetSetting_Agent as cs WITH (NOLOCK)
	where cs.custid IN (@recommend,@MRecommend,@srecommend)
		and cs.bettype = 1 and cs.sporttype=10
	Select 
		@MinBetv11_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv11_Min = Min(case when MaxBet = 0 then NULL else MaxBet end),
		@MaxperMatchv11_Max = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end),
		@MaxPayoutPerMatchv11_max = Min(case when cs.MaxPayoutPerMatch = 0 then NULL else cs.MaxPayoutPerMatch end)
	from CustBetSetting_Agent as cs WITH (NOLOCK)
	where cs.custid IN (@recommend,@MRecommend,@srecommend)
		and cs.bettype = 1 and cs.sporttype=11


	Select 
		@MinBetv99_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv99_Min = Min(case when MaxBet = 0 then NULL else MaxBet end),
		@MaxperMatchv99_Max = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end),
		@MaxPayoutPerMatchv99_max = Min(case when cs.MaxPayoutPerMatch = 0 then NULL else cs.MaxPayoutPerMatch end)
	from CustBetSetting_Agent as cs WITH (NOLOCK)
	where cs.custid IN (@recommend,@MRecommend,@srecommend)
		and cs.bettype = 1 and cs.sporttype=99


	Select 
		@MinBetv99MP_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv99MP_Min = Min(case when MaxBet = 0 then NULL else MaxBet end),
		@MaxperMatchv99MP_Max = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end),
		@MaxPayoutPerMatchv99MP_max = Min(case when cs.MaxPayoutPerMatch = 0 then NULL else cs.MaxPayoutPerMatch end)
	from CustBetSetting_Agent as cs WITH (NOLOCK)
	where cs.custid IN (@recommend,@MRecommend,@srecommend)
		and cs.bettype = 9 and cs.sporttype=99


	Select 
		@MinBetv1MP_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv1MP_Min = Min(case when MaxBet = 0 then NULL else MaxBet end),
		@MaxperMatchv1MP_Max = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end),
		@MaxPayoutPerMatchv1MP_max = Min(case when cs.MaxPayoutPerMatch = 0 then NULL else cs.MaxPayoutPerMatch end)
	from CustBetSetting_Agent as cs WITH (NOLOCK)
	where cs.custid IN (@recommend,@MRecommend,@srecommend)
		and cs.bettype = 9 and cs.sporttype=1

	Select 
		@MinBetv161_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv161_Min = Min(case when MaxBet = 0 then NULL else MaxBet end),
		@MaxperMatchv161_Max = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end),
		@MaxPerBallv161_Max = Min(case when cs.MaxPerNumber = 0 then NULL else cs.MaxPerNumber end)
	from CustBetSetting_Agent as cs WITH (NOLOCK)
	where cs.custid IN (@recommend,@MRecommend,@srecommend)
		and cs.bettype = 81 and cs.sporttype=161

	Select 
		@MinBetv164_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv164_Min = Min(case when MaxBet = 0 then NULL else MaxBet end),
		@MaxperMatchv164_Max = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end)
	from CustBetSetting_Agent as cs WITH (NOLOCK)
	where cs.custid IN (@recommend,@MRecommend,@srecommend)
		and cs.bettype = 8101 and cs.sporttype=164
END
GO