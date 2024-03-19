


ALTER PROCEDURE Age_CustomerCheckNotification
(
	@custid		INT,
	@isShowed	BIT = 0 OUTPUT
)
AS
/*
	Created: 20111219@Lukas
	Task: check if customer was showed Number Game notification (on web)
	DB: DB053.BODB02

	Revisions:
		@isshowed:  0	not allow to show Number game notification
					1	allow to show Number game notification
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @customer TABLE (custid INT)

	INSERT INTO @customer
			      SELECT 304314             ----CC
		UNION ALL SELECT 1783435             ----KKKUSD
		UNION ALL SELECT 262637             ----SCK
		UNION ALL SELECT 687622             ----MVKU
		UNION ALL SELECT 3390616             ----QHN
		UNION ALL SELECT 3390621             ----QVN
		UNION ALL SELECT 2198456             ----SKA
		UNION ALL SELECT 2793195             ----SKAA
		UNION ALL SELECT 2798869             ----SKAB
		UNION ALL SELECT 2798950             ----SKAC
		UNION ALL SELECT 2850839             ----SKAD
		UNION ALL SELECT 2853316             ----SKAE
		UNION ALL SELECT 3412762             ----SHB
		UNION ALL SELECT 3508886             ----SHD
		UNION ALL SELECT 2877199             ----SKAF
		UNION ALL SELECT 2975866             ----SKAG
		UNION ALL SELECT 3024023             ----SKAH
		UNION ALL SELECT 3024027             ----SKAI
		UNION ALL SELECT 3024035             ----SKAJ
		UNION ALL SELECT 3390623             ----SKAN
		UNION ALL SELECT 3472707             ----SKAO
		UNION ALL SELECT 3472732             ----SKAP
		UNION ALL SELECT 3535165             ----SKAR
		UNION ALL SELECT 3675856             ----SKAS
		UNION ALL SELECT 3675859             ----SKAT
		UNION ALL SELECT 4166219             ----skau
		UNION ALL SELECT 4166221             ----skav
		UNION ALL SELECT 4664102             ----skaw
		UNION ALL SELECT 4664106             ----skax
		UNION ALL SELECT 4664111             ----skay
		UNION ALL SELECT 731165             ----SKKS
		UNION ALL SELECT 1335772             ----SKT
		UNION ALL SELECT 1727945             ----SKKD
		UNION ALL SELECT 1940367             ----SKX
		UNION ALL SELECT 1999503             ----SKY
		UNION ALL SELECT 2126540             ----SKJ
		UNION ALL SELECT 2198461             ----SKL
		UNION ALL SELECT 2198868             ----SKQ
		UNION ALL SELECT 2462931             ----SKK
		UNION ALL SELECT 2470330             ----VIU
		UNION ALL SELECT 2503678             ----SKO
		UNION ALL SELECT 2793182             ----skn
		UNION ALL SELECT 2793190             ----skp
		UNION ALL SELECT 3122695             ----SKKA

	DECLARE @srecommend INT,
			@mrecommend INT,
			@recommend INT	

	SELECT	@srecommend = srecommend,
			@mrecommend = mrecommend,
			@recommend  = recommend
	FROM custinfo WITH(NOLOCK)
	WHERE custid = @custid

	IF EXISTS (SELECT 1 FROM @customer WHERE custid = @srecommend OR custid = @mrecommend OR custid = @recommend)
		SET @isshowed = 0
	ELSE	
		SET @isshowed = 1

END
GO
GRANT VIEW DEFINITION ON Age_CustomerCheckNotification TO vnteam
GO
GRANT EXECUTE ON Age_CustomerCheckNotification TO bodbDownlineNet,wsv_alp
GO
GRANT EXECUTE ON Age_CustomerCheckNotification TO bodbDownlineNetView,wsv_alpv