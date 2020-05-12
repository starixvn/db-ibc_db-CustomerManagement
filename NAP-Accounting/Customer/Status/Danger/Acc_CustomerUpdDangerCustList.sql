/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdDangerCustList]
	@CustList			VARCHAR(MAX) = '',	
	@DangerType			TINYINT,
	@DangerLevel		INT,
	@UserName			NVARCHAR(50),
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
	- 20181130@Winnie: Stop updating dangerous level of SMA when evidence is updated on FPS [RedmineID:#105604]
	- 20200511@Tiara: Enhance validation and error message [Redmine: #129306]
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
	DECLARE @UserId		INT
	DECLARE @duration	INT
	DECLARE	@roleid		INT
	DECLARE	@DangerOld	INT
	DECLARE	@DangerTypeText	VARCHAR(50)
	DECLARE @ErrCodeWriteLog		INT	
	DECLARE @ErrMsgWriteLog			NVARCHAR(200) 
	SELECT  @ErrCodeWriteLog=0
	SELECT  @ErrMsgWriteLog	=''

	SET @startRun = GETDATE()
	SET @ErrCode=0

	SELECT @UserID=CustID FROM dbo.Custinfo WITH(NOLOCK) WHERE username=@UserName

	DECLARE @tmpCust TABLE (		
						UserName			NVARCHAR(50)					
					,	CustID				INT
					,	RoleID				TINYINT			
					,	Danger				TINYINT
					,	IsFinished			BIT DEFAULT(0)
					,	IsFinishedWriteLog	BIT DEFAULT(0)
					,	PRIMARY KEY CLUSTERED (UserName)
					);
	
	--Get list Username
	INSERT INTO @tmpCust(UserName)
	SELECT ss.val	
	FROM dbo.strSplit(@CustList, ',') AS ss	
	
	-- get custid, roleid and danger

	-- If danger for Soccer Live
	IF @DangerType=1
	BEGIN
		UPDATE t
			SET t.CustID=c.custid,t.RoleID=c.roleid,t.Danger=c.danger
		FROM @tmpCust t 
			INNER JOIN dbo.custInfo c WITH(NOLOCK) ON t.UserName=c.username
			
		SET @DangerTypeText='Soccer Live'
	END
	-- If danger for Soccer Non-Live
	ELSE IF @DangerType=2
	BEGIN
		UPDATE t
			SET t.CustID=c.custid,t.RoleID=c.roleid,t.Danger=c.danger2
		FROM @tmpCust t 
			INNER JOIN dbo.custInfo c WITH(NOLOCK) ON t.UserName=c.username
			
		SET @DangerTypeText='Soccer Non-Live'
	END
	-- If danger for OtherSports
	ELSE
	BEGIN
		UPDATE t
			SET t.CustID=c.custid,t.RoleID=c.roleid,t.Danger=c.danger3
		FROM @tmpCust t 
			INNER JOIN dbo.custInfo c WITH(NOLOCK) ON t.UserName=c.username
			
		SET @DangerTypeText='OtherSports'
	END

	-- select @ErrorCode=100: Invalid usernames

	IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE CustID IS NULL)
	BEGIN
		SELECT @ErrCode=100
		SELECT @ErrMsg= 'Username '+	STUFF((
				SELECT ',' + UserName  
				FROM @tmpCust 
				WHERE CustID IS NULL
				FOR XML PATH('')
			), 1,1,'')+' do(es) not exist.' 
	END
		--Do not allow deposit accounts to update Super and Master danger level
	IF EXISTS (SELECT 1
				FROM Customer C WITH (NOLOCK)
				INNER JOIN Site S WITH (NOLOCK) ON  C.site = S.site
				INNER JOIN @tmpCust T ON T.CustID = C.custid 
				WHERE S.isLicensee = 1 AND T.RoleID IN (3,4))
	BEGIN
		SELECT @ErrCode=101
		SELECT  @ErrMsg= 'You can not update dangerous level for Super accounts '+	STUFF((
				SELECT ',' + T.UserName  
				FROM @tmpCust T
				INNER JOIN Customer C WITH (NOLOCK) ON C.custid = T.CustID
				INNER JOIN Site S WITH (NOLOCK) ON  C.site = S.site
				WHERE .isLicensee = 1 AND T.RoleID = 4
				FOR XML PATH('')
			), 1,1,'') + 'Master accounts ' +	STUFF((
				SELECT ',' + T.UserName  
				FROM @tmpCust T
				INNER JOIN Customer C WITH (NOLOCK) ON C.custid = T.CustID
				INNER JOIN Site S WITH (NOLOCK) ON  C.site = S.site
				WHERE .isLicensee = 1 AND T.RoleID = 3
				FOR XML PATH('')
			), 1,1,'')  
		RETURN
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

	/* region3: write log*/
	IF EXISTS (SELECT TOP 1 1 FROM @tmpCust WHERE CustID IS NOT NULL AND IsFinished=1)
	BEGIN
		WHILE (1 = 1)
		BEGIN
			UPDATE TOP (1) @tmpCust
			SET IsFinishedWriteLog		= 1
				,@CustId				= custid
				,@DangerOld				= Danger				
			WHERE IsFinishedWriteLog	= 0 
				AND IsFinished=1
				AND Custid IS NOT NULL
	
			IF @@ROWCOUNT = 0 BREAK
	
				DECLARE @LogSPData VARCHAR(2000),@LogSPData_Old VARCHAR(2000) 		  

				Select @LogSPData = '<Acc_CustomerUpdDangerCustList CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '"'					
					+' Dangerouslevel' + '="'  + coalesce(cast(@DangerLevel as varchar(50)),space(1)) + '"'
					+ ' Dangeroustype="'+ COALESCE(CAST(@DangerTypeText AS VARCHAR(50)),SPACE(1)) + '"'			
					+ ' FPSUser="'+ COALESCE(CAST(@UserName AS VARCHAR(50)),SPACE(1)) + '"'					
					+ ' ErrCode="'+ coalesce(cast(@ErrCodeWritelog as varchar(50)),space(1)) + '"'
					+ ' ErrMsg="'+ coalesce(cast(@ErrMsgWritelog as varchar(400)),space(1))+'"'
					+ ' IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
					
				Select @LogSPData_Old = '<Acc_CustomerUpdDangerCustList CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '"'				
					+' Dangerouslevel' + '="'  + coalesce(cast(@DangerOld as varchar(50)),space(1)) + '"'
					+ ' Dangeroustype="'+ COALESCE(CAST(@DangerTypeText AS VARCHAR(50)),SPACE(1)) + '"'			
					+ ' FPSUser="'+ COALESCE(CAST(@UserName AS VARCHAR(50)),SPACE(1)) + '"'					
					+ ' ErrCode="'+ coalesce(cast(@ErrCodeWritelog as varchar(50)),space(1)) + '"'
					+ ' ErrMsg="'+ coalesce(cast(@ErrMsgWritelog as varchar(400)),space(1))+'"'
					+ ' IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'			

				SET @endRun = GETDATE()
				SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)

				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
						@UserID = @UserID,
						@Custid = @CustId,	  
						@ActionID = 1165,
						@TrackingValue = @LogSPData,
						@TrackingValue2 = @LogSPData_old,  
						@duration = @duration
				END TRY
				BEGIN CATCH
					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
						@UserID = @UserID,	
						@Custid = @CustId,	  
						@ActionID = 1165,
						@TrackingValue = @LogSPData,
						@TrackingValue2 = @LogSPData_old,  
						@duration = @duration
				END CATCH
		
		END	
	END
	
END



GO
