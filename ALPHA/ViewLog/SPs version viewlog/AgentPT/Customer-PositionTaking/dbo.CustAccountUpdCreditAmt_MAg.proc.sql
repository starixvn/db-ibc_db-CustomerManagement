ALTER PROCEDURE [dbo].[CustAccountUpdCreditAmt_MAg]
	@CustID INT, --AgentID
	@CreditAmt money,
	@MAgID int,	
	@UserID  INT,
	@CreditProblem bit = 0 OUTPUT,
	@Language varchar(2) = 'E',
	@SubAccID int = 0 --Sub-AccountID
AS
--Original:???
--AGENT SITE
--UPDATED 02/22/2006: remove refno
--Used to edit Agent Credit
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

declare @Credit_AllMember money, @Credit_AllOtherAgent money, @Credit_MAg money

Select @Credit_AllOtherAgent = isnull(sum(credit), 0) from custinfo with (NOLOCK) where mrecommend = @MAgID and RoleID=2 and CustID <> @CustID
Select @Credit_AllMember = isnull(sum(credit), 0) from custinfo with (NOLOCK) where recommend = @CustID and RoleID=1
Select @Credit_MAg = isnull(credit, 0) from custinfo with (NOLOCK) where custid = @MAgID

print cast(@Credit_AllOtherAgent as varchar(20))
print cast(@Credit_AllMember as varchar(20))
print cast(@Credit_MAg as varchar(20))

if @Credit_AllMember > @CreditAmt or @Credit_AllOtherAgent + @CreditAmt > @Credit_MAg
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
MAgID='+ coalesce(cast(@MAgID as varchar(50)),space(1)) + ',
UserID='+ coalesce(cast(@UserID as varchar(50)),space(1)) + ',
CreditProblem='+ coalesce(cast(@CreditProblem as varchar(50)),space(1)) + ' ,
Language='+ coalesce(cast(@Language as varchar(2)),space(1))+',
SubAccID='+ coalesce(cast(@SubAccID as varchar(50)),space(1)) + '
'
EXEC DBLOG.bodb_CustomerLog.WriteLog_UserLog_RunSP 
	@UserID = @UserID,
	@CustID = @CustID,
	@SpName = 'CustAccountUpdCreditAmt_MAg',
	@Doing = @LogSPData
	

GO

GRANT EXECUTE ON [dbo].[CustAccountUpdCreditAmt_MAg] TO [bodbDownlineNet]