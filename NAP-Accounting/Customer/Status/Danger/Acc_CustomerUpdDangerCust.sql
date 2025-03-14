/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap, svc_tig" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_CustomerUpdDangercust]
	@CustID int = NULL,
	@Username VARCHAR(30) = '', --Username provided by user
	@UpdateDownline bit = 0,
	@DangerType tinyint,
	@DangerLevel int=0,
	@UserID int,
	@AdName	VARCHAR(30)='', -- UserID's username
	@Permission	VARCHAR(20) = '1,2,3',
	@DeniedList	NVARCHAR(MAX)=NULL,
	@Language varchar(2) = 'E',
	@system VARCHAR(50) = 'NAP',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IP varchar(15) = ''
AS
/*
	Created: 
	Task : Update Danger, Danger2, Danger3 fields , and write log content
	DB: DBCUST/CUSTDB
	Original:Accounting site

	Revisions:	
		- 20090717@pluto: update danger by dangertype.
		- 20090801@Shifu: check disabled user
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]		
		- 20090917@Phuc: Write log to dblog
		- 20091008@Kiwi: Remove WriteLog_UserLog	
		- 20091231@pluto: Writelog old value	
		- 20100102@Lewin: Change @LogSPData, using WriteLog_UserLog_RunSPNew to write log
		- 20101021@Henry: Record execution time
		- 20110506@Johnson: update dangerous status of agent
		- 20110804@Johnson: change name old value when write log
		- 20110829@Henry: not allow Licensee BA Member to be updated
		- 20110907@Sophia: Change Linked Server from DB052 to DB053
		- 20120306@Jim: Edit dangerous level of BA accounts
		- 20130201@Daniel: Change link server alias & failover writelog to DBTXN
		- 20150606@Elodie: Separate CustDB to DBCUST server (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB)
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20180924@Elodie: Migrate bodb_Licensee to DBCUST [Redmine:#99855]
		- 20190925@Johnson: Allow danger status for Super and Master levels [redmine:#120056]
		- 20191015@Johnson: Add param @sytem & check permission [PossessStatistics_CN88_DangerLevel] when update from NAP CM [redmine: #117714]
		- 20200218@Elodie: Prevent update level 41 -> 50 on NAP site [Redmine:#128250]
		- 20200511@Tiara: Enhance validation and error message [Redmine: #129306]
		- 20210820@Johnson: Add 2 new Dangerous types for Basketball & Esports [redmine:#159551]
		- 20211021@Johnson: Auto add & remove ABI Danger Level [redmine:#162834]
		- 20220823@Tacy: update BA member's Danger follow upline [redmine:#176518]
		- 20240816@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
		- 20241024@Johnson: Danger Setting - Update ABI 33/46 to ORI 33/46 [redmineID: #208301]
		- 20241128@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]		
		- 20250314@Virgil: Drop BA functions [RedmineID: #216882]

	Param's Explanation:
		@CustID: Id of member will be updated,
		@DangerType: type of danger,
		@DangerLevel: new danger level value,
		@System: accounting/NAP CM
*/		
BEGIN
	SET NOCOUNT ON
	declare @startRun datetime
	declare @endRun datetime
	declare @duration int, @roleid int
	set @startRun = getdate()
	
	IF @system = 'NAP'
	BEGIN
		EXECUTE dbo.Acc_CustomerCheckDangerCustList
			@UsernameList= @Username ,		
			@UserID = @UserID	,		
			@DangerType	= @DangerType	,	
			@DangerLevel =@DangerLevel	,	
			@IP	=@IP			,	
			@AdName = @AdName,
			@Permission	= @Permission,
			@DeniedList	= @DeniedList,
			@ErrCode = @ErrCode	OUTPUT,
			@ErrMsg = @ErrMsg	OUTPUT	

		IF @ErrCode <> 0
			RETURN
	END

	IF @Username <> ''
	BEGIN
		--Get CustID FROM DB06, WHERE got index on Username AND Username2 
		EXEC @custid = DBACC.bodb02.dbo.f_GetCustIDFromUsername @username
	END

	DECLARE @dangerfield AS VARCHAR(10)
		,@oldvalue AS VARCHAR(10)
		,@dangerfield2 AS VARCHAR(10)
		,@oldvalue2 AS VARCHAR(10)
		,@DangerLevel2 INT 
		,@UpdateDanger2 BIT
				
	--Auto add & remove ABI Danger Level	
	IF @DangerType = 2
	BEGIN
		SELECT @DangerLevel2 = CASE WHEN @DangerLevel= 11 THEN 15 
								 WHEN @DangerLevel= 16 THEN 49 
								 WHEN @DangerLevel IN (30,33,39,46) THEN @DangerLevel 
								 END,
			@UpdateDanger2 = CASE WHEN @DangerLevel IN (11,16,30,33,39,46) THEN 1 ELSE 0 END
	END	
	
	SELECT @roleid = roleid FROM custinfo (NOLOCK) WHERE custid = @CustID

	IF (@DangerType=1)
	BEGIN 
		SET @oldvalue=(Select Danger FROM custInfo (NOLOCK) WHERE custid=@CustID)
		SET @dangerfield='Danger'
	END
	ELSE IF (@DangerType=2)
	BEGIN 
		SELECT @dangerfield='Danger2',
			@dangerfield2= CASE WHEN @DangerLevel IN (11,16) THEN 'Danger4'
								WHEN @DangerLevel IN (30,33,39,46) THEN 'Danger' END
			
		SELECT @oldvalue= Danger2,
			@oldvalue2= CASE WHEN @dangerfield2 = 'Danger4' THEN Danger4
							WHEN @dangerfield2 = 'Danger' THEN Danger END
		FROM custInfo (NOLOCK) 
		WHERE custid=@CustID
		
		
	END	
	ELSE IF (@DangerType=3)
	BEGIN 
		SET @oldvalue=(Select Danger3 from custInfo (NOLOCK) where custid=@CustID)
		SET @dangerfield='Danger3'
	END	
	ELSE IF (@DangerType=4)
	BEGIN 
		SET @oldvalue=(Select Danger4 from custInfo (NOLOCK) where custid=@CustID)
		SET @dangerfield='Danger4'
	END		
	ELSE IF (@DangerType=5)
	BEGIN 
		SET @oldvalue=(Select Danger5 from custInfo (NOLOCK) where custid=@CustID)
		SET @dangerfield='Danger5'
	END	
		
	IF @roleid > 1 AND @updateDownline = 1 
	BEGIN
		EXEC Acc_CustomerInfo_Execrep_03
			@custid	= @custid,		
			@roleid = @roleid,			
			@DangerType = @DangerType,		
			@DangerLevel = @DangerLevel,	
			@mode = 'DangerStatus'
	END
	ELSE
	BEGIN
		IF (@DangerType=1)
		BEGIN
			UPDATE custInfo with (UPDLOCK,ROWLOCK)
			SET Danger = @DangerLevel,
				RepUpdateTime = dbo.f_GetDateTime2()
			WHERE custid = @custid
		END
		ELSE IF @DangerType= 2
		BEGIN
			UPDATE custInfo with (UPDLOCK,ROWLOCK)
			SET Danger2 = @DangerLevel,
				Danger4 = CASE WHEN @DangerLevel = 11 THEN 15
							WHEN @DangerLevel = 16 THEN 49
							ELSE Danger4 END,
				Danger = CASE WHEN @DangerLevel IN (30,33,39,46) THEN @DangerLevel
							ELSE Danger END,
				RepUpdateTime = dbo.f_GetDateTime2()
			WHERE custid = @custid
		END
		ELSE IF @DangerType= 3
		BEGIN
			UPDATE custInfo with (UPDLOCK,ROWLOCK)
			SET Danger3 = @DangerLevel,
				RepUpdateTime = dbo.f_GetDateTime2()
			WHERE custid = @custid
		END
		ELSE IF @DangerType= 4
		BEGIN
			UPDATE custInfo with (UPDLOCK,ROWLOCK)
			SET Danger4 = @DangerLevel,
				RepUpdateTime = dbo.f_GetDateTime2()
			WHERE custid = @custid
		END
		ELSE IF @DangerType= 5
		BEGIN
			UPDATE custInfo with (UPDLOCK,ROWLOCK)
			SET Danger5 = @DangerLevel,
				RepUpdateTime = dbo.f_GetDateTime2()
			WHERE custid = @custid
		END
	END
		
	declare @LogSPData varchar(2000)

	Select @LogSPData = '<Acc_CustomerUpdDangercust CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '"'
						+' ' +  @dangerfield + 'Old="' + coalesce(cast(@oldvalue as varchar(50)),space(1)) + '"' 
						+' ' + @dangerfield + '="'  + coalesce(cast(@DangerLevel as varchar(50)),space(1)) + '"'
						+ ' UpdateDownline="' + coalesce(convert(varchar(1),@UpdateDownline),space(1)) + '"'
						+ ' UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '"'
						+ ' Language= "'+ coalesce(cast(@Language as varchar(2)),space(1))+'"'
						+ ' ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '"'
						+ ' ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'"'
						+ ' IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

	/* 1114	Acc_CustomerUpdDangercust	Update Dangerous status for member*/	

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)



	EXEC Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 1114,
			@TrackingValue = @LogSPData,
			@duration = @duration	
			
	IF ISNULL(@UpdateDanger2,0) = 1
	BEGIN
		Select @LogSPData = '<Acc_CustomerUpdDangercust CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '"'
						+' ' +  @dangerfield2 + 'Old="' + coalesce(cast(@oldvalue2 as varchar(50)),space(1)) + '"' 
						+' ' + @dangerfield2 + '="'  + coalesce(cast(@DangerLevel2 as varchar(50)),space(1)) + '"'
						+ ' UpdateDownline="' + coalesce(convert(varchar(1),@UpdateDownline),space(1)) + '"'
						+ ' UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '"'
						+ ' Language= "'+ coalesce(cast(@Language as varchar(2)),space(1))+'"'
						+ ' ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '"'
						+ ' ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'"'
						+ ' IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

		EXEC Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @UserID,
				@CustID = @CustID,
				@ActionID = 1114,
				@TrackingValue = @LogSPData,
				@duration = @duration	
	END
END
GO
