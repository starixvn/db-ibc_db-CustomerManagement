 ALTER PROCEDURE [dbo].[WriteLog_UserLog_Credit]
	@UserID INT,
	@CustID INT = 0,
	@SpName VARCHAR(50),
	@Doing VARCHAR(1000),
	@OldValue MONEY = NULL,
	@NewValue MONEY = NULL,
	@IP varchar(15)=''
AS
/*
Created: 
Task : Write Credit Log .	
DB: DBLOG.bodb_CustomerLog
Original:

Revisions: 
    - 20090903@Simon: Write Credit Log.	
*/

INSERT INTO UserLog_Credit (UserID, CustID, SpName, Doing, OldValue, NewValue, IP) 
VALUES (@UserID, @CustID, @SpName, @Doing, @OldValue, @NewValue, @IP)

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Credit] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Credit] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_Credit] TO [vnteam]