/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE dbo.Acc_WhiteLabelSetting_Check
	-- Add the parameters for the stored procedure here
	 @Username		VARCHAR(30)
	,@CheckCustId	TINYINT = 0
	,@IsNew			BIT=1
	,@CustID		INT				= 0	OUTPUT
	,@ErrCode		INT				= 0	OUTPUT
	,@ErrMsg		NVARCHAR(4000)	= '' OUTPUT
AS
/*
	Created: Tacy
	Task: NAP - Configure White Label rate
	DB: DBCUST-CUSTDB

	Revisions:
		- 20240827@Tacy: Create SP [Redmine: #209807]

	Param's Explanation:
		* @IsNew=1 : add new setting
				=0 : update setting
*/
BEGIN 
	SET NOCOUNT ON;

	EXEC @custid = dbo.f_GetCustIDFromUsernameOrCustId @Username,@CheckCustId

	--Invalid username: do not exists on system
	IF @CustID IS NULL
	BEGIN
		SELECT @ErrCode=100
			, @ErrMsg='This account is invalid.'

		RETURN			
	END

	--Check disable user
    IF EXISTS (SELECT TOP 1 1 FROM custInfo WITH (NOLOCK) WHERE custid=@CustID AND Enabled = 0)
	BEGIN
		SELECT @ErrCode=101
			, @ErrMsg='This account is disabled.'

		RETURN			
	END

	--check: deposit account
	IF EXISTS (SELECT TOP 1 1 FROM Customer c WITH (NOLOCK) 
				INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site
				WHERE custid=@CustID AND s.isDeposit=1)
	BEGIN
		SELECT @ErrCode=102
			, @ErrMsg='This account is invalid.'

		RETURN			
	END

	--check: dummy account
	IF EXISTS (SELECT TOP 1 1 FROM Acc_CustDirect WITH (NOLOCK) WHERE custid=@CustID)
	BEGIN
		SELECT @ErrCode=103
			, @ErrMsg='This account is invalid.'

		RETURN			
	END

	--Check disable user
    IF EXISTS (SELECT TOP 1 1 FROM custInfo WITH (NOLOCK) WHERE custid=@CustID AND roleid NOT IN (2,3,4))
	BEGIN
		SELECT @ErrCode=104
			, @ErrMsg='This account is member level.'

		RETURN			
	END

	IF EXISTS (SELECT 1 FROM WhiteLabelSetting WITH (NOLOCK)
				WHERE CustID=@CustID AND ToDate > GETDATE()) 
		AND @IsNew=1
	BEGIN
		SELECT @ErrCode=105
			, @ErrMsg='This account has existing settings. New settings cannot be added.'

		RETURN	 
	END

	IF NOT EXISTS (SELECT 1 FROM WhiteLabelSetting WITH (NOLOCK)
					WHERE CustID=@CustID AND ToDate > GETDATE()) 
		AND @IsNew=0
	BEGIN
		SELECT @ErrCode=106
			, @ErrMsg='This account has no existing settings. Settings cannot be updated.'

		RETURN	 
	END
END
GO