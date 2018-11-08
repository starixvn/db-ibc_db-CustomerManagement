/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet, bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[Acc_CustomerSelTotalDownline]
	@CustId INT,
	@RoleId TINYINT
AS
/*
	Creator: 20181108@Elodie
	Task: Get total downline info in left panel (Put on DB053 to use index IX_CI_srecommend for super, IX_custinfo for master and IX_custinfo_1 for agent)
	DB: DBAGE/bodb02
	
	Revisions:	
		- 20181108@Elodie: Get total downline info [RedmineID: #58776]	

	Explanation: 
	
	Example: EXEC Acc_CustomerSelTotalDownline @CustID=24471545, @RoleId = 4
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TotalMemberActive INT, @TotalMemberClosed INT, @TotalMemberSuspended INT,
			@TotalAgentActive  INT, @TotalAgentClosed  INT, @TotalAgentSuspended  INT,
			@TotalMasterActive INT, @TotalMasterClosed INT, @TotalMasterSuspended INT				
		
	IF @RoleId = 2
	BEGIN
		SELECT	@TotalMemberActive = ISNULL(SUM(CASE WHEN Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
				@TotalMemberClosed = ISNULL(SUM(CASE WHEN Closed = 1 THEN 1 ELSE 0 END), 0),
				@TotalMemberSuspended = ISNULL(SUM(CASE WHEN ISNULL(reject,0) = 1 AND closed = 0 THEN 1 ELSE 0 END), 0) 
		FROM custinfo (NOLOCK) 
		WHERE recommend = @custID AND RoleID=1

		SELECT	@TotalMemberActive AS [TotalMemActive], 
				@TotalMemberClosed AS [TotalMemClosed], 
				@TotalMemberSuspended AS [TotalMemSuspended]

	END
	ELSE IF @RoleId = 3
	BEGIN
		SELECT	@TotalAgentActive = ISNULL(SUM(CASE WHEN RoleID = 2 AND Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
				@TotalAgentClosed = ISNULL(SUM(CASE WHEN RoleID = 2 AND Closed = 1 THEN 1 ELSE 0 END), 0),
				@TotalAgentSuspended = ISNULL(SUM(CASE WHEN RoleID = 2 AND ISNULL(reject,0) = 1 AND closed = 0 THEN 1 ELSE 0 END), 0),			
				@TotalMemberActive = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 0 and ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
				@TotalMemberClosed = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 1 THEN 1 ELSE 0 END), 0),
				@TotalMemberSuspended = ISNULL(SUM(CASE WHEN RoleID = 1 AND ISNULL(reject,0) = 1 AND closed = 0 THEN 1 ELSE 0 END), 0)
		FROM custinfo (NOLOCK) 
		WHERE mrecommend = @custID

		SELECT	@TotalAgentActive AS [TotalAgActive], 
				@TotalAgentClosed AS [TotalAgClosed], 
				@TotalAgentSuspended AS [TotalAgSuspended],	
				@TotalMemberActive AS [TotalMemActive], 
				@TotalMemberClosed AS [TotalMemClosed], 
				@TotalMemberSuspended AS [TotalMemSuspended]
	END	
	ELSE IF @RoleId = 4
	BEGIN
		SELECT	@TotalMasterActive = ISNULL(SUM(CASE WHEN RoleID = 3 AND Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
				@TotalMasterClosed = ISNULL(SUM(CASE WHEN RoleID = 3 AND Closed = 1 THEN 1 ELSE 0 END), 0),
				@TotalMasterSuspended = ISNULL(SUM(CASE WHEN RoleID = 3 AND ISNULL(reject,0) = 1 AND closed = 0 THEN 1 ELSE 0 END), 0),			
				@TotalAgentActive = ISNULL(SUM(CASE WHEN RoleID = 2 AND Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
				@TotalAgentClosed = ISNULL(SUM(CASE WHEN RoleID = 2 AND Closed = 1 THEN 1 ELSE 0 END), 0),
				@TotalAgentSuspended = ISNULL(SUM(CASE WHEN RoleID = 2 AND ISNULL(reject,0) = 1 AND closed = 0 THEN 1 ELSE 0 END), 0),		
				@TotalMemberActive = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 0 and ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
				@TotalMemberClosed = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 1 THEN 1 ELSE 0 END), 0),
				@TotalMemberSuspended = ISNULL(SUM(CASE WHEN RoleID = 1 AND ISNULL(reject,0) = 1 AND closed = 0 THEN 1 ELSE 0 END), 0)
		FROM custinfo (NOLOCK) 
		WHERE srecommend = @custID

		SELECT	@TotalMasterActive AS [TotalAgActive], 
				@TotalMasterClosed AS [TotalAgClosed], 
				@TotalMasterSuspended AS [TotalAgSuspended],	
				@TotalAgentActive AS [TotalAgActive], 
				@TotalAgentClosed AS [TotalAgClosed], 
				@TotalAgentSuspended AS [TotalAgSuspended],	
				@TotalMemberActive AS [TotalMemActive], 
				@TotalMemberClosed AS [TotalMemClosed], 
				@TotalMemberSuspended AS [TotalMemSuspended]
	END	
END

GO
