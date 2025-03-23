/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerInsMember_CloneSetting_Com]
(
	@Custid INT
	,@UserName VARCHAR(30)
	,@Userpwd VARCHAR(40)
	,@FirstName NVARCHAR(50)= ''
	,@LastName NVARCHAR(50)= ''
	,@Phone NVARCHAR(50)=''
	,@MobilePhone NVARCHAR(50)=''
	,@Fax NVARCHAR(50)=''
	,@Credit MONEY		
	,@ExistingCustid INT
	,@Creator INT	
	,@GroupAdmin VARCHAR(100) = ''
	,@GroupName	VARCHAR(MAX) = ''
	,@Language VARCHAR(2)= 'E'
	,@IP VARCHAR(15)=''		
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT	
	,@Case INT = 0 OUTPUT
	,@Old_Headline INT = 0 OUTPUT
	,@New_Headline INT = 0 OUTPUT
	,@SettingStatus TINYINT = 0
)
AS
/*  
	 Created by: Johnson  
	 Date:20200330 
	 Task: Add new super from existing super for 789y from Ext NAP [Redmine:#130647] 
	 DB: DBCUST/CustDB 

	Revisions:
		- 20200330@Johnson: initial sp [redmine:#130647]
		- 20200513@Johnson: check super's prefix for 789's group [redmine:#133846]
		- 20200601@Johnson: limit new supers per month for 789's group [redmine:#135057]
		- 20200610@Johnson: set new super limit = 200 for 789's group [redmine:#135057]
		- 20200723@Johnson: update errmsg limit supers [redmine:#135057]
		- 20200717@Malcolm : Integrate Credit Term & Staff/Boss Management [RedmineID : #137144]
		- 20201019@Johnson: check group of admin to assign super to EXT group [Redmine:#136501]
		- 20201012@Tina: Add new parameter @SettingStatus [Redmine: #143077]
		- 20201005@Eden: Minimize UM Time Phase 2 [Redmine: #142115]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20210723@Johnson: set new super limit = 300 for 789's group [redmine:#158946]
		- 20210802@Eden: Max Payout Per Match [redmine: #158073]
		- 20220222@Elodie: Default VR for 789y site [Redmine: #168885]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20220823@Johnson: Copy Date Limit range and  Auto Transfer Type for real currency 789y [redmine:#176778] 
		- 20221013@Eden: Remove unused columns from Custinfo table [RedmineID: #179014]
		- 20221122@Johnson: move sp Age_MsgCustReadStatus_Ins to web [RedmineID: #180730]
		- 20221226@Tacy: Alpha/NAP - Split 789y Site [RedmineID: #181596]
		- 20221123@Elodie: Migrate NG and Keno to DCS structure [Redmine: #179711]
		- 20230724@Eden: HotFix - EXT NAP - S&C super [Redmine: #191683]
		- 20230718@Eden: Scale out DBTRANS for Credit [Redmine: #181595]
		- 20230622@Helios: Alpha/ExtNAP - Create new downlines - Remove some obsolete rules [Redmine: #190167] 
		- 20240129@Luke: NAP - Virtual rate - Change default of VR Status for newly created Super to Enable [Redmine: #200311]
		- 20230918@Eden: DCS Sportsbook Credit[redmine: #193083]
		- 20240628@Johnson: scale out DBCUST [redmine: #199915]
		- 20240520@Eden: Unify RNG Games [redmine: #204358] 
		- 20240701@Winfred: Scale Out DBCUST - Apply In-house Replication for Virtual Rate Setting  [redmine: #207029]
		- 20240704@Helen: Revise code for scaleout dbcust - [Redmine:199915]
		- 20240911@Tacy: add param - update CustAccount [Redmine: #209807]
		- 20241209@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]
		- 20241225@July: Scale out DB - In-house Replicator - Support change for SMA TO Control [Redmine: #207042]
		- 20241230@July: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
		- 202503230@Elodie: Hotfix-Apply Inhouse replication [Redmine: #221349]

	Parameter's Explaination:
		@Case = 0 : No change 
		      = 1 : IsGroupHeadline 0-> 0, the User change group
			  = 2 : IsGroupHeadline 1-> 0
			  = 3 : IsGroupHeadline 0-> 1, the User don't change group
			  = 4 : IsGroupHeadline 0-> 1, the User change group
		@GroupAdmin: Ext group assign to admin 	 
		@SettingStatus: 0: Pro, 1: UAT  
	 
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @startRun DATETIME
			,@endRun DATETIME
			,@duration INT			
			,@srecommend INT	
			,@CreditRM MONEY
			,@NotificationInfo VARCHAR(MAX)
			,@CreateDate DATETIME	
	
	SELECT @startRun = GETDATE()		
	SET @CreateDate = GETDATE()		

	-- Check role of existing super
	DECLARE  @roleid tinyint
			,@currency INT
			,@site VARCHAR(10)
			,@SiteLabel VARCHAR(50)			
			,@EnableVR BIT
			,@SiteDBGroupID	smallint
			,@ugroup		VARCHAR(5)
			,@SiteID		INT

	SELECT 
		@roleid = ISNULL(roleid,0), 
		@currency = currency
	FROM dbo.CustInfo WITH(NOLOCK) 
	WHERE custid = @ExistingCustid
		
	SELECT @Site = c.site, @SiteLabel=s.SiteLabel, @SiteDBGroupID = s.SiteDBGroupID, @SiteID = s.siteid
	
		,@startRun = getdate()
		,@currency = currency
		,@srecommend = @CustID
		,@ugroup = ugroup
	FROM dbo.Customer C WITH (NOLOCK)
	INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site
	WHERE CustID = @ExistingCustid	

	BEGIN TRY
		EXEC Acc_CustomerIns
			@FirstName	= NULL	
			,@LastName	= NULL
			,@UserName	= @UserName	
			,@UserPwd	= @UserPwd	 
			,@roleid	= 4	
			,@CustID	= @CustID	
			,@creator	= @creator	

			,@phone			= NULL		
			,@mobilephone	= NULL	
			,@email			= '-'			
			,@fax			= NULL			
			,@address		= '-'	
			,@city			= '-'	
			,@state			= '-'		
			,@country		= '-'	
			,@postal		= '-'	
			,@srecommend	= @CustID	
			,@mrecommend	= 0	
			,@recommend		= 0	
			,@pwdexpiry		= NULL
		
			,@currency		= @currency		
			,@site			= @site			
			,@ugroup		= @ugroup
			,@birthday		= NULL
			,@refcode1		= NULL
			,@refcode2		= NULL
			,@remark		= NULL	
			,@important		= 0	
			
			,@ErrCode = @ErrCode OUTPUT
			,@ErrMsg  = @ErrMsg OUTPUT	
	
		IF ISNULL(@ErrCode,0) > 0
		BEGIN
			SELECT @ErrMsg = CASE @Language 
								WHEN 'E' THEN 'Create customer failed. Please try again.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language) 
							end
				,@ErrCode = 103
			
			EXEC Acc_CustomerInsUserInfo_Rollback @CustID = @CustID

			RETURN
		END
	
		-- insert CustSuper info
		DECLARE @MaxMember INT, @MaxMemberLog VARCHAR(50)
		SELECT @MaxMember = CASE WHEN @SiteLabel = '789y' THEN 20000 ELSE -1 END
		SELECT @MaxMemberLog = CASE WHEN @SiteLabel = '789y' THEN '20000' ELSE 'Unlimited' END

		INSERT INTO CustSuper(custId,IsInternal, TransferOption, LimitPerIP, SelectedBetting,MaxMember, IsAllDayBalTransfer,SiteDBGroupID,RepUpdateTime)  
		SELECT	@CustID, 0, TransferOption, LimitPerIP, SelectedBetting, @MaxMember, IsAllDayBalTransfer,@SiteDBGroupID, dbo.f_GetDateTime2()
		FROM CustSuper WITH(NOLOCK)
		WHERE custid=@ExistingCustid	
		
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = CASE @Language   
						   WHEN 'E' THEN 'Create customer failed. Please try again.'  
						   ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
						  END,  
				@ErrCode = 105  

		-- ROLLBACK MANUALLY
		EXEC Acc_CustomerInsUserInfo_Rollback @CustID = @CustID
		RETURN 
	END CATCH
	
	SELECT @CreditRM = @credit * actualrate
	FROM dbo.exchange WITH (NOLOCK) 
	WHERE exchangeid = @currency
	
	--SELECT @EnableVR = EnableVR FROM f_GenerateVirtualStatusBySite (@Site)
	SELECT @EnableVR = 1 --Enable as default [#200311]

	BEGIN TRY
		-- insert CustInfo info
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
				,credit
				,MatchLimit
				,VirtualMultiplier
				,Enabled   							       
				,DisableOutright				
				,DoubleCommLosing	
				,DisableSuperLive
				,RepUpdateTime
				)
		 SELECT
				@CustID
				,@username
				,currency
				,4 AS roleid
				,@Custid
				,0 as mrecommend
				,0 as recommend
				,dangercust
				,0 AS autosuspend
				,@Credit AS Credit
				,MatchLimit
				,@EnableVR AS VirtualMultiplier
				,Enabled  						
				,DisableOutright				
				,doubleCommLosing		
				,DisableSuperLive
				,dbo.f_GetDateTime2()
		FROM dbo.custinfo WITH(NOLOCK)
		WHERE custid=@ExistingCustid  
		
		IF @CreditRM > 300000
		BEGIN
			INSERT INTO SuspiciousCust (CustID, NotifyStatus1, NotifyStatus2, RepUpdateTime)
			SELECT @CustId, 1, 0, dbo.f_GetDateTime2()
		END

		DECLARE @ProductProfile VARCHAR(MAX) = ''

		EXEC dbo.Acc_CustomerInfo_Execrep_02
			@custid = @custid,
			@ExistingCustid = @ExistingCustid,
			@Language = @Language,
			@SettingStatus = @SettingStatus,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT,
			@ProductProfile	= @ProductProfile OUTPUT
			
		IF @ErrCode > 0 
		BEGIN
			SELECT @ErrMsg = CASE @Language 
							WHEN 'E' THEN 'Create customer failed. Please try again.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
						end
			,@ErrCode = 106

			-- ROLLBACK MANUALLY			
			EXEC Acc_CustomerInsSetting_Rollback @CustID = @CustID, @RoleID = 4
			EXEC Acc_CustomerInsUserInfo_Rollback @CustID = @CustID
			RETURN
		END

		-- Start : Initialize Data 3rd Products
		EXEC dbo.Acc_Custsetting_CloneSetting_3rdProductIns
			@custid = @custid,
			@ExistingCustID = @ExistingCustid,
			@RoleID = @RoleID,
			@SiteID = @SiteID,
			@Currency = @Currency,
			@ProductProfile = @ProductProfile,
			@ErrCode = @ErrCode OUTPUT,
			@SettingStatus	= @SettingStatus

		IF @ErrCode > 0 
		BEGIN
			SELECT @ErrMsg = CASE @Language 
									WHEN 'E' THEN 'Create customer failed. Please try again.'
									ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
								end
					,@ErrCode = 106
				EXEC Acc_CustomerInsSetting_Rollback @CustID = @CustID, @RoleID = 4
				EXEC Acc_CustomerInsUserInfo_Rollback @CustID = @CustID
			RETURN
		END	
		-- End : Initialize Data 3rd Products

		-- Start : Initialize Data SportsBook
		EXEC dbo.Acc_Custsetting_CloneSetting_SportsbookIns
			@custid = @custid,
			@ExistingCustid = @ExistingCustid,
			@Language = @Language,
			@SettingStatus = @SettingStatus,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode >0 
		BEGIN
			SELECT @ErrMsg = CASE @Language 
									WHEN 'E' THEN 'Create customer failed. Please try again.'
									ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
								end
					,@ErrCode = 106
			-- ROLLBACK MANUALLY			
			EXEC Acc_CustomerInsSetting_Rollback @CustID = @CustID, @RoleID = 4
			EXEC Acc_CustomerInsUserInfo_Rollback @CustID = @CustID	
			RETURN
		END
	-- End : Initialize Data SportsBook


		DECLARE @isForcedChangeSecurityCode BIT = 0, @ClosedReason TINYINT=0,@Closed BIT,
			@SystemID INT = 4 --EXT NAP

		SELECT TOP 1 @Closed= CASE WHEN cps.CloseInfo > 0 THEN 1 ELSE 0 END
		FROM CustProductStatus cps WITH(NOLOCK) 
		WHERE custid=@ExistingCustid

		IF (@SystemID=1 AND @Closed=1)
			SELECT @ClosedReason=1
		ELSE IF(@SystemID<>1 AND @Closed=1)
			SELECT @ClosedReason=2
		ELSE 
			SELECT @ClosedReason=0

		SELECT @isForcedChangeSecurityCode = 1

		INSERT INTO dbo.CustLoginInfo
		(
		    CustID, OldUserPwd, LastChangedPwdDate, isFirstLogin, SecurityCodeCount,
		    SecurityCode, isForcedChangeSecurityCode, LastChangedSecurityCodeDate,ClosedReason
		  , RepUpdateTime
		)
		VALUES
		(   @custid, NULL, GETDATE(), 1, 0,
		    NULL, @isForcedChangeSecurityCode, NULL,@ClosedReason
		  , dbo.f_GetDateTime2()
		)
		INSERT INTO [dbo].[CustVirtualSetting] (custid, seqNo, bitmapVirtual,RepUpdateTime)
		SELECT custid, seqNo, bitmapVirtual,[dbo].[f_GetDateTime2]() AS RepUpdateTime FROM f_GenerateVirtualSettingBySite (@Site,@CustID)
	
		INSERT INTO CustDirectAccount (CustID,ApprovedBy,Boss,ProcessedBy,RequestedBy, Coll_Status, RepUpdateTime)
		SELECT ci.custid,'' AS ApprovedBy,'' AS Boss,'' AS ProcessedBy,'' AS RequestedBy, NULL AS Coll_Status, dbo.f_GetDateTime2() AS RepUpdateTime
		FROM Customer ci WITH(NOLOCK)
		WHERE CI.custid = @custid AND ci.Custid NOT IN (SELECT custid from Acc_CustDirect WITH(NOLOCK))
		
		IF @@ROWCOUNT <> 0 
		BEGIN
			EXEC dbo.Acc_CreditCollStatusInit @CustId = @custid, @UserId = @creator, @IP = @IP, @Language = @Language
				
			SELECT @NotificationInfo = '<NewDirectCustomer  custid="'+ COALESCE(CAST(@custid AS VARCHAR(50)), SPACE(1)) + '" />'
			EXEC dbo.NAP_Email_NotificationInfoInsert @ActionID = 600,@NotificationInfo = @NotificationInfo, @CreateDate = @CreateDate
				
			INSERT INTO dbo.TOControl_GlobalSetting (CustID, MaxTurnOver, Sporttype, IsGroupHeadLine, ProfileID, RepUpdateTime)
			SELECT @custid
					-- Since there are many kinds of currency default setting, default setting will be converted to RM before convert to orginal curency
					, CASE 
							-- currency RM in default Setting
							WHEN TO_tmp.TOCurrency = 2 THEN CONVERT(MONEY,TO_tmp.MaxTurnOver / E1.actualrate) 
							-- NOT currency RM in default Setting
							ELSE  CONVERT(MONEY,(TO_tmp.MaxTurnOver * E.actualrate)/E1.actualrate)
					END AS MaxTurnOver
					, TO_tmp.Sporttype, 0, TO_tmp.ProfileID
					, dbo.f_GetDateTime2()
			FROM (        
					-- Soccer 
					SELECT TOP 10 f1.sporttype, f1.MaxTurnOver,f1.TOCurrency, f1.ProfileID
					FROM dbo.f_TOControl_GlobalSettingSel () f1                
					WHERE f1.site IN (@site,'') AND f1.ExchangeID IN (@currency,0) AND f1.sporttype = 1        
					ORDER BY f1.site DESC, f1.ExchangeID DESC                
		                
					UNION ALL
					-- Others sport
					SELECT TOP 10 sporttype, MaxTurnOver,TOCurrency, f2.ProfileID
					FROM dbo.f_TOControl_GlobalSettingSel () f2                
					WHERE f2.site IN (@site,'') AND f2.ExchangeID IN (@currency,0) AND f2.sporttype = 99
					ORDER BY f2.site DESC, f2.ExchangeID DESC
					) AS TO_tmp
	                            
				INNER JOIN dbo.Exchange e WITH (NOLOCK) ON e.ExchangeID = TO_tmp.TOCurrency
				INNER JOIN dbo.Exchange e1 WITH (NOLOCK) ON e1.ExchangeID = @currency
					
		END		  
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = CASE @Language 
								WHEN 'E' THEN 'Create customer failed. Please try again.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
							end
				,@ErrCode = 106
			
		-- ROLLBACK MANUALLY			
		EXEC Acc_CustomerInsSetting_Rollback @CustID = @CustID, @RoleID = 4
		EXEC Acc_CustomerInsUserInfo_Rollback @CustID = @CustID
		RETURN
	END CATCH	
	
	--add credit term	
	DECLARE @GroupID INT, @HeadlineName VARCHAR(30), @HeadlineID INT
	
	SELECT @GroupID = GroupID
	FROM CustAccount WITH(NOLOCK)
	WHERE custid = @ExistingCustid
	-- get information of headline
	SELECT @HeadlineID = CustId FROM dbo.CustGroupHeadline WITH(NOLOCK) WHERE GroupID = @GroupID
	SELECT @HeadlineName = Username FROM dbo.Customer WITH(NOLOCK) WHERE custid = @HeadlineID
	
	IF @GroupID IS NOT NULL
	BEGIN
		Declare @creditgrade nvarchar(1),
			@preagreeamount money,
			@installmentamount money,
			@installmentdate nvarchar(50),
			@accountremark nvarchar(200)

		select @New_Headline = custid,
			@creditgrade = creditgrade, 
			@installmentdate = installmentdate,
			@installmentamount = installmentamount,
			@preagreeamount = preagreeamount,
			@accountremark = ' '
		from custaccount with (nolock)
		where isgroupheadline = 1 and groupid = @groupID

		EXEC dbo.Acc_CreditTermUpdCollStatus 
			@CustId = @custid, 
			@UserID = @creator, 
			@IP = @IP, 
			@Language = @Language, 
			@Mode = 3,
			@OldGroupId = 0, 
			@NewGroupId = @groupID, 
			@Old_IsGroupHeadline = 0, 
			@New_IsGroupHeadline = 0	
		
		EXEC dbo.Acc_CreditTermUpdCustAccount 
			@custid = @custid,
			@creditgrade = @creditgrade,
			@preagreeamount = @preagreeamount,
			@installmentamount = @installmentamount,
			@installmentdate = @installmentdate,
			@accountremark = @accountremark,
			@groupID = @groupID,
			@isgroupheadline = 0,
			@UserID = @creator, 
			@IP = @IP
		
	    SELECT @Case = 1, @Old_Headline = 0
		
		SELECT @NotificationInfo = '<GroupHeadline custid="'+ COALESCE(CAST(@custid AS VARCHAR(50)), SPACE(1)) + '" ' +
									'GroupID="'+ COALESCE(CAST(@groupid AS VARCHAR(50)),SPACE(1)) + '" />'
		-- Send email notification for create new
		DECLARE @currentTime DATETIME = GETDATE()
		
		EXEC dbo.NAP_Email_NotificationInfoInsert @ActionID = 1000,@NotificationInfo = @NotificationInfo, @CreateDate = @currentTime	
	END	
	--END credit term

	--add external group
	INSERT INTO dbo.Acc_CustGroup (CustID, RoleID, GroupName, RepUpdateTime)
	SELECT a.CustId, a.RoleID, a.GroupName, dbo.f_GetDateTime2()
	FROM (SELECT @CustID CustId, @RoleID RoleID, GroupName
		FROM Acc_CustGroup WITH(NOLOCK)
		WHERE custid = @ExistingCustid
			AND GroupName IN (SELECT f.[value] AS GroupName FROM STRING_SPLIT(@GroupName, ',') AS f )
		UNION 
		SELECT @CustID, @RoleID, CASE WHEN @currency = 20 THEN 'ACCUUS2' ELSE 'ACCUSD' END) a

	
	INSERT INTO [CustDB].[dbo].[CustSuperProfile]
           ([custid]
           ,[firstname]
           ,[lastname]
           ,[phone]
           ,[mobilephone]
           ,[fax]
		   ,RepUpdateTime
           )
	VALUES (@custid,@firstname,@lastname,@phone,@mobilephone,@fax,dbo.f_GetDateTime2())
	
	DECLARE @transferType TINYINT,
			@MinDate SMALLDATETIME,
			@LimitDays SMALLINT,
			@NoLimitText VARCHAR(100) = 'No Limit',
			@IsLogDateLimit BIT = 0
			
	--auto transfer 
	SELECT @transferType = TransferType,
		@IsLogDateLimit = 1
	FROM Acc_ClearBalanceList WITH(NOLOCK)
	WHERE custid = @ExistingCustid
	
	IF @@ROWCOUNT > 0
	BEGIN
		INSERT INTO [dbo].[Acc_ClearBalanceList]
			   ([custid] 
			   ,[status]
			   ,[LastTransfer]           
			   ,[transferType])       
		SELECT @custid,'', GETDATE()-1, @TransferType
	END
	
	--copy Date limit value
	SELECT @MinDate = MinDate,
		@LimitDays = LimitDays,
		@IsLogDateLimit = 1
	FROM Age_CustDateLimit WITH(NOLOCK)
	WHERE custid = @ExistingCustid
	
	IF @@ROWCOUNT > 0
	BEGIN
		INSERT INTO [dbo].[Age_CustDateLimit]
			   ([CustId]
			   ,[MinDate]
			   ,[LimitDays]
			   ,RepUpdateTime
		)
		SELECT @custId, @MinDate, @LimitDays, dbo.f_GetDateTime2()	
	END	
		
	SET @endRun=GETDATE()
	SET @duration=datediff(millisecond,@startRun,@endRun)
	
	Declare @LogSPData VARCHAR(8000)
	--Log customer general info
	SELECT @LogSPData = '<EAS_CustomerInsMember_CloneSetting_Com custid="'+ coalesce(cast(@custid as VARCHAR(50)),space(1)) + '" ' +
	'fname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@firstname as VARCHAR(100)),space(1))) + '" ' +
	'lname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@lastname as VARCHAR(100)),space(1))) + '" ' +
	'creator="'+ coalesce(cast(@creator as VARCHAR(50)),space(1)) + '" ' +
	'username="'+ coalesce(cast(@username as VARCHAR(30)),space(1)) + '" ' +
	'phone="'+ dbo.f_EncodeXMLValue(coalesce(cast(@phone as VARCHAR(100)),space(1))) + '" ' +
	'fax="'+ dbo.f_EncodeXMLValue(coalesce(cast(@fax as VARCHAR(100)),space(1))) + '" ' +
	'mphone="'+ dbo.f_EncodeXMLValue(coalesce(cast(@mobilephone as VARCHAR(100)),space(1))) + '" ' +
	'site="'+ coalesce(cast(@site as VARCHAR(50)),space(1)) + '" ' +	
	'credit="'+ coalesce(cast(@Credit as VARCHAR(50)),space(1)) + '" ' +	
	'MaxMember="'+ coalesce(@MaxMemberLog,space(1)) + '" ' +		
	'GroupAdmin="'+ coalesce(@GroupAdmin,space(1)) + '" ' +
	CASE WHEN @IsLogDateLimit = 1 THEN 'TransferType="'+ coalesce(CAST(@transferType as VARCHAR(10)) ,space(1)) + '" ' ELSE '' END +
	CASE WHEN @IsLogDateLimit = 1 THEN 'DataAvailable="'+ COALESCE(CAST(@LimitDays AS VARCHAR(10)), CONVERT(VARCHAR, @MinDate, 101), @NoLimitText) + '" ' ELSE '' END +	
	'IP="'+ coalesce(cast(@IP as VARCHAR(15)),space(1)) + '" ' +	
	'Language="'+ coalesce(cast(@Language as VARCHAR(2)),space(1)) + '" ' +	
	'CopiedFrom="'+cast(@ExistingCustid as VARCHAR(10))+'" '+
	'CopiedFromUsername="'+c.username+'" '+
	'ErrCode="'+ coalesce(cast(@ErrCode as VARCHAR(50)),space(1)) + '" ' +
	'ErrMsg="'+ coalesce(cast(@ErrMsg as VARCHAR(4000)),space(1)) + '" />'
	FROM dbo.customer AS c WITH(NOLOCK) 
	WHERE custid=@ExistingCustid
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @Creator,
			@CustID = @CustID,
			@ActionID = 95009,
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY
	BEGIN CATCH	
		--Log customer general info
		SELECT @LogSPData = '<EAS_CustomerInsMember_CloneSetting_Com custid="'+ coalesce(cast(@custid as VARCHAR(50)),space(1)) + '" ' +
		'fname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@firstname as VARCHAR(100)),space(1))) + '" ' +
		'lname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@lastname as VARCHAR(100)),space(1))) + '" ' +
		'creator="'+ coalesce(cast(@creator as VARCHAR(50)),space(1)) + '" ' +
		'username="'+ coalesce(cast(@username as VARCHAR(30)),space(1)) + '" ' +
		'phone="'+ dbo.f_EncodeXMLValue(coalesce(cast(@phone as VARCHAR(100)),space(1))) + '" ' +
		'fax="'+ dbo.f_EncodeXMLValue(coalesce(cast(@fax as VARCHAR(100)),space(1))) + '" ' +
		'mphone="'+ dbo.f_EncodeXMLValue(coalesce(cast(@mobilephone as VARCHAR(100)),space(1))) + '" ' +
		'site="'+ coalesce(cast(@site as VARCHAR(50)),space(1)) + '" ' +	
		'credit="'+ coalesce(cast(@Credit as VARCHAR(50)),space(1)) + '" ' +	
		'MaxMember="'+ coalesce(@MaxMemberLog,space(1)) + '" ' +
		'GroupAdmin="'+ coalesce(@GroupAdmin,space(1)) + '" ' +
		CASE WHEN @IsLogDateLimit = 1 THEN 'TransferType="'+ coalesce(CAST(@transferType as VARCHAR(10)) ,space(1)) + '" ' ELSE '' END +
		CASE WHEN @IsLogDateLimit = 1 THEN 'DataAvailable="'+ COALESCE(CAST(@LimitDays AS VARCHAR(10)), CONVERT(VARCHAR, @MinDate, 101), @NoLimitText) + '" ' ELSE '' END +	
		'IP="'+ coalesce(cast(@IP as VARCHAR(15)),space(1)) + '" ' +	
		'Language="'+ coalesce(cast(@Language as VARCHAR(2)),space(1)) + '" ' +	
		'CopiedFrom="'+cast(@ExistingCustid as VARCHAR(10))+'" '+
		'CopiedFromUsername="'+c.username+'" '+
		'ErrCode="'+ coalesce(cast(ERROR_NUMBER() as VARCHAR(50)),space(1)) + '" ' +
		'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as VARCHAR(4000)),space(1)) + '" />'
		FROM dbo.customer AS c WITH(NOLOCK) 
		WHERE custid=@ExistingCustid
		
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @Creator,
			@CustID = @CustID,
			@ActionID = 95009,
			@TrackingValue = @LogSPData,
			@duration = @duration		
	END CATCH

	BEGIN TRY
		SELECT @LogSPData = '<EAS_CustomerInsMember_CloneSetting_Com HeadlineID="' + CAST(ISNULL(@HeadlineID,'') AS VARCHAR(20)) +'" HeadlineName="'+ ISNULL(@HeadlineName, 'Not assigned group') +'"/>'
		EXEC DBCRM.bodb_CRM.dbo.WriteLog_UserLog_crmUserLog_RunSP
			@UserID = @Creator,
			@CustID = @CustID,
			@ActionID = 913,
			@IP = @IP,
			@NewValues = @LogSPData				
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 107, @ErrMsg = 'Internal error! Please try again or contact the administrator!'
		RETURN
	END CATCH
		
	SET NOCOUNT OFF
END 
GO 

