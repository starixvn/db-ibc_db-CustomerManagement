/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE CS_CustomerIns_Headline
	@firstname NVARCHAR(50) = '',
	@lastname NVARCHAR(50) = '',	
	@phone NVARCHAR(50)='',
	@mobilephone NVARCHAR(50)='',	
	@fax NVARCHAR(50)='',	
	@username VARCHAR(30),
	@userpwd VARCHAR(40),	
	@ExtraPTSetting	VARCHAR(MAX),
	@currency INT,	
	@creator INT,
	@IP VARCHAR(20)= '',
	@ErrCode INT = 0 OUTPUT, 
	@ErrMsg NVARCHAR(1000) = '' OUTPUT
AS
/*
	Created: 20190715@Johnson	
	Task: create headline account for cn88
	DB: DBCUST/CUSTDB
	Revisions:
		- 20190715@Johnson: initial sp [redmine: #116691]
		- 20190819@Johnson: HF missing custAccount, CustGroupHeadline [redmine:#118868]
	
	-Parameter's Explanations:
		- @ExtraPTSetting:	<ROOT>
								<ExtraPT ProductId="1" ExtraPT="0.02"/>
								<ExtraPT ProductId="3" ExtraPT="0.03"/>
							</ROOT>	
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @startRun DATETIME , @endRun DATETIME , @duration INT
	
	SET @startRun = GETDATE()
	
	DECLARE 
		@pwdexpiry DATETIME = GETDATE()-1,
		@roleid TINYINT  =0,
		@srecommend INT =0, 
		@mrecommend INT =0, 
		@recommend INT = 0,
		@ugroup VARCHAR(10) ='',
		@custid INT,
		@isForcedChangeSecurityCode BIT = 1,
		@suspended BIT = 0,
		
		@Danger TINYINT = 0,
		@Danger2 TINYINT = 0,
		@Danger3 TINYINT = 0,
		@Abnormal TINYINT = 0,

		@closed BIT = 0,	
		@DisableOutright BIT = 0,
		@matchlimit SMALLMONEY = 0,
		@virtualmultiplier SMALLMONEY = 0,
		@DisableFinancial BIT = 0,
		@DisableAutoMPT BIT = 1,
		@IsInternal BIT = 0,
		
		@autosuspend BIT = 0,
		@autosuspend2 BIT = 0,

		@MaxPerMatch MONEY =0,
		@MaxPerMatchv2 MONEY=0,
		@MaxPerMatchv3 MONEY=0,
		@MaxPerMatchv5 MONEY=0,
		@MaxPerMatchv8 MONEY=0,
		@MaxPerMatchv10 MONEY=0,
		@MaxPerMatchv11 MONEY=0,
		@MaxPerMatchv44 MONEY=0,
		--v201
		@MaxPerMatchv201 MONEY = 0,
		@MaxPerMatchv99 MONEY = 0,
		@MaxPerMatchv99MP MONEY = 0,	
		
		@MaxPerMatchv1MP MONEY = 0,	
		
		@MaxPerMatchv161 MONEY = 0,	
		@MaxPerBallv161 MONEY = 0,	
		@MaxPerMatchv164 MONEY = 0,
		
		@DisableNumber BIT = 0,

		@DisableCasino BIT = 0,

		@DoubleCommLosing BIT = 0,
		@DisableCasinoBonus BIT = 0,	
		@DisableEsports BIT = 0,
		@DisableGoldDeluxe BIT = 0,
		@HideGoldDeluxe BIT = 0,
		
		@DisableColossusBet BIT = 1,
		@HideColossusBet BIT = 1,
		
		@DisableSuperLive BIT = 0,
		
		--Keno
		@HideKeno BIT = 0,	
		
		@credit MONEY = 0,
		@groupid INT,
		@GroupName VARCHAR(50),
		@site VARCHAR(30) = 'CN88',		
		@GroupHeadlineId INT
	
	DECLARE @today DATETIME
	SELECT  @today = CONVERT(DATE, GETDATE())
	
	DECLARE @ExtraPTTmp	TABLE(ProductId INT, ExtraPT MONEY) 	
		
	DECLARE @IsExists BIT 
	EXEC CS_CustomerCheckExists @username = @username, @Mode = 0, @IsExists = @IsExists OUTPUT

	IF @IsExists = 1
	BEGIN
		SELECT @ErrCode = 100,
				@ErrMsg = 'This username is not available.'
		RETURN
	END
	
	-- get Rate
	DECLARE @DocHandler INT
	BEGIN TRY
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @ExtraPTSetting
		
		INSERT INTO @ExtraPTTmp (ProductId, ExtraPT)
		SELECT ProductId, ExtraPT
		FROM OPENXML(@DocHandler, '/ROOT/ExtraPT', 1) WITH (ProductId INT, ExtraPT MONEY) AS Data

		EXEC sp_xml_removedocument @DocHandler
	END TRY
	BEGIN CATCH
		SELECT ErrCode = 102
			,ErrMsg = N'Paramter invalid.'
		RETURN
		
	END CATCH;
	
	--- get group extraPT			
	SELECT @GroupName = GroupName, @GroupId = GroupId
	FROM dbo.Acc_GroupExtraPT_Product a WITH (NOLOCK) 
		INNER JOIN @ExtraPTTmp e 
			ON  e.ProductID = a.ProductID
				AND e.ExtraPT = a.ExtraPT
	WHERE  	@today BETWEEN a.FromDate AND a.ToDate
			AND a.ProductID IN (1, 3)
			AND Sporttype = 0 AND SubProduct = ''
			AND GroupID BETWEEN 27 AND 42
	GROUP BY GroupName, GroupId
	HAVING COUNT(GroupId) = 2 
	
	IF @GroupName IS NULL OR @GroupID IS NULL
	BEGIN			 
		SELECT
			@ErrCode = 103,
			@ErrMsg = N'Invalid rates.'
		RETURN		 
	END
	
	INSERT INTO Customer   			
		(username, firstname, lastname, phone, mobilephone, fax, userpwd, roleid, srecommend, mrecommend, recommend, 
		currency, pwdexpiry, creator, Site, creatdate, ugroup
		) 
	 VALUES (@username, @firstname, @lastname, @phone, @mobilephone, @fax, @userpwd, @roleid, @srecommend, @mrecommend, @recommend, 
		@currency, @pwdexpiry, @creator, @site, GETDATE(), @ugroup
		)	

	SELECT @custid=@@IDENTITY
	
	IF @custid IS NULL
	BEGIN
		DELETE customer WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid
		
		SELECT @ErrCode = 104,
			@ErrMsg = 'Create customer failed. Please try again.'
			
		RETURN;
	END
	
	
	EXEC DBMSG.bodb_Message.dbo.Age_MsgCustReadStatus_Ins  @custid, 0, @roleid, @ErrCode OUTPUT, @ErrMsg OUTPUT
		
	IF @ErrCode <>0
	BEGIN	
		SELECT @ErrCode = 105,
			@ErrMsg = 'Create customer failed. Please try again.'
			
		DELETE customer WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid	
		RETURN;
	END
	
	INSERT INTO dbo.CustLoginInfo
		(
			CustID, OldUserPwd, LastChangedPwdDate, isFirstLogin, SecurityCodeCount,
			SecurityCode, isForcedChangeSecurityCode, LastChangedSecurityCodeDate,ClosedReason
		)
		VALUES
		(
			@custid, NULL, GETDATE(), 1, 0,
			NULL, @isForcedChangeSecurityCode, NULL,0
		)	
	
	IF @@ERROR > 0
	BEGIN
		SELECT @ErrCode = 106,
			@ErrMsg = 'Create customer failed. Please try again.'			
			
		DELETE customer WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid	
		EXEC DBMSG.bodb_Message.dbo.Age_MsgCustReadStatus_Del  @custid
		
		RETURN;
	END	
	
	INSERT INTO dbo.CS_HeadlineExtraPTGroup(HeadlineId,GroupID)
	VALUES (@custid,@groupid)
	
	IF @@ERROR > 0
	BEGIN		
		SELECT @ErrCode = 107,
			@ErrMsg = 'Create customer failed. Please try again.'			
				
		DELETE customer WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid	
		
		EXEC DBMSG.bodb_Message.dbo.Age_MsgCustReadStatus_Del  @custid
		
		DELETE CustLoginInfo WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid	
		RETURN;
	END	
	
	INSERT INTO dbo.CS_CustomerStatus (CustId, InactiveInfo, SuspendedInfo, ViewOnlyInfo)
	SELECT @custid, 0, 0, 0
	
	IF @@ERROR > 0
	BEGIN		
		SELECT @ErrCode = 108,
			@ErrMsg = 'Create customer failed. Please try again.'			
				
		DELETE customer WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid	
		
		EXEC DBMSG.bodb_Message.dbo.Age_MsgCustReadStatus_Del  @custid
		
		DELETE CustLoginInfo WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid	
		
		DELETE CS_HeadlineExtraPTGroup WITH(UPDLOCK,ROWLOCK)
		WHERE HeadlineId = @custid
		
		RETURN;
	END	
	
	INSERT INTO [dbo].[custinfo]
		(
			custid, currency,Disable151_AU
		  , maxpermatch, maxpermatch2, maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11,MaxPerMatch44, maxpermatch201
		  , maxpermatch99
		  , roleid, srecommend, mrecommend, recommend, dangercust, autosuspend, autosuspend2, reject, credit, closed, username
		  , MatchLimit, VirtualMultiplier
		  , DisableFinancial, DisableOutright, DisableCasino, DisableNumber, maxpermatch161, MaxPerMatch99MP, MaxPerBall161
		  --, MaxPerMatch180, MaxPerMatch181, MaxPerMatch186, maxpermatch182, maxpermatch184, maxpermatch183, maxpermatch185 , DisableVirtualSports, HideVirtualSports
		  , danger, danger2, danger3, Abnormal
		  ,  DoubleCommLosing, DisableCasinoBonus	 
		  , HideKeno, DisableEsports, DisableGoldDeluxe, HideGoldDeluxe, DisableSuperLive,DisableColossusBet,HideColossusBet
		  , MaxPerMatch1MP,maxpermatch164)
		VALUES
		(
			@custid, @currency,1
		  , @MaxPerMatch, @MaxPerMatchv2, @MaxPerMatchv3, @MaxPerMatchv5, @MaxPerMatchv8, @MaxPerMatchv10, @MaxPerMatchv11,@MaxPerMatchv44, @MaxPerMatchv201
		  , @MaxPerMatchv99
		  , @roleid, @srecommend, @mrecommend, @recommend, 0, @autosuspend, @autosuspend2, ISNULL(@suspended, 0), @credit, ISNULL(@closed, 0), @username
		  , @matchlimit, @virtualmultiplier
		  , @DisableFinancial, @DisableOutright, @DisableCasino, @DisableNumber,  @MaxPerMatchv161, @MaxPerMatchv99MP, @MaxPerBallv161
		  --, @MaxPerMatchv180, @MaxPerMatchv181, @MaxPerMatchv186, @maxpermatchv182, @maxpermatchv184, @maxpermatchv183, @maxpermatchv185, @Disable180_1201, @HideVirtualSports
		  , @danger, @danger2, @danger3, @Abnormal
		  ,  @DoubleCommLosing,@DisableCasinoBonus	
		  , @HideKeno, @DisableEsports, @DisableGoldDeluxe, @HideGoldDeluxe, @DisableSuperLive,@DisableColossusBet,@HideColossusBet
		  , @MaxPerMatchv1MP, @maxpermatchv164
		)

	IF @@ERROR > 0
	BEGIN		
		SELECT @ErrCode = 109,
			@ErrMsg = 'Create customer failed. Please try again.'			
								
		DELETE customer WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid	
		
		EXEC DBMSG.bodb_Message.dbo.Age_MsgCustReadStatus_Del  @custid
		
		DELETE CustLoginInfo WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid
		
		DELETE CS_HeadlineExtraPTGroup WITH(UPDLOCK,ROWLOCK)
		WHERE HeadlineId = @custid
		
		DELETE CS_CustomerStatus WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid
		
		RETURN;
	END	
	
	--INSERT GroupHeadline
	SELECT @GroupHeadlineId = MAX(groupid) + 1 FROM custaccount WITH(NOLOCK)

	INSERT INTO dbo.CustGroupHeadline (CustID, GroupID, HeadlineType, OwnerName, OwnerID)
	SELECT @custid, @GroupHeadlineId, 0, NULL, NULL	       
	
	IF @@ERROR > 0
	BEGIN		
		SELECT @ErrCode = 110,
			@ErrMsg = 'Create customer failed. Please try again.'			
								
		DELETE customer WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid	
		
		DELETE custinfo WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid	
		
		EXEC DBMSG.bodb_Message.dbo.Age_MsgCustReadStatus_Del  @custid
		
		DELETE CustLoginInfo WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid
		
		DELETE CS_HeadlineExtraPTGroup WITH(UPDLOCK,ROWLOCK)
		WHERE HeadlineId = @custid
		
		DELETE CS_CustomerStatus WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid
		
		DELETE CustGroupHeadline WITH(UPDLOCK,ROWLOCK)
		WHERE CustID = @custid
		RETURN;
	END	
	
	INSERT INTO dbo.custAccount (custid, creditgrade, installmentdate, installmentamount, preagreeamount, accountremark, accountremarkdate,groupid,isgroupheadline,checker)
	VALUES (@custid, N'A', N'1', 0, 0, '', CURRENT_TIMESTAMP, @GroupHeadlineId,1,0)

	IF @@ERROR > 0
	BEGIN		
		SELECT @ErrCode = 111,
			@ErrMsg = 'Create customer failed. Please try again.'			
								
		DELETE customer WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid	
		
		DELETE custinfo WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid	
		
		EXEC DBMSG.bodb_Message.dbo.Age_MsgCustReadStatus_Del  @custid
		
		DELETE CustLoginInfo WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid
		
		DELETE CS_HeadlineExtraPTGroup WITH(UPDLOCK,ROWLOCK)
		WHERE HeadlineId = @custid
		
		DELETE CS_CustomerStatus WITH(UPDLOCK,ROWLOCK)
		WHERE custid = @custid
		
		DELETE CustGroupHeadline WITH(UPDLOCK,ROWLOCK)
		WHERE CustID = @custid
				
		DELETE custAccount WITH(UPDLOCK,ROWLOCK)
		WHERE CustID = @custid
		RETURN;
	END	
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF (millisecond,@startRun,@endRun)

	DECLARE @LogSPData NVARCHAR(MAX)
	
	--Write general info
	SELECT @LogSPData = '<R fname="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@firstname AS NVARCHAR(100)),SPACE(1))) + '" ' +
						'lname="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@lastname AS NVARCHAR(100)),SPACE(1))) + '" ' +
						'phone="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@phone AS NVARCHAR(100)),SPACE(1))) + '" ' +
						'mphone="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@mobilephone AS NVARCHAR(100)),SPACE(1))) + '" ' +
						'fax="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@fax AS NVARCHAR(100)),SPACE(1))) + '" ' +
						'username="'+ COALESCE(CAST(@username AS VARCHAR(30)),SPACE(1)) + '" ' +												
						'group="' + COALESCE(CAST(@groupName AS VARCHAR(50)),SPACE(1)) + '" ' +		
						'currency="'+ COALESCE(CAST(@currency AS VARCHAR(50)),SPACE(1)) + '" ' +						
						'IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) + '" />'
						
	EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper
		@UserID = @Creator,
		@CustID = @CustID,
		@ActionID = 160012,
		@TrackingValue = @LogSPData,
		@duration = @duration	
END
GO		
			
		
		
			
		
		