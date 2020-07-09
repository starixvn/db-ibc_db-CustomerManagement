/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerInsMember_Ag_CreditStatusSel]
	@RefCust NVARCHAR(50)
/*
Created: 20200309@Eden
Task :  Get Credit available of new member
DB: DBCUST/CustDB
Original:  
Revisions:
    - 20200309@Eden: Alpha - New function to let new member sign in via QR Code [RM#129373]
	- 20200309@Eden: HotFix MaxCreditMember [RM#137309]
*/

AS
BEGIN
	DECLARE @RefCredit MONEY
			,@AgentID INT
			,@AgentCredit MONEY
			,@Credit_Ag_Bal MONEY
			,@Credit_AllOtherMember MONEY = 0
			,@MaxCredit_Mem MONEY
			,@Status VARCHAR(10)

	SELECT @RefCredit = Credit, 
		   @AgentID = recommend,
		   @Status = CASE	WHEN ci.Closed = 1 OR Enabled = 0 THEN 'Closed'
							WHEN ISNULL(ci.reject, 0) = 1 THEN 'Suspended'
							ELSE 'Open'
						END
	FROM custinfo ci WITH(NOLOCK)
	WHERE username = @RefCust

	SELECT @AgentCredit = Credit
	FROM custinfo WITH(NOLOCK)
	WHERE custID = @AgentID

	SELECT @Credit_AllOtherMember = ISNULL(SUM(Credit), 0) FROM custinfo WITH(NOLOCK) WHERE Recommend = @AgentID AND RoleID = 1
	SELECT @Credit_Ag_Bal = @AgentCredit - ISNULL(@Credit_AllOtherMember,0)
	SELECT @MaxCredit_Mem = isnull(maxcredit,0) from CustAgent WITH (NOLOCK) where CustID = @AgentID

	SELECT @MaxCredit_Mem = CASE WHEN @MaxCredit_Mem = 0 THEN @Credit_Ag_Bal 
								WHEN @MaxCredit_Mem > @Credit_Ag_Bal THEN @Credit_Ag_Bal
							 ELSE @MaxCredit_Mem END 

	SELECT @RefCredit AS RefCredit,
		   @MaxCredit_Mem AS MaxCredit_Mem,
		   0 AS MinCredit_Mem,
		   @Status AS [Status]
END
GO