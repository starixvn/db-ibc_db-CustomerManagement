/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE  [dbo].[Age_CustomerSelEditSuspend_MAg]
	@CustID INT
AS

/*
Created: 
Task : 
DB: DBCUST.CustDB
Original: 
Revisions:
	- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
	- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
	
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @mrecommend INT
	SELECT @mrecommend = mrecommend FROM Custinfo WITH (NOLOCK) WHERE custid = @CustID
	
	SELECT CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS UplineSuspended									
	FROM dbo.CustProductStatus  WITH(NOLOCK)
	WHERE CustID = @mrecommend

END
GO
