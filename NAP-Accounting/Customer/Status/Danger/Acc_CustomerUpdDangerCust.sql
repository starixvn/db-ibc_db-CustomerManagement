/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_CustomerUpdDangercust]
	@CustID int,
	@UpdateDownline bit = 0,
	@DangerType tinyint,
	@DangerLevel int=0,
	@UserID int,
	@Language varchar(2) = 'E',
	@isBA INT=0 OUTPUT,
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
	- 20191015@Johnson: check permission [PossessStatistics_CN88_DangerLevel] when update from NAP CM [redmine: #117714]
Param's Explanation:
	@CustID: Id of member will be updated,
	@DangerType: type of danger,
	@DangerLevel: new danger level value,
*/		
BEGIN
	SET NOCOUNT ON
	declare @startRun datetime
	declare @endRun datetime
	declare @duration int, @roleid int
	set @startRun = getdate()

	--Check permission for account site: @phuc20080213
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	
	If @ErrCode <> 0
	BEGIN
		EXEC NAP_UserControl.dbo.NAP_User_CheckPermission @UserId=@userid,@SiteKey='CustomerManagement',@FunctionKey='PossessStatistics_CN88_DangerLevel',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
		IF @ErrCode <> 0
			RETURN
	END
	--end

	--Check disable user
	EXEC Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
	--end
	
	select @roleid = roleid from custinfo (nolock) where custid = @custid
	
	IF @roleid NOT IN (1,2,3,4)
	BEGIN	
		Select @ErrMsg = 'Invalid user!!',
			@ErrCode = 101	
		return	
	END
	
	DECLARE @dangerfield AS VARCHAR(10)
	DECLARE @oldvalue AS VARCHAR(10)
	DECLARE @BAMemberAg VARCHAR(MAX) = ''
	
	IF (@DangerType=1)
	BEGIN 
		SET @oldvalue=(Select Danger from custInfo (NOLOCK) where custid=@CustID)
		SET @dangerfield='Danger'
		
		IF @updateDownline = 1 
		BEGIN
			IF @roleid = 2
			BEGIN
				SELECT BAMemberAg = CAST(lb.CustID AS VARCHAR(15)) +',' 
				FROM bodb_Licensee.dbo.LicenseeBAHistory lb WITH (NOLOCK)
					INNER JOIN custinfo ci WITH (NOLOCK)  ON lb.CustID=ci.CustID
				WHERE lb.Status='Running' 
					AND ci.recommend=@custid
			END
			ELSE IF @roleid = 3
			BEGIN
				SELECT BAMemberAg = CAST(lb.CustID AS VARCHAR(15)) +',' 
				FROM bodb_Licensee.dbo.LicenseeBAHistory lb WITH (NOLOCK)
					INNER JOIN custinfo ci WITH (NOLOCK)  ON lb.CustID=ci.CustID
				WHERE lb.Status='Running' 
					AND ci.mrecommend=@custid
			END
			ELSE IF @roleid = 4
			BEGIN
				SELECT BAMemberAg = CAST(lb.CustID AS VARCHAR(15)) +',' 
				FROM bodb_Licensee.dbo.LicenseeBAHistory lb WITH (NOLOCK)
					INNER JOIN custinfo ci WITH (NOLOCK)  ON lb.CustID=ci.CustID
				WHERE lb.Status='Running' 
					AND ci.srecommend=@custid
			END	
		END	
	END
	ELSE IF (@DangerType=2)
	BEGIN 
		SET @oldvalue=(Select Danger2 from custInfo (NOLOCK) where custid=@CustID)
		SET @dangerfield='Danger2'
	END	
	ELSE IF (@DangerType=3)
	BEGIN 
		SET @oldvalue=(Select Danger3 from custInfo (NOLOCK) where custid=@CustID)
		SET @dangerfield='Danger3'
	END		
		
	IF @roleid > 1 AND @updateDownline = 1 
	BEGIN
		EXEC Acc_CustomerInfo_Execrep_03
			@custid	= @custid,		
			@roleid = @roleid,			
			@DangerType = @DangerType,		
			@DangerLevel = @DangerLevel,	
			@BAMemberAg = @BAMemberAg,		 
			@mode = 'DangerStatus'
	END
	ELSE
	BEGIN
		IF (@DangerType=1)
		BEGIN
			IF EXISTS (
				 SELECT 1 FROM bodb_Licensee.dbo.LicenseeBAHistory lb WITH (NOLOCK)
				 WHERE custid=@custid AND status='running'
				)
				SET @isBA=1
			ELSE
				SET @isBA=0
			IF(@isBA=1 AND @DangerLevel =0)
				BEGIN
					SELECT @DangerLevel=100
				END	
				
			UPDATE custInfo with (UPDLOCK,ROWLOCK)
			SET Danger = @DangerLevel 
			WHERE custid = @custid
		END
		ELSE IF @DangerType= 2
		BEGIN
			UPDATE custInfo with (UPDLOCK,ROWLOCK)
			SET Danger2 = @DangerLevel 
			WHERE custid = @custid
		END
		ELSE IF @DangerType= 3
		BEGIN
			UPDATE custInfo with (UPDLOCK,ROWLOCK)
			SET Danger3 = @DangerLevel 
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
END
GO
