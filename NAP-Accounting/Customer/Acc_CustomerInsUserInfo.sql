
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Acc_CustomerInsUserInfo    Script Date: 12/2/2015 2:23:51 PM ******/
CREATE PROCEDURE [dbo].[Acc_CustomerInsUserInfo]
	@custid INT OUTPUT,
	@firstname NVARCHAR(50),
	@lastname NVARCHAR(50),
	@creator INT,
	@username VARCHAR(30),
	@userpwd VARCHAR(40),
	@pwdexpiry DATETIME,
	@currency INT,
	@site NVARCHAR(50),
	@ugroup VARCHAR(5) = NULL,

	@srecommend INT,
	@mrecommend INT,
	@recommend INT,
	@roleid INT,
	
	@Danger TINYINT = 0,
	@Danger2 TINYINT = 0,
	@Danger3 TINYINT = 0,
	@Abnormal TINYINT = 0,
	
	@phone NVARCHAR(50),
	@mobilephone NVARCHAR(50),
	@email NVARCHAR(50),
	@fax NVARCHAR(50),
	@address NVARCHAR(80),
	@city NVARCHAR(50),
	@state NVARCHAR(50),
	@country NVARCHAR(50),
	@postal NVARCHAR(50),
	@TransferOption VARCHAR(8) = NULL, --pass value (not NULL) in case direct master add new agent
	@suspended BIT = NULL,

	@closed BIT = NULL,
	@Disable151_31 BIT = 0, --@DisableHorseRacing -> @Disable151_31
	@Disable151_41 BIT=0, -- @DisableOpenTote -> @Disable151_41
	@Disable151_51 BIT = 0,-- @Disable151_AU -> @Disable151_51
	@Disable152_41 BIT = 0,-- @Disable152_UK -> @Disable152_41
	@Disable152_51 BIT = 0,-- @Disable152_AU -> @Disable152_51
	@Disable153_51 BIT = 0,-- @Disable153_AU -> @Disable153_51
	@DisableOutright BIT = 0,
	@matchlimit SMALLMONEY,
	@virtualmultiplier SMALLMONEY,
	@DisableFinancial BIT = 0,
	@DisableAutoMPT BIT = 1,
	@IsInternal BIT = 0,
	
	@autosuspend BIT = 0,
	@autosuspend2 BIT = 0,

	@MaxPerMatch MONEY,
	@MaxPerMatchv2 MONEY,
	@MaxPerMatchv3 MONEY,
	@MaxPerMatchv5 MONEY,
	@MaxPerMatchv8 MONEY,
	@MaxPerMatchv10 MONEY,
	@MaxPerMatchv11 MONEY,
	@MaxPerMatchv44 MONEY=0,
	--v201
	@MaxPerMatchv201 MONEY = 0,
	
	--v151
	@MaxPerMatchv151_31 MONEY = 0,-- @MaxPerMatchv151 -> @MaxPerMatchv151_31
	@MaxPerMatchv151_41 MONEY = 0,-- @MaxPerMatchv151OT -> @MaxPerMatchv151_41
	@MaxPerMatchv151_51 MONEY = 0,-- @MaxPerMatchv151_AU -> @MaxPerMatchv151_51
	
	--v152
	@MaxPerMatchv152_41 MONEY = 0,-- @MaxPerMatchv152_UK -> @MaxPerMatchv152_41
	@MaxPerMatchv152_51 MONEY = 0,--@MaxPerMatchv152_AU -> @MaxPerMatchv152_51
	
	--v153
	@MaxPerMatchv153_51 MONEY =0,-- @MaxPerMatchv153_AU -> @MaxPerMatchv153_51
	
	--HRFixedOdds
	@MaxPerMatchv154 MONEY = 0,
	
	@MaxPerMatchv99 MONEY,
	@MaxPerMatchv99MP MONEY,	
	@MaxPerMatchv161 MONEY,	
	@MaxPerBallv161 MONEY = 0,	
	-- VS
	@MaxPerMatchv180 MONEY = 0,
	@MaxPerMatchv181 MONEY = 0,
	@MaxPerMatchv182 MONEY = 0,
	@MaxPerMatchv183 MONEY = 0,
	@MaxPerMatchv184 MONEY = 0,
	@MaxPerMatchv185 MONEY = 0,
	@MaxPerMatchv186 MONEY = 0,
	
	@DisableNumber BIT = 0,
	@DisableBingo BIT = 0,
	@DisableCasino BIT = 0,
	@DisableP2P BIT = 0,
	@DisableFUNP2P BIT = 0,
	@ISAUTORESETP2P BIT = 0,
	@Disable162_1101 BIT = 0,
	@Disable180_1201 BIT = 0,
	@HideVirtualSports BIT = 0,
	@DoubleCommLosing BIT = 0,
	@isAutoResetLiveCasino BIT = 0, 
	@MaxWinLiveCasino SMALLMONEY = 0,
	@DisableCasinoBonus BIT = 0,
	@DisableHRFixedOdds BIT = 0,
	@DisableEsports BIT = 0,
	@DisableGoldDeluxe BIT = 0,
	@HideGoldDeluxe BIT = 0,
	
	@DisableColossusBet BIT = 1,
	@HideColossusBet BIT = 1,
	
	@DisableSuperLive BIT = 0,

	--Keno
	@HideKeno BIT = 0,	
	
	@credit MONEY,
	@maxcredit MONEY = 0,
	@isSearchAndCopy BIT = 0,
	@copyFromCustID INT = 0,
	
	@IP VARCHAR(15)='',
	@TransferOption_dec TINYINT,

	@Language VARCHAR(2)= 'E',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS

/*
Created: 20090121@Phuc
Task :	Insert general customer's Informatioin.
		Table related: customer, custinfo
DB: DBTXN/CustDB
Original:

Revisions:
	- 20090521@PhuongDao: Not to insert maxcredit on custinfo table 
	- 20090703@Phuc: manual rollback
	- 20090901@Shifu: add IsInternal
	- 20091112@Jamie: Add the input param @DisableOutright 
    - 20100413@Kiwi: + Remove to do not insert answer field.
					 + Move transferoption to CustSuper/CustMaster/CustAgent
	- 20100505@Huynguyen: Add param @DisableOpenTote
	- 20100828@Lukas:	- Add setting information (max per match, DisableBingo, DisableNumber) for Number game
						- Add Max per match for Mix Parlay for Mixed Sports
	- 20101029@Johnson: Include max per ball for number game
	- 20101230@Johnson: Add setting for HR AU, Greyhound, Harness
	- 20110405@Johnson: Add Danger's setting
	- 20110822@Tom: Add P2P setting
	- 20111222@Johnson: Add live casino setting 
	- 20120718@Dan: add 1 more field "site" in CustAgent table
	- 20120731@Dan: add Virtual soccer
	- 20120823@Elodie: add Abnormal field	
	- 20120926@Dan: add new fields for LCS-win limit
	- 20120928@Johnson: add double comm losing status
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20121130@Tom: Add  virtual tennis setting (sporttype : 186 , bettype : 1220)
	- 20130219@Johnson: Add virtual horse racing setting (sporttype : 181, bettype : 1321)
	- 20130328@Jamie: Add CustLoginInfo 
	- 20130423@Jamie: Set isForcedChangeSecurityCode = 1 WHEN Upline's SecurityCode NOT NULL 
	- 20130731@Elodie: Apply progressive bonus
	- 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
	- 20131107@Kathy: Add @autosuspend, @autosuspend2 [Redmine:#5520]
	- 20131120@Johnson: Add virtual greyhounds, virtual motor racing
	- 20140303@Patrick: Add more field HideKeno
	- 20140402@Kathy: Add Virtual Speedway (183), Virtual Virtual Cycling (185)	[Redmine:#14142]
	- 20140709@Logan: Force using Security Code for SMA from all sites (except 789y) [Redmine:#18121]
	- 20140822@Logan: Add Esport status [Redmine: #20531]
	- 20150102@Johnson: Separate virtual rate by sporttype, bettype [Redmine: #25840]				
	- 20150422@Elodie: Add Gold Deluxe product [Redmine:#34486]
	- 20150623@Elodie: Set HideGoldDeluxe = 1 for 789y site
	- 20150707@Elodie: Add Super Live product [Redmine: #35776]
	- 20150821@Elodie: Exclude WON currency for GoldDeluxe [Redmine: #41785]
	- 20150909@Elodie: Remove copying Virtual Rate setting from function Search and Copy [Redmine:#42976]                	
	- 20150825@Helen: Colossus Bet - [Redmine: #41264]
	- 20150904@Helen: commission setting for MO [Redmine #41470]
	- 20151028@Jim:Implement Muay's Setting for Deposit Customer [Redmine: #45491]
	- 20151029@Billy: Change to new VirtualRate structure [Redmine: #46541]

Param's Explanation:
• @ErrCode:
    = 0: Insert successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
BEGIN
    SET NOCOUNT ON 
	
	--IF @site = ''
	--	SELECT @site = site FROM Customer WITH (NOLOCK) WHERE custid = @recommend

	--IF @site = '789y'
	--	SELECT @HideGoldDeluxe = 1, @DisableGoldDeluxe = 1

	DECLARE @tmp_Site NVARCHAR(50)
	DECLARE @IsMyanmarOdds BIT = 0
	
	SELECT @tmp_Site = @site

	IF @tmp_Site = ''
		SELECT @tmp_Site = site FROM Customer WITH (NOLOCK) WHERE custid = @recommend

	IF @tmp_Site = '789y' OR @currency = 45 --Gold Deluxe doesn't support WON currency [Redmine: #41785]
		SELECT @HideGoldDeluxe = 1, @DisableGoldDeluxe = 1
		
    INSERT INTO Customer   			
			    (username, firstname, lastname, phone, mobilephone, fax, email, address,
			    city, state, country, postal, userpwd, roleid, srecommend, mrecommend, recommend, 
			    currency, pwdexpiry, creator, Site, creatdate, ugroup
			    ) 
 		     VALUES (@username, @firstname, @lastname, @phone, @mobilephone, @fax, @email, @address, 
			    @city, @state, @country, @postal, @userpwd, @roleid, @srecommend, @mrecommend, @recommend, 
			    @currency, @pwdexpiry, @creator, @site, GETDATE(), @ugroup
			    )

    SELECT @custid=@@IDENTITY

    IF @@ERROR <> 0
    BEGIN
	    SELECT @ErrMsg = CASE @Language 
							    WHEN 'E' THEN 'Create customer failed. Please try again.'
							    ELSE [dbo].[f_Get_MsgNamebyMsgID](40004, @Language)
						    END,
		    @ErrCode = 111
    		
	    -- ROLLBACK MANUALLY
	    DELETE FROM Customer WITH (ROWLOCK) WHERE custId = @CustID
    		
	    RETURN
    END

    DECLARE	@UplineSecurityCode			 VARCHAR(50)
	      , @isForcedChangeSecurityCode BIT

    SELECT @UplineSecurityCode		 = NULL
	     , @isForcedChangeSecurityCode = 0

    IF @roleid = 4
    BEGIN
        SELECT @isForcedChangeSecurityCode = CASE
                                               WHEN site LIKE '789y%' THEN 0
                                               ELSE 1
                                             END
          FROM Customer WITH(NOLOCK)
         WHERE custid = @custid

	    SET @srecommend = @custid
	    UPDATE Customer WITH(ROWLOCK, UPDLOCK)
	       SET srecommend = @custid
	     WHERE custId = @CustID
		
	    INSERT INTO CustSuper
	    (
	        custId, AutoIBCPositionTaking_Tote, AutoIBCPositionTaking_Fixed, AutoIBCPT151_AU,
	        AutoIBCPT152_UK, AutoIBCPT152_AU, AutoIBCPT153_AU, IsInternal, TransferOption
	    )
	    VALUES
	    (
	        @CustID, 0, 0, 0,
	        0, 0, 0, @IsInternal, CASE
	                                WHEN @TransferOption IS NULL THEN ISNULL(@TransferOption_dec, 0)
	                                ELSE dbo.F_Binary_Decimal(ISNULL(@TransferOption, 0))
	                              END
        )
		
			--Virtual rate
		INSERT INTO [dbo].[CustVirtualSetting] (custid, seqNo, bitmapVirtual)
		SELECT	@Custid, 
				seqNo,
				(
					SELECT TOP 1 bitmap
					FROM dbo.f_GenerateVirtualSetting_multiple(0x00, CONVERT(VARCHAR(MAX), virtualXML))
				) AS bitmapVirtual
		FROM (
			SELECT DISTINCT seqNo
			FROM ProfileVirtualSetting WITH(NOLOCK)
		) pvs
		CROSS APPLY (
			SELECT (
				SELECT	(
							SELECT	ipvs.profileID			AS '@p',
									vr.virtualMultiplier	AS '@v'
							FROM	ProfileVirtualSetting	AS ipvs WITH(NOLOCK)
							CROSS APPLY (
								SELECT CAST(1.00 AS SMALLMONEY) AS virtualMultiplier
							) vr
							WHERE	ipvs.seqNo = pvs.seqNo
							FOR XML PATH ('r'), 
							TYPE
						)
				FOR XML PATH ('root'), 
				TYPE
			) AS virtualXML
		) p	 
    END
    ELSE IF @roleid = 3
    BEGIN
	    SELECT @UplineSecurityCode = SecurityCode,
	           @isForcedChangeSecurityCode = isForcedChangeSecurityCode
	      FROM dbo.CustLoginInfo WITH(NOLOCK)
	     WHERE CustID = @srecommend

	    SET @mrecommend = @custid 
	    UPDATE Customer WITH (ROWLOCK, UPDLOCK) SET mrecommend = @custid WHERE custId = @CustID

	    INSERT INTO CustMaster(custId, DisableAutoMPT, IsInternal, TransferOption)
	    VALUES(@CustID,@DisableAutoMPT, @IsInternal, CASE WHEN @TransferOption IS NULL THEN ISNULL(@TransferOption_dec, 0) ELSE dbo.F_Binary_Decimal(ISNULL(@TransferOption, 0)) END)
	
		--Virtual rate
		INSERT INTO [dbo].[CustVirtualSetting] (custid, seqNo, bitmapVirtual)
		SELECT @Custid, seqNo, bitmapVirtual
		FROM CustVirtualSetting WITH(NOLOCK)
		WHERE custid = @srecommend
    END
    ELSE IF @roleid = 2
    BEGIN

	    SELECT @UplineSecurityCode = SecurityCode,
	           @isForcedChangeSecurityCode = isForcedChangeSecurityCode
	      FROM dbo.CustLoginInfo WITH(NOLOCK)
	     WHERE CustID = @mrecommend

	    SET @recommend = @custid
	    UPDATE Customer WITH (ROWLOCK, UPDLOCK) SET recommend = @custid WHERE custId = @CustID

	    INSERT INTO CustAgent(custId, MaxCredit, IsInternal, TransferOption, Site)
	    VALUES(@CustID, @MaxCredit, @IsInternal, CASE WHEN @TransferOption IS NULL THEN ISNULL(@TransferOption_dec, 0) ELSE dbo.F_Binary_Decimal(ISNULL(@TransferOption, 0)) END, @site)
		
		--Virtual rate
		INSERT INTO [dbo].[CustVirtualSetting] (custid, seqNo, bitmapVirtual)
		SELECT @Custid, seqNo, bitmapVirtual
		FROM CustVirtualSetting WITH(NOLOCK)
		WHERE custid = @mrecommend  
    END
	ELSE IF @roleid = 1
	BEGIN		
		INSERT INTO [dbo].[CustVirtualSetting] (custid, seqNo, bitmapVirtual)
		SELECT @Custid, seqNo, bitmapVirtual
		FROM CustVirtualSetting WITH(NOLOCK)
		WHERE custid = @recommend  
	END
    IF @@ERROR <> 0
    BEGIN
	    SELECT @ErrMsg = CASE @Language 
					       WHEN 'E' THEN 'Create customer failed. Please try again.'
					       ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
					     END
		     , @ErrCode = 112

	    -- ROLLBACK MANUALLY
	    IF @RoleID = 4
		    DELETE FROM CustSuper WITH(ROWLOCK) WHERE custId = @CustID
	    ELSE IF @RoleID = 3
		    DELETE FROM CustMaster WITH(ROWLOCK) WHERE custId = @CustID
	    ELSE IF @RoleID = 2
		    DELETE FROM CustAgent WITH(ROWLOCK) WHERE custId = @CustID

	    DELETE FROM Customer WITH(ROWLOCK) WHERE custId = @CustID
		DELETE FROM CustVirtualSetting WITH(ROWLOCK) WHERE custid = @CustID

	    RETURN
    END

    IF @roleid BETWEEN 2 AND 4 
    BEGIN
	    IF @UplineSecurityCode IS NOT NULL OR @isForcedChangeSecurityCode = 1
		    SELECT @isForcedChangeSecurityCode = 1

	    INSERT INTO dbo.CustLoginInfo
	    (
	        CustID, OldUserPwd, LastChangedPwdDate, isFirstLogin, SecurityCodeCount,
	        SecurityCode, isForcedChangeSecurityCode, LastChangedSecurityCodeDate
	    )
	    VALUES
	    (
	        @custid, NULL, GETDATE(), 1, 0,
	        NULL, @isForcedChangeSecurityCode, NULL
	    )

	    IF @@ERROR <> 0
	    BEGIN
		    SELECT	@ErrMsg = CASE @Language
								    WHEN 'E' THEN 'Create customer failed. Please try again.'
								    ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
							    END
				    ,@ErrCode = 115

		    IF @RoleID = 4
			    DELETE FROM CustSuper WITH(ROWLOCK) WHERE custId = @CustID
		    ELSE IF @RoleID = 3
			    DELETE FROM CustMaster WITH(ROWLOCK) WHERE custId = @CustID
		    ELSE IF @RoleID = 2
			    DELETE FROM CustAgent WITH(ROWLOCK) WHERE custId = @CustID

		    DELETE FROM Customer WITH(ROWLOCK) WHERE custId = @CustID
			DELETE FROM CustVirtualSetting WITH(ROWLOCK) WHERE custid = @CustID

		    RETURN
	    END
    END

    INSERT INTO [dbo].[custinfo]
    (
	    custid, currency
	  , maxpermatch, maxpermatch2, maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11,MaxPerMatch44, maxpermatch201, maxpermatch151
	  , maxpermatch151_OT, MaxPerMatch151_AU, MaxPerMatch152_UK, MaxPerMatch152_AU, MaxPerMatch153_AU, maxpermatch99
	  , roleid, srecommend, mrecommend, recommend, dangercust, autosuspend, autosuspend2, reject, credit, closed, username
	  , MatchLimit, VirtualMultiplier, DisableHorseRacing, DisableOpenTote, Disable151_AU, Disable152_UK, Disable152_AU, Disable153_AU
	  , DisableFinancial, DisableOutright, DisableCasino, DisableNumber,DisableBingo, maxpermatch161, MaxPerMatch99MP, MaxPerBall161
	  , MaxPerMatch180, MaxPerMatch181, MaxPerMatch186, danger, danger2, danger3, Abnormal, DisableP2P, DisableFunP2P, IsAutoResetP2P
	  , DisableLiveCasino, DisableVirtualSports, HideVirtualSports, DoubleCommLosing, isAutoResetLiveCasino, MaxWinLiveCasino
	  , DisableCasinoBonus, maxpermatch154, DisableHRFixedOdds, maxpermatch182, maxpermatch184, HideKeno, maxpermatch183, maxpermatch185
	  , DisableEsports, DisableGoldDeluxe, HideGoldDeluxe, DisableSuperLive,DisableColossusBet,HideColossusBet)
    VALUES
    (
	    @custid, @currency
	  , @MaxPerMatch, @MaxPerMatchv2, @MaxPerMatchv3, @MaxPerMatchv5, @MaxPerMatchv8, @MaxPerMatchv10, @MaxPerMatchv11,@MaxPerMatchv44, @MaxPerMatchv201,@MaxPerMatchv151_31
	  , @MaxPerMatchv151_41,@MaxPerMatchv151_51, @MaxPerMatchv152_41, @MaxPerMatchv152_51, @MaxPerMatchv153_51, @MaxPerMatchv99
	  , @roleid, @srecommend, @mrecommend, @recommend, 0, @autosuspend, @autosuspend2, ISNULL(@suspended, 0), @credit, ISNULL(@closed, 0), @username
	  , @matchlimit, @virtualmultiplier, @Disable151_31, @Disable151_41, @Disable151_51, @Disable152_41, @Disable152_51, @Disable153_51
	  , @DisableFinancial, @DisableOutright, @DisableCasino, @DisableNumber, @DisableBingo, @MaxPerMatchv161, @MaxPerMatchv99MP, @MaxPerBallv161
	  , @MaxPerMatchv180, @MaxPerMatchv181, @MaxPerMatchv186, @danger, @danger2, @danger3, @Abnormal, @DisableP2P, @DisableFUNP2P, @ISAUTORESETP2P
	  , @Disable162_1101, @Disable180_1201, @HideVirtualSports, @DoubleCommLosing, @isAutoResetLiveCasino, @MaxWinLiveCasino
	  , @DisableCasinoBonus, @MaxPerMatchv154, @DisableHRFixedOdds, @maxpermatchv182, @maxpermatchv184, @HideKeno, @maxpermatchv183, @maxpermatchv185
	  , @DisableEsports, @DisableGoldDeluxe, @HideGoldDeluxe, @DisableSuperLive,@DisableColossusBet,@HideColossusBet
    )

    IF @@ERROR <> 0
    BEGIN 
    --	DELETE customer with (ROWLOCK) where custid =  @custid
	    SELECT @ErrMsg = CASE @Language
					       WHEN 'E' THEN 'Create customer failed. Please try again.'
					       ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
					     END,
		       @ErrCode = 113

	    -- ROLLBACK MANUALLY
	    IF @RoleID = 4
	    BEGIN
		    DELETE FROM CustSuper WITH(ROWLOCK) WHERE custId = @CustID
		    DELETE FROM CustLoginInfo WITH (ROWLOCK) WHERE CustID = @CustID
	    END
	    ELSE IF @RoleID = 3
	    BEGIN
		    DELETE FROM CustMaster WITH(ROWLOCK) WHERE custId = @CustID
		    DELETE FROM CustLoginInfo WITH (ROWLOCK) WHERE CustID = @CustID 
	    END
	    ELSE IF @RoleID = 2
	    BEGIN
		    DELETE FROM CustAgent WITH(ROWLOCK) WHERE custId = @CustID
		    DELETE FROM CustLoginInfo WITH (ROWLOCK) WHERE CustID = @CustID 
	    END

	    DELETE FROM Customer WITH(ROWLOCK) WHERE custId = @CustID
		DELETE FROM CustVirtualSetting WITH(ROWLOCK) WHERE custid = @CustID	

	    RETURN
    END
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[Acc_CustomerInsUserInfo] TO [vnteam]
GO 
 GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerInsUserInfo] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[Acc_CustomerInsUserInfo] TO [bodbAdminNet]
GO 
 GRANT EXECUTE ON [dbo].[Acc_CustomerInsUserInfo] TO [bodbDownlineNet]
GO 
 GRANT EXECUTE ON [dbo].[Acc_CustomerInsUserInfo] TO [bodbExtAccNet]
GO 
