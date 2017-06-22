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
SET NOCOUNT ON
/*
Created: 
Task : Update Danger, Danger2, Danger3 fields , and write log content
DB: DBTXN/bodb02
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
	
Param's Explanation:
	@CustID: Id of member will be updated,
	@DangerType: type of danger,
	@DangerLevel: new danger level value,
*/		

declare @startRun datetime
declare @endRun datetime
declare @duration int, @roleid int
set @startRun = getdate()

--Check permission for account site: @phuc20080213
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

--Check disable user
EXEC Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end

if exists (select 1 from customer (NOLOCK) where custid = @CustID)
BEGIN
select @roleid = roleid from custinfo (nolock) where custid = @custid

declare @dangerfield as varchar(10)
declare @oldvalue as varchar(10)

if (@DangerType=1)
	Begin 
		set @oldvalue=(Select Danger from custInfo (NOLOCK) where custid=@CustID)
		/*
		IF CAST(ISNULL(@oldvalue,'0') AS INT) = 100
		BEGIN
			Select @ErrMsg = 'Could not update because this is Licensee BA Member!',
				@ErrCode = 102	
			return	
		END
		*/
		
			if @roleid = 2 and @updateDownline = 1 
				BEGIN
					DECLARE @BAMemberAg AS TABLE (CustID INT  PRIMARY KEY)
					INSERT INTO @BAMemberAg 
					SELECT lb.CustID FROM DBLIC.bodb_Licensee.dbo.LicenseeBAHistory lb WITH (NOLOCK)
					INNER JOIN custinfo ci WITH (NOLOCK)  ON lb.CustID=ci.CustID
					WHERE lb.Status='Running' 
					AND ci.recommend=@custid
					BEGIN
						IF(@DangerLevel<>0)
							BEGIN
								update custinfo with(UPDLOCK,ROWLOCK)
								set Danger = @DangerLevel
								where recommend= @custid
							END
						ELSE
							BEGIN
								update custinfo with(UPDLOCK,ROWLOCK)
								set Danger = @DangerLevel
								where recommend= @custid
								and custid not in (select custid from @BAMemberAg)
								update custinfo with(UPDLOCK,ROWLOCK)
								set Danger = 100
								where recommend= @custid
								and custid  in (select custid from @BAMemberAg)
							END
							
					END
				END
			else
			BEGIN
				IF EXISTS (
					 SELECT 1 FROM DBLIC.bodb_Licensee.dbo.LicenseeBAHistory lb WITH (NOLOCK)
					 WHERE custid=@custid AND status='running'
					)
					SET @isBA=1
				ELSE
					SET @isBA=0
				IF(@isBA=1 AND @DangerLevel =0)
					BEGIN
						SELECT @DangerLevel=100
					END	
				update custInfo with (UPDLOCK,ROWLOCK)
				set Danger = @DangerLevel 
				where custid = @custid
			END	
			set @dangerfield='Danger'
		
	end
if (@DangerType=2)
	Begin 
		set @oldvalue=(Select Danger2 from custInfo (NOLOCK) where custid=@CustID)
		if @roleid = 2 and @updateDownline = 1 
		BEGIN
			update custinfo with(UPDLOCK,ROWLOCK)
			set Danger2 = @DangerLevel
			where recommend= @custid
		END
		else
		BEGIN
			update custInfo with (UPDLOCK,ROWLOCK)
			set Danger2 = @DangerLevel 
			where custid = @custid
		END
		
		set @dangerfield='Danger2'
	end
if (@DangerType=3)
	Begin 
		set @oldvalue=(Select Danger3 from custInfo (NOLOCK) where custid=@CustID)
		if @roleid = 2 and @updateDownline = 1 
		BEGIN
			update custinfo with(UPDLOCK,ROWLOCK)
			set Danger3 = @DangerLevel
			where recommend= @custid
		END
		else
		BEGIN
			update custInfo with (UPDLOCK,ROWLOCK)set 
				Danger3 = @DangerLevel 
			where custid = @custid
		END
		
		set @dangerfield='Danger3'
	end
		
END
else
BEGIN	
	Select @ErrMsg = 'Invalid user!!',
		@ErrCode = 101	
	return	
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



BEGIN TRY
    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	    @UserID = @UserID,
	    @CustID = @CustID,
	    @ActionID = 1114,
	    @TrackingValue = @LogSPData,
	    @duration = @duration
END TRY
BEGIN CATCH
    EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	    @UserID = @UserID,
	    @CustID = @CustID,
	    @ActionID = 1114,
	    @TrackingValue = @LogSPData,
	    @duration = @duration
END CATCH



GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDangercust] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdDangercust] TO [vnteam]