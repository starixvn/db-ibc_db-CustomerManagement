USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_CustomerSelCasinoStatus]
	@CustID int,
	@IsSync	bit = 0 output,
	@IsDisable bit = 1 output
AS
/*
Created: 20081029@phuong.doan
Task : Get Casino Status of an Account
DB: DB02.bodb02
Original:


Param's Explanation:
*/
SET NOCOUNT ON
select @IsSync = SyncCasino, @IsDisable = DisableCasino 
from custinfo (nolock)
where custid=@Custid

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCasinoStatus] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCasinoStatus] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelCasinoStatus] TO [vnteam]