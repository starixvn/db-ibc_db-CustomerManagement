/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Age_CashService_AgentBankAccountLimit_Sel
	@CustID		INT,			-- SMA_ID Input
	@ModeView		BIT = 0
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Get daily withdrawal count [Redmine #223896]
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896] 

	Param:
		exec Age_CashService_AgentBankAccountLimit_Sel @CustID =  1176086

	@ModeView : 
		0 = View by Tab PaymentGateway
		1 = View by Tab BankAccount

*/  
BEGIN
	SET NOCOUNT ON;

	IF @ModeView = 1 
	BEGIN
			SELECT 
			      0 AS TransType,
				ctl.MinPerDeposit AS MinPer,
				ctl.MaxPerDeposit AS MaxPer
			FROM CashAgentBankAccountLimit ctl WITH (NOLOCK)
			WHERE ctl.AgentID = @CustID
			UNION ALL
			SELECT
				1 AS TransType,
				ctl.MinPerWithdrawal AS MinPer,
				ctl.MaxPerWithdrawal AS MaxPer
			FROM CashAgentBankAccountLimit ctl WITH (NOLOCK)
			WHERE ctl.AgentID = @CustID

		
	END
	
	SELECT ctl.DailyWithdrawalCount AS WDLimit
	FROM CashAgentManagement ctl WITH (NOLOCK)
	WHERE ctl.AgentID = @CustID


	
END
