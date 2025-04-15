/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_NAP_LM_CustomerClassJobImport] 
AS
/*
	Created: Winfred
	Date: 20240223
	Task : [NAP CM] Job call loop for updating policies [#201256]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20240223@Winfred: [NAP CM] - CCMgt - Update SP to call loop for updating policies [RedmineID: #201256]  
		- 20240315@Winfred: [NAP CM] - CCMgt - Enhance SP call loop for updating policies [RedmineID: #201256] 
		- 20250121@Winfred: [NAP CM] Scale Out DBCUST - Apply Inhouse replication for Customer Class[Redmine: #214119]

	Param's Explanation:
*/ 
BEGIN
	SET NOCOUNT ON;   
	DECLARE @StatusJob TINYINT, @LastModifiedTime DATETIME,@BatchID INT, @IDMin INT, @PolicySites NVARCHAR(MAX),
	@UserID INT,@IsTest TINYINT,@IsOverwrite BIT,@IP NVARCHAR(50),@ErrCode INT = 0 , @ErrMsg NVARCHAR(MAX)

	-- Get Primary Key 
	SELECT @LastModifiedTime = MIN(LastModifiedTime) FROM CustomerClassSMQueue WITH (NOLOCK) WHERE Status = 0
	SELECT @BatchID = MIN(BatchID) FROM CustomerClassSMQueue WITH (NOLOCK) WHERE LastModifiedTime = @LastModifiedTime AND Status = 0
	
	SELECT @IDMin = MIN(ID) FROM CustomerClassSMQueue WITH (NOLOCK) 
	WHERE LastModifiedTime = @LastModifiedTime AND BatchID = @BatchID AND Status = 0

	-- Check Status Job
	SELECT @StatusJob = CAST(VValue AS INT) FROM dbo.SystemSettings WITH (NOLOCK) WHERE VName = 'CustomerClass_Status'
	IF ISNULL(@StatusJob, 0) = 1 OR ISNULL(@IDMin, 0) = 0
	BEGIN
		RETURN
	END

	-- Update Status Job
	UPDATE s
	SET s.VValue = CAST(1 AS VARCHAR(10))
	FROM dbo.SystemSettings s WITH (ROWLOCK) 
	WHERE VName = 'CustomerClassJob_Status'
	
	-- Get ID Data insert
	SELECT @PolicySites = PolicySites, @UserID = UserID, @IsTest = IsTest, @IsOverwrite = IsOverwrite, @IP = IP
	FROM CustomerClassSMQueue WITH (NOLOCK) 
	WHERE ID = @IDMin

	-- Insert data 
	EXEC NAP_LM_CustomerClassPolicySiteIns @IsOverwrite=@IsOverwrite,@UserID=@UserID,@PolicySites=@PolicySites,@IP=@IP,@IsTest=@IsTest, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

	-- Update table Queue
	IF @ErrCode <> 0 -- Failed
	BEGIN
		UPDATE s
		SET s.Status = 2, ErrCode = @ErrCode,
			s.RepUpdateTime	 =	[dbo].[f_GetDateTime2]() 
		FROM dbo.CustomerClassSMQueue s WITH (ROWLOCK) 
		WHERE ID = @IDMin

		DECLARE @Subject VARCHAR(1000) = '', @recipients VARCHAR(1000), @Msg NVARCHAR(MAX) = ''
		SELECT @Subject = 'SQL Server Job System: ''NAP_LM: Import Queue Data'' failed on ' + @@SERVERNAME
		-- Send letstalk if have error
		SELECT @Msg = N'Dear all, on '+ CAST(@LastModifiedTime AS VARCHAR(50))  
						+ N' GMT-4, SP NAP_LM_CustomerClassPolicySiteIns encountered error(s) during runtime as: Error ' + CAST(@ErrCode AS VARCHAR(10))  
						+ N': ' +  @ErrMsg + ' - ID ' + CAST(@IDMin AS VARCHAR(10))  + N' : ' 
					 + REPLACE(REPLACE(REPLACE(REPLACE(@PolicySites, '<ROOT>', ''), '</ROOT>', ''), '<r', '['), '/>', ']')  
					 + N'. Please check this SP again. Thank you. (This is an auto-mail, please do not reply)'
		EXECUTE	DBNOTI.NotificationDB.dbo.Letstalk_SendMessage @To = 'NotiGroup3', @Msg = @msg, @Title=@Subject;

		-- Send mail if have error
		IF @@SERVERNAME IN ('TESTDBCUST')
			SELECT @recipients = 'winfred.pham@starixsoft.com'--'dba_local@starixsoft.com'
		ELSE
			SELECT @recipients = 'pontus@starixsoft.com,it@starixsoft.com,julien.le@starixsoft.com'

		SELECT @Msg = N'Dear all,'
					 + N'<br> On ' + CAST(@LastModifiedTime AS VARCHAR(50))  + ' GMT-4, SP NAP_LM_CustomerClassPolicySiteIns encountered error(s) during '
					 + N'<br> runtime: ' + CAST(@ErrCode AS VARCHAR(10))  + ' : ' +  @ErrMsg + ' </br>'
					 + N'<br> ID ' + CAST(@IDMin AS VARCHAR(10))  + N' : Info ' 
					 + REPLACE(REPLACE(REPLACE(REPLACE(@PolicySites, '<ROOT>', ''), '</ROOT>', ''), '<r', '['), '/>', ']')  + N' </br>'
					 + N'<br> Please check this SP again. '+ ' </br>'
					 + N'<br> Thank you.'+ ' </br>'
					 + N'<br> This is an auto-mail. Please do not reply. </br>'
			
		EXEC msdb.dbo.sp_send_dbmail
			@recipients		= @recipients,
			@subject		= @subject,
			@body			= @Msg,
			@body_format	= 'HTML',
			@profile_name =DEFAULT;	
	END
	ELSE -- Complete
	BEGIN
		UPDATE s
		SET s.Status = 1,
			s.RepUpdateTime	 =	[dbo].[f_GetDateTime2]() 
		FROM dbo.CustomerClassSMQueue s WITH (ROWLOCK) 
		WHERE ID = @IDMin
	END

	-- Update Status job 
	UPDATE s
	SET s.VValue = CAST(0 AS VARCHAR(10))
	FROM dbo.SystemSettings s WITH (ROWLOCK) 
	WHERE VName = 'CustomerClassJob_Status'

	-- Clear data 3 month
	DELETE a 
	OUTPUT DELETED.ID, [dbo].[f_GetDateTime2]() 
	INTO CustomerClassSMQueue_Del_InHouse(ID, RepUpdateTime )
	FROM dbo.CustomerClassSMQueue a WITH (ROWLOCK) WHERE LastModifiedTime <= DATEADD(month, -3, GETDATE()) AND Status = 1

END
