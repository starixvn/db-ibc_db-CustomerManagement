/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0" ></info>*/
ALTER PROCEDURE [dbo].[Task_Winlimit_CustWinlostGameDel]	
AS
/*   
	Create: 20220829@Johnson
	Task : Delete history data winlimit game - [Redmine:175278]
	DB: DBCUST/CUSTDB
	
	Revisions:
		- 20220829@Johnson: Initial sp [Redmine: 175278]
		- 20240809@Johnson: Apply Inhouse Replication for CWL [redmine: #209068]
		- 20241029@Eden: Remove in-house rep for WinLimit_CustWinlostGame [redmine: #209068]
	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Winlostdate SMALLDATETIME
	
	SELECT @Winlostdate =  DATEADD(DAY,-7,GETDATE())
	
	WHILE(1=1)
	BEGIN
		DELETE TOP (2000) WinLimit_CustWinlostGame WITH(ROWLOCK)
		--OUTPUT DELETED.CustID, DELETED.Winlostdate, DELETED.Bettype, dbo.f_GetDateTime2()
		--INTO WinLimit_CustWinlostGame_Del_InHouse(custid,Winlostdate,Bettype,RepUpdateTime)
		WHERE Winlostdate < @Winlostdate
		
		IF @@ROWCOUNT = 0
			BREAK;
	END
	
END	