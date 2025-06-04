/*<info serverAlias="DBCUST-CustDB" executers="asv_CashService,wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_MemberListSel
	@CustID		INT,			-- SMA_ID Input
	@IsSuspended	BIT = NULL,
	@IsClosed		BIT = NULL
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Get List Member [Redmine #223896]
	DB: DBCust.CustDB
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896] 
		- 20250604@Eden: Return more info [redmine: #223896] 

	Param:
		exec Age_CashService_MemberListSel @CustID=  1176086 , @IsSuspended = NULL , @IsClosed = NULL
*/  
BEGIN 

	SET NOCOUNT ON;


	SELECT c.UserName , c.CustID , vw_cps.SuspendInfo AS IsSuspended , vw_cps.CloseInfo AS IsClosed
		,ci.username2 AS NickName, ci.firstname, ci.lastname
	FROM custInfo c WITH (NOLOCK)
		INNER JOIN [vw_Cashservice_customer] ci WITH (NOLOCK) ON c.custid = ci.CustID
		INNER JOIN [vw_CustInfoExtra] vw_cps WITH (NOLOCK) ON c.custid = vw_cps.CustID
	WHERE c.recommend = @CustID
		AND c.roleid = 1 
		AND vw_cps.ServiceType = 1 			-- GET Cash Member Offered
		AND c.Enabled = 1
		AND (@IsSuspended		IS NULL	OR vw_cps.SuspendInfo = @IsSuspended)
		AND (@IsClosed		IS NULL	OR vw_cps.CloseInfo = @IsClosed)
	ORDER BY c.username

END
GO