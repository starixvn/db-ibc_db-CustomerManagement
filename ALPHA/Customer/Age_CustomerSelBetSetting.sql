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
		@MinBetv161_Max money, @MaxBetv161_Min money, @MaxPerMatchv161_Min money, @MaxPerMatchv161_Max money, 
		@MaxPerBallv161_Min MONEY, @MaxPerBallv161_Max MONEY,
		@MinBetv164_Max money, @MaxBetv164_Min money, @MaxPerMatchv164_Min money, @MaxPerMatchv164_Max money, 
		@MinBetv99MP_Max money, @MaxBetv99MP_Min money, @MaxPerMatchv99MP_Min money, @MaxPerMatchv99MP_Max money,
		@MinBetv1MP_Max money, @MaxBetv1MP_Min money, @MaxPerMatchv1MP_Min money, @MaxPerMatchv1MP_Max money

--SELECT LIMIT
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
	
		@MinBetv161_Max = @MinBetv161_Max output, @MaxBetv161_Min = @MaxBetv161_Min output, @MaxPerMatchv161_Min = @MaxPerMatchv161_Min output, @MaxPerMatchv161_Max = @MaxPerMatchv161_Max output, @MaxPerBallv161_Min = @MaxPerBallv161_Min output, @MaxPerBallv161_Max = @MaxPerBallv161_Max output,
		@MinBetv164_Max = @MinBetv164_Max output, @MaxBetv164_Min = @MaxBetv164_Min output, @MaxPerMatchv164_Min = @MaxPerMatchv164_Min output, @MaxPerMatchv164_Max = @MaxPerMatchv164_Max output
		 
DECLARE @RoleId INT
SELECT @RoleId = RoleId
FROM dbo.custInfo WITH(NOLOCK)
WHERE custid = @userid

--MIN,MAX BET
SELECT 	
	isnull(Ci.maxpermatch, 0) as maxpermatch,
	isnull(ci.maxpermatch2, 0) as maxpermatchv2,
	isnull(ci.maxpermatch3, 0) as maxpermatchv3,
	isnull(ci.maxpermatch5, 0) as maxpermatchv5,
	isnull(ci.maxpermatch8, 0) as maxpermatchv8,
	isnull(ci.maxpermatch10, 0) as maxpermatchv10,
	isnull(ci.maxpermatch11, 0) as maxpermatchv11,
	isnull(ci.maxpermatch99, 0) as maxpermatchv99,
	isnull(ci.maxpermatch99MP, 0) as maxpermatchv99MP,
	isnull(ci.maxpermatch1MP, 0) as maxpermatchv1MP,	
	isnull(ci.maxpermatch161, 0) as maxpermatchv161,	
	isnull(ci.maxperball161,0) as maxperballv161,
	isnull(ci.maxpermatch164, 0) as maxpermatchv164,
	
	isnull(max(case when cs.bettype = 1 and cs.sporttype=1 then cs.minbet else 0 end), 0) as minbet,
	isnull(max(case when cs.bettype = 1 and cs.sporttype=1 then cs.maxbet else 0 end), 0) as maxbet,
	
	isnull(max(case when cs.bettype = 1 and cs.sporttype=2 then cs.minbet else 0 end), 0) as MinBetv2,
	isnull(max(case when cs.bettype = 1 and cs.sporttype=2 then cs.maxbet else 0 end), 0) as MaxBetv2,
	
	isnull(max(case when cs.bettype = 1 and cs.sporttype=3 then cs.minbet else 0 end), 0) as MinBetv3,
	isnull(max(case when cs.bettype = 1 and cs.sporttype=3 then cs.maxbet else 0 end), 0) as MaxBetv3,

	isnull(max(case when cs.bettype = 1 and cs.sporttype=5 then cs.minbet else 0 end), 0) as MinBetv5,
	isnull(max(case when cs.bettype = 1 and cs.sporttype=5 then cs.maxbet else 0 end), 0) as MaxBetv5,

	isnull(max(case when cs.bettype = 1 and cs.sporttype=8 then cs.minbet else 0 end), 0) as MinBetv8,
	isnull(max(case when cs.bettype = 1 and cs.sporttype=8 then cs.maxbet else 0 end), 0) as MaxBetv8,

	isnull(max(case when cs.bettype = 1 and cs.sporttype=10 then cs.minbet else 0 end), 0) as MinBetv10,
	isnull(max(case when cs.bettype = 1 and cs.sporttype=10 then cs.maxbet else 0 end), 0) as MaxBetv10,

	isnull(max(case when cs.bettype = 1 and cs.sporttype=11 then cs.minbet else 0 end), 0) as MinBetv11,
	isnull(max(case when cs.bettype = 1 and cs.sporttype=11 then cs.maxbet else 0 end), 0) as MaxBetv11,

	isnull(max(case when cs.bettype = 1 and cs.sporttype=99 then cs.minbet else 0 end), 0) as MinBetv99,
	isnull(max(case when cs.bettype = 1 and cs.sporttype=99 then cs.maxbet else 0 end), 0) as MaxBetv99,
	
	isnull(max(case when cs.bettype = 9 and cs.sporttype=99 then cs.minbet else 0 end), 0) as MinBetv99MP,
	isnull(max(case when cs.bettype = 9 and cs.sporttype=99 then cs.maxbet else 0 end), 0) as MaxBetv99MP,

	isnull(max(case when cs.bettype = 9 and cs.sporttype=1 then cs.minbet else 0 end), 0) as MinBetv1MP,
	isnull(max(case when cs.bettype = 9 and cs.sporttype=1 then cs.maxbet else 0 end), 0) as MaxBetv1MP,
	
	isnull(max(case when cs3.bettype = 81 and cs3.sporttype=161 then cs3.minbet else 0 end), 0) as MinBetv161,
	isnull(max(case when cs3.bettype = 81 and cs3.sporttype=161 then cs3.maxbet else 0 end), 0) as MaxBetv161,
	
	isnull(max(case when cs3.bettype = 8101 and cs3.sporttype=164 then cs3.minbet else 0 end), 0) as MinBetv164,
	isnull(max(case when cs3.bettype = 8101 and cs3.sporttype=164 then cs3.maxbet else 0 end), 0) as MaxBetv164,

	
	--Limit
	IsNull(@MinBet_Max, 0) as MinBet_Max,
	IsNull(@MaxBet_Min, 0) as MaxBet_Min,
	IsNull(@MaxPerMatch_Min, 0) as MaxPerMatch_Min,
	IsNull(@MaxPerMatch_Max, 0) as MaxPerMatch_Max,
	
	IsNull(@MinBetv2_Max, 0) as MinBetv2_Max,	
	IsNull(@MaxBetv2_Min, 0) as MaxBetv2_Min,	
	IsNull(@MaxPerMatchv2_Min, 0) as MaxPerMatchv2_Min,	
	IsNull(@MaxPerMatchv2_Max, 0) as MaxPerMatchv2_Max,	
	
	IsNull(@MinBetv3_Max, 0) as MinBetv3_Max,	
	IsNull(@MaxBetv3_Min, 0) as MaxBetv3_Min,	
	IsNull(@MaxPerMatchv3_Min, 0) as MaxPerMatchv3_Min,	
	IsNull(@MaxPerMatchv3_Max, 0) as MaxPerMatchv3_Max,

	IsNull(@MinBetv5_Max, 0) as MinBetv5_Max,	
	IsNull(@MaxBetv5_Min, 0) as MaxBetv5_Min,	
	IsNull(@MaxPerMatchv5_Min, 0) as MaxPerMatchv5_Min,	
	IsNull(@MaxPerMatchv5_Max, 0) as MaxPerMatchv5_Max,

	IsNull(@MinBetv8_Max, 0) as MinBetv8_Max,	
	IsNull(@MaxBetv8_Min, 0) as MaxBetv8_Min,	
	IsNull(@MaxPerMatchv8_Min, 0) as MaxPerMatchv8_Min,	
	IsNull(@MaxPerMatchv8_Max, 0) as MaxPerMatchv8_Max,

	IsNull(@MinBetv10_Max, 0) as MinBetv10_Max,	
	IsNull(@MaxBetv10_Min, 0) as MaxBetv10_Min,	
	IsNull(@MaxPerMatchv10_Min, 0) as MaxPerMatchv10_Min,	
	IsNull(@MaxPerMatchv10_Max, 0) as MaxPerMatchv10_Max,

	IsNull(@MinBetv11_Max, 0) as MinBetv11_Max,	
	IsNull(@MaxBetv11_Min, 0) as MaxBetv11_Min,	
	IsNull(@MaxPerMatchv11_Min, 0) as MaxPerMatchv11_Min,	
	IsNull(@MaxPerMatchv11_Max, 0) as MaxPerMatchv11_Max,

	IsNull(@MinBetv99_Max, 0) as MinBetv99_Max,	
	IsNull(@MaxBetv99_Min, 0) as MaxBetv99_Min,	
	IsNull(@MaxPerMatchv99_Min, 0) as MaxPerMatchv99_Min,	
	IsNull(@MaxPerMatchv99_Max, 0) as MaxPerMatchv99_Max,
	
	IsNull(@MinBetv99MP_Max, 0) as MinBetv99MP_Max,	
	IsNull(@MaxBetv99MP_Min, 0) as MaxBetv99MP_Min,	
	IsNull(@MaxPerMatchv99MP_Min, 0) as MaxPerMatchv99MP_Min,	
	IsNull(@MaxPerMatchv99MP_Max, 0) as MaxPerMatchv99MP_Max,
	
	IsNull(@MinBetv1MP_Max, 0) as MinBetv1MP_Max,	
	IsNull(@MaxBetv1MP_Min, 0) as MaxBetv1MP_Min,	
	IsNull(@MaxPerMatchv1MP_Min, 0) as MaxPerMatchv1MP_Min,	
	IsNull(@MaxPerMatchv1MP_Max, 0) as MaxPerMatchv1MP_Max,
	

	IsNull(@MinBetv161_Max, 0) as MinBetv161_Max,	
	IsNull(@MaxBetv161_Min, 0) as MaxBetv161_Min,	
	ISNULL(@MaxPerBallv161_Min,0) AS MaxPerBallv161_Min,
	ISNULL(@MaxPerBallv161_Max,0) AS MaxPerBallv161_Max,
	IsNull(@MaxPerMatchv161_Min, 0) as MaxPerMatchv161_Min,	
	IsNull(@MaxPerMatchv161_Max, 0) as MaxPerMatchv161_Max,
	
	IsNull(@MinBetv164_Max, 0) as MinBetv164_Max,	
	IsNull(@MaxBetv164_Min, 0) as MaxBetv164_Min,	
	IsNull(@MaxPerMatchv164_Min, 0) as MaxPerMatchv164_Min,	
	IsNull(@MaxPerMatchv164_Max, 0) as MaxPerMatchv164_Max
	
	
FROM 	
	CustInfo ci with (NOLOCK)
	INNER JOIN CustSetting cs with (NOLOCK) on ci.custid = cs.custid	
	INNER JOIN CustSetting3rd cs3 with (NOLOCK) on cs.custid = cs3.custid
WHERE cs.custid=@custid
	AND ( ci.roleid = 4 OR ci.roleid = @RoleId - 1)
group by 
	ci.maxpermatch,
	ci.maxpermatch2,
	ci.maxpermatch3,
	ci.maxpermatch5,
	ci.maxpermatch8,
	ci.maxpermatch10,
	ci.maxpermatch11,
	ci.maxpermatch99,
	ci.maxpermatch99MP,
	ci.maxpermatch1MP,
	ci.maxpermatch161,
	ci.maxperball161,
	ci.maxpermatch164
END
GO