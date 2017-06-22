ALTER PROCEDURE [dbo].[DBA_ChangeCurrency] 
	@UserName varchar(50),
	@NewCurrency varchar(5)
AS
--REMEMBER TO CHECK THE RUNNING MIX PARLAY TICKETS
/*
Created: 
Task : Update Super currency: Update all the ticket within that day including bets and transfer trans
DB: DB02.bodb02
Original:

Revisions:
	2008-11-22: Add update status disable Horseracing
	- 20090527@Kiwi: + Add checking for for Finance, Horse, Casino
					+ Use function dbo.f_GetHRAllowedCurr()
    - 20091212@Kiwi: Add to write logs
	
Param's Explanation: 

*/	

Declare @CustID int, @RoleID tinyint, @ExchangeID int, @actualrate float,
		 @disableHR bit, @disableFI bit, @syncCasino bit, @OldCurrency varchar(5)
select	@CustID = CustID, 
		@RoleID = RoleID,
		@disableHR = disableHorseracing, 
		@disableFI = disableFinancial, 
		@syncCasino = SyncCasino,
		@OldCurrency = e.currency 
from custinfo ci with (nolock)
inner join exchange e with (nolock) on ci.currency = e.exchangeid
where username = @UserName


---Check Horse Racing, Financials, Casino
/*
if @disableHR = 0 or @disableFI = 0 or @syncCasino = 1
BEGIN
	raisError ('This customer is already enabled Horse Racing/Financials/Casino. Cannot Change Currency', 16, 1)
		RETURN
END
*/



select @ExchangeID = ExchangeID, @actualrate = actualrate
from Exchange with (nolock) where currency = @NewCurrency

if @RoleID = 4
BEGIN
	Update Customer set currency = @ExchangeID where srecommend = @CustID
	
	Update Custinfo set currency = @ExchangeID where srecommend = @CustID
	
	if @NewCurrency NOT IN(select currency From dbo.f_GetHRAllowedCurr())
		Update Custinfo set DisableHorseracing = 1 where srecommend = @CustID

	Update Bettrans
		set CurrencyName = @NewCurrency,
			currency = @ExchangeID,
			actualrate = @actualrate,
			virtualrate = @actualrate	
	where srecommend = @CustID
		--AND status= 'running'
		AND actualrate is NOT NULL
		and winlostdate >= convert(varchar(10),getdate(),112)
		AND bettype NOT IN (71,72,31,32,33,41,42,43,51,52,53,54,55,56,61,62,63,64,65,66, 112, 113, 114)
	
	Update Bettrans
		set CurrencyName = @NewCurrency,
			currency = @ExchangeID,
			actualrate = @actualrate,
			virtualrate = @actualrate	
	where srecommend = @CustID
		AND status= 'running'
		AND actualrate is NOT NULL
		and winlostdate < convert(varchar(10),getdate(),112)
		AND bettype = 9
END

--Write log

declare @LogSPData nvarchar(200)
Select @LogSPData = '<DBA_ChangeCurrency CustId="' + convert(varchar(30),@CustID)
					 + '" CustName="' + convert(varchar(30), @UserName) 
					 + '" Old="' + convert(varchar(10), @OldCurrency)
					 + '" New="' + convert(varchar(10),@NewCurrency) + '"/>'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = 8,
	@CustID = @CustID,
	@ActionID = 804,
	@TrackingValue = @LogSPData	

GO
GRANT EXECUTE ON [dbo].[DBA_ChangeCurrency] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_ChangeCurrency] TO [vnteam]