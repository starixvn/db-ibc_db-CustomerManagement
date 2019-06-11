/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_UserLog_RunSPSel]    
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
    DB: DBLOG/bodb_CustomerLog
    
    Revisions:
		- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]

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
	DECLARE @Site VARCHAR(10)

	SELECT @Site = Site FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE custid = @CustId

	IF @Site = 'CN88'
	BEGIN
		EXEC CS_UserLog_RunSPSel 
			@CustId = @CustId, @CustName = @CustName,
			@FromDate = @FromDate, @ToDate = @ToDate, 
			@ActionTypeId = @ActionTypeId, @IsInternal = @IsInternal, 
			@LowerActionId = @LowerActionId, @UpperActionId = @UpperActionId, 
			@PageIndex = @PageIndex, @PageSize = @PageSize
	END
	ELSE
	BEGIN
		EXEC Acc_UserLog_RunSPSel 
			@CustId = @CustId, @CustName = @CustName, 
			@FromDate = @FromDate, @ToDate = @ToDate, 
			@ActionTypeId = @ActionTypeId, @IsInternal = @IsInternal, 
			@LowerActionId = @LowerActionId, @UpperActionId = @UpperActionId, 
			@PageIndex = @PageIndex, @PageSize = @PageSize
	END
END
GO
