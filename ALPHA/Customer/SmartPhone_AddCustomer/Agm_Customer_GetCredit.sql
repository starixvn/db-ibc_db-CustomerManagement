ALTER PROCEDURE dbo.Agm_Customer_GetCredit
	@custid int
AS
BEGIN
/*  
 Created by: Elly  
 Date:20110817
 Original:
 Task: Get max remaining credit of an agent
 
 DB: DB052.BODB02
  
 History:  
  
 Explanation's Param:  
  
*/
	SET NOCOUNT ON
	DECLARE @roleid int
	
	SELECT @roleid=roleid
	FROM dbo.customer WITH(NOLOCK)
	WHERE custid=@custid
	
	IF @roleid=2 --agent
	BEGIN
		
			SELECT CASE WHEN ca.maxcredit >=(ISNULL(c1.Credit,0)-ISNULL(c2.SubCredit,0)) 
							OR ISNULL(ca.maxcredit,0)=0
							THEN ISNULL(c1.Credit,0)-ISNULL(c2.SubCredit,0)
						WHEN ca.maxcredit <(ISNULL(c1.Credit,0)-ISNULL(c2.SubCredit,0)) THEN ca.maxcredit
						END AS MaxCredit
			FROM dbo.custinfo AS c1 WITH(NOLOCK)
				,(SELECT SUM(c2.Credit) AS SubCredit
					FROM dbo.custinfo AS c2 WITH(NOLOCK)
					WHERE c2.Recommend=@custid
						AND c2.roleid=1
				) AS c2
				,dbo.CustAgent AS ca WITH(NOLOCK)
			WHERE c1.custid=@custid
				AND ca.custid=@custid			
	END
	
	SET NOCOUNT OFF  
END
/*
EXEC dbo.Agm_Customer_GetCredit 1262
EXEC dbo.Agm_Customer_GetCredit 1272
select * from dbo.CustAgent AS ca WITH(NOLOCK) where ca.custid=1262
*/
GO
GRANT EXECUTE ON [dbo].Agm_Customer_GetCredit TO [wsv_alp]
GO
GRANT VIEW DEFINITION ON [dbo].Agm_Customer_GetCredit TO [vnteam]