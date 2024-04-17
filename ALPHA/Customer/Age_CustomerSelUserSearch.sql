/*<info serverAlias="DBAGE-bodb02" executers="wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Age_CustomerSelUserSearch]
	@UserID INT,
	@custid INT,  -- roleid1
	@username NVARCHAR(50),
	@issubaccount BIT = 0,
	@excludemember BIT = 0,
	@directdownline BIT = 0,
	@isaccinfo BIT = 1,
	@isInternalAgent BIT = 0
	
AS
/*
	Created: 20090610@nqminh
	Task : Select downline list of custId based on query string. Used for AutoComplete by "Account Info".
	DB: DBAGE/bodb02
	Original:

	Revisions:
		- 20090122@[Reviewer]: [Description of revision]    
		- 20100601@Simon: Add function search by first name and last name.
		- 20101112@Terry: Allow search Subaccount for Viewlog login tab and exclude Member.
		- 20110721@Sophia: Add parameter @isInternalAgent
		- 20120326@Sophia: replace "where username like '%' + @username + '%'" (index scan) by "where username like @username + '%'" (index seek)
		- 20140708@Dom: Do not allow Super search Super name from Account Info section [Redmine: #18125]
		- 20190508@Elodie: Allow to search nickname [Redmine: #113044]
		- 20190512@Elodie: Allow to search nickname on customer list[Redmine: #113044]
		- 20230407@Helios: Changed datatype parameter @username [Redmine: #183697]
		- 20231222@Helios: Alpha - Search Customer run slowly - Add Forced Index  [Redmine: #198788]
		- 20231222@Helios: Alpha - Search Customer run slowly - Revise code to user index IX_agent [Redmine: #198788]
	Param's Explanation:
		• @custid: User who are logging in.
		• @username: part of downline's username.
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @tmpUsername TABLE(username VARCHAR(30), firstname NVARCHAR(50), lastname NVARCHAR(50), username2 VARCHAR(50), searchcount INT)
	DECLARE @roleid TINYINT, @CurrentUsername VARCHAR(30), @UserRoleId TINYINT

	SELECT @roleid = roleid, @CurrentUsername = username
	FROM custinfo WITH (NOLOCK)
	WHERE custid = @custid

	SELECT @UserRoleId = roleid
	FROM custinfo WITH (NOLOCK)
	WHERE custid = @UserID

	IF @isaccinfo = 1
	BEGIN
		INSERT INTO @tmpUsername (username, firstname, lastname, username2, searchcount)
		SELECT TOP 10 s.username, s.firstname, s.lastname, CASE WHEN c.roleid = @roleid - 1 THEN s.username2 ELSE NULL END, searchcount
		FROM custsearch s WITH (NOLOCK) 
			INNER JOIN customer c (NOLOCK) ON s.username = c.username  
		WHERE userid=@custid 
			AND (s.username LIKE '%' + @username  + '%' 
				OR s.username2 LIKE '%' + @username  + '%' 
				OR s.firstname LIKE '%' + @username  + '%' 
				OR s.lastname LIKE '%' + @username  + '%')
			AND  CASE WHEN @isInternalAgent = 0 THEN Left(s.username,7) ELSE 'A' END  <>
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
				INSERT INTO @tmpUsername (username, firstname, lastname, username2, searchcount)
				SELECT TOP 10 c.username, c.firstname, c.lastname, CASE WHEN @UserRoleId = @RoleID THEN c.username2 ELSE NULL END, -1 AS searchcount
				FROM customer c1 WITH (NOLOCK)
				CROSS APPLY (SELECT TOP 1 username, firstname, lastname, username2
							FROM Customer WITH (NOLOCK)
							WHERE custid = c1.custid 
								AND (username LIKE @username  + '%' 
								OR (@UserRoleId = @RoleID AND username2 LIKE @username  + '%')
								OR firstname LIKE @username  + '%' 
								OR lastname LIKE @username  + '%')) c
				WHERE roleid = 2
					AND recommend = @custid
				ORDER BY c.username
			END
			ELSE
			BEGIN
				INSERT INTO @tmpUsername (username, firstname, lastname, username2, searchcount)
				SELECT TOP 10 c.username, c.firstname, c.lastname, CASE WHEN @UserRoleId = @RoleID THEN c.username2 ELSE NULL END, -1 AS searchcount
				FROM customer c1 WITH (NOLOCK)
				CROSS APPLY (SELECT TOP 1 username, firstname, lastname, username2
							FROM Customer WITH (NOLOCK)
							WHERE custid = c1.custid 
								AND (username LIKE @username  + '%' 
								OR (@UserRoleId = @RoleID AND username2 LIKE @username  + '%')
								OR firstname LIKE @username  + '%' 
								OR lastname LIKE @username  + '%')) c
				WHERE roleid < 2
					AND recommend = @custid
				ORDER BY c.username
			END
		END
		ELSE IF @roleid = 3 -- Master
		BEGIN
			IF @directdownline = 1
			BEGIN
				INSERT INTO @tmpUsername (username, firstname, lastname, username2, searchcount)
				SELECT TOP 10 c.username, c.firstname, c.lastname, CASE WHEN @UserRoleId = @RoleID THEN c.username2 ELSE NULL END, -1 AS searchcount
				FROM customer c1 WITH (NOLOCK)
				CROSS APPLY (SELECT TOP 1 username, firstname, lastname, username2
							FROM Customer WITH (NOLOCK)
							WHERE custid = c1.custid 
								AND (username LIKE @username  + '%' 
								OR (@UserRoleId = @RoleID AND username2 LIKE @username  + '%')
								OR firstname LIKE @username  + '%' 
								OR lastname LIKE @username  + '%')) c
				WHERE roleid = 2
					AND mrecommend = @custid
				ORDER BY c.username
			END
			ELSE
			BEGIN
				IF @excludemember = 1
				BEGIN
					INSERT INTO @tmpUsername (username, firstname, lastname, username2, searchcount)
					SELECT TOP 10 c.username, c.firstname, c.lastname, CASE WHEN @UserRoleId = @RoleID THEN c.username2 ELSE NULL END, -1 AS searchcount
					FROM customer c1 WITH (NOLOCK)
					CROSS APPLY (SELECT TOP 1 username, firstname, lastname, username2
							FROM Customer WITH (NOLOCK)
							WHERE custid = c1.custid 
								AND (username LIKE @username  + '%' 
								OR (@UserRoleId = @RoleID AND username2 LIKE @username  + '%')
								OR firstname LIKE @username  + '%' 
								OR lastname LIKE @username  + '%')) c
					WHERE roleid < 3 AND roleid > 1
						AND mrecommend = @custid
					ORDER BY c.username
				END
				ELSE
				BEGIN
					INSERT INTO @tmpUsername (username, firstname, lastname, username2, searchcount)
					SELECT TOP 10 c.username, c.firstname, c.lastname, CASE WHEN @UserRoleId = @RoleID AND roleid = 2 THEN c.username2 ELSE NULL END, -1 AS searchcount
					FROM customer c1 WITH (NOLOCK)
					CROSS APPLY (SELECT TOP 1 username, firstname, lastname, username2
							FROM Customer WITH (NOLOCK)
							WHERE custid = c1.custid 
								AND (username LIKE @username  + '%' 
								OR (@UserRoleId = @RoleID AND username2 LIKE @username  + '%')
								OR firstname LIKE @username  + '%' 
								OR lastname LIKE @username  + '%')) c
					WHERE roleid < 3
						AND mrecommend = @custid
					ORDER BY c.username
				END
			END	
		END
		ELSE IF @roleid = 4 -- Super
		BEGIN
			IF @directdownline = 1
			BEGIN
				INSERT INTO @tmpUsername (username, firstname, lastname, username2, searchcount)
				SELECT TOP 10 c.username, c.firstname, c.lastname, CASE WHEN @UserRoleId = @RoleID THEN c.username2 ELSE NULL END, -1 AS searchcount
				FROM customer c1 WITH (NOLOCK)
				CROSS APPLY (SELECT TOP 1 username, firstname, lastname, username2
							FROM Customer WITH (NOLOCK)
							WHERE custid = c1.custid 
								AND (username LIKE @username  + '%' 
								OR (@UserRoleId = @RoleID AND username2 LIKE @username  + '%')
								OR firstname LIKE @username  + '%' 
								OR lastname LIKE @username  + '%')) c
				WHERE roleid = 3
					AND srecommend = @custid
				ORDER BY c.username
			END
			ELSE
			BEGIN
				IF @excludemember = 1
					BEGIN
						INSERT INTO @tmpUsername (username, firstname, lastname, username2, searchcount)
						SELECT TOP 10 c.username, c.firstname, c.lastname, CASE WHEN @UserRoleId = @RoleID AND roleid = 3 THEN c.username2 ELSE NULL END, -1 AS searchcount
						FROM customer c1 WITH (NOLOCK)
						CROSS APPLY (SELECT TOP 1 username, firstname, lastname, username2
							FROM Customer WITH (NOLOCK)
							WHERE custid = c1.custid 
								AND (username LIKE @username  + '%' 
								OR (@UserRoleId = @RoleID AND username2 LIKE @username  + '%')
								OR firstname LIKE @username  + '%' 
								OR lastname LIKE @username  + '%')) c
						WHERE roleid < 4 AND roleid > 1
							AND srecommend = @custid
						ORDER BY c.username
					END
				ELSE
					BEGIN
						INSERT INTO @tmpUsername (username, firstname, lastname, username2, searchcount)
						SELECT TOP 10 c.username, c.firstname, c.lastname, CASE WHEN @UserRoleId = @RoleID AND roleid = 3 THEN c.username2 ELSE NULL END, -1 AS searchcount
						FROM customer c1 WITH (NOLOCK)
						CROSS APPLY (SELECT TOP 1 username, firstname, lastname, username2
							FROM Customer WITH (NOLOCK)
							WHERE custid = c1.custid 
								AND (username LIKE @username  + '%' 
								OR (@UserRoleId = @RoleID AND username2 LIKE @username  + '%')
								OR firstname LIKE @username  + '%' 
								OR lastname LIKE @username  + '%')) c
						WHERE roleid < 4
							AND srecommend = @custid
						ORDER BY c.username
					END
			END	
		END
	END

	DECLARE @tmpSearchMax TABLE(username VARCHAR(30), firstname NVARCHAR(50), lastname NVARCHAR(50), username2 VARCHAR(50), searchcount INT)

	INSERT INTO @tmpSearchMax
	SELECT username, firstname, lastname, username2, MAX(searchcount) searchcount
	FROM @tmpUsername  		
	GROUP BY username, firstname, lastname, username2

	SELECT TOP 10 username, firstname, lastname, username2
	FROM 
		(	
			SELECT username, firstname, lastname, username2, searchcount
			FROM @tmpSearchMax  
			WHERE searchcount < 0
			UNION ALL 
			SELECT username, firstname, lastname, username2, searchcount
			FROM  @tmpSearchMax 
			WHERE username NOT IN (SELECT username FROM @tmpSearchMax WHERE searchcount < 0) 			
		)a
	WHERE a.username <> @CurrentUsername
	ORDER BY searchcount DESC, username
END