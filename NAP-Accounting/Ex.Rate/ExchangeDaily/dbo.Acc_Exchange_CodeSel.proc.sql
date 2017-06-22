
ALTER PROCEDURE  [dbo].[Acc_ExchangeCodeSel]
AS
/*
Created: Henry
Task : Get the list of Code need to get the exchange rate
DB: DB052.BODB02 
Revisions:
	- 20140220@Dan: exclude code 'C','H'
*/		
	SET NOCOUNT ON

	SELECT DISTINCT Code FROM exchange WITH (nolock)
	WHERE isnull(Code,'') <> '' 
		AND Code not in ('C', 'H')
		--AND Code in ('GBP', 'TWD')
GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeCodeSel] TO [bodbAdminNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeCodeSel] TO [vnteam]