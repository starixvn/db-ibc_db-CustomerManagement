/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap,wsv_alp,wsv_alpv" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerCheckSynced]  
	@CustID		INT = NULL,
	@Username VARCHAR(30) = NULL,
	@bitmap		TINYINT = 1,
	@IsSynced	BIT = 0 OUTPUT
AS  
/*  
	Creator: 20241001@Tacy  
	Task : Check custinfo has synced.
	DB: DBCUST/CustDB

	Revisions:  
		- 20241001@Tacy: Create SP [Redmine: #211405]
	
	Param's Explanation:
		@bitmap = 1 ~ NovaCasino
*/
BEGIN
    SET NOCOUNT ON;
	
	IF ISNULL(@CustID,0)=0 AND ISNULL(@Username,'')=''
		RETURN

	IF @Username<>''
		EXEC @custid = dbo.f_GetCustIDFromUsernameOrCustId @Username,0

	DECLARE @RoleID TINYINT

	SELECT @RoleID=roleid
	FROM Customer WITH (NOLOCK)
	WHERE custid=@CustID

	IF @RoleID=4
	BEGIN
		SELECT @IsSynced=dbo.f_GetProductStatus(c.IsSynced, @bitmap)
		FROM CustSuper c WITH (NOLOCK)
		WHERE CustID=@CustID
	END
	ELSE IF @RoleID=3
	BEGIN
		SELECT @IsSynced=dbo.f_GetProductStatus(c.IsSynced, @bitmap)
		FROM CustMaster c WITH (NOLOCK)
		WHERE CustID=@CustID
	END
	ELSE IF @RoleID=2
	BEGIN
		SELECT @IsSynced=dbo.f_GetProductStatus(c.IsSynced, @bitmap)
		FROM CustAgent c WITH (NOLOCK)
		WHERE CustID=@CustID
	END

	SELECT @IsSynced=ISNULL(@IsSynced,0)
END
GO