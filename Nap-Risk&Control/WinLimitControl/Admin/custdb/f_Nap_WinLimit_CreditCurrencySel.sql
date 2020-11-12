/*<info serverAlias="DBCUST-CustDB" selecters="bodbAdminNet" viewers="" isFunction="1" isNested="1"></info>*/

ALTER FUNCTION dbo.f_Nap_WinLimit_CreditCurrencySel()
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
	-20190516@Robert: CWL - New site CN88 integration[#112218]
	-20201106@Robert: NAP Risk & Control Site - Remove un-used currencies from related dropdownlist [140386]


Example:
SELECT * FROM [f_Nap_WinLimit_CreditCurrencySel]()
*/
RETURN
SELECT CASE
		 WHEN exchangeid = 20
		 THEN 'UUS'
		 ELSE Code
	  END+' ('+currency+')' AS Name
	, exchangeid AS Id
FROM exchange WITH (NOLOCk)
WHERE exchangeid NOT IN(27, 28) AND OfferSite IN (0,1) AND IsActive = 1
GO