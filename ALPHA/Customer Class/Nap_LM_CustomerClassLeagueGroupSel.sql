/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Nap_LM_CustomerClassLeagueGroupSel] 
AS
/*
	Created: Winfred
	Date: 20221209
	Task : [NAP CM] Build Customer Class Management [#180904]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20221209@Winfred: [NAP CM] Build Customer Class Management [RedmineID: #180904] 

	Param's Explanation:
	Example: Nap_LM_CustomerClassLeagueGroupSel
*/ 
BEGIN
	SET NOCOUNT ON;

	SELECT GroupID, GroupName ,SportType
	FROM DBACC.BODB02.DBO.LeagueGroup WITH(NOLOCK)
	ORDER BY GroupName
END
GO
