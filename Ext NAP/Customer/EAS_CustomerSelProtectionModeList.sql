/*<info serverAlias="DBCUST-CustDB" executers="wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE EAS_CustomerSelProtectionModeList
	@GroupName		VARCHAR(50),
	@Roleid			TINYINT,
	@UserId			INT,
	@CustList		VARCHAR(MAX)
 AS
 /*
	Created: Elodie
	Date: 20210824
	Task: Get Protection Mode for EXTNAP
	DB: DBCUST/CustDB
	Revisions:
		- 20210824@Elodie: Initial sp [Redmine: #160151]
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
		- 20240702@Tacy: EXT NAP - Not check Permission on Site/Currency [Redmine: #206918] 

	Parameter's Explanation:

	Example: exec EAS_CustomerSelProtectionModeList_uat2 @GroupName='ACCTEST',@Roleid=2,@UserId=52523910,@CustList='14373897,19989098,54298539,54298542,54298575,54298577,54298578,54298579'

*/ 
BEGIN	
	SET NOCOUNT ON

	DECLARE @CustListTmp TABLE (CustId INT)

	INSERT INTO @CustListTmp (CustId)
	SELECT  value
	FROM STRING_SPLIT (@CustList, ',')
	WHERE value <> ''

	-- check belong to group 
	IF EXISTS (	SELECT 1 
				FROM CustInfo ci WITH (NOLOCK)
					INNER JOIN @CustListTmp t ON t.custid = ci.custid
				WHERE NOT EXISTS (SELECT custid FROM dbo.Acc_CustGroup cg WITH(NOLOCK) WHERE GroupName = @GroupName AND cg.CustID = ci.srecommend))
	BEGIN
		RETURN
	END

	SELECT ci.custid, ci.username, ci.roleid, ISNULL(IsProtectedMode,0) AS IsProtectedMode
	FROM CustLoginInfo cl WITH(NOLOCK)
		INNER JOIN CustInfo ci WITH (NOLOCK) ON cl.custid = ci.custid
		INNER JOIN @CustListTmp t ON ci.custid = t.custid
	WHERE roleid = @Roleid
END
GO
