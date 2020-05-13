/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelDangerCustList]
	@UsernameList			VARCHAR(MAX) = '',	--List of provided usernames
	@UserName			NVARCHAR(50),
	@IP					VARCHAR(15) = '',
	@ErrCode			INT = 0				OUTPUT,
	@ErrMsg				NVARCHAR(200) = ''	OUTPUT	
AS
SET NOCOUNT ON
/*
Created: 
Task : Validate list of usernames
DB: DBCUST/CUSTDB
Original:

Revisions:	
	- 20200511@Tiara: Enhance validation and error message [Redmine: #129306]
Param's Explanation:
	@UsernameList: List usernames of members will be updated,

*/		

BEGIN

	DECLARE @CustId		INT
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
	
END

GO
