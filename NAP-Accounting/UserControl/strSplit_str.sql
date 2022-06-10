/*<info serverAlias="DBCUST-CustDB" selecters="" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[strSplit_str](@string [nvarchar](4000), @splitter [char](1))
RETURNS TABLE
AS
/*
		Created: 20220517@Eden
		Task: strSplit_str
		DB: DBCUST-CustDB
		
		Revisions:
			- 20220517@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831]  
		Parameter's Explanation:
*/
RETURN
	 SELECT value AS val 
	 FROM string_split(CASE WHEN CHARINDEX(@splitter, @string, LEN(@string)) = LEN(@string) AND @string <> '' THEN   SUBSTRING(@string, 1, LEN(@string) - 1) ELSE @string END,@splitter)
GO