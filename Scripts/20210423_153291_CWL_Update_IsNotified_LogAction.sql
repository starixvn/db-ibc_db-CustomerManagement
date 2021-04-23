/*
	Created: 20191218@Helen
	Task: Update IsNotified for Winlimit History - insert log action - [Redmine: 153291] 
	DB: dblog/bodb_CustomerLog
*/
USE bodb_CustomerLog
GO
INSERT INTO dbo.LogAction (ActionID,SPName,ActionNameEN,ActionNameCH,ActionNameCS,ActionNameJP,ActionNameTH,ActionNameKO,IsInternal,ActionNameVI)
VALUES 
(31208,'NAP_WinLimit_Notification_History_Update'
		,'Update IsNotified for Winlimit History'
		,'Update IsNotified for Winlimit History'
		,'Update IsNotified for Winlimit History'
		,'Update IsNotified for Winlimit History'
		,'Update IsNotified for Winlimit History'
		,'Update IsNotified for Winlimit History'
		,0
		,'Update IsNotified for Winlimit History'
		)
