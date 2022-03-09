/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingStake_SiteSel] 
	-- Add the parameters for the stored procedure here
	  @pMutilSite	VARCHAR(Max) = ''
AS
/*
		Task : NAP -  Flexible Initializing Stake Level
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20220210@Winfred: NAP -  Flexible Initializing Stake Level [Redmine: #167128]
		
		Param's Explanation:
			@pMutilSite  0 : All, <> 0 : Site
	*/
BEGIN
	
	SET NOCOUNT ON;
		
	SELECT 
		 siteid, site
	FROM Site  WITH(NOLOCK)
	WHERE IsActive = 1 AND (@pMutilSite = '0' OR siteid IN (SELECT val FROM dbo.strSplit(@pMutilSite, ',')))
	ORDER BY siteid, site
END
GO
