ALTER PROCEDURE [dbo].[Acc_CustomerUpdChangeCurrency_Super]
	@UserName varchar(50),
	@Currency varchar(5),	
	@UserID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2) = 'E'
AS

/*
Created: 
Task : Update Super currency: Update all the ticket within that day including bets and transfer trans
DB: DBTRANS.bodb02
Original:DBA_ChangeCurrency

Revisions:
	-2008-09-19: add check permission, errors and write log
	-Vinh@20080919: Modified from SP DBA_ChangeCurrency, add check permission, errors and write log
	-2008-11-22: Add update status disable Horseracing
	-20090527@Kiwi: + Add checking for for Finance, Horse, Casino
					+ Use function dbo.f_GetHRAllowedCurr()
	- 20101229@Lukas: Re-arrange bettype
	
Param's Explanation: 

*/		

SET NOCOUNT ON

--

Declare @CustID int, @RoleID tinyint, @ExchangeID int, @actualrate float
Declare @disableHR bit, @disableFI bit, @syncCasino bit
select	@CustID = CustID, 
		@RoleID = RoleID,
		@disableHR = disableHorseracing, 
		@disableFI = disableFinancial, 
		@syncCasino = SyncCasino
from custinfo with (nolock) 
where username = @UserName


---Check Horse Racing, Financials, Casino
if @disableHR = 0 or @disableFI = 0 or @syncCasino = 1
BEGIN
	Select @ErrMsg = case @Language 
					when 'E' then N'This customer is already enabled Horse Racing/Financials/Casino. Cannot Change Currency.'
					when 'CS' then N'This customer is already enabled Horse Racing/Financials/Casino. Cannot Change Currency.'
					else N'This customer is already enabled Horse Racing/Financials/Casino. Cannot Change Currency.'
		end, @ErrCode = 100			
	RETURN
END

if isnull(@RoleID, 0) <> 4
BEGIN
	Select @ErrMsg = case @Language 
					when 'E' then N'Invalid Super.'
					when 'CS' then N'Invalid Super.'
					else N'Invalid Super.'
			end, @ErrCode = 101	
	return
END

if @CustID < 100
BEGIN
	Select @ErrMsg = case @Language 
					when 'E' then N'Cannot change currency for dummy Super.'
					when 'CS' then N'Cannot change currency for dummy Super.'
					else N'Cannot change currency for dummy Super.'
			end, @ErrCode = 102
	return
END

if exists(
	select 1 from bettrans with (nolock)
	where bettype > 20000 and srecommend = @CustID and winlostdate = convert(varchar(10), current_timestamp, 120)
	)
BEGIN
	Select @ErrMsg = case @Language 
					when 'E' then N'Today''s transfer(s) exists!'
					when 'CS' then N'Today''s transfer(s) exists!'
					else N'Today''s transfer(s) exists!'
			end, @ErrCode = 102
	return
END

select @ExchangeID = ExchangeID, @actualrate = actualrate
from Exchange with (nolock) where currency = @Currency
if @ExchangeID is null
BEGIN
	Select @ErrMsg = case @Language 
					when 'E' then N'Invalid currency.'
					when 'CS' then N'Invalid currency.'
					else N'Invalid currency.'
			end, @ErrCode = 103
	return
END


BEGIN TRANSACTION
	Update Customer set currency = @ExchangeID where srecommend = @CustID
	Update Custinfo set currency = @ExchangeID where srecommend = @CustID

	if @Currency NOT IN(select currency From dbo.f_GetHRAllowedCurr())
		Update Custinfo set DisableHorseracing = 1 where srecommend = @CustID

	Update Bettrans
		set CurrencyName = @Currency,
			currency = @ExchangeID,
			actualrate = @actualrate,
			virtualrate = @actualrate	
	where srecommend = @CustID
		--AND status IN ('running', 'waiting')
		AND actualrate is NOT NULL
		AND winlostdate >= convert(varchar(10),getdate(),112)  


	if @@Error <> 0
	BEGIN
		Select @ErrMsg = case @Language 
						when 'E' then N'Update unsuccessful!'
						when 'CS' then N'Update unsuccessful!'
						else N'Update unsuccessful!'
				end, @ErrCode = 104
		ROLLBACK TRANSACTION
		return
	END
COMMIT TRANSACTION

declare @LogData nvarchar(200)
Select @LogData = 'Update currency for Super '
	 + convert(varchar(10),@UserName) + ' with currency ' + 
	 + convert(varchar(10),@Currency)
EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdChangeCurrency_Super] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdChangeCurrency_Super] TO [vnteam]