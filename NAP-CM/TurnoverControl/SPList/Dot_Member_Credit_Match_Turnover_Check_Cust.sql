/*<info serverAlias="DBCUST-CustDB" executers="Dot_Member,API_Vender" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_Member_Credit_Match_Turnover_Check_Cust]
	@CustID				INT,
	@MatchID			INT,
	@Recommend			INT,
	@MRecommend			INT,
	@SRecommend			INT,
	@Stake				MONEY,
	@TPositionTaking	SMALLMONEY,
	@eventdate			DATETIME,
	@actualrate			FLOAT
	
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
	
	DECLARE @NewMatchTurnover MONEY, @MaxMatchTurnover_Setting MONEY, @adjHouseTurnover MONEY
	DECLARE @StopFlag TINYINT
	
	SELECT @NewMatchTurnover = -1, @MaxMatchTurnover_Setting = -1
	SELECT @StopFlag = 0
	
	-- Get Extra PT Info: 
			-- Sportbook: Categorized by SubProduct =  '' , 'MG-SuperLive', 'MuayThai'. They are the same value. 
			-- So, only based on  conditions: Productid = 1, Sporttype = 0,SubProduct= '' 
			
	SET @ExtraPT = ISNULL((SELECT SUM(ExtraPT) 
							FROM dbo.Acc_GroupExtraPTSetting s WITH(NOLOCK) 
							WHERE s.SuperId = @SRecommend 
								AND s.ProductId = 1 
								AND s.Sporttype  = 0 
								AND s.SubProduct = ''
								AND @EventDate BETWEEN s.FromDate AND s.ToDate)
							,0)
	
	SET @adjHouseTurnover = (@Stake * (1 - @TPositionTaking- @ExtraPT))
	
	IF (@Recommend > -1) AND EXISTS (SELECT 1 FROM dbo.TOControl_GlobalSetting WITH (NOLOCK) WHERE CustID = @Recommend AND IsGroupHeadLine = 0)
	BEGIN
		SELECT 
			@NewMatchTurnover = tos.HouseTurnover + @adjHouseTurnover,
			@MaxMatchTurnover_Setting = tos.MaxTurnOver
		FROM dbo.TOControl_Setting tos WITH(NOLOCK)
			
		WHERE tos.CustID = @Recommend 
			AND	tos.matchid = @MatchID
			AND tos.IsGroupHeadLine = 0

		IF (@@ROWCOUNT > 0)
			IF (@NewMatchTurnover > @MaxMatchTurnover_Setting)
				SELECT @StopFlag = 1
	END

	IF (@MRecommend > -1 AND @StopFlag = 0) AND EXISTS (SELECT 1 FROM dbo.TOControl_GlobalSetting WITH (NOLOCK) WHERE CustID = @MRecommend AND IsGroupHeadLine = 0)
	BEGIN
		SELECT 
			@NewMatchTurnover = tos.HouseTurnover + @adjHouseTurnover,
			@MaxMatchTurnover_Setting = tos.MaxTurnOver
		FROM dbo.TOControl_Setting tos WITH(NOLOCK)
		WHERE tos.custid = @MRecommend 
			AND tos.matchid = @MatchID
			AND tos.IsGroupHeadLine = 0
			
		IF (@@ROWCOUNT > 0)
			IF (@NewMatchTurnover > @MaxMatchTurnover_Setting)
				SELECT @StopFlag = 1
	END

	IF (@SRecommend >- 1 AND @StopFlag = 0) AND EXISTS (SELECT 1 FROM dbo.TOControl_GlobalSetting WITH (NOLOCK) WHERE CustID = @SRecommend AND IsGroupHeadLine = 0)
	BEGIN
		SELECT 
			@NewMatchTurnover = tos.HouseTurnover + @adjHouseTurnover,
			@MaxMatchTurnover_Setting = tos.MaxTurnOver
		FROM dbo.TOControl_Setting tos WITH(NOLOCK)
		WHERE 
			tos.custid = @SRecommend 
			AND tos.matchid = @MatchID
			AND tos.IsGroupHeadLine = 0
			
		IF (@@ROWCOUNT > 0)
			IF (@NewMatchTurnover > @MaxMatchTurnover_Setting)
				SELECT @StopFlag = 1
	END 
	
	IF @StopFlag = 0
	BEGIN
		-------------- Process for Headline --------------------------------------
		-- Get Headline that member belongs to, his headline have TO Global setting
		
		INSERT INTO @GroupHeadlineList (CustID)
		SELECT DISTINCT GS.CustID
		FROM dbo.custAccount ca WITH (NOLOCK)
			INNER JOIN dbo.CustGroupHeadline ca1 WITH (NOLOCK) ON ca1.groupID = ca.groupID
			INNER JOIN dbo.TOControl_GlobalSetting GS WITH (NOLOCK) ON CA1.CustID = GS.CustID AND GS.IsGroupHeadLine = 1
		WHERE ca.custid IN (@CustID,@SRecommend,@Recommend,@MRecommend)
		
		IF EXISTS (SELECT 1 FROM @GroupHeadlineList)
		BEGIN
			SET @adjHouseTurnover = (@Stake * @actualrate * (1 - @TPositionTaking- @ExtraPT))
			
			IF EXISTS (SELECT TOP 1 1
						FROM @GroupHeadlineList GHL
							CROSS APPLY (SELECT HouseTurnover,MaxTurnOver
										 FROM TOControl_Setting tos WITH(NOLOCK)
										 WHERE tos.custid = GHL.CustID 
												AND	tos.matchid = @MatchID
												AND tos.IsGroupHeadLine = 1
												AND tos.HouseTurnover + @adjHouseTurnover > tos.MaxTurnOver
										) AS TO_tmp		
						)				
			BEGIN
				SELECT @StopFlag = 1
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