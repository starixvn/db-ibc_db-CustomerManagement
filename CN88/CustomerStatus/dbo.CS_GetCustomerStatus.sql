/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[CS_GetCustomerStatus]
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
	SET NOCOUNT ON;

	SELECT	InactiveInfo,
			SuspendedInfo,
			ViewOnlyInfo
	FROM CS_CustomerStatus WITH(NOLOCK)
	WHERE CustID = @CustID;

	SET NOCOUNT OFF;
END
GO