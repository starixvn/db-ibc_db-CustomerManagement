USE [bodb02]
GO
Create Procedure [dbo].[Acc_CustomerSelDisableOutRight]
	@CustID int
AS
SET NOCOUNT ON
/*
Created: 
Task : Get status DisableOutright by custid
DB: DB05.bodb02
Original: Accounting site

Revisions:
	- 20090729@Simon: Get customer DisableOutright status
Param's Explanation:
	@CustID: id of customer
*/		
Select isnull(DisableOutright,0) as DisableOutright
From custinfo with (nolock)
Where CustID = @CustID

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelDisableOutRight] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelDisableOutRight] TO [vnteam]

