 ALTER PROCEDURE dbo.DBA_AccAdminPolicyDel_RMS
	@CustID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
	/*
		Created: 20120725@Johnson
		DB: DB054.bodb_RMS
		Task: Remove admin out RMS system	
		
		Revisions:
			
	*/

SET NOCOUNT ON

--Delete RMS admin if exists
IF EXISTS (SELECT 1 FROM rmUserInfo WITH(NOLOCK) WHERE userid = @custid)
BEGIN
	DELETE FROM rmUserInfo WITH(ROWLOCK) WHERE userid = @custid
	DELETE FROM rmUserPolicy WITH(ROWLOCK) WHERE userid = @custid
	
	IF  @@ERROR <> 0
	BEGIN			
		select @ErrMsg = N'Error occurs.Delete unsuccessfully.',@ErrCode = 201
		RETURN
	END	
END

GO
GRANT VIEW DEFINITION ON  [dbo].[DBA_AccAdminPolicyDel_RMS] TO [vnteam]
