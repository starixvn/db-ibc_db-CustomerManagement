/*<info serverAlias="DBCUST-CustDB" executers="wsv_xnap,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelUsedCredit_SAg]
	@superID int
AS
/*
	Created: 20210505@Tina
	Task: Get used credit for SUPER  
	DB: DBTRANS.BODB02 
	Original: \account\hSuperUsedCredit.asp 

	Revisions:
		- 20210505@Tina: Lock account & indirect close account [redmine: #148600]
		- 20241107@Helios: Offer Direct Member for Super/Master [redmine: #211969] 
*/
BEGIN
	SET NOCOUNT ON

	SELECT
		c.username			 mastername
	    , ci.credit			 givencredit
	    , ISNULL ( uc.credit , 0 ) usedcredit
	FROM Customer c WITH (NOLOCK)
	INNER JOIN custInfo ci ON c.custid = ci.custid
	-- get Master
	LEFT OUTER JOIN (
				SELECT mrecommend , SUM ( credit ) credit
				FROM custInfo WITH (NOLOCK)
				WHERE srecommend = @superID AND ((roleid = 2) OR (roleid = 1 AND recommend = -3))
				GROUP BY mrecommend
		) uc ON c.custid = uc.mrecommend
	WHERE c.srecommend = @superID AND c.roleid = 3
	ORDER BY c.username
END
GO