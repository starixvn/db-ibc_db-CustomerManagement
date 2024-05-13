/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
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
			- 20240314@Helios: Unify Live RNG Casino [Redmine: #198960] 
	*/
BEGIN
	SET NOCOUNT ON;
	

	DECLARE @Tbl TABLE (
				ProductID		INT,
				SportType		SMALLINT,
				BetType		SMALLINT
				)		
	INSERT INTO @Tbl 
	(
		ProductID
	    , SportType
	    , BetType
	)
	SELECT DISTINCT fil.ProductID,  fil.SportType , fil.Bettype
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,1,@SettingStatus) fil
	UNION
	SELECT DISTINCT fil.ProductID,  fil.SportType , fil.Bettype
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,18,@SettingStatus) fil

	SELECT T.ProductID , P.ProductName
	FROM @Tbl AS t
	CROSS APPLY (
				SELECT dbo.f_CustSetting_GetOfferPTLimit (t.SportType, t.BetType)
			) fn (IsOffer)
	INNER JOIN  DBACC.bodb02.dbo.Products AS p WITH(NOLOCK) ON p.ProductID = t.ProductID
	WHERE fn.IsOffer = 1


	
	
END
GO
