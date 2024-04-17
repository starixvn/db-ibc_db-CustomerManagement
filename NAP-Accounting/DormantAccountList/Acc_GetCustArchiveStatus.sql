/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,wsv_alp,wsv_alpv,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_GetCustArchiveStatus] (
	 @CustID INT = NULL,
	 @IsArchived BIT = 0 OUTPUT
)
AS
/*
	Created: 20220811@Eden
	Task : get the dormant archive Status
	DB: DBCUST/CUSTDB
	Original:

	Revisions:  
		- 20220811@Eden: get Archive status of customer [RedmineID: #175938]

	Parameter Definition
		@IsArchived = 1: was Deleted setting ( stageid 3,4)

	Example: 
	DECLARE @IsArchived	BIT 
	EXEC [Acc_GetCustArchiveStatus] 
		@CustId = 47216485,
		@IsArchived = @IsArchived OUTPUT
	SELECT @IsArchived
	
	*/
BEGIN
	SET NOCOUNT ON
	SET @IsArchived = 0

	SELECT @IsArchived = CASE WHEN c.StageID >= 3 THEN 1 ELSE 0 END
	FROM Cust_ArchiveAccount c WITH(NOLOCK)
	WHERE c.CustID = @CustID
END
GO


