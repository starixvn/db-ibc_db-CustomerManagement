ALTER PROCEDURE [dbo].[Acc_GetCustIdByUsername]
	@custname AS VARCHAR(30)
AS
/*	Created by: Andersh
	Date: 2010-11-04
	Task: Get CustID from Username used in Daily Transaction 
	DB: DB06.BODB02
	
	Revisions:
	- 20120907@Sophia: Grant permission for wsv_xnap
	
*/

BEGIN
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT custid FROM customer with (nolock) WHERE username = @custname
END
GO
GRANT EXECUTE ON [dbo].[Acc_GetCustIdByUsername] TO [bodbAdminNet,wsv_nap]
GO
GRANT EXECUTE ON [dbo].[Acc_GetCustIdByUsername] TO [wsv_xnap]
GO 
GRANT VIEW DEFINITION ON [dbo].[Acc_GetCustIdByUsername] TO [VNTeam]
GO
