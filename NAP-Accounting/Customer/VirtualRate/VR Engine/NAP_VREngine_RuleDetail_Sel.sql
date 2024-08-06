/*<info serverAlias="DBACC-bodb02" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_VREngine_RuleDetail_Sel] 
	@RuleID INT = NULL
AS
/*
	Created: 20210428@Eden
	Task : VR Engine - Get Rule List
	DB: DBACC-bodb02
	Original:

	Revisions:  
	- 20210428@Eden: First commit [Redmine:#136423]
	- 20240319@Luke: [NAP CM] VR Engine - Add in new criteria: Apply follow the VR accumulated balance, Currency [Redmine: #201333]
	- 20240422@Winfred: [NAP CM] VR Engine - Allow to add CC by Sport, and re-arrange league group on dropdownlist [Redmine: #195539]

	Parameter explanation:
			
	Example: 
	EXEC NAP_VREngine_RuleDetail_Sel @RuleID = 12

	*/
BEGIN
	SELECT RuleID
		,RuleName
		,SiteType
		,Betfrom
		,StakeRM_From
		,StakeRM_To
		,VR_From = (VR_From -1 ) * 100
		,VR_To = (VR_To -1 ) * 100
		,VRStatus
		,BeginTime
		,EndTime
		,LiveIndicator
		,Adjustmenttype
		,AdjustmentValue = CASE WHEN Adjustmenttype = 1 THEN (AdjustmentValue -1 ) * 100 
								WHEN Adjustmenttype = 2 THEN AdjustmentValue * 100
							END
		,Priority
		,Status
		,ISNULL(c.username,'') AS CreatedBy
		,CreatedDTS
		,Enabled_Column
		,AccumulatedBalance
		,SportTypeList =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.Sporttype)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY Sporttype
									ORDER BY Sporttype
									FOR XML PATH ('')
									),1,1,'')
		,BettypeList =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.Bettype)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY Bettype
									ORDER BY Bettype
									FOR XML PATH ('')
									),1,1,'')
		,LeagueGroupList =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.LeagueGroupID)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY LeagueGroupID
									ORDER BY LeagueGroupID
									FOR XML PATH ('')
									),1,1,'')
		,LeagueList =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.Leagueid)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY Leagueid
									ORDER BY Leagueid
									FOR XML PATH ('')
									),1,1,'')

		,SiteIDList =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.SiteID)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY SiteID
									ORDER BY SiteID
									FOR XML PATH ('')
									),1,1,'')
		,CustomerClassList =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CustomerClass)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY CustomerClass
									ORDER BY CustomerClass
									FOR XML PATH ('')
									),1,1,'')
		,DateOfWeekList =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.DateOfWeek)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY DateOfWeek
									ORDER BY DateOfWeek
									FOR XML PATH ('')
									),1,1,'')
		,CurrencyIDList =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CurrencyID)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY CurrencyID
									ORDER BY CurrencyID
									FOR XML PATH ('')
									),1,1,'')

		,SportTypeList_NotApply =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.Sporttype)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND Sporttype <> 0
									GROUP BY Sporttype
									ORDER BY Sporttype
									FOR XML PATH ('')
									),1,1,'')
		,BettypeList_NotApply =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.Bettype)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND Bettype <> 0
									GROUP BY Bettype
									ORDER BY Bettype
									FOR XML PATH ('')
									),1,1,'')
		,LeagueGroupList_NotApply =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.LeagueGroupID)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND LeagueGroupID <> -1
									GROUP BY LeagueGroupID
									ORDER BY LeagueGroupID
									FOR XML PATH ('')
									),1,1,'')
		,LeagueList_NotApply =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.Leagueid)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND Leagueid <> -1
									GROUP BY Leagueid
									ORDER BY Leagueid
									FOR XML PATH ('')
									),1,1,'')

		,SiteIDList_NotApply =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.SiteID)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND SiteID <> 0
									GROUP BY SiteID
									ORDER BY SiteID
									FOR XML PATH ('')
									),1,1,'')
		,CustomerClassList_NotApply =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CustomerClass)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND CustomerClass <> 0
									GROUP BY CustomerClass
									ORDER BY CustomerClass
									FOR XML PATH ('')
									),1,1,'')
		,DateOfWeekList_NotApply =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.DateOfWeek)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND DateOfWeek <> 0
									GROUP BY DateOfWeek
									ORDER BY DateOfWeek
									FOR XML PATH ('')
									),1,1,'')
		,CurrencyIDList_NotApply =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CurrencyID)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND CurrencyID <> 0
									GROUP BY CurrencyID
									ORDER BY CurrencyID
									FOR XML PATH ('')
									),1,1,'')							
		,CCSportTypeList =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CCSporttype)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY CCSporttype
									ORDER BY CCSporttype
									FOR XML PATH ('')
									),1,1,'')
		,CustomerClassDetailList =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CustomerClassDetail)
									FROM VRSettingRuleDetail rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
									GROUP BY CustomerClassDetail
									ORDER BY CustomerClassDetail
									FOR XML PATH ('')
									),1,1,'')
		,CCSportTypeList_NotApply =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CCSporttype)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND CCSporttype <> 0
									GROUP BY CCSporttype
									ORDER BY CCSporttype
									FOR XML PATH ('')
									),1,1,'')
		,CustomerClassDetailList_NotApply =	STUFF(( SELECT ',' + CONVERT(VARCHAR,rd.CustomerClassDetail)
									FROM VRSettingRuleDetail_NotApply rd WITH(NOLOCK) 
									WHERE rd.RuleID = r.ruleID
										AND CustomerClassDetail <> 0
									GROUP BY CustomerClassDetail
									ORDER BY CustomerClassDetail
									FOR XML PATH ('')
									),1,1,'')
	FROM VRSettingRule r WITH(NOLOCK)
		LEFT JOIN custInfo c WITH(NOLOCK)
			ON r.CreatedBy = c.custid
	WHERE r.RuleID = @RuleID
END
GO


