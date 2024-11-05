/*<info serverAlias="DBGLOB-GLOBCUSTDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustInfoMiniEditUserName_Rollback]
(
	@oldname VARCHAR(30), 
	@custId INT
)
AS
/*
	Created: Helen
	Date: 2024-10-10
	Task: edit username for CREDIT 
	DB: DBGLOB-GLOBCUSTDB
	
	Revisions:
		- 20241010@Helen:edit username for CREDIT - [Redmine:#212007]
		
	Parameter's Explanation:
		
*/	
BEGIN
	SET NOCOUNT ON
	
	UPDATE c	
		SET username = @oldname, RepUpdateTime = SYSDATETIME ()
	FROM CustInfoMini c WITH (ROWLOCK,UPDLOCK)
	WHERE custid = @custId

END
GO

