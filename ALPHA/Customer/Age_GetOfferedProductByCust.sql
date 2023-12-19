/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_GetOfferedProductByCust]
	@custid INT
	, @SettingStatus TINYINT = 0
AS
/*
	Created: 20180906@Elodie
	DB: DBAGE/bodb02
	Task: Get all product which offered for customer

	Revisions:
		- 20180906@Elodie: Get all product which offered for customer [Redmine: #95940]
		- 20190926@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
		- 20200806@Elodie: Get real productid [Redmine: #139017]
		- 20200821@Winfred: Get all productid in MaCau Game [Redmine: #167768]
		- 20200911@Winfred: add product joker [Redmine: #131603]
		- 20201009@Tina: Add new parameter @SettingStatus [Redmine: #143077]
		- 20210104@Eden: add product Max Game [Redmine: #147232]
		- 20210302@Winfred: add Habanero  [RedmineID: #145459]
		- 20210324@Winfred: Get product Creative Gaming in MaCau Game [Redmine: #146016]
		- 20210506@Winfred: Get product AdvantPlay in MaCau Game [Redmine: #154258]
		- 20210514@Winfred: Get product AdvantPlay Mini in MaCau Game [Redmine: #155133]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20220803@Eden:  Implement the dependency between Macau Games Product Status and Jackpot Status [Redmine: #171715]
		- 20220922@Tacy: Add SEAL Entertainment [RedmineID: #176209]
		- 20220922@Tacy: Add Microgaming [RedmineID: #175853]
		- 20221102@Winfred: Get PP, SG, Arcadia Gaming in Macau Games Product Status [RedmineID: #180032] 
		- 20220921@Winfred:  Macau Game Setting Page - Rename the setting page into RNG Slot and hide all bet limit setting [Redmine: #174513]
		- 20230307@Winfred:  Hotfix - Telegram Chatbot: Report Today Win Loss not include data of product Macau games [Redmine: #184766]
		- 20230118@Helios: add JiliGame [RedmineId: #182869] 
		- 20230323@Eden: Migrate NG and Keno to DCS structure [Redmine: #179711]
		- 20230731@Eden: Simplify Live Casino Customer Setting - [Redmine: #189389]
		- 20230928@Luke: Modify SPs to adapt in-house replication setup [Redmine: #194414]
		- 20231204@Tacy: ExtNAP/Alpha - Return Offered product lists by site/currency [RedmineId: #196141]

	Param's Explanation:
		- @SettingStatus: 0: Pro, 1: UAT

	Example: EXEC Age_GetOfferedProductByCust @CustID = 1176086
		
*/
BEGIN
    SET NOCOUNT ON

	DECLARE @Currency INT, 	@Site VARCHAR(50)

	CREATE TABLE #Products (ProductID TINYINT, ProductName VARCHAR(50), EndOfSupportDate date, IsHidden BIT,[Type] tinyint,OrderNo int)

	--Get: site/currency
	SELECT @Currency=c.currency, @Site=c.site
	FROM Customer c WITH (NOLOCK)
	WHERE custid=@custid

	--Product Status
	INSERT INTO #Products (ProductID, ProductName, IsHidden, EndOfSupportDate, OrderNo, [Type])
	EXEC dbo.Age_GetOfferedProductBySiteCurrency @Site = @Site, @Currency = @Currency, @SettingStatus = @SettingStatus

	SELECT t.ProductID, t.isHidden, t.EndOfSupportDate
	FROM #Products t
	ORDER BY ProductID

	DROP TABLE #Products
END
GO