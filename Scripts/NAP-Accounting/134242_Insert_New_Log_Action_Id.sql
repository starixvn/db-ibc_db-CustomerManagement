/*<info serverAlias="DBLOG-bodb_CustomerLog" isFunction="0" isNested=""></info>*/
/*	
	Created: 20200602@Sol
	Task: Add new row into logaction table - [Redmine:#134242]
	DB: DBLOG/bodb_CustomerLog
*/

USE bodb_CustomerLog

GO 

INSERT INTO LogAction
(
	ActionID, 
	ActionTypeID, 
	SPName, 
	ActionNameEN, 
	IsInternal, 
	ActionNameCH,
	ActionNameCS,
	ActionNameJP,
	ActionNameIT,
	ActionNameTH,
	ActionNameKO,
	ActionNameVI,
	ActionNameCN
)
VALUES 
(
	707, 
	5, 
	'Acc_CustomerUpd_IsAutoEnableADBMaster', 
	'Enabled/Disabled Auto Enable ADB on Master', 
	1,
	'Enabled/Disabled Auto Enable ADB on Master',
	'Enabled/Disabled Auto Enable ADB on Master',
	'Enabled/Disabled Auto Enable ADB on Master',
	'Enabled/Disabled Auto Enable ADB on Master',
	'Enabled/Disabled Auto Enable ADB on Master',
	'Enabled/Disabled Auto Enable ADB on Master',
	'Enabled/Disabled Auto Enable ADB on Master',
	'Enabled/Disabled Auto Enable ADB on Master'
)

GO