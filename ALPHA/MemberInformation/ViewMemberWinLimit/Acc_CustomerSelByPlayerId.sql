/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView,bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE	dbo.Acc_CustomerSelByPlayerId
					@PlayerId		VARCHAR(20)	
				,	@ProductId		TINYINT	
				,	@CustId			INT OUTPUT
AS
/*
	Create:	20180815@Elodie
	Task:	Get CustID by PlayerId
	DB:		DBCUST/CustDB

	Revisions:
		- 20180815@Elodie: Get CustID by PlayerId [Redmine: 97675]
		- 20200511@Elodie: Change format of PlayerID [Redmine: #133755]
	Param's Explanation:
	Example: EXEC Acc_CustomerSelByPlayerId @PlayerId = '152636', @ProductId = 33
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @PrefixPlayerID3rd VARCHAR(11)

	SELECT @PrefixPlayerID3rd = site + '$' FROM Customer WITH (NOLOCK) WHERE custid = @CustId

	SELECT @CustId = cm.Custid
	FROM dbo.CustUserMapping3rd cm WITH (NOLOCK)
		INNER JOIN DBACC.bodb02.dbo.Products p WITH (NOLOCK) ON p.VendorID = cm.VendorID
	WHERE p.ProductID = @ProductID AND cm.PlayerID3rd = @PrefixPlayerID3rd + @PlayerId
END
GO