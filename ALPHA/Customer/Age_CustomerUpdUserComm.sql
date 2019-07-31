/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="" isFunction="0"></info>*/

/****** Object:  Stored Procedure dbo.Age_CustomerUpdUserComm    Script Date: 12/5/2013 4:35:18 PM ******/
ALTER PROCEDURE [dbo].[Age_CustomerUpdUserComm]	
	@custid INT, --customer to be updated
	@playerdiscount DECIMAL(9,8),
	@playerdiscountcs DECIMAL(9,8),
	@playerdiscount1x2 DECIMAL(9,8),	
	@playerdiscountnumber DECIMAL(9,8)=0,
	@playerdiscountMyanmarOdds DECIMAL(9,8) = 0,
	@userid INT, --updater Id	
	@subaccid INT = 0, --Sub-AccountID
	@language VARCHAR(2) = 'E',
	@IP VARCHAR(15)='',	
	@errcode INT = 0 OUTPUT,
	@errmsg NVARCHAR(200) = '' OUTPUT
AS
BEGIN
 /*
Created: 20090213@nqminh
Task : Update commission of specific customer
DB: DBCUST/CUSTDB
Original:

Revisions:    
    - 20090318@Hanh: add Korean language
    - 20090411@Minh: remove constraint: if upline is disabled financial then do not update FI
	- 20090429@Phuc: remove code for calling sp Acc_CustomerUpdMember_Commission.
	- 20090526@Minh: add code for updating 1x2 group commission.
	- 20090729@Phuc: Write log subaccname instead of subaccid.
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Phuc: hardcode not to update commission for member under agent 8RM.
	- 20100112@Kiwi: amend to write log in xml format.
	- 20100918@Terry: Add number game
	- 20101019@Henry: Record execution time
	- 20110907@Sophia: Change Linked Server from DB052 to DB053
	- 20110929@Johnson: Add more group under Won currency
	- 20120412@Hurri: hardcode not to update commission for member under agent BARM.
	- 20120523@Sophia: . Remove hardcode not to update commission for member under agent BARM.
					   . Update setting for all bettype of Number game, not only for bettype = 81
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130311@Dan: Change linked server DB053 to DBAGE; Write more log on DBTXN server in case of DBLOG server failure
	- 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
	- 20131029@Kathy: Apply exec rep to update commission [Redmine:#3244]
	- 20150611@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB) [Redmine:#36216]
	- 20150904@Helen: commission setting for MO [Redmine #41470]
	- 20160613@Helen: Security Prevention Step 1 - Cross level update -  [Redmine:55377]			            
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
	- 20190723@Eden: set default value for @discountnumber = 0 [redmine: #105955]
Param's Explanation:
• @custid: custid that need to be viewed.   
• @playerdiscount: Player discount for group			(sportype = 1 and bettype = 1)
• @playerdiscountcs: Player discount for other types.	(sportype = 1 and bettype = 4)
• @playerdiscount1x2: Player discount for 1x2 bettype   (sportype = 1 and bettype = 5)
• @@playerdiscountHRFixedOdds: Player discount for HR Fixed Odds bettype   (sportype = 154 and bettype = 20)

• @userid: updater id
• @subaccid: subaccId if any
• @language: updater's language
• @ip: updater's ip
• @errcode: error code
• @errmsg: error message if errcode > 0
*/

	SET NOCOUNT ON

	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()

	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <>0 RETURN
	--end
	
	DECLARE @roleid TINYINT
	
	SET @roleid = (SELECT roleid FROM Custinfo WITH (NOLOCK) WHERE custid = @custid)	
	
	-- Only direct upline have update permission
	IF NOT EXISTS (SELECT 1 FROM dbo.f_AGE_IsCrossLevelUpdate(@custid,@roleid,@userid))
	BEGIN
		SELECT @ErrMsg = 'You don''t have permission to perform this action.',
			   @ErrCode = 103	
		RETURN
	END
	
	--Do update
	DECLARE @username VARCHAR(40), @recommend INT,
			@discount DECIMAL(9,8), @discountcs DECIMAL(9,8), @ugroup VARCHAR(10),@discount1x2_max DECIMAL(9,8),@discountnumber_max DECIMAL(9,8)
	SELECT @UserName  = username,
			@recommend = recommend,
			@ugroup = c.ugroup
	FROM customer c WITH (NOLOCK) WHERE CustID = @CustID

	DECLARE	@playerdiscount_old DECIMAL(9,8),
			@playerdiscountcs_old DECIMAL(9,8),		
			@playerdiscount1x2_old DECIMAL(9,8),
			
			@playerdiscountnumber_old DECIMAL(9,8),
			@playerdiscountMyanmarOdds_old decimal(9,8)
			
	 -- For Myanmar Odds  
	 DECLARE @IsMyanmarOdds BIT = 0  
	 
	 SELECT @recommend = recommend
	 FROM custInfo WITH (NOLOCK)
	 WHERE custid = @custid  
	 
	 SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@recommend)  
	    
	 IF @IsMyanmarOdds = 1  
	 BEGIN  
	  -- Get old value  
	  SET @playerdiscountMyanmarOdds_old = (SELECT playerdiscount FROM CustCommRate WITH (NOLOCK) WHERE CustId = @custid AND Sporttype = 1 AND Bettype = 301)  
	    
	 END  
	 		
	DECLARE @updatecomm_old BIT

	SELECT @playerdiscount_old = playerdiscount
	FROM custsetting (NOLOCK) WHERE custid = @custid AND sporttype = 1 AND bettype = 1

	SELECT @playerdiscountcs_old = playerdiscount
	FROM custsetting (NOLOCK) WHERE custid = @custid AND sporttype = 1 AND bettype = 4

	SELECT @playerdiscount1x2_old = playerdiscount
	FROM custsetting (NOLOCK) WHERE custid = @custid AND sporttype = 1 AND bettype = 5


	SELECT @playerdiscountnumber_old = playerdiscount
	FROM custsetting3rd (NOLOCK) WHERE custid = @custid AND sporttype = 161 AND bettype = 81

	IF @playerdiscount_old <> @playerdiscount OR @playerdiscountcs_old <> @playerdiscountcs OR @playerdiscount1x2 <> @playerdiscount1x2_old OR @playerdiscountnumber <> @playerdiscountnumber_old 
		OR (@IsMyanmarOdds = 1 AND @playerdiscountMyanmarOdds <> @playerdiscountMyanmarOdds_old)
		SET @updatecomm_old = 1
	ELSE 
		SET @updatecomm_old = 0
		
	IF @updatecomm_old = 0
		RETURN

	--Check Param
	IF	@playerdiscount<0 OR @playerdiscount>0.2
		OR @playerdiscountcs<0 OR @playerdiscountcs>0.2
		OR @playerdiscount1x2<0 OR @playerdiscount1x2>0.2
		
		OR @playerdiscountnumber<0 OR @playerdiscountnumber>0.2
		OR @playerdiscountMyanmarOdds < 0  OR @playerdiscountMyanmarOdds > 0.01
	BEGIN	
		SELECT @ErrMsg = CASE @Language 
							WHEN 'E' THEN 'Invalid commission rate.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](1,@Language)
						END, @ErrCode = 101
		RETURN
	END

	---------------------------------------
	IF @updatecomm_old = 1
	BEGIN
		--Get g2
		SELECT 
			@discount = CASE WHEN @ugroup IN ('a','hka','dea') THEN groupa 
							 WHEN @ugroup IN ('b','hkb','deb') THEN groupb 
							 WHEN @ugroup IN ('c','hkc','dec') THEN groupc 
							 WHEN @ugroup IN ('d','hkd','ded') THEN groupd ELSE groupa END
		FROM custsetting WITH (NOLOCK)
		WHERE custid = @recommend AND bettype=1 AND sporttype=1
		
		--Get a2
		SELECT @discountcs = discount
		FROM custsetting WITH (NOLOCK)
		WHERE custid = @recommend AND sporttype = 1 AND bettype = 4
		
		--@playerdiscount>g2?g2:@playerdiscount 
		--@playerdiscountcs>a2?a2:@playerdiscountcs
		SELECT 
			@playerdiscount = CASE WHEN @playerdiscount>@discount THEN @discount ELSE @playerdiscount END,
			@playerdiscountcs = CASE WHEN @playerdiscountcs>@discountcs THEN @discountcs ELSE @playerdiscountcs END
		
	---- Update 1x2 commision ---------------------------------------------------------------------
		--Get a2
		SELECT @discount1x2_max = discount
		FROM custsetting WITH (NOLOCK)
		WHERE custid = @recommend AND sporttype = 1 AND bettype = 5
		
		SELECT @discountnumber_max = discount
		FROM custsetting3rd WITH (NOLOCK)
		WHERE custid = @recommend AND sporttype = 161 AND bettype = 81

		
		SELECT @playerdiscount1x2 = CASE WHEN @playerdiscount1x2 > @discount1x2_max THEN @discount1x2_max ELSE @playerdiscount1x2 END
		
		SELECT @playerdiscountnumber = CASE WHEN @playerdiscountnumber > @discountnumber_max THEN @discountnumber_max ELSE @playerdiscountnumber END			
		
		
		EXEC dbo.Acc_CustomerUpdMember_Commission
			@custid = @custid,
			@playerdiscount = @playerdiscount,
			@playerdiscountcs = @playerdiscountcs , 
			@playerdiscount1x2 = @playerdiscount1x2,
		
			@playerdiscountnumber =  @playerdiscountnumber, 
			@IsMyanmarOdds = @IsMyanmarOdds,
			@discountMyanmarOdds = @playerdiscountMyanmarOdds,
			@discountMyanmarOdds_old = @playerdiscountMyanmarOdds_old,
			@updatecomm_old = @updatecomm_old,
			@SubAccID = @SubAccID,
			@UserID = @UserID,
			@Language = @Language,
			@IP = @IP,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT
		
	END
		
	--Error return
	IF (@ErrCode > 0)
	BEGIN
		SELECT @ErrMsg =
						CASE @language 
							WHEN 'E' THEN 'Update process is unsuccessful.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](90001,@Language)
						END	, @ErrCode = 102
		RETURN
	END

END

GO