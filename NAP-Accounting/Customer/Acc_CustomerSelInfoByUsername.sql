/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,wsv_nap,bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv,bodbExtAccNet,wsv_xnap,wsv_lap" viewers="" isFunction="0" isNested="0"></info>*/
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
	- 20230510@Eden: Scale out DBTRANS for Credit [Redmine: #181595]
Param's Explanation:
*/
SET NOCOUNT ON
BEGIN
	SELECT @CustID = CustID, @RoleID = roleid, @Currency = currency 
	FROM custinfo WITH(NOLOCK)
	WHERE UserName = @UserName
END
GO
