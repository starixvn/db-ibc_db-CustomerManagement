/* Created:20091224@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- Convert strings seperated by commas to xml
	
    Param's Explaination:    
	- @parentTagName: parent tag of xml
	- @raw: string need to be converted
*/

CREATE FUNCTION [dbo].[ConvertToXML](@parentTagName [NVARCHAR](50), @raw [NVARCHAR](MAX))
RETURNS [NVARCHAR](MAX) WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [IBCViewLogCLR].[UserDefinedFunctions].[ConvertToXML]