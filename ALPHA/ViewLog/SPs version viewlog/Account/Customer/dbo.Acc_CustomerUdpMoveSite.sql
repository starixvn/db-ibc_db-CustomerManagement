ALTER PROCEDURE [dbo].[Acc_CustomerUpdMoveSite]
	@UserId			INT,
	@CustId			INT	,
	@Site			varchar(50),
	@ErrCode		INT OUTPUT,
	@ErrMsg			varchar(200) OUTPUT,
	@IP				varchar(50) = ''
AS
/*	Created by: [Khoa] 
	Date: 20091224
	Task: Move Site for customer
	DB: DB02.bodb02

	Revisions:		
		- 20100112@Kiwi: amend to write log in xml format.
	Param's Explanation:
		@CustID: Custid of customer want to move site. We allow to move all customers except members
		

*/

BEGIN
	SET NOCOUNT ON
	--Check permission for account site: @phuc20080213
	EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[MoveSite]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
	--end
	DECLARE @IsAllow bit, @RoleId int	
	EXEC db052.bodb02.dbo.Acc_CustomerSelCheckMoveSite @CustId= @CustId, @UserId = @UserId, @IsAllow = @IsAllow output, @RoleId = @RoleId output
	IF @IsAllow = 0
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Cannot move site for this customer. We do not allow Member move site.'
		RETURN
	END

	IF NOT EXISTS(SELECT 1 FROM Site (NOLOCK) WHERE SITE = @Site)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Do not exist any site name as ' + @Site + ' in the system.'
		RETURN
	END

	DECLARE @OldSite varchar(50), @LogSPData varchar(300)
	SELECT @OldSite =  site from customer (nolock) where custid = @CustId	

	IF @RoleId = 4 -- For Super
		UPDATE customer WITH(ROWLOCK,UPDLOCK) SET site = @site WHERE srecommend = @CustId and RoleId IN (4,3,2)
	ELSE IF @RoleId = 3 -- For Master
		UPDATE customer WITH(ROWLOCK,UPDLOCK) SET site = @site WHERE mrecommend = @CustId and RoleId IN (3, 2)
	ELSE IF @RoleId = 2 -- For Agent
		UPDATE customer WITH(ROWLOCK,UPDLOCK) SET site = @site WHERE recommend = @CustId and RoleId IN (2)

	--print('write log')-- Write Log Here
	SELECT @LogSPData = '<Acc_CustomerUpdMoveSite OldSite="'+ @OldSite + '" ' +
	'NewSite="'+ @Site  + '" ' +
	'IP="'+ @IP  + '" />'

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserId,
	@CustID = @CustId,
	@ActionID = 614,
	@TrackingValue = @LogSPData

END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMoveSite] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMoveSite] TO [vnteam]

