/*<info serverAlias="DBCUST-custDB" executers="wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE Age_CustomerSelSecurityFunctionInfo
	@custid		INT,
	@SubAccId	INT = 0
AS
/*
	Created: Elodie
	Date: 20210812
	Task: Get security function info 
	DB: DBCUST/custDB
		
	Revisions:
		- 20210812@Elodie: Initial sp [Redmine: #159628]
		- 20220419@Elodie: Move SP to DBCUST [Redmine: #171669]
	Parameter's Explanation:
	Example: EXEC Age_CustomerSelSecurityFunctionInfo @custid = 838203
*/ 
BEGIN
	SET NOCOUNT ON
	IF @SubAccId = 0 
		SELECT f1.IsOn AS 'BetList', f2.IsOn AS 'Statement'
		FROM CustLoginInfo cl WITH(NOLOCK)
			CROSS APPLY (SELECT IsOn FROM f_GetSecurityFunctionInfo(1,ISNULL(cl.FunctionInfo,0))) f1
			CROSS APPLY (SELECT IsOn FROM f_GetSecurityFunctionInfo(2,ISNULL(cl.FunctionInfo,0))) f2
		WHERE custid = @custid
	ELSE
		SELECT f1.IsOn AS 'BetList', f2.IsOn AS 'Statement'
		FROM CustLoginInfoSub cl WITH(NOLOCK)
			CROSS APPLY (SELECT IsOn FROM f_GetSecurityFunctionInfo(1,ISNULL(cl.FunctionInfo,0))) f1
			CROSS APPLY (SELECT IsOn FROM f_GetSecurityFunctionInfo(2,ISNULL(cl.FunctionInfo,0))) f2
		WHERE custid = @custid AND cl.SubAccId = @SubAccId
END
GO
