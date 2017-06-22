CREATE PROCEDURE DBA_ChangeCurrencyAndMoveAgent
	@mastername		varchar(40),
	@agentname		varchar(40),
	@NewCurrency varchar(5),
	@userid			int,
	@IP				varchar(15)='',
	@ErrCode		int = 0 OUTPUT,
	@ErrMsg			nvarchar(200) = '' OUTPUT
AS

/*
Created: 
Task : Update currency and move to new master for Agent
DB: DB02.bodb02
Original:

Revisions:
	- 20100109@Daniel: Added
	- 20100112@Kiwi: Amend to write log in xml format.
	
Param's Explanation: 

*/	


-------For test-----------
--select @agentname = 'HIS0188'--agent name
--select @mastername = 'itmaster'--master name
--select @NewCurrency = 'UUS'

Declare @CustID int, @RoleID tinyint, @ExchangeID int, @actualrate float, @OldCurrency varchar(5)
select @CustID = CustID, @RoleID = RoleID, @OldCurrency = e.currency 
from customer c with (nolock) 
	inner join exchange e with (nolock) on c.currency = e.exchangeid
where username = @agentname

select @ExchangeID = ExchangeID, @actualrate = actualrate
from Exchange with (nolock) where currency = @NewCurrency


--change currency on agent

Update Customer set currency = @ExchangeID where recommend = @CustID

Update Custinfo set currency = @ExchangeID where recommend = @CustID

Update Bettrans
	set CurrencyName = @NewCurrency,
		currency = @ExchangeID,
		actualrate = @actualrate,
		virtualrate = @actualrate	
where recommend = @CustID
	--AND status= 'running'
	AND actualrate is NOT NULL
	and winlostdate >= convert(varchar(10),getdate(),112)
	AND bettype NOT IN (71,72,31,32,33,41,42,43,51,52,53,54,55,56,61,62,63,64,65,66, 112, 113, 114)


Update Bettrans
	set CurrencyName = @NewCurrency,
		currency = @ExchangeID,
		actualrate = @actualrate,
		virtualrate = @actualrate	
where recommend = @CustID
	AND status= 'running'
	AND actualrate is NOT NULL
	and winlostdate < convert(varchar(10),getdate(),112)
	AND bettype = 9


--Move agent to new master
EXEC	[dbo].[Acc_CustomerUpdMoveAgent]
		@mastername = @mastername,
		@agentname = @agentname,
		@userid = @userid,
		@IP = @IP,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT


--Write log
declare @LogSPData nvarchar(200)

Select @LogSPData = '<DBA_ChangeCurrencyAndMoveAgent CustId="' + convert(varchar(30),@CustID)
					 + '" CustName="' + convert(varchar(30), @agentname) 
					 + '" Old="' + convert(varchar(10), @OldCurrency)
					 + '" New="' + convert(varchar(10),@NewCurrency) + '"/>'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @userid,
	@CustID = @CustID,
	@ActionID = 805,
	@TrackingValue = @LogSPData	
GO
GRANT VIEW DEFINITION ON [DBA_ChangeCurrencyAndMoveAgent] TO [vnteam]