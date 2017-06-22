USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_CustomerSelUserSearch]
	@custid				int,
	@username			nvarchar(30),
	@system				varchar(50) = 'ACCOUNTING',
	@IsAllowFISearch	bit = 1,
	@RoleId				tinyint = 0
AS

/*
Created: 20090610@huynguyen
Task : Select downline list of custId based on query string. Used for AutoComplete by "Account Info".
DB: DBAGE/bodb02 
Original:

Revisions:
    - 20090122@[Reviewer]: [Description of revision]    
	- 20101020@Lukas: add @IsAllowFISearch
	- 20101119@Johnson: Get super from Acc_CustGroup if system is not accounting
	- 20120324@Thien: replace "where username like '%' + @username + '%'" (index scan) by "where username like @username + '%'" (index seek)
	- 20130916@Jamie: Change DB06 to DBACC 
	- 20170120@Percy: add @RoleId to support search by super/master/agent/member [RedmineID: #69445]
	- 20170227@Percy: don't show username including ',' and ';' (super/master/agent/member) [RedmineID: #71342]

Param's Explanation:
	• @custid: User who are logging in.
	• @username: part of downline's username.
	• @RoleId: roleId of @username (0: search all)
*/

SET NOCOUNT ON

DECLARE @tmpUsername TABLE(username VARCHAR(30),searchcount int)

IF(@system = 'ACCOUNTING')
BEGIN
	IF(@IsAllowFISearch = 1)
	BEGIN
		IF @RoleId = 0
		BEGIN
			INSERT INTO @tmpUsername (username,searchcount)
			SELECT TOP 10 username, searchcount
			FROM dbo.custSearch WITH(NOLOCK)
			WHERE userid=@custid AND username LIKE '%' + @username  + '%'
			ORDER BY [searchcount] DESC
		END
		ELSE
		BEGIN
			INSERT INTO @tmpUsername (username,searchcount)
			SELECT TOP 10 ci.username, searchcount
			FROM dbo.custSearch cs WITH(NOLOCK)
				INNER JOIN dbo.CustInfo ci WITH(NOLOCK) ON cs.username = ci.username
			WHERE userid=@custid AND cs.username LIKE '%' + @username  + '%'
				AND cs.username NOT LIKE '%[,;]%'
				AND ci.roleid = @RoleId
			ORDER BY [searchcount] DESC
		END

		IF @@ROWCOUNT < 10
		BEGIN
			INSERT INTO @tmpUsername (username,searchcount)
			SELECT TOP 10 username, -1 AS searchcount
			FROM DBACC.bodb02.dbo.custinfo WITH (NOLOCK)
			WHERE roleid < 5
				AND (@RoleId = 0 OR @RoleId = roleid)
				AND username LIKE @username  + '%'
				AND username NOT LIKE '%[,;]%'
			ORDER BY username
		END
	END
	ELSE   -- @IsAllowFISearch = 0
	BEGIN
		Declare @tbnonFI table (custid int primary key)
		INSERT INTO @tbnonFI(custid)
		select tmp.custid
		from (	select top 10 custid, srecommend, mrecommend, recommend, username 
				from DBACC.bodb02.dbo.custinfo with(nolock)
				where username like  @username + '%'
					and (@RoleId = 0 OR @RoleId = roleid)
			 ) tmp left join custsuper cs with(nolock) on tmp.srecommend = cs.custid
					left join custmaster cm with(nolock) on tmp.mrecommend = cm.custid
					left join custagent ca with(nolock) on tmp.recommend = ca.custid		
		where cs.isinternal = 0 or cm.isinternal = 0 or ca.isinternal = 0

		INSERT INTO @tmpUsername (username,searchcount)
				SELECT top 10 cs.username, searchcount
				FROM custsearch cs with (nolock) 
						inner join @tbnonFI as t on cs.userid = t.custid
				ORDER BY [searchcount] DESC

		IF @@ROWCOUNT < 10
		BEGIN
			INSERT INTO @tmpUsername (username,searchcount)
					select tmp.username, -1 as searchcount
					from (	select top 10 custid, srecommend, mrecommend, recommend, username 
							from DBACC.bodb02.dbo.custinfo ci with(nolock)
							where roleid < 5 and username like @username + '%'
								and (@RoleId = 0 OR @RoleId = roleid)
						 ) tmp left join custsuper cs with(nolock) on tmp.srecommend = cs.custid
								left join custmaster cm with(nolock) on tmp.mrecommend = cm.custid
								left join custagent ca with(nolock) on tmp.recommend = ca.custid
					where cs.isinternal = 0 or cm.isinternal = 0 or ca.isinternal = 0
					ORDER BY username
		END		
	END
END
ELSE	--Others system
BEGIN
	IF @RoleId = 0
	BEGIN
		INSERT INTO @tmpUsername (username,searchcount)
		SELECT TOP 10 username, searchcount
		FROM CustSearch WITH (NOLOCK) 
		WHERE userid=@custid 
				AND username LIKE '%' + @username  + '%'
				AND groupname = @system
		ORDER BY [searchcount] DESC
	END
	ELSE
	BEGIN
		INSERT INTO @tmpUsername (username,searchcount)
		SELECT TOP 10 cs.username, searchcount
		FROM CustSearch cs WITH (NOLOCK)
			INNER JOIN dbo.custInfo ci WITH(NOLOCK) ON cs.username = ci.username
		WHERE userid=@custid 
				AND cs.username LIKE '%' + @username  + '%'
				AND cs.username NOT LIKE '%[,;]%'
				AND ci.roleid = @RoleId
				AND groupname = @system
		ORDER BY [searchcount] DESC
	END

	IF @@ROWCOUNT < 10
	BEGIN
		INSERT INTO @tmpUsername (username,searchcount)
		SELECT TOP 10 username, -1 AS searchcount
		FROM DBACC.bodb02.dbo.custinfo WITH (NOLOCK)
		WHERE roleid < 5
			and (@RoleId = 0 OR @RoleId = roleid)
			AND username LIKE @username  + '%'
			AND username NOT LIKE '%[,;]%'
			AND srecommend IN (SELECT custid FROM bodb_AGE.dbo.Acc_CustGroup WITH(NOLOCK) WHERE GroupName = @System)
		ORDER BY username
	END
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

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelUserSearch] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelUserSearch] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelUserSearch] TO [vnteam]