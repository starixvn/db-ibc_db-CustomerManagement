/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustLastBetFilter_Check]
	-- Add the parameters for the stored procedure here
	 @AgentID	INT
	,@UserNames	NVARCHAR(MAX)
	,@RoleId	TINYINT
AS
/*
	Creator: 20230626@Tacy  
	Task : Check username/nickname
	DB: DBCUST/CustDB

	Revisions:  
		- 20230626@Tacy: Alpha - Bet List - Enhance Last bet function [Redmine:#186142]
		- 20241108@Virgil: Alpha - Offer Last Bets function for Super/Master [Redmine: #213315]
		- 20250508@Virgil: Alpha - Offer Last Bets: User can see information of member other line [Redmine: #226466]
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Err_Tbl TABLE(
		CustID		INT, 
		Username	NVARCHAR(MAX),
		Username2	VARCHAR(50) NULL,
		firstname	NVARCHAR(50) NULL,
		lastname	NVARCHAR(50) NULL,
		ErrCode		INT DEFAULT 0
	)
	
	DECLARE @tbUsername TABLE (
		CustID			INT, 
		username		VARCHAR(50),
		Username2		VARCHAR(50) NULL,
		firstname		NVARCHAR(50) NULL,
		lastname		NVARCHAR(50) NULL,
		roleID			TINYINT,
		inputUsername	VARCHAR(50)
	)

	-- Username is overlength
	INSERT INTO @Err_Tbl (CustID, Username, ErrCode)
	SELECT NULL, TRIM(value), 100
	FROM STRING_SPLIT(@UserNames, ',') 
	WHERE TRIM(value)<>'' AND LEN(TRIM(value))>50

	-- Username
	INSERT INTO @tbUsername (CustID, Username, Username2, firstname, lastname, roleID, inputUsername)
	SELECT ci.custid, TRIM(t.value), c.username2, c.firstname, c.lastname, ci.roleid, TRIM(t.value)
	FROM STRING_SPLIT(@UserNames, ',') t
	LEFT JOIN custInfo ci WITH (NOLOCK) ON ci.username=TRIM(t.value)
	LEFT JOIN Customer c WITH (NOLOCK) ON c.custid=ci.custid
	WHERE TRIM(t.value)<>'' AND LEN(TRIM(value))<=50
	
	-- Nickname
	UPDATE t
	SET t.CustID=c.custid, 
		t.username=c.username,
		t.Username2=c.username2,
		t.firstname=c.firstname,
		t.lastname=c.lastname,
		t.roleID=c.roleid
	FROM @tbUsername t
	INNER JOIN Customer c WITH (NOLOCK) ON c.username2=t.username

	-- Not exist Username/nickname
	INSERT INTO @Err_Tbl (CustID, Username, Username2, firstname, lastname, ErrCode)
	SELECT DISTINCT CustID, Username, Username2, firstname, lastname, 100	
	FROM @tbUsername 
	WHERE CustID IS NULL

	-- Is SMA same line
	INSERT INTO @Err_Tbl (CustID, Username, Username2, firstname, lastname, ErrCode)
	SELECT DISTINCT t.CustID, t.Username, t.Username2, t.firstname, t.lastname, 101 --, c.recommend, c.mrecommend, c.srecommend
	FROM @tbUsername  t
	INNER JOIN Customer c WITH (NOLOCK) ON c.custid=t.CustID
	WHERE t.CustID IS NOT NULL AND t.roleID <> 1
		AND ((c.recommend = @AgentID AND @RoleId = 2) 
		OR (c.mrecommend = @AgentID AND @RoleId = 3) 
		OR (c.srecommend = @AgentID AND @RoleId = 4))

	-- Not same line (return input Usernames)
	IF EXISTS (SELECT 1
				FROM @tbUsername t
				INNER JOIN Customer c WITH (NOLOCK) ON c.custid=t.CustID
				WHERE ((c.recommend <> @AgentID AND @RoleId = 2) 
					OR (c.mrecommend <> @AgentID AND @RoleId = 3) 
					OR (c.srecommend <> @AgentID AND @RoleId = 4))
					AND NOT EXISTS (SELECT 1 FROM @Err_Tbl e WHERE e.CustID=t.CustID))
	BEGIN
		INSERT INTO @Err_Tbl (CustID, Username, Username2, firstname, lastname, ErrCode)
		SELECT DISTINCT t.CustID, t.inputUsername, NULL, NULL, NULL, 102
		FROM @tbUsername t 
		INNER JOIN Customer c WITH (NOLOCK) ON c.custid=t.CustID
		WHERE ((c.recommend <> @AgentID AND @RoleId = 2) 
			OR (c.mrecommend <> @AgentID AND @RoleId = 3) 
			OR (c.srecommend <> @AgentID AND @RoleId = 4))
			AND NOT EXISTS (SELECT 1 FROM @Err_Tbl e WHERE e.CustID=t.CustID)
	END

	-- Valid usernames
	INSERT INTO @Err_Tbl (CustID, Username, Username2, firstname, lastname)
	SELECT DISTINCT t.CustID, t.Username, t.Username2, t.firstname, t.lastname		
	FROM @tbUsername t
	LEFT JOIN @Err_Tbl e ON e.CustID=t.CustID
	WHERE T.CustID IS NOT NULL AND e.CustID IS NULL

	-- Remove CustID case Not SMA's downline 
	UPDATE @Err_Tbl
	SET CustID = NULL
	WHERE ErrCode = 102

	SELECT CustID, username, username2, firstname, lastname, ErrCode
	FROM @Err_Tbl
	ORDER BY ErrCode, Username
END
GO