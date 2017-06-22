
ALTER PROCEDURE Acc_CreditTermSelCheckerList 
	
AS
BEGIN
	SET NOCOUNT ON
	Select c.username , c.custid 
	from accCustomer_1 ac with (nolock)
    INNER JOIN Customer c with (nolock) ON ac.custid = c.custid 
	where groupid = 111 -- From Settlemement group
	    
END
GO
GRANT EXECUTE ON [dbo].[Acc_CreditTermSelCheckerList] TO [bodbAdminNet]
