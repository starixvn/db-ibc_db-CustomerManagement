/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelAllInfo]
	@username VARCHAR(50),
	@uplineid INT = -1,
	@isInternalAgent BIT = 0
AS
/*
	Created: 20090122@nqminh
	DB: DBAGE/bodb02
	Task: Left menu - Search customer - All Info

	Revisions:
		- 20090122@[Reviewer]: [Description of revision]    
		- 20090506@[Simon]: Calculate outstanding.
		- 20100429@Terry: Get status for Open Tote
		- 20100710@Simon: Remove firstname + ' ' + lastname = @username
		- 20100918@Jacob: Add column DisableBingo, SyncBingo, uplineDisableBingo
		- 20100924@Terry: Add column DisabledNumber, UplineDisabledNumber
		- 20101224@Johnson: Apply new arrange of bettype
		- 20110119@Simon: Select one more column upLineEnabledMa to disabled upline exactly.
		- 20110317@Lukas: move HR's status to another SP
		- 20110623@Sophia: Do not allow search by nickname 
		- 20110721@Sophia: Add parameter @isInternalAgent
		- 20110823@Sophia: Count Negative stake as positive turnover
		- 20111018@Tom: 1. Add P2P Transfer (23101)/Outstanding (23102)
						2. Remove variable @ABSDate ('2011-09-01')	
		- 20120206@Sophia: Get DisableLiveCasino, SyncLiveCasino for Live Casino
		- 20120815@Sophia: Get DisableVirtualSports, HideVirtualSports
		- 20120926@Sophia: Get DoubleCommLosing
		- 20121110@viet: get custinfo data base on uplineid instead of username only, to reduce scan
		- 20130522@Johnson: get Poker held funds on member level and disableP2P status (pending)
		- 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
		- 20140303@Kathy: - get HideKeno column [Redmine:#12691]
						  - modify formula of Outstanding amount to be calculated based on table Bettrans and TransLog [Redmine:#11550]
		- 20140822@Logan:   Add status for Esports [Redmine: #20661]			  
		- 20150422@Elodie: Add Gold Deluxe product [Redmine:#34486]
		- 20150612@Kathy: Migrate custDB to new server DBCust(Get credit from DBCust.CustDB) [Redmine:#36216]
		- 20150803@Elodie: Get DisableDownlinesGoldDeluxe field [Redmine:#38741]
		- 20150707@Jim: exclude Metric Gaming running ticket from bettrans (Feature #38789)
		- 20150825@Helen: Colossus Bet - [Redmine: #41264]
		- 20151014@Helen: Customer Setting for Sportsbook 2- [Redmine: #44604]
		- 20151214@Percy: Do not check ticket running of Cock Fighting at bettrans table, because of the translog [Redmine: #48601]
		- 20160112@Percy: Expand new bettype for RNG Casino [Redmine: #48283]
		- 20160128@Percy: Support new sport Cricket [Redmine: #50027]
		- 20160204@Percy: Support new product AllBet [Redmine: #50605]
		- 20160413@Percy: Support Voidbridge single wallet [Redmine: #55259]
		- 20161028@Percy: Support Fishing World [RedmineID: #65731]
		- 20170421@Helen: Enable Downline FishingWorld checkbox is ticked & disabled control although Member is disabled [RedmineID: #74421]
		- 20170601@Elodie: Migrate Inspired VS to DCS structure, add BetRadar VS product [Redmine: #77274]
		- 20170517@Winnie: Apply color for closed accounts  - [Redmine:74494]
		- 20170703@Percy: Hotfix formula today/yesterday balance when getting data from bettrans [RedmineID: #79236]
		- 20171020@Percy: Apply core SP [RedmineID: #84690]
		- 20180125@Winnie: Hide inactive products [RedmineID: #86086]	
		- 20180918@Winnie: Esports Product - [Redmine: #101526]	
		- 20180611@Elodie:	Move all status of customer to Age_CustomerSelAllStatus SP [RedmineID: #58776]	
							Move all balance info of customer to Age_CustomerBalanceSel SP 
							Move total downline info of customer to Acc_CustomerSelList SP 
		- 20190508@Elodie: Allow to search nickname [Redmine: #113044]
		- 20190412@Johnson: add suspendinfo [redmine: #105587]					
		- 20191008@Johnson: remove credit info[Redmine: #121538]		
		- 20191225@Johnson: enhance sp get max transdate [redmine: #125894]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20210824@Elodie: Implement Protection Code [Redmine: #160151]
		- 20211124@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
	Param's Explanation:
		• @username: username of customer that need to be viewed.   
		• @uplineId: the ID of the upline.
*/

BEGIN
    SET NOCOUNT ON

    DECLARE @custid INT, @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT
    DECLARE @ClosedReason TINYINT, @transdate DATETIME, @upLineEnabled BIT,
			@isDirectSuspend BIT = 0, @transid BIGINT, @Locked TINYINT, @ProtectionMode BIT, @transferid BIGINT,
			@isDirectClosed BIT

    SELECT @username = RTRIM(LTRIM(@username))

    SELECT @custid = custid, @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
	FROM custinfo WITH(NOLOCK)
    WHERE username = @username 
	   AND (srecommend = @uplineid OR mrecommend = @uplineid OR recommend = @uplineid)

    ------20110721: If @isInternal = 1 then searching by nickname, else do not allow
    IF (@custid IS NULL) AND @isInternalAgent = 1
    BEGIN
	    SELECT @custid = custid , @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
        FROM customer WITH (NOLOCK)
        WHERE username2 = @username
	       AND (srecommend = @uplineid OR mrecommend = @uplineid OR recommend = @uplineid)
    END
	
	IF (@custid IS NULL) AND @isInternalAgent = 0
	BEGIN
	    SELECT @custid = custid , @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
        FROM customer WITH (NOLOCK)
        WHERE username2 = @username
			AND ((srecommend = @uplineid AND roleid = 3)
				OR (mrecommend = @uplineid AND roleid = 2)
				OR (recommend = @uplineid AND roleid = 1))
    END
    --end
	
    --Check valid access!
    IF @custid IS NOT NULL
	BEGIN
		IF (@recommend <> @uplineid AND @mrecommend <> @uplineid AND @srecommend <> @uplineid) RETURN
    	
		IF @roleID=1 --for member
		BEGIN	
			--Upline
			SELECT	@upLineEnabled = ISNULL(Enabled, 0)
			FROM custinfo WITH(NOLOCK)
			WHERE custID = @recommend	
		
			SELECT @transdate = MAX(x.transdate) 
			FROM
			(
				SELECT MAX(transdate)  AS transdate
				FROM bettrans WITH (NOLOCK) WHERE custid = @custid
				UNION ALL
				SELECT MAX(transdate)  AS transdate
				FROM dbo.transfer WITH (NOLOCK) WHERE custid = @custid
			) x
		END 
		ELSE IF @roleID = 2 --for agent
		BEGIN
			--Upline
			SELECT	@upLineEnabled = ISNULL(Enabled, 0)
			FROM custinfo WITH(NOLOCK)
			WHERE custID = @mrecommend	
			
			SELECT @transid = MAX(transid) FROM bettrans WITH (NOLOCK) 
			WHERE recommend = @custid
			OPTION(OPTIMIZE FOR	UNKNOWN)

			SELECT @transferid = MAX(transid) FROM dbo.transfer WITH (NOLOCK) 
			WHERE recommend = @custid
				AND bettype NOT IN (20000,19999)
			
			SELECT @transdate = MAX(transdate)
			FROM 
			(
				SELECT  transdate FROM bettrans WITH (NOLOCK) WHERE transid = @transid
				UNION ALL
				SELECT  transdate FROM dbo.transfer WITH (NOLOCK) WHERE transid = @transferid
			) x
		END
		ELSE IF @roleID = 3 --for master
		BEGIN
			--Upline
			SELECT	@upLineEnabled = ISNULL(Enabled, 0)
			FROM custinfo WITH(NOLOCK)
			WHERE custID = @srecommend	

			SELECT @transid = MAX(transid) FROM bettrans WITH (NOLOCK) 
			WHERE mrecommend = @custid
			OPTION(OPTIMIZE FOR	UNKNOWN)

			SELECT @transferid = MAX(transid) FROM dbo.transfer WITH (NOLOCK) 
			WHERE mrecommend = @custid
				AND bettype NOT IN (20000,19999)
			
			SELECT @transdate = MAX(transdate)
			FROM 
			(
				SELECT  transdate FROM bettrans WITH (NOLOCK) WHERE transid = @transid
				UNION ALL
				SELECT  transdate FROM dbo.transfer WITH (NOLOCK) WHERE transid = @transferid
			) x
		END
    
		IF @roleid=1
			SELECT @ClosedReason=ClosedReason FROM DBACC.bodb02.dbo.CustLoginInfo_Member WITH(NOLOCK) WHERE Custid = @custid
		ELSE
			SELECT	@ClosedReason=ClosedReason, 
					@ProtectionMode = ISNULL(IsProtectedMode,0)
			FROM DBACC.bodb02.dbo.CustLoginInfo WITH(NOLOCK) 
			WHERE Custid = @custid	
	END
	
	--check suspend status is direct or not
	SELECT @isDirectSuspend = (SELECT suspendinfo FROM dbo.f_GetSuspendInfoStatus(@roleid,SuspendInfo)),
		@isDirectClosed = (SELECT suspendinfo FROM dbo.f_GetSuspendInfoStatus(@roleid,CloseInfo)),
		@Locked = ISNULL(Locked,0)
	FROM dbo.CustProductStatus WITH(NOLOCK)
	WHERE custid = @custid
	
	-------------------------------------------------------------------------
    SELECT	c.custid, ci.roleid, c.username, c.username2, c.firstname, c.lastname, c.phone, c.mobilephone, c.fax, ISNULL(@ClosedReason,0) AS ClosedReason, 
			ci.enabled,	ISNULL(@upLineEnabled,0) AS upLineEnabled, cs.closed, 
			cs.reject AS suspended,
			ISNULL(@isDirectSuspend,0) as isDirectSuspend,
			ISNULL(@isDirectClosed,0) as isDirectClosed,
			CASE WHEN c.roleid = 1 THEN c.custid ELSE NULL END AS memberID,
			CASE WHEN c.roleid = 1 THEN c.username ELSE NULL END AS memberName,	
			a.custid AS agentID,
			a.username AS agentName,	
			m.custid AS masterID,
			m.username AS masterName,
			s.custid AS superID,
			s.username AS superName,
			c.creatdate, lastlogged, iplogin AS lastloginip, pwdexpiry, @transdate AS lastTxn, @Locked AS Locked, 
			@ProtectionMode AS IsProtectedMode			
    FROM custinfo ci WITH (NOLOCK)
		INNER JOIN customer c WITH (NOLOCK) ON c.custid = ci.custid
		CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cs	
	    LEFT JOIN custinfo a WITH (NOLOCK) ON c.recommend = a.custid
	    LEFT JOIN custinfo m WITH (NOLOCK) ON c.mrecommend = m.custid
	    LEFT JOIN custinfo s WITH (NOLOCK) ON c.srecommend = s.custid
    WHERE c.custid = @custid

END	
GO