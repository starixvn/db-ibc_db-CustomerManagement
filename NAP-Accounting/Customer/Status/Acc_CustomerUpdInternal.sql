ALTER PROCEDURE [dbo].[Acc_CustomerUpdInternal]	
	@CustID int,	
	@UserID int,	
	@IsInternal bit,	
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IP varchar(15) = ''
AS

/*
	Created:
	Task : Update customer to Internal or Betting user
	DB: DBTXN/bodb02
	Original:

	Revisions:
		- 20080828@Shifu: Update Internal status for customer	
		- 20090917@Phuc: Write log to dblog	
		- 20091008@Kiwi: Remove WriteLog_UserLog
		-20100107@Lewin: Change format LogSPData, call new writelog sp
		- 20101021@Henry: Record execution time
		- 20130307@Lukas: change linked-server alias & add more write log section
	Param's Explanation:
	• @ErrCode:
		= 0: Transaction recorded successfully.
		> 0: Specific Error.
	    
	• @ErrMsg: Error description.
*/
SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()


EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end
DECLARE @roleid tinyint, @Old_IsInternal bit, @UplineIsInternal bit, @uplineid int 
SELECT @roleid = roleid, @uplineid = CASE roleid WHEN 4 THEN custid	WHEN 3 THEN srecommend WHEN 2 THEN mrecommend ELSE recommend END			 
FROM custinfo WITH (nolock)
WHERE custid = @custid

IF @RoleID is null OR @roleid NOT IN (2,3,4)
BEGIN
	SELECT @ErrMsg = N'Invalid user!!',	@ErrCode = 100	
	RETURN
END

--Get Internal status
SELECT @Old_IsInternal = CASE @roleid WHEN 4 THEN (SELECT isnull(IsInternal, 0) FROM custSuper WITH (NOLOCK) WHERE custid = @custid)
								  WHEN 3 THEN (SELECT isnull(IsInternal, 0) FROM custMaster WITH (NOLOCK) WHERE custid = @custid)
								  WHEN 2 THEN (SELECT isnull(IsInternal, 0) FROM custAgent WITH (NOLOCK) WHERE custid = @custid 		)								  
								  ELSE 0 END 	


IF @Old_IsInternal = @IsInternal 
	RETURN

--Parent Internal Status
SELECT @UplineIsInternal = CASE @roleid WHEN 3 THEN (SELECT isnull(IsInternal, 0) FROM custSuper WITH (NOLOCK) WHERE custid = @uplineid)
										WHEN 2 THEN (SELECT isnull(IsInternal, 0) FROM custMaster WITH (NOLOCK) WHERE custid = @uplineid)								  
										ELSE 0 END 

IF @UplineIsInternal = 1
BEGIN
	SELECT @ErrMsg =  N'Upline is Internal User. Cannot change status.', @ErrCode = 105
	RETURN
END 


IF(@RoleID = 4)
BEGIN
	Update CustSuper WITH(ROWLOCK,UPDLOCK) Set IsInternal = @IsInternal WHERE CustID = @CustID
END
ELSE IF(@RoleID = 3)
BEGIN
	Update CustMaster WITH(ROWLOCK,UPDLOCK) Set IsInternal = @IsInternal WHERE CustID = @CustID
END
ELSE
BEGIN
	Update CustAgent WITH(ROWLOCK,UPDLOCK) Set IsInternal = @IsInternal WHERE CustID = @CustID
END

IF (@@error <> 0)
BEGIN
	SELECT @ErrMsg = N'Update process is unsuccessful !', @ErrCode = 101
	RETURN
END

IF @roleid = 4
BEGIN
	UPDATE custMaster WITH (ROWLOCK, UPDLOCK) SET IsInternal = @IsInternal WHERE custid IN (SELECT custid FROM custinfo WITH (NOLOCK) WHERE srecommend = @custid and roleid = 3)
	IF (@@error <> 0)
	BEGIN
		SELECT @ErrMsg = N'Update process is unsuccessful !', @ErrCode = 102
	RETURN
	END
	
	UPDATE custAgent WITH (ROWLOCK, UPDLOCK) SET IsInternal = @IsInternal WHERE custid IN (SELECT custid FROM custinfo WITH (NOLOCK) WHERE srecommend = @custid and roleid = 2)
	IF (@@error <> 0)
	BEGIN
		SELECT @ErrMsg = N'Update process is unsuccessful !', @ErrCode = 102
	RETURN
	END
END

ELSE IF @roleid = 3
BEGIN
	UPDATE custAgent WITH (ROWLOCK, UPDLOCK) SET IsInternal = @IsInternal WHERE custid IN (SELECT custid FROM custinfo WITH (NOLOCK) WHERE mrecommend = @custid and roleid = 2)
	IF (@@error <> 0)
	BEGIN
		SELECT @ErrMsg = N'Update process is unsuccessful !', @ErrCode = 102
	RETURN
	END
END



declare @LogSPData varchar(1000)

Select @LogSPData = '<Acc_CustomerUpdInternal Custid="'+ coalesce(cast(@CustID as varchar(50)),space(1))+'" '+
					'IsInternal="'+ coalesce(cast(@IsInternal as varchar(50)),space(1)) + '" '+
					'Userid="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
					'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" '+
					'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

/*1112 Acc_CustomerUpdInternal Update Account type */
BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 1112,
		@TrackingValue = @LogSPData,
		@duration = @duration
END TRY
BEGIN CATCH
	Select @LogSPData = '<Acc_CustomerUpdInternal Custid="'+ coalesce(cast(@CustID as varchar(50)),space(1))+'" '+
					'IsInternal="'+ coalesce(cast(@IsInternal as varchar(50)),space(1)) + '" '+
					'Userid="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
					'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(400)),space(1))+'" '+
					'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 1112,
		@TrackingValue = @LogSPData,
		@duration = @duration
END CATCH


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdInternal] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdInternal] TO [vnTeam]