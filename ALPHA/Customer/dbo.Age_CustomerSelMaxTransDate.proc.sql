ALTER PROCEDURE Age_CustomerSelMaxTransDate
	@custid INT
AS
--Original:???
--AGENT SITE
--UPDATED 02/22/2006: remove refno
SET NOCOUNT ON
--Remove custaccount

SELECT 
	MAX(transdate) tdate 
FROM bettrans WITH (NOLOCK)
WHERE 
	custid=@custid



GO

GRANT EXECUTE ON [dbo].Age_CustomerSelMaxTransDate TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].Age_CustomerSelMaxTransDate TO [bodbDownlineNetView]
