/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp, wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_SubAccManagementSel
	@CustId INT,
	@RoleId TINYINT,
	@subaccid INT = 0,
	@IsAllDownline BIT = 0 OUTPUT
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
	
	IF @subaccid > 0
	BEGIN
		SELECT @IsAllDownline = s.IsAllDownline
		FROM dbo.custSub s WITH (NOLOCK) 
		WHERE subaccid = @subaccid

		IF @RoleId = 4
		BEGIN
			SELECT c.custid, c.username, c.firstname,
				CASE WHEN sm.DownlineId IS NULL AND @IsAllDownline = 0 THEN 0 
					 WHEN sm.DownlineId IS NOT NULL OR @IsAllDownline = 1 THEN 1 END AS Assigned 
			FROM dbo.customer c WITH (NOLOCK)
				LEFT JOIN dbo.CS_SubAccManagement sm WITH (NOLOCK) ON c.custid = sm.DownlineId AND sm.SubAccId = @subaccid
			WHERE c.srecommend = @CustId AND c.roleid = 3
		END
		ELSE IF @RoleId = 3
		BEGIN
			SELECT c.custid, c.username, c.firstname,
				CASE WHEN sm.DownlineId IS NULL AND @IsAllDownline = 0 THEN 0 
					 WHEN sm.DownlineId IS NOT NULL OR @IsAllDownline = 1 THEN 1 END AS Assigned 
			FROM dbo.customer c WITH (NOLOCK)
				LEFT JOIN dbo.CS_SubAccManagement sm WITH (NOLOCK) ON c.custid = sm.DownlineId AND sm.SubAccId = @subaccid
			WHERE c.mrecommend = @CustId AND c.roleid = 2
		END
		ELSE IF @RoleId = 2
		BEGIN
			SELECT c.custid, c.username, c.firstname,
				CASE WHEN sm.DownlineId IS NULL AND @IsAllDownline = 0 THEN 0 
					 WHEN sm.DownlineId IS NOT NULL OR @IsAllDownline = 1 THEN 1 END AS Assigned 
			FROM dbo.customer c WITH (NOLOCK)
				LEFT JOIN dbo.CS_SubAccManagement sm WITH (NOLOCK) ON c.custid = sm.DownlineId AND sm.SubAccId = @subaccid
			WHERE c.recommend = @CustId AND c.roleid = 1
		END
	END
	ELSE
	BEGIN
		IF @RoleId = 4
		BEGIN
			SELECT c.custid, c.username, c.firstname, 0 AS Assigned 
			FROM dbo.customer c WITH (NOLOCK)
			WHERE c.srecommend = @CustId AND c.roleid = 3
		END
		ELSE IF @RoleId = 3
		BEGIN
			SELECT c.custid, c.username, c.firstname, 0 AS Assigned 
			FROM dbo.customer c WITH (NOLOCK)
			WHERE c.mrecommend = @CustId AND c.roleid = 2
		END
		ELSE IF @RoleId = 2
		BEGIN
			SELECT c.custid, c.username, c.firstname, 0 AS Assigned 
			FROM dbo.customer c WITH (NOLOCK)
			WHERE c.recommend = @CustId AND c.roleid = 1
		END
	END
END	
GO

