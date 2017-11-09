/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,bodbExtAccNet" viewers="vnteam" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_GetCustIDFromUsername]
(
	@Username varchar(30)
)
RETURNS INT
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
	DECLARE @custID INT
	SET @Username = RTRIM(LTRIM(@username))
	
	SELECT @custid = custid
	FROM customer WITH (NOLOCK)
	WHERE username = @Username AND roleid <= 4
	
	IF (@custid IS NULL)
		SELECT @custid = custid
		FROM customer WITH (NOLOCK)
		WHERE username2 = @Username  AND roleid <= 4
	
	IF (@custID IS NULL AND ISNUMERIC(@Username) = 1)
	BEGIN
		SELECT @custid = custid
		FROM customer WITH (NOLOCK)
		WHERE custid = CAST(@username AS INT) AND roleid <= 4
	END
	
	return @custID
		
END
GO