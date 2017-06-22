/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE CustDB
GO

ALTER PROC Acc_CustDirectUpd
(
	@CustID INT
	, @ProcessedBy VARCHAR(100)= ''
	, @Boss VARCHAR(100)= ''
	, @RequestedBy VARCHAR(100) = ''
	, @ApprovedBy VARCHAR(100) = ''
	, @Mobilephone NVARCHAR(50) = ''
	, @MaxLoss MONEY = 0
	
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
	
*/
BEGIN
	DECLARE @startRun DATETIME
          , @endRun   DATETIME
          , @duration INT
          , @existed  BIT 
          , @IsUpdDirectAccount BIT = 0
    SET @startRun = getdate()
    
    DECLARE @ProcessedBy_OLD VARCHAR(100)
		, @Boss_OLD VARCHAR(100)
		, @RequestedBy_OLD VARCHAR(100) 
		, @ApprovedBy_OLD VARCHAR(100)
		, @Mobilephone_OLD NVARCHAR(50)
		, @MaxLoss_OLD MONEY 
    
	--Check permission & Valid @MaxLoss
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@Creator,@funcname='[OtherCust]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
		
	IF @MaxLoss > 0
	BEGIN
	   SELECT @ErrCode = 101, @ErrMsg = 'Max Loss should be negative!'
	   RETURN
	END	    
		
	SET @MaxLoss_Old = ISNULL((SELECT ls.MaxLoss FROM DBAGE.bodb_Age.dbo.LimitLoss_Setting ls WITH (NOLOCK) WHERE ls.CustId = @CustId),0)
	
	-- Update MaxLoss
	IF @MaxLoss_OLD <> @MaxLoss
	BEGIN
		SET @IsUpdDirectAccount = 1
		
		IF EXISTS (SELECT 1 FROM DBAGE.bodb_Age.dbo.LimitLoss_Setting ls WITH (NOLOCK) WHERE ls.CustId = @CustId)
		BEGIN
			UPDATE ML
				SET MaxLoss = @MaxLoss
			FROM DBAGE.bodb_Age.dbo.LimitLoss_Setting ML WITH(ROWLOCK,UPDLOCK) 
			WHERE CustID=@CustID
			
		END
		ELSE 
		BEGIN	
			INSERT INTO DBAGE.bodb_Age.dbo.LimitLoss_Setting(CustID, MaxLoss) 
			VALUES(@CustID, @MaxLoss)
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
			SET mobilephone = @Mobilephone
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
							'ProcessedBy="' + COALESCE(CAST(@ProcessedBy AS VARCHAR(200)), SPACE(1)) + '" ' +
							'Boss="' + COALESCE(CAST(@Boss AS VARCHAR(200)), SPACE(1)) + '" ' +
							'RequestedBy="' + COALESCE(CAST(@RequestedBy AS VARCHAR(200)), SPACE(1)) + '" ' +
							'ApprovedBy="' + COALESCE(CAST(@ApprovedBy AS VARCHAR(200)), SPACE(1)) + '" ' +
							'Mobilephone="' + COALESCE(CAST(@Mobilephone AS VARCHAR(200)), SPACE(1)) + '" ' +
							'MaxLoss="' + COALESCE(CAST(@MaxLoss AS VARCHAR(100)), SPACE(1)) + '" ' +
							'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' +
							'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' +
							'ErrMsg="'+ COALESCE(CAST(@ErrMsg AS VARCHAR(4000)), SPACE(1)) + '" />'
						    
		SELECT @LogData2 = '<Acc_CustDirectUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" ' +
							'ProcessedBy="' + COALESCE(CAST(@ProcessedBy_old AS VARCHAR(200)), SPACE(1)) + '" ' +
							'Boss="' + COALESCE(CAST(@Boss_old AS VARCHAR(200)), SPACE(1)) + '" ' +
							'RequestedBy="' + COALESCE(CAST(@RequestedBy_OLD AS VARCHAR(200)), SPACE(1)) + '" ' +
							'ApprovedBy="' + COALESCE(CAST(@ApprovedBy_old AS VARCHAR(200)), SPACE(1)) + '" ' +
							'Mobilephone="' + COALESCE(CAST(@Mobilephone_old AS VARCHAR(200)), SPACE(1)) + '" ' +
							'MaxLoss="' + COALESCE(CAST(@MaxLoss_old AS VARCHAR(100)), SPACE(1)) + '" ' +
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
GRANT EXECUTE ON [dbo].[Acc_CustDirectUpd] TO [bodbAdminNet] AS [dbo]
GO

