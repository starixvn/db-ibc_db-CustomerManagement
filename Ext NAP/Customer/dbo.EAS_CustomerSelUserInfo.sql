/*<info serverAlias="DBEAS-bodb_EAS" executers="bodbExtAccNet" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[EAS_CustomerSelUserInfo]  
	@custid	int = 0
AS  
/*
	Created: 20180628@Elodie
	Task : Get User Information and their upline info
	DB: DBAGE/bodb02

	Revisions:
		- 20181122@Elodie: DB053/bodb_Age Migration [Redmine:#104770]
		- 20180628@Elodie: Get User Information and their upline info [Redmine: #58776]

*/	
BEGIN
	SET NOCOUNT ON  
	/*
	DECLARE @roleID					TINYINT,	
			@HasSecurityCode		BIT = 0,
			@UplineHasSecurityCode	BIT =0,
			@ClosedReason			TINYINT,
			@srecommend				INT, 
			@mrecommend				INT,
			@recommend				INT,
			@SuperName				NVARCHAR(50),
			@MasterName				NVARCHAR(50),
			@AgentName				NVARCHAR(50)		 		

	SELECT  @roleID = roleID, 
			@srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
	FROM bodb02.dbo.custinfo WITH (NOLOCK) 
	WHERE custid = @custid

	IF @roleID IN(2,3,4)
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM DBACC.bodb02.dbo.CustLoginInfo cl WITH(NOLOCK) WHERE cl.Custid = @Custid AND cl.SecurityCode IS NOT NULL)
				SELECT @HasSecurityCode=1

		IF @roleID = 4
			SELECT @UplineHasSecurityCode = 1
		ELSE
		BEGIN
			IF EXISTS (SELECT TOP 1 1 FROM dbo.CustLoginInfo cl WITH(NOLOCK) WHERE cl.Custid = CASE WHEN @roleID = 3 THEN @SRecommend AND cl.SecurityCode IS NOT NULL)
				SELECT @UplineHasSecurityCode = 1
		END

		SELECT @ClosedReason = ClosedReason FROM DBACC.bodb02.dbo.CustLoginInfo cl WITH(NOLOCK) WHERE cl.Custid=@Custid
	END
	ELSE 
	BEGIN
		SELECT @ClosedReason = ClosedReason FROM DBACC.bodb02.dbo.CustLoginInfo_Member cl WITH(NOLOCK) WHERE cl.Custid=@Custid
	END

	-- check belong to group 
IF NOT EXISTS (SELECT 1 FROM bodb02.dbo.Acc_CustGroup WITH(NOLOCK) WHERE CustID = @srecommend AND GroupName = @GroupName)
	BEGIN
		RETURN
	END

	IF (@IsGetUplineInfo=1)
	BEGIN
		SELECT  @SuperName = case when roleid=4 then username else @SuperName end,
				@MasterName = case when roleid=3 then username else @MasterName end,
				@AgentName = case when roleid=2 then username else @AgentName end
		FROM bodb02.dbo.custinfo WITH (NOLOCK) 
		WHERE custid IN (@srecommend, @mrecommend, @recommend)
	END

	SELECT @custid AS custid, @username AS username, @roleID AS roleID, 
		ci.Enabled, c.firstname, c.lastname, c.username2, c.phone, c.mobilephone, c.fax, c.creatdate, c.iplogin AS lastloginip, 
		@ClosedReason AS ClosedReason, @HasSecurityCode AS HasSecurityCode
		@srecommend AS srecommend, @mrecommend AS mrecommend, @recommend AS recommend,
		@SuperName AS SuperName, @MasterName AS MasterName, @AgentName AS AgentName
	FROM bodb02.dbo.Customer c WITH (NOLOCK) 
		INNER JOIN bodb02.dbo.CustInfo ci WITH (NOLOCK) ON c.custid = ci.custid
	WHERE c.custid = @custid
	*/
END
GO
