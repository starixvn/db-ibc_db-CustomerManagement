/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbdownlineNet,bodbdownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Age_CustomerSelSuspendInfo
	@custid int,
	@RoleID TINYINT
AS
/*
	Created by: Elodie
	Date:[]
	Task: Customer List get suspend info
	DB: DBCUST/CustDB
	
	Revisions:	
		- 20210616@Elodie: apply color for suspend account [RedmineID: #157050]	
*/
BEGIN
	SET NOCOUNT ON

	IF @roleid = 2
	BEGIN		
		SELECT c.custid, cl.SuspendInfo
		FROM custinfo c WITH (NOLOCK)
			INNER JOIN CustProductStatus cl WITH(NOLOCK) ON c.custid = cl.CustID
		WHERE ((c.roleid = 1 AND c.recommend = @custid) OR c.custid = @custid) AND cl.SuspendInfo <> 0
	END
	ELSE IF @roleid = 3
	BEGIN
		SELECT c.custid, cl.SuspendInfo
		FROM custinfo c WITH (NOLOCK)
			INNER JOIN CustProductStatus cl WITH(NOLOCK) ON c.custid = cl.CustID
		WHERE ((c.roleid = 1 AND c.recommend = @custid) OR (c.roleid = 2 AND c.mrecommend = @custid)) AND cl.SuspendInfo <> 0
	END
	ELSE IF @roleid = 4
	BEGIN
		SELECT c.custid, cl.SuspendInfo
		FROM custinfo c WITH (NOLOCK)
			INNER JOIN CustProductStatus cl WITH(NOLOCK) ON c.custid = cl.CustID
		WHERE ((c.roleid = 1 AND c.recommend = @custid) OR (c.roleid IN (2,3) AND c.srecommend = @custid)) AND cl.SuspendInfo <> 0
	END
END

GO
