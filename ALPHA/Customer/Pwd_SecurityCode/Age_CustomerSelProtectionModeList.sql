/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp, bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Age_CustomerSelProtectionModeList
	@Custid			INT,
	@roleid			TINYINT,
	@CustList		VARCHAR(MAX)
 AS
 /*
	Created: Elodie
	Date: 20210824
	Task: Get Protection Mode for ALPHA
	DB: DBCUST/CustDB
	Revisions:
		- 20210824@Elodie: Initial sp [Redmine: #160151]
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 

	Parameter's Explanation:

	Example: EXEC Age_CustomerSelProtectionModeList @Custid = 838203, @roleid = 3, @CustList = '123,345'

*/ 
BEGIN	
	SET NOCOUNT ON
	DECLARE @CustListTmp TABLE (CustId INT)

	INSERT INTO @CustListTmp (CustId)
	SELECT  value
	FROM STRING_SPLIT (@CustList, ',')
	WHERE value <> ''

	SELECT ci.custid, ci.username, ci.roleid, ISNULL(IsProtectedMode,0) AS IsProtectedMode
	FROM CustLoginInfo cl WITH(NOLOCK)
		INNER JOIN CustInfo ci WITH (NOLOCK) ON cl.custid = ci.custid
		INNER JOIN @CustListTmp t ON ci.custid = t.custid
	WHERE CASE WHEN @roleid = 4 THEN ci.srecommend 
				WHEN @roleid = 3 THEN ci.mrecommend 
				WHEN @roleid = 2 THEN ci.recommend END = @custid
		AND ci.roleid = CASE	WHEN @roleid = 4 THEN 3
							WHEN @roleid = 3 THEN 2
							WHEN @roleid = 2 THEN 2 END 
END
GO
