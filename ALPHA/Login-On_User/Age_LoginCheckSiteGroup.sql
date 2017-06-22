ALTER PROCEDURE [dbo].[Age_LoginCheckSiteGroup]
@SiteGroup	VARCHAR(20) = 'ALL',
@Site		VARCHAR(20) = '',
@isAllowed	BIT	= 0 OUTPUT 
AS 
/*
	Created by: Jamie
	Date: 2012-06-27
	Task: Check the Site and Domain ( SiteGroup)
	DB: DBTRANS/BODB02

	Revisions:
		- 20130125@Jamie: Uncomment :IF @SiteGroup ='789y' AND @Site='789y'	SELECT	@isAllowed = 1

	Param's Explanation: 
	• @SiteGroup: Check the site and corresponding domain
		+ ALL: All add domains 
		+ 789y: Allow customers of 789y ONLY
		+ IBCBET | Others: Allow all customers except 789y


*/
BEGIN
	SET NOCOUNT ON 
	
	IF @SiteGroup = 'ALL'
	BEGIN
		SELECT	@isAllowed  = 1 
	END
	ELSE IF @SiteGroup IN ('789y','IBCBET','Others')
	BEGIN
		IF @SiteGroup ='789y' AND @Site='789y'	SELECT	@isAllowed = 1
		 --IF @site = '789y' SELECT @isAllowed = 1
		ELSE IF @SiteGroup IN ('IBCBET','Others') AND @Site <> '789y' SELECT @isAllowed = 1
		ELSE SELECT @isAllowed = 0 			
	END 
	ELSE SELECT	@isAllowed = 0 	

END
GO
GRANT EXECUTE ON [dbo].[Age_LoginCheckSiteGroup] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_LoginCheckSiteGroup] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_LoginCheckSiteGroup] TO [vnteam] AS [dbo]