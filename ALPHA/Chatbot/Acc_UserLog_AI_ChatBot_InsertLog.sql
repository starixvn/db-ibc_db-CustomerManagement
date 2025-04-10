/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="wsv_alp" isFunction="0"></info>*/
ALTER PROCEDURE Acc_UserLog_AI_ChatBot_InsertLog
    @UserID INT = NULL,
    @CustID INT = NULL,
    @SubAccID INT = NULL,
    @SessionID UNIQUEIDENTIFIER = NULL,
    @SenderID TINYINT = NULL,
	@ReceiverID TINYINT = NULL,
    @TrackingValue NVARCHAR(MAX) = NULL,
    @MsgDate DATETIME = NULL,
    @IsAction BIT = NULL,
    @MsgType VARCHAR(100) = NULL,
    @RespondTime INT = NULL
AS
/*
	Created: 20250409@Eden
	Task : Insert log record action of AI Chatbot
	DB: DBLOG/bodb_CustomerLog
	Original:

	Revisions:
		- 20250409@Eden: Insert log record action of AI Chatbot [Redmine: 218357]

	Param's Explanation:
		LogTime			: DB Log time		
		UserID			: Login UserID		
		CustID			: CustID of User		
		SubAccID		: Sub account ID		
		SessionID		: Login session of User		
		SenderID		: 0: User, 1,2,3..: BOT 1,2,3..			
		ReceiverID		: 0: User, 1,2,3..: BOT 1,2,3..	
		TrackingValue	: Chat message content		
		MsgDate			: Time when user/AI sent message		
		IsAction		: 0: Opening message, 1 : Closing message (got endpoint)		
		MsgType			: 'KnowledgeBase',  'SummaryReport', 'FullReport', 'Export' ...		
		RespondTime		: Respond duration ( milisecond)		
	
*/
BEGIN
    SET NOCOUNT ON;

    INSERT INTO UserLog_AI_ChatBot (
        LogTime, UserID, CustID, SubAccID, SessionID, SenderID, ReceiverID, TrackingValue, MsgDate, IsAction, MsgType, RespondTime
    )
    VALUES (
        GETDATE(), @UserID, @CustID, @SubAccID, @SessionID, @SenderID, @ReceiverID, @TrackingValue, @MsgDate, @IsAction, @MsgType, @RespondTime
    );
END;
GO

/*
--Sample:
TRUNCATE TABLE UserLog_AI_ChatBot

EXEC Acc_UserLog_AI_ChatBot_InsertLog 
    @UserID = 1176070, 
    @CustID = 1176070, 
    @SubAccID = 0, 
    @SessionID = 'E849B1F4-55CF-408B-A390-935AEE9C6527', 
    @SenderID = 0, 
	@ReceiverID = 1, 
    @TrackingValue = 'What is ProductID = 1?', 
    @MsgDate = '2025-04-08 03:58:31', 
    @IsAction = 0, 
    @MsgType = 'KnowledgeBase', 
    @RespondTime = 1;

EXEC Acc_UserLog_AI_ChatBot_InsertLog 
    @UserID = 1176070, 
    @CustID = 1176070, 
    @SubAccID = 0, 
    @SessionID = 'E849B1F4-55CF-408B-A390-935AEE9C6527', 
    @SenderID = 1, 
	@ReceiverID = 0,  
    @TrackingValue = 'ProductID = 1 is Sportsbook', 
    @MsgDate = '2025-04-08 03:58:36', 
    @IsAction = 1, 
    @MsgType = 'KnowledgeBase', 
    @RespondTime = 10;
*/