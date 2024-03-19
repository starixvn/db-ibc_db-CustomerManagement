/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_ManageAPI_SelByCust]
	-- Add the parameters for the stored procedure here
	  @CustID		INT
AS
/*
	Task : Alpha - API Management - Support data through API
	DB: DBCUST/CustDB
	Original: 
	Revisions:
		- 20221026@Tacy: Create SP [Redmine: #171247]

	Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON;
	
	IF @CustID IS NULL OR @CustID=0
		RETURN

	SELECT APIName, CreatedDate, ExpiredDate, APIKey
	FROM APIInfo WITH (NOLOCK)
	WHERE CustID=@CustID
	ORDER BY CreatedDate
END
GO
