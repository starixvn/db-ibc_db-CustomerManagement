/*<info serverAlias="DBCUST-bodb_CustomerLog,DBLOG-bodb_CustomerLog" executers="bodbAdminNet,wsv_nap,bodbDownlineNet,wsv_alp,bodbExtAccNet,wsv_xnap" viewers="" isFunction="0" isNested="1"></info>*/

 ALTER PROCEDURE [dbo].[WriteLog_UserLog_Credit]
	@UserID INT,
	@CustID INT = 0,
	@SPName	VARCHAR(50)=NULL, -- USE FOR OLD FORMAT AND WILL REMOVE LATER 
	@Doing VARCHAR(1000),
	@OldValue MONEY = NULL,
	@NewValue MONEY = NULL,
	@IP varchar(15)='',
	@ActionID int = NULL
AS
/*
	Created: 
	Task : Write Credit Log .	
	DB: DBLOG.bodb_CustomerLog
	Original:

	Revisions: 
		- 20090903@Simon: Write Credit Log.	
		- 20100102@Kiwi: Add ActionID Log.
		- 20150513@Sophia: Add Column ActualRate for Credit Movement Report [#30638]
		- 20200115@Elodie: Cannot write log on CustDB if service broker is failed to write log [Redmine: #89038]
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

	INSERT INTO UserLog_Credit (UserID, 
								CustID,
								SPName, 
								Doing, 
								OldValue, 
								NewValue, 
								IP, 
								ActionID,
								ActualRate) 
						VALUES (@UserID, 
								@CustID,
								@SPName, 
								@Doing, 
								@OldValue, 
								@NewValue, 
								@IP, 
								@ActionID,
								@ActualRate)
END
GO
