/*<info serverAlias="DBCUST-CUSTDB,DBACC-bodb02" selecters="bodbAdminNet,bodbDownlineNet,vnteam" viewers="" isFunction="1"></info>*/

CREATE FUNCTION [dbo].[f_CS_CustomerStatus] (@CustId INT)   
RETURNS TABLE  
AS  
/*
	Created: 20190528@Elodie
	DB: DBCUST/custDB

	Revision:     
		- 20190528@Elodie: Initial SP [Redmine: #113198]

	Param's Explanation:   
		
	Example: 
		SELECT a.custid, a.discount, b.binaryStr_new
		FROM CS_CustDiscount_Agent a WITH(NOLOCK)
			CROSS APPLY dbo.f_SetBinaryValues(a.discount, '<root><r pos="1" val="111"/><r pos="2" val="222"/></root>') as b
		WHERE a.custid in (19235084, 19235094)
*/ 
RETURN 
	SELECT CASE	WHEN InactiveInfo > 0 THEN 1 --Inactive
				WHEN InactiveInfo = 0 AND SuspendedInfo > 0 THEN 2 --Suspended
				WHEN InactiveInfo = 0 AND SuspendedInfo = 0 AND ViewOnlyInfo > 0 THEN 3 --ViewOnly
				ELSE 4 END AS CustStatus --Active
	FROM dbo.CS_CustomerStatus WITH (NOLOCK)
	WHERE CustId = @CustId

GO