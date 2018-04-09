

/****** Object:  StoredProcedure [dbo].[Acc_CustomerSelSAgListEx]    Script Date: 05/29/2010 10:04:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_CustomerSelSAgListEx] 
	@Currency INT  
AS  

/*
	Created by: [Creator]
	Date: 
	Task: Bet Super List when creating master (can choose which super for master)
	DB: DB05.bodb02 
	Original:  
	Revisions:
		-20090109@Henry: No need to get currency Name from Exchange since it is not used
		-20100521@Lewin: Add currency param.
*/

SET NOCOUNT ON  
--Admin 1 .Net  
SELECT c.custid, c.username, c.currency as exchangeid
FROM customer AS c WITH (NOLOCK) 
WHERE c.roleid = 4 
	AND c.custid>100  
	AND c.currency = @Currency
	AND dbo.f_IsDummySuper(c.custid) = 0
ORDER BY c.username   


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelSAgListEx] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelSAgListEx] TO [vnteam]

