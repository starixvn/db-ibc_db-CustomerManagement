/*<info serverAlias="DBACC-bodb02" executers="bodbExtAccNet" viewers="vnteam" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[EAS_CustomerSelLoginInfo]  
    @CustId	INT
AS  
/*  
	Creator: 20181030@Elodie  
	Task : Search Customer on left panel of EXT NAP (Login Info)
	DB: DBACC/bodb02

	Revisions:  
		- 20181030@Elodie: Search Customer on left panel of EXT NAP (Login Info) [Redmine:#95978]

	Example:	
		EXEC EAS_CustomerSelLoginInfo @CustId = 1176070
*/
BEGIN
    SET NOCOUNT ON

	DECLARE @RoleId							TINYINT,
			@recommend						INT,
			@Site							NVARCHAR(50),
			@NicknameLoginOnly				BIT = 0,
			@LastChangedSecurityCodeDate	DATETIME,
			@OTPCreateDate					DATETIME,
			@transdate						DATETIME

	SELECT  @RoleId = roleID, @Site = site, @recommend = recommend
	FROM dbo.customer WITH (NOLOCK) 
	WHERE custid = @CustId

	SELECT @OTPCreateDate = CreatedDate FROM dbo.CustOTP WITH(NOLOCK) WHERE custid = @CustId

	IF @RoleId = 4
	BEGIN
		SELECT @NicknameLoginOnly = ISNULL(NicknameLoginOnly, 0) FROM dbo.CustSuper WITH (NOLOCK) WHERE custid = @CustId
		SELECT @transdate = MAX(transdate) FROM dbo.bettrans WITH (NOLOCK) WHERE srecommend = @custid
	END
	ELSE IF @RoleId = 3
	BEGIN
		SELECT @NicknameLoginOnly = ISNULL(NicknameLoginOnly, 0) FROM dbo.CustMaster WITH (NOLOCK) WHERE custid = @CustId
		SELECT @transdate = MAX(transdate) FROM dbo.bettrans WITH (NOLOCK) WHERE mrecommend = @custid
	END
	ELSE IF @RoleId = 2
	BEGIN
		SELECT @NicknameLoginOnly = ISNULL(NicknameLoginOnly, 0) FROM dbo.CustAgent WITH (NOLOCK) WHERE custid = @CustId
		SELECT @transdate = MAX(transdate) FROM dbo.bettrans WITH (NOLOCK) WHERE recommend = @custid
	END
	ELSE IF @RoleId = 1
	BEGIN
		SELECT @transdate = MAX(transdate) FROM dbo.bettrans WITH (NOLOCK) WHERE custid = @custid
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

	SELECT	c.CustId, c.RoleId, @Site AS site,			
			c.creatdate, c.lastlogged, ISNULL(c.iplogin, '') AS lastloginip, pwdexpiry, 
			@LastChangedSecurityCodeDate AS LastChangedSecurityCodeDate, @NicknameLoginOnly AS NicknameLoginOnly, @OTPCreateDate AS OTPCreateDate, @transdate AS LastTxn
	FROM dbo.customer c WITH (NOLOCK) 
	WHERE c.custid = @CustId	
END
GO