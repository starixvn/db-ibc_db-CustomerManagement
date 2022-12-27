/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_InitializingGlobal_CurrencySel] 
	-- Add the parameters for the stored procedure here
	  @Mode	tinyint = 0	 -- 0: All, 1 : Credit, 2 :Deposit
AS
/*
		Task : NAP -  Flexible Initializing Stake Level
		DB: DBACC/bodb02
		Original: 
		Revisions:
			- 20220210@Winfred: NAP -  Flexible Initializing Stake Level [Redmine: #167128]
	*/
BEGIN
	
	SET NOCOUNT ON;
				
	SELECT 
		 ExchangeID, Currency
	FROM Exchange  WITH(NOLOCK)
	WHERE IsActive = 1 AND (@Mode = 0 OR (@Mode = 1 AND OfferSite IN (0,1)) OR (@Mode = 2 AND OfferSite IN (0,2)))
	ORDER BY ExchangeID, Currency
  
END
GO
