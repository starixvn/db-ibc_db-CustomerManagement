/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet" viewers="" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[CS_Acc_CustomerInfo_HeadlineSel]
	@username VARCHAR(30),
	@CheckCustId TINYINT = 0,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(500) = '' OUTPUT
AS
/*
	Created: 20190425@Johnson
	Task : Get headline info for cn88
	DB: DBAGE/bodb02
	
	Revisions:
		- 20190425@Johnson: initial sp [redmine: 105338]
*/
BEGIN
	
END
GO

