/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_PaymentProvider_Sel
	@CustID    INT 		-- SMA_ID Input
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Get list payment Provider [Redmine #223896]
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]

	Param:
		exec Age_CashService_PaymentProvider_Sel_UAT2 @CustID =  14373905 
*/  
BEGIN
	SET NOCOUNT ON;

	DECLARE @_tmp_ProviderList TABLE (ProviderID SMALLINT , ProviderName NVARCHAR(100) , ProviderStatus SMALLINT , LastUpdated SMALLDATETIME )

	INSERT INTO @_tmp_ProviderList (ProviderID , ProviderName, ProviderStatus, LastUpdated)
	SELECT capc.ProviderID  , cpp.ProviderName , capc.ProviderStatus , capc.RepUpdateTime
	FROM CashAgentProviderConfig capc WITH (NOLOCK)
	INNER JOIN CashPaymentProvider cpp WITH (NOLOCK) ON capc.ProviderID = cpp.ProviderID
	WHERE AgentID = @CustID

	--SELECT * FROM @_tmp_ProviderList
	
	SELECT 
		tmp.ProviderID,
		tmp.ProviderName,
		ISNULL(x.ProviderStatus, 2) AS ProviderStatus,
		tmp.LastUpdated
	FROM @_tmp_ProviderList tmp
	OUTER APPLY (
		SELECT TOP 1 tmp.ProviderStatus AS ProviderStatus
		FROM CashPaymentProviderAPIConfig cf WITH (NOLOCK)
		WHERE cf.AgentID = @CustID
		  AND cf.ProviderID = tmp.ProviderID
		  AND cf.PaymentMethodStatus = 2
	) x;
END

