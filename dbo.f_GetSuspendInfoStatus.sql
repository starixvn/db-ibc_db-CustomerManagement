/*<info serverAlias="DBCUST-CustDB,DBAGE-bodb02,DBACC-bodb02" executers="" viewers="" isFunction="1" isNested="0"></info>*/
ALTER FUNCTION dbo.f_GetSuspendInfoStatus(@bitOrder TINYINT,@suspendInfo TINYINT)
RETURNS BIT
AS 
/*
	Created by:Johnson
	Date:2019-04-08
	Task: get downlines suspend info status
	DB: DBCUST/CustDB
	
	Revisions:
		- 20190408@Johnson: initial sp [redmine: #105587]
	Parameter's Explanation:
*/
BEGIN
	RETURN(@suspendInfo&power(2,@bitOrder-1))
END
GO	