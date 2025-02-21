/*<info serverAlias="DBGLOB-GlobCustDB" executers="wsv_alp" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE Age_CustomerProfilePictureLibraryUpd
	@Old_ImageID INT,	-- Old picture id
	@New_ImageID INT = NULL OUTPUT, --Use for picture library
	@New_Image VARBINARY(MAX) = NULL OUTPUT --Use for picture of customer
AS
/*
	Created by: Tacy
	Date: 20250221
	Task: Update profile picture library 
	DB: DBGLOB-GlobCustDB 	

	Revisions:
		- 20250221@Tacy: Scale Out DBCUST - Migrate tables from CustDB to GlobCustdb [Redmine:#216870]

	Parameter's Explanation:
		ImageId > 1000000 : picture is picture of customer
				<=1000000 : picture is picture from library

*/
BEGIN
	SET NOCOUNT ON

	IF @New_ImageID IS NULL AND @New_Image IS NULL 
		RETURN

	IF @New_Image IS NOT NULL AND @New_ImageID IS NULL --Update new picture of customer
	BEGIN			
		IF @Old_ImageId > 1000000 -- Old picture is picture of customer
		BEGIN
			UPDATE ProfilePicture WITH (ROWLOCK)
			SET Image = @New_Image, RepUpdateTime =  SYSDATETIME()		
			WHERE ImageId = @Old_ImageId

			SELECT @New_ImageID = @Old_ImageId
		END
		ELSE -- Old picture is picture library
		BEGIN
			SELECT @New_ImageID = MAX(ImageId) + 1	
			FROM dbo.ProfilePicture WITH (NOLOCK)

			INSERT INTO dbo.ProfilePicture (ImageId, Image, RepUpdateTime) 
			SELECT @New_ImageID, @New_Image, SYSDATETIME()		
		END			
	END

	IF @New_ImageID IS NOT NULL AND @New_Image IS NULL --Update new picture library
	BEGIN
		IF @Old_ImageId > 1000000 -- Old picture is picture of customer
		BEGIN
			UPDATE ProfilePicture WITH (ROWLOCK)
			SET IsDeleted = 1 ,
				RepUpdateTime = SYSDATETIME()
			WHERE ImageId = @Old_ImageId
		END
	END
END
GO