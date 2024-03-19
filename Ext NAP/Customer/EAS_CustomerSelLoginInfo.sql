/*<info serverAlias="DBACC-bodb02" executers="bodbExtAccNet,wsv_xnap" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerSelLoginInfo]  
    @CustId	INT,
	@GroupName VARCHAR(50)
AS  
/*  
	Creator: 20181030@Elodie  
	Task : Search Customer on left panel of EXT NAP (Login Info)
	DB: DBACC/bodb02

	Revisions:  
		- 20181030@Elodie: Search Customer on left panel of EXT NAP (Login Info) [Redmine:#95978]
		- 20191227@Johnson: change to get max transdate from sp EAS_CustomerSelBalanceInfo [redmine: #125894]
		- 20230208@Tacy: Alpha/NAP - Split 789y site [Redmine:#181596]
	Example:	
		EXEC EAS_CustomerSelLoginInfo @CustId = 1176070, @GroupName = 'ACCUUS'
*/
BEGIN
    SET NOCOUNT ON

	DECLARE @RoleId							TINYINT,
			@recommend						INT,
			@srecommend						INT,
			@Site							NVARCHAR(50),
			@SiteLabel						VARCHAR(50),
			@NicknameLoginOnly				BIT = 0,
			@LastChangedSecurityCodeDate	DATETIME,
			@OTPCreateDate					DATETIME			

	SELECT  @RoleId = roleID, @Site = c.site, @recommend = recommend, @srecommend = srecommend, @SiteLabel=s.SiteLabel
	FROM dbo.customer c WITH (NOLOCK) 
	INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site
	WHERE custid = @CustId

	-- check belong to group 
	IF NOT EXISTS (SELECT 1 FROM dbo.Acc_CustGroup WITH(NOLOCK) WHERE CustID = @srecommend AND GroupName = @GroupName)
	BEGIN
		RETURN
	END

	SELECT @OTPCreateDate = CreatedDate FROM dbo.CustOTP WITH(NOLOCK) WHERE custid = @CustId

	IF @RoleId = 4
	BEGIN
		SELECT @NicknameLoginOnly = ISNULL(NicknameLoginOnly, 0) FROM dbo.CustSuper WITH (NOLOCK) WHERE custid = @CustId		
	END
	ELSE IF @RoleId = 3
	BEGIN
		SELECT @NicknameLoginOnly = ISNULL(NicknameLoginOnly, 0) FROM dbo.CustMaster WITH (NOLOCK) WHERE custid = @CustId		
	END
	ELSE IF @RoleId = 2
	BEGIN
		SELECT @NicknameLoginOnly = ISNULL(NicknameLoginOnly, 0) FROM dbo.CustAgent WITH (NOLOCK) WHERE custid = @CustId		
	END
	ELSE IF @RoleId = 1
	BEGIN		
		SELECT  @Site = site FROM dbo.customer WITH (NOLOCK) WHERE custid = @recommend
	END
	
	IF @RoleId=1
		SELECT @LastChangedSecurityCodeDate = LastChangedDate
	    FROM dbo.CustLoginInfo_Member WITH(NOLOCK)
	    WHERE custid = @CustId
	ELSE
		SELECT @LastChangedSecurityCodeDate = LastChangedSecurityCodeDate
	    FROM dbo.CustLoginInfo WITH(NOLOCK)
	    WHERE custid = @CustId

	SELECT	c.CustId, c.RoleId, @Site AS site, @SiteLabel AS sitelabel,			
			c.creatdate, c.lastlogged, ISNULL(c.iplogin, '') AS lastloginip, pwdexpiry, 
			@LastChangedSecurityCodeDate AS LastChangedSecurityCodeDate, @NicknameLoginOnly AS NicknameLoginOnly, @OTPCreateDate AS OTPCreateDate
	FROM dbo.customer c WITH (NOLOCK) 
	WHERE c.custid = @CustId	
END
GO