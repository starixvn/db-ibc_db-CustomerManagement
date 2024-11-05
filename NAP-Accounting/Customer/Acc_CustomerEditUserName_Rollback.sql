/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerEditUserName_Rollback]
(
	@oldname VARCHAR(30), 
	@custId INT
)
AS
/*
	Created: Helen
	Date: 2024-10-10
	Task: edit username for CREDIT 
	DB: DBCUST-CUSTDB
	
	Revisions:
		- 20241010@Helen:edit username for CREDIT - [Redmine:#212007]
		
	Parameter's Explanation:
		
*/	
BEGIN
	SET NOCOUNT ON
	
	UPDATE customer WITH (ROWLOCK, UPDLOCK) 
			SET username = @oldname, RepUpdateTime = SYSDATETIME () 
	WHERE custid = @custid

	UPDATE custinfo WITH (ROWLOCK, UPDLOCK) 
		SET username = @oldname, RepUpdateTime = SYSDATETIME () 
	WHERE custid = @custid
	
END
GO

