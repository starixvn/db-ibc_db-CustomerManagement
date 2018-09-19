/*<info serverAlias="DBCust-CustDB,DBAGE-bodb02,DBACC-bodb02" executers="bodbAdminNet,bodbExtAccNet" viewers="vnteam" isFunction="0"></info>*/


ALTER PROCEDURE [dbo].[Acc_CheckShowProduct]
	@ProductID	TINYINT,
	@IsHide		BIT OUTPUT 
AS
/*
	Created by: Elodie
	Date: 20170317
	Task: check if show product or not
	DB: DBCust/CustDB, DBAGE/bodb02, DBACC/bodb02
	Original: 
	
	Revisions:
		- 20170331@Winnie: Change to IsHide
		- 20170601@Elodie: Migrate Inspired VS to DCS structure, add BetRadar VS product [Redmine: #77274]
	Explanation's Param:
		
*/   
BEGIN 
	SET NOCOUNT ON
	
	SELECT @IsHide = 1

	-- For DCS Product
    DECLARE	@SettingType INT

	--IF @ProductID IN (16,19,20)
	--	SELECT @SettingType = 4
	--ELSE IF @ProductID = 23
	--	SELECT @SettingType = 11
	--ELSE IF @ProductID IN(21,22,23,24,5)
	--	SELECT @SettingType = 13
	
	SELECT @SettingType = SettingType FROM dbo.ProductSettingDetail WITH (NOLOCK) WHERE ProductID = @ProductID AND SettingType IN (4,11,13)

	IF EXISTS( SELECT 1 FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@ProductID,@SettingType))
	BEGIN
		SELECT @IsHide = 0
	END
END
GO