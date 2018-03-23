/*<info serverAlias="DBCUST-IPDB" executers="bodbAdminNet,bodbDownlineNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [IPDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE Age_AllowedAccessIPsSel
AS
	/*
		Created: Louis.Nguyen
		Date: 2018-03-13
		Task: Get office IPs or white list IPs
		DB: DBCust.IPDB 
		
		Revisions:
		
		Parameter's Explanation:
	*/
BEGIN
	SET NOCOUNT ON 
	
	SELECT IP FROM IPOffice WITH (NOLOCK) 	
	UNION
	SELECT IP FROM IPWhiteList WITH (NOLOCK) WHERE IsActive = 1	
END
GO