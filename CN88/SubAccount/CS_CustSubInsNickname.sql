/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[CS_CustSubInsNickname]  
    @custid INT,  
    @subaccid INT,  
    @Nickname VARCHAR(50) = NULL,  
    @IP VARCHAR(30) = '',  
    @language VARCHAR(2) = 'E' ,  
    @ErrCode INT = 0 OUTPUT,  
    @ErrMsg  NVARCHAR(4000) = '' OUTPUT  
AS  
/*  
    Created: 20190520@Kan  
    Task: Create nickname for sub account and set NicknameLoginOnly = 1  
    DB: DBCust/CustDB  
    
    Revisions:      
        - 20190520@Kan: Initial SP [Redmine:#112287]
        
    Param's Explanation:  
*/  
BEGIN  
    SET NOCOUNT ON  
  
    --- Precondition: Username2 is not assigned  
    IF EXISTS (SELECT 1 FROM [dbo].custSub WITH (NOLOCK) WHERE subaccid = @subaccid AND CustID = @custid AND ISNULL(Username2, '') = '')  
    BEGIN  
        --- Check duplicate Nickname    
        DECLARE @IsExists BIT  
        EXEC [dbo].CS_CustomerCheckExists @username = @Nickname, @Mode = 1, @IsExists = @IsExists OUTPUT  
  
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
        SET @ErrCode = 0  
  SET @ErrMsg = ''  
        DECLARE @Nickname_DB VARCHAR(50)  
        SELECT @Nickname_DB = NickName FROM dbo.f_CS_GetNickName(@Nickname, 1)  
  
        UPDATE [dbo].custSub WITH (ROWLOCK)    
        SET Username2 = @Nickname_DB, NicknameLoginOnly = 1  
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
        SELECT @LogSPData = '<CS_CustSubInsNickname CustID="' + COALESCE(CAST(@custid AS VARCHAR(50)), SPACE(1)) + '" '  
            + 'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@subaccid) as VARCHAR(30)), SPACE(1)) + '" ' +  
            + 'Username2="' + [dbo].f_EncodeXMLValue(COALESCE(CAST(@Nickname_DB AS VARCHAR(50)), SPACE(1))) + '" '    
            + 'NicknameOnly="1" '  
            + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(30)), SPACE(1)) + '" '     
            + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" '     
            + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'  
        EXEC [dbo].Acc_WriteLog_UserLog_RunSP_Wrapper  
            @UserID = @custid,  
            @CustID = @custid,  
            @ActionID = 690,  
            @TrackingValue = @LogSPData  
    END  
END  