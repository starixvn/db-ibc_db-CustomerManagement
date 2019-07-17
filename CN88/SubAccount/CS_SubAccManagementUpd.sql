/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_SubAccManagementUpd	
	@subaccid INT, 
	@CustId INT,
	@DownlineId VARCHAR(MAX),
	@Language VARCHAR(2) = 'E',
	@LoginIP VARCHAR(20)='',
	@UserID INT=0,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20190715
	Task : Manage account on sub account
	DB: DBCUST/CustDB

	Revisions:    
		- 20190715@Elodie: Initial SP [Redmine:#116825]

	Param's Explanation:
		• @ErrCode:
			= 0: Delete successfully.
			> 0: Specific Error.
  
		• @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON
	CREATE TABLE #Downlines (CustId INT)
	CREATE TABLE #AddAcc (CustId INT)
	CREATE TABLE #RemoveAcc (CustId INT)
	DECLARE @AddList VARCHAR(MAX), @RemoveList VARCHAR(MAX), @Roleid TINYINT
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX)
	SET @startRun = GETDATE()

	INSERT INTO #Downlines(CustID)
	SELECT CONVERT(INT, Val)
	FROM dbo.f_StringSplit(@DownlineId, ',')
	OPTION(MAXRECURSION 0)

	SELECT @Roleid = roleid FROM dbo.custInfo WITH (NOLOCK) WHERE custid = @CustId
	IF ((@Roleid = 4 AND EXISTS(SELECT 1 
								FROM dbo.custInfo ci WITH (NOLOCK) 
									INNER JOIN #Downlines d ON d.CustId = ci.custid
								WHERE (ci.srecommend <> @CustId AND ci.roleid = 3) OR ci.roleid <> 3
								))
		OR (@Roleid = 3 AND EXISTS (SELECT 1 
									FROM dbo.custInfo ci WITH (NOLOCK) 
										INNER JOIN #Downlines d ON d.CustId = ci.custid
									WHERE (ci.mrecommend <> @CustId AND ci.roleid = 3) OR ci.roleid <> 2
								))
		OR (@Roleid = 2 AND EXISTS (SELECT 1 
									FROM dbo.custInfo ci WITH (NOLOCK) 
										INNER JOIN #Downlines d ON d.CustId = ci.custid
									WHERE (ci.recommend <> @CustId AND ci.roleid = 3) OR ci.roleid <> 1
								))

	BEGIN
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Delete sub-account failed. Please try again.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40009, @Language) END,
					@ErrCode = 106
		 -- ROLLBACK MANUALLY
			UPDATE cs SET cs.IsDeleted = 0 FROM dbo.custSub cs WHERE subaccid = @subaccid AND CustId = @CustId
			RETURN
	END

	INSERT INTO #AddAcc (CustId) 
	SELECT d.CustId
	FROM #Downlines d WITH (NOLOCK)
	WHERE NOT EXISTS (SELECT 1 FROM dbo.CS_SubAccManagement cs WITH (NOLOCK) WHERE cs.SubAccId = @subaccid AND cs.DownlineId = d.CustId)

	INSERT INTO #RemoveAcc (CustId) 
	SELECT cs.DownlineId
	FROM CS_SubAccManagement cs WITH (NOLOCK)
	WHERE NOT EXISTS (SELECT 1 FROM #Downlines d WITH (NOLOCK) WHERE cs.DownlineId = d.CustId)
		AND cs.SubAccId = @subaccid

	SELECT @AddList = STUFF((SELECT ',' + CAST(custid AS VARCHAR(20))
							FROM #AddAcc
							FOR XML PATH('')), 1, 1, '')

	SELECT @RemoveList = STUFF((SELECT ',' + CAST(custid AS VARCHAR(20))
							FROM #RemoveAcc
							FOR XML PATH('')), 1, 1, '')

	INSERT INTO dbo.CS_SubAccManagement (SubAccId, DownlineId)
	SELECT @subaccid, CustId
	FROM #AddAcc

	DELETE s 
	FROM dbo.CS_SubAccManagement s 
		INNER JOIN #RemoveAcc r ON s.DownlineId = r.CustId
	WHERE SubAccId = @subaccid

	IF @ErrCode <> 0
	BEGIN
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Delete sub-account failed. Please try again.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40009, @Language) END,
					@ErrCode = 106
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

