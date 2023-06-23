/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
/*
	Created: Helios  
	Task : API Support Check UserName - Password - APISecretKey For Headline
	DB: DBCUST/CustDB  
	Revisions:  
		- 20230511@Helios: EXT - Support API for Headline [Redmine: #188035] 
	Parameter's Explanation:  
		@ErrCode = 0 : Pass || @ErrCode IN (101,102,103) : ERROR
		@IsAuthenticated:
			Pass : @IsAuthenticated = 1
			Err    : @IsAuthenticated = 0
*/
CREATE PROCEDURE [dbo].[EAS_API_CheckSecretKeyUser]
	@UserName			VARCHAR(50)		
  , @UserPassword		NVARCHAR(100)		
  , @APISecretKey		VARCHAR(100)		
  , @CustID				INT			  = 0	OUTPUT
  , @RoleID				TINYINT		  = 0	OUTPUT
  , @ErrCode			INT			  = 0	OUTPUT
  , @ErrMsg				NVARCHAR(200) = ''  OUTPUT
  , @IsAuthenticated	BIT			  = 1	OUTPUT
AS

BEGIN
	SET NOCOUNT ON

	SET @IsAuthenticated = 1

	DECLARE 
		@GroupID		INT = 0
	,	@GroupName		VARCHAR(50) = ''
	 
	CREATE TABLE #GroupName (GroupName VARCHAR(50))

	-- Check SecrectKey
	SELECT @GroupName = GroupName FROM [dbo].[f_API_CheckSecretKey] (@APISecretKey)
	IF @GroupName IS NULL -- SecrectKey not found  
	BEGIN
		SELECT  @ErrMsg =  'Wrong SecretKey',  
		@ErrCode = 101	,
		@IsAuthenticated = 0
			RETURN;
	END

	SELECT @GroupID = GroupID 
	FROM NAP_UserControl.dbo.eaGroup ea WITH (NOLOCK)  
	WHERE GroupName = @GroupName

	INSERT INTO #GroupName (GroupName)
	SELECT @GroupName
	UNION
	SELECT GroupName FROM NAP_UserControl.dbo.eaGroup ea WITH (NOLOCK) WHERE ParentID = @GroupID

	-- Check CustSub and Permission Report

	SET @CustID = (SELECT CustID FROM CustSub WITH (NOLOCK) WHERE (username = @UserName OR UserName2 = @UserName) AND userpwd = @UserPassword AND PageAccess LIKE '%[E]%')

	CREATE TABLE #Temp (SreCommend INT , CustID INT )

	-- Check user and password
	INSERT INTO #Temp (SreCommend , CustID)
	SELECT ISNULL(c.srecommend,0) , CustID
	FROM dbo.customer c WITH (NOLOCK)  
	WHERE (CustID = @CustID OR ((username = @UserName OR username2 = @UserName) AND c.userpwd = @UserPassword))
	AND c.roleid IN (2,3,4)	-- Just Check SMA	
	IF @@ROWCOUNT = 0 -- user not found  
	BEGIN
	  SELECT  @ErrMsg =  'Wrong username or password.',  
		@ErrCode = 103		,
		@IsAuthenticated = 0
			RETURN;
	END

	-- Check CustGroup
	SELECT @CustID = t.CustID 
	FROM Acc_CustGroup ac WITH (NOLOCK)  
	INNER JOIN #Temp t ON ac.CustID = t.SreCommend
	WHERE ac.GroupName IN (SELECT GroupName From #GroupName)
	IF @@ROWCOUNT = 0 -- CustGroup not found  
	BEGIN
	  SELECT  @ErrMsg =  'Wrong CustGroup',  
		@ErrCode = 102 ,
		@IsAuthenticated = 0
			RETURN;
	END



END
