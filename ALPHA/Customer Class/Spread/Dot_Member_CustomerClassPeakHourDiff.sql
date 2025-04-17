/*<info serverAlias="DBCUST-CUSTDB" executers="Dot_Admin,svc_tig" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Dot_Member_CustomerClassPeakHourDiff] 
	@Platform TINYINT = 0,
	@IsTest BIT = 0,
    @Islive BIT = 0,
    @IsLicensee BIT = 0,
	@RepUpdateTime DATETIME2 = NULL,
	@RowNum BIGINT = 0,
	@maxRecords INT = 1
AS
/*
	Created: Winfred
	Date: 20250416
	Task : [NAP CM] Customer Class - SP Integrate [#186118]
	DB: DBCUST/CustDB

	Revisions:
		- 20250416@Winfred: Customer Class - Add Peak Hour Spread setting - Get Push Node and RefData [Redmine: #186118]

	Param's Explanation:
	Example: Dot_Member_CustomerClassPeakHourDiff @PolicyID = 51, @Platform = 2, @IsTest = 0, @Islive=0, @IsLicensee = 0, @RepUpdateTime = '2025-02-24 23:09:04.0526651' , @RowNum = 0, @maxRecords = 500
	
*/ 
BEGIN
	SET NOCOUNT ON;
	DECLARE @ModeTest BIT, @NewSiteID INT

	IF 	@IsLicensee = 0
	BEGIN
		SELECT @NewSiteID = -1 --'AllCredit'
	END
	ELSE
	BEGIN
		SELECT @NewSiteID = -2 --'AllDeposit'
	END

	SELECT @ModeTest = [dbo].[f_GetModeCustomerClassPeakHour]()

	IF @IsTest = 1
	BEGIN
		SELECT @IsTest = dbo.f_CheckSPVersion(@@PROCID)
	END
	IF @ModeTest = 1 
	BEGIN
		SELECT PolicyID, [Action], RepUpdateTime
		FROM (
			SELECT PolicyID, CAST('NEW' AS VARCHAR(10)) AS [Action], RepUpdateTime
			FROM CustomerClassSpread_UAT WITH(NOLOCK)
			WHERE (@RepUpdateTime IS NULL OR RepUpdateTime >= @RepUpdateTime) AND IsTest = @IsTest AND Enable = 1 AND Type = 2
			UNION
			SELECT PolicyID, CAST('DELETE' AS VARCHAR(10)) AS [Action], RepUpdateTime
			FROM CustomerClassSpread_UAT_Del_InHouse WITH(NOLOCK)
			WHERE @RepUpdateTime IS NOT NULL AND RepUpdateTime >= @RepUpdateTime
			UNION
			SELECT PolicyID, CAST('DELETE' AS VARCHAR(10)) AS [Action], RepUpdateTime
			FROM CustomerClassSpread_UAT WITH(NOLOCK)
			WHERE @RepUpdateTime IS NOT NULL AND RepUpdateTime >= @RepUpdateTime AND IsTest = @IsTest AND Enable = 0 AND Type = 2
			) CCS
		ORDER BY RepUpdateTime

		IF @RepUpdateTime IS NOT NULL
		BEGIN
			SELECT TOP (@maxRecords) cs.PolicyID, cc.CustomerClass, cd.SiteID, cd.Currency, cd.[Platform], cd.SportType, cl.LeagueGroupID, cs.Spread, cs.IsLive, 
				cs.RepUpdateTime,
				(CAST(cs.PolicyID AS BIGINT) * 1000000000 + cl.ID * 1000000 + cc.ID * 1000 + cd.ID) AS RowNum
			FROM CustomerClassSpread_UAT cs WITH(NOLOCK)
				CROSS APPLY (SELECT LeagueGroupID, ID FROM CustomerClassSpreadLeagueGroup_UAT WITH(NOLOCK) WHERE PolicyID = cs.PolicyID) cl
				CROSS APPLY (SELECT CustomerClass, ID FROM CustomerClassSpreadClass_UAT WITH(NOLOCK) WHERE PolicyID = cs.PolicyID) cc
				CROSS APPLY (SELECT d.SiteID, Currency, [Platform], SportType, ID  
							 FROM CustomerClassSpreadDetail_UAT d WITH(NOLOCK) 
								CROSS APPLY (SELECT TOP 1 isLicensee FROM Site WITH(NOLOCK) WHERE siteid = d.SiteID) s 
							 WHERE PolicyID = cs.PolicyID AND s.isLicensee = @IsLicensee AND [Platform] IN (0, @Platform) 
							 UNION 
							 SELECT d.SiteID, Currency, [Platform], SportType, ID  
							 FROM CustomerClassSpreadDetail_UAT d WITH(NOLOCK) 
							 WHERE PolicyID = cs.PolicyID AND d.SiteID IN (0, @NewSiteID) AND [Platform] IN (0, @Platform)) cd
			WHERE cs.RepUpdateTime >= CAST(@RepUpdateTime  as datetime2)
				AND cs.IsTest = @IsTest
				AND cs.IsLive IN (2, @Islive) 
				AND cs.Enable = 1 
				AND cs.Type = 2 
				AND (CAST(cs.PolicyID AS BIGINT) * 1000000000 + cl.ID * 1000000 + cc.ID * 1000 + cd.ID) > @RowNum
			ORDER BY cs.RepUpdateTime, RowNum
		END
	END
	ELSE
	BEGIN
		SELECT PolicyID, [Action], RepUpdateTime
		FROM (
			SELECT PolicyID, CAST('NEW' AS VARCHAR(10)) AS [Action], RepUpdateTime
			FROM CustomerClassSpread WITH(NOLOCK)
			WHERE (@RepUpdateTime IS NULL OR RepUpdateTime >= @RepUpdateTime) AND IsTest = @IsTest AND Enable = 1 AND Type = 2
			UNION
			SELECT PolicyID, CAST('DELETE' AS VARCHAR(10)) AS [Action], RepUpdateTime
			FROM CustomerClassSpread_Del_InHouse WITH(NOLOCK)
			WHERE @RepUpdateTime IS NOT NULL AND RepUpdateTime >= @RepUpdateTime
			UNION
			SELECT PolicyID, CAST('DELETE' AS VARCHAR(10)) AS [Action], RepUpdateTime
			FROM CustomerClassSpread WITH(NOLOCK)
			WHERE @RepUpdateTime IS NOT NULL AND RepUpdateTime >= @RepUpdateTime AND IsTest = @IsTest AND Enable = 0 AND Type = 2
			) CCS
		ORDER BY RepUpdateTime

		IF @RepUpdateTime IS NOT NULL
		BEGIN
			SELECT TOP (@maxRecords) cs.PolicyID, cc.CustomerClass, cd.SiteID, cd.Currency, cd.[Platform], cd.SportType, cl.LeagueGroupID, cs.Spread, cs.IsLive, 
				cs.RepUpdateTime,
				(CAST(cs.PolicyID AS BIGINT) * 1000000000 + cl.ID * 1000000 + cc.ID * 1000 + cd.ID) AS RowNum
			FROM CustomerClassSpread cs WITH(NOLOCK)
				CROSS APPLY (SELECT LeagueGroupID, ID FROM CustomerClassSpreadLeagueGroup WITH(NOLOCK) WHERE PolicyID = cs.PolicyID) cl
				CROSS APPLY (SELECT CustomerClass, ID FROM CustomerClassSpreadClass WITH(NOLOCK) WHERE PolicyID = cs.PolicyID) cc
				CROSS APPLY (SELECT d.SiteID, Currency, [Platform], SportType, ID  
							 FROM CustomerClassSpreadDetail d WITH(NOLOCK) 
								CROSS APPLY (SELECT TOP 1 isLicensee FROM Site WITH(NOLOCK) WHERE siteid = d.SiteID) s 
							 WHERE PolicyID = cs.PolicyID AND s.isLicensee = @IsLicensee AND [Platform] IN (0, @Platform) 
							 UNION 
							 SELECT d.SiteID, Currency, [Platform], SportType, ID  
							 FROM CustomerClassSpreadDetail d WITH(NOLOCK) 
							 WHERE PolicyID = cs.PolicyID AND d.SiteID IN (0, @NewSiteID) AND [Platform] IN (0, @Platform)
									) cd
			WHERE cs.RepUpdateTime >= CAST(@RepUpdateTime  as datetime2)
				AND cs.IsTest = @IsTest
				AND cs.IsLive IN (2, @Islive) 
				AND cs.Enable = 1 
				AND cs.Type = 2 
				AND (CAST(cs.PolicyID AS BIGINT) * 1000000000 + cl.ID * 1000000 + cc.ID * 1000 + cd.ID) > @RowNum
			ORDER BY cs.RepUpdateTime, RowNum
		END
	END
END