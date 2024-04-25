/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_VREngine_Rule_Update] 
	@UserID INT = NULL,
	@IP VARCHAR(20) = '',
	@RuleID INT,
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
	Task : VR Engine - Update Rule
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
	EXEC NAP_VREngine_Rule_Update 
		@UserID = 8,
		@RuleID = 12,
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
		@AdjustmentValue = 0.01,
		@Status = 0,
		@AccumulatedBalance = 0,
		@CurrencyIDList = '0',
		@CustomerClassList ='',
		@CustomerClassDetailList ='',
		@CCSporttypeList = '0',
		@ErrorCode = @ErrorCode OUTPUT,
		@ErrorMsg = @ErrorMsg OUTPUT
	SELECT @ErrorCode,@ErrorMsg

	*/
BEGIN
	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @ActionID INT = 834
	DECLARE @SporttypeList_NotApply VARCHAR(MAX),
		@BettypeList_NotApply VARCHAR(MAX),
		@LeagueGroupList_NotApply VARCHAR(MAX),
		@LeagueList_NotApply VARCHAR(MAX),
		@SiteIDList_NotApply VARCHAR(MAX),
		@CustomerClassList_NotApply VARCHAR(MAX),
		@DateOfWeekList_NotApply VARCHAR(MAX),
		@CurrencyIDList_NotApply VARCHAR(MAX),
		@CustomerClassDetailList_NotApply VARCHAR(MAX),
		@CCSporttypeList_NotApply VARCHAR(MAX)

	DECLARE @Priority_Old INT ,
		@RuleName_Old VARCHAR(100) = '',
		@SiteType_Old TINYINT = 0,
		@Betfrom_Old VARCHAR(3) = '',
		@StakeRM_From_Old MONEY = 0,
		@StakeRM_To_Old	MONEY = 0,
		@VR_From_Old SMALLMONEY ,
		@VR_To_Old SMALLMONEY ,
		@VRStatus_Old TINYINT = 2,
		@BeginTime_Old VARCHAR(15) = '',
		@EndTime_Old VARCHAR(15) = '',
		@LiveIndicator_Old TINYINT = 2,
		@SporttypeList_Old VARCHAR(MAX) ,
		@BettypeList_Old VARCHAR(MAX) ,
		@LeagueGroupList_Old VARCHAR(MAX) ,
		@LeagueList_Old VARCHAR(MAX) ,
		@SiteIDList_Old VARCHAR(MAX) ,
		@CustomerClassList_Old VARCHAR(MAX) ,
		@DateOfWeekList_Old VARCHAR(MAX) ,
		@Criteria_NotApply_Old VARCHAR(MAX) ,
		@Enabled_Columns_Old VARCHAR(MAX) ,
		@Adjustmenttype_Old	tinyint ,
		@AdjustmentValue_Old SMALLMONEY ,
		@Status_Old TINYINT,
		@SporttypeList_NotApply_Old VARCHAR(MAX),
		@BettypeList_NotApply_Old VARCHAR(MAX),
		@LeagueGroupList_NotApply_Old VARCHAR(MAX),
		@LeagueList_NotApply_Old VARCHAR(MAX),
		@SiteIDList_NotApply_Old VARCHAR(MAX),
		@CustomerClassList_NotApply_Old VARCHAR(MAX),
		@DateOfWeekList_NotApply_Old VARCHAR(MAX),
		@AccumulatedBalance_Old BIT,
		@CurrencyIDList_Old VARCHAR(MAX),
		@CurrencyIDList_NotApply_Old VARCHAR(MAX),
		@CustomerClassDetailList_Old VARCHAR(MAX),
		@CustomerClassDetailList_NotApply_Old VARCHAR(MAX),
		@CCSporttypeList_Old VARCHAR(MAX),
		@CCSporttypeList_NotApply_Old VARCHAR(MAX)


	SET @StartRun = GETDATE()

	-- /* START - Validate input
	IF NOT EXISTS( SELECT 1 FROM VRSettingRule WITH(NOLOCK) WHERE RuleID = @RuleID)
	BEGIN
		SELECT @ErrorCode = 10,
			@ErrorMsg = 'The rule does not exist.'
		RETURN
	END	

	IF EXISTS( SELECT 1 FROM VRSettingRule WITH(NOLOCK) WHERE Priority = @Priority AND RuleID <> @RuleID)
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

	SELECT	 @RuleName_Old			= RuleName
		,@SiteType_Old			= SiteType
		,@Betfrom_Old			= Betfrom
		,@StakeRM_From_Old		= StakeRM_From
		,@StakeRM_To_Old		= StakeRM_To
		,@VR_From_Old 			= VR_From 
		,@VR_To_Old				= VR_To
		,@VRStatus_Old			= VRStatus
		,@BeginTime_Old			= BeginTime
		,@EndTime_Old			= EndTime
		,@LiveIndicator_Old		= LiveIndicator
		,@Adjustmenttype_Old	= Adjustmenttype
		,@AdjustmentValue_Old	= AdjustmentValue
		,@Priority_Old			= Priority
		,@Status_Old			= Status
		,@Enabled_Columns_Old	= Enabled_Column
		,@SportTypeList_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.Sporttype)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY Sporttype
									ORDER BY Sporttype
									FOR XML PATH ('')
									),1,1,'')
		,@BettypeList_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.Bettype)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY Bettype
									ORDER BY Bettype
									FOR XML PATH ('')
									),1,1,'')
		,@LeagueGroupList_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.LeagueGroupID)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY LeagueGroupID
									ORDER BY LeagueGroupID
									FOR XML PATH ('')
									),1,1,'')
		,@LeagueList_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.Leagueid)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY Leagueid
									ORDER BY Leagueid
									FOR XML PATH ('')
									),1,1,'')

		,@SiteIDList_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.SiteID)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY SiteID
									ORDER BY SiteID
									FOR XML PATH ('')
									),1,1,'')
		,@CustomerClassList_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CustomerClass)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY CustomerClass
									ORDER BY CustomerClass
									FOR XML PATH ('')
									),1,1,'')
		,@DateOfWeekList_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.DateOfWeek)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY DateOfWeek
									ORDER BY DateOfWeek
									FOR XML PATH ('')
									),1,1,'')

		,@SportTypeList_NotApply_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.Sporttype)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND Sporttype <> 0
									GROUP BY Sporttype
									ORDER BY Sporttype
									FOR XML PATH ('')
									),1,1,'')
		,@BettypeList_NotApply_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.Bettype)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND Bettype <> 0
									GROUP BY Bettype
									ORDER BY Bettype
									FOR XML PATH ('')
									),1,1,'')
		,@LeagueGroupList_NotApply_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.LeagueGroupID)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND LeagueGroupID <> -1
									GROUP BY LeagueGroupID
									ORDER BY LeagueGroupID
									FOR XML PATH ('')
									),1,1,'')
		,@LeagueList_NotApply_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.Leagueid)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND Leagueid <> -1
									GROUP BY Leagueid
									ORDER BY Leagueid
									FOR XML PATH ('')
									),1,1,'')

		,@SiteIDList_NotApply_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.SiteID)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND SiteID <> 0
									GROUP BY SiteID
									ORDER BY SiteID
									FOR XML PATH ('')
									),1,1,'')
		,@CustomerClassList_NotApply_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CustomerClass)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND CustomerClass <> 0
									GROUP BY CustomerClass
									ORDER BY CustomerClass
									FOR XML PATH ('')
									),1,1,'')
		,@DateOfWeekList_NotApply_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.DateOfWeek)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND DateOfWeek <> 0
									GROUP BY DateOfWeek
									ORDER BY DateOfWeek
									FOR XML PATH ('')
									),1,1,'')
		,@CurrencyIDList_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CurrencyID)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY CurrencyID
									ORDER BY CurrencyID
									FOR XML PATH ('')
									),1,1,'')
		,@CurrencyIDList_NotApply_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CurrencyID)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND CurrencyID <> 0
									GROUP BY CurrencyID
									ORDER BY CurrencyID
									FOR XML PATH ('')
									),1,1,'')
		,@CustomerClassDetailList_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CustomerClassDetail)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY CustomerClassDetail
									ORDER BY CustomerClassDetail
									FOR XML PATH ('')
									),1,1,'')
		,@CustomerClassDetailList_NotApply_Old = STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CustomerClassDetail)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND CustomerClassDetail <> 0
									GROUP BY CustomerClassDetail
									ORDER BY CustomerClassDetail
									FOR XML PATH ('')
									),1,1,'')
		,@CCSportTypeList_Old =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CCSporttype)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY CCSporttype
									ORDER BY CCSporttype
									FOR XML PATH ('')
									),1,1,'')
		,@CCSportTypeList_NotApply_Old = STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CCSporttype)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND CCSporttype <> 0
									GROUP BY CCSporttype
									ORDER BY CCSporttype
									FOR XML PATH ('')
									),1,1,'')
		,@AccumulatedBalance_Old = AccumulatedBalance
	FROM VRSettingRule r WITH(NOLOCK)
	WHERE RuleID = @RuleID

	CREATE TABLE #ValidData
	(
		 Sporttype		     SMALLINT, 
		 Bettype		     SMALLINT, 
		 LeagueGroupID	     INT, 
		 LeagueID		     INT,
		 SiteID			     INT, 
		 CustomerClass	     SMALLINT, 
		 DateOfWeek		     TINYINT,
		 CurrencyID		     INT,
		 IsApply		     BIT,
		 CustomerClassDetail SMALLINT, 
		 CCSporttype		 SMALLINT
	)

	SELECT @SporttypeList = ISNULL( @SporttypeList,'0')
	SELECT @BettypeList = ISNULL( @BettypeList,'0')
	SELECT @LeagueGroupList = ISNULL( @LeagueGroupList,'-1')
	SELECT @LeagueList = ISNULL( @LeagueList,'-1')
	SELECT @SiteIDList = ISNULL( @SiteIDList,'0')
	SELECT @CustomerClassList = ISNULL( @CustomerClassList,'0')
	SELECT @DateOfWeekList = ISNULL( @DateOfWeekList,'0')
	SELECT @CurrencyIDList = ISNULL(@CurrencyIDList,'0')
	SELECT @CustomerClassDetailList = ISNULL( @CustomerClassDetailList,'0')
	SELECT @CCSporttypeList = ISNULL(@CCSporttypeList,'0')

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
			@CurrencyIDList_NotApply = CASE WHEN @CurrencyIDList = '0' AND Criteria = 'CurrencyIDList' THEN Value ELSE @CurrencyIDList_NotApply END,
			@CustomerClassDetailList_NotApply = CASE WHEN @CustomerClassDetailList = '0' AND Criteria = 'CustomerClassDetailList' THEN Value ELSE @CustomerClassDetailList_NotApply END,
			@CCSporttypeList_NotApply = CASE WHEN @CCSporttypeList = '0' AND Criteria = 'CCSporttypeList' THEN Value ELSE @CCSporttypeList_NotApply END
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
		 @CCSporttypeList = @CCSporttypeList, 
		 @CCSporttypeList_NotApply = @CCSporttypeList_NotApply, 
		 @CustomerClassDetailList = @CustomerClassDetailList, 
		 @CustomerClassDetailList_NotApply = @CustomerClassDetailList_NotApply, 
		 @ErrorCode = @ErrorCode OUTPUT, 
		 @ErrorMsg = @ErrorMsg OUTPUT

	IF NOT EXISTS (SELECT 1 FROM #ValidData)
	BEGIN
		RETURN
	END
	
	IF CONVERT(TIME,@EndTime) <> ''
		SELECT @EndTime = DATEADD(MILLISECOND,59999,CONVERT(TIME,@EndTime))

	UPDATE VRSettingRule WITH(ROWLOCK,UPDLOCK)
	SET
		 RuleName			= @RuleName
		,SiteType			= @SiteType
		,Betfrom			= @Betfrom
		,StakeRM_From		= @StakeRM_From
		,StakeRM_To			= @StakeRM_To
		,VR_From			= @VR_From
		,VR_To				= @VR_To
		,VRStatus			= @VRStatus
		,BeginTime			= @BeginTime
		,EndTime			= @EndTime
		,LiveIndicator		= @LiveIndicator
		,Adjustmenttype		= @Adjustmenttype
		,AdjustmentValue	= @AdjustmentValue
		,Priority			= @Priority
		,Status				= @Status
		,Enabled_Column		= @Enabled_Columns
		,AccumulatedBalance = @AccumulatedBalance
	WHERE RuleID = @RuleID

	--> Refresh VRSettingRuleDetail
	MERGE VRSettingRuleDetail rd
	USING (SELECT * FROM #ValidData WHERE IsApply = 1)  t
		ON  rd.Sporttype = t.Sporttype
		AND rd.Bettype = t.Bettype 
		AND rd.SiteID = t.SiteID
		AND rd.CustomerClass = t.CustomerClass
		AND rd.DateOfWeek = t.DateOfWeek
		AND rd.LeagueGroupID = t.LeagueGroupID
		AND rd.LeagueID = t.LeagueID
		AND rd.ruleID = @RuleID
		AND rd.CurrencyID = t.CurrencyID
		AND rd.CustomerClassDetail = t.CustomerClassDetail
		AND rd.CCSporttype = t.CCSporttype
	WHEN NOT MATCHED THEN INSERT (RuleID,Sporttype,Bettype,SiteID,CustomerClass,DateOfWeek,LeagueGroupID,LeagueID,CurrencyID,CustomerClassDetail,CCSporttype)
						VALUES( @RuleID,t.Sporttype,t.Bettype,t.SiteID,t.CustomerClass,t.DateOfWeek,t.LeagueGroupID,t.LeagueID,t.CurrencyID,t.CustomerClassDetail,t.CCSporttype)
	WHEN NOT MATCHED BY SOURCE AND rd.RuleID = @RuleID
		THEN DELETE; 
	
	--> Refresh VRSettingRuleDetail_NotApply
	MERGE VRSettingRuleDetail_NotApply rd
	USING (SELECT * FROM #ValidData WHERE IsApply = 0)  t
		ON  rd.Sporttype = t.Sporttype
		AND rd.Bettype = t.Bettype 
		AND rd.SiteID = t.SiteID
		AND rd.CustomerClass = t.CustomerClass
		AND rd.DateOfWeek = t.DateOfWeek
		AND rd.LeagueGroupID = t.LeagueGroupID
		AND rd.LeagueID = t.LeagueID
		AND rd.ruleID = @RuleID
		AND rd.CurrencyID = t.CurrencyID
		AND rd.CustomerClassDetail = t.CustomerClassDetail
		AND rd.CCSporttype = t.CCSporttype
	WHEN NOT MATCHED THEN INSERT (RuleID,Sporttype,Bettype,SiteID,CustomerClass,DateOfWeek,LeagueGroupID,LeagueID,CurrencyID,CustomerClassDetail,CCSporttype)
						VALUES( @RuleID,t.Sporttype,t.Bettype,t.SiteID,t.CustomerClass,t.DateOfWeek,t.LeagueGroupID,t.LeagueID,t.CurrencyID,t.CustomerClassDetail,t.CCSporttype)
	WHEN NOT MATCHED BY SOURCE AND rd.RuleID = @RuleID
		THEN DELETE; 


	SET @EndRun = GETDATE()
	SET @Duration = DATEDIFF (MILLISECOND, @StartRun, @EndRun)

	DECLARE @LogData VARCHAR(MAX), @LogData_Old VARCHAR(MAX)

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
						+ 'CCSportType="'+ coalesce(CASE WHEN ISNULL(@CCSportTypeList_NotApply,'') = ''  THEN 'IN (' + @CCSportTypeList + ')'  ELSE 'NOT IN (' + @CCSportTypeList_NotApply + ')'  END ,space(1)) + '" ' 
						+ 'CustomerClassDetail="'+ coalesce(CASE WHEN ISNULL(@CustomerClassDetailList_NotApply,'') = ''  THEN 'IN (' + @CustomerClassDetailList + ')'  ELSE 'NOT IN (' + @CustomerClassDetailList_NotApply + ')'  END ,space(1)) + '" ' 
						+ 'Status="'+ coalesce(cast(@Status as varchar(10)),space(1)) + '" '
						+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
						+ ' />',
			@LogData_Old = '<R '
						+ 'RuleID="'+ coalesce(cast(@RuleID as varchar(200)),space(1)) + '" ' 
						+ 'RuleName="'+ coalesce(cast(@RuleName_Old as varchar(200)),space(1)) + '" ' 
						+ 'Priority="'+ coalesce(cast(@Priority_Old as varchar(50)),space(1)) + '" ' 
						+ 'SiteType="'+ coalesce(cast(@SiteType_Old as varchar(50)),space(1)) + '" ' 
						+ 'Betfrom="'+ coalesce(cast(@Betfrom_Old as varchar(50)),space(1)) + '" ' 
						+ 'StakeRM_From="'+ coalesce(cast(@StakeRM_From_Old as varchar(50)),space(1)) + '" ' 
						+ 'StakeRM_To="'+ coalesce(cast(@StakeRM_To_Old as varchar(50)),space(1)) + '" ' 
						+ 'VR_From="'+ coalesce(cast((@VR_From_Old -1 ) * 100 as varchar(50)),space(1)) + '" ' 
						+ 'VR_To="'+ coalesce(cast((@VR_To_Old -1 ) * 100 as varchar(50)),space(1)) + '" ' 
						+ 'VRStatus="'+ coalesce(cast(@VRStatus_Old as varchar(50)),space(1)) + '" ' 
						+ 'BeginTime="'+ coalesce(cast(@BeginTime_Old as varchar(50)),space(1)) + '" ' 
						+ 'EndTime="'+ coalesce(cast(@EndTime_Old as varchar(50)),space(1)) + '" ' 
						+ 'LiveIndicator="'+ coalesce(cast(@LiveIndicator_Old as varchar(50)),space(1)) + '" ' 
						+ 'Enabled_Column="'+ coalesce(cast(@Enabled_Columns_Old as varchar(200)),space(1)) + '" ' 
						+ 'SportType="'+ coalesce(CASE WHEN ISNULL(@SportTypeList_NotApply_Old,'') = ''  THEN 'IN (' + @SportTypeList_Old + ')'  ELSE 'NOT IN (' + @SportTypeList_NotApply_Old + ')'  END ,space(1)) + '" ' 
						+ 'Bettype="'+ coalesce(CASE WHEN ISNULL(@BettypeList_NotApply_Old,'') = ''  THEN 'IN (' + @BettypeList_Old + ')'  ELSE 'NOT IN (' + @BettypeList_NotApply_Old + ')'  END ,space(1)) + '" ' 
						+ 'LeagueGroup="'+ coalesce(CASE WHEN ISNULL(@LeagueGroupList_NotApply_Old,'') = ''  THEN 'IN (' + @LeagueGroupList_Old + ')'  ELSE 'NOT IN (' + @LeagueGroupList_NotApply_Old + ')'  END ,space(1)) + '" ' 
						+ 'League="'+ coalesce(CASE WHEN ISNULL(@LeagueList_NotApply_Old,'') = ''  THEN 'IN (' + @LeagueList_Old + ')'  ELSE 'NOT IN (' + @LeagueList_NotApply_Old + ')'  END ,space(1)) + '" ' 
						+ 'SiteID="'+ coalesce(CASE WHEN ISNULL(@SiteIDList_NotApply_Old,'') = ''  THEN 'IN (' + @SiteIDList_Old + ')'  ELSE 'NOT IN (' + @SiteIDList_NotApply_Old + ')'  END ,space(1)) + '" ' 
						+ 'CustomerClass="'+ coalesce(CASE WHEN ISNULL(@CustomerClassList_NotApply_Old,'') = ''  THEN 'IN (' + @CustomerClassList_Old + ')'  ELSE 'NOT IN (' + @CustomerClassList_NotApply_Old + ')'  END ,space(1)) + '" ' 
						+ 'DateOfWeek="'+ coalesce(CASE WHEN ISNULL(@DateOfWeekList_NotApply_Old,'') = ''  THEN 'IN (' + @DateOfWeekList_Old + ')'  ELSE 'NOT IN (' + @DateOfWeekList_NotApply_Old + ')'  END ,space(1)) + '" ' 
						+ 'CurrencyID="'+ coalesce(CASE WHEN ISNULL(@CurrencyIDList_NotApply_Old,'') = ''  THEN 'IN (' + @CurrencyIDList_Old + ')'  ELSE 'NOT IN (' + @CurrencyIDList_NotApply_Old + ')'  END ,space(1)) + '" ' 
						+ 'AdjustmentType="'+ coalesce(cast(@AdjustmentType_Old as varchar(20)),space(1)) + '" ' 
						+ 'AdjustmentValue="'+ coalesce(cast((CASE	WHEN @AdjustmentType_Old = 1 THEN (@AdjustmentValue_Old -1 ) * 100 
																	WHEN @AdjustmentType_Old = 2 THEN @AdjustmentValue_Old * 100
																END)
															as varchar(10)),space(1)) + '" '
						+ 'AccumulatedBalance="'+ coalesce(cast(@AccumulatedBalance_Old as varchar(2)),space(1)) + '" '
						+ 'CCSportType="'+ coalesce(CASE WHEN ISNULL(@CCSportTypeList_NotApply_Old,'') = ''  THEN 'IN (' + @CCSportTypeList_Old + ')'  ELSE 'NOT IN (' + @CCSportTypeList_NotApply_Old + ')'  END ,space(1)) + '" ' 
						+ 'CustomerClassDetail="'+ coalesce(CASE WHEN ISNULL(@CustomerClassDetailList_NotApply_Old,'') = ''  THEN 'IN (' + @CustomerClassDetailList_Old + ')'  ELSE 'NOT IN (' + @CustomerClassDetailList_NotApply_Old + ')'  END ,space(1)) + '" ' 
						+ 'Status="'+ coalesce(cast(@Status_Old as varchar(10)),space(1)) + '" '
						+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
						+ ' />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= @UserId,
		@ActionId			= @ActionID,
		@TrackingValue		= @LogData,
		@TrackingValue2		= @LogData_Old,
		@Duration			= @Duration

	DROP TABLE #ValidData
END
GO


