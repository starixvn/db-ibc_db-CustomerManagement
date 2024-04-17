/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="wsv_nap,bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CS_UserLog_CreditSelTotalRecords]    
    @CustID INT,
    @FromDate DATETIME,
    @ToDate DATETIME,
    @IsInternal TINYINT    
AS 
/* Created:20190606@Elodie
    Task: count total record with input conditions
    DB: DBLOG\bodb_CustomerLog
    
	Revisions:
		- 20190606@Elodie: Initial SP [Redmine: #113198]
		
    Param's Explaination:    
		- @CustID: a customer which we want to view actions affect to.
		- @FromDate: date range to view log
		- @ToDate: date range to view log	
		- @IsInternal: AccountingSite: 1 Agent:0
*/
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON

	DECLARE @__archiveDate DATETIME
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())
	IF @IsInternal = 1
	BEGIN
		IF @FromDate >= @__archiveDate
		BEGIN
			SELECT COUNT(LogID)                         
			FROM dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
				INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
			WHERE uc.CustID = @CustID
				AND LogDate BETWEEN @FromDate AND @ToDate                           
				AND IsInternal <= @IsInternal
		END
		ELSE IF @ToDate < @__archiveDate
		BEGIN
			SELECT COUNT(LogID)                      
			FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
				INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
			WHERE uc.CustID = @CustID
				AND LogDate BETWEEN @FromDate AND @ToDate                           
				AND IsInternal <= @IsInternal
		END
		ELSE
		BEGIN
			SELECT SUM(cnt)
			FROM (
				SELECT COUNT(LogID) cnt                          
				FROM dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
					INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
				WHERE uc.CustID = @CustID
					AND LogDate BETWEEN @__archiveDate AND @ToDate                           
					AND IsInternal <= @IsInternal

				UNION ALL
				SELECT COUNT(LogID) cnt                          
				FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
					INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
				WHERE uc.CustID = @CustID
					AND LogDate >= @FromDate AND LogDate < @__archiveDate                           
					AND IsInternal <= @IsInternal
			)t
		END
	END
	ELSE 
	BEGIN
		IF @FromDate >= @__archiveDate
		BEGIN
			SELECT COUNT(LogID)                           
			FROM dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
				INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
			WHERE uc.CustID = @CustID
				AND LogDate BETWEEN @FromDate AND @ToDate                           
				AND IsInternal <= @IsInternal
				AND ci.roleid <= 4
		END
		ELSE IF @ToDate < @__archiveDate
		BEGIN
			SELECT COUNT(LogID)                           
			FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
				INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
			WHERE uc.CustID = @CustID
				AND LogDate BETWEEN @FromDate AND @ToDate                           
				AND IsInternal <= @IsInternal
				AND ci.roleid <= 4
		END
		ELSE
		BEGIN
			SELECT SUM(cnt)
			FROM (
				SELECT COUNT(LogID) cnt                       
				FROM dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
					INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
				WHERE uc.CustID = @CustID
					AND LogDate BETWEEN @FromDate AND @ToDate                           
					AND IsInternal <= @IsInternal
					AND ci.roleid <= 4

				UNION ALL
				SELECT COUNT(LogID) cnt                        
				FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
					INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
				WHERE uc.CustID = @CustID
					AND LogDate BETWEEN @FromDate AND @ToDate                           
					AND IsInternal <= @IsInternal
					AND ci.roleid <= 4
			)t
		END
	END
END
GO
