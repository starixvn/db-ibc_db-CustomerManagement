/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_SelFIPermission]
	@custid int,
	@ViewGroup NVARCHAR (3)
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
			@Permission NVARCHAR(5)
			
	IF NOT EXISTS (SELECT 1 
					FROM f_GetFinanceUser () 
					WHERE CustID = @custid)
		SET @IsAllow = 0
	ELSE
	BEGIN
		SELECT @GroupName = GroupName
		FROM f_CS_GetFinanceUser ()
		WHERE CustID = @custid

		SELECT @Permission = Permission
		FROM f_GetFIPermission ()
		WHERE GroupName = @GroupName
		
		IF @Permission = 'All'
			SET @IsAllow = 1
		ELSE IF @Permission = 'B' AND @ViewGroup = 'A'
			SET @IsAllow = 0
		ELSE IF @Permission = 'B' AND (@ViewGroup = 'B' OR @ViewGroup = 'C')
			SET @IsAllow = 1
	END
	SELECT @IsAllow AS IsAllow
END