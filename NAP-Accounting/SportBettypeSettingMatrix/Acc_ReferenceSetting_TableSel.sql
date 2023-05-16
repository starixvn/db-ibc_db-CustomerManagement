/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE dbo.Acc_ReferenceSetting_TableSel
		@TableType TINYINT = 0
AS
/*
	Task : NAP - New function to manage SportBettypeSettingMatrix table
	DB: DBACC/bodb02
	Original: 

	Revisions:
		- 20230301@Tacy: Create SP [Redmine: #184255] 
		
	Param's Explanation:
		- @TableType = 0 ~ All
					   1 ~ TablePT
					   2 ~ TableComm
					   3 ~ TableBetSetting
					   4 ~ TableBettrans

		- OfferSite = [0-Credit, 1-Deposit, 2-All]

	Example: EXEC Acc_ReferenceSetting_TableSel @TableType=0
*/
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #RefTable (TableType VARCHAR(20), TableName VARCHAR(50), OfferSite TINYINT)

	INSERT INTO #RefTable (TableType, TableName, OfferSite)
	SELECT 'TablePT' AS TableType, 'CustSetting'					AS TableName,	0 AS OfferSite UNION ALL	SELECT 'TablePT' AS TableType, 'CustPTsetting3rd_Member'		AS TableName,	0 AS OfferSite UNION ALL	SELECT 'TablePT' AS TableType, 'Dep_CustPTGroupSetting_Member'	AS TableName,	1 AS OfferSite UNION ALL	SELECT 'TablePT' AS TableType, 'Dep_CustPTSetting_Member'		AS TableName,	1 AS OfferSite UNION ALL	SELECT 'TableComm' AS TableType, 'CustDiscount3rd_Member'				AS TableName,	0 AS OfferSite UNION ALL
	SELECT 'TableComm' AS TableType, 'CustSetting'							AS TableName,	0 AS OfferSite UNION ALL
	SELECT 'TableComm' AS TableType, 'Dep_CustDiscountSetting_Member'		AS TableName,	1 AS OfferSite UNION ALL
	SELECT 'TableComm' AS TableType, 'Dep_CustDiscountGroupSetting_Member'	AS TableName,	1 AS OfferSite UNION ALL

	SELECT 'TableBetSetting' AS TableType, 'CustSetting'						AS TableName,	0 AS OfferSite UNION ALL
	SELECT 'TableBetSetting' AS TableType, 'CustBetSetting3rd_Member'			AS TableName,	0 AS OfferSite UNION ALL
	SELECT 'TableBetSetting' AS TableType, 'CustBetSetting_Member'				AS TableName,	0 AS OfferSite UNION ALL
	SELECT 'TableBetSetting' AS TableType, 'CustStakeLevel_member'				AS TableName,	0 AS OfferSite UNION ALL
	SELECT 'TableBetSetting' AS TableType, 'Dep_CustBetSettingGameGroup_Member'	AS TableName,	1 AS OfferSite UNION ALL
	SELECT 'TableBetSetting' AS TableType, 'Dep_CustStakeLevel_Member'			AS TableName,	1 AS OfferSite UNION ALL
	SELECT 'TableBetSetting' AS TableType, 'Dep_CustBetSetting_Member'			AS TableName,	1 AS OfferSite UNION ALL

	SELECT 'TableBettrans' AS TableType, 'bettransLC'		AS TableName,	2 AS OfferSite UNION ALL
	SELECT 'TableBettrans' AS TableType, 'translog'			AS TableName,	2 AS OfferSite UNION ALL
	SELECT 'TableBettrans' AS TableType, 'bettransG'		AS TableName,	2 AS OfferSite UNION ALL
	SELECT 'TableBettrans' AS TableType, 'bettransRNG'		AS TableName,	2 AS OfferSite UNION ALL
	SELECT 'TableBettrans' AS TableType, 'bettrans'			AS TableName,	2 AS OfferSite

	SELECT TableType, TableName, OfferSite 
	FROM #RefTable
	WHERE 1 = CASE	WHEN @TableType=0 THEN 1
					WHEN @TableType=1 AND TableType='TablePT' THEN 1
					WHEN @TableType=2 AND TableType='TableComm' THEN 1
					WHEN @TableType=3 AND TableType='TableBetSetting' THEN 1
					WHEN @TableType=4 AND TableType='TableBettrans' THEN 1
					ELSE 0 END
END
GO