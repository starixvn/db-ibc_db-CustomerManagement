/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_VREngine_Rule_Insert] 
	@UserID INT = NULL,
	@IP VARCHAR(20) = '',
	@Priority INT ,
	@RuleName VARCHAR(100) = '',
	@SiteType TINYINT = 0,
	@Betfrom VARCHAR(3) = '',
	@StakeRM_From MONEY = 0,
	@StakeRM_To	MONEY = 0,
	@VR_From SMALLMONEY = NULL,
	@VR_To SMALLMONEY = NULL,
	@VRStatus TINYINT = 2,
	@BeginTime VARCHAR(15) = '',
	@EndTime VARCHAR(15) = '',
	@LiveIndicator TINYINT = 2,
	@SporttypeList VARCHAR(MAX) = NULL,
	@BettypeList VARCHAR(MAX) =  NULL,
	@LeagueGroupList VARCHAR(MAX) = NULL, -- 0: 'None Group' , -1 : All Group
	@LeagueList VARCHAR(MAX) =  NULL,
	@SiteIDList VARCHAR(MAX) =  NULL,
	@CustomerClassList VARCHAR(MAX) =  NULL,
	@DateOfWeekList VARCHAR(MAX) =  NULL,
	@Criteria_NotApply VARCHAR(MAX) = NULL,
	@Enabled_Columns VARCHAR(MAX) = NULL,
	@Adjustmenttype	tinyint = NULL,
	@AdjustmentValue SMALLMONEY = NULL,
	@Status TINYINT = 0, --0 PROD, 1: UAT, 2: Inactive
	@AccumulatedBalance BIT = 0,
	@CurrencyIDList VARCHAR(MAX) = NULL,
	@CustomerClassDetailList VARCHAR(MAX) =  NULL,
	@CCSporttypeList VARCHAR(MAX) = NULL,
	@ErrorCode INT = 0 OUTPUT,
	@ErrorMsg VARCHAR(MAX) = '' OUTPUT 
AS
/*
	Created: 20210428@Eden
	Task : VR Engine - Insert Rule
	DB: DBCUST-CUSTDB
	Original:

	Revisions:  
	- 20210428@Eden: First commit [Redmine:#136423]
	- 20240319@Luke: [NAP CM] VR Engine - Add in new criteria: Apply follow the VR accumulated balance, Currency [Redmine: #201333]
	- 20240422@Winfred: [NAP CM] VR Engine - Allow to add CC by Sport, and re-arrange league group on dropdownlist [Redmine: #195539]

	Parameter explanation:
		@Criteria_NotApply = 
			'<Root>
				<Row Criteria="SporttypeList" Value="1" />	
				<Row Criteria="BettypeList" Value="" />	
				<Row Criteria="LeagueGroupList" Value="" />	
				<Row Criteria="LeagueList" Value="" />	
				<Row Criteria="SiteIDList" Value="" />	
				<Row Criteria="CustomerClassList" Value="8,9,10" />	
				<Row Criteria="DateOfWeekList" Value="" />
				<Row Criteria="CurrencyIDList" Value="" />
			</Root>'	

		@Enabled_Columns : Criteras is enabled on UI
			'Site,CustomerClass,VRValue,VRStatus,Sporttype,Bettype,LiveIndicator,LeagueGroup,BetFrom,StakeRM,DateOfWeek,TicketTime,Currency'
			
	Example: 
	DECLARE @ErrorCode INT = 0 ,@ErrorMsg VARCHAR(MAX) = '' 
	EXEC NAP_VREngine_Rule_Insert 
		@UserID = 8,
		@Priority = 1,
		@RuleName = 'EdenTesting',
		@SiteType = 2,
		@Betfrom = '',
		@StakeRM_From = 0,
		@StakeRM_To = 99,
		@VR_From = -99,
		@VR_To = 200,
		@VRStatus = 1,
		@BeginTime = '4:00:00',
		@EndTime = '06:00:00',
		@LiveIndicator = 2,
		@SporttypeList = '0',
		@BettypeList = '0',
		@LeagueGroupList = '-1',
		@LeagueList =  '-1',
		@Adjustmenttype = 1,
		@AdjustmentValue = -99,
		@Status = 0,
		@AccumulatedBalance = 0,
		@CurrencyIDList = '0',
		@CustomerClassDetailList = '',
		@CCSporttypeList = '0',
		@ErrorCode = @ErrorCode OUTPUT,
		@ErrorMsg = @ErrorMsg OUTPUT
	SELECT @ErrorCode,@ErrorMsg

	*/
BEGIN
	DECLARE @RuleID INT
	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @ActionID INT = 833
	DECLARE @SporttypeList_NotApply VARCHAR(MAX) ,
		@BettypeList_NotApply VARCHAR(MAX) ,
		@LeagueGroupList_NotApply VARCHAR(MAX) ,
		@LeagueList_NotApply VARCHAR(MAX) ,
		@SiteIDList_NotApply VARCHAR(MAX) ,
		@CustomerClassList_NotApply VARCHAR(MAX) ,
		@DateOfWeekList_NotApply VARCHAR(MAX) ,
		@CurrencyIDList_NotApply VARCHAR(MAX),
		@CCSporttypeList_NotApply VARCHAR(MAX) ,
		@CustomerClassDetailList_NotApply VARCHAR(MAX) 
	
	SET @StartRun = GETDATE()

	-- /* START - Validate input
	IF EXISTS( SELECT 1 FROM VRSettingRule WITH(NOLOCK) WHERE Priority = @Priority)
	BEGIN
		SELECT @ErrorCode = 1,
			@ErrorMsg = 'This priority already exists, please input again.'
		RETURN
	END	

	SELECT @VR_From = ISNULL(@VR_From/100 + 1,0),
		   @VR_To = ISNULL(@VR_To/100 + 1,0)

	IF @VR_From < 0 OR @VR_To > 3.00
	BEGIN
		SELECT @ErrorCode = 2,
			@ErrorMsg = 'Value must be in this range [<-99>;<200>]'
		RETURN
	END

	IF ISNULL(@BeginTime,'') = '' AND ISNULL(@EndTime,'') = ''
	BEGIN
		SELECT @BeginTime = '00:00:00', @EndTime = '00:00:00'
	END

	IF ISDATE(@BeginTime) = 0 OR ISDATE(@EndTime) = 0
	BEGIN
		SELECT @ErrorCode = 3,
			@ErrorMsg = 'Invalid time format.'
		RETURN
	END

	IF CONVERT(TIME,@BeginTime,108) > CONVERT(TIME,@EndTime,108)
	BEGIN
		SELECT @ErrorCode = 4,
			@ErrorMsg = 'To Time should be greater than or equal to From Time.'
		RETURN
	END

	--*/ END - Validate input

	SELECT 	@AdjustmentValue = CASE WHEN @Adjustmenttype = 1 THEN @AdjustmentValue/100 + 1
									WHEN @Adjustmenttype = 2 THEN @AdjustmentValue/100
								END

	CREATE TABLE #ValidData
	(
		 Sporttype     SMALLINT, 
		 Bettype       SMALLINT, 
		 LeagueGroupID INT, 
		 LeagueID      INT,
		 SiteID        INT, 
		 CustomerClass SMALLINT, 
		 DateOfWeek    TINYINT,
		 CurrencyID	   INT,
		 IsApply	   BIT
	)

	SELECT @SporttypeList = ISNULL( @SporttypeList,'0')
	SELECT @BettypeList = ISNULL( @BettypeList,'0')
	SELECT @LeagueGroupList = ISNULL( @LeagueGroupList,'-1')
	SELECT @LeagueList = ISNULL( @LeagueList,'-1')
	SELECT @SiteIDList = ISNULL( @SiteIDList,'0')
	SELECT @CustomerClassList = ISNULL( @CustomerClassList,'0')
	SELECT @DateOfWeekList = ISNULL( @DateOfWeekList,'0')
	SELECT @CurrencyIDList = ISNULL(@CurrencyIDList,'0')

	IF @Criteria_NotApply <> ''
	BEGIN
		DECLARE @DocHandler INT	
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @Criteria_NotApply

		SELECT @SporttypeList_NotApply = CASE WHEN @SporttypeList = '0' AND Criteria = 'SporttypeList' THEN Value ELSE @SporttypeList_NotApply END,
			@BettypeList_NotApply = CASE WHEN @BettypeList = '0' AND Criteria = 'BettypeList' THEN Value ELSE @BettypeList_NotApply END,
			@LeagueGroupList_NotApply = CASE WHEN @LeagueGroupList = '-1' AND Criteria = 'LeagueGroupList' THEN Value ELSE @LeagueGroupList_NotApply END,
			@LeagueList_NotApply = CASE WHEN @LeagueList = '-1' AND Criteria = 'LeagueList' THEN Value ELSE @LeagueList_NotApply END,
			@SiteIDList_NotApply = CASE WHEN @SiteIDList = '0' AND Criteria = 'SiteIDList' THEN Value ELSE @SiteIDList_NotApply END,
			@CustomerClassList_NotApply = CASE WHEN @CustomerClassList = '0' AND Criteria = 'CustomerClassList' THEN Value ELSE @CustomerClassList_NotApply END,
			@DateOfWeekList_NotApply = CASE WHEN @DateOfWeekList = '0' AND Criteria = 'DateOfWeekList' THEN Value ELSE @DateOfWeekList_NotApply END,
			@CurrencyIDList_NotApply = CASE WHEN @CurrencyIDList = '0' AND Criteria = 'CurrencyIDList' THEN Value ELSE @CurrencyIDList_NotApply END
		FROM OPENXML (@DocHandler, '/Root/Row',1) 
		WITH (
			Criteria VARCHAR(20),
			Value VARCHAR(8000)
		) AS Data
		WHERE ISNULL(Value,'') <> ''

		EXEC sp_xml_removedocument @DocHandler
	END

	EXEC NAP_VREngine_CriteriaMatrix_Check 
		 @SporttypeList = @SporttypeList, 
		 @BettypeList = @BettypeList, 
		 @LeagueGroupList = @LeagueGroupList, 
		 @LeagueList = @LeagueList, 
		 @SiteIDList = @SiteIDList, 
		 @CustomerClassList = @CustomerClassList, 
		 @DateOfWeekList = @DateOfWeekList, 
		 @SporttypeList_NotApply = @SporttypeList_NotApply, 
		 @BettypeList_NotApply = @BettypeList_NotApply, 
		 @LeagueGroupList_NotApply = @LeagueGroupList_NotApply, 
		 @LeagueList_NotApply = @LeagueList_NotApply, 
		 @SiteIDList_NotApply = @SiteIDList_NotApply, 
		 @CustomerClassList_NotApply = @CustomerClassList_NotApply, 
		 @DateOfWeekList_NotApply = @DateOfWeekList_NotApply,
		 @CurrencyIDList = @CurrencyIDList,
		 @CurrencyIDList_NotApply = @CurrencyIDList_NotApply, 
		 @ErrorCode = @ErrorCode OUTPUT, 
		 @ErrorMsg = @ErrorMsg OUTPUT

	IF NOT EXISTS (SELECT 1 FROM #ValidData)
	BEGIN
		RETURN
	END

	IF CONVERT(TIME,@EndTime) <> ''
		SELECT @EndTime = DATEADD(MILLISECOND,59999,CONVERT(TIME,@EndTime))

	INSERT INTO VRSettingRule(
		 RuleName
		,SiteType
		,Betfrom
		,StakeRM_From
		,StakeRM_To
		,VR_From
		,VR_To
		,VRStatus
		,BeginTime
		,EndTime
		,LiveIndicator
		,Adjustmenttype
		,AdjustmentValue
		,Priority
		,Status
		,CreatedDTS
		,CreatedBy
		,Enabled_Column
		,AccumulatedBalance
	)
	SELECT  @RuleName
		,@SiteType
		,@Betfrom
		,@StakeRM_From
		,@StakeRM_To
		,@VR_From
		,@VR_To
		,@VRStatus
		,@BeginTime
		,@EndTime
		,@LiveIndicator
		,@Adjustmenttype
		,@AdjustmentValue
		,@Priority
		,@Status
		,GETDATE()
		,@UserID
		,@Enabled_Columns
		,@AccumulatedBalance

	SELECT @RuleID = SCOPE_IDENTITY()

	INSERT INTO VRSettingRuleDetail(
		 RuleID
		,Sporttype
		,Bettype
		,SiteID
		,CustomerClass
		,DateOfWeek
		,LeagueGroupID
		,LeagueID
		,CurrencyID
	)
	SELECT  @RuleID
		,Sporttype
		,Bettype
		,SiteID
		,CustomerClass
		,DateOfWeek
		,LeagueGroupID
		,LeagueID
		,CurrencyID
	FROM #ValidData
	WHERE IsApply = 1

	INSERT INTO VRSettingRuleDetail_NotApply(
		 RuleID
		,Sporttype
		,Bettype
		,SiteID
		,CustomerClass
		,DateOfWeek
		,LeagueGroupID
		,LeagueID
		,CurrencyID
	)
	SELECT  @RuleID
		,Sporttype
		,Bettype
		,SiteID
		,CustomerClass
		,DateOfWeek
		,LeagueGroupID
		,LeagueID
		,CurrencyID
	FROM #ValidData
	WHERE IsApply = 0

	SET @EndRun = GETDATE()
	SET @Duration = DATEDIFF (MILLISECOND, @StartRun, @EndRun)

	DECLARE @LogData VARCHAR(MAX)
	SELECT  @LogData = '<R '
						+ 'RuleID="'+ coalesce(cast(@RuleID as varchar(200)),space(1)) + '" ' 
						+ 'RuleName="'+ coalesce(cast(@RuleName as varchar(200)),space(1)) + '" ' 
						+ 'Priority="'+ coalesce(cast(@Priority as varchar(50)),space(1)) + '" ' 
						+ 'SiteType="'+ coalesce(cast(@SiteType as varchar(50)),space(1)) + '" ' 
						+ 'Betfrom="'+ coalesce(cast(@Betfrom as varchar(50)),space(1)) + '" ' 
						+ 'StakeRM_From="'+ coalesce(cast(@StakeRM_From as varchar(50)),space(1)) + '" ' 
						+ 'StakeRM_To="'+ coalesce(cast(@StakeRM_To as varchar(50)),space(1)) + '" ' 
						+ 'VR_From="'+ coalesce(cast((@VR_From -1 ) * 100 as varchar(50)),space(1)) + '" ' 
						+ 'VR_To="'+ coalesce(cast((@VR_To -1 ) * 100 as varchar(50)),space(1)) + '" ' 
						+ 'VRStatus="'+ coalesce(cast(@VRStatus as varchar(50)),space(1)) + '" ' 
						+ 'BeginTime="'+ coalesce(cast(@BeginTime as varchar(50)),space(1)) + '" ' 
						+ 'EndTime="'+ coalesce(cast(@EndTime as varchar(50)),space(1)) + '" ' 
						+ 'LiveIndicator="'+ coalesce(cast(@LiveIndicator as varchar(50)),space(1)) + '" ' 
						+ 'Enabled_Column="'+ coalesce(cast(@Enabled_Columns as varchar(200)),space(1)) + '" ' 
						+ 'SportType="'+ coalesce(CASE WHEN ISNULL(@SportTypeList_NotApply,'') = ''  THEN 'IN (' + @SportTypeList + ')'  ELSE 'NOT IN (' + @SportTypeList_NotApply + ')'  END ,space(1)) + '" ' 
						+ 'Bettype="'+ coalesce(CASE WHEN ISNULL(@BettypeList_NotApply,'') = ''  THEN 'IN (' + @BettypeList + ')'  ELSE 'NOT IN (' + @BettypeList_NotApply + ')'  END ,space(1)) + '" ' 
						+ 'LeagueGroup="'+ coalesce(CASE WHEN ISNULL(@LeagueGroupList_NotApply,'') = ''  THEN 'IN (' + @LeagueGroupList + ')'  ELSE 'NOT IN (' + @LeagueGroupList_NotApply + ')'  END ,space(1)) + '" ' 
						+ 'League="'+ coalesce(CASE WHEN ISNULL(@LeagueList_NotApply,'') = ''  THEN 'IN (' + @LeagueList + ')'  ELSE 'NOT IN (' + @LeagueList_NotApply + ')'  END ,space(1)) + '" ' 
						+ 'SiteID="'+ coalesce(CASE WHEN ISNULL(@SiteIDList_NotApply,'') = ''  THEN 'IN (' + @SiteIDList + ')'  ELSE 'NOT IN (' + @SiteIDList_NotApply + ')'  END ,space(1)) + '" ' 
						+ 'CustomerClass="'+ coalesce(CASE WHEN ISNULL(@CustomerClassList_NotApply,'') = ''  THEN 'IN (' + @CustomerClassList + ')'  ELSE 'NOT IN (' + @CustomerClassList_NotApply + ')'  END ,space(1)) + '" ' 
						+ 'DateOfWeek="'+ coalesce(CASE WHEN ISNULL(@DateOfWeekList_NotApply,'') = ''  THEN 'IN (' + @DateOfWeekList + ')'  ELSE 'NOT IN (' + @DateOfWeekList_NotApply + ')'  END ,space(1)) + '" ' 
						+ 'CurrencyID="'+ coalesce(CASE WHEN ISNULL(@CurrencyIDList_NotApply,'') = ''  THEN 'IN (' + @CurrencyIDList + ')'  ELSE 'NOT IN (' + @CurrencyIDList_NotApply + ')'  END ,space(1)) + '" ' 						
						+ 'AdjustmentType="'+ coalesce(cast(@AdjustmentType as varchar(20)),space(1)) + '" ' 
						+ 'AdjustmentValue="'+ coalesce(cast((CASE	WHEN @Adjustmenttype = 1 THEN (@AdjustmentValue -1 ) * 100 
																	WHEN @Adjustmenttype = 2 THEN @AdjustmentValue * 100
																END)
															as varchar(10)),space(1)) + '" ' 
						+ 'AccumulatedBalance="'+ coalesce(cast(@AccumulatedBalance as varchar(2)),space(1)) + '" ' 
						+ 'Status="'+ coalesce(cast(@Status as varchar(10)),space(1)) + '" '
						+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
						+ ' />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= @UserId,
		@ActionId			= @ActionID,
		@TrackingValue		= @LogData,
		@Duration			= @Duration

	DROP TABLE #ValidData
END
GO


