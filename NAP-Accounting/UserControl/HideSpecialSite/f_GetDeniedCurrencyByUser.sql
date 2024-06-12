/*<info serverAlias="DBPOL-NAP_UserControl" selecters="wsv_nap,wsv_xnap,wsv_alp,wsv_alpv,wsv_lap" viewers="" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION	[dbo].[f_GetDeniedCurrencyByUser] (@UserID INT)
RETURNS TABLE
AS

/*
	Created: 20240412@Tacy
	Task: Check permission: access real currency
	Database: DBPOL/NAP_UserControl
	
	Revision:
		- 20240412@Tacy:  Create function  [Redmine: #202523]
	
	Param's Explanation:
*/
RETURN
	SELECT e.ExchangeId, e.currency, OfferSite
	FROM CustDB.dbo.exchange e WITH (NOLOCK)
	WHERE e.ExchangeId NOT IN (20,72)	--UUS, YNG (test currency)
		AND NOT EXISTS (SELECT 1
						FROM acc_memberpolicy mp WITH (nolock)
							INNER JOIN acccustomer ac WITH (nolock) ON ac.custid = mp.custid
							INNER JOIN acc_functioninfo fi WITH (nolock) ON mp.funcid = fi.funcid
							INNER JOIN acc_grouppolicy gp WITH (nolock) ON gp.groupid = ac.groupid AND gp.funcid = mp.funcid
						WHERE mp.custid = @UserID
							AND (Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.funcrender,0) > 0
							AND fi.System = 'ACCOUNTING'
							AND fi.FuncName = '[AccessRealCurrency]'							
						)
GO