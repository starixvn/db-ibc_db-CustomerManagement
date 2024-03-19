/*<info serverAlias="DBCUST-IPDB" executers="bodbAdminNet,wsv_nap,bodbDownlineNet,wsv_alp" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_AllowedAccessIPsSel]
AS
	/*
		Created: Louis.Nguyen
		Date: 2018-03-13
		Task: Get office IPs or white list IPs
		DB: DBCust.IPDB 
		
		Revisions: 
			-20180313@Louis: Create [Redmine: 91633]
		
		Parameter's Explanation:
	*/
BEGIN
	SET NOCOUNT ON 
	
	SELECT IP FROM IPOffice WITH (NOLOCK) 	
	UNION
	SELECT IP FROM IPWhiteList WITH (NOLOCK) WHERE IsActive = 1	
END
GO