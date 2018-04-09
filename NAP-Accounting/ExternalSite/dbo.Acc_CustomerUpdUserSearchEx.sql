

/****** Object:  StoredProcedure [dbo].[Acc_CustomerUpdUserSearchEx]    Script Date: 05/29/2010 09:59:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_CustomerUpdUserSearchEx]
	@userid int,
	@search varchar(30),
	@Currency int = 43/*THB*/
AS
/*
Created: 20090723@huynguyen
Task : Update to increate number of hits of 'search' term by userid
DB: DB05.bodb02
Original:

Revisions:
    - 20090122@[Reviewer]: [Description of revision]    
	- 20100511@Simon: Add function search by first name and last name.
	- 20100518@Simon: Add currency id
	- 20100529@Lewin: Update data into table  CustSearchEx in lieu of CustSearch #IRP 411
	- 20100603@Lewin: Change CurrencyId to Curency
Param's Explanation:
	- @userid: userid that currently login.
	- @search: the search term.
	- @Currency
*/

SET NOCOUNT ON

IF NOT EXISTS (
	 SELECT userid FROM CustSearchEx WITH (NOLOCK) 
		WHERE   UserId = @userid 
				AND Username=@search
				AND Currency = @Currency
)
BEGIN
	--Insert
	INSERT INTO CustSearchEx(UserId, Username, SearchCount, Currency)
	VALUES (@userid, @search, 0, @Currency)
END
ELSE
BEGIN
	--Update count	
	UPDATE CustSearchEx WITH (ROWLOCK)
	SET [searchcount] = [searchcount] + 1
	WHERE userid = @userid 
			AND username=@search
			AND Currency = @Currency
END


GRANT EXECUTE ON [dbo].[Acc_CustomerUpdUserSearchEx] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdUserSearchEx] TO [vnteam]
