/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_ExchangeUpd]
	@exchangeid int,
	@actualrate FLOAT,
	@minbet FLOAT = 0,
	@minbetlive FLOAT = 0,
	@GBPRate FLOAT = NULL,
	@EURORate FLOAT = NULL,
	@US$Rate  FLOAT = NULL,
	@currency NVARCHAR(50),
	@Description Nvarchar(100) = '',
	@MultipliedBy DECIMAL(19,8) = 1,	
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
	@IP VARCHAR(15) = '',
	@OfferSite	TINYINT,
	@IsActive BIT
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
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20190627@Elodie: Apply currency min bet constrain for Bet Setting [Redmine:#115126]
		- 20200802@Elodie: Add 2 more columns into Exchange table to identify Currency Status & Site [RedmineID: #136023]
		- 20220401@Evan: In-house Replication (RepUpdateTime) [RedmineID: #170752]
		- 20221109@Eddie: Change datatype of @MultipliedBy to Decimal  [RedmineID: #180318]

	Param's Explanation:
	• @actualrate: new rate to update
	• @minbet: update new minbet 
*/
BEGIN
	SET NOCOUNT ON

	--Check permission for account site: @phuc20080213
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[ExchangeRate]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	If @ErrCode <> 0
		RETURN
	--end

	DECLARE 
		@LogData nvarchar(400),
		@old_minbet FLOAT ,
		@old_minbetlive FLOAT ,
		@old_actualrate FLOAT,
		@old_GBPRate FLOAT ,
		@old_EURORate FLOAT ,
		@old_US$Rate FLOAT ,	
		@old_currency NVARCHAR(50),
		@old_Description nvarchar(100),
		@old_MultipliedBy INT,
		@old_OfferSite	TINYINT,
		@old_IsActive BIT

	SELECT 
		@old_minbet = minbet,
		@old_minbetlive = minbetlive,
		@old_actualrate = actualrate,
		@old_GBPRate = GBPRate,
		@old_EURORate = EURORate,
		@old_US$Rate = US$Rate,	
		@old_currency = currency,
		@old_Description = Description,
		@old_MultipliedBy = MultipliedBy,
		@old_OfferSite = OfferSite,
		@old_IsActive = IsActive
	FROM exchange WITH (NOLOCK) 
	WHERE exchangeid=@exchangeid

	IF @old_OfferSite = 1 AND @OfferSite = 2
	BEGIN
		SELECT @ErrMsg = 'You cannot update Offer Site from Credit to Deposit', @ErrCode = 101
		RETURN
	END
	IF @old_OfferSite = 0 AND @OfferSite <> @old_OfferSite
	BEGIN
		SELECT @ErrMsg = 'You cannot update Offer Site from All to Credit/Deposit', @ErrCode = 102
		RETURN
	END
	IF @old_OfferSite = 2 AND @OfferSite <> @old_OfferSite
	BEGIN
		SELECT @ErrMsg = 'You cannot update Offer Site from Deposit to All/Credit', @ErrCode = 103
		RETURN
	END

	UPDATE exchange 
	SET 
		actualrate=@actualrate, 
		minbet=@minbet,
		minbetlive=@minbetlive,
		GBPRate = CASE WHEN ISNULL(@GBPRate,-1) > -1 THEN @GBPRate ELSE GBPRate END,
		EURORate = CASE WHEN ISNULL(@EURORate,-1) > -1 THEN @EURORate ELSE EURORate END,
		US$Rate = CASE WHEN ISNULL(@US$Rate,-1) > -1 THEN @US$Rate ELSE US$Rate END,
		Description = @Description,
		MultipliedBy = @MultipliedBy,
		OfferSite = @OfferSite,
		IsActive = @IsActive,
		RepUpdateTime = SYSDATETIME()
	WHERE exchangeid=@exchangeid

	IF @old_minbet <> @minbet OR @old_minbetlive <> @minbetlive 
	BEGIN
		--Sync minbet of SB to CS_ProductBetSetting for CN88
		UPDATE dbo.CS_ProductBetSetting 
		SET minbet = CASE WHEN islive = 0 THEN @minbet ELSE @minbetlive END
		WHERE Currency = @exchangeid AND (SportType BETWEEN 1 AND 99 OR SportType = 9999)
	END

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
		+  ' ,newMultipliedBy='+ ISNULL(convert(varchar(50),@MultipliedBy),'')	
		+  ' ,oldOfferSite='+ ISNULL(convert(varchar(10),@old_OfferSite),'')
		+  ' ,newOfferSite='+ ISNULL(convert(varchar(10),@OfferSite),'')	
		+  ' ,oldIsActive='+ ISNULL(convert(varchar(10),@old_IsActive),'')
		+  ' ,newIsActive='+ ISNULL(convert(varchar(10),@IsActive),'')	
		
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_ExchangeRate
		@UserID = @UserID, 
		@ExchangeID = @exchangeid, 
		@actualrate = @actualrate, 
		@IP = @IP, 
		@Doing = @LogData

END
GO
