SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_MessageNoticeUpd] 
	@custID			int, 	
	@userID			int,
	@TypeID			int=1 -- 1: Position taking. 2: Betting Limit.
AS
BEGIN
    /*
    Created: 20090119@AnhPham
    Task: update table "MESSAGE_NOTICE" when the minimum position taking value of value has  been changed
    DB: DB03.On_User
    Original:
    Revisions:
		- 20110427@Simon: Add Popup Message For Betting Limit.
    
    Param's Explanation:
        . @custID: ID of agent whose minimum position taking value has been changed
        . @userID: ID of master or admin who made it
    */
		
	DECLARE @isViewed bit
	DECLARE @modifiedDate datetime
	SET @isViewed = 0
	SET @modifiedDate = GETDATE()

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (NOT EXISTS(SELECT * FROM MESSAGE_NOTICE WITH(NOLOCK) WHERE @custID = custID AND @userID = userID AND @TypeID = TypeID))
	BEGIN
		-- Insert statements for procedure here
		INSERT INTO MESSAGE_NOTICE
		(
			custID,
			TypeID,
			modifiedDate,
			userID,
			isViewed
		)
		VALUES
		(
			@custID,
			@TypeID,
			@modifiedDate,
			@userID,
			@isViewed
		)
	END
	ELSE
	BEGIN
		-- Update statements for procedure here
		UPDATE MESSAGE_NOTICE WITH(ROWLOCK)
		SET
			TypeID			= @TypeID,
			modifiedDate	= @modifiedDate,
			isViewed		= @isViewed
		WHERE @custID = custID AND @userID = userID AND @TypeID = TypeID
	END

END
GO
 
GRANT EXECUTE ON [dbo].[Age_MessageNoticeUpd] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_MessageNoticeUpd] TO [wsv_nap]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_MessageNoticeUpd] TO [vnteam]
GO