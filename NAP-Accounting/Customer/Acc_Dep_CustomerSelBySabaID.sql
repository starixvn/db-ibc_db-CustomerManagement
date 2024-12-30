/*<info serverAlias="DBACC-bodb02" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Dep_CustomerSelBySabaID]
	@SabaID	BIGINT
AS
/*    
	Created: 20241230@Tacy 
	Task : show all Accounts which are linked to the same SabaID 
	DB: DBACC-bodb002    
	    
	Revisions:  
		- 20241230@Tacy: Create SP [Redmine: #215807]
*/
BEGIN
	SET NOCOUNT ON;

	SELECT sb.CustID, c.username, sb.CustType, sb.SabaID,
		a.custid	AS agentID,
	    a.username	AS agentName,	
	    m.custid	AS masterID,
	    m.username	AS masterName,
	    s.custid	AS superID,
	    s.username	AS superName
	FROM Dep_CustSabaInfo sb WITH (NOLOCK)
		INNER JOIN Customer c WITH (NOLOCK) ON c.custid=sb.CustID
		LEFT JOIN custinfo a WITH(NOLOCK) on c.recommend = a.custid
	    LEFT JOIN custinfo m WITH(NOLOCK) on c.mrecommend = m.custid
	    LEFT JOIN custinfo s WITH(NOLOCK) on c.srecommend = s.custid
	WHERE SabaID=@SabaID
END
GO