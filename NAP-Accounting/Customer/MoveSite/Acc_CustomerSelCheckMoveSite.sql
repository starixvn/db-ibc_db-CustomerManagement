/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelCheckMoveSite]
	@CustId			INT,
	@UserId			INT,
	@IsAllow		BIT OUTPUT,
	@RoleId			INT OUTPUT
AS
/*	Created by: [Khoa]
	Date: 20091224
	Task: Check the customer allow to move site or not
	DB: DBAGE/bodb02

	Revisions:		
		- 20130121@Dan: change linked server DB03 to DBPOLICY
		- 20180808@Helen: GET CODE FROM PRODUCTION + DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462] 
			
	Param's Explanation:
		@CustID: Custid of customer want to move site. We do not allow Member move site

*/
SET NOCOUNT ON 
BEGIN
	SELECT @IsAllow = 0, @RoleId = 0

	--Check permission for account site: @phuc20080213
	DECLARE @ErrCode int, @ErrMsg varchar(200)
	EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[MoveSite]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
	
	SELECT @RoleId = ISNULL(roleid,0) FROM custinfo (NOLOCK) WHERE custid=@CustId	
	
	IF @RoleId IN(4,3,2) -- for Super, Master , Agent
		SELECT @IsAllow = 1		
END
GO


