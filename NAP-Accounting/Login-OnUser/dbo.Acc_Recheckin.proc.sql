/*<info serverAlias="DBONUSER-ON_USER" executers="bodbAdminNet,bodbExtAccNet" viewers="VNTeam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ReCheckIn] 
	@On_UserID	 int,
	@IsKickedOut tinyint=0 OUTPUT
AS
/*
	Created: 20110912@Sophia
	Task :	- Accounting Re check in
			- Move the content of Acc_ReCheckIn to Age_ReCheckIn
			- And then move the content of Acc_On_UserUpd to Acc_ReCheckIn
	DB: DB03.ON_USER
	Original SP: Acc_On_UserUpd

	Revisions:
			- 20221118@Tacy: NAP - Set expired time for permission [RedmineID: #179323]
			- 20221228@Tacy: NAP Accounting - Expired date error - kick-out before expire time [RedmineID:#182093]
	Param's Explanation:
		@IsKickedOut = 0
					 = 1 : "Another session has been logged in or your session is expired. Forced to logout!"
					 = 2 : "Your Account was Expired, Please contact your supervisor"
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @CustID INT
	
	SELECT @CustID=custid
	FROM on_user_admin WITH (NOLOCK) 
	WHERE On_UserID = @On_UserID

	IF EXISTS (SELECT 1 FROM DBCUST.NAP_UserControl.dbo.AccCustomer WITH (NOLOCK) WHERE custid=@CustID AND ExpiredDate<GETDATE())
	BEGIN
		SELECT @IsKickedOut=2
	END
	ELSE IF EXISTS (SELECT 1 FROM on_user_admin WITH (NOLOCK) WHERE On_UserID = @On_UserID AND isKickedOut=1)
	BEGIN
		SELECT @IsKickedOut=1
	END
	ELSE
	BEGIN
		SELECT @IsKickedOut = 0

		UPDATE on_user_admin WITH (ROWLOCK, UPDLOCK) SET reload_time = getdate() 
		WHERE on_userid = @On_UserID
	
		IF @@ROWCOUNT = 0
			SELECT @IsKickedOut=1
	END
END
GO