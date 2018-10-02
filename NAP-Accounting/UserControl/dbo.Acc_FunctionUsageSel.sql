/*<info serverAlias="DBMA-bodb_Maintenance" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_FunctionUsageSel]    
	@UserId			INT, 
	@SiteId			INT = 0,
	@Environment	VARCHAR(10)	= 'UAT'	-- 'UAT', 'LIVE'
AS 
/* 
	Created: 20121214@Elodie
    Task: Get most function usage
    DB: DBMA.bodb_Maintenance
    
    Revisions:
		- 20180925@Helen: Get code from PRO + DB052.bodb_NAP Migration to DBCust - [Redmine:100493]
		
    Param's Explanation:    
	
*/
BEGIN
	SET NOCOUNT ON
		
	SELECT  TOP 10
			fu.MenuId, 
			CASE WHEN Position <> 0 THEN 0 ELSE count END VisitedCount,
			CASE WHEN Position <> 0 THEN Position ELSE 11 END Position
	FROM 
		(
			-- Select function permission of user in site and include its group function
			-- get highest policy in one function
			SELECT 
				CASE 
					WHEN ISNULL(A.FunctionID, 0) = 0 THEN B.FunctionID 
					ELSE A.FunctionID 
				END AS FunctionID,
				CASE 
					WHEN ISNULL(A.Policy, 0) < ISNULL(B.Policy, 0) THEN ISNULL(B.Policy, 0) 
					ELSE ISNULL(A.Policy, 0) 
				END AS Policy
			FROM 
			(
				-- Get function permission of @UserId in @SiteId
				SELECT uf.FunctionId, uf.Policy
				FROM 
					DBPOL.NAP_UserControl.dbo.NAP_UserFunction AS uf WITH (NOLOCK)
					INNER JOIN DBPOL.NAP_UserControl.dbo.NAP_Functions AS f WITH (NOLOCK) ON uf.FunctionId = f.FunctionId
				WHERE 
					uf.UserId = @UserId 
					AND uf.SiteId = @SiteId
					AND f.IsActive = 1
					AND (@Environment = 'UAT' OR (@Environment != 'UAT' AND f.Environment = @Environment))
			) AS A
			FULL OUTER JOIN
			(
				-- Get function permission of group where user belong to
				SELECT gf.FunctionId, gf.Policy
				FROM 
					DBPOL.NAP_UserControl.dbo.NAP_GroupFunction AS gf WITH (NOLOCK)
					INNER JOIN DBPOL.NAP_UserControl.dbo.NAP_Users AS u WITH (NOLOCK) ON u.GroupId = gf.GroupId
					INNER JOIN DBPOL.NAP_UserControl.dbo.NAP_Functions AS f WITH (NOLOCK) ON gf.FunctionId = f.FunctionId
				WHERE 
					u.UserId = @UserId
					AND gf.SiteId = @SiteId
					AND f.IsActive = 1
					AND (@Environment = 'UAT' OR (@Environment != 'UAT' AND f.Environment = @Environment))					
			) AS B
			ON A.FunctionID = B.FunctionID 	
		) AS uf
		INNER JOIN DBPOL.NAP_UserControl.dbo.NAP_MenuItems m WITH (NOLOCK) ON uf.FunctionID = m.FunctionID
		INNER JOIN Acc_FunctionUsage fu WITH (NOLOCK) ON m.MenuItemId =fu.MenuId		
		WHERE fu.CustId = @UserId	
	ORDER BY Position, VisitedCount DESC
END 
GO 
GRANT EXECUTE ON [dbo].[Acc_FunctionUsageSel] TO [bodbAdminNet]
GO 
GRANT VIEW DEFINITION ON [dbo].[Acc_FunctionUsageSel] TO [vnteam]
GO 
