/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerCheckDangerCustList]
	@UsernameList			VARCHAR(MAX) = '',	--List of provided usernames
	@UserID			INT, --Custid of viewer 
	@DangerType			TINYINT = 0,
	@DangerLevel		INT = 0,
	@IP					VARCHAR(15) = '',
	@system VARCHAR(50) = 'NAP',
	@ErrCode			INT = 0				OUTPUT,
	@ErrMsg				NVARCHAR(200) = ''	OUTPUT

AS
SET NOCOUNT ON
/*
Created: 
Task : Validate list of username
DB: DBCUST/CUSTDB
Original:

Revisions:	
	- 20200511@Tiara: Enhance validation and error message [Redmine: #129306]
Param's Explanation:
	@UsernameList: List usernames of members will be submited

*/		

BEGIN

	DECLARE @CustId		INT
	SET @ErrCode=0
	DECLARE @tmpCust TABLE (		
						UserName			NVARCHAR(50)					
					, CustID				INT
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
	SELECT ss.val	
	FROM dbo.strSplit(@UsernameList, ',') AS ss	


	
	-- get custid, roleid
	UPDATE t
	SET t.CustID=c.custid,RoleID =c.roleid, IsEnable = isnull(enabled,0)
	FROM @tmpCust t 
		INNER JOIN dbo.custInfo c WITH(NOLOCK) ON t.UserName=c.username

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

	--end
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

	--Check permission for account site: @phuc20080213
	IF @system = 'NAP'
	BEGIN
		EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
		
		IF @ErrCode <> 0
			RETURN
	END
	ELSE IF @system = 'NAP-CM'		
	BEGIN
		EXEC NAP_UserControl.dbo.NAP_User_CheckPermission @UserId=@userid,@SiteKey='CustomerManagement',@FunctionKey='PossessStatistics_CN88_DangerLevel',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
		
		IF @ErrCode <> 0
			RETURN		
	END
	--end
	--Do not allow to update danger level 41->50 for danger type 1
	IF @DangerType = 1 AND @DangerLevel BETWEEN 41 AND 50
	BEGIN	
		SELECT	@ErrMsg = 'You are not authorized to update danger level with range [41->50]',
				@ErrCode = 102
		RETURN	
	END
	--Do not allow deposit accounts to update Super and Master danger level
	IF EXISTS (SELECT 1
				FROM Customer C WITH (NOLOCK)
				INNER JOIN @tmpCust T ON T.CustID = C.custid 
				INNER JOIN Site S WITH (NOLOCK) ON  C.site = S.site
				WHERE S.isLicensee = 1 AND C.custid = @CustID AND T.roleid IN (3,4))
		
	BEGIN
		SELECT @ErrCode=105
		SELECT  @ErrMsg= 'You cannot update dangerous level for Super accounts '+	STUFF((
				SELECT ',' + T.UserName  
				FROM @tmpCust T
				INNER JOIN Customer C WITH (NOLOCK) ON C.custid = T.CustID
				INNER JOIN Site S WITH (NOLOCK) ON  C.site = S.site
				WHERE S.isLicensee = 1 AND T.RoleID = 4
				FOR XML PATH('')
			), 1,1,'') + 'Master accounts ' +	STUFF((
				SELECT ',' + T.UserName  
				FROM @tmpCust T
				INNER JOIN Customer C WITH (NOLOCK) ON C.custid = T.CustID
				INNER JOIN Site S WITH (NOLOCK) ON  C.site = S.site
				WHERE S.isLicensee = 1 AND T.RoleID = 3
				FOR XML PATH('')
			), 1,1,'')  
		RETURN
	END
	
	
END

GO
