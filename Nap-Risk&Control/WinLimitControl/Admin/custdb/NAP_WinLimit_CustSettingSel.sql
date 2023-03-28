/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingSel] @UserName  NVARCHAR(100) = '',
                                                    @MultiSite	VARCHAR(Max)  = '0',
                                                    @CurrencyID INT           = 0,
                                                    @ProductID	TINYINT       = 0
AS
/*
	Created: Franklin	
	Date: 2016-06-22
	Task: #57722 - Implement Game Win Limit Control phase2
	DB: DBCUST/CustDB

	Revisions:
		- 20160923@Jacob: Risk & Control - Phase 3 [#61220].
		- 20230215@Tacy: CWL - Split 789y site [RedmineID: #182387]

	Parameters Explanation:
		@MultiSite	: 0 ~ all site; <>0 ~ Site

	Example: 
		EXEC [NAP_WinLimit_CustSettingSel]
*/
BEGIN
    SET NOCOUNT ON;

	BEGIN --Site
		DECLARE @Site TABLE (siteID INT)
		
		IF @MultiSite='0'
		BEGIN
			INSERT INTO @Site(siteID)
			SELECT siteid
			FROM Site WITH (NOLOCK)
			WHERE isActive=1
		END
		ELSE
		BEGIN
			INSERT INTO @Site(siteID)
			SELECT TRIM(value) SiteID
			FROM STRING_SPLIT(@MultiSite, ',')
		END
	END;
    BEGIN -- @Products
        DECLARE @Products TABLE (ProductId TINYINT, LevelId TINYINT);

        INSERT INTO @Products
        (ProductId,
        LevelId
        )
            SELECT DISTINCT
                    ProductId,
                    LevelId
            FROM dbo.f_Nap_WinLimit_ProductSettingSel(@ProductId);
    END;
    BEGIN -- Query
        SELECT c.CustID,
            c.username,
            c.currency CurrencyId,
            s.SiteId,
            p.ProductId,
            cs.GroupId,
            cs.LevelID,
            ISNULL(cs.MaxWinLimit_RM, 0) MaxWinLimit
        FROM dbo.WinLimit_CustGameSetting cs WITH (NOLOCK)
            INNER JOIN @Products p ON cs.ProductId = p.ProductId
                                    AND cs.LevelId = p.LevelId
            INNER JOIN dbo.custInfo c WITH (NOLOCK) ON cs.CustID = c.custid
            INNER JOIN dbo.customer a WITH (NOLOCK) ON a.custid = c.recommend
                                                        AND a.roleid = 2
            INNER JOIN dbo.[Site] s WITH (NOLOCK) ON s.[site] = a.[site]
			CROSS APPLY (SELECT 1 val FROM @Site ss WHERE ss.siteID=s.siteid) ss
        WHERE(@UserName = ''
            OR c.username = @UserName)
            AND (@CurrencyID = 0
                OR c.currency = @CurrencyID)
        ORDER BY c.Username;
    END;
END
GO