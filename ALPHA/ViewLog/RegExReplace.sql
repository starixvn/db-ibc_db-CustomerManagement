/* Created:20100101@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- Within a specific string, replace all strings that match a sepecific regular expression
		with string returned
	
    Param's Explaination:    	
	- @expression: string to search for match
	- @pattern: regular expression to match
	- @repl: replacement string
*/

CREATE FUNCTION [dbo].[RegExReplace](@expression NVARCHAR(MAX), @pattern nvarchar(MAX),  @replace nvarchar(MAX))
RETURNS nvarchar(max) WITH EXECUTE AS CALLER
EXTERNAL NAME [IBCViewLogCLR].[UserDefinedFunctions].[RegExReplace]
