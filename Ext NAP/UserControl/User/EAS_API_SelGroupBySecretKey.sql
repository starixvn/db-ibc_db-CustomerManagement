/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_API_SelGroupBySecretKey]
	@APISecretKey	VARCHAR(100)=''
AS
/*
	Created: Tacy
	Task: API for Headline - Select all group assigned to APIKey
	DB: DBPOL/NAP_UserControl

	Revisions:
		- 20240821@Tacy: Create SP [Redmine: #208402]

	Parameter's Explanation:
*/ 
BEGIN
	SET NOCOUNT ON;

	;WITH eaGroup_Main AS (
		SELECT k.APISecretKey, k.GroupName, g.GroupID
		FROM [dbo].[f_API_CheckSecretKey] (@APISecretKey) k
			INNER JOIN eaGroup g WITH (NOLOCK) ON g.GroupName=k.GroupName
	)
	SELECT APISecretKey, GroupName
	FROM eaGroup_Main
	UNION
	SELECT t.APISecretKey, g.GroupName
	FROM eaGroup g WITH (NOLOCK) 
		INNER JOIN eaGroup_Main t ON t.GroupID=g.ParentID
	ORDER BY APISecretKey, GroupName
END