/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0" isNested="1"></info>*/
USE CustDB
GO 

ALTER PROCEDURE [dbo].[Age_LoginCheckSiteGroup]
	@SiteGroup	VARCHAR(20) = 'ALL',
	@Site		VARCHAR(20) = '',
	@isAllowed	BIT	= 0 OUTPUT 
AS 
/*
	Created by: Jamie
	Date: 2012-06-27
	Task: Check the Site and Domain ( SiteGroup)
	DB: DBCUST/CustDB

	Revisions:
		- 20130125@Jamie: Uncomment :IF @SiteGroup ='789y' AND @Site='789y'	SELECT	@isAllowed = 1
		- 20170918@Elodie: Add new Alpha site [Redmine: #83219]
		- 20180515@Elodie: Add new EU88 Alpha site [Redmine: #94865]

	Param's Explanation: 
	• @SiteGroup: Check the site and corresponding domain
		+ ALL: All add domains 
		+ 789y: Allow customers of 789y ONLY
		+ Y987: Allow customers of Y987 ONLY
		+ EU88: Allow customers of EU88 ONLY
		+ IBCBET | Others: Allow all customers except 789y and Y987


*/
BEGIN
	SET NOCOUNT ON 
	
	IF @SiteGroup = 'ALL'
	BEGIN
		SELECT	@isAllowed  = 1 
	END
	ELSE IF @SiteGroup IN ('789y','Y987','IBCBET','Others','EU88')
	BEGIN
		IF @SiteGroup ='789y' AND @Site='789y'	SELECT	@isAllowed = 1
		ELSE IF @SiteGroup ='Y987' AND @Site='Y987'	SELECT	@isAllowed = 1		 
		ELSE IF @SiteGroup ='EU88' AND @Site='EU88'	SELECT	@isAllowed = 1	
		ELSE IF @SiteGroup IN ('IBCBET','Others') AND @Site <> '789y' AND @Site <> 'Y987' AND @Site <> 'EU88' SELECT @isAllowed = 1
		ELSE SELECT @isAllowed = 0 			
	END 
	ELSE SELECT	@isAllowed = 0 	

END

