/*<info serverAlias="DBCUST-CUSTDB" executers="bodbadminNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[CS_PTMatrix_Sel]  
   @UserName VARCHAR(30) = '',
   @ErrCode INT = 0 OUTPUT,
   @ErrMsg VARCHAR(100) ='' OUTPUT
AS  
/*  
 Created: 20190813@Johnson
 Task : Get PT Matrix for cn88
 DB:  DBCUST/CustDB  
 Original:  

 Revision:
    - 20190813@Johnson: initial sp [redmine:#116691]
 Param's Explanation:  

 */  
BEGIN  
	SET NOCOUNT ON
	CREATE TABLE #PTResult (Sporttype INT, Bettype INT,roleid TINYINT, MinPT TINYINT, MaxPT TINYINT, SuperPT TINYINT, MasterPT TINYINT, AgentPT TINYINT)
	DECLARE @custid INT,
			@roleid TINYINT,
			@Srecommend INT,
			@mrecommend INT,
			@recommend INT,
			@site VARCHAR(10)
	
	SELECT @custid = custid,
		@roleid = roleid,
		@srecommend = srecommend,
		@mrecommend = mrecommend,
		@recommend = recommend,
		@site = site
	FROM dbo.customer WITH(NOLOCK)
	WHERE username = @username
		
	IF @@rowcount = 0 AND @site <> 'CN88'
	BEGIN  
		SELECT @ErrCode = 101, @ErrMsg ='Invalid account!'
		RETURN  
	END 
	
	SELECT custid, username, roleid
	FROM customer WITH(NOLOCK)
	WHERE custid IN (@srecommend,@mrecommend,@recommend,@custid)
		
	IF @roleid IN (4,3,2,1)
	BEGIN
		INSERT INTO #PTResult(sporttype,bettype,roleid,MinPT,MaxPT)
		SELECT sporttype, bettype, 4, MinPT, MaxPT
		FROM dbo.f_CS_GetPT_Agent(@srecommend)
	END
	
	IF @roleid IN (3,2,1)
	BEGIN
		INSERT INTO #PTResult(sporttype,bettype,roleid,SuperPT)
		SELECT sporttype, bettype, 3, SuperPT
		FROM dbo.f_CS_GetPT_Agent(@mrecommend)
	END
	
	IF @roleid IN (2,1)
	BEGIN
		INSERT INTO #PTResult(sporttype,bettype,roleid,MasterPT,AgentPT)
		SELECT sporttype, bettype, 2, MasterPT, AgentPT
		FROM dbo.f_CS_GetPT_Agent(@recommend)
	END
	
	SELECT * FROM #PTResult
	
END	
GO