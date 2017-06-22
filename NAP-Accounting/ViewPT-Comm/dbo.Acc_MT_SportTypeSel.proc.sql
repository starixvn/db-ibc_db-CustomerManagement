ALTER PROCEDURE [dbo].[Acc_MT_SportTypeSel]
AS 

/*
	Created: 
	Task : Retrieve Customer Setting Sporttypes.
	DB: DBCUST.CustDB
	Original:

	Revisions:
		- 20091201@Kiwi: Union with CustSetting3rd.
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB, use temp table for sports)
        - 20151021@Billy: Add support for DCS -- UNION with ProductSettingDetail
*/

SET NOCOUNT ON

----- 20150610@Kos -------------------
DECLARE @tmp_Sports TABLE (SportType TINYINT, SportName NVARCHAR(50))
	
BEGIN TRY
	INSERT INTO @tmp_Sports (SportType, SportName)
	SELECT SportType, SportName FROM DBAGE.bodb02.dbo.Sports WITH (NOLOCK)
END TRY
BEGIN CATCH
	INSERT INTO @tmp_Sports (SportType, SportName)
	SELECT SportType, SportName FROM DBTXN.bodb02.dbo.Sports WITH (NOLOCK)
END CATCH
----- 20150610@Kos -------------------

SELECT DISTINCT t.sporttype, s.sportname 
FROM 
	(	SELECT cs.custid, cs.sporttype FROM CustSetting cs WITH (NOLOCK)
		UNION 
		SELECT cs3rd.custid, cs3rd.sporttype FROM CustSetting3rd cs3rd WITH (NOLOCK)
        UNION
        SELECT 73104, psd.SportType FROM ProductSettingDetail psd WITH(NOLOCK)
        WHERE psd.SettingType IN (1,3)
	 ) t
	INNER JOIN @tmp_Sports s ON t.sporttype = s.sporttype
WHERE t.custid = 73104 
ORDER BY t.sporttype


GO
GRANT EXECUTE ON [dbo].[Acc_MT_SportTypeSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MT_BetTypeSel] TO [vnteam]