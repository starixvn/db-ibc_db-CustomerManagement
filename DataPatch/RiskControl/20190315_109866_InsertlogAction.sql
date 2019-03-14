
/*
	Created: Jacob	
	Task:  Insert LogAction
	DB: DBLOG/bodb_CustomerLog
	Date: 20190315
	Feature: 109866
*/

INSERT INTO bodb_CustomerLog.dbo.LogAction
       (ActionID,
        ActionTypeID,
        SPName,
        ActionNameEN,
        ActionNameCH,
        ActionNameCS,
        ActionNameJP,
        ActionNameIT,
        ActionNameTH,
        ActionNameKO,
        XsltContent,
        IsInternal,
        ActionNameVI
       )
VALUES
       (31601,
        NULL,
        'NAP_GameRoundBetLimitSettingUpd',
        'Update Game Ground Bet Limit Setting',
        'Update Game Ground Bet Limit Setting',
        'Update Game Ground Bet Limit Setting',
        'Update Game Ground Bet Limit Setting',
        'Update Game Ground Bet Limit Setting',
        'Update Game Ground Bet Limit Setting',
        'Update Game Ground Bet Limit Setting',
        'Update Game Ground Bet Limit Setting',
        1,
        'Update Game Ground Bet Limit Setting'
       );
GO