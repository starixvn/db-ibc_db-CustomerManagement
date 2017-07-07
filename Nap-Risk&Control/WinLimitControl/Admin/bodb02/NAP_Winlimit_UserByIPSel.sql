USE [bodb02];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_Winlimit_UserByIPSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_Winlimit_UserByIPSel];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_Winlimit_UserByIPSel] @IP VARCHAR(50)
AS

/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBACC/bodb02

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].

Parameters Explanation:
Eample:
EXEC [NAP_Winlimit_UserByIPSel] @IP = '127.0.0.1'
*/

     SET NOCOUNT ON;
     DECLARE @Today SMALLDATETIME;
     SELECT @Today = CONVERT( DATE, GETDATE());
     SELECT DISTINCT
            CustId,
            winlostdate LastAccessedDate,
            @IP AS IP
     FROM dbo.bettrans AS b WITH (NOLOCK)
     WHERE winlostdate = @Today
           AND ip = @IP
           AND bettype <= 19000;
GO
GRANT EXECUTE ON [dbo].[NAP_Winlimit_UserByIPSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Winlimit_UserByIPSel] TO [vnteam];
GO