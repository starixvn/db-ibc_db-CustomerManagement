/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Exchange_PJUnitPrice_Upd]
	@UserId			INT,
	@ExchangeId		INT,
	@PJUnitPrice	DECIMAL(19,8),
	@IP				VARCHAR(20) = '',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created by Percy
	Date: 2018-02-02
	DB: DBCUST.CustDB
	Task: Exchange - Update PJUnitPrice value

	Revisions:
		- 20180202@Percy: Initialize SP [RedmineID: #89122]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission --
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission
		@CustID = @UserID,
		@FuncName = '[PJUnitPrice]',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT,
		@System = 'ACCOUNTING'

	IF @ErrCode <> 0
		RETURN

	BEGIN TRY
		UPDATE dbo.Exchange WITH (ROWLOCK, UPDLOCK)
		SET PJUnitPrice = @PJUnitPrice
		WHERE ExchangeId = @ExchangeId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 100, @ErrMsg = 'Update failed'
		RETURN
	END CATCH
	
	-- write log
	DECLARE @LogData NVARCHAR(MAX)
	SELECT  @LogData = '<Acc_Exchange_PJUnitPrice_Upd UserID="' + CONVERT(VARCHAR(20), @UserID)
						+ '" ExchangeId="'			+ CONVERT(VARCHAR(50), @ExchangeId)
						+ '" PJUnitPrice="'			+ CONVERT(VARCHAR(50), @PJUnitPrice)
						+ '" />'

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_ExchangeRate
		@UserID = @UserID,
		@ExchangeID = @ExchangeId,
		@PJUnitPrice = @PJUnitPrice,
		@IP = @IP,
		@Doing = @LogData
END
GO