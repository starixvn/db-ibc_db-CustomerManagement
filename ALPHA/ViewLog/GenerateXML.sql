/* Created:20091224@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- Convert csv format string to xml format	     
	
    Param's Explaination:    	
	- @eleTagName: xml tag name
	- @logDataPlainText: string csv format ex: attr1=value1,attr2=value2
*/


CREATE FUNCTION [dbo].[GenerateXML](@eleTagName NVARCHAR(50), @logDataPlainText NVARCHAR(MAX))
RETURNS NVARCHAR(max) WITH EXECUTE AS CALLER
EXTERNAL NAME [IBCViewLogCLR].[UserDefinedFunctions].[GenerateXML]