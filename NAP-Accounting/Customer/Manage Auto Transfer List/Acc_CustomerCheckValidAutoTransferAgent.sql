 ALTER PROCEDURE [dbo].[Acc_CustomerCheckValidAutoTransferAgent]
	@username	VARCHAR(MAX)= ''
 AS
	/*
		Created: Johnson
		Date: 2014-09-29
		Task: Check valid agents before insert into automate transfer list
		DB: DBTXN/CustDB
		
		Revisions:
		
		Parameter's Explanation:
	*/
BEGIN
	SET NOCOUNT ON
	DECLARE @tmpUser TABLE (custid INT,username VARCHAR(50))
	DECLARE @tmpResult TABLE (username VARCHAR(50), remark VARCHAR(100), isValid bit)
	
	INSERT INTO @tmpUser(username)
	SELECT val
	FROM strSplit (@username,',')
	
	UPDATE t
	SET t.custid = c.custid
	FROM @tmpUser t
		LEFT JOIN customer c WITH(NOLOCK) ON t.username = c.username AND roleid > 1
	
	INSERT INTO @tmpResult(username,remark,isValid)
	SELECT username, 'Duplicate Username.', 0
	FROM @tmpUser
	WHERE custid IS NOT NULL
	GROUP BY username
	HAVING COUNT(1) > 1
	
	INSERT INTO @tmpResult(username,remark,isValid)
	SELECT username, 'Invalid Username.', 0
	FROM @tmpUser
	WHERE custid IS NULL
	
	INSERT INTO @tmpResult(username,remark,isValid)
	SELECT t.username, 'Existing Username.', 0
	FROM Acc_ClearBalanceList ac WITH(NOLOCK)
		INNER JOIN @tmpUser t ON ac.custid = t.custid
	
	INSERT INTO @tmpResult(username,remark,isValid)
	SELECT t.username, 'Valid Username.', 1
	FROM @tmpUser t 
		LEFT JOIN @tmpResult rs ON t.username = rs.username
	WHERE rs.username IS NULL
	
	SELECT * FROM @tmpResult
	
END
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerCheckValidAutoTransferAgent] TO [bodbAdminNet]