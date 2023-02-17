/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_WinLimit_SiteByProductSel] @ProductId INT = 0
AS
/*
	Created: Franklin	
	Date: 2016-06-22
	Task: #57722 - Implement Game Win Limit Control phase2

	DB: DBCUST/CustDB

	Revisions:
		20160923@Jacob: Risk & Control - Phase 3 [#61220].
		20180921@Jacob: Migrate some of Licensee Setting tables (LRF System) from DB052.bodb_Licensee to DBCust.bodb_Licensee [#99855]
		20230213@Tacy: CWL - Split 789y site [RedmineID: #182387]

	Parameters Explanation:
		   @ProductId: Product ID

	Example:
		EXEC [NAP_WinLimit_SiteByProductSel]
*/
BEGIN
     SET NOCOUNT ON;
    
     BEGIN -- Deposit Licensee
         CREATE TABLE #Party
         (PartyId    INT PRIMARY KEY,
          PartyName  VARCHAR(50),
          BranchName VARCHAR(50),
          ParentId   INT
         );
         CREATE TABLE #PartyGroup
         (PartyGroupId   INT PRIMARY KEY,
          PartyGroupName VARCHAR(50)
         );
         CREATE TABLE #DepositLicenseeProduct
         (ProductId    INT,
          LicenseeId   INT,
          LicenseeName VARCHAR(50),
          PartyId      INT
         );
        
		INSERT INTO #Party
         (PartyId,
          PartyName,
          BranchName,
          ParentId
         )
         EXEC DBLIC.bodb_licensee.dbo.LA_PartyListSel;
       
	   INSERT INTO #PartyGroup
         (PartyGroupId,
          PartyGroupName
         )
                SELECT p.PartyId,
                       p.PartyName
                FROM #Party p
                WHERE p.ParentId = 0;
        
		INSERT INTO #DepositLicenseeProduct
         (ProductId,
          LicenseeId,
          LicenseeName,
          PartyId
         )
                SELECT DISTINCT
                       lp3rd.ProductID,
                       lp3rd.LicenseeId,
                       l.LicenseeName,
                       pt.PartyId
                FROM
                (
                    SELECT CASE
                               WHEN ProductID = 14
                               THEN 13
                               ELSE ProductID
                           END AS ProductID,
                           LicenseeId
                    FROM bodb_licensee.dbo.LicenseeProduct3rd WITH (NOLOCK)
                    WHERE ProductID IN
                    (
                        SELECT CASE
                                   WHEN ProductId = 13
                                   THEN 14
                                   ELSE ProductId
                               END
                        FROM dbo.f_Nap_WinLimit_ProductSettingSel(67)
                    )
                ) AS lp3rd
                INNER JOIN bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeID = lp3rd.licenseeId
                INNER JOIN DBLIC.bodb_licensee.dbo.OAS_Party pt WITH (NOLOCK) ON pt.OldRefID = lp3rd.licenseeId
                                                                                 AND pt.PartyType = 1;
     END;
     BEGIN -- Query Data
         SELECT s.siteid AS SiteId,
                s.site AS SiteName,
				s.SiteLabel,
                'Credit Sites' AS GroupName
         FROM dbo.Site s WITH (NOLOCK)
         WHERE (s.isLicensee = 0 OR s.site='Saba789')
               AND S.isActive = 1
         UNION ALL
         SELECT DISTINCT
                s.siteid,
                s.site,
				s.SiteLabel,
                pg.PartyGroupName
         FROM #DepositLicenseeProduct dlp
              INNER JOIN #Party p ON dlp.PartyId = p.PartyId
              INNER JOIN #PartyGroup pg ON p.ParentId = pg.PartyGroupId
              INNER JOIN dbo.Site s WITH (NOLOCK) ON s.site = dlp.LicenseeName
                                                     AND S.isActive = 1
                                                     AND S.isLicensee = 1
		 WHERE s.site<>'Saba789'
         ORDER BY 
				  GroupName,
				  SiteLabel DESC,
                  SiteName;
     END;
     DROP TABLE #Party;
     DROP TABLE #PartyGroup;
     DROP TABLE #DepositLicenseeProduct;
END
GO