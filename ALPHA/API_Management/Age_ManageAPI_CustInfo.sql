/*<info serverAlias="DBAGE-bodb02" executers="wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_ManageAPI_CustInfo]
	-- Add the parameters for the stored procedure here
	  @CustID	INT=NULL,
	  @UserName	VARCHAR(30)=NULL
AS
/*
	Created: Tacy
	Task : Alpha - API Management - Support data through API
	DB: DBAGE/bodb02
	Original: [Age_ManageAPI_CustProductSel]

	Revisions:
		- 20221205@Tacy: Create SP [Redmine: #171247]
		- 20230714@Tacy: Remove HideKeno column [redmine: #191260]
		- 20230726@Tacy: Enhance performance [redmine: #190504]
		- 20240606@Tacy: Move to DBAGE [redmine: #206254]

	Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON;

	SELECT @CustID = ISNULL(@CustID,0), @UserName = ISNULL(@UserName,'')

	IF @CustID=0 AND @UserName=''
		RETURN

	IF @CustID<>0
	BEGIN
		SELECT c.custid, c.roleid, c.site, c.currency
		FROM Customer c WITH(NOLOCK) 
		WHERE c.custid=@CustID
	END
	ELSE IF @UserName<>''
	BEGIN
		SELECT c.custid, c.roleid, c.site, c.currency
		FROM Customer c WITH(NOLOCK)
		WHERE c.username=@UserName
	END 
END
GO