/*<info serverAlias="DBCUST-CustDB" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerSelAllInfo]  
    @GroupName	VARCHAR(50), 
	@UserName	VARCHAR(30),  
	@UserId		INT
AS  
/*  
Creator: 20181030@Elodie  
Task : Search Customer on left panel of EXT NAP
DB: DBCUST/CustDB

Revisions:  
	- 20181030@Elodie: Search Customer on left panel of EXT NAP [Redmine:#95978]
	- 20210408@Tina: Lock account & indirect close account [redmine: #148600]

Example:	
	EXEC EAS_CustomerSelAllInfo @GroupName='ACCUUS', @UserName = 'supertest1', @UserId = 8 
*/
BEGIN
    SET NOCOUNT ON

	DECLARE @CustId							INT,
			@RoleId							TINYINT,
			@Site							NVARCHAR(50),
			@srecommend						INT, 
			@mrecommend						INT,
			@recommend						INT,
			@SuperName						NVARCHAR(50),
			@MasterName						NVARCHAR(50),
			@AgentName						NVARCHAR(50),		 		
			@UplineHasSecurityCode			BIT = 0,
			@IsInternalAdmin				BIT = 0,
			@ClosedReason					TINYINT

	--Search Info	
	--Get CustID from DBCUST, where got index on Username and Username2
	EXEC @CustId = dbo.f_GetCustIDFromUsername @username
	IF @CustId IS NULL
		RETURN

	SELECT  @RoleId = roleID, @Site = site,
			@srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
	FROM dbo.customer WITH (NOLOCK) 
	WHERE custid = @CustId

	-- check belong to group 
	IF NOT EXISTS (SELECT 1 FROM dbo.Acc_CustGroup WITH(NOLOCK) WHERE CustID = @srecommend AND GroupName = @GroupName)
	BEGIN
		RETURN
	END

	EXEC dbo.Acc_CustomerIsInternalAdmin @CustId = @UserID, @IsInternalAdmin = @IsInternalAdmin OUTPUT

	--Check special site
	DECLARE @DenySite TABLE (siteid INT, site NVARCHAR(50), SpecialGroup TINYINT)
	INSERT INTO  @DenySite (siteid , site,SpecialGroup)
	SELECT siteid , site,SpecialGroup 
	FROM NAP_UserControl.dbo.f_GetDeniedSiteByUser (@UserId)

	IF (@IsInternalAdmin = 1 AND EXISTS (SELECT 1 FROM @DenySite WHERE site = @Site))
		RETURN

	SELECT @SuperName	= username FROM dbo.custinfo WITH (NOLOCK) WHERE custid = @srecommend
	SELECT @MasterName	= username FROM dbo.custinfo WITH (NOLOCK) WHERE custid = @mrecommend
	SELECT @AgentName	= username FROM dbo.custinfo WITH (NOLOCK) WHERE custid = @recommend
	
	IF @RoleId = 4
	BEGIN
		SELECT @UplineHasSecurityCode = 1
	END
	ELSE IF @RoleId = 3
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM dbo.CustLoginInfo cl WITH(NOLOCK) WHERE cl.Custid = @srecommend AND cl.SecurityCode IS NOT NULL)
				SELECT @UplineHasSecurityCode = 1
	END
	ELSE IF @RoleId = 2
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM dbo.CustLoginInfo cl WITH(NOLOCK) WHERE cl.Custid = @mrecommend AND cl.SecurityCode IS NOT NULL)
				SELECT @UplineHasSecurityCode = 1
	END
	ELSE IF @RoleId = 1
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM dbo.CustLoginInfo cl WITH(NOLOCK) WHERE cl.Custid = @recommend AND cl.SecurityCode IS NOT NULL)
				SELECT @UplineHasSecurityCode = 1
	END
	
	IF @RoleId=1
		SELECT @ClosedReason = ClosedReason
	    FROM dbo.CustLoginInfo_Member WITH(NOLOCK)
	    WHERE custid = @CustId
	ELSE
		SELECT @ClosedReason = ClosedReason
	    FROM dbo.CustLoginInfo WITH(NOLOCK)
	    WHERE custid = @CustId

	DECLARE @Locked TINYINT

	IF @RoleId = 4
	BEGIN		
		SELECT	c.CustId, c.RoleId, @Site AS site,			
				ISNULL(cp.firstname, '') AS firstname,
				ISNULL(cp.lastname, '') AS lastname,
				c.username, c.username2,
				cp.fax, cp.phone, cp.mobilephone, ISNULL(@ClosedReason,0) AS ClosedReason, @UplineHasSecurityCode AS UplineHasSecurityCode,
				ci.Enabled, ps.closed, ISNULL(ps.reject, 0) AS suspended,
				c.srecommend, c.mrecommend, c.recommend, @SuperName AS SuperName, @MasterName AS MasterName, @AgentName AS AgentName,
				ISNULL(ps.Locked,0) AS Locked,
				ISNULL((SELECT suspendinfo FROM dbo.f_GetSuspendInfoStatus(@roleid,ps.CloseInfo)),0) as isDirectClosed
		FROM CustSuperProfile cp WITH (NOLOCK)
			INNER JOIN dbo.customer c WITH (NOLOCK) ON c.custid = cp.custid
			INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON c.custid = ci.custid
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
										, Locked
										, CloseInfo
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS ps
		WHERE c.custid = @CustId			
	END
	ELSE
	BEGIN
		SELECT	c.CustId, c.RoleId, @Site AS site,			
				ISNULL(c.firstname, '') AS firstname,
				ISNULL(c.lastname, '') AS lastname,
				c.username, c.username2,
				c.fax, c.phone, c.mobilephone, ISNULL(@ClosedReason,0) AS ClosedReason, @UplineHasSecurityCode AS UplineHasSecurityCode,
				ci.Enabled, ps.closed, ISNULL(ps.reject, 0) AS suspended,
				c.srecommend, c.mrecommend, c.recommend, @SuperName AS SuperName, @MasterName AS MasterName, @AgentName AS AgentName,
				ISNULL(ps.Locked,0) AS Locked,
				ISNULL((SELECT suspendinfo FROM dbo.f_GetSuspendInfoStatus(@roleid,ps.CloseInfo)),0) as isDirectClosed
		FROM dbo.customer c WITH (NOLOCK) 
			INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON c.custid = ci.custid
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
										, Locked
										, CloseInfo
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS ps
		WHERE c.custid = @CustId	
	END
END
GO