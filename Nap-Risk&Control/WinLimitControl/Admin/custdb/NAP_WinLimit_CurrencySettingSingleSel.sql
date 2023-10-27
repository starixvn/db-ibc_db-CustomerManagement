/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingSingleSel] @ProductId  INT,
                                                               @SiteId     INT,
                                                               @CurrencyId INT,
                                                               @GroupId    INT
AS
/*
	Created: Franklin	
	Date: 2016-06-22
	Task: #57722 - Implement Game Win Limit Control phase2

	DB: DBCUST/CustDB

	Revisions:
		- 20160923@Jacob: Risk & Control - Phase 3 [#61220].
		- 20230911@Tacy: CWL - Suspend member accounts when member reaches Yellow level on RNG Slots Games [RedmineID: #184911]

	Parameters Explanation:
	   @ProductId: Product ID
	   @SiteId	: Site or Licensee ID
	   @IsCreditSite: Is Credit Site
	   @CurrencyId	: Currency ID
   
	Example:
	EXEC [NAP_WinLimit_CurrencySettingSingleSel] @ProductId = 6, @SiteId = 30, @CurrencyId = 1, @GroupId = 1
*/
BEGIN
     SET NOCOUNT ON;
     SELECT ProductID,
            GroupID,
            ExchangeID,
            SiteID,
            LevelID,
            MaxWinLimit,
            IsBlockedPlaceBet,
            IsBlockedTransfer,
			IsSuspendedAccount,
            MaxWinLimit_RM
     FROM dbo.WinLimit_ProductSettingDetail WITH (NOLOCK)
     WHERE ProductID = @ProductId
           AND ExchangeID = @CurrencyId
           AND SiteID = @SiteId
           AND GroupId = @GroupId;
END
GO