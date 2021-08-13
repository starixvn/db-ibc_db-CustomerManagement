/*<info serverAlias="DBCUST-custDB,DBACC-bodb02" executers="" viewers="" isFunction="1" isNested="0"></info>*/

ALTER FUNCTION dbo.f_GetSecurityFunctionInfo(@bitOrder TINYINT,@FunctionInfo TINYINT)
RETURNS TABLE
AS 
/*
	Created by: Elodie
	Date:2021-08-13
	Task: get function info status
	DB: DBCUST/CustDB
	
	Revisions:
		- 20210812@Elodie: initial sp [redmine: #159628]
	Parameter's Explanation:
*/
	RETURN(SELECT CASE WHEN @FunctionInfo&power(2,@bitOrder-1) > 0 THEN 1 ELSE 0 END AS FunctionInfo)
GO	