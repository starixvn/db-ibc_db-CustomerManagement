/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE Age_CustomerSelProtectionCode
	@Custid			INT,
	@SubAccID		INT = 0
 AS
 /*
	Created: Elodie
	Date: 20210824
	Task: Get ProtectionCode
	DB: DBCUST/CustDB
		
	Revisions:
		- 20210824@Elodie: Initial sp [Redmine: #160151]

	Parameter's Explanation:
	Example: EXEC Age_CustomerSelProtectionCode @Custid = 838203, @SubAccId = 29183

*/ 
BEGIN	
	SET NOCOUNT ON
	IF @SubAccID = 0 
		SELECT ISNULL(ProtectionCode,'') 
		FROM CustLoginInfo WITH(NOLOCK)
		WHERE custid = @custid
	ELSE
		SELECT ISNULL(ProtectionCode,'') 
		FROM CustLoginInfoSub WITH(NOLOCK)
		WHERE custid = @custid AND SubAccId = @SubAccID
END
GO
