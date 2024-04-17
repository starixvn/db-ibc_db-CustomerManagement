/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE	[dbo].[Age_CustSetting_BetChoiceLimitSelect]
(
	 @BettypeID	  INT = 2401
	, @CustID INT = 0 -- FOR SMA ONLY
)
AS
/*
	Created: 20160812@Helen
	Task: Betchoice Limit info for ALLBET - [redmine: 61873]
	Database: DBCUST/CustDB
	Revisions:	
		- 20220614@Elodie: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
	Param's Explanation:
*/
BEGIN
    SET NOCOUNT ON
    
    CREATE TABLE #StakeLevel (StakeLevelID INT,GameTypeID INT,MinLabel VARCHAR(100),MaxLabel VARCHAR(100))
    
    INSERT INTO #StakeLevel (StakeLevelID ,GameTypeID ,MinLabel ,MaxLabel )
    SELECT tmp.StakeLevelID,sla.BetType GameTypeID,tmp.MinLabel,tmp.MaxLabel
    FROM CustStakeLevel_Agent SLA WITH (NOLOCK) 
		CROSS APPLY (SELECT SL.StakeLevelID,MinLabel,MaxLabel,ExchangeId 
					 FROM string_split(SLA.StakeLevelList,',') AS T
						INNER JOIN StakeLevel SL (NOLOCK) ON T.value = SL.StakeLevelID ) AS tmp
    WHERE SLA.CustID = @CustID AND SLA.BetType = @BettypeID  
    
    
    SELECT StakeLevelID ,GameTypeID ,MinLabel ,MaxLabel
    FROM #StakeLevel
    
	SELECT slg.StakeLevelID,slg.ParentTypeID,slg.GameTypeID,slg.MinLabel,slg.MaxLabel,slg.MinStake,slg.MaxStake
	FROM StakeLevelGroupDetail slg WITH (NOLOCK)
		INNER JOIN #StakeLevel sl ON slg.StakeLevelID = sl.StakeLevelID
	ORDER BY slg.ParentTypeID,slg.GameTypeID
	
	DROP TABLE #StakeLevel
	
	SET NOCOUNT OFF
END



