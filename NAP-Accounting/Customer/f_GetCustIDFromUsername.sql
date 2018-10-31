/*<info serverAlias="DBACC-bodb02, DBCUST-CustDB" executers="bodbAdminNet,bodbExtAccNet" viewers="vnteam" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_GetCustIDFromUsername]
(
	@Username varchar(30)
)
RETURNS int
AS
/*
Created: Thien
Task : Get CustID from username. Note that DB06.bodb02 got index on Customer.username and username2
DB: DBACC/bodb02, DBCUST/CustDB
Original:Accounting site
	Revisions:
		- 20120423@Lukas: add filer by roleid 
		- 20171107@Vicky: Support to search customer id on Left panel (#86134)
*/
BEGIN
	declare @custID int
	
	SET @Username = RTRIM(LTRIM(@Username))
	
	IF (@Username = '')
		RETURN @custID
	
	select @custid = custid
	from customer with (nolock)
	where username = @Username AND roleid <= 4

	if (@custid IS NULL)
		select @custid = custid
		from customer with (nolock)
		where username2 = @Username  AND roleid <= 4
	
	return @custID
		
END


GO
