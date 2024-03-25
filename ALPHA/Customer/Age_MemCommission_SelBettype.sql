/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_MemCommission_SelBettype]  
	@custID INT = 0, -- default: site MBC
	@Site VARCHAR(10) = NULL
AS

/*  
 Task: Get bet types for Member Commission function  
 Date: 20150410@Tom.Vo
 DB: DBAGE/bodb02   
 Revisions:
	- 20150519@Sophia: Support Metric Gaming [#35278]
	- 20151207@Percy: Add new 4 bettypes Over/Under into comm1 section [Redmine: #48050]
	- 20160218@Percy: Add new bettypes of Cricket [Redmine: #50027]
	- 20160711@Helen: Change Moneyline Commission [Redmine: #58493]
	- 20170410@Percy:
		1. Add new bettypes of BAIO [RedmineID: #74558]
		2. Remove 2 excess bettypes 807, 808 [RedmineID: #56344]
	- 20170425@Percy: Use related bettype - commission group function [RedmineID: #71665]
	- 20190816@Percy: Apply primary-secondary bettype [RedmineID: #117068]
	- 20190826@Percy: Sort by bet type [RedmineID: #118699]
	- 20240105@Johnson: Hide bettype SABA for site 777777 [redmine: #194591]
	- 20230918@Eden: DCS Sportsbook Credit[redmine: #193083] 
*/

BEGIN

	SET NOCOUNT ON
	
	DECLARE @isIMBC BIT = 0,
		@SpecialPlatform TINYINT = 0


	IF ISNULL(@CustID, 0) <> 0
	BEGIN
		SELECT @Site = s.[Site],
			@SpecialPlatform = s.SpecialPlatfrom
		FROM DBCUST.CustDB.dbo.Customer c WITH (NOLOCK)
			INNER JOIN Site s WITH(NOLOCK) ON c.Site = s.Site
		WHERE custid = @CustID
	END

	IF @Site = 'IMBC'
		SELECT @isIMBC = 1

	;WITH CTE_bettype AS
	(
		SELECT DISTINCT ISNULL(g.GroupTypeId, bc.bettype) AS bettype, bc.CommGroup
		FROM f_Bettype_CommGroup() bc
			LEFT JOIN dbo.f_GroupBettype() g ON bc.bettype = g.Bettype AND g.Bettype <> g.GroupTypeId
		WHERE
			(
				@isIMBC = 0
				OR bc.bettype <> 501
			)
			AND bc.isShow = 1
			AND 1 = CASE WHEN @SpecialPlatform = 4 AND bc.Bettype IN (228,229) THEN 0 ELSE 1 END --Hide bettype SABA xxx for 777777
	)

	SELECT CommGroup AS CommID
		,STUFF((
				SELECT ',' + CONVERT(VARCHAR(10), b.bettype)
				FROM CTE_bettype b
				WHERE b.CommGroup = c.CommGroup
				ORDER BY b.bettype
				FOR XML PATH('')
				), 1, 1, '') AS typeid
		,CommGroup AS OrderID
	FROM dbo.f_Bettype_CommGroup() c
	WHERE CommGroup IN (1,2)
	GROUP BY CommGroup
	ORDER BY CommGroup
END

