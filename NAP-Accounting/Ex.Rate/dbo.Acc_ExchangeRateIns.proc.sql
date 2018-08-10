/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExchangeRateIns]
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
	DB: DBTXN/bodb02 

	Revisions:
		- 20100202@Jamie: Write log to bodb_CustomerLog 
		- 20180808@Helen: Get Code from Production + DB05.DBPOLICY migration - move to DBTRANS for exchangeRate [Redmine:99462]

*/
BEGIN
		
	SET NOCOUNT ON

	--Check permission for account site: @phuc20080213
	EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[MinMaxExRate]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
	--end

	IF exists(select 1 from Acc_ExchangeRate with(nolock) where FromExchangeID = @FromExchangeID and ToExchangeID = @ToExchangeID) 
	BEGIN
		Select @ErrMsg = 	case @Language 
						when 'E' then N'This exchange rate already existed.'
						when 'CS' then N'This exchange rate already existed.'
						else N'This exchange rate already existed.'
				end, @ErrCode = 101	
		return
	END


	/*
	IF @MinActualrate <= 0
		or @MaxActualrate <= 0
	BEGIN
		Select @ErrMsg = 	case @Language 
						when 'E' then N'Input numbers must be > 0. '
						when 'CS' then N'Input numbers must be > 0. '
						else N'Input numbers must be > 0.'
				end, @ErrCode = 102
		return
	END
	*/

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


	insert into Acc_ExchangeRate(FromExchangeID, ToExchangeID, MinActualrate, MaxActualrate, Creator, LastUpdate)
	values(@FromExchangeID, @ToExchangeID, abs(@MinActualrate), @MaxActualrate, @UserID, getdate())

	if @@Error <> 0
	BEGIN
		Select @ErrMsg = 	case @Language 
						when 'E' then N'Exchange rate insert fail.'
						when 'CS' then N'Exchange rate insert fail.'
						else N'Exchange rate insert fail.'
				end, @ErrCode = 105
		return
	END

	declare @LogData nvarchar(200), @FromExchange varchar(50), @ToExchange varchar(50)

	Select @FromExchange = currency From Exchange with(nolock) where ExchangeID = @FromExchangeID
	Select @ToExchange = currency From Exchange with(nolock) where ExchangeID = @ToExchangeID
	Select @LogData = 'Add exchange rate:' + 
			convert(varchar(50),@FromExchange) + ' -> ' + 
			convert(varchar(50),@ToExchange) + ';' + 
			convert(varchar(10),@MinActualrate) + ';' + 
			convert(varchar(10),@MaxActualrate) + ';IP:' +
			convert(varchar(15),@IP)
	EXEC dbo.WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

	-- Record history
	Insert into Acc_ExchangeRate_History(ActionDate, ActionType, UserID, FromExchangeID, ToExchangeID, MinActualrate, MaxActualrate) 
	Values(getdate(), 1, @UserID, @FromExchangeID, @ToExchangeID, abs(@MinActualrate), @MaxActualrate)

END
GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeRateIns] TO [bodbAdminNet]
GO 
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeRateIns] TO [VNTeam]
