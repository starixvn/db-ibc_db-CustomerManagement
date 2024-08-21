/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_xnap" viewers="" isFunction="0"></info>*/

CREATE PROCEDURE [dbo].[EAS_API_CheckSecretKeyUser]
	@UserName			VARCHAR(50)		
  , @UserPassword		NVARCHAR(100)		
  , @GroupNames			VARCHAR(MAX)
  , @ErrCode			INT			  = 0	OUTPUT
  , @ErrMsg				NVARCHAR(200) = ''  OUTPUT
AS
/*
	Created: Helios  
	Task : API Support Check UserName - Password - APISecretKey For Headline
	DB: DBCUST/CustDB  

	Revisions:  
		- 20230511@Helios: EXT - Support API for Headline [Redmine: #188035]
		- 20230816@Tacy: EXT - Adjust API to support Live Casino for Headline [Redmine: #192805]
		- 20240701@Tacy: EXT - API - Return Site & Currency [Redmine: #206055]
		- 20240812@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]

	Parameter's Explanation:  
		@ErrCode = 0 : Pass || @ErrCode IN (101,102,103) : ERROR
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @IsActive		BIT = 1
		, @CustID			INT = 0	
		, @SubAccID			INT	= 0	

	CREATE TABLE #GroupName (GroupName VARCHAR(50))

	INSERT INTO #GroupName (GroupName)
	SELECT value
	FROM STRING_SPLIT(@GroupNames,',')
	WHERE TRIM(value)<>''
		
	DECLARE @Srecommend	INT

	SET @Srecommend = 0

	-- Check user and password of Main Cust
	SELECT @Srecommend = ISNULL(c.srecommend,0)
		, @CustID = C.custid
	FROM dbo.customer c WITH (NOLOCK)    
	WHERE (username = @UserName OR username2 = @UserName) 
	AND c.userpwd = @UserPassword
	AND c.roleid IN (2,3,4) -- Just Check SMA   

	IF @Srecommend = 0
	BEGIN
		-- Check CustSub and Permission Report
		SELECT @CustID=CustID , @SubAccID=subaccid
		FROM CustSub WITH (NOLOCK) 
		WHERE (username = @UserName OR UserName2 = @UserName) 
			AND userpwd = @UserPassword 
			AND PageAccess LIKE '%[E]%'

		-- Check user and password of Sub Cust
		SELECT @Srecommend = ISNULL(c.srecommend,0)
		FROM dbo.customer c WITH (NOLOCK)  
		WHERE CustID = @CustID
		AND c.roleid IN (2,3,4)	-- Just Check SMA	

		IF @Srecommend = 0 -- user not found  
		BEGIN 
			SELECT  @ErrMsg =  'Wrong username or password.',    
					@ErrCode = 103
			RETURN;  
		END
	END

	--Check status:
	IF @SubAccID > 0
	BEGIN
		SELECT @IsActive=0 
		FROM custSub WITH (NOLOCK)
		WHERE custid=@CustID AND subaccid=@SubAccID
			AND closed=1
	END
	ELSE
	BEGIN
		SELECT @IsActive=0
		FROM custInfo ci WITH (NOLOCK)
		INNER JOIN CustProductStatus cs WITH (NOLOCK) ON cs.CustID=ci.custid
		WHERE ci.custid=@CustID 
		AND (ci.Enabled=0 OR cs.CloseInfo>0)
	END

	IF @IsActive=0
	BEGIN
		SELECT  @ErrMsg =  'This account was closed.',    
				@ErrCode = 104
		RETURN;
	END

	-- Check CustGroup
	IF NOT EXISTS (SELECT 1
					FROM Acc_CustGroup ac WITH (NOLOCK)  
					WHERE ac.CustID = @Srecommend
					AND ac.GroupName IN (SELECT GroupName From #GroupName))-- CustGroup not found  
	BEGIN
		SELECT  @ErrMsg =  'Wrong CustGroup',  
				@ErrCode = 102
		RETURN;
	END

	SELECT custid, username, site, currency
		, @SubAccID AS SubAccID
	FROM Customer WITH (NOLOCK)
	WHERE custid=@CustID
END
GO