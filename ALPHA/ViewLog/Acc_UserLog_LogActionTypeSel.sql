/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Acc_UserLog_LogActionTypeSel
	@ServiceType	TINYINT = 0
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
		- 20250728@Helios: Initial create for CashService log [redmine: 233474]
    Param's Explaination:    
	EXEC Acc_UserLog_LogActionTypeSel_UAT2
	EXEC Acc_UserLog_LogActionTypeSel_UAT2 @ServiceType = 1
*/
BEGIN
	SET NOCOUNT ON
	
	IF @ServiceType = 0
	BEGIN
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
		WHERE ActionTypeID < 100
	END
	IF @ServiceType = 1
	BEGIN
		-- Return hard-coded values for ActionTypeID > 100
		SELECT 101 AS ActionTypeID, N'Bank Account' AS ActionTypeNameEN, N'银行账户' AS ActionTypeNameCH, N'银行账户' AS ActionTypeNameCS, N'Bank Account' AS ActionTypeNameJP, N'Bank Account' AS ActionTypeNameIT, N'บัญชีธนาคาร' AS ActionTypeNameTH, N'Bank Account' AS ActionTypeNameKO, NULL AS ActionTypeNameVI, N'银行账户' AS ActionTypeNameCN
		UNION ALL
		SELECT 102, N'Payment Gateway', N'支付网关', N'支付网关', N'Payment Gateway', N'Payment Gateway', N'ช่องทางการชำระเงิน', N'Payment Gateway', NULL, N'支付网关'
		UNION ALL
		SELECT 103, N'Promotion', N'优惠', N'优惠', N'Promotion', N'Promotion', N'โปรโมชั่น', N'Promotion', NULL, N'优惠'
		UNION ALL
		SELECT 104, N'Deposit', N'存款', N'存款', N'Deposit', N'Deposit', N'ฝากเงิน', N'Deposit', NULL, N'存款'
		UNION ALL
		SELECT 105, N'Withdrawal', N'提款', N'提款', N'Withdrawal', N'Withdrawal', N'ถอนเงิน', N'Withdrawal', NULL, N'提款'

		/* Open when released
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
		WHERE ActionTypeID > 100
		*/
	END

END