/*<info serverAlias="DBCUST-CUSTDB,DBAGE-bodb02,DBACC-bodb02" selecters="wsv_nap,bodbDownlineNet,wsv_alp" viewers="" isFunction="1"></info>*/

CREATE FUNCTION [dbo].[f_CS_GetCustomerStatus] (@CustId INT)   
RETURNS TABLE  
AS  
/*
	Created: 20190528@Elodie
	DB: DBCUST/custDB

	Revision:     
		- 20190528@Elodie: Initial SP [Redmine: #113198]

	Param's Explanation:   
		
	Example: 
		SELECT CustStatus FROM f_CS_GetCustomerStatus (19235084)
*/ 
RETURN 
	SELECT CASE	WHEN InactiveInfo > 0 THEN 1 --Inactive
				WHEN InactiveInfo = 0 AND SuspendedInfo > 0 THEN 2 --Suspended
				WHEN InactiveInfo = 0 AND SuspendedInfo = 0 AND ViewOnlyInfo > 0 THEN 3 --ViewOnly
				ELSE 4 END AS CustStatus --Active
	FROM dbo.CS_CustomerStatus WITH (NOLOCK)
	WHERE CustId = @CustId

GO