/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="wsv_nap,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CS_UserLog_CreditSel]    
    @CustID INT ,
	@CustName varchar(50) = '',
    @FromDate DATETIME ,
    @ToDate DATETIME ,    
    @IsInternal TINYINT ,
    @PageIndex INT ,
    @PageSize INT
AS 
/* Created:20190606@Elodie
    Task: Get paged log credit
    DB: DBLOG\bodb_CustomerLog
    
	Revisions:
		- 20190606@Elodie: Initial SP [Redmine: #113198]
		
    Param's Explaination:    
		- @CustID: a customer which we want to view actions affect to.
		- @FromDate: date range to view log
		- @ToDate: date range to view log
		- @ActionTypeId: action type
		- @IsInternal: Accounting: 1 Agent:0
		- @PageIndex: from 0
		- @PageSize: total record per request
*/
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON ;

	SET @PageIndex = ABS(@PageIndex)
	SET @PageSize = ABS(@PageSize)  

	DECLARE @lbound INT 
	DECLARE @ubound INT

	SET @lbound = @PageIndex * @PageSize       
	
	SET @ubound = @lbound + @PageSize 
	IF ( @PageIndex > 0 ) 
		SET @lbound = @lbound + 1

	DECLARE @ActionName AS NVARCHAR(256)
	DECLARE @__archiveDate DATETIME
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())
		
	IF ( @IsInternal = 0 AND NOT EXISTS (SELECT TOP 1 1 FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE username2 = @CustName)) OR @IsInternal = 1
	BEGIN
		IF @IsInternal = 1
		BEGIN
			IF @FromDate >= @__archiveDate
			BEGIN
				SELECT	LogID,
						UserID,
						CustID,
						LogDate,
						OldValue,
						NewValue,
						IP,
						Doing,
						ActionID,
						IsInternal,
						ActionTypeID,
						SPName,
						UserName,
						CustName,                                                             
						ActionName
					
				FROM (
					SELECT ROW_NUMBER() OVER (ORDER BY LogDate DESC) AS RowNum,
							LogID,
							UserID,
							uc.CustID,
							LogDate,
							OldValue,
							NewValue,
							IP,
							Doing,
							la.ActionID,
							IsInternal,
							la.ActionTypeID,
							la.SPName,
							Username =	CASE 
												when (ci.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												ELSE ci.Username
											END,
							@CustName as CustName,                                         
							la.ActionNameEN As ActionName
					FROM    dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
							INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
					WHERE     uc.CustID = @CustID
							AND LogDate BETWEEN @FromDate AND @ToDate                            
							AND IsInternal <= @IsInternal
				) AS MyTable
				WHERE   RowNum BETWEEN @lbound AND @ubound
			END
			ELSE IF @ToDate < @__archiveDate
			BEGIN
				SELECT	LogID,
						UserID,
						CustID,
						LogDate,
						OldValue,
						NewValue,
						IP,
						Doing,
						ActionID,
						IsInternal,
						ActionTypeID,
						SPName,
						UserName,
						CustName,                                                             
						ActionName
					
				FROM (
					SELECT ROW_NUMBER() OVER (ORDER BY LogDate DESC) AS RowNum,
							LogID,
							UserID,
							uc.CustID,
							LogDate,
							OldValue,
							NewValue,
							IP,
							Doing,
							la.ActionID,
							IsInternal,
							la.ActionTypeID,
							la.SPName,
							Username =	CASE 
												when (ci.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												ELSE ci.Username
											END,
							@CustName as CustName,                                         
							la.ActionNameEN As ActionName
					FROM   bodb_CustomerLog_Archive.dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
						INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
					WHERE uc.CustID = @CustID
						AND LogDate BETWEEN @FromDate AND @ToDate                            
						AND IsInternal <= @IsInternal
				) AS MyTable
				WHERE   RowNum BETWEEN @lbound AND @ubound
			END
			ELSE
			BEGIN
				SELECT	LogID,
						UserID,
						CustID,
						LogDate,
						OldValue,
						NewValue,
						IP,
						Doing,
						ActionID,
						IsInternal,
						ActionTypeID,
						SPName,
						UserName,
						CustName,                                                             
						ActionName
				FROM (
					SELECT ROW_NUMBER() OVER (ORDER BY LogDate DESC) AS RowNum, *
					FROM (
						SELECT LogID,
								UserID,
								uc.CustID,
								LogDate,
								OldValue,
								NewValue,
								IP,
								Doing,
								la.ActionID,
								IsInternal,
								la.ActionTypeID,
								la.SPName,
								Username =	CASE 
													when (ci.RoleId > 4 and @IsInternal=0) THEN 'Admin'
													ELSE ci.Username
												END,
								@CustName as CustName,                                         
								la.ActionNameEN As ActionName
						FROM dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
							INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
						WHERE uc.CustID = @CustID
							AND LogDate BETWEEN @__archiveDate AND @ToDate                            
							AND IsInternal <= @IsInternal

						UNION ALL
						SELECT LogID,
								UserID,
								uc.CustID,
								LogDate,
								OldValue,
								NewValue,
								IP,
								Doing,
								la.ActionID,
								IsInternal,
								la.ActionTypeID,
								la.SPName,
								Username =	CASE 
													when (ci.RoleId > 4 and @IsInternal=0) THEN 'Admin'
													ELSE ci.Username
												END,
								@CustName as CustName,                                         
								la.ActionNameEN As ActionName
						FROM   bodb_CustomerLog_Archive.dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
							INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
						WHERE uc.CustID = @CustID
							AND LogDate >= @FromDate AND LogDate < @__archiveDate                            
							AND IsInternal <= @IsInternal

					) AS MyTable1
				) AS MyTable
				WHERE RowNum BETWEEN @lbound AND @ubound
			END
		END
		ELSE -- @IsInternal = 0
		BEGIN

			IF @FromDate >= @__archiveDate
			BEGIN
				SELECT	LogID,
					UserID,
					CustID,
					LogDate,
					OldValue,
					NewValue,
					IP,
					Doing,
					ActionID,
					IsInternal,
					ActionTypeID,
					SPName,
					UserName,
					CustName,                                                             
					ActionName
				FROM    ( SELECT    ROW_NUMBER() OVER (ORDER BY LogDate DESC) AS RowNum,
									LogID,
									UserID,
									uc.CustID,
									LogDate,
									OldValue,
									NewValue,
									IP,
									Doing,
									la.ActionID,
									IsInternal,
									la.ActionTypeID,
									la.SPName,
									Username =	CASE 
														when (ci.RoleId > 4 and @IsInternal=0) THEN 'Admin'
														ELSE ci.Username
													END,
									@CustName as CustName,                                         
									la.ActionNameEN As ActionName
							FROM      dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
									INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
							WHERE     uc.CustID = @CustID
									AND LogDate BETWEEN @FromDate AND @ToDate                            
									AND IsInternal <= @IsInternal
									AND ci.roleid <= 4
						) AS MyTable
				WHERE   RowNum BETWEEN @lbound AND @ubound
			END
			ELSE IF @ToDate < @__archiveDate
			BEGIN
				SELECT	LogID,
					UserID,
					CustID,
					LogDate,
					OldValue,
					NewValue,
					IP,
					Doing,
					ActionID,
					IsInternal,
					ActionTypeID,
					SPName,
					UserName,
					CustName,                                                             
					ActionName
				FROM    ( SELECT    ROW_NUMBER() OVER (ORDER BY LogDate DESC) AS RowNum,
									LogID,
									UserID,
									uc.CustID,
									LogDate,
									OldValue,
									NewValue,
									IP,
									Doing,
									la.ActionID,
									IsInternal,
									la.ActionTypeID,
									la.SPName,
									Username =	CASE 
														when (ci.RoleId > 4 and @IsInternal=0) THEN 'Admin'
														ELSE ci.Username
													END,
									@CustName as CustName,                                         
									la.ActionNameEN As ActionName
							FROM    bodb_CustomerLog_Archive.dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
									INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
							WHERE     uc.CustID = @CustID
									AND LogDate BETWEEN @FromDate AND @ToDate                            
									AND IsInternal <= @IsInternal
									AND ci.roleid <= 4
						) AS MyTable
				WHERE   RowNum BETWEEN @lbound AND @ubound
			END
			ELSE
			BEGIN
				SELECT	LogID,
					UserID,
					CustID,
					LogDate,
					OldValue,
					NewValue,
					IP,
					Doing,
					ActionID,
					IsInternal,
					ActionTypeID,
					SPName,
					UserName,
					CustName,                                                             
					ActionName
				FROM ( 
					SELECT    ROW_NUMBER() OVER (ORDER BY LogDate DESC) AS RowNum, *
					FROM (
						SELECT 		LogID,
									UserID,
									uc.CustID,
									LogDate,
									OldValue,
									NewValue,
									IP,
									Doing,
									la.ActionID,
									IsInternal,
									la.ActionTypeID,
									la.SPName,
									Username =	CASE 
														when (ci.RoleId > 4 and @IsInternal=0) THEN 'Admin'
														ELSE ci.Username
													END,
									@CustName as CustName,                                         
									la.ActionNameEN As ActionName
							FROM      dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
									INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
							WHERE     uc.CustID = @CustID
									AND LogDate BETWEEN @__archiveDate AND @ToDate                            
									AND IsInternal <= @IsInternal
									AND ci.roleid <= 4

						UNION ALL
						SELECT 		LogID,
									UserID,
									uc.CustID,
									LogDate,
									OldValue,
									NewValue,
									IP,
									Doing,
									la.ActionID,
									IsInternal,
									la.ActionTypeID,
									la.SPName,
									Username =	CASE 
														when (ci.RoleId > 4 and @IsInternal=0) THEN 'Admin'
														ELSE ci.Username
													END,
									@CustName as CustName,                                         
									la.ActionNameEN As ActionName
							FROM    bodb_CustomerLog_Archive.dbo.CS_UserLog_Credit AS uc WITH (NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
									INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
							WHERE     uc.CustID = @CustID
									AND LogDate >= @FromDate AND LogDate < @__archiveDate                            
									AND IsInternal <= @IsInternal
									AND ci.roleid <= 4
						) AS MyTable1
					) AS MyTable
				WHERE   RowNum BETWEEN @lbound AND @ubound
			END
		END
	END
END
GO
