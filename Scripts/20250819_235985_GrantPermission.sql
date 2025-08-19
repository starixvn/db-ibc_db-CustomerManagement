/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0"></info>*/
/*
    Created: 20250819@Max
	Task: Support Onelab team to review and grant permission for SP_Dot Member_ - [Redmine: #235985]
	DB: DBCUST-CustDB
*/

USE CustDB
GO

GRANT EXECUTE ON [dbo].[Dot_Member_CheckWinLimitBlockUser] TO [oneseal_integration]
GO
