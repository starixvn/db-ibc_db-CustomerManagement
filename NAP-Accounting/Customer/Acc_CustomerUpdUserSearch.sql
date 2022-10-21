/*<info serverAlias="DBCUST-CustDB" executers="bodbadminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdUserSearch]
	@userid int,
	@search varchar(30),
	@firstname nvarchar(50) = NULL,
	@lastname nvarchar(50)=NULL,
	@username2 VARCHAR(50)= NULL,
	@system varchar(50) = 'ACCOUNTING'
AS
/*
	Created: 20090723@nqminh
	Task : Update to increate number of hits of 'search' term by userid [Used for Agency Site]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20090122@[Reviewer]: [Description of revision]    
		- 20100511@Simon: Add function search by first name and last name.
		- 20100611@Jamie: Modify updating firstname and lastname for using both acc site and agent site 
		- 20100720@Shifu: Add currency when update user
		- 20101119@Johnson: get and add groupname into custsearch
		- 20110725@Sophia: If @search = username2 then do not save data into CustSearch (allow admin search nickname but allow quick search)
		- 20111114@Thien: change to refer to DB06.bodb02.dbo.Customer for query condition on username2
		- 20130916@Jamie: Change DB06 to DBACC
		- 20181122@Elodie: DB053/bodb_Age Migration [Redmine:#104770]
		- 20190508@Elodie: Allow to search nickname [Redmine: #113044]
		- 20221012@Eden: Enhance searching customer account [Redmine: #178984]

	Param's Explanation:
		• @userid: userid that currently login.
		• @search: the search term.
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @Currency INT

	SELECT @Currency = currency
	FROM Customer WITH(NOLOCK)
	WHERE custid = @userid

	IF @Currency IS NULL  --invalid userid
		RETURN

	SET @system = ISNULL(@system,'')

	IF (@system != 'ACCOUNTING')
	BEGIN
		SET @username2 = NULL
	END

	IF EXISTS (SELECT 1 FROM custsearch (NOLOCK) WHERE userid = @userid AND username=@search)
	BEGIN
		--Update count
		UPDATE custsearch WITH (ROWLOCK,UPDLOCK)
		SET [searchcount] = [searchcount] + 1
			, firstname = CASE WHEN @firstname IS NULL THEN firstname ELSE @firstname END 
			, lastname = CASE WHEN @lastname IS NULL THEN lastname ELSE @lastname END
			, currency = @Currency
			, username2 = CASE WHEN @system = 'ACCOUNTING' THEN @username2 ELSE username2 END
		WHERE userid = @userid AND username=@search
	END
	ELSE
	BEGIN
		INSERT INTO custsearch(userid, username, searchcount, firstname, lastname, currency, username2)
		SELECT @userid, @search, 0, @firstname, @lastname, @Currency, @username2	
		WHERE NOT EXISTS (SELECT TOP 1 1 FROM custsearch WITH(ROWLOCK,UPDLOCK)  WHERE userid = @userid AND username=@search)
	END
END