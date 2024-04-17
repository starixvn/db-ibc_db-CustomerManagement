ALTER PROCEDURE [dbo].[Age_CustomerShowAnnouncement]
	@CustID INT,
	@OfferedSite NVARCHAR(500),
	@IsLastBatch BIT,
	@IsShowAnnouncement BIT OUTPUT
AS
/*
	Created: 20170116@Elodie
	Task : Check if customer can see announcement to offer new product
	DB: DBAGE/bodb02
	Original:

	Revisions:
		- 20170220@Elodie: Offer FW for line 5005322,1036451,993226,2042873,1156957,506057,796555,2453866 on 21 Feb 2017
		- 20170221@Elodie: Exclude cross site super don't offer FW for batch 2 - [RedmineID:#71810]

	Param's Explanation:
		• @CustID: ID's customer 
		• @OfferedSite: Sites is offered new product in this batch if it's not last batch (@IsLastBatch = 0)
						Sites is not offered new product in this batch if it's a last batch (@IsLastBatch = 1)
		• @IsLastBatch: it's a last batch or not

*/
BEGIN
	SET NOCOUNT ON
	DECLARE @SuperID INT, @Site NVARCHAR(50)
	DECLARE @OfferedSiteTbl TABLE (SiteName NVARCHAR(50)) 
	SELECT @IsShowAnnouncement = 0

	INSERT INTO @OfferedSiteTbl (SiteName)
	SELECT val
	FROM dbo.strSplit(@OfferedSite, ',')

	SELECT @SuperID = srecommend, @Site = site FROM dbo.Customer WITH (NOLOCK) WHERE custid = @CustID

	IF @IsLastBatch = 1
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM @OfferedSiteTbl WHERE SiteName = @Site)
			OR @SuperID IN (-- cross site ('733333','222223', '222225', '222227', '222229')
							324561,395075,450036,674248,877004,896708,900371,913628,938136,1016771,1127269,1164457,1266057,3589744,4204225,6032879,17721601,
							-- cross site ('755555', 'Indo', 'KORIBC')
							938136,1229724,1229754,1229808,1229814,1338545,1755660,1775757,1776435,1776525,2075752
							)
		BEGIN
			SELECT @IsShowAnnouncement = 1
		END
		
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT 1 FROM @OfferedSiteTbl WHERE SiteName = @Site)
			AND @SuperID NOT IN (-- cross site ('733333','222223', '222225', '222227', '222229')
							324561,395075,450036,674248,877004,896708,900371,913628,938136,1016771,1127269,1164457,1266057,3589744,4204225,6032879,17721601,
							-- cross site ('755555', 'Indo', 'KORIBC')
							938136,1229724,1229754,1229808,1229814,1338545,1755660,1775757,1776435,1776525,2075752
							)
		BEGIN
			SELECT @IsShowAnnouncement = 1
		END
	END
END

GO
GRANT EXECUTE ON Age_CustomerShowAnnouncement TO wsv_alp
GO
GRANT EXECUTE ON Age_CustomerShowAnnouncement TO wsv_alpv
GO
GRANT VIEW DEFINITION ON Age_CustomerShowAnnouncement TO vnteam