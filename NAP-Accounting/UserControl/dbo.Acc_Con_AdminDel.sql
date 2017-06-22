ALTER PROCEDURE [dbo].[Acc_Con_AdminDel]
	@userid		INT,
	@custid		INT,
	@system		NVARCHAR(50) = 'ACCOUNTING',  
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(1000) = '' OUTPUT
AS
/*
	Created: Johnson
	Date: 2012-07-17
	Task: Remove admin from accounting site
	DB: DBPOLICY/BODB02
	
	Revisions:
		- 20130125@Elodie: Write more log on UserLog table in case of DBLOG server failure
		
	Parameter's Explanation:
		- @userid : admin who remove
		- @custid : admin who been removed
*/	
SET NOCOUNT ON

	DECLARE @Begin AS DATETIME;
	SET @Begin = GETDATE();
	
	--Check permission for account site
	EXEC dbo.Acc_Con_CheckPermission @custid = @userid, @funcname = '[UserControl]', @System = @System, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
	IF @ErrCode <> 0
	   RETURN;
	DECLARE @GroupName VARCHAR(50)
	
	SELECT @GroupName = ISNULL(GroupName,'') 
	FROM accCustomer_1 ac WITH(NOLOCK)
		INNER JOIN Acc_GroupInfo_1 ag WITH(NOLOCK) ON ac.groupID = ag.groupID
	WHERE ac.custid = @custid
	
	BEGIN TRANSACTION		
		DELETE FROM Acc_MemberPolicy_1 WHERE custid = @custid	
		DELETE FROM accCustomer_1 WHERE custid = @custid
		
		IF  @@ERROR <> 0
		BEGIN
			ROLLBACK TRANSACTION
			select @ErrMsg = N'Error occurs.Delete unsuccessfully.',@ErrCode = 101
			RETURN
		END
	COMMIT TRANSACTION
	
	DECLARE @LogData AS NVARCHAR (500), 
			@End AS DATETIME, 
			@Duration AS INT;
			
	SELECT @LogData = '<Acc_Con_AdminDel>' +
							'<GroupName>' + @GroupName + '</GroupName>' +							
					  '</Acc_Con_AdminDel>'

	SET @End = GETDATE();
	SET @Duration = DATEDIFF(millisecond, @Begin, @End);
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] 
			@custID = @custid, 
			@Doing = @LogData, 
			@userid = @userid, 
			@typeid = 1,			
			@actionid = 1711, 
			@duration = @Duration
	END TRY
	BEGIN CATCH							  
		SELECT @LogData = '<Acc_Con_AdminDel> ' +							
							'ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 							
						'</Acc_Con_AdminDel>'	
							  
		EXEC WriteLog_UserLog @UserID = @userid, 
							  @Doing = @LogData					 
	END CATCH
	
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminDel] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminDel] TO  [bodbAdminNet]
