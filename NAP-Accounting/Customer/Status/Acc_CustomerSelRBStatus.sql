 ALTER PROCEDURE [dbo].[Acc_CustomerSelRBStatus]
	@custid INT
	
/*
	Created: Johnson
	Date: 2011-03-15
	DB: DB052.BODB02
	Task: get disable status of Racing 
	
	Revisions:
*/
AS
SET NOCOUNT ON


DECLARE @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT,
	@DisableDownlines151_31 BIT, @DisableDownlines151_41 BIT, @DisableDownlines151_51 BIT,
	@DisableDownlines152_41 BIT, @DisableDownlines152_51 BIT, @DisableDownlines153_51 BIT, 
	@DisableUplines151_31 BIT, @DisableUplines151_41 BIT, @DisableUplines151_51 BIT,
	@DisableUplines152_41 BIT, @DisableUplines152_51 BIT, @DisableUplines153_51 BIT

SELECT @roleid = roleid , @srecommend = srecommend , @mrecommend = mrecommend , @recommend = recommend 
FROM custinfo WITH(NOLOCK) 
WHERE custid = @custid 

SELECT @DisableDownlines151_31 = CASE @roleid WHEN 4 THEN (SELECT TOP 1 isnull(DisableHorseracing,0) FROM custInfo WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableHorseracing = 1)
										  WHEN 3 THEN (SELECT TOP 1 isnull(DisableHorseracing,0) FROM custInfo WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableHorseracing = 1) 											 
										  WHEN 2 THEN (SELECT TOP 1 isnull(DisableHorseracing,0) FROM custInfo WITH (NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableHorseracing = 1) 											 
										  ELSE 0 END 

SELECT @DisableDownlines151_41 = CASE @roleid WHEN 4 THEN (SELECT TOP 1 isnull(DisableOpenTote,0) FROM custInfo WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableOpenTote = 1)
										  WHEN 3 THEN (SELECT TOP 1 isnull(DisableOpenTote,0) FROM custInfo WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND DisableOpenTote = 1) 											 
										  WHEN 2 THEN (SELECT TOP 1 isnull(DisableOpenTote,0) FROM custInfo WITH (NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND DisableOpenTote = 1) 											 
										  ELSE 0 END 

SELECT @DisableDownlines151_51 = CASE @roleid WHEN 4 THEN (SELECT TOP 1 isnull(Disable151_AU,0) FROM custInfo WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND Disable151_AU = 1)
										  WHEN 3 THEN (SELECT TOP 1 isnull(Disable151_AU,0) FROM custInfo WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND Disable151_AU = 1) 											 
										  WHEN 2 THEN (SELECT TOP 1 isnull(Disable151_AU,0) FROM custInfo WITH (NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND Disable151_AU = 1) 											 
										  ELSE 0 END 

SELECT @DisableDownlines152_41 = CASE @roleid WHEN 4 THEN (SELECT TOP 1 isnull(Disable152_UK,0) FROM custInfo WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND Disable152_UK = 1)
										  WHEN 3 THEN (SELECT TOP 1 isnull(Disable152_UK,0) FROM custInfo WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND Disable152_UK = 1) 											 
										  WHEN 2 THEN (SELECT TOP 1 isnull(Disable152_UK,0) FROM custInfo WITH (NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND Disable152_UK = 1) 											 
										  ELSE 0 END 

SELECT @DisableDownlines152_51 = CASE @roleid WHEN 4 THEN (SELECT TOP 1 isnull(Disable152_AU,0) FROM custInfo WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND Disable152_AU = 1)
										  WHEN 3 THEN (SELECT TOP 1 isnull(Disable152_AU,0) FROM custInfo WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND Disable152_AU = 1) 											 
										  WHEN 2 THEN (SELECT TOP 1 isnull(Disable152_AU,0) FROM custInfo WITH (NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND Disable152_AU = 1) 											 
										  ELSE 0 END 

SELECT @DisableDownlines153_51 = CASE @roleid WHEN 4 THEN (SELECT TOP 1 isnull(Disable153_AU,0) FROM custInfo WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND Disable153_AU = 1)
										  WHEN 3 THEN (SELECT TOP 1 isnull(Disable153_AU,0) FROM custInfo WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2 AND Disable153_AU = 1) 											 
										  WHEN 2 THEN (SELECT TOP 1 isnull(Disable153_AU,0) FROM custInfo WITH (NOLOCK) WHERE recommend  = @custid AND roleid = 1 AND Disable153_AU = 1) 											 
										  ELSE 0 END 


select 
	@DisableUplines151_31 = isnull(DisableHorseRacing,0),
   @DisableUplines151_41 = isnull(DisableOpenTote,0),
   @DisableUplines151_51 = isnull(Disable151_AU,0),
   @DisableUplines152_41 = isnull(Disable152_UK,0),
   @DisableUplines152_51 = isnull(Disable152_AU,0),
   @DisableUplines153_51 = isnull(Disable153_AU,0)		 
FROM custinfo with (NOLOCK) 
WHERE custid = case @roleid when 1 then @recommend	
							when 2 then @mrecommend 
							when 3 then @srecommend
							else 0 end									  

SELECT
	ci.username,
	ci.roleid,
	@DisableDownlines151_31 as DisableDownlines151_31,
	@DisableDownlines151_41 as DisableDownlines151_41,	
	@DisableDownlines151_51 as DisableDownlines151_51,
	@DisableDownlines152_41 as DisableDownlines152_41,	
	@DisableDownlines152_51 as DisableDownlines152_51,
	@DisableDownlines153_51 as DisableDownlines153_51,
	
	isnull(@DisableUplines151_31,0) as DisableUplines151_31,
	isnull(@DisableUplines151_41,0) as DisableUplines151_41,
	isnull(@DisableUplines151_51,0) as DisableUplines151_51,
	isnull(@DisableUplines152_41,0) as DisableUplines152_41,
	isnull(@DisableUplines152_51,0) as DisableUplines152_51,
	isnull(@DisableUplines153_51,0) as DisableUplines153_51, 
	
	ci.DisableHorseRacing as Disable151_31,
	ci.DisableOpenTote	as Disable151_41,
	ci.Disable151_AU as Disable151_51,
	ci.Disable152_UK as Disable152_41,
	ci.Disable152_AU as Disable152_51,
	ci.Disable153_AU as Disable153_51

FROM custinfo ci WITH(NOLOCK)
WHERE custid = @custid
					
					
								

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelRBStatus] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelRBStatus] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelRBStatus] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelRBStatus] TO [vnteam]