/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_UserLog_LoginSelTotalRecords]
    @UserId INT,	
	@UserName AS VARCHAR(50),
    @FromDate DATETIME,
    @ToDate DATETIME,    
    @LogType TINYINT = 0
	   
AS
/* 
	Created:20190606@Elodie
    Task: count total record with input conditions
    DB: DBLOG/bodb_CustomerLog

	Revisions:
		- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]

    Param's Explaination:    
		- @CustID: a customer which we want to view actions affect to.
		- @FromDate: date range to view log
		- @ToDate: date range to view log	
		- @LogType: 0: show log for customer (Main Alpha) 
					1: show log for Internal Alpha (link alpha tu ExtNap va Nap) 
					2: show log for Nap
	
*/
BEGIN
	DECLARE @Site VARCHAR(10)

	SELECT @Site = Site FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE custid = @UserId

	IF @Site = 'CN88'
	BEGIN
		EXEC CS_UserLog_LoginSelTotalRecords @UserId = @UserId, @UserName = @UserName, @FromDate = @FromDate, @ToDate = @ToDate, @LogType = 2
	END
	ELSE
	BEGIN
		EXEC Acc_UserLog_LoginSelTotalRecords @UserId = @UserId, @UserName = @UserName, @FromDate = @FromDate, @ToDate = @ToDate, @LogType = 2
	END
END
GO