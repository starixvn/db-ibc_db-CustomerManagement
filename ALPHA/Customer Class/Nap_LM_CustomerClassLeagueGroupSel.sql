/*<info serverAlias="DBACC-BODB02" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
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
		SELECT GroupID, GroupName ,SportType
		FROM LeagueGroup WITH(NOLOCK)
		WHERE SportType = @SportType
		ORDER BY GroupName
	END
END
GO
