/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[CS_CustomerStatusSel]
	@CustID INT,
	@subAccID INT = 0
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

	DECLARE @IsClosed BIT = 1;

	IF @subAccID <> 0
	BEGIN
		SELECT @IsClosed = ci.closed | cs.closed
		FROM dbo.custInfo ci WITH(NOLOCK)
			INNER JOIN custSub cs WITH(NOLOCK) ON ci.custid = cs.custid
		WHERE ci.custid = @CustID
			AND cs.subaccid = @subAccID;
	END
	ELSE
	BEGIN
		SELECT @IsClosed = ci.closed
		FROM dbo.custInfo ci WITH(NOLOCK)
		WHERE ci.custid = @CustID;
	END

	SELECT	@IsClosed AS IsClosed,
			CustStatus		
	FROM dbo.f_CS_GetCustomerStatus(@CustID);

	SET NOCOUNT OFF;
END
GO