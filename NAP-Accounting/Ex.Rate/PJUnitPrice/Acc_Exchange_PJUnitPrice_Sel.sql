/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_Exchange_PJUnitPrice_Sel]
AS

/*
	Created by Percy
	Date: 2018-02-02
	DB: DBACC.bodb02
	Task: Exchange - Select PJUnitPrice value

	Revisions:
		- 20180202@Percy: Initialize SP [RedmineID: #89122]
*/

BEGIN
	SET NOCOUNT ON

	SELECT
		ExchangeId AS CurrencyId, Currency, Code, PJUnitPrice
	FROM dbo.Exchange WITH (NOLOCK)
	ORDER BY Currency ASC
END
GO