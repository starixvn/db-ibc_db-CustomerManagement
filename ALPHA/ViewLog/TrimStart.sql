/* Created:20091224@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- Remove all leading occurences char 
	
    Param's Explaination:    	
	- @string: 
	- @trimChar:
*/

CREATE FUNCTION [dbo].[TrimStart](@string NVARCHAR(MAX), @trimChar nvarchar)
RETURNS NVARCHAR(MAX) WITH EXECUTE AS CALLER
EXTERNAL NAME [IBCViewLogCLR].[UserDefinedFunctions].[TrimStart]
