/*<info serverAlias="DBCUST-bodb_Credit" executers="bodbDownlineNet,wsv_alp" viewers="" isFunction="0"></info>*/

CREATE PROCEDURE DBA_InsertProfilePictureLibrary
	@Image VARBINARY(MAX),
	@IsMBC BIT
AS	
/*

	Created by: ELodie
	Date: 20191128
	Task: Initial library profile picture [Redmine:#120726]
	DB: DBCUST/bodb_Credit 	

	Revisions:
		- 20191003@Elodie: Force user to use profile picture [Redmine: #120726]
		- 20230523@Helios: Migrate SP FROM DBAGE TO DBCUST [Redmine: #186502]
	Parameter's Explanation:


*/
BEGIN
	DECLARE @ImageId INT

	IF @IsMBC = 1
		SELECT @ImageId = ISNULL(MAX(ImageId),0) + 1 FROM ProfilePicture WITH (NOLOCK) WHERE ImageId <= 10000
	ELSE
		SELECT @ImageId = ISNULL(MAX(ImageId),10000) + 1 FROM ProfilePicture WITH (NOLOCK) WHERE ImageId BETWEEN 10001 AND 20000

	INSERT INTO dbo.ProfilePicture (ImageId, Image, RepUpdateTime) 
	SELECT @ImageId, @Image , SYSDATETIME()
END
