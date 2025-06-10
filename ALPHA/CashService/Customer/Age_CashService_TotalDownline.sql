/*<info serverAlias="DBCUST-CustDB" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_TotalDownline
	@CustID				INT
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Check Cust is ServiceType or not [Redmine #223896] 
	DB: DBCust.CustDB
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #228627]

	Param:
	DECLARE @p1 INT
	exec Age_CashService_TotalDownline @CustID =  233657343
	SELECT @p1 
*/  
BEGIN
	SET NOCOUNT ON;
	   
	DECLARE
		@total_memberActive		INT,
		@total_memberClosed		INT,
		@total_memberSuspended	INT	

	-- all downline's status
	SELECT
		@Total_memberActive    = ISNULL(SUM(CASE WHEN cs.IsClosed = 0 AND cs.IsSuspended = 0 THEN 1 ELSE 0 END), 0),
		@Total_memberClosed    = ISNULL(SUM(CASE WHEN cs.IsClosed = 1 THEN 1 ELSE 0 END), 0),
		@Total_memberSuspended = ISNULL(SUM(CASE WHEN cs.IsSuspended = 1 AND cs.IsClosed = 0 THEN 1 ELSE 0 END), 0)
	FROM dbo.custInfo ci WITH (NOLOCK)
		CROSS APPLY  
		(
			SELECT TOP 1
				CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS IsClosed
				,CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS IsSuspended
				,ServiceType
			FROM vw_CustInfoExtra WITH(NOLOCK)
			WHERE CustID = ci.custid
		) AS cs
	WHERE recommend = @CustId	
		AND roleid = 1
		AND cs.ServiceType = 1

	SELECT
		@total_memberActive		AS total_memberActive,
		@total_memberClosed		AS total_memberClosed,
		@total_memberSuspended	AS total_memberSuspended
END