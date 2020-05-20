/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerCheckDangerCustList]
	@UsernameList			VARCHAR(MAX) = '',	--List of provided usernames
	@UserName			NVARCHAR(50),
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

	DECLARE @CustId		INT, @RoleID INT
	DECLARE @UserId		INT
	
	SET @ErrCode=0

	SELECT @UserID=CustID FROM dbo.Custinfo WITH(NOLOCK) WHERE username=@UserName

	DECLARE @tmpCust TABLE (		
						UserName			NVARCHAR(50)					
					,	CustID				INT
					,	PRIMARY KEY CLUSTERED (UserName)
					);
	
	--Get list Username
	INSERT INTO @tmpCust(UserName)
	SELECT ss.val	
	FROM dbo.strSplit(@UsernameList, ',') AS ss	
	
	-- get custid, roleid
	UPDATE t
	SET t.CustID=c.custid
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

	--Check permission for account site: @phuc20080213
	IF @system = 'NAP'
	BEGIN
		EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
		
		IF @ErrCode <> 0
			RETURN
	END
	ELSE IF @system = 'NAP-CM'		
	BEGIN
		DECLARE @CheckPermission VARCHAR(MAX) = ''
		SELECT @CheckPermission = @CheckPermission + 'EXEC NAP_UserControl.dbo.NAP_User_CheckPermission  @UserId=' + ltrim(CustID) + '@FunctionKey=''PossessStatistics_CN88_DangerLevel'',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT;'
		FROM @tmpCust
		EXEC(@CheckPermission );
		IF @ErrCode <> 0
			RETURN
	END
	--end
	--Check disable user
	DECLARE @CheckEnable VARCHAR(MAX) = ''
	SELECT @CheckEnable = @CheckEnable + 'EXEC Acc_CustomerSelCheckEnable  @Custid=' + ltrim(CustID) + '@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT;'
	FROM @tmpCust
	EXEC(@CheckPermission );
	IF @ErrCode <> 0
		RETURN
	--end
	
	IF @DangerType = 1 AND @DangerLevel BETWEEN 41 AND 50
	BEGIN	
		SELECT	@ErrMsg = 'You are not authorized to update danger level with range [41->50]',
				@ErrCode = 102
		RETURN	
	END
	--Do not allow deposit accounts to update Super and Master danger level
	IF EXISTS (SELECT 1
				FROM Customer C WITH (NOLOCK)
				INNER JOIN Site S WITH (NOLOCK) ON  C.site = S.site
				WHERE S.isLicensee = 1 AND C.custid = @CustID) 
		AND @roleid IN (3,4)
	BEGIN
		SELECT	@ErrMsg = 'You can not update dangerous level for Super/ Master accounts.',
				@ErrCode = 103
		RETURN
	END
	
	
END

GO
