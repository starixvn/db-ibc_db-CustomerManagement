/*<info serverAlias="DBACC-bodb02" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Dep_CustomerSel_Shadow]
	@CustID	INT
AS
/*    
	Created: 20241230@Tacy 
	Task : All Shadow Accounts which have same SabaID by real member
	DB: DBACC-bodb002    
	    
	Revisions:  
		- 20241230@Tacy: Create SP [Redmine: #215807]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @SabaID	BIGINT

	SELECT @SabaID=SabaID
	FROM Dep_CustSabaInfo sb WITH (NOLOCK)
	WHERE CustID=@CustID AND CustType=0

	SELECT sb.CustID, c.username
	FROM Dep_CustSabaInfo sb WITH (NOLOCK)
	INNER JOIN Customer c WITH (NOLOCK) ON c.custid=sb.CustID
	WHERE SabaID=@SabaID AND CustType=1
END
GO