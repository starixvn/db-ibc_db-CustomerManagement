/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet, bodbDownlineNetView" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_SubAccManagementSel
	@subaccid INT
AS
/*
	Created: 20190715
	Task : Manage account on sub account
	DB: DBCUST/CustDB

	Revisions:    
		- 20190715@Elodie: Initial SP [Redmine:#116825]

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @RoleId TINYINT, @IsAllDownline BIT, @CustId INT

	SELECT @RoleId = ci.roleid, @IsAllDownline = s.IsAllDownline, @CustId = s.custid
	FROM dbo.custSub s WITH (NOLOCK) 
		INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.custid = s.custid
	WHERE subaccid = @subaccid
	
	IF @RoleId = 4
	BEGIN
		SELECT ci.custid, 
			CASE WHEN sm.DownlineId IS NULL AND @IsAllDownline = 0 THEN 0 
				 WHEN sm.DownlineId IS NOT NULL OR @IsAllDownline = 1 THEN 1 END AS Assigned 
		FROM dbo.custInfo ci WITH (NOLOCK)
			INNER JOIN dbo.CS_SubAccManagement sm WITH (NOLOCK) ON ci.custid = sm.DownlineId
		WHERE sm.SubAccId = @subaccid AND ci.srecommend = @CustId AND ci.roleid = 3
	END
	ELSE IF @RoleId = 3
	BEGIN
		SELECT ci.custid, 
			CASE WHEN sm.DownlineId IS NULL AND @IsAllDownline = 0 THEN 0 
				 WHEN sm.DownlineId IS NOT NULL OR @IsAllDownline = 1 THEN 1 END AS Assigned 
		FROM dbo.custInfo ci WITH (NOLOCK)
			INNER JOIN dbo.CS_SubAccManagement sm WITH (NOLOCK) ON ci.custid = sm.DownlineId
		WHERE sm.SubAccId = @subaccid AND ci.mrecommend = @CustId AND ci.roleid = 2
	END
	ELSE IF @RoleId = 2
	BEGIN
		SELECT ci.custid, 
			CASE WHEN sm.DownlineId IS NULL AND @IsAllDownline = 0 THEN 0 
				 WHEN sm.DownlineId IS NOT NULL OR @IsAllDownline = 1 THEN 1 END AS Assigned 
		FROM dbo.custInfo ci WITH (NOLOCK)
			INNER JOIN dbo.CS_SubAccManagement sm WITH (NOLOCK) ON ci.custid = sm.DownlineId
		WHERE sm.SubAccId = @subaccid AND ci.recommend = @CustId AND ci.roleid = 1
	END

	SELECT @IsAllDownline AS IsAllDownline
END	
GO

