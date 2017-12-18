USE [bodb_CustomerLog]
GO

 ALTER PROCEDURE [dbo].[WriteLog_UserLog_Credit]
	@UserID INT,
	@CustID INT = 0,
	@SPName	VARCHAR(50)=NULL, -- USE FOR OLD FORMAT AND WILL REMOVE LATER 
	@Doing VARCHAR(1000),
	@OldValue MONEY = NULL,
	@NewValue MONEY = NULL,
	@IP varchar(15)='',
	@ActionID int = NULL
AS
/*
Created: 
Task : Write Credit Log .	
DB: DBLOG.bodb_CustomerLog
Original:

Revisions: 
    - 20090903@Simon: Write Credit Log.	
    - 20100102@Kiwi: Add ActionID Log.
	- 20150513@Sophia: Add Column ActualRate for Credit Movement Report [#30638]
*/
SET NOCOUNT ON

DECLARE @Date DATE , @ActualRate FLOAT, @ExchangeId TINYINT
SELECT @Date = CURRENT_TIMESTAMP
 
SELECT  @ExchangeId = Currency
FROM	bodb02.dbo.Customer WITH (NOLOCK)
WHERE	CustId = @CustID

SELECT @ActualRate = ActualRate
FROM  bodb02.dbo.ExchangeDailyOanda WITH (NOLOCK)
WHERE ExchangeDate = @Date
	  AND ExchangeId = @ExchangeId

 

INSERT INTO UserLog_Credit (UserID, 
							CustID,
							SPName, 
							Doing, 
							OldValue, 
							NewValue, 
							IP, 
							ActionID,
							ActualRate) 
					VALUES (@UserID, 
							@CustID,
							@SPName, 
							@Doing, 
							@OldValue, 
							@NewValue, 
							@IP, 
							@ActionID,
							@ActualRate)
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Credit] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Credit] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Credit] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_Credit] TO [vnteam] AS [dbo]