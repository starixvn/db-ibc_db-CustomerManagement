/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustDirectUpd]
(
	@CustID INT
	, @ProcessedBy NVARCHAR(100)= ''
	, @Boss NVARCHAR(100)= ''
	, @RequestedBy NVARCHAR(100) = ''
	, @ApprovedBy NVARCHAR(100) = ''
	, @Mobilephone NVARCHAR(50) = ''
	, @MaxLoss MONEY = NULL
	, @MaxLossHeadline MONEY = NULL

	, @creator    INT = NULL
	, @IP         VARCHAR(20) = ''
	, @ErrCode    INT = 0 OUTPUT
	, @ErrMsg	    NVARCHAR(200) = '' OUTPUT
)
AS
/*
Created: 20170419@Helen
Task: Add Extra information for Direct Accounts, for NAP only - [Redmine:72339]
DB: DBCUST/CUSTDB

Revisions:
	- 20171026@Elodie:  Add MaxLoss of headline - [Redmine:82892]
	- 20171114@Elodie: Some fields cannot decode Chinese words - [Redmine:86612]
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
	- 20241128@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]		
*/
BEGIN
	DECLARE @startRun DATETIME
          , @endRun   DATETIME
          , @duration INT
          , @existed  BIT 
          , @IsUpdDirectAccount BIT = 0
		  , @GroupHeadlineID INT
		  , @Username NVARCHAR(50)
    SET @startRun = getdate()
    
    DECLARE @ProcessedBy_OLD NVARCHAR(100)
		, @Boss_OLD NVARCHAR(100)
		, @RequestedBy_OLD NVARCHAR(100) 
		, @ApprovedBy_OLD NVARCHAR(100)
		, @Mobilephone_OLD NVARCHAR(50)
		, @MaxLoss_OLD MONEY 
		, @MaxLossHeadline_OLD MONEY 
    
	IF (@MaxLoss IS NOT NULL AND @MaxLoss >= 0) OR (@MaxLossHeadline >= 0 AND @MaxLossHeadline IS NOT NULL)
	BEGIN
	   SELECT @ErrCode = 101, @ErrMsg = 'Max Loss should be negative!'
	   RETURN
	END	    
		
	SELECT @MaxLoss_Old = ls.MaxLoss FROM DBAGE.bodb_Age.dbo.LimitLoss_Setting ls WITH (NOLOCK) WHERE ls.CustId = @CustId

	SELECT @GroupHeadlineID = groupID 
	FROM dbo.custAccount ca WITH (NOLOCK) 
		INNER JOIN DBAGE.bodb_Age.dbo.LimitLoss_HeadlineSetting hs WITH (NOLOCK) ON ca.groupID = hs.GroupHeadlineID
	WHERE custid = @CustID

	SELECT @MaxLossHeadline_OLD = hs.MaxLoss FROM DBAGE.bodb_Age.dbo.LimitLoss_HeadlineSetting hs WITH (NOLOCK) WHERE hs.GroupHeadlineID = @GroupHeadlineID

	IF @MaxLoss IS NOT NULL --update MaxLoss
	BEGIN
		SET @IsUpdDirectAccount = 1		

		IF @MaxLoss_OLD IS NOT NULL
		BEGIN
			-- Update MaxLoss
			IF @MaxLoss_OLD <> @MaxLoss
			BEGIN
				EXEC DBAGE.bodb_Age.dbo.NAP_LimitLoss_SMAMaxLossUpd 
					@CustId = @CustID, 
					@MaxLoss = @MaxLoss, 
					@Mode = 0, 
					@System = 1,
					@UserID = @creator, 
					@IP = @IP, 
					@ErrCode = @ErrCode OUTPUT,
					@ErrMsg = @ErrMsg OUTPUT						
			END
		END
		ELSE
		BEGIN
			SELECT @Username = username FROM dbo.custInfo WITH (NOLOCK) WHERE custid = @CustID
			-- Insert MaxLoss
			EXEC DBAGE.bodb_Age.dbo.NAP_LimitLoss_SMAIns 
					@Username = @Username, 
					@MaxLoss = @MaxLoss, 
					@Mode = 0, 
					@System = 1,
					@UserID = @creator, 
					@IP = @IP, 
					@ErrCode = @ErrCode OUTPUT,
					@ErrMsg = @ErrMsg OUTPUT		
		END
	END

	IF @MaxLossHeadline IS  NOT NULL --update MaxLossHeadline
	BEGIN
		SET @IsUpdDirectAccount = 1		

		IF @MaxLossHeadline_OLD IS NOT NULL
		BEGIN
			-- Update MaxLossHeadline
			IF @MaxLossHeadline_OLD <> @MaxLossHeadline
			BEGIN
				EXEC DBAGE.bodb_Age.dbo.NAP_LimitLoss_SMAMaxLossUpd 
					@CustId = @CustID, 
					@MaxLoss = @MaxLossHeadline, 
					@Mode = 1, 
					@System = 1,
					@UserID = @creator, 
					@IP = @IP, 
					@ErrCode = @ErrCode OUTPUT,
					@ErrMsg = @ErrMsg OUTPUT						
			END
		END
		ELSE
		BEGIN
			SELECT @Username = username FROM dbo.custInfo WITH (NOLOCK) WHERE custid = @CustID
			-- Insert MaxLossHeadline
			EXEC DBAGE.bodb_Age.dbo.NAP_LimitLoss_SMAIns 
					@Username = @Username, 
					@MaxLoss = @MaxLossHeadline, 
					@Mode = 1, 
					@System = 1,
					@UserID = @creator, 
					@IP = @IP, 
					@ErrCode = @ErrCode OUTPUT,
					@ErrMsg = @ErrMsg OUTPUT		
		END
	END

    -- Update extra info for direct account
	SELECT  @ProcessedBy_OLD = ISNULL(ProcessedBy,'')
			, @Boss_OLD = ISNULL(Boss,'')
			, @RequestedBy_OLD = ISNULL(RequestedBy,'')
			, @ApprovedBy_OLD = ISNULL(ApprovedBy,'')
	FROM CustDirectAccount CDA WITH (NOLOCK)
	WHERE CDA.CustID = @CustID
	
	IF @ProcessedBy_OLD <> @ProcessedBy
		OR @Boss_OLD <> @Boss
		OR @ApprovedBy_OLD <> @ApprovedBy
		OR @RequestedBy_OLD <> @RequestedBy
	BEGIN	
		SET @IsUpdDirectAccount = 1
		
		UPDATE CDA
			SET ProcessedBy = @ProcessedBy
				, Boss = @Boss
				, RequestedBy = @RequestedBy
				, ApprovedBy = @ApprovedBy
		FROM CustDirectAccount CDA WITH (ROWLOCK,UPDLOCK)
		WHERE CDA.CustID = @CustID
	END

	-- Update MobilePhone
	SET @Mobilephone_old = (SELECT mobilephone FROM CUSTOMER C WITH (NOLOCK) WHERE C.CustId = @CustId)
	
	IF @Mobilephone_OLD <> @Mobilephone
	BEGIN
		SET @IsUpdDirectAccount = 1	
		
		UPDATE C
			SET mobilephone = @Mobilephone,
				RepUpdateTime = dbo.f_GetDateTime2()
		FROM Customer c WITH(ROWLOCK,UPDLOCK) 
		WHERE C.CUSTID = @custid 
		 
	END
		
	--Log Update Action	
	SET @endRun = GETDATE()

    SET @duration  = DATEDIFF(MILLISECOND, @startRun, @endRun)
        	
    DECLARE @LogData NVARCHAR(4000), @LogData2 NVARCHAR(4000)
	
	IF @IsUpdDirectAccount = 1
	BEGIN
		SELECT @LogData = '<Acc_CustDirectUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" ' +
							'ProcessedBy="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@ProcessedBy AS NVARCHAR(100)), SPACE(1))) + '" ' +
							'Boss="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Boss AS NVARCHAR(100)), SPACE(1))) + '" ' +
							'RequestedBy="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@RequestedBy AS NVARCHAR(100)), SPACE(1))) + '" ' +
							'ApprovedBy="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@ApprovedBy AS NVARCHAR(100)), SPACE(1))) + '" ' +
							'Mobilephone="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Mobilephone AS NVARCHAR(50)), SPACE(1))) + '" ' +
							'MaxLoss="' + COALESCE(CAST(ISNULL(@MaxLoss,@MaxLoss_OLD) AS VARCHAR(100)), SPACE(1)) + '" ' +
							'MaxLossHeadline="' + COALESCE(CAST(ISNULL(@MaxLossHeadline,@MaxLossHeadline_OLD) AS VARCHAR(100)), SPACE(1)) + '" ' +
							'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' +
							'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' +
							'ErrMsg="'+ COALESCE(CAST(@ErrMsg AS VARCHAR(4000)), SPACE(1)) + '" />'
						    
		SELECT @LogData2 = '<Acc_CustDirectUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" ' +
							'ProcessedBy="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@ProcessedBy_old AS NVARCHAR(100)), SPACE(1))) + '" ' +
							'Boss="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Boss_old AS NVARCHAR(100)), SPACE(1))) + '" ' +
							'RequestedBy="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@RequestedBy_OLD AS NVARCHAR(100)), SPACE(1))) + '" ' +
							'ApprovedBy="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@ApprovedBy_old AS NVARCHAR(100)), SPACE(1))) + '" ' +
							'Mobilephone="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Mobilephone_old AS NVARCHAR(50)), SPACE(1))) + '" ' +
							'MaxLoss="' + COALESCE(CAST(@MaxLoss_old AS VARCHAR(100)), SPACE(1)) + '" ' +
							'MaxLossHeadline="' + COALESCE(CAST(@MaxLossHeadline_OLD AS VARCHAR(100)), SPACE(1)) + '" ' +
							'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' +
							'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' +
							'ErrMsg="'+ COALESCE(CAST(@ErrMsg AS VARCHAR(4000)), SPACE(1)) + '" />'

		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					@Userid = @Creator,
					@CustID = @CustID,
					@ActionID = 672,
					@TrackingValue = @LogData,
					@TrackingValue2 = @LogData2,
					@Duration = @duration
	END
END
GO