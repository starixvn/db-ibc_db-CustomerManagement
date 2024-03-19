/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,wsv_nap,bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[CS_UserLog_RunSPSelTotalRecords]     
	@CustId INT, 
	@LoginUserId INT = 0,
    @FromDate DATETIME,
    @ToDate DATETIME,
    @ActionTypeId INT =-1,
    @IsInternal TINYINT,
	@LowerActionId INT = NULL,
	@UpperActionId INT = NULL  
AS 
/* Created:20190606@Elodie
    Task: count total record with input conditions
    DB: DBLOG\bodb_CustomerLog
    
	Revisions:
		- 20190606@Elodie: Initial SP [Redmine: #113198]
		- 20190808@Elodie: Don't show log of problem account when master, agent view log [Redmine:#116814]

    Param's Explaination:    
		- @CustID: a customer which we want to view actions affect to.
		- @FromDate: date range to view log
		- @ToDate: date range to view log	
		- @IsAdminAccess: Accouting site TRUE, agent = FALSE
		- @IsSubCust: view logaction affect to sub account or not
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
			,@LoginUserRoleId TINYINT

	SELECT @srecommend = srecommend, 
		@mrecommend = mrecommend, 
		@recommend = recommend, 
		@roleid = roleid,
		@creatdate = creatdate
	FROM bodb02.dbo.Customer WITH(NOLOCK)
	WHERE custid = @CustID
	
	SELECT	@LoginUserRoleId = roleid
	FROM bodb02.dbo.Customer WITH(NOLOCK)
	WHERE custid = @LoginUserId

	SELECT	@LoginUserRoleId = ISNULL(@LoginUserRoleId,0)

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
		SELECT @LowerActionId=1100, @UpperActionId=1199	 --exclude to select Customer Status
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
											FROM dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK) 
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

					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) mt.*, lt.CustID
											FROM dbo.CS_UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
												INNER JOIN dbo.CS_UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID
											WHERE lt.custid = tmp.Custid 
												AND mt.LogDate BETWEEN @FromDate AND @ToDate
												) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = ul.UserID
					WHERE	la.ActionTypeID = @ActionTypeId
							AND la.ActionID BETWEEN 165000 AND 169999
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

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
					
				END
				ELSE IF @ToDate < @__archiveDate
				BEGIN
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM @tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK) 
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

					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) mt.*, lt.CustID
											FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
												INNER JOIN bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID
											WHERE lt.custid = tmp.Custid 
												AND mt.LogDate BETWEEN @FromDate AND @ToDate
												) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = ul.UserID
					WHERE	la.ActionTypeID = @ActionTypeId
							AND la.ActionID BETWEEN 165000 AND 169999
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

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
					
				END
				ELSE
				BEGIN
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM @tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK) 
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
											FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK) 
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

					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) mt.*, lt.CustID
											FROM dbo.CS_UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
												INNER JOIN dbo.CS_UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID
											WHERE lt.custid = tmp.Custid 
												AND mt.LogDate BETWEEN @__archiveDate AND @ToDate
												) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = ul.UserID
					WHERE	la.ActionTypeID = @ActionTypeId
							AND la.ActionID = 165004
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))
						
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) mt.*, lt.CustID
											FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
												INNER JOIN bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID
											WHERE lt.custid = tmp.Custid 
												AND mt.LogDate >= @FromDate AND mt.LogDate < @__archiveDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = ul.UserID
					WHERE	la.ActionTypeID = @ActionTypeId
							AND la.ActionID BETWEEN 165000 AND 169999
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

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK) 
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
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM    dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE   ul.CustID = @CustId
							AND LogDate BETWEEN @FromDate AND @ToDate
							AND ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
							AND ul.ActionID NOT BETWEEN 31000 AND 31100					
							AND ul.ActionId <> 1050 --Message Customer Read Status Update
					
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT @__cntTemp = COUNT(mt.LogID)
					FROM dbo.CS_UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
							INNER JOIN dbo.CS_UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
						WHERE	lt.custid = @CustId
								AND mt.LogDate BETWEEN @FromDate AND @ToDate
								AND  la.ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END	

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

				END
				ELSE IF @ToDate < @__archiveDate
				BEGIN
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM    bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE   ul.CustID = @CustId
							AND LogDate BETWEEN @FromDate AND @ToDate
							AND ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
							AND ul.ActionID NOT BETWEEN 31000 AND 31100					
							AND ul.ActionId <> 1050 --Message Customer Read Status Update

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT @__cntTemp = COUNT(mt.LogID)
					FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
							INNER JOIN bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
						WHERE	lt.custid = @CustId
								AND mt.LogDate BETWEEN @FromDate AND @ToDate
								AND  la.ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END	

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
				END
				ELSE
				BEGIN
					SELECT  @__cntTemp = COUNT(LogID) 
					FROM    dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE   ul.CustID = @CustId
							AND LogDate BETWEEN @__archiveDate AND @ToDate
							AND ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
							AND ul.ActionID NOT BETWEEN 31000 AND 31100					
							AND ul.ActionId <> 1050 --Message Customer Read Status Update
					
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT  @__cntTemp = COUNT(LogID) 
					FROM    bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE   ul.CustID = @CustId
							AND LogDate >= @FromDate AND LogDate < @__archiveDate
							AND ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
							AND ul.ActionID NOT BETWEEN 31000 AND 31100					
							AND ul.ActionId <> 1050 --Message Customer Read Status Update
					
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT  @__cntTemp = COUNT(mt.LogID)
					FROM dbo.CS_UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
						INNER JOIN dbo.CS_UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
					WHERE	lt.custid = @CustId
							AND mt.LogDate BETWEEN @__archiveDate AND @ToDate
							AND  la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END	

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT  @__cntTemp = COUNT(mt.LogID)
					FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
							INNER JOIN bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
						WHERE	lt.custid = @CustId
								AND mt.LogDate >= @FromDate AND mt.LogDate < @__archiveDate
								AND  la.ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END	

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
				END

				SELECT @__cnt AS cnt
			END			
		END--@ActionTypeId > 0			
		ELSE
		BEGIN
			IF @FromDate >= @__archiveDate
			BEGIN
				SELECT  @__cntTemp = COUNT(LogID)                           
				FROM    dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate BETWEEN @FromDate AND @ToDate								
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 1100 AND 1199
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						AND la.ActionID NOT BETWEEN 60000 AND 79999					
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						--exclude log action of smart punter
						AND ul.ActionID NOT BETWEEN 31000 AND 31100
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
						AND (ul.ActionId NOT BETWEEN 31608 AND 31610 
							OR ( ul.ActionId BETWEEN 31608 AND 31610 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))

				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0

				SELECT  @__cntTemp = COUNT(mt.LogID)  
				FROM dbo.CS_UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
					INNER JOIN dbo.CS_UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
				WHERE	lt.custid = @CustId
						AND mt.LogDate BETWEEN @FromDate AND @ToDate
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 165000 AND 169999

				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0
			END
			ELSE IF @ToDate < @__archiveDate
			BEGIN
				SELECT  @__cntTemp = COUNT(LogID)                           
				FROM    bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate BETWEEN @FromDate AND @ToDate								
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 1100 AND 1199
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						AND la.ActionID NOT BETWEEN 60000 AND 79999					
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						--exclude log action of smart punter
						AND ul.ActionID NOT BETWEEN 31000 AND 31100
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
						AND (ul.ActionId NOT BETWEEN 31608 AND 31610 
							OR ( ul.ActionId BETWEEN 31608 AND 31610 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))

				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0

				SELECT  @__cntTemp = COUNT(mt.LogID)  
				FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
					INNER JOIN bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
				WHERE	lt.custid = @CustId
						AND mt.LogDate BETWEEN @FromDate AND @ToDate
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 165000 AND 169999

				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0
			END
			ELSE
			BEGIN
				SELECT  @__cntTemp = COUNT(LogID)                           
				FROM    dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate BETWEEN @__archiveDate AND @ToDate								
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 1100 AND 1199
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						AND la.ActionID NOT BETWEEN 60000 AND 79999					
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						--exclude log action of smart punter
						AND ul.ActionID NOT BETWEEN 31000 AND 31100
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
						AND (ul.ActionId NOT BETWEEN 31608 AND 31610 
							OR ( ul.ActionId BETWEEN 31608 AND 31610 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))
				
				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0

				SELECT  @__cntTemp = COUNT(LogID)                           
				FROM    bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate >= @FromDate AND LogDate < @__archiveDate								
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 1100 AND 1199
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						AND la.ActionID NOT BETWEEN 60000 AND 79999					
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						--exclude log action of smart punter
						AND ul.ActionID NOT BETWEEN 31000 AND 31100
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
						AND (ul.ActionId NOT BETWEEN 31608 AND 31610 
							OR ( ul.ActionId BETWEEN 31608 AND 31610 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))	

				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0

				SELECT  @__cntTemp = COUNT(mt.LogID)  
				FROM dbo.CS_UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
					INNER JOIN dbo.CS_UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
				WHERE	lt.custid = @CustId
						AND mt.LogDate BETWEEN @__archiveDate AND @ToDate
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 165000 AND 169999

				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0

				SELECT  @__cntTemp = COUNT(mt.LogID)  
				FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
					INNER JOIN bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
				WHERE	lt.custid = @CustId
						AND mt.LogDate >= @FromDate AND mt.LogDate < @__archiveDate								
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 165000 AND 169999

				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0
			END

			SELECT @__cnt AS cnt
		END
	END--(@LowerActionId IS NULL OR @UpperActionId IS NULL)  
	ELSE
	BEGIN
		IF @FromDate >= @__archiveDate
		BEGIN
			SELECT  COUNT(LogID)                           
			FROM    dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
			WHERE   ul.CustID = @CustId
					AND LogDate BETWEEN @FromDate AND @ToDate
					AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
					AND IsInternal <= @IsInternal
					AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
					AND (ul.ActionId NOT BETWEEN 31608 AND 31610 
						OR ( ul.ActionId BETWEEN 31608 AND 31610 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))	
		END
		ELSE IF @ToDate < @__archiveDate
		BEGIN
			SELECT  COUNT(LogID)                           
			FROM    bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
			WHERE   ul.CustID = @CustId
					AND LogDate BETWEEN @FromDate AND @ToDate
					AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
					AND IsInternal <= @IsInternal
					AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
					AND (ul.ActionId NOT BETWEEN 31608 AND 31610 
						OR ( ul.ActionId BETWEEN 31608 AND 31610 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))	
		END
		ELSE
		BEGIN
			SELECT SUM(cnt)
			FROM (
				SELECT  COUNT(LogID) AS cnt
				FROM    dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate BETWEEN @__archiveDate AND @ToDate
						AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						AND (ul.ActionId NOT BETWEEN 31608 AND 31610 
							OR ( ul.ActionId BETWEEN 31608 AND 31610 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))	
				UNION ALL
				SELECT  COUNT(LogID) 
				FROM    bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate >= @FromDate AND LogDate < @__archiveDate
						AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						AND (ul.ActionId NOT BETWEEN 31608 AND 31610 
							OR ( ul.ActionId BETWEEN 31608 AND 31610 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))	
			)t
		END
	END
END

GO
