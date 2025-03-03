/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
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
		- 20210914@Eden: Amendment on Virtual Rate by Big stake request [#156824]
		- 20220105@Eden: Enhance to write more logs for Virtual Rate jobs [Redmine:#166626]
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
		- 20250121@Winfred: [NAP CM] Scale Out DBCUST - Apply Inhouse replication for Customer Class[Redmine: #214119]
		- 20250303@Winfred: NAP CM - Customer - Whitelist Big Credit Members - Username Input Validation [Redmine: #218901] 

		ErrorCode table Return:
			Validate Code
				1001: These accounts don't belong to big stake VR adjustment flow: 
				1002: The function can only process up to 500 accounts per request.

			Partial Update Code
				1003: Already whitelisted accounts:
				--1004: No ticket accounts:
				--1005: Accounts which had been removed from queue before:
				1006: Invalid input. Please use a comma to separate usernames:
				0: Successfully whitelisted accounts:

	Param's Explanation:  	

	EXEC Acc_VR_MemberBigStake_WhiteList_Upd_Manual 
			@Usernames			= 'member02,member03'	
		,	@UserID				= 8 --sa	
		,	@IP					= '0.0.0.0'	
	
*/  
BEGIN  
	DECLARE @ErrorTbl TABLE (Username VARCHAR(500),ErrorCode INT , ErrorMsg VARCHAR(200))
	DECLARE @CustTbl TABLE (CustID INT, Username VARCHAR(500), FirstBetDate DATE, WLStatus tinyint, IsFinished BIT default 0)

	INSERT INTO @CustTbl(Username)
	SELECT DISTINCT LTRIM(RTRIM(p.value))
	FROM STRING_SPLIT(@Usernames,',') p
	WHERE value <> ''

	INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
	SELECT Username,1006,'Invalid input. Please use a comma to separate usernames.'
	FROM @CustTbl
	WHERE LEN(Username) > 30
		
	IF (SELECT COUNT(1) FROM @CustTbl) > 500
		INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
		SELECT NULL,1002,'The function can only process up to 500 accounts per request.'
	
	IF EXISTS (SELECT 1 FROM @ErrorTbl)
	BEGIN
		GOTO EndStep;
	END

	UPDATE t
	SET t.CustID = c.Custid
		,t.WLStatus = v.Status
		,t.FirstBetDate = v.FirstBetDate
	FROM @CustTbl t
		INNER JOIN customer c WITH(NOLOCK)
			ON c.username = t.Username
		INNER JOIN dbo.f_GetVRBigStakeConfig(NULL) p 
			ON p.site = c.site
		LEFT JOIN VRMemberBigStake v WITH(NOLOCK)
			ON c.CustID = v.CustID
			AND v.Type = p.Type
	WHERE c.roleid = 1
		AND c.creatdate > = p.ReleasedDate
		AND p.type = @type

	INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
	SELECT Username,1001,'These accounts don''t belong to big stake VR adjustment flow: '
	FROM @CustTbl
	WHERE CustID IS NULL

	IF EXISTS (SELECT 1 FROM @ErrorTbl)
	BEGIN
		GOTO EndStep;
	END

	INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
	SELECT Username,1003,'Already whitelisted accounts: '
	FROM @CustTbl
	WHERE WLStatus = 1

	--INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
	--SELECT Username,1004,'No ticket accounts: '
	--FROM @CustTbl
	--WHERE FirstBetDate IS NULL
	--	AND WLStatus IS NOT NULL --on queue but no ticket

	DELETE t
	FROM @CustTbl t
		INNER JOIN @ErrorTbl e ON t.Username = e.Username

	DECLARE @CustIDList VARCHAR(MAX) = ''

	SELECT @CustIDlist = CONVERT(VARCHAR(MAX),
				(
					SELECT CustID AS '@CustID'
					FROM @CustTbl
					FOR XML PATH('Row'), ROOT ('Root'), TYPE)
				)

	EXEC Acc_VR_MemberBigStake_WhiteList_Upd 
			 @CustIDList = @CustIDList
			,@Type = @type
			,@UpdateType = 2 --Manual
			,@UserID = @UserID

	INSERT INTO @ErrorTbl (Username,ErrorCode,ErrorMsg)
	SELECT Username
		,ErrorCode = 0
		,ErrorMsg = 'Successfully whitelisted accounts:'
	FROM @CustTbl v

	EndStep:
	SELECT * FROM @ErrorTbl
END
GO
	