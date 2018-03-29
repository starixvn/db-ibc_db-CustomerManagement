/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_MT_BetTypeSel]
	@Sporttype	INT = NULL
AS

/*
Created: 
Task : Retrieve Customer Setting Bet types.
DB: DBCUST.CustDB
Original:

Revisions:
	- 20091201@Kiwi: Union with CustSetting3rd.
	- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB, use temp table for bettype)
    - 20151021@Billy: Add support for DCS -- UNION with ProductSettingDetail
	- 20160409@Winnie: Fix bug Bug #56129: [NAP] should show only ".: ALL :." option in bettype drop down list
	- 20160801@Elodie: Modify code to get only bettype for PT
	- 20180326@Winnie: Customer Setting - urgent fix to support for long bettype name. [RedmineID: #91216]
Parameters Explanation:  
	
*/

SET NOCOUNT ON

IF (@Sporttype IS NOT NULL) AND ((SELECT COUNT( DISTINCT BetType) FROM ProductSettingDetail(NOLOCK) where SportType=@Sporttype AND SettingType=1) =1)
BEGIN
SELECT NULL AS bettype, NULL AS typenamee 
WHERE 1=0
RETURN
END
----- 20150610@Kos -------------------
	BEGIN TRY			
		SELECT *
		INTO #tmp_Bettype
		FROM dbo.f_GetSportTypeBetTypeGameType(2,'DBAGE')	
	END TRY
	BEGIN CATCH		
		IF OBJECT_ID(N'tempdb..#tmp_Bettype') IS NOT NULL
		BEGIN
			TRUNCATE TABLE #tmp_Bettype
			INSERT INTO #tmp_Bettype
			SELECT *
			FROM dbo.f_GetSportTypeBetTypeGameType(2,'DBTXN')	
		END
	END CATCH
----- 20150610@Kos -------------------

SELECT DISTINCT t.bettype, b.Name 
FROM 
	(	SELECT cs.custid, cs.bettype, cs.sporttype FROM CustSetting cs WITH (NOLOCK)
		UNION 
		SELECT cs3rd.custid, cs3rd.bettype, cs3rd.sporttype FROM CustSetting3rd cs3rd WITH (NOLOCK)
        UNION
        SELECT 73104, psd.BetType, psd.SportType FROM ProductSettingDetail psd WITH(NOLOCK)
        WHERE psd.SettingType = 1
	 ) t
	INNER JOIN #tmp_Bettype b ON t.bettype = b.ID
WHERE t.custid IN( 73104) AND t.sporttype = ISNULL(@sporttype, t.sporttype)
ORDER BY t.bettype



GO
GRANT EXECUTE ON [dbo].[Acc_MT_BetTypeSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MT_BetTypeSel] TO [vnteam]