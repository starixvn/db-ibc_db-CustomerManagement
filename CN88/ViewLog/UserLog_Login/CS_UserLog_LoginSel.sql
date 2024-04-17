/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="wsv_nap,bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[CS_UserLog_LoginSel]
    @UserId INT,
	@UserName AS VARCHAR(50),
    @FromDate DATETIME,
    @ToDate DATETIME,    
    @LogType TINYINT = 0,
    @PageIndex INT,
    @PageSize INT
AS 
/*  
	Created:20190606@Elodie
    Task: Get paged log login
    DB: DBLOG\bodb_CustomerLog
    
	Revisions:
		- 20190606@Elodie: Initial SP [Redmine: #113198]
	
    Param's Explaination:    
		- @UserId: a customer which we want to view actions affect to.
		- @UserName: customer name type in textbox to search
		- @FromDate: date range to view log
		- @ToDate: date range to view log
		- @TypeLog: 0: show log for customer (Main Alpha) 
					1: show log for Internal Alpha (link alpha tu ExtNap va Nap) 
					2: show log for Nap
		- @PageIndex: from 0
		- @PageSize: total record per request
*/
BEGIN
	SET NOCOUNT ON 
	--		BEGIN CALCULATE BEGIN RECORD INDEX AND END RECORD INDEX    
	SET @PageIndex = ABS(@PageIndex)
	SET @PageSize = ABS(@PageSize)          

	DECLARE @lbound INT 
	DECLARE @ubound INT

	SET @lbound = @PageIndex * @PageSize       
	
	SET @ubound = @lbound + @PageSize 
	IF ( @PageIndex > 0 ) 
		SET @lbound = @lbound + 1
	--		END CALCULATE BEGIN RECORD INDEX AND END RECORD INDEX

	--		PAGING QUERY

	--RETURN TO RETRIEVE DATA IF ROLEID = 1 
	DECLARE @RoleID tinyint, @srecommend int
	SELECT @RoleID = roleid, @srecommend = srecommend from bodb02.dbo.custinfo(nolock) where custid = @UserId
	IF (@RoleID = 1)
		RETURN
	--------------- hardcode for super ZZ---------------
	declare @hideLocation bit
	select @hideLocation = case when @srecommend=5532706 and SYSTEM_USER like 'bodbdownlinen%' then 1 else 0 end
	----------------------------------------------------

	DECLARE @__archiveDate DATETIME
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

	IF (@LogType = 0) AND NOT EXISTS (SELECT TOP 1 1 FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE username2 = @UserName)
	BEGIN
		IF @FromDate >= @__archiveDate
		BEGIN
			SELECT  LogID,
				UserID,
				Username,
				Doing,
				LogDate,
				ActionID,				
				IsInternal,				
				ActionName,
				SPName,
				case @hideLocation when 1 then '' else IP end IP,
				ServerID,
				Browser,
				Domain,
				[Platform],
				case @hideLocation when 1 then '' else CountryCode end CountryCode
			FROM    (
						 SELECT    ROW_NUMBER() OVER (ORDER BY  LogDate DESC) AS RowNum,
									LogID,
									UserID,
									@Username as  Username,
									Doing,
									LogDate,
									la.ActionID,	
									IsInternal,												
									la.ActionNameEN AS ActionName,
									la.SPName AS SPName,
									IP,
									ServerID, 
									BrowserName as Browser,
									DomainName as Domain,
									[Platform],
									CountryCode,
									username2
						  FROM      dbo.CS_UserLog_Login AS ul WITH(NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
									INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = ul.UserID
						  WHERE     LogDate BETWEEN @FromDate AND @ToDate	
									AND IsInternal = 0
									AND ((	UserID = @UserId AND SubAccID >= 0)
												--OR (SubAccID = @UserId)
											) 
									AND ci.roleid <=4
					) AS MyTable
			WHERE   RowNum BETWEEN @lbound AND @ubound
		END
		ELSE IF @ToDate < @__archiveDate
		BEGIN
			SELECT  LogID,
				UserID,
				Username,
				Doing,
				LogDate,
				ActionID,				
				IsInternal,				
				ActionName,
				SPName,
				case @hideLocation when 1 then '' else IP end IP,
				ServerID,
				Browser,
				Domain,
				[Platform],
				case @hideLocation when 1 then '' else CountryCode end CountryCode
			FROM    (
						 SELECT    ROW_NUMBER() OVER (ORDER BY  LogDate DESC) AS RowNum,
									LogID,
									UserID,
									@Username as  Username,
									Doing,
									LogDate,
									la.ActionID,	
									IsInternal,												
									la.ActionNameEN AS ActionName,
									la.SPName AS SPName,
									IP,
									ServerID, 
									BrowserName as Browser,
									DomainName as Domain,
									[Platform],
									CountryCode,
									username2
						  FROM     bodb_CustomerLog_Archive.dbo.CS_UserLog_Login AS ul WITH(NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
									INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = ul.UserID
						  WHERE     LogDate BETWEEN @FromDate AND @ToDate	
									AND IsInternal = 0
									AND ((	UserID = @UserId AND SubAccID >= 0)
												--OR (SubAccID = @UserId)
											) 
									AND ci.roleid <=4
					) AS MyTable
			WHERE   RowNum BETWEEN @lbound AND @ubound
		END
		ELSE
		BEGIN
			SELECT  LogID,
				UserID,
				Username,
				Doing,
				LogDate,
				ActionID,				
				IsInternal,				
				ActionName,
				SPName,
				case @hideLocation when 1 then '' else IP end IP,
				ServerID,
				Browser,
				Domain,
				[Platform],
				case @hideLocation when 1 then '' else CountryCode end CountryCode
			FROM    (
						 SELECT ROW_NUMBER() OVER (ORDER BY  LogDate DESC) AS RowNum, *
						 FROM (
							SELECT LogID,
									UserID,
									@Username as  Username,
									Doing,
									LogDate,
									la.ActionID,	
									IsInternal,												
									la.ActionNameEN AS ActionName,
									la.SPName AS SPName,
									IP,
									ServerID, 
									BrowserName as Browser,
									DomainName as Domain,
									[Platform],
									CountryCode,
									username2
						  FROM      dbo.CS_UserLog_Login AS ul WITH(NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
									INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = ul.UserID
						  WHERE     LogDate BETWEEN @__archiveDate AND @ToDate	
									AND IsInternal = 0
									AND ((	UserID = @UserId AND SubAccID >= 0)
												--OR (SubAccID = @UserId)
											) 
									AND ci.roleid <= 4

						UNION ALL
						SELECT LogID,
									UserID,
									@Username as  Username,
									Doing,
									LogDate,
									la.ActionID,	
									IsInternal,												
									la.ActionNameEN AS ActionName,
									la.SPName AS SPName,
									IP,
									ServerID, 
									BrowserName as Browser,
									DomainName as Domain,
									[Platform],
									CountryCode,
									username2
						  FROM      bodb_CustomerLog_Archive.dbo.CS_UserLog_Login AS ul WITH(NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
									INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = ul.UserID
						  WHERE     LogDate >= @FromDate AND LogDate < @__archiveDate	
									AND IsInternal = 0
									AND ((	UserID = @UserId AND SubAccID >= 0)
												--OR (SubAccID = @UserId)
											) 
									AND ci.roleid <= 4
						) AS MyTable1
					) AS MyTable
			WHERE   RowNum BETWEEN @lbound AND @ubound
		END
	END
	ELSE
	IF (@LogType = 1 OR @LogType = 2) 
	BEGIN
		IF @FromDate >= @__archiveDate
		BEGIN
			SELECT  LogID,
					UserID,
					Username,
					Doing + CASE WHEN ISNULL(username2,'') <>'' THEN ' - Nickname: '+ username2 ELSE '' END as Doing,
					LogDate,
					ActionID,				
					IsInternal,
					ActionName,
					SPName,
					case @hideLocation when 1 then '' else IP end IP,
					ServerID,
					Browser,
					Domain,
					[Platform],
					case @hideLocation when 1 then '' else CountryCode end CountryCode
			FROM    (
						 SELECT    ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum,
									LogID,
									UserID,
									@Username as Username,
									Doing,
									LogDate,
									la.ActionID,	
									IsInternal,											
									la.ActionNameEN AS ActionName,
									la.SPName AS SPName,
									IP,
									ServerID,BrowserName as Browser,
									DomainName as Domain,
									[Platform],
									CountryCode, 
									username2
						  FROM      dbo.CS_UserLog_Login AS ul WITH(NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
						  WHERE     LogDate BETWEEN @FromDate AND @ToDate								
									--AND IsInternal <= 1
									AND UserID = @UserId
											--AND SubAccID <= 0)
											--OR (SubAccID = @UserId)
									AND (la.ActionID <> 1301 OR @LogType = 2)								
					) AS MyTable
			WHERE   RowNum BETWEEN @lbound AND @ubound
		END
		ELSE IF @ToDate < @__archiveDate
		BEGIN
			SELECT  LogID,
					UserID,
					Username,
					Doing + CASE WHEN ISNULL(username2,'') <>'' THEN ' - Nickname: '+ username2 ELSE '' END as Doing,
					LogDate,
					ActionID,				
					IsInternal,
					ActionName,
					SPName,
					case @hideLocation when 1 then '' else IP end IP,
					ServerID,
					Browser,
					Domain,
					[Platform],
					case @hideLocation when 1 then '' else CountryCode end CountryCode
			FROM    (
						 SELECT    ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum,
									LogID,
									UserID,
									@Username as Username,
									Doing,
									LogDate,
									la.ActionID,	
									IsInternal,											
									la.ActionNameEN AS ActionName,
									la.SPName AS SPName,
									IP,
									ServerID,BrowserName as Browser,
									DomainName as Domain,
									[Platform],
									CountryCode, 
									username2
						  FROM      bodb_CustomerLog_Archive.dbo.CS_UserLog_Login AS ul WITH(NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
						  WHERE     LogDate BETWEEN @FromDate AND @ToDate								
									--AND IsInternal <= 1
									AND UserID = @UserId
											--AND SubAccID <= 0)
											--OR (SubAccID = @UserId)
									AND (la.ActionID <> 1301 OR @LogType = 2)								
					) AS MyTable
			WHERE   RowNum BETWEEN @lbound AND @ubound
		END
		ELSE
		BEGIN
			SELECT  LogID,
					UserID,
					Username,
					Doing + CASE WHEN ISNULL(username2,'') <>'' THEN ' - Nickname: '+ username2 ELSE '' END as Doing,
					LogDate,
					ActionID,				
					IsInternal,
					ActionName,
					SPName,
					case @hideLocation when 1 then '' else IP end IP,
					ServerID,
					Browser,
					Domain,
					[Platform],
					case @hideLocation when 1 then '' else CountryCode end CountryCode
			FROM    (
						 SELECT    ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum, *
						 FROM (
							SELECT LogID,
									UserID,
									@Username as Username,
									Doing,
									LogDate,
									la.ActionID,	
									IsInternal,											
									la.ActionNameEN AS ActionName,
									la.SPName AS SPName,
									IP,
									ServerID,BrowserName as Browser,
									DomainName as Domain,
									[Platform],
									CountryCode, 
									username2
						  FROM      dbo.CS_UserLog_Login AS ul WITH(NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
						  WHERE     LogDate BETWEEN @__archiveDate AND @ToDate								
									--AND IsInternal <= 1
									AND UserID = @UserId
											--AND SubAccID <= 0)
											--OR (SubAccID = @UserId)
									AND (la.ActionID <> 1301 OR @LogType = 2)	

						UNION ALL
						SELECT LogID,
									UserID,
									@Username as Username,
									Doing,
									LogDate,
									la.ActionID,	
									IsInternal,											
									la.ActionNameEN AS ActionName,
									la.SPName AS SPName,
									IP,
									ServerID,BrowserName as Browser,
									DomainName as Domain,
									[Platform],
									CountryCode, 
									username2
						  FROM      bodb_CustomerLog_Archive.dbo.CS_UserLog_Login AS ul WITH(NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
						  WHERE     LogDate >= @FromDate AND LogDate < @__archiveDate								
									--AND IsInternal <= 1
									AND UserID = @UserId
											--AND SubAccID <= 0)
											--OR (SubAccID = @UserId)
									AND (la.ActionID <> 1301 OR @LogType = 2)	
						) AS MyTable1
					) AS MyTable
			WHERE   RowNum BETWEEN @lbound AND @ubound
		END
	END
END
GO