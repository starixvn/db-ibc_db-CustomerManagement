
ALTER PROCEDURE [dbo].[CustAccountUpdCreditAmt_SAg]
	@CustID INT, --masterID
	@CreditAmt money,
	@SAgID int,	
	@UserID  INT,
	@CreditProblem bit = 0 OUTPUT,
	@Language varchar(2) = 'E',
	@SubAccID int = 0 --Sub-AccountID
AS
--Original:???
--AGENT SITE
--UPDATED 02/22/2006: remove refno
--Used to edit Master Credit
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

declare @Credit_AllAgent money, @Credit_AllOtherMaster money, @Credit_SAg money

Select @Credit_AllOtherMaster = isnull(sum(credit), 0) from custinfo with (NOLOCK) where srecommend = @SAgID and RoleID=3 and CustID <> @CustID
Select @Credit_AllAgent = isnull(sum(credit), 0) from custinfo with (NOLOCK) where mrecommend = @CustID and RoleID=2
Select @Credit_SAg = isnull(credit, 0) from custinfo with (NOLOCK) where custid = @SAgID and roleid = 4

if @Credit_AllAgent > @CreditAmt or @Credit_AllOtherMaster + @CreditAmt > @Credit_SAg
BEGIN
	Select @CreditProblem = 1
	return
END


UPDATE 
	custinfo WITH (ROWLOCK, UPDLOCK)
SET 
	credit=@CreditAmt
WHERE 
	custID = @CustID

DECLARE @LogData NVARCHAR(200)
SELECT @LogData ='Update credit : ' + convert(varchar(20), @CustID) + ' creditamount: ' + convert(varchar(20), @CreditAmt)
---------------------------
-- ***Check Sub-Account***
if @SubAccID > 0
	SET @LogData = 'SubAccountID:' +  convert(varchar(20), @SubAccID) + ' - ' + @LogData
---------------------------
EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

Declare @LogSPData varchar(5000)
Select @LogSPData = 
'CustID='+ coalesce(cast(@CustID as varchar(50)),space(1)) + ',
CreditAmt='+ coalesce(cast(@CreditAmt as varchar(50)),space(1)) + ',
SAgID='+ coalesce(cast(@SAgID as varchar(50)),space(1)) + ',
UserID='+ coalesce(cast(@UserID as varchar(50)),space(1)) + ',
CreditProblem='+ coalesce(cast(@CreditProblem as varchar(50)),space(1)) + ' ,
Language='+ coalesce(cast(@Language as varchar(2)),space(1))+',
SubAccID='+ coalesce(cast(@SubAccID as varchar(50)),space(1)) + '
'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
	@UserID = @UserID,
	@CustID = @CustID,
	@SpName = 'CustAccountUpdCreditAmt_SAg',
	@Doing = @LogSPData
	


GO
GRANT EXECUTE ON [dbo].[CustAccountUpdCreditAmt_SAg] TO [bodbDownlineNet]