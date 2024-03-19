/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LimitPTDaily_ProductList] 
	-- Add the parameters for the stored procedure here
	 @SettingStatus		TINYINT = 0
AS
/*
		Task : NAP CM -  Limit Daily PT Update
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20211027@Winfred: NAP CM -  Limit Daily PT Update [Redmine: #162476]
			- 20220921@Winfred:  Macau Game Setting Page - Rename the setting page into RNG Slot and hide all bet limit setting [Redmine: #174513]
	*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT DISTINCT fil.ProductID,  P.ProductName
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,1,@SettingStatus) fil 
	INNER JOIN  DBACC.bodb02.dbo.Products AS p WITH(NOLOCK) ON p.ProductID = fil.ProductID
	WHERE fil.ProductID = 18
	UNION 
	SELECT DISTINCT fil.ProductID,  P.ProductName
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,18,@SettingStatus) fil 
	INNER JOIN  DBACC.bodb02.dbo.Products AS p WITH(NOLOCK) ON p.ProductID = fil.ProductID
	WHERE fil.ProductID = 18
	
END
GO
