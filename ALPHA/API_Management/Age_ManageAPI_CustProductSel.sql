/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_ManageAPI_CustProductSel]
	-- Add the parameters for the stored procedure here
	  @CustID	INT=NULL,
	  @UserName	VARCHAR(100)=NULL
AS
/*
	Task : Alpha - API Management - Support data through API
	DB: DBCUST/CustDB
	Original: 
	Revisions:
		- 20221205@Tacy: Create SP [Redmine: #171247]
		- 20230714@Tacy: Remove HideKeno column [redmine: #191260]
		- 20230726@Tacy: Enhance performance [redmine: #190504]

	Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON;
	
	IF @CustID IS NULL AND @UserName IS NULL RETURN

	IF @CustID<>0
	BEGIN
		SELECT ci.custid, ci.roleid, c.site, ci.currency
		FROM custInfo ci WITH (NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON c.custid=ci.custid
		WHERE ci.custid=@CustID
	END
	ELSE IF @UserName<>''
	BEGIN
		SELECT ci.custid, ci.roleid, c.site, ci.currency
		FROM custInfo ci WITH (NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON c.custid=ci.custid
		WHERE ci.username=@UserName
	END 
END
GO