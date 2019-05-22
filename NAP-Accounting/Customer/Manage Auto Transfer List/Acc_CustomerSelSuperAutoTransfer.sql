/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Acc_CustomerSelSuperAutoTransfer] @custId INT
AS
/*
		Created: Razor
		Date: 2019-05-04
		Task: 
		DB: DBCust/CustDB
		
		Revisions:
			- 20190405@Razor: Transfer Condition for Automate Transfer - [Redmine: #111365]
		Parameter's Explanation:
	*/
BEGIN
	SET NOCOUNT ON

	SELECT b.CustId
	FROM dbo.Acc_ClearBalanceList AS b WITH (NOLOCK)
		INNER JOIN dbo.custinfo AS c WITH (NOLOCK) ON c.srecommend = b.CustId
	WHERE c.custid = @custId
		AND b.TransferType = 2
END
