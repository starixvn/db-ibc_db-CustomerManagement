/*<info serverAlias="DBCUST-CustDB" executers="Dot_Member,API_Vender" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Dot_Member_Credit_Match_Turnover_Check_Cust]
	@CustID				INT,
	@MatchID			INT,
	@Recommend			INT,
	@MRecommend			INT,
	@SRecommend			INT
AS
/*
	Created: Don
	Date: 2017-04-10
	Task: Check if House Turnover is valid to place bet
	DB: DBCUST.CustDB

	Revisions:

	Parameter's explaination:
	
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @MatchTurnover MONEY, @MaxMatchTurnover_Setting MONEY
	DECLARE @StopFlag TINYINT
	
	SELECT @MatchTurnover = -1, @MaxMatchTurnover_Setting = -1
	SELECT @StopFlag = 0
	
	IF (@Recommend > -1)
	BEGIN
		SELECT 
			@MatchTurnover = tos.HouseTurnover,
			@MaxMatchTurnover_Setting = tos.MaxTurnOver
		FROM dbo.TOControl_Setting tos WITH(NOLOCK)
		WHERE 
			tos.CustID = @Recommend AND
			tos.matchid = @MatchID

		IF (@@ROWCOUNT > 0)
			IF (1 =		CASE 
							WHEN @MaxMatchTurnover_Setting = 0 THEN 1 
							WHEN @MatchTurnover/@MaxMatchTurnover_Setting >= 1 THEN 1 
							ELSE 0 
						END)
				SELECT @StopFlag = 1
	END

	IF (@MRecommend > -1 AND @StopFlag = 0)
	BEGIN
		SELECT 
			@MatchTurnover = tos.HouseTurnover,
			@MaxMatchTurnover_Setting = tos.MaxTurnOver
		FROM dbo.TOControl_Setting tos WITH(NOLOCK)
		WHERE 
			tos.custid = @MRecommend AND 
			tos.matchid = @MatchID
			
		IF (@@ROWCOUNT > 0)
			IF (1 =		CASE 
							WHEN @MaxMatchTurnover_Setting = 0 THEN 1 
							WHEN @MatchTurnover/@MaxMatchTurnover_Setting >= 1 THEN 1 
							ELSE 0 
						END)
				SELECT @StopFlag = 1
	END

	IF (@SRecommend >- 1 AND @StopFlag = 0)
	BEGIN
		SELECT 
			@MatchTurnover = tos.HouseTurnover,
			@MaxMatchTurnover_Setting = tos.MaxTurnOver
		FROM dbo.TOControl_Setting tos WITH(NOLOCK)
		WHERE 
			tos.custid = @SRecommend AND
			tos.matchid = @MatchID
			
		IF (@@ROWCOUNT > 0)
			IF (1 =		CASE 
							WHEN @MaxMatchTurnover_Setting = 0 THEN 1 
							WHEN @MatchTurnover/@MaxMatchTurnover_Setting >= 1 THEN 1 
							ELSE 0 
						END)
				SELECT @StopFlag = 1
	END 
	
	/*	@StopFlag = 1, invalid, so cancel the place bet 
		@StopFlag = 0, valid, so it's okay for the place bet
	*/
	SELECT @StopFlag AS StopFlag

END
GO