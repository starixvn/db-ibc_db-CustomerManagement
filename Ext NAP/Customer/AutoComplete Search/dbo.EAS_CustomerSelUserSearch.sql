/*<info serverAlias="DBAGE-bodb02" executers="bodbExtAccNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE bodb02
GO

ALTER PROC [dbo].[EAS_CustomerSelUserSearch]
	@custid int,
	@username nvarchar(30),
	@groupname varchar(50)	
AS
/*
	Created: 20121105@Dan
	Task : Select downline list of custId based on query string. Used for AutoComplete by "Account Info".
	DB: DBAGE/bodb02
	Original: [Acc_CustomerSelUserSearch]

	Revisions:
		- 20130121@Dan: change linked server DB06 to DBACC, Move sp from DB053/bodb02 to DBEAS/bodb_EAS
		- 20181019@Elodie: Move sp from DBEAS/bodb_EAS to DB053/bodb02

	Param's Explanation:
		• @custid: User who are logging in.
		• @username: part of downline's username.
*/
BEGIN
	SET ARITHABORT ON -- don't remove it, can cause performance problem
	SET NOCOUNT ON

	IF ISNULL(@username,'')='' OR ISNULL(@groupname,'')='' 
		RETURN

	DECLARE @tmpUsername TABLE(username VARCHAR(30),searchcount int)
	
	INSERT INTO @tmpUsername (username,searchcount)
	SELECT TOP 10 username, searchcount
	FROM dbo.CustSearch WITH (NOLOCK) 
	WHERE userid=@custid 
		AND username LIKE CONVERT(VARCHAR(30),'%'+@UserName+'%')
		AND groupname = @groupname		
	ORDER BY [searchcount] DESC

	IF @@ROWCOUNT < 10
	BEGIN
		INSERT INTO @tmpUsername (username,searchcount)
		SELECT TOP 10 username, -1 AS searchcount
		FROM dbo.Customer c WITH (NOLOCK)
			INNER JOIN bodb_AGE.dbo.Acc_CustGroup g WITH(NOLOCK) ON c.srecommend = g.custid
		WHERE c.roleid < 5
			AND username LIKE CONVERT(VARCHAR(30), @UserName+'%')
			AND GroupName = @groupname
		ORDER BY username
	END

	SELECT TOP 10 username 
	FROM 
		(	SELECT 
				username, searchcount
			FROM 
				@tmpUsername  
			WHERE 
				searchcount >= 0
			UNION ALL 
			SELECT 
				username, searchcount
			FROM  
				@tmpUsername 
			WHERE 
				username NOT IN (SELECT username FROM @tmpUsername WHERE searchcount >= 0) 
		)a
	ORDER BY searchcount DESC, username
END
