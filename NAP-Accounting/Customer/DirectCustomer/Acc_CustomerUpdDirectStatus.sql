/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdDirectStatus]
    @custid  	INT
  , @creator    INT
  , @IP         VARCHAR(20) = ''
  , @ErrCode    INT = 0 OUTPUT
  , @ErrMsg	    NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 
	Task : Marking an account as Direct Account
	DB: DBCUST/CustDB
	Original: 

	Revisions:		
		- 20140523@Logan: Initial version.
		- 20170420@Helen:  Add Extra information for Direct Accounts, for NAP only - [Redmine:72339]
		
    Param's Explanation:
    • @ErrCode:
        = 0:  Successful update.
        > 0:  Specific Error.
      
    • @ErrMsg: Error description.
		
*/
BEGIN
    SET NOCOUNT ON

    DECLARE @startRun DATETIME
          , @endRun   DATETIME
          , @duration INT
          , @existed  BIT  
    SET @startRun = getdate()

    --Checking if the account is markable or not
    DECLARE @upline INT = 0
          , @roleid TINYINT

    SELECT @upline = CASE roleid 
                       WHEN 1 THEN recommend
                       WHEN 2 THEN mrecommend
                       WHEN 3 THEN srecommend
                     END
         , @roleid = roleid
      FROM dbo.custInfo WITH(NOLOCK)
     WHERE custid = @custid
    
    EXEC DBACC.bodb02.dbo.Acc_CustMarkDirectCheckEnable
        @custid = @custid
      , @roleid = @roleid
      , @ErrCode = @ErrCode OUTPUT
      , @ErrMsg = @ErrMsg OUTPUT

    IF @ErrCode <> 0
        RETURN

    SELECT @existed = 1
      FROM dbo.Acc_CustDirect WITH(NOLOCK)
     WHERE custid = @upline
       AND roleid = @roleid + 1

    IF @@ROWCOUNT > 0
        RETURN

    INSERT INTO dbo.Acc_CustDirect(custid, roleid)
    VALUES(@upline, @roleid + 1)

    IF @@ERROR <> 0
    BEGIN
        SELECT @ErrMsg = 'Insert process is unsuccessful.',
		       @ErrCode = 103
	    RETURN
    END
    
    DECLARE @affectedList TABLE
    (
        custid INT
    )
    
    INSERT INTO @affectedList(custid)
    EXEC dbo.Acc_CustDirectListAffected
        @custid = @custid
      , @mode = 1
	
	--[72339]:Add Extra information for Direct Accounts
	INSERT INTO CustDirectAccount (CustID)
	SELECT C.custid
	FROM @affectedList C 
	
	--DELETE dbo.CustDirectAccount WHERE CustID = @upline
		
    DECLARE @affCust INT
    
    SELECT @affCust = MIN(custid)
    FROM @affectedList

    WHILE @affCust IS NOT NULL
    BEGIN
        SET @endRun = GETDATE()

        SET @duration  = DATEDIFF(MILLISECOND, @startRun, @endRun)

        --Log Update Action		
        DECLARE @LogSPData VARCHAR(8000)

        SELECT @LogSPData = '<Acc_CustomerUpdDirectStatus CustID="' + COALESCE(CAST(@affCust AS VARCHAR(50)), SPACE(1)) + '" ' +
                            'RoleID="' + COALESCE(CAST(@roleid AS VARCHAR(2)), SPACE(1)) + '" ' +
                            'DirectUplineCustID="' + COALESCE(CAST(@upline AS VARCHAR(50)), SPACE(1)) + '" ' +
					        'UserID="' + COALESCE(CAST(@creator AS VARCHAR(50)), SPACE(1)) + '" ' +
					        'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' +
                            'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' +
						    'ErrMsg="'+ COALESCE(CAST(@ErrMsg AS VARCHAR(4000)), SPACE(1)) + '" />'
        BEGIN TRY
	        EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		        @UserID = @creator,
		        @CustID = @affCust,
		        @ActionID = 1151,
		        @TrackingValue = @LogSPData,
		        @duration = @duration
        END TRY
        	
        BEGIN CATCH
	        SELECT @LogSPData = '<Acc_CustomerUpdDirectStatus custid="' + COALESCE(CAST(@affCust AS VARCHAR(50)), SPACE(1)) + '" ' +
					            'RoleID="' + COALESCE(CAST(@roleid AS VARCHAR(2)), SPACE(1)) + '" ' +
                                'DirectUplineCustID="' + COALESCE(CAST(@upline AS VARCHAR(50)), SPACE(1)) + '" ' +
                                'UserID="' + COALESCE(CAST(@creator AS VARCHAR(50)), SPACE(1)) + '" ' +
					            'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)),SPACE(1)) + '" ' +
						        'ErrCode="'+ COALESCE(CAST(ERROR_NUMBER() AS VARCHAR(50)), SPACE(1)) + '" ' +
						        'ErrMsg="'+ COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(4000)), SPACE(1)) + '" />'
        	
	        EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		        @UserID = @creator,
		        @CustID = @affCust,
		        @ActionID = 1151,
		        @TrackingValue = @LogSPData,
		        @duration = @duration		
        END CATCH

        DELETE @affectedList
         WHERE custid = @affCust

        SELECT @affCust = MIN(custid)
        FROM @affectedList
    END
END


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdDirectStatus] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDirectStatus] TO [bodbAdminNet]
GO 
