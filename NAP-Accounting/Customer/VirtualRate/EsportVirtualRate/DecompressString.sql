/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="1"></info>*/
CREATE FUNCTION [dbo].[DecompressString](@Text [nvarchar](max))
RETURNS [nvarchar](max)
AS
/* 
	Created:20190715@Dominic
    Task: Add a temporary prototype funtion to decompress string,
		it will be replaced with a CLR funtion later
    DB: bodb_CustomerLog
	Revisions:    
		- 20190715@Dominic : First commit
*/
BEGIN
	RETURN @Text
END