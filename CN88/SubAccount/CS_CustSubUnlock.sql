/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/

CREATE PROCEDURE [dbo].[CS_CustSubUnlock]  
    @custid INT,  
    @subaccid INT,  
    @IP VARCHAR(20) = '',  
    @Language VARCHAR(2) = 'E',  
    @ErrCode INT = 0 OUTPUT,  
    @ErrMsg nVARCHAR(4000) = '' OUTPUT  
AS  
/*  
    Created: 20190520@Kan  
    Task : Unlock sub account  
    DB: DBCUST/CustDB  
  
    Revisions:       
        - 20190520@Kan: Initial SP [Redmine:#112287]  
		- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]

    Param's Explanation:  
*/  
BEGIN  
    SET NOCOUNT ON  
  
    IF EXISTS (SELECT 1 FROM [dbo].custSub WITH (NOLOCK) WHERE subaccid = @subaccid AND custid = @custid AND closed = 1)  
    BEGIN  
        UPDATE [dbo].custSub WITH (ROWLOCK)    
        SET closed = 0  
        WHERE subaccid = @subaccid AND custid = @custid  
  
        --- Error return    
        IF @@error <> 0  
        BEGIN  
            SET @ErrCode = 105  
            RETURN  
        END  
  
        --- Write log    
        DECLARE @LogSPData NVARCHAR(4000)  
        SELECT @LogSPData = '<CS_CustSubUnlock CustID="' + COALESCE(CAST(@custid AS VARCHAR(50)), SPACE(1)) + '" '  
            + 'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@subaccid) as VARCHAR(30)), SPACE(1)) + '" ' +  
            + 'Closed="0" '  
            + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(30)), SPACE(1)) + '" '     
            + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" '     
            + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'  
        EXEC [dbo].CS_WriteLog_UserLog_RunSP_Wrapper  
            @UserID = @custid,  
            @CustID = @custid,  
            @ActionID = 691,  
            @TrackingValue = @LogSPData  
    END  
END  