ALTER PROCEDURE [dbo].[Acc_CustomerSelUsedCredit_MAg]
	@masterID int
AS
/*
	Created: 
	Task: Get used credit for master 
	DB: DBTRANS.BODB02 
	Original: \account\hMasterUsedCredit.asp
*/
SET NOCOUNT ON

SELECT c.username agentname, ci.credit givencredit,
	IsNull(uc.credit,0) usedcredit
FROM customer c (nolock)
	inner join custinfo ci on c.custid = ci.custid
	LEFT OUTER JOIN
		(SELECT recommend, SUM(credit) credit
			FROM custinfo (nolock)
		WHERE mrecommend = @masterID AND roleid = 1
		GROUP BY recommend
	) uc ON c.custid = uc.recommend
WHERE c.mrecommend = @masterID AND c.roleid = 2
ORDER BY c.username

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelUsedCredit_MAg] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelUsedCredit_MAg] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelUsedCredit_MAg] TO [vnteam]