ALTER  PROCEDURE [dbo].[Age_CustomerUpdUserSearch]
	@userid int,
	@username varchar(30) 
AS
/*
Created: 20090723@nqminh
Task : Update to increate number of hits of 'search' term by userid
DB: DB03.bodb02
Original:

Revisions:
    - 20090122@[Reviewer]: [Description of revision]    

Param's Explanation:
• @userid: userid that currently login.
• @search: the search term.
*/

SET NOCOUNT ON

IF NOT EXISTS (SELECT userid FROM custsearch (NOLOCK) WHERE userid = @userid AND username=@username)
BEGIN
	--Insert
	INSERT INTO custsearch(userid, username, searchcount)
	VALUES (@userid, @username, 0)
END
ELSE
BEGIN
	--Update count
	UPDATE custsearch WITH (ROWLOCK)
	SET [searchcount] = [searchcount] + 1
	WHERE userid = @userid AND username=@username
END
