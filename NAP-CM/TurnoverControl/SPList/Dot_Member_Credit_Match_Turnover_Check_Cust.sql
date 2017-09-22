/*<info serverAlias="DBCUST-CustDB" executers="Dot_Member,API_Vender" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_Member_Credit_Match_Turnover_Check_Cust]
	@CustID				INT,
	@MatchID			INT,
	@Recommend			INT,
	@MRecommend			INT,
	@SRecommend			INT,
	@Stake				MONEY,
	@TPositionTaking	SMALLMONEY,
	@eventdate	DATETIME 
	
AS
/*
	Created: Don
	Date: 2017-04-10
	Task: Check if House Turnover is valid to place bet
	DB: DBCUST.CustDB

	Revisions:
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
		
	Parameter's explaination:
	
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @GroupHeadlineList TABLE (CustID INT PRIMARY KEY, ID INT IDENTITY (1,1))
	DECLARE @Start INT, @Stop INT, @CustID_Headline INT, @ExtraPT DECIMAL(9,8)
	
	DECLARE @NewMatchTurnover MONEY, @MaxMatchTurnover_Setting MONEY
	DECLARE @StopFlag TINYINT
	
	SELECT @NewMatchTurnover = -1, @MaxMatchTurnover_Setting = -1
	SELECT @StopFlag = 0
	
	SET @ExtraPT = ISNULL((SELECT TOP 1 ExtraPT 
							FROM dbo.Acc_GroupExtraPTSetting s WITH(NOLOCK) 
							WHERE s.SuperId = @SRecommend 
								AND s.ProductId = 1 
								AND s.Sporttype  = 0 
								AND @EventDate BETWEEN s.FromDate AND s.ToDate)
							,0)
	
	IF (@Recommend > -1) AND EXISTS (SELECT 1 FROM dbo.TOControl_GlobalSetting WITH (NOLOCK) WHERE CustID = @Recommend AND IsGroupHeadLine = 0)
	BEGIN
		SELECT 
			@NewMatchTurnover = tos.HouseTurnover + (@Stake * (1 - @TPositionTaking- @ExtraPT)),
			@MaxMatchTurnover_Setting = tos.MaxTurnOver
		FROM dbo.TOControl_Setting tos WITH(NOLOCK)
			
		WHERE 
			tos.CustID = @Recommend AND
			tos.matchid = @MatchID

		IF (@@ROWCOUNT > 0)
			IF (@NewMatchTurnover > @MaxMatchTurnover_Setting)
				SELECT @StopFlag = 1
	END

	IF (@MRecommend > -1 AND @StopFlag = 0) AND EXISTS (SELECT 1 FROM dbo.TOControl_GlobalSetting WITH (NOLOCK) WHERE CustID = @MRecommend AND IsGroupHeadLine = 0)
	BEGIN
		SELECT 
			@NewMatchTurnover = tos.HouseTurnover + (@Stake * (1 - @TPositionTaking - @ExtraPT)),
			@MaxMatchTurnover_Setting = tos.MaxTurnOver
		FROM dbo.TOControl_Setting tos WITH(NOLOCK)
		WHERE 
			tos.custid = @MRecommend AND 
			tos.matchid = @MatchID
			
		IF (@@ROWCOUNT > 0)
			IF (@NewMatchTurnover > @MaxMatchTurnover_Setting)
				SELECT @StopFlag = 1
	END

	IF (@SRecommend >- 1 AND @StopFlag = 0) AND EXISTS (SELECT 1 FROM dbo.TOControl_GlobalSetting WITH (NOLOCK) WHERE CustID = @SRecommend AND IsGroupHeadLine = 0)
	BEGIN
		SELECT 
			@NewMatchTurnover = tos.HouseTurnover + (@Stake * (1 - @TPositionTaking - @ExtraPT)),
			@MaxMatchTurnover_Setting = tos.MaxTurnOver
		FROM dbo.TOControl_Setting tos WITH(NOLOCK)
		WHERE 
			tos.custid = @SRecommend AND
			tos.matchid = @MatchID
			
		IF (@@ROWCOUNT > 0)
			IF (@NewMatchTurnover > @MaxMatchTurnover_Setting)
				SELECT @StopFlag = 1
	END 
	
	IF @StopFlag = 0
	BEGIN
		-------------- Process for Headline --------------------------------------
		-- Get Headline that member belongs to, his headline have TO Global setting
		INSERT INTO @GroupHeadlineList (CustID)
		SELECT GS.CustID
		FROM dbo.custAccount ca WITH (NOLOCK)
			INNER JOIN dbo.CustGroupHeadline ca1 WITH (NOLOCK) ON ca1.groupID = ca.groupID
			INNER JOIN dbo.TOControl_GlobalSetting GS WITH (NOLOCK) ON CA1.CustID = GS.CustID AND GS.IsGroupHeadLine = 1
		WHERE ca.custid IN (@CustID,@SRecommend,@Recommend,@MRecommend)
		
		IF EXISTS (SELECT 1 FROM @GroupHeadlineList)
		BEGIN
			SET @Start = 1
			SET @Stop = (SELECT MAX(ID) FROM @GroupHeadlineList)
			WHILE @Start <= @Stop
			BEGIN
				SELECT @CustID_Headline = CustID FROM @GroupHeadlineList WHERE ID = @Start
				
				SELECT 
					@NewMatchTurnover = tos.HouseTurnover + (@Stake * (1 - @TPositionTaking - @ExtraPT)),
					@MaxMatchTurnover_Setting = tos.MaxTurnOver
				FROM dbo.TOControl_Setting tos WITH(NOLOCK)
				WHERE tos.custid = @CustID_Headline 
					AND	tos.matchid = @MatchID
					AND tos.IsGroupHeadLine = 1
					
				IF (@@ROWCOUNT > 0)
				BEGIN
					IF (@NewMatchTurnover > @MaxMatchTurnover_Setting)
					BEGIN
						SELECT @StopFlag = 1
						BREAK
					END
				END		
				SET @Start = @Start + 1	
			END
		END
	END	
	/*	@StopFlag = 1, invalid, so cancel the place bet 
		@StopFlag = 0, valid, so it's okay for the place bet
	*/
	SELECT @StopFlag AS StopFlag

END
GO
GRANT EXECUTE ON [dbo].[Dot_Member_Credit_Match_Turnover_Check_Cust] TO [Dot_Member]
GO
GRANT EXECUTE ON [dbo].[Dot_Member_Credit_Match_Turnover_Check_Cust] TO [API_Vender]
GO