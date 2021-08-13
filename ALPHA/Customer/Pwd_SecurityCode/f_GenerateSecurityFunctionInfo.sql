/*<info serverAlias="DBCUST-custDB" executers="" viewers="" isFunction="1" isNested="0"></info>*/

ALTER FUNCTION dbo.f_GenerateSecurityFunctionInfo(@bitOrder TINYINT, @IsOn BIT,@FunctionInfo TINYINT)
RETURNS TABLE
AS 
/*
	Created by: Elodie
	Date:2021-08-12
	Task: get function info
	DB: DBCUST/CustDB
	
	Revisions:
		- 20210812@Elodie: initial sp [redmine: #159628]
	Parameter's Explanation:
	
*/
RETURN(SELECT CASE WHEN @IsOn = 1 THEN @FunctionInfo|POWER(2,@bitOrder-1)
					ELSE @FunctionInfo&(~POWER(2,@bitOrder-1)) END AS FunctionInfo)
GO