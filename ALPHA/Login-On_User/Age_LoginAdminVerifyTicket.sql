ALTER PROC [dbo].[Age_LoginAdminVerifyTicket]
	@LoginTime  DATETIME = null OUTPUT,
	@Language varchar(2) = 'E',  
	@ErrCode INT = 0 OUTPUT,  
	@ErrMsg NVARCHAR(4000) = '' OUTPUT 
AS
SET NOCOUNT ON
/*
Created: 20091006@Phuc
Task : use for admin login agent site
DB: DBTXN/CustDB

Revisions:
    
Param's Explanation:
*/


IF @LoginTime is null
BEGIN
	SELECT @LoginTime = CURRENT_TIMESTAMP
	RETURN
END
ELSE IF ISDATE(@LoginTime) = 0 OR DATEDIFF(SECOND, @LoginTime, CURRENT_TIMESTAMP) > 5 
BEGIN	
	SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Login error! Session expired.'  
				WHEN 'CS' THEN N'Login error! Session expired.'  
				WHEN 'CT' THEN N'Login error! Session expired.'  
				WHEN 'J' THEN N'Login error! Session expired.'  
				WHEN 'TH' THEN N'Login error! Session expired.'  
				WHEN 'KO' THEN N'Login error! Session expired.'  
				ELSE N'Login error! Session expired.'  
			END , @ErrCode=105    
	RETURN    
END
GO
GRANT EXECUTE ON [dbo].[Age_LoginAdminVerifyTicket] TO [bodbAdminNet,wsv_nap] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_LoginAdminVerifyTicket] TO [bodbDownlineNet,wsv_alp] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_LoginAdminVerifyTicket] TO [bodbDownlineNetView,wsv_alpv] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_LoginAdminVerifyTicket] TO [bodbExtAccNet,wsv_xnap] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_LoginAdminVerifyTicket] TO [vnteam] AS [dbo]