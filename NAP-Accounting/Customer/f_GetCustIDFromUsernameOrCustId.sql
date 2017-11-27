/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,bodbExtAccNet" viewers="vnteam" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[f_GetCustIDFromUsernameOrCustId]
(
	@Username varchar(30),
	@CheckCustId TINYINT = 0
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
	SET @Username = RTRIM(LTRIM(@Username))
	
	SELECT @custID = custid
	FROM customer WITH (NOLOCK)
	WHERE username = @Username AND roleid <= 4
	
	IF (@custID IS NULL)
		SELECT @custID = custid
		FROM customer WITH (NOLOCK)
		WHERE username2 = @Username  AND roleid <= 4
	
	IF (@CheckCustId <> 0 AND @custID IS NULL AND ISNUMERIC(@Username) = 1
		AND ((LEN(@Username) BETWEEN 1 AND 9) OR (LEN(@Username) = 10 AND @Username <= '2147483647'))) --check overflow 
	   )
	BEGIN
		SELECT @custID = custid
		FROM customer WITH (NOLOCK)
		WHERE custid = CAST(@Username AS INT) AND roleid <= 4
	END
	
	RETURN @custID
		
END
GO