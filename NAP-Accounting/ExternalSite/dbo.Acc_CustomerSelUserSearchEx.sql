

/****** Object:  StoredProcedure [dbo].[Acc_CustomerSelUserSearchEx]    Script Date: 05/29/2010 10:00:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_CustomerSelUserSearchEx]
	@custid int,
	@username varchar(30),
	@Currency int = 43
AS

/*
Created: 20090610@huynguyen
Task : Select downline list of custId based on query string. Used for AutoComplete by "Account Info".
DB: DB03.bodb02
Original:

Revisions:
    - 20090122@[Reviewer]: [Description of revision]    
	- 20100518@Lewin: Add currencyid to param list. 
	- 20100603@Lewin: Change param currencyid to currency

Param's Explanation:
	- @custid: User who are logging in.
	- @username: part of downline's username.
	- @Currency: valid currency id
*/

SET NOCOUNT ON

DECLARE @tmpUsername TABLE(username VARCHAR(30),searchcount INT)

INSERT INTO @tmpUsername (username,searchcount)
	SELECT TOP 10 username, searchcount
	FROM CustSearchEx WITH (NOLOCK) 
	WHERE userid=@custid 
			AND username LIKE '%' + @username  + '%'
			AND Currency = @Currency
			AND dbo.f_IsDummySuper(userid) = 0
	ORDER BY [searchcount] DESC

IF @@ROWCOUNT < 10
BEGIN
	INSERT INTO @tmpUsername (username,searchcount)
	SELECT TOP 10 username, -1 AS searchcount
	FROM custinfo WITH (NOLOCK)
	WHERE roleid < 5
		AND username LIKE @username  + '%'
		AND Currency = @Currency
		AND dbo.f_IsDummySuper(custid) = 0
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
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelUserSearchEx] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelUserSearchEx] TO [vnteam]

