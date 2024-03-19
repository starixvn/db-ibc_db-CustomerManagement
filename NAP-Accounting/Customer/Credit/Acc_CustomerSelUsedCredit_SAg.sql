ALTER PROCEDURE [dbo].[Acc_CustomerSelUsedCredit_SAg]
	@superID int
AS
/*
	Created: 
	Task: Get used credit for SUPER  
	DB: DBTRANS.BODB02 
	Original: \account\hSuperUsedCredit.asp 
*/
SET NOCOUNT ON

SELECT c.username mastername, ci.credit givencredit,
	IsNull(uc.credit,0) usedcredit
FROM customer c (nolock)
	inner join custinfo ci on c.custid = ci.custid
	LEFT OUTER JOIN
		(SELECT mrecommend, SUM(credit) credit
			FROM custinfo (nolock)
		WHERE srecommend = @superID AND roleid = 2
		GROUP BY mrecommend
	) uc ON c.custid = uc.mrecommend
WHERE c.srecommend = @superID AND c.roleid = 3
ORDER BY c.username

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelUsedCredit_SAg] TO [bodbAdminNet,wsv_nap]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelUsedCredit_SAg] TO [bodbExtAccNet,wsv_xnap]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelUsedCredit_SAg] TO [vnteam]