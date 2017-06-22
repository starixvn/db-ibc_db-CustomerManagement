ALTER PROCEDURE [dbo].[Acc_CustomerSelCheckEnable]
 @username	nvarchar(50)=null
,@custid	int = 0 
,@ErrCode	int = 0 output
,@ErrMsg	nvarchar(200) ='' output 	
AS
/*
	Created: Elodie
	Date: 20150606
	DB: DBCUST/CustDB
	Task: Get Enabled status
	
	Revisions:
*/
BEGIN
	SET NOCOUNT ON
	declare @isEnable bit

	if @custid =0
	begin
		select @isEnable = isnull(enabled,0) from custinfo with (nolock)
		where username =@username 
	end 
	else if @username is null 
	begin
		select @isEnable = isnull(enabled,0) from custinfo with (nolock)
		where custid = @custid 
	end

	if @isEnable = 0 or @@rowcount =0
	begin
		select @ErrMsg = 'This account was disabled!'
			, @ErrCode = 600
		return
	end
END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCheckEnable] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCheckEnable] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCheckEnable] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCheckEnable] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelCheckEnable] TO [vnteam] AS [dbo]