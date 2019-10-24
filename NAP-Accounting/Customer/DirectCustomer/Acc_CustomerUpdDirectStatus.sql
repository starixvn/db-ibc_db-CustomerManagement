/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdDirectStatus]
(
    @custid  	INT
  , @creator    INT
  , @IP         VARCHAR(20) = ''
  , @ErrCode    INT = 0 OUTPUT
  , @ErrMsg	    NVARCHAR(200) = '' OUTPUT
)
AS
/*
	Created: 
	Task : Marking an account as Direct Account
	DB: DBCUST/CustDB
	Original: 

	Revisions:		
		- 20140523@Logan: Initial version.
		- 20170420@Helen:  Add Extra information for Direct Accounts, for NAP only - [Redmine:72339]
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
		- 20171113@Helen: Support to add default TO setting for new direct customers - [Redmine:86052]
		- 20181107@Louis: Credit Collection [Redmine: #98621]
		- 20200114@Malcolm: Separate setting and notification into Live/Non-Live and bettypes [Redmine : 125076]
		- 20191024@Eden: Hofix - removed dummy acc from table CustDirectAccount [Redmine:83206]

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
    
    DECLARE @CreateDate DATETIME
	SET @CreateDate = GETDATE()

    --Checking if the account is markable or not
    DECLARE @upline INT = 0
          , @roleid TINYINT
          , @srecommend INT
          , @mrecommend INT
		  , @recommend INT	
    SELECT @upline = CASE roleid 
                       WHEN 1 THEN recommend
                       WHEN 2 THEN mrecommend
                       WHEN 3 THEN srecommend
                     END
         , @roleid = roleid
         , @srecommend = srecommend
         , @mrecommend = mrecommend
         , @recommend = recommend
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
	INSERT INTO CustDirectAccount (CustID, Coll_Status)
	SELECT C.custid, NULL AS Coll_Status
	FROM @affectedList C 

	--> Rmove upline from CustDirectAccount
	DELETE CustDirectAccount WITH(ROWLOCK,UPDlOCK)
	WHERE custid = @upline
	
	EXEC dbo.Acc_CreditCollStatusInit @custid = @custid, @UserId = @creator, @IP = @IP
	
	-- TO Control: Send Email
	IF @roleid IN (2,3,4)
	BEGIN
		
		INSERT INTO dbo.EmailNotification (NotificationInfo, CreatedDate, ActionID)
		
		SELECT '<NewDirectCustomer  custid="'+ COALESCE(CAST(CustID AS VARCHAR(300)), SPACE(1)) + '" />'  AS NotificationInfo
				, @CreateDate AS CreatedDate
				
				, CASE	WHEN @roleid = 4 THEN 600
						WHEN @roleid = 3 THEN 601
						WHEN @roleid = 2 THEN 602
				  END AS ActionID		
										
		FROM @affectedList
		 
		INSERT INTO dbo.TOControl_GlobalSetting (CustID, MaxTurnOver, Sporttype, IsGroupHeadLine, ProfileID)
		SELECT al.custid
				-- Since there are many kinds of currency default setting, default setting will be converted to RM before convert to orginal curency
				, CASE 
						-- currency RM in default Setting
						WHEN TO_tmp.TOCurrency = 2 THEN CONVERT(MONEY,TO_tmp.MaxTurnOver / E1.actualrate) 
						-- NOT currency RM in default Setting
						ELSE  CONVERT(MONEY,(TO_tmp.MaxTurnOver * E.actualrate)/E1.actualrate)
				END AS MaxTurnOver
				, TO_tmp.Sporttype, 0, TO_tmp.ProfileID
        
		FROM @affectedList al
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON al.custid = c.custid 
			CROSS APPLY 
			(        
				-- Soccer 
				SELECT TOP 10 f1.sporttype, f1.MaxTurnOver,f1.TOCurrency, f1.ProfileID
				FROM dbo.f_TOControl_GlobalSettingSel () f1                
				WHERE f1.site IN (c.site,'') AND f1.ExchangeID IN (c.currency,0) AND f1.sporttype = 1        
				ORDER BY f1.site DESC, f1.ExchangeID DESC                
                
				UNION ALL
				-- Others sport
				SELECT TOP 10 sporttype, MaxTurnOver,TOCurrency, f2.ProfileID
				FROM dbo.f_TOControl_GlobalSettingSel () f2                
				WHERE f2.site IN (c.site,'') AND f2.ExchangeID IN (c.currency,0) AND f2.sporttype = 99
				ORDER BY f2.site DESC, f2.ExchangeID DESC
				) AS TO_tmp
                        
			INNER JOIN dbo.Exchange e WITH (NOLOCK) ON e.ExchangeID = TO_tmp.TOCurrency
			INNER JOIN dbo.Exchange e1 WITH (NOLOCK) ON e1.ExchangeID = c.currency
		WHERE c.roleid IN (2,3,4) 
			AND NOT EXISTS (SELECT 1 FROM dbo.TOControl_GlobalSetting gs WITH (NOLOCK) 
							WHERE gs.custid =  al.custid AND gs.Sporttype =  TO_tmp.sporttype AND gs.IsGroupHeadLine = 0)	
									
	END
	
	IF @roleid = 3
	BEGIN
		DELETE TOControl_GlobalSetting
		WHERE CustID = @srecommend
		
		DELETE TOControl_Setting
		WHERE CustID = @srecommend
	END
	ELSE IF @roleid = 2
	BEGIN
		DELETE TOControl_GlobalSetting
		WHERE CustID IN (@srecommend,@mrecommend)
		
		DELETE TOControl_Setting
		WHERE CustID IN (@srecommend,@mrecommend)
	END
	ELSE IF @roleid = 1
	BEGIN
			DELETE dbo.TOControl_GlobalSetting
			WHERE CustID IN (@srecommend,@mrecommend,@recommend)
			
			DELETE dbo.TOControl_Setting
			WHERE CustID IN (@srecommend,@mrecommend,@recommend)
	END
		
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
 GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDirectStatus] TO [bodbAdminNet]
GO 
