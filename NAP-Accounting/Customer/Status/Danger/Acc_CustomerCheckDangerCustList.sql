/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerCheckDangerCustList]
	@UsernameList			VARCHAR(MAX) = '',	--List of provided usernames
	@UserID			INT, --Custid of viewer 
	@DangerType			TINYINT = 0,
	@DangerLevel		INT = 0,
	@IP					VARCHAR(15) = '',
	@system VARCHAR(50) = 'NAP',
	@ErrCode			INT = 0				OUTPUT,
	@ErrMsg				NVARCHAR(MAX) = ''	OUTPUT

AS
SET NOCOUNT ON
/*
Created: 
Task : Validate list of username
DB: DBCUST/CUSTDB
Original:

Revisions:	
	- 20200511@Tiara: Enhance validation and error message [Redmine: #129306]
	- 20210519@Winfred: Remove constraints update range 41-50 of Dangerous Setting [Redmine: #155280]
Param's Explanation:
	@UsernameList: List usernames of members will be submited

*/		

BEGIN

	DECLARE @CustId		INT, @IsViewSmartPunter BIT = 1, @IsViewSpeciaSite BIT = 1, @IsViewCN88 BIT = 1, @IsViewCreditSite BIT = 1, @IsViewDepositSite BIT = 1--Checking permission of userid
	SET @ErrCode=0
	DECLARE @tmpCust TABLE (		
						UserName			NVARCHAR(50)					
					, CustID				INT
					, recommend				INT
					, RoleID				TINYINT
					, IsSpecialSite			BIT
					, IsSpecialHeadline     BIT
					, Site                  NVARCHAR(50) 
					, IsEnable				BIT
					, IsView				BIT
					, IsSmartPunter			BIT
					, IsAllowAccess			BIT
					, RowNum				INT IDENTITY (1,1)
					,	PRIMARY KEY CLUSTERED (UserName)
					);
	
	--Get list Username
	INSERT INTO @tmpCust(UserName)
	SELECT DISTINCT ss.val	
	FROM dbo.strSplit(@UsernameList, ',') AS ss	


	-- get custid, roleid, enable, recommend
	UPDATE t
	SET t.CustID=c.custid,RoleID =c.roleid, IsEnable = isnull(enabled,0), recommend = c.recommend
	FROM @tmpCust t 
		INNER JOIN dbo.custInfo c WITH(NOLOCK) ON t.UserName=c.username
	--Get site
	UPDATE t
	SET t.Site = c.site
	FROM @tmpCust t 
		INNER JOIN dbo.Customer c WITH(NOLOCK) ON t.custid= c.custid
	
	UPDATE t
	SET t.Site = c.site
	FROM @tmpCust t 
		INNER JOIN dbo.Customer c WITH(NOLOCK) ON t.recommend= c.custid
	WHERE t.RoleID = 1

	-- select @ErrorCode=100: Invalid usernames: do not exists on system
	IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE CustID is NULL)
	BEGIN
		SELECT @ErrCode=100
		SELECT @ErrMsg= 'Username '+	STUFF((
				SELECT ',' + UserName  
				FROM @tmpCust 
				WHERE CustID IS NULL
				FOR XML PATH('')
			), 1,1,'')+' do(es) not exist.' 
		RETURN
	END
	--Check disable user
	IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE IsEnable = 0)
	BEGIN
		SELECT @ErrCode=101
		SELECT @ErrMsg= 'Username '+	STUFF((
				SELECT ',' + UserName  
				FROM @tmpCust 
				WHERE IsEnable = 0
				FOR XML PATH('')
			), 1,1,'')+' was (were) disabled.' 
		RETURN
	END
	-- select @ErrorCode=106: Invalid usernames: do not exists on system
	IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE RoleID = 0)
	BEGIN
		SELECT @ErrCode=106
		SELECT @ErrMsg= 'You cannot update dangerous level for Headline account(s) '+	STUFF((
				SELECT ',' + UserName  
				FROM @tmpCust 
				WHERE RoleID = 0
				FOR XML PATH('')
			), 1,1,'')
		RETURN
	END
	--end
	--Check permission for account site
	IF @system = 'NAP'
	BEGIN
		EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission_All @custid=@userid,@funcname='[SmartPunter]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
		IF @ErrCode <> 0
			SET @IsViewSmartPunter = 0
		EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission_All @custid=@userid,@funcname='[AccessSpecialSites]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
		IF @ErrCode <> 0
			SET @IsViewSpeciaSite = 0
		EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission_All @custid=@userid,@funcname='[CN88Site]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
		IF @ErrCode <> 0
			SET @IsViewCN88 = 0
		EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission_All @custid=@userid,@funcname='[CreditSite]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
		IF @ErrCode <> 0
			SET @IsViewCreditSite= 0
		EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission_All @custid=@userid,@funcname='[DepositSite]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
		IF @ErrCode <> 0
			SET @IsViewDepositSite= 0
	END
	--Reset error message if error code = 0
	IF @ErrCode = 0
		SET @ErrMsg = NULL
	--Check CN88 site
	IF @IsViewCN88 = 0
		BEGIN
			IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE Site = 'CN88')
			BEGIN
				SELECT @ErrCode=102
				SELECT @ErrMsg= 'You are not authorized to view account '+	STUFF((
						SELECT ',' + UserName  
						FROM @tmpCust 
						WHERE Site = 'CN88'
						FOR XML PATH('')
					), 1,1,'')
				RETURN
			END
		END
	--Check Credit site
	IF @IsViewCreditSite = 0
		BEGIN
			IF EXISTS(SELECT 1
				FROM @tmpCust T
				INNER JOIN Site S WITH (NOLOCK) ON T.Site = S.site
				WHERE S.isLicensee = 0)
			BEGIN
				SELECT @ErrCode=102
				SELECT @ErrMsg= 'You are not authorized to view account '+	STUFF((
						SELECT ',' + UserName  
						FROM @tmpCust T INNER JOIN Site S WITH (NOLOCK) ON T.Site = S.site
						WHERE S.isLicensee = 0
						FOR XML PATH('')
					), 1,1,'')
				RETURN
			END
		END

	--Check Deposit site
		IF @IsViewDepositSite = 0
		BEGIN
			IF EXISTS(SELECT 1
				FROM @tmpCust T
				INNER JOIN Site S WITH (NOLOCK) ON T.Site = S.site
				WHERE S.isLicensee = 1)
			BEGIN
				SELECT @ErrCode=102
				SELECT @ErrMsg= 'You are not authorized to view account '+	STUFF((
						SELECT ',' + UserName  
						FROM @tmpCust T INNER JOIN Site S WITH (NOLOCK) ON T.Site = S.site
						WHERE S.isLicensee = 1
						FOR XML PATH('')
					), 1,1,'')
				RETURN
			END
		END
	
	--Check special FI permission
	DECLARE @CheckFIPermission TABLE (IsView BIT)
	DECLARE @Username NVARCHAR (50), @i INT = 1, @Count INT
	SELECT @Count =  COUNT(*) FROM @tmpCust
	WHILE (@i < = @Count)
	BEGIN
		SELECT TOP 1 @Username = UserName
		FROM @tmpCust
		WHERE RowNum = @i
		
		INSERT INTO @CheckFIPermission (IsView)
		EXEC Acc_SelFIPermission @UserID = @UserID, @username= @Username, @CheckCustId=1
			
		UPDATE t
		SET t.IsView = CH.IsView
		FROM @tmpCust t 
		CROSS JOIN @CheckFIPermission CH
		WHERE T.UserName = @Username

		SELECT @i = @i + 1
	END

	IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE IsView = 0)
	BEGIN
		SELECT @ErrCode=102
		SELECT @ErrMsg= 'Username '+	STUFF((
				SELECT ',' + UserName  
				FROM @tmpCust 
				WHERE IsView = 0
				FOR XML PATH('')
			), 1,1,'')+' is (are) special finance account(s).' 
		RETURN
	END
	--Check Is special site 
	IF @IsViewSpeciaSite = 0  --Skip this check if user can view accounts under special sites (@IsViewSpeciaSite = 1)
	BEGIN
		Set @i = 1
		DECLARE @IsSpecialSite BIT, @IsSpecialHeadline BIT, @Site NVARCHAR(50)
		WHILE (@i < = @Count)
		BEGIN
			SELECT TOP 1 @Username = UserName
			FROM @tmpCust
			WHERE RowNum = @i
		
			EXEC Acc_CustomerIsSpecialSite  @username= @Username, @CheckCustId=1, @IsSpecialSite = @IsSpecialSite OUTPUT, @IsSpecialHeadline = @IsSpecialHeadline OUTPUT, @Site = @Site OUTPUT
			
			UPDATE t
			SET t.IsSpecialSite= ISNULL(@IsSpecialSite,0), t.IsSpecialHeadline = ISNULL (@IsSpecialSite,0), t.Site = ISNULL (@Site,0)
			FROM @tmpCust t 
			WHERE T.UserName = @Username

			SELECT @i = @i + 1
		END
	END
	
	IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE IsSpecialSite = 1 OR IsSpecialHeadline = 1)
	BEGIN
		SELECT @ErrCode=103
		SELECT @ErrMsg= 'Username '+	STUFF((
				SELECT ',' + UserName  
				FROM @tmpCust 
				WHERE IsSpecialSite = 1 OR IsSpecialHeadline = 1
				FOR XML PATH('')
			), 1,1,'')+' is (are) under special site.' 
		RETURN
	END

	--Check Is Allow access 
	Set @i = 1
	DECLARE @IsAllowAccess BIT
	WHILE (@i < = @Count)
	BEGIN
		SELECT TOP 1 @Username = UserName, @CustID = CustID
		FROM @tmpCust
		WHERE RowNum = @i
		
		EXEC Acc_CustomerIsAllowedAccess @Userid = @UserId, @CustName = @username, @CustID= @CustID, @CheckCustId=1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
			
		UPDATE t
		SET t.IsAllowAccess= CASE WHEN (@ErrCode = 0 OR @ErrCode IS NULL) THEN 1 ELSE 0 END 
		FROM @tmpCust t 
		WHERE T.UserName = @Username

		SELECT @i = @i + 1
	END

	IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE IsAllowAccess = 0)
	BEGIN
		SELECT @ErrCode=103
		SELECT @ErrMsg= 'You are not authorized to view account '+	STUFF((
				SELECT ',' + UserName  
				FROM @tmpCust 
				WHERE IsAllowAccess = 0
				FOR XML PATH('')
			), 1,1,'')
		RETURN
	END

	IF @IsViewSmartPunter = 0  --Skip this check if user can view smart punter accounts (@IsViewSmartPunter = 1)
	BEGIN
		--Check Is Smart Punter
		Set @i = 1
		DECLARE @IsSmartPunter BIT
		WHILE (@i < = @Count)
		BEGIN
			SELECT TOP 1 @Username = UserName, @CustId = @CustId
			FROM @tmpCust
			WHERE RowNum = @i
		
			EXEC Acc_CustomerSelCheckSmartPunter  @Custid = @CustId,@Username = @Username, @IsSmartPunter = @IsSmartPunter OUTPUT, @UserId = @UserId,@IsRestricted=0, @ActionID=0,@IP = @IP
			
			UPDATE t
			SET t.IsSmartPunter= ISNULL(@IsSmartPunter,0)
			FROM @tmpCust t 
			WHERE T.UserName = @Username

			SELECT @i = @i + 1
		END
	END
	
	IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE IsSmartPunter = 1)
	BEGIN
		SELECT @ErrCode=103
		SELECT @ErrMsg= 'You are not authorized to view account '+	STUFF((
				SELECT ',' + UserName  
				FROM @tmpCust 
				WHERE IsSmartPunter = 1
				FOR XML PATH('')
			), 1,1,'')
		RETURN
	END

	--end
	--Do not allow to update danger level 41->50 for danger type 1
	--IF @DangerType = 1 AND @DangerLevel BETWEEN 41 AND 50
	--BEGIN	
	--	SELECT	@ErrMsg = 'You are not authorized to update danger level with range [41->50]',
	--			@ErrCode = 102
	--	RETURN	
	--END
	--Do not allow deposit accounts to update Super and Master danger level
	IF EXISTS (SELECT 1
				FROM Customer C WITH (NOLOCK)
				INNER JOIN @tmpCust T ON T.CustID = C.custid 
				INNER JOIN Site S WITH (NOLOCK) ON  C.site = S.site
				WHERE S.isLicensee = 1 AND C.custid = t.CustID AND T.roleid IN (3,4))
		
	BEGIN
		DECLARE @ErrMsg1 NVARCHAR(200), @ErrMsg2 NVARCHAR(200)
		SELECT @ErrCode=105

		SELECT  @ErrMsg1 = 'You cannot update dangerous level for Super accounts '+	STUFF((
				SELECT ',' + T.UserName  
				FROM @tmpCust T
				INNER JOIN Customer C WITH (NOLOCK) ON C.custid = T.CustID
				INNER JOIN Site S WITH (NOLOCK) ON  C.site = S.site
				WHERE S.isLicensee = 1 AND T.RoleID = 4
				FOR XML PATH('')
			), 1,1,'') 
		
		SELECT @ErrMsg2 = 'Master accounts ' +	STUFF((
				SELECT ',' + T.UserName  
				FROM @tmpCust T
				INNER JOIN Customer C WITH (NOLOCK) ON C.custid = T.CustID
				INNER JOIN Site S WITH (NOLOCK) ON  C.site = S.site
				WHERE S.isLicensee = 1 AND T.RoleID = 3
				FOR XML PATH('')
			), 1,1,'')  

		SELECT @ErrMsg = ISNULL(@ErrMsg1,'You cannot update dangerous level for  ') + ISNULL(@ErrMsg2,'')
		RETURN
	END
	
	
END

GO
