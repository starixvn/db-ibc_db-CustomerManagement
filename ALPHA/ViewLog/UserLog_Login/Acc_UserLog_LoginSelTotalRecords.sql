/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="wsv_nap,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UserLog_LoginSelTotalRecords]
    @UserId INT,	
	@UserName AS VARCHAR(50),
    @FromDate DATETIME,
    @ToDate DATETIME,    
    @LogType TINYINT = 0
	   
AS
/* Created:20100121@Lewin
    Task: ViewLog function 331
    DB: DBLOG.bodb_CustomerLog

	Description:
	- count total record with input conditions
	Revisions:
	- 20100710@Kiwi: put in a check to return retrieving data if roleid = 1
	- 20100711@Thien: add index hint
	- 20101214@Thien: comment out "OR (SubAccID = @UserId)" for performance improvement
	- 20110526@Jamie: Allow agency/admin view sub-account log
	- 20171214@Vicky: NAP - View Log - The login log of Internal Admin arenot shown when NAP Admin views SMA's logs [Redmine: #87841]
	- 20190405@Patrick: Support archive date range [Redmine: #111476]
	- 20190619@Johnson: show log kickout for member[redmine: #114566]
	- 20210618@Elodie: call link server DBEXT to use index 

    Param's Explaination:    
	- @CustID: a customer which we want to view actions affect to.
	- @FromDate: date range to view log
	- @ToDate: date range to view log	
	- @TypeLog: 0: show log for customer (Main Alpha) 
	            1: show log for Internal Alpha (link alpha tu ExtNap va Nap) 
	            2: show log for Nap
	
*/
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON ;
--RETURN TO RETRIEVE DATA IF ROLEID = 1 
DECLARE @RoleID tinyint, @ActionID_KO INT = 1331 --log action of kickout for member
SELECT @RoleID = roleid from bodb02.dbo.custinfo(nolock) where custid = @UserId
--IF (@RoleID = 1)
--	RETURN

DECLARE @__archiveDate DATETIME
SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

IF (@LogType = 0) AND NOT EXISTS (SELECT TOP 1 1 FROM DBEXT.bodb02.dbo.Customer WITH (NOLOCK) WHERE username2 = @UserName)
BEGIN
	IF @FromDate >= @__archiveDate
	BEGIN
		SELECT  COUNT(LogID)                           
		FROM    dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
				INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
				INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = ul.UserID
		WHERE    LogDate BETWEEN @FromDate AND @ToDate			
				AND IsInternal = 0
				AND ((	UserID = @UserId AND SubAccID >= 0)
						--OR (SubAccID = @UserId)
						)
				AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)								
				AND ci.roleid <=4
	END
	ELSE IF @ToDate < @__archiveDate
	BEGIN
		SELECT  COUNT(LogID)                           
		FROM    bodb_CustomerLog_Archive.dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
				INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
				INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = ul.UserID
		WHERE    LogDate BETWEEN @FromDate AND @ToDate			
				AND IsInternal = 0
				AND ((	UserID = @UserId AND SubAccID >= 0)
						--OR (SubAccID = @UserId)
						)
				AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)								
				AND ci.roleid <=4
	END
	ELSE
	BEGIN
		SELECT SUM(cnt)
		FROM (
			SELECT  COUNT(LogID) cnt                         
			FROM    dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
					INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
					INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = ul.UserID
			WHERE    LogDate BETWEEN @__archiveDate AND @ToDate			
					AND IsInternal = 0
					AND ((	UserID = @UserId AND SubAccID >= 0)
							--OR (SubAccID = @UserId)
							)
					AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)								
					AND ci.roleid <=4

			UNION ALL
			SELECT  COUNT(LogID) cnt                        
			FROM    bodb_CustomerLog_Archive.dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
					INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
					INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = ul.UserID
			WHERE    LogDate >= @FromDate AND LogDate < @__archiveDate			
					AND IsInternal = 0
					AND ((	UserID = @UserId AND SubAccID >= 0)
							--OR (SubAccID = @UserId)
							)
					AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)								
					AND ci.roleid <=4
		)t
	END
END
ELSE
IF (@LogType = 1 OR @LogType = 2) 
BEGIN

	IF @FromDate >= @__archiveDate
	BEGIN
		SELECT  COUNT(LogID)                           
		FROM    dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
				INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
		WHERE     LogDate BETWEEN @FromDate AND @ToDate			
				--AND IsInternal <= @IsAdminAccess
				AND UserID = @UserId 
						-- AND SubAccID <= 0)
						--OR (SubAccID = @UserId)
				AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)										
				AND (la.ActionID <> 1301 OR @LogType = 2)
	END
	ELSE IF @ToDate < @__archiveDate
	BEGIN
		SELECT  COUNT(LogID)                           
		FROM    bodb_CustomerLog_Archive.dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
				INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
		WHERE     LogDate BETWEEN @FromDate AND @ToDate			
				--AND IsInternal <= @IsAdminAccess
				AND UserID = @UserId 
						-- AND SubAccID <= 0)
						--OR (SubAccID = @UserId)
				AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)										
				AND (la.ActionID <> 1301 OR @LogType = 2)
	END
	ELSE
	BEGIN
		SELECT SUM(cnt)
		FROM (
			SELECT  COUNT(LogID) cnt
			FROM    dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
					INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
			WHERE   LogDate BETWEEN @__archiveDate AND @ToDate			
					--AND IsInternal <= @IsAdminAccess
					AND UserID = @UserId 
							-- AND SubAccID <= 0)
							--OR (SubAccID = @UserId)
					AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)										
					AND (la.ActionID <> 1301 OR @LogType = 2)

			UNION ALL
			SELECT  COUNT(LogID) cnt
			FROM    bodb_CustomerLog_Archive.dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
					INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
			WHERE     LogDate >= @FromDate AND LogDate < @__archiveDate			
					--AND IsInternal <= @IsAdminAccess
					AND UserID = @UserId 
							-- AND SubAccID <= 0)
							--OR (SubAccID = @UserId)
					AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)										
					AND (la.ActionID <> 1301 OR @LogType = 2)
		)t
	END
END
GO