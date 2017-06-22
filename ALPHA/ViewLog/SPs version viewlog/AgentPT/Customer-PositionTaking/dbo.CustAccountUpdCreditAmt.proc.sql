ALTER PROCEDURE [dbo].[CustAccountUpdCreditAmt]
	@CustID INT, --memberID
	@creditamt FLOAT,
	@AgID int,
	@UserID  INT,
	@CreditProblem bit = 0 OUTPUT,
	@Language varchar(2) = 'E',
	@SubAccID int = 0 --Sub-AccountID
AS
--Original:???
--AGENT SITE
--UPDATED 02/22/2006: remove refno
--UPDATED 03/20/2006: split table Customer
--Used to edit Member Credit
SET NOCOUNT ON


---------------------------
-- ***Check Sub-Account***
Declare @spPageAccess varchar(10)
set @spPageAccess = '[B]' --Update Account - PageAccess for this sp
Declare @SubAllow bit
Exec CustSubCheckPageAccess @SubAccID, @spPageAccess, @Language, @SubAllow OUTPUT
if @SubAllow = 0
	Return
---------------------------

declare @credit float, @ACredit float, @TotalAmt float


select @credit = sum(credit) 
from 
	custinfo with (NOLOCK)
where 
	custinfo.custid<>@CustID  and  custinfo.recommend=@AgID and custinfo.roleid = 1

select  @ACredit = credit
from custinfo with (NOLOCK)
where custid=@AgID

select  @TotalAmt = sum(winlost-actual_stake+playercomm)
from bettrans
where custid = @CustID

Select @Credit = isnull(@Credit, 0), @ACredit = isnull(@ACredit, 0), @TotalAmt = isnull(@TotalAmt, 0), @CreditAmt = isnull(@CreditAmt, 0) 

If @CreditAmt + @TotalAmt < 0
BEGIN
	Select @CreditProblem = 1
	return
END
ELSE IF @Credit + @CreditAmt >= @ACredit
BEGIN
	Select @CreditProblem = 1
	return
END 

UPDATE 
	custinfo WITH (ROWLOCK)
SET 
	credit=@creditamt
WHERE 
	CustID = @CustID
EXEC dbo.CustBetCreditUpdResync @custid= @custid, @resync = 1
-------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @LogData NVARCHAR(200)
SELECT @LogData ='Update member credit : ' + convert(varchar(20), @CustID) + ' creditamount: ' + convert(varchar(20), @creditamt)
---------------------------
-- ***Check Sub-Account***
if @SubAccID > 0
	SET @LogData = 'SubAccountID:' +  convert(varchar(20), @SubAccID) + ' - ' + @LogData
---------------------------
EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

Declare @LogSPData varchar(5000)
Select @LogSPData = 
'CustID='+ coalesce(cast(@CustID as varchar(50)),space(1)) + ',
Creditamt='+ coalesce(cast(@creditamt as varchar(50)),space(1)) + ',
AgID='+ coalesce(cast(@AgID as varchar(50)),space(1)) + ',
UserID='+ coalesce(cast(@UserID as varchar(50)),space(1)) + ',
CreditProblem='+ coalesce(cast(@CreditProblem as varchar(50)),space(1)) + ' ,
Language='+ coalesce(cast(@Language as varchar(2)),space(1))+',
SubAccID='+ coalesce(cast(@SubAccID as varchar(50)),space(1)) + '
'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
	@UserID = @UserID,
	@CustID = @CustID,
	@SpName = 'CustAccountUpdCreditAmt',
	@Doing = @LogSPData
	
GO

GRANT EXECUTE ON [dbo].[CustAccountUpdCreditAmt] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustAccountUpdCreditAmt] TO [vnteam]
