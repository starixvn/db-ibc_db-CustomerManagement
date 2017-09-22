/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE CustDB
GO 

ALTER PROCEDURE [dbo].[Acc_ExchangeSel_Sync_NG2]
AS
/*
Created: 20160823@Jamie
Task : Currencys synchronized to NG2 [RedmineID:#62306 ]
DB: DBCUST\CustDB
Original:

Revisions:

Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON 
	SELECT	ExchangeID, Currency, actualrate
	FROM	Exchange WITH (NOLOCK)
	WHERE	ExchangeID IN (
				 3		--US$
				,16		--Yen
				,17		--NTD
				,20		--UUS
				,35		--$US
				,40		--IRR
				,64		--UT
				,74		--TH
			)
END

GO
GRANT  EXECUTE  ON [dbo].[Acc_ExchangeSel_Sync_NG2]  TO [bodbAdminNet]
GO

