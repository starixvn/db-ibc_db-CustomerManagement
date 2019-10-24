/*<info serverAlias="DBAGE-BODB02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE Age_CustomerProfilePictureLibrarySel
	@Mode TINYINT
AS
/*
	Created by: Elodie
	Date: 20191003
	Task: Get all picture library [Redmine:#120726]
	DB: DBAGE/BODB02 	

	Revisions:
		- 20191003@Elodie: Initial SP
		
	Parameter's Explanation:
		@Mode:	1: Load picture for MBC site
				2: Load picture for 789y site
*/
BEGIN
	SET NOCOUNT ON

	SELECT ImageId, Image
	FROM Age_ProfilePicture WITH(NOLOCK)
	WHERE ImageId > (@Mode - 1) * 10000 AND ImageId <= @Mode * 10000
END
GO


