/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_SelFIPermission]
	@UserID INT,
	@username VARCHAR(30),
	@CheckCustId TINYINT = 0
	
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
	DECLARE @CustID INT
	DECLARE @IsAllow BIT = 0,
			@GroupName NVARCHAR(3),
			@GroupNameV NVARCHAR(3),
			@Permission NVARCHAR(5)
	    --Get CustID FROM DB06, WHERE got index on Username AND Username2 or CustID
    EXEC @custid = DBACC.bodb02.dbo.f_GetCustIDFromUsernameOrCustId @username, @CheckCustId
	
	IF NOT EXISTS (SELECT CustID
					FROM dbo.f_GetFinanceUser () 
					WHERE CustID = @CustID)
		SELECT @IsAllow = 1
	ELSE
		BEGIN
			IF NOT EXISTS (SELECT UserID 
					FROM f_GetAdminUser () 
					WHERE UserID = @UserID) --Viewer
				SET @IsAllow = 0
			ELSE 
				BEGIN
					SELECT @GroupName = GroupName
					FROM f_GetAdminUser()
					WHERE UserId = @UserId

					SELECT @GroupNameV = GroupName
					FROM f_GetFinanceUser ()
					WHERE CustID = @CustID --Viewee

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