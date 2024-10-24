/*<info serverAlias="DBGLOB-GLOBCUSTDB" executers="wsv_nap,wsv_alp,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerInsNickName_Register]
(
	 @custid	INT
	,@Nickname	VARCHAR(50) = NULL
	,@Language	VARCHAR(2)= 'E'
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
)
AS
/*
	Created: 20240704@Louisa
	Task : Validate Create member Lite Mode
	DB: DBCUST/CustDB

	Revision:
		- 20240704@Louisa: Scaleout DBCUST [Redmine:#199915]
		
*/	
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Username2 VARCHAR(50)
	SELECT @Username2 = ISNULL(Username2,'') FROM CustInfoMini WITH (NOLOCK) WHERE CustID = @CustID

	IF @Username2 =''
	BEGIN TRY

		IF EXISTS(SELECT 1 FROM CustInfoMini WITH(NOLOCK) WHERE username = @Nickname)
		OR EXISTS (SELECT 1 FROM CustInfoMini WITH (NOLOCK) WHERE username2 = @Nickname)
		OR EXISTS(SELECT 1 FROM CustSubMini WITH (NOLOCK) WHERE username = @Nickname)
		OR EXISTS(SELECT 1 FROM CustSubMini WITH (NOLOCK) WHERE username2 = @Nickname)
		BEGIN 
			SELECT  @ErrMsg = CASE @language
								  WHEN 'E' THEN 'Nickname is not available'
								  ELSE [dbo].[f_Get_MsgNamebyMsgID](40006,@Language)
								END ,
					@ErrCode = 102
			RETURN
		END  
		
		UPDATE  CustInfoMini WITH (ROWLOCK)
		SET     Username2 = @Nickname, RepUpdateTime = SYSDATETIME()
		WHERE   custid = @custid and ISNULL(Username2,'') = ''

	END TRY
    BEGIN CATCH
        SELECT  @ErrMsg = CASE @language
                                WHEN 'E' THEN 'Failed to create username. Please try again.'
                                ELSE [dbo].[f_Get_MsgNamebyMsgID](40007,@Language)
                            END ,
                @ErrCode = 105 
        RETURN
    END CATCH
END
GO

