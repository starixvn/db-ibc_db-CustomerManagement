/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="" isFunction="1"></info>*/
ALTER FUNCTION [dbo].[f_CS_AGE_IsCrossLevelUpdate](@custid INT, @userid INT) 
RETURNS TABLE 
AS
/*
	Created By: Johnson
	Created Date: 20190403
	Task: fix cross level update for 8 functions - [Redmine: #105660]
	DB: DBCUST/CUSTDB
	Original: f_AGE_IsCrossLevelUpdate
	
	Revisions:
		- 20190403@Johnson: intitial sp [redmine: #105660]
		
*/
RETURN
	SELECT custid
	FROM dbo.custInfo ci WITH(NOLOCK)
	WHERE custid = @custid 
		AND ( 	@custid = @userid
				OR EXISTS (SELECT 1 FROM custInfo ci_tmp WITH (NOLOCK) WHERE ci_tmp.custid = @userid AND ci_tmp.roleid > 4)
				OR (ci.recommend = @userid)
				OR (ci.mrecommend = @userid)
				OR (ci.srecommend = @userid)
			)


GO