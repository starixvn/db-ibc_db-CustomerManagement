/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  [dbo].[Acc_CustomerVRAdjust_Confirm] 
	@CustID int,
	@Message NVARCHAR(500) = '' OUTPUT
AS
/*
	Created: 20200827@Eden
	DB: DBCUST/CUSTDB
	Task: checking to show confirmation when update SMA VR1 (NAP)
		
	Revisions:
		- 20200827@Eden: VR Adjustment by Agent profile [#140421]
		- 20200903@Eden: Adjust VR setting for Soccer of Haifa, IBO [redmine: #140368]
		- 20210223@Eden: Implement Lock for VR update [Redmine:#149370]

	Parameter's Explanation:

	DECLARE @Message NVARCHAR(500)
	EXEC Acc_CustomerVRAdjust_Confirm 
		@CustID = 44757232
		, @Message = @Message OUTPUT
	SELECT @Message
*/	
BEGIN
	DECLARE @RoleID TINYINT
	SELECT @RoleID = RoleID FROM custinfo WITH(NOLOCK) WHERE custid = @CustID

	IF @RoleID = 1
		SELECT @Message = 'Are you sure that you want to update this Virtual Exchange Rate value for this account?'
	ELSE
		SELECT @Message = 'Are you sure that you want to update these virtual rate values for this account and all of its non-locked downlines?'
END
