/*<info serverAlias="DBAGE-bodb02" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerCheckHideIP]
	@custid		INT,
	@isHideIP	BIT = 0 OUTPUT
AS
/*
	Created: 20251113@Dave
	Task: Update Customer's isHideIP field
	DB: DBCust/Custdb

	Revisions: 
		- 20251113@Dave: EXT - Allow Headline to hide IP info of their downlines [Redmine: #243331]
	
*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT @isHideIP = ISNULL(cs.isHideIP,0)
	FROM dbo.CustInfo AS ci WITH (NOLOCK)
		INNER JOIN dbo.CustSuper AS cs WITH (NOLOCK) ON ci.srecommend = cs.custid
	WHERE ci.custid = @custid;
	
	SET @isHideIP = ISNULL(@isHideIP,0);
END

GO
