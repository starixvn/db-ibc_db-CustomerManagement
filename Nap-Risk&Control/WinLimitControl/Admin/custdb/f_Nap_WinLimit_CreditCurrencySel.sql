/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_Nap_WinLimit_CreditCurrencySel]
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
	-20170313@Jacob: Risk & Control - Phase 3A [#72604].
	-20180309@Johnson: add new 2 currencies KHR, LIR [#91574]

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
            72
     UNION 
	 SELECT 'KHR (KHR)',
			71
	 UNION 
	 SELECT 'LIR (LIR)',
			73;
	 		            

GO