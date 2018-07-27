/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/

USE [bodb_CustomerLog]
GO
ALTER PROCEDURE [dbo].[Acc_UserLog_RunSPSel]    
    @CustId INT,
	@CustName VARCHAR(50) = '',
    @FromDate DATETIME,
    @ToDate DATETIME,
    @ActionTypeId INT = -1,
    @IsInternal TINYINT,
    @LowerActionId INT = NULL,
	@UpperActionId INT = NULL,
    @PageIndex INT,
    @PageSize INT
AS 
/* Created:20100121@Lewin
    Task: ViewLog function 331
    DB: DBLOG/bodb_CustomerLog
    
    Revisions:
		- 20110421@Jamie: Temporiraly fix to show Logs updated from Licensee Risk and Forecast 
		- 20110511@Henry: Change LRF ActionID to new Range (2000-2299)
		- 20110513@Amy: Get more column TrackingValue2 
		- 20110721@Sophia: If is Internal access and @custName is nickname then don't show data
		- 20121029@Elodie: Get UseName = 'Admin' if ActionID BETWEEN 1142 AND 1144
		- 20140708@Dom: Do not show any log info (including log of Supers, Masters, Agents and Members) updated by Admin relate to all log categories [Redmine: #18125]
		- 20160115@Dominic: Do not show logactionid=237 if Trackingvalues is null Redmine: #50937
		- 20160222@Dominic: Correct TrackingValue when logactionid In (1100,1101,1102,1103) and its value contain 'Hide*Cricket' Redmine: #52667
		- 20160222@Dominic: Correct TrackingValue when logactionid In (1100,1101,1102,1103) and its value contain 'Hide*Cricket' Redmine: #52667
		- 20161018@Winnie: Handle logactionid range of smartpunter RedmineID #63077
		- 20171205@Winnie: Provide API for FPS to update dangerous level for evidence member #86627
		- 20180123@Johnson: support view log for status by level for new direction[Redmine: #87328]
		- 20180621@Razor: Exclude log of Message Customer Read Status [Redmind: #94705]
	Description:
	- Get paged log run sp. If @LowerActionId and @UpperActionId are both not null, get actions in range 
	
    Param's Explaination:    
	- @UserId: a customer which we want to view actions affect to.
	- @CustName: customer name type in textbox to search
	- @FromDate: date range to view log
	- @ToDate: date range to view log
	- @ActionTypeId: action type. If ActionType < 0: select all type
	- @IsInternal: accounting site = 1, agent = 0
	- @LowerActionId: query actionid in range
	- @UpperActionId: query actionid in range	
	- @PageIndex: from 0
	- @PageSize: total record per request
*/
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
BEGIN
	SET NOCOUNT ON ;

	SET @PageIndex = ABS(@PageIndex)
	SET @PageSize = ABS(@PageSize)  

	DECLARE @lbound INT 
			,@ubound INT
			,@roleid TINYINT
			,@srecommend INT
			,@mrecommend INT
			,@recommend INT
			,@creatdate DATETIME
			
	DECLARE @tmpCust TABLE(Custid INT)		
	CREATE TABLE #tmpLog (LogID BIGINT,
						UserID INT,
						Username NVARCHAR(100),
						TrackingValue NVARCHAR(MAX),
						TrackingValueOld NVARCHAR(MAX),
						LogDate DATETIME,
						ActionID INT,
						ActionTypeID INT,
						SPName VARCHAR(50),
						IsInternal BIT,
						CustID INT,
						CustName NVARCHAR(100),
						ActionName NVARCHAR(512)
					)
					
	SELECT @srecommend = srecommend, 
		@mrecommend = mrecommend, 
		@recommend = recommend, 
		@roleid = roleid,
		@creatdate = creatdate
	FROM bodb02.dbo.Customer WITH(NOLOCK)
	WHERE custid = @CustID
	
	IF @FromDate < @creatdate
		SELECT @FromDate = @creatdate
		
	SET @lbound = @PageIndex * @PageSize       
		
	SET @ubound = @lbound + @PageSize 
	IF ( @PageIndex > 0 ) 
		SET @lbound = @lbound + 1

	IF (@IsInternal = 0 AND NOT EXISTS (SELECT TOP 1 1 FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE username2 = @CustName))
		OR (@IsInternal = 1)
	BEGIN 
		IF  (@LowerActionId IS NULL OR @UpperActionId IS NULL)       
		BEGIN
			select @LowerActionId=1100, @UpperActionId=1199	 --exclude to select Customer Status
			IF (@ActionTypeId > 0)						
			BEGIN
				IF @ActionTypeID = 5--for status
				BEGIN
					--old log status has actionid from 1100 and 1199
					INSERT INTO #tmpLog
						(LogID,
						UserID,
						Username,
						TrackingValue,
						TrackingValueOld,
						LogDate,
						ActionID,
						ActionTypeID,
						SPName,
						IsInternal,
						CustID,
						CustName,
						ActionName
						)
					 SELECT    LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
												ELSE c.Username
											END,
								CASE WHEN ul.ActionID IN  (1100,1101,1102,1103) AND ul.TrackingValue LIKE '%Hide*Cricket%' 
										THEN REPLACE(TrackingValue,'Hide*Cricket','HideCricket') 
										ELSE ul.TrackingValue END TrackingValue,
								TrackingValue2,
								LogDate,
								la.ActionID,
								ActionTypeID,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
					  FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					  WHERE     ul.CustID = @CustId
								AND LogDate BETWEEN @FromDate AND @ToDate
								AND la.ActionTypeID = @ActionTypeId
								AND la.ActionID BETWEEN 1100 AND 1199
								AND IsInternal <= @IsInternal
								AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
								AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)	
								AND ul.ActionID NOT BETWEEN 31000 AND 31100		
					
					--new range logactionid for status by level
					SELECT @LowerActionId = CASE @roleid WHEN 4 THEN 60000
														WHEN 3 THEN 65000
														WHEN 2 THEN 70000
														WHEN 1 THEN 75000 END,
							@UpperActionId = CASE @roleid WHEN 4 THEN 64999
														WHEN 3 THEN 69999
														WHEN 2 THEN 74999
														WHEN 1 THEN 79999 END									
					
					INSERT INTO @tmpCust(CustID)
					SELECT @CustID 
					UNION SELECT @srecommend WHERE @roleid<4
					UNION SELECT @mrecommend WHERE @roleid<3
					UNION SELECT @recommend WHERE @roleid<2
					
					INSERT INTO #tmpLog
						(LogID,
						UserID,
						Username,
						TrackingValue,
						TrackingValueOld,
						LogDate,
						ActionID,
						ActionTypeID,
						SPName,
						IsInternal,
						CustID,
						CustName,
						ActionName
						)
					 SELECT    LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
												ELSE c.Username
											END,
								CASE WHEN ul.ActionID IN  (1100,1101,1102,1103) AND ul.TrackingValue LIKE '%Hide*Cricket%' 
										THEN REPLACE(TrackingValue,'Hide*Cricket','HideCricket') 
										ELSE ul.TrackingValue END TrackingValue,
								TrackingValue2,
								LogDate,
								la.ActionID,
								ActionTypeID,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
					  FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					  WHERE     ul.CustID IN (SELECT custid FROM @tmpCust)
								AND LogDate BETWEEN @FromDate AND @ToDate
								AND la.ActionTypeID = @ActionTypeId
								AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
								AND IsInternal <= @IsInternal
								--show these actions on alpha
								--AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
								AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)	
								AND ul.ActionID NOT BETWEEN 31000 AND 31100
								
					SELECT  LogID,
						UserID,
						Username,
						TrackingValue,
						TrackingValueOld,
						LogDate,
						ActionID,
						ActionTypeID,
						SPName,
						IsInternal,
						CustID,
						CustName,
						ActionName
									
					FROM    (
						 SELECT    ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum,
									LogID,
									UserID,
									Username,
									TrackingValue,
									TrackingValueOld,
									LogDate,
									ActionID,
									ActionTypeID,
									SPName,
									IsInternal,
									CustID,
									CustName,
									ActionName
						  FROM  #tmpLog					
						) AS MyTable
					WHERE   RowNum BETWEEN @lbound AND @ubound
				END--end @ActionTypeID = 5
				ELSE
				BEGIN 
					SELECT  LogID,
						UserID,
						Username,
						TrackingValue,
						TrackingValue2 as TrackingValueOld,
						LogDate,
						ActionID,
						ActionTypeID,
						SPName,
						IsInternal,
						CustID,
						CustName,
						ActionName
									
					FROM    (
						 SELECT    ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum,
									LogID,
									UserID,
									Username =	CASE 
													when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
													when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
													ELSE c.Username
												END,
									CASE WHEN ul.ActionID IN  (1100,1101,1102,1103) AND ul.TrackingValue LIKE '%Hide*Cricket%' 
											THEN REPLACE(TrackingValue,'Hide*Cricket','HideCricket') 
											ELSE ul.TrackingValue END TrackingValue,
									TrackingValue2,
									LogDate,
									la.ActionID,
									ActionTypeID,
									la.SPName,
									IsInternal,
									ul.CustID,
									@CustName AS CustName,
									la.ActionNameEN AS ActionName
						  FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
									LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						  WHERE     ul.CustID = @CustId
									AND LogDate BETWEEN @FromDate AND @ToDate
									AND  la.ActionTypeID = @ActionTypeId
									AND IsInternal <= @IsInternal
									AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
									AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)	
									AND ul.ActionID NOT BETWEEN 31000 AND 31100					
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
						) AS MyTable
					WHERE   RowNum BETWEEN @lbound AND @ubound
				END	
			END--end (@ActionTypeId > 0)	
			ELSE 
			BEGIN
				SELECT  LogID,
					UserID,
					Username,
					TrackingValue,
					TrackingValue2 as TrackingValueOld,
					LogDate,
					ActionID,
					ActionTypeID,
					SPName,
					IsInternal,
					CustID,
					CustName,
					ActionName
								
				FROM (
					 SELECT    ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum,
								LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												when (la.ActionID BETWEEN 2000 AND 3000 OR la.ActionID BETWEEN 1142 AND 1144) then 'Admin'
												ELSE c.Username
											END,
								CASE WHEN ul.ActionID IN  (1100,1101,1102,1103) AND ul.TrackingValue LIKE '%Hide*Cricket%' 
										THEN REPLACE(TrackingValue,'Hide*Cricket','HideCricket') 
										ELSE ul.TrackingValue END TrackingValue,
								LogDate,
								la.ActionID,
								ActionTypeID,
								TrackingValue2,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
					 FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					  WHERE     ul.CustID = @CustId
								AND LogDate BETWEEN @FromDate AND @ToDate				
								AND IsInternal <= @IsInternal
								--exclude log action of status
								AND la.ActionID NOT BETWEEN 1100 AND 1199
								AND la.ActionID NOT BETWEEN 60000 AND 79999
								AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
								AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
								AND ul.ActionID NOT BETWEEN 31000 AND 31100
						AND ul.ActionId <> 1050 --Message Customer Read Status Update

					) AS MyTable
				WHERE   RowNum BETWEEN @lbound AND @ubound
			END	
		END --end (@LowerActionId IS NULL OR @UpperActionId IS NULL) 
		ELSE
		BEGIN
			SELECT  LogID,
					UserID,
					Username,
					TrackingValue,
					TrackingValue2 as TrackingValueOld,
					LogDate,
					ActionID,
					ActionTypeID,
					SPName,
					IsInternal,
					CustID,
					CustName,
					ActionName
								
			FROM    ( SELECT    ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum,
								LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												when (la.ActionID BETWEEN 2000 AND 3000 OR la.ActionID BETWEEN 1142 AND 1144 OR la.ActionID=1165) then 'Admin'
												ELSE c.Username
											END,
								CASE WHEN ul.ActionID IN  (1100,1101,1102,1103) AND ul.TrackingValue LIKE '%Hide*Cricket%' 
										THEN REPLACE(TrackingValue,'Hide*Cricket','HideCricket') 
										ELSE ul.TrackingValue END TrackingValue,
								TrackingValue2,
								LogDate,
								la.ActionID,
								ActionTypeID,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
					 FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID					
					  WHERE     ul.CustID = @CustId
								AND LogDate BETWEEN @FromDate AND @ToDate
								AND la.actionid BETWEEN @LowerActionId AND @UpperActionId
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
								AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
								
					) AS MyTable
			WHERE   RowNum BETWEEN @lbound AND @ubound
		END
	END
END

GO