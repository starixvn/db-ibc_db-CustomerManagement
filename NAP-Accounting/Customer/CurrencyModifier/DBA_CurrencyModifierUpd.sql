/*<info serverAlias="DBCUST-CustDB" executers="vnteam" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE DBA_CurrencyModifierUpd
	@CustId	INT,
	@CurrencyModifier SMALLMONEY
AS
/*  
	Created: Elodie
	Date: 20200210
	Task : Update CurrencyModifier
	DB: DBCUST/CustDB

	Revisions:
		- 20200210@Elodie: Initial SP [Redmine:#127300]

	Parameter's explaination:
	Example: EXEC DBA_CurrencyModifierUpd @CustId = 24972511, @CurrencyModifier = 0.7
*/
BEGIN
	DECLARE @FromDate DATETIME = GETDATE()

	IF EXISTS (SELECT 1 FROM dbo.Dep_CustSuper WITH (NOLOCK) WHERE custid = @CustId)
	BEGIN
		UPDATE s
		SET s.CurrencyModifier = @CurrencyModifier
		FROM dbo.Dep_CustSuper s WITH (ROWLOCK)
		WHERE custid = @CustId		
	END
	ELSE
	BEGIN
		UPDATE s
		SET s.CurrencyModifier = @CurrencyModifier
		FROM dbo.CustSuper s WITH (ROWLOCK)
		WHERE custid = @CustId
	END

	UPDATE dbo.CurrencyModifier_History
	SET ToDate = @FromDate
	WHERE CustId = @CustId AND ToDate = '9999-12-31 0:00:00.000'

	INSERT INTO CurrencyModifier_History(CustId, CurrencyModifier, FromDate, ToDate)
	SELECT @CustId, @CurrencyModifier, @FromDate, '9999-12-31 0:00:00.000'

END