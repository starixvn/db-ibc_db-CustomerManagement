/*<info serverAlias="DBAGE-bodb02,DBACC-bodb02" executers="bodbAdminNet,wsv_nap,bodbExtAccNet,wsv_xnap,wsv_alp" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExchangeCurrencySel]
	@Mode int = 1
AS
/*
Created: Winfred.pham
Task : Alpha - Enable/disable status for Saba Virtual Sport
DB: DB05.BODB02 , DB06.BODB02
Original:All site
Revisions:
	Parameter's explaination: @Mode  = 0: No currency UUS
									 = 1: All Site
									 = 2: All Site and IsActive = 1
	- 20200624@Winfred: Input format metadata [Redmine: #131241]
	- 20210713@Eden:  Flexible Initializing Customer Setting - add mode = 2 [RedmineID: #156667]
*/		

-- test 2
	SET NOCOUNT ON

	SELECT exchangeid, currency 
	FROM exchange WITH (NOLOCK) 
	WHERE @Mode = 1 
		OR ( @Mode = 0 AND exchangeid <> 20)
		OR ( @Mode = 2 AND IsActive = 1)

