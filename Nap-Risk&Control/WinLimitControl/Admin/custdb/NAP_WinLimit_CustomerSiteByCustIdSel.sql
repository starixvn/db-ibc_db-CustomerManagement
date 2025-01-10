/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/ 

ALTER PROCEDURE [dbo].[NAP_WinLimit_CustomerSiteByCustIdSel] @CustIdList NVARCHAR(MAX) = ''
AS
/*
	Created: Franklin	
	Date: 2016-06-22
	Task: #57722 - Implement Game Win Limit Control phase2

	DB: DBCUST/CustDB

	Revisions:
		- 20160923@Jacob: Risk & Control - Phase 3 [#61220].
		- 20220613@Elodie: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831]  
		- 20250122@Tacy: Offer direct member for super/master [Redmine: #215809]

	Parameters Explanation:

	Example: 
		EXEC [NAP_WinLimit_CustomerSiteByCustIdSel] @CustIdList = '791088,807023,807567'
*/
BEGIN
     SET NOCOUNT ON;
     DECLARE @Customer TABLE(CustId INT);
     INSERT INTO @Customer(CustId)
    SELECT CONVERT( INT, value)
    FROM string_split(@CustIdList, ',')
	WHERE value <> ''

     SELECT c.custid,
            c.username,
            c.[site] SiteName
     FROM dbo.Customer c WITH (NOLOCK)
          INNER JOIN @Customer u ON c.custid = u.custid
END
GO
