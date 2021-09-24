/*<info serverAlias="DBACC-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE Age_CustomerSelSecurityFunctionInfo
	@custid		INT,
	@SubAccId	INT = 0
AS
/*
	Created: Elodie
	Date: 20210812
	Task: Get security function info 
	DB: DBACC/bodb02
		
	Revisions:
		- 20210812@Elodie: Initial sp [Redmine: #159628]

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
