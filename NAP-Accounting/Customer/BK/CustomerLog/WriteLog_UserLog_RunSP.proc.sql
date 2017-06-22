ALTER PROCEDURE [dbo].[WriteLog_UserLog_RunSP]
	@UserID int,
	@CustID int = 0,
	@SpName varchar(50),
	@Doing varchar(4000)
AS
 
insert into UserLog_RunSP (UserID, CustID, SpName, Doing) values (@UserID, @CustID, @SpName, @Doing)

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_RunSP] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_RunSP] TO [bodbDownlineNet]