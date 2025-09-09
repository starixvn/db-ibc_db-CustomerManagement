/*<info serverAlias="DBAGE-bodb02" executers="wsv_alp,wsv_alpv" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelUserSearch_ByRole]
	@custid		INT,
	@username	NVARCHAR(50),
	@RoleId		TINYINT = 0
AS
/*
	Created: 20240802@Tacy
	Task : Select username list by roleID.
	DB: DBAGE/bodb02 

	Revisions:
		- 20240802@Tacy: Create SP [Redmine: #204089]
		- 20250903@Elodie: Enhance SP [Redmine: #237555]
	Param's Explanation:
		� @custid: User who are logging in.
		� @username: part of username.
		� @RoleId: roleId of @username 
					0 ~ All
					1 ~ Member
					2 ~ Agent
					3 ~ Master
					4 ~ Super
					
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE  @CurrentUsername VARCHAR(30), @UserRoleId TINYINT

	DECLARE @tmpUsername TABLE(username VARCHAR(30), firstname NVARCHAR(50), lastname NVARCHAR(50), username2 VARCHAR(50), searchcount INT DEFAULT(-1))

	SELECT @UserRoleId = roleid, @CurrentUsername = username
	FROM custinfo WITH (NOLOCK)
	WHERE custid = @custid

	INSERT INTO @tmpUsername (username, firstname, lastname, username2, searchcount)
	SELECT TOP 10 s.username, c.firstname, c.lastname
				, CASE WHEN c.roleid = @UserRoleId - 1 THEN s.username2 ELSE NULL END
				, searchcount
	FROM custsearch s WITH (NOLOCK) 
		INNER JOIN customer c (NOLOCK) ON s.username = c.username  
	WHERE userid=@custid 
		AND (s.username LIKE '%' + @username  + '%' 
			OR s.username2 LIKE '%' + @username  + '%' 
			OR s.firstname LIKE '%' + @username  + '%' 
			OR s.lastname LIKE '%' + @username  + '%')
		AND (c.roleid = @RoleId OR @RoleId=0)
	ORDER BY [searchcount] DESC
	
	IF @@ROWCOUNT < 10
	BEGIN
		IF @UserRoleId=4
		BEGIN
			INSERT INTO @tmpUsername (username, firstname, lastname, username2)
			SELECT TOP 10 c1.username, c1.firstname, c1.lastname, c1.username2
			FROM customer c WITH (NOLOCK)
				CROSS APPLY (SELECT TOP 1 username, firstname, lastname, username2, roleid
							FROM Customer t WITH (NOLOCK)
							WHERE t.custid = c.custid 
								) c1
			WHERE c.srecommend=@custid
				AND c1.roleid < @UserRoleId 
				AND (@RoleId = 0 OR @RoleId = c1.roleid)
				AND (c1.username LIKE @username  + '%' 
					OR c1.username2 LIKE @username  + '%' 
					OR c1.firstname LIKE @username  + '%' 
					OR c1.lastname LIKE @username  + '%')
			ORDER BY c1.username
		END
		ELSE IF @UserRoleId=3
		BEGIN
			INSERT INTO @tmpUsername (username, firstname, lastname, username2)
			SELECT TOP 10 c1.username, c1.firstname, c1.lastname, c1.username2
			FROM customer c WITH (NOLOCK)
				CROSS APPLY (SELECT TOP 1 username, firstname, lastname, username2, roleid
							FROM Customer t WITH (NOLOCK)
							WHERE t.custid = c.custid 
								) c1
			WHERE c.mrecommend=@custid
				AND c1.roleid < @UserRoleId 
				AND (@RoleId = 0 OR @RoleId = c1.roleid)
				AND (c1.username LIKE @username  + '%' 
					OR c1.username2 LIKE @username  + '%' 
					OR c1.firstname LIKE @username  + '%' 
					OR c1.lastname LIKE @username  + '%')
			ORDER BY c1.username
		END
		ELSE IF @UserRoleId=2
		BEGIN
			INSERT INTO @tmpUsername (username, firstname, lastname, username2)
			SELECT TOP 10 c.username, c.firstname, c.lastname, c.username2
			FROM customer c WITH (NOLOCK)
				CROSS APPLY (SELECT TOP 1 username, firstname, lastname, username2, roleid
							FROM Customer t WITH (NOLOCK)
							WHERE t.custid = c.custid 
								) c1
			WHERE c.recommend=@custid
				AND c1.roleid < @UserRoleId 
				AND (@RoleId = 0 OR @RoleId = c1.roleid)
				AND (c1.username LIKE @username  + '%' 
					OR c1.username2 LIKE @username  + '%' 
					OR c1.firstname LIKE @username  + '%' 
					OR c1.lastname LIKE @username  + '%')
			ORDER BY c1.username
		END
	END

	SELECT TOP 10 username, firstname, lastname, username2
	FROM 
		(	SELECT 
				username, firstname, lastname, username2, searchcount
			FROM 
				@tmpUsername  
			WHERE 
				searchcount >= 0
			UNION ALL 
			SELECT 
				username, firstname, lastname, username2, searchcount
			FROM  
				@tmpUsername 
			WHERE 
				username NOT IN (SELECT username FROM @tmpUsername WHERE searchcount >= 0) 
		)a
	WHERE a.username <> @CurrentUsername
	ORDER BY searchcount DESC, username
END
GO