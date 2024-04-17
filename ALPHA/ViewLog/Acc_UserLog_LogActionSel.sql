/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="wsv_nap,bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE Acc_UserLog_LogActionSel
AS 
/* 
	Created:20100304@Henry
    Task: Get all data of table LogAction	
    DB: DBLOG/bodb_CustomerLog
    Param's Explaination:    
    Revisions:
		- 20130227@Elodie: Get log action with Vietname language
		- 20190405@Elodie: Get log action with Chinese Traditional (CN88) language
	
*/
BEGIN
    SET NOCOUNT ON
	SELECT 
		ActionID,
		ActionTypeID,
		SPName,
		ActionNameEN,
		ActionNameCH,
		ActionNameCS,
		ActionNameJP,
		ActionNameIT,
		ActionNameTH,
		ActionNameKO,
		ActionNameVI,
		ActionNameCN,
		IsInternal,
		XsltContent
	FROM LogAction WITH (NOLOCK)
END
