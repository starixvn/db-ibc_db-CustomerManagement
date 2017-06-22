ALTER PROCEDURE [dbo].[Acc_CustomerSelCustomerInfo] 
	@CustID INT = null,
	@Username NVARCHAR(50) = null
AS
/*
Created: 
Task : Get User Information
DB: DBCUST.CustDB
Original:Accounting site

Revisions:
	- 20090912@Shifu: Get User Information by CustID or Username
	- 20120405@Johnson: get status of live casino
	- 20120504@Johnson: get superid, masterid 
	- 20150609@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
*/	
SET NOCOUNT ON
IF @CustID IS NOT NULL
BEGIN
	Select site, e.currency
	from Customer with (NOLOCK)
	INNER JOIN Exchange AS e with (NOLOCK) ON Customer.Currency = e.ExchangeID
	where CustID = @CustID
END
ELSE IF @Username IS NOT NULL
BEGIN
	Select ISNULL(c.DisableCasino,0) AS DisableCasino,	
		ISNULL(c.synccasino,0) AS synccasino,	
		ISNULL(c.SyncLiveCasino,0) as SyncLiveCasino,
		m.custid as MasterID,
		m.username as MasterName,
		s.username as SuperName,
		s.custid as SuperID,
		c.custid
	FROM custinfo c with (nolock)		
		LEFT JOIN custinfo m with (nolock) ON c.mrecommend = m.custid
		LEFT JOIN custinfo s with (nolock) ON c.srecommend = s.custid
	WHERE c.username = @Username
END



GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCustomerInfo] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCustomerInfo] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCustomerInfo] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCustomerInfo] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelCustomerInfo] TO [vnteam]
