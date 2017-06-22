ALTER PROCEDURE dbo.DBA_AccAdminPolicyDel
	@CustID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
	/*
		Created: @DBA
		DB: DB03.bodb02
		Task: Remove admin out system	
		
		Revisions:
			- 20120718@Johnson: - change table AccCustomer to AccCustomer_1							
	*/
	
SET NOCOUNT ON

IF EXISTS (SELECT 1 FROM AccCustomer_1 WITH(NOLOCK) WHERE custid = @custid)
BEGIN
	DELETE FROM Acc_MemberPolicy_1 WITH(ROWLOCK) WHERE Custid=@Custid
	DELETE FROM AccCustomer_1 WITH(ROWLOCK) WHERE Custid = @Custid
	
	IF  @@ERROR <> 0
	BEGIN			
		select @ErrMsg = N'Error occurs.Delete unsuccessfully.',@ErrCode = 101
		RETURN
	END
END

GO
GRANT VIEW DEFINITION ON  [dbo].[DBA_AccAdminPolicyDel] TO [vnteam]