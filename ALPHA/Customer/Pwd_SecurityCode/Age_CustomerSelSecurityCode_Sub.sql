ALTER PROCEDURE [dbo].[Age_CustomerSelSecurityCode_Sub]
	@SubAccId	INT,
	@custid		INT
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
	FROM CustLoginInfoSub WITH(NOLOCK)
	WHERE SubAccID = @SubAccID AND custid = @custid

GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelSecurityCode_Sub] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelSecurityCode_Sub] TO [bodbDownlineNetView]