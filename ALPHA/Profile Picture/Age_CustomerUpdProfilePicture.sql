/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE Age_CustomerUpdProfilePicture
	@custid INT,
	@Mode TINYINT, 
	@ImageID INT = NULL, --Use for picture library
	@Image VARBINARY(MAX) = NULL OUTPUT, --Use for picture of customer
	@isDefault BIT = 0, -- Add default picture when user first login
	@IsMainServer BIT, 

	@IP VARCHAR(20) = '',
	@ErrMsg VARCHAR(200) = '' OUTPUT,
	@ErrCode INT = 0 OUTPUT
AS
/*

	Created by: Kathy
	Date: 20131114
	Task: Customer profile picture [Redmine:#7547]
	DB: DBCUST/CustDB 	

	Revisions:
		- 20140120@Kathy: Add more logAction
		- 20181123@Helen: DB053.bodb_AGE/BODB02 & DB052.bodb_Summary Migration [Redmine: 104770]
		- 20191003@Elodie: Force user to use profile picture [Redmine: #120726]
		- 20210611@Elodie: Correct Log action [Redmine: #156679]
		- 20230523@Helios: Migrate SP FROM DBAGE TO DBCUST [Redmine: #186502]
		- 20240821@Helios: Scale Out DBCUST - Move CustProfilePicture and ProfilePicture to DBcust [Redmine: #209640]   
	Parameter's Explanation:
		@isDefault: - 0 Update picture
					- 1 Insert default picture
		@Mode:	1: Load picture for MBC site
				2: Load picture for 789y site

*/
BEGIN
	SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @ActionID INT,
			@LogData VARCHAR(MAX), @LogOldData VARCHAR(MAX), @Old_ImageId INT, @New_ImageId INT
	DECLARE @ProfilePicture TABLE (ImageId INT)

	SET @startRun = GETDATE()
	
	IF @isDefault = 1 
	BEGIN
		SELECT @ImageID = (@custid%200 + 1) + (@Mode-1) * 10000

		INSERT INTO CustProfilePicture (CustId, ImageId, modified , RepUpdateTime)
		SELECT @custid, @ImageID, NULL, SYSDATETIME()
		WHERE NOT EXISTS (SELECT 1 FROM CustProfilePicture WITH (NOLOCK) WHERE CustId = @custid)	

		IF @@ROWCOUNT = 0
			RETURN
		
		SELECT @Image = Image FROM ProfilePicture WITH (NOLOCK) WHERE ImageId = @ImageID
		SET @ActionID = 697
	END	
	ELSE
	BEGIN
		SELECT @Old_ImageId = cp.ImageId
		FROM dbo.CustProfilePicture cp WITH (NOLOCK)
		WHERE cp.custid = @custid

		IF @Image IS NOT NULL AND @ImageID IS NULL --Update new picture of customer
		BEGIN			
			IF @Old_ImageId > 1000000 -- Old picture is picture of customer
			BEGIN
				UPDATE ProfilePicture WITH (ROWLOCK)
				SET Image = @Image, RepUpdateTime =  SYSDATETIME()		
				WHERE ImageId = @Old_ImageId

				UPDATE CustProfilePicture WITH (ROWLOCK)
				SET modified = GETDATE(), RepUpdateTime =  SYSDATETIME()				
				WHERE custid = @custid

				SELECT @ImageID = @Old_ImageId
				SET @ActionID = 95001
			END
			ELSE -- Old picture is picture library
			BEGIN
				INSERT INTO dbo.ProfilePicture (ImageId, Image, RepUpdateTime) 
				OUTPUT inserted.ImageId INTO @ProfilePicture (ImageId)
				SELECT MAX(ImageId) + 1, @Image, SYSDATETIME()		
				FROM dbo.ProfilePicture WITH (NOLOCK)

				UPDATE cp 
				SET ImageId = p.ImageId,
					modified = GETDATE(),
					RepUpdateTime = SYSDATETIME()
				FROM CustProfilePicture cp WITH (ROWLOCK)
					CROSS JOIN @ProfilePicture p 
				WHERE custid = @custid

				SELECT @ImageID = ImageId FROM @ProfilePicture
				SET @ActionID = 698
			END			
		END

		IF @ImageID IS NOT NULL AND @Image IS NULL --Update new picture library
		BEGIN
			IF @Old_ImageId > 1000000 -- Old picture is picture of customer
			BEGIN
				UPDATE ProfilePicture WITH (ROWLOCK)
				SET IsDeleted = 1 ,
					RepUpdateTime = SYSDATETIME()
				WHERE ImageId = @Old_ImageId

				UPDATE CustProfilePicture WITH (ROWLOCK)
				SET ImageId = @ImageID,
					modified = GETDATE(),
					RepUpdateTime = SYSDATETIME()
				WHERE custid = @custid

				SET @ActionID = 699
			END
			ELSE -- Old picture is picture library
			BEGIN
				UPDATE CustProfilePicture WITH (ROWLOCK)
				SET ImageId = @ImageID,
					modified = GETDATE(),
					RepUpdateTime = SYSDATETIME()
				WHERE custid = @custid

				SET @ActionID = 95000
			END
		END
	END

	IF @IsMainServer = 1
	BEGIN
		SET @endRun = getdate()
		SET @duration  = datediff (millisecond,@startRun,@endRun)
				
		-- write log
		SELECT	@LogData =  '<R ' +
							'ImageId = "' + COALESCE(CAST(@ImageID AS VARCHAR(20)),SPACE(1)) + '" ' +
							'IP="'+ COALESCE(CAST(@IP as varchar(20)),SPACE(1)) + '" />'
								
		SELECT	@LogOldData =  '<R ' +
							'ImageId = "' + COALESCE(CAST(@Old_ImageId AS VARCHAR(20)),SPACE(1)) + '" ' +
							'IP="'+ COALESCE(CAST(@IP as varchar(20)),SPACE(1)) + '" />'
		
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= @CustID,
			@CustId				= @CustId,
			@ActionId			= @ActionID,
			@TrackingValue		= @LogData,
			@TrackingValue2		= @LogOldData,
			@Duration			= @Duration

	END
END
GO



