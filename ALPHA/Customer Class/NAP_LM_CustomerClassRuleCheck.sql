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
	CREATE TABLE #RuleError( RuleID INT, RuleTitle	VARCHAR(500)) 
	CREATE TABLE #RuleTemp( RuleID INT) 
	INSERT INTO #RuleTemp(RuleID)
	SELECT VALUE AS RuleID FROM STRING_SPLIT(@RuleIDs,',') WHERE VALUE <> ''

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassRule a WITH(NOLOCK) 
					CROSS APPLY ( SELECT TOP 1 RuleID FROM #RuleTemp WHERE RuleID = a.RuleID ) b
				WHERE a.IsTest <> @IsTest ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot Delete PROD data' 
		RETURN
	END	

	INSERT INTO #RuleError(RuleID, RuleTitle)
	SELECT DISTINCT a.RuleID, b.RuleTitle 
	FROM #RuleTemp a 
		CROSS APPLY ( SELECT TOP 1 RuleTitle FROM CustomerClassRule WHERE RuleID = a.RuleID AND IsTest = @IsTest ) b
		CROSS APPLY ( SELECT TOP 1 PolicyID FROM CustomerClassPolicyRule  WITH(NOLOCK) WHERE RuleID = a.RuleID ) c
	ORDER BY a.RuleID

	SELECT RuleID, RuleTitle FROM #RuleError ORDER BY RuleID

	IF 	EXISTS(SELECT TOP 1 1 FROM #RuleError a) 
	BEGIN
		SELECT @ErrCode = 106 , @ErrMsg = 'If you delete, they will also be removed from policies.' 
		RETURN
	END	

	DROP TABLE #RuleTemp
END
GO
