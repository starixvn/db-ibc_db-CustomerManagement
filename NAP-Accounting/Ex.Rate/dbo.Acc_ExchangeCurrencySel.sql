/*<info serverAlias="DBAGE-bodb02,DBACC-bodb02" executers="bodbAdminNet,bodbExtAccNet,bodbDownlineNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExchangeCurrencySel]
AS
/*
Created: HuyNguyen
Task : Get Currency Name by exchangeID
DB: DB05.BODB02 , DB06.BODB02
Original:Accounting site
Revisions:
	- 20200624@Winfred: Input format metadata [Redmine: #131241]
*/		

-- test 2
	SET NOCOUNT ON

	SELECT exchangeid, currency from exchange with (nolock) where exchangeid <> 20

