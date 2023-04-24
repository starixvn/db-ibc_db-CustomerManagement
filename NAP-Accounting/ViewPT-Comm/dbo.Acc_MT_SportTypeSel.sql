/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_MT_SportTypeSel]
 @SettingStatus TINYINT = 0
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
		- 20190726@Eden: Exclude Poker Games, Bullfighting,Colosus Bet, Lucky 3 [Redmine: #117439]
		- 20191101@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
		- 20200615@Elodie: Implement new setting type 18 [Redmine: #135363]
		- 20221006@Winfred: Don't show setting of products which are not offered to a credit site [Redmine: #174744] 
		- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]
		- 20221123@Elodie: Migrate NG and Keno to DCS structure [Redmine: #179711]
*/

SET NOCOUNT ON

----- 20150610@Kos -------------------
DECLARE @tmp_Sports TABLE (SportType SMALLINT, SportName NVARCHAR(50))

INSERT INTO @tmp_Sports (SportType, SportName)
EXEC DBACC.bodb02.dbo.Acc_SporttypeSel @Mode=1

DELETE t 
FROM @tmp_Sports t
WHERE Sporttype IN (151,152,153,154,206,252,253,164,160,163,207,204,50,206)

SELECT DISTINCT t.sporttype, s.sportname
FROM 
	(	SELECT cs.custid, cs.sporttype FROM CustSetting cs WITH (NOLOCK)
		UNION 		
		SELECT 73104,SportType FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,1,@SettingStatus)
		UNION
		SELECT 73104,SportType FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,18,@SettingStatus)
	 ) t
	INNER JOIN @tmp_Sports s ON t.sporttype = s.sporttype
WHERE t.custid = 73104 
ORDER BY t.sporttype
GO
