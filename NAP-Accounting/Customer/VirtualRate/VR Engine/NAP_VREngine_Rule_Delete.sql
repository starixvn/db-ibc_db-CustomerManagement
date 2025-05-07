/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_VREngine_Rule_Delete] 
	@UserID INT = NULL,
	@IP VARCHAR(20) = '',
	@RuleID INT,
	@ErrorCode INT = 0 OUTPUT,
	@ErrorMsg VARCHAR(MAX) = '' OUTPUT 
AS
/*
	Created: 20210428@Eden
	Task : VR Engine - Delete Rule
	DB: DBCUST-CUSTDB
	Original:

	Revisions:  
	- 20210428@Eden: First commit [Redmine:#136423]
	- 20240319@Luke: [NAP CM] VR Engine - Add in new criteria: Apply follow the VR accumulated balance, Currency [Redmine: #201333]
	- 20240422@Winfred: [NAP CM] VR Engine - Allow to add CC by Sport, and re-arrange league group on dropdownlist [Redmine: #195539]
	- 20240701@Winfred: Scale Out DBCUST - Apply In-house Replication for Virtual Rate Setting  [redmine: #207029]
	- 20241230@Winfred: [NAP CM] VR Engine - Pre-match Period with Extra VR [redmine: #215791]

	Parameter explanation:

	Example: 
	DECLARE @ErrorCode INT = 0 ,@ErrorMsg VARCHAR(MAX) = '' 
	EXEC NAP_VREngine_Rule_Delete 
		@UserID = 8,
		@IP = '1.1.1.1',
		@RuleID = 12,
		@ErrorCode = @ErrorCode OUTPUT,
		@ErrorMsg = @ErrorMsg OUTPUT
	SELECT @ErrorCode,@ErrorMsg

	*/
BEGIN	
	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @ActionID INT = 835
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
		@CurrencyIDList_Old VARCHAR(MAX),
		@CurrencyIDList_NotApply_Old VARCHAR(MAX),
		@AccumulatedBalance_Old BIT,
		@CustomerClassDetailList_Old VARCHAR(MAX) ,
		@CustomerClassDetailList_NotApply_Old VARCHAR(MAX),
		@CCSporttypeList_Old VARCHAR(MAX) ,
		@CCSporttypeList_NotApply_Old VARCHAR(MAX),
		@TimeBeforeKO_Old SMALLMONEY

	SET @StartRun = GETDATE()

	IF NOT EXISTS( SELECT 1 FROM VRSettingRule WITH(NOLOCK) WHERE RuleID = @RuleID)
	BEGIN
		SELECT @ErrorCode = 10,
			@ErrorMsg = 'The rule does not exist.'
		RETURN
	END	

	DECLARE @RuleName VARCHAR(100),
			@AdjustmentType VARCHAR(20),
			@AdjustmentValue VARCHAR(10),
			@Status VARCHAR(10)

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
		,@TimeBeforeKO_Old = TimeBeforeKO
	FROM VRSettingRule r WITH(NOLOCK)
	WHERE RuleID = @RuleID

	DELETE c
	OUTPUT deleted.RuleID, [dbo].[f_GetDateTime2]() 
	INTO VRSettingRule_Del_Inhouse(RuleID,RepUpdateTime)
	FROM VRSettingRule c WITH(ROWLOCK,UPDLOCK)
	WHERE RuleID = @RuleID

	DELETE c
	OUTPUT deleted.DetailID, [dbo].[f_GetDateTime2]() 
	INTO VRSettingRuleDetail_Del_Inhouse(DetailID,RepUpdateTime)
	FROM VRSettingRuleDetail c WITH(ROWLOCK,UPDLOCK)
	WHERE RuleID = @RuleID

	DELETE c
	OUTPUT deleted.DetailID, [dbo].[f_GetDateTime2]() 
	INTO VRSettingRuleDetail_NotApply_Del_Inhouse(DetailID,RepUpdateTime) 
	FROM VRSettingRuleDetail_NotApply c WITH(ROWLOCK,UPDLOCK)
	WHERE RuleID = @RuleID

	SET @EndRun = GETDATE()
	SET @Duration = DATEDIFF (MILLISECOND, @StartRun, @EndRun)

	DECLARE @LogData_Old VARCHAR(MAX)
	SET @LogData_Old = '<R '
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
						+ 'AdjustmentType="'+ coalesce(cast(@AdjustmentType_Old as varchar(20)),space(1)) + '" ' 
						+ 'AdjustmentValue="'+ coalesce(cast((CASE	WHEN @AdjustmentType_Old = 1 THEN (@AdjustmentValue_Old -1 ) * 100 
																	WHEN @AdjustmentType_Old = 2 THEN @AdjustmentValue_Old * 100
																	WHEN @AdjustmentType_Old = 3 THEN @AdjustmentValue_Old * 100
																END)
															as varchar(10)),space(1)) + '" '
						+ 'CCSporttype="'+ coalesce(CASE WHEN ISNULL(@CCSportTypeList_NotApply_Old,'') = ''  THEN 'IN (' + @CCSportTypeList_Old + ')'  ELSE 'NOT IN (' + @CCSportTypeList_NotApply_Old + ')'  END ,space(1)) + '" ' 
						+ 'CustomerClassDetail="'+ coalesce(CASE WHEN ISNULL(@CustomerClassDetailList_NotApply_Old,'') = ''  THEN 'IN (' + @CustomerClassDetailList_Old + ')'  ELSE 'NOT IN (' + @CustomerClassDetailList_NotApply_Old + ')'  END ,space(1)) + '" ' 
						+ 'CurrencyID="'+ coalesce(CASE WHEN ISNULL(@CurrencyIDList_NotApply_Old,'') = ''  THEN 'IN (' + @CurrencyIDList_Old + ')'  ELSE 'NOT IN (' + @CurrencyIDList_NotApply_Old + ')'  END ,space(1)) + '" ' 
						+ 'AccumulatedBalance="'+ coalesce(cast(@AccumulatedBalance_Old as varchar(2)),space(1)) + '" '
						+ 'Status="'+ coalesce(cast(@Status_Old as varchar(10)),space(1)) + '" '
						+ 'TimeBeforeKO="'+ coalesce(cast(@TimeBeforeKO_Old as varchar(10)),space(1)) + '" '
						+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
						+ ' />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= @UserId,
		@ActionId			= @ActionID,
		@TrackingValue		= @LogData_Old,
		@Duration			= @Duration
END
GO


