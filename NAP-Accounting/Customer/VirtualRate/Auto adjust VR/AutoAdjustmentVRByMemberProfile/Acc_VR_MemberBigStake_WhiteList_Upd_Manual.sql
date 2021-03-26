/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_VR_MemberBigStake_WhiteList_Upd_Manual   
		@Usernames	VARCHAR(MAX)
	,	@UserID		INT
	,	@Type		TINYINT = 1
	,	@IP			VARCHAR(15)		= '' 
AS  
/*  
	Created:	20210323@Eden
	Task:		Update Status = 1 (white list) of customers in VRMemberBigStake table - By manual (UI function)
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20210323@Eden: Enhancement for VR Member Big Stake [Redmine:#149372]

		ErrorCode table Return:
			Validate Code
				1001: These accounts don't belong to big stake VR adjustment flow: 
				1002: The function can only process up to 500 accounts per request.

			Partial Update Code
				1003: Already whitelisted accounts:
				1004: No ticket accounts:
				1005: Accounts which had been removed from queue before:
				0: Successfully whitelisted accounts:

	Param's Explanation:  	

	EXEC Acc_VR_MemberBigStake_WhiteList_Upd_Manual 
			@Usernames			= 'member02,member03'	
		,	@UserID				= 8 --sa	
		,	@IP					= '0.0.0.0'	
	
*/  
BEGIN  
	DECLARE @ErrorTbl TABLE (Username VARCHAR(30),ErrorCode INT , ErrorMsg VARCHAR(200))
	DECLARE @CustTbl TABLE (CustID INT, Username VARCHAR(30), FirstBetDate DATE, WLStatus tinyint, IsFinished BIT default 0)

	INSERT INTO @CustTbl(Username)
	SELECT DISTINCT LTRIM(RTRIM(p.val))
	FROM dbo.f_StringSplit(@Usernames,',') p
	OPTION (MAXRECURSION 0)

	UPDATE t
	SET t.CustID = ci.Custid
		,t.WLStatus = v.Status
		,t.FirstBetDate = v.FirstBetDate
	FROm @CustTbl t
		INNER JOIN custinfo ci WITH(NOLOCK)
			ON ci.username = t.Username
		INNER JOIN VRMemberBigStake v WITH(NOLOCK)
			ON ci.CustID = v.CustID
			AND v.Type = @Type

	INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
	SELECT Username,1001,'These accounts don''t belong to big stake VR adjustment flow: '
	FROM @CustTbl
	WHERE CustID IS NULL

	IF (SELECT COUNT(1) FROM @CustTbl) > 500
		INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
		SELECT NULL,1002,'The function can only process up to 500 accounts per request.'

	IF EXISTS (SELECT 1 FROM @ErrorTbl)
	BEGIN
		GOTO EndStep;
	END

	INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
	SELECT Username,1003,'Already whitelisted accounts: '
	FROM @CustTbl
	WHERE WLStatus = 1

	INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
	SELECT Username,1004,'No ticket accounts: '
	FROM @CustTbl
	WHERE FirstBetDate IS NULL

	DELETE t
	FROM @CustTbl t
		INNER JOIN @ErrorTbl e ON t.Username = e.Username

	DECLARE @CustIDList VARCHAR(MAX) = ''
	SELECT @CustIDList = @CustIDList + ',' + CONVERT(varchar,c.custid) 
	FROM @CustTbl c
		
	SELECT @CustIDList = ISNULL(STUFF(@CustIDList,1,1,''),'')

	EXEC Acc_VR_MemberBigStake_WhiteList_Upd 
			 @CustIDList = @CustIDList
			,@Type = @type
			,@UpdateType = 2 --Manual
			,@UserID = @UserID

	INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
	SELECT Username
		,ErrorCode = CASE WHEN ci.CustID IS NOT NULL THEN 0 ELSE 1005 END
		,ErrorMsg = CASE WHEN ci.CustID IS NOT NULL THEN 'Successfully whitelisted accounts:' ELSE 'Accounts which had been removed from queue before:' END
	FROM @CustTbl v
		LEFT JOIN VRMemberBigStake ci WITH(NOLOCK)
			ON ci.custid = v.CustID

	EndStep:
	SELECT * FROM @ErrorTbl
END
GO
	