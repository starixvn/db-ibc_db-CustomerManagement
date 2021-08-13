/*<info serverAlias="DBCUST-custDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/

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
		- 20210812@Elodie: Initial sp [redmine: #159628]

	Parameter's Explanation:
*/ 
BEGIN
	SET NOCOUNT ON
	IF @SubAccId = 0 
		SELECT f1.FunctionInfo AS 'BetList', f2.FunctionInfo AS 'Statement'
		FROM CustLoginInfo cl WITH(NOLOCK)
			CROSS APPLY (SELECT FunctionInfo FROM f_GetSecurityFunctionInfo(1,cl.FunctionInfo)) f1
			CROSS APPLY (SELECT FunctionInfo FROM f_GetSecurityFunctionInfo(2,cl.FunctionInfo)) f2
		WHERE custid = @custid
	ELSE
		SELECT f1.FunctionInfo AS 'BetList', f2.FunctionInfo AS 'Statement'
		FROM CustLoginInfo_Sub cl WITH(NOLOCK)
			CROSS APPLY (SELECT FunctionInfo1 FROM f_GetSecurityFunctionInfo(1,cl.FunctionInfo)) f1
			CROSS APPLY (SELECT FunctionInfo2 FROM f_GetSecurityFunctionInfo(2,cl.FunctionInfo)) f2
		WHERE custid = @custid AND cl.SubAccId = @SubAccId
END
GO
