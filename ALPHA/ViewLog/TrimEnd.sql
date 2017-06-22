/* Created:20091224@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- Within a string, remove all trailing occurences match a sepecific string with string returned
	
    Param's Explaination:    	
	- @string: string to remove
	- @trimChar: string pattern that remove out of @string
*/

CREATE FUNCTION [dbo].[TrimEnd](@string NVARCHAR(MAX), @trimChar nvarchar)
RETURNS NVARCHAR(MAX) WITH EXECUTE AS CALLER
EXTERNAL NAME [IBCViewLogCLR].[UserDefinedFunctions].[TrimEnd]
