/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet" viewers="vnteam" isFunction="0"></info>*/
ALTER  PROCEDURE [dbo].[CS_CustomerInsNickName] 
	@custid		INT,
	@Nickname	VARCHAR(50) = NULL,
	@IP			VARCHAR(30) = '',
	@language	VARCHAR(2) = 'E' ,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20190422@Elodie
	Task : Create nickname of CN88's customer
	DB: DBCust/CustDB

	Revisions:    
		- 20190422@Elodie: Initial SP [Redmine:#110497]

	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	-----******* Create Nickname
	DECLARE @Username2 varchar(50), @Nickname_DB VARCHAR(50)

	SELECT @Username2 = ISNULL(Username2,'') FROM Customer WITH (NOLOCK) WHERE CustID = @CustID

	IF @Username2 =''
	BEGIN 
		---Check duplicate Nickname
		DECLARE @IsExists BIT 
		EXEC CS_CustomerCheckExists @username = @Nickname, @Mode = 1, @IsExists = @IsExists OUTPUT		

		IF @IsExists = 1
		BEGIN 
			SELECT  @ErrMsg = CASE @language
								  WHEN 'E' THEN 'Nickname is not available'
								  ELSE [dbo].[f_Get_MsgNamebyMsgID](40006,@Language)
								END ,
					@ErrCode = 102
			RETURN
		END  

		------ Create Nickname
		SET @ErrCode = 0
		SET @ErrMsg = ''
		SELECT @Nickname_DB = NickName FROM dbo.f_CS_GetNickName(@Nickname,1)

		UPDATE  Customer WITH (ROWLOCK)
		SET     Username2 = @Nickname_DB
		WHERE   custid = @custid and ISNULL(Username2,'') = ''
 	
		----Error return
		IF ( @@error <> 0 ) 
		BEGIN
			SELECT  @ErrMsg = CASE @language
									WHEN 'E' THEN 'Failed to create username. Please try again.'
									ELSE [dbo].[f_Get_MsgNamebyMsgID](40007,@Language)
								END ,
					@ErrCode = 105 
			RETURN
		END

		---------- 
		--Write log Nickname
		DECLARE @LogSPData NVARCHAR(4000)

		SELECT  @LogSPData = '<CS_CustomerInsNickName CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" '
							+ 'Username2="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@Nickname_DB AS  VARCHAR(50)), SPACE(1))) + '" '
							+ 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' 
							+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) + '" ' 
							+ 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />' 

		EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @CustID,
			@CustID = @CustID, 
			@ActionID = 687, 
			@TrackingValue = @LogSPData 
	END 
END
