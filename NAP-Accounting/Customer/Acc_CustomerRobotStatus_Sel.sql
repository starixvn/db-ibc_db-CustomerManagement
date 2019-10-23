/*<info serverAlias="DBONUSER-ON_USER" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerRobotStatus_Sel]
	@username VARCHAR(30),
	@isRobot BIT = 0 OUTPUT
AS
/*
	Created: 20190916@Johnson
	Task : check customer is robot or not
	DB: DBONUSER/ON_USER

	Revisions:
		- 20190916@Johnson: initial sp [redmine:#119714]	
*/	
BEGIN
	SET NOCOUNT ON
	
	DECLARE @custid INT
	
	SELECT @custid = custid
	FROM bodb02.dbo.customer WITH(NOLOCK)
	WHERE username = @username
	
	IF @@rowcount =0
		RETURN;
	
	IF EXISTS (SELECT 1 FROM RobotUsers WITH(NOLOCK) WHERE custid = @custid)
		SELECT @isRobot = 1
	ELSE 
		SELECT @isRobot = 0
	
END
GO