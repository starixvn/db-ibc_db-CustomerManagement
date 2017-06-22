ALTER FUNCTION [dbo].[f_AGE_IsCrossLevelUpdate](@custid INT,@roleID TINYINT, @userid INT) 
RETURNS TABLE 
AS
/*
	Created By: Helen
	Created Date: 20160614
	Task: fix cross level update for 8 functions - [Redmine: 55377]
	DB: DBCUST/CUSTDB
*/
RETURN
	SELECT custid
	FROM dbo.custInfo ci WITH(NOLOCK)
	WHERE custid = @custid 
		AND ( 	@custid = @userid
				OR EXISTS (SELECT 1 FROM custInfo ci_tmp WITH (NOLOCK) WHERE ci_tmp.custid = @userid AND ci_tmp.roleid > 4)
				OR (@roleID = 1 AND ci.recommend = @userid)
				OR (@roleID = 2 AND ci.mrecommend = @userid)
				OR (@roleID = 3 AND ci.srecommend = @userid)
			)


GO
GRANT SELECT ON [f_AGE_IsCrossLevelUpdate] TO [bodbDownlineNet] 
GO
GRANT SELECT ON [f_AGE_IsCrossLevelUpdate] TO [bodbDownlineNetView]
GO

