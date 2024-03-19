/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustSubInsNickname]
    @custid INT,
    @subaccid INT,
    @Nickname VARCHAR(50) = NULL,
    @IP VARCHAR(30) = '',
    @language VARCHAR(2) = 'E' ,
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg  NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20190515@Kan
	Task: Create nickname for sub account
	DB: DBCust/CustDB

	Revisions:    
		- 20190515@Kan: Initial SP [Redmine:#112287]

	Param's Explanation:
*/
BEGIN
    SET NOCOUNT ON

    --- Precondition: Username2 is not assigned
    IF EXISTS (SELECT 1 FROM [dbo].custSub WITH (NOLOCK) WHERE subaccid = @subaccid AND CustID = @custid AND ISNULL(Username2, '') = '')
    BEGIN
        --- Check duplicate Nickname  
        DECLARE @IsExists BIT
        EXEC [dbo].Age_CustomerCheckExists @username = @Nickname, @IsExists = @IsExists OUTPUT

        IF @IsExists = 1  
        BEGIN
            SELECT @ErrMsg =
                CASE @language
                    WHEN 'E' THEN 'Nickname is not available'
                    ELSE [dbo].[f_Get_MsgNamebyMsgID](40006, @Language)
                END,
                @ErrCode = 102
            RETURN
        END

        --- Create Nickname
        UPDATE [dbo].custSub WITH (ROWLOCK)  
        SET Username2 = @Nickname  
        WHERE subaccid = @subaccid AND CustID = @custid AND ISNULL(Username2, '') = ''

        --- Error return  
        IF @@error <> 0
        BEGIN
            SELECT @ErrMsg =
                CASE @language
                    WHEN 'E' THEN 'Failed to create Nickname. Please try again.'
                    ELSE [dbo].[f_Get_MsgNamebyMsgID](40007, @Language)
                END,
                @ErrCode = 105   
            RETURN
        END

        --- Write log Nickname  
        DECLARE @LogSPData NVARCHAR(4000)
        SELECT @LogSPData = '<Age_CustSubInsNickname CustID="' + COALESCE(CAST(@custid AS VARCHAR(50)), SPACE(1)) + '" '
            + 'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@subaccid) as VARCHAR(30)), SPACE(1)) + '" ' +
            + 'Username2="' + [dbo].f_EncodeXMLValue(COALESCE(CAST(@Nickname AS VARCHAR(50)), SPACE(1))) + '" '  
            + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(30)), SPACE(1)) + '" '   
            + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" '   
            + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'
        EXEC [dbo].Acc_WriteLog_UserLog_RunSP_Wrapper
            @UserID = @custid,
            @CustID = @custid,
            @ActionID = 688,
            @TrackingValue = @LogSPData
    END
END
GO
