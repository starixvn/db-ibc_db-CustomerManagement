/*<info serverAlias="DBAGE-bodb02,DBACC-bodb02" executers="bodbAdminNet,bodbExtAccNet,bodbDownlineNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExchangeCurrencySel]
	@Mode int = 1
AS
/*
Created: HuyNguyen
Task : Get Currency Name by exchangeID
DB: DB05.BODB02 , DB06.BODB02
Original:Accounting site
Revisions:
	Parameter's explaination: @Mode  = 0: No currency UUS
									 = 1: All Site
	- 20200624@Winfred: Input format metadata [Redmine: #131241]
*/		

-- test 2
	SET NOCOUNT ON

	SELECT exchangeid, currency 
	FROM exchange WITH (NOLOCK) 
	WHERE @Mode = 1 OR ( @Mode = 0 AND exchangeid <> 20)

