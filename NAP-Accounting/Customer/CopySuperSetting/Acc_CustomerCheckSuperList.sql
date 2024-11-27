/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerCheckSuperList]  
	@username		VARCHAR(30)='',
	@SuperList		VARCHAR(MAX),
	@IsCopy			BIT=0,
	@DeniedList		NVARCHAR(MAX)=NULL, 
	@Mode			VARCHAR(50)='',
	@SettingStatus	TINYINT=0,
	@CustID			INT=0 OUTPUT,
	@Errcode		INT=0 OUTPUT,
	@ErrMsg			NVARCHAR(MAX)='' OUTPUT
AS  
/*  
	Creator: 20241010@Tacy  
	Task : Validate source and destination supers before updating.
	DB: DBCUST/CustDB

	Revisions:  
		- 20241010@Tacy: NAP & Ext - Manage super settings [redmine: #206291]
	
	Param's Explanation:
		* @IsCopy : 1 ~ Copy Setting
					0 ~ Edit Setting

		* @Mode = 'WinLossLimit'
				= 'BetSetting'
				= 'AccountInfo'
				= 'AccountStatus'

	Example:	
*/
BEGIN
    SET NOCOUNT ON

	DECLARE @tmpSupers TABLE (
			RowID			INT IDENTITY (1,1)
			,CustID			INT NULL
			,UserName		VARCHAR(30)
			,IsFinished		BIT DEFAULT(0)
	)

	--get denied site/currency:
	DECLARE @tmpSite TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
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

	--Destination username
	IF (ISNULL(@SuperList,'')='')
	BEGIN
		SET @Errcode=104
		SET @ErrMsg=CASE WHEN @IsCopy=0 THEN 'Please input username of supers' ELSE 'Please input destination super' END
		RETURN
	END

	--Username over-length
	IF EXISTS (SELECT 1 FROM STRING_SPLIT(@SuperList, ',') 
				WHERE TRIM(value)<>'' AND LEN(TRIM(value))>30)
	BEGIN
		SELECT  @Errcode=97,
				@ErrMsg='Invalid super account(s): '
						+ STUFF ((SELECT ', ' + TRIM(value)
								  FROM STRING_SPLIT(@SuperList, ',') 
								  WHERE TRIM(value)<>'' AND LEN(TRIM(value))>30
								  FOR XML PATH('')),1,1,'')
		RETURN
	END

	INSERT INTO @tmpSupers (CustID, UserName)
	SELECT c.custid, TRIM(value)
	FROM string_split(@SuperList, ',') 
	LEFT JOIN Customer c WITH (NOLOCK) ON c.username=TRIM(value)
	WHERE TRIM(value)<>''

	-- Source username
	IF @IsCopy=1
	BEGIN
		IF (ISNULL(@username,'')='')
		BEGIN
			SET @Errcode=99
			SET @ErrMsg='Please input source super'
			RETURN
		END
		ELSE
		BEGIN
			--check: single source account
			IF EXISTS (SELECT 1 FROM STRING_SPLIT(@username,',') WHERE TRIM(value)<>'' HAVING COUNT(1)>1)
			BEGIN
				SET @Errcode=100
				SET @ErrMsg='Please input a single source super'
				RETURN
			END

			--check: permission on Site/Currency
			IF EXISTS (SELECT 1 FROM customer c WITH (NOLOCK)
						WHERE c.username=@username
							AND (c.currency IN (SELECT exchangeID FROM @tmpExchange)
								OR c.site IN (SELECT site FROM @tmpSite)))
			BEGIN
				SET @Errcode = 112
				SET @ErrMsg = 'You don''t have permission to access: ' + @username

				RETURN
			END

			--check: source account is not super's username, invalid, disable, dummy
			IF NOT EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE username=@username)
				OR EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE (roleid<>4 OR Enabled=0) AND username=@username)
				OR EXISTS (SELECT 1 FROM Customer c WITH (NOLOCK)
							INNER JOIN Acc_CustDirect cd WITH (NOLOCK) ON c.custid=cd.custid
							WHERE c.username=@username)	--Dummy
				OR EXISTS (SELECT 1 FROM Dep_CustSuper WITH(NOLOCK) WHERE username=@username)
			BEGIN
				SET @Errcode=101
				SET @ErrMsg='Invalid source super'
				RETURN
			END

			--check: source account is among the destination ones
			IF EXISTS (SELECT 1 FROM @tmpSupers WHERE UserName=@username)
			BEGIN
				SET @Errcode=103
				SET @ErrMsg='Source Super and destination Super are duplicated: ' + @username
				RETURN
			END
		END

		SELECT @CustID=custid 
		FROM Customer WITH (NOLOCK)
		WHERE username=@username
	END

	--check: destination account is invalid username
	IF EXISTS (SELECT 1 FROM @tmpSupers WHERE custid IS NULL)
	BEGIN
		SET @Errcode=106
		SET @ErrMsg='Invalid super account(s): ' 
					+ STUFF ((SELECT ', ' + d.UserName
							  FROM @tmpSupers d  
							  WHERE custid IS NULL
							  ORDER BY d.UserName
							  FOR XML PATH('')),1,1,'')
		RETURN
	END

	--check: duplicate destination account
	IF EXISTS (SELECT 1 FROM @tmpSupers GROUP BY UserName HAVING COUNT(1)>1)
	BEGIN
		SET @Errcode=105
		SET @ErrMsg='Duplicate super account(s): ' 
					+ STUFF ((SELECT ', ' + d.UserName
							  FROM @tmpSupers d  
							  GROUP BY UserName 
							  HAVING COUNT(1)>1
							  ORDER BY d.UserName
							  FOR XML PATH('')),1,1,'')
		RETURN
	END 

	--check: permission on Site/Currency
	IF EXISTS (SELECT 1 FROM customer c WITH (NOLOCK)
				INNER JOIN @tmpSupers s ON s.CustID=c.custid
				WHERE c.currency IN (SELECT exchangeID FROM @tmpExchange)
					OR c.site IN (SELECT site FROM @tmpSite))
	BEGIN
		SET @Errcode = 112
		SET @ErrMsg = 'You don''t have permission to access: ' 
					+ STUFF((
								SELECT ',' + c.UserName  
								FROM customer c WITH (NOLOCK)
								INNER JOIN @tmpSupers s ON s.CustID=c.custid
								WHERE c.currency IN (SELECT exchangeID FROM @tmpExchange)
										OR c.site IN (SELECT site FROM @tmpSite)
								FOR XML PATH('')
							), 1,1,'')

		RETURN
	END

	--check: destination accounts are not super
	IF EXISTS (SELECT 1 FROM @tmpSupers d  
				INNER JOIN Customer c WITH (NOLOCK) ON d.custid=c.custid
				WHERE c.roleid<>4)
	BEGIN
		SET @Errcode=107
		SET @ErrMsg='Invalid super account(s): ' 
					+ STUFF ((SELECT ', ' + d.UserName
							  FROM @tmpSupers d  
							  INNER JOIN Customer c WITH (NOLOCK) ON d.custid=c.custid
							  WHERE c.roleid<>4
							  ORDER BY d.UserName
							  FOR XML PATH('')),1,1,'')
		RETURN
	END

	--check: destination accounts are disabled / Deposit
	IF EXISTS (SELECT 1 FROM @tmpSupers d  
				INNER JOIN custInfo c WITH (NOLOCK) ON d.custid=c.custid
				LEFT JOIN Dep_CustSuper cs WITH (NOLOCK) ON cs.custid=d.CustID
				WHERE c.Enabled=0 OR cs.custid IS NOT NULL)
	BEGIN
		SET @Errcode=108
		SET @ErrMsg='Invalid super account(s): ' 
					+ STUFF ((SELECT ', ' + d.UserName
							  FROM @tmpSupers d  
							  INNER JOIN custInfo c WITH (NOLOCK) ON d.custid=c.custid
							  LEFT JOIN Dep_CustSuper cs WITH (NOLOCK) ON cs.custid=d.CustID
							  WHERE c.Enabled=0 OR cs.custid IS NOT NULL
							  ORDER BY d.UserName
							  FOR XML PATH('')),1,1,'')
		RETURN
	END

	--check: destination accounts are dummy
	IF EXISTS (SELECT 1 FROM @tmpSupers d  
				INNER JOIN Acc_CustDirect cd WITH (NOLOCK) ON d.custid=cd.custid)
	BEGIN
		SET @Errcode=109
		SET @ErrMsg='Invalid super account(s): ' 
					+ STUFF ((SELECT ', ' + d.UserName
							  FROM @tmpSupers d  
							  INNER JOIN Acc_CustDirect cd WITH (NOLOCK) ON d.custid=cd.custid
							  ORDER BY d.UserName
							  FOR XML PATH('')),1,1,'')
		RETURN
	END
		
	--check: not the same line
	IF EXISTS (SELECT TOP 1 1 FROM @tmpSupers d  
				INNER JOIN Customer c WITH (NOLOCK) ON d.custid=c.custid
				CROSS APPLY (SELECT s.site, s.currency FROM Customer s WITH (NOLOCK) 
							 WHERE s.custid=@CustID) s
				WHERE c.currency<>s.currency OR c.site<>s.site)
		AND @IsCopy=1
	BEGIN
		SET @Errcode=114
		SET @ErrMsg='The following accounts are not the same site and currency with the source account: ' 
					+ STUFF ((SELECT ', ' + d.UserName
							  FROM @tmpSupers d  
							  INNER JOIN Customer c WITH (NOLOCK) ON d.custid=c.custid
							  CROSS APPLY (SELECT s.site, s.currency FROM Customer s WITH (NOLOCK) 
											WHERE s.custid=@CustID) s
							  WHERE c.currency<>s.currency OR c.site<>s.site
							  ORDER BY d.UserName
							  FOR XML PATH('')),1,1,'')
		RETURN
	END

	;WITH cte_DiffSiteCurrency AS (
		SELECT c.site, c.currency FROM @tmpSupers d  
		INNER JOIN Customer c WITH (NOLOCK) ON d.custid=c.custid
		WHERE @Mode='BetSetting'
		GROUP BY c.site, c.currency
	)
	SELECT TOP 1 
		@Errcode=115
		, @ErrMsg='The function can only edit bet setting of Supers with same site and currency.'
	FROM cte_DiffSiteCurrency
	HAVING COUNT (1) > 1

	IF @Errcode <> 0
		RETURN

	--check: the number of the destination accounts exceeds 100
	DECLARE @cnt INT

	SELECT @cnt=COUNT(1) FROM @tmpSupers 

	IF (@Mode NOT IN ('WinLossLimit','AccountStatus') AND @cnt>100)
	OR (@Mode IN ('WinLossLimit','AccountStatus') AND @cnt>500)
	BEGIN
		SET @Errcode=111
		SET @ErrMsg='The function can only edit up to '
				+ CASE WHEN @Mode NOT IN ('WinLossLimit','AccountStatus') AND @cnt>100 THEN '100'
					  WHEN @Mode IN ('WinLossLimit','AccountStatus') AND @cnt>500 THEN '500'
				END
				+ ' accounts per request.'
		RETURN
	END
	
	SELECT t.CustID, t.UserName, c.currency, c.site, s.SiteLabel
		, closed = CASE WHEN cs.CloseInfo > 0 THEN 1 ELSE 0 END
		, Suspended = CASE WHEN cs.SuspendInfo > 0 THEN 1 ELSE 0 END
		, ISNULL(ci.IsProtectedMode,0) IsProtectedMode
	FROM @tmpSupers t
		INNER JOIN customer c WITH(NOLOCK) ON t.custid = c.custid		
		INNER JOIN CustProductStatus cs WITH(NOLOCK) ON t.custid = cs.custid
		INNER JOIN CustLoginInfo ci WITH(NOLOCK) ON t.custid = ci.custid
		INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site
	ORDER BY t.RowID

	IF @Mode='WinLossLimit'
	BEGIN
		--get list products
		EXEC Acc_CopySetting_CustomerCheckSuperList 
			@username=@username
			,@SuperList=@SuperList
			,@SettingStatus=@SettingStatus
	END
END
GO