ALTER PROCEDURE [dbo].[Agm_CustomerInsMember_Ag]
	@Custid int output
	,@UserName varchar(30)
	,@Userpwd varchar(40)
	,@FirstName nvarchar(50)
	,@LastName nvarchar(50)
	,@Phone nvarchar(50)
	,@MobilePhone nvarchar(50)
	,@Fax nvarchar(50)
	,@GivenCredit money
	,@Creator int
	,@recommend int	
	,@ExistingCustid int
	,@SubAccountID int=0	
	,@Language varchar(2)= 'E'
	,@IP varchar(15)=''		
	,@ErrCode int = 0 output
	,@ErrMsg nvarchar(4000) = '' output
AS
/*  
 Created by: Elly  
 Date:20110722
 Original:
 Task: Add new customer from smart phone
 
 DB: DBTXN/BODB02  
  
 History:  
	- 20110823@Elly: Correct log information
				Insert pwdexpire = dateadd(dd,30,getdate())
	- 20120208 @Dan: add p2p and livecasino copy, init custcredit, custdebit 
	- 20120323 @Dan: check roleid and the recomment of existing customer before copying 
	- 20120502@Lukas: Encode XML values when logging
	- 20120820@Dan: add 3 fields in custinfo table (VS)
	- 20120823@Elodie: add Abnormal field
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20121203@Tom: Add  virtual tennis setting (sporttype : 186 , bettype : 1220)
	- 20130305@Johnson: Add virtual horse racing setting (sporttype : 181) and write log on DBTXN if DBLOG failure
 Explanation's Param:  
	
	
  
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @Danger tinyint
		,@Danger2 tinyint
		,@Danger3 tinyint
		,@Abnormal tinyint
		,@startRun datetime
		,@endRun datetime
		,@duration int
		,@pwdexpiry datetime
		
	--Check an account disabled or not 
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @recommend, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output 
	if @ErrCode <>0		return 
	
	
	IF EXISTS (SELECT 1 FROM dbo.customer WITH(NOLOCK) WHERE username=@username OR username2=@username
			UNION ALL
				SELECT 1 FROM dbo.custsub WITH(NOLOCK) WHERE username= @username
		)
	BEGIN		
		Select @ErrMsg = case @Language 
								when 'E' then 'This username is not available.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40001,@Language)
							end		
				,@ErrCode = 201
		return		

	END	
	
	-- Check role and reccomend of existing customer
	DECLARE @existingUsername varchar(30),@roleid tinyint, @existingRecommend int
	
	SELECT @existingUsername =  ISNULL(username,''), @roleid = ISNULL(roleid,0), @existingRecommend = ISNULL(recommend,0)
	FROM dbo.customer WITH(NOLOCK) 
	WHERE custid = @ExistingCustid

	
	IF ( NOT (@roleid = 1 AND @existingRecommend = @recommend))
	BEGIN		
		 SELECT @ErrMsg = CASE @Language 
								WHEN 'E' THEN 'Invalid user' + ' (' + @existingUsername + ')!'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language) + ' (' + @existingUsername + ')!'								
								END, 
						@ErrCode = 202
		return		

	END	

	--CHECK CREDIT
	DECLARE @AgRemain_Credit money
		,@MaxMem_Credit money
		
	SELECT @AgRemain_Credit=(ISNULL(c1.Credit,0)-ISNULL(c2.SubCredit,0))	
	FROM dbo.custinfo AS c1 WITH(NOLOCK)
		,(SELECT SUM(c2.Credit) AS SubCredit
			FROM dbo.custinfo AS c2 WITH(NOLOCK)
			WHERE c2.Recommend=@recommend
				AND c2.roleid=1
		) AS c2
		,dbo.CustAgent AS ca WITH(NOLOCK)
	WHERE c1.custid=@recommend		
		
	SELECT @MaxMem_Credit=ISNULL(ca.MaxCredit,0)
	FROM dbo.CustAgent AS ca WITH(NOLOCK)
	WHERE ca.custid=@recommend
	
	IF @MaxMem_Credit=0 SET @MaxMem_Credit=@AgRemain_Credit
	IF @Givencredit>@AgRemain_Credit 
	BEGIN
		SELECT @ErrMsg =	case @Language 
							when 'E' then 'Sorry, increase credit unsuccessfully, You have exceeded your agent credit.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70003,@Language)
						end	
			,@ErrCode = 204		
		
		RETURN
	END
	ELSE IF @Givencredit>@MaxMem_Credit
	BEGIN
		SELECT @ErrMsg =	case @Language 
							when 'E' then 'Sorry, increase credit unsuccessfully, You have exceeded the member max credit.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70009,@Language)
						end	
			,@ErrCode =217		
			
		RETURN
	END 
	
	SELECT @pwdexpiry = dateadd(dd, 30, getdate())
		,@startRun = getdate()
		
	--INSERT GENERAL INFORMATION OF CUSTOMER
	INSERT INTO dbo.customer
		(firstname
		,lastname
		,address
		,postal
		,city
		,state
		,country
		,phone
		,mobilephone
		,fax
		,email
		,birthday
		,refcode1
		,refcode2
		,remark
		,creatdate
		,creator
		,username
		,currency
		,userpwd				
		,roleid
		,mrecommend
		,recommend
		,ugroup		
		,site
		,srecommend		
		,pwdexpiry
		)
	SELECT
		@firstname
		,@lastname
		,'-' AS address
		,'-' AS postal
		,'-' AS city
		,'-' AS state
		,'-' AS country
		,@phone
		,@mobilephone
		,@fax
		,'-' AS email
		,NULL AS birthday
		,NULL AS refcode1
		,NULL AS refcode2
		,NULL AS remark
		,GETDATE() AS creatdate
		,@creator
		,@username
		,currency
		,@userpwd				
		,roleid=1
		,mrecommend
		,recommend
		,ugroup		
		,site		
		,srecommend		
		,@pwdexpiry
	FROM dbo.customer WITH(NOLOCK)
	WHERE custid=@ExistingCustid
	
	SET @Custid = SCOPE_IDENTITY()
	
	IF @@error <> 0
	BEGIN
		SELECT @ErrMsg = case @Language 
							when 'E' then 'Create customer failed. Please try again.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
						end
			,@ErrCode = 111
			
		-- ROLLBACK MANUALLY
		DELETE FROM dbo.customer With (ROWLOCK) WHERE CustID = @CustID			
		RETURN
	END
	
	--INSERT DATA INTO custinfo	
	SELECT @danger = c.danger
		,@danger2=c.danger2
		,@danger3=c.danger3
		,@Abnormal = c.Abnormal
	FROM dbo.custinfo AS c WITH(NOLOCK)
	WHERE c.custid=@recommend
			
	INSERT INTO dbo.custInfo
           (custid
           ,username
           ,currency
           ,roleid
           ,srecommend
           ,mrecommend
           ,recommend
           ,dangercust
           ,autosuspend
           ,reject
           ,credit
           ,closed
           ,MatchLimit
           ,VirtualMultiplier
           ,maxpermatch
           ,maxpermatch2
           ,maxpermatch3
           ,maxpermatch5
           ,maxpermatch8
           ,maxpermatch10
           ,maxpermatch11
           ,maxpermatch12
           ,maxpermatch99
           ,Enabled
           ,danger
           ,danger2
           ,danger3
           ,Abnormal
           ,maxpermatch151
           ,maxpermatch201
           ,DisableHorseRacing
           ,DisableFinancial
           ,DisableCasino
           ,SyncCasino           
           ,DisableOutright
           ,DisableOpenTote
           ,maxpermatch151_OT
           ,MaxPerMatch99MP
           ,DisableBingo
           ,DisableNumber
           ,maxpermatch161
           ,SyncBingo
           ,MaxPerBall161
           ,MaxPerMatch151_AU
           ,MaxPerMatch152_UK
           ,MaxPerMatch152_AU
           ,MaxPerMatch153_AU
           ,Disable151_AU
           ,Disable152_UK
           ,Disable152_AU
           ,Disable153_AU
           ,MaxTransferP2P
           ,IsAutoResetP2P
           ,DisableP2P
           ,DisableFunP2P
           ,DisableLiveCasino
           ,SyncLiveCasino
           ,DisableVirtualSports
			,HideVirtualSports
			,maxpermatch180
			,maxpermatch181
			,maxpermatch186
           )
     SELECT
           @custid
           ,@username
           ,currency
           ,roleid=1
           ,srecommend
           ,mrecommend
           ,recommend
           ,0 AS dangercust
           ,0 AS autosuspend
           ,reject
           ,@Givencredit AS Credit
           ,closed
           ,MatchLimit
           ,VirtualMultiplier
           ,maxpermatch
           ,maxpermatch2
           ,maxpermatch3
           ,maxpermatch5
           ,maxpermatch8
           ,maxpermatch10
           ,maxpermatch11
           ,maxpermatch12
           ,maxpermatch99
           ,Enabled
           ,@danger
           ,@danger2
           ,@danger3
           ,@Abnormal
           ,maxpermatch151
           ,maxpermatch201
           ,DisableHorseRacing
           ,DisableFinancial
           ,DisableCasino
           ,SyncCasino           
           ,DisableOutright
           ,DisableOpenTote
           ,maxpermatch151_OT
           ,MaxPerMatch99MP
           ,DisableBingo
           ,DisableNumber
           ,maxpermatch161
           ,SyncBingo
           ,MaxPerBall161
           ,MaxPerMatch151_AU
           ,MaxPerMatch152_UK
           ,MaxPerMatch152_AU
           ,MaxPerMatch153_AU
           ,Disable151_AU
           ,Disable152_UK
           ,Disable152_AU
           ,Disable153_AU
           ,MaxTransferP2P
           ,IsAutoResetP2P
           ,DisableP2P
           ,DisableFunP2P
           ,DisableLiveCasino
           ,0
           ,DisableVirtualSports
			,HideVirtualSports
			,maxpermatch180
			,maxpermatch181
			,maxpermatch186
        FROM dbo.custinfo WITH(NOLOCK)
        WHERE custid=@ExistingCustid  
        
	IF @@error <> 0
	BEGIN 	
		SELECT @ErrMsg = case @Language 
								when 'E' then 'Create customer failed. Please try again.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
							end
				,@ErrCode = 113
					
		-- ROLLBACK MANUALLY	
		DELETE FROM dbo.Customer WITH(ROWLOCK) WHERE CustID = @CustID
		RETURN
	END
		
	--COPY SETTING DATA FROM EXISTING CUSTID TO NEW CUSTID
	INSERT INTO dbo.custSetting
	SELECT
		@Custid
		,bettype
		,sporttype
		,apositiontaking
		,mpositiontaking
		,spositiontaking
		,alivepositiontaking
		,mlivepositiontaking
		,slivepositiontaking
		,playerdiscount
		,discount
		,adiscount
		,sdiscount
		,groupa
		,groupb
		,groupc
		,groupd
		,groupe
		,groupf
		,minbet
		,maxbet
		,autopositiontaking
		,autolivepositiontaking
		,isautopositiontaking
		,isautolivepositiontaking
		,autompositiontaking
		,autolivempositiontaking
		,isautompositiontaking
		,isautolivempositiontaking	
	FROM dbo.custSetting WITH(NOLOCK)
	WHERE custid=@ExistingCustid
	
	IF @@error <> 0
	BEGIN 	
		SELECT @ErrMsg = case @Language 
								when 'E' then 'Create customer failed. Please try again.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
							end
				,@ErrCode = 113
					
		-- ROLLBACK MANUALLY	
		DELETE FROM dbo.Customer WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustInfo WITH(ROWLOCK) WHERE CustID = @CustID
		RETURN
	END
	
	INSERT INTO dbo.CustSetting3rd
	SELECT
		@Custid
		,bettype
		,sporttype
		,apositiontaking
		,mpositiontaking
		,spositiontaking
		,playerdiscount
		,discount
		,adiscount
		,sdiscount
		,minbet
		,maxbet
		,autopositiontaking
		,isautopositiontaking
		,autompositiontaking
		,isautompositiontaking
		,alivepositiontaking
		,mlivepositiontaking
		,slivepositiontaking
		,autolivepositiontaking
		,isautolivepositiontaking
		,autolivempositiontaking
		,isautolivempositiontaking
	FROM dbo.CustSetting3rd WITH(NOLOCK)
	WHERE custid=@ExistingCustid
	
	IF @@error <> 0
	BEGIN 	
		SELECT @ErrMsg = case @Language 
								when 'E' then 'Create customer failed. Please try again.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
							end
				,@ErrCode = 113
					
		-- ROLLBACK MANUALLY	
		DELETE FROM dbo.Customer WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustInfo WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustSetting WITH(ROWLOCK) WHERE CustID = @CustID
		RETURN
	END
	
		--Insert Into P2P Setting
	INSERT INTO  dbo.P2PGameSetting WITH(ROWLOCK)
		(custId,bettype,StakeLevel1,StakeLevel2,StakeLevel3,StakeLevel4,StakeLevel5)
	SELECT @custId,bettype,StakeLevel1,StakeLevel2,StakeLevel3,StakeLevel4,StakeLevel5	
	FROM dbo.P2PGameSetting WITH(NOLOCK)
	WHERE custid=@ExistingCustid	

	if @@error <> 0
	BEGIN

		--Error occur
		SELECT @ErrMsg = case @Language 
								when 'E' then 'Create customer failed. Please try again.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
							end,
			@ErrCode = 115
			
		-- ROLLBACK MANUALLY
		DELETE FROM dbo.CustSetting3rd WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustSetting WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.Customer WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustInfo WITH(ROWLOCK) WHERE CustID = @CustID
							
		RETURN
	END
	
	--insert P2PGroupComm
	INSERT INTO dbo.P2PGroupComm WITH(ROWLOCK)
           (custId,groupID,sdiscount,adiscount,discount,playerdiscount)
	SELECT @custid,groupID,sdiscount,adiscount,discount,playerdiscount
	FROM dbo.P2PGroupComm
	WHERE custid  = @ExistingCustid  

	if @@error <> 0
	BEGIN

		--Error occur
		SELECT @ErrMsg = case @Language 
								when 'E' then 'Create customer failed. Please try again.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
							end,
			@ErrCode = 115
			
		-- ROLLBACK MANUALLY			
		DELETE FROM dbo.P2PGameSetting WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustSetting3rd WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustSetting WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.Customer WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustInfo WITH(ROWLOCK) WHERE CustID = @CustID
		
		RETURN
	END
	
		--- insert into CustSettingGame
	INSERT INTO custsettingGame
		(CustID, 
		Bettype, 
		Sporttype, 
		apositiontaking, 
		mpositiontaking, 
		spositiontaking, 
		playerdiscount, 
		discount, 
		adiscount, 
		sdiscount, 
		autopositiontaking, 
		isautopositiontaking, 
		autompositiontaking, 
		isautompositiontaking)
	SELECT 
		@custid, 
		Bettype, 
		Sporttype, 
		apositiontaking, 
		mpositiontaking, 
		spositiontaking, 
		playerdiscount, 
		discount, 
		adiscount, 
		sdiscount, 
		autopositiontaking, 
		isautopositiontaking, 
		autompositiontaking, 
		isautompositiontaking
	FROM custsettingGame WITH(NOLOCK)
	WHERE custid = @ExistingCustid

	if @@error <> 0
	BEGIN

		--Error occur
		SELECT @ErrMsg = case @Language 
								when 'E' then 'Create customer failed. Please try again.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
							end,
			@ErrCode = 210
			
		-- ROLLBACK MANUALLY
		DELETE FROM P2PGroupComm WITH (ROWLOCK) WHERE custid =  @CustID
		DELETE FROM dbo.P2PGameSetting WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustSetting3rd WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustSetting WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.Customer WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustInfo WITH(ROWLOCK) WHERE CustID = @CustID
					
		RETURN
	END
		
	---- Create balance for new customer  
	INSERT INTO BalanceCredit (CustID, Balance )  
	VALUES (@CustID, 0)  
	
	if @@error <> 0
	BEGIN

		--Error occur
		SELECT @ErrMsg = case @Language 
								when 'E' then 'Create customer failed. Please try again.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
							end,
			@ErrCode = 210
			
		-- ROLLBACK MANUALLY
		DELETE FROM custsettingGame WITH (ROWLOCK) WHERE custid =  @CustID
		DELETE FROM P2PGroupComm WITH (ROWLOCK) WHERE custid =  @CustID
		DELETE FROM dbo.P2PGameSetting WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustSetting3rd WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustSetting WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.Customer WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustInfo WITH(ROWLOCK) WHERE CustID = @CustID
					
		RETURN
	END
	
	INSERT INTO BalanceDebit (CustID, Balance )  
	VALUES (@CustID, 0)  
	
	if @@error <> 0
	BEGIN

		--Error occur
		SELECT @ErrMsg = case @Language 
								when 'E' then 'Create customer failed. Please try again.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
							end,
			@ErrCode = 210
			
		-- ROLLBACK MANUALLY
		DELETE FROM BalanceCredit WITH (ROWLOCK) WHERE custid =  @CustID
		DELETE FROM custsettingGame WITH (ROWLOCK) WHERE custid =  @CustID
		DELETE FROM P2PGroupComm WITH (ROWLOCK) WHERE custid =  @CustID
		DELETE FROM dbo.P2PGameSetting WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustSetting3rd WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustSetting WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.Customer WITH(ROWLOCK) WHERE CustID = @CustID
		DELETE FROM dbo.CustInfo WITH(ROWLOCK) WHERE CustID = @CustID
					
		RETURN
	END
		
	SET @endRun=GETDATE()
	SET @duration=datediff(millisecond,@startRun,@endRun)
	
	Declare @LogSPData varchar(MAX)
	--Log customer general info
	Select @LogSPData = '<Agm_CustomerInsMember_Ag custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
	'fname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@firstname as varchar(100)),space(1))) + '" ' +
	'lname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@lastname as varchar(100)),space(1))) + '" ' +
	'creator="'+ coalesce(cast(@creator as varchar(50)),space(1)) + '" ' +
	'username="'+ coalesce(cast(@username as varchar(30)),space(1)) + '" ' +
	'phone="'+ dbo.f_EncodeXMLValue(coalesce(cast(@phone as varchar(100)),space(1))) + '" ' +
	'fax="'+ dbo.f_EncodeXMLValue(coalesce(cast(@fax as varchar(100)),space(1))) + '" ' +
	'mphone="'+ dbo.f_EncodeXMLValue(coalesce(cast(@mobilephone as varchar(100)),space(1))) + '" ' +
	'credit="'+ coalesce(cast(@GivenCredit as varchar(50)),space(1)) + '" ' +
	'recommend="'+ coalesce(cast(@recommend as varchar(50)),space(1)) + '" ' +	
	'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +	
	'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +	
	'CopiedFrom="'+cast(@ExistingCustid as varchar(10))+'" '+
	'CopiedFomUsername="'+c.username+'" '+
	'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccountID) as varchar(30)),space(1)) + '" ' +
	'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
	'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(4000)),space(1)) + '" />'
	FROM dbo.customer AS c WITH(NOLOCK) 
	WHERE custid=@ExistingCustid
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @Creator,
			@CustID = @CustID,
			@ActionID = 627,
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY
	BEGIN CATCH
		Select @LogSPData = '<Agm_CustomerInsMember_Ag custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
		'fname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@firstname as varchar(100)),space(1))) + '" ' +
		'lname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@lastname as varchar(100)),space(1))) + '" ' +
		'creator="'+ coalesce(cast(@creator as varchar(50)),space(1)) + '" ' +
		'username="'+ coalesce(cast(@username as varchar(30)),space(1)) + '" ' +
		'phone="'+ dbo.f_EncodeXMLValue(coalesce(cast(@phone as varchar(100)),space(1))) + '" ' +
		'fax="'+ dbo.f_EncodeXMLValue(coalesce(cast(@fax as varchar(100)),space(1))) + '" ' +
		'mphone="'+ dbo.f_EncodeXMLValue(coalesce(cast(@mobilephone as varchar(100)),space(1))) + '" ' +
		'credit="'+ coalesce(cast(@GivenCredit as varchar(50)),space(1)) + '" ' +
		'recommend="'+ coalesce(cast(@recommend as varchar(50)),space(1)) + '" ' +	
		'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +	
		'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +	
		'CopiedFrom="'+cast(@ExistingCustid as varchar(10))+'" '+
		'CopiedFomUsername="'+c.username+'" '+
		'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccountID) as varchar(30)),space(1)) + '" ' +
		'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
		'ErrMsg="'+ ERROR_MESSAGE() + '" />'
		FROM dbo.customer AS c WITH(NOLOCK) 
		WHERE custid=@ExistingCustid
		
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @Creator,
			@CustID = @CustID,
			@ActionID = 627,
			@TrackingValue = @LogSPData,
			@duration = @duration
	END CATCH	
	
	
	SET NOCOUNT OFF
END

GO
GRANT EXECUTE ON [dbo].[Agm_CustomerInsMember_Ag] TO [bodbDownlineNet,wsv_alp]
GO
GRANT VIEW DEFINITION ON [dbo].[Agm_CustomerInsMember_Ag] TO [vnteam]