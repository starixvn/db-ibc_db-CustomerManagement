/*<info serverAlias="DBCUST-custDB,DBAGE-bodb02,DB042-bodb02,DB04Admin1-bodb02,DB04Admin2-bodb02,DBONUSER-bodb02,DBEXT-bodb02,DBLICAPI-bodb02,DBLICAPI02-bodb02,DBACC-bodb02" executers="" viewers="" isFunction="1" isNested="0"></info>*/

ALTER FUNCTION dbo.f_GetSuspendInfoStatus(@bitOrder TINYINT,@suspendInfo TINYINT)
RETURNS TABLE
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
	RETURN(SELECT @suspendInfo&power(2,@bitOrder-1) as suspendInfo)
GO	