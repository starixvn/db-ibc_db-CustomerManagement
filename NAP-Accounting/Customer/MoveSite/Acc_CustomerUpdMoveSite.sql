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
	DB: DBTXN/bodb02

	Revisions:		
		- 20100112@Kiwi: amend to write log in xml format.
		- 20101021@Henry: Record execution time
		- 20110907@Sophia: Change Linked Server from DB052 to DB053	
		- 20120718@Dan: add 1 more field "site" in CustAgent table
		- 20130218@Dan: Change linked server DB03 to DBPOLICY, DB053 to DBAGE; Write more log on DBTXN server in case of DBLOG server failure
		- 20150904@Helen: commission setting for MO [Redmine #41470]
		- 20151026@Don: Support moving site from 766666 to other sites
		- 20160707@Winnie: Feature #48948 Hide_special_sites_from_unautorized_users
	Param's Explanation:
		@CustID: Custid of customer want to move site. We allow to move all customers except members
		

*/

BEGIN
	SET NOCOUNT ON
	
	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()
	
	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpUserid VARCHAR(50)
	
	DECLARE @SearchQuery varchar(1024)
	SELECT @tmpUserid=CAST(@Userid AS VARCHAR(50))
	SELECT @SearchQuery = 'SELECT * 
	FROM OPENQUERY(DBPOLICY, 
	''SELECT siteid , site,SpecialGroup FROM bodb02.dbo.f_GetDeniedSiteByUser( ''''' + @tmpUserid + ''''')'')'

	INSERT INTO  @tmp (siteid , site,SpecialGroup)
	EXECUTE(@SearchQuery)	
	
	IF (@site IN (SELECT site FROM @tmp ))
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg ='You don''t have permission to access'
		RETURN
	END
	
	--Check permission for account site: @phuc20080213
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[MoveSite]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
	--end
	DECLARE @IsAllow bit, @RoleId int	
	EXEC DBAGE.bodb02.dbo.Acc_CustomerSelCheckMoveSite @CustId= @CustId, @UserId = @UserId, @IsAllow = @IsAllow output, @RoleId = @RoleId output
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
	
	DECLARE @OldSite varchar(50), @LogSPData varchar(8000)
	DECLARE @userName VARCHAR(50)
	SELECT @OldSite =  site from customer (nolock) where custid = @CustId	

	SET @userName = (SELECT username FROM custInfo WITH (NOLOCK) WHERE custid = @CustId)
	--IF @OldSite = '766666' OR @Site = '766666'
	-- 20151026@Don - Support moving site from 766666 to other sites
	IF @Site = '766666' 
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Cannot move site for ' + @userName + ' since amongs its new and old sites, one has % Odds.'
		RETURN
	END
	
	IF @RoleId = 4 -- For Super
	BEGIN
		UPDATE customer WITH(ROWLOCK,UPDLOCK) SET site = @site WHERE srecommend = @CustId and RoleId IN (4,3,2)
		UPDATE custagent WITH(ROWLOCK,UPDLOCK) 
		SET site = @site 
		FROM custagent JOIN customer C ON c.custid = custagent.custid
		WHERE srecommend = @CustId and RoleId IN (4,3,2)
	END
	ELSE IF @RoleId = 3 -- For Master
	BEGIN
		UPDATE customer WITH(ROWLOCK,UPDLOCK) SET site = @site WHERE mrecommend = @CustId and RoleId IN (3, 2)
		UPDATE custagent WITH(ROWLOCK,UPDLOCK) 
		SET site = @site 
		FROM custagent JOIN customer C ON c.custid = custagent.custid
		WHERE mrecommend = @CustId and RoleId IN (3, 2)
	END
	ELSE IF @RoleId = 2 -- For Agent
	BEGIN
		UPDATE customer WITH(ROWLOCK,UPDLOCK) SET site = @site WHERE recommend = @CustId and RoleId IN (2)
		UPDATE custagent WITH(ROWLOCK,UPDLOCK) 
		SET site = @site 
		FROM custagent JOIN customer C ON c.custid = custagent.custid
		WHERE recommend = @CustId and RoleId IN (2)
	END 

	--print('write log')-- Write Log Here
	SELECT @LogSPData = '<Acc_CustomerUpdMoveSite OldSite="'+ @OldSite + '" ' +
						'NewSite="'+ @Site  + '" ' +
						'IP="'+ @IP  + '" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserId,
		@CustID = @CustId,
		@ActionID = 614,
		@TrackingValue = @LogSPData,
		@duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogSPData = '<Acc_CustomerUpdMoveSite OldSite="'+ @OldSite + '" ' +
			'NewSite="'+ @Site  + '" ' +
			'IP="'+ @IP + '" ' + 
			'ErrCode="'+ COALESCE(CAST(ERROR_NUMBER() AS VARCHAR(50)),SPACE(1)) + '" ' + 
			'ErrMsg="'+ COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" />'
			
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserId,
		@CustID = @CustId,
		@ActionID = 614,
		@TrackingValue = @LogSPData,
		@duration = @duration
	END CATCH	
END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMoveSite] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMoveSite] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMoveSite] TO [vnteam]

