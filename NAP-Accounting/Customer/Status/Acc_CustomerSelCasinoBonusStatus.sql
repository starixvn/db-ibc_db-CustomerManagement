USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_CustomerSelCasinoBonusStatus]    Script Date: 6/9/2015 9:57:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_CustomerSelCasinoBonusStatus]
	@custid INT
	
/*
	Created: Elodie
	Date: 2013-07-30
	DB: DBCUST.CustDB
	Task: get DisableCasinoBonus status
	
	Revisions:
		- 20150609@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
*/
AS
SET NOCOUNT ON


DECLARE @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT,@downlines BIT,
	@DisableDownlinesCasinoBonus BIT, @DisableUplinesCasinoBonus BIT

SELECT @roleid = roleid , @srecommend = srecommend , @mrecommend = mrecommend , @recommend = recommend 
FROM custinfo WITH(NOLOCK) 
WHERE custid = @custid 

SELECT @downlines = CASE @roleid WHEN 4 THEN  CASE WHEN EXISTS(SELECT top 1 1 FROM custinfo WITH(NOLOCK) WHERE srecommend = @custid and roleid = 3) THEN 1 ELSE 0 END
								 WHEN 3 THEN  CASE WHEN EXISTS(SELECT top 1 1 FROM custinfo WITH(NOLOCK) WHERE mrecommend = @custid and roleid = 2) THEN 1 ELSE 0 END
								 WHEN 2 THEN  CASE WHEN EXISTS(SELECT top 1 1 FROM custinfo WITH(NOLOCK) WHERE recommend = @custid  and roleid = 1) THEN 1 ELSE 0 END
								 ELSE 0 END

SELECT @DisableDownlinesCasinoBonus = CASE @roleid WHEN 4 THEN (SELECT TOP 1 isnull(DisableCasinoBonus,0) FROM custInfo WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableCasinoBonus = 1)
										  WHEN 3 THEN (SELECT TOP 1 isnull(DisableCasinoBonus,0) FROM custInfo WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableCasinoBonus = 1) 											 
										  WHEN 2 THEN (SELECT TOP 1 isnull(DisableCasinoBonus,0) FROM custInfo WITH (NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableCasinoBonus = 1) 											 
										  ELSE 0 END 

select @DisableUplinesCasinoBonus = isnull(DisableCasinoBonus,0)	 
FROM custinfo with (NOLOCK) 
WHERE custid = case @roleid when 1 then @recommend	
							when 2 then @mrecommend 
							when 3 then @srecommend
							else 0 end									  

SELECT
	ci.username,
	ci.roleid,
	ci.currency,
	case when @downlines = 0 then ci.DisableCasinoBonus else isnull(@DisableDownlinesCasinoBonus,0) end as DisableDownlinesCasinoBonus,	
	
	isnull(@DisableUplinesCasinoBonus,0) as DisableUplinesCasinoBonus,
	
	ci.DisableCasinoBonus as DisableCasinoBonus

FROM custinfo ci WITH(NOLOCK)
WHERE custid = @custid

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCasinoBonusStatus] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelCasinoBonusStatus] TO [vnteam]