/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet" viewers="vnteam" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[Acc_CustomerSelAllInfo]
	@username VARCHAR(30),
	@CheckCustId TINYINT = 0
AS

/*
Created: 
Task : Get move bet day, balanceup day
DB: DBAGE/bodb02
Original:Accounting site

Revisions:
	- 20080925@PhuongDao: Calculate Balance with correct date instead of date - 1 
		- Add yesterday balance info
		- Web calculation (for current balance & yesterday balance):
		- Balance (general) = self cash + total downline cash
		- Agent balance = his cash + total cash of his members
		- Master balance = his cash + total cash of his agents + total cash of his members
		- Super balance = his cash + total cash of his masters  + total cash of his agents + total cash of his members
	- Dung@20081021 : Get ci.danger field instead of ci.dangercust in General info block	
	- Khoa@20090312 : Get ci.autosuspend field 
	- Qui@20090317 : Get ci.disablecasino, ci.synccasino field
	- 20090320@PhuongDao: Get the auto-suspend status of the upline. 
    - Shifu@20090324: Get c.site, customer's site information
	- 20090325@PhuongDao: Get the HR, FI status of Downlines under the customer
	- 20090401@Shifu: Get member website base agent website
	- 20090701@Phuc: get disableautoMPT.
	- 20090717@pluto: get danger2, danger3.
	- 20090729@Simon: get Status DisableOutRight.
	- 20090731@pluto:get Enabled status: Member, Agent, Master, Super
	- 20100505@pluto:get DisableDownlinesOpenTote status
	- 20100608@pluto:get DisableDownlinesCasino status
	- 20100619@Thien: get custID FROM Username on DB06, via f_GetCustIDFromUsername function
	- 201000909@Ethan:get  DisableBingo, DisableDownlinesBI, syncbingo, DisableDownlinesNumber, DisableNumber  status
	- 20101007@Henry: Change column transid FROM INT to BIGINT
	- 20101015@Ethan: Get Limited Per IP value @LimitPerIP + SelectedBetting
	- 20110315@Johnson: remove get status Horse Racing
	- 20110429@Lukas: get downline statistics (number of Active, closed, suspended)
	- 20110516@Lukas: re-arrange bettype
	- 20110718@Sophia: because username2 add prefix 'Agency$', so hide the prefix WHEN SELECT username2
	- 20110721@Sophia: remove prefix 'Agency$' WHEN SELECT username2
	- 20110822@Elly: - Correct Turnover of sports book since Sep 01, 2011
	- 20120131@Johnson: Get DisableLiveCasino, SyncLiveCasino status, currencyid
	- 20120302@Jim: add more isBA column in General info return
	- 20120504@Dom: add more IsDeposit column in General info return
	- 20120423@Lukas: check if roleid > 4 THEN return
	- 20120815@Sophia: Get DisableVirtualSports, HideVirtualSports, DisableDownlinesVirtualSports
	- 20120822@Elodie: Get Abnormal field
	- 20120927@Johnson: Get double comm losing status
	- 20130121@Dan: change linked server DB06 to DBARC, DB052 to DBLIC
	- 20130322@Ethan:Get column NicknameLoginOnly for Super, Master, Agent
	- 20130422@Johnson: get field LastChangedSecurityCodeDate
	- 20130719@Elodie: Correct link server DBACC instead of DBARC
	- 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
	- 20131108@Elodie: Splitting bodb02 INTo CustDB (call CustLoginInfo, CustLoginInfo_Member by link server DBTXN.CustDB)
	- 20140305@Dom: Change Outstanding formula to get FROM Bettrans AND Translog for Keno tickets
	- 20140820@Logan:   Add status for E-Sports [Redmine: #20531]
	- 20140912@Logan:   Add status of Direct/Indirect Account [Redmine: #15267]
	- 20141120@Johnson: correct Last transaction date for super [Redmine: #26006]
	- 20141226@Johnson: Separate virtual rate by sporttype, bettype [Redmine: #25840]			
	- 20150422@Elodie: Add Gold Deluxe product [Redmine:#34486]
	- 20150606@Kathy: Migrate custDB to new server DBCust(Get credit from DBCust.CustDB) [Redmine:#36216]
	- 20150707@Elodie: Add Super Live product [Redmine: #35776]
	- 20150707@Jim: exclude Metric Gaming running ticket from bettrans (Feature #38789)
	- 20150825@Helen: Colossus Bet - [Redmine: #41264]
	- 20151001@Percy: AG Casino & Microgaming - Outstanding Info [Redmine: #43765]
	- 20151014@Helen: Customer Setting for Sportsbook 2- [Redmine: #44604]
	- 20151030@Percy: AG Casino & Microgaming - Outstanding Info for new Sporttype [Redmine: #46450]
	- 20151112@Percy: AG Casino & Microgaming - Fix bug for new Sporttype [Redmine: #47441]
	- 20151210@Percy: Add new product: Cockfighting Sabong [Redmine: #48836]
	- 20160108@Percy: Expand new bettype for RNG Casino [Redmine: #48285]
	- 20160202@Percy: Support new sport Cricket [Redmine: #50028]
	- 20160215@Percy: Support new product AllBet [Redmine: #50588]
	- 20160329@Francis: Change to use inline function instead of table variable to enhance performance
	- 20160412@Percy: support Voidbridge single wallet [Redmine: #55258]
	- 20161019@Percy: Support show OTP info [RedmineID: #64871]
	- 20161028@Percy: Support Fishing World [RedmineID: #65734]
	- 20170421@Helen: Enable Downline FishingWorld checkbox is ticked & disabled control although Member is disabled [RedmineID: #74421]
	- 20170420@Helen:  Add Extra information for Direct Accounts, for NAP only - [Redmine:72339]
	- 20170515@Helen:  Add Extra information for Direct Accounts, for NAP only Change Request - [Redmine:72339]
	- 20170517@Winnie: Apply color for closed accounts  - [Redmine:74494]
	- 20170612@Winnie: New agent cash balance - [Redmine:74291]
	- 20170601@Elodie: Migrate Inspired VS to DCS structure, add BetRadar VS product [Redmine: #77274]
	- 20170629@Winnie: Offer Enable/Disable GoldDeluxe [RedmineID: #72957]
	- 20170601@Elodie: Migrate Inspired VS to DCS structure, add BetRadar VS product [Redmine: #77274]
	- 20170721@Winnie: EXT - Support Security Code on Customer List RedmineID: #78298
	- 20171107@Vicky: Support to search customer id on Left panel [RedmineID: #86134]
	- 20171018@Percy:
		1. Move code of balance part into new nested sp [RedmineID: #73606]
		2. Change yesterday balance formula + Integrate Bullfighting [RedmineID: #84692]
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]  
Param's Explanation:
	@username: username want to get all info related
*/		

BEGIN
    SET NOCOUNT ON

    DECLARE @custid INT
          , @uplineid INT
          , @roleid TINYINT
          , @UsedCredit MONEY     
          , @DisableDownlinesCS BIT       
          , @DisableDownlinesNumber BIT          
          --, @DisableDownlinesVirtualSports BIT
          , @DisableDownlinesEsports BIT
          , @DownlinesSelectedBetting BIT
		  , @DisableDownlinesGoldDeluxe BIT
		  , @IsSyncUplineGoldDeluxe BIT
		  , @DisabledUplineGoldDeluxe BIT
		  , @DisableDownlinesColossusBet BIT 
		  , @DisableDownlinesSuperLive BIT
          , @IsInternal BIT
          , @LimitPerIP TINYINT
          , @SelectedBetting BIT
          , @NicknameLoginOnly BIT
          , @LastChangedSecurityCodeDate DATETIME
		  , @HasDownline BIT = 0
		  , @ClosedReason TINYINT
		  ,	@UplineHasSecurityCode	BIT=0

    DECLARE @membersite VARCHAR(10)
    DECLARE @TotalMAgentActive INT,
		    @TotalMAgentClosed INT,
		    @TotalMAgentSuspended INT,
		    @TotalAgentActive INT,
		    @TotalAgentClosed INT,
		    @TotalAgentSuspended INT,
		    @TotalMemberActive INT,
		    @TotalMemberClosed INT,
		    @TotalMemberSuspended INT,
			@IsAllDayBalTransfer BIT

    DECLARE @IsHideDirectStatus BIT = 0
          , @IsCheckedDirectStatus BIT = 0
          , @IsDisabledDirectStatus BIT = 0

    DECLARE @NegativeBetEffectiveDate DATETIME
    SET @NegativeBetEffectiveDate='2011-09-01'

	DECLARE @netPosition MONEY = 0 -- for member
	
    --Get CustID FROM DB06, WHERE got index on Username AND Username2 or CustID
    EXEC @custid = DBACC.bodb02.dbo.f_GetCustIDFromUsernameOrCustId @username, @CheckCustId

    IF @custid is NULL
    BEGIN
	    RETURN
    END
    ELSE
    BEGIN
	    SELECT @roleid = roleID
	      FROM custinfo WITH(NOLOCK)
	     WHERE custid = @custid
    END

	IF @roleid = 1
		-- Net Balance
		SELECT @netPosition = ISNULL(SUM(Credit - Debit), 0) FROM DBTXN.bodb02.dbo.BalNetPosition WITH (NOLOCK) WHERE custid = @custid

    IF @roleid > 4
	    RETURN
    -----------------------------	

    SELECT @DisableDownlinesCS = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableCasino,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND DisableCasino = 1)
										      WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableCasino,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND DisableCasino = 1) 											 
										      WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableCasino,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid AND DisableCasino = 1) 											
										      ELSE 0 END

    SELECT @DisableDownlinesNumber = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableNumber,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND DisableNumber = 1)
										      WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableNumber,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND DisableNumber = 1) 											 
										      WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableNumber,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid AND DisableNumber = 1) 											 
										      ELSE 0 END	
 
    										  
    --SELECT @DisableDownlinesVirtualSports = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableVirtualSports,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND DisableVirtualSports = 1)
				--						     WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableVirtualSports,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND DisableVirtualSports = 1) 											 
				--						     WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableVirtualSports,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid AND DisableVirtualSports = 1) 											 
				--						     ELSE 0 END

    SELECT @DisableDownlinesEsports = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableEsports, 0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND DisableEsports = 1)
											WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableEsports, 0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid  AND DisableEsports = 1)
											WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableEsports, 0) FROM custInfo WITH(NOLOCK) WHERE recommend = @custid  AND DisableEsports = 1)
											ELSE 0 END

    SELECT @DisableDownlinesGoldDeluxe = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableGoldDeluxe,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND DisableGoldDeluxe = 1)
										      WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableGoldDeluxe,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND DisableGoldDeluxe = 1) 											 
										      WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableGoldDeluxe,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid AND DisableGoldDeluxe = 1) 											 
										      ELSE 0 END

	SELECT @DisableDownlinesColossusBet = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableColossusBet,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND DisableColossusBet = 1)
										      WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableColossusBet,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND DisableColossusBet = 1) 											 
										      WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableColossusBet,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid  AND DisableColossusBet = 1) 											 
										      ELSE 0 END	
										      
	SELECT @DisableDownlinesSuperLive = CASE @roleid WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableSuperLive,0) FROM custInfo WITH(NOLOCK) WHERE srecommend = @custid AND DisableSuperLive = 1)
										      WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableSuperLive,0) FROM custInfo WITH(NOLOCK) WHERE mrecommend = @custid  AND DisableSuperLive = 1) 											 
										      WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableSuperLive,0) FROM custInfo WITH(NOLOCK) WHERE recommend  = @custid  AND DisableSuperLive = 1) 											 
										      ELSE 0 END												  									  										  							  
    -------------------------------------------------------------------------
    DECLARE @IsDeposit BIT --Identify deposit customer
	    SET @IsDeposit = 0

    IF @roleid in (2,3,4)
    BEGIN
	    IF EXISTS (SELECT 1 FROM dbo.Customer c WITH(NOLOCK)
							    INNER JOIN dbo.Site s WITH(NOLOCK) ON c.site = s.site 
					    WHERE custid = @custid
						      AND isLicensee =1)
	    SET @IsDeposit =1
    	
	    SELECT @LastChangedSecurityCodeDate = LastChangedSecurityCodeDate,@ClosedReason=ClosedReason
	    FROM DBCUST.CustDB.dbo.CustLoginInfo WITH(NOLOCK)
	    WHERE custid = @custid
    END

    --Get member site
    IF @roleid = 1
    BEGIN
	    SELECT	@membersite = c.site, @uplineid = c.custid
	    FROM	customer c WITH(NOLOCK)
		    INNER JOIN custinfo ci WITH(NOLOCK) ON c.custid = ci.recommend
	    WHERE ci.custid = @custid
    	SELECT @IsSyncUplineGoldDeluxe=CASE WHEN HideGoldDeluxe=0 THEN 1 ELSE 0 END,@DisabledUplineGoldDeluxe=ISNULL(DisableGoldDeluxe,1)  FROM custInfo WITH(NOLOCK) WHERE custid=@uplineid

	    IF EXISTS (SELECT 1 FROM dbo.Customer c WITH(NOLOCK)
							    INNER JOIN dbo.Site s WITH(NOLOCK) ON c.site = s.site 
					    WHERE custid = @uplineid
						      AND isLicensee =1)

	    SET @IsDeposit =1
    	
	    SELECT @LastChangedSecurityCodeDate = LastChangedDate,@ClosedReason=ClosedReason
	    FROM DBCUST.CustDB.dbo.CustLoginInfo_Member WITH(NOLOCK)
	    WHERE custid = @custid
    END


    /*
    --Get INTernal status
    SELECT @IsInternal = CASE @roleid WHEN 4 THEN (SELECT ISNULL(IsInternal, 0) FROM custSuper WITH(NOLOCK) WHERE custid = @custid)
								      WHEN 3 THEN (SELECT ISNULL(IsInternal, 0) FROM custMaster WITH(NOLOCK) WHERE custid = @custid)
								      WHEN 2 THEN (SELECT ISNULL(IsInternal, 0) FROM custAgent WITH(NOLOCK) WHERE custid = @custid 		)
								      WHEN 1 THEN (SELECT ISNULL(IsInternal, 0) FROM custAgent WITH(NOLOCK) WHERE custid = @uplineid)
								      ELSE 0 END 	
    */								  

    SET @LimitPerIP = 0
    SET @NicknameLoginOnly=0
    SET @SelectedBetting = 0
    SET @IsInternal = 0
    SET @DownlinesSelectedBetting = 0

    IF @roleid = 4 --super
    BEGIN
		SELECT @UplineHasSecurityCode=1
		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3		
		SELECT @IsSyncUplineGoldDeluxe=1
		SELECT @DisabledUplineGoldDeluxe=0


	    SELECT @IsInternal = ISNULL(IsInternal, 0)
	         , @LimitPerIP = ISNULL(LimitPerIP, 0)
	         , @SelectedBetting = ISNULL(SelectedBetting, 0)
	         , @NicknameLoginOnly = ISNULL(NicknameLoginOnly, 0)
			 , @IsAllDayBalTransfer=ISNULL(IsAllDayBalTransfer, 0)
	      FROM custSuper WITH(NOLOCK)
	     WHERE custid = @custid

	    SELECT TOP 1 @DownlinesSelectedBetting = ISNULL(SelectedBetting, 0)
	      FROM custMaster WITH(NOLOCK)
	     WHERE custid IN (SELECT mrecommend 
	                        FROM custinfo WITH(NOLOCK)  
					       WHERE srecommend = @custid 
						     AND roleid = 3
				         )

	    SELECT @TotalMAgentActive =
	             ISNULL(SUM(CASE
	                          WHEN RoleID = 3 AND Closed = 0 AND ISNULL(reject, 0) = 0 THEN 1
	                          ELSE 0
	                        END
	                       ), 0
	                   )
	         , @TotalMAgentClosed =
	             ISNULL(SUM(CASE
	                          WHEN RoleID = 3 AND Closed = 1 THEN 1
	                          ELSE 0 END
	                       ), 0
	                   )
             , @TotalMAgentSuspended =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 3 AND ISNULL(reject, 0) = 1 AND Closed = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalAgentActive =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 2 AND Closed = 0 AND ISNULL(reject, 0) = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalAgentClosed =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 2 AND Closed = 1 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalAgentSuspended =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 2 AND ISNULL(reject, 0) = 1 AND Closed = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalMemberActive =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 1 AND Closed = 0 AND ISNULL(reject, 0) = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalMemberClosed =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 1 AND Closed = 1 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalMemberSuspended =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 1 AND ISNULL(reject, 0) = 1 AND Closed = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
	      FROM dbo.custInfo WITH(NOLOCK)
	     WHERE srecommend = @custid
    END								  
    ELSE IF @roleid = 3 --master
    BEGIN
		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2
		SELECT	@uplineid = srecommend    FROM	custinfo ci WITH(NOLOCK)    WHERE ci.custid = @custid
		SELECT @IsSyncUplineGoldDeluxe=CASE WHEN HideGoldDeluxe=0 THEN 1 ELSE 0 END,@DisabledUplineGoldDeluxe=ISNULL(DisableGoldDeluxe,1)  FROM custInfo WITH(NOLOCK) WHERE custid=@uplineid

	    SELECT @IsInternal = ISNULL(IsInternal, 0)
	         , @LimitPerIP = ISNULL(LimitPerIP, 0)
	         , @SelectedBetting = ISNULL(SelectedBetting, 0)
	         , @NicknameLoginOnly = ISNULL(NicknameLoginOnly, 0)
	      FROM custMaster WITH(NOLOCK)
	     WHERE custid = @custid
    	
	    SELECT TOP 1 @DownlinesSelectedBetting = ISNULL(SelectedBetting, 0)
	      FROM custAgent WITH(NOLOCK)
	     WHERE custid IN (SELECT recommend
	                        FROM custinfo WITH(NOLOCK)  
					       WHERE srecommend = @custid 
						     AND roleid = 2
				         )
	    SELECT
	    @TotalAgentActive = ISNULL(SUM(CASE WHEN RoleID = 2 AND Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
	    @TotalAgentClosed = ISNULL(SUM(CASE WHEN RoleID = 2 AND Closed = 1 THEN 1 ELSE 0 END), 0),
	    @TotalAgentSuspended = ISNULL(SUM(CASE WHEN RoleID = 2 AND ISNULL(reject,0) = 1 AND Closed = 0 THEN 1 ELSE 0 END), 0),
    	
	    @TotalMemberActive = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
	    @TotalMemberClosed = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 1 THEN 1 ELSE 0 END), 0),
	    @TotalMemberSuspended = ISNULL(SUM(CASE WHEN RoleID = 1 AND ISNULL(reject,0) = 1 AND Closed = 0 THEN 1 ELSE 0 END), 0)
	    FROM Custinfo WITH(NOLOCK)
	    WHERE MRecommend = @custid

            --------------
		SELECT 
			@IsAllDayBalTransfer=ISNULL(IsAllDayBalTransfer, 0)
	    FROM custSuper WITH(NOLOCK)
		WHERE custid = (SELECT srecommend FROM Customer WITH(NOLOCK) WHERE Custid= @custid)

    END
    ELSE IF @roleid = 2 --agent
    BEGIN
		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE recommend = @custid AND roleid = 1
		SELECT	@uplineid = mrecommend    FROM	custinfo ci WITH(NOLOCK)    WHERE ci.custid = @custid
		SELECT @IsSyncUplineGoldDeluxe=CASE WHEN HideGoldDeluxe=0 THEN 1 ELSE 0 END,@DisabledUplineGoldDeluxe=ISNULL(DisableGoldDeluxe,1)  FROM custInfo WITH(NOLOCK) WHERE custid=@uplineid
	    SELECT 
		    @IsInternal = ISNULL(IsInternal, 0),
		    @LimitPerIP = ISNULL(LimitPerIP, 0),
		    @SelectedBetting =  ISNULL(SelectedBetting, 0),
		    @NicknameLoginOnly =ISNULL(NicknameLoginOnly, 0)
	    FROM custAgent WITH(NOLOCK) WHERE custid = @custid
    	
	    SELECT
	    @TotalMemberActive = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
	    @TotalMemberClosed = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 1 THEN 1 ELSE 0 END), 0),
	    @TotalMemberSuspended = ISNULL(SUM(CASE WHEN RoleID = 1 AND ISNULL(reject,0) = 1 AND Closed = 0 THEN 1 ELSE 0 END), 0)
	    FROM Custinfo WITH(NOLOCK)
	    WHERE Recommend = @custid
				   --------------
		  SELECT 
			 @IsAllDayBalTransfer=ISNULL(IsAllDayBalTransfer, 0)
	      FROM custSuper WITH(NOLOCK)
		  WHERE custid = (SELECT srecommend FROM Customer WITH(NOLOCK) WHERE Custid= @custid)
    END
    ELSE IF @roleid = 1 --member
    BEGIN
	    SELECT 
		    @IsInternal = ISNULL(IsInternal, 0)
	    FROM custAgent WITH(NOLOCK) WHERE custid = @uplineid
		  --------------
		  SELECT 
			 @IsAllDayBalTransfer=ISNULL(IsAllDayBalTransfer, 0)
	      FROM custSuper WITH(NOLOCK)
		  WHERE custid = (SELECT srecommend FROM Customer WITH(NOLOCK) WHERE Custid= @custid)
    END
    
    --Direct Customer Status
    SELECT @IsHideDirectStatus =
             CASE
               WHEN roleid = 4 OR Enabled = 0 OR @IsInternal = 1 OR @IsDeposit = 1 THEN 1
               ELSE 0
             END
      FROM dbo.custInfo WITH(NOLOCK)
     WHERE custid = @custid

    IF @IsHideDirectStatus = 0
    BEGIN
        SELECT @IsCheckedDirectStatus = 1
             , @IsDisabledDirectStatus = 1
          FROM dbo.custInfo ci WITH(NOLOCK)
         WHERE ci.custid = @custid
           AND ((ci.roleid = 1
                 AND EXISTS (SELECT 1
                               FROM dbo.Acc_CustDirect cd WITH(NOLOCK)
                              WHERE ci.recommend = cd.custid
                                AND cd.roleid = 2
                            )
                )
                OR (ci.roleid = 2
                    AND EXISTS (SELECT 1
                                  FROM dbo.Acc_CustDirect cd WITH(NOLOCK)
                                 WHERE ci.mrecommend = cd.custid
                                   AND cd.roleid = 3
                               )
                   )
                OR (ci.roleid = 3
                    AND EXISTS (SELECT 1
                                  FROM dbo.Acc_CustDirect cd WITH(NOLOCK)
                                 WHERE ci.srecommend = cd.custid
                                   AND cd.roleid = 4
                               )
                   )
               )

        SELECT @IsDisabledDirectStatus = 1
             , @IsCheckedDirectStatus = 0
          FROM dbo.Acc_CustDirect WITH(NOLOCK)
         WHERE custid = @custid
    END

    --General info
    DECLARE @isBA BIT
    IF EXISTS (
			     SELECT 1 FROM DBLIC.bodb_Licensee.dbo.LicenseeBAHistory lb WITH(NOLOCK)
			     WHERE custid=@custid AND status='running'
			    )
	    SET @isBA=1
    ELSE
	    SET @isBA=0

	DECLARE @credit MONEY
	SELECT @credit = credit
	FROM DBCUST.CustDB.dbo.CustInfo WITH(NOLOCK)
	WHERE custid = @custid

	DECLARE @OTPCreateDate DATETIME
	SELECT  @OTPCreateDate = CreatedDate FROM DBCUST.CustDB.dbo.CustOTP WITH(NOLOCK)
	WHERE custid = @custid
	
	DECLARE @CustGroupHeadlineID INT, @srecommend INT, @mrecommend INT, @recommend INT
	
	IF @IsDeposit = 0
	BEGIN
		SELECT @srecommend = srecommend, @mrecommend = mrecommend, @recommend=recommend
		FROM custInfo WITH (NOLOCK)
		WHERE custid = @custid
		
		SELECT @CustGroupHeadlineID = CDA.CustID
		FROM CustDirectAccount CDA WITH (NOLOCK)
		WHERE CDA.CustID IN (@srecommend,@mrecommend,@recommend,@custid)
		
		IF @CustGroupHeadlineID IS NULL
			SET @CustGroupHeadlineID = @srecommend	

	END

			
	IF EXISTS (SELECT TOP 1 1 FROM DBCUST.CustDB.dbo.CustLoginInfo cl WITH(NOLOCK) WHERE cl.Custid=@uplineid AND cl.SecurityCode IS NOT NULL)
			SELECT @UplineHasSecurityCode=1

    SELECT c.custid, c.username, c.firstname, c.lastname, 
	    c.username2, 		
	    ci.roleid, 
	    lastlogged, 
	    iplogin lastloginip, 
	    pwdexpiry, 
	    @credit as credit, --ci.credit,
		@netPosition as netPosition,
	    e.currency,
	    e.exchangeid,
	    e.actualrate,
	    --virtual rate status
	    ci.virtualmultiplier as EnableVirtualrate,
	    important,
	    ci.danger,
	    ci.danger2,
	    ci.danger3,
	    ci.Abnormal,
	    ci.closed, ci.reject as suspended, ci.autosuspend,		 
	    ISNULL(@DisableDownlinesCS,0) DisableDownlinesCS,	  
	    ISNULL(@DisableDownlinesNumber,0) DisableDownlinesNumber,	
	    --ISNULL(@DisableDownlinesVirtualSports,0) DisableDownlinesVirtualSports,
	    ISNULL(@DownlinesSelectedBetting,0) DownlinesSelectedBetting,
		ISNULL(@DisableDownlinesEsports, 0) DisableDownlinesEsports,
		ISNULL(@DisableDownlinesGoldDeluxe,0) DisableDownlinesGoldDeluxe,
		ISNULL(@DisableDownlinesColossusBet,0) DisableDownlinesColossusBet,
		ISNULL(@DisableDownlinesSuperLive,0) DisableDownlinesSuperLive,
		@IsSyncUplineGoldDeluxe AS IsSyncUplineGoldDeluxe,
		@DisabledUplineGoldDeluxe AS DisabledUplineGoldDeluxe,
	 
	    ci.DisableNumber,
	    ci.DisableOutRight,
	    ci.disablecasino,
	    ci.synccasino,
	 
	 
	    --ci.DisableVirtualSports,
	    --ci.HideVirtualSports,
	    ci.DoubleCommLosing,	    	   
		ci.DisableEsports,
		ISNULL(ci.DisableGoldDeluxe,1) AS DisableGoldDeluxe,			
		ISNULL(ci.HideGoldDeluxe,1) AS HideGoldDeluxe,
		ISNULL(ci.DisableColossusBet,1) AS DisableColossusBet,
		ISNULL(ci.HideColossusBet,1) AS HideColossusBet,
		ISNULL(ci.DisableSuperLive,1) AS DisableSuperLive,
	    ci.Enabled,
	    @isBA IsBA,
	    @IsDeposit IsDeposit, 
	    c.phone, c.mobilephone, c.fax, c.creatdate as createdate,
	    c.site,
	    @IsInternal as IsInternal,
	    @LimitPerIP as LimitPerIP,
	    @SelectedBetting as SelectedBetting,
	    @NicknameLoginOnly as NicknameLoginOnly,
	    @membersite as membersite,
	    @LastChangedSecurityCodeDate as LastChangedSecurityCodeDate,
	    @IsHideDirectStatus IsHideDirectStatus,
	    @IsCheckedDirectStatus IsCheckDirectStatus,
	    @IsDisabledDirectStatus IsDisabledDirectStatus,
		@HasDownline AS HasDownline, 
		@OTPCreateDate AS OTPCreateDate
		,ISNULL(@IsAllDayBalTransfer,0) IsAllDayBalTransfer
		, ISNULL(Headline.username,'') AS Headline
		, ISNULL(GroupHeadline.GroupID,0) AS GroupHeadlineID
		,CASE WHEN @IsDeposit=1 THEN 1 ELSE ISNULL(@ClosedReason,0) END AS ClosedReason
		,@UplineHasSecurityCode AS UplineHasSecurityCode
    FROM customer c WITH(NOLOCK)
	    inner join custinfo ci WITH(NOLOCK) on c.custid = ci.custid
	    inner join exchange e WITH(NOLOCK) on c.currency = e.exchangeid 
	    LEFT JOIN custaccount AS GroupHeadline WITH (NOLOCK) ON GroupHeadline.CUSTID = @CustGroupHeadlineID AND GroupHeadline.GroupID > 0 AND @IsDeposit = 0
		OUTER APPLY (SELECT C.username
					 FROM dbo.custaccount ca WITH (NOLOCK)
						INNER JOIN Customer C ON CA.custid = C.custid 
					 WHERE ca.GroupID = GroupHeadline.GroupID AND ca.IsGroupHeadLine = 1 AND @IsDeposit = 0
					) AS Headline
					
    WHERE c.custid = @custid
    
    
    ----------------------------
    -------------------------------------------------------------------------
    --Agency Info
    SELECT CASE WHEN c.roleid = 1 THEN c.custid ELSE NULL END as memberID,
	    CASE WHEN c.roleid = 1 THEN c.username ELSE NULL END as memberName,	
	    CASE @roleid	WHEN 1 THEN ISNULL(a.autosuspend,0) 
					    WHEN 2 THEN ISNULL(m.autosuspend,0) 
					    WHEN 3 THEN ISNULL(s.autosuspend,0) 
					    ELSE 0 END uplineAutosuspend,							    		
	    a.custid as agentID,
	    a.username as agentName,	
	    a.Enabled as agentEnabled,
	    m.custid as masterID,
	    m.username as masterName,
	    m.Enabled as masterEnabled,
	    s.custid as superID,
	    s.username as superName,
	    s.Enabled as superEnabled
    	
    FROM custinfo c WITH(NOLOCK)
	    left join custinfo a WITH(NOLOCK) on c.recommend = a.custid
	    left join custinfo m WITH(NOLOCK) on c.mrecommend = m.custid
	    left join custinfo s WITH(NOLOCK) on c.srecommend = s.custid
    where
	    c.custid = @custid
  
	 -------------------------------------------------------------------------
	 /* Balance Info */
	 EXEC dbo.Acc_CustomerSelBalanceCashInfo @custid = @custid
	-------------------------------------------------------------------------


    SELECT  @TotalMAgentActive MAgentActive,
		    @TotalMAgentClosed MAgentClosed,
		    @TotalMAgentSuspended MAgentSuspended,
		    @TotalAgentActive AgentActive,
		    @TotalAgentClosed AgentClosed,
		    @TotalAgentSuspended AgentSuspended,
		    @TotalMemberActive MemberActive,
		    @TotalMemberClosed MemberClosed,
		    @TotalMemberSuspended MemberSuspended

	-- For sportbook2
	IF @IsDeposit = 0 -- credit
	BEGIN
		EXEC Acc_CustSetting_StatusSettingSelect @CustID = @custid,@roleid = @roleid      
	END
	ELSE  -- deposit
	BEGIN
		EXEC DBACC.bodb02.dbo.Acc_Dep_CustSetting_StatusSettingSelect @CustID = @custid,@roleid = @roleid      
	END
	
END
GO
