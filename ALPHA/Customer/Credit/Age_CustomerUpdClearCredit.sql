ALTER PROCEDURE [dbo].[Age_CustomerUpdClearCredit] 
	@CustId int,
	@UserId int,
	@SubAccId int = 0, 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IP varchar(15) = '',
	@Language varchar(2) = 'E'
AS

/*	Created by: [QuiMinh]
	Task: clear credit of the specified account and all downline accounts
	Original:Acc_CustomerUpdClearCredit
	DB: DBTXN/bodb02
	Revisions:
		- 20090828@Reviewer: 
		- 20100909@Thien: temporarily disable this function. Fix for member level to count the member balance.	
		- 20110709@Johnson: Change to use new server BD053 instead DB052
		- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
		- 20130218@Dan: Change linked server DB03 to DBPOLICY, DB053 to DBAGE; Write more log on DBTXN server in case of DBLOG server failure
		- 20150707@Jim: exclude Metric Gaming running ticket from bettrans (Feature #38789)
*/

SET NOCOUNT ON
----------------------

--- 20100909@Thien: temporarily disable this function	
    SELECT @ErrMsg = CASE @Language 
						WHEN 'E' THEN N'Sorry, the [Clear All Credit] function is temporarily unavailable!\nThe account was still closed already.'
						ELSE [dbo].[f_Get_MsgNamebyMsgID](70008,@Language)
					 END,
		   @ErrCode = 999			 	
	RETURN

----------------------

--Check disable user
EXEC DBAGE.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT

IF @ErrCode <> 0 RETURN

DECLARE 
		@roleid		tinyint,
		@custLine	varchar(30),
		@username	varchar(50)
DECLARE	@tmpCust TABLE (custid int, Credit money)

SELECT @roleid = roleid, @username = username FROM custinfo WITH (NOLOCK) WHERE custid=@custid

IF ISNULL(@roleid, 0) >= 4
BEGIN
	SELECT @ErrMsg = CASE @Language 
						WHEN 'E' THEN N'Error occurs. This user does not exist. Please try again!'
						ELSE [dbo].[f_Get_MsgNamebyMsgID](40003,@Language)
					 END,
		   @ErrCode = 101					 	
	RETURN	
END

IF @roleid = 3
BEGIN
	Select @custLine =' all lines of master'
	Update custinfo with (ROWLOCK, UPDLOCK) 
	set credit = 0 
	output deleted.custid, deleted.Credit into @tmpCust(custid, Credit)
	where mrecommend = @custid AND Credit != 0 
END
ELSE IF @roleid = 2
BEGIN
	Select @custLine =' all lines of agent'
	Update custinfo with (ROWLOCK, UPDLOCK) 
	set credit = 0 
	output deleted.custid, deleted.Credit into @tmpCust(custid, Credit)
	where recommend = @custid AND Credit != 0 
END
ELSE IF @roleid = 1
BEGIN
	Select @custLine =' member'
	
	DECLARE @TotalAmt money
	
	select  @TotalAmt = sum(winlost-actual_stake+playercomm)
    from bettrans with (nolock)
    where custid = @CustID
		and (
			(bettrans.bettype NOT IN (801,802,803,804,805,806)
			AND ruben =0)
			OR ruben <> 0
			)
    select @TotalAmt = isnull(@TotalAmt, 0)
	
	Update custinfo with (ROWLOCK, UPDLOCK) 
	set credit = case when @TotalAmt >= 0 then 0 else abs(@TotalAmt) end
	output deleted.custid, deleted.Credit into @tmpCust(custid, Credit)
	where custid = @custid AND Credit != 0 
END

-- Write Log Credit
DECLARE @LogSPCredit VARCHAR(500)
SELECT @LogSPCredit = 'Clear credit of ' + @custLine + ': ' +  @username
					  + CASE WHEN @subAccId > 0 THEN ' by sub account ' + dbo.f_GetSubUsername(@SubAccID) ELSE '' END

BEGIN TRY
	INSERT INTO DBLOG.bodb_CustomerLog.dbo.userlog_Credit(userid, custid, OldValue, NewValue, ip, doing, ActionID)
	SELECT	@UserID, custid, Credit, 0, @ip, @LogSPCredit, 1211 
	FROM	@tmpCust 
END TRY
BEGIN CATCH
	Select @LogSPCredit = @LogSPCredit + ' ErrMsg=' + error_message()
	
	INSERT INTO DBLOG.bodb_CustomerLog.dbo.userlog_Credit(userid, custid, OldValue, NewValue, ip, doing, ActionID)
	SELECT	@UserID, custid, Credit, 0, @ip, @LogSPCredit, 1211 
	FROM	@tmpCust 
END CATCH


GO
GRANT EXECUTE ON [dbo].[Age_CustomerUpdClearCredit] TO [wsv_alp]

GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerUpdClearCredit] TO [vnteam]