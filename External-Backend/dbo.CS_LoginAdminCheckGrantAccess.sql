/*<info serverAlias="DBCUST-IPDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[CS_LoginAdminCheckGrantAccess]
	@username VARCHAR(50),
	@LoginIP	varchar(15),
	@isAccess	BIT = 0 OUTPUT
AS
	/*
		Created: Razor
		Date: 2019-09-05
		Task: Check admins login from office
		DB: DBCust/IPDB
		
		Revisions:
			- 20190905@Razor: Init (Readmine: #119017)
		
		Parameter's Explanation:
	*/ 
	SET NOCOUNT ON
	IF @username NOT IN ('QA_starix101','fn001','fn002','cs001','cs002')
	BEGIN
		SELECT @isAccess = 1
		RETURN
	END
	
	IF EXISTS (SELECT 1 FROM IPOffice WITH(NOLOCK) WHERE IP = @LoginIP)
	BEGIN
		SELECT @IsAccess = 1
	END
	ELSE
	BEGIN
		SELECT @IsAccess = 0
	END 
