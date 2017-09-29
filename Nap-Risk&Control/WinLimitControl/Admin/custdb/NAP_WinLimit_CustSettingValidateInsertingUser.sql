USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustSettingValidateInsertingUser]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustSettingValidateInsertingUser];
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustSettingValidateInsertingUser]    Script Date: 07/07/2015 16:09:00 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingValidateInsertingUser] @Username VARCHAR(100) = ''
AS
	
/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].

Parameters Explanation:
exec NAP_WinLimit_CustSettingValidateInsertingUser @Username='166HK488'

*/

     SET NOCOUNT ON;
     BEGIN -- Check custname is valid or not.
         DECLARE @CustID INT, @CurrencyID INT, @AgentId INT;
         SELECT @CustID = c.custid,
                @CurrencyID = e.exchangeid,
                @AgentId = c.recommend
         FROM dbo.Customer c WITH (NOLOCK)
              INNER JOIN dbo.exchange e WITH (NOLOCK) ON c.currency = e.exchangeid
         WHERE c.username = @Username
               AND c.roleid = 1;
         IF @CustID IS NULL
             BEGIN
                 SELECT 3 AS ErrorCode
                 RETURN;
         END;
     END;
     BEGIN -- SiteId
         DECLARE @SiteId INT
         SELECT @SiteId = s.siteid
         FROM dbo.Customer c WITH (NOLOCK)
              INNER JOIN dbo.[Site] s WITH (NOLOCK) ON c.site = s.site
         WHERE CustId = @AgentId;
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
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingValidateInsertingUser] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustSettingValidateInsertingUser] TO [vnteam];
GO