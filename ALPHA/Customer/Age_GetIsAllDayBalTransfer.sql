/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp, bodbDownlineNetView,wsv_alpv" isFunction="0"></info>*/
ALTER PROCEDURE Age_GetIsAllDayBalTransfer
	@CustId	INT
AS
/*
	Creator:	20230308@Elodie
	Task:		Get IsAllDayBalTransfer - [Redmine: #184699]
	Database:	DBCUST/CustDB
	
	Revisions:
		- 20230308@Elodie: Get IsAllDayBalTransfer Info - [Redmine: #184699]
		

	Parameter's Explaination:
		
	Developer's Notes:
	Example: EXEC Age_GetIsAllDayBalTransfer @CustId = 1176070
*/
BEGIN
	SET NOCOUNT ON

	SELECT	ci.custid, ci.username, ci.roleid, ci.currency, ci.Enabled,
			ci.recommend, ci.mrecommend, ci.srecommend,  
		CASE 
			WHEN m.custid IS NOT NULL 
			THEN ISNULL(m.IsAllDayBalTransfer,0)
			ELSE ISNULL(s.IsAllDayBalTransfer,0)
		END AS IsAllDayBalTransfer			
	FROM dbo.custInfo ci
		INNER JOIN dbo.CustSuper s WITH (NOLOCK) ON ci.srecommend = s.custid
		LEFT JOIN dbo.CustMaster m WITH (NOLOCK) ON ci.mrecommend = m.custid
	WHERE ci.custid = @CustId	 
END
GO