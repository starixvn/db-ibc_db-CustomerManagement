/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_VR_ManualUpdAcc_Remove]
	@SportType INT = NULL,
	@CustIDs VARCHAR(MAX),
	@UserID INT = NULL,
	@IP VARCHAR(15) = '',
	@ErrMsg	NVARCHAR(MAX) = '' OUTPUT,
	@ErrCode TINYINT = 0 OUTPUT
AS
/*    
	Created: 20200310@Eden    
	Task :  Remove Manually Updated Virtual Rate Accounts
	DB: CustDB/DBCUST
	    
	Revisions:    
		- 20200310@Eden : First commit [Redmind: #128749]

	Examples :
		DECLARE @ErrMsg	NVARCHAR(MAX) = '', @ErrCode TINYINT = 0 
		EXEC dbo.[Acc_VR_ManualUpdAcc_Remove]
			@SportType = 43,
			@CustIDs = '1176086,1176083,1176092',
			@UserID = 8,
			@IP  = '1.1.1.1',
			@ErrMsg	 = @ErrMsg OUTPUT,
			@ErrCode  = @ErrCode OUTPUT
		SELECT @ErrMsg, @ErrCode
  
*/ 
BEGIN
	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @ActionID INT = 813
	SET @StartRun = GETDATE()

	CREATE TABLE #CustIDs(CustID INT)

	INSERT INTO #CustIDs(CustID)
	SELECT val 
	FROM dbo.f_StringSplit(@CustIDs,',') 
	OPTION (MAXRECURSION 0)

	SELECT vr.CustID, CAST (0 AS BIT) IsProcessed
	INTO #RealUpdateList
	FROM [dbo].[VRSettingManualUpdAcc] vr WITH(NOLOCK)
	WHERE vr.SportType = @SportType
		AND vr.CustID IN ( SELECT CustID FROM #CustIDs)

	DELETE vr
	FROM [dbo].[VRSettingManualUpdAcc] vr WITH(ROWLOCK)
	WHERE vr.SportType = @SportType
		AND vr.CustID IN ( SELECT CustID FROM #RealUpdateList)

	IF @@ERROR <> ''
	BEGIN
		SET @ErrCode = 1
		SELECT @ErrMsg = 'Failed' 
		RETURN
	END

	SET @EndRun = GETDATE()
	SET @Duration = DATEDIFF (MILLISECOND, @StartRun, @EndRun)

	DECLARE @LogData VARCHAR(500),@CustId INT
	SELECT  @LogData = '<R '
							+ 'SportType="'+ coalesce(cast(@SportType as varchar(50)),space(1)) + '" ' 
							+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
							+ ' />'

	WHILE 1 = 1
	BEGIN
		UPDATE TOP(1) #RealUpdateList
		SET @CustId = custID,
			IsProcessed = 1
		WHERE IsProcessed = 0

		IF @@ROWCOUNT = 0
			BREAK;

		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= @UserId,
			@CustId				= @CustId,
			@ActionId			= @ActionID,
			@TrackingValue		= @LogData,
			@Duration			= @Duration     
	END  
END