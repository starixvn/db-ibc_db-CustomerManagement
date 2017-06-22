ALTER PROCEDURE [dbo].[Age_CustomerSelUserSearch]
	@custid INT,  -- roleid1
	@username VARCHAR(50),
	@issubaccount BIT = 0,
	@excludemember BIT = 0,
	@directdownline BIT = 0,
	@isaccinfo BIT = 1,
	@isInternalAgent BIT = 0
	
AS

/*
Created: 20090610@nqminh
Task : Select downline list of custId based on query string. Used for AutoComplete by "Account Info".
DB: DB053.bodb02
Original:

Revisions:
    - 20090122@[Reviewer]: [Description of revision]    
	- 20100601@Simon: Add function search by first name and last name.
	- 20101112@Terry: Allow search Subaccount for Viewlog login tab and exclude Member.
	- 20110721@Sophia: Add parameter @isInternalAgent
	- 20120326@Sophia: replace "where username like '%' + @username + '%'" (index scan) by "where username like @username + '%'" (index seek)
	- 20140708@Dom: Do not allow Super search Super name from Account Info section [Redmine: #18125]
Param's Explanation:
• @custid: User who are logging in.
• @username: part of downline's username.
*/

SET NOCOUNT ON
DECLARE @tmpUsername TABLE(username VARCHAR(30), firstname NVARCHAR(50), lastname NVARCHAR(50), searchcount INT)

DECLARE @roleid TINYINT
DECLARE @CurrentUsername VARCHAR(30)


SELECT @roleid = roleid,@CurrentUsername = username
FROM custinfo WITH (NOLOCK)
WHERE custid = @custid

IF @isaccinfo = 1
BEGIN
	INSERT INTO @tmpUsername (username, firstname, lastname, searchcount)
	SELECT TOP 10 username, firstname, lastname, searchcount
	FROM custsearch WITH (NOLOCK) 
	WHERE userid=@custid 
		AND (username LIKE '%' + @username  + '%' 
			OR firstname LIKE '%' + @username  + '%' 
			OR lastname LIKE '%' + @username  + '%')
		AND  CASE WHEN @isInternalAgent = 0 THEN Left(username,7) ELSE 'A' END  <>
			 CASE WHEN @isInternalAgent = 0 THEN 'Agency$' ELSE 'B' END 

	ORDER BY [searchcount] DESC
END

IF @@ROWCOUNT < 10
BEGIN
	IF @issubaccount = 1 -- SubAccount
	BEGIN
		INSERT INTO @tmpUsername (username, firstname, lastname, searchcount)
		SELECT TOP 10 username, firstname, lastname, -1 AS searchcount
		FROM custsub WITH (NOLOCK)
		WHERE custid = @custid
			--AND recommend = @custid
				AND (username LIKE @username  + '%' 
				OR firstname LIKE @username  + '%' 
				OR lastname LIKE @username  + '%')
		ORDER BY username
	END

	IF @roleid = 2 -- Agent
	BEGIN
		IF @excludemember = 1
		BEGIN
			INSERT INTO @tmpUsername (username, firstname, lastname, searchcount)
			SELECT TOP 10 username, firstname, lastname, -1 AS searchcount
			FROM customer WITH (NOLOCK)
			WHERE roleid = 2
				AND recommend = @custid
				AND (username LIKE @username  + '%' 
					OR firstname LIKE @username  + '%' 
					OR lastname LIKE @username  + '%')
			ORDER BY username
		END
		ELSE
		BEGIN
			INSERT INTO @tmpUsername (username, firstname, lastname, searchcount)
			SELECT TOP 10 username, firstname, lastname, -1 AS searchcount
			FROM customer WITH (NOLOCK)
			WHERE roleid < 2
				AND recommend = @custid
				AND (username LIKE @username  + '%' 
					OR firstname LIKE @username  + '%' 
					OR lastname LIKE @username  + '%')
			ORDER BY username
		END
	
		
	END
	ELSE IF @roleid = 3 -- Master
	BEGIN
		IF @directdownline = 1
			BEGIN
				INSERT INTO @tmpUsername (username, firstname, lastname, searchcount)
				SELECT TOP 10 username, firstname, lastname, -1 AS searchcount
				FROM customer WITH (NOLOCK)

				WHERE roleid =2
					AND mrecommend = @custid
					AND (username LIKE @username  + '%' 
						OR firstname LIKE @username  + '%' 
						OR lastname LIKE @username  + '%')
				ORDER BY username
			END
		ELSE
			BEGIN
			IF @excludemember = 1
			BEGIN
				INSERT INTO @tmpUsername (username, firstname, lastname, searchcount)
				SELECT TOP 10 username, firstname, lastname, -1 AS searchcount
				FROM customer WITH (NOLOCK)

				WHERE roleid < 3 AND roleid > 1
					AND mrecommend = @custid
					AND (username LIKE @username  + '%' 
						OR firstname LIKE @username  + '%' 
						OR lastname LIKE @username  + '%')
				ORDER BY username
			END
			ELSE
			BEGIN
				INSERT INTO @tmpUsername (username, firstname, lastname, searchcount)
				SELECT TOP 10 username, firstname, lastname, -1 AS searchcount
				FROM customer WITH (NOLOCK)

				WHERE roleid < 3
					AND mrecommend = @custid
					AND (username LIKE @username  + '%' 
						OR firstname LIKE @username  + '%' 
						OR lastname LIKE @username  + '%')
				ORDER BY username
			END
		END	
	END
	ELSE IF @roleid = 4 -- Super
	BEGIN
		IF @directdownline = 1
			BEGIN
				INSERT INTO @tmpUsername (username, firstname, lastname, searchcount)
				SELECT TOP 10 username, firstname, lastname, -1 AS searchcount
				FROM customer WITH (NOLOCK)
				WHERE roleid = 3
					AND srecommend = @custid
					AND (username LIKE @username  + '%' 
						OR firstname LIKE @username  + '%' 
						OR lastname LIKE @username  + '%')
				ORDER BY username
			END
		ELSE
			BEGIN
				IF @excludemember = 1
					BEGIN
						INSERT INTO @tmpUsername (username, firstname, lastname, searchcount)
						SELECT TOP 10 username, firstname, lastname, -1 AS searchcount
						FROM customer WITH (NOLOCK)
						WHERE roleid < 4 AND roleid > 1
							AND srecommend = @custid
							AND (username LIKE @username  + '%' 
								OR firstname LIKE @username  + '%' 
								OR lastname LIKE @username  + '%')
						ORDER BY username
					END
				ELSE
					BEGIN
						INSERT INTO @tmpUsername (username, firstname, lastname, searchcount)
						SELECT TOP 10 username, firstname, lastname, -1 AS searchcount
						FROM customer WITH (NOLOCK)
						WHERE roleid < 4
							AND srecommend = @custid
							AND (username LIKE @username  + '%' 
								OR firstname LIKE @username  + '%' 
								OR lastname LIKE @username  + '%')
						ORDER BY username
					END
			END	
	END
END


DECLARE @tmpSearchMax TABLE(username VARCHAR(30), firstname NVARCHAR(50), lastname NVARCHAR(50), searchcount INT)

INSERT INTO @tmpSearchMax
SELECT username, firstname, lastname, MAX(searchcount) searchcount
FROM @tmpUsername  		
GROUP BY username, firstname, lastname


SELECT TOP 10 username, firstname, lastname
FROM 
	(	
		SELECT username, firstname, lastname, searchcount
		FROM @tmpSearchMax  
		WHERE searchcount < 0
		UNION ALL 
		SELECT username, firstname, lastname, searchcount
		FROM  @tmpSearchMax 
		WHERE username NOT IN (SELECT username FROM @tmpSearchMax WHERE searchcount < 0) 			
	)a
WHERE a.username <> @CurrentUsername
ORDER BY searchcount DESC, username


GO
GRANT EXECUTE ON [dbo].Age_CustomerSelUserSearch TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].Age_CustomerSelUserSearch TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].Age_CustomerSelUserSearch TO [vnteam]

