/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_UserLog_CreditSel]    
    @CustID INT ,
	@CustName varchar(50) = '',
    @FromDate DATETIME ,
    @ToDate DATETIME ,    
    @IsInternal TINYINT ,
    @PageIndex INT ,
    @PageSize INT
AS 
/* 
	Created:20190606@Elodie
    Task: Get paged log credit
    DB: DBLOG/bodb_CustomerLog
    
	Revisions:
		- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]

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
	DECLARE @Site VARCHAR(10)

	SELECT @Site = Site FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE custid = @CustID

	IF @Site = 'CN88'
	BEGIN
		EXEC CS_UserLog_CreditSel @CustID = @CustID, @CustName = @CustName, @FromDate = @FromDate, @ToDate = @ToDate, @IsInternal = @IsInternal, @PageIndex = @PageIndex, @PageSize = @PageSize
	END
	ELSE
	BEGIN
		EXEC Acc_UserLog_CreditSel @CustID = @CustID, @CustName = @CustName, @FromDate = @FromDate, @ToDate = @ToDate, @IsInternal = @IsInternal, @PageIndex = @PageIndex, @PageSize = @PageSize
	END
END
GO
