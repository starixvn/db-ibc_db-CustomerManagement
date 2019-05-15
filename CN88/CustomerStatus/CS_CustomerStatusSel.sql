/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_CustomerStatusSel
	@CustID INT
AS
/*  
	Created by: Paul  
	Date: 2019-05-14
	Task: 
	DB: DBCUST/CustDB
	Original SP:
	Revisions:
		- 20190514@Paul: Create new SP [RedmineID: #113198]
*/

BEGIN
	SET NOCOUNT ON

	SELECT	CASE	WHEN InactiveInfo > 0 THEN 1 
					WHEN InactiveInfo = 0 AND SuspendedInfo > 0 THEN 2 
					WHEN InactiveInfo = 0 AND SuspendedInfo = 0 AND ViewOnlyInfo > 0 THEN 3 ELSE 4 END AS CustStatus		
	FROM CS_CustomerStatus WITH(NOLOCK)
	WHERE CustID = @CustID

	SET NOCOUNT OFF
END
GO