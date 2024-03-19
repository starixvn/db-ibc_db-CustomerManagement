/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE	dbo.Acc_CustomerSelByPlayerId
					@PlayerId		VARCHAR(50)	
				,	@ProductId		TINYINT	
				,	@CustId			INT OUTPUT
AS
/*
	Create:	20180815@Elodie
	Task:	Get CustID by PlayerId
	DB:		DBCUST/CustDB

	Revisions:
		- 20180815@Elodie: Get CustID by PlayerId [Redmine: 97675]

	Param's Explanation:
	Example: EXEC Acc_CustomerSelByPlayerId @PlayerId = '152636', @ProductId = 33
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT @CustId = cm.Custid
	FROM dbo.CustUserMapping3rd cm WITH (NOLOCK)
		INNER JOIN DBACC.bodb02.dbo.Products p WITH (NOLOCK) ON p.VendorID = cm.VendorID
	WHERE p.ProductID = @ProductID AND cm.PlayerID3rd = @PlayerId
END
GO