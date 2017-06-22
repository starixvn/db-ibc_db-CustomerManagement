/* Created:20091224@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- Determine whether the end of the string match the specific string 
	
    Param's Explaination:    	
	- @string: 
	- @end: pattern to remove out of @string
*/

CREATE FUNCTION [dbo].[EndsWith](@string NVARCHAR(MAX), @end nvarchar(MAX))
RETURNS BIT WITH EXECUTE AS CALLER
EXTERNAL NAME [IBCViewLogCLR].[UserDefinedFunctions].[EndsWith]
