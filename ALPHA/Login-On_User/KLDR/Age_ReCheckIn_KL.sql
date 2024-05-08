/*<info serverAlias="DBONUSER-ON_USER" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_RecheckIn_KL] 
	@On_UserID int,
	@IsKickedOut bit = 0 OUTPUT,
	@KickOutReason TINYINT = 0 OUTPUT
AS
/*
Created: 20110912@Sophia
Task : Agent recheckin
DB: DB03.ON_USER
Original SP: Acc_RecheckIn

Revisions:
	- 20190614@Johnson: force kickout when upline reset pwd [redmine:#114566]
	- 20231102@Elodie: Use local variable instead of temp table [redmine:#196260]
	- 20231218@Johnson: setup KL DR [redmine: #195700]
Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON
	---- 20110901@Joe: using OUTPUT table, to skip 1 round of reading on on_user table
	--UPDATE on_user_agent with (ROWLOCK)
--	SET reload_time = GETDATE(),
--		@IsKickedOut = IsKickedOut,
--		@KickOutReason = ISNULL(@KickOutReason,0)
--	WHERE on_userid = @On_UserID

--	IF @@ROWCOUNT = 0
--		SELECT @IsKickedOut = 1, @KickOutReason = ISNULL(@KickOutReason,0)
	
	SELECT @IsKickedOut = 0
END
GO

