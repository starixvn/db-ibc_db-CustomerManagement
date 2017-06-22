ALTER PROCEDURE [dbo].[Acc_CustomerUpdChangeCurrency_DirectMaster]
	@UserName varchar(50),
	@Currency varchar(5),	
	@UserID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2) = 'E'
AS

/*
Created: 
Task : Update Direct master currency: Update all the ticket within that day including bets and transfer trans
DB: DBTRANS.bodb02
Original:DBA_ChangeCurrency

Revisions:
	--2008-09-19: add check permission, errors and write log
	--2008-11-22: Add update status disable Horseracing
	-20090527@Kiwi: + Add checking for for Finance, Horse, Casino
					+ Use function dbo.f_GetHRAllowedCurr()
	- 20101229@Lukas: Re-arrange bettype

Param's Explanation: 

*/		

SET NOCOUNT ON

Declare @CustID int, @srecommend int, @RoleID tinyint, @ExchangeID int, @actualrate float
Declare @SuperID int, @disableHR bit, @disableFI bit, @syncCasino bit

select	@CustID = CustID, 
		@RoleID = RoleID, 
		@srecommend = srecommend,
		@disableHR = disableHorseracing, 
		@disableFI = disableFinancial, 
		@syncCasino = SyncCasino
from custinfo with (nolock) where username = @UserName


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

if isnull(@RoleID, 0) <> 3
BEGIN
	Select @ErrMsg = case @Language 
					when 'E' then N'Invalid Master.'
					when 'CS' then N'Invalid Master.'
					else N'Invalid Master.'
			end, @ErrCode = 101	
	return
END

if @srecommend >= 100
BEGIN
	Select @ErrMsg = case @Language 
					when 'E' then N'Master is not direct.'
					when 'CS' then N'Master is not direct.'
					else N'Master is not direct.'
			end, @ErrCode = 102
	return
END

if exists(
	select 1 from bettrans with (nolock)
	where bettype > 20000 and mrecommend = @CustID and winlostdate = convert(varchar(10), current_timestamp, 120)
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

--Find dummy super for changing currency
select @srecommend = custid from customer with (nolock) where custid = @ExchangeID

BEGIN TRANSACTION

	--Move master
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend where custid = @CustID
	update custinfo with (ROWLOCK, UPDLOCK) set srecommend = @srecommend where custid = @CustID

	update bettrans with (ROWLOCK, UPDLOCK) set srecommend = @srecommend where mrecommend = @CustID
	update bettrans14 with (ROWLOCK, UPDLOCK) set srecommend = @srecommend where mrecommend = @CustID
	update sum_winloss with (ROWLOCK, UPDLOCK) set srecommend = @srecommend where mrecommend = @CustID

	--update currency
	Update Customer with (ROWLOCK, UPDLOCK) set currency = @ExchangeID where mrecommend = @CustID
	Update Custinfo with (ROWLOCK, UPDLOCK) set currency = @ExchangeID where mrecommend = @CustID
	
	--Disable Horse Racing if new currency is now allowed
	if @Currency NOT IN(select currency From dbo.f_GetHRAllowedCurr())
		Update Custinfo set DisableHorseracing = 1 where mrecommend = @CustID
	

	Update Bettrans
		set CurrencyName = @Currency,
			currency = @ExchangeID,
			actualrate = @actualrate,
			virtualrate = @actualrate	
	where mrecommend = @CustID
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
Select @LogData = 'Update currency for direct Master '
	 + convert(varchar(10),@UserName) + ' with currency ' + 
	 + convert(varchar(10),@Currency)
EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdChangeCurrency_DirectMaster] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdChangeCurrency_DirectMaster] TO [vnteam]