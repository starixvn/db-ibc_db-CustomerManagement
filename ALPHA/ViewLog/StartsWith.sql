/* Created:20091224@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- Determine whether beginning of the string match the specific string 
	
    Param's Explaination:    	
	- @string: 
	- @start: pattern to remove out of @string
*/

CREATE FUNCTION [dbo].[StartsWith](@string NVARCHAR(MAX), @start nvarchar(MAX))
RETURNS BIT WITH EXECUTE AS CALLER
EXTERNAL NAME [IBCViewLogCLR].[UserDefinedFunctions].[StartsWith]
