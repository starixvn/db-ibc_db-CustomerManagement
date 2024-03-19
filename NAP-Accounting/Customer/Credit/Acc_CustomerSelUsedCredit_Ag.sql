/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap,bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelUsedCredit_Ag]
	@agentID int
AS
/*	Created by: 
	Task: Get Used Credit for agent 
	DB: DBCUST.CustDB 
	Original: \account\hAgentUsedCredit.asp

	Revisions: 
		- 20210505@Tina: Lock account & indirect close account [redmine: #148600]
	
*/
BEGIN
SET NOCOUNT ON

DECLARE @IsDeposit BIT = 0

SELECT @IsDeposit = 1
FROM Customer c WITH (NOLOCK)
	INNER JOIN Dep_CustSuper DS WITH (NOLOCK) ON c.srecommend = DS.custid
WHERE C.custid = @agentID

IF @IsDeposit = 1
BEGIN
	SELECT c.username, c.firstname, c.lastname, ci.credit, ci.closed
	FROM customer c WITH (NOLOCK)
		inner join custInfo ci WITH (NOLOCK) on c.custid = ci.custid
	WHERE c.recommend = @agentID
		AND c.roleid = 1
	ORDER BY
		ci.closed ASC, 
		c.Username
END
ELSE
BEGIN
	SELECT c.username, c.firstname, c.lastname, ci.credit, CASE WHEN cps.CloseInfo > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END closed
	FROM customer c WITH (NOLOCK)
		INNER JOIN custInfo ci WITH (NOLOCK) ON c.custid = ci.custid
		INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = c.custid
	WHERE c.recommend = @agentID
		AND c.roleid = 1
	ORDER BY
		CASE WHEN cps.CloseInfo > 0 THEN 1 ELSE 0 END ASC, 
		c.Username
END

END
GO
