/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerIsAllowedAccess]
	@UserID INT, 
	@UserName VARCHAR(30),		--Admin's username
	@DeniedList	NVARCHAR(MAX)=NULL,
	@CustID INT = NULL,
	@CustName NVARCHAR(50) = NULL,
	@CheckCustId TINYINT = 0,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg	NVARCHAR(200) = '' OUTPUT

AS
/*
	Created: 20160601@Elodie
	Task: check if user is allowed access customer
	Database: DBCUST/CUSTDB
	
	Revision:
		- 20161111@Elodie: Check more member of group headline
		- 20170816@Elodie: Add more starix account
		- 20171107@Vicky: Support to search customer id on Left panel [RedmineID: #86134]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20191009@Andy: Add permission for wsv_xnap and include checking special permission for internal admins only [Redmine: 121712]
		- 20210219@Tina: Add more starix account
		- 20220620@Johnson: define temp table to avoid dump db [redmine:#174035]	
		- 20231123@Johnson: re-arrange permission for credit sites [redmine: #197160]
		- 20240412@Tacy: NAP - Permission controls on real currency [redmine: #202523]
		- 20240425@Johnson: add starix104 to access 789y [redmine: #204395]
		- 20240809@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
		- 20241001@Tacy: Not call on Ext-NAP - Remove wsv_xnap account [redmineID: #206918]
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @RoleID TINYINT, @GroupID SMALLINT = NULL
	
	DECLARE @789ySites BIT = 1,
			@777Sites BIT = 1,
			@OtherSites BIT = 1,
			@AccessRealCurrency BIT = 1

	IF @CustID IS NULL
	BEGIN
		EXEC @custid = dbo.f_GetCustIDFromUsernameOrCustId @CustName,@CheckCustId

		IF @CustID IS NULL
		BEGIN
			RETURN
		END
	END
	
	SELECT @RoleID = roleid, @CustName = username FROM dbo.CustInfo WITH (NOLOCK) WHERE custid = @CustID

	DECLARE @tmpSite TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT)
	DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)

	IF ISNULL(@DeniedList,'')<>''
	BEGIN
		--get deny site
		INSERT INTO @tmpSite (siteid, site, SpecialGroup)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Site'
	
		--get deny currency
		INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Exchange'
	END

	IF EXISTS (SELECT 1 FROM @tmpSite WHERE SpecialGroup=1)
		OR (@UserID NOT IN (	360418		--starix1
								,15471134	--starix10
								,15477066	--starix11
								,15477075	--starix12
								,862400		--starix2
								,15512861	--starix20
								,15512891	--starix21
								,15513549	--starix23
								,15552859	--starix26
								,15560315	--starix27
								,169368		--starix3
								,16994226	--starix37
								,1070340	--starix4
								,22040268	--starix59
								,22040272	--starix60
								,22040275	--starix61
								,24103343	--starix65
								,15470946	--starix7
								,15470969	--starix8
								,15471129	--starix9
								,10278938	--starixIT
								/*-- 20170816@Elodie: Add more starix account*/
								,26870995	--starix68
								,26871005	--starix69
								,26871009	--starix70
								,26879871	--starix71
								,16492113	--starix33
								/*-- 20200219@Tina: Add more starix account*/
								,15470939	--starix6
								,28031365	--starix30
								,85471139 	--starix130
								
								,68830139  --starix104

							) AND @UserName LIKE 'starix%')				
		SELECT @789ySites = 0
	
	IF EXISTS (SELECT 1 FROM @tmpSite WHERE SpecialGroup=2) 		
		SELECT @777Sites = 0
								
	IF EXISTS (SELECT 1 FROM @tmpSite WHERE ISNULL(SpecialGroup,0) = 0) 		
		SELECT @OtherSites = 0	
		
	IF EXISTS (SELECT 1 FROM @tmpExchange WHERE exchangeID NOT IN (20,72)) 		
		SELECT @AccessRealCurrency = 0	

	IF @789ySites = 0 OR @777Sites = 0 OR @OtherSites = 0 OR @AccessRealCurrency=0
	BEGIN
		SELECT @GroupID = groupID FROM dbo.custAccount WITH (NOLOCK) WHERE custid = @CustID AND IsGroupHeadLine = 1
		IF @GroupID IS NOT NULL -- Headline
		BEGIN
			CREATE TABLE #tmpCustGroup(custid INT)
			
			INSERT INTO #tmpCustGroup(custid)
			SELECT custid			
			FROM dbo.custAccount WITH(NOLOCK) 
			WHERE groupID = @GroupID

			IF EXISTS ( SELECT 1
						FROM #tmpCustGroup cg
							INNER JOIN dbo.customer c WITH (NOLOCK) ON cg.custid = c.custid
							INNER JOIN dbo.site s WITH (NOLOCK) ON s.site = c.site
						WHERE ((IsDeposit = 0
								AND (	(SpecialGroup = 1 AND @789ySites = 0)
									OR	(SpecialGroup = 2 AND @777Sites = 0)
									OR	(ISNULL(SpecialGroup,0) = 0 AND @OtherSites = 0)
									))
								OR (c.currency NOT IN (20,72) AND @AccessRealCurrency=0)
							)	
							AND c.roleid BETWEEN 1 AND 4)
					SELECT @ErrCode = 100, @ErrMsg = 'You don''t have permission to access'
			
			DROP TABLE #tmpCustGroup 		
		END
		ELSE 
		BEGIN
			IF EXISTS (	SELECT 1
						FROM dbo.site s WITH (NOLOCK)
							INNER JOIN dbo.customer c WITH (NOLOCK) ON c.site = s.site
						WHERE c.custid = @CustID 
							AND	((IsDeposit = 0
								AND (	(SpecialGroup = 1 AND @789ySites = 0)
									OR	(SpecialGroup = 2 AND @777Sites = 0)
									OR	(ISNULL(SpecialGroup,0) = 0 AND @OtherSites = 0)
									))
								OR (c.currency NOT IN (20,72) AND @AccessRealCurrency=0)
							)
							AND c.roleid BETWEEN 1 AND 4)
				SELECT @ErrCode = 101, @ErrMsg = 'You don''t have permission to access'			
		END
	END
END
GO