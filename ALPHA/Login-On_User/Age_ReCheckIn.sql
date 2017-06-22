
CREATE PROCEDURE [dbo].[Age_RecheckIn] 
	@On_UserID int,
	@IsKickedOut bit = 0 OUTPUT
AS
SET NOCOUNT ON
/*
Created: 20110912@Sophia
Task : Agent recheckin
DB: DB03.ON_USER
Original SP: Acc_RecheckIn

Revisions:
Param's Explanation:

*/

---- 20110901@Joe: using OUTPUT table, to skip 1 round of reading on on_user table
 
Declare @OUTPUT TABLE (IsKickedOut bit)

update on_user_agent with (ROWLOCK)
set reload_time = getdate() 
OUTPUT DELETED.IsKickedOut INTO @OUTPUT
where on_userid = @On_UserID


IF @@ROWCOUNT = 0
	SELECT @IsKickedOut = 1
ELSE IF EXISTS (SELECT 1 FROM @OUTPUT WHERE IsKickedOut = 1)
	SELECT @IsKickedOut = 1
ELSE
	SET @IsKickedOut = 0

GO
GRANT EXECUTE ON [dbo].[Age_RecheckIn] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_RecheckIn] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CheckOut] TO [vnteam]
GO
