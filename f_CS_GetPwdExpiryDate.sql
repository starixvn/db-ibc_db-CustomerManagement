/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet" viewers="" isFunction="1"></info>*/

ALTER FUNCTION f_CS_GetPwdExpiryDate(@roleid TINYINT) 
RETURNS DATETIME 
AS
/*
    Created: Elodie
    Date: 20181212
    Task: Get password expiry date (CS Customer Setting)
    DB: DBCUST/CustDB
    Original versions:                
    Revision:
		- 20181212@Elodie: Initial SP [Redmine: #105338]
		- 20190708@Johnson: set expiry date = yesterday to force change pwd when reset downline pwd [redmine:#116088]
    Example:
		SELECT dbo.f_CS_GetPwdExpiryDate (2)
*/
BEGIN
	DECLARE @Date DATETIME

	SET @Date = DATEADD(dd, -1, GETDATE())
	
	RETURN @Date
END

