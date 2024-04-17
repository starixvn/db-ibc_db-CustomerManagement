/*<info serverAlias="DBAGE-bodb02" executers="wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

CREATE PROCEDURE Age_CustomerProfilePictureLibrarySel
	@Mode TINYINT
AS
/*
	Created by: Elodie
	Date: 20191003
	Task: Get all picture library [Redmine:#120726]
	DB: DBAGE/bodb02	

	Revisions:
		- 20191003@Elodie: Initial SP
		- 20230523@Helios: Migrate SP FROM bodb_Age TO bodb02 [Redmine: #186502]
	Parameter's Explanation:
		@Mode:	1: Load picture for MBC site
				2: Load picture for 789y site
*/
BEGIN
	SET NOCOUNT ON

	SELECT ImageId, Image
	FROM ProfilePicture WITH(NOLOCK)
	WHERE ImageId > (@Mode - 1) * 10000 AND ImageId <= @Mode * 10000
	AND IsDeleted = 0
END
GO


