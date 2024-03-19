/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,wsv_alp" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Personal_Multiple_Ins
	 @Usernames VARCHAR(MAX)
	,@AgentID INT
	,@Sporttype SMALLINT = 0
	,@WinningThreshold MONEY = NULL
	,@LosingThreshold MONEY = NULL
	,@UserId INT = 0
	,@SubAccID INT = 0
	,@IP VARCHAR(20) = ''
AS  
/*  
	Created:	20220523@Eden
	Task:		Insert Personal threshold (multiple Member)
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]

	Param's Explanation:  	

	EXEC Acc_WLMonitored_Personal_Multiple_Ins 
		 @Usernames = 'member01,member13,memberEden'
		,@AgentID = 1176086
		,@Sporttype = 0
		,@WinningThreshold = 1000
		,@LosingThreshold = 5000
		,@UserId = 8
		,@SubAccID = 0
		,@IP = '0.0.0.0'
*/  
BEGIN 
	DECLARE @ErrCode INT = 0, @ErrMsg VARCHAR(500) = ''
	DECLARE @CustID INT
	DECLARE @Err_Tbl TABLE(
		CustID INT, 
		Username VARCHAR(30),
		ErrCode INT DEFAULT 0,
		ErrMsg VARCHAR(500) DEFAULT '',
		Isfinished BIT DEFAULT 0
	)

	INSERT INTO @Err_Tbl(Username)
	SELECT DISTINCT LTRIM(value)
	FROM string_split(@Usernames, ',')
	WHERE LTRIM(value) != ''

	UPDATE t
	SET t.CustID = ci.custid
	FROM @Err_Tbl t
		INNER JOIN custInfo ci WITH(NOLOCK) 
			ON t.Username = ci.Username 
			AND ci.recommend = @AgentID
			AND ci.roleid = 1

	UPDATE t
	SET t.ErrCode = 101,
		t.ErrMsg = 'are not member',
		t.Isfinished = 1
	FROM @Err_Tbl t
	WHERE custid IS NULL
	
	WHILE 1 = 1
	BEGIN
		SELECT TOP (1) @CustID= CustID
		FROM @Err_Tbl
		WHERE Isfinished = 0 
			AND CustID IS NOT NULL

		IF @@ROWCOUNT = 0 
			BREAK

		EXEC Acc_WLMonitored_Personal_Ins 
			 @CustID = @CustID
			,@Sporttype = @Sporttype
			,@WinningThreshold = @WinningThreshold
			,@LosingThreshold = @LosingThreshold
			,@ErrCode = @ErrCode OUT
			,@ErrMsg = @ErrMsg OUT
			,@UserId = @UserId
			,@SubAccID = @SubAccID
			,@IP = @IP

		UPDATE t
		SET t.ErrCode = ISNULL(@ErrCode,0),
			t.ErrMsg = ISNULL(@ErrMsg,''),
			t.Isfinished = 1
		FROM @Err_Tbl t
		WHERE custid = @CustID 
	END

	SELECT * 
	FROM @Err_Tbl
END
GO