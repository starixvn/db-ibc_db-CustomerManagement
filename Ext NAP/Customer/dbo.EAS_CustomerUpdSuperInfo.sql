/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet,wsv_xnap" viewers="vnteam" isFunction="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[EAS_CustomerUpdSuperInfo] @custid INT
	,@firstname NVARCHAR(50)
	,@lastname NVARCHAR(50)
	,@phone NVARCHAR(50)
	,@mobilephone NVARCHAR(50)
	,@email NVARCHAR(50)
	,@fax NVARCHAR(50)
	,@remark NVARCHAR(300)
	,@IP AS NVARCHAR(15) = ''
	,@userid INT
	,@errCode INT = 0 OUTPUT
	,@errMsg NVARCHAR(200) = '' OUTPUT
AS
/*  
Created by: 20180731@Razor
TASk : Splitting Super Profile
DB: DBCUST/CustDB
Revisions:  
	- 20180731@Razor: Splitting Super Profile [#86934]
	- 20181018@Razor: Write log to DBCust when write log has exception [redmine:#103415]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
		,@endRun DATETIME
		,@duration INT
		,@oldValue VARCHAR(MAX)
		,@newValue VARCHAR(MAX)
		,@ActionID INT
		,@oldFirstName VARCHAR(50)
		,@oldLastName VARCHAR(50)
		,@oldPhone VARCHAR(50)
		,@oldMobilephone VARCHAR(50)
		,@oldEmail VARCHAR(50)
		,@oldFax VARCHAR(50)
		,@oldRemark VARCHAR(300)

	SELECT @startRun = GETDATE()
		,@ActionID = 677

	SELECT @oldFirstName = firstname
		,@oldLastName = lastname
		,@oldPhone = phone
		,@oldMobilephone = mobilephone
		,@oldEmail = email
		,@oldFax = fax
		,@oldRemark = remark
	FROM [dbo].[CustSuperProfile] WITH (NOLOCK)
	WHERE custid = @CustId

	BEGIN TRY
		UPDATE [dbo].[CustSuperProfile]
		SET [firstname] = @firstname
			,[lastname] = @lastname
			,[phone] = @phone
			,[mobilephone] = @mobilephone
			,[fax] = @fax
			,[email] = @email
			,[remark] = @remark
		WHERE custid = @CustId
	END TRY

	BEGIN CATCH
		SELECT @ErrMsg = 'Error! Error when updating Message Customer Read Status.'
			,@ErrCode = 101
	END CATCH

	SELECT @oldValue = '<EAS_CustomerUpdSuperInfo LastName="' + COALESCE(@oldLastName, SPACE(1)) + '" FirstName ="' + COALESCE(@oldFirstName, SPACE(1)) + '" Phone="' + COALESCE(@oldPhone, SPACE(1)) + '" Mobilephone="' + COALESCE(@oldMobilephone, SPACE(1)) + '" Email="' + COALESCE(@oldEmail, SPACE(1)) + '" Fax="' + COALESCE(@oldFax, SPACE(1)) + '" Remark="' + COALESCE(@oldRemark, SPACE(1)) + '" IP="' + COALESCE(@IP, SPACE(1))

	SELECT @newValue = '<EAS_CustomerUpdSuperInfo LastName="' + COALESCE(@LastName, SPACE(1)) + '" FirstName ="' + COALESCE(@FirstName, SPACE(1)) + '" Phone="' + COALESCE(@Phone, SPACE(1)) + '" Mobilephone="' + COALESCE(@mobilephone, SPACE(1)) + '" Email="' + COALESCE(@email, SPACE(1)) + '" Fax="' + COALESCE(@fax, SPACE(1)) + '" Remark="' + COALESCE(@remark, SPACE(1)) + '" IP="' + COALESCE(@IP, SPACE(1))

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun)

	BEGIN TRY
		DECLARE @tempNewValue NVARCHAR(MAX)
			,@tempOldValue NVARCHAR(MAX)

		SELECT @tempNewValue = @newValue + '" ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), space(1)) + '" ErrMsg="' + COALESCE(@ErrMsg, space(1)) + '" />'
			,@tempOldValue = @oldValue + '" ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), space(1)) + '" ErrMsg="' + COALESCE(@ErrMsg, space(1)) + '" />'

		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP @UserID = @userid
			,@CustID = @CustId
			,@ActionID = @ActionID
			,@TrackingValue = @tempNewValue
			,@TrackingValue2 = @tempOldValue
			,@duration = @duration
	END TRY

	BEGIN CATCH
		SELECT @oldValue = @oldValue + '" ErrMsg="' + ERROR_MESSAGE() + '" />'

		SELECT @newValue = @newValue + '" ErrMsg="' + ERROR_MESSAGE() + '" />'

		EXEC DBCUST.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP @UserID = @userid
			,@CustID = @CustID
			,@ActionID = @ActionID
			,@TrackingValue = @newValue
			,@TrackingValue2 = @oldValue
			,@duration = @duration
	END CATCH
END
GO


