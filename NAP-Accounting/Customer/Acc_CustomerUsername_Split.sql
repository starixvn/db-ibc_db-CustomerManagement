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
		- 20250520@Virgil: NAP - Text to Username Enhancement [Redmine: #227391]
		
	Parameter's Explanation:
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @tmpUser TABLE (custid INT, username VARCHAR(200), roleid TINYINT)
	DECLARE @tmpNickname TABLE (custid INT, username VARCHAR(200), nickname VARCHAR(100), roleid TINYINT)

	DECLARE @tmpResult TABLE (username VARCHAR(100), ErrMsg VARCHAR(100), ErrCode TINYINT)

	INSERT INTO @tmpUser(username)
	SELECT DISTINCT username
	FROM STRING_SPLIT(@username,'#') ss
	CROSS APPLY dbo.f_Acc_UserNameSplit (TRIM(ss.value),'-',',',';')

	-- Insert list users have nickname
	INSERT INTO @tmpNickname(custid, username, nickname, roleid)
	SELECT c.custid, c.username, c.username2, c.roleid
	FROM @tmpUser t
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON t.username = c.username2

	-- Update customer info from username list
	UPDATE t
	SET t.custid = c.custid, t.roleid = c.roleid
	FROM @tmpUser t
		LEFT JOIN dbo.Customer c WITH (NOLOCK) ON t.username = c.username

	-- Remove username that already has nickname 
	DELETE FROM @tmpUser WHERE username IN (SELECT nickname FROM @tmpNickname)

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

	END
	
	/* ===== Valid case ===== */
	BEGIN
		INSERT INTO @tmpResult(username, ErrMsg, ErrCode)
		SELECT t.username, 'Valid Username', 0
		FROM @tmpUser t 
			LEFT JOIN @tmpResult rs ON t.username = rs.username
		WHERE rs.username IS NULL
		UNION
		SELECT t.nickname, 'Valid Nicknames', 99
		FROM @tmpNickname t 
			LEFT JOIN @tmpResult nn ON t.nickname = nn.username
		WHERE nn.username IS NULL
	END

	/* ===== Return result ===== */
	SELECT username, ErrMsg, ErrCode 
	FROM @tmpResult
	ORDER BY ErrCode, username
END
GO