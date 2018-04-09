USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_CustomerSelByUserNameEx]    Script Date: 06/03/2010 11:23:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_CustomerSelByUserNameEx] 
	@UserName nvarchar(50),
	@Currency int = 43 --default thai currency
AS

/*
	Task : Select Super Agent list
	DB: DB05.bodb02
	Revisions:
	- 20100521@Lewin: Add currency param #IRP411
*/

SET NOCOUNT ON
--Original: account\accounttop.asp

SELECT 	CustId, roleid
FROM	Custinfo with (NOLOCK)
WHERE	UserName = @UserName 
		AND Currency = @Currency
		AND dbo.f_IsDummySuper(srecommend) = 0

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelByUserNameEx] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelByUserNameEx] TO [vnteam]

