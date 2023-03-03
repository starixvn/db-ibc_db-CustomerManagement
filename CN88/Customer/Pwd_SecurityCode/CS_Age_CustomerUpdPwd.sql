/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,bodbExtAccNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CS_Age_CustomerUpdPwd]
    @CustID INT ,
    @UserPwd NVARCHAR(50) ,
    @UserID INT ,
    @DisCasino BIT = 0 ,
    @Language VARCHAR(2) = 'E' ,
    @SubAccID INT = 0 , --Sub-AccountID
    @LoginIP VARCHAR(20) = '' ,
    @ErrCode INT = 0 OUTPUT , --default no error
    @ErrMsg NVARCHAR(500) = '' OUTPUT
AS 
/*
Created: 20190326@Johnson
Task : Reset password for his downlines
DB: DBCust/Custdb
Original: Age_CustomerUpdPwd

Revisions:
    - 20190326@Johnson: clone new sp for cn88 alpha [redmine: #105660]
	- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]
	- 20230302@Tacy: Demo - CN88 Site

Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
BEGIN
    SET NOCOUNT ON
    
	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()
--Check disable user
    EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid,
        @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
    IF @ErrCode <> 0 
        RETURN
--end

    DECLARE  @ErrLog NVARCHAR(50)
			,@PwdExpiry DATETIME
			,@OldPwd	VARCHAR(40)
			,@roleid 	TINYINT
    
    --IF ( @DisCasino = 1
    --     AND EXISTS ( SELECT    1
    --                  FROM      CustInfo WITH ( NOLOCK )
    --                  WHERE     SyncCasino = 1
    --                            AND Custid = @CustID )
    --   ) 
    --    BEGIN
    --        SELECT  @ErrMsg = CASE @Language
    --                            WHEN 'E' THEN 'This CHANGED PASSWORD function is temporarily unavailable, please update later.'
    --                            ELSE [dbo].[f_Get_MsgNamebyMsgID](40022,@Language)
    --                          END ,
    --                @ErrCode = 100
    --        RETURN
    --    END
    
    IF EXISTS (SELECT 1 FROM custSub WITH(NOLOCK) WHERE custid = @custid AND subaccID = @SubAccID)
	 BEGIN
            SELECT  @ErrMsg ='You dont have permission to do this action.',
                    @ErrCode = 101
            RETURN
        END	
	
	IF @UserID <> @CustID AND CURRENT_USER <> 'bodbAdminNet' AND EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE custid = @CustID AND LockUpd = 1 AND roleid = 1)
	BEGIN
		 SELECT  @ErrMsg = CASE @Language
                                WHEN 'E' THEN 'You are currently not authorized to perform this action. Please contact the Customer Service Department for further assistance.'
                                ELSE [dbo].[f_Get_MsgNamebyMsgID](40033,@Language)
                              END ,
                 @ErrCode = 102
         RETURN
	END
	
	SELECT	@OldPwd	= userpwd, @roleid = roleid
	FROM	Customer WITH (NOLOCK) 
	WHERE	custid = @CustID
	
	SELECT @pwdexpiry = dbo.f_CS_GetPwdExpiryDate(@roleid)
	
    UPDATE  customer WITH (ROWLOCK, UPDLOCK)
    SET     userpwd = @UserPwd ,
            pwdexpiry = @PwdExpiry
    WHERE   custid = @CustID
    
    UPDATE	CustLoginInfo WITH (ROWLOCK, UPDLOCK)
    SET		OldUserPwd			= @OldPwd
			,LastChangedPwdDate = GETDATE()
	WHERE	custid = @CustID

    DECLARE @LogData NVARCHAR(4000)

    SELECT  @LogData = '<CS_Age_CustomerUpdPwd  UserID="' + CONVERT(VARCHAR(20), @CustID)
            + '" IP="' + @LoginIP +'" '
---------------------------
-- ***Check Sub-Account***
    IF @SubAccID > 0 
        BEGIN
            SET @LogData =  @LogData + 'SubAccount="' + dbo.f_GetSubUsername(@SubAccID) + '"'
                
        END
---------------------------
	SET @LogData = @LogData + ' />'
	
	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)
	
	EXEC CS_WriteLog_UserLog_RunSP_Wrapper
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 938,
		@TrackingValue = @LogData	,
		@duration = @duration
END
GO