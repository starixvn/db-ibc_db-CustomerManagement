/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUsername_Split]
	@username	 NVARCHAR(MAX)
	,@DeniedList NVARCHAR(MAX)=NULL
AS

/*
	Created: Tacy@20240704
	Task: support to split username 
	DB: DBCUST/CustDB
		
	Revisions:
		- 20240704@Tacy: Create SP [Redmine: #206291]
		
	Parameter's Explanation:
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @tmpUser TABLE (custid INT, username VARCHAR(200), roleid TINYINT)
	DECLARE @tmpResult TABLE (username VARCHAR(100), ErrMsg VARCHAR(100), ErrCode TINYINT)

	INSERT INTO @tmpUser(username)
	SELECT DISTINCT username
	FROM STRING_SPLIT(@username,'#') ss
	CROSS APPLY dbo.f_Acc_UserNameSplit (TRIM(ss.value),'-',',',';')

	UPDATE t
	SET t.custid = c.custid, t.roleid = c.roleid
	FROM @tmpUser t
		LEFT JOIN dbo.Customer c WITH (NOLOCK) ON t.username = c.username

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

	/* ===== Invalid case ===== */
	BEGIN
		-- User have not permission on Site/Currency
		INSERT INTO @tmpResult (username, ErrMsg, ErrCode)
		SELECT DISTINCT t.username, 'You don''t have permission to access', 99
		FROM @tmpUser t
			INNER JOIN customer c WITH (NOLOCK) ON c.custid = t.custid
		WHERE c.currency IN (SELECT exchangeID FROM @tmpExchange)
			OR c.site IN (SELECT site FROM @tmpSite)

		-- Invalid Username
		INSERT INTO @tmpResult (username, ErrMsg, ErrCode)
		SELECT username, 'Invalid Super account', 100
		FROM @tmpUser
		WHERE custid IS NULL
		UNION
		SELECT t.username, 'Invalid Super account', 0
		FROM @tmpUser t
			LEFT JOIN @tmpResult rs ON t.username = rs.username
		WHERE roleid<>4 AND rs.username IS NULL
	END
	
	/* ===== Valid case ===== */
	BEGIN
		INSERT INTO @tmpResult(username, ErrMsg, ErrCode)
		SELECT t.username, 'Valid Username.', 0
		FROM @tmpUser t 
			LEFT JOIN @tmpResult rs ON t.username = rs.username
		WHERE rs.username IS NULL
	END

	/* ===== Return result ===== */
	SELECT username, ErrMsg, ErrCode 
	FROM @tmpResult
	ORDER BY ErrCode, username
END
GO