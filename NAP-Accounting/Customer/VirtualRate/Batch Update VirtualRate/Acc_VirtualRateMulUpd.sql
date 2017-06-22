ALTER PROCEDURE [dbo].[Acc_VirtualRateMulUpd]
    @UserID INT ,
    @IP VARCHAR(20) ,
    @FileName VARCHAR(20) ,
    @FileSize INT ,
    @Index INT ,
    @ErrCode INT = 0 OUTPUT ,
    @ErrMsg NVARCHAR(200) = '' OUTPUT
AS /*
	Created: 
	Task : Update new multi virtual rates for username
	DB: DBTXN/CustDB
	Original: 
	Revisions:	
		- 20090812@Simon: Update new multi virtual rates for username
		- 20090910@Jamie: Only update 500 users once 
		- 20090915@Simon: Only update max 500 users once exec this SP
		- 20090917@Phuc: Write log to dblog		
		- 20091116@Daniel: Change to check permission on dedicated function [UploadVR]
		- 20100107@Lewin: Modify @LogSPData, call new writelog function
		- 20101021@Henry: Record execution time
		- 20130224@Lukas: move table Acc_CustVirtualRate to new database bodb_ACC
						& change linked-server from db03 to DBPOLICY
		- 20150126@Johnson: Separate virtual rate setting into sport types and bet types [Redmine: #25840]						
						+ Change to use new structure : table Ac_VirtualRateList				
		- 20151105@Billy: Change to new VirtualRate structure [Redmine: #46541]		 						
							
*/
BEGIN
    SET NOCOUNT ON		
	declare @startRun datetime
	declare @endRun datetime
	declare @duration int

	DECLARE @VirtualRateBitmap BINARY(64),
			@seqNo TINYINT

	set @startRun = getdate()

--Check permission for account site
    EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @UserID,
        @funcname = '[UploadVR]', @ErrCode = @ErrCode OUTPUT,
        @ErrMsg = @ErrMsg OUTPUT
    IF @ErrCode <> 0 
        RETURN
	
    DECLARE @tmpStatus TABLE
        (
          custid INT ,
          username VARCHAR(50)           
        )
	
	DECLARE @tmpCust TABLE(
		custid INT,
		sporttype INT,
		bettype	INT,
		isLive BIT,
		virtualRate SMALLMONEY
	)       

    DECLARE @FromRow INT ,
        @ToRow INT
    SET @FromRow = ( @Index - 1 ) * 100 + 1
    SET @ToRow = @Index *100

    INSERT  INTO @tmpStatus
            ( custid ,
              username             
            )
            SELECT  custid ,
                    username 
            FROM    ( SELECT    ROW_NUMBER() OVER ( ORDER BY t.USERNAME ) IndexRow ,
                                ci.custid ,
                                t.username
                      FROM      custinfo ci WITH ( NOLOCK )
                                INNER JOIN (SELECT DISTINCT username
											FROM DBACC.bodb_Acc.dbo.Acc_VirtualRateList WITH(NOLOCK)
											WHERE userid = @userid											
                                )t ON ci.username = t.username
                    ) Tmp
            WHERE   IndexRow BETWEEN @FromRow AND @ToRow
	
	INSERT INTO @tmpCust(custid, sporttype, bettype, isLive, virtualRate)
	SELECT t.custid, sporttype, bettype, isLive, virtualRate
	FROM DBACC.bodb_Acc.dbo.Acc_VirtualRateList c WITH(NOLOCK) 
		INNER JOIN @tmpStatus t ON c.username = t.username
	
	--enable virtual rate for disabled customers
	UPDATE custinfo WITH(UPDLOCK,ROWLOCK)
	SET virtualmultiplier = 1
	WHERE custid IN (SELECT DISTINCT custid FROM @tmpCust)
		AND virtualmultiplier = 0
	
	-- Update using new Virtual Rate structure
	UPDATE cvs
	SET		bitmapVirtual = (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_multiple(bitmapVirtual, CONVERT(VARCHAR(MAX), virtualXML)))
	FROM		CustVirtualSetting AS cvs WITH(UPDLOCK, ROWLOCK)
	CROSS APPLY (
		SELECT (
			SELECT	(
						SELECT	ipvs.profileID			AS '@p',
								tmp.virtualRate			AS '@v'
						FROM		@tmpCust				AS tmp
						INNER JOIN	ProfileVirtualSetting	AS ipvs WITH(NOLOCK)
								ON	tmp.sporttype	= ipvs.sporttype
								AND tmp.bettype		= ipvs.bettype
								AND tmp.isLive		= ipvs.islive
						WHERE	ipvs.seqNo = cvs.seqNo
							AND tmp.custid = cvs.custid
						FOR XML PATH ('r'), 
						TYPE
					)
			FOR XML PATH ('root'), 
			TYPE
		) AS virtualXML
	) p
	WHERE cvs.custid IN (SELECT DISTINCT custid FROM @tmpCust)
								
	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

    IF @@ERROR <> 0 
    BEGIN
        SELECT  @ErrMsg = 'Update process is unsuccessful. Only updated successfully '
                + CONVERT(VARCHAR(8), @FromRow - 1)
                + ' first rows in list!' ,
                @ErrCode = 103

/*803	Acc_VirtualRateMulUpd_Sum	Sum up users when updating new multi virtual rates*/
        INSERT  INTO DBLOG.bodb_CustomerLog.dbo.UserLog_RunSP
                ( UserID,
                  CustID,
                  TrackingValue,
                  ActionId,
                  duration
                )
        SELECT  @UserID,
                -( @FromRow - 1 ),
                '<Acc_VirtualRateMulUpd_Sum IP="'
                + @IP + '" FileName="' + @FileName
                + '" FileSize="'
                + CONVERT(VARCHAR(20), @FileSize)
                + '" ErrMsg="' + @ErrMsg + '" />',
                803,
                @duration
        RETURN
    END

-- Write Log
/*802	Acc_VirtualRateMulUpd	Update new multi virtual rates*/
	INSERT  INTO DBLOG.bodb_CustomerLog.dbo.UserLog_RunSP
			( UserID,
			  CustID,
			  TrackingValue,
			  ActionID,
			  Duration
			)
    SELECT  @UserID,
            CustID,
            '<Acc_VirtualRateMulUpd UserName="'
            + username + '" IP="' + @IP + '" FileName="'
            + @FileName + '" Size="'
            + CONVERT(VARCHAR(20), @FileSize) + '">'+
            (
				SELECT  SportType
						,BetType
						,IsLive
						,Virtualrate as VirtualMultiplier
				FROM @tmpCust c
				WHERE c.custid = t.custid   
				ORDER BY sporttype,isLive DESC,bettype
				FOR XML  RAW('s')          
            )+'</Acc_VirtualRateMulUpd>',
            802,
            @duration
    FROM    @tmpStatus t
     

    DECLARE @TotalUsers INT
    SELECT  @TotalUsers = COUNT(DISTINCT username)
    FROM    DBACC.bodb_acc.dbo.Acc_CustVirtualRate WITH ( NOLOCK )
    WHERE   userID = @UserID

-- Insert Last Log Row
    IF (@Index * 100 >= @TotalUsers) 
    BEGIN
		set @endRun = getdate()
		set @duration  = datediff (millisecond,@startRun,@endRun)
    
/*803	Acc_VirtualRateMulUpd_Sum	Sum up users when updating new multi virtual rates*/
        
         
         DECLARE @LogData NVARCHAR(200)  
         SET @LogData = '<Acc_VirtualRateMulUpd_Sum TotalUser="'
                + CONVERT(VARCHAR(20), @TotalUsers) + '" IP="'
                + @IP + '" FileName="' + @FileName
                + '" Size="' + CONVERT(VARCHAR(20), @FileSize) + '" />'
         
         SET @TotalUsers = -1 * @TotalUsers
         
         EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
         @UserID = @UserID,
         @CustID = @TotalUsers,
         @ActionID = 803,
         @TrackingValue = @LogData,
         @duration = @duration
         
         
                
    END				
END
	
GO
GRANT EXECUTE ON [dbo].[Acc_VirtualRateMulUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_VirtualRateMulUpd] TO [vnteam]
