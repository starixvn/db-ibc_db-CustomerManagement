ALTER PROCEDURE [dbo].[Acc_ReCheckIn] 
	@On_UserID int,
	@IsKickedOut bit = 0 OUTPUT
AS
/*
Created: 20110912@Sophia
Task :	- Accounting Re check in
		- Move the content of Acc_ReCheckIn to Age_ReCheckIn
		- And then move the content of Acc_On_UserUpd to Acc_ReCheckIn
DB: DB03.ON_USER
Original SP: Acc_On_UserUpd

Revisions:
Param's Explanation:

*/
SET NOCOUNT ON
if exists (select 1 from on_user_admin with (NOLOCK) where On_UserID = @On_UserID and isKickedOut=1)
BEGIN
	Select @IsKickedOut=1
END
else
BEGIN
	Select @IsKickedOut = 0
	update on_user_admin with (ROWLOCK, UPDLOCK) set reload_time = getdate() 
	where on_userid = @On_UserID
	
	IF @@ROWCOUNT = 0
		Select @IsKickedOut=1
END
GO
GRANT EXECUTE ON [dbo].[Acc_ReCheckIn] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_ReCheckIn] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ReCheckIn] TO [VNTeam]
GO 
