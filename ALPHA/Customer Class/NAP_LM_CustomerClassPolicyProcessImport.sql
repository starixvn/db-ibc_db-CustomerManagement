/*<info serverAlias="DBACC-bodb02,DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicyProcessImport] 
	@UserID		INT
	,@LastModifiedTime DATETIME = NUll OUTPUT
	,@CountBatch	INT = 0 OUTPUT 
    ,@InitialBatch	INT = 0 OUTPUT
AS
/*
	Created: Winfred
	Date: 20240223
	Task : [NAP CM] Enhance SP to call loop for updating policies [#201256]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20240223@Winfred: [NAP CM] - CCMgt - Update SP to call loop for updating policies [RedmineID: #201256]  
		- 20240315@Winfred: [NAP CM] - CCMgt - Enhance SP call loop for updating policies [RedmineID: #201256] 
		- 20240610@Winfred: NAPCM - CCS - EC24 Preparation [RedmineID: #206297]  

	Param's Explanation:
	* @MaxBatchID: Max ID batch input
	* @InitialBatch : row count initial in batch
	Example: NAP_LM_CustomerClassPolicyProcessImport @UserID =8,  @CountBatch = 0 OUTPUT, @InitialBatch =0 OUTPUT
*/ 
BEGIN
	SET NOCOUNT ON;   
   
	IF 	@LastModifiedTime IS NULL
	BEGIN
		SELECT @LastModifiedTime = MIN(LastModifiedTime) FROM CustomerClassSMQueue WITH (NOLOCK) WHERE Status = 0 AND UserID = @UserID
	END

	IF EXISTS( SELECT TOP 1 1 FROM CustomerClassSMQueue WITH (NOLOCK) WHERE Status = 0 AND UserID = @UserID AND LastModifiedTime >= @LastModifiedTime AND ActionID = 1)	-- EXISTS import excel row
	BEGIN
		SELECT @CountBatch = COUNT(ID) FROM CustomerClassSMQueue WITH (NOLOCK) 
		WHERE LastModifiedTime >= @LastModifiedTime AND UserID = @UserID AND Status IN ( 0,1,2)

		SELECT @InitialBatch = COUNT(ID) FROM CustomerClassSMQueue WITH(NOLOCK) 
		WHERE LastModifiedTime >=  @LastModifiedTime  AND UserID = @UserID AND Status = 0
	END	 
END
