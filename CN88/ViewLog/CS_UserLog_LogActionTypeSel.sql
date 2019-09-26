/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_UserLog_LogActionTypeSel
AS 
/* 
	Created:20190926@Elodie
    Task: Get all data of table LogActionType for CN88
    DB: DBLOG/bodb_CustomerLog

	Revisions:
		- 20190926@Elodie: Initial SP [Redmine#120133]

    Param's Explaination:    
	
*/
BEGIN
	SET NOCOUNT ON
	SELECT 
		ActionTypeID,
		ActionTypeNameEN,
		ActionTypeNameCH,
		ActionTypeNameCS,
		ActionTypeNameJP,
		ActionTypeNameIT,
		ActionTypeNameTH,
		ActionTypeNameKO,
		ActionTypeNameVI,
		ActionTypeNameCN
	FROM LogActionType WITH (NOLOCK)
END