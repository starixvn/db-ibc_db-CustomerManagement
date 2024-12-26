/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE dbo.Acc_WhiteLabelSetting_UpdGroup
	-- Add the parameters for the stored procedure here
	 @CustIDList	VARCHAR(200)
	,@GroupID		INT 
	,@UserID		INT
	,@IP			VARCHAR(20)		= ''
	,@ErrCode		INT				= 0	 OUTPUT
	,@ErrMsg		NVARCHAR(4000)	= '' OUTPUT
AS
/*
	Created: Tacy
	Task: NAP - CreditTerm - Move group headline and update WhiteLabelInfo
	DB: DBCUST-CUSTDB

	Revisions:
		- 20240910@Tacy: Create SP [Redmine: #209807]

	Param's Explanation:
*/
--Update: GroupID for WhiteLabel
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @LogData NVARCHAR(MAX), @LogDataOld NVARCHAR(MAX)

	DECLARE   @Today	DATETIME
			, @startRun DATETIME
			, @duration INT
			, @CustID	INT
			
	DECLARE @tmpWhiteLabel TABLE (CustID INT PRIMARY KEY)
	DECLARE @tmpWhiteLabel_out TABLE (CustID INT PRIMARY KEY, FromDate DATETIME)

	SELECT	@startRun = GETDATE()
			,@Today = CONVERT(DATE,GETDATE())

	INSERT INTO @tmpWhiteLabel (CustID)
	SELECT wi.CustID
	FROM WhiteLabelInfo wi WITH (NOLOCK)
	INNER JOIN Customer c WITH (NOLOCK) ON c.custid=wi.CustID
	WHERE EXISTS 
		(SELECT 1 FROM STRING_SPLIT(@CustIDList, ',')
			WHERE CAST(value as int) IN (c.custid, c.recommend, c.mrecommend, c.srecommend))
	
	WHILE (1=1)
	BEGIN
		SELECT TOP 1 @CustID=CustID
		FROM @tmpWhiteLabel

		IF @@ROWCOUNT=0
			BREAK
		

		SELECT  @LogDataOld = (SELECT wi.CustID, wi.WhiteLabel
									, ISNULL(ws.GroupID,0) AS GroupID
									, COALESCE (CAST (@IP AS VARCHAR(20)), SPACE (1)) AS IP
								FROM WhiteLabelInfo wi WITH (NOLOCK)
									CROSS APPLY (SELECT TOP 1 a.GroupID 
												 FROM WhiteLabelSetting a WITH (NOLOCK) 
												 WHERE a.CustID=wi.CustID AND a.ToDate > @Today
												) ws
								WHERE wi.CustID=@CustID
								FOR XML RAW('Acc_WhiteLabelSetting_UpdGroup')
							) 

		--End setting, but have updating within a day
		IF EXISTS (SELECT TOP 1 1 FROM WhiteLabelSetting ws WITH (NOLOCK)
					WHERE ws.CustID=@CustID
						AND FromDate = DATEADD(DAY,1,@Today)
						AND ToDate > @Today)
		BEGIN
			UPDATE ws
			SET ws.GroupID=@GroupID
				,ws.HeadlineRate=CASE WHEN @GroupID=0 THEN 0 ELSE ws.HeadlineRate END 
				,ws.RepUpdateTime=dbo.f_GetDateTime2()
			FROM WhiteLabelSetting ws WITH (ROWLOCK, UPDLOCK)
			WHERE ws.CustID=@CustID
				AND FromDate = DATEADD(DAY,1,@Today)
				AND ToDate > @Today
		END
		ELSE IF EXISTS (SELECT TOP 1 1 FROM WhiteLabelSetting ws WITH (NOLOCK)
						WHERE ws.CustID=@CustID	AND ToDate > @Today)
		BEGIN
			UPDATE ws
			SET ws.ToDate=@Today
				,ws.RepUpdateTime=dbo.f_GetDateTime2()
			OUTPUT inserted.CustID, inserted.FromDate INTO @tmpWhiteLabel_out (CustID,FromDate)
			FROM WhiteLabelSetting ws WITH (ROWLOCK, UPDLOCK)
			WHERE ws.CustID=@CustID	AND ToDate > @Today

			INSERT INTO WhiteLabelSetting (GroupID, CustID, AgentRate, MasterRate, SuperRate, HeadlineRate, FromDate, Remark, RepUpdateTime)
			SELECT @GroupID, ws.CustID, AgentRate, MasterRate, SuperRate
				, HeadlineRate=CASE WHEN @GroupID=0 THEN 0 ELSE ws.HeadlineRate END 
				, DATEADD(DAY, 1, @Today), Remark, dbo.f_GetDateTime2()
			FROM WhiteLabelSetting ws WITH (NOLOCK)
			INNER JOIN  @tmpWhiteLabel_out t ON t.CustID=ws.CustID AND t.FromDate=ws.FromDate
		END

		--Writelog
		SELECT  @LogData = (SELECT wi.CustID, wi.WhiteLabel
								, CONVERT(VARCHAR(10), @GroupID) AS GroupID
								, COALESCE (CAST (@IP AS VARCHAR(20)), SPACE (1)) AS IP
							FROM WhiteLabelInfo wi WITH (NOLOCK) 
							WHERE wi.CustID=@CustID
							FOR XML RAW('Acc_WhiteLabelSetting_UpdGroup')
							) 

		SELECT	@duration = DATEDIFF(MILLISECOND, @startRun, GETDATE())

		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper 
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 712,
			@TrackingValue = @LogData,
			@TrackingValue2 = @LogDataOld,
			@duration = @Duration

		DELETE FROM @tmpWhiteLabel WHERE CustID=@CustID
		DELETE FROM @tmpWhiteLabel_out WHERE CustID=@CustID
		
		SELECT	@startRun = GETDATE()
	END
END