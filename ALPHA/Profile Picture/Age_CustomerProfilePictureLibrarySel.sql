/*<info serverAlias="DBAGE-BODB02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE Age_CustomerProfilePictureLibrarySel
AS
/*
	Created by: Elodie
	Date: 20191003
	Task: Get all picture library [Redmine:#120726]
	DB: DBAGE/BODB02 	

	Revisions:
		- 20191003@Elodie: Initial SP
		
	Parameter's Explanation:

*/
BEGIN
	SET NOCOUNT ON

	SELECT ImageId, Image
	FROM Age_ProfilePicture WITH(NOLOCK)
	WHERE ImageId <=200
END
GO


