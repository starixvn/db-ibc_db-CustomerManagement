/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_DormantAccountList_Del] (
	 @CustID	INT,
	 @RoleID	TINYINT
)
AS
/*
	Created: 20201209@Eden
	Task : Delete data from Cust_ArchiveAccount.
	DB: DBCUST/CUSTDB
	Original:

	Revisions:  
	- 20201209@Eden: Alpha Site | Implement Dormant Account List [RedmineID: #144903]

	Parameter Definition

	Example: 
		EXEC Acc_DormantAccountList_Del 
			@CustId = 46773170,
			@RoleID = 2
	
	*/
BEGIN
	SET NOCOUNT ON

	IF @RoleID = 2
	BEGIN
		DELETE c
		FROM Cust_ArchiveAccount c WITH(ROWLOCK)
		WHERE c.recommend = @CustID
	END
	IF @RoleID = 3
	BEGIN
		DELETE c
		FROM Cust_ArchiveAccount c WITH(ROWLOCK)
		WHERE c.CustID = @CustID
	END
END
GO


