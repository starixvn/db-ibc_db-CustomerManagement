/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" isFunction="0" isNested="1"></info>*/
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
		- 20181219@Andy: Add new CN88 Alpha site [Redmine: #105660]
		- 20200311@Andy: Add new IBCIndo Alpha site [Redmine: #129673]
		- 20221226@Tacy: Alpha/NAP - Split 789y Site [RedmineID: #181596]
		- 20230929@Johnson: Add new sitegroup 777 [redmine: #194591]
		- 20231023@Johnson: Add new sitegroup TH7a5 [redmine: #195550]
	Param's Explanation: 
	• @SiteGroup: Check the site and corresponding domain
		+ ALL: All add domains 
		+ 789y: Allow customers of 789y ONLY
		+ CN88:	Allow customers of CN88 ONLY
		+ IBCIndo: Allow customers of IBCIndo ONLY
		+ IBCBET | Others: Allow all customers except 789y, CN88, IBCIndo
*/
BEGIN
	SET NOCOUNT ON 

	DECLARE @SiteLabel VARCHAR(50)

	SELECT @SiteLabel=SiteLabel
	FROM Site WITH(NOLOCK)
	WHERE site=@Site

	
	IF @SiteGroup = 'ALL'
	BEGIN
		SELECT	@isAllowed  = 1 
	END
	ELSE IF @SiteGroup IN ('789y','IBCBET','Others','CN88','IBCIndo','TH7a5','777')
	BEGIN
		IF		@SiteGroup = '789y'		AND @SiteLabel = '789y'	SELECT @isAllowed = 1
		ELSE IF @SiteGroup = 'CN88'		AND @Site = 'CN88'		SELECT @isAllowed = 1
		ELSE IF @SiteGroup = 'IBCIndo'	AND @Site = 'IBCIndo'	SELECT @isAllowed = 1
		ELSE IF @SiteGroup = 'TH7a5'	AND @Site = '7a5555'	SELECT @isAllowed = 1		
		ELSE IF @SiteGroup = '777'		AND @Site = '777777'	SELECT @isAllowed = 1
		ELSE IF @SiteGroup IN ('IBCBET','Others') AND @SiteLabel <> '789y' AND @Site NOT IN ('CN88','IBCIndo','777777','7a5555') SELECT @isAllowed = 1
		ELSE SELECT @isAllowed = 0 			
	END 
	ELSE SELECT	@isAllowed = 0 	
END