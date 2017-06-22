ALTER PROCEDURE [dbo].[Acc_CustomerUpdGroupHeadlineOwner]
	@HeadlineID INT,
	@OwnerName NVARCHAR(100),
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(500) = '' OUTPUT,
	@Language VARCHAR(2)= 'E',
	@IP VARCHAR(15) = ''
AS
/*	
	Created: Elodie
	Date: 2016-06-10
	Task : Update headline type  
	DB: DBCUST/CustDB
	Original:  
	
	Revisions:
		- 20160915@Elodie: SMA Mangement allows to input freetext for Owner info [Redmine:#63349]

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT
	SET @StartRun = GETDATE()

	Declare @Old_OwnerName NVARCHAR(100) = '', @GroupID SMALLINT = 0

	--Check permission for account site 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @CustID=@UserID, @funcname='[SMAManagement]', @ErrCode=@ErrCode OUTPUT, @ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS (SELECT 1 FROM dbo.custInfo WITH (NOLOCK) WHERE custid = @HeadlineID AND roleid BETWEEN 1 AND 4)
	BEGIN
		SELECT @ErrMsg = 'Customer is not valid.'
			 , @ErrCode = 101
		RETURN
	END

	EXEC Acc_CustomerSelCheckEnable @CustID = @HeadlineID, @ErrCode=@ErrCode OUTPUT, @ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <>0 
		RETURN

	SELECT @Old_OwnerName = hl.OwnerName, @GroupID = GroupID 
	FROM dbo.CustGroupHeadline hl WITH (NOLOCK)
	WHERE hl.CustID = @HeadlineID 
	
	UPDATE  CustGroupHeadline WITH (ROWLOCK, UPDLOCK) 
	SET		OwnerName = @OwnerName
	WHERE	CustID = @HeadlineID
	
	IF @@ROWCOUNT = 0
		INSERT INTO dbo.CustGroupHeadline( CustID, GroupID, HeadlineType, OwnerName)
		SELECT @HeadlineID, 0, NULL, @OwnerName
	
	---Write log 
	DECLARE @LogSPData NVARCHAR(MAX), @TrackingValue2 NVARCHAR(MAX)

	SELECT @LogSPData = '<Acc_CustomerUpdGroupHeadlineOwner CustID="' + CONVERT (VARCHAR(20), @HeadlineID) + '" ' + 
			'GroupID="' + CONVERT (VARCHAR(20), @GroupID) + '" ' + 
			'Owner="' + @OwnerName + '" ' +
			'IP="' + coalesce (cast (@IP AS VARCHAR(15)), space (1)) + '" ' +
			'ErrCode="' + coalesce (cast (@ErrCode AS VARCHAR(10)), space (1)) + '" ' +
			'ErrMsg="' + @ErrMsg + '" />'

	SELECT @TrackingValue2 = '<Acc_CustomerUpdGroupHeadlineOwner CustID="' + CONVERT (VARCHAR(20), @HeadlineID) + '" ' + 
			'GroupID="' + CONVERT (VARCHAR(20), @GroupID) + '" ' + 
			'Owner="' + @Old_OwnerName + '" ' +
			'IP="' + coalesce (cast (@IP AS VARCHAR(15)), space (1)) + '" ' +
			'ErrCode="' + coalesce (cast (@ErrCode AS VARCHAR(10)), space (1)) + '" ' +
			'ErrMsg="' + @ErrMsg + '" />'

	SET @EndRun = getdate()
	SET @Duration  = DATEDIFF(millisecond,@StartRun,@EndRun)

	/*623	Acc_CustomerUpdConsolidatedGroup	Update Consolidated Group*/
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @HeadlineID,
		@ActionID = 661,
		@TrackingValue = @LogSPData,
		@TrackingValue2 = @TrackingValue2,
		@Duration = @Duration
END
		 
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdGroupHeadlineOwner] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdGroupHeadlineOwner] TO [vnteam]