/*<info serverAlias="DBCUST-CustDB" executers="wsv_xnap,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelUsedCredit_MAg]
	@masterID int
AS
/*
	Created: 
	Task: Get used credit for master 
	DB: DBTRANS.BODB02 
	Original: \account\hMasterUsedCredit.asp

	Revisions:
		- 20210505@Tina: Lock account & indirect close account [redmine: #148600]
		- 20241107@Helios: Offer Direct Member for Super/Master [redmine: #211969]
		- 20250724@Helios: Agency Cash Service -Customer Setting Sprint 7 [redmine: #233474] 
*/
BEGIN
	SET NOCOUNT ON
	SELECT
		c.username			 agentname
	    , ci.credit			 givencredit
	    , ISNULL ( uc.credit , 0 )  + ISNULL ( ac.AccumCredit , 0 ) AS  usedcredit
	FROM Customer c (NOLOCK)
	INNER JOIN custInfo ci ON c.custid = ci.custid
	LEFT OUTER JOIN (
		SELECT recommend , SUM ( credit ) credit
		FROM custInfo ( nolock )
		WHERE mrecommend = @masterID AND roleid = 1 AND recommend NOT IN (-3,-4)
		GROUP BY recommend
	) uc ON c.custid = uc.recommend
	LEFT JOIN (
		SELECT recommend , SUM (AccumCreditReturn ) AccumCredit
		FROM CashAccumCredit WITH (NOLOCK)
		WHERE mrecommend = @masterID 
		GROUP BY recommend
	) ac ON c.custid = uc.recommend
	WHERE c.mrecommend = @masterID AND c.roleid = 2
	ORDER BY c.username
END
