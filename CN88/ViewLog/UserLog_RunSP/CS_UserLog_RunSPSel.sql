/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[CS_UserLog_RunSPSel]    
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
/* 
	Created:20190606@Elodie
    Task: Get paged log run sp. If @LowerActionId and @UpperActionId are both not null, get actions in range 
    DB: DBLOG\bodb_CustomerLog
    
	Revisions:
		- 20190606@Elodie: Initial SP [Redmine: #113198]
		
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
	SET NOCOUNT ON

	SELECT @PageIndex = ABS(@PageIndex), @PageSize = ABS(@PageSize)  

	DECLARE @lbound INT, @ubound INT,
			@roleid TINYINT, @creatdate DATETIME,
			@srecommend INT, @mrecommend INT, @recommend INT,
			@LowerActionIdStatus INT, @UpperActionIdStatus INT, @i INT = 1000000

	DECLARE @tmpCust TABLE(Custid INT)		
	CREATE TABLE #tmpLog (LogID BIGINT, UserID INT, Username NVARCHAR(100), TrackingValue NVARCHAR(MAX), TrackingValueOld NVARCHAR(MAX), LogDate DATETIME,
							ActionID INT, ActionTypeID INT, SPName VARCHAR(50), IsInternal BIT, CustID INT, CustName NVARCHAR(100), ActionName NVARCHAR(512))
					
	SELECT	@srecommend = srecommend, 
			@mrecommend = mrecommend, 
			@recommend = recommend, 
			@roleid = roleid,
			@creatdate = creatdate
	FROM bodb02.dbo.Customer WITH(NOLOCK)
	WHERE custid = @CustID
	
	IF @FromDate < @creatdate
		SELECT @FromDate = DATEADD(SECOND,-30,@creatdate)--@Johnson: backward 30s to get log [#97633]
		
	SET @lbound = @PageIndex * @PageSize       
		
	SET @ubound = @lbound + @PageSize 
	IF ( @PageIndex > 0 ) 
		SET @lbound = @lbound + 1

	DECLARE @__archiveDate DATETIME
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

	IF (@IsInternal = 0 AND NOT EXISTS (SELECT TOP 1 1 FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE username2 = @CustName))
		OR (@IsInternal = 1)
	BEGIN 
		IF  (@LowerActionId IS NULL OR @UpperActionId IS NULL)       
		BEGIN
			IF (@ActionTypeId > 0)						
			BEGIN
				IF @ActionTypeID = 5--for status
				BEGIN
					INSERT INTO @tmpCust(CustID)
					SELECT @CustID 
					--new range logactionid for status by level
					SELECT @LowerActionIdStatus = CASE @roleid WHEN 4 THEN 60000
														WHEN 3 THEN 65000
														WHEN 2 THEN 70000
														WHEN 1 THEN 75000 END,
							@UpperActionIdStatus = CASE @roleid WHEN 4 THEN 64999
														WHEN 3 THEN 69999
														WHEN 2 THEN 74999
														WHEN 1 THEN 79999 END

					IF @FromDate >= @__archiveDate
					BEGIN
						--old log status has actionid from 1100 and 1199
						INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
							, SPName, IsInternal, CustID, CustName, ActionName)
						 SELECT LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												when (la.ActionID BETWEEN 1142 AND 1144 OR la.ActionID=1165) then 'Admin'
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
						 FROM	@tmpCust tmp
								CROSS APPLY (	SELECT TOP (@i) * 
												FROM dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK) 
												WHERE ul.custid = tmp.Custid 
													AND LogDate BETWEEN @FromDate AND @ToDate) ul
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE	la.ActionTypeID = @ActionTypeId
								AND (la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						OPTION (OPTIMIZE FOR (@i = 1))
					
						INSERT INTO @tmpCust(CustID)
						SELECT @srecommend WHERE @roleid<4
						UNION SELECT @mrecommend WHERE @roleid<3
						UNION SELECT @recommend WHERE @roleid<2
					
						INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
							, SPName, IsInternal, CustID, CustName, ActionName)
						SELECT  LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												ELSE c.Username
											END,
								ul.TrackingValue,
								TrackingValue2,
								LogDate,
								la.ActionID,
								ActionTypeID,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
						FROM	@tmpCust tmp
								CROSS APPLY (	SELECT TOP (@i) * 
												FROM dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK) 
												WHERE ul.custid = tmp.Custid 
													AND LogDate BETWEEN @FromDate AND @ToDate) ul
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE	la.ActionID BETWEEN @LowerActionIdStatus AND @UpperActionIdStatus
								AND la.ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								--dont show these actions on alpha
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						OPTION (OPTIMIZE FOR (@i = 1))

						INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
							, SPName, IsInternal, CustID, CustName, ActionName)
						 SELECT LogID,
								UserID,
								Username =	CASE WHEN (c.RoleId > 4 and @IsInternal=0) THEN 'Admin' ELSE c.Username END,
								ul.TrackingValue,
								TrackingValue2,
								LogDate,
								la.ActionID,
								ActionTypeID,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
						 FROM	@tmpCust tmp
								CROSS APPLY (	SELECT TOP (@i) mt.*, lt.CustID
												FROM dbo.CS_UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 
													INNER JOIN dbo.CS_UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID
												WHERE lt.custid = tmp.Custid 
													AND mt.LogDate BETWEEN @FromDate AND @ToDate) ul
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE	la.ActionTypeID = @ActionTypeId
								AND la.ActionID = 165004
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						OPTION (OPTIMIZE FOR (@i = 1))

					END
					ELSE IF @ToDate < @__archiveDate
					BEGIN
						--old log status has actionid from 1100 and 1199
						INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
							, SPName, IsInternal, CustID, CustName, ActionName)
						 SELECT LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												when (la.ActionID BETWEEN 1142 AND 1144 OR la.ActionID=1165) then 'Admin'
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
						 FROM	@tmpCust tmp
								CROSS APPLY (	SELECT TOP (@i) * 
												FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK) 
												WHERE ul.custid = tmp.Custid 
													AND LogDate BETWEEN @FromDate AND @ToDate) ul
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE	la.ActionTypeID = @ActionTypeId
								AND (la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						OPTION (OPTIMIZE FOR (@i = 1))
					
						INSERT INTO @tmpCust(CustID)
						SELECT @srecommend WHERE @roleid<4
						UNION SELECT @mrecommend WHERE @roleid<3
						UNION SELECT @recommend WHERE @roleid<2
					
						INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
							, SPName, IsInternal, CustID, CustName, ActionName)
						SELECT  LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												ELSE c.Username
											END,
								ul.TrackingValue,
								TrackingValue2,
								LogDate,
								la.ActionID,
								ActionTypeID,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
						FROM	@tmpCust tmp
								CROSS APPLY (	SELECT TOP (@i) * 
												FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK) 
												WHERE ul.custid = tmp.Custid 
													AND LogDate BETWEEN @FromDate AND @ToDate) ul
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE	la.ActionID BETWEEN @LowerActionIdStatus AND @UpperActionIdStatus
								AND la.ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								--dont show these actions on alpha
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						OPTION (OPTIMIZE FOR (@i = 1))

					END
					ELSE
					BEGIN
						--old log status has actionid from 1100 and 1199
						INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
							, SPName, IsInternal, CustID, CustName, ActionName)
						 SELECT LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												when (la.ActionID BETWEEN 1142 AND 1144 OR la.ActionID=1165) then 'Admin'
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
						 FROM	@tmpCust tmp
								CROSS APPLY (	SELECT TOP (@i) * 
												FROM dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK) 
												WHERE ul.custid = tmp.Custid 
													AND LogDate BETWEEN @__archiveDate AND @ToDate) ul
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE	la.ActionTypeID = @ActionTypeId
								AND (la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						OPTION (OPTIMIZE FOR (@i = 1))

						--old log status has actionid from 1100 and 1199
						INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
							, SPName, IsInternal, CustID, CustName, ActionName)
						 SELECT LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												when (la.ActionID BETWEEN 1142 AND 1144 OR la.ActionID=1165) then 'Admin'
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
						 FROM	@tmpCust tmp
								CROSS APPLY (	SELECT TOP (@i) * 
												FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK) 
												WHERE ul.custid = tmp.Custid 
													AND LogDate >= @FromDate AND logdate < @__archiveDate) ul
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE	la.ActionTypeID = @ActionTypeId
								AND (la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						OPTION (OPTIMIZE FOR (@i = 1))
					
						INSERT INTO @tmpCust(CustID)
						SELECT @srecommend WHERE @roleid<4
						UNION SELECT @mrecommend WHERE @roleid<3
						UNION SELECT @recommend WHERE @roleid<2

						INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
							, SPName, IsInternal, CustID, CustName, ActionName)
						SELECT  LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												ELSE c.Username
											END,
								ul.TrackingValue,
								TrackingValue2,
								LogDate,
								la.ActionID,
								ActionTypeID,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
						FROM	@tmpCust tmp
								CROSS APPLY (	SELECT TOP (@i) * 
												FROM dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK) 
												WHERE ul.custid = tmp.Custid 
													AND LogDate BETWEEN @__archiveDate AND @ToDate) ul
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE	la.ActionID BETWEEN @LowerActionIdStatus AND @UpperActionIdStatus
								AND la.ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								--dont show these actions on alpha
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						OPTION (OPTIMIZE FOR (@i = 1))
					
						INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
							, SPName, IsInternal, CustID, CustName, ActionName)
						SELECT  LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												ELSE c.Username
											END,
								ul.TrackingValue,
								TrackingValue2,
								LogDate,
								la.ActionID,
								ActionTypeID,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
						FROM	@tmpCust tmp
								CROSS APPLY (	SELECT TOP (@i) * 
												FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK) 
												WHERE ul.custid = tmp.Custid 
													AND LogDate > @FromDate AND LogDate < @__archiveDate) ul
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE	la.ActionID BETWEEN @LowerActionIdStatus AND @UpperActionIdStatus
								AND la.ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								--dont show these actions on alpha
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						OPTION (OPTIMIZE FOR (@i = 1))
					END
						
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

					IF @FromDate >= @__archiveDate
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
										ul.TrackingValue,
										TrackingValue2,
										LogDate,
										la.ActionID,
										ActionTypeID,
										la.SPName,
										IsInternal,
										ul.CustID,
										@CustName AS CustName,
										la.ActionNameEN AS ActionName
							  FROM      dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
										INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
										LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
							  WHERE     ul.CustID = @CustId
										AND LogDate BETWEEN @FromDate AND @ToDate
										AND  la.ActionTypeID = @ActionTypeId
										AND IsInternal <= @IsInternal
										AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
										AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)	
										AND ul.ActionID NOT BETWEEN 31000 AND 31100					
										AND ul.ActionId <> 1050 --Message Customer Read Status Update
							) AS MyTable
						WHERE   RowNum BETWEEN @lbound AND @ubound
					END
					ELSE IF @ToDate < @__archiveDate
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
										ul.TrackingValue,
										TrackingValue2,
										LogDate,
										la.ActionID,
										ActionTypeID,
										la.SPName,
										IsInternal,
										ul.CustID,
										@CustName AS CustName,
										la.ActionNameEN AS ActionName
							  FROM      bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
										INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
										LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
							  WHERE     ul.CustID = @CustId
										AND LogDate BETWEEN @FromDate AND @ToDate
										AND  la.ActionTypeID = @ActionTypeId
										AND IsInternal <= @IsInternal
										AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
										AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)	
										AND ul.ActionID NOT BETWEEN 31000 AND 31100					
										AND ul.ActionId <> 1050 --Message Customer Read Status Update
							) AS MyTable
						WHERE   RowNum BETWEEN @lbound AND @ubound
					END
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
							 SELECT    ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum, *
							 FROM (
								SELECT LogID,
										UserID,
										Username =	CASE 
														when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
														when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
														ELSE c.Username
													END,
										ul.TrackingValue,
										TrackingValue2,
										LogDate,
										la.ActionID,
										ActionTypeID,
										la.SPName,
										IsInternal,
										ul.CustID,
										@CustName AS CustName,
										la.ActionNameEN AS ActionName
							  FROM      dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
										INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
										LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
							  WHERE     ul.CustID = @CustId
										AND LogDate BETWEEN @__archiveDate AND @ToDate
										AND  la.ActionTypeID = @ActionTypeId
										AND IsInternal <= @IsInternal
										AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
										AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)	
										AND ul.ActionID NOT BETWEEN 31000 AND 31100					
										AND ul.ActionId <> 1050 --Message Customer Read Status Update

								UNION ALL
								SELECT LogID,
										UserID,
										Username =	CASE 
														when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
														when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
														ELSE c.Username
													END,
										ul.TrackingValue,
										TrackingValue2,
										LogDate,
										la.ActionID,
										ActionTypeID,
										la.SPName,
										IsInternal,
										ul.CustID,
										@CustName AS CustName,
										la.ActionNameEN AS ActionName
							  FROM      bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
										INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
										LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
							  WHERE     ul.CustID = @CustId
										AND LogDate >= @FromDate AND LogDate < @__archiveDate
										AND  la.ActionTypeID = @ActionTypeId
										AND IsInternal <= @IsInternal
										AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
										AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)	
										AND ul.ActionID NOT BETWEEN 31000 AND 31100					
										AND ul.ActionId <> 1050 --Message Customer Read Status Update
							 ) AS MyTable1
						) AS MyTable
						WHERE   RowNum BETWEEN @lbound AND @ubound
					END
				END	
			END--end (@ActionTypeId > 0)	
			ELSE 
			BEGIN
				IF @FromDate >= @__archiveDate
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
													when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
													ELSE c.Username
												END,
									ul.TrackingValue,
									LogDate,
									la.ActionID,
									ActionTypeID,
									TrackingValue2,
									la.SPName,
									IsInternal,
									ul.CustID,
									@CustName AS CustName,
									la.ActionNameEN AS ActionName
						 FROM      dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
									LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						  WHERE     ul.CustID = @CustId
									AND LogDate BETWEEN @FromDate AND @ToDate				
									AND IsInternal <= @IsInternal
									AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
									AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
									--exclude log action of status
									AND la.ActionID NOT BETWEEN 1100 AND 1199
									AND la.ActionID NOT BETWEEN 165000 AND 169999
									AND la.ActionID NOT BETWEEN 60000 AND 79999
									--exclude log action of smart punter
									AND ul.ActionID NOT BETWEEN 31000 AND 31100
									AND ul.ActionId <> 1050 --Message Customer Read Status Update

						) AS MyTable
					WHERE   RowNum BETWEEN @lbound AND @ubound
				END
				ELSE IF @ToDate < @__archiveDate
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
													when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
													ELSE c.Username
												END,
									ul.TrackingValue,
									LogDate,
									la.ActionID,
									ActionTypeID,
									TrackingValue2,
									la.SPName,
									IsInternal,
									ul.CustID,
									@CustName AS CustName,
									la.ActionNameEN AS ActionName
						 FROM      bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
									LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						  WHERE     ul.CustID = @CustId
									AND LogDate BETWEEN @FromDate AND @ToDate				
									AND IsInternal <= @IsInternal
									AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
									AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
									--exclude log action of status
									AND la.ActionID NOT BETWEEN 1100 AND 1199
									AND la.ActionID NOT BETWEEN 165000 AND 169999
									AND la.ActionID NOT BETWEEN 60000 AND 79999
									--exclude log action of smart punter
									AND ul.ActionID NOT BETWEEN 31000 AND 31100
									AND ul.ActionId <> 1050 --Message Customer Read Status Update

						) AS MyTable
					WHERE   RowNum BETWEEN @lbound AND @ubound
				END
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
						 SELECT    ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum, *
						 FROM (
							SELECT LogID,
									UserID,
									Username =	CASE 
													when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
													when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
													ELSE c.Username
												END,
									ul.TrackingValue,
									LogDate,
									la.ActionID,
									ActionTypeID,
									TrackingValue2,
									la.SPName,
									IsInternal,
									ul.CustID,
									@CustName AS CustName,
									la.ActionNameEN AS ActionName
						 FROM      dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
									LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						 WHERE     ul.CustID = @CustId
									AND LogDate BETWEEN @__archiveDate AND @ToDate				
									AND IsInternal <= @IsInternal
									AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
									AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
									--exclude log action of status
									AND la.ActionID NOT BETWEEN 1100 AND 1199
									AND la.ActionID NOT BETWEEN 165000 AND 169999
									AND la.ActionID NOT BETWEEN 60000 AND 79999
									--exclude log action of smart punter
									AND ul.ActionID NOT BETWEEN 31000 AND 31100
									AND ul.ActionId <> 1050 --Message Customer Read Status Update

						 UNION ALL
						 SELECT LogID,
									UserID,
									Username =	CASE 
													when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
													when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
													ELSE c.Username
												END,
									ul.TrackingValue,
									LogDate,
									la.ActionID,
									ActionTypeID,
									TrackingValue2,
									la.SPName,
									IsInternal,
									ul.CustID,
									@CustName AS CustName,
									la.ActionNameEN AS ActionName
						 FROM      bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
									LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						 WHERE     ul.CustID = @CustId
									AND LogDate >= @FromDate AND LogDate < @__archiveDate				
									AND IsInternal <= @IsInternal
									AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
									AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
									--exclude log action of status
									AND la.ActionID NOT BETWEEN 1100 AND 1199
									AND la.ActionID NOT BETWEEN 165000 AND 169999
									AND la.ActionID NOT BETWEEN 60000 AND 79999
									--exclude log action of smart punter
									AND ul.ActionID NOT BETWEEN 31000 AND 31100
									AND ul.ActionId <> 1050 --Message Customer Read Status Update
						 	
						 ) AS MyTable1
					) AS MyTable
					WHERE   RowNum BETWEEN @lbound AND @ubound
				END
			END	
		END --end (@LowerActionId IS NULL OR @UpperActionId IS NULL) 
		ELSE
		BEGIN
			IF @FromDate >= @__archiveDate
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
						 FROM      dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
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
			ELSE IF @ToDate < @__archiveDate
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
						 FROM      bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
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
					SELECT ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum, *
					FROM (
						SELECT LogID,
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
							 FROM      dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
										INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
										LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID					
							  WHERE     ul.CustID = @CustId
										AND LogDate BETWEEN @__archiveDate AND @ToDate
										AND la.actionid BETWEEN @LowerActionId AND @UpperActionId
										AND IsInternal <= @IsInternal
										AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
										AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)

							UNION ALL
							SELECT LogID,
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
							 FROM      bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
										INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
										LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID					
							  WHERE     ul.CustID = @CustId
										AND LogDate >= @FromDate AND LogDate < @__archiveDate
										AND la.actionid BETWEEN @LowerActionId AND @UpperActionId
										AND IsInternal <= @IsInternal
										AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
										AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
					) AS MyTable1
				) AS MyTable
				WHERE   RowNum BETWEEN @lbound AND @ubound
			END
		END
	END
END
GO
