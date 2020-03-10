/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerInsMember_Ag_CreditSel]
	@RefCustID INT
/*
Created: 20200309@Eden
Task :  Get Credit available of new member
DB: DBCUST/CustDB
Original:  
Revisions:
    - 20200309@Eden: Alpha - New function to let new member sign in via QR Code [RM#129373]
*/

AS
BEGIN
	DECLARE @RefCredit MONEY
			,@AgentID INT
			,@AgentCredit MONEY
			,@Credit_AllOtherMember MONEY = 0
			,@MaxCredit_Mem MONEY

	SELECT @RefCredit = Credit, 
		   @AgentID = recommend
	FROM custinfo WITH(NOLOCK)
	WHERE custID = @RefCustID

	SELECT @AgentCredit = Credit
	FROM custinfo WITH(NOLOCK)
	WHERE custID = @AgentID

	SELECT @Credit_AllOtherMember = ISNULL(SUM(Credit), 0) FROM custinfo WITH(NOLOCK) WHERE Recommend = @AgentID AND RoleID = 1

	SELECT @MaxCredit_Mem = @AgentCredit - ISNULL(@Credit_AllOtherMember,0)

	SELECT @RefCredit AS RefCredit,
		   @MaxCredit_Mem AS MaxCredit_Mem,
		   0 AS MinCredit_Mem
END
GO