/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
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
		- 20170808@Winnie: Change Data Type of Sporttype [RedmineID: #73545]
		- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
		- 20180711@Elodie: Remove setting type 3 of DCS (commission) [RedmineID: #97675]
		- 20181214@Johnson: Exclude Happy 5 [Redmine: #104006]
*/

SET NOCOUNT ON

----- 20150610@Kos -------------------
DECLARE @tmp_Sports TABLE (SportType SMALLINT, SportName NVARCHAR(50))
	
BEGIN TRY
	INSERT INTO @tmp_Sports (SportType, SportName)
	SELECT SportType, SportName FROM DBAGE.bodb02.dbo.Sports WITH (NOLOCK)
	WHERE Sporttype NOT IN(151,152,153,154,206,252,253,164)
END TRY
BEGIN CATCH
	INSERT INTO @tmp_Sports (SportType, SportName)
	SELECT SportType, SportName FROM DBTXN.bodb02.dbo.Sports WITH (NOLOCK)
	WHERE Sporttype NOT IN(151,152,153,154,206,252,253,164)
END CATCH
----- 20150610@Kos -------------------

SELECT DISTINCT t.sporttype, s.sportname 
FROM 
	(	SELECT cs.custid, cs.sporttype FROM CustSetting cs WITH (NOLOCK)
		UNION 
		SELECT cs3rd.custid, cs3rd.sporttype FROM CustSetting3rd cs3rd WITH (NOLOCK)
        UNION
        SELECT 73104, psd.SportType FROM ProductSettingDetail psd WITH(NOLOCK)
        WHERE psd.SettingType = 1
	 ) t
	INNER JOIN @tmp_Sports s ON t.sporttype = s.sporttype
WHERE t.custid = 73104 
ORDER BY t.sporttype


GO
