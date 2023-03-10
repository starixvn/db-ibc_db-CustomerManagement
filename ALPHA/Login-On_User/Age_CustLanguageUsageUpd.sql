/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/
ALTER PROC [dbo].[Age_CustLanguageUsageUpd]  
@CustID INT , 
@SubAccID INT  = 0,
@LanguageUsage VARCHAR(2) ,
@IP 		   VARCHAR(15) = ''
AS
/*
	Created: 20230214@Helios
	Task : Update language change by SMA in Alpha Site
	DB: DBCUST/CustDB

	Revisions:
	- 20230214@Helios: Enhance language part [RedmineID: #183700]
	- 20230310@Helios: Insert Log Changed [RedmineID: #184858]

EXEC  [dbo].[Age_CustLanguageUsageUpd] 2000003763, 0 , 'EN'
EXEC  [dbo].[Age_CustLanguageUsageUpd] 2000003763, 1722384 , 'TH'
EXEC  [dbo].[Age_CustLanguageUsageUpd] 2000003763, 1722385 , 'CN'
*/ 
BEGIN
	
	SET NOCOUNT ON
	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @ActionID INT = 95085

IF  @SubAccID > 0
	BEGIN
		UPDATE custSub Set LanguageUsage = @LanguageUsage
		FROM CustLoginInfoSub custsub WITH (ROWLOCK ,UPDLOCK)
		WHERE CustID = @CustID and SubAccID = @SubAccID
	END
ELSE
	BEGIN
		UPDATE cust Set LanguageUsage = @LanguageUsage
		FROM CustLoginInfo cust WITH (ROWLOCK ,UPDLOCK)
		WHERE CustID = @CustID
	END

SET @StartRun = GETDATE()
SET @EndRun = GETDATE()
SET @Duration = DATEDIFF (MILLISECOND, @StartRun, @EndRun)

DECLARE @LogData VARCHAR(500)
SELECT  @LogData = '<R '
					+ 'CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" ' 
					+ 'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(50)),space(1)) + '" ' +  
					+ 'LanguageUsage="'+ coalesce(cast(@LanguageUsage as varchar(50)),space(1)) + '" ' 
					+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
					+ ' />'
 
EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= @CustID,
			@CustId				= @CustId,
			@ActionId			= @ActionID,
			@TrackingValue		= @LogData,
			@Duration			= @Duration

END