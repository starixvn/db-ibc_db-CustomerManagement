/*<info serverAlias="DBCUST-bodb_CustomerLog,DBLOG-bodb_CustomerLog" executers="wsv_nap,wsv_alp,wsv_xnap" viewers="" isFunction="0" isNested="1"></info>*/

CREATE PROCEDURE [dbo].[CS_WriteLog_UserLog_Credit]
	@UserID INT,
	@CustID INT = 0,
	@SubAccID	INT, 
	@Doing VARCHAR(500),
	@OldValue MONEY = NULL,
	@NewValue MONEY = NULL,
	@IP varchar(15) = '',
	@ActionID int = NULL
AS
/*
	Created: 
	Task : Write Credit Log .	
	DB: DBCUST-bodb_CustomerLog,DBLOG-bodb_CustomerLog
	Original:

	Revisions: 
		- 20190530@Paul: Insert log when updating credit [Redmine: #113198]
		- 20190530@Paul: Cannot write log on CustDB if service broker is failed to write log [Redmine: #125244]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Date DATE , @ActualRate FLOAT, @ExchangeId TINYINT
	SELECT @Date = CURRENT_TIMESTAMP
 
	IF @@SERVERNAME IN ('DBCUST','SITDBCUST','DB233','DB230\SQLSERVER2008R2')
	BEGIN
		SELECT  @ExchangeId = Currency
		FROM	CustDB.dbo.Customer WITH (NOLOCK)
		WHERE	CustId = @CustID

		SELECT @ActualRate = ActualRate
		FROM  CustDB.dbo.ExchangeDailyOanda WITH (NOLOCK)
		WHERE ExchangeDate = @Date
			  AND ExchangeId = @ExchangeId 
	END
	ELSE
	BEGIN
		SELECT  @ExchangeId = Currency
		FROM	bodb02.dbo.Customer WITH (NOLOCK)
		WHERE	CustId = @CustID

		SELECT @ActualRate = ActualRate
		FROM  bodb02.dbo.ExchangeDailyOanda WITH (NOLOCK)
		WHERE ExchangeDate = @Date
			  AND ExchangeId = @ExchangeId 
	END

	INSERT INTO CS_UserLog_Credit (
		UserID,
		CustID,
		SubAccID,
		OldValue,
		NewValue,
		IP,
		Doing,
		ActionID,
		ActualRate
	) 
	VALUES (@UserID, 
			@CustID,
			@SubAccID, 
			@OldValue, 
			@NewValue, 
			@IP, 
			@Doing, 
			@ActionID,
			@ActualRate)
END
GO