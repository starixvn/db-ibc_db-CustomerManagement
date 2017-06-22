ALTER PROCEDURE [dbo].[Acc_CustomerUpdUserSearch]
	@userid int,
	@search varchar(30),
	@firstname nvarchar(50) = NULL,
	@lastname nvarchar(50)=NULL,
	@system varchar(50) = 'ACCOUNTING'
AS
/*
Created: 20090723@nqminh
Task : Update to increate number of hits of 'search' term by userid [Used for Agency Site]
DB: DBAGE/bodb02
Original:

Revisions:
    - 20090122@[Reviewer]: [Description of revision]    
	- 20100511@Simon: Add function search by first name and last name.
	- 20100611@Jamie: Modify updating firstname and lastname for using both acc site and agent site 
	- 20100720@Shifu: Add currency when update user
	- 20101119@Johnson: get and add groupname into custsearch
	- 20110725@Sophia: If @search = username2 then do not save data into CustSearch (allow admin search nickname but allow quick search)
	- 20111114@Thien: change to refer to DB06.bodb02.dbo.Customer for query condition on username2
	- 20130121@Dan: change linked server DB06 to DBACC,call to bodb_AGE for Acc_CustGroup
Param's Explanation:
• @userid: userid that currently login.
• @search: the search term.
*/

SET NOCOUNT ON

IF EXISTS (SELECT 1 FROM DBACC.bodb02.dbo.Customer WITH (NOLOCK) WHERE Username2 = @search )
RETURN
ELSE
BEGIN
	Declare @Currency int
	Declare @GroupName varchar(50)

	SELECT @Currency = currency
	FROM Customer with (Nolock)
	WHERE custid = @userid

	IF NOT EXISTS (SELECT userid FROM custsearch (NOLOCK) WHERE userid = @userid AND username=@search)
	BEGIN
		-- Check userid EXISTS or NOT in table custinfo.
		IF EXISTS (SELECT custid FROM custinfo (NOLOCK) WHERE custid = @userid)
		BEGIN
			IF (@system='ACCOUNTING')
			BEGIN
				--Insert
				INSERT INTO custsearch(userid, username, searchcount, firstname, lastname, currency)
				VALUES (@userid, @search, 0, @firstname, @lastname, @Currency)	
			END
			ELSE
			BEGIN
				select @GroupName=groupname from bodb_AGE.dbo.Acc_CustGroup  (nolock)
				WHERE roleid = 4 AND CustID = (SELECT srecommend from custinfo (NOLOCK) WHERE username = @search)
				--Insert
				INSERT INTO custsearch(userid, username, searchcount, firstname, lastname, currency,groupname)
				VALUES (@userid, @search, 0, @firstname, @lastname, @Currency,@GroupName)	
			END
		END
	END
	ELSE
	BEGIN
		IF (@system='ACCOUNTING')
		BEGIN
			--Update count
			UPDATE custsearch WITH (ROWLOCK)
			SET [searchcount] = [searchcount] + 1
				, firstname = CASE WHEN @firstname IS NULL THEN firstname ELSE @firstname END 
				, lastname = CASE WHEN @lastname IS NULL THEN lastname ELSE @lastname END
				, currency = @Currency
			WHERE userid = @userid AND username=@search
		END
		ELSE
		BEGIN
			select @GroupName=groupname from bodb_AGE.dbo.Acc_CustGroup  (nolock)
			WHERE roleid = 4 AND CustID = (SELECT srecommend from custinfo (NOLOCK) WHERE username = @search)
		
			--Update count
			UPDATE custsearch WITH (ROWLOCK)
			SET [searchcount] = [searchcount] + 1
				, firstname = CASE WHEN @firstname IS NULL THEN firstname ELSE @firstname END 
				, lastname = CASE WHEN @lastname IS NULL THEN lastname ELSE @lastname END
				, currency = @Currency
				, groupname = @GroupName
			WHERE userid = @userid AND username=@search
		END
		
	END

END




GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdUserSearch] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdUserSearch] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdUserSearch] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdUserSearch] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdUserSearch] TO [vnteam]