/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdMoveSite]
	@UserId			INT,
	@CustId			INT	,
	@Site			varchar(50),
	@ErrCode		INT OUTPUT,
	@ErrMsg			varchar(200) OUTPUT,
	@IP				varchar(50) = ''
AS
/*	Created by: [Khoa] 
	Date: 20091224
	Task: Move Site for customer
	DB: DBCUST/CUSTDB

	Revisions:		
		- 20100112@Kiwi: amend to write log in xml format.
		- 20101021@Henry: Record execution time
		- 20110907@Sophia: Change Linked Server from DB052 to DB053	
		- 20120718@Dan: add 1 more field "site" in CustAgent table
		- 20130218@Dan: Change linked server DB03 to DBPOLICY, DB053 to DBAGE; Write more log on DBTXN server in case of DBLOG server failure
		- 20150904@Helen: commission setting for MO [Redmine #41470]
		- 20151026@Don: Support moving site from 766666 to other sites
		- 20160707@Winnie: Feature #48948 Hide_special_sites_from_unautorized_users
		- 20180808@Helen: DB05.DBPOLICY migration  [Redmine:99462]
		- 20190814@Johnson: dont move cn88 site [redmine:#116691]
		- 20200915@Johnson: check dont move deposit site [redmine:#141257]
		- 20200918@Winfred: Reinsert MyanmarOdds [Redmine: #141926]
		- 20201103@Tina: move site for members level [Redmine: #144323]
		- 20210202@Winfred : Virtual Rate for Basketball - New 611111 site super must have VR setting = 0%   [Redmine: #149369]	
		- 20220419@Eden: Turn off VR Basketball & E-sports for 611111 site [Redmine: #171609]
		- 20230112@Tacy: Alpha/NAP - Split 789y Site [RedmineID: #181596]
		- 20230317@Johnson: Return Basketball VR to its original state [redmine:#184339]
		- 20230418@Tacy: allow Member move site [RedmineID: 181596]
		- 20231219@Tacy: NAP - Move sites among 789y and other site labels with YNG currency for testing
		- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
		- 20240701@Winfred: Scale Out DBCUST - Apply In-house Replication for Virtual Rate Setting  [redmine: #207029]
		- 20241010@Helen: Temporarily RETURN SP - [Redmine:#212007]
		- 20241010@Helen: move site for CREDIT - [Redmine:#212007]
		- 20241101@Winfred: HF  - NAP- Cannot updating VR value for licensee super line with big downline member (over 500000 members downline)  [redmine: #213009]

	Param's Explanation:
		@CustID: Custid of customer want to move site. We allow to move all customers
*/

BEGIN
	SET NOCOUNT ON
	

	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	declare @SiteLabel VARCHAR(50)
	DECLARE @RoleId int	

	DECLARE @OldSite varchar(50), @OldSiteLabel varchar(50), @LogSPData varchar(8000)
	DECLARE @userName VARCHAR(50),@currency TINYINT

	SELECT @OldSite =  c.site, @OldSiteLabel = s.SiteLabel
	from customer c with(nolock) 
		inner join site s with (nolock) on s.site=c.site
	where custid = @CustId	
	
	set @startRun = getdate()

	SELECT @RoleId = ISNULL(roleid,0) FROM custinfo (NOLOCK) WHERE custid=@CustId

	EXEC dbo.Acc_CustomerInfo_Execrep_06
	    @custid = @custid,
	    @roleid = @roleid,
		@site = @site,
	    @ErrCode = @ErrCode OUTPUT

    IF @ErrCode > 0
    BEGIN
	    SELECT @ErrMsg = 'Update customer fail. Please try again'
	    RETURN
    END	 

	--New 611111 super must have VR setting = 0% (ESport level)
	 IF @site = '611111' AND (@RoleId = 4 OR EXISTS(SELECT 1 FROM dbo.CustDirectAccount (NOLOCK) WHERE custid = @CustId))
	 BEGIN		
		DECLARE @VirtualRateMultiplier2 VARCHAR(MAX) = '' --Esports
		SELECT @VirtualRateMultiplier2 = CONVERT(VARCHAR(MAX),(  SELECT b.LevelID,vr.ValueID AS ValueIDLive,vr.ValueID AS ValueIDNonLive 
															FROM VRSettingHierarchy b WITH(NOLOCK) 
																CROSS APPLY VRValueMapping vr (NOLOCK)
															WHERE b.SportType = 43 
																AND b.VRLeagueGroupID = -1 
																AND b.BetType = -1 
																AND vr.Value = 1
															FOR XML RAW('Row'), ROOT ('Root'))
											)

		EXEC [Acc_CustVirtualMultiplier_Upd]
			  @CustID = @CustID
			, @SportType = 43
			, @VirtualMultiplier = @VirtualRateMultiplier2
			, @UserID  = @UserId
			, @IP  = @IP
			, @ErrCode = @ErrCode OUTPUT 
			, @ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode > 0
		BEGIN
			SELECT @ErrMsg = 'Update VRCustSetting fail. Please try again'
			RETURN
		END	

		--Add to [VRSettingManualUpdAcc]
		INSERT INTO [VRSettingManualUpdAcc](CustID,SportType,RepUpdateTime)		
		SELECT @CustID,43 AS SportType, [dbo].[f_GetDateTime2]() AS RepUpdateTime
		WHERE NOT EXISTS (SELECT 1 FROM VRSettingManualUpdAcc WHERE custid = @CustId AND SportType = 43)	

		--Call sp execrep in order to add all downline to VRSettingManualUpdAcc, and remove all downline's private VR
		EXEC [dbo].[Acc_CustomerInfo_Execrep_05] 
			@custid = @custid
			,@roleid = @roleid
			,@action = 'DisableVR2Downline'
			,@Sporttype = 2

		--Call sp execrep in order to add all downline to VRSettingManualUpdAcc, and remove all downline's private VR, And set all member with Override AS = 1
		EXEC [dbo].[Acc_CustomerInfo_Execrep_05] 
			@custid = @custid
			,@roleid = @roleid
			,@action = 'DisableVR2Downline'
			,@Sporttype = 43
	 END

	--print('write log')-- Write Log Here
	SELECT @LogSPData = '<Acc_CustomerUpdMoveSite OldSite="'+ @OldSite + '" ' +
						'NewSite="'+ @Site  + '" ' +
						'IP="'+ @IP  + '" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserId,
		@CustID = @CustId,
		@ActionID = 614,
		@TrackingValue = @LogSPData,
		@duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogSPData = '<Acc_CustomerUpdMoveSite OldSite="'+ @OldSite + '" ' +
			'NewSite="'+ @Site  + '" ' +
			'IP="'+ @IP + '" ' + 
			'ErrCode="'+ COALESCE(CAST(ERROR_NUMBER() AS VARCHAR(50)),SPACE(1)) + '" ' + 
			'ErrMsg="'+ COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" />'
			
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserId,
		@CustID = @CustId,
		@ActionID = 614,
		@TrackingValue = @LogSPData,
		@duration = @duration
	END CATCH	
END

GO

