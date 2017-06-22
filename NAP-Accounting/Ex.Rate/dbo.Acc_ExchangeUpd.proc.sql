USE [CustDB]
GO

ALTER PROC [dbo].[Acc_ExchangeUpd]
	@exchangeid int,
	@actualrate FLOAT,
	@minbet FLOAT = 0,
	@minbetlive FLOAT = 0,
	@GBPRate FLOAT = NULL,
	@EURORate FLOAT = NULL,
	@US$Rate  FLOAT = NULL,
	@currency NVARCHAR(50),
	@Description Nvarchar(100) = '',
	@MultipliedBy int = 1,	
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
	@IP VARCHAR(15) = ''
AS

/*
Created: ?
Task : Update ex rate

DB: DBCUST.CustDB
Original: 

Revisions: 
	- 20091025@Peter: Call SP update Aff's ex.Rate
	- 20091027@Daniel: Change to writelog to table userlog_exchange instead
	- 20100127@Khoa: add columns GBPRate, AUDRate, ZARRate, EURO, USD
	- 20100504@Peter :  Remove the calling to SP [DB052].[Affiliate_12BET].[dbo].[Aff_AccUpdateExchange]
	                    coz it will be updated on Affiliate Admin
	- 20110605@Johnson: Add columns Description, MultipliedBy       
	- 20130822@Lukas: change alias for DB03
	- 20161219@Percy: Remove AUDRate and ZARRate columns [RedmineID: #68649]
Param's Explanation:
• @actualrate: new rate to update
• @minbet: update new minbet 


*/

SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[ExchangeRate]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end


declare 
	@LogData nvarchar(400),
	@old_minbet FLOAT ,
	@old_minbetlive FLOAT ,
	@old_actualrate FLOAT,
	@old_GBPRate FLOAT ,
	@old_EURORate FLOAT ,
	@old_US$Rate FLOAT ,	
	@old_currency NVARCHAR(50),
	@old_Description nvarchar(100),
	@old_MultipliedBy int


select 
	@old_minbet = minbet,
	@old_minbetlive = minbetlive,
	@old_actualrate = actualrate,
	@old_GBPRate = GBPRate,
	@old_EURORate = EURORate,
	@old_US$Rate = US$Rate,	
	@old_currency = currency,
	@old_Description = Description,
	@old_MultipliedBy = MultipliedBy	
from exchange with (nolock) where exchangeid=@exchangeid

UPDATE exchange SET 
	actualrate=@actualrate, 
	minbet=@minbet,
	minbetlive=@minbetlive,
	GBPRate = CASE WHEN ISNULL(@GBPRate,-1) > -1 THEN @GBPRate ELSE GBPRate END,
	EURORate = CASE WHEN ISNULL(@EURORate,-1) > -1 THEN @EURORate ELSE EURORate END,
	US$Rate = CASE WHEN ISNULL(@US$Rate,-1) > -1 THEN @US$Rate ELSE US$Rate END,
	Description = @Description,
	MultipliedBy = @MultipliedBy
WHERE exchangeid=@exchangeid


Select @LogData = 'Update exchange rate:'
	+  ' currencyName=' + @currency 
	+  ' ,newRMRate=' + ISNULL(convert(VARCHAR(10), @actualrate),'')  
	+  ' ,oldRMRate=' + ISNULL(convert(VARCHAR(10), @old_actualrate),'')  
	+  ' ,newminbet='+ ISNULL(convert(VARCHAR(10), @minbet),'') 
	+  ' ,oldminbet='+ ISNULL(convert(VARCHAR(10), @old_minbet),'') 
	+  ' ,newminbetlive='+ ISNULL(convert(VARCHAR(10), @minbetlive),'') 
	+  ' ,oldminbetlive='+ ISNULL(convert(VARCHAR(10), @old_minbetlive),'') 
	+  ' ,newGBPRate='+ ISNULL(convert(VARCHAR(10), @GBPRate),'') 
	+  ' ,oldGBPRate='+ ISNULL(convert(VARCHAR(10), @old_GBPRate),'') 
	+  ' ,newEURORate='+ ISNULL(convert(VARCHAR(10), @EURORate),'') 
	+  ' ,oldEURORate='+ ISNULL(convert(VARCHAR(10), @old_EURORate),'') 
	+  ' ,newUS$Rate='+ ISNULL(convert(VARCHAR(10), @US$Rate),'') 
	+  ' ,oldUS$Rate='+ ISNULL(convert(VARCHAR(10), @old_US$Rate),'') 
	+  ' ,oldDescription='+ ISNULL(@old_Description,'')
	+  ' ,newDescription='+ ISNULL(@Description,'')
	+  ' ,oldMultipliedBy='+ ISNULL(convert(varchar(10),@old_MultipliedBy),'')
	+  ' ,newMultipliedBy='+ ISNULL(convert(varchar(10),@MultipliedBy),'')	
	

EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_ExchangeRate
	@UserID = @UserID, 
	@ExchangeID = @exchangeid, 
	@actualrate = @actualrate, 
	@IP = @IP, 
	@Doing = @LogData


GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeUpd] TO [ITVivi] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeUpd] TO [vnteam] AS [dbo]