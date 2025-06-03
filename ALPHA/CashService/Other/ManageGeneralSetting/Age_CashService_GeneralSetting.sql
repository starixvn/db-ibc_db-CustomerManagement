/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService,wsv_nap"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_GeneralSetting
	@CustID			INT				-- SMA Input
AS 
/* 
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Get Member Site Management [Redmine #223896]  
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]

	Param:
		exec Age_CashService_GeneralSetting	@CustID =  1176086

*/  
BEGIN
	SET NOCOUNT ON;
	
	SELECT 
		a.AgentId
		--, CONCAT(REPLACE(a.SubDomainPrefix, '[agentID]', CAST(a.AgentID AS VARCHAR)), '.', dm.Domain) 
		--, REPLACE(a.SubDomainPrefix, '[agentID]', CAST(a.AgentID AS VARCHAR))
		, CONCAT(a.SubDomainPrefix, '.', dm.Domain) 
		AS Domain
	FROM CashDomainManagement a WITH (NOLOCK)
	INNER JOIN GlobCustDB.dbo.DomainManagement dm WITH (NOLOCK) ON a.DomainId = dm.DomainID
	WHERE dm.isDeleted = 0
	AND dm.Status = 3		-- Domain is Active
	AND dm.OfferType = 1
	AND a.AgentId = @CustID

	SELECT 
		a.SettingInfo ,
		a.Mobile AS Mobile, 
		a.Contact AS Contact, 
		a.Announcement AS Announcement
	FROM CashAgentManagement a WITH (NOLOCK)
	WHERE a.AgentId = @CustID


END
