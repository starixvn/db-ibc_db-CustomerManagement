/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Nap_LM_CustomerClassSel] 
AS
/*
	Created: Winfred
	Date: 20221209
	Task : [NAP CM] Build Customer Class Management [#180904]
	DB: DBACC/bodb02
	Original:

	Revisions:
		- 20221209@Winfred: [NAP CM] Build Customer Class Management [RedmineID: #180904] 

	Param's Explanation:
	Example: EXEC Nap_LM_CustomerClassSel
*/ 
BEGIN
	SET NOCOUNT ON;

	SELECT ResourceId, Resource_en
	FROM RefResource WITH (NOLOCK)
	WHERE RefId='CustomerClass'
	ORDER BY ResourceId
END
GO
