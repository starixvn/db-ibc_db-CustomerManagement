/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UserLog_RunSPSelTotalRecords]     
	@CustId INT, 
    @FromDate DATETIME,
    @ToDate DATETIME,
    @ActionTypeId INT =-1,
    @IsInternal TINYINT,
	@LowerActionId INT = NULL,
	@UpperActionId INT = NULL  
AS 
/* Created:20100121@Lewin
    Task: ViewLog function 331
    DB: DBLOG/bodb_CustomerLog

	Description:
	- count total record with input conditions
	
    Param's Explaination:    
	- @CustID: a customer which we want to view actions affect to.
	- @FromDate: date range to view log
	- @ToDate: date range to view log	
	- @IsAdminAccess: Accouting site TRUE, agent = FALSE
	- @IsSubCust: view logaction affect to sub account or not

	 Revisions:
		- 20140708@Dom: Do not show any log info (including log of Supers, Masters, Agents and Members) updated by Admin relate to all log categories [Redmine: #18125]
		- 20160115@Dominic: Do not show logactionid=237 if Trackingvalues is null Redmine: #50937
		- 20171205@Winnie: Provide API for FPS to update dangerous level for evidence member #86627
		- 20180123@Johnson: support view log for status by level for new direction[Redmine: #87328]
		- 20180621@Razor: Exclude log of Message Customer Read Status [Redmind: #94705]
		- 20180911@Eloide: Use Index hint IX_UserLog_RunSP
		- 20180903@Elodie: Revise SP for @ActionTypeID = 5 (status)
		- 20180227@Elodie: Add new range actionID for status of CN88 [Redmind: #105338]
		- 20190405@Patrick: Support archive date range [Redmine: #111476]
*/
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

	SET NOCOUNT ON ;
	DECLARE @srecommend INT
			,@mrecommend INT
			,@recommend INT
			,@roleid TINYINT
			,@creatdate DATETIME 
			,@LowerActionIdStatus INT
			,@UpperActionIdStatus INT
			,@i INT = 1000000

	SELECT @srecommend = srecommend, 
		@mrecommend = mrecommend, 
		@recommend = recommend, 
		@roleid = roleid,
		@creatdate = creatdate
	FROM bodb02.dbo.Customer WITH(NOLOCK)
	WHERE custid = @CustID
	
	IF @FromDate < @creatdate
		SELECT @FromDate = DATEADD(SECOND,-30,@creatdate)--@Johnson: backward 30s to get log [#97633]
	
	DECLARE @tmpCust TABLE(Custid INT)
	CREATE TABLE #tmpLog (LogID BIGINT)
	
	DECLARE @__archiveDate DATETIME
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())
	DECLARE @__cnt INT, @__cntTemp INT
	SELECT @__cnt = 0, @__cntTemp = 0

	IF  (@LowerActionId IS NULL OR @UpperActionId IS NULL)  
	BEGIN
		select @LowerActionId=1100, @UpperActionId=1199	 --exclude to select Customer Status
		IF (@ActionTypeId > 0)
		BEGIN
			IF @ActionTypeID = 5--status
			BEGIN
				INSERT INTO @tmpCust(CustID)
				SELECT @CustID 

				IF @FromDate >= @__archiveDate
				BEGIN
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM @tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate BETWEEN @FromDate AND @ToDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE		la.ActionTypeID = @ActionTypeId
							AND (la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))
					
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
					--new range logactionid for status by level
					SELECT @LowerActionIdStatus = CASE @roleid WHEN 4 THEN 60000
														WHEN 3 THEN 65000
														WHEN 2 THEN 70000
														WHEN 1 THEN 75000 END,
							@UpperActionIdStatus = CASE @roleid WHEN 4 THEN 64999
														WHEN 3 THEN 69999
														WHEN 2 THEN 74999
														WHEN 1 THEN 79999 END									
				
					INSERT INTO @tmpCust(CustID)
					SELECT @srecommend WHERE @roleid<4
					UNION SELECT @mrecommend WHERE @roleid<3
					UNION SELECT @recommend WHERE @roleid<2
				
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
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

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
				END
				ELSE IF @ToDate < @__archiveDate
				BEGIN
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM @tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate BETWEEN @FromDate AND @ToDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE		la.ActionTypeID = @ActionTypeId
							AND (la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))
					
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
					--new range logactionid for status by level
					SELECT @LowerActionIdStatus = CASE @roleid WHEN 4 THEN 60000
														WHEN 3 THEN 65000
														WHEN 2 THEN 70000
														WHEN 1 THEN 75000 END,
							@UpperActionIdStatus = CASE @roleid WHEN 4 THEN 64999
														WHEN 3 THEN 69999
														WHEN 2 THEN 74999
														WHEN 1 THEN 79999 END									
				
					INSERT INTO @tmpCust(CustID)
					SELECT @srecommend WHERE @roleid<4
					UNION SELECT @mrecommend WHERE @roleid<3
					UNION SELECT @recommend WHERE @roleid<2
				
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
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

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
				END
				ELSE
				BEGIN
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM @tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate BETWEEN @__archiveDate AND @ToDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE		la.ActionTypeID = @ActionTypeId
							AND (la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))
					
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM @tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate >= @FromDate AND LogDate < @__archiveDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE		la.ActionTypeID = @ActionTypeId
							AND (la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))
					
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					--new range logactionid for status by level
					SELECT @LowerActionIdStatus = CASE @roleid WHEN 4 THEN 60000
														WHEN 3 THEN 65000
														WHEN 2 THEN 70000
														WHEN 1 THEN 75000 END,
							@UpperActionIdStatus = CASE @roleid WHEN 4 THEN 64999
														WHEN 3 THEN 69999
														WHEN 2 THEN 74999
														WHEN 1 THEN 79999 END									
				
					INSERT INTO @tmpCust(CustID)
					SELECT @srecommend WHERE @roleid<4
					UNION SELECT @mrecommend WHERE @roleid<3
					UNION SELECT @recommend WHERE @roleid<2
				
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
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

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate >= @FromDate AND LogDate < @__archiveDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE	la.ActionID BETWEEN @LowerActionIdStatus AND @UpperActionIdStatus
							AND la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							--dont show these actions on alpha
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
				END

				SELECT @__cnt AS cnt
							
			END--@ActionTypeID = 5
			ELSE
			BEGIN
				IF @FromDate >= @__archiveDate
				BEGIN
					SELECT  COUNT(LogID)
					FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE   ul.CustID = @CustId
							AND LogDate BETWEEN @FromDate AND @ToDate
							AND ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
							AND ul.ActionId <> 1050 --Message Customer Read Status Update
				END
				ELSE IF @ToDate < @__archiveDate
				BEGIN
					SELECT  COUNT(LogID)
					FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE   ul.CustID = @CustId
							AND LogDate BETWEEN @FromDate AND @ToDate
							AND ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
							AND ul.ActionId <> 1050 --Message Customer Read Status Update
				END
				ELSE
				BEGIN
					SELECT SUM(cnt)
					FROM (
						SELECT  COUNT(LogID) AS cnt
						FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE   ul.CustID = @CustId
								AND LogDate BETWEEN @__archiveDate AND @ToDate
								AND ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
								AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
								AND ul.ActionId <> 1050 --Message Customer Read Status Update

						UNION ALL
						SELECT  COUNT(LogID)
						FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE   ul.CustID = @CustId
								AND LogDate >= @FromDate AND LogDate < @__archiveDate
								AND ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
								AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
								AND ul.ActionId <> 1050 --Message Customer Read Status Update
					)t
				END
			END			
		END--@ActionTypeId > 0			
		ELSE
			IF @FromDate >= @__archiveDate
			BEGIN
				SELECT  COUNT(LogID)                           
				FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate BETWEEN @FromDate AND @ToDate								
						AND IsInternal <= @IsInternal
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 1100 AND 1199
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						AND la.ActionID NOT BETWEEN 60000 AND 79999					
						AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
			END
			ELSE IF @ToDate < @__archiveDate
			BEGIN
				SELECT  COUNT(LogID)                           
				FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate BETWEEN @FromDate AND @ToDate								
						AND IsInternal <= @IsInternal
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 1100 AND 1199
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						AND la.ActionID NOT BETWEEN 60000 AND 79999					
						AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
			END
			ELSE
			BEGIN
				SELECT SUM(cnt)
				FROM (
					SELECT  COUNT(LogID) AS cnt                       
					FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE   ul.CustID = @CustId
							AND LogDate BETWEEN @__archiveDate AND @ToDate								
							AND IsInternal <= @IsInternal
							--exclude log action of status
							AND la.ActionID NOT BETWEEN 1100 AND 1199
							AND la.ActionID NOT BETWEEN 165000 AND 169999
							AND la.ActionID NOT BETWEEN 60000 AND 79999					
							AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
							AND ul.ActionId <> 1050 --Message Customer Read Status Update

					UNION ALL
					SELECT  COUNT(LogID)                           
					FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE   ul.CustID = @CustId
							AND LogDate >= @FromDate AND LogDate < @__archiveDate								
							AND IsInternal <= @IsInternal
							--exclude log action of status
							AND la.ActionID NOT BETWEEN 1100 AND 1199
							AND la.ActionID NOT BETWEEN 165000 AND 169999
							AND la.ActionID NOT BETWEEN 60000 AND 79999					
							AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
							AND ul.ActionId <> 1050 --Message Customer Read Status Update
				)t
			END
			
	END--(@LowerActionId IS NULL OR @UpperActionId IS NULL)  
	ELSE
	BEGIN
		IF @FromDate >= @__archiveDate
		BEGIN
			SELECT  COUNT(LogID)                           
			FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
			WHERE   ul.CustID = @CustId
					AND LogDate BETWEEN @FromDate AND @ToDate
					AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
					AND IsInternal <= @IsInternal
					AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
		END
		ELSE IF @ToDate < @__archiveDate
		BEGIN
			SELECT  COUNT(LogID)                           
			FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
			WHERE   ul.CustID = @CustId
					AND LogDate BETWEEN @FromDate AND @ToDate
					AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
					AND IsInternal <= @IsInternal
					AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
		END
		ELSE
		BEGIN
			SELECT SUM(cnt)
			FROM (
				SELECT  COUNT(LogID) AS cnt
				FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate BETWEEN @__archiveDate AND @ToDate
						AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)

				UNION ALL
				SELECT  COUNT(LogID) 
				FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate >= @FromDate AND LogDate < @__archiveDate
						AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
			)t
		END
	END
END

GO
