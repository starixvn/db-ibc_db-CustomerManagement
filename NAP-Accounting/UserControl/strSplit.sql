/*<info serverAlias="DBCUST-bodb_Licensee,DBCUST-IPDB,DBCUST-CustDB,DBPOL-NAP_UserControl" selecters="bodbAdminNet,wsv_nap,wsv_lap,wsv_alp,Dot_Member" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[strSplit](@string [nvarchar](MAX), @splitter [char](1))
RETURNS TABLE
AS
/*
		Created: Helen
		Date: 2018-03-13
		Task: Split string
		DB: DBCUST-bodb_Licensee,DBCUST-IPDB,DBCUST-CustDB,DBPOL-NAP_UserControl
		
		Revisions:
			- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
			- 20220517@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831]  
		Parameter's Explanation:
*/
	 
RETURN
	WITH TMP AS(
	 SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS id, 
		value AS val 
	 FROM string_split(CASE WHEN CHARINDEX(@splitter, @string, LEN(@string)) = LEN(@string) AND @string <> '' THEN   SUBSTRING(@string, 1, LEN(@string) - 1) ELSE @string END,@splitter)
	 )
	 SELECT id, id as [rank],val FROM tmp
GO