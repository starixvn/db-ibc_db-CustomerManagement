ALTER PROCEDURE [dbo].[NAP_CustomerSelInfoByUsername]
	@UserName	VARCHAR(30)
AS
/*
Created: 20140911@Jamie
Task : Get CustID, RoleID, Currency by Username FOR all system 
DB: DBACC/BODB02
Original: Acc_CustomerSelInfoByUsername

Revisions:
	
Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	SELECT	 CustID
			,Roleid
			,Currency
	FROM	custinfo WITH (NOLOCK)
	WHERE	UserName = @UserName
END

GO
GRANT EXECUTE ON [dbo].[NAP_CustomerSelInfoByUsername] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_CustomerSelInfoByUsername] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[NAP_CustomerSelInfoByUsername] TO [bodbDownlineNetView]