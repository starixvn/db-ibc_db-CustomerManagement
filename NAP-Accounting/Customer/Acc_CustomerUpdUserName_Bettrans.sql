ALTER PROCEDURE [dbo].[Acc_CustomerUpdUserName_Bettrans]
	@NewUserName varchar(30),
	@CustID INT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
SET NOCOUNT ON

/*
Created: 20130808@Elodie
Task : Change username in bettrans table
DB: DBTXN/bodb02
Original:

Revisions:

Param's Explanation:
  
*/
BEGIN TRANSACTION
	UPDATE bettrans WITH (ROWLOCK, UPDLOCK) set username = @NewUserName where custid = @CustID	
	If @ErrCode <> 0
	BEGIN
		ROLLBACK TRANSACTION
		SELECT  @ErrCode = 102, 
				@ErrMsg = 'Transaction: Update username unsuccessfully.'
		RETURN			
	END
	
	UPDATE bettrans14 WITH (ROWLOCK, UPDLOCK) set username = @NewUserName where custid = @CustID
	If @ErrCode <> 0
	BEGIN
		ROLLBACK TRANSACTION
		SELECT @ErrCode = 102, @ErrMsg = 'Transaction: Update username unsuccessfully.'
		RETURN			
	END		
COMMIT TRANSACTION


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdUserName_Bettrans] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdUserName_Bettrans] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdUserName_Bettrans] TO [vnteam] AS [dbo]