ALTER PROCEDURE [dbo].[Age_CustomerSelSecurityCode]
	@custid	INT
AS
	/*
		Created: Johnson
		Date: 2013-04-17
		Task: Get security code 
		DB: DBTXN/bodb02
		
		Revisions:
		
		Parameter's Explanation:
	*/ 
SET NOCOUNT ON

	SELECT ISNULL(SecurityCode,'') 
	FROM CustLoginInfo WITH(NOLOCK)
	WHERE custid = @custid

GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelSecurityCode] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelSecurityCode] TO [wsv_alpv] 