/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_CustomerLockSuspendSel
	@DeniedList NVARCHAR(MAX)=NULL
AS
/*
	Created: 20200216@Elodie
	Task : Select customer who upline don''t allow to unsuspend
	DB: DBCUST/CustDB

	Revisions:
		- 20200216@Elodie: Initial SP [Redmine:#128541]
		- 20210510@Tina: Lock account & indirect close account [redmine: #148600]
		- 20240523@Tacy: NAP - Permission controls on real currency [redmineID: #202523]
		- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)

	IF ISNULL(@DeniedList,'')<>''
	BEGIN
		--get deny site
		INSERT INTO @tmp (siteid, site, SpecialGroup)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Site'
	
		--get deny currency
		INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Exchange'
	END

	SELECT ci.custid, ci.username, ci.roleid,
		--1:Open, 2:Suspended, 3:Closed
		CASE WHEN ci.Enabled = 1 THEN CASE WHEN ISNULL(cps.closed,ci.closed) = 1 THEN 'Closed' WHEN ISNULL(cps.reject,ci.reject) = 1 THEN 'Suspended' ELSE 'Open' END ELSE 'Disabled' END AS CustStatus						
	FROM CustSuspendLockUpd cs WITH (NOLOCK)
		INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON cs.custid = ci.custid
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.custid=cs.CustId
		CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid 
								) AS cps	
	WHERE  c.Site NOT IN (SELECT Site FROM @tmp)
		AND c.currency NOT IN (SELECT exchangeID FROM @tmpExchange)
	ORDER BY ci.username, ci.roleid
END

