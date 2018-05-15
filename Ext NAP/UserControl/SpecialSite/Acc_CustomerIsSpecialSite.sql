/*<info serverAlias="DBPOLICY-bodb02" executers="bodbAdminNet,bodbExtAccNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE bodb02
GO 

ALTER PROCEDURE [dbo].[Acc_CustomerIsSpecialSite]
	@UserName VARCHAR(30),
	@CheckCustId TINYINT = 0,	
	@IsSpecialSite BIT = 0 OUTPUT,
	@IsSpecialHeadline BIT = 0 OUTPUT,
	@SiteCode TINYINT = 1 OUTPUT
AS
/*
	Created: 20160901@Elodie
	Task: check if the customer belongs to special site
	Database: DBPOLICY/bodb02
	
	Revision:
		- 20161031@Elodie: Change a type of parameter Username NVARCHAR(30) - > VARCHAR(30) 
		- 20161111@Elodie: Check more member of group headline
		- 20161201@Elodie: Output more @IsSpecialHeadline [RedmineID: #66873]
		- 20170918@Elodie: Output more @SiteCode [RedmineID: #83219]
		- 20171107@Vicky: Support to search customer id on Left panel [RedmineID: #86134]
		- 20180130@Elodie: Get @SiteCode value of customer instead of Group Headline [RedmineID: #90192]
		- 20180515@Elodie: Add new EU88 Alpha site [Redmine: #94865]

	Param's Explanation:
		1. NAP & ExtNAP: search left panel -> If (@IsSpecialSite = 1 OR @IsSpecialHeadline = 1) AND admin have special site permission then show customer on left panel, else then show access denied
		2. Alpha: Consolidation report -> bet list -> show NG2 ticket if @IsSpecialHeadline of login SMA = 1 (only check on link i1; i7 & i9 default show NG2 ticket)
		3. SiteCode: Use to define link i1, i7, Eu88 or i9 when internal ALPHA site
	Example query:
		DECLARE @IsSpecialSite BIT = 0,
				@IsSpecialHeadline BIT = 0,
				@SiteCode TINYINT = 1,
				@CheckCustId TINYINT = 0

		EXEC Acc_CustomerIsSpecialSite @UserName = 'supertestY987', @IsSpecialHeadline = @IsSpecialHeadline OUTPUT, @IsSpecialSite = @IsSpecialSite OUTPUT, @SiteCode = @SiteCode OUTPUT

		SELECT @SiteCode, @IsSpecialSite, @IsSpecialHeadline

*/
BEGIN
	SET NOCOUNT ON

	SELECT @IsSpecialSite = 0, @IsSpecialHeadline = 0
	DECLARE @CustID INT, @RoleID TINYINT, @recommend INT, @site NVARCHAR(50), @GroupID SMALLINT = NULL

	EXEC @CustID = DBACC.bodb02.dbo.f_GetCustIDFromUsernameOrCustId @UserName,@CheckCustId
	IF @CustID IS NULL 
		RETURN
	SELECT @RoleID = roleID, @recommend = recommend, @site = Site FROM customer WITH (NOLOCK) WHERE custid = @CustID

	SELECT @GroupID = groupID FROM dbo.custAccount WITH (NOLOCK) WHERE custid = @CustID AND IsGroupHeadLine = 1

	--check if customer is special site
	IF @RoleID = 1
	BEGIN
		SELECT @site = NULL

		SELECT @site = c.site 
		FROM dbo.Customer c WITH (NOLOCK)
			INNER JOIN dbo.Site s WITH (NOLOCK) ON c.site = s.site
		WHERE c.custid = @recommend AND s.SpecialGroup = 1

		IF @site IS NOT NULL 
		BEGIN
			SELECT @IsSpecialSite = 1			
		END
	END
	ELSE
	BEGIN
		IF EXISTS (	SELECT 1 
					FROM dbo.Site s WITH (NOLOCK)
					WHERE s.site = @site AND s.SpecialGroup = 1)
		BEGIN
			SELECT @IsSpecialSite = 1			
		END
	END

	IF @site = 'Y987'
		SELECT @SiteCode = 9
	ELSE IF @site = '789y'
		SELECT @SiteCode = 7
	ELSE IF @site = 'EU88'
		SELECT @SiteCode = 8
	ELSE 
		SELECT @SiteCode = 1

	--Check Special Headline
	IF @GroupID IS NOT NULL -- Headline
	BEGIN
		SELECT custid
		INTO #tmpCustGroup
		FROM dbo.custAccount WITH(NOLOCK) 
		WHERE groupID = @GroupID

		IF EXISTS ( SELECT 1
					FROM #tmpCustGroup cg
						INNER JOIN dbo.customer c WITH (NOLOCK) ON cg.custid = c.custid
						INNER JOIN dbo.site s WITH (NOLOCK) ON s.site = c.site
					WHERE SpecialGroup = 1 AND c.roleid BETWEEN 2 AND 4)
			OR EXISTS (	SELECT 1
						FROM #tmpCustGroup cg
							INNER JOIN dbo.customer c WITH (NOLOCK) ON cg.custid = c.custid
							INNER JOIN dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid
							INNER JOIN dbo.site s WITH (NOLOCK) ON s.site = ag.site
						WHERE SpecialGroup = 1 AND c.roleid = 1)
			SELECT @IsSpecialHeadline = 1
	END
END
GO

