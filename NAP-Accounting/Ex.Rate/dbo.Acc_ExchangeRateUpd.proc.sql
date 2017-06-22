ALTER PROCEDURE [dbo].[Acc_ExchangeRateUpd]
	@FromExchangeID int,
	@ToExchangeID int,
	@MinActualrate smallmoney,
	@MaxActualrate smallmoney,
	@UserID int,
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2) = 'E'
AS
/*	Created: Jamie
	Task: Insert Min Max Rate between two currencies
	DB: DB03.BODB02 

	Revisions:
		- 20100202@Jamie: Write log to bodb_CustomerLog 

*/

SET NOCOUNT ON
--Check permission for account site: @phuc20080213
EXEC dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[MinMaxExRate]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

/*
	-0.1 <= @MinActualrate <= 0
	0<= @MaxActualrate < 0.1 	
*/


IF @MinActualrate > 0 or @MinActualrate < -0.1 
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N'Min exchange rate must be between -10% and 0%. '
					when 'CS' then N'Min exchange rate must be between -10% and 0%. '
					else N'Min exchange rate must be between -10% and 0%.'
			end, @ErrCode = 102
	return
END

IF @MaxActualrate < 0 or @MaxActualrate > 0.1 
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N'Max exchange rate must be between 0% and 10%. '
					when 'CS' then N'Max exchange rate must be between 0% and 10%. '
					else N'Max exchange rate must be between 0% and 10%.'
			end, @ErrCode = 103
	return
END


IF @MinActualrate > @MaxActualrate
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N'Max exchange rate must be equal to or greater than min exchange rate.  '
					when 'CS' then N'Max exchange rate must be equal to or greater than min exchange rate. '
					else N'Max exchange rate must be equal to or greater than min exchange rate. '
			end, @ErrCode = 104	
	return
END
If not exists(select 1 from acc_exchangerate with(nolock) where FromExchangeID = @FromExchangeID and ToExchangeID = @ToExchangeID)
begin
	Select @ErrMsg = 	case @Language 
					when 'E' then N'The exchange rate does not exist. '
					when 'CS' then N'The exchange rate does not exist. '
					else N'The exchange rate does not exists. '
			end, @ErrCode = 105
	return
end

Update Acc_ExchangeRate
set MinActualrate = abs(@MinActualrate),
	MaxActualrate = @MaxActualrate,
	LastUpdate = getdate()
where FromExchangeID = @FromExchangeID and ToExchangeID = @ToExchangeID

if @@Error <> 0
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N'Exchange rate update fail.'
					when 'CS' then N'Exchange rate update fail.'
					else N'Exchange rate update fail.'
			end, @ErrCode = 106
	return
END

declare @LogData nvarchar(200), @FromExchange varchar(50), @ToExchange varchar(50), @FromActualrate float 

Select	@FromExchange = currency,
		@FromActualrate = actualrate 
From Exchange with(nolock) where ExchangeID = @FromExchangeID
Select @ToExchange = currency From Exchange with(nolock) where ExchangeID = @ToExchangeID
Select @LogData = 'Update Min-Max Rate:' + 
	+ ' FromCurrency=' + @FromExchange
	+ ' ,ToCurrency=' + @ToExchange
	+ '	,MinActualrate=' + convert(varchar(10),@MinActualrate)
	+ ' ,MaxActualrate=' + convert(varchar(10),@MaxActualrate)

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_ExchangeRate 
	@UserID = @UserID, 
	@ExchangeID = @FromExchangeID,
	@Actualrate = @FromActualrate,
	@IP = @IP,
	@Doing = @LogData

-- Record history
Insert into Acc_ExchangeRate_History(ActionDate, ActionType, UserID, FromExchangeID, ToExchangeID, MinActualrate, MaxActualrate) 
Values(getdate(), 2, @UserID, @FromExchangeID, @ToExchangeID, abs(@MinActualrate), @MaxActualrate)

GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeRateUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeRateUpd] TO [VNTeam]
GO 