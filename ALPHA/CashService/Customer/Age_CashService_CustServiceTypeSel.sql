/*<info serverAlias="DBCUST-CustDB" executers="wsv_CashService,wsv_nap,wsv_alp,wsv_alpv"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_CustServiceTypeSel
	@CustID				INT,
	@ServiceType			TINYINT	OUTPUT
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Check Cust is ServiceType or not [Redmine #223896] 
	DB: DBCust.CustDB
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]    
		- 20250724@Dave: Add executers wsv_alp,wsv_alpv [Redmine: #233474]

	Param:

	@ServiceType : 0 - Credit  || 1 - Cash

	DECLARE @p1 TINYINT
	exec Age_CashService_CustServiceTypeSel @CustID =  1176086  , @ServiceType = @p1 OUTPUT
	SELECT @p1
*/  
BEGIN
	SET NOCOUNT ON;
	     
	SELECT @ServiceType  = 0

	IF EXISTS (SELECT TOP 1 1 FROM [vw_CustInfoExtra] vw_cps WITH (NOLOCK) WHERE vw_cps.CustID = @CustID AND vw_cps.ServiceType = 1)
	BEGIN
		SET @ServiceType = 1
	END


END