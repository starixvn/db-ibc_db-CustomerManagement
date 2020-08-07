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
	@MultipliedBy int = 1,
	@Code	nvarchar(3) = '',
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
	@IP VARCHAR(15) = '',
	@OfferSite	TINYINT
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
	
Param's Explanation:
	• @actualrate: specIFy exchange-rate of the currency
	• @minbet: specIFy minbet of the currency

*/
BEGIN
	SET NOCOUNT ON
	DECLARE @IDTemp TABLE (ID TINYINT)
	DECLARE @id TINYINT

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

		SELECT @exchangeid = MIN(t.ID)
		FROM Exchange e WITH (NOLOCK)
			RIGHT JOIN @IDTemp t ON e.ExchangeID = t.ID
		WHERE e.ExchangeID IS NULL

		IF @exchangeid >=100
		BEGIN
			SELECT @ErrMsg = 'Cannot add new currency. The range of ExchangeID from 1 to 99 has been used!', @ErrCode = 102
			RETURN
		END
	END
	ELSE 
	BEGIN
		SELECT @exchangeid = MAX(ExchangeID) + 1
		FROM Exchange e WITH (NOLOCK)

		IF @exchangeid < 1001
			SELECT @exchangeid = 1001
	END

	SET IDENTITY_INSERT exchange ON
	INSERT INTO exchange(exchangeid, actualrate, creator, currency, minbet, minbetlive, GBPRate, EURORate, US$Rate, Description, MultipliedBy, Code, OfferSite, IsActive)
	VALUES (@exchangeid, @actualrate, @UserID, @currency, @minbet, @minbetlive, @GBPRate, @EURORate, @US$Rate, @Description, @MultipliedBy, @Code, @OfferSite, 1)
	SET IDENTITY_INSERT exchange OFF

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
		+  ' ,OfferSite='+ ISNULL(convert(varchar(10),@OfferSite),'')

	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_ExchangeRate
		@UserID = @UserID, 
		@ExchangeID = @exchangeid, 
		@actualrate = @actualrate, 
		@IP = @IP, 
		@Doing = @LogData

END
GO
