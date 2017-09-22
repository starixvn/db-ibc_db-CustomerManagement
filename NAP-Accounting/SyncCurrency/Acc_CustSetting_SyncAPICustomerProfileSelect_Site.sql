USE [CustDB]
GO
ALTER PROCEDURE [dbo].[Acc_CustSetting_SyncAPICustomerProfileSelect_Site]
	@RoleID		TINYINT			= NULL,
	@UplineID	INT				= NULL,
	@Site		VARCHAR(10)		='789y',
	@MaxCustID	INT				= 23570555, ---	SIT & UAT Test-- Synchronized by API 
	@isTest		BIT				= 1 
AS 
	/*
		Created by: Jamie@20161101
		Task: Getting the list of customers' profile [RedmineID:#65873 ]
		DB: DBCUST.[CustDB] 

		ExchangeID IN (
						 3		--US$
						,16		--Yen
						,17		--NTD
						,20		--UUS
						,35		--$US
						,40		--IRR
						,64		--UT
					)

		CreateAccount (UplineID,Level,CurrencyID, SiteID,CustID)

		Business Closed Agent List 
		71852	,--	AE13
		74139	,--	AE17
		105400	,--	BEE01
		106103	,--	BEE49
		108322	,--	AE151
		116494	,--	AE175
		127141	,--	AE183
		127142	,--	AE184
		127143	,--	AE185
		142400	,--	AE189
		142401	,--	AE190
		142402	,--	AE191
		142403	,--	AE192
		142404	,--	AE193
		142406	,--	AE194
		142408	,--	AE195
		142409	,--	AE196
		142410	,--	AE197
		142411	,--	AE198

		Business Closed Master List 
		6525	,--	MVN
		14396	,--	AE
		1276306	,--	M922U

	Param's Explanation: 
	@UplineID: 
		+ NULL: Get current level by RoleID 
		+ NOT NULL: Get customers' RoleID under UplineID 
			
		EXEC Acc_CustSetting_SyncAPICustomerProfileSelect_Site	
			@RoleID = 4
	*/
BEGIN	
	SET NOCOUNT ON 

	--DECLARE @tmpCurrList TABLE(
	--	Currency	INT PRIMARY KEY
	--)

	--INSERT INTO @tmpCurrList(Currency)
	--SELECT				3		--US$
	--UNION ALL SELECT	16		--Yen
	--UNION ALL SELECT	17		--NTD
	--UNION ALL SELECT	20		--UUS
	--UNION ALL SELECT	35		--$US
	--UNION ALL SELECT	40		--IRR
	--UNION ALL SELECT	64		--UT
	
	DECLARE @tmpCurrList TABLE(
		Currency		INT PRIMARY KEY
		,CurrencyNAME	NVARCHAR(50)
		,ActualRate		FLOAT 
	)

	INSERT INTO @tmpCurrList(Currency,CurrencyNAME,ActualRate)
	EXEC [Acc_ExchangeSel_Sync_NG2]

	----UPLINE: SUPER LEVEL , MASTER AND AGENT 
	--IF @RoleID BETWEEN 1 AND 3 AND @UplineID IS NOT NULL  --Get customers under a specific upline
	--BEGIN
	--	SELECT   CASE ci.RoleID WHEN 4 THEN ci.CustID 
	--							WHEN 3 THEN ci.srecommend
	--							WHEN 2 THEN ci.mrecommend
	--							WHEN 1 THEN ci.recommend
	--							ELSE 0 END AS UplineID  --- = SuperID 
	--			,c.roleID As [Level]
	--			,ci.currency AS CurrencyID
	--			,CASE WHEN @RoleID = 1 THEN 4100300 ELSE 0 END AS SiteID
	--			,ci.CustID
	--			,ci.Username
	--	FROM	Customer c WITH (NOLOCK)
	--			INNER JOIN custInfo ci WITH (NOLOCK) ON c.custid = ci.custid
	--			--INNER JOIN dbo.CustProductStatus cps  WITH (NOLOCK) ON ci.CustID = cps.CustID 
	--	WHERE	--c.Site = @Site --789y
	--			@Site = CASE WHEN @RoleID BETWEEN 2 AND 4 THEN c.site 
	--						 ELSE @Site END 
	--			AND ci.roleid = @RoleID 
	--			AND ISNULL(@UplineID,1) = CASE	WHEN @RoleID = 4 THEN ISNULL(@UplineID,1)
	--											WHEN @RoleID = 3 THEN ci.srecommend
	--											WHEN @RoleID = 2 THEN ci.mrecommend
	--											WHEN @RoleID = 1 THEN ci.recommend
	--											ELSE 0 END 
	--			AND ci.CustID > @MaxCustID		-- 23155908 MaxCustID 
	--			AND ci.currency IN (
	--				 SELECT Currency 
	--				 FROM	@tmpCurrList	
	--				 WHERE	Currency = CASE WHEN @isTest = 1 THEN 20 ELSE Currency END 
	--			)
	--			AND ci.Enabled = 1
	--			AND ci.CustID NOT IN (	
	--				--Master
	--				6525	,--	MVN
	--				14396	,--	AE
	--				1276306	,--	M922U				
	--				--Agency 
	--				71852	,--	AE13
	--				74139	,--	AE17
	--				105400	,--	BEE01
	--				106103	,--	BEE49
	--				108322	,--	AE151
	--				116494	,--	AE175
	--				127141	,--	AE183
	--				127142	,--	AE184
	--				127143	,--	AE185
	--				142400	,--	AE189
	--				142401	,--	AE190
	--				142402	,--	AE191
	--				142403	,--	AE192
	--				142404	,--	AE193
	--				142406	,--	AE194
	--				142408	,--	AE195
	--				142409	,--	AE196
	--				142410	,--	AE197
	--				142411	 --	AE198
	--			)
	--		ORDER BY ci.currency ASC 
	--END

	----Get customers of current roleID SUPER/MASTER/AGENT
	IF @RoleID BETWEEN 2 AND 4 AND @UplineID IS NULL	
	BEGIN
		SELECT   CASE ci.RoleID WHEN 4 THEN ci.CustID 
								WHEN 3 THEN ci.srecommend
								WHEN 2 THEN ci.mrecommend
								WHEN 1 THEN ci.recommend
								ELSE 0 END AS UplineID  --- = SuperID 
				,c.roleID As [Level]
				,ci.currency AS CurrencyID
				,CASE WHEN @RoleID = 1 THEN 4100300 ELSE 0 END AS SiteID
				,ci.CustID
				,ci.Username
		FROM	Customer c WITH (NOLOCK)
				INNER JOIN custInfo ci WITH (NOLOCK) ON c.custid = ci.custid
		WHERE	c.Site = @Site
				AND ci.roleid = @RoleID 
				AND ci.CustID > @MaxCustID		-- 23155908 MaxCustID 
				AND ci.currency IN (
					 SELECT Currency 
					 FROM	@tmpCurrList	
					 WHERE	Currency = CASE WHEN @isTest = 1 THEN 20 ELSE Currency END 
				)
				AND ci.Enabled = 1
				AND ci.CustID NOT IN (	
					--Master
					6525	,--	MVN
					14396	,--	AE
					1276306	,--	M922U				
					--Agency 
					71852	,--	AE13
					74139	,--	AE17
					105400	,--	BEE01
					106103	,--	BEE49
					108322	,--	AE151
					116494	,--	AE175
					127141	,--	AE183
					127142	,--	AE184
					127143	,--	AE185
					142400	,--	AE189
					142401	,--	AE190
					142402	,--	AE191
					142403	,--	AE192
					142404	,--	AE193
					142406	,--	AE194
					142408	,--	AE195
					142409	,--	AE196
					142410	,--	AE197
					142411	 --	AE198
				)		
			ORDER BY ci.currency ASC 
	END

	----Get customers of current roleID MEMBER
	IF @RoleID = 1 AND @UplineID IS NULL	
	BEGIN
		SELECT   CASE ci.RoleID WHEN 4 THEN ci.CustID 
								WHEN 3 THEN ci.srecommend
								WHEN 2 THEN ci.mrecommend
								WHEN 1 THEN ci.recommend
								ELSE 0 END AS UplineID  --- = SuperID 
				,c.roleID As [Level]
				,ci.currency AS CurrencyID
				,CASE WHEN @RoleID = 1 THEN 4100300 ELSE 0 END AS SiteID
				,ci.CustID
				,ci.Username
		FROM	Customer c WITH (NOLOCK)
				INNER JOIN custInfo ci WITH (NOLOCK) ON c.custid = ci.custid
				INNER JOIN customer ag WITH (NOLOCK) ON ag.CustID = ci.recommend
		WHERE	ag.Site = @Site --789y
				AND ci.roleid = @RoleID 
				AND ci.CustID > @MaxCustID		-- 23155908 MaxCustID 
				AND ci.currency IN (
					 SELECT Currency 
					 FROM	@tmpCurrList	
					 WHERE	Currency = CASE WHEN @isTest = 1 THEN 20 ELSE Currency END 
				)
				AND ci.Enabled = 1
				AND ci.CustID NOT IN (	
					--Master
					6525	,--	MVN
					14396	,--	AE
					1276306	,--	M922U				
					--Agency 
					71852	,--	AE13
					74139	,--	AE17
					105400	,--	BEE01
					106103	,--	BEE49
					108322	,--	AE151
					116494	,--	AE175
					127141	,--	AE183
					127142	,--	AE184
					127143	,--	AE185
					142400	,--	AE189
					142401	,--	AE190
					142402	,--	AE191
					142403	,--	AE192
					142404	,--	AE193
					142406	,--	AE194
					142408	,--	AE195
					142409	,--	AE196
					142410	,--	AE197
					142411	 --	AE198
				)		
			ORDER BY ci.currency ASC;
	END
END
GO
GRANT EXECUTE ON [dbo].[Acc_CustSetting_SyncAPICustomerProfileSelect_Site] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustSetting_SyncAPICustomerProfileSelect_Site] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustSetting_SyncAPICustomerProfileSelect_Site] TO [vnteam] AS [dbo]