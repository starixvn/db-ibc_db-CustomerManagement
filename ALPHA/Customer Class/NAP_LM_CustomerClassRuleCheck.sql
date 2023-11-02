/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_LM_CustomerClassRuleCheck] 
	  @RuleIDs		VARCHAR(MAX)
	, @IsTest		TINYINT	
	, @ErrCode		INT				= 0		OUTPUT
	, @ErrMsg		NVARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: Winfred
	Date: 20221209
	Task : Support to delete settings Customer Class Management [#188590]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20231101@Winfred: [NAP CM] Customer Class - Support to delete settings [RedmineID: #188590] 

	Param's Explanation:
	* @RuleIDs: List ID Rule

	Example: NAP_LM_CustomerClassRuleCheck @RuleIDs = '1,2,3,4,5,6,9,7,8,11'
*/ 
BEGIN
	SET NOCOUNT ON;

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassRule a WITH(NOLOCK) 
					CROSS APPLY ( SELECT  TOP 1 VALUE FROM STRING_SPLIT(@RuleIDs,',') WHERE VALUE = a.RuleID ) b
				WHERE a.IsTest <> @IsTest ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot Delete PROD data' 
		RETURN
	END	

	SELECT DISTINCT a.RuleID, a.RuleTitle 
	FROM CustomerClassRule a WITH(NOLOCK) 
		CROSS APPLY ( SELECT  TOP 1 VALUE FROM STRING_SPLIT(@RuleIDs,',') WHERE VALUE = a.RuleID ) b
		CROSS APPLY ( SELECT  TOP 1 PolicyID FROM CustomerClassPolicyRule  WITH(NOLOCK) WHERE RuleID = a.RuleID ) c
	WHERE a.IsTest = @IsTest
	ORDER BY a.RuleID
END
GO
