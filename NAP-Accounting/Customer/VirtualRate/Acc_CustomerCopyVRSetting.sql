/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_CustomerCopyVRSetting   
					@Source_Username		VARCHAR(30)
				,	@Dest_Usernames			VARCHAR(MAX)
				,	@UserID					INT
				,	@IP						VARCHAR(15)		= ''
				--,	@ErrCode				INT				= 0		OUTPUT
				--,	@ErrMsg					NVARCHAR(4000)	= ''	OUTPUT  
AS  
/*  
	Created:	20210308@Eden
	Task:		New function allow user to copy virtual rate setting from an account to others
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20210308@Eden: Copy and apply VR settings to multiple member accounts [Redmine:#149372]

	Param's Explanation:  	

	EXEC Acc_CustomerCopyVRSetting 
		    @Source_Username	= 'member01'	
		,	@Dest_Usernames		= 'member02,member03'	
		,	@UserID				= 8 --sa	
		,	@IP					= '0.0.0.0'	
	
*/  
BEGIN  
	DECLARE @ErrorTbl TABLE (Username VARCHAR(30),ErrorCode INT , ErrorMsg VARCHAR(200))
	DECLARE @CustTbl TABLE (CustID INT, Username VARCHAR(30), RoleID TINYINT, IsFinished BIT default 0)
	DECLARE @Source_CustID INT
	DECLARE	@ErrCode INT = 0
	DECLARE	@ErrMsg	NVARCHAR(4000)	= ''

	SELECT @Source_CustID = custid 
	FROM custInfo c WITH(NOLOCK) 
	WHERE username = @Source_Username

	IF @Source_CustID IS NULL
	BEGIN
		INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
		SELECT NULL,1,'Invalid source account.'

		--SET @ErrCode = 999
		GOTO EndStep;
	END

	INSERT INTO @CustTbl(Username)
	SELECT DISTINCT LTRIM(RTRIM(p.val))
	FROM dbo.f_StringSplit(@Dest_Usernames,',') p
	OPTION (MAXRECURSION 0)

	IF EXISTS (SELECT 1 FROM @CustTbl WHERE Username = @Source_Username) 
	BEGIN
		INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
		SELECT NULL,1004,'Source account is find among copied accounts. You cannot copy an account''s VR to itself.'

		GOTO EndStep;
	END

	UPDATE t
	SET t.CustID = ci.Custid,
		t.RoleID = ci.roleid
	FROm @CustTbl t
		INNER JOIN custinfo ci WITH(NOLOCK)
			ON ci.username = t.Username

	INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
	SELECT Username,1001,'Invalid destination accounts: '
	FROM @CustTbl
	WHERE CustID IS NULL

	INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
	SELECT Username,1002,'The following accounts are not members: '
	FROM @CustTbl
	WHERE RoleID <> 1

	IF (SELECT COUNT(1) FROM @CustTbl) > 500
		INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
		SELECT NULL,1003,'The function can only copy up to 500 accounts per request.'

	IF EXISTS (SELECT 1 FROM @ErrorTbl)
	BEGIN
		--SET @ErrCode = 999
		GOTO EndStep;
	END

	DECLARE @Source_EnableVirtualrate BIT = 0
	DECLARE @Source_VRLockedStatus_Soccer BIT 
	DECLARE @Source_VRLockedStatus_OS BIT
	DECLARE @Source_Virtualmultiplier VARCHAR(MAX)

	SELECT @Source_EnableVirtualrate = VirtualMultiplier FROM custInfo c WITH(NOLOCK) WHERE custid = @Source_CustID

	IF EXISTS ( SELECT 1 FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = @Source_CustID AND Type = 1)
		SET @Source_VRLockedStatus_Soccer = 1
	ELSE 
		SET @Source_VRLockedStatus_Soccer = 0

	IF EXISTS ( SELECT 1 FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = @Source_CustID AND Type = 2)
		SET @Source_VRLockedStatus_OS = 1
	ELSE 
		SET @Source_VRLockedStatus_OS = 0

	SELECT @Source_Virtualmultiplier = CONVERT (VARCHAR(MAX),
		(	
			SELECT pvs.SportType, 
					pvs.BetType, 
					pvs.IsLive, 
					dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID) AS VirtualMultiplier
			FROM CustVirtualSetting AS cvs WITH(NOLOCK)
					INNER JOIN ProfileVirtualSetting AS pvs WITH(NOLOCK)
					ON cvs.seqNo = pvs.seqNo
			WHERE cvs.custid = @Source_CustID 
				AND pvs.sporttype NOT IN (2, 43)
			FOR XML RAW('Rate'), ROOT ('ROOT')
		)
	)

	DECLARE @CustID INT, @Username VARCHAR(30)

	--Scan all Customers
	WHILE 1=1
	BEGIN
		SELECT @ErrCode = 0, @ErrMsg = ''

		UPDATE TOP(1)t
		SET IsFinished = 1,
			@CustID = t.CustID,
			@Username = t.Username
		FROM @CustTbl t
		WHERE IsFinished = 0

		IF @@ROWCOUNT = 0
			BREAK;

		--enable VR status and copy VR , VR lock status
		EXEC Acc_CustomerUpdVirtualMultiplier
			 @custid = @CustID, 
			 @EnableVirtualrate = @Source_EnableVirtualrate, 
			 @virtualmultiplier = @Source_Virtualmultiplier, 
			 @UserID = @UserID, 
			 @IP = @IP, 
			 @ErrCode = @ErrCode OUTPUT, 
			 @ErrMsg = @ErrMsg OUTPUT, 
			 @VRLockedStatus_Soccer = @Source_VRLockedStatus_Soccer, 
			 @VRLockedStatus_OS = @Source_VRLockedStatus_OS,
			 @CopyFrom = @Source_CustID

		IF @ErrCode <> 0
		BEGIN
			INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
			SELECT @Username,@ErrCode,@ErrMsg + ' :'
		END
		ELSE
		BEGIN
			INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
			SELECT @Username,0,''
		END
	END

	EndStep:
	SELECT * FROM @ErrorTbl
END


GO
	