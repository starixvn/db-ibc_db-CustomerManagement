/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_CustSubUpd
	@custid INT,
	@subaccid INT,
	@firstname NVARCHAR(50),
	@PageAccess VARCHAR(50), --[A] or [B]
	@Language VARCHAR(2) = 'E',
	@LoginIP VARCHAR(20)='',
	@UserID INT=0,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20190329
	Task : Update info of sub-account
	DB: DBCust/CustDB

	Revisions:    
		- 20190329@Elodie: Initial SP [Redmine:#110497]

	Param's Explanation:
		• @ErrCode:
			= 0: Update successfully.
			> 0: Specific Error.
  
		• @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON

	IF(EXISTS(SELECT subaccid FROM dbo.custSub WITH(NOLOCK) WHERE subaccid = @subaccid and custid = @custid))
	BEGIN
		DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT
		DECLARE @LogSPData NVARCHAR(MAX), @TrackingValue2 NVARCHAR(MAX)

		SET @startRun = GETDATE()
		
		DECLARE @old_firstname NVARCHAR(50), @Old_PageAccess VARCHAR(50)

		SELECT @old_firstname = firstname, @Old_PageAccess = PageAccess
		FROM custsub  WITH(NOLOCK)
		WHERE subaccid = @subaccid and custid = @custid
		
		IF @old_firstname = @firstname AND @Old_PageAccess = @PageAccess
			RETURN

		UPDATE custsub  WITH(ROWLOCK)
		SET firstname = @firstname,
			PageAccess = @PageAccess
		WHERE subaccid = @subaccid and custid = @custid
		
		---------------------------
		--Write log
		SELECT @LogSPData ='<R SubAccName="'+ COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)),SPACE(1)) + '" ' +
			'fname="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@firstname AS NVARCHAR(50)),SPACE(1))) + '" ' +
			'PageAccess="'+ coalesce(cast(@PageAccess AS VARCHAR(50)),SPACE(1)) + '" ' +
			'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1)) + '" ' +
			'LoginIP="'+ COALESCE(CAST(@LoginIP AS VARCHAR(20)),SPACE(1)) + '" ' +
			'ErrCode="'+ coalesce(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" ' +
			'ErrMsg="'+ COALESCE(CAST(@ErrMsg AS VARCHAR(8000)),SPACE(1)) + '" />'
		
		SELECT @TrackingValue2 ='<R SubAccName="'+ COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)),SPACE(1)) + '" ' +
			'fname="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@old_firstname AS NVARCHAR(50)),SPACE(1))) + '" ' +
			'PageAccess="'+ coalesce(cast(@Old_PageAccess AS VARCHAR(50)),SPACE(1)) + '" ' +
			'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1)) + '" ' +
			'LoginIP="'+ COALESCE(CAST(@LoginIP AS VARCHAR(20)),SPACE(1)) + '" ' +
			'ErrCode="'+ coalesce(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" ' +
			'ErrMsg="'+ COALESCE(CAST(@ErrMsg AS VARCHAR(8000)),SPACE(1)) + '" />'

		SET @endRun = GETDATE()
		SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)	
		
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @UserID, 
			@CustID = @CustID,
			@ActionID = 686,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END
END
GO
