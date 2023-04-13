/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicyGet]
	@SportType SMALLINT,
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

	Param's Explanation:
	Example: NAP_LM_CustomerClassPolicyGet	
*/ 
BEGIN
	SET NOCOUNT ON; 
	
	SELECT  DISTINCT a.PolicyID, a.PolicyTitle , a.SportType
	FROM CustomerClassPolicyManagement a WITH(NOLOCK)
	WHERE (@SportType = 0 OR a.SportType = @SportType ) AND a.IsTest <= @IsTest
END
GO
