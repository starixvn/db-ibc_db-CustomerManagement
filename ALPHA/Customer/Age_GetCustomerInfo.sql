/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_GetCustomerInfo]
	@CustId	INT
AS
/*
	Creator:	20180821@Elodie
	Task:		Get Customer Info - [Redmine: #96019]
	Database:	DBAGE/bodb02
	
	Revisions:
		- 20180821@Elodie: Get Customer Info - [Redmine: #96019]
		- 20200310@Percy: Get IsAllDayBalTransfer on CustMaster (under master level) [RedmineID: #130091]
		- 20200312@Andy:   Get Customer Info - [Redmine: #129673]
		- 20210824@Elodie: Implement Protection Code [Redmine: #160151]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20221226@Tacy: Alpha/NAP - Split 789y Site [RedmineID: #181596]

	Parameter's Explaination:
		
	Developer's Notes:
	Example: EXEC Age_GetCustomerInfo @UserId = 1176070
*/
BEGIN
	SET NOCOUNT ON

	SELECT	ci.custid, ci.username, ci.roleid, ci.currency, e.currency AS CurrencyName, ci.Enabled,
			ci.recommend, ci.mrecommend, ci.srecommend,  
		CASE 
			WHEN m.custid IS NOT NULL 
			THEN m.IsAllDayBalTransfer 
			ELSE s.IsAllDayBalTransfer 
		END AS IsAllDayBalTransfer,
			c.site,
		CASE	
			WHEN c.site = 'IBCIndo'		THEN 11
			WHEN c.site = 'Y987'		THEN 9
			WHEN ss.SiteLabel = '789y'	THEN 7
			WHEN c.site = 'EU88'		THEN 8 
										ELSE 1 
		END AS SiteCode,
		ss.SiteLabel,
		ISNULL(IsProtectedMode,0) AS IsProtectedMode
	FROM dbo.customer c WITH (NOLOCK)
		INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.custid = c.custid
		INNER JOIN DBCUST.CustDB.dbo.CustLoginInfo cl WITH(NOLOCK) ON ci.custid = cl.custid
		INNER JOIN dbo.CustSuper s WITH (NOLOCK) ON c.srecommend = s.custid
		INNER JOIN dbo.Exchange e WITH (NOLOCK) ON e.exchangeid = ci.currency
		INNER JOIN dbo.Site ss WITH (NOLOCK) ON ss.site=c.site
		LEFT JOIN dbo.CustMaster m WITH (NOLOCK) ON c.mrecommend = m.custid
	WHERE ci.custid = @CustId	 
END
GO