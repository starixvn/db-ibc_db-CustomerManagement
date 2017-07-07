USE [CustDB];
GO

/****** Object:  UserDefinedFunction [dbo].[f_Nap_WinLimit_CreditCurrencySel]    Script Date: 07/11/2016 12:54:52 ******/

IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[f_Nap_WinLimit_CreditCurrencySel]')
          AND type IN(N'FN', N'IF', N'TF', N'FS', N'FT')
)
    DROP FUNCTION [dbo].[f_Nap_WinLimit_CreditCurrencySel];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION [dbo].[f_Nap_WinLimit_CreditCurrencySel]
(
)
RETURNS TABLE
AS

/*
Created: Jacob	
Date: 2017-03-13
Task: #72604 - Implement Game Win Limit Control phase2 3A

DB: DBCUST/CustDB

Revisions:
20170313@Jacob: Risk & Control - Phase 3A [#72604].

Example:
SELECT * FROM [f_Nap_WinLimit_CreditCurrencySel]()
*/

     RETURN
     SELECT 'MYR (RM)' Name,
            2 Id
     UNION
     SELECT 'USD ($US)',
            35
     UNION
     SELECT 'USD (US$)',
            3
     UNION
     SELECT 'USD (UT)',
            64
     UNION
     SELECT 'USD (IRR)',
            40
     UNION
     SELECT 'USD (NTD)',
            17
     UNION
     SELECT 'USD (Yen)',
            16
     UNION
     SELECT 'EUR (EURO)',
            6
     UNION
     SELECT 'HKD (HK$)',
            5
     UNION
     SELECT 'HKD (HKK)',
            67
     UNION
     SELECT 'CNY (RMB)',
            13
     UNION
     SELECT 'THB (THB)',
            43
     UNION
     SELECT 'IDR (DDD)',
            47
     UNION
     SELECT 'IDR (IDD)',
            33
     UNION
     SELECT 'IDR (IDR)',
            34
     UNION
     SELECT 'IDR (IN)',
            15
     UNION
     SELECT 'IDR (IND)',
            22
     UNION
     SELECT 'KRW (Won)',
            45
     UNION
     SELECT 'MMK (MKK)',
            70
     UNION
     SELECT 'MMK (MMK)',
            69
     UNION
     SELECT 'SGD (SD$)',
            1
     UNION
     SELECT 'GBP (GBP)',
            12
     UNION
     SELECT 'THB (TB)',
            4
     UNION
     SELECT 'INH (INH)',
            51
     UNION
     SELECT 'INR (INR)',
            61
     UNION
     SELECT 'UUS (UUS)',
            20
     UNION
     SELECT 'YNG (YNG)',
            72;
GO
GRANT SELECT ON f_Nap_WinLimit_CreditCurrencySel TO [bodbAdminNet];
GO