/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_xnap,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerDateLimitMultipleUpd] @ListCustID VARCHAR(MAX) = ''
	,@ListUserName VARCHAR(MAX) = ''
	,@MinDate DATETIME = NULL
	,@TimePeriod INT = NULL
	,@Choice TINYINT
	,@EffectedRow INT = 0 OUTPUT
	,@NoChangeUser NVARCHAR(MAX) = '' OUTPUT
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(MAX) = '' OUTPUT
	,@UserId INT
	,@DeniedList NVARCHAR(MAX)=NULL
AS
/*
	Created: 20180906@Winnie
	DB: DBCUST/CUSTDB
	Task: 
	Revisions:
		- 20180906@Winnie: EXT-Function to control data range for SMA RedmineID:100067
		- 20180927@Razor: Change write log [Redmind: #102072]
		- 20181002@Razor: Support to add multiple Super by UserName [Redmine: #102213]
		- 20181010@Winnie: Enhance Perf [Redmine: #102213]
		- 20181011@Razor: Don't write Log when data no change [Redmine: #102213]
		- 20181019@Razor: missing log when inserting existing, new super case [Redmine: #103458]
		- 20181017@Razor: Remove Date Limit for multiple supers [Redmine: #103207]
		- 20181123@Helen: Get code from PRO + DB053.bodb_AGE/BODB02 & DB052.bodb_Summary Migration [Redmine: 104770]
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
		- 20240529@Tacy: NAP - Permission controls on real currency [redmineID: #202523]
		- 20240613@Tacy: Rollback check permission [redmineID: #202523]
		- 20240621@Tacy: Ext NAP - Not check Permission on Site/Currency [redmineID: #206918]
		- 20241231@Hughie: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
		
	Param's Explanation:	
	@Choice=1: None
	@Choice=2: Time Period
	@Choice=3: Min Date
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
		,@endRun DATETIME
		,@duration INT
		,@LogSPData VARCHAR(max)
		,@CustID INT
		,@UserName VARCHAR(30)
		,@oldMinDate DATETIME
		,@oldLimitDays INT
		,@oldLogSPData VARCHAR(max)
		,@tempNewValue NVARCHAR(MAX)
		,@tempOldValue NVARCHAR(MAX)
		,@NoLimitText VARCHAR(10)
		,@InvalidCustIds VARCHAR(MAX)
	DECLARE @oldCustDateLimit TABLE (
		CustId INT
		,MinDate DATETIME
		,LimitDays INT
		)
	DECLARE @tempCust TABLE (
		CustID INT
		,UserName VARCHAR(30)
		)

	SELECT @startRun = GETDATE()
		,@NoLimitText = 'No Limit'

	IF @TimePeriod < 0
		OR @TimePeriod > 32767
	BEGIN
		SELECT @ErrMsg = 'Invalid data.'
			,@ErrCode = 101

		RETURN
	END

	IF (@ListUserName = '')
	BEGIN
		INSERT INTO @tempCust
		SELECT t.value
			,c.username
		FROM STRING_SPLIT(@ListCustID, ',') t
			INNER JOIN dbo.custInfo c WITH (NOLOCK) ON c.custid = t.value
		WHERE c.roleid = 4
			AND LEN(t.value) > 0
	END
	ELSE
	BEGIN
		INSERT INTO @tempCust (UserName)
		SELECT DISTINCT RTRIM(LTRIM(value))
		FROM STRING_SPLIT(@ListUserName, ',')
		WHERE LEN(value) > 0

		UPDATE t
		SET CustID = c.custid
		FROM @tempCust t
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.username = t.UserName
		WHERE c.roleid = 4
	END

	SELECT @InvalidCustIds = STUFF((
				SELECT ', ' + userName
				FROM @tempCust
				WHERE CustId IS NULL
				FOR XML PATH('')
				), 1, 1, '')

	IF (LEN(@InvalidCustIds) > 0)
	BEGIN
		SELECT @ErrCode = 102
			,@ErrMsg = @InvalidCustIds + ': Invalid account(s)'

		RETURN
	END

	--Check: permit to access site/currency
	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)

	IF ISNULL(@DeniedList,'')<>''
	BEGIN
		--get deny site
		INSERT INTO  @tmp (siteid , site,SpecialGroup)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Site'
	
		--get deny currency
		INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Exchange'
	END

	SELECT @InvalidCustIds = STUFF((
				SELECT ', ' + t.userName
				FROM @tempCust t
				INNER JOIN Customer c WITH (NOLOCK) ON t.custid=c.custid
				WHERE c.site IN (SELECT site FROM @tmp)
					OR c.currency IN (SELECT exchangeID FROM @tmpExchange)
				FOR XML PATH('')
				), 1, 1, '')

	IF (LEN(@InvalidCustIds) > 0)
	BEGIN
		SELECT @ErrCode = 104
			,@ErrMsg = 'You don''t have permission to access: ' + @InvalidCustIds

		RETURN
	END
	
	INSERT INTO @oldCustDateLimit
	SELECT b.CustId
		,a.MinDate
		,a.LimitDays	
	FROM @tempCust b 
	LEFT JOIN dbo.Age_CustDateLimit a WITH (NOLOCK) ON b.CustId = a.CustId

	IF (@Choice = 1)
	BEGIN
		DELETE a WITH (ROWLOCK)
		OUTPUT DELETED.custid, dbo.f_GetDateTime2()
		INTO Custinfo_Del_Inhouse(custid,RepUpdateTime)
		FROM dbo.Age_CustDateLimit a
		INNER JOIN @tempCust t ON a.CustID = t.CustID
		WHERE a.CustId = @CustID
		
		SELECT @ErrCode = @@ERROR, @EffectedRow = @@ROWCOUNT
	END
	ELSE IF (@Choice = 2)
	BEGIN
		UPDATE a WITH (ROWLOCK, UPDLOCK)
		SET a.LimitDays = @TimePeriod
			,a.MinDate = NULL
			,RepUpdateTime = dbo.f_GetDateTime2()
		FROM dbo.Age_CustDateLimit a WITH (ROWLOCK, UPDLOCK)
			INNER JOIN @tempCust t ON a.CustID = t.CustID
		WHERE a.LimitDays <> @TimePeriod
			OR a.LimitDays IS NULL
			AND a.CustId = @CustID
		
		SELECT @EffectedRow = @@ROWCOUNT
		
		INSERT INTO dbo.Age_CustDateLimit (
			CustId
			,LimitDays
			)
		SELECT Custid
			,@TimePeriod
		FROM @tempCust t
		WHERE NOT EXISTS (
				SELECT 1
				FROM dbo.Age_CustDateLimit WITH (NOLOCK)
				WHERE CustID = t.CustID
				)

		SELECT @ErrCode = @@ERROR, @EffectedRow = @EffectedRow + @@ROWCOUNT
	END
	ELSE IF (@Choice = 3)
	BEGIN
		UPDATE a
		SET a.MinDate = @MinDate
			,a.LimitDays = NULL
		FROM dbo.Age_CustDateLimit a WITH (ROWLOCK, UPDLOCK)
			INNER JOIN @tempCust t ON a.CustID = t.CustID
		WHERE a.MinDate <> @MinDate
			OR a.MinDate IS NULL

		SELECT @EffectedRow = @@ROWCOUNT
		
		INSERT INTO dbo.Age_CustDateLimit (
			CustId
			,MinDate
			)
		SELECT Custid
			,@MinDate
		FROM @tempCust t
		WHERE NOT EXISTS (
				SELECT 1
				FROM dbo.Age_CustDateLimit WITH (NOLOCK)
				WHERE CustID = t.CustID
				)

		SELECT @ErrCode = @@ERROR, @EffectedRow = @EffectedRow + @@ROWCOUNT
	END

	SELECT @LogSPData = '<EAS_CustomerDateLimitMultipleUpd DataAvailable="' + COALESCE(CAST(@TimePeriod AS VARCHAR(10)), CONVERT(VARCHAR, @MinDate, 101), @NoLimitText) + '" ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1))
						+ '" />'

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun)

	WHILE EXISTS (
			SELECT 1
			FROM @tempCust
			)
	BEGIN
		SELECT TOP 1 @CustID = CustID, @UserName = UserName
		FROM @tempCust

		SELECT @oldMinDate = MinDate
			,@oldLimitDays = LimitDays
		FROM @oldCustDateLimit
		WHERE CustId = @CustID

		IF (
				ISNULL(@oldMinDate, '1/1/1900') <> ISNULL(@MinDate, '1/1/1900')
				OR ISNULL(@oldLimitDays, 0) <> ISNULL(@TimePeriod, 0)
				)
		BEGIN		
			SELECT @oldLogSPData = '<EAS_CustomerDateLimitMultipleUpd DataAvailable="' + COALESCE(CAST(@oldLimitDays AS VARCHAR(10)), CONVERT(VARCHAR, @oldMinDate, 101), @NoLimitText) + '" ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1))
							+ '" />'

			EXEC Acc_WriteLog_UserLog_RunSP_Wrapper @UserID = @UserID
					,@CustID = @custID
					,@ActionID = 31503
					,@TrackingValue = @LogSPData
					,@TrackingValue2 = @oldLogSPData
					,@duration = @duration
		END
		ELSE
		BEGIN
			SELECT @NoChangeUser = @NoChangeUser + CASE @NoChangeUser WHEN '' THEN @UserName ELSE  ', ' + @UserName END
		END
		DELETE
		FROM @tempCust
		WHERE CustID = @CustID
	END
END
GO