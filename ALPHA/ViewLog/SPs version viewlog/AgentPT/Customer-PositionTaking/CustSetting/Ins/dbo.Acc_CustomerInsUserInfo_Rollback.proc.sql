ALTER PROCEDURE [dbo].[Acc_CustomerInsUserInfo_Rollback]
	@CustID int
AS
--Rollback data for invalid insert

Declare @RoleID tinyint
SELECT @RoleID = RoleID FROM CustInfo (nolock) WHERE CustID = @CustID

DELETE FROM custinfo WHERE custid = @CustID
DELETE FROM customer WHERE CustID = @CustID
IF @RoleID = 4
	DELETE FROM CustSuper WHERE CustID = @CustID
ELSE IF @RoleID = 3
	DELETE FROM CustMaster WHERE CustID = @CustID
ELSE IF @RoleID = 2
	DELETE FROM CustAgent WHERE CustID = @CustID
		

GO
GRANT EXECUTE ON [Acc_CustomerInsUserInfo_Rollback] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [Acc_CustomerInsUserInfo_Rollback] TO [bodbAdminNet]
