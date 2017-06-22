/* Created:20091224@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- Remove all leading and trailing with-space characters
	
    Param's Explaination:    	
	- @string: 
*/

CREATE FUNCTION [dbo].[Trim](@string NVARCHAR(MAX))
RETURNS NVARCHAR(MAX) WITH EXECUTE AS CALLER
EXTERNAL NAME [IBCViewLogCLR].[UserDefinedFunctions].[Trim]

