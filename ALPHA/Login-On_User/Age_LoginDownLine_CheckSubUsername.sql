
ALTER PROCEDURE [dbo].[Age_LoginDownline_CheckSubUsername]
	@SubUserName varchar(50),	
	@isExisted bit=0 OUTPUT
AS
--AGENT Site
--Original:LoginDownline_CheckSubUsername
SET NOCOUNT ON

if exists (SELECT 1 FROM custsub as c with (nolock) where c.username = @SubUserName)
	set @isExisted = 1
else
	set @isExisted = 0


GO

GRANT EXECUTE ON [dbo].[Age_LoginDownline_CheckSubUsername] TO [bodbDownlineNet,wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_LoginDownline_CheckSubUsername] TO [bodbDownlineNetView,wsv_alpv]
