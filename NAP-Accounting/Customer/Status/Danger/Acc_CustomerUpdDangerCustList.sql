/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdDangerCustList]
	@CustList			VARCHAR(MAX) = '',	
	@DangerType			TINYINT,
	@DangerLevel		INT,
	@UserID				INT,
	@IP					VARCHAR(15) = '',
	@ErrCode			INT = 0				OUTPUT,
	@ErrMsg				NVARCHAR(200) = ''	OUTPUT	
AS
SET NOCOUNT ON
/*
Created: 
Task : Update Danger, Danger2, Danger3 fields , and write log content [RedmineID:#86627]
DB: DBCUST/CUSTDB
Original:

Revisions:	
	- 20171124@Winnie: Update Danger, Danger2, Danger3 fields , and write log content [RedmineID:#86627]
Param's Explanation:
	@CustList: List usernames of members will be updated,
	@DangerType:  type of danger,
		1: Soccer Live
		2: Soccer Non-Live
		3: OtherSports
	@DangerLevel: new danger level value,
*/		
/* region1: declare params, tables, get input and validate*/
BEGIN
	DECLARE @startRun	DATETIME
	DECLARE @endRun		DATETIME
	DECLARE @CustId		INT
	DECLARE @duration	INT
	DECLARE	@roleid		INT
	DECLARE	@DangerOld	INT
	SET @startRun = GETDATE()

	DECLARE @tmpCust TABLE (		
						UserName			NVARCHAR(50)					
					,	CustID				INT
					,	RoleID				TINYINT			
					,	Danger				TINYINT
					,	IsFinished			BIT DEFAULT(0)
					,	PRIMARY KEY CLUSTERED (UserName)
					);
	
	--Get list Username
	INSERT INTO @tmpCust(UserName)
	SELECT ss.val	
	FROM dbo.strSplit(@CustList, ',') AS ss
	
	IF (SELECT COUNT(UserName) FROM @tmpCust)>100
	BEGIN
		SELECT @ErrCode=101
		SELECT @ErrMsg='Maximun is 100 usernames'
		RETURN
	END
	-- get custid, roleid and danger

	-- If danger for Soccer Live
	IF @DangerType=1
	BEGIN
		UPDATE t
			SET t.CustID=c.custid,t.RoleID=c.roleid,t.Danger=c.danger
		FROM @tmpCust t 
			INNER JOIN dbo.custInfo c WITH(NOLOCK) ON t.UserName=c.username
	END
	-- If danger for Soccer Non-Live
	ELSE IF @DangerType=2
	BEGIN
		UPDATE t
			SET t.CustID=c.custid,t.RoleID=c.roleid,t.Danger=c.danger2
		FROM @tmpCust t 
			INNER JOIN dbo.custInfo c WITH(NOLOCK) ON t.UserName=c.username
	END
	-- If danger for OtherSports
	ELSE
	BEGIN
		UPDATE t
			SET t.CustID=c.custid,t.RoleID=c.roleid,t.Danger=c.danger3
		FROM @tmpCust t 
			INNER JOIN dbo.custInfo c WITH(NOLOCK) ON t.UserName=c.username
	END

	-- select @ErrorCode=100: Invalid usernames

	IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE CustID IS NULL)
	BEGIN
		SELECT @ErrCode=100
		SELECT @ErrMsg='There are invalid usernames'
	END

	/* region2: update for member level and Call execrept sp to update SMA folow business*/
	-- update for member level
	IF @DangerType = 1 
	BEGIN 
		
		UPDATE c
			SET danger = @DangerLevel	
		FROM custinfo c WITH(UPDLOCK,ROWLOCK) 
			INNER JOIN @tmpCust t ON c.custid=t.CustID			
		WHERE t.RoleID=1
		 		
	END 
	-- If danger for Soccer Non-Live
	ELSE IF @DangerType = 2
	BEGIN 

		UPDATE c
			SET danger2 = @DangerLevel	
		FROM custinfo c WITH(UPDLOCK,ROWLOCK) 
			INNER JOIN @tmpCust t ON c.custid=t.CustID			
		WHERE t.RoleID=1
				  		
	END 
	-- If danger for OtherSports
	ELSE 
	BEGIN 
		
		UPDATE c
			SET danger3 = @DangerLevel	
		FROM custinfo c WITH(UPDLOCK,ROWLOCK) 
			INNER JOIN @tmpCust t ON c.custid=t.CustID			
		WHERE t.RoleID=1 	
			
	END 

	UPDATE @tmpCust SET IsFinished=1 WHERE RoleID=1

	IF EXISTS (SELECT TOP 1 1 FROM @tmpCust WHERE CustID IS NOT NULL AND IsFinished=0)
	BEGIN
		WHILE (1 = 1)
		BEGIN
			UPDATE TOP (1) @tmpCust
			SET isfinished		= 1
				,@CustId		= custid
				,@DangerOld		= Danger
				,@roleid		= roleid			
			WHERE isfinished	= 0 
				AND Custid IS NOT NULL
	
			IF @@ROWCOUNT = 0 BREAK
	
			EXEC dbo.Acc_CustomerInfo_Execrep_03	@custid			= @custid, 
													@roleid			= @roleid, 
													@DangerType		= @DangerType,
													@DangerLevel	= @DangerLevel 	
		
		END	
	END

	/* region3: write log*/
	DECLARE @LogSPData VARCHAR(2000)

									SELECT @LogSPData = '<Acc_CustomerUpdDangerCustList CustList="'+ COALESCE(CAST(@CustList AS VARCHAR(MAX)),SPACE(1)) + '"'						
					+ ' DangerType="' + COALESCE(CONVERT(VARCHAR(1),@DangerType),SPACE(1)) + '"'
					+ ' RoleId="' + COALESCE(CONVERT(VARCHAR(1),@roleid),SPACE(1)) + '"'
					+ ' DangerLevel="' + COALESCE(CONVERT(VARCHAR(2),@DangerLevel),SPACE(1)) + '"'
					+ ' DangerLevel_Old="' + COALESCE(CONVERT(VARCHAR(2),@DangerOld),SPACE(1)) + '"'
					+ ' UserID="'+ COALESCE(CAST(@UserID AS VARCHAR(50)),SPACE(1)) + '"'				
					+ ' ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(50)),space(1)) + '"'
					+ ' ErrMsg="'+ COALESCE(cast(@ErrMsg as varchar(400)),space(1))+'"'
					+ ' IP="'+ COALESCE(cast(@IP as varchar(15)),space(1))+'" />'

	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)

														BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,	  
		@ActionID = 1165,
		@TrackingValue = @LogSPData,
		@duration = @duration
END TRY
BEGIN CATCH
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,	
		@ActionID = 1165,
		@TrackingValue = @LogSPData,
		@duration = @duration
END CATCH

	-- select out put table for error cases 
	SELECT 	STUFF((
			SELECT ',' + UserName  
			FROM @tmpCust 
			WHERE CustID IS NULL
			FOR XML PATH('')
		), 1,1,'') AS ListUsername,'Invalid Usernames' AS ErrorMsg
END

GO
