/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE Age_CustomerUpdProfilePicture
	@custid INT,
	@Mode TINYINT, 
	@ImageID INT = NULL, 
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
		- 20250221@Tacy: Scale Out DBCUST - Migrate tables from CustDB to GlobCustdb [Redmine:#216870]
	Parameter's Explanation:
		@isDefault: - 0 Update picture
					- 1 Insert default picture
		@Mode:	1: Load picture for MBC site
				2: Load picture for 789y site

		ImageId > 1000000 : picture is picture of customer (CustPic)
				<=1000000 : picture is picture from library (LibPic)
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @ActionID INT,
			@LogData VARCHAR(MAX), @LogOldData VARCHAR(MAX), @Old_ImageID INT
	
	IF @Image IS NULL AND @ImageID IS NULL 
		RETURN

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

		UPDATE cp 
		SET ImageId = @ImageID,
			modified = GETDATE(),
			RepUpdateTime = SYSDATETIME()
		FROM CustProfilePicture cp WITH (ROWLOCK)
		WHERE custid = @custid

		SELECT @ActionID = 
				CASE WHEN @Image IS NOT NULL --Update new picture of customer
					THEN
						CASE WHEN @Old_ImageId > 1000000 THEN 95001 ELSE 698 END	-- CustPic / LibPic to new CustPic
					ELSE --Update new picture library
						CASE WHEN @Old_ImageId > 1000000 THEN 699 ELSE 95000 END	-- CustPic / LibPic to new LibPic
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



