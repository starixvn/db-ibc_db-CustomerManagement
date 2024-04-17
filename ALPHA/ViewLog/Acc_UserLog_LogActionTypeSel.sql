/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE Acc_UserLog_LogActionTypeSel
AS 
/* 
	Created:20100304@Henry
    Task: Get all data of table LogActionType
    DB: DBLOG/bodb_CustomerLog

	Revisions:
		- 20121212@Elodie: Get more field ActionTypeNameVI
		- 20190405@Elodie: Get log action with Chinese Traditional (CN88) language
		- 20190926@Elodie: Exclude ProblemAccount [Redmine#120934]
		- 20200119@Elodie: Offer ProblemAccount for credit and deposit [Redmine#127446]

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