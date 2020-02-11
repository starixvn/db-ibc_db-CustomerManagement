/*<info serverAlias="DBCUST-CustDB" executers="vnteam" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE DBA_CurrencyModifierUpd
	@CustId	INT,
	@IsLicensee BIT,
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
*/
BEGIN
	IF @IsLicensee = 0
	BEGIN
		UPDATE s
		SET s.CurrencyModifier = @CurrencyModifier
		FROM dbo.CustSuper s WITH (ROWLOCK)
		WHERE custid = @CustId
	END
	ELSE
	BEGIN
		UPDATE s
		SET s.CurrencyModifier = @CurrencyModifier
		FROM dbo.Dep_CustSuper s WITH (ROWLOCK)
		WHERE custid = @CustId
	END
END