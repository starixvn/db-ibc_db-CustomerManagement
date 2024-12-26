/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Acc_WhiteLabelSetting_Ins
	-- Add the parameters for the stored procedure here
	 @CustID		INT
	,@WhiteLabel	CHAR(16)	
	,@AgentRate		SMALLMONEY
	,@MasterRate	SMALLMONEY
	,@SuperRate		SMALLMONEY
	,@HeadlineRate	SMALLMONEY
	,@LaunchedDate	DATETIME
	,@Remark		VARCHAR(1000)=NULL
	,@UserID		INT
	,@IP			VARCHAR(50)		= ''
	,@ErrCode		INT				= 0	 OUTPUT
	,@ErrMsg		NVARCHAR(4000)	= '' OUTPUT
AS
/*
	Created: Tacy
	Task: NAP - Configure White Label rate - Insert setting
	DB: DBCUST-CUSTDB

	Revisions:
		- 20240827@Tacy: Create SP [Redmine: #209807]

	Param's Explanation:
*/
BEGIN 
	SET NOCOUNT ON;

	DECLARE @LogData NVARCHAR(MAX)

	DECLARE   @Today	DATETIME
			, @startRun DATETIME
			, @duration INT

	DECLARE @CustHeadlineID INT, @GroupHeadlineID INT

	SELECT	@startRun = GETDATE()
			,@Today = CONVERT(DATE,GETDATE())
			,@LaunchedDate = CONVERT(DATE,@LaunchedDate)
	
	EXEC dbo.Acc_WhiteLabelSetting_Check
		 @Username		= @CustID
		,@CheckCustId	= 1
		,@IsNew			= 1
		,@ErrCode		= @ErrCode	OUTPUT
		,@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN
	
	IF ISNULL(@WhiteLabel,'')=''
	BEGIN
		SELECT @ErrCode=107
			, @ErrMsg='Please input White Label name.'

		RETURN
	END
	
	IF EXISTS (SELECT TOP 1 1 FROM WhiteLabelInfo WITH (NOLOCK)
				WHERE WhiteLabel=@WhiteLabel)
	BEGIN
		SELECT @ErrCode=108
			, @ErrMsg='This White Label name is existed.'

		RETURN

	END

	IF (@LaunchedDate IS NULL)
	BEGIN
		SELECT @ErrCode=109
			, @ErrMsg='Please select Launched Date.'

		RETURN	 
	END

	SELECT @CustHeadlineID = CASE WHEN cda.CustID IS NOT NULL THEN cda.CustID ELSE c.srecommend END
	FROM Customer c WITH (NOLOCK)
	OUTER APPLY (SELECT TOP 1 cda.CustID
						FROM CustDirectAccount cda WITH (NOLOCK)
						WHERE cda.CustID in (c.custid, c.mrecommend, c.srecommend, c.recommend)
						) cda
	WHERE c.custid=@CustID
		
	SELECT @GroupHeadlineID=ca.groupID
	FROM custAccount ca WITH (NOLOCK)
	WHERE ca.custid=@CustHeadlineID AND ca.groupID>0

	BEGIN TRY
		INSERT INTO WhiteLabelInfo (CustID, WhiteLabel, LaunchedDate, RepUpdateTime)
		SELECT @CustID		
			, @WhiteLabel	
			, @LaunchedDate	
			, dbo.f_GetDateTime2()

		INSERT INTO WhiteLabelSetting (GroupID, CustID, AgentRate, MasterRate, SuperRate, HeadlineRate, FromDate, Remark, RepUpdateTime)
		SELECT @GroupHeadlineID, @CustID, @AgentRate, @MasterRate, @SuperRate, @HeadlineRate, @Today, @Remark, dbo.f_GetDateTime2()
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH
	
	--Writelog
	SELECT  @LogData = (SELECT wi.WhiteLabel
								, CONVERT(VARCHAR(50), COALESCE(@GroupHeadlineID,0)) AS GroupID
								, CONVERT(DATE, @LaunchedDate) AS LaunchedDate
								, CONVERT(VARCHAR(50), @AgentRate)	AS AgentRate
								, CONVERT(VARCHAR(50), @MasterRate)	AS MasterRate
								, CONVERT(VARCHAR(50), @SuperRate)	AS SuperRate
								, CONVERT(VARCHAR(50), @HeadlineRate) AS HeadlineRate
								, CONVERT(VARCHAR(50), @Remark)		AS Remark
								, CONVERT(VARCHAR(20), @IP)			AS IP
							FROM WhiteLabelInfo wi WITH (NOLOCK) 
							WHERE wi.CustID=@CustID
							FOR XML RAW('Acc_WhiteLabelSetting_Ins')
						)   

	SELECT	@duration = DATEDIFF(MILLISECOND, @startRun, GETDATE())

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper 
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 710,
		@TrackingValue = @LogData,
		@duration = @Duration	
END
GO