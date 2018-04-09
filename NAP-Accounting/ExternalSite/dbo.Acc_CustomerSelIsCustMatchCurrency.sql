ALTER PROCEDURE [dbo].[Acc_CustomerSelIsCustMatchCurrency]
	-- Add the parameters for the stored procedure here
	@CustId INT,
	@Currency INT
AS
/* =============================================
--	Task : IRP#411
--	DB: DB05.bodb02
--  Description: Select boolean value from  comparing user's currency with input param currency
--	Revisions:
--	- 20100521@Lewin:  Created
    =============================================*/
BEGIN
	SET NOCOUNT ON;
	SELECT dbo.f_IsMatchCustCurrency(@CustId, @Currency)
END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelIsCustMatchCurrency] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelIsCustMatchCurrency] TO [vnteam]

