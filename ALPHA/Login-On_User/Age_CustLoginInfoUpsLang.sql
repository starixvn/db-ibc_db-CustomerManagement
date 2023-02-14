/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet, bodbDownlineNetView" viewers="" isFunction="0"></info>*/
CREATE PROC [dbo].[Age_CustLoginInfoUpsLang]  

@CustID INT = 0,
@SubAccID INT = 0,
@Lang varchar(2)= NULL
AS
/*
	Created: 20230214@Helios
	Task : Update language change by SMA in Alpha Site
	DB: DBTXN/BODB02

-- EXEC  [dbo].[Age_CustLoginInfoUpsLang] 1176083, 91726 , 'EN'
*/
BEGIN

IF @SubAccID > 0
	BEGIN
		Update custSub Set Lang = @Lang
		from CustLoginInfoSub custsub WITH (ROWLOCK ,UPDLOCK)
		where CustID = @CustID and SubAccID = @SubAccID

		Update cust Set Lang = @Lang
		from CustLoginInfo cust WITH (ROWLOCK ,UPDLOCK)
		where CustID = @CustID
	END
ELSE
	BEGIN
		Update cust Set Lang = @Lang
		from CustLoginInfo cust
		where CustID = @CustID
	END

END


