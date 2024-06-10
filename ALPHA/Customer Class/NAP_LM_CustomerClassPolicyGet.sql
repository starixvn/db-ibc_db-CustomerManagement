/*<info serverAlias="DBACC-bodb02,DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicyGet]
	@SportTypes VARCHAR(2000),
	@IsTest	TINYINT
AS
/*
	Created: Winfred
	Date: 20221209
	Task : [NAP CM] Build Customer Class Management [#180904]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20221209@Winfred: [NAP CM] Build Customer Class Management [RedmineID: #180904] 
		- 20240314@Winfred: [NAP CM] Customer Class - Grant permission for each Sport type [RedmineID: #199465] 
		- 20240610@Winfred: NAPCM - CCS - EC24 Preparation [RedmineID: #206297]  

	Param's Explanation:
	Example: NAP_LM_CustomerClassPolicyGet	
*/ 
BEGIN
	SET NOCOUNT ON; 
	
	SELECT  DISTINCT a.PolicyID, a.PolicyTitle , a.SportType
	FROM CustomerClassPolicyManagement a WITH(NOLOCK)
	WHERE a.SportType IN ( SELECT CAST(VALUE AS INT) FROM STRING_SPLIT(@SportTypes ,',') WHERE VALUE <> '') AND a.IsTest <= @IsTest
END
GO
