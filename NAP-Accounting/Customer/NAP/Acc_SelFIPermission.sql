/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_SelFIPermission]
	@UserID int,
	@ViewCustID NVARCHAR (3)
AS
/*
Created: 20200212@Tiara
Task :  Arrange detail permission for finance account 
DB: DBCUST/CUSTDB
Original:

	Revisions:
		- 20200211@Tiara: Arrange detail permission for finance account [Redmine: #128128]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @IsAllow BIT = 0,
			@GroupName NVARCHAR(3),
			@GroupNameV NVARCHAR(3)
					
	IF NOT EXISTS (SELECT 1 
					FROM f_GetFinanceUser () 
					WHERE CustID = @ViewCustID)
		SET @IsAllow = 1
	ELSE
	BEGIN
			IF NOT EXISTS (SELECT 1 
					FROM f_GetAdminUser () 
					WHERE UserID = @UserID)
				SET @IsAllow = 0
			ELSE 
				BEGIN
					SELECT @GroupName = GroupName
					FROM f_GetAdminUser()
					WHERE UserId = @UserId

					SELECT @GroupNameV = GroupName
					FROM f_GetFinanceUser ()
					WHERE CustID = @ViewCustID

					IF @GroupName = 'A' 
						SET @IsAllow = 1
					ELSE IF @GroupName = 'B' AND @GroupNameV = 'A'
						SET @IsAllow = 0
					ELSE IF @GroupName = 'B' AND @GroupNameV = 'B'
						SET @IsAllow = 1
				END
	END
	SELECT @IsAllow AS IsAllow
END