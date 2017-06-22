ALTER PROCEDURE [dbo].[Acc_SiteSelMoveSite] 
 @System varchar(50) = 'ACCOUNTING',
 @Userid INT=NULL
AS
/*
DB: DB052.BODB02

Revisions:
	- 20100819@Ethan: get Sites by System
	- 20110310@Henry: get active credit sites and licensee sites
	- 20160114@Helen: Cricket - [Redmine: #50027] 
	- 20160620@Winnie: #48948 Hide_special_sites_from_unautorized_users
*/
SET NOCOUNT ON
DECLARE @SearchQuery varchar(1024)
DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
DECLARE @tmpUserid VARCHAR(50)
	
IF(@System = 'ACCOUNTING')
BEGIN
IF @Userid IS NULL
BEGIN
SELECT [siteid], [site],  isLicensee
FROM [Site] with (NOLOCK)
WHERE isActive = 1 AND [site] <> 'IMBC'
ORDER BY isLicensee, [site]
END
ELSE
BEGIN
	SELECT @tmpUserid=CAST(@Userid AS VARCHAR(50))
	SELECT @SearchQuery = 'SELECT * 
	FROM OPENQUERY(DBPOLICY, 
	''SELECT siteid , site,SpecialGroup FROM bodb02.dbo.f_GetDeniedSiteByUser( ''''' + @tmpUserid + ''''')'')'

	INSERT INTO  @tmp (siteid , site,SpecialGroup)
	EXECUTE(@SearchQuery)
	
	SELECT [siteid], [site],  isLicensee
	FROM [Site] with (NOLOCK)
	WHERE isActive = 1 AND [site] <> 'IMBC' AND siteid NOT IN (SELECT siteid FROM @tmp )
	ORDER BY isLicensee, [site]
END
END
ELSE
BEGIN
	SELECT [siteid], [site], isLicensee
	FROM [Site] with (NOLOCK) 
	WHERE 
		siteid in (SELECT siteid FROM dbo.f_SiteBySystem(@System))
		and isActive = 1
		AND [site] <> 'IMBC'
	ORDER BY isLicensee, [site]
END

GO
GRANT EXECUTE ON [dbo].[Acc_SiteSelMoveSite] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_SiteSelMoveSite] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SiteSelMoveSite] TO [vnteam]


