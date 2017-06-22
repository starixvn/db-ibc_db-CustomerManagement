 ALTER PROCEDURE [dbo].[Acc_CustomerSelInfoByUsername]
	@UserName	VARCHAR(30),
	@CustID		INT =0		OUTPUT,
	@RoleID		TINYINT =0	OUTPUT,
	@Currency	INT = 0		OUTPUT 
AS
/*
Created: 20120306@Jamie
Task : Get CustID, RoleID, Currency by Username FOR all system 
DB: DB06.BODB02
Original:

Revisions:
	
Param's Explanation:
*/
SET NOCOUNT ON
BEGIN
	SELECT @CustID = CustID, @RoleID = roleid, @Currency = currency 
	FROM custinfo WITH(NOLOCK)
	WHERE UserName = @UserName
END


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelInfoByUsername] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelInfoByUsername] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelInfoByUsername] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelInfoByUsername] TO [bodbDownlineNetView]