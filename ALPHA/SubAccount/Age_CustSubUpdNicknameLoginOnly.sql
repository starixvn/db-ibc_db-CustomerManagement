/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustSubUpdNicknameLoginOnly]
	@custid INT,
    @subaccid INT,
	@NicknameLoginOnly BIT = 0,
	@IP VARCHAR(30) = '',
	@language VARCHAR(2) = 'E' ,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS

/*
    Created: 20190515@Kan
    Task : Set NicknameLoginOnly for sub account
    DB: DBCUST/CustDB

    Revisions:
        - 20190515@Kan: Initial SP [Redmine:#112287]

    Param's Explanation:
*/
BEGIN
    SET NOCOUNT ON

    UPDATE dbo.custSub WITH (ROWLOCK, UPDLOCK)
    SET NicknameLoginOnly = @NicknameLoginOnly 
    WHERE subaccid = @subaccid AND CustID = @custid

    --- Error return
    IF @@error <> 0
    BEGIN
        SELECT @ErrMsg =
            CASE @language
                WHEN 'E' THEN 'Update process is unsuccessful.'
                ELSE [dbo].[f_Get_MsgNamebyMsgID](90001, @Language)
            END,
            @ErrCode = 106 
        RETURN
    END

    --- Write log NicknameLoginOnly
    DECLARE @LogSPData NVARCHAR(4000)
    SELECT  @LogSPData = '<Age_CustSubUpdNicknameLoginOnly CustID="' + COALESCE(CAST(@custid AS VARCHAR(50)), SPACE(1)) + '" '
        + 'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@subaccid) as VARCHAR(30)), SPACE(1)) + '" ' +
        + 'NicknameOnly="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@NicknameLoginOnly AS VARCHAR(50)), SPACE(1))) + '" '
        + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' 
        + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) + '" ' 
        + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'
    EXEC [dbo].Acc_WriteLog_UserLog_RunSP_Wrapper
        @UserID = @custid,
        @CustID = @custid,
        @ActionID = 689,
        @TrackingValue = @LogSPData
END 
