/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[EAS_AccountType_Check]
	 @GroupName	VARCHAR(50)
	,@UserNames NVARCHAR(max)	
AS
/*
	Creator: 20230525@Tacy  
	Task : Validate usernames before mark account.
	DB: DBCUST/CustDB

	Revisions:  
		- 20230525@Tacy: Ext NAP - Function for Headline to provide customer class based on their knowledge [Redmine:#188025]
	
	Param's Explanation:

	Example:	
*/		
BEGIN
    SET NOCOUNT ON

	DECLARE @Err_Tbl TABLE(
		CustID INT, 
		Username NVARCHAR(100),
		ErrCode INT DEFAULT 0,
		ErrMsg VARCHAR(500) DEFAULT ''
	)
	
	--exist: username is overlength
	INSERT INTO @Err_Tbl (CustID, Username, ErrCode, ErrMsg)
	SELECT NULL, TRIM(value), 100, 'Invalid usernames'
	FROM STRING_SPLIT(@UserNames, ',') 
	WHERE TRIM(value)<>'' AND LEN(TRIM(value))>30

	CREATE TABLE #tmpUsers (CustID INT, Username NVARCHAR(50))

	INSERT INTO #tmpUsers (CustID, Username)
	SELECT c.custid, TRIM(t.value)
	FROM STRING_SPLIT(@UserNames, ',') t
	LEFT JOIN custInfo c WITH (NOLOCK) ON c.username=TRIM(t.value)
	WHERE TRIM(t.value)<>'' AND LEN(TRIM(value))<=30

	-- Invalid accounts
	INSERT INTO @Err_Tbl (CustID, Username, ErrCode, ErrMsg)
	SELECT CustID, Username, 100, 'Invalid usernames'		-- not exist accounts
	FROM #tmpUsers 
	WHERE CustID IS NULL
	UNION
	SELECT t.CustID, t.Username, 100, 'Invalid usernames'	-- accounts do not belong to current Group
	FROM #tmpUsers t 
	INNER JOIN Customer c WITH (NOLOCK) ON c.custid=t.CustID
	LEFT JOIN Acc_CustGroup ag WITH (NOLOCK) ON ag.CustID=c.srecommend
											AND ag.GroupName=@GroupName
	WHERE ag.CustID IS NULL

	-- Already marked account
	INSERT INTO @Err_Tbl (CustID, Username, ErrCode, ErrMsg)
	SELECT t.CustID, t.Username, 101, 'The following usernames already marked'
	FROM #tmpUsers t
	INNER JOIN Acc_CustType ct WITH (NOLOCK) ON ct.custid=t.CustID
	WHERE NOT EXISTS (SELECT 1 FROM @Err_Tbl e WHERE e.CustID=t.CustID)

	-- Disabled Accounts
	INSERT INTO @Err_Tbl (CustID, Username, ErrCode, ErrMsg)
	SELECT t.CustID, t.Username, 102, 'The following usernames are disabled'
	FROM #tmpUsers t
	INNER JOIN custInfo ci WITH (NOLOCK) ON ci.custid=t.CustID
	WHERE ci.Enabled=0
	AND NOT EXISTS (SELECT 1 FROM @Err_Tbl e WHERE e.CustID=t.CustID)

	-- Valid usernames
	INSERT INTO @Err_Tbl (CustID, Username, ErrCode, ErrMsg)
	SELECT t.CustID, t.Username, 0, '' 
	FROM #tmpUsers t
	LEFT JOIN @Err_Tbl e ON e.CustID=t.CustID
	WHERE T.CustID IS NOT NULL AND e.CustID IS NULL

	-- get all
	SELECT CustID, Username, ErrCode, ErrMsg 
	FROM @Err_Tbl
END
GO