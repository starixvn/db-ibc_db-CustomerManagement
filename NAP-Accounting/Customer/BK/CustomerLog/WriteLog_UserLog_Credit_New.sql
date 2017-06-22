CREATE PROCEDURE [dbo].[WriteLog_UserLog_Credit_New]
	@UserID INT,
	@CustID INT = 0,
	@Doing VARCHAR(1000),
	@OldValue MONEY = NULL,
	@NewValue MONEY = NULL,
	@IP varchar(15)='',
	@ActionID int = 0
AS
/*
Created: 
Task : Write Credit Log .	
DB: DBLOG.bodb_CustomerLog
Original:

Revisions: 
    - 20090903@Simon: Write Credit Log.
    - 20100102@Kiwi: Add ActionID Log.	
*/

INSERT INTO UserLog_Credit (UserID, 
							CustID, 
							Doing, 
							OldValue, 
							NewValue, 
							IP, 
							ActionID) 
					VALUES (@UserID, 
							@CustID, 
							@Doing, 
							@OldValue, 
							@NewValue, 
							@IP, 
							@ActionID)

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Credit_New] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Credit_New] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_Credit_New] TO [vnteam]