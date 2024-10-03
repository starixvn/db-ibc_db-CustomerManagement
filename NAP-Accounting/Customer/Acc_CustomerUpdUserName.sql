/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,vnteam" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdUserName]
	@oldname varchar(30), 
	@newname varchar(30),
	@userid int = 8,	
	@ReturnCustId int = 0 output,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
Created: 
Task : Change username 
DB: DBCUST/CustDB
Original:

Revisions:
    - 20080213@Phuc: Check permission for account site
    - 20080815@PhuongDao: Check an account disabled or not
    - 20090218@PhuongDao: Check username2
    - 20090517@Thien: update username on bettrans and bettrans14 / write log userlog_runSP
    - 20090528@Kiwi: add checking for Casino
    - 20090701@Lee: Return custid for casino customer 
	- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]	
	- 20090917@Phuc: Write log into dblog.
	- 20091008@Kiwi: Remove WriteLog_UserLog	
	- 20091112@Simon: Write Log IP
	- 20100107@Lewin: Change LogSPData format, write log by new function
	- 20101021@Henry: Record execution time
	- 20110517@Jamie: Expand the size of input name to varchar(30)
	- 20110722@Sophia: Add prefix 'Agency$' to Username2
	- 20110722@Sophia: Remove prefix 'Agency$' to Username2
	- 20110907@Lukas: Change linked-server from DB052 -> DB053
	- 20120507@Lukas: call update username in CRM system
	- 20121213@Dan: Change linked server from DB052-->DBCRM
	- 20130310@Lukas: change linked-server alias & add more write log section
	- 20130705@Kathy: Synchronize user data between Accounting and AdminSite: Change username in AdminSiteUser table
	- 20131108@Elodie: Splitting bodb02 into CustDB (Update username in bettrans, bettrans14 by link database)
	- 20150610@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB, call Acc_CustomerUpdUserName_Bettrans by linked server DBTXN) [Redmine:#36216]	                    
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	- 20181002@Dominic: Check existing username/username2 in archived DB  [Redmine:99882]
	- 20190422@Elodie: Offer unique nickname for CN88 [Redmine:112287]
	- 20200512@Johnson: check super's prefix for 789y's group [redmine:#133846]
	- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
	- 20220722@Eden: Scale Out DBTrans  [redmine: #158293]
    - 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
Param's Explanation:
• @ErrCode:
    = 0: super create master successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @roleid INT 
		,@startRun DATETIME
		,@endRun DATETIME
		,@duration INT
		,@GroupName VARCHAR(50)
		
	set @startRun = getdate()

	Declare @custid int, @IsExists BIT, @Site VARCHAR(10)
	SELECT @custid = custid from custinfo with (nolock) where username = @oldname
	SELECT @site = site FROM customer WITH(NOLOCK) WHERE custid = @custid
	
	IF @Site = 'CN88'
		EXEC CS_CustomerCheckExists @username = @newname, @Mode = 0, @IsExists = @IsExists OUTPUT	
	ELSE
		EXEC Age_CustomerCheckExists @username = @newname, @IsExists = @IsExists OUTPUT	

	if	@custid IS NOT NULL AND @newname <> '' AND @IsExists = 0
	BEGIN
		--CHECK an account disabled or not 
		EXEC dbo.Acc_CustomerSelCheckEnable @username = @oldname, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output 
		if @ErrCode <>0	 return	
		
		SET @roleid = (SELECT c.roleid FROM Customer c WITH(NOLOCK) WHERE c.custid = @custid)
		
		IF @roleid = 4
		BEGIN
			SELECT @GroupName = GroupName
			FROM Acc_CustGroup WITH(NOLOCK)
			WHERE custid = @custid
				AND GroupName IN ('ACCUT','ACCYEN789','ACCYEN889','ACCTEST')	--789y
			
			IF ISNULL(@GroupName,'') <> ''
				AND NOT EXISTS(SELECT 1 FROM Acc_SuperPrefix WITH(NOLOCK)
							WHERE GroupName = @GroupName
								AND prefix = LEFT(@newname,2)
								AND AllowNewSuper = 1
					)
			BEGIN
				SELECT @ErrMsg =' The new username does not follow its external group prefix.', 
						@ErrCode = 110
				RETURN		
			END
		END
		
		BEGIN TRANSACTION
			UPDATE customer WITH (ROWLOCK, UPDLOCK) SET username = @newname WHERE custid = @custid
			IF (@@error <> 0)
			BEGIN
				ROLLBACK TRANSACTION
				SELECT @ErrMsg ='Update username does not successfully.', @ErrCode = 100
				RETURN
			END
			UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET username = @newname WHERE custid = @custid
			IF (@@error <> 0)
			BEGIN
				ROLLBACK TRANSACTION
				SELECT @ErrMsg ='Update username does not successfully.', @ErrCode = 100
				RETURN
			END
		COMMIT TRANSACTION
		
		BEGIN TRY	
			IF (@roleid > 4)
				EXEC DBPRO.bodb02.dbo.Dot_Admin_AccountRename_Update @oldname, @newname, @custid, @userid, @roleid
		END TRY
		BEGIN CATCH
			UPDATE customer WITH (ROWLOCK, UPDLOCK) SET username = @oldname WHERE custid = @custid
			UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET username = @oldname WHERE custid = @custid
				
			select @ErrMsg = 'Update username does not successfully.' + @ErrMsg
			RETURN
		END CATCH		
	END
	ELSE
	BEGIN	
		IF @oldname = @newname
			SELECT @ErrMsg = 'An error occurs. New username and old username are the same!', @ErrCode = 101
		ELSE
			SELECT @ErrMsg = 'An error occurs. The user does not exist or new username is not available: ['+ @oldname + '] - ['+@newname+']', @ErrCode = 102		
		RETURN
	END

	EXEC [DBCRM].[bodb_CRM].[dbo].[Acc_CRM_CustomerUpdUsername]
					@NewUsername = @newname,
					@CustID		 = @CustID,	
					@UserID		 = @UserID,
					@IP			 = @IP,
					@ErrCode	 = @ErrCode OUTPUT,
					@ErrMsg		 = @ErrMsg OUTPUT
	IF @ErrCode <> 0
		BEGIN
			SET @ErrMsg = 'Update username does not successfully. ' + @ErrMsg
			--- manually rollback
			UPDATE customer WITH (ROWLOCK, UPDLOCK) SET username = @oldname WHERE custid = @custid
			UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET username = @oldname WHERE custid = @custid

			RETURN
		END

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)
	declare @LogSPData nvarchar(1000)

	Select @LogSPData = '<Acc_CustomerUpdUserName  FromName="' + @oldname + '" ToName="' + @newname + '" ' +
						'userid="'+ coalesce(cast(@userid as varchar(50)),space(1))+ '" ' +
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+ '" ' +
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1))+ '" ' +
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" />'
	/*605 Acc_CustomerUpdUserName Change username */
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 605,
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY
	BEGIN CATCH
		Select @LogSPData = '<Acc_CustomerUpdUserName  FromName="' + @oldname + '" ToName="' + @newname + '" ' +
						'userid="'+ coalesce(cast(@userid as varchar(50)),space(1))+ '" ' +
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+ '" ' +
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1))+ '" ' +
						'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(400)),space(1))+'" />'
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 605,
			@TrackingValue = @LogSPData,
			@duration = @duration
	END CATCH

	SELECT @ReturnCustId = @custid
END
GO


