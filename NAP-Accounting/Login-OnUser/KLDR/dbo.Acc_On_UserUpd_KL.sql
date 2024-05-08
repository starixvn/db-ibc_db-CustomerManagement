/*<info serverAlias="DBONUSER-ON_USER" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_On_UserUpd_KL] 
	@On_UserID int,
	@IsKickedOut bit = 0 OUTPUT
AS
/*
	Created: []
	Task: Login 
	DB:DBONUSER/ON_USER
	
	Revisions:
		- 20231219@Johnson: setup KL DR [redmine: #195700]
*/
SET NOCOUNT ON

Select @IsKickedOut = 0
/*
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
END*/

GO