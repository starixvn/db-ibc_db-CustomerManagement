/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_CustSubDel	
	@subaccid INT, 
	@CustId INT, 
	@Language VARCHAR(2) = 'E',
	@LoginIP VARCHAR(20)='',
	@UserID INT=0,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20190715
	Task : Delete sub-account for agent of CN88
	DB: DBCUST/CustDB

	Revisions:    
		- 20190715@Elodie: Initial SP [Redmine:#110497]

	Param's Explanation:
		• @ErrCode:
			= 0: Delete successfully.
			> 0: Specific Error.
  
		• @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX)

	SET @startRun = GETDATE()

	UPDATE cs 
	SET cs.IsDeleted = 1
	FROM dbo.custSub cs 
	WHERE subaccid = @subaccid AND CustId = @CustId

	EXEC DBMSG.bodb_Message.dbo.Age_MsgCustReadStatus_Del @custid, @subaccid
	
	IF @ErrCode <> 0
	BEGIN
		--Delete sub-account failed. Please try again.
		SELECT @ErrMsg = [dbo].[f_Get_MsgNamebyMsgID](40048, @Language), @ErrCode = 106
		-- ROLLBACK MANUALLY
		UPDATE cs SET cs.IsDeleted = 0 FROM dbo.custSub cs WHERE subaccid = @subaccid AND CustId = @CustId
		RETURN
	END

	--Write log
	Select @LogSPData =	'<R subaccid="'+ COALESCE(CAST(@SubAccID as VARCHAR(30)),SPACE(1)) + '" ' +
						'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

	EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper 
		@UserID = @UserID, 
		@CustID = @CustId,
		@ActionID = 691,
		@TrackingValue = @LogSPData,
		@duration = @duration	
END	
GO

