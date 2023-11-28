/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,bodbExtAccNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROC [Acc_SiteSel_Credit]
	@UserID INT = 0,
	@Mode INT = 0
AS

/*
Created by: Scott
Date: 2012-11-20
Task : GET active CREDIT sites
DB: DB053.BODB02
Original SP: [Acc_SiteSel] 
Revisions:
	Parameter's explaination: @Mode  = 0: No sites CN88 and isActive = 1
									 = 1: All Site
	 - 20190528@Winnie: NAP - Support CN88 Headline RedmineID: #112999
	 - 20200629@Winfred: NAP - Get site by cansee RedmineID: #131241	 
	 - 20221808@Elodie: Get SiteDBGroupID [RedmineID: #158293]
	 - 20230110@Tacy: Alpha/NAP - Split 789y Site [RedmineID: #181596]
	 - 20231206@Johnson: check permission by UserID [RedmineID: #197160]
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @tmp TABLE (siteid INT, site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpUserid VARCHAR(50)
	DECLARE @SearchQuery varchar(MAX)
	
	IF @UserID > 0
	BEGIN
		SELECT @tmpUserid = CAST(@Userid AS VARCHAR(50))
		SELECT @SearchQuery = 'SELECT * 
		FROM OPENQUERY(DBPOL, 
		''SELECT siteid , site, SpecialGroup FROM NAP_UserControl.dbo.f_GetDeniedSiteByUser( ''''' + @tmpUserid + ''''')'')'

		INSERT INTO  @tmp (siteid, site, SpecialGroup)
		EXECUTE(@SearchQuery)
	END
	
	SELECT SiteLabel, [siteid], [site] 
	FROM [site]  WITH(NOLOCK)
	WHERE islicensee = 0  
		AND ((@Mode = 1 AND isactive=1) 
			OR (@Mode = 0 AND isactive=1 AND [siteid]<>329)
			)
		AND SiteID NOT IN (SELECT SiteID FROM @tmp)	
END
GO
