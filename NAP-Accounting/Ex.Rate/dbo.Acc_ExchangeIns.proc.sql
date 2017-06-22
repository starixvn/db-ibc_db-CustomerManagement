USE [CustDB]
GO

ALTER PROC [dbo].[Acc_ExchangeIns]	
	@exchangeid INT OUTPUT,
	@actualrate FLOAT,
	@minbet FLOAT = 0,
	@minbetlive FLOAT = 0,
	@GBPRate FLOAT = NULL,
	@EURORate  FLOAT = NULL,
	@US$Rate  FLOAT  = NULL,
	@currency NVARCHAR(50),
	@Description NVARCHAR(100) = '',
	@MultipliedBy int = 1,
	@Code	nvarchar(3) = '',
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
	@IP VARCHAR(15) = ''
AS
SET NOCOUNT ON
/*
Created: 
Task : Insert new currency
DB: DBCUST.CustDB
Original:

Revisions:
	- 20080213@Phuc: Check permission for account site
	- 20090701@: add param @minbet
	- 20100127@Khoa: add columns @GBPRate AUDRate, ZARRate, EURORate , US$Rate   
	- 20110506@Johnson: Add columns @Description, @MultipliedBy, @Code 
	- 20130822@Lukas: change alias for DB03
	- 20161219@Percy: Remove AUDRate and ZARRate columns [RedmineID: #68649]
Param's Explanation:
	• @actualrate: specIFy exchange-rate of the currency
	• @minbet: specIFy minbet of the currency

*/

EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[ExchangeRate]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
IF @ErrCode <> 0
	RETURN
--END

--check leaguename
IF EXISTS (SELECT 1 FROM Exchange WITH (NOLOCK) WHERE Currency = @Currency)
BEGIN
	SELECT @ErrMsg = 'This currency name is already used.', @ErrCode = 101	
	RETURN
END

INSERT INTO exchange(actualrate, creator, currency, minbet, minbetlive, GBPRate, EURORate, US$Rate, Description, MultipliedBy, Code)
VALUES (@actualrate, @UserID, @currency, @minbet, @minbetlive, @GBPRate, @EURORate, @US$Rate, @Description, @MultipliedBy, @Code)


SELECT @exchangeid=@@IDENTITY

DECLARE @LogData NVARCHAR(200)
SELECT @LogData = 'Add exchange rate:'
	+  ' CurrencyName='+ ISNULL(@currency,'') 
    +  ' ,RMRate=' + ISNULL(convert(VARCHAR(10), @actualrate),'')  
	+  ' ,minbet='+ ISNULL(convert(VARCHAR(10), @minbet),'') 
	+  ' ,minbetlive='+ ISNULL(convert(VARCHAR(10), @minbetlive),'') 
	+  ' ,GBPRate='+ ISNULL(convert(VARCHAR(10), @GBPRate),'') 
	+  ' ,EURORate='+ ISNULL(convert(VARCHAR(10), @EURORate),'') 
	+  ' ,US$Rate='+ ISNULL(convert(VARCHAR(10), @US$Rate),'')
	+  ' ,Description='+ ISNULL(@Description,'')
	+  ' ,MultipliedBy='+ ISNULL(convert(varchar(10),@MultipliedBy),'')
	+  ' ,Code='+ ISNULL(@code,'') 

EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_ExchangeRate
	@UserID = @UserID, 
	@ExchangeID = @exchangeid, 
	@actualrate = @actualrate, 
	@IP = @IP, 
	@Doing = @LogData


GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeIns] TO [ITVivi] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeIns] TO [vnteam] AS [dbo]