/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp, bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE Age_CustomerIndirectLoginAccountSel
	@custid INT,
	@SubAccID INT = 0,
	@CustIDInDirect INT = NULL,
	@SubAccIDIndirect INT = NULL
AS
/*
	Created: 20200521@Johnson
	Task : get indirect login account by upline
	DB: DBCUST/CustDB

	Revisions:
		- 20200521@Johnson: initial sp [redmine:#133846]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
*/		
BEGIN
	SET NOCOUNT ON
	
	SELECT c.CustIDInDirect, c.SubAccIDIndirect,
		CASE WHEN cs.custid IS NULL THEN ci.username ELSE cs.username END as username,
		ci.roleid, 
		CASE WHEN cs.custid IS NULL THEN ps.closed ELSE cs.closed END closed, 
		CASE WHEN cs.custid IS NULL THEN ps.reject ELSE 0 END as Suspended,
		CASE WHEN cs.custid IS NULL THEN ci.Enabled ELSE 1 END as Enabled,
		c.LastVerifyPwd,
		CASE WHEN cs.custid IS NULL THEN l.LastChangedPwdDate ELSE ls.LastChangedPwdDate END as LastChangedPwdDate,
		CASE WHEN cs.custid IS NULL THEN ISNULL(ps.Locked,0) ELSE 0 END	AS Locked
	FROM CustInDirectLogin c WITH(NOLOCK)
		INNER JOIN custinfo ci WITH(NOLOCK) ON c.custidInDirect = ci.custid
		LEFT JOIN custSub cs WITH(NOLOCK) ON cs.custid = c.CustIDInDirect
											AND cs.SubAccID = c.SubAccIDIndirect
		LEFT JOIN CustLoginInfoSub ls WITH(NOLOCK) ON cs.custid = ls.CustID 
													AND cs.subaccid = ls.SubAccID
		LEFT JOIN CustLoginInfo l WITH(NOLOCK) ON ci.custid = l.CustID
		OUTER APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
							, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
							, Locked
						FROM dbo.CustProductStatus  WITH(NOLOCK)
						WHERE CustID = ci.custid
					) AS ps
								
		
	WHERE c.custid = @custid
		AND c.subAccID = @SubAccID
		AND c.CustIDInDirect = ISNULL(@CustIDInDirect,c.CustIDInDirect)
		AND c.SubAccIDIndirect = ISNULL(@SubAccIDIndirect,c.SubAccIDIndirect)
	ORDER BY roleid DESC,username ASC	
END
GO