/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_ExchangeMultiBaseRateUpd]
	@Exchange NVARCHAR(MAX),
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
	@IP VARCHAR(15) = ''
AS
/*
	Created: 20211229@Malcolm
	DB: DBCUST-CUSTDB
	Task: NAP Accouting Site - Ex.Rate - Edit Base rate

	Revisions:
		- 20211229@Malcolm: Initialize SP [RedmineID: #163417]
		- 20220301@Malcolm: Fix Logs [RedmineID: #163417]
		- 20220401@Evan: In-house Replication (RepUpdateTime) [RedmineID: #170752]
		- 20220914@Sophia: Update ActualRate of ExchangeDailyOanda [RedmineID: #175253] 
		- 20221107@Evan: Support Crypto Currency [RedmineID: #177844]
		- 20240729@Lewis: Scale Out DBCust - Remove Linked Server [Redmine : #206895] 
		- 20250114@Lewis: Apply Rep-Inhouse [RedmineID: #215883]

	Param's Explanation:
		. @Exhange 
			<root>
				<r ExchangeId="" Actualrate=""/>
			</root>
*/
BEGIN
	SET NOCOUNT ON


	DECLARE @XmlExchange XML = CONVERT(XML, @Exchange), @ExchangeId INT, @OldActualrate FLOAT, @NewActualrate FLOAT, @LogData NVARCHAR(MAX) = ''

	CREATE TABLE #Exchange (ExchangeId INT, Actualrate FLOAT)
	INSERT INTO #Exchange (ExchangeId, Actualrate)
	SELECT 
		t.c.value('@ExchangeId', 'INT') AS ExchangeId
		,t.c.value('@Actualrate', 'FLOAT') AS Actualrate
	FROM @XmlExchange.nodes('root/r') t(c) 
	OPTION(OPTIMIZE FOR (@XmlExchange = NULL))

	CREATE TABLE #LogExchange (ID INT IDENTITY(1, 1), ExchangeId INT, OldActualrate FLOAT, NewActualrate FLOAT)
	INSERT INTO #LogExchange (ExchangeId, OldActualrate, NewActualrate)
	SELECT e.ExchangeId, e.actualrate AS OldActualrate, ex.Actualrate AS NewActualrate
	FROM dbo.Exchange e WITH(NOLOCK)
		INNER JOIN #Exchange ex ON ex.ExchangeId = e.ExchangeId
	
	-- update Exchange 
	BEGIN TRY
		UPDATE e WITH(ROWLOCK)
			SET e.actualrate = ex.Actualrate,
				e.RepUpdateTime = dbo.f_GetDateTime2()
		FROM dbo.Exchange e 
			INNER JOIN #Exchange ex ON e.ExchangeId = ex.ExchangeId
		WHERE e.CurrencyType = 0

	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 100, @ErrMsg = 'Error occurs. update unsucessfully.'
		RETURN
	END CATCH

	-- update ExchangeDailyOanda

	BEGIN TRY
		EXEC dbo.Acc_ExchangeDaily_ActualRateUpd  
	END TRY
	BEGIN CATCH 
		SELECT @ErrCode = 103, @ErrMsg = 'Error occurs. update unsucessfully OANDA exchange rate.'
		RETURN
	END CATCH
	

	-- Write log
	DECLARE @ID INT = 1

	WHILE 1 = 1
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM #LogExchange WHERE ID = @ID)
			BREAK
		
		SELECT @OldActualrate = OldActualrate, @NewActualrate = NewActualrate, @Exchangeid = ExchangeId FROM #LogExchange WHERE ID = @ID
		
		SELECT @LogData = 'Update exchange rate: newRMRate=' + ISNULL(CONVERT(VARCHAR(10), @NewActualRate), '') +',oldRMRate=' + ISNULL(CONVERT(VARCHAR(10), @OldActualrate), '')
		
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_ExchangeRate
			@UserID		= @UserID, 
			@ExchangeID = @Exchangeid, 
			@actualrate = @NewActualRate, 
			@IP			= @IP, 
			@Doing		= @LogData

		SET @ID = @ID + 1
	END

	DROP TABLE #Exchange
	DROP TABLE #LogExchange
END
GO
