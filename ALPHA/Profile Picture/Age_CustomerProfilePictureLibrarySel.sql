/*<info serverAlias="DBAGE-bodb02" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE Age_CustomerProfilePictureLibrarySel
	@Mode TINYINT,
	@IsRandom BIT = 0
AS
/*
	Created by: Elodie
	Date: 20191003
	Task: Get all picture library [Redmine:#120726]
	DB: DBAGE/bodb02	

	Revisions:
		- 20191003@Elodie: Initial SP
		- 20230523@Helios: Migrate SP FROM bodb_Age TO bodb02 [Redmine: #186502]
		- 20241220@Elodie: Random Image [Redmine: #215625]
	Parameter's Explanation:
		@Mode:	1: Load picture for MBC site
				2: Load picture for 789y site
	Ex: EXEC Age_CustomerProfilePictureLibrarySel_xtest @Mode = 2, @IsRandom = 1
*/
BEGIN
	SET NOCOUNT ON

	IF @IsRandom = 0
	BEGIN
		SELECT ImageId, Image
		FROM ProfilePicture WITH(NOLOCK)
		WHERE ImageId > (@Mode - 1) * 10000 AND ImageId <= @Mode * 10000
			AND IsDeleted = 0
	END
	ELSE
	BEGIN
		DECLARE @ImageId INT, @MaxImageId INT, @MinImageId INT

		SELECT @MinImageId = (@Mode - 1) * 10000 + 1
		SELECT @MaxImageId = @MinImageId + 200
		WHILE (1=1)
		BEGIN			
			SELECT @ImageId = FLOOR(RAND()*(@MaxImageId-@MinImageId)+@MinImageId)
			
			SELECT ImageId, Image
			FROM ProfilePicture WITH(NOLOCK)
			WHERE ImageId = @ImageId
				AND IsDeleted = 0
			
			IF @@ROWCOUNT = 1 BREAK 
		END
	END
	
END
GO


