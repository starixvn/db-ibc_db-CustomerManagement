ALTER PROCEDURE [dbo].[Acc_ExchangeRateSelMailList]
	
AS
/*
	Created by: []
	Task: Get email list from DB 
	DB: DB03.BODB02 
	
	Revisions: 
		- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
*/
	SET NOCOUNT ON
	DECLARE @funcid_MinMax int 

	SELECT @funcid_MinMax = funcid FROM acc_functioninfo WITH (NOLOCK)
	WHERE funcName ='[MinMaxExRate]' and system='ACCOUNTING'

	SELECT email FROM AccCustomer_1 ac WITH (NOLOCK)
		INNER JOIN Customer c WITH (NOLOCK) ON ac.custid = c.custid 
		LEFT JOIN Acc_MemberPolicy_1 am WITH (NOLOCK) ON ac.custid = am.custid and am.funcid = @funcid_MinMax
		LEFT JOIN Acc_GroupPolicy_1 ag WITH (NOLOCK) ON ac.groupid = ag.groupid and ag.funcid = @funcid_MinMax
	WHERE am.policy > 0 OR ag.policy > 0 

GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeRateSelMailList] TO [bodbAdminNet]	
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeRateSelMailList] TO [VNTeam]	
GO