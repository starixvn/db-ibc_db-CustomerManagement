USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_Game_Unblock]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_Game_Unblock];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE PROCEDURE dbo.NAP_WinLimit_Game_Unblock @CustId INT
	, @ProductId TINYINT
	, @WinlostDate SMALLDATETIME
	, @UserId INT = 0
	, @IP VARCHAR(20) = ''
	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: 20160509@Patrick	
		Task: CWL - Unlock member
		DB: DBTXN/bodb02
		
		Revisions:
		- 20160520@Helen: Fix concurrency isue [Redmine: 57680]
		Parameters Explanation:	
	*/
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS (SELECT 1 FROM WinLimit_Game WITH (NOLOCK) WHERE IsBlocked = 0 AND ProductID = @ProductId AND Custid = @CustId AND WinlostDate= @WinlostDate)
	BEGIN
		
		SELECT	@ErrCode	= 2,
				@ErrMsg		= 'Invalid data because it has changed by some other people. Please refresh the page.'
	
		RETURN			
	END
	
	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @LogSPData VARCHAR(MAX), @CurrentDate DATETIME, @BetType SMALLINT
	SELECT @CurrentDate = GETDATE(), @StartRun = @CurrentDate
	
	SELECT @BetType = BetType
	FROM dbo.f_Winlimit_GetProductSetting()
	WHERE ProductId = @ProductId
	
	--Need to reset all data by @CustId & @BetType
	UPDATE cg
	SET cg.WinLost = 0
	FROM dbo.WinLimit_CreditGame cg WITH (ROWLOCK, UPDLOCK)
	WHERE cg.CustId = @CustId AND cg.BetType = @BetType
		
	UPDATE dg
	SET dg.WinLost = 0
	FROM dbo.WinLimit_DebitGame dg WITH (ROWLOCK, UPDLOCK)
	WHERE dg.CustId = @CustId AND dg.BetType = @BetType
	
	DECLARE @HistoryDataTmp TABLE(CustId INT, ProductId TINYINT, MaxWinLimit MONEY, TotalWinAmt MONEY, BlockedDate DATETIME
		, UnBlockedDate DATETIME, IsNotified BIT, BetType SMALLINT, BlockedWinAmt MONEY, ModifiedBy INT, CreatedBy INT, WinlostDate SMALLDATETIME)

	--update data
	UPDATE g
	SET g.UnBlockedDate = @CurrentDate
		, g.IsBlocked = 0
		, g.ModifiedBy = @UserId
	OUTPUT INSERTED.CustId, INSERTED.ProductId, INSERTED.MaxWinLimit, INSERTED.TotalWinAmt, INSERTED.BlockedDate
		, INSERTED.UnBlockedDate, INSERTED.IsNotified, INSERTED.BetType, INSERTED.BlockedWinAmt, INSERTED.ModifiedBy
		, INSERTED.CreatedBy, INSERTED.WinlostDate
	INTO @HistoryDataTmp(CustId, ProductId, MaxWinLimit, TotalWinAmt
		, BlockedDate, UnBlockedDate, IsNotified, BetType, BlockedWinAmt, ModifiedBy, CreatedBy, WinlostDate)
	FROM dbo.WinLimit_Game g WITH (ROWLOCK, UPDLOCK)
	WHERE CustID = @CustId AND WinlostDate = @WinlostDate AND BetType = @BetType
	
	-- Write history (new value)
	DECLARE @StrData VARCHAR(MAX), @XmlData XML
	SET @XmlData = (
		SELECT g.CustId '@a1'
			, g.ProductId '@a2'
			, g.MaxWinLimit '@a3'
			, g.TotalWinAmt '@a4'
			, 0 '@a5'
			, g.BlockedDate '@a6'
			, g.UnBlockedDate '@a7'
			, g.IsNotified '@a8'
			, g.BetType '@a9'
			, g.BlockedWinAmt '@b1'
			, g.ModifiedBy  '@b2'
			, g.CreatedBy  '@b3'
			, g.WinlostDate '@b4'
			FROM @HistoryDataTmp g
			FOR XML PATH('r'), ROOT ('root'), TYPE
	)
	
	SET @StrData = CONVERT(NVARCHAR(MAX), @XmlData)
	EXEC DBLOG.bodb_CustomerLog.dbo.Task_Winlimit_InsertHistoryData @XmlData = @StrData
	
	-- Write Log	
	SELECT	@EndRun = GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
			
	SELECT @LogSPData = '<NAP_WinLimit_Game_Unblock '
		+ '" CustId ="' + CONVERT(VARCHAR(50), @CustId)
		+ '" WinlostDate ="' + CONVERT(VARCHAR(50), @WinlostDate) 
		+ '" ProductId ="' + CONVERT(VARCHAR(50), @ProductId) 
		+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
		+ '" IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))
		+ '" />'
		
	BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID			= @UserID,
		@ActionID		= 31207,
		@TrackingValue	= @LogSPData,
		@Duration		= @Duration
	END TRY
	BEGIN CATCH
	SELECT @LogSPData = '<NAP_WinLimit_Game_Unblock '
		+ '" CustId ="' + CONVERT(VARCHAR(50), @CustId)
		+ '" WinlostDate ="' + CONVERT(VARCHAR(50), @WinlostDate) 
		+ '" ProductId ="' + CONVERT(VARCHAR(50), @ProductId) 
		+ '" UserId="' + CONVERT(VARCHAR(20), @UserId)
		+ '" ErrMsg="'+ COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(400)), SPACE(1)) 
		+ '" />'
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID			= @UserID,
		@ActionID		= 31207,
		@TrackingValue	= @LogSPData,
		@Duration		= @Duration
	END CATCH
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_Game_Unblock] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_Game_Unblock] TO [vnteam]
GO