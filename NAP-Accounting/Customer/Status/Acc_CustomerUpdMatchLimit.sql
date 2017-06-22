ALTER PROCEDURE [dbo].[Acc_CustomerUpdMatchLimit]
	@custid int,
	@matchlimit smallmoney,
	@UserID int,
	@ReturnErrCode bit = 0,
	@IP varchar(20) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

SET NOCOUNT ON
/*	Created by: [Creator]
	DB: DBTXN/BODB02
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]	
		- 20091008@Kiwi: Remove WriteLog_UserLog	
		- 20100106@Lewin: Replace @LogSPData	
		- 20100813@Shifu: Change function name to check permission [MaxExposure] for [OtherCust]
		- 20101021@Henry: Record execution time
		- 20110603@Amy: Write log Old value
		- 20110907@Sophia: Change Linked Server from DB052 to DB053
		- 20120917@Elodie: Correct content of log
		- 20130307@Lukas: change linked-server alias & add more write log section
		- 20150606@Elodie: Separate CustDB to DBCUST server (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB)
*/

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

DECLARE @Old_matchlimit smallmoney

--Check permission for account site: @phuc20080213
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[MaxExposure]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output

If @ErrCode <> 0
BEGIN
	IF @ReturnErrCode = 0
		RAISERROR (@ErrMsg, 16, 1)
	RETURN
END
--end
--Check disable user
	EXEC Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
--end
declare @roleid int
if @matchlimit >1 or @matchlimit<0
BEGIN
	select @ErrMsg = 'Invalid credit per match value', @ErrCode = 101
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

select @roleid = roleid, @Old_matchlimit=matchlimit from custinfo with (NOLOCK) where custid = @custid

select @matchlimit = round(@matchlimit, 2)

IF @Old_matchlimit = @matchlimit RETURN

if @roleid = 4
BEGIN
	update custinfo with (ROWLOCK, UPDLOCK) set matchlimit = @matchlimit
	where srecommend = @custid
END
else if @roleid = 3
BEGIN
	update custinfo with (ROWLOCK, UPDLOCK) set matchlimit = @matchlimit
	where mrecommend = @custid
END
else if @roleid = 2
BEGIN
	update custinfo with (ROWLOCK, UPDLOCK) set matchlimit = @matchlimit
	where recommend = @custid
END

DECLARE @LogSPData VARCHAR(300)
DECLARE @TrackingValue2 VARCHAR(300)

SELECT @LogSPData = '<Acc_CustomerUpdMatchLimit CustID="' + convert(varchar(20), @CustID) 
					+ '" MatchLimit ="' + convert(varchar(20), @matchlimit) 
					+ '" UserId="' + convert(varchar(20), @UserID)
					+ '" IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
					
SELECT @TrackingValue2 = '<Acc_CustomerUpdMatchLimit CustID="' + convert(varchar(20), @CustID) 
					+ '" MatchLimit ="' + convert(varchar(20), @Old_matchlimit) 
					+ '" UserId="' + convert(varchar(20), @UserID)
					+ '" IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

/*800 Acc_CustomerUpdMatchLimit Update Max Exposure (%) */
BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 800,
		@TrackingValue = @LogSPData	,
		@TrackingValue2 = @TrackingValue2,
		@duration = @duration
END TRY
BEGIN CATCH
	SELECT @LogSPData = '<Acc_CustomerUpdMatchLimit CustID="' + convert(varchar(20), @CustID) 
					+ '" MatchLimit ="' + convert(varchar(20), @matchlimit) 
					+ '" UserId="' + convert(varchar(20), @UserID)
					+ '" IP="'+ coalesce(cast(@IP as varchar(15)),space(1))
					+ '" ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(400)),space(1)) +'" />'
	SELECT @TrackingValue2 = '<Acc_CustomerUpdMatchLimit CustID="' + convert(varchar(20), @CustID) 
						+ '" MatchLimit ="' + convert(varchar(20), @Old_matchlimit) 
						+ '" UserId="' + convert(varchar(20), @UserID)
						+ '" IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
						+ '" ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(400)),space(1)) +'" />'
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 800,
		@TrackingValue = @LogSPData	,
		@TrackingValue2 = @TrackingValue2,
		@duration = @duration
END CATCH


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMatchLimit] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMatchLimit] TO [vnteam]
