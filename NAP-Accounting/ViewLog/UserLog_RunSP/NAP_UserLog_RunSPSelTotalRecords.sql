/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_UserLog_RunSPSelTotalRecords]     
	@CustId INT, 
    @FromDate DATETIME,
    @ToDate DATETIME,
    @ActionTypeId INT =-1,
    @IsInternal TINYINT,
	@LowerActionId INT = NULL,
	@UpperActionId INT = NULL  
AS 
/* 
	Created:20190606@Elodie
    Task: count total record with input conditions
    DB: DBLOG/bodb_CustomerLog

    Param's Explaination:    
		- @CustID: a customer which we want to view actions affect to.
		- @FromDate: date range to view log
		- @ToDate: date range to view log	
		- @IsAdminAccess: Accouting site TRUE, agent = FALSE
		- @IsSubCust: view logaction affect to sub account or not

	 Revisions:
		- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]
*/
BEGIN
	DECLARE @Site VARCHAR(10)

	SELECT @Site = Site FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE custid = @CustId

	IF @Site = 'CN88'
	BEGIN
		EXEC CS_UserLog_RunSPSelTotalRecords
			@CustId = @CustId,
			@FromDate = @FromDate, @ToDate = @ToDate, 
			@ActionTypeId = @ActionTypeId, @IsInternal = @IsInternal, 
			@LowerActionId = @LowerActionId, @UpperActionId = @UpperActionId
	END
	BEGIN
		EXEC Acc_UserLog_RunSPSelTotalRecords
			@CustId = @CustId,
			@FromDate = @FromDate, @ToDate = @ToDate, 
			@ActionTypeId = @ActionTypeId, @IsInternal = @IsInternal, 
			@LowerActionId = @LowerActionId, @UpperActionId = @UpperActionId
	END
END
GO
