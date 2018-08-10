/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet,bodbDownlineNet" viewers="vnteam" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_EncodeXMLValue](@value NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
/*  Created:20091224@Lewin
    Task: ViewLog function 331
    DB: DB: DBLOG.bodb_CustomerLog, DB03.BODB02, DBTRANS.BODB02,DB02.bodb02, DB052.bodb_CRM , DBCUST/NAP_UserControl
    
    
    
	Revision:
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
*/

BEGIN
	/*
		# &amp; refers to an ampersand (&) 
		# &lt; refers to a less-than symbol (<) 
		# &gt; refers to a greater-than symbol (>) 
		# &quot; refers to a double-quote mark (") 
		# &apos; refers to an apostrophe (') 	
	*/
		
	SET @value = REPLACE(@value, '&', '&amp;')
	SET @value = REPLACE(@value, '<', '&lt;')
	SET @value = REPLACE(@value, '>', '&gt;')
	SET @value = REPLACE(@value, '"', '&quot;')
	SET @value = REPLACE(@value, '', '&apos;')
	
	RETURN @value
END
GO
GRANT VIEW DEFINITION ON [dbo].[f_EncodeXMLValue] TO [vnteam]
GO