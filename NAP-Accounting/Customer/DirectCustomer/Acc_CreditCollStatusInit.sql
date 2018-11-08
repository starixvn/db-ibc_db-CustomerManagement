/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_CreditCollStatusInit] 
	@CustId 			INT,
	@UserId 			INT,	
	@IP					VARCHAR(15) = '',
	@Language			VARCHAR(2) = 'E',
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: Louis
	Date: 2018-11-05
	Task: Credit Collection Summary
	DB: DBCust/CustDB

	Revisions:
		--20181105@Louis: Credit Collection Summary  [RedmineID: #98621]
	Parameter's explaination: 		
		• @Status: 			 0: Normal 
							 1: Alert
							 2: Unused
*/
BEGIN
	SET NOCOUNT ON	 
	DECLARE @startRun DATETIME;
	DECLARE @endRun DATETIME;
	DECLARE @duration INT;
	SET @startRun = GETDATE();
		
	UPDATE CustDirectAccount WITH(ROWLOCK, UPDLOCK)
	SET Coll_Status = 0
	WHERE CustId = @CustId;
	
	SET @ErrMsg = '';		
		
	IF (@@ERROR <> 0)
		SELECT @ErrCode = 101, @ErrMsg = 'Init process is unsuccessful!'	
	
	DECLARE @LogData NVARCHAR(4000);
	SELECT @LogData = '<Acc_CreditCollStatusInit ' 
					+ 'CustId="' + COALESCE(CAST(@CustId AS VARCHAR(50)), SPACE(1)) + '" ' 
					+ 'Coll_Status="' + COALESCE([dbo].[f_CreditColl_GetStatusName](0), SPACE(1)) + '" '
					+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
					+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)),SPACE(1)) + '" '
					+ 'ErrMsg="' + @ErrMsg + '" '
					+ '/>';

	DECLARE @LogOldData NVARCHAR(4000);
	SELECT @LogOldData = '<Acc_CreditCollStatusInit ' 
					+ 'CustId="' + COALESCE(CAST(@CustId AS VARCHAR(50)), SPACE(1)) + '" ' 
					+ 'Coll_Status="NULL" '
					+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
					+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)),SPACE(1)) + '" '
					+ 'ErrMsg="' + @ErrMsg + '" '
					+ '/>';
	
	SET @endRun = GETDATE();
	set @duration  = DATEDIFF(MILLISECOND, @startRun, @endRun);

	EXEC Acc_WriteLog_UserLog_RunSP_Wrapper @Userid = @UserId
		, @CustId = @CustId
		, @ActionID = 1166
		, @TrackingValue = @LogData
		, @TrackingValue2 = @LogOldData
		, @Duration = @duration;	
		
END

GO




