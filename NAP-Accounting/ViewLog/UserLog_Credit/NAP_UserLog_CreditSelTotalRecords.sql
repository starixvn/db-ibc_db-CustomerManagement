/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_UserLog_CreditSelTotalRecords]    
    @CustID INT,
    @FromDate DATETIME,
    @ToDate DATETIME,
    @IsInternal TINYINT    
AS 
/* 
	Created:20190606@Elodie
    Task: count total record with input conditions
    DB: DBLOG/bodb_CustomerLog

    Param's Explaination:    
		- @CustID: a customer which we want to view actions affect to.
		- @FromDate: date range to view log
		- @ToDate: date range to view log	
		- @IsInternal: AccountingSite: 1 Agent:0

	Revisions:
		- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]
*/
BEGIN
	DECLARE @Site VARCHAR(10)

	SELECT @Site = Site FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE custid = @CustID

	IF @Site = 'CN88'
	BEGIN
		EXEC CS_UserLog_CreditSelTotalRecords @CustID = @CustID, @IsInternal = @IsInternal, @FromDate = @FromDate, @ToDate = @ToDate
	END
	ELSE
	BEGIN
		EXEC Acc_UserLog_CreditSelTotalRecords @CustID = @CustID, @IsInternal = @IsInternal, @FromDate = @FromDate, @ToDate = @ToDate
	END
END
GO
