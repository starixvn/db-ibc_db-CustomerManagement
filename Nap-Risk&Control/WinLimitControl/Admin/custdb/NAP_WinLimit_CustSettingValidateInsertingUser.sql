/*<info serverAlias="DBCust-CustDB" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingValidateInsertingUser] @Username VARCHAR(100) = ''
AS
	
/*
	Created: Franklin	
	Date: 2016-06-22
	Task: #57722 - Implement Game Win Limit Control phase2

	DB: DBCUST/CustDB

	Revisions:
		- 20160923@Jacob: Risk & Control - Phase 3 [#61220].
		- 20250122@Tacy: Offer direct member for super/master [Redmine: #215809]

	Parameters Explanation:
		exec NAP_WinLimit_CustSettingValidateInsertingUser @Username='166HK488'

*/
BEGIN
     SET NOCOUNT ON;
     BEGIN -- Check custname is valid or not.
         DECLARE @CustID INT, @CurrencyID INT, @siteId INT;
		 
		 SELECT @CustID = c.custid,
                @CurrencyID = e.exchangeid,
                @siteId = s.siteid
         FROM dbo.Customer c WITH (NOLOCK)
              INNER JOIN dbo.exchange e WITH (NOLOCK) ON c.currency = e.exchangeid
			  INNER JOIN dbo.Site s WITH (NOLOCK) ON s.site=c.site
         WHERE c.username = @Username
               AND c.roleid = 1;

         IF @CustID IS NULL
         BEGIN
            SELECT 3 AS ErrorCode
            RETURN;
         END;
     END;

     BEGIN -- Check Currency Win Limit is set or not
         DECLARE @CurrencySettingCount INT;

         SELECT @CurrencySettingCount = COUNT(1)
         FROM WinLimit_ProductSettingDetail WITH (NOLOCK)
         WHERE ExchangeID = @CurrencyID
               AND SiteId = @SiteId;
     
		 IF @CurrencySettingCount = 0
         BEGIN
                 SELECT 4 AS ErrorCode
                 RETURN;
         END;
     END;
	 
	 SELECT 0 AS ErrorCode
END
GO