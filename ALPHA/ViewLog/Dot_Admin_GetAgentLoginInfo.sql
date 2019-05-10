/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="Dot_Admin" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_Admin_GetAgentLoginInfo]
	@custid int
AS
/*
	Created: 
	Task: get login info on a specific userID
	DB: DBLog.bodb_CustomerLog

	Revisions: 
		- 20190411@Lukas: archive a part of old log records to new database [Redmine: #111879]
*/
BEGIN
	SET NOCOUNT ON 

	DECLARE @__archiveDate DATETIME,
			@rowcount INT
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())
	
	DECLARE @result TABLE (LogID BIGINT, UserID INT, Doing VARCHAR(400), Logdate DATETIME , SubAccID INT, DomainName NVARCHAR(506),
						  unique CLUSTERED (Logdate DESC,LogID DESC))

	INSERT INTO @result
	SELECT TOP 500 LogID, UserID, Doing + ' - IP: ' + IP as Doing
				, LogDate, SubAccID, DomainName
	FROM userlog_Login with (nolock) 
	WHERE userid = @custid
		AND logdate >= @__archiveDate
	ORDER BY logdate DESC

	SET @rowcount = @@ROWCOUNT
	IF @rowcount < 500
	BEGIN	
		SET @rowcount = 500 - @rowcount

		INSERT INTO @result
		SELECT TOP(@rowcount) LogID, UserID, Doing + ' - IP: ' + IP as Doing
			, LogDate, SubAccID, DomainName
		FROM [bodb_CustomerLog_Archive].dbo.userlog_Login with(nolock) 
		WHERE userid = @custid
			AND logdate < @__archiveDate	 
		ORDER BY logdate DESC
	END

	SELECT *
	FROM @result
	ORDER BY logdate DESC

END

go
 