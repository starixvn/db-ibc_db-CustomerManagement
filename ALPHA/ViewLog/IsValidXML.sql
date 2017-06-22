/* Created:20091224@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- Check a string has valid xml format or not
	
    Param's Explaination:    	
	- @VALUE: xml string
*/

CREATE FUNCTION [dbo].[IsValidXML](@VALUE [NVARCHAR](MAX))
RETURNS [BIT] WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [IBCViewLogCLR].[UserDefinedFunctions].[IsValidXML]