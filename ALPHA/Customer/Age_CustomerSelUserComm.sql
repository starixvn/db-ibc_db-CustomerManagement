/*<info serverAlias="DBCUST-CustDB,DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="" isFunction="0"></info>*/
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
Param's Explanation:
• @custid: custid that need to be viewed.   
*/

	SET NOCOUNT ON

	DECLARE @ga decimal(9,8), @gb decimal(9,8), @gc decimal(9,8), @gd decimal(9,8), @dis decimal(9,8), @dis1x2 decimal(9,8)
	DECLARE @RoleId INT
			
	DECLARE @srecommend INT,@mrecommend INT,@recommend INT 
	
	SELECT @RoleId = roleid, @srecommend=srecommend,@mrecommend = mrecommend,@recommend = recommend FROM custInfo WITH (NOLOCK) WHERE custid = @CustID
	
	IF (@RoleId = 1) 
	BEGIN
		-- Member Commission --
		SELECT 	
			ISNULL(MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.discount ELSE 0 END), 0) AS discount,
			ISNULL(MAX(CASE WHEN cs.bettype = 4 AND cs.sporttype=1 THEN cs.discount ELSE 0 END), 0) AS discountcs,

			ISNULL(MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.playerdiscount ELSE 0 END), 0) AS playerdiscount,
			ISNULL(MAX(CASE WHEN cs.bettype = 4 AND cs.sporttype=1 THEN cs.playerdiscount ELSE 0 END), 0) AS playerdiscountcs,	
			
			ISNULL(MAX(CASE WHEN cs.bettype = 5 AND cs.sporttype=1 THEN cs.discount ELSE 0 END), 0) AS discount1x2,
			ISNULL(MAX(CASE WHEN cs.bettype = 5 AND cs.sporttype=1 THEN cs.playerdiscount ELSE 0 END), 0) AS playerdiscount1x2

		FROM 	
			CustSetting AS cs WITH (NOLOCK)
			Inner join CustSetting3rd as cs3 WITH (NOLOCK) on cs.custid = cs3.custid
		WHERE cs.custid=@custid
	END
	ELSE 
	IF (@RoleId = 2) 
	BEGIN
		-- Agent Commission ---	
		
		SELECT 
			@ga = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupa ELSE 0 END),
			@gb = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupb ELSE 0 END),
			@gc = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupc ELSE 0 END),
			@gd = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupd ELSE 0 END),
			@dis1x2 = MAX(CASE WHEN acs.bettype = 5 AND acs.sporttype=1 THEN acs.adiscount ELSE 0 END), --1x2 comm
			@dis = MAX(CASE WHEN acs.bettype = 4 AND acs.sporttype=1 THEN acs.adiscount ELSE 0 END) --other comm			
		FROM custsetting as acs WITH (NOLOCK)
		INNER JOIN Custsetting3rd as acs3 WITH (NOLOCK) ON acs.custid = acs3.custid
		WHERE acs.custid = @mrecommend

		SELECT
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupa ELSE 0 END) AS groupa,
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupb ELSE 0 END) AS groupb,
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupc ELSE 0 END) AS groupc,
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.groupd ELSE 0 END) AS groupd,
			MAX(CASE WHEN cs.bettype = 5 AND cs.sporttype=1 THEN cs.discount ELSE 0 END) AS discount1x2, --1x2 comm
			MAX(CASE WHEN cs.bettype = 4 AND cs.sporttype=1 THEN cs.discount ELSE 0 END) AS discountcs, --other comm		
			
			@ga AS groupa_max,
			@gb AS groupb_max,
			@gc AS groupc_max,
			@gd AS groupd_max,
			@dis1x2 AS discount1x2_max,
			@dis AS discountcs_max	
			
		FROM 
			custsetting AS cs WITH (NOLOCK)
			INNER JOIN custsetting3rd as cs3 WITH (NOLOCK) ON cs.custid = cs3.custid
		WHERE 
			cs.custid=@CustID
	END
	ELSE
	IF @RoleId = 3
	BEGIN
		SELECT 
			@ga = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupa ELSE 0 END),
			@gb = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupb ELSE 0 END),
			@gc = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupc ELSE 0 END),
			@gd = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupd ELSE 0 END),
			@dis1x2 = MAX(CASE WHEN acs.bettype = 5 AND acs.sporttype=1 THEN acs.sdiscount ELSE 0 END), --1x2 comm
			@dis = MAX(CASE WHEN acs.bettype = 4 AND acs.sporttype=1 THEN acs.sdiscount ELSE 0 END) --other comm		
		FROM custsetting as acs WITH (NOLOCK)
		INNER JOIN CustSetting3rd as acs3 WITH (NOLOCK) ON acs.custid = acs3.custid
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
			@dis AS discountcs_max
		FROM 
			custsetting AS cs WITH (NOLOCK)
			INNER JOIN CustSetting3rd as cs3 WITH (NOLOCK) ON cs.custid = cs3.custid
		WHERE cs.custid=@CustID
	END
	ELSE IF @RoleId = 4
	BEGIN
		SELECT 
			@ga = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupa ELSE 0 END),
			@gb = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupb ELSE 0 END),
			@gc = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupc ELSE 0 END),
			@gd = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.groupd ELSE 0 END),
			@dis1x2 = MAX(CASE WHEN acs.bettype = 5 AND acs.sporttype=1 THEN acs.sdiscount ELSE 0 END), --1x2 comm
			@dis = MAX(CASE WHEN acs.bettype = 4 AND acs.sporttype=1 THEN acs.sdiscount ELSE 0 END) --other comm		
		FROM custsetting as acs WITH (NOLOCK)
		INNER JOIN CustSetting3rd as acs3 WITH (NOLOCK) ON acs.custid = acs3.custid
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
			@dis AS discountcs_max
		FROM 
			custsetting AS cs WITH (NOLOCK)
			INNER JOIN CustSetting3rd as cs3 WITH (NOLOCK) ON cs.custid = cs3.custid
		WHERE cs.custid=@CustID
	
	END
end
GO
