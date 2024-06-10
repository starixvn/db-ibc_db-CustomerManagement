/*<info serverAlias="DBACC-bodb02,DBACC-BODB02" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Nap_LM_CustomerClassLeagueGroupSel] 
	@SportType SMALLINT = 0
AS
/*
	Created: Winfred
	Date: 20221209
	Task : [NAP CM] Build Customer Class Management [#180904]
	DB: DBACC/BODB02
	Original:

	Revisions:
		- 20221209@Winfred: [NAP CM] Build Customer Class Management [RedmineID: #180904] 
		- 20231031@Winfred: NAPCM - Cannot filter specific filters and show league group None on grid [RedmineID: #196365] 
		- 20240122@Winfred: NAPCM - Support for Saba [RedmineID: #193809] 
		- 20240610@Winfred: NAPCM - CCS - EC24 Preparation [RedmineID: #206297]  

	Param's Explanation:
		* @SportType : 0 All
	Example: Nap_LM_CustomerClassLeagueGroupSel
*/ 
BEGIN
	SET NOCOUNT ON;
	IF @SportType = 0
	BEGIN
		SELECT GroupID, GroupName ,SportType
		FROM LeagueGroup WITH(NOLOCK)
		ORDER BY GroupName
	END
	ELSE
	BEGIN
		IF @SportType = 1  --Soccer
		BEGIN
			SELECT GroupID, GroupName ,SportType
			FROM LeagueGroup WITH(NOLOCK)
			WHERE SportType IN (0, @SportType) AND GroupID NOT IN (42, 74, 108)
			ORDER BY GroupName
		END
		ELSE IF @SportType = 9901  --Saba Soccer
		BEGIN
			SELECT GroupID, GroupName ,SportType
			FROM LeagueGroup WITH(NOLOCK)
			WHERE GroupID IN (42, 74, 108) OR SportType = 0
			ORDER BY GroupName
		END
		ELSE IF @SportType = 2  --Basketball
		BEGIN
			SELECT GroupID, GroupName ,SportType
			FROM LeagueGroup WITH(NOLOCK)
			WHERE SportType IN (0, @SportType) AND GroupID NOT IN (42)
			ORDER BY GroupName
		END
		ELSE IF @SportType = 9902 --Saba Basketball
		BEGIN
			SELECT GroupID, GroupName ,SportType
			FROM LeagueGroup WITH(NOLOCK)
			WHERE GroupID IN (42) OR SportType = 0
			ORDER BY GroupName
		END
		ELSE
		BEGIN
			SELECT GroupID, GroupName ,SportType
			FROM LeagueGroup WITH(NOLOCK)
			WHERE SportType IN (0, @SportType)
			ORDER BY GroupName
		END
	END
END
GO
