/*<info serverAlias="DBACC-bodb02, DBCUST-CustDB, DBAGE-bodb02" executers="bodbAdminNet,bodbExtAccNet" viewers="" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_GetCustIDFromUsernameOrCustId]
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
		- 20191119@Tiara: Replacing ISNUMERIC function by PATINDEX to check numeric (#123972)
		- 20200525@Malcolm: Add metadata [Redmine : #128128]
		- 20210616@Winfred: NAP -Left Panel -Allow to search sub account nickname [Redmine: #155713]
		- 20230421@Elodie: Deploy on DBAGE-bodb02 [Redmine: #169643]
*/
BEGIN
	DECLARE @custID INT
	SET @Username = RTRIM(LTRIM(@Username))
	
	IF (@Username = '')
		RETURN @custID
	
	SELECT @custID = custid
	FROM customer WITH (NOLOCK)
	WHERE username = @Username AND roleid <= 4
	
	IF (@custID IS NULL)
		SELECT @custID = custid
		FROM customer WITH (NOLOCK)
		WHERE username2 = @Username  AND roleid <= 4
		
	IF (@custID IS NULL)
		SELECT @custID = a.custid
		FROM custSub a WITH (NOLOCK)
		WHERE a.username = @Username  	
	
	IF (@custID IS NULL)
		SELECT @custID = a.custid
		FROM custSub a WITH (NOLOCK)
		WHERE a.UserName2 = @Username  		
	
	IF (@CheckCustId <> 0 AND @custID IS NULL AND ~(CAST(PATINDEX('%[^0-9]%',@Username) as BIT)) = 1
		AND ((LEN(@Username) BETWEEN 1 AND 9) OR (LEN(@Username) = 10 AND @Username <= '2147483647'))) --check overflow 
	BEGIN
		SELECT @custID = custid
		FROM customer WITH (NOLOCK)
		WHERE custid = CAST(@Username AS INT) AND roleid <= 4
		
		IF (@custID IS NULL)
			SELECT @custID = a.custid
			FROM custSub a WITH (NOLOCK)
			WHERE a.subaccid = CAST(@Username AS INT)	
		
	END
	
	RETURN @custID
		
END
GO