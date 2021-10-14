/*<info serverAlias="DBCUST-IPDB" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_GetIPInfo_Full
	@IP varchar(15)
AS
/*
	Created by: Jamie
	Date: 2010-04-01
	Task: Get IP Info 
	DB: DB02.IPDB 
	Original: GetIPInfo_Full
	Revisions:	
	- 20180710@Razor: Grant permission for bodbExtAccNet
	
*/
SET NOCOUNT ON

Declare @IPLong bigint, @IP1 tinyint

SET @IPLong = dbo.ipConvert(@IP)
SET @IP1 = @IPLong/16777216

Declare @countrySHORT nvarchar(2),
	@countryLONG nvarchar(64)

SELECT
	*
FROM iptable with (nolock)
WHERE
	@IP1 = ipKeyFrom
	and @IPLong between ipFrom and ipTo

IF @@ROWCOUNT = 0
SELECT
	*
FROM iptable with (nolock)
WHERE
	@IP1 between ipKeyFrom and ipKeyTo
	and @IPLong between ipFrom and ipTo