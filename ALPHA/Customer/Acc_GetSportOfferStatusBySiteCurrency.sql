/*<info serverAlias="DBCUST-CustDB,DBAGE-bodb02,DBACC-bodb02,DBTXN-CustDB" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv,bodbExtAccNet,wsv_xnap,wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_GetSportOfferStatusBySiteCurrency]
	@SiteID INT, 
	@Currency INT,
	@Sporttype SMALLINT,
	@Bettype SMALLINT,
	@IsHidden BIT = NULL OUTPUT,
	@SettingStatus TINYINT = 0
AS

/*  
	Created: 20230731@Eden  
	Task : Get Sport Offer Status By CustID
	DB: DBCUST/CustDB,DBAGE/bodb02, DBACC/bodb02,DBTXN-CustDB
  
	Revisions:
		- 20230731@Eden: Simplify Live Casino Customer Setting - [Redmine: #189389]

	Examples:
		DECLARE @IsHidden BIT
		EXEC [Acc_GetSportOfferStatusBySiteCurrency] 
			  @SiteID = 1
			, @Currency = 20
			, @Sporttype = 211
			, @Bettype = 2401
			, @IsHidden = @IsHidden OUT
		SELECT @IsHidden
*/

BEGIN
	SET NOCOUNT ON
	SELECT @IsHidden = dbo.f_CustSetting_GetSportOfferStatusBySiteCurrency(@SiteID,@Currency,@Sporttype,@Bettype,@SettingStatus)
END
GO