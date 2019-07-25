/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_SubAccManagementUpd	
	@subaccid INT, 
	@CustId INT,
	@RoleId TINYINT,
	@IsAllDownline BIT, 
	@DownlineId VARCHAR(MAX) = '',
	@Language VARCHAR(2) = 'E',
	@LoginIP VARCHAR(20)='',
	@UserID INT=0,
	@IsUpdated BIT = 0 OUTPUT,
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
	DECLARE @AddList VARCHAR(MAX) ='', @RemoveList VARCHAR(MAX)='', @Old_IsAllDownline BIT
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX)
	SET @startRun = GETDATE()	
	SELECT @IsUpdated = 0

	IF ISNULL(@DownlineId,'') = '' AND @IsAllDownline = 0
	BEGIN
		--You do not have any Managed Accounts selected.Please select a Managed Account or select"All"
		SELECT @ErrMsg = [dbo].[f_Get_MsgNamebyMsgID](40050, @Language), @ErrCode = 107
		RETURN
	END

	IF ISNULL(@DownlineId,'') <> ''
	BEGIN
		INSERT INTO #Downlines(CustID)
		SELECT CONVERT(INT, Val)
		FROM dbo.f_StringSplit(@DownlineId, ',')
		OPTION(MAXRECURSION 0)
	
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
									)))

		BEGIN
			--Action failed. Please try again.
			SELECT @ErrMsg = [dbo].[f_Get_MsgNamebyMsgID](40049, @Language), @ErrCode = 106
			RETURN
		END	
	END

	SELECT @Old_IsAllDownline = IsAllDownline FROM dbo.CustSub WITH (NOLOCK) WHERE SubAccId = @subaccid

	IF @Old_IsAllDownline <> @IsAllDownline
	BEGIN
		UPDATE s 
		SET s.IsAllDownline = @IsAllDownline
		FROM dbo.custSub s WITH (ROWLOCK)
		WHERE subaccid = @subaccid

		IF @IsAllDownline = 1
		BEGIN
			 DELETE FROM dbo.CS_SubAccManagement WITH (ROWLOCK) WHERE SubAccId = @subaccid
		END

		SELECT @IsUpdated = 1
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

	SELECT @AddList = STUFF((SELECT ',' + ci.username
							FROM #AddAcc t
								INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.custid = t.CustId
							FOR XML PATH('')), 1, 1, '')

	SELECT @RemoveList = STUFF((SELECT ',' + ci.username
							FROM #RemoveAcc t
								INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.custid = t.CustId
							FOR XML PATH('')), 1, 1, '')

	IF ISNULL(@AddList,'') <> '' OR ISNULL(@RemoveList,'') <> ''
	BEGIN
		INSERT INTO dbo.CS_SubAccManagement (SubAccId, DownlineId)
		SELECT @subaccid, CustId
		FROM #AddAcc

		DELETE s 
		FROM dbo.CS_SubAccManagement s 
			INNER JOIN #RemoveAcc r ON s.DownlineId = r.CustId
		WHERE SubAccId = @subaccid

		SELECT @IsUpdated = 1
	END

	IF @IsUpdated = 1
	BEGIN
		--Write log
		Select @LogSPData =	'<R SubAcc="'+ COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' +
							'SelectAll="'+ COALESCE(CAST(@IsAllDownline as VARCHAR(1)),SPACE(1)) + '" ' +
							'AddedAccount="'+ COALESCE(CAST(@AddList as VARCHAR(MAX)),SPACE(1)) + '" ' +
							'RemovedAccount="'+ COALESCE(CAST(@RemoveList as VARCHAR(MAX)),SPACE(1)) + '" ' +
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'

		Select @LogSPData2 ='<R SubAcc="'+ COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' +
							'SelectAll="'+ COALESCE(CAST(@Old_IsAllDownline as VARCHAR(1)),SPACE(1)) + '" ' +
							'AddedAccount="'+ COALESCE(CAST(@AddList as VARCHAR(MAX)),SPACE(1)) + '" ' +
							'RemovedAccount="'+ COALESCE(CAST(@RemoveList as VARCHAR(MAX)),SPACE(1)) + '" ' +
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'

		SET @endRun = GETDATE()
		SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

		EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper 
			@UserID = @UserID, 
			@CustID = @CustId,
			@ActionID = 693,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @LogSPData2,
			@duration = @duration	
	END
END	
GO

