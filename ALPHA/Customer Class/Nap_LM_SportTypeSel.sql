/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Nap_LM_SportTypeSel] 
AS
/*
	Created: Winfred
	Date: 20221209
	Task : [NAP CM] Build Customer Class Management [#180904]
	DB: DBACC/bodb02
	Original:

	Revisions:
		- 20240122@Winfred: [NAP CM] NAPCM - Support for Saba [RedmineID: #193809] 

	Param's Explanation:
	Example: EXEC Nap_LM_SportTypeSel
*/ 
BEGIN
	SET NOCOUNT ON;

	SELECT CAST(SportType AS SMALLINT) AS SportType, SportName
	FROM Sports WITH (NOLOCK)
	WHERE SportType in (1,2,43,99)
	UNION
	SELECT CAST(ResourceId AS SMALLINT) AS SportType, Resource_en AS SportName
	FROM RefResource WITH (NOLOCK)
	WHERE RefId='DummySport' AND ResourceId IN (9901, 9902)
	
END
GO
