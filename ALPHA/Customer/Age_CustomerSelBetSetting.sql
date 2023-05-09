/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelBetSetting]
	@custid int,
	@userid int
AS
/*
Created: 20090211@nqminh
Task : Select customer bet settings
DB: DBCUST.CustDB
Original:

Revisions:
    - 20090122@[Reviewer]: [Description of revision]    
	- 20101029@Johnson: Inlcude max per ball for number game
	- 20131021@Kathy: Add HR Fixed Odds (154) [Redmine:#6505]
	- 20161109@Helen: Separate Bet Setting for Soccer - Parlay - [Redmine:66265]
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
	- 20180404@Razor: Security in Jan 2018 - Issue #2: uper/Master can edit bet setting of its indirect donwlines [RedmineID: #91896]
	- 20181218@Johnson: add Happy 5 [Redmine: #104006]
	- 20210802@Eden: Max Payout Per Match [redmine: #158073]
	- 20210831@Eden: Break setting for Saba Soccer/Basketball [redmine: #159626]
	- 20230227@Eden: Migrate NG and Keno to DCS structure [Redmine: #179711]

Param's Explanation:
• @custid: custid that need to be viewed.   
*/
BEGIN
	SET NOCOUNT ON

	Declare @MinBet_Max money, @MaxBet_Min money, @MaxPerMatch_Min money, @MaxPerMatch_Max money,
			@MinBetv2_Max money, @MaxBetv2_Min money, @MaxPerMatchv2_Min money, @MaxPerMatchv2_Max money,
			@MinBetv3_Max money, @MaxBetv3_Min money, @MaxPerMatchv3_Min money, @MaxPerMatchv3_Max money,
			@MinBetv5_Max money, @MaxBetv5_Min money, @MaxPerMatchv5_Min money, @MaxPerMatchv5_Max money,
			@MinBetv8_Max money, @MaxBetv8_Min money, @MaxPerMatchv8_Min money, @MaxPerMatchv8_Max money,
			@MinBetv10_Max money, @MaxBetv10_Min money, @MaxPerMatchv10_Min money, @MaxPerMatchv10_Max money,
			@MinBetv11_Max money, @MaxBetv11_Min money, @MaxPerMatchv11_Min money, @MaxPerMatchv11_Max money,
			@MinBetv99_Max money, @MaxBetv99_Min money, @MaxPerMatchv99_Min money, @MaxPerMatchv99_Max money,				
			@MinBetv99MP_Max money, @MaxBetv99MP_Min money, @MaxPerMatchv99MP_Min money, @MaxPerMatchv99MP_Max money,
			@MinBetv1MP_Max money, @MaxBetv1MP_Min money, @MaxPerMatchv1MP_Min money, @MaxPerMatchv1MP_Max money,
			@MaxPayoutPerMatch_max money = 0,
			@MaxPayoutPerMatchv2_max money = 0,
			@MaxPayoutPerMatchv3_max money = 0,
			@MaxPayoutPerMatchv5_max money = 0,
			@MaxPayoutPerMatchv8_max money = 0,
			@MaxPayoutPerMatchv10_max money = 0,
			@MaxPayoutPerMatchv11_max money = 0,
			@MaxPayoutPerMatchv99_max money = 0,
			@MaxPayoutPerMatchv99mp_max money = 0,
			@MaxPayoutPerMatchv1mp_max money = 0

	DECLARE @minbet                 MONEY = 0, 
			@maxbet                 MONEY = 0, 
			@maxpermatch            MONEY = 0, 
			@minbetv2               MONEY = 0, 
			@maxbetv2               MONEY = 0, 
			@maxpermatchv2          MONEY = 0, 
			@minbetv3               MONEY = 0, 
			@maxbetv3               MONEY = 0, 
			@maxpermatchv3          MONEY = 0, 
			@minbetv5               MONEY = 0, 
			@maxbetv5               MONEY = 0, 
			@maxpermatchv5          MONEY = 0, 
			@minbetv8               MONEY = 0, 
			@maxbetv8               MONEY = 0, 
			@maxpermatchv8          MONEY = 0, 
			@minbetv10              MONEY = 0, 
			@maxbetv10              MONEY = 0, 
			@maxpermatchv10         MONEY = 0, 
			@minbetv11              MONEY = 0, 
			@maxbetv11              MONEY = 0, 
			@maxpermatchv11         MONEY = 0, 
			@minbetv99              MONEY = 0, 
			@maxbetv99              MONEY = 0, 
			@maxpermatchv99         MONEY = 0, 
			@minbetv99mp            MONEY = 0, 
			@maxbetv99mp            MONEY = 0, 
			@maxpermatchv99mp       MONEY = 0, 
			@minbetv1mp             MONEY = 0, 
			@maxbetv1mp             MONEY = 0, 
			@maxpermatchv1mp        MONEY = 0, 			
			@MaxPayoutPerMatch      MONEY = 0, 
			@MaxPayoutPerMatchv2    MONEY = 0, 
			@MaxPayoutPerMatchv3    MONEY = 0, 
			@MaxPayoutPerMatchv5    MONEY = 0, 
			@MaxPayoutPerMatchv8    MONEY = 0, 
			@MaxPayoutPerMatchv10   MONEY = 0, 
			@MaxPayoutPerMatchv11   MONEY = 0, 
			@MaxPayoutPerMatchv99   MONEY = 0, 
			@MaxPayoutPerMatchv99mp MONEY = 0, 
			@MaxPayoutPerMatchv1mp  MONEY = 0,
			--- Saba soccer
			@minbetv1saba				MONEY = 0, 
			@maxbetv1saba				MONEY = 0, 
			@maxpermatchv1saba			MONEY = 0, 
			@maxPayoutpermatchv1saba    MONEY = 0,
			--- Saba basketball
			@minbetv2saba				MONEY = 0, 
			@maxbetv2saba				MONEY = 0, 
			@maxpermatchv2saba			MONEY = 0, 
			@maxPayoutpermatchv2saba	MONEY = 0,

			--- Saba soccer
			@MinBetv1saba_Max            MONEY = 0, 
			@MaxBetv1saba_Min            MONEY = 0, 
			@MaxPerMatchv1saba_Min       MONEY = 0, 
			@MaxPerMatchv1saba_Max       MONEY = 0, 
			@MaxPayoutPerMatchv1saba_max MONEY = 0,
			--- Saba Basketball
			@MinBetv2saba_Max            MONEY = 0, 
			@MaxBetv2saba_Min            MONEY = 0, 
			@MaxPerMatchv2saba_Min       MONEY = 0, 
			@MaxPerMatchv2saba_Max       MONEY = 0, 
			@MaxPayoutPerMatchv2saba_max MONEY = 0

	DECLARE @Login_RoleId TINYINT, @RoleID TINYINT
	SELECT @Login_RoleId = RoleId FROM dbo.custInfo WITH(NOLOCK) WHERE custid = @userid
	SELECT @RoleId = RoleId FROM dbo.custInfo WITH(NOLOCK) WHERE custid = @custid

	IF @RoleId = 4 OR @Login_RoleId - 1 = @RoleId
	BEGIN
		--Get BetSetting limit
		EXEC Age_CustomerSelMinMaxLimit @custid, @userid, 
				@MinBet_Max = @MinBet_Max output, @MaxBet_Min = @MaxBet_Min output, @MaxPerMatch_Min = @MaxPerMatch_Min output, @MaxPerMatch_Max = @MaxPerMatch_Max output,
				@MinBetv2_Max = @MinBetv2_Max output, @MaxBetv2_Min = @MaxBetv2_Min output, @MaxPerMatchv2_Min = @MaxPerMatchv2_Min output, @MaxPerMatchv2_Max = @MaxPerMatchv2_Max output,
				@MinBetv3_Max = @MinBetv3_Max output, @MaxBetv3_Min = @MaxBetv3_Min output, @MaxPerMatchv3_Min = @MaxPerMatchv3_Min output, @MaxPerMatchv3_Max = @MaxPerMatchv3_Max output,
				@MinBetv5_Max = @MinBetv5_Max output, @MaxBetv5_Min = @MaxBetv5_Min output, @MaxPerMatchv5_Min = @MaxPerMatchv5_Min output, @MaxPerMatchv5_Max = @MaxPerMatchv5_Max output,
				@MinBetv8_Max = @MinBetv8_Max output, @MaxBetv8_Min = @MaxBetv8_Min output, @MaxPerMatchv8_Min = @MaxPerMatchv8_Min output, @MaxPerMatchv8_Max = @MaxPerMatchv8_Max output,
				@MinBetv10_Max = @MinBetv10_Max output, @MaxBetv10_Min = @MaxBetv10_Min output, @MaxPerMatchv10_Min = @MaxPerMatchv10_Min output, @MaxPerMatchv10_Max = @MaxPerMatchv10_Max output,
				@MinBetv11_Max = @MinBetv11_Max output, @MaxBetv11_Min = @MaxBetv11_Min output, @MaxPerMatchv11_Min = @MaxPerMatchv11_Min output, @MaxPerMatchv11_Max = @MaxPerMatchv11_Max output,
				@MinBetv99_Max = @MinBetv99_Max output, @MaxBetv99_Min = @MaxBetv99_Min output, @MaxPerMatchv99_Min = @MaxPerMatchv99_Min output, @MaxPerMatchv99_Max = @MaxPerMatchv99_Max output,		
				@MinBetv99MP_Max = @MinBetv99MP_Max output, @MaxBetv99MP_Min = @MaxBetv99MP_Min output, @MaxPerMatchv99MP_Min = @MaxPerMatchv99MP_Min output, @MaxPerMatchv99MP_Max = @MaxPerMatchv99MP_Max output,
				@MinBetv1MP_Max = @MinBetv1MP_Max output, @MaxBetv1MP_Min = @MaxBetv1MP_Min output, @MaxPerMatchv1MP_Min = @MaxPerMatchv1MP_Min output, @MaxPerMatchv1MP_Max = @MaxPerMatchv1MP_Max output,
				@MaxPayoutPerMatch_max      = @MaxPayoutPerMatch_max      OUTPUT,
				@MaxPayoutPerMatchv2_max    = @MaxPayoutPerMatchv2_max    OUTPUT,
				@MaxPayoutPerMatchv3_max    = @MaxPayoutPerMatchv3_max    OUTPUT,
				@MaxPayoutPerMatchv5_max    = @MaxPayoutPerMatchv5_max    OUTPUT,
				@MaxPayoutPerMatchv8_max    = @MaxPayoutPerMatchv8_max    OUTPUT,
				@MaxPayoutPerMatchv10_max   = @MaxPayoutPerMatchv10_max   OUTPUT,
				@MaxPayoutPerMatchv11_max   = @MaxPayoutPerMatchv11_max   OUTPUT,
				@MaxPayoutPerMatchv99_max   = @MaxPayoutPerMatchv99_max   OUTPUT,
				@MaxPayoutPerMatchv99mp_max = @MaxPayoutPerMatchv99mp_max OUTPUT,
				@MaxPayoutPerMatchv1mp_max  = @MaxPayoutPerMatchv1mp_max  OUTPUT,
				--saba
				@MinBetv1saba_Max = @MinBetv1saba_Max output, @MaxBetv1saba_Min = @MaxBetv1saba_Min output, @MaxPerMatchv1saba_Min = @MaxPerMatchv1saba_Min output, 
				@MaxPerMatchv1saba_Max = @MaxPerMatchv1saba_Max output, @MaxPayoutPerMatchv1saba_max = @MaxPayoutPerMatchv1saba_max OUTPUT,
				@MinBetv2saba_Max = @MinBetv2saba_Max output, @MaxBetv2saba_Min = @MaxBetv2saba_Min output, @MaxPerMatchv2saba_Min = @MaxPerMatchv2saba_Min output, 
				@MaxPerMatchv2saba_Max = @MaxPerMatchv2saba_Max output, @MaxPayoutPerMatchv2saba_max = @MaxPayoutPerMatchv2saba_max OUTPUT

		--> Get BetSetting
		EXEC Acc_CustomerSelMinMax
			@custid						= @custid,
			@minbet						= @minbet					OUTPUT,            
			@maxbet                		= @maxbet                	OUTPUT,
			@maxpermatch           		= @maxpermatch           	OUTPUT,
			@minbetv2              		= @minbetv2              	OUTPUT,
			@maxbetv2              		= @maxbetv2              	OUTPUT,
			@maxpermatchv2         		= @maxpermatchv2         	OUTPUT,
			@minbetv3              		= @minbetv3              	OUTPUT,
			@maxbetv3              		= @maxbetv3              	OUTPUT,
			@maxpermatchv3         		= @maxpermatchv3         	OUTPUT,
			@minbetv5              		= @minbetv5              	OUTPUT,
			@maxbetv5              		= @maxbetv5              	OUTPUT,
			@maxpermatchv5         		= @maxpermatchv5         	OUTPUT,
			@minbetv8              		= @minbetv8              	OUTPUT,
			@maxbetv8              		= @maxbetv8              	OUTPUT,
			@maxpermatchv8         		= @maxpermatchv8         	OUTPUT,
			@minbetv10             		= @minbetv10             	OUTPUT,
			@maxbetv10             		= @maxbetv10             	OUTPUT,
			@maxpermatchv10        		= @maxpermatchv10        	OUTPUT,
			@minbetv11             		= @minbetv11             	OUTPUT,
			@maxbetv11             		= @maxbetv11             	OUTPUT,
			@maxpermatchv11        		= @maxpermatchv11        	OUTPUT,
			@minbetv99             		= @minbetv99             	OUTPUT,
			@maxbetv99             		= @maxbetv99             	OUTPUT,
			@maxpermatchv99        		= @maxpermatchv99        	OUTPUT,
			@minbetv99mp           		= @minbetv99mp           	OUTPUT,
			@maxbetv99mp           		= @maxbetv99mp           	OUTPUT,
			@maxpermatchv99mp      		= @maxpermatchv99mp      	OUTPUT,
			@minbetv1mp            		= @minbetv1mp            	OUTPUT,
			@maxbetv1mp            		= @maxbetv1mp            	OUTPUT,
			@maxpermatchv1mp       		= @maxpermatchv1mp       	OUTPUT,		
			@MaxPayoutPerMatch     		= @MaxPayoutPerMatch     	OUTPUT,
			@MaxPayoutPerMatchv2   		= @MaxPayoutPerMatchv2   	OUTPUT,
			@MaxPayoutPerMatchv3   		= @MaxPayoutPerMatchv3   	OUTPUT,
			@MaxPayoutPerMatchv5   		= @MaxPayoutPerMatchv5   	OUTPUT,
			@MaxPayoutPerMatchv8   		= @MaxPayoutPerMatchv8   	OUTPUT,
			@MaxPayoutPerMatchv10  		= @MaxPayoutPerMatchv10  	OUTPUT,
			@MaxPayoutPerMatchv11  		= @MaxPayoutPerMatchv11  	OUTPUT,
			@MaxPayoutPerMatchv99  		= @MaxPayoutPerMatchv99  	OUTPUT,
			@MaxPayoutPerMatchv99mp		= @MaxPayoutPerMatchv99mp	OUTPUT,
			@MaxPayoutPerMatchv1mp 		= @MaxPayoutPerMatchv1mp 	OUTPUT,
			--Saba
			@minbetv1saba              	= @minbetv1saba             OUTPUT,
			@maxbetv1saba              	= @maxbetv1saba             OUTPUT,
			@maxpermatchv1saba         	= @maxpermatchv1saba        OUTPUT,
			@MaxPayoutPerMatchv1saba   	= @MaxPayoutPerMatchv1saba  OUTPUT,

			@minbetv2saba              	= @minbetv2saba             OUTPUT,
			@maxbetv2saba              	= @maxbetv2saba             OUTPUT,
			@maxpermatchv2saba         	= @maxpermatchv2saba        OUTPUT,
			@MaxPayoutPerMatchv2saba   	= @MaxPayoutPerMatchv2saba  OUTPUT

	END

	SELECT ISNULL(@MinBet_Max, 0) as MinBet_Max,
		ISNULL(@MaxBet_Min, 0) as MaxBet_Min,
		ISNULL(@MaxPerMatch_Min, 0) as MaxPerMatch_Min,
		ISNULL(@MaxPerMatch_Max, 0) as MaxPerMatch_Max,
	
		ISNULL(@MinBetv2_Max, 0) as MinBetv2_Max,	
		ISNULL(@MaxBetv2_Min, 0) as MaxBetv2_Min,	
		ISNULL(@MaxPerMatchv2_Min, 0) as MaxPerMatchv2_Min,	
		ISNULL(@MaxPerMatchv2_Max, 0) as MaxPerMatchv2_Max,	
	
		ISNULL(@MinBetv3_Max, 0) as MinBetv3_Max,	
		ISNULL(@MaxBetv3_Min, 0) as MaxBetv3_Min,	
		ISNULL(@MaxPerMatchv3_Min, 0) as MaxPerMatchv3_Min,	
		ISNULL(@MaxPerMatchv3_Max, 0) as MaxPerMatchv3_Max,

		ISNULL(@MinBetv5_Max, 0) as MinBetv5_Max,	
		ISNULL(@MaxBetv5_Min, 0) as MaxBetv5_Min,	
		ISNULL(@MaxPerMatchv5_Min, 0) as MaxPerMatchv5_Min,	
		ISNULL(@MaxPerMatchv5_Max, 0) as MaxPerMatchv5_Max,

		ISNULL(@MinBetv8_Max, 0) as MinBetv8_Max,	
		ISNULL(@MaxBetv8_Min, 0) as MaxBetv8_Min,	
		ISNULL(@MaxPerMatchv8_Min, 0) as MaxPerMatchv8_Min,	
		ISNULL(@MaxPerMatchv8_Max, 0) as MaxPerMatchv8_Max,

		ISNULL(@MinBetv10_Max, 0) as MinBetv10_Max,	
		ISNULL(@MaxBetv10_Min, 0) as MaxBetv10_Min,	
		ISNULL(@MaxPerMatchv10_Min, 0) as MaxPerMatchv10_Min,	
		ISNULL(@MaxPerMatchv10_Max, 0) as MaxPerMatchv10_Max,

		ISNULL(@MinBetv11_Max, 0) as MinBetv11_Max,	
		ISNULL(@MaxBetv11_Min, 0) as MaxBetv11_Min,	
		ISNULL(@MaxPerMatchv11_Min, 0) as MaxPerMatchv11_Min,	
		ISNULL(@MaxPerMatchv11_Max, 0) as MaxPerMatchv11_Max,

		ISNULL(@MinBetv99_Max, 0) as MinBetv99_Max,	
		ISNULL(@MaxBetv99_Min, 0) as MaxBetv99_Min,	
		ISNULL(@MaxPerMatchv99_Min, 0) as MaxPerMatchv99_Min,	
		ISNULL(@MaxPerMatchv99_Max, 0) as MaxPerMatchv99_Max,
	
		ISNULL(@MinBetv99MP_Max, 0) as MinBetv99MP_Max,	
		ISNULL(@MaxBetv99MP_Min, 0) as MaxBetv99MP_Min,	
		ISNULL(@MaxPerMatchv99MP_Min, 0) as MaxPerMatchv99MP_Min,	
		ISNULL(@MaxPerMatchv99MP_Max, 0) as MaxPerMatchv99MP_Max,
	
		ISNULL(@MinBetv1MP_Max, 0) as MinBetv1MP_Max,	
		ISNULL(@MaxBetv1MP_Min, 0) as MaxBetv1MP_Min,	
		ISNULL(@MaxPerMatchv1MP_Min, 0) as MaxPerMatchv1MP_Min,	
		ISNULL(@MaxPerMatchv1MP_Max, 0) as MaxPerMatchv1MP_Max,
			
		--> MaxMaxPayoutPerMatch
		@MaxPayoutPerMatch_max AS MaxPayoutPerMatch_max, 
		@MaxPayoutPerMatchv2_max AS MaxPayoutPerMatchv2_max, 
		@MaxPayoutPerMatchv3_max AS MaxPayoutPerMatchv3_max, 
		@MaxPayoutPerMatchv5_max AS MaxPayoutPerMatchv5_max, 
		@MaxPayoutPerMatchv8_max AS MaxPayoutPerMatchv8_max, 
		@MaxPayoutPerMatchv10_max AS MaxPayoutPerMatchv10_max, 
		@MaxPayoutPerMatchv11_max AS MaxPayoutPerMatchv11_max, 
		@MaxPayoutPerMatchv99_max AS MaxPayoutPerMatchv99_max, 
		@MaxPayoutPerMatchv99mp_max AS MaxPayoutPerMatchv99mp_max, 
		@MaxPayoutPerMatchv1mp_max AS MaxPayoutPerMatchv1mp_max,
		--BetSetting
		@minbet AS minbet, 
		@maxbet AS maxbet, 
		@maxpermatch AS maxpermatch, 
		@minbetv2 AS minbetv2, 
		@maxbetv2 AS maxbetv2, 
		@maxpermatchv2 AS maxpermatchv2, 
		@minbetv3 AS minbetv3, 
		@maxbetv3 AS maxbetv3, 
		@maxpermatchv3 AS maxpermatchv3, 
		@minbetv5 AS minbetv5, 
		@maxbetv5 AS maxbetv5, 
		@maxpermatchv5 AS maxpermatchv5, 
		@minbetv8 AS minbetv8, 
		@maxbetv8 AS maxbetv8, 
		@maxpermatchv8 AS maxpermatchv8, 
		@minbetv10 AS minbetv10, 
		@maxbetv10 AS maxbetv10, 
		@maxpermatchv10 AS maxpermatchv10, 
		@minbetv11 AS minbetv11, 
		@maxbetv11 AS maxbetv11, 
		@maxpermatchv11 AS maxpermatchv11, 
		@minbetv99 AS minbetv99, 
		@maxbetv99 AS maxbetv99, 
		@maxpermatchv99 AS maxpermatchv99, 
		@minbetv99mp AS minbetv99mp, 
		@maxbetv99mp AS maxbetv99mp, 
		@maxpermatchv99mp AS maxpermatchv99mp, 
		@minbetv1mp AS minbetv1mp, 
		@maxbetv1mp AS maxbetv1mp, 
		@maxpermatchv1mp AS maxpermatchv1mp, 		
		@MaxPayoutPerMatch AS MaxPayoutPerMatch, 
		@MaxPayoutPerMatchv2 AS MaxPayoutPerMatchv2, 
		@MaxPayoutPerMatchv3 AS MaxPayoutPerMatchv3, 
		@MaxPayoutPerMatchv5 AS MaxPayoutPerMatchv5, 
		@MaxPayoutPerMatchv8 AS MaxPayoutPerMatchv8, 
		@MaxPayoutPerMatchv10 AS MaxPayoutPerMatchv10, 
		@MaxPayoutPerMatchv11 AS MaxPayoutPerMatchv11, 
		@MaxPayoutPerMatchv99 AS MaxPayoutPerMatchv99, 
		@MaxPayoutPerMatchv99mp AS MaxPayoutPerMatchv99mp, 
		@MaxPayoutPerMatchv1mp AS MaxPayoutPerMatchv1mp,
		--saba
		@minbetv1saba					AS minbetv1saba,
		@maxbetv1saba					AS maxbetv1saba,
		@maxpermatchv1saba				AS maxpermatchv1saba,
		@maxPayoutpermatchv1saba		AS maxPayoutpermatchv1saba,

		@minbetv2saba					AS minbetv2saba,
		@maxbetv2saba					AS maxbetv2saba,
		@maxpermatchv2saba				AS maxpermatchv2saba,
		@maxPayoutpermatchv2saba		AS maxPayoutpermatchv2saba,
		--saba
		ISNULL(@MinBetv1saba_Max			,0)	AS MinBetv1saba_Max,
		ISNULL(@MaxBetv1saba_Min			,0)	AS MaxBetv1saba_Min,
		ISNULL(@MaxPerMatchv1saba_Min 		,0)	AS MaxPerMatchv1saba_Min ,
		ISNULL(@MaxPerMatchv1saba_Max 		,0)	AS MaxPerMatchv1saba_Max ,
		ISNULL(@MaxPayoutPerMatchv1saba_max	,0) AS MaxPayoutPerMatchv1saba_max,
		ISNULL(@MinBetv2saba_Max			,0)	AS MinBetv2saba_Max,
		ISNULL(@MaxBetv2saba_Min			,0)	AS MaxBetv2saba_Min,
		ISNULL(@MaxPerMatchv2saba_Min 		,0)	AS MaxPerMatchv2saba_Min ,
		ISNULL(@MaxPerMatchv2saba_Max 		,0)	AS MaxPerMatchv2saba_Max ,
		ISNULL(@MaxPayoutPerMatchv2saba_max	,0)	AS MaxPayoutPerMatchv2saba_max
	WHERE @RoleId = 4 OR @Login_RoleId - 1 = @RoleId

END
GO