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
		202231108@Johnson: Offer site SEAL888 to group Others [RedmineID: #195581]
		20240118@Tacy: NAP Risk & Control - Merge VS1, VS2, VS3 as Virtual Sports [Redmine: #199920]

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
                       lp3rd.LicenseeName,
                       pt.PartyId
                FROM bodb_licensee.dbo.f_Nap_SiteByProductSel(@ProductId) lp3rd
                INNER JOIN DBLIC.bodb_licensee.dbo.OAS_Party pt WITH (NOLOCK) ON pt.OldRefID = lp3rd.licenseeId
                                                                                 AND pt.PartyType = 1;
     END;
     BEGIN -- Query Data
		SELECT s.siteid AS SiteId,
			s.site AS SiteName,
			CASE WHEN s.SiteLabel IS NULL THEN 'Others' ELSE s.SiteLabel END AS SiteLabel,
			'Credit Sites' AS GroupName
		FROM dbo.Site s WITH (NOLOCK)
		WHERE (s.isLicensee = 0 OR s.site IN ('Saba789','SEAL888'))
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
		WHERE s.site NOT IN ('Saba789','SEAL888')
        ORDER BY 
				GroupName,
				SiteLabel,
                SiteName;
     END;
     DROP TABLE #Party;
     DROP TABLE #PartyGroup;
     DROP TABLE #DepositLicenseeProduct;
END
GO