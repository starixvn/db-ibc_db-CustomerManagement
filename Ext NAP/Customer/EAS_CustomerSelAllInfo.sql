/*<info serverAlias="DBCUST-CustDB" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerSelAllInfo]  
    @GroupName	VARCHAR(50), 
	@UserName	VARCHAR(30),  
	@UserId		INT, 
	@ErrCode 		INT = 0 OUTPUT,
	@ErrMsg 		NVARCHAR(4000) = '' OUTPUT	
AS  
/*  
Creator: 20181030@Elodie  
Task : Search Customer on left panel of EXT NAP
DB: DBCUST/CustDB

Revisions:  
	- 20181030@Elodie: Search Customer on left panel of EXT NAP [Redmine:#95978]
	- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
	- 20210824@Elodie: Fix issue no data in CustSuperProfile [Redmine:#160682]
	- 20230602@Eden: Ext Nap - Archive Super level [Redmine:#183447]
	- 20240220@Luke: Ext Nap - Support to show Headline's username on left panel [Redmine: #200995]
	- 20240702@Tacy: EXT NAP - Not check Permission on Site/Currency [Redmine: #206918] 

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
			@ClosedReason					TINYINT,
			@CustGroupHeadlineID			INT,
			@UplineID						INT
	
	DECLARE @IsCheckSuperArchived BIT = 0

	--Search Info	
	--Get CustID from DBCUST, where got index on Username and Username2
	EXEC @CustId = dbo.f_GetCustIDFromUsername @username
	IF @CustId IS NULL
	BEGIN
		SET @IsCheckSuperArchived = 1
		GOTO CheckSuperArchived;
	END

	SELECT  @RoleId = roleID, @Site = site,
			@srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
	FROM dbo.customer WITH (NOLOCK) 
	WHERE custid = @CustId

	-- check belong to group 
	IF NOT EXISTS (SELECT 1 FROM dbo.Acc_CustGroup WITH(NOLOCK) WHERE CustID = @srecommend AND GroupName = @GroupName)
	BEGIN
		SET @IsCheckSuperArchived = 1
		GOTO CheckSuperArchived;
	END
	
	SELECT @SuperName	= username FROM dbo.custinfo WITH (NOLOCK) WHERE custid = @srecommend
	SELECT @MasterName	= username FROM dbo.custinfo WITH (NOLOCK) WHERE custid = @mrecommend
	SELECT @AgentName	= username FROM dbo.custinfo WITH (NOLOCK) WHERE custid = @recommend

	SELECT @CustGroupHeadlineID = CDA.CustID
	FROM CustDirectAccount CDA WITH (NOLOCK)
	WHERE CDA.CustID IN (@srecommend,@mrecommend,@recommend,@custid)
		
	IF @CustGroupHeadlineID IS NULL
		SET @CustGroupHeadlineID = @srecommend	

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
				ISNULL((SELECT suspendinfo FROM dbo.f_GetSuspendInfoStatus(@roleid,ps.CloseInfo)),0) as isDirectClosed,
				ISNULL(Headline.username,'') AS Headline
		FROM CustSuperProfile cp WITH (NOLOCK)
			RIGHT JOIN dbo.customer c WITH (NOLOCK) ON c.custid = cp.custid
			INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON c.custid = ci.custid
			LEFT JOIN custaccount AS GroupHeadline WITH (NOLOCK) ON GroupHeadline.CUSTID = @CustGroupHeadlineID AND GroupHeadline.GroupID > 0
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
										, Locked
										, CloseInfo
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS ps
			OUTER APPLY (SELECT C.username
				FROM dbo.custaccount ca WITH (NOLOCK)
				INNER JOIN Customer C ON CA.custid = C.custid 
				WHERE ca.GroupID = GroupHeadline.GroupID AND ca.IsGroupHeadLine = 1
			) AS Headline
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
				ISNULL((SELECT suspendinfo FROM dbo.f_GetSuspendInfoStatus(@roleid,ps.CloseInfo)),0) as isDirectClosed,
				ISNULL(Headline.username,'') AS Headline
		FROM dbo.customer c WITH (NOLOCK) 
			INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON c.custid = ci.custid
			LEFT JOIN custaccount AS GroupHeadline WITH (NOLOCK) ON GroupHeadline.CUSTID = @CustGroupHeadlineID AND GroupHeadline.GroupID > 0 
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
										, Locked
										, CloseInfo
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS ps
			OUTER APPLY (SELECT C.username
				FROM dbo.custaccount ca WITH (NOLOCK)
				INNER JOIN Customer C ON CA.custid = C.custid 
				WHERE ca.GroupID = GroupHeadline.GroupID AND ca.IsGroupHeadLine = 1
			) AS Headline
		WHERE c.custid = @CustId	
	END

	CheckSuperArchived:
	IF @IsCheckSuperArchived = 1
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1
			FROM dbo.Cust_ArchiveAccount ar WITH (NOLOCK) 
				INNER JOIN dbo.Acc_CustGroup gr WITH(NOLOCK)
					ON ar.CustID = gr.CustID
			WHERE ar.Username = @UserName
				AND ar.RoleID = 4
				AND ar.StageID = 4
				AND gr.GroupName = @GroupName
		)
		BEGIN
			SELECT @ErrCode = 101, 
					@ErrMsg = '<b>' + @UserName + '</b> has been archived. You can create a new account with this username if it is available.'
		END
	END
END
GO