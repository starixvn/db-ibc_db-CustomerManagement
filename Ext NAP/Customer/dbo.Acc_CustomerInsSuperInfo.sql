/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Acc_CustomerInsSuperInfo] @custName VARCHAR(100)
	,@errCode INT = 0 OUTPUT
	,@errMsg NVARCHAR(200) = '' OUTPUT
AS
/*  
Created by: 20180731@Razor
TASk : Splitting Super Profile
DB: DBCUST/CustDB
Revisions:  
	- 20180731@Razor: Splitting Super Profile [#86934]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @custId INT
	
	SELECT @custId = custid
	FROM dbo.Customer WITH(NOLOCK)
	WHERE UserName = @custName
		AND RoleId = 4
	
	IF ISNULL(@custId, 0) = 0
	BEGIN
		SELECT @ErrMsg = 	N'This username is invalid!'	
			, @ErrCode = 102
		RETURN
	END
	
	BEGIN TRY
		IF (
				NOT EXISTS (
					SELECT 1
					FROM [dbo].[CustSuperProfile] WITH (NOLOCK)
					WHERE custid = @custid
					)
				)
		BEGIN
			INSERT INTO [dbo].[CustSuperProfile] (custid)
			VALUES (@custid)
		END
	END TRY

	BEGIN CATCH
		SELECT @errMsg = 'Error! Error when inserting Customer User Info.'
			,@errCode = 101
	END CATCH
END
GO


