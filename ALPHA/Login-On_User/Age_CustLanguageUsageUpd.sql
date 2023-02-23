/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/
CREATE PROC [dbo].[Age_CustLanguageUsageUpd]  

@CustID INT , 
@SubAccID INT = 0 ,
@LanguageUsage varchar(2)
AS
/*
	Created: 20230214@Helios
	Task : Update language change by SMA in Alpha Site
	DB: DBCUST/CustDB

	Revisions:
	- 20230214@Helios: Enhance language part [RedmineID: #183700]
EXEC  [dbo].[Age_CustLanguageUsageUpd] 2000003763, 0 , 'EN'
EXEC  [dbo].[Age_CustLanguageUsageUpd] 2000003763, 1722384 , 'TH'
EXEC  [dbo].[Age_CustLanguageUsageUpd] 2000003763, 1722385 , 'CN'
*/ 
BEGIN

IF  @SubAccID > 0
	BEGIN
		UPDATE custSub Set LanguageUsage = @LanguageUsage
		FROM CustLoginInfoSub custsub WITH (ROWLOCK ,UPDLOCK)
		WHERE CustID = @CustID and SubAccID = @SubAccID
	END
ELSE
	BEGIN
		UPDATE cust Set LanguageUsage = @LanguageUsage
		FROM CustLoginInfo cust WITH (ROWLOCK ,UPDLOCK)
		WHERE CustID = @CustID
	END

END