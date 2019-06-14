/*<info serverAlias="DBONUSER-ON_USER" executers="bodbDownlineNet, bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_RecheckIn] 
	@On_UserID int,
	@IsKickedOut bit = 0 OUTPUT,
	@KickOutReason TINYINT = 0 OUTPUT
AS
SET NOCOUNT ON
/*
Created: 20110912@Sophia
Task : Agent recheckin
DB: DB03.ON_USER
Original SP: Acc_RecheckIn

Revisions:
	- 20190614@Johnson: force kickout when upline reset pwd [redmine:#114566]
Param's Explanation:

*/

---- 20110901@Joe: using OUTPUT table, to skip 1 round of reading on on_user table
 
Declare @OUTPUT TABLE (IsKickedOut bit, KickOutReason TINYINT)

update on_user_agent with (ROWLOCK)
set reload_time = getdate() 
OUTPUT DELETED.IsKickedOut, DELETED.KickOutReason INTO @OUTPUT(isKickedOut, KickOutReason)
where on_userid = @On_UserID


IF @@ROWCOUNT = 0
	SELECT @IsKickedOut = 1
ELSE IF EXISTS (SELECT 1 FROM @OUTPUT WHERE IsKickedOut = 1)
	BEGIN
		SELECT top (1) @IsKickedOut = 1, @KickOutReason = KickOutReason
		FROM @OutPut
		WHERE isKickedOut = 1
	END
ELSE
	SET @IsKickedOut = 0

GO

