/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv,wsv_xnap" viewers="" isFunction="0"></info>*/
alter PROCEDURE [dbo].[Age_CustomerSelUserComm]
	@custid int,
	@userid int --upline id
AS
BEGIN
/*
Created: 20090211@nqminh
Task : Select customer commission
DB: DBAGE/bodb02, DBTXN/custDBd
Original:

Revisions:
    - 20090122@[Reviewer]: [Description of revision]   
    - 20100924@Terry: Get discount for number game 
	- 20131018@Kathy: Add HR Fixed Odds (154) [Redmine:#6505]
	- 20131227@Kathy: Correct column name discountHRFixedOdds_max
	- 20150904@Helen: commission setting for MO [Redmine #41470]
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
	- 20190905@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
	- 20200918@Winfred: Reinsert MyanmarOdds [Redmine: #141926]	
	- 20221123@Elodie: Migrate NG and Keno to DCS structure [Redmine: #179711]
Param's Explanation:
• @custid: custid that need to be viewed.   
*/

	SET NOCOUNT ON

	DECLARE @ga decimal(9,8), @gb decimal(9,8), @gc decimal(9,8), @gd decimal(9,8), @dis decimal(9,8), @dis1x2 decimal(9,8)
	DECLARE @RoleId INT
	
		
	DECLARE @playerdiscountMyanmarOdds DECIMAL(9,8)=0,
			@discountMyanmarOdds DECIMAL(9,8)=0,
			@adiscountMyanmarOdds DECIMAL(9,8)=0,
			@sdiscountMyanmarOdds DECIMAL(9,8)=0,
			@IsMyanmarOdds BIT = 0
			
	DECLARE @srecommend INT,@mrecommend INT,@recommend INT 
	
	SELECT @RoleId = roleid, @srecommend=srecommend,@mrecommend = mrecommend,@recommend = recommend FROM custInfo WITH (NOLOCK) WHERE custid = @CustID
	
	IF (@RoleId = 1) 
	BEGIN
		SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@srecommend)
		
		IF @IsMyanmarOdds = 1
		BEGIN
			SET @playerdiscountMyanmarOdds = (SELECT playerdiscount FROM CustCommRate WITH (NOLOCK) WHERE CustId = @custid AND Sporttype = 1 AND Bettype = 1)
			SET @discountMyanmarOdds = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @recommend AND Sporttype = 1 AND Bettype = 1)
		END
		-- Member Commission --
		SELECT 	
			ISNULL(MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.discount ELSE 0 END), 0) AS discount,
			ISNULL(MAX(CASE WHEN cs.bettype = 4 AND cs.sporttype=1 THEN cs.discount ELSE 0 END), 0) AS discountcs,

			ISNULL(MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.playerdiscount ELSE 0 END), 0) AS playerdiscount,
			ISNULL(MAX(CASE WHEN cs.bettype = 4 AND cs.sporttype=1 THEN cs.playerdiscount ELSE 0 END), 0) AS playerdiscountcs,	
			
			ISNULL(MAX(CASE WHEN cs.bettype = 5 AND cs.sporttype=1 THEN cs.discount ELSE 0 END), 0) AS discount1x2,
			ISNULL(MAX(CASE WHEN cs.bettype = 5 AND cs.sporttype=1 THEN cs.playerdiscount ELSE 0 END), 0) AS playerdiscount1x2,
						
			ISNULL(@IsMyanmarOdds,0) AS IsMyanmarOdds,
			ISNULL(@playerdiscountMyanmarOdds,0) AS playerdiscountMyanmarOdds,
			ISNULL(@discountMyanmarOdds,0) AS discountMyanmarOdds
		FROM 	
			CustSetting AS cs WITH (NOLOCK)
		WHERE cs.custid=@custid
	END
	ELSE 
	IF (@RoleId = 2) 
	BEGIN
		-- Agent Commission ---	
		SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@srecommend)
		
		IF @IsMyanmarOdds = 1
		BEGIN
			SET @discountMyanmarOdds = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @custid AND Sporttype = 1 AND Bettype = 1)
			SET @adiscountMyanmarOdds = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @mrecommend AND Sporttype = 1 AND Bettype = 1)
		END
				
		SELECT 
			@ga = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupa ELSE 0 END),
			@gb = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupb ELSE 0 END),
			@gc = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupc ELSE 0 END),
			@gd = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupd ELSE 0 END),
			@dis1x2 = MAX(CASE WHEN acs.bettype = 5 AND acs.sporttype=1 THEN acs.adiscount ELSE 0 END), --1x2 comm
			@dis = MAX(CASE WHEN acs.bettype = 4 AND acs.sporttype=1 THEN acs.adiscount ELSE 0 END) --other comm			
		FROM custsetting as acs WITH (NOLOCK)
		WHERE acs.custid = @mrecommend

		SELECT
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupa ELSE 0 END) AS groupa,
			CASE WHEN @IsMyanmarOdds = 1 THEN 0 ELSE 
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupb ELSE 0 END) END AS groupb,
			CASE WHEN @IsMyanmarOdds = 1 THEN 0 ELSE 
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupc ELSE 0 END) END AS groupc,
			CASE WHEN @IsMyanmarOdds = 1 THEN 0 ELSE 
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupd ELSE 0 END) END AS groupd,
			MAX(CASE WHEN cs.bettype = 5 AND cs.sporttype=1 THEN cs.discount ELSE 0 END) AS discount1x2, --1x2 comm
			MAX(CASE WHEN cs.bettype = 4 AND cs.sporttype=1 THEN cs.discount ELSE 0 END) AS discountcs, --other comm		
			@ga AS groupa_max,
			CASE WHEN @IsMyanmarOdds = 1 THEN 0 ELSE @gb END AS groupb_max,
			CASE WHEN @IsMyanmarOdds = 1 THEN 0 ELSE @gc END AS groupc_max,
			CASE WHEN @IsMyanmarOdds = 1 THEN 0 ELSE @gd END AS groupd_max,
			@dis1x2 AS discount1x2_max,
			@dis AS discountcs_max		,
		
			ISNULL(@IsMyanmarOdds,0) AS IsMyanmarOdds,
			ISNULL(@discountMyanmarOdds,0.00) AS discountMyanmarOdds,
			ISNULL(@adiscountMyanmarOdds,0.00) AS discountMyanmarOdds_Max 	
			
		FROM 
			custsetting AS cs WITH (NOLOCK)
		WHERE 
			cs.custid=@CustID
	END
	ELSE
	IF @RoleId = 3
	BEGIN
	
		SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@srecommend)
		
		IF @IsMyanmarOdds = 1
		BEGIN
			SET @sdiscountMyanmarOdds = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @SRecommend AND Sporttype = 1 AND Bettype = 1)
			SET @discountMyanmarOdds = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @custid AND Sporttype = 1 AND Bettype = 1)
		END
	
		SELECT 
			@ga = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupa ELSE 0 END),
			@gb = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupb ELSE 0 END),
			@gc = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupc ELSE 0 END),
			@gd = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupd ELSE 0 END),
			@dis1x2 = MAX(CASE WHEN acs.bettype = 5 AND acs.sporttype=1 THEN acs.sdiscount ELSE 0 END), --1x2 comm
			@dis = MAX(CASE WHEN acs.bettype = 4 AND acs.sporttype=1 THEN acs.sdiscount ELSE 0 END) --other comm		
		FROM custsetting as acs WITH (NOLOCK)
		WHERE acs.custid = @SRecommend
		
		SELECT
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupa ELSE 0 END) AS groupa,
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupb ELSE 0 END) AS groupb,
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupc ELSE 0 END) AS groupc,
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupd ELSE 0 END) AS groupd,
			MAX(CASE WHEN cs.bettype = 5 AND cs.sporttype=1 THEN cs.adiscount ELSE 0 END) AS discount1x2, --1x2 comm
			MAX(CASE WHEN cs.bettype = 4 AND cs.sporttype=1 THEN cs.adiscount ELSE 0 END) AS discountcs, --other comm	
		
			@ga AS groupa_max,
			@gb AS groupb_max,
			@gc AS groupc_max,
			@gd AS groupd_max,
			@dis1x2 AS discount1x2_max,
			@dis AS discountcs_max,
			
			ISNULL(@IsMyanmarOdds,0) AS IsMyanmarOdds,
			ISNULL(@discountMyanmarOdds,0.00) AS discountMyanmarOdds,
			ISNULL(@sdiscountMyanmarOdds,0.00) AS discountMyanmarOdds_Max 
		FROM 
			custsetting AS cs WITH (NOLOCK)
		WHERE cs.custid=@CustID
	END
	ELSE IF @RoleId = 4
	BEGIN
	
		SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@custid)
		IF @IsMyanmarOdds = 1
		BEGIN
			SET @sdiscountMyanmarOdds = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @SRecommend AND Sporttype = 1 AND Bettype = 1)
			SET @discountMyanmarOdds = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @custid AND Sporttype = 1 AND Bettype = 1)
		END
		
		SELECT 
			@ga = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupa ELSE 0 END),
			@gb = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupb ELSE 0 END),
			@gc = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupc ELSE 0 END),
			@gd = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupd ELSE 0 END),
			@dis1x2 = MAX(CASE WHEN acs.bettype = 5 AND acs.sporttype=1 THEN acs.sdiscount ELSE 0 END), --1x2 comm
			@dis = MAX(CASE WHEN acs.bettype = 4 AND acs.sporttype=1 THEN acs.sdiscount ELSE 0 END) --other comm		
		FROM custsetting as acs WITH (NOLOCK)
		WHERE acs.custid = @custid
		
		SELECT
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupa ELSE 0 END) AS groupa,
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupb ELSE 0 END) AS groupb,
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupc ELSE 0 END) AS groupc,
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupd ELSE 0 END) AS groupd,
			MAX(CASE WHEN cs.bettype = 5 AND cs.sporttype=1 THEN cs.sdiscount ELSE 0 END) AS discount1x2, --1x2 comm
			MAX(CASE WHEN cs.bettype = 4 AND cs.sporttype=1 THEN cs.sdiscount ELSE 0 END) AS discountcs, --other comm	
			
			@ga AS groupa_max,
			@gb AS groupb_max,
			@gc AS groupc_max,
			@gd AS groupd_max,
			@dis1x2 AS discount1x2_max,
			@dis AS discountcs_max,
			
			ISNULL(@IsMyanmarOdds,0) AS IsMyanmarOdds,
			ISNULL(@discountMyanmarOdds,0.00) AS discountMyanmarOdds,
			ISNULL(@sdiscountMyanmarOdds,0.00) AS discountMyanmarOdds_Max 
		FROM 
			custsetting AS cs WITH (NOLOCK)
		WHERE cs.custid=@CustID
	
	END
end
GO
