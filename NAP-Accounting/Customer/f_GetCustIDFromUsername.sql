/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,bodbExtAccNet" viewers="vnteam" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_GetCustIDFromUsername]
(
	@Username varchar(30)
)
RETURNS int
AS
/*
Created: Thien
Task : Get CustID from username. Note that DB06.bodb02 got index on Customer.username and username2
DB: DB06.bodb02
Original:Accounting site
	Revisions:
		- 20120423@Lukas: add filer by roleid 
		- 20171107@Vicky: Support to search customer id on Left panel (#86134)
*/
BEGIN
	declare @custID int
	SET @Username = RTRIM(LTRIM(@username))
	
	select @custid = custid
	from customer with (nolock)
	where username = @Username AND roleid <= 4
	
	if (@custid IS NULL)
		select @custid = custid
		from customer with (nolock)
		where username2 = @Username  AND roleid <= 4
	
	IF(@custID IS NULL AND ISNUMERIC(@Username) = 1)
	BEGIN
		SELECT @custid = custid
		FROM customer with (nolock)
		WHERE custid = CAST(@username as int) AND roleid <= 4
	END
	
	return @custID
		
END
GO