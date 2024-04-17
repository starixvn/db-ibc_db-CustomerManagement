/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

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
		- 20190723@Elodie: Hotfix - Sub account will get lock access when main is locked [Redmine:#117407]
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @IsClosed BIT = 1

	IF @subAccID <> 0
	BEGIN
		SELECT @IsClosed = cs.closed
		FROM dbo.custInfo ci WITH(NOLOCK)
			INNER JOIN custSub cs WITH(NOLOCK) ON ci.custid = cs.custid
		WHERE ci.custid = @CustID
			AND cs.subaccid = @subAccID
	END
	ELSE
	BEGIN
		SELECT @IsClosed = ci.closed
		FROM dbo.custInfo ci WITH(NOLOCK)
		WHERE ci.custid = @CustID
	END

	SELECT	@IsClosed AS IsClosed,
			CustStatus		
	FROM dbo.f_CS_GetCustomerStatus(@CustID)
END
GO