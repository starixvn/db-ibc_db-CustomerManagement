ALTER PROCEDURE [dbo].Acc_CustomerSelCheckSmartPunter
	@custid INT = NULL,
	@username VARCHAR(50) = '',
	@isSmartPunter BIT = 0 OUTPUT,
	@UserId	INT=0,
	@IsRestricted	BIT=0,
	@ActionID		INT=0,
	@IP	VARCHAR(15)=NULL 
AS
/*
	Created: Johnson
	Date: 2014-05-20
	DB: DBCUST.CustDB
	Task: Check customer is smart punter or not
	Revisions:  
		- 20150609@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20161004@Winnie: Write log data smart punter monitoring RedmineID: #58901
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @srecommend INT,@mrecommend INT,@recommend INT
	IF @custid IS NULL
		SELECT @custid = custid,@srecommend=srecommend,@mrecommend=mrecommend,@recommend=recommend FROM customer WITH(NOLOCK) WHERE username = @username
	ELSE
		SELECT @srecommend=srecommend,@mrecommend=mrecommend,@recommend=recommend FROM customer WITH(NOLOCK) WHERE custid = @custid	
			
	IF EXISTS (SELECT TOP 1 1 FROM SmartPunterList WITH(NOLOCK) WHERE custid = @custid )
	BEGIN
	SELECT @isSmartPunter = 1
	IF(@ActionID<>0)
	EXEC DBLOG.bodb_CustomerLog.dbo.NAP_UserLog_SmartPunterIns 
			@Userid = @userid,
			@Custid = @CustID,
			@ActionID = @ActionID,
			@IP = @IP,
			@IsRestricted = @IsRestricted
	END
	ELSE IF EXISTS (SELECT TOP 1 1 FROM SmartPunterList WITH(NOLOCK) WHERE custid = @recommend )
	BEGIN
	SELECT @isSmartPunter = 1
	IF(@ActionID<>0)
	EXEC DBLOG.bodb_CustomerLog.dbo.NAP_UserLog_SmartPunterIns 
			@Userid = @userid,
			@Custid = @CustID,
			@ActionID = @ActionID,
			@IP = @IP,
			@IsRestricted = @IsRestricted,
			@UplineID=@recommend
	END
	ELSE IF  EXISTS (SELECT TOP 1 1 FROM SmartPunterList WITH(NOLOCK) WHERE custid = @mrecommend )
	BEGIN
	SELECT @isSmartPunter = 1
	IF(@ActionID<>0)
	EXEC DBLOG.bodb_CustomerLog.dbo.NAP_UserLog_SmartPunterIns 
			@Userid = @userid,
			@Custid = @CustID,
			@ActionID = @ActionID,
			@IP = @IP,
			@IsRestricted = @IsRestricted,
			@UplineID=@mrecommend
	END
	ELSE IF  EXISTS (SELECT TOP 1 1 FROM SmartPunterList WITH(NOLOCK) WHERE custid = @srecommend )
	BEGIN
	SELECT @isSmartPunter = 1
	IF(@ActionID<>0)
	EXEC DBLOG.bodb_CustomerLog.dbo.NAP_UserLog_SmartPunterIns 
			@Userid = @userid,
			@Custid = @CustID,
			@ActionID = @ActionID,
			@IP = @IP,
			@IsRestricted = @IsRestricted,
			@UplineID=@srecommend
	END
	ELSE 
		SELECT @isSmartPunter = 0
		
	
END


GRANT EXECUTE ON [dbo].[Acc_CustomerSelCheckSmartPunter_xtest] TO [bodbAdminNet]