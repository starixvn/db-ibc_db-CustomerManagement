/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_BetMonitoring_NotifiedCustomerListSel]
AS
/*  
	Creator: Elodie 
	Date: 20160705
	Task: Get customer list to send email - [Redmine:#58401]
	DB: DBACC/bodb02
  
	Revisions:		
		- 20210512@Eden: Migrate bodb_Acc to main server [#152636]
		- 20210524@Tina: Lock account & indirect close account [redmine: #148600]  

*/
BEGIN
	SET NOCOUNT ON

	SELECT ci.custid, ci.username,  s.SportType, s.SportName, ROUND(CONVERT(FLOAT,his.BetCount)*100/his.TotalBet,0) AS Threshold, his.BetCount, his.TotalBet, ci.currency
	FROM dbo.BetMonitoring_CustTotalBet_History his WITH (NOLOCK)
		INNER JOIN dbo.CustInfo ci WITH (NOLOCK) ON his.CustID = ci.custid
		INNER JOIN dbo.Sports s WITH (NOLOCK) ON s.SportType = his.SportType
		OUTER APPLY  (  SELECT TOP 1 ci.closed, ci.reject
			      		FROM bodb02.dbo.Dep_CustSuper  WITH(NOLOCK)
			 			WHERE CustID = ci.srecommend
						UNION ALL
						SELECT TOP 1 CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
							, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
						FROM bodb02.dbo.CustProductStatus  WITH(NOLOCK)
						WHERE CustID = ci.custid
			     ) AS cps
	WHERE his.NotifiedStatus = 1 AND cps.closed = 0
	ORDER BY s.SportType
END
GO