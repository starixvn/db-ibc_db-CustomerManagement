/*<info serverAlias="DBSIC-bodb02" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Task_CashService_BonusTransaction_Ins
	@TransDate DATETIME,
	@MemberBonus VARCHAR(MAX),
	@SiteDBGroupID TINYINT,
	@IsBonusChanged BIT = 0 OUTPUT,
	@LogJson NVARCHAR(MAX) OUTPUT
AS 
/*  
	Created By: Elodie
	Created Date: 2025-07-07
	Description: Agency Cash Service - Calculate and add pending bonus transaction for qualified members [Redmine #232347]
	DB: DBSIC.bodb02
	
	Revisions:
		- 20250707@Elodie: Initial SP [Redmine: #232347] 

	Param:
		exec Task_CashService_BonusTransaction_Ins @MemberBonus = @MemberBonus
*/  
BEGIN
	SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @logSpData NVARCHAR(MAX), @xml XML
	
	SET @startRun = GETDATE()

	CREATE TABLE #CashTransaction (
		CustId INT,
		TransactionTypeID TINYINT,
		StatusId TINYINT,
		Amount MONEY,
		CreatedTime DATETIME,
		Creator INT,		
		SiteDBGroupID TINYINT,
		ExtraInfo NVARCHAR(1000),
		PromotionID INT,	
		TrackingValue NVARCHAR(MAX)
	)	

	INSERT INTO #CashTransaction ([CustId], [TransactionTypeID], [StatusId], [Amount], [CreatedTime], [Creator], [SiteDBGroupID], [ExtraInfo], [PromotionID])
	SELECT 
		CustId,
		11 AS TransactionTypeID, -- Bonus Transaction
		2 AS StatusId, -- Pending
		Bonus AS Amount,
		@TransDate AS CreatedTime,
		10278938 AS Creator, -- StarixIT
		@SiteDBGroupID AS SiteDBGroupID,
		ExtraInfo AS ExtraInfo,
		PromotionID
	FROM OPENJSON(@MemberBonus)
	WITH (
		CustId INT '$.CustId',
		Bonus MONEY '$.Bonus',
		ExtraInfo NVARCHAR(1000) '$.ExtraInfo',
		PromotionID INT '$.PromotionID'
	) 	

	IF EXISTS(SELECT TOP 1 1 
				FROM #CashTransaction ct
				INNER JOIN CashTransaction c 
					ON ct.CustId = c.CustId 
					AND ct.TransactionTypeID = c.TransactionTypeID 
					AND c.CreatedTime = ct.CreatedTime
					AND c.ExtraInfo = ct.ExtraInfo
					AND c.Amount <> ct.Amount)
	BEGIN		
		--[ALERT] Bonus transaction amount mismatch detected (same CustId, TransactionTypeID, date). Logged to CashTransactionError for review.
		SET @IsBonusChanged = 1
		
		-- Insert into CashTransactionError for mismatched amounts		
		DELETE c
		OUTPUT 
			DELETED.CustId,
			DELETED.TransactionTypeID,
			DELETED.StatusId,
			DELETED.Amount,
			DELETED.CreatedTime,
			DELETED.Creator,
			DELETED.SiteDBGroupID,
			DELETED.ExtraInfo,
			DELETED.PromotionID
		INTO CashTransactionError (CustId, TransactionTypeID, StatusId, Amount, CreatedTime, Creator, SiteDBGroupID, ExtraInfo, PromotionID)
		FROM #CashTransaction c
		WHERE EXISTS (	SELECT 1
						FROM CashTransaction ct WITH (NOLOCK)
						WHERE ct.CustId = c.CustId
							AND ct.TransactionTypeID = c.TransactionTypeID
							AND ct.CreatedTime = c.CreatedTime
							AND c.ExtraInfo = ct.ExtraInfo
							AND ct.Amount <> c.Amount
					)						
	END

	DELETE c	
	FROM #CashTransaction c
	WHERE EXISTS (	SELECT 1
					FROM CashTransaction ct WITH (NOLOCK)
					WHERE ct.CustId = c.CustId
						AND ct.TransactionTypeID = c.TransactionTypeID
						AND ct.CreatedTime = c.CreatedTime
						AND c.ExtraInfo = ct.ExtraInfo
				)	

	DELETE c	
	FROM #CashTransaction c
		INNER JOIN AgencyCashService.dbo.CashPromotion p WITH (NOLOCK) ON c.PromotionID = p.PromotionID AND p.SiteDBGroupID = @SiteDBGroupID
	WHERE p.IsSoftDeleted = 1 AND p.Enabled = 0

	INSERT INTO CashTransaction (CustId, TransactionTypeID, StatusId, Amount, CreatedTime, Creator, [RepUpdateTime], SiteDBGroupID, ExtraInfo)
	SELECT 
		CustId, 
		TransactionTypeID, 
		StatusId, 
		Amount, 
		CreatedTime, 
		Creator, 
		dbo.f_GetDateTime2() AS RepUpdateTime,
		SiteDBGroupID,
		ExtraInfo
	FROM #CashTransaction c	

	SELECT @endRun = GETDATE(), @duration = DATEDIFF(MILLISECOND, @startRun, @endRun)

	UPDATE  c
	SET TrackingValue = 
						CONVERT( NVARCHAR(MAX),(
							SELECT  
								StatusId      AS [@StatusId],
								Amount        AS [@Amount],
								CreatedTime   AS [@CreatedTime],
								pl.Title   	  AS [@Title],
								TRY_CAST(JSON_VALUE(ExtraInfo, '$.FromDate') AS DATE) AS [@FromDate],
								TRY_CAST(JSON_VALUE(ExtraInfo, '$.ToDate') AS DATE) AS [@ToDate]														
							FOR XML PATH('R'), TYPE))
	FROM  #CashTransaction c
		INNER JOIN AgencyCashService.dbo.CashPromotionLanguage pl WITH (NOLOCK) ON c.PromotionID = pl.PromotionID AND pl.SiteDBGroupID = c.SiteDBGroupID
	WHERE pl.LanguageCode = 'en'

	SELECT @LogJson = (
		SELECT  
			Creator   AS UserID,
			CustID, 
			315107 AS ActionID,
			TrackingValue,
			TrackingValue AS TrackingValueMask,
			TrackingValue AS TrackingValue2,
			TrackingValue AS TrackingValueMask2,
			@duration AS Duration
		FROM #CashTransaction
		FOR JSON PATH
	);

/*
	DECLARE @CustId INT, @UserID INT
	WHILE(1=1)
	BEGIN
		DELETE TOP (1)
		FROM #CashTransaction
		OUTPUT 
			DELETED.CustId,
			DELETED.TransactionTypeID,
			DELETED.StatusId,
			DELETED.Amount,
			DELETED.CreatedTime,
			DELETED.Creator,
			DELETED.SiteDBGroupID,
			DELETED.ExtraInfo
		INTO @CashTransactionLog

		IF @@ROWCOUNT = 0 BREAK
		
		SELECT	@CustId = CustId,
				@UserID = Creator
		FROM @CashTransactionLog

		SET @xml = (	SELECT	'Pending'	AS '@Status',
									Amount		AS '@Amount',
									CreatedTime	AS '@CreatedTime',																		
									ExtraInfo	AS '@ExtraInfo'
							FROM @CashTransactionLog t
							FOR XML PATH('ROOT'),
							TYPE)
		SET @logSpData	= REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

		EXEC Acc_WriteLog_UserLog_RunSP_Wrapper 
			@UserID 		= @UserID,
			@CustID			= @CustID,
			@ActionID		= 315107,
			@TrackingValue	= @logSpData,
			@duration		= @duration
	END
	*/
END
