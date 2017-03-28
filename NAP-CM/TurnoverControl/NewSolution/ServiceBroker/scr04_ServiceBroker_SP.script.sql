/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [sb].[ConversationManagement_Del]
        @FunctionName VARCHAR(100)
    ,    @ContractName VARCHAR(100)    
    ,    @NewCnt INT 
AS
/*
    Create By: Don
    Created Date: 2017-03-22
    Task: Apply Service Broker for Turnover Control function
    DB: DBAGE.bodb02
    
    Para's explaination
*/
BEGIN 
    SET NOCOUNT ON 
                       
    DECLARE @ErrorMessage NVARCHAR(4000) 
          , @ErrorSeverity INT
          , @ErrorState INT
    
    SELECT @ErrorSeverity = 10, @ErrorState = 1                    
    
    SET @ErrorMessage = '=============================================== Begin decrease process ==============================================='
    RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
              );
                              
    UPDATE sb.ConversationCount WITH (ROWLOCK)
        SET Cnt = @NewCnt
    WHERE FunctionName = @FunctionName
      AND ContractName = @ContractName    
    
    SET @ErrorMessage = '=============================================== End decrease process ==============================================='
    RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
              )
    
END
GO

GRANT VIEW DEFINITION ON [sb].[ConversationManagement_Del] TO [vnteam] AS [dbo]
GO
/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Sb].[ConversationManagement_End]
        @FunctionName VARCHAR(100) = 'TOControl'
    ,    @ContractName VARCHAR(200) = ''
AS
/*
    Create By: Don
    Created Date: 2017-03-22
    Task: Apply Service Broker for Turnover Control function
    DB: DBAGE.bodb02
    
    Para's explaination
*/
BEGIN
    SET NOCOUNT ON 

    DECLARE @Conversation_tmp AS TABLE (ID INT IDENTITY(1,1), handle UNIQUEIDENTIFIER)    
    DECLARE @max_conversation INT, @min_Conversation INT = 1, @cnt INT, @handle UNIQUEIDENTIFIER
    
    SELECT @cnt = Cnt
    FROM sb.ConversationCount WITH (NOLOCK)
    WHERE FunctionName = @functionName AND ContractName = @ContractName
    
    INSERT INTO @Conversation_tmp (handle)
    SELECT ConversationHandle
    FROM sb.ConversationManagement WITH (NOLOCK)
    WHERE FunctionName = @functionName AND ContractName = @ContractName AND ConversationNo > @cnt 
    
    IF EXISTS (SELECT 1 FROM @Conversation_tmp)
    BEGIN
        SET @max_conversation = (SELECT MAX(ID) FROM @Conversation_tmp)
        WHILE @min_Conversation <= @max_conversation
        BEGIN
            SELECT @handle = handle
            FROM @Conversation_tmp
            WHERE ID = @min_Conversation
            
            BEGIN TRY
                END CONVERSATION @handle
            END TRY
            
            BEGIN CATCH
                PRINT ' Invalid Handle'
            END CATCH
            SET @min_Conversation = @min_Conversation + 1
        END
        
        DELETE FROM sb.ConversationManagement WITH(ROWLOCK)
        WHERE FunctionName = @functionName
              AND ContractName = @ContractName
              AND ConversationNo > @cnt 
    END    
    
END
GO

GRANT VIEW DEFINITION ON [sb].[ConversationManagement_End] TO [vnteam] AS [dbo]
GO
/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [sb].[ConversationManagement_Ins]
        @FunctionName VARCHAR(100)
    ,    @ContractName VARCHAR(100)  
    ,    @FromService VARCHAR(100)
    ,    @ToService VARCHAR(100)
    ,    @NewCnt INT  
AS
/*
    Create By: Don
    Created Date: 2017-03-22
    Task: Apply Service Broker for Turnover Control function
    DB: DBAGE.bodb02
    
    Para's explaination
    
        - @NewCnt: expected conversation for this contract
*/
BEGIN 
    SET NOCOUNT ON 
    
    DECLARE @Cnt INT
          , @i INT
          , @handle UNIQUEIDENTIFIER
          , @ConversationNo INT
          , @SendSequence BIGINT
          , @CurrentSendSequence BIGINT          
          , @CurrentDate DATETIME          
          , @MaxID INT              
    DECLARE @ErrorMessage NVARCHAR(4000) 
          , @ErrorSeverity INT
          , @ErrorState INT          
    DECLARE @t TABLE(ID BIGINT IDENTITY(1, 1), Handle UNIQUEIDENTIFIER, ConversationNo INT, SendSequence BIGINT)
    
    SELECT @ErrorSeverity = 10, @ErrorState = 1                             
              
    SET @Cnt = (SELECT Cnt
                FROM sb.ConversationCount WITH (NOLOCK)
                WHERE FunctionName = @functionName
                        AND ContractName = @contractName)
    
    IF @Cnt IS NULL 
    BEGIN
        INSERT INTO sb.ConversationCount (functionName,ContractName,Cnt) 
        VALUES (@functionName,@contractName,0)
    END        
    
    SET @Cnt = ISNULL(@Cnt,0)
    SET @CurrentDate =  GETDATE()        
        
    SET @ErrorMessage = '=============================================== Begin increase process ==============================================='
    RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
              )
              
    SET @i = @Cnt + 1
            
    WHILE @i <= @newCnt
    BEGIN
        BEGIN DIALOG CONVERSATION @handle
        FROM SERVICE  @fromService 
        TO SERVICE  @toService 
        on contract @contractName 
        WITH ENCRYPTION = OFF                                
        
        INSERT INTO sb.ConversationManagement(FunctionName, ContractName, ConversationNo, ConversationHandle,CreatedDate,IsValid)
        VALUES(@functionName, @contractName, @i, @handle,@CurrentDate,1)
        
        SET @ErrorMessage = 'Begin conversation ' + CAST(@handle AS VARCHAR(200)) + ' successfully'
        RAISERROR (@ErrorMessage, -- Message text.  
                   @ErrorSeverity, -- Severity.  
                   @ErrorState -- State.  
                  )
        
        SET @i = @i + 1                    
    END
    
    UPDATE sb.ConversationCount WITH (ROWLOCK)
        SET Cnt = @newCnt
    WHERE FunctionName = @functionName
      AND ContractName = @contractName
    
    SET @ErrorMessage = '=============================================== End increase process ==============================================='
    RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
              )
    
END
GO

GRANT VIEW DEFINITION ON [sb].[ConversationManagement_Ins] TO [vnteam] AS [dbo]
GO
/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Sb].[ConversationManagement_Upd]
( 
        @FunctionName VARCHAR(100) 
    ,    @ContractName VARCHAR(100) = NULL  
    ,    @FromService VARCHAR(100)
    ,    @ToService VARCHAR(100)
    ,    @NewCnt INT   
)
AS
/*
    Create By: Don
    Created Date: 2017-03-22
    Task: Apply Service Broker for Turnover Control function
    DB: DBAGE.bodb02
    
    Para's explaination
*/
BEGIN 
    SET NOCOUNT ON 
    
    DECLARE @Cnt INT
          , @i BIGINT          
          , @MinConversation INT
          , @MaxConversation INT
          , @Count BIGINT
          , @IsError BIT
          
    DECLARE @ErrorMessage NVARCHAR(4000) 
          , @ErrorSeverity INT = 10 -- Information No
          , @ErrorState INT = 1
    DECLARE @t TABLE(ID BIGINT IDENTITY(1, 1), ContractName VARCHAR(100))
    
    IF @contractName IS NOT NULL
        INSERT INTO @t(ContractName) VALUES(@contractName)
    ELSE -- FOR ALL CONTRACTS PROCESS
    BEGIN
        INSERT INTO @t(ContractName) 
        SELECT ContractName
        FROM sb.ConfigurationReferenceDetail WITH (NOLOCK)
        WHERE FunctionName = @functionName
    END            
            
    SET @Count = @@ROWCOUNT        
    
    SET @IsError = 0
    SET @i = 1    
    WHILE @i <= @Count
    BEGIN    
        SELECT @contractName = ContractName
        FROM @t
        WHERE ID = @i
      
        SELECT @MinConversation = MinConversation
             , @MaxConversation = MaxConversation
        FROM sb.ConfigurationReferenceDetail WITH (NOLOCK)
        WHERE FunctionName = @functionName
          AND ContractName = @contractName
          
        IF @newCnt NOT BETWEEN @MinConversation AND @MaxConversation
        BEGIN
            SET @ErrorMessage = 'Contract name ' + @contractName + ' : @newCnt must be between ' + CAST(@MinConversation AS VARCHAR(100)) + ' and ' + CAST(@MaxConversation AS VARCHAR(100))
            RAISERROR (@ErrorMessage, -- Message text.  
                       @ErrorSeverity, -- Severity.  
                       @ErrorState -- State.  
                      );
            SET @IsError = 1                  
        END
        
        SET @i = @i + 1
    END    
    
    IF @IsError = 1
        RETURN                    
    
    SET @i = 1    
    WHILE @i <= @Count
    BEGIN    
        SELECT @contractName = ContractName
        FROM @t
        WHERE ID = @i
        
        SET @Cnt = NULL
        SET @Cnt = (SELECT Cnt
                    FROM sb.ConversationCount WITH (NOLOCK)
                    WHERE FunctionName = @functionName
                      AND ContractName = @contractName)
        SET @Cnt = ISNULL(@Cnt, 0)                              
        
        IF @Cnt <> @newCnt
        BEGIN              
            IF @Cnt < @newCnt -- Open new conversations for specific contract
                EXEC [sb].[ConversationManagement_Ins]
                        @functionName = @functionName
                      , @contractName = @contractName  
                      , @fromService = @fromService
                      , @toService = @toService
                      , @newCnt = @newCnt
            ELSE -- Close existing conversations for specific contract
                EXEC [sb].[ConversationManagement_Del]
                        @functionName = @functionName
                      , @contractName = @contractName    
                      , @newCnt = @newCnt             
        END
        
        SET @i = @i + 1
    END        
          
    -- warning all contracts without conversation if any for DBA to have more info
    SELECT cfd.ContractName AS ContractWithoutConversation
    FROM sb.ConfigurationReferenceDetail cfd WITH (NOLOCK)
         LEFT JOIN sb.ConversationCount cc WITH (NOLOCK)
                ON cfd.FunctionName = cc.FunctionName
                   AND cfd.ContractName = cc.ContractName
    WHERE cfd.FunctionName = @functionName 
      AND ISNULL(cc.Cnt, 0) = 0
    
END
GO

GRANT VIEW DEFINITION ON [sb].[ConversationManagement_Upd] TO [vnteam] AS [dbo]
GO
/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="1"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Sb].[ConversationPick]
( 
        @FunctionName VARCHAR(100)
    ,    @ContractName VARCHAR(200)
    ,    @Handle UNIQUEIDENTIFIER OUT
)
AS
/*
    Create By: Don
    Created Date: 2017-03-22
    Task: Apply Service Broker for Turnover Control function
    DB: DBAGE.bodb02 
    
    Revision

    Para's explaination
*/
BEGIN 
    
    SET NOCOUNT ON 
    DECLARE @ConversationNo INT
            , @Cnt INT
              
    SELECT @Cnt = Cnt
    FROM sb.ConversationCount WITH (NOLOCK)
    WHERE FunctionName = @functionName AND contractName = @ContractName
    
    SET @Cnt = ISNULL(@Cnt, 0)
    
    IF @Cnt = 0
    BEGIN
        SET @handle = NULL
        RETURN
    END
    
    SET @ConversationNo = @@SPID % @Cnt + 1
    
    SELECT @handle = ConversationHandle
    FROM sb.ConversationManagement WITH (NOLOCK)
    WHERE FunctionName = @functionName
            AND contractName = @ContractName
            AND ConversationNo = @ConversationNo 
            AND IsValid = 1  

END
GO

GRANT VIEW DEFINITION ON [sb].[ConversationPick] TO [vnteam] AS [dbo]
GO
/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="1"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Sb].[MsgSent]
(
        @Xml XML
    ,    @Handle UNIQUEIDENTIFIER
    ,    @MessageType VARCHAR(200)
    ,    @ErrorCode INT = 0 OUT
    ,    @ErrorMessage VARCHAR(MAX) = '' OUT
)
AS
/*
    Create By: Don
    Created Date: 2017-03-22
    Task: Apply Service Broker for Turnover Control function
    DB: DBAGE.bodb02 
    
    Revision

    Para's explaination
*/

BEGIN
    
    SET NOCOUNT ON

    DECLARE @sql_string NVARCHAR(MAX) = ''
    SET @sql_string='SEND ON CONVERSATION @handle
                     MESSAGE TYPE ' + @MessageType + '(@xml)'
    BEGIN TRY
        EXEC SP_EXECUTESQL @sql_string,N'@handle uniqueidentifier, @xml xml', @Handle, @Xml
        --PRINT @sql_string
    END TRY
    
    BEGIN CATCH
        SET @ErrorCode = ERROR_NUMBER()
        SET @ErrorMessage = ERROR_MESSAGE()
    END CATCH
    
END
GO

GRANT VIEW DEFINITION ON [sb].[MsgSent] TO [vnteam] AS [dbo]
GO

CREATE PROCEDURE [sb].[TOControl_TransitionIns]
    @XMLString XML
AS 
/*
Created: 20170324@Francis
Task : Process message from SB queue to insert data into transition table
DB: DBAGE.bodb02

Original:

Revisions:

Param explanation:

/*
    XML mapping dictionary tag when buliding and parsing XML string
    Tag        Stand_For
    ---        ---------
    s        srecommend
    m        mrecommend
    a        arecommend
    mid        matchid
    aTO        adjusted_TurnOver
    aHTO    adjusted_HouseTurnOver
*/

*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @TmpTable AS TABLE (srecommend INT, mrecommend INT, recommend INT, matchid INT, adjusted_TurnOver MONEY, adjusted_HouseTurnOver MONEY
    , MinTransID BIGINT, MaxTransid BIGINT
                               )

    DECLARE @transidTbl AS TABLE (transid BIGINT)
    DECLARE  @FinishedTime DATETIME, @MaxBatchID BIGINT, @MinTransID BIGINT, @MaxTransID BIGINT

    BEGIN TRY
        INSERT INTO @TmpTable(srecommend, mrecommend, recommend, matchid, adjusted_TurnOver, adjusted_HouseTurnOver, MinTransID, MaxTransid)
        SELECT x.v.value('(s/text())[1]','INT') AS srecommend,
               x.v.value('(m/text())[1]','INT') AS mrecommend,
               x.v.value('(a/text())[1]','INT') AS recommend,
               x.v.value('(mid/text())[1]','INT') AS matchid,
               x.v.value('(aTO/text())[1]','MONEY') AS adjusted_TurnOver,
               x.v.value('(aHTO/text())[1]','MONEY') AS adjusted_HouseTurnOver
               , x.v.value('(min/text())[1]','BIGINT') AS MinTransID
               , x.v.value('(max/text())[1]','BIGINT') AS MaxTransID
        FROM @XMLString.nodes('/root/r') AS x(v)
        OPTION (OPTIMIZE FOR (@XMLString = NULL))
        
        INSERT INTO dbo.TOControl_Transition (CustID, matchid, adjusted_TurnOver, adjusted_HouseTurnOver)
            SELECT gl.CustID, t.matchid, t.adjusted_TurnOver, t.adjusted_HouseTurnOver
            FROM @TmpTable t INNER JOIN TOControl_GlobalSetting gl WITH (NOLOCK) 
                 ON (t.srecommend = gl.CustID OR t.mrecommend = gl.CustID OR t.recommend = gl.CustID)
                 AND gl.MaxTurnOver != 0

        SELECT @FinishedTime = CURRENT_TIMESTAMP

        SELECT @MinTransID = MIN(MinTransID), @MaxTransID = MAX(MaxTransid)
        FROM @TmpTable

        UPDATE b
        SET b.after_DLTO_Setting = @FinishedTime
        OUTPUT deleted.transid
        INTO @transidTbl (transid)
        FROM DownlineTO_Log_tmp b WITH (ROWLOCK, UPDLOCK)
        INNER JOIN @TmpTable t ON b.recommend = t.recommend AND b.matchid = t.matchid 
        WHERE b.after_DLTO_Setting IS NULL
            AND b.transid BETWEEN @MinTransID AND @MaxTransID

        SELECT @MaxBatchID = ISNULL(MAX(batchid) + 1,0)
        FROM DownlineTO_Log WITH (NOLOCK)

        INSERT INTO DownlineTO_Log (batchid, transid, transdate, srecommend, mrecommend, recommend, matchid, after_DLTO_Trigger, after_DLTO_Setting, tstamp)
            SELECT @MaxBatchID, b.transid, transdate, srecommend, mrecommend, recommend, matchid, after_DLTO_Trigger, after_DLTO_Setting, tstamp
            FROM DownlineTO_Log_tmp b WITH (NOLOCK)
                INNER JOIN @transidTbl t ON b.transid = t.transid
        
        DELETE DownlineTO_Log_tmp WITH(ROWLOCK,UPDLOCK)
        WHERE transid IN (SELECT transid FROM @transidTbl)

    END TRY
    BEGIN CATCH --Write ErrLog
        PRINT (ERROR_MESSAGE())
    END CATCH
END 
GO
GRANT VIEW DEFINITION ON [sb].[TOControl_TransitionIns] TO [vnteam] AS [dbo]
GO

/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [sb].[TOControl_ProcessData]
AS
/*
    Create By: Don
    Created Date: 2017-03-22
    Task: Apply Service Broker for Turnover Control function
    DB: DBAGE.bodb02 
        
    Revision
    
    Param's explaination
*/
BEGIN
    SET NOCOUNT ON

    DECLARE @FunctionName VARCHAR(100) = 'TOControl'

    DECLARE @xml_TOControl XML = ''
    
    DECLARE @handle UNIQUEIDENTIFIER
    
    DECLARE @i INT, @countDeleted INT
    
    DECLARE @ReceiveMax INT, @timeout INT, @IsExistingTarget BIT
    
    DECLARE @message_type_name NVARCHAR(256)
    
    SELECT TOP 1 @ReceiveMax = ISNULL(MaxReceiveMsg, 1)
               , @timeout = ISNULL(MaxReceiveTimeOut, 0)
               , @IsExistingTarget = ISNULL(IsExistingTarget, 0)
    FROM sb.ConfigurationReference    WITH (NOLOCK) 
    WHERE FunctionName = @FunctionName    
    
    DECLARE @Messages TABLE (conversation_handle UNIQUEIDENTIFIER, message_type_name NVARCHAR(256), message_body XML)
    DECLARE @EndDialogMessages TABLE 
    (
        ID INT IDENTITY(1, 1) PRIMARY KEY, 
        conversation_handle UNIQUEIDENTIFIER, 
        message_type_name NVARCHAR(256), 
        message_body XML
    )
     
    WAITFOR (RECEIVE TOP (@ReceiveMax)
                    conversation_handle,
                    message_type_name, 
                    message_body
            FROM Queue_TOControl_DBAGE
            INTO @Messages ), TIMEOUT @timeout;
            
    IF (@@ROWCOUNT = 0)
        RETURN
        
    DELETE FROM @Messages
    OUTPUT DELETED.conversation_handle
         , DELETED.message_type_name
         , DELETED.message_body    
    INTO @EndDialogMessages
    WHERE message_type_name IN ('http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
                              , 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')    
    
    SET @countDeleted = @@ROWCOUNT
    
    IF @countDeleted > 0
    BEGIN
        SELECT TOP 1 @handle = conversation_handle
        FROM @EndDialogMessages
        
        END CONVERSATION @handle WITH CLEANUP;
    END            
    
    SELECT TOP 1 
           @handle = conversation_handle
         , @message_type_name = message_type_name
    FROM @Messages                                                    
    
    IF @message_type_name IN ('MessageType_TOControl_Single','MessageType_TOControl_Multiple')
    BEGIN
        SET @xml_TOControl = (SELECT message_body AS 'node()'
                                FROM @Messages                    
                                FOR XML PATH (''), ROOT)
    IF @xml_TOControl IS NOT NULL 
    --TRY
    EXEC sb.TOControl_TransitionIns @XMLString = @xml_TOControl
    --CATCH

    END
END
GO
GRANT VIEW DEFINITION ON [sb].[TOControl_ProcessData] TO [vnteam] AS [dbo]
GO
/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [sb].[TOControl_SendMessage]
(    
        @Xml XML = NULL
    ,    @FunctionName VARCHAR(100) = 'TOControl'
    ,    @ContractName VARCHAR(100) = ''
    ,    @SB_error BIT = 0 OUTPUT
)
AS
/*
    Create By: Don
    Created Date: 2017-03-22
    Task: Apply Service Broker for Turnover Control function
    DB: DBAGE.bodb02 
        
    Revision
    
    Para's explaination
*/

BEGIN
    
    SET NOCOUNT ON
    DECLARE @Handle UNIQUEIDENTIFIER, @MessageType VARCHAR (200)
    DECLARE @ErrorCode INT = 0, @ErrorMessage VARCHAR(MAX) = ''
    
    SET @MessageType = (SELECT TOP 1 MessageType FROM sb.ConfigurationReferenceDetail WITH (NOLOCK) WHERE FunctionName = @FunctionName AND ContractName = @ContractName)
    
    EXEC sb.ConversationPick @FunctionName = @FunctionName, @ContractName = @ContractName, @Handle = @Handle OUT
    
    IF @Handle IS NULL
    BEGIN
        SET @SB_error = 1
        RETURN
    END
    ELSE 
    BEGIN
        EXEC sb.MsgSent @Handle = @Handle, @Xml = @Xml, @MessageType = @MessageType, @ErrorCode = @ErrorCode OUT, @ErrorMessage =  @ErrorMessage OUT
        IF @ErrorCode <> 0
            SET @SB_error = 1
        ELSE 
            SET @SB_error = 0    
    END
    
END
GO

GRANT VIEW DEFINITION ON [sb].[TOControl_SendMessage] TO [vnteam] AS [dbo]
GO
/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


