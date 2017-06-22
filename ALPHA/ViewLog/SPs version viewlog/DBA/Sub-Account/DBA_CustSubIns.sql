/****** Object:  StoredProcedure [dbo].[DBA_CustSubIns]    Script Date: 11/28/2008 13:24:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DBA_CustSubIns]
	@subaccid int OUTPUT,
	@custid int, -- agentid or masterid or superid
	@username varchar(30),		
	@success bit = 1 OUTPUT,	
	@UserID int=0
AS

/*Description: Create new sub-account for agent
Create date: 2008.05.08
Original SP: Age_CustSubIns
Revisions:    
	- 20100112@Kiwi: Amend to write log in xml format.
*/
SET NOCOUNT ON
--Insert data to db
Insert into custsub
			(
			custid,
			username,
			userpwd,
			firstname,
			lastname,
			PageAccess,
			createdate			
			)
			VALUES
			(
			@custid,
			@username,			
			'4D48FCD27827B82C5E831B9896C57C', -- user password
			'', -- 1st name
			'', -- lastname
			'', -- page access
			getdate()
			)
			
Select @subaccid = @@IDENTITY

if @@error <> 0
BEGIN		
	return	
END


Select @Success = 1

Declare @LogSPData varchar(200)
Select @LogSPData = '<DBA_CustSubIns CustName="' + @UserName + '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID, 
	@CustID = @CustID,
	@ActionID = 616,
	@TrackingValue = @LogSPData
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_CustSubIns] TO [vnteam]