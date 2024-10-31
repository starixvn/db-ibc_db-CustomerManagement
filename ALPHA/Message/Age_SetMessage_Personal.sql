/*<info serverAlias="DBMSG-bodb_Message" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_SetMessage_Personal]
	@CustList		NVARCHAR(MAX)
	,@Content_en	NVARCHAR(4000)=NULL
	,@Content_cs	NVARCHAR(4000)=NULL
	,@Content_ch	NVARCHAR(4000)=NULL
	,@Content_th	NVARCHAR(4000)=NULL
	,@Content_vn	NVARCHAR(4000)=NULL
	,@IsTest		BIT = 0
AS
/*
	Created: 20241002@Tacy
    Task: Alpha - Add personal message
    DB: DBMSG-bodb_Message

	Revisions:
		- 20241002@Tacy: Send personal message for upline when account has synced into NovaCasino [RedmineID: #211405]

	Param's Explanation:
		- @MsgContentsType: to identify normal message or changed settings message
				= 0 ~ Normal Data
				= 100 ~ msg from CRM site
				= 109 ~ msg from CWL
				= 110 ~ msg from NAP CM - Manage Domain

		- @CustList:
				[
					{"custid":73270241,"username":"supertestMSG02"},
					{"custid":73247076,"username":"SupertestME0100"}
				]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	@MessageId	INT
			,@CustID	INT
			,@Username	VARCHAR(30)

	CREATE TABLE #tbSMA (
		custid INT PRIMARY KEY, 
		UserName VARCHAR(30),
		IsFinished BIT DEFAULT(0)
	)

	INSERT INTO #tbSMA(custid, UserName)
	SELECT DISTINCT custid, username 
	FROM OPENJSON(@CustList) WITH (
		custid		INT			'$.CustId',
		username	VARCHAR(30)	'$.Username' 
	)
	WHERE ISJSON(@CustList) = 1

	IF NOT EXISTS (SELECT TOP 1 1 FROM #tbSMA)
		RETURN

	IF @Content_en = NULL AND @Content_cs = NULL AND @Content_ch = NULL
		AND @Content_th	= NULL AND @Content_vn = NULL
		RETURN

	SELECT @Content_cs	= ISNULL (@Content_cs,@Content_en)
		, @Content_ch	= ISNULL (@Content_ch,@Content_en)
		, @Content_th	= ISNULL (@Content_th,@Content_en)
		, @Content_vn	= ISNULL (@Content_vn,@Content_en)

	--Insert Msg
	EXEC Age_Msg_SetMessage 
				@Content_en=@Content_en,
				@Content_ch=@Content_ch,
				@Content_cs=@Content_cs,
				@Content_jp=@Content_en,
				@Content_th=@Content_th,
				@Content_ko=@Content_en,
				@Content_vn=@Content_vn,
				@CreatorName='starixIT',
				@IsTest=@IsTest,
				@MsgType=1,
				@IsBatch=0,
				@MsgContentsType=0,
				@MessageIDOutput=@MessageId OUTPUT

	WHILE (1=1)
	BEGIN
		SELECT @CustID=NULL, @Username=NULL

		UPDATE TOP (1) #tbSMA 
		SET @CustID=CustID, @Username=Username
			,IsFinished=1
		WHERE IsFinished=0

		IF @CustID=NULL OR @Username=NULL
			OR @@ROWCOUNT = 0 
			BREAK

		--Insert MsgTarget
		EXEC Age_Msg_SetUsrMessage @MessageId=@MessageId,@TargetId=@CustID,@TargetName=@Username
	END
END
GO