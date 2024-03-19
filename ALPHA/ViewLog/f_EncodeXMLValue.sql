/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet,wsv_nap,bodbDownlineNet,wsv_alp" viewers="vnteam" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_EncodeXMLValue](@value NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
/* Created:20091224@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

    
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