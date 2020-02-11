/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UserLog_LoginSel]
    @UserId INT,
	@UserName AS VARCHAR(50),
    @FromDate DATETIME,
    @ToDate DATETIME,    
    @LogType TINYINT = 0,
    @PageIndex INT,
    @PageSize INT
AS 
/* Created:20100121@Lewin
    Task: ViewLog function 331
    DB: DBLOG.bodb_CustomerLog

	Description:
	- Get paged log credit
	Revisions:
	- 20100710@Kiwi: put in a check to return retrieving data if roleid = 1
	- 20100711@Thien: add index hint
	- 20101019@Anders: query extra columns: Browser, Domain, Platform, CountryCode
	- 20101214@Thien: comment out "OR (SubAccID = @UserId)" for performance improvement
	- 20110526@Jamie: Allow agency/admin view sub-account log
	- 20110608@Sophia: Show nickname for account site when customer login nickname
	- 20110623@Sophia: Do not allow to search for Nickname if @IsAdminAccess = 0
	- 20110715@Sophia: Edit prefix of username2
	- 20120914@Viet: hide IP/country for customer under super ZZ from agentsite's viewlog only
	- 20140708@Dom: Do not show any log info (including log of Supers, Masters, Agents and Members) updated by Admin relate to all log categories [Redmine: #18125]
	- 20160321@Percy: Do not show any Internal Admin's log for External Admin [Redmine: #53932]
	- 20171214@Vicky: NAP - View Log - The login log of Internal Admin arenot shown when NAP Admin views SMA's logs [Redmine: #87841]
	- 20190405@Patrick: Support archive date range [Redmine: #111476]
	- 20190619@Johnson: show log kickout for member[redmine: #114566]
	- 20191113@Winnie: Alpha - View Log : user can view total records when searching by nickname [Redmine: #110148]

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

SET NOCOUNT ON ;
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
DECLARE @RoleID tinyint, @srecommend int,@ActionID_KO INT = 1331 --log action of kickout for member
SELECT @RoleID = roleid, @srecommend = srecommend from bodb02.dbo.custinfo(nolock) where custid = @UserId

--IF (@RoleID = 1)
--	RETURN
--------------- hardcode for super ZZ---------------
declare @hideLocation bit
select @hideLocation = case when @srecommend=5532706 and SYSTEM_USER like 'bodbdownlinen%' then 1 else 0 end
----------------------------------------------------

DECLARE @__archiveDate DATETIME
SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

IF @LogType = 0
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
					  FROM      dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
								INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
								INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = ul.UserID
					  WHERE     LogDate BETWEEN @FromDate AND @ToDate	
								AND IsInternal = 0
								AND ((	UserID = @UserId AND SubAccID >= 0)
											--OR (SubAccID = @UserId)
										) 
								AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)						
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
					  FROM     bodb_CustomerLog_Archive.dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
								INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
								INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = ul.UserID
					  WHERE     LogDate BETWEEN @FromDate AND @ToDate	
								AND IsInternal = 0
								AND ((	UserID = @UserId AND SubAccID >= 0)
											--OR (SubAccID = @UserId)
										)
								AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)				
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
					  FROM      dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
								INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
								INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = ul.UserID
					  WHERE     LogDate BETWEEN @__archiveDate AND @ToDate	
								AND IsInternal = 0
								AND ((	UserID = @UserId AND SubAccID >= 0)
											--OR (SubAccID = @UserId)
										) 
								AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)						
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
					  FROM      bodb_CustomerLog_Archive.dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
								INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
								INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = ul.UserID
					  WHERE     LogDate >= @FromDate AND LogDate < @__archiveDate	
								AND IsInternal = 0
								AND ((	UserID = @UserId AND SubAccID >= 0)
											--OR (SubAccID = @UserId)
										) 
								AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)						
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
					  FROM      dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
								INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
					  WHERE     LogDate BETWEEN @FromDate AND @ToDate								
								--AND IsInternal <= 1
								AND UserID = @UserId
										--AND SubAccID <= 0)
										--OR (SubAccID = @UserId)
								AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)						
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
					  FROM      bodb_CustomerLog_Archive.dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
								INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
					  WHERE     LogDate BETWEEN @FromDate AND @ToDate								
								--AND IsInternal <= 1
								AND UserID = @UserId
										--AND SubAccID <= 0)
										--OR (SubAccID = @UserId)
								AND (la.ActionID <> 1301 OR @LogType = 2)	
								AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)						
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
					  FROM      dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
								INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
					  WHERE     LogDate BETWEEN @__archiveDate AND @ToDate								
								--AND IsInternal <= 1
								AND UserID = @UserId
										--AND SubAccID <= 0)
										--OR (SubAccID = @UserId)
								AND (la.ActionID <> 1301 OR @LogType = 2)
								AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)						

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
					  FROM      bodb_CustomerLog_Archive.dbo.UserLog_Login AS ul WITH(NOLOCK, index=CIX_LogDate_User)
								INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
					  WHERE     LogDate >= @FromDate AND LogDate < @__archiveDate								
								--AND IsInternal <= 1
								AND UserID = @UserId
										--AND SubAccID <= 0)
										--OR (SubAccID = @UserId)
								AND (la.ActionID <> 1301 OR @LogType = 2)
								AND la.ActionID = (CASE WHEN @roleid = 1 THEN @ActionID_KO ELSE la.ActionID END)				
					) AS MyTable1
				) AS MyTable
		WHERE   RowNum BETWEEN @lbound AND @ubound
	END
END
GO