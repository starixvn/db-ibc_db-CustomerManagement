/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_LM_CustomerClassPolicyCheck] 
	  @Policies		VARCHAR(MAX)
	, @IsTest		TINYINT	
	, @IsShow		BIT				= 1	
	, @ErrCode		INT				= 0	 OUTPUT
	, @ErrMsg		NVARCHAR(MAX)	= '' OUTPUT
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
	* @PolicyIDs: List ID Policy

	Example: NAP_LM_CustomerClassPolicyCheck @Policies = '1,2,3,4,5,6,9,7,8,11'
*/ 
BEGIN
	SET NOCOUNT ON;
	CREATE TABLE #PolicyError( PolicyID INT, PolicyTitle VARCHAR(500))
	CREATE TABLE #PolicyTemp( PolicyID INT) 

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassPolicyManagement a WITH(NOLOCK) 
					CROSS APPLY ( SELECT  TOP 1 VALUE FROM STRING_SPLIT(@Policies,',') WHERE VALUE = a.PolicyID ) b
				WHERE a.IsTest <> @IsTest ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot Delete PROD data' 
		RETURN
	END	

	INSERT INTO #PolicyTemp(PolicyID)
	SELECT VALUE AS PolicyID FROM STRING_SPLIT(@Policies,',') WHERE VALUE <> ''
	
	INSERT INTO #PolicyError(PolicyID, PolicyTitle)
	SELECT DISTINCT a.PolicyID, b.PolicyTitle 
	FROM #PolicyTemp  a
		CROSS APPLY (SELECT TOP 1 PolicyTitle FROM CustomerClassPolicyManagement WITH(NOLOCK) WHERE PolicyID = a.PolicyID  AND IsTest = @IsTest) b
		CROSS APPLY (SELECT TOP 1 PolicyID FROM CustomerClassSiteManagement WITH(NOLOCK) WHERE PolicyID = a.PolicyID ) c
	ORDER BY a.PolicyID

	IF	@IsShow = 1
	BEGIN
		SELECT PolicyID, PolicyTitle FROM #PolicyError ORDER BY PolicyID
	END

	IF 	EXISTS(SELECT TOP 1 1 FROM #PolicyError a) 
	BEGIN
		SELECT @ErrCode = 106 , 
			   @ErrMsg = 'If you delete, their assign settings with Site - Currency will also be deleted.' 
		RETURN
	END	

	DROP TABLE #PolicyTemp
	DROP TABLE #PolicyError
END
GO
