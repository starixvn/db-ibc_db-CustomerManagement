/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,wsv_nap,bodbDownlineNet,wsv_alp,bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE Acc_CustomerUpdCreditOnReplicateServer
	@CustId		INT,
	@NewCredit	MONEY
AS

/*
	Created: 20191010@Elodie
	Task: Update given credit of customer on replicate server after credit's updated successfully on DBCUST
	DB: DBAGE/bodb02

	Revisions:
		- 20191010@Elodie: Initial SP [Redmine: #121789]		
*/

BEGIN
	SET NOCOUNT ON

	UPDATE	dbo.custInfo WITH (ROWLOCK) 
	SET		credit = @NewCredit
	WHERE	custid = @custid AND credit <> @NewCredit
END
GO
