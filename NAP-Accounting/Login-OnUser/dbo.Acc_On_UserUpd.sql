ALTER PROCEDURE [dbo].[Acc_On_UserUpd] 
	@On_UserID int,
	@IsKickedOut bit = 0 OUTPUT
AS
/*
	Created: []
	Task: Login 
	DB:DB03.ON_USER
	
*/
SET NOCOUNT ON
if exists (select 1 from on_user with (NOLOCK) where On_UserID = @On_UserID and isKickedOut=1)
BEGIN
	Select @IsKickedOut=1
END
else
BEGIN
	Select @IsKickedOut = 0
	update on_user with (ROWLOCK, UPDLOCK) set reload_time = getdate() 
	where on_userid = @On_UserID
	
	IF @@ROWCOUNT = 0
		Select @IsKickedOut=1
END
GO
GRANT EXECUTE ON [dbo].[Acc_On_UserUpd] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_On_UserUpd] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_On_UserUpd] TO [VNTeam]
GO 
