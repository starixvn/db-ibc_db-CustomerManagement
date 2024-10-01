/*<info serverAlias="DBACC-bodb02" executers="wsv_nap,wsv_alp,wsv_alpv" viewers="" isNested="1"></info>*/
ALTER PROCEDURE	dbo.Acc_GroupHeadlineSelectByCustID (@CustID INT)  
AS
/*
	Created: 20241001@Tacy
	Task: Get headline info by custid
	Database: DBACC/bodb02
	
	Revision:
		- 20241001@Tacy : Initial function [Redmine: #211405]

	Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON;

	;WITH cte_DirectAccount AS (
		SELECT @CustID AS CustID, 
			CustDirect = CASE WHEN cda.CustID IS NOT NULL THEN cda.CustID ELSE c.srecommend END
		FROM Customer c WITH (NOLOCK)
		OUTER APPLY (SELECT TOP 1 cda.CustID
							FROM CustDirectAccount cda WITH (NOLOCK)
							WHERE cda.CustID in (c.custid, c.mrecommend, c.srecommend, c.recommend)
							) cda
		WHERE c.custid=@CustID
	)
	SELECT t.CustID 
		,t.CustDirect
		,hl.custid AS HeadlineID
		,c.username AS HeadlineName
		,hl.GroupID
	FROM cte_DirectAccount t
		LEFT JOIN custAccount ca WITH(NOLOCK) ON ca.custid=t.CustDirect
		LEFT JOIN CustGroupHeadline hl WITH(NOLOCK) ON hl.GroupID=ca.groupID
		LEFT JOIN Customer c WITH (NOLOCK) ON hl.CustID=c.custid
END
GO