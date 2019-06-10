/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_UserLog_LoginSel]
    @UserId INT,
	@UserName AS VARCHAR(50),
    @FromDate DATETIME,
    @ToDate DATETIME,    
    @PageIndex INT,
    @PageSize INT
AS 
/* 
	Created:20190606@Elodie
    Task: Get paged log credit
    DB: DBLOG/bodb_CustomerLog

	Revisions:
		- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]
	
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
	DECLARE @Site VARCHAR(10)

	SELECT @Site = Site FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE custid = @UserId

	IF @Site = 'CN88'
	BEGIN
		EXEC CS_UserLog_LoginSel	@UserId = @UserId, @UserName = @UserName, 
									@FromDate = @FromDate, @ToDate = @ToDate, 
									@LogType = 2, @PageIndex = @PageIndex, @PageSize = @PageSize
	END
	ELSE
	BEGIN
		EXEC Acc_UserLog_LoginSel	@UserId = @UserId, @UserName = @UserName, 
									@FromDate = @FromDate, @ToDate = @ToDate, 
									@LogType = 2, @PageIndex = @PageIndex, @PageSize = @PageSize
	END
END
GO