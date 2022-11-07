/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExchangeIns]	
	@exchangeid INT OUTPUT,
	@actualrate FLOAT,
	@minbet FLOAT = 0,
	@minbetlive FLOAT = 0,
	@GBPRate FLOAT = NULL,
	@EURORate  FLOAT = NULL,
	@US$Rate  FLOAT  = NULL,
	@currency NVARCHAR(50),
	@Description NVARCHAR(100) = '',
	@MultipliedBy DECIMAL(19,8) = 1,
	@Code	nvarchar(3) = '',
	@UserID INT,
	@IP VARCHAR(15) = '',
	@OfferSite	TINYINT,
	@CurrencyType	TINYINT,
	@CoinMarketCapID	FLOAT = NULL,
	@ErrCode INT = 0			OUTPUT,
	@ErrMsg NVARCHAR(200) = ''	OUTPUT
AS
/*
Created: 
Task : Insert new currency
DB: DBCUST/CustDB
Original:

Revisions:
	- 20080213@Phuc: Check permission for account site
	- 20090701@: add param @minbet
	- 20100127@Khoa: add columns @GBPRate AUDRate, ZARRate, EURORate , US$Rate   
	- 20110506@Johnson: Add columns @Description, @MultipliedBy, @Code 
	- 20130822@Lukas: change alias for DB03
	- 20161219@Percy: Remove AUDRate and ZARRate columns [RedmineID: #68649]
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	- 20200802@Elodie: Add 2 more columns into Exchange table to identify Currency Status & Site [RedmineID: #136023]
	- 20221107@Evan: Support Crypto Currency [RedmineID: #177844]
Param's Explanation:
	• @actualrate: specIFy exchange-rate of the currency
	• @minbet: specIFy minbet of the currency

*/
BEGIN
	SET NOCOUNT ON
	DECLARE @IDTemp TABLE (ID TINYINT)
	DECLARE @id TINYINT, @USDT FLOAT = 1E-20, @Today DATE = GETDATE();

	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[ExchangeRate]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	IF @ErrCode <> 0
		RETURN
	--END

	--check currency name
	IF EXISTS (SELECT 1 FROM Exchange WITH (NOLOCK) WHERE Currency = @Currency)
	BEGIN
		SELECT @ErrMsg = 'This currency name is already used.', @ErrCode = 101	
		RETURN
	END

	IF @OfferSite <> 2
	BEGIN
		SET @id = 1
		WHILE (@id < 100)
		BEGIN
			INSERT INTO @IDTemp (ID) values (@id)
			SELECT @id = @id + 1
		END

		DELETE @IDTemp WHERE ID = 8 -- not used exchangeid = 8, custid = 8 is sa account
		DELETE @IDTemp WHERE ID IN (25,26,29) -- these dummy account aren't created yet

		SELECT @exchangeid = ISNULL(MIN(t.ID),0)
		FROM Exchange e WITH (NOLOCK)
			RIGHT JOIN @IDTemp t ON e.ExchangeID = t.ID
		WHERE e.ExchangeID IS NULL

		IF @exchangeid = 0
		BEGIN
			SELECT @ErrMsg = 'Cannot add new currency. Please contact IT to support!', @ErrCode = 102
			RETURN
		END
	END
	ELSE 
	BEGIN
		SELECT @exchangeid = MAX(ExchangeID) + 1
		FROM Exchange e WITH (NOLOCK)

		IF @exchangeid < 121
			SELECT @exchangeid = 121

		IF @exchangeid > 255
		BEGIN
			SELECT @ErrMsg = 'Cannot add new currency. Please contact IT to support!', @ErrCode = 102
			RETURN
		END
	END

	INSERT INTO exchange(exchangeid, actualrate, creator, currency, minbet, minbetlive, GBPRate, EURORate, US$Rate, Description, MultipliedBy, Code, OfferSite, CurrencyType, stakerate, IsActive)
	VALUES (@exchangeid, @actualrate, @UserID, @currency, @minbet, @minbetlive, @GBPRate, @EURORate, @US$Rate, @Description, @MultipliedBy, @Code, @OfferSite, @CurrencyType,@CoinMarketCapID, 1)

	IF @CurrencyType = 1
	BEGIN 
		INSERT INTO ExchangeDaily_Crypto (ExchangeDate,ExchangeId,USDT)
		SELECT CONVERT(SMALLDATETIME,@Today),@exchangeid,@USDT
	END

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
		+  ' ,MultipliedBy='+ ISNULL(convert(VARCHAR(50),@MultipliedBy),'')
		+  ' ,Code='+ ISNULL(@code,'') 
		+  ' ,OfferSite='+ ISNULL(convert(VARCHAR(10),@OfferSite),'')
		+  ' ,CurrencyType='+ ISNULL(convert(VARCHAR(10),@CurrencyType),'')
		+  ' ,stakerate='+ ISNULL(convert(VARCHAR(10),@CoinMarketCapID),'')

	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_ExchangeRate
		@UserID = @UserID, 
		@ExchangeID = @exchangeid, 
		@actualrate = @actualrate, 
		@IP = @IP, 
		@Doing = @LogData

END
GO
