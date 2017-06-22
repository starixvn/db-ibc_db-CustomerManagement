ALTER PROCEDURE [dbo].[Acc_CustomerSelVirtualRateHistory]	
	@CustID INT
AS
/*
Created: 
Task : View change history of virtual rate
DB: DBLOG.bodb_CustomerLog
Original: 
Revisions:	
	- 20091106@Simon: View change history of virtual rate
	- 20100512@Kiwi: Retrieve data from TrackingValue rather than doing.
	- 20110923@Henry: show logs that updated from LRF
	- 20141231@Johnson: separate virtual rate settings by sporttype bettype [Redmine: #25840]
Explanations:
ActionID: 801, SPName: Acc_CustomerUpdVirtualMultiplier
ActionID: 802, SPName: Acc_VirtualRateMulUpd
*/
BEGIN
SET NOCOUNT ON			
	SELECT TOP 10 logdate,	
		ActionID,	
		TrackingValue,
		Username =	CASE 
						when (ActionID IN (2800,2802)) then 'LRF Admin'
						ELSE c.Username
					END
	FROM UserLog_RunSP u WITH(NOLOCK)
	LEFT JOIN bodb02.dbo.CustInfo c WITH(NOLOCK) ON c.custid = u.userid
	WHERE u.custid = @CustID
		AND ActionID IN (801,802,806,807,2800,2802)
	ORDER BY logdate DESC
END	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelVirtualRateHistory] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelVirtualRateHistory] TO [vnteam]
