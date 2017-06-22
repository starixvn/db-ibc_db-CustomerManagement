ALTER PROCEDURE [dbo].[Acc_CustomerUpdSelectedBetting]	
	@CustID int,		
	@SelectedBetting bit,	
	@RemoveDownlines bit = 0,
	@UserID int,
	@IP varchar(20) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
	
AS

/*
Created: 20101015@Henry
Task : Update Selected Betting
DB: DBTXN/bodb02
Original:

Revisions:
   - 20101021@Henry: Record execution time
   - 20110603@Amy: Write log Old value
   - 20130310@Lukas: change linked-server alias & add more log section
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
    
• @ErrMsg: Error description.
* @RemoveDownlines: 
	* if @SelectedBetting = 0 and if @RemoveDownlines = 0 then keep the limitation at downline 
	* if @SelectedBetting = 0 and if @RemoveDownlines = 1 then Remove the limitation for all the downlines

*/
SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int
declare @isWritelog bit
set @startRun = getdate()
set @isWritelog = 1


EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end


DECLARE @roleid tinyint
DECLARE @OldSelectedBetting bit
DECLARE @UplineSelectedBetting bit

SELECT @roleid = roleid FROM custinfo WITH (nolock)
WHERE custid = @custid

IF @RoleID is null OR @roleid NOT IN (2,3,4)
BEGIN
	SELECT @ErrMsg = N'Invalid user!!',	@ErrCode = 100	
	RETURN
END

IF @roleid = 4 --super
BEGIN
	SELECT @OldSelectedBetting = SelectedBetting FROM CustSuper WITH (NOLOCK)
	WHERE custid = @custid
	
	IF @OldSelectedBetting <> @SelectedBetting
	BEGIN
		Update CustSuper WITH(ROWLOCK,UPDLOCK) 
		Set SelectedBetting = @SelectedBetting
		WHERE 
			custid = @custid
			
		IF (@@error <> 0)
		BEGIN
			SELECT @ErrMsg = N'Update process is unsuccessful !', @ErrCode = 101
			RETURN
		END	
	END

	

	IF (@SelectedBetting = 1 OR (@SelectedBetting = 0 AND @RemoveDownlines = 1)) 
	BEGIN
		Update CustMaster WITH(ROWLOCK,UPDLOCK) SET SelectedBetting = @SelectedBetting
		WHERE 
		custid IN (
					SELECT mrecommend FROM custinfo WITH (nolock)  
					WHERE 
						srecommend = @custid 
						AND roleid = 3
				  )
		
		IF (@@error <> 0)
		BEGIN
			SELECT @ErrMsg = N'Update process is unsuccessful !', @ErrCode = 102
			RETURN
		END

		Update CustAgent WITH(ROWLOCK,UPDLOCK) SET SelectedBetting = @SelectedBetting
		WHERE 
		custid IN (
					SELECT recommend FROM custinfo WITH (nolock)  
					WHERE 
						srecommend = @custid 
						AND roleid = 2
				  )
				  
		IF (@@error <> 0)
		BEGIN
			SELECT @ErrMsg = N'Update process is unsuccessful !', @ErrCode = 103
			RETURN
		END
	END
END

ELSE IF @roleid = 3 --master
BEGIN
	SELECT @OldSelectedBetting = SelectedBetting FROM CustMaster WITH (NOLOCK)
	WHERE custid = @custid

	--Check upline SelectedBetting
	SELECT @UplineSelectedBetting = SelectedBetting From CustSuper WITH (NOLOCK)
	Where custid = ( Select srecommend From custinfo WITH (nolock) WHERE custid = @custid and roleid = 3)
	

	IF @OldSelectedBetting <> @SelectedBetting and isnull(@UplineSelectedBetting,0) = 0
	BEGIN
		Update CustMaster WITH(ROWLOCK,UPDLOCK) 
		Set SelectedBetting = @SelectedBetting
		WHERE custid = @custid
		IF (@@error <> 0)
		BEGIN
			SELECT @ErrMsg = N'Update process is unsuccessful !', @ErrCode = 101
			RETURN
		END
	END		
	
	IF ((@SelectedBetting = 1 OR (@SelectedBetting = 0 AND @RemoveDownlines = 1)) and isnull(@UplineSelectedBetting,0) = 0  )
	BEGIN
		Update CustAgent WITH(ROWLOCK,UPDLOCK) SET SelectedBetting = @SelectedBetting
		WHERE 
		custid IN (
					SELECT  recommend FROM custinfo WITH (nolock)  
					WHERE 
						mrecommend = @custid 
						AND roleid = 2
				  )
				  
		IF (@@error <> 0)
		BEGIN
			SELECT @ErrMsg = N'Update process is unsuccessful !', @ErrCode = 102
			RETURN
		END
	END	
	
	IF isnull(@UplineSelectedBetting,0) <> 0
	BEGIN
		SET @isWritelog = 0
	END
END
ELSE IF @roleid = 2 --agent
BEGIN
	SELECT @OldSelectedBetting = SelectedBetting FROM CustAgent WITH (NOLOCK)
	WHERE custid = @custid

	--Check upline SelectedBetting
	SELECT @UplineSelectedBetting = SelectedBetting From CustMaster WITH (NOLOCK)
	Where custid = ( Select mrecommend From custinfo WITH (nolock) WHERE custid = @custid and roleid = 2)

	IF @OldSelectedBetting <> @SelectedBetting and isnull(@UplineSelectedBetting,0) = 0
	BEGIN
		Update CustAgent WITH(ROWLOCK,UPDLOCK) 
		Set SelectedBetting = @SelectedBetting
		WHERE custid = @custid
		IF (@@error <> 0)
		BEGIN
			SELECT @ErrMsg = N'Update process is unsuccessful !', @ErrCode = 101
			RETURN
		END	
	END
	
	IF isnull(@UplineSelectedBetting,0) <> 0
	BEGIN
		SET @isWritelog = 0
	END
END

IF  @isWritelog = 1
BEGIN
	declare @LogSPData varchar(1000)
	declare @TrackingValue2 varchar(1000)
	
	Select @LogSPData = '<Acc_CustomerUpdSelectedBetting Custid="'+ coalesce(cast(@CustID as varchar(50)),space(1))+'" '+
						'SelectedBetting="'+ coalesce(cast(@SelectedBetting as varchar(50)),space(1)) + '" '+
						'RemoveDownlines="'+ coalesce(cast(@RemoveDownlines as varchar(50)),space(1)) + '" '+
						'Userid="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" '+
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
						
	Select @TrackingValue2 = '<Acc_CustomerUpdSelectedBetting Custid="'+ coalesce(cast(@CustID as varchar(50)),space(1))+'" '+
						'SelectedBetting="'+ coalesce(cast(@OldSelectedBetting as varchar(50)),space(1)) + '" '+
						'RemoveDownlines="'+ coalesce(cast(@RemoveDownlines as varchar(50)),space(1)) + '" '+
						'Userid="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" '+
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)
	BEGIN TRY	
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 1124,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END TRY
	BEGIN CATCH
		Select @LogSPData = '<Acc_CustomerUpdSelectedBetting Custid="'+ coalesce(cast(@CustID as varchar(50)),space(1))+'" '+
						'SelectedBetting="'+ coalesce(cast(@SelectedBetting as varchar(50)),space(1)) + '" '+
						'RemoveDownlines="'+ coalesce(cast(@RemoveDownlines as varchar(50)),space(1)) + '" '+
						'Userid="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
						'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(400)),space(1))+'" '+
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
						
		Select @TrackingValue2 = '<Acc_CustomerUpdSelectedBetting Custid="'+ coalesce(cast(@CustID as varchar(50)),space(1))+'" '+
						'SelectedBetting="'+ coalesce(cast(@OldSelectedBetting as varchar(50)),space(1)) + '" '+
						'RemoveDownlines="'+ coalesce(cast(@RemoveDownlines as varchar(50)),space(1)) + '" '+
						'Userid="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
						'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(400)),space(1))+'" '+
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 1124,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END CATCH
END


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSelectedBetting] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdSelectedBetting] TO [vnTeam] 